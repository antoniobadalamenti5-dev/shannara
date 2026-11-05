# HealingPotion pickup item
# Area2D node that adds to inventory when player enters

class_name HealingPotion
extends Area2D

signal pickuped(player: Node)

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body is Player:
		var player: Player = body as Player

		# Add to inventory
		var inventory_system = get_node("/root/InventorySystem")
		inventory_system.add_item("healing_potion")

		# Consume 1 turn for pickup
		var turn_manager = get_node("/root/TurnManager")
		turn_manager.consume_action()

		# Signal pickup (could be used for visual feedback)
		pickuped.emit(player)

		# Remove from scene
		queue_free()