# Vertical Corporativa (cafetería interna): criterio contable, fiscal y de control

**Especialista contable y fiscal (RD)** · 2026-10-15 · versión 2, con las precisiones del propietario del mismo día · Estado: **Completado. Recomendación técnica; las decisiones son del propietario (C2).**

## Caso principal (precisión del propietario, 2026-10-15)

**Literal:** «La cafetería es propiedad de la empresa, pero la administra una empresa de terceros. El sistema controla los consumos y es parte de la empresa propietaria de la cafetería. A cada empleado se le asigna un subsidio y si consumen el total antes del mes, pueden pagar con su propio dinero para adquirir lo que deseen. También la empresa les asigna un Almuerzo y una cena subsidiado 100%. y algunos artículos con solo la mitad subsidiado en donde el empleado aporta la proporción restante.»

**Postura del propietario:** «todos estos consumos son internos y no generan un NCF.» Solo los visitantes que lo pidan reciben un comprobante con NCF.

**Qué hace este documento:**
- da el soporte normativo de esa postura;
- señala con precisión dónde puede no sostenerse ante la DGII, con la norma citada;
- para cada riesgo, propone la salida que **menos altere** su diseño e indica su severidad.

---

## 0. Respuesta corta

| Porción del consumo | ¿Sostiene la postura «interno, sin NCF»? | Severidad del riesgo | Salida que menos altera el diseño |
|---|---|---|---|
| **Porción subsidiada** (bolsa mensual, almuerzo y cena al 100 %, la mitad subsidiada de los artículos al 50 %) | **Sí, con una condición.** No hay venta: es un retiro gratuito de bienes de la empresa para sus empleados. La DGII acepta que el autoconsumo se ampare con **documentos internos** y se **declare** en el IT-1 (Consulta 23-2025). La condición es declarar el ITBIS del retiro sobre el costo | **Media** si no se declara; **Baja** si se declara | Vale interno sin NCF (como pide el propietario) más un reporte mensual al costo para el IT-1 y el IR-17 |
| **Porción que el empleado paga con su dinero** (después de agotar la bolsa, y la otra mitad de los artículos al 50 %) | **No.** Es una transferencia **onerosa**: el empleado compra bienes de la empresa. El Código Tributario obliga a emitir un comprobante (art. 50, lit. k) y el ITBIS nace al entregar el bien (art. 338, num. 1) | **Alta** | Un **e-CF de consumo (E32) automático y solo por el dinero del empleado**, emitido por la misma empresa, sin que el cajero elija nada. El vale interno se conserva. El empleado no da datos (por debajo de RD$250.000 va el cliente genérico) |
| **Visitante** | No aplica (el propietario ya prevé el NCF) | — | E32, o E31 si lo pide con su RNC |

**El emisor es la empresa propietaria**, siempre que el contrato con el tercero sea de **administración por cuenta de la empresa**. Si en la sustancia es una **concesión** (el tercero compra en su nombre y vende por su cuenta), el emisor es el tercero y la postura «interno, sin NCF» **no se sostiene en ninguna porción** (sección 1).

**Desde noviembre de 2026 no hay serie B** (los medianos y grandes desde el 1-nov y los pequeños desde el 15-nov), salvo en contingencia. Todo comprobante de esta vertical será un **e-CF**.

---

## 1. ¿Quién es el vendedor ante la DGII?

**Criterio:** la DGII mira **la sustancia**, no el nombre del contrato. El contribuyente del ITBIS es quien transfiere los bienes o presta el servicio en ejercicio de su actividad (art. 337, lit. a). Las preguntas decisivas son estas:
- ¿a nombre de quién (de qué RNC) se compra la mercancía?
- ¿de quién es el inventario?
- ¿a qué cuenta va el efectivo que cobra la caja?
- ¿quién asume la pérdida si la cafetería no cubre sus costos?

| Elemento | **Modelo A: administración por cuenta de la empresa** (lo que describe el propietario) | **Modelo B: concesión** |
|---|---|---|
| Compras e inventario | A nombre de la **empresa** (su RNC; los comprobantes de compra a su nombre) | A nombre del **tercero** |
| Efectivo de la caja | Es de la **empresa**: se deposita en su cuenta y el tercero rinde cuentas | Es del tercero |
| Riesgo económico | De la empresa. El tercero cobra un honorario (fijo o un porcentaje) | Del tercero, que gana el margen |
| Sistema (GPOS) | De la **empresa** («es parte de la empresa propietaria») | Del tercero |
| **Vendedor ante la DGII** | **La empresa propietaria** | **El tercero** |
| Consumo subsidiado | **Retiro gratuito** de bienes de la empresa para sus empleados (art. 336, num. 2), sin venta | **Venta** del tercero a la empresa (E31) por el subsidio |
| Dinero del empleado | Venta de la **empresa** al empleado (E32 de la empresa) | Venta del tercero al empleado (E32 del tercero) |
| ¿Se sostiene «interno, sin NCF»? | **Sí para la porción subsidiada; no para el dinero del empleado** | **No en ninguna porción** |

**Señal de alarma (recomendación de control):** si en la práctica el tercero compra con su propio RNC y la empresa le «reembolsa», la DGII puede leerlo como una concesión. En ese caso, las salidas de la cafetería serían ventas del tercero sin comprobante. El modelo A exige que **las compras de la cafetería entren a nombre de la empresa** (por GPOS o por el ERP) y que **el efectivo se deposite en su cuenta**.

**El servicio del administrador tercero (fuera del alcance de GPOS):**
- El tercero factura a la empresa su **honorario de administración** con su propio e-CF (E31, ITBIS del 18 %). Ese servicio no está en la lista de exentos del art. 344.
- Si el tercero es **persona física**, la empresa le retiene el **100 % del ITBIS** (Decreto 293-11, art. 25, párrafo I; Consulta 2-2024), más la retención del ISR que defina el contador.
- Si el tercero es persona jurídica, la retención del 30 % de la NG 02-05 solo aplica a los servicios profesionales liberales o al alquiler de bienes muebles (Consulta 2-2024). Si el honorario de administración entra en esa categoría, lo dice el contador (CC-11).
- La factura del tercero la registra el **ERP de la empresa** (CxP y 606).
- **GPOS solo aporta, si el honorario es un porcentaje, el reporte de ventas y consumos que sirve de base para calcularlo.**

---

## 2. Las tres formas de consumo (modelo A)

**Ejemplos:** precios con ITBIS incluido al 18 %. Los costos son ilustrativos.

### 2.1 Almuerzo y cena subsidiados al 100 %

- **Documento:** **vale de consumo interno**, sin NCF, que mueve el inventario como **salida de clase 5 con `EsConsumoInterno`** (ADR-112, punto 10), al costo.
- **Naturaleza:** retiro a título gratuito para el consumo de los empleados (art. 336, num. 2). La base del ITBIS es el valor asignado, **no menor que el costo** (art. 340, lit. a).
- **Soporte para la postura del propietario:** la Consulta 23-2025 dice que el autoconsumo se presenta en el IT-1 como «otras operaciones (positivas)» **con documentos internos** (conduce o salida de inventario; NG 05-2019, art. 12). No exige un NCF.
- **Ejemplo:** almuerzo con un precio de lista de RD$354,00 y un costo de RD$180,00. No hay venta.

  | Si el contador confirma el retiro gravado (CC-07) | |
  |---|---|
  | Base | 180,00 |
  | ITBIS (18 %) | 32,40 |
  | Dónde se declara | IT-1 de la empresa, en «otras operaciones» |
  | Comprobante | Ninguno |

### 2.2 Bolsa mensual (subsidio con tope)

- **Mientras alcanza el saldo de la bolsa:** igual que en 2.1 (vale interno y retiro al costo).
- **La bolsa se mide en pesos al precio de lista** (es un control del beneficio). **El dato fiscal es el costo.** GPOS guarda los dos.
- **Bolsa sin usar a fin de mes:** vence sin efecto fiscal (no hubo retiro). Recomendación en D-06.

### 2.3 Artículos subsidiados al 50 %

- Hay **una línea con dos porciones:** la mitad gratuita (vale interno) y la mitad que paga el empleado (venta; sección 3).
- **Ejemplo:** refresco con un precio de RD$59,00 (base 50,00 más ITBIS 9,00) y un costo de RD$30,00.
  - **Porción del empleado:** paga RD$29,50, que se descomponen en una base de 25,00 y un ITBIS de 4,50. Va en el **e-CF de la sección 3**.
  - **Porción subsidiada:** retiro al costo proporcional, de 15,00. El ITBIS del retiro, de 2,70, solo se declara si el contador lo confirma.

---

## 3. El dinero del empleado: dónde no se sostiene «sin NCF»

**Casos:**
- la bolsa se agotó y el empleado paga con su dinero;
- la otra mitad de un artículo al 50 %;
- un consumo que agota la bolsa a medias.

**Normas:**
1. **Hay transferencia onerosa:** el empleado entrega dinero a cambio de bienes de la empresa. El ITBIS grava la transferencia de bienes industrializados (art. 335, num. 1; art. 336, num. 2). La comida preparada es un bien transformado (art. 336, num. 1). La venta de almuerzos «de consumo general» está gravada (Consulta 4-2025).
2. **El ITBIS nace** al emitir el documento «o desde que se entregue o retire el bien, si dicho documento no existiese» (art. 338, num. 1). **No emitir el comprobante no evita el impuesto:** solo lo deja sin documento.
3. **La obligación de comprobante** recae sobre quien transfiere bienes «a título oneroso o gratuito» (art. 50, lit. k, citado en la NG 06-2018; Decreto 254-06, art. 2). El incumplimiento es una falta a los deberes formales que se sanciona por el **art. 257** (NG 06-2018, art. 12). Bajo la Ley 32-23, la sanción va de **5 a 30 salarios mínimos** (fuentes secundarias).
4. **Además:** el efectivo que entra a la caja sin un documento fiscal que lo respalde es un **ingreso sin soporte**. En una fiscalización se presta a la presunción de ingresos omitidos (inferido; no cité un artículo).

**Severidad: Alta.** El monto de cada caso es pequeño, pero la falta es **sistemática** (todos los días y en cada caja), y la caja diaria (el Z) la deja documentada.

**Pago mixto de un consumo que agota la bolsa.** Consumo de RD$354,00 con un saldo de bolsa de RD$100,00 y un costo de RD$180,00:

| Porción | Monto | Documento | ITBIS |
|---|---|---|---|
| Bolsa | 100,00 (al precio de lista) | Vale interno | Retiro sobre el costo proporcional: 180 × 100/354 = 50,85; ITBIS 9,15, si se confirma (CC-07) |
| Dinero del empleado | 254,00 | **E32** de la empresa | Base 215,25 + ITBIS 38,75 = 254,00 (ITBIS incluido; los centavos del redondeo van al ITBIS de la última parte) |

**Salidas, de menor a mayor cambio en el diseño del propietario:**

| # | Salida | Cambio en el diseño | Riesgo que queda | Recomendación |
|---|---|---|---|---|
| S-1 | **E32 automática solo por el dinero del empleado.** La emite la empresa propietaria por la ruta única de emisión, con el cliente genérico (por debajo de RD$250.000 no se piden datos ni se identifica a nadie en el e-CF) | Mínimo. El vale interno sigue igual. Cuando hay una forma de pago con dinero, el sistema agrega la E32 por esa porción. **El cajero no elige.** El empleado recibe el vale con el e-NCF de su parte | **Bajo** | **Recomendada** |
| S-2 | **Una E32 global diaria** por el total cobrado a los empleados en el día y la caja | Menor que S-1 en la caja: un solo e-CF por día | **Medio.** El comprobante global diario solo lo admite el Decreto 254-06 (art. 3, párrafo II) **con autorización de la DGII**. En el e-CF, el comprador de la E32 no recibe un comprobante en el momento. Requiere la autorización previa y la respuesta del contador (CC-12) | Solo si la DGII lo autoriza |
| S-3 | Una E32 por **período mensual** por el dinero del empleado | El menor de todos | **Alto.** No tiene apoyo normativo: el ITBIS nació en cada entrega y el empleado pagó sin comprobante | No recomendada |
| S-4 | **Que el dinero no lo cobre la cafetería:** el exceso se descuenta por nómina o se precarga a la bolsa | Medio | **No resuelve.** El descuento por nómina o la precarga siguen siendo una contraprestación del empleado, así que la transferencia sigue siendo onerosa. Además, el descuento salarial tiene el límite del art. 201 del Código de Trabajo | No resuelve el punto fiscal |
| S-5 | **Que cobre otra figura** (el administrador tercero vende con su propio RNC la porción pagada) | Alto | **Alto.** El tercero tendría que comprarle la mercancía a la empresa (otra transferencia gravada, con su comprobante) y emitir sus propios e-CF. Mezcla los modelos A y B | No recomendada |
| S-6 | **Eliminar el dinero del empleado:** todo es subsidio (sin pago al agotar la bolsa y artículos al 100 % o al 0 %) | Cambia el negocio, no el sistema | **Bajo.** Todo queda como retiro interno y la postura «sin NCF» se sostiene completa | Alternativa válida si el propietario prefiere no emitir nada a los empleados |

**Conclusión del punto 3:**
- **S-1 respeta la postura del propietario en todo lo subsidiado**, que es la mayor parte del volumen, y solo agrega un e-CF donde hay dinero.
- **S-6 es la única forma de sostener «sin NCF» en el 100 % de los casos.**

---

## 4. Tratamiento para la empresa (advertencia para su ERP o su nómina; no es tarea de GPOS)

- **Retribución complementaria:** la DGII incluye los «**gastos alimenticios**» y grava el beneficio con un elemento personal **individualizable** (Guía 14; Código Tributario, art. 318). La tasa es del **27 %**, a cargo del empleador, y se declara y paga en el **IR-17** a más tardar el día 10.
  - **El control por empleado de la vertical (bolsa, almuerzo y cena por persona) individualiza el beneficio.**
  - Lo prudente es que el contador de la empresa evalúe el IR-17 sobre el costo del subsidio por empleado.
  - GPOS le entrega el dato: reporte mensual por empleado, al costo y al precio de lista.
- **ITBIS del retiro:** sobre el costo (art. 340, lit. a), en el IT-1 como «otras operaciones» (Consulta 23-2025). Lo decide el contador (CC-07).
- **Gasto deducible:** la empresa compra los insumos con sus propios comprobantes (E31 de sus suplidores). El gasto de alimentación es deducible si se cumple lo del IR-17 (Guía 14; art. 87 del Reglamento 139-98, citado por la DGII en la Consulta 26-2025, que no leí).
- **Severidad para la empresa** si no evalúa el IR-17: **Media** (reliquidación del 27 % más recargos). No afecta al diseño de GPOS.

---

## 5. Qué registra GPOS y qué va al ERP (modelo A)

| Concepto | GPOS NG (auxiliar y fiscal, ADR-73) | ERP de la empresa |
|---|---|---|
| Vale interno (porción subsidiada) | Documento no fiscal con secuencia propia sin huecos; salida de inventario de clase 5 al costo; saldo de la bolsa por empleado; bitácora | Asiento del gasto de personal (alimentación) contra el inventario |
| Dinero del empleado (S-1) | E32 por la ruta única, caja y Z | Ingreso por ventas e ITBIS por pagar |
| Visitante | E32 o E31 y caja | Ingreso e ITBIS |
| Reporte mensual de consumo interno | Total al costo y al precio de lista, por empleado y por tipo de subsidio | ITBIS del retiro (IT-1) y retribución complementaria (IR-17) |
| Compras de la cafetería | Recepción a nombre de la empresa (si usa GPOS) | 606 y CxP |
| Honorario del administrador | Reporte de base, si es un porcentaje | E31 del tercero, CxP, retenciones y 606 |

**Asientos de referencia para el conector** (GPOS no los genera):

| Evento | Débito | Crédito |
|---|---|---|
| Vale interno | Gasto de personal: alimentación | Inventario de la cafetería (al costo) |
| ITBIS del retiro (si se confirma) | Gasto de ITBIS no recuperable | ITBIS por pagar |
| E32 del empleado | Caja | Ingresos de la cafetería; ITBIS por pagar |
| Costo de la porción vendida | Costo de ventas | Inventario |
| Retribución complementaria (IR-17) | Gasto de impuesto sustitutivo (no deducible) | Retenciones por pagar |

---

## 6. Control interno (NOBACI y COSO)

### 6.1 Segregación de funciones (ADR-106)

| Función | Quién | Incompatible con |
|---|---|---|
| Padrón (alta, baja, foto, categoría, bolsa asignada) | RR. HH. de la empresa | Caja |
| Configurar bolsas, artículos al 100 % y al 50 %, y horarios | ADMIN de la empresa, con privilegio y bitácora | Caja y administración del tercero |
| Despachar y cobrar | Cajero (personal del tercero) | Padrón y configuración |
| Autorizar excepciones (sin carné, fuera de horario, segundo almuerzo, anulación) | Supervisor (ADR-68). Nunca el mismo cajero | Despachar ese vale |
| Recibir y depositar el efectivo de la empresa | Tesorería de la empresa, a partir del Z del tercero | Caja |

**El efectivo lo cobra personal del tercero, pero es dinero de la empresa.** Por eso:
- el **Z por jornada** (ADR-17) con conteo ciego;
- el **depósito** en la cuenta de la empresa;
- la **conciliación** del Z con el depósito, a cargo de la empresa, no del tercero.

### 6.2 Identidad (carné con foto)

- La lectura del carné muestra la foto del padrón. El cajero **confirma** antes de despachar; sin confirmar, no hay vale.
- La foto se guarda una sola vez, cifrada (ADR-44 y ADR-67). El vale guarda la **huella** de la foto, quién confirmó y la hora.
- Es un dato personal: Ley 172-13 (no verifiqué sus artículos).
- **Controles detectivos:**
  - reporte de identificaciones manuales (sin carné, con la autorización del supervisor);
  - consumos del mismo empleado en dos cajas en pocos minutos;
  - **almuerzo o cena al 100 % repetidos el mismo día**, que el servidor rechaza;
  - consumos de empleados dados de baja, que el servidor también rechaza.

### 6.3 Topes y horarios

- **Bolsa mensual, almuerzo y cena (uno por franja y día):** los valida **el servidor** con una actualización condicional del saldo. Dos cajas a la vez no pasan el tope.
- **El horario del artículo** decide si es elegible para el almuerzo o la cena al 100 %. Fuera de la franja, el artículo se paga (sección 3) o se bloquea, según la configuración.

### 6.4 Bitácora (`_LOG`)

Se registran:
- los cambios del padrón y de la foto;
- los cambios de bolsas, porcentajes y horarios;
- las identificaciones manuales y las excepciones;
- las anulaciones de vales;
- los ajustes de la bolsa (con motivo);
- la emisión de los E32;
- la exportación de los reportes mensuales, con su huella (ADR-111).

**«No generar comprobante» (evento 4901) no es la vía ordinaria:** el vale interno es otro tipo de documento, no una venta sin NCF.

### 6.5 Reversos

| Caso | Corrección |
|---|---|
| Vale interno equivocado | Anulación con motivo y autorización de otra persona. **Devuelve la bolsa** o el derecho al almuerzo. Lo preparado va a merma (ADR-113, punto 5) |
| E32 del dinero del empleado | **Nota de crédito (E34)** contra la E32 (ADR-70). Un e-NCF no se anula (ADR-108); solo el rechazo de la DGII anula |
| Consumo mixto | Se revierten **las dos partes**: anulación del vale y E34 de la E32, enlazadas |

### 6.6 Qué pediría un auditor (interno, externo o de la DGII)

1. **Integridad:** secuencia de vales sin huecos ni duplicados, a una fecha de corte.
2. **Cuadre del inventario de la cafetería:** salidas por vale interno (clase 5) + salidas vendidas (E32 y visitantes) + mermas = consumo del inventario del período.
3. **Cuadre de la caja:** Z = total de las E32 de empleados y visitantes = depósito en la cuenta de la empresa.
4. **Ningún cobro de dinero sin e-CF:** prueba de que toda forma de pago con dinero de un vale tiene su E32.
5. **Excepciones con su autorizante** y la segregación demostrada con la bitácora.
6. **Reporte mensual al costo**, reproducible, que sirve de base para el IT-1 (retiro) y el IR-17 (retribución complementaria).

---

## 7. Variantes (breves)

| Variante | Resultado |
|---|---|
| **Concesión** (el tercero compra, vende y factura el subsidio a la empresa) | El tercero es el emisor. **E32** al empleado por lo que paga y **E31** (o E44 si la empresa es de zona franca, o E45 si es del Estado) a la empresa por el subsidio, **diaria por omisión** y sin cruzar el mes (CE-03, firmada el 2026-10-09; CC-01 abierta). El vale previo solo vale si termina en ese e-CF. La venta de almuerzos no lleva la retención del 30 % (Consulta 4-2025). Si el tercero es persona física, se le retiene el 100 % del ITBIS (Consulta 2-2024) |
| **Comedor propio, gratuito y sin administrador** | Igual que el subsidio del modelo A: todo es interno |
| **Comedor propio que cobra todo** (sin subsidio) | E32 por cada consumo |
| **Visitante** | E32, o E31 con RNC. Desde RD$250.000, con nombre y documento (ADR-108) |

---

## 8. Encaje con lo firmado (para el Arquitecto Maestro)

- **CE-03 a CE-06** (catering y ejecutivos, firmada el 2026-10-09) suponen un **concesionario** (el modelo B): el «Cargo a la empresa» termina en una E31, y `CORPORATIVO` requiere `RESTAURANTE`. El caso real del propietario es el **modelo A**, en la **Estándar**, donde el subsidio **no se factura**: es un consumo interno. **Las dos vías deben convivir en un solo módulo**, con un «modelo de operación» por empresa (A o B) que decide la ruta fiscal. El cajero nunca la elige.
- **En la Estándar no hay cuenta ni orden.** El vale interno mueve el inventario (clase 5). La E32 de la porción pagada **no** lo vuelve a mover: lleva la marca «inventario ya descargado por el vale» (UF-05).
- **Ventana propia de la vertical:** nada de esto entra como parámetro de la Facturación Ágil (precisión de ADR-112, DY-01).

---

## 9. Decisiones para el propietario (cada una con mi recomendación)

| # | Decisión | Recomendación |
|---|---|---|
| **D-01** | ¿Confirma el **modelo A** (las compras a nombre de la empresa, el efectivo depositado en su cuenta y el tercero con un honorario)? | **Sí.** Es lo que sostiene que el subsidio sea interno. Si en la práctica es una concesión, rige la variante de la sección 7 |
| **D-02** | **Porción subsidiada** (bolsa, almuerzo y cena al 100 %, mitad de los artículos al 50 %): ¿vale interno sin NCF? | **Sí, según su postura**, con el reporte mensual al costo para que el contador declare el retiro (IT-1) y evalúe el IR-17. Riesgo residual: **Baja** |
| **D-03** | **Dinero del empleado** (al agotar la bolsa y en la mitad de los artículos al 50 %): ¿cómo se documenta? | **S-1: una E32 automática solo por la porción pagada.** El vale interno sigue igual y el cajero no elige. Alternativas: S-2 (E32 global diaria, solo con autorización de la DGII) o S-6 (eliminar el pago del empleado). **No recomiendo «sin NCF» en esta porción: severidad Alta** |
| **D-04** | Los artículos al 50 %, ¿se dividen solos en la línea (la mitad interna y la mitad en la E32)? | **Sí, automático,** con el redondeo en la porción pagada |
| **D-05** | ¿Con qué valor se registra el consumo interno? | **Con el costo** como dato fiscal (art. 340, lit. a) y con el precio de lista para controlar la bolsa |
| **D-06** | La bolsa no usada a fin de mes, ¿vence o se acumula? | **Vence.** Sin efecto fiscal y más simple de controlar. Acumularla convierte la bolsa en un saldo que hay que conciliar |
| **D-07** | ¿El almuerzo y la cena al 100 % son uno por franja y día, sin acumularse? | **Sí,** validado en el servidor. El segundo almuerzo solo se da con la autorización del supervisor |
| **D-08** | ¿Se guarda la foto del empleado en GPOS? | **Sí,** cifrada y una sola vez. El vale guarda la huella y quién confirmó |
| **D-09** | Si el carné no se lee, ¿se busca al empleado por nombre? | **Sí, con la autorización del supervisor** y una línea en la bitácora |
| **D-10** | El efectivo que cobra el personal del tercero, ¿lo concilia la empresa con el Z y el depósito? | **Sí.** El Z por jornada con conteo ciego y la conciliación con el depósito a cargo de la empresa |
| **D-11** | ¿Debe GPOS emitir o registrar la factura del honorario del administrador? | **No.** Es del ERP de la empresa. GPOS solo da el reporte de base si el honorario es un porcentaje |

## 10. Preguntas para el contador de la empresa (siguen a CC-01 a CC-05)

| # | Pregunta |
|---|---|
| CC-06 | El café, el chocolate o el yogur **preparados**, ¿tributan al 18 % o al 16 % del bien (art. 345, párrafo II)? |
| CC-07 | ¿El consumo subsidiado de la cafetería propia es un **retiro gravado** sobre el costo (art. 336, num. 2; art. 340, lit. a; Consulta 23-2025), declarado en el IT-1 como «otras operaciones»? ¿Y si la mayoría de los insumos son exentos (art. 343)? |
| CC-10 | ¿El subsidio por empleado es una **retribución complementaria** (27 %, IR-17)? ¿Sobre el costo o sobre el precio de lista? |
| CC-11 | El honorario de administración del tercero, ¿lleva alguna retención (NG 02-05; Decreto 293-11, art. 25)? |
| CC-12 | ¿Conviene pedir a la DGII la autorización de un **comprobante global diario** por el dinero de los empleados (Decreto 254-06, art. 3, párrafo II; salida S-2), o basta la E32 por cobro (S-1)? |
| CC-13 | ¿La actividad registrada de la empresa en el RNC le permite emitir E32 por la venta de comida a sus empleados (NG 06-2018, art. 3, párrafo III)? ¿Hace falta registrar una actividad secundaria? |
| CC-08 / CC-09 | Solo si hay zona franca o Estado: ¿E44 o E45, y qué retenciones? |

---

## 11. Fuentes

### 11.1 Repositorio (verificadas)

| Ref. | Ruta | Qué aporta |
|---|---|---|
| ADR-14 | `GPOS NG/docs/adr/ADR-014.md:181`, `:189-193` | «No generar comprobante» es explícito, deja el evento 4901 y no se fomenta |
| ADR-73 | `GPOS NG/docs/adr/ADR-073.md` (73.1 a 73.6) | Auxiliar y fiscal; los asientos son del ERP |
| ADR-112 | `GPOS NG/docs/adr/ADR-112.md:10`, `:14`, `:19` | La Estándar no es módulo; la ruta única de emisión; el consumo de personal es de clase 5 con `EsConsumoInterno` |
| ADR-113 | `GPOS NG/docs/adr/ADR-113.md:56-60` | El documento previo no fiscal; UF-05 |
| ADR-70 y ADR-108 | `GPOS NG/docs/adr/ADR-070.md`; `GPOS NG/docs/adr/ADR-108.md:20`, `:67` | La nota de crédito; la E32 por debajo de RD$250.000 sin identificar al comprador |
| ADR-111 | `GPOS NG/docs/adr/ADR-111.md:33` | Los reportes fiscales aplazados |
| Hoja CE | `git show a98edbe:docs/decisiones/2026-10-09-hoja-firma-catering-y-ejecutivos.md` | CE-03 a CE-06 firmadas; CC-01 a CC-05 abiertas |
| Tasas | `GPOS NG/docs/decisiones/2026-10-03-decision-modelo-datos-ng.md:349` | Tasas del 18 %, 16 %, 0 % y Exento. **El 16 % es correcto** como tasa reducida de los bienes del art. 345, párrafo II (yogur, mantequilla, café, grasas, azúcar, cacao y chocolate). **La general es el 18 %** (inferido: la reducción general del inciso iii quedó condicionada al párrafo I y no se aplicó) |

### 11.2 Normativa

| Fuente | Qué aporta | Verificación |
|---|---|---|
| [Código Tributario, Título III (DGII)](https://dgii.gov.do/legislacion/codigoTributario/Cdigo%20Tributario/Titulo3.pdf) | Arts. 335, 336 (num. 2: retiro para consumo de los empleados), 337, 338, 339, 340 (lit. a), 343, 344 y 345 | Texto leído |
| [Norma General 06-2018](https://ws945695e.dgii.gov.do/legislacion/normasGenerales/Documents/NG%20sobre%20Comprobantes%20Fiscales/Norma06-18.pdf) (01-feb-2018) | Considerandos (art. 50, lit. k), art. 2, art. 3 (párrafo III) y art. 12 (art. 257) | Texto leído |
| [Decreto 254-06](https://fc-abogados.com/dec-no-254-06-que-establece-el-reglamento-para-la-regulacion-de-la-impresion-emision-y-entrega-de-comprobantes-fiscales-2/) | Art. 2, art. 3 (párrafo II: comprobante global diario con autorización) y art. 8.4 b | Fuente secundaria |
| [DGII, Consulta 23-2025](https://dgii.gov.do/legislacion/consultas/Consultas%20Tecnicas%202025/Enero/Consulta%2023-ITBIS%20salida%20de%20inventario%20para%20uso%20interno.pdf) (08-ene-2025) | El autoconsumo está gravado y se declara con documentos internos en el IT-1 | Texto leído |
| [DGII, Consulta 4-2025](https://dgii.gov.do/legislacion/consultas/Consultas%20Tecnicas%202025/Marzo/Consulta%204-ITBIS%20Norma%2002-05.pdf) (17-mar-2025) | Los almuerzos están gravados y sin la retención del 30 % | Texto leído |
| [DGII, Consulta 2-2024](https://dgii.gov.do/legislacion/consultas/Consultas%20Tecnicas%202024/Marzo/Consulta%202-ITBIS%20Norma%2007-2007.pdf) (05-mar-2024) | La retención del 100 % del ITBIS a la persona física; la del 30 % de la NG 02-05 solo para los servicios liberales y el alquiler | Texto leído |
| [DGII, Guía 14, retribuciones complementarias](https://dgii.gov.do/publicacionesOficiales/bibliotecaVirtual/contribuyentes/retencionesRetribucionesComplementarias/Documents/1-Guia%2014-Impuesto%20Sustitutivo%20sobre%20Retribuciones%20Complementarias.pdf) | «Gastos alimenticios», el beneficio individualizable, el 27 % y el IR-17 | Texto leído; sin fecha |
| [DGII, Consulta 26-2025](https://dgii.gov.do/legislacion/consultas/Consultas%20Tecnicas%202025/Julio/Consulta%2026-Retribuci%C3%B3n%20complementaria.pdf) | Los bonos de supermercado son retribución complementaria; la deducción del gasto si se pagó el impuesto | Resumen de búsqueda; no la leí |
| [Formato del RFCE (DGII)](https://dgii.gov.do/cicloContribuyente/facturacion/comprobantesFiscalesElectronicosE-CF/Documentacin%20sobre%20eCF/Formatos%20XML/Formato%20Resumen%20Factura%20Consumo%20Electr%C3%B3nica%20v1.0.pdf) | La E32 de menos de RD$250.000 va en resumen | Búsqueda; puede haber una versión posterior |
| Plazos del e-CF (Ley 32-23 y Decreto 587-24): [EY](https://www.ey.com/es_ce/technical/tax/tax-alerts/republica-dominicana-dgii-otorga-prorroga-de-seis-meses-a-contribuyentes-identificados-como-pequenos-micros-y-no-clasificados-para-la-implementacion-de-fe), [Alegra](https://blog.alegra.com/republica-dominicana/prorroga-ecf-pymes/), [El Faro](https://www.elfarord.com/2026/08/dgii-informa-la-emision-exclusiva-de.html), [Diario Libre](https://www.diariolibre.com/economia/negocios/2026/09/10/dgii-advierte-no-habra-prorroga-para-la-factura-electronica/3655048), [DGII, Aviso 14-25](https://ws945695e.dgii.gov.do/publicacionesOficiales/avisosInformativos/Documents/2025/14-25.pdf) | Solo e-CF desde el 1-nov-2026 (medianos y grandes) y desde el 15-nov-2026 (pequeños); la serie B, solo en contingencia | Fuentes secundarias; no leí el aviso oficial |
| [Código de Trabajo, art. 201](https://fc-abogados.com/puede-hacerse-descuento-del-salario-ganado-por-el-trabajador/) | Los descuentos del salario permitidos | Fuente secundaria; no verifiqué si hay una reforma |

---

## 12. Resumen

- **En el caso real** (cafetería de la empresa, administrada por un tercero por cuenta de la empresa), **el emisor es la empresa propietaria.**
- **Su postura «consumo interno sin NCF» tiene soporte** en la porción **subsidiada** (bolsa, almuerzo y cena al 100 %, mitad de los artículos al 50 %):
  - es un retiro gratuito para los empleados (art. 336, num. 2);
  - la DGII acepta documentos internos y la declaración en el IT-1 (Consulta 23-2025);
  - la condición es declarar el ITBIS del retiro sobre el costo (art. 340, lit. a).

  Riesgo residual: **Bajo**.
- **No se sostiene en el dinero que paga el empleado** (al agotar la bolsa y en la otra mitad de los artículos al 50 %):
  - es una venta onerosa con obligación de comprobante (art. 50, lit. k; Decreto 254-06, art. 2);
  - el ITBIS nace al entregar el bien (art. 338, num. 1);
  - la sanción es la del art. 257.

  Severidad: **Alta**.
- **La salida que menos altera el diseño es S-1:** una **E32 automática solo por la porción pagada**, con el cliente genérico y el vale interno intacto. La única forma de no emitir nada a los empleados es **S-6**: que todo sea subsidio.
- **Si el contrato es en la sustancia una concesión**, el tercero es el emisor y nada puede ir sin comprobante.
- **Para la empresa:** el subsidio individualizado probablemente sea una retribución complementaria (27 %, IR-17). Es una advertencia para su contador y su ERP.
- **El honorario del administrador** lo factura el tercero (E31) y está fuera de GPOS.

### Cierre
- Estado: Completado (recomendación técnica; las decisiones D-01 a D-11 son del propietario)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\contable-vertical-corporativa-2026-10-15.md` (versión 2, sustituye a la versión 1 del mismo día)
- Supuestos:
  - El contrato real es de administración por cuenta de la empresa (D-01).
  - La tasa general es el 18 % (inferido).
  - Los plazos del e-CF, el Decreto 254-06, el art. 201 y la Ley 172-13 vienen de fuentes secundarias.
  - La presunción de ingresos omitidos es inferida, sin artículo citado.
  - Los costos de los ejemplos son ilustrativos.
- Decisiones candidatas a ADR:
  - (1) «Modelo de operación» por empresa en `CORPORATIVO` (A: interno, propiedad de la empresa; B: concesión, CE-03), que fija la ruta fiscal; alternativa descartada: que el cajero elija si emite NCF.
  - (2) Vale de consumo interno (clase 5) con E32 automática solo por el dinero del empleado (S-1); alternativas: E32 global diaria (S-2) o sin pago del empleado (S-6).
  - (3) `CORPORATIVO` también sobre la Estándar (precisión de CE-06 y de ADR-112).
- Entregas a otros agentes:
  - arquitecto-maestro → hoja de firma con D-01 a D-11 y la conciliación con CE-03 a CE-06;
  - arquitecto-software y arquitecto-datos → vale interno con secuencia, división automática de la línea al 50 %, bolsa y franjas en el servidor, E32 marcada «inventario ya descargado»;
  - auditor-seguridad → custodia de la foto;
  - diseñador-ux-ui → confirmación de la identidad con foto y visualización de la porción subsidiada frente a la pagada;
  - especialista-contable → sumar CC-06, CC-07 y CC-10 a CC-13 a la adenda del contador.
- Próximo paso recomendado: que el propietario decida D-01 y D-03, y enviar CC-07, CC-10 y CC-12 al contador de la empresa.
