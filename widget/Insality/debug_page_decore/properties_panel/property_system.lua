local color = require("druid.color")
local helper = require("druid.helper")

---@class widget.property_system: druid.widget
---@field root node
---@field text_name druid.text
local M = {}

local HASH_SIZE_X = hash("size.x")
local COLOR_HUGE = color.hex2vector4("#D59E9E")
local COLOR_LOW = color.hex2vector4("#8ED59E")

local COLOR_TEXT_LIGHT = color.hex2vector4("#212428")
local COLOR_TEXT_DARK = color.hex2vector4("#76797D")

function M:init()
	self.root = self:get_node("root")

	self.text_name = self.druid:new_text("text_name")
		:set_text_adjust("scale_then_trim", 0.3)

	self.text_memory_update = self.druid:new_text("text_memory_update")
	self.text_memory_update_fps = self.druid:new_text("text_memory_update_fps")
	self.text_memory_postwrap = self.druid:new_text("text_memory_postwrap")
	self.text_memory_postwrap_fps = self.druid:new_text("text_memory_postwrap_fps")

	self.node_update = self:get_node("node_update")
	self.node_update_fps = self:get_node("node_update_fps")
	self.node_postwrap = self:get_node("node_postwrap")
	self.node_postwrap_fps = self:get_node("node_postwrap_fps")

	self.system_last_time = 0
	self.update_limit = 1024
	self.update_time_limit = 3
	self.postwrap_limit = 1024
	self.postwrap_time_limit = 3

	self.button_inspect = self.druid:new_button("button_inspect")

	self.container = self.druid:new_container(self.root)
	self.container:add_container("text_name")
	self.container:add_container("E_Anchor")
end


function M:on_remove()
	if self.system_old_update then
		self.system.update = self.system_old_update
	end

	if self.system_old_postwrap then
		self.system.postWrap = self.system_old_postwrap
	end
end


function M:set_text(text)
	self.text_name:set_text(text)
	return self
end


---@param system system
function M:set_system(system)
	self.system = system
	self.system_old_update = system.update
	self.system_old_postwrap = system.postWrap

	self.system_memory_samples_update = {}
	self.system_memory_samples_update_fps = {}

	self.system_memory_samples_postwrap = {}
	self.system_memory_samples_postwrap_fps = {}

	self.system_last_time = 0
	self.memory_update_per_second = 0
	self.memory_postwrap_per_second = 0

	if self.system_old_update then
		system.update = function(...)
			local memory = collectgarbage("count")
			local time = socket.gettime()

			self.system_old_update(...)

			local memory_after = collectgarbage("count")
			local diff = memory_after - memory
			if diff > 0 then
				table.insert(self.system_memory_samples_update, diff)
			end

			local diff_time = socket.gettime() - time
			table.insert(self.system_memory_samples_update_fps, diff_time)
		end
	end

	if self.system_old_postwrap then
		system.postWrap = function(...)
			local memory = collectgarbage("count")
			local time = socket.gettime()

			self.system_old_postwrap(...)

			local memory_after = collectgarbage("count")
			local diff = memory_after - memory
			if diff > 0 then
				table.insert(self.system_memory_samples_postwrap, diff)
			end

			local diff_time = socket.gettime() - time
			table.insert(self.system_memory_samples_postwrap_fps, diff_time)
		end
	end

	self:update(0)
end


function M:update(dt)
	if not self.system then
		return
	end

	self.system_last_time = self.system_last_time - dt
	if self.system_last_time <= 0 then
		self.system_last_time = 1

		local update_memory = 0
		for _, v in ipairs(self.system_memory_samples_update) do
			update_memory = update_memory + v
		end

		local postwrap_memory = 0
		for _, v in ipairs(self.system_memory_samples_postwrap) do
			postwrap_memory = postwrap_memory + v
		end
		-- Update UI
		local text_update = math.ceil(update_memory) .. " KB/s"
		if update_memory > 1024 then
			text_update = string.format("%.2f", update_memory / 1024) .. " MB/s"
		end

		local text_postwrap = math.ceil(postwrap_memory) .. " KB/s"
		if postwrap_memory > 1024 then
			text_postwrap = string.format("%.2f", postwrap_memory / 1024) .. " MB/s"
		end

		self.text_memory_update:set_text(text_update)
		self.text_memory_postwrap:set_text(text_postwrap)

		-- Update graphs
		---@diagnostic disable-next-line: undefined-field
		local update_limit = self.system.DEBUG_PANEL_UPDATE_MEMORY_LIMIT or self.update_limit

		---@diagnostic disable-next-line: undefined-field
		local postwrap_limit = self.system.DEBUG_PANEL_POSTWRAP_MEMORY_LIMIT or self.postwrap_limit

		local update_perc = helper.clamp(update_memory / update_limit, 0, 1)
		local postwrap_perc = helper.clamp(postwrap_memory / postwrap_limit, 0, 1)

		gui.set(self.node_update, HASH_SIZE_X, update_perc * 80)
		gui.set(self.node_postwrap, HASH_SIZE_X, postwrap_perc * 80)

		gui.set_color(self.node_update, color.lerp(update_perc, COLOR_LOW, COLOR_HUGE))
		gui.set_color(self.node_postwrap, color.lerp(postwrap_perc, COLOR_LOW, COLOR_HUGE))

		gui.set_color(self.text_memory_update.node, color.lerp(update_perc, COLOR_TEXT_DARK, COLOR_TEXT_LIGHT))
		gui.set_color(self.text_memory_postwrap.node, color.lerp(postwrap_perc, COLOR_TEXT_DARK, COLOR_TEXT_LIGHT))

		self.system_memory_samples_update = {}
		self.system_memory_samples_postwrap = {}

		do -- Frame time update
			-- Mediana time for update
			local update_time = 0
			for _, v in ipairs(self.system_memory_samples_update_fps) do
				update_time = update_time + v
			end
			update_time = update_time / math.max(#self.system_memory_samples_update_fps, 1)
			update_time = update_time * 1000

			-- Mediana time for postwrap
			local postwrap_time = 0
			for _, v in ipairs(self.system_memory_samples_postwrap_fps) do
				postwrap_time = postwrap_time + v
			end
			postwrap_time = postwrap_time / math.max(#self.system_memory_samples_postwrap_fps, 1)
			postwrap_time = postwrap_time * 1000

			self.text_memory_update_fps:set_text( string.format("%.1f", update_time) .. " ms")
			self.text_memory_postwrap_fps:set_text( string.format("%.2f", postwrap_time) .. " ms")

			local update_time_perc = helper.clamp(update_time / self.update_time_limit, 0, 1)
			local postwrap_time_perc = helper.clamp(postwrap_time / self.postwrap_time_limit, 0, 1)

			gui.set(self.node_update_fps, HASH_SIZE_X, update_time_perc * 80)
			gui.set(self.node_postwrap_fps, HASH_SIZE_X, postwrap_time_perc * 80)

			gui.set_color(self.node_update_fps, color.lerp(update_time_perc, COLOR_LOW, COLOR_HUGE))
			gui.set_color(self.node_postwrap_fps, color.lerp(postwrap_time_perc, COLOR_LOW, COLOR_HUGE))

			gui.set_color(self.text_memory_update_fps.node, color.lerp(update_time_perc, COLOR_TEXT_DARK, COLOR_TEXT_LIGHT))
			gui.set_color(self.text_memory_postwrap_fps.node, color.lerp(postwrap_time_perc, COLOR_TEXT_DARK, COLOR_TEXT_LIGHT))

			self.system_memory_samples_update_fps = {}
			self.system_memory_samples_postwrap_fps = {}
		end
	end
end


return M
