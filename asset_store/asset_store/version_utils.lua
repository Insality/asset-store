--- Defold version requirements for assets
--- Assets can declare a minimum Defold version they need. Dependencies declare it per
--- version in the `min_versions` map, folder assets in the `defold_min_version` field.
--- When the requirement is not met, the editor refuses to fetch the library, so the store
--- should not offer such versions in the first place.

local M = {}


---Extract version name from URL
---@param url string|nil URL to extract version from
---@return string|nil version_name Version name or nil
function M.extract_version_name_from_url(url)
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


---Get the Defold version of the running editor
---@return string|nil version Version string (e.g. "1.13.1") or nil if unknown
function M.get_editor_version()
	local is_ok, version = pcall(function()
		return editor.version
	end)

	if is_ok and type(version) == "string" and version ~= "" then
		return version
	end

	return nil
end


---Split version string into numeric components
---@param version string Version string
---@return table components Array of numbers
local function split_version(version)
	local components = {}
	for part in version:gmatch("[^%.]+") do
		table.insert(components, tonumber(part:match("%d+")) or 0)
	end

	return components
end


---Compare two version strings
---Mirrors the comparison Bob does for `defold_min_version`: components are compared
---numerically, missing components count as zero.
---@param version_a string First version
---@param version_b string Second version
---@return number result Negative if a < b, positive if a > b, 0 if equal
function M.compare(version_a, version_b)
	local a = split_version(version_a)
	local b = split_version(version_b)
	local count = math.max(#a, #b)

	for index = 1, count do
		local diff = (a[index] or 0) - (b[index] or 0)
		if diff ~= 0 then
			return diff
		end
	end

	return 0
end


---Get minimum Defold version required by an asset version
---@param item table Asset item
---@param version_name string|nil Version name (for dependencies)
---@return string|nil min_version Required Defold version or nil if there is no requirement
function M.get_min_version(item, version_name)
	if not item then
		return nil
	end

	if version_name and type(item.min_versions) == "table" then
		local min_version = item.min_versions[version_name]
		if type(min_version) == "string" and min_version ~= "" then
			return min_version
		end
	end

	if type(item.defold_min_version) == "string" and item.defold_min_version ~= "" then
		return item.defold_min_version
	end

	return nil
end


---Check if an asset version can be used with the current editor
---@param item table Asset item
---@param version_name string|nil Version name (for dependencies)
---@return boolean is_supported True if there is no requirement or it is satisfied
function M.is_supported(item, version_name)
	local min_version = M.get_min_version(item, version_name)
	if not min_version then
		return true
	end

	local editor_version = M.get_editor_version()
	if not editor_version then
		-- Older editors do not expose their version, so nothing can be checked
		return true
	end

	return M.compare(editor_version, min_version) >= 0
end


---Check if an URL from the content array can be used with the current editor
---@param item table Dependency item
---@param url string Content URL
---@return boolean is_supported True if the version behind the URL can be used
function M.is_url_supported(item, url)
	return M.is_supported(item, M.extract_version_name_from_url(url))
end


---Get the latest content URL that can be used with the current editor
---@param item table Dependency item with content array
---@return string|nil url Latest supported URL or nil if every version requires a newer editor
function M.get_latest_supported_url(item)
	if not item or not item.content or type(item.content) ~= "table" then
		return nil
	end

	-- Content is sorted by date ascending, so walk it backwards to find the newest match
	for index = #item.content, 1, -1 do
		local url = item.content[index]
		if type(url) == "string" and url ~= "" and M.is_url_supported(item, url) then
			return url
		end
	end

	return nil
end


---Get info about the newest version the current editor cannot use
---@param item table Asset item
---@return string|nil version_name Blocked version name or nil if the newest version is usable
---@return string|nil min_version Defold version required by it
function M.get_blocked_version_info(item)
	if not item then
		return nil, nil
	end

	local has_content = item.content and type(item.content) == "table" and #item.content > 0
	if not has_content then
		-- Folder assets ship a single version
		if not M.is_supported(item, item.version) then
			return item.version, M.get_min_version(item, item.version)
		end
		return nil, nil
	end

	local version_name = M.extract_version_name_from_url(item.content[#item.content])
	if not M.is_supported(item, version_name) then
		return version_name, M.get_min_version(item, version_name)
	end

	return nil, nil
end


---Get the lowest Defold version that makes any version of the asset usable
---@param item table Asset item
---@return string|nil min_version Lowest requirement across all versions, or nil if there is none
---@note Only meaningful when every version is blocked: a version without a requirement
---@note is usable by any editor, so there would be nothing to report
function M.get_lowest_requirement(item)
	if not item then
		return nil
	end

	local has_content = item.content and type(item.content) == "table" and #item.content > 0
	if not has_content then
		return M.get_min_version(item, item.version)
	end

	local lowest = nil
	for _, url in ipairs(item.content) do
		local min_version = M.get_min_version(item, M.extract_version_name_from_url(url))
		if not min_version then
			-- This version has no requirement at all, so nothing blocks the asset
			return nil
		end
		if not lowest or M.compare(min_version, lowest) < 0 then
			lowest = min_version
		end
	end

	return lowest
end


---Check if an asset has any version that can be installed with the current editor
---@param item table Asset item
---@return boolean can_install True if at least one version is usable
function M.has_supported_version(item)
	if not item then
		return false
	end

	local has_content = item.content and type(item.content) == "table" and #item.content > 0
	if not has_content then
		return M.is_supported(item, item.version)
	end

	return M.get_latest_supported_url(item) ~= nil
end


return M
