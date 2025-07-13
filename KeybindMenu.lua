-- Keybind menu
-- Zie Supermenu.lua voor slash command en SavedVariables

local keybindFrame
function ShowKeybindMenu()
    if keybindFrame and keybindFrame:IsShown() then
        keybindFrame:Hide()
        return
    end
    if not keybindFrame then
        keybindFrame = CreateFrame("Frame", "SupermenuKeybindFrame", UIParent, "BackdropTemplate")
        keybindFrame:SetSize(420, 520)
        keybindFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        keybindFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, tileSize = 0, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        keybindFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        keybindFrame:SetBackdropBorderColor(0.4, 0.4, 1, 0.8)
        keybindFrame:SetFrameStrata("HIGH")
        keybindFrame:SetMovable(true)
        keybindFrame:EnableMouse(true)
        keybindFrame:RegisterForDrag("LeftButton")
        keybindFrame:SetScript("OnDragStart", keybindFrame.StartMoving)
        keybindFrame:SetScript("OnDragStop", keybindFrame.StopMovingOrSizing)

        local title = keybindFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        title:SetPoint("TOP", keybindFrame, "TOP", 0, -20)
        title:SetText("Action Bar 1 Key Bindings")
        title:SetTextColor(0.85, 0.95, 1)

        local closeBtn = CreateFrame("Button", nil, keybindFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", keybindFrame, "TOPRIGHT", -8, -8)
        closeBtn:SetScript("OnClick", function() keybindFrame:Hide() end)

        -- No scroll area, all rows visible
        local content = CreateFrame("Frame", nil, keybindFrame)
        content:SetPoint("TOPLEFT", keybindFrame, "TOPLEFT", 20, -50)
        content:SetPoint("BOTTOMRIGHT", keybindFrame, "BOTTOMRIGHT", -20, 20)
        keybindFrame.content = content

        local function getBinding(slot)
            local action = "ACTIONBUTTON"..slot
            local key1, key2 = GetBindingKey(action)
            if key1 and key2 then
                return key1..", "..key2
            elseif key1 then
                return key1
            else
                return "-"
            end
        end

        keybindFrame.UpdateBindings = function()
            for i = 1, 12 do
                local row = content["row"..i]
                if row then
                    row.keyLabel:SetText(getBinding(i))
                end
            end
        end

        local y = 0
        for i = 1, 12 do
            local row = CreateFrame("Frame", nil, content)
            row:SetPoint("TOPLEFT", 0, y)
            row:SetSize(370, 32)
            content["row"..i] = row

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", row, "LEFT", 8, 0)
            label:SetText("Action Button "..i)
            label:SetTextColor(0.85, 0.95, 1)

            local keyLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            keyLabel:SetPoint("LEFT", label, "RIGHT", 30, 0)
            keyLabel:SetText(getBinding(i))
            keyLabel:SetTextColor(1, 1, 0.7)
            row.keyLabel = keyLabel

            local setBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            setBtn:SetSize(60, 22)
            setBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            setBtn:SetText("Set Key")
            setBtn:SetScript("OnClick", function()
                keybindFrame:EnableKeyboard(true)
                keybindFrame.capturing = i
                print("Press a key to bind to Action Button "..i.." (ESC to cancel)")
            end)

            y = y - 36
        end

        keybindFrame:SetScript("OnKeyDown", function(self, key)
            if not self.capturing then return end
            if key == "ESCAPE" then
                print("Key binding cancelled.")
                self.capturing = nil
                self:EnableKeyboard(false)
                return
            end
            local slot = self.capturing
            local action = "ACTIONBUTTON"..slot
            while true do
                local oldKey = GetBindingKey(action)
                if not oldKey then break end
                SetBinding(oldKey)
            end
            SetBinding(key, action)
            SaveBindings(GetCurrentBindingSet())
            print("Bound "..key.." to Action Button "..slot)
            self.capturing = nil
            self:EnableKeyboard(false)
            self:UpdateBindings()
        end)
    end
    keybindFrame:UpdateBindings()
    keybindFrame:Show()
end
