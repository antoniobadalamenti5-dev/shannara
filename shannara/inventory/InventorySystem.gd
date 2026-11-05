# Inventory system singleton for player item management

extends Node

var active_items: Dictionary = {}

func _ready() -> void:
	add_item("healing_potion", 1)

func add_item(item_id: String, quantity: int = 1) -> void:
	if active_items.has(item_id):
		active_items[item_id] = active_items[item_id] + quantity
	else:
		active_items[item_id] = quantity

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not active_items.has(item_id):
		return false
	if active_items[item_id] < quantity:
		return false
	active_items[item_id] = active_items[item_id] - quantity
	if active_items[item_id] <= 0:
		active_items.erase(item_id)
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	if not active_items.has(item_id):
		return false
	return active_items[item_id] >= quantity

func get_item_count(item_id: String) -> int:
	if active_items.has(item_id):
		return active_items[item_id]
	return 0

func use_item(item_id: String) -> bool:
	if not has_item(item_id, 1):
		return false

	var item_database = get_node("/root/ItemDatabase")
	var item = item_database.get_item(item_id)
	var item_type: String = item.get("type", "")

	if item_type == "consumable":
		var hp_restore: int = item.get("hp_restore", 0)
		var players: Array = get_tree().get_nodes_in_group("players")
		var player: Node = players[0] if players.size() > 0 else null
		if player != null and player.is_alive():
			player.heal(hp_restore)
			remove_item(item_id, 1)
			return true
	elif item_type == "weapon":
		remove_item(item_id, 1)
		return true

	return false

func consume_item_on_pickup(item_id: String) -> void:
	var tm: Node = get_node("/root/TurnManager")
	tm.consume_action()