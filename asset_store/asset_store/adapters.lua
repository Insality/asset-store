--- Adapters module - provides installers for different asset types
--- Returns appropriate adapter based on asset type

local dependency_adapter = require("asset_store.asset_store.adapters.dependency")
local item_adapter = require("asset_store.asset_store.adapters.item")

local M = {}


---Get adapter for specific asset type
---@param asset_type string - Asset type: "dependency" or "folder" (default)
---@return table - Adapter module with install, is_installed, and other methods
function M.get_adapter(asset_type)
	if asset_type == "dependency" then
		return dependency_adapter
	else
		-- Default to item adapter for "folder" type
		return item_adapter
	end
end


return M

