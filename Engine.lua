local _, ns = ...

local Engine = {
    YES = 'YES',
    NO = 'NO',
    UNKNOWN = 'UNKNOWN',
    testMode = false,
    eventCasting = nil,
    eventNotInterruptible = false,
    prevActiveKinds = {},
    buttonActiveKinds = {},
    activeKindCounts = {},
}
ns.Engine = Engine

local SOUND_ELIGIBLE_KINDS = {
    interrupt = true,
    execute = true,
}

function Engine:ResetTargetState()
    self.eventCasting = nil
    self.eventNotInterruptible = false
    self.prevActiveKinds = {}
    self.buttonActiveKinds = {}
    self.activeKindCounts = {}
end

function Engine:IsTargetCasting(unit)
    unit = unit or 'target'
    local direct, directNotInterruptible = ns.Secret.IsCasting(unit)
    if directNotInterruptible ~= nil then
        self.eventNotInterruptible = directNotInterruptible
    end
    if direct ~= nil then
        if direct == false then
            return false
        end
        if directNotInterruptible == nil and self.eventNotInterruptible then
            return false
        end
        return direct
    end
    if self.eventCasting == true then
        if directNotInterruptible == true then
            return false
        end
        if directNotInterruptible == nil and self.eventNotInterruptible then
            return false
        end
        return true
    end
    if self.eventCasting == false then
        return false
    end
    return nil
end

function Engine:EvalRule(rule, slot, unit)
    if type(rule) ~= 'table' then
        return self.UNKNOWN
    end
    unit = unit or 'target'
    local conditions = ns.db and ns.db.conditions
    if conditions and rule.kind and conditions[rule.kind] == false then
        return self.UNKNOWN
    end

    if rule.kind == 'types' then
        local typeID = ns.Secret.CreatureTypeID(unit)
        if typeID == nil then
            return self.UNKNOWN
        end
        if rule.typesSet then
            return rule.typesSet[typeID] and self.YES or self.NO
        end
        if type(rule.types) == 'table' then
            for i = 1, #rule.types do
                if rule.types[i] == typeID then
                    return self.YES
                end
            end
            return self.NO
        end
        return self.UNKNOWN
    elseif rule.kind == 'execute' then
        local usable = ns.Secret.IsActionUsable(slot)
        if usable == true then
            return self.YES
        end
        return self.UNKNOWN
    elseif rule.kind == 'interrupt' then
        local casting = self:IsTargetCasting(unit)
        if casting == true then
            return self.YES
        end
        return self.UNKNOWN
    elseif rule.kind == 'debuff' then
        local present = ns.Secret.OwnAuraState(unit, rule.debuffNames, 'HARMFUL|PLAYER')
        if present == true then
            return self.UNKNOWN
        elseif present == false then
            if rule.namesComplete then
                return self.YES
            else
                return self.UNKNOWN
            end
        end
        return self.UNKNOWN
    elseif rule.kind == 'requires' then
        local filter = (rule.auraUnit == 'player') and 'HELPFUL' or 'HARMFUL|PLAYER'
        local present = ns.Secret.OwnAuraState(rule.auraUnit or 'target', rule.auraNames, filter)
        if present == true then
            return self.UNKNOWN
        elseif present == false then
            if rule.namesComplete then
                return self.NO
            else
                return self.UNKNOWN
            end
        end
        return self.UNKNOWN
    elseif rule.kind == 'mana' then
        if type(UnitPowerType) ~= 'function' then return self.UNKNOWN end
        local ok, pt = pcall(UnitPowerType, unit)
        if not ok or not ns.Secret.Accessible(pt) or type(pt) ~= 'number' then return self.UNKNOWN end
        if pt ~= 0 then return self.NO end
        
        if type(UnitPowerMax) ~= 'function' then return self.UNKNOWN end
        local okMax, pm = pcall(UnitPowerMax, unit, 0)
        if not okMax or not ns.Secret.Accessible(pm) or type(pm) ~= 'number' then return self.UNKNOWN end
        if pm == 0 then return self.NO end
        
        return self.UNKNOWN
    elseif rule.kind == 'outOfCombat' then
        if type(UnitAffectingCombat) ~= 'function' then return self.UNKNOWN end
        local ok, inCombat = pcall(UnitAffectingCombat, unit)
        if not ok or not ns.Secret.Accessible(inCombat) or type(inCombat) ~= 'boolean' then return self.UNKNOWN end
        if inCombat == true then return self.NO end
        return self.UNKNOWN
    end

    return self.UNKNOWN
end

-- Precedence: any NO -> NO (grey); else any YES -> YES (glow); else UNKNOWN (none).
function Engine.CombineStates(states)
    if type(states) ~= 'table' then
        return Engine.UNKNOWN
    end
    local hasYes = false
    for i = 1, #states do
        local st = states[i]
        if st == Engine.NO then
            return Engine.NO
        elseif st == Engine.YES then
            hasYes = true
        end
    end
    if hasYes then
        return Engine.YES
    end
    return Engine.UNKNOWN
end

function Engine.StateToVisual(state)
    if state == Engine.NO then
        if ns.db and ns.db.grey == false then
            return 'none'
        end
        return 'grey'
    elseif state == Engine.YES then
        if ns.db and ns.db.glow == false then
            return 'none'
        end
        return 'glow'
    end
    return 'none'
end

function Engine:EvaluateRules(rules, slot, unit)
    if type(rules) ~= 'table' or #rules == 0 then
        return self.UNKNOWN, {}
    end
    local states = {}
    local yesKinds = {}
    for i = 1, #rules do
        local rule = rules[i]
        local st = self:EvalRule(rule, slot, unit)
        states[i] = st
        if st == self.YES and rule.kind then
            yesKinds[rule.kind] = true
        end
    end
    local combined = Engine.CombineStates(states)
    if combined ~= self.YES then
        yesKinds = {}
    end
    return combined, yesKinds
end

function Engine:PlayAlertSound()
    if not (ns.db and ns.db.sound) then
        return false
    end
    if type(PlaySound) ~= 'function' then
        return false
    end
    local kit = type(SOUNDKIT) == 'table'
        and (SOUNDKIT.RAID_WARNING or SOUNDKIT.TELL_MESSAGE or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        or nil
    if not kit then
        return false
    end
    pcall(PlaySound, kit, 'Master')
    return true
end

function Engine:EvaluateButton(btn)
    local rules, slot = ns.Buttons.GetButtonRules(btn)
    if not rules then
        if self.buttonActiveKinds[btn] then
            for kind in pairs(self.buttonActiveKinds[btn]) do
                self.activeKindCounts[kind] = (self.activeKindCounts[kind] or 1) - 1
            end
            self.buttonActiveKinds[btn] = nil
        end
        ns.Buttons:SetVisual(btn, 'none')
        return
    end

    local state, yesKinds = self:EvaluateRules(rules, slot, 'target')
    local eligibleKinds = nil
    for kind in pairs(yesKinds) do
        if SOUND_ELIGIBLE_KINDS[kind] then
            if not eligibleKinds then
                eligibleKinds = {}
            end
            eligibleKinds[kind] = true
        end
    end

    local oldKinds = self.buttonActiveKinds[btn]
    if oldKinds then
        for kind in pairs(oldKinds) do
            if not eligibleKinds or not eligibleKinds[kind] then
                self.activeKindCounts[kind] = (self.activeKindCounts[kind] or 1) - 1
            end
        end
    end
    if eligibleKinds then
        for kind in pairs(eligibleKinds) do
            if not oldKinds or not oldKinds[kind] then
                self.activeKindCounts[kind] = (self.activeKindCounts[kind] or 0) + 1
            end
        end
    end
    self.buttonActiveKinds[btn] = eligibleKinds

    local visual = Engine.StateToVisual(state)
    ns.Buttons:SetVisual(btn, visual)
end

function Engine:CheckSoundTransition()
    local transitioned = false
    local prev = self.prevActiveKinds or {}
    local active = {}
    
    for kind, count in pairs(self.activeKindCounts) do
        if count > 0 then
            active[kind] = true
            if not prev[kind] then
                transitioned = true
            end
        end
    end
    
    self.prevActiveKinds = active

    if transitioned then
        self:PlayAlertSound()
    end
end

function Engine:UpdateButton(btn)
    if not btn or not ns.Buttons.known[btn] then
        return
    end
    if not ns.Buttons.overlays[btn] and ns.Buttons.IsInCombat() then
        ns.Buttons.needsDiscovery = true
        return
    end

    if self.testMode then
        local showGlow = not (ns.db and ns.db.glow == false)
        local rules = ns.Buttons.GetButtonRules(btn)
        if rules and showGlow then
            ns.Buttons:SetVisual(btn, 'glow')
        else
            ns.Buttons:SetVisual(btn, 'none')
        end
        return
    end

    if not ns.Secret.CanAttack('target') then
        self.buttonActiveKinds[btn] = nil
        ns.Buttons:SetVisual(btn, 'none')
        self:ResetTargetState()
        return
    end

    self:EvaluateButton(btn)
    self:CheckSoundTransition()
end

function Engine:UpdateAll()
    if ns.Buttons.needsDiscovery and not ns.Buttons.IsInCombat() then
        ns.Buttons:Discover()
    end

    if self.testMode then
        local showGlow = not (ns.db and ns.db.glow == false)
        for i = 1, #ns.Buttons.list do
            local btn = ns.Buttons.list[i]
            local rules = ns.Buttons.GetButtonRules(btn)
            if rules and showGlow then
                ns.Buttons:SetVisual(btn, 'glow')
            else
                ns.Buttons:SetVisual(btn, 'none')
            end
        end
        return
    end

    if not ns.Secret.CanAttack('target') then
        ns.Buttons:ClearAll()
        self:ResetTargetState()
        return
    end

    self.buttonActiveKinds = {}
    self.activeKindCounts = {}
    for i = 1, #ns.Buttons.list do
        self:EvaluateButton(ns.Buttons.list[i])
    end

    self:CheckSoundTransition()
end

ns:RegisterEvent('PLAYER_ENTERING_WORLD', function()
    ns.Data:BuildIndex()
    ns.Buttons:Discover()
    Engine:ResetTargetState()
    Engine:UpdateAll()
end)

ns:RegisterEvent('PLAYER_REGEN_DISABLED', function()
    Engine:UpdateAll()
end)

ns:RegisterEvent('PLAYER_REGEN_ENABLED', function()
    if ns.Buttons.needsDiscovery then
        ns.Buttons:Discover()
    end
    Engine:UpdateAll()
end)

ns:RegisterEvent('SPELLS_CHANGED', function()
    ns.Data:BuildIndex()
    Engine:UpdateAll()
end)

ns:RegisterEvent('SPELL_DATA_LOAD_RESULT', function(_, spellID, success)
    if not ns.Secret.Accessible(spellID) or type(spellID) ~= 'number' then
        return
    end
    ns.Data.inFlightSpells[spellID] = nil

    local loadOk
    if not ns.Secret.Accessible(success) then
        loadOk = false
    elseif success == false then
        loadOk = false
    elseif success == true then
        loadOk = true
    else
        loadOk = ns.Data.GetSpellName(spellID) ~= nil
    end

    if not loadOk then
        ns.Data:MarkSpellFailed(spellID)
        return
    end

    local spellName = ns.Data.GetSpellName(spellID)
    if not spellName then
        ns.Data:MarkSpellFailed(spellID)
        return
    end

    local wasPendingRule = ns.Data.pendingRuleSpells[spellID] == true
    local wasPendingAction = ns.Data.pendingActionSpells[spellID] == true
    if not wasPendingRule and not wasPendingAction then
        return
    end

    if wasPendingRule then
        ns.Data:BuildIndex()
    end
    if wasPendingAction then
        ns.Data:ResolveActionSpell(spellID)
    end

    for i = 1, #ns.Buttons.list do
        local btn = ns.Buttons.list[i]
        local slot = ns.Buttons.GetSlot(btn)
        local slotSpellID = slot and ns.Buttons.GetSlotSpellID(slot)
        if slotSpellID then
            local match = (slotSpellID == spellID)
            if not match and wasPendingRule then
                local slotSpellName = ns.Data.GetSpellName(slotSpellID)
                if slotSpellName and ns.Data.bySpellName[slotSpellName] then
                    match = true
                end
            end
            if match then
                Engine:UpdateButton(btn)
            end
        end
    end
end)

ns:RegisterEvent('PLAYER_TARGET_CHANGED', function()
    Engine:ResetTargetState()
    Engine:UpdateAll()
end)

local BAR_EVENTS = {
    'ACTIONBAR_UPDATE_USABLE',
    'ACTION_USABLE_CHANGED',
    'ACTIONBAR_SLOT_CHANGED',
    'ACTIONBAR_PAGE_CHANGED',
    'UPDATE_BONUS_ACTIONBAR',
}
for i = 1, #BAR_EVENTS do
    ns:RegisterEvent(BAR_EVENTS[i], function()
        Engine:UpdateAll()
    end)
end

local UNIT_RECOMPUTE_EVENTS = {
    'UNIT_FLAGS',
    'UNIT_FACTION',
    'UNIT_HEALTH',
    'UNIT_MAXHEALTH',
    'UNIT_AURA',
    'UNIT_DISPLAYPOWER',
    'UNIT_MAXPOWER',
}
for i = 1, #UNIT_RECOMPUTE_EVENTS do
    ns:RegisterTargetEvent(UNIT_RECOMPUTE_EVENTS[i], function()
        Engine:UpdateAll()
    end)
end

ns:RegisterUnitEvent('player', 'UNIT_AURA', function()
    Engine:UpdateAll()
end)

local CAST_START_EVENTS = {
    'UNIT_SPELLCAST_START',
    'UNIT_SPELLCAST_CHANNEL_START',
}
for i = 1, #CAST_START_EVENTS do
    ns:RegisterTargetEvent(CAST_START_EVENTS[i], function()
        Engine.eventCasting = true
        Engine.eventNotInterruptible = false
        Engine:UpdateAll()
    end)
end

local CAST_STOP_EVENTS = {
    'UNIT_SPELLCAST_STOP',
    'UNIT_SPELLCAST_FAILED',
    'UNIT_SPELLCAST_INTERRUPTED',
    'UNIT_SPELLCAST_CHANNEL_STOP',
}
for i = 1, #CAST_STOP_EVENTS do
    ns:RegisterTargetEvent(CAST_STOP_EVENTS[i], function()
        Engine.eventCasting = false
        Engine.eventNotInterruptible = false
        Engine:UpdateAll()
    end)
end

ns:RegisterTargetEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', function()
    Engine.eventNotInterruptible = true
    Engine:UpdateAll()
end)

ns:RegisterTargetEvent('UNIT_SPELLCAST_INTERRUPTIBLE', function()
    Engine.eventNotInterruptible = false
    Engine:UpdateAll()
end)
