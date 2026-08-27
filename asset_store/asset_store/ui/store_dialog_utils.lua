local adapters = require("asset_store.asset_store.adapters.adapters")
local locales = require("asset_store.asset_store.locales")
local version_utils = require("asset_store.asset_store.version_utils")


local M = {}


---Extract version name from URL
---@param url string|nil URL to extract version from
---@return string|nil version_name Version name or nil
function M.extract_version_name_from_url(url)
	return version_utils.extract_version_name_from_url(url)
end


---Build a label for a version option
---@param option table Version option
---@return string label Text shown in the version select box
function M.get_version_option_label(option)
	if not option then
		return ""
	end

	if option.min_version and not option.supported then
		return option.name .. locales.get("widget_card_version_needs", option.min_version)
	end

	return option.name
end


---Get version options from dependency content array
---@param item table Asset item
---@param asset_type string Type of asset: "folder" or "dependency"
---@param adapter table Adapter instance
---@param install_folder string|nil Installation folder
---@return table|nil options Array of version options or nil
---@note Every option is a table: { name, url, min_version, supported, is_delete }
function M.get_version_options(item, asset_type, adapter, install_folder)
	if asset_type ~= "dependency" or not item.content or type(item.content) ~= "table" then
		return nil
	end
	local options = {}
	for _, url in ipairs(item.content) do
		local version_name = M.extract_version_name_from_url(url)
		if version_name then
			table.insert(options, {
				name = version_name,
				url = url,
				min_version = version_utils.get_min_version(item, version_name),
				supported = version_utils.is_supported(item, version_name)
			})
		end
	end

	if adapter.is_installed(item, install_folder) then
		table.insert(options, {
			name = locales.get("actions_delete"),
			supported = true,
			is_delete = true
		})
	end

	return #options > 0 and options or nil
end


---Get installed version name for asset
---@param item table Asset item
---@param asset_type string Type of asset: "folder" or "dependency"
---@param adapter table Adapter instance
---@param install_folder string|nil Installation folder
---@return string|nil version_name Installed version name or nil
function M.get_installed_version_name(item, asset_type, adapter, install_folder)
	if asset_type == "dependency" then
		local installed_url = adapter.get_installed_version_url(item)
		if not installed_url then
			return nil
		end
		return M.extract_version_name_from_url(installed_url)
	elseif asset_type == "folder" then
		if install_folder and adapter.get_installed_version then
			return adapter.get_installed_version(item, install_folder)
		end
		return nil
	end
	return nil
end


---Determine default filter type based on asset type and installed items
---@param asset_type string Type of asset: "folder" or "dependency"
---@param items table Array of items
---@param install_folder string|nil Installation folder
---@return string default_type Default filter type (localized "All")
function M.get_default_type(asset_type, items, install_folder)
	return locales.get("filters_all_types")
end


---Build sort options based on asset type
---@param asset_type string Type of asset: "folder" or "dependency"
---@return table options Array of sort option strings
function M.build_sort_options(asset_type)
	local options = {locales.get("sort_asset_name"), locales.get("sort_author")}
	if asset_type == "dependency" then
		table.insert(options, locales.get("sort_stars"))
	elseif asset_type == "folder" then
		table.insert(options, locales.get("sort_size"))
	end
	return options
end


return M

