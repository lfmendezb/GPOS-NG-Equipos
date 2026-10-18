```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/demo-plantillas-lote (3967ac1), PR #15 hacia feature/modelo-ng
Estado: Abierto
```

# C-6: plantillas del DEMO con existencias y lotes (PR #15)

**PR #15:** https://github.com/lfmendezb/GPOS-NG/pull/15. Se une sin conflictos con `dec845c` (después del PR #13). C no une.

## Formato verificado (109aae0)
- La plantilla «Existencias iniciales» tiene las columnas Artículo*, Almacén, Cantidad*, Costo, Fecha, **Lote** y Ubicación (`Importaciones.cs:301-320`). **No tiene vencimiento**, y una columna desconocida hace rechazar el archivo completo.
- Nada escribe `inv.Lote.FechaVencimiento`, la Fecha no puede ser futura y no hay fechas relativas.
- **Por eso la columna «Vence» no se inventó:** queda como dependencia de **UX-118-01 y T4**.

## Juego nuevo (`paquetes-demo\datos-demo-lotes\` en el equipo C, fuera del repositorio)
- **01 a 05 y 08:** sin cambios.
- **06-articulos:** 8 artículos nuevos con «Requiere lote»: `LAC-023` a `027`, `BEB-024`, `VIV-047` y `VIV-048`, con EAN-13 de prefijo 209. No se marcaron artículos existentes, porque las facturas históricas van sin lote y el disparador 51307 las rechazaría.
- **07-existencias-iniciales:**
  - las cantidades cubren unos 15 días de venta;
  - suben 113 de los 153 artículos (de 8.329 a 12.656 unidades);
  - se agregan **14 lotes**;
  - **`LAC-020` queda en 2 unidades a propósito, para mostrar el 422.**
- **`T4-vencimientos-lotes.csv`:** vencimientos fijos entre julio y diciembre de 2027, más los casos de demostración contados desde la instalación:

  | Artículo | Vence | Qué muestra |
  |---|---|---|
  | `LAC-023` | instalación − 5 días | Vencido |
  | `LAC-024` | día de la instalación | Vence hoy: se vende |
  | `LAC-025` | instalación + 3 días | Vence pronto: es el sugerido |
  | `VIV-047` | instalación + 5 días | Vence pronto: es el sugerido |

  Cada uno tiene además otro lote normal.
- **Las facturas de la plantilla 08 no mueven inventario** (`ImportacionExistencias.cs:62`): el orden entre 07 y 08 no afecta a los negativos.

## En el repositorio
- `instalador/Demo/datos-demo/LEEME.md`: nueva sección del juego con lotes.
- `ImplantacionDemoTests`: toma las cifras de los archivos y comprueba los artículos con lote y los lotes creados.

## Pruebas (filtradas, `.\SQLEXPRESS`)
`ImplantacionDemoTests` pasa con el juego nuevo (161 artículos, 167 existencias, 14 lotes y 9.604 facturas, sin errores ni avisos) y con el del 2026-10-07.

## Para B
- **T4:** agregar la columna «Vence» (fecha, opcional) en «Existencias iniciales» y decidir qué pasa si el lote ya existe con otro vencimiento (ver UX-118-02).
- **Antes de T4:** los 8 artículos con lote no se pueden vender en el POS por el disparador 51307. **Este juego no se publica en OneDrive hasta que exista un paquete con T4**; entonces, quien arme el paquete pasa los vencimientos del CSV a la plantilla 07.

## Estado
- **C-5, C-6 y C-7 entregados.**
- **C-2:** espera el PR de H-11 (el #14 es la tanda A-2 de A, no H-11).
- C queda sin agentes activos.
