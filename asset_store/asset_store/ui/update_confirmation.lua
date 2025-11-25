local M = {}


---Show confirmation dialog for widget update
---@param item table - Widget item to update (must have id, title, version, and installed_version)
---@param on_confirm function - Callback when user confirms
---@param on_cancel function - Callback when user cancels
function M.show(item, on_confirm, on_cancel)
	local dialog_component = editor.ui.component(function(props)
		local widget_title = item.title or item.id
		local installed_version = props.installed_version or "unknown"
		local store_version = item.version or "unknown"

		return editor.ui.dialog({
			title = "Update Widget",
			content = editor.ui.vertical({
				spacing = editor.ui.SPACING.MEDIUM,
				padding = editor.ui.PADDING.MEDIUM,
				children = {
					editor.ui.paragraph({
						text = "All changes to this widget will be lost. Make sure you have everything saved in git.",
						color = editor.ui.COLOR.TEXT
					}),
					editor.ui.label({
						text = "Widget: " .. widget_title,
						color = editor.ui.COLOR.OVERRIDE
					}),
					editor.ui.label({
						text = "Current version: " .. tostring(installed_version),
						color = editor.ui.COLOR.HINT
					}),
					editor.ui.label({
						text = "New version: " .. tostring(store_version),
						color = editor.ui.COLOR.HINT
					}),
					editor.ui.paragraph({
						text = "Update widget?",
						color = editor.ui.COLOR.TEXT
					})
				}
			}),
			buttons = {
				editor.ui.dialog_button({
					text = "Cancel",
					cancel = true
				}),
				editor.ui.dialog_button({
					text = "Update",
					result = "update"
				})
			}
		})
	end)

	local result = editor.ui.show_dialog(dialog_component({
		installed_version = item.installed_version
	}))

	if result == "update" then
		on_confirm()
	else
		on_cancel()
	end
end


return M

