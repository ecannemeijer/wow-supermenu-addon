-- Character stats window
-- Zie Supermenu.lua voor slash command en SavedVariables

local statsFrame
local minimized = false

local function GetArmorReduction()
    local level = UnitLevel("player")
    local _, effectiveArmor = UnitArmor("player")
    local reduction = effectiveArmor / (effectiveArmor + 467.5 * level - 22167.5)
    reduction = reduction > 0 and reduction or 0
    reduction = reduction < 0.75 and reduction or 0.75
    return string.format("%.2f%%", reduction*100)
end

local function stat_tooltip(row_name)
    local tips = {
        ["Health"] = "Your current and maximum health.",
        ["Mana"] = "Your current and maximum primary resource for spells.",
        ["Strength"] = "Increases attack power for Warriors, Paladins, and Death Knights, and slightly increases block value.",
        ["Agility"] = "Increases critical strike chance, dodge chance, and armor for Rogues, Hunters, and Druids.",
        ["Stamina"] = "Increases your maximum health.",
        ["Intellect"] = "Increases mana pool and spell critical chance.",
        ["Spirit"] = "Increases health/mana regeneration when not casting spells.",
        ["Attack Power"] = "Determines the damage of your physical attacks.",
        ["Spell Power"] = "Determines the damage/healing of your spells.",
        ["Crit Chance"] = "Chance for your attacks and spells to critically hit for extra damage.",
        ["Hit Rating"] = "Increases your chance to hit with melee and spells.",
        ["Expertise"] = "Reduces the chance for your attacks to be dodged or parried.",
        ["Haste Rating"] = "Increases attack and casting speed.",
        ["Mastery Rating"] = "Improves your class mastery bonus.",
        ["Armor"] = "Reduces physical damage taken.\n\nPhysical damage reduction: "..GetArmorReduction(),
        ["Dodge"] = "Chance to avoid melee attacks completely.",
        ["Parry"] = "Chance to parry melee attacks.",
        ["Block"] = "Chance to block part of incoming melee attacks.",
        ["Resilience"] = "Reduces damage taken from players and their pets.",
        ["Fire"] = "Reduces fire spell damage taken.",
        ["Frost"] = "Reduces frost spell damage taken.",
        ["Arcane"] = "Reduces arcane spell damage taken.",
        ["Nature"] = "Reduces nature spell damage taken.",
        ["Shadow"] = "Reduces shadow spell damage taken.",
    }
    return tips[row_name] or ""
end

local categories = {
    { "Primary Stats", {
        { "Strength", function() return UnitStat("player", 1) end },
        { "Agility", function() return UnitStat("player", 2) end },
        { "Stamina", function() return UnitStat("player", 3) end },
        { "Intellect", function() return UnitStat("player", 4) end },
        { "Spirit", function() return UnitStat("player", 5) end },
    }},
    { "Combat Stats", {
        { "Attack Power", function()
            local base, pos, neg = UnitAttackPower("player")
            return base + pos + neg
        end },
        { "Spell Power", function() return GetSpellBonusDamage and GetSpellBonusDamage(2) or 0 end },
        { "Crit Chance", function() return string.format("%.2f%%", GetCritChance() or 0) end },
        { "Hit Rating", function() return GetCombatRating and GetCombatRating(6) or 0 end },
        { "Expertise", function() return GetCombatRating and GetCombatRating(23) or 0 end },
        { "Haste Rating", function() return GetCombatRating and GetCombatRating(18) or 0 end },
        { "Mastery Rating", function() return GetCombatRating and GetCombatRating(26) or 0 end },
    }},
    { "Defensive Stats", {
        { "Armor", function() return UnitArmor("player") end },
        { "Dodge", function() return string.format("%.2f%%", GetDodgeChance() or 0) end },
        { "Parry", function() return string.format("%.2f%%", GetParryChance() or 0) end },
        { "Block", function() return string.format("%.2f%%", GetBlockChance() or 0) end },
        { "Resilience", function() return GetCombatRating and GetCombatRating(15) or 0 end },
    }},
    { "Resistances", {
        { "Fire", function() return UnitResistance("player", 2) or 0 end },
        { "Frost", function() return UnitResistance("player", 4) or 0 end },
        { "Arcane", function() return UnitResistance("player", 6) or 0 end },
        { "Nature", function() return UnitResistance("player", 3) or 0 end },
        { "Shadow", function() return UnitResistance("player", 5) or 0 end },
    }},
}

local function getHealthMana()
    return {
        { "Health", function() return UnitHealth("player") .. " / " .. UnitHealthMax("player") end },
        { "Mana", function()
            local pt = UnitPowerType("player")
            local v = UnitPower("player", pt)
            local max = UnitPowerMax("player", pt)
            local n = pt == 0 and "Mana" or (pt == 1 and "Rage" or (pt == 2 and "Focus" or "Energy"))
            return v .. " / " .. max .. " " .. n
        end },
    }
end

local function ShowTooltip(self, statName)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(statName, 1, 1, 1)
    GameTooltip:AddLine(stat_tooltip(statName), nil, nil, nil, true)
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

function CreateStatsWindow()
    if statsFrame then
        return statsFrame
    end
    statsFrame = CreateFrame("Frame", "SupermenuStatsFrame", UIParent, "BackdropTemplate")
    statsFrame:SetSize(350, 520)
    statsFrame:SetPoint("CENTER", 200, 0)
    statsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, tileSize = 0, edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    statsFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    statsFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
    statsFrame:SetMovable(true)
    statsFrame:EnableMouse(true)
    statsFrame:RegisterForDrag("LeftButton")
    statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
    statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)
    statsFrame:SetFrameStrata("HIGH")

    -- Fancy title bar
    local titleBar = statsFrame:CreateTexture(nil, "OVERLAY")
    titleBar:SetColorTexture(0.18, 0.25, 0.42, 0.93)
    titleBar:SetPoint("TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", -8, -8)
    titleBar:SetHeight(38)

    local title = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    title:SetPoint("TOP", statsFrame, "TOP", 0, -20)
    title:SetText("Character Stats")
    title:SetTextColor(0.85, 0.95, 1)

    -- Close button
    local close = CreateFrame("Button", nil, statsFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", statsFrame, "TOPRIGHT", -5, -5)
    close:SetScale(1.1)

    -- Minimize button
    local minimizeBtn = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
    minimizeBtn:SetSize(24, 24)
    minimizeBtn:SetPoint("RIGHT", close, "LEFT", -2, 0)
    minimizeBtn:SetText("_")
    minimizeBtn:SetNormalFontObject("GameFontNormalLarge")
    minimizeBtn:SetHighlightFontObject("GameFontHighlightLarge")
    minimizeBtn:EnableMouse(true)
    minimizeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if minimized then
            GameTooltip:SetText("Maximize", 1, 1, 1)
        else
            GameTooltip:SetText("Minimize", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    minimizeBtn:SetScript("OnLeave", HideTooltip)

    -- Content area with scroll
    local scrollFrame = CreateFrame("ScrollFrame", nil, statsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 20, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", statsFrame, "BOTTOMRIGHT", -35, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    statsFrame.scrollFrame = scrollFrame
    statsFrame.content = content

    -- Draw Health/Mana
    local y = -5
    local healthMana = getHealthMana()
    for _, stat in ipairs(healthMana) do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", 0, y+5)
        row:SetSize(300, 22)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", row, "LEFT", 8, 0)
        label:SetText(stat[1]..":")
        label:SetTextColor(0.6, 0.9, 1)
        local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        value:SetText("...")
        value:SetTextColor(0.9, 0.95, 1)
        stat.label, stat.value = label, value

        -- Tooltip
        row:EnableMouse(true)
        row:SetScript("OnEnter", function() ShowTooltip(row, stat[1]) end)
        row:SetScript("OnLeave", HideTooltip)
        y = y - 22
    end

    -- Section loop
    for ci, cat in ipairs(categories) do
        local catName, statsTable = unpack(cat)
        -- Category header
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
        header:SetText(catName)
        if ci==1 then header:SetTextColor(0.95, 0.85, 0.23)
        elseif ci==2 then header:SetTextColor(0.23, 0.95, 0.40)
        elseif ci==3 then header:SetTextColor(0.25, 0.7, 1.0)
        else header:SetTextColor(0.8, 0.5, 1.0) end
        y = y - 22

        for _, stat in ipairs(statsTable) do
            local row = CreateFrame("Frame", nil, content)
            row:SetPoint("TOPLEFT", 0, y+5)
            row:SetSize(290, 18)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", row, "LEFT", 8, 0)
            label:SetText(stat[1]..":")
            label:SetTextColor(0.85,0.85,0.92)
            local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            value:SetText("...")
            value:SetTextColor(1,1,1)
            stat.label, stat.value = label, value

            -- Mouseover highlight and tooltip
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                label:SetTextColor(1,1,0.6)
                value:SetTextColor(1,0.95,0.7)
                ShowTooltip(row, stat[1])
            end)
            row:SetScript("OnLeave", function()
                label:SetTextColor(0.85,0.85,0.92)
                value:SetTextColor(1,1,1)
                HideTooltip()
            end)

            y = y - 18
        end
    end

    -- Stat updater
    statsFrame.UpdateStats = function()
        for _, stat in ipairs(healthMana) do
            local ok, val = pcall(stat[2])
            stat.value:SetText(ok and val or "?")
        end
        for _, cat in ipairs(categories) do
            for _, stat in ipairs(cat[2]) do
                local ok, val = pcall(stat[2])
                stat.value:SetText(ok and val or "?")
            end
        end
    end

    statsFrame:SetScript("OnShow", function(self)
        self:UpdateStats()
        if minimized then
            statsFrame.scrollFrame:Hide()
            statsFrame:SetHeight(62)
        else
            statsFrame.scrollFrame:Show()
            statsFrame:SetHeight(520)
        end
    end)
    statsFrame:Hide()

    -- Minimize/Maximize logic
    local function toggleMinimize()
        minimized = not minimized
        if minimized then
            statsFrame.scrollFrame:Hide()
            statsFrame:SetHeight(62)
            minimizeBtn:SetText("▣")
        else
            statsFrame.scrollFrame:Show()
            statsFrame:SetHeight(520)
            minimizeBtn:SetText("_")
        end
    end
    minimizeBtn:SetScript("OnClick", toggleMinimize)
    
    return statsFrame
end

function ShowCharacterStats()
    local statsWin = CreateStatsWindow()
    if statsWin:IsShown() then
        statsWin:Hide()
    else
        statsWin:Show()
        statsWin:UpdateStats()
    end
end
