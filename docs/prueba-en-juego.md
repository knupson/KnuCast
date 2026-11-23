# Prueba en el juego: KnuCast (rama `condiciones-2`, paladín)

Nada de esto está probado todavía en el juego. Lo que se ve acá decide si sale la beta.

## Instalar (lo copia el user)
```powershell
robocopy "E:\Repositorios\Personal\KnuCast" "D:\World of Warcraft\_forever_\Interface\AddOns\KnuCast" /MIR /XD .git tests docs .github /XF .gitignore .gitattributes .pkgmeta
```
`/MIR` deja la carpeta del juego igual al repo: borra archivos viejos de una copia anterior de KnuCast y no toca otros addons. Después, `/reload` o entrar al personaje.

## Lista (paladín) y qué tendrías que ver
1. `/knu cast` → una línea de estado (brillo, gris, sonido, prueba).
2. `/knu cast debug` con un bicho en el objetivo → tipo de criatura (número o `secreto`), botones encontrados y una línea por regla de paladín: Exorcismo, Cólera sagrada, Expulsar no-muertos, Martillo de cólera, Juicio, cada una con su nombre y la cantidad de botones que la usan. Si alguna dice `pendiente` o `no existe en este cliente`, mandá captura.
3. Exorcismo en la barra. Objetivo **no-muerto** o **demonio** → brilla. **Bestia** o **humanoide** → gris.
4. Lo mismo **en combate**, pegándole al bicho: ¿sigue igual o se apaga?
5. **Juicio sin Sello** puesto → gris. Con cualquier Sello (Rectitud, Cruzado, Furia…) → sin marca.
6. Martillo de cólera (nivel 44; si no lo tenés, salteá) → brilla cuando el objetivo baja de 20 % de vida.
7. Objetivo amistoso o sin objetivo → ninguna marca.
8. Cambiar de página de barra y volver → las marcas siguen en el botón correcto.
9. `/knu cast test` → brillo en todos los botones con regla; otra vez `/knu cast test` lo apaga.
10. BugSack o errores de Lua: ¿alguno que diga «KnuCast» o «secret»?

Mandá captura de los puntos 2, 3, 4 y 5.
