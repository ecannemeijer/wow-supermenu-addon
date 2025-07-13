

local lastDPS = nil
-- Use the global groupDamage table set by DungeonTracking.lua
local groupDamage = _G.groupDamage or {} -- [name] = {damage=0, startTime=0, inCombat=false, lastDPS=0}
local tableRows = {}
local NUM_ROWS = 8
local function GetDamageStats()
    if not dungeonTracker then return 0, 1, "-" end
    if dungeonTracker.inCombat or dungeonTracker.damageDone > 0 or dungeonTracker.damageTaken > 0 then
        return dungeonTracker.damageDone, GetTime() - dungeonTracker.startTime, dungeonTracker.zoneName
    else
        local last = SupermenuDB and SupermenuDB.DungeonRuns and SupermenuDB.DungeonRuns[#SupermenuDB.DungeonRuns]
        if last then
            local dmg = string.match(last, "Damage Done: (%d+)")
            local dur = string.match(last, "Duration: (%d+)s")
            local zname = string.match(last, "Zone: ([^|]+)")
            return tonumber(dmg) or 0, tonumber(dur) or 1, zname or "-"
        end
    end
    return 0, 1, "-"
end



_G["DamageWindow"] = CreateFrame("Frame", "SupermenuDamageWindow", UIParent)
DamageWindow = _G["DamageWindow"]
_G.DamageWindow:SetSize(340, 220)
_G.DamageWindow:SetPoint("CENTER")
_G.DamageWindow:Hide()
_G.DamageWindow:SetMovable(true)
_G.DamageWindow:EnableMouse(true)
_G.DamageWindow:RegisterForDrag("LeftButton")
_G.DamageWindow:SetResizable(true)
_G.DamageWindow:SetScript("OnDragStart", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
_G.DamageWindow:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Resize handle (bottom right corner)
local resizeBtn = CreateFrame("Button", nil, _G.DamageWindow)
resizeBtn:SetSize(18, 18)
resizeBtn:SetPoint("BOTTOMRIGHT", _G.DamageWindow, "BOTTOMRIGHT", -2, 2)
resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:GetParent():StartSizing("BOTTOMRIGHT")
    end
end)
resizeBtn:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:GetParent():StopMovingOrSizing()
    end
end)

-- Flat dark background
local bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0.09, 0.09, 0.13, 0.55)



-- Modern close button
local closeBtn = CreateFrame("Button", nil, _G.DamageWindow, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -2, -2)
closeBtn:SetScale(0.85)
local headerFont = "GameFontNormalSmall"

-- Dynamic columns and rows
local headers = {"Name", "Damage", "DPS"}
local headerObjs = {}
local function LayoutDamageWindow()
    local width = _G.DamageWindow:GetWidth()
    local colX = {
        18,
        math.floor(width * 0.41),
        math.floor(width * 0.74)
    }
    -- Layout headers
    for i, text in ipairs(headers) do
        if not headerObjs[i] then
            headerObjs[i] = _G.DamageWindow:CreateFontString(nil, "OVERLAY", headerFont)
            headerObjs[i]:SetTextColor(0.8, 0.8, 0.85)
            headerObjs[i]:SetText(text)
        end
        headerObjs[i]:SetPoint("TOPLEFT", colX[i], -12)
    end
    -- Layout rows
    local rowYStart = -30
    local rowWidth = width - 20
    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        if not row then
            row = {}
            row.bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
            row.bar = _G.DamageWindow:CreateTexture(nil, "ARTWORK")
            row.name = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.damage = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.dps = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tableRows[i] = row
        end
        row.bg:SetColorTexture(0, 0, 0, 0.15)
        row.bg:SetPoint("TOPLEFT", 10, rowYStart - (i-1)*22)
        row.bg:SetSize(rowWidth, 18)
        row.bar:SetPoint("TOPLEFT", 12, rowYStart - (i-1)*22)
        row.bar:SetHeight(16)
        row.bar:SetColorTexture(0.2, 0.6, 1, 1)
        -- Fontstrings
        row.name:SetPoint("LEFT", row.bg, "LEFT", 8, 0)
        row.damage:SetPoint("LEFT", row.bg, "LEFT", math.floor(rowWidth * 0.37), 0)
        row.dps:SetPoint("LEFT", row.bg, "LEFT", math.floor(rowWidth * 0.68), 0)
    end
end

for i = 1, NUM_ROWS do tableRows[i] = nil end -- clear for re-layout
LayoutDamageWindow()

_G.DamageWindow:HookScript("OnSizeChanged", LayoutDamageWindow)







-- Local implementation first

local RAID_CLASS_COLORS = RAID_CLASS_COLORS or _G.RAID_CLASS_COLORS or {}
local function GetClassColor(name)
    if not name then return 1,1,1 end
    local class
    if UnitExists and UnitClass then
        for i=1,40 do
            local unit = (i==1) and "player" or (IsInRaid() and "raid"..(i-1) or "party"..i)
            if UnitExists(unit) and UnitName(unit) == name then
                _, class = UnitClass(unit)
                break
            end
        end
    end
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 1,1,1
end


local function UpdateDamageWindow_local()
    -- Build a sorted list of group members by damage
    local sorted = {}
    local maxDamage = 0
    for name, data in pairs(_G.groupDamage or {}) do
        table.insert(sorted, {name=name, damage=data.damage or 0, dps=data.lastDPS or 0})
        if (data.damage or 0) > maxDamage then maxDamage = data.damage or 0 end
    end
    table.sort(sorted, function(a, b) return a.damage > b.damage end)

    local width = _G.DamageWindow:GetWidth()
    local rowWidth = width - 20
    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        local entry = sorted[i]
        if entry then
            row.name:SetText(entry.name)
            row.damage:SetText(entry.damage)
            row.dps:SetText(entry.dps)
            -- Bar width proportional to max damage, min 20px if damage > 0
            local minBarWidth = 20
            local barWidth = minBarWidth
            if maxDamage > 0 and entry.damage > 0 then
                barWidth = math.max(minBarWidth, math.floor((entry.damage / maxDamage) * (rowWidth - 22)))
                -- If window is extremely small, don't let bar overflow
                barWidth = math.min(barWidth, rowWidth - 22)
            end
            row.bar:SetWidth(barWidth)
            row.bar:SetHeight(16)
            row.bar:Show()
            -- Class color for name
            local r,g,b = GetClassColor(entry.name)
            row.name:SetTextColor(r,g,b)
            -- Bold font for self
            if entry.name == UnitName("player") then
                row.name:SetFontObject("GameFontNormalLarge")
            else
                row.name:SetFontObject("GameFontHighlight")
            end
            row.bg:Show()
            row.name:Show()
            row.damage:Show()
            row.dps:Show()
        else
            row.name:SetText("")
            row.damage:SetText("")
            row.dps:SetText("")
            row.bar:Hide()
            row.bg:Hide()
            row.name:Hide()
            row.damage:Hide()
            row.dps:Hide()
        end
    end
end

function UpdateDamageWindow()
    UpdateDamageWindow_local()
end
_G.UpdateDamageWindow = UpdateDamageWindow


local updateElapsed = 0
_G.DamageWindow:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then return end
    updateElapsed = updateElapsed + elapsed
    if updateElapsed > 0.2 then
        updateElapsed = 0
        UpdateDamageWindow()
    end
end)


-- Reset lastDPS when new combat starts, only if dungeonTracker is available
if dungeonTracker then
    local origOnEvent = dungeonTracker:GetScript("OnEvent")
    dungeonTracker:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            lastDPS = nil
        end
        if origOnEvent then
            origOnEvent(self, event, ...)
        end
    end)
end

function _G.DamageWindow:ShowDamageWindow()
    UpdateDamageWindow()
    self:Show()
end
