---
name: adr92-decisiones-2026-10-22
description: "2026-10-22: aprobadas F-1 a F-8 (F-5 con observación: la supresión abarca el historial) y F-9 (saldar deuda; saldo a favor no bloquea); Q-TT1-a respondida; TT lo construye B; 4 preguntas de B sin responder"
metadata:
  node_type: memory
  type: project
  originSessionId: 8d3579bd-595e-4fdd-99fe-94d543735f58
---

Decisiones del propietario en el chat del 2026-10-22 sobre el borrador de B «ADR-92: integración de las respuestas de A» (borrador en el scratchpad de la sesión, no en el repo):
- **Aprobadas:** F-1 (P-92-S1, lista cerrada del caso para el SUPER), F-2 (P-92-S2, `--caso` en `GPOS.Migracion`), F-3 (P-92-S3, cierre de urgencia sin entrar a una empresa), F-6 (TT-P4, evento en `audit.Bitacora` de la empresa, ≥10 años), F-7 (TT-P5, fin de conservación, lo dispara el ADMIN), F-8 (textos de las pantallas).
- **F-5 aprobada con observación:** la supresión **debe abarcar también el historial temporal**, aunque se trate como restringido. Esperan que las solicitudes vengan con poder legal si el cliente apodera a una firma de abogados; para el sistema es lo mismo: se suprimen los datos del cliente que lo exija. Esto vuelve obligatorio el verbo de `GPOS.Migracion` de TT-P2 (+0,2 a 0,4 sp) y cambia lo que TT-04 decía por omisión.
- **Q-TT1-a respondida por él:** ningún dato permite saber si un RNC es de persona física; solo la estructura (RNC 9 dígitos, cédula 11, sin guiones). Propone un **maestro «Tipo de identificador fiscal»** (Identificador Empresa, Persona Física, Pasaporte/otros, Carnet de Migración): más determinista que deducir por `TipoIdentificacion`.
- **Responsable de TT-01 a TT-06: equipo B.**
- **F-4 aprobada según la recomendación** (rutas `/api/titulares`, privilegio `solicitudestitulares` en «Especiales», confirmación tecleada al suprimir).
- **F-9 (afinada el mismo día):** los saldos a favor no bloquean. **Cliente con deuda por cobrar:** la empresa puede negarse a suprimir los datos que impidan el cobro y aplazar la supresión de los datos *estrictamente necesarios* para avalar la deuda (por si debe proceder legalmente); esos datos no se pueden usar para fines ajenos al cobro. **Proveedor con CxP adeudada (caso sui generis):** se levanta una bandera con el motivo (la CxP), «no se recomienda la supresión», y se dan dos opciones claramente reconocibles que no se pasen por alto: «Proceder de todos modos» o «Esperar a saldar la deuda». Pendiente: qué campos son «estrictamente necesarios», quién completa la supresión al saldarse, y validar con el abogado.
- **4 preguntas de B (respondidas el 2026-10-22):** (1) la supresión del historial **no** cubre los respaldos; (2) **sí** se registra el apoderado y los datos del poder, con posibilidad de **adjuntar el documento del poder íntegro** como aval en un proceso legal; (4) el verbo del historial corre **dentro de los 10 días hábiles**. (3) **decidida:** el maestro «Tipo de identificador fiscal» **convive** inicialmente con C/P/N/R (no los reemplaza); **solo un SUPER puede usarlo** y en él se definen las reglas de cantidad de dígitos, similar al modelo actual de C/R/N/P. Hoy el tipo se deduce solo por el largo de los dígitos (`TiposIdentificacion.TipoDe`: 9 = R, 11 = C, vacío = N, otro = P). Precisado: solo el SUPER **define** los tipos y sus reglas; el ADMIN y los usuarios lo **seleccionan** al registrar el cliente; se construye **aparte de TT** (necesita su propio ADR, estimado y migración; sin fecha: nada desplaza a DB-7). Sin decidir: el formato del carnet de migración (queda configurable por el SUPER) y el número de ADR (el rango de B, 100 a 129, está agotado).

**Why:** ADR-92 firmado el 2026-10-20; estas precisiones cambian lo que ve o hace el ADMIN y el SUPER.
**How to apply:** registrar como hoja de firma y precisión de ADR-92 en un PR a master solo cuando él lo pida; CS-P2 entra en la DDL de D1 antes del 2026-11-02. Relacionado: [[tarjetas-articulos-decisiones]], [[documentacion-estricta-estado-de-firmas]].
