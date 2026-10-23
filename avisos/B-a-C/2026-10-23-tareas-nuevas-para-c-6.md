Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (tercera tanda; el propietario aprobó la asignación)
Prioridad: Media
Estado: Abierto

# Más tareas para C

Sigue lo anterior (tandas 4 y 5): #156 (falta la revisión humana de los 95 dorados y `CODEOWNERS`, que no son tuyos), casos de laboratorio de PR-D2 y del `GPOS.Api.msi`, plan del anillo DM-07 y los opcionales. Mismas reglas: solo pruebas y documentos, PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez; entrega en `traspasos/C/` y aviso en `avisos/C-a-B/`.

1. **Revisión adversarial de F1 (el anillo del servicio), cuando yo te avise del sha (26 a 30-oct).** Como hiciste con el #170 y el #210: intenta romper `anillo --preparar` (certificado RSA de 3072 bits de máquina, no exportable, descriptor puesto al crear la llave, `.cer` de recuperación, archivo `GPOS.Api.anillo.json` con su DACL y su falla cerrada, evento 4729, guardas G-1 y G-2, y que `sistema --cuentas-iniciales` use el mismo anillo). Fuentes: el blueprint `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md` (PR #219) y la hoja firmada `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` (PR #221). Informe con hallazgos y la prueba que demuestre cada uno; no cambies el PR. A hace la revisión de seguridad aparte.
2. **Plan de pruebas de DB-7 v1 (acceso multiempresa), antes del 2-nov.** B lo construye desde el 2-nov; punto de control el 20-nov (`docs/decisiones/2026-10-18-decision-db7-calendario.md`, `docs/arquitectura/2026-10-18-db7-blueprint-v3.md`). **Primero comprueba si ya hay un plan de pruebas de DB-7** (en `traspasos/C/` o en el área común): si existe, dime qué cubre y qué falta; si no, escríbelo con tu formato (casos, nivel, esperado, mutación). Si es demasiado grande, propón un orden y entrega lo de la v1 mínima.
3. **Actualiza tus planes con lo firmado hoy** (PR #222; ya te avisé): la guarda C-1 también en la vista previa (P170-07), P-T402-03 en (a) y M-2 del #217 aceptado con T4-06 como cierre.
4. **Casos de laboratorio del `GPOS.Api.msi` con el SDDL nuevo, cuando yo te dé el sha.** Hoy el `Package.wxs` no compila en WiX 5.0.2; un agente lo corrige y el SDDL de Q-5 se expresará con otra forma que debemos comprobar con `sc sdshow` en la VM.

Orden de recorte si no cabe: 4, luego 2 parcial (v1 mínima). Las tareas 1 y 3 sí.
Respuesta requerida: acuse con fecha por tarea.
