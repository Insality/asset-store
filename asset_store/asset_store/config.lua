local constants = require("asset_store.asset_store.constants")


local M = {}


---Normalize and validate configuration
---@param input table Input configuration table
---@return table config Normalized configuration
function M.normalize_config(input)
	assert(type(input) == "table", "asset_store.open expects a config table")

	-- Support both single store (store_url) and multiple stores (stores array)
	if input.stores then
		-- Multiple stores mode
		assert(type(input.stores) == "table" and #input.stores > 0, "asset_store.open requires at least one store in stores array")
		return {
			stores = input.stores,
			title = input.title or constants.DEFAULT_TITLE,
		}
	else
		-- Single store mode (backward compatibility)
		assert(input.store_url, "asset_store.open requires either store_url or stores array")

		local config = {
			store_url = input.store_url,
			install_prefs_key = input.install_prefs_key,
			asset_type = input.asset_type or "folder", -- Default to "folder" if not specified
			info_url = input.info_url,
			title = input.title or constants.DEFAULT_TITLE,
			info_button_label = input.info_button_label or constants.DEFAULT_INFO_BUTTON,
			close_button_label = input.close_button_label or constants.DEFAULT_CLOSE_BUTTON,
			empty_search_message = input.empty_search_message or constants.DEFAULT_EMPTY_SEARCH_MESSAGE,
			empty_filter_message = input.empty_filter_message or constants.DEFAULT_EMPTY_FILTER_MESSAGE,
			labels = input.labels or {},
			info_action = input.info_action,
		}

		config.labels.search = config.labels.search or {}
		for key, value in pairs(constants.DEFAULT_SEARCH_LABELS) do
			if config.labels.search[key] == nil then
				config.labels.search[key] = value
			end
		end

		return config
	end
end


return M

