# Build Phases – Detailed Task Breakdown
## Dungeon Crawler RPG | Godot Engine 4 | Sviluppatore solitario | 10 ore/settimana

Ogni fase è divisa in **Task Principali** e **Subtask** step-by-step. L'ordine è vincolante: non saltare alla fase successiva senza completamento ed approvazione della fase corrente.

---

## FASE 1: Project Setup (Ore stimate: 3-4h)
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

**Subtask 1.1.3:** Configurare `project_settings` GDScript init
```gdscript
# project_settings.gd (autoload)
extends Node

func _ready():
    pass
```

**Subtask 1.1.4:** Impostare Autoload principale
- TurnManager, GridSystem, ItemDatabase come Autoload (/root)
- Verificare nomi univoci

### Task 1.2: Scene Structure Base
**Subtask 1.2.1:** Creare scena root `MainScene.tscn`
- Node2D root
- Child: `Player` (Body2D)
- Child: `Enemy` (Area2D)
- Child: `Grid` (TileMap)
- Child: `UI` (Node2D)

**Subtask 1.2.2:** Impostare TileMap base 10x10
- TileSet: tileset base pixel art 32x32
- Layer 0: Ground floor
- Aggiungere 3 tile types: Floor, Wall, Empty

**Subtask 1.2.3:** Posizionare giocatore iniziale
- Posizione: (5, 5, Z:0)
- Sprite: placeholder 32x32

**Subtask 1.2.4:** Creare scena UI overlay minimale
- Indicatore turno (Label "Turno: Giocatore")
- Barra HP (ProgressBar)
- Aggiungere al nodo root

### Task 1.3: Configurazione Claude Code Hooks
**Subtask 1.3.1:** Verificare `.claude/settings.json` permit list
- Confirmare `allow_bash: true`, `allow_write: true`
- Testare comando `cd` project directory

**Subtask 1.3.2:** Creare hook pre-commit per check IP
- Script che greppa tutti i file nuovi/modificati per riferimenti "Shea", "Allanon", "Shannara"
- Fallimento commit se riferimenti trovati

**Subtask 1.3.3:** Testare hooks base
- Eseguire `git status` dal project root
- Verificare output leggibile

### Task 1.4: Commit Iniziale
**Subtask 1.4.1:** `git add -A`
**Subtask 1.4.2:** `git commit -m "feat: project setup base structure
- Godot project initialized
- Main scene with grid 10x10
- Player start position (5,5,Z:0)
- UI overlay minimal
- Autoload: TurnManager, GridSystem, ItemDatabase
- IP check hook configured"`

**Subtask 1.4.3:** `git status` verifica nessun file shannara reference

---

## FASE 2: Grid & Movement (Ore stimate: 3-4h)
### Task 2.1: GridSystem Core
**Subtask 2.1.1:** Creare `res://utils/GridCell.gd`
```gdscript
class_name GridCell

var x: int
var y: int
var elevation: int = 0 # 0: piano, 1: altura, -1: fossato
var walkable: bool = true
var occupant: Node = null
var terrain_type: enum("FLOOR", "BRIDGE", "SPIKE", "WALL")
```

**Subtask 2.1.2:** Creare `res://utils/GridSystem.gd` (singleton)
- Dictionaty `GridCell[x,y]` per mappa attiva
- Metodo `get_cell(x,y) -> GridCell`
- Metodo `set_cell(x,y,cell)`
- Metodo `is_valid_position(x,y,elevation) -> bool`

**Subtask 2.1.3:** Testare sistema grid base
- Posizionare cella a (5,5) elevation 0
- Verificare `GridSystem.get_cell(5,5).elevation == 0`

### Task 2.2: Movement Resolution
**Subtask 2.2.1:** Implementare `can_move(x,y,elevation) -> bool` in GridSystem
- Controllare bounds mappa (0-9, 0-9)
- Controllare `cell.walkable == true`
- Controllare nessun `occupant` presente

**Subtask 2.2.2:** Implementare `move_player(x,y,elevation) -> bool` in ActorController
- Salvare posizione precedente
- Chiamare `GridSystem.is_valid_position(new_x,new_y,new_elevation)`
- Se vero: muovere `Position = Vector2(new_x, new_y)`, aggiornare `elevation`
- Se falso: ripristinare posizione precedente, restituire false

**Subtask 2.2.3:** Testare movimento base
- Subtask 2.2.3a: Mosse gratuita (5,5)→(5,6) se walkable → posizione aggiornata
- Subtask 2.2.3b: Mosse bloccata da muro → posizione invariata, restituire false
- Subtask 2.2.3c: Mosse fuori bounds → posizione invariata

### Task 2.3: Elevation & Dislivelli Base
**Subtask 2.3.1:** Aggiungere tile "Scala" al TileSet
- Sprite scale 32x16 (occupi 2 tile height Z-level)
- Flag: `is_stairs = true`

**Subtask 2.3.2:** Implementare regola scala in GridSystem
- Quando `move_player` targeting cell con `elevation == 1` e tile sopra è "Scala":
  - Consentire movimento, aggiornare `elevation` da 0→1
- Altrimenti: respinto, `elevation` invariato

**Subtask 2.3.3:** Implementare regola ponte in GridSystem
- Quando `move_player` targeting cell con `elevation == -1` (fossato) ma sopra c'è ponte (TileMapLayer 1):
  - Consentire movimento mantenendo `elevation == 0`
- Altrimenti: respinto

**Subtask 2.3.4:** Testare dislivelli
- Subtask 2.3.4a: Tentativo salita senza scala → respinto, elevation invariato
- Subtask 2.3.4b: Tentativo salita CON scala → elevation 0→1, movimento successo
- Subtask 2.3.4c: Ponte sopra fossato → movimento successo, elevation mantiene 0

### Task 2.4: Input Handling Base
**Subtask 2.4.1:** Collegare input 4 direzioni (Arrow Keys / WASD) al ` _process()` player
- Mappatura: Up→Vector2(0,-1), Down→Vector2(0,1), Left→Vector2(-1,0), Right→Vector2(1,0)

**Subtask 2.4.2:** Implementare `on_action_move(direction)` in ActorController
- Calcolare `new_position = position + direction`
- Chiamare `GridSystem.can_move(new_position.x, new_position.y, new_position.elevation)`
- Se vero: `move_player(new_position.x, new_position.y, new_position.elevation)`
- Se falso: nothing (o flash error visuale)

**Subtask 2.4.3:** Testare input
- Premere Freccia Destra → giocatore si muove destra se cella walkable
- Premere Freccia Sinistra contro muro → nessun movimento

### Task 2.5: Commit
**Subtask 2.5.1:** `git add res/utils/GridCell.gd res/utils/GridSystem.gd scenes/MainScene.tscn`
**Subtask 2.5.2:** `git commit -m "feat: grid system & movement resolver
- GridCell class con elevation tracking
- GridSystem singleton con gestione mappa 10x10
- Regole movimento base e blocco ostacoli
- Scale Z-level con tile 'Scala'
- Ponte sopra fossato mantiene Z:0
- Input Arrow Keys/WASD operative"`

---

## FASE 3: Turn System (Ore stimate: 2-3h)
### Task 3.1: TurnManager Singleton
**Subtask 3.1.1:** Creare `res/utils/TurnManager.gd` (singleton /autoload)
```gdscript
class_name TurnManager

enum TurnState { PLAYER_TURN, ENEMY_TURN }

var current_state: TurnState = TurnState.PLAYER_TURN
var turn_count: int = 0
var is_player_turn: bool = true

# Events
signal turn_start(new_state)
signal turn_end()
signal action_taken()

func start_turn():
    turn_count += 1
    current_state = TurnState.PLAYER_TURN
    is_player_turn = true
    emit_signal("turn_start", current_state)

func end_turn():
    current_state = TurnState.ENEMY_TURN
    is_player_turn = false
    emit_signal("turn_end")
    # Trigger enemy phase dopo breve delay
    get_tree().create_timer(0.5).timeout.connect("_on_turn_delayed")

func _on_turn_delayed():
    # Passa al turno nemico automatico
    start_turn()  # Ricicla con nuovo conteggio turni
```

**Subtask 3.1.2:** Aggiungere TurnManager come Autoload in project settings
- Nome: "TurnManager"
- Path: `res/utils/TurnManager.gd`

**Subtask 3.1.3:** Testare avvio turno
- All'avvio gioco: `is_player_turn == true`, `turn_count == 1`

### Task 3.2: Turn Flow Implementation
**Subtask 3.2.1:** Modificare `ActorController._process()` per controllare `TurnManager.is_player_turn`
- Se `is_player_turn == false`: ignorare input player
- Se `is_player_turn == true`: permettere input (già configurato Fase 2)

**Subtask 3.2.2:** Implementare passaggio turno automatico dopo azione player
- Dopo `move_player` o `attack` successful: `TurnManager.end_turn()`
- Verificare che `turn_count` incrementi di 1 per azione

**Subtask 3.2.3:** Testare consumo turno
- Subtask 3.2.3a: Muovere giocatore → `turn_count` diventa 1
- Subtask 3.2.3b: Muovere di nuovo prima che nemico agisca → `turn_count` diventa 2
- Subtask 3.2.3c: Verificare che tra 2 movimenti ci sia il cambio turno player→nemico→player

### Task 3.3: Enemy Phase Semplice
**Subtask 3.3.1:** Implementare `Enemy AI Patrol` base
- Nemico si muove tile casuale o verso waypoint fisso
- Consuma 1 turno quando agisce

**Subtask 3.3.2:** Collegare AI al TurnManager
- Nemico riceve segnale `turn_start` quando `current_state == ENEMY_TURN`
- Quando segnale ricevuto: eseguire `enemy_act()`

**Subtask 3.3.3:** Testare fase nemico
- Subtask 3.3.3a: Dopo giocatore muove, nemico agisce immediatamente dopo
- Subtask 3.3.3b: Turno nemico consuma 1 dal contatore
- Subtask 3.3.3c: Dopo nemico, turno ritorna al giocatore (`is_player_turn = true`)

### Task 3.4: Commit
**Subtask 3.4.1:** `git add res/utils/TurnManager.gd scenes/ActorController.gd`
**Subtask 3.4.2:** `git commit -m "feat: turn system deterministico
- TurnManager singleton con stato PLAYER/ENEMY turn
- Consumo 1 turno per azione player
- Fine turno automatico → nemico phase
- Enemy AI patrol base con segnali
- Turn count tracking funzionante"`

---

## FASE 4: Combat Basic (Ore stimate: 3-4h)
### Task 4.1: CombatResolver Utility
**Subtask 4.1.1:** Creare `res/utils/CombatResolver.gd` (stateless, no state storage)
```gdscript
class_name CombatResolver

# Formula danno base: attacker_atk - defender_def
# Minimo 1 danno sempre

func calc_damage(attacker_atk: int, defender_def: int) -> int:
    var raw_damage = attacker_atk - defender_def
    return max(1, raw_damage)

# Risoluzione attacco adiacente
func resolve_adjacent_attack(attacker, target) -> dict:
    var damage = calc_damage(attacker.atk, target.def)
    target.hp -= damage
    var result = {
        "damage": damage,
        "target_hp": target.hp,
        "dead": target.hp <= 0,
        "attacker": attacker.name,
        "target": target.name
    }
    return result
```

**Subtask 4.1.2:** Testare formula danni
- Subtask 4.1.2a: Attaccante atk=10, difensore def=3 → damage=7
- Subtask 4.1.2b: Attaccante atk=3, difensore def=10 → damage=1 (minimo)
- Subtask 4.1.2c: Attaccante atk=5, difensore def=5 → damage=1 (minimo)

### Task 4.2: Player Attack Implementation
**Subtask 4.2.1:** Implementare `input_action_attack()` in ActorController
- Controllare che nemico sia adiacente (manhattan distance == 1)
- Verificare `TurnManager.is_player_turn == true`
- Chiamare `CombatResolver.resolve_adjacent_attack(player, enemy)`
- Applicare risultato: `enemy.hp -= damage`, visualizzare feedback

**Subtask 4.2.2:** Aggiungere indicatore attacco visivo
- Flash sprite player rosso per 0.1s
- Numeri danno sopra nemico (temporaneo: print console)

**Subtask 4.2.3:** Testare attacco player
- Subtask 4.2.3a: Nemico a distanza 1, premere attacco → nemico HP diminuisce
- Subtask 4.2.3b: Nemico fuori distanza attacco → nulla accade
- Subtask 4.2.3c: Attacco contro muro/ostacolo → nulla accade

### Task 4.3: Enemy Attack & Death
**Subtask 4.3.1:** Implementare attacco nemico verso player
- Nemico controlla se player adiacente durante `ENEMY_TURN`
- Se sì: calcolare danno `CombatResolver.resolve_adjacent_attack(enemy, player)`
- Applicare `player.hp -= damage`

**Subtask 4.3.2:** Implementare morte nemico a 0 HP
- Quando `enemy.hp <= 0`: rimuovere nodo nemico dalla scena
- Incrementare `player.xp` o flag "killed"
- Premio: possibile drop oggetto curativo

**Subtask 4.3.3:** Testare combat flow completo
- Subtask 4.3.3a: Player attacca nemico adiacente → HP nemico diminuisce
- Subtask 4.3.3b: Nemico attacca player dopo il suo turno → player HP diminuisce
- Subtask 4.3.3c: Nemico morto a 0 HP → rimosso dalla scena, player guadagna "kill"

### Task 4.4: Commit
**Subtask 4.4.1:** `git add res/utils/CombatResolver.gd scenes/Player.gd scenes/Enemy.gd`
**Subtask 4.4.2:** `git commit -m "feat: combat basic resolver
- CombatResolver utility stateless con formula danni
- Attacco player adiacente con feedback visivo
- Enemy attack during ENEMY_TURN
- Morte nemica a 0 HP con rimozione nodo
- Sistema XP/kill basic"`

---

## FASE 5: Inventory & Items (Ore stimate: 2-3h)
### Task 5.1: ItemDatabase Base
**Subtask 5.1.1:** Creare `res/items/item_database.json` (dati JSON)
```json
{
  "items": {
    "healing_potion": {
      "name": "Pozione Curativa",
      "type": "consumable",
      "hp_restore": 15,
      "description": "Ripristina 15 PV"
    },
    "wooden_sword": {
      "name": "Spada di Legno",
      "type": "weapon",
      "atk_bonus": 3,
      "description": "+3 Attacco"
    }
  }
}
```

**Subtask 5.1.2:** Creare `res/utils/ItemDatabase.gd` (singleton, lettore JSON)
- Metodo `get_item(id) -> dict`
- Metodo `get_all_items() -> dict`
- Caricare JSON all'`_ready()`

**Subtask 5.1.3:** Testare caricamento item
- Caricare database, verificare `get_item("healing_potion").hp_restore == 15`

### Task 5.2: Inventory System
**Subtask 5.2.1:** Creare `res/inventory/inventory.gd` (singleton)
- Lista `active_items: dict` (chiave=item_id, valore=quantità)
- Metodo `add_item(item_id, quantity=1)`
- Metodo `remove_item(item_id, quantity=1)`
- Metodo `has_item(item_id, quantity=1) -> bool`

**Subtask 5.2.2:** Collegare inventario al player
- Player starts with: 1 healing_potion
- UI mostra icone oggetti in possesso

**Subtask 5.2.3:** Testare inventory base
- Subtask 5.2.3a: Aggiungere pozione all'inventario → count diventa 1
- Subtask 5.2.3b: Aggiungere altra pozione → count diventa 2
- Subtask 5.2.3c: Usare pozione → HP ripristina 15, count diminuisce di 1

### Task 5.3: Pickup & Consumption Mechanics
**Subtask 5.3.1:** Creare scena `HealingPotion.tscn`
- Area2D collider sulla tile mappa
- Script che rileva `body_entered` player
- Al rilevamento: aggiungere all'inventario, rimuovere dalla mappa, consumare 1 turno

**Subtask 5.3.2:** Implementare `on_body_entered_player(potion)`
- `InventorySystem.add_item("healing_potion")`
- `queue_free()` (rimuovi dalla scena)
- `TurnManager.end_turn()` (consuma turno per pickup)

**Subtask 5.3.3:** Testare pickup mechanics
- Subtask 5.3.3a: Entrare in tile pozione → aggiunta inventario, pozione sparita
- Subtask 5.3.3b: Usare pozione dall'inventario → HP +15, count -1
- Subtask 5.3.3c: Pickup consuma 1 turno (verificare turn_count incrementa)

### Task 5.4: Commit
**Subtask 5.4.1:** `git add res/items/item_database.json res/utils/ItemDatabase.gd res/inventory/inventory.gd scenes/HealingPotion.tscn`
**Subtask 5.4.2:** `git commit -m "feat: inventory & items system
- ItemDatabase JSON con pozioni base
- Item singleton loader da JSON
- Inventory system con gestione slot/quantities
- Pickup meccanica area2D + inventario
- Pozione curativa ripristina 15 HP
- Pickup consuma 1 turno"`

---

## FASE 6: Single Enemy + Boss (Ore stimate: 4-5h)
### Task 6.1: Enemy AI Base (Slime)
**Subtask 6.1.1:** Creare scena `Slime.tscn`
- Area2D o RigidBody2D
- Sprite placeholder slime
- Script base con stati: Idle, Patrol, Hunt, Attack

**Subtask 6.1.2:** Implementare stato machine nemica
- `func _physics_process(delta)` controlla stato corrente
- Stato Idle: nessun movimento
- Stato Patrol: muoversi waypoint casuale ogni N secondi
- Stato Hunt: A* toward player position (semplificato, ogni 3 turni)
- Stato Attack: quando player adjacent, eseguire attacco

**Subtask 6.1.3:** Testare AI base
- Subtask 6.1.3a: Nemico patrulla zona iniziale
- Subtask 6.1.3b: Quando player si avvicina, nemico cambia stato Hunt
- Subtask 6.1.3c: Nemico attacca quando player adjacent durante ENEMY_TURN

### Task 6.2: Boss Fight Minima (1^ Bioma)
**Subtask 6.2.1:** Creare scena `BossGolem.tscn`
- NodeBody2D dimensioni maggiori (2 tile x 2 tile)
- PV maggiori (es. 50 invece di 10)
- Attacco più potente (danno 5 invece di 1)
- Animazione speciale "carica" prima attacco

**Subtask 6.2.2:** Implementare fasi boss
- Fase 1: HP > 30 → comportamento normale
- Fase 2: HP 30-15 → attacco più frequente, velocità +20%
- Fase 3: HP < 15 → "Rabbia": attacco ogni turno, velocità +40%

**Subtask 6.2.3:** Testare boss fight
- Subtask 6.2.3a: Combattere boss con PV 50, attacchi da 5 danno
- Subtask 6.2.3b: Riconoscere transizione fasi a HP 30 e HP 15
- Subtask 6.2.3c: Sconfiggere boss → scena victory o progressione bioma

### Task 6.3: Bioma Transition
**Subtask 6.3.1:** Creare sistema cambio bioma
- Completare bioma 1 (terreni di confine) → sbloccare ingresso bioma 2
- Nuova mappa generata con tile differenti (foresta)
- Nuovi nemici spawn bioma 2

**Subtask 6.3.2:** Testare transizione bioma
- Subtask 6.3.2a: Raggiungere fine bioma 1 → porta/ Scala ingresso bioma 2
- Subtask 6.3.2b: Nuova mappa si carica con nemici diversi
- Subtask 6.3.2c: Progresso salvato (turn count, posizione player)

### Task 6.4: Commit
**Subtask 6.4.1:** `git add scenes/Slime.tscn scenes/BossGolem.tscn`
**Subtask 6.4.2:** `git commit -m "feat: single enemy + boss fight
- Slime enemy AI con stato machine Idle/Patrol/Hunt/Attack
- Boss Golem con 3 fasi e HP 50
- Attacchi boss potenti (danno 5)
- Transizione bioma 1→2 con mappa nuova
- Progresso tra fasi salvato"`

---

## FASE 7: Vertical Slice Playable (Ore stimate: 5-6h)
### Task 7.1: End-to-End Gameplay Loop
**Subtask 7.1.1:** Combinare tutti sistemi Fase 1-6 in loop giocabile
- Player muove con arrow keys
- Turno consuma 1 action
- Nemico agisce dopo player
- Attacco funziona adiacente
- Pickup oggetto curativo funziona
- nemico muore a 0 HP

**Subtask 7.1.2:** Testare loop completo "nuova partita → fine bioma 1"
- Step-by-step: aprire progetto, nuova partita, giocare 5 turni completi
- Verificare: turno player→nemico→player, attacchi, HP, oggetti

**Subtask 7.1.3:** Fix bug integration
- Risolvere eventuali conflitti segnali tra sistemi
- Assicurare che `TurnManager` stato sincronizzato su tutti i nodi
- Verificare nessun crash su transizioni rapide

### Task 7.2: Vertical Slice Criteri Accettazione
**Subtask 7.2.1:** Checklist finale (dal spec Fase Zero)
- [ ] Premendo Freccia/Space protagonista si muove tile adiacente
- [ ] Turno si consuma esattamente 1 per azione giocatore
- [ ] Nemico agisce subito dopo giocatore
- [ ] Attacco vicino infligge danno, nemico muore a 0 HP
- [ ] Oggetto pickup ripristina HP, scompare, 1 turno consumato per pickup
- [ ] Due dislivelli funzionano: scala (Z:0→Z:1), ponte (sopra Z:-1 mantiene Z:0)
- [ ] Nessun riferimento "Shannara" visibile nel codice/nomi file

**Subtask 7.2.2:** Registrare video proof-of-concept (opzionale)
- Capture gameplay 10 minuti
- Verificare tutti i criteri sopra

### Task 7.3: Commit Finale e Documentazione
**Subtask 7.3.1:** `git add -A` (tutti i file nuovi/modificati Fase 1-7)
**Subtask 7.3.2:** `git commit -m "feat: vertical slice v0.1 playable demo
- 1 mappa 10x10 tile con 2 dislivelli (scala + ponte)
- Sistema turni deterministico player→nemico
- Nemico Slime AI base patrol→hunt→attack
- Attacco base adiacente con danni
- Oggetto curativo pickup consuma 1 turno
- UI indicatore turno e barra HP
- Nessun riferimento IP Shannara nel codice
- Testato: loop completo giocabile da fermata"`

**Subtask 7.3.3:** Creare `CHANGELOG.md` v0.1
- Lista breve cambiamenti da init a v0.1
- Ore stimate totali, prossimi obiettivi

### Task 7.4: Handoff Report
**Subtask 7.4.1:** Scrivere report breve: "Vertical Slice v0.1 completato in X ore"
**Subtask 7.4.2:** Aggiornare `ROADMAP.md` stato: Fase 7 completata, prossima fase feature expansion
**Subtask 7.4.3:** Pianificare Fase 8 (espansione: bioma 2, nuove abilità, inventory upgrade)

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

### Test Suite Aggiunta (6 file)
- `tests/test_grid_cell.gd` - Verifica GridCell e TerrainType
- `tests/test_grid_system.gd` - Verifica GridSystem con pathfinding
- `tests/test_turn_manager.gd` - Verifica sistema turni
- `tests/test_player.gd` - Verifica movimento player
- `tests/test_combat.gd` - Verifica formula danni
- `tests/test_setup.gd` - Setup/teardown per isolamento test

### Commit Log Fase 1-2
```
a54efe1 feat: complete Fase 1 - core game object definitions
446e30b feat: complete Fase 2 - Grid & Movement system
0f4883c test: add comprehensive test suite for core systems
```

*Note: Ore totali stimate per sviluppatore solitario 10h/settimana ≈ 2.5-3 settimane. Ogni fase è indipendente e testabile prima di passare alla successiva.*