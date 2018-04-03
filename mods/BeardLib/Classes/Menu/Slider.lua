BeardLib.Items.Slider = BeardLib.Items.Slider or class(BeardLib.Items.Item)
local Slider = BeardLib.Items.Slider
Slider.type_name = "Slider"
function Slider:Init()
    self.value = self.value or 1
    self.size_by_text = false
	Slider.super.Init(self)
    self.step = self.step or 1
    self.value = tonumber(self.value) or 0
    self.min = self.min or self.value
    self.max = self.max or self.value
    if self.max or self.min then
        self.value = math.clamp(self.value, self.min, self.max)    
    end
    self:WorkParam("floats", 3)
    self.filter = "number"
    self.min = self.min or 0
    self.max = self.max or self.min
    local item_width = self.panel:w() * self.control_slice
    local slider_width = item_width * 0.66
    local text_width = item_width - slider_width

    local fgcolor = self:GetForeground()
    self._textbox = BeardLib.Items.TextBoxBase:new(self, {
        lines = 1,
        btn = "1",
        panel = self.panel,
        align = "center",
        layer = 10,
        line = false,
        w = text_width,
        value = self.value,
    })
    self._slider = self.panel:panel({
        w = slider_width,
        name = "slider",
        layer = 4,
    })
    local ch = self.size - 4
    self.circle = self._slider:bitmap({
        name = "circle",
        w = ch,
        h = ch,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {92, 1, 34, 34},
        layer = 3,
        color = fgcolor,
    })
    self.circle:set_center_y(self._slider:h() / 2)

    self.sfg = self._slider:rect({
        name = "fg",
        x = ch / 2,
        w = self._slider:w() * (self.value / self.max),
        h = 2,
        layer = 2,
        color = fgcolor
    })
    self.sfg:set_center_y(self._slider:h() / 2)
        
    self.sbg = self._slider:rect({
        name = "bg",
        x = ch / 2,        
        w = self._slider:w() - ch,
        h = 2,
        layer = 1,
        color = fgcolor:with_alpha(0.25),
    })
    self.sbg:set_center_y(self._slider:h() / 2)


    self._slider:set_right(self._textbox.panel:x())
    self._mouse_pos_x, self._mouse_pos_y = 0,0
    self._textbox:PostInit()
end

function Slider:SetStep(step)
    self.step = step
end

function Slider:TextBoxSetValue(value, run_callback, reset_selection, no_format)  
    value = tonumber(value) or 0 
    if self.max or self.min then
        value = math.clamp(value, self.min, self.max)    
    end
    value = tonumber(not no_format and format or value)
    local final_number = self.floats and string.format("%." .. self.floats .. "f", value) or tostring(value)
    local text = self._textbox.panel:child("text")
    self.sfg:set_w(self.sbg:w() * ((value - self.min) / (self.max - self.min)))
    self._slider:child("circle"):set_center(self.sfg:right(), self.sfg:center_y())
    if not no_format then
        text:set_text(final_number)
    end
    if reset_selection then
        text:set_selection(text:text():len())
    end
    self._before_text = self.value
    Slider.super.SetValue(self, value, run_callback)
end

function Slider:SetValue(value, ...)
    if not self:alive() then
        return false
    end
    if self.value ~= value then
        self._textbox:add_history_point(value)
    end
    self:TextBoxSetValue(value, ...)
    return true
end

function Slider:SetValueByPercentage(percent, run_callback)
    self:SetValue(self.min + (self.max - self.min) * percent, run_callback, true)
end

function Slider:MouseReleased(button, x, y)
    self._textbox:MouseReleased(button, x, y)
end

function Slider:DoHighlight(highlight)
    Slider.super.DoHighlight(self, highlight)
    self._textbox:DoHighlight(highlight)
    local fgcolor = self:GetForeground(highlight)
    if self.sfg then
        if self.animate_colors then
            play_color(self.sfg, fgcolor)
            play_color(self.sbg, fgcolor:with_alpha(0.25))
            play_color(self.circle, fgcolor)
        else
            self.sfg:set_color(fgcolor)
            self.sbg:set_color(fgcolor:with_alpha(0.25))
            self.circle:set_color(fgcolor)
        end
    end
end

local mouse_0 = Idstring("0")
local wheel_up = Idstring("mouse wheel up")
local wheel_down = Idstring("mouse wheel down")
function Slider:MousePressed(button, x, y)
	Slider.super.MousePressed(self, button, x, y)
    self._textbox:MousePressed(button, x, y)
    if not self.enabled or not alive(self.panel) then
        return
    end
    local inside = self._slider:inside(x,y)
    if inside then
        local wheelup = (button == wheel_up and 0) or (button == wheel_down and 1) or -1
        if self.wheel_control and wheelup ~= -1 then
            self:SetValue(self.value + ((wheelup == 1) and -self.step or self.step), true, true)
            return true
        end
    	if button == mouse_0 then
            self.menu._slider_hold = self
            if self.max or self.min then
                local slider_bg = self._slider:child("bg")
                local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
                managers.menu_component:post_event("menu_enter")
                self:SetValueByPercentage(where)
            end
            return true
        end
    end
end

local abs = math.abs
function Slider:SetValueByMouseXPos(x)
    if not alive(self.panel) then
        return
    end
    local slider_bg = self._slider:child("bg")
    self:SetValueByPercentage((x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left()), true)
end
