# Informe QA: T-r de la fase A de ADR-81 (equipo C)

**Fecha:** 2026-10-16 · **Rama:** `c/adr81-fase-a` @ `bdcf7804` (más el commit de QA `06b913c8`, sin push) · **Árbol:** `GPOS-C-adr81-fase-a` · **Instancia:** `.\SQLEXPRESS` · **Máquina:** con este agente como único proceso de pruebas.

**Qué manda:** blueprint v4 (`docs/arquitectura/2026-10-16-adr81-fase-a-blueprint-v4.md`): fila T-r (línea 508), criterio de salida (línea 511) y §13. Blueprint v3 (`2026-10-10-adr81-fase-a-blueprint.md`): §6.6 (recorridos S1 a S13) y §12 (PF-01 a PF-42). Blueprint v4.1: PF-J2-xx.

---

## 1. Alcance probado

- La suite oficial completa de `GPOS.Tests` (filtro `Transicion!=Ola5&Transicion!=Defecto`), `GPOS.Web.Tests` y `GPOS.UI.MAUI.Tests`.
- PF-18 con y sin el PR #49 (`origin/a/autorizacion-otra-persona`, `c565146e`).
- PF-24: búsqueda de secretos en el diff `ce33b2a8..bdcf7804` y en los registros que generan las pruebas del factor.
- PF-40 y los recorridos de salida del candado (PF-33).
- El criterio de salida de la fase A, prueba por prueba.
- PA-14 y PF-12, medidas con la máquina sola.

**Pruebas nuevas.** Solo código de pruebas, en el commit `06b913c8`, sin push:

- `tests/GPOS.Tests/SegundoFactor/SalidaFaseATests.cs` (nuevo), con 9 pruebas:
  - PF-18: SF-01 y SF-02 por HTTP;
  - PF-24;
  - PF-40;
  - los recorridos S4 y S8, S5, S7 y S10.
- `tests/GPOS.Tests/ModeloNg/QaOla4HttpTests.cs`: la lista de rutas anónimas ahora incluye 5.2, 5.3 y J2-1 a J2-3 (ver D-01).

## 2. Trazabilidad: criterio de aceptación → pruebas

| Criterio (T-r y §13) | Pruebas | Estado previo |
|---|---|---|
| PF-18: regresión HTTP de SF-01 y SF-02, con o sin el #49 | `RegresionSf01Sf02HttpTests.PF18_SF01_…` y `PF18_SF02_…` (nuevas) | Solo existían a nivel de servicio (`AutorizacionSupervisorTests`) |
| PF-24: búsqueda de secretos | `BusquedaSecretosFactorTests.PF24_…` (nueva) y la búsqueda manual del diff (§3.3) | Parcial (PF-J2-12 cubría el JWS y `otpauth` en la vía a′) |
| PF-40: restauración sin detener la API | `SalidaPf40Tests.PF40_…` (nueva) | No había prueba con la base del sistema |
| Recorridos de salida completos (PF-33: S1, S3, S4, S5, S7, S10) | S1 y S3: `RestauracionFactorTests.PF31_PF33_PF35_…` (existente). S4 y S8, S5, S7, S10: `SalidaS4S8Tests`, `SalidaS5Tests`, `SalidaS7Tests` y `SalidaS10Tests` (nuevas) | Solo S1 y S3 |
| PA-14 medido; PF-12 | `LecturaSesionMedicionTests.PA14_…` y `SegundoFactorServicioTests.PF12_…` (rasgo `Medicion`) | Existentes, omitidas por omisión |
| El resto del criterio de salida | Ver §5 | Existentes |

Los recorridos S2, S6, S9, S11, S12 y S13 no tienen prueba propia:

- S2 es S1 o S5.
- S6 pasa por la consola (V4-14).
- S9 lo cubre PF-29.
- S11 es la Web (T-p).
- S12 es anterior a la fase A.
- S13 lo cubren PF-19 y PF-41.

## 3. Resultados

### 3.1 Suites completas

| Suite | Total | Correctas | Fallidas | Omitidas | Duración |
|---|---|---|---|---|---|
| `GPOS.Tests`, rama tal cual (`bdcf7804`), corrida 1 | 3434 | 3408 | 6 | 20 | 12 min |
| `GPOS.Tests` con el commit de QA (`06b913c8`), corrida 2 | 3442 | 3419 | 3 | 20 | 12 min 26 s |
| `GPOS.Web.Tests` | 786 | 786 | 0 | 0 | 9 s |
| `GPOS.UI.MAUI.Tests` | 611 | 611 | 0 | 0 | 0,7 s |

Las 20 omitidas son las mediciones y cargas con `Skip`, más las condicionadas por la instancia; son las mismas en las dos corridas.

### 3.2 Fallas, una por una (cada una repetida sola)

| Corrida | Prueba | Repetida sola | Causa | Clasificación |
|---|---|---|---|---|
| 1 | `QaOla4HttpTests.Ninguna_ruta_de_la_api_queda_sin_autorizacion_fuera_de_las_publicas` | Falla siempre. En `ce33b2a8` (árbol temporal) **pasa** | La rama agregó 5 rutas anónimas por diseño (5.2, 5.3, J2-1 a J2-3) sin actualizar la lista de la prueba de arquitectura | **Regresión de la rama (D-01)**, corregida en el commit de QA; en la corrida 2 pasa |
| 1 | `BusquedaNumeroHttpTests.CP126_…` | Pasa | `SqlException` «No hay ningún proceso en el otro extremo de la canalización» al arrancar el anfitrión (`AnilloLicenciaInstalacion.cs:42`) | Intermitente por carga (D-03) |
| 1 | `PersistenciaLicenciaTests.Anteriores_va_en_orden_…` | Pasa | Grupo de conexiones agotado | Intermitente por carga |
| 1 | `NumeracionQaB2Tests.Rafaga_de_anulaciones_…` | Pasa | Grupo de conexiones agotado | Intermitente por carga |
| 1 | `HuecosOla4HttpTests.La_clase_de_agente_…` | Pasa | Igual que CP126 (D-03) | Intermitente por carga |
| 1 | `NumeracionMotorTests.CP103_…` | Pasa | Espera de bloqueo bajo carga | Intermitente por carga |
| 2 | `Rg14RotacionApiTests.PA30_…` | Pasa | 500 durante la rotación bajo carga | Intermitente por carga |
| 2 | `RestablecimientoFactorHttpTests.PF23_…` | Pasa | Igual que CP126 (D-03) | Intermitente por carga |
| 2 | `Rg14VerificarTests.PA28_…` | **Falla siempre** desde la corrida 2; en la corrida 1 pasó. En `ce33b2a8` (árbol temporal) **falla igual** | `ALTER DATABASE … SET CONTAINMENT = PARTIAL WITH ROLLBACK IMMEDIATE` → «lock could not be placed». La misma orden sobre una base vacía funciona a mano | **Preexistente**, depende del estado de la instancia; ajena a la rama (D-04) |

Otra falla apareció en la corrida dirigida del criterio: `PF31_PF33_PF35`, con la misma causa que CP126 (D-03). Repetida sola pasó dos veces, y en la corrida siguiente del conjunto, también.

Las 9 pruebas nuevas pasaron en todas las corridas: dos corridas dirigidas seguidas, la corrida 2 de la suite y el conjunto del criterio.

### 3.3 PF-18 con y sin el #49

| Variante | Conjunto | Resultado |
|---|---|---|
| Sin el #49 (rama tal cual) | PF-18 (2) + `AutorizacionSupervisorTests` + `ReimpresionTests` + `PermisosTests` + `FlujosMvpTests` + `FiltroFactorTests` + `InventarioCandadoTests` | **49/49** |
| Con el #49 (árbol temporal: `c565146e` unido sobre `bdcf7804`) | El mismo conjunto, más las 4 pruebas del #49 | **53/53** |

- **La unión es limpia**, sin conflictos; git resolvió solo `tests/GPOS.Tests/Mvp/FlujosMvpTests.cs`. Compila con 0 errores.
- **Sin el #49:** otro SUPER (con la contraseña correcta o con la incorrecta) y el propio SUPER de la sesión reciben `200 false`, la misma respuesta que una cuenta inexistente, y `IntentosFallidos` queda en 0. Un supervisor con el privilegio autoriza (`200 true`); con la contraseña incorrecta, el intento cuenta (1).
- **Con el #49:** el SUPER de la sesión recibe **422 `AUTORIZACION_INVALIDA`** sin contar el intento, y otro SUPER sigue recibiendo la respuesta de una credencial incorrecta, también sin contar el intento.
- La prueba elige la rama según exista `AutorizacionesSupervisor.CausaMismoUsuario`, así que sigue valiendo después de unir el #49.
- **SF-02:** las medianas de la cuenta inexistente y de la SUPER no bajan de un tercio de la de una cuenta real.
- El árbol temporal se borró.

### 3.4 PF-24: búsqueda de secretos (cero apariciones)

**Diff `ce33b2a8..bdcf7804`.** Son 182 archivos y +24 087 líneas, revisadas con `git diff` y expresiones regulares:

| Patrón | Apariciones | Revisión |
|---|---|---|
| URI `otpauth://` y `secret=<base32>` | Solo datos sintéticos de prueba y documentación | El vector del RFC 6238 (`GEZDGNBV…`, «12345678901234567890») y el ejemplo público `JBSWY3DPEHPK3PXP`, en `FundamentosTotpTests.cs`, `SegundoFactorServicioTests.cs`, `GPOS.Web.Tests/{InicioSesionFactorWebTests,RecuperacionFactorTests,SegundoFactorSuperPantallasTests,VistaSegundoFactorTests}.cs` y `GPOS.UI.MAUI.Tests/SegundoFactorMauiTests.cs`. En los documentos de `docs/arquitectura`, `docs/decisiones` y `docs/ux` solo aparece el texto «`otpauth://`». En `src/GPOS.Core/Sistema/SegundoFactor/UriOtpAuth.cs` está la plantilla que construye el URI, sin ningún valor |
| JWS completo (`eyJ….eyJ….firma`) | 1 | `tests/GPOS.Web.Tests/RecuperacionFactorTests.cs:36-37`: JWS sintético con la firma literal `FIRMA-SECRETA-DE-GSF_…` (no verifica con ninguna llave) |
| Códigos de respaldo literales (`XXXXX-XXXXX`) | 0 | — |
| `Password=` o `Pwd=` y contraseñas literales en `src`, `database`, `instalador` y `GPOS.UI.MAUI` | 0 | Solo constantes de códigos y textos de error |
| Llamadas a `Log*` nuevas con secreto, código, JWS o URI | 0 | Las 14 llamadas nuevas registran el usuario, el intento y el máximo, nunca el valor |

**Registros que generan las pruebas.** Prueba nueva `PF24_ningun_secreto_en_registros_errores_ni_bitacora`:

- Recorre estas operaciones:
  - alta, código erróneo y alta correcta;
  - 409 con un código de respaldo;
  - reautenticación errónea y correcta;
  - regeneración de los códigos;
  - cambio de teléfono, con contraseña errónea, código erróneo y confirmación;
  - `/clave`, errónea y correcta;
  - vía a′ con el JWS, con contraseña errónea y correcta;
  - vía a.
- Captura el registro completo de la API en nivel Trace, con una regla por proveedor: **4742 líneas**. Con solo `SetMinimumLevel`, la configuración dejaba pasar 16.
- Busca 60 valores:
  - las dos claves manuales y los dos URI;
  - los 30 códigos de respaldo, con y sin guion;
  - los JWT emitidos, el desafío y el comprobante del 409;
  - el JWS y su firma;
  - las 4 contraseñas;
  - el texto `otpauth`.
- Los busca en:
  - el registro;
  - los cuerpos de las respuestas de error (`ProblemDetails`);
  - toda la tabla `BitacoraSeguridad` (`FOR JSON`);
  - `Usuarios`, `UsuariosCodigosRespaldo` y `UsuariosFactor`.
- **Resultado: cero apariciones.**

Los cuerpos que llevan secretos por contrato no entran en la búsqueda:

- el 202 con el desafío;
- el alta;
- el 200 o el 409 con los códigos;
- `/codigos-respaldo`;
- el cambio de teléfono;
- J2-1.

**Rutas revisadas:** el diff completo y además `src/GPOS.Web/Program.cs`, `src/GPOS.Web/appsettings.json` y `src/GPOS.Api/appsettings.json`. Ni la API ni la Web usan `HttpLogging`, y el `HttpClient` de la Web registra solo desde `Warning`. La API solo escribe al Visor de eventos; las pruebas limpian los proveedores, y la captura en memoria recibe los mismos mensajes.

### 3.5 PF-40 y recorridos de salida

| Prueba | Qué comprueba | Resultado |
|---|---|---|
| PF-40 | `RESTORE` de `GPOS_SYSDATA` con la API arriba y **sin volver a arrancarla** (solo la vigilancia de 15 s): la entrada de un USER recibe 503 `SISTEMA_RESTAURADO`; el token anterior da 401; el SUPER con el factor entra y su `POST /api/admin/usuarios` recibe 503; una vuelta más y un arranque no repiten la reconciliación (un solo `SISTEMA_RESTAURADO`); libera | Pasa. El candado rigió a los **6,4 s, 6,8 s y 8,0 s** del `RESTORE` (tres corridas). La prueba exige ≤ 20 s (ver R-3) |
| S8 y S4 | Factor de A bloqueado en el respaldo → 423 → B entra y lo desbloquea (5.10) con el candado → A entra con el TOTP. Después B restablece el factor de A (5.9) → A hace una nueva alta y libera | Pasa |
| S5 | Vía (b) (`RestablecimientoFactor`, con el anillo de la API) con el candado → `login` 202 `Alta` con la contraseña temporal → 5.2 → 5.3 → `/clave` con `auth_time` de 6 min y «Debe cambiar», sin reautenticación (UX-81A-08) → token completo → la liberación pide 401 `REAUTENTICAR` → `/reautenticar` → libera; queda `FACTOR_RESTABLECIDO_CONSOLA` | Pasa |
| S7 | Secreto cifrado con otro anillo → el TOTP da 401 `SEGUNDO_FACTOR_INVALIDO` y `FACTOR_SECRETO_ILEGIBLE`, sin contar como fallo → entra con un código de respaldo revivido → cambio de teléfono → libera | Pasa |
| S10 | La sesión del SUPER muere con `inactiva` (31 min) durante la revisión → otro arranque y otra vuelta → sigue habiendo un solo `SISTEMA_RESTAURADO` y el candado → vuelve a entrar y libera | Pasa |

Nota de construcción de la prueba (S5): un token re-firmado con `iat` de hace 7 min (`FactorHttp.ConAuthTime`) recibe 401 `revocada` después de la restauración. Es **correcto**: el token se emitió antes del candado. La prueba usa un ayudante que conserva el `iat` y solo mueve `auth_time`.

## 4. Cobertura

- **Política aplicada:** la que el contrato fija por omisión, 70 % de líneas del código modificado en los módulos críticos (aquí, seguridad). El `CLAUDE.md` del proyecto no define otra.
- **Medición:** `coverlet.collector` (XPlat), con las 244 pruebas de `GPOS.Tests.SegundoFactor`, `ClaseLicenciaFactorTests`, `InventarioCandadoTests` y `CandadoSistemaApiTests` (242 correctas y 2 omitidas, las de medición). Se midió sobre los 71 archivos `.cs` de `src` tocados por el diff.
  - **Resultado: 77,1 % de líneas** (3636/4713) por archivo completo. Es una estimación conservadora: no se midieron solo las líneas cambiadas ni se corrió la suite entera.
  - **Núcleo del factor, entre 92 % y 100 %:**
    - `SegundoFactorService.cs`: 98,2 %;
    - `SegundoFactorService.Recuperacion.cs`: 93,2 %;
    - `RecuperacionFactorService.cs`: 92,2 %;
    - `Totp`, `Base32`, `CodigosRespaldo`, `DesafiosFactor`, `DesafiosRecuperacion` y `AutenticacionReciente`: 100 %;
    - `RevocacionSesiones.cs`: 97,8 %;
    - `AuthEndpoints.SegundoFactor.cs`: 91,8 %;
    - `RestablecimientoFactor.cs`: 92,0 %.
  - **Por debajo del 70 %** (fuera del núcleo del factor, o cubiertos por otras clases):
    - `GPOS.Migracion/Program.cs`: 0 % (punto de entrada de la consola; las pruebas llaman a `RestablecimientoFactor` directamente);
    - `ValidadorTokenPrincipal.cs`: 20,5 %;
    - `LicenciaEndpoints.cs`: 25,5 %;
    - `ImpresionEndpoints.cs`: 31,2 %;
    - `Core/Infraestructura/Sesion.cs`: 42,9 %;
    - `VerificadorJws.cs`: 49,7 %.
  - Los archivos de `GPOS.Web` se cubren con `GPOS.Web.Tests`, que no entró en esta medición. Los de `Consultas/…/SegundoFactor` son constantes SQL, sin líneas ejecutables.
- **Comparación con la política: cumple** (77,1 % ≥ 70 %).

## 5. Criterio de salida de la fase A (blueprint v4, línea 511)

Corrida dirigida con TRX: 33/33 correctas, más `V4_15_ExigirSuper_es_obligatorio_en_Release` (1/1).

| Criterio | Prueba (ruta) | Resultado |
|---|---|---|
| PF-17 (SF-03) | `tests/GPOS.Tests/SegundoFactor/InicioSesionFactorTests.cs:170` `PF17_el_409_solo_sale_despues_del_factor` | Verde |
| PF-18 (SF-01, SF-02) | `SalidaFaseATests.cs`: `PF18_SF01_…`, `PF18_SF02_…`, con y sin el #49 | Verde |
| PF-19 | `FiltroFactorTests.cs:119` `PF19_ADMIN_ascendido_a_SUPER` (el token SUPER sin `otp` está en `PF41_…`) | Verde |
| PF-24 | `SalidaFaseATests.cs` `PF24_…` y la búsqueda del diff (§3.4) | Verde: **cero apariciones** |
| PF-31 | `RestauracionFactorTests.cs:56` `PF31_PF33_PF35_restauracion_real_con_el_factor` | Verde (una vez intermitente por D-03; solo, verde dos veces) |
| PF-33 | La misma prueba (S1 y S3) y `SalidaS4S8Tests`, `SalidaS5Tests`, `SalidaS7Tests` y `SalidaS10Tests` | Verde |
| PF-35 | `RestauracionFactorTests.cs:56` | Verde |
| PF-41 | `FiltroFactorTests.cs:63` `PF41_el_401_factor_no_cierra_la_sesion_y_reautenticar_la_confirma`; `FiltroFactorTests.cs` `V4_15_ExigirSuper_es_obligatorio_en_Release` | Verde |
| PF-42 | `FiltroFactorTests.cs:149` `PF42_la_lista_sin_factor_es_cerrada` | Verde |
| PF-43 | `EsquemaSegundoFactorTests.cs:234` `PF43_Estricto_…` | Verde |
| PF-44 | `Licencia/ClaseLicenciaFactorTests.cs:123` y `Licencia/ClasificacionRutasLicenciaTests.cs:163` (10 casos) | Verde |
| PF-45 | `SegundoFactorServicioTests.cs:320` y `RestablecimientoFactorConsolaTests.cs:168` | Verde |
| PF-46 | `BitacoraSeguridadTests.cs:52` y `:70` | Verde |
| CA-CR-02 de A con las rutas de C | `ModeloNg/RestauracionSistemaApiTests.cs:118` `CA_CR_02_base_del_sistema_restaurada` | Verde |
| CA-INV-01 de A con las rutas de C | `ModeloNg/InventarioCandadoTests.cs` `CA_INV_01_…` y las dos de GET; la lista aprobada (líneas 26-51) incluye `login/alta`, `login/factor`, `reautenticar`, `factor/*`, `super/usuarios/{codigo}/factor/*`, `login/recuperacion*` y `super/sistema/restauracion/liberar` | Verde |
| Revisión del auditor-seguridad sin hallazgos Críticos ni Altos | — | **Pendiente: fuera del alcance de QA** |

## 6. Medición (con la máquina sola)

**Condiciones:**
- Sin procesos `dotnet`, `testhost`, `MSBuild`, `vstest` ni `VBCSCompiler` (servidor de compilación detenido con `dotnet build-server shutdown`).
- En SQL Server, la única otra sesión era la telemetría `SQLServerCEIP`, inactiva.
- `Skip` quitado de forma temporal, con los percentiles escritos en un archivo temporal. El proyecto no tiene un interruptor para estas mediciones. El cambio se revirtió (`git checkout`) y no está en el commit.

**PA-14** (`EstadoSesionAsync`; 500 muestras después de 20 de calentamiento; meta p95 ≤ 2 ms), en ms:

| Corrida | Debug p50 | Debug p95 | Debug p99 | Debug máx. | Release p50 | Release p95 | Release p99 | Release máx. |
|---|---|---|---|---|---|---|---|---|
| 1 | 1,041 | 1,961 | 2,414 | 5,417 | 1,276 | **2,107** | 2,916 | 8,123 |
| 2 | 1,060 | 1,830 | 2,891 | 11,291 | 1,223 | 1,951 | 2,726 | 16,523 |
| 3 | 1,140 | 1,966 | 2,708 | 8,412 | 1,299 | 1,909 | 2,368 | 6,530 |
| 4 | 1,295 | **2,089** | 2,602 | 6,632 | 1,250 | **2,156** | 3,002 | 11,346 |
| 5 | 1,260 | 1,943 | 2,618 | 9,709 | 1,259 | **2,025** | 2,492 | 10,869 |

**PF-12** (verificación de los 10 códigos de respaldo; la prueba exige un máximo < 2000 ms), en ms:

| Corrida | p50 | p95 | p99 | Máx. |
|---|---|---|---|---|
| 1 | 562,5 | 1154,1 | 1154,1 | 1154,1 |
| 2 | 564,4 | 1148,6 | 1148,6 | 1148,6 |
| 3 | 558,2 | 1158,4 | 1158,4 | 1158,4 |
| 4 | 561,5 | 1156,5 | 1156,5 | 1156,5 |
| 5 | 555,6 | 1152,7 | 1152,7 | 1152,7 |

En Release los valores son iguales a ±1 %: p50 de 552,6 a 560,1 y máximo de 1153,5 a 1171,4. Con 10 muestras, p95 = p99 = máximo.

**Lectura:**
- PA-14 cumple en 6 de 10 corridas. El p95 va de 1,830 a 2,156 ms; la mediana de los diez p95 es 1,98 ms. Cuando se pasa, lo hace como mucho por **0,156 ms (7,8 %)**.
- PF-12 cumple su límite con margen (máximo 1,17 s frente a 2 s). En cada corrida, una verificación tarda unas dos veces la mediana (≈ 1,15 s frente a ≈ 0,56 s).

## 7. Defectos

| # | Severidad | Defecto | Reproducción | Esperado | Obtenido | Responsable |
|---|---|---|---|---|---|---|
| D-01 | Media (**resuelta en el commit de QA**) | La prueba de arquitectura de rutas anónimas no conocía las 5 rutas anónimas de la fase A | En `bdcf7804`: `dotnet test tests/GPOS.Tests --filter "FullyQualifiedName=GPOS.Tests.ModeloNg.QaOla4HttpTests.Ninguna_ruta_de_la_api_queda_sin_autorizacion_fuera_de_las_publicas"` | Verde; en `ce33b2a8` pasa | Falla: lista distinta desde la posición 4 (`POST /api/auth/login/alta`, `…/factor`, `…/recuperacion/`, `…/recuperacion/alta`, `…/recuperacion/confirmar`) | QA actualizó la lista citando 5.2, 5.3 y J2-1 a J2-3. **El auditor-seguridad debe confirmar** que las cinco son anónimas por diseño |
| D-02 | Media | PA-14 (p95 ≤ 2 ms) no se cumple de forma estable | Quitar el `Skip` de `LecturaSesionMedicionTests.PA14_…` (`CicloSesionInactividadTests.cs:285`) y correr 5 veces `--filter "Medicion=PA-14"` con la máquina sola | p95 ≤ 2,000 ms en todas las corridas | p95 > 2 ms en 4 de 10 corridas (máximo 2,156 ms en Release) | Desarrollador de T-e (CS): optimizar la lectura, o decisión del propietario sobre el umbral o una tolerancia. Impacto operativo: ≈ 0,1 ms por petición |
| D-03 | Baja (código de A, en la base) | Primer arranque contra una base del sistema que no existe: `AnilloLicenciaInstalacion.AnilloDeClienteAsync` (`src/GPOS.Core/Infraestructura/Motor/AnilloLicenciaInstalacion.cs:37-55`, commit `5eedc67d`) solo captura el error 4060. Bajo carga, el proveedor de memoria compartida devuelve «No hay ningún proceso en el otro extremo de la canalización», el anfitrión no arranca y la prueba falla | Suite completa en `.\SQLEXPRESS`. Se vio en CP126, `HuecosOla4`, PF-23 y PF-31: 4 de las 9 fallas intermitentes | Tratarlo como «la base no existe» o reintentar una vez | Excepción sin capturar en `Inicializacion.ExigirSinLicenciaDeClienteAsync` (`src/GPOS.Api/Servicios/Inicializacion.cs:199`) | Equipo A. En producción solo afecta al primer arranque (se resuelve al volver a arrancar); en las pruebas es la mayor fuente de intermitencia |
| D-04 | Baja (preexistente; RG-14 de A) | `Rg14VerificarTests.PA28_…`: `ALTER DATABASE … SET CONTAINMENT = PARTIAL WITH ROLLBACK IMMEDIATE` falla con «lock could not be placed» sobre la base recién aprovisionada | `--filter "FullyQualifiedName~Rg14VerificarTests.PA28_un_usuario_contenido_ajeno"` | Verde (lo fue en la corrida 1) | Falla siempre desde la corrida 2, también en `ce33b2a8`. Sobre una base vacía, la misma orden funciona a mano | Equipo A. Ajena a la rama |
| O-1 | Baja (observación) | J2-1 está registrada como `POST /api/auth/login/recuperacion/` (con barra final); el blueprint v4.1 (§5, J2-1) y `InventarioCandadoTests` la nombran sin la barra | `EndpointDataSource` (la salida de D-01) | El mismo patrón que el contrato | Funciona con y sin la barra (las pruebas usan la ruta sin ella) | Desarrollador de T-j2d o documentador |
| O-2 | Observación | La vía (b) muestra la contraseña temporal en la consola (`GPOS.Migracion/Program.cs`, «entréguela por un canal seguro») | — | Por diseño (8.7 y PF-26): va a la pantalla del técnico, no a un registro | — | Ninguno |

No hay defectos Críticos ni Altos.

## 8. Riesgos no cubiertos por pruebas

- **R-1:** la revisión del auditor-seguridad, que forma parte del criterio de salida, no la hace QA y sigue pendiente.
- **R-2:** PF-40 se probó con la base del sistema en una sola instancia de la API; con varias instancias, el tiempo depende de la vigilancia de cada una. Lo multinodo es de la entrega 2.
- **R-3:** el límite de PF-40 en el blueprint es ≤ 15 s, pero la vigilancia tiene un intervalo de 15 s. El peor caso teórico es 15 s más la duración de la vuelta. Por eso la prueba exige ≤ 20 s; la medición real fue de 6,4 a 8,0 s.
- **R-4:** S6 (sin ningún SUPER en la base) y la ruta por consola de V4-14 (`GPOS.Migracion sistema`) solo tienen las pruebas de la consola, no un recorrido con el candado.
- **R-5:** el p95 de PF-12 se calcula con 10 muestras, que no bastan para un percentil estable; solo vale como orden de magnitud.
- **R-6:** la intermitencia de la suite bajo carga (9 fallas distintas en dos corridas, ninguna repetible sola salvo D-01 y D-04) puede ocultar una regresión real en una sola corrida.
- **R-7:** la base `GPOS_TEST_MVP_d12c0a15`, creada el 2026-10-16 a las 15:53 (antes de esta sesión), sigue en la instancia. No se tocó.

## 9. Recomendación

**Aprobado** (recomendación técnica de QA; la decisión es del propietario):

- no hay defectos Críticos ni Altos;
- todo el criterio de salida que corresponde a QA está en verde;
- PF-24 da cero apariciones;
- la cobertura cumple la política.

Condiciones para avanzar:
- la revisión del auditor-seguridad (criterio de salida), que debe confirmar también la lista de rutas anónimas de D-01;
- una decisión sobre PA-14 (D-02).

---

### Cierre
- Estado: Aprobado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-tr-informe-qa.md`; commit `06b913c8` en `c/adr81-fase-a` (sin push) con `tests/GPOS.Tests/SegundoFactor/SalidaFaseATests.cs` y `tests/GPOS.Tests/ModeloNg/QaOla4HttpTests.cs`
- Supuestos: cobertura con la política por omisión del contrato (70 %), medida por archivo completo y solo con las pruebas de la fase A; la meta de PA-14 se evaluó en Debug y en Release con la instancia `.\SQLEXPRESS` de este equipo
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: auditor-seguridad → revisión de la fase A y confirmación de las 5 rutas anónimas (D-01); desarrollador de C (T-e) → PA-14 (D-02); equipo A → D-03 (`AnilloLicenciaInstalacion`) y D-04 (`PA28`); documentador → O-1 (barra final de J2-1)
- Próximo paso recomendado: revisión del auditor-seguridad y decisión del propietario sobre el umbral de PA-14; después, el push de `06b913c8`
