# Prueba en el juego — KnuCast 0.1.0-beta (paladín)

Nada de esto está probado todavía. Lo que se ve acá decide si sale la beta.

## Instalar (lo copia el user)
```powershell
robocopy "E:\Repositorios\Personal\KnuCast" "D:\World of Warcraft\_forever_\Interface\AddOns\KnuCast" /MIR /XD .git tests docs .github /XF .gitignore .gitattributes .pkgmeta
```
`/MIR` deja la carpeta del juego igual al repo (borra archivos viejos de KnuCast de una copia anterior; no toca otros addons).

## Lista (paladín 20-25)
1. `/knu cast` → responde con el estado. `/knu cast debug` → anotar lo que imprime (tipo de criatura, botones encontrados, reglas y nombres de hechizo resueltos).
2. Exorcismo en la barra. Apuntar a un **no-muerto** → Exorcismo brilla. Apuntar a una **bestia** → Exorcismo gris. Apuntar a un **elemental** → gris.
3. Lo mismo **en combate** (pegándole al bicho): ¿sigue brillando/gris o se apaga?
4. Expulsar no-muertos (si lo tenés): brilla sólo con no-muertos.
5. Martillo de cólera (nivel 44, si no lo tenés, saltear): brilla al bajar el objetivo de 20 %.
6. Objetivo amistoso o sin objetivo → ninguna marca.
7. Cambiar de barra/página y volver → las marcas siguen en el botón correcto.
8. `/knu cast test` → brillo en todos los botones con regla; otra vez `/knu cast test` lo apaga.
9. `/knu cast sound on` → sonido sólo con interrupción o vida baja (paladín: Martillo de cólera).
10. BugSack / errores de Lua: ¿alguno con «KnuCast» o «secret»?

Mandá captura de `/knu cast debug` y de los puntos 2 y 3.
