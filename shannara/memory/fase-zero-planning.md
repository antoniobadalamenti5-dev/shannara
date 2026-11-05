# FASE ZERO – PLANNING REPORT
## Dungeon Crawler RPG in Godot Engine 4

*Per sviluppatore solitario, 10 ore settimanali, primo videogioco con Claude Code*

---

## 1. TABELLA DI CONVERSIONE IP & LORE BASE

### Mappatura concettuale Shannara → IP Originale

| Concetto Shannara | Trasposizione IP Originale | Ruolo Narrativo |
|-------------------|---------------------------|------------------|
| Shea Ohmsford (mezzosangue ignaro) | **Kaelen di Valleombra** | Protagonista riluttante, erede di potere antico senza consapevolezza |
| Allanon (druido millenario) | **L'ultimo Veggente dell'Ordine Spezzato** | Guida saggia, custode di conoscenze perdute, mentore simbolico |
| La Spada di Shannara | **La Lama della Risonanza** | Arma che rivela la verità interiore, non semplicemente "verità assoluta" |
| Signore degli Inganni / Warlock Lord | **Il Monarca Sepolto** | Antagonista principale, apparentemente morto ma tornato per reclamare il potere |
| Portatori del Teschio | **Gli Aruspici d'Ombra** | Messaggeri/oracolisti nemici, servitori del Monarca Sepolto |
| Elfi del Nord | **Custodi delle Radici Antiche** | Guardiani della natura, tecnologicamente/spritualmente avanzati ma isolati |
| Nani delle Montagne Nere | **Forgiatori di Valtor** | Artigiani esperti, maestri di armi e lavori di pietra |

### Lore Base Originale (Sintesi)

Il mondo di **Valleombra** un tempo era unito sotto l'ordine dei Veggenti, custodi del equilibrio tra luce e ombra. Quando il **Monarca Sepolto** tentativo di assorbire il potere della **Lama della Risonanza** per l'eternità, fu sconfitto e sigillato nelle profondità della terra. Tuttavia, la sua influenza corrotta permea ancora le terre di confine.

I **Custodi delle Radici Antiche** proteggono conoscenze dimenticate, mentre gli **Aruspici d'Ombra** servono forze sinistre dal sottosuolo. Il protagonista, **Kaelen di Valleombra**, scopre per caso di avere un legame con la Lama della Risonanza, iniziando un viaggio che lo porterà a confrontarsi con il ritorno del Monarca Sepolto e le sue armate di creature corrotte.

---

## 2. ANALISI DEI REQUISITI E GAP ANALYSIS

### Requisiti Tratti dal Concept

| Requisito | Descrizione | Fattibilità 10h/settimana |
|-----------|-------------|---------------------------|
| Movimento griglia 4-direzionale | Protagonista si muove tile per tile | ✅ Alta |
| Sistema a turni deterministico | Ogni azione = 1 turno, nemici reagiscono dopo | ✅ Alta |
| Gestione dislivelli (Z-level) | Ponti, scale, fossati, altezze | ⚠️ Media (richiede design attento) |
| Inventario & equipaggiamento | Oggetti usabili, equipaggiabili | ✅ Alta |
| Combattimento base | Attacco nemico, danni, morte | ✅ Alta |
| Biomi & boss fight | Fine bioma, incontro boss | ⚠️ Bassa (scope esteso) |
| Pixel art dungeon | Asset modulari da internet | ✅ Alta (usando asset esistenti) |
| Ritratti dialogo 2D | Illustrazioni fantasy per scene chiave | ⚠️ Media (risorse esterne) |

### Gap Analysis (Cosa Manca al Concept)

1. **Assenza di sistema di progressione livelli** - Non specificato come guadagno XP, salgo livello, statistiche
2. **Nessuna definizione abilità sbloccabili** - Il sistema di "abilità sbloccabili" non ha meccaniche definite
3. **AI nemica semplificata** - "Comportamenti basati su stati" non specificati oltre Idle/Patrol/Hunt
4. **Manca sistema di salvataggio** - Essenziale per sessioni da 10h/settimana
5. **UI minimal** - Non specificata, ma necessaria per indicatori turni, inventario

### Scelte di Design per Fattibilità 10h/settimana

- **Scope minimo**: Una mappa giocabile, 1 nemico, sistema turni base, 1 attacco, 1 oggetto curativo
- **Asset pipeline**: Usare pixel art modulari esistenti + placeholders per ritratti
- **No engine scripting complesso**: GDScript statico, evitando reflection/duck typing avanzato
- **Testing automatizzato**: Script di asserzione per logiche critiche (consumo turni, formule danno)

---

## 3. ARCHITETTURA SOFTWARE IN GODOT 4

### Moduli Principali (Namespace/Class Pattern)

```gdscript
# class_name declarations (top-level per static typing)
class_name GridCell
class_name GridSystem
class_name TurnManager
class_name ActorController
class_name CombatResolver
class_name InventorySystem
class_name ItemDatabase
```

### Gestione Turno Deterministico Sincrono

```
Flow Turn:
1. Player input → Process Movement/Action (consumes 1 turn)
2. TurnManager avanzamento stato → Enemy Phase attivato
3. Enemy AI calcolo azione (A* grid pathfinding, stato semplice)
4. Enemy action execution → TurnManager fine turno
5. Reset input state, prossimo turno giocatore
```

### Astrazione 3 Coordinate (X, Y, Z/Elevation)

```
TileMap Structure:
- TileMapLayer 0: Ground (Z=0)
- TileMapLayer 1: Bridges/Platforms (Z=-1 sotto, Z=0 sopra)
- TileMapLayer 2: Elevation markers (altezze opzionali)
- TileMapLayer 3: Decorazioni/Wall

GridCell data:
- x: int
- y: int  
- elevation: int (-1=fossato, 0=piano, 1=altura)
- walkable: bool
- occupant: Node|null
- terrain_type: enum("FLOOR", "BRIDGE", "SPIKE", "WALL")
```

### FSM a Eventi Disaccoppiati

```
TurnManager (singleton, leggero)
├── Emits: "turn_start", "turn_end", "action_taken"
├── Listens: "player_input", "enemy_death"
│
GridSystem (singleton)
├── Emits: "move_attempt", "move_completed", "attack_resolved"
│
ActorController (istanza per entità)
├── Riceve eventi da TurnManager
├── Agisce sul GridSystem
│
CombatResolver (utility stateless)
├── Formula danno, calcolo crit, effetti secondari
```

### AI Nemica (Leggero, CPU-friendly)

```
Stati Nemico:
- Idle: nessun action finché player vicino
- Patrol: percorso fisso tile-per-tile
- Hunt: A* toward player position (calcolato ogni N turni)
- Attack: quando player adjacent, roll d'attacco
```

### Target Risoluzione

- **PC Desktop**: 1920x1080 UI, pixel art dungeon scalata con `CanvasItem.filter = Nearest`
- **Interface**: Font pixel, colori ad alto contrasto, indicatori turno visibili

---

## 4. MATRICE DEI RISCHI TECNICI E PRODUTTIVI

| Rischio | Probabilità | Impatto | Strategia Mitigazione |
|---------|-------------|---------|----------------------|
| Debito tecnico da codice "monolita" | Alta | Alta | Moduli piccoli, class_name, FSM rigorosa. No singleton eccessivi. |
| IP transformation inconsistente | Media | Media | Tabella di conversione rigida, check automatizzati prima commit. |
| Sovrapposizione scope (aggiunte feature) | Alta | Alta | Regola d'oro: UNA feature per fase. Approvazione esplicita prima successiva. |
| Difficoltà AI grid pathfinding | Bassa | Media | Usare Godot Navigation2D semplificato, non A* completo ogni frame. |
| Asset pixel art qualità variabile | Alta | Media | Specificare requisiti asset (dimensioni, palette, transparency). Usare placeholder iniziali. |
| Bug turn system "off-by-one" | Alta | Alta | Test automatici consumi turni (vedi sezione testing). |
| Burnout sviluppatore solitario | Alta | Critico | Massimo 2h continui, pause obbligatorie, tracciamento ore settimanali. |
| Claude Code permission prompts | Media | Bassa | Configurare .claude/settings.json allowlist anticipatamente. |

### Strategie Produttive Sviluppatore Soli + Claude Code

1. **Branch per feature**: `feature/<id>-<short-name>`, merge solo dopo test pass
2. **Commit atomici**: Ogni task = un file nuovo o cambiamento definito
3. **Testing inline**: Script GUT dentro ogni modulo, run manuale veloce
4. **Check IP giornaliera**: Script grep che verifica nessuna riferimento Shannara rimanga
5. **Log ore**: Simple txt tracking, rifiuto task se >10h/settimana accumulate

---

## 5. ROADMAP MODULARE A FASI

### Milestone Overview

| Fase | Ore Stimate | Obiettivo | Dipendenze |
|------|-------------|-----------|------------|
| **Fase 0** (corrente) | 2-3 | Analisi, roadmap, spec, tabella IP | — |
| **Fase 1: Project Setup** | 3-4 | Godot project, scene structure, config, README/ARCHITECTURE | Fase 0 approvata |
| **Fase 2: Grid & Movement** | 3-4 | GridSystem, movimento base, Z-level semplici | Fase 1 |
| **Fase 3: Turn System** | 2-3 | TurnManager, ordine azioni, consumo turni | Fase 2 |
| **Fase 4: Combat Basic** | 3-4 | Attack resolution, danni, nemico attacco | Fase 3 |
| **Fase 5: Inventory & Items** | 2-3 | Sistema inventario, oggetto curativo base | Fase 4 |
| **Fase 6: Single Enemy + Boss** | 4-5 | Nemico singolo, AI base, primo boss fight | Fase 5 |
| **Fase 7: Vertical Slice Playable** | 5-6 | 1 mappa completa giocabile dall'inizio alla fine | Fase 6 |

### Distribuzione Ore (Media Settimanale)

- Fase 1-2: Prima settimana
- Fase 3-4: Seconda settimana  
- Fase 5: Terza settimana
- Fase 6-7: Quarta settimana
- **Buffer**: 2 ore/settimana per debugging/imprevisti

### Critical Path

`Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6 → Fase 7`

Solo il completamento di ogni fase sbloga la successiva. Niente parallelismo tra fasi consecutive.

---

## 6. SPECIFICA TECNICA DELLA VERTICAL SLICE

### Perimetro Minimo (v0.1 "Playable Demo")

| Componente | Descrizione | File / Node Chiave |
|------------|-------------|-------------------|
| Mappa | 1 schermata griglia 10x10 tile, 2 dislivelli ( scala + ponte ) | `res://scenes/GridMap.tscn` |
| Protagonista | NodeBody2D, sprite pixel, posizione iniziale (5,5,Z:0) | `res://scenes/Player.tscn` |
| Nemico | NodeArea2D o RigidBody2D semplice, AI patrol semplice | `res://scenes/Slime.tscn` |
| Sistema Turni | TurnManager singleton, consumo 1 turn/action | `res://utils/TurnManager.gd` |
| Attacco Base | Raycast/area check adiacente, danno fisso 10 HP | `res/utils/CombatResolver.gd` |
| Oggetto Curativo | Area2D pickup, ripristina 15 HP, consuma turno pickup | `res://items/HealingPotion.tscn` |
| UI Minimale | Indicatore turno, HP barra sopra protagonista | `res://ui/Overlay.tscn` |

### Criteri di Accettazione Vertical Slice

- [ ] Premendo **Freccia/Space** protagonista si muove tile adiacente (o viene respinto da muro/fall)
- [ ] Turno si consuma esattamente 1 per azione giocatore
- [ ] Nemico agisce subito dopo giocatore (stato Patrol → Move toward player)
- [ ] Attacco vicino infligge danno, nemico muore a 0 HP
- [ ] Oggetto pickup ripristina HP, scompare, 1 turno consumato per pickup
- [ ] Due dislivelli funzionano: scala (Z:0→Z:1), ponte (sopra Z:-1 mantiene Z:0)
- [ ] Nessun riferimento "Shannara" visibile nel codice/nomi file

### Test Automatici Minimi (GUT/Assertion Scripts)

```gdscript
# Test: consumo turno
func test_turn_consumption():
    TurnManager.start_turn()
    Player.move(Vector2(1, 0))
    assert TurnManager.turn_consumed == true
    assert TurnManager.is_player_turn == false

# Test: movimento bloccato da muro
func test_move_blocked():
    Player.position = Vector2(5, 5)
    assert GridSystem.can_move(Vector2(5, 6)) == false
    Player.move(Vector2(0, 1))  # should not move
    assert Player.position == Vector2(5, 5)

# Test: dislivello scala
func test_elevation_stairs():
    Player.position = Vector2(5, 5, elevation=0)
    # Tentativo salita senza scala → respinto
    Player.move_to(Vector2(5, 6, elevation=1))  # without stairs
    assert Player.elevation == 0  # unchanged
    # Tentativo salita CON scala → successo
    Player.move_to(Vector2(5, 6, elevation=1))  # with stairs
    assert Player.elevation == 1  # changed
```

---

## 7. PROSSIMI PASSI PER L'APPROVAZIONE

### Checklist Fase GitHub (non toccare codice prima di approvazione)

- [ ] **Tabella IP convertita**: Verificare che tutti i nomi Shannara siano rimpiazzati coerentemente
- [ ] **Roadmap approvata**: Milestone e ore stimate concordate
- [ ] **Vertical slice scope definito**: Conferma perimetro v0.1 minimamente giocabile
- [ ] **Architettura approvata**: Moduli FSM, grid system, gestione Z-levels
- [ ] **Testing protocollo definito**: Matrice tracciamento feature + test automatici minimi
- [ ] **Asset pipeline**: Strategia pixel art + placeholders concordata
- [ ] **Branch strategy**: `main` + `feature/<id>-<name>`, merge con test passanti

### Cosa Serve per Passare alla FASE GITHUB

1. **Approvazione formale** di questo documento Fase Zero (tutte le sezioni lette e accettate)
2. **Creazione repository struttura base**: `README.md`, `ARCHITECTURE.md`, `GAME_DESIGN.md`, `ROADMAP.md`
3. **Setup .claude/settings.json**: Allowlist permission per tool usati abitualmente
4. **Branch iniziale**: `git checkout -b feature/fase-1-project-setup`
5. **Prime risorse**: Alguna asset placeholder o documentazione inizio

---

*Documento generato per approvazione. Non procedere con sviluppo prima di ricevere conferma esplicita.*