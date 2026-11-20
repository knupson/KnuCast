local Stub = {
    locale = 'enUS',
    playerClass = { 'Paladin', 'PALADIN' },
    inCombat = false,
    secrets = {},
    frames = {},
    chatMessages = {},
    soundsPlayed = {},
    units = {},
    actions = {},
    usableActions = {},
    auras = {},
}

_G.wow_stub = Stub

_G.strmatch = string.match
_G.strtrim = function(s)
    if type(s) ~= 'string' then
        return ''
    end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

_G.STANDARD_TEXT_FONT = 'Fonts\\FRIZQT__.TTF'
_G.RAID_CLASS_COLORS = {
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
}

_G.SOUNDKIT = {
    RAID_WARNING = 8959,
    TELL_MESSAGE = 3081,
    IG_MAINMENU_OPTION_CHECKBOX_ON = 856,
}

_G.SlashCmdList = _G.SlashCmdList or {}
_G.hash_SlashCmdList = _G.hash_SlashCmdList or {}
_G.ChatFrameUtil = {
    ImportAllListsToHash = function() end,
}

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, msg)
        Stub.chatMessages[#Stub.chatMessages + 1] = tostring(msg)
    end,
}

function _G.GetLocale()
    return Stub.locale
end

function _G.UnitClass(unit)
    if unit == 'player' then
        return Stub.playerClass[1], Stub.playerClass[2]
    end
    return nil, nil
end

function _G.InCombatLockdown()
    return Stub.inCombat == true
end

function _G.hooksecurefunc(tbl, name, fn)
    if type(tbl) == 'string' then
        fn = name
        name = tbl
        tbl = _G
    end
    if type(tbl) ~= 'table' or type(fn) ~= 'function' then
        return
    end
    local orig = tbl[name]
    tbl[name] = function(...)
        if type(orig) == 'function' then
            orig(...)
        end
        fn(...)
    end
end

local SECRET_MT = {
    __index = function() error('Attempt to index secret value') end,
    __newindex = function() error('Attempt to modify secret value') end,
    __add = function() error('Attempt to do arithmetic on secret value') end,
    __sub = function() error('Attempt to do arithmetic on secret value') end,
    __mul = function() error('Attempt to do arithmetic on secret value') end,
    __div = function() error('Attempt to do arithmetic on secret value') end,
    __mod = function() error('Attempt to do arithmetic on secret value') end,
    __pow = function() error('Attempt to do arithmetic on secret value') end,
    __unm = function() error('Attempt to do arithmetic on secret value') end,
    __concat = function() error('Attempt to concatenate secret value') end,
    __len = function() error('Attempt to get length of secret value') end,
    __lt = function() error('Attempt to compare secret value') end,
    __le = function() error('Attempt to compare secret value') end,
    __call = function() error('Attempt to call secret value') end,
    __tostring = function() error('Attempt to convert secret value to string') end,
}

function Stub.MarkSecret(v)
    local proxy = setmetatable({}, SECRET_MT)
    Stub.secrets[proxy] = { value = v }
    return proxy
end

function Stub.UnwrapSecret(v)
    local info = v ~= nil and Stub.secrets[v]
    if info then
        return info.value, true
    end
    return v, false
end

function Stub.ClearSecrets()
    Stub.secrets = {}
end

function _G.issecretvalue(v)
    if v == nil then
        return false
    end
    return Stub.secrets[v] ~= nil
end

function _G.canaccessvalue(v)
    return not _G.issecretvalue(v)
end

local function NewTexture(parent, name, layer)
    local tex = {
        _type = 'Texture',
        _parent = parent,
        _name = name,
        _layer = layer,
        _shown = true,
        _alpha = 1,
        _points = {},
    }
    function tex:Show() self._shown = true end
    function tex:Hide() self._shown = false end
    function tex:IsShown() return self._shown end
    function tex:SetAlpha(a) self._alpha = a end
    function tex:GetAlpha() return self._alpha end
    function tex:SetAllPoints(anchor) self._allPoints = anchor or parent end
    function tex:SetPoint(...) self._points[#self._points + 1] = { ... } end
    function tex:ClearAllPoints() self._points = {}; self._allPoints = nil end
    function tex:SetColorTexture(r, g, b, a) self._color = { r, g, b, a } end
    function tex:SetVertexColor(r, g, b, a) self._vertexColor = { r, g, b, a } end
    function tex:SetBlendMode(mode) self._blendMode = mode end
    function tex:SetWidth(w) self._width = w end
    function tex:SetHeight(h) self._height = h end
    function tex:SetSize(w, h) self._width = w; self._height = h end
    if name then
        _G[name] = tex
    end
    return tex
end

local function NewAnimationGroup(parent)
    local ag = {
        _parent = parent,
        _playing = false,
        _looping = 'NONE',
        _animations = {},
    }
    function ag:SetLooping(loopType) self._looping = loopType end
    function ag:GetLooping() return self._looping end
    function ag:Play() self._playing = true end
    function ag:Stop() self._playing = false end
    function ag:IsPlaying() return self._playing end
    function ag:CreateAnimation(animType)
        local anim = { _type = animType }
        function anim:SetFromAlpha(a) self._fromAlpha = a end
        function anim:SetToAlpha(a) self._toAlpha = a end
        function anim:SetChange(c) self._change = c end
        function anim:SetDuration(d) self._duration = d end
        function anim:SetSmoothing(s) self._smoothing = s end
        self._animations[#self._animations + 1] = anim
        return anim
    end
    return ag
end

function _G.CreateFrame(frameType, name, parent, template)
    local isProtected = (frameType == 'CheckButton')
        or (type(template) == 'string' and (template:find('Secure') ~= nil or template:find('ActionButton') ~= nil))
    if Stub.inCombat and (isProtected or (parent and parent._protected)) then
        error('Attempt to create frame on protected parent during combat lockdown')
    end

    local f = {
        _type = frameType or 'Frame',
        _name = name,
        _parent = parent,
        _template = template,
        _protected = isProtected,
        _shown = true,
        _alpha = 1,
        _level = 1,
        _events = {},
        _unitEvents = {},
        _scripts = {},
        _hooks = {},
        _attributes = {},
        _points = {},
        _children = {},
        _textures = {},
    }
    if parent and type(parent._children) == 'table' then
        parent._children[#parent._children + 1] = f
    end
    local function CheckProtected(self, op)
        if Stub.inCombat and self._protected then
            error('Attempt to call ' .. tostring(op) .. ' on protected frame during combat lockdown')
        end
    end
    function f:GetName() return self._name end
    function f:GetParent() return self._parent end
    function f:IsProtected() return self._protected == true end
    function f:SetProtected(val) self._protected = val == true end
    function f:Show() CheckProtected(self, 'Show'); self._shown = true end
    function f:Hide() CheckProtected(self, 'Hide'); self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetAlpha(a) self._alpha = a end
    function f:GetAlpha() return self._alpha end
    function f:SetFrameLevel(lvl) self._level = lvl end
    function f:GetFrameLevel() return self._level end
    function f:SetAllPoints(anchor) CheckProtected(self, 'SetAllPoints'); self._allPoints = anchor or self._parent end
    function f:SetPoint(...) CheckProtected(self, 'SetPoint'); self._points[#self._points + 1] = { ... } end
    function f:ClearAllPoints() CheckProtected(self, 'ClearAllPoints'); self._points = {}; self._allPoints = nil end
    function f:RegisterEvent(event)
        self._events[event] = true
        self._unitEvents[event] = nil
        return true
    end
    function f:RegisterUnitEvent(event, unit1, unit2)
        self._events[event] = true
        self._unitEvents[event] = { unit1, unit2 }
        return true
    end
    function f:UnregisterEvent(event)
        self._events[event] = nil
        self._unitEvents[event] = nil
    end
    function f:IsEventRegistered(event) return self._events[event] == true end
    function f:SetScript(scriptName, fn) self._scripts[scriptName] = fn end
    function f:GetScript(scriptName) return self._scripts[scriptName] end
    function f:HookScript(scriptName, fn)
        self._hooks[scriptName] = self._hooks[scriptName] or {}
        table.insert(self._hooks[scriptName], fn)
    end
    function f:GetAttribute(attr) return self._attributes[attr] end
    function f:SetAttribute(attr, val)
        CheckProtected(self, 'SetAttribute')
        self._attributes[attr] = val
    end
    function f:CreateTexture(texName, layer)
        local tex = NewTexture(self, texName, layer)
        self._textures[#self._textures + 1] = tex
        return tex
    end
    function f:CreateAnimationGroup()
        return NewAnimationGroup(self)
    end

    if name then
        _G[name] = f
    end
    Stub.frames[#Stub.frames + 1] = f
    return f
end

function Stub.FireEvent(event, ...)
    local unit = ...
    local rawUnit = Stub.UnwrapSecret(unit)
    for i = 1, #Stub.frames do
        local f = Stub.frames[i]
        if f._events[event] and type(f._scripts.OnEvent) == 'function' then
            local unitFilter = f._unitEvents and f._unitEvents[event]
            local allowed = true
            if unitFilter then
                allowed = false
                for j = 1, #unitFilter do
                    if unitFilter[j] ~= nil and unitFilter[j] == rawUnit then
                        allowed = true
                        break
                    end
                end
            end
            if allowed then
                f._scripts.OnEvent(f, event, ...)
            end
        end
    end
end
_G.FireEvent = Stub.FireEvent

Stub.DEFAULT_SPELLS = {
    [879] = 'Exorcism',
    [5614] = 'Exorcism', -- Higher rank
    [2812] = 'Holy Wrath',
    [2878] = 'Turn Undead',
    [9484] = 'Shackle Undead',
    [453] = 'Mind Soothe',
    [605] = 'Mind Control',
    [710] = 'Banish',
    [1098] = 'Enslave Demon',
    [2637] = 'Hibernate',
    [2908] = 'Soothe Animal',
    [1513] = 'Scare Beast',
    [1515] = 'Tame Beast',
    [1462] = 'Beast Lore',
    [118] = 'Polymorph',
    [6770] = 'Sap',
    [24275] = 'Hammer of Wrath',
    [5308] = 'Execute',
    [72] = 'Shield Bash',
    [6552] = 'Pummel',
    [1766] = 'Kick',
    [2139] = 'Counterspell',
    [8042] = 'Earth Shock',
    [15487] = 'Silence',
    [589] = 'Shadow Word: Pain',
    [172] = 'Corruption',
    [6222] = 'Corruption', -- Higher rank
    [348] = 'Immolate',
    [980] = 'Curse of Agony',
    [8921] = 'Moonfire',
    [770] = 'Faerie Fire',
    [5570] = 'Insect Swarm',
    [1130] = "Hunter's Mark",
    [1978] = 'Serpent Sting',
    [772] = 'Rend',
    [21084] = 'Seal of Righteousness',
    [21082] = 'Seal of the Crusader',
    [20375] = 'Seal of Command',
    [20164] = 'Seal of Justice',
    [20165] = 'Seal of Light',
    [20166] = 'Seal of Wisdom',
    [20271] = 'Judgement',
    [17962] = 'Conflagrate',
    [8129] = 'Mana Burn',
    [5138] = 'Drain Mana',
    [3034] = 'Viper Sting',
    [7386] = 'Sunder Armor',
    [1160] = 'Demoralizing Shout',
    [6343] = 'Thunder Clap',
    [99] = 'Demoralizing Roar',
    [16857] = 'Faerie Fire (Feral)',
    [15286] = 'Vampiric Embrace',
    [18265] = 'Siphon Life',
    [1490] = 'Curse of the Elements',
    [17862] = 'Curse of Shadow',
    [704] = 'Curse of Recklessness',
    [702] = 'Curse of Weakness',
}

Stub.spells = {}
function Stub.ResetSpells()
    Stub.spells = {}
    Stub.lastRequestedSpell = nil
    Stub.requestedSpells = {}
    Stub.spellRequestCounts = {}
    for k, v in pairs(Stub.DEFAULT_SPELLS) do
        Stub.spells[k] = v
    end
end
Stub.ResetSpells()

_G.C_Spell = {
    GetSpellName = function(spellID)
        return Stub.spells[spellID]
    end,
    RequestLoadSpellData = function(spellID)
        Stub.lastRequestedSpell = spellID
        Stub.requestedSpells[spellID] = true
        Stub.spellRequestCounts[spellID] = (Stub.spellRequestCounts[spellID] or 0) + 1
    end,
}

function _G.GetSpellInfo(spellID)
    return Stub.spells[spellID]
end

function _G.UnitExists(unit)
    local u = Stub.units[unit]
    if not u then
        return false
    end
    if u.exists ~= nil then
        return u.exists
    end
    return true
end

function _G.UnitCanAttack(attacker, target)
    local u = Stub.units[target]
    if not u then
        return false
    end
    return u.canAttack
end

function _G.UnitCreatureType(unit)
    local u = Stub.units[unit]
    if not u then
        return nil, nil
    end
    return u.creatureTypeName, u.creatureTypeID
end

function _G.UnitPowerType(unit)
    local u = Stub.units[unit]
    if not u then return 0 end
    return u.powerType or 0
end

function _G.UnitPowerMax(unit, powerType)
    local u = Stub.units[unit]
    if not u then return 100 end
    return u.powerMax or 100
end

function _G.UnitAffectingCombat(unit)
    local u = Stub.units[unit]
    if not u then return false end
    return u.affectingCombat or false
end

function _G.UnitCastingInfo(unit)
    local u = Stub.units[unit]
    if not u or not u.casting then
        return nil
    end
    local c = u.casting
    return c.name, c.text, c.texture, c.startTime, c.endTime, c.isTradeSkill, c.castID, c.notInterruptible, c.spellId
end

function _G.UnitChannelInfo(unit)
    local u = Stub.units[unit]
    if not u or not u.channeling then
        return nil
    end
    local c = u.channeling
    return c.name, c.text, c.texture, c.startTime, c.endTime, c.isTradeSkill, c.notInterruptible, c.spellId
end

_G.C_UnitAuras = {
    GetAuraDataByIndex = function(unit, index, filter)
        Stub.lastAuraUnit = unit
        Stub.lastAuraFilter = filter
        local list = Stub.auras[unit]
        if not list then
            return nil
        end
        local filtered = {}
        for i = 1, #list do
            if not list[i].filter or list[i].filter == filter then
                filtered[#filtered + 1] = list[i]
            end
        end
        return filtered[index]
    end,
    GetAuraDataBySpellName = function()
        error('GetAuraDataBySpellName should not be used (RequiresNonSecretAura)')
    end,
}

function _G.GetActionInfo(slot)
    local act = Stub.actions[slot]
    if not act then
        return nil
    end
    return act.type, act.id, act.subType
end

function _G.IsUsableAction(slot)
    return Stub.usableActions[slot]
end

_G.C_ActionBar = {
    IsUsableAction = function(slot)
        return Stub.usableActions[slot]
    end,
}

function _G.PlaySound(soundKitID, channel)
    Stub.soundsPlayed[#Stub.soundsPlayed + 1] = {
        id = soundKitID,
        channel = channel,
    }
end

return Stub
