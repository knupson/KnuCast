# Registro de cambios

## 0.1.0-beta

- Primera versión beta de KnuCast para WoW Forever (`Interface: 16001`).
- Motor por eventos con precedencia de tres estados (`SÍ`, `NO`, `DESCONOCIDO`) y protección completa ante valores secretos (`canaccessvalue` / `issecretvalue`).
- Reglas iniciales por clase para tipo de criatura (`types`), ejecución por acción usable (`execute`), interrupciones (`interrupt`) y debuffs propios (`debuff`).
- Descubrimiento de botones de Blizzard, ElvUI, Bartender4 y Dominos con creación de capas no seguras fuera de combate.
- Alerta sonora opcional (una vez por transición de estado del objetivo) y comandos `/knu cast` (`/knu knucast`).
