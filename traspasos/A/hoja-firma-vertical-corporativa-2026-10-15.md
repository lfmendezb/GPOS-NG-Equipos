# Hoja de firma: vertical Corporativa (cafetería o comedor interno)

[Decisión preparada por el Arquitecto Maestro (equipo A)] · 2026-10-15 · **Estado: Pendiente de firma** (salvo F-1 a F-4, que el propietario ya respondió y se registran como firmadas)

**Qué se decide:** cómo atiende GPOS NG a una empresa que tiene su propia cafetería o comedor para empleados, ejecutivos y personal de servicio, administrado por un tercero, con consumos internos sin NCF, subsidios y control por empleado. También se decide cómo encaja esto con la hoja de catering y ejecutivos firmada el 2026-10-09.

**Cómo firmar:** marque una casilla por punto en la sección 4 (H-01 a H-11). Si firma «todo según recomendación», queda abierta solo la opción de H-04 (porción pagada por el empleado), que es suya y no tiene casilla por omisión. H-01, H-02 y H-04 son las que cambian el diseño. Las demás se pueden corregir después sin rehacer nada.

**Convención:** *verificado* significa leído en esta sesión, con `ruta:línea` o con la rama; *inferido* es una estimación sin medir. No compilé, no ejecuté pruebas ni toqué código.

---

## 1. Contexto y fuentes

### 1.1 Lo que dijo el propietario (literal y en orden)

1. «Quiero agregar una nueva vertical que deriva de la vertical Standard, a esta vertical la llamaremos Corporativa. Esta vertical esta orientada a organizaciones que necesitan atender a clientes internos: Empleados, Ejecutivos y personal de servicio que realiza consumos en la cafetería o comedor a lo interno de la empresa. Por tanto, se generan tickets y consumos sin NCF, a modo de seguimiento de gasto por empleados. Con la posibilidad de generar facturas con NCF a visitantes que lo requieran. También debe controlar el horario de consumo de cada item por horarios y subsidios a empleados con un consumo tope y con la posibilidad de pagar directamente o endosarlo al monto de subsidio de la empresa. También debe llevar un control del consumo de cada empleado. Mediante la lectura de un carnet que trae los datos del empleado junto a su foto para que el cajero pueda identificarlo de modo inequívoco y solo después proceder con el despacho de productos.»
2. «La cafetería es propiedad de la empresa, pero la administra una empresa de terceros. El sistema controla los consumos y es parte de la empresa propietaria de la cafetería. A cada empleado se le asigna un subsidio y si consumen el total antes del mes, pueden pagar con su propio dinero para adquirir lo que deseen. Tambien la empresa les asigna un Almuerzo y una cena subsidiado 100%. y algunos artículos con solo la mitad subsidiado en donde el empleado aporta la proporción restante»
3. «todos estos consumos son internos y no generan un NCF.»

Las cuatro respuestas posteriores del propietario están en la sección 3.

### 1.2 Fuentes

| Ref. | Fuente | Qué aporta |
|---|---|---|
| [POS] | `Solucion GPOS NG/pos-vertical-corporativa-2026-10-15.md` (revisión 2) | Flujos F-01 a F-09, reglas AT, R-H, R-L, R-D, R-E, R-P y R-O, hardware, reportes RC-01 a RC-06, PQ-1 a PQ-8 y una estimación de 7,2 a 7,6 sp |
| [CONT] | `Solucion GPOS NG/contable-vertical-corporativa-2026-10-15.md` (versión 2) | Modelo A frente a modelo B, salidas S-1 a S-6, D-01 a D-11, CC-06, CC-07 y CC-10 a CC-13 |
| [CE] | `GPOS NG`, rama `origin/b/verticales-diseno`, `docs/decisiones/2026-10-09-hoja-firma-catering-y-ejecutivos.md` | Firmada el 2026-10-09 «todo según recomendación». CE-03 (Cargo a la empresa con E31 agrupada), CE-04 (padrón `res.ClienteEmpleado`, topes), CE-06 (a) (`CORPORATIVO` complemento de `RESTAURANTE`) y CE-06 (c) descartada «se hace con el primer cliente que lo pida» (líneas 42-45 y 194-200) |
| [ADR112] | `origin/master:docs/adr/ADR-112.md`, puntos 1, 5, 6, 9 y 10 | Verticales como módulos que activa solo el SUPER, ruta única de emisión con `IExtensionVenta`, el núcleo no referencia a las verticales, en Tienda la factura mueve el inventario, consumo de personal por la clase 5 con `EsConsumoInterno` |
| [IDX] | `origin/master:docs/adr/README.md:107` (commit `8508d003`) | Rango de A: 68 a 99. ADR-79 y 80 libres; después, ADR-85. En `origin/master` existen ADR-068 a 078 y ADR-081 a 084. Ninguna rama remota tiene ADR-79, 80 ni 85 a 99 (verificado con `git ls-tree` en todas las ramas) |
| [PAGOS] | `origin/master:src/GPOS.Contracts/Ventas/Pos.cs:145` | La venta POS ya admite una lista de pagos (`List<PagoPos> Pagos`): el pago combinado no es nuevo en el contrato (verificado). Que el `PanelCobro` lo muestre bien con nómina es inferido |

---

## 2. Requerimiento consolidado

### 2.1 Objetivo

Una vertical **Corporativa**, derivada de la Estándar, con su propia ventana («Facturación Corporativa»), para que la empresa dueña de una cafetería que administra un tercero:
- identifique a cada comensal con su carné y su foto antes de despachar;
- registre cada consumo de un empleado en un **ticket de consumo interno sin NCF**;
- aplique en el servidor los beneficios (almuerzo y cena al 100 %, bolsa mensual y artículos al 50 % con cargo a la bolsa);
- cobre la parte del empleado en efectivo, con tarjeta o por descuento de nómina, combinables;
- facture con NCF (e-CF) solo a los visitantes;
- entregue a la empresa el control del consumo por empleado y por centro de costo, y la base para validar la factura del tercero.

La Facturación Ágil (ventana de la Estándar) no se toca.

### 2.2 Actores

| Actor | De quién es | Qué hace |
|---|---|---|
| Cajero o despachador | Del tercero | Lee el carné, confirma la foto, despacha y cobra. Usuario nominativo con perfil «Cajero de cafetería» |
| Supervisor de la cafetería | Del tercero | Abre y cierra la caja, arquea y autoriza las excepciones (ADR-68). No toca beneficios ni precios |
| Comensal | Empleado, ejecutivo o personal de servicio | Presenta el carné, consume, paga su parte |
| Visitante | Externo | Compra con e-CF (E32, o E31 si da su RNC) |
| Administrador del beneficio | RR. HH. o servicios generales de la empresa | Padrón, categorías, carnés, fotos, franjas, bolsas y coberturas |
| Finanzas y contabilidad de la empresa | Empresa | Reportes, conciliación del efectivo, validación de la factura del tercero |
| Nómina | Empresa | Recibe el corte de descuentos |

### 2.3 Flujos (se toman de [POS] con los ajustes de la sección 3)

| Flujo | Contenido | Origen |
|---|---|---|
| F-01 | Consumo con carné: lectura → foto → «Confirmar identidad» → artículos → reparto en el servidor → cobro de la parte del empleado → ticket interno atómico | [POS] F-01, con el orden de aplicación revisado (sección 3.5) |
| F-02 | Visitante: lista de precios de visitante, sin beneficios, e-CF por la ruta única | [POS] F-02 |
| F-03 | Ejecutivo y personal de servicio como **categorías** de comensal, sin código propio | [POS] F-03 |
| F-04 | Reverso del consumo: documento interno enlazado (no es nota de crédito), con autorización de otra persona | [POS] F-04, [CONT] 6.5 |
| F-05 | Apertura, cierre y arqueo: el arqueo cuenta solo el dinero; los consumos subsidiados son bloques informativos | [POS] F-05, [CONT] D-10 |
| F-06 | Papel del tercero: cobra y despacha; nunca configura beneficios | [POS] F-06 |
| F-07 a F-09 | Carné perdido, identificación sin carné, comensal inactivo | [POS] F-07 a F-09 |
| Cierre de mes | El día 1 la bolsa vuelve a su monto asignado; lo no usado se pierde | F-3 |
| Corte de nómina | Exportación con huella y bloqueo del período | [POS] AT-7, F-4 |

### 2.4 Alcance de la fase 1

1. Módulo de licencia, modo de caja «Corporativa», ventana «Facturación Corporativa» con su guarda de módulo y el visitante con e-CF por la ruta única.
2. Carné con identificador opaco (QR o el carné de proximidad que ya use la empresa), foto, confirmación obligatoria e identificación sin carné con autorización.
3. Padrón de comensales: importación por plantilla con vista previa, categorías, centros de costo con vigencia, estados, carnés y foto de acceso restringido.
4. Restricción de horario **opcional por artículo**, que bloquea la venta fuera de su franja (F-1).
5. Motor de beneficios en el servidor: almuerzo y cena al 100 % (uno por franja y por día), bolsa mensual con porcentaje de cobertura por artículo (100 % por omisión, 50 % en algunos) y renovación mensual sin acumulación (F-2 y F-3).
6. Ticket de consumo interno atómico, con serie propia, y su reverso interno.
7. Cobro de la parte del empleado con **efectivo, tarjeta y descuento por nómina, combinables**, según los medios que habilite cada empresa, con cupo de nómina por período (F-4).
8. La **costura fiscal** de la porción pagada (sección 5), construida y probada, con el valor que firme el propietario en H-04.
9. Perfiles del tercero y del administrador del beneficio.
10. Bloques del Z y arqueo solo con dinero.
11. Reportes RC-01 (consumo por empleado), RC-02 (bolsa usada frente a la asignada), RC-03 (corte de nómina), RC-04 (por centro de costo, con el costo), RC-05 (excepciones) y RC-06 (liquidación al administrador).

### 2.5 Lo que se aplaza (fase 2 en adelante, en orden de valor)

1. Integración con la nómina o RR. HH. como conector (nunca toca el núcleo).
2. Menú del día por fecha para el almuerzo y la cena (reutiliza el combo `K` de [CE] CE-02).
3. Conciliación de las comidas contra la asistencia o el control de acceso.
4. Pantalla de despacho en la línea de servicio (reutiliza el KDS).
5. Invitados del ejecutivo con cargo al centro de costo.
6. Tableta de autoservicio con PIN.
7. Transferencia o QR bancario.
8. Saldos consolidados entre sedes con nodos.
9. Lectura cifrada DESFire y visor hacia el comensal.
10. Concesionario (modelo B) sobre la Estándar.
11. Contingencia con SQLite local en la sucursal en línea (llega después de las olas, ADR-53).

### 2.6 Criterios de aceptación (verificables, para el QA de la fase 1)

| # | Criterio |
|---|---|
| CA-01 | Sin «Confirmar identidad» la API rechaza agregar líneas a un ticket con comensal |
| CA-02 | Un artículo con franja no se vende fuera de ella: la API lo rechaza con la hora del servidor, desde la Web y desde MAUI |
| CA-03 | Dos cajas que piden a la vez el almuerzo del mismo comensal en la misma franja: solo una lo obtiene al 100 % (prueba de concurrencia) |
| CA-04 | Dos cajas que consumen a la vez la bolsa del mismo comensal nunca la dejan en negativo |
| CA-05 | Los ejemplos E-1 a E-7 de la sección 3.6 dan exactamente los importes de la tabla |
| CA-06 | El ticket interno nunca toma un número del rango de NCF y su serie no tiene huecos a una fecha de corte |
| CA-07 | Un fallo en cualquier paso del ticket no deja saldo descontado, marca de almuerzo ni movimiento de inventario sin ticket |
| CA-08 | El arqueo del Z solo cuenta dinero; los bloques de beneficios y de nómina no entran en él |
| CA-09 | El perfil «Cajero de cafetería» recibe 403 en el padrón, las bolsas, las coberturas, las franjas y los precios |
| CA-10 | El día 1 la bolsa de cada comensal vale su monto asignado, haya sobrado o no; repetir el cierre no cambia nada |
| CA-11 | Un cobro combinado (efectivo + tarjeta + nómina) cuadra al centavo con el ticket y el cupo de nómina no se excede |
| CA-12 | Con la costura en el valor firmado en H-04, el resultado fiscal del ticket es el esperado (ningún e-CF, o un E32 enlazado solo por la porción pagada) |
| CA-13 | Ningún reporte ni exportación contiene la foto ni la cédula |

---

## 3. Respuestas del propietario ya firmadas (F-1 a F-4) y su efecto en el diseño

### 3.1 F-1 · Horario

> «Los consumos Almuerzos y Cenas deben consumirse en un rango de horario restringido, no se pueden consumir fuera del mismo, el sistema los bloquea. Esto aplica a cualquier artículo con restricción de horario. La mayoría de productos no tienen esta restricción.»

**Efecto:**
- La restricción de horario es un **atributo opcional del artículo** (una o varias franjas por sede). La mayoría de los artículos no la tienen y se venden a cualquier hora.
- Un artículo con franja **no se vende fuera de ella**: el servidor lo bloquea. Ya no rige [POS] B-6 («fuera de la franja se paga con la bolsa o con dinero propio») para esos artículos, y el ejemplo E-7 de [POS] cambia: el plato fuerte a las 16:00 se rechaza.
- Los artículos del almuerzo y de la cena son artículos con franja.

**PF-1, respondida por el propietario (2026-10-15):** «La franja de tiempo se fija por artículo, el carnet solo se utiliza para validar la identidad del empleado que consume.» Por eso la franja es un atributo del artículo y se comprueba con la hora del servidor al agregar cada artículo al consumo, para el empleado y para el visitante por igual. El carné no fija ni extiende la franja. Tolerancia: 0 minutos (no se pidió ninguna). [x] Respondida

### 3.2 F-2 · Artículos al 50 %

> «El 50% se descuenta de la bolsa.»

**Efecto (cambia [POS] 2.2):**
- La mitad subsidiada **consume la bolsa mensual**. Ya no es un beneficio aparte con su propio tope técnico ([POS] C-2 desaparece: el tope es la bolsa).
- La otra mitad la paga el empleado con su dinero (lectura literal de la precisión 2: «el empleado aporta la proporción restante»). Con esto, **[POS] PQ-3 queda respondida**.
- Si la bolsa no alcanza para la mitad subsidiada, **la diferencia también la paga el empleado**. Nunca se rechaza el artículo por falta de saldo.
- **Modelo resultante, más simple:** cada artículo tiene un **porcentaje de cobertura de la bolsa**: 100 % por omisión, 50 % en los artículos que la empresa decida y 0 % en los que nunca se subsidian. Ya no hay tres beneficios, sino dos: el almuerzo y la cena al 100 %, y la bolsa.

### 3.3 F-3 · Saldo de la bolsa

> «El saldo se renueva cada mes, si no se consume completo no pasa nada.»

**Efecto:** coincide con [POS] A-B3 y [CONT] D-06. El día 1 la bolsa **vuelve a su monto asignado** (no se le suma al sobrante); lo no usado se pierde, nunca se paga en dinero y no se traspasa.

**PF-3, confirmada por el propietario (2026-10-15):** «Correcto. Si la bolsa es de RD$300.00 y solo se consumió un total de RD$250.00, al llegar el nuevo corte mensual, la bolsa vuelve a su valor inicial de RD$300.00.» [x] Confirmo

### 3.4 F-4 · Cómo paga el empleado su parte

> «Puede ser una combinación de cada uno. Eso depende de cada empresa.»

**Efecto:**
- Efectivo, tarjeta y descuento por nómina, **combinables en un mismo cobro**. El contrato de la venta POS ya admite varios pagos ([PAGOS]).
- **Cada empresa configura** qué medios habilita.
- El descuento por nómina entra en la **fase 1**, con un **cupo por período de nómina** controlado en el servidor como la bolsa, y con el corte RC-03.
- El límite legal del descuento salarial (Código de Trabajo, art. 201, fuente secundaria de [CONT]) va al contador en CF-1.
- **No resuelve el punto fiscal:** cobrar por nómina sigue siendo una contraprestación del empleado ([CONT] S-4). Ver la sección 5.

**PF-4, pendiente:** el propietario pidió más contexto sobre «cupo de nómina» (2026-10-15). La explicación está en la sesión de A. Queda abierta hasta su respuesta. [ ] Confirmo · [ ] Otra: ____

### 3.5 Orden de aplicación revisado (sustituye [POS] 2.4)

El servidor reparte cada línea con este orden fijo. El cajero no lo edita.

1. **Almuerzo o cena al 100 %:** las líneas que caben en la composición de la franja vigente (H-05), si el comensal no la usó todavía ese día. No consumen la bolsa.
2. **Bolsa:** a cada línea restante le corresponde una porción de bolsa = precio × cobertura (100 % o 50 %). La bolsa paga esas porciones **de mayor a menor importe** hasta agotar su saldo.
3. **Dinero del empleado:** todo lo demás, que es la mitad no cubierta de los artículos al 50 % más lo que la bolsa no alcanzó. Se cobra con los medios habilitados, combinables.

El total del dinero del empleado no depende del orden de las líneas (= total − almuerzo/cena − mín(saldo, porciones de bolsa)). El orden solo fija qué línea queda pagada con qué, que importa para el reverso parcial y para la porción fiscal.

### 3.6 Ejemplos numéricos (sustituyen [POS] E-1 a E-7)

**Datos ilustrativos:** composición del almuerzo = 1 plato fuerte + 1 acompañante + 1 bebida. Plato RD$250 y arroz RD$60, los dos con franja de almuerzo (12:00 a 14:30). Jugo RD$60, sin franja. Postre RD$80, sin franja, cobertura de bolsa 50 %. Galletas RD$120, sin franja, cobertura 100 %.

| # | Hora y situación | Líneas | Almuerzo 100 % | Bolsa | Dinero del empleado | Bolsa después |
|---|---|---|---|---|---|---|
| E-1 | 12:10, almuerzo normal, bolsa 1.000 | Plato, arroz, jugo | 370 | 0 | **0** | 1.000 |
| E-2 | 12:10, almuerzo + postre + galletas, bolsa 1.000 | + postre 80, galletas 120 | 370 | 160 (galletas 120 + mitad del postre 40) | **40** (la otra mitad del postre) | 840 |
| E-3 | 15:30, postre + galletas, bolsa 100 | Postre 80, galletas 120 | — | 100 (todo a las galletas, la porción mayor) | **100** (galletas 20 + postre 80) | 0 |
| E-4 | 15:30, postre, bolsa 25 | Postre 80 | — | 25 | **55** (mitad del empleado 40 + 15 que la bolsa no alcanzó) | 0 |
| E-5 | 12:40, segundo plato el mismo día, bolsa 500 | Plato 250 | — (ya almorzó) | 250, si H-06 (a) | **0** | 250 |
| E-6 | 12:10, bolsa en 0, dos jugos | Plato, arroz, 2 jugos | 370 (un jugo entra en la composición) | 0 | **60** | 0 |
| E-7 | 16:00, plato fuerte | Plato 250 | — | — | — | **Rechazado:** «Artículo fuera de su horario (12:00 a 14:30)» (F-1) |

---

## 4. Hoja de firma (H-01 a H-11)

**Correspondencia con los insumos (sin duplicar):**

| Punto | Recoge |
|---|---|
| H-01 | [CONT] D-01; [POS] PQ-5 y PQ-6 |
| H-02 | [POS] PQ-8; candidatas a ADR (1) y (3) de [CONT]; conflicto con [CE] (sección 6) |
| H-03 | [CONT] D-02 y D-05; [POS] sección 8 (ticket y reverso), R-P3 |
| H-04 | [CONT] D-03 y D-04; [POS] sección 8 (costura) y CF-1 (detalle en la sección 5) |
| H-05 | [POS] PQ-1 y B-2 |
| H-06 | [CONT] D-07; [POS] B-1 y R-D2 |
| H-07 | [POS] PQ-4 (lo que F-3 no respondió: alta y baja a mitad de mes) |
| H-08 | [CONT] D-08 y D-09; [POS] H-1, H-2, F-08 y sección 7 |
| H-09 | [CONT] D-10 y D-11; [POS] F-06, RC-06 |
| H-10 | [POS] sección 5 (R-O1 a R-O5) |
| H-11 | [POS] PQ-7 y sección 14; [CE] CE-07 |
| Ya firmadas | [POS] PQ-2 (F-4), PQ-3 (F-2), la mitad de PQ-4 (F-3); [CONT] D-06 (F-3) |

---

### H-01 · ¿Quién es el dueño de la operación? (modelo de operación) — cambia el diseño

**Qué se decide:** si la cafetería funciona por cuenta de la empresa (el tercero solo administra) o si, en la sustancia, es una concesión. La DGII mira la sustancia: de quién son las compras, el inventario y el efectivo, y quién asume la pérdida ([CONT] sección 1, art. 337, lit. a).

| Opción | Consecuencia |
|---|---|
| **(a) Administración por cuenta de la empresa** | Las compras entran a nombre de la empresa (su RNC), el inventario es suyo, el efectivo se deposita en su cuenta y el tercero cobra un honorario con su propio E31. El emisor es la empresa. El subsidio es un retiro interno y se sostiene sin NCF. Todo el diseño de esta hoja aplica. Los artículos son inventariables, como en la Estándar |
| (b) Concesión | El tercero compra y vende por su cuenta: el emisor es el tercero y **nada puede ir sin comprobante** (E32 al empleado y E31 a la empresa por el subsidio). GPOS NG estaría en la base del tercero. Es el caso de [CE] CE-03, que hoy exige `RESTAURANTE`; en la Estándar es fase 2 |
| (c) Mixto: el tercero compra con su RNC y la empresa le reembolsa | La DGII puede leerlo como concesión: las salidas serían ventas del tercero sin comprobante. Riesgo **Alto**. No se soporta |

**Sub-decisión de (a): precios.** El tercero los propone y la empresa los aprueba; cada cambio queda en la bitácora.

**Recomendación: (a).** Es lo que describió el propietario («es parte de la empresa propietaria de la cafetería»). Control asociado: el contrato con el tercero debe decir que las compras van a nombre de la empresa y que el efectivo se deposita en su cuenta.

**Costo:** (a) está dentro de la estimación base. (b) en la Estándar necesita la factura de varios consumos en el núcleo, que [CE] CE-06 (c) señaló como obstáculo: unas 1,0 a 1,5 sp más (inferido), en la fase 2.

- [ ] (a) Administración por cuenta de la empresa · precios: el tercero propone y la empresa aprueba
- [ ] (b) Concesión
- [ ] Otra: ____

---

### H-02 · Encaje con la hoja de catering y código del módulo — cambia el diseño

**Qué se decide:** si la Corporativa y el consumo corporativo del Restaurante ([CE]) comparten una sola capacidad, y con qué código de módulo. Detalle del conflicto en la sección 6.

| Opción | Consecuencia |
|---|---|
| **(a) Una capacidad común de comensales** (padrón, carné, foto, topes y saldos en el servidor), fuera del esquema `res`. Dos usos: la **vertical `CORPORATIVA`** (modelo A, consumo interno) y el complemento del Restaurante (modelo B, CE-03 sin cambios), **que pasa a llamarse `CARGO_EMPRESA`** | Se construye una vez. Los nombres no se confunden en la pantalla de licencias del SUPER. Exige precisar dos cosas de [CE], sin cambiar su fondo: el nombre del complemento (CE-06) y la ubicación del padrón (CE-04). Ninguna de las dos está registrada ni construida: costo de la precisión, 0 |
| (b) Capacidad común; el complemento conserva `CORPORATIVO` y la vertical usa otro código (por ejemplo, `COMEDOR`), con el nombre visible «Corporativa» | No toca el nombre firmado. Queda un código interno que no coincide con el nombre que eligió el propietario, y la pantalla de licencias muestra «Corporativo» y «Corporativa» a la vez. Sigue exigiendo la precisión de CE-04 (ubicación del padrón) |
| (c) Dos implementaciones separadas | No toca nada de [CE]. Duplica el padrón, el carné y los topes: unas 1,2 sp más (inferido, [POS] sección 14) y dos lugares que mantener |
| (d) Un solo módulo `CORPORATIVO` con un parámetro «modelo de operación» A o B por empresa ([CONT] candidata 1) | Un solo código, pero una vertical con ventana propia quedaría como complemento de otra, y el parámetro es otro interruptor fiscal que alguien puede poner mal |

**Recomendación: (a).** El módulo mismo fija la ruta fiscal (Corporativa = interno; `CARGO_EMPRESA` = factura a la empresa), así que nadie elige el modelo en un parámetro y el cajero nunca lo elige.

**Costo:** (a) y (b) ahorran unas 1,2 sp entre las dos verticales (inferido). (c) cuesta unas 1,2 sp más.

- [ ] (a) Capacidad común; `CORPORATIVA` y `CARGO_EMPRESA`
- [ ] (b) Capacidad común; `CORPORATIVO` se mantiene y la vertical usa el código ____
- [ ] (c) Separadas
- [ ] (d) Un módulo con modelo de operación

---

### H-03 · Documento del consumo interno

**Qué se decide:** con qué documento queda el consumo subsidiado y cómo se corrige.

| Opción | Consecuencia |
|---|---|
| **(a) Ticket de consumo interno** con serie propia sin huecos (nunca del rango de NCF), la leyenda «CONSUMO INTERNO – NO ES UN COMPROBANTE FISCAL», el reparto por línea y el saldo de la bolsa. Guarda el precio de lista completo (los beneficios son formas de liquidación, no descuentos) y el **costo congelado**. Mueve el inventario una sola vez, por la clase 5 con `EsConsumoInterno` (ADR-112, punto 10). Se corrige con un **reverso de consumo** interno, enlazado, con autorización de otra persona; nunca con una nota de crédito | Sostiene la postura del propietario en la porción subsidiada ([CONT]: retiro gratuito, art. 336, num. 2; Consulta 23-2025). El costo por empleado y por centro de costo sale exacto |
| (b) Usar «No generar comprobante» de la Estándar (evento 4901) | Convierte una excepción con privilegio en la vía normal, mezcla los consumos con las ventas y llena la bitácora. Descartada por [CONT] 6.4 |
| (c) Una salida de inventario por consumo, sin ticket | No controla ni el pago del empleado ni la bolsa |

**Precisión sobre los reportes fiscales aplazados:** el contador declarará el retiro (IT-1) y evaluará la retribución complementaria (IR-17) con el **costo**, que ya traen RC-02 y RC-04. No se crea un reporte fiscal nuevo: los apoyos del IT-1 y del IR-17 siguen aplazados al ERP.

**Riesgo residual de la porción subsidiada:** Bajo si el contador declara el retiro sobre el costo; Medio si no ([CONT] sección 0).

**Recomendación: (a).**

**Costo:** 1,0 sp el ticket y 0,4 sp el reverso (inferido, [POS] sección 14).

- [ ] (a) Ticket interno con serie propia y reverso interno
- [ ] Otra: ____

---

### H-04 · La porción que paga el empleado con su dinero — punto fiscal crítico — cambia el diseño

**Qué se decide:** qué documento ampara el dinero que paga el empleado (la mitad de los artículos al 50 %, lo que la bolsa no alcanza y lo que compra con la bolsa agotada), por efectivo, tarjeta o nómina. **Se trata con detalle en la sección 5.** Esta casilla no tiene opción por omisión: la decide el propietario.

| Opción | Riesgo fiscal | Costo |
|---|---|---|
| P-0. Sin NCF (postura del propietario) | **Alto** ([CONT]) | 0 adicional |
| S-1. Un E32 automático solo por la porción pagada | Bajo | ≈ 0,3 sp más + el costo por documento del proveedor de e-CF |
| S-2. Un E32 global diario | Medio; requiere la autorización de la DGII | ≈ 0,4 sp más (inferido) y el trámite |
| S-6. Sin dinero del empleado | Bajo | Ahorra unas 0,5 sp, pero contradice la precisión 2 y F-2 |

**En todas las opciones** se construye en la fase 1 la **costura fiscal** de [POS] sección 8, de modo que se pueda pasar de P-0 a S-1 (o a S-2) sin rehacer la ventana.

**Recomendación del Maestro:** decidir la opción **antes de la puesta en marcha del primer cliente**, con la respuesta del contador a CF-1. Hasta entonces no hay exposición, porque todo es desarrollo. La recomendación técnica del contable es S-1.

- [ ] P-0 · Sin NCF, con el riesgo Alto aceptado por escrito como riesgo residual
- [ ] S-1 · E32 automático por la porción pagada
- [ ] S-2 · E32 global diario, sujeto a la autorización de la DGII (CC-12); S-1 mientras tanto
- [ ] S-6 · Sin dinero del empleado
- [ ] Decido después de CF-1, antes del primer cliente; mientras tanto se construye la costura

---

### H-05 · ¿Qué es un «almuerzo» y una «cena»?

**Qué se decide:** qué cubre exactamente el 100 %.

| Opción | Consecuencia |
|---|---|
| **(a) Composición por grupos con cantidades** (por ejemplo, 1 plato fuerte, 1 acompañante, 1 bebida y 1 postre del día), sobre artículos con franja | Lo que pasa de la composición (un segundo jugo) va a la bolsa o al dinero. El inventario es exacto por artículo |
| (b) Un artículo único «Almuerzo» a precio fijo | Simple en la caja, pero no se sabe qué salió del inventario ni se controla cuánto se lleva |
| (c) Cualquier artículo de la categoría «Almuerzo», sin cantidades | Permite llevarse tres platos al 100 % |
| (d) Menú del día por fecha, como el combo `K` de [CE] CE-02 | El mejor control, pero más caro; tiene sentido en la fase 2, reutilizando lo de [CE] |

**Recomendación: (a) en la fase 1 y (d) en la fase 2.**

**Costo:** (a) está dentro del motor (1,6 sp). (d) suma ≈ 1,0 sp en la fase 2 si [CE] CE-02 ya está construido (inferido).

- [ ] (a) Composición por grupos; (d) en la fase 2
- [ ] (b) · [ ] (c) · [ ] (d) ya en la fase 1

---

### H-06 · Segundo consumo en la misma franja

**Qué se decide:** qué pasa si el comensal vuelve a pedir un plato del almuerzo el mismo día. [POS] lo permite pagado; [CONT] D-07 pide autorización.

| Opción | Consecuencia |
|---|---|
| **(a) El 100 % se da una sola vez por franja y por día. El segundo plato se paga con la bolsa o con dinero, sin autorización, y sale en RC-05** (ejemplo E-5) | El subsidio no se duplica; la bolsa ya es un tope. La caja no se detiene en la hora pico |
| (b) Un segundo almuerzo al 100 % con autorización del supervisor (doble turno) | Abre una vía para que el tercero infle su liquidación con autorizaciones propias (el supervisor también es del tercero) |
| (c) Bloquear el segundo plato | El empleado no puede comprar algo que paga él |

El doble turno se resuelve por **categoría** (las franjas al 100 % de cada categoría), no por excepción.

**Recomendación: (a).** **Costo:** 0 en (a) y (c); ≈ 0,1 sp en (b).

- [ ] (a) · [ ] (b) · [ ] (c)

---

### H-07 · Alta y baja a mitad de mes

**Qué se decide:** el monto de la bolsa del mes de ingreso y de salida.

| Opción | Consecuencia |
|---|---|
| **(a) Proporcional** a los días que quedan al ingresar (alta el día 16 de un mes de 30 = 50 %). Desde la baja, la bolsa deja de estar disponible y lo consumido no se reclama | Más justo y defendible ante RR. HH. |
| (b) Bolsa completa en el mes de ingreso | Más simple, pero regala medio mes al que entra el día 28 |

**Recomendación: (a).** **Costo:** ≈ 0,05 sp.

- [ ] (a) · [ ] (b)

---

### H-08 · Identificación del comensal (carné, foto y contingencia)

**Qué se decide:** qué lleva el carné, cómo se guarda la foto y qué pasa sin carné.

| Opción | Consecuencia |
|---|---|
| **(a)** El carné lleva **solo un identificador opaco** (QR, o el carné de proximidad que la empresa ya use en su control de acceso). La foto y los datos vienen del servidor. La foto se guarda **una vez, cifrada en reposo** (ADR-44 y ADR-67), reducida a 300 × 400 px, sin galería ni exportación, y se borra a los 90 días de la baja. El ticket guarda quién confirmó y a qué hora. Sin carné: búsqueda por código o por nombre **con autorización de otra persona** (ADR-68), con un límite de 3 por comensal y por mes y marcada en RC-05. La cédula no se guarda | La seguridad real es la foto más la confirmación. La autorización de otra persona dificulta que un cajero del tercero registre comensales ausentes |
| (b) Un QR con el nombre y la cédula | Dato personal impreso y fácil de falsificar. Descartada |
| (c) Sin carné, por privilegio del propio cajero ([POS] F-08) | Más rápido, pero el cajero es del tercero: es juez y parte |

**Pendiente con cualquier opción:** el auditor-seguridad debe verificar si la foto es un dato sensible según la Ley 172-13 y si hace falta un consentimiento escrito (las dos fuentes la citan sin releerla).

**Recomendación: (a).** **Costo:** 0,8 sp (inferido). Para el cliente: un lector de USD 20 a 150 por caja (inferido).

- [ ] (a) · [ ] (c) · [ ] Otra: ____

---

### H-09 · Control del tercero y del efectivo

**Qué se decide:** la segregación entre quien cobra (el tercero) y quien define el subsidio (la empresa).

| Opción | Consecuencia |
|---|---|
| **(a)** Usuarios nominativos del tercero con dos perfiles («Cajero de cafetería» y «Supervisor de cafetería»); el tercero **nunca** toca beneficios, bolsas, coberturas, franjas ni precios. Z por jornada con conteo ciego; depósito en la cuenta de la empresa, conciliado **por la empresa**. RC-06 (liquidación al administrador) como base para validar la factura del tercero. La factura del honorario del tercero la registra el ERP, no GPOS NG | Control cruzado completo. El riesgo RO-3 de [POS] (el tercero infla su liquidación) queda mitigado |
| (b) El tercero administra también los beneficios o los precios | Juez y parte; riesgo Alto |

**Recomendación: (a).** **Costo:** 0,2 sp los perfiles, 0,3 sp los bloques del Z y RC-06 dentro de los 0,9 sp de reportes (inferido).

- [ ] (a) · [ ] (b)

---

### H-10 · Operación sin conexión

**Qué se decide:** qué pasa si la sede pierde internet a la hora del almuerzo. Hoy una sucursal en línea sin internet no vende (ADR-53); la base SQLite local llega después de las olas. Riesgo operativo **Alto** ([POS] RO-1).

| Opción | Consecuencia |
|---|---|
| **(a)** **Advertir, sin exigir,** un nodo local a toda sede con más de unas 150 comidas por franja (inferido). Contingencia en papel para las sedes sin nodo: vales preimpresos y numerados, solo para el almuerzo o la cena al 100 %, y recibos manuales para el dinero; después se digitan en un lote con privilegio y la marca «Contingencia». Los visitantes no se atienden sin emisión | La cafetería no se detiene. El riesgo queda acotado y medido |
| (b) Exigir un nodo en toda sede | Cierra el riesgo, pero le cuesta USD 500 a 1.000 a cada sede pequeña |
| (c) Solo en línea, sin contingencia | Cientos de personas sin comer en cada corte |

**Recomendación: (a).** **Costo:** ≈ 0,2 sp para la digitación por lote, que **no estaba** en la estimación de [POS] (inferido). Para el cliente: un nodo de USD 500 a 1.000 por sede grande.

- [ ] (a) · [ ] (b) · [ ] (c)

---

### H-11 · Etapa

**Qué se decide:** cuándo se diseña y cuándo se construye.

| Opción | Consecuencia |
|---|---|
| **(a)** **Nada en la entrega 1.** El diseño se hace tras esta firma sin restarle capacidad a la ruta crítica de diciembre; se construye en la **entrega 3**, en un tramo propio después del mecanismo de verticales (3a). Si aparece un cliente concreto con fecha, se adelanta dentro de la entrega 3 | Respeta el corte fijo y la prioridad (POS, verticales e inventario del núcleo primero) |
| (b) Construir en la entrega 1 | Rompe el corte: el mecanismo de verticales de ADR-112 aún no está implementado |
| (c) Entrega 2 | Posible solo si el mecanismo de verticales se adelanta, cosa que hoy no está firmada |

**Recomendación: (a).** **Costo:** sección 8.

- [ ] (a) · [ ] (c) · [ ] Otra: ____

---

### Firma

| Casilla | Contenido |
|---|---|
| [ ] **Todo según recomendación**, con la opción de H-04 marcada arriba | H-01 (a), H-02 (a), H-03 (a), H-05 (a), H-06 (a), H-07 (a), H-08 (a), H-09 (a), H-10 (a), H-11 (a); PF-1, PF-3 y PF-4 como se proponen |
| [ ] Firma punto por punto | Según las casillas marcadas |

Firma: ________________ (propietario) · Fecha: ________

---

## 5. El punto fiscal crítico: la porción que paga el empleado

**Lo digo con franqueza:** la postura «todo interno, sin NCF» se sostiene bien para lo que **paga la empresa** (almuerzo, cena, bolsa y la mitad subsidiada). **No** se sostiene con la misma solidez para el dinero que entrega el empleado. Lo que sigue presenta las opciones con su norma y su riesgo; la decisión es del propietario.

### 5.1 Por qué el especialista contable lo califica de riesgo Alto

Cuando el empleado paga, entrega dinero a cambio de bienes de la empresa: es una **transferencia onerosa**, no un retiro gratuito. Según [CONT] sección 3 (normas leídas por el especialista, salvo donde se indica):
- **Código Tributario, art. 50, lit. k** (citado en la NG 06-2018) y **Decreto 254-06, art. 2** (fuente secundaria): quien transfiere bienes debe emitir un comprobante.
- **Art. 338, num. 1:** el ITBIS nace al emitir el documento «o desde que se entregue o retire el bien, si dicho documento no existiese». **No emitir no evita el impuesto**; solo lo deja sin documento.
- **Arts. 335 y 336:** la comida preparada es un bien gravado; la Consulta 4-2025 confirma que la venta de almuerzos está gravada.
- **Art. 257** (NG 06-2018, art. 12): sanción por los deberes formales. Bajo la Ley 32-23, de 5 a 30 salarios mínimos (fuente secundaria).
- El efectivo que entra a la caja sin documento fiscal es un ingreso sin soporte en una fiscalización (inferido por el contable, sin artículo).

**Por qué la severidad es Alta y no Media:** cada monto es pequeño, pero la falta es **diaria, en cada caja**, y el propio Z la documenta.

**Orden de magnitud (inferido, ilustrativo):** con 300 empleados que pagan en promedio RD$40 al día durante 22 días, se cobran unos RD$264.000 al mes. Con el ITBIS incluido al 18 %, son unos **RD$40.300 de ITBIS al mes (unos RD$483.000 al año)** sin documento, más recargos y sanciones formales.

**El descuento por nómina no lo resuelve** ([CONT] S-4): sigue siendo una contraprestación del empleado. **Tampoco lo resuelve** que lo cobre el tercero con su RNC (S-5): mezcla los modelos y obliga a otra venta de la empresa al tercero.

**Si el contrato fuera una concesión** (H-01 (b)), la postura no se sostiene en **ninguna** porción.

### 5.2 Opciones

| # | Opción | Norma que la apoya o la contradice | Riesgo | Efecto en la operación | Costo |
|---|---|---|---|---|---|
| **P-0** | **Sin NCF** (postura del propietario): el ticket interno ampara también el dinero | Contradice el art. 50, lit. k, y el art. 338, num. 1 | **Alto** ([CONT]) | Ninguno | 0 |
| **S-1** | **Un E32 automático solo por la porción pagada**, emitido por la empresa por la ruta única, con el cliente genérico (por debajo de RD$250.000 no se identifica al comprador, ADR-108), enlazado al ticket y marcado «inventario ya descargado por el ticket». El cajero no elige nada. En un reverso, nota de crédito E34 enlazada (un e-NCF no se anula) | Cumple el art. 50, lit. k, y el art. 338 | **Bajo** | El ticket sigue igual; lleva además el e-NCF de la parte pagada. Unos 3.300 e-CF al mes en el caso de 300 empleados, si la mitad de los tickets llevan dinero (inferido) | ≈ 0,3 sp (inferido) + el precio por documento del proveedor de e-CF (**no verificado**; pedirlo a IQ) |
| S-2 | Un E32 **global diario** por caja | Decreto 254-06, art. 3, párrafo II, **solo con la autorización de la DGII** (fuente secundaria) | **Medio** hasta tener la autorización (CC-12) | Un e-CF por caja y día | ≈ 0,4 sp (inferido) y el trámite |
| S-6 | **Sin dinero del empleado:** todo es subsidio | Todo queda como retiro interno | **Bajo** | **Contradice la precisión 2 y F-2** («pueden pagar con su propio dinero», «el empleado aporta la proporción restante»). Cambia el negocio de la empresa cliente | Ahorra ≈ 0,5 sp |
| S-3, S-4, S-5 | E32 mensual; cobrar solo por nómina; que cobre el tercero | Sin apoyo normativo | Alto | — | No recomendadas |

**Desde noviembre de 2026** todo comprobante será un e-CF (los medianos y grandes desde el 1-nov y los pequeños desde el 15-nov; fuentes secundarias de [CONT]). Por eso S-1 habla de E32, no de B02.

### 5.3 La costura fiscal permite cambiar de opción después

El diseño de [POS] (sección 8) ya prevé un **punto de extensión** en la emisión del ticket interno, «Comprobante de la parte pagada con dinero propio»:
- vive en el servidor (`IExtensionVenta`, ADR-112, punto 5); **la ventana no cambia**;
- su valor lo cambia **solo el SUPER**, con motivo y una línea en `_LOG` (el mismo patrón del interruptor de [CE] CE-03.5);
- se diseña y se prueba en la fase 1 aunque arranque en P-0, porque reservarla cuesta poco y retrofitearla cuesta más.

**Lo que la costura no hace (franqueza):** encenderla **no corrige el pasado**. Los tickets anteriores al cambio quedan sin E32. Por eso la recomendación es fijar la opción **antes de la puesta en marcha del primer cliente**. Hoy todo es desarrollo y no hay exposición.

### 5.4 Qué haría falta en cada caso

- **Si firma P-0:** registrar la aceptación del riesgo Alto por escrito como riesgo residual en ADR-87. Enviar igual CF-1 al contador, para que la empresa cliente lo sepa antes de usar el sistema.
- **Si firma S-1:** el arquitecto-software diseña la extensión con la marca de inventario ya descargado y la E34 enlazada. Pedir a IQ el precio por documento.
- **Si firma S-2:** S-1 hasta la autorización de la DGII; después, el SUPER cambia el valor.
- **Si firma S-6:** quitar la nómina y el dinero del empleado del alcance, y confirmar con el propietario que su precisión 2 cambia.

---

## 6. Conflicto con la hoja de catering firmada ([CE], 2026-10-09)

### 6.1 Dónde chocan

| Tema | [CE] firmado | Vertical Corporativa | ¿Contradicción? |
|---|---|---|---|
| Modelo | Concesionario: el restaurante vende a una empresa cliente (modelo B) | La empresa es dueña; el tercero solo administra (modelo A, H-01) | No: son negocios distintos. Pueden convivir |
| Ruta fiscal del subsidio | CE-03: «Cargo a la empresa» no fiscal y **E31 agrupada** por período | Consumo interno, sin comprobante | No: la diferencia la explica el modelo |
| Licencia | CE-06 (a): `CORPORATIVO` como complemento que **requiere `RESTAURANTE`** | Vertical propia, derivada de la Estándar | **Sí, en el nombre:** `CORPORATIVO` frente a `CORPORATIVA` |
| Corporativo en la Estándar | CE-06 (c) **descartado por ahora**: «se hace con el primer cliente que lo pida» | Es justamente ese pedido | No: se ejecuta lo que [CE] dejó para después. El obstáculo que citaba (la factura de varios conduces en el núcleo) **no aplica**, porque el modelo A no factura por período |
| Padrón | CE-04: `res.ClienteEmpleado` en el esquema del Restaurante, identificación por código o nombre y sin PIN | La Estándar no puede depender de `res` (ADR-112, punto 6). Exige carné con foto y confirmación | **Sí, en la ubicación del padrón y en la política de identificación** |
| Tope | CE-04: rechazo por omisión | El empleado paga al agotar la bolsa | No: CE-04 ya admite «el empleado paga el excedente» por cliente |
| ADR | [CE] proponía ADR-126 y 127, no registrados | — | **Sí, en la numeración:** ADR-126 ya se usó en `master` para «valores de terceros» ([POS] [CE-reg]). B tendrá que renumerar al registrar [CE] |

### 6.2 Resolución propuesta (H-02 (a))

- **Una capacidad común de comensales** (padrón, carné, foto, categorías, topes y saldos en el servidor con `UPDATE` condicional, ADR-45), **fuera de `res`**, con la política de identificación como parámetro (carné con foto obligatoria en la Corporativa; código o nombre en el Restaurante, como firmó CE-04). El esquema lo decide el arquitecto-datos.
- **Dos usos:** la vertical `CORPORATIVA` (modelo A) y el complemento del Restaurante, que se renombra `CARGO_EMPRESA` (modelo B, CE-03 intacto).

### 6.3 ¿Exige precisar lo firmado?

**Sí, dos precisiones de forma, no de fondo:**
1. **CE-06:** el código del complemento pasa de `CORPORATIVO` a `CARGO_EMPRESA` (solo con H-02 (a)). Costo 0: no está registrado ni construido.
2. **CE-04, punto 1:** el padrón no vive en `res.ClienteEmpleado`, sino en la capacidad común, que también sirve al Restaurante. CE-04 conserva sus reglas (sin cédula, sin PIN en la v1, topes en el servidor y las tres opciones al pasar el tope).

**No cambian:** CE-01, CE-02, CE-03, CE-05 ni CE-07. Las dos precisiones las firma el propietario con H-02. Como [CE] es de B, el Documentador las anota cuando B registre los ADR de [CE] en `master`.

---

## 7. Preguntas para el contador de la empresa (texto listo para enviar)

> **Asunto:** Cafetería interna administrada por un tercero – consultas fiscales (GPOS NG)
>
> Estimado/a:
>
> Nuestra empresa tiene una cafetería propia que administra una empresa de terceros por cuenta nuestra: las compras se hacen a nombre de la empresa, el inventario es nuestro y el efectivo se deposita en nuestra cuenta; el tercero nos factura un honorario. Cada empleado tiene un subsidio mensual en pesos que se renueva cada mes y no se acumula. Además, la empresa le cubre al 100 % un almuerzo y una cena por día, y en algunos artículos cubre el 50 % con cargo a ese subsidio. Cuando el subsidio se agota, o en la mitad que no cubre la empresa, el empleado paga con su dinero (efectivo, tarjeta o descuento por nómina, combinables). Los visitantes reciben un e-CF. Los consumos de los empleados se registran en un ticket interno, sin NCF. Le agradeceríamos su criterio sobre lo siguiente:
>
> **CF-1.** Cuando el empleado paga con su dinero en la cafetería de la empresa (por la bolsa agotada o por la mitad no subsidiada), ¿la empresa le está **vendiendo**, con ITBIS y obligación de emitir un comprobante de consumo (E32), según el art. 50, lit. k, y el art. 338, num. 1, del Código Tributario? ¿O basta el ticket interno? ¿Cambia la respuesta si esa parte se cobra **por descuento de nómina** en lugar de en la caja? Y en ese caso, ¿qué límite tiene el descuento salarial (Código de Trabajo, art. 201) y hay que emitir algo al consumir o al descontar?
>
> **CC-06.** El café, el chocolate o el yogur **preparados** en la cafetería, ¿tributan al 18 % o a la tasa reducida del 16 % del bien (art. 345, párrafo II)?
>
> **CC-07.** El consumo subsidiado (almuerzo y cena al 100 %, subsidio mensual y la mitad subsidiada), ¿es un **retiro gravado** sobre el costo (art. 336, num. 2; art. 340, lit. a; Consulta 23-2025), que se declara en el IT-1 como «otras operaciones» con documentos internos? ¿Y si la mayoría de los insumos son exentos (art. 343)?
>
> **CC-10.** El subsidio por empleado, ¿es una **retribución complementaria** (27 %, IR-17)? Si lo es, ¿sobre el costo o sobre el precio de lista? ¿Importa que el sobrante se pierda cada mes?
>
> **CC-11.** El honorario de administración que nos factura el tercero, ¿lleva alguna retención (NG 02-05; Decreto 293-11, art. 25)? ¿Cambia si el tercero es persona física?
>
> **CC-12.** Si la respuesta a CF-1 es que hay que emitir un comprobante, ¿conviene pedir a la DGII la autorización de un **comprobante global diario** por el dinero de los empleados (Decreto 254-06, art. 3, párrafo II), o basta un E32 por cada cobro?
>
> **CC-13.** ¿La actividad registrada de la empresa en el RNC le permite emitir E32 o E31 por la venta de comida a sus empleados y a los visitantes (NG 06-2018, art. 3, párrafo III)? ¿Hace falta registrar una actividad secundaria?
>
> Solo si aplica: si la empresa está en zona franca o es del Estado, ¿se usaría E44 o E45 para los visitantes y qué retenciones corresponden (CC-08 y CC-09)?
>
> Quedamos atentos. Gracias.

**Nota de envío:** CF-1 decide H-04. CC-13 condiciona incluso la venta a visitantes. Lo prudente es enviar este paquete con la adenda de CC-01 a CC-05 de [CE]. El especialista-contable lo suma a la adenda.

---

## 8. Etapa propuesta y estimación

### 8.1 Estimación revisada de la fase 1 (inferida, ±40 %)

| Pieza | [POS] | Revisada | Motivo |
|---|---|---|---|
| Ventana, modo de caja, guarda de módulo y visitante | 0,8 | 0,8 | — |
| Carné, foto, confirmación y sin carné | 0,8 | 0,8 | — |
| Padrón de comensales | 1,0 | 1,0 | — |
| Franjas y motor de beneficios | 1,8 | **1,6** | F-2 elimina el beneficio C aparte y su tope; F-1 simplifica la franja a un bloqueo por artículo |
| Ticket interno atómico, dinero propio y costura | 1,0 | 1,0 | — |
| Reverso interno | 0,4 | 0,4 | — |
| Perfiles | 0,2 | 0,2 | — |
| Bloques del Z | 0,3 | 0,3 | — |
| Reportes RC-01, 02, 04, 05 y 06 | 0,9 | 0,9 | — |
| Nómina con cupo y RC-03 | 0,4 (opcional) | **0,5** | F-4 la hace obligatoria y combinable, con medios configurables por empresa |
| **Base** | 7,2 a 7,6 | **7,5** (de 4,5 a 10,5) | |
| Contingencia en papel por lote (H-10) | — | +0,2 | No estaba en [POS] |
| Opción fiscal (H-04) | — | P-0: 0 · S-1: +0,3 · S-2: +0,4 · S-6: −0,5 | |
| **Total con S-1** | | **≈ 8,0 sp** (de 4,8 a 11,2) | A ≈ 1,2 sp por semana: **unas 6,7 semanas-persona** |
| Con la capacidad común ya construida por [CE] (H-02 (a)) | | ≈ 6,8 sp | Ahorro de ≈ 1,2 sp |

**Efecto en la entrega 3 (inferido):** [CE] la llevaba a unas 38,5 a 39,5 sp. Con la Corporativa y la capacidad común, quedaría en **unas 45,3 a 47,5 sp** (45,3 si se aprovecha la capacidad común; 47,5 sin ella). Licencias e infraestructura de GSF: **0 adicional**. Para el cliente: lector (USD 20 a 150 por caja), impresora térmica si no la tiene (USD 150 a 300) y un nodo por sede grande (USD 500 a 1.000). El precio por e-CF de S-1 no está verificado.

**Etapa:** entrega 3, en un tramo propio después de 3a (mecanismo de verticales). Es recomendable construirlo junto a 3d de [CE], porque comparten la capacidad común. **Nada en la entrega 1.**

### 8.2 Secuencia de agentes del diseño (proyectada, no lanzada)

**Precondición:** la firma de H-01, H-02 y la casilla de H-04, aunque sea «decido después de CF-1»: la costura se diseña igual. El diseño no compila, así que cabe en el límite de la PC A (dos agentes demandantes). Se lanza solo cuando no reste capacidad a la ruta crítica de diciembre.

| # | Agente | Entrada | Entrega | Paralelo |
|---|---|---|---|---|
| 1 | **arquitecto-datos** | Esta hoja firmada, [POS] secciones 2, 4 y 7, [CE] CE-04 | Capacidad común de comensales fuera de `res` (padrón enlazable con `rrhh.Empleado`, carné, foto cifrada, categorías, centros de costo con vigencia); franja por artículo; composición del almuerzo y la cena; cobertura de bolsa por artículo; bolsas con cierre mensual idempotente; cupo de nómina; serie del ticket y del reverso; marca única por comensal, fecha y franja; costo congelado | — |
| 2 | **arquitecto-software** | Diseño de datos | Motor de reparto en el servidor (sección 3.5) dentro del orden de bloqueos (ADR-45); ventana y guarda de módulo; extensión de la ruta única para la costura (H-04), con la marca «inventario ya descargado» y la E34 enlazada; atomicidad AT-1 a AT-9; sincronización del padrón, las fotos y los saldos al nodo; contratos de la API | Puede empezar cuando el arquitecto-datos tenga el esquema |
| 3 | **disenador-ux-ui** | Esquema y contratos | `TarjetaComensal`, `BotoneraFranja` (artículos fuera de franja en gris, bloqueados), `RepartoBeneficios`, cobro combinado con nómina en el `PanelCobro` compartido; objetivo de 10 a 12 s por transacción y foto en menos de 1 s (p95) | En paralelo con el arquitecto-software, una vez fijados los contratos |
| 4 | **auditor-seguridad** | Los tres diseños | Foto y Ley 172-13 (si es un dato sensible, consentimiento, retención), perfiles del tercero, lector por teclado (prefijo y sufijo), límite de identificaciones sin carné, interruptor de la costura solo del SUPER | Al final |

Después: el especialista-contable suma CF-1 y CC-06 a CC-13 a la adenda; el documentador-tecnico registra los ADR firmados; el orquestador agrega el tramo a la entrega 3.

---

## 9. ADR candidatos (estado: Propuesto)

**Números elegidos: 85, 86, 87 y 88.** Están libres en `origin/master` y en todas las ramas remotas ([IDX]). No uso ADR-79 ni 80, aunque también estén libres: los documentos de A del 2026-10-07 (`traspasos/A/hoja-firma-api-reportes-2026-10-07.md` y `propuesta-api-reportes-solo-lectura-2026-10-07.md`) los usan para la API de reportes, que pasó a B, y reutilizarlos confundiría las citas. Quedan libres para otro tema.

### ADR-85 (Propuesto) · Vertical Corporativa: módulo, ventana propia y ticket de consumo interno

- **Contexto:** precisiones 1 a 3 del propietario; ADR-112; la regla de una ventana por vertical.
- **Decisión:** un módulo de vertical (`CORPORATIVA`, según H-02) que activa solo el SUPER; un modo de caja «Corporativa»; la ventana «Facturación Corporativa» con su ruta, su menú y su guarda; el ticket de consumo interno sin NCF, con serie propia, costo congelado y salida de inventario por la clase 5 con `EsConsumoInterno`; el reverso de consumo interno (no nota de crédito); el visitante por la ruta única con e-CF; el arqueo solo con dinero; los perfiles del tercero sin acceso a beneficios.
- **Precisa:** ADR-112, punto 1 (lista de verticales y modos de caja).
- **Alternativas descartadas:** un parámetro de la Facturación Ágil (contradice la ventana por vertical); un complemento del Restaurante (no hay cuenta ni orden en este negocio); «No generar comprobante» como vía normal.

### ADR-86 (Propuesto) · Beneficios del comensal: almuerzo y cena al 100 %, bolsa mensual con cobertura por artículo y franja que bloquea

- **Decisión:** franja opcional por artículo que bloquea la venta fuera de horario (F-1); el almuerzo y la cena al 100 % como composición por grupos, uno por franja y por día (H-05, H-06); la bolsa mensual con cobertura por artículo (100 % por omisión, 50 % configurable, F-2), que vuelve a su monto asignado cada mes sin acumularse (F-3) y es proporcional en el mes de alta (H-07); el orden fijo de la sección 3.5; todo controlado en el servidor con `UPDATE` condicional en el nivel de saldos (ADR-45); los beneficios como formas de liquidación, no como descuentos; medios de pago combinables configurados por empresa, con cupo de nómina (F-4).
- **Alternativas descartadas:** beneficios como descuentos de precio (deforman el costo y la liquidación); el 50 % como beneficio aparte con su propio tope ([POS] revisión 2, superado por F-2); control de topes en la pantalla (carrera entre cajas).

### ADR-87 (Propuesto) · Tratamiento fiscal de la porción pagada por el comensal y costura fiscal

- **Decisión:** el emisor es la empresa propietaria (H-01 (a)). La porción subsidiada va en el ticket interno, sin comprobante. La porción pagada sigue la opción que firme el propietario en H-04 (P-0, S-1, S-2 o S-6), mediante una costura en el servidor (`IExtensionVenta`) que solo cambia el SUPER, con motivo y `_LOG`. Con S-1: un E32 por la porción pagada, enlazado, marcado «inventario ya descargado por el ticket», con E34 en el reverso. Si se firma P-0, el ADR registra el riesgo Alto aceptado por escrito.
- **Alternativas descartadas:** que el cajero elija si emite (error y abuso); E32 mensual (sin apoyo normativo); que cobre el tercero con su RNC (mezcla los modelos).

### ADR-88 (Propuesto) · Capacidad común de comensales compartida entre la Corporativa y el consumo corporativo del Restaurante

- **Decisión:** padrón, carné, foto (cifrada, sin exportación, borrado a los 90 días de la baja), categorías, centros de costo con vigencia, topes y saldos en una capacidad común **fuera de `res`**, con la política de identificación como parámetro. El módulo fija el modelo fiscal: `CORPORATIVA` = interno; `CARGO_EMPRESA` = CE-03. La cédula no se guarda.
- **Precisa:** CE-04, punto 1, y CE-06 de la hoja del 2026-10-09 (y los ADR que B registre a partir de ella, que ya no podrán usar el número 126).
- **Alternativas descartadas:** dos padrones separados (+1,2 sp); un módulo único con un parámetro «modelo de operación».

Los textos completos se redactan para `master` al firmar; los registra el coordinador (B) con el Documentador.

---

## 10. Riesgos principales y qué pasa al firmar

| # | Riesgo | Severidad | Mitigación o aceptación |
|---|---|---|---|
| R-1 | Porción pagada sin NCF (si se firma P-0) | **Alta** | Costura lista; CF-1 al contador antes del primer cliente; si se mantiene, se acepta por escrito en ADR-87 |
| R-2 | El contrato real resulta una concesión | Alta | H-01 y la cláusula contractual (compras y depósitos a nombre de la empresa) |
| R-3 | Cafetería detenida sin conexión | Alta (operativa) | H-10 (a) |
| R-4 | El tercero infla su liquidación | Alta | H-08 (a), H-09 (a), RC-05 y RC-06 |
| R-5 | Exposición de las fotos (Ley 172-13) | Alta | H-08 (a) y la revisión del auditor-seguridad |
| R-6 | La entrega 3 crece unas 7 a 8 sp | Media | Capacidad común (H-02); nada en la entrega 1 |
| R-7 | Retribución complementaria (IR-17) para la empresa cliente | Media (para el cliente, no para GPOS) | RC-02 y RC-04 con el costo; CC-10 al contador |

**Si el propietario firma:**
1. El coordinador (B) registra ADR-85 a 88 y las precisiones de CE-04 y CE-06.
2. El especialista-contable suma CF-1 y CC-06 a CC-13 a la adenda; el propietario la envía.
3. Se lanza la secuencia de la sección 8.2 cuando no reste capacidad a la entrega 1.

**Si rechaza:**
- **H-01 (b):** esta hoja se rehace sobre el modelo de concesión; la Corporativa queda como el complemento de [CE] llevado a la Estándar (fase 2, ≈ 1,0 a 1,5 sp más).
- **H-02 (c):** se diseñan dos padrones (+1,2 sp) y [CE] no se toca.
- **H-04 S-6:** se quitan el dinero del empleado y la nómina del alcance, y el propietario confirma por escrito que cambian su precisión 2 y F-2.

---

## Resumen: los 5 puntos que más importan

1. **H-04, la porción que paga el empleado:** «sin NCF» es riesgo **Alto** según el contable (art. 50, lit. k; art. 338, num. 1). S-1 (un E32 automático solo por esa porción) lo baja a Bajo por ≈ 0,3 sp. La costura permite decidir después de CF-1, **pero antes del primer cliente**, porque encenderla no corrige el pasado.
2. **H-01, el modelo de operación:** todo el diseño supone que la cafetería funciona por cuenta de la empresa (compras, inventario y efectivo suyos). Si en la sustancia es una concesión, nada puede ir sin comprobante.
3. **F-2 cambia el motor:** el 50 % se carga a la bolsa. Ya no hay tres beneficios, sino dos (el almuerzo y la cena al 100 %, y la bolsa con una cobertura por artículo), y si la bolsa no alcanza, la diferencia la paga el empleado. Los ejemplos de la sección 3.6 son la referencia para el QA.
4. **H-02, el encaje con catering:** una capacidad común de comensales fuera de `res`, con `CORPORATIVA` para la vertical y `CARGO_EMPRESA` para el complemento del Restaurante. Exige dos precisiones de forma en CE-04 y CE-06, de costo 0, y ahorra ≈ 1,2 sp.
5. **H-11 y la estimación:** nada en la entrega 1. La construcción va en la entrega 3, con ≈ 7,5 sp de base y ≈ 8,0 sp con S-1 (de 4,8 a 11,2), porque la nómina pasa a la fase 1.

### Cierre
- Estado: Completado (hoja preparada; decisiones H-01 a H-11 **Pendientes de firma**; F-1 a F-4 registradas como firmadas)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\hoja-firma-vertical-corporativa-2026-10-15.md` (sin commit)
- Supuestos: sp, volúmenes y costos inferidos (±40 %); orden de magnitud del ITBIS ilustrativo; normas citadas según [CONT], con las fuentes secundarias que él marca; precio por e-CF no verificado; lectura de F-3 como «vuelve al monto asignado» (PF-3); PF-1 y PF-4 como precisiones propuestas
- Decisiones candidatas a ADR: ADR-85, 86, 87 y 88 (Propuesto); precisiones de CE-04 y CE-06 de la hoja del 2026-10-09
- Entregas a otros agentes: especialista-contable → CF-1 y CC-06 a CC-13 a la adenda; arquitecto-datos, arquitecto-software, disenador-ux-ui y auditor-seguridad → sección 8.2, tras la firma; documentador-tecnico (vía B) → registrar ADR-85 a 88 y renumerar los ADR de [CE] (el 126 está ocupado)
- Próximo paso recomendado: que el propietario firme H-01, H-02 y la casilla de H-04, y que se envíe la sección 7 al contador
