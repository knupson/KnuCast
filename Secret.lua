local _, ns = ...

local Secret = {}
ns.Secret = Secret

-- Guard against Blizzard "secret values". Never boolean-test, compare,
-- concatenate, or do arithmetic on a potentially secret value before checking
-- Accessible(v).
function Secret.Accessible(v)
    if type(canaccessvalue) == 'function' then
        local ok, res = pcall(canaccessvalue, v)
        if not ok or not res then
            return false
        end
    end
    if type(issecretvalue) == 'function' then
        local ok, res = pcall(issecretvalue, v)
        if not ok or res then
            return false
        end
    end
    return true
end

function Secret.CanAttack(unit)
    unit = unit or 'target'
    if type(UnitExists) == 'function' then
        local ok, exists = pcall(UnitExists, unit)
        if not ok or not Secret.Accessible(exists) or exists ~= true then
            return false
        end
    end
    if type(UnitCanAttack) ~= 'function' then
        return false
    end
    local ok, canAttack = pcall(UnitCanAttack, 'player', unit)
    if not ok or not Secret.Accessible(canAttack) then
        return false
    end
    return canAttack == true
end

-- Returns the numeric creatureTypeID (2nd return of UnitCreatureType) or nil if
-- absent/secret.
function Secret.CreatureTypeID(unit)
    unit = unit or 'target'
    if type(UnitCreatureType) ~= 'function' then
        return nil
    end
    local ok, _, typeID = pcall(UnitCreatureType, unit)
    if not ok or not Secret.Accessible(typeID) then
        return nil
    end
    if type(typeID) ~= 'number' then
        return nil
    end
    return typeID
end

local function ReadCastInfo(fn, unit)
    if type(fn) ~= 'function' then
        return false, false, nil, nil
    end
    local ok, name, _, _, _, _, _, r7, r8 = pcall(fn, unit)
    if not ok then
        return true, true, nil, nil
    end

    -- UnitCastingInfo returns notInterruptible at #8; UnitChannelInfo at #7 (or #8).
    local notInterruptible = nil
    if Secret.Accessible(r8) and type(r8) == 'boolean' then
        notInterruptible = r8
    elseif Secret.Accessible(r7) and type(r7) == 'boolean' then
        notInterruptible = r7
    end

    if not Secret.Accessible(name) then
        if notInterruptible == true then
            return true, true, false, true
        end
        return true, true, nil, notInterruptible
    end
    if name == nil or name == false then
        return true, false, false, nil
    end
    if notInterruptible == true then
        return true, true, false, true
    end
    return true, true, true, notInterruptible
end

-- Returns true (interruptible cast/channel active), false (not casting or
-- uninterruptible), or nil (secret/unknown). Second return is readable
-- notInterruptible boolean when available, or nil.
function Secret.IsCasting(unit)
    unit = unit or 'target'
    local hasCastFn, handledCast, castState, castNotInt = ReadCastInfo(UnitCastingInfo, unit)
    if handledCast then
        return castState, castNotInt
    end
    local hasChanFn, handledChan, chanState, chanNotInt = ReadCastInfo(UnitChannelInfo, unit)
    if handledChan then
        return chanState, chanNotInt
    end
    if not hasCastFn and not hasChanFn then
        return nil, nil
    end
    return false, nil
end

local function NormalizeSpellNames(spellNames)
    local wanted = {}
    local count = 0
    if type(spellNames) == 'string' and spellNames ~= '' then
        wanted[spellNames] = true
        count = 1
    elseif type(spellNames) == 'table' then
        for k, v in pairs(spellNames) do
            if type(k) == 'number' and type(v) == 'string' and v ~= '' then
                wanted[v] = true
                count = count + 1
            elseif type(k) == 'string' and k ~= '' and v then
                wanted[k] = true
                count = count + 1
            end
        end
    end
    return wanted, count
end

-- Iterates auras via C_UnitAuras.GetAuraDataByIndex (not GetAuraDataBySpellName).
-- Returns true (present), false (missing, all auras read in the clear), or nil (unknown/secret).
function Secret.OwnAuraState(unit, spellNames, filter)
    unit = unit or 'target'
    local wanted, count = NormalizeSpellNames(spellNames)
    if count == 0 then
        return nil
    end

    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == 'function' then
        for i = 1, 100 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
            if not ok or not Secret.Accessible(aura) then
                return nil
            end
            if aura == nil then
                return false
            end
            if type(aura) ~= 'table' then
                return nil
            end
            local name = aura.name
            if not Secret.Accessible(name) or type(name) ~= 'string' then
                return nil
            end
            if wanted[name] then
                return true
            end
        end
        return nil
    end

    if type(UnitAura) == 'function' then
        for i = 1, 100 do
            local ok, name = pcall(UnitAura, unit, i, filter)
            if not ok or not Secret.Accessible(name) then
                return nil
            end
            if name == nil then
                return false
            end
            if type(name) ~= 'string' then
                return nil
            end
            if wanted[name] then
                return true
            end
        end
        return nil
    end

    return nil
end

function Secret.PlayerDebuffState(unit, spellNames)
    return Secret.OwnAuraState(unit, spellNames, 'HARMFUL|PLAYER')
end

-- Uses C_ActionBar.IsUsableAction with fallback to global IsUsableAction.
-- Returns true, false, or nil (unknown/secret).
function Secret.IsActionUsable(slot)
    if type(slot) ~= 'number' or slot <= 0 then
        return nil
    end
    local fn = (C_ActionBar and type(C_ActionBar.IsUsableAction) == 'function' and C_ActionBar.IsUsableAction)
        or (type(IsUsableAction) == 'function' and IsUsableAction)
    if not fn then
        return nil
    end
    local ok, usable = pcall(fn, slot)
    if not ok or not Secret.Accessible(usable) then
        return nil
    end
    if type(usable) ~= 'boolean' then
        return nil
    end
    return usable
end
