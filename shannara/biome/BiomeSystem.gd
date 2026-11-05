# BiomeSystem singleton
# Gestisce la transizione tra biomi e la generazione di nuove mappe

class_name BiomeSystem
extends Node

enum BiomeType { FOREST, CAVE, DESERT, ICE, SWAMP }

signal biome_changed(new_biome: int)
signal map_completed(biome: int)

var current_biome: int = BiomeType.FOREST
var completed_biomes: Array = []
var forest_boundaries: Array = []  # Tiles che segnano l'ingresso al bioma successivo

func _ready() -> void:
	# Inizializza con il primo bioma
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
	"""Verifica se il giocatore ha completato il biome corrente."""
	for boundary in forest_boundaries:
		var bx := boundary[0]
		var by := boundary[1]
		if player_x == bx and player_y == by:
			# Player ha raggiunto il confine
			return true
	return false

func transition_to_next_biome() -> void:
	"""Passa al bioma successivo."""
	var next_biome := current_biome + 1
	if next_biome > BiomeType.SWAMP:
		next_biome = BiomeType.FOREST

	completed_biomes.append(current_biome)
	current_biome = next_biome
	biome_changed.emit(current_biome)

	# Ricarica la mappa del nuovo bioma
	load_biome_map(current_biome)

func load_biome_map(biome: int) -> void:
	"""Carica la mappa per il biome specificato."""
	# Questo metodo sarà completato in Fase 7
	# Per ora simula il caricamento
	push_warning("load_biome_map non completato - vedi Fase 7")

func generate_biome_map(biome: int) -> Dictionary:
	"""Genera una nuova mappa per il biome specificato."""
	return {
		"biome_type": biome,
		"width": 20,
		"height": 20,
		"enemies": [],
		"items": []
	}

func get_biome_multiplier() -> float:
	"""Ritorna il moltiplicatore di difficoltà per il biome corrente."""
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