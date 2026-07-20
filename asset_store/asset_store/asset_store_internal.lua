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


---True when search query matches item id exactly (case-insensitive)
local function query_matches_id(lower_query, item)
	return lower_query and item.id and string.lower(item.id) == lower_query
end


---Normalize required folder path (ensures leading slash)
---@param required_path string|nil Folder path from requires field
---@return string|nil normalized_path Normalized path or nil if invalid
local function normalize_required_path(required_path)
	if type(required_path) ~= "string" then
		return nil
	end

	local normalized = required_path:match("^%s*(.-)%s*$")
	if normalized == "" then
		return nil
	end

	if normalized:sub(1, 1) ~= "/" then
		normalized = "/" .. normalized
	end

	return normalized
end


---Check if all required folders for item are available
---@param requires string[]|nil Required folder paths
---@param cache table|nil Optional cache for folder checks
---@return boolean available True if all required folders exist
local function has_required_folders(requires, cache)
	if not requires or type(requires) ~= "table" or #requires == 0 then
		return true
	end

	if not editor or not editor.can_get then
		return true
	end

	cache = cache or {}

	for _, required_path in ipairs(requires) do
		local normalized = normalize_required_path(required_path)
		if normalized then
			local is_available = cache[normalized]
			if is_available == nil then
				is_available = pcall(editor.can_get, normalized, "path")
				cache[normalized] = is_available
			end

			if not is_available then
				return false
			end
		end
	end

	return true
end


---Check if item should be visible based on unlisted/requires fields
---@param item table Item to check
---@param lower_query string|nil Lowercase search query
---@param requires_cache table|nil Cache for folder availability checks
---@return boolean visible True if item should be visible
local function is_item_visible(item, lower_query, requires_cache)
	local exact_id_match = query_matches_id(lower_query, item)

	local hidden_because_unlisted = item.unlisted and not exact_id_match
	if hidden_because_unlisted then
		return false
	end

	local visible_because_exact_id = exact_id_match
	local visible_because_has_requirements = has_required_folders(item.requires, requires_cache)

	return visible_because_exact_id or visible_because_has_requirements
end


---Download JSON from URL
---@param json_url string URL to download JSON from
---@return table|nil data JSON data or nil
---@return string|nil error Error message or nil
function M.download_json(json_url)
	local success, response = pcall(function()
		return http.request(json_url, { as = "json" })
	end)

	if not success then
		local error_msg = "Failed to fetch store data: " .. tostring(response)
		print("Asset Store Error:", error_msg)
		return nil, error_msg
	end

	if response.status ~= 200 then
		local error_msg = "Failed to fetch store data. HTTP status: " .. response.status
		print("Asset Store Error:", error_msg)
		return nil, error_msg
	end

	if not response.body or not response.body.items then
		local error_msg = "Invalid store data format"
		print("Asset Store Error:", error_msg)
		return nil, error_msg
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
	local requires_cache = {}

	for _, item in ipairs(items) do
		if is_item_visible(item, nil, requires_cache) and item.author and not author_set[item.author] then
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
	local requires_cache = {}

	for _, item in ipairs(items) do
		if is_item_visible(item, nil, requires_cache) and item.tags then
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
	local requires_cache = {}

	for _, item in ipairs(items) do
		if is_item_visible(item, lower_query, requires_cache) then
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
		print("No URL available")
		return
	end

	editor.browse(url)
end


return M
