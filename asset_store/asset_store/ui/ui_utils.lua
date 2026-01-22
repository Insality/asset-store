local M = {}


---Format size in bytes to human-readable string
---@param size_bytes number|nil Size in bytes
---@param unknown_size_label string|nil Label to use for unknown size (default: "Unknown")
---@return string formatted Formatted size string
function M.format_size(size_bytes, unknown_size_label)
	if not size_bytes then
		return unknown_size_label or "Unknown"
	end

	if size_bytes < 1024 then
		return size_bytes .. " B"
	elseif size_bytes < 1024 * 1024 then
		return math.floor(size_bytes / 1024) .. " KB"
	end

	return math.floor(size_bytes / (1024 * 1024)) .. " MB"
end


---Escape URL
---@param url string URL
---@return string escaped Escaped URL
function M.escape_url(url)
	if not url or type(url) ~= "string" then
		return url
	end

	local scheme_end = url:find("://")
	if not scheme_end then
		return url
	end

	local scheme = url:sub(1, scheme_end + 2)
	local rest = url:sub(scheme_end + 3)
	local host_end = rest:find("/")

	if not host_end then
		return url
	end

	local host = rest:sub(1, host_end - 1)
	local path = rest:sub(host_end)

	local encoded_path = path:gsub("([^/]+)", function(segment)
		local result = {}
		for i = 1, #segment do
			local char = segment:sub(i, i)
			local byte = string.byte(char)
			if (byte >= 48 and byte <= 57) or
			   (byte >= 65 and byte <= 90) or
			   (byte >= 97 and byte <= 122) or
			   char == "-" or char == "_" or char == "." or char == "~" then
				result[#result + 1] = char
			elseif char == " " then
				result[#result + 1] = "%20"
			else
				result[#result + 1] = string.format("%%%02X", byte)
			end
		end
		return table.concat(result)
	end)

	return scheme .. host .. encoded_path
end


---Build labels with overrides
---@param default_labels table Default labels table
---@param overrides table|nil Label overrides
---@return table labels Labels table
function M.build_labels(default_labels, overrides)
	if not overrides then
		return default_labels
	end

	local labels = {}
	for key, value in pairs(default_labels) do
		labels[key] = overrides[key] or value
	end

	return labels
end


return M
