local locales = require("asset_store.asset_store.locales")


local M = {}


---@class store_selector.params
---@field current_store_config table Current store configuration
---@field store_options table Array of store names for dropdown
---@field on_store_change function Callback when store changes
---@field loading_store boolean Whether store is loading
---@field install_folder string|nil Current installation folder
---@field on_install_folder_changed function Callback when installation folder changes
---@field install_prefs_key string|nil Preferences key for installation folder
---@field labels table|nil Label overrides


---Create store selector component with installation folder in one line
---@param params store_selector.params Parameters for the component
---@return userdata component UI component
function M.create(params)
	local store_folder_children = {
		editor.ui.label({
			text = locales.get("store_selector_store_label"),
			color = editor.ui.COLOR.TEXT
		}),
		editor.ui.select_box({
			value = params.current_store_config.name,
			options = params.store_options,
			on_value_changed = params.on_store_change,
			enabled = not params.loading_store
		})
	}

	-- Add installation folder if available
	if params.install_prefs_key then
		local labels = {}
		if params.labels and params.labels.settings then
			labels = params.labels.settings
		end
		local install_label = labels.install_label or locales.get("settings_install_label")

		table.insert(store_folder_children, editor.ui.label({
			text = install_label,
			color = editor.ui.COLOR.TEXT
		}))
		table.insert(store_folder_children, editor.ui.string_field({
			value = params.install_folder or "",
			on_value_changed = params.on_install_folder_changed,
			title = labels.install_title or locales.get("settings_install_title"),
			tooltip = labels.install_tooltip or locales.get("settings_install_tooltip"),
			grow = true
		}))
	end

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.MEDIUM,
		children = store_folder_children
	})
end


return M

