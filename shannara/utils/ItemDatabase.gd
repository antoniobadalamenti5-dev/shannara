# ItemDatabase singleton for loading item definitions from JSON

extends Node

var items: Dictionary = {}

func _ready() -> void:
	_load_items()

func _load_items() -> void:
	var file: FileAccess = FileAccess.open("res://items/item_database.json", FileAccess.READ)
	if file == null:
		push_error("Impossibile aprire item_database.json")
		return
	var json_text: String = file.get_as_text()
	file.close()
	var json_instance = JSON.new()
	var parse_result = json_instance.parse(json_text)
	# parse() returns int (0=OK), not an object with error property
	if parse_result != OK:
		push_error("Failed to parse item_database.json: %d" % parse_result)
		return
	var data = json_instance.get_data()
	if typeof(data) == TYPE_DICTIONARY and data.has("items"):
		items = data["items"]
	else:
		push_error("item_database.json non ha chiave 'items'")

func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}

func get_all_items() -> Dictionary:
	return items

func get_item_name(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return item.get("name", "Unknown")

func get_item_type(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	return item.get("type", "unknown")

func get_hp_restore(item_id: String) -> int:
	var item: Dictionary = get_item(item_id)
	return item.get("hp_restore", 0)

func get_atk_bonus(item_id: String) -> int:
	var item: Dictionary = get_item(item_id)
	return item.get("atk_bonus", 0)