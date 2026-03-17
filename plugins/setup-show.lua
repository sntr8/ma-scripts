local Macro_RGBW = 'Create Colours RGBW'
local Macro_SpotMix = 'Colour Mix Spots'
local Macro_SpotWheel = 'Colour Wheel Spots'
local Macro_NoWash = 'No House Wash'
local Macro_SingleWash = 'Single-Truss Wash'
local Macro_MultiWash = 'Multi-Truss Wash'

local pluginTable, pluginHandle = select(3, ...)

local function q(s) return '"' .. s .. '"' end

local function showError(msg)
    Echo("## ERROR: " .. msg)
    MessageBox({
        title = 'Setup error',
        message = msg,
        commands = { { value = 1, name = 'Ok' } }
    })
end

local matricksPool

local function getMAtricksPool()
    if not matricksPool then
        local pool = DataPool()
        for i = 1, pool:Count() do
            local child = pool:Ptr(i)
            if child and child:GetClass() == 'MAtricks' then
                matricksPool = child
                break
            end
        end
        if not matricksPool then
            showError("MAtricks pool not found in DataPool")
        end
    end
    return matricksPool
end

local function setMAtricks(name, property, value)
    local matricks = getMAtricksPool():Find(name)
    if not matricks or not matricks:IsValid() then
        showError("MAtricks not found: " .. name)
        return
    end
    matricks:Set(property, tostring(value))
end

local function copyMAtricks(srcName, dstName)
    local pool = getMAtricksPool()
    local src = pool:Find(srcName)
    local dst = pool:Find(dstName)
    if not src or not src:IsValid() then
        showError("MAtricks not found: " .. srcName)
        return
    end
    if not dst or not dst:IsValid() then
        showError("MAtricks not found: " .. dstName)
        return
    end
    dst:Copy(src)
    dst:Set('NAME', dstName)
end

local groupsPool

local function getGroupsPool()
    if not groupsPool then
        local pool = DataPool()
        for i = 1, pool:Count() do
            local child = pool:Ptr(i)
            if child and child:GetClass() == 'Groups' then
                groupsPool = child
                break
            end
        end
    end
    return groupsPool
end

local function groupExists(name)
    local pool = getGroupsPool()
    if not pool then return false end
    local grp = pool:Find(name)
    return grp ~= nil and grp:IsValid()
end

local function showSetupDialog()
    local inputNames  = { 'Spot', 'Wash', 'Wash Back', 'Beam', 'Blinder', 'Strobe' }
    local rgbwNames   = { 'Spot RGBW', 'Wash RGBW', 'Wash Back RGBW', 'Face RGBW' }
    local washOptions = { 'No change', 'None', 'Single-truss', 'Multi-truss' }
    local spotOptions = { 'No change', 'Colour Mix', 'Colour Wheel' }

    local washSelected = 1
    local spotSelected = 1
    local dialogResult = nil

    local overlay = GetFocusDisplay().ScreenOverlay
    local W, H = 460, 570

    local dialog = overlay:Append('BaseInput')
    dialog.W, dialog.H = W, H
    dialog:Set('FRAMEWIDTH', '2')

    -- Title label (manual — avoids NormedTitleBar's built-in close behaviour)
    local titleLabel = dialog:Append('UIObject')
    titleLabel.Text = 'Show Setup'
    titleLabel.X, titleLabel.Y = 0, 0
    titleLabel.W, titleLabel.H = W, 30

    -- Fixture count header
    local fixtureHeader = dialog:Append('UIObject')
    fixtureHeader.Text = 'Fixture counts  (format: fixtures/trusses  eg. 6/3)'
    fixtureHeader.X, fixtureHeader.Y = 10, 35
    fixtureHeader.W, fixtureHeader.H = 440, 20

    -- Fixture inputs
    local inputFields = {}
    for i, name in ipairs(inputNames) do
        local y = 60 + (i - 1) * 35
        local lbl = dialog:Append('UIObject')
        lbl.Text = name
        lbl.X, lbl.Y = 10, y
        lbl.W, lbl.H = 120, 25
        local edit = dialog:Append('LineEdit')
        edit.X, edit.Y = 135, y
        edit.W, edit.H = 315, 25
        inputFields[name] = edit
    end

    -- Selector buttons
    local washLbl = dialog:Append('UIObject')
    washLbl.Text = 'House Wash'
    washLbl.X, washLbl.Y = 10, 280
    washLbl.W, washLbl.H = 120, 25

    local washBtn = dialog:Append('Button')
    washBtn.Text = washOptions[washSelected]
    washBtn.X, washBtn.Y = 135, 280
    washBtn.W, washBtn.H = 315, 25
    washBtn.clicked = 'setupWashClicked'
    washBtn.plugincomponent = pluginHandle

    local spotLbl = dialog:Append('UIObject')
    spotLbl.Text = 'House Spot'
    spotLbl.X, spotLbl.Y = 10, 315
    spotLbl.W, spotLbl.H = 120, 25

    local spotBtn = dialog:Append('Button')
    spotBtn.Text = spotOptions[spotSelected]
    spotBtn.X, spotBtn.Y = 135, 315
    spotBtn.W, spotBtn.H = 315, 25
    spotBtn.clicked = 'setupSpotClicked'
    spotBtn.plugincomponent = pluginHandle

    -- RGBW toggles (2 columns)
    local rgbwHeader = dialog:Append('UIObject')
    rgbwHeader.Text = 'RGBW'
    rgbwHeader.X, rgbwHeader.Y = 10, 355
    rgbwHeader.W, rgbwHeader.H = 440, 20

    local checkboxes = {}
    local rgbwStates = {}
    for i, name in ipairs(rgbwNames) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cb = dialog:Append('CheckBox')
        cb.Text = name
        cb.X, cb.Y = 10 + col * 225, 378 + row * 35
        cb.W, cb.H = 215, 25
        cb.clicked = 'setupRgbwChanged'
        cb.plugincomponent = pluginHandle
        checkboxes[name] = cb
        rgbwStates[name] = false
    end

    -- Run / Cancel buttons
    local cancelBtn = dialog:Append('Button')
    cancelBtn.Text = 'Cancel'
    cancelBtn.X, cancelBtn.Y = 10, 465
    cancelBtn.W, cancelBtn.H = 100, 35
    cancelBtn.clicked = 'setupCancelClicked'
    cancelBtn.plugincomponent = pluginHandle

    local runBtn = dialog:Append('Button')
    runBtn.Text = 'Run'
    runBtn.X, runBtn.Y = 350, 465
    runBtn.W, runBtn.H = 100, 35
    runBtn.clicked = 'setupRunClicked'
    runBtn.plugincomponent = pluginHandle

    dialog:WaitInit()
    FindBestFocus(dialog)

    -- Callbacks
    function pluginTable.setupRgbwChanged(caller)
        for name, cb in pairs(checkboxes) do
            if cb == caller then
                rgbwStates[name] = not rgbwStates[name]
                caller:Set('STATE', rgbwStates[name] and '1' or '0')
                break
            end
        end
    end

    function pluginTable.setupWashClicked(caller)
        local idx = PopupInput({ title = 'House Wash configuration', caller = caller, items = washOptions })
        if idx then
            washSelected = idx
            washBtn.Text = washOptions[washSelected]
        end
    end

    function pluginTable.setupSpotClicked(caller)
        local idx = PopupInput({ title = 'House Spot colours', caller = caller, items = spotOptions })
        if idx then
            spotSelected = idx
            spotBtn.Text = spotOptions[spotSelected]
        end
    end

    function pluginTable.setupRunClicked()
        dialogResult = 'run'
    end

    function pluginTable.setupCancelClicked()
        dialogResult = 'cancel'
    end

    -- Wait for Run or Cancel
    dialog:HookDelete(function() dialogResult = 'cancel' end)

    while dialogResult == nil do coroutine.yield(0.1) end

    -- Read values before closing
    local inputs = {}
    for _, name in ipairs(inputNames) do
        inputs[name] = inputFields[name].content
    end

    local states = rgbwStates

    local wasRun = dialogResult == 'run'

    -- Always clean up the frame, even if something errors
    pcall(function() dialog:Parent():Remove(dialog:Index()) end)
    coroutine.yield()

    if not wasRun then
        return nil
    end

    return {
        inputs     = inputs,
        states     = states,
        washConfig = washSelected,
        spotColours = spotSelected
    }
end

local function main()
    local setup = showSetupDialog()

    if not setup then
        Echo("## Showfile setup cancelled")
        return
    end

    Echo("## Starting configuring the showfile")

    if setup.spotColours == 2 then
        Echo("### Colour mix spots")
        CmdIndirectWait('Macro ' .. q(Macro_SpotMix))
    elseif setup.spotColours == 3 then
        Echo("### Colour wheel spots")
        CmdIndirectWait('Macro ' .. q(Macro_SpotWheel))
    end

    if setup.washConfig == 2 then
        Echo("### No House Washes")
        CmdIndirectWait('Macro ' .. q(Macro_NoWash))
    elseif setup.washConfig == 3 then
        Echo("### Single truss of House Washes")
        CmdIndirectWait('Macro ' .. q(Macro_SingleWash))
    elseif setup.washConfig == 4 then
        Echo("### Multiple trusses of House Washes")
        CmdIndirectWait('Macro ' .. q(Macro_MultiWash))
    end

    for group, state in pairs(setup.states) do
        local groupName = group:gsub(" RGBW", "")
        local isSpot = groupName == "Spot"
        if isSpot and setup.spotColours == 3 then
            -- skip: colour wheel spots don't support RGBW
        elseif state == true then
            Echo("### House " .. groupName .. " are RGBW")
            CmdIndirectWait('Group ' .. q('House ' .. groupName .. ' Linear') .. '; Macro ' .. q(Macro_RGBW))
            CmdIndirectWait('ClearAll')
        else
            Echo("### House " .. groupName .. " are not RGBW")
        end
    end

    local typeId = { Spot = 1, Wash = 2, Beam = 3, Blinder = 4, Strobe = 5 }

    for group, value in pairs(setup.inputs) do
        local fixtureCount, trussCount = string.match(tostring(value), "^(%d+)/(%d+)$")
        fixtureCount = tonumber(fixtureCount)
        trussCount = tonumber(trussCount)
        if fixtureCount then
            Echo("### House " .. group .. " fixture count: " .. fixtureCount .. " truss count: " .. tostring(trussCount))
            local id = typeId[group]
            if id and trussCount then
                Echo("### Updating group grid for House " .. group)
                CmdIndirectWait(string.format(
                    'Preview On /NoOops; ClearAll /NoOops; Grid 0/0 Thru %d/%d /NoOops; Fixture %d0001 Thru %d9999 /NoOops; Store Group %s /o /NoOops; ClearAll /NoOops; Preview Off /NoOops',
                    fixtureCount - 1, trussCount - 1,
                    id, id,
                    q('House ' .. group)
                ))
            elseif trussCount then
                showError('Update group grid for House ' .. group .. ' manually.')
            end
            if group == "Strobe" then
                setMAtricks('Potpuri Clap House', 'XGROUP', fixtureCount)
                setMAtricks('Potpuri Clap House', 'SPEEDFROMX', 165 / fixtureCount)
                setMAtricks('Kerran vielä Bridge Strobe', 'XGROUP', fixtureCount)
                setMAtricks('Kerran vielä Bridge Strobe', 'SPEEDFROMX', 150 / fixtureCount)
            else
                setMAtricks('Half Rig - House ' .. group, 'XBLOCK', math.ceil(fixtureCount / 2))
                if trussCount then
                    local template = 'Template Y' .. trussCount .. ' grp3'
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1')
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1 ><')
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 ><', 'XWINGS', 2)
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1 <>')
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 <>', 'XWINGS', 2)
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 <>', 'INVERTX', 'Yes')
                end
            end
            local shuffleName = 'House ' .. group .. ' Shuffle'
            if groupExists(shuffleName) then
                Echo("### Updating shuffle group for House " .. group)
                CmdIndirectWait('Preview On /NoOops; ClearAll /NoOops; Group ' ..
                q('House ' .. group .. ' Linear') .. ' /NoOops; Shuffle /NoOops; Store Group ' .. q(shuffleName) .. ' /o /NoOops; ClearAll /NoOops; Preview Off /NoOops')
            end
            local invertName = 'House ' .. group .. ' Invert'
            if groupExists(invertName) then
                Echo("### Updating invert group for House " .. group)
                CmdIndirectWait('Preview On /NoOops; ClearAll /NoOops; Group ' ..
                q('House ' .. group) ..
                '; Grid "Flip" "X"; Store Group ' ..
                q(invertName) .. ' /o /NoOops; ClearAll /NoOops; Preview Off /NoOops')
            end
            local invertYName = 'House ' .. group .. ' Y Invert'
            if groupExists(invertYName) then
                Echo("### Updating Y invert group for House " .. group)
                CmdIndirectWait('Preview On /NoOops; ClearAll /NoOops; Group ' ..
                q('House ' .. group) ..
                '; Grid "Flip" "Y"; Store Group ' ..
                q(invertYName) .. ' /o /NoOops; ClearAll /NoOops; Preview Off /NoOops')
            end
        else
            Echo("### " .. group .. " count not given")
        end

    end
end

return main
