

local lastDPS = nil
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


_G.DamageWindow:SetSize(260, 110)
_G.DamageWindow:SetPoint("CENTER")
_G.DamageWindow:Hide()
_G.DamageWindow:SetMovable(true)
_G.DamageWindow:EnableMouse(true)
_G.DamageWindow:RegisterForDrag("LeftButton")
_G.DamageWindow:SetScript("OnDragStart", _G.DamageWindow.StartMoving)
_G.DamageWindow:SetScript("OnDragStop", _G.DamageWindow.StopMovingOrSizing)
_G.DamageWindow.title = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
_G.DamageWindow.title:SetPoint("TOP", 0, -10)
_G.DamageWindow.title:SetText("Damage & DPS")
_G.DamageWindow.damageText = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
_G.DamageWindow.damageText:SetPoint("TOPLEFT", 20, -40)
_G.DamageWindow.dpsText = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
_G.DamageWindow.dpsText:SetPoint("TOPLEFT", 20, -70)
local closeBtn = CreateFrame("Button", nil, _G.DamageWindow, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -5, -5)




local function UpdateDamageWindow()
    local damage, duration, name = GetDamageStats()
    local dpsText
    if dungeonTracker and dungeonTracker.inCombat then
        local dps = math.floor(damage / math.max(duration,1) + 0.5)
        dpsText = "DPS: |cffffffff"..dps.."|r"
        lastDPS = dps
    elseif lastDPS then
        dpsText = "DPS: |cffffffff"..lastDPS.."|r (last)"
    else
        dpsText = "DPS: -"
    end
    _G.DamageWindow.title:SetText("Damage & DPS - "..(name or "-"))
    _G.DamageWindow.damageText:SetText("Total Damage: |cffffffff"..damage.."|r")
    _G.DamageWindow.dpsText:SetText(dpsText)
end

function UpdateDamageWindow()
    local damage, duration, name = GetDamageStats()
    local dpsText
    if dungeonTracker and dungeonTracker.inCombat then
        local dps = math.floor(damage / math.max(duration,1) + 0.5)
        dpsText = "DPS: |cffffffff"..dps.."|r"
        lastDPS = dps
    elseif lastDPS then
        dpsText = "DPS: |cffffffff"..lastDPS.."|r (last)"
    else
        dpsText = "DPS: -"
    end
    _G.DamageWindow.title:SetText("Damage & DPS - "..(name or "-"))
    _G.DamageWindow.damageText:SetText("Total Damage: |cffffffff"..damage.."|r")
    _G.DamageWindow.dpsText:SetText(dpsText)
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
