---
name: restaurante-catering-ejecutivos
description: "Restaurante sin mesas: catering y «ejecutivos» = menú ejecutivo diario + clientes corporativos a crédito con consumo por empleado (propietario, 2026-10-09); hoja de firma en preparación"
metadata:
  node_type: memory
  type: project
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-10T00:31:04.013Z
---

El 2026-10-09 el propietario preguntó si la vertical Restaurante sirve a negocios que **no atienden en mesas** sino por **catering** y «**ejecutivos**». Aclaró que «ejecutivos» son **ambos**: (a) menú ejecutivo (plato del día o combo a precio fijo que cambia cada día) y (b) clientes corporativos (una empresa paga los almuerzos de sus empleados a crédito; consumo por empleado, con o sin tope, y factura a la empresa por período).

Ya cubierto en diseño: venta sin mesa (Mostrador / Para llevar / Domicilio como mesas virtuales, ADR-113), «Venta por Despachar», anticipo de eventos facturado al cobrarlo (DP-3 a, condicionado a C-39 y CT-Q8), producción y merma (ADR-125). No diseñado: el evento como documento, el menú ejecutivo y el consumo corporativo.

**Why:** amplía el alcance de la vertical Restaurante para un tipo de negocio real del propietario.

**How to apply:** el Arquitecto Maestro de B prepara `docs/decisiones/2026-10-09-hoja-firma-catering-y-ejecutivos.md` en `b/verticales-diseno`; es diseño para la entrega 3 salvo decisión del propietario, sin restar capacidad al MVP del 1-nov ([[mvp-fecha-medicion]]). Punto fiscal clave del corporativo: cuándo nacen el ITBIS y el NCF (consumo frente a factura del período). Relacionado: [[ventana-facturacion-por-vertical]], [[prioridad-ventas-inventario]].

**Firmada el 2026-10-09 «todo según recomendación»** (`b/verticales-diseno` `a98edbe`): CE-01 evento ligero sobre la cotización COT; CE-02 menú ejecutivo como combo K con grupos de elección y menú del día; CE-03 consumo «Cargo a la empresa» no fiscal + B01 agrupado por período sin cruzar el mes, Diario por omisión (solo el SUPER amplía, tras CC-01); CE-04 padrón de empleados y topes; CE-05 reportes CO-01 y CO-02; CE-06 menú y eventos en RESTAURANTE, módulo complementario CORPORATIVO; CE-07 tramo 3d después de la 3b (entrega 3). Pendientes: registrar ADR-126 (corporativo), ADR-127 (combo) y precisión de ADR-113 (eventos) en master; P-01 a P-06 del propietario; CC-01 a CC-05 al contador (CC-01 crítica).
