# GameUI - Main user interface for dungeon crawler
# Displays player stats, turn info, messages, and combat log

class_name GameUI
extends CanvasLayer

signal hp_updated(current: int, max: int)
signal turn_changed(state: int, player: String, enemy: String)
signal message_displayed(text: String)
signal combat_log_updated(damage: int, target: String)

@export var display_hp: bool = true
@export var display_turn: bool = true
@export var display_messages: bool = true
@export var display_combat_log: bool = true

var current_hp_label: Label = null
var max_hp_label: Label = null
var turn_label: Label = null
var message_label: Label = null
var combat_log_label: RichTextLabel = null

func _ready() -> void:
	# Initialize UI elements by name
	current_hp_label = get_node_or_null("HPLabel") as Label
	max_hp_label = get_node_or_null("MaxHPLabel") as Label
	turn_label = get_node_or_null("TurnLabel") as Label
	message_label = get_node_or_null("MessageLabel") as Label
	combat_log_label = get_node_or_null("CombatLog") as RichTextLabel

	# Connect to game systems
	ConnectToGameSystems()
	UpdateDisplay()

func ConnectToGameSystems() -> void:
	# Connect to player state changes
	var turn_manager = get_node("/root/TurnManager")
	if turn_manager != null:
		turn_manager.connect("turn_start", Callable(self, "_on_turn_start"))
		turn_manager.connect("turn_end", Callable(self, "_on_turn_end"))
		turn_manager.connect("action_consumed", Callable(self, "_on_action_consumed"))

	# Connect to combat events
	var combat_resolver = get_node("/root/CombatResolver")
	if combat_resolver != null:
		combat_resolver.connect("attack_resolved", Callable(self, "_on_attack_resolved"))

func _on_turn_start(new_state: int) -> void:
	if not display_turn:
		return

	var player_text: String = ""
	var enemy_text: String = ""

	match new_state:
		0:  # PLAYER_TURN
			turn_label.text = "TURNO: GIocatore"
			player_text = "Attivo"
			enemy_text = "In attesa"
		1:  # ENEMY_TURN
			turn_label.text = "TURNO: NEMICI"
			player_text = "In attesa"
			enemy_text = "Attivo"

	turn_changed.emit(new_state, player_text, enemy_text)

func _on_turn_end() -> void:
	# Turn ended - will transition to next
	pass

func _on_action_consumed() -> void:
	UpdateDisplay()

func _on_attack_resolved(result: Dictionary) -> void:
	if not display_combat_log:
		return

	var target: String = "Target"
	if result.has("target_killed") and result.target_killed:
		target = "Morte"

	combat_log_updated.emit(result.damage, target)

func UpdateDisplay() -> void:
	# Update HP display
	var turn_manager = get_node("/root/TurnManager")
	if turn_manager != null and turn_manager.player != null:
		var player: Node = turn_manager.player
		if player is Player:
			var p: Player = player as Player
			current_hp_label.text = str(p.current_hp)
			max_hp_label.text = str(p.max_hp)
			hp_updated.emit(p.current_hp, p.max_hp)

	# Update turn display
	if turn_manager != null:
		turn_label.text = "Turno: %d" % turn_manager.turn_count

func DisplayMessage(text: String, duration: float = 3.0) -> void:
	if message_label == null or not display_messages:
		return

	message_label.text = text

	# Clear message after duration
	call_deferred("_clear_message", duration)

func _clear_message(duration: float) -> void:
	message_label.text = ""

func DisplayCombatLog(damage: int, target_name: String) -> void:
	if combat_log_label == null:
		return

	var log_text: String = "[color=red]%s: -%d danni[/color]" % [target_name, damage]
	if combat_log_label.get_line_count() > 10:
		combat_log_label.clear()

	combat_log_label.append_text(log_text + "\n")

func GetPlayerHP() -> Dictionary:
	var turn_manager = get_node("/root/TurnManager")
	if turn_manager == null or turn_manager.player == null:
		return {"current": 0, "max": 100}

	var player: Node = turn_manager.player
	if player is Player:
		var p: Player = player as Player
		return {"current": p.current_hp, "max": p.max_hp}
	return {"current": 0, "max": 100}

func GetTurnInfo() -> Dictionary:
	var turn_manager = get_node("/root/TurnManager")
	if turn_manager == null:
		return {"count": 0, "state": 0}

	return {
		"count": turn_manager.turn_count,
		"state": turn_manager.current_state
	}