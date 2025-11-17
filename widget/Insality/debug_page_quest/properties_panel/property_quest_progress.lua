local color = require("druid.color")

---@class druid.widget.property_quest_progress: druid.widget
---@field root node
---@field text_name druid.text
---@field progress druid.progress
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.container = self.druid:new_container(self.root)
	self.container:add_container("E_Anchor")

	--self.color_start = gui.get_color(self:get_node("progress"))
	--self.color_end = gui.get_color(self:get_node("progress_color_full"))
	--gui.set_enabled(self:get_node("progress_color_full"), false)

	self.progress = self.druid:new_progress("progress", "x")

	self.text_name = self.druid:new_text("text_name")
		:set_text_adjust("scale_then_trim", 0.3)

	self.text_progress = self.druid:new_text("text_progress")

	self.progress:set_to(0)
end


---@param text string
---@return druid.widget.property_quest_progress
function M:set_text_property(text)
	self.text_name:set_text(text)
	return self
end


---@return druid.widget.property_quest_progress
function M:set_progress(current_value, max_value)
	local progress = current_value / max_value
	progress = math.max(0, math.min(1, progress))

	--local lerp_color = color.lerp(progress, self.color_start, self.color_end)
	--color.set_color(self:get_node("progress"), lerp_color)

	self.progress:set_to(progress)
	self.text_progress:set_text(tostring(current_value) .. "/" .. tostring(max_value))

	return self
end


return M
