local addonName, ns = ...
local KL = LibStub('KnuLib-1.0')

_G.KnuCast = ns
ns.addonName = addonName or 'KnuCast'
ns.KL = KL
ns.Print = KL:NewPrinter('Cast')

ns.DEFAULTS = {
    glow = true,
    grey = true,
    sound = false,
    conditions = {
        types = true,
        execute = true,
        interrupt = true,
        debuff = true,
        requires = true,
        mana = true,
        outOfCombat = true,
    },
}

function ns:InitDB()
    if type(_G.KnuCastDB) ~= 'table' then
        _G.KnuCastDB = {}
    end
    self.db = KL:ApplyDefaults(_G.KnuCastDB, self.DEFAULTS)
    return self.db
end

-- KnuLib MINOR 5 event object; handlers registered through ns:RegisterEvent
-- still receive the event name as their first argument.
ns.events = KL:NewEvents()

ns.unitEvents = {}
ns.unitFiltered = {}
ns.unitFrames = {}

function ns:RegisterUnitEvent(unit, event, handler)
    assert(type(unit) == 'string', 'Expected unit')
    assert(type(event) == 'string', 'Expected event name')
    assert(type(handler) == 'function', 'Expected event handler function')
    
    if not self.unitEvents[unit] then
        self.unitEvents[unit] = {}
        self.unitFiltered[unit] = {}
        local frameName = 'KnuCast' .. unit:gsub('^%l', string.upper) .. 'Frame'
        self.unitFrames[unit] = CreateFrame('Frame', frameName)
        self.unitFrames[unit]:SetScript('OnEvent', function(_, ev, u)
            ns:FireUnitEvent(unit, ev, u)
        end)
    end

    local list = self.unitEvents[unit][event]
    if not list then
        list = {}
        self.unitEvents[unit][event] = list
        local unitFiltered = false
        local frame = self.unitFrames[unit]
        if type(frame.RegisterUnitEvent) == 'function' then
            local ok, res = pcall(frame.RegisterUnitEvent, frame, event, unit)
            unitFiltered = ok and res ~= false
        end
        if not unitFiltered then
            pcall(frame.RegisterEvent, frame, event)
        end
        self.unitFiltered[unit][event] = unitFiltered
    end
    list[#list + 1] = handler
end

function ns:FireUnitEvent(expectedUnit, event, unit)
    local list = self.unitEvents[expectedUnit] and self.unitEvents[expectedUnit][event]
    if not list then
        return
    end
    if not self.unitFiltered[expectedUnit][event] then
        if not (ns.Secret and ns.Secret.Accessible(unit)) then
            return
        end
        if unit ~= expectedUnit then
            return
        end
    end
    for i = 1, #list do
        list[i](event)
    end
end

function ns:RegisterEvent(event, handler)
    assert(type(event) == 'string', 'Expected event name')
    assert(type(handler) == 'function', 'Expected event handler function')
    -- Unknown events (e.g. ACTIONBAR_UPDATE_USABLE on Forever) make On return
    -- false and keep the error in ns.events.invalid; loading continues.
    return self.events:On(event, function(...)
        handler(event, ...)
    end)
end

function ns:RegisterTargetEvent(event, handler)
    self:RegisterUnitEvent('target', event, handler)
end

ns:InitDB()

ns:RegisterEvent('ADDON_LOADED', function(_, loadedName)
    if ns.Secret and not ns.Secret.Accessible(loadedName) then
        return
    end
    if loadedName == nil or loadedName == ns.addonName then
        ns:InitDB()
    end
end)
