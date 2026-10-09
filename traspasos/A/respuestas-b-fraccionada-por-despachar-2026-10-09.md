# Respuestas de A a B: UF-05, «Por despachar», venta fraccionada, vistas (revisión 4), kit de conectores y V-08

- **Fecha:** 2026-10-09
- **Autor:** arquitecto-software del equipo A
- **Tipo:** recomendación técnica. Lo marcado **OD-n** lo decide el propietario. Lo demás es técnico de A y queda **Pendiente de firma** solo donde toca un ADR.
- **Fuentes:**
  - avisos de B del 2026-10-09: `uf05-kardex-orden-conduce`, `marca-pendiente-despacho-y-kit`, `marca-por-despachar`, `dp1-dp3-erp-anticipos`, `fraccionada-por-despachar-preguntas`, `blueprint-v2-fraccionada-por-despachar`, `farmacia-unidad-base-fraccionada`, `vistas-ola5-revision4` y `k1-listo-para-unir`;
  - blueprint v2 de B, `origin/b/verticales-diseno:docs/arquitectura/2026-10-09-fraccionada-y-pendiente-despacho.md` (en adelante **[BP]**);
  - ADR-113, ADR-078, ADR-104 y ADR-124 en `origin/master` (`3a2d0bd`);
  - `traspaso-A-2026-10-09.md`, `decisiones-por-registrar-2026-10-08.md` y `estimacion-proyecto-sp-2026-10-08.md`.
- **Código verificado en `472d078`** (`feature/modelo-ng`, con `git show` desde `GPOS NG`). No se compiló ni se ejecutó nada, y no se tocó el árbol `GPOS-NG-numeracion`. Las líneas que cita B (`Ventas.cs:300-303`) corresponden a su árbol (`5b407bb`); en `472d078` el mismo código está en `:323-328`.

## 0. Resumen

| # | Tema | Respuesta corta | De quién | Tanda |
|---|---|---|---|---|
| 1a | UF-05: la factura desde conduce no mueve el kárdex ni descarga dos veces | **Confirmado** en `472d078`, con cinco protecciones. Queda un hueco menor (saldo del conduce facturado en parte) | A, técnico | Ya está |
| 1b | La devolución de una factura desde conduce mete inventario con la propia nota | **Confirmado** (`Ventas.cs:327-328`). Se corrige: la nota no mueve inventario y la mercancía entra por Entradas/Recepción con el conduce de origen. Hay que cambiar también la regla 51380, que hoy obliga a la devolución a reintegrar | A, técnico (lo cubren las precisiones de ADR-113) | Entrega 1, «tanda UF-05» |
| 2 | A-Q1 a A-Q13 | A-Q5 y A-Q6: **sí**. A-Q10: **sí al contador**, pero como columna `Sueltas` en las filas de existencia, sin nivel de bloqueo nuevo. A-Q11: **sí a la forma**, sujeta al contador (CT-Q8, C-39) y al XSD del e-CF. El detalle de las demás está en la sección 2 | A, técnico; A-Q11 depende del contador | Por pregunta (sección 2) |
| 3 | «Por despachar» en la entrega 1 | **Cabe solo si la tanda 3 de equivalencias sigue siendo la que sale primero.** Se propone hacer la versión mínima (unas 2,2 sp de A) antes de la tanda 3 | **Propietario** (OD-1 y OD-2) | Entrega 1 |
| 4 | UX-10 (el conteo no guarda el desglose) frente a FR-Q2 b (cajas cerradas y sueltas) | Tres opciones. Recomiendo la (a): UX-10 sigue para todos, con una excepción solo para los artículos fraccionables | **Propietario** (OD-3, junto con FR-Q7) | Entrega 3 |
| 5 | Vistas, revisión 4, preguntas 1 a 6 | 1: agregar `TipoIdentificacionCliente`. 2: el costo de la línea ya viene (no es 0), pero debe heredarse del conduce. 3: sí al costo; la unidad y el factor van con valor y `CantidadOrigen` en NULL. 4: coinciden por construcción. 5: usar la clave (`vercostos`). 6: `RncReceptorEnmascarado` | A, técnico | 1, 2 y 5 antes de unir la ola 5; 3, 4 y 6 no piden cambios de código de A |
| 6 | Kit: D-K4, D-K5 y el nombre del campo de contingencia | D-K4: **de acuerdo**, con condiciones. D-K5: **sí**, en `GPOS.Conectores.Contratos`, no en el kit. Campo: `contingenciaReemplazo` | A, técnico | Ya, sin costo; la integración va con T-29, después del corte |
| 7 | Farmacia: nacer con la unidad mínima como base | **Sí se puede ya:** el alta y la importación crean la base igual a la unidad de venta (TAB, factor 1). Lo que no se puede todavía es la CAJA × 21. No recomiendo un aviso en la entrega 1 | A, técnico; **propietario** si hay una farmacia antes de la tanda 3 (OD-4) | Entrega 1 (nada) o +0,15 sp si OD-4 = sí |
| 8 | V-08: el limitador usa la IPv6 completa | **Sí:** dos niveles, la dirección y el /64 con un cupo mayor; el IPv4 mapeado se normaliza. Unas 0,05 sp | A, técnico | Entrega 1, con la fase A del segundo factor |

---

## 1. UF-05: lo que hace hoy `feature/modelo-ng` (`472d078`)

### 1a. La factura desde conduce: sin kárdex y sin doble descarga (confirmado)

| Protección | Evidencia |
|---|---|
| La factura de crédito con conduce **no registra inventario** | `src/GPOS.Core/Servicios/DocumentosComercialesService.Ventas.cs:311` (`if (conduce is null && almacen is not null)`); `:241` (la retrofecha no exige período de inventario) |
| El conduce se **bloquea** (`GPOS.Doc:Conduce:{n}`) y se valida con el bloqueo tomado: vigente, del mismo cliente y **sin otra factura vigente** | `Ventas.cs:197-201`, `:462-474`; `InventarioService.cs:75-79` |
| Cada línea inventariable de la factura es del conduce: mismo artículo, misma unidad y sin pasar de la cantidad del conduce (422 `LineaFueraDelConduce`) | `Ventas.cs:483-506` |
| Un conduce facturado **no se anula** («Anule primero la factura») | `InventarioService.cs:289-290` |
| La regla 51380 exime a la factura (FAC/FPOS) cuyo origen está emitido y tiene movimientos vigentes | `SqlMigracionesOla4FactorUnidadAjustes.cs:69-81` (`@origenMovio`) |

**Conclusión:** hoy no hay doble descarga. Anular la factura no revierte nada, porque no tiene movimientos (`Ventas.cs:542`), y deja el conduce libre para facturarlo otra vez (el filtro es `Estado = Emitido`).

**Hueco menor (Baja, verificado):** se puede facturar **menos** de lo que salió en el conduce (`Ventas.cs:478-481`), pero después el conduce queda «ya facturado» (`:580`). Lo que no se facturó sale del inventario sin factura y sin saldo que lo muestre. Se cierra con el mismo mecanismo de saldos de «Por despachar», con un saldo por facturar en las líneas del conduce. Lo dejo para la tanda de «Por despachar» (unas 0,05 sp), no para ahora.

**Lo que falta frente a la precisión:**
- la marca explícita (`OrigenInventario`, A-Q5);
- la regla inversa: una factura que no es `F` **no puede** tener movimientos;
- el cambio de la devolución (1b).

### 1b. La devolución de una factura desde conduce (hallazgo de B confirmado)

- **Evidencia:** en la devolución de crédito, `Ventas.cs:327-328` registra la entrada de inventario siempre que haya almacén, sin mirar si la factura de origen movió el kárdex. Además, la regla 51380 lo **exige**: «La devolución no se exime nunca: siempre reintegra» (`SqlMigracionesOla4FactorUnidadAjustes.cs:59` y `:71`).
- **Por qué es de A sin firma nueva:** ADR-113 en `master` ya dice que «las devoluciones y anulaciones siguen la misma vía» (UF-05) y que «toda mercancía que regresa entra por Entradas/Recepción» (precisión sobre los conduces). La factura C-4 está en la entrega 1, así que el ajuste también.
- **Corrección propuesta (A, unas 0,25 sp con la entrada):**
  1. Una devolución de una factura con `OrigenInventario` distinto de `F` no registra movimientos. Sigue consumiendo el saldo D y creando el saldo a favor (ADR-70) como hoy.
  2. La regla 51380 exime a la devolución si su factura no es `F`, leyendo la columna en lugar de `@origenMovio`.
  3. **Entrada por devolución de cliente** en Entradas/Recepción:
     - conduce de origen obligatorio;
     - unidad, lote y costo heredados del movimiento de salida del conduce, no editables;
     - límite por el saldo D de las líneas del conduce.

     Es el CB-9 de [BP] B.6.3, en su forma mínima. **Simplificación sobre [BP]:** no hace falta un «motivo» nuevo en la cabecera, porque `inv.DocInventario` no tiene campo de motivo; en `Inventario.cs` solo existe `MotivoAjusteId` por línea. La presencia de `ConduceOrigenId` ya marca la entrada como devolución de cliente.
  4. Los dos reportes de excepción de [CT] 6.4 (nota con devolución física sin entrada y entrada sin nota) son de B, en la ola 5.
- **Pérdida aceptada:** la nota y la entrada dejan de ser atómicas. Hasta que se corrija, el comportamiento actual da cantidades correctas cuando la mercancía vuelve de verdad, por eso la severidad es Baja.

---

## 2. Preguntas A-Q1 a A-Q13

| # | Respuesta de A | Tanda |
|---|---|---|
| **A-Q5** (prioritaria) | **Sí: una sola columna con F, C, O y P.** Sustituye la `Venta.InventarioPor` que A tenía anotada para el restaurante (`SqlMigracionesOla4FactorUnidadAjustes.cs:71`; traspaso, «Para más adelante»). Adoptamos el nombre de B, `OrigenInventario`, que ya usan DP-1 y el conector. Forma: `ventas.Venta.OrigenInventario char(1) NOT NULL DEFAULT 'F'` con el `CHECK` de los cuatro valores y relleno `C` donde `DocumentoOrigenId` sea un CON. Reglas en la emisión: **`F`** cuadra su kárdex línea a línea (51380); **`C`, `O` y `P` no pueden tener movimientos propios**. Esa regla nueva es la defensa en la base contra la doble descarga; el número lo asigna el arquitecto-datos de A (inferido: 51395 está libre). Con la columna, `@origenMovio` desaparece y el disparador hace una lectura menos | **Entrega 1, tanda UF-05**, antes de unir la ola 5: si las vistas `rpt` la exponen, debe existir antes de publicar la 1.0 del contrato, porque cambia la huella. Los valores `P` y `O` se usan con «Por despachar» y con el restaurante |
| **A-Q6** (prioritaria) | **Lo diseña el arquitecto-datos de A** (son tablas del núcleo: `doc.LineaSaldo`, `inv.DocInventario`). Se aceptan las clases `E` (por despachar) y `V` (devolución física pendiente de entrada) y el saldo `D` en las líneas del conduce de despacho. **Precisión:** para que el enlace línea de inventario → línea de venta tenga una llave foránea real, la línea guarda las dos partes, `(VentaDocumentoId, VentaLinea)` → `ventas.VentaLinea(DocumentoId, Linea)`, y no solo `VentaLinea` con la cabecera en otra tabla. B revisa el diseño | Entrega 1, si OD-1 = sí |
| **A-Q10** (prioritaria) | **Sí al contador explícito** (FR-Q2 b). **Contrapropuesta:** columna `Sueltas decimal(18,4) NOT NULL DEFAULT 0` en `inv.ExistenciaLote` (y en `inv.Existencia` para los fraccionables sin lote), **no una tabla aparte**. Motivos: (1) I-A7 pasa a ser un `CHECK` de la misma fila (`Sueltas >= 0 AND (Sueltas <= Cantidad OR Cantidad < 0)`), junto al `CK_ExistenciaLote_Negativa` que ya existe (`InvConfiguracion.cs:63`); (2) el descuento de existencia y de sueltas es **un solo `UPDATE` condicional**, sin fila extra; (3) **no hay nivel de bloqueo nuevo** en ADR-104, porque la fila ya se toma. Costo de espacio: 9 bytes por fila, despreciable. **Alternativa descartada:** la tabla aparte de [BP] A.5.1, que agrega una fila, un nivel en el orden de bloqueos y la creación concurrente de filas, y no permite el `CHECK` entre tablas. Si el arquitecto-datos prefiere la tabla, su lugar es **inmediatamente después de `Existencia`/`ExistenciaLote` y antes de `NumeroSerie`**, como propone B. **Negativos sin lote:** las sueltas nunca bajan de 0; si la política permite negativos y no hay sueltas ni cajas, la venta pasa y `Sueltas` queda en 0 (como propone B) | Entrega 3 (Farmacia, con la tanda 3) |
| **A-Q11** (prioritaria) | **Sí a la forma** ([BP] D.2 a D.4): el anticipo de un servicio no es un saldo a favor de ADR-70, sino `ventas.Anticipo` con su saldo; la factura final toma el documento del anticipo en la pasada única y descuenta en el nivel «saldos» con un `UPDATE` condicional. **Encaja con ADR-70** si se registra como precisión («el anticipo facturado de un servicio no pasa por `cxc.Credito`»); la prepara el maestro con la tanda. **No se construye** hasta que respondan el contador (CT-Q8 y C-39) y IQ sobre el descuento global en el XSD (R-D2), que es el riesgo real: si el XSD no admite reducir la base con un descuento global, cambia el mecanismo | Entrega 3, con condición |
| A-Q1 | **Sí:** `cat.Oferta.UnidadId` obligatorio en las ofertas `PRECIO` de artículos con más de una unidad de venta, y `CantidadMinima` en unidad base. Es latente mientras los factores valgan 1; **debe estar antes de activar cualquier equivalencia** | Tanda 3 (pieza obligatoria) |
| A-Q2 | Ver el punto 7 | Según OD-4 |
| A-Q3 | **Sí** a `doc.LineaSaldo.MotivoBloqueo char(1) NULL` con un catálogo de códigos neutros del núcleo; A reserva los códigos | Entrega 3 |
| A-Q4 | **Ya lo admite el modelo:** `cat.ArticuloCodigo` tiene `UnidadId` (la importación lo llena en `ComandosImportacion.cs:269-273`). La tanda 3 solo agrega la pantalla (UX firmado: mover los códigos de barras al crear la equivalencia) | Tanda 3 |
| A-Q7 | Cerrada (UF-11) | — |
| A-Q8 | **Sí**, ver 1b | Entrega 1, tanda UF-05 |
| A-Q9 | **Sí, como capacidad de la vertical:** `IExtensionVenta` declara si admite «Por despachar» (por omisión, sí); la ruta de emisión la consulta con la vertical de la caja, y el núcleo no nombra a Duty Free (ADR-112, punto 6). La factura del back-office no tiene caja: se admite. En la entrega 1 solo existe la Estándar, así que la comprobación es trivial, pero el gancho entra con la marca | Entrega 1, con «Por despachar» |
| A-Q12 | **Sí**, en la forma mínima de 1b: costo heredado del `CostoUnitario` del movimiento de salida (en base); el promedio se recalcula con ese costo, con `ArticuloCosto` tomado según ADR-104; con el período cerrado, la entrada va al período abierto con el costo original | Entrega 1, tanda UF-05 |
| A-Q13 | **Sí, entran en el canónico de A** (ADR-73): `OrigenInventario`, el enlace del conduce con la factura y la línea, las entradas por devolución, los cierres sin entrega y los anticipos. Se reservan los nombres ahora y se construye con las piezas A-1 a A-16 de AdmCloud, **después del corte** (con T-29) | Después del corte |

---

## 3. «Por despachar» en la entrega 1: calendario y orden

**Carga de A hasta el corte** (sp inferidas, ±40 %):

| Partida | sp | Fuente |
|---|---|---|
| Pendiente de la entrega 1 (incluye la ola 3b con 12,3, ADR-118/119 con 2,9, VE-01, RN-24, T-34, el corte y el apoyo a la ola 5) | 23,0 | `estimacion-proyecto-sp-2026-10-08.md:93-110` |
| Fase A del segundo factor (firmada el 2026-10-09) | 4,6 | `decisiones-por-registrar-2026-10-08.md:164` |
| Tanda 3 de equivalencias | ≈ 19 | Ídem, `:152` |
| Búsqueda sin tildes y redondeo del vuelto | ≈ 0,3 | Traspaso, puntos 3 y 5 |
| **Subtotal sin «Por despachar»** | **≈ 46,9** | |
| «Por despachar» mínima, parte de A (sección 3.2) | ≈ 2,2 | [BP] B.12 con los recortes de abajo |
| **Total** | **≈ 49** | |

- **Al ritmo del plan** (4,6 sp por semana): 9,5 semanas dan unas 43,7 sp. **Ya sin «Por despachar» falta capacidad** (unas 3 sp); con ella faltan unas 5 sp, es decir, poco más de una semana.
- **Al ritmo observado** (más de 1 sp por hora efectiva), construir no es el cuello de botella. Lo son la QA, las cargas con la máquina sola, las firmas y la regla de un solo editor por árbol.
- **Conclusión:** «Por despachar» cabe **solo si la tanda 3 sigue siendo el fusible**, que es lo que ya está firmado («sale de la entrega 1 si no cabe»).
- La parte de B (unas 0,7 sp: casilla en la Ágil, reportes y capacidad) cabe en su ola 5.

### 3.1 Orden propuesto para A

1. **14-oct:** corridas oficiales de QA (sin cambios).
2. **15-oct:** ADR-118/119 (T1, T2, T4 y T6) con `GPOS.Componentes`.
3. Búsqueda sin tildes.
4. **Tanda UF-05** (unas 0,5 sp; adelanta lo que la ola 5 necesita para su contrato):
   - `OrigenInventario` (F y C) y la regla de los «sin movimientos»;
   - 51380 leyendo la columna;
   - A-Q8 con la entrada por devolución mínima (A-Q12);
   - costo de la línea de la factura de conduce heredado del conduce (vistas, pregunta 2);
   - `TipoIdentificacionCliente` (vistas, pregunta 1);
   - claves de los privilegios nuevos (vistas, pregunta 5).
5. Fase A del segundo factor, con V-08, antes de la ola 5 como está firmado.
6. **Hacia el 22-23 oct:** unir la ola 5.
7. Núcleo de caja: reimpresión y redondeo del vuelto.
8. Ola 3b.
9. **«Por despachar» mínima** (N-B1 a N-B3, N-B3b, N-B5 a N-B8, A-Q9 y pruebas).
10. **Punto de control hacia el 13-nov:** si queda calendario, la tanda 3; si no, la tanda 3 pasa a la siguiente entrega (ya firmado).
11. T-34, el corte (T-35 a T-39), RN-24, H-17 y lo pendiente de Fable.

### 3.2 Qué sale si no cabe (en este orden)

1. **La tanda 3 completa** (≈ 19 sp, ya firmado como fusible). Efecto: la venta sigue solo en la unidad de venta o la base (UF-03) y la Farmacia fraccionada espera, lo que no afecta a la entrega 1.
2. Dentro de «Por despachar», sin perder control:
   - **N-B4**, el reenlace tras un rechazo de la DGII: ya está fuera de la mínima de B y va con la pista e-CF;
   - **N-B10**, el canónico: no hay conector ERP en la entrega 1;
   - **N-B9**, «Cerrar saldo sin entrega» (0,20): ningún saldo cumple el plazo de 90 días antes de unos tres meses de uso real. **Esto aplaza DP-2 y necesita el visto bueno del propietario (OD-2).**
3. **No se recortan:** el saldo `E` (impide despachar dos veces), la nota que no mueve inventario, la entrada con conduce de origen y sus dos reportes de excepción (el contador los pide antes de producción, [CT] 6.6).

---

## 4. Choque: UX-10 frente a FR-Q2 b (para el propietario, OD-3)

- **UX-10 (firmado el 2026-10-09):** el conteo no guarda el desglose «cajas + sueltas». Se cuenta en una unidad y se guarda en base (`decisiones-por-registrar-2026-10-08.md:160`).
- **FR-Q2 b (firmado):** las sueltas nunca forman una caja.
- **FR-Q7 (pendiente):** para cumplirlo, el conteo de un fraccionable captura por separado las cajas cerradas y las sueltas y fija el contador.

En un artículo fraccionable, el desglose deja de ser una comodidad de captura: es **estado del inventario**.

| Opción | Qué es | Costo | Riesgo |
|---|---|---|---|
| **(a) Recomendada** | UX-10 sigue para todos los artículos. **Excepción solo para los fraccionables** (entrega 3): el conteo captura «cajas cerradas» y «sueltas» y guarda las dos (la existencia en base y `Sueltas`) | 0,10 sp (N-A8 de [BP]) | Ninguno nuevo; es una precisión acotada de UX-10 |
| (b) | UX-10 sin excepción: el conteo fija solo la existencia y el sistema recorta `Sueltas` a `min(Sueltas, Existencia)` | −0,10 sp | Después de un conteo, el contador de sueltas se aparta de lo físico (R-A3) y se venden como caja tabletas sueltas: incumple FR-Q2 b |
| (c) | UX-10 sin excepción en el conteo, más una operación aparte «Ajuste de sueltas» (sin kárdex, con privilegio y bitácora) | 0,15 sp | Dos operaciones para un mismo recuento; depende de que alguien haga la segunda |

No afecta a la entrega 1: solo hay fraccionables con la tanda 3 y la Farmacia.

---

## 5. Vistas de la ola 5, revisión 4: preguntas 1 a 6

1. **Tipo de identificación.**
   - **Recomendación:** agregar `TipoIdentificacionCliente char(1) NULL` (R = RNC, C = cédula, P = pasaporte) a `ventas.Venta` y `fiscal.Comprobante`, fijado en la emisión desde el maestro o, con el cliente genérico, desde lo que indique el cajero.
   - **Descartado:** sellar (enmascarar) el pasaporte en la venta, porque se pierde un dato que el e-CF puede necesitar (`IdentificadorExtranjero`; inferido, por verificar en el XSD) y que el cifrado de RS-05 va a proteger de todos modos.
   - **Costo:** unas 0,10 sp, con el selector del tipo en la caja cuando se teclea una identificación con el cliente genérico (lo confirma UX).
   - **Tanda:** la tanda UF-05, antes de la 1.0 del contrato. **Técnico de A.**
2. **Costo de la línea de una factura de conduce.**
   - **Ya viene, no es 0:** `Ventas.cs:182` le pone a toda línea el `CostoEfectivo` del artículo, por unidad base (`VentasNg.cs:39`).
   - Pero es el costo **del día de la factura**, no el del movimiento del conduce.
   - **Recomendación:** para `OrigenInventario` = C, la línea hereda el `CostoUnitario` del movimiento de salida del conduce (en base), con la misma regla que la devolución. Unas 0,03 sp, en la tanda UF-05.
   - Para `P`, el costo real sale de los conduces de despacho: `rptc` debe tomarlo de ellos y no de la línea de la factura (B, al diseñar `rpt.PorDespachar`).
3. **Movimiento de clase 7 (CNT).**
   - **Costo:** **sí**, lleva el costo del renglón: el `CostoEfectivo` del artículo, por unidad base, que fija el servidor (OB-03, `InventarioService.cs:388-391`). El movimiento usa ese valor (`:456-459`); el renglón lo guarda redondeado a 6 decimales (`:445`). Inferido: no hay diferencia práctica, y V-D19 puede comparar con tolerancia 0 si los dos van a 6 decimales.
   - **Unidad:** el movimiento lleva **`UnidadId` y `FactorUnidad` con valor y `CantidadOrigen` en NULL**, a propósito (`:454-455`), porque la diferencia la calcula el motor en base y R1 admite «unidad con factor y sin origen».
4. **`caja.Cierre.Anulado` y el estado 2.**
   - **Coinciden por construcción:** el único escritor de `Anulado` (`ConsultasCaja.cs:259`) corre en la misma transacción que `DocumentosNg.AnularAsync` (`CierresCajaService.cs:211-213`).
   - No hay `CHECK` entre las dos tablas.
   - **Recomendación:** que la vista tome `doc.Documento.Estado` como fuente de verdad; las dos condiciones juntas también son correctas.
5. **Identificador del privilegio.**
   - Usar la **clave** del catálogo, no el nombre visible: `vercostos` (`Permisos.cs:121`), igual que `sincomprobante` y `fechaanterior`.
   - Para los dos nuevos, A fija ahora **`verdatospersonales`** y **`vercuadrecaja`**. B cambia el contrato antes de recalcular la huella.
6. **Nombre de la columna del RNC.** **`RncReceptorEnmascarado`**: así lo dicen ADR-109 en `master` («sufijo `Enmascarada` o `Enmascarado`») y la revisión firmada (`revision-rpt-rptc-sensibles-2026-10-09.md:73, 136`). La prueba estática reconoce `Enmascarad[ao]$`.

**Al unir la ola 5 (sin cambios):** los dos privilegios en el catálogo y las pruebas V-D1b ampliada, V-D18 a V-D23 y V-C1 con motor.

---

## 6. Kit de conectores (ADR-124, D-K4 y D-K5)

- **D-K4: de acuerdo**, con cuatro condiciones:
  1. el identificador del paquete sigue siendo `GPOS.Conectores.Contratos` (PA-07 A de la hoja de ADR-73);
  2. versiones `0.x` de prueba (`-alfa`) mientras se publique desde `GPOS-NG-AddOn-Kit`;
  3. todo cambio del contrato pasa por la revisión de A (archivo de dueños del código o aviso en el área común);
  4. con T-29, después del corte, el código pasa a la solución del núcleo y la 1.0 se publica desde ahí; el kit lo consume como dependencia.

  Verificado: el contrato no existe todavía en `472d078`. Costo para A: unas 0,05 sp de revisión.
- **D-K5: sí, al paquete del núcleo (`GPOS.Conectores.Contratos`), no al kit.** Los estados canónicos y el esquema de capacidades los necesitan también los conectores ERP (AdmCloud), y el kit es solo de e-CF y no se comparte con AdmCloud (ADR-124, punto 10). Además, el núcleo valida las capacidades declaradas (ADR-73.3).
- **Nombre del campo:** **`contingenciaReemplazo`** (booleano: el conector emite el reemplazo de un NCF emitido en contingencia, código 4). Ya lo usan la hoja de AdmCloud (AC-07) y el diseño de Polaris en `master` (`docs/integraciones/2026-10-08-conector-polaris-diseno.md:130, 152`). `contingenciaTipo1` no dice qué capacidad declara; el conector IQ hace la traducción.

---

## 7. Farmacia: unidad mínima como base desde la entrega 1

- **Ya se puede, verificado:**
  - el **alta** crea el artículo con `UnidadBaseId` = la unidad de venta (`MaestrosService.Articulos.cs:313`);
  - la **importación** también (`ComandosImportacion.cs:248-253`, `VALUES (... o.UnidadVentaId, o.UnidadVentaId ...)`) y crea `cat.ArticuloUnidad` con factor 1 (`:256-262`).

  Un medicamento dado de alta con la unidad de venta TAB nace con base TAB. Con la tanda 3, la CAJA × 21 se agrega como unidad nueva: R7 permite agregar unidades, solo prohíbe cambiar el factor de una unidad usada o la base.
- **Lo que no se puede todavía** (A-Q2): declarar CAJA × 21. **Trampa:** si se importa con la unidad de compra CAJA, nace con **factor 1**, y una compra de 10 cajas suma 10 tabletas. Hasta la tanda 3, el artículo fraccionable debe usar TAB también en la compra. Esto vale para cualquier artículo con unidad de compra distinta en la entrega 1 (observación Media, latente: ADR-078 ya lo reconoce).
- **¿Aviso al crear un artículo de Farmacia?** **No en la entrega 1.**
  - El núcleo no sabe qué artículo es un medicamento hasta el diseño `far` (principio activo, entrega 3).
  - En la entrega 1 no hay ventana de Farmacia.
  - **Recomendación:** el texto de ayuda de la plantilla de importación (0,01 sp) y, con la tanda 3 y la extensión FAR, un aviso en la ficha cuando un artículo fraccionable tenga una base mayor que su unidad más pequeña.
- **Si se implanta una farmacia antes de la tanda 3 (OD-4):** columnas `UnidadBase`, `FactorVenta` y `FactorCompra` en la plantilla, solo al crear (UX firmado: «la importación solo crea»). Unas 0,15 sp en la entrega 1.

---

## 8. V-08: limitador por IPv6 completa

- **Verificado:** la clave es `RemoteIpAddress.ToString()` (`LimitesPeticiones.cs:105`) en el login (`:61`) y en el límite general anónimo (`:89`). También en las particiones sin sesión de reportes, numeración, búsqueda e importaciones (`:53-54` y `:62-66`).
- **Recomendación:**
  - una función `ClaveIp` que normaliza el IPv4 mapeado (`::ffff:a.b.c.d` → IPv4) y, en IPv6, devuelve el prefijo /64;
  - **dos niveles** con `PartitionedRateLimiter.CreateChained`: la dirección completa con el cupo actual y el /64 con 4 veces ese cupo (parámetro en `OpcionesLimites`), solo en el login y en el general anónimo;
  - las rutas con sesión siguen por usuario.
- **Costo:** unas 0,05 sp con pruebas.
- **Tanda:** entrega 1, junto con la fase A del segundo factor (toca el login y cierra SF-01 a SF-03), y en todo caso antes de exponer la API central a internet (sucursales en línea, ADR-53). Severidad Baja: en una red local con IPv4 no aplica. **Técnico de A, sin firma.**

---

## 9. Decisiones para el propietario

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| **OD-1** | ¿«Por despachar» (Estándar y factura de crédito) entra en la entrega 1 **antes** que la tanda 3 de equivalencias? | (a) Sí; la tanda 3 sigue siendo la primera que sale si no cabe. (b) No; «Por despachar» va después del corte. (c) Las dos; se mueve el corte | **(a).** Corrige una salida falsa de inventario (defecto de existencias antes que función nueva) y cuesta unas 2,2 sp de A frente a ≈ 19. Con (b), el cliente que factura sin entregar sigue registrando salidas falsas |
| **OD-2** | ¿Se aplaza «Cerrar saldo sin entrega» (DP-2) hasta antes de que el primer saldo cumpla 90 días? | Sí / No | **Sí** (−0,20 sp en la entrega 1). Ningún saldo llega al plazo antes de unos tres meses de uso real |
| **OD-3** | UX-10 frente a FR-Q2 b en el conteo (junto con FR-Q7) | (a), (b) o (c) de la sección 4 | **(a):** excepción solo para los fraccionables (+0,10 sp, entrega 3) |
| **OD-4** | ¿Se implantará alguna farmacia con la Estándar antes de la tanda 3? | Sí: factor en la plantilla (+0,15 sp en la entrega 1). No: nada en la entrega 1 | Responder con el plan comercial; **si no hay una conocida, No** |

**Para conocimiento, sin firma nueva (ya cubierto por ADR-113):** la devolución de una factura desde conduce dejará de mover el inventario. La mercancía que vuelve entrará por Entradas/Recepción, enlazada al conduce de origen (sección 1b). A-Q11 espera al contador (CT-Q8 y C-39), no al propietario.

## Supuestos
- Las sp son inferidas (±40 %) y vienen de [BP] y de la estimación del 2026-10-08. El ritmo del plan es de 4,6 sp por semana.
- La entrega 1 no tiene clientes con Farmacia ni Restaurante (las verticales son de la entrega 3).
- El XSD del e-CF tiene un campo para el identificador extranjero (sección 5, pregunta 1): no lo verifiqué.
- 51395 está libre: inferido de los rangos reservados del traspaso; lo confirma el arquitecto-datos.

## Decisiones candidatas a ADR
1. `OrigenInventario` (F, C, O, P) con la regla «sin movimientos propios si no es F», como precisión de ADR-113 y ADR-078. Descartadas: columna `bit` aparte; heurística `@origenMovio`.
2. Contador de sueltas como columna de `inv.Existencia`/`inv.ExistenciaLote`, como precisión de ADR-104. Descartada: tabla `inv.ExistenciaSuelta` con un nivel de bloqueo propio.
3. El anticipo facturado de un servicio no es un saldo a favor, como precisión de ADR-70 (con la tanda, en la entrega 3).
4. Limitador de dos niveles (dirección y /64), como nota de seguridad del núcleo.

## Entregas a otros agentes
- **arquitecto-datos (A):** `OrigenInventario` con su regla y número de error; enlaces y clases `E` y `V`; `Sueltas` en existencia; `TipoIdentificacionCliente`; `ConduceOrigenId` en las entradas.
- **backend (A):** tanda UF-05; V-08 con la fase A del segundo factor.
- **disenador-ux-ui (A):** selector del tipo de identificación con el cliente genérico.
- **B:** cambiar las claves de privilegio y `RncReceptorEnmascarado` en el contrato; cortar el costo de `P` desde los conduces en `rptc`; condiciones de D-K4.
- **arquitecto-integraciones:** descuento global del anticipo en el XSD, con IQ.
- **especialista-contable:** CT-Q8.
- **arquitecto-maestro:** OD-1 a OD-4 para la firma del propietario; precisiones de ADR candidatas.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\respuestas-b-fraccionada-por-despachar-2026-10-09.md`
- Supuestos: sp inferidas (±40 %); sin Farmacia ni Restaurante en la entrega 1; XSD del identificador extranjero sin verificar; 51395 libre (inferido)
- Decisiones candidatas a ADR: `OrigenInventario` con regla inversa; `Sueltas` en las filas de existencia; anticipo fuera de ADR-70; limitador /64
- Entregas a otros agentes: arquitecto-datos, backend y UX de A; B; arquitecto-integraciones; especialista-contable; arquitecto-maestro (OD-1 a OD-4)
- Próximo paso recomendado: que el maestro lleve OD-1 a OD-4 al propietario y que A avise a B las respuestas de vistas (claves y nombre) antes de recalcular la huella de la ola 5
