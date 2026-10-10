# Plantillas de datos del DEMO

Las 8 plantillas del DEMO (minimarket y colmado) se importan desde la Web en **Administración > Herramientas > Importaciones**, en este
orden y tal como vienen:

| Archivo | Importación | Filas nuevas esperadas |
|---|---|---|
| `01-categorias.xlsx` | Categorías | 6 |
| `02-subcategorias.xlsx` | Subcategorías | 33 |
| `03-marcas.xlsx` | Marcas | 15 |
| `04-suplidores.xlsx` | Suplidores | 10 |
| `05-clientes.xlsx` | Clientes | 30 |
| `06-articulos.xlsx` | Artículos | 153 |
| `07-existencias-iniciales.xlsx` | Existencias iniciales (fecha de corte 01/10/2026) | 153 |
| `08-facturas-historicas.xlsx` | Facturas históricas (confirmar los contadores que propone la validación) | 9.604 |

Cifras de `tests/GPOS.Tests/ModeloNg/ImplantacionDemoTests.cs` (prueba que importa las 8 plantillas en una base nueva).

**Las plantillas no están en el repositorio** (son datos de demostración, no código). Si esta carpeta solo tiene este archivo, cópielas
de la carpeta `datos-demo\` del paquete anterior (`GPOS-Demo-Socio-2026-10-07.7z`, en OneDrive, `Instalador\GPOS ARGON\Actualización`).
La prueba anterior las valida con el código de este paquete cuando se ejecuta con `GPOST_DEMO_DATOS` apuntando a esa carpeta; al armar
este paquete no se pudo ejecutar (las plantillas no estaban disponibles en el equipo que lo armó). Si alguna fila falla al validar,
avise antes de importar.

## Juego con existencias y lotes (C-6, PQ-4 de ADR-118 y ADR-119, 2026-10-10)

Con ADR-118 la empresa del DEMO pasa a **prohibir** las existencias negativas, y con ADR-119 todo artículo con «Requiere lote» exige un
lote existente y no vencido en la venta. El juego nuevo está en `paquetes-demo\datos-demo-lotes\`, **fuera del repositorio** como los
anteriores. **No se publica en OneDrive hasta que exista un paquete con T4** (lote en la venta). Los datos siguen siendo ficticios.

| Archivo | Cambio | Filas nuevas esperadas |
|---|---|---|
| `01` a `05` y `08` | Sin cambios (copias idénticas) | 6, 33, 15, 10, 30 y 9.604 |
| `06-articulos.xlsx` | 8 artículos nuevos con «Requiere lote» = Sí: `LAC-023` a `LAC-027`, `BEB-024`, `VIV-047` y `VIV-048` (yogures, queso fresco, leche deslactosada, crema agria, jugo refrigerado y pan de molde) | 161 |
| `07-existencias-iniciales.xlsx` | Cantidades para unos **15 días de venta** (según los últimos 90 días de la plantilla 08; mínimo 12, en múltiplos de 6, nunca por debajo de la cantidad anterior; 113 de 153 artículos suben, de 8.329 a 12.656 unidades); `LAC-020` (huevos, cartón de 30) queda con **2** a propósito para mostrar el faltante (422 `EXISTENCIA_INSUFICIENTE`); 14 filas con **lote** para los 8 artículos nuevos | 167 |
| `T4-vencimientos-lotes.csv` | Hoja de trabajo: los mismos 14 lotes con su vencimiento (no es una plantilla y no se importa) | No aplica |

**Por qué hay artículos nuevos con lote.** Las facturas históricas (08) no traen lote y se emiten igual que una venta: el disparador 51307
rechazaría la factura de un artículo con «Requiere lote» sin lote. Por eso ningún artículo de 08 se marca con lote. Las facturas
históricas **no mueven inventario**, así que no necesitan existencias y el orden de 07 y 08 no importa para los negativos.

**Dependencia de T4 y de UX-118-01: vencimiento del lote.** La plantilla «Existencias iniciales» ya tiene la columna **Lote**
(`Importaciones.cs`, definición `ExistenciasIniciales`), pero **no la de vencimiento**. Hoy ningún camino escribe `inv.Lote.FechaVencimiento`:
`ConsultasInventario.LoteDeArticulo` inserta solo el artículo y el código. Una columna desconocida hace que se rechace el archivo completo
(`PlantillasImportacion.Leer`), así que **no se agregó**. Falta:
- en la plantilla «Existencias iniciales», una columna **«Vence»** (fecha, opcional; campo sugerido `Vencimiento`), que fije el vencimiento al
  crear el lote; está pendiente de la firma de UX-118-01 (campo «Vence» en la entrada, la factura de compra, el ajuste y la plantilla) y se
  construye con T4;
- su regla para un lote que ya existe con otro vencimiento (error de fila o aviso), que se define en T4.

Mientras tanto, los lotes se cargan **sin vencimiento**: se venden todos y los casos de lote vencido o por vencer todavía no se pueden mostrar.
Cuando exista la columna, se pasa la columna `Vence` del CSV a la plantilla 07.

**Fechas.** La plantilla no admite fechas relativas. Los lotes normales llevan una fecha fija de julio a diciembre de 2027 (más larga que la
vida real de un yogur, para que el DEMO dure). Los cuatro casos de demostración solo tienen sentido respecto del día de la demostración, por lo
que el CSV da los días desde la instalación (`VenceDiasDesdeInstalacion`). Quien arme el paquete con T4 calcula la fecha:

| Artículo | Lote | Cantidad | Vence | Caso |
|---|---|---:|---|---|
| `LAC-023` Yogur de vainilla | `YV-260901` | 6 | instalación − 5 días | Vencido: la venta lo rechaza (`LOTE_VENCIDO`) y se da de baja con merma o ajuste |
| `LAC-024` Yogur de piña | `YP-260903` | 6 | día de la instalación | Vence hoy: **se vende** (PQ-2) |
| `LAC-025` Queso blanco fresco | `QB-260920` | 8 | instalación + 3 días | Vence pronto: es el lote sugerido |
| `VIV-047` Pan de molde blanco | `PB-260929` | 15 | instalación + 5 días | Vence pronto: es el lote sugerido |

Cada uno de estos artículos tiene otro lote normal, para que se vea la lista de lotes disponibles. Si la demostración se hace días
después de instalar, «vence hoy» ya estará vencido: se corrige con un ajuste o reinstalando.

**Cómo se cargan.** Igual que antes (sección 1 del `LEEME.md` del paquete): 01 a 08 en orden, por **Administración > Herramientas >
Importaciones**, con «Agregar y actualizar». Validado el 2026-10-10 sobre `feature/modelo-ng` `109aae0` con
`ImplantacionDemoTests` (`GPOST_DEMO_DATOS` apuntando a `datos-demo-lotes`). Resultado: 161 artículos, 167 existencias en una entrada del 01/10/2026,
14 lotes y 9.604 facturas, sin errores ni avisos. La prueba sigue pasando con el juego del 2026-10-07: ahora toma de los archivos las cifras
de artículos y existencias.

**Antes de T4, con el código de hoy**, los 8 artículos con lote se importan, pero no se pueden vender en el POS: la pantalla no pide el lote
y el disparador 51307 rechaza la venta. Por eso este juego espera al paquete con T4.
