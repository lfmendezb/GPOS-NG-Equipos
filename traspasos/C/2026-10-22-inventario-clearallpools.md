```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (inventario de `SqlConnection.ClearAllPools()` en las pruebas; insumo de la decisión sobre el #153)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (ref local tras `git fetch`)
Estado: Abierto
```

# Inventario de `ClearAllPools()` en las pruebas

**Solo lectura; nada compilado ni ejecutado.** Lo hizo un agente de lectura; yo verifiqué los totales con `git grep` y corrijo una cifra mía anterior.

## Corrección de cifras
En el #153 y en mis avisos dije «38 llamadas en 15 archivos». **El número correcto es 43 llamadas en 19 archivos:** 39 en 15 archivos de `tests/GPOS.Tests` y 4 en `tests/GPOS.Reportes.Tests`. Un `git grep -c 'ClearAllPools()'` da 45 en 20 archivos porque cuenta dos **comentarios** de `tests/GPOS.Tests/BasesTemporales.cs` (líneas 6 y 22); su `ClearPool(propia)` de la línea 23 es el patrón correcto. Ningún resultado en `GPOS.Web.Tests`, `GPOS.UI.MAUI.Tests` ni en `src/`.

## Resumen
- **30 de las 43 son redundantes:** van justo antes de `BasesTemporales.EliminarAsync`, que ya vacía el pool de su base. **26 se pueden quitar sin más**; 4 de ellas (DL22, filas 19–22) hay que leerlas antes de quitar.
- **Patrón B, login/usuario (5)** — filas 11, 12, 13, 14, 28: antes de `DROP LOGIN`/`DROP USER`; necesitan soltar las sesiones del login con `ClearPool` de la cadena concreta.
- **Patrón C, Reportes (4)** — filas 1–4: el DROP va por `master` y la cadena de la fixture ya es `Pooling=false`; es higiene.
- **Patrón D (1)** — fila 29: copia inline de la lógica de `BasesTemporales`.
- **Patrón E (1)** — fila 24: rotación bajo carga (`Rg14Lote2Tests.cs:1313`).
- **Patrón F, Sellos (2)** — filas 42–43: `RestaurarAsync`; el `ROLLBACK IMMEDIATE` deja conexiones pooled muertas, así que aquí hay un motivo real.
- **Ninguna de las 19 clases tiene `[Collection]` ni `DisableParallelization`** y no hay `xunit.runner.json`: corren en paralelo con la colección «bd» (27 clases).
- **Una colección no paralela solo para estas clases NO arregla nada:** serializa a las 19 entre sí, pero las víctimas están en «bd» y siguen corriendo en paralelo. Recomiendo no tomar esa opción.

## Corrección de la premisa de mi diagnóstico
`H11S01` (`BaseNoDisponibleApiTests.cs:188`) y `CP103` (`NumeracionMotorTests.cs:157`) **no llaman** a `ClearAllPools`: usan su pool propio (`CadenaPoolUno`, `MaxPoolSize=1`, `WorkstationID`/`ApplicationName` únicos) y lo vacían con `ClearPool(cadena)` (`BaseNoDisponibleApiTests.cs:156`, `NumeracionMotorTests.cs:212`). **Son víctimas, no causas** (coincide con lo que dije en el #153).

## Orden recomendado y esfuerzo (inferido)
1. Quitar las 26 redundantes sin revisión (filas 5–10, 15–18, 23, 25–27, 30–41): mecánico, ~1–2 h con revisión.
2. Reportes (1–4) y la copia inline (29): quitar o usar `BasesTemporales`; en Reportes comprobar que el proyecto de pruebas puede referenciar `BasesTemporales` (no lo comprobé).
3. Leer DL22 (19–22) y rotación (24) y decidir.
4. Login/usuario (11–14, 28) y Sellos (42–43): `ClearPool` de la cadena concreta, probando en el entorno.
5. No usar la colección no paralela (ver arriba).

Esfuerzo total: bajo para el 1 y el 2, medio para el 4; en total dentro de los 0,5 a 1 día-persona que ya estimé, más una suite completa que debe correr B.

## Riesgos de cambiar
- `ClearPool(cadena)` solo vacía el pool de esa cadena **exacta**. Si la app abre con otra (`ApplicationName`/`WorkstationID` distintos, como `CadenaConexion.ParaTrabajo`/`SinBloqueoDelPool`), ese pool sobrevive y el arreglo queda incompleto (I).
- Quitar la llamada global sin reemplazo deja conexiones pooled a bases eliminadas o restauradas: fallos en pruebas posteriores (Sellos, login).
- `DROP LOGIN`/`USER` con sesiones pooled puede fallar: hay que comprobarlo caso por caso.
- Las pruebas DL22 pueden medir el vaciado de grupos; quitar su llamada sin leerlas puede romperlas.
- Son 43 sitios sin compilar; la regresión debe cubrirse con ejecución en LFMB.

## Tabla (V = visto en el código de la rama; I = inferido)

**Reportes.Tests (4)** — todas: `DisposeAsync` de una `IClassFixture` sin `[Collection]` (paralela); higiene, porque su cadena ya es `Pooling=false`; alternativa: quitar.
| # | archivo:línea | clase | V/I |
|---|---|---|---|
| 1 | `tests/GPOS.Reportes.Tests/ConsultasRegistradasMotorTests.cs:57` | `VistasContratoFixture` (cadena `Pooling=false` en :21) | V |
| 2 | `tests/GPOS.Reportes.Tests/EjecutorConsultasSqlTests.cs:58` | `BaseReportesFixture` (:22) | V |
| 3 | `tests/GPOS.Reportes.Tests/EjecutorDisenadorSqlTests.cs:81` | `BaseDisenadorFixture` (:38) | V |
| 4 | `tests/GPOS.Reportes.Tests/LectorRegistradasSqlTests.cs:68` | `BaseLecturaFixture` (:30) | V |

**GPOS.Tests (39)**
| # | archivo:línea | clase / método | Contexto | ¿Propósito o higiene? | Alternativa | V/I |
|---|---|---|---|---|---|---|
| 5–9 | `ModeloNg/Dl02CuentasArranqueTests.cs:76, 97, 123, 162, 294` | `Dl02CuentasArranqueTests` (5 métodos) | `finally`: `ClearAllPools`, luego `BasesTemporales.EliminarAsync` | Higiene, redundante | Quitar | V |
| 10 | `ModeloNg/RespaldoPosteriorForkTests.cs:44` | helper `Borrar` (:42) | `ClearAllPools` y luego `EliminarAsync` | Higiene, redundante | Quitar | V |
| 11, 12 | `ModeloNg/Rg14CandadoSistemaEstrictoTests.cs:98, 149` | `HV401_*` | `finally`: `ClearAllPools`, `EliminarAsync`, `LoginsPruebaRg14.BorrarAsync(login)` | Parcial: el `DROP LOGIN` posterior puede chocar con sesiones pooled del login | `ClearPool(cadena del login)` antes del DROP | V (uso), I (motivo) |
| 13 | `ModeloNg/Rg14LoginsServicioTests.cs:396` | `Rg14VerificarPoliticaLoginsTests.R2_CONTENIDO_DUPLICA_LOGIN_*` | igual que 11 | Parcial | `ClearPool(cadena del login)` | V (uso), I (motivo) |
| 14 | `ModeloNg/Rg14Lote2Tests.cs:93` | `LoginsPruebaRg14.BorrarAsync(login)` (helper estático usado en :100 y :151 de Rg14CandadoSistemaEstrictoTests) | `ClearAllPools` y luego `DROP LOGIN` (cadena Maestra ya `Pooling=false`, :61) | Parcial, mismo motivo | `ClearPool(cadena del login)` | V (uso), I (motivo) |
| 15–18 | `ModeloNg/Rg14Lote2Tests.cs:196, 216, 255, 365` | `Rg14Lote2Tests` | `finally`: `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 19, 20 | `ModeloNg/Rg14Lote2Tests.cs:491, 552` | `DL22_bmas_*` («vacía el grupo de la anterior», «deja de abrir conexiones en 1 s») | `finally`: `ClearAllPools`, `EliminarAsync(sistema)` | Probablemente higiene, pero el nombre trata del vaciado de grupos: **leer el cuerpo antes** | Quitar tras revisar; si se mantiene, `ClearPool(cadena anterior)` | V (uso), I (motivo) |
| 21, 22 | `ModeloNg/Rg14Lote2Tests.cs:597, 655` | `DL22_bmas_*` (cache/GPOS_SYSDATA caída) | antes, `ALTER DATABASE` (líneas 596 y 654); después `ClearAllPools`, `EliminarAsync(sistema)` | Revisar | `ClearPool(cadena de sistema)` | V (uso), I (motivo) |
| 23 | `ModeloNg/Rg14Lote2Tests.cs:1035` | `Rg14AprovisionarRealTests.ProbarAsync` | `finally`: `ClearAllPools`, `EliminarAsync(empresa)` | Higiene, redundante | Quitar | V |
| 24 | `ModeloNg/Rg14Lote2Tests.cs:1313` | probablemente `Rg14RotacionApiTests.DosRotacionesBajoCargaAsync` (confirmar) | `finally`: `RestaurarAsync()`, `ClearAllPools`, `RotacionPrueba.BorrarUsuariosAppAsync` | Probablemente a propósito: los pools de la API con el usuario anterior de la rotación | `ClearPool(api.ConexionEmpresa)` y de la cadena del sistema | V (uso), I (motivo) |
| 25–27 | `ModeloNg/Rg14Lote2bTests.cs:88, 129, 196` | `Rg14Lote2bTests` | `finally`: `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 28 | `ModeloNg/Rg14PrivilegioMinimoTests.cs:476` | `Rg14SistemaTests.PA47_*` | `finally`: `ClearAllPools`, luego `DROP USER` | Dudoso: `DROP USER` no tiene por qué fallar por sesiones; posible higiene | `ClearPool(cadena del usuario)` o quitar | I |
| 29 | `Mvp/CredencialesLecturaRevocacionTests.cs:83` | `Revocar_sin_VIEW_SERVER_STATE_*` | `finally`: `ClearAllPools` y `DROP DATABASE` inline (copia de `BasesTemporales`) | Higiene; duplica `BasesTemporales` | `BasesTemporales.EliminarAsync(cadena)` | V |
| 30 | `SegundoFactor/BitacoraSeguridadTests.cs:33` | `SistemaSegundoFactorFixture.DisposeAsync` | `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 31–33 | `SegundoFactor/EsquemaRecuperacionFactorTests.cs:131, 195, 271` | `PF_J2_14_*` | `finally`: `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 34–37 | `SegundoFactor/EsquemaSegundoFactorTests.cs:165, 222, 335, 357` | `PF30_*`, `PF43_*`, `Los_permisos_sin_S1_*` | igual | Higiene, redundante | Quitar | V |
| 38 | `SegundoFactor/RecuperacionFactorServicioTests.cs:50` | `SistemaRecuperacionFixture.DisposeAsync` | `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 39 | `Usuarios/Sellos/EntornoSellos.cs:123` | `EntornoSellos.DisposeAsync` (tras cada prueba de sellos) | `ClearAllPools`, `EliminarAsync(Cadena)` | Higiene, redundante | Quitar | V |
| 40, 41 | `Usuarios/Sellos/SellosPadronTests.cs:701, 741` | `Sistema_sella_*`, `La_API_solo_sella_al_arrancar_en_Debug` | `finally`: `ClearAllPools`, `EliminarAsync` | Higiene, redundante | Quitar | V |
| 42 | `Usuarios/Sellos/SellosRestauracionTests.cs:47` | helper `RestaurarAsync(e, archivo)` | antes del `RESTORE`: `ClearAllPools`, `ALTER ... SINGLE_USER WITH ROLLBACK IMMEDIATE`, `RESTORE WITH REPLACE`, `MULTI_USER` | A propósito en parte: `ROLLBACK IMMEDIATE` deja conexiones pooled muertas | `ClearPool(new SqlConnection(e.Cadena))` | V (uso), I (motivo) |
| 43 | `Usuarios/Sellos/SellosRestauracionTests.cs:53` | helper `RestaurarAsync` | tras el `RESTORE`: `ClearAllPools`, luego `e.Padron.Olvidar()` y `ComprobarAsync` | Probablemente a propósito: la app vuelve a abrir la base restaurada | `ClearPool(e.Cadena)` | I |

Todas las clases de GPOS.Tests de la tabla corren en paralelo (sin `[Collection]`; las `IClassFixture` no serializan).

## Qué no verifiqué
- Solo lectura; no se compiló ni ejecutó nada. La única operación con efecto fue `git fetch origin feature/modelo-ng`.
- Búsquedas: `ClearAllPools`, `ClearPool(`, `Pooling=false`, `Microsoft.Data.SqlClient` en `tests`, y wrappers (`LoginsPruebaRg14.BorrarAsync`, `RestaurarAsync` de Sellos, `Conexiones.Borrar`, `DisposeAsync` de fixtures). Sin llamadas a `EnsureDeletedAsync` en las pruebas.
- No se leyó el cuerpo de DL22 (filas 19–22, líneas 596 y 654 cortadas) ni el de la prueba de rotación (fila 24); sus motivos son hipótesis.
- No se comprobó si `GPOS.Reportes.Tests` puede referenciar `BasesTemporales` ni el paralelismo de toda la solución (solo las 19 clases afectadas).
- No hay logs ni resultados de CI: no sé qué pruebas fallan de verdad ni con qué frecuencia.
