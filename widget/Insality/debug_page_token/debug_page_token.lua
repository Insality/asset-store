local token = require("token.token")

local M = {}


---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Token Panel")

	-- Show containers
	properties_panel:add_text(function(text)
		local containers = token.get_state().containers
		text:set_text_property("Container Count")
		text:set_text_value(tostring(M.token_count_containers(containers)))
	end)

	for container_id, container in pairs(token.get_state().containers) do
		properties_panel:add_button(function(button)
			local token_count = M.token_count_tokens(container.tokens)
			button:set_text_property(container_id)
			button:set_text_button("Inspect (" .. token_count .. ")")
			button.button.on_click:subscribe(function()
				M.render_container_page(token, container_id, properties_panel)
			end)
		end)
	end
end


---Count the number of containers
---@param containers table<string, token.container_data>
---@return number
function M.token_count_containers(containers)
	local count = 0
	for _ in pairs(containers) do
		count = count + 1
	end
	return count
end


---Count the number of tokens in a container
---@param tokens table<string, number>
---@return number
function M.token_count_tokens(tokens)
	local count = 0
	for _ in pairs(tokens) do
		count = count + 1
	end
	return count
end


---Render a specific container page
---@param token token
---@param container_id string
---@param properties_panel druid.widget.properties_panel
function M.render_container_page(token, container_id, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Container: " .. container_id)

	-- Container actions
	properties_panel:add_button(function(button)
		button:set_text_property("Container")
		button:set_text_button("Clear")
		button.button.on_click:subscribe(function()
			token.clear_container(container_id)
			properties_panel:set_dirty()
		end)
	end)

	local container = token.get_state().containers[container_id]
	-- Show tokens
	if container.tokens then
		properties_panel:add_text(function(text)
			text:set_text_property("Tokens")
			text:set_text_value("")
		end)

		for token_id, _ in pairs(container.tokens) do
			-- Token actions
			properties_panel:add_button(function(button)
				local amount = token.container(container_id):get(token_id, 0)
				button:set_text_property(token_id)
				button:set_text_button(amount)
				button.button.on_click:subscribe(function()
					local token_container = token.container(container_id)
					M.render_token_details_page(token_container, token_id, properties_panel)
				end)
			end)
		end
	end
end


---Render the details page for a specific token
---@param container token.container
---@param token_id string
---@param properties_panel druid.widget.properties_panel
function M.render_token_details_page(container, token_id, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Token: " .. token_id)

	-- Amount
	properties_panel:add_input(function(input)
		local amount = container:get(token_id, 0)
		input:set_text_property("Amount")
		input:set_text_value(tostring(amount))
		input.on_change_value:subscribe(function(value)
			local new_amount = tonumber(value) or 0
			container:set(token_id, new_amount, "debug")
			properties_panel:set_dirty()
		end)
	end)

	-- Visual amount
	properties_panel:add_text(function(text)
		local visual_amount = container:get_visual(token_id)
		text:set_text_property("Visual Amount")
		text:set_text_value(tostring(visual_amount))
	end)

	-- Sync visual
	properties_panel:add_button(function(button)
		button:set_text_property("Visual")
		button:set_text_button("Sync")
		button.button.on_click:subscribe(function()
			container:sync_visual(token_id)
			properties_panel:set_dirty()
		end)
	end)

	-- Total sum
	properties_panel:add_text(function(text)
		local total_sum = container:get_total_sum(token_id)
		text:set_text_property("Total Acquired")
		text:set_text_value(tostring(total_sum))
	end)

	-- Infinity time
	properties_panel:add_text(function(text)
		local infinity_time = container:get_infinity_time(token_id)
		text:set_text_property("Infinity Time")
		text:set_text_value(tostring(infinity_time) .. " sec")
	end)

	-- Add infinity time
	properties_panel:add_input(function(input)
		input:set_text_property("Add Infinity")
		input.rich_input:set_placeholder("+ Seconds")
		input:set_text_value("")
		input.on_change_value:subscribe(function(value)
			local time = tonumber(value) or 0
			if time > 0 then
				container:add_infinity_time(token_id, time)
				properties_panel:set_dirty()
			end
			input:set_text_value("")
		end)
	end)

	-- Add token
	properties_panel:add_button(function(button)
		button:set_text_property("Add")
		button:set_text_button("+1")
		button.button.on_click:subscribe(function()
			container:add(token_id, 1, "debug")
			properties_panel:set_dirty()
		end)
	end)

	-- Pay token
	properties_panel:add_button(function(button)
		button:set_text_property("Pay")
		button:set_text_button("-1")
		button.button.on_click:subscribe(function()
			container:pay(token_id, 1, "debug")
			properties_panel:set_dirty()
		end)
	end)
end


return M
