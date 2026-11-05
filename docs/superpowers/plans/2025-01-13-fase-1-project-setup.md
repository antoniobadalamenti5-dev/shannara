# Fase 1: Game Object Definitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create all core game object class definitions with static typing for the dungeon crawler RPG's turn-based combat and grid movement system.

**Architecture:** Following_fsm_architecture with Godot 4 singleton patterns. Each module is a separate GDScript file with class_name declarations for static type safety. Using Godot's Node system with Composition over inheritance.

**Tech Stack:** Godot Engine 4.x, GDScript with static typing, Godot's NavigationServer2D for pathfinding, Godot's built-in enums

**Spec:** [path to the spec/design doc this plan implements] — the plan argues from the spec, so the spec travels with it; executors read both.

## Global Constraints

- Godot Engine 4.x GDScript static typing required
- Grid system: 3D coordinates (x, y, elevation) with elevation as int
- Turn system: Player → Enemy → Player cycle, 1 action = 1 turn
- Deterministic damage: base damage + modifiers, no RNG
- File naming: snake_case for files, PascalCase for class names
- All class_name declarations at top of script

## Review Focus

1. Input class: Invalid grid coordinates passed to movement → handled gracefully
2. Failure mode: Null reference when accessing grid cell occupant → defensive checks
3. Input: Negative elevation values → clamped to valid range
4. Failure mode: Damage calculation overflow → use int64 for damage values
5. Input: Missing terrain type on cell creation → default to FLOOR

---

## Task Structure

### Task 1: GridCell System and Terrain Types

**Files:**
- Create: `res://utils/GridCell.gd`
- Create: `res://utils/enums.gd`

**Interfaces:**
- Consumes: None (base data structure)
- Produces: `GridCell`, `TerrainType` enum, `grid_cell_factory` function

- [ ] **Step 1: Write the failing test**

Create test file to verify GridCell instantiation and terrain type enum:

```gdscript
# test_grid_cell.gd (GUT test format)
func test_grid_cell_creation():
    var cell := GridCell.new()
    assert_not_null(cell)
    assert_equals(cell.x, 0)
    assert_equals(cell.y, 0)
    assert_equals(cell.elevation, 0)
    assert_equals(cell.walkable, true)
    assert_is(cell.occupant, Null)

func test_terrain_type_enum():
    assert_equals(TerrainType.FLOOR, 0)
    assert_equals(TerrainType.BRIDGE, 1)
    assert_equals(TerrainType.SPIKE, 2)
    assert_equals(TerrainType.WALL, 3)

func test_elevation_values():
    var cell := GridCell.new()
    cell.elevation = -1  # fossato
    cell.elevation = 0   # piano
    cell.elevation = 1   # altezza
    assert(cell.elevation >= -1 && cell.elevation <= 1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --evaluate-test test_grid_cell.gd`
Expected: FAIL - "Invalid get index 'TerrainType' (no such variable)"

- [ ] **Step 3: Implement TerrainType enum in enums.gd**

```gdscript
# res://utils/enums.gd
extends Resource

enum TerrainType { FLOOR, BRIDGE, SPIKE, WALL }
```

- [ ] **Step 4: Implement GridCell class with static typing**

```gdscript
# res://utils/GridCell.gd
class_name GridCell
extends Resource

var x: int = 0
var y: int = 0
var elevation: int = 0  # -1 = fossato, 0 = piano, 1 = altezza
var walkable: bool = true
var occupant: Node = null
var terrain_type: int = TerrainType.FLOOR

func grid_cell_factory(p_x: int, p_y: int, p_elevation: int = 0) -> GridCell:
    var cell := GridCell.new()
    cell.x = p_x
    cell.y = p_y
    cell.elevation = clamp(p_elevation, -1, 1)
    return cell
```

- [ ] **Step 5: Run test to verify it passes**

Run: `godot --headless --evaluate-test test_grid_cell.gd`
Expected: PASS - all assertions succeed

- [ ] **Step 6: Commit**

```bash
git add res://utils/enums.gd res://utils/GridCell.gd test_grid_cell.gd
git commit -m "feat: add GridCell data structure and TerrainType enum"
```

---

### Task 2: GridSystem for 3D Coordinate Management

**Files:**
- Create: `res://utils/GridSystem.gd`

**Interfaces:**
- Consumes: `GridCell`, `TurnManager` (for notifications)
- Produces: `GridSystem` singleton with grid state, `is_cell_walkable`, `get_cell_at`, `set_occupant`

- [ ] **Step 1: Write the failing test**

```gdscript
func test_grid_system_initialization():
    assert_not_null(GridSystem)
    assert(GridSystem.grid_size.x > 0)
    assert(GridSystem.grid_size.y > 0)

func test_get_cell_at_returns_cell():
    var cell := GridSystem.get_cell_at(0, 0, 0)
    assert_not_null(cell)
    assert_is(cell, GridCell)

func test_set_occupant():
    var actor := Actor.new()
    GridSystem.set_occupant(5, 5, 0, actor)
    var cell := GridSystem.get_cell_at(5, 5, 0)
    assert_eq(cell.occupant, actor)

func test_is_cell_walkable():
    assert(GridSystem.is_cell_walkable(0, 0, 0) == true)
    # Assuming wall placed at (1,1,0)
    GridSystem.place_terrain(1, 1, 0, TerrainType.WALL)
    assert(GridSystem.is_cell_walkable(1, 1, 0) == false)
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - "Can't instantiate GridSystem"

- [ ] **Step 3: Implement GridSystem singleton with 2D grid storage**

```gdscript
# res://utils/GridSystem.gd
class_name GridSystem
extends Node

signal move_requested(cell_x, cell_y, elevation_from, elevation_to)
signal attack_requested(attacker_x, attacker_y, target_x, target_y)

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20
const MAX_ELEVATION: int = 2

var grid: Array = []  # [y][x][elevation] -> GridCell

func _ready() -> void:
    _initialize_grid()

func _initialize_grid() -> void:
    for y in range(GRID_HEIGHT):
        var row := []
        for x in range(GRID_WIDTH):
            var elevation_row := []
            for z in range(MAX_ELEVATION + 1):  # 0, 1, 2
                var cell := GridCell.new()
                cell.x = x
                cell.y = y
                cell.elevation = z - 1  # -1, 0, 1
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
    var cell := get_cell_at(x, y, elevation)
    if cell == null:
        return false
    return cell.walkable and cell.occupant == null

func set_occupant(x: int, y: int, elevation: int, occupant: Node) -> void:
    var cell := get_cell_at(x, y, elevation)
    if cell != null:
        cell.occupant = occupant

func place_terrain(x: int, y: int, elevation: int, terrain_type: int) -> void:
    var cell := get_cell_at(x, y, elevation)
    if cell != null:
        cell.terrain_type = terrain_type
        if terrain_type == TerrainType.WALL:
            cell.walkable = false

func can_move_to(from_x: int, from_y: int, from_elev: int, to_x: int, to_y: int, to_elev: int) -> bool:
    if not is_cell_walkable(to_x, to_y, to_elev):
        return false
    # Check elevation transition rules
    if from_elev != to_elev:
        # Can only change elevation at stairs/bridge cells
        return true
    return true
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS - all grid operations work correctly

- [ ] **Step 5: Commit**

```bash
git add res://utils/GridSystem.gd test_grid_system.gd
git commit -m "feat: add GridSystem singleton for coordinate management"
```

---

### Task 3: TurnManager with Deterministic Turn System

**Files:**
- Create: `res://utils/TurnManager.gd`

**Interfaces:**
- Consumes: `GridSystem` (via signals), player/enemy actors
- Produces: `TurnManager` singleton with turn state, `start_player_turn`, `advance_to_enemy`, `end_turn`

- [ ] **Step 1: Write the failing test**

```gdscript
func test_turn_manager_initial_state():
    assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN)
    assert_eq(TurnManager.turn_count, 0)

func test_start_player_turn_emits_signal():
    TurnManager.start_player_turn()
    # Should emit turn_start with PLAYER_TURN
    assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN)

func test_consume_turn_advances_to_enemy():
    TurnManager.turn_count = 0
    TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
    TurnManager.end_turn()
    assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN)
    assert_eq(TurnManager.turn_count, 1)

func test_turn_order_player_enemy_player():
    TurnManager.turn_count = 0
    TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
    TurnManager.end_turn()  # → ENEMY_TURN
    assert_eq(TurnManager.current_state, TurnManager.TurnState.ENEMY_TURN)
    TurnManager.end_turn()  # → PLAYER_TURN (next cycle)
    assert_eq(TurnManager.current_state, TurnManager.TurnState.PLAYER_TURN)
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - "Can't instantiate TurnManager"

- [ ] **Step 3: Implement TurnManager with FSM**

```gdscript
# res://utils/TurnManager.gd
class_name TurnManager
extends Node

enum TurnState { PLAYER_TURN, ENEMY_TURN }

var current_state: int = TurnState.PLAYER_TURN
var turn_count: int = 0
var grid_system: Node = null

signal turn_start(new_state: int)
signal turn_end()
signal action_consumed

func _ready() -> void:
    grid_system = get_tree().get_root().find_node("GridSystem", true, false)

func start_player_turn() -> void:
    current_state = TurnState.PLAYER_TURN
    turn_start.emit(TurnState.PLAYER_TURN)

func start_enemy_turn() -> void:
    current_state = TurnState.ENEMY_TURN
    turn_start.emit(TurnState.ENEMY_TURN)

func is_player_turn() -> bool:
    return current_state == TurnState.PLAYER_TURN

func is_enemy_turn() -> bool:
    return current_state == TurnState.ENEMY_TURN

func end_turn() -> void:
    if current_state == TurnState.PLAYER_TURN:
        start_enemy_turn()
    else:
        turn_count += 1
        start_player_turn()
    turn_end.emit()

func consume_action() -> void:
    action_consumed.emit()
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS - all turn state transitions work

- [ ] **Step 5: Commit**

```bash
git add res://utils/TurnManager.gd test_turn_manager.gd
git commit -m "feat: add TurnManager with deterministic turn system"
```

---

### Task 4: ActorController Base Class

**Files:**
- Create: `res://actors/ActorController.gd`
- Create: `res://actors/Player.gd`
- Create: `res://actors/Enemy.gd`

**Interfaces:**
- Consumes: `GridSystem`, `TurnManager`, `CombatResolver`
- Produces: Base `ActorController`, `Player` actor, `Enemy` actor

- [ ] **Step 1: Write the failing test**

```gdscript
func test_actor_controller_creation():
    var actor := ActorController.new()
    assert_not_null(actor)
    assert_eq(actor.max_hp, 100)
    assert_eq(actor.current_hp, 100)

func test_actor_take_damage():
    var actor := ActorController.new()
    actor.take_damage(25)
    assert_eq(actor.current_hp, 75)

func test_actor_is_alive():
    var actor := ActorController.new()
    assert(actor.is_alive())
    actor.take_damage(100)
    assert(!actor.is_alive())

func test_player_can_act_on_player_turn():
    var player := Player.new()
    TurnManager.current_state = TurnManager.TurnState.PLAYER_TURN
    assert(player.can_act())
    TurnManager.current_state = TurnManager.TurnState.ENEMY_TURN
    assert(!player.can_act())
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - "Can't instantiate ActorController"

- [ ] **Step 3: Implement ActorController base class**

```gdscript
# res://actors/ActorController.gd
class_name ActorController
extends Node2D

@export var max_hp: int = 100
var current_hp: int = max_hp
var grid_x: int = 0
var grid_y: int = 0
var grid_elevation: int = 0

func _ready() -> void:
    current_hp = max_hp

func take_damage(amount: int) -> void:
    current_hp = max(0, current_hp - abs(amount))

func heal(amount: int) -> void:
    current_hp = min(max_hp, current_hp + abs(amount))

func is_alive() -> bool:
    return current_hp > 0

func can_act() -> bool:
    if TurnManager == null:
        return false
    return TurnManager.current_state == TurnManager.TurnState.PLAYER_TURN

func move_to(x: int, y: int, elevation: int) -> bool:
    if GridSystem.is_cell_walkable(x, y, elevation):
        GridSystem.set_occupant(grid_x, grid_y, grid_elevation, null)
        grid_x = x
        grid_y = y
        grid_elevation = elevation
        GridSystem.set_occupant(x, y, elevation, self)
        return true
    return false
```

- [ ] **Step 4: Implement Player class**

```gdscript
# res://actors/Player.gd
class_name Player
extends ActorController

func _init() -> void:
    max_hp = 100
    current_hp = 100

func can_act() -> bool:
    return is_alive() and TurnManager.is_player_turn()
```

- [ ] **Step 5: Implement Enemy class**

```gdscript
# res://actors/Enemy.gd
class_name Enemy
extends ActorController

enum EnemyState { IDLE, PATROL, HUNT, ATTACK }

var state: int = EnemyState.IDLE
var patrol_points: Array = []
var patrol_index: int = 0

func _init() -> void:
    max_hp = 50
    current_hp = 50

func can_act() -> bool:
    return is_alive() and TurnManager.is_enemy_turn()

func update_state(player_x: int, player_y: int) -> void:
    var distance := abs(grid_x - player_x) + abs(grid_y - player_y)
    if distance <= 2:
        state = EnemyState.HUNT
    elif patrol_points.size() > 0:
        state = EnemyState.PATROL
    else:
        state = EnemyState.IDLE
```

- [ ] **Step 6: Run test to verify it passes**

Expected: PASS - all actor tests succeed

- [ ] **Step 7: Commit**

```bash
git add res://actors/ActorController.gd res://actors/Player.gd res://actors/Enemy.gd test_actor.gd
git commit -m "feat: add base ActorController, Player, and Enemy classes"
```

---

### Task 5: CombatResolver for Damage Calculations

**Files:**
- Create: `res://combat/CombatResolver.gd`

**Interfaces:**
- Consumes: `ActorController` (attacker, target)
- Produces: Deterministic damage formula, `calculate_damage`, `resolve_attack`

- [ ] **Step 1: Write the failing test**

```gdscript
func test_calculate_damage_basic():
    var damage := CombatResolver.calculate_damage(attacker_power: 10, defender_defense: 5)
    assert_eq(damage, 5)  # 10 - 5 = 5

func test_calculate_damage_minimum():
    var damage := CombatResolver.calculate_damage(attacker_power: 3, defender_defense: 10)
    assert_eq(damage, 1)  # minimum 1 damage

func test_calculate_damage_with_weapon_bonus():
    var damage := CombatResolver.calculate_damage(attacker_power: 10, defender_defense: 5, weapon_bonus: 3)
    assert_eq(damage, 8)  # (10 - 5) + 3 = 8

func test_resolve_attack():
    var attacker := ActorController.new()
    attacker.grid_x = 5
    attacker.grid_y = 5
    var target := ActorController.new()
    target.grid_x = 6
    target.grid_y = 5
    var result := CombatResolver.resolve_attack(attacker, target)
    assert(result.success == true)
    assert(result.damage > 0)
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - "Can't call static method CombatResolver.calculate_damage"

- [ ] **Step 3: Implement CombatResolver with stateless deterministic logic**

```gdscript
# res://combat/CombatResolver.gd
class_name CombatResolver
extends Resource

const MIN_DAMAGE: int = 1
const MAX_DAMAGE: int = 999999

func calculate_damage(attacker_power: int, defender_defense: int, weapon_bonus: int = 0) -> int:
    var base_damage := attacker_power - defender_defense
    var total_damage := base_damage + weapon_bonus
    return clamp(total_damage, MIN_DAMAGE, MAX_DAMAGE)

func resolve_attack(attacker: ActorController, target: ActorController) -> Dictionary:
    var result := {
        "success": false,
        "damage": 0,
        "target_killed": false
    }
    
    if target == null or not target.is_alive():
        return result
    
    var is_adjacent := abs(attacker.grid_x - target.grid_x) + abs(attacker.grid_y - target.grid_y) <= 1
    if not is_adjacent:
        return result
    
    result.success = true
    result.damage = calculate_damage(10, 2)  # Base values
    target.take_damage(result.damage)
    
    result.target_killed = not target.is_alive()
    return result
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS - all combat calculations deterministic

- [ ] **Step 5: Commit**

```bash
git add res://combat/CombatResolver.gd test_combat.gd
git commit -m "feat: add CombatResolver with deterministic damage formulas"
```

---

### Task 6: Scene Structure and Project Organization

**Files:**
- Create directory structure: `scenes/`, `items/`, `ui/`, `fonts/`
- Create: `scenes/GameRoot.tscn` (main scene)
- Create: `scenes/Camera2D.tscn`

**Interfaces:**
- Consumes: None (project scaffolding)
- Produces: Scene files ready for Godot editor loading

- [ ] **Step 1: Write the failing test**

Verify directory structure exists:

```bash
# Test that all required directories exist
test -d "res://scenes"
test -d "res://items"
test -d "res://ui"
test -d "res://fonts"
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - directories don't exist

- [ ] **Step 3: Create directory structure via Godot**

```bash
mkdir -p res://scenes res://items res://ui res://fonts
```

- [ ] **Step 4: Create main GameRoot scene with autoload singletons**

Create `scenes/GameRoot.tscn` with:
- Node2D root
- Attach script with _ready() that instantiates GridSystem, TurnManager
- Set as autoload in project.godot

- [ ] **Step 5: Run test to verify it passes**

Expected: PASS - directory structure created, scene loads

- [ ] **Step 6: Commit**

```bash
git add res://scenes/GameRoot.tscn res://scenes/Camera2D.tscn
git commit -m "chore: create scene structure and GameRoot main scene"
```

---

## Summary Table

| Module | File | Lines | Dependencies |
|--------|------|-------|--------------|
| GridCell | `utils/GridCell.gd` | ~25 | None |
| TerrainType enum | `utils/enums.gd` | ~5 | None |
| GridSystem | `utils/GridSystem.gd` | ~100 | GridCell |
| TurnManager | `utils/TurnManager.gd` | ~60 | None |
| ActorController | `actors/ActorController.gd` | ~50 | GridSystem, TurnManager |
| Player | `actors/Player.gd` | ~10 | ActorController |
| Enemy | `actors/Enemy.gd` | ~25 | ActorController, TurnManager |
| CombatResolver | `combat/CombatResolver.gd` | ~40 | ActorController |

## Total Estimated Effort

- Development: ~4 hours
- Testing: ~2 hours
- Documentation: ~1 hour
- **Total: 7 hours** (within 10h/week constraint)

## Next Steps

Upon completion, proceed to Fase 2: Grid & Movement with the TurnManager already integrated.