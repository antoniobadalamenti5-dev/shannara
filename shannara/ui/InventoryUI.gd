# InventoryUI - Toggleable inventory panel
# Listens to InputManager.inventory_requested and renders active items.
# Consumes the player turn on open/close so the UI is a real game action.

class_name InventoryUI
extends CanvasLayer

signal inventory_opened()
signal inventory_closed()

@export var panel_width: int = 320
@export var panel_height: int = 240

var _inventory_system: Node = null
var _is_open: bool = false

# Root centrato: tutti i figli usano anchor/offset relativi a questo rettangolo.
# Mettere i Control direttamente sotto il CanvasLayer costringe a calcolare le
# coordinate rispetto al viewport, ed è lì che la lista era collassata a
# altezza zero (anchor_top 0.5 contro anchor_bottom 0).
var _panel: Control = null
var _items_list: VBoxContainer = null


func _ready() -> void:
	visible = false
	# Aggiungi al gruppo per la gestione segnali
	add_to_group("inventory_ui")
	_inventory_system = get_node_or_null("/root/InventorySystem")
	if _inventory_system == null:
		push_error("[InventorySystem] InventorySystem singleton non trovato!")
		return

	_build_ui()
	_connect_signals()
	print("[InventoryUI] _ready() completato")


func _build_ui() -> void:
	# Pannello radice: 320x240 centrato sul viewport. Gli anchor 0.5 su tutti e
	# quattro i lati con offset simmetrici danno un rettangolo di dimensione
	# fissa indipendente dalla risoluzione della finestra.
	_panel = Control.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -panel_width * 0.5
	_panel.offset_right = panel_width * 0.5
	_panel.offset_top = -panel_height * 0.5
	_panel.offset_bottom = panel_height * 0.5
	add_child(_panel)

	# Background scuro che copre l'intero pannello
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.1, 0.1, 0.15, 0.95)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(background)

	# Titolo
	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "INVENTARIO"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	title_label.position = Vector2(0, 12)
	title_label.size = Vector2(panel_width, 28)
	_panel.add_child(title_label)

	# Lista item: area centrale tra titolo e pulsante Chiudi
	_items_list = VBoxContainer.new()
	_items_list.name = "ItemsList"
	_items_list.position = Vector2(16, 52)
	_items_list.size = Vector2(panel_width - 32, panel_height - 52 - 60)
	_items_list.add_theme_constant_override("separation", 8)
	_panel.add_child(_items_list)

	# Pulsante di chiusura ancorato in basso nel pannello
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Chiudi (I)"
	close_button.position = Vector2(12, panel_height - 48)
	close_button.size = Vector2(panel_width - 24, 36)
	close_button.pressed.connect(_on_close_pressed)
	_panel.add_child(close_button)


func _connect_signals() -> void:
	var input_manager = get_node_or_null("/root/InputManager")
	if input_manager != null:
		if input_manager.has_signal("inventory_requested"):
			input_manager.connect("inventory_requested", Callable(self, "_on_inventory_requested"))
			print("[InventoryUI] Connesso a InputManager.inventory_requested")
		else:
			push_error("[InventoryUI] InputManager non ha il segnale inventory_requested!")
	else:
		push_error("[InventoryUI] InputManager non trovato!")


# Public method to open inventory (called from GameManager)
func open_inventory() -> void:
	"""Open inventory programmatically. Does NOT consume turn."""
	print("[InventoryUI] open_inventory() called, _is_open=%s" % _is_open)
	if _is_open:
		return
	_open_inventory()

func _on_inventory_requested() -> void:
	print("[InventoryUI] _on_inventory_requested() CALLED, _is_open=%s" % _is_open)
	if _is_open:
		print("[InventoryUI] Inventory was open, calling _close_inventory() from _on_inventory_requested")
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	_is_open = true
	visible = true
	_refresh_items()
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager != null and turn_manager.is_player_turn():
		# La pausa va settata PRIMA di consume_action(): consume_action emette
		# action_consumed, GameManager la raccoglie in synchronia e chiama
		# end_turn(). Se inventory_paused fosse ancora false, quel end_turn
		# aprirebbe il turno nemico con la finestra ancora aperta.
		turn_manager.inventory_paused = true
		turn_manager.consume_action()
		print("[InventoryUI] Turno consumato, inventory_paused=true")
	inventory_opened.emit()
	print("[InventoryUI] Inventario aperto - is_open=%s" % _is_open)


func _close_inventory() -> void:
	print("[InventoryUI] _close_inventory() CALLED! _is_open=%s" % _is_open)
	if not _is_open:
		print("[InventoryUI] WARN: _close_inventory() called but inventory not open - ignoring")
		return
	_is_open = false
	visible = false
	inventory_closed.emit()
	_release_turn()
	print("[InventoryUI] Inventario chiuso")


# Sblocca il turno che _open_inventory aveva messo in pausa.
func _release_turn() -> void:
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager == null:
		return
	turn_manager.inventory_paused = false
	# end_turn differito: _close_inventory può essere chiamata dall'interno di
	# una callback di segnale, e avviare il turno nemico in quella pila
	# rientrerebbe nel flusso dei segnali a iterazione in corso.
	turn_manager.call_deferred("end_turn")


func _on_close_pressed() -> void:
	print("[InventoryUI] _on_close_pressed() CALLED - close button clicked")
	_close_inventory()


func _refresh_items() -> void:
	print("[InventoryUI] Refresh items - visible=%s" % visible)
	# Pulisci i figli esistenti
	for child in _items_list.get_children():
		child.queue_free()

	if _inventory_system == null:
		print("[InventoryUI] ERRORE: refresh con _inventory_system null!")
		return

	var items: Dictionary = _inventory_system.active_items
	print("[InventoryUI] Item count: %d" % items.size())
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventario vuoto"
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_items_list.add_child(empty_label)
		return

	for item_id in items.keys():
		var item_count: int = items[item_id]
		var item_database = get_node_or_null("/root/ItemDatabase")
		var display_name: String = item_id
		if item_database != null:
			var item_data = item_database.get_item(item_id)
			if not item_data.is_empty():
				display_name = item_data.get("name", item_id)

		var row = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var count_label = Label.new()
		count_label.text = "x%d" % item_count
		count_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		row.add_child(count_label)

		# Use button
		var use_btn = Button.new()
		use_btn.text = "Usa"
		use_btn.pressed.connect(_on_use_item.bind(item_id))
		print("[InventoryUI] Created Use button for %s - signal connected" % item_id)
		# Assicura che il pulsante possa ricevere l'input
		use_btn.focus_mode = Control.FOCUS_ALL
		row.add_child(use_btn)

		_items_list.add_child(row)


func _on_use_item(item_id: String) -> void:
	print("[InventoryUI] _on_use_item() CALLED with item_id=%s" % item_id)
	print("[InventoryUI] _is_open=%s, visible=%s" % [_is_open, visible])
	if _inventory_system == null:
		print("[InventoryUI] ERRORE: _inventory_system è null!")
		return

	print("[InventoryUI] Item count: %d" % _inventory_system.get_item_count(item_id))

	var result: Dictionary = _inventory_system.use_item(item_id)
	print("[InventoryUI] Result: success=%s, message=%s, consumed=%s" % [result.success, result.message, result.consumed])
	if result.success:
		print("[InventoryUI] %s" % result.message)
		_refresh_items()
		if result.consumed:
			print("[InventoryUI] Chiudo inventario dopo consumo")
			_close_inventory()
	else:
		print("[InventoryUI] Impossibile usare %s: %s" % [item_id, result.message])
		# Mostra messaggio di stato
		_show_status_message(result.message)


func _show_status_message(message: String) -> void:
	"""Mostra un messaggio temporaneo nell'inventario quando l'azione fallisce."""
	var status_label = Label.new()
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.anchor_left = 0.5
	status_label.anchor_bottom = 0
	status_label.offset_left = -panel_width * 0.5 + 20
	status_label.offset_bottom = 180
	status_label.offset_top = 160
	status_label.offset_right = panel_width * 0.5 - 20
	_items_list.add_child(status_label)

	# Rimuovi il messaggio dopo 2 secondi
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(func():
		status_label.queue_free()
		timer.queue_free()
	)
	_items_list.add_child(timer)