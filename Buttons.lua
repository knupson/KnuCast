local _, ns = ...

local Buttons = {
    list = {},
    known = {},
    overlays = {},
    needsDiscovery = true,
}
ns.Buttons = Buttons

local BLIZZARD_PREFIXES = {
    'ActionButton',
    'MultiBarBottomLeftButton',
    'MultiBarBottomRightButton',
    'MultiBarRightButton',
    'MultiBarLeftButton',
    'MultiBar5Button',
    'MultiBar6Button',
    'MultiBar7Button',
}

function Buttons.IsInCombat()
    if type(InCombatLockdown) == 'function' then
        local ok, locked = pcall(InCombatLockdown)
        return ok and locked == true or false
    end
    return false
end

-- Resolves the action slot for a button.
-- For LibActionButton (ElvUI / Bartender4), _state_action is only used when
-- _state_type == "action"; if _state_type is set to anything else, the button
-- is ignored.
function Buttons.GetSlot(button)
    if type(button) ~= 'table' and type(button) ~= 'userdata' then
        return nil
    end
    if button._state_type ~= nil then
        if button._state_type ~= 'action' then
            return nil
        end
        if type(button._state_action) == 'number' and button._state_action > 0 then
            return button._state_action
        end
    end
    if type(button.action) == 'number' and button.action > 0 then
        return button.action
    end
    if type(button.GetAttribute) == 'function' then
        local okType, attrType = pcall(button.GetAttribute, button, 'type')
        if okType and attrType ~= nil and attrType ~= 'action' then
            return nil
        end
        local okAct, attrAction = pcall(button.GetAttribute, button, 'action')
        if okAct and type(attrAction) == 'number' and attrAction > 0 then
            return attrAction
        end
    end
    return nil
end

function Buttons.GetSlotSpellID(slot)
    if type(slot) ~= 'number' or slot <= 0 then
        return nil
    end
    if type(GetActionInfo) ~= 'function' then
        return nil
    end
    local ok, actionType, id = pcall(GetActionInfo, slot)
    if not ok or not ns.Secret.Accessible(actionType) or not ns.Secret.Accessible(id) then
        return nil
    end
    if actionType ~= 'spell' or type(id) ~= 'number' or id <= 0 then
        return nil
    end
    return id
end

function Buttons.GetSlotSpellName(slot)
    local id = Buttons.GetSlotSpellID(slot)
    if not id then
        return nil
    end
    local name = ns.Data.GetSpellName(id)
    if not name then
        ns.Data:TrackActionSpell(id)
        return nil
    end
    ns.Data:ResolveActionSpell(id)
    return name
end

function Buttons.GetButtonRules(button)
    local slot = Buttons.GetSlot(button)
    if not slot then
        return nil, nil, nil
    end
    local spellName = Buttons.GetSlotSpellName(slot)
    if not spellName then
        return nil, slot, nil
    end
    local rules = ns.Data:GetRulesForSpell(spellName)
    if not rules or #rules == 0 then
        return nil, slot, spellName
    end
    return rules, slot, spellName
end

-- Glow border: 4 px gold, sticking out GLOW_OUTSET px past the button so it
-- still reads next to the bar addon's own borders (user, 21/11: the old 2 px
-- orange edge was not evident enough).
local GLOW_EDGE = 4
local GLOW_OUTSET = 2

local function CreateBorderEdge(parent, point1, x1, y1, point2, x2, y2, width, height)
    local tex = parent:CreateTexture(nil, 'OVERLAY')
    tex:SetColorTexture(1, 0.82, 0.1, 1)
    tex:SetPoint(point1, parent, point1, x1, y1)
    tex:SetPoint(point2, parent, point2, x2, y2)
    if width and tex.SetWidth then
        tex:SetWidth(width)
    end
    if height and tex.SetHeight then
        tex:SetHeight(height)
    end
    return tex
end

-- Creates our own non-secure overlay frame/textures as children of the action
-- button OUT OF COMBAT, keeping all references in Buttons.overlays[button].
function Buttons:CreateOverlay(button)
    if self.overlays[button] then
        return self.overlays[button]
    end
    if Buttons.IsInCombat() then
        self.needsDiscovery = true
        return nil
    end

    local holder = CreateFrame('Frame', nil, button)
    holder:SetAllPoints(button)
    if type(button.GetFrameLevel) == 'function' and type(holder.SetFrameLevel) == 'function' then
        local level = button:GetFrameLevel() or 1
        holder:SetFrameLevel(level + 4)
    end

    -- Anchor to our own holder (= the whole button), never to the bar addon's
    -- icon texture: on ElvUI the grey ended up covering only the icon's
    -- top-left corner, so a greyed spell still looked usable (19/11 in game).
    local grey = holder:CreateTexture(nil, 'OVERLAY')
    grey:SetAllPoints(holder)
    grey:SetColorTexture(0, 0, 0, 0.65)
    grey:Hide()

    local glow = CreateFrame('Frame', nil, holder)
    glow:SetAllPoints(holder)

    local fill = glow:CreateTexture(nil, 'OVERLAY')
    fill:SetAllPoints(holder)
    if fill.SetBlendMode then
        fill:SetBlendMode('ADD')
    end
    fill:SetColorTexture(1, 0.8, 0.2, 0.35)

    local o = GLOW_OUTSET
    local edges = {
        CreateBorderEdge(glow, 'TOPLEFT', -o, o, 'TOPRIGHT', o, o, nil, GLOW_EDGE),
        CreateBorderEdge(glow, 'BOTTOMLEFT', -o, -o, 'BOTTOMRIGHT', o, -o, nil, GLOW_EDGE),
        CreateBorderEdge(glow, 'TOPLEFT', -o, o, 'BOTTOMLEFT', -o, -o, GLOW_EDGE, nil),
        CreateBorderEdge(glow, 'TOPRIGHT', o, o, 'BOTTOMRIGHT', o, -o, GLOW_EDGE, nil),
    }

    local animGroup
    if type(glow.CreateAnimationGroup) == 'function' then
        animGroup = glow:CreateAnimationGroup()
        if animGroup.SetLooping then
            animGroup:SetLooping('BOUNCE')
        end
        if type(animGroup.CreateAnimation) == 'function' then
            local alpha = animGroup:CreateAnimation('Alpha')
            if alpha then
                if alpha.SetFromAlpha and alpha.SetToAlpha then
                    alpha:SetFromAlpha(0.45)
                    alpha:SetToAlpha(1.0)
                elseif alpha.SetChange then
                    alpha:SetChange(-0.65)
                end
                if alpha.SetDuration then
                    alpha:SetDuration(0.4)
                end
                if alpha.SetSmoothing then
                    alpha:SetSmoothing('IN_OUT')
                end
            end
        end
    end

    glow:Hide()

    local overlay = {
        frame = holder,
        glow = glow,
        fill = fill,
        edges = edges,
        anim = animGroup,
        grey = grey,
        state = 'none',
    }
    self.overlays[button] = overlay
    return overlay
end

local KnuCastLABHandle = {}
Buttons.labHandle = KnuCastLABHandle

local LAB_NAMES = {
    'LibActionButton-1.0',
    'LibActionButton-1.0-ElvUI',
}

local function OnLABButtonUpdate(arg1, arg2, arg3)
    local button
    if (type(arg1) == 'table' or type(arg1) == 'userdata') and arg1 ~= KnuCastLABHandle then
        button = arg1
    elseif type(arg2) == 'table' or type(arg2) == 'userdata' then
        button = arg2
    elseif type(arg3) == 'table' or type(arg3) == 'userdata' then
        button = arg3
    end
    if not button or not Buttons.known[button] then
        return
    end
    if ns.Engine and type(ns.Engine.UpdateButton) == 'function' then
        ns.Engine:UpdateButton(button)
    end
end

function Buttons:SubscribeLAB()
    if type(LibStub) ~= 'table' and type(LibStub) ~= 'function' then
        return
    end
    for i = 1, #LAB_NAMES do
        local ok, lib = pcall(LibStub, LAB_NAMES[i], true)
        if ok and type(lib) == 'table' and type(lib.RegisterCallback) == 'function' then
            pcall(lib.RegisterCallback, KnuCastLABHandle, 'OnButtonUpdate', OnLABButtonUpdate)
            pcall(lib.RegisterCallback, KnuCastLABHandle, 'OnButtonState', OnLABButtonUpdate)
        end
    end
end

function Buttons:RegisterButton(button)
    if type(button) ~= 'table' and type(button) ~= 'userdata' then
        return
    end
    if not self.known[button] then
        self.known[button] = true
        self.list[#self.list + 1] = button
    end
    if not self.overlays[button] then
        self:CreateOverlay(button)
    end
    local slot = Buttons.GetSlot(button)
    if slot then
        Buttons.GetSlotSpellName(slot)
    end
end

function Buttons:Discover()
    if Buttons.IsInCombat() then
        self.needsDiscovery = true
        return false
    end

    self:SubscribeLAB()

    for i = 1, #BLIZZARD_PREFIXES do
        local prefix = BLIZZARD_PREFIXES[i]
        for j = 1, 12 do
            local btn = _G[prefix .. j]
            if btn then
                self:RegisterButton(btn)
            end
        end
    end

    for bar = 1, 15 do
        local prefix = 'ElvUI_Bar' .. bar .. 'Button'
        for j = 1, 12 do
            local btn = _G[prefix .. j]
            if btn then
                self:RegisterButton(btn)
            end
        end
    end

    for i = 1, 180 do
        local bt4 = _G['BT4Button' .. i]
        if bt4 then
            self:RegisterButton(bt4)
        end
        local dom = _G['DominosActionButton' .. i]
        if dom then
            self:RegisterButton(dom)
        end
    end

    for i = 1, #self.list do
        local btn = self.list[i]
        if not self.overlays[btn] then
            self:CreateOverlay(btn)
        end
    end

    self.needsDiscovery = false
    return true
end

function Buttons:SetVisual(button, visual)
    visual = visual or 'none'
    local overlay = self.overlays[button]
    if not overlay then
        overlay = self:CreateOverlay(button)
        if not overlay then
            return false
        end
    end

    overlay.state = visual
    if visual == 'glow' then
        overlay.grey:Hide()
        overlay.glow:Show()
        if overlay.anim and overlay.anim.Play then
            local playing = overlay.anim.IsPlaying and overlay.anim:IsPlaying()
            if not playing then
                overlay.anim:Play()
            end
        end
    elseif visual == 'grey' then
        if overlay.anim and overlay.anim.Stop then
            overlay.anim:Stop()
        end
        overlay.glow:Hide()
        overlay.grey:Show()
    else
        if overlay.anim and overlay.anim.Stop then
            overlay.anim:Stop()
        end
        overlay.glow:Hide()
        overlay.grey:Hide()
    end
    return true
end

function Buttons:GetVisual(button)
    local overlay = self.overlays[button]
    return overlay and overlay.state or 'none'
end

function Buttons:ClearAll()
    for i = 1, #self.list do
        local btn = self.list[i]
        if self.overlays[btn] then
            self:SetVisual(btn, 'none')
        end
    end
end

function Buttons:CountButtonsWithRules()
    local count = 0
    for i = 1, #self.list do
        if Buttons.GetButtonRules(self.list[i]) then
            count = count + 1
        end
    end
    return count
end

function Buttons:Reset()
    self.list = {}
    self.known = {}
    self.overlays = {}
    self.needsDiscovery = true
    if ns.Data and type(ns.Data.ResetPendingActionSpells) == 'function' then
        ns.Data:ResetPendingActionSpells()
    end
end

Buttons:SubscribeLAB()
