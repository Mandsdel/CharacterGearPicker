local container = C_Container or _G
local bagSize = container.GetContainerNumSlots or GetContainerNumSlots
local bagLink = container.GetContainerItemLink or GetContainerItemLink
local bagInfo = container.GetContainerItemInfo or GetContainerItemInfo
local pickupBag = container.PickupContainerItem or PickupContainerItem
local itemInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local slotDefinitions = {
    { "Head", 1, "left", { INVTYPE_HEAD = true } },
    { "Neck", 2, "left", { INVTYPE_NECK = true } },
    { "Shoulder", 3, "left", { INVTYPE_SHOULDER = true } },
    { "Back", 15, "left", { INVTYPE_CLOAK = true } },
    { "Chest", 5, "left", { INVTYPE_CHEST = true, INVTYPE_ROBE = true } },
    { "Shirt", 4, "left", { INVTYPE_BODY = true } },
    { "Tabard", 19, "left", { INVTYPE_TABARD = true } },
    { "Wrist", 9, "left", { INVTYPE_WRIST = true } },
    { "Hands", 10, "right", { INVTYPE_HAND = true } },
    { "Waist", 6, "right", { INVTYPE_WAIST = true } },
    { "Legs", 7, "right", { INVTYPE_LEGS = true } },
    { "Feet", 8, "right", { INVTYPE_FEET = true } },
    { "Finger0", 11, "right", { INVTYPE_FINGER = true } },
    { "Finger1", 12, "right", { INVTYPE_FINGER = true } },
    { "Trinket0", 13, "right", { INVTYPE_TRINKET = true } },
    { "Trinket1", 14, "right", { INVTYPE_TRINKET = true } },
    { "MainHand", 16, "bottom", {
        INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_2HWEAPON = true,
    } },
    { "SecondaryHand", 17, "bottom", {
        INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true,
        INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true,
    } },
    { "Ranged", 18, "bottom", {
        INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true,
        INVTYPE_RELIC = true,
    } },
}

local function message(text)
    print("|cff80cfffCharacterGearPicker:|r " .. text)
end

if not (bagSize and bagLink and pickupBag and itemInfo and PickupInventoryItem and GetInventoryItemLink
    and CursorHasItem and InCombatLockdown and C_Timer and C_Timer.After) then
    message("Required inventory APIs are unavailable; the picker is disabled.")
    return
end

local picker = CreateFrame("Frame", "CharacterGearPickerFlyout", UIParent,
    BackdropTemplateMixin and "BackdropTemplate" or nil)
picker:SetSize(200, 80)
picker:SetFrameStrata("DIALOG")
picker:SetClampedToScreen(true)
picker:EnableMouse(true)
picker:Hide()

if picker.SetBackdrop then
    picker:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    })
else
    local background = picker:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
end

local hint = picker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", 12, -9)
hint:SetText("Click to equip")

local scroll = CreateFrame("ScrollFrame", nil, picker)
scroll:SetPoint("TOPLEFT", 10, -26)
scroll:EnableMouseWheel(true)
local content = CreateFrame("Frame", nil, scroll)
scroll:SetScrollChild(content)

local buttons, activeSlot, activeDefinition = {}, nil, nil
local cellSize, columns, maxRows = 38, 4, 5
local closeGeneration = 0

local function scheduleClose()
    closeGeneration = closeGeneration + 1
    local generation = closeGeneration
    C_Timer.After(0.5, function()
        if generation ~= closeGeneration or not picker:IsShown() then return end
        if (activeSlot and activeSlot:IsVisible() and activeSlot:IsMouseOver())
            or picker:IsMouseOver() then
            return
        end
        picker:Hide()
    end)
end

picker:SetScript("OnEnter", function() closeGeneration = closeGeneration + 1 end)
picker:SetScript("OnLeave", scheduleClose)
picker:SetScript("OnHide", function()
    closeGeneration = closeGeneration + 1
    activeSlot, activeDefinition = nil, nil
    for _, button in ipairs(buttons) do
        if GameTooltip:IsOwned(button) then
            GameTooltip:Hide()
            break
        end
    end
end)
scroll:SetScript("OnMouseWheel", function(self, delta)
    local limit = math.max(0, content:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(limit, self:GetVerticalScroll() - delta * cellSize)))
end)

local function locked(bag, index)
    if not bagInfo then return false end
    local info, _, isLocked = bagInfo(bag, index)
    if type(info) == "table" then return info.isLocked end
    return isLocked
end

local function equip(button)
    local choice = button.choice
    if not choice or not activeDefinition then return end
    if InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        message("Gear changes are unavailable during combat.")
        return
    end
    if CursorHasItem() or (GetCursorInfo and GetCursorInfo()) then
        message("Clear your cursor before changing gear.")
        return
    end
    if bagLink(choice.bag, choice.index) ~= choice.link then
        message("That bag slot changed. Hover over the equipment slot again.")
        picker:Hide()
        return
    end
    if locked(choice.bag, choice.index)
        or (IsInventoryItemLocked and IsInventoryItemLocked(activeDefinition[2])) then
        message("That item or equipment slot is busy. Try again.")
        return
    end

    local slot = activeDefinition[2]
    pickupBag(choice.bag, choice.index)
    if not CursorHasItem() then
        message("Could not pick up that item.")
        return
    end
    PickupInventoryItem(slot)
    local equipped = GetInventoryItemLink("player", slot) == choice.link
    if CursorHasItem() then pickupBag(choice.bag, choice.index) end
    if CursorHasItem() then
        message("An item remains on your cursor; place it in a bag.")
    elseif not equipped then
        message("Could not equip that item in this slot.")
    end
    picker:Hide()
end

local function makeButton()
    local button = CreateFrame("Button", nil, content)
    button:SetSize(36, 36)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnEnter", function(self)
        closeGeneration = closeGeneration + 1
        if not self.choice then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetBagItem then
            GameTooltip:SetBagItem(self.choice.bag, self.choice.index)
        else
            GameTooltip:SetHyperlink(self.choice.link)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        scheduleClose()
    end)
    button:SetScript("OnClick", equip)
    return button
end

local function draw()
    if not activeDefinition then return end
    local choices = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for index = 1, bagSize(bag) do
            local link = bagLink(bag, index)
            if link then
                local _, _, _, location, icon = itemInfo(link)
                if activeDefinition[4][location] then
                    choices[#choices + 1] = { bag = bag, index = index, link = link, icon = icon }
                end
            end
        end
    end
    if #choices == 0 then
        picker:Hide()
        return
    end

    local shownColumns = math.min(columns, #choices)
    local rows = math.ceil(#choices / shownColumns)
    local visibleRows = math.min(maxRows, rows)
    picker:SetSize(shownColumns * cellSize + 20, visibleRows * cellSize + 36)
    scroll:SetSize(shownColumns * cellSize, visibleRows * cellSize)
    content:SetSize(shownColumns * cellSize, rows * cellSize)
    scroll:SetVerticalScroll(0)
    hint:SetText(rows > maxRows and "Click to equip; scroll for more" or "Click to equip")

    for i, choice in ipairs(choices) do
        local button = buttons[i]
        if not button then
            button = makeButton()
            buttons[i] = button
        end
        button.choice = choice
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", ((i - 1) % shownColumns) * cellSize,
            -math.floor((i - 1) / shownColumns) * cellSize)
        button.icon:SetTexture(choice.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        button:Show()
    end
    for i = #choices + 1, #buttons do
        buttons[i].choice = nil
        buttons[i]:Hide()
    end
    picker:Show()
end

local function open(slot, definition)
    closeGeneration = closeGeneration + 1
    activeSlot, activeDefinition = slot, definition
    picker:ClearAllPoints()
    if definition[3] == "left" then
        picker:SetPoint("RIGHT", slot, "LEFT", -2, 0)
    elseif definition[3] == "right" then
        picker:SetPoint("LEFT", slot, "RIGHT", 2, 0)
    else
        picker:SetPoint("BOTTOM", slot, "TOP", 0, 2)
    end
    draw()
    if picker:IsShown() and definition[3] == "right" and GameTooltip:IsOwned(slot) then
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOMRIGHT", slot, "BOTTOMLEFT", -8, 0)
    end
end

local hooked = {}
local function hookSlots()
    for _, definition in ipairs(slotDefinitions) do
        local definition = definition
        local slot = _G["Character" .. definition[1] .. "Slot"]
        if slot and not hooked[slot] then
            hooked[slot] = true
            slot:HookScript("OnEnter", function(self) open(self, definition) end)
            slot:HookScript("OnLeave", scheduleClose)
            slot:HookScript("OnHide", function(self)
                if activeSlot == self then picker:Hide() end
            end)
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
        hookSlots()
    elseif event == "PLAYER_REGEN_DISABLED" then
        picker:Hide()
    elseif picker:IsShown() then
        draw()
    end
end)
