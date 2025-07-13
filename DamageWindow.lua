 
print('Supermenu: DamageWindow.lua loaded')
-- Add a slash command to open the Damage window directly
SLASH_SUPERMENUDAMAGE1 = '/damage'
SlashCmdList['SUPERMENUDAMAGE'] = function()
    if _G.DamageWindow then
        _G.DamageWindow:Show()
    else
        print("[Supermenu] Damage window not available.")
    end
end


_G.DamageWindow = CreateFrame("Frame", "SupermenuDamageWindow", UIParent)
DamageWindow = _G.DamageWindow
DamageWindow:SetSize(340, 220)
    DamageWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    DamageWindow:SetMovable(true)
    DamageWindow:EnableMouse(true)
    DamageWindow:RegisterForDrag("LeftButton")
    DamageWindow:SetScript("OnDragStart", function(self) if not DamageWindow.isLocked then self:StartMoving() end end)
    DamageWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Lock/Unlock button
    local lockBtn = CreateFrame("Button", nil, DamageWindow)
    lockBtn:SetSize(60, 18)
    lockBtn:ClearAllPoints()
    lockBtn:SetPoint("BOTTOMLEFT", DamageWindow, "BOTTOMLEFT", 2, 2)
    lockBtn.text = lockBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockBtn.text:SetAllPoints()
    lockBtn.text:SetJustifyH("LEFT")
    DamageWindow.isLocked = false

    local function UpdateLockState()
        if DamageWindow.isLocked then
            DamageWindow:EnableMouse(false)
            lockBtn.text:SetText("Unlock")
        else
            DamageWindow:EnableMouse(true)
            lockBtn.text:SetText("Lock")
        end
    end

    lockBtn:SetScript("OnClick", function()
        DamageWindow.isLocked = not DamageWindow.isLocked
        UpdateLockState()
    end)
    lockBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(DamageWindow.isLocked and "Click to unlock window" or "Click to lock window", 1, 1, 1)
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UpdateLockState()
    DamageWindow:SetResizable(true)
DamageWindow:SetFrameStrata("DIALOG")
DamageWindow:SetFrameLevel(10)
if not DamageWindow.bg then
    DamageWindow.bg = DamageWindow:CreateTexture(nil, "BACKGROUND")
    DamageWindow.bg:SetAllPoints(true)
    DamageWindow.bg:SetColorTexture(0.09, 0.09, 0.13, 0.85)
end
DamageWindow:Hide()

local lastDPS = nil
-- Use the global groupDamage table set by DungeonTracking.lua
local groupDamage = _G.groupDamage or {} -- [name] = {damage=0, startTime=0, inCombat=false, lastDPS=0}
local tableRows = {}
local NUM_ROWS = 8
-- ...existing code...

-- Place IsRealPlayer and UpdateDamageWindow after mode and UI setup

local function IsRealPlayer(name)
    if not name then return false end
    local lower = string.lower(name)
    if lower:find("dummy") or lower:find("training") or lower == "world" or lower == "unknown" then return false end
    -- Exclude common mob names, expand as needed
    if lower:find("target") or lower:find("boss") then return false end
    -- Only allow group/raid members
    for i=1,4 do if name == UnitName("party"..i) then return true end end
    for i=1,40 do if name == UnitName("raid"..i) then return true end end
    if name == UnitName("player") then return true end
    return false
end

local function UpdateDamageWindow()
    -- ...existing code for all modes...
    print("Supermenu: UpdateDamageWindow called")
    if mode == "taken" then
        -- Show group/raid members' damage taken, filter out dummies/world/mobs
        local data = {}
        for name, v in pairs(_G.groupDamage or {}) do
            if IsRealPlayer(name) then
                table.insert(data, {name=name, taken=v.taken or 0})
            end
        end
        table.sort(data, function(a, b) return (a.taken or 0) > (b.taken or 0) end)
        for i = 1, NUM_ROWS do
            local row = tableRows[i]
            local entry = data[i]
            if entry and entry.taken > 0 then
                print("Supermenu: entry=", entry and entry.name, entry and entry.taken, entry and entry.damage, entry and entry.dps)
                row.name:SetText(entry.name)
                row.taken:SetText(entry.taken)
                row.bg:Show()
                row.name:Show()
                row.taken:Show()
                row.bar:Show()
                -- Bar width proportional to max taken
                local maxTaken = data[1] and data[1].taken or 1
                local barWidth = math.max(1, math.floor((row.bg:GetWidth()-4) * (entry.taken / maxTaken)))
                row.bar:SetWidth(barWidth)
                row.bar:SetColorTexture(1, 0.3, 0.3, 0.85)
            else
                row.bg:Hide()
                row.name:Hide()
                row.taken:Hide()
                row.bar:Hide()
            end
        end
        return
    end
    -- ...rest of UpdateDamageWindow for other modes...
end

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



local closeBtn = CreateFrame("Button", nil, _G.DamageWindow)
closeBtn:SetSize(16, 16)
closeBtn:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -24, -2) -- moved further right for more spacing
closeBtn:SetFrameStrata("DIALOG")
closeBtn:SetFrameLevel(100)
closeBtn:Show()
local closeIcon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up" -- stylized red X for close
closeBtn.icon = closeBtn:CreateTexture(nil, "ARTWORK", nil, 1)
closeBtn.icon:SetAllPoints()
closeBtn.icon:SetTexture(closeIcon)
closeBtn.icon:SetDesaturated(false)
closeBtn.icon:Show()
closeBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
closeBtn:SetScript("OnClick", function()
    _G.DamageWindow:Hide()
end)
closeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText("Close", 1, 1, 1)
    GameTooltip:Show()
end)
closeBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Reset button (icon style)
local resetBtn = CreateFrame("Button", nil, _G.DamageWindow)
resetBtn:SetSize(16, 16)
resetBtn:SetPoint("TOPLEFT", _G.DamageWindow, "TOPLEFT", 6, -2) -- align reset to left
resetBtn:SetFrameStrata("DIALOG")
resetBtn:SetFrameLevel(100)
resetBtn:Show()
local resetIcon = "Interface\\Buttons\\UI-GroupLoot-Coin-Up" -- gold coin icon, can be changed
resetBtn.icon = resetBtn:CreateTexture(nil, "ARTWORK", nil, 1)
resetBtn.icon:SetAllPoints()
resetBtn.icon:SetTexture(resetIcon)
resetBtn.icon:SetDesaturated(false)
resetBtn.icon:Show()
resetBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
resetBtn:SetScript("OnClick", function()
    -- Reset DPS history
    if SupermenuDB and SupermenuDB.DungeonRuns then
        wipe(SupermenuDB.DungeonRuns)
    end
    -- Reset real-time DPS
    if _G.groupDamage then
        for k in pairs(_G.groupDamage) do
            _G.groupDamage[k].damage = 0
            _G.groupDamage[k].lastDPS = 0
            _G.groupDamage[k].startTime = GetTime()
        end
    end
    if dungeonTracker then
        dungeonTracker.damageDone = 0
        dungeonTracker.damageTaken = 0
        dungeonTracker.startTime = GetTime()
    end
    UpdateDamageWindow()
end)
resetBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText("Reset DPS & History", 1, 1, 1)
    GameTooltip:Show()
end)
resetBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
local headerFont = "GameFontNormalSmall"

-- Toggle button for history/current
local mode = "current" -- or "history" or "taken"



-- Toggle buttons for mode switching
local toggleBtns = {}
local modeIcons = {
    current = "Interface\\Icons\\Ability_Warrior_SavageBlow", -- sword icon
    history = "Interface\\Icons\\INV_Misc_Note_05", -- parchment/note icon
    taken = "Interface\\Icons\\Ability_Warrior_ShieldBash", -- shield icon
}
local modeOrder = {"current", "history", "taken"}
for i, m in ipairs(modeOrder) do
    local btn = CreateFrame("Button", nil, _G.DamageWindow)
    btn:SetSize(16, 16)
    btn:SetPoint("TOPLEFT", _G.DamageWindow, "TOPLEFT", 32 + (i-1)*24, -2) -- align mode/history/taken icons to left, after reset
    btn:SetFrameStrata("DIALOG")
    btn:SetFrameLevel(100)
    btn:Show()
    btn.icon = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(modeIcons[m])
    btn.icon:SetDesaturated(m ~= mode)
    btn.icon:Show()
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn:SetScript("OnClick", function()
        mode = m
        for j, b in ipairs(toggleBtns) do
            b.icon:SetDesaturated(modeOrder[j] ~= mode)
        end
        UpdateDamageWindow()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        if m == "current" then
            GameTooltip:SetText("Show Damage Done", 1, 1, 1)
        elseif m == "history" then
            GameTooltip:SetText("Show History", 1, 1, 1)
        elseif m == "taken" then
            GameTooltip:SetText("Show Damage Taken", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    toggleBtns[i] = btn
end

-- Dynamic columns and rows

local headers = {"Name", "Damage", "DPS"}
local historyHeaders = {"#", "Name", "Damage", "DPS"}
local takenHeaders = {"Name", "Taken"}
local headerObjs = {}



local function LayoutDamageWindow()
    local width = _G.DamageWindow:GetWidth()
    local colX, useHeaders
    if mode == "history" then
        -- #, Name, Damage, DPS
        local nameColWidth = math.floor(width * 0.38)
        colX = {18, 48, 48 + nameColWidth + 8, math.floor(width * 0.80)}
        useHeaders = historyHeaders
    elseif mode == "taken" then
        colX = {18, math.floor(width * 0.60)}
        useHeaders = takenHeaders
    else
        -- Move DPS column further left to avoid overlap with close button
        colX = {18, math.floor(width * 0.41), math.floor(width * 0.68)}
        useHeaders = headers
    end
    -- Layout headers
    for i, text in ipairs(useHeaders) do
        if not headerObjs[i] then
            headerObjs[i] = _G.DamageWindow:CreateFontString(nil, "OVERLAY", headerFont)
            headerObjs[i]:SetTextColor(0.8, 0.8, 0.85)
            headerObjs[i]:SetText(text)
        else
            headerObjs[i]:SetText(text)
        end
        -- Align headers: left for #/Name, right for Damage/DPS
        if i == 1 or (mode == "history" and i == 2) or (mode == "taken" and i == 1) then
            headerObjs[i]:ClearAllPoints()
            headerObjs[i]:SetPoint("TOPLEFT", colX[i], -36)
            headerObjs[i]:SetJustifyH("LEFT")
        else
            headerObjs[i]:ClearAllPoints()
            headerObjs[i]:SetPoint("TOPRIGHT", _G.DamageWindow, "TOPRIGHT", -math.floor(width * (i == 3 and 0.32 or 0.06)) - 10, -36)
            headerObjs[i]:SetJustifyH("RIGHT")
        end
    end
    -- Hide unused headers
    for i = #useHeaders+1, #headerObjs do
        if headerObjs[i] then headerObjs[i]:SetText("") end
    end
    -- Layout rows
    local rowYStart = -54
    local rowWidth = width - 20
    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        if not row then
            row = {}
            row.bg = _G.DamageWindow:CreateTexture(nil, "BACKGROUND")
            row.bar = _G.DamageWindow:CreateTexture(nil, "ARTWORK")
            row.classIcon = _G.DamageWindow:CreateTexture(nil, "OVERLAY", nil, 7)
            row.classIcon:SetSize(16, 16)
            row.name = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.extra = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal") -- for history name
            row.damage = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.dps = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.taken = _G.DamageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tableRows[i] = row
        end
        row.bg:SetColorTexture(0, 0, 0, 0.15)
        row.bg:SetPoint("TOPLEFT", 10, rowYStart - (i-1)*22)
        row.bg:SetSize(rowWidth, 18)
        row.bar:SetPoint("LEFT", row.classIcon, "RIGHT", 2, 0)
        row.bar:SetHeight(16)
        row.bar:SetColorTexture(0.2, 0.6, 1, 1)
        -- Fontstrings
        if mode == "history" then
            -- #
            row.classIcon:ClearAllPoints()
            row.classIcon:SetPoint("LEFT", row.bg, "LEFT", 4, 0)
            row.classIcon:Show()
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.classIcon, "RIGHT", 4, 0)
            row.name:SetJustifyH("LEFT")
            -- Name (mob/boss/zone)
            row.extra:ClearAllPoints()
            row.extra:SetPoint("LEFT", row.bg, "LEFT", 38, 0)
            row.extra:SetWidth(math.floor(rowWidth * 0.38))
            row.extra:SetJustifyH("LEFT")
            row.extra:SetWordWrap(false)
            -- Damage
            row.damage:ClearAllPoints()
            row.damage:SetPoint("RIGHT", row.bg, "RIGHT", -math.floor(rowWidth * 0.32), 0)
            row.damage:SetJustifyH("RIGHT")
            -- DPS
            row.dps:ClearAllPoints()
            row.dps:SetPoint("RIGHT", row.bg, "RIGHT", -math.floor(rowWidth * 0.15), 0) -- shift DPS value further left
            row.dps:SetJustifyH("RIGHT")
            -- Bar: start after name column
            row.bar:ClearAllPoints()
            row.bar:SetPoint("LEFT", row.classIcon, "RIGHT", 2, 0)
            if row.taken then row.taken:Hide() end
        elseif mode == "taken" then
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.bg, "LEFT", 8, 0)
            row.name:SetJustifyH("LEFT")
            row.taken:ClearAllPoints()
            row.taken:SetPoint("RIGHT", row.bg, "RIGHT", -math.floor(rowWidth * 0.06), 0)
            row.taken:SetJustifyH("RIGHT")
            if row.extra then row.extra:Hide() end
            if row.damage then row.damage:Hide() end
            if row.dps then row.dps:Hide() end
        else
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.bg, "LEFT", 8, 0)
            row.name:SetJustifyH("LEFT")
            row.damage:ClearAllPoints()
            row.damage:SetPoint("RIGHT", row.bg, "RIGHT", -math.floor(rowWidth * 0.32), 0)
            row.damage:SetJustifyH("RIGHT")
            row.dps:ClearAllPoints()
            row.dps:SetPoint("RIGHT", row.bg, "RIGHT", -math.floor(rowWidth * 0.15), 0) -- shift DPS value further left
            row.dps:SetJustifyH("RIGHT")
            if row.extra then row.extra:Hide() end
            if row.taken then row.taken:Hide() end
        end
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
    if mode == "taken" then
        -- Show group/raid members by damage taken
        local sorted = {}
        local maxTaken = 0
        for name, data in pairs(_G.groupDamage or {}) do
            local taken = data.taken or 0
            table.insert(sorted, {name=name, taken=taken})
            if taken > maxTaken then maxTaken = taken end
        end
        table.sort(sorted, function(a, b) return a.taken > b.taken end)
        local width = _G.DamageWindow:GetWidth()
        local rowWidth = width - 20
        for i = 1, NUM_ROWS do
            local row = tableRows[i]
            local entry = sorted[i]
            if entry then
                -- Set class icon
                local class = nil
                if entry.name == UnitName("player") then
                    class = select(2, UnitClass("player"))
                else
                    for i=1,4 do if entry.name == UnitName("party"..i) then class = select(2, UnitClass("party"..i)) break end end
                    if not class and GetNumGroupMembers and GetRaidRosterInfo then
                        local num = GetNumGroupMembers()
                        for j=1,num do
                            local n, _, _, _, _, classFile = GetRaidRosterInfo(j)
                            if n and n == entry.name then class = classFile break end
                        end
                    end
            if class and CLASS_ICON_TCOORDS[class] then
                row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
                row.classIcon:SetDrawLayer("OVERLAY", 7)
                row.classIcon:SetAlpha(1)
                row.classIcon:Show()
            else
                row.classIcon:SetTexture(nil)
                row.classIcon:SetAlpha(1)
                row.classIcon:Hide()
            end
                if row.damage then row.damage:Hide() end
                if row.dps then row.dps:Hide() end
                if row.extra then row.extra:Hide() end
            end
        else
            row.name:SetText("")
            row.taken:SetText("")
            row.bar:Hide()
            row.bg:Hide()
            row.name:Hide()
            row.taken:Hide()
            if row.damage then row.damage:Hide() end
            if row.dps then row.dps:Hide() end
            if row.extra then row.extra:Hide() end
        end
        end
        return
    end
    if mode == "history" then
        -- Show last 10 encounters (from SupermenuDB.DungeonRuns)
        local runs = (SupermenuDB and SupermenuDB.DungeonRuns) or {}
        local width = _G.DamageWindow:GetWidth()
        local rowWidth = width - 20
        local count = math.min(NUM_ROWS, #runs)
        -- Find max damage for bar scaling
        local maxDamage = 0
        for j = #runs - count + 1, #runs do
            local edmg = tonumber(string.match(runs[j], "Damage Done: (%d+)") or 0)
            if edmg > maxDamage then maxDamage = edmg end
        end
        for i = 1, NUM_ROWS do
            local row = tableRows[i]
            local idx = #runs - count + i
            if i <= count and runs[idx] then
                local entry = runs[idx]
                local dmg = tonumber(string.match(entry, "Damage Done: (%d+)") or 0)
                local dur = tonumber(string.match(entry, "Duration: (%d+)s") or 1)
                local mob = string.match(entry, "Mob: ([^|]+)")
                local boss = string.match(entry, "Boss: ([^|]+)")
                local zname = string.match(entry, "Zone: ([^|]+)") or "-"
                local nameToShow = mob or boss or zname
                local dps = math.floor(dmg / math.max(1, dur))
                row.name:SetText(tostring(i))
                if row.extra then
                    row.extra:SetText(nameToShow)
                    row.extra:Show()
                end
                row.damage:SetText(dps)
                row.dps:SetText(dmg)
                row.damage:SetText(dps)
                row.dps:SetText(dmg)
                row.damage:SetFontObject("GameFontNormal")
                row.damage:SetTextColor(1,1,1)
                row.damage:Show()
                row.damage:SetJustifyH("RIGHT")
                row.damage:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                    GameTooltip:SetText(nameToShow, 1, 1, 1)
                    GameTooltip:Show()
                end)
                row.damage:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                -- Bar width proportional to max damage, min 20px, but bar starts after name column
                local minBarWidth = 20
                local barStart = 38 + math.floor(rowWidth * 0.38) + 8
                local barMaxWidth = rowWidth - barStart - 10
                local barWidth = minBarWidth
                if maxDamage > 0 and dmg > 0 then
                    barWidth = math.max(minBarWidth, math.floor((dmg / maxDamage) * barMaxWidth))
                    barWidth = math.min(barWidth, barMaxWidth)
                end
                row.bar:SetWidth(barWidth)
                row.bar:SetHeight(16)
                row.bar:Show()
                row.bar:SetColorTexture(0.2, 0.6, 1, 1)
                row.name:SetTextColor(1,1,1)
                row.name:SetFontObject("GameFontHighlight")
                row.bg:Show()
                row.name:Show()
                if row.extra then row.extra:Show() end
                row.damage:Show()
                row.dps:Show()
            else
                row.name:SetText("")
                if row.extra then row.extra:SetText(""); row.extra:Hide() end
                row.damage:SetText("")
                row.dps:SetText("")
                row.bar:Hide()
                row.bg:Hide()
                row.name:Hide()
                if row.extra then row.extra:Hide() end
                row.damage:Hide()
                row.dps:Hide()
            end
        end
        return
    end
    -- Default: current DPS table
    -- Build a sorted list of group members by damage
    local sorted = {}
    local maxDamage = 0
    for name, data in pairs(_G.groupDamage or {}) do
        table.insert(sorted, {name=name, damage=data.damage or 0, dps=data.lastDPS or 0})
        if (data.damage or 0) > maxDamage then maxDamage = data.damage or 0 end
        -- Track taken for new tab
        if not data.taken then data.taken = 0 end
    end
    table.sort(sorted, function(a, b) return a.damage > b.damage end)

    local width = _G.DamageWindow:GetWidth()
    local rowWidth = width - 20
    for i = 1, NUM_ROWS do
        local row = tableRows[i]
        local entry = sorted[i]
        if entry then
            -- Set class icon
            local class = nil
            -- Try to find the unit for this name in party or raid
            if entry.name == UnitName("player") then
                class = select(2, UnitClass("player"))
            else
                -- Check party
                for j=1,4 do
                    local unit = "party"..j
                    if UnitExists(unit) and UnitName(unit) == entry.name then
                        class = select(2, UnitClass(unit))
                        break
                    end
                end
                -- Check raid if not found
                if not class and IsInRaid() then
                    for j=1,40 do
                        local unit = "raid"..j
                        if UnitExists(unit) and UnitName(unit) == entry.name then
                            class = select(2, UnitClass(unit))
                            break
                        end
                    end
                end
                -- Fallback: use GetRaidRosterInfo if still not found
                if not class and GetNumGroupMembers and GetRaidRosterInfo then
                    local num = GetNumGroupMembers()
                    for j=1,num do
                        local n, _, _, _, _, classFile = GetRaidRosterInfo(j)
                        if n and n == entry.name then class = classFile break end
                    end
                end
            end
            if class and CLASS_ICON_TCOORDS[class] then
                row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
                row.classIcon:SetDrawLayer("OVERLAY", 7)
                row.classIcon:SetAlpha(1)
                row.classIcon:Show()
            else
                row.classIcon:SetTexture(nil)
                row.classIcon:SetAlpha(1)
                row.classIcon:Hide()
            end
            row.classIcon:ClearAllPoints()
            row.classIcon:SetPoint("LEFT", row.bg, "LEFT", 4, 0)
            row.classIcon:SetSize(16, 16)
            row.classIcon:Show()
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.classIcon, "RIGHT", 4, 0)
            row.name:SetText(entry.name)
            row.damage:SetText(entry.dps)
            row.dps:SetText(entry.damage)
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
            -- Bar: class color
            local r,g,b = GetClassColor(entry.name)
            row.bar:SetColorTexture(r, g, b, 1)
            -- Name: white for all except priest, priest gets light yellow
            local classForText = nil
            if entry.name == UnitName("player") then
                classForText = select(2, UnitClass("player"))
            else
                for j=1,4 do
                    local unit = "party"..j
                    if UnitExists(unit) and UnitName(unit) == entry.name then
                        classForText = select(2, UnitClass(unit))
                        break
                    end
                end
                if not classForText and IsInRaid() then
                    for j=1,40 do
                        local unit = "raid"..j
                        if UnitExists(unit) and UnitName(unit) == entry.name then
                            classForText = select(2, UnitClass(unit))
                            break
                        end
                    end
                end
                if not classForText and GetNumGroupMembers and GetRaidRosterInfo then
                    local num = GetNumGroupMembers()
                    for j=1,num do
                        local n, _, _, _, _, classFile = GetRaidRosterInfo(j)
                        if n and n == entry.name then classForText = classFile break end
                    end
                end
            end
            if classForText == "PRIEST" then
                row.name:SetTextColor(0.3, 0.3, 0.3)
            else
                row.name:SetTextColor(1, 1, 1)
            end
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
            row.classIcon:SetTexture(nil)
            row.classIcon:Hide()
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
