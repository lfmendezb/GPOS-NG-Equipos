# Informe de Seguridad: rama `b/ola5-auditoria` (T3-11 `audit.Exportacion` y bases contenidas P-B1 a P-B3)

Fecha: 2026-10-10 · Auditor de seguridad, equipo B · Revisión de solo lectura (sin compilar ni correr pruebas).
Árbol: `GPOS-B-ola5-auditoria`, commits `7dbc58d`, `24d898e`, `4c18986`, `bd30d5d` sobre `ec459d5`.
Firmas contrastadas: ADR-111 (cláusula 7, P-A1 a P-A5), ADR-054 (P-B1 a P-B3), ADR-109, ADR-044, ADR-052.

## 1. Alcance y superficie revisada

- Endpoints autenticados que exportan: `GET /api/reportes/{id}/exportar/{formato}` (reenvío y principal), `GET /api/ventas/facturas/exportar/{formato}`.
- Endpoint administrativo nuevo: `GET /api/admin/exportaciones/verificar` (ADMIN y SUPER).
- Tarea en segundo plano: envío programado de reportes (`TrabajoNotificaciones` / `EjecucionReglas`).
- Canal interno principal ↔ API de reportes (encabezados `X-GPOS-Sucursal`, `X-GPOS-Huella-Definicion`, `X-GPOS-Huella-Datos`, `X-GPOS-Renglones`, `X-GPOS-Totales`).
- Base de empresa: tablas `audit.Exportacion`, `audit.ExportacionCierre`, procedimientos, disparadores, vista, permisos.
- Creación de bases: `Aprovisionamiento.CrearAsync`/`ActualizarAsync` (`GPOS.Migracion`) y `EsquemaEmpresa.CrearBaseAsync` (API).
- Pantallas «Verificar Exportación» (Web y MAUI).

## 2. Resumen de hallazgos

| Id | Severidad | Título |
|---|---|---|
| AE-01 | Media | La inmutabilidad de la evidencia solo resiste DML; DDL, usuarios contenidos y registros falsos dependen de RG-14 |
| AE-02 | Media | El envío programado atribuye la exportación a quien modificó la regla, sin marca de automatismo |
| AE-03 | Baja | La copia de la evidencia en el registro (A5) solo existe en la ruta de reenvío |
| AE-04 | Baja | «Verificar» devuelve los filtros (posibles datos personales) que la pantalla no usa |
| AE-05 | Baja | Sucursal con caracteres no ASCII se registra como «todas» |
| AE-06 | Baja | Las respuestas no 2xx de la API de reportes se copian al cliente sin límite de tipo ni tamaño |
| AE-07 | Baja | Restaurar una base contenida en una instancia con la opción en 0 falla (inferido, 12824); los respaldos llevan los hash de los usuarios contenidos |
| AE-08 | Baja | Bases creadas por la API: intercalación de la instancia y catálogo con otra intercalación al ser contenidas |
| AE-09 | Observación | Sin prueba del cierre `I` cuando el cliente corta |
| AE-10 | Observación | `CacheSecuencias` congelada por posición (`Take(13)`) sin prueba que la ate |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Estado |
|---|---|
| A01 Control de acceso | Verificado: `RequiereAdmin` más comprobación en el servicio; empresa de la sesión. Heredado H-01 (acceso a cualquier empresa) sin cambio. AE-02, AE-04 |
| A02 Criptografía | Verificado: SHA-256 de datos, archivo y definición; sin secretos nuevos |
| A03 Inyección | Verificado sin hallazgo (ver 5) |
| A04 Diseño inseguro | AE-01 (riesgo residual aceptado en el diseño, condicionado a RG-14), AE-05 |
| A05 Configuración | AE-07, AE-08; AUTO_CLOSE OFF se fija en bases contenidas (DM-04) |
| A06 Componentes vulnerables | No aplica (sin paquetes nuevos en el diff) |
| A07 Autenticación | Usuarios contenidos: AE-01 (dependencia RG-14) |
| A08 Integridad de datos | AE-01, AE-02, AE-03 |
| A09 Registro y monitoreo | AE-03; errores del motor solo al registro, nunca en la respuesta (verificado) |
| A10 SSRF | No aplica (la URL del canal es fija; `formato` va con `Uri.EscapeDataString`) |

## 4. Hallazgos

### AE-01 · Media · Inmutabilidad limitada a DML; depende de RG-14 (punto 1 del desarrollador)
- **Evidencia:** `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesAuditExportacion.cs:5` (comentario «disparadores que detienen también a db_owner y sysadmin»), `:69-85` (disparadores `AFTER UPDATE, DELETE`), `:130-137` (DENY solo `INSERT, UPDATE, DELETE`), `:89-105` (`usp_IniciarExportacion` acepta usuario, sucursal, huellas y renglones de quien llama); `SqlMigraciones.cs:52` (`GRANT SELECT, INSERT ON SCHEMA::audit TO gpos_app`). ADR-054 P-B3 nota: «`ALTER ANY USER` permite crear usuarios que entran sin login».
- **Riesgo:** los disparadores bloquean `UPDATE/DELETE`, pero no DDL. Un principal con `ALTER` sobre las tablas (cualquier `db_owner`, o el login de la API mientras RG-14 siga abierto) puede deshabilitar los disparadores, borrar o reescribir, o vaciar `audit.ExportacionCierre` con `TRUNCATE` (no la protege ninguna FK entrante; el comentario de `:69` solo cubre `audit.Exportacion`), lo que convierte todos los cierres en `P`. Con la base contenida, `ALTER ANY USER` permite además crear usuarios con contraseña que entran sin login de instancia ni su auditoría. Quien tenga el login de la API puede insertar registros falsos por los procedimientos: es inherente a que la aplicación sea quien escribe y no lo resuelve ningún control dentro de la misma base.
- **Escenario:** un operador con la cadena de conexión de la API borra la evidencia de una exportación indebida antes de una revisión.
- **Remediación:** (1) cerrar RG-14 antes de publicar: `gpos_app_{EMP}` sin `db_owner`, sin `ALTER ANY USER` y sin `ALTER` en `audit`; ya es parte de PUB-06. (2) Defensa en profundidad barata (0,1 sp): `DENY ALTER ON SCHEMA::audit TO gpos_app` y `DENY ALTER ANY USER TO gpos_app` en la migración. (3) Corregir el comentario de `:5`: los disparadores solo detienen DML. (4) Huella externa: la copia en el registro (AE-03) es hoy la única traza fuera de la base. Para una prueba más fuerte, después del corte se podría encadenar las huellas y anclar la última en el registro de eventos de Windows o en el respaldo. Alternativa descartada por ahora: un ledger table de SQL Server 2022, que exige versión y edición y no cubre Express 2019.

### AE-02 · Media · Atribución del envío programado (punto 5)
- **Evidencia:** `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:126` (`Alcance(empresa, regla.UsuarioModificacion ?? "SISTEMA")`), `:160` (sesión sintética con nivel Admin), `:64-80` (`IniciarAsync` toma `sesion.Usuario`; `Origen` queda nulo y `Parametros` no lleva la regla).
- **Riesgo:** el registro dice que exportó una persona que no hizo nada en ese momento, y no se distingue de una exportación manual suya. Eso debilita el propósito de la cláusula 7 (no repudio) y puede inculpar a quien solo editó la regla meses antes.
- **Remediación (0,1 sp):** registrar `Origen = "programado:regla {Id}"` (o `Usuario = "PROGRAMADO"`) y llevar `UsuarioModificacion` y el Id de la regla en `Parametros`. La pantalla de verificación debe mostrarlo.

### AE-03 · Baja · Copia en el registro solo en la ruta de reenvío
- **Evidencia:** `src/GPOS.Api/Endpoints/ReenvioReportes.cs` (bloque `LogInformation(EventoExportacion, …)` tras el cierre); `src/GPOS.Api/Impresion/EntregaExportacion.cs:17-46` y `TrabajoNotificaciones.cs:64-80` no escriben esa línea.
- **Riesgo:** las exportaciones que arma la principal (reportes P-2, consulta de facturas) y los envíos programados no dejan rastro fuera de la base. Si se altera la base (AE-01), no queda nada con qué contrastar.
- **Remediación:** mover la línea de registro a `EvidenciaExportacionesService.CerrarAsync` (o a `IniciarAsync` más `CerrarAsync`) para que todas las rutas la escriban, sin filtros ni datos personales.

### AE-04 · Baja · Filtros devueltos sin uso (punto 4)
- **Evidencia:** `EvidenciaExportacionesService.cs:173-174` y `:195` (selecciona y devuelve `Parametros`); `src/GPOS.Contracts/Reportes/Reportes.cs` (`ExportacionVerificada.Parametros`); `src/GPOS.Web/Components/Pages/Admin/VerificarExportacion.razor` y su copia en MAUI no lo muestran.
- **Riesgo:** P-A5 admite guardar el texto de los filtros, que puede traer cédula o nombre (Ley 172-13). Devolverlos a una pantalla que no los usa expone datos personales sin necesidad. Mientras siga H-01 (heredado: el ADMIN es global y cualquier usuario entra a cualquier empresa), un ADMIN puede leerlos en todas las empresas.
- **Remediación:** quitar `Parametros` del DTO y de la consulta, o mostrarlos deliberadamente con una decisión de UX. La verificación por huella ya basta (P-A4).

### AE-05 · Baja · Sucursal no ASCII registrada como «todas» (punto 2)
- **Evidencia:** `src/GPOS.Reportes.Api/Endpoints/EndpointsReportes.cs:79` (`suc.All(char.IsAscii) ? suc : ""`); `SqlMigracionesAuditExportacion.cs:102` (`NULLIF(@SucursalCodigo, '')`); la pantalla muestra nulo como «Todas».
- **Riesgo:** un reporte restringido a una sucursal cuyo código no sea ASCII queda en la evidencia como «todas las sucursales». Inferido: los códigos de sucursal probablemente se validan como ASCII al crearlos; no lo verifiqué. `char.IsAscii` admite caracteres de control, que Kestrel rechaza: la exportación falla, pero falla cerrada.
- **Remediación:** codificar el valor (por ejemplo con `Uri.EscapeDataString`) y decodificarlo en la principal, o enviar un marcador explícito de «desconocida» y responder 503 sin evidencia. La confianza en los encabezados por la canalización con dueño verificado (T2-04) es aceptable: quien controle el proceso de reportes ya lee los datos.

### AE-06 · Baja · Respuestas no 2xx copiadas sin control
- **Evidencia:** `ReenvioReportes.cs` (rama `!respuesta.IsSuccessStatusCode` → `CopiarAsync` sin evidencia).
- **Riesgo:** defensa en profundidad. Si la API de reportes fallara o estuviera comprometida, podría entregar contenido en el cuerpo de un 4xx/3xx sin dejar evidencia. El canal es de confianza: la probabilidad es baja.
- **Remediación:** en esa rama, copiar solo `application/problem+json` con un tope pequeño (por ejemplo 16 KB); si no cumple, responder 502.

### AE-07 · Baja · Restauración y respaldos de bases contenidas (punto 6)
- **Evidencia:** `Aprovisionamiento.cs:86-93`, `EsquemaEmpresa.cs:205-217` (crean bases contenidas cuando la opción está en 1); ADR-054 P-B2 («Backup Tool comprueba la opción antes de restaurar»), no implementado en esta rama.
- **Riesgo:** (inferido, sin ejecutar) `RESTORE` de una base contenida en una instancia con `contained database authentication = 0` falla con el error 12824, lo que afecta la recuperación ante desastres en un servidor nuevo. Además, el respaldo lleva los hash de las contraseñas de los usuarios contenidos `gpos_rpt_*`/`gpos_lec_*`: quien robe un respaldo puede restaurarlo con la opción en 1 y entrar con esas credenciales, o atacarlas fuera de línea.
- **Remediación:** Backup Tool y el procedimiento de restauración activan o comprueban la opción (P-B2). Los respaldos se cifran. Después de restaurar en otra instancia, se rotan las credenciales de lectura (el mecanismo de rotación ya existe).

### AE-08 · Baja · Intercalación de las bases que crea la API (punto 7)
- **Evidencia:** `EsquemaEmpresa.cs:205-213` (`CREATE DATABASE` sin `COLLATE`: intercalación de la instancia, que puede ser CP1, `Modern_Spanish_CI_AS` u otra) frente a `Aprovisionamiento.cs:71` (`Latin1_General_100_CI_AS_SC_UTF8`). El comentario de `EvidenciaExportacionesService.cs:79` supone «la base es UTF-8».
- **Riesgo:** en una base contenida, el catálogo usa `Latin1_General_100_CI_AS_KS_WS_SC`. Comparar columnas de datos `varchar` con columnas de `sys.*` da el error 468. Verifiqué con búsqueda (no exhaustiva) que las comparaciones actuales con el catálogo usan literales o `VALUES` (`02_actualizacion_gpos.sql:898`, `NumeracionService.Diagnostico.cs:665,674`), que son coercibles y no fallan. Las tablas `#temp` toman la intercalación de la base contenida: eso reduce el 468 con `tempdb`. En una base CP1, recortar por bytes UTF-8 es conservador y no trunca de más. El riesgo es de disponibilidad, no de confidencialidad.
- **Remediación:** aplicar la regla de P-B1 (`COLLATE CATALOG_DEFAULT`) en código nuevo. Agregar una prueba que aplique 01/02 y el diagnóstico de índices sobre una base contenida CP1 (la prueba `Crear_actualizar_esquema_de_la_API_crea_la_base_contenida` existe; no verifiqué si cubre el diagnóstico).

### AE-09 · Observación · Falta probar el cierre `I` (punto 3)
- **Evidencia:** `tests/GPOS.Tests/Mvp/ReportesF9Tests.cs:388,458` cubren la evidencia completa y el 503. No hay prueba de corte del cliente.
- **Verificado en el código:** `EntregaExportacion.cs:39-43` y `ReenvioReportes.cs` (bloque `catch`) registran `I` con los bytes copiados. `CerrarAsync` usa `CancellationToken.None` (`EvidenciaExportacionesService.cs:146,152`), así que el cierre se registra aunque el cliente haya cortado.
- **Remediación:** prueba con `RequestAborted` cancelado a mitad de la copia, que exija `Resultado = 'I'`, `Bytes > 0` y `HuellaArchivo` nula (qa-automatizado).

### AE-10 · Observación · `CacheSecuencias` por posición
- **Evidencia:** `SqlMigraciones.cs` (`Take(SecuenciasFundamentos)` con `= 13`); `SecuenciasNodo.cs:19-20` (la nueva va al final).
- **Verificado:** el script de `Fundamentos` no cambia hoy: las 13 primeras son las mismas.
- **Riesgo:** si alguien inserta una secuencia en medio de la lista, cambia en silencio el script de una migración ya aplicada.
- **Remediación:** una prueba que fije los 13 nombres esperados, o una lista literal en lugar de `Take`.

## 5. Controles bien implementados (verificados)

- **Falla cerrada (P-A1):**
  - En el reenvío, `IniciarAsync` corre después de leer los encabezados 2xx y antes de `CopiarAsync`, que es lo primero que fija el estado y escribe. Sin la huella o los renglones lanza `ExportacionSinEvidenciaException` (`ReenvioReportes.cs`).
  - En la principal, el archivo se arma en memoria y el inicio se registra antes de escribir (`EntregaExportacion.cs:20-25`).
  - La excepción se traduce en 503 con el código `EXPORTACION_SIN_EVIDENCIA` y solo el texto de la regla (`Program.cs`, `ManejarErrorAsync`). El error del motor queda en el registro (`EvidenciaExportacionesService.cs:130-134`).
  - En el envío programado, sin evidencia no se encola (`TrabajoNotificaciones.cs:64-80`).
- **Hora y RNC:** los fija la base (`usp_IniciarExportacion`, `:102`).
- **Validaciones de la base:** huella de 32 bytes obligatoria (51481) y cierre único (51482). La aplicación manda `NULL` en lugar de rellenar con ceros (`:123`).
- **Inyección:**
  - Todo el SQL nuevo va parametrizado, con tipo y largo por columna (cumple ADR-50).
  - El SQL dinámico de `CrearBaseAsync` usa nombre entre corchetes con `]` escapado y un sufijo constante.
  - `Aprovisionamiento` usa `Cita` y `ValidarCadena`.
  - `Parametros` y `Totales` se validan como JSON y por tamaño, en la aplicación y con `CHECK` en la base.
- **API de reportes sin escritura (ADR-109, P-A1):**
  - Solo agrega dos encabezados (`EndpointsReportes.cs:78-80`, `ServicioReportes.cs:142-188`).
  - `PermisosLecturaReportes.Sql` niega `SELECT/INSERT/UPDATE/DELETE/EXECUTE/ALTER` sobre `audit` a `gpos_reportes` y `gpos_lectura`.
  - Ninguna vista `rpt`/`rptc`/`imp` lee `audit` (búsqueda).
  - La prueba T6 lo cubre.
- **Autorización de «Verificar»:**
  - Política Admin más comprobación en el servicio (`EvidenciaExportacionesService.cs:168`).
  - Solo lee la base de la empresa de la sesión.
  - Sin `Origen` en la respuesta (P-A4).
  - Las pantallas no usan `MarkupString` (Blazor codifica la salida).
- **Rechazos (P-A3):** van al registro con nivel Warning, sin filtros.
- **Bases contenidas:**
  - `ROLLBACK IMMEDIATE` solo sobre bases sin tablas (`Aprovisionamiento.cs:97-98`).
  - `actualizar` usa `NO_WAIT` y no revierte ventas (P-B3).
  - AUTO_CLOSE OFF en las bases nuevas, lo que mitiga el riesgo conocido de contención con AUTO_CLOSE.
- **Origen del cliente:** `X-Forwarded-For` solo de proxies confiables (`Program.cs:44-47,228`).

## 6. Remediaciones priorizadas

1. Antes de publicar: RG-14 / PUB-06 (AE-01). Es condición de publicación existente, no de unión.
2. Antes del corte, unas 0,3 sp en total:
   - AE-02: marca de envío programado.
   - AE-03: registro centralizado.
   - AE-01 (2): `DENY ALTER` sobre `audit` y `ALTER ANY USER`, y corrección del comentario.
   - AE-04: quitar `Parametros` del DTO.
3. Con Backup Tool: AE-07 (comprobar la opción, cifrar, rotar las credenciales al restaurar).
4. Pruebas: AE-09 y AE-10 (qa-automatizado). AE-05, AE-06 y AE-08 cuando se toque el código.

## 7. Recomendación

**Aprobado con observaciones** para unir `b/ola5-auditoria`: no hay hallazgos Críticos ni Altos. AE-01 queda como riesgo residual del diseño firmado, atado a RG-14, que ya es condición de publicación. Recomendación técnica: la decisión de unir es del propietario (C2).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: este archivo
- Supuestos: los códigos de sucursal se validan como ASCII (no verificado); el error 12824 al restaurar es inferido; sin compilar ni ejecutar pruebas
- Decisiones candidatas a ADR: ninguna (AE-01 (4), anclaje externo de la evidencia, se podría evaluar después del corte)
- Entregas a otros agentes: desarrollador B → AE-02 a AE-06 y AE-01 (2)-(3); qa-automatizado → AE-09, AE-10 y la prueba de AE-08; devops / Backup Tool → AE-07 y P-B2; arquitecto de datos → AE-01 (DENY ALTER) y AE-10
- Próximo paso recomendado: aplicar el lote barato AE-01 (2), AE-02, AE-03 y AE-04 antes de unir, o registrarlo como pendiente con fecha
