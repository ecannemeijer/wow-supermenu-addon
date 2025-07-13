-- Guild Members window
-- Zie Supermenu.lua voor slash command en SavedVariables

local guildMembersFrame
function ShowGuildMembersWindow()
    if guildMembersFrame and guildMembersFrame:IsShown() then
        guildMembersFrame:Hide()
        return
    end
    if not guildMembersFrame then
        guildMembersFrame = CreateFrame("Frame", "SupermenuGuildMembersFrame", UIParent, "BackdropTemplate")
        guildMembersFrame:SetSize(500, 520)
        guildMembersFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        guildMembersFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, tileSize = 0, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        guildMembersFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        guildMembersFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
        guildMembersFrame:SetFrameStrata("HIGH")
        guildMembersFrame:SetMovable(true)
        guildMembersFrame:EnableMouse(true)
        guildMembersFrame:RegisterForDrag("LeftButton")
        guildMembersFrame:SetScript("OnDragStart", guildMembersFrame.StartMoving)
        guildMembersFrame:SetScript("OnDragStop", guildMembersFrame.StopMovingOrSizing)

        -- Fancy title bar (like stats window)
        local titleBar = guildMembersFrame:CreateTexture(nil, "OVERLAY")
        titleBar:SetColorTexture(0.18, 0.25, 0.42, 0.93)
        titleBar:SetPoint("TOPLEFT", 8, -8)
        titleBar:SetPoint("TOPRIGHT", -8, -8)
        titleBar:SetHeight(38)

        local title = guildMembersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        title:SetPoint("TOP", guildMembersFrame, "TOP", 0, -20)
        title:SetText("Guild Members")
        title:SetTextColor(0.85, 0.95, 1)

        local closeBtn = CreateFrame("Button", nil, guildMembersFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", guildMembersFrame, "TOPRIGHT", -8, -8)
        closeBtn:SetScript("OnClick", function() guildMembersFrame:Hide() end)

        -- Checkbox to toggle online/all members
        guildMembersFrame.showOnlineOnly = true
        local checkBtn = CreateFrame("CheckButton", nil, guildMembersFrame, "UICheckButtonTemplate")
        checkBtn:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -15)
        checkBtn:SetSize(24, 24)
        checkBtn:SetChecked(true)
        checkBtn.text = checkBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkBtn.text:SetPoint("LEFT", checkBtn, "RIGHT", 2, 1)
        checkBtn.text:SetText("Show only online members")
        checkBtn:SetScript("OnClick", function(self)
            guildMembersFrame.showOnlineOnly = self:GetChecked()
            if guildMembersFrame and guildMembersFrame:IsShown() then
                local content = guildMembersFrame.content
                for i = 1, content:GetNumChildren() do
                    local child = select(i, content:GetChildren())
                    if child then child:Hide() end
                end
                GuildRoster()
                local numMembers = GetNumGuildMembers()
                local y = -5
                local showOnlineOnly = guildMembersFrame.showOnlineOnly
                for i = 1, numMembers do
                    local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
                    if name and (not showOnlineOnly or online) then
                        local row = CreateFrame("Frame", nil, content)
                        row:SetSize(440, 26)
                        row:SetPoint("TOPLEFT", 0, y)
                        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
                        local levelStr = level and ("|cffb0b0ff["..level.."]|r ") or ""
                        if online then
                            nameText:SetText(levelStr .. name .. " |cff00ff00[Online]|r")
                        else
                            nameText:SetText(levelStr .. name .. " |cffff0000[Offline]|r")
                        end
                        local zoneText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        zoneText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
                        zoneText:SetText(zone or "?")
                        zoneText:SetTextColor(0.6, 0.9, 1)
                        local whisperBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                        whisperBtn:SetSize(60, 22)
                        whisperBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                        whisperBtn:SetText("Whisper")
                        whisperBtn:SetScript("OnClick", function()
                            ChatFrame_SendTell(name)
                        end)
                        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                        inviteBtn:SetSize(50, 22)
                        inviteBtn:SetPoint("RIGHT", whisperBtn, "LEFT", -5, 0)
                        inviteBtn:SetText("Invite")
                        inviteBtn:SetScript("OnClick", function()
                            InviteUnit(name)
                        end)
                        y = y - 28
                    end
                end
            end
        end)
        guildMembersFrame.checkBtn = checkBtn

        -- Scroll area
        local scrollFrame = CreateFrame("ScrollFrame", nil, guildMembersFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", guildMembersFrame, "BOTTOMRIGHT", -35, 20)
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(1, 1)
        scrollFrame:SetScrollChild(content)
        guildMembersFrame.scrollFrame = scrollFrame
        guildMembersFrame.content = content
    end

    -- Clear previous content
    local content = guildMembersFrame.content
    for i = 1, content:GetNumChildren() do
        local child = select(i, content:GetChildren())
        if child then child:Hide() end
    end

    GuildRoster() -- Request update
    local numMembers = GetNumGuildMembers()
    local y = -5
    local showOnlineOnly = guildMembersFrame.showOnlineOnly
    -- Gather all members into a table for sorting
    local members = {}
    for i = 1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
        if name and (not showOnlineOnly or online) then
            table.insert(members, {
                name = name,
                rank = rank,
                rankIndex = rankIndex,
                level = level or 0,
                class = class,
                zone = zone,
                note = note,
                officernote = officernote,
                online = online and 1 or 0,
                status = status,
                classFileName = classFileName
            })
        end
    end
    -- Sort: online first, then level desc, then name asc
    table.sort(members, function(a, b)
        if a.online ~= b.online then
            return a.online > b.online
        elseif (a.level or 0) ~= (b.level or 0) then
            return (a.level or 0) > (b.level or 0)
        else
            return (a.name or "") < (b.name or "")
        end
    end)
    for _, m in ipairs(members) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(440, 26)
        row:SetPoint("TOPLEFT", 0, y)

        -- Use smaller font for name and zone
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
        local levelStr = m.level and ("|cffb0b0ff["..m.level.."]|r ") or ""
        if m.online == 1 then
            nameText:SetText(levelStr .. m.name .. " |cff00ff00[Online]|r")
        else
            nameText:SetText(levelStr .. m.name .. " |cffff0000[Offline]|r")
        end

        local zoneText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        zoneText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
        zoneText:SetText(m.zone or "?")
        zoneText:SetTextColor(0.6, 0.9, 1)

        -- Whisper button (rightmost)
        local whisperBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        whisperBtn:SetSize(60, 22)
        whisperBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        whisperBtn:SetText("Whisper")
        whisperBtn:SetScript("OnClick", function()
            ChatFrame_SendTell(m.name)
        end)

        -- Invite button (to the left of Whisper)
        local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        inviteBtn:SetSize(50, 22)
        inviteBtn:SetPoint("RIGHT", whisperBtn, "LEFT", -5, 0)
        inviteBtn:SetText("Invite")
        inviteBtn:SetScript("OnClick", function()
            InviteUnit(m.name)
        end)

        y = y - 28
    end
    guildMembersFrame:Show()
end
