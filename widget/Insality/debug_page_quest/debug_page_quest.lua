local quest = require("quest.quest")
local utils = require("quest.internal.quest_utils")
local property_quest_progress = require("quest.properties_panel.property_quest_progress")

local M = {}


---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Quest Panel")

	-- Statistics
	properties_panel:add_text(function(text)
		text:set_text_property("Total Quests")
		text:set_text_value(tostring(quest.get_quests_count()))
	end)

	-- Active quests
	properties_panel:add_button(function(button)
		local current_quests = quest.get_current()
		local current_count = utils.count_table_entries(current_quests)
		button:set_text_property("Active Quests")
		button:set_text_button("View (" .. current_count .. ")")
		button.button.on_click:subscribe(function()
			M.render_active_quests_page(druid, properties_panel)
		end)
	end)

	-- Completed quests
	properties_panel:add_button(function(button)
		local completed_quests = quest.get_completed()
		local completed_count = utils.count_table_entries(completed_quests)
		button:set_text_property("Completed Quests")
		button:set_text_button("View (" .. completed_count .. ")")
		button.button.on_click:subscribe(function()
			M.render_completed_quests_page(druid, properties_panel)
		end)
	end)

	-- Available quests
	properties_panel:add_button(function(button)
		local can_be_started = quest.get_can_be_started()
		button:set_text_property("Ready to start Quests")
		button:set_text_button("View (" .. #can_be_started .. ")")
		button.button.on_click:subscribe(function()
			M.render_available_quests_page(druid, properties_panel)
		end)
	end)

	-- All quests
	properties_panel:add_button(function(button)
		button:set_text_property("All Quests")
		button:set_text_button("View (" .. utils.count_table_entries(quest.get_quests_data()) .. ")")
		button.button.on_click:subscribe(function()
			M.render_all_quests_page(druid, properties_panel)
		end)
	end)

	-- Quest Events
	properties_panel:add_button(function(button)
		button:set_text_property("Quest Events")
		button:set_text_button("View")
		button.button.on_click:subscribe(function()
			M.render_quest_events_page(druid, properties_panel)
		end)
	end)

	-- Reset Quests
	properties_panel:add_button(function(button)
		button:set_text_property("Reset Quests")
		button:set_text_button("Reset")
		button.button.on_click:subscribe(function()
			quest.clear_all_progress()
			properties_panel:set_dirty()
		end)
	end)
end


---Render the active quests page
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_active_quests_page(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Active Quests")

	local current_quests = quest.get_current()
	if utils.count_table_entries(current_quests) == 0 then
		properties_panel:add_text(function(text)
			text:set_text_property("Info")
			text:set_text_value("No active quests")
		end)
		return
	end

	for quest_id, quest_progress in pairs(current_quests) do
		properties_panel:add_button_small(function(button)
			button:set_text_property(quest_id)
			button.button.on_click:subscribe(function()
				M.render_quest_details_page(druid, quest_id, properties_panel)
			end)
		end)
	end
end


---Render the quests page
---@param druid druid.instance
---@param quests table<string, any>
---@param properties_panel druid.widget.properties_panel
function M.add_render_quests(druid, quests, properties_panel)
	local sorted_quests = {}
	for quest_id, _ in pairs(quests) do
		table.insert(sorted_quests, quest_id)
	end
	table.sort(sorted_quests)

	for _, quest_id in ipairs(sorted_quests) do
		properties_panel:add_button(function(button)
			button:set_text_property(quest_id)
			button.button.on_click:subscribe(function()
				M.render_quest_details_page(druid, quest_id, properties_panel)
			end)
		end)
	end
end


---Render the completed quests page
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_completed_quests_page(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Completed Quests")
	M.add_render_quests(druid, quest.get_completed(), properties_panel)
end


---Render the available quests page
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_available_quests_page(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Available Quests")
	M.add_render_quests(druid, quest.get_can_be_started(), properties_panel)
end


---Render the all quests page
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_all_quests_page(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("All Quests")
	M.add_render_quests(druid, quest.get_quests_data(), properties_panel)
end


---Render the quest events page
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_quest_events_page(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Quest Events")

	-- Gather all available actions in quests
	local actions = {}
	for quest_id, quest_config in pairs(quest.get_quests_data()) do
		for _, task in ipairs(quest_config.tasks) do
			actions[task.action] = true
		end
	end

	local sorted_actions = {}
	for action in pairs(actions) do
		table.insert(sorted_actions, action)
	end
	table.sort(sorted_actions)

	for _, action in ipairs(sorted_actions) do
		properties_panel:add_button(function(button)
			button:set_text_property(action)
			button:set_text_button("Trigger")
			button.button.on_click:subscribe(function()
				M.render_quest_event_page(druid, action, properties_panel)
			end)
		end)
	end
end


---Render the quest event page
---@param druid druid.instance
---@param action string
---@param properties_panel druid.widget.properties_panel
function M.render_quest_event_page(druid, action, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Quest Event: " .. action)

	local object = ""
	local amount = 1

	properties_panel:add_input(function(input)
		input:set_text_property("Object")
		input:set_text_value("")
		input.on_change_value:subscribe(function(value)
			object = value
		end)
	end)

	properties_panel:add_input(function(input)
		input:set_text_property("Amount")
		input:set_text_value(amount or 1)
		input.on_change_value:subscribe(function(value)
			amount = value
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Trigger")
		button.button.on_click:subscribe(function()
			quest.event(action, object, amount)
			properties_panel:set_dirty()
		end)
	end)
end


---Get the quest status text
---@param quest quest
---@param quest_id string
---@return string
function M.get_quest_status(quest, quest_id)
	if quest.is_completed(quest_id) then
		return "Completed"
	elseif quest.is_active(quest_id) then
		return "Active"
	elseif quest.is_can_start_quest(quest_id) then
		return "Available"
	else
		return "Locked"
	end
end


---Render the details page for a specific quest
---@param druid druid.instance
---@param quest_id string
---@param properties_panel druid.widget.properties_panel
function M.render_quest_details_page(druid, quest_id, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Quest: " .. quest_id)

	local quest_config = quest.get_quest_config(quest_id)
	if not quest_config then
		properties_panel:add_text(function(text)
			text:set_text_property("Error")
			text:set_text_value("Quest config not found")
		end)
		return
	end

	properties_panel:add_text(function(text)
		text:set_text_property("Category")
		text:set_text_value(quest_config.category or "None")
	end)

	properties_panel:add_text(function(text)
		text:set_text_property("Status")
		text:set_text_value(M.get_quest_status(quest, quest_id))
	end)

	properties_panel:add_checkbox(function(checkbox)
		checkbox:set_text_property("Repeatable")
		checkbox:set_value(quest_config.repeatable or false)
		checkbox:set_enabled(false)
	end)

	properties_panel:add_checkbox(function(checkbox)
		checkbox:set_text_property("Autostart")
		checkbox:set_value(quest_config.autostart or false)
		checkbox:set_enabled(false)
	end)

	properties_panel:add_checkbox(function(checkbox)
		checkbox:set_text_property("Autofinish")
		checkbox:set_value(quest_config.autofinish or false)
		checkbox:set_enabled(false)
	end)

	properties_panel:add_checkbox(function(checkbox)
		checkbox:set_text_property("Events Always")
		checkbox:set_value(quest_config.events_offline or false)
		checkbox:set_enabled(false)
	end)

	-- Required quests
	local required_quests = quest_config.required_quests
	if type(required_quests) == "string" then
		required_quests = { required_quests }
	end

	if required_quests and #required_quests > 0 then
		properties_panel:add_text(function(text)
			text:set_text_property("Required Quests")
			text:set_text_value(table.concat(required_quests, ", "))
		end)
	end

	-- Tasks
	properties_panel:add_widget(function()
		local quest_progress = druid:new_widget(property_quest_progress, "property_quest_progress", "root")
		quest_progress:set_text_property("Tasks")

		local tasks = quest_config.tasks
		local tasks_count = utils.count_table_entries(tasks)
		local tasks_completed = 0

		for task_index, task in ipairs(tasks) do
			local task_progress = quest.get_task_progress(quest_id, task_index)
			if task_progress >= (task.required or 1) then
				tasks_completed = tasks_completed + 1
			end
		end

		quest_progress:set_progress(tasks_completed, tasks_count)

		return quest_progress
	end)

	for task_index, task in ipairs(quest_config.tasks) do
		properties_panel:add_widget(function()
			local quest_progress = druid:new_widget(property_quest_progress, "property_quest_progress", "root")

			local task_text = task.action or ""
			if task.object then
				task_text = task_text .. " " .. task.object
			end

			quest_progress:set_text_property(task_text)

			local task_progress = quest.get_task_progress(quest_id, task_index)
			local required = task.required or 1
			quest_progress:set_progress(task_progress, required)

			return quest_progress
		end)
		properties_panel:add_button(function(button)
			button:set_text_property("Add Progress")
			button:set_text_button("+ 1 (hold to 50%)")
			button.button.on_click:subscribe(function()
				quest.add_task_progress(quest_id, task_index, 1)
				properties_panel:set_dirty()
			end)
			button.button.on_long_click:subscribe(function()
				local required = task.required or 1
				quest.add_task_progress(quest_id, task_index, math.floor(required * 0.5))
				properties_panel:set_dirty()
			end)
		end)
	end

	-- Actions
	properties_panel:add_button(function(button)
		button:set_text_property("Action")
		button:set_text_button("Start Quest")
		button.button.on_click:subscribe(function()
			quest.start_quest(quest_id)
			properties_panel:set_dirty()
		end)
		button:set_enabled(quest.is_can_start_quest(quest_id))
	end)

	-- Complete quest button
	properties_panel:add_button(function(button)
		button:set_text_property("Action")
		button:set_text_button("Complete Quest")
		button.button.on_click:subscribe(function()
			quest.complete_quest(quest_id)
			properties_panel:set_dirty()
		end)
		button:set_enabled(quest.is_can_complete_quest(quest_id))
	end)

		-- Force complete button
	properties_panel:add_button(function(button)
		button:set_text_property("Action")
		button:set_text_button("Force Complete")
		button.button.on_click:subscribe(function()
			quest.force_complete_quest(quest_id)
			properties_panel:set_dirty()
		end)
		button:set_enabled(quest.is_active(quest_id))
	end)

	-- Reset progress button
	properties_panel:add_button(function(button)
		button:set_text_property("Action")
		button:set_text_button("Reset Progress")
		button.button.on_click:subscribe(function()
			quest.reset_progress(quest_id)
			properties_panel:set_dirty()
		end)
		button:set_enabled(quest.is_active(quest_id))
	end)

	-- Restart quest button
	properties_panel:add_button(function(button)
		button:set_text_property("Action")
		button:set_text_button("Restart Quest")
		button.button.on_click:subscribe(function()
			quest.reset_quest(quest_id)
			properties_panel:set_dirty()
		end)
	end)
end


return M

