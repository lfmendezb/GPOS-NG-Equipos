```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/rb-p4-pruebas-fiscales (9dee5e6), PR #22
Estado: Abierto
```

# C-11, complemento: los 28 casos de la lista de B (P1 a P28) están cubiertos

Completa `C-a-B/2026-10-10-acuse-casos-rb-p4.md`.

## Qué se hizo
- **Trazabilidad P1 a P28:** cada caso de la lista tiene su caso en `ReglasFiscalesBaseTests`.
  - **Ya estaban:** 17 casos, cubiertos o equivalentes.
  - **Agregados:** P2 y P27 en su forma exacta; P5 (incorporación y reaplicación no exigen la marca de 51379); P11 y P12 (devoluciones a suplidor acumuladas dentro de la misma transacción); P13 y P14 (línea, artículo y factura citados en 51362); P17 y P20 (retención acumulada en la misma transacción); P22 (51375 no usa la tasa del pago); P28 (un `UPDATE` de varios motivos se rechaza entero).
  - **Casos límite adicionales:** descuento del 5 %, línea inexistente y retención en CxP.
- **Total:** de 55 a **75 casos** (20 nuevos). Se agregó el auxiliar `EmitirEnLoteYComprobarAsync`, que indica en qué copia llega el rechazo.
- **No se escribieron P29 a P31 (RB-P3), según lo pedido.** No se cambió código de producción.
- **Ninguna contradicción ni caso inalcanzable:** se confirmó contra la definición vigente de `TR_Documento_Ola4b` (guion acumulado, l. 9780) y de `TR_MotivoAjuste_ClaseInmutable` (l. 9127).
- **Preparación:** es directa, sin pasar por el servicio. Las seis reglas solo leen `ventas`, `compras`, `fiscal.Registro606` y las tablas de aplicación de CxC y CxP; no usan el kárdex ni la existencia que pedía el esqueleto.

## Cómo se verificó (`.\SQLEXPRESS`)
- **La clase, 3 veces seguidas:** 75/75 en cada corrida.
- **Lote conjunto:** `ReglasFiscalesBaseTests`, `DisparadoresEmisionTests`, `MigracionOla4bTests` y arquitectura, con el filtro oficial: **236/236**.

## Pendiente
- **Para el arquitecto de datos de B (observación Baja, inferida de la lectura, no ejecutada):** 51374 y 51375 no filtran `Origen <> 'I'` ni `ControlFecha`, a diferencia de 51359, 51362 y 51379. En un mismo `UPDATE` que mezcle un documento de oficina con uno importado, también se validaría el importado. Hoy el servicio emite uno a uno.
- **P29 a P31:** cuando una migración toque `TR_Documento_Anulacion`.

**Estado de C:**
- C-11 y C-12 entregados (PR #22 y #23).
- La construcción de C-13 espera C13-P01 a 04 del propietario.
- Sin agentes activos.
