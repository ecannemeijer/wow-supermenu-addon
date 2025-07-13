-- Dungeon Stats window
-- Zie Supermenu.lua voor slash command en SavedVariables

local dungeonStatsFrame
function ShowDungeonStatsWindow()
    if dungeonStatsFrame and dungeonStatsFrame:IsShown() then
        dungeonStatsFrame:Hide()
        return
    end
    if not dungeonStatsFrame then
        dungeonStatsFrame = CreateFrame("Frame", "SupermenuDungeonStatsFrame", UIParent, "BackdropTemplate")
        dungeonStatsFrame:SetSize(700, 500)
        dungeonStatsFrame:SetPoint("CENTER")
        dungeonStatsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, tileSize = 0, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        dungeonStatsFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        dungeonStatsFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
        dungeonStatsFrame:SetFrameStrata("HIGH")
        dungeonStatsFrame:SetMovable(true)
        dungeonStatsFrame:EnableMouse(true)
        dungeonStatsFrame:RegisterForDrag("LeftButton")
        dungeonStatsFrame:SetScript("OnDragStart", dungeonStatsFrame.StartMoving)
        dungeonStatsFrame:SetScript("OnDragStop", dungeonStatsFrame.StopMovingOrSizing)

        -- Title
        local title = dungeonStatsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", dungeonStatsFrame, "TOP", 0, -15)
        title:SetText("Dungeon Runs Log")
        title:SetTextColor(0.85, 0.95, 1)

        -- Close button
        local closeButton = CreateFrame("Button", nil, dungeonStatsFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", dungeonStatsFrame, "TOPRIGHT", -5, -5)

        -- Scroll frame for content
        local scrollFrame = CreateFrame("ScrollFrame", nil, dungeonStatsFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", dungeonStatsFrame, "TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", dungeonStatsFrame, "BOTTOMRIGHT", -30, 10)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(630, 1)
        scrollFrame:SetScrollChild(content)

        -- Text display
        local logText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        logText:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
        logText:SetJustifyH("LEFT")
        logText:SetJustifyV("TOP")
        logText:SetSpacing(2)
        logText:SetTextColor(0.9, 0.9, 0.9)

        -- Function to update logs display
        dungeonStatsFrame.UpdateLogs = function()
            local logs = SupermenuDB.DungeonRuns or {}
            if #logs == 0 then
                logText:SetText("No logs found")
                content:SetHeight(30)
            else
                local text = table.concat(logs, "\n")
                logText:SetText(text)
                content:SetHeight(logText:GetStringHeight() + 20)
            end
        end
    end
    dungeonStatsFrame:Show()
    dungeonStatsFrame:UpdateLogs()
end
