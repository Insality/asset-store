local locales = require("asset_store.asset_store.locales")


local M = {}


---@class asset_store.config
---@field title string The title of the asset store displayed in the dialog window
---@field store_url string The URL of the asset store JSON file containing items list
---@field install_prefs_key string The preferences key used to store and retrieve the installation folder path
---@field asset_type string? The type of assets in this store: "folder" (default) or "dependency"
---@field info_url string? The URL of the info page, if nil then info button will be hidden
---@field info_button_label string? The label text for the info button (default: "Info")
---@field close_button_label string? The label text for the close button (default: "Close")
---@field add_asset_url string? The URL to open when "Add Asset" button is clicked (if nil, button will be hidden)
---@field add_asset_button_label string? The label text for the add asset button (auto-determined by asset_type if not provided)
---@field empty_search_message string? The message format to show when no items match search query (default: "No items found matching '%s'.")
---@field empty_filter_message string? The message to show when no items match current filters (default: "No items found matching the current filters.")
---@field labels table Table containing UI label overrides for different sections
---@field labels.search table? Overrides for search UI labels (search_label, search_title, search_tooltip)
---@field labels.filters table? Overrides for filter UI labels (type_label, author_label, tag_label, all_types, installed, not_installed, all_authors, all_tags)
---@field labels.widget_card table? Overrides for widget card labels (install_button, api_button, example_button, author_caption, installed_tag, tags_prefix, depends_prefix, size_separator, unknown_size)
---@field labels.settings table? Overrides for settings UI labels (install_label, install_title, install_tooltip)

---@class asset_store.item
---@field id string Unique identifier for the asset item
---@field version string Version string of the asset (e.g., "1.0", "2.3.1")
---@field title string Display name of the asset
---@field author string Author name of the asset
---@field description string Detailed description of the asset functionality
---@field api string? URL to API documentation for the asset
---@field author_url string? URL to author's profile or website
---@field image string? URL to the preview image for the asset
---@field manifest_url string URL to the asset's manifest JSON file
---@field zip_url string URL to download the asset as a ZIP file
---@field json_zip_url string URL to download the asset as base64-encoded JSON with file list
---@field sha256 string SHA256 hash of the ZIP file for integrity verification
---@field size number Size of the ZIP file in bytes
---@field depends string[] Array of dependency strings (format: "author:widget_id@version" or "author@widget_id" or "widget_id")
---@field tags string[] Array of tag strings for categorization and filtering


M.INFO_RESULT = "asset_store_open_info"
M.SUPPORT_RESULT = "asset_store_open_support"
M.ADD_ASSET_RESULT = "asset_store_open_add_asset"
M.DEFAULT_TITLE = locales.get("title")
M.DEFAULT_INFO_BUTTON = locales.get("info_button")
M.DEFAULT_CLOSE_BUTTON = locales.get("close_button")
M.DEFAULT_ADD_ASSET_BUTTON_LABEL = locales.get("add_asset_button")
M.DEFAULT_EMPTY_SEARCH_MESSAGE = locales.get("empty_search_message")
M.DEFAULT_EMPTY_FILTER_MESSAGE = locales.get("empty_filter_message")
M.DEFAULT_EMPTY_INSTALLED_MESSAGE = locales.get("empty_installed_message")
M.DEFAULT_SEARCH_LABELS = {
	search_tooltip = locales.get("search_tooltip")
}
M.ITEMS_PER_PAGE = 50


return M

