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
    },
}

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == 'table' then
            if type(dst[k]) ~= 'table' then
                dst[k] = {}
            end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function ns:InitDB()
    if type(_G.KnuCastDB) ~= 'table' then
        _G.KnuCastDB = {}
    end
    self.db = ApplyDefaults(_G.KnuCastDB, self.DEFAULTS)
    return self.db
end

ns.events = {}
ns.frame = CreateFrame('Frame', 'KnuCastFrame')

ns.targetEvents = {}
ns.targetUnitFiltered = {}
ns.targetFrame = CreateFrame('Frame', 'KnuCastTargetFrame')

function ns:RegisterEvent(event, handler)
    assert(type(event) == 'string', 'Expected event name')
    assert(type(handler) == 'function', 'Expected event handler function')
    local list = self.events[event]
    if not list then
        list = {}
        self.events[event] = list
        pcall(self.frame.RegisterEvent, self.frame, event)
    end
    list[#list + 1] = handler
end

function ns:RegisterTargetEvent(event, handler)
    assert(type(event) == 'string', 'Expected event name')
    assert(type(handler) == 'function', 'Expected event handler function')
    local list = self.targetEvents[event]
    if not list then
        list = {}
        self.targetEvents[event] = list
        local unitFiltered = false
        if type(self.targetFrame.RegisterUnitEvent) == 'function' then
            local ok, res = pcall(self.targetFrame.RegisterUnitEvent, self.targetFrame, event, 'target')
            unitFiltered = ok and res ~= false
        end
        if not unitFiltered then
            pcall(self.targetFrame.RegisterEvent, self.targetFrame, event)
        end
        self.targetUnitFiltered[event] = unitFiltered
    end
    list[#list + 1] = handler
end

function ns:FireEvent(event, ...)
    local list = self.events[event]
    if not list then
        return
    end
    for i = 1, #list do
        list[i](event, ...)
    end
end

function ns:FireTargetEvent(event, unit)
    local list = self.targetEvents[event]
    if not list then
        return
    end
    if not self.targetUnitFiltered[event] then
        if not (ns.Secret and ns.Secret.Accessible(unit)) then
            return
        end
        if unit ~= 'target' then
            return
        end
    end
    for i = 1, #list do
        list[i](event)
    end
end

ns.frame:SetScript('OnEvent', function(_, event, ...)
    ns:FireEvent(event, ...)
end)

ns.targetFrame:SetScript('OnEvent', function(_, event, unit)
    ns:FireTargetEvent(event, unit)
end)

ns:InitDB()

ns:RegisterEvent('ADDON_LOADED', function(_, loadedName)
    if ns.Secret and not ns.Secret.Accessible(loadedName) then
        return
    end
    if loadedName == nil or loadedName == ns.addonName then
        ns:InitDB()
    end
end)
