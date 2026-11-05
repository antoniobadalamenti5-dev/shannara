# Roadmap Modulare a Fasi

Progetto: Dungeon Crawler RPG Godot Engine 4
Sviluppatore solitario: 10 ore/settimana
Obiettivo: v1.0 playable complete

## Panoramica Fasi

| Fase | Ore Stimate | Obiettivo | Dipendenze |
|------|-------------|-----------|------------|
| **Fase 0** | 2-3 | Analisi, roadmap, spec, tabella IP | — |
| **Fase 1: Project Setup** | 3-4 | Godot project, scene structure, config | Fase 0 approvata |
| **Fase 2: Grid & Movement** | 3-4 | GridSystem, movimento base, Z-level semplici | Fase 1 |
| **Fase 3: Turn System** | 2-3 | TurnManager, ordine azioni, consumo turni | Fase 2 |
| **Fase 4: Combat Basic** | 3-4 | Attack resolution, danni, nemico attacco | Fase 3 |
| **Fase 5: Inventory & Items** | 2-3 | Sistema inventario, oggetto curativo base | Fase 4 |
| **Fase 6: Single Enemy + Boss** | 4-5 | Nemico singolo, AI base, primo boss fight | Fase 5 |
| **Fase 7: Vertical Slice Playable** | 5-6 | 1 mappa completa giocabile dall'inizio alla fine | Fase 6 |

## Distribuzione Ore Settimanale

- **Settimana 1**: Fase 1-2 (Project Setup + Grid & Movement) — 6-8h
- **Settimana 2**: Fase 3-4 (Turn System + Combat Basic) — 5-7h
- **Settimana 3**: Fase 5 (Inventory & Items) — 2-3h
- **Settimana 4**: Fase 6-7 (Single Enemy + Boss + Vertical Slice) — 9-11h
- **Buffer**: 2 ore/settimana per debugging/imprevisti

## Critical Path

`Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6 → Fase 7`

Solo il completamento di ogni fase sbloga la successiva. Niente parallelismo tra fasi consecutive.

## Milestone

- **M1** (Fase 2): Primo movimento giocatore confermato su griglia ✅
- **M2** (Fase 3): Primo turno completo giocatore→nemico concluso ✅
- **M3** (Fase 4): Primo attacco nemico inflitto confermato ✅
- **M4** (Fase 5): Oggetto curativo pickup funzionante ✅
- **M5** (Fase 7): Vertical slice "1 mappa → fine" giocabile dal nulla ✅ **COMPLETATO**

## Weekly Track

Ogni settimana: check ore accumulate, eventuali ridimensionamenti scope, report findings.

## Fase 7 Completion

**Fine Fase 7**: 2026-11-05

**Sistema completati:**
- GameManager: Orchestratore principale del gioco
- InputManager: Gestione input tastiera (freccette, A, I, SPAZIO, ESC)
- GameUI: Interfaccia utente con HP display e turn counter
- CombatResolver: Aggiornato con signal attack_resolved e supporto get_attack_damage

**Test Suite totale: 14 file**
- test_grid_cell.gd
- test_grid_system.gd
- test_turn_manager.gd
- test_player.gd
- test_combat.gd
- test_combat_flow.gd
- test_enemy_ai.gd
- test_inventory.gd
- test_biome.gd
- test_gameplay.gd (nuovo)
- test_game_manager.gd (nuovo)
- test_input_manager.gd (nuovo)
- test_setup.gd

**Stato Progetto**: ✅ **COMPLETATO** - Dungeon Crawler RPG con vertical slice giocabile