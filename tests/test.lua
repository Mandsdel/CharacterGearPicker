local frames, timers, messages, created = {}, {}, {}, {}
local function frame(name)
    local object = { name = name, shown = true, scripts = {}, children = {} }
    function object:SetScript(event, handler) self.scripts[event] = handler end
    function object:HookScript(event, handler) self.scripts[event] = handler end
    function object:CreateTexture() return frame() end
    function object:CreateFontString() return frame() end
    function object:SetScrollChild(child) self.scrollChild = child end
    function object:SetVerticalScroll(value) self.scroll = value end
    function object:GetVerticalScroll() return self.scroll or 0 end
    function object:GetHeight() return self.height or 0 end
    function object:SetSize(_, height) self.height = height end
    function object:Show() self.shown = true end
    function object:Hide()
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function object:IsShown() return self.shown end
    function object:IsVisible() return self.shown end
    function object:IsMouseOver() return rawget(self, "mouseOver") or false end
    function object:IsOwned() return false end
    setmetatable(object, { __index = function() return function() end end })
    if name then frames[name] = object end
    return object
end

UIParent = frame()
GameTooltip = frame()
function CreateFrame(_, name, parent)
    local object = frame(name)
    created[#created + 1] = object
    if parent then parent.children[#parent.children + 1] = object end
    return object
end
CharacterTrinket1Slot = frame("trinket")
CharacterHeadSlot = frame("head")
NUM_BAG_SLOTS = 0
local bags = { "trinket-a", "helmet", "trinket-b" }
local equipped, cursor, combat = { [14] = "old-trinket" }, nil, false
local locations = {
    ["trinket-a"] = "INVTYPE_TRINKET", ["trinket-b"] = "INVTYPE_TRINKET",
    helmet = "INVTYPE_HEAD", ["old-trinket"] = "INVTYPE_TRINKET",
}
function GetContainerNumSlots() return 3 end
function GetContainerItemLink(_, index) return bags[index] end
function GetContainerItemInfo() return { isLocked = false } end
function GetItemInfoInstant(link) return nil, nil, nil, locations[link], "icon" end
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
assert(first.choice.link == "trinket-a" and second.choice.link == "trinket-b")
first.scripts.OnClick(first)
assert(equipped[14] == "trinket-a" and bags[1] == "old-trinket" and cursor == nil)
assert(not picker:IsShown())

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
