local M = {}


---Build dialog UI component
---@param params table Parameters: title, children, buttons, spacing, padding, width, height, resizable
---@return userdata dialog UI dialog component
function M.build(params)
	return editor.ui.dialog({
		title = params.title or "Asset Store",
		width = params.width or 800,
		height = params.height or 1100,
		resizable = params.resizable ~= false,
		grow = true,
		content = editor.ui.vertical({
			spacing = params.spacing or editor.ui.SPACING.MEDIUM,
			padding = params.padding or editor.ui.PADDING.SMALL,
			children = params.children or {},
			grow = true,
		}),
		buttons = params.buttons or {}
	})
end


return M

