--- Adapter for folder/item type assets
--- Handles widget installation from zip files
--- Downloads zip files and extracts them to the specified folder

local base64 = require("asset_store.asset_store.base64")
local path_replacer = require("asset_store.asset_store.path_replacer")
local internal = require("asset_store.asset_store.asset_store_internal")

local M = {}


---URL encode a string (percent encoding)
---@param str string - String to encode
---@return string - URL encoded string
local function url_encode(str)
	local result = {}
	for i = 1, #str do
		local char = str:sub(i, i)
		local byte = string.byte(char)
		if (byte >= 48 and byte <= 57) or -- 0-9
		   (byte >= 65 and byte <= 90) or -- A-Z
		   (byte >= 97 and byte <= 122) or -- a-z
		   char == "-" or char == "_" or char == "." or char == "~" then
			result[#result + 1] = char
		elseif char == " " then
			result[#result + 1] = "%20"
		else
			result[#result + 1] = string.format("%%%02X", byte)
		end
	end
	return table.concat(result)
end


---Encode URL path component (encodes only the path part, not the scheme/host)
---@param url string - Full URL
---@return string - URL with encoded path
local function encode_url_path(url)
	local scheme_end = url:find("://")
	if not scheme_end then
		return url_encode(url)
	end

	local scheme = url:sub(1, scheme_end + 2)
	local rest = url:sub(scheme_end + 3)
	local host_end = rest:find("/")

	if not host_end then
		return scheme .. rest
	end

	local host = rest:sub(1, host_end - 1)
	local path = rest:sub(host_end)

	local encoded_path = path:gsub("([^/]+)", function(segment)
		return url_encode(segment)
	end)

	return scheme .. host .. encoded_path
end


---Download a file from URL
---@param url string - The URL to download from
---@return string|nil, string|nil, table|nil - Downloaded content or nil, filename or nil, content list or nil
local function download_file_zip_json(url)
	local encoded_url = encode_url_path(url)
	local response = http.request(encoded_url, { as = "json" })

	if response.status ~= 200 then
		print("Failed to download file. HTTP status: " .. response.status)
		return nil
	end

	local data = response.body
	local content_list = data.content -- Array of file paths from zip

	return base64.decode(data.data), data.filename, content_list
end


---Find widget by dependency string (format: "author:widget_id@version" or "author@widget_id" or "widget_id")
---@param dep_string string - Dependency string
---@param all_items table - List of all available widgets
---@return table|nil - Found widget item or nil
local function find_widget_by_dependency(dep_string, all_items)
	if not dep_string or not all_items then
		return nil
	end

	local author, widget_id

	-- Try format: "author:widget_id@version" (e.g., "Insality:mini_graph@1")
	author, widget_id = dep_string:match("^([^:]+):([^@]+)@")
	if not author then
		-- Try format: "author@widget_id" (e.g., "insality@mini_graph")
		author, widget_id = dep_string:match("^([^@]+)@(.+)$")
		if not author then
			-- No author specified, search by widget_id only
			widget_id = dep_string
		end
	end

	for _, item in ipairs(all_items) do
		if item.id == widget_id then
			-- If author was specified, check it matches (case-insensitive)
			if not author or string.lower(item.author or "") == string.lower(author) then
				return item
			end
		end
	end

	return nil
end


---Get path to version file for a widget
---@param item table - Widget item data containing id
---@param install_folder string - Install folder
---@return string - Path to version file
local function get_version_file_path(item, install_folder)
	return install_folder .. "/" .. item.id .. "/" .. item.id .. ".version"
end


---Read installed version from version file
---@param item table - Widget item data containing id
---@param install_folder string - Install folder
---@return string|nil - Version string or nil if file doesn't exist
local function read_installed_version(item, install_folder)
	local version_path = get_version_file_path(item, install_folder)
	local version_file = io.open("." .. version_path, "r")
	if not version_file then
		return nil
	end

	local version_data = version_file:read("*a")
	version_file:close()

	-- Trim whitespace
	version_data = version_data:match("^%s*(.-)%s*$")
	if version_data == "" then
		return nil
	end

	-- Parse format: "author:id@version" - extract version
	local version = version_data:match("@(.+)$")
	return version
end


---Write version to version file in format: author:id@version
---@param item table - Widget item data containing id, author, and version
---@param install_folder string - Install folder
---@return boolean - Success status
local function write_installed_version(item, install_folder)
	if not item.version or not item.id or not item.author then
		return false
	end

	local version_path = get_version_file_path(item, install_folder)
	local version_file = io.open("." .. version_path, "w")
	if not version_file then
		return false
	end

	-- Write in format: author:id@version
	local full_version = item.author .. ":" .. item.id .. "@" .. tostring(item.version)
	version_file:write(full_version)
	version_file:close()

	return true
end


---Install widget dependencies recursively
---@param item asset_store.item - Widget item
---@param all_items table - List of all available widgets
---@param install_folder string - Installation folder
---@param installing_set table - Set of widget IDs currently being installed (to prevent cycles)
---@return boolean, string|nil - Success status and message
local function install_dependencies(item, all_items, install_folder, installing_set)
	if not item.depends or #item.depends == 0 then
		return true, nil
	end

	installing_set = installing_set or {}

	for _, dep_string in ipairs(item.depends) do
		local dep_item = find_widget_by_dependency(dep_string, all_items)
		if not dep_item then
			print("Warning: Dependency not found:", dep_string)
			-- Continue with other dependencies
		else
			-- Check if already installed
			if M.is_installed(dep_item, install_folder) then
				print("Dependency already installed:", dep_item.id)
			else
				-- Check for circular dependencies
				if installing_set[dep_item.id] then
					print("Warning: Circular dependency detected:", dep_item.id)
					-- Continue with other dependencies
				else
					print("Installing dependency:", dep_item.id)
					local success, err = M.install(dep_item, install_folder, all_items, installing_set)
					if not success then
						return false, "Failed to install dependency " .. dep_item.id .. ": " .. (err or "unknown error")
					end
				end
			end
		end
	end

	return true, nil
end


---Install a widget from a zip URL
---@param item asset_store.item - Widget item data containing zip_url and id
---@param install_folder string - Target folder to install to
---@param all_items table|nil - Optional list of all widgets for dependency resolution
---@param installing_set table|nil - Optional set of widget IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
function M.install(item, install_folder, all_items, installing_set)
	return M.install_widget(item, install_folder, all_items, installing_set)
end


---Install a widget from a zip URL (legacy method name, use install instead)
---@param item asset_store.item - Widget item data containing zip_url and id
---@param install_folder string - Target folder to install to
---@param all_items table|nil - Optional list of all widgets for dependency resolution
---@param installing_set table|nil - Optional set of widget IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
function M.install_widget(item, install_folder, all_items, installing_set)
	if not item.json_zip_url or not item.id then
		return false, "Invalid widget data: missing json_zip_url or id"
	end

	-- Install dependencies first if all_items is provided
	if all_items then
		installing_set = installing_set or {}
		if installing_set[item.id] then
			return false, "Circular dependency detected: " .. item.id
		end
		installing_set[item.id] = true
		local dep_success, dep_err = install_dependencies(item, all_items, install_folder, installing_set)
		if not dep_success then
			installing_set[item.id] = nil
			return false, dep_err or "Failed to install dependencies"
		end
	end

	-- Create install folder if it doesn't exist
	local install_folder_attrs = editor.resource_attributes(install_folder)
	if not install_folder_attrs or not install_folder_attrs.exists then
		editor.create_directory(install_folder)
		print("Created install folder:", install_folder)
	end

	-- Check if widget folder already exists
	local widget_folder_path = install_folder .. "/" .. item.id
	local widget_folder_attrs = editor.resource_attributes(widget_folder_path)
	if widget_folder_attrs and widget_folder_attrs.exists then
		if installing_set then
			installing_set[item.id] = nil
		end
		return false, "Widget folder already exists: " .. widget_folder_path
	end

	-- Create widget folder before zip is downloaded
	editor.create_directory(widget_folder_path)
	local created_widget_folder = true
	print("Created widget folder:", widget_folder_path)

	-- Download the zip file
	local zip_data, filename, content_list = download_file_zip_json(item.json_zip_url)
	if not zip_data or not filename then
		if installing_set then
			installing_set[item.id] = nil
		end
		if created_widget_folder then
			editor.delete_directory(widget_folder_path)
		end
		return false, "Failed to download widget: " .. (filename or "unknown error")
	end

	if not content_list then
		print("Warning: No content list in JSON data")
	end

	local zip_file_path = "." .. install_folder .. "/" .. filename
	local zip_file = io.open(zip_file_path, "wb")
	if not zip_file then
		if installing_set then
			installing_set[item.id] = nil
		end
		if created_widget_folder then
			editor.delete_directory(widget_folder_path)
		end
		print("Failed to create zip file: " .. zip_file_path)
		return false, "Failed to create zip file: " .. zip_file_path
	end

	zip_file:write(zip_data)
	zip_file:close()

	-- Unzip the zip file
	local folder_path = "." .. install_folder .. "/" .. item.id

	local unpack_ok, unpack_result, unpack_err = pcall(zip.unpack, zip_file_path, folder_path)

	-- Remove the zip file even if something goes wrong
	os.remove(zip_file_path)

	if not unpack_ok or unpack_result == false then
		if installing_set then
			installing_set[item.id] = nil
		end
		if created_widget_folder then
			editor.delete_directory(widget_folder_path)
		end

		local err = unpack_ok and unpack_err or unpack_result
		if err then
			return false, "Failed to unpack widget: " .. tostring(err)
		end

		return false, "Failed to unpack widget"
	end

	-- Process paths within the extracted widget
	if content_list and #content_list > 0 then
		local success, err = path_replacer.process_widget_paths(folder_path, install_folder, item.id, item.author, content_list)
		if not success then
			print("Warning: Path replacement failed:", err)
			-- Don't fail installation if path replacement fails, just warn
		end
	else
		print("Warning: No file list available, skipping path replacement")
	end

	-- Write version to version file
	if item.version then
		local version_written = write_installed_version(item, install_folder)
		if version_written then
			local version_path = install_folder .. "/" .. item.id .. "/" .. item.id .. ".version"
			print("Version written to file:", version_path)
		else
			print("Warning: Failed to write version file")
		end
	end

	if installing_set then
		installing_set[item.id] = nil
	end

	return true, "Widget installed successfully"
end


---Check if a widget is already installed
---@param item table - Widget item data containing id
---@param install_folder string - Install folder to check in
---@return boolean - True if widget is already installed
function M.is_installed(item, install_folder)
	local p = editor.resource_attributes(install_folder .. "/" .. item.id)
	return p.exists
end


---Update a widget by removing old version and installing new one
---@param item asset_store.item - Widget item data
---@param install_folder string - Target folder to install to
---@param all_items table|nil - Optional list of all widgets for dependency resolution
---@param installing_set table|nil - Optional set of widget IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
local function update_widget(item, install_folder, all_items, installing_set)
	if not item.id then
		return false, "Invalid widget data: missing id"
	end

	local widget_path = install_folder .. "/" .. item.id

	-- Check if widget is installed
	if not M.is_installed(item, install_folder) then
		return false, "Widget is not installed: " .. item.id
	end

	-- Remove old widget folder using editor.delete_directory
	print("Removing old widget:", widget_path)

	-- Check if folder exists
	local resource_attrs = editor.resource_attributes(widget_path)
	if not resource_attrs or not resource_attrs.exists then
		-- Widget folder doesn't exist, nothing to remove
		print("Widget folder doesn't exist, skipping removal")
	else
		-- Remove directory using editor API
		editor.delete_directory(widget_path)
		print("Old widget removed successfully")
	end

	-- Install new version
	return M.install_widget(item, install_folder, all_items, installing_set)
end


---Get installed version of a widget
---@param item table - Widget item data containing id
---@param install_folder string - Install folder
---@return string|nil - Installed version or nil if not found
function M.get_installed_version(item, install_folder)
	if not item or not item.id or not install_folder then
		return nil
	end
	return read_installed_version(item, install_folder)
end


---Update a widget
---@param item asset_store.item - Widget item data
---@param install_folder string|nil - Target folder (optional, will be retrieved if not provided)
---@param all_items table|nil - Optional list of all widgets for dependency resolution
---@param installing_set table|nil - Optional set of widget IDs currently being installed (to prevent cycles)
---@return boolean, string - Success status and message
function M.update(item, install_folder, all_items, installing_set)
	if not item or not item.id then
		return false, "Invalid widget data"
	end

	install_folder = install_folder or M.get_install_folder()
	if not install_folder then
		return false, "Install folder not set"
	end

	return update_widget(item, install_folder, all_items, installing_set)
end


---Check if item can be updated
---@param item table - Item data
---@param install_folder string|nil - Install folder (optional, will be retrieved if not provided)
---@return boolean, nil - True if can be updated, nil if no update available
function M.can_update(item, install_folder)
	if not item or not item.id or not item.version then
		return false, nil
	end

	install_folder = install_folder or M.get_install_folder()
	if not install_folder then
		return false, nil
	end

	-- Check if widget is installed
	if not M.is_installed(item, install_folder) then
		return false, nil
	end

	-- Read installed version
	local installed_version = read_installed_version(item, install_folder)
	if not installed_version then
		-- No version file means version is unknown, don't show update
		return false, nil
	end

	-- Compare versions (simple string/number comparison)
	local store_version = tostring(item.version)
	local installed_version_str = tostring(installed_version)

	-- If versions are different, can update
	if store_version ~= installed_version_str then
		return true, nil
	end

	return false, nil
end


---Get installation folder
---@return string - Installation folder path
function M.get_install_folder()
	return editor.prefs.get("druid.asset_install_folder")
end


return M
