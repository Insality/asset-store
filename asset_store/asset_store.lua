local adapters = require("asset_store.asset_store.adapters.adapters")
local internal = require("asset_store.asset_store.asset_store_internal")
local dialog_ui = require("asset_store.asset_store.ui.dialog")
local filters_ui = require("asset_store.asset_store.ui.filters")
local search_ui = require("asset_store.asset_store.ui.search")
local settings_ui = require("asset_store.asset_store.ui.settings")
local widget_list_ui = require("asset_store.asset_store.ui.widget_list")

---@class asset_store.config
---@field title string The title of the asset store displayed in the dialog window
---@field store_url string The URL of the asset store JSON file containing items list
---@field install_prefs_key string The preferences key used to store and retrieve the installation folder path
---@field asset_type string? The type of assets in this store: "folder" (default) or "dependency"
---@field info_url string? The URL of the info page, if nil then info button will be hidden
---@field info_button_label string? The label text for the info button (default: "Info")
---@field close_button_label string? The label text for the close button (default: "Close")
---@field add_asset_url string? The URL to open when "Add Asset" button is clicked (if nil, button will be hidden)
---@field add_asset_button_label string? The label text for the add asset button (auto-determined by asset_type if not provided)
---@field empty_search_message string? The message format to show when no items match search query (default: "No items found matching '%s'.")
---@field empty_filter_message string? The message to show when no items match current filters (default: "No items found matching the current filters.")
---@field labels table Table containing UI label overrides for different sections
---@field labels.search table? Overrides for search UI labels (search_label, search_title, search_tooltip)
---@field labels.filters table? Overrides for filter UI labels (type_label, author_label, tag_label, all_types, installed, not_installed, all_authors, all_tags)
---@field labels.widget_card table? Overrides for widget card labels (install_button, api_button, example_button, author_caption, installed_tag, tags_prefix, depends_prefix, size_separator, unknown_size)
---@field labels.settings table? Overrides for settings UI labels (install_label, install_title, install_tooltip)

---@class asset_store.item
---@field id string Unique identifier for the asset item
---@field version string Version string of the asset (e.g., "1.0", "2.3.1")
---@field title string Display name of the asset
---@field author string Author name of the asset
---@field description string Detailed description of the asset functionality
---@field api string? URL to API documentation for the asset
---@field author_url string? URL to author's profile or website
---@field image string? URL to the preview image for the asset
---@field manifest_url string URL to the asset's manifest JSON file
---@field zip_url string URL to download the asset as a ZIP file
---@field json_zip_url string URL to download the asset as base64-encoded JSON with file list
---@field sha256 string SHA256 hash of the ZIP file for integrity verification
---@field size number Size of the ZIP file in bytes
---@field depends string[] Array of dependency strings (format: "author:widget_id@version" or "author@widget_id" or "widget_id")
---@field tags string[] Array of tag strings for categorization and filtering


local M = {}

local INFO_RESULT = "asset_store_open_info"
local SUPPORT_RESULT = "asset_store_open_support"
local ADD_ASSET_RESULT = "asset_store_open_add_asset"
local DEFAULT_TITLE = "Asset Store"
local DEFAULT_INFO_BUTTON = "Info"
local DEFAULT_CLOSE_BUTTON = "Close"
local DEFAULT_ADD_ASSET_BUTTON_LABEL = "Add Asset"
local DEFAULT_EMPTY_SEARCH_MESSAGE = "No items found matching '%s'."
local DEFAULT_EMPTY_FILTER_MESSAGE = "No items found matching the current filters."
local DEFAULT_SEARCH_LABELS = {
	search_tooltip = "Search by title, author, or description"
}


local function normalize_config(input)
	assert(type(input) == "table", "asset_store.open expects a config table")
	assert(input.store_url, "asset_store.open requires a store_url")

	local config = {
		store_url = input.store_url,
		install_prefs_key = input.install_prefs_key,
		asset_type = input.asset_type or "folder", -- Default to "folder" if not specified
		info_url = input.info_url,
		title = input.title or DEFAULT_TITLE,
		info_button_label = input.info_button_label or DEFAULT_INFO_BUTTON,
		close_button_label = input.close_button_label or DEFAULT_CLOSE_BUTTON,
		add_asset_url = input.add_asset_url,
		add_asset_button_label = input.add_asset_button_label,
		empty_search_message = input.empty_search_message or DEFAULT_EMPTY_SEARCH_MESSAGE,
		empty_filter_message = input.empty_filter_message or DEFAULT_EMPTY_FILTER_MESSAGE,
		labels = input.labels or {},
		info_action = input.info_action,
	}

	config.labels.search = config.labels.search or {}
	for key, value in pairs(DEFAULT_SEARCH_LABELS) do
		if config.labels.search[key] == nil then
			config.labels.search[key] = value
		end
	end

	return config
end


---Handle asset installation (widget or dependency)
---@param item table - Asset item to install
---@param install_folder string - Installation folder (for folder type assets)
---@param all_items table - List of all items for dependency resolution
---@param asset_type string - Type of asset: "folder" or "dependency"
---@param on_success function - Success callback
---@param on_error function - Error callback
local function handle_install(item, install_folder, all_items, asset_type, on_success, on_error)
	local adapter = adapters.get_adapter(asset_type)

	print("Installing " .. asset_type .. ":", item.id)

	local success, message = adapter.install(item, install_folder, all_items)

	if success then
		print("Installation successful:", message)
		on_success(message)
	else
		print("Installation failed:", message)
		on_error(message)
	end
end


---Handle asset update (dependency only)
---@param item table - Dependency item to update
---@param all_items table - List of all items for dependency resolution
---@param asset_type string - Type of asset: "folder" or "dependency"
---@param on_success function - Success callback
---@param on_error function - Error callback
---@param new_url string|nil - Optional URL to update to (if nil, uses latest from can_update)
local function handle_update(item, all_items, asset_type, on_success, on_error, new_url)
	local adapter = adapters.get_adapter(asset_type)

	-- If new_url is provided, use it directly; otherwise check can_update
	if not new_url then
		local can_update_result, latest_url = adapter.can_update(item)
		if not can_update_result or not latest_url then
			on_error("Cannot update: " .. item.id)
			return
		end
		new_url = latest_url
	end

	print("Updating " .. asset_type .. ":", item.id)
	local success, message = adapter.update(item, new_url)
	if success then
		print("Update successful:", message)
		on_success(message)
	else
		print("Update failed:", message)
		on_error(message)
	end
end


---Handle asset removal (dependency only)
---@param item table - Dependency item to remove
---@param asset_type string - Type of asset: "folder" or "dependency"
---@param on_success function - Success callback
---@param on_error function - Error callback
local function handle_remove(item, asset_type, on_success, on_error)
	local adapter = adapters.get_adapter(asset_type)

	if not adapter.remove_dependency then
		on_error("Remove not supported for asset type: " .. asset_type)
		return
	end

	print("Removing " .. asset_type .. ":", item.id)
	local success, message = adapter.remove_dependency(item)
	if success then
		print("Removal successful:", message)
		on_success(message)
	else
		print("Removal failed:", message)
		on_error(message)
	end
end


function M.open(config_input)
	local config = normalize_config(config_input)

	print("Opening " .. config.title .. " from:", config.store_url)

	local store_data, fetch_error = internal.download_json(config.store_url)
	if not store_data then
		print("Failed to load store items:", fetch_error)
		return
	end
	print("Successfully loaded", #store_data.items, "items")

	local initial_items = store_data.items
	local initial_install_folder = config.install_prefs_key and editor.prefs.get(config.install_prefs_key) or nil
	local filter_overrides = config.labels.filters and { labels = config.labels.filters } or nil

	-- Track if dependencies were changed during dialog session
	local dependencies_changed = false

	local dialog_component = editor.ui.component(function(props)
		local all_items = editor.ui.use_state(initial_items)
		local install_folder, set_install_folder = editor.ui.use_state(initial_install_folder)
		local search_query, set_search_query = editor.ui.use_state("")
		local filter_type, set_filter_type = editor.ui.use_state("All")
		local filter_author, set_filter_author = editor.ui.use_state("All Authors")
		local filter_tag, set_filter_tag = editor.ui.use_state("All Tags")
		local sort_by, set_sort_by = editor.ui.use_state("Stars")
		local install_status, set_install_status = editor.ui.use_state("")

		local authors = editor.ui.use_memo(internal.extract_authors, all_items)
		local tags = editor.ui.use_memo(internal.extract_tags, all_items)

		local type_options = editor.ui.use_memo(filters_ui.build_type_options, filter_overrides)
		local author_options = editor.ui.use_memo(filters_ui.build_author_options, authors, filter_overrides)
		local tag_options = editor.ui.use_memo(filters_ui.build_tag_options, tags, filter_overrides)

		local adapter = adapters.get_adapter(config.asset_type)

		-- Build sort options based on asset type
		local sort_options = editor.ui.use_memo(function(asset_type)
			--local options = {"Popularity", "Asset Name", "Author"}
			local options = {"Asset Name", "Author"}
			if asset_type == "dependency" then
				table.insert(options, "Stars")
			elseif asset_type == "folder" then
				table.insert(options, "Size")
			end
			return options
		end, config.asset_type)

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
			config.asset_type
		)

		local function on_install(item)
			handle_install(item, install_folder, all_items, config.asset_type,
				function(message)
					set_install_status("Success: " .. message)
					-- Track changes for dependency type assets
					if config.asset_type == "dependency" then
						dependencies_changed = true
					end
				end,
				function(message)
					set_install_status("Error: " .. message)
				end
			)
		end

		local function on_update(item)
			handle_update(item, all_items, config.asset_type,
				function(message)
					set_install_status("Success: " .. message)
					-- Track changes for dependency type assets
					if config.asset_type == "dependency" then
						dependencies_changed = true
					end
				end,
				function(message)
					set_install_status("Error: " .. message)
				end
			)
		end

		-- Extract version name from URL (helper function)
		local function extract_version_name_from_url(url)
			if not url or type(url) ~= "string" then
				return nil
			end
			local path = url:match("^([^%?]+)")
			if not path then
				return nil
			end
			local filename = path:match("([^/]+)/?$")
			if not filename then
				return nil
			end
			local version_name = filename:match("^(.+)%.zip$")
			if version_name then
				return version_name
			end
			return filename
		end

		-- Get version options from dependency content array
		local function get_version_options(item)
			if config.asset_type ~= "dependency" or not item.content or type(item.content) ~= "table" then
				return nil
			end
			local options = {}
			for _, url in ipairs(item.content) do
				local version_name = extract_version_name_from_url(url)
				if version_name then
					table.insert(options, version_name)
				end
			end

			-- Add "delete" option if dependency is installed
			if adapter.is_installed(item, install_folder) then
				table.insert(options, "delete")
			end

			return #options > 0 and options or nil
		end

		-- Get installed version name for dependency
		local function get_installed_version_name(item)
			if config.asset_type ~= "dependency" then
				return nil
			end
			local installed_url = adapter.get_installed_version_url(item)
			if not installed_url then
				return nil
			end
			return extract_version_name_from_url(installed_url)
		end

		-- Handle version change (immediately update or remove dependency)
		local function on_version_change(item, selected_version_name)
			if config.asset_type ~= "dependency" then
				return
			end

			-- Check if "delete" was selected
			if selected_version_name == "delete" then
				handle_remove(item, config.asset_type,
					function(message)
						set_install_status("Success: " .. message)
						-- Track changes for dependency type assets
						dependencies_changed = true
					end,
					function(message)
						set_install_status("Error: " .. message)
					end
				)
				return
			end

			-- Find the URL corresponding to the selected version
			local selected_url = nil
			if item.content then
				for _, url in ipairs(item.content) do
					local version_name = extract_version_name_from_url(url)
					if version_name == selected_version_name then
						selected_url = url
						break
					end
				end
			end

			if not selected_url then
				set_install_status("Error: Could not find URL for version: " .. selected_version_name)
				return
			end

			handle_update(item, all_items, config.asset_type,
				function(message)
					set_install_status("Success: " .. message)
					-- Track changes for dependency type assets
					dependencies_changed = true
				end,
				function(message)
					set_install_status("Error: " .. message)
				end,
				selected_url
			)
		end

		local content_children = {}

		-- Only show installation folder settings for folder type assets
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
			on_type_change = set_filter_type,
			on_author_change = set_filter_author,
			on_tag_change = set_filter_tag,
			labels = config.labels.filters,
		}))

		table.insert(content_children, search_ui.create({
			search_query = search_query,
			on_search = set_search_query,
			sort_by = sort_by,
			sort_options = sort_options,
			on_sort_change = set_sort_by,
			labels = config.labels.search,
		}))

		if #filtered_items == 0 then
			local message = config.empty_filter_message
			if search_query ~= "" then
				message = string.format(config.empty_search_message, search_query)
			end
			table.insert(content_children, editor.ui.label({
				text = message,
				color = editor.ui.COLOR.HINT,
				alignment = editor.ui.ALIGNMENT.CENTER
			}))
		else
			table.insert(content_children, widget_list_ui.create(filtered_items, {
				on_install = on_install,
				on_update = on_update,
				on_version_change = on_version_change,
				open_url = internal.open_url,
				is_installed = function(item)
					return adapter.is_installed(item, install_folder)
				end,
				can_update = function(item)
					local can_update_result, _ = adapter.can_update(item)
					return can_update_result
				end,
				get_version_options = get_version_options,
				get_installed_version_name = get_installed_version_name,
				labels = config.labels.widget_card,
			}))
		end

		local buttons = {}

		-- Add "Add Asset" button if URL is provided
		if config.add_asset_url then
			table.insert(buttons, editor.ui.dialog_button({
				text = config.add_asset_button_label or DEFAULT_ADD_ASSET_BUTTON_LABEL,
				result = ADD_ASSET_RESULT,
			}))
		end

		-- Add support button
		table.insert(buttons, editor.ui.dialog_button({
			text = "Support",
			result = SUPPORT_RESULT,
		}))

		if config.info_url then
			table.insert(buttons, editor.ui.dialog_button({
				text = config.info_button_label,
				result = INFO_RESULT,
			}))
		end
		table.insert(buttons, editor.ui.dialog_button({
			text = config.close_button_label,
			cancel = true
		}))

		return dialog_ui.build({
			title = config.title,
			children = content_children,
			buttons = buttons
		})
	end)

	local result = editor.ui.show_dialog(dialog_component({}))

	-- If dependencies were changed, call fetch-libraries via HTTP API
	if dependencies_changed and config.asset_type == "dependency" then
		print("Asset Store: Dependencies were changed, calling fetch-libraries...")
		internal.call_editor_command("fetch-libraries")
	end

	if result then
		if result == INFO_RESULT then
			if config.info_url then
				internal.open_url(config.info_url)
			end
		elseif result == SUPPORT_RESULT then
			internal.open_url("https://github.com/sponsors/insality")
		elseif result == ADD_ASSET_RESULT then
			internal.open_url(config.add_asset_url)
		end
	end

	return {}
end


return M
