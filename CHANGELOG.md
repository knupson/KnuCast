# Registro de cambios

## 0.2.0-beta

Probado en el juego con un paladín y ElvUI el 22/11/2026. Las demás clases todavía no se probaron.

- Si un hechizo no sirve contra el objetivo, el botón lleva una cruz roja sobre un velo oscuro. Antes era sólo una capa gris, que se confundía con el fuera de rango de la barra.
- El brillo es un borde dorado de 4 px que sobresale del botón, con relleno más fuerte y latido más rápido.
- Quemadura de maná, Drenar maná y Picadura de víbora llevan la cruz contra objetivos sin maná.
- Porrazo, Calmar mente y Calmar animal llevan la cruz si el objetivo ya está en combate.
- Brillan cuando faltan en el objetivo: Hender armadura, Grito desmoralizador, Atronar, Rugido desmoralizador, Abrazo vampírico, Succionar vida y las maldiciones de brujo. Banes y maldiciones van por separado, porque Forever permite uno de cada uno por objetivo.
- Juicio sin Sello y Conflagración sin Inmolar no se marcan.
- Las IDs se revisaron contra wowhead Forever. Maldición de los elementos usa la 440892, y se quitaron Maldición de las Sombras y Fuego feérico feral, que Forever no tiene.
- Una ID que no existe en el cliente ya no frena las marcas. `/knu cast debug` la muestra como «no existe en este cliente», y para cada regla dice cuántos botones la usan, si se cumple y qué marca tiene.
- Corregido: un debuff cuyos nombres no habían terminado de cargar podía brillar sin motivo.
- Pasa a KnuLib 6.

## 0.1.0-beta

- Primera versión beta de KnuCast para WoW Forever (`Interface: 16001`).
- Motor por eventos con precedencia de tres estados (`SÍ`, `NO`, `DESCONOCIDO`) y protección completa ante valores secretos (`canaccessvalue` / `issecretvalue`).
- Reglas iniciales por clase para tipo de criatura (`types`), ejecución por acción usable (`execute`), interrupciones (`interrupt`) y debuffs propios (`debuff`).
- Descubrimiento de botones de Blizzard, ElvUI, Bartender4 y Dominos con creación de capas no seguras fuera de combate.
- Alerta sonora opcional (una vez por transición de estado del objetivo) y comandos `/knu cast` (`/knu knucast`).
