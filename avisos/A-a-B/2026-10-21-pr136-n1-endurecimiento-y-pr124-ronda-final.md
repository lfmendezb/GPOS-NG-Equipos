```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (PR #136 y #124 actualizado) y consultas
Prioridad: Media
Repositorio y rama: GPOS-NG PR #136 `a/n1-endurecimiento-servicio` @ 2cd41377 (sobre feature/modelo-ng fc7f07f2); PR #124 `a/instalador-o1-o3` @ 82318329
Estado: Abierto
```

# PR #136 (S-03, S-04, S-05, S-07 del #127) y #124 con la relectura del auditor

## #136
Tarea 1 de tu encargo del 2026-10-21, en PR aparte y **antes de PR-4** (PR-4 se apila sobre él). Revisión de seguridad: **Aprobado con observaciones** (`traspasos/A/revision-seguridad-n1-endurecimiento-2026-10-21.md`), sin Críticos, Altos ni Medios. Corregidos en el PR: S-03 (`--servicio` con falla cerrada), S-04/R-02 (el 4767 siempre por `RegistroEventosReserva` primero y el proveedor de .NET como segunda oportunidad), S-05/R-06 (Información solo para `GPOS.Api.Servicio` y `Microsoft.Hosting.Lifetime`, con prueba de precedencia sobre el `appsettings.json` real), S-07 (un solo cálculo del SID) y R-03 (marshaling explícito). Pruebas filtradas 78/78; la suite oficial la corres tú en `LFMB`.
- **Para tu devops/instalador:** R-01 (`ServiceInstall/@Arguments="--servicio"` y la comprobación del origen `GPOS.Api` y del camino de reserva en L-1/L-2). Es condición antes de instalar fuera del laboratorio, junto con S-01 y S-02 (cierra PR-4).
- **Decide el propietario (vía B):** R-05 (tres categorías en Información en `appsettings.json`: `GPOS.Numeracion.Rastro`, `GPOS.Ncf.Rastro` y `GPOS.Api.Seguridad.ModoEsquemaPendiente`; llevan código de usuario y empresa, sin secretos; aceptar o un registro propio con lectura restringida, 4 a 8 h). `AuthEndpoints.cs:82` (usuario tecleado tal cual en intentos fallidos) sigue abierto para su responsable.
- Una nota: este PR cambia `ModoServicioApi.cs`, el mismo archivo que PR-4 tocará para retirar `FijarEscuchaPorOmision`.

## #124
- Relectura de seguridad: **Aprobado con observaciones** (`traspasos/A/relectura-seguridad-o1-o3-2026-10-21.md`), sin Críticos ni Altos. Commit `82318329`: R-01 (prueba genérica de que `GposFeatureCarpetas` nombra una feature existente que trae las carpetas, en todo MSI que compile el fragmento), R-02 (`&F = 4` y `AllowAdvertise="no"`), R-04 (la contención de S-04 solo cae con la firma real de la `.CA.dll`), R-05 (GUID de `OrigenEventosEstacion` regenerado) y notas de operaciones. Pruebas filtradas 162 correctas, 1 omitida a propósito (S-04), 0 fallidas.
- **Pregunta para el arquitecto-maestro (R-06):** la Web y la Migración leen `config\` sin declararla. ¿Entran en `declaran` de `ConfigGposNg` en el vector (precisión de ADR-77, punto 5, antes de publicar la v3)? No lo cambié.
- **R-03:** con el GUID nuevo, desinstalar IQ 0.4.1 podría borrar la raíz si está vacía (solo laboratorio): P-O3-4 con IQ.
- **Para devops:** S-04 (firma de la `.CA.dll` en `construir.ps1`; al hacerlo, quitar el `Skip` de la prueba estricta), P-O1-7 con FIPS, `ADDSOURCE` y `ADVERTISE`. **Si ya copiaste el borrador anterior de la v3 en IQ o AdmCloud**, sus pruebas fallarán por la huella nueva (`6879e0b2…`): es lo esperado.
- La unión del #124 sigue siendo solo con orden del propietario.

## PR-1b y PR-4
PR-1b (`GPOS.Comun.Servidor`) en construcción sobre el #130; entrega prevista 2026-10-28; PR-4, 2026-10-30, apilado sobre #136 y #130.

Respuesta requerida: ninguna.
