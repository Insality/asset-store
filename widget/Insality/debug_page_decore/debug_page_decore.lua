local decore = require("decore.decore")
local decore_data = require("decore.internal.decore_data")

local property_entity_prefab = require("decore.properties_panel.property_entity_prefab")
local property_system = require("decore.properties_panel.property_system")
local M = {}


---@param world world
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(world, druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Decore Panel")

	properties_panel:add_button(function(button)
		button.text_name:set_text("Entities")
		button.text_button:set_text(string.format("Inspect (%d)", #world.entities))
		button:set_color("#A1D7F5")
		button.button.on_click:subscribe(function()
			--self:select_page(PAGES.ENTITIES, self.world.entities, "Entities")
			M.render_entities_page(world, druid, properties_panel)
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Systems")
		button:set_text_button(string.format("Inspect (%d)", #world.systems))
		button:set_color("#E6DF9F")
		button.button.on_click:subscribe(function()
			--self:select_page(PAGES.SYSTEMS, self.world.systems, "Systems")
			M.render_systems_page(world, druid, properties_panel)
		end)
	end)

	properties_panel:add_button(function(button)
		button:set_text_property("Entity Prefabs")
		button:set_text_button("Open")
		button.button.on_click:subscribe(function()
			--self:select_page(PAGES.ENTITY_PREFABS, nil, "Entity Prefabs")
			M.render_entity_prefabs_page(world, druid, properties_panel)
		end)
	end)
end


---@param world world
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_entities_page(world, druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Entities")

	local entities = world.entities
	properties_panel.text_header:set_text("World Entities (" .. #entities .. ")")

	for i = 1, #entities do
		properties_panel:add_widget(function()
			local entity = entities[i]
			local entity_prefab_id = entity.prefab_id or "Entity"
			local entity_name = entity.id .. ". " .. entity_prefab_id

			local widget = druid:new_widget(property_entity_prefab, "property_entity_prefab", "root")
			widget:set_text_property(entity_name)
			widget:set_text_button("Inspect")
			widget.button.on_click:subscribe(function()
				properties_panel:next_scene()
				properties_panel:set_header(string.format("Entity %s, %s", entity.id, entity.prefab_id))
				properties_panel:render_lua_table(entity)
			end)

			widget.on_drag_start:subscribe(function()
				entity.follow_cursor = true
				entity.debug_draw_transform = true
				world:addEntity(entity)
			end)

			widget.on_drag_end:subscribe(function()
				entity.follow_cursor = nil
				entity.debug_draw_transform = nil
				world:addEntity(entity)
			end)

			widget.on_drag_hover:subscribe(function(_, is_hover)
				if is_hover then
					entity.debug_draw_transform = true
					world:addEntity(entity)
				end
				if not is_hover and not entity.follow_cursor then
					entity.debug_draw_transform = nil
					world:addEntity(entity)
				end
			end)

			return widget
		end)
	end
end


---@param world world
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_systems_page(world, druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Systems")

	local systems = world.systems
	properties_panel.text_header:set_text("World systems (" .. #systems .. ")")
	for i = 1, #systems do
		local system = systems[i]
		local system_id = system.id or "Unknown"
		local system_name = i .. ". " .. system_id .. " (" .. #system.entities .. ")"

		properties_panel:add_widget(function()
			local widget = druid:new_widget(property_system, "property_system", "root")
			widget:set_system(system)
			widget:set_text(system_name)
			widget.button_inspect.on_click:subscribe(function()
				properties_panel:next_scene()
				properties_panel:set_header(string.format("System %s", system_id))
				properties_panel:render_lua_table(system)
			end)

			return widget
		end)
	end
end


---@param world world
---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_entity_prefabs_page(world, druid, properties_panel)
	properties_panel:next_scene()
	properties_panel:set_header("Entity Prefabs")

	for _, pack_id in ipairs(decore_data.entities_order) do
		properties_panel:add_text(function(text)
			text:set_text_property("Pack id")
			text:set_text_value(pack_id)
		end)

		-- Sort
		local entities_ordered = {}
		for prefab_id in pairs(decore_data.entities[pack_id]) do
			table.insert(entities_ordered, prefab_id)
		end
		table.sort(entities_ordered, function(a, b)
			if type(a) == "number" and type(b) == "number" then
				return a < b
			end
			return tostring(a) < tostring(b)
		end)

		for i = 1, #entities_ordered do
			local prefab_id = entities_ordered[i]
			if type(prefab_id) == "string" then
				properties_panel:add_widget(function()
					local widget = druid:new_widget(property_entity_prefab, "property_entity_prefab", "root")
					widget:set_text_property(prefab_id)
					widget:set_text_button("Inspect")
					widget.button.on_click:subscribe(function()
						properties_panel:next_scene()
						properties_panel:set_header("Entity Prefab")
						properties_panel:render_lua_table(decore_data.entities[pack_id][prefab_id])
					end)

					---@type entity?
					local entity_to_create = nil
					local drag_n_drop_entity = nil

					widget.on_drag_start:subscribe(function()
						entity_to_create = decore.create_prefab(prefab_id, pack_id)
						local visual_entity_to_create = {
							game_object = entity_to_create.game_object,
							transform = entity_to_create.transform or {},
							color = entity_to_create.color,
							follow_cursor = true,
						}

						if entity_to_create.child_instancies then
							local child_instancies = {}
							for index = 1, #entity_to_create.child_instancies do
								local child = entity_to_create.child_instancies[index]
								local components = child.components
								local created_child = decore.create_prefab(child.prefab_id, child.pack_id, child.components)
								if components then
									table.insert(child_instancies, {
										game_object = created_child.game_object,
										transform = created_child.transform,
										color = created_child.color,
									})
								end
							end
							visual_entity_to_create.child_instancies = child_instancies
						end

						drag_n_drop_entity = decore.create_prefab(nil, nil, visual_entity_to_create)
						world:addEntity(drag_n_drop_entity)
					end)

					widget.on_drag_end:subscribe(function()
						if not entity_to_create or not drag_n_drop_entity then
							return

						end

						drag_n_drop_entity.game_object.remove_delay = nil
						entity_to_create.transform = drag_n_drop_entity.transform

						world:removeEntity(drag_n_drop_entity)
						world:addEntity(entity_to_create)

						entity_to_create = nil
						drag_n_drop_entity = nil
					end)

					return widget
				end)
			end
		end
	end
end


return M
