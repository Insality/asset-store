local color = require("druid.color")
local decore = require("decore.decore")
local command_debug_draw = require("system.debug_draw.debug_draw_command")

---@class entity
---@field debug_draw component.debug_draw|nil

---@class entity.debug_draw: entity
---@field debug_draw component.debug_draw
---@field game_object component.game_object

---@class component.debug_draw: boolean
decore.register_component("debug_draw", false)

---@class system.debug_draw: system
---@field buffer_info table
---@field header table
---@field entities entity.debug_draw[]
---@field is_dirty boolean
local M = require("M")(...)

local HASH_DRAW_TEXT = hash("draw_text")
local MSG_DRAW_TEXT = {
	text = "",
	position = vmath.vector3(),
}
local DEFAULT_COLOR = color.hex2vector4("#FF6430")
local SIZE = 1024

---@return system.debug_draw
function M.create()
	local system = decore.system(M, "debug_draw")

	system.buffer_info = {
	buffer = buffer.create(SIZE * SIZE, {{
			name = hash("my_buffer"),
			type = buffer.VALUE_TYPE_UINT8,
			count = 4 -- same as channels
		}}),
		width = SIZE,
		height = SIZE,
		channels = 4,
		premultiply_alpha = false
	}

	system.header = {
		width  = SIZE,
		height = SIZE,
		type   = graphics.TEXTURE_TYPE_2D,
		format = graphics.TEXTURE_FORMAT_RGBA,
	}

	return system
end


function M:onAddToWorld()
	self.is_dirty = true
	self.world.debug_draw = command_debug_draw.create(self)
end


---@param x number center
---@param y number center
---@param width number
---@param height number
---@param color vector4
function M:draw_rectangle(x, y, width, height, color)
	local x1, y1 = self:convert_to_texture(x, y)
	color = color or DEFAULT_COLOR

	local x2, y2 = self:convert_to_texture(x + width, y + height)
	width = (x2 - x1)
	height = (y2 - y1)

	--drawpixels.rect(self.buffer, x1, y1, width, height, color.x * 255, color.y * 255, color.z * 255, color.w * 255)

	x1 = x1 - width / 2
	y1 = y1 - height / 2

	drawpixels.line(self.buffer_info, x1, y1, x1 + width, y1, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer_info, x1 + width, y1, x1 + width, y1 + height, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer_info, x1 + width, y1 + height, x1, y1 + height, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)
	drawpixels.line(self.buffer_info, x1, y1 + height, x1, y1, color.x * 255, color.y * 255, color.z * 255, color.w * 255, false, 2)

	self.is_dirty = true
end


function M:draw_rectangle_fill(x, y, width, height, fill_color)
	fill_color = fill_color or DEFAULT_COLOR

	local x1, y1 = self:convert_to_texture(x, y)
	local x2, y2 = self:convert_to_texture(x + width, y + height)
	width = (x2 - x1)
	height = (y2 - y1)

	drawpixels.filled_rect(self.buffer_info, x1, y1, width, height, fill_color.x * 255, fill_color.y * 255, fill_color.z * 255, fill_color.w * 255)

	self.is_dirty = true
end


function M:draw_text(x, y, text, color)
	self.is_dirty = true

	local x1, y1 = self.world.camera:world_to_screen(x, y)
	MSG_DRAW_TEXT.position.x = x1
	MSG_DRAW_TEXT.position.y = y1
	MSG_DRAW_TEXT.text = text

	-- Still are best way to draw text? I can't find any other way, somehow with label factories? or gui?
	-- Probably GUI also can replace draw pixels to use just nodes? sounds good
	msg.post("@render:", HASH_DRAW_TEXT, MSG_DRAW_TEXT)
end


function M:draw_line(x1, y1, x2, y2, line_color)
	x1, y1 = self:convert_to_texture(x1, y1)
	x2, y2 = self:convert_to_texture(x2, y2)
	line_color = line_color or DEFAULT_COLOR
	drawpixels.line(self.buffer_info, x1, y1, x2, y2, line_color.x * 255, line_color.y * 255, line_color.z * 255, line_color.w * 255, false, 4)
	self.is_dirty = true
end


function M:get_screen_ratio()
	local gui_width = sys.get_config_int("display.width")
	local gui_height = sys.get_config_int("display.height")
	local gui_r = gui_width / gui_height

	local _, _, window_width, window_height = defos.get_view_size()
	local window_r = window_width / window_height

	local w_s = 1
	local h_s = 1

	if gui_r < window_r then
		w_s = window_r / gui_r
	else
		h_s = gui_r / window_r
	end

	return w_s, h_s
end


function M:update()
	if not self.is_dirty then
		if not self.is_cleared then
			self.is_cleared = true
		else
			return
		end
	end

	local camera = self.world.camera:get_current_camera()
	if not camera then
		return
	end

	local sprite_url = msg.url(nil, camera.game_object.root, "screen_overlay")
	local texture = go.get(sprite_url, "texture0")

	local ratio_x, ratio_y = self:get_screen_ratio()
	go.set(sprite_url, "size.x", sys.get_config_int("display.width") * ratio_x)
	go.set(sprite_url, "size.y", sys.get_config_int("display.height") * ratio_y)

	resource.set_texture(texture, self.header, self.buffer_info.buffer)

	-- Too slow! how update and clear faster?
	drawpixels.fill(self.buffer_info, 0, 0, 0, 0)

	if self.is_dirty then
		self.is_cleared = false
	end
	self.is_dirty = false
end


---@param x number World x
---@param y number World y
---@return number x Texture x
---@return number y Texture y
function M:convert_to_texture(x, y)
	local screen_x, screen_y = self.world.camera:world_to_screen(x, y)
	local width, height = window.get_size()

	screen_x = screen_x * (SIZE / width)
	screen_y = screen_y * (SIZE / height)

	return screen_x, screen_y
end


return M
