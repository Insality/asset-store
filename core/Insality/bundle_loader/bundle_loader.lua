--- File Loader Module
--- Provides promise-based API for loading files from bundle resources
--- Works cross-platform with HTML5 using HTTP requests with caching
--- and native platforms using direct file I/O
---
--- Usage Examples:
---
--- -- Load a bundle resource
--- file_loader.load("/bundle/common/data.txt"):next(function(content)
---     print("File content:", content)
--- end):catch(function(err)
---     print("Error:", err)
--- end)
---
--- -- Load arbitrary project file, which is not in the bundle
--- file_loader.load("/loader.collection", { raw_path = true }):next(function(content)
---     print("Data:", content)
--- end)
---

local promise = require("event.promise")

---@class file_loader
local M = {}

local project_folder = nil
local bundle_resources_path = nil


---Get the bundle resources path from game.project
---@return string bundle_path The bundle resources path (e.g., "/bundle")
local function get_bundle_resources_path()
	if bundle_resources_path then
		return bundle_resources_path
	end

	-- Read from game.project
	local config_path = sys.get_config_string("project.bundle_resources")
	if config_path and config_path ~= "" then
		bundle_resources_path = config_path
		return bundle_resources_path
	end

	-- Default fallback
	bundle_resources_path = "/bundle"
	return bundle_resources_path
end


---Get current project folder (only desktop, for development mode)
---@return string|nil project_folder Current project folder, nil if failed
local function get_project_folder()
	if project_folder then
		return project_folder
	end

	if not io.popen or html5 then
		return nil
	end

	local file = io.popen("pwd")
	if not file then
		return nil
	end

	local pwd = file:read("*l")
	file:close()

	if not pwd then
		return nil
	end

	-- Check the game.project file exists in this folder
	local game_project_path = pwd .. "/game.project"
	local game_project_file = io.open(game_project_path, "r")
	if not game_project_file then
		return nil
	end

	game_project_file:close()
	return pwd
end


---Convert bundle path to cache file path for HTML5
---@param bundle_path string
---@return string cache_path
local function get_cache_path(bundle_path)
	local sanitized = bundle_path:gsub("[^a-zA-Z0-9_.-]", "_")
	local project_title = sys.get_config_string("project.title")
	return sys.get_save_file(project_title, sanitized)
end


---Load file from absolute file path using io.open
---@param absolute_path string
---@return string|nil content File content or nil if failed
---@return string|nil error Error message if failed
local function load_from_file_path(absolute_path)
	local file, err = io.open(absolute_path, "rb")
	if not file then
		return nil, "Failed to open file: " .. (err or "unknown error")
	end

	local content = file:read("*a")
	file:close()

	if not content then
		return nil, "Failed to read file content"
	end

	return content
end


---Load file from bundle for native platforms
---@param bundle_path string Full path from project root (e.g., "/bundle/common/example.json")
---@param is_bundle_resource boolean Whether this is a bundle resource
---@param is_raw_path boolean Whether to skip path transformations
---@return promise promise_instance Resolves with file content string
local function load_native(bundle_path, is_bundle_resource, is_raw_path)
	local content, err
	local bundle_prefix = get_bundle_resources_path()

	-- Try development mode first: load from project directory
	local proj_folder = get_project_folder()
	if proj_folder then
		local dev_path = proj_folder .. bundle_path
		content, err = load_from_file_path(dev_path)
		if content then
			return promise.resolved(content)
		end
	end

	-- Production mode
	local prod_path

	if is_raw_path then
		-- No transformation, use path as-is
		prod_path = sys.get_application_path() .. bundle_path
	elseif is_bundle_resource then
		-- Strip bundle prefix since resources are flattened
		-- /bundle/common/file.json -> /common/file.json
		prod_path = bundle_path:gsub("^" .. bundle_prefix, "")
		prod_path = sys.get_application_path() .. prod_path
	else
		-- Non-bundle resource in production - file doesn't exist
		return promise.rejected("File not available in production build (not a bundle resource): " .. bundle_path)
	end

	content, err = load_from_file_path(prod_path)

	if content then
		return promise.resolved(content)
	else
		return promise.rejected(err or ("Failed to load file: " .. bundle_path))
	end
end


---Load file from bundle for HTML5 platform with caching
---@param bundle_path string Full path from project root (e.g., "/bundle/common/example.json")
---@param ignore_cache boolean
---@param is_bundle_resource boolean Whether this is a bundle resource
---@param is_raw_path boolean Whether to skip path transformations
---@return promise promise_instance Resolves with file content string
local function load_html5(bundle_path, ignore_cache, is_bundle_resource, is_raw_path)
	local cache_path = get_cache_path(bundle_path)
	local bundle_prefix = get_bundle_resources_path()

	-- Try to load from cache first if not ignoring cache
	if not ignore_cache then
		local cached_content = load_from_file_path(cache_path)
		if cached_content then
			return promise.resolved(cached_content)
		end
	end

	-- Determine URL path based on options
	local url_path

	if is_raw_path then
		-- No transformation, use path as-is (ensure leading slash)
		url_path = bundle_path:sub(1, 1) == "/" and bundle_path:sub(2) or bundle_path
	elseif is_bundle_resource then
		-- Strip bundle prefix AND platform folder
		-- /bundle/common/file.json -> file.json
		-- Pattern: /bundle/<platform>/<rest> -> <rest>
		url_path = bundle_path:gsub("^" .. bundle_prefix .. "/[^/]+/", "")
	else
		-- Non-bundle resource in production - file doesn't exist
		return promise.rejected("File not available in HTML5 build (not a bundle resource): " .. bundle_path)
	end

	-- Cache miss or ignored, download from server
	local result_promise = promise.create()
	local url = sys.get_application_path() .. "/" .. url_path

	http.request(url, "GET", function(self, id, response)
		if response.status == 200 or response.status == 304 then
			-- File was downloaded and saved to cache_path automatically
			local content = load_from_file_path(cache_path)
			if content then
				result_promise:resolve(content)
			else
				result_promise:reject("Failed to read downloaded file from cache: " .. bundle_path)
			end
		else
			result_promise:reject("HTTP error " .. response.status .. " loading file: " .. bundle_path)
		end
	end, nil, nil, { path = cache_path })

	return result_promise
end


---Load a file from bundle resources
---Returns a promise that resolves with the file content as a string
---@param path string Full path from project root (e.g., "/bundle/common/data.txt")
---@param options table|nil Optional table with: ignore_cache (boolean), raw_path (boolean)
---@return promise promise Resolves with file content string
function M.load(path, options)
	options = options or {}
	local ignore_cache = options.ignore_cache or false
	local raw_path = options.raw_path or false
	local bundle_prefix = get_bundle_resources_path()

	-- Check if this is a bundle resource
	local is_bundle_resource = path:match("^" .. bundle_prefix .. "/") ~= nil

	-- Auto-prefix with bundle path if not raw_path and not already prefixed
	if not raw_path and not is_bundle_resource then
		if path:sub(1, 1) == "/" then
			path = bundle_prefix .. path
		else
			path = bundle_prefix .. "/" .. path
		end
		is_bundle_resource = true
	end

	if html5 then
		return load_html5(path, ignore_cache, is_bundle_resource, raw_path)
	else
		return load_native(path, is_bundle_resource, raw_path)
	end
end


---Load and parse a JSON file from bundle resources
---Returns a promise that resolves with the parsed JSON as a Lua table
---@param path string Full path from project root (e.g., "/bundle/common/data.json")
---@param options table|nil Optional table with: ignore_cache (boolean)
---@return promise promise_instance Resolves with parsed JSON table
function M.load_json(path, options)
	return M.load(path, options):next(function(content)
		local success, result = pcall(json.decode, content)
		if success then
			return result
		else
			return promise.rejected("Failed to parse JSON from file: " .. path .. " - " .. tostring(result))
		end
	end)
end


---Get cached file content if available (HTML5 only)
---@param path string Relative path from bundle folder
---@return string|nil content File content or nil if not cached
function M.get_cached(path)
	if not html5 then
		return nil
	end

	local cache_path = get_cache_path(path)
	local content = load_from_file_path(cache_path)
	return content
end


---Load a file with callback-based interface (wraps promise-based load)
---@param path string Full path from project root (e.g., "/bundle/common/data.txt")
---@param on_success function Callback with signature: on_success(content)
---@param on_error function Callback with signature: on_error(error)
---@param options table|nil Optional table with: ignore_cache (boolean), raw_path (boolean)
function M.load_with_callback(path, on_success, on_error, options)
	M.load(path, options):next(function(content)
		on_success(content)
	end):catch(function(err)
		on_error(err)
	end)
end


return M
