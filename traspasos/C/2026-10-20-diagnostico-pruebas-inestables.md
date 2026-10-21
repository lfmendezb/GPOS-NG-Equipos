# Diagnóstico de tres pruebas inestables (encargo de B, tarea 3 del 2026-10-20)

Rama: `c/pruebas-inestables-r02-super-dl22` (worktree `GPOS-C-inestables`), desde `origin/feature/modelo-ng` @ `b8f166db`. Sin push. Tres commits, uno por causa, solo pruebas.
Instancia: `GPOST_TEST_SERVER=.\SQLEXPRESS`. Una compilación o corrida a la vez, sin suites completas ni carga. Marca **[I]** = inferido, no reproducido: esta PC no puede reproducir la falla bajo carga.

Corrección al encargo: `DL22_S18_…` está solo en `tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs:502`; la coincidencia de `NegativosNucleoTests.cs:311` es `N1_24_R02_…`, otra prueba.

| Prueba | Causa | Arreglo | Va a B |
|---|---|---|---|
| `R02_…` | La cuenta de lecturas de la política no tolera que el plan salga de la caché entre las dos lecturas **[I]** | Hecho en la rama (`73fbdf78`) | No |
| `Un_Super_Usuario_inhabilitado_…` | El inicio de sesión en AJENA (base inexistente) sufre un error de infraestructura y la API responde, con razón, «No se pudo conectar» **[I]** | Hecho en la rama (`b073f390`) | No |
| `DL22_S18_…_en_1_s` | El tope de 1,5 s de reloj mide también el inicio de sesión físico de la lectura y su reintento bajo carga **[I]** | Hecho en la rama (`c9045630`) | No |

Ninguna toca código de producción. No hay Hallazgo para B.

---

## 1. `NegativosPoliticaPreparacionTests.R02_la_politica_se_lee_una_vez_por_venta_de_20_renglones_y_las_unidades_van_por_llave`

**Síntoma.** Falla en las suites oficiales bajo carga y pasa sola (avisos de A del 2026-10-20: `pr103-dv07-y-reparto-adr90.md:14`, `revision-pr103-dv07.md:26`). Los avisos no traen el mensaje de falla.

**Causa [I].**
- La prueba cuenta las lecturas de la política de una venta como diferencia de `execution_count` entre dos lecturas de la caché de planes (`NegativosPoliticaPreparacionTests.cs:53-55` y `:59` antes del arreglo: `antes` → `VenderAsync` → `SentenciasAsync` → `Assert.Equal(1, Ejecuciones(...) - antes)`).
- Si el plan sale de la caché o se recompila entre esas lecturas, el contador vuelve a 0 y la diferencia da 0 o un número negativo.
- El propio archivo reconoce la eviction («Con otras suites en la misma instancia el plan puede salir de la caché entre la venta y la lectura (visto el 2026-10-16 en «.»)», antes `:67-68`) y la tolera con un bucle de reintento, pero el bucle está **después** de la aserción de la línea 59. Esa aserción quedaba sin protección.
- La base es propia (`BaseDatosFixture`), así que el plan no sale por otras bases. Salen la presión de memoria del plan en la instancia compartida y una recompilación del enunciado, por ejemplo por actualización automática de estadísticas tras crear unos 340 artículos.
- No pude ver la falla real. Lo que sí verifiqué es la mecánica: con `ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE` entre la venta y la lectura, la prueba original falla con `Expected: 1, Actual: -21` (`antes` vale 21: 20 lecturas al crear los artículos con existencia inicial y 1 de la venta).

**Arreglo (hecho, `73fbdf78`).** La medición se repite (hasta 5 ventas) mientras la diferencia no sea positiva. Una diferencia positiva siempre vale, así que dos lecturas o las 20 por renglón siguen haciendo fallar la prueba. La existencia esperada descuenta las ventas realizadas (`(100 − ventas) × 20`) en vez de fijar 98.

**Riesgos que quedan en la misma prueba (no tocados, [I]).**
- `Assert.Single(...)` por marca (`:76`): falla si el mismo enunciado aparece en dos planes.
- `Concesion` exacta: 0 para la política y ≤ 1024 KB para las unidades.
- El catálogo se crea con 8 tareas en paralelo.
Si vuelve a fallar con otro mensaje, esos son los siguientes sospechosos.

**Corridas literales** (`dotnet test … --no-build --filter "FullyQualifiedName~NegativosPoliticaPreparacionTests"`):
- Antes del arreglo, sola: `Correctas: 2/2` (1 vez, 7 s la R02).
- Prueba original con la caché vaciada a propósito: `Con error! … Expected: 1 / Actual: -21` (temporal, revertido).
- Arreglo con la caché vaciada a propósito tras la primera venta medida: `Correctas! - Con error: 0, Superado: 1, Total: 1` (temporal, revertido).
- Arreglo, 5 vueltas seguidas:
  ```
  Correctas! - Con error: 0, Superado: 2, Omitido: 0, Total: 2, Duración: 14 s
  Correctas! - Con error: 0, Superado: 2, Omitido: 0, Total: 2, Duración: 14 s
  Correctas! - Con error: 0, Superado: 2, Omitido: 0, Total: 2, Duración: 14 s
  Correctas! - Con error: 0, Superado: 2, Omitido: 0, Total: 2, Duración: 13 s
  Correctas! - Con error: 0, Superado: 2, Omitido: 0, Total: 2, Duración: 13 s
  ```

---

## 2. `EsquemaPendienteAccesoTests.Un_Super_Usuario_inhabilitado_pierde_el_modo_limitado_con_su_token_vigente`

**Síntoma.** Falla una vez en la suite oficial con «no se pudo conectar a la base de la empresa» y pasa sola (`A-a-B/2026-10-20-pr103-revision-atendida.md:16`; antes, `C-a-B/2026-10-16-suite-oficial-pr52-pr48.md:24` y `B/2026-10-15-traspaso…:72`).

**Causa [I].**
- La prueba entra como GSF a AJENA, una empresa cuya base **no existe** (`EsquemaPendienteAccesoTests.cs:428` antes del arreglo).
- En `AuthEndpoints.DestinoAsync` (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:331-355`), `HabilitadasAsync` da 4060. `SucursalesEmpresa.EsquemaPendienteAsync` → `BaseNoExisteAsync` (`src/GPOS.Core/Sistema/SucursalesEmpresa.cs:42-90`) abre una conexión nueva a `master` para ver si la base existe, y repite esa consulta **una sola vez** (500 ms) ante un error transitorio (PC3-02).
- Si ese segundo intento también falla (233, tiempo vencido, 1205 con la instancia cargada), devuelve false. Entonces `DestinoAsync` loguea el error y lanza `MensajeSinConexion`: 400 «No se pudo conectar con la base de datos de la empresa Empresa ajena QA. Intente de nuevo…». La prueba espera 200 (`Es(OK, r, "GSF en AJENA")`).
- Por qué esta prueba y no otras de la clase: es la **única de la suite oficial** que pasa por la rama del 4060 con `master`. La de NUEVA, que hace lo mismo, es `Transicion=Defecto` y el filtro oficial la excluye. Las demás entran a VACIA o LISTA, cuya base existe y no consultan `master`.
- El comportamiento de producción es correcto: el mensaje dice «Intente de nuevo» y es un error de infraestructura.
- Es el mismo patrón que A resolvió para «Probar» en `ProbarSinTransporteAsync` (`:320`, commit `54950826`), que no cubría el inicio de sesión.
- Descarté que falle después del login: las peticiones posteriores solo leen `GPOS_SYSDATA` (`ModoEsquemaPendiente.cs:49-55`) o se rechazan antes de llegar a la base de la empresa.

**Arreglo (hecho, `b073f390`).** `EntrarSinTransporteAsync` repite hasta 5 veces (200 ms × intento) **solo** la respuesta 400 con el texto exacto `AuthEndpoints.MensajeSinConexion(<descripción>)`. Es seguro repetir: `DestinoAsync` va antes de abrir la sesión (`AuthEndpoints.cs:93`). Se usa solo en esta prueba. La empresa CAIDA, que sí debe dar ese texto, sigue con `EntrarAsync`.

**Exposición parecida que no toqué.**
- Los demás `EntrarAsync` a VACIA, NUEVA y LISTA tienen el mismo riesgo, menor porque no consultan `master`.
- Si vuelve a fallar otra de la clase con el mismo texto, el arreglo es el mismo.

**Corridas literales** (`--filter "FullyQualifiedName~EsquemaPendienteAccesoTests&Transicion!=Defecto"`):
- Antes del arreglo, 3 vueltas: `Correctas! … Superado: 8, Total: 8, Duración: 1 m 3 s / 1 m 2 s / 1 m 2 s`.
- Después, 3 vueltas: `Correctas! - Con error: 0, Superado: 8, Omitido: 0, Total: 8, Duración: 1 m 2 s` (×3).

---

## 3. `Rg14Lote2Tests.DL22_S18_al_inhabilitar_la_empresa_deja_de_abrir_conexiones_en_1_s`

**Síntoma.** Prueba de tiempo. Solo la cita B; no hay mensaje de falla en los avisos.

**Causa [I].**
- El tope `dejada <= ComprobacionCadenaSegundos + 0.5` (1,5 s) estaba en `Rg14Lote2Tests.cs:532` (antes del arreglo). Medía con reloj el tiempo hasta que `ObtenerAsync` dejaba de dar la cadena, y ese tiempo incluye:
  1. lo que falta del segundo de `Comprobada`;
  2. el inicio de sesión físico de la lectura. `ComprobarAsync` usa su propia cadena con `ConnectTimeout = 3` (`EmpresasService.cs:105`), que es **otro grupo**, y en esta prueba esa cadena nunca se había abierto;
  3. la consulta;
  4. un fallo transitorio de esa lectura, que conserva la vigente, reinicia `Comprobada` (`:115-117`) y repite **un segundo después**. Así el tiempo pasa de 2 s y se pierde el tope.
- Medición sin carga con una instrumentación temporal, revertida: `dejada` = 894, 904 y 890 ms. Eso deja ≈ 600 ms de margen para el inicio de sesión y la consulta. Bajo carga, un inicio de sesión de varios cientos de ms, o un solo fallo transitorio, supera el tope aunque la caché cumpla.
- El tope no es un contrato con otro componente: a diferencia de `CambioClaveAnteriorSegundos` en DL22 b+, aquí no hay un plazo posterior que dependa de él.
- La propiedad que importa es que **el intervalo de la comprobación sea 1 s**. La petición que comprueba espera su propia lectura (`ObtenerAsync` → `ComprobarAsync` → `return null`), así que el tiempo que tarde SQL Server no forma parte del contrato.

**Arreglo (hecho, `c9045630`).**
- No sube el tope: cambia lo que se mide. Se espera `ComprobacionCadenaSegundos` + 100 ms (el `Task.Delay` nunca espera menos) y la **primera** lectura debe dar null.
- Una caché con un intervalo mayor al segundo falla.
- Si la lectura no pudo comprobar (aviso Warning «no se pudo comprobar la cadena guardada», comportamiento de DL22-S16), se repite el segundo, como máximo 3 rondas.
- Mutación verificada: quitar `AND Inhabilitado = 0` de `ComprobarAsync` hace fallar la prueba («Pasados 1.1 s de la inhabilitación la API seguía dando la cadena de la empresa»). Se revirtió.
- La otra mitad del contrato (sin sesiones tras vaciar el grupo, y al habilitar vuelve) queda igual.

**Corridas literales.**
- `--filter "FullyQualifiedName~Rg14Lote2Tests.DL22_S18"`, antes del arreglo, 3 vueltas con la instrumentación: `Correctas! … Superado: 1, Duración: 2 s` (×3).
- Después, 3 vueltas: `Correctas! - Con error: 0, Superado: 1, Omitido: 0, Total: 1, Duración: 2 s` (×3).
- Con la mutación: `Con error! - Con error: 1, Superado: 0, Total: 1`.
- Clase completa, `--filter "FullyQualifiedName~Rg14Lote2Tests"`, 2 vueltas: `Correctas! - Con error: 0, Superado: 14, Omitido: 0, Total: 14, Duración: 45 s / 44 s`.

---

## Para B
- Nada de producción. Los tres commits son solo pruebas y se pueden unir como un PR contra `feature/modelo-ng` (no abrí el PR; sin push).
- Si el PR se abre, la validación bajo carga solo la puede hacer B en su suite. Si alguna vuelve a fallar, pido el mensaje literal para afinar la causa.
- Nota para B, solo informativa: `DL22_S18` es `[FactModoMixto]`. En una instancia en modo solo-Windows se omite y no se prueba.
