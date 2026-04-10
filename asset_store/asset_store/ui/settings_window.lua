local locales = require("asset_store.asset_store.locales")
local settings = require("asset_store.asset_store.settings")

local M = {}


local function bool_or_default(value, default_value)
	if value == nil then
		return default_value
	end

	return value == true
end


function M.open()
	local dialog_component = editor.ui.component(function(props)
		local use_version_files, set_use_version_files = editor.ui.use_state(bool_or_default(editor.prefs.get(settings.PREF_USE_VERSION_FILES), settings.DEFAULT_USE_VERSION_FILES))
		local show_preview_images, set_show_preview_images = editor.ui.use_state(bool_or_default(editor.prefs.get(settings.PREF_SHOW_PREVIEW_IMAGES), settings.DEFAULT_SHOW_PREVIEW_IMAGES))
		local show_tags, set_show_tags = editor.ui.use_state(bool_or_default(editor.prefs.get(settings.PREF_SHOW_DEPENDENCIES_TAGS), settings.DEFAULT_SHOW_DEPENDENCIES_TAGS))
		local items_per_page, set_items_per_page = editor.ui.use_state(tostring(settings.get_items_per_page()))

		return editor.ui.dialog({
			title = locales.get("settings_window_title"),
			content = editor.ui.vertical({
				spacing = editor.ui.SPACING.MEDIUM,
				padding = editor.ui.PADDING.MEDIUM,
				children = {
					editor.ui.check_box({
						value = use_version_files,
						on_value_changed = set_use_version_files,
						text = locales.get("settings_use_version_files")
					}),
					editor.ui.check_box({
						value = show_preview_images,
						on_value_changed = set_show_preview_images,
						text = locales.get("settings_show_preview_images")
					}),
					editor.ui.check_box({
						value = show_tags,
						on_value_changed = set_show_tags,
						text = locales.get("settings_show_tags")
					}),
					editor.ui.horizontal({
						spacing = editor.ui.SPACING.MEDIUM,
						children = {
							editor.ui.label({
								text = locales.get("settings_items_per_page_label"),
								color = editor.ui.COLOR.TEXT
							}),
							editor.ui.select_box({
								value = items_per_page,
								options = { "15", "30", "50", "100" },
								on_value_changed = set_items_per_page
							})
						}
					})
				}
			}),
			buttons = {
				editor.ui.dialog_button({
					text = locales.get("settings_cancel_button"),
					cancel = true
				}),
				editor.ui.dialog_button({
					text = locales.get("settings_save_button"),
					default = true,
					result = {
						use_version_files = use_version_files,
						show_preview_images = show_preview_images,
						show_tags = show_tags,
						items_per_page = items_per_page,
					}
				})
			}
		})
	end)

	local result = editor.ui.show_dialog(dialog_component({}))
	if not result then
		return false
	end

	editor.prefs.set(settings.PREF_USE_VERSION_FILES, result.use_version_files)
	editor.prefs.set(settings.PREF_SHOW_PREVIEW_IMAGES, result.show_preview_images)
	editor.prefs.set(settings.PREF_SHOW_DEPENDENCIES_TAGS, result.show_tags)
	editor.prefs.set(settings.PREF_ITEMS_PER_PAGE, tonumber(result.items_per_page))

	return true
end


return M
