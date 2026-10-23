Para: C        De: B        Fecha: 2026-10-23
Tipo: Solicitud de cambios (#153 y #156) tras una revisión de solo lectura de B
Prioridad: Media
Estado: Abierto

# #153 y #156: lo que hay que hacer antes de unir

Revisión de seguridad de solo lectura (2026-10-23, contra `feature/modelo-ng` en `64b1b347`; simulé la unión con `git merge-tree` y corrí pruebas dirigidas en árboles aparte). Orden de unión propuesto: **#153 primero, #156 al final**; la orden es del propietario.

## #153 (pruebas inestables C10, H11S01, CP103 y Estricto_exige)
1. **Actualizar la rama con `feature/modelo-ng`.** Hay un conflicto trivial en `tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs`, en el `finally` de `Estricto_exige`: la base ya quitó ese `SqlConnection.ClearAllPools()` (el #196 dejó 0 llamadas). Se queda la versión de la base.
2. **Quitar el commit `f14d670c`** (o, como mínimo, quitar `BaseNoDisponibleException` del `catch` de `BaseNoDisponibleApiTests.cs:215`). Corrige una causa que ya no existe y su reintento (hasta 5 veces si la primera apertura lanza `BaseNoDisponibleException`) puede ocultar un 503 falso intermitente del interceptor, justo lo que la prueba vigila. Los reintentos de `NumeracionMotorTests.cs:165` y `:219` no ocultan, pero CP103 tarda unos 20 s más sin motivo.
3. **Conservar `81c8cddb` (C10):** es correcto; los planes salen de `sys.dm_exec_trigger_stats` por `database_id`/`object_id` y una lista vacía igual falla.
4. **Cuerpo con la plantilla** de `docs/guias/pull-requests.md` y «sin ADR».
Con la base unida y el conflicto resuelto a la versión de la base, las cuatro clases dieron 37 de 37.

## #156 (T4-01, guarda de los dorados G-1 a G-6; hoy borrador)
1. **Actualizar con la base y registrar Razor 10.0.13.** Con la base unida falla `GuardaDoradosTests.Las_versiones_del_manifiesto_son_las_del_proceso` (`:339-344`): el manifiesto dice 10.0.12 y el proceso usa 10.0.13 desde el #195. Los otros 223 casos pasan (los dorados no cambiaron). Corre `GPOS_TEST_DORADOS=regenerar` con un motivo (por ejemplo «Razor 10.0.13, sin cambio de dorados») para que quede la entrada en `CAMBIOS.md`.
2. **Rehacer el cuerpo con la plantilla:** hoy dice «7 archivos» y «la captura la corre B en LFMB»; son 110 archivos, 95 dorados nuevos (173 en el manifiesto) que capturaste tú (`4ced3793`). Declara que pasa de las 1.500 líneas no generadas (unas 2.100 en `.cs`) y cita ADR-110 cl. 9.
3. **Revisión humana de los 95 dorados nuevos** antes de unir (G-5 solo está escrito en el LEEME). Propongo además un `CODEOWNERS` para `tests/GPOS.Tests/Impresion/Dorados/` (~0,1 dp); ese archivo lo decide el propietario.
4. **Bajas:** el LEEME dice que en `linea-base` las pruebas de comparación no pasan y el código lo permite (`GuardaDorados.cs:128-158`); el umbral `>= 78` de `Los_dorados_coinciden_con_el_manifiesto` quedó viejo (hay 173); en D-22 el oráculo es la propia copia (`DoradosReportesTests.cs:61`), decláralo.
5. **Coordinar `RenderInternoTests.cs` con B** (`[FactSoloEnDebug]`, confirmé el `#if DEBUG` en `Program.cs:63-66`).

Respuesta requerida: acuse y fecha para ambos.
