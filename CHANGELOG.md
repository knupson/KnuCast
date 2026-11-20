# Registro de cambios

## Unreleased

- Nuevas reglas de resaltado: requerimiento de aura propia o en objetivo (`requires`), objetivo sin maná/energía (`mana`) y exigencia de estar fuera de combate (`outOfCombat`).
- Completitud en la resolución de nombres de auras (`namesComplete`); la ausencia de auras (para `debuff` o `requires`) sólo se evalúa como SÍ/NO si resolvieron todos sus IDs.
- Optimización de rendimiento para el sonido al cambiar de estado (evita iterar botones que no tienen tipos elegibles).
- Soporte para maldiciones de brujo (grupo de debuffs compartidos donde la presencia de cualquiera cancela el brillo).
- El comando `/knu cast debug` ahora imprime la cantidad de botones activos que usan cada regla.
- `RegisterUnitEvent` optimizado para `player` (para sellos) y otros eventos dependientes de la unidad.

## 0.1.0-beta

- Primera versión beta de KnuCast para WoW Forever (`Interface: 16001`).
- Motor por eventos con precedencia de tres estados (`SÍ`, `NO`, `DESCONOCIDO`) y protección completa ante valores secretos (`canaccessvalue` / `issecretvalue`).
- Reglas iniciales por clase para tipo de criatura (`types`), ejecución por acción usable (`execute`), interrupciones (`interrupt`) y debuffs propios (`debuff`).
- Descubrimiento de botones de Blizzard, ElvUI, Bartender4 y Dominos con creación de capas no seguras fuera de combate.
- Alerta sonora opcional (una vez por transición de estado del objetivo) y comandos `/knu cast` (`/knu knucast`).
