# Respuestas de A a B: VE-01 (reimpresión fiscal), VE-02 (vendedor) y componentes compartidos `SelectorLote` / `DialogoFaltantes`

- **Fecha:** 2026-10-08
- **Autor:** arquitecto-software, equipo A
- **Responde a:** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-08-ventanas-respuestas-nucleo.md`
- **Base verificada (solo lectura, `git show` y `git grep`):** código de A en `origin/feature/modelo-ng` (`e300320`); diseños de B en `origin/b/verticales-diseno` (`2f02c89`, `d44a891`); ADR-04, ADR-68, ADR-118 y ADR-119 en `origin/master`.
- **Estado:** son recomendaciones técnicas. Lo marcado **F-n** queda **Pendiente de firma** del propietario.

## 0. Resumen

| # | Tema | Respuesta de A | Esfuerzo (±40 %, inferido) | Tanda | ¿Firma? |
|---|---|---|---|---|---|
| VE-01 | Nombre y código del privilegio | `Permisos.ReimprimirComprobante = "reimprimircomprobante"`, «Reimprimir comprobantes fiscales (copias de facturas, tickets y notas con NCF o e-NCF)», grupo **Especiales**, con la acción **Autorizar** (quien lo tiene puede autorizar a otro) | — | — | No: el nombre lo fija A (precisión de ADR-68) |
| VE-01 | Perfiles por omisión | SUPERVISOR y CONTADOR: sí. CAJERO: no. Las instalaciones ya sembradas lo reciben con un paso único, igual que `AgregarPermisosOla3ContadorAsync` | incluido | — | **F-1** |
| VE-01 | Qué es una «reimpresión» | Toda impresión, PDF o envío por correo de un documento **con NCF o e-NCF emitido por la empresa** después de la primera impresión de cada representación. **No** son reimpresión: la primera impresión, la RI definitiva automática de VF-13 ni los reintentos tras una falla de la impresora | — | — | **F-2**, **F-3**, **F-4** |
| VE-01 | Contrato del error | 422 `AUTORIZACION_REIMPRESION_REQUERIDA`. Con supervisor: `POST /api/impresion/reimpresion` con `AutorizacionSupervisor` (ADR-68). Si la credencial falla: 422 `AUTORIZACION_INVALIDA`, el mismo de hoy | — | — | No |
| VE-01 | Bitácora | Una fila en `doc.Impresion` (RO-54, hoy sin escritor), una línea en `audit.Bitacora` y en `_LOG` con el puente actual y, si autoriza un supervisor, `doc.Autorizacion` de tipo `REIMPRESION` | — | — | **F-5** (motivo) |
| VE-01 | Esfuerzo y tanda | **0,5 a 0,7 sp**. B estimó 0,1 sp, pero RO-54 («COPIA n») no está construido y hay cinco pantallas que imprimen. Va en una **tanda de núcleo de caja**, junto con VF-06 y VF-19, **después de unir T1, T2 y T4** y **antes de T-29 (e-CF)** y del corte | 0,5–0,7 sp | Antes del corte | No |
| VE-02 | Política de campos frente a `ExigirVendedor` | **Sí choca, y el choque ya está en el código de A:** la Política de campos puede marcar `VendedorId` como obligatorio en el POS y en las ventas, y el servidor lo exige. Propuesta: `ExigirVendedor` es la **única** fuente de la obligatoriedad. La política solo puede ocultar el campo o dejarlo de solo lectura, y la ventana de cada vertical solo decide cómo lo muestra | 0,15 sp | La misma tanda de núcleo de caja | **F-6** (precisa ADR-11), **F-7** |
| VE-02 | Qué cambia B | Casi nada: los diseños de Duty Free, Farmacia y Restaurante ya cumplen (AJ-1, 3.3). Falta quitar el «vendedor obligatorio» de toda Política de campos de pantallas de vertical, tomar la obligatoriedad de `ConfigPosDto.ExigirVendedor` (aditivo nuevo de A) y usar `VENDEDOR_REQUERIDO` y `VENDEDOR_INHABILITADO` | — | — | No |
| Comp. | ¿Quién construye primero `SelectorLote` y `DialogoFaltantes`? | **A, en la Estándar, con T4 (desde el 15-oct)**, en el proyecto nuevo `GPOS.Componentes`. B los reutiliza sin copiarlos y con el contrato de la sección 3 | 0,3–0,4 sp (incluye crear el proyecto) | T4 | **F-8** (informativa: adelanta la creación de `GPOS.Componentes`, que ADR-04 V-3 dejaba para la entrega 3) |

---

## 1. VE-01: reimpresión de comprobantes fiscales

### 1.1 Lo verificado hoy

- **No hay ninguna restricción.** `GET /api/impresion/documento|ticket|nota/{numero}` solo comprueba el permiso de la opción del documento (`src/GPOS.Api/Endpoints/ImpresionEndpoints.cs:22-33` y `:136-140`). En la Web, el POS imprime con `BotonImprimir` (`src/GPOS.Web/Components/Pages/Ventas/PuntoVenta.razor:261`, `:472`). En MAUI se reimprime desde `DialogoVentasPos.razor:38`.
- **RO-54 no está construido.** La tabla `doc.Impresion` existe, es de solo inserción (`DENY UPDATE, DELETE`, `SqlMigracionesOla3.cs:650`) y tiene la llave `(DocumentoId, Numero)` (`DocConfiguracion.cs:148-157`, `Documentos.cs:139-146`). Ningún servicio escribe en ella: solo aparece el `DbSet`. Tampoco hay marca «COPIA» en el modelo de impresión.
- **Convención de los privilegios.** Son constantes en minúsculas y sin separadores (`"vercostos"` y `"sincomprobante"`, `Permisos.cs:121` y `:126`). Se declaran con `Privilegio(clave, descripción, "Especiales")` (`Permisos.cs:233-243`). Un privilegio funciona como interruptor: `Normalizar` concede `Completo`, es decir, todas las acciones que declara (`Permisos.cs`, `Normalizar`).
- **ADR-68 en código.** `AutorizacionesSupervisor.ValidarAsync` valida la credencial y la acción **Autorizar** de la opción (`AutorizacionesSupervisor.cs:48`). `RegistrarAsync` escribe `doc.Autorizacion` y la línea de bitácora (`:110`). `BitacoraDocumentos.Registrar` escribe `audit.Bitacora` y la línea de `_LOG` por `PuenteCfg.Bitacora`.
- **Tipos de autorización.** `CK_Autorizacion_Tipo` no tiene un tipo de reimpresión (`DocConfiguracion.cs:110`).

### 1.2 El privilegio

```csharp
/// <summary>
/// Reimprimir comprobantes fiscales (VE-01, precisión de ADR-68 del 2026-10-08): copias, PDF y envíos por correo de un documento con NCF o e-NCF
/// después de su primera impresión. Sin él, la reimpresión exige la autorización de un supervisor que lo tenga. Deja su línea en la bitácora.
/// </summary>
public const string ReimprimirComprobante = "reimprimircomprobante";
// en Todos, grupo Especiales, junto a NoGenerarComprobante:
Privilegio(ReimprimirComprobante, "Reimprimir comprobantes fiscales (copias de facturas, tickets y notas)", "Especiales",
    acciones: AccionesPermiso.Autorizar),
```

- **Por qué lleva la acción Autorizar.** `ValidarAsync` exige `PuedeAccion(opcion, Autorizar)`. Como es un interruptor, quien recibe el privilegio recibe también Autorizar, y el supervisor es simplemente quien tiene el privilegio (o un ADMIN). Así se reutiliza ADR-68 sin código nuevo de validación.
  - *Alternativa descartada:* usar la acción Autorizar de cada opción (Punto de venta, Facturación, Notas, Devoluciones). Serían cuatro lugares para una sola regla, y el cajero con Autorizar en el POS, que hoy autoriza eliminar renglones, quedaría autorizando reimpresiones sin que nadie lo decida.
- **ADMIN y SUPER** lo tienen por su nivel, como los demás privilegios (`MapaPermisos`).
- **Perfiles (F-1).** La recomendación es agregarlo a `PerfilesIniciales`: SUPERVISOR sí (`PermisosService.cs:259`), CONTADOR sí (`:267`; reimprime para los clientes desde la consulta), CAJERO no (`:255`; es justamente el caso de la decisión). Las instalaciones ya sembradas lo reciben con un paso único `AgregarPermisosReimpresionAsync`, con la misma marca de opciones entregadas que `AgregarPermisosOla3ContadorAsync` (`:195`): si el ADMIN lo quita después, no vuelve. Un usuario sin perfil (convertido desde el legado) **pierde** la reimpresión libre. Como hoy todo es desarrollo, no hay producción afectada.

### 1.3 Qué cuenta como reimpresión (F-2, F-3, F-4)

| Caso | ¿Reimpresión? | Registro |
|---|---|---|
| Primera impresión de un documento con NCF o e-NCF, al emitirlo o después | No | `doc.Impresion` con `Clase = 'O'` (original) |
| Constancia de contingencia de ADR-51 (sin título de comprobante fiscal) | No la primera; sí las siguientes | `'O'` |
| **RI definitiva que se imprime sola al llegar la firma (VF-13)** | **No.** Es la primera impresión de la representación definitiva, aunque antes se haya impreso la constancia | `'A'` (automática), con usuario `SISTEMA` y la caja |
| «Imprimir otra vez» tras una falla de la impresora (ADR-68, precisión VE-01) | **No**, si el mismo usuario lo pide hasta **2 veces** dentro de **10 minutos** desde la última impresión de esa representación (F-3) | `'F'` (reintento) y una línea de bitácora «Reintento de impresión n (falla de impresora)» |
| Cualquier otra copia, el PDF descargado desde la consulta o el envío por correo | **Sí** (F-4) | `'R'`, «COPIA n» en el documento (RO-54), bitácora y, si autoriza un supervisor, `doc.Autorizacion` |
| Documento sin NCF («No generar comprobante», cotización, pedido, conduce, recibo, Cierre X/Z, inventario) | No aplica (libre) | Ninguno |
| Factura de compra con el NCF del suplidor | No aplica: el comprobante no lo emitió la empresa | Ninguno |
| Vista previa del diseñador de formatos | No aplica: solo ADMIN, que tiene el privilegio | Ninguno |

**Comprobante fiscal** = documento con NCF o e-NCF **emitido por la empresa**: ticket POS, factura de crédito, nota de crédito o débito, devolución y comprobantes de compras o gastos menores que emite la empresa.

**El servidor no puede saber si la impresora falló.** Por eso la ventana de reintento se acota por usuario, tiempo y cantidad, y queda en la bitácora (inferido; el riesgo residual son dos «originales» si la falla era falsa, y se ve en el reporte).

### 1.4 Contrato de la API interna

| Ruta | Método | Entrada | Salida | Permiso | Errores |
|---|---|---|---|---|---|
| `/api/impresion/documento/{tipo}/{numero}`, `/ticket/{numero}`, `/nota/{numero}` (existentes) | GET | `formato?`, `papel?` y el nuevo **`reintento?: bool`** (aditivo) | PDF | El de hoy, por opción | 403 y 404, como hoy; **422 `AUTORIZACION_REIMPRESION_REQUERIDA`** si el documento es fiscal, ya se imprimió, no es un reintento válido y la sesión no tiene `reimprimircomprobante` |
| `/api/impresion/reimpresion` (nueva) | POST | `ReimpresionRequest { string Ruta; int? Formato; string? Papel; AutorizacionSupervisor Autorizacion }`. La ruta es la misma que la del GET (`"ticket/FC0001"`) | PDF «COPIA n» | El mismo de la ruta | 422 `AUTORIZACION_INVALIDA` (ADR-68: falta el motivo, la credencial es incorrecta, la cuenta está bloqueada o el supervisor no tiene el privilegio); 403; 404 |

- **POST y no GET para el supervisor.** La contraseña no viaja en la URL, porque la URL queda en registros y en el historial. Es la misma forma de ADR-68: la pantalla recibe el 422, pide los datos y reenvía la operación.
- **Con el privilegio propio**, el GET imprime la copia sin preguntar el motivo. La línea de bitácora dice «privilegio propio».
- **Código nuevo**, en `CodigosDocumento`: `AutorizacionReimpresionRequerida = "AUTORIZACION_REIMPRESION_REQUERIDA"`. Sigue el patrón de `MOTIVO_ANULACION_REQUERIDO` y `APERTURA_REQUERIDA`. Mensaje: «Este comprobante ya se imprimió. Para imprimir una copia se requiere el privilegio "Reimprimir comprobantes fiscales" o la autorización de un supervisor.»
- **Orden en el servidor:**
  1. Validar la credencial, si viene, fuera de la transacción (ADR-68).
  2. Generar el PDF en memoria.
  3. En una transacción: `INSERT doc.Impresion` con `Numero = MAX+1`, más `doc.Autorizacion` y la bitácora.
  4. Si hay choque de llave (doble clic), reintentar una vez con el número siguiente. Eso convierte el segundo clic en un reintento `'F'`, sin pedir autorización.
  5. Devolver el PDF.

  Si el PDF falla, no se cuenta nada.
- **Aislamiento:** la base de la empresa de la sesión, como hoy. `Sitio(OperacionSitio.Libre)` sin cambio.
- **Rendimiento:** no toca el camino de la venta (la impresión es otra petición). Agrega un INSERT por impresión fiscal, de 0,3 a 1 ms en red local (inferido).

### 1.5 Línea de `_LOG` y de `audit.Bitacora`

Se escribe con `BitacoraDocumentos.Registrar(u, "Reimpresión", numero, documentoId, accion)`, que escribe las dos con el puente actual:

| Caso | `Accion` |
|---|---|
| Privilegio propio | `Reimpresión COPIA {n} (privilegio propio)` |
| Supervisor | `Reimpresión COPIA {n} autorizada por {SUP} (supervisor presente): {motivo}`, más `doc.Autorizacion` con `Tipo = 'REIMPRESION'`, `Valor = n` y `Motivo` |
| Reintento | `Reintento de impresión {k} (falla de impresora)` |
| RI automática de VF-13 | Solo la fila `'A'` en `doc.Impresion` (sin línea, para no llenar la bitácora) |
| Credencial rechazada | Ya lo registra `RegistrarRechazoAsync` |

**F-5:** con el privilegio propio **no** se pide motivo (sería fricción en cada copia). Con supervisor, el motivo es obligatorio, como en todo ADR-68.

### 1.6 Interfaz (Web y MAUI)

`BotonImprimir` es el punto central (`src/GPOS.Web/Components/Compartidos/BotonImprimir.razor`). Ante el 422 abre el `DialogoAutorizacionSupervisor` existente y reenvía por POST. Las pantallas que imprimen un comprobante fiscal son la Facturación Ágil, el diálogo de ventas del POS, la consulta de facturas, `DocumentoPage` y las notas. El documento impreso lleva «COPIA n» (RO-54), fuera del cuerpo fiscal. El texto exacto lo fija UX.

### 1.7 Esfuerzo y tanda

| Parte | sp (±40 %, inferido) |
|---|---|
| Privilegio, perfiles y paso único | 0,05 |
| `doc.Impresion` (`Clase`, `AutorizacionId`), `CK_Autorizacion_Tipo` + `'REIMPRESION'`, migración (arquitecto-datos) | 0,1 |
| Regla en el servidor, POST, «COPIA n» en `FabricaModelo` y en las plantillas base | 0,2 |
| `BotonImprimir` y las pantallas, en Web y MAUI | 0,1–0,2 |
| Pruebas (servidor, concurrencia del doble clic, bUnit) | 0,05–0,15 |
| **Total** | **0,5–0,7** |

**Tanda recomendada.** Una tanda corta de **núcleo de caja** (VE-01 + VF-06/VF-19), **después de unir T1, T2 y T4** y fuera de ella, para no mezclarla con la medición del p95 de la venta. Tiene que ir **antes de T-29 (e-CF)**, porque VF-13 la usa con la clase `'A'`, y **antes del corte** de mediados de diciembre, porque es una regla fiscal y de venta.

---

## 2. VE-02: Política de campos del vendedor frente a `ExigirVendedor`

### 2.1 ¿Choca? Sí, y el choque está en el núcleo de A, no solo en el diseño de B

- `Pantallas` permite configurar `VendedorId` en todas las pantallas de venta (`PoliticasCampos.cs:68`) y en el punto de venta (`:107-110`). El servidor exige lo que la política marque como obligatorio: `PoliticasCamposService.Faltantes` (`PoliticasCamposService.cs:116`) se llama en `PosService.cs:223` y en `DocumentosComercialesService.Ventas.cs:163`.
- Por eso hoy una empresa con `ExigirVendedor` **apagado** puede exigir el vendedor por política, incluso por usuario. ADR-11 lo pone como ejemplo: «vendedor obligatorio solo para un usuario». Eso contradice la decisión del propietario: opcional salvo que la empresa lo exija, como regla general del núcleo.
- Los diseños de B **ya cumplen**: Duty Free AJ-1 y 3.3 («desaparece el "Vendedor*" de la Política de campos de `FacturacionDutyFree`»), y Farmacia y Restaurante con «opcional salvo `ExigirVendedor`».

### 2.2 Cómo encajarlo (recomendación, opción A; F-6)

1. **`ExigirVendedor` es la única fuente de la obligatoriedad del vendedor de una venta.** Se agrega a `CampoDef` el indicador `ObligatoriedadDelNucleo` (aditivo) en `VendedorId` de Cotización, Pedido, FacturaCxc, DevolucionCxc, PuntoVenta y las pantallas de vertical que se registren.
2. **Con ese indicador:**
   - `GuardarAsync` rechaza `Obligatorio = true`, con 422 y el mensaje «La obligatoriedad del vendedor la decide el parámetro "Exigir vendedor en las ventas".».
   - `Resolver` calcula `Obligatorio = ExigirVendedor` en el POS y en FacturaCxc, y `false` en las demás.
   - Con el parámetro encendido, `Oculto` se ignora.
   - `Faltantes` **salta** el campo. La regla con código (`VENDEDOR_REQUERIDO`) ya la aplica el servicio desde `32a73ae`, así que no hay dos mensajes distintos.
3. **La vertical solo decide la presentación, nunca la exigencia.** Decide si muestra el selector, cómo (botonera o chip) y si lo llena por otra vía (el mesero identificado con PIN en el restaurante). Con `ExigirVendedor` encendido, una ventana que oculte el selector debe llenar el vendedor por otra vía. Si no lo hace, el servidor responde 422 `VENDEDOR_REQUERIDO`.
4. **Ocultar y solo lectura** siguen siendo de la Política de campos de la empresa (por usuario o nivel), no de la vertical.
5. **Datos existentes:** un paso único de migración pone `Obligatorio = NULL` en las reglas `VendedorId` de esas pantallas. Si una regla queda sin atributos, se inhabilita. Deja una línea de bitácora. Hoy todo es desarrollo.
6. **`ConfigPosDto.ExigirVendedor`** (aditivo). Hoy el valor solo llega al servicio (`PosService.cs:115-151`) y a `ParametrosDto` (`Admin.cs:51`), así que la ventana no lo conoce.
7. **`CodigosEfectivo.VendedorInhabilitado = "VENDEDOR_INHABILITADO"`** (aditivo) para el vendedor elegido a mano que está inhabilitado, como propone B (Duty Free, 7.3). No hay código propio para ese caso: verificado en `CodigosEfectivo.cs`, que solo tiene `VENDEDOR_ASIGNADO_CAJA`, `VENDEDOR_REQUERIDO` y `VENDEDOR_INHABILITADO_ASIGNADO`.

- *Alternativa B, descartada:* `ExigirVendedor` como piso, y la Política de la **empresa** (no de la vertical) puede exigirlo además para un usuario o un nivel. Conserva el ejemplo de ADR-11, pero vuelve a dejar dos reglas y un error sin código. La propuesta A es la más simple y es la que recomendó B (VE-02 en `ventana-facturacion-estandar.md`, sección 4).
- **F-7:** `ExigirVendedor` **no** se extiende a cotizaciones ni a pedidos, como en `32a73ae`. La factura que sale de ellos sí lo exige. Con la opción A, esas pantallas pierden la posibilidad de exigirlo por política.
- **Clientes › `IdVendedor`** (el vendedor asignado en la ficha) no es una venta y queda fuera de este cambio.

### 2.3 Qué debe cambiar B

- Quitar «Obligatorio» del vendedor en toda Política de campos de pantallas de vertical (en sus diseños, si queda alguno). Tomar la obligatoriedad de `ConfigPosDto.ExigirVendedor` o de `PoliticaPantalla.Obligatorio("VendedorId")`, que ya la reflejará.
- Usar los códigos `VENDEDOR_REQUERIDO` y `VENDEDOR_INHABILITADO`.
- Restaurante: con `ExigirVendedor` encendido y un mesero que no es vendedor habilitado, la ventana muestra el 422 y deja elegir un vendedor. No lo resuelve por su cuenta.

**Esfuerzo de A:** unas 0,15 sp (inferido, ±40 %). Va en la misma tanda de núcleo de caja que VE-01.

---

## 3. `SelectorLote` y `DialogoFaltantes`: quién y con qué contrato

### 3.1 Confirmación

**A los construye primero, en la Estándar (Facturación Ágil), con T4, desde el 15-oct.** ADR-119 (estado de implementación) y ADR-118 (T1 y T2) son de A, y la Estándar es la primera vertical. B los **reutiliza sin copiarlos**: Farmacia y Duty Free descuentan unas 0,3 sp, como calcula B en `ventana-facturacion-estandar.md`, sección 3.

**Dónde viven: `src/GPOS.Componentes` (Razor Class Library),** como dice la precisión V-3 de ADR-04. Esa precisión dejaba el proyecto para la entrega 3. **F-8 (informativa):** A lo crea en T4 con estos dos componentes, por unas 0,1 sp más.
- *Alternativa descartada:* escribirlos en Web y en MAUI y moverlos después. Duplica el trabajo y las pruebas.
- **Dependencias:** `GPOS.Componentes` → `GPOS.Contracts` y MudBlazor 9.10.0 (la misma versión que `GPOS.Web.csproj`). Web y MAUI → `GPOS.Componentes`. No depende de `Core` ni de `Api`, y no hay ciclos.
- La Facturación Ágil los adopta **por decisión propia y con sus pruebas de regresión**, como exige la precisión DY-14 de ADR-04.

### 3.2 Contrato de `SelectorLote`

| Parámetro | Tipo | Regla |
|---|---|---|
| `Articulo`, `Almacen` | `string` | Códigos. Solo se muestra si el artículo tiene `ControlLote` |
| `Lote` / `LoteChanged` | `string?` | Enlace de dos vías con el código del lote del renglón (`IdLote` de la línea) |
| `Origen` / `OrigenChanged` | `OrigenLote { Sugerido, Manual, Lector }` | Cómo se eligió |
| `Sugerir` | `Func<IReadOnlyList<LoteDisponibleDto>, LoteDisponibleDto?>?` | Por omisión, el primero **no vencido** en el orden del servidor (vence primero y después el más antiguo). Duty Free pasa su propio orden (blueprint de ADR-118 y 119, 6.2 C) |
| `FueraDeOrden` | `EventCallback<LoteFueraDeOrden>` | Se dispara si el elegido no es el sugerido, con el elegido, el sugerido y el `Origen` |
| `SoloLectura` | `bool` | Por ejemplo, en una devolución, donde el lote sale de la línea de origen |

- **Datos:** recibe una interfaz `IFuenteLotes.DisponiblesAsync(articulo, almacen, ct)` que implementa el `ApiClient` de cada anfitrión sobre `GET /api/inventario/lotes-disponibles` (`LoteDisponibleDto(Lote, Vencimiento, Existencia, Vencido)`). Guarda la lista en caché por (artículo, almacén) durante la venta y la vuelve a leer después de un `EXISTENCIA_INSUFICIENTE`.
- **Lotes vencidos:** se ven marcados y **no se pueden elegir**, porque el núcleo responde 422 `LOTE_VENCIDO` (ADR-119, punto 5, P-4 B, y la precisión que retira `'A'`). Sin lotes con existencia muestra «Sin lotes con existencia en {almacén}» y no elige nada. El servidor responde `LOTE_REQUERIDO`.
- **El componente nunca autoriza, nunca avisa por su cuenta y nunca valida la existencia.** Solo informa `FueraDeOrden`, y cada ventana decide:
  - la **Estándar** lo ignora (ADR-119, punto 4: es regla de la farmacia);
  - la **Farmacia** pide autorización si la elección es manual, y con el lector da el aviso, la marca y la bitácora (VFA-03);
  - **Duty Free** aplica su propia regla.
- **La marca «fuera de orden»** en la línea y su bitácora **no** entran en el contrato de T4. B la define como extensión de la línea de su vertical (ADR-112, punto 5).
- **Teclado:** Enter acepta el sugerido. La lectura con el lector GS1 llega después (ADR-119) y usa `Origen = Lector`.

### 3.3 Contrato de `DialogoFaltantes`

| Parámetro | Tipo | Regla |
|---|---|---|
| `Mensaje` | `string` | El `detail` del servidor, que empieza con «Existencia insuficiente…». Se muestra tal cual |
| `Faltantes` | `IReadOnlyList<FaltanteExistenciaDto>` | `(Renglon, Articulo, Descripcion, Almacen, Lote?, Existencia, Requerido, Motivo, Categoria?)`, en `GPOS.Contracts/Inventario` (blueprint de ADR-118 y 119, 5.1) |
| Resultado | `short?` | El primer renglón, para que la ventana marque las filas y ponga el foco ahí |

- Es un diálogo modal con una tabla (renglón, artículo, almacén, lote, existencia, requerido y motivo con el texto de E/G/A/L/S/V) y **un solo botón, «Aceptar» (Enter)**.
- **Prohibido ofrecer** «No generar comprobante», cambiar la política o una autorización de supervisor (ADR-118, punto 5, y la prueba PA-12). El documento sigue en edición.
- La lectura de `faltantes` del ProblemDetails la hace cada `ApiClient` (`ProblemaApi.Faltantes`, blueprint 5.2). El componente solo recibe los datos.

### 3.4 Lo que deben respetar las ventanas de B

- No copian ni derivan los componentes. Si necesitan algo nuevo, piden un **parámetro aditivo** a A mientras A sea el dueño (hasta el corte). Después del corte, cualquier cambio de contrato va con aviso en el área común.
- La regla de autorización o de aviso del lote fuera de orden vive en la ventana, nunca en el componente.
- Pruebas con bUnit, como en `GPOS.Web.Tests`, contra el contrato publicado por A.

---

## 4. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-1 | El reintento de impresión no se puede verificar en el servidor y alguien podría usarlo para sacar copias libres | Media | Tope de 2 en 10 min por el mismo usuario, cada uno con su línea de bitácora y un reporte de reintentos por usuario (entrega a UX y reportes) |
| R-2 | Con la réplica de la entrega 2, `doc.Impresion` podría contar distinto en el nodo y en la central | Baja | Se imprime en el sitio dueño del documento. Se revisa al diseñar la réplica |
| R-3 | La opción A de VE-02 quita una capacidad que ADR-11 pone como ejemplo | Baja | F-6. Nadie la usa en producción (BP2 nunca salió) |
| R-4 | Adelantar `GPOS.Componentes` toca la solución en T4, junto con la medición del p95 | Baja | Es un proyecto de interfaz y no toca el camino caliente del servidor |

### Cierre
- Estado: Completado (respuestas preparadas; F-1 a F-8 **Pendientes de firma**)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\respuestas-ve01-ve02-2026-10-08.md`
- Supuestos: «comprobante fiscal» = NCF o e-NCF emitido por la empresa; ventana de reintento de 2 en 10 min; la RI automática de VF-13 se imprime con el usuario `SISTEMA`; el proyecto de pruebas Web sigue con bUnit 2.*; esfuerzos inferidos con ±40 %
- Decisiones candidatas a ADR: complemento de la precisión VE-01 de ADR-68 (privilegio `reimprimircomprobante` con Autorizar, alcance, reintentos, contrato); precisión de ADR-11 (la obligatoriedad del vendedor la fija solo `ExigirVendedor`); precisión de ADR-04 V-3 (crear `GPOS.Componentes` en T4)
- Entregas a otros agentes: arquitecto-maestro → llevar F-1 a F-8 al propietario y redactar las precisiones; arquitecto-datos → `doc.Impresion` (`Clase`, `AutorizacionId`), `'REIMPRESION'` en `CK_Autorizacion_Tipo`, paso de las reglas `VendedorId`; disenador-ux-ui → «COPIA n», diálogo del 422 de reimpresión y diseño de `SelectorLote` y `DialogoFaltantes` en la Estándar; equipo B → sección 2.3 y contrato 3.4; desarrolladores A → tanda de núcleo de caja y T4
- Próximo paso recomendado: firmar F-1 a F-8 antes del 15-oct para que T4 cree `GPOS.Componentes` y la tanda de núcleo de caja quede programada antes de T-29

---
**Firma del propietario (2026-10-08):** «Como recomiendas, apruebo las tres». **F-1 a F-5 y F-8: Sí, según la recomendación.** **F-6 y F-7 sustituidos (camino 1):** la **Política de campos es la única fuente** de la obligatoriedad del vendedor; se retira el parámetro `ExigirVendedor` (`32a73ae`). Vendedor exigido en el POS = alguna regla activa de «Punto de venta», campo `VendedorId`, obligatoria en cualquier alcance; entonces: no se inhabilita a un vendedor asignado a caja o perfil, y no se guarda la regla con asignaciones inhabilitadas. En el POS el vendedor por omisión (perfil → caja) se resuelve **antes** de validar la política (defecto corregido). Facturación a crédito, cotizaciones y pedidos con su propia regla. En devoluciones el vendedor se hereda y no se puede marcar obligatorio. ADR-11 se mantiene, con nota de estas protecciones.
