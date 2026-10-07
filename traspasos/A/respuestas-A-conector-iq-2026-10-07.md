# Respuestas del equipo A a las tareas del conector de e-CF con IQ (ADR-108)

**Para:** equipo B y propietario · **De:** equipo A (arquitecto-software) · **Fecha:** 2026-10-07
**Responde a:** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-07-tareas-a-conector-iq.md`
**Estado:** recomendaciones técnicas. Nada de esto es una firma: el propietario decide (C2).

**Fuentes leídas, todas en solo lectura**
- Equipo B (`GPOS-NG-AddOn-IQS`, `origin/b/conector-iq-diseno`):
  - `docs/decisiones/2026-10-07-respuestas-propietario-df.md` ([DEC]), que manda sobre la hoja;
  - `docs/decisiones/2026-10-07-hoja-firma-adr108-conector-iq.md` ([HOJA], revisión 4);
  - `docs/integraciones/2026-10-07-conector-iq-diseno.md` ([DIS]);
  - `docs/integraciones/2026-10-07-conector-iq-preguntas.md` ([PRE]);
  - `docs/seguridad/2026-10-07-huella-sha256-json-ecf.md` ([SEL]) y `docs/seguridad/2026-10-07-revision-dp10-ancla-adjunto.md` ([RDP]).
- Núcleo (`GPOS-NG-numeracion`, rama `feature/modelo-ng`, `a1fe022`):
  - el código citado abajo;
  - `docs/datos/2026-10-04-h0-ddl-entrega1.sql` ([DDL]);
  - `docs/integraciones/2026-10-07-ecf-enchufable.md` ([ECF-E]);
  - `docs/decisiones/2026-10-01-decision-ecf.md`, `docs/decisiones/2026-10-06-hoja-firma-ola4.md` ([OLA4]) y `docs/decisiones/2026-10-07-hoja-firma-adr073-auxiliar-contable.md` ([H73]);
  - `docs/datos/2026-10-05-adjuntos-modelo-datos.md` ([ADJ-D]);
  - ADR-44, 54, 67, 70 y 73 en `origin/master` (`c4aff09`).

No compilé, no corrí pruebas y no toqué ningún árbol.

---

## 0. Resumen

| # | Tema | Veredicto de A | Efecto en el contrato o en ADR-108 | sp (inferido, ±50 %) | Ola o momento recomendado |
|---|---|---|---|---|---|
| **A-01** | Clave `{Uid}:{Rol}` | **Aceptar con cambios:** clave `{Uid}:{Rol}:{Generacion}` | Hay que volver a emitir un documento que la guardia rechazó (`INVALIDO`) sin chocar con el 409 | 0,05 (dentro de T-29c) | Pista e-CF del núcleo, antes de congelar el protocolo |
| **A-02** | `GPOS.Conectores.Contratos` con `gpos-jcs-1` | **Aceptar con cambios** | Paquete del núcleo; A es dueño y B aporta el código por una rama `b/` | 0,3 (0,2 de A más la revisión) | Fase 0, antes de congelar el protocolo v1 |
| **A-03** | Estado `EN_PROCESO` | **Aceptar**, y sumar `INVALIDO` | Lista de estados de `fiscal.Ecf` cerrada en este documento | 0 (DDL de T-29b) | T-29b |
| **A-11** | Campos del sobre | **Aceptar con cambios:** 4 precisiones y `versionCanonico` | El sobre queda definido para el borrador v1 | 0,1 | Con A-02 |
| **A-13** | Sello de integridad | **Aceptar** como ADR del núcleo, **ADR-74 registrado por A**, con 4 dependencias explícitas | ADR-108 lo cita como ADR-74, no «sin número» | 5,0 (sin cambio) | Fase 0 con ADR-108; fase 1 antes del piloto; completa antes de la producción general |
| **A-14** | Instantánea fiscal | **Aceptar con cambios:** buena parte ya existe; la prueba primaria es el canónico guardado | Precisa D-03 | 0,3 (B decía 0,2) | Fase 0 |
| A-04 | Identidad de la API para la ACL | Aceptar con cambios: un **grupo local** en lugar de publicar el SID | Precisa D-12 | 0,1 | Instaladores, pista e-CF |
| A-05 | Descuentos globales prorrateados | **Ya está hecho** en `Calculadora` | Ninguno | 0,02 | — |
| A-06 | Quitar `CK_Ecf_Proveedor` | **Sí** (confirmado), con FK a `integ.Conector` | Ninguno en el protocolo | 0 | Ya, en el DDL de diseño |
| A-07 | Contenido del canónico | Aceptar | Ninguno | 0,3 (dentro de T-29a y T-29c) | Pista e-CF |
| A-08 v2 | Pesables | Aceptar; no hace falta guardar el precio derivado | Ninguno | 0,1 | Pista e-CF |
| A-09 | Plazo desde la salida y `finContingencia` | Aceptar; el dato ya existe | Ninguno | 0,05 | Pista e-CF |
| A-10 | El ERP ignora el rol `R` | Aceptar; sale casi solo del modelo | Ninguno | 0,1 | Con X-2 (después del corte) |
| A-12 | Precisión de ADR-67, punto 2 | **Aceptar con 6 cambios** (choque de nombres con `doc.Adjunto.Proveedor`, cuota, límite por ancla, desmarcado…) | Precisa el punto 7 de ADR-108 | 0,3 | Después de 3b-A (ADR-67 aún no existe) |
| A-15 | Comprador de la E32 | Aceptar con cambios: el cliente genérico es **por caja**, no por empresa | Ninguno | 0,25 | Pista e-CF |
| A-16 | Ámbito de la propina | Aceptar | Ninguno | 0,05 | Pista e-CF |
| A-17 | Cambio de tipo, aviso y reporte | **Aceptar con cambios:** **conflicto de inventario** con el catálogo firmado, y la frase del asiento choca con ADR-73.2 | Ninguno en el protocolo | 0,25 | Pista e-CF; reporte en la ola 5 |
| A-18 | Fecha del reemplazo | Aceptar; falta `FechaAutorizacion` en el rango | Ninguno | 0,1 | Pista e-CF |
| A-19 | Cálculo L-1 de los totales | **Aceptar, re-estimado: no son 0,05 sp.** El núcleo hoy calcula el ITBIS **por línea** y no tiene modo «ITBIS incluido» | Ninguno en el protocolo; **cambia lo que cobra la caja (centavos)** | 0,6 (de 0,4 a 1,0) | **Antes del corte**, si cabe en la holgura |
| Prec. ADR-44 p. 2 | Diario SQLite del conector | **Compatible**, con 2 ajustes de redacción | Punto 2 de ADR-108 | — | Con F-6 |
| Prec. ADR-67 p. 2 | Evidencia y XML de origen sistema | **Compatible con cambios** (ver A-12) | Punto 7 de ADR-108 | — | Con F-6 |

**Núcleo de ADR-108, re-estimado por A:** unas **2,4 sp adicionales** a T-29a, b y c de [ECF-E] 7 (de 1,6 a 3,6; inferido), frente a las **0,6** de [HOJA] 6.4. La diferencia sale casi toda de A-19 (+0,55), de A-12 (+0,3, que [HOJA] no contaba), de A-14 (+0,1) y de A-15 y A-17 (+0,2). El sello sigue en 5,0 sp aparte.

**Conclusión para F-6:** con los cambios de la sección 1, A no tiene objeciones de fondo al texto de ADR-108. El arquitecto-maestro de B debe incorporarlos en la revisión 5 de la sección 7 de [HOJA] (lista exacta en la sección 5 de este documento). Después, el propietario puede firmar F-6.

---

## 1. Las seis tareas que bloquean F-6

### A-01 · Clave de idempotencia · **Aceptar con cambios**

**Lo que está bien.** La razón de B es correcta.
- El B de contingencia y su e-CF de reemplazo son **el mismo documento** con dos roles: `fiscal.Comprobante` tiene la PK `(DocumentoId, Rol)` y `CK_Comprobante_Reemplazo` exige rol `R` con prefijo `E` y código 4 (`src/GPOS.Core/Datos/Empresa/Configuracion/FisConfiguracion.cs:97`; [DDL]:1037).
- `doc.Documento.Uid` existe y es global entre nodos (`src/GPOS.Core/Dominio/Numeracion/Documentos.cs:85`).
- Con solo el `Uid`, el reemplazo devolvería el resultado del B.

**El cambio.** La clave queda **`{Uid}:{Rol}:{Generacion}`**. `Generacion` es un `tinyint` de `fiscal.Ecf` que empieza en 1.
- **Problema que resuelve:** la guardia rechaza con `INVALIDA`, un estado final, y [DIS] 6.1 dice «el núcleo corrige y manda **otra clave**». Con `{Uid}:{Rol}` fijo no hay otra clave posible para ese documento: el documento emitido no cambia (ADR-08, ADR-73.4).
- **Cuándo pasa (inferido):** la causa realista de un `Invalido` es de configuración o del generador, no del documento. Por ejemplo, falta `DireccionEmisor`, que es obligatoria (A-07), o hay un defecto del canonizador. Corregirlo cambia los bytes del canónico. Con la misma clave, eso da **409 `CONFLICTO_CONTENIDO` para siempre**.
- **Regla.** El núcleo sube `Generacion` **solo** si la generación anterior terminó en `INVALIDO` o `NoSoportado` **sin ningún intento hacia el proveedor**. El conector rechaza con 409 una generación nueva si alguna anterior del mismo e-NCF llegó al proveedor.
- La llave natural `(RNC, e-NCF)` sigue protegiendo frente a una doble firma.
- **Alternativa descartada:** mantener `{Uid}:{Rol}` y dejar que una clave en `INVALIDA` acepte contenido nuevo. Es igual de segura, pero rompe la regla «misma clave = mismo contenido» y complica la evidencia y el sello, porque habría dos `H_c` bajo una misma clave.

**Efecto en el código actual.**
- `fiscal.Ecf` no existe en el modelo EF: llega con T-29 (`FisConfiguracion.cs:9-10`). Agregar la columna no migra datos.
- El evento de la bandeja publica `{DocumentoId, Ncf, TipoComprobante}` sin el rol (`src/GPOS.Core/Servicios/Modulos/Fiscal/EmisionNcfNg.cs:109-112`). La emisión del reemplazo debe publicar `Rol = R`, y el despachador arma la clave desde `fiscal.Ecf`.
- **Formato:** `Uid` en minúsculas (formato `D`), `:`, `O` o `R`, `:`, y la generación en decimal. Son 40 caracteres como máximo.

### A-02 · `GPOS.Conectores.Contratos` y el canonizador `gpos-jcs-1` · **Aceptar con cambios**

- **El nombre es el firmado** (PA-07 de [H73]). Sustituye a `GPOS.Ecf.Contratos` de [ECF-E] 3.3: ese documento queda superado en ese punto.
- **Dueño: el núcleo (equipo A).** Proyecto `src/GPOS.Conectores.Contratos` en la solución del núcleo, sin referencias a `GPOS.Core` ni a `GPOS.Contracts`. Se publica como paquete NuGet interno con versión semántica, en un *feed* local o en una carpeta compartida (USD 0).
  - Contenido: los DTO del protocolo (superficies `ecf` y `erp`), el OpenAPI, los errores canónicos, el canonizador **único** `gpos-jcs-1` con sus **vectores normativos** y el simulador del núcleo.
- **Cómo aporta B sin editar el árbol del núcleo** (regla de un solo editor por árbol): B ya escribe `gpos-jcs-1` en `b/conector-iq-construccion`. Lo entrega como rama `b/` o como parche contra el núcleo, y A lo integra. Mientras tanto, el borrador sigue en el repositorio de B, como propone [PRE] A-02.
- **Precisión técnica de A:** con todo decimal fiscal como cadena, los únicos números JSON que quedan son enteros pequeños (`tipoEcf`, `NumeroLinea`, `IndicadorFacturacion`). La serialización de números de RFC 8785 deja de ser un riesgo, y el canonizador cabe en unas 200 líneas propias, **sin biblioteca externa**.
- **La parte delicada es el texto:** NFC y el rechazo de controles y de sustitutos aislados, como dice [SEL] HS-04.3. Las bases son `varchar` CP1252 (ADR-50), y el canonizador debe recibir siempre `string` de .NET, nunca bytes CP1252.
- **Con el paquete llega la prueba `NucleoSinProveedoresTests` de 73.7.6.** Hoy no existe en ninguna rama (ADR-73, «Estado de implementación»). Debe comprobar también que el paquete no nombra proveedores.
- **Efecto en el contrato:** ninguno de fondo. Confirma el punto (2) de D-02.

### A-03 · Estado `EN_PROCESO` · **Aceptar**, y agregar `INVALIDO`

**Contraste.**
- El DDL de diseño admite solo `PENDIENTE`, `ENVIADO`, `ACEPTADO`, `CONDICIONADO`, `RECHAZADO` y `CONTINGENCIA` ([DDL]:1027).
- [ECF-E] 3.3 y 3.8 ya proponían `ENVIANDO`, `VERIFICANDO`, `CONFLICTO`, `REEMPLAZADO` y `ANULADO_ANECF`.
- Nada de esto está en el código (`FisConfiguracion.cs:9-10`).

**Lista cerrada que propone A para `fiscal.Ecf.Estado`** (cabe en `varchar(15)`):

| Estado | Significado | ¿Cuenta para la alarma de 72 h? |
|---|---|---|
| `PENDIENTE` | En la bandeja, sin enviar | Sí |
| `ENVIANDO` | Barrera del núcleo | Sí |
| `VERIFICANDO` | Resultado desconocido; solo se sale consultando. Aquí cae también `AGOTADA` del conector, con alerta | Sí |
| **`EN_PROCESO`** | Firmado, con timbre, sin dictamen de la DGII; **la RI con QR se puede imprimir** | No: ya se envió. Tiene seguimiento propio |
| `ACEPTADO`, `CONDICIONADO`, `RECHAZADO` | Finales | — |
| **`INVALIDO`** (nuevo) | La guardia lo rechazó **antes** de salir; el e-NCF no llegó a la DGII. Se corrige con una generación nueva (A-01) | Sí, porque no hay e-CF en la DGII |
| `CONFLICTO` | Revisión humana; nunca se reenvía | Sí |
| `CONTINGENCIA`, `REEMPLAZADO`, `ANULADO_ANECF` | Como en [ECF-E] 3.3 | — |

- **Por qué `INVALIDO` aparte de `RECHAZADO`:** un rechazo de la DGII consume el e-NCF; un `Invalido` de la guardia no. Mezclarlos lleva al ADMIN a hacer una ANECF o una nota que no corresponden.
- **Pendiente operativo (especialista-pos y especialista-contable):** qué se hace si un documento pasa de `EN_PROCESO` a `RECHAZADO` **después** de entregar la RI al cliente. Es el mismo hueco que EC-15 de [ECF-E].
- **Efecto en el contrato:** ninguno. El mapeo de [DIS] 6.2 es correcto; solo se agrega `Invalido` (422) → `INVALIDO`.

### A-11 · Campos del sobre · **Aceptar con cambios**

Se aceptan `perfilCanonico`, `totalDocumento`, `montoTotalNcfModificado`, `finContingencia`, `nombreClienteGenerico`, `lineasPesables`, los decimales como cadena de escala fija y `H_c` sobre todo el sobre salvo `clave`, `prioridad` y `reintento`. Estas son las precisiones:

1. **`totalDocumento`:** es `ventas.Venta.Total` en la moneda del documento (solo DOP en v1) **incluida la propina legal**, porque `MontoTotal` incluye `MontoImpuestoAdicional`. **Por verificar al construir:** que `Total` incluya `CargoServicio` (`src/GPOS.Core/Dominio/Ventas/Ventas.cs:32-33`).
2. **`montoTotalNcfModificado`:** sale de `fiscal.Comprobante.MontoTotal` del comprobante modificado, que es su instantánea (`src/GPOS.Core/Dominio/Fiscal/Comprobantes.cs:104`), y no se recalcula.
3. **`finContingencia`:** sale de `fiscal.Contingencia.Hasta`. El dato ya existe (`Comprobantes.cs:67-69`, con `NotificadaEn`).
4. **`nombreClienteGenerico`:** en el núcleo, el cliente genérico es el **cliente de contado de la caja** (`caja.ClienteContadoId`; `src/GPOS.Core/Consultas/Caja/ConsultasCaja.cs:21-28`), **no uno por empresa** como dicen DF-01 y A-15. El valor es la instantánea `Venta.NombreCliente` cuando `ClienteId` es el de contado de la caja del documento. La guardia lo compara documento por documento, así que no le afecta que haya varios genéricos. Ver la pregunta P-A3.
5. **`lineasPesables`:** `cantidadOriginal` con escala 3 (la de la balanza) y `precioOriginal` con escala 2. Quedan dentro de `H_c`.
6. **Campo nuevo `versionCanonico`** (entero), dentro de `H_c`. Es la versión del **generador del núcleo** (HS-06.2), distinta de `versionContrato` (protocolo) y de `perfilCanonico` (canonizador). Sin él, una auditoría no sabe con qué generador regenerar.
7. **La generación (A-01)** viaja solo en la `clave`, fuera de `H_c`.

Se confirman «sin código 5 en v1» y «sin partición». El núcleo no parte documentos.

### A-13 · Sello de integridad · **Aceptar**, como ADR del núcleo registrado por A

El contenido técnico de [SEL] 6, de [RDP] 9 y de la sección 8 de [HOJA] es sólido, y A lo adopta. Respuesta sobre el registro en la sección 3. Antes del texto, cuatro dependencias que **no** figuran en [HOJA] y que el propietario debe ver, porque condicionan el piloto (DP-04):

| Dependencia | Estado verificado | Efecto |
|---|---|---|
| **Almacén de adjuntos (ADR-67)**, donde se guardan el canónico, el JSON enviado y la respuesta | Decidido, no implementado; bloque 3b-A, **después de unir la ola 4** (ADR-67, encabezado y precisiones del 2026-10-07) | Sin él no hay evidencia: la fase 0 del núcleo y la fase 1 del sello dependen de 3b-A (5,5 sp de A) |
| **`GPOS.Criptografia` y `CifradorAnillo` (H-17 v2)**, para la llave `GPOS.Sello.Ancla` y la ES256 | Decidido, no implementado; el anillo sigue con DPAPI (CLAUDE.md, «Seguridad»; `src/GPOS.Api/Servicios/ProteccionDatos.cs:22-37`, citado en el índice de ADR) | La fase 1 necesita al menos el anillo propio; la completa, además el TPM |
| **RG-14 y PUB-06** (privilegio mínimo del login SQL; `sa` y `gsf`) | Abiertos | «Solo inserción» es defensa en profundidad hasta entonces (I-05 de [HOJA]); no bloquea la fase 1 |
| **Despachador e-CF (T-29c)** con el acuse de la evidencia | No existe | El sello se escribe al pasar a `FINAL` o `EN_PROCESO` |

**Cambios de A al contenido:**
- **La fase 0** (`gpos-jcs-1` con vectores, más la instantánea) **va con A-02 y A-14**, antes de congelar el protocolo v1. Así queda en [HOJA].
- **«Auditar comprobantes fiscales» es un privilegio del catálogo genérico** (grupo Especiales), con la regla I-07 (solo el SUPER lo concede hasta la versión 1 del acceso multiempresa).
- **Las tablas** `fiscal.EcfSello`, `fiscal.SelloLlave` y la de resultados (A propone `fiscal.SelloAuditoria`) **las diseña el arquitecto-datos de A** cuando se construya la fase 1. Ningún documento de B las fija.
- **El sello cubre también la serie B de contingencia** (DP-09), así que no depende de ningún conector. Es genérico y cumple 73.7.

**Esfuerzo:** sin cambio, **5,0 sp de A** (2,4 en la fase 1 y 2,1 en la completa, más 0,5 de la fase 0, con la del conector aparte). Con las dependencias de arriba, la fase 1 **no puede empezar antes de 3b-A y H-17 v2**.

### A-14 · Instantánea fiscal del documento · **Aceptar con cambios**

**Lo que ya existe** (verificado):
- `ventas.Venta` guarda la instantánea del cliente: nombre, identificación, teléfono y correo, y su comentario dice que «no cambia el maestro» (`Ventas.cs:4-6` y `:15-18`).
- `ventas.VentaLinea` guarda `Descripcion`, `Cantidad` y `PrecioUnitario`, con el impuesto por línea y por tasa (`Ventas.cs:78-125`).
- `fiscal.Comprobante` guarda el NCF, la fecha, el vencimiento de la secuencia, el RNC y el nombre del receptor, el NCF modificado, el código de modificación y los totales fiscales (`Comprobantes.cs:79-105`).
- El documento emitido no cambia (ADR-08, ADR-73.4).

**Lo que falta**, inferido del modelo:
- La **instantánea del emisor** (razón social, nombre comercial y `DireccionEmisor`), que hoy sale de la configuración de la empresa y puede cambiar.
- El **tipo de documento del comprador** (RNC, cédula o pasaporte; A-15).
- La marca **«comprador genérico»**.
- La **tasa declarada** por línea, si `VentaLineaImpuesto` no la guarda tal cual. Por verificar.
- **`versionCanonico`.**

**El cambio que propone A:**
1. **La prueba primaria es el canónico guardado**, tal como dice [SEL] HS-06.3. El despachador genera los bytes `gpos-jcs-1` **una vez**, en su propia transacción y apenas se emite el documento, y los guarda como evidencia con `H_c`. Lo demás es comprobación secundaria.
2. **La instantánea adicional va en una tabla pequeña** `fiscal.ComprobanteInstantanea (DocumentoId, Rol, ...)`, escrita **en la transacción del documento**, con los datos del emisor, el tipo de documento del comprador, la marca de genérico y `versionCanonico`. No se copian otra vez las líneas.
3. **La cantidad y el precio derivados de los pesables no se guardan.** Se derivan de forma determinista desde la línea real con el generador versionado (A-08).
4. **Re-instantánea:** solo con una generación nueva (A-01), es decir, cuando nada llegó al proveedor.

- **Esfuerzo:** 0,3 sp (B decía 0,2).
- **Efecto en el contrato:** D-03 queda así: «`H_c` se calcula desde la instantánea; el canónico guardado es la prueba primaria».

---

## 2. Valoración de A-04 a A-10, A-12 y A-15 a A-19

Cada una se contrasta con lo firmado: 73.7, ADR-70, [OLA4], el catálogo de conceptos con `CodigoModificacion` derivado y el código 4 para el reemplazo de contingencia.

| # | ¿Del núcleo? | ¿Choca con algo firmado? | Observaciones de A | sp | Ola |
|---|---|---|---|---|---|
| **A-04** | Sí (instaladores) | No | La API no tiene hoy instalador propio de servicio (en `instalador/` solo está `AgenteImpresion`). Propuesta más simple y estable que publicar un SID: el instalador del núcleo crea el **grupo local `GPOS NG Servicios`** y mete en él la identidad de la API; el MSI del conector da acceso a la tubería a ese grupo. Sobrevive a un cambio de cuenta, y el núcleo no publica nada. Alternativa: la clave de registro de [PRE] | 0,1 | Pista e-CF, con el instalador |
| **A-05** | Sí | No | **Ya está hecho:** `Calculadora.Calcular` reparte el descuento general **por línea** (`src/GPOS.Contracts/Documentos/Calculadora.cs:82-85`). Falta solo que el generador lo exprese en `TablaSubDescuento` | 0,02 | Con A-07 |
| **A-06** | Sí | **No: es un sí.** Lo confirmo | `CK_Ecf_Proveedor` con `'IQSOLUTION'` está en [DDL]:1026 y viola 73.7.4 y V-6. Reemplazo: `ConectorId` con FK a **`integ.Conector`** ([H73] 4.7), **un solo registro** para los conectores de e-CF y ERP, que el conector crea al registrarse (V-6). **No** el `fiscal.ConectorEcf` de [ECF-E] 3.8, que duplicaría el catálogo. Como `fiscal.Ecf` no está construido, es solo un cambio del DDL de diseño. En la misma pasada se corrige el comentario de [DDL]:962-963, que aún dice «código de modificación 3» (fe de erratas pendiente) | 0 | **Ya**, en el documento de diseño (lo hace el arquitecto-datos de A, coordinado con el backend que trabaja en el árbol) |
| **A-07** | Sí | No | Sale de la instantánea (A-14). `NumeroFacturaInterna` es `Documento.Numero` (cabe en 20). `DireccionEmisor` es obligatoria: el núcleo valida que la empresa la tenga **al activar el emisor e-CF**, no en la caja. `GPOS-Perfil` sale de ADR-64. El descubrimiento por la carpeta de registro ([DIS] 12.3) cumple 73.7.3: agregar un conector no cambia el núcleo | 0,3 (dentro de T-29a y T-29c) | Pista e-CF |
| **A-08 v2** | Sí | No | La línea ya guarda la cantidad real (`VentaLinea.Cantidad`), así que el inventario no cambia. Cantidad y precio derivados en el generador versionado. PQ-14 sigue abierta (propietario). RI: UX-01 ya aprobada (opción A) | 0,1 | Pista e-CF |
| **A-09** | Sí | No | `fiscal.Contingencia.Hasta` y `NotificadaEn` ya existen (`Comprobantes.cs:67-69`). Solo faltan la vigilancia de 30 días con alerta a los 20 (en T-29c) y el campo del sobre | 0,05 | Pista e-CF |
| **A-10** | Sí | No; compatible con 73.4 y 73.6 | El reemplazo es el **mismo documento** (rol `R`), así que el ERP no recibe una venta nueva por diseño. Con 73.4 («un mensaje entregado no se reescribe»), la interfaz ERP manda un evento canónico aparte, `ComprobanteReemplazado`, nunca la venta otra vez. La conciliación mensual «B = reemplazos aceptados» es una vista `rpt` | 0,1 | Con X-2, **después del corte** |
| **A-12** | Sí | Compatible con cambios (sección 4) | Detalle en la sección 4.2 | 0,3 | Después de 3b-A |
| **A-15** | Sí | No; cumple la regla de los NCF del 2026-10-02 (el mensaje no sugiere «No generar comprobante») | (1) El genérico es **por caja** (A-11.4). (2) `Venta` tiene `IdentificacionCliente` pero no su **tipo**: falta `TipoIdentificacionCliente char(1)` (R, C o P) en la instantánea. (3) **Umbral de RD$250.000 como parámetro del núcleo** (por omisión 250.000, solo lo cambia el SUPER), porque lo fija la DGII y puede cambiar. (4) La restricción al guardar lee la capacidad `identificadorExtranjero` del conector **emisor de la empresa**, con la última respuesta en caché si el conector no contesta (73.7.5: la caja no se cae por el conector). (5) Rige en la caja y en la oficina | 0,25 (B: 0,15) | Pista e-CF |
| **A-16** | Sí | No | Parámetro por empresa con anulación por sucursal. La propina ya existe como `Venta.CargoServicio` (`Ventas.cs:32`) | 0,05 | Pista e-CF |
| **A-17** | Sí | **Sí, en dos puntos** | **(a) Inventario.** El catálogo firmado dice que solo `DEV` lleva mercancía (código 3) y que `ANU` es «sin mercancía» con código 1 (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla4.cs:51`; `src/GPOS.Core/Servicios/Modulos/Fiscal/ConceptosNota.cs:12-14`). DF-05 pide «E34 código 1 + documento nuevo». Si el documento nuevo descarga inventario, **la mercancía sale dos veces** (la factura original y la nueva). Hace falta decidirlo (P-A2). **(b) ADR-73.2 y 73.3:** «asiento de esa E34 solo por el precio» no es del núcleo, que no hace asientos. La redacción correcta: el núcleo marca la nota como `FueraPlazoFiscal` y el ERP o el contador decide el asiento. **A favor:** la marca de 30 días **ya existe** (MD-46: `Ventas.cs:38-39`; `src/GPOS.Core/Servicios/DocumentosComercialesService.Ventas.cs:71`; `src/GPOS.Core/Servicios/PosService.cs:603`). El aviso y el `IndicadorNotaCredito` deben salir de **esa misma función**, para que no diverjan. El reporte mensual se solapa con HC-03 de la ola 4 (607 con ITBIS 0 y línea «ITBIS de devoluciones sin rebaja fiscal», firmado): es una vista `rpt` sobre la misma marca. La liquidación de la nota sigue ADR-70 sin cambios: saldo a favor o nota `P` consumida en la factura nueva | 0,25 | Flujo y aviso en la pista e-CF; reporte en la **ola 5** (reportes) |
| **A-18** | Sí | No; tampoco choca con HC-02 de [OLA4] | (1) `fiscal.RangoAutorizado` **no tiene fecha de autorización** (`Comprobantes.cs:4-13`): falta `FechaAutorizacion date`, obligatoria en los rangos `E`, para la excepción «secuencia autorizada después del B». (2) Sin choque con el tope de 5 días para fechar hacia atrás (HC-02): el reemplazo es el **mismo documento** con rol `R`, y `Documento.Fecha` no cambia. Solo `fiscal.Comprobante(R).FechaEmision` lleva la fecha del B. Conviene escribirlo como exención expresa en el servicio. (3) Pregunta para el especialista-contable: un B de un período cuyo 607 ya se presentó | 0,1 | Pista e-CF |
| **A-19** | Sí | **Choca con el cálculo actual**, no con una firma. DF-03 (L-1) está firmado y el núcleo debe cumplirlo | Detalle abajo | **0,6** (de 0,4 a 1,0) | **Antes del corte**, si cabe |

**A-19 en detalle.** Esta es la tarea que más cambia la estimación.
- **Hoy:** `Calculadora.Calcular` redondea el ITBIS **por línea** y suma los redondeos por tasa (`Calculadora.cs:86` y `:95`). Es justo la forma que la guardia de B rechaza ([DIS] 4.6: «el ITBIS como suma del ITBIS por línea»). Además, **no tiene modo «ITBIS incluido»**: siempre suma el impuesto encima del precio. Sin embargo, la lista de precios guarda `IncluyeImpuesto` por precio y el resolvedor lo devuelve (`src/GPOS.Core/Servicios/PreciosService.cs:31` y `:118-121`). No verifiqué qué hace la caja con esa marca.
- **Consecuencias:**
  1. Con precios sin ITBIS (indicador 0), `round(Σ base × tasa)` difiere de `Σ round(base × tasa)` en hasta 0,005 por línea. **`MontoTotal` = cobrado y `TotalITBIS` = regla 4 no se cumplen a la vez**, y la guardia rechaza.
  2. Con precios con ITBIS incluido no hay forma de declarar el indicador 1 con L-1.
  3. Un ticket que mezcle precios con y sin ITBIS no cabe en el **único** `IndicadorMontoGravado` del documento (RF-02).
- **Lo que hay que tocar:**
  - `Calculadora` (en `GPOS.Contracts`, compartida por la caja, la oficina, las compras, la impresión y la Web: 15 archivos la usan);
  - los disparadores de emisión CA-10 a CA-12, que comprueban el cuadre en el motor (`src/GPOS.Core/Servicios/Nucleo/VentasNg.cs:18-22`);
  - las pruebas.
- **También hay `Math.Round` sin modo** (redondeo bancario, contra la regla de L-1) en `PosService.cs:342` y `:349`, `CobrosService.cs:236` y `CierresCajaService.cs:287`. No son del e-CF, pero entran en la misma pasada.
- **Por qué antes del corte:** es la regla de cobro de la caja. Cambiarla después del corte deja dos reglas en la historia. GPOS NG no tiene clientes, así que hoy no hay nada que migrar. Depende de **P-A1** (PQ-05).

---

## 3. ADR del sello de integridad: quién lo registra y con qué número

**Recomendación: lo registra el equipo A como ADR-74**, el primero libre de su rango. Verificado: 74 a 99 están libres en `origin/master` ([README de ADR]: «74 a 99 · Libres para el equipo A»), y ningún documento de las dos ramas cita ADR-74 a 79.

**Por qué A y no B (ADR-109):**
1. **Es una decisión del núcleo:** tablas `fiscal.*`, `GPOS.Criptografia`, una ventana del núcleo y el ancla por correo. La construye A (5,0 sp) y vale para cualquier conector y para la serie B (DP-09). La numeración por rangos identifica al equipo dueño. Un 109 de B diría que es de B.
2. **ADR-108 es de B y precisa ADR existentes del núcleo** (44, 51 y 67). Que además el sello naciera con número de B mezclaría el dueño.
3. **Alternativa descartada:** ADR-109 de B con la nota «construye A». Funciona, pero deja el ADR y su mantenimiento en el equipo que no lo construye.

**Cómo se hace:**
- El arquitecto-maestro de A redacta el ADR-74 (estado Propuesto) a partir de la sección 8 de [HOJA], [SEL] 6, [RDP] 9 y [DEC] (DP-08 a DP-15, DP-10 v3, DP-11 precisada y K-04: el CLI lo corre GSF), con las cuatro dependencias de A-13.
- SI-01 (F-10) está firmado **en principio**. El **texto** del ADR-74 necesita su propia firma.
- Se registra en `master` después de la firma, como manda la regla del 2026-10-06.
- **ADR-108 cita el sello como «ADR-74 (Propuesto)»** en «Relacionado», en lugar de «decisión candidata, sin número».

---

## 4. Precisiones que trae ADR-108 a ADR-44 y ADR-67

### 4.1 ADR-44, punto 2 (diario SQLite del conector) · **Compatible**, con 2 ajustes de redacción

- **Por qué es compatible:** ADR-44.2 reserva la base embebida a la configuración para que los datos del negocio estén en SQL Server (`docs/adr/ADR-044.md:11`). El diario **no es fuente de verdad**: el núcleo reenvía por clave y el conector consulta ([DIS] 7.2). Va cifrado (cumple 44.3, sin texto plano) y es transitorio. Hay precedente acotado: la base SQLite de la sucursal en línea (P-2 de ADR-53).
- **Ajuste 1.** La frase de [DIS] 7.2 «retención máxima de 90 días» contradice «ningún cuerpo se purga sin acuse», que puede retenerlo más. Manda el texto de [HOJA] 7, punto 2 («30 días, máximo 90, y solo después del acuse»), y [DIS] debe alinearse: «90 días **después del acuse**; sin acuse se conserva y alerta».
- **Ajuste 2.** Escribir en ADR-108 que **no precisa ADR-54**. ADR-54 fija el motor de `GPOS_SYSDATA`, las centrales y los nodos (ADR-54, punto 1). El diario es una cola interna de un complemento, no una base de GPOS NG. Sin esa frase, alguien leerá «SQLite» como una segunda base del producto, que es justo lo que P-2 de ADR-53 tuvo que precisar.

### 4.2 ADR-67, punto 2 (evidencia y XML de origen sistema) · **Compatible con cambios**

**Por qué es compatible:**
- ADR-67.2 limita el contenido a PDF, JPEG, PNG, TIFF y HEIC/HEIF **porque los sube un usuario**. Un archivo que solo escribe el sistema, nunca un usuario, no tiene ese riesgo.
- La marca de soporte fiscal sin papelera ya está firmada (precisión B-3 de ADR-73), y la pone el sistema (PC-3b-03).
- El ancla «documento emitido o anulado» se cumple.

**Los cambios, contrastados con el modelo de adjuntos:**
1. **Nombre de la columna.** `doc.Adjunto` ya tiene **`Proveedor char(1)`** para el *proveedor de almacenamiento* (D disco; G, O y X reservados para la nube) ([ADJ-D], DDL de `doc.Adjunto`). Un `Origen = PROVEEDOR` se leería como lo mismo. A propone **`OrigenContenido char(1)`**: `U` usuario (por omisión), `S` sistema y `P` proveedor externo (el XML de IQ). La regla es igual a la de [HOJA]; solo cambian el nombre y la codificación.
2. **`CK_Adjunto_Tipo`** admite `JSON` y `XML` **solo** con `OrigenContenido <> 'U'`. La validación es la de [DIS] 9: JSON estricto, y XML sin DTD ni entidades externas.
3. **`SubidoPorId` y `SubidoPor` son `NOT NULL`:** se usa el usuario técnico `SISTEMA`, que ya aparece como autor en las siembras de [ADJ-D].
4. **Cuota por empresa, tope diario por usuario y 20 archivos por ancla** (ADR-67.2) **no aplican al origen `S` o `P`.** Con 8 intentos (hasta 20 con `maximoIntentos`), un documento puede pasar de 20 archivos. El volumen (de 22 a 36 GB en 10 años por empresa) agotaría la cuota, y un rechazo por cuota **perdería evidencia fiscal**. Se cuenta aparte y alerta, sin rechazar.
5. **Desmarcado del soporte fiscal (PC-3b-04, firmado):** el Contador, el ADMIN o el SUPER pueden quitar la marca. **No debe alcanzar al origen `S` o `P`**: sería una puerta para borrar evidencia que sostiene el sello. Tampoco el estado `R` («Sustituido por error»). La desvinculación del punto 12 (después del piso de 10 años) sí aplica, y la lápida conserva la huella que el sello verifica.
6. **La tabla de referencia** `fiscal.EcfArchivo (DocumentoId, Rol, Generacion, Clase [C canónico, J enviado, R respuesta, X XML], Intento, AdjuntoId, Sha256)` **sustituye** a `fiscal.EcfXml` con `varbinary(max)` ([DDL]:1054-1061), como ya pedía [ECF-E] 3.8.

**Dependencia:** ADR-67 no existe en el código. Se construye en 3b-A, después de unir la ola 4. Hasta entonces, la evidencia no tiene dónde guardarse (ver A-13).

---

## 5. Cambios concretos al texto de ADR-108 (sección 7 de [HOJA]) para la revisión 5

1. **Encabezado:**
   - en «Relacionado», sustituir «la decisión candidata "Sello de integridad…" (núcleo, sin número)» por «**ADR-74** (sello de integridad de comprobantes fiscales, Propuesto)»;
   - agregar «Diseño del núcleo: `docs/integraciones/2026-10-07-ecf-enchufable.md` (superado en el nombre del paquete y en el código de reemplazo)».
2. **Punto 2:**
   - «Clave `{Uid}:{Rol}:{Generacion}`; una generación nueva solo si la anterior no llegó al proveedor»;
   - «perfil `gpos-jcs-1`, con implementación única en `GPOS.Conectores.Contratos`, paquete del núcleo»;
   - «`H_c`, calculado desde la instantánea; **el canónico guardado es la prueba primaria**»;
   - en la precisión de ADR-44: «retiene los cuerpos de 7 a 90 días **contados desde el acuse**; sin acuse, los conserva y alerta» y «**no precisa ADR-54**: el diario no es una base de GPOS NG».
3. **Punto 4 o «Qué rompe»:** agregar que el núcleo suma los estados **`EN_PROCESO` e `INVALIDO`** y que **el cálculo de los totales de venta del núcleo pasa a L-1** (un redondeo por tasa). Puede cambiar en centavos lo que cobra la caja frente al cálculo por línea actual. Nada que migrar, porque no hay clientes.
4. **Punto 7, precisión de ADR-67:** sustituir «`Origen = SISTEMA` / `PROVEEDOR`» por «`OrigenContenido` `S` (sistema) o `P` (proveedor externo)». Agregar: «fuera de la cuota, del tope diario y del límite por ancla; no se desmarca como soporte fiscal ni pasa a "Sustituido por error"».
5. **Consecuencias:** «unas **2,4** semanas-persona en el núcleo (de 1,6 a 3,6), además de T-29 y del sello (ADR-74)», en lugar de 0,6. Agregar: «la evidencia depende de la construcción de ADR-67 (bloque 3b-A)».
6. **Sin cambios** en los puntos 1, 3 (salvo la cita de L-1), 5, 6 y 8.

---

## 6. Calendario, sin mover el corte del 2026-12-02

[OLA4]:136-139 declara más de 4 semanas de holgura para la ola 5. Todo lo que sigue es inferido (±50 %).

| Momento | Qué | sp de A |
|---|---|---|
| **Ya** (documento, sin código) | A-06 en el DDL de diseño, con la fe de erratas de [DDL]:963; respuesta de este documento | 0 |
| **Pista e-CF del núcleo, después de unir la ola 4 y en paralelo con la ola 5** | **A-19 con la decisión P-A1** (primero, porque toca la caja); A-02 y A-14 (fase 0, antes de congelar el protocolo v1); T-29a, b y c con A-01, A-03, A-07, A-09, A-11, A-15, A-16, A-17 (flujo y aviso) y A-18; A-04 con los instaladores | ~2,0 más T-29a a c (2,6) |
| **3b-A** (ya planificado después de la ola 4) | ADR-67, base de A-12 | (5,5, ya contadas en la ola 3b) |
| **Ola 5** | Reporte «Notas de crédito con más de 30 días» (A-17), sobre la marca de MD-46 | 0,05 |
| **Después del corte, antes del piloto** | A-12 sobre el almacén ya construido; fase 1 del sello (ADR-74; necesita H-17 v2); A-10 con X-2 | 2,4 + 0,4 |
| **Antes de la producción general** | Fase completa del sello | 2,1 |

**Regla si no cabe:** se difiere primero lo que solo hace falta para el piloto (A-10, A-12 y la fase 1), **nunca el corte**. A-19 es la única tarea que conviene hacer antes del corte, por ser regla de cobro. Si no cabe, se hace antes del primer cliente: EC-01 ya dice que ningún cliente se implanta sin e-CF.

---

## 7. Preguntas para el propietario

| # | Pregunta | Recomendación de A | Alternativa descartada |
|---|---|---|---|
| **P-A1** (cierra PQ-05 y desbloquea A-19) | ¿Los precios de la caja llevan el ITBIS incluido? ¿Lo decide cada empresa? | **Un parámetro por empresa, «Precios con ITBIS incluido»**, que fija el **modo de cada documento** (el `IndicadorMontoGravado` es uno por documento). Un precio de lista con el otro modo se convierte al entrar en la línea. En los dos modos, el ITBIS se calcula **por tasa sobre la suma** (L-1), y la caja puede cobrar algún centavo distinto del cálculo por línea actual | Mantener el cálculo por línea: incumple DF-03, ya firmado, y la guardia rechaza. Un modo por línea: la DGII no lo admite |
| **P-A2** (A-17) | En el «Cambiar tipo de comprobante» (E34 con `ANU` más documento nuevo), ¿qué pasa con el inventario? | **El documento nuevo es una refacturación que no mueve inventario**: queda ligado al original, con sus mismas líneas, y la E34 `ANU` sigue sin mercancía, como en el catálogo firmado. Físicamente no se movió nada, así que el kárdex no debe mostrar movimientos | Usar `DEV`, que tiene mercancía pero código 3, no 1, y movería el promedio dos veces. Abrir `ANU` con mercancía: cambia el catálogo firmado el 2026-10-07 |
| **P-A3** (A-11.4 y A-15) | El «cliente genérico» del núcleo es el **cliente de contado de cada caja**, no uno por empresa. Si el cajero escribió un nombre en una E32 de menos de RD$250.000 sin documento, ¿qué va en `RazonSocialComprador`? | **El nombre del cliente de contado de la caja** (DF-01 en su versión final). El nombre que escribió el cajero queda en el documento y en la RI | El nombre que escribió el cajero (DF-01 en su primera versión): la guardia lo rechazaría por no ser el genérico |
| **P-A4** | ¿Registra A el sello como **ADR-74**? | Sí (sección 3) | ADR-109 de B |
| **P-A5** | ¿Aprueba la clave `{Uid}:{Rol}:{Generacion}`? | Sí (A-01) | `{Uid}:{Rol}` con contenido sustituible en `INVALIDA` |
| **P-A6** | ¿El umbral de RD$250.000 es un parámetro del núcleo (por omisión 250.000, solo lo cambia el SUPER)? | Sí: lo fija la DGII y puede cambiar sin una versión nueva | Constante en el código |
| **P-A7** | ¿Se hace A-19 antes del corte? | Sí, si cabe en la holgura; si no, antes del primer cliente | Después del corte, que deja dos reglas de cobro en la historia |

---

## 8. Lo que necesitan los especialistas

**Especialista-contable**
1. **L-1 con indicador 0** (precios sin ITBIS): confirmar que la DGII acepta el ITBIS **por tasa sobre la suma**, y no línea por línea, sin «Aceptado Condicional» (A-19).
2. **Refacturación sin inventario** en el cambio de tipo (P-A2): ¿algún efecto fiscal? También, si la E34 `ANU` a más de 30 días se informa en el 607 con ITBIS 0, como HC-03.
3. **Reemplazo de un B de un período ya declarado** (el 607 presentado): ¿cómo se informa el e-CF de reemplazo? (A-18; período fiscal declarado de HC-02).
4. **`EN_PROCESO` que termina en `RECHAZADO`** con la RI ya entregada: ¿qué documento corrige? (A-03; EC-15).
5. **Devolución total con `DEV`:** el catálogo deriva el código 3 (corrige montos). ¿Acepta la DGII el 3 para una devolución que deja el comprobante en cero, o exige el 1?
6. **Redacción de A-17:** el efecto de la nota a más de 30 días es un dato para el ERP o el contador, no un asiento de GPOS NG (ADR-73.2).

**Especialista-pos**
1. La RI con QR en **`EN_PROCESO`**, y qué ve el cajero si después se rechaza.
2. Dónde vive el flujo «Cambiar tipo de comprobante» (caja u oficina), quién lo autoriza y cómo se muestra la refacturación (P-A2).
3. El **cliente de contado por caja** como genérico del e-CF, y qué hacer con el nombre que escribe el cajero (P-A3).
4. El efecto de L-1 en el ticket: centavos frente al cálculo actual y cómo se muestra el ITBIS por línea (P-A1).

---

## 9. Hallazgos colaterales (no bloquean)

- **Fe de erratas del código 4 sin aplicar** en `feature/modelo-ng`. Quedan el comentario de [DDL]:962-963 y [ECF-E]:234, :293 y :563, que siguen diciendo «código 3». [OLA4]:410-416 lo encargó. El código ya está corregido (`FisConfiguracion.cs:96-97`). Para el documentador técnico.
- **[HOJA] 5 (F-6)** condiciona la firma a «A-01, A-02, A-03, A-11, A-13 a A-15», y el aviso a «A-01, A-02, A-03, A-11, A-13 y A-14». A-15 no bloquea el texto (DF-01 ya está firmado), pero B debería unificar la lista en la revisión 5.
- **`Math.Round` sin modo**, que redondea al par, en `PosService.cs:342` y `:349`, `CobrosService.cs:236` y `CierresCajaService.cs:287`. Se corrigen con A-19.

---

## Supuestos

- [DEC] es el registro fiel de lo firmado. La revisión 4 de [HOJA] y la revisión 3 de [DIS] son las vigentes en `origin/b/conector-iq-diseno`.
- Lo que digo de la caja sobre `IncluyeImpuesto` es inferido: vi la marca en el resolvedor de precios, pero no cómo la usa la caja.
- Que `Venta.Total` incluya `CargoServicio`, y que `VentaLineaImpuesto` guarde la tasa declarada, está **por verificar** al construir.
- Todas las cifras de esfuerzo son inferidas (±50 %). La holgura del calendario es la que declara [OLA4]:136-139.
- 74 es el primer número libre del rango de A en `origin/master` (`c4aff09`) a la fecha.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\respuestas-A-conector-iq-2026-10-07.md`
- Supuestos: los de la sección «Supuestos»
- Decisiones candidatas a ADR:
  - ADR-74, sello de integridad de comprobantes fiscales (núcleo, A; alternativa descartada: ADR-109 de B);
  - en ADR-108: clave `{Uid}:{Rol}:{Generacion}` (alternativa descartada: contenido sustituible en `INVALIDA`), estado `INVALIDO`, `OrigenContenido` en lugar de `Origen` (alternativa descartada: reutilizar `Proveedor`), precisión de ADR-44 sin precisar ADR-54;
  - modo de precios por empresa con L-1 por tasa (P-A1);
  - refacturación sin inventario en el cambio de tipo (P-A2).
- Entregas a otros agentes:
  - arquitecto-maestro de B: revisión 5 de [HOJA] con la sección 5 de este documento;
  - arquitecto-maestro de A: redactar ADR-74;
  - arquitecto-datos de A: A-06 en el DDL de diseño, `fiscal.Ecf` (estados, `Generacion`, `ConectorId`), `fiscal.ComprobanteInstantanea`, `fiscal.EcfArchivo`, `OrigenContenido` en `doc.Adjunto`, `FechaAutorizacion` en `fiscal.RangoAutorizado`, `TipoIdentificacionCliente`;
  - especialista-contable y especialista-pos: sección 8;
  - documentador-tecnico: fe de erratas del código 4 pendiente;
  - arquitecto-integraciones de B: alinear [DIS] 7.2 (retención) y 6.1 (`INVALIDA` → generación).
- Próximo paso recomendado: que el propietario responda P-A1 a P-A7 (sobre todo P-A1 y P-A2) y que B emita la revisión 5 de [HOJA] para firmar F-6.
