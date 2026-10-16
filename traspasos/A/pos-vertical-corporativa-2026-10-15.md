# Blueprint POS: vertical Corporativa (comedor y cafetería internos)

[Blueprint POS] · Especialista en Sistemas POS · 2026-10-15 · Revisión 2: incorpora las dos precisiones del propietario del mismo día · **Estado de las decisiones: Pendiente de firma** (el propietario firma; este documento solo propone reglas operativas)

**Pedido del propietario (2026-10-15, resumen):** una vertical nueva, **Corporativa**, derivada de la Estándar, para organizaciones que atienden a clientes internos (empleados, ejecutivos y personal de servicio) en su cafetería o comedor. Los consumos se registran con tickets sin NCF para dar seguimiento al gasto por empleado. A los visitantes que la pidan se les emite factura con NCF. Pide también horarios por artículo, subsidio con tope, pago directo o endoso al subsidio, control del consumo de cada empleado e identificación inequívoca con un carné y la foto del empleado antes de despachar.

**Precisiones del propietario (2026-10-15, literales; mandan sobre todo lo demás):**
1. «La cafetería es propiedad de la empresa, pero la administra una empresa de terceros. El sistema controla los consumos y es parte de la empresa propietaria de la cafetería. A cada empleado se le asigna un subsidio y si consumen el total antes del mes, pueden pagar con su propio dinero para adquirir lo que deseen. También la empresa les asigna un Almuerzo y una cena subsidiado 100%. y algunos artículos con solo la mitad subsidiado en donde el empleado aporta la proporción restante.»
2. «Todos estos consumos son internos y no generan un NCF.»

**Convención:** *verificado* = lo leí en esta sesión, con `ruta:línea` o con la rama; *inferido* = deducción o estimación sin medir. No compilé ni ejecuté pruebas, no toqué SQL Server ni modifiqué código.

---

## 0. Fuentes y precedentes (verificados)

| Ref. | Fuente | Qué aporta |
|---|---|---|
| [ADR112] | `GPOS NG/docs/adr/ADR-112.md` (rama `origin/feature/modelo-ng`) | Cada vertical es un módulo de la licencia por empresa con tres niveles: licencia, activación y **modo de la caja**. **Solo el SUPER la activa** (punto 2). La API comprueba el módulo antes del permiso (404 `MODULO_NO_ACTIVO`, luego 403). **Ruta única de emisión** con `IExtensionVenta` (punto 5). El núcleo no referencia a las verticales (6). **En Tienda la factura mueve el inventario** (9). El consumo de personal va por la clase 5 con el motivo `EsConsumoInterno` (10) |
| [VENT] | Memoria `ventana-facturacion-por-vertical` y aviso `GPOS-NG-Equipos/avisos/A-a-B/2026-10-08-ventana-facturacion-por-vertical.md` | Cada vertical tiene **su propia ventana**. La Facturación Ágil es la ventana de la Estándar y no se toca. Lo común se comparte por `GPOS.Componentes` y por la ruta única de emisión |
| [DY-01] | `docs/decisiones/2026-10-08-hoja-firma-duty-free.md:44-54` | Precedente de una ventana propia («Facturación Duty Free»): ruta, opción de menú y guarda de módulo propias, con componentes nuevos sin tocar `PuntoVenta.razor` |
| **[CE]** | `origin/b/verticales-diseno:docs/decisiones/2026-10-09-hoja-firma-catering-y-ejecutivos.md` (**firmada el 2026-10-09 «todo según recomendación»**) | **Precedente directo.** CE-03: consumo «Cargo a la empresa» no fiscal y factura agrupada por período. CE-04: padrón de empleados y topes controlados en el servidor con un `UPDATE` condicional (ADR-45); sin cédula; sin PIN en la v1. CE-02: combo `K` con grupos de elección y menú del día. CE-05: reportes CO-01 a CO-04. **CE-06 (c) descartó «Corporativo en la Estándar (comedores industriales, cafeterías de empresa)… se hace con el primer cliente que lo pida»**: este pedido es ese caso |
| [CE-reg] | Búsqueda de `CORPORATIVO` y «Cargo a la empresa» en `origin/master` y `origin/feature/modelo-ng` | **Sin resultados.** Los ADR que proponía [CE] no están registrados: el número 126 quedó para otro tema (`origin/master:docs/adr/ADR-126.md`, valores de terceros) |
| [EMP] | `src/GPOS.Core/Dominio/Configuracion/Personas.cs:11-31` | `rrhh.Empleado` existe (MD-30: empleados y vendedores en una sola entidad), **sin foto, sin carné, sin categoría y sin centro de costo** |
| [CC] | `git grep CentroCosto` en `src/` | **No hay centro de costo** en el modelo |
| [HOR] | `git grep HoraDesde\|HoraInicio\|DiasSemana` en `Dominio` y `Contracts` | **No hay franjas horarias** en artículos ni en precios |
| [CAJA] | `src/GPOS.Core/Dominio/Configuracion/Organizacion.cs:86-108` | `org.Caja` todavía **no tiene el modo de la caja** de ADR-112, que está decidido pero no implementado |
| [MOT] | `database/empresa/gpos-empresa-20261015003000_Rg14RespaldoTope.sql:10617` | Ya existe el motivo de ajuste `CONSUMO` («Consumo interno», `EsConsumoInterno = 1`) |
| [NOGEN] | Memoria `no-generar-comprobante-permiso-bitacora` | En la Estándar, «No generar comprobante» exige un privilegio del grupo Especiales y deja una línea en `_LOG` |
| [ADR53] | Memoria `sucursal-en-linea-sqlite-y-licencia` | Una sucursal en línea **sin internet no vende**. La contingencia con SQLite local se construye **después de las olas** |
| [BP2] | Búsqueda de `comedor`, `subsid`, `carnet` (también en UTF-16) en `Solucion GPOS NG/BP2-NEW` (fuentes, `GPOST2.exe`, reportes y notas) | **BP2 no tenía nada de comedor, subsidio ni carné.** Solo aparece «empleado» como vendedor. No hay costumbre heredada que proteger (memoria `bp2-nunca-en-produccion`) |

**Modelos de operación.** El **caso principal** es el que precisó el propietario:

| Modelo | Quién es el dueño | Quién opera | Dónde está GPOS NG | Situación en este documento |
|---|---|---|---|---|
| **M-P (principal)** | La empresa | **Un administrador tercero** (empresa de alimentos) | **En la base de la empresa dueña** | **Caso principal**, base de todo el documento |
| M1 | La empresa | La propia empresa | En la base de la empresa | El mismo diseño, sin el bloque del administrador |
| M2 (concesionario) | El operador | El operador, que factura a la empresa cliente | En la base del operador | Ya diseñado en [CE] CE-03; queda fuera de este documento |

---

## 1. Contexto operativo

| Dato | Valor de diseño | Origen |
|---|---|---|
| Tipo de negocio | Cafetería o comedor **de la empresa**, que **administra un tercero**. GPOS NG pertenece a la empresa dueña y controla los consumos | Propietario |
| Comensales | De 100 a 2.000 por sede. Caso de cálculo: **300 empleados** | Inferido |
| Franjas | Desayuno, **almuerzo** y **cena** (las dos subsidiadas al 100 %) y una merienda opcional. El pico es el almuerzo: en una planta por turnos, del 40 al 60 % de los comensales llega en 30 minutos | Propietario, salvo los porcentajes, que son inferidos |
| Ritmo exigido | Con 300 comensales y el 50 % en 30 minutos: **unas 5 transacciones por minuto**. Con 10 a 12 s por transacción con carné, **hacen falta dos cajas por cada 300 comensales en el pico** | Inferido, ±30 % |
| Consumo típico | El almuerzo o la cena cubiertos al 100 % (sin dinero) son la mayoría de los tickets. El dinero aparece en los artículos al 50 % y cuando se agota la bolsa | Inferido |
| Conectividad | Oficina con internet corporativo (buena). Plantas y zonas francas con enlaces inestables y cortes eléctricos | Inferido |
| Objetivo de latencia | De la lectura del carné a la foto en pantalla: **menos de 1 s (p95)**. Confirmar el ticket: **menos de 1,5 s (p95)** | Propuesta |

**Actores:**
- **Cajero o despachador:** personal del **administrador tercero**.
- **Supervisor de la cafetería:** personal del tercero. Abre y cierra la caja y autoriza las excepciones operativas.
- **Comensal:** empleado, ejecutivo o personal de servicio.
- **Visitante.**
- **Administrador del beneficio:** RR. HH. o servicios generales de la **empresa dueña**. Lleva el padrón, los planes, las franjas y las bolsas.
- **Contabilidad y finanzas de la empresa dueña:** reciben los reportes.
- **Nómina:** recibe el corte, si se usa el descuento por nómina.

---

## 2. Los tres beneficios y cómo conviven (caso principal)

### 2.1 (B) Almuerzo y cena subsidiados al 100 %

| # | Regla | Recomendación |
|---|---|---|
| B-1 | **Uno por franja y por día.** Un almuerzo y una cena por comensal y por día, en la franja de su horario. El servidor lo garantiza con una marca única por comensal, fecha y franja, dentro de la transacción del ticket | Firmar |
| B-2 | **Qué es un «almuerzo» o una «cena»:** una **composición de la franja**, con grupos y cantidades (por ejemplo, 1 plato fuerte, 1 acompañante, 1 bebida y 1 postre del día). Cada grupo dice qué artículos admite y en qué cantidad. Lo que entra en la composición queda cubierto al 100 %; lo que pasa de ella (un segundo jugo) **no entra en B** y sigue el orden de la sección 2.4. *Alternativas descartadas:* «cualquier artículo de la categoría Almuerzo», sin cantidades, porque abre la puerta a llevarse tres platos; y el combo completo con un menú del día por fecha ([CE] CE-02), que es mejor pero más caro y queda para la fase 2 | **Composición por grupos en la fase 1; el menú del día por fecha, en la fase 2** |
| B-3 | **B va aparte de la bolsa (A):** no la consume. Lo paga la empresa como beneficio propio | Firmar |
| B-4 | **Lo que no se usa se pierde.** Un almuerzo que no se tomó no se acumula, no se pasa a otro día y **no se convierte en saldo de la bolsa** | Firmar |
| B-5 | **Categorías:** qué franjas cubiertas al 100 % tiene cada categoría (el turno nocturno tiene la cena; el administrativo, solo el almuerzo) | Firmar |
| B-6 | **Fuera de la franja**, B no aplica: el artículo se paga con la bolsa o con dinero propio | Firmar |

### 2.2 (C) Artículos con un porcentaje subsidiado (50 %)

| # | Regla | Recomendación |
|---|---|---|
| C-1 | Por artículo (o por categoría de artículos), un **porcentaje que paga la empresa**: 50 % según el propietario, configurable de 0 a 100 %. El redondeo es al centavo y la diferencia queda del lado del empleado | Firmar |
| C-2 | **La parte de la empresa (50 %) es un beneficio aparte:** no consume la bolsa (A). Tiene un **tope técnico de seguridad** por comensal y por día (por ejemplo, 3 unidades o RD$ 300) para frenar un error o un abuso | Firmar |
| C-3 | **La parte del empleado (el otro 50 %)** se paga, según un parámetro de la empresa, con **dinero propio** (lectura literal de «el empleado aporta la proporción restante») o primero con la **bolsa** y después con dinero propio | **Dinero propio por omisión.** Pregunta **PQ-3** |
| C-4 | **Si la bolsa no alcanza** (cuando C-3 dice «bolsa»): la bolsa paga hasta su saldo y el resto se cobra con dinero propio. **Nunca se rechaza el artículo** por falta de saldo | Firmar |
| C-5 | Un artículo puede estar en la composición de B y tener también C. **Si el artículo entra en B, B gana** (100 %). Si queda fuera de la composición o de la franja, aplica C | Firmar |

### 2.3 (A) Bolsa mensual de subsidio por empleado

| # | Regla | Recomendación |
|---|---|---|
| A-B1 | **Monto mensual** por categoría, con excepción por comensal y con vigencia (la bolsa de un mes usa el monto vigente el día 1) | Firmar |
| A-B2 | **Se reinicia el día 1 de cada mes** (mes calendario, hora del servidor) | Firmar |
| A-B3 | **El sobrante se pierde.** No se acumula al mes siguiente, **nunca se paga en dinero** y no se transfiere a otro comensal. Acumularlo genera picos de consumo, saldos que RR. HH. tendría que explicar y una posible lectura como salario en especie (CF-3) | **Se pierde** |
| A-B4 | **Al agotarse, el empleado paga con su propio dinero** lo que desee (literal del propietario). No hay rechazo ni autorización: el ticket se completa con la forma de pago del empleado (sección 2.5) | Firmar |
| A-B5 | **Para qué sirve la bolsa:** cualquier artículo **disponible** que no cubran B ni C (meriendas, bebidas, extras y lo que pase de la composición), y la parte del empleado de C si así lo dice C-3 | Firmar |
| A-B6 | **Alta a mitad de mes:** la bolsa es **proporcional** a los días que quedan (por ejemplo, alta el día 16 de un mes de 30 días = 50 %). *Alternativa:* la bolsa completa | Proporcional. Pregunta **PQ-4** |
| A-B7 | **Baja a mitad de mes:** desde la fecha de baja la bolsa deja de estar disponible. Lo consumido no se reclama | Firmar |
| A-B8 | **El servidor controla el saldo** con un `UPDATE` condicional en el nivel «saldos» del orden de bloqueos (ADR-45; [CE] CE-04.3). Con dos cajas a la vez no se puede gastar dos veces el mismo saldo | Firmar |
| A-B9 | El comensal puede pedir «**No usar mi bolsa**» en un ticket (para guardar saldo) y pagar con su dinero. Es una tecla, sin autorización | Firmar |

### 2.4 Orden de aplicación en un mismo ticket

El servidor reparte cada línea con este orden fijo y determinista. **El cajero no lo edita.**

1. **B:** las líneas que caben en la composición de la franja vigente, si no se usó todavía hoy. Se cubren al 100 %.
2. **C:** la parte de la empresa en los artículos con porcentaje que no entraron en B.
3. **A (bolsa):** lo que queda de los artículos sin regla y, si C-3 lo dice, la parte del empleado de C. Las líneas se toman **de mayor a menor importe**.
4. **Dinero propio:** lo que queda, con la forma de pago del empleado (sección 2.5).

**Datos de los ejemplos** (ilustrativos): bolsa mensual de RD$ 3.000. Composición del almuerzo: 1 plato fuerte, 1 acompañante y 1 bebida. Precios: plato RD$ 250, arroz RD$ 60, jugo RD$ 60, postre con C al 50 % RD$ 80, galletas sin regla RD$ 120. Con C-3 en «Dinero propio».

| # | Situación | Líneas | B (100 %) | C (empresa) | A (bolsa) | Dinero propio | Bolsa después |
|---|---|---|---|---|---|---|---|
| E-1 | Almuerzo normal, bolsa de 1.000 | Plato 250, arroz 60, jugo 60 | 370 | — | — | **0** | 1.000 |
| E-2 | Almuerzo con postre y galletas, bolsa de 1.000 | Plato, arroz y jugo (370), postre 80, galletas 120 | 370 | 40 | 120 (galletas) | **40** (la mitad del postre) | 880 |
| E-3 | Lo mismo con C-3 en «Bolsa primero» | Igual | 370 | 40 | 160 (galletas 120 y mitad del postre 40) | **0** | 840 |
| E-4 | Bolsa casi agotada (50) | Galletas 120 a media tarde | — | — | 50 | **70** | 0 |
| E-5 | Segundo almuerzo el mismo día | Plato 250 | — (B ya usado, B-1) | — | 250 | 0 | Saldo − 250 |
| E-6 | Bolsa en 0 y dos jugos en el almuerzo | Plato, arroz y 2 jugos | 370 (un jugo entra en la composición) | — | 0 | **60** (el segundo jugo) | 0 |
| E-7 | Plato fuerte fuera de la franja (a las 16:00) | Plato 250, bolsa de 500 | — (B-6) | — | 250 | 0 | 250 |

El ticket muestra el reparto por línea y los totales «Empresa (almuerzo y cena)», «Empresa (50 %)», «Bolsa» y «A pagar», más el **saldo de la bolsa que queda**.

### 2.5 Cobro de la parte del empleado

| Forma | ¿Dinero en la caja? | Fase |
|---|---|---|
| Efectivo | Sí | 1 |
| Tarjeta (pinpad de la Estándar) | Sí | 1 |
| Transferencia o pago con QR bancario | Sí, conciliable | 2 |
| **Descuento por nómina** | No. Va al corte RC-03, con un **cupo por período de nómina** controlado en el servidor como la bolsa | **Pregunta PQ-2.** Si se usa, va en la fase 1, porque el propietario pidió el corte por nómina |

**Pregunta al propietario (PQ-2):** ¿el empleado paga su parte en efectivo, con tarjeta, por descuento de nómina o con varias formas? Mi recomendación es efectivo y tarjeta, más el descuento por nómina con cupo si la empresa ya descuenta otros conceptos.

---

## 3. Flujos operativos de punta a punta

Precondición común: caja en modo **Corporativa** (ADR-112, nivel 3), con el módulo activo en la empresa (lo activa solo el SUPER) y la jornada abierta por el supervisor del tercero. La caja abre la ventana propia **«Facturación Corporativa»** [VENT].

### F-01 · Consumo del empleado con carné (camino feliz)

| # | Actor | Paso | Resultado |
|---|---|---|---|
| 1 | Comensal | Presenta el carné en el lector | El lector entrega el **número de carné**, un identificador opaco (H-1) |
| 2 | Servidor | Resuelve el carné → comensal. Comprueba los estados, la **franja vigente** según la hora del servidor, la categoría, si **B** está disponible hoy en la franja, el saldo de la **bolsa** y el cupo de nómina | Devuelve la tarjeta: **foto**, nombre, código, categoría, centro de costo, «Almuerzo disponible / ya tomado a las 12:14», saldo de la bolsa y avisos |
| 3 | Cajero | **Compara la foto con la persona** y pulsa «Confirmar identidad» (Enter), o pulsa «No es la persona» | **Sin confirmar no se agregan artículos** (regla del propietario). «No es la persona» bloquea el carné de forma preventiva (F-07) y deja una línea en la bitácora |
| 4 | Cajero | Agrega los artículos: botonera de la franja (con la composición resaltada) o lector de código | Cada línea muestra en vivo B, C, bolsa y la parte a pagar |
| 5 | Servidor | Aplica el orden de la sección 2.4 | Totales por beneficio y «A pagar» |
| 6 | Cajero | Si «A pagar» es 0: «Despachar» (Ctrl+Enter). Si no, cobra con el `PanelCobro` compartido | — |
| 7 | Servidor | Emite el **ticket de consumo interno** en una sola transacción (AT-1) | Ticket con numeración propia, **sin NCF** |
| 8 | Agente de impresión | Imprime el ticket o lo muestra en pantalla, según la caja | El comensal recoge en la línea de servicio |

**Errores:**
- Carné desconocido → «Carné no registrado». Se ofrece la identificación sin carné (F-08).
- Carné bloqueado o perdido → alerta roja «Carné bloqueado: retenga el carné». Queda en la bitácora.
- Comensal inactivo → F-09.
- Almuerzo ya tomado → B no aplica y la pantalla dice cuándo y en qué caja. Se sigue con la bolsa o con dinero propio (B-1).
- La tarjeta se rechaza → el ticket no se emite. **No queda saldo descontado sin ticket** (AT-1).
- Fallo técnico → reintento con la **misma llave de idempotencia**, sin duplicar.

### F-02 · Visitante con factura con NCF

1. «**Visitante**» (F4), sin carné.
2. Se usa la **lista de precios de visitante**. Las franjas de disponibilidad aplican; ningún beneficio aplica.
3. Comprobante: consumidor final (B02/E32) o crédito fiscal (B01/E31) con RNC y razón social.
4. Se cobra con el `PanelCobro`.
5. Emisión por la **ruta única** (ADR-112.5): número, NCF o e-NCF, guarda de emisión, idempotencia y descarga del inventario, **como en la Estándar**.

Un visitante **siempre** genera comprobante. «No generar comprobante» sigue la regla vigente [NOGEN]. Su devolución es una **nota de crédito**; con e-NCF no se anula, se reversa (E34). Sin conexión, la misma regla de la Estándar [ADR53].

**Un empleado que pide factura con NCF** (por ejemplo, para un reembolso de viáticos) se atiende como visitante por esa compra, sin beneficios. Si la costura de la sección 8 está activa, se usa esa costura.

### F-03 · Ejecutivo y personal de servicio

Las diferencias se configuran como **categorías de comensal**, sin código propio:

| Categoría | B (almuerzo y cena) | C | Bolsa (A) | Particularidades |
|---|---|---|---|---|
| Empleado | Las franjas de su turno | Sí | Monto de la categoría | — |
| **Ejecutivo** | Almuerzo y cena, con horario extendido y una composición más amplia si la empresa lo decide | Sí | Mayor | Artículos restringidos a su categoría (R-L3). **Invitados: fase 2** |
| **Personal de servicio** (seguridad, limpieza, contratistas) | Las franjas de su turno, a menudo nocturno | Según el contrato | Sin bolsa o con una bolsa menor | Pertenece a una **organización externa**, que funciona como centro de costo. **Carné con vencimiento.** Sin descuento por nómina, porque no está en la nómina de la empresa |

### F-04 · Reverso de un consumo (documento interno)

El reverso del ticket es un **documento interno** («Reverso de consumo»): tiene su propia numeración, se enlaza con el ticket, guarda el motivo y la autorización y queda en la bitácora. **No es una nota de crédito fiscal**, porque el ticket no tiene NCF. La nota de crédito queda solo para la factura de un visitante.

| Momento | Quién lo hace | Qué devuelve |
|---|---|---|
| Misma jornada, antes del Z | Cajero, con motivo y **autorización de otra persona** (ADR-68: el supervisor del tercero; el servidor rechaza que autorice el mismo cajero) | **B:** la franja vuelve a estar disponible. **C:** se anula la parte de la empresa. **Bolsa:** se devuelve el saldo. **Dinero propio:** se devuelve por la forma original o en efectivo, según la política de la Estándar. **Nómina:** se resta del corte |
| Después del Z, dentro del mismo mes y antes del corte de nómina | El supervisor del tercero desde la ventana de documentos, con un privilegio | Igual. El dinero sale de la caja abierta del día como egreso con referencia |
| **Después del cierre del mes** | El mismo | **La bolsa de un mes cerrado no se reabre** (el sobrante se pierde igual, A-B3). Se devuelve solo el dinero propio. La parte de nómina va como **ajuste** del período siguiente |
| Después del corte de nómina exportado | El administrador del beneficio de la empresa dueña | **No se toca el ticket.** Se hace un ajuste de consumo en el período siguiente |

**Inventario:** al reversar se pregunta «¿Se sirvió?».
- **Sí:** borrador de merma o consumo interno, con el motivo [MOT], que confirma el encargado.
- **No:** el artículo vuelve a la existencia.

**Reverso parcial:** es por líneas. El reparto se recalcula sobre lo que queda con el mismo orden de la sección 2.4. Se devuelve primero el dinero propio, después la bolsa y por último C y B. Así el empleado recupera primero su dinero.

### F-05 · Apertura, cierre y arqueo con consumos sin cobro

**Apertura** (supervisor del tercero): igual que la Estándar (fondo y cajero). Además, la caja muestra la **franja vigente** y la frescura del padrón (fecha de la última actualización y fotos en caché).

**Durante la jornada:** el cambio de franja es automático por la hora del servidor. No hace falta cerrar la caja entre franjas.

**Cierre (Z) de la caja Corporativa:**

| Bloque | Contenido | ¿Entra en el arqueo? |
|---|---|---|
| Ventas a visitantes (con NCF) | Las de la Estándar: por tipo de comprobante y forma de pago | **Sí** |
| Dinero propio de los empleados (tickets internos) | Por forma de pago | **Sí** |
| **Almuerzos y cenas (B)** | Comidas por franja e importe, por centro de costo | **No** (informativo) |
| **Parte de la empresa en los artículos al 50 % (C)** | Cantidad e importe | **No** |
| **Consumo de bolsas (A)** | Importe | **No** |
| Descuentos por nómina | Importe | **No** |
| Reversos | Cantidad, importe y autorizante | Solo la parte devuelta en dinero |
| **Excepciones** | Sin carné, carnés bloqueados, «No es la persona», segundos almuerzos, contingencia | No |

- **Arqueo:** solo cuenta el dinero (fondo, dinero propio y visitantes). **Los consumos subsidiados nunca cuadran contra el efectivo**, para que un faltante no se tape con un consumo subsidiado.
- **El Z no se cierra con un ticket en curso** en esa caja (con líneas sin emitir).
- **¿De quién es el dinero cobrado?** Depende del contrato con el administrador tercero (PQ-6). El Z lo deja medido en los dos casos.

### F-06 · Papel del administrador tercero

| Función | La hace | Cómo |
|---|---|---|
| Cobrar y despachar | **Cajeros del tercero** | Usuarios **propios y nominativos** en la empresa dueña, con el perfil «Cajero de cafetería»: solo la ventana Corporativa, sin padrón, planes, costos ni reportes de la empresa |
| Abrir, cerrar, arquear y autorizar los reversos | **Supervisor del tercero** | Perfil «Supervisor de cafetería»: Z, arqueo y autorizaciones de la sede. **No cambia beneficios, bolsas ni precios** |
| Padrón, categorías, B, C, A, franjas y carnés | **Empresa dueña** (RR. HH. o servicios generales) | Perfil «Administrador del beneficio». **El tercero nunca modifica los beneficios:** es quien los cobra, y sería juez y parte |
| Precios y artículos de la cafetería | Según el contrato (PQ-5) | Recomendación: el tercero propone y la empresa dueña aprueba. Cada cambio queda en la bitácora |
| Inventario y compras | Según quién compra la materia prima (PQ-5) | Si compra el tercero, en la fase 1 los artículos pueden ser **no inventariables** y GPOS NG controla solo el consumo. Si compra la empresa, el inventario completo funciona como en la Estándar |
| Reportes | Empresa dueña: todos. Tercero: los de su operación | Ver sección 7, que agrega la **liquidación al administrador** |

**Control cruzado:** la persona que cobra (el tercero) y la que define cuánto se subsidia (la empresa) son distintas. La **liquidación al administrador** (RC-06) es la base para validar la factura que el tercero le presenta a la empresa.

### F-07 · Carné perdido, bloqueado o reemplazado

1. El comensal reporta la pérdida a la empresa dueña.
2. El administrador del beneficio marca el carné como **Perdido** o **Bloqueado**, con motivo y en la bitácora. El efecto es inmediato en línea y en los nodos en la siguiente sincronización (R-O4).
3. Se emite un carné nuevo con **otro número**. El anterior queda **Reemplazado** y nunca se reactiva.
4. Mientras recibe el carné nuevo: F-08.

### F-08 · Identificación sin carné (contingencia)

Búsqueda por código o por nombre, con la **misma foto**, que el cajero tiene que confirmar. Requiere el privilegio «Identificar comensal sin carné» o la autorización del supervisor. Queda marcada en el ticket y en el reporte de excepciones.
- **Límite:** 3 identificaciones sin carné por comensal y por mes (por omisión). Al pasarlo, hace falta autorización.
- **Sin foto registrada:** solo con autorización y con marca.

### F-09 · Comensal inactivo

Ver R-E1 a R-E3.

---

## 4. Reglas de transacción, atomicidad y negocio

### 4.1 Atomicidad

| # | Regla |
|---|---|
| **AT-1** | **El ticket de consumo interno es atómico.** En una sola transacción ocurren: su **numeración propia** (serie interna, sin NCF); las líneas con precio, **reparto por beneficio** y **costo congelado** (`VenConfiguracion.cs:116`); la **descarga del inventario** si el artículo es inventariable (semántica de la Estándar, ADR-112.9); la **marca de B** por comensal, fecha y franja; el **saldo de la bolsa** y del cupo de nómina con un `UPDATE` condicional (ADR-45); los pagos con dinero propio; y la **bitácora** de las excepciones. **O se hace todo o no se hace nada** |
| AT-2 | **Idempotencia:** cada ticket lleva una llave generada en la caja antes del primer envío. El reintento con la misma llave devuelve el ticket ya emitido |
| AT-3 | **La impresión no forma parte de la transacción.** Si falla, el ticket existe y se reimprime con la marca «REIMPRESIÓN» |
| AT-4 | **Tarjeta en un ticket con dinero propio:** se autoriza **antes** de emitir. Si se aprueba y la emisión falla, se aplica el procedimiento de la Estándar (reverso o reintento idempotente con la misma referencia) |
| AT-5 | **El reverso es atómico:** devuelve B, C, la bolsa y el cupo, registra el egreso y crea el borrador de merma o el retorno a la existencia, todo junto |
| AT-6 | **La factura del visitante** sigue la atomicidad de la ruta única, sin cambios |
| AT-7 | **El cierre del corte de nómina:** la exportación y el **bloqueo** del período son una sola operación. Exportar dos veces el mismo período devuelve el mismo archivo con su huella |
| AT-8 | **El cierre del mes de las bolsas** lo hace el sistema el día 1, a la hora 00:00 del servidor: el saldo restante queda en «Perdido» (para el reporte) y la bolsa nueva se crea. Es una operación idempotente; si el nodo estaba apagado, se ejecuta al arrancar |
| AT-9 | **No se reintenta en automático** un ticket rechazado por una regla de negocio. Solo se reintentan los fallos técnicos con la misma llave |

### 4.2 Horarios (franjas)

| # | Regla |
|---|---|
| R-H1 | Las franjas se definen **por sede**: inicio, fin y días de la semana. Una franja que cruza la medianoche (la cena del turno nocturno) se asigna a la **fecha de inicio** |
| R-H2 | **Por artículo**, dos conceptos separados: **disponibilidad** (en qué franjas se vende) y **pertenencia a la composición** de B (de qué franja y de qué grupo) |
| R-H3 | **Por categoría:** qué franjas de B tiene (B-5) |
| R-H4 | **Fuera de franja:** lo no disponible no se vende. Lo disponible se paga con C, con la bolsa o con dinero propio |
| R-H5 | **La hora es la del servidor**, nunca la del equipo. La franja se fija **al leer el carné**, con una tolerancia de 5 minutos por omisión (de 0 a 15) |
| R-H6 | Calendario de excepciones por sede (feriados o días sin cena) |

### 4.3 Límites por comensal

| # | Regla |
|---|---|
| R-L1 | B: un almuerzo y una cena por día (B-1) |
| R-L2 | Cupo de descuento por nómina por período, si se usa (PQ-2). Lo controla el servidor. **El límite legal de los descuentos es una pregunta para el contador** (CF-5) |
| R-L3 | Artículos restringidos por categoría (por ejemplo, el menú ejecutivo) |
| R-L4 | Topes técnicos de C por día (C-2) |
| R-L5 | Bolsa mensual (A-B1), con el sobrante perdido (A-B3) |

### 4.4 Doble consumo en la misma franja

| # | Regla |
|---|---|
| R-D1 | **Un solo B por comensal, fecha y franja** (B-1) |
| R-D2 | **Segundo consumo en la franja:** la pantalla muestra «Ya almorzó a las 12:14 en la Caja 2». Se permite con la bolsa o con dinero propio (ejemplo E-5) |
| R-D3 | **El mismo carné en dos cajas a la vez:** la segunda recibe el rechazo de B y el caso queda en la bitácora como **posible carné clonado** (RC-05) |
| R-D4 | **El mismo carné en dos sedes** en menos de N minutos: alerta en RC-05, sin bloqueo en la fase 1 |

### 4.5 Comensal inactivo

| # | Regla |
|---|---|
| R-E1 | Estados: **Activo**, **Suspendido** (vacaciones, licencia o sanción, con fecha de fin), **De baja** (con fecha efectiva) e **Inhabilitado**. Un registro con transacciones nunca se elimina (precisión de ADR-08) |
| R-E2 | Si no está Activo: **ni B, ni C, ni bolsa, ni nómina**. La pantalla dice el motivo y el cajero puede atenderlo como **visitante** (F-02) |
| R-E3 | La baja es efectiva desde su fecha. Los consumos subsidiados posteriores a esa fecha salen en el reporte «Consumos posteriores a la baja», para que la empresa decida. No se reversan solos |

### 4.6 Precios

| # | Regla |
|---|---|
| R-P1 | Dos listas de precios por sede: **comensal** y **visitante** (`Cliente.ListaPrecioId` ya existe; [CE] CE-04.5) |
| R-P2 | El precio queda fijo al confirmar la línea. Los beneficios aplicados son los vigentes al leer el carné |
| R-P3 | **Los beneficios no son descuentos sobre el precio.** El ticket guarda el precio completo y B, C y A son **formas de liquidación**. Así el costo real por centro de costo y la liquidación al tercero son exactos |

---

## 5. Operación sin conexión y reconexión

**Restricción vigente:** en una **sucursal en línea sin internet no hay operación** [ADR53], y la contingencia con SQLite local llega **después de las olas**. Una cafetería que se detiene a la hora del almuerzo deja a cientos de personas sin comer: **el riesgo operativo es Alto**.

| # | Regla |
|---|---|
| R-O1 | **Recomendación: nodo local para toda sede con más de unas 150 comidas por franja** (inferido), con el mismo criterio de «advertir, no exigir» de Q-05 en Restaurante. Costo del equipo: de USD 500 a 1.000 por sede (cifra de la hoja de verticales, Q-05) |
| R-O2 | **En un nodo,** todo funciona sin la central: el padrón, los carnés, los beneficios, las franjas, las **fotos en caché**, las marcas de B y los **saldos de las bolsas** de los comensales de esa sede. Los tickets suben a la central al reconectar |
| R-O3 | **Saldos entre sedes:** cada comensal tiene una **sede de referencia**, que lleva su saldo. Si consume en otra sede **sin conexión entre nodos**, esa sede aplica una regla conservadora: B sí (con la marca local), **bolsa no** y el resto con dinero propio. La conciliación marca los B duplicados como excepciones, **sin reversar** lo servido |
| R-O4 | **Los bloqueos y las bajas** viajan de la central a los nodos con prioridad. **Riesgo aceptado:** entre el bloqueo y la sincronización, un carné perdido puede consumir en un nodo aislado. La foto lo mitiga |
| R-O5 | **Sede sin nodo y sin internet (contingencia en papel):** <br>1. Se entregan vales preimpresos y numerados con el código del comensal, su firma y solo el B de la franja. <br>2. El dinero propio se cobra con un recibo manual numerado. <br>3. Al volver la conexión, se digitan en un lote con privilegio, con la fecha real y la marca «Contingencia». <br>4. Si un vale pasa una regla, se marca como excepción y no se rechaza. <br>5. Los visitantes no se atienden sin emisión |
| R-O6 | La SQLite local de la sucursal en línea, cuando llegue, debe incluir el padrón, las fotos, las marcas de B y los saldos de la sede. Esto queda como requisito para ese diseño |

---

## 6. Hardware y comportamiento ante fallos

### H-1 · Lector de carné

**Principio:** el carné lleva **solo un identificador opaco**, nunca los datos del empleado.
- La foto y los datos que ve el cajero vienen **del servidor**.
- Un QR con el nombre y la cédula es un dato personal impreso y es fácil de falsificar.
- Interpreto «un carnet que trae los datos del empleado junto a su foto» como **el plástico impreso**, que lleva la foto y el nombre a la vista; la máquina lee solo el identificador.

| Tecnología | Costo del lector (inferido, USD) | Seguridad | Velocidad | Recomendación |
|---|---|---|---|---|
| Código de barras 1D | 40 a 100 | Muy baja: se fotocopia | Buena | Aceptable solo con la foto |
| **QR (2D)** | 60 a 150 | Baja: se copia con una foto | Buena; lee también un teléfono | **Fase 1 si la empresa no tiene un carné de proximidad** |
| Banda magnética | 30 a 80 | Muy baja: se clona y se desgasta | Media | **No** |
| **RFID 125 kHz** (EM4100, HID Prox) | 20 a 60 (USB, emula un teclado) | Baja: se clona | Muy buena | **Fase 1 si la empresa ya lo usa en su control de acceso:** un solo carné para todo |
| Mifare Classic (solo el UID) | 30 a 100 | Baja: el cifrado está roto | Muy buena | Aceptable si ya existe |
| Mifare DESFire EV2 o EV3 (lectura cifrada) | 80 a 200, más la integración de llaves | Alta | Muy buena | Fase 2, solo si el cliente lo exige |

- **Lector USB que emula un teclado** (sin controlador, igual en Web y en MAUI), con prefijo y sufijo para distinguir la lectura de lo que se teclea.
- **La seguridad real es la foto y la confirmación del cajero**, más RC-05.
- **Ante un fallo:** si el lector no responde, se usa F-08. Una lectura mal formada se descarta con el aviso «Lea de nuevo». **Nunca se busca por coincidencia parcial.**

### H-2 · Pantalla de foto

- **Fase 1:** un panel en la pantalla de la caja con una foto de **al menos 240 × 320 px**, el nombre, el código, la categoría, el estado de B en la franja, el saldo de la bolsa y los avisos. El panel se queda visible hasta terminar el ticket.
- La foto se sirve **reducida**: JPEG de 300 × 400 px, de 30 a 50 KB. Con 300 comensales son unos 15 MB, que caben en la caché de la caja.
- **Opcional:** un visor hacia el comensal (de USD 100 a 200) con su nombre y su saldo, **sin la foto**.
- **Ante un fallo:** si la foto no carga en 1,5 s, aparece «Foto no disponible» y se puede confirmar solo con el privilegio de F-08. La foto se pide por el identificador y la versión: nunca se muestra la de otra persona.

### H-3 · Impresora de tickets

- Térmica de 80 mm con ESC/POS, por el agente de impresión existente (de USD 150 a 300, inferido).
- **El ticket interno lleva:** la leyenda **«CONSUMO INTERNO – NO ES UN COMPROBANTE FISCAL»**, el número de la serie interna, la fecha y la hora, la sede y la caja, el código y el nombre corto del comensal (**sin cédula ni foto**), la franja, las líneas, el reparto (Almuerzo/Cena, Empresa 50 %, Bolsa y Pagado con su forma), el **saldo de la bolsa** y el cajero.
- **Modo sin papel por caja:** el ticket solo se muestra en pantalla. Por omisión se imprime.
- **Ante un fallo:** el ticket ya existe (AT-3). Aviso, reimpresión con marca y cola de reimpresión al recuperar el papel.
- **Factura del visitante:** el formato de la Estándar, sin cambios.

### H-4 · Tableta de autoservicio (opcional, fase 2)

El comensal acerca su carné y pide él mismo; solo admite tickets sin dinero (B, C y bolsa).
- **Riesgo:** desaparece la verificación de la foto, y un carné prestado basta para consumir.
- **Mitigación:** un PIN (credencial con custodia, ADR-122) o una cámara, que es un dato personal más y requiere revisión de privacidad.
- **Costo:** de USD 300 a 600 por tableta, más unas 1,5 a 2 sp de desarrollo (inferido).
- **No va en la fase 1.**

### H-5 · Pinpad y gaveta

Los de la Estándar. La gaveta **no se abre** en un ticket sin dinero.

---

## 7. Datos del comensal

| Tema | Regla operativa |
|---|---|
| **Origen (fase 1)** | Alta manual e **importación por plantilla** (CSV o Excel) con vista previa de altas, cambios y bajas antes de aplicar. La lleva **la empresa dueña**. La llave es el **código de empleado de la nómina**, que nunca se reutiliza |
| **Origen (fase 2)** | Integración con la nómina o RR. HH. como **conector complementario** que nunca toca el núcleo |
| **Campos mínimos** | Código, nombres, apellidos, categoría, centro de costo, departamento, sede de referencia, estado con fechas, carné, foto y, si es de servicio, la organización externa y la fecha de fin |
| **Cédula** | **No se guarda por omisión**, como en [CE] CE-04. Si la nómina solo identifica por cédula, se guarda **cifrada** y enmascarada, como el pasaporte de Duty Free |
| **Foto** | **Dato personal.** La empresa dueña es la responsable del tratamiento; GPOS NG procesa el dato y **el tercero solo lo ve durante la identificación**. Reglas: <br>1. Se guarda reducida y con **acceso restringido**, fuera de las vistas `rpt` generales y sin exportarse en los reportes. <br>2. No hay galería navegable para el cajero. <br>3. Se borra a los **90 días de la baja** (por omisión). <br>4. Su carga y su cambio quedan en la bitácora. <br>5. Se renueva cada 3 años (por omisión), con el aviso «Foto antigua» al cajero. <br>Base: **Ley 172-13 de protección de datos personales**, que cito de memoria sin releer. Queda como supuesto; tiene que verificarse si la foto es un dato sensible y si hace falta un consentimiento escrito. Revisión del auditor-seguridad |
| **Comensales frente a `rrhh.Empleado`** | Hoy `rrhh.Empleado` es el personal propio y los vendedores (MD-30) [EMP]. Los comensales son **cientos o miles** y no tienen usuario ni comisión. **La necesidad operativa** es un padrón de comensales que se pueda enlazar con `rrhh.Empleado` sin ensuciar los selectores de vendedor y que también sirva a `res.ClienteEmpleado` de [CE]. **La decisión de las tablas es del arquitecto-datos** |
| **Centro de costo y departamento** | No existen en el modelo [CC]. **Necesidad:** catálogo de centros de costo (con el código del ERP si lo hay) y la asignación del comensal **con vigencia**. **El ticket congela el centro de costo vigente al consumir** |
| **Carné** | Número, tecnología, estado (Activo, Bloqueado, Perdido, Reemplazado o Vencido), fecha de emisión y de vencimiento. Un comensal tiene un solo carné activo |
| **Usuarios del tercero** | Nominativos, uno por persona, con un perfil limitado (F-06). Nunca una cuenta compartida «cafetería». Al terminar el contrato con el tercero, sus usuarios se inhabilitan |

---

## 8. Documentos y comprobantes: ticket interno y costura fiscal

**Regla del propietario:** «todos estos consumos son internos y no generan un NCF».

| Operación | Documento | NCF | Reverso |
|---|---|---|---|
| Consumo de un empleado (B, C, bolsa y dinero propio) | **Ticket de consumo interno**, con numeración propia por sede o por caja (serie interna, **nunca del rango de NCF**), bitácora y conservación como documento de la empresa | **No** | **Reverso de consumo** (documento interno, F-04). **No es una nota de crédito** |
| Visitante | Factura por la ruta única de emisión | **Sí** (B02/E32 o B01/E31) | Nota de crédito. Con e-NCF se reversa (E34) |

**Costura fiscal (opcional, no es el camino principal):**
1. **Punto de extensión** en la emisión del ticket interno: «**Comprobante de la parte pagada con dinero propio**».
2. Valor por omisión: **Ninguno** (regla del propietario).
3. Si el contador lo exige, el SUPER lo cambia a **«Consumidor final (B02/E32)»**, con motivo y una línea en `_LOG` (el mismo patrón del interruptor de [CE] CE-03.5). Desde ese momento, el ticket interno que tenga dinero propio **emite además**, en la misma transacción y por la **ruta única de emisión**, un comprobante **solo por la porción pagada por el empleado**, enlazado con el ticket.
4. **La ventana no cambia:** la extensión vive en el servidor (`IExtensionVenta`, ADR-112.5). En la pantalla, el `PanelCobro` solo muestra el NCF emitido.
5. El reverso de un ticket con comprobante emitido agrega la **nota de crédito** de esa porción. Con e-NCF se reversa.
6. La costura se diseña y se prueba en la fase 1, porque reservarla es barato y retrofitearla es caro (unas 0,3 sp). **Encenderla no requiere desarrollo.**

---

## 9. Reportes operativos mínimos

En el catálogo de reportes (vistas `rpt` y API de reportes de solo lectura). Ninguno muestra la foto ni la cédula.

| Código | Reporte | Columnas clave | Para quién |
|---|---|---|---|
| **RC-01** | **Consumo por empleado** | Fecha y hora, franja, ticket, artículos, reparto (B, C, bolsa y dinero propio con su forma), marcas (sin carné, contingencia o reverso) | Empresa dueña (RR. HH.) |
| **RC-02** | **Subsidio usado frente al tope** | Por comensal y mes: bolsa asignada, usada, **perdida al cierre**, B tomados frente a los disponibles (almuerzos y cenas) y C usado | Empresa dueña (RR. HH. y Finanzas) |
| **RC-03** | **Corte para descuento por nómina** (si PQ-2 lo incluye) | Código, nombre, monto, tickets y ajustes. Exportación CSV o Excel con huella y **bloqueo del período** (AT-7) | Nómina |
| **RC-04** | **Consumo por centro de costo** | Comidas B, importe de B, de C y de la bolsa, dinero propio y costo de lo servido | Contabilidad (carga en el ERP) |
| RC-05 | **Excepciones** | Sin carné, carné bloqueado, «No es la persona», posible clonación, consumo posterior a la baja, contingencia, reversos y autorizaciones, **cambios de precios y beneficios** | Auditoría interna de la empresa dueña |
| **RC-06** | **Liquidación al administrador** (nuevo por el caso principal) | Por período: comidas B servidas por franja, importe de C de la empresa, importe de las bolsas consumidas, dinero propio cobrado (según PQ-6, a favor del tercero o de la empresa) y reversos. Es **la base para validar la factura del tercero** | Empresa dueña (Finanzas) y el tercero |

**Para el tercero:** el Z y el arqueo de sus cajas, RC-06 de su sede y las excepciones de su operación. **No ve** RC-01 a RC-04 por empleado, salvo que la empresa lo decida.

---

## 10. Señal para el especialista contable (no lo resuelvo)

El camino principal es **sin NCF** por decisión del propietario. Las preguntas siguientes no lo cambian: deciden si la costura de la sección 8 se enciende y cómo se contabiliza lo demás. Busqué la norma dominicana sobre la alimentación del personal y no encontré fuentes aplicables, solo normas de otros países, que descarté. Queda **abierto**.

| # | Pregunta fiscal | Dónde lo necesito | Severidad |
|---|---|---|---|
| **CF-1** | Cuando el empleado paga con **su dinero** en la cafetería de la empresa, ¿la empresa le está **vendiendo**, con ITBIS y comprobante de consumidor final? ¿O basta el ticket interno? ¿Cambia si el dinero lo cobra el tercero por su cuenta (PQ-6)? | Si se enciende la costura (sección 8) | **Crítica** |
| **CF-2** | La parte que paga la empresa (B, C y bolsa), ¿es un **autoconsumo** con ITBIS o un gasto de personal? ¿A qué valor (costo o precio)? | Salida del inventario (clase 5 con `EsConsumoInterno` o el ticket) | Alta |
| **CF-3** | ¿El subsidio de comida (y la bolsa mensual) es una **retribución complementaria** o un salario en especie para el IR o la TSS? ¿Importa que el sobrante se pierda? | Regla A-B3 y los reportes para RR. HH. | Alta |
| **CF-4** | **Factura del administrador tercero a la empresa** (fuera del sistema): ¿qué debe facturar (el servicio de administración, las comidas o ambos) y con qué soporte? | El formato de RC-06 | Alta |
| **CF-5** | **Descuento por nómina:** ¿qué límite legal tiene (Código de Trabajo)? ¿Hay que emitir algo al consumir o al descontar? | R-L2 y RC-03 | Media |
| **CF-6** | **Visitantes:** si la venta de comida no es el giro de la empresa dueña, ¿puede emitir B02 o B01, o necesita la actividad registrada en la DGII? ¿Serie E por la obligación de la facturación electrónica (Ley 32-23, con un calendario que **no verifiqué**)? ¿O debe facturar el tercero? | F-02 | Alta |
| **CF-7** | ¿Se aplica la propina legal del 10 % en una cafetería interna? | Configuración por tipo de servicio (ADR-113) | Baja |
| **CF-8** | Conservación de los tickets internos (¿10 años?) | Retención y archivado | Baja |

---

## 11. Qué se reutiliza de la Estándar y qué es propio

| Se reutiliza (sin tocar la Facturación Ágil) | Es propio de la ventana Corporativa |
|---|---|
| **Ruta única de emisión** (ADR-112.5) para el visitante y para la costura fiscal | Ventana **«Facturación Corporativa»** con su ruta, su opción de menú y su guarda de módulo (patrón de [DY-01]) |
| Caja, jornada, Z y arqueo del núcleo, a los que se suman bloques informativos | **Identificación por carné con foto** y «Confirmar identidad» obligatorio |
| `PanelCobro`, búsqueda de artículos, consulta del RNC y teclado de `GPOS.Componentes` | Componentes nuevos: `TarjetaComensal`, `RepartoBeneficios`, `BotoneraFranja` (con la composición resaltada) |
| Artículos, listas de precios, inventario al emitir y costo congelado | **Ticket de consumo interno** y su **reverso interno**, con una serie propia |
| Agente de impresión, reimpresión con marca | **Motor de beneficios** (B por franja con composición, C por porcentaje, A bolsa mensual) con el orden de la sección 2.4 |
| ADR-68, `_LOG`, privilegios y perfiles | Perfiles del tercero (cajero y supervisor) y del administrador del beneficio |
| Motivo `CONSUMO` [MOT] para los reversos de lo servido | Centros de costo con vigencia, carnés, cierre mensual de las bolsas, corte de nómina, RC-01 a RC-06 |
| **De [CE]:** padrón y topes con `UPDATE` condicional (CE-04), reportes CO-01 y CO-02 como base, patrón del interruptor fiscal (CE-03.5) y, en la fase 2, el menú del día como combo (CE-02) | Costura «Comprobante de la parte pagada con dinero propio» |

**Licencia (ADR-112):** un módulo de vertical nuevo, `CORPORATIVA`, con el modo de caja «Corporativa». **Conflicto de nombre:** [CE] CE-06 reservó `CORPORATIVO` como complemento de `RESTAURANTE`, sin registrarlo [CE-reg]. **Recomendación:** que el padrón, el carné, los topes y los beneficios sean **una sola capacidad** compartida (como las recetas son una capacidad de inventario). Pregunta **PQ-8**.

---

## 12. Riesgos operativos y mitigaciones

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| RO-1 | Cafetería detenida sin conexión en el almuerzo | Media en plantas | **Alto** | Nodo desde unas 150 comidas por franja (R-O1) y contingencia en papel (R-O5) |
| RO-2 | Carné prestado o clonado | Media | Medio | Foto y confirmación obligatoria, R-D1 a R-D3 y RC-05 |
| RO-3 | **El tercero registra B o bolsas de comensales ausentes** para inflar su liquidación | Media | **Alto** | Lectura de carné obligatoria, F-08 con límite y marca, el tercero no toca los beneficios (F-06), RC-05 y RC-06 auditables por la empresa, conciliación contra la asistencia (fase 2) |
| RO-4 | Fila en el pico por la latencia de la foto | Media | Medio | Foto reducida y en caché, 1 s en el p95, dos cajas por cada 300 comensales |
| RO-5 | Exposición de fotos o del padrón al personal del tercero | Media | Alto (Ley 172-13) | Perfil limitado, foto solo durante la identificación, sin reportes por empleado para el tercero |
| RO-6 | Corte de nómina o cierre de mes mal hechos | Media | Medio | AT-7 y AT-8. Las correcciones van como ajuste del período siguiente |
| RO-7 | La DGII considera una venta el dinero propio sin NCF | Media hasta que responda CF-1 | Alto | Decisión del propietario (sin NCF). **La costura de la sección 8 permite corregirlo sin rehacer la ventana.** Enviar CF-1 al contador antes del primer cliente |
| RO-8 | Padrón desactualizado (bajas tardías) | Alta | Bajo a medio | Importación con vista previa, R-E3 y aviso de padrón antiguo en la apertura |

---

## 13. Preguntas para el propietario (con recomendación)

| # | Pregunta | Recomendación |
|---|---|---|
| **PQ-1** | ¿El «almuerzo» y la «cena» se definen como una **composición** (1 plato fuerte, 1 acompañante, 1 bebida y 1 postre) o como «cualquier artículo de la categoría»? | **Composición por grupos con cantidades** (B-2). El menú del día por fecha, en la fase 2 |
| **PQ-2** | ¿Cómo paga el empleado su parte: efectivo, tarjeta, **descuento por nómina** o varias formas? | Efectivo y tarjeta, más el descuento por nómina con cupo si la empresa ya descuenta otros conceptos |
| **PQ-3** | La mitad que aporta el empleado en los artículos al 50 %, ¿sale de **su dinero** o primero de la **bolsa**? | **De su dinero** por omisión (lectura literal), configurable por empresa |
| **PQ-4** | La bolsa de un empleado que ingresa a mitad de mes, ¿es **proporcional** o completa? ¿El sobrante **se pierde** al cerrar el mes? | Proporcional, y el sobrante se pierde |
| **PQ-5** | Con el administrador tercero: ¿**quién compra la materia prima** (de quién es el inventario) y **quién fija los precios**? | Si compra el tercero, en la fase 1 los artículos son no inventariables y solo se controla el consumo. Los precios los propone el tercero y los aprueba la empresa |
| **PQ-6** | El **dinero** que pagan los empleados y los visitantes, ¿es de la empresa o del tercero? ¿Quién emite la factura del visitante, la empresa o el tercero? | Lo define el contrato. El Z y RC-06 lo miden en los dos casos. Si el tercero factura a los visitantes con su propio RNC, la factura del visitante sale de su sistema y no de GPOS NG (CF-6) |
| **PQ-7** | ¿Hay un cliente concreto con fecha? ¿Cuántos comensales tiene y con qué conectividad? | Sin cliente: **diseño ahora y construcción en la entrega 3**, sin tocar el corte de diciembre. Con más de 150 comidas por franja, se le recomienda un nodo |
| **PQ-8** | ¿Unificamos la capacidad «padrón, carné, topes y beneficios» con el complemento `CORPORATIVO` del Restaurante ([CE]), con el código de módulo `CORPORATIVA` para la vertical? | **Sí:** se construye una vez |

---

## 14. Alcance: fase 1 frente a lo que puede esperar

**Calendario:** **nada en la entrega 1** (el corte es a mediados de diciembre y la prioridad es el núcleo). La fase 1 se construye en la **entrega 3** como un tramo propio, después del mecanismo de verticales (que llega con el tramo 3c de Duty Free).

### Fase 1 (caso principal: cafetería de la empresa administrada por un tercero)

| Pieza | sp (inferido, ±40 %) |
|---|---|
| Ventana «Facturación Corporativa», modo de caja, guarda de módulo y visitante con NCF por la ruta única | 0,8 |
| Carné (QR, código o UID de proximidad por teclado) con foto y confirmación, identificación sin carné | 0,8 |
| Padrón de comensales: importación, categorías, centros de costo con vigencia, estados, carnés y foto restringida | 1,0 |
| Franjas por sede y **motor de beneficios** (B con composición y uno por franja, C por porcentaje, A bolsa mensual con cierre de mes), con el orden y los controles en el servidor | 1,8 |
| Ticket interno atómico con serie propia, dinero propio (efectivo y tarjeta) y la **costura fiscal apagada** | 1,0 |
| Reverso interno (antes y después del Z, y después del cierre del mes) y ajustes | 0,4 |
| Perfiles del tercero y del administrador del beneficio | 0,2 |
| Bloques del Z y arqueo solo con dinero | 0,3 |
| Reportes RC-01, RC-02, RC-04, RC-05 y **RC-06** | 0,9 |
| Descuento por nómina con cupo y RC-03 (solo si PQ-2 lo incluye) | 0,4 |
| **Total** | **Unas 7,2 sp sin nómina y 7,6 con nómina (de 4,5 a 10,6)**. A unas 1,2 sp por semana, son **unas 6 semanas-persona**. Con la capacidad de [CE] ya construida, unas 6 sp |

**Costo para el cliente (inferido):** lector de USD 20 a 150 por caja e impresora térmica de USD 150 a 300 si no la tiene. Nodo de USD 500 a 1.000 por sede grande. Licencias e infraestructura de GSF: 0 adicional.

### Puede esperar (fase 2 en adelante), en orden de valor

1. Integración con la nómina o RR. HH. por conector.
2. Menú del día por fecha para B (reutiliza [CE] CE-02).
3. Conciliación de las comidas B contra la asistencia o el control de acceso (contra RO-3).
4. Pantalla de despacho en la línea de servicio (reutiliza el KDS).
5. Invitados del ejecutivo con cargo al centro de costo (sujeto al contador).
6. Tableta de autoservicio con PIN (H-4).
7. Transferencia o pago con QR bancario.
8. Saldos consolidados entre sedes con nodos (R-O3 completo).
9. Lectura segura de DESFire y visor hacia el comensal.
10. Modelo M2 (concesionario) con la factura por período de [CE] CE-03.

---

## Resumen

**Caso principal:** la cafetería es de la empresa, la administra un tercero y GPOS NG está en la base de la empresa dueña. La Corporativa es la Estándar más:
- identificación por carné con foto y confirmación obligatoria;
- un **motor de tres beneficios** que se aplican siempre en el orden B, C, A y dinero propio:
  - **(B)** almuerzo y cena al 100 %, uno por franja, definidos por una composición y sin consumir la bolsa;
  - **(C)** artículos con el 50 % que paga la empresa como beneficio aparte, y la otra mitad con dinero propio por omisión;
  - **(A)** una bolsa mensual que se reinicia el día 1, cuyo sobrante se pierde y que, al agotarse, deja paso al dinero propio sin rechazar;
- un **ticket de consumo interno sin NCF**, con serie propia y reverso interno (no nota de crédito);
- una **costura fiscal apagada**, que emite un B02/E32 por la porción de dinero propio si el contador lo exige, sin tocar la ventana.

El visitante se factura con NCF por la ruta única. El tercero cobra, despacha y cierra la caja, pero **no toca los beneficios**. La empresa recibe los reportes RC-01 a RC-06, incluida la **liquidación al administrador**, que sirve para validar lo que el tercero le factura. Riesgos principales:
- quedarse sin conexión en el almuerzo (nodo desde unas 150 comidas por franja);
- que el tercero infle su liquidación;
- **CF-1:** si el dinero propio sin NCF es una venta para la DGII.

Fase 1: unas 7,2 a 7,6 sp en la entrega 3, sin tocar el corte de diciembre.

### Cierre
- Estado: Completado (blueprint, revisión 2; decisiones **Pendientes de firma**)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\pos-vertical-corporativa-2026-10-15.md`
- Supuestos:
  - volúmenes, tiempos por transacción, costos de hardware y sp inferidos;
  - el carné solo lleva un identificador opaco;
  - la composición por grupos para B;
  - la parte del empleado en C se paga con dinero propio por omisión;
  - la bolsa proporcional en un alta a mitad de mes;
  - la Ley 172-13 y la Ley 32-23 se citan de memoria, sin releer;
  - no revisé la rama local `GPOS-B-verticales` más allá de `origin/b/verticales-diseno`.
- Decisiones candidatas a ADR:
  - vertical Corporativa (módulo `CORPORATIVA`, ventana propia, ticket interno con serie propia y reverso interno). Alternativa descartada: un parámetro de la Facturación Ágil;
  - motor de beneficios B, C y A con el orden fijo. Alternativa descartada: los beneficios como descuentos de precio, que deforman el costo y la liquidación;
  - costura fiscal apagada para la porción de dinero propio;
  - capacidad común con el complemento `CORPORATIVO` de [CE];
  - registro pendiente en `master` de los ADR de [CE], cuyo número 126 se reutilizó.
- Entregas a otros agentes:
  - especialista-contable → CF-1 a CF-8 (CF-1 crítica; CF-4 y CF-6 por el tercero);
  - arquitecto-datos → padrón frente a `rrhh.Empleado` y `res.ClienteEmpleado`, centros de costo con vigencia, carnés, franjas, composición de B, porcentajes de C, bolsas con cierre de mes, serie interna del ticket y del reverso;
  - arquitecto-software → extensión de la ruta única para la costura, motor de reparto en el servidor, sincronización del padrón, las fotos y los saldos al nodo;
  - disenador-ux-ui → `TarjetaComensal`, `RepartoBeneficios` y `BotoneraFranja` con el objetivo de 10 a 12 s por transacción;
  - auditor-seguridad → fotos y Ley 172-13, perfiles del tercero, lectura del carné por teclado;
  - documentador-tecnico → registrar los ADR de [CE].
- Próximo paso recomendado: el propietario responde PQ-1 a PQ-8 y envía CF-1 al contador antes de comprometer un cliente.
