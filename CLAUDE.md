# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Lua plugins for **grandMA3** lighting console. No build system — files are placed directly in the console's plugin directory and executed from within MA3.

## Plugin structure

```lua
local pluginTable, pluginHandle = select(3, ...)  -- must be module-level for UI callbacks
local function main() ... end
return main
```

## MA3 API

Two categories: Object-Free globals (`CmdIndirectWait`, `Echo`, `DataPool()`, `PopupInput`) and Object API via colon notation (`handle:Find()`, `handle:Set()`, `handle:Get()`). See `grandMA3_lua_functions.txt` for full reference.

Property names are uppercase (`XBlock` → `'XBLOCK'`). Booleans use `'Yes'`/`'No'`. Always pass `Enums.Roles.Display` as the second arg to `:Get()`.

DataPool children by class: `Worlds`, `Filters`, `GeneratorTypes`, `PresetPools`, `Groups`, `Sequences`, `Plugins`, `Macros`, `Quickeys`, `MAtricks`, `Configurations`, `Pages`, `Layouts`, `Timecodes`, `Timers`.

`dst:Copy(src)` overwrites the destination name — restore with `dst:Set('NAME', dstName)`.

`MessageBox()` returns a table — the selected command value is in `result.result`, not `result.value`.

## Custom UI

Correct dialog structure: `BaseInput` (outer container) → `TitleBar` with `TitleButton` + `CloseButton` → `DialogFrame` (provides background/border, append all content here). `BaseInput` is always transparent — `DialogFrame` is what draws the background.

Z-order: first appended = bottom, last appended = top. UIObjects always render on top of interactive elements regardless of order.

**CheckBox does not self-toggle.** The `clicked` callback fires before STATE updates. Manually toggle and set STATE:
```lua
function pluginTable.myCallback(caller)
    myState = not myState
    caller:Set('STATE', myState and '1' or '0')
end
```

Close dialog with `overlay:ClearUIChildren()`. Handle external dismissal with `dialog:HookDelete(fn)`.

## setup-show.lua

Setup dialog for configuring a stage lighting rig. Inputs are `fixtures/trusses` per type (Spot, Wash, Wash Back, Beam, Blinder, Strobe). On run:
- Triggers macros for spot colour and wash configuration
- Updates MAtricks (effects engine) block/group/speed values
- Updates group grids, shuffle, invert, and combined groups (opt-in per type via "Groups" checkbox)

Fixture IDs: `<type 1 digit><truss 2 digits><fixture 2 digits>` — type 1=Spot, 2=Wash, 3=Beam, 4=Blinder, 5=Strobe. Wash Back borrows ID 3 when no Beams are in the show.

Wrap group-modifying commands with `Preview On /NoOops; ClearAll /NoOops; ...; ClearAll /NoOops; Preview Off /NoOops`.
