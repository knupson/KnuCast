# KnuCast 0.1.0-beta: plan (2026-11-18)

Requisitos del user: `E:\Repositorios\Personal\_datos\WOWAddons\knucast\requisitos-user-2026-11-18.md`.
API de Forever: `E:\Repositorios\Personal\_datos\WOWAddons\knucast\api-forever-2026-11-18.md`.

## Entregable
Addon sin ElvUI como dependencia que, para el objetivo actual (enemigo atacable), dibuja sobre cada botón de acción que contiene un hechizo conocido:
- **brillo** (marco propio animado, no el `ActionButtonSpellAlertManager` de Blizzard) cuando el hechizo sirve;
- **gris** (capa propia oscura semitransparente + icono no tocado) cuando el hechizo no sirve;
- nada cuando no hay dato (valor secreto, sin objetivo, objetivo amistoso, hechizo sin regla).

Sonido opcional (apagado por defecto) cuando un botón pasa a «sirve» por interrupción o vida baja.

## Reglas por condición (motor genérico, datos por clase)
| Condición | Lectura | Brillo | Gris | Si el dato es secreto |
|---|---|---|---|---|
| Tipo de criatura (`types`) | 2.º retorno de `UnitCreatureType("target")` (ID, no texto) | tipo permitido | tipo no permitido | nada |
| Vida baja (`execute`) | `IsUsableAction(slot)` del botón (el juego decide; `UnitHealth` es siempre secreto) | usable y objetivo atacable | no aplica (Blizzard ya lo pinta inusable) | nada |
| Objetivo lanzando (`interrupt`) | `UnitCastingInfo`/`UnitChannelInfo("target")`; si vienen secretos, estado por eventos `UNIT_SPELLCAST_*` del objetivo | lanzando (y no `notInterruptible` si se puede leer) | no aplica | estado por eventos |
| Debuff propio (`debuff`) | `C_UnitAuras.GetAuraDataBySpellName("target", nombre, "HARMFUL\|PLAYER")` | falta el debuff | no aplica | nada |

Todo por eventos (nada de `OnUpdate` ni `C_Timer.NewTicker`): `PLAYER_TARGET_CHANGED`, `UNIT_FLAGS`/`UNIT_FACTION` del objetivo, `UNIT_HEALTH` del objetivo (sólo para volver a preguntar `IsUsableAction`), `ACTIONBAR_UPDATE_USABLE`, `ACTIONBAR_SLOT_CHANGED`, `ACTIONBAR_PAGE_CHANGED`, `UPDATE_BONUS_ACTIONBAR`, `UNIT_SPELLCAST_START/STOP/FAILED/INTERRUPTED/CHANNEL_START/CHANNEL_STOP/INTERRUPTIBLE/NOT_INTERRUPTIBLE` del objetivo, `UNIT_AURA` del objetivo, `SPELLS_CHANGED`, `PLAYER_ENTERING_WORLD`.

Cada lectura se protege con `issecretvalue` (si existe) y `pcall`; un secreto nunca se compara ni se usa en aritmética.

## Botones soportados
Detección por nombre al iniciar y en `PLAYER_ENTERING_WORLD` (fuera de combate): Blizzard (`ActionButton1-12`, `MultiBarBottomLeftButton`, `MultiBarBottomRightButton`, `MultiBarRightButton`, `MultiBarLeftButton`, `MultiBar5-7Button`), ElvUI (`ElvUI_Bar1..15ButtonN`), Bartender4 (`BT4Button1..180`), Dominos (`DominosActionButton1..`). Slot: `button.action`, o `button._state_action` (LibActionButton), o `button:GetAttribute("action")`. Las capas se crean fuera de combate como hijas no seguras del botón; mostrar/ocultar una textura propia no toca nada protegido.

## Datos (hechizos por clase)
Se identifican por **nombre localizado** derivado de un ID base (`C_Spell.GetSpellName(id)` / `GetSpellInfo(id)`) para cubrir todos los rangos y cualquier idioma del cliente. Lista inicial en `Data.lua` (fuente por línea). Probado en el juego: nada todavía; paladín es la prioridad.

## Comandos
`/knu cast` (alias `/knu knucast`): estado y ayuda. `/knu cast sound on|off`, `/knu cast glow on|off`, `/knu cast grey on|off`, `/knu cast debug` (imprime tipo de criatura, secretos y botones encontrados), `/knu cast test` (simula brillo en los botones con regla).

## Fuera de la beta
Detrás/delante del objetivo, objetivo fuera de combate, reacciones (Abrumar, Revancha, Riposte: Blizzard ya las marca), puntos de combo, opciones gráficas.

## Cambios tras la auditoría de Codex del plan (2026-11-18, verificados releyendo la doc)
1. `UnitCreatureType` es `SecretWhenUnitIdentityRestricted`: la doc dice «secreto cuando la unidad no es controlada por un jugador ni está en el grupo» (`SecretPredicatesDocumentation.lua`). En el juego Buscador lo leyó en claro contra un elemental en combate, así que la restricción no está activa en mundo abierto; igual: si viene secreto → DESCONOCIDO (sin capa).
2. Tres estados por condición: SÍ / NO / DESCONOCIDO. Combinación: algún NO → gris; si no, algún SÍ → brillo; si no, nada.
3. Guardas: `canaccessvalue(v)` si existe, si no `not issecretvalue(v)`, si no existe ninguna → accesible. Nunca `if v` sobre un booleano secreto. `pcall` no desclasifica.
4. Debuffs: `C_UnitAuras.GetAuraDataBySpellName` devuelve **nada** si el aura es secreta (precondición `RequiresNonSecretAura`), así que nil no prueba ausencia. Usar `C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL|PLAYER")` en bucle: si un campo leído es secreto → DESCONOCIDO; si se recorre todo en claro sin encontrarlo → NO está (brillo).
5. Lanzando: eventos `UNIT_SPELLCAST_*` también son secretos con la misma restricción; no leer su carga útil. Al cambiar de objetivo, volver a consultar `UnitCastingInfo`/`UnitChannelInfo`. `UNIT_SPELLCAST_INTERRUPTIBLE`/`NOT_INTERRUPTIBLE` no tienen marca de secreto.
6. Usable: `C_ActionBar.IsUsableAction` (respaldo: global `IsUsableAction`). Evento nuevo `ACTION_USABLE_CHANGED` (Blizzard reemplazó `ACTIONBAR_UPDATE_USABLE`, `Shared_ActionButton.lua:257`); se registran los dos. Más `UNIT_MAXHEALTH`.
7. LibActionButton: usar `_state_action` sólo si `_state_type == "action"`.
8. Botones: si el descubrimiento cae en combate, reintentar en `PLAYER_REGEN_ENABLED`.
9. Nombres: si `GetSpellName` devuelve nil, reintentar en `SPELL_DATA_LOAD_RESULT` / `SPELLS_CHANGED`. Macros: fuera de la beta (sólo acciones de tipo `spell`).
10. Sonido: uno por cambio de estado del objetivo, no uno por botón.

## Archivos
`KnuCast.toc`, `Libs/KnuLib` (copia de MINOR 4), `Locales/Locales.lua` (es/en), `Core.lua` (eventos, base de datos guardada), `Data.lua`, `Conditions.lua` (lecturas seguras), `Buttons.lua` (descubrimiento y capas), `Engine.lua` (decide estado por botón), `Sound.lua`, `Commands.lua`, `tests/` (stub de WoW tomado de KnuMail + pruebas del motor con secretos simulados), `.pkgmeta`, `.github/workflows/release.yml` (copia de KnuMail sin ID de CurseForge), README, CHANGELOG, LICENSE (MIT).
