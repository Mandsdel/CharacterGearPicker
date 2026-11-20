local frames, timers, messages, created = {}, {}, {}, {}
local function frame(name)
    local object = { name = name, shown = true, scripts = {}, children = {}, textures = {} }
    function object:SetScript(event, handler) self.scripts[event] = handler end
    function object:HookScript(event, handler) self.scripts[event] = handler end
    function object:CreateTexture(_, layer)
        local texture = frame()
        texture.layer = layer
        self.textures[#self.textures + 1] = texture
        return texture
    end
    function object:SetTexture(path) self.texture = path end
    function object:CreateFontString() return frame() end
    function object:SetScrollChild(child) self.scrollChild = child end
    function object:SetVerticalScroll(value) self.scroll = value end
    function object:GetVerticalScroll() return self.scroll or 0 end
    function object:GetHeight() return self.height or 0 end
    function object:SetSize(width, height) self.width, self.height = width, height end
    function object:SetPoint(...) self.point = { ... } end
    function object:GetLeft() return rawget(self, "left") end
    function object:GetRight() return rawget(self, "right") end
    function object:GetTop() return rawget(self, "top") end
    function object:GetBottom() return rawget(self, "bottom") end
    function object:GetEffectiveScale() return rawget(self, "scale") or 1 end
    function object:Show() self.shown = true end
    function object:Hide()
        local wasShown = self.shown
        self.shown = false
        if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function object:IsShown() return self.shown end
    function object:IsVisible() return self.shown end
    function object:IsMouseOver() return rawget(self, "mouseOver") or false end
    function object:IsOwned(owner) return rawget(self, "owner") == owner end
    function object:SetOwner(owner) self.owner = owner end
    setmetatable(object, { __index = function() return function() end end })
    if name then frames[name] = object end
    return object
end

UIParent = frame()
UIParent.left, UIParent.right, UIParent.top, UIParent.bottom = 0, 1000, 800, 0
GameTooltip = frame()
function GameTooltip:Hide() self.shown, self.owner = false, nil end
function GameTooltip:SetBagItem(bag, index)
    self.bag, self.index, self.link = bag, index, GetContainerItemLink(bag, index)
end
function CreateFrame(_, name, parent)
    local object = frame(name)
    created[#created + 1] = object
    if parent then parent.children[#parent.children + 1] = object end
    return object
end
CharacterTrinket1Slot = frame("trinket")
CharacterHeadSlot = frame("head")
CharacterMainHandSlot = frame("mainhand")
CharacterTrinket1Slot.left, CharacterTrinket1Slot.right = 800, 840
CharacterTrinket1Slot.top, CharacterTrinket1Slot.bottom = 400, 360
CharacterHeadSlot.left, CharacterHeadSlot.right = 160, 200
CharacterHeadSlot.top, CharacterHeadSlot.bottom = 400, 360
CharacterMainHandSlot.left, CharacterMainHandSlot.right = 400, 440
CharacterMainHandSlot.top, CharacterMainHandSlot.bottom = 790, 750
NUM_BAG_SLOTS = 0
local bags = { "trinket-a", "helmet", "trinket-b" }
local bagSlots = 3
local requested = {}
local equipped, cursor, combat = { [14] = "old-trinket" }, nil, false
local locations = {
    ["trinket-a"] = "INVTYPE_TRINKET", ["trinket-b"] = "INVTYPE_TRINKET",
    helmet = "INVTYPE_HEAD", ["old-trinket"] = "INVTYPE_TRINKET",
}
function GetContainerNumSlots() return bagSlots end
function GetContainerItemLink(_, index) return bags[index] end
function GetContainerItemInfo() return { isLocked = false } end
function GetItemInfoInstant(link) return nil, nil, nil, locations[link], "icon" end
function GetItemInfo(link) requested[#requested + 1] = link end
function PickupContainerItem(_, index) cursor, bags[index] = bags[index], cursor end
function PickupInventoryItem(slot) cursor, equipped[slot] = equipped[slot], cursor end
function GetInventoryItemLink(_, slot) return equipped[slot] end
function CursorHasItem() return cursor ~= nil end
function InCombatLockdown() return combat end
function print(text) messages[#messages + 1] = text end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }

assert(loadfile("Core.lua"))()
local events = created[#created]
events.scripts.OnEvent(events, "PLAYER_LOGIN")
local picker = frames.CharacterGearPickerFlyout
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(picker:IsShown())
local scroll = picker.children[1]
local content = scroll.scrollChild
assert(#content.children == 2)
local first, second = content.children[1], content.children[2]
assert(first.textures[1].layer == "ARTWORK" and first.textures[2].layer == "OVERLAY")
assert(first.textures[2].texture == "Interface\\Buttons\\UI-Quickslot2")
assert(first.textures[2].width == 52 and first.textures[2].height == 52)
assert(first.textures[2].point[1] == "CENTER")
assert(first.choice.link == "trinket-a" and second.choice.link == "trinket-b")
first.scripts.OnClick(first)
assert(equipped[14] == "trinket-a" and bags[1] == "old-trinket" and cursor == nil)
assert(not picker:IsShown())

-- A hidden flyout must reopen after uncached item data arrives while still hovered.
bags = { "cold-trinket" }
bagSlots = 1
CharacterTrinket1Slot.mouseOver = true
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(not picker:IsShown())
assert(requested[#requested] == "cold-trinket")
locations["cold-trinket"] = "INVTYPE_TRINKET"
events.scripts.OnEvent(events, "GET_ITEM_INFO_RECEIVED")
assert(picker:IsShown() and first.choice.link == "cold-trinket")
picker:Hide()

-- Leaving before data arrives must not reopen an obsolete flyout.
locations["cold-trinket"] = nil
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
CharacterTrinket1Slot.mouseOver = false
CharacterTrinket1Slot.scripts.OnLeave(CharacterTrinket1Slot)
locations["cold-trinket"] = "INVTYPE_TRINKET"
events.scripts.OnEvent(events, "GET_ITEM_INFO_RECEIVED")
assert(not picker:IsShown())
timers[#timers]()

-- Keep the scroll offset on refresh and clamp it when the list shrinks.
bags = {}
for i = 1, 25 do
    bags[i] = "trinket-" .. i
    locations[bags[i]] = "INVTYPE_TRINKET"
end
bagSlots = 25
CharacterTrinket1Slot.mouseOver = true
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(picker:IsShown() and content:GetHeight() == 7 * 38)
scroll:SetVerticalScroll(76)
events.scripts.OnEvent(events, "BAG_UPDATE_DELAYED")
assert(scroll:GetVerticalScroll() == 76)
CharacterHeadSlot.mouseOver = true
CharacterHeadSlot.scripts.OnEnter(CharacterHeadSlot)
assert(not picker:IsShown() and scroll:GetVerticalScroll() == 0)
CharacterHeadSlot.mouseOver = false
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(scroll:GetVerticalScroll() == 0)
scroll:SetVerticalScroll(76)
bagSlots = 21
events.scripts.OnEvent(events, "BAG_UPDATE_DELAYED")
assert(scroll:GetVerticalScroll() == 38)
bagSlots = 1
events.scripts.OnEvent(events, "BAG_UPDATE_DELAYED")
assert(scroll:GetVerticalScroll() == 0)

-- Reassigning a hovered button updates its tooltip.
first.scripts.OnEnter(first)
assert(GameTooltip:IsOwned(first) and GameTooltip.index == 1)
bags[1] = "trinket-b"
events.scripts.OnEvent(events, "BAG_UPDATE_DELAYED")
assert(first.choice.link == "trinket-b" and GameTooltip:IsOwned(first))
assert(GameTooltip.link == "trinket-b")

-- Placement flips away from the screen edge, including the weapon row.
CharacterHeadSlot.scripts.OnEnter(CharacterHeadSlot)
-- No matching head items exist yet.
assert(not picker:IsShown())
bags[1] = "helmet"
CharacterHeadSlot.scripts.OnEnter(CharacterHeadSlot)
assert(picker.point[1] == "RIGHT")
CharacterHeadSlot.left, CharacterHeadSlot.right = 10, 50
CharacterHeadSlot.scripts.OnEnter(CharacterHeadSlot)
assert(picker.point[1] == "LEFT")
bags[1] = "trinket-b"
CharacterTrinket1Slot.left, CharacterTrinket1Slot.right = 970, 990
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(picker.point[1] == "RIGHT")
bags[1] = "weapon"
locations.weapon = "INVTYPE_WEAPON"
CharacterMainHandSlot.scripts.OnEnter(CharacterMainHandSlot)
assert(picker.point[1] == "TOP")

-- If horizontal space is too narrow on both sides, use available vertical space.
bags[1] = "trinket-b"
CharacterTrinket1Slot.left, CharacterTrinket1Slot.right = 20, 980
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
assert(picker.point[1] == "BOTTOM")

picker:Hide()
bags = { "cold-trinket" }
locations["cold-trinket"] = nil
CharacterTrinket1Slot.mouseOver = true
CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED")
locations["cold-trinket"] = "INVTYPE_TRINKET"
events.scripts.OnEvent(events, "GET_ITEM_INFO_RECEIVED")
assert(not picker:IsShown())

bags = { "old-trinket", "helmet", "trinket-b" }
bagSlots = 3
CharacterTrinket1Slot.mouseOver = false
CharacterTrinket1Slot.left, CharacterTrinket1Slot.right = 800, 840
CharacterHeadSlot.scripts.OnEnter(CharacterHeadSlot)
assert(picker:IsShown() and first.choice.link == "helmet" and not second:IsShown())
combat = true
first.scripts.OnClick(first)
assert(not equipped[1] and bags[2] == "helmet")
assert(messages[#messages]:match("combat"))
combat = false
cursor = "held-item"
first.scripts.OnClick(first)
assert(cursor == "held-item" and bags[2] == "helmet")
assert(messages[#messages]:match("cursor"))
cursor = nil
bags[2] = "changed"
first.scripts.OnClick(first)
assert(not equipped[1] and bags[2] == "changed")
assert(messages[#messages]:match("changed"))

CharacterTrinket1Slot.scripts.OnEnter(CharacterTrinket1Slot)
CharacterTrinket1Slot.scripts.OnLeave(CharacterTrinket1Slot)
picker.mouseOver = true
timers[#timers]()
assert(picker:IsShown())
picker.mouseOver = false
picker.scripts.OnLeave(picker)
timers[#timers]()
assert(not picker:IsShown())
