# DB-7, tramo D0: modelo de datos del acceso multiempresa v1

- **Fecha:** 2026-10-18 · **Autor:** arquitecto de datos (equipo B) · **Estado:** propuesta de diseño. Las preguntas P-D0-D01 a P-D0-D05 de la sección 11 y las discrepancias de la sección 13 quedan **pendientes de firma**. Nada de lo descrito existe en el código.
- **Base leída (solo lectura):**
  - `feature/modelo-ng` @ `4e094323`;
  - la unión del #57 que otro agente hacía en el mismo árbol: `b/une-57` @ `f165d1fa` (fase A de ADR-81, esquema del sistema en las versiones 4 y 5);
  - `master` @ `9b38c947` para los ADR y la decisión.
- **Entradas:**
  - decisión `docs/decisiones/2026-10-18-decision-db7-calendario.md` (DB7-01 a DB7-07, firmada);
  - hoja `traspasos/B/2026-10-18-propuesta-calendario-db7.md`;
  - modelo `docs/datos/2026-09-29-modelo-acceso-multiempresa.md` (en adelante **DAT-0929**);
  - estándar v2.3 `docs/arquitectura/2026-09-29-estandar-acceso-multiempresa.md` (**EST**);
  - ADR-34 a 43 con sus precisiones del 2026-10-18; ADR-58 (punto 9); ADR-79; ADR-81 (punto 12); ADR-82; ADR-83 (puntos 1 a 9, SL, TN y RS); `CLAUDE.md`.
- **Alineado con el blueprint v3** `docs/arquitectura/2026-10-18-db7-blueprint-v3.md` (**BP3**): secciones 6.1, 6.3, 6.4, 8.4, 11.1 y 12. Las diferencias que no resolví en silencio están en la sección 13.

[Blueprint de Datos]

---

## 1. Contexto y modelo de tenencia aplicado

### 1.1 Tenencia (sin cambios)
- Base por empresa más `GPOS_SYSDATA` (ADR-52 y ADR-53). **Todo DB-7 vive en `GPOS_SYSDATA`.** Las bases de empresa no cambian de esquema (ADR-34, «Consecuencias»).
- **Aislamiento entre empresas** en cada tabla nueva:
  - `EmpresaCodigo` forma parte de la clave primaria;
  - las FK compuestas llevan la empresa;
  - los filtros usan la empresa de la sesión, tomada del token validado en el servidor (2.4).
- Un solo dueño por instalación (ADR-43).

### 1.2 Mecanismo real del esquema (verificado)
- `GPOS_SYSDATA` se crea con `EnsureCreated` y después se aplican lotes idempotentes **sin `GO`** con `ExecuteSqlRawAsync`, en este orden: `ActualizarTablasAsync` → `ActualizarRestauracionAsync` → `ExtensionesEsquemaSistema.Ddl` → `rptsis` → `PrivilegioMinimoSistema` (`4e094323:src/GPOS.Core/Data/Sistema/EsquemaSistema.cs:55-68`).
- Los aplica `GPOS.Migracion sistema`, y también el arranque en Amplio. Los permisos van en `ExtensionesEsquemaSistema.Permisos`, que solo aplica `sistema`.
- **No hay migraciones de EF para `GPOS_SYSDATA`.**
- **Versión del esquema:** la marca `GPOS.EsquemaSistema` está en 3 en `4e094323:…/EsquemaSistema.cs:73` y en 5 con el #57 (`f165d1fa:…/EsquemaSistema.cs:73`). **DB-7 usa la 6** (supuesto S-1).
- **Dónde va el lote de DB-7:** hoy el `Ddl` es `[SqlLicenciaSistema.Ddl, EsquemaSistema.SegundoFactorDdl]` (`f165d1fa:src/GPOS.Core/Data/Sistema/ExtensionesEsquemaSistema.cs:20`). El de DB-7 va **tercero**.
- **Tipos y parámetros:**
  - `GPOS_SYSDATA` es Unicode y los códigos son `nvarchar(30)` (`4e094323:src/GPOS.Core/Data/Sistema/SistemaDbContext.cs:27-36`).
  - ADR-50 no aplica, pero **sí su regla de fondo**: cada parámetro lleva el tipo y el largo de su columna (`DbString`, `IsAnsi`; patrón en `4e094323:src/GPOS.Core/Sistema/Restauracion/BitacoraSeguridad.cs:55-60`).
  - Los dominios cerrados nuevos van en `varchar`, como `BitacoraSeguridad.Evento`.
- **`Configuracion.Valor` es `nvarchar(max)`** (`4e094323:…/EsquemaSistema.cs`, creación de `dbo.Configuracion`). Responde a BP3 11.1.8: el padrón v2 (hasta unos 0,7 MB protegido) **no exige cambiar la columna**.
  - Con 0,7 MB en texto base64 son unos 1,4 MB en UTF-16, fuera de la fila (LOB).
  - Se escribe una vez por acción de administración y se lee cuando cambia.
  - *Alternativa descartada:* pasar a `varbinary(max)`. Ahorra la mitad del tamaño, pero cambia la columna que comparten todas las filas de configuración y el formato de su copia en el disco.

### 1.3 Qué cambia respecto de DAT-0929 por la firma del 2026-10-18
| Pieza de DAT-0929 | En la v1 mínima | Motivo |
|---|---|---|
| Migración «TODAS», partes B y C, revisión de 30 días, `MIGRACION`, `FechaRevision`, `Transferida`, Q14, Q15, Q16, Q16-S, Q19, Q19-a, Q20 y C-MEM08 | **Retiradas** | DB7-02 |
| `BitacoraSistema` | No se crea: va en `BitacoraSeguridad` | DB7-03 |
| `Empresas.UsuariosAutorizados` y Q5-c | Retirados: el cupo es el de la licencia | ADR-58, punto 9 |
| Q5 contada con las filas y `sp_getapplock` | **Sustituida:** el consumo sale del padrón y serializa la fila del padrón | ADR-83, punto 2, y DB7-05 |
| Sello solo de cuenta | **Dos niveles** | DB7-05 |
| Invitaciones (Q4, Q11, Q12 y F2-A), cadena de hashes, P7-C, TRZ-07 y TRZ-10 | Fase 2 | DB7-01 y P-D0-05 de BP3 |
| `AprobacionesFormato` (Q17) | Fuera de D0 | M-3 solo se verifica; R-12 en P-D0-03 de BP3 |
| `Reportes` global (`ReportesService.cs:105-149`: cualquier ADMIN edita o borra cualquier definición) | **Reportes por empresa** (`Reportes.EmpresaCodigo`), sección 2.6 | SD0-01 (Alta, H-06); opción (a) de P-D0-08 |

---

## 2. Tablas y relaciones

### 2.1 Diagrama (v1)
```
Usuarios (CUENTA, existente)
  **Codigo** nvarchar(30), Descripcion, PasswordHash, Nivel {SUPER|USER}   ← CK nuevo: deja de admitir ADMIN
  Inhabilitado, DebeCambiarClave, IntentosFallidos, BloqueadoHasta, SesionId, SesionInicio, SesionExpira, SesionOrigen,
  SesionesRevocadas, UltimoAcceso, FechaCreacion, EmpresaDefault, SelloHabilitacion varbinary(512) (sello de cuenta v2)
  + SelloSeguridad, SesionTokenId, SesionActividad      (#57)
  + SesionEmpresa nvarchar(30) NULL                     nuevo (ADR-36)
  + FallosVentana int, FallosVentanaInicio datetime2(3) nuevo (SES-13; DAT-0929 Q18)
  − RestringirSucursal, SucursalDefault                 retiradas por accesos --convertir (EmpresaDefault: ver la discrepancia DX-3)

Empresas (existente) + AdministradaPorSuper bit NOT NULL DEFAULT 0 (MEM-06)

UsuariosEmpresas (MEMBRESÍA)                             nueva
  **UsuarioCodigo**→Usuarios, **EmpresaCodigo**→Empresas, Nivel {ADMIN|USER}, SucursalDefault, RestringirSucursal,
  Estado {HABILITADA|SUSPENDIDA|BAJA}, FechaEstado, CuentaEstado, MotivoEstado, VersionPrivilegios (monótona),
  SesionesRevocadas, UltimoAcceso, Origen {MANUAL|VINCULO|CONVERSION}, FechaAlta, UsuarioAlta,
  FechaModificacion, UsuarioModificacion, SelloMembresia varbinary(512)
EmpresasPerfiles, EmpresasPerfilesPermisos, UsuariosEmpresasPerfiles, UsuariosEmpresasPermisos   nuevas
Perfiles, PerfilesPermisos, UsuariosPerfiles, UsuariosPermisos                                    retiradas

BitacoraSeguridad (existente) + EmpresaActua, ActorNivel, Categoria, ValorAnterior, ValorNuevo
  (la columna Empresa existente = empresa AFECTADA; ver DX-6)
CategoriasSeguridad, CatalogoEventosSeguridad            nuevas
Configuracion: Licencia.PadronSellos en el formato v2; clave nueva Accesos.Modelo

Reportes (existente) + EmpresaCodigo nvarchar(30) NULL → Empresas   (NULL = reporte del sistema; SD0-01, 2.6)
ConversionReportes (**EmpresaCodigo, IdOriginal**, IdNuevo, ReglasActualizadasUtc)   nueva, solo la escribe el verbo (7.3)
```

### 2.2 `dbo.UsuariosEmpresas`
| Columna | Tipo | Nulo | Regla |
|---|---|---|---|
| `UsuarioCodigo` | `nvarchar(30)` | No | FK → `Usuarios`, NO ACTION: una cuenta con membresías no se borra (ADR-08) |
| `EmpresaCodigo` | `nvarchar(30)` | No | FK → `Empresas`, NO ACTION |
| `Nivel` | `varchar(5)` | No | `ADMIN` o `USER` |
| `SucursalDefault` | `nvarchar(30)` | Sí | El tipo de la columna que sustituye (`SistemaDbContext.cs:35`) |
| `RestringirSucursal` | `bit` | No | Por omisión 0; si vale 1, exige sucursal |
| `Estado` | `varchar(10)` | No | `HABILITADA`, `SUSPENDIDA` o `BAJA` |
| `FechaEstado`, `CuentaEstado`, `MotivoEstado` | `datetime2(0)`, `nvarchar(30)`, `nvarchar(200)` | Sí | Obligatorios fuera de `HABILITADA`, con un motivo de 10 o más caracteres |
| `VersionPrivilegios` | `int` | No | ≥ 1; nunca retrocede (51619) |
| `SesionesRevocadas` | `datetime2(3)` | Sí | Revocación en esta empresa (REV-03) |
| `UltimoAcceso` | `datetime2(0)` | Sí | Último ingreso a esta empresa (ADM-03) |
| `Origen` | `varchar(10)` | No | `MANUAL`, `VINCULO` o `CONVERSION` |
| `FechaAlta`, `UsuarioAlta` | `datetime2(0)`, `nvarchar(30)` | No | UTC |
| `FechaModificacion`, `UsuarioModificacion` | `datetime2(0)`, `nvarchar(30)` | Sí | — |
| `SelloMembresia` | `varbinary(512)` | Sí | El sello de la membresía (3.2) |

- **PK agrupada** `(UsuarioCodigo, EmpresaCodigo)`.
- **Volumen:** con 50 cuentas y 5 empresas son 250 filas de unos 700 B (menos de 200 KB). Con 1 000 cuentas y 5 empresas, unos 3,5 MB (*inferido*).

### 2.3 Hijas
| Tabla | PK | FK |
|---|---|---|
| `EmpresasPerfiles` (`Descripcion nvarchar(100)`, `Inhabilitado bit`) | `(EmpresaCodigo, Codigo)` | → `Empresas`, NO ACTION |
| `EmpresasPerfilesPermisos` (`Opcion nvarchar(50)`, `Nivel int`, `Acciones int`) | `(EmpresaCodigo, PerfilCodigo, Opcion)` | → `EmpresasPerfiles`, CASCADE |
| `UsuariosEmpresasPerfiles` | `(UsuarioCodigo, EmpresaCodigo, PerfilCodigo)` | → `UsuariosEmpresas`, NO ACTION; `(EmpresaCodigo, PerfilCodigo)` → `EmpresasPerfiles`, **NO ACTION** (PRV-03) |
| `UsuariosEmpresasPermisos` (`Opcion nvarchar(50)`, `Nivel int NOT NULL`, `Acciones int NOT NULL`) | `(UsuarioCodigo, EmpresaCodigo, Opcion)` | → `UsuariosEmpresas`, NO ACTION |

**Por qué NO ACTION al asignar perfiles** (hoy, `Perfiles` → `UsuariosPerfiles` es CASCADE):
- Si borrar un perfil quitara sus asignaciones en cascada, los privilegios cambiarían **sin subir la versión**, y la caché de permisos por (cuenta, empresa, versión) quedaría vieja.
- El servicio ya rechaza borrar un perfil asignado (`4e094323:src/GPOS.Core/Sistema/PermisosService.cs:96-105`). El motor pasa a garantizarlo.

### 2.4 Aislamiento por tabla
| Tabla | Regla |
|---|---|
| `UsuariosEmpresas`, hijas y `EmpresasPerfiles*` | La empresa forma parte de la PK. El ADMIN siempre filtra por `@empresa` de la sesión. Las FK compuestas impiden cruces |
| `Usuarios` | Global. El ADMIN solo ve tres indicadores (ADM-03, Q3) |
| `BitacoraSeguridad` | El ADMIN solo ve `Empresa = @empresa` y las categorías visibles (Q8-a), sin `EmpresaActua` |
| `Configuracion` (padrón) | Solo la API. El ADMIN obtiene únicamente el consumo de su empresa |

### 2.5 Columnas globales de hoy
| Columna de `Usuarios` | Destino |
|---|---|
| `Nivel` | Queda con `SUPER` o `USER`. La conversión pasa `ADMIN` a `USER` y crea `CK_Usuarios_Nivel` (IDN-03) |
| `RestringirSucursal` (con `DF_Usuarios_RestringirSucursal`) y `SucursalDefault` | Pasan a la membresía según P-D0-07 de BP3 (7.3). Se retiran en el verbo |
| `EmpresaDefault` | Lo usa la conversión (P-D0-07). Después se **conserva** como preferencia, aunque BP3 11.1.2 pide retirarla: ver DX-3 |
| `SesionesRevocadas` | Queda: revocación global (REV-04) |
| `IntentosFallidos` (con `DF_Usuarios_IntentosFallidos`) | **Se retira en el verbo** (E-SW-4, sección 14 de BP3). D2 lo sustituye por el contador por (cuenta, IP) en memoria y el global `FallosVentana*` (SES-13). No se borra antes de convertir, porque el reverso de 7.2 exige que la versión anterior siga funcionando |
| `SelloHabilitacion` | Queda, con el sello de cuenta v2 |

Las tablas `Perfiles`, `PerfilesPermisos`, `UsuariosPerfiles` y `UsuariosPermisos` **se borran en el verbo**, después de la prueba de equivalencia (DB7-02, sin convivencia).

---

### 2.6 Reportes por empresa (SD0-01; opción (a) de P-D0-08)
**Hecho verificado.** Hoy las definiciones de `dbo.Reportes` son globales:
- `GuardarAsync` modifica cualquier `Id`, también un reporte del sistema;
- `EliminarAsync` borra cualquiera que no sea del sistema y sus permisos `rpt:{id}` en todas partes (`4e094323:src/GPOS.Core/Servicios/ReportesService.cs:105-149`);
- las rutas piden `RequiereAdmin`.

Con el ADMIN por empresa, esto deja abierto H-06 (Alta).

**Modelo (a).**

| Pieza | Regla |
|---|---|
| `Reportes.EmpresaCodigo nvarchar(30) NULL` | FK a `Empresas` (NO ACTION). **NULL = reporte del sistema** (`DelSistema = 1`, lo mantienen la semilla o el SUPER). Con valor: reporte personalizado de esa empresa |
| `CK_Reportes_Ambito` | `(DelSistema = 1 AND EmpresaCodigo IS NULL) OR (DelSistema = 0 AND EmpresaCodigo IS NOT NULL)`. Lo crea el verbo **después** de asignar las filas de hoy (7.3, paso 8 h) |
| `ReportesColumnas` | Sin cambios: hereda el ámbito por `ReporteId` (FK CASCADE que ya existe) |
| Lectura (ADMIN y USER) | `WHERE EmpresaCodigo = @empresa OR EmpresaCodigo IS NULL`, siempre con la empresa del token. Un `Id` de otra empresa responde 404 sin distinguir (PRV-07, QA-20) |
| Escritura (ADMIN) | Solo filas con `EmpresaCodigo = @empresa`. Un reporte del sistema **no** lo modifica el ADMIN: lo **duplica** en su empresa (copia con `Codigo = NULL`, para que `ReportesSemilla.SembrarAsync` no lo tome por instalado, `ReportesSemilla.cs:364-369`) |
| Escritura (SUPER) | Reportes del sistema y de cualquier empresa (`/api/super`) |
| Semilla (`ReportesSemilla`) | Sin cambios de regla: solo toca `DelSistema = 1`, que ahora implica `EmpresaCodigo IS NULL`. Los reportes del sistema que el ADMIN modificó antes de la v1 se conservan como están (la semilla ya los respeta) y quedan del SUPER |
| Permisos `rpt:{id}` | Se guardan por membresía y por perfil de empresa (2.3), así que un `rpt:{id}` solo vale en la empresa de la sesión. Al borrar un reporte, se borra `rpt:{id}` **solo** en `EmpresaCodigo` del reporte y se sube `VersionPrivilegios` de los miembros afectados (SD0-11) |
| Índices | En `Reportes`, **ninguno nuevo**: son cientos de filas y la lectura por empresa recorre la tabla en menos de 1 ms (*inferido*). **Corrección de 4.4:** el borrado de `rpt:{id}` sí existe (`ReportesService.cs:131-135`), y justifica `IX_UsuariosEmpresasPermisos_Empresa_Opcion` |
| `rptsis.Reporte` v2 | Agrega `EmpresaCodigo`. La API de reportes filtra `EmpresaCodigo = @empresa OR EmpresaCodigo IS NULL` con la empresa de la introspección. `rptsis.ReporteColumna` se lee unida a `rptsis.Reporte`. Es la misma versión mayor de `contrato-rptsis` |
| Conversión del DEMO | 7.3, paso 3 b: cada reporte personalizado de hoy (`DelSistema = 0`) queda en la **primera** empresa habilitada (por `Prioridad`, `Codigo`), con su mismo `Id`. Así siguen valiendo sus permisos, sus reglas de notificación y la evidencia de `audit.Exportacion` (ADR-111). Se **copia** a las demás empresas con un `Id` nuevo, registrado en `ConversionReportes`; los permisos `rpt:{original}` y los `Detalle = "id:{original}"` de esas empresas se reasignan al `Id` nuevo |

- **Reglas de notificación** (`NotificacionesReglas.ReporteId`, en la base de cada empresa, `EmpresaDbContext.cs:333`).
  - No se pueden reasignar en la transacción de `GPOS_SYSDATA`: están en otra base.
  - El verbo las reasigna **después** del commit, empresa por empresa, de forma idempotente con `ConversionReportes` (`ReglasActualizadasUtc`), y se puede repetir.
  - Mientras tanto, la regla apunta a un reporte de otra empresa: la lectura por empresa responde 404 y la regla se suspende (Q7). **Falla cerrado.**
- **Volumen:** cientos de reportes × N empresas en el DEMO; menos de 1 MB (*inferido*).
- **Costo:** de 0,3 a 0,5 sp entre D1 y D5 (estimación del auditor).

**Si el propietario elige (b)** (el diseñador solo para el SUPER en la v1):
- **No hay cambio de datos:**
  - sin `Reportes.EmpresaCodigo`;
  - sin `ConversionReportes`;
  - sin `CK_Reportes_Ambito`;
  - sin el paso 3 b ni el 11 del verbo;
  - `rptsis.Reporte` sin cambios.
- `POST` y `DELETE /api/admin/reportes` pasan a `RequiereSuper`, en BP3.
- Los permisos `rpt:{id}` siguen siendo por membresía (2.3): la visibilidad ya es por empresa, pero la **definición** es común a todas.
- El índice `IX_UsuariosEmpresasPermisos_Empresa_Opcion` se mantiene igual, por el borrado del SUPER.
- **Qué rompe:** el ADMIN deja de diseñar reportes hasta la fase 2.

## 3. Sello en dos niveles y padrón por (cuenta, empresa) (DB7-05; BP3 8.4)

### 3.1 Sello de cuenta v2
- **Propósito:** `GPOS.Usuarios.Sello.v2`. Un sello v1 no verifica con este lector: falla cerrado.
- **Dónde:** `dbo.Usuarios.SelloHabilitacion` (`varbinary(512)`, sin cambiar la columna).

```json
{ "v": 2, "i": "<InstalacionId>", "c": "<Codigo>", "S": false, "x": false,
  "t": "<HabilitadoUtc, ms>", "k": "<SHA-256 hex del PasswordHash>", "f": null }
```

- **Contenido:** el de BP3 8.4.
  - `S`: si la cuenta es SUPER.
  - `x`: inhabilitada; siempre `false`, porque solo se sellan cuentas habilitadas.
  - `k`: huella de la contraseña (DL-05 (a)).
  - `f`: factor. **Solo en el SUPER** (`true`/`false`); `null` en las demás cuentas. Ver DX-4.
- **Salen del sello:** el nivel completo y la sucursal, que pasan a la membresía.
- **Tamaño:** unos 300 B protegido (*inferido*). La prueba de SL de la cuenta más larga se repite.

### 3.2 Sello de membresía v1
- **Propósito:** `GPOS.Membresias.Sello.v1`, con el subpropósito `{Codigo}|{Empresa}` (BP3 8.4). Un sello copiado a otra fila no se puede ni descifrar.
- **Dónde:** `dbo.UsuariosEmpresas.SelloMembresia`.

```json
{ "v": 1, "i": "<InstalacionId>", "c": "<UsuarioCodigo>", "e": "<EmpresaCodigo>", "n": "ADMIN",
  "st": "HABILITADA", "r": true, "s": "<SHA-256(empresa ‖ 0x1F ‖ sucursal)[0..8] hex, o null>", "t": "<SelladoUtc, ms>" }
```

- **Cuándo se sella** (BP3): en **toda** transición de estado (`HABILITADA` ↔ `SUSPENDIDA` → `BAJA`) y en todo cambio de nivel, de restricción o de sucursal restringida.
  - Un `UPDATE` por SQL que reactiva una fila deja `st = SUSPENDIDA` en el sello: no coincide con la fila y responde 401 `credenciales`.
- **No cubre** perfiles ni excepciones (ADR-83, «Alcance»; SEG-L2-04).
- **Tamaño:** unos 330 B protegido (*inferido*).

### 3.3 Padrón v2
- **Dónde:** la misma fila `Licencia.PadronSellos` y el mismo archivo `padron`.
- **Propósito:** `GPOS.Usuarios.Padron.v2`.
- **Versión:** continúa la del v1 (`v1.Version + 1`), así que «prevalece la mayor versión que verifique» sigue valiendo entre la base y el disco.

```json
{ "v": 2, "c": "Licencia.PadronSellos", "i": "<InstalacionId>", "n": <Version>,
  "a": { "<CODIGO>": { "h": "<b64 SHA-256(sello de cuenta)[0..12]>", "S": false } },
  "m": { "<CODIGO>|<EMPRESA>": { "h": "<b64 SHA-256(sello de membresía)[0..12]>", "n": "A", "st": "H" } } }
```

- **`a` (cuentas):** una entrada por **cada** cuenta habilitada y sellada, sea SUPER o no. BP3 8.4 ya lo dice así. El texto firmado de DB7-05 habla de «entradas SUPER de cuenta»: lo resuelve P-D0-D01.
- **`m` (membresías):** una entrada por membresía `HABILITADA` (`st = H`) o `SUSPENDIDA` (`st = S`) sellada.
  - La **`BAJA` sale del padrón**: no tiene derechos y así el padrón no crece con las bajas. El sello de la fila queda con `st = BAJA`. Ver DX-5.
- **Volumen:** unos 100 B por membresía; con 1 000 cuentas × 5 empresas, unos 0,7 MB protegido (BP3, R-DB7-06). Cabe en `nvarchar(max)` (1.2).

| Acción | Cambio en el padrón (siempre por diferencias, en la transacción del sello; nunca desde las filas) |
|---|---|
| Alta, vínculo o reactivación | `m(c,E).st = H`, **con control del cupo de E** |
| Suspensión | Se vuelve a sellar; `m(c,E).st = S` |
| Baja | Se vuelve a sellar la fila con `BAJA` y se quita `m(c,E)` |
| Volver a dar de alta una fila en `BAJA` | Reutiliza la fila, la versión sube (51619), sin privilegios; `m(c,E).st = H` con el cupo |
| Cambio de nivel o de sucursal | Se vuelve a sellar y se reemplaza `m` (el cupo no cambia) |
| Inhabilitar una cuenta | Se quita `a(c)`; las `m` se quedan y no cuentan (BP3) |
| Habilitar una cuenta | `a(c)`, con el cupo de **cada** E con `m(c,E).st = H`, todo o nada |
| Contraseña, factor o restablecimiento | Se vuelve a sellar la cuenta y se reemplaza `a(c)` |
| Legitimación por cuenta, o por (cuenta, empresa) con `--empresa` | Con el control del cupo (ADR-83, punto 5) |
| Purga | Retira `a` o `m` sin fila |

### 3.4 Consumo por empresa
```
consumo(E) = |{ (c,E) ∈ padrón.m : st = H  ∧  c ∈ padrón.a  ∧  ¬padrón.a[c].S }|
cupo(E)    = IEstadoLicencia.CupoUsuarios(E)        (0 sin licencia, LV-17)
EnExceso(E) ⇔ consumo(E) > cupo(E)
```
- Hoy el código llama `CupoUsuarios(null)`, que es la suma de todas las empresas (`4e094323:src/GPOS.Core/Sistema/UsuariosService.cs:409`; `Usuarios/SellosService.cs:261` y `:424`; `Licencia/EstadoLicenciaService.cs:190-197`). En la v1, toda llamada pasa la empresa, salvo la vista del SUPER.
- **Confirmación pedida por BP3 11.1.7:**
  - el cupo se serializa con la fila del padrón (`UPDLOCK, HOLDLOCK` en una transacción `SERIALIZABLE`; `4e094323:src/GPOS.Core/Consultas/Sistema/Usuarios/ConsultasSellos.cs:21`);
  - **no se usa `sp_getapplock`**: un segundo recurso agregaría otro orden de bloqueos sin ninguna ganancia.

### 3.5 Por qué un `UPDATE` directo no amplía el cupo (la clase SEG-L2-01)
| # | Intento por SQL, sin el anillo | Resultado |
|---|---|---|
| 1 | `UPDATE … SET Estado = 'HABILITADA'` en una membresía suspendida | No entra (`credenciales`): el sello dice `SUSPENDIDA`. No consume: `m.st = S` |
| 2 | `INSERT` de membresías en E | No entra (no tiene sello) y no consume (no tiene `m`) |
| 3 | Copiar un sello a otra cuenta o a otra empresa | No se descifra (subpropósito) y no coincide (`c`, `e`) |
| 4 | «Apagar y encender»: suspender por SQL, dar un alta por la API y reactivar por SQL | El alta se rechaza: la suspensión por SQL no cambia `m.st` y el consumo no baja |
| 5 | Reponer un par antiguo (hash, sello) de una cuenta | No verifica: `a(c)` fija la huella vigente. **Sin `a` para los que no son SUPER, este caso entraría** (P-D0-D01) |
| 6 | `UPDATE … SET Nivel = 'ADMIN'` en la membresía | Falla cerrado: la fila no coincide con el sello ni con `m.n` |
| 7 | `UPDATE Usuarios SET Nivel = 'SUPER'` | No entra: no coincide con `S` (TN 7(d)) |
| 8 | Reponer un padrón o una base anterior | Prevalece la versión mayor, la del disco (SEG-L2-07, SL-F1 (a)) |
| 9 | **Reponer en la fila las columnas y el sello de antes de una baja o de un cambio de nivel**, cuando estaba `HABILITADA` (incluso como ADMIN) (SD0-03) | No entra (401 `credenciales`) y no consume. El sello descifra y coincide con la fila repuesta, pero el padrón **no** tiene `m(c,E)` (la baja salió del padrón, DX-5), o la tiene con otra huella u otro nivel. La definición de `Valido` de 3.6 exige la entrada con la misma huella, el mismo nivel y `st = H` |

- **Contraejemplo de un solo nivel** (el motivo firmado en DB7-05): con el sello solo de cuenta y el consumo contado con las filas `HABILITADA`, el caso 2 suma consumo en E sin tocar ningún MAC.
- **Residual:** quien tenga `sysadmin` y el anillo puede rehacer los sellos (CP-4, AP-04).

**Residual sin sello (SD0-14; se acepta de forma expresa con la firma).** Quien tenga escritura en `GPOS_SYSDATA` cambia estas columnas sin rehacer ningún MAC. Ninguna amplía el cupo, sube el nivel ni da una membresía:

| Columna | Efecto | Mitigación |
|---|---|---|
| `Usuarios.DebeCambiarClave` | Se salta el cambio forzado | El sello cubre la huella de la contraseña: no cambia cuál es |
| `Usuarios.SesionesRevocadas`, `UsuariosEmpresas.SesionesRevocadas` | Vuelven a valer tokens revocados (hasta su vencimiento) | Opcional en `verificar`: avisar de una revocación anterior a la última registrada en la bitácora (`SESIONES_*_REVOCADAS`) |
| `BloqueadoHasta`, `FallosVentana*` | Ayudan a probar contraseñas | Lo limita el contador (cuenta, IP) en memoria |
| `Empresas.AdministradaPorSuper` | Cambia quién administra según MEM-06 | Es una marca, no da privilegio. V-4 la revisa |
| Perfiles y excepciones | Permisos granulares | SEG-L2-04, ya aceptado (ADR-83, «Alcance») |

### 3.6 Verificación en cada petición (BP3 6.1 y 6.3)
- Q1 lee las columnas y los dos sellos **en cada petición**, por ADO.NET, en un solo viaje.
- El **resultado criptográficos** (`Unprotect` más la comparación con el padrón) se memoriza por `(SHA-256 de los bytes del sello, versión del padrón, época del anillo)` (SD0-13; BP3 6.3). La época sube con toda revocación o reprotección del anillo (ADR-79), y así un sello protegido con una llave revocada deja de valer en el acto. Máximo de 20 000 entradas y 5 minutos.
- La comparación del contenido con la fila se hace **siempre**. Esto coincide con BP3 6.1.
- **`Valido` de la membresía (SD0-03): se cumplen todas estas condiciones; cualquier otro caso da `FueraDePadron` o `SelloInvalido` y 401 `credenciales`.**
  1. El sello descifra con el propósito `GPOS.Membresias.Sello.v1` y el subpropósito `{c}|{E}`.
  2. `c`, `e`, `n`, `st`, `r` y `s` del contenido son iguales a la fila.
  3. Existe `m(c,E)` en el padrón verificado, con `h = SHA-256(bytes del sello)[0..12]`, el mismo `n` y `st = H`.
  4. Existe `a(c)` y no es SUPER. El sello de cuenta es `Valido`, con su propia regla (`a(c).h` igual).
- **`Valido` de la cuenta:** el sello descifra, sus campos coinciden y existe `a(c)` con la huella igual y `S` igual (como hoy, `RevocacionSesiones.cs:175`).
- **Dónde se aplica:** la misma función la usan Q1 (paso g de BP3 6.1), Q2 (la lista de `identificar`), el autorizante (SD0-06) y Q9 y Q10 (el dominio).
- **Consulta que lo comprueba.** Los datos salen de Q1 (conjunto 1: `SelloMembresia`, `Estado`, `Nivel`, `RestringirSucursal`, `SucursalDefault`) y del padrón vigente. El predicado de las condiciones 1 a 4 se evalúa en C#, porque el padrón está protegido y no se puede leer en SQL. Para `verificar` (V-1) y la prueba del caso 9 en D3:
  ```sql
  -- Candidatas: filas que dicen dar acceso. C# marca MEMBRESIA_SIN_SELLO cada una cuyo predicado 1 a 4 no se cumple.
  SELECT ue.UsuarioCodigo, ue.EmpresaCodigo, ue.Nivel, ue.Estado, ue.RestringirSucursal, ue.SucursalDefault, ue.SelloMembresia
    FROM dbo.UsuariosEmpresas ue
   WHERE ue.Estado = 'HABILITADA';       -- recorrido de cientos de filas; solo en verificar
  ```
  **Prueba de D3 (caso 9):**
  1. Guardar la fila y el sello de una membresía ADMIN `HABILITADA`.
  2. Darla de baja por la API.
  3. Reponer por SQL la fila y el sello guardados.
  4. Comprobar que Q1 da 401 `credenciales`, que Q2 no lista la empresa, que el consumo no cambia y que V-1 la informa.
- El padrón tiene su caché de 15 s, que `TrasConfirmar` vacía en la instancia que escribe (`4e094323:src/GPOS.Core/Sistema/Usuarios/PadronSellos.cs:316-321`). Fuera de la API, el padrón solo lo cambia el verbo de consola, que exige la API detenida (7.3), o un `sysadmin` (residual).

### 3.7 Orden de bloqueos en `GPOS_SYSDATA`
El orden único de `CLAUDE.md` es el de las bases de empresa, y DB-7 no toma ninguno de esos recursos. Dentro de `GPOS_SYSDATA`, este orden amplía el de ADR-83, el de D81-08 y el de BP3 8.4 (padrón → `Usuarios` → `UsuariosEmpresas` → bitácora):

```
[RestauracionSistema (solo la reconciliación)] → Configuracion: Licencia.InstalacionId + Licencia.PadronSellos (UPDLOCK, HOLDLOCK)
 → Usuarios (UPDLOCK; orden ordinal del código) → UsuariosFactor
 → hijas de la membresía (UsuariosEmpresasPerfiles / UsuariosEmpresasPermisos)  ← solo en la BAJA, antes del padre (51623)
 → UsuariosEmpresas (orden ordinal de (cuenta, empresa)) → hijas (en los demás casos)
 → EmpresasPerfiles / EmpresasPerfilesPermisos → Empresas (AdministradaPorSuper) → INSERT en BitacoraSeguridad
```

- **Toda** transacción de administración de accesos empieza tomando la fila del padrón, aunque no cambie ningún sello (por ejemplo, Q6). Así quedan en serie y no hay interbloqueos entre Q6 y Q13, ni por las hijas de una baja.
  - Son menos de 20 operaciones al día (*inferido*, DAT Q5).
  - *Alternativa descartada:* un orden por tabla. Aparece el ciclo X/S sobre `EmpresasPerfiles` entre Q6 y la FK de Q13.
- El **inicio de sesión** no toma el padrón. Escribe `Usuarios` y, aparte, `UsuariosEmpresas.UltimoAcceso` y `INGRESO_EMPRESA` en sentencias propias.
- **Q1 frente a las transacciones de administración (SD0-16, disponibilidad).**
  - Los `Protect` (sellos y padrón) se calculan **antes** de tomar los bloqueos de las filas, con los campos nuevos. Así la transacción solo escribe, en unos milisegundos.
  - D1 mide la espera de Q1 detrás de un alta.
  - Si pasa de 200 ms, se evalúa `READ_COMMITTED_SNAPSHOT` en `GPOS_SYSDATA`: no cambia la decisión, porque la fila confirmada anterior también tiene su sello.
- **Residual:** la regla de notificación suspendida (AIS-06) escribe en dos bases y no es atómica (R-8).

---

## 4. Restricciones, consultas e índices

### 4.1 Restricciones y disparadores (franja usada: 51619 a 51625; siguiente libre: 51626)
| Objeto | Regla | Error |
|---|---|---|
| `CK_UsuariosEmpresas_Nivel`, `_Estado`, `_Origen`, `_Version`, `_Sucursal` | Dominios; versión ≥ 1; la restricción exige sucursal | — |
| `CK_UsuariosEmpresas_EstadoMotivo` | Fuera de `HABILITADA`: fecha, cuenta y motivo `IS NOT NULL`, de 10 o más caracteres. *Ojo:* `LEN(NULL)` deja pasar el `CHECK` | — |
| `TR_UsuariosEmpresas_Version` | La versión no baja, **también al reutilizar una fila en `BAJA`**. El estado, el nivel o la sucursal no cambian sin subirla. La PK, `Origen` y el alta no cambian | 51619 |
| `TR_UsuariosEmpresas_SinBorrado` | `INSTEAD OF DELETE`: no se borran membresías (además de `DENY DELETE`) | 51620 |
| `TR_UsuariosEmpresas_Version` (misma) | Una fila que **queda** en `BAJA` no puede tener perfiles ni excepciones. El servicio los borra antes (3.7) | 51623 |
| `TR_UsuariosEmpresasHijas_SinBaja` (en las dos hijas, `AFTER INSERT`) | No se asignan perfiles ni excepciones a una membresía en `BAJA` | 51623 |
| `TR_UsuariosEmpresas_SinSuper` (`AFTER INSERT, UPDATE`) | Una membresía no dada de baja de una cuenta con `Nivel = 'SUPER'` | 51624 |
| `TR_Usuarios_SuperSinMembresias` (`AFTER UPDATE`, solo `IF UPDATE(Nivel)`) | Pasar a SUPER una cuenta con membresías no dadas de baja | 51625 |
| `CK_Usuarios_Nivel` | `Nivel IN (N'SUPER', N'USER')`. Lo crea el verbo | — |
| `FK_BitacoraSeguridad_Evento` y `FK_BitacoraSeguridad_EventoCategoria` (`WITH NOCHECK`) | Catálogo cerrado validado por el motor (ADR-37) | — |
| `CK_BitacoraSeguridad_EmpresaCategoria` | `ACCESO` y `MEMBRESIA` exigen `Empresa`. **Excepción:** `ACCESO_EMPRESA_DENEGADO` (DX-7) | — |
| `CK_BitacoraSeguridad_IngresoSuper` | `INGRESO_SUPER` exige un motivo de 10 o más caracteres | — |
| `CK_BitacoraSeguridad_Json` | `ISJSON` (compatibilidad mínima 130, CB-01) | — |

- **Errores siguientes libres de la franja:** 51626 a 51638. 51621 (equivalencia) y 51622 (precondiciones y reverso) son del verbo (7.3).
- **El costo de 51625 en cada inicio de sesión es nulo:** el inicio de sesión no actualiza `Nivel`, así que `IF UPDATE(Nivel)` sale en el acto.
- **MEM-06** queda en el servicio, con el padrón, y en `verificar`.

### 4.2 Q1 a Q13 (numeración de DAT §4.2; criterios de BP3 12.1)
Mediciones en el banco de T-28 y T-57 (`GPOST_B9_AFINIDAD=auto`), con un DEMO de 50 cuentas × 5 empresas y la variante de 1 000 × 5. Las lecturas lógicas son *inferidas*; las mide D6.

**Q1. `EstadoAcceso` en cada petición, sin caché, por ADO.NET (MD-09).** Un lote con uno o tres conjuntos (`NextResult`), en `READ COMMITTED` y con `CommandTimeout` de 2 s.
```sql
-- Conjunto 1 (siempre). @usuario, @empresa: nvarchar(30)
SELECT u.Codigo, u.Inhabilitado AS CuentaInhabilitada, u.Nivel AS NivelCuenta, u.PasswordHash, u.SelloHabilitacion AS SelloCuenta,
       u.SesionId, u.SesionTokenId, u.SesionInicio, u.SesionExpira, u.SesionActividad, u.SesionEmpresa, u.SesionesRevocadas,
       u.SelloSeguridad, u.DebeCambiarClave,
       CONVERT(bit, CASE WHEN u.Nivel = N'SUPER' AND f.SecretoCifrado IS NOT NULL THEN 1 ELSE 0 END) AS FactorAlta,
       e.Codigo AS Empresa, e.Inhabilitado AS EmpresaInhabilitada,
       ue.Estado, ue.Nivel, ue.VersionPrivilegios, ue.SesionesRevocadas AS RevocadasEmpresa,
       ue.SucursalDefault, ue.RestringirSucursal, ue.SelloMembresia
  FROM dbo.Usuarios u
  LEFT JOIN dbo.UsuariosFactor f    ON f.UsuarioCodigo = u.Codigo
  LEFT JOIN dbo.Empresas e          ON e.Codigo = @empresa
  LEFT JOIN dbo.UsuariosEmpresas ue ON ue.UsuarioCodigo = u.Codigo AND ue.EmpresaCodigo = @empresa
 WHERE u.Codigo = @usuario;
-- Conjuntos 2 y 3: solo con la membresía HABILITADA y la versión distinta de @versionEnCache (también para el ADMIN: BP3 6.1, paso 5)
IF EXISTS (SELECT 1 FROM dbo.UsuariosEmpresas
            WHERE UsuarioCodigo = @usuario AND EmpresaCodigo = @empresa AND Estado = 'HABILITADA'
              AND (@versionEnCache IS NULL OR VersionPrivilegios <> @versionEnCache))
BEGIN
    SELECT Opcion, Nivel, Acciones FROM dbo.UsuariosEmpresasPermisos WHERE UsuarioCodigo = @usuario AND EmpresaCodigo = @empresa;
    SELECT pp.Opcion, pp.Nivel, pp.Acciones
      FROM dbo.UsuariosEmpresasPerfiles up
      JOIN dbo.EmpresasPerfiles p          ON p.EmpresaCodigo = up.EmpresaCodigo AND p.Codigo = up.PerfilCodigo AND p.Inhabilitado = 0
      JOIN dbo.EmpresasPerfilesPermisos pp ON pp.EmpresaCodigo = up.EmpresaCodigo AND pp.PerfilCodigo = up.PerfilCodigo
     WHERE up.UsuarioCodigo = @usuario AND up.EmpresaCodigo = @empresa;
END
```
- **El factor:** su condición es la de la fase A (`SecretoCifrado IS NOT NULL`, `f165d1fa:src/GPOS.Core/Consultas/Sistema/SegundoFactor/ConsultasSegundoFactor.cs:32-35`).
  - Va en la misma ida para no hacer un segundo viaje del SUPER.
  - Es **una búsqueda por PK más** que las tres de BP3 (DX-1).
- **Plan:** cuatro búsquedas por PK agrupada, de 9 a 12 lecturas en el conjunto 1. Sin la versión en caché, de 20 a 60 lecturas más, por prefijo de PK.
- **Criterio (BP3 12.1):**
  - **p95 ≤ 2 ms** con la versión en caché, y **p95 ≤ 4 ms** sin ella;
  - 12 o menos lecturas lógicas en el conjunto 1;
  - T-28 y T-57 por debajo de sus topes de 32,8 y 31,6 ms;
  - se mide en el cliente, del envío al último `Read`, con 10 000 iteraciones en caliente.
- **Si la lectura falla:** 503 `ACCESO_NO_DISPONIBLE` (EventId 4724 de BP3).

**Q2. Empresas de la persona.**
```sql
SELECT e.Codigo, e.Descripcion, ue.Nivel, ue.Estado, ue.RestringirSucursal, ue.SucursalDefault, ue.SelloMembresia
  FROM dbo.UsuariosEmpresas ue JOIN dbo.Empresas e ON e.Codigo = ue.EmpresaCodigo AND e.Inhabilitado = 0
 WHERE ue.UsuarioCodigo = @usuario AND ue.Estado = 'HABILITADA'
 ORDER BY e.Prioridad, e.Descripcion;
-- Q2-S (SUPER): SELECT Codigo, Descripcion FROM dbo.Empresas WHERE Inhabilitado = 0 ORDER BY Prioridad, Descripcion;
```
- C# descarta, sin decirlo, las membresías cuyo sello no verifica (MEM-02).
- **Plan:** prefijo de la PK.
- **Criterio:** p95 ≤ 5 ms.

**Q3. Miembros de A y el último ADMIN.**
```sql
SELECT ue.UsuarioCodigo, u.Descripcion, ue.Nivel, ue.Estado, ue.FechaEstado, ue.MotivoEstado, ue.UltimoAcceso, ue.SesionesRevocadas,
       ue.Origen, ue.VersionPrivilegios, ue.RestringirSucursal, ue.SucursalDefault,
       u.Inhabilitado AS CuentaInhabilitada, u.BloqueadoHasta, u.DebeCambiarClave
  FROM dbo.UsuariosEmpresas ue JOIN dbo.Usuarios u ON u.Codigo = ue.UsuarioCodigo
 WHERE ue.EmpresaCodigo = @empresa AND ue.Estado <> 'BAJA' AND u.Nivel <> N'SUPER';
```
- **El último ADMIN** se cuenta con el padrón: otra `m(x, A)` con `n = A`, `st = H` y `a(x)` presente, no SUPER, o bien `AdministradaPorSuper = 1`.
- **Plan:** `IX_UsuariosEmpresas_Empresa_Estado` más `PK_Usuarios`.
- **Criterio:** p95 ≤ 50 ms con 1 000 miembros.

**Q4.** Fuera de la v1 (fase 2).

**Q5. Cupo por empresa.** Dentro de la transacción `SERIALIZABLE`, con el padrón tomado primero (`TomarFilas`):
- **Q5-a, alta, vínculo o reactivación en E:** sin `m(c,E).st = H` y con `a(c)` no SUPER, rechaza si `consumo(E) + 1 > cupo(E)`.
- **Q5-b, habilitar una cuenta:** comprueba todas sus E con `st = H`, todo o nada.
- **Q5-c, habilitar una empresa:** rechaza si `consumo(E) > cupo(E)`.
- **Q5-d, vista:** el ADMIN ve solo lo de su empresa; el SUPER, todas las empresas y la suma.
- **Sin SQL de conteo:** el consumo se calcula en C# con el padrón.
- **Errores:** 409 `CUPO_AGOTADO` (ya existe) y 409 `PADRON_NO_DISPONIBLE`.
- **Orden de las validaciones:** autorización → ámbito → cupo (BP3 8.3, QA-94).
- **Criterio (BP3):** con un cupo libre, de 2 altas simultáneas pasa exactamente una. p95 ≤ 50 ms por alta, sin contar el hash.

**Q6. Editar un perfil de A.** Toma primero el padrón.
```sql
UPDATE ue SET VersionPrivilegios = ue.VersionPrivilegios + 1, FechaModificacion = SYSUTCDATETIME(), UsuarioModificacion = @actor
  FROM dbo.UsuariosEmpresas ue
 WHERE ue.EmpresaCodigo = @empresa
   AND EXISTS (SELECT 1 FROM dbo.UsuariosEmpresasPerfiles p
                WHERE p.EmpresaCodigo = @empresa AND p.PerfilCodigo = @perfil AND p.UsuarioCodigo = ue.UsuarioCodigo);
```
- **Plan:** `IX_UsuariosEmpresasPerfiles_Empresa_Perfil`.
- **Criterio:** los miembros de B no cambian de versión.
- **Alcance de Q6 (SD0-11):** toda escritura en `EmpresasPerfiles` (incluido `Inhabilitado`) y en `EmpresasPerfilesPermisos` sube la versión de los miembros de A que tienen ese perfil, en la misma transacción.
  - Lo mismo hace todo paso de `GPOS.Migracion sistema` que cambie permisos de perfiles o de membresías, y el borrado de un reporte con sus `rpt:{id}` (2.6).
  - Prueba de D1: inhabilitar un perfil revoca en la petición siguiente.

**Q7.** Es Q1 con el autor de la regla (AIS-06).

**Q8. Bitácora.**
```sql
-- Q8-a. ADMIN de A: categorías visibles, sin EmpresaActua y sin el código del SUPER (P-D0-D05).
SELECT TOP (200) b.Id, b.MomentoUtc, b.Evento,
       CASE WHEN b.ActorNivel = 'SUPER' THEN N'Super Usuario' ELSE b.Actor END AS Actor,
       CASE WHEN b.ActorNivel = 'SUPER' AND b.Usuario = b.Actor THEN N'Super Usuario' ELSE b.Usuario END AS Usuario,
       b.Motivo, b.Detalle, b.ValorAnterior, b.ValorNuevo, b.Ip, b.Dispositivo, b.Canal
  FROM dbo.BitacoraSeguridad b
  JOIN dbo.CatalogoEventosSeguridad c ON c.Evento = b.Evento
  JOIN dbo.CategoriasSeguridad k      ON k.Categoria = c.Categoria AND k.VisibleAdmin = 1
 WHERE b.Empresa = @empresa AND (@antesDe IS NULL OR b.Id < @antesDe)
 ORDER BY b.Id DESC;
-- Q8-b. SUPER, por cuenta: … FROM dbo.BitacoraSeguridad WHERE Usuario = @cuenta AND (@antesDe IS NULL OR Id < @antesDe) ORDER BY Id DESC
```
- **Plan de Q8-a:** `IX_BitacoraSeguridad_Empresa (Empresa, Id DESC)`, nuevo, con de 200 a 400 búsquedas de clave. Ver DX-6 frente al índice que propone BP3.
- **Plan de Q8-b:** `IX_BitacoraSeguridad_Usuario`, que ya existe (`4e094323:…/EsquemaRestauracionSistema.cs:39-40`).
- **Criterio:** p95 ≤ 100 ms con 1 millón de filas, y ninguna fila de otra empresa (QA-28).

**Q9. Dominio de administración.**
- `@empresasDominio`: lo calcula C# con el padrón (`m(@admin, X)` con `n = A` y `st = H`) y las empresas habilitadas. Es una TVP `nvarchar(30)`.

```sql
SELECT DISTINCT m.UsuarioCodigo, u.Descripcion
  FROM dbo.UsuariosEmpresas m JOIN dbo.Usuarios u ON u.Codigo = m.UsuarioCodigo AND u.Nivel <> N'SUPER'
 WHERE m.EmpresaCodigo IN (SELECT Valor FROM @empresasDominio) AND m.Estado = 'HABILITADA' AND m.UsuarioCodigo <> @admin
   AND NOT EXISTS (SELECT 1 FROM dbo.UsuariosEmpresas x
                    WHERE x.UsuarioCodigo = m.UsuarioCodigo AND x.EmpresaCodigo = @empresa AND x.Estado <> 'BAJA');
```
- C# exige además que cada candidato tenga `m` en el padrón.
- **Límite:** 20 por hora.
- **Criterio:** menos de 1 ms con cientos de filas, y un 404 idéntico (QA-19).

**Q10. Desbloqueo por el ADMIN.**
```sql
SELECT CASE WHEN @cuenta <> @admin
     AND NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Codigo = @cuenta AND Nivel = N'SUPER')
     AND EXISTS (SELECT 1 FROM dbo.UsuariosEmpresas s WHERE s.UsuarioCodigo = @cuenta AND s.EmpresaCodigo = @empresa AND s.Estado <> 'BAJA')
     AND NOT EXISTS (SELECT 1 FROM dbo.UsuariosEmpresas x WHERE x.UsuarioCodigo = @cuenta AND x.Estado <> 'BAJA'
                      AND x.EmpresaCodigo NOT IN (SELECT Valor FROM @empresasDominio))
   THEN 1 ELSE 0 END AS PuedeDesbloquear;
```
- Una fila falsificada solo puede **negar** el desbloqueo. Para ocultar una membresía habría que borrarla, y eso lo impiden 51620 y `DENY`.
- Limpia `BloqueadoHasta` y `FallosVentana*` (ADM-09).
- **Criterio:** la matriz de QA-21 y QA-58.

**Q11 y Q12.** Fuera de la v1.

**Q13. Guardar los privilegios.** Pasos: padrón → `Usuarios` (UPDLOCK; la cuenta existe y no es SUPER) → la sentencia.
```sql
UPDATE ue
   SET Nivel = @nivel, SucursalDefault = @sucursal, RestringirSucursal = @restringir, SelloMembresia = @selloNuevo,
       VersionPrivilegios = ue.VersionPrivilegios + 1, FechaModificacion = SYSUTCDATETIME(), UsuarioModificacion = @actor
  FROM dbo.UsuariosEmpresas ue
 WHERE ue.UsuarioCodigo = @usuario AND ue.EmpresaCodigo = @empresa AND ue.VersionPrivilegios = @versionLeida AND ue.Estado <> 'BAJA';
-- 0 filas: 409 VERSION_PRIVILEGIOS. 1 fila: reemplazar las hijas de (@usuario, @empresa); reemplazar m en el padrón; MEM-06 con el
-- padrón si deja de ser ADMIN; CambioPadron.GuardarAsync; PRIVILEGIOS_CAMBIADOS (MEMBRESIA, Empresa = @empresa, antes y después y Version).
```
- `@selloNuevo` lo calcula C# antes del `UPDATE`, con los campos nuevos.
- **Criterio:** con la versión vieja, 409; la versión nunca retrocede (51619).

### 4.3 Q23 a Q26 (nuevas de BP3) y las demás de la v1
**Q23. Equivalencia de la conversión.** Es el paso 4 del verbo (7.3).
- Para cada par (cuenta no SUPER, empresa habilitada) se compara el conjunto **esperado** según P-D0-07 de BP3 con lo creado, en los dos sentidos.

```sql
-- Esperado (P-D0-07): sin restricción → todas las empresas habilitadas; con restricción → solo EmpresaDefault, si está habilitada.
WITH esperado AS (
    SELECT u.Codigo AS UsuarioCodigo, e.Codigo AS EmpresaCodigo,
           CASE WHEN u.Nivel = N'ADMIN' THEN 'ADMIN' ELSE 'USER' END AS Nivel,
           CASE WHEN e.Codigo = u.EmpresaDefault THEN u.SucursalDefault END AS SucursalDefault,
           CONVERT(bit, CASE WHEN u.RestringirSucursal = 1 THEN 1 ELSE 0 END) AS RestringirSucursal
      FROM dbo.Usuarios u CROSS JOIN dbo.Empresas e
     WHERE u.Nivel <> N'SUPER' AND e.Inhabilitado = 0
       AND (u.RestringirSucursal = 0 OR e.Codigo = u.EmpresaDefault))
SELECT TOP (1) 1 FROM (
    (SELECT * FROM esperado EXCEPT SELECT UsuarioCodigo, EmpresaCodigo, Nivel, SucursalDefault, RestringirSucursal FROM dbo.UsuariosEmpresas)
    UNION ALL
    (SELECT UsuarioCodigo, EmpresaCodigo, Nivel, SucursalDefault, RestringirSucursal FROM dbo.UsuariosEmpresas EXCEPT SELECT * FROM esperado)) d;
-- Una fila → THROW 51621. Igual, con EXCEPT en los dos sentidos: E3 perfiles y E4 sus permisos por empresa frente a los globales;
-- E5 asignaciones y E6 excepciones (Permiso → Opcion) de cada membresía frente a las de la cuenta.
-- E7 (C#): Permisos.Combinar del modelo anterior frente al nuevo, por cada (cuenta, empresa) creado.
```
- **Criterio:** cero diferencias, o se revierte la transacción y se informa. Es idempotente: con la marca ya puesta, no hace nada.
- **Plan:** recorridos de tablas pequeñas (cientos de filas); menos de 1 s en el DEMO.

**Q24. Consumo del padrón frente a las filas** (`GPOS.Migracion verificar`).
```sql
SELECT ue.EmpresaCodigo, COUNT(*) AS ConsumoFilas
  FROM dbo.UsuariosEmpresas ue JOIN dbo.Usuarios u ON u.Codigo = ue.UsuarioCodigo
 WHERE ue.Estado = 'HABILITADA' AND u.Inhabilitado = 0 AND u.Nivel <> N'SUPER'
 GROUP BY ue.EmpresaCodigo;
```
- Se compara con `consumo(E)` del padrón. Si difieren: `CONSUMO_DESCUADRADO` por empresa (BP3).
- **Plan:** `IX_UsuariosEmpresas_Empresa_Estado`.

**Q25. Introspección v2.** No es una consulta de datos: ejecuta Q1 del lado de la principal.
- **Criterio (BP3):** p95 ≤ 5 ms.
- No agrega objetos de datos.

**Q26. Aislamiento estático.** Es una prueba de arquitectura, no SQL.
- Como apoyo de datos: toda consulta sobre `UsuariosEmpresas`, sus hijas y `EmpresasPerfiles*` lleva `EmpresaCodigo = @…` o la PK completa, salvo `/api/super` y el verbo.
- Las constantes SQL de D1 se agrupan en una sola clase (`ConsultasAcceso`) para que la prueba las recorra.

**Otras de la v1:**

| Q | Contenido |
|---|---|
| Q18 (DAT-0929) | Bloqueo global de la cuenta, sin cambios (`FallosVentana*`) |
| Q27 | Ingreso: `UPDATE UsuariosEmpresas SET UltimoAcceso = …` en una sentencia aparte, más el `INSERT` de `INGRESO_EMPRESA` o `INGRESO_SUPER` |
| Q28 | Membresías de una cuenta, para la pantalla «Cuentas» del SUPER (prefijo de la PK) |
| Q29 | Purga por categoría (5.4) |

### 4.4 Índices
| Índice | Definición | Lo justifica | Costo de escritura |
|---|---|---|---|
| `PK_UsuariosEmpresas` (agrupado) | `(UsuarioCodigo, EmpresaCodigo)` | Q1, Q2, Q10, Q13, Q27, Q28 | — |
| `IX_UsuariosEmpresas_Empresa_Estado` | `(EmpresaCodigo, Estado) INCLUDE (Nivel)` | Q3, Q9, Q24, la FK desde `Empresas` | Bajo. **Sin `UltimoAcceso`**, que cambia en cada ingreso |
| PK de las hijas | 2.3 | Q1 (conjuntos 2 y 3), Q13, Q23 | — |
| `IX_UsuariosEmpresasPerfiles_Empresa_Perfil` | `(EmpresaCodigo, PerfilCodigo)` | Q6; la FK NO ACTION al borrar un perfil | Bajo |
| `IX_BitacoraSeguridad_Empresa` | `(Empresa, Id DESC) INCLUDE (MomentoUtc, Evento, ActorNivel)` | Q8-a | Una inserción por evento |
| `PK_` y `UQ_CatalogoEventosSeguridad` | `(Evento)`, `(Evento, Categoria)` | FK, Q8-a, Q29 | Nulo |

- **Sin índices filtrados** en la bitácora (D-J2-06 del #57).
- **Corrección:** sí hace falta un índice de `rpt:{id}`. El borrado existe (`ReportesService.cs:131-135`, con `Permisos.Reporte(id)`): mi búsqueda anterior por el literal `"rpt:"` no lo encontró. Se agrega `IX_UsuariosEmpresasPermisos_Empresa_Opcion (EmpresaCodigo, Opcion)`:
  - lo justifica el borrado de los `rpt:{id}` de un reporte en su empresa (2.6);
  - costo de escritura bajo, una entrada por excepción.
  - `EmpresasPerfilesPermisos` no lo necesita: su PK empieza por la empresa.
- **Sin índice para el cupo:** sale del padrón.

### 4.5 Volumen y costo
- **Tamaño:** con 50 cuentas × 5 empresas, menos de 1,5 MB de tablas. La bitácora, unos 130 MB en 5 años (ADR-37) más unos 20 MB del índice.
- **Infraestructura y licencias:** costo nulo; cabe en Express.
- **Esfuerzo de datos** (*inferido*, ±30 %, dentro de los tramos firmados):

| Tramo | Contenido | sp |
|---|---|---|
| D1 | DDL, disparadores, verbo, Q23 y consultas | 1,3 a 1,7 |
| D3 | Sello y padrón v2 | 0,8 a 1,1 |
| D5 | Bitácora | 0,4 a 0,6 |

---

## 5. Auditoría y trazabilidad (DB7-03; BP3 6.4)

### 5.1 Columnas de `BitacoraSeguridad`
| Columna | Uso |
|---|---|
| `Empresa` (ya existe) | **Empresa afectada.** No se renombra: ya la leen RN (`ComandosCambioRnc.cs:81`) y la consulta de eventos. BP3 11.1.4 deja la decisión a datos (DX-6) |
| `EmpresaActua nvarchar(30) NULL` | Empresa de la sesión de quien actúa. Solo la ve el SUPER (TRZ-06) |
| `ActorNivel varchar(7) NULL` | `SUPER`, `ADMIN`, `USER` o `SISTEMA`, tomado del servidor (Q1), no del token |
| `Categoria varchar(10) NULL` | La pide DB7-03. La FK compuesta la valida. **La retención y la visibilidad salen del catálogo por `Evento`**, así que una fila sin categoría no se purga antes de tiempo ni se muestra de más |
| `ValorAnterior`, `ValorNuevo` (`nvarchar(2000) NULL`, JSON) | Antes y después de los privilegios. Si pasa de 2 000 caracteres: `{"Excepciones":{"Cambiadas":n,"Huella":"…"}}` (*inferido*) |

La bitácora sigue siendo de solo inserción (52001, y el `DENY` de RG-14 en `4e094323:src/GPOS.Core/Infraestructura/Motor/PrivilegioMinimoSistema.cs:128`), sin secretos.

### 5.2 Categorías
| Categoría | Retención | La ve el ADMIN | Eventos (nombres de BP3 6.4, más los de datos marcados con \*) |
|---|---|---|---|
| `ACCESO` | 5 años | Sí | `INGRESO_EMPRESA`, `INGRESO_SUPER`, `ACCESO_EMPRESA_DENEGADO` (sin empresa, DX-7), `SESIONES_EMPRESA_REVOCADAS`\*, `EMPRESA_CREADA`\*, `EMPRESA_HABILITADA`\*, `EMPRESA_INHABILITADA`\* |
| `MEMBRESIA` | 5 años | Sí | `MEMBRESIA_CREADA` (el origen va en `ValorNuevo`), `MEMBRESIA_SUSPENDIDA`, `MEMBRESIA_REACTIVADA`, `MEMBRESIA_BAJA`, `PRIVILEGIOS_CAMBIADOS`, `PERFIL_CAMBIADO`, `PERFIL_ELIMINADO`\*, `ACCESOS_CONVERTIDOS` (por empresa, DX-8) |
| `CUENTA` | 5 años | No | `CUENTA_CREADA`, `CUENTA_MODIFICADA`, `CUENTA_INHABILITADA`, `CUENTA_HABILITADA`, `CLAVE_CAMBIADA` (ya existe), `CLAVE_RESTABLECIDA`, `CUENTA_BLOQUEADA`, `CUENTA_DESBLOQUEADA`, `SESIONES_CUENTA_REVOCADAS`, `ALTA_NO_DISPONIBLE` y `VINCULO_NO_ENCONTRADO` (DX-9) |
| `NOTIFICACION` | 5 años | No (BP3) | `REGLA_NOTIFICACION_SUSPENDIDA` |
| `SISTEMA` | **2 años**, con una excepción de 5 años (DX-8) | No | Candado, restauración, RNC y anillo (ya existen); `ACCESOS_CONVERTIDOS_INSTALACION`\* (el global de la conversión) |
| `FACTOR`, `SELLO`, `LICENCIA` | 2 años | No | Los que ya existen, más `MEMBRESIA_SIN_SELLO`\* y `MEMBRESIA_LEGITIMADA`\* (`SELLO`) y `LICENCIA_EN_EXCESO`\* (`LICENCIA`) |

- **Fuente única del catálogo:** `GPOS.Contracts.EventosSeguridad`, que pasa a llevar la categoría. La DDL genera el `MERGE` desde esa lista y una prueba de D6 compara la tabla con la lista.
- **Eventos verificados que ya existen** (`c/adr81-tn-sobre-rn`): `FACTOR_*`, `RESPALDO_*`, `REAUTENTICACION_*`, `TOKEN_SUPER_SIN_OTP`, `DERIVA_RELOJ`, `RECUPERACION_FACTOR_*`, `USUARIO_SIN_SELLO`, `CUENTA_LEGITIMADA`, `PADRON_*`, `SELLADO_INICIAL`, `CUENTAS_INICIALES_CREADAS`, `CUENTAS_FUERA_DE_PADRON`, `LICENCIA_*`, `ENTORNO_*`, `ARRANQUE_AMPLIO_BLOQUEADO`, `FILA_LICENCIA_INVALIDA`, `SISTEMA_RESTAURADO`, `CANDADO_RESTAURACION_LIBERADO`, `ACCESO_RECHAZADO_CANDADO`, `MARCA_P7_RECOMPUESTA`, `CAMBIO_RNC_SUPER`, `CLAVE_BLOQUEO_CAMBIO`.
- **Por qué una tabla con FK:** ADR-37 pide un catálogo «validado por el motor», y hoy solo existe en C#. Si falta un evento, la transacción falla de forma visible (R-1).
  - *Alternativa descartada:* el `CHECK IN` con acción testigo de DAT-0929.

### 5.3 Visibilidad
- El ADMIN ve `ACCESO` y `MEMBRESIA` con empresa afectada igual a la suya (BP3 6.4, P-D0-D02), sin `EmpresaActua`.
- Un vínculo se ve como «vinculada por <ADMIN>».
- El SUPER lo ve todo.

### 5.4 Purga por categoría
- `TR_BitacoraSeguridad_Purga` (52002, 2 años fijos; `4e094323:…/EsquemaRestauracionSistema.cs:45-50`) y `dbo.PurgarBitacoraSeguridad` (`f165d1fa:src/GPOS.Core/Consultas/Sistema/SegundoFactor/EsquemaSegundoFactor.cs:128`) pasan a usar la **retención del catálogo por `Evento`**. Un evento que no esté en el catálogo se guarda 5 años.
- **Se editan en su sitio**, sin sobrescribirlos desde el lote de DB-7: los dos usan `CREATE OR ALTER` en cada arranque y ganaría el último en ejecutarse.
- La tarea diaria del #57 no cambia.

---

### 5.6 Un evento fuera del catálogo no debe revertir el cambio ni el bloqueo (SD0-07)
La FK se mantiene: ADR-37 pide un catálogo validado por el motor. Para que un desfase entre el código y la tabla no haga daño:

1. **Comprobación al arrancar.** Antes de abrir el puerto, la API compara `GPOS.Contracts.EventosSeguridad.Todos` con `SELECT Evento FROM dbo.CatalogoEventosSeguridad`.
   - Es una lectura de un centenar de filas, una vez.
   - En **Release**, si falta alguno, la API no arranca: «Ejecute GPOS.Migracion sistema». En Debug y en Amplio, `sistema` aplica la DDL al arrancar y el `MERGE` lo resuelve.
   - Registra el **EventId 4733** («falta un evento en el catálogo al arrancar en Release»), el número del blueprint (secciones 6.4 y 15), que es el dueño de los contratos.
   - Cubre el caso real: el modo Estricto, con una versión nueva de la API y `sistema` sin ejecutar.
2. **Rutas de fallo y de bloqueo:** la unión de esta lista con la de BP3 6.4: `CUENTA_BLOQUEADA`, `ACCESO_EMPRESA_DENEGADO`, `VINCULO_NO_ENCONTRADO`, `ALTA_NO_DISPONIBLE`, `USUARIO_SIN_SELLO`, `MEMBRESIA_SIN_SELLO` y los eventos de los intentos fallidos de `identificar`.
   - Los contadores (`FallosVentana*`, `BloqueadoHasta`; Q18) se confirman en **su propia sentencia**, en autocommit.
   - El evento se escribe **después**, en otra sentencia. Si el `INSERT` falla (FK u otro error), va al registro de la aplicación con el **EventId 4734** («el evento de bitácora no se pudo escribir»; BP3 6.4 y 15), y la respuesta no cambia: el mismo 401 o 404, sin oráculo.
   - La regla de «misma transacción» (TRZ-01) queda **solo para los cambios de administración** (altas, privilegios, estados, conversión). En ellos, revertir es lo correcto.
3. **Prueba de D5:** con un evento retirado de la tabla, el bloqueo se aplica igual, la respuesta es idéntica y queda la línea en el registro.
4. *Alternativa descartada:* quitar la FK y validar solo en C#. No cumple el «validado por el motor» de ADR-37.

## 6. Persistencia de sincronización
**No aplica:** los nodos de sucursal son de la entrega 2. Las cachés son las de 3.6 y de BP3 6.3. `VersionPrivilegios` es monótona (51619, 51620, `DENY DELETE`).

---

## 7. Script de migración y reversión

### 7.1 Dónde va cada parte
| Lote | Dónde | Quién lo aplica | ¿Destructivo? |
|---|---|---|---|
| **D7-A** (estructura) | Tercer elemento de `ExtensionesEsquemaSistema.Ddl`; `Version = 6` | `sistema` | No |
| **D7-P** (permisos) | `ExtensionesEsquemaSistema.Permisos` | Solo `sistema` | No |
| **rptsis v2** | `database/ola5/rptsis-vistas-sistema.sql`, contrato en versión mayor (`:109-110`, `:137-139`) | `sistema` | No |
| **D7-C** (conversión) | `GPOS.Migracion accesos --convertir` | Técnico de GSF, con la API detenida | **Sí** |
| **Retiro de las líneas heredadas** | `ActualizarTablasAsync` (`4e094323:…/EsquemaSistema.cs:102-103`, `:131-148`), más las de `IntentosFallidos` (`55365806:…/EsquemaSistema.cs:108-109`, que son las `:105-106` en `4e094323`; E-SW-4), y el modelo de EF | PR de D1 (las de `IntentosFallidos`, con D2) | — |

- **Retiro obligatorio de las líneas heredadas (R-2):** si no se quitan, el siguiente `sistema` vuelve a crear `RestringirSucursal` y las tablas globales, o falla en el `ALTER` sobre `UsuariosPermisos`.
- **El modelo de EF** quita `Perfil`, `PerfilPermiso`, `UsuarioPerfil`, `UsuarioPermiso` y las propiedades de sucursal de `Usuario`.
- **Las tablas nuevas quedan fuera de EF**, como en D81-01 (ADO.NET y Dapper), para que `EnsureCreated` no las cree sin disparadores.

### 7.2 Borrador de la DDL (no se aplicó a ninguna base)
```sql
-- D7-A · DB-7, GPOS_SYSDATA versión 6. Idempotente, sin GO; disparadores y vistas en EXEC.
SET NOCOUNT ON;
IF COL_LENGTH('dbo.Empresas', 'AdministradaPorSuper') IS NULL
    ALTER TABLE dbo.Empresas ADD AdministradaPorSuper bit NOT NULL CONSTRAINT DF_Empresas_AdministradaPorSuper DEFAULT (0);
IF COL_LENGTH('dbo.Usuarios', 'SesionEmpresa') IS NULL ALTER TABLE dbo.Usuarios ADD SesionEmpresa nvarchar(30) NULL;
IF COL_LENGTH('dbo.Usuarios', 'FallosVentana') IS NULL
    ALTER TABLE dbo.Usuarios ADD FallosVentana int NOT NULL CONSTRAINT DF_Usuarios_FallosVentana DEFAULT (0);
IF COL_LENGTH('dbo.Usuarios', 'FallosVentanaInicio') IS NULL ALTER TABLE dbo.Usuarios ADD FallosVentanaInicio datetime2(3) NULL;

IF OBJECT_ID(N'dbo.UsuariosEmpresas', N'U') IS NULL
    CREATE TABLE dbo.UsuariosEmpresas (
        UsuarioCodigo nvarchar(30) NOT NULL CONSTRAINT FK_UsuariosEmpresas_Usuarios REFERENCES dbo.Usuarios (Codigo),
        EmpresaCodigo nvarchar(30) NOT NULL CONSTRAINT FK_UsuariosEmpresas_Empresas REFERENCES dbo.Empresas (Codigo),
        Nivel varchar(5) NOT NULL CONSTRAINT CK_UsuariosEmpresas_Nivel CHECK (Nivel IN ('ADMIN', 'USER')),
        SucursalDefault nvarchar(30) NULL,
        RestringirSucursal bit NOT NULL CONSTRAINT DF_UsuariosEmpresas_Restringir DEFAULT (0),
        Estado varchar(10) NOT NULL CONSTRAINT CK_UsuariosEmpresas_Estado CHECK (Estado IN ('HABILITADA', 'SUSPENDIDA', 'BAJA')),
        FechaEstado datetime2(0) NULL, CuentaEstado nvarchar(30) NULL, MotivoEstado nvarchar(200) NULL,
        VersionPrivilegios int NOT NULL CONSTRAINT DF_UsuariosEmpresas_Version DEFAULT (1)
            CONSTRAINT CK_UsuariosEmpresas_Version CHECK (VersionPrivilegios >= 1),
        SesionesRevocadas datetime2(3) NULL,
        UltimoAcceso datetime2(0) NULL,
        Origen varchar(10) NOT NULL CONSTRAINT CK_UsuariosEmpresas_Origen CHECK (Origen IN ('MANUAL', 'VINCULO', 'CONVERSION')),
        FechaAlta datetime2(0) NOT NULL CONSTRAINT DF_UsuariosEmpresas_FechaAlta DEFAULT (SYSUTCDATETIME()),
        UsuarioAlta nvarchar(30) NOT NULL,
        FechaModificacion datetime2(0) NULL, UsuarioModificacion nvarchar(30) NULL,
        SelloMembresia varbinary(512) NULL,
        CONSTRAINT PK_UsuariosEmpresas PRIMARY KEY CLUSTERED (UsuarioCodigo, EmpresaCodigo),
        CONSTRAINT CK_UsuariosEmpresas_Sucursal CHECK (RestringirSucursal = 0 OR SucursalDefault IS NOT NULL),
        CONSTRAINT CK_UsuariosEmpresas_EstadoMotivo CHECK (Estado = 'HABILITADA'
            OR (FechaEstado IS NOT NULL AND CuentaEstado IS NOT NULL AND MotivoEstado IS NOT NULL AND LEN(LTRIM(RTRIM(MotivoEstado))) >= 10)));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_UsuariosEmpresas_Empresa_Estado' AND object_id = OBJECT_ID(N'dbo.UsuariosEmpresas'))
    CREATE INDEX IX_UsuariosEmpresas_Empresa_Estado ON dbo.UsuariosEmpresas (EmpresaCodigo, Estado) INCLUDE (Nivel);

IF OBJECT_ID(N'dbo.EmpresasPerfiles', N'U') IS NULL
    CREATE TABLE dbo.EmpresasPerfiles (
        EmpresaCodigo nvarchar(30) NOT NULL CONSTRAINT FK_EmpresasPerfiles_Empresas REFERENCES dbo.Empresas (Codigo),
        Codigo nvarchar(30) NOT NULL, Descripcion nvarchar(100) NOT NULL,
        Inhabilitado bit NOT NULL CONSTRAINT DF_EmpresasPerfiles_Inhabilitado DEFAULT (0),
        CONSTRAINT PK_EmpresasPerfiles PRIMARY KEY (EmpresaCodigo, Codigo));
IF OBJECT_ID(N'dbo.EmpresasPerfilesPermisos', N'U') IS NULL
    CREATE TABLE dbo.EmpresasPerfilesPermisos (
        EmpresaCodigo nvarchar(30) NOT NULL, PerfilCodigo nvarchar(30) NOT NULL, Opcion nvarchar(50) NOT NULL,
        Nivel int NOT NULL, Acciones int NOT NULL,
        CONSTRAINT PK_EmpresasPerfilesPermisos PRIMARY KEY (EmpresaCodigo, PerfilCodigo, Opcion),
        CONSTRAINT FK_EmpresasPerfilesPermisos_Perfil FOREIGN KEY (EmpresaCodigo, PerfilCodigo)
            REFERENCES dbo.EmpresasPerfiles (EmpresaCodigo, Codigo) ON DELETE CASCADE);
IF OBJECT_ID(N'dbo.UsuariosEmpresasPerfiles', N'U') IS NULL
    CREATE TABLE dbo.UsuariosEmpresasPerfiles (
        UsuarioCodigo nvarchar(30) NOT NULL, EmpresaCodigo nvarchar(30) NOT NULL, PerfilCodigo nvarchar(30) NOT NULL,
        CONSTRAINT PK_UsuariosEmpresasPerfiles PRIMARY KEY (UsuarioCodigo, EmpresaCodigo, PerfilCodigo),
        CONSTRAINT FK_UsuariosEmpresasPerfiles_Membresia FOREIGN KEY (UsuarioCodigo, EmpresaCodigo)
            REFERENCES dbo.UsuariosEmpresas (UsuarioCodigo, EmpresaCodigo),
        CONSTRAINT FK_UsuariosEmpresasPerfiles_Perfil FOREIGN KEY (EmpresaCodigo, PerfilCodigo)
            REFERENCES dbo.EmpresasPerfiles (EmpresaCodigo, Codigo));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_UsuariosEmpresasPerfiles_Empresa_Perfil' AND object_id = OBJECT_ID(N'dbo.UsuariosEmpresasPerfiles'))
    CREATE INDEX IX_UsuariosEmpresasPerfiles_Empresa_Perfil ON dbo.UsuariosEmpresasPerfiles (EmpresaCodigo, PerfilCodigo);
IF OBJECT_ID(N'dbo.UsuariosEmpresasPermisos', N'U') IS NULL
    CREATE TABLE dbo.UsuariosEmpresasPermisos (
        UsuarioCodigo nvarchar(30) NOT NULL, EmpresaCodigo nvarchar(30) NOT NULL, Opcion nvarchar(50) NOT NULL,
        Nivel int NOT NULL, Acciones int NOT NULL,
        CONSTRAINT PK_UsuariosEmpresasPermisos PRIMARY KEY (UsuarioCodigo, EmpresaCodigo, Opcion),
        CONSTRAINT FK_UsuariosEmpresasPermisos_Membresia FOREIGN KEY (UsuarioCodigo, EmpresaCodigo)
            REFERENCES dbo.UsuariosEmpresas (UsuarioCodigo, EmpresaCodigo));

-- Disparadores (51619, 51620, 51623, 51624, 51625)
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_UsuariosEmpresas_Version ON dbo.UsuariosEmpresas AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM deleted d
                 WHERE d.UsuarioCodigo = i.UsuarioCodigo AND d.EmpresaCodigo = i.EmpresaCodigo))
       OR EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.UsuarioCodigo = i.UsuarioCodigo AND d.EmpresaCodigo = i.EmpresaCodigo
                   WHERE i.VersionPrivilegios < d.VersionPrivilegios
                      OR (i.VersionPrivilegios = d.VersionPrivilegios
                          AND (i.Estado <> d.Estado OR i.Nivel <> d.Nivel OR i.RestringirSucursal <> d.RestringirSucursal
                               OR ISNULL(i.SucursalDefault, N'''') <> ISNULL(d.SucursalDefault, N'''')))
                      OR i.Origen <> d.Origen OR i.FechaAlta <> d.FechaAlta OR i.UsuarioAlta <> d.UsuarioAlta)
        THROW 51619, N''Membresía: la versión de privilegios no retrocede y sube con cada cambio de estado, nivel o sucursal.'', 1;
    IF EXISTS (SELECT 1 FROM inserted i WHERE i.Estado = ''BAJA''
                 AND (EXISTS (SELECT 1 FROM dbo.UsuariosEmpresasPerfiles p WHERE p.UsuarioCodigo = i.UsuarioCodigo AND p.EmpresaCodigo = i.EmpresaCodigo)
                   OR EXISTS (SELECT 1 FROM dbo.UsuariosEmpresasPermisos x WHERE x.UsuarioCodigo = i.UsuarioCodigo AND x.EmpresaCodigo = i.EmpresaCodigo)))
        THROW 51623, N''Una membresía dada de baja no conserva perfiles ni excepciones.'', 1;
END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_UsuariosEmpresas_SinBorrado ON dbo.UsuariosEmpresas INSTEAD OF DELETE AS
BEGIN SET NOCOUNT ON; THROW 51620, N''Las membresías no se borran: se dan de baja.'', 1; END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_UsuariosEmpresas_SinSuper ON dbo.UsuariosEmpresas AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.Usuarios u ON u.Codigo = i.UsuarioCodigo WHERE u.Nivel = N''SUPER'' AND i.Estado <> ''BAJA'')
        THROW 51624, N''El Super Usuario no tiene membresías.'', 1;
END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_UsuariosEmpresasPerfiles_SinBaja ON dbo.UsuariosEmpresasPerfiles AFTER INSERT AS
BEGIN SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.UsuariosEmpresas m ON m.UsuarioCodigo = i.UsuarioCodigo AND m.EmpresaCodigo = i.EmpresaCodigo
                WHERE m.Estado = ''BAJA'') THROW 51623, N''Una membresía dada de baja no conserva perfiles ni excepciones.'', 1;
END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_UsuariosEmpresasPermisos_SinBaja ON dbo.UsuariosEmpresasPermisos AFTER INSERT AS
BEGIN SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.UsuariosEmpresas m ON m.UsuarioCodigo = i.UsuarioCodigo AND m.EmpresaCodigo = i.EmpresaCodigo
                WHERE m.Estado = ''BAJA'') THROW 51623, N''Una membresía dada de baja no conserva perfiles ni excepciones.'', 1;
END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_Usuarios_SuperSinMembresias ON dbo.Usuarios AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Nivel) RETURN;
    IF OBJECT_ID(N''dbo.UsuariosEmpresas'', N''U'') IS NULL RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.UsuariosEmpresas m ON m.UsuarioCodigo = i.Codigo
                WHERE i.Nivel = N''SUPER'' AND m.Estado <> ''BAJA'')
        THROW 51625, N''Una cuenta con membresías no puede pasar a Super Usuario: dé de baja antes sus membresías.'', 1;
END');
EXEC (N'ENABLE TRIGGER ALL ON dbo.UsuariosEmpresas;');
EXEC (N'ENABLE TRIGGER dbo.TR_UsuariosEmpresasPerfiles_SinBaja ON dbo.UsuariosEmpresasPerfiles;');
EXEC (N'ENABLE TRIGGER dbo.TR_UsuariosEmpresasPermisos_SinBaja ON dbo.UsuariosEmpresasPermisos;');
EXEC (N'ENABLE TRIGGER dbo.TR_Usuarios_SuperSinMembresias ON dbo.Usuarios;');

-- Bitácora: categorías, catálogo, columnas, restricciones e índice
IF OBJECT_ID(N'dbo.CategoriasSeguridad', N'U') IS NULL
    CREATE TABLE dbo.CategoriasSeguridad (
        Categoria varchar(12) NOT NULL CONSTRAINT PK_CategoriasSeguridad PRIMARY KEY,
        RetencionAnios tinyint NOT NULL CONSTRAINT CK_CategoriasSeguridad_Retencion CHECK (RetencionAnios BETWEEN 2 AND 10),
        VisibleAdmin bit NOT NULL);
MERGE dbo.CategoriasSeguridad AS t
USING (VALUES ('ACCESO', 5, 1), ('MEMBRESIA', 5, 1), ('CUENTA', 5, 0), ('NOTIFICACION', 5, 0),
              ('FACTOR', 2, 0), ('LICENCIA', 2, 0), ('SELLO', 2, 0), ('SISTEMA', 2, 0)) AS s (Categoria, RetencionAnios, VisibleAdmin)
   ON t.Categoria = s.Categoria
 WHEN MATCHED AND (t.RetencionAnios <> s.RetencionAnios OR t.VisibleAdmin <> s.VisibleAdmin)
      THEN UPDATE SET RetencionAnios = s.RetencionAnios, VisibleAdmin = s.VisibleAdmin
 WHEN NOT MATCHED THEN INSERT (Categoria, RetencionAnios, VisibleAdmin) VALUES (s.Categoria, s.RetencionAnios, s.VisibleAdmin);
IF OBJECT_ID(N'dbo.CatalogoEventosSeguridad', N'U') IS NULL
    CREATE TABLE dbo.CatalogoEventosSeguridad (
        Evento varchar(40) NOT NULL CONSTRAINT PK_CatalogoEventosSeguridad PRIMARY KEY,
        Categoria varchar(12) NOT NULL CONSTRAINT FK_CatalogoEventosSeguridad_Categoria REFERENCES dbo.CategoriasSeguridad (Categoria),
        RetencionAnios tinyint NULL CONSTRAINT CK_CatalogoEventosSeguridad_Retencion CHECK (RetencionAnios BETWEEN 2 AND 10), -- excepción por evento (DX-8)
        CONSTRAINT UQ_CatalogoEventosSeguridad_EventoCategoria UNIQUE (Evento, Categoria));
-- MERGE del catálogo, GENERADO por C# desde GPOS.Contracts.EventosSeguridad: (Evento, Categoria, RetencionAnios NULL salvo la excepción);
-- WHEN MATCHED con diferencias → UPDATE; WHEN NOT MATCHED → INSERT; sin NOT MATCHED BY SOURCE (los eventos retirados siguen válidos para la historia).

IF COL_LENGTH('dbo.BitacoraSeguridad', 'EmpresaActua') IS NULL ALTER TABLE dbo.BitacoraSeguridad ADD EmpresaActua nvarchar(30) NULL;
IF COL_LENGTH('dbo.BitacoraSeguridad', 'ActorNivel') IS NULL
    ALTER TABLE dbo.BitacoraSeguridad ADD ActorNivel varchar(7) NULL
        CONSTRAINT CK_BitacoraSeguridad_ActorNivel CHECK (ActorNivel IN ('SUPER', 'ADMIN', 'USER', 'SISTEMA'));
IF COL_LENGTH('dbo.BitacoraSeguridad', 'Categoria') IS NULL ALTER TABLE dbo.BitacoraSeguridad ADD Categoria varchar(12) NULL;
IF COL_LENGTH('dbo.BitacoraSeguridad', 'ValorAnterior') IS NULL
    ALTER TABLE dbo.BitacoraSeguridad ADD ValorAnterior nvarchar(2000) NULL, ValorNuevo nvarchar(2000) NULL;
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_Json', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_Json
            CHECK ((ValorAnterior IS NULL OR ISJSON(ValorAnterior) = 1) AND (ValorNuevo IS NULL OR ISJSON(ValorNuevo) = 1));');
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_EmpresaCategoria', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_EmpresaCategoria
            CHECK (Categoria IS NULL OR Categoria NOT IN (''ACCESO'', ''MEMBRESIA'') OR Empresa IS NOT NULL OR Evento = ''ACCESO_EMPRESA_DENEGADO'');');
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_IngresoSuper', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_IngresoSuper
            CHECK (Evento <> ''INGRESO_SUPER'' OR (Motivo IS NOT NULL AND LEN(LTRIM(RTRIM(Motivo))) >= 10));');
IF OBJECT_ID(N'dbo.FK_BitacoraSeguridad_Evento', N'F') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad WITH NOCHECK ADD CONSTRAINT FK_BitacoraSeguridad_Evento
            FOREIGN KEY (Evento) REFERENCES dbo.CatalogoEventosSeguridad (Evento);');
IF OBJECT_ID(N'dbo.FK_BitacoraSeguridad_EventoCategoria', N'F') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad WITH NOCHECK ADD CONSTRAINT FK_BitacoraSeguridad_EventoCategoria
            FOREIGN KEY (Evento, Categoria) REFERENCES dbo.CatalogoEventosSeguridad (Evento, Categoria);');
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BitacoraSeguridad_Empresa' AND object_id = OBJECT_ID(N'dbo.BitacoraSeguridad'))
    EXEC (N'CREATE INDEX IX_BitacoraSeguridad_Empresa ON dbo.BitacoraSeguridad (Empresa, Id DESC) INCLUDE (MomentoUtc, Evento, ActorNivel);');

-- Purga por categoría (texto nuevo; se EDITA en SqlBitacoraSeguridad y en SegundoFactorDdl, 5.4)
-- Retención efectiva de una fila: ISNULL(c.RetencionAnios, k.RetencionAnios), y 5 si el evento no está en el catálogo.
--   Disparador: IF EXISTS (SELECT 1 FROM deleted d LEFT JOIN dbo.CatalogoEventosSeguridad c ON c.Evento = d.Evento
--                            LEFT JOIN dbo.CategoriasSeguridad k ON k.Categoria = c.Categoria
--                           WHERE d.MomentoUtc >= DATEADD(year, -ISNULL(ISNULL(c.RetencionAnios, k.RetencionAnios), 5), SYSUTCDATETIME()))
--                 THROW 52002, ''Solo se purgan eventos que superan la retención de su categoría.'', 1;
--   Procedimiento (el mismo contrato: @Lote y «Purgadas»): DELETE TOP (@Lote) b FROM dbo.BitacoraSeguridad b LEFT JOIN … WHERE
--     b.MomentoUtc < DATEADD(day, -1, DATEADD(year, -2, SYSUTCDATETIME()))                               -- usa IX_BitacoraSeguridad_Momento
--     AND b.MomentoUtc < DATEADD(day, -1, DATEADD(year, -ISNULL(ISNULL(c.RetencionAnios, k.RetencionAnios), 5), SYSUTCDATETIME()));
--   y al final, como hoy, la limpieza de AcusesAvisoSeguridad.

-- Reportes por empresa (SD0-01; solo con la opción (a) de P-D0-08)
IF COL_LENGTH('dbo.Reportes', 'EmpresaCodigo') IS NULL ALTER TABLE dbo.Reportes ADD EmpresaCodigo nvarchar(30) NULL;
IF OBJECT_ID(N'dbo.FK_Reportes_Empresas', N'F') IS NULL
    EXEC (N'ALTER TABLE dbo.Reportes ADD CONSTRAINT FK_Reportes_Empresas FOREIGN KEY (EmpresaCodigo) REFERENCES dbo.Empresas (Codigo);');
IF OBJECT_ID(N'dbo.ConversionReportes', N'U') IS NULL
    CREATE TABLE dbo.ConversionReportes (
        EmpresaCodigo nvarchar(30) NOT NULL CONSTRAINT FK_ConversionReportes_Empresas REFERENCES dbo.Empresas (Codigo),
        IdOriginal int NOT NULL, IdNuevo int NOT NULL,
        ReglasActualizadasUtc datetime2(0) NULL,
        CONSTRAINT PK_ConversionReportes PRIMARY KEY (EmpresaCodigo, IdOriginal));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_UsuariosEmpresasPermisos_Empresa_Opcion' AND object_id = OBJECT_ID(N'dbo.UsuariosEmpresasPermisos'))
    CREATE INDEX IX_UsuariosEmpresasPermisos_Empresa_Opcion ON dbo.UsuariosEmpresasPermisos (EmpresaCodigo, Opcion);
-- CK_Reportes_Ambito lo crea el verbo (7.3, paso 8 h), después de asignar las filas de hoy:
--   ALTER TABLE dbo.Reportes ADD CONSTRAINT CK_Reportes_Ambito
--     CHECK ((DelSistema = 1 AND EmpresaCodigo IS NULL) OR (DelSistema = 0 AND EmpresaCodigo IS NOT NULL));
-- rptsis.Reporte v2: la vista de hoy (rptsis-vistas-sistema.sql:160-178) más la columna r.EmpresaCodigo.

-- D7-P · permisos (después de S1)
IF DATABASE_PRINCIPAL_ID(N'gpos_api') IS NOT NULL
BEGIN
    DENY DELETE ON OBJECT::dbo.UsuariosEmpresas TO gpos_api;
    DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.CatalogoEventosSeguridad TO gpos_api;
    DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.CategoriasSeguridad TO gpos_api;
    IF OBJECT_ID(N'dbo.ConversionReportes', N'U') IS NOT NULL DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.ConversionReportes TO gpos_api;
END;
```

**rptsis v2 (BP3 11.1.9).** `rptsis.PermisoEfectivo` con la empresa en la llave; la misma combinación que hoy (`4e094323:database/ola5/rptsis-vistas-sistema.sql:111-138`):
```sql
EXEC (N'CREATE OR ALTER VIEW rptsis.PermisoEfectivo AS
SELECT m.UsuarioCodigo, m.EmpresaCodigo, x.Opcion, x.Nivel, x.Acciones, x.Origen
  FROM dbo.UsuariosEmpresas m
  JOIN dbo.Usuarios u ON u.Codigo = m.UsuarioCodigo AND u.Inhabilitado = 0
  CROSS APPLY (SELECT f.Opcion, f.Nivel, f.Acciones, CONVERT(char(1), ''P'') AS Origen
                 FROM (SELECT pp.Opcion, MAX(pp.Nivel) AS Nivel,
                              MAX(pp.Acciones & 1) | MAX(pp.Acciones & 2) | MAX(pp.Acciones & 4) | MAX(pp.Acciones & 8)
                            | MAX(pp.Acciones & 16) | MAX(pp.Acciones & 32) | MAX(pp.Acciones & 64) | MAX(pp.Acciones & 128) AS Acciones
                         FROM dbo.UsuariosEmpresasPerfiles up
                         JOIN dbo.EmpresasPerfiles p ON p.EmpresaCodigo = up.EmpresaCodigo AND p.Codigo = up.PerfilCodigo AND p.Inhabilitado = 0
                         JOIN dbo.EmpresasPerfilesPermisos pp ON pp.EmpresaCodigo = up.EmpresaCodigo AND pp.PerfilCodigo = up.PerfilCodigo
                        WHERE up.UsuarioCodigo = m.UsuarioCodigo AND up.EmpresaCodigo = m.EmpresaCodigo
                        GROUP BY pp.Opcion) f
                WHERE NOT EXISTS (SELECT 1 FROM dbo.UsuariosEmpresasPermisos e
                                   WHERE e.UsuarioCodigo = m.UsuarioCodigo AND e.EmpresaCodigo = m.EmpresaCodigo AND e.Opcion = f.Opcion)
               UNION ALL
               SELECT e.Opcion, e.Nivel, e.Acciones, CONVERT(char(1), ''E'')
                 FROM dbo.UsuariosEmpresasPermisos e
                WHERE e.UsuarioCodigo = m.UsuarioCodigo AND e.EmpresaCodigo = m.EmpresaCodigo) x
 WHERE m.Estado = ''HABILITADA'';');
```
- **Plan:** con `UsuarioCodigo = @u AND EmpresaCodigo = @e`, búsquedas por PK de la membresía y de las hijas.
- **Las otras vistas:**
  - `rptsis.SesionUsuario` pierde `SucursalDefault` y `RestringirSucursal` y gana `SesionEmpresa`;
  - `rptsis.Membresia` es nueva;
  - `rptsis.AccesoEmpresa` pasa a la membresía `HABILITADA`, unida al SUPER por empresa habilitada. Es **informativa**: el acceso lo decide la introspección (DB7-04 (b)).

**Reverso de D7-A, D7-P y rptsis v2.** Solo vale antes de convertir.
```sql
IF EXISTS (SELECT 1 FROM dbo.Configuracion WHERE Clave = N'Accesos.Modelo')
    THROW 51622, N'El modelo de accesos ya se convirtió: revierta restaurando el respaldo previo a la conversión.', 1;
DROP TRIGGER IF EXISTS dbo.TR_Usuarios_SuperSinMembresias;
IF OBJECT_ID(N'dbo.FK_BitacoraSeguridad_EventoCategoria', N'F') IS NOT NULL ALTER TABLE dbo.BitacoraSeguridad DROP CONSTRAINT FK_BitacoraSeguridad_EventoCategoria;
IF OBJECT_ID(N'dbo.FK_BitacoraSeguridad_Evento', N'F') IS NOT NULL ALTER TABLE dbo.BitacoraSeguridad DROP CONSTRAINT FK_BitacoraSeguridad_Evento;
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_IngresoSuper', N'C') IS NOT NULL ALTER TABLE dbo.BitacoraSeguridad DROP CONSTRAINT CK_BitacoraSeguridad_IngresoSuper;
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_EmpresaCategoria', N'C') IS NOT NULL ALTER TABLE dbo.BitacoraSeguridad DROP CONSTRAINT CK_BitacoraSeguridad_EmpresaCategoria;
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_Json', N'C') IS NOT NULL ALTER TABLE dbo.BitacoraSeguridad DROP CONSTRAINT CK_BitacoraSeguridad_Json;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BitacoraSeguridad_Empresa' AND object_id = OBJECT_ID(N'dbo.BitacoraSeguridad'))
    DROP INDEX IX_BitacoraSeguridad_Empresa ON dbo.BitacoraSeguridad;
-- Las columnas nuevas de la bitácora SE CONSERVAN (solo inserción; la versión anterior no las lee).
DROP TABLE IF EXISTS dbo.CatalogoEventosSeguridad, dbo.CategoriasSeguridad;
DROP TABLE IF EXISTS dbo.UsuariosEmpresasPermisos, dbo.UsuariosEmpresasPerfiles, dbo.UsuariosEmpresas;   -- vacías antes de convertir
DROP TABLE IF EXISTS dbo.EmpresasPerfilesPermisos, dbo.EmpresasPerfiles;
-- Reportes por empresa (antes de convertir, todas las filas tienen EmpresaCodigo NULL)
IF OBJECT_ID(N'dbo.CK_Reportes_Ambito', N'C') IS NOT NULL ALTER TABLE dbo.Reportes DROP CONSTRAINT CK_Reportes_Ambito;
IF OBJECT_ID(N'dbo.FK_Reportes_Empresas', N'F') IS NOT NULL ALTER TABLE dbo.Reportes DROP CONSTRAINT FK_Reportes_Empresas;
IF COL_LENGTH('dbo.Reportes', 'EmpresaCodigo') IS NOT NULL ALTER TABLE dbo.Reportes DROP COLUMN EmpresaCodigo;   -- rptsis v1 se repone después
DROP TABLE IF EXISTS dbo.ConversionReportes;
-- AdministradaPorSuper, SesionEmpresa y FallosVentana*: se conservan (la versión anterior las ignora).
-- La purga y rptsis v1: las repone el `sistema` de la versión anterior (CREATE OR ALTER). La marca no baja (R-D14 de H-11).
```

### 7.3 Verbo `GPOS.Migracion accesos --convertir` (DB7-02; Q23)
**Uso:** `accesos --convertir --motivo "<10 a 200>" --confirmar [--instalacion-demo] [--aceptar-exceso --motivo-exceso "<10 a 200>"] [--solo-reglas]` (`--instalacion-demo` convierte en modo DEMO; sin él, modo mínimo: una membresía USER en `EmpresaDefault`, sin ningún ADMIN; precondición 9 y SD0-10). En una instalación nueva, `sistema --cuentas-iniciales` escribe directamente el padrón v2 y la marca.

**Precondiciones**, comprobadas en la vista previa. Si alguna falla: 51622 y nada cambia.
1. Sin la marca `Accesos.Modelo`. Si ya existe, informa «ya convertido» y sale con código 0.
2. `GPOS.Api` y `GPOS.Reportes` detenidos (ADR-79, punto 1).
3. El anillo verifica `Licencia.InstalacionId`. El padrón v1 verifica, o no hay cuentas no SUPER.
4. Ninguna entrada `FilaAusente` en el padrón v1. Si la hay, primero `sellos --purgar`: si no, la conversión liberaría un cupo.
5. Ninguna fila de `UsuariosPermisos` con `Nivel` NULL.
6. Marca del esquema ≥ 6.
7. Respaldo `COPY_ONLY` de `GPOS_SYSDATA` de menos de 60 minutos, o lo hace el verbo con `usp_RespaldoCopia` (ADR-82, D-05), junto con la copia del archivo `padron`.
8. **Pasos únicos de `PermisosService` (E-SW-7):** antes del paso 2 y en la misma transacción, el verbo ejecuta sobre las tablas globales `MigrarModeloAnterior`, `MigrarReportesPorArea` y los `AgregarPermisos*` que falten según sus marcas de `Configuracion`. Así se convierte el estado final del modelo anterior; Q23 compara después de esos pasos. Con este paso, la precondición 5 se cumple sola: `MigrarModeloAnterior` asigna el nivel a las filas de `UsuariosPermisos` que lo tenían en NULL.
9. **Instalación de desarrollo o DEMO (SD0-10).** El verbo no puede saber por sí mismo qué instalación es. Para no sellar como legítimo el sobreacceso de hoy (H-01 y H-02) fuera del DEMO:
   - **Con `--instalacion-demo`**, en modo DEMO: la conversión de los pasos 2 a 4 (P-D0-07 de BP3).
     - El indicador queda en `ACCESOS_CONVERTIDOS_INSTALACION` (`ValorNuevo.Modo = "DEMO"`), con la cuenta de Windows.
     - Cuando exista la clasificación de empresas (Desarrollo, Beta, Producción, Demostración; pendiente), el modo DEMO solo corre si **todas** son Desarrollo o Demostración (51622).
   - **Sin el indicador**, en modo mínimo:
     - cada cuenta no SUPER recibe una sola membresía, en su `EmpresaDefault` si está habilitada, como `USER` y con su restricción de sucursal;
     - ninguna membresía ADMIN, salvo `AdministradaPorSuper = 1` en todas las empresas habilitadas (MEM-06);
     - perfiles y excepciones copiados solo en esa membresía.
     - El verbo deja la lista de lo que **no** se convirtió (cuenta, empresa, nivel de hoy) en el informe de consola y en `ValorNuevo.Pendientes` (solo el número), para que el SUPER lo complete desde «Cuentas» después de revisarlo.
     - Q23 compara contra ese conjunto esperado.
   - **`--aceptar-exceso` exige `--motivo-exceso "<10 a 200>"`**, que queda en la misma fila.

**Algoritmo:** una sola transacción `SERIALIZABLE` con `XACT_ABORT ON`, en el orden de 3.7.

| Paso | Qué hace |
|---|---|
| 0 | `TomarFilas` del padrón y de `Accesos.Modelo` (`UPDLOCK, HOLDLOCK`) |
| 1 | `TABLOCKX, HOLDLOCK`, en orden: `Usuarios`, `UsuariosFactor`, `Empresas`, `Perfiles`, `PerfilesPermisos`, `UsuariosPerfiles`, `UsuariosPermisos` |
| 2 | Perfiles por empresa: **todos** los perfiles globales, con el mismo código, en **cada** empresa habilitada, con sus permisos (P-D0-07 de BP3, tercera viñeta) |
| 3 | Membresías (P-D0-07 de BP3): **sin** restricción, en todas las empresas habilitadas, con `SucursalDefault` solo en `EmpresaDefault`; **con** restricción, solo en `EmpresaDefault` y con la restricción, si está habilitada (si no, ninguna, y se informa). `Nivel` = el actual (`ADMIN` o `USER`); `Origen = 'CONVERSION'`; hijas copiadas de la cuenta. En modo mínimo, la regla de la precondición 9 |
| 3 b | Reportes (opción (a) de P-D0-08; 2.6): cada reporte con `DelSistema = 0` toma `EmpresaCodigo` = la primera empresa habilitada (`Prioridad`, `Codigo`) y conserva su `Id`. Para cada una de las demás se inserta una copia con sus columnas, con `Codigo = NULL` y el `Detalle` `id:{original}` reasignado, y la pareja se registra en `ConversionReportes`. En las membresías y perfiles de esas empresas, `rpt:{original}` pasa a `rpt:{nuevo}`. En modo mínimo, el reporte va a la empresa de su autor si se conoce; si no, a la primera |
| 4 | **Q23** (equivalencia E1 a E7). Una diferencia → 51621 y se revierte todo |
| 5 | MEM-06: `AdministradaPorSuper = 1` en las empresas habilitadas sin ADMIN en el padrón nuevo |
| 6 | Sellos y padrón v2 (C#, misma transacción). Detalle abajo |
| 7 | Cupo por empresa. Detalle abajo |
| 8 | Retiro: (a) `CREATE OR ALTER` de `rptsis` v2 **antes** de borrar (`rptsis.SesionUsuario` nombra las columnas: `:86-100`); (b) `Nivel` `ADMIN` → `USER`; (c) `CK_Usuarios_Nivel`; (d) si se firma **P-D0-04 de BP3**, `DebeCambiarClave = 1` en las cuentas que salen con alguna membresía ADMIN; (e) `DROP CONSTRAINT DF_Usuarios_RestringirSucursal` y `DROP COLUMN RestringirSucursal, SucursalDefault`; (f) `DROP TABLE UsuariosPerfiles, UsuariosPermisos, PerfilesPermisos, Perfiles`; (g) `DROP CONSTRAINT DF_Usuarios_IntentosFallidos` y `DROP COLUMN IntentosFallidos` (E-SW-4); (h) `CK_Reportes_Ambito` (2.6) |
| 9 | Bitácora: `ACCESOS_CONVERTIDOS` por empresa (`MEMBRESIA`, con `Empresa`; `ValorNuevo = {"Membresias":n,"Admin":k,"Consumo":c,"Cupo":q,"EnExceso":b}`), sin nombrar otras empresas; `ACCESOS_CONVERTIDOS_INSTALACION` (`SISTEMA`, 5 años por excepción) con el motivo, la cuenta de Windows y el equipo; la marca `Accesos.Modelo = 'MEMBRESIA.v1'` |
| 10 | `COMMIT`; después, el archivo `padron` de forma atómica. **Si no se puede escribir (SD0-10):** el verbo termina con un código distinto de 0 y lo dice. La base ya confirmó; la API, al leer, reescribe el disco desde la base (`RegistroPadronSellos`, ruta `ReescribirDisco`), y `verificar` y el arranque informan `PadronDiscoAusente` hasta entonces |
| 11 | Reglas de notificación (2.6): por cada empresa con filas en `ConversionReportes`, `UPDATE NotificacionesReglas SET ReporteId = @nuevo WHERE ReporteId = @original` en su base. Después, `ReglasActualizadasUtc` en `GPOS_SYSDATA`. Es idempotente y se puede repetir con `accesos --convertir --solo-reglas`. Mientras no se aplique, la regla se suspende (falla cerrado). **Si el paso no termina** (una base de empresa no responde, por ejemplo), el verbo sale con un código distinto de 0 y nombra las empresas pendientes, y `GPOS.Migracion verificar` y el arranque informan las reglas pendientes (filas de `ConversionReportes` con `ReglasActualizadasUtc` NULL). **Nada se reactiva sin el paso:** las reglas suspendidas por esta causa solo vuelven a correr después de repetir `--solo-reglas` y de que su ADMIN las reactive |

**Paso 6, sellos y padrón v2:**
1. Cada cuenta con `Valido` en el padrón v1 recibe el sello de cuenta v2 y `a`. Si no es SUPER, también un sello de membresía y `m(st = H)` por cada membresía.
2. Las cuentas inhabilitadas con sello propio reciben las `m`, sin `a`.
3. Las cuentas sin sello en orden dejan sus membresías sin sello; se legitiman después, por empresa.
4. **El padrón v2 se deriva del v1, nunca de las filas** (ADR-83, punto 2).

**Paso 7, cupo:** si `consumo(E) > cupo(E)`:
- sin `--aceptar-exceso`: 51622 con la lista de empresas y se revierte;
- con `--aceptar-exceso`: la empresa queda `EnExceso` (P-D0-D04).
- En el DEMO sin licencia, el cupo es 0 (LV-17).

**Lo que se espera:**
- **Duración:** menos de 2 s en el DEMO; con 1 000 cuentas × 5 empresas, de 1 a 3 s (*inferido*, unos 6 000 `Protect`).
- **Bloqueos:** nulos, porque la API está detenida.
- **Pérdida de datos:** ninguna. Todo lo copiado se prueba antes de borrar y queda el respaldo.

### 7.4 Reversión después de convertir
- Se restaura el respaldo previo y se reinstala la versión anterior. DB7-02 no tiene fase reversible.
- **Hay que reponer la copia previa del archivo `padron`.** El v2 no verifica con el lector v1 (cambia el propósito): no prevalece, pero deja `PadronDiscoAusente`.
- *Inferido:* falta confirmarlo con la prueba de restauración de D3. Hay un paso para devops.

### 7.5 `GPOS.Migracion verificar`
| Código | Qué verifica |
|---|---|
| V-1 | Cada `m` tiene su fila y su sello coincide. Una fila `HABILITADA` sin `m` da `MEMBRESIA_SIN_SELLO` |
| V-2 | Cada `a` tiene su fila |
| V-3 | MEM-05 |
| V-4 | MEM-06 |
| V-5 | La `BAJA` no tiene hijas |
| V-6 | `CK_Usuarios_Nivel` existe |
| V-7 | El catálogo es igual a la lista de C# y todo evento de la bitácora está en él |
| V-8 | Q24 |
| V-9 | Los `DENY` de D7-P |

---

## 8. Respaldo, restauración y retención
- **Respaldo:** sin cambios (MD-54, `usp_RespaldoCopia`).
- **Restauración de `GPOS_SYSDATA`:** aplica SL-F1 (a), ahora por membresía. Lo cambiado después del respaldo queda `FueraDePadron`, y el SUPER lo legitima por (cuenta, empresa) con el cupo. `CUENTAS_FUERA_DE_PADRON` informa también las membresías.
- **Retención:** la de 5.2 y 5.4. **Sigue pendiente el dictamen legal de los 5 años** (Ley 172-13, ADR-37). Las membresías no se purgan.

---

## 9. Privilegios de base de datos
| Identidad | DB-7 |
|---|---|
| `gpos_api` (`gpos_sistema`) | DML de `dbo` (S1, `PrivilegioMinimoSistema.cs:124`), **más** `DENY DELETE` en `UsuariosEmpresas`; `DENY INSERT, UPDATE, DELETE` en las dos tablas del catálogo; el `DENY UPDATE, DELETE` de la bitácora sigue; `EXECUTE` sobre la purga (#57). Ningún permiso DDL |
| `gpos_rpt_sis` | Solo `rptsis` v2 (T3-12 sin cambios) |
| `GPOS.Migracion` (D-09) | D7-A, D7-P y el verbo |

---

## 10. Riesgos
| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | Un evento que no está en el catálogo hace fallar la transacción | Media / Medio | Catálogo generado desde C#; prueba de D6; V-7 |
| R-2 | Las líneas heredadas resucitan las tablas globales | Alta si se olvidan / Alto | 7.1; prueba de «`sistema` dos veces después de convertir» |
| R-3 | `rptsis` v1 queda inválida al borrar columnas | Cierta sin el paso 8a / Alto | Paso 8a |
| R-4 | Q1 pasa de 2 ms (cuatro búsquedas y dos sellos en la fila) | Baja / Medio | Medición de D6; DX-1 |
| R-5 | El padrón v2 de 0,7 MB: costo de `Unprotect` y de escritura | Baja / Bajo | Se descifra solo cuando cambia; se mide con 1 000 × 5 (R-DB7-06 de BP3) |
| R-6 | `UltimoAcceso` frente a Q13 | Baja / Bajo | Sentencia aparte |
| R-7 | 51623: el servicio da de baja sin borrar antes las hijas | Media en D1 / Bajo (falla visible) | Orden de 3.7; prueba |
| R-8 | AIS-06 no es atómica (dos bases) | Baja / Bajo | Residual, como en DAT-0929 |
| R-9 | Conversión con la API en marcha | Baja / Alto | Precondición 2 |
| R-10 | Queda el `padron` v2 en el disco después de revertir | Media / Bajo | 7.4 |
| R-11 | Sin `a` para las cuentas que no son SUPER se reabre SH-5 | Cierta con el texto literal / Alto | P-D0-D01 (BP3 ya lo diseña así) |
| Residual | `sysadmin` con el anillo | Aceptado (CP-4, AP-04) | — |

---

## 11. Preguntas abiertas para el propietario
Cada una indica la recomendación, qué rompe, a quién afecta, por qué y cómo se migra. Las preguntas P-D0-01 a P-D0-07 son de BP3. **P-D0-07** es la regla de la conversión que aplica 7.3, con la observación de hechos de DX-2. La antigua P-D0-D06 (perfiles) queda cubierta por la tercera viñeta de P-D0-07.

**P-D0-D01. Entradas de cuenta del padrón para toda cuenta habilitada** (precisión del punto 9 de ADR-83, DB7-05)
- **Recomendación (a):** una entrada `a` por cada cuenta habilitada, sea SUPER o no. Es lo que ya diseña BP3 8.4.
- **Alternativa (b):** el texto literal, solo SUPER.
- **Qué rompe:** nada visible.
- **A quién afecta:** a nadie fuera del código.
- **Por qué:** con (b), quien escribe en la base puede reponer un par antiguo (hash, sello) y entrar con una contraseña vieja (SH-5; caso 5 de 3.5). Costo: unos 40 B por cuenta.
- **Cómo se migra:** con el verbo.

**P-D0-D02. Qué ve el ADMIN en la bitácora** (precisión de DB7-03, «filas de acceso»)
- **Recomendación (a):** `ACCESO` y `MEMBRESIA` de su empresa (BP3 6.4).
- **Alternativa (b):** solo `ACCESO`.
- **Qué rompe:** con (b), el ADMIN no ve las altas, bajas ni cambios de privilegios de su empresa, que TRZ-01 pone en su bitácora.
- **A quién afecta:** al ADMIN.
- **Por qué:** es la lectura de ADR-37 y de TRZ-01.
- **Cómo se migra:** es un dato del catálogo.

**P-D0-D03. Retención de los eventos de la cuenta y de los accesos denegados**
- **Recomendación (a):** 5 años (`CUENTA` y `ACCESO`, BP3 6.4).
- **Alternativa (b):** 2 años.
- **Qué rompe:** nada.
- **A quién afecta:** al SUPER; son unos 2 MB más en 5 años.
- **Por qué:** ADR-37 los incluye en la bitácora de acceso de 5 años, y la firma solo fija 2 años para factor, licencia y sello.
- **Cómo se migra:** es un dato.

**P-D0-D04. Conversión del DEMO con el cupo excedido** (precisión de DB7-05, «con control del cupo»)
- **Recomendación (a):** se detiene y lista las empresas; solo con `--aceptar-exceso` convierte y las deja `EnExceso`.
- **Alternativas:** (b) convertir siempre; (c) no convertir nunca con exceso.
- **Qué rompe:** con (c), el DEMO sin licencia (cupo 0) no se puede convertir.
- **A quién afecta:** a GSF.
- **Por qué:** es el mismo criterio de SL-F2 (b), y obliga a decidir con la lista a la vista.
- **Cómo se migra:** no aplica.

**P-D0-D05. El código del SUPER en la bitácora que ve el ADMIN**
- **Recomendación (a):** «Super Usuario», sin el código (SUP-04), con el motivo, la fecha, la IP y el canal.
- **Alternativa (b):** el código.
- **Qué rompe:** el ADMIN no distingue entre varios SUPER.
- **A quién afecta:** al ADMIN.
- **Por qué:** concilia SUP-04 con ADR-35.
- **Cómo se migra:** está en la proyección de Q8-a.

**P-D0-08. Reportes por empresa (SD0-01; la presentan el auditor y BP3).** Lo que la pregunta supone en datos:
- **(a) (recomendada):** 2.6, con `Reportes.EmpresaCodigo`, `CK_Reportes_Ambito`, `ConversionReportes`, el paso 3 b y el 11 del verbo, y `rptsis.Reporte` v2.
  - **Qué rompe:** el ADMIN ya no modifica los reportes del sistema (los duplica) ni ve los personalizados de otras empresas. En el DEMO, cada reporte personalizado queda copiado en cada empresa.
  - **Costo:** de 0,3 a 0,5 sp.
- **(b):** sin cambio de datos. El diseñador queda solo para el SUPER hasta la fase 2.

---

## 12. Decisiones candidatas a ADR (precisiones; las prepara el Maestro)
| # | Decisión | Descartadas |
|---|---|---|
| 1 | Formatos del sello de cuenta v2, del sello de membresía v1 y del padrón v2 (3.1 a 3.3, coinciden con BP3 8.4), con `a` para todos (P-D0-D01) y la `BAJA` fuera del padrón | Solo SUPER; sellar la huella de la cuenta dentro de cada membresía (obliga a volver a sellar N membresías por cada cambio de contraseña) |
| 2 | Catálogo cerrado en una tabla con FK y la retención desde el catálogo (precisión de ADR-37) | `CHECK IN` con testigo; la categoría solo en la fila |
| 3 | Un solo bloqueo de administración, la fila del padrón, con el orden de 3.7 | `sp_getapplock`; un orden por tabla |
| 4 | Tablas nuevas fuera de EF (D81-01) | Mapearlas en EF |
| 5 | Revertir después de convertir es restaurar | Un script que reconstruya el modelo global |

---

## 13. Discrepancias con el blueprint v3 y con el código (no resueltas en silencio)
| # | Tema | BP3 dice | Veo o propongo | Quién decide |
|---|---|---|---|---|
| DX-1 | Búsquedas de Q1 | «Tres búsquedas por PK y 12 o menos lecturas» | **Cuatro**: sumo `UsuariosFactor` para no hacer un segundo viaje del SUPER, con la condición de la fase A `SecretoCifrado IS NOT NULL` (`f165d1fa:…/ConsultasSegundoFactor.cs:32-35`). Sigo dentro de las 12 lecturas (*inferido*). Alternativa: tres búsquedas y la consulta del factor solo para el SUPER, como hoy (`FactorSuperUsuariosFactor.cs`) | Arquitecto de software; D6 mide |
| DX-2 | P-D0-07, motivo de la alternativa (b) | «Un cajero restringido a una sucursal de A ganaría acceso **sin restricción** a B» | **No coincide con el código.** Hoy la restricción se evalúa por el **código** de sucursal en la empresa que se elige, no por `EmpresaDefault` (`4e094323:src/GPOS.Core/Sistema/UsuariosService.cs:743-760`, `ResolverSucursal`). Copiar la restricción a cada membresía **no** amplía nada: el cajero entraría a B solo si B tiene una sucursal con ese código, y solo a ella (es H-08). La opción (a) es **más restrictiva** que hoy (quita esas entradas). Apliqué (a) en 7.3 porque reduce el acceso, pero el motivo de la hoja hay que corregirlo antes de la firma | Arquitecto Maestro (texto de P-D0-07) |
| DX-3 | `Usuarios.EmpresaDefault` | 11.1.2: retirarla junto con la sucursal | **Conservarla.** No autoriza nada, es la preferencia de empresa del inicio de sesión (DAT-0929 §3.2; ADM-03 la nombra como dato de la cuenta que el ADMIN no ve) y la conversión la necesita. Si BP3 confirma que no la usa ningún flujo, se borra en el paso 8 sin otro costo | Arquitecto de software |
| DX-4 | `FactorAlta` en el sello de cuenta | Solo en el SUPER | Apliqué «solo SUPER» (DL-05 (a)). Lo dejo como propuesta: incluirlo en toda cuenta para que el factor opcional de la fase B de ADR-81 no exija otro formato | Arquitecto de software (fase B) |
| DX-5 | `BAJA` en el padrón | `Membresias` con su estado | Los estados `H` y `S` van en el padrón; la `BAJA` sale de él, pero su fila queda sellada. No cambia la seguridad (la baja no tiene derechos) y el padrón no crece con la historia | Arquitecto de software |
| DX-6 | Columna e índice de la empresa afectada | Columnas `EmpresaAfectada` y `Categoria`; índice `(EmpresaAfectada, Categoria, MomentoUtc DESC)` | Conservo **`Empresa`** como empresa afectada (renombrarla rompe RN y la consulta de eventos, `ComandosCambioRnc.cs:81`). Índice `(Empresa, Id DESC)`, con la visibilidad tomada del catálogo por `Evento`, porque `Categoria` puede ser NULL en la historia y en los procedimientos que todavía no la envían. Paginar por `Id` evita los empates de `MomentoUtc`. Si D5 hace `Categoria` obligatoria en todas las inserciones, el índice de BP3 pasa a ser mejor | Arquitecto de software |
| DX-7 | `ACCESO_EMPRESA_DENEGADO` | `ACCESO`, sin empresa | Acepto, con la excepción explícita en `CK_BitacoraSeguridad_EmpresaCategoria`. Como no tiene empresa, el ADMIN no la ve (TRZ-04) | Ninguno (alineado) |
| DX-8 | `ACCESOS_CONVERTIDOS` | `SISTEMA`, 5 años, sin empresa | `SISTEMA` vale 2 años para el candado y la restauración (ADR-81, punto 12). Propongo una fila **por empresa** en `MEMBRESIA` (5 años, que ve su ADMIN) y una global, `ACCESOS_CONVERTIDOS_INSTALACION`, con la excepción de 5 años del catálogo (`CatalogoEventosSeguridad.RetencionAnios`) | Arquitecto de software |
| DX-9 | `ALTA_NO_DISPONIBLE` y `VINCULO_NO_ENCONTRADO` | `MEMBRESIA`, con la empresa (los ve el ADMIN) | ADM-13 manda registrarlos en la **bitácora del sistema** (solo el SUPER). Los pongo en `CUENTA`, sin empresa y con `EmpresaActua` | Arquitecto de software y auditor |
| DX-10 | Franja de errores | 51619 a 51638 | Uso 51619 a 51625. El siguiente libre es el **51626**. Los EventId 4724 a 4729 son de BP3; datos no usa ninguno | Documentador (ADR-82) |

**Pedidos que siguen abiertos para el arquitecto de software:**
- **E-SW-6:** la prueba que prohíbe `CupoUsuarios(null)` fuera del SUPER.
- **E-SW-8:** la fuente de sellos de ADR-79, que BP3 8.4 ya asigna a D3.
- **E-SW-11:** el inventario de unas 72 referencias en `src` a lo que se retira (`git grep` en `4e094323`, sin contar Web ni pruebas).

---

### Respuesta a la revisión de seguridad (2026-10-18)
Informe: `traspasos/B/2026-10-18-db7-d0-revision-seguridad.md`. Aquí solo lo que toca a este documento; el arquitecto de software aplica lo suyo en BP3.

| Hallazgo | Severidad | Qué cambié en DAT-D0 |
|---|---|---|
| SD0-01 | Alta | Nueva 2.6 (reportes por empresa, opción (a) de P-D0-08) y lo que cambia con (b). En 1.3, 2.1 y 7.2: DDL de `Reportes.EmpresaCodigo`, la FK, `ConversionReportes` y su `DENY`, `CK_Reportes_Ambito` en el verbo, y el reverso. `rptsis.Reporte` v2. Pasos 3 b, 8 h y 11 del verbo; P-D0-08 en la sección 11. **Corrección propia:** el borrado de `rpt:{id}` sí existe, y se agrega `IX_UsuariosEmpresasPermisos_Empresa_Opcion` (4.4) |
| SD0-02 | Alta | No aplica a datos (R-12, en BP3) |
| SD0-03 | Media | Caso 9 en 3.5. En 3.6, la definición de `Valido` de la membresía (padrón con la misma huella, el mismo nivel y `st = H`, y `a(c)`), dónde se aplica, la consulta de las candidatas y la prueba del caso 9 en D3 |
| SD0-04 a SD0-06 y SD0-08 a SD0-09 | Media | No aplican a datos (BP3). Para SD0-04, el nivel de la política se obtiene del padrón (`m.n = A` con `st` H o S), sin consulta nueva |
| SD0-07 | Media | Nueva 5.6: comprobación del catálogo al arrancar (Release), eventos de las rutas de fallo fuera de la sentencia del contador (con respaldo en el registro de la aplicación) y prueba de D5. La FK se mantiene |
| SD0-10 | Media | Precondición 9 de 7.3: `--instalacion-demo` o modo mínimo (solo en `EmpresaDefault`, como USER, con la lista de pendientes para el SUPER); `--motivo-exceso`; el caso de fallo del archivo `padron` en el paso 10 |
| SD0-11 | Baja | El alcance de Q6 abarca toda escritura en `EmpresasPerfiles*`, los pasos de `sistema` y el borrado de un reporte, con su prueba |
| SD0-12 y SD0-15 | Baja | No aplican a datos |
| SD0-13 | Baja | Sin cambio de datos: la «época del anillo» va en la llave de la memoria criptográfica (BP3 6.3). Los verbos de ADR-79 son los que la suben |
| SD0-14 | Baja | Tabla «Residual sin sello» en 3.5, para aceptarlo con la firma |
| SD0-16 | Baja | En 3.7: los `Protect` se calculan antes de tomar los bloqueos, D1 mide la espera y `READ_COMMITTED_SNAPSHOT` queda como opción con su criterio |
| SD0-17 | Baja | Anotado. Si el propietario prefiere la (c), es una columna `Usuarios.ClaveCumpleAdmin bit NOT NULL DEFAULT 0`, que se fija al elegir la contraseña. Va en D7-A y en el reverso, sin otro cambio (unas 0,05 sp) |
| SD0-18 | Baja | No aplica a datos (devops). El registro de `jti` consumidos sigue en memoria; no se persiste |

### Conciliación con el blueprint (2026-10-18)
La sección 14 del blueprint v3 (`docs/arquitectura/2026-10-18-db7-blueprint-v3.md`, árbol de `master`) concilia este modelo:
- **E-SW-4:** `IntentosFallidos` se retira. Cambian 2.5, 7.1 y el paso 8 (g) de 7.3.
- **E-SW-7:** los pasos únicos de `PermisosService` corren dentro del verbo. Se agrega la precondición 8 de 7.3.
- **DX-1 a DX-10:** quedaron resueltas sin otros cambios en este documento.
- **Cita de líneas:** BP3 cita `EsquemaSistema.cs:108-109` en `55365806`; en `4e094323` son las `:105-106`. Dejo citados los dos commits.

### Supuestos
| # | Supuesto |
|---|---|
| S-1 | El #57 entra con el esquema en la versión 5 y DB-7 usa la 6 |
| S-2 | Las cifras de tiempo, tamaño y esfuerzo son *inferidas* (±30 %); las mide D6 |
| S-3 | `EnsureCreated` crearía las tablas mapeadas en EF sin disparadores; por eso quedan fuera de EF (*inferido*) |
| S-4 | En Estricto, la versión anterior arranca con una marca mayor |
| S-5 | El árbol `GPOS-B-integracion` cambió de `b/une-73` (`4e094323`) a `b/une-57` (`f165d1fa`) mientras lo leía; cito por commit y no lo toqué |
| S-6 | **51619 estaba libre** (`git grep` en las 121 ramas de origin; solo aparece en la nota de ADR-82). Uso 51619 a 51625 dentro de la franja de BP3 |

### Cierre
- Estado: Completado (modelo D0 alineado con BP3, con la respuesta a la revisión de seguridad; P-D0-D01 a P-D0-D05 y P-D0-08, Pendientes de firma; el auditor confirma las correcciones).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-18-db7-d0-modelo-datos.md`
- Supuestos: S-1 a S-6.
- Decisiones candidatas a ADR: las 5 de la sección 12 (precisiones de ADR-37 y ADR-83).
- Entregas a otros agentes:
  - arquitecto-software → DX-1, 3, 4, 5, 6, 8 y 9 y los E-SW abiertos;
  - arquitecto-maestro → corregir el motivo de P-D0-07 (DX-2) e incluir P-D0-D01 a D05 en la hoja del diseño;
  - auditor-seguridad → confirmar SD0-01, SD0-03, SD0-07, SD0-10, SD0-11, SD0-14 y SD0-16 en esta versión;
  - arquitecto-software → en BP3: rutas de reportes por empresa y duplicado (2.6), uso de la definición de `Valido` (3.6) y la época del anillo (SD0-13). Los EventId de 5.6 (4733 y 4734) ya están alineados con BP3;
  - desarrollador-backend → D7-A, D7-P, el verbo y el retiro de las líneas heredadas;
  - devops → el procedimiento de conversión y la reversión con `padron`;
  - B ola 5 → `rptsis` v2;
  - documentador → 51619 a 51625 en ADR-82.
- Próximo paso recomendado: el auditor confirma las correcciones (objetivo: 10-29) y el Maestro lleva P-D0-08 y la hoja del diseño a la firma (objetivo: 2026-10-31).
