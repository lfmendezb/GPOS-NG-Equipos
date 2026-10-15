# Informe de Seguridad: PR #41, S-1 y S-2 de H-11

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #41, rama `a/h11-s1-s2` @ `974cf675`, contra la base `30b4d5b3` (worktree `GPOS-NG-h11s`). Son 21 archivos, +533 y −51 líneas.

**Contrato:** la validación del arquitecto del 2026-10-15 (A.1 a A.3) y H-11 (candado de restauración y respaldo posterior).

**Método:** no compilé ni ejecuté pruebas, y no reproduje las cifras de prueba que declara el PR.

---

## 1. Alcance y superficie revisada

- **S-2:** `EsquemaRestauracionSistema.cs` (columnas e índice), `ConsultasRestauracionSistema.cs`, `RespaldosPosteriores.cs` (`EncolarAsync`) y `RestauracionSitioService.cs`.
- **S-1:**
  - `BaseNoDisponibleException.cs`;
  - `ReaperturaConexionEmpresa.cs` (apertura);
  - `Program.cs` (503 con `Retry-After`);
  - `CadenaConexion.ParaTrabajo` y `OrigenConexion`;
  - los trabajos en segundo plano;
  - `CandadoEmpresas.cs` y `EsquemaEmpresasNg.cs`.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| H11S-01 | Baja | S-1 traduce **cualquier** `InvalidOperationException` de la apertura en un 503: un error de configuración o de programación queda como «base no disponible» |
| H11S-02 | Informativa | Con la identidad de la API, las filas de `RespaldoPosterior` se pueden insertar o actualizar (solo hay `DENY DELETE`): la pantalla podría mostrar un respaldo falso |
| H11S-03 | Informativa | `CandadoEmpresas.ActivoAsync` trata «la base no responde» como candado inactivo; S-1 agrega una causa más de ese estado |
| H11S-04 | Informativa | Si un árbol anterior inserta filas con centinelas, el «último pedido» (por `Id`) puede ser una de ellas |

No hay hallazgos Críticos, Altos ni Medios.

---

## 3. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| **S-2: ¿se puede forzar que un respaldo posterior no se encole?** | Solo con escritura en las bases. `EncolarAsync` rechaza los centinelas (`Guid.Empty` o `default`) con una `ReglaNegocioException`, que `DespuesDelCommitAsync` captura y **muestra como aviso**: no falla en silencio. El fork y la hora de detección salen de `sync.Reconciliacion` de la reconciliación confirmada; para que lleguen nulos habría que alterar esa fila en la base de la empresa (credencial de la aplicación). La idempotencia (con `NOT EXISTS` más el índice único de 5 columnas) solo deja de encolar un pedido **idéntico**, y para adelantarse insertando la fila hace falta escribir en `GPOS_SYSDATA` (H11S-02) | `RespaldosPosteriores.cs` (`EncolarAsync`); `RestauracionSitioService.cs`; `ConsultasRestauracionSistema.cs` |
| **S-2: ¿puede la pantalla mostrar uno viejo?** | Ya no. Antes se elegía el último pedido por `MAX(ReconciliacionId)`, y un RESTORE hace retroceder el IDENTITY, así que se podía mostrar o reintentar el pedido equivocado. Ahora es el último **insertado** (`ORDER BY Id DESC`) con su clave completa (reconciliación, fork y hora de detección), y R4 reintenta solo los fallidos de ese pedido. El caso de los árboles anteriores está en H11S-04 | `ConsultasRestauracionSistema.cs` (`UltimoPedido`) |
| Esquema S-2 | Las columnas son `NOT NULL` con centinelas `WITH VALUES` (las filas anteriores quedan válidas). El índice único se recrea con `DROP_EXISTING` y conserva el nombre, para que un árbol anterior no lo vuelva a crear con la clave vieja. La hora va como `datetime2` (Dapper la redondearía con `datetime`), así que la clave es exacta. `EsquemaSistema.Version` sube a 3 | `EsquemaRestauracionSistema.cs`; `RespaldosPosteriores.Pedido` |
| **S-1: ¿oculta errores de programación?** | En parte: H11S-01. La traducción está acotada a la **apertura** de la conexión de la empresa (interceptor y `CandadoEmpresas` con `!abierta`), nunca a un comando ni a una transacción. Se registra con `LogWarning` y conserva la excepción interna | `ReaperturaConexionEmpresa.cs` (`Abrir`, `AbrirAsync`); `Program.cs` |
| **S-1: ¿filtra algo?** | No. El 503 lleva un texto genérico («No se pudo abrir la base de la empresa en este momento…»), el código `ModoCandadoRestauracion.CodigoEstadoNoDisponible` y `Retry-After: 15`, sin la cadena ni detalles del motor. El registro incluye la empresa y la ruta, pero no la cadena | `Program.cs` |
| Trabajos con su propio pool | Correcto. `ComoTrabajo()` marca el alcance, y `EmpresasService` devuelve entonces `CadenaConexion.ParaTrabajo` (otro `Application Name`, es decir, otra clave de pool, y `Connect Timeout = 5`). `GPOS_SYSDATA` del trabajador usa también esa cadena. Así un trabajo que espera una base en RESTORING no bloquea el pool de las peticiones. No cambia la identidad ni los permisos: solo separa los pools | `CadenaConexion.cs`; `EmpresasService.ParaOrigen`; trabajos en `GPOS.Api/Servicios` |
| Escrituras con la base no disponible | El 503 cubre lecturas y escrituras. La guarda del candado (`ModoCandadoRestauracion`) sigue tratando un estado desconocido como bloqueante para las escrituras (falla cerrado) | `ModoCandadoRestauracion.cs:66-70` |

---

## 4. Hallazgos

### H11S-01 · Baja · Cualquier `InvalidOperationException` de la apertura es un 503

`SqlConnection.Open` lanza `InvalidOperationException` por el tiempo de espera del pool (el caso buscado), pero también por errores de programación o de configuración: una cadena vacía, una conexión que ya estaba abierta o una conexión enlistada en una transacción ajena. Con S-1, todos esos casos responden 503 con `Retry-After`. El cliente reintenta y el registro queda como `Warning`, en lugar de un 500 con un `Error`. No es explotable, pero esconde fallos que antes se veían.
- **Remediación (≈ 0,02 dp):** antes de `Open`, comprobar que `connection.State == Closed` y que la cadena no esté vacía (y lanzar el error original si no). Así solo queda el tiempo de espera del pool como causa plausible, sin depender del texto del mensaje. Registrar como `Error` si el mismo 503 se repite N veces seguidas para una empresa.

### H11S-02 · Informativa · `RespaldoPosterior` se puede escribir con la identidad de la API

S1 (RG-14) solo niega `DELETE` sobre `dbo.RespaldoPosterior`, porque el trabajador necesita `INSERT` y `UPDATE`. Con la identidad de la API se puede insertar el pedido antes de que llegue (y el real ya no se encolaría por idempotencia) o marcar una fila como terminada sin que lo esté. Hace falta escribir en `GPOS_SYSDATA` con la identidad del servicio, que en Estricto es una cuenta de servicio de Windows. Si se quiere cerrar: los cambios de estado, por un procedimiento `EXECUTE AS OWNER`, y `DENY UPDATE` directo, como con las marcas P-7 y los latidos.

### H11S-03 · Informativa · `ActivoAsync` trata «no responde» como inactivo

`CandadoEmpresas.ActivoAsync` devuelve `EstadoAsync ?? false`. Lo usan el inicio de sesión, `TrabajoNotificaciones` y `TrabajoVigilanciaRestauracion`. S-1 agrega una causa más de `null` (el tiempo de espera del pool). La guarda HTTP de las escrituras usa `EstadoAsync` y falla cerrado, así que la emisión no se ve afectada. En la vigilancia, un «inactivo» por no respuesta equivale a «no detecté nada» en ese ciclo, que se repite. Comportamiento anterior al PR; conviene revisarlo cuando se toque la vigilancia.

### H11S-04 · Informativa · Centinelas de árboles anteriores

Mientras convivan árboles que no envían el fork y la hora (R-D14), sus inserciones llevan los centinelas. Si una de ellas es la más reciente por `Id`, la pantalla y el reintento R4 trabajan sobre ese pedido. Solo pasa en desarrollo con varios árboles sobre la misma base. Retirar los valores por omisión cuando no quede ningún árbol anterior.

---

## 5. Controles bien implementados

- **Clave completa del pedido** (reconciliación, fork y hora con precisión de `datetime2`): resiste el retroceso del IDENTITY tras un RESTORE.
- **El pedido no se encola en silencio:** sin fork u hora no se encola y se avisa.
- **S-1 acotado a la apertura,** con un 503 genérico y `Retry-After`, sin filtrar la cadena.
- **Pools separados** para los trabajos en segundo plano, sin cambiar la identidad.
- **El candado sigue fallando cerrado** para las escrituras con un estado desconocido.

---

## 6. Recomendación

**PR #41: Aprobado con observaciones.**

No hay hallazgos Críticos, Altos ni Medios. H11S-01 es una mejora barata de diagnóstico. Es una recomendación técnica: la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr41-h11-s1-s2-2026-10-15.md`
- Supuestos: no reproduje las pruebas declaradas por el PR; las causas de `InvalidOperationException` en la apertura son las documentadas de `SqlConnection`.
- Decisiones candidatas a ADR: Ninguna.
- Entregas a otros agentes:
  - desarrollador-backend: H11S-01 (comprobar el estado antes de abrir) y, si se quiere, H11S-02 (procedimiento para los cambios de estado de `RespaldoPosterior`);
  - desarrollador de H-11: H11S-03 al tocar la vigilancia.
- Próximo paso recomendado: unir el PR #41 y aplicar H11S-01 en un seguimiento.
