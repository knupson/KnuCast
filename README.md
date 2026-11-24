# KnuCast

Addon para World of Warcraft (Forever, interfaz `16001`) que resalta en las barras de acción los hechizos situacionales de tu clase según el estado del objetivo enemigo actual:

- El botón brilla en dorado, con un latido, cuando el hechizo aplica: tipo de criatura válido, rango de ejecución usable, lanzamiento interrumpible o debuff propio ausente.
- El botón lleva una cruz roja cuando el hechizo no sirve contra ese objetivo, para no confundirla con el fuera de rango de la barra: tipo de criatura que no corresponde, objetivo sin maná, o objetivo ya en combate con un hechizo que sólo sirve fuera de combate.
- No hay marca cuando no hay objetivo atacable o el dato no está disponible.

Se probó en el juego con ElvUI. El código también reconoce los botones de Blizzard, Bartender4 y Dominos, pero esas barras todavía no se probaron en el juego. No depende de ninguna de ellas.

## Comandos

- `/knu cast` (alias `/knu knucast`): muestra el estado actual y la ayuda.
- `/knu cast glow on|off`: activa o desactiva el borde de brillo.
- `/knu cast grey on|off`: activa o desactiva la cruz roja (y su velo).
- `/knu cast sound on|off`: activa o desactiva el sonido cuando el objetivo empieza a lanzar (interrupciones) o entra en vida baja (Martillo de cólera, Ejecutar). Apagado por defecto.
- `/knu cast debug`: imprime el ID de tipo de criatura del objetivo (o `secreto`), estado de lanzamiento, botones detectados y botones con regla.
- `/knu cast test`: alterna el modo de prueba (muestra brillo en todos los botones con regla hasta volver a ejecutar `/knu cast test`).

## Estado de pruebas

Probado en el juego: paladín (22/11/2026, con ElvUI): tipos de criatura, Martillo de cólera sin probar (falta nivel), brillo dorado y cruz roja. Las demás clases, sin probar.

## Límites

- Cuando el cliente restringe la lectura de un dato del objetivo (son los valores secretos, `canaccessvalue` / `issecretvalue`), KnuCast no dibuja ninguna marca, ni brillo ni cruz.
- Medido en el juego el 20/11 (build 1.60.1.71037): en combate, Forever no deja que ningún addon lea auras (`C_UnitAuras.GetAuraDataByIndex` da error). Por eso los debuffs propios que faltan (Palabra de las Sombras: Dolor, Corrupción, etc.) sólo se marcan fuera de combate, y en combate esos botones quedan sin marca.
- El tipo de recurso del objetivo se lee siempre, pero cuánto maná tiene es secreto en combate. Un objetivo que no usa maná lleva la cruz y uno con maná queda sin marca.
- Las macros quedan fuera del alcance de la beta: sólo se evalúan las ranuras de acción de tipo `spell`.
- Las capas visuales se crean únicamente fuera de combate. Si aparecen botones nuevos durante el combate, su creación se difiere a `PLAYER_REGEN_ENABLED`.

## Opiniones y errores

Si KnuCast te sirve, marcalo como favorito (la estrella) en [CurseForge](https://www.curseforge.com/wow/addons/knucast) y dejá un comentario: así lo encuentran otros jugadores de Forever.

Si encontrás un error, abrí un [issue en GitHub](https://github.com/knupson/KnuCast/issues) o dejá un comentario en CurseForge. Pegá el texto del error que copia BugSack y contá qué estabas haciendo. Las ideas y los pedidos también se reciben ahí.

## Feedback and bugs

If KnuCast is useful to you, add it to your favorites (the star) on [CurseForge](https://www.curseforge.com/wow/addons/knucast) and leave a comment. That helps other Forever players find it.

If you find a bug, open an [issue on GitHub](https://github.com/knupson/KnuCast/issues) or leave a comment on CurseForge. Paste the error text from BugSack and say what you were doing. Ideas and requests are welcome there too.
