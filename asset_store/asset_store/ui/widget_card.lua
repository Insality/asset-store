local DEFAULT_LABELS = {
	install_button = "Install",
	update_button = "Update",
	api_button = "API",
	example_button = "Example",
	author_caption = "Author",
	installed_tag = "Version",
	tags_prefix = "Tags: ",
	depends_prefix = "Depends: ",
	size_separator = "• ",
	unknown_size = "Unknown size",
}


local M = {}


local function format_size(size_bytes)
	if not size_bytes then
		return DEFAULT_LABELS.unknown_size
	end

	if size_bytes < 1024 then
		return size_bytes .. " B"
	elseif size_bytes < 1024 * 1024 then
		return math.floor(size_bytes / 1024) .. " KB"
	end

	return math.floor(size_bytes / (1024 * 1024)) .. " MB"
end


local function build_labels(overrides)
	if not overrides then
		return DEFAULT_LABELS
	end

	local labels = {}
	for key, value in pairs(DEFAULT_LABELS) do
		labels[key] = overrides[key] or value
	end

	return labels
end


---Extract version name from dependency URL (filename without .zip extension)
---@param url string - Dependency URL
---@return string|nil - Version name or nil
local function extract_version_name_from_url(url)
	if not url or type(url) ~= "string" then
		return nil
	end

	-- Remove query parameters if any
	local path = url:match("^([^%?]+)")
	if not path then
		return nil
	end

	-- Extract the last path segment (filename)
	local filename = path:match("([^/]+)/?$")
	if not filename then
		return nil
	end

	-- Remove .zip extension if present
	local version_name = filename:match("^(.+)%.zip$")
	if version_name then
		return version_name
	end

	-- Return filename as-is if no .zip extension
	return filename
end


function M.create(item, context)
	local labels = build_labels(context and context.labels)
	local open_url = context and context.open_url or function(_) end
	local on_install = context and context.on_install or function(...) end
	local on_update = context and context.on_update or function(...) end
	local is_installed = context and context.is_installed or false
	local can_update = context and context.can_update or false
	local on_version_change = context and context.on_version_change or function(...) end
	local installed_version_name = context and context.installed_version_name or nil
	local version_options = context and context.version_options or nil

	-- Detect if this is a dependency (has content array)
	local is_dependency = item.content and type(item.content) == "table" and #item.content > 0

	local tags_text = item.tags and #item.tags > 0 and labels.tags_prefix .. table.concat(item.tags, ", ") or ""
	local deps_text = item.depends and #item.depends > 0 and labels.depends_prefix .. table.concat(item.depends, ", ") or ""

	-- Build left side of header (title, version, size)
	local header_left = {
		editor.ui.label({
			text = item.title or item.id,
			color = editor.ui.COLOR.OVERRIDE
		}),
	}

	-- Add version if it exists (for items) or if dependency is installed (show installed version)
	if installed_version_name or item.version then
		-- Show installed version for dependencies
		table.insert(header_left, editor.ui.label({
			text = (installed_version_name or item.version),
			color = editor.ui.COLOR.WARNING
		}))
	end

	-- Only add size if it exists
	if item.size and item.size > 0 then
		local size_text = format_size(item.size)
		table.insert(header_left, editor.ui.label({
			text = labels.size_separator .. size_text,
			color = editor.ui.COLOR.HINT
		}))
	end

	-- Build right side of header (stars, downloads)
	local header_right = {}

	-- Add stars for dependencies if available
	if is_dependency and item.stars and item.stars > 0 then
		table.insert(header_right, editor.ui.label({
			text = "★ " .. tostring(item.stars) .. "  ",
			color = editor.ui.COLOR.HINT
		}))
	end

	-- Add weekly downloads for dependencies if available
	--if is_dependency and item.popularity and item.popularity.week and item.popularity.week > 0 then
	--	table.insert(header_right, editor.ui.label({
	--		text = " ↓ " .. tostring(item.popularity.week) .. "  ",
	--		color = editor.ui.COLOR.HINT
	--	}))
	--end

	-- Combine left, spacer, and right parts
	local header_children = {}
	for _, child in ipairs(header_left) do
		table.insert(header_children, child)
	end
	table.insert(header_children, editor.ui.horizontal({ grow = true }))
	for _, child in ipairs(header_right) do
		table.insert(header_children, child)
	end

	local widget_details_children = {
		editor.ui.horizontal({
			spacing = editor.ui.SPACING.SMALL,
			children = header_children
		}),
		editor.ui.paragraph({
			text = item.description or "No description available",
			color = editor.ui.COLOR.TEXT
		})
	}

	if tags_text ~= "" then
		table.insert(widget_details_children, editor.ui.label({
			text = tags_text,
			color = editor.ui.COLOR.HINT
		}))
	end

	if deps_text ~= "" then
		table.insert(widget_details_children, editor.ui.label({
			text = deps_text,
			color = editor.ui.COLOR.HINT
		}))
	end

	local button_children = {}

	-- Show Update button if can update, otherwise show Install button
	-- For dependencies, disable Install button when installed (even if can_update is false)
	if can_update then
		table.insert(button_children, editor.ui.button({
			text = labels.update_button,
			on_pressed = on_update,
			enabled = true
		}))
	else
		table.insert(button_children, editor.ui.button({
			text = labels.install_button,
			on_pressed = on_install,
			enabled = not is_installed
		}))
	end

	if item.api then
		table.insert(button_children, editor.ui.button({
			text = labels.api_button,
			on_pressed = function() open_url(item.api) end,
			enabled = item.api ~= nil
		}))
	end

	-- Show Example button if example_url or example_code exists
	local example_url = item.example_url or item.example_code
	if example_url then
		table.insert(button_children, editor.ui.button({
			text = labels.example_button,
			on_pressed = function() open_url(example_url) end,
			enabled = example_url ~= nil
		}))
	end

	-- Add version dropdown for installed dependencies
	if is_dependency and is_installed and version_options and #version_options > 0 then
		-- Find the selected value (installed version name if it exists in options)
		local selected_value = nil
		if installed_version_name then
			for _, option in ipairs(version_options) do
				if option == installed_version_name then
					selected_value = option
					break
				end
			end
		end

		table.insert(button_children, editor.ui.select_box({
			value = selected_value,
			options = version_options,
			on_value_changed = function(selected_version_name)
				-- Find the URL corresponding to the selected version
				if item.content then
					for _, url in ipairs(item.content) do
						local version_name = extract_version_name_from_url(url)
						if version_name == selected_version_name then
							on_version_change(item, url)
							break
						end
					end
				end
			end
		}))
	end

	table.insert(button_children, editor.ui.horizontal({ grow = true }))

	if item.author_url then
		table.insert(button_children, editor.ui.label({
			text = labels.author_caption,
			color = editor.ui.COLOR.HINT
		}))
		table.insert(button_children, editor.ui.button({
			text = item.author or labels.author_caption,
			on_pressed = function() open_url(item.author_url) end,
			enabled = item.author_url ~= nil
		}))
	end

	table.insert(widget_details_children, editor.ui.horizontal({
		spacing = editor.ui.SPACING.SMALL,
		children = button_children
	}))

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.NONE,
		padding = editor.ui.PADDING.NONE,
		children = {
			editor.ui.label({
				text = is_installed and "▸▸  " or "▹▹  ",
				color = editor.ui.COLOR.HINT
			}),
			editor.ui.vertical({
				spacing = editor.ui.SPACING.SMALL,
				grow = true,
				children = widget_details_children
			}),
		}
	})
end


return M
