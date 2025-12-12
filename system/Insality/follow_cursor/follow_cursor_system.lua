local decore = require("decore.decore")

---@class entity
---@field follow_cursor boolean|nil

---@class entity.follow_cursor: entity
---@field follow_cursor boolean
decore.register_component("follow_cursor", false)

---@class system.follow_cursor: system
---@field entities entity.follow_cursor[]
local M = {}


---@return system.follow_cursor
function M.create()
	return decore.system(M, "follow_cursor", { "follow_cursor", "transform" })
end


function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input, self)
end


---@param action action
function M:process_input(action)
	if #self.entities == 0 then
		return
	end

	local x, y = self.world.camera:screen_to_world(action.screen_x, action.screen_y)
	for index = 1, #self.entities do
		local entity = self.entities[index]
		self.world.transform:set_position(entity, x, y)
	end
end


return M
