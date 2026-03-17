local Macro_RGBW = 'Create Colours RGBW'
local Macro_SpotMix = 'Colour Mix Spots'
local Macro_SpotWheel = 'Colour Wheel Spots'
local Macro_NoWash = 'No House Wash'
local Macro_SingleWash = 'Single-Truss Wash'
local Macro_MultiWash = 'Multi-Truss Wash'

local function getMAtricksPool()
    local pool = DataPool()
    for i = 1, pool:Count() do
        local child = pool:Ptr(i)
        if child:GetClass() == 'MAtricks' then
            return child
        end
    end
end

local function setMAtricks(name, property, value)
    local matricks = getMAtricksPool():Find(name)
    if not matricks or not matricks:IsValid() then
        Echo("MAtricks not found: " .. name)
        return
    end
    matricks:Set(property, tostring(value))
end

local function copyMAtricks(srcName, dstName)
    local pool = getMAtricksPool()
    local src = pool:Find(srcName)
    local dst = pool:Find(dstName)
    if not src or not src:IsValid() then
        Echo("MAtricks not found: " .. srcName)
        return
    end
    if not dst or not dst:IsValid() then
        Echo("MAtricks not found: " .. dstName)
        return
    end
    dst:Copy(src)
end

local function main()
    local result
    local resultTable
    local inputs = {
        { name = 'Spot',      whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' },
        { name = 'Wash',      whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' },
        { name = 'Wash Back', whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' },
        { name = 'Beam',      whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' },
        { name = 'Blinder',   whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' },
        { name = 'Strobe',    whiteFilter = '0123456789/', maxTextLength = 4, vkPlugin = 'NumericInput' }
    }
    local selectors = {
        { name = 'House Wash configuration', selectedValue = 1, values = { ['None'] = 1, ['Single-truss'] = 2, ['Multi-truss'] = 3 }, type = 1 },
        { name = 'House Spot colours',     selectedValue = 1, values = { ['Colour Mix'] = 1, ['Colour Wheel'] = 2 },  type = 1 }
    }
    local states = {
        { name = "Spot RGBW",    state = false },
        { name = "Wash RGBW",    state = false },
        { name = "Wash Back RGBW", state = false },
        { name = "Face RGBW",    state = false }
    }
    repeat
        result = true
        resultTable =
            MessageBox(
                {
                    title = 'Show setup',
                    message =
                    'Define the show rig. Define the max number of fixtures per truss and the count of truss (eg. 6/3) and select correct parameters',
                    message_align_h = Enums.AlignmentH.Left,
                    message_align_v = Enums.AlignmentV.Top,
                    commands = { { value = 1, name = 'Run' }, { value = 0, name = 'Cancel' } },
                    selectors = selectors,
                    inputs = inputs,
                    states = states,
                    backColor = 'Global.Default',
                    icon = 'logo_small',
                    titleTextColor = 'Global.Text',
                    messageTextColor = 'Global.Text'
                }
            )
    until (result and resultTable.result == 1) or resultTable.result == 0
    if resultTable.result == 0
    then
        Echo("## Showfile setup cancelled")
        return
    end

    Echo("## Starting configuring the showfile")

    if resultTable.selectors['House Spot colours'] == 1
    then
        Echo("### Colour mix spots")
        CmdIndirectWait('Macro ' .. string.char(34) .. Macro_SpotMix .. string.char(34))
        if resultTable.states["Spot RGBW"] == true
        then
            Echo("### House spots are RGBW")
            CmdIndirectWait('Group ' ..
            string.char(34) ..
            'House Spot Linear' .. string.char(34) .. '; Macro ' .. string.char(34) .. Macro_RGBW .. string.char(34))
            CmdIndirectWait('ClearAll')
        end
    elseif resultTable.selectors['House Spot colours'] == 2
    then
        Echo("### Colour wheel spots")
        CmdIndirectWait('Macro ' .. string.char(34) .. Macro_SpotWheel .. string.char(34))
    end

    if resultTable.selectors['House Wash configuration'] == 1
    then
        Echo("### No House Washes")
        CmdIndirectWait('Macro ' .. string.char(34) .. Macro_NoWash .. string.char(34))
    elseif resultTable.selectors['House Wash configuration'] == 2
    then
        Echo("### Single truss of House Washes")
        CmdIndirectWait('Macro ' .. string.char(34) .. Macro_SingleWash .. string.char(34))
    elseif resultTable.selectors['House Wash configuration'] == 3
    then
        Echo("### Multiple trusses of House Washes")
        CmdIndirectWait('Macro ' .. string.char(34) .. Macro_MultiWash .. string.char(34))
    end

    for group, state in pairs(resultTable.states)
    do
        local groupName = group:gsub(" RGBW", "")
        if groupName ~= "Spot"
        then
            if state == true
            then
                Echo("### House " .. groupName .. " are RGBW")
                CmdIndirectWait('Group ' ..
                string.char(34) ..
                'House ' ..
                groupName .. ' Linear' .. string.char(34) .. '; Macro ' .. string.char(34) .. Macro_RGBW ..
                string.char(34))
                CmdIndirectWait('ClearAll')
            else
                Echo("### House " .. groupName .. " are not RGBW")
            end
        end
    end

    for group, value in pairs(resultTable.inputs)
    do
        if value ~= nil and string.find(tostring(value), "/")
        then
            local i = 1
            local fixtureCount
            local trussCount
            for match in string.gmatch(value, "([^/]+)")
            do
                if (i == 1)
                then
                    fixtureCount = tonumber(match)
                elseif (i == 2)
                then
                    trussCount = tonumber(match)
                end
                i = i + 1
            end

            Echo("### House " .. group .. " fixture count: " .. fixtureCount .. " truss count: " .. trussCount)
            if group == "Strobe"
            then
                setMAtricks('Potpuri Clap House', 'XGROUP', fixtureCount)
                setMAtricks('Potpuri Clap House', 'SPEEDFROMX', 165 / fixtureCount)
                setMAtricks('Kerran vielä Bridge Strobe', 'XGROUP', fixtureCount)
                setMAtricks('Kerran vielä Bridge Strobe', 'SPEEDFROMX', 150 / fixtureCount)
            else
                setMAtricks('Half Rig - House ' .. group, 'XBLOCK', math.ceil(fixtureCount / 2))
                if trussCount
                then
                    local template = 'Template Y' .. trussCount .. ' grp3'
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1')
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1 ><')
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 ><', 'XWINGS', 2)
                    copyMAtricks(template, 'House ' .. group .. ' - Grp3 Y-1 <>')
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 <>', 'XWINGS', 2)
                    setMAtricks('House ' .. group .. ' - Grp3 Y-1 <>', 'INVERTX', 'Yes')
                end
            end
        else
            Echo("### " .. group .. " count not given")
        end
    end
end

return main
