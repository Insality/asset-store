local M = {}


M.PREF_USE_VERSION_FILES = "asset_store.use_version_files"
M.PREF_SHOW_PREVIEW_IMAGES = "asset_store.show_preview_images"
M.PREF_ITEMS_PER_PAGE = "asset_store.items_per_page"
M.PREF_SHOW_DEPENDENCIES_TAGS = "asset_store.show_dependencies_tags"

M.DEFAULT_USE_VERSION_FILES = true
M.DEFAULT_SHOW_PREVIEW_IMAGES = true
M.DEFAULT_ITEMS_PER_PAGE = 30
M.DEFAULT_SHOW_DEPENDENCIES_TAGS = true

M.ITEMS_PER_PAGE_OPTIONS = { 15, 30, 50, 100 }


local function is_allowed_items_per_page(value)
	for _, option in ipairs(M.ITEMS_PER_PAGE_OPTIONS) do
		if option == value then
			return true
		end
	end

	return false
end


function M.get_use_version_files()
	local value = editor.prefs.get(M.PREF_USE_VERSION_FILES)
	if value == nil then
		return M.DEFAULT_USE_VERSION_FILES
	end

	return value == true
end


function M.get_show_preview_images()
	local value = editor.prefs.get(M.PREF_SHOW_PREVIEW_IMAGES)
	if value == nil then
		return M.DEFAULT_SHOW_PREVIEW_IMAGES
	end

	return value == true
end


function M.get_show_dependencies_tags()
	local value = editor.prefs.get(M.PREF_SHOW_DEPENDENCIES_TAGS)
	if value == nil then
		return M.DEFAULT_SHOW_DEPENDENCIES_TAGS
	end

	return value == true
end


function M.get_items_per_page()
	local value = tonumber(editor.prefs.get(M.PREF_ITEMS_PER_PAGE))
	if not value or not is_allowed_items_per_page(value) then
		return M.DEFAULT_ITEMS_PER_PAGE
	end

	return value
end


return M
