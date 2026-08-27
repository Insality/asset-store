return {
	-- Constants
	title = "Asset Store",
	info_button = "Info",
	close_button = "Close",
	add_asset_button = "Add Asset",
	support_button = "Support",
	empty_search_message = "No items found matching '%s'.",
	empty_filter_message = "No items found matching the current filters.",
	empty_installed_message = "No installed items found. Select `All` in the `Type` filter to see all items.",

	-- Search
	search_label = "Search:",
	search_title = "Search:",
	search_tooltip = "Search by title, author, or description",
	sort_label = "Sort:",

	-- Filters
	filters_type_label = "Type:",
	filters_author_label = "Author:",
	filters_tag_label = "Tag:",
	filters_all_types = "All            ",
	filters_installed = "Installed",
	filters_not_installed = "Not Installed            ",
	filters_all_authors = "All Authors              ",
	filters_all_tags = "All Tags              ",

	-- Settings
	settings_install_label = "Installation Folder:",
	settings_install_title = "Installation Folder:",
	settings_install_tooltip = "The folder to install the assets to",
	settings_button = "Settings",
	settings_window_title = "Asset Store Settings",
	settings_use_version_files = "Write .version files for tracking asset updates",
	settings_show_preview_images = "Show asset preview images in list",
	settings_show_tags = "Show tags in list",
	settings_items_per_page_label = "Cards per page:",
	settings_cancel_button = "Cancel",
	settings_save_button = "Save",

	-- Store Selector
	store_selector_store_label = "Store:",

	-- Widget Card
	widget_card_install_button = "Install",
	widget_card_update_button = "Update",
	widget_card_api_button = "API",
	widget_card_example_button = "Example",
	widget_card_author_caption = "Author",
	widget_card_installed_tag = "Version",
	widget_card_tags_prefix = "Tags: ",
	widget_card_depends_prefix = "Depends: ",
	widget_card_size_separator = "• ",
	widget_card_unknown_size = "Unknown size",
	widget_card_no_description = "No description available",
	widget_card_version_needs = " — needs Defold %s",
	widget_card_latest_needs_defold = "⚠ %s needs Defold %s, you have %s",
	widget_card_requires_defold = "⚠ Requires Defold %s, you have %s",

	-- Sort Options
	sort_asset_name = "Asset Name",
	sort_author = "Author",
	sort_stars = "Stars",
	sort_size = "Size",

	-- Pagination
	pagination_page_info = "Page %d of %d • Showing %d–%d of %d",
	pagination_page_info_single = "Page 1 of 1",
	pagination_prev_button = "◀",
	pagination_next_button = "▶",

	-- Update Confirmation
	update_confirmation_title = "Update Widget",
	update_confirmation_warning = "All changes to this widget will be lost. Make sure you have everything saved in git.",
	update_confirmation_widget_label = "Widget: %s",
	update_confirmation_current_version = "Current version: %s",
	update_confirmation_new_version = "New version: %s",
	update_confirmation_question = "Update widget?",
	update_confirmation_cancel = "Cancel",
	update_confirmation_update = "Update",

	-- Messages
	messages_loading = "Loading...",
	messages_loading_store = "Loading store: %s...",
	messages_success = "Success: %s",
	messages_error = "Error: %s",
	messages_error_failed_load_store = "Error: Failed to load store: %s",
	messages_error_could_not_find_url = "Error: Could not find URL for version: %s",
	messages_version_not_supported = "Version %s needs Defold %s, you have %s",
	messages_no_compatible_version = "No version compatible with Defold %s",
	messages_installation_successful = "Installation successful",
	messages_installation_failed = "Installation failed",
	messages_update_successful = "Update successful",
	messages_update_failed = "Update failed",
	messages_update_cancelled = "Update cancelled by user",
	messages_cannot_update = "Cannot update: %s",
	messages_removal_successful = "Removal successful",
	messages_removal_failed = "Removal failed",
	messages_remove_not_supported = "Remove not supported for asset type: %s",

	-- Actions
	actions_delete = "delete",
}
