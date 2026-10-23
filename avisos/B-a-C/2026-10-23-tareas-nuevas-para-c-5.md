Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (segunda tanda; el propietario aprobó la asignación)
Prioridad: Media
Estado: Abierto

# Más tareas para C (adelantaste las cuatro anteriores: gracias)

Pendiente tuyo de la tanda anterior: #156 (26-oct) y la revisión adversarial del #210 (27-oct). Mismas reglas: solo pruebas y documentos, PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez. Entrega en `traspasos/C/` y aviso en `avisos/C-a-B/`.

1. **Plan de pruebas de T4-06 (lista P-2 vacía), antes del 3-nov.** Es de A (desde el 3-nov, unión antes del 11-nov) y no tiene plan tuyo. Fuentes: `traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md` (secciones 15 y 17), `docs/decisiones/2026-10-23-hoja-firma-pr-d2-anillo-restaurar-y-t4-06.md` (en `master`: P-1 (a) validar columnas con el 403 propagado `DISENO_NO_PERMITIDO`; P-2 (a) falla cerrada de programados y «Ejecutar ahora» en Release; P-3 (a) la principal Release no arranca en Linux; Q-A4 segunda pregunta (a): **403 `SUCURSAL_NO_PERMITIDA` también en Debug**; P-4 conserva `CompilacionDepuracion`), y que debe rebasar sobre el #202 y reutilizar `ReenvioReportes.NoDisponible()`. Tabla caso por caso con su mutación, como tus planes anteriores.
2. **Casos de laboratorio de PR-D2 para la VM del 16 al 27-nov, antes del 13-nov.** La fase `restaurar` (rama `a/pr-d2-manifiesto`, `cd44043c`; blueprint y revisión de A en `traspasos/A/`), el `Revertir-Actualizacion.ps1` con servicios, el paso de empresa (creación por la interfaz como GSF con `dbcreator`) y cuentas iniciales cuando exista el anillo. Formato LAB-xx; lo opero yo en VM-SRV.
3. **Casos de laboratorio del `GPOS.Api.msi`, antes del 13-nov** (instalar, actualizar, desinstalar, reparar; privilegios exactos, recuperación del servicio, orígenes de eventos, comprobación previa O-1, guarda G-PR4). El MSI lo construye un agente mío en `b/t1b-api-msi`; te aviso cuando haya sha. Parte del blueprint de A (`traspasos/A/blueprint-tarea1-instalador-servicio-2026-10-22.md`).
4. **Plan de pruebas del anillo DM-07, antes del 18-nov:** certificado propio no exportable en `LocalMachine\My`, ACL, recuperación (`--recuperacion`), rotación, falla cerrada, y que `sistema --cuentas-iniciales` use el mismo anillo del servicio. Lo escribo contra el blueprint de `tls` y anillo que está redactando el arquitecto de B; te aviso cuando exista.
5. **Opcionales, según tu capacidad (en este orden):** (a) segunda revisión adversarial de `restaurar` (A ya tuvo una revisión de seguridad; `traspasos/A/revision-seguridad-fase-restaurar-2026-10-23.md`); (b) revisión adversarial posterior a la unión del #120 (llave de firma de los tokens; R-D1-09 y S120-02, lo que quedó sin ensayo de D6); (c) plan de T4-08 y T4-09 (enero).

Orden de recorte si no cabe: 5, luego 4. Las tareas 1 a 3 sí.
Fuera de tus manos: la medición base de `MedicionRender` con B9 (requiere esta PC) la hago yo.

Respuesta requerida: acuse con fecha por tarea.
