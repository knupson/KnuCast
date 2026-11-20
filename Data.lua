local _, ns = ...

local Data = {}
ns.Data = Data

-- Classic creature type IDs:
-- 1 Beast, 2 Dragonkin, 3 Demon, 4 Elemental, 5 Giant, 6 Undead,
-- 7 Humanoid, 8 Critter, 9 Mechanical, 10 Not specified, 11 Totem.
Data.CREATURE_TYPES = {
    BEAST = 1,
    DRAGONKIN = 2,
    DEMON = 3,
    ELEMENTAL = 4,
    GIANT = 5,
    UNDEAD = 6,
    HUMANOID = 7,
    CRITTER = 8,
    MECHANICAL = 9,
    NOT_SPECIFIED = 10,
    TOTEM = 11,
}

Data.RULES = {
    -- Creature type restrictions (types)
    { id = 879, class = 'PALADIN', kind = 'types', types = { 6, 3 }, source = 'https://www.wowhead.com/classic/spell=879' },
    { id = 2812, class = 'PALADIN', kind = 'types', types = { 6, 3 }, source = 'https://www.wowhead.com/classic/spell=2812' },
    { id = 2878, class = 'PALADIN', kind = 'types', types = { 6 }, source = 'https://www.wowhead.com/classic/spell=2878' },
    { id = 9484, class = 'PRIEST', kind = 'types', types = { 6 }, source = 'https://www.wowhead.com/classic/spell=9484' },
    { id = 453, class = 'PRIEST', kind = 'types', types = { 7 }, source = 'https://www.wowhead.com/classic/spell=453' },
    { id = 605, class = 'PRIEST', kind = 'types', types = { 7 }, source = 'https://www.wowhead.com/classic/spell=605' },
    { id = 710, class = 'WARLOCK', kind = 'types', types = { 3, 4 }, source = 'https://www.wowhead.com/classic/spell=710' },
    { id = 1098, class = 'WARLOCK', kind = 'types', types = { 3 }, source = 'https://www.wowhead.com/classic/spell=1098' },
    { id = 2637, class = 'DRUID', kind = 'types', types = { 1, 2 }, source = 'https://www.wowhead.com/classic/spell=2637' },
    { id = 2908, class = 'DRUID', kind = 'types', types = { 1 }, source = 'https://www.wowhead.com/classic/spell=2908' },
    { id = 1513, class = 'HUNTER', kind = 'types', types = { 1 }, source = 'https://www.wowhead.com/classic/spell=1513' },
    { id = 1515, class = 'HUNTER', kind = 'types', types = { 1 }, source = 'https://www.wowhead.com/classic/spell=1515' },
    { id = 1462, class = 'HUNTER', kind = 'types', types = { 1 }, source = 'https://www.wowhead.com/classic/spell=1462' },
    { id = 118, class = 'MAGE', kind = 'types', types = { 1, 7, 8 }, source = 'https://www.wowhead.com/classic/spell=118' },
    { id = 6770, class = 'ROGUE', kind = 'types', types = { 7 }, source = 'https://www.wowhead.com/classic/spell=6770' },

    -- Execute range spells (execute)
    { id = 24275, class = 'PALADIN', kind = 'execute', source = 'https://www.wowhead.com/classic/spell=24275' },
    { id = 5308, class = 'WARRIOR', kind = 'execute', source = 'https://www.wowhead.com/classic/spell=5308' },

    -- Interrupts (interrupt)
    { id = 72, class = 'WARRIOR', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=72' },
    { id = 6552, class = 'WARRIOR', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=6552' },
    { id = 1766, class = 'ROGUE', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=1766' },
    { id = 2139, class = 'MAGE', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=2139' },
    { id = 8042, class = 'SHAMAN', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=8042' },
    { id = 15487, class = 'PRIEST', kind = 'interrupt', source = 'https://www.wowhead.com/classic/spell=15487' },

    -- Player debuffs that should be kept on the target (debuff)
    { id = 589, class = 'PRIEST', kind = 'debuff', debuff = { 589 }, source = 'https://www.wowhead.com/classic/spell=589' },
    { id = 172, class = 'WARLOCK', kind = 'debuff', debuff = { 172 }, source = 'https://www.wowhead.com/classic/spell=172' },
    { id = 348, class = 'WARLOCK', kind = 'debuff', debuff = { 348 }, source = 'https://www.wowhead.com/classic/spell=348' },
    { id = 980, class = 'WARLOCK', kind = 'debuff', debuff = { 980, 1490, 17937, 704, 702 }, source = 'https://www.wowhead.com/classic/spell=980' },
    { id = 8921, class = 'DRUID', kind = 'debuff', debuff = { 8921 }, source = 'https://www.wowhead.com/classic/spell=8921' },
    { id = 770, class = 'DRUID', kind = 'debuff', debuff = { 770 }, source = 'https://www.wowhead.com/classic/spell=770' },
    { id = 5570, class = 'DRUID', kind = 'debuff', debuff = { 5570 }, source = 'https://www.wowhead.com/classic/spell=5570' },
    { id = 1130, class = 'HUNTER', kind = 'debuff', debuff = { 1130 }, source = 'https://www.wowhead.com/classic/spell=1130' },
    { id = 1978, class = 'HUNTER', kind = 'debuff', debuff = { 1978 }, source = 'https://www.wowhead.com/classic/spell=1978' },
    { id = 772, class = 'WARRIOR', kind = 'debuff', debuff = { 772 }, source = 'https://www.wowhead.com/classic/spell=772' },
    
    -- New rules from condiciones-2
    { id = 20271, class = 'PALADIN', kind = 'requires', auraUnit = 'player', aura = { 21084, 21082, 20375, 20164, 20165, 20166 }, source = 'https://www.wowhead.com/classic/spell=20271' },
    { id = 17962, class = 'WARLOCK', kind = 'requires', auraUnit = 'target', aura = { 348 }, source = 'https://www.wowhead.com/classic/spell=17962' },
    
    { id = 8129, class = 'PRIEST', kind = 'mana', source = 'https://www.wowhead.com/classic/spell=8129' },
    { id = 5138, class = 'WARLOCK', kind = 'mana', source = 'https://www.wowhead.com/classic/spell=5138' },
    { id = 3034, class = 'HUNTER', kind = 'mana', source = 'https://www.wowhead.com/classic/spell=3034' },

    { id = 6770, class = 'ROGUE', kind = 'outOfCombat', source = 'https://www.wowhead.com/classic/spell=6770' },
    { id = 453, class = 'PRIEST', kind = 'outOfCombat', source = 'https://www.wowhead.com/classic/spell=453' },
    { id = 2908, class = 'DRUID', kind = 'outOfCombat', source = 'https://www.wowhead.com/classic/spell=2908' },

    { id = 7386, class = 'WARRIOR', kind = 'debuff', debuff = { 7386 }, source = 'https://www.wowhead.com/classic/spell=7386' },
    { id = 1160, class = 'WARRIOR', kind = 'debuff', debuff = { 1160 }, source = 'https://www.wowhead.com/classic/spell=1160' },
    { id = 6343, class = 'WARRIOR', kind = 'debuff', debuff = { 6343 }, source = 'https://www.wowhead.com/classic/spell=6343' },
    { id = 99, class = 'DRUID', kind = 'debuff', debuff = { 99 }, source = 'https://www.wowhead.com/classic/spell=99' },
    { id = 16857, class = 'DRUID', kind = 'debuff', debuff = { 16857 }, source = 'https://www.wowhead.com/classic/spell=16857' },
    { id = 15286, class = 'PRIEST', kind = 'debuff', debuff = { 15286 }, source = 'https://www.wowhead.com/classic/spell=15286' },
    { id = 18879, class = 'WARLOCK', kind = 'debuff', debuff = { 18879 }, source = 'https://www.wowhead.com/classic/spell=18879' },
    { id = 1490, class = 'WARLOCK', kind = 'debuff', debuff = { 980, 1490, 17937, 704, 702 }, source = 'https://www.wowhead.com/classic/spell=1490' },
    { id = 17937, class = 'WARLOCK', kind = 'debuff', debuff = { 980, 1490, 17937, 704, 702 }, source = 'https://www.wowhead.com/classic/spell=17937' },
    { id = 704, class = 'WARLOCK', kind = 'debuff', debuff = { 980, 1490, 17937, 704, 702 }, source = 'https://www.wowhead.com/classic/spell=704' },
    { id = 702, class = 'WARLOCK', kind = 'debuff', debuff = { 980, 1490, 17937, 704, 702 }, source = 'https://www.wowhead.com/classic/spell=702' },
}

Data.MAX_SPELL_REQUESTS = 2
Data.bySpellName = {}
Data.pendingRuleSpells = {}
Data.hasPendingSpells = false
Data.pendingActionSpells = {}
Data.hasPendingActionSpells = false
Data.inFlightSpells = {}
Data.spellRequestCount = {}
Data.failedSpells = {}

function Data.GetSpellName(spellID)
    if type(spellID) ~= 'number' then
        return nil
    end
    if C_Spell and type(C_Spell.GetSpellName) == 'function' then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and ns.Secret.Accessible(name) and type(name) == 'string' and name ~= '' then
            return name
        end
    end
    if type(GetSpellInfo) == 'function' then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and ns.Secret.Accessible(name) and type(name) == 'string' and name ~= '' then
            return name
        end
    end
    return nil
end

function Data.GetPlayerClass()
    if type(UnitClass) ~= 'function' then
        return nil
    end
    local ok, _, classToken = pcall(UnitClass, 'player')
    if not ok or not ns.Secret.Accessible(classToken) or type(classToken) ~= 'string' then
        return nil
    end
    return classToken
end

local function RequestSpellLoad(spellID)
    if type(spellID) ~= 'number' or spellID <= 0 then
        return false
    end
    if Data.inFlightSpells[spellID] then
        return false
    end
    local count = Data.spellRequestCount[spellID] or 0
    if count >= Data.MAX_SPELL_REQUESTS then
        return false
    end
    Data.spellRequestCount[spellID] = count + 1
    Data.inFlightSpells[spellID] = true
    if C_Spell and type(C_Spell.RequestLoadSpellData) == 'function' then
        pcall(C_Spell.RequestLoadSpellData, spellID)
    end
    return true
end
Data.RequestSpellLoad = RequestSpellLoad

function Data:CanRetrySpell(spellID)
    if type(spellID) ~= 'number' or spellID <= 0 then
        return false
    end
    if self.inFlightSpells[spellID] then
        return true
    end
    return (self.spellRequestCount[spellID] or 0) < self.MAX_SPELL_REQUESTS
end

function Data:TrackActionSpell(spellID)
    if type(spellID) ~= 'number' or spellID <= 0 then
        return false
    end
    if not self:CanRetrySpell(spellID) then
        if self.pendingActionSpells[spellID] then
            self.pendingActionSpells[spellID] = nil
            self.hasPendingActionSpells = next(self.pendingActionSpells) ~= nil
        end
        return false
    end
    self.pendingActionSpells[spellID] = true
    self.hasPendingActionSpells = true
    RequestSpellLoad(spellID)
    return true
end

function Data:ResolveActionSpell(spellID)
    if type(spellID) ~= 'number' then
        return
    end
    self.inFlightSpells[spellID] = nil
    self.failedSpells[spellID] = nil
    if self.pendingActionSpells[spellID] then
        self.pendingActionSpells[spellID] = nil
        self.hasPendingActionSpells = next(self.pendingActionSpells) ~= nil
    end
end

function Data:MarkSpellFailed(spellID)
    if type(spellID) ~= 'number' then
        return
    end
    self.inFlightSpells[spellID] = nil
    self.failedSpells[spellID] = true
    if (self.spellRequestCount[spellID] or 0) >= self.MAX_SPELL_REQUESTS then
        if self.pendingActionSpells[spellID] then
            self.pendingActionSpells[spellID] = nil
            self.hasPendingActionSpells = next(self.pendingActionSpells) ~= nil
        end
        if self.pendingRuleSpells[spellID] then
            self.pendingRuleSpells[spellID] = nil
            self.hasPendingSpells = next(self.pendingRuleSpells) ~= nil
        end
    end
end

function Data:ResetPendingActionSpells()
    self.pendingActionSpells = {}
    self.hasPendingActionSpells = false
    self.pendingRuleSpells = {}
    self.inFlightSpells = {}
    self.spellRequestCount = {}
    self.failedSpells = {}
end

function Data:BuildIndex()
    self.bySpellName = {}
    self.pendingRuleSpells = {}
    self.hasPendingSpells = false
    local playerClass = Data.GetPlayerClass()
    if not playerClass then
        return self.bySpellName
    end

    for i = 1, #self.RULES do
        local rule = self.RULES[i]
        if rule.class == playerClass then
            if rule.types then
                local set = {}
                for j = 1, #rule.types do
                    set[rule.types[j]] = true
                end
                rule.typesSet = set
            end

            local spellName = Data.GetSpellName(rule.id)
            if not spellName then
                if self:CanRetrySpell(rule.id) then
                    self.pendingRuleSpells[rule.id] = true
                    self.hasPendingSpells = true
                    RequestSpellLoad(rule.id)
                end
            else
                self.inFlightSpells[rule.id] = nil
                self.failedSpells[rule.id] = nil
                if rule.debuff then
                    local debuffNames = {}
                    local complete = true
                    for j = 1, #rule.debuff do
                        local dID = rule.debuff[j]
                        local dName = Data.GetSpellName(dID)
                        if dName then
                            self.inFlightSpells[dID] = nil
                            self.failedSpells[dID] = nil
                            debuffNames[dName] = true
                        else
                            complete = false
                            if self:CanRetrySpell(dID) then
                                self.pendingRuleSpells[dID] = true
                                self.hasPendingSpells = true
                                RequestSpellLoad(dID)
                            end
                        end
                    end
                    rule.debuffNames = debuffNames
                    rule.namesComplete = complete
                end

                if rule.aura then
                    local auraNames = {}
                    local complete = true
                    for j = 1, #rule.aura do
                        local aID = rule.aura[j]
                        local aName = Data.GetSpellName(aID)
                        if aName then
                            self.inFlightSpells[aID] = nil
                            self.failedSpells[aID] = nil
                            auraNames[aName] = true
                        else
                            complete = false
                            if self:CanRetrySpell(aID) then
                                self.pendingRuleSpells[aID] = true
                                self.hasPendingSpells = true
                                RequestSpellLoad(aID)
                            end
                        end
                    end
                    rule.auraNames = auraNames
                    if rule.debuff == nil then
                        rule.namesComplete = complete
                    else
                        rule.namesComplete = rule.namesComplete and complete
                    end
                end

                local list = self.bySpellName[spellName]
                if not list then
                    list = {}
                    self.bySpellName[spellName] = list
                end
                list[#list + 1] = rule
            end
        end
    end

    return self.bySpellName
end

function Data:GetRulesForSpell(spellName)
    if type(spellName) ~= 'string' or spellName == '' then
        return nil
    end
    if not next(self.bySpellName) then
        self:BuildIndex()
    end
    return self.bySpellName[spellName]
end
