# KnuCast — segunda tanda de condiciones (2026-11-19)

Pedido del user (19/11): sumar las cuatro ideas. Todo sigue las reglas de `plan-beta.md` (tres estados, nada de OnUpdate, guardas de secretos, sin comparar valores secretos).

## 0. Pendientes de la auditoría anterior
- **Recorrido cuadrático:** `Engine:CheckSoundTransition` recorre `ns.Buttons.list` en cada `UpdateButton`. Cambiar a recorrer sólo `self.buttonActiveKinds` (que guarda únicamente botones con tipos elegibles para sonido), saltando botones que ya no están en `ns.Buttons.known`. Si `ns.db.sound` está apagado, igual se actualiza `prevActiveKinds` (para no sonar de golpe al prenderlo).
- **Debug por regla:** `/knu cast debug` imprime en cada regla cuántos botones de las barras la tienen (`Regla %d: %s (%s) — %d botones`). Contar una sola pasada por `ns.Buttons.list` con `GetButtonRules`.

## 1. Tipos de regla nuevos (Engine:EvalRule)
Ninguno de estos tipos produce brillo: sólo NO (gris) o DESCONOCIDO (sin marca). El brillo queda para las condiciones existentes. Por eso un hechizo con dos reglas (p. ej. Porrazo: `types` + `outOfCombat`) brilla por el tipo y se pone gris si el objetivo está en combate (cualquier NO gana).

| kind | Lee | NO cuando | Si no se puede leer |
|---|---|---|---|
| `requires` | Auras propias en `rule.auraUnit` (`'player'` con filtro `HELPFUL`, o `'target'` con `HARMFUL\|PLAYER`) por nombre resuelto de `rule.aura` (lista de IDs) | Se leyeron todas las auras en claro y ninguna coincide | DESCONOCIDO |
| `mana` | `UnitPowerType(unit)`; si es 0 (maná), `UnitPowerMax(unit, 0)` | powerType accesible y ≠ 0, o powerMax accesible y == 0 | DESCONOCIDO (UnitPowerMax tiene `SecretWhenUnitPowerMaxRestricted`) |
| `outOfCombat` | `UnitAffectingCombat(unit)` | devuelve `true` accesible | DESCONOCIDO |

- `Secret.PlayerDebuffState(unit, names)` se generaliza a `Secret.OwnAuraState(unit, names, filter)` (mismo recorrido por índice, mismo manejo de secretos); `PlayerDebuffState` queda como envoltorio para no romper llamadas ni tests.
- Las comparaciones (`~= 0`, `== 0`, `== true`) sólo después de `Secret.Accessible` y `type(...) == 'number'/'boolean'`.
- Los nombres de `rule.aura` se resuelven en `Data:BuildIndex` igual que `rule.debuff` (pendientes + `RequestSpellLoad`), en `rule.auraNames`.

## 2. Eventos nuevos
- Aura del jugador (Sellos): `UNIT_AURA` filtrado a `'player'`. Hace falta un registro por unidad distinto del de `'target'`: generalizar `ns:RegisterTargetEvent` a `ns:RegisterUnitEvent(unit, event, handler)` con un frame por unidad (`KnuCastPlayerFrame`), manteniendo `RegisterTargetEvent` como envoltorio. Sólo se registra si la clase del jugador tiene alguna regla con `auraUnit = 'player'` (hoy paladín) — o siempre, si es más simple; el costo es una evaluación por cambio de aura propia.
- Maná del objetivo: `UNIT_DISPLAYPOWER` y `UNIT_MAXPOWER` del objetivo → `UpdateAll`.
- Combate del objetivo: `UNIT_FLAGS` ya está registrado (cambia al entrar/salir de combate).

## 3. Datos nuevos (IDs pendientes de la auditoría de Gemini en `scratchpad/ids/audit-ids.md`; sólo entran las verificadas)
- `requires`: Juicio (20271) con `auraUnit='player'`, `aura` = rango 1 de los seis Sellos; Conflagración (17962) con `auraUnit='target'`, `aura = {348}` (Inmolar).
- `mana`: Quemadura de maná (8129), Drenar maná (5138), Picadura de víbora (3034).
- `outOfCombat`: Porrazo (6770), Calmar mente (453), Calmar animal (2908) — reglas extra, se mantienen las de `types`.
- `debuff`: Hender armadura 7386, Grito desmoralizador 1160, Atronar 6343, Rugido desmoralizador 99, Fuego feérico (feral) 16857, Abrazo vampírico 15286, Succionar vida 18879, maldiciones 1490/17937/704/702 (+ la existente 980).
- **Maldiciones:** un brujo pone una sola maldición por objetivo; todas las reglas de maldición comparten `debuff` = las cinco maldiciones, así ninguna brilla si ya hay una propia.

## 4. Configuración
- `ns.DEFAULTS.conditions` suma `requires`, `mana`, `outOfCombat` (todos `true`).
- Locales: textos nuevos en castellano.

## 5. Tests (`tests/run.lua`, `luajit`)
Por cada tipo nuevo: NO / DESCONOCIDO con valores claros, secretos y funciones ausentes; Porrazo con humanoide en combate → gris; Juicio sin sello → gris, con sello → sin marca; maldiciones compartidas; `CheckSoundTransition` ya no recorre `Buttons.list` (contar llamadas); debug imprime el conteo por regla; `RegisterUnitEvent('player', ...)` sólo dispara con `unit == 'player'`.
