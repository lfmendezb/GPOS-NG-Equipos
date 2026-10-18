```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng; diseño en b/verticales-diseno (4be9b72)
Estado: Abierto
```

# Dos puntos del comprobante en código de A, hallados en el diseño de verticales

El propietario aprobó en B el diseño de las ventanas por vertical: Farmacia, Restaurante con mesas y comandas (MD-31 reabierto) y Duty Free. **Se mantiene el cronograma:** las verticales se construyen en la entrega 3. Los documentos están en `b/verticales-diseno`.

El especialista-contable de B propone dos ajustes para la entrega 1, de unos 0,1 sp cada uno. Están en código de A:

1. **E1-1 (Media hoy; Alta al activar el restaurante):**
   - el comprobante se guarda siempre con la propina legal en 0 (`src/GPOS.Core/Consultas/Fiscal/ConsultasFiscal.cs:37`), así que el 607 la informaría en cero aunque la venta la tenga en `Venta.CargoServicio`;
   - es el mismo punto que HD-11 de la solicitud de la ola 5 (S-9).
2. **E1-2 (riesgo; B no lo verificó en la venta POS):**
   - confirmar que el comprobante y el 607 guardan los montos en pesos cuando la venta se cobra en dólares;
   - afecta a cualquier cliente que cobre en USD;
   - coincide con PD-02 / S-7 de la solicitud de la ola 5.

Los otros enchufes propuestos para la entrega 1 son solo de reserva, de unos 0,25 sp en total:
- el recurso de bloqueo `GPOS.Cuenta:`;
- las clases `PRO` y `MER`;
- el tipo 16 / E46;
- la clase «Consumo de personal»;
- los códigos de módulo de la licencia como lista abierta.

Irán a la hoja de firma de las verticales. A decide cómo entran en su plan.

## Complemento (2026-10-08, arquitecto-maestro de B, hoja `2026-10-08-hoja-firma-verticales`, bloque V-9)
- **E1-2 tiene evidencia en el código; falta la prueba con una venta en USD.** En una venta en dólares, los montos del comprobante salen de las líneas sin aplicar la tasa (`src/GPOS.Core/Servicios/Nucleo/VentasNg.cs:87-89`, `PosService.cs:265`), y `rpt.Formato607` no convierte (`Ola4Compras.sql:5345`).
- **E1-3, E1-4 y E1-5 ya no hacen falta.**
  - Los tipos 16 y 46 ya están en el catálogo.
  - La merma y el autoconsumo van por la clase 5 con motivos.
  - La línea de venta ya guarda el costo.
- **Lo que queda para A en la entrega 1:** E1-1 (propina) y E1-2 (montos en pesos), unas 0,2 sp de código.
