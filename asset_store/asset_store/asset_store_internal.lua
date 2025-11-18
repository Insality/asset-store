local M = {}


local function normalize_query(query)
	if not query or query == "" then
		return nil
	end

	return string.lower(query)
end


local function is_unlisted_visible(item, lower_query)
	if not item.unlisted then
		return true
	end

	if not lower_query or not item.id then
		return false
	end

	return string.lower(item.id) == lower_query
end


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


function M.extract_tags(items)
	local tags = {}
	local tag_set = {}

	for _, item in ipairs(items) do
		if not item.unlisted and item.tags then
			for _, tag in ipairs(item.tags) do
				if not tag_set[tag] then
					tag_set[tag] = true
					table.insert(tags, tag)
				end
			end
		end
	end

	table.sort(tags)

	return tags
end


function M.filter_items_by_filters(items, search_query, filter_type, filter_author, filter_tag, install_folder, adapter, sort_by, asset_type)
	local lower_query = normalize_query(search_query)
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

	if filter_type and filter_type ~= "All" then
		local type_filtered = {}
		for _, item in ipairs(filtered) do
			local is_installed = adapter.is_installed(item, install_folder)
			if (filter_type == "Installed" and is_installed) or
				(filter_type == "Not Installed" and not is_installed) then
				table.insert(type_filtered, item)
			end
		end
		filtered = type_filtered
	end

	if filter_author and filter_author ~= "All Authors" then
		local author_filtered = {}
		for _, item in ipairs(filtered) do
			if item.author == filter_author then
				table.insert(author_filtered, item)
			end
		end
		filtered = author_filtered
	end

	if filter_tag and filter_tag ~= "All Tags" then
		local tag_filtered = {}
		for _, item in ipairs(filtered) do
			if item.tags then
				for _, tag in ipairs(item.tags) do
					if tag == filter_tag then
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


---Encode a string for use in URL query parameters
---@param str string
---@return string
local function encode_for_url(str)
	local result = {}
	for i = 1, #str do
		local byte = string.byte(str, i)
		-- Safe: letters, digits, hyphen, underscore, tilde
		if (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or
		   byte == 45 or byte == 95 or byte == 126 then
			result[#result + 1] = string.char(byte)
		else
			result[#result + 1] = string.format("%%%02X", byte)
		end
	end
	return table.concat(result)
end


---Track download event via external tracking service
---Used to grant popularity points to the asset and different sorting day to day
---@param item table - Asset item that was downloaded (widget or dependency)
---@param asset_type string - Asset type: "widget" or "dependency"
function M.track_download(item, asset_type)
	if not item or not item.id then
		return
	end

	-- Build asset identifier: type:author:id (no version)
	local asset_id = item.id
	if item.author then
		asset_id = item.author .. ":" .. asset_id
	end

	-- Add asset type prefix: item: or dependency:
	local asset_type_prefix = (asset_type == "dependency" and "dependency:") or "item:"
	asset_id = asset_type_prefix .. asset_id

	-- Encode for URL (Express will auto-decode, so it matches JSON format in stats)
	asset_id = encode_for_url(asset_id)

	-- Get tracking service URL from prefs
	local tracking_service_url = editor.prefs.get("asset_store.tracking_service_url")
	if not tracking_service_url or tracking_service_url == "" then
		return
	end

	-- Get or generate user_id
	local user_id_key = "asset_store.user_id"
	local user_id = editor.prefs.get(user_id_key)
	if not user_id or user_id == "" then
		math.randomseed(os.time())
		user_id = "user_" .. tostring(math.random(1000000, 9999999))
		editor.prefs.set(user_id_key, user_id)
	end

	-- Build tracking URL
	local tracking_url = string.format(
		"%s/api/track?asset=%s&user_id=%s",
		tracking_service_url,
		asset_id,
		user_id
	)

	-- Fire and forget - send tracking request (server handles protection)
	pcall(function()
		http.request(tracking_url, {
			method = "GET",
			headers = {
				["Accept"] = "application/json"
			},
			as = "json"
		})
	end)
end


function M.open_url(url)
	if not url then
		print("No URL available for:", url)
	end

	editor.browse(url)
end


return M

