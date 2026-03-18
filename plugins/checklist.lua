local STATE_FILE = '/tmp/checklist-state.txt'

local items = {
    'World', 'Group', 'Generic Positions', 'Band Positions',
    'Frontlight', 'Gobo', 'Gobo Rotation', 'Prism',
    'Prism Rotation', 'Focus', 'Colour Match'
}

local STATUS_DONE    = 'OK'
local STATUS_PENDING = 'NOT'

local pluginTable, pluginHandle = select(3, ...)

local function loadState()
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
    return state
end

local function saveState(state)
    local f = io.open(STATE_FILE, 'w')
    if f then
        local parts = {}
        for i = 1, #items do
            parts[i] = state[i] and '1' or '0'
        end
        f:write(table.concat(parts, ' '))
        f:close()
    end
end

local function main()
    local state   = loadState()
    local buttons = {}
    local closed  = false

    local overlay  = GetFocusDisplay().ScreenOverlay
    local W        = 400
    local itemH    = 38
    local itemGap  = 5
    local padding  = 10

    local contentH = padding + #items * (itemH + itemGap) + 15 + 40 + padding

    local dialog = overlay:Append('BaseInput')
    dialog.W = W + 25
    dialog.H = contentH + 70
    dialog.Columns = 1
    dialog.Rows = 2
    dialog[1][1].SizePolicy = 'Fixed'
    dialog[1][1].Size = 40
    dialog[1][2].SizePolicy = 'Stretch'
    dialog.AutoClose = 'No'

    local titleBar = dialog:Append('TitleBar')
    titleBar.Columns = 2
    titleBar.Rows = 1
    titleBar.Anchors = '0,0'
    titleBar[2][2].SizePolicy = 'Fixed'
    titleBar[2][2].Size = 50
    titleBar.Texture = 'corner2'

    local titleButton = titleBar:Append('TitleButton')
    titleButton.Text = 'Pre-Show Checklist'
    titleButton.Texture = 'corner1'
    titleButton.Anchors = '0,0'

    local closeButton = titleBar:Append('CloseButton')
    closeButton.Anchors = '1,0'
    closeButton.Texture = 'corner2'

    local dlgFrame = dialog:Append('DialogFrame')
    dlgFrame.H = '100%'
    dlgFrame.W = '100%'
    dlgFrame.Anchors = '0,1'

    local statusW = 55
    for i, name in ipairs(items) do
        local y = padding + (i - 1) * (itemH + itemGap)

        local nameBtn = dlgFrame:Append('Button')
        nameBtn.Text = name
        nameBtn.X, nameBtn.Y = padding, y
        nameBtn.W, nameBtn.H = W - padding * 2 - statusW - 5, itemH
        nameBtn.TextalignmentH = 'Left'
        nameBtn.clicked = 'checklistItemClicked'
        nameBtn.plugincomponent = pluginHandle

        local statusBtn = dlgFrame:Append('Button')
        statusBtn.Text = state[i] and STATUS_DONE or STATUS_PENDING
        statusBtn.X, statusBtn.Y = W - padding - statusW, y
        statusBtn.W, statusBtn.H = statusW, itemH
        statusBtn.clicked = 'checklistItemClicked'
        statusBtn.plugincomponent = pluginHandle

        buttons[i] = { name = nameBtn, status = statusBtn }
    end

    local resetY   = padding + #items * (itemH + itemGap) + 15
    local resetBtn = dlgFrame:Append('Button')
    resetBtn.Text  = 'Reset'
    resetBtn.X, resetBtn.Y = padding, resetY
    resetBtn.W, resetBtn.H = W - padding * 2, 35
    resetBtn.clicked = 'checklistResetClicked'
    resetBtn.plugincomponent = pluginHandle

    dialog:WaitInit()
    FindBestFocus(dialog)

    function pluginTable.checklistItemClicked(caller)
        for i, pair in ipairs(buttons) do
            if pair.name == caller or pair.status == caller then
                state[i] = not state[i]
                pair.status.Text = state[i] and STATUS_DONE or STATUS_PENDING
                saveState(state)
                break
            end
        end
    end

    function pluginTable.checklistResetClicked()
        for i = 1, #items do
            state[i] = false
            buttons[i].status.Text = STATUS_PENDING
        end
        saveState(state)
    end

    dialog:HookDelete(function() closed = true end)
    while not closed do coroutine.yield(0.1) end
end

return main
