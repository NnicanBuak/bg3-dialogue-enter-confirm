local DialogueEnterHandler = {}

-- Флаг для отслеживания состояния диалога
local isInDialogue = false
local selectedOption = 1

-- Функция для обработки нажатия Enter
local function handleEnterPress()
    if not isInDialogue then
        return
    end
    
    -- Получаем текущий UI диалога
    local dialogueUI = Ext.UI.GetByType(115) -- Dialogue UI type
    if not dialogueUI then
        return
    end
    
    -- Симулируем нажатие цифровой клавиши для выбранной опции
    local keyCode = string.byte(tostring(selectedOption))
    Ext.UI.HandleEvent(dialogueUI, "KeyDown", keyCode)
end

-- Функция для отслеживания изменения выбранной опции стрелками
local function updateSelectedOption(direction)
    if not isInDialogue then
        return
    end
    
    local dialogueUI = Ext.UI.GetByType(115)
    if not dialogueUI then
        return
    end
    
    -- Получаем количество доступных опций из UI
    local optionsData = dialogueUI:GetValue("options")
    if not optionsData then
        return
    end
    
    local optionCount = #optionsData
    
    if direction == "up" then
        selectedOption = selectedOption > 1 and selectedOption - 1 or optionCount
    elseif direction == "down" then
        selectedOption = selectedOption < optionCount and selectedOption + 1 or 1
    end
end

-- Обработчик событий клавиатуры и контроллера  
local function onKeyDown(key)
    if key == "Return" or key == "KP_Enter" or key == "Joy1" then -- Joy1 = кнопка A на контроллере
        handleEnterPress()
        return true
    elseif key == "Up" or key == "Joy_DPad_Up" then
        updateSelectedOption("up")
    elseif key == "Down" or key == "Joy_DPad_Down" then  
        updateSelectedOption("down")
    end
    
    return false
end

-- Дополнительный обработчик для геймпада
local function onGamepadInput(input)
    if not isInDialogue then
        return false
    end
    
    if input.button == "A" and input.pressed then
        handleEnterPress()
        return true
    elseif input.button == "DPadUp" and input.pressed then
        updateSelectedOption("up")
    elseif input.button == "DPadDown" and input.pressed then
        updateSelectedOption("down")  
    end
    
    return false
end

-- Отслеживание состояния диалога
local function onUIEvent(ui, call, ...)
    if ui:GetTypeId() == 115 then -- Dialogue UI
        if call == "show" then
            isInDialogue = true
            selectedOption = 1 -- Сброс на первую опцию при открытии
        elseif call == "hide" then
            isInDialogue = false
            selectedOption = 1
        end
    end
end

-- Регистрация обработчиков событий
Ext.Events.KeyDown:Subscribe(onKeyDown)
Ext.Events.UICall:Subscribe(onUIEvent)

-- Попытка зарегистрировать обработчик геймпада (если доступен)
if Ext.Events.GamepadInput then
    Ext.Events.GamepadInput:Subscribe(onGamepadInput)
end

-- Инициализация при загрузке сохранения
Ext.Events.SessionLoaded:Subscribe(function()
    isInDialogue = false
    selectedOption = 1
end)

return DialogueEnterHandler