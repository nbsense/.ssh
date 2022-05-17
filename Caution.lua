-- @version: 1.0.0
-- @latest update:

-- @ffi
local ffi = require 'ffi'

-- @ui
local ui = {
    visuals = {
        enabled = Menu.Switch('Visuals', 'Main', 'Enabled', false),

        custom_scope = Menu.SwitchColor('Visuals', 'Other', 'Custom Scope', false, Color.RGBA(0, 0, 0, 255)),
        scope = {
            overlay_position = Menu.SliderInt('Visuals', 'Other', 'Initial Pos.', 190, 0, 500),
            overlay_offset = Menu.SliderInt('Visuals', 'Other', 'Offset', 15, 0, 500),
            fade_time = Menu.SliderInt('Visuals', 'Other', 'Fade Anim.', 12, 3, 20, '[3] = Off'),
            viewmodel = Menu.Switch('Visuals', 'Other', 'Viewmodel in Scope', false),
        },
        
        
    },
}

-- @helpers
local helpers = {
    clamp = function(v, min, max) 
        local num = v 
        
        num = num < min and min or num
        num = num > max and max or num
        
        return num 
    end,

    set_table_visibility = function(table, state)
        for i = 1, #table do
            table[i]:SetVisible(state)
        end
    end,
}

-- @easing
local easing = {
    linear = function(t, b, c, d)
        return c * t / d + b
    end,
}

-- @vars
local vars = {
    custom_scope = {
        m_alpha = 0
    }
}

-- @functions
local function ui_callback()
    helpers.set_table_visibility({ui.visuals.custom_scope}, ui.visuals.enabled:Get())
    helpers.set_table_visibility({ui.visuals.scope.overlay_position, ui.visuals.scope.overlay_offset, ui.visuals.scope.fade_time, ui.visuals.scope.viewmodel}, ui.visuals.enabled:Get() and ui.visuals.custom_scope:Get())
end

local function custom_scope()
    if not ui.visuals.enabled:Get() or not ui.visuals.custom_scope:Get() then
        return
    end

    local size = EngineClient.GetScreenSize()
    local width, height = size.x, size.y
    local offset, initial_position, speed, color =
        ui.visuals.scope.overlay_offset:Get() * height / 1080,
        ui.visuals.scope.overlay_position:Get() * height / 1080,
        ui.visuals.scope.fade_time:Get(),
        ui.visuals.custom_scope:GetColor()

    local me = EntityList.GetLocalPlayer()

    if me == nil or not me:IsAlive() then
        return
    end

    local wpn = me:GetActiveWeapon()

    if wpn == nil then
        return
    end

    local scope_level = wpn:GetProp('m_zoomLevel')
    local scoped = me:GetProp('m_bIsScoped')
    local resume_zoom = me:GetProp('m_bResumeZoom')

    local act = scope_level ~= nil and scope_level > 0 and scoped and not resume_zoom

    local FT = speed > 3 and GlobalVars.frametime * speed or 1
    local alpha = easing.linear(vars.custom_scope.m_alpha, 0, 1, 1)

    Render.GradientBoxFilled(Vector2.new(width / 2 - initial_position + 2, height / 2), Vector2.new(width / 2 - offset + 2, height / 2 + 1), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, alpha * color.a))
    Render.GradientBoxFilled(Vector2.new(width / 2 + offset, height / 2), Vector2.new(width / 2 + initial_position, height / 2 + 1), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, 0))

    Render.GradientBoxFilled(Vector2.new(width / 2, height / 2 - initial_position + 2), Vector2.new(width / 2 + 1, height / 2 - offset + 2), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, alpha * color.a))
    Render.GradientBoxFilled(Vector2.new(width / 2, height / 2 + offset), Vector2.new(width / 2 + 1, height / 2 + initial_position), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, alpha * color.a), Color.new(color.r, color.g, color.b, 0), Color.new(color.r, color.g, color.b, 0))

    vars.custom_scope.m_alpha = helpers.clamp(vars.custom_scope.m_alpha + (act and FT or -FT), 0, 1)
end

local function viewmodel_in_scope()
    CVar.FindVar('fov_cs_debug'):SetInt((ui.visuals.enabled:Get() and ui.visuals.custom_scope:Get() and ui.visuals.scope.viewmodel:Get()) and 90 or 0)
end

for _, cid in pairs({
    {
        'frame_stage', function(stage)
            viewmodel_in_scope()
        end,
    },

    {
        'draw', function()
            ui_callback()
            custom_scope()
        end,
    },
}) do
    Cheat.RegisterCallback(cid[1], cid[2])
end
