# Validación del arquitecto: S-1 (pool agotado), el KILL en la rotación de `gpos_app` y el PR #39 (RG-14, lote 2b)

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A.
- **Qué revisé:** el PR #39 (`a/rg14-lote2b` @ `aca9f898`, árbol `GPOS-NG-rg14l2`), en solo lectura: el cuerpo del PR y búsquedas dirigidas en el código. No compilé ni ejecuté pruebas.
- **Contra qué lo contrasté:** `datos-t3-12-rg14-2026-10-14.md` (`[DAT]` 2.6, D-04, D-07, PA-21 a PA-30, T3-03 en la línea 196) y `validacion-h11-500-pool-2026-10-15.md` (S-1).

## A. S-1: pool agotado durante un RESTORE. **Amplío el texto anterior**

La causa ya está confirmada con el registro. Un trabajo en segundo plano (`TrabajoNotificaciones`) abre la base durante el RESTORE y se queda esperando (4060). Mientras tanto, el pool, que crea las conexiones de una en una, retiene la creación, y las demás aperturas vencen a los 15 s con `InvalidOperationException`. El error sale por `CandadoEmpresas.LeerConLoginAsync` y también por **otras** rutas (`ModoCandadoRestauracion`, `VersionEsquemaEmpresa`). Por eso capturar la excepción solo en `LeerAsync` no basta. **Texto exacto:**

1. **Excepción con tipo, en la fábrica de conexiones de empresa.** En el punto único donde se abre la conexión de una empresa, el mismo de la reapertura ante el 18456 de #36:
   - un `InvalidOperationException` que lance **`OpenAsync`** se convierte en `BaseNoDisponibleException(empresa)`;
   - no se reconoce por el texto del mensaje: se reconoce por venir de `OpenAsync`;
   - solo se captura en la apertura, nunca en un comando ni en una transacción.
2. **Manejador de errores:** `BaseNoDisponibleException` responde **503** con el código del estado no disponible que ya usa el candado y `Retry-After: 15`. `CandadoEmpresas.LeerConLoginAsync` la trata igual que hoy trata un `SqlException`: devuelve `null`, que acaba en el 503 controlado. **No** se agrega una regla genérica que mapee cualquier `InvalidOperationException` a 503, porque ocultaría errores de programación.
3. **Pool propio para los trabajos en segundo plano:**
   - los trabajos (`TrabajoNotificaciones`, respaldos posteriores, vigilancia y similares) abren con `CadenaConexion.ParaTrabajo(cadena)`;
   - esa cadena tiene la misma opción de pool que `SinBloqueoDelPool`, más `Application Name = "GPOS.Api.Trabajos"` (que da otra clave de pool) y `Connect Timeout = 5`;
   - así un trabajo no retiene la creación de conexiones del pool de las peticiones, y suelta antes la base que no responde.
4. **Prueba:** con `Max Pool Size = 1` en la cadena de las peticiones y un trabajo esperando una base en `RESTORING`, R1 responde 503, no 500.

**¿Bloquea?** No bloquea ninguna unión. Es el PR de seguimiento S-1, **antes de cerrar H-11** (≈ 0,25 dp).

## B. KILL en la rotación de `gpos_app` (PA-30). **Apruebo el cambio con una condición. Sí cambia lo firmado**

- **Diagnóstico aceptado.** Es inferido; no lo verifiqué. El `KILL` deja en el pool conexiones cortadas. La reconexión automática de SqlClient vuelve a entrar con la credencial vieja, y el 18456 aparece en el comando, no en la apertura, así que la reapertura única de #36 no lo cubre.
- **Por qué no basta con quitar el `KILL`:** `DENY CONNECT` solo impide entrar de nuevo. Las sesiones abiertas de la generación anterior seguirían vivas sin límite, porque el pool las conserva. Si la rotación se hace porque la credencial está comprometida, las sesiones del atacante también seguirían abiertas.
- **Texto exacto:**
  1. **Rotación normal** (`credencial-app` sin opciones) para `gpos_app`:
     - crea la generación nueva;
     - escribe la cadena nueva;
     - hace `DENY CONNECT` a la generación anterior **sin `KILL`**.
  2. **Vida máxima de las conexiones de la API:** `CadenaConexion.SinBloqueoDelPool` agrega `Connection Lifetime = 300`. El pool destruye cada conexión de la generación anterior cuando se devuelve después de 5 minutos. La apertura siguiente da 18456, y la reapertura única de #36 relee la cadena y entra con la generación nueva.
  3. **Barrido diferido:** después de `DENY CONNECT`, `credencial-app` espera **6 minutos** (`--espera` configurable, mínimo 6) y hace `KILL` de las sesiones de la generación anterior que queden. Para ese momento ya no están en uso por la API.
  4. **`credencial-app --urgente`** (compromiso): `DENY CONNECT` y `KILL` inmediatos, como hoy. Se aceptan unos pocos 500 transitorios y se informa en la salida del comando.
  5. **Prueba (PA-30):** dos rotaciones normales bajo carga sin ningún 500, y, 6 minutos después, ninguna sesión abierta de la generación anterior.
  6. Las credenciales de lectura (`rotar-lectura`) mantienen su mecanismo actual.
- **¿Cambia algo firmado?** **Sí, en el detalle.** T3-03 (`[DAT]`:196) y PA-30 dicen «`DENY CONNECT` y `KILL`» y «sus sesiones cerradas». Con este cambio, en la rotación normal las sesiones se cierran **en 6 minutos como máximo**, no en el acto; el cierre inmediato queda en `--urgente`. La intención firmada, que la generación anterior no tenga acceso, se cumple igual.
  - Va a la hoja del propietario como **precisión de D-04 y PA-30**. El número lo asigna el arquitecto-maestro, para no repetir un DL.
  - Hasta la firma, el cambio se construye marcado «PENDIENTE DE FIRMA». Si el propietario no lo firma, se mantiene el `KILL` inmediato y PA-30 se cumple con la reapertura en el comando, que es más compleja.
- **Costo:** ≈ 0,15 dp (I). La vida de 300 s añade una reconexión cada 5 minutos por conexión del pool, que es despreciable.

## C. PR #39 (lote 2b): **Aprobado con observaciones; nada lo bloquea**

| Punto | Dictamen |
|---|---|
| C-08, `Licencia.InstalacionId` en `GPOS.Migracion sistema` con la fila de L1a-4 | **Confirmado.** Usa el mismo `ProtectorLicencia` y la misma configuración de Data Protection de la instalación que la API (`ComandoSistema.cs:89-110` [V]). Si la fila no verifica, el comando se detiene sin pisarla: es la falla cerrada de C-08, y la salida es `recuperar-anillo` (CR). Que `Version` siga en 2 es correcto, porque no hay DDL nueva |
| Empresa «pendiente de aprovisionar» (D-04 i) | **Confirmado.** Además, dejar de guardar en caché la **ausencia** de cadena es necesario: si no, la API seguiría sin cadena después de `aprovisionar` |
| D-07 y M-1 (409 `ESQUEMA_DESDE_MIGRACION` y `CADENA_DESDE_MIGRACION`) | **Confirmado.** Texto firmado de D-07 (PA-27) y H-RG14-03 cerrado. **Secundario:** que los dos códigos estén en las constantes de contratos y que la Web y MAUI muestren el texto, no el código |
| 2.6 en Estricto (no arranca con una identidad amplia; 503 `IDENTIDAD_NO_MINIMA` por empresa; reverificación cada 5 minutos) | **Confirmado.** Cubre PA-21 a PA-24. La reverificación cada 5 minutos va más allá de `[DAT]` 2.6 («al abrir su primera conexión»): es más restrictiva, porque detecta un `GRANT` que se agregue después, y se acepta como precisión |
| RG2-03 (`aprovisionar` exige `sysadmin` también en la instancia de `GPOS_SYSDATA`) | **Confirmado** |
| El respaldo con conexión propia sin agrupación y sin cancelar un BACKUP ya iniciado | **Confirmado.** Una operación larga no ocupa una conexión del pool, y un BACKUP cancelado a medias dejaría un archivo incompleto |

## Resumen

| # | Qué | ¿Bloquea? |
|---|---|---|
| 1 | S-1 con la excepción con tipo, el 503 y un pool propio para los trabajos (A) | No; antes de cerrar H-11 |
| 2 | Rotación sin `KILL` inmediato, con `Connection Lifetime = 300`, barrido diferido y `--urgente` (B) | No; queda Pendiente de firma (precisión de D-04 y PA-30) |
| 3 | Códigos de D-07 en los contratos y textos en la Web y MAUI (C) | Secundaria |

### Cierre
- Estado: Aprobado con observaciones.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-rg14-lote2b-y-s1-2026-10-15.md`.
- Supuestos:
  - La causa del 500 de PA-30 es inferida, no la verifiqué.
  - Doy por hecho que `Connection Lifetime` de Microsoft.Data.SqlClient destruye la conexión al devolverla al pool cuando supera su vida [I, comportamiento documentado].
- Decisiones candidatas a ADR: la precisión de D-04 y PA-30 (rotación sin `KILL` inmediato), que va a la hoja del propietario.
- Entregas a otros agentes:
  - **desarrollador-backend (A o I, según el dueño de H-11):** S-1;
  - **desarrollador-backend (I):** el punto B y los códigos de D-07;
  - **arquitecto-maestro:** la precisión de D-04 y PA-30 en la hoja;
  - **qa-automatizado:** PA-30 bajo carga.
- Próximo paso recomendado: unir #39 y abrir el PR de S-1 junto con S-2.
