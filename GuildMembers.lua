-- Guild Members window
-- Zie Supermenu.lua voor slash command en SavedVariables

-- Declare CLASS_ICONS at the top of the file for global accessibility
CLASS_ICONS = {
    WARRIOR = "Interface\\Icons\\ClassIcon_Warrior",
    MAGE = "Interface\\Icons\\ClassIcon_Mage",
    ROGUE = "Interface\\Icons\\ClassIcon_Rogue",
    DRUID = "Interface\\Icons\\ClassIcon_Druid",
    HUNTER = "Interface\\Icons\\ClassIcon_Hunter",
    SHAMAN = "Interface\\Icons\\ClassIcon_Shaman",
    PRIEST = "Interface\\Icons\\ClassIcon_Priest",
    WARLOCK = "Interface\\Icons\\ClassIcon_Warlock",
    PALADIN = "Interface\\Icons\\ClassIcon_Paladin",
    DEATHKNIGHT = "Interface\\Icons\\ClassIcon_DeathKnight",
    MONK = "Interface\\Icons\\ClassIcon_Monk",
    DEMONHUNTER = "Interface\\Icons\\ClassIcon_DemonHunter"
}

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
                local showOnlineOnly = guildMembersFrame.showOnlineOnly
                -- Gather all members into a table for sorting
                local members = {}
                for i = 1, numMembers do
                    local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
                    name = name:match("^[^%-]+")
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
                local CLASS_COLORS = RAID_CLASS_COLORS

                for _, m in ipairs(members) do
                    local row = CreateFrame("Frame", nil, content)
                    row:SetSize(440, 26)
                    row:SetPoint("TOPLEFT", 0, y)

                    -- Add class icon
                    local classIcon = row:CreateTexture(nil, "ARTWORK")
                    classIcon:SetSize(20, 20)
                    classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
                    classIcon:SetTexture(CLASS_ICONS[m.classFileName] or "Interface\\Icons\\INV_Misc_QuestionMark")

                    -- Level text
                    local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    levelText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
                    levelText:SetText(m.level and ("|cffb0b0ff["..m.level.."]|r") or "")

                    -- Name text
                    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameText:SetPoint("LEFT", levelText, "RIGHT", 5, 0)
                    local classColor = CLASS_COLORS[m.classFileName] or {r=1, g=1, b=1}
                    local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
                    nameText:SetText(colorCode .. m.name .. "|r")

                    -- Online status
                    local onlineText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    onlineText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
                    onlineText:SetText(m.online == 1 and "|cff00ff00Online|r" or "|cffff0000Offline|r")

                    -- Area text
                    local areaText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    areaText:SetPoint("LEFT", onlineText, "RIGHT", 5, 0)
                    areaText:SetText(m.zone or "?")
                    areaText:SetTextColor(0.6, 0.9, 1)

                    -- Invite button
                    local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    inviteBtn:SetSize(45, 20)
                    inviteBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
                    inviteBtn:SetText("Invite")
                    inviteBtn:SetNormalFontObject("GameFontHighlightSmall") -- Adjust font size
                    inviteBtn:SetScript("OnClick", function()
                        InviteUnit(m.name)
                    end)

                    -- Whisper button (rightmost)
                    local whisperBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    whisperBtn:SetSize(45, 20)
                    whisperBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
                    whisperBtn:SetText("Whisper")
                    whisperBtn:SetNormalFontObject("GameFontHighlightSmall") -- Adjust font size
                    whisperBtn:SetScript("OnClick", function()
                        ChatFrame_SendTell(m.name)
                    end)

                    y = y - 28
                end
                guildMembersFrame:Show()
            end
        end)
        guildMembersFrame.checkBtn = checkBtn

        -- Scroll area
        -- local scrollFrame = CreateFrame("ScrollFrame", nil, guildMembersFrame, "UIPanelScrollFrameTemplate")
        -- scrollFrame:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -50)
        -- scrollFrame:SetPoint("BOTTOMRIGHT", guildMembersFrame, "BOTTOMRIGHT", -35, 20)
        -- local content = CreateFrame("Frame", nil, scrollFrame)
        -- content:SetSize(1, 1)
        -- scrollFrame:SetScrollChild(content)
        -- guildMembersFrame.scrollFrame = scrollFrame
        -- guildMembersFrame.content = content

        -- Replace with a simple content frame
        local content = CreateFrame("Frame", nil, guildMembersFrame)
        content:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -50)
        content:SetPoint("BOTTOMRIGHT", guildMembersFrame, "BOTTOMRIGHT", -20, 20)
        guildMembersFrame.content = content
    end

    -- Clear previous content
    local content = guildMembersFrame.content
    for i = 1, content:GetNumChildren() do
        local child = select(i, content:GetChildren())
        if child then child:Hide() end
    end

    -- Add header to the table
    CreateTableHeader(content)

    GuildRoster() -- Request update
    local numMembers = GetNumGuildMembers()
    local showOnlineOnly = guildMembersFrame.showOnlineOnly
    local members = {}
    for i = 1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
        name = name:match("^[^%-]+")
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

    -- Sort members
    table.sort(members, function(a, b)
        if a.online ~= b.online then
            return a.online > b.online
        elseif (a.level or 0) ~= (b.level or 0) then
            return (a.level or 0) > (b.level or 0)
        else
            return (a.name or "") < (b.name or "")
        end
    end)

    -- Populate table
    PopulateGuildMembersTable(content, members)

    -- Adjust the window size dynamically based on the table content
    local numMembers = #members
    local rowHeight = 28
    local headerHeight = 26
    local padding = 50
    local totalHeight = (numMembers * rowHeight) + headerHeight + padding
    guildMembersFrame:SetHeight(totalHeight)

    guildMembersFrame:Show()
end

local function CreateTableRow(parent, y, m)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(440, 26)
    row:SetPoint("TOPLEFT", 0, y)

    -- Add class icon
    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
    classIcon:SetTexture(CLASS_ICONS[m.classFileName] or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Level text
    local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
    levelText:SetText(m.level and ("|cffb0b0ff["..m.level.."]|r") or "")

    -- Name text
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", levelText, "RIGHT", 5, 0)
    local classColor = CLASS_COLORS[m.classFileName] or {r=1, g=1, b=1}
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
    nameText:SetText(colorCode .. m.name .. "|r")

    -- Online status
    local onlineText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    onlineText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    onlineText:SetText(m.online == 1 and "|cff00ff00Online|r" or "|cffff0000Offline|r")

    -- Area text
    local areaText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    areaText:SetPoint("LEFT", onlineText, "RIGHT", 5, 0)
    areaText:SetText(m.zone or "?")
    areaText:SetTextColor(0.6, 0.9, 1)

    -- Invite button
    local inviteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    inviteBtn:SetSize(45, 20)
    inviteBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    inviteBtn:SetText("Invite")
    inviteBtn:SetNormalFontObject("GameFontHighlightSmall") -- Adjust font size
    inviteBtn:SetScript("OnClick", function()
        InviteUnit(m.name)
    end)

    -- Whisper button
    local whisperBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    whisperBtn:SetSize(45, 20)
    whisperBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    whisperBtn:SetText("Whisper")
    whisperBtn:SetNormalFontObject("GameFontHighlightSmall") -- Adjust font size
    whisperBtn:SetScript("OnClick", function()
        ChatFrame_SendTell(m.name)
    end)

    return row
end

function CreateTableHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(440, 26)
    header:SetPoint("TOPLEFT", 0, -5)

    -- Adjust header alignment and spacing
    local columnWidth = {
        classIcon = 30,
        level = 30,
        name = 100,
        online = 50,
        area = 80,
        invite = 40,
        whisper = 40
    }

    -- Class Icon Header
    local classIconHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classIconHeader:SetPoint("LEFT", header, "LEFT", 5, 0)
    classIconHeader:SetWidth(columnWidth.classIcon)
    classIconHeader:SetText("Class")

    -- Level Header
    local levelHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelHeader:SetPoint("LEFT", classIconHeader, "RIGHT", 5, 0)
    levelHeader:SetWidth(columnWidth.level)
    levelHeader:SetText("Level")

    -- Name Header
    local nameHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", levelHeader, "RIGHT", 5, 0)
    nameHeader:SetWidth(columnWidth.name)
    nameHeader:SetText("Name")

    -- Online Status Header
    local onlineHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    onlineHeader:SetPoint("LEFT", nameHeader, "RIGHT", 5, 0)
    onlineHeader:SetWidth(columnWidth.online)
    onlineHeader:SetText("Online")

    -- Area Header
    local areaHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    areaHeader:SetPoint("LEFT", onlineHeader, "RIGHT", 5, 0)
    areaHeader:SetWidth(columnWidth.area)
    areaHeader:SetText("Area")

    -- Invite Header
    local inviteHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    inviteHeader:SetPoint("LEFT", areaHeader, "RIGHT", 5, 0)
    inviteHeader:SetWidth(columnWidth.invite)
    inviteHeader:SetText("Invite")

    -- Whisper Header
    local whisperHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whisperHeader:SetPoint("LEFT", inviteHeader, "RIGHT", 5, 0)
    whisperHeader:SetWidth(columnWidth.whisper)
    whisperHeader:SetText("Whisper")

    return header
end

-- Ensure PopulateGuildMembersTable is declared globally
function PopulateGuildMembersTable(parent, members)
    -- Adjust column widths to fit the table within the window
    local columnWidth = {
        classIcon = 30,
        level = 30,
        name = 100,
        online = 50,
        area = 80,
        invite = 40,
        whisper = 40
    }

    -- Update parent width to fit adjusted columns
    parent:SetWidth(columnWidth.classIcon + columnWidth.level + columnWidth.name + columnWidth.online + columnWidth.area + columnWidth.invite + columnWidth.whisper + 20)

    local CLASS_COLORS = RAID_CLASS_COLORS -- Use WoW's built-in class colors

    for i, member in ipairs(members) do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(parent:GetWidth(), 26)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -5 - (i * 26))

        -- Class Icon
        local classIcon = row:CreateTexture(nil, "OVERLAY")
        classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
        classIcon:SetWidth(columnWidth.classIcon)
        classIcon:SetHeight(columnWidth.classIcon) -- Ensure square aspect ratio
        classIcon:SetTexture("Interface\\Icons\\ClassIcon_" .. (member.classFileName or "Unknown"))
        classIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Crop the texture for better appearance

        -- Level
        local level = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        level:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
        level:SetWidth(columnWidth.level)
        level:SetText(member.level)

        -- Name
        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("LEFT", level, "RIGHT", 5, 0)
        name:SetWidth(columnWidth.name)
        local classColor = CLASS_COLORS[member.classFileName] or {r=1, g=1, b=1} -- Default to white if class color is not found
        name:SetTextColor(classColor.r, classColor.g, classColor.b)
        name:SetText(member.name)

        -- Online Status
        local online = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        online:SetPoint("LEFT", name, "RIGHT", 5, 0)
        online:SetWidth(columnWidth.online)
        if member.online == 1 then
            online:SetTextColor(0, 1, 0) -- Green for online
            online:SetText("Online")
        else
            online:SetTextColor(1, 1, 1) -- White for offline
            online:SetText("Offline")
        end

        -- Area
        local area = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        area:SetPoint("LEFT", online, "RIGHT", 5, 0)
        area:SetWidth(columnWidth.area)
        area:SetText(member.zone)

        -- Invite Button
        local invite = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        invite:SetPoint("LEFT", area, "RIGHT", 5, 0)
        invite:SetWidth(columnWidth.invite)
        invite:SetText("Invite")
        invite:SetNormalFontObject("GameFontNormalSmall") -- Adjust font size
        invite:SetScript("OnClick", function()
            InviteUnit(member.name)
        end)

        -- Whisper Button
        local whisper = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        whisper:SetPoint("LEFT", invite, "RIGHT", 5, 0)
        whisper:SetWidth(columnWidth.whisper)
        whisper:SetText("Whisper")
        whisper:SetNormalFontObject("GameFontNormalSmall") -- Adjust font size
        whisper:SetScript("OnClick", function()
            ChatFrame_OpenChat("/w " .. member.name)
        end)
    end
end

-- Define reloadUIButton and damageButton explicitly
local reloadUIButton = CreateFrame("Button", nil, guildMembersFrame, "UIPanelButtonTemplate")
reloadUIButton:SetSize(100, 30)
reloadUIButton:SetText("Reload UI")
reloadUIButton:SetNormalFontObject("GameFontNormal")
reloadUIButton:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -80)
reloadUIButton:SetScript("OnClick", function()
    ReloadUI()
end)

local damageButton = CreateFrame("Button", nil, guildMembersFrame, "UIPanelButtonTemplate")
damageButton:SetSize(100, 30)
damageButton:SetText("Damage")
damageButton:SetNormalFontObject("GameFontNormal")
damageButton:SetPoint("TOPLEFT", guildMembersFrame, "TOPLEFT", 20, -50)
damageButton:SetScript("OnClick", function()
    if dungeonTracker and dungeonTracker.ShowDamageWindow then
        dungeonTracker:ShowDamageWindow()
    else
        print("Damage window not available.")
    end
end)

-- Remove duplicate Damage and Reload UI buttons
reloadUIButton:Hide()
damageButton:Hide()
