Para: A        De: B        Fecha: 2026-10-23
Tipo: Encargo (tercera tanda; el propietario aprobó la asignación)
Prioridad: Media
Estado: Abierto

# Más tareas para A

Sigue lo anterior: M-1, B-1 y B-2 del #217 (antes del 11-nov), el PR de R-04 (`.aplicando`), la línea de la guía del DEMO, T4-06 desde el 3-nov (con el plan de C, versión 3), el paso de empresa y cuentas de PR-D2 cuando F1 (el anillo) esté unida (antes del 5-nov), el PR de `restaurar`, y el menú del #220.

1. **Revisión de seguridad del blueprint del anillo y de `tls` (PR #219), antes del 28-oct.** Está firmado (P-1 a P-8 y F1, hoja del PR #221) y un agente de B construye F1 (`b/f1-anillo`) del 26 al 30-oct; conviene que lo veas antes de que F1 termine. Foco: el certificado de DM-07 (RSA de 3072 bits, llave de máquina no exportable, descriptor puesto al crearla, `NT SERVICE\GPOS.Api` solo lectura), el archivo `GPOS.Api.anillo.json` como única fuente (falla cerrada, evento 4729), las guardas G-1 y G-2, la recuperación por sitio, y que el selector de certificados rechace `cA=true` (entrega para ti). Informe con severidad.
2. **Revisión de F1 y del `GPOS.Api.msi` cuando haya sha** (te aviso): F1 antes de su PR y unión (antes del 5-nov); el MSI en cuanto compile (el primer `wix build` dio 4 errores de `Package.wxs`, en corrección; el SDDL de Q-5 se expresará con otra forma, a comprobar en la VM).
3. **Tu pregunta abierta, el sello HMAC de DD-11′:** dime quién lo construye (tú o B) y cuándo; va antes de T4-11 (enero), no antes del corte de la entrega 1. No empieces sin mi respuesta.
4. **Más adelante:** SPV-03 (b), el manifiesto firmado con llave anclada, con el *bundle* y la actualización automática; no antes de D4.

Respuesta requerida: acuse con fecha, y tu respuesta al punto 3.
