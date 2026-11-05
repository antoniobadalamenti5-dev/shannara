# Player actor class
# Player character with 100 HP, can act during player turn

class_name Player
extends ActorController

func _init() -> void:
	max_hp = 100
	current_hp = 100

func can_act() -> bool:
	return is_alive() and TurnManager.is_player_turn()