extends Node

# REBOUND - Save Manager Autoload
# Handles persistent game state saving and loading to user:// storage.

const SAVE_PATH: String = "user://rebound_save.json"

func save_game(custom_data: Dictionary = {}) -> bool:
	var save_dict: Dictionary = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_level_id": GameManager.current_level_id,
		"credits": GameManager.credits,
		"inventory": InventoryManager.slots,
		"custom_data": custom_data
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false
		
	var json_string = JSON.stringify(save_dict, "\t")
	file.store_string(json_string)
	file.close()
	return true

func load_game() -> Dictionary:
	if not has_save():
		return {}
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
		
	var content = file.get_as_text()
	file.close()
	
	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(content)
	if error != OK:
		push_error("JSON Parse Error in save file: " + test_json_conv.get_error_message())
		return {}
		
	var data = test_json_conv.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("credits"):
			GameManager.credits = int(data["credits"])
		if data.has("current_level_id"):
			GameManager.current_level_id = str(data["current_level_id"])
		if data.has("inventory") and typeof(data["inventory"]) == TYPE_ARRAY:
			InventoryManager.slots = data["inventory"]
			InventoryManager.inventory_updated.emit()
		return data
	return {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
