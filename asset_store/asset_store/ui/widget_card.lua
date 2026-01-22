local locales = require("asset_store.asset_store.locales")
local ui_utils = require("asset_store.asset_store.ui.ui_utils")


local DEFAULT_LABELS = {
	install_button = locales.get("widget_card_install_button"),
	update_button = locales.get("widget_card_update_button"),
	api_button = locales.get("widget_card_api_button"),
	example_button = locales.get("widget_card_example_button"),
	author_caption = locales.get("widget_card_author_caption"),
	installed_tag = locales.get("widget_card_installed_tag"),
	tags_prefix = locales.get("widget_card_tags_prefix"),
	depends_prefix = locales.get("widget_card_depends_prefix"),
	size_separator = locales.get("widget_card_size_separator"),
	unknown_size = locales.get("widget_card_unknown_size"),
}


local M = {}


---Create widget card UI component
---@param item asset_store.item Asset item
---@param context table Context: on_install, on_update, on_version_change, open_url, is_installed, can_update, version_options, installed_version_name, labels
---@return userdata component UI component
function M.create(item, context)
	local labels = ui_utils.build_labels(DEFAULT_LABELS, context and context.labels)
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
		local size_text = ui_utils.format_size(item.size, labels.unknown_size)
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

	local description_children = {}
	local description_spacing = editor.ui.SPACING.NONE
	if item.image and item.image ~= "" then
		description_spacing = editor.ui.SPACING.LARGE
		table.insert(description_children, editor.ui.image({
			image = ui_utils.escape_url(item.image),
			width = 146,
		}))
	end
	table.insert(description_children, editor.ui.paragraph({
		text = item.description or locales.get("widget_card_no_description"),
		color = editor.ui.COLOR.TEXT
	}))

	local widget_details_children = {
		editor.ui.horizontal({
			spacing = editor.ui.SPACING.SMALL,
			children = header_children
		}),
		editor.ui.horizontal({
			spacing = description_spacing,
			children = description_children
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
			grow = true,
			value = selected_value,
			options = version_options,
			on_value_changed = function(selected_version_name)
				-- Pass selected version name directly to on_version_change
				-- It will handle both version updates and "delete" option
				on_version_change(item, selected_version_name)
			end
		}))
	end

	table.insert(button_children, editor.ui.horizontal({ grow = true }))

	local right_button_children = {}
	if item.author_url then
		table.insert(right_button_children, editor.ui.label({
			text = labels.author_caption,
			color = editor.ui.COLOR.HINT
		}))
		table.insert(right_button_children, editor.ui.button({
			text = item.author or labels.author_caption,
			on_pressed = function() open_url(item.author_url) end,
			enabled = item.author_url ~= nil
		}))

		table.insert(button_children, editor.ui.horizontal({
			spacing = editor.ui.SPACING.MEDIUM,
			children = right_button_children
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
