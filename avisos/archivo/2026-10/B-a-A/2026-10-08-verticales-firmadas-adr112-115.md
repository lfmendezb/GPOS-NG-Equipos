```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG master (6077b0c); diseño en b/verticales-diseno (cc82956)
Estado: Abierto
```

# Verticales firmadas: ADR-112 a 115 registrados en `master` (`6077b0c`)

El propietario firmó la hoja de las verticales completa el 2026-10-08. Los ADR quedaron registrados en `master` y entraron sin choques sobre `b403f32`.

## ADR registrados
- **ADR-112 · Mecanismo de verticales y ruta única de emisión.**
  - **Solo el SUPER activa una vertical**, también después de la versión 1 del acceso multiempresa.
  - **Los ingredientes siguen la política de existencias negativas de la empresa.**
- **ADR-113 · Mesas y comandas.**
  - **En Restaurante, el inventario lo mueve la orden enviada a cocina, no la factura.** La factura solo afecta a caja y CxC.
  - Pendiente de diseño, en la sección 5.1 de la hoja. Uno de sus puntos choca con EN-4: los movimientos de inventario de la comanda sí suben desde el nodo.
- **ADR-114 · Impresión remota de comandas por cola y estación.** Requiere la revisión del auditor antes de construir.
- **ADR-115 · Duty Free.** Hay cliente: una cadena con tres sucursales en aeropuerto, que vende en salida y en llegada y no vende al mercado local. La construcción depende de las respuestas del despacho aduanal; la venta de llegada, en particular, de DF-Q4.

## Precisiones registradas
- **MD-31:** se reabren mesas y comandas; la entrega 3 va en tramos 3a, 3b y 3c, de unas 22 sp. El corte de la entrega 1 no se mueve.
- **ADR-04:** biblioteca `GPOS.Componentes`, solo para lo nuevo.
- **ADR-58, punto 10:** módulos de vertical que solo activa el SUPER, y códigos desconocidos ignorados.

## Para A
- **`CLAUDE.md`:** conviene agregar las verticales (ADR-112 a 115) a la lista de decisiones. Lo hace A, que es su dueño.
- **Plan de la entrega 1:** V-9 ya lo tomó A (E1-1 y E1-2). Además quedan:
  - EN-1: reservar `GPOS.Cuenta:` en la pasada de documentos de ADR-45;
  - EN-2: constantes de las clases 2, 3 y 4 del kárdex;
  - EN-4: corregido por la condición de V-2, porque la comanda mueve inventario y sus movimientos se replican.
- **ADR-109 a 111** (ola 5) siguen reservados. Se registran cuando el propietario confirme R-8, PD-07, PD-12, PD-03 y E-10.
