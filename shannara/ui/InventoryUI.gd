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

var _panel_container: PanelContainer = null
var _title_label: Label = null
var _close_button: Button = null
var _items_grid: GridContainer = null


func _ready() -> void:
	visible = false
	_inventory_system = get_node_or_null("/root/InventorySystem")
	if _inventory_system == null:
		push_error("[InventorySystem] InventorySystem singleton non trovato!")
		return

	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	# Panel container - centered with background
	_panel_container = PanelContainer.new()
	_panel_container.name = "InventoryPanel"
	_panel_container.anchor_left = 0.5
	_panel_container.anchor_top = 0.5
	_panel_container.anchor_right = 0.5
	_panel_container.anchor_bottom = 0.5
	_panel_container.offset_left = -panel_width * 0.5
	_panel_container.offset_right = panel_width * 0.5
	_panel_container.offset_top = -panel_height * 0.5
	_panel_container.offset_bottom = panel_height * 0.5
	_panel_container.modulate = Color(0.1, 0.1, 0.15, 0.95)
	add_child(_panel_container)

	# Layout container inside the panel
	var vbox = VBoxContainer.new()
	vbox.setanchors(PRESET_TOP_WIDE)
	vbox.content_margin_top = 10
	vbox.content_margin_bottom = 10
	vbox.content_margin_left = 10
	vbox.content_margin_right = 10
	_panel_container.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "INVENTARIO"
	_title_label.custom_fonts.font = load("res://fonts/DejaVuSans.ttf") if FileAccess.file_exists("res://fonts/DejaVuSans.ttf") else null
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	vbox.add_child(_title_label)

	# Items grid
	_items_grid = GridContainer.new()
	_items_grid.name = "ItemsGrid"
	_items_grid.columns = 2
	_items_grid.custom_constants.separation = 8
	vbox.add_child(_items_grid)

	# Close button
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "Chiudi (I)"
	vbox.add_child(_close_button)
	_close_button.pressed.connect(_on_close_pressed)


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


func _on_inventory_requested() -> void:
	if _is_open:
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	_is_open = true
	visible = true
	_refresh_items()
	# Consuma il turno: aprire l'inventario è un'azione
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager != null and turn_manager.is_player_turn():
		turn_manager.consume_action()
	inventory_opened.emit()
	print("[InventoryUI] Inventario aperto")


func _close_inventory() -> void:
	_is_open = false
	visible = false
	inventory_closed.emit()
	print("[InventoryUI] Inventario chiuso")


func _on_close_pressed() -> void:
	_close_inventory()


func _refresh_items() -> void:
	# Pulisci i figli esistenti
	for child in _items_grid.get_children():
		child.queue_free()

	if _inventory_system == null:
		return

	var items: Dictionary = _inventory_system.active_items
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventario vuoto"
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_items_grid.add_child(empty_label)
		return

	# Header row come HBox
	var header = HBoxContainer.new()
	var header_name = Label.new()
	header_name.text = "Item"
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	header.add_child(header_name)

	var header_count = Label.new()
	header_count.text = "Qty"
	header_count.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	header.add_child(header_count)

	_items_grid.add_child(header)

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
		row.add_child(use_btn)

		_items_grid.add_child(row)


func _on_use_item(item_id: String) -> void:
	if _inventory_system == null:
		return
	var success: bool = _inventory_system.use_item(item_id)
	if success:
		print("[InventoryUI] Usato: %s" % item_id)
		_refresh_items()
	else:
		print("[InventoryUI] Impossibile usare: %s" % item_id)