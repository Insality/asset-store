local locales = require("asset_store.asset_store.locales")


local M = {}


---Create pagination UI component
---@param params table Parameters: current_page, total_pages, total_items, items_per_page, on_page_change
---@return userdata component UI component
function M.create(params)
	local current_page = params.current_page or 1
	local total_pages = params.total_pages or 1
	local total_items = params.total_items or 0
	local items_per_page = params.items_per_page or 50
	local on_page_change = params.on_page_change or function(page_index) end

	-- Calculate range of items shown on current page
	local start_index = (current_page - 1) * items_per_page + 1
	local end_index = math.min(current_page * items_per_page, total_items)

	-- Build page info text: "Page 1 of 5 • Showing 1–50 of 300"
	local page_info_text
	if total_items > 0 then
		page_info_text = locales.get("pagination_page_info", current_page, total_pages, start_index, end_index, total_items)
	else
		page_info_text = locales.get("pagination_page_info_single")
	end

	local children = {}

	-- Previous button with solid arrow (◀)
	table.insert(children, editor.ui.button({
		text = locales.get("pagination_prev_button"),
		on_pressed = function() on_page_change(current_page - 1) end,
		enabled = current_page > 1
	}))

	-- Page info label
	table.insert(children, editor.ui.label({
		text = page_info_text,
		color = editor.ui.COLOR.TEXT
	}))

	-- Next button with solid arrow (▶)
	table.insert(children, editor.ui.button({
		text = locales.get("pagination_next_button"),
		on_pressed = function() on_page_change(current_page + 1) end,
		enabled = current_page < total_pages
	}))

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.MEDIUM,
		alignment = editor.ui.ALIGNMENT.CENTER,
		children = children
	})
end


return M

