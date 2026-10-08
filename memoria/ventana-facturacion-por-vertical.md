---
name: ventana-facturacion-por-vertical
description: "Regla del propietario 2026-10-08: cada vertical tiene su propia ventana de facturación, independiente de la Facturación Ágil, aunque sea casi igual"
metadata:
  node_type: memory
  type: project
  originSessionId: 530fd254-7a8e-48be-92f3-504c7e3e55bc
  modified: 2026-10-08T14:41:06.371Z
---

El 2026-10-08 el propietario pidió: **cada vertical (Farmacia, Restaurante, Duty Free, las que vengan) tiene su propia ventana de facturación, independiente de la Facturación Ágil**, aunque el cambio sea mínimo y las ventanas resulten muy parecidas o iguales.

**La Facturación Ágil es la ventana de la vertical Estándar** (precisión del propietario, 2026-10-08): no es una base común que las demás extienden, sino una ventana más, la de la Estándar.

**Why:** que los cambios de una vertical nunca toquen ni arriesguen la Facturación Ágil de la Estándar (entrega 1) ni las demás verticales.

**How to apply:** nada específico de una vertical (p. ej. vendedor obligatorio o botonera de vendedores de Duty Free, pasaporte, vuelo) se agrega como parámetro de la Facturación Ágil; va en la ventana de su vertical. Se puede compartir lo común por componentes (`GPOS.Componentes`, ADR-04) y la ruta única de emisión (ADR-112), no la pantalla. Relacionado: [[dos-equipos-a-coordina]], [[corte-entrega1-mediados-diciembre]].
