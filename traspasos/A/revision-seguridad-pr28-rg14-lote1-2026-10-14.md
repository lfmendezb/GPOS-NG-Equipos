# [Informe de Seguridad] PR #28: RG-14, lote 1 (identidades SQL y privilegio mínimo)

- **Fecha:** 2026-10-14
- **Auditor:** auditor-seguridad (Opus 5.5)
- **PR:** `lfmendezb/GPOS-NG` #28, rama `a/rg14-lote1` @ `4d10ecaf`, base `feature/modelo-ng` @ `ad6015d7`
- **Contrato:** `datos-t3-12-rg14-2026-10-14.md`, sección 5 (D-01 a D-11 firmadas; D-04 (i) y (iii) firmadas; (ii) sin firma)
- **Método:** lectura de `git diff ad6015d7..4d10ecaf` y del árbol `GPOS-NG-rg14` en `4d10ecaf`, sin editar, sin compilar y sin ejecutar pruebas (pedido expreso: otra suite podía estar corriendo). Todo lo marcado [V] se verificó en el código; [I] es inferido y requiere confirmación.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Migración de empresa `Rg14PrivilegioMinimo` (S2 y S3) y su guion idempotente | `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesRg14.cs`, `20261014172843_Rg14PrivilegioMinimo.cs`, `PermisosLecturaReportes.cs`, `SqlMigracionesOla5.cs`, `database/empresa/gpos-empresa-20261014172843_Rg14PrivilegioMinimo.sql` |
| GPOS_SYSDATA (T3-08 y T3-12 de `gpos_rpt_sis`) | `src/GPOS.Core/Infraestructura/Motor/PrivilegioMinimoSistema.cs`, `src/GPOS.Core/Data/Sistema/EsquemaSistema.cs`, `src/GPOS.Migracion/Lectura/CredencialesLectura.cs` |
| `GPOS.Migracion verificar` (S4) | `src/GPOS.Migracion/VerificacionPrivilegios.cs`, `Program.cs`, `Aprovisionamiento.cs` |
| Autoverificación S5 y modo de identidad | `src/GPOS.Core/Infraestructura/Motor/AutoverificacionIdentidad.cs`, `src/GPOS.Api/Seguridad/IdentidadSql.cs`, `VersionEsquemaEmpresa.cs`, `Program.cs` |
| Endpoint expuesto | `GET /api/super/identidad-sql` (`src/GPOS.Api/Endpoints/AdminEndpoints.cs:288`) |
| UI | `IdentidadSqlDiagnostico.razor` (Web y MAUI), `VistaIdentidadSql.cs`, `ApiClient.IdentidadSql.cs` |
| Configuración y DEMO | `src/GPOS.Api/appsettings.Development.json`, `instalador/Demo/scripts/herramientas/Comun-Demo.ps1`, `Actualizar-Demo.ps1` |
| Pruebas | `tests/GPOS.Tests/ModeloNg/Rg14PrivilegioMinimoTests.cs`, `Rg14VerificarTests.cs`, `ModoIdentidadPruebas.cs`, `tests/GPOS.Web.Tests/IdentidadSqlDiagnosticoTests.cs` |

Endpoints anónimos nuevos: ninguno. Endpoints administrativos nuevos: uno (solo SUPER, solo lectura). Tareas en segundo plano nuevas: ninguna (la autoverificación corre al arrancar y en la primera petición de cada empresa).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SEG-RG14-01 | **Media** | El control compensatorio de D-11 no existe: O-2 pierde la cobertura de objeto en todos los esquemas ya existentes (también `rpt`, `rptc` e `imp`, más allá del texto de D-11) y S4 no lee los `GRANT` de esquema ni de objeto de los roles de lectura |
| SEG-RG14-02 | Baja | El modo Amplio no está impedido técnicamente en la versión publicada (hoy solo cambia el registro; el bloqueo es de DL-02 / SEG-L2-05 en el lote 2) |
| SEG-RG14-03 | Baja | S4 puede dar «conforme» falso si quien ejecuta `verificar` no ve todo el catálogo |
| SEG-RG14-04 | Baja | Huecos de detección en S4/S5: `IMPERSONATE` sobre usuarios, `GRANT` de esquema a `gpos_app`, `DELETE` en `SobresAbiertos`, y los `DENY` nuevos de `gpos_app` no se comprueban |
| SEG-RG14-05 | Baja | `conf.usp_RespaldoCopia` sin límite de frecuencia: con la credencial de la aplicación se puede llenar el disco de respaldos |
| SEG-RG14-06 | Baja | PA-47: la clave del login temporal va interpolada en el texto SQL, con `CHECK_POLICY = OFF` y sin barrido de logins huérfanos si el proceso muere |
| SEG-RG14-07 | Baja | «Nunca lanza» no se cumple: una excepción fuera de las tres capturadas detiene el arranque de la API |
| SEG-RG14-08 | Baja | `VIEW DEFINITION` negado por esquema no cubre los objetos de ámbito de base (usuarios, roles, certificados) ante un `GRANT VIEW DEFINITION TO public` |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Evidencia |
|---|---|---|
| A01 Control de acceso | Conforme | Endpoint con `RequiereSuper()` (`AdminEndpoints.cs:288`; política `Seguridad.cs:178-179`, claim de nivel SUPER). Prueba del 403 al ADMIN (`Rg14VerificarTests.cs`, `PA25_…`). La UI no consulta si no es SUPER. Privilegio mínimo SQL: ver SEG-RG14-01 y 04 |
| A02 Fallas criptográficas | No aplica | El lote no cifra ni descifra nada nuevo; `GPOS.Migracion` reutiliza el anillo existente |
| A03 Inyección | Conforme | SQL dinámico solo con nombres de `sys.schemas` entre `QUOTENAME` (`PermisosLecturaReportes.cs:88`, `PrivilegioMinimoSistema.cs`); S4 y S5 son constantes sin entrada; la etiqueta de `usp_RespaldoCopia` se valida con `[A-Z0-9_]` en BIN2 y `BACKUP` usa variables, no texto concatenado; la cadena de `verificar` se arma con `SqlConnectionStringBuilder` (`EmpresasSistema.cs:79-89`). En pruebas, nombres generados con `Guid` (ver SEG-RG14-06) |
| A04 Diseño inseguro | Observación | SEG-RG14-01 (control compensatorio de una decisión firmada que no se construyó) |
| A05 Configuración | Observación | Amplio por configuración (SEG-RG14-02). `appsettings.Development.json` no se publica (`GPOS.Api.csproj:35`, `CopyToPublishDirectory="Never"`; `Publicar-PaqueteDemo.ps1:96-97` lo rechaza) [V] |
| A06 Componentes vulnerables | No aplica | El PR no agrega ni actualiza paquetes. No se ejecutó `dotnet list package --vulnerable` (no se permitió compilar) |
| A07 Autenticación | No aplica | Sin cambios en autenticación |
| A08 Integridad | Conforme | `DENY INSERT, UPDATE, DELETE` sobre `conf.__EFMigrationsHistory` a `gpos_app` (H-RG14-06) |
| A09 Registro y monitoreo | Conforme con observación | Eventos 5130 a 5132 sin cadena de conexión ni mensaje del motor (`IdentidadSql.cs:120-125`); el registro nombra base, columnas y usuario de base, como pide S5. SEG-RG14-07 |
| A10 SSRF | No aplica | `verificar` conecta a los servidores registrados en GPOS_SYSDATA con la identidad del técnico; no hay URL controlada por un usuario de la aplicación |

Puntos específicos del encargo:

| Punto | Resultado |
|---|---|
| DENY/GRANT imponen privilegio mínimo | Sí en lo que cubren (S2 y S3 coinciden con el contrato; la desviación H-03 es correcta, ver §5). Ver SEG-RG14-01 y 04 |
| `Down` no deja permisos de más ni quita necesarios | Conforme [V]: antes de esta migración `gpos_app` no tenía `DENY` de nivel de base ni permisos sobre `__EFMigrationsHistory` (`SqlMigraciones.cs:30-47`, `SqlMigracionesMae.cs:79-91`), así que el `REVOKE` vuelve exactamente al estado anterior; no revoca el `GRANT … ON SCHEMA::dbo` de `Mae` ni el `DENY` de `dbo._LOG`; los `DENY` que `SqlOla5` reaplica en el `Up` (más restrictivos) se conservan. El `Down` de GPOS_SYSDATA no existe por diseño (S6, manual) |
| QUOTENAME y SQL dinámico | Conforme (A03) |
| Autorización y fugas del endpoint | Conforme: el DTO no lleva cadena ni secreto; el error solo lleva el número (`IdentidadSql.cs:120-125`); la prueba comprueba que el catálogo no aparece en el evento |
| Amplio en Release/producción | SEG-RG14-02 |
| Secretos en configuración, DEMO y pruebas | Sin secretos nuevos: `appsettings.Development.json` usa seguridad integrada; `Comun-Demo.ps1` solo agrega la clave de modo. PA-47: SEG-RG14-06 |
| Aislamiento entre empresas | Conforme: la instantánea agrupa por código de empresa y solo la ve el SUPER (de la plataforma); el ADMIN de una empresa recibe 403. No hay datos de negocio en la respuesta |

## 4. Hallazgos

### SEG-RG14-01 · Media · El control compensatorio de D-11 no existe

**Riesgo.** D-11 (firmada) autoriza el plan de reserva: `DENY VIEW DEFINITION` por esquema «a todo esquema que no sea de vistas», y dice que la cobertura de objeto que O-2 pierde «se completa con `GPOS.Migracion verificar` (S4), que lee `sys.database_permissions` como administrador» (`datos-t3-12-rg14-2026-10-14.md`, 2.3).
- La implementación niega `VIEW DEFINITION` en **todos** los esquemas de usuario, incluidos `rpt`, `rptc` e `imp` (`PermisosLecturaReportes.cs:84-91`). El propio comentario reconoce que O-2 solo ve los `GRANT` sueltos en esquemas creados después (`:81`), y la prueba PA-14 solo cubre ese caso (esquema nuevo).
- La consulta O-2 recorre `sys.objects` (`src/GPOS.Reportes/Ejecucion/PreparadorSesion.cs:62-64`); con la definición negada, los objetos de esos esquemas dejan de verse [I, coherente con R-RG14-04 comprobado por el equipo].
- S4 **no** lee los permisos de clase 1 (objeto) ni de clase 3 (esquema) concedidos a `gpos_reportes`, `gpos_lectura` ni `gpos_rpt_sis`: solo `PERMISO_ADMIN` de clase 0 y la presencia de `DENY` (`VerificacionPrivilegios.cs:53-80`) [V]. El texto S4 del diseño tampoco los incluye: la inconsistencia viene del diseño y el código la hereda.

**Impacto real.** Acotado: la escritura, la ejecución y `ALTER` ya están negadas por esquema (`SqlOla5`, `PermisosLecturaReportes.cs:58-70`), y un `DENY` de esquema prevalece sobre un `GRANT` de objeto. Lo que queda sin detección es lo que esos `DENY` no cubren (`TAKE OWNERSHIP`, `CONTROL` y `REFERENCES` de objeto, y cualquier `GRANT` de esquema que un administrador agregue por error); el efecto de un cambio de dueño sobre los `DENY` de esquema no se verificó [I]. Es un hueco de detección en un control declarado como compensatorio, no una escritura abierta hoy.

**Remediación** (≈ 0,25 días-persona):
1. Agregar a `SqlBase` una condición `GRANT_ROL_LECTURA`: toda fila de `sys.database_permissions` con `state IN ('G','W')`, `class IN (1, 3)`, beneficiario `gpos_reportes`, `gpos_lectura` o `gpos_rpt_sis`, y permiso distinto de `SELECT` (y `SELECT` fuera de `rpt`/`rptc`/`imp`/`rptsis`).
2. Decidir con el arquitecto de datos si `rpt`, `rptc` e `imp` llevan el `DENY VIEW DEFINITION` (texto de D-11: no) o si se mantiene la ampliación con 1. como compensación. Si se mantiene, documentarla como desviación en el PR.
3. Una prueba que conceda `TAKE OWNERSHIP` sobre una vista de `rpt` y espere el hallazgo en S4.

### SEG-RG14-02 · Baja · Amplio no está impedido en la versión publicada

**Riesgo.** El modo se lee solo de la configuración (`IdentidadSql.cs` constructor; clave `GPOS:Seguridad:ModoIdentidad`). Nada impide fijar `Amplio` en una instalación de cliente. En Amplio, la falla de identidad deja de ser el evento crítico 5131 y pasa a Information (`IdentidadSql.cs:135`), aunque queda el 5130 crítico en cada arranque.
**Por qué es Baja hoy.** En el lote 1 el modo no cambia ningún comportamiento salvo el registro [V: `EsAmplio` solo se usa en `IdentidadSql.cs` y en la vista]; Estricto tampoco rechaza nada (D-01). `appsettings.Development.json` (`:7`) no se publica [V].
**Remediación.** En el lote 2, aplicar DL-02 / SEG-L2-05 tal como están firmadas: en Release, ningún modo crea ni sella cuentas, y con una licencia `Produccion` o `Beta` la API no arranca en Amplio (`ArranqueAmplioBloqueado`). Agregar «`GPOS__Seguridad__ModoIdentidad` ausente o `Estricto`» a la lista de PUB-06 y una comprobación del paquete publicado (como la de `Publicar-PaqueteDemo.ps1:96-97`). ≈ 0,1 días-persona más de lo ya presupuestado.

### SEG-RG14-03 · Baja · «Conforme» falso con una identidad sin visibilidad

**Riesgo.** S4 interpreta el resultado vacío como conforme (`VerificacionPrivilegios.cs`, resumen). Si el técnico ejecuta `verificar --login` con una cuenta sin `VIEW DEFINITION` / `VIEW SECURITY DEFINITION` en la base o sin visibilidad del servidor, `sys.database_permissions`, `sys.database_role_members` y `sys.server_principals` devuelven solo lo visible, y `--estricto` sale con 0. La probabilidad es baja porque D-09 y D-04 (iii) fijan que lo ejecuta el técnico de GSF, que es `sysadmin`.
**Remediación.** Al inicio de `SqlBase` y `SqlInstancia`, un hallazgo `VERIFICADOR_SIN_VISIBILIDAD` (que no sea aviso) si `HAS_PERMS_BY_NAME(NULL,'DATABASE','VIEW DEFINITION')` (y `VIEW SERVER STATE`/`VIEW ANY DEFINITION` en la instancia) no es 1. ≈ 0,1 días-persona.

### SEG-RG14-04 · Baja · Huecos de detección en S4 y S5

- `IMPERSONATE ON USER::dbo` (clase 4) concedido a un rol de la aplicación escala a `dbo`; ni S4 (`PERMISO_ADMIN` filtra `class = 0`, `VerificacionPrivilegios.cs:56`) ni S5 lo ven.
- S5 `SobresAbiertos` no incluye `DELETE` (`AutoverificacionIdentidad.cs:26-29`); S4 sí lo exige.
- S4 solo comprueba `ALTER ANY USER` entre los `DENY` de `gpos_app`; no los de respaldo, DDL ni `__EFMigrationsHistory`.
- La lista de `DENY` de `gpos_app` no incluye permisos menos comunes (`CREATE ASSEMBLY`, `ALTER ANY ASSEMBLY`, `CREATE DEFAULT`, `CREATE RULE`, `ALTER ANY CERTIFICATE`, `ALTER ANY SYMMETRIC KEY`, `ALTER ANY DATABASE SCOPED CONFIGURATION`, `UNMASK`). Sigue al contrato y el control principal (sin rol fijo ni dueño) es el que manda (2.5, control 1).

Todo coincide con el texto firmado de S4 y S5: es defensa en profundidad. **Remediación** (≈ 0,25 días-persona, lote 2): agregar clase 4 `IMPERSONATE`/`CONTROL`/`TAKE OWNERSHIP`/`ALTER` sobre principales; `DELETE` en `SobresAbiertos`; las filas de `DENY_FALTANTE` de `gpos_app` para `BACKUP DATABASE`, `CREATE TABLE` y `__EFMigrationsHistory`.

### SEG-RG14-05 · Baja · `usp_RespaldoCopia` sin límite de frecuencia

**Riesgo.** `gpos_app` puede ejecutar `conf.usp_RespaldoCopia` sin límite (`SqlMigracionesRg14.cs:21-41`, `GRANT EXECUTE` en el `Up`). Con `INIT` y un nombre que cambia cada segundo, una credencial de la aplicación comprometida puede llenar el disco de `InstanceDefaultBackupPath` y detener la instancia (todas las empresas). La ruta y el nombre los fija el servidor y la etiqueta se valida bien [V].
**Remediación.** Dentro del procedimiento, rechazar (`THROW 51612`) si `msdb.dbo.backupset` tiene un respaldo `COPY_ONLY` de la misma base en los últimos N minutos (N configurable, p. ej. 10), o limitar la frecuencia en la API (`LimitesPeticiones`). ≈ 0,1 días-persona. Alternativa más barata: solo el límite en la API, que no cubre el uso directo de la credencial.

### SEG-RG14-06 · Baja · Login temporal de PA-47

**Verificado.** La clave es aleatoria (24 bytes de `RandomNumberGenerator`), no se escribe en ningún registro ni salida, y el `finally` borra usuario y login (`Rg14PrivilegioMinimoTests.cs:394-420`). SQL Server oculta el texto de `CREATE LOGIN … PASSWORD` en las trazas.
**Riesgo residual.** La clave va interpolada en el texto SQL (`:394`), con `CHECK_POLICY = OFF`. Si el proceso muere entre el `CREATE` y el `finally`, queda un login `gpos_test_pa47_*` habilitado, sin rol de servidor y con clave desconocida, en la instancia de desarrollo.
**Remediación** (≈ 0,05 días-persona): el patrón de PA-28 (clave como parámetro con `QUOTENAME(@c, '''')` en SQL dinámico), quitar `CHECK_POLICY = OFF` (la clave ya cumple la complejidad), crear el login `DISABLE`d (`EXECUTE AS LOGIN` no exige que esté habilitado [I, confirmar]) y barrer los `gpos_test_pa47_%` huérfanos al iniciar el fixture.

### SEG-RG14-07 · Baja · «Nunca lanza» no se cumple

`VerificarAsync` captura solo `SqlException`, `InvalidOperationException` y `ArgumentException` (`IdentidadSql.cs:120`), y `VerificarSistemaAsync` se llama fuera de un `try` (`Program.cs:292`). Otra excepción (p. ej. `Win32Exception` o `TimeoutException` del proveedor) detiene el arranque en el lote 1, contra lo declarado, y en una petición produce un 500 cuyo registro incluiría el mensaje de la excepción. **Remediación:** `catch (Exception ex) when (ex is not OperationCanceledException)`, con el mismo texto sin mensaje.

### SEG-RG14-08 · Baja · `VIEW DEFINITION` de ámbito de base

El `DENY VIEW DEFINITION` por esquema (D-11) no alcanza los objetos de ámbito de base (usuarios, roles, pertenencias, certificados). Un `GRANT VIEW DEFINITION TO public` posterior los mostraría a los usuarios de reportes. No expone datos de negocio. **Remediación:** S4 debe marcar como hallazgo cualquier `GRANT VIEW DEFINITION` de clase 0 a `public` o a los roles de lectura.

## 5. Controles que están bien implementados

- **S2 conforme al contrato**, y la desviación H-03 es correcta: no repetir `GRANT … ON SCHEMA::dbo` evita que el `Down` le quite a `gpos_app` el esquema heredado que concede `Mae` (`SqlMigracionesMae.cs:89`).
- **Up idempotente y Down exacto** (§3). El guion idempotente regenerado coincide con el `Up` (`database/empresa/gpos-empresa-20261014172843_Rg14PrivilegioMinimo.sql`).
- **`usp_RespaldoCopia`:** ruta fija del servidor, etiqueta `[A-Z0-9_]` comparada en BIN2, `BACKUP` con variables (sin SQL dinámico), `EXECUTE AS OWNER` en un procedimiento que `gpos_app` no puede alterar (sin `ALTER` de esquema, con `DENY ALTER ANY SCHEMA`).
- **T3-08:** `DENY` de las cuatro operaciones sobre `dbo.ConexionLectura` a `gpos_api`; aplicado solo con `CONTROL`, con aviso 51607 si no lo hay; prueba PA-17.
- **T3-12:** `DENY` explícitos que resisten un `GRANT … TO public` (prueba con `GRANT VIEW DEFINITION, SHOWPLAN TO public`).
- **SQL dinámico** solo con `QUOTENAME` sobre `sys.schemas` y rango de `schema_id` que excluye `sys`, `INFORMATION_SCHEMA`, `guest` y los esquemas de roles fijos.
- **Sin fuga de secretos:** ni la cadena ni el mensaje del motor llegan al registro ni a la respuesta; prueba de que el catálogo no aparece en el evento.
- **Autorización** del endpoint con política SUPER, 403 al ADMIN probado, y la UI no consulta si no es SUPER.
- **Modo seguro por omisión:** un valor desconocido se toma como Estricto, con aviso.
- **`appsettings.Development.json`** fuera del paquete publicado, con doble control.

## 6. Remediaciones priorizadas

| Orden | Hallazgo | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | SEG-RG14-01: `GRANT_ROL_LECTURA` en S4 y decisión sobre `rpt`/`rptc`/`imp` | Antes de unir o como condición del lote 1 | 0,25 dp |
| 2 | SEG-RG14-07: captura amplia | Con 1 | 0,02 dp |
| 3 | SEG-RG14-06: PA-47 con parámetro y barrido | Con 1 | 0,05 dp |
| 4 | SEG-RG14-02: bloqueo de Amplio (DL-02 / SEG-L2-05) y PUB-06 | Lote 2 | ya presupuestado + 0,1 dp |
| 5 | SEG-RG14-03, 04 y 08: completar S4 y S5 | Lote 2 | 0,35 dp |
| 6 | SEG-RG14-05: límite de frecuencia del respaldo | Lote 2, cuando la API use el procedimiento | 0,1 dp |

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario). No quedan hallazgos Críticos ni Altos. El Medio SEG-RG14-01 conviene cerrarlo antes de unir o dejarlo registrado como condición explícita del lote 1, porque afecta al control compensatorio de una decisión firmada (D-11).

## 8. Lectura de diferencias `4d10ecaf..f1551aa8` (2026-10-14)

Revisé en solo lectura los commits `57ec5dea` y `f1551aa8`, sin compilar. Los resultados de las pruebas (Rg14 31/32 con 1 omitida; Arquitectura 111/111) los informa el coordinador; no los verifiqué.

| Hallazgo | Estado | Evidencia |
|---|---|---|
| SEG-RG14-01 (Media) | **Cerrado** | `PermisosLecturaReportes.cs` `SqlT312`: sin `DENY VIEW DEFINITION` en `rpt`, `rptc` e `imp`, y retira el que hubiera dejado la versión anterior (`REVOKE` con `QUOTENAME`). `PrivilegioMinimoSistema.cs`: lo mismo para `rptsis`. S4 agrega `GRANT_ROL_LECTURA` (clases 1 y 3, todo lo que no sea el `SELECT` permitido por rol y esquema). Nueva prueba con `TAKE OWNERSHIP` sobre `rpt.VentaDocumento`: la detectan O-2 y S4 |
| SEG-RG14-02 (Baja) | Abierto, para el lote 2 | Sin cambios; DL-02 / SEG-L2-05 y PUB-06 |
| SEG-RG14-03 (Baja) | **Cerrado** | `VERIFICADOR_SIN_VISIBILIDAD` en la base (`VIEW DEFINITION`) y en la instancia (`VIEW ANY DEFINITION`); no es aviso, así que cuenta para `--estricto` |
| SEG-RG14-04 (Baja) | **Cerrado** | `PERMISO_SOBRE_PRINCIPAL` (clase 4); los 15 `DENY` de `gpos_app` y de `gpos_api`; `DENY` de `conf.__EFMigrationsHistory`; `DELETE` en `SobresAbiertos` (S5). Lo que la lista no cubre (`CREATE ASSEMBLY` y similares) queda como defensa en profundidad no exigida |
| SEG-RG14-05 (Baja) | Abierto, para el lote 2 | Sin cambios (límite de frecuencia de `usp_RespaldoCopia`) |
| SEG-RG14-06 (Baja) | **Cerrado** | La clave viaja como parámetro y entra con `QUOTENAME(@c, '''')`; el login se crea deshabilitado y sin `CHECK_POLICY = OFF`; al empezar se barren los `gpos_test_pa47_%` de tipo `S` (patrón con `_` escapado). Los usuarios huérfanos que dejara una corrida interrumpida quedan solo en bases `GPOS_TEST_*` |
| SEG-RG14-07 (Baja) | **Cerrado** | `IdentidadSql.cs`: la captura pasa a `when (ex is not OperationCanceledException \|\| !ct.IsCancellationRequested)`, solo con el número o el tipo, nunca el mensaje |
| SEG-RG14-08 (Baja) | Abierto, ahora algo más amplio | Ver la evaluación de D-11 abajo |

**Consecuencia de D-11: aceptable.** Si un administrador concede `GRANT VIEW DEFINITION TO public` (o a los roles de lectura), los usuarios de reportes verían la definición de las vistas de `rpt`, `rptc`, `imp` y `rptsis`. Las razones para aceptarlo:
- Es metadato: texto SQL, tablas y columnas de origen. No hay filas.
- Cada empresa tiene su propia base, así que no se cruzan datos entre empresas.
- La consecuencia exige primero un error administrativo.
- Esa cuenta ya lee las filas de esas mismas vistas.
- A cambio, O-2 conserva la cobertura de objeto en los esquemas que la credencial lee, que es la más valiosa.

Riesgo residual: Bajo. Remediación barata, que sigue abierta como SEG-RG14-08 para el lote 2: S4 debe marcar un `GRANT VIEW DEFINITION` o `SHOWPLAN` de nivel de base a `public` o a los roles de lectura (hoy `PERMISO_ADMIN` no lo incluye). ≈ 0,05 días-persona.

**Observación nueva (sin severidad).** El texto de la migración `Rg14PrivilegioMinimo` cambió después de `4d10ecaf`. Una base de desarrollo o del DEMO que ya la hubiera aplicado conserva el `DENY` en `rpt`, `rptc` e `imp` (más restrictivo) hasta que se vuelva a aplicar `crear-lectura`. Si alguna base la aplicó, conviene reaplicar la constante o recrear la base.

**Dictamen final: Aprobado con observaciones** (recomendación técnica; la firma es del propietario). No quedan hallazgos Críticos, Altos ni Medios. Quedan abiertos tres Bajos (02, 05 y 08), asignados al lote 2.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr28-rg14-lote1-2026-10-14.md`
- Supuestos: sin compilar ni ejecutar pruebas (pedido expreso), así que los resultados de las pruebas no se confirmaron; SUPER es de la plataforma (memoria «sucursal-en-linea-sqlite-y-licencia»); el técnico que ejecuta `verificar` es `sysadmin` (D-09, D-04 iii).
- Decisiones candidatas a ADR: ninguna nueva. Precisar D-11: si `rpt`/`rptc`/`imp` llevan el `DENY VIEW DEFINITION` y cuál es el control compensatorio en S4.
- Entregas a otros agentes: arquitecto-datos → S4 con `GRANT_ROL_LECTURA` y alcance de D-11 (SEG-RG14-01, 03, 04, 08); backend → captura amplia en `IdentidadSql` (07) y límite del respaldo (05); qa-automatizado → PA-47 parametrizado y barrido (06), prueba de `TAKE OWNERSHIP` en `rpt`; devops → `ModoIdentidad` en la lista de PUB-06 y comprobación del paquete (02).
- Próximo paso recomendado: el propietario decide la unión del PR #28 (`f1551aa8`); SEG-RG14-02, 05 y 08 pasan al lote 2.
