# CharacterGearPicker

A standalone World of Warcraft Forever add-on (interface `16001`) that adds
bag-item choices to the character panel.

Hover over an equipment slot to show matching bag items beside it. Move onto
the icons to see their normal item tooltips, and left-click an icon to equip
it in the hovered slot. The flyout closes when you move away; use the mouse
wheel if it has more items than fit. The normal equipment-slot tooltip remains
available. Empty slots work too. The picker chooses a different side of the
slot when there is not enough screen space on its preferred side.

The picker matches item equipment types, including both ring and trinket slots,
robes, weapons, shields and ranged items. The game still decides whether your
character can equip an item, including class, skill, level, unique-equipped
and weapon restrictions. Bag contents are shown individually, not bank items.
Gear changes are blocked in combat and when the cursor is occupied.
The addon does not write to chat. Blocked actions and cursor problems use
on-screen error notifications instead. Equipment acceptance is left to the
game rather than inferred from an immediate inventory-link check.

**Options > AddOns > CharacterGearPicker** describes how to use the picker.
There are no configurable settings.

This add-on is independent of MountGear. If you change gear while mounted,
MountGear can still restore the gear it recorded before mounting on dismount.

## Install

On the computer with WoW Forever installed, run
`Install-CharacterGearPicker.ps1` from this folder. By default it installs to
`D:\World of Warcraft\_forever_\Interface\AddOns\CharacterGearPicker`.
To use another AddOns folder:

```powershell
.\Install-CharacterGearPicker.ps1 -AddOnsPath 'X:\World of Warcraft\_forever_\Interface\AddOns'
```

Alternatively, copy `CharacterGearPicker.toc`, `Core.lua`, and `Options.lua` into an
`Interface\AddOns\CharacterGearPicker` folder. Enable the add-on at character
select, or use `/reload` if already enabled.

The game client is not available in the development environment. The character
slot hooks, tooltip placement, equipment swaps and API compatibility require
testing in WoW Forever.

## Local checks

The small mocked behavior check runs without the game:

```powershell
npx --yes --package=fengari-node-cli fengari tests\test.lua
```

It does not verify game-client behavior.
