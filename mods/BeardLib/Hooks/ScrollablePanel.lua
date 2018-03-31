ScrollablePanelModified = ScrollablePanelModified or class(ScrollablePanel)
local PANEL_PADDING = 4

function ScrollablePanelModified:init(panel, name, data)
	ScrollablePanelModified.super.init(self, panel, name, data)
	data = data or {}
	data.scroll_width = data.scroll_width or 4
	data.color = data.color or Color.black
	self._scroll_width = data.scroll_width
	self._scroll_speed = data.scroll_speed or 28

	local panel = self:panel()
	self:canvas():set_w(panel:w() - data.scroll_width)
	panel:child("scroll_up_indicator_arrow"):hide()
	panel:child("scroll_down_indicator_arrow"):hide()
	self._scroll_bar:set_w(data.scroll_width)
	self._scroll_bar:set_right(self:panel():w())
	self._scroll_bg = panel:rect({
		name = "scroll_bg",
		color = data.color:contrast():with_alpha(0.1),
		visible = not data.hide_scroll_background,
		x = self._scroll_bar:x(),
		w = data.scroll_width,
		h = panel:h(),
	})

	if data.hide_shade then
		panel:child("scroll_up_indicator_shade"):hide()
		panel:child("scroll_down_indicator_shade"):hide()
	end
	self:set_scroll_color(data.color)
end

function ScrollablePanelModified:set_scroll_color(color)
	color = color or Color.white
	local function set_boxgui_img(pnl)
		for _, child in pairs(pnl:children()) do
			local typ = type_name(child)
			if typ == "Panel" then
				set_boxgui_img(child)
			elseif typ == "Bitmap" then
				if child:texture_name() == Idstring("guis/textures/pd2/shared_lines") then
					child:set_image("units/white_df")
					child:set_x(0)
					child:set_w(child:parent():w())
				end
				child:set_color(color)
			end
		end
	end
	set_boxgui_img(self:panel())
end

function ScrollablePanelModified:set_size(...)
    ScrollablePanelModified.super.set_size(self, ...)
	self:canvas():set_w(self:canvas_max_width())
	self._scroll_bar:set_right(self:panel():w())
	self._scroll_bg:set_x(self._scroll_bar:x())
end

function ScrollablePanelModified:update_canvas_size()
	local orig_w = self:canvas():w()
	local max_h = 0
	local children = self:canvas():children()
	for i, panel in pairs(children) do
		if panel:visible() then
			local h = panel:bottom()
			if max_h < h then
				max_h = h
			end
		end
	end
	local scroll_h = self:canvas_scroll_height()
	local show_scrollbar = scroll_h > 0 and scroll_h < max_h
	local max_w = show_scrollbar and self:canvas_scroll_width() or self:canvas_max_width()

	self:canvas():grow(max_w - self:canvas():w(), max_h - self:canvas():h())
	self:canvas():set_w(math.min(self:canvas():w(), self:scroll_panel():w()))
	if self._on_canvas_updated then
		self._on_canvas_updated(max_w)
	end

	max_h = 0

	for i, panel in pairs(children) do
		if panel:visible() then
			local h = panel:bottom()
			if max_h < h then
				max_h = h
			end
		end
	end

	if max_h <= self:scroll_panel():h() then
		max_h = self:scroll_panel():h()
	end

	self:set_canvas_size(nil, max_h)
end

function ScrollablePanelModified:is_scrollable()
	return (self:canvas():h() - self:scroll_panel():h()) > 2
end

function ScrollablePanelModified:canvas_max_width()
	return self:canvas_scroll_width()
end

function ScrollablePanelModified:scroll(x, y, direction)
	if self:panel():inside(x, y) then
		self:perform_scroll(self._scroll_speed * TimerManager:main():delta_time() * 200, direction)
		return true
	end
end

function ScrollablePanelModified:mouse_moved(button, x, y)
	if self._grabbed_scroll_bar then
		self:scroll_with_bar(y, self._current_y)
		self._current_y = y
		return true, "grab"
	elseif alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true, "hand"
	elseif self:panel():child("scroll_up_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_up then
			self:perform_scroll(self._scroll_speed * 0.1, 1)
		end
		return true, "link"
	elseif self:panel():child("scroll_down_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_down then
			self:perform_scroll(self._scroll_speed * 0.1, -1)
		end
		return true, "link"
	end
end

function ScrollablePanelModified:canvas_scroll_width()
	return math.max(0, self:scroll_panel():w() - self._scroll_bar:w())
end

function ScrollablePanelModified:set_canvas_size(w, h)
	w = w or self:canvas():w()
	h = h or self:canvas():h()
	if h <= self:scroll_panel():h() then
		h = self:scroll_panel():h()
		self:canvas():set_y(0)
	end
	self:canvas():set_size(w, h)
	local show_scrollbar = (h - self:scroll_panel():h()) > 0.5
	if not show_scrollbar then
		self._scroll_bar:set_alpha(0)
		self._scroll_bar:set_visible(false)
		self._scroll_bg:hide()
		self._scroll_bar_box_class:hide()
	else
		self._scroll_bar:set_alpha(1)
		self._scroll_bar:set_visible(true)
		self._scroll_bar_box_class:show()
		self._scroll_bg:show()
		self:_set_scroll_indicator()
		self:_check_scroll_indicator_states()
	end
end

function ScrollablePanelModified:set_element_alpha_target(element, target, speed)
	play_anim(self:panel():child(element), {set = {alpha = target}})
end

function ScrollablePanelModified:scrollbar_x_padding()
	return self._x_padding or PANEL_PADDING
end

function ScrollablePanelModified:scrollbar_y_padding()
	return self._y_padding or PANEL_PADDING
end

function ScrollablePanelModified:_set_scroll_indicator()
	local bar_h = self:panel():h()
	if self:canvas():h() ~= 0 then
		self._scroll_bar:set_h(math.max((bar_h * self:scroll_panel():h()) / self:canvas():h(), self._bar_minimum_size))
	end
end

function ScrollablePanelModified:_check_scroll_indicator_states()
	local canvas_h = self:canvas():h() ~= 0 and self:canvas():h() or 1
	local at = self:canvas():top() / (self:scroll_panel():h() - canvas_h)
	local max = self:panel():h() - self._scroll_bar:h()

	self._scroll_bar:set_top(max * at)
end
