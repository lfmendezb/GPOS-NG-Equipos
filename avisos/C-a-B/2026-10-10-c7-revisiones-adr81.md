```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega | Hallazgo | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno (bb045b7)
Estado: Abierto
```

# C-7: revisiones de la fase A de ADR-81 (datos del §7.2 y pantallas del §15)

**Documentos (rama `c/adr81-fase-a-diseno`, `bb045b7`):**
- `docs/datos/2026-10-10-revision-adr81-fase-a-datos.md`
- `docs/ux/2026-10-10-adr81-fase-a-pantallas.md`

## Datos (§7.2): Aprobado con observaciones
Se probó en SQL Server 2019 Express con bases `GPOS_TEST_C7_*`, ya borradas.

**Verificado:**
- El SQL se puede correr dos veces.
- La bitácora es de solo inserción: `UPDATE` da 52001 y `DELETE` de una fila reciente da 52002; la purga de lo que pasa de 2 años funciona.
- El `INSERT … OUTPUT` de EF funciona con los disparadores.
- El `UPDATE` condicional de `UltimoPaso` resiste dos sesiones en paralelo.
- La cascada se comporta como se diseñó.
- Los errores 52001 a 52019 están libres.
- Cumple ADR-44.

**Hallazgos:**
| Id | Sev. | Hallazgo | Corrección |
|---|---|---|---|
| **D81-01** | **Alta** | El blueprint pone las tablas en `SistemaDbContext`. En una base nueva, `EnsureCreated` las crea desde EF **antes** de `EsquemaSistema` (`Inicializacion.cs:17-18`), y el SQL revisado se salta: sin `CHECK`, sin `DEFAULT` de `MomentoUtc` y con otros tipos. Como toda implantación es desde cero, pasaría en todas las instalaciones | Tablas solo en SQL, con acceso por SQL escrito a mano, como `Dispositivos*`. PF-30 compara el esquema de las dos rutas |
| D81-02 | Media | El contador y el bloqueo del factor no tienen concurrencia definida. Con el patrón de `UsuariosService.cs:31-50` se perderían incrementos y podrían probarse más de 5 códigos | Transacción por usuario con `UPDLOCK` y una sola sentencia que incrementa y bloquea |
| D81-03 | Media | `UltimoPaso` debe guardar el paso **que coincidió**, no el del reloj protegido; si no, vuelve el bloqueo sin salida de R-01 | — |
| D81-04 | Media | La FK de los códigos de respaldo debe apuntar a `UsuariosFactor` con cascada | — |
| D81-05 | Media | Relojes mezclados: el corte de purga calculado en la aplicación hace fallar el `DELETE`; `MomentoUtc` admite fechas atrasadas; `UltimoAcceso` usa la hora local (`UsuariosService.cs:51`) | Procedimiento `dbo.PurgarBitacoraSeguridad` con el corte calculado en la base; un solo origen de hora |
| D81-06 | Media | Con `IF OBJECT_ID IS NULL`, un cambio de los disparadores nunca llega a las bases existentes, y uno deshabilitado sigue así para siempre | `CREATE OR ALTER` más `ENABLE TRIGGER` en cada arranque |
| D81-07 | Media | Restaurar `GPOS_SYSDATA` no tiene tratamiento: revive códigos usados, un `UltimoPaso` viejo y factores ya restablecidos (H-11 y MD-59 solo cubren las bases de empresa) | Detectarlo con `recovery_fork_guid`: sello nuevo, cierre de sesiones, `UltimoPaso` adelantado y evento `SISTEMA_RESTAURADO` (≈ 0,1 sp) |
| D81-08 a 12 | Baja | Orden de bloqueos en `GPOS_SYSDATA`, `CHECK` faltantes, columnas de la bitácora, relleno del sello, `TRUNCATE` frente a RG-14 y paso del DDL a M-4 | Ver el documento |

El documento trae **el SQL corregido completo** para reemplazar el §7.2 (probado tres veces seguidas), los privilegios para RG-14 y los cambios a las pruebas PF, con una PF-31 nueva. **Conviene incorporar D81-01, 02 y 04 antes de T2.**

**Pregunta P-D81-01:** tras restaurar `GPOS_SYSDATA`, ¿qué se hace con los códigos de respaldo que podrían haber revivido?
- **(a) Solo avisar a cada SUPER que genere códigos nuevos. Recomendado:** reutilizar un código revivido exige además la contraseña.
- (b) Invalidar todos los códigos no usados.
- (c) Invalidarlos y exigir el cambio de contraseña a todos.

## Pantallas (§15): P1 a P12 en Web y MAUI
- **Interfaz actual:** en la Web, el inicio de sesión es SSR estático sin MudBlazor. Los componentes no están en una biblioteca común: cada uno se crea en Web y en MAUI.
- **Pantallas:**
  - código de verificación (un mensaje único, sin oráculo, y bloqueo con la hora en que podrá volver a intentarlo);
  - alta con QR en tres pasos;
  - códigos de respaldo mostrados una sola vez;
  - «sesión en uso» después del factor (SF-03);
  - avisos al entrar (P-81A-06, 07 y 09);
  - «Confirmar su Identidad» ante un 401 `REAUTENTICAR`;
  - «Mi Segundo Factor»;
  - restablecer y desbloquear en Usuarios (con un `MinLength` nuevo en `DialogoMotivo`);
  - bitácora de seguridad;
  - el flujo con contraseña temporal.
- **Para el frontend:** hoy `ApiClient.cs:149-151` convierte **todo** 401 en sesión expirada. El 401 `REAUTENTICAR` no debe cerrar la sesión.
- **Datos que faltan en el contrato (D-01 a D-07, para el arquitecto):** la etiqueta de la instalación en el 202, el indicador de menos de dos SUPER, el estado del factor en `UsuarioDto`, los campos de `EventoSeguridadDto`, el cambio de teléfono pendiente, el caso de UX-81A-01 y `codigo = REAUTENTICAR` en `ProblemDetails`.

**Preguntas UX-81A-01 a 08** (recomendación entre paréntesis). **Las que cambian el contrato, 01, 02 y 08, conviene firmarlas antes de T4:**

| # | Pregunta | Recomendación |
|---|---|---|
| 01 | La respuesta 409 y la confirmación pierden los códigos recién creados y los avisos | Que el 409 los incluya (a) |
| 02 | Volver a entrar durante un alta crea entradas duplicadas en la aplicación | Reutilizar el alta pendiente (b) |
| 03 | ¿Ofrecer el enlace `otpauth://` en MAUI sobre un teléfono? | No; solo la clave manual (a) |
| 04 | ¿Avisar antes del cierre por inactividad? | Sí, 2 minutos antes (b) |
| 05 | ¿Avisar si el código se aceptó con el reloj del sistema? | Sí, con un indicador y una franja (b) |
| 06 | ¿Exportar la bitácora de seguridad? | No en la fase A (a) |
| 07 | Al restablecer el factor de otro SUPER, ¿restablecer también su contraseña? | Solo recomendarlo con un texto (a) |
| 08 | Con la contraseña temporal, el SUPER puede quedar sin salida | Que `/clave` con `cambiar_clave = 1` no exija autenticación reciente (a) |

## Estado del encargo C-5, C-6 y C-7
| Tarea | Estado |
|---|---|
| C-5 | Entregado (`C-a-B/2026-10-10-c5-pantallas-adr118-119.md`) |
| C-7 | Entregado (este aviso) |
| C-6 | En curso |
| C-2 | Espera el PR de H-11 |
