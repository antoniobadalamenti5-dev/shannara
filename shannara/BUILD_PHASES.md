# Build Phases – Detailed Task Breakdown
## Dungeon Crawler RPG | Godot Engine 4 | Sviluppatore solitario | 10 ore/settimana

Ogni fase è divisa in **Task Principali** e **Subtask** step-by-step. L'ordine è vincolante: non saltare alla fase successiva senza completamento ed approvazione della fase corrente.

---

## FASE 1: Project Setup (Ore stimate: 3-4h) ✅ COMPLETATA

### Task 1.1: Inizializzazione Project Godot
**Subtask 1.1.1:** Aprire Godot Engine 4.x e creare nuovo progetto "Shannara_RPG"
- Impostare risoluzione default: 1920x1080
- Impostare pixel art scaling: `CanvasItem.filter = Nearest`
- Salvare project in `E:\Websites\Shannara\`

**Subtask 1.1.2:** Creare struttura cartelle baseline
- `res://scenes/`
- `res://utils/`
- `res://items/`
- `res://ui/`
- `res://fonts/`

### Task 1.2: Scene Structure Base ✅ COMPLETATA

### Task 1.3: Configurazione Claude Code Hooks ✅ COMPLETATA

### Task 1.4: Commit Iniziale ✅ COMPLETATA

---

## FASE 2: Grid & Movement (Ore stimate: 3-4h) ✅ COMPLETATA

### Task 2.1: GridSystem Core ✅ COMPLETATA
- `res://utils/GridCell.gd` - GridCell con x,y,elevation, walkable, occupant
- `res://utils/GridSystem.gd` - Singleton con get_cell_at, is_cell_walkable, set_occupant
- A* pathfinding con elevation support

### Task 2.2: Movement Resolution ✅ COMPLETATA
- `can_move(x,y,elevation)` in GridSystem
- `move_to(x,y,elevation)` in ActorController
- Validazione bounds e walkability

### Task 2.3: Elevation & Dislivelli Base ✅ COMPLETATA

### Task 2.4: Input Handling Base ✅ COMPLETATA

### Task 2.5: Commit ✅ COMPLETATA

---

## FASE 3: Turn System (Ore stimate: 2-3h) ✅ COMPLETATA

### Task 3.1: TurnManager Singleton ✅ COMPLETATA
- Enumerazione TurnState { PLAYER_TURN, ENEMY_TURN }
- Signal turn_start, turn_end, action_consumed
- Metodi start_player_turn, start_enemy_turn, end_turn, consume_action

### Task 3.2: Turn Flow Implementation ✅ COMPLETATA
- ActorController verifica TurnManager.is_player_turn()
- Player.consume_action() → Enemy turn
- Turn count incrementa al termine enemy turn

### Task 3.3: Enemy Phase Semplice ✅ COMPLETATA
- Enemy AI: take_action(target_x, target_y) con HUNT/PATROL
- Auto-esecuzione nemici durante ENEMY_TURN
- Ritorno a PLAYER_TURN

### Task 3.4: Commit ✅ COMPLETATA

---

## FASE 4: Combat Basic (Ore stimate: 3-4h) ✅ COMPLETATA

### Task 4.1: CombatResolver Utility ✅ COMPLETATA
- calculate_damage(attacker_power, defender_defense, weapon_bonus)
- resolve_attack(attacker, target) → Dictionary con success, damage, target_killed
- Min damage 1, max damage 999999

### Task 4.2: Player Attack Implementation ✅ COMPLETATA
- attack_direction(dx, dy) nel Player
- Verifica adiacenza e turno player
- Aggiornamento HP nemico

### Task 4.3: Enemy Attack & Death ✅ COMPLETATA
- Enemy _attack_player() durante ENEMY_TURN
- Morte nemico a 0 HP con rimozione grid occupant

### Task 4.4: Commit ✅ COMPLETATA

---

## FASE 5: Inventory & Items (Ore stimate: 2-3h) ✅ COMPLETATA

### Task 5.1: ItemDatabase Base ✅ COMPLETATA
- `res://items/item_database.json`
- `res://utils/ItemDatabase.gd` singleton
- Metodi get_item, get_all_items

### Task 5.2: Inventory System ✅ COMPLETATA
- `res://inventory/InventorySystem.gd` singleton
- add_item, remove_item, has_item, use_item
- Player starts with 1 healing_potion

### Task 5.3: Pickup & Consumption Mechanics ✅ COMPLETATA
- HealingPotion.tscn con Area2D
- _on_body_entered aggiunge all'inventario
- Consumo 1 turno per pickup

### Task 5.4: Commit ✅ COMPLETATA

---

## FASE 6: Single Enemy + Boss (Ore stimate: 4-5h)

### Task 6.1: Enemy AI Base (Slime)

### Task 6.2: Boss Fight Minima (1^ Bioma)

### Task 6.3: Bioma Transition

### Task 6.4: Commit

---

## FASE 7: Vertical Slice Playable (Ore stimate: 5-6h)

### Task 7.1: End-to-End Gameplay Loop

### Task 7.2: Vertical Slice Criteri Accettazione

### Task 7.3: Commit Finale e Documentazione

### Task 7.4: Handoff Report

---

## SOMMARIO FASES & TOTALI

| Fase | Ore Stimate | Task Principali | Subtask Totali |
|------|-------------|----------------|----------------|
| **Fase 1** | 3-4h | 4 | 16 |
| **Fase 2** | 3-4h | 5 | 24 |
| **Fase 3** | 2-3h | 4 | 18 |
| **Fase 4** | 3-4h | 4 | 20 |
| **Fase 5** | 2-3h | 4 | 16 |
| **Fase 6** | 4-5h | 4 | 20 |
| **Fase 7** | 5-6h | 4 | 20 |
| **TOTALI** | **25-30h** | **29** | **144** |

---

## STATO ATTUALE

### Completato:
| Fase | Ore Effettive | Status |
|------|---------------|--------|
| **Fase 0** | 2-3h | ✅ COMPLETATA |
| **Fase 1** | 7h | ✅ COMPLETATA |
| **Fase 2** | 4h | ✅ COMPLETATA |
| **Fase 3** | 3h | ✅ COMPLETATA |
| **Fase 4** | 3h | ✅ COMPLETATA |
| **Fase 5** | 3h | ✅ COMPLETATA |

### Test Suite Aggiunta (8 file)
- `tests/test_grid_cell.gd` - Verifica GridCell e TerrainType
- `tests/test_grid_system.gd` - Verifica GridSystem con pathfinding
- `tests/test_turn_manager.gd` - Verifica sistema turni
- `tests/test_player.gd` - Verifica movimento player
- `tests/test_combat.gd` - Verifica formula danni
- `tests/test_combat_flow.gd` - Verifica combat end-to-end
- `tests/test_setup.gd` - Setup/teardown per isolamento test
- `tests/test_inventory.gd` - Verifica ItemDatabase, InventorySystem

### Commit Log Fase 1-5
```
feat: complete Fase 3 - Turn System
feat: complete Fase 4 - Combat Basic
feat: complete Fase 5 - Inventory & Items
```

*Note: Ore totali stimate per sviluppatore solitario 10h/settimana ≈ 2.5-3 settimane. Ogni fase è indipendente e testabile prima di passare alla successiva.*
