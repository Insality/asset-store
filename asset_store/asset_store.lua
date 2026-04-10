local constants = require("asset_store.asset_store.constants")
local config_module = require("asset_store.asset_store.config")
local internal = require("asset_store.asset_store.asset_store_internal")
local store_dialog_assets = require("asset_store.asset_store.ui.store_dialog_assets")
local store_dialog_dependencies = require("asset_store.asset_store.ui.store_dialog_dependencies")
local settings_window = require("asset_store.asset_store.ui.settings_window")


local M = {}


---Open asset store dialog
---@param config_input table Configuration table (see asset_store.config)
---@return table|nil result Result table or nil
function M.open(config_input)
	local config = config_module.normalize_config(config_input)

	-- Handle multiple stores mode
	if config.stores then
		return M.open_multiple_stores(config)
	end

	return M.open_single_store(config)
end


---Open dialog for multiple stores
---@param config table Configuration table with stores array
---@return table|nil result Result table or nil on error
function M.open_multiple_stores(config)
	local stores = config.stores
	local default_store = stores[1]
	local last_selected_name = editor.prefs.get("asset_store.last_selected_store")
	if last_selected_name then
		for _, store in ipairs(stores) do
			if store.name == last_selected_name then
				default_store = store
				break
			end
		end
	end

	-- Load initial store data
	local store_data, fetch_error = internal.download_json(default_store.store_url)
	if not store_data then
		print("Failed to load store items:", fetch_error)
		return
	end
	print("Successfully loaded", #store_data.items, "items from:", default_store.name)

	local initial_items = store_data.items
	local initial_store_config = default_store
	local initial_install_folder = default_store.install_prefs_key and editor.prefs.get(default_store.install_prefs_key) or nil

	-- Track if dependencies were changed during dialog session
	local dependencies_changed = { false }
	local last_selected_store_config = { initial_store_config }

	local dialog_component = store_dialog_assets.create_dialog_component(
		stores,
		initial_store_config,
		initial_items,
		initial_install_folder,
		config,
		dependencies_changed,
		last_selected_store_config
	)
	local result = editor.ui.show_dialog(dialog_component({}))

	-- If dependencies were changed, call fetch-libraries via HTTP API
	if dependencies_changed[1] then
		internal.call_editor_command("fetch-libraries")
		editor.save()
	end

	if result then
		if result == constants.SETTINGS_RESULT then
			settings_window.open()
			return M.open_multiple_stores(config)
		elseif result == constants.INFO_RESULT then
			if last_selected_store_config[1] and last_selected_store_config[1].info_url then
				internal.open_url(last_selected_store_config[1].info_url)
			end
		elseif result == constants.SUPPORT_RESULT then
			internal.open_url("https://github.com/sponsors/insality")
		end
	end

	return {}
end


---Open dialog for single store
---@param config table Configuration table (see asset_store.config)
---@return table|nil result Result table or nil on error
function M.open_single_store(config)
	print("Opening " .. config.title .. " from:", config.store_url)

	local store_data, fetch_error = internal.download_json(config.store_url)
	if not store_data then
		print("Failed to load store items:", fetch_error)
		return
	end
	print("Successfully loaded", #store_data.items, "items")

	local initial_items = store_data.items
	local initial_install_folder = config.install_prefs_key and editor.prefs.get(config.install_prefs_key) or nil

	-- Track if dependencies were changed during dialog session
	local dependencies_changed = { false }

	local dialog_component = store_dialog_dependencies.create_dialog_component(
		config,
		initial_items,
		initial_install_folder,
		dependencies_changed
	)
	local result = editor.ui.show_dialog(dialog_component({}))

	-- If dependencies were changed, call fetch-libraries via HTTP API
	if dependencies_changed[1] and config.asset_type == "dependency" then
		internal.call_editor_command("fetch-libraries")
		editor.save()
	end

	if result then
		if result == constants.SETTINGS_RESULT then
			settings_window.open()
			return M.open_single_store(config)
		elseif result == constants.INFO_RESULT then
			if config.info_url then
				internal.open_url(config.info_url)
			end
		elseif result == constants.SUPPORT_RESULT then
			internal.open_url("https://github.com/sponsors/insality")
		end
	end

	return {}
end


return M
