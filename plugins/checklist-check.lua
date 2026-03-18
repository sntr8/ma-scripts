local STATE_FILE       = '/tmp/checklist-state.txt'
local MACRO_START_SHOW = 'Start Show'
local MACRO_PROG_MODE  = 'Program Mode'

local items = {
    'World', 'Group', 'Generic Positions', 'Band Positions',
    'Frontlight', 'Gobo', 'Gobo Rotation', 'Prism',
    'Prism Rotation', 'Focus', 'Colour Match'
}

local function main()
    local state = {}
    for i = 1, #items do state[i] = false end

    local f = io.open(STATE_FILE, 'r')
    if f then
        local line = f:read('*l')
        f:close()
        if line then
            local i = 1
            for val in line:gmatch('%S+') do
                if state[i] ~= nil then
                    state[i] = val == '1'
                end
                i = i + 1
            end
        end
    end

    local incomplete = {}
    for i, done in ipairs(state) do
        if not done then
            incomplete[#incomplete + 1] = items[i]
        end
    end

    if #incomplete == 0 then
        CmdIndirect('Go+ Macro "' .. MACRO_START_SHOW .. '"')
        return
    end

    local result = MessageBox({
        title    = 'Show not ready',
        message  = 'Not done:\n' .. table.concat(incomplete, '\n'),
        commands = {
            { value = 1, name = 'Proceed' },
            { value = 2, name = 'Return to Program' },
        }
    })

    if result and result.result == 2 then
        CmdIndirect('Off Macro "' .. MACRO_START_SHOW .. '"')
        CmdIndirect('Macro "' .. MACRO_PROG_MODE .. '"')
    else
        CmdIndirect('Go+ Macro "' .. MACRO_START_SHOW .. '"')
    end
end

return main
