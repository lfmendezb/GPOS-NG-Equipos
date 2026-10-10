# Guía de actualización del DEMO de GPOS NG (ensayada sobre una copia)

```
De: C (devops)            Para: propietario (y técnicos que actualicen un cliente)            Fecha: 2026-10-09
Encargo: avisos/B-a-C/2026-10-09-ensayo-demo.md (aprobado por el propietario)
Equipo del ensayo: LAPTOP-DUMQQ5QK, SQL Server 2019 Express 15.0.2190.7 (.\SQLEXPRESS), 8 núcleos, 7,8 GB de RAM
Estado: Listo para decisión (la actualización real la ejecuta el propietario)
```

Todo lo de esta guía se ensayó el 2026-10-09 **sobre copias restauradas** (`GPOS_TEST_DEMO_*`) de las bases del DEMO. Las bases reales
`GPOS_DEMO` y `GPOS_SYSDATA` no se modificaron: solo se respaldaron con `COPY_ONLY` y se consultaron (sección 10). Las cifras son de este
equipo, con la máquina sola; en un cliente con más datos, los tiempos de respaldo y restauración crecen con el tamaño de la base (unos
200 MB/s medidos aquí), y los de la actualización del esquema casi no dependen de los datos.

## 1. Resumen en una página

| Paso | `demo/2026-10-08` (recomendado hoy) | `feature/modelo-ng` (302dab5) |
|---|---|---|
| Migraciones que aplica sobre lo instalado | 3 (Ola4, Ola4b, Ola4bImplantacion) | 19 (hasta `20261010000121_NucleoCajaRedondeoVuelto`) |
| Respaldo `COPY_ONLY` de las dos bases | 0,12 s + 0,42 s (23 MB + 92 MB) | igual |
| `GPOS.Migracion actualizar`, 1.ª pasada | **3,4 s** | **4,9 s** |
| 2.ª pasada (idempotencia) | 2,8 s, «el script no aplicó cambios»; esquema y datos idénticos | 2,9 s, igual |
| Cambios en `GPOS_SYSDATA` | ninguno de esquema; al iniciar, la API da al perfil «Contador» el privilegio del período fiscal | 4 tablas nuevas (`dbo.Dispositivos*`, 0,2 s) y un privilegio de reimpresión, ambos al iniciar la API |
| Datos conservados | Sí (salvo los ajustes intencionales de la sección 6.3) | Sí (ídem) |
| Reversión (restaurar el respaldo) | 0,5 s por base; esquema y datos idénticos al original | igual |
| Importar `datos-demo` 04 y 05 (10 suplidores, 30 clientes) | validar 0,4 a 6,9 s; importar 0,3 a 1,1 s; memoria pedida al motor: 0 KB | validar 0,8 a 5,6 s; importar 0,3 a 1,0 s; 0 KB |
| Mejoras de la ronda 2 que ya tiene el DEMO instalado | Se conservan | **Se pierden 3** (DM-06) |

**Advertencia principal (DM-01, Alta):** si hay que **revertir restaurando el respaldo**, la base restaurada queda **sin poder emitir
documentos** (regla MD-59: la base detecta que fue restaurada y falla cerrada) y hoy **no existe** en el código el procedimiento para
desbloquearla (H-11 de ADR-53, decidido, no construido). Para el DEMO, la salida es reinstalarlo o una decisión expresa del propietario
(sección 8.3). En un cliente real, **no se debe publicar una actualización sin resolver antes DM-01**.

## 2. Qué hay instalado hoy en este equipo (inventario, solo lectura)

| Elemento | Valor verificado |
|---|---|
| Carpeta del DEMO | `C:\GSF\PROYECTO ARGON\GPOS-Demo-Socio-2026-10-07` (paquete «2026-10-07», rama `demo/2026-10-07`, confirmación `5ad4e78`) |
| Instalado | 2026-10-06 22:41, por el usuario de Windows `LAPTOP-DUMQQ5QK\lfmen` (`config\instalacion.json`) |
| Programas | `app\api` (GPOS.Api.exe), `app\web`, `app\maui`, `app\migracion`, publicados en Release, autocontenidos win-x64 (.NET 10.0.12 incluido) |
| Cómo se arranca | **A mano**, con `.\Iniciar-Demo.ps1` en PowerShell desde la carpeta del DEMO: comprueba el esquema con `GPOS.Migracion verificar`, arranca la API (http://localhost:5071), la Web (http://localhost:5054) y la aplicación de Windows, sin ventanas de consola; registros en `registros\`. Se detiene con `.\Detener-Demo.ps1`. No es un servicio de Windows ni una tarea programada. Últimos arranques: 2026-10-09 00:44 y 01:14. Durante el ensayo **no estaba corriendo** y no se arrancó. |
| Configuración de la API | Por variables de entorno que pone el script: conexión a `GPOS_SYSDATA` con la cuenta de Windows, carpeta de llaves de Data Protection `datos\llaves-api`, clave JWT leída de `config\secretos.dpapi` (cifrada con DPAPI del usuario). Los `appsettings.json` del paquete no llevan secretos y son **idénticos** a los de `demo/2026-10-08` (comparado). |
| Base de la empresa | `GPOS_DEMO`: 80 MB (72 de datos, 8 de registro), recuperación FULL, RCSI, Query Store, **AUTO_CLOSE activo**, intercalación `Latin1_General_100_CI_AS_SC_UTF8`; esquema `20261006170943_Ola3EmisionLigera` (8 migraciones); tiene los dos esquemas (el heredado `dbo`, 124 tablas, y el nuevo, 104 tablas); 153 artículos, 2 clientes, 10 suplidores, 3 ventas, 5 documentos |
| Base del sistema | `GPOS_SYSDATA`: 528 MB (200 de datos, 328 de registro), recuperación SIMPLE, AUTO_CLOSE activo; 5 usuarios, 4 perfiles, 1 empresa; 793.093 filas del padrón de RNC |
| Respaldos previos | **Ninguno** (msdb solo registra los dos `COPY_ONLY` de este ensayo) (DM-07) |
| SQL Server | `.\SQLEXPRESS` 2019 Express, memoria mín. 1.024 / máx. 3.072 MB, en uso 726 MB; carpeta de respaldo por omisión `C:\Databases_bak`, datos en `C:\Databases`. Existe además `.\BARTENDER` (Express, sin tope de memoria; ajena a GPOS) |
| Disco C: | **98 % ocupado, 6,5 GB libres** (bajó a 2,9 GB durante el ensayo por las compilaciones y las copias) |
| Agente de impresión | `C:\Program Files\GPOS\Agente de impresion`, en ejecución; no se toca en esta actualización |

## 3. Qué trae cada opción

**`demo/2026-10-08` (6f07a7f):** lo instalado más la ola 4 del modelo nuevo hasta la implantación (compras, CxP, bancos y caja chica en
el esquema; `configtpv` pasa a `conf.Parametros` y a `org.Caja`; período fiscal declarado; «hoy de la empresa» UTC−4 desde el reloj
protegido; códigos fiscales 606/607 en las formas de pago; fecha anterior con privilegio y autorización), la **corrección de la lentitud
de la importación de suplidores y clientes** (`d833c99`, `b1fe442`) y las mejoras de la ronda 2 (segundo Guardar, datos de los gráficos
en tabla, Enter = Buscar). 3 migraciones de empresa; ningún cambio de esquema en `GPOS_SYSDATA`.

**`feature/modelo-ng` (302dab5; mismo código que `ebd121a`, lo posterior es documentación):** 19 migraciones (compras, conversión,
retiro, factor de unidad y kárdex, 607/608, propina legal, exigir vendedor, núcleo de caja: reimpresión y redondeo del vuelto) y, en
`GPOS_SYSDATA`, el registro de dispositivos del KDS. **No contiene** las confirmaciones `eb7bd62`, `f7646be` y `87b90f8` de la ronda 2,
que el DEMO instalado ya tiene (DM-06).

**Recomendación (sección 9):** actualizar ahora a `demo/2026-10-08`; pasar a `feature/modelo-ng` cuando la ronda 2 (PR #6) esté unida
en ella y se corte una rama `demo/` nueva. El procedimiento es el mismo y quedó ensayado también para `feature/modelo-ng`.

## 4. Antes de empezar (requisitos)

1. **Paquete de la versión nueva.** Hoy **no existe** un paquete del 2026-10-08 (DM-05): en OneDrive solo están los del 2026-10-05 y
   2026-10-07. Quien lo prepare publica desde la rama elegida, en una copia limpia del repositorio (no en la del propietario):
   ```powershell
   git worktree add C:\temp\gpos-demo-1008 origin/demo/2026-10-08
   cd C:\temp\gpos-demo-1008
   dotnet publish src\GPOS.Api\GPOS.Api.csproj             -c Release -r win-x64 --self-contained true -o C:\temp\paquete\app\api
   dotnet publish src\GPOS.Web\GPOS.Web.csproj             -c Release -r win-x64 --self-contained true -o C:\temp\paquete\app\web
   dotnet publish src\GPOS.Migracion\GPOS.Migracion.csproj -c Release -r win-x64 --self-contained true -o C:\temp\paquete\app\migracion
   ```
   Medido: 15 s, 16 s y 4 s (202 MB, 122 MB y 140 MB). La aplicación de Windows (MAUI) se publica con el mismo procedimiento con que se
   armó el paquete del 2026-10-07; **no se ensayó aquí** (exige la carga de trabajo MAUI). Sin ella, el DEMO funciona con la Web
   (`.\Iniciar-Demo.ps1 -SinMaui`).
2. **Espacio libre:** al menos 2 GB en C: para los respaldos y la copia de la carpeta (hoy hay 6,5 GB; con menos de 1 GB, no empiece).
3. **Mismo usuario de Windows** que instaló el DEMO (`lfmen`): el secreto JWT está cifrado con su DPAPI.
4. **Ventana:** 15 minutos con el DEMO detenido; el trabajo efectivo son unos 2 minutos.

## 5. Procedimiento de actualización

Todos los comandos se ejecutan en PowerShell (no como administrador), en la carpeta del DEMO:
`cd 'C:\GSF\PROYECTO ARGON\GPOS-Demo-Socio-2026-10-07'`.

### Paso 1. Detener el DEMO
```powershell
.\Detener-Demo.ps1
Get-Process GPOS.Api, GPOS.Web, GPOS.UI.MAUI -ErrorAction SilentlyContinue   # no debe listar nada
```
`GPOS.Migracion actualizar` activa opciones de la base con `ROLLBACK IMMEDIATE` y vuelve a crear objetos del esquema heredado: con la
API abierta, cortaría transacciones en curso.

### Paso 2. Respaldo previo (obligatorio)
```powershell
$f = Get-Date -Format 'yyyyMMdd_HHmm'
sqlcmd -S '.\SQLEXPRESS' -E -b -Q "BACKUP DATABASE [GPOS_DEMO]    TO DISK = N'C:\Databases_bak\GPOS_DEMO_antes_$f.bak'    WITH COPY_ONLY, INIT, CHECKSUM"
sqlcmd -S '.\SQLEXPRESS' -E -b -Q "BACKUP DATABASE [GPOS_SYSDATA] TO DISK = N'C:\Databases_bak\GPOS_SYSDATA_antes_$f.bak' WITH COPY_ONLY, INIT, CHECKSUM"
sqlcmd -S '.\SQLEXPRESS' -E -b -Q "RESTORE VERIFYONLY FROM DISK = N'C:\Databases_bak\GPOS_DEMO_antes_$f.bak' WITH CHECKSUM; RESTORE VERIFYONLY FROM DISK = N'C:\Databases_bak\GPOS_SYSDATA_antes_$f.bak' WITH CHECKSUM"
robocopy . "..\GPOS-Demo-Socio-2026-10-07_antes_$f" /E /XD registros /NFL /NDL /NJH
```
- Esperado: «BACKUP DATABASE successfully processed 2977 pages» (0,12 s) y «11777 pages» (0,42 s); dos «The backup set on file 1 is
  valid» (0,2 s). Archivos de unos 23 MB y 92 MB.
- `C:\Databases_bak` es la carpeta por omisión de la instancia: la cuenta del servicio (`NT Service\MSSQL$SQLEXPRESS`) **no puede**
  escribir en las carpetas temporales del usuario (error 5, comprobado).
- La copia de la carpeta guarda `config\` (instalación y secreto DPAPI), **`datos\llaves-api` y `datos\llaves-web` (sin ellas no se
  descifra la conexión de la empresa)** y los programas actuales, para volver atrás.
- `COPY_ONLY` no altera la cadena de respaldos de la base (`GPOS_DEMO` está en FULL).

### Paso 3. Huella antes (para comparar después)
```powershell
sqlcmd -S '.\SQLEXPRESS' -E -W -Q "SET NOCOUNT ON; SELECT MigrationId FROM GPOS_DEMO.conf.__EFMigrationsHistory ORDER BY 1; SELECT (SELECT COUNT(*) FROM GPOS_DEMO.cat.Articulo) art, (SELECT COUNT(*) FROM GPOS_DEMO.cat.Cliente) cli, (SELECT COUNT(*) FROM GPOS_DEMO.cat.Suplidor) sup, (SELECT COUNT(*) FROM GPOS_DEMO.ventas.Venta) ventas, (SELECT COUNT(*) FROM GPOS_DEMO.doc.Documento) docs, (SELECT COUNT(*) FROM GPOS_DEMO.inv.Movimiento) movs, (SELECT SUM(Cantidad) FROM GPOS_DEMO.inv.Existencia) existencias, (SELECT COUNT(*) FROM GPOS_SYSDATA.dbo.Usuarios) usuarios" > "..\huella_antes_$f.txt"
```
Hoy: 8 migraciones; 153 artículos, 2 clientes, 10 suplidores, 3 ventas, 5 documentos, 158 movimientos, 5 usuarios.

### Paso 4. Reemplazar los programas
Borre y reemplace **solo** `app\api`, `app\web`, `app\migracion` (y `app\maui` si el paquete la trae) con las del paquete nuevo. **No
toque** `config\`, `datos\` ni `registros\`. Los `appsettings.json` del paquete nuevo son iguales a los instalados.

### Paso 5. Actualizar la base de la empresa (el paso que cambia el esquema)
```powershell
.\app\migracion\GPOS.Migracion.exe actualizar --servidor '.\SQLEXPRESS' --base GPOS_DEMO
```
Salida esperada con `demo/2026-10-08` (3,4 s):
```
.\SQLEXPRESS / GPOS_DEMO:
  Aviso: la base tiene la intercalación , no la del modelo nuevo (...)      <- ver DM-03: con AUTO_CLOSE la base estaba cerrada; ignórelo si «verificar» informa Latin1_General_100_CI_AS_SC_UTF8
  Migraciones aplicadas: 20261007024725_Ola4, 20261007051739_Ola4b, 20261007072312_Ola4bImplantacion.
```
Con `feature/modelo-ng`: las 19 migraciones, en 4,9 s. Si aparece «ADVERTENCIA (H-1)», **deténgase**: la base tendría maestros solo en el
esquema heredado (no ocurrió en el ensayo).

Este comando aplica, en este orden: opciones de la base (RCSI, FULL, Query Store, si faltan), el esquema heredado (`database/01` y `02`,
convivencia H-03), el script idempotente embebido del modelo nuevo y el registro del sitio si faltara. Usa la cuenta de Windows de
quien lo ejecuta (necesita permisos de esquema en la base; nunca `sa` ni `gsf`).

### Paso 6. Segunda pasada (comprobación de idempotencia, opcional, 2,8 s)
Repita el comando del paso 5. Esperado: «Esquema al día (20261007072312_Ola4bImplantacion): el script no aplicó cambios.»

### Paso 7. Verificar el esquema
```powershell
.\app\migracion\GPOS.Migracion.exe verificar --servidor '.\SQLEXPRESS' --base GPOS_DEMO ; $LASTEXITCODE
```
Esperado: «pendientes: ninguna», intercalación UTF-8, RCSI activado, FULL, nodo 1, **sin** «RESTAURADA», y código 0.

### Paso 8. Iniciar el DEMO (aquí se actualiza `GPOS_SYSDATA`)
```powershell
.\Iniciar-Demo.ps1
```
`GPOS_SYSDATA` no tiene comando de migración aparte (ADR-38, decidido, no construido): la API la actualiza **al iniciar**
(`Inicializacion.EjecutarAsync`: `EsquemaSistema.ActualizarAsync`, semillas de reportes y de privilegios). Con `demo/2026-10-08` no hay
cambios de esquema; el perfil de ejemplo «Contador» recibe «Período fiscal» (Consultar) una sola vez. Con `feature/modelo-ng` se crean
además `dbo.Dispositivos`, `DispositivosAreas`, `DispositivosCodigos` y `DispositivosBitacora` (0,2 s, idempotente, ensayado) y se
entrega «Reimprimir comprobantes fiscales» a los perfiles de ejemplo.

### Paso 9. Verificación después
1. `Iniciar-Demo` debe informar «Esquema de la base GPOS_DEMO al día», «API en http://localhost:5071» y «La conexión cifrada de la
   empresa DEMO se descifra».
2. Repita la consulta del paso 3 en `huella_despues_$f.txt` y compare: mismas cifras de maestros, ventas, documentos, movimientos y
   existencias; 11 migraciones (o 27 con `feature/modelo-ng`).
3. Revise `registros\api.log` y `api-errores.log`: sin errores. Busque `RelojInconsistente` (ya aparece en el DEMO actual, aviso de B
   del 2026-10-09); esta versión toma el «hoy de la empresa» del reloj protegido, así que si aparece, revise la fecha que muestran los
   documentos nuevos.
4. Prueba manual corta: entrar como ADMIN; consultar artículos, clientes, suplidores y facturas; importar `datos-demo\05-clientes.xlsx`
   (tarda menos de 2 s; antes se estancaba); una venta en Facturación Ágil.

## 6. Resultado del ensayo (evidencia)

### 6.1 Cómo se ensayó
1. Respaldo `COPY_ONLY` de las dos bases reales a `C:\Databases_bak\GPOS_TEST_DEMO_*.bak`; restauración `WITH MOVE` como
   `GPOS_TEST_DEMO_EMP` y `GPOS_TEST_DEMO_SYS` (y luego `_EMP2` y `_SYS2` para `feature/modelo-ng`).
2. Huella de cada copia en una base auxiliar: objetos (con el SHA-256 de su definición), columnas, índices, propiedades de la base y, por
   tabla, filas y sumas de control (`CHECKSUM_AGG` y suma de `BINARY_CHECKSUM`) de las columnas que existían antes.
3. `GPOS.Migracion` compilado desde cada rama, `actualizar --servidor .\SQLEXPRESS --base GPOS_TEST_DEMO_...` dos veces; el esquema de
   `GPOS_SYSDATA` se aplicó a su copia con el SQL de `EsquemaSistema.cs` (sin arrancar la API: la copia del sistema guarda las conexiones
   cifradas que apuntan a la base real).
4. Pruebas filtradas: `AprovisionamientoTests` y `VersionEsquemaTests` en `demo/2026-10-08` (17 de 17) y, además,
   `MigracionNucleoCajaTests` en `feature/modelo-ng` (18 de 18).

### 6.2 Idempotencia: **sí**
Entre la 1.ª y la 2.ª pasada, en las dos ramas: 0 diferencias en objetos, definiciones, columnas, índices, propiedades, filas y sumas
de control de **todas** las columnas de las 249 tablas. Única huella de la 2.ª pasada: la fecha de modificación de 7 objetos del esquema
heredado que se vuelven a crear con la misma definición (`dbo.NUM_Series`, `dbo.Sucursales`, sus 2 disparadores y 3 vistas
`vw_GPost_*`) (DM-09). `GPOS_SYSDATA`: también idempotente.

### 6.3 Datos conservados: **sí**
Las 228 tablas existentes conservan filas y contenido, salvo estos **ajustes intencionales de las migraciones** (verificados contra su
SQL):
| Tabla | Cambio | Origen |
|---|---|---|
| `cat.FormaPago` | NOTACREDITO: `ClaseFiscal607` 7 → 5 | Ola4b, línea `UPDATE cat.FormaPago SET ClaseFiscal607 = 5 WHERE Codigo = 'NOTACREDITO' AND ClaseFiscal607 = 7` |
| `org.Caja` | CAJA2: `ClienteContadoId` NULL → cliente genérico | Ola4 (T-42, `configtpv` → `org.Caja`) |
| `conf.Parametros` | columnas nuevas con valores de `configtpv` y por omisión (cantidad POS 1, impuesto y unidad POS, clase de agente J, descuento máximo POS 100, 30 días de aviso de devolución); deja 1 fila en `conf.ParametrosHistorial` | Ola4/Ola4b |
| `doc.TipoDocumento` | 16 → 30 tipos | catálogo |
| catálogos nuevos | `cat.ConceptoNota` 7, `fiscal.TipoRetencionIsr` 9 (y `inv.MotivoAjuste` 6 con `feature/modelo-ng`) | catálogo |
Esquema: `demo/2026-10-08` agrega 21 tablas, 230 columnas y 79 índices, cambia 3 definiciones (`cxc.TR_Aplicacion_Inmutable`,
`doc.TR_Documento_Emision`, `rpt.Formato607`) y quita `IX_Caja_PuntoEmisionId`. `feature/modelo-ng`: 21 tablas, 240 columnas, 81
índices, 5 definiciones, 3 índices quitados e `inv.Movimiento.Linea` pasa de `smallint` a `int`.

### 6.4 Importación de suplidores y clientes (archivos reales de `datos-demo`, sobre la copia actualizada)
| Paso | `demo/2026-10-08` | `feature/modelo-ng` |
|---|---|---|
| Suplidores, 10 filas, validar (en frío, 1.ª vez del proceso) | 6,85 s (2,85 s leyendo el Excel) | 5,58 s |
| Suplidores, importar (10 actualizados) | 0,62 s | 0,79 s |
| Clientes, 30 filas, validar | 1,10 s | 0,81 s |
| Clientes, importar (30 nuevos) | 1,14 s | 1,04 s |
| 2.ª pasada completa (todo se actualiza) | 0,31 a 0,74 s por paso | 0,25 a 0,77 s |
| Mayor concesión de memoria pedida al motor | 0 KB (11 planes) | 0 KB |
Prueba de referencia `ImportacionTercerosTiempoTests` (base propia): con el volumen del DEMO, 0,26 a 3,69 s por paso, 0 KB; con 1.000
veces el DEMO (10.000 suplidores, 30.000 clientes), validar 2,55 s y 8,04 s, importar suplidores 1,92 s, dentro de los topes. **El
estancamiento del 2026-10-07 (129 a 281 s esperando memoria) no se reproduce.** El primer paso de cada arranque tarda 4 a 6 s más por el
arranque en frío (lectura del Excel y compilación), agravado por AUTO_CLOSE (DM-04).

### 6.5 Reversión ensayada
Restaurar el respaldo previo sobre la copia actualizada tardó 0,49 s; la huella quedó **idéntica** a la de antes (esquema, índices,
definiciones, filas y contenido), con una sola diferencia: el `recovery_fork_guid` de la base, que cambia en **cada** restauración
(original `0C83BDC3…`, copia `94E69ED8…`, copia revertida `80EC3D83…`). Eso es lo que activa DM-01.

## 7. Reversión (si algo falla)

Regla: **la base y los programas vuelven juntos.** La API de una versión solo trabaja con la versión exacta de esquema que espera
(`EsquemaEmpresasNg.cs:63-71`): con programas viejos y base nueva responde `VERSION_ESQUEMA` («esquema más nuevo»), comprobado con el
`GPOS.Migracion verificar` instalado contra la copia actualizada (código 2). Las migraciones tienen `Down` en EF, pero el proyecto no
genera scripts de reversión y no se ensayaron: **la reversión soportada es restaurar el respaldo.**

1. Si falló el paso 5 (o el 8) y **no se ha vendido** con la versión nueva:
   ```powershell
   .\Detener-Demo.ps1
   sqlcmd -S '.\SQLEXPRESS' -E -b -Q "ALTER DATABASE [GPOS_DEMO] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; RESTORE DATABASE [GPOS_DEMO] FROM DISK = N'C:\Databases_bak\GPOS_DEMO_antes_$f.bak' WITH REPLACE, RECOVERY, CHECKSUM; ALTER DATABASE [GPOS_DEMO] SET MULTI_USER;"
   sqlcmd -S '.\SQLEXPRESS' -E -b -Q "ALTER DATABASE [GPOS_SYSDATA] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; RESTORE DATABASE [GPOS_SYSDATA] FROM DISK = N'C:\Databases_bak\GPOS_SYSDATA_antes_$f.bak' WITH REPLACE, RECOVERY, CHECKSUM; ALTER DATABASE [GPOS_SYSDATA] SET MULTI_USER;"
   ```
   y vuelva a poner `app\` desde la copia del paso 2 (`robocopy "..\GPOS-Demo-Socio-2026-10-07_antes_$f\app" .\app /MIR`). Tiempo: unos
   2 s de base y lo que tarde la copia de archivos.
2. Restaurar `GPOS_SYSDATA` solo hace falta si se llegó a iniciar la API nueva (paso 8); sus cambios son aditivos, pero así queda
   exactamente como estaba.
3. **Después de restaurar, el DEMO no emite** (DM-01): `GPOS.Migracion verificar` mostrará «RESTAURADA: el fork no coincide con el
   registrado» y toda venta o documento con número responderá «Emisión bloqueada: la base fue restaurada… (MD-59)». Opciones (decisión
   del propietario):
   - (a) **Recomendada para el DEMO:** si no hay nada que conservar, reinstalar el paquete del 2026-10-07 y recargar `datos-demo`
     (procedimiento ya conocido del LEEME).
   - (b) Esperar el procedimiento de desbloqueo H-11 (cerrar secuencias, adelantar series y confirmar con motivo y privilegio
     «Reconciliar nodo restaurado»), que hoy no existe.
   - (c) Registrar a mano el fork actual en `sync.EstadoNodo`. **No lo recomiendo** sin la firma del propietario: se salta un control
     fiscal (MD-59) sin la evidencia que H-11 exige. No se ensayó.
4. Si se vendió con la versión nueva antes de revertir, esas ventas se pierden al restaurar: no revierta sin consultar.

## 8. Riesgos y defectos encontrados

| Id | Severidad | Hallazgo | Evidencia | Para |
|---|---|---|---|---|
| DM-01 | **Alta** | La reversión por restauración deja la base sin poder emitir y no hay procedimiento implementado para desbloquearla. Cada `RESTORE` crea un `recovery_fork_guid` nuevo; el disparador de emisión lo compara con `sync.EstadoNodo.ForkRegistrado` y lanza 51330. `actualizar` no vuelve a registrar el fork (`registrarSiExiste: false`) y no hay comando, servicio ni pantalla de reconciliación (H-11 de ADR-53, cláusula 9). Afecta a todo cliente que restaure un respaldo, no solo a la actualización. | `SqlMigracionesOla3EmisionLigera.cs:49-55`; `Aprovisionamiento.cs:118-120` y `:208-233`; `GPOS.Migracion/Program.cs:51-63` (solo crear, actualizar, verificar); ensayo: fork `0C83…` frente a `94E6…` y `80EC…`, condición del disparador «BLOQUEARÍA 51330» en la copia revertida | arquitecto-datos y backend (A): construir H-11 antes de publicar a un cliente |
| DM-02 | Media | `verificar` devuelve 0 («al día») aunque la base esté RESTAURADA y no pueda emitir; `Iniciar-Demo` dice «Esquema al día». | `Program.cs:63-71` (código 2 solo si `!AlDia`; `AlDia` no mira `Restaurada`); salida del ensayo | backend (A) / devops (scripts del DEMO) |
| DM-03 | Baja | `actualizar` avisa «la base tiene la intercalación , no la del modelo nuevo» cuando la base tiene AUTO_CLOSE y estaba cerrada (`DATABASEPROPERTYEX` devuelve NULL); confunde al técnico. | `Aprovisionamiento.cs:108-112`; las 4 pasadas del ensayo | backend (A) |
| DM-04 | Media | Las bases del DEMO tienen AUTO_CLOSE activo (valor por omisión de Express para bases nuevas) y el aprovisionamiento no lo apaga: cada primera conexión reabre la base y vacía sus planes (arranques en frío de 4 a 6 s en la importación) y causa DM-03. | `sys.databases.is_auto_close_on = 1` en `GPOS_DEMO` y `GPOS_SYSDATA`; `FijarOpcionesAsync` solo fija RCSI, FULL y Query Store | arquitecto-datos: `AUTO_CLOSE OFF` en `crear`/`actualizar` y en la base del sistema |
| DM-05 | Media | No hay paquete de actualización del 2026-10-08 ni scripts de actualización/reversión del DEMO en el repositorio (los de la ronda 1, `Actualizar-Demo.ps1` y `Revertir-Actualizacion.ps1`, solo están dentro de un .7z de OneDrive). | `git ls-tree` de las dos ramas; carpeta `OneDrive\Instalador\GPOS ARGON\Actualización` | coordinador de B / devops: publicar el paquete con esta guía |
| DM-06 | Media | `feature/modelo-ng` no tiene `eb7bd62`, `f7646be` ni `87b90f8` (ronda 2: segundo Guardar, datos de los gráficos en tabla, Enter = Buscar en 5 pantallas), que el DEMO instalado (`5ad4e78`) ya tiene: actualizar a esa rama las quitaría. | `git cherry origin/feature/modelo-ng 5ad4e78` | coordinador (A/B): unir PR #6 antes de cortar el próximo DEMO |
| DM-07 | Baja | El DEMO nunca tuvo un respaldo propio; se instaló sin `--respaldo-inicial`. | msdb `backupset`; `registros\migracion.log` | propietario: respaldo diario (MD-54, Backup Tool) |
| DM-08 | Baja | Aplicar el SQL de `EsquemaSistema` a mano con `sqlcmd` sin `-I` falla en el índice filtrado `IX_Dispositivos_Pendientes` y deja la base a medias (solo `dbo.Dispositivos`). Por la API no ocurre. | ensayo sobre `GPOS_TEST_DEMO_SYS2`, mensaje 1934 | técnicos: usar `sqlcmd -I`; arquitecto: comando de migración del sistema (ADR-38) |
| DM-09 | Baja | Cada `actualizar` vuelve a crear 7 objetos del esquema heredado con la misma definición (cambia su fecha): por eso se ejecuta con la API detenida. | huellas `d08_1` frente a `d08_2` | informativo (desaparece con el corte de la entrega 1) |

Otros riesgos:
- **Disco:** C: al 98 %. Un respaldo, la restauración o el crecimiento del registro pueden fallar por espacio. Libere al menos 10 GB.
- **Servidor GC en la API** (`System.GC.Server: true` en `GPOS.Api.runtimeconfig.json`): en equipos de 4 a 8 GB usa más memoria que el
  modo estación. Propuesta para el arquitecto: medirlo y, si conviene, `DOTNET_gcServer=0` en los clientes pequeños.
- **Reloj protegido:** el DEMO ya registra `RelojInconsistente`; la versión nueva usa ese reloj para el «hoy de la empresa». Verificarlo en
  el paso 9.

## 9. ¿`demo/2026-10-08` o `feature/modelo-ng`? (pregunta de B)

**Recomendación: `demo/2026-10-08` ahora.** Motivos: es la rama cortada para esta actualización; conserva las mejoras de la ronda 2 que
el propietario ya probó (DM-06); trae la corrección de la importación que motivó el pendiente; aplica 3 migraciones (menos superficie)
y no toca el esquema de `GPOS_SYSDATA`. `feature/modelo-ng` también se actualiza bien (4,9 s, idempotente, datos conservados, 18 de 18
pruebas filtradas), pero quitaría tres mejoras visibles y agrega funciones (compras completas, factor de unidad, núcleo de caja, KDS)
que conviene presentar en un DEMO cortado a propósito, con la ronda 2 unida. Pasar de `demo/2026-10-08` a esa futura rama `demo/` usa el
mismo procedimiento: el script es acumulativo e idempotente (las 16 migraciones restantes).

Alternativa descartada: actualizar ya a `feature/modelo-ng` y volver a aplicar a mano las 3 confirmaciones de la ronda 2; es trabajo de
desarrollo fuera de esta tarea y crearía una rama del DEMO sin revisión.

## 10. Comprobación de que las bases reales no se tocaron

Antes y después del ensayo, con las mismas consultas de solo lectura: `conf.__EFMigrationsHistory` de `GPOS_DEMO` con las mismas 8 filas
(última `20261006170943_Ola3EmisionLigera`); última modificación de esquema de `GPOS_DEMO` 2026-10-06 22:42:27.500 (1.110 objetos) y de
`GPOS_SYSDATA` 2026-10-06 22:41:57.113 (26 objetos), sin cambios; `recovery_fork_guid` de `GPOS_DEMO` el mismo (`0C83BDC3…`); opciones
iguales (FULL/SIMPLE, RCSI, Query Store, AUTO_CLOSE, MULTI_USER); 2 clientes y 10 suplidores. `diff` de las dos huellas: sin diferencias.
Lo único que queda del ensayo en la instancia son dos filas de historial en `msdb` (los `COPY_ONLY`).

## 11. Propuesta de memoria de SQL Server (no aplicada)

Express limita el búfer de datos a 1.410 MB por instancia; con la caché de planes y lo demás, la instancia no pasa de unos 1,8 a 2 GB:
el máximo actual de 3.072 MB no se alcanza nunca, y el mínimo de 1.024 MB retiene 1 GB una vez alcanzado aunque el equipo lo necesite.
Medido: la instancia usa 726 MB; quedan 1.032 MB libres de 7.991; los datos del DEMO son unos 80 MB y los de `GPOS_SYSDATA` 200 MB.

| Equipo | Mín. / Máx. propuesto | Motivo |
|---|---|---|
| Este equipo (desarrollo + DEMO, 7,8 GB, con Visual Studio, compilaciones y `.\BARTENDER`) | **512 / 2.048 MB** | Cubre el tope real de Express y devuelve memoria al resto; `.\BARTENDER` no tiene tope: si se usa, fijarle 512 MB |
| Cliente pequeño, un equipo servidor y caja, 8 GB | 512 / 2.048 MB | Igual tope de Express; deja 5 GB para Windows, la API, la Web y la aplicación |
| Cliente pequeño con 4 GB | 256 / 1.024 MB | Con 4 GB la API, la Web y Windows necesitan unos 2,5 GB |

Comando (lo ejecuta el propietario; dinámico, sin reiniciar; para volver atrás, los valores 1.024 y 3.072):
```sql
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'min server memory (MB)', 512;
EXEC sp_configure 'max server memory (MB)', 2048; RECONFIGURE;
```
Costo: ninguno (configuración). Con Standard (centrales grandes, ADR-54) la cifra se calcula aparte: allí el tope sí se usa.

## 12. Para repetir en un cliente (lista corta)

1. Detener la API, la Web y las cajas. 2. Respaldo `COPY_ONLY` + `CHECKSUM` + `VERIFYONLY` de la base de cada empresa y de
`GPOS_SYSDATA`; copia de la carpeta de programas y de las llaves de Data Protection. 3. Huella antes (paso 3). 4. Reemplazar programas.
5. `GPOS.Migracion actualizar --empresa <código>` (lee las empresas de `GPOS_SYSDATA`; necesita `ConnectionStrings:Sistema` y la carpeta
de llaves de la API en `GPOS.Migracion.json`) o `--servidor/--base` por cada base. 6. `verificar` (código 0 y sin «RESTAURADA»).
7. Iniciar la API (actualiza `GPOS_SYSDATA`). 8. Huella después y prueba corta. 9. Si algo falla antes de vender: restaurar base y
programas juntos (sección 7), sabiendo que hoy la base restaurada no emite (DM-01). Tiempos esperados: segundos por base de hasta unos
cientos de MB; el respaldo y la restauración, unos 200 MB/s en un disco como el de este equipo.
