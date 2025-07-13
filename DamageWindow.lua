

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

_G["DamageWindow"] = CreateFrame("Frame", "SupermenuDamageWindow", UIParent, "BasicFrameTemplateWithInset")
DamageWindow = _G["DamageWindow"]
-- Use only the global DamageWindow


_G.DamageWindow:SetSize(340, 240)
_G.DamageWindow:SetPoint("CENTER")
_G.DamageWindow:Hide()
_G.DamageWindow:SetMovable(true)
_G.DamageWindow:EnableMouse(true)
_G.DamageWindow:RegisterForDrag("LeftButton")
_G.DamageWindow:SetScript("OnDragStart", _G.DamageWindow.StartMoving)
_G.DamageWindow:SetScript("OnDragStop", _G.DamageWindow.StopMovingOrSizing)
_G.DamageWindow.title = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
_G.DamageWindow.title:SetPoint("TOP", 0, -10)
_G.DamageWindow.title:SetText("Group Damage & DPS")
-- Table headers
local headerFont = "GameFontNormal"
local colX = {20, 150, 250}
local headers = {"Name", "Damage", "DPS"}
for i, text in ipairs(headers) do
    local header = _G.DamageWindow:CreateFontString(nil, "OVERLAY", headerFont)
    header:SetPoint("TOPLEFT", colX[i], -40)
    header:SetText(text)
end

-- Table rows
local rowYStart = -60 -- Start just below headers
for i = 1, NUM_ROWS do
    local row = {}
    row.bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
    row.bg:SetColorTexture(i % 2 == 0 and 0.15 or 0.08, 0.08, 0.08, 0.7)
    row.bg:SetPoint("TOPLEFT", 10, rowYStart - (i-1)*20)
    row.bg:SetSize(320, 20)
    row.name = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.bg, "LEFT", 10, 0)
    row.damage = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.damage:SetPoint("LEFT", row.bg, "LEFT", 140, 0)
    row.dps = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.dps:SetPoint("LEFT", row.bg, "LEFT", 240, 0)
    tableRows[i] = row
end
local closeBtn = CreateFrame("Button", nil, _G.DamageWindow, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -5, -5)






-- Local implementation first
local function UpdateDamageWindow_local()
    -- Build a sorted list of group members by damage
    local sorted = {}
    -- Always use the global groupDamage table for live updates
    for name, data in pairs(_G.groupDamage or {}) do
        table.insert(sorted, {name=name, damage=data.damage or 0, dps=data.lastDPS or 0})
    end
    table.sort(sorted, function(a, b) return a.damage > b.damage end)

    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        local entry = sorted[i]
        if entry then
            row.name:SetText(entry.name)
            row.damage:SetText(entry.damage)
            row.dps:SetText(entry.dps)
            if entry.name == UnitName("player") then
                row.name:SetTextColor(0,1,0)
            else
                row.name:SetTextColor(1,1,1)
            end
            row.bg:Show()
            row.name:Show()
            row.damage:Show()
            row.dps:Show()
        else
            row.name:SetText("")
            row.damage:SetText("")
            row.dps:SetText("")
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
