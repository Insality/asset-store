local en = require("asset_store.asset_store.locales.en")


local M = {}


-- Current locale (can be changed to support multiple languages)
local current_locale = en


---Get localized string
---@param key string Key (e.g., "filters_type_label" or "messages_loading")
---@param ... any Format arguments (for string.format)
---@return string localized Localized string
function M.get(key, ...)
	local value = current_locale[key]
	
	if type(value) == "string" then
		if select("#", ...) > 0 then
			return string.format(value, ...)
		end
		return value
	end
	
	return key -- Return key if value not found or not a string
end


---Set locale
---@param locale table Locale table
function M.set_locale(locale)
	current_locale = locale
end


---Get current locale
---@return table locale Current locale table
function M.get_locale()
	return current_locale
end


return M
