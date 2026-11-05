# Game Design Document

Genere: Dungeon Crawler RPG a turni su griglia
Visuale: 2D dall'alto / isometrica con pixel art
Stile artistico: Hibrido low-budget pixel art dungeon + illustrazioni 2D fantasy

## Gameplay Core

### Sistema a Turni Deterministico Sincrono
- Ogni azione consuma esattamente 1 turno
- Player agisce, poi nemico reagisce
- Nessun elemento RNG nel consumo turni o movimento
- Formule danni deterministiche (base + modificatori)

### Movimento ed Esplorazione
- Griglia 4-direzionale (up/down/left/right)
- Blocco su ostacoli (rocce, muri)
- Gestione dislivelli: scale (Z:0↔Z:1), ponti (sopra Z:-1)
- Fossati: attraversabili solo con ponte o specifiche abilità

### Progressione Personaggio
- Livelli XP: guadagno da nemici sconfitti, oggetti, milestone
- Statistiche: PV, Attacco, Difesa, Velocità
- Abilità sbloccabili: al livello 3, 5, 8
- Equipaggiamento: armi, armor, accessori slots

### Inventario
- Slot limitati per tipo (armamento, consumabili, materiali)
- Oggetti curativi (potion, erbe)
- Oggetti equipaggiabili (armi, scudi)
- Gestione peso/volume opzionale

## Biomi e Struttura

- Bioma 1: Terreni di Confine (tutorial, 1 nemico tipo Slime)
- Bioma 2: Foreste Antiche (2 nemici, primi dislivelli)
- Bioma 3: Rovine Maledette (2 nemici, puzzle ambientali)
- Bioma 4: Regione del Fuoco (boss fight finale)
- Ogni bioma: 3-4 stanze per tile, 1-2 dislivelli unici

## UI Minimale
- Indicatore turno corrente (es. "Turno: Giocatore" / "Turno: Nemico")
- Barra HP sopra protagonista
- Icone inventario in alto a destra
- Mini-map opzionale