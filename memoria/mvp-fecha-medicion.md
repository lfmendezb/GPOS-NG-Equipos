---
name: mvp-fecha-medicion
description: "MVP de flujos de punta a punta: fecha de medición 2026-11-01 (propietario, 2026-10-09); responde PF-Q2; meta 70 % (7 de 10) y lista F1-F10 aprobadas"
metadata:
  node_type: memory
  type: project
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-09T23:23:25.756Z
---

El 2026-10-09 el propietario fijó la **fecha de medición del MVP: 1 de noviembre de 2026** (domingo). Responde PF-Q2 de la hoja «Por despachar»: como es antes del 15-nov, «Por despachar» no cuenta para la meta.

Contexto: el MVP se mide como «% de flujos de la lista funcionando de punta a punta en la aplicación real, con sus pruebas». B propuso una lista de 10 flujos (F1 inicio de sesión y permisos, F2 maestros, F3 compra y recepción, F4 venta Ágil con NCF, F5 crédito y CxC, F6 devolución con nota de crédito, F7 caja y Z con reimpresión, F8 conteo y kárdex, F9 reportes por la API de reportes, F10 transferencias 3b) y dos escenarios: 60 % (6/10) y 70 % (7/10). El propietario preguntó si el equipo nuevo permitía subir a 70 %.

**Why:** fija el calendario de B como coordinador (cierre de la ola 4 el 15-oct, ADR-118/119, ola 5 unida el 22-23 oct).

**How to apply:** planificar para que lo medible esté unido y verificado antes del 1-nov (en la práctica, el viernes 30-oct). Si la meta (60/70) o la lista aún no están confirmadas, confirmarlas antes de llevar la hoja a firma. Relacionado: [[prioridad-ventas-inventario]], [[dos-equipos-a-coordina]].

**Confirmado por el propietario (2026-10-09):** meta **70 % (7 de 10)** y lista F1-F10 aprobadas; verificación de QA de F1 a F8 lanzada ese día. Falta la hoja de firma formal (B coordina).

**Línea base del 2026-10-09 (QA, `feature/modelo-ng` `e3a1d2b`, pruebas `tests/GPOS.Tests/Mvp/`, `Categoria=Mvp`):** cuentan 6 de 10 (F1, F2, F4, F5, F6, F8). F3 espera D-MVP-02 (orden recibida y facturada duplica existencia; dirección aprobada: la factura de orden recibida no mueve existencia, solo CxP y ajuste de costo; criterio del especialista contable en curso). **F7 espera la reimpresión de facturas** (propietario: la del Z no basta; la construye A en la tanda de núcleo de caja). D-MVP-01 (cambio de clave solo exigido en la interfaz) encargado a A. RNC del encabezado de evidencia: opción (a), vista `rpt` en la base de la empresa (aprobada).
