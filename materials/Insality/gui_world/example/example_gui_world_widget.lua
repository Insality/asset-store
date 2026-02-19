---@class widget.example_gui_world: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.progress = self.druid:new_progress("progress_fill", "x")
	self.text_progress = self.druid:new_text("text_progress")

	self.button = self.druid:new_button("root", self.on_click)
end


---@private
function M:on_click()
	gui.set(self.progress.node, "color.w", 2)
	gui.animate(self.progress.node, "color.w", 1, gui.EASING_OUTSINE, 0.5)
end


---@param progress number [0-1]
function M:set_progress(progress)
	self.progress:set_to(progress)

	local hp = math.ceil(progress * 100)
	self.text_progress:set_text(tostring(hp))
end


---Currently we need to call set position to adjust it from the script module
---@param position vector3
function M:set_position(position)
	gui.set_position(self.root, position)
end


---Currently we need to call set scale to adjust it from the script module
---@param scale vector3
function M:set_scale(scale)
	gui.set_scale(self.root, scale)
end


return M
