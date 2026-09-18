local DialogueEnterHandler = {}

-- BG3's controller dialogue page already exposes this command. The keyboard page
-- exposes the same view model but does not bind a key to it. Calling that command
-- keeps selection, disabled answers, and dialogue ownership in the game itself.
local DIALOGUE_WIDGET_NAMES = {
    Dialogue = true,
    Dialogue_c = true,
}

-- These widgets can take focus away from dialogue. The list is deliberately
-- conservative: a missing or unknown widget never blocks the command.
local BLOCKING_WIDGET_NAMES = {
    Chat = true,
    ChatWindow = true,
    TextChat = true,
    Console = true,
    DebugConsole = true,
    MessageBox = true,
    GameMenu = true,
    PauseMenu = true,
    Inventory = true,
    Journal = true,
    CharacterCreation = true,
    Options = true,
    TextInput = true,
    TextEntry = true,
    InputDialog = true,
    Modal = true,
    ModalDialog = true,
    Popup = true,
    SaveGameInputSaveNameDialog = true,
    LoadingScreen = true,
}

local MAX_TREE_DEPTH = 8

local function safeCall(fn, ...)
    local ok, value = pcall(fn, ...)
    if ok then
        return value
    end
    return nil
end

local function readProperty(object, name)
    if not object then
        return nil
    end

    local value = safeCall(function()
        if object.GetProperty then
            return object:GetProperty(name)
        end
        return object[name]
    end)

    if value ~= nil then
        return value
    end

    -- The fallback is useful for small test doubles and for plain Lua view models.
    return safeCall(function()
        return object[name]
    end)
end

local function widgetName(node)
    local name = safeCall(function()
        return node.Name
    end)
    return type(name) == "string" and name or ""
end

local function childCount(node)
    local count = safeCall(function()
        return node.VisualChildrenCount
    end)
    return type(count) == "number" and math.max(0, math.floor(count)) or 0
end

local function childAt(node, index)
    return safeCall(function()
        return node:VisualChild(index)
    end)
end

local function contentRoot()
    local root = safeCall(Ext.UI.GetRoot)
    if not root then
        return nil
    end

    return safeCall(function()
        return root:Find("ContentRoot")
    end)
end

local function isVisible(node)
    local visible = readProperty(node, "IsVisible")
    if visible ~= nil then
        return visible == true
    end

    local visibility = readProperty(node, "Visibility")
    if visibility ~= nil then
        return tostring(visibility):upper() == "VISIBLE" or visibility == true
    end

    local open = readProperty(node, "IsOpen")
    return open == true
end

local function findDialogueNode(root)
    if not root then
        return nil
    end

    local current = { root }
    for _ = 0, MAX_TREE_DEPTH do
        local nextLevel = {}
        for _, node in ipairs(current) do
            local name = widgetName(node)
            if DIALOGUE_WIDGET_NAMES[name] then
                local dataContext = readProperty(node, "DataContext")
                if dataContext then
                    return node, dataContext
                end
            end

            for index = 1, childCount(node) do
                local child = childAt(node, index)
                if child then
                    nextLevel[#nextLevel + 1] = child
                end
            end
        end
        current = nextLevel
        if #current == 0 then
            break
        end
    end

    return nil
end

local function hasBlockingOverlay(root)
    if not root then
        return false
    end

    local current = { root }
    for _ = 0, MAX_TREE_DEPTH do
        local nextLevel = {}
        for _, node in ipairs(current) do
            if BLOCKING_WIDGET_NAMES[widgetName(node)] and isVisible(node) then
                return true
            end

            for index = 1, childCount(node) do
                local child = childAt(node, index)
                if child then
                    nextLevel[#nextLevel + 1] = child
                end
            end
        end
        current = nextLevel
        if #current == 0 then
            break
        end
    end

    return false
end

local function dialoguePath(dataContext)
    local currentPlayer = readProperty(dataContext, "CurrentPlayer")
    local selectedCharacter = readProperty(currentPlayer, "SelectedCharacter")
    local characterProperties = readProperty(selectedCharacter, "PlayerCharacterProperties")
    return readProperty(characterProperties, "ActiveDialogue")
end

local function canShowAnswers(dataContext)
    local activeDialogue = dialoguePath(dataContext)
    local showAnswers = readProperty(activeDialogue, "ShowAnswers")
    -- If the property is unavailable on a particular UI build, let the command's
    -- own CanExecute check decide. A known false value always fails closed.
    return showAnswers ~= false
end

local function playerId(dataContext)
    local id = readProperty(dataContext, "PlayerId")
    if id ~= nil then
        return id
    end

    return readProperty(readProperty(dataContext, "CurrentPlayer"), "PlayerId")
end

local function executeSelectedAnswer()
    local root = contentRoot()
    if not root or hasBlockingOverlay(root) then
        return false
    end

    local _, dataContext = findDialogueNode(root)
    if not dataContext or not canShowAnswers(dataContext) then
        return false
    end

    local command = readProperty(dataContext, "SelectorEnterCommand")
    local id = playerId(dataContext)
    if not command or id == nil then
        return false
    end

    local canExecute = safeCall(function()
        return command:CanExecute(id)
    end)
    if canExecute ~= true then
        return false
    end

    return safeCall(function()
        command:Execute(id)
        return true
    end) == true
end

local function keyName(key)
    local function normalize(name)
        name = name:upper():gsub("[%s%-]", "_")
        return name:gsub("^SDL_SCANCODE_", ""):gsub("^SCANCODE_", "")
    end

    local label = safeCall(function()
        return key.Label
    end)
    if type(label) == "string" and label ~= "" then
        return normalize(label)
    end

    return normalize(tostring(key or ""))
end

local function isConfirmKey(event)
    if not event or event.Pressed ~= true or event.Repeat == true then
        return false
    end

    if event.Key == 40 or event.Key == 88 then
        return true
    end

    local keyValue = safeCall(function()
        return event.Key.Value
    end)
    if keyValue == 40 or keyValue == 88 then
        return true
    end

    local key = keyName(event.Key)
    return key == "RETURN"
        or key == "ENTER"
        or key == "KP_ENTER"
        or key == "KPENTER"
        or key == "KEY_RETURN"
end

local function onKeyInput(event)
    if not isConfirmKey(event) then
        return
    end

    -- Do not compete with another UI handler that already consumed the event.
    if event.ActionPrevented == true or event.Stopped == true then
        return
    end

    if executeSelectedAnswer() and event.CanPreventAction == true then
        safeCall(function()
            event:PreventAction()
        end)
    end
end

-- Exposed only for the repository's Lua tests; no game state is retained here.
DialogueEnterHandler._test = {
    IsConfirmKey = isConfirmKey,
    KeyName = keyName,
    CanShowAnswers = canShowAnswers,
    ExecuteSelectedAnswer = executeSelectedAnswer,
    OnKeyInput = onKeyInput,
}

if Ext and Ext.Events and Ext.Events.KeyInput then
    Ext.Events.KeyInput:Subscribe(onKeyInput)
else
    safeCall(function()
        Ext.Utils.PrintWarning("Dialogue Enter Confirm: BG3SE KeyInput event is unavailable")
    end)
end

return DialogueEnterHandler
