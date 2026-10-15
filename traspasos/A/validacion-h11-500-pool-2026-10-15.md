# Validación del arquitecto: H-11, 500 tras la restauración (`PoolBlockingPeriod`), PR #24

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A.
- **Qué revisé:** PR #24, rama `a/h11-p7-candado` @ `34798dce`, en el árbol `GPOS-NG-h11b`, solo en lectura (`git diff 51376b52..34798dce`, 8 archivos). No compilé ni ejecuté pruebas.
- **Hallazgo de origen:** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-14-hallazgo-h11-500-tras-restauracion.md`.
- **Decisión del propietario que se cumple:** «Que A corrija primero el 500 tras la restauración (PoolBlockingPeriod) en #24 con su prueba de regresión y validación del arquitecto».

## Dictamen general: **Aprobado con observaciones. La corrección no tiene nada que bloquee la unión de #24**

- **Ayudante único.** `CadenaConexion.SinBloqueoDelPool` se aplica donde nace la cadena (`EmpresasService.Conexion` en sus tres lecturas; `GPOS_SYSDATA` en `Program.cs`) [V]. Los demás usos de la cadena la heredan:
  - `RespaldosPosteriores`, `ServicioDispositivos`, `RncDgiiService`, `Inicializacion` y `LongitudesColumnas` la toman de `db.Database.GetConnectionString()` o de `IConexionesEmpresa`, que ya devuelven la cadena con la opción [V];
  - `SqlConnectionStringBuilder` conserva la opción al cambiar el `InitialCatalog` (`RespaldosPosteriores.cs:85`).
- **Cadenas que quedan fuera, con razón:**
  - `EmpresasService.cs:49` solo enmascara la cadena para mostrarla;
  - `EmpresasService.cs:144` solo la compara.
- **Pendiente en #28:** `IdentidadSql` debe usar el mismo ayudante (ya está anunciado).
- **La prueba de regresión** (`Un_login_fallido_durante_la_restauracion_no_deja_la_empresa_en_500`) reproduce la causa sin carreras:
  - provoca un login fallido con la cadena de la API mientras la base está en `RESTORING`;
  - pide R1 en cuanto termina la recuperación y exige un 200;
  - en el `finally`, deja la base recuperada y en `MULTI_USER`.
- **Alternativa descartada, de acuerdo con B:** traducir 18456 o 4060 a un 503 en `ManejarErrorAsync`. Oculta el síntoma y el pool sigue bloqueado.

## Puntos

| # | Pregunta | Dictamen | ¿Bloquea la unión? |
|---|---|---|---|
| 1 | ¿Es correcto `NeverBlock` ante una caída real del servidor? | **Sí.** Con `Auto`, una caída hace que todas las aperturas fallen al instante durante 5 a 60 s. Con `NeverBlock`, cada apertura vuelve a intentar el login y falla al cumplirse `Connect Timeout`, que sigue en 15 s por omisión. **Efectos:** (a) un intento de login por apertura, acotado por las peticiones y los trabajos activos (decenas en un POS) y sin reintentos añadidos; (b) las peticiones tardan hasta 15 s en fallar en lugar de fallar al instante. Las aperturas son asíncronas, así que no agotan hilos. (c) **Recuperación inmediata** cuando el servidor vuelve, que es justo lo que buscaba H-11. **Residual [I]:** si las credenciales de la API son incorrectas (no es el caso de la restauración) y el inicio de sesión SQL tiene `CHECK_POLICY = ON` con una política de bloqueo de cuentas, se acumulan más intentos fallidos y la cuenta se puede bloquear. Con los usuarios contenidos de RG-14 no aplica la política de bloqueo de Windows [I, por verificar]. Devops lo comprueba en el inventario | **No** |
| 2 | Durante un `RESTORE` en curso, el pool se agota y lanza `InvalidOperationException`, que acaba en 500. ¿Debe capturarla `CandadoEmpresas.LeerAsync`? | **Sí, pero como seguimiento.** Es el mismo escenario R-6, con API arriba y la restauración en curso, y el contrato es el mismo: «la base no responde → `null` → 503 controlado» (`CandadoEmpresas.cs:50-61` [V], que hoy solo captura `SqlException`). Necesita unas 100 aperturas pendientes a la vez (`Max Pool Size`), así que es raro y su efecto es transitorio. **Texto exacto:** en `LeerAsync`, capturar además `InvalidOperationException` **solo cuando la lanza `OpenAsync`** (el tiempo de espera del pool) y devolver `null`, con un registro de advertencia «pool agotado». No se amplía la captura a la consulta, para no ocultar errores de programación. La prueba de regresión baja `Max Pool Size` a 1 en la cadena de prueba y retiene una conexión | **No.** Seguimiento antes de cerrar H-11 (≈ 0,15 dp). Si A ya está tocando #24 y no hay que regenerar migraciones, puede entrar ahí |
| 3 | Tras restaurar un respaldo anterior a un desbloqueo, ¿puede repetirse el número de reconciliación y `EncolarRespaldo` no encolar el respaldo posterior? | **Es real** (verificado leyendo el código; no lo ejecuté). `sync.Reconciliacion` vive en la base de la empresa con `IDENTITY` (`SqlMigracionesH11.cs:73-75` [V]). Un `RESTORE` devuelve el contador al valor del respaldo. La siguiente reconciliación puede recibir el mismo `Id`, y `EncolarRespaldo`, idempotente por (empresa, reconciliación, base) en `GPOS_SYSDATA` (que no se restauró), no inserta nada (`ConsultasRestauracionSistema.cs:32-37` [V]). Además, `UltimosRespaldos` (`MAX(ReconciliacionId)`) muestra las filas del desbloqueo **anterior** como si fueran las del actual: es una garantía falsa de que existe un respaldo posterior al desbloqueo. **Severidad: Media.** El candado no se debilita, porque la detección por `recovery_fork_guid` sigue funcionando (cláusula 9 de ADR-53). Lo que se pierde es la defensa de P-7 contra volver a restaurar un respaldo anterior al desbloqueo, y el SUPER ve un estado incorrecto. **Remedio:** la clave de idempotencia incluye el `ForkActual` de la reconciliación, que es distinto después de cada restauración. Columna `ForkActual uniqueidentifier NOT NULL` en `dbo.RespaldoPosterior`; `EncolarRespaldo` y las consultas por reconciliación filtran también por ella, y `UltimosRespaldos` ordena por `SolicitadoUtc`, no por `MAX(ReconciliacionId)`. Prueba: restaurar un respaldo anterior a un desbloqueo, volver a desbloquear y comprobar que se encolan dos filas nuevas | **No bloquea #24:** es un defecto del diseño de H-11, no de esta corrección, y necesita una migración en `GPOS_SYSDATA` que obligaría a regenerar las marcas de #26 y #28. **Seguimiento obligatorio** en un PR propio antes de cerrar H-11 (≈ 0,3 dp, con la migración) |

## Correcciones y seguimiento

1. **Ninguna corrección bloquea la unión de #24.**
2. **Seguimiento S-1 (punto 2):** captura acotada de `InvalidOperationException` al abrir en `CandadoEmpresas.LeerAsync`, con su prueba.
3. **Seguimiento S-2 (punto 3, Media):** idempotencia de `RespaldoPosterior` por (empresa, reconciliación, `ForkActual`, base), y `UltimosRespaldos` por fecha. Va con migración en `GPOS_SYSDATA`.
4. **En #28:** `IdentidadSql` con `CadenaConexion.SinBloqueoDelPool`.
5. **Devops:** comprobar que los inicios de sesión de la API no tienen una política de bloqueo por intentos fallidos (punto 1).

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica; la unión la decide el propietario a través de B).
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-h11-500-pool-2026-10-15.md`.
- Supuestos:
  - No ejecuté las pruebas: me baso en las cifras de B y del PR.
  - Que la política de bloqueo de Windows no se aplique a los usuarios contenidos es una inferencia sin verificar.
- Decisiones candidatas a ADR: ninguna.
- Entregas a otros agentes:
  - **desarrollador-backend (A):** S-1 y S-2, y el ayudante en #28.
  - **arquitecto-datos:** la columna `ForkActual` y el índice de S-2.
  - **devops:** el punto 1.
  - **B:** unir #24, #26, #21 y #28 en ese orden.
- Próximo paso recomendado: unir #24 y abrir el PR de S-2 antes de cerrar H-11.
