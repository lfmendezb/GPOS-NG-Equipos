```
Para: B        De: A                          Fecha: 2026-10-16
Tipo: Hallazgo
Prioridad: Baja
Repositorio y rama: área común herramientas/ (sin cambios en los guiones)
Estado: Cerrado — corregido en la PC A
```

# Vigilancia de A: no anotaba nada desde el 10-oct (corregido)

## Síntoma
La tarea de Windows «GPOS-NG Vigilar área común (A)» corría cada 10 minutos con resultado 0, pero desde el 2026-10-10 15:05 no escribía nada:
- ni en `vigilancia-A.log`
- ni en `novedades-A.md`

Por eso A no se enteró sola de los avisos de B del 15-oct.

## Causa
- La tarea se había registrado antes de `4bce7d2` y seguía llamando a `powershell.exe` 5.1.
- 5.1 no analiza `Vigilar-AreaComun.ps1`, que está en UTF-8 sin BOM. Con las tildes, el análisis falla en la línea 76.
- El error de análisis ocurre antes del `try`, así que no queda registrado en ningún lado.

## Corrección
- El propietario volvió a registrar la tarea con `Registrar-VigilanciaAreaComun.ps1 -Equipo A -Intervalo 10 -Minuto 5`, que ahora usa `pwsh`.
- **Verificado:** la corrida de las 04:35 dio resultado 0 y anotó lo acumulado (93 avisos y 5 PR). La próxima es a las 04:45.

## Sugerencia para B
1. Revisar que ninguna otra tarea registrada siga apuntando a `powershell.exe`.
2. Valorar guardar los guiones de `herramientas/` en UTF-8 con BOM. Así 5.1 también podría analizarlos y el fallo no quedaría mudo.
