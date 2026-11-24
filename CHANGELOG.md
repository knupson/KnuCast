# Registro de cambios

## Sin publicar

- La primera vez que entrás con KnuCast (una sola vez por cuenta), el chat muestra dónde marcarlo como favorito en CurseForge y dónde reportar errores. Los mismos links aparecen al final de `/knu cast`.
- KnuLib pasa a la versión 7. En el juego no cambia nada.

## 0.2.1-beta

Sólo cambian textos. El comportamiento del addon es el mismo.

- Se probó en el juego con ElvUI. Las barras de Blizzard, Bartender4 y Dominos todavía no se probaron en el juego, y el README ahora lo dice.
- En el chat en inglés, el estado y el aviso del comando de la cruz decían «grey». Ahora dicen «cross» y «Red cross». En castellano ya decían «cruz».
- La descripción del comando `/knu cast` menciona la cruz.
- El texto de `/knu cast debug` usa palabras separadas («tipo de objetivo», «con regla») y guiones comunes entre los datos.
- Se reescribieron frases del README y de la versión 0.1.0-beta para que se lean más claras.

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
- Marca en tus barras de acción los hechizos que sirven contra el objetivo (brillo) y los que no (capa gris).
- KnuCast no lee datos secretos; si un dato es secreto, no marca.
- Reglas iniciales por clase: tipo de criatura, hechizos que sólo se pueden usar con el objetivo en vida baja, interrupciones cuando el objetivo lanza, y debuffs propios que faltan en el objetivo.
- Busca los botones de las barras de Blizzard, ElvUI, Bartender4 y Dominos. Los botones nuevos que aparecen en combate se marcan al salir del combate.
- Alerta de sonido opcional que suena una vez cada vez que cambia el estado del objetivo.
- Comando `/knu cast` (alias `/knu knucast`).
