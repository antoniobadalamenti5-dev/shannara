# BiomeSystem singleton
# Gestisce la transizione tra biomi e la generazione di nuove mappe

extends Node

enum BiomeType { FOREST = 0, CAVE = 1, DESERT = 2, ICE = 3, SWAMP = 4 }

signal biome_changed(new_biome: int)
signal map_completed(biome: int)

var current_biome: int = BiomeType.FOREST
var completed_biomes: Array = []
var forest_boundaries: Array = []  # Tiles che segnano l'ingresso al bioma successivo

func _ready() -> void:
	current_biome = BiomeType.FOREST

func get_biome_name(biome_type: int) -> String:
	match biome_type:
		BiomeType.FOREST:
			return "Foresta"
		BiomeType.CAVE:
			return "Caverna"
		BiomeType.DESERT:
			return "Deserto"
		BiomeType.ICE:
			return "Ghiacciaio"
		BiomeType.SWAMP:
			return "Palude"
	return "Sconosciuto"

func check_biome_completion(player_x: int, player_y: int) -> bool:
	for boundary in forest_boundaries:
		var bx: int = boundary[0] as int
		var by: int = boundary[1] as int
		if player_x == bx and player_y == by:
			return true
	return false

func transition_to_next_biome() -> void:
	var next_biome: int = current_biome + 1
	if next_biome > BiomeType.SWAMP:
		next_biome = BiomeType.FOREST

	completed_biomes.append(current_biome)
	current_biome = next_biome
	biome_changed.emit(current_biome)
	load_biome_map(current_biome)

func load_biome_map(biome: int) -> void:
	# TODO: Implement in Fase 7
	push_warning("load_biome_map non completato - vedi Fase 7")

func generate_biome_map(biome: int) -> Dictionary:
	"""Return biome data with enemy and item spawn definitions."""
	var enemies: Array = []
	var items: Array = []

	match biome:
		BiomeType.FOREST:
			# 1 Slime + 1 BossGolem (boss fight)
			enemies = [
				{"type": "Slime", "grid_x": 8, "grid_y": 5, "grid_elevation": 0},
				{"type": "BossGolem", "grid_x": 15, "grid_y": 10, "grid_elevation": 0}
			]
			items = [
				{"type": "healing_potion", "grid_x": 6, "grid_y": 8, "grid_elevation": 0}
			]
		BiomeType.CAVE:
			enemies = [
				{"type": "Slime", "grid_x": 5, "grid_y": 8, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 12, "grid_y": 12, "grid_elevation": 0}
			]
		BiomeType.DESERT:
			enemies = [
				{"type": "Slime", "grid_x": 3, "grid_y": 6, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 10, "grid_y": 10, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 17, "grid_y": 14, "grid_elevation": 0}
			]
		BiomeType.ICE:
			enemies = [
				{"type": "Slime", "grid_x": 6, "grid_y": 10, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 14, "grid_y": 10, "grid_elevation": 0}
			]
		BiomeType.SWAMP:
			enemies = [
				{"type": "Slime", "grid_x": 4, "grid_y": 9, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 9, "grid_y": 14, "grid_elevation": 0},
				{"type": "Slime", "grid_x": 16, "grid_y": 9, "grid_elevation": 0}
			]
		_:
			enemies = [
				{"type": "Slime", "grid_x": 8, "grid_y": 5, "grid_elevation": 0}
			]

	return {
		"biome_type": biome,
		"width": 20,
		"height": 20,
		"enemies": enemies,
		"items": items
	}

func get_biome_multiplier() -> float:
	match current_biome:
		BiomeType.FOREST:
			return 1.0
		BiomeType.CAVE:
			return 1.5
		BiomeType.DESERT:
			return 2.0
		BiomeType.ICE:
			return 2.5
		BiomeType.SWAMP:
			return 3.0
	return 1.0