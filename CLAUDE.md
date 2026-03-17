# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains Lua plugins for **grandMA3** lighting console software. Plugins are loaded and executed directly within the MA3 console or MA3 onPC (PC-based version).

## Development

There is no build system. Lua files are written and placed directly into the console's plugin directory. The grandMA3 console executes them using its built-in Lua runtime.

To test changes, copy the plugin file to the grandMA3 plugins directory and execute it from within the MA3 software.

## Architecture

### Plugin structure

Each plugin is a Lua file that returns a `main` function. The MA3 console calls this function when the plugin is executed:

```lua
local function main()
    -- plugin logic
end
return main
```

### MA3 API

The API is split into two categories (also reflected in `grandMA3_lua_functions.txt`):

**Object-Free API** — called as plain globals:
- `MessageBox(config)` — displays a dialog with inputs, selectors, and state toggles; returns a result table
- `CmdIndirectWait(cmd)` — executes an MA3 console command string and waits for completion
- `Echo(msg)` — logs a message to the MA3 command line output
- `Enums` — MA3 enum constants (e.g. `Enums.AlignmentH.Left`)
- `DataPool()` — returns a handle to the show data pool

**Object API** — called with colon notation on a handle (e.g. `handle:Find(name)`):
- `handle:Find(name[, class])` — finds a direct child by name
- `handle:FindRecursive(name[, class])` — finds a child recursively
- `handle:Count()` — number of children
- `handle:Ptr(index)` — child handle by 1-based index
- `handle:Get(property[, role])` — get a property value; pass `Enums.Roles.Display` to always get a string
- `handle:Set(property, value)` — set a property value (value must be a string)
- `handle:GetClass()` — returns the object's class name as a string
- `handle:PropertyCount()` / `handle:PropertyName(i)` / `handle:PropertyInfo(i)` — enumerate properties
- `handle:IsValid()` — check if a handle is still valid
- `handle:Copy(src)` — copy src into handle

### Object API: MAtricks

MAtricks objects live inside `DataPool()` in a child pool of class `'MAtricks'`. To get that pool:

```lua
local function getMAtricksPool()
    local pool = DataPool()
    for i = 1, pool:Count() do
        local child = pool:Ptr(i)
        if child:GetClass() == 'MAtricks' then
            return child
        end
    end
end
```

To read/write a specific MAtricks by name:

```lua
local matricks = getMAtricksPool():Find('Half Rig - House Spot')
matricks:Set('XBLOCK', '3')
matricks:Get('XBLOCK', Enums.Roles.Display)
```

Property names are uppercase versions of the CLI names (e.g. `XBlock` → `'XBLOCK'`, `SpeedFromX` → `'SPEEDFROMX'`). Boolean properties use `'Yes'`/`'No'` strings (e.g. `InvertX` → `'INVERTX'`, value `'Yes'` or `'No'`). Use the snippet below to discover all properties on any object:

```lua
for i = 1, handle:PropertyCount() do
    Echo(handle:PropertyName(i) .. ' = ' .. tostring(handle:Get(handle:PropertyName(i), Enums.Roles.Display)))
end
```

`dst:Copy(src)` works but overwrites the destination name — restore it with `dst:Set('NAME', dstName)` after copying.

### Object API: Custom UI

Plugins can build custom windows on the ScreenOverlay using `BaseInput` as the container. Requires `local pluginTable, pluginHandle = select(3, ...)` at module level for button callbacks. Button signals use `btn.clicked = 'callbackName'` + `btn.plugincomponent = pluginHandle`, with the callback defined as `function pluginTable.callbackName(caller) end`. Read values via `lineEdit.content` and `checkBox.checked`. Use `dialog:HookDelete(function() result = 'cancel' end)` to handle external dismissal. Close with `dialog:Parent():Remove(dialog:Index())`.

### `setup-show.lua`

The main plugin. Presents a setup dialog for configuring a stage lighting rig. Based on user input it:

1. Runs macros for house spot colour configuration (colour mix or colour wheel)
2. Runs macros for house wash configuration (none, single-truss, or multi-truss)
3. Sets RGBW colour presets on fixture groups that have RGBW enabled
4. Configures MAtricks (MA3 effects engine building blocks) for each fixture type using the `fixtureCount/trussCount` format (e.g. `6/3` = 6 fixtures per truss, 3 trusses)

Fixture types: Spot, Wash, Wash Back, Beam, Blinder, Strobe. Strobe uses speed-based MAtricks configuration; all other types use block-based half-rig and Y-axis grouping templates.

### Macro dependencies

The plugin depends on these macros already existing in the showfile:
- `Create Colours RGBW`
- `Colour Mix Spots`
- `Colour Wheel Spots`
- `No House Wash`
- `Single-Truss Wash`
- `Multi-Truss Wash`

It also depends on groups named `House <Type> Linear` (e.g. `House Spot Linear`) and MAtricks named `Half Rig - House <Type>`, `Template Y<n> grp3`, `House <Type> - Grp3 Y-1`, etc.
