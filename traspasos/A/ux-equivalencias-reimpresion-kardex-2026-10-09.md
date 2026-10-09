# [Diseño UX/UI] Equivalencias de Unidades, Reimpresión de Comprobantes, Unidad Base en Kárdex y Existencias, y Conteo con Unidad por Línea

- **Fecha:** 2026-10-09 · **Autor:** disenador-ux-ui (equipo A) · **Estado:** propuesta; las decisiones **UX-n** quedan **Pendientes de firma** del propietario.
- **Código leído (solo lectura):** `GPOS-NG-numeracion`, HEAD `7302d9d`. No se editó nada en ese árbol.
- **Fuentes:** `diseno-factor-unidad-kardex-2026-10-08.md` (secciones 2.2, 5.3, 6.1 y 12), `respuestas-ve01-ve02-2026-10-08.md` (VE-01, F-1 a F-5 firmadas el 2026-10-08).
- **Convención de títulos:** títulos de menú, pantalla, pestaña y diálogo con mayúsculas de título (RG-30); etiquetas y mensajes en oración normal, como hoy.

---

## 0. Resumen

| Pieza | Dónde vive | Componentes que reutiliza | Lo nuevo |
|---|---|---|---|
| 1. Equivalencias | Ficha del artículo, pestaña nueva **«Unidades»** (Web `Pages/Tablas/Articulos.razor`, MAUI `Pages/Tablas/Articulos.razor`) + Importaciones (grupo Maestros) | `MudSimpleTable` con `tabla-lineas` (como Precios y Almacenes, `Articulos.razor:164-204`), `SelectorCatalogo`, `ConfirmarAsync`, `EjecutarAsync`, `ImportacionesPage` | Diálogo «Nueva Equivalencia» para R7, candado de factor, columna de códigos por unidad |
| 2. Reimpresión | `BotonImprimir`, `BotonCompartir` y los accesos directos que llaman a `gpos.imprimirDirecto` | `DialogoAutorizacionSupervisor` (ADR-68) con dos parámetros nuevos | Manejo del 422 en el cliente, acción «Imprimir otra vez», marca «COPIA n» |
| 3. R6 | `Pages/Inventario/Existencias.razor` (tabla y panel de kárdex) y chip de existencia de la ficha | `MudTable`, `MudSimpleTable`, `MudTooltip` | Rótulos de unidad base, columna «Origen» con unidad y cantidad del documento |
| 4. Conteo | `Pages/Inventario/ConteoFisico.razor` | Captura por código (`EntradaCodigo.Interpretar`), `MudNumericField` | Selector de unidad por línea, desglose «cajas + sueltas», columna «En unidad base» |

Esfuerzo de interfaz adicional que este diseño agrega a las estimaciones vigentes (inferido, ±40 %): equivalencias ya está en las 3 + 2 sp de 12.4; reimpresión +0,1 sp sobre la estimación de VE-01 por el cambio en `gpos.js`; R6 ≈ 0,3 sp (API + Web + MAUI); conteo ≈ 0,5 sp (selector, desglose, lector por unidad).

---

## 1. Objetivo y usuarios

| Pieza | Usuario | Dispositivo | Frecuencia | Tiempo objetivo |
|---|---|---|---|---|
| Equivalencias | Encargado de compras o de maestros, en la **central** | PC con teclado y lector | Baja (alta de artículos, cambios de empaque) | Agregar una unidad con factor y código: ≤ 30 s |
| Reimpresión | Cajero (sin privilegio), supervisor, contador | POS táctil o PC; MAUI en caja | Media en caja | Copia con privilegio: 1 clic, ≤ 3 s. Con supervisor: ≤ 25 s incluido el motivo |
| R6 | Encargado de inventario, auditor | PC | Diaria | Saber en qué unidad está una cifra sin abrir otra pantalla: 0 clics |
| Conteo | Contador de almacén | PC o tableta MAUI con lector | Periódica, cientos de líneas | Una lectura de código: ≤ 1 s; capturar «2 cajas y 5 sueltas»: ≤ 5 s |

---

## 2. Pieza 1: Tabla de Equivalencias de Unidades por Artículo (tanda 3)

### 2.1 Dónde vive y por qué

- **Pestaña «Unidades»** en la ficha del artículo, entre «General» y «Precios». Deshabilitada para servicios, como «Almacenes» (`Articulos.razor:184`).
- Los tres selectores de «Unidad de venta / compra / reporte» de la pestaña General (`Articulos.razor:106-108`) **se mudan** a la pestaña Unidades como columnas de selección («Venta», «Compra», «Reporte»). Así no se puede elegir como unidad de venta una unidad sin equivalencia. **(UX-1)**
  - *Alternativa descartada:* dejarlos en General y filtrar su catálogo por las unidades del artículo. Duplica el lugar de la verdad y obliga a guardar en dos pasos al dar de alta una unidad nueva y hacerla de venta.
- En la pestaña «Precios», el selector de unidad de la lista de precios (`Articulos.razor:174`) se limita a las unidades **habilitadas** del artículo.
- **Solo en la central** (`ArticuloUnidad` es `ISoloCentral`, 12.3). En un nodo de sucursal la pestaña es de solo consulta, con el aviso existente de `REQUIERE_CENTRAL` (`VistaOla4.cs:260`).

### 2.2 Wireframe (Web; MAUI usa la misma tabla con filas de 48 px)

```
┌ Ficha del artículo ─────────────────────────────────────────────────────────────────────┐
│ ←  Agua Mineral 500 ml  [AG500]  [Existencia 1,284.00 UND]          [Eliminar] [Guardar] │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│ General │ ▸Unidades │ Clasificaciones │ Precios │ Almacenes                               │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│ Unidad base: UND · Unidad  🔒                                     [+ Agregar Unidad] [⋮] │
│ Todas las existencias, el kárdex y los costos se expresan en la unidad base.            │
│                                                                                          │
│ Unidad        │ Factor (en UND) │ Venta │ Compra │ Reporte │ Códigos de barras │ Precio 1 │ Estado │   │
│───────────────┼─────────────────┼───────┼────────┼─────────┼───────────────────┼──────────┼────────┼───│
│ UND Unidad ★  │ 1          🔒   │  (•)  │  ( )   │  (•)    │ 7460001000012 +1  │   25.00  │ Base   │   │
│ CJ  Caja      │ 12         🔒   │  ( )  │  (•)   │  ( )    │ 17460001000019    │ ≈300.00ᵈ │ En uso │ ⋮ │
│ PQ6 Paquete 6 │ [ 6        ]    │  ( )  │  ( )   │  ( )    │ — [+ código]      │ ≈150.00ᵈ │ Nueva  │ ⋮ │
│ CJ24 Caja 24  │ 24         🔒   │  ( )  │  ( )   │  ( )    │ —                 │   —      │ Inhabilitada │ ⋮ │
│                                                                                          │
│ ★ unidad base (factor 1)   🔒 factor fijo: unidad usada en documentos   ᵈ precio derivado │
│ [ ] Mostrar inhabilitadas                                                                │
└──────────────────────────────────────────────────────────────────────────────────────────┘
Menú ⋮ de la fila: Editar códigos de barras · Nueva equivalencia con otro factor · Inhabilitar / Habilitar · Eliminar (solo sin referencias)
Menú ⋮ general: Cambiar unidad base (solo sin movimientos) · Importar equivalencias (abre Importaciones › Equivalencias)
```

### 2.3 Campos y reglas visibles

| Campo | Control | Regla visible | Error del servidor |
|---|---|---|---|
| Unidad | `SelectorCatalogo Catalogo.Unidades`; en filas guardadas, texto fijo | No se repite una unidad en el artículo | Duplicada: «La unidad CJ ya está en el artículo.» |
| Factor | `MudNumericField` decimal, 6 decimales máx., `Min` > 0 | Ayuda: «Cuántas UND contiene 1 CJ». Unidad base: 1, siempre de solo lectura (★) | **51384**: «La unidad base tiene factor 1.» |
| Factor en uso | Texto con 🔒 y `MudTooltip` | «Esta unidad ya se usó en documentos: su factor no cambia. Para otra equivalencia, cree una unidad nueva.» Con nodos activos sin uso local: «Hay sucursales activas que pueden haberla usado sin conexión: el factor no cambia.» | **51383** (si el candado no se mostró por datos desactualizados) |
| Venta / Compra / Reporte | `MudRadio` por columna | Solo unidades habilitadas | **51387**: «No se inhabilita la unidad base ni una unidad por omisión de venta, compra o reporte.» |
| Códigos de barras | Chips; «+n» si hay más de uno; clic abre «Códigos de Barras por Unidad» | Un código pertenece a una sola unidad del artículo | Código usado en otro artículo: el mensaje de hoy del alta |
| Precio 1 | Solo lectura | Si la unidad no tiene precio propio en la lista: **precio base × factor**, con «ᵈ» y tooltip «Derivado: 25.00 × 12. Defina un precio propio en la pestaña Precios.» | — |
| Estado | Chip | Base · En uso · Nueva · Inhabilitada | — |

- **Inhabilitar en lugar de borrar.** «Eliminar» solo aparece si la unidad no tiene referencias (memoria del propietario: eliminar solo sin referencias). Si el servidor responde con la FK (547 traducido), el mensaje es «La unidad tiene documentos, precios o códigos: inhabilítela.» con la acción **[Inhabilitar]** en la misma alerta.
- **Cambiar unidad base:** solo habilitado si el artículo no tiene movimientos ni documentos. Si los tiene, la opción se ve deshabilitada con el texto de **51385**: «La unidad base de un artículo con movimientos no cambia: cree un artículo nuevo.»
- **Guardar:** con el botón «Guardar» de la ficha, como Precios y Almacenes (un solo guardado). Un error de regla en una fila la marca en rojo, pone el foco en ella y muestra el mensaje en la alerta superior.

### 2.4 Diálogo «Nueva Equivalencia» (R7: otra equivalencia = unidad nueva)

Se abre desde «⋮ › Nueva equivalencia con otro factor» o al intentar escribir en un factor con 🔒.

```
┌ Nueva Equivalencia para AG500 ──────────────────────────────────────┐
│ La unidad CJ (12 UND) ya se usó en documentos y su factor no cambia. │
│ Cree una unidad nueva para el empaque distinto.                      │
│                                                                      │
│ Unidad nueva  [CJ24 · Caja de 24      ▾]  [+ Crear en el catálogo]   │
│ Factor        [24        ] UND                                       │
│ [x] Mover los códigos de barras de CJ a la unidad nueva              │
│ [x] Inhabilitar CJ al guardar                                        │
│ [ ] Hacerla unidad de compra por omisión                             │
│                                                                      │
│ Resultado: 1 CJ24 = 24 UND. CJ queda para los documentos históricos. │
│                                           [Cancelar] [Crear Unidad]  │
└──────────────────────────────────────────────────────────────────────┘
```

- «+ Crear en el catálogo» solo si el usuario tiene permiso de Agregar en el catálogo de Unidades; si no, el texto «Pida al administrador la unidad en Tablas › Unidades».
- Las marcas por omisión (mover códigos, inhabilitar la anterior) son **UX-3**.

### 2.5 Importación por plantilla

- En `Admin › Importaciones`, grupo **Maestros**, entrada **«Equivalencias de Unidades»**, con los pasos de hoy (`ImportacionesPage.razor:40-42`): descargar plantilla, validar sin guardar, importar.
- Plantilla, hoja «Datos»: `Artículo · Unidad · Factor · Código de barras (opcional) · Inhabilitada (S/N, opcional)`.
- Resultado de la validación, por fila:

```
Fila │ Artículo │ Unidad │ Factor │ Resultado
  2  │ AG500    │ CJ     │ 12     │ Sin cambio
  3  │ AG500    │ PQ6    │ 6      │ Nueva
  4  │ AG500    │ CJ     │ 24     │ ✖ 51383 La unidad CJ ya se usó: su factor no cambia. Use otra unidad (p. ej. CJ24).
  5  │ AG500    │ UND    │ 2      │ ✖ 51384 La unidad base tiene factor 1.
  6  │ XX999    │ CJ     │ 12     │ ✖ El artículo no existe.
Resumen: 1 nueva · 1 sin cambio · 3 con error. [Descargar errores] [Importar las válidas]
```

- **UX-4:** la importación **solo crea** unidades y códigos; no cambia factores, ni siquiera de unidades sin uso. Recomendado: el cambio de factor solo por la ficha, donde el usuario ve el candado.

### 2.6 Estados

| Estado | Qué ve el usuario |
|---|---|
| Carga | `MudProgressLinear` sobre la tabla (patrón `Loading="Ocupado"`) |
| Vacío (artículo nuevo) | Una sola fila con la unidad base elegida (por omisión UND), factor 1 fijo, y el texto «Agregue cajas, paquetes u otras presentaciones con su factor.» |
| Error de regla | Fila marcada, foco en el campo, mensaje del servidor (51383/51384/51385/51387) en la alerta superior |
| Concurrencia (409 `REGISTRO_MODIFICADO`) | El mensaje de hoy, con «Recargar» |
| Sin permisos | Sin Modificar en Artículos: tabla de solo lectura y chip «Solo consulta» (`Articulos.razor:66`) |
| Nodo de sucursal | Solo lectura con alerta Info «Solo en la central: esta sucursal consulta las equivalencias, pero no las cambia.» |
| Sin conexión | Web: la reconexión estándar de Blazor; MAUI: alerta «No hay conexión con el servidor. Sus cambios siguen en pantalla; pulse Guardar al volver la conexión.» Nada se guarda a medias (un solo POST) |

---

## 3. Pieza 2: Reimpresión de Comprobantes (VE-01, F-1 a F-5)

### 3.1 Hallazgos en el código que condicionan el diseño (verificados)

1. `gpos.imprimirDirecto` (`src/GPOS.Web/wwwroot/js/gpos.js:465-489`) hace el `fetch` en JavaScript y, ante cualquier respuesta no PDF, **abre una ventana con la URL** (`:477`). Un 422 se vería como página de error del navegador. El cliente debe devolver el estado y el código del ProblemDetails a Blazor para abrir el diálogo.
2. MAUI `DialogoVentasPos.razor:89` llama a `gpos.imprimirDirecto` directamente, sin `BotonImprimir`. Debe pasar por el mismo camino central.
3. `BotonCompartir` (PDF, correo, compartir) y «Vista previa» también piden el PDF: por F-4 cuentan como reimpresión.
4. `DialogoAutorizacionSupervisor` tiene el texto de botón fijo «Autorizar y guardar» (`VistaAutorizacionSupervisor.cs`, `TextoBoton`) y su explicación habla del «privilegio Autorizar en {opción}». Sirve tal cual con dos parámetros nuevos.

### 3.2 Flujo

```
[Imprimir] ─GET─► 200 PDF ───────────────► imprime (original 'O' o copia 'R' con privilegio propio)
     │
     ├─► 422 AUTORIZACION_REIMPRESION_REQUERIDA ─► Diálogo «Autorización: Reimpresión de Comprobante»
     │                                               ├─ Autorizar e imprimir ─POST /api/impresion/reimpresion─► 200 PDF «COPIA n» ─► imprime
     │                                               ├─ 422 AUTORIZACION_INVALIDA ─► se queda en el diálogo (patrón ADR-68)
     │                                               └─ Cancelar ─► nada se cuenta
     ├─► 403 / 404 ─► mensaje de siempre
     └─► Falla de la impresora (el PDF llegó) ─► aviso con [Imprimir otra vez] (GET ?reintento=true) y [Abrir PDF]
                                                   └─ 3.er intento o fuera de 10 min ─► el servidor responde 422 ─► diálogo
```

### 3.3 Botón (pantallas que imprimen un comprobante fiscal)

Facturación Ágil (`PuntoVenta.razor:261`, Web y MAUI), Ventas del POS (MAUI `DialogoVentasPos.razor:38`; Web si lo tiene), `DialogoDetalleFactura`, `DocumentoPage` (facturas de crédito) y `NotasCxc`. No cambian: Recibos, Caja chica, Pagos, Solicitudes, Cheques devueltos, Conteo y documentos de inventario (sin NCF: libres, F-2).

- El botón mantiene su forma (`MudButtonGroup` con menú). **UX-5:** si el documento ya se imprimió, el texto pasa de «Imprimir» a «Reimprimir» y aparece un chip «Impreso 2 veces». Necesita el dato del contrato (sección 7). Sin el dato, el botón queda como hoy y el servidor decide.
- El tooltip del ícono en la lista de ventas del POS ya dice «Reimprimir ticket»: se mantiene.

### 3.4 Diálogo del 422 (reutiliza `DialogoAutorizacionSupervisor`)

```
┌ Autorización: Reimpresión de Comprobante ─────────────────────────────┐
│ ⚠ Este comprobante ya se imprimió. Para imprimir una copia se requiere │
│   el privilegio "Reimprimir comprobantes fiscales" o la autorización   │
│   de un supervisor.                                     (texto del 422)│
│ Ticket FC00001234 · B0200000123 · RD$ 1,850.00 · se imprimirá COPIA 2  │
│                                                                        │
│ Un supervisor con el privilegio «Reimprimir comprobantes fiscales»     │
│ escribe su usuario y su contraseña. Quedará registrado como quien      │
│ autoriza, con el motivo.                                               │
│ Usuario supervisor   [__________]                                      │
│ Contraseña           [__________]                                      │
│ Motivo *             [__________________________________] 0/200        │
│   (Cliente perdió el original) (Papel dañado) (Copia para contabilidad)│
│                                        [Cancelar] [Autorizar e Imprimir]│
└────────────────────────────────────────────────────────────────────────┘
```

- **Solo la forma supervisor** (`PuedeAutorizarSolo = false`): quien tiene el privilegio nunca recibe el 422 (F-5: con privilegio propio no hay diálogo ni motivo).
- Parámetros nuevos del componente (aditivos): `TextoBoton` (por omisión el de hoy) y `Encabezado` (tipo, número, NCF, total y «COPIA n»). La explicación usa `NombreOpcion("reimprimircomprobante")`.
- **Motivo obligatorio** (F-5). Las fichas de motivo rápido solo **rellenan** el texto, editable. **UX-6:** ¿se ofrecen esas tres fichas o solo texto libre?
- La contraseña se borra al responder, como hoy. Enter en el motivo = Autorizar; Esc = Cancelar.

### 3.5 Falla de la impresora: [Imprimir otra vez]

El aviso de hoy («No se pudo imprimir directo…» con «Abrir PDF», `gpos.js:486-487`) cambia a:

```
⚠ No se pudo imprimir en EPSON-TM20: el agente de impresión no respondió.
   [Imprimir otra vez]  [Abrir PDF]            Reintento 1 de 2 · hasta las 14:42
```

- **[Imprimir otra vez]** = GET con `reintento=true`: sin marca COPIA, sin diálogo, línea de bitácora «Reintento de impresión n».
- **[Abrir PDF]** abre el PDF **ya descargado** en memoria (no hace otra petición), así no cuenta como reimpresión.
- Tras el 2.º reintento, o pasados 10 minutos, el botón cambia a «Reimprimir (requiere autorización)» y sigue el flujo del 422.
- El contador visible es una ayuda; el servidor manda (F-3).

### 3.6 Marca «COPIA n» en el documento (RO-54)

| Papel | Dónde | Texto |
|---|---|---|
| Rollo 80 y 58 mm | Línea centrada, en negrita, **antes** del encabezado fiscal (fuera del bloque NCF) | `*** COPIA 2 ***` |
| Carta | Banda en la esquina superior derecha, sobre el título | `COPIA 2` |
| Pie (todos) | Última línea, fuera del cuerpo fiscal | `Reimpreso el 09/10/2026 14:32` |

- Sin marca: el original (`'O'`), el reintento (`'F'`) y la RI automática de VF-13 (`'A'`).
- **UX-7:** ¿marca de agua diagonal «COPIA» en Carta además de la banda? ¿El pie nombra al usuario que reimprimió? Recomendación: banda sí, marca de agua no (dificulta leer el detalle impreso en láser), pie sin usuario (ya está en la bitácora).
- El diseñador de formatos debe exponer el campo «Copia» para los formatos personalizados (entrega a desarrollador-frontend).

### 3.7 Estados

| Estado | Qué ve el usuario |
|---|---|
| Carga | El botón queda deshabilitado con indicador mientras llega el PDF |
| Sin permisos (403) | El mensaje de hoy |
| Autorización rechazada | Error en el diálogo, que sigue abierto |
| Sin conexión | «No se pudo obtener el documento para imprimirlo.» (texto de hoy); nada se cuenta |
| Documento sin NCF | Imprime siempre, sin diálogo ni marca |

---

## 4. Pieza 3: R6, Unidad Base en Kárdex y Existencias

### 4.1 Existencias (`Existencias.razor:41-70`)

```
Código │ Descripción        │ Categoría │ Almacén │ Unidad │ Existencia │ Mínimo │ Máximo │ Costo/UND │ Valor │ 🧾
AG500  │ Agua Mineral 500ml │ Bebidas   │ PRIN    │ UND    │  1,284.00  │ 240.00 │ ...    │ 18.50     │ ...   │ 🧾
Leyenda bajo la tabla: «Existencia, mínimo y máximo en la unidad base de cada artículo.»
```

- Columna nueva **«Unidad»** (la base). Encabezado del costo: «Costo por unidad base». Tooltip en «Existencia»: «En la unidad base del artículo».
- **UX-8:** ¿columna opcional «En unidad de reporte» (p. ej. «107 CJ»)? Recomendación: no en esta tanda; solo si el propietario la pide.

### 4.2 Kárdex (panel en `Existencias.razor:72-96`)

```
┌ Kárdex · AG500 Agua Mineral 500 ml (PRIN) · cantidades en UND (unidad base) ──────────────── ✕ ┐
│ Fecha      │ Documento │ Número     │ Origen del documento   │ Entrada │ Salida │ Costo/UND │ Saldo │
│ 01/10/2026 │ FCP       │ CP00000045 │ 10 CJ × 12             │  120.00 │        │  18.50    │ 1,320 │
│ 02/10/2026 │ FPOS      │ FC00001234 │ 2 CJ × 12              │         │  24.00 │  18.50    │ 1,296 │
│ 03/10/2026 │ FPOS      │ FC00001240 │ 12 UND                 │         │  12.00 │  18.50    │ 1,284 │
│ 05/10/2026 │ CON       │ CF00000007 │ Contado en CJ (× 12)   │    4.00 │        │  18.50    │ 1,288 │
│ 20/09/2026 │ AJU       │ AJ00000002 │ —                      │         │   3.00 │  18.50    │ 1,291 │
└───────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Caso (columnas R1 de `inv.Movimiento`) | Columna «Origen del documento» |
|---|---|
| `UnidadId`, `FactorUnidad`, `CantidadOrigen` con valor y factor ≠ 1 | `10 CJ × 12` (tooltip «10 CJ de 12 UND = 120 UND») |
| Unidad base (factor 1) | `12 UND` |
| Conteo: unidad y factor sin `CantidadOrigen` (2.2/3 del blueprint) | `Contado en CJ (× 12)` |
| Las tres NULL (historia, traslados) | `—` con tooltip «Movimiento anterior al registro de la unidad o sin unidad de documento» |

- El título del panel lleva siempre «cantidades en {unidad base} (unidad base)». La ficha del artículo muestra el chip «Existencia 1,284.00 UND».

### 4.3 Estados

Carga: indicador de la tabla. Vacío: «Sin movimientos en los últimos 3 meses.» (hoy la tabla queda vacía sin texto). Sin conexión: mensaje estándar de `CargarAsync`. Sin permisos de costos: se ocultan Costo y Valor, como hoy (`VerCostos`).

---

## 5. Pieza 4: Conteo Físico con Unidad por Línea

### 5.1 Restricción de datos que manda en el diseño

`UX_ConteoLinea_Articulo (DocumentoId, ArticuloId, LoteId)`: **una línea y una unidad por artículo y lote** (blueprint 2.2). La unidad no cambia después de capturar ni tras el corte (**51386**). Por eso «cajas y sueltas en la misma hoja» se resuelve en la **captura**, no con dos líneas.

### 5.2 Wireframe

```
┌ Conteo Físico [CF00000008] [Pendiente de aplicar] ───────────── [Guardar sin aplicar] [Aplicar conteo] ┐
│ Agregar artículo [3+17460001000019______] 🔍   Enter suma 1 en la unidad del código · 3+código suma 3   │
│ ✓ +1 CJ = +12 UND · AG500                                                                               │
│                                                                                                          │
│ Código │ Descripción      │ Unidad      │ Sistema (UND) │ Contado        │ En UND │ Diferencia (UND) │   │
│ AG500  │ Agua 500 ml      │ [UND ▾]     │   1,284.00    │ [1,279] [⊞]    │ 1,279  │ −5.00            │ 🗑 │
│ GL001  │ Galletas surtid. │ CJ ×24 🔒   │     480.00    │ 20             │   480  │  0.00            │   │
│ LE001  │ Leche 1 L        │ [UND ▾]     │      36.00    │ 37             │    37  │ +1.00            │ 🗑 │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
⊞ = desglose por presentaciones (abre la ventana de abajo)
```

### 5.3 Cómo se elige la unidad

- La hoja **propone la unidad base** (blueprint 6.1; `LineaConteoDto.Unidad`, `Inventario.cs:70`). **UX-9:** ¿proponer en cambio la unidad de reporte del artículo, si existe? Recomendación: base, porque admite mezclar cajas y sueltas sin fracciones.
- **Selector por línea** con las unidades habilitadas del artículo («UND · CJ ×12 · PQ6 ×6»). Se puede cambiar mientras la línea no esté guardada con captura; después se muestra fija con 🔒 y el tooltip de 51386: «La unidad de la línea no cambia después de capturar o del corte.»
- **Al cambiar la unidad antes de guardar**, lo contado se convierte: 2 CJ → 24 UND (exacto hacia la base). Hacia una unidad mayor solo si el resultado es exacto; si no, se impide con «24 UND no son un número entero de PQ6 ×6… use la unidad base o el desglose.»

### 5.4 Cajas y sueltas en la misma hoja: desglose

```
┌ Contado de AG500 · Agua 500 ml ─────────────────┐
│ CJ  (× 12)   [ 106 ]  = 1,272 UND               │
│ PQ6 (× 6)    [   1 ]  =     6 UND               │
│ UND (× 1)    [   1 ]  =     1 UND               │
│ ─────────────────────────────────────────────── │
│ Total contado                     1,279 UND     │
│ Sistema 1,284 UND · Diferencia −5 UND           │
│                        [Cancelar] [Aceptar ↵]   │
└─────────────────────────────────────────────────┘
```

- Solo para líneas en la **unidad base**. El total va a `Contado` en la unidad de la línea; la diferencia la calcula el motor en base (`Diferencia`, PERSISTED).
- **UX-10:** el desglose **no se guarda** (no hay dónde en `inv.ConteoLinea`); queda solo el total en base. Si el propietario quiere conservarlo (para reimprimir la hoja con «106 CJ + 1 PQ6 + 1 UND»), hace falta un cambio de datos (entrega a arquitecto-datos). Recomendación: no guardarlo.

### 5.5 Lector de código de barras

| Línea en | Se lee el código de | Resultado |
|---|---|---|
| UND (base) | CJ | Suma 12 a lo contado; aviso «+1 CJ = +12 UND» |
| CJ | CJ | Suma 1 |
| CJ | UND | Si la línea no está guardada: ofrece «Pasar la línea a UND (24 UND + 1)» con Enter. Si está fija: aviso de error «Esta línea se cuenta en CJ; cuente las sueltas en otra hoja o anule y rehaga la línea.» y sonido de error |
| Artículo nuevo en la hoja | Cualquiera | La línea nace en la **unidad base** y suma el factor del código leído |

- «3+código» multiplica en la unidad del código (3 cajas = 36 UND).

### 5.6 Cómo se ve la diferencia

- Columnas «Sistema (UND)», «En UND» y «Diferencia (UND)»: el rótulo de la unidad base va en el encabezado si todas las líneas comparten la misma base; si no, el número lleva la unidad: `−5 UND`, `+0.5 KG`.
- Color: rojo faltante, verde sobrante (como hoy, `ConteoFisico.razor:130`) **más el signo** explícito (no depender solo del color).
- La confirmación de «Aplicar conteo» dice: «Se ajustarán 2 artículo(s). Las diferencias se registran en la unidad base de cada artículo.»
- La hoja impresa del conteo agrega la columna «Unidad».

### 5.7 Estados

| Estado | Qué ve el usuario |
|---|---|
| Vacío | «Agregue artículos con el lector o cárguelos por clasificación.» |
| Error 51386 | Alerta en la línea con el texto del servidor; la unidad vuelve a la guardada |
| Sin conexión | MAUI: «No hay conexión. Lo contado sigue en pantalla; pulse Guardar sin aplicar al volver.» No se pierde lo capturado mientras la página siga abierta |
| Sin permisos | El aviso de hoy (`ConteoFisico.razor:13`) |
| Aplicado o anulado | Todo de solo lectura; la unidad se muestra como texto |

---

## 6. Accesibilidad y teclado (las cuatro piezas)

| Pantalla | Teclas | Accesibilidad |
|---|---|---|
| Unidades | `Alt+U` abre la pestaña; `Insert` agrega fila; `Tab` recorre Unidad → Factor → radios; `Supr` en fila nueva la quita; `F2` abre códigos de la fila | Candado con `aria-label="Factor fijo: unidad usada en documentos"`; radios con `aria-label="Unidad de venta por omisión: CJ"` |
| Diálogo de reimpresión | Foco inicial en «Usuario supervisor»; `Enter` en el motivo = Autorizar; `Esc` = Cancelar | Mensaje con `role="alert"`; contador del motivo leído por el lector de pantalla |
| Aviso de impresora | `Alt+I` = Imprimir otra vez | Aviso en región `aria-live="polite"` |
| Kárdex y existencias | `F3` busca artículo (como hoy) | Encabezados con la unidad en texto, no solo en tooltip |
| Conteo | Lector y `Enter` como hoy; `F4` abre el desglose de la línea enfocada; `Alt+↓` abre el selector de unidad | Diferencia con signo y color (no solo color); objetivos táctiles de 48 px en MAUI |

Contraste AA en los chips de estado (usar `Color.Default`/`Warning` de la paleta actual, no gris sobre gris).

---

## 7. Datos requeridos de la API

### 7.1 Existentes (verificados)

- `ArticuloDto.UnidadVenta`, `UnidadCompra`, `UnidadInforme`, `Precios[].IdUnidad`, `CodigoBarras`, `Version` (`GPOS.Contracts/Tablas/Maestros.cs:140-190`).
- `LineaConteoDto.Unidad`, `FactorUnidad`, `Existencia` (base), `Contado`, `Diferencia` (`GPOS.Contracts/Inventario/Inventario.cs:66-82`).
- `AutorizacionSupervisor`, `CodigosDocumento.AutorizacionInvalida`, `CodigosSitio.RequiereCentral`.

### 7.2 Faltantes (para arquitecto-software)

| Pantalla | Dato | Uso |
|---|---|---|
| Unidades | `ArticuloDto.UnidadBase` | No existe en el contrato (verificado). Cabecera, ★, rótulos |
| Unidades | `ArticuloDto.Unidades[]`: `Unidad`, `Descripcion`, `Factor`, `Inhabilitada`, **`EnUso`** (bool), `Codigos[]`, `PrecioDerivado` | Tabla, candado proactivo, «Eliminar» solo sin referencias |
| Unidades | `FactorBloqueadoPorNodos` (bool, empresa) | Texto del candado cuando el motivo son las sucursales activas (51383) |
| Unidades | Códigos de regla 51383/51384/51385/51387/51388 traducidos a 422 con `CodigoRegla` y la unidad afectada | Marcar la fila |
| Importación | Definición «Equivalencias de Unidades» en `Importaciones.Todas` con validación por fila | 2.5 |
| Reimpresión | Estado y código del ProblemDetails devueltos por `gpos.imprimirDirecto` y `BotonCompartir` a Blazor; variante POST del cliente para `/api/impresion/reimpresion` | 3.2 |
| Reimpresión | `Impresiones` (cantidad) y `Fiscal` (bool) en las vistas de documento y en las filas de ventas del POS | UX-5 y la línea «se imprimirá COPIA n» |
| Reimpresión | Reintentos restantes y hora límite en la respuesta del reintento (encabezado) | «Reintento 1 de 2 · hasta las 14:42» (si no, se omite) |
| Existencias | `ExistenciaDto.UnidadBase` | Columna «Unidad» |
| Kárdex | `MovimientoInventarioDto.Unidad`, `FactorUnidad`, `CantidadOrigen` (NULL admitidos) y `UnidadBase` | Columna «Origen del documento» |
| Conteo | `ArticuloLinea` (búsqueda por código): unidad y factor **del código leído**; lista de unidades habilitadas del artículo | Lector por unidad y selector |
| Conteo | Indicador por línea «unidad fija» (hay captura o corte) | Candado 51386 |

---

## 8. Decisiones que requieren al propietario

| # | Pregunta | Recomendación |
|---|---|---|
| UX-1 | ¿Mudar «Unidad de venta / compra / reporte» de General a la pestaña Unidades? | Sí |
| UX-2 | R7 obliga a crear una unidad de catálogo por cada empaque distinto (CJ, CJ24, CJ6…). ¿Se acepta que el catálogo de Unidades crezca así, con códigos como «CJ24»? | Sí; alternativa sería unidades por artículo, que cambia el modelo de datos |
| UX-3 | En «Nueva Equivalencia», ¿mover por omisión los códigos de barras a la unidad nueva e inhabilitar la anterior? | Ambas marcadas por omisión, editables |
| UX-4 | ¿La importación solo crea, sin cambiar factores? | Sí |
| UX-5 | ¿El botón dice «Reimprimir» y muestra «Impreso n veces» cuando ya se imprimió? | Sí (requiere el dato 7.2) |
| UX-6 | ¿Motivos rápidos en el diálogo de reimpresión, o solo texto libre? | Fichas que rellenan texto editable |
| UX-7 | ¿Marca de agua «COPIA» en Carta? ¿Usuario en el pie? | Banda sí, marca de agua no, pie sin usuario |
| UX-8 | ¿Columna de existencia en la unidad de reporte? | No en esta tanda |
| UX-9 | ¿Unidad propuesta en la hoja de conteo: base o de reporte? | Base |
| UX-10 | ¿Guardar el desglose «cajas + sueltas» del conteo? | No (evita cambio de datos) |
| UX-11 | ¿«Vista previa» de un comprobante ya impreso cuenta como reimpresión (F-4 dice que el PDF sí)? | Sí, con marca COPIA; si no, la vista previa sería una vía libre de copias |

---

### Cierre
- Estado: Completado (diseño; UX-1 a UX-11 Pendientes de firma)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\ux-equivalencias-reimpresion-kardex-2026-10-09.md`
- Supuestos: Facturación Ágil = `PuntoVenta.razor` (inferido de la navegación); la API traducirá 51383-51388 a 422 con `CodigoRegla`; el conteo de la Web no usa hoy rondas de `ConteoCaptura`, así que la unidad se fija al primer guardado con cantidad (inferido); esfuerzos inferidos ±40 %
- Decisiones candidatas a ADR: ninguna nueva de arquitectura; UX-2 (catálogo de unidades por empaque) puede requerir precisión del ADR del modelo de datos si se rechaza
- Entregas a otros agentes: arquitecto-software → datos faltantes de 7.2 y el cambio de contrato de `gpos.imprimirDirecto`; arquitecto-datos → UX-10 solo si el propietario pide guardar el desglose; desarrollador-frontend → `BotonImprimir`/`BotonCompartir`/`DialogoVentasPos` por el camino central, parámetros `TextoBoton` y `Encabezado` del diálogo, campo «Copia» en el diseñador de formatos; arquitecto-maestro → llevar UX-1 a UX-11 al propietario
- Próximo paso recomendado: firmar UX-1 a UX-11 junto con F-1 a F-5 para que la tanda de núcleo de caja (reimpresión) y la tanda 3 (equivalencias) arranquen sin preguntas abiertas
