```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (472d078); b/ola5
Estado: Abierto
```

# Respuestas de A: A-Q1 a A-Q13, vistas revisión 4, kit y Farmacia

Documento completo del arquitecto-software de A: `traspasos/A/respuestas-b-fraccionada-por-despachar-2026-10-09.md`. Lo técnico ya está decidido por A; **OD-1 a OD-4 van al propietario** (te aviso).

## Para recalcular la huella de la ola 5 (ya, sin esperar)
- **Pregunta 1:** agrega `TipoIdentificacionCliente`.
- **Pregunta 2:** la línea de factura de conduce no viene en 0, pero el costo debe **heredarse del conduce**.
- **Pregunta 3:** el movimiento de clase 7 del conteo lleva costo (lo fija el servidor, OB-03), `UnidadId` y `FactorUnidad`, con `CantidadOrigen` en NULL.
- **Pregunta 4:** `caja.Cierre.Anulado` coincide por construcción con el estado 2.
- **Pregunta 5:** en el contrato, **claves** de privilegio, no nombres visibles: `vercostos`, `verdatospersonales`, `vercuadrecaja`.
- **Pregunta 6:** **`RncReceptorEnmascarado`** (como dice ADR-109); aplica el mismo género gramatical a cada columna.
- A-Q5 (`OrigenInventario`) cambia la huella: entra en la entrega 1 **antes** de unir la ola 5.

## UF-05 y devoluciones
Confirmado en `472d078`: la factura desde conduce no genera kárdex ni descarga dos veces. **Tu hallazgo es correcto** (`Ventas.cs:327-328`): A lo corrige en una «tanda UF-05» de la entrega 1 (la devolución no mueve inventario; la mercancía entra por Entradas/Recepción con el conduce de origen). Sin firma nueva.

## A-Q (resumen)
- **A-Q5:** sí a `OrigenInventario` (F, C, O, P); regla: si no es F, la factura no puede tener movimientos.
- **A-Q6:** sí a las clases `E` y `V` y al saldo `D`; las diseña el arquitecto-datos de A; la línea de inventario guarda `(VentaDocumentoId, VentaLinea)` con FK real. B revisa.
- **A-Q10:** columna `Sueltas` en las filas de existencia, sin nivel de bloqueo nuevo (entrega 3). **A-Q11:** sí a la forma, sujeta a CT-Q8, C-39 y el XSD del e-CF (entrega 3).
- Las demás, en la sección 2 del documento.

## Kit
- **D-K4:** de acuerdo, con condiciones (versión `0.x`, revisión de A, paso al núcleo con T-29).
- **D-K5:** en `GPOS.Conectores.Contratos`, no en el kit (lo usa también AdmCloud).
- Campo: **`contingenciaReemplazo`**.

## Farmacia
El alta y la importación ya crean la base igual a la unidad de venta (TAB, factor 1). Riesgo: una CAJA de compra nace con factor 1. OD-4 (¿farmacia antes de la tanda 3?) decide si hace falta el factor en la plantilla (+0,15 sp).

## V-08
Normalizar el IPv4 mapeado y limitar en dos niveles (dirección y /64 con 4 veces el cupo), ≈0,05 sp, con la fase A del segundo factor.
