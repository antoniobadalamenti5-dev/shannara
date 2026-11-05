# Architettura del Sistema

Motore: Godot Engine 4.x (GDScript staticamente tipizzato)
Target: PC Desktop 1920x1080

## Moduli Principali

- **GridSystem**: Gestione mappa a griglia 2D con astrazione 3 coordinate (X, Y, Z/Elevation)
- **TurnManager**: Sistema a turni deterministico sincrono, FSM a eventi disaccoppiati
- **ActorController**: Controllo entità giocatore e nemici
- **CombatResolver**: Risoluzione attacchi, formule danni, effetti secondari
- **InventorySystem**: Gestione inventario, equipaggiamento, oggetti consumabili
- **ItemDatabase**: Catalogo dati oggetti e attrezzature

## Gestione Dislivelli (Z-Level)

- TileMapLayer 0: Ground (Z=0)
- TileMapLayer 1: Bridges/Platforms (Z=-1 sotto, Z=0 sopra)
- GridCell elevation: -1=fossato, 0=piano, 1=altura
- Regole passaggio: scala Z:0→Z:1, ponte sopra Z:-1 mantiene Z:0

## AI Nemica

Stati: Idle → Patrol → Hunt (A* calcolato ogni N turni) → Attack
Ottimizzato CPU: pathfinding non ogni frame, stato machine leggera.

## Risoluzione

1920x1080 nativo UI, pixel art dungeon scalata con `CanvasItem.filter = Nearest`.