# Informe de Seguridad: PR #33, L1a-4 «Persistencia y arranque» (Amplio)

**Fecha:** 2026-10-14 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Fuentes**
- PR #33, rama `a/lic-l1a-4` @ `9e4326c8` (worktree `GPOS-NG-lic3`), comparada con `a/lic-l1a-2` @ `9e47cc68` (`git diff a/lic-l1a-2...HEAD`).
- El diff también trae L1a-3 (`MotorEstados`, `EstadosLicencia`) por la unión de `feature/modelo-ng`; esa pieza solo la consulté donde la usa L1a-4.

**Referencias:** `[LIC]` 3.3, 3.3.1, 3.5, 3.6 y 4.1.3; `[PSF]` 4A.5 y 4A.6; blueprint de la licencia v2.4 (DL-16, reglas 12 y 13); mis informes previos (SEG-L2-05, -09, -18 y -24; CR-*; RA-*).

**Método:** no compilé ni ejecuté pruebas; las cifras que cito son las que declara el PR. **Atacante modelado:** el propio cliente con acceso de administrador a su servidor (el caso típico de un clon o de evitar un corte), con estos tres niveles de privilegio:
- **(a)** solo las credenciales de la API en SQL (INSERT sobre `Licencias`, escritura en `Configuracion`);
- **(b)** administrador de Windows;
- **(c)** `sysadmin` de SQL.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| DDL, bloqueo, consultas y permisos | `Infraestructura/Motor/SqlLicenciaSistema.cs`, `ComandosLicencia.cs`, `Data/Sistema/EsquemaSistema.cs` |
| Filas y archivos con MAC (Data Protection) | `Sistema/Licencia/FilasProtegidas.cs` |
| Almacén de disco | `Sistema/Licencia/AlmacenLicenciaDisco.cs` |
| Arranque, refresco, carga, solicitud e historial | `Sistema/Licencia/EstadoLicenciaService.cs` |
| Importador | `Sistema/Licencia/ImportadorCarpetaEntrada.cs` |
| Huella | `Sistema/Licencia/HuellaEntorno.cs` |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| PA-01 | **Media** | Si la lectura de la huella falla después de reiniciar, el cambio de entorno no se detecta y la marca de entorno guardada **se borra** (falla abierta) |
| PA-02 | **Media** | Una fila insertada en `Licencias` con la misma `sec` que la vigente hace que la vigente «no verifique» y se use la anterior: se deshace un corte, una baja de empresa o una reducción de cupo |
| PA-03 | Baja | Un `PublicadoUtc` insertado en `LicenciaLlavesRetiradas` alarga la gracia de una llave retirada hasta el `vence` de la licencia |
| PA-04 | Baja | No se verifica una carpeta de la licencia que ya existe (dueño, DACL, puntos de reanálisis) |
| PA-05 | Baja | SEG-L2-05 solo se aplica al arrancar: una licencia `Produccion` cargada en caliente en Amplio sigue operando |
| PA-06 | Baja | Importador: un archivo ilegible o bloqueado detiene todas las importaciones (bloqueo en cabeza de cola), y un archivo a medio escribir se rechaza |
| PA-07 | Informativa | Reiniciar la gracia de entorno borrando la fila y el archivo `estado`: dentro del riesgo residual firmado (K-LV-06), con la bitácora pendiente (DL-04) |
| PA-08 | Informativa | Rollback de filas con MAC (no llevan contador): analizado, sin efecto útil para el atacante, salvo PA-02 y PA-03 |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Observación:** `DENY UPDATE, DELETE, ALTER` en Estricto y disparadores de solo inserción siempre. El `INSERT` sigue abierto, por necesidad (PA-02, PA-03) |
| A02 Criptografía | **Bien.** Data Protection (cifrado autenticado) con propósitos separados para estado y aceptación |
| A03 Inyección | **Bien.** Todo va parametrizado con Dapper, el `LIKE` se escapa, las fechas van como `datetime2` y `'A'`/`'R'` son literales |
| A04 Diseño inseguro | **Hallazgos** PA-01, PA-02 y PA-05 |
| A05 Configuración | **Observación** PA-04; los `DENY` no se aplican en Amplio (es Estricto, del desarrollador I) |
| A06 Componentes | **No aplica** |
| A07 Autenticación | **No aplica** |
| A08 Integridad | **Bien** en las filas con MAC (amarradas a clave e instalación), en las escrituras atómicas y en el orden base → disco. Ver PA-02 |
| A09 Registro y monitoreo | **Bien:** eventos con `EventId`; la bitácora llega con DL-04 |
| A10 SSRF | **No aplica** |

---

## 4. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| DDL idempotente | Verificado: guarda de forma (51613), `IF … IS NULL`, índices filtrados por `'A'`, disparadores `CREATE OR ALTER` habilitados en cada arranque, CHECK de coherencia (aceptada/rechazada, tamaño ≤ 64 KB, `AceptadaUtc` solo distinta en `RESTAURACION`) | `SqlLicenciaSistema.cs:16-87` |
| `sp_getapplock` | Verificado: exclusivo, dueño la transacción, 10 s, error 51615. Se toma también en la reinserción desde el disco | `ComandosLicencia.cs:146-152`; `EstadoLicenciaService.cs:246, 464` |
| Permisos | `DENY UPDATE, DELETE, ALTER` a `gpos_api`: impide `TRUNCATE` y deshabilitar los disparadores. Solo en Estricto | `SqlLicenciaSistema.cs:93-98` |
| Filas con MAC: reutilización entre claves o instalaciones | **No es posible:** `Leer` exige `V == 1`, `Clave` exacta e `InstalacionId` exacta (ordinal). `LeerInstalacion` se amarra a sí misma. El sello usa otro propósito. Un código repetido en `Gracias` no verifica | `FilasProtegidas.cs:105-142` |
| Rollback de una fila vieja | Posible (no hay contador). Efecto analizado en PA-08: la `sec` máxima y el piso son el máximo de tres fuentes, y una `Gracias` vieja es **más** restrictiva. Ver PA-03 y PA-07 | — |
| Disco | DACL protegida en una sola operación al **crear** la carpeta, reemplazo atómico (temporal y `Move`), nombres de archivos protegidos cerrados y nivel del sello validado. Ver PA-04 | `AlmacenLicenciaDisco.cs:73-161` |
| Sellos `.acept` | Amarrados a SHA-256 del contenido, nivel e instalación, con su propio propósito, y `AceptadaUtc ≤ ahora` | `EstadoLicenciaService.cs:241-255` |
| LV-21 | Se toma la mayor `sec` que verifica para **esta** instalación entre `vigente.gposlic` y `Procesados`. Solo se reinserta si supera la de la base. Con sello válido, con su `AceptadaUtc`; sin sello, se trata como **nueva** con las reglas de hoy (`comoNuevo` excluye su propio contenido de la `sec` máxima). No permite volver a una licencia anterior | `:222-260` |
| «Ya aceptado» por (contenido, nivel) | Verificado: `NivelAceptadoAsync`, con `UX_Licencias_Aceptada` y la captura de 2601/2627 como respaldo. Un nivel superior abre una fila nueva (base de SEG-L2-24) | `:479-494`; `SqlLicenciaSistema.cs:56-57` |
| 50 rechazos completos al día | Verificado: después de 50, solo el SHA-256 y el motivo | `:501-506` |
| Importador de 20 por hora | Verificado: las cargas se serializan con el bloqueo, así que no hay carrera con L-03. Ver PA-06 | `ImportadorCarpetaEntrada.cs` |
| `Anteriores` cortada en la primera que no verifica | Verificado en `Anteriores`. **La vigente sí salta las filas que no verifican:** ver PA-02 | `EstadoLicenciaService.cs:363-378` |
| Regla 12 (`RetiroEfectivoUtc`) | Se calcula desde `LicenciaLlavesRetiradas`, de solo inserción. Solo cuentan los retiros derivables (`BINARIOS` y retirada en el recurso). Ver PA-03 | `:380-396, 404-405` |
| `Licencia.Gracias` cada 15 min | Verificado. Solo se escribe con una vigente que verificó, nunca en `Ilegible`. Ver PA-01 sobre lo que escribe | `:423-433` |
| SEG-L2-05 | Solo al arrancar: PA-05 | `:170-179` |
| La huella C-07 conserva la última si falla | **Solo en memoria:** después de reiniciar no hay ninguna última huella. Ver PA-01 | `HuellaEntorno.cs:28, 57-61` |
| Elevación entre instalaciones | No es posible: `InstalacionId` va en cada fila, sello y archivo protegido; `Verificar` exige la `instalacion` local (ordinal); sin `InstalacionId` válido no se arranca (en Estricto) | `:183-198, 268` |

---

## 5. Hallazgos

### PA-01 · Media · Una lectura fallida de la huella desactiva la detección del entorno y borra la marca

- **Riesgo:** `HuellaEntornoSql` guarda la última huella **solo en memoria** (`_ultima`). Después de un reinicio con la lectura fallando (un error, `recovery_fork_guid` NULL según PA-47, o la identidad de la API sin permiso sobre `sys.database_recovery_status`), `LeerAsync` devuelve `Huella = null`. Con una vigente, `RefrescarAsync` se salta la comparación (`huella.Huella is { } h`) y deja `entorno = null`. Luego `GuardarMarcasAsync` **reescribe** `Licencia.Gracias` y el archivo `estado` con `Entorno = null`, y así borra la primera detección que ya estaba guardada. Hay dos consecuencias:
  - un clon cuyo dueño niega a la API la lectura de la huella opera **sin gracia de entorno y sin límite**, y sin repetir la manipulación (el residual firmado K-LV-06 supone que hay que repetirla);
  - si la lectura vuelve, la detección empieza de cero (la marca ya se borró).
  
  Además, una instalación en Estricto con los permisos mal puestos (AI-02 aún sin confirmar) se queda sin detección por accidente. `[LIC]` 3.3.1 pide conservar la última huella calculada y avisar; que un error no cuente como cambio no debería convertirse en que un error borre lo detectado.
- **Evidencia:** `HuellaEntorno.cs:28, 46-47, 57-61`; `EstadoLicenciaService.cs:304-317, 328-329, 426-432`.
- **Remediación (≈ 0,15 dp):**
  1. Persistir la última huella calculada en la fila `Gracias` y en el archivo `estado` (ya tienen MAC) y usarla cuando la lectura falla también después de reiniciar.
  2. Cuando la lectura falla, **arrastrar** la marca de entorno existente (la más antigua entre la fila y el disco) y no escribir nunca `Entorno = null` encima de una marca guardada, salvo que una lectura **correcta** coincida con la huella de la vigente.
  3. Si no se ha podido calcular ninguna huella durante más de `graciaDias` con una vigente, tratarlo como un entorno distinto (falla cerrado) y avisar al SUPER.
  4. Prueba: con la marca guardada, reiniciar con la lectura fallando y comprobar que la marca se conserva.

### PA-02 · Media · Volver a la licencia anterior insertando una fila en `Licencias`

- **Riesgo:** la consulta 4.2 elige una fila por `sec` (`ROW_NUMBER` con `avanzado` primero y luego el menor `Id`) y marca `ContenidoUnico = 0` si en esa `sec` hay dos contenidos. `LeerCadenaAsync` toma como vigente **la primera que verifica** y se salta las que no. La identidad de la API puede hacer `INSERT` en `Licencias`, por necesidad: los `DENY` solo cubren `UPDATE`, `DELETE` y `ALTER`, y los disparadores tampoco cubren el `INSERT`. Por eso, con solo las credenciales de la API (nivel a), una fila `'A'` con la `sec` de la vigente y otro SHA-256, o con `NivelFirma = 'avanzado'` y un JWS que no verifica, hace que la `sec` vigente se salte. La licencia **anterior** pasa a regir sin que se marque `Ilegible`. Así se deshacen un `corte: "inmediato"` (CW-02, la herramienta de GSF contra el fraude), la baja de una empresa, una reducción de usuarios o de módulos, o un cambio de RNC. El efecto dura como mucho hasta el `vence` de la licencia anterior (≈ 1 mes con la suscripción mensual), y se repite con cada licencia nueva. No hace falta el anillo, ni `sysadmin`, ni tocar el disco.
- **Evidencia:** `ComandosLicencia.cs:161-175`; `EstadoLicenciaService.cs:363-378`; `SqlLicenciaSistema.cs:75-80, 96-97`.
- **Remediación (≈ 0,2 dp):**
  1. Dentro de cada `sec`, elegir la fila **que verifica**, no por nivel e `Id`; varias filas de una misma `sec` que verifican con contenidos distintos son un error de integridad.
  2. **No caer en silencio a una licencia anterior:** si hay filas `'A'` con una `sec` mayor que la vigente encontrada, o si la `sec` máxima con MAC (fila `Licencia.SecMax` o archivo `secmax`) es mayor, registrar `FilaLicenciaInvalida` y evaluar como `Ilegible` (72 h con el tope de `Gracias`), que es lo más restrictivo, en lugar de usar la anterior.
  3. Prueba: insertar una fila con la misma `sec` y otro contenido y comprobar que no rige la anterior.

### PA-03 · Baja · Un `PublicadoUtc` insertado alarga la gracia de una llave retirada

- **Riesgo:** `ConRetiro` toma `Max(PublicadoUtc)` de **todas** las filas del `kid`, incluidas las insertadas a mano con origen `BINARIOS` y otro `FuenteRef`. `RetiradasDerivables` filtra el `kid`, no la fila. Un `PublicadoUtc` en el futuro corre el inicio de la gracia de `LlaveRetirada`, y el retiro solo queda acotado por el `vence` de esa licencia (`AplicarEspeciales`). Es el escenario de una llave comprometida (una licencia falsificada aceptada antes del retiro), más la escritura en la base. Con DL-14, el `vence` está a como mucho 200 días de `emitida`.
- **Evidencia:** `EstadoLicenciaService.cs:384-388, 404-405`; `RegistrarRetirosBinariosAsync` siempre inserta `PublicadoUtc = null` (`:211-212`).
- **Remediación (≈ 0,02 dp):** para el origen `BINARIOS`, no usar `PublicadoUtc` (es null por construcción) o rechazar las filas que lo traigan. Para `MANIFIESTO`, tomarlo solo del JWS del manifiesto que deriva el retiro (CV-08), no de la columna.

### PA-04 · Baja · No se verifica una carpeta que ya existe

- **Riesgo:** `CrearProtegida` solo pone la DACL al **crear** la carpeta. Si `Licencia` o sus subcarpetas ya existen, no se comprueba su dueño, su DACL ni si son un punto de reanálisis (una unión de directorios no necesita privilegios). En `%ProgramData%`, un usuario estándar puede crear subcarpetas (CREATOR OWNER) **antes** del primer arranque, quedarse como dueño y luego borrar los archivos protegidos o redirigir la carpeta. Pierde la segunda fuente que «un `sysadmin` de SQL no alcanza», y puede llenar `Entrada` de archivos basura (PA-06). El PR lo marca como pendiente (ADR-77, punto 4).
- **Evidencia:** `AlmacenLicenciaDisco.cs:58-60, 73-90`.
- **Remediación (devops y L, antes de Estricto):** al arrancar, comprobar en cada carpeta que el dueño sea Administradores o SYSTEM, que la DACL esté protegida y sea la esperada, y que no haya `ReparseDisposition`. Si algo no cumple, rehacerla o no arrancar en Estricto. Crear también `GPOS NG` con una DACL protegida.

### PA-05 · Baja · SEG-L2-05 solo al arrancar

- **Riesgo:** una licencia `Produccion` o `Beta` cargada por L-03 o por el importador con la API en Amplio se acepta y la API sigue en Amplio hasta el próximo reinicio, que puede tardar semanas. SEG-L2-05 busca que la operación real nunca corra en el modo permisivo.
- **Evidencia:** `EstadoLicenciaService.cs:170-179` (solo en `ArrancarAsync`).
- **Remediación (≈ 0,05 dp):** en Amplio, rechazar en la carga el anillo `Produccion` o `Beta` con un código propio y el mensaje de pasar a Estricto, o aceptarla y poner un indicador que bloquee como al arrancar. Agregar una prueba.

### PA-06 · Baja · Importador: bloqueo en cabeza de cola y archivos a medio escribir

- **Riesgo:**
  - Una excepción al leer un archivo (bloqueado o ilegible) aborta `ProcesarAsync`, y como el orden es del más antiguo al más reciente, ese archivo detiene **todas** las importaciones en cada ciclo, incluida la renovación que deja el agente.
  - Un archivo que el agente todavía está escribiendo se lee incompleto, se rechaza y va a `Rechazados`.
  - El cupo de 20 por hora vive en memoria y se reinicia al arrancar (menor).
- **Evidencia:** `ImportadorCarpetaEntrada.cs:25-42`.
- **Remediación (≈ 0,05 dp):** un `try/catch` por archivo, que lo pase a `Rechazados` después de N intentos. El agente escribe en un temporal con prefijo `.` (el importador ya los ignora) y luego lo renombra (entrega a L4 y al agente).

### PA-07 · Informativa · Reiniciar la gracia de entorno borrando la fila y el archivo

Con privilegios (a) y (b), borrar `Licencia.Gracias` y el archivo `estado` hace que la primera detección vuelva a ser «ahora». Es el riesgo residual firmado Medio de `[LIC]` 3.3.1 (K-LV-06: «una base manipulada para reiniciar su gracia de entorno», mientras se repita la manipulación). Pero `[LIC]` 3.3.1 y NV-01 nombran la **bitácora** como tercera fuente de esta marca, y aquí no se usa hasta DL-04. Cuando llegue DL-04, la marca de entorno tiene que leerse también de `BitacoraSeguridad`, que es de solo inserción.

### PA-08 · Informativa · Rollback de filas con MAC

Ninguna fila lleva contador, así que se puede restaurar un texto protegido anterior de la misma clave e instalación. Revisé cada caso:
- **`SecMax` y `PisoNivelFirma`:** el valor efectivo es el máximo con `Licencias` (solo inserción) y el disco, así que el rollback de una fuente no lo baja.
- **`Gracias`:** una `UltimaVerificacionUtc` vieja es más restrictiva (se toma la más antigua).
- **`RegresosNivel`:** un estado viejo solo permitiría reutilizar autorizaciones de licencias firmadas por GSF con `s2`, que ya rechaza el orden de `sec`.
- **`InstalacionId`:** borrarlo en Amplio genera otro, y entonces ninguna licencia verifica (restrictivo).

Sin efecto útil para el atacante, salvo PA-02 y PA-03.

---

## 6. Controles bien implementados

- **Filas y archivos con cifrado autenticado**, amarrados a la versión, la clave y la `InstalacionId`, con propósitos separados para estado y aceptación. Fallan cerrados ante cualquier excepción de lectura.
- **Orden base → disco** («el disco nunca adelanta a la base»), reemplazo atómico y sello `.acept` después de confirmar.
- **LV-21 sin rollback:** solo se reinserta una `sec` mayor; sin sello, la licencia pasa por las reglas de hoy.
- **Una sola puerta de carga** (L-03 e importador) con `sp_getapplock`, el SHA-256 del contenido y el nivel, el índice único de respaldo y RA-05 (la recarga no tiene efecto).
- **SQL** parametrizado, con `datetime2` explícito, `LIKE` escapado, disparadores de solo inserción recreados en cada arranque y `DENY ALTER`, que impide `TRUNCATE` y deshabilitar los disparadores.
- **Regla 12** sobre una tabla de solo inserción, con retiros derivables (CV-08).
- **SEG-L2-09** en la solicitud, sin secretos.

---

## 7. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | PA-02, PA-01 | Antes de L1b (`UseLicencia` hace efectivo el estado) y en todo caso antes de Estricto | ≈ 0,35 dp |
| 2 | PA-03, PA-05, PA-06 | En L1a-4 (seguimiento) o L1b | ≈ 0,12 dp |
| 3 | PA-04 | Devops y L, antes de Estricto (ADR-77, punto 4) | ≈ 0,2 dp |
| 4 | PA-07 | Con DL-04 | — |

---

## 8. Recomendación

**PR #33: Aprobado con observaciones.**

No hay hallazgos Críticos ni Altos. PA-01 y PA-02 son Medios y de código, y salen baratos. Recomiendo resolverlos antes de L1b, que es cuando el estado empieza a bloquear la operación, y como condición para pasar a Estricto. El resto son Bajos o informativos. Es una recomendación técnica: la decisión es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr33-persistencia-2026-10-14.md`
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir. Que `sys.database_recovery_status` pueda fallar o devolver NULL para la identidad de la API viene de PA-47 y AI-02, sin verificar.
- Decisiones candidatas a ADR: precisión de la regla «la vigente es la primera que verifica» (PA-02): si una fila con una `sec` mayor no verifica, se evalúa como `Ilegible` y no se cae a la anterior. Alternativa descartada: dejarlo como está, que convierte una fila insertada en un rollback.
- Entregas a otros agentes:
  - desarrollador-backend (L): PA-01, PA-02, PA-03, PA-05 y PA-06;
  - devops: PA-04 (comprobar la raíz y las carpetas al arrancar) y que la identidad de la API pueda leer la huella en Estricto (AI-02);
  - arquitecto-software: confirmar la precisión de PA-02 y que la bitácora sea fuente de la marca de entorno con DL-04 (PA-07);
  - agente o L4: escribir en `Entrada` con un temporal `.` y renombrar (PA-06);
  - qa-automatizado: vectores de PA-01 (reinicio con la lectura fallando) y PA-02 (fila insertada con la misma `sec`).
- Próximo paso recomendado: corregir PA-02 y PA-01 en un seguimiento de L1a-4 antes de empezar L1b.

---

## 9. Lectura de diferencias (`9e4326c8..48e22905`)

**Commits:** `69a13a24` (une L1a-2 con DL-17 y DL-14 firmadas) y `48e22905` (correcciones 1, 2, 6 y 8 de la validación de L1a-4). Revisé solo en lectura, sin compilar. Las pruebas son las que declara el PR (persistencia 34/34, Licencia 468 con 1 omitida, Arquitectura 174/174, suite 2766/0/19): **no las reproduje**.

| Punto | Estado | Evidencia y comentario |
|---|---|---|
| **PA-02, parte sin firma (corrección 6)** | **Cerrado** | La consulta 4.2 devuelve **todas** las filas `'A'` de cada `sec` y `PorSec` verifica cada una. Una fila cuenta solo si coinciden JWS, SHA-256, nivel y `sec` con la fila. Las que no verifican se ignoran con `FilaLicenciaInvalida`, y dos contenidos que verifican en la misma `sec` dejan esa `sec` sin verificar. Así, una fila insertada con la `sec` vigente (otro contenido, nivel `avanzado` con un JWS falso, o un JWS real con otra `sec`) ya no hace saltar la vigente. Rellenar la ventana de 32 `sec` con filas falsas deja la instalación en `Ilegible`, es decir, falla cerrado. (`ComandosLicencia.cs`, `UltimasAceptadasAsync`; `EstadoLicenciaService.cs`, `PorSec` y `LeerCadenaAsync`) |
| **La corrección 6 extendida a la carga** | **No abre ninguna falla; cierra una** | En la carga, la `sec` máxima efectiva y el perfil vigente salen ahora solo de filas que verifican. Antes, una fila insertada con una `sec` mayor y `PerfilMin = 'basica'` podía **bajar el perfil heredado**: esa falla abierta queda cerrada. La `sec` máxima sigue siendo el máximo junto con las dos fuentes con MAC (la fila `Licencia.SecMax` y el archivo `secmax`), así que no cae por ignorar filas falsas. Queda un caso límite, informativo: si unos binarios **quitaran** un `kid` del recurso (en vez de retirarlo), sus filas dejarían de contar y solo quedarían las fuentes con MAC. GSF no debe quitar llaves del recurso, solo retirarlas |
| **PA-05 (corrección 2)** | **Cerrado** | En Amplio, una carga en caliente (L-03 o el importador) de una licencia `Produccion` o `Beta` se rechaza con `LICENCIA_ANILLO_NO_ADMITIDO`, `ArranqueAmplioBloqueado` y un mensaje para el SUPER. Se aplica antes de insertar. Una recarga idempotente no tiene efecto, y el arranque la bloquea igual. La reinserción con sello desde el disco no pasa por esta regla, pero queda bloqueada en el arranque siguiente |
| **PA-01 (corrección 8)** | **Cerrado en parte** | (1) La última huella correcta y su hora se guardan en la fila `Gracias` y en el archivo `estado` (con MAC), y se usan cuando la lectura falla, también después de reiniciar. (2) La marca de entorno se arrastra cuando la lectura falla y **solo** se borra tras una lectura correcta que coincide con la huella de la vigente. (3) `EntornoLecturaFallida` avisa una vez al día. Con esto, **borrar la marca provocando un fallo de lectura ya no es posible**. **Sigue abierto hasta DL-19:** en un clon que niega a la API la lectura de la huella desde el primer arranque, la huella guardada es la del original (viaja en la base y en el disco clonados) y coincide con la de la licencia, así que el clon nunca entra en gracia de entorno. Tampoco ayuda la solicitud a GSF, porque el clon puede copiar los archivos de renovación del original. El aviso diario le llega al SUPER, que en este escenario es el propio atacante. **Severidad residual: Media, pendiente de la firma de DL-19** (tratar como entorno distinto una lectura que falla más de máx(`graciaDias`, 72 h)) |
| **PA-02, parte con firma (DL-18)** | Pendiente de firma | Aún no se construye que la vigente no pueda caer en silencio por debajo de la `sec` atestiguada con MAC. Con la corrección 6, el único camino que queda para caer a una anterior es que la fila real deje de verificar: no puede alterarse (solo inserción) y solo ocurre si cambia el recurso de llaves (retiro por binarios, informativo). DL-18 cierra ese resto |
| **RA-01 / DL-17** | **Cerrado** (PR #32) | `HoraReferencia(ahora)` usa solo la hora protegida, y la carga ya la usa así. Queda una sobrecarga de compatibilidad que ignora la `emitida`; conviene marcarla `[Obsolete]` para que nadie crea que la tiene en cuenta (informativo) |
| `InternalsVisibleTo` | Movido a `GPOS.Core.csproj` | Responde a la observación del PR #32. Sin cambio en el análisis de Release |
| Corrección 1 (perfil en la reinserción) | **Correcto** | Al reinsertar con sello, el perfil sigue INV-4 con D-2: solo una firma Avanzada propia lo fija; sin ella, se hereda el vigente. Antes, la reinserción desde el disco podía bajar el perfil |

### Lo que queda hasta DL-18 y DL-19

- **DL-19 (PA-01 residual, Media):** un clon que bloquea la lectura de la huella opera sin gracia de entorno. Mitigación mientras se firma: GSF puede revisar en su tablero las instalaciones que avisan `EntornoLecturaFallida`, aunque ese aviso queda en el registro local y no llega a GSF sin el agente. Recomiendo firmar DL-19 antes de la primera licencia de pago, igual que AP-04.
- **DL-18 (PA-02 residual, Baja después de la corrección 6):** que nunca rija en silencio una `sec` menor que la atestiguada con MAC.
- **Sin cambios:** PA-03, PA-04 y PA-06 (Bajos), PA-07 y PA-08 (informativos).

### Dictamen final del PR #33

**Aprobado con observaciones.**
- PA-05 está cerrado.
- PA-02 está cerrado en su parte sin firma, y la extensión a la carga cierra además la falla abierta del perfil.
- PA-01 está cerrado en cuanto a borrar la marca. Queda abierto su residual Medio (el clon que bloquea la huella) hasta DL-19.

No hay hallazgos Críticos ni Altos. Es una recomendación técnica: la decisión es del propietario.

### Cierre (lectura de diferencias)
- Estado: Aprobado con observaciones
- Artefactos: este informe (sección 9 agregada)
- Supuestos: los resultados de pruebas son los declarados, sin reproducir
- Decisiones candidatas a ADR: DL-18 y DL-19, ya en la hoja de firma; recomiendo firmar DL-19 antes de la primera licencia de pago
- Entregas a otros agentes:
  - desarrollador L: PA-03, PA-06, `[Obsolete]` en la sobrecarga de `HoraReferencia`, y DL-18 y DL-19 cuando se firmen;
  - devops: PA-04;
  - GSF: no quitar `kid` del recurso, solo retirarlos
- Próximo paso recomendado: unir el PR #33 y llevar DL-19 a firma antes de L1b
