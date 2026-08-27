local adapters = require("asset_store.asset_store.adapters.adapters")
local locales = require("asset_store.asset_store.locales")
local update_confirmation_ui = require("asset_store.asset_store.ui.update_confirmation")
local version_utils = require("asset_store.asset_store.version_utils")


---Report assets that require a newer Defold than the one we run
---@param item table - Asset item
---@param on_error function - Error callback
---@return boolean is_blocked True if the asset cannot be used at all
local function reject_unsupported(item, on_error)
	if version_utils.has_supported_version(item) then
		return false
	end

	local message = locales.get("messages_no_compatible_version", version_utils.get_editor_version() or "?")
	print("Asset requires a newer Defold:", item.id, message)
	on_error(message)

	return true
end


local M = {}


---Handle asset installation (widget or dependency)
---@param item table - Asset item to install
---@param install_folder string - Installation folder (for folder type assets)
---@param all_items table - List of all items for dependency resolution
---@param asset_type string - Type of asset: "folder" or "dependency"
---@param on_success function - Success callback
---@param on_error function - Error callback
---@param source_folder string|nil - Store source folder for path replacement (folder-type only)
function M.handle_install(item, install_folder, all_items, asset_type, on_success, on_error, source_folder)
	local adapter = adapters.get_adapter(asset_type)

	if reject_unsupported(item, on_error) then
		return
	end

	print("Installing " .. asset_type .. ":", item.id)

	local success, message = adapter.install(item, install_folder, all_items, nil, source_folder)

	if success then
		print("Installation successful:", message)
		on_success(message)
	else
		print("Installation failed:", message)
		on_error(message)
	end
end


---Handle asset update
---@param item table - Asset item to update
---@param all_items table - List of all items for dependency resolution
---@param asset_type string - Type of asset: "folder" or "dependency"
---@param install_folder string|nil - Install folder (for folder type assets)
---@param on_success function - Success callback
---@param on_error function - Error callback
---@param new_url string|nil - Optional URL to update to (if nil, uses latest from can_update)
function M.handle_update(item, all_items, asset_type, install_folder, on_success, on_error, new_url)
	local adapter = adapters.get_adapter(asset_type)

	if reject_unsupported(item, on_error) then
		return
	end

	-- For widgets (folder type), show confirmation dialog
	if asset_type == "folder" then
		-- Get installed version for display
		local installed_version = nil
		if install_folder and adapter.get_installed_version then
			installed_version = adapter.get_installed_version(item, install_folder)
		end

		-- Create item copy with installed version for dialog
		local item_with_version = {}
		for k, v in pairs(item) do
			item_with_version[k] = v
		end
		item_with_version.installed_version = installed_version

		-- Show confirmation dialog
		update_confirmation_ui.show(item_with_version,
			function()
				-- User confirmed, proceed with update
				print("Updating " .. asset_type .. ":", item.id)
				local success, message = adapter.update(item, install_folder, all_items)
				if success then
					print("Update successful:", message)
					on_success(message)
				else
					print("Update failed:", message)
					on_error(message)
				end
			end,
			function()
				-- User cancelled
				on_error(locales.get("messages_update_cancelled"))
			end
		)
		return
	end

	-- For dependencies, use existing logic
	-- If new_url is provided, use it directly; otherwise check can_update
	if not new_url then
		local can_update_result, latest_url = adapter.can_update(item)
		if not can_update_result or not latest_url then
			on_error(locales.get("messages_cannot_update", item.id))
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
function M.handle_remove(item, asset_type, on_success, on_error)
	local adapter = adapters.get_adapter(asset_type)

	if not adapter.remove_dependency then
		on_error(locales.get("messages_remove_not_supported", asset_type))
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


return M

