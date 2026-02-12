--- Module for replacing paths in installed files
--- Handles path replacement from original structure to user's installation path

local M = {}


---Replace paths in file content
---@param content string File content
---@param author string Author name (e.g., "Insality")
---@param install_folder string Installation folder (e.g., "widget")
---@return string modified Modified content
local function replace_paths_in_content(content, author, install_folder)
	-- Escape special characters for literal string replacement
	local function escape_pattern(str)
		return str:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
	end

	-- Remove leading / from install_folder if present
	local clean_install_folder = install_folder or ""
	clean_install_folder = clean_install_folder:gsub("^/", "")
	if clean_install_folder == "" then
		return content
	end
	local clean_install_folder_dots = clean_install_folder:gsub("/", ".")

	local function replace_literal(source, target)
		source = escape_pattern(source)
		target = target:gsub("%%", "%%%%")
		content = content:gsub(source, target)
	end

	local target_path_prefix = clean_install_folder .. "/"
	local target_dots_prefix = clean_install_folder_dots .. "."
	local target_abs_path_prefix = "/" .. target_path_prefix

	local default_folder_path = "widget"
	local default_abs_folder_path = "/" .. default_folder_path .. "/"

	do -- Author paths
		replace_literal("\"" .. default_abs_folder_path .. author .. "/", "\"" .. target_abs_path_prefix)
		replace_literal("'" .. default_abs_folder_path .. author .. "/", "'" .. target_abs_path_prefix)

		replace_literal("\"" .. default_folder_path .. "/" .. author .. "/", "\"" .. target_path_prefix)
		replace_literal("'" .. default_folder_path .. "/" .. author .. "/", "'" .. target_path_prefix)

		replace_literal("\"" .. default_folder_path .. "." .. author .. ".", "\"" .. target_dots_prefix)
		replace_literal("'" .. default_folder_path .. "." .. author .. ".", "'" .. target_dots_prefix)
	end

	do -- Default paths
		replace_literal("\"" .. default_abs_folder_path, "\"" .. target_abs_path_prefix)
		replace_literal("'" .. default_abs_folder_path, "'" .. target_abs_path_prefix)

		replace_literal("\"" .. default_folder_path .. "/", "\"" .. target_path_prefix)
		replace_literal("'" .. default_folder_path .. "/", "'" .. target_path_prefix)

		replace_literal("\"" .. default_folder_path .. ".", "\"" .. target_dots_prefix)
		replace_literal("'" .. default_folder_path .. ".", "'" .. target_dots_prefix)
	end

	return content
end


---Read file content
---@param file_path string File path
---@return string|nil content File content or nil on error
---@return string|nil reason Error reason or nil
function M.read_file(file_path)
	local file = io.open(file_path, "r")
	if file == nil then
		return nil, "Could not open file: " .. file_path
	end

	local content = file:read("*a")
	file:close()

	return content, nil
end


---Write file content
---@param file_path string File path
---@param content string Content to write
---@return boolean success Success status
---@return string|nil reason Error reason or nil
function M.write_file(file_path, content)
	local file = io.open(file_path, "w")
	if file == nil then
		return false, "Could not open file: " .. file_path
	end

	file:write(content)
	file:close()

	return true, nil
end


---Process widget paths in all files
---@param folder_path string Path to the unpacked widget folder
---@param install_folder string Installation folder (e.g., "widget")
---@param widget_id string Widget ID (e.g., "fps_panel")
---@param author string Author name (e.g., "Insality")
---@param file_list table Optional list of file paths from zip content
---@return boolean success Success status
---@return string|nil error Error message if any
function M.process_widget_paths(folder_path, install_folder, widget_id, author, file_list)
	print("Processing widget paths in:", folder_path)

	-- Get absolute project path
	local absolute_project_path = editor.external_file_attributes(".").path
	if not absolute_project_path:match("[\\/]$") then
		absolute_project_path = absolute_project_path .. "/"
	end

	-- Clean folder_path
	local clean_folder_path = folder_path
	if clean_folder_path:sub(1, 1) == "." then
		clean_folder_path = clean_folder_path:sub(2)
	end
	if clean_folder_path:sub(1, 1) == "/" then
		clean_folder_path = clean_folder_path:sub(2)
	end

	-- Process each file from the list
	local processed_count = 0
	for _, file_path_in_zip in ipairs(file_list) do
		-- Build full path to the file after unpacking
		local file_path = clean_folder_path .. "/" .. file_path_in_zip

		-- Get absolute path
		local clean_file_path = file_path
		if clean_file_path:sub(1, 1) == "/" then
			clean_file_path = clean_file_path:sub(2)
		end
		local absolute_file_path = absolute_project_path .. clean_file_path

		-- Read file content
		local content, err = M.read_file(absolute_file_path)
		if not content then
			print("Warning: Could not read file:", file_path, err)
		else
			-- Replace all paths with author
			local modified_content = replace_paths_in_content(content, author, install_folder)
			if modified_content ~= content then
				-- Write modified content back
				local success, write_err = M.write_file(absolute_file_path, modified_content)
				if success then
					processed_count = processed_count + 1
					print("Processed:", file_path)
				else
					print("Warning: Could not write file:", file_path, write_err)
				end
			end
		end
	end

	return true, nil
end


return M
