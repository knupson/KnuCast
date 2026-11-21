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

## 6. Cambios tras la auditoría de Codex del plan (19/11)
1. **Nombres incompletos (alto, también afecta a `debuff` de la beta):** `Data:BuildIndex` guarda `rule.auraNames`/`rule.debuffNames` junto con `rule.namesComplete = true` sólo si resolvieron TODAS las IDs. Nunca se usa el nombre del hechizo de la acción como sustituto. En `EvalRule`: coincidencia encontrada vale siempre; «ausente» (que da brillo en `debuff` o gris en `requires`) sólo si `namesComplete`; si no, DESCONOCIDO. Cuando una ID pendiente resuelve (`SPELL_DATA_LOAD_RESULT`), `BuildIndex` vuelve a correr y completa el conjunto.
2. **Combate del jugador:** `PLAYER_REGEN_DISABLED` y `PLAYER_REGEN_ENABLED` siempre llaman a `UpdateAll` (manteniendo el `Discover` diferido al salir de combate), porque la legibilidad de auras cambia con las restricciones de combate sin que cambie el objetivo.
3. **Límite del recorrido de auras:** si se llega al índice 100 sin un `nil` legible, el resultado es DESCONOCIDO (`nil`), no «ausente».
4. **Sonido sin recorrido cuadrático:** `Engine.activeKindCounts[kind]` = cantidad de botones con ese tipo activo. `EvaluateButton` resta la contribución anterior del botón y suma la nueva; `UpdateAll` reconstruye desde cero una vez; un botón que deja de ser conocido resta su contribución. La transición (de 0 a >0 en algún tipo) se calcula con los contadores, sin recorrer botones. Test: con N botones de interrupción, N `UpdateButton` hacen O(N) trabajo (contar llamadas a `GetButtonRules`/iteraciones).
5. **Tests de eventos y filtros:** el stub de auras respeta `unit` y `filter` (`HELPFUL`, `HARMFUL|PLAYER`) y los tests verifican los argumentos exactos. `RegisterUnitEvent` conserva el criterio de `Core.lua:97`: si el filtrado nativo funcionó se confía; si no, se guarda `Accessible(unit)` antes de comparar. Tests: unidad secreta, payload de `UNIT_AURA` secreto (no se lee), registro nativo fallido → fallback, nombres parciales, aura en índice 101, transición de combate sin eventos del objetivo.

## 7. Datos de Forever (verificado 19/11 con `https://nether.wowhead.com/forever/tooltip/spell/<id>`)
Las 55 IDs de `Data.lua` se consultaron una por una. Resuelven todas salvo **1490** (Maldición de los elementos), **17862** (Maldición de las Sombras) y **16857** (Fuego feérico feral): «Entity not found» en Forever. Los textos de los tooltips de Forever confirman las condiciones de tipo de criatura, vida ≤ 20 %, interrupciones (Silencio interrumpe 3 s en Forever) y Porrazo «sólo humanoides fuera de combate».
- Maldición de los elementos en Forever = **440892**. Maldición de las Sombras y Fuego feérico feral no existen: se quitan sus reglas y sus IDs de las listas.
- **980 es «Bane of Agony»** en Forever: «sólo un Bane por brujo». Grupo propio de Banes: 980, 603 (Bane of Doom), 1225228 (Bane of Havoc). Grupo de Maldiciones: 440892, 704, 702.
- Juicio: sumar **1311649** (Seal of Fury, sello nuevo de Forever) a la lista de sellos.
- Conflagración: 17962 sigue existiendo en Forever (rango 3; el rango 1 es 1293817) y el addon compara por nombre, así que alcanza con una ID.
- **Robustez:** una ID de `debuff`/`aura` que agotó sus intentos de carga (`MAX_SPELL_REQUESTS`) y no resolvió se considera inexistente en el cliente: deja de bloquear `namesComplete` (un aura que el cliente no conoce no puede estar puesta). `/knu cast debug` la lista como «no existe en este cliente».

## 8. Medido en el juego (KnuSonda 0.7.0, 20/11, build 1.60.1.71037)
Detalle: `E:\Repositorios\Personal\_datos\WOWAddons\knucast\secretos-medidos-2026-11-20.md`.
- En combate `C_UnitAuras.GetAuraDataByIndex` **tira error** para objetivo y jugador con cualquier filtro («Auras cannot be accessed when secret while tainted»). `Secret.OwnAuraState` lo atrapa con `pcall` → DESCONOCIDO. Decisión: se mantiene así; `debuff` y `requires` marcan sólo fuera de combate (antes del pull) y el README lo dice. Alternativa a evaluar más adelante: seguir los debuffs propios por los lanzamientos del jugador (frágil: resistencias, refrescos, muertes).
- Se leen en combate: `UnitCreatureType`, `UnitPowerType`, `UnitAffectingCombat`, `UnitCanAttack`. Secretos: `UnitHealth*` siempre, `UnitPower`/`UnitPowerMax` en combate.
- Barras: `IsUsableAction`, `IsActionInRange`, `GetActionInfo`, `C_Spell.IsSpellUsable` sin secretos, también en combate.
- `UnitCastingInfo` con objetivo lanzando: **sin medir** (pendiente de KnuSonda).
