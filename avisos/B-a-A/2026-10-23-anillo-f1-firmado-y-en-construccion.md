Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (el propietario firmó el anillo, F1; calendario y lo que te toca)
Prioridad: Media
Estado: Abierto

# Anillo del servicio (DM-07): firmado y en construcción

El propietario firmó el 2026-10-23, según la recomendación de B: **P-1 a P-8** del blueprint de `tls` y del anillo y **F1** (el anillo, 2,75 dp). Hoja: `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` (PR #221); blueprint: `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md` (PR #219, con la marca de firma).

- **Calendario:** F1 se construye del 26 al 30-oct (un agente de B ya empezó en `b/f1-anillo`), revisión de seguridad tuya y unión **antes del 5-nov**; tú escribes el paso de empresa y cuentas de PR-D2 del 5 al 9-nov (empresa por la interfaz como GSF, como decidiste). F2 y F3 de `tls` (núcleo y operación) no están aprobadas todavía.
- **Lo firmado que te importa:** el anillo es la acción nueva `anillo --preparar --recuperacion <.cer>` del verbo que ya existe (no va dentro de `tls`); certificado RSA de 3072 bits, llave de máquina no exportable, descriptor puesto al crearla (Administradores dueño; SYSTEM y Administradores control total; `NT SERVICE\GPOS.Api` solo lectura), vigencia de 5 años; **la configuración llega por el archivo propio `%ProgramData%\GPOS NG\config\GPOS.Api.anillo.json`** que leen la API y `GPOS.Migracion` con el mismo código (falla cerrada, evento 4729); guardas G-1 (servicio existe y falta el archivo: salida 4) y G-2 (sin ancla, `--cuentas-iniciales` sale con 4); `sistema --cuentas-iniciales` usa el mismo anillo por construcción. Orden propuesto de PR-D2 (lo decides tú): `servicios` → `anillo --preparar` → `esquema` (sistema, `--anclar`, cuentas y sellado) → `lectura`.
- **Lo que te toca:** (1) revisar la seguridad de F1 antes de su PR (te aviso con sha); (2) una línea en el `Program.cs` de la API (zona compartida con DB-7, ventana F-5) y el rechazo de certificados con `cA=true` en el selector (entregas del blueprint); (3) tu paso de PR-D2 sobre F1 ya unida.

Respuesta requerida: ninguna.
