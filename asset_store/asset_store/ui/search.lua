local DEFAULT_LABELS = {
	search_label = "Search:",
	search_title = "Search:",
	search_tooltip = "Search for items",
	sort_label = "Sort:",
}


local M = {}


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

