---@class widget.log_panel: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")

	self.scroll = self.druid:new_scroll("view", "content")
	self.grid = self.druid:new_grid("content", "prefab")
	self.data_list = self.druid:new_data_list(self.scroll, self.grid, self.create_element)
end


function M:create_element(data)
	print("Create")
end


function M:add_message(text)

end


function M:clear()

end


return M
