local adapters = require("asset_store.asset_store.adapters.adapters")
local constants = require("asset_store.asset_store.constants")
local internal = require("asset_store.asset_store.asset_store_internal")
local asset_handlers = require("asset_store.asset_store.asset_handlers")
local dialog_utils = require("asset_store.asset_store.ui.store_dialog_utils")
local dialog_ui = require("asset_store.asset_store.ui.dialog")
local filters_ui = require("asset_store.asset_store.ui.filters")
local locales = require("asset_store.asset_store.locales")
local pagination_ui = require("asset_store.asset_store.ui.pagination")
local search_ui = require("asset_store.asset_store.ui.search")
local settings_ui = require("asset_store.asset_store.ui.settings")
local widget_list_ui = require("asset_store.asset_store.ui.widget_list")


local M = {}


---Create dialog component for dependencies store
---@param config table Store configuration
---@param initial_items table Initial items array
---@param initial_install_folder string|nil Initial installation folder
---@param dependencies_changed_ref table Reference to track dependencies changes
---@return function Dialog component function
function M.create_dialog_component(config, initial_items, initial_install_folder, dependencies_changed_ref)
	local filter_overrides = config.labels.filters and { labels = config.labels.filters } or nil

	-- Determine default filter type
	local default_type = dialog_utils.get_default_type(config.asset_type, initial_items, initial_install_folder)

	return editor.ui.component(function(props)
		local all_items = editor.ui.use_state(initial_items)
		local install_folder, set_install_folder = editor.ui.use_state(initial_install_folder)
		local search_query, set_search_query = editor.ui.use_state("")
		local filter_type, set_filter_type = editor.ui.use_state(default_type)
		local filter_author, set_filter_author = editor.ui.use_state(locales.get("filters_all_authors"))
		local filter_tag, set_filter_tag = editor.ui.use_state(locales.get("filters_all_tags"))
		local sort_by, set_sort_by = editor.ui.use_state(locales.get("sort_stars"))
		local install_status, set_install_status = editor.ui.use_state("")
		local current_page, set_current_page = editor.ui.use_state(1)

		local authors = editor.ui.use_memo(internal.extract_authors, all_items)
		local tags = editor.ui.use_memo(internal.extract_tags, all_items)

		local type_options = editor.ui.use_memo(filters_ui.build_type_options, filter_overrides)
		local author_options = editor.ui.use_memo(filters_ui.build_author_options, authors, filter_overrides)
		local tag_options = editor.ui.use_memo(filters_ui.build_tag_options, tags, filter_overrides)

		local asset_type = config.asset_type
		local adapter = adapters.get_adapter(asset_type)

		-- Build sort options based on asset type
		local sort_options = editor.ui.use_memo(dialog_utils.build_sort_options, asset_type)

		-- Helper function to reset page when filters change
		local function reset_page_if_needed()
			if current_page ~= 1 then
				set_current_page(1)
			end
		end

		local filtered_items = editor.ui.use_memo(
			internal.filter_items_by_filters,
			all_items,
			search_query,
			filter_type,
			filter_author,
			filter_tag,
			install_folder,
			adapter,
			sort_by,
			asset_type
		)

		-- Calculate pagination
		local total_pages = math.max(1, math.ceil(#filtered_items / constants.ITEMS_PER_PAGE))

		-- Ensure current_page is valid (in case filtered_items count decreased)
		local safe_current_page = math.min(current_page, math.max(1, total_pages))
		if safe_current_page ~= current_page then
			set_current_page(safe_current_page)
		end

		-- Slice filtered_items for current page
		local paginated_items = editor.ui.use_memo(function(items, page, per_page)
			local start_index = (page - 1) * per_page + 1
			local end_index = math.min(page * per_page, #items)

			if start_index > #items or start_index < 1 then
				return {}
			end

			local page_items = {}
			for i = start_index, end_index do
				table.insert(page_items, items[i])
			end

			return page_items
		end, filtered_items, safe_current_page, constants.ITEMS_PER_PAGE)

		local function on_install(item)
			asset_handlers.handle_install(item, install_folder, all_items, asset_type,
				function(message)
					set_install_status(locales.get("messages_success", message))
					if asset_type == "dependency" then
						dependencies_changed_ref[1] = true
					end
				end,
				function(message)
					set_install_status(locales.get("messages_error", message))
				end
			)
		end

		local function on_update(item)
			asset_handlers.handle_update(item, all_items, asset_type, install_folder,
				function(message)
					set_install_status(locales.get("messages_success", message))
					if asset_type == "dependency" then
						dependencies_changed_ref[1] = true
					end
				end,
				function(message)
					set_install_status(locales.get("messages_error", message))
				end
			)
		end

		-- Get version options from dependency content array
		local function get_version_options(item)
			return dialog_utils.get_version_options(item, asset_type, adapter, install_folder)
		end

		-- Get installed version name for asset
		local function get_installed_version_name(item)
			return dialog_utils.get_installed_version_name(item, asset_type, adapter, install_folder)
		end

		-- Handle version change (immediately update or remove dependency)
		local function on_version_change(item, selected_version_name)
			if asset_type ~= "dependency" then
				return
			end

			if selected_version_name == locales.get("actions_delete") then
				asset_handlers.handle_remove(item, asset_type,
					function(message)
						set_install_status(locales.get("messages_success", message))
						dependencies_changed_ref[1] = true
					end,
					function(message)
						set_install_status(locales.get("messages_error", message))
					end
				)
				return
			end

			local selected_url = nil
			if item.content then
				for _, url in ipairs(item.content) do
					local version_name = dialog_utils.extract_version_name_from_url(url)
					if version_name == selected_version_name then
						selected_url = url
						break
					end
				end
			end

			if not selected_url then
				set_install_status(locales.get("messages_error_could_not_find_url", selected_version_name))
				return
			end

			asset_handlers.handle_update(item, all_items, asset_type, install_folder,
				function(message)
					set_install_status(locales.get("messages_success", message))
					dependencies_changed_ref[1] = true
				end,
				function(message)
					set_install_status(locales.get("messages_error", message))
				end,
				selected_url
			)
		end

		local content_children = {}

		-- Add header component (settings)
		if config.install_prefs_key then
			table.insert(content_children, settings_ui.create({
				install_folder = install_folder,
				on_install_folder_changed = function(new_folder)
					set_install_folder(new_folder)
					editor.prefs.set(config.install_prefs_key, new_folder)
				end,
				labels = config.labels.settings
			}))
		end

		table.insert(content_children, filters_ui.create({
			filter_type = filter_type,
			filter_author = filter_author,
			filter_tag = filter_tag,
			type_options = type_options,
			author_options = author_options,
			tag_options = tag_options,
			on_type_change = function(value)
				set_filter_type(value)
				reset_page_if_needed()
			end,
			on_author_change = function(value)
				set_filter_author(value)
				reset_page_if_needed()
			end,
			on_tag_change = function(value)
				set_filter_tag(value)
				reset_page_if_needed()
			end,
			labels = config.labels and config.labels.filters,
		}))

		table.insert(content_children, search_ui.create({
			search_query = search_query,
			on_search = function(value)
				set_search_query(value)
				reset_page_if_needed()
			end,
			sort_by = sort_by,
			sort_options = sort_options,
			on_sort_change = function(value)
				set_sort_by(value)
				reset_page_if_needed()
			end,
			labels = config.labels and config.labels.search,
		}))

		if #filtered_items == 0 then
			local empty_message = config.empty_filter_message or constants.DEFAULT_EMPTY_FILTER_MESSAGE
			if search_query ~= "" then
				empty_message = string.format(config.empty_search_message or constants.DEFAULT_EMPTY_SEARCH_MESSAGE, search_query)
			end
			if filter_type == locales.get("filters_installed") then
				empty_message = constants.DEFAULT_EMPTY_INSTALLED_MESSAGE
			end
			table.insert(content_children, editor.ui.label({
				text = empty_message,
				color = editor.ui.COLOR.HINT,
				alignment = editor.ui.ALIGNMENT.CENTER
			}))
		else
			table.insert(content_children, widget_list_ui.create(paginated_items, {
				on_install = on_install,
				on_update = on_update,
				on_version_change = on_version_change,
				open_url = internal.open_url,
				is_installed = function(item)
					return adapter.is_installed(item, install_folder)
				end,
				can_update = function(item)
					local can_update_result, _ = adapter.can_update(item, install_folder)
					return can_update_result
				end,
				get_version_options = get_version_options,
				get_installed_version_name = get_installed_version_name,
				labels = config.labels and config.labels.widget_card,
			}))
		end

		-- Add pagination controls if there's more than one page
		if total_pages > 1 then
			table.insert(content_children, pagination_ui.create({
				current_page = safe_current_page,
				total_pages = total_pages,
				total_items = #filtered_items,
				items_per_page = constants.ITEMS_PER_PAGE,
				on_page_change = set_current_page
			}))
		end

		local buttons = {}

		table.insert(buttons, editor.ui.dialog_button({
			text = locales.get("support_button"),
			result = constants.SUPPORT_RESULT,
		}))

		if config.info_url then
			table.insert(buttons, editor.ui.dialog_button({
				text = config.info_button_label or constants.DEFAULT_INFO_BUTTON,
				result = constants.INFO_RESULT,
			}))
		end
		table.insert(buttons, editor.ui.dialog_button({
			text = config.close_button_label or constants.DEFAULT_CLOSE_BUTTON,
			cancel = true
		}))

		-- Build title with entity count
		local title_with_count = config.title .. " (" .. #all_items .. " entities)"

		return dialog_ui.build({
			title = title_with_count,
			children = content_children,
			buttons = buttons
		})
	end)
end


return M

