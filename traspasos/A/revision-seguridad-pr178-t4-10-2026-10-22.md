[Informe de Seguridad] Revisión de cierre del PR #178 (T4-10: vistas `imp` y DD-11 con sello) · equipo A · 2026-10-22

- **Objeto:** `docs/datos/2026-10-22-t4-10-vistas-imp.md`, rama `origin/b/datos-t4-10`, punta `bad7714b` (1291 líneas, revisión 3). Se leyó con `git show`, sin cambiar de rama ni compilar.
- **Contraste:** diseño del sello de A (`traspasos/A/diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`) y código de `origin/feature/modelo-ng` `dedc62ec` (el documento cita `2fa6843b` y `dedc62ec`), leído con `git show` y `git grep`. Esquema: `database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql` (en adelante **[ESQ]**).
- **Marcas:** [V] = verificado por lectura (las líneas «doc:NNN» son del documento del PR); [I] = inferido.
- **Naturaleza:** es una recomendación técnica. La decisión es del propietario (C2).

## Resumen y recomendación

El documento incorpora bien lo firmado. El sello es un HMAC calculado en la API de reportes, con `Huella binary(33)`, guardado en dos pasos y falla cerrada. S-02 tiene su CHECK y la comprobación 51641. C-1′ queda en el patrón de tres columnas crudas, con S-04 y S-05. C-2′ parte el cuadre por `Tipo` en dos juegos de vistas. La DDL no usa `SELECT *`, ni SQL dinámico, ni dependencias de tres partes. Los permisos de `imp` (`GRANT` a `gpos_lectura`, `DENY` a `gpos_reportes`) son los vigentes y se verificaron. No hay choques de EventId ni de códigos de error.

Queda **un hallazgo Alto**. C-2′ se aplica en la ruta de impresión, pero el servidor ya entrega los montos del X por las rutas JSON de `/cierres` a quien solo tiene `cierrex`. Así, cumplir C-2′ en el impreso no protege lo que C-2′ quiere proteger (S178-01). Hay además tres hallazgos Medios: la regla de `otp` de la ruta de sellado puede fallar abierta; no se puede revocar un sello concreto y el sello no está atado a la empresa; y el conteo a ciegas se expone sin privilegio.

**Recomendación: Rechazar en la forma actual.** El arreglo es barato: unas 0,1 dp de texto en el documento y unas 0,3 a 0,5 dp de construcción. Con S178-01 incorporado en la sección 2.3, las pruebas 21 y la sección 12, pasaría a **Aprobar con condiciones**. Las condiciones serían S178-02, S178-03 y S178-04, resueltas en el texto o aceptadas por el propietario, antes de construir.

## 1. Alcance y superficie revisada

- **DDL de la sección 7:** P1 (esquema), P2 (DD-11 y S-02), las 45 vistas, P0 (51639 y 51640), P3 (permisos) y P4 (huella del contrato).
- **Sello:** secciones 3.1 y 3.2, contra el diseño de A.
- **Identificación:** sección 3.3 y las vistas de venta, compra, constancia y caja chica.
- **Cierre X/Z:** sección 2.3, 9.2 y pruebas 9 y 21, contra las rutas reales de `ImpresionEndpoints.cs` y `EfectivoEndpoints.cs`.
- **Copia y bitácora:** sección 5 (P-03 y P-08).
- **Retención:** sección 8.
- **EventId y errores SQL:** sección 0.5, contra todas las ramas remotas.
- **Superficie expuesta:**
  - lectura de `imp` con la credencial `gpos_lec_*` desde la API de reportes, para los documentos de todas las empresas del sitio;
  - la ruta nueva `POST /api/impresion/formatos/sello`, solo para el SUPER;
  - las rutas de impresión del cierre, la reimpresión y el correo de la principal;
  - las rutas JSON de `/api/efectivo/cierres`.

## 2. Tabla resumen

| ID | Severidad | Título |
|---|---|---|
| S178-01 | **Alta** | C-2′ se evade por las rutas JSON de `/cierres`: el cajero con solo `cierrex` recibe los montos del X sin `vercuadrecaja` |
| S178-02 | **Media** | La regla de `otp` y de autenticación reciente de la ruta de sellado puede fallar abierta (se remite a `SinFactorExigido`, que depende de `ExigeOtpSuper`) |
| S178-03 | **Media** | No se puede revocar un sello concreto, y el sello no está atado a la empresa: se puede repetir y trasplantar un Razor ya sellado |
| S178-04 | **Media** | `imp.ConteoLinea` entrega `ExistenciaCorte` y `Diferencia` sin privilegio, lo que anula el conteo a ciegas (S-10 aplazado) |
| S178-05 | Baja | En la compra y la constancia, la identificación sale del maestro vigente y no del documento: al reimprimir puede salir completa otra cédula |
| S178-06 | Baja | `DEV` está en dos vistas de encabezado (`imp.Ticket` e `imp.DocumentoVenta`): la partición «un tipo, una vista» no se cumple |
| S178-07 | Baja | 51639 se usa en dos comprobaciones distintas, y la franja 51639 a 51644 de `imp` no está anotada en ADR-82 |
| S178-08 | Baja | EventId: los nombres no coinciden con el diseño de A, y hay un choque previo, ajeno a T4-10, en la franja reservada al instalador |
| S178-09 | Baja | Diferencias de detalle con el diseño de A: `Papel`, sello pedido antes de escribir, fila inerte frente a «siempre un predeterminado» y primera generación de la llave |
| S178-10 | Baja | La ruta de impresión del cierre de la principal no comprueba la sucursal, y registra la copia antes de la barrera de la API de reportes |
| S178-11 | Baja | Retención (Ley 172-13): no está definida para las líneas nuevas de bitácora; S-03 (tope de reimpresión) queda como recomendación; textos libres sin enmascarar |
| S178-12 | Baja | 51640 solo niega los esquemas de vistas: no hay una lista blanca de los esquemas de tablas que puede leer `imp` |

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Falla parcial**: S178-01 (Alta) y S178-10. El privilegio por vista es solo de la aplicación: la base no lo exige (residual ya aceptado; ver 5) |
| A02 Criptografía | Correcta en lo esencial: HMAC-SHA256 con subllave HKDF, `FixedTimeEquals` y llave fuera de la base. Observaciones S178-03 y S178-09 |
| A03 Inyección | Sin hallazgos. Vistas estáticas; el SQL dinámico de P3 usa `QUOTENAME` [V] `PermisosLecturaReportes.cs:59-66`; `GeneradorRazor` codifica en HTML y escapa la arroba [V] `GeneradorRazor.cs:152` |
| A04 Diseño inseguro | S178-03 y S178-04 |
| A05 Configuración | S178-02 (el `otp` depende de un indicador) |
| A06 Componentes vulnerables | No aplica: no se agregan paquetes |
| A07 Autenticación | S178-02 |
| A08 Integridad | Sello correcto, con S178-03 |
| A09 Registro y monitoreo | Eventos sin la plantilla ni montos (correcto). S178-08 y S178-11 |
| A10 SSRF | No aplica: la ruta de sellado no hace peticiones salientes |

## 4. Hallazgos

### S178-01 · Alta · C-2′ se evade por las rutas JSON de `/cierres`

- **Evidencia:**
  - [V] doc:175-179: C-2′ se aplica en el servidor solo en la ruta de impresión del cierre, la reimpresión y el correo.
  - [V] `src/GPOS.Api/Endpoints/EfectivoEndpoints.cs:72`: el grupo `/cierres` admite `cierrex` **o** `movcajas`.
  - [V] `:80` `POST /cierres/x`, sin más permiso, devuelve `CuadreCajaDto`.
  - [V] `:76-79` `GET /cierres/{numero}` lo devuelve completo al cajero de su propio turno.
  - [V] `src/GPOS.Core/Servicios/CierresCajaService.cs:74-94` (`CierreXAsync` devuelve `r`, con todos los montos) y `:155-167` (`CierreAsync` deserializa el `Detalle` completo).
  - [V] `:185-186`: la lista `GET /cierres/` muestra `TotalVentas` y «dif. N2».
  - [V] `src/GPOS.Contracts/Efectivo/Efectivo.cs:236` y siguientes: el DTO lleva ventas, esperado, declarado y diferencia.
  - [V] `Permisos.cs:137` y `:284`: `vercuadrecaja` es «Ver el cuadre de caja (esperado, declarado y diferencia)».
- **Riesgo:** fraude en caja. El cajero con `cierrex` y sin `vercuadrecaja` hace un X a media jornada (o lee uno anterior) y obtiene el efectivo esperado y la diferencia. Con ese dato ajusta lo que declara en el Z y retira el sobrante sin que salga una diferencia. Es justo lo que el cuadre a ciegas y C-2′ quieren impedir. Que la impresión dé 403 no cambia nada si la misma respuesta JSON trae los montos.
- **Remediación:**
  1. Agregar a la sección 2.3 y a la entrega del desarrollador-backend un requisito. Sin `vercuadrecaja`, `POST /cierres/x`, `GET /cierres/{numero}` (cuando el cierre es un X) y la lista de `GET /cierres/` responden **sin montos**: solo número, caja, cajero, fechas, cantidades y folios. Basta con proyectar un DTO reducido y quitar `TotalVentas` y «dif.» de la lista.
  2. La denegación deja una línea en la bitácora, como en la impresión.
  3. Para el Z, `POST /z` ya exige `movcajas`, coherente con la regla del Z del chat. `GET /cierres/{numero}` de un Z por el cajero de su propio turno debe seguir la misma regla: montos solo con `movcajas`.
  4. Pruebas: ampliar la prueba 21 con estas tres rutas.
  5. Costo: unas 0,3 a 0,5 dp.
- **Defensa en profundidad:** la pantalla oculta los montos, pero el control real es el servidor.
- **Nota:** si el propietario entendía C-2′ solo para el impreso, debe decirlo de forma explícita. En ese caso, el control de C-2′ queda sin efecto práctico, y conviene que lo firme sabiéndolo.

### S178-02 · Media · `otp` y autenticación reciente en la ruta de sellado pueden fallar abiertos

- **Evidencia:**
  - [V] doc:243: la ruta exige «`otp` … [V] `AutenticacionIntrospeccion.cs:110-115`».
  - [V] esas líneas definen `SinFactorExigido`, que solo rechaza si la principal manda `ExigeOtpSuper: true`. Su comentario dice: «Una principal anterior no manda `ExigeOtpSuper`: false, no rechaza nada».
  - [V] el diseño de A, 3.3, pide `otp` **sin depender** de ese indicador, salvo una configuración de desarrollo explícita que quede registrada al arrancar. El documento no recoge esa condición.
  - [V] `auth_time` aparece en `AuthEndpoints.cs:49`, `:300` y `Program.cs:394`. Que la introspección v1 lo devuelva es [I] (doc:1269), y el documento no dice qué pasa si falta.
- **Riesgo:** sellar equivale a autorizar C# en el proceso que abre los sobres de todas las empresas (doc:215). Si una principal mal configurada, o una versión antigua, no manda `ExigeOtpSuper`, la ruta sellaría con una sesión de SUPER sin segundo factor. Si `auth_time` falta y la comprobación se salta, una sesión desatendida de SUPER también podría sellar.
- **Remediación:** escribir en 3.2, paso 2:
  - la ruta exige `amr` con `otp` **siempre**, sin usar `SinFactorExigido`;
  - la falta de `auth_time` o un `auth_time` de más de 5 minutos responden 403 (`SELLO_AUTENTICACION_ANTIGUA`);
  - la excepción de desarrollo solo existe con una opción explícita, que registra un evento al arrancar.
  - Agregar a la prueba 15: «principal sin `ExigeOtpSuper` → no sella» y «token sin `auth_time` → no sella».
  - Costo: unas 0,1 dp.

### S178-03 · Media · No hay revocación de un sello, ni atadura a la empresa

- **Evidencia:**
  - [V] doc:213: la repetición (R-SELLO-1 de A) se acepta como Baja y no se agrega `Revision`.
  - [V] doc:217-226: el mensaje cubre `Id`, `TipoDocumento`, `Modo`, `Papel` y `Plantilla`, sin nada de la empresa ni de la base.
  - [V] doc:237: hay una llave por instalación de la API de reportes, que sirve a **todas** las empresas del sitio (doc:215).
- **Riesgo:**
  1. **Revocación.** Un SUPER descubre que un Razor sellado es dañino (por ejemplo, saca datos que no debía o escribe archivos) y lo reemplaza. Quien pueda escribir en `conf.FormatoImpresion` (por la credencial `gpos_app` filtrada, como DBA o por la bajada de configuración, doc:215) puede restituir el trío anterior `Plantilla` y `Huella`, que sigue verificando. Hoy la única forma de revocarlo es rotar la llave del sitio, y el documento no lo dice.
  2. **Trasplante entre empresas.** Los `Id` son identidades por base, así que `Id = 1` existe en todas. Un Razor sellado en la empresa A se puede copiar a la fila del mismo `Id` y el mismo tipo en la base de la empresa B, y verifica.
  - El código fue autorizado por un SUPER alguna vez, por eso el riesgo es Medio y no Alto. Pero lo acepta un equipo, no el propietario.
- **Remediación (la más barata primero):**
  1. Incluir en el mensaje la **empresa que conoce la API de reportes por el contexto de la petición**, no la que viene de la base (por ejemplo, `uint16 BE + ASCII(códigoEmpresa)`). Así se cierra el trasplante. Costo: menos de 0,1 dp.
  2. Documentar como procedimiento que **revocar un Razor = rotar `Kid`** y volver a sellar los válidos (son decenas de filas).
  3. Agregar `Revision int` **dentro del mensaje**, con `imp.Formato` entregándola, para la auditoría que propone A.
  4. Que el propietario firme el riesgo residual de repetición o pida un mínimo de revisión por `(empresa, Id)` guardado en el anillo de la API de reportes. Eso es un archivo propio, no una escritura en la base, así que no rompe ADR-109 [I: confirmar con el arquitecto-software].

### S178-04 · Media · Conteo a ciegas expuesto sin privilegio

- **Evidencia:**
  - [V] doc:730-737: `imp.ConteoLinea` entrega `l.ExistenciaCorte` y `l.Diferencia`, sin privilegio de vista.
  - [V] doc:1288: el conteo a ciegas (S-10) se entrega al especialista-pos, sin regla en la DDL.
  - Solo el costo va aparte (`imp.ConteoLineaCosto`, doc:739-744).
- **Riesgo:** fraude de inventario. Si la hoja de conteo se imprime durante la captura, el contador ve la existencia esperada y anota esa cifra. Así se tapan faltantes (robo hormiga) y se anula el control del conteo ciego.
- **Remediación:** la más barata es que la vista entregue `ExistenciaCorte` y `Diferencia` solo cuando la captura está cerrada. Por ejemplo, unir `inv.Conteo` y `CASE WHEN c.CapturaCerradaEn IS NOT NULL THEN … END`, que falla cerrado. La alternativa es moverlas a una vista con privilegio. Agregar una prueba. Costo: unas 0,1 dp. Si el especialista-pos confirma que el CNT nunca se imprime antes del cierre de la captura, baja a Baja, pero la regla en la vista sigue siendo la defensa.

### S178-05 · Baja · Compra y constancia: identificación del maestro vigente

- **Evidencia:** [V] doc:607-631 y 785-804: la identificación sale de `cat.Suplidor`, sin copia en el documento (doc:289). Para la venta, S-04 exigió la identificación del documento (doc:26).
- **Riesgo:** si el maestro cambia después de emitir, una reimpresión de una FCP con comprobante `11`/`41` o de una constancia imprime **completa** la cédula de otra persona, en un documento fiscal.
- **Remediación:** tomar la identificación del comprobante, si `fiscal.Comprobante` del documento la guarda [I], o dejar como entrega al arquitecto-datos que se guarde una copia en `compras.Compra`. Mientras tanto, documentarlo como residual.

### S178-06 · Baja · `DEV` en dos vistas de encabezado

- **Evidencia:** [V] doc:443 (`imp.Ticket`: `FPOS`, `DEV`) y doc:485 (`imp.DocumentoVenta`: `COT`, `PED`, `FAC`, `DEV`). Las pruebas 3 y la última de 9.2.3 suponen una partición exclusiva.
- **Riesgo:** quien tiene el permiso de `TicketPos` puede leer una devolución de crédito por la vista del ticket, y al revés, si los permisos de `TiposFormato` difieren. Es poco probable (los dos son ventas), pero rompe la defensa que la sección 2.3 declara.
- **Remediación:** un discriminador explícito en cada vista (por ejemplo, `v.CajaId IS NOT NULL` en el ticket) y una prueba de que ningún `DocumentoId` aparece en dos encabezados.

### S178-07 · Baja · Códigos de error

- **Evidencia:**
  - [V] doc:352-353 (P1) y doc:1066-1069 (P0): las dos usan **51639**, con mensajes distintos.
  - [V] ADR-82 en `master`, líneas 216 y 222: anota 51619 a 51625 (D0) y 51626 (D1), con reserva hasta **51638** para DB-7. **No** anota 51639 a 51644 para `imp`.
  - [V] `git grep` en todas las ramas remotas: 51639 a 51644 no se usa fuera de los documentos de `imp`. **No hay choque con D1/ADR-161** (la franja de D1 acaba en 51638).
- **Remediación:** usar 51642 para P1, o dejar dicho que 51639 cubre «propiedad y contenido de `imp`», y que el documentador anote 51639 a 51644 en ADR-82.

### S178-08 · Baja · EventId

- **Evidencia:**
  - [V] `git grep` de `new(51nn,` en `src` de todas las ramas remotas: 5150 a 5154 están libres. Están en uso 5117 y 5119 (`ConvertidorPdf.cs:37` y `:40`, PR #170) y 5121 a 5129 (`ReenvioReportes.cs`, `EvidenciaExportacionesService.cs`, `TrabajoNotificaciones.cs:75-76`). **Sin choque con T4-10.**
  - [V] el 5152 se llama `SelloRazorRechazado` en el documento (doc:99), que lo atribuye al diseño de A, pero A lo llama `FormatoSelloRechazado` (diseño de A, 7).
  - [V] **choque previo, ajeno a T4-10:** 5130 a 5133 (`IdentidadSql.cs`, `Inicializacion.cs`) y 5140 a 5143 (`SellosCuentas.cs`, `PadronSellos.cs`, `Inicializacion.cs:34`) ya están declarados dentro de la franja 5130 a 5149 que se reserva al instalador (N-8).
- **Remediación:** unificar el nombre del 5152, y avisar al responsable de N-8 de que esa franja ya no está libre.

### S178-09 · Baja · Diferencias de detalle con el diseño de A

1. **`Papel`.** El documento sigue la fórmula firmada e incluye `Papel` (doc:211 y 229). El diseño de A lo deja fuera (A, 2). Manda lo firmado: A debe actualizar su texto. Su condición («si `ServicioRender` usa `Papel`, entra») queda cubierta.
2. **Sello pedido antes de escribir** en un formato existente (doc:246). Mejora la falla cerrada, pero la API de reportes emite sellos válidos de contenido que puede no llegar a guardarse (por un choque de `Version`). Agrava un poco S178-03. Basta con anotarlo.
3. **La fila inerte del formato nuevo** con `Inhabilitado = 1` y `Predeterminado = 0` (doc:247) choca con la regla vigente «siempre un predeterminado habilitado por documento» [V] `FormatosService.cs:100-111`. Si es el primer formato del tipo, quien construya podría relajar esa regla. Hay que decir cómo se compone.
4. **Primera generación de `K_sello`** «la primera vez que hace falta» (doc:234): dos sellados simultáneos podrían crear dos llaves con el mismo `Kid`. Es solo disponibilidad (falla cerrada). Se cubre generando con creación exclusiva del archivo. El diseño de A también pide poner la llave a cero al detener el servicio, y el documento no lo recoge.

### S178-10 · Baja · Sucursal en la ruta de impresión del cierre

- **Evidencia:** [V] `ImpresionEndpoints.cs:16` (grupo `Sitio(OperacionSitio.Libre)`) y `:112-121`; [V] `ConsultasCaja.CierrePorNumero`, en `ConsultasCaja.cs:275-283`, no filtra por sucursal. La sección 2.3 (doc:176) manda registrar la copia en `doc.Impresion` **antes** de pedir el PDF. El 404 por sucursal lo da solo el lector de la API de reportes (doc:1120).
- **Riesgo:** quien tiene `movcajas` en la central registra copias de cierres de otra sucursal. Hoy, con el render en la principal, los imprime (un problema previo, fuera de T4-10). Con T4-11, el contenido queda protegido por la segunda barrera, pero la bitácora de copias se ensucia.
- **Remediación:** que la principal compruebe la membresía por sucursal antes de registrar la copia, con el mismo 404.

### S178-11 · Baja · Retención y datos personales (Ley 172-13)

- **Evidencia:** [V] doc:1100-1103: retención «sin cambios». Las líneas nuevas (denegaciones de C-2′, `FORMATO_RAZOR_SELLADO`, 5152 a 5154 y `doc.Impresion.ImpresoPor`) identifican empleados y no tienen plazo. [V] doc:322: S-03 (registrar la reimpresión de documentos con identificación y poner un tope) queda como «recomendación» [I]. [V] Hay textos libres sin enmascarar: `VentaPago.Referencia`, `Recibo.Concepto`, `Notas`, `Transportista` y `Beneficiario` (doc:588, 651, 1041, 860).
- **Remediación:** que las líneas nuevas sigan la retención del catálogo de T1-1, y que el especialista-pos convierta el tope de S-03 en requisito de T4-11. Además, anotar en el contrato que los textos libres no deben llevar identificaciones (validación de forma en la captura, como mejora posterior).

### S178-12 · Baja · 51640 sin lista blanca de esquemas de tablas

- **Evidencia:** [V] doc:1070-1076: solo se niegan los esquemas de vistas y las dependencias de otra base. Por encadenamiento de propiedad, el `DENY` de los esquemas de tablas no corta lo que lee una vista [V] `PermisosLecturaReportes.cs:12-14`. En la base de empresa existen `seg`, `audit` y `sync` [V] [ESQ].
- **Riesgo:** una vista `imp` futura podría leer `seg` o `audit`, y ni la migración ni la prueba 11 lo detectarían.
- **Remediación:** agregar a 51640 la condición `referenced_schema_name NOT IN (<esquemas permitidos>)`, con la lista que hoy usan las 45 vistas (`doc`, `ventas`, `compras`, `cxc`, `cxp`, `inv`, `banco`, `caja`, `cat`, `org`, `fiscal`, `num`, `conf`, `rrhh`). Costo: menos de 0,1 dp.

## 5. Controles que están bien implementados

- **Sello:** HMAC-SHA256 con subllave HKDF y `Kid`; `Huella binary(33)`; mensaje con prefijos de longitud; UTF-8 estricto con tope de 256 KB; verificación sobre los mismos bytes que se compilan; `FixedTimeEquals`; falla cerrada en todos los motivos; la principal y A-1 no tienen la llave; el nodo no acepta el sello de la central; el guardado no deja una transacción abierta durante la llamada HTTP y usa la guarda de `rowversion` (doc:204-256). Todo coincide con el diseño de A, salvo lo anotado en S178-09.
- **S-02:** `CK_FormatoImpresion_VisualConDiseno` con comprobación previa 51641 que falla cerrada y no corrige datos (doc:367-381), más la regla del render sin depender de `Modo`. `GeneradorRazor` escapa el texto del diseño [V] `GeneradorRazor.cs:149-152`.
- **C-1′, S-04, S-05 y S-07:** la cédula completa solo sale como `RncReceptor`, con la forma de 9 u 11 dígitos, en la caja chica con NCF (`CK_CajaChica_Rnc` [V] [ESQ]:6839), en la constancia y en la compra con `11`/`41`. El tipo y el número salen del mismo origen, el pasaporte y el tipo NULL se enmascaran, no se compone `'*******'` en SQL, y menos de 5 caracteres no revela nada. Ninguna otra columna estructurada entrega la cédula completa: se revisaron las 45 vistas, sin unión hacia `cat.Cliente.Identificacion` fuera de `idc`.
- **C-2′:** `imp.Cierre` sin montos; partición por `ci.Tipo` dentro de cada vista del cuadre; privilegio por vista; `SucursalId` en las vistas con privilegio; la principal y la API de reportes comprueban por separado.
- **Permisos:** `gpos_lectura` lee `imp` y `gpos_reportes` tiene `DENY` [V] `PermisosLecturaReportes.cs:51-55`; `DENY` de escritura y de creación de objetos; `guest` sin `CONNECT`. La API de reportes no escribe (ADR-109).
- **Sin `SELECT *`**, sin SQL dinámico en las vistas, `imp.Empresa` con la lista blanca de `LogoTipo` igual a `ImagenDiseno.TiposPermitidos` [V] `ImagenDiseno.cs:34`, y eventos sin la plantilla ni montos.
- **Residual ya aceptado:** el privilegio por vista (`vercostos`, `vercuadrecaja`, `movcajas`) lo exige solo `LectorRegistradas`. La base no lo exige, porque `gpos_lectura` lee todo `imp`. Un defecto de la API de reportes expondría costos y cuadres. Lo mitigan el lector único y la prueba estática de S-06.

## 6. Cierre de la revisión previa (S-01 a S-09)

El texto original de esa revisión está en la carpeta de B, fuera del repositorio, y no se leyó. Se evalúa contra lo que el propio documento dice de cada hallazgo (doc:22-41) y contra la DDL.

| ID | Estado | Evidencia |
|---|---|---|
| S-01 (Alta) | **Cerrado**, con las observaciones S178-02 y S178-03 | doc:209-268; columna `binary(33)` en doc:361 |
| S-02 (Alta) | **Cerrado** | doc:206 y 367-381; regla del render en doc:250-253; prueba 14 |
| S-03 (Media) | **Cerrado** en la regla (C-1′ firmada); el tope de reimpresión sigue como recomendación (S178-11) | doc:283-296 y 322 |
| S-04 (Media) | **Cerrado** en las vistas de venta, nota y cheque devuelto (`idc`); ver S178-05 para la compra | doc:457-459, 535-537 y 565-567 |
| S-05 (Media) | **Cerrado** en la forma (`rr` en el ticket, el documento de venta y la nota); el residual R12 está declarado | doc:452-456, 494-497, 531-534 y 1152 |
| S-06 (Media) | **Parcial**: los requisitos de T4-11 y `SucursalId` en las vistas con privilegio están; su efecto solo se puede verificar en T4-11; ver S178-10 | doc:711-744, 907-1030 y 1116-1133 |
| S-07 (Baja) | **Cerrado**: ninguna vista contiene `'*******'` | DDL de la sección 7; prueba 19 |
| S-08 (Baja) | **Cerrado**: hijas con `OPENJSON … WITH` tipado y DTO cerrados | doc:922-1030 y 1131 |
| S-09 (Baja) | **Cerrado**: la lista de la vista es igual a `TiposPermitidos` | doc:390-392; `ImagenDiseno.cs:34` |
| (S-10) | **Abierto**, aplazado al especialista-pos y al propietario; ver S178-04 | doc:1288-1290 |

## 7. Remediaciones priorizadas

1. **S178-01:** requisito de montos en las rutas JSON de `/cierres`, más la prueba 21 (0,3 a 0,5 dp). Es la condición para levantar el rechazo.
2. **S178-02:** `otp` incondicional y `auth_time` obligatorio en la ruta de sellado (0,1 dp).
3. **S178-03:** empresa en el mensaje, procedimiento de revocación por `Kid` y firma del residual (menos de 0,2 dp).
4. **S178-04:** `ExistenciaCorte` y `Diferencia` solo con la captura cerrada (0,1 dp).
5. **Bajas:** S178-12, S178-07, S178-06, S178-09, S178-05, S178-10, S178-11 y S178-08 (en conjunto, menos de 0,5 dp).

## 8. Lo que NO se verificó

- El texto original de la revisión previa (S-01 a S-10) de B ni la del PR #179 de A: se evaluó contra la descripción del documento.
- La hoja firmada de T4-10 (`docs/decisiones/2026-10-22-hoja-firma-t4-10-dd-11-c-1-c-2.md`): no se leyó el texto exacto de las firmas.
- Que la DDL compile: las columnas marcadas [I], los nombres JSON del `Detalle` y `conf.Parametros.Id = conf.Empresa.Id`.
- Que la introspección v1 devuelva `auth_time` a la API de reportes.
- Que `ServicioRender` no compile nada que dependa de `Papel` (ahora va en el mensaje, así que da igual).
- Que `fiscal.Comprobante` guarde la identificación del suplidor en los tipos `11`/`41` (S178-05).
- Q-TI-9 en `rpt.VentaDocumento` y `rpt.ConsultaFactura`: está fuera de este documento y no se revisó.
- Si el CNT se imprime antes de cerrar la captura (S178-04).
- Que `LectorRegistradas` y `ContextoLectura` acepten `movcajas` (doc:172, [I] del documento).
- Las rutas de la interfaz (MAUI/Blazor) que muestran el resultado del X: solo se revisó el servidor.
- No se ejecutó ninguna prueba ni compilación.

### Cierre
- Estado: Rechazado (recomendación técnica; pasa a «Aprobado con observaciones» cuando se incorpore S178-01 y se resuelvan o acepten S178-02 a S178-04)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr178-t4-10-2026-10-22.md`
- Supuestos: el código de `origin/feature/modelo-ng` `dedc62ec` es el que T4-10 y T4-11 van a modificar; la descripción que hace el documento de S-01 a S-09 es fiel a la revisión previa.
- Decisiones candidatas a ADR: atar el sello a la empresa del contexto (S178-03); revocar un Razor rotando `Kid` (S178-03); que C-2′ cubra también las respuestas JSON del cierre X (S178-01; confirmación del propietario).
- Entregas a otros agentes: arquitecto-datos (B) → S178-01 en la sección 2.3, más S178-02, S178-03, S178-04, S178-06, S178-07 y S178-12 en el documento; desarrollador-backend → S178-01 y S178-10 en `EfectivoEndpoints`, `CierresCajaService` e `ImpresionEndpoints`; equipo A (diseño del sello) → `Papel` en el mensaje y el nombre del 5152 (S178-08 y S178-09); especialista-pos → S178-04 y el tope de S-03; documentador → 51639 a 51644 en ADR-82 (S178-07); responsable de N-8 → la franja 5130 a 5149 ya está ocupada en parte (S178-08); propietario → firmar el residual de S178-03 y confirmar el alcance de C-2′ (S178-01).
- Próximo paso recomendado: que B incorpore S178-01 a S178-04 en la revisión 4 del documento y pida una revisión de cierre corta, solo de esas secciones.
