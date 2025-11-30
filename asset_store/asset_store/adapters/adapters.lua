local dependency_adapter = require("asset_store.asset_store.adapters.adapter_dependency")
local item_adapter = require("asset_store.asset_store.adapters.adapter_item")

local M = {}


---Get adapter for specific asset type
---@param asset_type string Asset type: "dependency" or "folder" (default)
---@return table adapter Adapter module with install, is_installed, and other methods
function M.get_adapter(asset_type)
	if asset_type == "dependency" then
		return dependency_adapter
	else
		return item_adapter
	end
end


return M

