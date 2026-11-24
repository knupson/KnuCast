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
        L['Status: glow=%s, cross=%s, sound=%s, test=%s'],
        FormatBool(ns.db.glow),
        FormatBool(ns.db.grey),
        FormatBool(ns.db.sound),
        FormatBool(ns.Engine.testMode)
    ))
    ns.Print(L['Commands: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]'])
    Commands.PrintFeedback()
    ns.Print(string.format(L['Other KNU addons: KnuCompanion (%s) and more at %s'], 'https://companion.knunet.com', 'https://www.curseforge.com/members/knupwns/projects'))
end

local CURSEFORGE_URL = 'https://www.curseforge.com/wow/addons/knucast'
local ISSUES_URL = 'https://github.com/knupson/KnuCast/issues'

function Commands.PrintFeedback()
    ns.Print(string.format(L['Like it? Add it to your favorites on CurseForge and leave a comment: %s'], CURSEFORGE_URL))
    ns.Print(string.format(L['Found a bug? Report it with the BugSack error text: %s'], ISSUES_URL))
end

-- Shown once per account; KnuCastDB is account-wide.
function Commands.ShowFeedbackOnce()
    if ns.db.feedbackShown then
        return
    end
    ns.db.feedbackShown = true
    Commands.PrintFeedback()
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

    local playerClass = ns.Data.GetPlayerClass()
    if playerClass then
        local ruleButtonCounts = {}
        local ruleFirstButton = {}
        for i = 1, #ns.Buttons.list do
            local btn = ns.Buttons.list[i]
            local rules = ns.Buttons.GetButtonRules(btn)
            if rules then
                for j = 1, #rules do
                    local r = rules[j]
                    ruleButtonCounts[r] = (ruleButtonCounts[r] or 0) + 1
                    if not ruleFirstButton[r] then
                        ruleFirstButton[r] = btn
                    end
                end
            end
        end

        local STATE_TEXT = {
            [ns.Engine.YES] = L['yes'],
            [ns.Engine.NO] = L['no'],
            [ns.Engine.UNKNOWN] = L['unknown'],
        }
        local VISUAL_TEXT = { glow = 'glowing', grey = 'greyed', none = 'unmarked' }
        local canAttack = ns.Secret.CanAttack('target')

        for i = 1, #ns.Data.RULES do
            local rule = ns.Data.RULES[i]
            if rule.class == playerClass then
                local spellName = ns.Data.GetSpellName(rule.id)
                if not spellName then
                    spellName = ns.Data:IsSpellMissing(rule.id) and L['missing in this client'] or L['pending']
                end
                -- The mark shown is the one on the first button that holds the rule.
                local verdict = L['none']
                local visual = L['none']
                local btn = ruleFirstButton[rule]
                if btn and canAttack then
                    local slot = ns.Buttons.GetSlot(btn)
                    verdict = STATE_TEXT[ns.Engine:EvalRule(rule, slot, 'target')] or L['unknown']
                end
                if btn then
                    visual = L[VISUAL_TEXT[ns.Buttons:GetVisual(btn)] or 'unmarked']
                end
                ns.Print(string.format(
                    L['Rule %d: %s (%s) - %d buttons - applies: %s - mark: %s'],
                    rule.id,
                    spellName,
                    tostring(rule.kind),
                    ruleButtonCounts[rule] or 0,
                    verdict,
                    visual
                ))
            end
        end
    end
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
        ns.Print(string.format(L['Red cross: %s'], FormatBool(val)))
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
    ns.KL:RegisterCommand('cast', Commands.Handle, L['Highlights situational spells on action buttons and crosses out the ones that do not work'], { 'knucast' })
end

-- Registered through KnuLib's login queue: deferred until PLAYER_LOGIN, or run
-- immediately if the client is already logged in (KnuLib MINOR 5).
ns.KL:OnLogin(function()
    Commands:Register()
    Commands.ShowFeedbackOnce()
end)
