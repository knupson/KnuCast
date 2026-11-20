# KnuCast

Addon para World of Warcraft (Forever, interfaz `16001`) que resalta en las barras de acción los hechizos situacionales de tu clase según el estado del objetivo enemigo actual:

- **Brillo animado propio** cuando el hechizo aplica (tipo de criatura válido, rango de ejecución usable, lanzamiento interrumpible o debuff propio ausente).
- **Capa gris oscura** cuando el hechizo está restringido (tipo de criatura no correspondiente, auras requeridas ausentes, recurso no agotado o si requiere estar fuera de combate).
- **Sin marca** cuando no hay objetivo atacable o el dato no está disponible.

Soporta botones de Blizzard, ElvUI, Bartender4 y Dominos sin depender de ninguno de ellos.

## Comandos

- `/knu cast` (alias `/knu knucast`): muestra el estado actual y la ayuda.
- `/knu cast glow on|off`: activa o desactiva el borde de brillo.
- `/knu cast grey on|off`: activa o desactiva la capa gris.
- `/knu cast sound on|off`: activa o desactiva el sonido cuando el objetivo empieza a lanzar (interrupciones) o entra en vida baja (Martillo de cólera, Ejecutar). Apagado por defecto.
- `/knu cast debug`: imprime el ID de tipo de criatura del objetivo (o `secreto`), estado de lanzamiento, botones detectados y botones con regla.
- `/knu cast test`: alterna el modo de prueba (muestra brillo en todos los botones con regla hasta volver a ejecutar `/knu cast test`).

## Estado de pruebas

Probado en el juego: nada todavía; prioridad paladín.

## Límites

- **Valores secretos (`secret values`)**: cuando el cliente restringe la lectura de un dato del objetivo (`canaccessvalue` / `issecretvalue`), KnuCast no dibuja ninguna marca (ni brillo ni gris).
- **Macros**: fuera del alcance de la beta (sólo se evalúan ranuras de acción de tipo `spell`).
- **Combate**: las capas visuales se crean únicamente fuera de combate; si se detectan botones nuevos durante el combate, su creación se difiere a `PLAYER_REGEN_ENABLED`.
