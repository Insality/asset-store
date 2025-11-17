--- Adapter for dependency type assets
--- Handles dependency installation to game.project
--- Adds dependency URLs to game.project file instead of copying files
local internal = require("asset_store.asset_store.asset_store_internal")

local M = {}


---Get dependencies from game.project using editor API
---@return table|nil - Array of dependency URLs or nil
local function get_dependencies()
	local dependencies = editor.get("/game.project", "project.dependencies")
	if dependencies and type(dependencies) == "table" then
		return dependencies
	end
	return {}
end


---Set dependencies in game.project using editor API
---@param dependencies table - Array of dependency URLs
---@return boolean - Success status
local function set_dependencies(dependencies)
	if not dependencies or type(dependencies) ~= "table" then
		return false
	end

	editor.transact({
		editor.tx.set("/game.project", "project.dependencies", dependencies)
	})

	return true
end


---Extract repository identifier from URL (e.g., "Insality/druid" from GitHub URL)
---@param url string - Dependency URL
---@return string|nil - Repository identifier or nil
local function extract_repo_id(url)
	if not url or type(url) ~= "string" then
		return nil
	end

	-- Match GitHub URLs: https://github.com/owner/repo/archive/...
	local owner, repo = url:match("github%.com/([^/]+)/([^/]+)/")
	if owner and repo then
		return owner .. "/" .. repo
	end

	return nil
end


---Extract version number from URL (e.g., "12" from "tags/12.zip" or "1.1.6" from "tags/1.1.6.zip")
---@param url string - Dependency URL
---@return string|nil - Version string or nil
local function extract_version_from_url(url)
	if not url or type(url) ~= "string" then
		return nil
	end

	-- Match patterns like: tags/12.zip, tags/1.1.6.zip, refs/tags/12.zip, etc.
	local version = url:match("tags/([^/]+)%.zip")
	if version then
		return version
	end

	-- Try to match version in other patterns
	version = url:match("refs/tags/([^/]+)%.zip")
	if version then
		return version
	end

	return nil
end


---Compare two version strings (simple numeric comparison)
---@param v1 string - First version
---@param v2 string - Second version
---@return number - Negative if v1 < v2, positive if v1 > v2, 0 if equal
local function compare_versions(v1, v2)
	if not v1 or not v2 then
		return 0
	end

	-- Try to parse as numbers first (for simple versions like "12", "13")
	local n1, n2 = tonumber(v1), tonumber(v2)
	if n1 and n2 then
		return n1 - n2
	end

	-- For semantic versions like "1.1.6", do string comparison
	-- This is a simple approach - for more complex cases might need proper semver parsing
	return v1 < v2 and -1 or (v1 > v2 and 1 or 0)
end


---Add a dependency URL to game.project
---@param url string - Dependency URL to add
---@return boolean - Success status
local function add_to_game_project(url)
	if not url or url == "" then
		return false
	end

	local dependencies = get_dependencies()
	if not dependencies then
		dependencies = {}
	end

	-- Extract repository identifier from the URL we want to add
	local url_repo_id = extract_repo_id(url)

	-- Check if repository already exists (by comparing repo IDs, not exact URLs)
	if url_repo_id then
		for _, existing_url in ipairs(dependencies) do
			if type(existing_url) == "string" then
				local existing_repo_id = extract_repo_id(existing_url)
				if existing_repo_id == url_repo_id then
					print("Dependency repository already exists in game.project:", url_repo_id, "(existing:", existing_url .. ", new:", url .. ")")
					return true
				end
			end
		end
	end

	-- Also check for exact URL match (for backwards compatibility)
	for _, existing_url in ipairs(dependencies) do
		if existing_url == url then
			print("Dependency URL already exists in game.project:", url)
			return true
		end
	end

	-- Add the dependency
	table.insert(dependencies, url)
	print("Adding dependency to game.project:", url)

	return set_dependencies(dependencies)
end


---Find dependency by dependency string (format: "author:dependency_id" or "author@dependency_id" or "dependency_id")
---@param dep_string string - Dependency string
---@param all_items table - List of all available dependencies
---@return table|nil - Found dependency item or nil
local function find_dependency_by_string(dep_string, all_items)
	if not dep_string or not all_items then
		return nil
	end

	local author, dep_id

	-- Try format: "author:dependency_id" (e.g., "Insality:defold-event")
	author, dep_id = dep_string:match("^([^:]+):([^@]+)$")
	if not author then
		-- Try format: "author@dependency_id" (e.g., "insality@defold-event")
		author, dep_id = dep_string:match("^([^@]+)@(.+)$")
		if not author then
			-- No author specified, search by dependency_id only
			dep_id = dep_string
		end
	end

	for _, item in ipairs(all_items) do
		if item.id == dep_id then
			-- If author was specified, check it matches (case-insensitive)
			if not author or string.lower(item.author or "") == string.lower(author) then
				return item
			end
		end
	end

	return nil
end


---Install dependency dependencies recursively
---@param item table - Dependency item
---@param all_items table - List of all available dependencies
---@param installing_set table - Set of dependency IDs currently being installed (to prevent cycles)
---@return boolean, string|nil - Success status and message
local function install_dependency_dependencies(item, all_items, installing_set)
	if not item.depends or #item.depends == 0 then
		return true, nil
	end

	installing_set = installing_set or {}

	for _, dep_string in ipairs(item.depends) do
		local dep_item = find_dependency_by_string(dep_string, all_items)
		if not dep_item then
			print("Warning: Dependency not found:", dep_string)
			-- Continue with other dependencies
		else
			-- Check if already installed
			if M.is_installed(dep_item) then
				print("Dependency already installed:", dep_item.id)
			else
				-- Check for circular dependencies
				if installing_set[dep_item.id] then
					print("Warning: Circular dependency detected:", dep_item.id)
					-- Continue with other dependencies
				else
					print("Installing dependency:", dep_item.id)
					local success, err = M.install(dep_item, nil, all_items, installing_set)
					if not success then
						return false, "Failed to install dependency " .. dep_item.id .. ": " .. (err or "unknown error")
					end
				end
			end
		end
	end

	return true, nil
end


---Install a dependency by adding URLs from content array to game.project
---@param item table - Dependency item with content array containing URLs
---@param install_folder string|nil - Not used for dependencies, kept for interface compatibility
---@param all_items table|nil - Optional list of all items for dependency resolution
---@param installing_set table|nil - Optional set of dependency IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
function M.install(item, install_folder, all_items, installing_set)
	return M.install_dependency(item, all_items, installing_set)
end


---Install a dependency by adding URLs from content array to game.project
---@param item table - Dependency item with content array containing URLs
---@param all_items table|nil - Optional list of all items for dependency resolution
---@param installing_set table|nil - Optional set of dependency IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
function M.install_dependency(item, all_items, installing_set)
	if not item.content or type(item.content) ~= "table" or #item.content == 0 then
		return false, "Invalid dependency data: missing content array"
	end

	if not item.id then
		return false, "Invalid dependency data: missing id"
	end

	-- Install dependencies first if all_items is provided
	if all_items then
		installing_set = installing_set or {}
		if installing_set[item.id] then
			return false, "Circular dependency detected: " .. item.id
		end
		installing_set[item.id] = true
		local dep_success, dep_err = install_dependency_dependencies(item, all_items, installing_set)
		if not dep_success then
			installing_set[item.id] = nil
			return false, dep_err or "Failed to install dependencies"
		end
	end

	-- Use the latest version (last element in content array, sorted by date ascending)
	local latest_url = M.get_latest_version_url(item)
	if not latest_url or latest_url == "" then
		if installing_set then
			installing_set[item.id] = nil
		end
		return false, "No valid dependency URL found in content array"
	end

	-- Add only the latest version URL to game.project
	local success = add_to_game_project(latest_url)
	if not success then
		if installing_set then
			installing_set[item.id] = nil
		end
		return false, "Failed to add dependency URL to game.project: " .. latest_url
	end

	if installing_set then
		installing_set[item.id] = nil
	end

	internal.track_download(item, "dependency")

	return true, "Dependency installed successfully"
end


---Get currently installed version URL for a dependency
---@param item table - Dependency item with content array
---@return string|nil - Currently installed URL or nil
function M.get_installed_version_url(item)
	if not item.content or type(item.content) ~= "table" or #item.content == 0 then
		return nil
	end

	local dependencies = get_dependencies()
	if not dependencies or #dependencies == 0 then
		return nil
	end

	-- Extract repository identifiers from content URLs
	local content_repos = {}
	for _, url in ipairs(item.content) do
		if type(url) == "string" and url ~= "" then
			local repo_id = extract_repo_id(url)
			if repo_id then
				content_repos[repo_id] = true
			end
		end
	end

	-- Find the installed URL for this repository
	for _, existing_url in ipairs(dependencies) do
		if type(existing_url) == "string" then
			local existing_repo_id = extract_repo_id(existing_url)
			if existing_repo_id and content_repos[existing_repo_id] then
				return existing_url
			end
		end
	end

	return nil
end


---Get the latest version URL from content array
---@param item table - Dependency item with content array
---@return string|nil - Latest version URL or nil
---@note The last element in content array is always the latest version (sorted by date ascending)
function M.get_latest_version_url(item)
	if not item.content or type(item.content) ~= "table" or #item.content == 0 then
		return nil
	end

	-- Last element in content array is always the latest version (sorted by date ascending)
	return item.content[#item.content]
end


---Check if a dependency can be updated
---@param item table - Dependency item with content array
---@return boolean, string|nil - True if can be updated, and new version URL if available
function M.can_update(item)
	return M.can_update_dependency(item)
end


---Check if a dependency can be updated (legacy method name, use can_update instead)
---@param item table - Dependency item with content array
---@return boolean, string|nil - True if can be updated, and new version URL if available
function M.can_update_dependency(item)
	local installed_url = M.get_installed_version_url(item)
	if not installed_url then
		return false, nil
	end

	local latest_url = M.get_latest_version_url(item)
	if not latest_url then
		return false, nil
	end

	-- If URLs are the same, no update needed
	if installed_url == latest_url then
		return false, nil
	end

	local installed_version = extract_version_from_url(installed_url)
	local latest_version = extract_version_from_url(latest_url)

	-- If we can't extract versions, compare URLs directly
	if not installed_version or not latest_version then
		return installed_url ~= latest_url, latest_url
	end

	-- Check if latest version is newer
	return compare_versions(latest_version, installed_version) > 0, latest_url
end


---Check if a dependency is already installed by checking if repository from content exists in game.project
---@param item table - Dependency item with content array
---@return boolean - True if dependency is installed
function M.is_installed(item, _)
	return M.get_installed_version_url(item) ~= nil
end


---Check if a dependency is already installed (legacy method name, use is_installed instead)
---@param item table - Dependency item with content array
---@return boolean - True if dependency is installed
function M.is_dependency_installed(item)
	return M.is_installed(item)
end


---Update a dependency by replacing old URL with new URL in game.project
---@param item table - Dependency item with content array
---@param new_url string|nil - New URL to replace old one with (if nil, uses latest from content)
---@return boolean, string - Success status and message
function M.update(item, new_url)
	if not new_url then
		local can_update_result, latest_url = M.can_update(item)
		if not can_update_result or not latest_url then
			return false, "Cannot determine update URL"
		end
		new_url = latest_url
	end
	return M.update_dependency(item, new_url)
end


---Update a dependency by replacing old URL with new URL in game.project
---@param item table - Dependency item with content array
---@param new_url string - New URL to replace old one with
---@return boolean, string - Success status and message
function M.update_dependency(item, new_url)
	if not new_url or new_url == "" then
		return false, "Invalid URL for update"
	end

	local installed_url = M.get_installed_version_url(item)
	if not installed_url then
		return false, "Dependency is not installed"
	end

	local dependencies = get_dependencies()
	if not dependencies then
		return false, "Failed to read game.project dependencies"
	end

	-- Find and replace the old URL with new URL
	local found = false
	for idx, existing_url in ipairs(dependencies) do
		if existing_url == installed_url then
			dependencies[idx] = new_url
			found = true
			print("Updating dependency in game.project:", installed_url, "->", new_url, "at index", idx)
			break
		end
	end

	if not found then
		return false, "Could not find installed dependency URL in game.project"
	end

	local success = set_dependencies(dependencies)
	if success then
		return true, "Dependency updated successfully"
	else
		return false, "Failed to update game.project"
	end
end


return M

