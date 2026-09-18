local source = arg[1] or "src/Mods/DialogueEnterConfirm/ScriptExtender/Lua/Client/DialogueEnterHandler.lua"

local subscription
local activeRoot

Ext = {
    UI = {
        GetRoot = function()
            return activeRoot
        end,
    },
    Events = {
        KeyInput = {
            Subscribe = function(_, callback)
                subscription = callback
            end,
        },
    },
}

local handler = assert(dofile(source))
assert(subscription, "KeyInput subscription was not registered")

local function vm(properties)
    return {
        GetProperty = function(self, name)
            return properties[name]
        end,
    }
end

local command = {
    canExecute = true,
    executeCount = 0,
    lastPlayerId = nil,
}
function command:CanExecute(playerId)
    return self.canExecute and playerId == 7
end
function command:Execute(playerId)
    self.executeCount = self.executeCount + 1
    self.lastPlayerId = playerId
end

local activeDialogue = vm({ ShowAnswers = true })
local dataContext = vm({
    PlayerId = 7,
    SelectorEnterCommand = command,
    CurrentPlayer = vm({
        PlayerId = 7,
        SelectedCharacter = vm({
            PlayerCharacterProperties = vm({ ActiveDialogue = activeDialogue }),
        }),
    }),
})

local dialogue = {
    Name = "Dialogue",
    DataContext = dataContext,
    VisualChildrenCount = 0,
}
local contentRoot = {
    VisualChildrenCount = 1,
    VisualChild = function(_, index)
        return index == 1 and dialogue or nil
    end,
}
local root = {
    Find = function(_, name)
        return name == "ContentRoot" and contentRoot or nil
    end,
}
activeRoot = root

local function event(key, overrides)
    local result = {
        Key = key,
        Pressed = true,
        Repeat = false,
        CanPreventAction = true,
        prevented = false,
    }
    function result:PreventAction()
        self.prevented = true
    end
    for name, value in pairs(overrides or {}) do
        result[name] = value
    end
    return result
end

assert(handler._test.IsConfirmKey(event("RETURN")))
assert(handler._test.IsConfirmKey(event("KP_ENTER")))
assert(handler._test.IsConfirmKey(event({ Value = 40, Label = "SDL_SCANCODE_RETURN" })))
assert(handler._test.IsConfirmKey(event({ Value = 88, Label = "SDL_SCANCODE_KP_ENTER" })))
assert(not handler._test.IsConfirmKey(event("SPACE")))
assert(not handler._test.IsConfirmKey(event("RETURN", { Pressed = false })))
assert(not handler._test.IsConfirmKey(event("RETURN", { Repeat = true })))

local first = event("RETURN")
subscription(first)
assert(command.executeCount == 1, "Enter did not execute SelectorEnterCommand")
assert(command.lastPlayerId == 7)
assert(first.prevented, "successful confirmation did not consume the key")

local repeated = event("RETURN", { Repeat = true })
subscription(repeated)
assert(command.executeCount == 1, "held Enter executed the command twice")

activeDialogue = vm({ ShowAnswers = false })
dataContext = vm({ PlayerId = 7, SelectorEnterCommand = command, CurrentPlayer = vm({
    PlayerId = 7,
    SelectedCharacter = vm({ PlayerCharacterProperties = vm({ ActiveDialogue = activeDialogue }) }),
}) })
dialogue.DataContext = dataContext
subscription(event("RETURN"))
assert(command.executeCount == 1, "hidden answers were confirmed")

activeDialogue = vm({ ShowAnswers = true })
dataContext = vm({ PlayerId = 7, SelectorEnterCommand = command, CurrentPlayer = vm({
    PlayerId = 7,
    SelectedCharacter = vm({ PlayerCharacterProperties = vm({ ActiveDialogue = activeDialogue }) }),
}) })
dialogue.DataContext = dataContext
command.canExecute = false
subscription(event("RETURN"))
assert(command.executeCount == 1, "a disabled SelectorEnterCommand was executed")

command.canExecute = true
local overlay = { Name = "Chat", IsVisible = true, VisualChildrenCount = 0 }
contentRoot.VisualChildrenCount = 2
contentRoot.VisualChild = function(_, index)
    return index == 1 and dialogue or index == 2 and overlay or nil
end
subscription(event("RETURN"))
assert(command.executeCount == 1, "a visible chat overlay was ignored")

-- No dialogue and a closed dialogue must be harmless.
activeRoot = {
    Find = function()
        return nil
    end,
}
subscription(event("RETURN"))
assert(command.executeCount == 1, "Enter outside dialogue executed the command")

activeRoot = root
contentRoot.VisualChildrenCount = 0
subscription(event("RETURN"))
assert(command.executeCount == 1, "Enter after dialogue close executed the command")

-- A new view model (as after a reply transition or save reload) is read fresh.
contentRoot.VisualChildrenCount = 1
local replacementCommand = { executeCount = 0 }
function replacementCommand:CanExecute(playerId)
    return playerId == 8
end
function replacementCommand:Execute(playerId)
    self.executeCount = self.executeCount + 1
    self.lastPlayerId = playerId
end
dialogue.DataContext = vm({ PlayerId = 8, SelectorEnterCommand = replacementCommand,
    CurrentPlayer = vm({ PlayerId = 8, SelectedCharacter = vm({
        PlayerCharacterProperties = vm({ ActiveDialogue = vm({ ShowAnswers = true }) }),
    }) }),
})
subscription(event("KP_ENTER"))
assert(replacementCommand.executeCount == 1 and replacementCommand.lastPlayerId == 8,
    "a changed dialogue view model was not used")

print("DialogueEnterHandler tests passed")
