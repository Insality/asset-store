local widget_card = require("asset_store.asset_store.ui.widget_card")


local M = {}


---No-op function
---@param ... any Arguments (ignored)
local function noop(...)
end


---Build widget card context
---@param overrides table|nil Context overrides
---@return table context Context table
local function build_context(overrides)
	return {
		on_install = overrides.on_install or noop,
		on_update = overrides.on_update or noop,
		on_version_change = overrides.on_version_change or noop,
		open_url = overrides.open_url or noop,
		labels = overrides.labels,
		get_version_options = overrides.get_version_options or function(_) return nil end,
		get_installed_version_name = overrides.get_installed_version_name or function(_) return nil end,
	}
end


---Create widget list UI component
---@param items table Array of asset items
---@param overrides table|nil Overrides: on_install, on_update, on_version_change, open_url, is_installed, can_update, get_version_options, get_installed_version_name, labels
---@return userdata component UI component
function M.create(items, overrides)
	local card_context = build_context(overrides or {})
	local is_installed = overrides and overrides.is_installed or function(_)
		return false
	end
	local can_update = overrides and overrides.can_update or function(_)
		return false
	end

	local widget_items = {}
	for i, item in ipairs(items) do
		local context = {
			on_install = function()
				card_context.on_install(item)
			end,
			on_update = function()
				card_context.on_update(item)
			end,
			on_version_change = function(item, url)
				card_context.on_version_change(item, url)
			end,
			open_url = card_context.open_url,
			labels = card_context.labels,
			is_installed = is_installed(item),
			can_update = can_update(item),
			version_options = card_context.get_version_options(item),
			installed_version_name = card_context.get_installed_version_name(item),
		}

		table.insert(widget_items, widget_card.create(item, context))

		-- Add separator between items (not after the last one)
		if i < #items then
			table.insert(widget_items, editor.ui.vertical({
				padding = editor.ui.PADDING.SMALL,
				children = {
					editor.ui.separator({})
				}
			}))
		end
	end

	---- Add empty spacers if there are few items to make dialog taller
	local min_items = 5
	if #items < min_items then
		for i = #items, min_items - 1 do
			for index = 1, 18 do
			table.insert(widget_items, editor.ui.vertical({ grow = true }))
			end
		end
	end

	return editor.ui.scroll({
		content = editor.ui.vertical({
			children = widget_items
		})
	})
end


return M
