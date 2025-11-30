local locales = require("asset_store.asset_store.locales")


local DEFAULT_LABELS = {
	type_label = locales.get("filters_type_label"),
	author_label = locales.get("filters_author_label"),
	tag_label = locales.get("filters_tag_label"),
	all_types = locales.get("filters_all_types"),
	installed = locales.get("filters_installed"),
	not_installed = locales.get("filters_not_installed"),
	all_authors = locales.get("filters_all_authors"),
	all_tags = locales.get("filters_all_tags"),
}


local M = {}


---Build labels with overrides
---@param overrides table|nil Label overrides
---@return table labels Labels table
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


---Build type filter options
---@param overrides table|nil Label overrides
---@return table options Array of type option strings
function M.build_type_options(overrides)
	local labels = build_labels(overrides and overrides.labels)

	return {
		labels.all_types,
		labels.installed,
		labels.not_installed,
	}
end


---Build author filter options
---@param authors table Array of author names
---@param overrides table|nil Label overrides
---@return table options Array of author option strings
function M.build_author_options(authors, overrides)
	local labels = build_labels(overrides and overrides.labels)
	local options = {labels.all_authors}

	for _, author in ipairs(authors or {}) do
		table.insert(options, author)
	end

	return options
end


---Build tag filter options
---@param tags table Array of tag names
---@param overrides table|nil Label overrides
---@return table options Array of tag option strings
function M.build_tag_options(tags, overrides)
	local labels = build_labels(overrides and overrides.labels)
	local options = {labels.all_tags}

	for _, tag in ipairs(tags or {}) do
		table.insert(options, tag)
	end

	return options
end


---Create filters UI component
---@param params table Parameters: filter_type, filter_author, filter_tag, type_options, author_options, tag_options, on_type_change, on_author_change, on_tag_change, labels
---@return userdata component UI component
function M.create(params)
	local labels = build_labels(params and params.labels)

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.MEDIUM,
		children = {
			editor.ui.horizontal({
				spacing = editor.ui.SPACING.SMALL,
				children = {
					editor.ui.label({
						text = labels.type_label,
						color = editor.ui.COLOR.TEXT
					}),
					editor.ui.select_box({
						value = params.filter_type,
						options = params.type_options,
						on_value_changed = params.on_type_change
					})
				}
			}),
			editor.ui.horizontal({
				spacing = editor.ui.SPACING.SMALL,
				children = {
					editor.ui.label({
						text = labels.author_label,
						color = editor.ui.COLOR.TEXT
					}),
					editor.ui.select_box({
						value = params.filter_author,
						options = params.author_options,
						on_value_changed = params.on_author_change
					})
				}
			}),
			editor.ui.horizontal({
				spacing = editor.ui.SPACING.SMALL,
				children = {
					editor.ui.label({
						text = labels.tag_label,
						color = editor.ui.COLOR.TEXT
					}),
					editor.ui.select_box({
						value = params.filter_tag,
						options = params.tag_options,
						on_value_changed = params.on_tag_change
					})
				}
			})
		}
	})
end


return M

