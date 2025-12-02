local M = {}


---Normalize search query
---@param query string|nil Search query
---@return string|nil normalized Normalized query or nil
local function normalize_query(query)
	if not query or query == "" then
		return nil
	end

	return string.lower(query)
end


---Check if unlisted item should be visible
---@param item table Item to check
---@param lower_query string|nil Lowercase search query
---@return boolean visible True if item should be visible
local function is_unlisted_visible(item, lower_query)
	if not item.unlisted then
		return true
	end

	if not lower_query or not item.id then
		return false
	end

	return string.lower(item.id) == lower_query
end


---Download JSON from URL
---@param json_url string URL to download JSON from
---@return table|nil data JSON data or nil
---@return string|nil error Error message or nil
function M.download_json(json_url)
	local response = http.request(json_url, { as = "json" })

	if response.status ~= 200 then
		return nil, "Failed to fetch store data. HTTP status: " .. response.status
	end

	if not response.body or not response.body.items then
		return nil, "Invalid store data format"
	end

	return response.body, nil
end


---Filter items by search query
---@param items table Array of items to filter
---@param query string Search query
---@return table filtered Filtered items array
function M.filter_items(items, query)
	if query == "" or query == nil then
		return items
	end

	local filtered = {}
	local lower_query = string.lower(query)

	for _, item in ipairs(items) do
		local matches = false
		if item.id and string.find(string.lower(item.id), lower_query, 1, true) then
			matches = true
		elseif item.title and string.find(string.lower(item.title), lower_query, 1, true) then
			matches = true
		elseif item.author and string.find(string.lower(item.author), lower_query, 1, true) then
			matches = true
		elseif item.description and string.find(string.lower(item.description), lower_query, 1, true) then
			matches = true
		end

		if not matches and item.tags then
			for _, tag in ipairs(item.tags) do
				if string.find(string.lower(tag), lower_query, 1, true) then
					matches = true
					break
				end
			end
		end

		if not matches and item.depends then
			for _, dep in ipairs(item.depends) do
				if string.find(string.lower(dep), lower_query, 1, true) then
					matches = true
					break
				end
			end
		end

		if matches then
			table.insert(filtered, item)
		end
	end

	return filtered
end


---Extract unique authors from items
---@param items table Array of items
---@return table authors Array of unique author names (sorted)
function M.extract_authors(items)
	local authors = {}
	local author_set = {}

	for _, item in ipairs(items) do
		if not item.unlisted and item.author and not author_set[item.author] then
			author_set[item.author] = true
			table.insert(authors, item.author)
		end
	end

	table.sort(authors)

	return authors
end


---Extract unique tags from items
---@param items table Array of items
---@return table tags Array of unique tag names (sorted)
function M.extract_tags(items)
	local tags = {}
	local tag_set = {}

	for _, item in ipairs(items) do
		if not item.unlisted and item.tags then
			for _, tag in ipairs(item.tags) do
				local lower_tag = string.lower(tag)
				if not tag_set[lower_tag] then
					tag_set[lower_tag] = tag
					table.insert(tags, tag)
				end
			end
		end
	end

	table.sort(tags)

	return tags
end


---Filter and sort items by multiple criteria
---@param items table Array of items to filter
---@param search_query string Search query string
---@param filter_type string Filter type (e.g., "All", "Installed", "Not Installed")
---@param filter_author string Filter author (e.g., "All Authors" or specific author)
---@param filter_tag string Filter tag (e.g., "All Tags" or specific tag)
---@param install_folder string|nil Installation folder
---@param adapter table Adapter instance
---@param sort_by string Sort criteria
---@param asset_type string Asset type: "folder" or "dependency"
---@return table filtered Filtered and sorted items array
function M.filter_items_by_filters(items, search_query, filter_type, filter_author, filter_tag, install_folder, adapter, sort_by, asset_type)
	local lower_query = normalize_query(search_query)
	-- Normalize filter_type by trimming whitespace for comparison
	local normalized_filter_type = filter_type and filter_type:match("^%s*(.-)%s*$") or nil
	local visible_items = {}

	for _, item in ipairs(items) do
		if is_unlisted_visible(item, lower_query) then
			table.insert(visible_items, item)
		end
	end

	local filtered = visible_items

	if lower_query then
		filtered = M.filter_items(filtered, search_query)
	end

	if normalized_filter_type and normalized_filter_type ~= "All" then
		local type_filtered = {}
		for _, item in ipairs(filtered) do
			local is_installed = adapter.is_installed(item, install_folder)
			if (normalized_filter_type == "Installed" and is_installed) or
				(normalized_filter_type == "Not Installed" and not is_installed) then
				table.insert(type_filtered, item)
			end
		end
		filtered = type_filtered
	end

	-- Normalize filter_author by trimming whitespace for comparison
	local normalized_filter_author = filter_author and filter_author:match("^%s*(.-)%s*$") or nil

	if normalized_filter_author and normalized_filter_author ~= "All Authors" then
		local author_filtered = {}
		for _, item in ipairs(filtered) do
			if item.author == normalized_filter_author then
				table.insert(author_filtered, item)
			end
		end
		filtered = author_filtered
	end

	-- Normalize filter_tag by trimming whitespace and converting to lowercase for comparison
	local normalized_filter_tag = filter_tag and filter_tag:match("^%s*(.-)%s*$") or nil

	if normalized_filter_tag and normalized_filter_tag ~= "All Tags" then
		local tag_filtered = {}
		local lower_filter_tag = string.lower(normalized_filter_tag)
		for _, item in ipairs(filtered) do
			if item.tags then
				for _, tag in ipairs(item.tags) do
					if string.lower(tag) == lower_filter_tag then
						table.insert(tag_filtered, item)
						break
					end
				end
			end
		end
		filtered = tag_filtered
	end

	-- Apply sorting
	M.sort_items(filtered, sort_by, asset_type)

	return filtered
end


---Sort items by specified criteria
---@param items table Array of items to sort
---@param sort_by string Sort criteria: "Popularity", "Stars", "Asset Name", "Author", "Size"
---@param asset_type string Asset type: "folder" or "dependency"
function M.sort_items(items, sort_by, asset_type)
	if not items or #items == 0 then
		return
	end

	sort_by = sort_by or "Popularity"

	if sort_by == "Popularity" then
		-- Sort by popularity (week > month > total > title)
		table.sort(items, function(a, b)
			local pop_a = a.popularity or {}
			local pop_b = b.popularity or {}

			local week_a = pop_a.week or 0
			local week_b = pop_b.week or 0
			if week_a ~= week_b then
				return week_a > week_b
			end

			local month_a = pop_a.month or 0
			local month_b = pop_b.month or 0
			if month_a ~= month_b then
				return month_a > month_b
			end

			local total_a = pop_a.total or 0
			local total_b = pop_b.total or 0
			if total_a ~= total_b then
				return total_a > total_b
			end

			-- If popularity is equal, sort by title
			return (a.title or "") < (b.title or "")
		end)
	elseif sort_by == "Stars" and asset_type == "dependency" then
		-- Sort by stars (descending), then by title
		table.sort(items, function(a, b)
			local stars_a = a.stars or 0
			local stars_b = b.stars or 0
			if stars_a ~= stars_b then
				return stars_a > stars_b
			end
			return (a.title or "") < (b.title or "")
		end)
	elseif sort_by == "Asset Name" then
		-- Sort by title (ascending)
		table.sort(items, function(a, b)
			return (a.title or "") < (b.title or "")
		end)
	elseif sort_by == "Author" then
		-- Sort by author (ascending), then by title
		table.sort(items, function(a, b)
			local author_a = a.author or ""
			local author_b = b.author or ""
			if author_a ~= author_b then
				return author_a < author_b
			end
			return (a.title or "") < (b.title or "")
		end)
	elseif sort_by == "Size" and asset_type == "folder" then
		-- Sort by size (descending), then by title
		table.sort(items, function(a, b)
			local size_a = a.size or 0
			local size_b = b.size or 0
			if size_a ~= size_b then
				return size_a > size_b
			end
			return (a.title or "") < (b.title or "")
		end)
	else
		-- Default: sort by title
		table.sort(items, function(a, b)
			return (a.title or "") < (b.title or "")
		end)
	end
end


---Open URL in browser
---@param url string|nil URL to open
function M.open_url(url)
	if not url then
		print("No URL available for:", url)
	end

	editor.browse(url)
end


---Read editor port from .internal/editor.port file
---@return number|nil port Editor port number or nil if not found
local function get_editor_port()
	local port_file_path = ".internal/editor.port"
	local port_file = io.open(port_file_path, "r")
	if not port_file then
		return nil
	end

	local port_str = port_file:read("*a")
	port_file:close()

	if not port_str then
		return nil
	end

	-- Trim whitespace
	port_str = string.match(port_str, "%s*(.-)%s*$")
	local port = tonumber(port_str)
	return port
end


---Call editor HTTP API command
---@param command string Command name (e.g., "fetch-libraries")
---@return boolean success True if request was sent successfully
function M.call_editor_command(command)
	if not command or command == "" then
		return false
	end

	local port = get_editor_port()
	if not port then
		print("Asset Store: Could not read editor port from .internal/editor.port")
		return false
	end

	local url = string.format("http://localhost:%d/command/%s", port, command)

	-- Fire and forget - send POST request to editor API
	pcall(function()
		local response = http.request(url, {
			method = "POST",
			headers = {
				["Accept"] = "application/json"
			}
		})
	end)

	return true
end


return M

