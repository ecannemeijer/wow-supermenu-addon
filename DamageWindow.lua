

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
_G.DamageWindow:SetScript("OnDragStart", _G.DamageWindow.StartMoving)
_G.DamageWindow:SetScript("OnDragStop", _G.DamageWindow.StopMovingOrSizing)

-- Flat dark background
local bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0.09, 0.09, 0.13, 0.55)



-- Modern close button
local closeBtn = CreateFrame("Button", nil, _G.DamageWindow, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -2, -2)
closeBtn:SetScale(0.85)
local headerFont = "GameFontNormalSmall"
local colX = {18, 140, 250}
local headers = {"Name", "Damage", "DPS"}
for i, text in ipairs(headers) do
    local header = _G.DamageWindow:CreateFontString(nil, "OVERLAY", headerFont)
    header:SetPoint("TOPLEFT", colX[i], -12)
    header:SetText(text)
    header:SetTextColor(0.8, 0.8, 0.85)
end

-- Table rows
local rowYStart = -30 -- Start just below headers
for i = 1, NUM_ROWS do
    local row = {}
    -- Row background for mouseover (bottom layer)
    row.bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
    row.bg:SetColorTexture(0, 0, 0, 0.15)
    row.bg:SetPoint("TOPLEFT", 10, rowYStart - (i-1)*22)
    row.bg:SetSize(320, 18)
    -- Bar background (damage bar, above bg)
    row.bar = _G.DamageWindow:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("TOPLEFT", 12, rowYStart - (i-1)*22)
    row.bar:SetSize(2, 16) -- width set dynamically, min 2
    row.bar:SetColorTexture(0.2, 0.6, 1, 0.85)
    -- Fontstrings (above bar)
    row.name = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.bg, "LEFT", 8, 0)
    row.damage = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.damage:SetPoint("LEFT", row.bg, "LEFT", 130, 0)
    row.dps = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.dps:SetPoint("LEFT", row.bg, "LEFT", 220, 0)
    tableRows[i] = row
end







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

    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        local entry = sorted[i]
        if entry then
            row.name:SetText(entry.name)
            row.damage:SetText(entry.damage)
            row.dps:SetText(entry.dps)
            -- Bar width proportional to max damage, min 2px if damage > 0
            local barWidth = 1
            if maxDamage > 0 and entry.damage > 0 then
                barWidth = math.max(2, math.floor((entry.damage / maxDamage) * 298))
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
