local const = require("druid.const")
local event = require("event.event")
local helper = require("druid.helper")

---@class widget.on_screen_joystick: druid.widget
---@field stick_root node
---@field stick_position vector3
---@field on_action event @()
---@field on_movement event @(x: number, y: number, dt: number) X/Y values are in range -1..1
---@field on_movement_stop event @()
---@field is_multitouch boolean
---@field _is_stick_drag boolean|number
---@field _prev_x number
---@field _prev_y number
local M = {}

local STICK_DISTANCE = 80
local ALPHA_IDLE = 0.5
local ALPHA_ACTIVE = 1


function M:init()
	self.root = self:get_node("root")
	self.content = self:get_node("content")
	self.stick_root = self:get_node("stick_root")
	self.stick_position = gui.get_position(self.stick_root)

	self.on_movement = event.create()
	self.on_movement_stop = event.create()

	self.is_multitouch = helper.is_multitouch_supported()

	-- Set initial alpha to idle state
	gui.set_alpha(self.root, ALPHA_IDLE)
end


---@param action_id hash
---@param action action
function M:on_input(action_id, action)
	if self.is_multitouch then
		if action_id == const.ACTION_MULTITOUCH then
			for _, touch in ipairs(action.touch) do
				self:process_touch(touch)
			end
		end
	else
		if action_id == const.ACTION_TOUCH then
			self:process_touch(action)
		end
	end

	return false
end


---@param action action|touch
function M:process_touch(action)
	local is_the_same_touch_id = not action.id or action.id == self._is_stick_drag

	if gui.pick_node(self.root, action.x, action.y) then
		if not self._is_stick_drag then
			-- First touch - initialize drag
			self._is_stick_drag = action.id or true
			-- Reset stick to center and initialize tracking
			self.stick_position.x = 0
			self.stick_position.y = 0
			self._prev_x = action.x
			self._prev_y = action.y
			gui.set_position(self.stick_root, self.stick_position)

			-- Animate alpha to active state when drag starts
			gui.animate(self.root, "color.w", ALPHA_ACTIVE, gui.EASING_OUTQUAD, 0.2)
		end
	end

	if self._is_stick_drag and is_the_same_touch_id then
		-- action.dx and action.dy are broken inside touches for some reason, manual calculations seems fine
		local dx = action.x - (self._prev_x or action.x)
		local dy = action.y - (self._prev_y or action.y)
		self._prev_x = action.x
		self._prev_y = action.y

		self.stick_position.x = self.stick_position.x + dx
		self.stick_position.y = self.stick_position.y + dy

		-- Limit to STICK_DISTANCE
		local length = vmath.length(self.stick_position)
		if length > STICK_DISTANCE then
			self.stick_position.x = self.stick_position.x / length * STICK_DISTANCE
			self.stick_position.y = self.stick_position.y / length * STICK_DISTANCE
		end

		gui.set_position(self.stick_root, self.stick_position)
	end

	if action.released and is_the_same_touch_id then
		self._is_stick_drag = false
		self.stick_position.x = 0
		self.stick_position.y = 0
		self._prev_x = nil
		self._prev_y = nil
		gui.animate(self.stick_root, gui.PROP_POSITION, self.stick_position, gui.EASING_OUTBACK, 0.3)

		-- Animate alpha back to idle state
		gui.animate(self.root, "color.w", ALPHA_IDLE, gui.EASING_OUTQUAD, 0.3)

		self.on_movement_stop:trigger()
	end
end


function M:update(dt)
	if self.stick_position.x ~= 0 or self.stick_position.y ~= 0 then
		self.on_movement:trigger(self.stick_position.x / STICK_DISTANCE, self.stick_position.y / STICK_DISTANCE, dt)
	end
end


return M

