# GridSystem singleton for 3D coordinate management
# Manages the dungeon grid with elevation levels
#
# Modelo di elevazione: l'indice di layer E l'elevazione (autoritativo).
# grid[y][x][elevation + 1] contiene la cella a quota `elevation` (-1 fossato,
# 0 piano, 1 piattaforma rialzata). Il campo cell.elevation coincide sempre
# con l'indice di layer: il layout genera i tratti su layer diversi, non
# modificando il campo delle celle a layer 0.

extends Node

signal move_requested(cell_x, cell_y, elevation_from, elevation_to)
signal attack_requested(attacker_x, attacker_y, target_x, target_y)

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20
const MAX_ELEVATION: int = 2

var grid: Array = []  # [y][x][elevation] -> GridCell

func _ready() -> void:
	_initialize_grid()
	generate_basic_layout()

# Genera un layout semplice: muri al bordo, un fossato valicabile, un ponte
# e una piattaforma rialzata (layer 1) raggiungibile dai bordi.
func generate_basic_layout() -> void:
	# 1. Muri sul perimetro (layer 0)
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var border: bool = x == 0 or y == 0 or x == GRID_WIDTH - 1 or y == GRID_HEIGHT - 1
			if border:
				_set_cell(x, y, 0, GridCell.TERRAIN_WALL, false)
	# 2. Fossato (quota -1) a colonna x=13: la fossa è transitabile, la quota 0
	#    sopra la fossa è spuntoni non transitabili.
	for y in range(2, 18):
		_set_cell(13, y, -1, GridCell.TERRAIN_FLOOR, true)   # fondo del fossato
		_set_cell(13, y, 0, GridCell.TERRAIN_SPIKE, false)   # spuntoni in superficie
	# 3. Ponte (transitabile) che attraversa gli spuntoni a y=10
	for x in range(11, 16):
		_set_cell(x, 10, 0, GridCell.TERRAIN_BRIDGE, true)
	# 4. Piattaforma rialzata a quota 1 (x3..7, y3..7): calpestabile salendo
	#    di 1 dal bordo, con penalità di movimento (Task 2.3).
	for y in range(3, 8):
		for x in range(3, 8):
			_set_cell(x, y, 1, GridCell.TERRAIN_FLOOR, true)

func _set_cell(x: int, y: int, elevation: int, terrain_type: int, walkable: bool) -> void:
	var cell: GridCell = get_cell_at(x, y, elevation)
	if cell != null:
		cell.terrain_type = terrain_type
		cell.walkable = walkable

func _initialize_grid() -> void:
	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			var elevation_row: Array = []
			for z in range(MAX_ELEVATION + 1):  # 0, 1, 2
				var cell: GridCell = GridCell.new()
				cell.x = x
				cell.y = y
				cell.elevation = z - 1  # -1, 0, 1
				# Solo il piano (0) è calpestabile di default: quota 1 è
				# "piattaforma" e -1 "vuoto/fossato", attivati dal layout.
				cell.walkable = (z == 1)
				elevation_row.append(cell)
			row.append(elevation_row)
		grid.append(row)

func get_cell_at(x: int, y: int, elevation: int) -> GridCell:
	if x < 0 or y < 0 or x >= GRID_WIDTH or y >= GRID_HEIGHT:
		return null
	if elevation < -1 or elevation > 1:
		return null
	return grid[y][x][elevation + 1]  # offset for -1 base

func is_cell_walkable(x: int, y: int, elevation: int) -> bool:
	var cell: GridCell = get_cell_at(x, y, elevation)
	if cell == null:
		return false
	return cell.walkable and cell.occupant == null

func set_occupant(x: int, y: int, elevation: int, occupant: Node) -> void:
	var cell: GridCell = get_cell_at(x, y, elevation)
	if cell != null:
		cell.occupant = occupant

func place_terrain(x: int, y: int, elevation: int, terrain_type: int) -> void:
	var cell: GridCell = get_cell_at(x, y, elevation)
	if cell != null:
		cell.terrain_type = terrain_type
		if terrain_type == 3:  # TerrainType.WALL
			cell.walkable = false

# Regole di movimento (Task 2.2 + 2.3):
# - la cella di arrivo deve esistere ed essere calpestabile
# - un passo ortogonale di 1 cella (niente diagonali, niente salti multipli)
# - cambio quota di 1 ammesso in diagonale-no: solo sul posto (scala) o su
#   un passo ortogonale adiacente; delta > 1 vietato
func can_move_to(from_x: int, from_y: int, from_elev: int, to_x: int, to_y: int, to_elev: int) -> bool:
	if not is_cell_walkable(to_x, to_y, to_elev):
		return false
	var dx: int = absi(to_x - from_x)
	var dy: int = absi(to_y - from_y)
	var de: int = absi(to_elev - from_elev)
	if de > 1:
		return false
	var step: int = dx + dy  # distanza di Manhattan sul piano
	if step == 0:
		return de == 1      # cambio quota sul posto (scala)
	if step == 1 and de <= 1:
		return true         # passo ortogonale, con o senza cambio quota
	return false            # diagonali e spostamenti multipli non ammessi

# Restituisce i vicini calpestabili in formato [x, y, elevation].
# Include i cambi quota di 1 (scale/ponti/fossato) come da regole 2.3.
func get_neighbors(x: int, y: int, elevation: int) -> Array:
	var neighbors: Array = []
	var directions: Array = [
		Vector2i(0, -1),  # up
		Vector2i(0, 1),   # down
		Vector2i(-1, 0),  # left
		Vector2i(1, 0)    # right
	]

	for dir in directions:
		var nx: int = x + dir.x
		var ny: int = y + dir.y
		if is_cell_walkable(nx, ny, elevation):
			neighbors.append([nx, ny, elevation])
		# Transizioni di quota: solo di 1 livello (norma 2.3)
		if elevation < 1 and is_cell_walkable(nx, ny, elevation + 1):
			neighbors.append([nx, ny, elevation + 1])
		if elevation > -1 and is_cell_walkable(nx, ny, elevation - 1):
			neighbors.append([nx, ny, elevation - 1])
	# Cambio quota sul posto (scala/pozzo)
	if elevation < 1 and is_cell_walkable(x, y, elevation + 1):
		neighbors.append([x, y, elevation + 1])
	if elevation > -1 and is_cell_walkable(x, y, elevation - 1):
		neighbors.append([x, y, elevation - 1])

	return neighbors

# BFS sul piano + quote: su griglia non pesata garantisce il cammino minimo.
# Restituisce array di [x, y, elevation] da start (incluso) a target (incluso),
# oppure [] se non c'è percorso.
func find_path(start_x: int, start_y: int, start_elev: int, target_x: int, target_y: int, target_elev: int) -> Array:
	if get_cell_at(start_x, start_y, start_elev) == null:
		return []
	if get_cell_at(target_x, target_y, target_elev) == null:
		return []

	var start_key: String = "%d,%d,%d" % [start_x, start_y, start_elev]
	var goal_key: String = "%d,%d,%d" % [target_x, target_y, target_elev]
	if start_key == goal_key:
		return [[start_x, start_y, start_elev]]

	var came_from: Dictionary = {start_key: null}
	var queue: Array = [start_key]
	var head: int = 0

	while head < queue.size():
		var key: String = queue[head]
		head += 1
		var parts: PackedStringArray = key.split(",")
		var cx: int = int(parts[0])
		var cy: int = int(parts[1])
		var ce: int = int(parts[2])

		for n in get_neighbors(cx, cy, ce):
			var n_key: String = "%d,%d,%d" % [n[0], n[1], n[2]]
			if came_from.has(n_key):
				continue
			came_from[n_key] = key
			if n_key == goal_key:
				var path: Array = []
				var k = n_key  # non tipizzato: l'entry radice mappa a null
				while k != null:
					var p: PackedStringArray = String(k).split(",")
					path.push_front([int(p[0]), int(p[1]), int(p[2])])
					k = came_from[k]
				return path
			queue.append(n_key)

	return []  # Nessun percorso
