# Informe de Seguridad: PR #39, RG-14 lote 2b

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #39, rama `a/rg14-lote2b` @ `aca9f898`, contra la base `feature/modelo-ng` @ `30b4d5b3` (worktree `GPOS-NG-rg14l2`). Son 19 archivos, +482 y −55 líneas.

**Contrato:** `datos-t3-12-rg14-2026-10-14.md` (C-08, D-04 (i), D-07, M-1, 2.6); `[PSF]` A6 (FP-03); mis informes de los PR #28, #33 y #36.

**Método:** no compilé ni ejecuté pruebas. Las cifras que menciono (700 correctas y 5 omitidas en los filtros; suite de 2 966 correctas con 1 fallida concurrente) son las que declara el PR y no las reproduje.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Fila `Licencia.InstalacionId` | `GPOS.Migracion/ComandoSistema.cs` (`AsegurarInstalacionAsync`); `GPOS.Api/Servicios/Inicializacion.cs` (`ExigirInstalacionAsync`) |
| Empresa «pendiente de aprovisionar» | `GPOS.Core/Sistema/EmpresasService.cs`; `GPOS.Migracion/ComandoAprovisionar.cs`, `CredencialApp.cs`, `EmpresasSistema.cs` |
| D-07 y M-1 | `GPOS.Api/Endpoints/AdminEndpoints.cs`; `EsquemaEmpresa.cs` |
| 2.6 en Estricto | `GPOS.Api/Seguridad/IdentidadSql.cs`, `VersionEsquemaEmpresa.cs` |
| Respaldo | `RespaldoService.cs`, `RespaldosPosteriores.cs` |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| P39-01 | **Media** | La cadena que `aprovisionar` crea para una empresa pendiente lleva `TrustServerCertificate = true`, y la API la usa con la credencial contenida |
| P39-02 | Baja | 2.6 en Estricto: un error de la verificación no bloquea, y una empresa conforme no se vuelve a verificar |
| P39-03 | Baja | `GPOS:EmpresaInicial` escribe una cadena al arrancar también en Estricto (contradice M-1) |
| P39-04 | Valoración | Revocar `gpos_app` solo con `DENY CONNECT`, sin `KILL`: no recomendado por sí solo (sección 5) |

No hay hallazgos Críticos ni Altos.

---

## 3. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| `Licencia.InstalacionId` (C-08) | **Verificado.** `GPOS.Migracion sistema` la genera con la fila de L1a-4 (`FilaInstalacion` protegida con `ProtectorLicencia`, GUID `D` en minúsculas, origen `MIGRACION`), con el anillo de la API, y escribe con `UPDLOCK, HOLDLOCK`. Una fila que verifica no se toca. Una que **no verifica no se pisa**: el comando se detiene. En Estricto, la API no arranca sin la fila o con una que no verifica. Si la fila se vacía, se genera otra; el efecto es restrictivo, porque las licencias de la anterior dejan de valer | `ComandoSistema.cs` (`AsegurarInstalacionAsync`); `Inicializacion.cs` (`ExigirInstalacionAsync`) |
| Empresa pendiente | **Verificado.** Se registra sin cadena (`ConexionCifrada = ""`). No aparece entre las empresas disponibles al iniciar sesión. `Conexion`, `ProbarAsync` y el esquema responden con el texto de «pendiente». La caché ya no guarda la ausencia de cadena. `aprovisionar --servidor --base` exige el prefijo `GPOS_` | `EmpresasService.cs`; `ComandoAprovisionar.cs:55-66` |
| D-07 / M-1 | **Verificado.** En Estricto, «Crear / actualizar esquema» responde 409 `ESQUEMA_DESDE_MIGRACION` sin intentarlo, y escribir una cadena responde 409 `CADENA_DESDE_MIGRACION`. Una cadena con la máscara `********` **no** sirve para saltarse la regla: `GuardarAsync` la trata como «sin cambios» y conserva la guardada, sin fusionarlas. El texto sin permiso ya no pide `db_owner`. Ver P39-03 | `AdminEndpoints.cs`; `EmpresasService.cs:86-92` |
| 2.6 en Estricto | **Verificado:** una identidad no conforme en `GPOS_SYSDATA` detiene el arranque, y una empresa no conforme responde 503 `IDENTIDAD_NO_MINIMA` (con un mensaje sin la cadena) mientras las demás siguen. Una no conforme se vuelve a verificar cada 5 minutos. Ver P39-02 | `IdentidadSql.cs`; `VersionEsquemaEmpresa.cs` |
| RG2-03 | **Cerrado:** `sysadmin` se exige en la instancia de la empresa **y** en la de `GPOS_SYSDATA` antes de empezar | `ComandoAprovisionar.cs` |
| Respaldo (Baja del #36) | **Cerrado:** conexión propia con `Pooling = false` y `CommandTimeout` largo, y el `BACKUP` se ejecuta con `CancellationToken.None`. Al cerrar la conexión termina la sesión y se libera el `sp_getapplock` de sesión, también si el lote se aborta. Solo la apertura usa el token de la petición, antes de que haya nada iniciado | `RespaldoService.cs`; `RespaldosPosteriores.cs` |

---

## 4. Hallazgos

### P39-01 · Media · `TrustServerCertificate = true` en la cadena de la API para las empresas pendientes

- **Riesgo:** en una empresa pendiente, `aprovisionar` arma la cadena base como `new SqlConnectionStringBuilder { DataSource = servidor, InitialCatalog = baseDatos, TrustServerCertificate = true }`. `CredencialApp.CadenaApi` le añade el usuario contenido y su contraseña, y **esa** es la cadena que la API guarda y usa. En Estricto, todas las empresas nuevas pasan por aquí. Con `TrustServerCertificate = true`, el TLS hacia SQL Server no valida el certificado: quien esté en la red entre la API y un SQL Server **remoto** puede hacerse pasar por el servidor y recibir el inicio de sesión de `gpos_app_x`, incluida su contraseña, y después leer y escribir la base de la empresa. Esto contradice A6 de `[PSF]` (FP-03, firmado): «Se rechaza guardar o usar una cadena con `TrustServerCertificate=true` hacia un servidor no local».
- **Evidencia:** `ComandoAprovisionar.cs:63`; `CredencialApp.CadenaApi` conserva las opciones de la cadena base; la cadena administrativa de `EmpresasSistema.cs:123` hace lo mismo para el técnico, con menos impacto (identidad de Windows).
- **Remediación (≈ 0,1 dp):**
  1. Poner `TrustServerCertificate = true` solo si el servidor es local (memoria compartida, `.`, `(local)`, `localhost`, el mismo criterio que A6). Para un servidor remoto, `Encrypt = Mandatory` (o `Strict` con SQL Server 2022) con `TrustServerCertificate = false`, y opcionalmente `HostNameInCertificate`.
  2. Si hace falta la excepción, un indicador explícito `--confiar-certificado` que S4 informe como hallazgo.
  3. Que S4 (o la autoverificación de 2.6) marque las cadenas guardadas con `TrustServerCertificate = true` hacia un servidor no local.

### P39-02 · Baja · 2.6: un error de verificación no bloquea, y las conformes no se vuelven a verificar

- Si la autoverificación da **error** (por ejemplo, sin permiso para leer el catálogo), ni el arranque ni el 503 se aplican (`r.Error is null && !r.Conforme`). Bloquear por un error transitorio sería peor. Pero un error persistente deja Estricto sin esta comprobación y sin que nadie se entere.
- Una empresa **conforme** no se vuelve a verificar en la vida del proceso: si después alguien agrega su identidad a `db_owner`, no se detecta hasta reiniciar.
- **Remediación (≈ 0,05 dp):** en Estricto, un error que persista N veces (por ejemplo, 3 ciclos de 5 minutos) cuenta como «no conforme» con su evento crítico. Volver a verificar también las conformes cada cierto tiempo (por ejemplo, cada hora).

### P39-03 · Baja · `GPOS:EmpresaInicial` escribe una cadena también en Estricto

`Inicializacion` registra la empresa inicial con la cadena de la configuración si la empresa no existe, sin mirar el modo. En Estricto, eso escribe una cadena que no viene de `aprovisionar` (M-1), normalmente con una identidad amplia. Exige editar la configuración (un administrador) y solo actúa si la empresa no existe.
- **Remediación (≈ 0,02 dp):** solo en Amplio; en Estricto, ignorarla y registrar un aviso, o registrar la empresa como pendiente.

---

## 5. Valoración de la propuesta para PA-30: revocar solo con `DENY CONNECT`, sin `KILL`

**Qué cambia.** `DENY CONNECT` impide los inicios de sesión nuevos, pero **no corta las sesiones ya abiertas**. Hay dos casos:
- **Las conexiones de la propia API en el grupo** siguen usándose mientras haya tráfico, porque el grupo las reutiliza; no expiran a los pocos minutos si están en uso. No verifiqué si `sp_reset_connection` vuelve a comprobar el permiso `CONNECT` del usuario contenido [inferido; hay que comprobarlo con una prueba]. Mientras sigan, la API trabaja con la credencial anterior. Eso no es grave por sí solo, porque es la misma aplicación.
- **El caso que importa es una credencial comprometida.** Si la rotación se hace **porque** alguien obtuvo la contraseña anterior y ya tiene una sesión abierta, sin `KILL` esa sesión sigue viva sin límite de tiempo: la rotación no corta al atacante. «Unos minutos» solo es cierto para las conexiones ociosas del grupo.

**Recomendación: no adoptarla tal cual. Proponer `DENY CONNECT` inmediato y `KILL` diferido y obligatorio:**
1. **Rotación ordinaria:** `DENY CONNECT` de inmediato; la API recibe un 18456 en la siguiente apertura y relee la cadena (PA-30). Después de una espera corta (por ejemplo, 2 minutos, para que terminen las peticiones en curso), `KILL` de las sesiones restantes del usuario anterior. El comando no termina hasta que no quede ninguna.
2. **Rotación por sospecha** (`credencial-app --rotar --inmediato`): `DENY CONNECT` y `KILL` sin espera, aceptando errores en las peticiones en curso.
3. **En la API:** al detectar el 18456 de una empresa, además de `Olvidar`, llamar a `SqlConnection.ClearPool` con la cadena anterior, para que no reutilice conexiones abiertas con la credencial vieja.
4. S4 informa cualquier sesión abierta de un `gpos_app_*` que no sea el vigente.

Costo ≈ 0,1 dp. **Alternativa descartada:** `KILL` inmediato siempre (lo actual), que corta peticiones en curso en cada rotación ordinaria. Es aceptable, pero más molesto que el `KILL` diferido.

---

## 6. Controles bien implementados

- **`InstalacionId`** generada solo por la migración en Estricto, sin pisar una fila que no verifica, y exigida al arrancar.
- **Empresa pendiente** fuera del inicio de sesión, sin caché de la ausencia de cadena y con mensajes claros.
- **D-07 / M-1** con 409, y la máscara no permite saltárselos.
- **2.6** detiene el arranque o responde 503 por empresa sin filtrar la cadena, y se vuelve a verificar la no conforme.
- **`sysadmin` en las dos instancias** (RG2-03).
- **Respaldo** con conexión sin agrupación y sin cancelar un `BACKUP` iniciado.

---

## 7. Recomendación

**PR #39: Aprobado con observaciones.**

No hay hallazgos Críticos ni Altos. P39-01 (Media) es barato y conviene corregirlo **antes de usar Estricto con un SQL Server remoto**. Con una instancia local, que es el caso habitual de la PYME, no hay exposición en la red. Es una recomendación técnica: la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr39-rg14-lote2b-2026-10-15.md`
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir; no verifiqué si `sp_reset_connection` vuelve a comprobar `CONNECT` en un usuario contenido.
- Decisiones candidatas a ADR: Ninguna (P39-01 aplica A6/FP-03, ya firmado; la revocación con `KILL` diferido precisa T3-03).
- Entregas a otros agentes:
  - desarrollador I: P39-01, P39-02, P39-03 y la revocación de la sección 5 (con `ClearPool` en la API);
  - qa-automatizado: una prueba de sesión abierta con la credencial anterior después de rotar.
- Próximo paso recomendado: corregir P39-01 en este PR o en un seguimiento antes de usar Estricto con un SQL remoto, y decidir la revocación con `KILL` diferido.
