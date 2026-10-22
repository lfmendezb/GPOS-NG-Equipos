[Blueprint Técnico] Estado del documento: **Completado (blueprint previo de T4-06)**. Tiene **9 preguntas abiertas para B** (sección 12). Tres de ellas (P-1 a P-3) deben responderse antes de empezar el código. Nada de esto está construido.

# T4-06 · La lista P-2 vacía y el reenvío por ruta (PR 6): blueprint previo de A

- **Fecha:** 2026-10-22
- **Autor:** arquitecto-software del equipo A (encargo de B: `avisos/B-a-A/2026-10-22-ola5-tramo4-tareas-para-a.md`, tarea 1)
- **Base leída** (solo lectura con `git show` y `git grep`, sin cambiar de rama; no compilé ni ejecuté pruebas):
  - código: `origin/feature/modelo-ng` `b4378650`, que incluye T4-05 (#121 `7b50b810` y #129 `e3e729c1`);
  - documentos: `origin/master` `3254be35`;
  - PR-4: `origin/a/adr90-pr4-cableado-api` (#139, abierto).
- **Fuentes:**
  - PLAN: `docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md`, T4-06 (`:184-200`) y las secciones 6.2, 6.4 y 7;
  - HOJA: `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md`, A-2 (`:39`, `:108-121`) y A-5 (`:166-170`);
  - ADR-109 (`master`): cl. 8 y P-2 (`:77`), nota del tramo 4 y Q-6 (`:98-105`), calendario A-2 (`:117`);
  - T4-10OCT, sección 5.3 y 5.4 y punto 7.1 (`GPOS-NG-Equipos/traspasos/B/2026-10-10-plan-ola5-tramo4.md:139-198`);
  - diseño de las vistas de B, sección 4, con el SQL N1 a N7 (`traspasos/B/2026-10-10-ola5-tramo4-vistas.md:81-107` y `traspasos/B/ola5-tramo4/21-consultas-nuevas.sql`).
- **Convenciones:**
  - [V] = verificado en el código o el documento citado, con `ruta:línea`;
  - [I] = inferido;
  - dp = días-persona nominales con agente; **todas las cifras de esfuerzo son inferidas, con un margen de ±40 %**.

---

## 1. Contexto y alcance

T4-06 cumple la **condición de publicación firmada** de P-2: la lista `EnLaPrincipal` se vacía y se elimina, y ningún reporte del sistema se ejecuta con la conexión de escritura (ADR-109 `:77` y `:98`; HOJA A-2: no se recorta). El encargo de B tiene cuatro partes, y este documento suma dos que no estaban escritas:

| # | Parte | Origen |
|---|---|---|
| 1 | Reescribir las 11 definiciones de la P-2 sobre `rpt`, con totales en moneda base | PLAN `:187` |
| 2 | Eliminar `EnLaPrincipal`, `IntactoEnLaPrincipal` y `EnLaPrincipalAsync` | PLAN `:188` |
| 3 | `GET /api/reportes` lo responde siempre la principal (H-T4-12). Si la API de reportes cae, la lista se ve y cada reporte da 503 | PLAN `:189` |
| 4 | Q-6: en Release, la principal no arranca sin el reenvío, y el camino de ejecución de `ReportesService` se compila solo en Debug | PLAN `:190` |
| 5 (**nueva**) | **Guardar** del diseñador ejecuta el SQL en la principal: `GuardarAsync` → `ValidarDefinicionAsync` → `EsquemaAsync` → `EjecutarLecturaAsync` con la fábrica de escritura (`ReportesService.cs:105-113`, `:221`, `:406-415`, `:420`) [V]. Si ese camino queda solo en Debug, Release no compila o no valida. Ver H-A06-01 y P-1 | Este blueprint |
| 6 (**nueva**) | Los **programados** y «Ejecutar ahora» llaman a `ReportesService.EjecutarAsync` (`TrabajoNotificaciones.cs:45` y `:59`) [V]. Si T4-06 se une antes que T4-04, Release no compila. Ver P-2 | Este blueprint |

**No cubre:**
- el tablero (T4-07);
- el render (T4-01 y T4-02);
- la consulta de facturas (T4-08), cuyo truncado de 10.000 filas en `ConsultaFacturasEndpoints.cs:71` **sigue** en Release hasta T4-08;
- el resto de T4-04 (adjuntos por la API de reportes).

### 1.1 H-T4-11: ¿existen las vistas que necesita la P-2? **Sí, todas** [V]

T4-05 ya creó todo lo que leen las 11 definiciones. El contrato está en la 1.3 (`contrato-vistas.v1.json:3`) y la migración es `Ola5VistasTramo4` (`database/ola5/rpt-vistas-tramo4.sql:46-397`).

| Reporte | Código | Vista `rpt` (1.3) | Catálogos que usa |
|---|---|---|---|
| 8 | `CXC-ANTIGUEDAD` | `rpt.CxcDocumento` (`:46`) | `rpt.CatSucursal` |
| 9 | `CXC-ANTIGUEDAD-RESUMEN` | `rpt.CxcDocumento` | `rpt.CatSucursal` |
| 10 | `CXC-ESTADO-CUENTA` | `rpt.CxcDocumento` | `rpt.CatSucursal` |
| 27 | `DASH-CXC-ANTIGUEDAD` | `rpt.CxcDocumento` | — |
| 13 | `CXP-FACTURAS` | `rpt.Compra` (`:127`) | `rpt.CatSucursal` |
| 14 | `CXP-POR-SUPLIDOR` | `rpt.Compra` | `rpt.CatSucursal` |
| 15 | `CXP-ANTIGUEDAD` | `rpt.CxpDocumento` (`:89`) | `rpt.CatSucursal` |
| 16 | `CXP-PAGOS` | `rpt.DocBanco` (`:181`) | `rpt.CatSucursal` |
| 21 | `EF-DOCS-BANCARIOS` | `rpt.DocBanco` | `rpt.CatSucursal` |
| 22 | `EF-CAJA-CHICA` | `rpt.CajaChica` (`:230`); con Q-2, nunca `rptc` | `rpt.CatSucursal` |
| 23 | `EF-MOV-CAJA` | `rpt.MovimientoCaja` (`:315`); con Q-4, el monto de cierre va en NULL | `rpt.CatSucursal` |

**Faltan:** ninguna vista.
- No existe `rpt.CatZona`, pero `rpt.CxcDocumento` ya trae `ZonaCodigo` (`:62`).
- No hace falta DDL ni subir el contrato. Lo que queda abierto de H-T4-11 es solo la lista con sus 11 códigos (`ReportesSemilla.cs:136-140`), y eso es justamente T4-06.

---

## 2. Módulos y dependencias

No hay proyectos nuevos ni dependencias nuevas.

| Proyecto | Cambio en T4-06 |
|---|---|
| `GPOS.Core` | Semilla reescrita. `ReportesService` se parte en dos: la ejecución queda en un archivo que se compila solo en Debug. Nueva interfaz `IDetectorColumnas`, que usa Guardar |
| `GPOS.Api` | Las rutas de reportes cambian: la lista va siempre local y el resto se reenvía sin consultar ninguna lista. Q-6 entra en `AgregarReenvioReportes`. Implementación Release de `IDetectorColumnas` por la canalización. Guarda Release en `EjecucionReglas` |
| `GPOS.Reportes*`, `GPOS.Web`, `GPOS.UI.MAUI` | Sin cambios. Rutas, métodos y DTO iguales (cl. 8) |

**Dependencias:** sin ciclos. `GPOS.Api` → `GPOS.Core` (la interfaz va en Core y la implementación en Api, igual que hoy pasa con `ISesionActual`).

## 3. C4

No aplica: los contenedores y los flujos son los del tramo 3. Solo cambia **qué ruta** decide reenviar.

## 4. Modelo de dominio

No cambia. Hay dos reglas de lectura, ya firmadas:
- **Monto en moneda base por fila:** `ROUND(monto × tasa, 2)`. Las vistas lo traen calculado como `*Base` (P-4 y P-5 de ADR-109; `rpt-vistas-tramo4.sql:13`).
- **Días vencidos:** se calculan en el SQL del reporte con el «hoy» de la empresa, `DATEDIFF(DAY, Vence, CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME())))`. Las vistas no pueden usar `SYSUTCDATETIME` (`rpt-vistas-tramo4.sql:11-12`). El SQL del diseñador sí puede: ScriptDom no rechaza funciones (`AnalizadorSql.cs:105-121`) y la semilla actual ya lo hace (`ReportesSemilla.cs:79`) [V].

---

## 5. Contratos de la API interna (rutas de la principal)

En todas las rutas, la empresa sale del token (cl. 6) y no hay permisos nuevos.

| Ruta | Método | Antes [V] | Después | Permiso | Errores |
|---|---|---|---|---|---|
| `/api/reportes` | GET | Se reenvía si hay dirección (`ReportesEndpoints.cs:24-29`) | **Siempre local**: `ReportesService.ListarAsync` sobre `GPOS_SYSDATA`. No llama a la API de reportes | Autenticado; `Permisos.VeReporte` (`ReportesService.cs:88`) | Ninguno nuevo. **200 aunque la API de reportes no responda** |
| `/api/reportes/{id}` | GET | Se reenvía salvo la P-2 (`:30-38`) | Se reenvía siempre que haya dirección (en Release, siempre). Sin dirección (solo Debug), local | El de la API de reportes (`ContextoReportes.VeReporte`) | 503 `REPORTES_NO_DISPONIBLE` si la API de reportes cae (P-8) |
| `/api/reportes/{id}/ejecutar` | POST | Se reenvía salvo la P-2 (`:40-49`) | Igual que la anterior | Igual | 503, 403, 422 y 429, los de hoy |
| `/api/reportes/{id}/exportar/{formato}` | GET | `ExportarAsync` por la canalización, salvo la P-2, que la arma la principal (`:52-71`) | Siempre por la canalización con evidencia. El armado local queda solo en Debug | `rptexportar` | Los de hoy |
| `/api/admin/reportes/detectar` y `/vista-previa` | POST | Se reenvían si hay dirección (`:91-111`) | Igual. El camino local queda solo en Debug | ADMIN | Los de hoy |
| `/api/admin/reportes` (Guardar) | POST | Valida el SQL **en la principal** (`ReportesService.cs:221`) | En Release, valida las columnas con la API de reportes por la canalización, con el token del ADMIN (P-1 (a)) | ADMIN | **Nuevo:** 503 `REPORTES_NO_DISPONIBLE` si la API de reportes cae. El 400 de regla «La consulta no devuelve: …» se mantiene |

**Validaciones:** las de hoy. Q-6 no agrega reglas de entrada.

---

## 6. Interfaces entre módulos

- **`IDetectorColumnas`** (en `GPOS.Core/Servicios`):
  - firma: `Task<IReadOnlyList<(string Nombre, string Tipo)>> DetectarAsync(string consulta, CancellationToken ct)`;
  - Debug sin dirección: la implementa el `EsquemaAsync` actual;
  - con dirección (Release siempre): la implementa `GPOS.Api` con un método nuevo de `ReenvioReportes`. Ese método hace un POST programático a `/api/admin/reportes/detectar` por la misma canalización con dueño verificado (`ReenvioReportes.cs:161-182`), lleva el token de la petición en curso y deserializa `List<ReporteColumnaDto>`;
  - el SQL corre con `gpos_rpt` sobre `rpt`, que es el mismo usuario con el que se ejecutará después. Así se cierra la inconsistencia actual: hoy se valida con escritura y se ejecuta con lectura.
- **`ReenvioReportes`** deja de recibir `ReportesService` en las rutas y de llamar a `EnLaPrincipalAsync`. El reenvío pasa a ser **por ruta** (T4-10OCT, sección 6).
- **`EjecucionReglas.ReporteAsync`** (`TrabajoNotificaciones.cs:42-95`): en Release, hasta que se una T4-04, falla cerrada con una `ReglaNegocioException` que queda como resultado de la regla (`:34-38`). Ver P-2.

---

## 7. Estructura de proyectos y carpetas: archivos que se tocan

### 7.1 Código

| Archivo | Líneas hoy [V] | Cambio |
|---|---|---|
| `src/GPOS.Core/Sistema/ReportesSemilla.cs` | `:17-33` (`SaldosCxc`, heredado), `:63-81` (`SaldosCxp`), `:83-98` (`Compras`), `:100-114` (`DocsBancarios`), `:132-140` (`EnLaPrincipal`), `:202-220` (8, 9 y 10), `:249-274` (13 a 16), `:297-331` (21 a 23), `:352-355` (27), `:488` (`HuellasCodigo`), `:490-497` (`IntactoEnLaPrincipal`) | Las 4 fuentes pasan a `SaldosCxcRpt`, `ComprasRpt`, `SaldosCxpRpt` y `DocsBancariosRpt`, más las consultas del 22 y el 23 (sección 7.3). Se borran `EnLaPrincipal`, `IntactoEnLaPrincipal` y `HuellasCodigo` (su único uso es `:497`). **Se conserva `HuellasVersion1` (`:383-394`)**: con ella, `ActualizarSistemaAsync` (`:401-419`) lleva a la nueva versión los reportes instalados intactos y respeta los que modificó un ADMIN. `Detalles` (`:507-511`) y `EnlaceDe` (`:514-520`) no cambian, porque se conservan los campos `Documento` y `Factura` |
| `src/GPOS.Core/Servicios/ReportesService.cs` | `:64-74` (`EnLaPrincipalAsync`); ejecución en `:157-175`, `:252-399`, `:401-485`; tope en `:319` y truncado en `:389`; fábrica de escritura en `:420`; Guardar en `:178-225` (`EsquemaAsync` en `:221`) | Se borra `EnLaPrincipalAsync`. La ejecución se mueve **completa** a un archivo nuevo, `ReportesService.Ejecucion.cs`, encerrado en `#if DEBUG`: los dos `EjecutarAsync`, `ExportarAsync`, `VistaPreviaAsync`, `DetectarColumnasAsync`, `DetalleAsync`, `EsquemaAsync`, `EjecutarLecturaAsync`, `Funcion`, `TipoDe` y `Etiqueta`. En `ReportesService.cs` quedan el catálogo, Guardar, Eliminar y `ValidarConsulta` (que es estático y lo usan las pruebas). Guardar recibe `IDetectorColumnas`. Con esto **desaparece en Release el truncado de 10.000 filas** de los reportes; `ResultadoReporte.MaximoFilas` (`Reportes.cs:162`) sigue como tope válido de `Limite` (`:198`) |
| `src/GPOS.Core/GPOS.Core.csproj` | No tiene la guarda del símbolo DEBUG que sí tiene `GPOS.Api.csproj:42-51` [V] | Agregar la misma guarda, para que una compilación Release con `DefineConstants=DEBUG` no reactive la ejecución en la principal (0,1 dp) |
| `src/GPOS.Api/Endpoints/ReportesEndpoints.cs` | `:9-15` (comentario), `:24-29`, `:30-38`, `:40-49`, `:52-71`, `:91-111` | La lista va siempre local. En las demás rutas, `if (reenvio.Habilitado) { reenviar }` seguido del camino local dentro de `#if DEBUG` (en `#else`, 503: es inalcanzable, porque Release no arranca sin reenvío). Se quita `ReportesService` de las firmas que ya no lo usan en Release |
| `src/GPOS.Api/Endpoints/ReenvioReportes.cs` | `:18-40` (opciones), `:226-240` (`AgregarReenvioReportes`) | Q-6 entra en `AgregarReenvioReportes`, que se llama en `Program.cs:233`, y **no en `Program.cs`**. Se agrega `public static bool CompilacionDepuracion` (true con `#if DEBUG`) y `ValidarModo(op, depuracion)`: sin dirección y sin Debug, `InvalidOperationException` con el texto «GPOS:Reportes:Reenvio:Direccion es obligatoria en esta compilación (ADR-109 cl. 8, Q-6)…». Se agrega `DetectarAsync` (sección 6) |
| `src/GPOS.Api/Servicios/` (archivo nuevo, `DetectorColumnasReenvio.cs`) | — | Implementación Release de `IDetectorColumnas`. Se registra en `AgregarReenvioReportes`, no en `Program.cs` |
| `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs` | `:42-95` (`ReporteAsync`; usos en `:45` y `:59`) | Guarda `#if DEBUG` alrededor de la ejecución local; en Release, regla fallida (P-2). **Si T4-04 se une antes, no se toca** |
| `src/GPOS.Api/Program.cs` | `:231` (`AddScoped<ReportesService>`), `:233` | **Ninguna línea.** `ReportesService` sigue registrado (catálogo, diseñador y notificaciones) |

### 7.2 Otros archivos afectados que T4-06 no edita (entregas)

| Archivo | Por qué [V] | A quién |
|---|---|---|
| `instalador/Demo/Publicar-PaqueteDemo.ps1:130-134` | Rechaza que el DEMO traiga `Reenvio:Direccion`. Con Q-6, una principal Release sin dirección **no arranca**, así que el DEMO de `feature/modelo-ng` deja de arrancar (es más que «no muestra la P-2» de H-T4-07) | devops de A (tarea 3) |
| `tests/GPOS.EnsayoImplantacion/iniciar-api.ps1:22` y `README.md:17-18` | El ensayo corto arranca la principal **Release** sin la API de reportes | devops o QA (P-4) |
| Guiones del laboratorio de ADR-90 (#146) y el instalador (#124) | [I] Si instalan la principal sin la API de reportes, no arranca | devops de A |

### 7.3 Las 11 definiciones

**Base del SQL.** Se usan los bloques N1 a N7 de B (`21-consultas-nuevas.sql`), que B ya ejecutó como `gpos_reportes` con datos de prueba (`2026-10-10-ola5-tramo4-vistas.md:83-97`). Hay que hacerles tres ajustes obligatorios:
- **quitar los `ORDER BY`**: los rechazan `ValidarConsulta` (`ReportesService.cs:243-244`) y el analizador (`AnalizadorSql.cs:119`). El orden lo da `OrdenarPor`;
- **sufijo `Base` en los tramos totalizados** de los reportes 8 y 15: `CorrienteBase`, `De1a30Base`, `De31a60Base`, `De61a90Base` y `Mas90Base`. N1 y N3 los llaman `Corriente`… aunque ya están en moneda base, y la regla de `SemillaReportesOla5Tests.cs:35-36` (MONEDA totalizada sin agregación que no termina en `Base`) los rechazaría. Ver P-5;
- **conservar los campos que usan los enlaces y los detalles**: `Documento`, `Factura`, `Cliente` y `Suplidor`.

**Columnas.** Las de la propuesta de B (`2026-10-10-ola5-tramo4-vistas.md:100-107`), con esa corrección de nombres:

| Reporte | Fuente | Columnas que cambian (MD = `MontoDocumento`, se muestra sin totalizar; T = totalizada en moneda base) | Filtro y orden |
|---|---|---|---|
| 8 `CXC-ANTIGUEDAD` | N1 | `Balance` MD; `BalanceBase` T; tramos `*Base` T; `NCF` opcional | El de hoy |
| 9 `CXC-ANTIGUEDAD-RESUMEN` | N1 | Solo `BalanceBase` y tramos `*Base` con SUMA | El de hoy |
| 10 `CXC-ESTADO-CUENTA` | N1 | `Monto`, `Aplicado` y `Balance` MD; `MontoBase` y `BalanceBase` T; `NCF` visible (Q-3) | Cliente obligatorio (igual) |
| 27 `DASH-CXC-ANTIGUEDAD` | N1 | `Rango` y SUMA de `BalanceBase` | Igual |
| 13 `CXP-FACTURAS` | N2 | `SubTotal`, `Itbis` y `Total` MD; `TotalBase` T. Opcionales: `SubTotalBase`, `ItbisBase`, `Descuento`, `Tasa`, `Almacen` y `Termino` | Igual |
| 14 `CXP-POR-SUPLIDOR` | N2 | SUMA de `SubTotalBase`, `ItbisBase` y `TotalBase` | Igual |
| 15 `CXP-ANTIGUEDAD` | N3 | Como el 8 | Igual |
| 16 `CXP-PAGOS` | N5 | `Monto` MD; `MontoBase` T | Igual |
| 21 `EF-DOCS-BANCARIOS` | N4 | `Monto` MD; `MontoBase` T (sin signo, como hoy; P-6) | Igual |
| 22 `EF-CAJA-CHICA` | N6 | Etiqueta «RNC o cédula» (siempre abreviada, Q-2); `Monto` e `Itbis` MD; `MontoBase` e `ItbisBase` T; `Moneda` opcional | Igual |
| 23 `EF-MOV-CAJA` | N7 | `Moneda` visible; `Ingreso` y `Egreso` MD; `IngresoBase` y `EgresoBase` T; `Usuario` opcional; «Origen» con las etiquetas de caja | **`HOY` por omisión** (Q-T4D-02, firmada) |

**Qué cambia para el usuario** (lo documenta el PR):
- totales en moneda base;
- NCF del B11 en el 15;
- vocabulario de `caja.Movimiento` en el 23.

**Qué no rompe nada:** BP2 nunca salió a producción.

**Copias que modificó un ADMIN:** conservan su SQL sobre tablas. Ahora van a la API de reportes y fallan con el rechazo del esquema, que es lo aceptado en T3-02 (`ReportesF9Tests.cs:281-302`).

---

## 8. Requisitos de seguridad de arquitectura

- **Autenticación:** sin cambios (introspección y E1).
- **Autorización:**
  - la lista usa `Permisos.VeReporte` de la principal y la definición usa la de la API de reportes (`ContextoReportes.cs:46-47`, con el nivel **efectivo**: el menor entre el claim y `rptsis`);
  - pueden divergir. Por ejemplo, un SUPER con el nivel de `rptsis` rebajado, o después de T1-5 y D5 cuando el nivel salga de la membresía. Lo vigila `ListaReportesContratoTests` (R-3).
- **Aislamiento:** la empresa sale siempre del token y no hay ruta nueva.
- **Ejecución:** ningún SQL del diseñador corre con la conexión de escritura en Release:
  - **ni al ejecutar ni al guardar** (H-A06-01);
  - **ni en los programados** (P-2): hasta T4-04, cierra H-T4-06 en Release por falla cerrada.
- **Secretos:** ninguno nuevo. El token del ADMIN viaja por la canalización con dueño verificado, como hoy.
- **Configuración:**
  - Release exige `Reenvio:Direccion`, y la dirección exige Windows (`ReenvioReportes.cs:232-234`). Por eso **en Linux la principal Release no arranca** hasta que exista el socket Unix de ADR-129 (P-3);
  - la guarda del símbolo DEBUG se extiende a `GPOS.Core`.

**Hallazgo H-A06-01 (Media; que el auditor-seguridad confirme la severidad):**
- **Qué pasa:** «Guardar» del diseñador ejecuta el SQL del ADMIN en la principal con el inicio de sesión de escritura, aunque el reenvío esté encendido (`ReportesService.cs:221` → `:409` → `:420`) [V].
- **Qué lo contiene:** `TOP (0)`, transacción que siempre se revierte y la lista de palabras prohibidas. Pero es código de usuario junto a la escritura, el riesgo R-C5 por el que se firmó ADR-109.
- **Qué no lo listaba:** ni la auditoría del #101 ni el PLAN.
- **Cómo se cierra:** con P-1 (a).

## 9. Sincronización

No aplica.

## 10. Necesidades para Datos e Integraciones

- **Datos:** ninguna. No hay DDL ni sube el contrato. Solo se pide que el arquitecto-datos de B confirme el signo de `caja.Movimiento.Monto` (positivo = ingreso), que N7 supone [I: `CK_CajaMovimiento_Monto` solo exige que sea distinto de 0, `CajConfiguracion.cs:58`].
- **Integraciones:** ninguna.

---

## 11. Pruebas

### 11.1 Que se reescriben

| Prueba | Hoy [V] | Después |
|---|---|---|
| `GPOS.Reportes.Tests/AuditoriaAdr109Tests.P2_la_lista_de_reportes_que_ejecuta_la_principal_solo_puede_encogerse` | `:30-49`: busca el bloque `EnLaPrincipal` | `P2_la_lista_ya_no_existe_y_ningun_reporte_del_sistema_lee_fuera_de_rpt`. Es textual, porque el proyecto no referencia Core (`:9-11`): `EnLaPrincipal` e `IntactoEnLaPrincipal` no aparecen en `src`, y todo `FROM` o `JOIN` de los literales SQL de `ReportesSemilla.cs` nombra `rpt.` (nunca `rptc.`, porque `gpos_rpt` no lo ve, cl. 4) |
| `…Todas_las_rutas_de_reportes_reenviables_pasan_por_el_reenvio_o_por_la_lista_P2` | `:80-97` | `g.MapGet("/"` sale del recorrido, y se agrega la comprobación de que el cuerpo de `"/"` **no** contiene `reenvio.` (H-T4-12). El conteo del tablero (`:96`, igual a 2) no se toca: lo cambia T4-07 |
| `GPOS.Tests/ModeloNg/SemillaReportesOla5Tests.Los_registrados_…_y_P2_lista_los_que_no_tienen_vista` | `:52-65` (`:61-64`, «11 en la principal») | `Ningun_SQL_del_sistema_lee_tablas`: todas las definiciones SQL contienen `rpt.`. La teoría `DeVistas` (`:21-50`) pasa sola a cubrir las 11 con `gpos_reportes` |
| `Mvp/ReportesF9Tests.T3_02_un_reporte_P2_modificado_por_el_ADMIN_no_corre_en_la_principal` | `:281-302` | `Ningun_reporte_del_sistema_se_ejecuta_en_la_principal`: para cada reporte del sistema de la lista, `ejecutar` responde 200 con `Metadatos["rnc"]`. Ese metadato solo lo pone la API de reportes; el camino local no lo llena (`ReportesService.cs:384`). Se conserva el caso de la copia modificada por un ADMIN que lee tablas: no responde 200 |
| `Mvp/ReportesF9Tests.T3_06_la_exportacion_de_la_principal_exige_exportar_reportes` | `:335-364` (usa `CXP-FACTURAS` como «principal») | Pasa a ejecutarse sobre la API de reportes: el mismo 403 sin `rptexportar` (con `PRIVILEGIO_REQUERIDO`) y 200 con él |
| `ReportesF9Tests.F9_reportes_basicos_por_la_API_de_reportes` | `:276-278`: «P-2 sigue en la principal» | Esa aserción se cambia por la ejecución reenviada |
| `ReportesF9Tests.T3_11_toda_exportacion_deja_su_evidencia_…` | `:570-580` (`CXP-FACTURAS` «la arma la principal») | Pasa a exportación reenviada con su evidencia. **No está en la lista de B** |
| `ReportesF9Tests.T3_11_sin_evidencia_no_se_exporta_y_responde_503` | `:665-669` | El caso «la arma la principal» pasa a ser reenviado. **No está en la lista de B** |
| `ReportesF9Tests.AE_02_…programado…` | `:408-457` (`CXP-FACTURAS` por `EjecucionReglas`) | Sin cambios en Debug, porque la ejecución local existe. Si T4-04 se une antes, la adapta B |
| `ReportesTests` y `ModeloNg/ReferenciasOla4Tests` | `ReportesTests.cs:20-32`, `:68-77`; `ReferenciasOla4Tests.cs:93-105` | Siguen en Debug. Se revisan las aserciones que dependen de columnas (`Totales.Max()` = 118 del 15 pasa a la columna `BalanceBase`) [I: que la base de la fixture tenga la 1.3] |

### 11.2 Nuevas

| Prueba | Proyecto | Qué comprueba |
|---|---|---|
| `ReenvioReportesTests.En_Release_la_principal_no_arranca_sin_el_reenvio` | `GPOS.Tests/Mvp` (Neutral, junto a `ReenvioReportesSeguridadTests.cs:22-38`) | `ValidarModo(sin dirección, depuracion: false)` lanza y `ValidarModo(sin dirección, true)` no lanza. Además, una prueba **textual** de que `ReportesService.Ejecucion.cs` empieza con `#if DEBUG` y termina con `#endif`, y de que `GPOS.Core.csproj` tiene la guarda. La suite corre en Debug, así que el comportamiento Release solo se prueba por la costura |
| `ReenvioReportesTests.La_lista_la_responde_la_principal_aunque_la_API_de_reportes_no_responda` | `GPOS.Tests/Mvp` (NG; fábrica de la principal con una canalización que nadie atiende) | `GET /api/reportes` responde 200 con los 26 del sistema, y `POST /{id}/ejecutar` responde 503 `REPORTES_NO_DISPONIBLE`. **El PLAN la pone en `AuditoriaAdr109Tests`, pero ese proyecto no levanta la API**: allí queda solo la parte textual |
| `ListaReportesContratoTests.La_lista_y_la_definicion_coinciden_en_visibilidad_para_USER_ADMIN_y_SUPER` | `GPOS.Tests/Mvp` (con `ReportesF9Fixture`) | Para USER sin permisos, USER con `ReportesVentas` y `ReportesCompras`, ADMIN y SUPER: cada `Id` de la lista responde 200 en `GET /{id}`, y uno que no está en la lista responde 403 o 404. **Hoy no hay ayudante para el SUPER** (`ApiMvpFactory.cs:158` solo tiene `AdminAsync`) (P-7) |
| `Guardar_valida_las_columnas_en_la_API_de_reportes` | `GPOS.Tests/Mvp` (F9) | Con el reenvío encendido, un SQL sobre tablas (`FROM cxc.Cuenta`) **no se guarda**: 400 «La consulta no devuelve…» o el rechazo de la API de reportes, nunca 200. Hoy se guardaría (P-1) |
| `P2_los_11_reportes_corren_en_la_API_de_reportes` | F9 | Los 11 responden 200 por la principal, con las columnas de su definición. Los datos ya los prueban `VistasP2Tests` (T4-05); aquí no se rehace el escenario completo de T4-10OCT 7.1.4, porque cuesta unos +0,75 dp. Ver P-9 |

**Criterio de PR** (nuevo, por el `#if`):
- `dotnet build src/GPOS.Api -c Release` en verde. **La suite compila solo Debug**, así que un error dentro del `#else` no lo detecta nadie más;
- suite oficial (`--filter "Transicion!=Ola5&Transicion!=Defecto"`), `GPOS.Reportes.Tests` y `GPOS.Web.Tests`, ejecutadas solas.

---

## 12. Orden de trabajo (tareas pequeñas; un PR)

| # | Tarea | Depende de | dp [I] | ¿Compila? |
|---|---|---|---|---|
| TA-0 | Respuestas de B a P-1, P-2 y P-3; rebase sobre la punta; confirmar que T4-04 no se une antes (o adaptar 7.1) | — | 0,1 | No |
| TA-1 | Semilla: 11 definiciones (sección 7.3); borrar `EnLaPrincipal`, `IntactoEnLaPrincipal` y `HuellasCodigo`; reescribir `SemillaReportesOla5Tests` y ajustar `ReportesTests` y `ReferenciasOla4Tests` | TA-0 | 1,0 | Sí: pruebas NG de semilla |
| TA-2 | `ReportesService` partido en dos, con `#if DEBUG`; `IDetectorColumnas` y sus dos implementaciones; guarda en `GPOS.Core.csproj` | TA-1 | 0,75 | Sí |
| TA-3 | `ReportesEndpoints` (lista local), Q-6 en `AgregarReenvioReportes`, guarda de `EjecucionReglas` | TA-2 | 0,5 | Sí, más Release |
| TA-4 | `AuditoriaAdr109Tests` (dos cambios y la parte textual de Q-6) | TA-3 | 0,3 | Sí (`GPOS.Reportes.Tests`) |
| TA-5 | F9 (T3_02, T3_06, F9 básica y las dos T3_11), `ReenvioReportesTests`, `ListaReportesContratoTests` (con el SUPER), Guardar y P-2 | TA-3 | 1,75 | Sí: suite F9 |
| TA-6 | Compilación Release, suite oficial sola, PR (cita ADR-109 cl. 8, P-2 y Q-6, y PLAN T4-06) y texto de «qué cambia» | TA-1 a TA-5 | 0,5 | Sí: suite completa |
| | **Total** | | **4,9 dp** (de 2,9 a 6,9) | |

**Frente al PLAN (4,5 dp):** sube 0,4 dp, dentro del margen. Viene de Guardar por la canalización (+0,5), la guarda de las notificaciones (+0,1), el SUPER (+0,2) y las dos T3_11 que no estaban listadas, y baja porque no se rehace el escenario de datos de 7.1.4 (−0,75).

**Calendario propuesto:**
- del 11-03 al 11-07: TA-0 a TA-5, con 1 agente compilando y el otro cupo de la PC A libre;
- 11-09 o 11-10: TA-6 (suite sola);
- **unión antes del 11-11**, solo con orden del propietario.

**Holgura:** 1 día. Si la suite corre en C (`delegacion-a-equipo-c`), se gana medio día.

**Se puede adelantar:** TA-1 no toca `Program.cs` ni archivos de PR-4. Si la capacidad de A lo permite, puede empezar antes del 11-03 y reducir el riesgo de la fecha (R-4).

---

## 13. Choques

| Con | Archivos en común [V] | Regla |
|---|---|---|
| **PR-4 (#139)**, `Program.cs` | PR-4 cambia `Program.cs` en cuatro bloques (`+16 −1`) y `GPOS.Api.csproj` (paquete WindowsServices y `GPOS.Comun.Servidor`). **Con este diseño, T4-06 no toca `Program.cs`**: Q-6 va en `ReenvioReportes.cs:226-240` y el registro nuevo, también | El choque (a) del encargo desaparece. Igual se recomienda empezar el código después de PR-4, por la capacidad de A, y rebasar sobre él. Si PR-4 no se une antes del 11-10, T4-06 no lo espera |
| **T4-02 (B, desde el 11-16)** | `ReportesEndpoints.cs:62-70` (camino local de exportación con `ExportadorReporte`, que T4-02 pasa a `ClienteRender`); `AuditoriaAdr109Tests` (T4-02 renombra `GPOS_Api_no_agrega_motores…`, `:105-115`); `ReportesF9Tests` | T4-06 se une primero (11-11) y T4-02 rebasa. Después de T4-06, el PDF de la P-2 en la principal ya no existe en Release: T4-02 solo lo atiende en Debug |
| **T4-04 (B, con el token de A, tarea 2)** | `TrabajoNotificaciones.cs:42-95`, `AE_02` | Si T4-04 se une antes, TA-3 no toca `EjecucionReglas`. Si se une después, sustituye la guarda Release de T4-06. Lo acuerdan los arquitectos de A y de B, junto con la frontera de la tarea 2 |
| **T4-07 (B, después del 11-16)** | `ReportesEndpoints.cs:78-80`; `AuditoriaAdr109Tests.cs:96` | T4-06 no toca el tablero. T4-07 rebasa |
| **T1-5 de D1 (11-11 a 11-13)** | `ReportesF9Tests.cs`, `FlujosMvpTests.cs`, `BaseDatosFixture.cs`, `ApiMvpFactory` (`UsuarioAsync` pasa a `AccesoPruebas`); el nivel con el que la principal filtra la lista (`ReportesService.cs:88`, `sesion.EsAdmin`) pasa a salir de la membresía | **T4-06 antes del 11-11** (PLAN 6.4). `ListaReportesContratoTests` es la alarma de T1-5 y D5: si después divergen, la prueba falla, que es lo que se busca |
| **D5 (introspección v2, `rptsis.PermisoEfectivo`)** | La visibilidad de la definición | La misma prueba de contrato |
| **Tarea 3 (DEMO) y el instalador #124** | Sección 7.2 | Ningún DEMO ni ensayo Release de `feature/modelo-ng` arranca entre la unión de T4-06 y la tarea 3 |

---

## 14. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | Un `#if DEBUG` oculta un error que solo aparece en Release (la suite compila Debug) | Media / Alto | Compilación Release obligatoria en TA-6; la ejecución en un archivo propio entero, sin `#if` intercalados |
| R-2 | **El DEMO, el ensayo corto y el laboratorio no arrancan** después de T4-06 (Q-6). Es más grave que H-T4-07 | Alta / Alto | Tarea 3 antes de publicar; P-D1-02 ya prohíbe publicar desde T1-5; P-4 para que B fije que tampoco se publique entre el 11-11 y T1-5 |
| R-3 | La lista (principal) y la definición (API de reportes) divergen en visibilidad: nivel efectivo, T1-5 y D5 | Media / Medio | `ListaReportesContratoTests` |
| R-4 | 5 días hábiles con 1 día de holgura en una PC de 8 GB; si se corre más allá del 11-11, choca con T1-5 | Media / Alto | TA-1 adelantable; suite en C; si el 11-06 no hay PR, avisar a B ese mismo día |
| R-5 | Las copias de reportes de la P-2 que modificó un ADMIN dejan de funcionar (leen tablas) | Cierta en el DEMO / Bajo | Aceptado en T3-02; lo dice el texto del PR |
| R-6 | Reporte 23 sin filtro de caja sobre un mes: de 3,6 a 4,4 s (medición M8 de B) | Baja (el filtro por omisión es «Hoy») / Bajo | Q-T4D-02 firmada; dentro de los 30 s |
| R-7 | Guardar con P-1 (a): si la API de reportes cae, el ADMIN no puede guardar reportes | Baja / Bajo | 503 con texto claro. La alternativa (b) permite guardar reportes rotos |

**Costo:** USD 0 en infraestructura y licencias. El esfuerzo está en la sección 12.

---

## 15. Preguntas abiertas para B

| # | Pregunta | Opciones | Recomendación de A | Antes de |
|---|---|---|---|---|
| **P-1** | Guardar del diseñador en Release (H-A06-01) | (a) Validar las columnas en la API de reportes por la canalización con el token del ADMIN (+0,5 dp); (b) solo la validación estática y el error al ejecutar (0 dp) | **(a)**: cierra H-A06-01 y valida con el mismo usuario que ejecuta | TA-0 |
| **P-2** | Programados y «Ejecutar ahora» en Release, si T4-06 se une antes que T4-04 | (a) Falla cerrada, con el mensaje registrado en la regla (+0,1 dp); (b) T4-06 espera a T4-04 (no cabe antes del 11-11); (c) dejar la ejecución de las notificaciones en Release (contradice Q-6 y deja H-T4-06 abierto) | **(a)**: hoy no hay clientes y cierra H-T4-06 en Release antes | TA-0 |
| **P-3** | Con Q-6, la principal Release **no arranca en Linux** (el reenvío exige Windows, `ReenvioReportes.cs:232-234`) | (a) Se acepta como falla cerrada de ADR-129 hasta el socket Unix; (b) un modo Linux temporal (contradice Q-6) | **(a)** | TA-0 |
| P-4 | ¿Quién adapta el ensayo corto (`iniciar-api.ps1`, Release) y se confirma que no se publica ningún DEMO de `feature/modelo-ng` desde la unión de T4-06 hasta la tarea 3? | — | Devops de A, con la tarea 3. El ensayo puede compilar Debug mientras tanto | Unión |
| P-5 | Nombre de los tramos de antigüedad: `Corriente` (B, `vistas.md:101`) o `CorrienteBase` | — | **`*Base`**: lo exige `SemillaReportesOla5Tests.cs:35-36` y es la regla del tramo 3 | TA-1 |
| P-6 | El total del 21 mezcla depósitos con cheques (`Monto` sin signo, como hoy) | (a) Igual que hoy; (b) neto con `Signo` | **(a)** para T4-06; (b) en el bloque B si UX lo pide | TA-1 |
| P-7 | El SUPER en `ListaReportesContratoTests`: hoy no hay ayudante, y T1-5 cambia cómo se crea | (a) Ayudante mínimo ahora, que T1-5 adapta; (b) solo USER y ADMIN, y el SUPER con T1-5 | **(a)** (+0,2 dp) | TA-5 |
| P-8 | `GET /{id}` sigue reenviándose (T4-10OCT 5.3). Si la API de reportes cae, el 503 aparece **al abrir** el reporte, no al ejecutarlo | Confirmar que eso cumple «503 por reporte» | Sí | TA-3 |
| P-9 | La F9 con datos de los 11 reportes (T4-10OCT 7.1.4) | (a) 200 y columnas por la principal, con los datos ya probados en `VistasP2Tests`; (b) el escenario completo (+0,75 dp) | **(a)** | TA-5 |

---

## 16. Decisiones candidatas a ADR

- **Q-6 aplicada en `AgregarReenvioReportes`, con la costura `ValidarModo`, y no en `Program.cs`.** Contexto: choque con PR-4 y T1-5. *Alternativa descartada:* un `#if` en `Program.cs`, que suma un archivo más en conflicto.
- **Validación de Guardar por la API de reportes** (P-1 (a)). Precisa la cl. 1 y la cl. 8 de ADR-109. *Alternativa descartada:* (b).

Ninguna cambia lo firmado. Las dos son de implementación y bastaría anotarlas en el PR, salvo que B quiera registrarlas.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-t4-06-lista-p2-2026-10-22.md`
- Supuestos:
  - `caja.Movimiento.Monto` positivo = ingreso [I];
  - la base de `BaseDatosFixture` tiene el contrato 1.3 [I];
  - los guiones del laboratorio y el instalador arrancan la principal Release [I];
  - T4-04 se une después de T4-06 (calendario de B).
- Decisiones candidatas a ADR: las dos de la sección 16.
- Entregas a otros agentes:
  - arquitecto-software de B → P-1 a P-9 (P-1 a P-3 antes del 11-03);
  - auditor-seguridad → severidad de H-A06-01;
  - arquitecto-datos de B → signo de `caja.Movimiento.Monto`;
  - devops de A → DEMO, ensayo corto y laboratorio con la API de reportes (tarea 3, R-2).
- Próximo paso recomendado: que B responda P-1 a P-3, y empezar TA-1 en cuanto la capacidad de A lo permita (no depende de PR-4).
