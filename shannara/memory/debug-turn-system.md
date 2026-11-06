---
name: debug-turn-system
description: Debug del sistema turni - log aggiunti per tracciamento
metadata:
  type: reference
---

## Log di debug aggiunti per tracciare il flusso dei turni

### TurnManager.gd
- `_ready()`: Log inizializzazione, `current_state = 1` inizialmente (ENEMY_TURN)
- `start_player_turn()`: Log cambiamento stato
- `end_turn()`: Log passaggio turni
- `consume_action()`: Log emissione segnale

### GameManager.gd
- `_connect_turn_manager_signals()`: Log connettività segnali
- `_on_action_consumed()`: Log ricezione segnale
- `StartGame()`: Log avvio gioco

### InputManager.gd
- `_handle_key_input()`: Log quando input ignorato per "non è il turno del giocatore"

### GameRoot.gd
- Log verifica `_game_manager != null` prima di chiamare `StartGame()`

### project.godot
- Ordine autoload riorganizzato: TurnManager ora PRIMA di GameManager

## Expected log flow per verifica visiva
1. `[TurnManager] _ready() called`
2. `[GameManager] Connettendo segnali`
3. `[GameManager] StartGame() chiamato`
4. `[TurnManager] start_player_turn()`
5. Muovi giocatore → `[TurnManager] consume_action() emitted`
6. `[GameManager] riceve action_consumed`
7. `[TurnManager] switching to ENEMY_TURN`