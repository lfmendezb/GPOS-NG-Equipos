# [Blueprint de Datos] L1a-4 «Persistencia y arranque» de la licencia firmada: filas con MAC, historial de cargas, «ya aceptado» y DDL de `GPOS_SYSDATA`

- **Fecha:** 2026-10-14. **Autor:** arquitecto-datos, equipo A.
- **Estado del documento:** diseño. Precisa `[DAT]` 6.3, que está firmado (L-01, 2026-10-14). **No cambia ninguna decisión firmada.** Lo que depende de DL-01, DL-03, DL-04, DL-11, DL-14 y DL-15 queda marcado (sección 11). Nada de esto existe en el código: verifiqué que ninguna rama local (`GPOS-NG-rg14` @ `46eac73f`, `GPOS-NG-lic` @ `a1562505`, `GPOS-NG-lic3` @ `87ec8e38`) contiene `dbo.Licencias`, `LicenciaLlavesRetiradas` ni `SqlLicenciaSistema` [V, `grep` en `src` y `database`].
- **Fuentes:**
  - `[BP2]` = `blueprint-licencia-lote2-2026-10-14.md` v2.2: §1.2 (C-03, C-05, C-06, C-08, C-11), §4.1 (L1a-4), §5.1 (S-03), §5.2, §6.1, §6.1.1, §7, §8 y los registros de cambios v2, v2.1 y v2.2;
  - `[DAT]` = `datos-t3-12-rg14-2026-10-14.md` v2: §2.2, §2.7 (S1 y S4) y §6.3;
  - `[VAL]` = `validacion-l1a-3-motor-estados-2026-10-14.md`, punto 8 y precisiones para L1a-4;
  - `[SEG]` = `revision-seguridad-blueprint-licencia-lote2-2026-10-14.md` (SEG-L2-18 y D.3 / SEG-L2-24);
  - `[SEG-PR31]` = `revision-seguridad-pr31-motor-estados-2026-10-14.md`, incluida la lectura de diferencias `4f86390b..87ec8e38`;
  - `[LIC]` = `GPOS-NG-lic/docs/arquitectura/2026-10-05-licencia-por-vigencia.md` v3.1 (§3.5, §4.1.2);
  - `[C81]` = `origin/c/adr81-fase-a-diseno:docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md` (DDL de `BitacoraSeguridad`).
- **Código leído, solo lectura:**
  - motor: `GPOS-NG-lic3/src/GPOS.Core/Sistema/Licencia/EstadosLicencia.cs` y `MotorEstados.cs` @ `87ec8e38`;
  - reglas: `GPOS-NG-lic/src/GPOS.Core/Sistema/Licencia/ReglasAceptacion.cs`, `ReglaSecuencia.cs`, `PisoNivelFirma.cs`, `AutorizacionRegresoNivel.cs` y `GPOS.Contracts/Licencia/LicenciaDtos.cs` @ `a1562505`;
  - esquema: `GPOS-NG-lic3/src/GPOS.Core/Data/Sistema/EsquemaSistema.cs`, `SistemaDbContext.cs` y `src/GPOS.Core/Sistema/RelojSitio.cs`.
  - No toqué ningún repositorio, base ni instancia. No compilé ni ejecuté nada.
- **Etiquetas:** **[V]** verificado con `ruta:línea`; **[I]** inferido. **dp** = días-persona.

---

## 0. Resumen

1. **El motor no cambia de lógica.** `GraciasGuardadas`, `CambioRncSuper` y `SituacionLicencia` se alimentan tal como están. Solo hay que corregir dos comentarios XML de `EstadosLicencia.cs` (sección 2.4).
2. **`Licencia.Gracias` y `Licencia.CambiosRnc:<empresa>`** son filas de `dbo.Configuracion` con `Valor` = `Protect` de Data Protection (propósito `GPOS.Licencia.Estado.v1`). El JSON de cada una lleva dentro su clave y el `InstalacionId`. No hace falta DDL para ellas.
3. **`dbo.Licencias` cambia respecto de `[DAT]` 6.3 en cinco puntos:**
   - `Sha256` pasa a `Sha256Contenido` (la identidad, SEG-L2-18), y se agrega `Sha256Archivo` como dato informativo;
   - **`AceptadaUtc` se separa de `RecibidaUtc`**, para que una reinserción `RESTAURACION` conserve la hora de aceptación del sello `.acept`. Sin esto, NV-02 en cadena y NV-07 fallarían después de restaurar;
   - `Kid` pasa a `Kids`, porque un archivo cofirmado `s1`+`a1` tiene dos;
   - se agrega `Emitida`;
   - **`UX_Licencias_Aceptada` pasa a ser único sobre (`Sha256Contenido`, `NivelFirma`)**, compatible con SEG-L2-24 desde hoy.
4. **`Anteriores`:** una consulta acotada (sección 4.2) devuelve una fila por `sec`, en orden descendente, con la `AceptadaUtc` mínima de esa `sec`. L1a-4 la corta en la primera que no verifique. Nunca se salta una.
5. **Hallazgo en `[DAT]` 6.3:** `Usuarios.SelloHabilitacion varbinary(256)` no alcanza para el sello con DL-05 (unos 380 bytes [I]). Pasa a `varbinary(512)`.
6. **Esquema:** se queda en `dbo`, como está firmado. «`Licencia.`» es el prefijo de las claves de `Configuracion`, no un esquema SQL. El motivo y la alternativa están en 1.2.

---

## 1. Contexto y modelo de tenencia aplicado

### 1.1 Tenencia

- Todo vive en **`GPOS_SYSDATA`**, la base de la instalación. La licencia es **de instalación** (`[BP2]` 5.1, L-03), no de empresa.
- El aislamiento entre empresas no se hace con una base ni con un esquema por empresa: se hace con el **código de empresa dentro de los datos protegidos**.
  - `FinGraciaPorEmpresa` va indexado por código.
  - Hay una fila `Licencia.CambiosRnc:<código>` por empresa, que lleva el código también dentro del JSON protegido. Así, una fila no se puede mover a la clave de otra empresa.
- Las rutas que exponen estos datos ya filtran por empresa: L-02 usa la empresa del token, y L-04, L-05 y L-08 son solo del SUPER (`[BP2]` 5.1). Este diseño no agrega ninguna lectura cruzada.

### 1.2 Por qué `dbo` y no un esquema `Licencia`

- **Elección: `dbo`**, como está firmado en `[DAT]` 6.3 (L-01). S1 concede `SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo` a `gpos_api` y niega por objeto (`[DAT]` 2.7, S1). PA-41 y S4 ya nombran `dbo.Licencias`.
- **Alternativa descartada: esquema `Licencia`.** Su único beneficio es un `DENY UPDATE, DELETE ON SCHEMA::Licencia` en una línea, en lugar de dos `DENY` por objeto. A cambio:
  - obliga a modificar S1 (conceder `SELECT, INSERT` sobre el esquema nuevo), S4 y PA-41, que están firmados;
  - hace ambiguo `Licencia.Gracias`, que se leería como el nombre de una tabla.
- Si el propietario prefiere el esquema, cuesta unos 0,1 dp. No lo recomiendo.

### 1.3 Cómo se aplica (C-11, M-4)

| Pieza | Contenido | La aplica |
|---|---|---|
| `SqlLicenciaSistema.Ddl` (`GPOS.Core/Data/Sistema/`) | Tablas, índices, disparadores y columna del sello (sección 7.1) | En Amplio, `EsquemaSistema.ActualizarAsync`, entre `ActualizarTablasAsync` y `Rptsis()` (`EsquemaSistema.cs:52-56` [V]). En Estricto, `GPOS.Migracion sistema` |
| `SqlLicenciaSistema.Permisos` | `DENY` a `gpos_api` (sección 9) | **Solo** `GPOS.Migracion sistema`, después de S1 (C-11) |
| Filas de `Configuracion` | Ninguna DDL: las escribe L1a-4 en tiempo de ejecución. `Licencia.InstalacionId` lo genera `sistema` en Estricto y la API en Amplio (C-08) | — |

**Orden en `GPOS.Migracion sistema`:**
1. `EnsureCreated` y `EsquemaSistema` (tablas);
2. `SqlLicenciaSistema.Ddl`;
3. `rptsis`;
4. S1 de `[DAT]` (roles, `gpos_sistema` y `DENY` generales);
5. `SqlLicenciaSistema.Permisos`;
6. `Licencia.InstalacionId` si falta;
7. cuentas iniciales y sellado inicial (DL-02);
8. subir la marca `GPOS.EsquemaSistema` (S1, paso 9).

**No es EF de empresa ni EF del sistema.**
- `Licencias` y `LicenciaLlavesRetiradas` **no se mapean en `SistemaDbContext`**. Se accede con SQL escrito a mano (Dapper o ADO.NET), con la conexión de ese contexto, igual que `BitacoraSeguridad` en `[C81]` (D81-01).
- **Motivo:** `GPOS_SYSDATA` se crea con `EnsureCreated` (`EsquemaSistema.cs:20-22` [V]). Si las tablas estuvieran en el modelo, una base nueva las recibiría con la forma de EF, sin índices filtrados ni restricciones. Después, el `IF OBJECT_ID … IS NULL` de la DDL se saltaría la creación correcta.
- Una prueba de arquitectura comprueba que el modelo de `SistemaDbContext` no tiene ninguna entidad sobre `Licencias` ni sobre `LicenciaLlavesRetiradas`.

---

## 2. Filas protegidas con MAC (`dbo.Configuracion`)

### 2.1 Reglas comunes

- **Tabla:** `dbo.Configuracion (Clave nvarchar(50) PK, Valor nvarchar(max), FechaModificacion, UsuarioModificacion)` (`EsquemaSistema.cs:100-102` [V]).
- **`Valor`:** la cadena de `IDataProtector.Protect(string)` con el propósito **`GPOS.Licencia.Estado.v1`** (`[DAT]` 6.3), igual que `AlmacenRelojSistema` (`RelojSitio.cs:25-49` [V]).
  - Data Protection cifra y autentica (AES-256-CBC con HMAC-SHA256). Por eso **ningún dato va en claro**: ni el RNC, ni el usuario, ni las fechas.
- **JSON interno:**
  - `System.Text.Json` con los nombres por omisión (PascalCase), como `RelojProtegido.Serializar` (`RelojProtegido.cs:268` [V]);
  - fechas UTC en ISO 8601 con `Z` (`DateTimeKind.Utc`); los null se escriben.
- **Campos de amarre obligatorios en cada fila:** `V` (versión del formato, hoy 1), `Clave` (igual a la clave de la fila) e `InstalacionId`.
  - Al leer, si `V` es desconocida, si `Clave` o `InstalacionId` no coinciden, o si el JSON no deserializa, **la fila no verifica**: se ignora, se recalcula si se puede y se registra el evento (PA-43).
  - Una fila copiada de otra clave o de otra instalación no verifica.
- **Escritura:** dentro de una transacción, con `UPDATE … ; IF @@ROWCOUNT = 0 INSERT …`. La API tiene un único proceso que escribe por instalación; el bloqueo de aplicación de 4.4 cubre los casos con concurrencia.

### 2.2 `Licencia.Gracias` (NV-01; `[VAL]` punto 8; `[SEG-PR31]` SEG-PR31-02)

```json
{
  "V": 1,
  "Clave": "Licencia.Gracias",
  "InstalacionId": "<id de la instalación>",
  "SecVerificada": 177010563200,
  "UltimaVerificacionUtc": "2026-11-20T14:03:00.000Z",
  "HoraCorte": "06:00",
  "FinGraciaPorEmpresa": [
    { "Empresa": "EMP01", "TopeGraciaUtc": "2026-12-31T10:00:00.000Z" },
    { "Empresa": "EMP02", "TopeGraciaUtc": null }
  ],
  "Entorno": { "PrimeraDeteccionUtc": "2026-11-18T09:12:00.000Z", "HuellaDetectada": "<SHA-256 hex de la huella leída>" },
  "RetirosConocidos": [ { "Kid": "gsf-lic-s1", "ConocidoUtc": "2026-11-19T00:00:00.000Z" } ]
}
```

**Correspondencia con el motor** (`EstadosLicencia.cs`, `GraciasGuardadas(DateTime UltimaVerificacionUtc, IReadOnlyDictionary<string, DateTime?> FinGraciaPorEmpresa, TimeOnly? HoraCorte = null)` [V]):

| Campo JSON | Tipo del motor | Regla de L1a-4 |
|---|---|---|
| `UltimaVerificacionUtc` | `UltimaVerificacionUtc` | Al leer: la **más antigua** entre esta fila y el archivo `estado` del disco (2.5), con `MotorEstados.MarcaMasRestrictiva`. **La bitácora no es fuente de esta marca** (2.6) |
| `FinGraciaPorEmpresa` (arreglo) | `IReadOnlyDictionary<string, DateTime?>` | Se escribe **exactamente** `EstadoEmpresaCalculado.TopeGraciaUtc` de cada empresa evaluada, null incluido (`[VAL]`, precisión L1a-4; SEG-PR31-02). Al leer se construye un `Dictionary` con `StringComparer.Ordinal`. Así, dos códigos que solo difieren en mayúsculas llegan los dos y `FinGuardado` falla cerrado (`MotorEstados.cs:398-408` [V]). **Un código repetido exacto hace que la fila no verifique**: el `Dictionary` no puede representarlo |
| `HoraCorte` (`"HH:mm"`) | `TimeOnly? HoraCorte` | Siempre el `horaCorte` de la licencia verificada. Null solo en filas de una versión anterior; el motor usa entonces 06:00 (`MotorEstados.cs:42` [V]) |
| `SecVerificada` | — (no lo usa el motor) | `sec` de la licencia con la que se calcularon los topes. Sirve para diagnóstico y para L-04 |
| `Entorno` | Entrada de `MotorEstados.GraciaEntorno(primeraDeteccionUtc, …)` | Marca de **instalación** (`[VAL]` punto 8). Null si la huella coincide. Se fija una sola vez por huella distinta y se borra al aceptar una licencia con la huella nueva. Al leer: la más antigua entre esta fila, `estado` y la bitácora (DL-04) |
| `RetirosConocidos` | `conocidoUtc` de `MotorEstados.GraciaLlaveRetirada` | Marca de instalación por `kid`. Al leer: la más antigua entre esta fila, `estado`, `MIN(RegistradoUtc)` de `LicenciaLlavesRetiradas` para ese `kid` y la bitácora (DL-04) |

**Por qué el arreglo y no un objeto JSON:** con un objeto `{ "EMP01": … }`, el comportamiento ante claves duplicadas depende del deserializador [I]. El arreglo hace explícito el duplicado y lo resuelve con falla cerrada.

**Cuándo se escribe:**
- **Solo** después de una evaluación con una licencia vigente **que verificó**.
- **Nunca** durante `Ilegible`: si se escribiera, la última verificación avanzaría sin que haya habido una verificación.
- Se escribe si cambia algo distinto de `UltimaVerificacionUtc`, o si esta avanzó **15 minutos o más** desde lo guardado [I]. Esa cadencia acorta la gracia `Ilegible` como mucho 15 minutos (va del lado restrictivo) y baja las escrituras de 1 440 a unas 96 al día.
- **Tamaño:** con 50 empresas, unos 3 KB de JSON y unos 4,3 KB en `Valor` [I].

**Si la fila falta o no verifica:** `Guardadas = null`. Con eso no hay gracia `Ilegible` y las empresas quedan en `SoloConsulta` (`[LIC]` 4.1.2; `MotorEstados.cs:386` [V]). Es lo firmado.

### 2.3 `Licencia.CambiosRnc:<empresa>` (NV-07; C-06; S-03 v2.2) — **pendiente de DL-03**

- **Clave:** `Licencia.CambiosRnc:` (20 caracteres) más el código de empresa (`nvarchar(30)`, `SistemaDbContext.cs:74` [V]). En total, **50 como máximo**, que es justo el ancho de `Clave`.
  - El código que escribe la fila comprueba la longitud. Si algún día el código de empresa crece, la clave pasa a usar el SHA-256 del código.

```json
{
  "V": 1,
  "Clave": "Licencia.CambiosRnc:EMP01",
  "InstalacionId": "<id de la instalación>",
  "Empresa": "EMP01",
  "RncAnterior": "101123456",
  "RncNuevo": "131234567",
  "CambiadoUtc": "2026-11-21T15:00:00.000Z",
  "UltimoCambioUtc": "2026-11-25T12:00:00.000Z",
  "Usuario": "GSF",
  "Origen": "S03",
  "SecVigenteAlCambiar": 177010563200
}
```

| Campo | Motor (`CambioRncSuper(string RncAnterior, string RncNuevo, DateTime CambiadoUtc)` [V]) | Regla |
|---|---|---|
| `RncAnterior`, `RncNuevo` | Iguales | Forma canónica: solo dígitos ASCII, 9 u 11, sin guiones ni espacios. El motor vuelve a canonizar con `RncCanonico` (`MotorEstados.cs:440-449` [V], según `[SEG-PR31]`) |
| `CambiadoUtc` | Igual | Hora protegida (`IRelojProtegido`). **En una cadena A→B→C se conserva**, igual que `RncAnterior` (S-03 v2.2) |
| `UltimoCambioUtc`, `Usuario`, `Origen` (`S03` o `VERBO`), `SecVigenteAlCambiar` | — | Para auditoría. `Usuario` es el código del SUPER; con el verbo va null y el SID queda en la bitácora (D.2). **El motivo no va en la fila**: va en el evento `CambioRncSuper` de la bitácora |

- **Una fila por empresa.** Se reemplaza en su sitio.
- **El motor la recibe en `EmpresaEvaluada.CambioRnc`**, o null si falta o no verifica. Con null no hay transición por RNC, que es la falla cerrada.
- **Concurrencia de S-03 y del verbo:** `sp_getapplock @Resource = N'GPOS.Licencia.CambioRnc:<empresa>'`, exclusivo y de transacción, antes de leer y escribir la fila. La segunda escritura, en la base de la empresa, va fuera de esa transacción. Es idempotente por la regla de SEG-L2-16.

### 2.4 Lo que cambia en el motor: solo comentarios

| Archivo y línea | Hoy | Debe decir |
|---|---|---|
| `EstadosLicencia.cs`, `LicenciaAceptada`, `<param name="AceptadaUtc">` | «`Licencias.RecibidaUtc`» | «`Licencias.AceptadaUtc`: la mínima de las filas aceptadas de esa `sec` (datos L1a-4, 4.2)» |
| `EstadosLicencia.cs`, `GraciasGuardadas`, `<param name="UltimaVerificacionUtc">` | «La marca más restrictiva entre la base, la bitácora y el disco» | «La más restrictiva entre la fila y el archivo `estado` del disco (la bitácora no es fuente de esta marca)» |

**No cambian ni la lógica, ni las firmas, ni las pruebas.** Además, el `<param>` de `SituacionInstalacion.SecMaximaEfectiva` (`ReglasAceptacion.cs:12-13`, rama `a/lic-l1a-2` [V]) nombra `LicenciaSecMax`: la clave es `Licencia.SecMax`.

### 2.5 Las demás filas y el archivo `estado`

| Clave / archivo | Contenido (además de `V`, `Clave` e `InstalacionId`) | Lo usa |
|---|---|---|
| `Licencia.InstalacionId` | `Valor` (el identificador, 128 bits aleatorios, en el formato del campo `instalacion` de la licencia), `CreadoUtc`, `Origen` (`MIGRACION` o `API-AMPLIO`) | C-08. Los verbos de 5.1 no corren si no verifica (D.2) |
| `Licencia.SecMax` | `Sec`, **`Sha256Contenido`** (hex) y `Kids` | LV-05 e INV-6. **El SHA-256 es obligatorio:** `ReglasAceptacion` exige `Sha256ContenidoSecMaxima` cuando hay `SecMaximaEfectiva` (`ReglasAceptacion.cs:225` usa `!.Value` [V]). Si la `sec` máxima sale de esta fila o de `secmax` porque se borraron filas de `Licencias`, sin el SHA-256 L1a-4 no podría llenar la situación. **El archivo `secmax` del disco lleva el mismo JSON**, con `Clave = "Disco.SecMax"` |
| `Licencia.PisoNivelFirma` | `Nivel` (`basico` o `avanzado`) | INV-11 (`FuentesPisoNivel.Configuracion`, `PisoNivelFirma.cs:58-60` [V]). El archivo `pisonivel` lleva el mismo JSON, con `Clave = "Disco.PisoNivel"` |
| **`Licencia.RegresosNivel`** (nueva respecto de `[DAT]`) | `Kids: [{ Kid, DesdeMinimo, InicioRegreso, HastaVigente, SecMaxima }]` = `EstadoRegresoKid` (`AutorizacionRegresoNivel.cs:16` [V]) | L1a-2 la pide con MAC y derivable de los JWS ([PSF] 4A.6, firmado) |
| `Licencia.SelloInicial` y `Licencia.HuellaAnclada` | Las fija `[DAT]` 6.3 sin cambios (`SelloInicial`: `SelladoUtc` y número de cuentas) | SL, H-17 v2 |
| `Licencia.PadronSellos` | Lo fija SL con su propio propósito (`GPOS.Usuarios.Padron.v1`) | **DL-01** (sección 11) |
| Archivo `estado` del disco (`%ProgramData%\GPOS NG\Licencia\`, C-03) | `Clave = "Disco.Estado"`, `UltimaVerificacionUtc`, `Entorno` y `RetirosConocidos`, **sin** `FinGraciaPorEmpresa` | Segunda fuente de las marcas. Si la fila `Gracias` falta, el disco **no** da la gracia `Ilegible` (`[LIC]` 4.1.2) |
| Sellos `Aceptaciones\<sha256Contenido>-<nivel>.acept` | `Sha256Contenido`, `NivelFirma`, **`AceptadaUtc`**, `InstalacionId`. Propósito propio: `GPOS.Licencia.Aceptacion.v1` | INV-7 y LV-21. El nombre lleva el SHA-256 **del contenido** (SEG-L2-18) y el nivel (SEG-L2-24). De aquí sale `AceptadaUtc` en una reinserción (4.1) |

### 2.6 Por qué la bitácora no es fuente de `UltimaVerificacionUtc`

- La regla es «la marca más antigua». Una fuente que se escribe con menos frecuencia queda siempre más atrás, y acortaría la gracia `Ilegible` sin que nadie haya atacado.
- Para que la bitácora sirviera, habría que escribir un evento cada 15 minutos: unas 70 000 filas al año en `BitacoraSeguridad`, con 2 años de retención [I].
- Un atacante con `sysadmin` de SQL no puede **adelantar** la marca, porque eso exige el anillo; solo puede borrarla o volver a una más antigua, y las dos cosas van del lado restrictivo. Por eso la fila y el disco bastan.
- La bitácora **sí** es fuente de las marcas de **inicio** (entorno y retiro), que son eventos únicos (`[LIC]` 3.3.1).

---

## 3. Tablas y relaciones

| Tabla | Clave | Relaciones | Escribe | Lee |
|---|---|---|---|---|
| `dbo.Licencias` | `Id bigint IDENTITY` (PK agrupada; aproximadamente cronológica) | Ninguna FK: el historial sobrevive a todo y la licencia es de instalación | API (L1a-4: L-03, importador y reinserción al arrancar), solo `INSERT` | API |
| `dbo.LicenciaLlavesRetiradas` | `Id int IDENTITY`; único (`Kid`, `Origen`, `FuenteRef`) | Ninguna FK | API, solo `INSERT` | API |
| `dbo.Configuracion` (existente) | `Clave` | — | API y `GPOS.Migracion` | API |
| `dbo.Usuarios.SelloHabilitacion` (columna) | — | — | API y `GPOS.Migracion` (SL) | API |

### 3.1 `dbo.Licencias`: columnas

| Columna | Tipo | Nulo | Qué es |
|---|---|---|---|
| `Id` | `bigint IDENTITY` | No | Clave |
| `Lid` | `uniqueidentifier` | Sí; obligatorio en `A` | `lid` del contenido |
| `Sec` | `bigint` | Sí; obligatorio en `A` | `sec` del contenido |
| `Emitida` | `datetime2(3)` | Sí; obligatorio en `A` | `emitida` (UTC). Caché para L-04, L-05 y el diagnóstico; el motor la toma del contenido verificado |
| `Kids` | `varchar(130)` | Sí; obligatorio en `A` | `kid` de las firmas que contaron (`ResultadoAceptacion.KidsFirma`), ordenados y separados por comas, sin espacios. Hasta 3 de 40 caracteres |
| `Jws` | `varbinary(max)` | Sí; obligatorio en `A` | El archivo. ≤ 64 KB. Null en un rechazo por encima del tope de 50 al día (LV-15) |
| **`Sha256Contenido`** | `binary(32)` | Sí; obligatorio en `A` | **Identidad de la licencia** (SEG-L2-18): `VerificadorJws.HuellaContenido`. Null en un rechazo cuyo JWS no verificó |
| **`Sha256Archivo`** | `binary(32)` | Sí | Dato informativo (`ResultadoAceptacion.Sha256Archivo`). Null si el archivo supera 64 KB |
| `Origen` | `varchar(14)` | No | `AGENTE`, `MANUAL`, `SINCRONIZACION` o `RESTAURACION` (`OrigenesCargaLicencia` [V]) |
| `Resultado` | `char(1)` | No | `A` o `R` |
| `Motivo` | `varchar(60)` | Obligatorio en `R` | Código de `CodigosLicencia` |
| `NivelFirma` | `varchar(9)` | Sí; obligatorio en `A` | Nivel **efectivo** de la carga: `avanzado` solo con firma Avanzada propia. Caché, porque el piso se recalcula desde los JWS (INV-11) |
| `NivelMin`, `PerfilMin` | `varchar(9)` | Sí | Caché del contenido |
| `RecibidaUtc` | `datetime2(3)` | No | Hora protegida en que **se insertó esta fila** |
| **`AceptadaUtc`** | `datetime2(3)` | Sí; obligatorio en `A`, null en `R` | **Hora de aceptación de INV-7**. Es igual a `RecibidaUtc` en `AGENTE`, `MANUAL` y `SINCRONIZACION`. En `RESTAURACION` con sello `.acept` válido es la del sello (≤ `RecibidaUtc`); sin sello, el archivo es nuevo y es igual a `RecibidaUtc` |
| `Usuario` | `nvarchar(30)` | Sí | Quién cargó el archivo (null en el agente y en la reinserción) |

**Por qué se separa `AceptadaUtc` (precisión de `[DAT]` 6.3 y de CI-2):**
- `[DAT]` usaba `RecibidaUtc` como hora de aceptación. Pero en una reinserción `RESTAURACION` (LV-21, PA-42) la hora de inserción es la de la restauración.
- Con esa hora:
  - **NV-07** dejaría de dar la transición por RNC, porque `AceptadaUtc ≤ CambiadoUtc` sería falso;
  - **NV-02 en cadena** cortaría la lista, porque la aceptación de la reinsertada sería posterior a la de su sucesora (`CadenaOrdenada`, SEG-PR31-05). La empresa perdería el derecho previo y quedaría sin la gracia de transición a la que tenía derecho.
- El sello `.acept` ya guarda la hora de aceptación con MAC (`[LIC]` 3.5) [V]: basta con conservarla en su propia columna.

### 3.2 `dbo.LicenciaLlavesRetiradas`

Sin cambios respecto de `[DAT]` 6.3. En el lote 2 solo se escriben los orígenes `BINARIOS` y `AUTORIZACIONVENCIDA` (C-10).

### 3.3 Volumen y crecimiento

| Dato | Estimación [I] |
|---|---|
| Licencias aceptadas | De 12 a 26 al año (mensuales; semestrales con DL-14; reemisiones), a unos 4–8 KB cada una: **≈ 200 KB/año** |
| Rechazos normales | Pocos al año |
| Rechazos por abuso (cliente que inunda su propia base) | Importador a 20 por hora + L-03 a 10 por hora por cuenta. Con el tope de 50 completos al día, son 50 × 64 KB ≈ 3,2 MB/día más filas de unos 150 B: **≈ 1,2 GB/año en el peor caso sostenido** (riesgo R-1) |
| `Configuracion` (filas de la licencia) | < 20 KB sin el padrón; el padrón (DL-01) llega a unos 85 KB con 1 000 cuentas (`[BP2]` 2.3) |
| Costo de hosting | **USD 0**: SQL Server local del cliente, dentro del límite de 10 GB de Express. Ninguna base nueva |

---

## 4. Historial de cargas, «ya aceptado» y `Anteriores`

### 4.1 Qué se inserta y qué no

| Caso | Fila en `Licencias` |
|---|---|
| Aceptada nueva (`MANUAL`, `AGENTE`) | `A`, con `AceptadaUtc = RecibidaUtc` |
| Reinserción al arrancar (LV-21) con sello `.acept` válido | `A`, `Origen = 'RESTAURACION'`, `AceptadaUtc` del sello |
| Reinserción sin sello válido | Se trata como archivo nuevo: se aplican las reglas de hoy (INV-7) |
| Rechazo | `R`, con `Motivo`, `Sha256Contenido` si el JWS verificó y `Jws` mientras no se pase el tope de 50 al día |
| **Recarga idempotente** (misma `sec`, mismo contenido, nivel no superior) | **Ninguna fila.** El evento `LicenciaRecargada` va a la bitácora (DL-04). *Descartado:* un tercer valor `Resultado = 'I'`, porque cambia el contrato `CargaLicenciaDto.Resultado` y el historial no gana nada |
| **Mismo contenido con firma de nivel superior** (SEG-L2-24, con la versión que incorpora las llaves Avanzadas) | `A` nueva, con el mismo `Sha256Contenido`, su propio `Sha256Archivo` y `NivelFirma = 'avanzado'` |

### 4.2 `Anteriores` (`SituacionLicencia.Anteriores`, ≥ 24, en orden descendente de `sec`)

Hay una sola lectura acotada. L1a-4 la hace al arrancar y cuando cambia el `MAX(Id)` de `Licencias` (lo comprueba el refresco de 60 s), y la guarda en memoria:

```sql
-- @Cuantas = 32: la vigente, 24 anteriores y un margen de 7 por si las de mayor sec no verifican.
-- El literal 'A' tiene que ir en el texto, no como parámetro: si no, el optimizador no puede usar los índices filtrados.
DECLARE @Piso bigint = (SELECT MIN(s.Sec)
                          FROM (SELECT DISTINCT TOP (@Cuantas) Sec
                                  FROM dbo.Licencias WHERE Resultado = 'A' ORDER BY Sec DESC) s);
SELECT d.Id, d.Sec, d.Lid, d.Emitida, d.Kids, d.NivelFirma, d.Sha256Contenido, d.AceptadaUtc, d.ContenidoUnico, d.Jws
  FROM (SELECT l.Id, l.Sec, l.Lid, l.Emitida, l.Kids, l.NivelFirma, l.Sha256Contenido, l.Jws,
               MIN(l.AceptadaUtc) OVER (PARTITION BY l.Sec) AS AceptadaUtc,
               CASE WHEN MIN(l.Sha256Contenido) OVER (PARTITION BY l.Sec)
                       = MAX(l.Sha256Contenido) OVER (PARTITION BY l.Sec) THEN 1 ELSE 0 END AS ContenidoUnico,
               ROW_NUMBER() OVER (PARTITION BY l.Sec
                                  ORDER BY CASE l.NivelFirma WHEN 'avanzado' THEN 0 ELSE 1 END, l.Id) AS n
          FROM dbo.Licencias l
         WHERE l.Resultado = 'A' AND l.Sec >= @Piso) d
 WHERE d.n = 1
 ORDER BY d.Sec DESC;
```

**Reglas de L1a-4 sobre el resultado:**
1. **Una fila por `sec`.**
   - Si en una misma `sec` hay dos filas (caso SEG-L2-24), se toma el JWS de la de mayor nivel.
   - `AceptadaUtc` es la **mínima** de esa `sec`: el contenido rige desde la primera aceptación. Es lo correcto para NV-07 (`AceptadaUtc ≤ CambiadoUtc`) y para el orden de la cadena.
2. **`ContenidoUnico = 0`** (dos contenidos distintos con la misma `sec`, algo que solo puede pasar con una inserción manual) cuenta como «no verifica».
3. **Se vuelve a verificar cada JWS** (LV-20 e INV-7: firma e integridad, no caducidad ni retiro). `FirmaAvanzadaPropia` sale de esa verificación (`NivelFirmaLicencia.EsAvanzadaPropia` [V]), **no** de la columna `NivelFirma`, que es una caché.
4. **Vigente:** la primera de la lista que verifica (`[LIC]` 4.1.2).
5. **`Anteriores`:** las que siguen a la vigente, hasta 24. **Si una no verifica, la lista se corta ahí; nunca se la salta.** Saltarla abriría una transición que la intermedia ya había consumido (el escenario de SEG-PR31-05). El motor vuelve a comprobar el orden (`CadenaOrdenada`).
6. **Llaves retiradas:** no excluyen a una licencia de `Anteriores`. Es historial, y el retiro se evalúa al aceptar (INV-7) [I]. Si la llave ya no está en el recurso, el JWS no verifica y rige la regla 5, del lado restrictivo. Lo confirma el arquitecto-software (entrega).

**Plan de ejecución esperado** [I, por validar con el plan real en la suite]:
- `TOP DISTINCT`: una búsqueda descendente en `IX_Licencias_Sec` (filtrado y cubierto) que lee unas 32 filas;
- la consulta principal: una búsqueda por rango `Sec >= @Piso` sobre el mismo índice, sin ordenación adicional por `Sec`, más una búsqueda por clave para `Jws` en cada fila (≤ unas 40).
- Costo: < 1 ms y unos 32 × 8 KB ≈ 256 KB de lectura, solo cuando cambia el historial.

### 4.3 `sec` máxima efectiva (LV-05 e INV-6 con CV-06)

- Se toma el máximo de tres fuentes:
  - las filas `A` de la consulta 4.2 cuyo conjunto `Kids` no esté **todo** retirado (con una sola llave de la firma que siga vigente, la licencia cuenta);
  - la fila `Licencia.SecMax`;
  - el archivo `secmax`.
- `Sha256ContenidoSecMaxima` sale de la fuente que dio el máximo.
- **El cálculo se hace en memoria.** *Descartado:* resolverlo en SQL con `Kids` partido por comas, porque haría falta `STRING_SPLIT` y una búsqueda en `LicenciaLlavesRetiradas` en cada consulta, sin ninguna ganancia con menos de 40 filas.

### 4.4 «Ya aceptado» (INV-7, SEG-L2-18 y SEG-L2-24) y serialización de la aceptación

Toda la aceptación (leer la `sec` máxima, decidir e insertar) va en **una transacción con un bloqueo de aplicación**:

```sql
DECLARE @r int;
EXEC @r = sys.sp_getapplock @Resource = N'GPOS.Licencia.Aceptacion', @LockMode = N'Exclusive',
                            @LockOwner = N'Transaction', @LockTimeout = 10000;
IF @r < 0 THROW 51615, N'Otra carga de licencia está en curso; repita.', 1;
-- «ya aceptado»: nivel más alto registrado para ese contenido
SELECT TOP (1) NivelFirma, AceptadaUtc
  FROM dbo.Licencias
 WHERE Resultado = 'A' AND Sha256Contenido = @Sha256Contenido
 ORDER BY CASE NivelFirma WHEN 'avanzado' THEN 0 ELSE 1 END;
```

- **Regla:**
  - si no hay fila, siguen las reglas de L1a-2;
  - si hay una fila con nivel **≥** al del candidato, es una recarga idempotente, sin fila nueva;
  - si el candidato trae un nivel **superior** (SEG-L2-24, con la versión de las llaves Avanzadas), se procesa y se inserta una fila `A` nueva.
- Hoy, `ReglaSecuencia.MismaSec` solo compara el contenido (`ReglaSecuencia.cs` [V]). Para SEG-L2-24, `SituacionInstalacion` tendrá que recibir además el **nivel registrado** de ese contenido (entrega a L1a-2, en esa versión).
- **Respaldo declarativo:** `UX_Licencias_Aceptada` (sección 5) impide una segunda fila `A` del mismo contenido y del mismo nivel. Si aun así llega el error 2601 sobre ese índice, L1a-4 lo trata como «ya aceptado».
- **Por qué el bloqueo de aplicación:** L-03 y el importador pueden llegar a la vez. *Descartado:* `SERIALIZABLE` con `UPDLOCK` sobre el `TOP (1)` por `sec`, porque toma bloqueos de rango sobre un índice filtrado y es más difícil de razonar. `sp_getapplock` no exige permisos adicionales a `gpos_api` [I, documentado: basta con ser usuario de la base].
- **Tope de 50 rechazos completos al día (LV-15):** `SELECT COUNT(*) FROM dbo.Licencias WHERE Resultado = 'R' AND RecibidaUtc >= @InicioDiaUtc`, cubierto por `IX_Licencias_Rechazos`. El día es el día UTC de la hora protegida [I].
- **L-06 (SEG-L2-09):** `SecVigente`, `LidVigente` y `Sha256ContenidoVigente` salen de la vigente que L1a-4 guarda en memoria (4.2), sin otra consulta.
- **L-05 (historial, rango de 2 años como máximo):** `WHERE RecibidaUtc BETWEEN @desde AND @hasta ORDER BY Id DESC`. Con unos cientos de filas, el recorrido del índice agrupado basta; **no** se crea otro índice.

---

## 5. Índices y consultas que los justifican

| Índice | Definición | Consulta que lo usa | Costo de escritura |
|---|---|---|---|
| `PK_Licencias` | Agrupado sobre `Id` | Búsqueda de `Jws` por clave (4.2); L-05 por rango cronológico | Solo inserción al final |
| `IX_Licencias_Sec` | `(Sec DESC) INCLUDE (Lid, Emitida, Kids, Sha256Contenido, NivelFirma, AceptadaUtc) WHERE Resultado = 'A'` | `Anteriores` y vigente (4.2); `sec` máxima (4.3); `ReglaSecuencia.MismaSec` (busca la misma `sec`) | Una entrada por aceptación (unas 20 al año) |
| **`UX_Licencias_Aceptada`** | **`UNIQUE (Sha256Contenido, NivelFirma) WHERE Resultado = 'A'`** | «Ya aceptado» (4.4), con búsqueda por `Sha256Contenido` | Igual |
| `IX_Licencias_Rechazos` | `(RecibidaUtc) WHERE Resultado = 'R'` | Tope diario de LV-15 | Una entrada por rechazo |
| `UX_LicenciaLlavesRetiradas` | `UNIQUE (Kid, Origen, FuenteRef)` (`[DAT]`) | Retiros por `kid` (4.3, NV-08) e idempotencia de la derivación | — |

**`UX_Licencias_Aceptada` frente a SEG-L2-24:**
- Admite como máximo **dos** filas `A` por contenido (una `basico` y una `avanzado`), que es justo el caso de la cofirma a la que se le quitó `a1`.
- Hasta la versión con las llaves Avanzadas, todas las filas son `basico`, así que equivale a «único por `Sha256Contenido`».
- **No hará falta migrar el índice** cuando llegue esa versión.
- **Alternativas descartadas:**
  - **único solo sobre `Sha256Contenido`** (la forma de `[DAT]` corregida a contenido): con SEG-L2-24 obliga a borrar o a cambiar el índice, y la tabla es de solo inserción;
  - **sin índice único y la regla solo en la aplicación**: la integridad dependería del código y del bloqueo de aplicación, sin respaldo declarativo;
  - **un único adicional sobre (`Sec`, `NivelFirma`)** para impedir dos contenidos con la misma `sec`: la regla `SecDuplicada` ya lo impide y 4.2 detecta el caso (`ContenidoUnico`). Un índice más no aporta frente a un `sysadmin`, que puede borrarlo.
- **Requisito de las sesiones:** los índices filtrados exigen `ANSI_NULLS`, `QUOTED_IDENTIFIER` y las demás opciones en `ON` al insertar (error 1934). Microsoft.Data.SqlClient y `sqlcmd` las activan por omisión [I, documentado].

---

## 6. Restricciones e integridad

- **`CK_Licencias_Aceptada`:** una fila `A` tiene `Jws`, `Sec`, `Lid`, `Emitida`, `Kids`, `Sha256Contenido`, `NivelFirma` y `AceptadaUtc`, y `AceptadaUtc ≤ RecibidaUtc`.
- **`CK_Licencias_Rechazada`:** una fila `R` no tiene `AceptadaUtc` y sí tiene `Motivo`.
- **`CK_Licencias_Restauracion`:** fuera de `RESTAURACION`, `AceptadaUtc = RecibidaUtc`. **Solo una reinserción puede llevar una hora de aceptación anterior.**
- **`CK_Licencias_Tamano`** (64 KB), **`CK_Licencias_Kids`** (sin espacios ni comas sobrantes) y los dominios de `Origen`, `Resultado`, `NivelFirma`, `NivelMin` y `PerfilMin`.
- **Solo inserción:** `TR_Licencias_SoloInsercion` y `TR_LicenciaLlavesRetiradas_SoloInsercion` (`INSTEAD OF UPDATE, DELETE`, error 51612). Se recrean y se **habilitan** en cada aplicación de la DDL, como D81-06. Además van los `DENY` de la sección 9.
- **Lo que no protege la base:** un `sysadmin` puede deshabilitar los disparadores y borrar filas. El efecto es volver a una licencia anterior o a «sin licencia», y el arranque recupera la del disco (`[DAT]` 6.2; PA-42). Las filas de `Configuracion` las protege el MAC, no la base (PA-43).

---

## 7. Script de migración y reversión

### 7.1 `SqlLicenciaSistema.Ddl` (un solo lote, sin `GO`, idempotente)

```sql
/* SqlLicenciaSistema.Ddl · GPOS_SYSDATA · lote único, sin GO, idempotente.
   La aplican EsquemaSistema.ActualizarAsync (Amplio) y GPOS.Migracion sistema (Estricto), después de las tablas del sistema
   (necesita dbo.Usuarios y dbo.Configuracion) y antes de rptsis. No crea roles ni concede permisos (eso es SqlLicenciaSistema.Permisos).
   Errores 51613 a 51615: libres según [DAT] 2.7 (51600 a 51612 ya asignados); backend los confirma en el registro de errores. */
SET NOCOUNT ON;

-- 0. Guarda de forma: si alguna base de desarrollo tiene la forma de [DAT] 6.3 v2 (Sha256 del archivo), no se convierte en silencio.
IF OBJECT_ID(N'dbo.Licencias', N'U') IS NOT NULL AND COL_LENGTH(N'dbo.Licencias', N'Sha256Contenido') IS NULL
    THROW 51613, N'dbo.Licencias tiene la forma anterior (Sha256 del archivo, sin AceptadaUtc). En desarrollo: bórrela y repita.', 1;

-- 1. Licencias: cada archivo aceptado (A) o rechazado (R). Solo inserción (ADR-58, punto 8; [LIC] 3.5)
IF OBJECT_ID(N'dbo.Licencias', N'U') IS NULL
    CREATE TABLE dbo.Licencias (
        Id              bigint IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Licencias PRIMARY KEY CLUSTERED,
        Lid             uniqueidentifier NULL,
        Sec             bigint           NULL,
        Emitida         datetime2(3)     NULL,
        Kids            varchar(130)     NULL,            -- kid de las firmas que contaron, ordenados, separados por comas
        Jws             varbinary(max)   NULL,            -- NULL en un rechazo por encima del tope de 50 al día (LV-15)
        Sha256Contenido binary(32)       NULL,            -- identidad (SEG-L2-18): SHA-256 del payload decodificado
        Sha256Archivo   binary(32)       NULL,            -- informativo; NULL si el archivo supera 64 KB
        Origen          varchar(14)      NOT NULL CONSTRAINT CK_Licencias_Origen
                            CHECK (Origen IN ('AGENTE', 'MANUAL', 'SINCRONIZACION', 'RESTAURACION')),
        Resultado       char(1)          NOT NULL CONSTRAINT CK_Licencias_Resultado CHECK (Resultado IN ('A', 'R')),
        Motivo          varchar(60)      NULL,
        NivelFirma      varchar(9)       NULL CONSTRAINT CK_Licencias_Nivel     CHECK (NivelFirma IN ('basico', 'avanzado')),
        NivelMin        varchar(9)       NULL CONSTRAINT CK_Licencias_NivelMin  CHECK (NivelMin   IN ('basico', 'avanzado')),
        PerfilMin       varchar(9)       NULL CONSTRAINT CK_Licencias_PerfilMin CHECK (PerfilMin  IN ('basica', 'avanzada')),
        RecibidaUtc     datetime2(3)     NOT NULL,        -- hora protegida de la inserción
        AceptadaUtc     datetime2(3)     NULL,            -- hora de aceptación de INV-7 (en RESTAURACION, la del sello .acept)
        Usuario         nvarchar(30)     NULL,
        CONSTRAINT CK_Licencias_Tamano      CHECK (Jws IS NULL OR DATALENGTH(Jws) <= 65536),
        CONSTRAINT CK_Licencias_Kids        CHECK (Kids IS NULL OR (Kids NOT LIKE '% %' AND Kids NOT LIKE ',%' AND Kids NOT LIKE '%,' AND Kids NOT LIKE '%,,%')),
        CONSTRAINT CK_Licencias_Aceptada    CHECK (Resultado = 'R'
            OR (Jws IS NOT NULL AND Sec IS NOT NULL AND Lid IS NOT NULL AND Emitida IS NOT NULL AND Kids IS NOT NULL
                AND Sha256Contenido IS NOT NULL AND NivelFirma IS NOT NULL AND AceptadaUtc IS NOT NULL AND AceptadaUtc <= RecibidaUtc)),
        CONSTRAINT CK_Licencias_Rechazada   CHECK (Resultado = 'A' OR (AceptadaUtc IS NULL AND Motivo IS NOT NULL)),
        CONSTRAINT CK_Licencias_Restauracion CHECK (Origen = 'RESTAURACION' OR AceptadaUtc IS NULL OR AceptadaUtc = RecibidaUtc));

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Licencias') AND name = N'IX_Licencias_Sec')
    EXEC (N'CREATE INDEX IX_Licencias_Sec ON dbo.Licencias (Sec DESC)
            INCLUDE (Lid, Emitida, Kids, Sha256Contenido, NivelFirma, AceptadaUtc) WHERE Resultado = ''A''');
-- «Ya aceptado» compatible con SEG-L2-24: como máximo una fila aceptada por (contenido, nivel)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Licencias') AND name = N'UX_Licencias_Aceptada')
    EXEC (N'CREATE UNIQUE INDEX UX_Licencias_Aceptada ON dbo.Licencias (Sha256Contenido, NivelFirma) WHERE Resultado = ''A''');
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Licencias') AND name = N'IX_Licencias_Rechazos')
    EXEC (N'CREATE INDEX IX_Licencias_Rechazos ON dbo.Licencias (RecibidaUtc) WHERE Resultado = ''R''');

-- 2. Llaves retiradas (LV-14; CV-08): sin cambios respecto de [DAT] 6.3
IF OBJECT_ID(N'dbo.LicenciaLlavesRetiradas', N'U') IS NULL
    CREATE TABLE dbo.LicenciaLlavesRetiradas (
        Id                int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_LicenciaLlavesRetiradas PRIMARY KEY,
        Kid               varchar(40)  NOT NULL,
        Origen            varchar(20)  NOT NULL CONSTRAINT CK_LicenciaLlavesRetiradas_Origen
                              CHECK (Origen IN ('BINARIOS', 'MANIFIESTO', 'AUTORIZACIONVENCIDA')),
        FuenteRef         varchar(100) NOT NULL,
        PublicadoUtc      datetime2(3) NULL,
        RetiroEfectivoUtc datetime2(3) NOT NULL,
        RegistradoUtc     datetime2(3) NOT NULL,
        CONSTRAINT UX_LicenciaLlavesRetiradas UNIQUE (Kid, Origen, FuenteRef));

-- 3. Solo inserción también frente a un error de la aplicación o de un db_owner (no frente a un sysadmin). Se recrean y se habilitan siempre (D81-06).
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_Licencias_SoloInsercion ON dbo.Licencias INSTEAD OF UPDATE, DELETE AS
BEGIN SET NOCOUNT ON; THROW 51612, N''dbo.Licencias es de solo inserción (ADR-58, punto 8).'', 1; END;');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_LicenciaLlavesRetiradas_SoloInsercion ON dbo.LicenciaLlavesRetiradas INSTEAD OF UPDATE, DELETE AS
BEGIN SET NOCOUNT ON; THROW 51612, N''dbo.LicenciaLlavesRetiradas es de solo inserción (ADR-58, punto 8).'', 1; END;');
EXEC (N'ENABLE TRIGGER dbo.TR_Licencias_SoloInsercion ON dbo.Licencias;
        ENABLE TRIGGER dbo.TR_LicenciaLlavesRetiradas_SoloInsercion ON dbo.LicenciaLlavesRetiradas;');

-- 4. Sello de habilitación ([DAT] 6.3). varbinary(512): con DL-05 (huella del PasswordHash y FactorAlta) el Protect ronda 380 bytes [I]
IF COL_LENGTH(N'dbo.Usuarios', N'SelloHabilitacion') IS NULL
    ALTER TABLE dbo.Usuarios ADD SelloHabilitacion varbinary(512) NULL;
ELSE IF COL_LENGTH(N'dbo.Usuarios', N'SelloHabilitacion') < 512
    ALTER TABLE dbo.Usuarios ALTER COLUMN SelloHabilitacion varbinary(512) NULL;
```

**Datos existentes:** ninguna de estas tablas existe en ninguna instalación (BP2 nunca salió a producción y L1 no está construido [V]).
- `ALTER TABLE … ADD` de una columna nula es un cambio solo de metadatos.
- Ampliar un `varbinary` también lo es (`ALTER COLUMN` a un ancho mayor) [I, documentado].
- La fila `UsuariosAutorizados` sigue hasta L1b (LV-17).

**Bloqueos:**
- `Sch-M` breve sobre `dbo.Usuarios` en el `ALTER`, de milisegundos con pocos miles de filas.
- En Estricto, `GPOS.Migracion sistema` se ejecuta con la API detenida (M-4). En Amplio, al arrancar la API, antes de atender peticiones.

### 7.2 Reversión

- **Instalación con licencias reales:** **no se revierte el dato.** Las tablas son el registro de la licencia (ADR-58, punto 8). La reversión es volver a los binarios anteriores; las tablas quedan sin uso y no estorban, porque todo es aditivo.
- **Solo en desarrollo o pruebas (Amplio), antes de cualquier licencia real:**

```sql
-- Reversión de desarrollo. NO borra Licencia.InstalacionId (es la identidad de la instalación) ni el padrón (DL-01, de SL).
IF OBJECT_ID(N'dbo.Licencias', N'U') IS NOT NULL                DROP TABLE dbo.Licencias;               -- arrastra sus disparadores e índices
IF OBJECT_ID(N'dbo.LicenciaLlavesRetiradas', N'U') IS NOT NULL  DROP TABLE dbo.LicenciaLlavesRetiradas;
DELETE dbo.Configuracion
 WHERE Clave IN (N'Licencia.Gracias', N'Licencia.SecMax', N'Licencia.PisoNivelFirma', N'Licencia.RegresosNivel')
    OR Clave LIKE N'Licencia.CambiosRnc:%';
-- La columna SelloHabilitacion se conserva: la quita SL con su propia reversión si hace falta.
```

- El disco (`%ProgramData%\GPOS NG\Licencia\`) se limpia aparte. Si no se limpia, al arrancar la API vuelve a insertar desde `Procesados` lo que tenga sello (LV-21).

### 7.3 Agregar a S4 (`GPOS.Migracion verificar`, en `GPOS_SYSDATA`)

```sql
-- Disparadores de solo inserción ausentes o deshabilitados
INSERT @h SELECT 'LICENCIA_DISPARADOR', v.Nombre, N'Disparador de solo inserción ausente o deshabilitado'
  FROM (VALUES (N'TR_Licencias_SoloInsercion'), (N'TR_LicenciaLlavesRetiradas_SoloInsercion')) v(Nombre)
 WHERE NOT EXISTS (SELECT 1 FROM sys.triggers t
                    WHERE t.name COLLATE CATALOG_DEFAULT = v.Nombre COLLATE CATALOG_DEFAULT AND t.is_disabled = 0);
-- DENY de la sección 9 ausentes
INSERT @h SELECT 'LICENCIA_SIN_DENY', o.Objeto + N': ' + p.Permiso, N'Falta el DENY a gpos_api'
  FROM (VALUES (N'dbo.Licencias'), (N'dbo.LicenciaLlavesRetiradas')) o(Objeto)
  CROSS JOIN (VALUES (N'UPDATE'), (N'DELETE'), (N'ALTER')) p(Permiso)
 WHERE DATABASE_PRINCIPAL_ID(N'gpos_api') IS NOT NULL AND OBJECT_ID(o.Objeto) IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.database_permissions d
                    WHERE d.class = 1 AND d.major_id = OBJECT_ID(o.Objeto) AND d.state = 'D'
                      AND d.grantee_principal_id = DATABASE_PRINCIPAL_ID(N'gpos_api')
                      AND d.permission_name COLLATE CATALOG_DEFAULT = p.Permiso COLLATE CATALOG_DEFAULT);
-- Crecimiento anómalo del historial (R-1): más de 200 MB
INSERT @h SELECT 'LICENCIA_HISTORIAL_GRANDE', N'dbo.Licencias', N'Más de 200 MB; revise rechazos repetidos'
 WHERE (SELECT SUM(a.used_pages) * 8 / 1024 FROM sys.partitions p JOIN sys.allocation_units a ON a.container_id = p.partition_id
         WHERE p.object_id = OBJECT_ID(N'dbo.Licencias')) > 200;
```

---

## 8. Respaldo, restauración y retención

- **Respaldo:** las tablas viajan en el `.bak` de `GPOS_SYSDATA` (Backup Tool, `usp_RespaldoCopia`). Las filas protegidas solo se leen con el anillo del equipo de la API: en otro equipo no verifican. Es lo esperado, porque la licencia está atada a la instalación.
- **Restauración de `GPOS_SYSDATA`:**
  - LV-21 vuelve a insertar la licencia de mayor `sec` desde el disco, con `AceptadaUtc` del sello.
  - `recovery_fork_guid` cambia, lo que abre la gracia de entorno según la huella (`[DAT]` 6.3).
  - Las marcas del disco no se restauran con la base, y rige la más antigua (QA-L13).
- **Retención:**
  - `Licencias` y `LicenciaLlavesRetiradas` **no se purgan**: el volumen normal es mínimo (3.3).
  - Si R-1 se materializa, la remediación es un disparador de purga como el de `BitacoraSeguridad`, que permita borrar filas `R` de más de un año. Hoy no se construye (C13.5).
- **Configuración:** las filas se sobrescriben en su sitio, sin historial. Los cambios quedan en la bitácora (DL-04).

---

## 9. Privilegios de base de datos (RG-14)

```sql
/* SqlLicenciaSistema.Permisos · solo GPOS.Migracion sistema, después de S1 de [DAT] 2.7 (C-11). Idempotente. */
IF DATABASE_PRINCIPAL_ID(N'gpos_api') IS NULL
    THROW 51614, N'RG-14: falta el rol gpos_api; ejecute antes S1.', 1;
-- La API inserta y lee (GRANT SELECT, INSERT ON SCHEMA::dbo de S1); nunca cambia ni borra, ni deshabilita los disparadores (exige ALTER)
DENY UPDATE, DELETE, ALTER ON OBJECT::dbo.Licencias TO gpos_api;
DENY UPDATE, DELETE, ALTER ON OBJECT::dbo.LicenciaLlavesRetiradas TO gpos_api;
```

| Identidad | `Licencias` y `LicenciaLlavesRetiradas` | `Configuracion` (filas con MAC) | `Usuarios.SelloHabilitacion` |
|---|---|---|---|
| `gpos_sistema` (rol `gpos_api`) | `SELECT` e `INSERT`; `DENY UPDATE, DELETE, ALTER` | `SELECT`, `INSERT`, `UPDATE` y `DELETE` (S1). La integridad la da el MAC, no el permiso | `SELECT` y `UPDATE` (S1) |
| `gpos_rpt_sis` (API de reportes) | Ninguno: solo lee `rptsis`, que no expone estas tablas | Ninguno | Ninguno |
| `gpos_respaldo_srv` | `db_backupoperator` (sin lectura de datos) | — | — |
| Técnico con `GPOS.Migracion` | Administrativa (D-09) | Administrativa | Administrativa |

- **`ALTER` agregado al `DENY` de `[DAT]`:** deshabilitar un disparador exige `ALTER` sobre la tabla. S1 no lo concede, pero el `DENY` explícito impide que un `GRANT` posterior por error lo abra. Es el mismo criterio que el bloque A de `[C81]` con `BitacoraSeguridad`.
- **Sin datos sensibles en claro:** RNC, usuario, marcas y topes van dentro de `Protect`. En las tablas solo hay datos firmados por GSF (el JWS, que el `sysadmin` puede leer, `[DAT]` 6.2) y huellas SHA-256. No hay secretos ni cadenas de conexión.

---

## 10. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | Un cliente inunda su propia base con rechazos (≈ 1,2 GB/año en el peor caso) frente al límite de 10 GB de Express | Baja / Medio | Topes de 20 por hora y 10 por hora por cuenta y LV-15; S4 avisa a partir de 200 MB (7.3); purga de filas `R` si llega a hacer falta (8) |
| R-2 | Un `INSERT` desde una sesión con `QUOTED_IDENTIFIER OFF` falla por los índices filtrados (1934) | Baja / Bajo | Las conexiones de la API y de `GPOS.Migracion` usan SqlClient con las opciones por omisión; lo cubre una prueba de integración de la carga |
| R-3 | La DDL se aplica sobre una base de desarrollo con la forma de `[DAT]` v2 | Muy baja / Bajo | Guarda 51613 (7.1); hoy no existe en ninguna rama [V] |
| R-4 | Alguien mapea `Licencias` en `SistemaDbContext` y `EnsureCreated` la crea con otra forma | Baja / Alto | Prueba de arquitectura (1.3) |
| R-5 | Un código de empresa de más de 30 caracteres desborda la clave `Licencia.CambiosRnc:` | Muy baja / Bajo | Comprobación en el código que escribe la fila; plan con el SHA-256 del código (2.3) |
| R-6 | El disco (`estado`, `secmax`, `.acept`) y la base divergen | Media / Bajo | Regla de la más restrictiva o de la mayor `sec` que verifica; evento si la diferencia de `UltimaVerificacionUtc` supera 15 minutos |
| R-7 | La recarga idempotente no deja fila: si DL-04 no se firma, el intento no queda en ningún sitio | Media / Bajo | Registro de la API (Serilog) mientras tanto; con DL-04, el evento `LicenciaRecargada` |
| R-8 | La cadencia de 15 minutos de `UltimaVerificacionUtc` acorta la gracia `Ilegible` | Cierta / Muy bajo | Va del lado restrictivo; como máximo 15 minutos sobre 72 h |

---

## 11. Lo que depende de firmas pendientes

| Parte | Depende de | ¿Se construye ya? |
|---|---|---|
| `dbo.Licencias` con la forma nueva, `IX_Licencias_Sec`, `IX_Licencias_Rechazos`, disparadores, `LicenciaLlavesRetiradas` | L-01 y `[DAT]` 6.3 (firmados); SEG-L2-18 (aceptado en `[BP2]` v2) | **Sí** |
| `UX_Licencias_Aceptada` sobre (`Sha256Contenido`, `NivelFirma`) | SEG-L2-24 (aceptado en v2.1). La **regla** de la segunda fila depende de **DL-11** (pendiente) y de la versión con las llaves Avanzadas | **Sí, el índice.** La regla, con esa versión |
| Filas `Licencia.Gracias`, `SecMax`, `PisoNivelFirma`, `RegresosNivel` e `InstalacionId`; archivos `estado`, `secmax`, `pisonivel` y `.acept` | Firmado (L-01, [PSF] 4A.5 y 4A.6, C-08) | **Sí** |
| `Usuarios.SelloHabilitacion varbinary(512)` | `[DAT]` 6.3 (firmado). El tamaño contempla **DL-05** (pendiente); sin DL-05 también sirve | **Sí** |
| `Licencia.PadronSellos` | **DL-01** (pendiente). Sin DDL: es una fila de `Configuracion` con el formato de SL | Formato y código: tras DL-01. L1a-4 solo crea la carpeta donde SL escribe `padron` |
| `Licencia.CambiosRnc:<empresa>` | **DL-03** (pendiente). Sin DDL | **El lector, sí** (L1a-4: sin fila, null, sin transición, falla cerrada). El escritor (S-03 y `--cambiar-rnc`), tras DL-03 |
| La bitácora como tercera fuente de las marcas de inicio; los eventos `LicenciaRecargada`, `CambioRncSuper`, etc. | **DL-04** (pendiente). DDL: el bloque A de `[C81]` §7.2, **sin cambios** (`Evento varchar(40)` no tiene una lista cerrada [V]) | La interfaz `IBitacoraSeguridad`, sí. Mientras no se firme, las marcas salen de la base y del disco, que ya protegen frente a un `sysadmin` de SQL sin acceso al disco |
| Tope de 200 días (rechazo `LICENCIA_VIGENCIA_BASICA`) | **DL-14** (pendiente) | Sin efecto en los datos: el código cabe en `Motivo varchar(60)` |
| Mínimo de la transición al acortar un `vence` | **DL-15** (pendiente) | Sin efecto en los datos: el formato de `Gracias` no cambia (se guarda `TopeGraciaUtc` tal cual con cualquier variante) |
| `Licencia.SelloInicial` y cuentas iniciales desde `GPOS.Migracion` | **DL-02** (pendiente) | Formato, sí; quién lo escribe, tras DL-02 |

**Conclusión:** toda la DDL de 7.1 y 9 se puede construir **ya**. Ninguna firma pendiente cambia una columna ni un índice. Las firmas pendientes solo deciden **quién escribe** algunas filas de `Configuracion` y si la bitácora es una tercera fuente.

---

## Estimación

| Pieza | Esfuerzo [I] |
|---|---|
| Este diseño y la revisión del código de L1a-4 (datos) | 0,3 dp |
| Impacto en L1a-4 frente a `[DAT]` 6.3: `AceptadaUtc` del sello, consulta deduplicada por `sec`, `Kids`, SHA-256 en `SecMax`, bloqueo de aplicación | +0,15 dp, dentro de los 2,85 dp de L1a-4 (margen de L ≈ 0,6 dp, hoja v2.2) |
| Comentarios XML del motor (2.4) | 0,02 dp |
| Costo de infraestructura | USD 0 (sin bases ni servicios nuevos) |

---

## Supuestos

- `Protect` con el propósito `GPOS.Licencia.Estado.v1` (`[DAT]` 6.3). Hasta H-17 v2 se usa el anillo actual; las filas se reprotegen cuando llegue (`[DAT]` 6.6).
- El tamaño del sello con DL-05 (unos 380 bytes) es una estimación a partir de la sobrecarga de Data Protection (unos 84 bytes) y un JSON de unos 300 bytes.
- El comportamiento de `System.Text.Json` con claves duplicadas no lo verifiqué. Por eso uso un arreglo.
- `sp_getapplock` sin permisos adicionales, el `ALTER COLUMN` de `varbinary` solo de metadatos y las opciones `SET` de SqlClient: comportamiento documentado de SQL Server, no probado en la PC A.
- Las llaves retiradas no excluyen una licencia de `Anteriores` (4.2, regla 6): es mi lectura de INV-7.
- El «día» del tope de rechazos es el día UTC de la hora protegida.
- El SUPER es siempre de la plataforma.
- No compilé ni ejecuté nada.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\datos-licencia-l1a4-2026-10-14.md`
- Supuestos: los de la sección «Supuestos».
- Decisiones candidatas a ADR:
  - **Precisión de `[DAT]` 6.3 y CI-2 (ADR-58, punto 8; INV-7).**
    - `AceptadaUtc` es una columna propia, conservada del sello en `RESTAURACION`. *Descartado:* usar `RecibidaUtc`, porque rompe NV-02 en cadena y NV-07 después de una restauración.
    - Identidad (`Sha256Contenido`, `NivelFirma`) con un índice único filtrado compatible con SEG-L2-24. *Descartados:* único solo por contenido, y solo la regla en la aplicación.
    - La recarga idempotente no deja fila. *Descartado:* `Resultado = 'I'`.
    - Lo registra el arquitecto-maestro en ADR-83 o en la hoja.
  - **Esquema `dbo` y no `Licencia`** (1.2). Se mantiene lo firmado.
- Entregas a otros agentes:
  - **desarrollador-backend (L, L1a-4):**
    - DDL 7.1 en `SqlLicenciaSistema.Ddl`, sin mapear en EF;
    - consultas 4.2 a 4.4 con el literal `'A'`;
    - JSON de 2.2, 2.3 y 2.5;
    - cadencia de 15 minutos de `Gracias`;
    - sellos `.acept` con el SHA-256 del contenido y el nivel;
    - corregir los dos comentarios de `EstadosLicencia.cs` (2.4) en `a/lic-l1a-3` o en L1a-4.
  - **desarrollador-backend (L, L1a-2):** con la versión de las llaves Avanzadas, `SituacionInstalacion` recibe el nivel registrado del contenido (SEG-L2-24). Corregir `LicenciaSecMax` → `Licencia.SecMax` en el comentario.
  - **desarrollador-backend (I, `GPOS.Migracion sistema` y SL):**
    - el orden de 1.3;
    - `SqlLicenciaSistema.Permisos` después de S1;
    - la ampliación del sello a `varbinary(512)`;
    - S4 de 7.3.
  - **desarrollador-backend (I, RN):** el formato de `Licencia.CambiosRnc:<empresa>` (2.3) y el bloqueo de aplicación, cuando se firme DL-03.
  - **arquitecto-software:** confirmar la regla 6 de 4.2 (las llaves retiradas no excluyen de `Anteriores`) y que la bitácora no es fuente de `UltimaVerificacionUtc` (2.6).
  - **qa-automatizado:**
    - PA-42 ampliada: después de la reinserción, la `AceptadaUtc` es la del sello y la cadena sigue en orden;
    - prueba de SEG-L2-24 contra `UX_Licencias_Aceptada`;
    - fila `Gracias` con un código duplicado → no verifica;
    - `Kids` con cofirma.
  - **arquitecto-maestro:** registrar las precisiones; DL-01, DL-03, DL-04, DL-11, DL-14 y DL-15 siguen en la hoja v2.2.
- Próximo paso recomendado: que el desarrollador L arranque L1a-4 en Amplio con la DDL 7.1, que no depende de ninguna firma pendiente, y que el desarrollador I enganche `SqlLicenciaSistema` en `GPOS.Migracion sistema` antes del 2026-11-13.
