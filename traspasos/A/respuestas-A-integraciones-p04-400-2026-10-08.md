# Respuesta del equipo A (arquitecto-integraciones) a P-04 y al 400 de IQ

**Para:** equipo B y propietario · **De:** equipo A (arquitecto-integraciones) · **Fecha:** 2026-10-08
**Responde a:** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-07-conector-iq-040-para-el-nucleo.md`, sección 3 (P-04 y «El 400 de IQ»)
**Estado:** recomendaciones técnicas. No es una firma: decide el propietario (C2).

**Fuentes, todas leídas sin modificar nada:**
- [AVISO]: el aviso de B citado arriba.
- [K18]: `respuestas-A-k16-k18-k19-2026-10-07.md`, sección 2, aprobado por el propietario («como se recomendó», K18-a y K18-b; `decisiones-por-registrar-2026-10-07.md:64`).
- [A01]: `respuestas-A-conector-iq-2026-10-07.md`, A-01 (regla 409) y A-03 (estados).
- [DEC]: `decisiones-por-registrar-2026-10-07.md:55` (anulación automática por rechazo), `:60` (condiciones A, B y C) y `:64` (K18-a y K18-b).
- [DIS]: `GPOS-NG-AddOn-IQS`, `docs/integraciones/2026-10-07-conector-iq-diseno.md` en `49f38b7` (el commit que cita el aviso). La sección 19 es idéntica en la punta actual de `origin/b/conector-iq-instalador` (`80b667d`).
- El código del conector en `49f38b7`: `src/GPOS.Conector.Iq/Diario/ProcesadorEmision.cs` ([PE]), `src/GPOS.Conector.Iq/Iq/InterpreteIq.cs` ([II]) y `tests/GPOS.Conector.Iq.Tests/ConflictoReemisionTests.cs` ([T]). El mock está en `origin/b/conector-iq-mock`, en `src/GPOS.Conector.Iq.MockIq/Api/EndpointsIq.cs` ([MOCK]).
- [IQ-OAS]: `docs/referencias/2026-10-07-iq-openapi.json` («IQ SOLUTION API de Facturación Electrónica», OpenAPI 3.1.0, `info.version` 1.0). [SYNC]: `GSF.SyncToIQS/Services/DocumentSignService.cs:109-137`.
- ADR-108 (punto 2 y la sección «Por confirmar») y ADR-74 (puntos 1 y 9), en `GPOS NG/docs/adr/`.

No compilé, no corrí pruebas, no llamé a IQ y no toqué ninguna rama.

---

## 0. Resumen

| # | Tema | Veredicto de A | ¿Cambia algo firmado? | Qué hace cada lado | sp (inferido, ±50 %) |
|---|---|---|---|---|---|
| **P-04** | «409 con el estado real» de K-18 entregado como **resultado diferido** de la generación, no como código del `POST` | **Aceptar**, con 3 correcciones al conector (H-2, H-3 y H-4) | **No cambia K18-a, K18-b ni la clave de A-01.** El punto 2 de ADR-108 sí necesita una **precisión de registro** («única excepción» → dos excepciones). Hay **dos preguntas de confirmación** para el propietario (P-04-a y P-04-b) | **Núcleo:** sondeo con `GET`, sin notificación; estados `VERIFICANDO` → `CONFLICTO` con `EstadoProveedor`; reglas de la sección 1.3. **Conector:** timbre y seguimiento del estado real; 409 si se reenvía otra vez | Núcleo 0,05 (dentro de T-29c); conector 0,1 |
| **400 de IQ** | Un 400 con campo `estado` se consulta en lugar de quedar en `CONFLICTO` | **Aceptar la idea, no la implementación actual.** Tiene un defecto **Alto** (H-1): con dos «no encontrado» **reenvía solo** el mismo cuerpo, y eso contradice K-18 | No. Es coherente con la salvedad «por verificar» de [K18] | **Conector:** tras un 400, «no encontrado» lleva a `CONFLICTO`, nunca a `PENDIENTE`; el disparo solo con un estado conocido (H-5); contraste antes de adoptar un «secuencia ya utilizada» en el primer envío (H-6). **Propietario:** pregunta P-02 a IQ (sección 2.4) | Conector 0,1 |

**Total:** unas 0,05 sp del núcleo y 0,2 sp del conector, todo inferido. El costo externo incremental es de **USD 0** (inferido): son dos `ConsultECF` por cada reenvío corregido, un caso raro, y [IQ-OAS] no publica una tarifa por consulta.

---

## 1. P-04: el «409 con el estado real» como resultado diferido

### 1.1 Veredicto: se acepta

**Por qué el `POST` no puede dar el 409 (verificado):**
- La espera del `POST /v1/comprobantes` es `Prefer: wait=N`, con 8 s como máximo ([DIS] 7.4).
- Las dos consultas «no encontrado» deben estar separadas al menos 60 s, y la primera debe hacerse 2 min después del último envío del e-NCF ([DIS] 7.3; [PE]:307-312).
- Responder 409 dentro del `POST` obligaría a consultar sin separación, lo que rompe la regla de oro, o a retener la petición más de 60 s, lo que rompe el tiempo de espera del cliente (N + 1 s, [DIS] 10.2).

**La sustancia de lo aprobado se conserva.** [K18] decía: «si la consulta encuentra el e-NCF, devuelve 409 con el estado real y el núcleo sigue ese estado». Lo que importa es que **la generación corregida nunca sale** si IQ ya tiene el e-NCF, y el conector lo cumple: [PE]:738-757 la deja en `CONFLICTO` con `ECF-IQ-0033` y `EstadoProveedor`, sin enviarla, y la prueba [T]:148 lo comprueba. El «409» era el medio, no la decisión.

**Alternativas descartadas:**
- **Híbrido: una consulta dentro del `POST` y 409 inmediato si IQ ya lo tiene.** Un «encontrado» es concluyente con una sola consulta, así que sería correcto. Se descarta porque crea dos caminos para el mismo resultado, y el núcleo tendría que tratar los dos. El ahorro, de 1 a 3 min en un caso raro y sin cliente esperando, no lo justifica.
- **Retener el `POST` hasta tener el resultado.** Bloquea el hilo de la consola hasta 3 min y choca con el tiempo de espera de 8 + 1 s.

### 1.2 Cómo lo ve el núcleo: estado, evento y sondeo, sin notificación

**Secuencia, en la pista e-CF del núcleo (T-29c):**

| Paso | Núcleo | Conector |
|---|---|---|
| 1 | El ADMIN o el SUPER elige «Reenviar corregido» (K18-a). Se escriben la línea en `_LOG` y `fiscal.EcfEvento` `ECF_REENVIO_CORREGIDO`. Se inserta `fiscal.Ecf` generación *k+1*, con el **mismo** e-NCF, en `ENVIANDO` | — |
| 2 | `POST /v1/comprobantes` (clave `…:k+1`) | La admite sin 409 y responde **202**: `estadoOperacion = VERIFICANDO`, `codigo = ECF-IQ-0013`, `llegoAlProveedor = false` ([DIS] 19.2; [T]:201) |
| 3 | La generación *k+1* pasa a `VERIFICANDO` (lista de A-03). La generación *k* sigue en `CONFLICTO` como fila final, sin `UPDATE`, y deja de contar como conflicto abierto porque ya no es la generación mayor del par `(DocumentoId, Rol)` | Consulta el e-NCF dos veces |
| 4 | **Sondeo** con `GET /v1/comprobantes/{clave}`: cada 20 s durante 5 min, y después la espera creciente general del despachador | — |
| 5a | Si el resultado es normal (`EN_PROCESO` o final), sigue el flujo de siempre: sello, evidencia y acuse (ADR-74) | Dos «no encontrado»: envía con el mismo e-NCF |
| 5b | Si el resultado es `CONFLICTO` con `codigo = ECF-IQ-0033` y `estadoProveedor`, el núcleo aplica la sección 1.3 | No envía nada |

**Tiempo esperado (inferido, a partir de [PE]:307-312 y [DIS] 7.3):**
- Si el `CONFLICTO` tiene más de 2 min, que es lo normal porque «Reenviar corregido» lo decide una persona, el resultado llega en **60 a 90 s**: la separación de 60 s más el ciclo del procesador, cuyo período no verifiqué.
- En el peor caso, unos **3 a 4 min**.
- La consola no espera: muestra «Verificando en el proveedor (1 a 3 minutos)», y el resultado aparece en la bandeja, en el Visor y en la alerta.

**Por qué sondeo y no notificación.** El Protocolo de Conectores v1 es solo de petición y respuesta sobre la tubería ([DIS] 10.1). Para que el conector notificara al núcleo haría falta un canal inverso, con la verificación de identidad de ADR-75 en el otro sentido. Es mucho costo para un caso raro, y el despachador ya sondea por `VERIFICANDO`, `EN_PROCESO` y `AGOTADA`. **Se descarta** la notificación, y también una espera larga en el `GET`, que el protocolo no tiene.

**Datos del núcleo (para el arquitecto-datos de A):**
- `fiscal.Ecf.EstadoProveedor varchar(15) NULL`: solo con `ECF-IQ-0033`, y con los valores de la lista de A-03.
- `fiscal.Ecf.CodigoConector varchar(20) NULL`, para guardar `ECF-IQ-0013` o `ECF-IQ-0033` sin interpretarlo, porque el núcleo es genérico (73.7).
- Ninguna tabla nueva.

**Sello (ADR-74).** La generación *k+1* con `ECF-IQ-0033` tiene `llegoAlProveedor = false`, así que **no se sella**. La generación *k*, que llegó al proveedor, ya está sellada como `CONFLICTO`. El resultado fiscal real, cuando lo adopta P-04-b, es un sello de **otro tipo** sobre la generación *k* (ADR-74, «lo que llega después»). No hace falta nada nuevo en el conector.

### 1.3 Qué hace el núcleo con `ECF-IQ-0033`, según el estado real

| `estadoProveedor` | Qué significa | Recomendación de A | Fuente |
|---|---|---|---|
| `RECHAZADO` | La DGII dictaminó sobre el contenido de una generación anterior. El e-NCF está consumido | **Se aplica la regla general del rechazo:** anulación automática con A, B y C para `O`, X-1 manual para `R` (K16-a) y X-2 para una nota. El resultado trae `accionRechazo` ([PE], línea 1104) | [DEC]:55 y :60; [K18] («si es `RECHAZADO`, se aplica la anulación automática»). **Confirmar con P-04-a** |
| `ACEPTADO` o `CONDICIONADO` | El e-CF **existe ante la DGII** con el contenido de la generación *k* (inferido: es la única que llegó con ese e-NCF, salvo una cadena de reenvíos) | **El núcleo adopta el estado** para el e-NCF y lo asocia a la generación *k*, que tiene la evidencia y el canónico. Antes de cerrarlo, pide `GET …/contraste` de la clave *k*: si `MontoTotal`, la fecha y el RNC coinciden con la instantánea, queda `ACEPTADO`. Si no coinciden, queda en `CONFLICTO` con revisión humana. Dejarlo en `CONFLICTO` sin más **ocultaría un e-CF válido al 607** | [K18] («el núcleo sigue ese estado»). **Confirmar con P-04-b** |
| `EN_PROCESO` | Firmado, sin dictamen | Lo mismo que la fila anterior, con seguimiento hasta el estado final | Ídem |
| `CONFLICTO` (IQ tiene varias filas o la secuencia está consumida sin timbre) | No se sabe | Revisión humana: solo se permite «Anular el documento» | K18-a |

**Reglas del núcleo que no dependen de P-04-a ni de P-04-b:**
1. Con `EstadoProveedor` no nulo, la consola **no ofrece «Reenviar corregido»**: volvería a dar `ECF-IQ-0033` (ver H-3).
2. Si `EstadoProveedor` es `ACEPTADO`, `CONDICIONADO` o `EN_PROCESO`, «Anular el documento» **no es** «anular un e-NCF no usado». Es una nota de crédito E34 sobre un e-CF aceptado (ADR-70). La pregunta P-01 (608 o ANECF) solo cubre el `CONFLICTO` en el que IQ nunca registró el e-NCF.

### 1.4 ¿Cambia algo firmado?

- **K18-a y K18-b: no.** La salida sigue siendo humana: la persona decide reenviar, y lo que pasa después es consecuencia de esa decisión. Ningún `CONFLICTO` se anula por sí solo, salvo el caso de P-04-a.
- **A-01 y P-A5: la clave no cambia.** La regla 409 de A-01 conserva su efecto: no se envía una generación nueva de un e-NCF que ya llegó. Solo cambia el medio, de código HTTP a resultado.
- **ADR-108, punto 2 (texto firmado):** dice «**Única excepción:** el e-CF de reemplazo… El conector rechaza con 409…». K-18, aprobado después, agregó una **segunda excepción** («Reenviar corregido» con el mismo e-NCF). Con P-04, el rechazo de esa excepción es diferido. ADR-108 todavía lista K-18 como «Por confirmar» (`GPOS NG/docs/adr/ADR-108.md`, sección «Por confirmar con el equipo A»). **Hace falta una precisión de registro** (documentador técnico), no una firma nueva, porque K18-a y K18-b ya están firmados.

**Preguntas para el propietario** (confirman la lectura; no abren decisiones nuevas):

| # | Pregunta | Recomendación de A | Alternativa descartada |
|---|---|---|---|
| **P-04-a** | Si «Reenviar corregido» descubre que la DGII **ya rechazó** ese e-NCF, ¿se aplica la anulación automática de la regla general del rechazo, aunque el documento venga de un `CONFLICTO` (K18-b dice «un `CONFLICTO` nunca se anula automáticamente»)? | **Sí.** Hay un dictamen de la DGII, que es lo que exige la anulación automática ([DEC]:55). K18-b protege de anular **sin** dictamen | Dejarlo en `CONFLICTO` y anular a mano: retrasa la anulación y la tarea A sin ganar seguridad |
| **P-04-b** | Si descubre que la DGII **ya aceptó** (o tiene en proceso) ese e-NCF, ¿el núcleo adopta ese estado para el documento después de un contraste automático correcto, y solo vuelve a revisión humana si el contraste no coincide? | **Sí**, como dice [K18] («el núcleo sigue ese estado»). B implementó «revisión humana» para todo lo que no sea `RECHAZADO` ([DIS] 19.2, caso 5), y eso deja un e-CF aceptado fuera del 607 hasta que alguien actúe | Revisión humana siempre: no hay ninguna salida definida para un `ACEPTADO` (no se puede reenviar, y anular exige una E34) |

### 1.5 Hallazgos para el conector (equipo B)

| # | Severidad | Hallazgo | Evidencia | Recomendación |
|---|---|---|---|---|
| **H-2** | Media | Con `ECF-IQ-0033` y un estado `ACEPTADO`, `CONDICIONADO` o `EN_PROCESO`, el resultado **no trae el timbre** (`codigoSeguridad`, `fechaHoraFirma`, `urlQr`) aunque la consulta lo obtuvo. Además, la operación en `CONFLICTO` **no tiene seguimiento** si el estado real es `EN_PROCESO` (inferido: no vi seguimiento de operaciones en `CONFLICTO`) | [PE]:738-757 (se descarta `c.Timbre`) | Incluir el timbre de la consulta en el resultado y actualizar `EstadoProveedor` con el seguimiento hasta el estado final, o documentar que el núcleo usa `GET /v1/comprobantes?rnc=&encf=` ([DIS] 10.2) para obtenerlos |
| **H-3** | Media | Un segundo «Reenviar corregido» después de `ECF-IQ-0033` se admite otra vez ([PE], regla de generaciones: `previa.Estado == Conflicto`), vuelve a consultar y vuelve a dar `ECF-IQ-0033`. Es un ciclo que solo para el tope de 255 | [PE]:385-410 | 409 con un código estable (por ejemplo, `ENCF_REGISTRADO_EN_PROVEEDOR`) si la generación previa en `CONFLICTO` tiene `EstadoProveedor`. El núcleo también lo bloquea (1.3, regla 1) |
| **H-4** | Baja | [DIS] 19.2, caso 5, dice «si no, revisión humana». Hay que alinearlo con P-04-b cuando el propietario responda | [DIS] 19.2 | Ajustar el texto y la prueba [T]:148 |

---

## 2. El 400 de IQ: la defensa de B

### 2.1 Lo que se verificó

- **[IQ-OAS]:** el 400 de `SendECF` es `BadRequest`, con el esquema `ErrorResponse` (solo `error`). No hay `estado`. Coincide con lo que cita B.
- **[SYNC]:** trata todo 400 como `{"error": …}`, y el único caso con estado dentro del texto es «Esta secuencia ya ha sido utilizada con el estatus Aceptado» (`DocumentSignService.cs:119-122`).
- **[MOCK]:** `Validacion400ConEstado` devuelve `{error, estado}` con estado 400 (`EndpointsIq.cs:344-346`). Es una **forma inventada por B** para la prueba, no una forma observada en IQ.
- **[II]:88-125:** primero «secuencia ya utilizada» (prefijo) → consulta (`ECF-IQ-0010`). Después, **cualquier** `estado` no vacío → `Indeterminado` con `EstadoEnError` → `VERIFICANDO` (`ECF-IQ-0012`). Lo demás → `Invalido` → `CONFLICTO` (`ECF-IQ-0400`, [PE]:686-702).
- **[T]:92-102** solo comprueba el estado inicial (`VERIFICANDO`, `ECF-IQ-0012`). **No hay ninguna prueba** de lo que pasa cuando la consulta no encuentra el e-NCF.

### 2.2 Valoración

**La idea es correcta y es coherente con lo firmado.** [K18] ya dejaba la salvedad «si IQ entrega un rechazo de la DGII dentro de un 400, ese caso es `RECHAZADO` y no `CONFLICTO`». Consultar es la forma segura de averiguarlo sin interpretar un texto (PR-44). Si la consulta encuentra el e-NCF, adoptar su estado es correcto, porque el contenido que IQ tiene es el de **esta misma** generación (`H_j`), a diferencia del caso de P-04.

**La implementación tiene un defecto que hay que corregir antes de la prueba de integración:**

| # | Severidad | Riesgo | Evidencia | Corrección |
|---|---|---|---|---|
| **H-1** | **Alta** | Después de `ECF-IQ-0012`, dos «no encontrado» llevan la operación a `PENDIENTE` y **reenvían el mismo cuerpo** (la regla de 7.3 pensada para los tiempos agotados). Un 400 es una respuesta **concluyente** de que IQ no lo procesó, así que el reenvío vuelve a dar 400. El ciclo se repite hasta 8 intentos (unos 25 a 30 min, inferido) y termina en `AGOTADA`, que el núcleo ve como `VERIFICANDO` con alerta (A-03), **no** como `CONFLICTO`. Esto contradice K-18 («el 400… nunca se reenvía de forma automática»), oculta el defecto de la guardia y repite 8 envíos inválidos a IQ | [PE]:783-797 (`NoEncontrado` → `Pendiente`, sin distinguir el origen `ECF-IQ-0012`); [T]:92-102 no lo cubre | Marcar la operación con un origen 400 (por ejemplo, reutilizar `ConfirmarNoRegistrado` o un indicador `OrigenRespuesta400`). Con ese origen, el **primer** «no encontrado» lleva a `CONFLICTO` (`ECF-IQ-0400`), porque un 400 no necesita la doble consulta: IQ ya dijo que no lo procesó. Con «encontrado», se adopta el estado. Agregar la prueba «400 con `estado` + no encontrado = `CONFLICTO`, 1 sola llamada a `SendECF`» |
| **H-5** | Baja | **Cualquier** valor de `estado` dispara la consulta («error», «400», «Inválido»). Con H-1 corregido, el peor caso es una consulta de más antes del `CONFLICTO` | [II]:101 y 299-311 (`EstadoEnCuerpo` no compara con la tabla) | Aceptable con H-1. Si se prefiere precisión: consultar solo si `estado` está en la tabla de IQ (Aceptado, Aceptado Condicional, Rechazado, En Proceso), y dejar los demás en `CONFLICTO` con el texto en la alerta |
| **H-6** | Media (inferido) | «Secuencia ya utilizada» en el **primer** envío de un e-NCF, sin un intento previo en el diario y con `reintento = false`, indica un choque de numeración: una base restaurada, un diario perdido o un defecto. Hoy la consulta adopta el estado que encuentra, que puede ser el de **otro documento** | [PE]:765-768 (adopta sin contraste); [DIS] 6.3 | En ese caso, adoptar solo si el contraste (`jsondata` frente a la instantánea: `MontoTotal`, fecha y RNC del comprador) coincide. Si no coincide, `CONFLICTO`. No verifiqué si el código ya distingue el primer envío |
| R-1 | Baja | La forma real de un 400 de IQ puede ser otra (`status`, `codigo`, `mensajes`), y entonces la defensa no se dispara nunca | [MOCK] usa una forma supuesta | Si no se dispara, el resultado es `CONFLICTO`, que es la **falla segura**: revisión humana, sin anulación. La respuesta de IQ a P-02 cierra el riesgo |

**Conclusión:** con H-1 corregido, la defensa es **segura en los dos sentidos**:
- un dictamen real de la DGII se adopta por consulta, nunca por texto;
- un 400 sin registro en IQ termina en `CONFLICTO`, como manda K-18.

Mientras IQ no responda, el comportamiento por omisión ante cualquier forma desconocida es `CONFLICTO`. Es correcto.

### 2.3 P-01 (para información)

No es mío: lo responde el especialista-contable. Solo una precisión de integración: P-01 aplica **solo** al `CONFLICTO` en el que IQ **no** tiene el e-NCF. Si la consulta lo encuentra, es la tabla de 1.3, no 608 ni ANECF.

### 2.4 Pregunta exacta para el cuestionario a IQ Solution (P-02 del propietario)

Va junto a IQ-06 del cuestionario de B (`docs/integraciones/2026-10-07-conector-iq-preguntas.md`, línea 58), como texto literal:

> **P-02. Respuestas 400 de `POST /api/eCF/SendECF/{TipoeCF}`.**
> Su documentación OpenAPI (versión 1.0) describe el 400 solo como `{"error": "<texto>"}`. Para integrar de forma segura les pedimos que confirmen por escrito, con un ejemplo real del ambiente de pruebas (TesteCF) de cada caso:
> 1. ¿Puede `SendECF` responder **400** cuando el comprobante **ya llegó a la DGII** o cuando la DGII lo **rechazó**? ¿O el dictamen de la DGII (Aceptado, Aceptado Condicional, Rechazado, En Proceso) llega siempre como **200** con el campo `estado`?
> 2. ¿Qué campos puede traer el cuerpo de un 400, además de `error` (por ejemplo, `estado`, `codigo`, `mensajes`)? ¿Hay un **código de error estable** que podamos usar en lugar del texto?
> 3. Cuando `SendECF` responde 400, ¿garantizan que **no registraron, no firmaron y no consumieron** el e-NCF, de modo que `POST /api/eCF/ConsultECF` con ese e-NCF devuelva «no encontrado»?
> 4. Para el mensaje «Esta secuencia ya ha sido utilizada con el estatus *X*», ¿qué valores puede tomar *X*? ¿El texto es fijo o puede cambiar entre versiones?
> 5. Después de un 400 de validación, si corregimos el contenido y enviamos **el mismo e-NCF**, ¿lo aceptan como un envío nuevo? ¿O responden «secuencia ya utilizada»?
> 6. Sus validaciones del 400, ¿son solo las del esquema XSD de la DGII (Formato e-CF v1.0)? ¿O tienen reglas propias? Si tienen reglas propias, ¿pueden compartir la lista?

**Qué decidimos con cada respuesta:**
- **1 y 3:** si un 400 puede traer un dictamen, la defensa queda como regla firme. Si no puede, queda solo como red de seguridad.
- **2:** si hay un código estable, deja de compararse el texto (H-5).
- **4:** la tabla de 6.3 de [DIS].
- **5:** confirma el paso 4 de «Reenviar corregido».
- **6:** sirve para cerrar la diferencia entre la guardia y IQ, que es la causa de los `CONFLICTO` por un 400.

---

## Supuestos

- La sección 19 de [DIS] y el código en `49f38b7` representan la versión 0.4.0 que entrega B. La sección 19 es igual en `80b667d`.
- El período del ciclo del procesador del conector y la ausencia de seguimiento de las operaciones en `CONFLICTO` son **inferidos**. No los verifiqué.
- Los tiempos (60 a 90 s típico, 3 a 4 min en el peor caso, 25 a 30 min del ciclo de H-1) y las cifras de sp son **inferidos** (±50 %).
- Que IQ no cobre por `ConsultECF` es **inferido**: [IQ-OAS] no publica tarifas.
- Que el contenido aceptado en IQ sea el de la generación *k* es **inferido**. Con una cadena de varios reenvíos que llegaron a IQ, el contraste lo decide.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\respuestas-A-integraciones-p04-400-2026-10-08.md`
- Supuestos: los de la sección «Supuestos».
- Decisiones candidatas a ADR (precisión de ADR-108, punto 2):
  - K-18 como segunda excepción a la regla 409, con el rechazo entregado como resultado diferido (`ECF-IQ-0033`). Alternativas descartadas: el 409 en el `POST`, el híbrido y retener la petición.
  - Un 400 de IQ con «no encontrado» va a `CONFLICTO` sin doble consulta. Alternativa descartada: el reenvío de 7.3.
- Entregas a otros agentes:
  - arquitecto-integraciones y backend de B: H-1 (Alta), H-2, H-3 y H-6 (Media), H-4 y H-5 (Baja), con las pruebas correspondientes contra el mock;
  - arquitecto-datos de A: `fiscal.Ecf.EstadoProveedor` y `CodigoConector`;
  - backend de A (T-29c): el sondeo de 1.2 y las reglas de 1.3;
  - documentador técnico de A: la precisión de registro de K-18 en ADR-108 (punto 2 y «Por confirmar»);
  - propietario: P-04-a, P-04-b y la pregunta P-02 a IQ (2.4);
  - especialista-contable: P-01, acotada según 2.3.
- Próximo paso recomendado: que B corrija H-1 antes de la prueba elevada y que el propietario responda P-04-a y P-04-b y envíe P-02 a IQ.
