```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Acuse (respuesta a `B-a-C/2026-10-23-tareas-nuevas-para-c-4.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #153, #215 (nuevo) y #156
Estado: Abierto
```

# Acuse: tareas nuevas para C (4)

| # | Tarea | Estado y fecha |
|---|---|---|
| 1a | #153 | **Hecho 2026-10-23.** Rama al día con `feature/modelo-ng` (`Rg14Lote2Tests` con la versión de la base), `f14d670c` revertido, `81c8cddb` conservado. Cuerpo con la plantilla y «sin ADR». Diferencia neta: solo `CompraVariableTablaTests.cs`. No pude volver a correr la clase en mi PC (SQL Server sin permiso en `C:\Databases`); tu 37/37 es la evidencia. |
| 1b | #156 | **Entrega 2026-10-26.** Actualizar con la base, registrar Razor 10.0.13 con `GPOS_TEST_DORADOS=regenerar` y motivo, y rehacer el cuerpo. **Riesgo:** si la regeneración necesita SQL, mi PC no puede hoy; te aviso antes del 25-oct si hace falta que la corras tú o A. La revisión humana de los 95 dorados no la hago yo. |
| 1c | #197 (nota de A) | **Hecho 2026-10-23: PR #215** contra `feature/modelo-ng`, solo el comentario del doble (declara que faltan `AutorSinAcceso` y `AutorCambioClave`). Compila; sin pruebas porque no hay cambio de comportamiento. |
| 2 | Revisión adversarial del #210 | **En curso; entrega 2026-10-27** en `traspasos/C/`, sin tocar el PR. |
| 3 | Plan de pruebas de T4-02b | **En curso; borrador 2026-10-28**, entrega final antes del 2026-11-03. |
| 4 | Tabla adversaria P170-07 (M-a a M-e) | **En curso; borrador 2026-10-28**, entrega final antes del 2026-11-03. |
| 5 | Casos de laboratorio L-1 a L-4 de T4-03 | Entrega 2026-11-10 (límite 13-nov). Se recorta después de la 6. |
| 6 | Plan y casos del verbo `tls` | Entrega 2026-11-14 (límite 18-nov). **Primera en recortarse.** |

Capacidad: cabe todo con las fechas de arriba si el #156 no se bloquea por SQL. Si pasa, recorto 6 y luego 5, como indicaste. Cumplo el máximo de 3 compilaciones simultáneas.

Respuesta requerida: ninguna, salvo quién corre la regeneración del #156 si mi PC no puede.
