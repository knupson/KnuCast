local Stub = dofile('tests/wow_stub.lua')

local passed = 0
local failed = 0

local function Assert(cond, msg)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ' .. tostring(msg) .. '\n')
    end
end

local function AssertEq(actual, expected, msg)
    if actual == expected then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write(string.format(
            'FAIL: %s (expected %s, got %s)\n',
            tostring(msg),
            tostring(expected),
            tostring(actual)
        ))
    end
end

-- Load files listed in KnuCast.toc (supporting both .xml and .lua entries).
local addonName = 'KnuCast'
local ns = {}

local function LoadLuaFile(path)
    path = path:gsub('\\', '/')
    -- Bytecode check first to verify clean Lua 5.1 syntax.
    local chunk, err = loadfile(path)
    Assert(chunk ~= nil, 'Syntax/loadfile check for ' .. path .. ': ' .. tostring(err))
    if chunk then
        chunk(addonName, ns)
    end
end

local function LoadXmlFile(xmlPath)
    xmlPath = xmlPath:gsub('\\', '/')
    local dir = xmlPath:match('^(.*)/[^/]+$') or '.'
    local fh = assert(io.open(xmlPath, 'r'))
    local content = fh:read('*a')
    fh:close()
    for scriptRel in content:gmatch('<Script%s+file="([^"]+)"') do
        LoadLuaFile(dir .. '/' .. scriptRel)
    end
end

local function LoadFromToc(tocPath)
    local fh = assert(io.open(tocPath, 'r'))
    for line in fh:lines() do
        line = strtrim(line)
        if line ~= '' and not line:match('^#') then
            if line:match('%.xml$') then
                LoadXmlFile(line)
            elseif line:match('%.lua$') then
                LoadLuaFile(line)
            end
        end
    end
    fh:close()
end

LoadFromToc('KnuCast.toc')

-- Verify command registration happens only on PLAYER_LOGIN, not at file load.
AssertEq(ns.KL.commands['cast'], nil, 'Command is not registered at file load')
Stub.FireEvent('PLAYER_LOGIN')
Assert(ns.KL.commands['cast'] ~= nil, 'Command is registered on PLAYER_LOGIN')

-- Feedback invitation: once per account on login, plus at the end of the help.
do
    AssertEq(ns.db.feedbackShown, true, 'Feedback line is flagged as shown after PLAYER_LOGIN')
    local loginChat = table.concat(Stub.chatMessages or {}, '\n')
    Assert(loginChat:find('curseforge.com/wow/addons/knucast', 1, true) ~= nil, 'Login prints the CurseForge link once')
    Assert(loginChat:find('github.com/knupson/KnuCast/issues', 1, true) ~= nil, 'Login prints the issues link once')
    local before = #Stub.chatMessages
    ns.Commands.ShowFeedbackOnce()
    AssertEq(#Stub.chatMessages, before, 'Feedback line is not repeated once flagged')
    ns.KL:Dispatch('cast')
    local helpChat = table.concat(Stub.chatMessages, '\n', before + 1)
    Assert(helpChat:find('curseforge.com/wow/addons/knucast', 1, true) ~= nil, 'Help footer includes the CurseForge link')
end

-- Also syntax-check the test files themselves.
do
    local c1, e1 = loadfile('tests/wow_stub.lua')
    Assert(c1 ~= nil, 'Syntax check tests/wow_stub.lua: ' .. tostring(e1))
    local c2, e2 = loadfile('tests/run.lua')
    Assert(c2 ~= nil, 'Syntax check tests/run.lua: ' .. tostring(e2))
end

-- Not in Data.lua (no mark for it), but the reference case for kind = 'requires'
-- with auraUnit = 'player'.
local TEST_JUDGEMENT_RULE = { id = 20271, class = 'PALADIN', kind = 'requires', auraUnit = 'player',
    aura = { 21084, 21082, 20375, 20164, 20165, 20166, 1311649 } }
local TEST_CONFLAGRATE_RULE = { id = 17962, class = 'WARLOCK', kind = 'requires', auraUnit = 'target', aura = { 348 } }
local function WithTestRule(rule, fn)
    table.insert(ns.Data.RULES, rule)
    ns.Data:BuildIndex()
    local ok, err = pcall(fn)
    for i = #ns.Data.RULES, 1, -1 do
        if ns.Data.RULES[i] == rule then table.remove(ns.Data.RULES, i) end
    end
    ns.Data:BuildIndex()
    if not ok then error(err, 0) end
end

local function ResetTestEnvironment(classToken)
    Stub.ClearSecrets()
    Stub.inCombat = false
    Stub.playerClass = { classToken or 'Paladin', classToken or 'PALADIN' }
    Stub.units = {}
    Stub.actions = {}
    Stub.usableActions = {}
    Stub.auras = {}
    Stub.chatMessages = {}
    Stub.soundsPlayed = {}
    Stub.ResetSpells()

    for i = 1, 12 do
        _G['ActionButton' .. i] = nil
        _G['ElvUI_Bar1Button' .. i] = nil
    end
    for i = 1, 10 do
        _G['BT4Button' .. i] = nil
        _G['DominosActionButton' .. i] = nil
    end

    _G.KnuCastDB = nil
    ns:InitDB()
    ns.Engine.testMode = false
    ns.Engine:ResetTargetState()
    ns.Buttons:Reset()
    ns.Data:BuildIndex()
end

-- 1. Secret guards test
do
    ResetTestEnvironment('PALADIN')
    AssertEq(ns.Secret.Accessible(42), true, 'Normal number is accessible')
    AssertEq(ns.Secret.Accessible(false), true, 'Normal boolean false is accessible')
    AssertEq(ns.Secret.Accessible(nil), true, 'nil is accessible')

    local secretProxy = Stub.MarkSecret()
    local secretBool = Stub.MarkSecret(true)
    local secretNum = Stub.MarkSecret(6)

    AssertEq(issecretvalue(secretProxy), true, 'issecretvalue returns true for marked proxy')
    AssertEq(canaccessvalue(secretProxy), false, 'canaccessvalue returns false for marked proxy')
    AssertEq(ns.Secret.Accessible(secretProxy), false, 'Secret.Accessible false for marked proxy')
    AssertEq(ns.Secret.Accessible(secretBool), false, 'Secret.Accessible false for marked boolean')
    AssertEq(ns.Secret.Accessible(secretNum), false, 'Secret.Accessible false for marked number')

    -- Marking true/6 must not taint ordinary primitives, and secret operations must error
    AssertEq(ns.Secret.Accessible(true), true, 'Ordinary true remains accessible after MarkSecret(true)')
    AssertEq(ns.Secret.Accessible(6), true, 'Ordinary 6 remains accessible after MarkSecret(6)')
    local okAdd = pcall(function() return secretNum + 1 end)
    AssertEq(okAdd, false, 'Arithmetic on secret number proxy raises error')
    local okConcat = pcall(function() return Stub.MarkSecret('a') .. 'b' end)
    AssertEq(okConcat, false, 'Concatenation on secret string proxy raises error')

    -- Target with secret UnitCanAttack must not glow or grey
    Stub.units.target = { canAttack = secretBool, creatureTypeID = 6 }
    AssertEq(ns.Secret.CanAttack('target'), false, 'CanAttack is false when UnitCanAttack is secret')
end

-- 2. Creature type yes/no/unknown
do
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 5614 } -- Exorcism Rank 2 (matches Rank 1 name)
    ns.Buttons:Discover()

    -- YES: Undead (6)
    Stub.units.target = { canAttack = true, creatureTypeID = 6 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Secret.CreatureTypeID('target'), 6, 'CreatureTypeID returns 6 for Undead')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Exorcism glows on Undead (6)')

    -- YES: Demon (3)
    Stub.units.target = { canAttack = true, creatureTypeID = 3 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Exorcism glows on Demon (3)')

    -- NO: Beast (1)
    Stub.units.target = { canAttack = true, creatureTypeID = 1 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Exorcism greys out on Beast (1)')

    -- UNKNOWN: Secret creature type
    local secretType = Stub.MarkSecret(6)
    Stub.units.target = { canAttack = true, creatureTypeID = secretType }
    ns.Engine:UpdateAll()
    AssertEq(ns.Secret.CreatureTypeID('target'), nil, 'CreatureTypeID returns nil when secret')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Exorcism shows no overlay when creature type is secret')

    -- Friendly target clears overlays
    Stub.units.target = { canAttack = false, creatureTypeID = 6 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Exorcism clears overlay on friendly target')
end

-- 3. Debuff present/missing/unknown
do
    ResetTestEnvironment('WARLOCK')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 6222 } -- Corruption (higher rank)
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7 }

    -- Missing: no auras on target -> PlayerDebuffState == false -> glow
    Stub.auras.target = {}
    AssertEq(ns.Secret.PlayerDebuffState('target', 'Corruption'), false, 'Debuff missing returns false')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Corruption glows when debuff is missing')

    -- Present: Corruption is on target -> PlayerDebuffState == true -> none
    Stub.auras.target = {
        { name = 'Immolate' },
        { name = 'Corruption' },
    }
    AssertEq(ns.Secret.PlayerDebuffState('target', 'Corruption'), true, 'Debuff present returns true')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Corruption has no overlay when debuff is present')

    -- Unknown: secret aura name -> PlayerDebuffState == nil -> none
    local secretAuraName = Stub.MarkSecret('Corruption')
    Stub.auras.target = {
        { name = secretAuraName },
    }
    AssertEq(ns.Secret.PlayerDebuffState('target', 'Corruption'), nil, 'Secret aura name returns nil (unknown)')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Corruption has no overlay when aura is secret')
end

-- 4. Interrupt casting/not/unknown (+ event fallback)
do
    ResetTestEnvironment('ROGUE')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 1766 } -- Kick
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7 }

    -- Not casting
    AssertEq(ns.Secret.IsCasting('target'), false, 'IsCasting is false when target not casting')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick has no overlay when target not casting')

    -- Casting interruptible spell
    Stub.units.target.casting = { name = 'Shadow Bolt', notInterruptible = false }
    AssertEq(ns.Secret.IsCasting('target'), true, 'IsCasting is true on interruptible cast')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows on interruptible cast')

    -- Casting uninterruptible spell
    Stub.units.target.casting = { name = 'Divine Shield', notInterruptible = true }
    AssertEq(ns.Secret.IsCasting('target'), false, 'IsCasting is false on uninterruptible cast')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick does not glow on uninterruptible cast')

    -- Unknown (secret cast name) + UNIT_SPELLCAST_* event fallback with secret unit token proxy
    local secretCastName = Stub.MarkSecret('Heal')
    local secretTargetUnit = Stub.MarkSecret('target')
    local secretFocusUnit = Stub.MarkSecret('focus')
    Stub.units.target.casting = { name = secretCastName }
    AssertEq(ns.Secret.IsCasting('target'), true, 'IsCasting is true when the cast info comes back secret (casting, measured in game)')
    ns.Engine:ResetTargetState()
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows on a secret cast seen right after a target change, with no event')

    -- UNIT_SPELLCAST_* events trigger recomputation (cast info present, secret)
    Stub.units.target.casting = nil
    ns.Engine:ResetTargetState()
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick has no overlay when the target is not casting')
    Stub.units.target.casting = { name = secretCastName } -- in game the cast info comes back secret while casting

    -- Non-target secret unit token must be ignored by RegisterUnitEvent filter
    Stub.FireEvent('UNIT_SPELLCAST_START', secretFocusUnit)
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick ignores UNIT_SPELLCAST_START for secret focus unit')

    -- Secret target unit token on dedicated RegisterUnitEvent('target') frame triggers fallback
    Stub.FireEvent('UNIT_SPELLCAST_START', secretTargetUnit)
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows via UNIT_SPELLCAST_START fallback with secret target token')

    Stub.FireEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', secretTargetUnit)
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick clears glow on UNIT_SPELLCAST_NOT_INTERRUPTIBLE with secret token')

    Stub.FireEvent('UNIT_SPELLCAST_INTERRUPTIBLE', secretTargetUnit)
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick restores glow on UNIT_SPELLCAST_INTERRUPTIBLE with secret token')

    Stub.units.target.casting = nil -- after STOP the client returns no cast info
    Stub.FireEvent('UNIT_SPELLCAST_STOP', secretTargetUnit)
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick clears glow on UNIT_SPELLCAST_STOP with secret token')

    -- Readable notInterruptible=true must be preserved even when cast name is secret
    Stub.units.target.casting = { name = secretCastName, notInterruptible = true }
    AssertEq(ns.Secret.IsCasting('target'), false, 'IsCasting returns false when cast name is secret but notInterruptible=true is readable')
    Stub.FireEvent('UNIT_SPELLCAST_START', secretTargetUnit)
    AssertEq(ns.Engine:IsTargetCasting('target'), false, 'IsTargetCasting is false when readable notInterruptible=true despite eventCasting=true')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick does not glow when secret-named cast has readable notInterruptible=true')

    -- Stale cached eventNotInterruptible=true must be overridden by current readable interruptible cast
    ns.Engine.eventCasting = true
    ns.Engine.eventNotInterruptible = true
    Stub.units.target.casting = { name = 'Shadow Bolt', notInterruptible = false }
    ns.Engine:UpdateAll()
    AssertEq(ns.Engine:IsTargetCasting('target'), true, 'Readable interruptible cast overrides stale eventNotInterruptible=true')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows when readable interruptible cast overrides stale event cache')

    -- Readable notInterruptible=false with secret cast name also overrides stale eventNotInterruptible=true
    ns.Engine.eventCasting = true
    ns.Engine.eventNotInterruptible = true
    Stub.units.target.casting = { name = secretCastName, notInterruptible = false }
    ns.Engine:UpdateAll()
    AssertEq(ns.Engine:IsTargetCasting('target'), true, 'Readable notInterruptible=false with secret name overrides stale eventNotInterruptible')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows when secret-named cast has readable notInterruptible=false')

    -- True event fallback: cast info unreadable (call errors) -> direct state unknown,
    -- so only UNIT_SPELLCAST_START / STOP decide.
    do
        local origCast, origChan = _G.UnitCastingInfo, _G.UnitChannelInfo
        _G.UnitCastingInfo = function() error('cast info unavailable') end
        _G.UnitChannelInfo = function() error('channel info unavailable') end
        ns.Engine:ResetTargetState()
        ns.Engine:UpdateAll()
        AssertEq(ns.Secret.IsCasting('target'), nil, 'IsCasting is unknown when the cast info call errors')
        AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'No glow before any cast event when cast info is unreadable')
        Stub.FireEvent('UNIT_SPELLCAST_START', 'target')
        AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Event fallback: UNIT_SPELLCAST_START alone makes Kick glow')
        Stub.FireEvent('UNIT_SPELLCAST_STOP', 'target')
        AssertEq(ns.Engine.eventCasting, false, 'UNIT_SPELLCAST_STOP records the end of the cast')
        AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Event fallback: UNIT_SPELLCAST_STOP alone clears the glow')
        _G.UnitCastingInfo, _G.UnitChannelInfo = origCast, origChan
    end

    -- Fallback unit check when RegisterUnitEvent is unavailable: rejects secret unit token without error
    ns.Engine:ResetTargetState()
    Stub.units.target.casting = { name = secretCastName }
    ns.unitFiltered['target']['UNIT_SPELLCAST_START'] = false
    ns.FireUnitEvent(ns, 'target', 'UNIT_SPELLCAST_START', secretTargetUnit)
    AssertEq(ns.Engine.eventCasting, nil, 'Fallback unit filter rejects secret unit token safely')
    ns.FireUnitEvent(ns, 'target', 'UNIT_SPELLCAST_START', 'target')
    AssertEq(ns.Engine.eventCasting, true, 'Fallback unit filter accepts accessible target unit')
    ns.unitFiltered['target']['UNIT_SPELLCAST_START'] = true
end

-- 5. Execute via usable action (C_ActionBar.IsUsableAction + fallback IsUsableAction)
do
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 24275 } -- Hammer of Wrath
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7 }

    -- Not usable
    Stub.usableActions[1] = false
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Hammer of Wrath has no overlay when not usable')

    -- Usable via C_ActionBar.IsUsableAction
    Stub.usableActions[1] = true
    Stub.FireEvent('ACTION_USABLE_CHANGED')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Hammer of Wrath glows when usable')

    -- Fallback to global IsUsableAction when C_ActionBar is absent
    local savedActionBar = _G.C_ActionBar
    _G.C_ActionBar = nil
    AssertEq(ns.Secret.IsActionUsable(1), true, 'IsActionUsable falls back to global IsUsableAction')
    _G.C_ActionBar = savedActionBar
end

-- 6. Precedence (any NO -> grey)
do
    ResetTestEnvironment('PALADIN')
    AssertEq(
        ns.Engine.CombineStates({ ns.Engine.UNKNOWN, ns.Engine.YES, ns.Engine.NO }),
        ns.Engine.NO,
        'CombineStates gives NO when any state is NO'
    )
    AssertEq(
        ns.Engine.CombineStates({ ns.Engine.UNKNOWN, ns.Engine.YES }),
        ns.Engine.YES,
        'CombineStates gives YES when YES and UNKNOWN'
    )
    AssertEq(
        ns.Engine.CombineStates({ ns.Engine.UNKNOWN, ns.Engine.UNKNOWN }),
        ns.Engine.UNKNOWN,
        'CombineStates gives UNKNOWN when all are UNKNOWN'
    )

    -- Test button with two rules on the same spell: one YES (execute) and one NO (types)
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism (Undead/Demon)
    Stub.usableActions[1] = true
    -- Add an execute rule to Exorcism in the current index to test multi-rule precedence on a button
    local rules = ns.Data:GetRulesForSpell('Exorcism')
    rules[#rules + 1] = { id = 879, class = 'PALADIN', kind = 'execute' }

    ns.Buttons:Discover()
    -- Target is Beast (1): types -> NO, execute -> YES => precedence must choose NO (grey)
    Stub.units.target = { canAttack = true, creatureTypeID = 1 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Button with both YES and NO rules resolves to grey')
end

-- 7. Button slot resolution incl. LibActionButton _state_type ~= "action" ignored
do
    ResetTestEnvironment('PALADIN')
    local btnBlizz = CreateFrame('CheckButton', 'ActionButton1')
    btnBlizz.action = 3
    AssertEq(ns.Buttons.GetSlot(btnBlizz), 3, 'Blizzard button.action resolved')

    local btnLabAction = CreateFrame('CheckButton', 'ElvUI_Bar1Button1')
    btnLabAction._state_type = 'action'
    btnLabAction._state_action = 5
    AssertEq(ns.Buttons.GetSlot(btnLabAction), 5, 'LibActionButton with _state_type=="action" resolved')

    local btnLabMacro = CreateFrame('CheckButton', 'BT4Button1')
    btnLabMacro._state_type = 'macro'
    btnLabMacro._state_action = 5
    btnLabMacro.action = 5
    AssertEq(ns.Buttons.GetSlot(btnLabMacro), nil, 'LibActionButton with _state_type~="action" is ignored')

    local btnAttr = CreateFrame('CheckButton', 'DominosActionButton1')
    btnAttr:SetAttribute('action', 9)
    AssertEq(ns.Buttons.GetSlot(btnAttr), 9, 'Button with action attribute resolved')
end

-- 8. No overlay creation in combat (deferred to PLAYER_REGEN_ENABLED)
do
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism
    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead

    Stub.inCombat = true
    local discovered = ns.Buttons:Discover()
    AssertEq(discovered, false, 'Discover returns false during InCombatLockdown')
    AssertEq(ns.Buttons.overlays[btn1], nil, 'No overlay created during combat lockdown')
    AssertEq(#btn1._children, 0, 'No child frames attached to button during combat lockdown')

    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons.overlays[btn1], nil, 'UpdateAll does not create overlays in combat')

    -- Protected frame mutations in combat must be rejected by the stub
    local okAttr = pcall(btn1.SetAttribute, btn1, 'action', 2)
    AssertEq(okAttr, false, 'Protected button rejects SetAttribute during combat lockdown')
    local okChild = pcall(CreateFrame, 'Frame', nil, btn1)
    AssertEq(okChild, false, 'Protected button rejects child CreateFrame during combat lockdown')

    -- Leave combat and fire PLAYER_REGEN_ENABLED
    Stub.inCombat = false
    Stub.FireEvent('PLAYER_REGEN_ENABLED')
    Assert(ns.Buttons.overlays[btn1] ~= nil, 'Overlay created on PLAYER_REGEN_ENABLED')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Button state updated to glow on PLAYER_REGEN_ENABLED')
end

-- 9. Commands toggles (/knu cast glow|grey|sound|test|debug)
do
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Glow active initially')

    ns.KL:Dispatch('cast glow off')
    AssertEq(ns.db.glow, false, '/knu cast glow off disables glow setting')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Glow hidden when glow setting is off')

    ns.KL:Dispatch('knucast glow on')
    AssertEq(ns.db.glow, true, '/knu knucast glow on enables glow via alias')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Glow restored when glow setting is on')

    Stub.units.target = { canAttack = true, creatureTypeID = 1 } -- Beast
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Grey active on Beast')

    ns.KL:Dispatch('cast grey off')
    AssertEq(ns.db.grey, false, '/knu cast grey off disables grey setting')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Grey hidden when grey setting is off')

    ns.KL:Dispatch('cast grey on')
    AssertEq(ns.db.grey, true, '/knu cast grey on enables grey setting')

    ns.KL:Dispatch('cast sound on')
    AssertEq(ns.db.sound, true, '/knu cast sound on enables sound setting')
    ns.KL:Dispatch('cast sound off')
    AssertEq(ns.db.sound, false, '/knu cast sound off disables sound setting')

    -- Test mode toggle without target
    Stub.units.target = nil
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'No glow without target outside test mode')

    ns.KL:Dispatch('cast test')
    AssertEq(ns.Engine.testMode, true, 'First /knu cast test enables test mode')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Button with rule glows in test mode')

    ns.KL:Dispatch('cast test')
    AssertEq(ns.Engine.testMode, false, 'Second /knu cast test disables test mode')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Glow cleared when test mode is turned off')

    -- Debug and status output (including per-rule debug lines and matched button count)
    Stub.chatMessages = {}
    Stub.spells[2878] = nil -- Turn Undead uncached -> should print as pending
    ns.KL:Dispatch('cast debug')
    local debugOutput = table.concat(Stub.chatMessages, '\n')
    Assert(debugOutput:find('withRules=1', 1, true) ~= nil, 'debug prints count of action buttons matching a rule')
    Assert(debugOutput:find('879', 1, true) ~= nil and debugOutput:find('Exorcism', 1, true) ~= nil and debugOutput:find('types', 1, true) ~= nil and debugOutput:find('1 buttons', 1, true) ~= nil, 'debug prints rule 879 resolved name, kind and button count')
    Assert(debugOutput:find('2812', 1, true) ~= nil and debugOutput:find('Holy Wrath', 1, true) ~= nil, 'debug prints rule 2812 resolved name')
    Assert(debugOutput:find('2878', 1, true) ~= nil and debugOutput:find('pending', 1, true) ~= nil, 'debug prints pending for unresolved rule 2878')
    Assert(debugOutput:find('24275', 1, true) ~= nil and debugOutput:find('Hammer of Wrath', 1, true) ~= nil and debugOutput:find('execute', 1, true) ~= nil, 'debug prints rule 24275 resolved name and kind')
    Stub.spells[2878] = 'Turn Undead'

    local beforeStatus = #Stub.chatMessages
    ns.KL:Dispatch('cast')
    Assert(#Stub.chatMessages >= beforeStatus + 2, 'status command prints chat lines')
end

-- 10. Sound only for interrupt and execute (once per transition); silence for types and debuff
do
    -- 10a. Silence for creature-type transitions (types)
    ResetTestEnvironment('PALADIN')
    ns.db.sound = true
    local btnType1 = CreateFrame('CheckButton', 'ActionButton1')
    btnType1.action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism
    local btnType2 = CreateFrame('CheckButton', 'ActionButton2')
    btnType2.action = 2
    Stub.actions[2] = { type = 'spell', id = 2812 } -- Holy Wrath
    ns.Buttons:Discover()

    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead
    Stub.FireEvent('PLAYER_TARGET_CHANGED')
    AssertEq(ns.Buttons:GetVisual(btnType1), 'glow', 'Exorcism glows on Undead')
    AssertEq(ns.Buttons:GetVisual(btnType2), 'glow', 'Holy Wrath glows on Undead')
    AssertEq(#Stub.soundsPlayed, 0, 'No sound played on creature-type transition to glow')

    -- 10b. Silence for missing-debuff transitions (debuff)
    ResetTestEnvironment('WARLOCK')
    ns.db.sound = true
    local btnDebuff = CreateFrame('CheckButton', 'ActionButton1')
    btnDebuff.action = 1
    Stub.actions[1] = { type = 'spell', id = 172 } -- Corruption
    ns.Buttons:Discover()

    Stub.units.target = { canAttack = true, creatureTypeID = 7 }
    Stub.auras.target = {}
    Stub.FireEvent('PLAYER_TARGET_CHANGED')
    AssertEq(ns.Buttons:GetVisual(btnDebuff), 'glow', 'Corruption glows when debuff is missing')
    AssertEq(#Stub.soundsPlayed, 0, 'No sound played on debuff transition to glow')

    -- 10c. Sound once per transition for interrupt (even with two interrupt buttons)
    ResetTestEnvironment('WARRIOR')
    ns.db.sound = true
    local btnInt1 = CreateFrame('CheckButton', 'ActionButton1')
    btnInt1.action = 1
    Stub.actions[1] = { type = 'spell', id = 72 } -- Shield Bash
    local btnInt2 = CreateFrame('CheckButton', 'ActionButton2')
    btnInt2.action = 2
    Stub.actions[2] = { type = 'spell', id = 6552 } -- Pummel
    ns.Buttons:Discover()

    Stub.units.target = {
        canAttack = true,
        creatureTypeID = 7,
        casting = { name = 'Shadow Bolt', notInterruptible = false },
    }
    Stub.FireEvent('UNIT_SPELLCAST_START', 'target')
    AssertEq(ns.Buttons:GetVisual(btnInt1), 'glow', 'Shield Bash glows on interruptible cast')
    AssertEq(ns.Buttons:GetVisual(btnInt2), 'glow', 'Pummel glows on interruptible cast')
    AssertEq(#Stub.soundsPlayed, 1, 'Exactly one sound played when two interrupt buttons transition to glow')

    -- Repeated updates without state change must NOT play another sound
    Stub.FireEvent('UNIT_AURA', 'target')
    Stub.FireEvent('ACTIONBAR_UPDATE_USABLE')
    AssertEq(#Stub.soundsPlayed, 1, 'No additional sound when interrupt state has not transitioned')

    -- Cast stops (no glow), then new cast starts (glow again) -> second sound
    Stub.units.target.casting = nil
    Stub.FireEvent('UNIT_SPELLCAST_STOP', 'target')
    AssertEq(#Stub.soundsPlayed, 1, 'No sound when cast stops')

    Stub.units.target.casting = { name = 'Shadow Bolt', notInterruptible = false }
    Stub.FireEvent('UNIT_SPELLCAST_START', 'target')
    AssertEq(#Stub.soundsPlayed, 2, 'Second sound played on new interrupt transition to glow')

    -- 10d. Sound for execute transition
    ResetTestEnvironment('PALADIN')
    ns.db.sound = true
    local btnExec = CreateFrame('CheckButton', 'ActionButton1')
    btnExec.action = 1
    Stub.actions[1] = { type = 'spell', id = 24275 } -- Hammer of Wrath
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7 }
    Stub.usableActions[1] = true
    Stub.FireEvent('ACTION_USABLE_CHANGED')
    AssertEq(ns.Buttons:GetVisual(btnExec), 'glow', 'Hammer of Wrath glows when usable')
    AssertEq(#Stub.soundsPlayed, 1, 'Sound played on execute transition to glow')
end

-- 11. LibActionButton OnButtonUpdate / OnButtonState callback refresh (in and out of combat)
do
    ResetTestEnvironment('PALADIN')
    local callbacks = {}
    local lab = LibStub:NewLibrary('LibActionButton-1.0', 99)
    function lab.RegisterCallback(target, event, handler)
        callbacks[event] = { target = target, handler = handler }
    end
    local function FireLAB(event, button)
        local entry = callbacks[event]
        if entry and type(entry.handler) == 'function' then
            entry.handler(event, button)
        end
    end

    local btnLab = CreateFrame('CheckButton', 'ElvUI_Bar1Button1')
    btnLab._state_type = 'action'
    btnLab._state_action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism
    Stub.actions[2] = nil

    ns.Buttons:Discover()
    Assert(callbacks.OnButtonUpdate ~= nil, 'Subscribed to LibActionButton OnButtonUpdate')
    Assert(callbacks.OnButtonState ~= nil, 'Subscribed to LibActionButton OnButtonState')

    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btnLab), 'glow', 'LAB button glows on Undead initially')

    -- Enter combat: existing overlay must refresh on LAB state change without creating frames
    Stub.inCombat = true
    btnLab._state_action = 2 -- paged to empty slot
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'none', 'LAB button clears glow when _state_action pages to empty slot')

    btnLab._state_action = 1 -- paged back to Exorcism slot
    FireLAB('OnButtonState', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'glow', 'LAB button restores glow on OnButtonState')

    btnLab._state_type = 'macro' -- switched to macro state
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'none', 'LAB button clears glow when switched to macro state')
    Stub.inCombat = false
end

-- 12. Unresolved higher-rank action spell ID requested, tracked, and refreshed on SPELL_DATA_LOAD_RESULT
do
    ResetTestEnvironment('PALADIN')
    -- Base rule 879 (Exorcism) is already indexed, so hasPendingSpells is false
    AssertEq(ns.Data.hasPendingSpells, false, 'Base rules resolved with no pending rule spells')

    -- Remove higher-rank Exorcism (5614) from spell cache before placing it on a button
    Stub.spells[5614] = nil
    Stub.lastRequestedSpell = nil

    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 5614 }
    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead

    ns.Buttons:Discover()
    ns.Engine:UpdateAll()
    AssertEq(Stub.lastRequestedSpell, 5614, 'RequestLoadSpellData called for uncached rank 5614')
    AssertEq(ns.Data.hasPendingActionSpells, true, 'hasPendingActionSpells is true while 5614 is uncached')
    AssertEq(ns.Data.pendingActionSpells[5614], true, 'Spell 5614 tracked in pendingActionSpells')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'No overlay before rank 5614 data loads')

    -- Simulate async spell data load completion for rank 5614
    Stub.spells[5614] = 'Exorcism'
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 5614, true)
    AssertEq(ns.Data.hasPendingActionSpells, false, 'hasPendingActionSpells cleared once 5614 resolves')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Overlay refreshed to glow when rank 5614 loads')
end

-- 13. Spell request deduplication, success=false retry cap (max 2), and targeted button refresh
do
    ResetTestEnvironment('PALADIN')
    Stub.spells[5614] = nil -- Uncached Exorcism Rank 2
    Stub.spells[99999] = nil -- Non-existent / failing spell

    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 5614 }

    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 2812 } -- Holy Wrath (already cached)

    local btn3 = CreateFrame('CheckButton', 'ActionButton3')
    btn3.action = 3
    Stub.actions[3] = { type = 'spell', id = 99999 }

    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead

    ns.Buttons:Discover()
    -- Discover called GetSlotSpellName once; now call UpdateAll multiple times while in-flight
    ns.Engine:UpdateAll()
    ns.Engine:UpdateAll()
    ns.Data:TrackActionSpell(5614)
    ns.Data:TrackActionSpell(99999)

    AssertEq(Stub.spellRequestCounts[5614], 1, 'In-flight spell 5614 requested only once across repeated lookups')
    AssertEq(Stub.spellRequestCounts[99999], 1, 'In-flight spell 99999 requested only once across repeated lookups')

    -- Spy on SetVisual to verify SPELL_DATA_LOAD_RESULT refreshes only affected buttons
    local touchedButtons = {}
    local origSetVisual = ns.Buttons.SetVisual
    ns.Buttons.SetVisual = function(self, button, visual)
        touchedButtons[button] = (touchedButtons[button] or 0) + 1
        return origSetVisual(self, button, visual)
    end

    -- First failure for 99999: marks failed, does not refresh any buttons
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 99999, false)
    AssertEq(ns.Data.failedSpells[99999], true, 'Spell 99999 marked as failed on success=false')
    AssertEq(ns.Data.inFlightSpells[99999], nil, 'In-flight flag cleared on SPELL_DATA_LOAD_RESULT')
    AssertEq(next(touchedButtons), nil, 'No buttons refreshed when SPELL_DATA_LOAD_RESULT has success=false')

    -- Next lookup retries 99999 once (attempt 2 of 2), deduplicated while in-flight
    ns.Engine:UpdateAll()
    ns.Engine:UpdateAll()
    AssertEq(Stub.spellRequestCounts[99999], 2, 'Spell 99999 retried a second time after first failure')

    -- Second failure for 99999: capped at 2 total requests and removed from pending
    touchedButtons = {}
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 99999, false)
    AssertEq(ns.Data.failedSpells[99999], true, 'Spell 99999 remains marked failed after second failure')
    AssertEq(ns.Data.pendingActionSpells[99999], nil, 'Spell 99999 removed from pendingActionSpells after 2 failures')
    AssertEq(next(touchedButtons), nil, 'No buttons refreshed on second failure')

    -- Further lookups must NOT request 99999 a 3rd time
    ns.Engine:UpdateAll()
    ns.Data:TrackActionSpell(99999)
    AssertEq(Stub.spellRequestCounts[99999], 2, 'Spell 99999 never requested more than 2 times total')
    AssertEq(ns.Data.pendingActionSpells[99999], nil, 'Spell 99999 not re-added to pendingActionSpells after cap')

    -- Resolve 5614: only btn1 (which holds 5614) should be refreshed, not btn2 or btn3
    touchedButtons = {}
    Stub.spells[5614] = 'Exorcism'
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 5614, true)
    AssertEq(touchedButtons[btn1], 1, 'Affected button btn1 refreshed when 5614 loads')
    AssertEq(touchedButtons[btn2], nil, 'Unaffected button btn2 not refreshed when 5614 loads')
    AssertEq(touchedButtons[btn3], nil, 'Unaffected button btn3 not refreshed when 5614 loads')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'btn1 glows after 5614 loads')

    ns.Buttons.SetVisual = origSetVisual
end

-- 14. UpdateButton (LibActionButton callback path) sound transition logic
do
    ResetTestEnvironment('ROGUE')
    ns.db.sound = true

    local callbacks = {}
    local lab = LibStub:NewLibrary('LibActionButton-1.0', 100)
    function lab.RegisterCallback(target, event, handler)
        callbacks[event] = { target = target, handler = handler }
    end
    local function FireLAB(event, button)
        local entry = callbacks[event]
        if entry and type(entry.handler) == 'function' then
            entry.handler(event, button)
        end
    end

    local btnLab = CreateFrame('CheckButton', 'ElvUI_Bar1Button1')
    btnLab._state_type = 'action'
    btnLab._state_action = 2 -- starts on empty slot
    Stub.actions[1] = { type = 'spell', id = 1766 } -- Kick (interrupt)
    Stub.actions[2] = nil

    ns.Buttons:Discover()
    Stub.units.target = {
        canAttack = true,
        creatureTypeID = 7,
        casting = { name = 'Shadow Bolt', notInterruptible = false },
    }
    ns.Engine:UpdateAll()
    AssertEq(#Stub.soundsPlayed, 0, 'No sound when interrupt spell is not on active button')

    -- LAB pages button onto Kick while target is casting -> plays sound once
    btnLab._state_action = 1
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'glow', 'LAB button glows when paged to Kick during cast')
    AssertEq(#Stub.soundsPlayed, 1, 'Sound played once when UpdateButton transitions to interrupt glow')

    -- Repeated LAB callback without state change must not play sound again
    FireLAB('OnButtonState', btnLab)
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(#Stub.soundsPlayed, 1, 'No duplicate sound on subsequent UpdateButton calls while already active')

    -- LAB pages away to empty slot, then back to Kick -> plays second sound on new transition
    btnLab._state_action = 2
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'none', 'LAB button clears glow when paged away')
    AssertEq(#Stub.soundsPlayed, 1, 'No sound when transitioning away from interrupt')

    btnLab._state_action = 1
    FireLAB('OnButtonUpdate', btnLab)
    AssertEq(ns.Buttons:GetVisual(btnLab), 'glow', 'LAB button glows again when paged back to Kick')
    AssertEq(#Stub.soundsPlayed, 2, 'Second sound played when UpdateButton transitions back to interrupt glow')
end


-- KnuLib MINOR 5 integration
do
    local KL = ns.KL
    AssertEq(KL.minor or select(2, LibStub:GetLibrary('KnuLib-1.0')), 7, 'Embedded KnuLib is MINOR 7')
    Assert(type(ns.events) == 'table' and type(ns.events.On) == 'function', 'ns.events is a KnuLib NewEvents object')

    local gotName, gotArg
    ns:RegisterEvent('KNUCAST_TEST_EVENT', function(event, arg)
        gotName, gotArg = event, arg
    end)
    Stub.FireEvent('KNUCAST_TEST_EVENT', 42)
    AssertEq(gotName, 'KNUCAST_TEST_EVENT', 'RegisterEvent handler receives the event name first')
    AssertEq(gotArg, 42, 'RegisterEvent handler receives the event payload after the name')

    local saved = { glow = false, conditions = { types = false } }
    KL:ApplyDefaults(saved, ns.DEFAULTS)
    AssertEq(saved.glow, false, 'ApplyDefaults keeps saved scalar values')
    AssertEq(saved.conditions.types, false, 'ApplyDefaults keeps saved nested values')
    AssertEq(saved.conditions.interrupt, true, 'ApplyDefaults fills missing nested defaults')
    Assert(saved.conditions ~= ns.DEFAULTS.conditions, 'ApplyDefaults does not alias the defaults table')

    -- An event the client rejects does not break registration of later handlers.
    local frame = ns.events.frame
    local origRegister = frame.RegisterEvent
    frame.RegisterEvent = function(self, event)
        if event == 'KNUCAST_BOGUS_EVENT' then
            error('Attempt to register unknown event')
        end
        return origRegister(self, event)
    end
    local okBogus, resBogus = pcall(ns.RegisterEvent, ns, 'KNUCAST_BOGUS_EVENT', function() end)
    AssertEq(okBogus, true, 'Registering an unknown event does not raise')
    AssertEq(resBogus, false, 'Registering an unknown event reports false')
    Assert(ns.events.invalid['KNUCAST_BOGUS_EVENT'] ~= nil, 'Unknown event error kept in ns.events.invalid')
    frame.RegisterEvent = origRegister
    local afterBogus = false
    ns:RegisterEvent('KNUCAST_VALID_AFTER_BOGUS', function() afterBogus = true end)
    Stub.FireEvent('KNUCAST_VALID_AFTER_BOGUS')
    AssertEq(afterBogus, true, 'A valid event registered after a rejected one still fires')

    -- OnLogin runs immediately once logged in.
    local ran = false
    KL:OnLogin(function() ran = true end)
    AssertEq(ran, true, 'KL:OnLogin runs immediately after PLAYER_LOGIN')
end

-- Condiciones 2 (requires, mana, outOfCombat, shared curses, sound counters, unit events)
do
    -- outOfCombat
    ResetTestEnvironment('ROGUE')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 6770 } -- Sap
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7, affectingCombat = true }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Sap is grey on humanoid in combat')

    Stub.units.target.affectingCombat = false
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Sap glows on humanoid out of combat')

    local secretCombat = Stub.MarkSecret(true)
    Stub.units.target.affectingCombat = secretCombat
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Sap glows if combat state is secret (fallback to types)')

    -- Real data: Judgement without a Seal is not marked
    ResetTestEnvironment('PALADIN')
    btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 20271 } -- Judgement
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.player = {}
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Judgement without any seal has no mark (shipped data)')

    -- requires (test rule shaped like the old Judgement one)
    WithTestRule(TEST_JUDGEMENT_RULE, function()
    ResetTestEnvironment('PALADIN')
    btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 20271 } -- Judgement
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.player = {}

    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Judgement is grey without any seal')

    Stub.auras.player = { { name = 'Seal of Command' } }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Judgement has no visual when seal is active')

    local secretAura = Stub.MarkSecret('Seal of Command')
    Stub.auras.player = { { name = secretAura } }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Judgement has no visual when seal is secret')
    end)

    -- mana
    ResetTestEnvironment('PRIEST')
    btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 8129 } -- Mana Burn
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, powerType = 1 } -- Rage
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Mana Burn is grey on target with Rage')

    Stub.units.target = { canAttack = true, powerType = 0, powerMax = 0 } -- Mana type but 0 max
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Mana Burn is grey on target with 0 max mana')

    Stub.units.target = { canAttack = true, powerType = 0, powerMax = 100 } -- Normal mana target
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Mana Burn has no visual on target with mana')
    
    Stub.units.target = { canAttack = true, powerType = Stub.MarkSecret(1) }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Mana Burn has no visual on target with secret power type')

    -- Forever: banes and curses are separate groups (one Bane and one Curse per warlock)
    ResetTestEnvironment('WARLOCK')
    btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 980 } -- Bane of Agony
    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 440892 } -- Curse of the Elements (Forever ID)
    ns.Buttons:Discover()

    Stub.units.target = { canAttack = true }
    Stub.auras.target = {}
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Bane of Agony glows when no bane is active')
    AssertEq(ns.Buttons:GetVisual(btn2), 'glow', 'Curse of the Elements glows when no curse is active')

    Stub.auras.target = { { name = 'Curse of Weakness' } }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Bane of Agony still glows when only a curse is present')
    AssertEq(ns.Buttons:GetVisual(btn2), 'none', 'Curse of the Elements loses glow when Curse of Weakness is present')

    Stub.auras.target = { { name = 'Bane of Doom' } }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Bane of Agony loses glow when Bane of Doom is present')
    AssertEq(ns.Buttons:GetVisual(btn2), 'glow', 'Curse of the Elements still glows when only a bane is present')

    -- An aura ID that does not exist in this client stops blocking namesComplete
    -- once its loads are exhausted (Classic IDs removed by Forever).
    ResetTestEnvironment('WARLOCK')
    local savedRules = ns.Data.RULES
    Stub.spells[999001] = 'Test Curse'
    ns.Data.RULES = { { id = 999001, class = 'WARLOCK', kind = 'debuff', debuff = { 999001, 999002 } } }
    ns.Data:BuildIndex()
    local missRule = ns.Data.bySpellName['Test Curse'][1]
    AssertEq(missRule.namesComplete, false, 'Unresolved aura ID keeps names incomplete at first')
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 999002, false)
    AssertEq(ns.Data.bySpellName['Test Curse'][1].namesComplete, false, 'One failed load (retry left) keeps names incomplete')
    ns.Data:BuildIndex() -- retries the request (second attempt)
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 999002, false)
    AssertEq(ns.Data:IsSpellMissing(999002), true, 'ID is treated as missing after exhausting its loads')
    AssertEq(ns.Data.bySpellName['Test Curse'][1].namesComplete, true, 'Missing ID no longer blocks namesComplete (index rebuilt)')
    ns.Data.RULES = savedRules
    Stub.spells[999001] = nil
    ns.Data:BuildIndex()

    -- N incremental updates with sound enabled must do linear total work.
    ResetTestEnvironment('WARRIOR')
    ns.db.sound = true
    local buttonCount = 12
    for i = 1, buttonCount do
        local btn = CreateFrame('CheckButton', 'ActionButton' .. i)
        btn.action = i
        Stub.actions[i] = { type = 'spell', id = 72 } -- Shield Bash
    end
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, casting = { name = 'Shadow Bolt', notInterruptible = false } }
    ns.Engine:UpdateAll()
    AssertEq(ns.Engine.activeKindCounts.interrupt, buttonCount, 'All interrupt buttons are active for performance measurement')
    AssertEq(#Stub.soundsPlayed, 1, 'Performance measurement has sound enabled')

    local ruleCalls = 0
    local orig = ns.Buttons.GetButtonRules
    ns.Buttons.GetButtonRules = function(...)
        ruleCalls = ruleCalls + 1
        return orig(...)
    end

    local iterations = 0
    local origPairs, origIpairs = pairs, ipairs
    local function countedIterator(iterator, state, key)
        return function(s, k)
            local nextKey, value = iterator(s, k)
            if nextKey ~= nil then iterations = iterations + 1 end
            return nextKey, value
        end, state, key
    end
    _G.pairs = function(t) return countedIterator(origPairs(t)) end
    _G.ipairs = function(t) return countedIterator(origIpairs(t)) end
    for i = 1, buttonCount do
        ns.Engine:UpdateButton(ns.Buttons.list[i])
    end
    _G.pairs, _G.ipairs = origPairs, origIpairs
    ns.Buttons.GetButtonRules = orig
    AssertEq(ruleCalls, buttonCount, 'N UpdateButton calls evaluate rules exactly N times with sound enabled')
    Assert(iterations <= 6 * buttonCount, 'N UpdateButton calls stay within a linear iteration bound')

    -- RegisterUnitEvent 'player' filter
    ResetTestEnvironment('PALADIN')
    local called = false
    ns:RegisterUnitEvent('player', 'KNUCAST_TEST_UNIT_EVENT', function() called = true end)
    
    Stub.FireEvent('KNUCAST_TEST_UNIT_EVENT', 'target')
    AssertEq(called, false, 'RegisterUnitEvent("player") ignores "target" event')

    Stub.FireEvent('KNUCAST_TEST_UNIT_EVENT', 'player')
    AssertEq(called, true, 'RegisterUnitEvent("player") triggers on "player" event')
end




-- 15. Counter drift
do
    ResetTestEnvironment('WARRIOR')
    ns.db.sound = true
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 72 } -- Shield Bash
    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 6552 } -- Pummel
    ns.Buttons:Discover()

    Stub.units.target = { canAttack = true, casting = { name = 'Shadow Bolt', notInterruptible = false } }
    ns.Engine:UpdateAll()
    AssertEq(#Stub.soundsPlayed, 1, 'Sound played on cast with 2 buttons')

    -- Remove btn1
    ns.Buttons.known[btn1] = nil
    ns.Engine:UpdateButton(btn1)
    AssertEq(ns.Engine.activeKindCounts.interrupt, 1, 'Removal immediately releases one interrupt contribution')
    AssertEq(ns.Engine.buttonActiveKinds[btn1], nil, 'Removal immediately clears the button contribution')

    -- Cast stops -> btn2 clears its contribution, but if btn1 didn't, count would be 1
    Stub.units.target.casting = nil
    ns.Engine:UpdateButton(btn2)
    AssertEq(ns.Engine.activeKindCounts.interrupt, 0, 'Incremental cast stop clears the remaining contribution')
    AssertEq(#Stub.soundsPlayed, 1, 'No new sound when cast stops')

    -- Cast starts -> should play sound again (transition from 0 to 1 on btn2)
    Stub.units.target.casting = { name = 'Shadow Bolt', notInterruptible = false }
    ns.Engine:UpdateButton(btn2)
    AssertEq(ns.Engine.activeKindCounts.interrupt, 1, 'Incremental cast start restores only the remaining button')
    AssertEq(#Stub.soundsPlayed, 2, 'Sound plays again on second cast because removed button released its contribution')
end

-- 16. Aura stub honours unit AND filter
do
    WithTestRule(TEST_JUDGEMENT_RULE, function()
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 20271 } -- Judgement (requires player HELPFUL)
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.player = {}
    Stub.lastAuraUnit = nil
    Stub.lastAuraFilter = nil
    ns.Engine:UpdateAll()
    AssertEq(Stub.lastAuraUnit, 'player', 'Judgement checked player auras')
    AssertEq(Stub.lastAuraFilter, 'HELPFUL', 'Judgement used HELPFUL filter')
    end)

    WithTestRule(TEST_CONFLAGRATE_RULE, function()
    ResetTestEnvironment('WARLOCK')
    local btn2 = CreateFrame('CheckButton', 'ActionButton1')
    btn2.action = 1
    Stub.actions[1] = { type = 'spell', id = 17962 } -- Conflagrate (requires target HARMFUL|PLAYER)
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.target = {}
    Stub.lastAuraUnit = nil
    Stub.lastAuraFilter = nil
    ns.Engine:UpdateAll()
    AssertEq(Stub.lastAuraUnit, 'target', 'Conflagrate checked target auras')
    AssertEq(Stub.lastAuraFilter, 'HARMFUL|PLAYER', 'Conflagrate used HARMFUL|PLAYER filter')
    end)
end

-- 17. Partial names
do
    WithTestRule(TEST_CONFLAGRATE_RULE, function()
    ResetTestEnvironment('WARLOCK')
    Stub.spells[348] = nil
    Stub.spells[172] = nil
    ns.Data:BuildIndex()
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 17962 } -- Conflagrate (requires 348 Immolate)
    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 172 } -- Corruption (debuff 172)
    
    Stub.spells[348] = nil -- Immolate not loaded
    Stub.spells[172] = nil -- Corruption not loaded

    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.target = {}
    ns.Engine:UpdateAll()
    
    -- Absence of auras should give no mark because names are incomplete
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Conflagrate has no mark when Immolate name is unresolved')
    AssertEq(ns.Buttons:GetVisual(btn2), 'none', 'Corruption has no mark when its debuff name is unresolved')
    
    -- Resolve Immolate
    Stub.spells[348] = 'Immolate'
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 348, true)
    
    -- Now Conflagrate has complete names, absence => grey
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Conflagrate turns grey when Immolate resolves and is absent')
    AssertEq(ns.Buttons:GetVisual(btn2), 'none', 'Corruption still has no mark')

    -- Resolve Corruption
    Stub.spells[172] = 'Corruption'
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 172, true)
    AssertEq(ns.Buttons:GetVisual(btn2), 'glow', 'Corruption turns glow when its name resolves and is absent')
    end)
end

-- 18. Aura at index 101
do
    WithTestRule(TEST_CONFLAGRATE_RULE, function()
    ResetTestEnvironment('WARLOCK')
    Stub.spells[348] = 'Immolate'
    ns.Data:BuildIndex()
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 17962 } -- Conflagrate
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.target = {}
    for i = 1, 100 do
        Stub.auras.target[i] = { name = 'DummyAura' }
    end
    Stub.auras.target[101] = { name = 'Immolate' }
    local rule = ns.Data.bySpellName['Conflagrate'][1]
    AssertEq(rule.namesComplete, true, 'Aura limit test has fully resolved names')
    AssertEq(rule.auraNames.Immolate, true, 'Aura limit test scans for Immolate')
    AssertEq(ns.Engine:EvalRule(rule, 1, 'target'), ns.Engine.UNKNOWN, 'Matching aura at index 101 yields UNKNOWN at the scan limit')
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Aura absence after 100 dummy auras results in UNKNOWN (no mark), not absent')
    end)
    -- Shipped data: Conflagrate without Immolate is not marked
    ResetTestEnvironment('WARLOCK')
    Stub.spells[348] = 'Immolate'
    ns.Data:BuildIndex()
    local btnC = CreateFrame('CheckButton', 'ActionButton1')
    btnC.action = 1
    Stub.actions[1] = { type = 'spell', id = 17962 }
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.target = {}
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btnC), 'none', 'Conflagrate without Immolate has no mark (shipped data)')
end

-- 19. Combat transitions refresh marks
do
    ResetTestEnvironment('ROGUE')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 6770 } -- Sap (outOfCombat)
    ns.Buttons:Discover()
    
    Stub.units.target = { canAttack = true, affectingCombat = false, creatureTypeID = 7 }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Sap glows on humanoid out of combat')
    
    Stub.units.target.affectingCombat = true
    Stub.FireEvent('PLAYER_REGEN_DISABLED')
    AssertEq(ns.Buttons:GetVisual(btn1), 'grey', 'Sap greys out on combat transition without target events')
    
    Stub.units.target.affectingCombat = false
    Stub.FireEvent('PLAYER_REGEN_ENABLED')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Sap glows again on combat end')
end

-- 20. Native RegisterUnitEvent failure fallback
do
    ResetTestEnvironment('PALADIN')
    local called = false
    local frame = ns.unitFrames['player']
    local oldRUE = frame.RegisterUnitEvent
    frame.RegisterUnitEvent = nil
    ns:RegisterUnitEvent('player', 'KNUCAST_FALLBACK_TEST', function() called = true end)
    frame.RegisterUnitEvent = oldRUE
    
    Stub.FireEvent('KNUCAST_FALLBACK_TEST', 'target')
    AssertEq(called, false, 'Fallback ignores wrong unit')

    Stub.FireEvent('KNUCAST_FALLBACK_TEST', 'player')
    AssertEq(called, true, 'Fallback triggers on correct unit')
    
    called = false
    local secretUnit = Stub.MarkSecret('player')
    Stub.FireEvent('KNUCAST_FALLBACK_TEST', secretUnit)
    AssertEq(called, false, 'Fallback safely ignores secret unit token without error')
end

-- 21. UNIT_AURA with secret payload
do
    ResetTestEnvironment('PALADIN')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 24275 } -- Hammer of Wrath (just any spell to cause an UpdateAll)
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 7 }
    Stub.usableActions[1] = true
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Hammer of Wrath glows')
    
    local secretPayload = Stub.MarkSecret('isFullUpdate')
    local ok = pcall(Stub.FireEvent, 'UNIT_AURA', 'target', secretPayload)
    AssertEq(ok, true, 'UNIT_AURA with secret payload did not error (handler ignored payload)')
end

-- 22. Secret UnitPowerMax / missing APIs
do
    ResetTestEnvironment('PRIEST')
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 8129 } -- Mana Burn (requires mana)
    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 453 } -- Mind Soothe (requires outOfCombat)
    ns.Buttons:Discover()

    Stub.units.target = { canAttack = true, powerType = 0, powerMax = Stub.MarkSecret(100), creatureTypeID = Stub.MarkSecret(7), affectingCombat = false }
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Mana Burn has no mark when UnitPowerMax is secret')

    local oldUnitAffectingCombat = UnitAffectingCombat
    _G.UnitAffectingCombat = nil
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn2), 'none', 'Mind Soothe has no mark when UnitAffectingCombat is missing')
    _G.UnitAffectingCombat = oldUnitAffectingCombat
end


-- 23. A successful load after exhaustion restores aura names and button state.
do
    ResetTestEnvironment('WARLOCK')
    Stub.spells[1225228] = nil -- Bane of Havoc shares the Bane of Agony rule.
    ns.Data:BuildIndex()
    local btn = CreateFrame('CheckButton', 'ActionButton1')
    btn.action = 1
    Stub.actions[1] = { type = 'spell', id = 980 }
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true }
    Stub.auras.target = { { name = 'Bane of Havoc' } }
    for i = 1, ns.Data.MAX_SPELL_REQUESTS do
        Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 1225228, false)
        if i < ns.Data.MAX_SPELL_REQUESTS then ns.Data:BuildIndex() end
    end
    AssertEq(ns.Data:IsSpellMissing(1225228), true, 'Bane of Havoc loads are exhausted')
    AssertEq(ns.Data.pendingRuleSpells[1225228], nil, 'Exhausted ID is no longer pending')
    AssertEq(ns.Buttons:GetVisual(btn), 'glow', 'Missing aura ID initially permits the debuff glow')

    Stub.spells[1225228] = 'Bane of Havoc'
    Stub.FireEvent('SPELL_DATA_LOAD_RESULT', 1225228, true)
    AssertEq(ns.Data:IsSpellMissing(1225228), false, 'Late successful load clears missing classification')
    AssertEq(ns.Data.failedSpells[1225228], nil, 'Late successful load clears failure bookkeeping')
    local rule = ns.Data.bySpellName['Bane of Agony'][1]
    AssertEq(rule.debuffNames['Bane of Havoc'], true, 'Late successful load rebuilds affected aura names')
    AssertEq(ns.Engine:EvalRule(rule, 1, 'target'), ns.Engine.UNKNOWN, 'Existing late-loaded aura yields UNKNOWN')
    AssertEq(ns.Buttons:GetVisual(btn), 'none', 'Late successful load refreshes the existing button')
end


-- On ElvUI the grey covered only the icon's top-left corner, so a greyed
-- Exorcism still looked usable against an Elemental (type 4).
do
    ResetTestEnvironment('PALADIN')
    local btn = CreateFrame('CheckButton', 'ElvUI_Bar1Button6')
    btn._state_type = 'action'
    btn._state_action = 6
    btn.icon = btn:CreateTexture(nil, 'ARTWORK')
    Stub.actions[6] = { type = 'spell', id = 879 } -- Exorcism
    ns.Buttons:Discover()
    Stub.units.target = { canAttack = true, creatureTypeID = 4 } -- Elemental
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn), 'grey', 'Exorcism is grey against an Elemental (type 4)')
    local ov = ns.Buttons.overlays[btn]
    AssertEq(ov.grey._allPoints, ov.frame, 'Grey covers the whole holder, not the bar addon icon')
    AssertEq(ov.fill._allPoints, ov.frame, 'Glow fill covers the whole holder, not the bar addon icon')
    AssertEq(ov.frame._allPoints, btn, 'Holder covers the whole button')
    -- A dark veil alone reads as "out of range"; grey adds a red X.
    AssertEq(ov.cross:IsShown(), true, 'Grey shows the red X')
    AssertEq(#ov.cross.lines, 2, 'The X has two lines')
    AssertEq(ov.cross.lines[1]._start[1], 'TOPLEFT', 'First line starts at the top-left corner')
    AssertEq(ov.cross.lines[1]._end[1], 'BOTTOMRIGHT', 'First line ends at the bottom-right corner')
    AssertEq(ov.cross.lines[2]._start[1], 'TOPRIGHT', 'Second line starts at the top-right corner')
    AssertEq(ov.cross.lines[2]._end[1], 'BOTTOMLEFT', 'Second line ends at the bottom-left corner')
    AssertEq(ov.cross.lines[1]._start[2], ov.cross, 'Line anchors to the overlay, not the bar addon icon')

    Stub.chatMessages = {}
    ns.KL:Dispatch('cast debug')
    local out = table.concat(Stub.chatMessages, ' | ')
    local exoLine = out:match('Rule 879:[^|]*') or ''
    Assert(exoLine:find('applies: no', 1, true) ~= nil and exoLine:find('mark: greyed', 1, true) ~= nil,
        'debug shows the rule verdict and the mark on its button')

    Stub.units.target = { canAttack = true, creatureTypeID = 6 } -- Undead
    ns.Engine:UpdateAll()
    Stub.chatMessages = {}
    ns.KL:Dispatch('cast debug')
    out = table.concat(Stub.chatMessages, ' | ')
    exoLine = out:match('Rule 879:[^|]*') or ''
    Assert(exoLine:find('applies: yes', 1, true) ~= nil and exoLine:find('mark: glowing', 1, true) ~= nil,
        'debug shows yes and glow against an Undead')
    AssertEq(ov.cross:IsShown(), false, 'Glow hides the red X')
    Stub.units.target = nil
    ns.Engine:UpdateAll()
    AssertEq(ov.cross:IsShown(), false, 'No target hides the red X')
end

print(string.format('%d passed, %d failed (0 failures required)', passed, failed))
if failed > 0 then
    os.exit(1)
end
