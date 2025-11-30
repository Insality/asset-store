local locales = require("asset_store.asset_store.locales")


local DEFAULT_LABELS = {
	search_label = locales.get("search_label"),
	search_title = locales.get("search_title"),
	search_tooltip = locales.get("search_tooltip"),
	sort_label = locales.get("sort_label"),
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


---Create search UI component
---@param params table Parameters: search_query, on_search, sort_by, sort_options, on_sort_change, labels
---@return userdata component UI component
function M.create(params)
	local labels = build_labels(params and params.labels)

	local children = {
		editor.ui.label({
			text = labels.search_label,
			color = editor.ui.COLOR.TEXT
		}),
		editor.ui.string_field({
			value = params.search_query or "",
			on_value_changed = params.on_search,
			title = labels.search_title,
			tooltip = labels.search_tooltip,
			grow = true
		})
	}

	-- Add sort select_box if sort options are provided
	if params.sort_options and #params.sort_options > 0 then
		table.insert(children, editor.ui.label({
			text = labels.sort_label,
			color = editor.ui.COLOR.TEXT
		}))
		table.insert(children, editor.ui.select_box({
			value = params.sort_by or params.sort_options[1],
			options = params.sort_options,
			on_value_changed = params.on_sort_change
		}))
	end

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.MEDIUM,
		children = children
	})
end


return M

