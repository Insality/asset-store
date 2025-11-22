local M = {}


function M.create(params)
	local current_page = params.current_page or 1
	local total_pages = params.total_pages or 1
	local total_items = params.total_items or 0
	local items_per_page = params.items_per_page or 50
	local on_page_change = params.on_page_change or function() end

	-- Calculate range of items shown on current page
	local start_index = (current_page - 1) * items_per_page + 1
	local end_index = math.min(current_page * items_per_page, total_items)

	-- Build page info text: "Page 1 of 5 • Showing 1–50 of 300"
	local page_info_text
	if total_items > 0 then
		page_info_text = string.format("Page %d of %d • Showing %d–%d of %d", 
			current_page, total_pages, start_index, end_index, total_items)
	else
		page_info_text = "Page 1 of 1"
	end

	local children = {}

	-- Create button callbacks
	local function go_to_prev_page()
		on_page_change(current_page - 1)
	end

	local function go_to_next_page()
		on_page_change(current_page + 1)
	end

	-- Previous button with solid arrow (◀)
	local prev_button
	if current_page > 1 then
		prev_button = editor.ui.button({
			text = "◀",
			on_pressed = go_to_prev_page
		})
	else
		prev_button = editor.ui.button({
			text = "◀",
			enabled = false
		})
	end
	table.insert(children, prev_button)

	-- Page info label
	table.insert(children, editor.ui.label({
		text = page_info_text,
		color = editor.ui.COLOR.TEXT
	}))

	-- Next button with solid arrow (▶)
	local next_button
	if current_page < total_pages then
		next_button = editor.ui.button({
			text = "▶",
			on_pressed = go_to_next_page
		})
	else
		next_button = editor.ui.button({
			text = "▶",
			enabled = false
		})
	end
	table.insert(children, next_button)

	return editor.ui.horizontal({
		spacing = editor.ui.SPACING.MEDIUM,
		alignment = editor.ui.ALIGNMENT.CENTER,
		children = children
	})
end


return M

