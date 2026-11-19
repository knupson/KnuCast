local _, ns = ...
local L = ns.L

local Commands = {}
ns.Commands = Commands

local function FormatBool(v)
    return v and L['on'] or L['off']
end

local function ParseToggle(arg, current)
    if arg == 'on' or arg == '1' or arg == 'true' or arg == 'si' or arg == 'sí' then
        return true
    elseif arg == 'off' or arg == '0' or arg == 'false' or arg == 'no' then
        return false
    elseif arg == '' then
        return not current
    end
    return nil
end

function Commands.PrintStatus()
    ns.Print(string.format(
        L['Status: glow=%s, grey=%s, sound=%s, test=%s'],
        FormatBool(ns.db.glow),
        FormatBool(ns.db.grey),
        FormatBool(ns.db.sound),
        FormatBool(ns.Engine.testMode)
    ))
    ns.Print(L['Commands: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]'])
end

function Commands.PrintDebug()
    local targetType = L['none']
    if type(UnitCreatureType) == 'function' then
        local ok, _, rawTypeID = pcall(UnitCreatureType, 'target')
        if ok then
            if not ns.Secret.Accessible(rawTypeID) then
                targetType = L['secret']
            elseif type(rawTypeID) == 'number' then
                targetType = tostring(rawTypeID)
            end
        end
    end

    local casting = ns.Engine:IsTargetCasting('target')
    local castingText
    if casting == true then
        castingText = L['yes']
    elseif casting == false then
        castingText = L['no']
    else
        castingText = L['secret']
    end

    local totalButtons = #ns.Buttons.list
    local withRules = ns.Buttons:CountButtonsWithRules()
    ns.Print(string.format(
        L['Debug: targetType=%s, casting=%s, buttons=%d, withRules=%d'],
        targetType,
        castingText,
        totalButtons,
        withRules
    ))
end

function Commands.Handle(msg)
    msg = strtrim(msg or '')
    local sub, rest = msg:match('^(%S*)%s*(.-)$')
    sub = string.lower(sub or '')
    rest = string.lower(strtrim(rest or ''))

    if sub == 'glow' then
        local val = ParseToggle(rest, ns.db.glow)
        if val == nil then
            return Commands.PrintStatus()
        end
        ns.db.glow = val
        ns.Print(string.format(L['Glow overlay: %s'], FormatBool(val)))
        ns.Engine:UpdateAll()
        return
    elseif sub == 'grey' then
        local val = ParseToggle(rest, ns.db.grey)
        if val == nil then
            return Commands.PrintStatus()
        end
        ns.db.grey = val
        ns.Print(string.format(L['Grey overlay: %s'], FormatBool(val)))
        ns.Engine:UpdateAll()
        return
    elseif sub == 'sound' then
        local val = ParseToggle(rest, ns.db.sound)
        if val == nil then
            return Commands.PrintStatus()
        end
        ns.db.sound = val
        ns.Print(string.format(L['Sound alert: %s'], FormatBool(val)))
        return
    elseif sub == 'debug' then
        return Commands.PrintDebug()
    elseif sub == 'test' then
        ns.Engine.testMode = not ns.Engine.testMode
        ns.Print(string.format(L['Test mode: %s'], FormatBool(ns.Engine.testMode)))
        ns.Engine:UpdateAll()
        return
    end

    return Commands.PrintStatus()
end

function Commands:Register()
    ns.KL:RegisterCommand('cast', Commands.Handle, L['Situational spell highlights on action buttons'], { 'knucast' })
end

Commands:Register()

ns:RegisterEvent('PLAYER_LOGIN', function()
    Commands:Register()
end)
