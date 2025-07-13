-- Main menu frame and slash command
-- Zie Supermenu.lua voor SavedVariables

local mainFrame

function CreateMainFrame()
    if mainFrame then return mainFrame end
    -- Button definitions
    local buttons = {
        { label = "Character Stats", onClick = function() ShowCharacterStats() end },
        { label = "Guild Members", onClick = function() ShowGuildMembersWindow() end },
        { label = "Key Bindings", onClick = ShowKeybindMenu },
        { label = "Dungeon Lockouts", onClick = ShowDungeonWindow },
        { label = "Dungeon Stats", onClick = ShowDungeonStatsWindow },
        { label = "Damage", onClick = function()
            if dungeonTracker and dungeonTracker.ShowDamageWindow then
                dungeonTracker:ShowDamageWindow()
            else
                print("Damage window not available.")
            end
        end },
        { label = "Reload UI", onClick = function() ReloadUI() end, color = {1,0,0,1} },
    }
    -- Move Damage button above Reload UI
    table.insert(buttons, #buttons, table.remove(buttons, #buttons-1))
    -- Correctly swap the positions of Damage and Reload UI buttons
    local damageButtonIndex = #buttons - 1
    local reloadUIButtonIndex = #buttons
    buttons[damageButtonIndex], buttons[reloadUIButtonIndex] = buttons[reloadUIButtonIndex], buttons[damageButtonIndex]

    local buttonHeight = 28
    local gap = 8
    local topMargin = 55
    local bottomMargin = 16
    local numButtons = #buttons
    local frameHeight = topMargin + (numButtons * buttonHeight) + ((numButtons - 1) * gap) + bottomMargin
    mainFrame = CreateFrame("Frame", "SupermenuMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(180, frameHeight)

    -- Load saved position or use default
    if SupermenuDB and SupermenuDB.position then
        mainFrame:SetPoint(SupermenuDB.position.point, UIParent, SupermenuDB.position.relativePoint, 
                          SupermenuDB.position.x, SupermenuDB.position.y)
    else
        mainFrame:SetPoint("TOP", UIParent, "TOP", -200, -50)
    end

    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, tileSize = 0, edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    mainFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, x, y = self:GetPoint()
        if not SupermenuDB then SupermenuDB = {} end
        SupermenuDB.position = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end)
    mainFrame:SetFrameStrata("HIGH")

    -- Fancy title bar
    local titleBar = mainFrame:CreateTexture(nil, "OVERLAY")
    titleBar:SetColorTexture(0.18, 0.25, 0.42, 0.93)
    titleBar:SetPoint("TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", -8, -8)
    titleBar:SetHeight(35)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -23)
    title:SetText("Supermenu")
    title:SetTextColor(0.85, 0.95, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function()
        mainFrame:Hide()
    end)

    -- Remove old button creation, and use the new buttons table
    local prevBtn
    for i, btnDef in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
        btn:SetSize(160, buttonHeight)
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        btn:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.8, 0.8)
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(btnDef.label)
        if btnDef.color then
            btnText:SetTextColor(unpack(btnDef.color))
        else
            btnText:SetTextColor(0.85, 0.9, 1, 1)
        end
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.15, 0.18, 0.35, 1)
            btn:SetBackdropBorderColor(0.5, 0.5, 1, 1)
            btnText:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.8, 0.8)
            if btnDef.color then
                btnText:SetTextColor(unpack(btnDef.color))
            else
                btnText:SetTextColor(0.85, 0.9, 1, 1)
            end
        end)
        btn:SetScript("OnMouseDown", function()
            btn:SetBackdropColor(0.05, 0.05, 0.12, 1)
            btnText:SetPoint("CENTER", btn, "CENTER", 1, -1)
        end)
        btn:SetScript("OnMouseUp", function()
            btn:SetBackdropColor(0.15, 0.18, 0.35, 1)
            btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end)
        btn:SetScript("OnClick", btnDef.onClick)
        btn:EnableMouse(true)
        if i == 1 then
            btn:SetPoint("TOP", mainFrame, "TOP", 0, -topMargin)
        else
            btn:SetPoint("TOP", prevBtn, "BOTTOM", 0, -gap)
        end
        prevBtn = btn
    end

    mainFrame:Show()
    return mainFrame
end

SLASH_SUPERMENU1 = "/supermenu"
SlashCmdList["SUPERMENU"] = function()
    if not mainFrame then CreateMainFrame() end
    if mainFrame:IsShown() then
        mainFrame:Hide()
        print("Supermenu window hidden")
    else
        mainFrame:Show()
        print("Supermenu window shown")
    end
end

-- Auto-show the menu when addon loads and initialize saved variables
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Supermenu" then
        if not SupermenuDB then
            SupermenuDB = {}
        end
        CreateMainFrame()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        if mainFrame and SupermenuDB then
            local point, _, relativePoint, x, y = mainFrame:GetPoint()
            SupermenuDB.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
        end
    end
end)
