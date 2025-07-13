-- Dungeon Lockouts window
-- Zie Supermenu.lua voor slash command en SavedVariables

local dungeonFrame
function ShowDungeonWindow()
    if dungeonFrame and dungeonFrame:IsShown() then
        dungeonFrame:Hide()
        return
    end
    if not dungeonFrame then
        dungeonFrame = CreateFrame("Frame", "SupermenuDungeonFrame", UIParent, "BackdropTemplate")
        dungeonFrame:SetSize(420, 400)
        dungeonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dungeonFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, tileSize = 0, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        dungeonFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        dungeonFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
        dungeonFrame:SetFrameStrata("HIGH")
        dungeonFrame:SetMovable(true)
        dungeonFrame:EnableMouse(true)
        dungeonFrame:RegisterForDrag("LeftButton")
        dungeonFrame:SetScript("OnDragStart", dungeonFrame.StartMoving)
        dungeonFrame:SetScript("OnDragStop", dungeonFrame.StopMovingOrSizing)

        local title = dungeonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        title:SetPoint("TOP", dungeonFrame, "TOP", 0, -20)
        title:SetText("Today's Dungeon Lockouts")
        title:SetTextColor(0.85, 0.95, 1)

        local closeBtn = CreateFrame("Button", nil, dungeonFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", dungeonFrame, "TOPRIGHT", -8, -8)
        closeBtn:SetScript("OnClick", function() dungeonFrame:Hide() end)

        -- Scroll area for dungeon list
        local scrollFrame = CreateFrame("ScrollFrame", nil, dungeonFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 20, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", dungeonFrame, "BOTTOMRIGHT", -35, 20)
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(1, 1)
        scrollFrame:SetScrollChild(content)
        dungeonFrame.scrollFrame = scrollFrame
        dungeonFrame.content = content

        dungeonFrame.UpdateDungeons = function()
            -- Clear previous rows
            for i = 1, content:GetNumChildren() do
                local child = select(i, content:GetChildren())
                if child then child:Hide() end
            end
            local y = -5
            local found = false
            for i = 1, GetNumSavedInstances() do
                local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
                if name and locked and not isRaid then
                    found = true
                    local row = CreateFrame("Frame", nil, content)
                    row:SetSize(340, 26)
                    row:SetPoint("TOPLEFT", 0, y)
                    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
                    nameText:SetText(name)
                    nameText:SetTextColor(0.85, 0.95, 1)
                    local resetText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    resetText:SetPoint("LEFT", nameText, "RIGHT", 20, 0)
                    local hours = math.floor(reset/3600)
                    local mins = math.floor((reset%3600)/60)
                    resetText:SetText(string.format("%dh %dm left", hours, mins))
                    resetText:SetTextColor(1, 1, 0.7)
                    y = y - 28
                end
            end
            if not found then
                local row = CreateFrame("Frame", nil, content)
                row:SetSize(340, 26)
                row:SetPoint("TOPLEFT", 0, y)
                local noneText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                noneText:SetPoint("LEFT", row, "LEFT", 8, 0)
                noneText:SetText("No dungeons completed today.")
                noneText:SetTextColor(0.8, 0.9, 1)
            end
        end
    end
    dungeonFrame:UpdateDungeons()
    dungeonFrame:Show()
end
