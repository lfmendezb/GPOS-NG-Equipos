# Diseño UX/UI: pantallas de transferencias de la ola 3b, tramo 1 (F10 del MVP)

- **Fecha:** 2026-10-10 · **Autor:** diseñador UX/UI del equipo B · **Estado:** Completado (diseño). Las preguntas UX-TI-01 a UX-TI-07 están **Pendientes de firma**.
- **Solo lectura:** no edité, no compilé y no ejecuté nada. Árbol de código leído: `GPOS-B-modelo-ng`, rama `feature/modelo-ng`, HEAD `b77e64e` (limpio). Las rutas `src/…` son relativas a ese árbol, y las de `docs/adr/…` son de `master` (`dc89478`).
- **Lo firmado manda:** ADR-100 a ADR-107 con sus precisiones del 2026-10-10 (P-1 a P-5: F10 sin diferencias, T-09 estricto, despacho desde una sucursal cerrada por la central, errores 51440 a 51459), ADR-118 y 119 (lote y vencimiento como una sola información, el servidor valida) y ADR-52 (vocabulario). Por debajo de eso: el plan `GPOS-NG-Equipos/traspasos/B/2026-10-10-plan-ola3b.md` («el plan»), el blueprint `docs/arquitectura/2026-10-07-ola3b-blueprint.md` ([SW3B]), el modelo de datos `docs/datos/2026-10-07-ola3b-modelo-datos.md` ([D3B]) y las reglas operativas `docs/pos/2026-10-05-transferencias-y-costos-central.md` ([TRF]), todos en la rama. Para no inventar controles, reutilizo el diseño del lote del equipo C (`origin/c/adr118-119-ux`, `docs/ux/2026-10-10-adr118-119-pantallas.md`, revisión 2, [UXL]).
- **Qué no cubre este documento:** contratos definitivos (arquitecto-software de B, tramo 0), reglas operativas nuevas (especialista-pos) ni el formato del conduce (3b-3; aquí solo defino cómo se pide y cuándo se habilita la salida).

---

## 0. Hallazgos del código que condicionan el diseño (verificado)

| # | Hecho | Evidencia | Efecto en el diseño |
|---|---|---|---|
| H1 | No existe ninguna pantalla, contrato ni permiso de transferencias | Plan 2.2; búsqueda propia en `src/GPOS.Web` | Todo es nuevo. No se rompe nada de lo que el usuario ya conoce |
| H2 | **Trampa de vocabulario:** en el menú ya existen «Conduces» (`inventario/Conduce`, entrega a cliente, serie `CO`) y «Entradas / Recepción» (recepción de suplidor) | `src/GPOS.Web/Components/Layout/NavMenu.razor:136-137`; [TRF] 0.1 | El menú **no** usa las palabras «Conduce» ni «Recepción» solas. El botón dice «Imprimir conduce» solo dentro de la transferencia, y el papel dice «CONDUCE DE TRANSFERENCIA» |
| H3 | `EditorLineas` es comercial: tiene precio, descuento, impuesto e ITBIS | `src/GPOS.Web/Components/Compartidos/EditorLineas.razor:30-49` | No sirve para el despacho. Tomo como base la tabla simple de `DocInventarioPage.razor:112-171` (código, existencia, cantidad, unidad con selector ADR-78) y su campo de lectura (`:104-110`) |
| H4 | El catálogo de almacenes no filtra por la sucursal de la sesión ni dice de qué sucursal es cada almacén | `src/GPOS.Core/Consultas/Configuracion/ConsultasConfiguracion.cs:57-63`; `AlcancesCatalogo` solo tiene `historico` y `ajuste` (`src/GPOS.Contracts/Admin/CierreSucursal.cs:39-52`) | Hacen falta dos alcances nuevos (C-1) |
| H5 | `ArticuloLinea` todavía no trae `RequiereLote` (F-1 está firmado para antes del 15-oct) | `src/GPOS.Contracts/Catalogos/Catalogo.cs:18` | Si no llega, el despacho no sabe sin otra consulta si el renglón pide lote. Dependencia D-1 |
| H6 | La Web es Blazor Server interactivo (circuito SignalR). La pérdida de la API se avisa con «No se pudo contactar el servidor de la aplicación.», y la del circuito, con `ReconnectModal` | `src/GPOS.Web/Program.cs:28,160`; `Components/App.razor:30-41`; `Compartidos/PaginaBase.cs:132-135` | «Sin conexión» tiene dos capas: navegador → servidor Web y servidor Web → API. Las lecturas no enviadas tienen que sobrevivir a las dos (sección 4) |
| H7 | Patrones que se reutilizan: `PaginaBase.EjecutarAsync` con reenvío por supervisor (Q-5), `DialogoAutorizacionSupervisor`, `DialogoAnulacion` (motivos de ADR-71), `BotonImprimir`, `SelectorCatalogo`, `VistaUnidadBase.ConUnidad`, la leyenda por renglón de `VistaRechazoUnidad` y el atajo «3+código» (`EntradaCodigo.Interpretar`) | `PaginaBase.cs:62-110`; `Compartidos/*.razor`; `EditorLineas.razor:255-259` | No se crean componentes que ya existen |
| H8 | No hay atajos de teclado globales. Solo F3 (búsqueda) en 8 lugares; [UXL] reserva **F2** para el lote | [UXL] P-1, «Teclado nuevo» | F2 = «lote o series del renglón». No agrego otra tecla de función |
| H9 | El menú no tiene contadores (insignias) | `NavMenu.razor:4-31` | Contador nuevo para «Transferencias por Recibir» (también lo pide [UXL] P-13; un solo mecanismo para los dos) |
| H10 | En MAUI, Inventario tiene las mismas 4 páginas que la Web, en copia aparte | `GPOS.UI.MAUI/Components/Pages/Inventario/` | En el tramo 1 no hay MAUI. Diseño la recepción Web sin depender del puntero para que el tramo 2 la copie (sección 3.6) |
| H11 | El motor de formatos no tiene un elemento de código de barras | Búsqueda de `Code128`/`barcode` en `src`: solo maestros e importación | El número de la transferencia no se puede escanear del papel hasta que llegue el QR del tramo 2: en el tramo 1 se digita |

---

## 1. Objetivo y usuarios

**Objetivo.** Que el despachador de la sucursal A arme una transferencia de 50 a 200 renglones (P-T12) **escaneando**, con el lote propuesto y sin ver costos. Que imprima el conduce y confirme la salida. Que el receptor de B la encuentre en «Por Recibir», la cuente escaneando (conteo ciego), la compare y la confirme. Ningún corte de red, de luz o de navegador debe perder un conteo ni duplicar una recepción.

| Usuario (perfil sembrado, [SW3B] 8.4) | Dispositivo (P-T14, P-T15) | Tarea | Tiempo objetivo (inferido, ±30 %) |
|---|---|---|---|
| Despachador de A (ALMACEN: `transfdespacho` Agregar) | PC con teclado, lector 2D e impresora carta | Agregar un renglón escaneando, con el lote sugerido | **1 lectura y 0 pulsaciones extra**; renglón visible ≤ 300 ms p95 en red local (una lectura de `ArticuloLinea` y una de lotes, memorizada por artículo y almacén, como D-02 de [UXL]) |
| Ídem | Ídem | Despacho de 200 renglones | De 8 a 12 min de lectura, más un guardado de ≤ 3 s p95 (esa cifra es del servidor y la tiene que medir B) |
| Ídem | Ídem | Imprimir el conduce y confirmar la salida | 2 clics + transportista (unas 15 pulsaciones) |
| Receptor de B (ALMACEN: `transfrecepcion` Agregar; **otro usuario**, S-02) | PC o mostrador con lector 2D | Abrir la transferencia desde «Por Recibir» | 1 clic, o el número digitado + Enter |
| Ídem | Ídem | Contar un bulto | 1 lectura; el conteo local se ve ≤ 150 ms (optimista) y el servidor lo confirma en segundo plano |
| Ídem | Ídem | Terminar, comparar y confirmar | 3 clics |
| Supervisor de almacén (SUPERVISOR_ALMACEN) | PC | Anular un despacho en tránsito (autoriza) y borrar lecturas de otro usuario | Diálogo de supervisor existente (ADR-68) |
| ADMIN / SUPER | PC | Consultar y anular, con la misma segregación (ADR-106) | — |
| Usuario de la central con `transfreconciliacion` | PC | Ver todas las transferencias («Todas») | — |

**Segregación (ADR-106, S-02):** quien despachó **no recibe**, tampoco el ADMIN ni el SUPER. La pantalla lo dice antes de que el servidor responda 403 (sección 3.2). Excepción firmada S-3b-04: el traslado dentro de la misma sucursal (modo S) es de un solo paso y basta el permiso de Despacho.

---

## 2. Flujos de interacción

### F-1. Despacho entre sucursales (modo E)
1. Menú Inventario › Transferencias › **Despacho de Transferencias**. Se abre «Despacho de Transferencia» con el chip «Nueva».
2. **Almacén de origen:** solo los de la sucursal de la sesión (S-3b-02 A). Si hay uno solo, viene elegido.
3. **Almacén de destino:** cualquier almacén activo de la empresa distinto del origen, agrupado por sucursal. Si es de **otra** sucursal, el modo es E: el botón dice «Despachar» y se muestra la línea «Entre sucursales: sale del inventario de {A} y queda en tránsito hasta que {B} lo reciba.».
4. Transportista y vehículo son opcionales aquí: si se conocen, salen impresos en el conduce. Las notas también son opcionales.
5. Renglones: se escanea o se digita el código y se pulsa Enter (F3 busca; «3+código» agrega 3). Si el artículo pide lote, se precarga el **sugerido** del almacén de origen (el que vence primero entre los no vencidos). Si no alcanza, el renglón se parte con el siguiente lote (UX-118-04, firmada). Con series, F2 abre «Números de Serie».
6. **Despachar.** Antes de enviar, la pantalla valida lo que puede (destino elegido, renglones > 0, lote en todo renglón que lo pide, series completas). Si hay lotes vencidos, abre «Lote Vencido» y pide el motivo (D3 de [TRF]).
7. El servidor responde 201 con el número `TI…`. La pantalla navega al **detalle** (F-3) y ofrece «Imprimir conduce» como acción principal.
8. Si el servidor rechaza (422), los renglones se conservan y se marcan (sección 3.7). **Nada de lo escrito se pierde.**

### F-2. Traslado entre almacenes de la misma sucursal (modo S, un solo paso)
1. Igual que F-1, pero el destino es de la **misma** sucursal. El botón cambia a «Trasladar» y la línea dice «Traslado interno: sale de {almacén A} y entra en {almacén B} en el mismo paso.».
2. No hay salida, conduce obligatorio ni recepción. La transferencia nace **Recibida**, con el chip «Traslado interno». Imprimir es opcional (UX-TI-06).
3. No se aplica S-02 (S-3b-04). El traslado aparece en el reporte de funciones incompatibles de la ola 5.

### F-3. Salida con conduce (detalle de la transferencia)
1. En el detalle de una transferencia **Despachada**, la acción principal es «Imprimir conduce». El servidor genera el PDF carta (T-21) y registra `CONDUCE_IMPRESO`. La segunda impresión y las siguientes salen como «REIMPRESIÓN n».
2. Una vez impreso, se habilita «Confirmar salida». El diálogo pide el transportista (obligatorio según UX-TI-04) y el vehículo, ya precargados con lo que se indicó en el despacho, y envía la `Version`.
3. Con éxito, el estado pasa a **En tránsito** y aparece la línea «Salida confirmada el {dd/MM/aaaa HH:mm} por {usuario} · Transportista {x} · Vehículo {y}».
4. Con `SalidaEnUnPaso = 1` (P-T1), el despacho nace En tránsito: la pantalla abre la impresión del conduce sola, justo después de despachar, y no muestra «Confirmar salida».
5. La confirmación de la salida es **opcional para recibir** ([TRF] 2.3): B puede recibir una transferencia Despachada.

### F-4. Recepción por sesión (en B)
1. Menú › **Transferencias por Recibir** (con contador). Se escanea o se digita el número `TI…` en el campo superior, o se elige un renglón de la lista y se pulsa «Recibir».
2. La pantalla llama a T-08: abre la sesión **o se une** a la que ya está abierta. Se abre «Recepción de Transferencia».
3. Se cuenta escaneando: cada lectura genera un `EscaneoId` en el cliente, suma al instante en pantalla (optimista) y se envía en tandas de hasta 200 cada 400 ms. Si el artículo viene en un solo lote en la transferencia, se toma ese lote. Si viene en varios, se pide el lote con F2, leyéndolo o eligiéndolo entre los de la transferencia (sin otros lotes).
4. Con **conteo ciego** (`ConteoCiegoRecepcion = 1` por omisión, P-T3), la pantalla muestra los artículos y sus lotes, pero no las cantidades esperadas.
5. Varias personas pueden contar a la vez: la lista se refresca con cada tanda propia y cada 15 s sin actividad, y la cabecera dice «Contando: ANA, LUIS».
6. **Terminar conteo** (T-12): aparece «Resultado del Conteo», con lo esperado, lo contado y la diferencia por renglón.
7. **Confirmar recepción** (T-13, sin diferencias en el tramo 1): entra lo contado, hasta lo pendiente de cada renglón. Lo que faltó **queda pendiente** (la transferencia sigue En tránsito, «Recibida en parte (R1)») y otra sesión puede recibirlo después (R2). Si se contó de más, ver UX-TI-03.
8. Con éxito, la pantalla navega al detalle y muestra «Recepción R{n} confirmada: {x} renglones, {y} unidades.». Una confirmación repetida (`Repetida = true`) muestra el mismo resultado, sin error.

### F-5. Anulación (en A)
- **Despachada, sin recepciones:** «Anular» → diálogo «Anular Transferencia» (motivo del catálogo de ADR-71 y texto) → 204 → estado **Anulada**. La mercancía vuelve al origen y las series vuelven a «en existencia».
- **En tránsito, sin recepciones:** además, un supervisor de A (ADR-68) y dos declaraciones obligatorias: «La mercancía está de vuelta en el almacén {A} o no salió» y «El conduce físico se recuperó o se destruyó» ([TRF] 2.5).
- **Con recepciones:** el botón «Anular» se ve deshabilitado y explica por qué: «Tiene recepciones: no se puede anular. Lo pendiente se cierra con «No llegará más» (disponible con el registro de diferencias).».

---

## 3. Pantallas

Convenciones: `[…▾]` selector; `[___]` campo; `(F2)` atajo; `⚠` aviso; `✖` error; `ⓘ` ayuda. Los textos entre comillas son **literales propuestos**.

### 3.0 Menú (Inventario)

```
Inventario
  Entradas / Recepción
  Conduces
  Ajustes de Inventario
  ▸ Transferencias
      Despacho de Transferencias          (transfdespacho, Agregar)
      Transferencias por Recibir   (3)    (transfrecepcion)
      Consulta de Transferencias          (transfdespacho | transfrecepcion | transfreconciliacion)
  Conteo Físico
  Existencias
  Cierre de Período de Inventario
```

- Es un subgrupo con `Sub("Transferencias", …)` (`NavMenu.razor:89`). No lleva `Central: true`: las rutas son `OperacionSitio.Libre` ([SW3B] 5.1).
- **Contador:** `MudBadge` con el número de `PorRecibirDto.Contador` (T-02). Se lee al iniciar la sesión y cada 60 s. Sin dato (cargando o sin conexión) **no se muestra** ningún número, para no enseñar uno viejo (como P-13 de [UXL]). `aria-label="{n} transferencias por recibir"`.
- En el tramo 1, MAUI no muestra el subgrupo (sección 3.6).
- Rutas: `inventario/transferencias` (lista), `inventario/transferencias/nueva` (despacho), `inventario/transferencias/{numero}` (detalle), `inventario/transferencias/{numero}/recepcion` (recepción) y `inventario/transferencias?vista=por-recibir`.

### 3.1 P-1 «Consulta de Transferencias» (lista, con la vista «Por Recibir»)

**Ajuste del plan:** el plan pide «Transferencias» y «Por recibir» como dos pantallas. Diseño **una sola página con tres vistas**, porque las columnas y los estados son los mismos. Se ahorra un componente (≈ 0,05 sp) y el menú entra directo en la vista que corresponde.

```
┌ Consulta de Transferencias                                      [Despacho de transferencia] ┐
│ [ Enviadas ] [ Por Recibir (3) ] [ Todas ]   ← «Todas» solo con transfreconciliacion en la central │
│ Número / código de barras [TI_________] (Enter abre)                                         │
│ Estado [Todos ▾]  Desde [10/09/2026]  Hasta [10/10/2026]  Texto [__________]  [Buscar]       │
├────────────┬────────────┬──────────────────────┬──────────────────────┬──────────────┬──────┬────────┬──────────┤
│ Número     │ Despacho   │ Desde                │ Hacia                │ Estado       │ Rngl.│ Días   │          │
├────────────┼────────────┼──────────────────────┼──────────────────────┼──────────────┼──────┼────────┼──────────┤
│ TIA0000123 │ 10/10 09:12│ 01 Principal · ALM01 │ 02 Santiago · ALM02  │ ● Despachada │  48  │ 0 de 2 │ [Ver]    │
│            │            │                      │                      │ ⚠ Salida sin confirmar             │
│ TIA0000119 │ 07/10 15:40│ 01 Principal · ALM01 │ 03 La Vega · ALM03   │ ● En tránsito│ 120  │ 3 de 2 │ [Ver]    │
│            │            │                      │                      │ ⚠ Tránsito vencido                 │
│ TIA0000117 │ 06/10 11:05│ 01 Principal · ALM01 │ 02 Santiago · ALM02  │ ● En tránsito│  12  │ 1 de 2 │ [Ver]    │
│            │            │                      │                      │ Recibida en parte (R1)             │
│ TIA0000110 │ 02/10 08:30│ 01 Principal · ALM01 │ 01 Principal · ALM05 │ ● Recibida   │   6  │ —      │ [Ver]    │
│            │            │                      │                      │ Traslado interno                   │
├────────────┴────────────┴──────────────────────┴──────────────────────┴──────────────┴──────┴────────┴──────────┤
│ 1–50 de 132                                                       [‹ Anterior] Página 1 de 3 [Siguiente ›] │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Elemento | Regla |
|---|---|
| Vistas | **Enviadas** (`rol=origen`): origen = sucursal de la sesión. **Por Recibir** (T-02): destino vigente = sucursal de la sesión, con saldo pendiente. **Todas** (`rol=todas`): solo con `transfreconciliacion` y la sesión en la central. Vista inicial: la de la opción del menú; si se entra por «Consulta», la primera que el usuario puede ver |
| Número / código de barras | Enter con un número completo abre el detalle (en «Por Recibir», abre la recepción directamente si `Acciones.Recibir`). En el tramo 2 el mismo campo acepta el QR del conduce |
| Filtros | Estado (Todos, Despachada, En tránsito, Recibida, Anulada; en el tramo 2 se agregan Con diferencias y Recibida provisional). Desde y Hasta: por omisión los últimos 30 días; rango ≤ 1 año (400 del servidor). Texto: número, almacén o código de artículo (semántica de T-01 por confirmar, C-6) |
| Columnas | Número, fecha y hora del despacho, Desde («{cód. sucursal} {nombre} · {almacén}»), Hacia, Estado (chip, sección 5.2), Renglones y Días en tránsito frente al plazo («3 de 2»), solo en Despachada y En tránsito. **Sin costos ni valores** en ninguna vista |
| Indicadores bajo el estado | «⚠ Salida sin confirmar» (Despachada hace más de 24 h, [TRF] 7.1), «⚠ Tránsito vencido» (`DiasEnTransito > PlazoDias`), «Recibida en parte (R{n})», «Traslado interno». Siempre texto y color, nunca solo color (UX-TI-07) |
| Acción por fila | Clic o Enter en la fila abre el detalle. En «Por Recibir», el botón de la fila es «Recibir» si `Acciones.Recibir`; si no, «Ver», con el motivo debajo (por ejemplo «Usted la despachó: la recibe otro usuario.») |
| Botón de cabecera | «Despacho de transferencia», solo con `transfdespacho` Agregar |
| Paginación | 50 por página, en el servidor (T-01 `pagina`) |

### 3.2 P-2 «Despacho de Transferencia» (nueva)

```
┌ Despacho de Transferencia  [Nueva]                                    [Buscar] [Despachar] ┐
│ Almacén de origen  [ALM01 · Principal ▾]   Almacén de destino [ALM02 · 02 Santiago ▾]      │
│ ⓘ Entre sucursales: sale del inventario de 01 Principal y queda en tránsito hasta que      │
│   02 Santiago lo reciba.                                                                    │
│ Transportista [______________]  Vehículo [________]  Notas [_______________________________]│
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ Código / código de barras [________________] [+ Agregar]                                    │
│ Enter para agregar · F3 para buscar · F2 lote o series del renglón · 3+código agrega 3      │
├───┬─────────────────────────┬──────────────┬────────┬───────┬──────────────────────────────┬────┤
│ # │ Artículo                │ Existencia   │ Cant.  │ Unid. │ Lote y vencimiento / Series  │    │
├───┼─────────────────────────┼──────────────┼────────┼───────┼──────────────────────────────┼────┤
│ 1 │ ARZ-05 Arroz selecto 5lb│  80,00 UND   │  10    │ UND   │                              │ 🗑 │
│ 2 │ AMX-500 Amoxicilina     │ 150,00 UND   │   3    │ CAJA  │ [L-2406 · vence 30/11/2026 ▾]│ 🗑 │
│   │                         │              │        │       │ Sugerido                     │    │
│ 3 │ AMX-500 Amoxicilina     │              │   2    │ CAJA  │ [L-2412 · vence 15/03/2027 ▾]│ 🗑 │
│   │                         │              │        │       │ Sugerido · completa el 2     │    │
│ 4 │ VIT-C Vitamina C 1 g    │  12,00 UND   │   5    │ UND   │ [L-2301 · vencido ▾]         │ 🗑 │
│   │                         │              │        │       │ ⚠ Vencido: pide motivo       │    │
│ 5 │ TEL-A15 Teléfono A15    │   7,00 UND   │   3    │ UND   │ [Series 2 de 3 ▾] (F2)       │ 🗑 │
│   │                         │              │        │       │ ✖ Faltan 1 serie             │    │
├───┴─────────────────────────┴──────────────┴────────┴───────┴──────────────────────────────┴────┤
│ 5 renglones · 23 unidades en unidad base                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Campo o acción | Regla |
|---|---|
| Almacén de origen | Alcance nuevo `transferencia-origen`: almacenes activos de la sucursal de la sesión (C-1). Obligatorio. Cambiarlo con renglones vuelve a validar los lotes y la existencia, y muestra «Cambió el almacén: se revisaron los lotes de {n} renglón(es).» (patrón de P-2 de [UXL]). **P-4 (firmada; el plan la ubica en el tramo 2):** una sesión en la central ve también los almacenes de las sucursales **cerradas**, con la marca «(sucursal cerrada)» |
| Almacén de destino | Alcance nuevo `transferencia-destino`: todos los almacenes activos de la empresa menos el de origen, con `Detalle` = sucursal, agrupados por sucursal (C-1). Obligatorio. Al elegirlo se fija el **modo**: misma sucursal = S («Trasladar»); otra = E («Despachar») |
| Transportista / Vehículo / Notas | Opcionales: 80, 30 y 200 caracteres ([D3B] 2.2). Salen en el conduce |
| Campo de código | Igual que `DocInventarioPage.razor:104-110`. Una lectura del **mismo** artículo suma 1 al último renglón de ese artículo y lote, siempre que el lote sugerido alcance. Si no alcanza, parte el renglón (UX-118-04) |
| Existencia | La del almacén de origen, en unidad base (`VistaUnidadBase.ConUnidad`). Si la cantidad (× factor) la supera, aparece la leyenda ámbar «Existencia 2,00 UND: una transferencia no deja negativo el almacén de origen.» No bloquea la edición: decide el servidor (T-09) |
| Cantidad y unidad | La unidad se elige entre las del artículo (ADR-78), como en `DocInventarioPage.razor:137-145`. Cantidad > 0 |
| **Lote y vencimiento** | Una sola celda y un solo texto: «{lote} · vence {dd/MM/aaaa}» (precisión del 2026-10-10, punto 1). Se usa `SelectorLote` de [UXL] con un **modo nuevo `Transferencia`** (C-4): sugerido = el primero no vencido; los vencidos van **al final, habilitados**, con la leyenda «Vencido · pide motivo» (D3 de [TRF]; PQ-2 solo rechaza el conduce a cliente, supuesto del plan). F2, clic o Enter abren el campo; F2 o ↓ abren «Elegir Lote». **No se captura el vencimiento**: el lote ya existe con el suyo |
| Series | En un artículo con serie, la celda es el chip «Series {n} de {cantidad}»; F2 abre «Números de Serie» (3.7.3). Solo series «en existencia» del almacén de origen; las valida el servidor (`SERIE_NO_DISPONIBLE`) |
| Eliminar renglón | Icono con `aria-label="Eliminar renglón {n}"`. Quitar un renglón partido no recompone el otro |
| Pie | Renglones y unidades en unidad base (lo mismo que imprime el conduce). **Sin costo, precio ni valor para nadie** ([TRF] D2) |
| Buscar | Abre P-1 en la vista «Enviadas» |
| Despachar / Trasladar | Se habilita con origen, destino y al menos 1 renglón. Primero valida en el cliente (lote en todo renglón que lo pide y series completas); si falta algo, marca los renglones y muestra «Complete los renglones marcados.» Con vencidos, abre «Lote Vencido». Después envía `DespachoRequest` con la `ClaveIdempotencia` del intento (sección 4.2) |
| Borrador local | El despacho en edición se guarda en el navegador, sin efecto en el servidor (UX-TI-02). Al volver: «Tiene un despacho sin terminar de {dd/MM HH:mm} con {n} renglones. [Continuar] [Descartar]» |

**Segregación en el despacho:** no aplica (S-01 solo exige el permiso y el origen de la sesión).

### 3.3 P-3 «Transferencia de Inventario» (detalle: salida con conduce, anulación e historial)

```
┌ Transferencia de Inventario  [TIA0000123]  ● Despachada                 [Imprimir conduce] [Anular] ┐
│ Desde 01 Principal · ALM01  →  Hacia 02 Santiago · ALM02            Despachada el 10/10/2026 09:12   │
│ Despachó ANA · Transportista J. Pérez · Vehículo L123456 · Huella A3F9-12C0-7B                     │
│ Conduce: impreso 1 vez (10/10 09:15)                                         [Confirmar salida]   │
├──[ Renglones ]──[ Recepciones (0) ]──[ Historial ]──────────────────────────────────────────────────┤
│ # │ Artículo                │ Lote y vencimiento         │ Despachada       │ Recibida │ Pendiente │
│ 1 │ ARZ-05 Arroz selecto 5lb│                            │ 10 UND           │ 0        │ 10        │
│ 2 │ AMX-500 Amoxicilina     │ L-2406 · vence 30/11/2026  │ 3 CAJA (= 30 UND)│ 0        │ 30 UND    │
│ 5 │ TEL-A15 Teléfono A15    │ Series: S1001, S1002, S1003│ 3 UND            │ 0        │ 3         │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Elemento | Regla |
|---|---|
| Cabecera | Número, chip de estado (5.2) e indicadores (los de P-1, más «Traslado interno»). Origen → destino (destino **vigente**; en el tramo 2, si se redirigió, «Hacia {nuevo} (antes {original})»). Fecha, despachador, transportista, vehículo y huella corta (`Huella10`). Notas si las hay |
| Conduce | «Conduce: sin imprimir» o «impreso {n} veces (último {dd/MM HH:mm})» (C-2 `ConduceImpresiones`). El botón «Imprimir conduce» va **resaltado** (`Filled`) mientras la transferencia esté Despachada sin salida; después, en contorno. En modo S el botón dice «Imprimir traslado» (UX-TI-06) |
| Confirmar salida | Visible si `Acciones.ConfirmarSalida`. Deshabilitado sin conduce impreso, con la ayuda «Imprima el conduce antes de confirmar la salida.» Abre «Confirmar Salida» (3.7.4) |
| Anular | Visible si el usuario tiene `transfdespacho` Anular y la sesión está en la sucursal de origen. Si `Acciones.Anular = false`, se ve deshabilitado y explica por qué (F-5). Abre «Anular Transferencia» (3.7.5) |
| Recibir | En B: si `Acciones.Recibir`, botón principal «Recibir» → T-08 → P-4. Si la recepción está abierta por otros, el botón dice «Unirse a la recepción (ANA contando)» (C-2 `RecepcionAbierta`). Si el usuario la despachó: botón deshabilitado y «Usted despachó esta transferencia: la recibe otro usuario.» |
| Pestaña Renglones | #, artículo (código y descripción), lote y vencimiento (un solo texto) o series, despachada (en la unidad del renglón y su equivalente en unidad base si el factor es distinto de 1), recibida, pendiente. **Costo y valor solo con `VerCostos`** (`[DatoCosto]`; en el tramo 2 se aplica el privilegio efectivo de 3b-1) |
| Pestaña Recepciones | R1, R2…: fecha, quién la registró, renglones y unidades. Al expandir, las cantidades por renglón |
| Pestaña Historial | Línea de tiempo de T-04: «Despachada por ANA», «Conduce impreso (1)», «Reimpresión 2 por ANA», «Salida confirmada por ANA · J. Pérez», «Recepción R1 confirmada por LUIS: 46 de 48 renglones», «Anulada por SUP1 · motivo». Sin costos. Fecha y hora de cada evento |
| Anulada | Banda `MudAlert` de error, como `DocInventarioPage.razor:45`: «Anulada el {fecha} por {usuario}. {motivo}» |

### 3.4 P-4 «Recepción de Transferencia» (sesión)

```
┌ Recepción de Transferencia  [TIA0000123]  Desde 01 Principal · ALM01 → ALM02             ┐
│ Conteo ciego · Contando: LUIS, MARÍA · ● Conectado · 0 lecturas por enviar                │
│ Código / código de barras [________________]  (Enter cuenta · 3+código cuenta 3 · F2 lote) │
│ Última: ✔ AMX-500 Amoxicilina · L-2406 · +1 CAJA  (contado 3)                             │
├───┬─────────────────────────┬────────────────────────────┬─────────┬────────────┬─────────┤
│ # │ Artículo                │ Lote y vencimiento / Series│ Unid.   │ Contado    │ Esperado│
├───┼─────────────────────────┼────────────────────────────┼─────────┼────────────┼─────────┤
│ 1 │ ARZ-05 Arroz selecto 5lb│                            │ UND     │ 10         │  ••     │
│ 2 │ AMX-500 Amoxicilina     │ L-2406 · vence 30/11/2026  │ CAJA    │ 3          │  ••     │
│ 3 │ AMX-500 Amoxicilina     │ L-2412 · vence 15/03/2027  │ CAJA    │ 0          │  ••     │
│ 5 │ TEL-A15 Teléfono A15    │ Series 1 leída             │ UND     │ 1          │  ••     │
├───┴─────────────────────────┴────────────────────────────┴─────────┴────────────┴─────────┤
│ No esperados (no se reciben en esta transferencia): GAL-01 Galletas · 2 UND               │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Lecturas (34)]                           [Descartar conteo]   [Terminar conteo]           │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Elemento | Regla |
|---|---|
| Campo de lectura | Siempre tiene el foco (lo recupera al cerrar diálogos, `EnfocarAsync`). Una lectura es un artículo o una serie. «3+código» cuenta 3 (`Origen = D`, digitado). Enter sin código no hace nada |
| Lote | Si el artículo tiene **un solo** renglón (un lote) en la transferencia, se toma ese lote. Si tiene varios, aparece «¿De Qué Lote?» (diálogo de [UXL]) con **solo** los lotes de la transferencia para ese artículo: se lee el lote o se elige con 1 a 9. Se recuerda para las lecturas siguientes del mismo código mientras dure la sesión; F2 cambia el recordado |
| Respuesta a la lectura | Visual inmediata: la fila parpadea y la línea «Última: …» se actualiza (`aria-live="polite"`). Sonido corto de aceptado o de error (se puede silenciar, preferencia del navegador). Lectura rechazada: «✖ {código} no está en esta transferencia.» o «✖ La serie {s} no pertenece a esta transferencia.» (`ESCANEO_NO_PERTENECE`) |
| Artículo existente fuera de la transferencia | Va a «No esperados» (T-10), con la nota «no se reciben en esta transferencia». En el tramo 1 no entran (UX-TI-03) |
| Columna Esperado | Con conteo ciego: «••» y `aria-label="Oculto hasta terminar el conteo"`. Sin conteo ciego: el número, y la fila se marca «Completo» o «Faltan {n}» |
| Cabecera | «Conteo ciego» (si aplica), usuarios que cuentan (`Usuarios`), estado de la conexión y lecturas por enviar |
| Lecturas | Panel con las últimas lecturas: hora, usuario, código, lote o serie y cantidad. Se puede borrar una lectura **propia** (T-11). Las de otro usuario solo se borran con `transfrecepcion` Autorizar; sin ese permiso, el icono no aparece |
| Descartar conteo | Confirmación: «Se borran las {n} lecturas de esta recepción. La transferencia sigue por recibir. ¿Descartar?» → T-14 → vuelve a «Por Recibir» |
| Terminar conteo | Deshabilitado mientras haya lecturas por enviar o no haya conexión («Espere a que se envíen las lecturas.»). Llama a T-12 y abre «Resultado del Conteo» (3.7.6) |
| Sesión cerrada por otro | Si otro usuario confirma o descarta, la siguiente respuesta es 409 `SESION_CERRADA`: la pantalla se bloquea con «Esta recepción ya se confirmó o se descartó.» y, si queda saldo, «[Abrir una recepción nueva para lo pendiente]» |
| Segregación | Si el usuario despachó la transferencia, la pantalla no se abre: T-08 responde 403 `FUNCION_INCOMPATIBLE` y se muestra «Usted despachó esta transferencia: la recibe otro usuario.» |

### 3.5 Detalle de reglas compartidas por renglón

- **Un renglón = un artículo y, como máximo, un lote** ([D3B] 2.3). Dos lotes del mismo artículo son dos renglones, en el despacho y en la recepción.
- **Lote y vencimiento** se muestran siempre juntos, con un solo texto. Ninguna pantalla de este tramo captura un vencimiento: el despacho sale de lotes que ya existen y la recepción recibe por `LoteId`. La captura con `CampoLoteVencimiento` y la bandera `LOTE_VENCIMIENTO_DISTINTO` llegan con el sobrante y la sustitución del tramo 2.
- Cantidades con dos decimales y su unidad; fechas `dd/MM/aaaa` (D-05 de [UXL]).

### 3.6 Variante MAUI (tramo 2; criterios que la Web cumple desde ya)

En el tramo 1 no hay MAUI. Según el plan, el despacho queda solo en la Web en la versión 1, y la recepción y «Por Recibir» llegan a MAUI en el tramo 2, con la cámara. Para que la copia sea directa, la Web ya cumple esto:

```
┌ Recepción  TIA0000123 ┐   (teléfono o tableta vertical, xs)
│ ● Conectado · 0 por enviar │
│ [ 📷 Escanear ]  [___]     │  ← cámara o lector Bluetooth; el campo también acepta el lector
│ Última: ✔ AMX-500 +1 CAJA │
│ ┌────────────────────────┐ │
│ │ ARZ-05 Arroz 5 lb      │ │  tarjeta por renglón (sin tabla), ≥ 48 px de alto
│ │ Contado 10      ••     │ │
│ ├────────────────────────┤ │
│ │ AMX-500 · L-2406       │ │
│ │ vence 30/11/2026       │ │
│ │ Contado 3   [− 1] [+ 1]│ │  ← botones táctiles que generan lecturas digitadas
│ └────────────────────────┘ │
│ [Terminar conteo] (ancho)  │
└────────────────────────────┘
```

- Nada depende de pasar el puntero; los objetivos táctiles miden ≥ 48 × 48 px; los diálogos van a pantalla completa en `xs` ([UXL] sección 6).
- La lectura con cámara produce el mismo `EscaneoDto` (`Origen = E`). «− 1» genera una lectura negativa o borra la última propia (C-7).
- La cola de lecturas por enviar se guarda en el almacenamiento local del dispositivo (Preferences o un archivo en `FileSystem.AppDataDirectory`), con la misma regla de reenvío que la Web (4.2).

### 3.7 Diálogos

#### 3.7.1 «Existencia Insuficiente» (reutilizado: `DialogoFaltantes` de [UXL] P-4)
- Primera línea: «No se guardó la transferencia.» + «Corrija los renglones marcados.»
- Columna «Detalle»: los motivos de [UXL] más uno nuevo, **`T` «Una transferencia no deja negativo el almacén de origen»**, para cuando la política de la empresa permite negativos pero rige T-09 (P-2 del 2026-10-10). Requiere C-3.
- Sin botones de política, de autorización ni de «despachar igual».

#### 3.7.2 «Lote Vencido»
```
┌ Lote Vencido ───────────────────────────────────────────────┐
│ Estos renglones llevan un lote vencido:                     │
│  4  VIT-C Vitamina C 1 g · L-2301 · venció el 02/09/2026    │
│ Motivo del despacho [_______________________________] (≥ 10) │
│ ⓘ Por ejemplo: «Devolución al suplidor desde la central».   │
│                                      [Cancelar] [Despachar] │
└─────────────────────────────────────────────────────────────┘
```
Un solo motivo para la cabecera (`DespachoRequest.MotivoLoteVencido`, contrato vigente). Si llega `LOTE_VENCIDO_SIN_MOTIVO`, el diálogo se vuelve a abrir.

#### 3.7.3 «Números de Serie»
Lista de las series leídas para el renglón, con un campo de lectura con foco. Enter agrega la serie; se pueden quitar. El contador dice «2 de 3». Una serie repetida da «Esa serie ya está en el renglón {n}.» La validación de que exista en el almacén la hace el servidor.

#### 3.7.4 «Confirmar Salida»
```
┌ Confirmar Salida · TIA0000123 ──────────────────────────────┐
│ La mercancía se entregó al transportista.                   │
│ Transportista [J. Pérez____________] (obligatorio, UX-TI-04)│
│ Vehículo      [L123456_]                                    │
│                              [Cancelar] [Confirmar salida]  │
└─────────────────────────────────────────────────────────────┘
```
Envía `ConfirmarSalidaRequest { transportista, vehiculo, version }`. Si llega `SALIDA_YA_CONFIRMADA`, la pantalla recarga y muestra quién confirmó.

#### 3.7.5 «Anular Transferencia»
- Base: `DialogoAnulacion` (motivo del catálogo de ADR-71 más texto; `ConNcf = false`).
- Con salida confirmada: dos casillas obligatorias (F-5) y, después, `DialogoAutorizacionSupervisor` con la opción `transfdespacho` y el encabezado «Autorización del supervisor de {sucursal A}». La pantalla lo pide de entrada, porque sabe que la salida está confirmada; si el servidor responde `AUTORIZACION_INVALIDA`, el diálogo lo dice y deja reintentar (patrón Q-5).
- Texto final: «Transferencia anulada: la mercancía volvió a {almacén A}.»

#### 3.7.6 «Resultado del Conteo» (comparar y confirmar)
```
┌ Resultado del Conteo · TIA0000123 · Recepción R1 ─────────────────────────────────┐
│ # │ Artículo                 │ Lote          │ Esperado │ Contado │ Se recibe │       │
│ 1 │ ARZ-05 Arroz 5 lb        │               │ 10 UND   │ 10      │ 10        │ ✔     │
│ 2 │ AMX-500 Amoxicilina      │ L-2406        │ 30 UND   │ 24      │ 24        │ Faltan 6 │
│ 3 │ AMX-500 Amoxicilina      │ L-2412        │ 20 UND   │ 22      │ 20        │ Sobran 2 │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ⚠ Faltan 6 UND en 1 renglón: quedan pendientes en tránsito y se pueden recibir    │
│   en otra recepción.                                                              │
│ ⚠ Sobran 2 UND en 1 renglón: no entran al inventario. Se registran con el         │
│   registro de diferencias (UX-TI-03).                                             │
│ [ ] Revisé el conteo                                                              │
│ No esperados: GAL-01 Galletas · 2 UND (no se reciben)                             │
│                          [Volver a contar] [Confirmar recepción]                  │
└────────────────────────────────────────────────────────────────────────────────────┘
```
- «Volver a contar» regresa a P-4 con «Esperado» visible solo en los renglones con diferencia. Las lecturas nuevas quedan marcadas «después de ver lo esperado» (UX-TI-05).
- «Confirmar recepción» solo pide la casilla «Revisé el conteo» si hay diferencias. Envía T-13 con `CierraSaldo = false` y sin diferencias.
- Si todo coincide, el diálogo muestra «Todo coincide con lo despachado.» y el botón queda enfocado.

---

## 4. Estados por pantalla

### 4.1 Estados de la transferencia (lo que ve el usuario)

| Código del servidor ([SW3B] 4.1) | Texto del chip | Color (con el texto, nunca solo) | Tramo |
|---|---|---|---|
| — (sin guardar) | «Nueva» | Contorno gris | 1 |
| `DESPACHADO` | «Despachada» | Info (azul) | 1 |
| `EN_TRANSITO` | «En tránsito» | Primario | 1 |
| `EN_TRANSITO` con recepciones | «En tránsito» + indicador «Recibida en parte (R{n})» | Primario + ámbar | 1 |
| `RECONCILIADO` | «Recibida» (modo S: + «Traslado interno») | Éxito (verde) | 1 |
| `ANULADO` | «Anulada» | Error (rojo) | 1 |
| `RECIBIDO_PROVISIONAL` | «Recibida provisional» | Ámbar | 2 |
| `CON_DIFERENCIAS` | «Con diferencias» | Ámbar oscuro | 2 |

**Borrador:** el despacho no tiene borrador en el servidor. El borrador sin número de ADR-72 vive dentro de la transacción y el usuario no lo ve. El único borrador visible es el **local** del navegador (UX-TI-02). La sesión de recepción sí es un borrador del servidor: se ve como «Recepción en curso (ANA contando)» y no como estado de la transferencia. «Reconciliado» queda como término interno de la central: para el almacén, el texto es «Recibida».

### 4.2 Estados técnicos por pantalla

| Pantalla | Carga | Vacío | Error | Sin permisos | Sin conexión | Resultado desconocido |
|---|---|---|---|---|---|---|
| P-1 lista | `MudProgressLinear` sobre la tabla; el contador del menú oculto | Enviadas: «No hay transferencias enviadas en estas fechas.» · Por Recibir: «No hay transferencias por recibir en {sucursal}.» · Todas: «No hay transferencias con ese filtro.» | 400 de rango: «El rango de fechas no puede pasar de un año.»; otros, el aviso de `PaginaBase` | Sin ninguno de los tres permisos: el subgrupo no aparece; por dirección directa, «Su usuario no tiene acceso a las transferencias.» | Banda «No se pudo contactar el servidor de la aplicación. [Reintentar]»; los datos ya mostrados se conservan con «Sin conexión: los datos pueden no estar al día.» (patrón del visor) | No aplica (lectura) |
| P-2 despacho | Al abrir, catálogos de almacenes; por renglón, «Buscando lotes…» sin bloquear la siguiente lectura | «Sin renglones. Escanee o digite el código del artículo.» Sin almacenes de origen: «Su sucursal no tiene almacenes habilitados para despachar.» Sin destinos: «No hay otro almacén activo en la empresa.» | Sección 3.8 (por código); los renglones se conservan y se marcan | Sin `transfdespacho` Agregar: «Su usuario no tiene acceso al despacho de transferencias.» | Las lecturas de artículos fallan con el aviso de conexión y el renglón no se agrega; lo ya escrito se conserva (borrador local). «Despachar» muestra el error de conexión | **Si se pierde la respuesta de «Despachar»:** los renglones quedan en solo lectura y aparece la banda «No se sabe si la transferencia se guardó. Reintente: si ya se guardó, verá la transferencia sin duplicarla. [Reintentar]». Se reenvía con **la misma** `ClaveIdempotencia`; un 201 o un 200 `Repetida` navegan al detalle. La clave se renueva solo si la respuesta es un rechazo claro (4xx) y el usuario edita |
| P-3 detalle | Esqueleto de la cabecera y las pestañas | No aplica | 404: «No se encontró la transferencia {n} o no es de su sucursal.» Errores de acción: sección 3.8 | Sin permiso de lectura: 404 (el servidor no distingue) | Acciones deshabilitadas con «Sin conexión»; datos con la marca de P-1 | «Confirmar salida» se reintenta con la misma `Version`: si ya se aplicó, `SALIDA_YA_CONFIRMADA` → recarga y «La salida ya estaba confirmada.». «Anular» se reintenta: si ya se anuló, la recarga muestra Anulada. «Imprimir» se puede repetir (sale como reimpresión) |
| P-4 recepción | «Abriendo la recepción…»; al unirse, «Se unió a la recepción que inició {usuario}.» | Transferencia sin saldo: `TRANSFERENCIA_SIN_SALDO` → «Esta transferencia ya no tiene nada pendiente de recibir.» y vuelve a la lista | Lectura rechazada: en la línea «Última» y con sonido de error; el resto, sección 3.8 | Sin `transfrecepcion`: «Su usuario no tiene acceso a la recepción de transferencias.» | **Se sigue contando.** Las lecturas se encolan con su `EscaneoId`, en la memoria del circuito y copiadas en `localStorage` (clave = `SesionId`). La cabecera dice «● Sin conexión · {n} lecturas por enviar» y se reintenta cada 5 s. Terminar y Confirmar quedan deshabilitados. Si se cae el circuito (`ReconnectModal`) o se recarga la página, al volver la cola se reenvía y nunca suma dos veces (PK `(SesionId, EscaneoId)`) | **Confirmar sin respuesta:** banda «No se sabe si la recepción se confirmó. [Reintentar]». Se reintenta con el mismo `sid`: 200 `Repetida = true` → «La recepción ya se había confirmado (R{n}).»; 409 `IDEMPOTENCIA_CONFLICTO` → recarga del detalle |
| Diálogos | — | — | El error queda dentro del diálogo, que no se cierra (patrón de `DialogoAperturaCaja`) | — | Error de conexión dentro del diálogo; lo escrito se conserva | Igual que la pantalla que lo abrió |

### 4.3 Transiciones y acciones habilitadas (lo que muestra la pantalla; manda `AccionesTransferenciaDto`)

| Estado | En A (origen) | En B (destino) |
|---|---|---|
| Despachada | Imprimir conduce · Confirmar salida (con conduce) · Anular | Recibir (otro usuario) |
| En tránsito sin recepciones | Imprimir (reimpresión) · Anular con supervisor | Recibir |
| En tránsito con R1… | Imprimir · Anular **deshabilitado** con motivo | Recibir lo pendiente |
| Recibida | Imprimir | — |
| Anulada | Imprimir (sale con «ANULADA», a cargo de 3b-3) | — |

---

## 5. Componentes y sistema de diseño

### 5.1 Reutilizados (sin cambiar su comportamiento)
`PaginaBase` (`EjecutarAsync`, `CargarAsync`, `MostrarError`, `ConfirmarAsync`), `SelectorCatalogo` (con los alcances nuevos), `DialogoAnulacion`, `DialogoAutorizacionSupervisor`, `DialogoMotivo`, `DialogoBuscarArticulo`, `BotonImprimir` (para el PDF de T-21; la ruta del proxy la fija el desarrollador-frontend), `VistaUnidadBase`, `VistaUnidadesArticulo`, `EntradaCodigo.Interpretar`, `MudSimpleTable`, `MudTable` (lista), `MudChip`, `MudBadge`, `MudTabs`, `MudTimeline` (historial) y la clase `zona-tactil`. Del diseño del lote [UXL] (los construye T4 de ADR-119): `SelectorLote` (con el modo nuevo `Transferencia`, C-4), `DialogoElegirLote`, «¿De Qué Lote?» y `DialogoFaltantes` (con el motivo `T`).

### 5.2 Nuevos (Web; la copia MAUI de P-1 y P-4 va en el tramo 2)

| Componente | Responsabilidad |
|---|---|
| `Pages/Inventario/Transferencias.razor` | P-1, con las vistas Enviadas, Por Recibir y Todas |
| `Pages/Inventario/DespachoTransferencia.razor` | P-2 (modos E y S), borrador local, idempotencia y estado de resultado desconocido |
| `Pages/Inventario/TransferenciaDetalle.razor` | P-3 con sus pestañas y acciones |
| `Pages/Inventario/RecepcionTransferencia.razor` | P-4: cola de lecturas, conteo optimista, ciego, varios usuarios, terminar y confirmar |
| `Compartidos/DialogoConfirmarSalida.razor`, `DialogoAnularTransferencia.razor`, `DialogoLoteVencido.razor`, `DialogoNumerosSerie.razor`, `DialogoResultadoConteo.razor` | Sección 3.7 |
| `Compartidos/EstadoTransferencia.razor` | Chip de estado más indicadores (patrón de `EstadoFactura.razor`) |
| `Servicios/VistaTransferencias.cs` | Textos fijos por código (3.8), estados, indicadores, regla de modo E/S, días frente al plazo. Se prueba sin interfaz (patrón de `VistaRechazoUnidad`) |
| `Servicios/ColaEscaneos.cs` (+ funciones en `gpos.js` para `localStorage` y sonido) | `EscaneoId`, tandas de ≤ 200 cada 400 ms, reintentos cada 5 s, copia local y reenvío idempotente |

### 5.3 Notas de diseño (decididas aquí porque no cambian reglas)
- **DT-01** El despacho no muestra costo, precio ni valor a nadie. El detalle lo muestra solo con `VerCostos`.
- **DT-02** Ningún diálogo aparece después de cada lectura, salvo el de lote ambiguo, que se recuerda por código durante la sesión.
- **DT-03** El conteo se muestra optimista y queda marcado «por enviar» hasta que el servidor lo confirma: la confirmación de una lectura no espera la red.
- **DT-04** Color siempre con texto («Vencido», «Tránsito vencido», «Faltan 6»…). El ámbar va como fondo con texto oscuro (contraste ≥ 4,5:1).
- **DT-05** Títulos con mayúsculas de título (RG-30): «Consulta de Transferencias», «Despacho de Transferencias» (menú), «Despacho de Transferencia» (pantalla), «Transferencias por Recibir», «Transferencia de Inventario», «Recepción de Transferencia», «Confirmar Salida», «Anular Transferencia», «Lote Vencido», «Números de Serie», «Resultado del Conteo». Los botones siguen en minúscula de oración, como el resto de la aplicación («Imprimir conduce», «Terminar conteo»).
- **DT-06** Vocabulario. BP2 no tenía transferencias ([TRF] 0.1), así que no hay texto de BP2 que conservar en ellas; se conservan «Almacén», «Existencia insuficiente», «Requiere lote», «Anulado/a» y el formato de los números. **No se usan:** «tránsito virtual», «parte», «sesión» (en pantalla es «recepción» o «conteo»), «reconciliado», «idempotencia», «S-02», «stock», «picking», «FEFO».
- **DT-07** El conteo ciego es un **empujón, no un control fuerte**: el conduce en papel trae las cantidades ([TRF] 6.1) y el receptor con permiso de lectura puede abrir el detalle. Coincide con lo firmado (P-T3 y el reporte de diferencias por receptor). Lo dejo como observación, sin pregunta.

---

## 6. Accesibilidad, teclado y lector

| Tecla | Dónde | Acción |
|---|---|---|
| Enter | Código (P-2) | Agrega el renglón con el lote sugerido; el foco vuelve al código |
| F3 | Código (P-2) | Busca el artículo (como hoy) |
| **F2** | P-2 (código o renglón) | Lote o series del renglón enfocado o del último que los tenga |
| Enter | Código (P-4) | Cuenta la lectura |
| F2 | Código (P-4) | Cambia el lote recordado del último artículo con varios lotes |
| 1 a 9 / ↑↓ / Enter | «Elegir Lote», «¿De Qué Lote?» | Elegir |
| Esc | Diálogos | Cancela y devuelve el foco al campo de código |
| Enter | Número en P-1 | Abre el detalle o la recepción |

- **Lector:** teclea y envía Enter. En el campo de código de P-2 y P-4, una lectura es un artículo o una serie. En el campo «Lote» o en el diálogo de lote, es un lote. En el número de P-1, es un número de transferencia (tramo 2: el QR). Un lector que envía dos lecturas no duplica nada en el servidor (cada lectura tiene su `EscaneoId`), pero **sí suma dos** en el conteo, porque son dos lecturas. Por eso el panel «Lecturas» deja borrar una.
- **Criterios (WCAG 2.1 AA como referencia):** `aria-label` en los controles nuevos («Lote del renglón {n}», «Series del renglón {n}», «Eliminar renglón {n}», «Contado del renglón {n}», «Oculto hasta terminar el conteo»). `aria-live="polite"` en la línea «Última lectura». `role="alert"` en las leyendas de error por renglón. Los diálogos atrapan el foco y lo devuelven al campo de código. Ninguna información depende solo del color o del sonido (el sonido acompaña al texto). Las tablas tienen encabezados `th` con `scope`. Todo se opera solo con teclado, sin ratón.

---

## 7. Mensajes por código de error

**Numeración del motor (inferida):** ADR-100 (P-5) asigna 51440 a 51459, los mismos 20 números que la franja 51360 a 51379 del DDL. Supongo un desplazamiento de +80 (51360 → 51440 … 51379 → 51459); lo fija el arquitecto-software (C-8). **La pantalla decide por `extensions.codigo`, nunca por el número.** Si llega un número sin código, se muestra el texto del servidor.

| Código | HTTP (número del motor) | Pantalla | Texto propuesto | Qué hace la pantalla |
|---|---|---|---|---|
| `DESTINO_INVALIDO` | 422 | P-2 | «El almacén de destino no es válido: elija un almacén activo de la empresa, distinto del de origen.» | Foco y marca en el destino |
| `EXISTENCIA_INSUFICIENTE` (+ `faltantes`) | 422 | P-2 | «Existencia Insuficiente» (3.7.1) | Marca los renglones; foco en la cantidad del primero |
| `SERIE_NO_DISPONIBLE` | 422 | P-2 | «La serie {s} del renglón {n} no está disponible en {almacén}{; la tiene la transferencia {TI}}.» | Marca el renglón; F2 la corrige |
| `LOTE_VENCIDO_SIN_MOTIVO` | 422 | P-2 | «El lote {l} del renglón {n} está vencido: indique el motivo para despacharlo.» | Abre «Lote Vencido» |
| `LOTE_REQUERIDO` | 422 | P-2 | «{artículo} se controla por lote: elija el lote del renglón {n}.» | Marca el renglón (F-5 de [UXL]: por renglón) |
| `LOTE_INEXISTENTE` | 422 | P-2 | «El lote {l} no existe para {artículo} en {almacén}.» | Marca el renglón y abre «Elegir Lote» |
| `PERIODO_CERRADO` | 422 (51333) | P-2, P-3 (anular), P-4 (confirmar) | Texto del servidor + «Avise al administrador.» | Diálogo de aviso (`VistaAvisosDocumento`) |
| `EMISION_BLOQUEADA` | 503 (51330) | P-2, P-3, P-4 | Texto del servidor (restauración, H-11) | Diálogo de aviso; no se reintenta solo |
| `PARTE_DE_OTRO_SITIO` | 409 (51440 como red) | Todas las acciones | «Esta parte de la transferencia la registra {sitio}. Hágalo desde allí.» | Aviso; en la entrega 1 no debería ocurrir |
| `PARTE_INMUTABLE`, `FECHA_PARTE` | 500 (51441, 51457) | Todas | «Ocurrió un error interno ({código}). Avise al soporte.» | Aviso de error |
| `TRANSFERENCIA_CON_PARTES` | 409 (51442) | P-3 anular | «La transferencia ya tiene recepciones: no se puede anular.» | Recarga; «Anular» queda deshabilitado |
| `DESTINO_NO_VIGENTE` | 409 (51443) | P-4 | «La transferencia se redirigió a otro almacén: ya no se recibe aquí.» | Bloquea la recepción y vuelve a la lista |
| `SALIDA_YA_CONFIRMADA` | 409 | P-3 | «La salida ya fue confirmada por {usuario} el {fecha}.» | Recarga |
| `REGISTRO_MODIFICADO` | 409 | P-3 | «La transferencia cambió mientras la tenía abierta. Se recargó; revise y vuelva a intentarlo.» | Recarga |
| `CONDUCE_NO_IMPRESO` | 422 | P-3 | «Imprima el conduce antes de confirmar la salida.» | El diálogo ofrece «Imprimir conduce» |
| `SESION_CERRADA` | 409 | P-4 | «Esta recepción ya se confirmó o se descartó.» (+ «¿Abrir una recepción nueva para lo pendiente?» si queda saldo) | Bloquea la pantalla y ofrece abrir otra |
| `TRANSFERENCIA_SIN_SALDO` | 409 | P-1, P-3, P-4 | «Esta transferencia ya no tiene nada pendiente de recibir.» | Vuelve a la lista |
| `ESCANEO_NO_PERTENECE` | 422 | P-4 | «{código} no está en esta transferencia.» / «La serie {s} no pertenece a esta transferencia.» | Línea «Última» en rojo y sonido de error; no suma |
| `SALDO_INSUFICIENTE` (+ línea) | 409 (547) | P-4 confirmar | «El renglón {n} ya no tiene saldo suficiente: se confirmó otra recepción al mismo tiempo. Se recargó la recepción.» | Recarga la sesión; los escaneos se conservan |
| `IDEMPOTENCIA_CONFLICTO` | 409 | P-2, P-4 | «Esta operación ya se registró con otros datos. Se recargó la transferencia.» | Navega al detalle |
| `FUNCION_INCOMPATIBLE` | 403 (51456) | P-4 (abrir, unirse, confirmar) | «Usted despachó esta transferencia: la recibe otro usuario.» (el motivo del servidor, si es otro) | No abre la recepción |
| `AUTORIZACION_INVALIDA` | 422 | P-3 anular | Texto existente del diálogo de supervisor | Reintento dentro del diálogo |
| `MOTIVO_REQUERIDO` | 422 | P-3 anular, P-2 vencido | «Indique el motivo.» | Foco en el motivo |
| `TRANSFERENCIA_NO_ENCONTRADA` | 404 | P-1, P-3 | «No se encontró la transferencia {n} o no es de su sucursal.» | Se queda en la lista |
| `IDEMPOTENCIA` repetida (`Repetida = true`) | 200 | P-2, P-4 | «La transferencia ya estaba guardada: {TI}.» / «La recepción ya se había confirmado (R{n}).» | Trata el caso como éxito |
| Sin respuesta / `HttpRequestException` | — | Todas | «No se pudo contactar el servidor de la aplicación.» (existente) | Estados «Sin conexión» y «Resultado desconocido» (4.2) |

---

## 8. Datos requeridos de la API

### 8.1 Existentes en el diseño ([SW3B] 5.2 y 5.3; ninguno construido todavía)
T-01 a T-14 y T-21; `DespachoRequest`, `LineaDespachoDto` (con `Unidad`, `Lote` y `Series`), `TransferenciaDto`, `LineaTransferenciaDto`, `AccionesTransferenciaDto`, `EscaneoDto`, `EscaneosRequest`, `SesionRecepcionDto`, `LineaSesionDto` y `ConfirmarRecepcionRequest`. Del código actual: `ArticuloLinea` (existencia y unidad base), las unidades del artículo y `DialogoAnulacion` con los motivos de ADR-71.

### 8.2 Cambios de contrato que necesita el frontend (para el arquitecto-software de B, tramo 0)

| # | Cambio | Por qué | Prioridad |
|---|---|---|---|
| **C-1** | Alcances de catálogo `transferencia-origen` (almacenes activos de la sucursal de la sesión; con P-4, los de sucursales cerradas si la sesión está en la central) y `transferencia-destino` (todos los activos de la empresa, `Detalle` = código y nombre de la sucursal) | H4. Sin ellos, el selector ofrece almacenes que el servidor rechaza | **Alta** |
| **C-2** | En `TransferenciaDto`: `Despachador`, `Transportista`, `Vehiculo`, `Notas`, `ConduceImpresiones` y `ConduceUltimaImpresion`, `RecepcionAbierta { SesionId, Usuarios }`, `Anulacion { Fecha, Usuario, Motivo }` y `SucursalOrigen`/`SucursalDestino` con código. En `LineaTransferenciaDto`: `Unidad`, `CantidadUnidad`, `UnidadBase` y `VencimientoLote` (lote y vencimiento son una sola información) | Cabecera de P-3, «Confirmar salida» habilitado tras imprimir y el motivo de S-02 sin otra consulta | **Alta** |
| **C-3** | Motivo de faltante `T` («una transferencia no deja negativo el almacén de origen») en `FaltanteExistenciaDto`, y `renglon` en base 1 según la lista enviada | 3.7.1: sin él, el motivo diría «No alcanza la existencia» aunque la política permita negativos | Media |
| **C-4** | `SelectorLote` y `lotes-disponibles` con un modo `Transferencia` (vencidos al final y habilitados) | D3 de [TRF] frente al modo conduce de [UXL] | **Alta** (entrega a C y U) |
| **C-5** | Definir `TransferenciaResumenDto` (número, fecha, origen y destino con sucursal, estado, renglones, unidades, días y plazo, consecutivo de recepciones, `TrasladoInterno`, `SalidaConfirmada`) y `PorRecibirDto { Contador, Lista }` | P-1 y el contador del menú | **Alta** |
| **C-6** | Precisar qué busca `texto` en T-01 (número, almacén o artículo) | Ayuda del campo | Baja |
| **C-7** | En `SesionRecepcionDto`: `Descripcion`, `Unidad`, `VencimientoLote` y `RequiereSerie` por línea; `Lecturas` recientes (`EscaneoId`, usuario, hora, código, lote o serie, cantidad, `DespuesDeTerminar`) para el panel y para borrar (T-11); `Terminada` y `TerminadaEn`. En la respuesta de T-10, **un resultado por escaneo** (`EscaneoId`, `Estado`: aceptado, no esperado o rechazado, `Codigo` del error) | El panel de lecturas, borrar lecturas y la línea «Última» sin adivinar | **Alta** |
| **C-8** | Tabla definitiva código ↔ número del motor (51440 a 51459) en `CodigosTransferencia.cs` | Sección 7 | Media |
| **C-9** | Definir `ComparacionRecepcionDto` (por renglón: esperado, contado, a recibir, diferencia; más los no esperados) y la regla del tramo 1 cuando lo contado supera lo pendiente (UX-TI-03) | 3.7.6. Hoy T-13 fallaría entero con `SALDO_INSUFICIENTE` | **Alta** |
| **C-10** | Definir `HistorialTransferenciaDto` (evento, fecha y hora, usuario, detalle sin costos) | Pestaña Historial | Media |
| **C-11** | F-1 de ADR-119 (`ArticuloLinea.RequiereLote` y `RequiereSerie`) | H5. Sin él, una consulta más por renglón | **Alta** (firmado, antes del 15-oct) |

---

## 9. Qué queda para el tramo 2 (y después)

| Pieza | Tramo | Qué cambia en estas pantallas |
|---|---|---|
| Diferencias (faltante, pérdida, no apto, sobrante, sustitución), «No llegará más» (`CierraSaldo`), supervisor de B y confirmación del origen (A3′) | 2 | «Resultado del Conteo» suma «Registrar diferencias» por renglón (motivo del maestro, referencia y supervisor). P-3 suma la pestaña «Diferencias» y la acción «Confirmar como origen». Se agregan los estados «Recibida provisional» y «Con diferencias». El sobrante y la sustitución capturan **lote y vencimiento** con `CampoLoteVencimiento` y `LOTE_VENCIMIENTO_DISTINTO` (bandera de revisión) |
| QR del conduce (3b-3 resto) | 2 | El campo de número de P-1 y P-4 lee el QR de cualquier página |
| MAUI: «Por Recibir» y recepción con la cámara | 2 | Copia de P-1 (vista Por Recibir) y P-4 según 3.6 |
| Costos solo en la central (3b-1) | 2 | `VerCostos` pasa a ser el privilegio efectivo en P-3 |
| Despacho desde una sucursal cerrada por la central (P-4 firmada) | 2 (plan) | Ya diseñado en P-2 (alcance `transferencia-origen`) |
| Imputación, redirección, maestro de motivos y parámetros | 2 | Pantallas propias de la central (fuera de este diseño) |
| Adjuntos y avales (3b-A) | 3 | Adjuntar en la diferencia; «pendiente de aval» |
| Avisos por correo, tránsito vencido escalado (T6) | 3 | Los indicadores de P-1 ya existen desde el tramo 1 |
| Recepción provisional sin conexión con la central, USB y reconstrucción | Entrega 2 | Fuera de alcance |

---

## 10. Hoja de firma (preguntas para el propietario)

| # | Pregunta | Opciones | Recomendación | Qué rompe / costo | Firma |
|---|---|---|---|---|---|
| **UX-TI-01** | ¿Cómo aparecen las transferencias en el menú? | (a) Subgrupo «Transferencias» en Inventario con «Despacho de Transferencias», «Transferencias por Recibir» (con contador) y «Consulta de Transferencias». (b) Una sola opción «Transferencias» | **(a)**: cada perfil ve solo lo suyo (el despachador no ve «Por Recibir» y el receptor no ve «Despacho»), y el contador avisa a B sin entrar. Evita las palabras «Conduce» y «Recepción», que ya usa el menú para otras cosas (H2) | Nada en uso; ≈ 0,02 sp con el contador | ☐ (a) ☐ (b) |
| **UX-TI-02** | El despacho en edición (hasta 200 renglones) se puede perder si se cierra el navegador antes de despachar. ¿Se guarda? | (a) Borrador **local** en el navegador, sin efecto en el inventario ni número, que se ofrece al volver. (b) Sin borrador. (c) Borrador en el servidor («En preparación») | **(a)**: protege 10 minutos de lectura por ≈ 0,05 sp. (c) agrega un estado y una tabla que no están firmados; (b) obliga a volver a escanear todo | El borrador queda en ese navegador y en ese equipo. No guarda costos ni datos personales | ☐ (a) ☐ (b) ☐ (c) |
| **UX-TI-03** | En el tramo 1 (sin diferencias), ¿qué pasa si el receptor cuenta **más** de lo despachado en un renglón, o lee un artículo que no venía? | (a) Se recibe hasta lo pendiente; el excedente y los no esperados se muestran, quedan anotados en la bitácora de la recepción y se registran como sobrante con el registro de diferencias del tramo 2 (T-15). (b) La confirmación se rechaza hasta que el conteo no pase de lo pendiente | **(a)**: la mercancía que llegó entra sin bloquear la recepción, y el sobrante queda a la vista. Con (b), el receptor borra lecturas para poder confirmar y el sobrante desaparece | Con (a), del 1-nov al tramo 2, el sobrante está físicamente en B pero no en el sistema (hoy todo es desarrollo). ≈ 0,05 sp de servidor (C-9) | ☐ (a) ☐ (b) |
| **UX-TI-04** | ¿Qué es obligatorio al confirmar la salida? | (a) Transportista obligatorio y vehículo opcional. (b) Los dos opcionales. (c) Los dos obligatorios | **(a)**: la salida existe para saber a quién se entregó la mercancía (D7 de [TRF]); no todo traslado va en vehículo con placa (mensajero o a pie) | Nada en uso; 0 sp | ☐ (a) ☐ (b) ☐ (c) |
| **UX-TI-05** | Con conteo ciego, después de «Terminar conteo» se ven las cantidades esperadas. ¿Se puede volver a contar? | (a) Sí, solo en los renglones con diferencia, y esas lecturas quedan marcadas «después de ver lo esperado» en el reporte de diferencias. (b) No: se descarta el conteo y se empieza de nuevo. (c) Sí, sin marca | **(a)**: corrige un bulto que no se leyó sin repetir 200 renglones, y la marca conserva el control de R-09 | ≈ 0,03 sp (la marca sale de `TerminadaEn`) | ☐ (a) ☐ (b) ☐ (c) |
| **UX-TI-06** | En el traslado dentro de la misma sucursal (un paso), ¿se imprime algo? | (a) Opcional: el mismo PDF del conduce con el título «TRASLADO ENTRE ALMACENES». (b) Nada en el tramo 1 | **(a)**: [TRF] 2.6 prevé una «lista de traslado» para el almacenista; es el mismo formato con otro título | ≈ 0,02 sp en 3b-3 | ☐ (a) ☐ (b) |
| **UX-TI-07** | ¿Se muestran desde el tramo 1 «Salida sin confirmar» (más de 24 h) y «Tránsito vencido» (más del plazo, 2 días por omisión)? | (a) Sí, como indicadores en la lista y en el detalle, con los datos que ya trae el contrato. (b) Con los avisos de T6, en el tramo 3 | **(a)**: es la mitigación de R-03 y R-07 de [TRF]; los correos y la escalada siguen en T6 | ≈ 0,03 sp; sin servidor nuevo | ☐ (a) ☐ (b) |

---

## 11. Esfuerzo estimado de frontend (Web, tramo 1; inferido, ±40 %)

| Pieza | sp |
|---|---|
| `ApiClient` (rutas T-01 a T-14 y T-21), `VistaTransferencias` (textos por código y estados) | 0,10 |
| P-1 lista con vistas, filtros, paginación, indicadores y contador del menú | 0,12 |
| P-2 despacho: tabla, modos E/S, lote (con `SelectorLote`), series, faltantes, vencido, borrador local, idempotencia y resultado desconocido | 0,25 |
| P-3 detalle: pestañas, historial, conduce, confirmar salida, anular con supervisor | 0,12 |
| P-4 recepción: `ColaEscaneos` (EscaneoId, tandas, reintentos, `localStorage`), conteo optimista y ciego, varios usuarios, lecturas, terminar, «Resultado del Conteo», confirmar y descartar | 0,25 |
| Pruebas de `Vista*` y `ColaEscaneos` en `GPOS.Web.Tests` | 0,08 |
| **Total** | **0,92 (de 0,65 a 1,30)** |

- **Frente al plan:** el plan reservaba 0,60 sp para la Web. La diferencia (≈ +0,3 sp) sale sobre todo de la cola de lecturas sin conexión, del estado de resultado desconocido y del lote y las series en el despacho, que el plan no detallaba.
- **Opción más barata (≈ 0,75 sp):** sin borrador local (UX-TI-02 b, −0,05), sin sonidos (−0,02), sin refresco automático entre usuarios, solo con el botón «Actualizar» (−0,03), y con la lista sin la vista «Todas» hasta el tramo 2 (−0,03). **No recomiendo** quitar la cola de lecturas ni el estado de resultado desconocido: son la garantía visible de ADR-105.
- **Plan B del plan (F10 sin Web):** la prueba de API basta para que F10 cuente. Si el 23-oct la Web va atrasada, el orden es P-2 → P-4 → P-3 → P-1.
- **MAUI (tramo 2):** «Por Recibir» y la recepción con cámara: 0,5 sp según el plan; con el diseño de 3.6, de 0,4 a 0,55.
- **Costo de infraestructura y licencias:** USD 0. Los sonidos usan WebAudio del navegador, sin archivos ni librerías.

---

## Supuestos
1. La numeración 51440 a 51459 sigue el orden del DDL con +80 (inferido; C-8).
2. El despacho de un lote vencido se admite con motivo (D3 de [TRF]; supuesto del plan). PQ-2 rechaza solo el conduce a cliente `CON`.
3. Con `SalidaEnUnPaso = 1`, la salida se registra al despachar (P-T1 firmada) y la pantalla abre el conduce sola. La regla «sin conduce no hay salida» queda cubierta por esa impresión automática y por la bitácora `CONDUCE_IMPRESO`.
4. Si el despachador tiene `transfdespacho` Autorizar, el diálogo de supervisor le ofrece autorizar él mismo la anulación en tránsito, según la regla vigente de `VistaAutorizacionSupervisor.OfrecerPropio`. Lo decide el servidor.
5. `SelectorLote`, `DialogoElegirLote` y `DialogoFaltantes` los construye T4 de ADR-119 antes del 23-oct. Si no llegan, el despacho usa un campo de lote simple validado por el servidor (D-2).
6. Las fechas y cifras de tiempo son inferidas: no medí nada.

## Dependencias
- **D-1:** F-1 de ADR-119 (`ArticuloLinea.RequiereLote`) antes del 15-oct (C-11).
- **D-2:** componentes del lote de [UXL] (rama `b/adr118-119-t1`, unión prevista el 27-oct).
- **D-3:** contratos C-1, C-2, C-5, C-7 y C-9 congelados en el tramo 0 (14-oct).

## Decisiones candidatas a ADR
Ninguna. Son decisiones de pantalla dentro de lo firmado. UX-TI-03 precisa el comportamiento de T-13 en el tramo 1; si el propietario elige (a), es una nota de ADR-105, no un ADR nuevo.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\ux-transferencias.md`
- Supuestos: los de la sección «Supuestos» (1 a 6).
- Decisiones candidatas a ADR: Ninguna (UX-TI-03 sería una nota de ADR-105).
- Entregas a otros agentes: arquitecto-software (B) → C-1 a C-11 en `Transferencias.cs` y `CodigosTransferencia.cs` (tramo 0); constructor de T4 de ADR-119 y equipo C → modo `Transferencia` de `SelectorLote` y motivo `T` de `DialogoFaltantes` (C-3, C-4); 3b-3 (formato del conduce) → título «TRASLADO ENTRE ALMACENES» (UX-TI-06), «REIMPRESIÓN n» y «ANULADA»; desarrollador-frontend → las cuatro pantallas, los diálogos y `ColaEscaneos`; qa-automatizado → pruebas de `ColaEscaneos` (reenvío sin duplicar, recarga de página) y recorrido Web de F10 si cabe.
- Próximo paso recomendado: que el propietario firme UX-TI-01 a 07 y que el arquitecto-software de B congele C-1, C-2, C-5, C-7 y C-9 el 14-oct.
