# Registro de cambios

## Unreleased

- Juicio sin Sello ya no se marca: la cruz roja queda sólo para hechizos que no sirven contra el objetivo.
- Un hechizo que no sirve contra el objetivo ahora muestra una cruz roja sobre el botón, para no confundirlo con fuera de rango.
- El brillo se nota más: borde dorado de 4 px que sobresale del botón, relleno más fuerte y latido más rápido.
- Conflagración se pone gris si el objetivo no tiene tu Inmolar.
- Quemadura de maná, Drenar maná y Picadura de víbora se ponen grises contra objetivos sin maná.
- Porrazo, Calmar mente y Calmar animal se ponen grises si el objetivo ya está en combate.
- Más debuffs que brillan cuando faltan: Hender armadura, Grito desmoralizador, Atronar, Rugido desmoralizador, Abrazo vampírico, Succionar vida y las maldiciones de brujo. Banes y maldiciones van por separado, como en Forever: uno de cada uno por objetivo.
- IDs revisadas contra wowhead Forever: Maldición de los elementos usa la 440892; se quitaron Maldición de las Sombras y Fuego feérico feral, que Forever no tiene.
- Si una ID no existe en el cliente, ya no bloquea las marcas, y `/knu cast debug` la muestra como «no existe en este cliente». También muestra cuántos botones usan cada regla.
- Corregido: un debuff con nombres sin cargar del todo podía brillar de más.
- Pasa a KnuLib 6.

## 0.1.0-beta

- Primera versión beta de KnuCast para WoW Forever (`Interface: 16001`).
- Motor por eventos con precedencia de tres estados (`SÍ`, `NO`, `DESCONOCIDO`) y protección completa ante valores secretos (`canaccessvalue` / `issecretvalue`).
- Reglas iniciales por clase para tipo de criatura (`types`), ejecución por acción usable (`execute`), interrupciones (`interrupt`) y debuffs propios (`debuff`).
- Descubrimiento de botones de Blizzard, ElvUI, Bartender4 y Dominos con creación de capas no seguras fuera de combate.
- Alerta sonora opcional (una vez por transición de estado del objetivo) y comandos `/knu cast` (`/knu knucast`).
