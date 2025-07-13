
-- Dungeon run tracking en logging
-- Zie Supermenu.lua voor slash command en SavedVariables

-- Hier komt de WriteDungeonRunLog functie en dungeonTracker
-- (Wordt in de volgende stap ingevuld)

-- Dungeon tracking logic
-- Zie Supermenu.lua voor SavedVariables

local function WriteDungeonRunLog(data)
    if not SupermenuDB.DungeonRuns then SupermenuDB.DungeonRuns = {} end
    table.insert(SupermenuDB.DungeonRuns, data)
    -- Beperk tot de laatste 200 runs om SavedVariables niet te groot te maken
    if #SupermenuDB.DungeonRuns > 200 then
        table.remove(SupermenuDB.DungeonRuns, 1)
    end
end

dungeonTracker = CreateFrame("Frame")
dungeonTracker.inCombat = false
dungeonTracker.damageTaken = 0
dungeonTracker.damageDone = 0
dungeonTracker.zoneName = "World"
dungeonTracker.startTime = 0

dungeonTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
dungeonTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
dungeonTracker:RegisterEvent("PLAYER_REGEN_DISABLED")
dungeonTracker:RegisterEvent("PLAYER_REGEN_ENABLED")



dungeonTracker.ShowDamageWindow = function(self)
    if _G.DamageWindow and _G.DamageWindow.ShowDamageWindow then
        _G.DamageWindow:ShowDamageWindow()
    else
        print("[Supermenu] Damage window not available. DamageWindow=", tostring(_G.DamageWindow), "ShowDamageWindow=", tostring(_G.DamageWindow and _G.DamageWindow.ShowDamageWindow))
    end
end

dungeonTracker:SetScript("OnEvent", function(self, event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        local zone = GetRealZoneText() or "World"
        self.zoneName = zone
        self.damageTaken = 0
        self.damageDone = 0
        self.startTime = GetTime()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat
        self.inCombat = true
        self.damageTaken = 0
        self.damageDone = 0
        self.startTime = GetTime()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Left combat, log the run
        if self.inCombat then
            local playerName = UnitName("player")
            local realm = GetRealmName()
            local duration = GetTime() - self.startTime
            local timestamp = date("%Y-%m-%d %H:%M:%S")
            local logLine = string.format("[%s] %s-%s | Zone: %s | Duration: %ds | Damage Done: %d | Damage Taken: %d",
                timestamp, playerName, realm, self.zoneName, duration, self.damageDone, self.damageTaken)
            WriteDungeonRunLog(logLine)
            self.inCombat = false
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, _, _, _, amount = CombatLogGetCurrentEventInfo()
        local relevant = (subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE")
        -- Track damage taken for player only
        if destGUID == UnitGUID("player") and relevant then
            self.damageTaken = self.damageTaken + (amount or 0)
        end
        -- Track damage done for all group/raid members
        if relevant and sourceName then
            if not _G.groupDamage then _G.groupDamage = {} end
            local g = _G.groupDamage
            if not g[sourceName] then
                g[sourceName] = {damage=0, startTime=GetTime(), inCombat=true, lastDPS=0}
            end
            local data = g[sourceName]
            data.damage = (data.damage or 0) + (amount or 0)
            if data.inCombat then
                local dur = GetTime() - (data.startTime or GetTime())
                data.lastDPS = math.floor(data.damage / math.max(dur,1) + 0.5)
            end
            -- Also update your own legacy fields for compatibility
            if sourceGUID == UnitGUID("player") then
                self.damageDone = self.damageDone + (amount or 0)
            end
            if DamageWindow and DamageWindow:IsShown() and UpdateDamageWindow then
                UpdateDamageWindow()
            end
        end
    end
end)
