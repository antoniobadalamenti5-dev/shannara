# Inventory system singleton for player item management

class_name InventorySystem
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

	var item := ItemDatabase.get_item(item_id)
	var item_type := item.get("type", "")

	if item_type == "consumable":
		var hp_restore := item.get("hp_restore", 0)
		var player := get_tree().get_root().find_node("Player", true, false)
		if player != null and player.is_alive():
			player.heal(hp_restore)
			remove_item(item_id, 1)
			return true
	elif item_type == "weapon":
		# Weapon equipping logic would go here
		remove_item(item_id, 1)
		return true

	return false

func consume_item_on_pickup(item_id: String) -> void:
	# Mark item as consumed when picked up (1 turn action)
	TurnManager.consume_action()