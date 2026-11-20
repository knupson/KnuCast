# KnuCast → KnuLib MINOR 5 (2026-11-19)

Pedido del Integrador. KnuLib `E:\Repositorios\Personal\KnuLib`, MINOR 5 en `df48db3` (README en `77b4435`).

1. Copiar `KnuLib.lua` de MINOR 5 a `Libs/KnuLib/` (el `.xml` y `LibStub` ya son iguales; verificado con `diff` sin CR).
2. `Core.lua`: borrar el `ApplyDefaults` local y usar `KL:ApplyDefaults(_G.KnuCastDB, self.DEFAULTS)` (misma semántica: merge recursivo, sólo completa `nil`, reemplaza no-tablas por tabla cuando el default es tabla).
3. `Core.lua`: `ns.events` pasa a ser `KL:NewEvents()`. `ns:RegisterEvent(event, handler)` queda como envoltorio que registra `function(...) handler(event, ...) end` con `ns.events:On`, para que los handlers actuales (que reciben el nombre del evento como primer argumento) no cambien. Se borra `ns.frame`/`KnuCastFrame` y `ns:FireEvent` (sin otros usos; el stub de tests dispara los frames directamente). Si `On` devuelve `false` (evento inexistente en Forever, p. ej. `ACTIONBAR_UPDATE_USABLE`), se ignora como hoy (antes: `pcall` del `RegisterEvent`).
4. El frame de eventos del objetivo (`RegisterTargetEvent`, `RegisterUnitEvent` con `'target'`) **no** cambia: `NewEvents` no filtra por unidad.
5. `Commands.lua`: `ns:RegisterEvent('PLAYER_LOGIN', ...)` → `KL:OnLogin(function() Commands:Register() end)`. Sigue sin registrar el comando al cargar el archivo (antes del login).
6. Tests: `luajit tests/run.lua` carga la KnuLib real desde el `.toc`; tienen que seguir pasando los 151. Se agregan: `ns.events` es un objeto de `NewEvents`; un handler recibe el nombre del evento como primer argumento; `ApplyDefaults` respeta valores guardados.
