# Test Flow Checklist - Verifica Sistema a Turni

## Passi per verificare manualmente in Godot

### 1. Prima di tutto - Pulisci cache
```
Chiudi Godot
Elimina cartella .import/
Riavvia Godot
```

### 2. Verifica che gli script carichino senza errori
- Apri `actors/Player.gd` - VERIFICA "Class 'Player' in scene"
- Apri `actors/Slime.gd` - VERIFICA "Class 'Slime' in scene"
- Apri `actors/BossGolem.gd` - VERIFICA "Class 'BossGolem' in scene"
- Apri `actors/Enemy.gd` - VERIFICA "Class 'Enemy' in scene"
- Apri `scenes/GameRoot.gd` - VERIFICA che non ci siano errori

### 3. Avvia il gioco
- Apri `scenes/GameRoot.tscn`
- Premi F5 (Play Scene)
- Dovresti vedere in alto: "Turno: 1 - Player" con le coordinate del giocatore

### 4. Test Movimento Player
Premi **WASD** o **freccette** per muoverti:
- ✅ Dovrebbe apparire "[Player] move_direction(X, Y) - can_act=true"
- ✅ Il turno deve cambiare da "Player" a "Nemici"
- ✅ Il turn_count deve incrementare

### 5. Test Attacco Player
1. Muovi il giocatore a una posizione dove un Slime si trovi adiacente
2. Premi **F** per attaccare
- ✅ Dovrebbe apparire "[Player] attack_direction(X, Y) - can_act=true"
- ✅ Dovrebbe mostrare "Hai attaccato!"
- ✅ Il turno passa a "Nemici"

### 6. Test Movimento Slime (HUNT)
1. Muovi il giocatore fino a farlo avvicinarsi allo Slime (distanza ≤ 3)
2. Dopo il turno del giocatore, lo Slime dovrebbe:
   - Apparire in console: "[Slime] state=HUNT, distanza al player=X"
   - Muoversi verso il giocatore
   - Il turno torna a "Player"

**Verifica spostamento:**
- Lo Slime inizialmente è a (12, 5), il player a (5, 5)
- Muovi il player a (9, 5) - distanza 3
- Nel turno nemico, lo Slime si muove verso il player

### 7. Test Attacco Nemico
1. Lascia il giocatore con HP > 0
2. Dopo il turno del giocatore, lo Slime attacca (se adiacente)
- ✅ Dovrebbe apparire "[Slime] take_action() ... can_act=true"
- ✅ Dovrebbe apparire "[Slime] nemico adiacente, attacco!"
- ✅ Il turno torna a "Player"

### 8. Console Log Esempio Corretto
```
[GameManager] StartGame() chiamato
[TurnManager] start_player_turn() - changing from state 1 to PLAYER_TURN
[Player] move_direction(1, 0) - can_act=true, pos=5,5
[TurnManager] consume_action() - current_state=0, is_player_turn=true
[GameManager] riceve action_consumed signal!
[GameManager] chiama end_turn()
[TurnManager] end_turn() - current_state=0
[TurnManager] switching to ENEMY_TURN
[Slime] take_action() richiesto...
[Slime] state=HUNT, distanza al player=3
[Slime] stato HUNT, inizio caccia
[TurnManager] Enemy turn complete
[TurnManager] switching to PLAYER_TURN (turn_count=1)
```

### 9. Verifica Movimento Slime Specifico
Se lo Slime non si muove:
1. Controlla che la distanza al player sia ≤ 3
2. Controlla che `find_path()` restituisca un percorso valido
3. Verifica che `is_cell_walkable()` ritorni true per la cella target

## Problemi Comuni

### Errore "Could not resolve class"
- **Causa:** Cache Godot non rigenerata
- **Soluzione:** Chiudi Godot, elimina `.import/`, riavvia

### Nessun movimento Slime
- **Causa:** `path.size() <= 1` nel `_hunt_action()`
- **Verifica:** Aggiungi debug stampa del percorso trovato

### Attacco non funziona
- **Causa:** Nemico non nella cella target
- **Verifica:** Verifica che enemy.grid_x/y coincida con target

### Turno nemico non arriva
- **Causa:** `consume_action()` non chiamato
- **Verifica:** Dovrebbe essere chiamato in `player.move_direction()` o `player.attack_direction()`

## Stato Attuale
- ✅ Player.gd: autonomo, funziona
- ✅ Slime.gd: autonomo, funziona con HUNT, PATROL, IDLE
- ✅ BossGolem.gd: autonomo, funziona
- ✅ TurnManager.gd: gestisce stati turno
- ✅ GameManager.gd: connette segnali
- ✅ GameRoot.gd: spawn nemico a (12,5), patrol points inizializzati
- ✅ InputManager.gd: legge input tastiera
- ✅ Test creati: test_turn_flow.gd, test_gameplay_simple.gd, QuickVerify.gd

## Test Verboli Aggiuntivi
- `tests/run_slime_test.gd` - Test veloce movimento Slime
- `tests/test_slime_movement.gd` - Test unitari movimento Slime