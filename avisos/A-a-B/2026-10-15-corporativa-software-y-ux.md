```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/blueprint-vertical-corporativa-2026-10-15.md y ux-vertical-corporativa-2026-10-15.md
Estado: Abierto — SW-01 a SW-18 y UQ-1 a UQ-9 por firmar; el auditor está en curso; DB-1 a DB-7 para B
```

# Vertical Corporativa: blueprint técnico y diseño UX listos

## Blueprint (755 líneas, alineado con UX en la §16)
- **Módulos:** `Comensales` (capacidad común, nivel 5) y `Corporativa` (nivel 6). Ninguna vertical depende de otra. La ventana es propia y no toca `PuntoVenta.razor`.
- **Sin carrito en el servidor:** tokens firmados de vida corta para la lectura, la identificación y la cotización.
  - El motor corre en la cotización y otra vez en la transacción.
  - Si el reparto cambia, la API responde 409 `REPARTO_CAMBIO`.
- **Contratos:** C-1 a C-14 y la administración, cada uno con su `ClaseLicencia`, privilegio, límite y candado.
- **Costura fiscal:** estrategias por modo, con H-04 abierta y falla cerrada.
- **Estimación:** **8,8 sp** (9,3 con S-1) en los tramos T1 a T12.

## UX
- **Caja:** la foto con la confirmación de identidad, la botonera por franja, el reparto por línea, el saldo «QUEDA» en vivo (F-5) y el cobro mixto.
- **Estados:** EC-01 a EC-17.
- **Tickets:** TK-01 a TK-04, en 80 y 58 mm.
- **Administración:** AC-01 a AC-14, solo para la empresa.
- **Privacidad:** PV-1 a PV-7.
- **Estimación de la interfaz:** unas 2,9 sp.

## Para B (dependencias DB-1 a DB-7)
| ID | Qué |
|---|---|
| DB-1 | Mecanismo de verticales 3c |
| DB-2 | `PanelCobro` con nómina |
| DB-3 | FD-10 (marca de inventario compartida con `CARGO_EMPRESA`) y los métodos aditivos en `IExtensionVenta` |
| DB-4 | Ids de tipo 40 y 41 y el rango de errores 51800-51849 |
| DB-5 | Módulos en la API de reportes |
| DB-6 | Sincronizador del nodo |
| **DB-7 (Alto)** | **El acceso multiempresa v1 no está implementado:** un cajero del tercero podría entrar a otra empresa de la instalación. **Es condición antes del primer cliente.** |

**También:**
- **El Z de hoy solo suma ventas y movimientos de caja** (`ConsultasCaja.cs:152-207`). Hace falta `IAporteCierreCaja`, con la regla de que cada peso cuenta una vez.
- **La reimpresión de documentos sin NCF no cuenta las copias.** Se propone contarlas y marcarlas (P-8 y SW-11).

## Siguiente en A
El auditor revisa el diseño. Después el Maestro reúne en una sola hoja FD-01 a FD-15, SW-01 a SW-18 y UQ-1 a UQ-9 para la firma del propietario.
