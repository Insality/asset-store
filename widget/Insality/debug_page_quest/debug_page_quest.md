# widget.debug_page_quest API

> at widget/insality/debug_page_quest/debug_page_quest.lua

## Functions

- [render_properties_panel](#render_properties_panel)
- [render_active_quests_page](#render_active_quests_page)
- [add_render_quests](#add_render_quests)
- [render_completed_quests_page](#render_completed_quests_page)
- [render_available_quests_page](#render_available_quests_page)
- [render_all_quests_page](#render_all_quests_page)
- [render_quest_events_page](#render_quest_events_page)
- [render_quest_event_page](#render_quest_event_page)
- [get_quest_status](#get_quest_status)
- [render_quest_details_page](#render_quest_details_page)


### render_properties_panel

---
```lua
debug_page_quest:render_properties_panel(druid, properties_panel)
```

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_active_quests_page

---
```lua
debug_page_quest:render_active_quests_page(druid, properties_panel)
```

Render the active quests page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### add_render_quests

---
```lua
debug_page_quest:add_render_quests(druid, quests, properties_panel)
```

Render the quests page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `quests` *(table<string, any>)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_completed_quests_page

---
```lua
debug_page_quest:render_completed_quests_page(druid, properties_panel)
```

Render the completed quests page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_available_quests_page

---
```lua
debug_page_quest:render_available_quests_page(druid, properties_panel)
```

Render the available quests page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_all_quests_page

---
```lua
debug_page_quest:render_all_quests_page(druid, properties_panel)
```

Render the all quests page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_quest_events_page

---
```lua
debug_page_quest:render_quest_events_page(druid, properties_panel)
```

Render the quest events page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_quest_event_page

---
```lua
debug_page_quest:render_quest_event_page(druid, action, properties_panel)
```

Render the quest event page

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `action` *(string)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### get_quest_status

---
```lua
debug_page_quest:get_quest_status(quest, quest_id)
```

Get the quest status text

- **Parameters:**
	- `quest` *(quest)*:
	- `quest_id` *(string)*:

- **Returns:**
	- `` *(string)*:

### render_quest_details_page

---
```lua
debug_page_quest:render_quest_details_page(druid, quest_id, properties_panel)
```

Render the details page for a specific quest

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `quest_id` *(string)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

