# ItemDatabase singleton for loading item definitions from JSON

class_name ItemDatabase
extends Node

var items: Dictionary = {}

func _ready() -> void:
	_load_items()

func _load_items() -> void:
	var file := FileAccess.open("res://items/item_database.json", FileAccess.READ)
	if file != null:
		var json_text := file.get_as_text()
		var parsed := JSON.parse(json_text)
		if parsed.error == OK:
			items = parsed.result.items
		else:
			push_error("Failed to parse item_database.json: %s" % parsed.error_string)
		file.close()

func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}

func get_all_items() -> Dictionary:
	return items

func get_item_name(item_id: String) -> String:
	var item := get_item(item_id)
	return item.get("name", "Unknown")

func get_item_type(item_id: String) -> String:
	var item := get_item(item_id)
	return item.get("type", "unknown")

func get_hp_restore(item_id: String) -> int:
	var item := get_item(item_id)
	return item.get("hp_restore", 0)

func get_atk_bonus(item_id: String) -> int:
	var item := get_item(item_id)
	return item.get("atk_bonus", 0)