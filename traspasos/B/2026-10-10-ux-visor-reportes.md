# Diseño UX/UI: visor de reportes (bloque 3.G del tramo 3 de la ola 5, ADR-109)

- **Fecha:** 2026-10-10 · **Autor:** diseñador UX/UI del equipo B · **Estado:** Completado (diseño); preguntas UX-V-01 a UX-V-08 **Pendientes de firma**.
- **Base revisada:** rama `b/ola5`, árbol `GPOS-B-ola5-construccion`, commit `c47d3b0` (solo lectura).
- **Alcance:** pantalla `Reportes de {Área}` (Web y MAUI), componentes `TablaReporte`, `FiltrosReporte` y `MenuExportar`. No cubre el diseñador de reportes (`admin/reportes`), salvo los códigos que comparte.
- **Firmas que rigen:** ADR-109 (cláusulas 4, 6, 8, 12 y 13), notas de aplicación del 2026-10-10 (P-1 a P-5, E1), D2 del tramo 3, D-04 (profundidad 50.000), ADR-111 cláusula 7 (evidencia), ADR-81 fase A (UX-81A, `401 REAUTENTICAR` sin cerrar la sesión), RG-30 (mayúsculas de título), ADR-52 (vocabulario de BP2).

---

## 0. Hallazgos del código (evidencia)

| # | Hallazgo | Evidencia | Consecuencia para el diseño |
|---|---|---|---|
| H1 | Los parámetros `OPCION` y `BOOLEANO` (y `ENTERO`) no se dibujan: `ColumnasDeFiltro` devuelve `null` para ellos | `src/GPOS.Contracts/Reportes/ReportesLectura.cs:66-83` | Sección 3.1. Hoy el usuario no puede pedir «Agrupar por Categoría» en el 5 ni «Incluir anulados» en el 7 |
| H2 | Parámetros reales: 17 «Agrupar por» (A, S, G, C; defecto A) e «Incluir existencia cero»; 20 «Saldo por almacén» e «Incluir artículos sin movimiento»; 5 «Agrupar por» (A, C; obligatorio, defecto A); 7 «Tipo de cierre» (Z, X, T; obligatorio, defecto Z) e «Incluir anulados» | `ReportesInventarioRegistrados.cs:23-27,53-59,196-202`; `ReportesVentasRegistrados.cs:41-44,62-67,186-189,225-229` | Hay 3 opciones y 5 Sí/No que dibujar en los 4 registrados de F9 |
| H3 | El servidor lee el Sí/No como texto (`true`/`1`/`sí` → sí; vacío/`false`/`no` → no) y la opción por código en mayúsculas; un valor fuera de la lista da 400 `PARAMETRO_INVALIDO` | `IReporteRegistrado.cs:249-273` | El control envía `Valor = "true"` o nada; la opción envía su `Codigo` |
| H4 | Página por omisión: 1.000 filas (`TamanoMaximo = 1000`); `Totales` se calculan solo en la página 1 si no se piden; profundidad máxima 50.000 (`salto + tamano`) → 422 `PAGINA_FUERA_DE_ALCANCE` | `src/GPOS.Contracts/Reportes/Inventario/ReportesInventario.cs:9`; `src/GPOS.Reportes/Ejecucion/PaginaPantalla.cs:17-35`; `OpcionesEjecutor.cs:56` | Sección 3.2 |
| H5 | En las páginas 2 y siguientes el servidor responde `TotalesCompletos = false` (no los calculó) y la tabla actual muestra «Total no disponible: resultado parcial.» aunque la página 1 sí los trajo | `TablaReporte.razor:44-49,98`; `ReportesVentasRegistrados.cs:300,315` | La interfaz **conserva** los totales de la página 1 (lo dice el propio contrato: «la interfaz los conserva al pasar de página», `PaginaPantalla.cs:13`) |
| H6 | `TotalFilas` solo lo llena el ejecutor del diseñador y solo con `contar=true`; el conteo sale en la misma consulta de los totales | `EjecutorDisenador.cs:93,397-407` | Pedir `contar=true` junto con los totales en la página 1 no cuesta otra consulta; los registrados no dan total de filas |
| H7 | Orden en el servidor: **una** columna visible (lista blanca) más el desempate interno; columnas `xml/text/image/geography` no ordenables (400). Los **registrados ignoran** `orden` (orden fijo) | `EjecutorDisenador.cs:292-321`; `ColumnaDescrita.cs:65`; ningún uso de `pagina.Orden` en `Definiciones/Registrados/` | Sección 3.3 |
| H8 | La principal reenvía la consulta (`QueryString`) tal cual; los reportes de la lista P-2 (8-10, 13-16, 21-23, 27) los ejecuta la principal, que **ignora** `pagina`, `orden` y `totales` y responde `Tamano = 0` con el tope de 10.000 | `src/GPOS.Api/Endpoints/ReportesEndpoints.cs:38-47`; `ReenvioReportes.cs:68-90` | El visor tiene **dos modos**: paginado en el servidor (`Tamano > 0`) y completo en memoria (`Tamano = 0`, como hoy) |
| H9 | Todo 401 se convierte en `SesionExpiradaException` y lleva al inicio de sesión; el motivo `cerrada` no tiene texto propio | `src/GPOS.Web/Servicios/ApiClient.cs:24-44,149-151` (igual en MAUI) | El 401 con `X-GPOS-Sesion: factor` hay que distinguirlo **antes** (sección 3.4.2) |
| H10 | La API de reportes envía `X-GPOS-Sesion: factor`; el blueprint de la fase A de ADR-81 usa `factor-requerido` para el mismo caso en la principal y lo lleva al inicio de sesión; además `/api/auth/reautenticar` conserva el mismo `amr` (no agrega `otp`) | `AutenticacionIntrospeccion.cs:57-64,80-82`; `ProtocoloIntrospeccion.cs:46-51`; rama `c/adr81-fase-a-diseno`: blueprint §5.4, I-1 (línea 190), UX P10 | **Contradicción** con el comportamiento pedido (confirmar sin cerrar la sesión). Ver C-1 y UX-V-01 |
| H11 | `PRIVILEGIO_REQUERIDO` de los registrados arma el mensaje con las **claves** del privilegio (`vercostos`, `vercuadrecaja`…), no con sus nombres | `src/GPOS.Reportes/Consultas/LectorRegistradas.cs:154-156` | El usuario leería «(vercostos)». Ver C-3 |
| H12 | Sin «Ver costos» las columnas de costo no llegan (`conValor = false`); sin «Ver cuadre de caja» el 7 llega sin esperado/declarado/diferencia (`cuadre = false`); no hay metadato para «Ver datos personales» | `ReportesVentasRegistrados.cs:151,316`; `ReportesInventarioRegistrados.cs:136,275`; `ServicioReportes.cs:60` | Leyenda bajo el título (sección 3.5); C-6 para datos personales |
| H13 | El metadato `totales` tiene dos usos: estado («no disponibles», el cálculo agotó el tiempo) y leyenda («Cierres Z no anulados del filtro») | `EjecutorDisenador.cs:409-413`; `ReportesVentasRegistrados.cs:316` | Ver C-4 |
| H14 | La pantalla no muestra los `Metadatos`, aunque el RNC es el «encabezado de evidencia en pantalla (ADR-111, cláusula 7), nunca omitido» | `IReporteRegistrado.cs:99-101`; `EjecutorDisenador.cs:74`; `TablaReporte.razor` sin `Metadatos` | La cabecera del resultado muestra el RNC (sección 3.5) |
| H15 | La exportación Web se baja con un enlace `<a download>` al proxy `/reporte/{id}/{formato}`, que **no copia** `X-GPOS-Renglones` ni `X-GPOS-Huella-Datos`; un error llega al navegador como un archivo o una página con el JSON del problema. MAUI baja con `ApiClient.DescargarAsync` (sí podría leerlos) | `src/GPOS.Web/Program.cs:154-180`; `wwwroot/js/gpos.js:18-25`; `GPOS.UI.MAUI/Servicios/ArchivosNativos.cs:8-12` | Ver 3.6 y C-2 |
| H16 | `RutaExportacion` no envía `orden`/`desc`, que la API sí acepta | `ApiClient.Modulos.cs:376-378`; `EndpointsReportes.cs:68-70` | La exportación saldría en otro orden que la pantalla |
| H17 | `ApiException` no conserva `Retry-After`; los 429 (`LIMITE_PETICIONES`, `REPORTE_EN_CURSO`, `REPORTES_OCUPADOS`, `EXPORTACIONES_EN_CURSO`) lo traen | `ApiClient.cs:10-19`; `ErroresReportes.cs:36-37`; `ReenvioReportes.cs:58` (se copia) | Cuenta regresiva en el botón (sección 3.4) |
| H18 | Los errores se muestran con `Snackbar` (8 s) y los de regla con diálogo; los componentes de Web y MAUI son copias idénticas | `PaginaBase.cs:111-187`; H13 del diseño UX-81A | Se sigue el patrón; cada componente nuevo va en los dos proyectos |
| H19 | El privilegio de exportar se llama «Exportar reportes (CSV y Excel)», pero el servidor lo exige para **todos** los formatos, PDF incluido | `src/GPOS.Contracts/Seguridad/Permisos.cs:259`; `ServicioReportes.cs:113` | Ver UX-V-05 |

---

## 1. Objetivo y usuarios

**Objetivo.** Que el ADMIN, el supervisor y el usuario de oficina ejecuten los reportes 1, 5, 7, 17, 18 y 20 de F9 (y los demás del área) con todos sus parámetros, recorran resultados grandes sin bajar 10.000 filas de golpe, ordenen en el servidor y exporten un CSV con evidencia, entendiendo siempre por qué algo falla y qué hacer.

| Usuario | Dispositivo | Tarea típica | Meta de tiempo |
|---|---|---|---|
| ADMIN / dueño | PC (Web), teclado y ratón | Ventas por artículo con utilidad del mes, por categoría; exportar a CSV | Abrir, cambiar «Agrupar por» y ejecutar en ≤ 3 interacciones; resultado en ≤ 5 s con 10.000 artículos (la consulta tiene su tope de 30 s) |
| Supervisor de caja | PC o tableta MAUI | Cierres de caja Z de ayer, con anulados | ≤ 4 toques desde la lista |
| Encargado de almacén | Tableta MAUI (táctil) | Kárdex de un artículo; existencias por almacén | Ordenar y pasar de página con objetivos táctiles de 48 px |
| Usuario sin privilegios sensibles | PC | Ver el reporte sin costos ni cuadre | Entender en una línea qué no ve y por qué |

---

## 2. Flujos de interacción

### 2.1 Ejecutar con parámetros

```
[Lista del área] ─ elegir ─> [Reporte: filtros desplegados con valores por omisión]
   ─ ajustar (fecha, catálogo, opción, Sí/No) ─ Ejecutar / Enter ─> [Cargando… · botón Cancelar (Esc)]
       ├─ 200 con filas ─> [Resultado, página 1, filtros plegados, totales] 
       ├─ 200 sin filas ─> [Vacío, filtros desplegados]
       ├─ 4xx de filtro (FILTRO_REQUERIDO, PARAMETRO_INVALIDO, 413, 422) ─> [filtros desplegados, aviso, resultado anterior conservado]
       ├─ 429 con Retry-After ─> [botón «Ejecutar (12 s)» deshabilitado con cuenta regresiva]
       ├─ 401 factor ─> [Confirmar su Identidad] ─ código ─> se repite la ejecución UNA vez
       └─ 503 ─> [Aviso en el panel con Reintentar]
```

### 2.2 Paginar (modo servidor, `Tamano > 0`)

```
[Página 1: totales y conteo] ─ Siguiente ─> [Página 2: los totales de la página 1 se conservan]
   ─ … ─> [última: HayMas = false, Siguiente deshabilitado]
   ─ Siguiente cuando (página × tamaño) + tamaño > 50.000 ─> deshabilitado de antemano si se conoce la profundidad;
       si no, 422 PAGINA_FUERA_DE_ALCANCE ─> se queda en la página actual con aviso en la barra de páginas
[Cambiar filtros, campos o parámetros y Ejecutar] ─> vuelve a la página 1 (totales nuevos)
[Cambiar tamaño de página] ─> página 1, sin recalcular totales si la consulta no cambió
```

### 2.3 Ordenar

```
Diseñador (SQL) en la API de reportes: clic en encabezado ─> ascendente ─> descendente ─> orden del reporte (sin indicador propio)
   cada cambio pide la página 1 con totales=false (los totales no dependen del orden; se conservan)
Registrado (REG): encabezados sin orden; tooltip «Este reporte tiene un orden fijo».
Modo completo (principal, Tamano = 0): orden en memoria, como hoy.
```

### 2.4 Exportar con evidencia

```
Exportar ▸ CSV ─> [Preparando la exportación… (en el botón)]
   ├─ 200 ─> archivo descargado (Web) / compartido o guardado (MAUI)
   │        └─ aviso: «Exportación lista: 1.234 renglones. Huella de los datos: 3F2A9C1D…7B04E6A2.» [Copiar huella]
   ├─ 403 PRIVILEGIO_REQUERIDO ─> no ocurre si el menú está deshabilitado; si llega, aviso
   ├─ 429 EXPORTACIONES_EN_CURSO ─> aviso con el tiempo de espera
   ├─ 503 EXPORTACION_NO_DISPONIBLE / REPORTES_NO_DISPONIBLE ─> aviso de error
   └─ corte de la descarga (EXPORTACION_VENCIDA en el registro) ─> «La descarga se interrumpió. Intente de nuevo.»
```

### 2.5 Sesión y segundo factor

```
401 + X-GPOS-Sesion revocada | reemplazada | cerrada | cuenta-inhabilitada | credenciales ─> inicio de sesión con el motivo (como hoy)
401 + X-GPOS-Sesion factor (o factor-requerido, ver C-1) ─> [Confirmar su Identidad] (DialogoConfirmarIdentidad de UX-81A P6)
     ├─ código válido ─> token con otp, misma sesión ─> se repite la petición UNA vez
     ├─ Cancelar ─> «No se ejecutó el reporte: no se confirmó su identidad.» (la sesión sigue)
     └─ la repetición vuelve a dar 401 factor ─> inicio de sesión con motivo «factor»
```

---

## 3. Pantallas y controles

### 3.0 Wireframe general (Web, ≥ 960 px)

```
Reportes de Ventas                                                     [Diseñador]   ← RG-30 (hoy «Reportes de ventas»)
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ [≡] Ventas por artículo con utilidad          [Campos (7)] [Exportar ▾] [▶ Ejecutar]        │
│ Nota del reporte (caption)                                                                  │
│ [▾ Filtros]  3 aplicados: Período, Agrupar por, Sucursal                                    │
│ ┌──────────────────────────────────────────────────────────────────────────────────────┐   │
│ │ Período desde [01/10/2026] hasta [10/10/2026]   Sucursal [Todas ▾]  Categoría [   ▾] │   │
│ │ Artículo [      ▾]  Vendedor [     ▾]   Agrupar por * [Artículo ▾]                   │   │
│ │ ( ) Incluir anulados   ← Sí/No: interruptor (en el 7)                                │   │
│ └──────────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ RNC 1-01-12345-6 · Moneda base · Sin costos: su usuario no tiene «Ver costos».   ← cabecera│
│ Código ▲ │ Descripción │ Cantidad │ Venta      │ Costo │ Utilidad │ Margen %             │
│ A-0001   │ Arroz 5 lb  │   120,00 │  18.000,00 │  …    │  …       │  …                   │
│ …                                                                                          │
│ Total (3.450 filas)    │          │ 9.870,00 │ 1.234.567,00 │ …                            │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│ Filas por página [500 ▾]     Filas 501–1.000 de 3.450     [|‹ Primera] [‹ Anterior] 2 [Siguiente ›] │
└────────────────────────────────────────────────────────────────────────────────────────────┘
▸ Totales por categoría   ▸ Conteo por forma de pago      ← anexos plegables (ya hechos)
```

### 3.1 Parámetros de opción y Sí/No (registrados)

**Regla de construcción.** `FiltrosReporte` recibe, además de las columnas, la lista `ReporteDto.Parametros` de un registrado y dibuja **cada parámetro en el orden de la lista** (`Orden = i + 1`), sin pasar las opciones y los Sí/No por `ReporteColumnaDto` (no tienen tipo de columna que los represente). Los de fecha y catálogo siguen con su control actual.

| Tipo | Control (Web y MAUI) | Valor inicial | Envío | Reglas |
|---|---|---|---|---|
| `OPCION` | `MudSelect<string>` denso, `Variant.Outlined`, etiqueta `Etiqueta` + « *» si `Obligatorio`; ancho `xs=12 sm=6 md=3` como los catálogos | `Defecto`; si no hay defecto y no es obligatorio, «(Todas)» | `FiltroReporte { Campo, Valor = Codigo }`; **siempre** se envía el valor elegido, también el de omisión, para que la evidencia lo liste | Obligatorio: sin opción vacía ni `Clearable`. No obligatorio: primera opción «(Todas)» = sin filtro. Muestra la `Descripcion`, nunca el código. Si la opción cambia las columnas (17 «Agrupar por»), el resultado anterior se marca «Desactualizado: ejecute de nuevo.» y no se pagina sobre él |
| `BOOLEANO` | `MudSwitch<bool>` con la etiqueta a la derecha, `Color.Primary`; en MAUI fila completa tocable de 48 px | Apagado (el servidor trata la ausencia como No) | Encendido: `Valor = "true"`; apagado: no se envía (filtro vacío) | El texto no cambia con el estado («Incluir anulados», no «Sí/No»); el estado lo dicen la posición y `aria-checked`. Va en una fila propia debajo de los selectores |
| `ENTERO` (ningún registrado lo usa hoy) | `MudNumericField<int?>`, `HideSpinButtons` | `Defecto` si es número | `Valor` en texto invariable | Se dibuja para no volver a dejar un tipo sin control; mínimo/máximo no están en el contrato |

- **Resumen junto a «Filtros»:** cuenta opciones y Sí/No encendidos: «3 aplicados: Período, Agrupar por (Categoría), Incluir anulados». El Sí/No apagado no cuenta.
- **Restablecer:** el botón «Restablecer» existente del panel de campos no toca los filtros; se agrega en el panel de filtros un botón de texto «Valores por omisión» que repone fechas, opciones y Sí/No.
- **Inicial:** `FiltrosReporte.Iniciales` pasa a sembrar también `OPCION` (con `Defecto`) y `BOOLEANO` (vacío). Es un cambio de código en `GPOS.Contracts` (`FiltrosRegistrados`), no del contrato JSON.

### 3.2 Paginación

**Modos.** El visor decide el modo por la respuesta, no por el reporte:

| Modo | Cuándo | Barra de páginas | Orden | Totales |
|---|---|---|---|---|
| **Servidor** | `Resultado.Tamano > 0` (API de reportes) | La de 3.2.1 | En el servidor (3.3) | Los de la página 1, conservados (3.2.3) |
| **Completo** | `Tamano = 0` (la principal: lista P-2, o instalación sin la API de reportes) | La paginación en memoria actual de `MudTablePager` (25/50/100/500) | En memoria (como hoy) | Como hoy; con `Truncado`, D2 |

#### 3.2.1 Barra de páginas (modo servidor)

```
Filas por página [500 ▾]    Filas 501–1.000 de 3.450        [|‹ Primera] [‹ Anterior]  Página 2  [Siguiente ›]
Filas por página [500 ▾]    Filas 501–1.000 · hay más       (registrados: sin total de filas)
```

| Elemento | Regla |
|---|---|
| Tamaño | Opciones **100, 250, 500, 1.000**. Por omisión **500** en Web y tableta, **100** en MAUI con ancho < 600 px (UX-V-02). Se recuerda por usuario y dispositivo (almacenamiento local), no por reporte. Cambiarlo pide la página 1 con `totales=false` si la consulta no cambió |
| Texto de posición | Con `TotalFilas`: «Filas {desde}–{hasta} de {total}». Sin él: «Filas {desde}–{hasta}» y, si `HayMas`, «· hay más». Números con separador de miles (`N0`) |
| Primera | Deshabilitada en la página 1 |
| Anterior | Deshabilitada en la página 1 |
| Página N | Texto, no editable: sin total de páginas no se ofrece saltar a una página arbitraria (cada salto profundo cuesta un `OFFSET`) |
| Siguiente | Deshabilitada si `HayMas = false`, o si `Pagina × Tamano + Tamano > profundidad` cuando la profundidad se conoce (C-5). En ese caso el tooltip dice: «En pantalla se pueden recorrer las primeras 50.000 filas. Agregue filtros o exporte el reporte.» |
| Durante la carga | Botones deshabilitados, barra de progreso lineal sobre la tabla; la tabla anterior queda visible y atenuada (no se vacía) |
| Petición | `POST …/ejecutar?pagina=N&tamano=T` con los **mismos** filtros, campos y orden de la página 1 (la interfaz guarda la «firma» de la consulta: filtros + campos + parámetros). Si el usuario cambió un filtro sin ejecutar, «Siguiente» ejecuta con la firma guardada y el resumen dice «Filtros modificados sin ejecutar» |

- El aviso actual «Se muestran las primeras N filas; hay más. Acote los filtros o exporte el reporte para verlas todas.» **se retira** en el modo servidor (la barra lo sustituye); en el modo completo con `Truncado` se mantiene el de hoy.
- Dentro de una página del servidor la tabla **no** pagina en memoria: muestra todas las filas de la página con `Virtualize="true"` (alto fijo de fila, encabezado y pie fijos). Motivo: dos niveles de paginación confunden y el pie con totales debe quedar a la vista.

#### 3.2.2 `PAGINA_FUERA_DE_ALCANCE` (422)

- Se queda en la página actual (no se borra la tabla). Mensaje en línea, debajo de la barra, con `Severity.Warning`: el texto del servidor («En pantalla se pueden recorrer las primeras 50.000 filas. Agregue filtros o exporte el reporte.») y dos acciones: **[Ver filtros]** (despliega el panel y enfoca el primer filtro) y **[Exportar ▾]** (si tiene el privilegio).
- «Siguiente» queda deshabilitado para esa firma de consulta.

#### 3.2.3 Totales al paginar (relación con D2)

| Situación | Pie de la tabla |
|---|---|
| Página 1 con `TotalesCompletos = true` | Totales del servidor; «Total ({TotalFilas} filas)» si hay conteo, «Total» si no. **Nunca** `Filas.Count` (es la página, no el resultado) |
| Página ≥ 2, misma firma, totales de la página 1 conservados | Los mismos totales, idénticos; leyenda en el pie: «Totales de todo el resultado» |
| Página ≥ 2 sin totales conservados (p. ej. se restauró el estado al volver de un documento en la página 3) | Se piden con `totales=true` en esa petición (no se suma la página) |
| `TotalesCompletos = false` y `HayMas = true` (no se pidieron o no se pudieron calcular) | **D2:** «Total no disponible: resultado parcial.» |
| `totales = "no disponibles"` (el cálculo agotó el tiempo o el costo, C-4) | «Total no disponible: el cálculo superó el tiempo máximo. Agregue filtros para verlo.» (UX-V-03) |
| `TotalesCompletos = false` y `HayMas = false` en la página 1 | Suma en memoria permitida (es el resultado entero), como hoy |
| Modo completo con `Truncado` | D2 como hoy |
| Leyenda del servidor (`totales` con otro texto, p. ej. «Cierres Z no anulados del filtro») | Se muestra como nota bajo el pie, en `caption` |

- Peticiones: página 1 → `totales=true&contar=true` (el conteo sale en la misma consulta de totales, H6). Páginas siguientes, cambio de orden o de tamaño → `totales=false` mientras la firma no cambie.

### 3.3 Orden en el servidor

| Regla | Detalle |
|---|---|
| Qué reportes | Solo los del diseñador (`Fuente = SQL`) ejecutados en la API de reportes (modo servidor). Los registrados (`REG`) tienen orden fijo; el modo completo ordena en memoria |
| Qué columnas | Las visibles del resultado. Si C-5 agrega `Ordenable`, las que no lo son no muestran el control. Sin C-5, se ofrece en todas y un 400 `PARAMETRO_INVALIDO` («La columna "X" no se puede ordenar.») revierte el indicador y se muestra como aviso |
| Ciclo del clic | Sin orden propio → **ascendente** (▲) → **descendente** (▼) → vuelve al orden del reporte (`OrdenarPor`/`OrdenDescendente` de la definición, que el encabezado muestra con un indicador gris) |
| Orden múltiple | **No** (UX-V-04). El servidor acepta una sola columna más su desempate interno; Mayús+clic no hace nada distinto |
| Petición | `?orden={Campo}&desc={true|false}&pagina=1&totales=false`. Al cambiar el orden **siempre** se vuelve a la página 1 |
| Indicador | `MudTableSortLabel` controlado (no el orden en memoria de `MudTable`): flecha y `aria-sort="ascending|descending|none"` en el `<th>` |
| Registrados | Encabezado sin cursor de mano ni flecha; `title`/tooltip en el título de la tabla: «Este reporte tiene un orden fijo.» (una vez, no por columna) |
| Exportación | Lleva el mismo `orden` y `desc` (C-7, H16) |
| Columnas ocultas por privilegio | No llegan; no se pueden ordenar (lo garantiza el servidor) |

### 3.4 Textos por código

#### 3.4.1 Reglas de presentación

| Clase | Presentación | Dónde |
|---|---|---|
| **De filtro** (corrige el usuario) | Aviso en línea, `MudAlert Severity.Warning` denso, **dentro del panel de filtros** desplegado, con `role="alert"`; el resultado anterior se conserva | 400 `PARAMETRO_INVALIDO`, 413, 422 (salvo página), 403 `SUCURSAL_NO_PERMITIDA` |
| **Pasajero** (reintentar) | `Snackbar` amarillo 8 s + botón **[Reintentar]** en el aviso; con `Retry-After`, cuenta regresiva en el botón Ejecutar | 409, 429 |
| **De acceso** | Aviso en el panel del resultado, `Severity.Info` (privilegio) o `Warning` (reporte/empresa); sin reintentar | 403, 404 |
| **De servicio** | Aviso en el panel del resultado, `Severity.Error`, con [Reintentar] y la línea «Si persiste, avise al administrador.» | 503 |
| **De sesión** | Navegación al inicio de sesión con motivo, o diálogo de identidad | 401 |

- `ApiClient` (Web y MAUI) agrega `RetryAfter` (`TimeSpan?`) a `ApiException` (cambio de cliente, no del contrato).
- El visor usa el `detail` del servidor cuando la tabla lo indica («servidor»); cuando propone un texto propio es porque el del servidor no sirve en pantalla.

#### 3.4.2 Tabla de códigos

| HTTP | Código / encabezado | Origen | Texto en pantalla | Acción / comportamiento |
|---|---|---|---|---|
| 400 | `PARAMETRO_INVALIDO` | API reportes | Servidor (p. ej. «El valor del filtro "Agrupar por" no es una de sus opciones.») | De filtro. Si vino de un orden: revierte el indicador |
| 400 | `REPORTE_ERROR_CONSULTA` | API reportes | ADMIN: servidor + «Revise la consulta en el Diseñador.» con [Abrir en el Diseñador]. Otros: «El reporte no se pudo ejecutar por un error en su definición. Avise al administrador.» | Error, sin reintentar. Motivo: el texto del motor puede traer nombres internos |
| 400 | `CONSULTA_NO_PERMITIDA` | API reportes (diseñador) | Servidor (lista de rechazos, una por línea) | Solo en el diseñador |
| 401 | `X-GPOS-Sesion: revocada` | ambas | «Un administrador actualizó su sesión. Vuelva a iniciar sesión para continuar.» (existente) | Inicio de sesión |
| 401 | `X-GPOS-Sesion: reemplazada` | ambas | «Su usuario inició sesión en otro equipo o navegador; esta sesión se cerró.» (existente) | Inicio de sesión |
| 401 | `X-GPOS-Sesion: cerrada` | API reportes | **Nuevo:** «Su sesión se cerró. Vuelva a iniciar sesión.» | Inicio de sesión (`motivo=cerrada`) |
| 401 | `X-GPOS-Sesion: factor` (o `factor-requerido`, C-1) | API reportes (E1) / principal (ADR-81) | Diálogo **Confirmar su Identidad** (UX-81A P6): «Para ver reportes, el Super Usuario debe confirmar su verificación en dos pasos. Escriba el código de su aplicación (GPOS NG – {instalación}:{usuario}).» | No cierra la sesión. Éxito: repite la petición una vez. Cancelar: «No se ejecutó el reporte: no se confirmó su identidad.» Segundo 401 factor tras confirmar: inicio de sesión con «Su usuario ahora requiere la verificación en dos pasos. Vuelva a iniciar sesión.» **Depende de C-1** |
| 401 | `REAUTENTICAR` (sin encabezado) | principal (ADR-81) | Diálogo P6 tal como lo diseñó UX-81A | Ningún reporte es acción sensible hoy; se cubre por el camino común de `PaginaBase` |
| 401 | sin encabezado | ambas | «La sesión expiró. Vuelva a iniciar sesión.» (existente) | Inicio de sesión |
| 403 | `EMPRESA_NO_PERMITIDA` | API reportes | Servidor: «Su usuario no tiene acceso a esta empresa.» | Aviso de página completa con [Cambiar empresa] |
| 403 | `REPORTE_NO_PERMITIDO` | API reportes | Servidor: «Su usuario no tiene acceso a este reporte.» | Aviso en el panel; se recarga la lista del área |
| 403 | `PRIVILEGIO_REQUERIDO` (vista `rptc`) | API reportes | «Este reporte necesita el privilegio {nombres}. Pídalo al administrador.» con nombres del catálogo: «Ver costos», «Ver cuadre de caja», «Ver datos personales» | Info en el panel. Requiere C-3 (hoy el servidor da las claves) |
| 403 | `PRIVILEGIO_REQUERIDO` (exportar) | API reportes | Servidor: «Su usuario no tiene el privilegio de exportar reportes.» | No debería verse: el menú Exportar está deshabilitado sin el privilegio (3.6) |
| 403 | `SUCURSAL_NO_PERMITIDA` | API reportes | Servidor (dos variantes: «Su usuario solo puede consultar los datos de su sucursal.» / la de D-03) | De filtro; el selector de sucursal de un usuario restringido viene fijado en la suya y deshabilitado |
| 403 | `DISENO_NO_PERMITIDO` | API reportes | Servidor | Solo diseñador |
| 403 | sin cuerpo | principal | «Su usuario no tiene permiso para esta operación.» (existente) | — |
| 404 | `REPORTE_NO_EXISTE` | API reportes | «Este reporte ya no existe; puede que lo hayan eliminado.» | Se vuelve a la lista del área y se recarga |
| 408 | `EXPORTACION_VENCIDA` (solo registro; la conexión se corta) | API reportes | «La descarga se interrumpió. Intente de nuevo.» | Se detecta por el corte de la descarga |
| 409 | `REPORTE_BLOQUEADO` | API reportes | Servidor («…se detuvo para no demorarla. Intente de nuevo en unos segundos.») | Pasajero con [Reintentar] |
| 413 | `REPORTE_DEMASIADO_GRANDE` | API reportes | Servidor | De filtro |
| 422 | `REPORTE_TIEMPO_AGOTADO` | API reportes | Servidor | De filtro; enfoca el rango de fechas |
| 422 | `REPORTE_DEMASIADO_COSTOSO` | API reportes | Servidor | De filtro |
| 422 | `FILTRO_REQUERIDO` | API reportes | Servidor (p. ej. artículo o categoría en el kárdex) | De filtro; resalta los selectores de artículo y categoría con borde de error |
| 422 | `PAGINA_FUERA_DE_ALCANCE` | API reportes | Servidor | 3.2.2 |
| 429 | `LIMITE_PETICIONES` | API reportes | Servidor («Demasiados reportes seguidos. Espere N segundo(s)…») | Cuenta regresiva en Ejecutar y en la barra de páginas |
| 429 | (sin código) «Demasiadas solicitudes» | principal | Servidor | Igual, con `Retry-After` |
| 429 | `REPORTE_EN_CURSO` | API reportes | Servidor | Cuenta regresiva. Suele pasar al cancelar y ejecutar de nuevo enseguida |
| 429 | `REPORTES_OCUPADOS` | API reportes | Servidor | Cuenta regresiva |
| 429 | `EXPORTACIONES_EN_CURSO` | API reportes | Servidor | El menú Exportar muestra la espera |
| 503 | `REPORTES_NO_DISPONIBLE` | principal (reenvío, P-2) | Servidor: «Los reportes no están disponibles en este momento. Intente de nuevo en unos minutos o avise al administrador.» | De servicio. Los reportes de la lista P-2 (ejecutados por la principal) siguen funcionando: el aviso no bloquea la lista |
| 503 | `SISTEMA_NO_DISPONIBLE` | API reportes | Servidor | De servicio |
| 503 | `PRINCIPAL_NO_DISPONIBLE` | API reportes | «Los reportes no pudieron verificar su sesión. Intente de nuevo en unos segundos.» | De servicio; **nunca** cierra la sesión |
| 503 | `CREDENCIALES_LECTURA_PENDIENTES` | API reportes | Servidor («…todavía no están configurados en este servidor. Avise al administrador.») | De servicio, sin [Reintentar] |
| 503 | `CONEXION_LECTURA_NO_SEGURA` | API reportes | Servidor | De servicio, sin [Reintentar] |
| 503 | `CONTRATO_VISTAS_PENDIENTE` | API reportes | Servidor | De servicio, sin [Reintentar] |
| 503 | `ESQUEMA_PENDIENTE` | API reportes (SUPER en modo limitado) | Servidor | De servicio; no cierra la sesión |
| 503 | `EXPORTACION_NO_DISPONIBLE` | API reportes | Servidor | Aviso en el menú Exportar |
| — | `HttpRequestException` / sin respuesta | cliente | «No se pudo contactar el servidor de la aplicación.» (existente) | Estado sin conexión (sección 4) |
| — | Tiempo de espera del cliente (`TaskCanceledException`) | cliente | «El servidor tardó demasiado en responder.» (existente) | Pasajero con [Reintentar] |

> Ningún texto menciona comprobantes; la regla de no sugerir «No generar comprobante» no se ve afectada.

### 3.5 Cabecera del resultado (evidencia y privilegios)

Línea `Typo.caption` entre el gráfico y la tabla, separada por « · »:

1. **RNC** (`Metadatos["rnc"]`), siempre que venga (ADR-111 cláusula 7, H14).
2. **Moneda** si `Metadatos["moneda"] = "base"`: «Moneda base».
3. **Aviso** (`Metadatos["aviso"]`, p. ej. «A fin de mes con almacén o sucursal solo se muestran cantidades.»): en su propio `MudAlert Severity.Info` denso.
4. **Privilegios** (sin botón, no son errores):
   - `conValor = "false"`: «Sin costos: su usuario no tiene «Ver costos».»
   - `cuadre = "false"`: «Sin cuadre: su usuario no tiene «Ver cuadre de caja».»
   - datos personales abreviados (C-6): «Identificaciones abreviadas: su usuario no tiene «Ver datos personales».»
5. **Filtros aplicados** (`FiltrosAplicados`): ya están en el resumen de «Filtros»; no se repiten.

### 3.6 Exportar

| Regla | Detalle |
|---|---|
| Privilegio | Sin `rptexportar` (`Info.Tiene(Permisos.ReportesExportar)`), el botón **Exportar** queda deshabilitado con tooltip «Su usuario no tiene el privilegio «Exportar reportes».» (UX-V-05 sobre el PDF) |
| Qué exporta | Los filtros **ejecutados** (la firma), los campos y el orden actuales (C-7). Si hay filtros modificados sin ejecutar, se pregunta: «Los filtros cambiaron y no se han ejecutado. ¿Exportar con los filtros del resultado en pantalla?» [Exportar el resultado] [Cancelar] |
| Durante | El botón muestra «Preparando…» con progreso circular y queda deshabilitado; Ejecutar sigue disponible |
| Éxito con evidencia | `Snackbar` verde, 12 s, con acción [Copiar huella]: «Exportación lista: {Renglones:N0} renglones. Huella de los datos: {primeros 8}…{últimos 8}.» La huella completa va en el portapapeles y en el `title`. Requiere C-2 |
| Web | Descarga por `ApiClient` en el circuito y entrega al navegador por `DotNetStreamReference` (función JS nueva `gpos.descargarFlujo`), en lugar del enlace al proxy: así se leen los encabezados y un error se muestra como aviso y no como archivo (H15). El PDF sigue abriéndose en pestaña nueva (`gpos.imprimir`) |
| MAUI | Igual que hoy (`ArchivosNativos.DescargarUrl` → compartir/guardar), devolviendo además los encabezados para el aviso |
| Modo completo (P-2) | La principal no envía evidencia: el aviso dice solo «Exportación lista.» |

### 3.7 Cancelar una ejecución

Mientras se ejecuta, el botón **Ejecutar** se convierte en **Cancelar** (icono `Stop`, `Color.Default`) y `Esc` cancela. Se cancela el `CancellationToken` de la petición; la API de reportes cancela el comando en el motor. Texto: «Ejecución cancelada.» (Snackbar normal, 4 s). Se conserva el resultado anterior.

### 3.8 MAUI (táctil)

```
┌────────────────────────────── 360–600 px ──┐
│ ‹ Reportes de Inventario                   │
│ Movimientos (kárdex)            [⋮]        │ ← ⋮ = Campos, Exportar, Valores por omisión
│ [▾ Filtros] 2 aplicados: Período, Artículo │
│ ┌────────────────────────────────────────┐ │
│ │ Período desde [01/10/2026]             │ │
│ │ hasta         [10/10/2026]             │ │
│ │ Artículo      [A-0001 Arroz 5 lb  ▾]   │ │
│ │ Saldo por almacén              (●  )   │ │ ← fila entera tocable, 48 px
│ │ Incluir sin movimiento         (  ○)   │ │
│ └────────────────────────────────────────┘ │
│ RNC 1-01-12345-6                           │
│ ← tabla con desplazamiento horizontal →    │
│ Total                       …              │
├────────────────────────────────────────────┤
│ Filas 101–200 · hay más                    │
│ [ ‹ Anterior ]   Pág. 2   [ Siguiente › ]  │ ← fija abajo, botones de 48 px
├────────────────────────────────────────────┤
│            [ ▶ Ejecutar ]                  │ ← botón ancho, fijo, encima del teclado
└────────────────────────────────────────────┘
```

- Objetivos táctiles ≥ 48 × 48 px (encabezados ordenables incluidos: alto de fila de encabezado 48 px).
- Con ancho < 600 px: lista de reportes en pantalla aparte (no lateral); «Primera» se oculta (queda Anterior/Siguiente); tamaño 100 por omisión; Campos y Exportar van al menú ⋮.
- Exportar: hoja de compartir del sistema (existente).
- Filtros: tras ejecutar con filas se pliegan (como hoy); el teclado en pantalla no tapa Ejecutar (botón fijo con `env(safe-area-inset-bottom)`).
- Sin gestos ocultos (sin deslizar para paginar): todo con botones visibles.

---

## 4. Estados por pantalla

| Estado | Qué se ve | Notas |
|---|---|---|
| **Sin reporte elegido** | «Seleccione un reporte.» (existente) | — |
| **Lista vacía** | «No hay reportes en esta área» (existente) | — |
| **Carga de la definición** | Esqueleto (`MudSkeleton`) de 2 filas de filtros | Hoy no hay indicador |
| **Ejecutando** | Barra lineal indeterminada; Ejecutar → Cancelar; tabla anterior atenuada (`opacity .5`, `aria-busy="true"`); tras 5 s, texto «Ejecutando… puede tardar hasta 30 segundos.» | El tope de 30 s es de ADR-38 M-2 |
| **Paginando / reordenando** | Barra lineal sobre la tabla; barra de páginas deshabilitada; filas anteriores atenuadas | No se vacía la tabla |
| **Resultado** | Cabecera (3.5), tabla, pie, barra de páginas, anexos | — |
| **Vacío** | «El reporte no devolvió filas con los filtros indicados.» (existente) + filtros desplegados + botón de texto [Valores por omisión] | — |
| **Resultado parcial** | Modo servidor: barra con «hay más» y totales de todo el resultado o D2. Modo completo: aviso actual de las 10.000 filas + D2 | D2 vigente |
| **Desactualizado** | Al cambiar un parámetro que altera las columnas o al cambiar filtros sin ejecutar: chip «Filtros modificados sin ejecutar» junto al resumen; paginar y exportar usan la firma ejecutada | — |
| **Error de filtro** | Aviso en el panel de filtros desplegado; resultado anterior visible | 3.4.1 |
| **Sin permisos** | Área: «Su usuario no tiene acceso a los reportes de {área}.» (existente). Reporte: aviso de 403 en el panel. Privilegios parciales: leyenda 3.5 | — |
| **Servicio no disponible (503)** | Aviso de error en el panel con [Reintentar] (salvo los de instalación) | La lista P-2 sigue usable |
| **Sin conexión** | Web: modal de reconexión de Blazor (existente) y, si la API no responde, «No se pudo contactar el servidor de la aplicación.» con [Reintentar]. MAUI: indicador de `VerificacionApi` (existente) y el mismo aviso. **Los reportes no funcionan sin conexión** (no hay caché local de resultados; los datos en pantalla se conservan para leerlos, con la marca «Sin conexión: los datos pueden no estar al día.») | Sin cola sin conexión: un reporte es lectura |
| **Espera por ritmo (429)** | «Ejecutar (12 s)» deshabilitado con cuenta regresiva; al llegar a 0 se habilita solo | No reintenta solo |
| **Identidad por confirmar** | Diálogo P6 sobre la pantalla; la pantalla queda intacta detrás | 2.5 |

---

## 5. Componentes y sistema de diseño

| Componente | Acción | Notas |
|---|---|---|
| `FiltrosReporte` | **Extender**: parámetro `Parametros` (lista de `ParametroReporteDto`), controles de 3.1, botón «Valores por omisión» | Web y MAUI (copias idénticas) |
| `FiltrosRegistrados` (`GPOS.Contracts`) | **Extender**: `Iniciales(def)` siembra opción y Sí/No | Código compartido, no contrato JSON |
| `TablaReporte` | **Extender**: modo servidor (orden controlado, `Virtualize`, sin paginación interna), pie con totales conservados y `TotalFilas`, cabecera de 3.5, `aria-sort` | El modo completo queda igual |
| `BarraPaginasReporte` | **Nuevo** (pequeño) | Web y MAUI; parámetros: `Pagina`, `Tamano`, `HayMas`, `TotalFilas?`, `Profundidad?`, `Ocupado`, eventos |
| `MenuExportar` | **Extender**: privilegio, orden, evidencia, estado «Preparando…», confirmación con filtros modificados | — |
| `DialogoConfirmarIdentidad` | **Reutilizar** el de UX-81A P6 (lo construye la fase A de ADR-81) | Si la fase A no llegó, el 401 factor va al inicio de sesión (no hay factor que confirmar) |
| `VistaErroresReportes` | **Nuevo** (clase sin interfaz): mapa código → clase de presentación y texto propio, como `VistaAvisosDocumento` | Probado con bUnit/xUnit |
| `MudSelect`, `MudSwitch`, `MudAlert`, `MudSnackbar`, `MudSkeleton`, `MudTableSortLabel` | Reutilizar (MudBlazor ya en el proyecto) | Sin colores nuevos: `Primary`, `Warning`, `Error`, `Info` del tema |
| Títulos | «Reportes de Ventas», «Reportes de Compras», «Reportes de Inventario», «Reportes de Efectivo», «Reportes Fiscales» (RG-30) en `PageTitle` y `h5` | Cambio de texto pequeño; si RG-30 se aplica en otra tanda, se deja |

---

## 6. Accesibilidad y teclado

**Teclado (Web).**

| Tecla | Acción | Ámbito |
|---|---|---|
| `Enter` | Ejecutar | En cualquier campo del panel de filtros (salvo un selector abierto, donde elige) |
| `Esc` | Cancelar la ejecución en curso; cerrar diálogo o menú | Pantalla |
| `F3` | Buscar en el catálogo del selector enfocado (artículo, cliente…) | Patrón existente (`EditorLineas`, `Existencias`) |
| `Tab` / `Mayús+Tab` | Orden: lista → título → Campos → Exportar → Ejecutar → Filtros → campos → tabla (encabezados) → barra de páginas → anexos | Orden visual = orden de foco |
| `Enter` / `Espacio` en un encabezado | Cambia el orden (ciclo de 3.3) | Solo ordenables |
| `Enter` / `Espacio` en una fila con detalle | Abre el detalle (drill down) | Las filas con detalle llevan `tabindex="0"` y `role="button"` (hoy solo el clic funciona) |

- Sin atajos globales de paginación: `Alt+←/→` y `Ctrl+AvPág/RePág` los usa el navegador (atrás/adelante, cambiar de pestaña). Los botones de la barra son enfocables y con nombre accesible.

**Lector de pantalla y contraste.**
- Región `aria-live="polite"` que anuncia: «Reporte ejecutado: 3.450 filas. Mostrando 1 a 500.», «Página 2: filas 501 a 1.000.», «Orden por Venta, descendente.»; los errores usan `role="alert"`.
- `<th aria-sort>` en la columna ordenada; los botones de página con `aria-label` («Página siguiente», «Página anterior», «Primera página»); la flecha del orden no es el único indicador (también `aria-sort` y el tooltip «Ordenado por … descendente»).
- El interruptor Sí/No con `role="switch"` y `aria-checked`; la etiqueta asociada por `for`/`aria-labelledby`.
- Contraste AA del tema MudBlazor actual; los textos atenuados (`mud-text-secondary`) no se usan para avisos de error.
- La tabla atenuada durante la carga lleva `aria-busy="true"`.
- Columnas sensibles: se mantiene el enmascarado existente (`columna-sensible`).

---

## 7. Datos requeridos de la API

### 7.1 Existentes (verificados)

| Dato | Contrato | Uso |
|---|---|---|
| `ReporteDto.Fuente`, `Parametros` (`Campo`, `Etiqueta`, `Tipo`, `Obligatorio`, `Defecto`, `Opciones`, `Catalogo`) | `ReportesLectura.cs:6-26`; `Reportes.cs:147-151` | 3.1 |
| `ReporteDto.OrdenarPor`, `OrdenDescendente` | `Reportes.cs:107-108` | Indicador del orden por omisión |
| `ResultadoReporte.Pagina`, `Tamano`, `HayMas`, `TotalFilas`, `TotalesCompletos`, `Metadatos`, `Anexos` | `Reportes.cs:198-224` | 3.2, 3.5 |
| `?pagina`, `tamano`, `orden`, `desc`, `totales`, `contar`, `columnas` en `ejecutar`; `orden`, `desc` en `exportar` | `EndpointsReportes.cs:54-70` | 3.2, 3.3, 3.6 |
| `X-GPOS-Renglones`, `X-GPOS-Huella-Datos`, `X-GPOS-Totales` (los copia la principal) | `EndpointsReportes.cs:76-78`; `ReenvioReportes.cs:58` | 3.6 |
| `Retry-After` en los 429 (lo copia la principal) | `ErroresReportes.cs:36-37`; `ReenvioReportes.cs:58` | 3.4 |
| Privilegios en `SesionInfo` (`Tiene`) | `Cuentas.cs:84`; `Permisos.cs:122-132` | Exportar deshabilitado |

### 7.2 Cambios de contrato que necesita el frontend

| ID | Cambio | Tipo | Quién | Prioridad |
|---|---|---|---|---|
| **C-1** | Unificar el motivo del 401 del SUPER sin segundo factor: la API de reportes envía `factor` y la principal (blueprint ADR-81) `factor-requerido`. **Y** que `POST /api/auth/reautenticar` (o una ruta nueva) **agregue `otp` al `amr`** de un SUPER cuyo token no lo tiene, y que la principal responda ese caso **sin cerrar la sesión** (hoy el blueprint lo lleva al inicio). Sin esto, «confirmar el factor sin cerrar la sesión» no es posible: la principal rechazaría el token antes de reenviar (`RequireAuthorization` corre primero) | Encabezado + comportamiento | arquitecto-software (A y C, fase A de ADR-81) | **Alta**: decide UX-V-01 |
| **C-2** | La interfaz debe recibir la evidencia de la exportación: en la Web, sustituir el proxy `/reporte/{id}/{formato}` (que descarta encabezados) por la descarga desde `ApiClient` en el circuito; `ApiClient.DescargarAsync` (Web y MAUI) devuelve también `Renglones` y `HuellaDatos` | Cliente (sin cambio en las API) | desarrollador-frontend | Alta (F9 pide «CSV con evidencia») |
| **C-3** | `PRIVILEGIO_REQUERIDO` con los **nombres** del privilegio en el mensaje, o con un campo aditivo `privilegios: ["vercostos", …]` en el problema para que la interfaz los nombre | Mensaje / campo aditivo | arquitecto-software (B, `LectorRegistradas.cs:155`) | Media |
| **C-4** | Separar el metadato `totales`: `totalesEstado = "no-disponibles"` para el estado y `totales` (o `totalesNota`) solo para la leyenda | Metadato aditivo | arquitecto-software (B) | Media (sin él, la interfaz compara con el texto literal «no disponibles») |
| **C-5** | Opcionales: `ReporteColumnaDto.Ordenable` (bool?, null = sí) en el resultado del diseñador y `Metadatos["profundidad"]` (50.000 configurable) | Campos aditivos | arquitecto-software (B) | Baja (hay camino reactivo) |
| **C-6** | Metadato `datosPersonales = "abreviados"` cuando el usuario no tiene «Ver datos personales» y el reporte enmascara identificaciones | Metadato aditivo | arquitecto-software (B), con las vistas del tramo 4 (CxC/CxP) | Baja hoy (ningún reporte de F9 muestra identificaciones) |
| **C-7** | `RutaExportacion` envía `orden` y `desc` | Cliente | desarrollador-frontend | Alta (la exportación debe salir como la pantalla) |
| **C-8** | `ApiException.RetryAfter` | Cliente | desarrollador-frontend | Media |

Ninguno rompe a los clientes actuales (cláusula 8 de ADR-109): todos son aditivos o del cliente, salvo C-1, que cambia el valor de un encabezado que hoy ningún cliente interpreta.

---

## 8. Hoja de firma (preguntas para el propietario)

| ID | Pregunta | Opciones | Recomendación | Firma |
|---|---|---|---|---|
| **UX-V-01** | El SUPER con una sesión abierta antes de activar la fase A de ADR-81 (token sin segundo factor) abre un reporte. ¿Qué pasa? | (a) **Confirmar su Identidad** sin cerrar la sesión y repetir el reporte (requiere C-1: `/reautenticar` agrega `otp` y la principal no cierra la sesión en ese caso). (b) Ir al inicio de sesión con «Su usuario ahora requiere la verificación en dos pasos», como diseñó UX-81A para la principal | **(a)**, que es lo pedido y no hace perder el trabajo; con C-1 se aplica igual en la principal, para que las dos API se comporten igual. Costo: ≈ 0,5 día en A/C (precisión de `/reautenticar`) + 0,25 día en el visor. Si C-1 no entra en la fase A, (b) como respaldo temporal | ☐ |
| **UX-V-02** | Tamaño de página por omisión | (a) 500 en Web y tableta, 100 en teléfono. (b) 1.000 en todos (el del servidor). (c) 100 en todos | **(a)**: 500 filas se recorren con la rueda y cargan en < 1 s; 1.000 duplica el HTML del circuito Blazor (≈ 8.000 celdas) sin beneficio; en el teléfono, 100 evita listas interminables | ☐ |
| **UX-V-03** | Texto del pie cuando el cálculo de totales agotó el tiempo (distinto del resultado parcial de D2) | (a) «Total no disponible: el cálculo superó el tiempo máximo. Agregue filtros para verlo.» (b) El mismo de D2 para todo | **(a)**: dice al usuario qué hacer; D2 no cambia para el resultado parcial | ☐ |
| **UX-V-04** | Orden por varias columnas | (a) No: una columna, ciclo ascendente → descendente → del reporte. (b) Sí, con Mayús+clic | **(a)**: el servidor ordena por una sola columna más su desempate (`EjecutorDisenador.cs:292-321`); (b) exige cambio de contrato y de SQL (≈ 2 días) para un uso raro en BP2 | ☐ |
| **UX-V-05** | El privilegio «Exportar reportes (CSV y Excel)» el servidor lo exige también para el PDF | (a) El PDF también es exportación: se corrige el nombre del privilegio a «Exportar reportes (PDF, Excel, CSV y otros)». (b) El PDF queda libre (es «imprimir») y se cambia el servidor | **(a)**: un PDF también saca los datos del sistema; coincide con lo construido; solo cambia un texto del catálogo de privilegios | ☐ |
| **UX-V-06** | Los registrados (1, 5, 7, 17, 18, 20) tienen orden fijo | (a) Se mantiene fijo; el encabezado lo dice. (b) Agregar orden en el servidor a los registrados | **(a)** para la entrega 1: su orden es el de BP2 y el de los totales por grupo; (b) son ≈ 2-3 días de B (SQL por reporte) | ☐ |
| **UX-V-07** | Los títulos de la pantalla pasan a mayúsculas de título («Reportes de Ventas», «Reportes Fiscales») en esta tanda | (a) Sí, en esta tanda. (b) Con el resto de RG-30 en la siguiente fase | **(a)**: es el mismo archivo que se toca; 5 minutos | ☐ |
| **UX-V-08** | Exportar con filtros modificados sin ejecutar | (a) Preguntar y exportar el resultado en pantalla. (b) Exportar con los filtros nuevos sin preguntar | **(a)**: la evidencia debe corresponder a lo que el usuario vio | ☐ |

---

## 9. Esfuerzo estimado de frontend (Web + MAUI, copias idénticas)

| Pieza | Días-persona |
|---|---|
| Opción, Sí/No y entero; valores iniciales; resumen; «Valores por omisión» (3.1) | 0,5 |
| Paginación en el servidor: barra, firma de la consulta, totales conservados, `TotalFilas`, `Virtualize`, modo completo intacto, 422 (3.2) | 1,5 |
| Orden en el servidor controlado, ciclo, registrados fijos, reversión ante 400 (3.3) | 0,75 |
| Errores: `VistaErroresReportes`, `RetryAfter` y cuenta regresiva, avisos en línea, motivo `cerrada`, gancho del 401 factor (3.4) | 1,0 |
| Exportación con evidencia: descarga por `ApiClient` en Web con `DotNetStreamReference`, encabezados en MAUI, orden, privilegio, confirmación (3.6, C-2, C-7) | 1,0 |
| Cancelar la ejecución; cabecera de evidencia y privilegios (3.5, 3.7) | 0,5 |
| Accesibilidad, teclado y ergonomía MAUI (6, 3.8); títulos RG-30 | 0,75 |
| Pruebas (`GPOS.Web.Tests`, `GPOS.UI.MAUI.Tests`): controles, barra, pie D2, mapa de errores | 1,0 |
| **Total** | **≈ 7 días-persona (≈ 1,4 semanas-persona)**, margen ± 25 % |

No incluye: el diálogo `DialogoConfirmarIdentidad` (fase A de ADR-81) ni los cambios de servidor C-1 y C-3 a C-6 (≈ 1 día de B y ≈ 0,5 día de A/C). Sin costo de infraestructura ni licencias.

---

### Supuestos

- La fase A de ADR-81 construye `DialogoConfirmarIdentidad` (UX-81A P6); el visor solo lo invoca.
- Ningún reporte es «acción sensible» de ADR-81 (no se pide `REAUTENTICAR` para ejecutar ni exportar).
- La profundidad de 50.000 se mantiene en la configuración por omisión mientras no exista C-5.
- Los reportes 1 y 18 se comportan como sus pares (1: diseñador o principal según la lista P-2; 18: el 17 con agrupación fija, sin el parámetro «Agrupar por»). Inferido de `ReportesInventarioRegistrados.cs:47-50`, no verificado para el 1.
