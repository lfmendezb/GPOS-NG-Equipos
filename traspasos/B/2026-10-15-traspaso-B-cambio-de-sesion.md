# Traspaso del equipo B: cambio de sesión del 2026-10-15

Sesión de B en **LFMB**, abierta el 2026-10-14 tras el traspaso de emergencia. Se cierra porque el contexto está casi lleno.
**Al abrir la sesión nueva:** abrirla en la carpeta `GPOS NG`, para que cargue la memoria completa del proyecto. Después, leer este traspaso, `estado.md` y los avisos abiertos para B.

## Estado de `feature/modelo-ng`
- **Punta actual:** `7898beeb`.
- **Unidos al cerrar:** #40 → #41 → #39 → #34 → #37, en `7898beeb` (punta actual de `feature/modelo-ng`).
  - **Conflictos resueltos:**
    - `EmpresasService.ObtenerAsync` (#39 con #41): se mantiene `Pendiente(e)`, el `null` no se guarda en caché y se devuelve `ParaOrigen(cs)`;
    - `GPOS.Migracion/Program.cs` (#39 con #34): se conservan las dos líneas de ayuda y las banderas, incluida `confiar-certificado`.
  - **`EsquemaSistema.Version` = 3** (S-2 de #41).
- **#42 (L1b-2) rechazado:** el commit `b24ffe5f` todavía trae el interruptor `GPOS:Licencia:Aplicar` (contra ADR-60.6), `ArrancarAsync` impide arrancar en Estricto sin `InstalacionId`, retira `/api/super/licencia`, que la Web aún usa, y apoya en DL-02, sin firma. A tiene que publicar la versión que anunció.
- **#38 (bancos N6-02 y N6-03 de T6):** unido a `b/prep-27oct`, no a `modelo-ng`.

## Uniones de los días 14 y 15
- **14-oct:**
  - `ad6015d`: DEMO 10b, revisión del DEMO y propuesta de ADR-126;
  - `4ace678`: T1 de ADR-126;
  - `e59d8de`: #29, #30, #25 y #27;
  - `f5e36e5`: Pkcs parcheado;
  - `b5e4c48`: #31.
- **15-oct:**
  - `bc15304d`: #24, #26, #21 (C-10) y #28;
  - `30b4d5b3`: #36, #32, #33 (DDL de la licencia en el enganche y versión 2) y #35.

## Marcas de migraciones (regla: siguen el orden de unión)
- **Unidas:**
  - H11 `20261014204007`;
  - C-10 `20261014205000`;
  - Rg14 `20261014210613`;
  - **Rg14RespaldoTope `20261015003000`, la última**.
- **En `b/prep-27oct`:** `NegativosTresNiveles` `20261015010000` y `Ola3bTransferencias` `20261015020000`. Ya son posteriores a la última unida.
- **Método al unir:**
  1. Regenerar un solo guion con `dotnet ef migrations script --idempotent` (está probado que reproduce los existentes).
  2. Alinear el `Designer` de la última migración con el snapshot. Suele faltar el `INCLUDE` de `UQ_CxpAplicacion` de C-10.
  3. Verificar con `has-pending-model-changes`.

## Preparación del 27-oct (PQ-3)
- **Rama:** `b/prep-27oct` (árbol `GPOS-B-prep27`), con T1 de ADR-118/119 y la ola 3b, tramo 1, más #38. **Hay que rebasarla sobre la punta nueva.**
- **Corregido en la preparación:**
  - la migración de la 3b borraba la regla de H-4 en `CK_Autorizacion_Motivo`;
  - los conteos de numeración por el tipo TI.
- **Pruebas:** Mvp **24/24 con F10** en las dos instancias.
- **T6** (`traspasos/B/2026-10-15-t6-medicion-adr118-119.md`):
  - **criterios 1 y 2 en verde**;
  - **faltan 2 corridas por lado** (regla de dispersión), con la máquina sola, unas 3,5 h. El guion de la noche está en el scratchpad de la sesión anterior: rehacerlo con el procedimiento de la medición oficial;
  - ahora existen los bancos N6-02 y N6-03 (#38): medirlos también.
- **27-oct:** unir T1 y la 3b si todo está en verde. Así **F10 cuenta (MVP 10/10)**. Medición del MVP: 1-nov.
- **Después de la 3b:** `b/ola5-auditoria`, con la migración regenerada, `SecExportacion` en `Todas` y el DENY ALTER ANY USER con un solo dueño (RG-14).

## Pendiente de A (área común)
- Publicar el **#42 corregido**.
- **Fase A de ADR-81** (#26 ya está unido; nada la bloquea).
- **A-N2:** corrección `FORCESEEK` en UF-05 de `TR_Documento_Emision` (falla 8.2 (6) de T-28). **El propietario dijo «A-N2 después»: confirmarla a A después de esta unión**, con un agente que no sea L ni I, sobre `b/prep-27oct`.
- **A-N3 y A-N4** (devops).
- Observaciones Bajas de #39 y #41 (`Retry-After` en el 503 de la guarda; `MensajeSinPermiso`).
- PA30 intermitente en la instancia predeterminada (DL-22).

## Pendiente del propietario (firmas)
- **Licencia:**
  - firmados el 14-oct: DL-07 (a), DL-08 (a), DL-10 (a), DL-13, DL-14 y DL-17;
  - **sin firmar:** DL-01, DL-02, DL-03 y DL-05 (camino crítico del desarrollador I), DL-09, DL-11, DL-12, DL-15, DL-16, DL-18 a DL-22, la regla 3, las P de v2.2 a v2.4, C-5 y DL-21 (para activar `UseLicencia`) y la precisión de las cuatro rutas `Esencial` de #35.
- **Custodio suplente (AP-02):** falta el nombre.
- **Backup Tool:** no listo para producción, registrado sin plan por decisión del propietario.

## Entorno de LFMB
- Las dos instancias de SQL Server 2025 están **en modo mixto** desde el 2026-10-15.
- Falta el origen NuGet local `C:\Users\lfmen\source\NugetLocalFeed`: restaurar con `--ignore-failed-sources`.
- Runtime .NET y ASP.NET Core 10.0.13.
- Si `RecursoLlavesGsfTests` falla por la huella, volver a sacar `src/GPOS.Criptografia/Llaves/*.json` con `rm` y `git checkout` (fines de línea LF).
- Pruebas que fallan **solo bajo carga** y pasan solas: `AplicacionEmisionPlanTests`, C-10, `CandadoRestauracionApiTests` (S-1) y `EsquemaPendienteAccesoTests.Un_Super_Usuario_inhabilitado…`.
- **Árboles de trabajo:**
  - `GPOS-B-integracion`: uniones;
  - `GPOS-B-prep27`: preparación del 27-oct;
  - `GPOS-B-carga`: base de T6 y comprobaciones.
