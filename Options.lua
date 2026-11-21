local panel = CreateFrame("Frame", "CharacterGearPickerSettingsPanel", UIParent)
panel.name = "CharacterGearPicker"
panel:Hide()
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("CharacterGearPicker")
local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
description:SetWidth(500)
description:SetJustifyH("LEFT")
description:SetText("There are no configurable settings. Hover over an equipment slot on the character panel to choose a replacement from your bags.")

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "CharacterGearPicker")
        Settings.RegisterAddOnCategory(category)
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
    else
        UIErrorsFrame:AddMessage("CharacterGearPicker: AddOns options registration is unavailable.", 1, 0.2, 0.2)
    end
end)
