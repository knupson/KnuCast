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

-- Also syntax-check the test files themselves.
do
    local c1, e1 = loadfile('tests/wow_stub.lua')
    Assert(c1 ~= nil, 'Syntax check tests/wow_stub.lua: ' .. tostring(e1))
    local c2, e2 = loadfile('tests/run.lua')
    Assert(c2 ~= nil, 'Syntax check tests/run.lua: ' .. tostring(e2))
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

    -- Unknown (secret cast name) + UNIT_SPELLCAST_* event fallback
    local secretCastName = Stub.MarkSecret('Heal')
    Stub.units.target.casting = { name = secretCastName }
    AssertEq(ns.Secret.IsCasting('target'), nil, 'IsCasting returns nil when cast name is secret')
    ns.Engine:ResetTargetState()
    ns.Engine:UpdateAll()
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick has no overlay when cast is secret and no event')

    Stub.FireEvent('UNIT_SPELLCAST_START', 'target')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick glows via UNIT_SPELLCAST_START fallback when cast info is secret')

    Stub.FireEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', 'target')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick clears glow on UNIT_SPELLCAST_NOT_INTERRUPTIBLE')

    Stub.FireEvent('UNIT_SPELLCAST_INTERRUPTIBLE', 'target')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Kick restores glow on UNIT_SPELLCAST_INTERRUPTIBLE')

    Stub.FireEvent('UNIT_SPELLCAST_STOP', 'target')
    AssertEq(ns.Buttons:GetVisual(btn1), 'none', 'Kick clears glow on UNIT_SPELLCAST_STOP')
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

    -- Debug and status output
    local beforeMsgs = #Stub.chatMessages
    ns.KL:Dispatch('cast debug')
    ns.KL:Dispatch('cast')
    Assert(#Stub.chatMessages >= beforeMsgs + 3, 'debug and status commands print chat lines')
end

-- 10. Sound once per transition
do
    ResetTestEnvironment('PALADIN')
    ns.db.sound = true
    -- Place two Paladin creature-type spells (Exorcism + Holy Wrath) on two buttons
    local btn1 = CreateFrame('CheckButton', 'ActionButton1')
    btn1.action = 1
    Stub.actions[1] = { type = 'spell', id = 879 } -- Exorcism
    local btn2 = CreateFrame('CheckButton', 'ActionButton2')
    btn2.action = 2
    Stub.actions[2] = { type = 'spell', id = 2812 } -- Holy Wrath
    ns.Buttons:Discover()

    -- Transition to Undead target: both buttons glow, but only ONE sound must play
    Stub.units.target = { canAttack = true, creatureTypeID = 6 }
    Stub.FireEvent('PLAYER_TARGET_CHANGED')
    AssertEq(ns.Buttons:GetVisual(btn1), 'glow', 'Button 1 glows on Undead')
    AssertEq(ns.Buttons:GetVisual(btn2), 'glow', 'Button 2 glows on Undead')
    AssertEq(#Stub.soundsPlayed, 1, 'Exactly one sound played when two buttons transition to glow')

    -- Repeated updates without state change must NOT play another sound
    Stub.FireEvent('UNIT_AURA', 'target')
    Stub.FireEvent('ACTIONBAR_UPDATE_USABLE')
    AssertEq(#Stub.soundsPlayed, 1, 'No additional sound when state has not transitioned')

    -- Target changes to Beast (no glow), then back to Undead (glow again) -> second sound
    Stub.units.target = { canAttack = true, creatureTypeID = 1 }
    Stub.FireEvent('PLAYER_TARGET_CHANGED')
    AssertEq(#Stub.soundsPlayed, 1, 'No sound when transitioning to grey')

    Stub.units.target = { canAttack = true, creatureTypeID = 6 }
    Stub.FireEvent('PLAYER_TARGET_CHANGED')
    AssertEq(#Stub.soundsPlayed, 2, 'Second sound played on new transition to glow')
end

print(string.format('%d passed, %d failed (0 failures required)', passed, failed))
if failed > 0 then
    os.exit(1)
end
