[Informe de Seguridad] Revisión previa de T4-10 (vistas `imp`, C-1, C-2 y DD-11), solo lectura

- **Fecha:** 2026-10-22 · **Autor:** auditor-seguridad (agente) · **Para:** equipo B (arquitecto-datos y desarrollador-backend)
- **Objeto:** el borrador `t4-10-vistas-imp-borrador.md` (scratchpad, 908 líneas) y sus auxiliares `esquema-empresa.sql` (copia del script `database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql`) y `cols.sh`.
- **Código:** `origin/feature/modelo-ng` en `5237e11b`, leído con `git show` y `git grep`. El borrador se escribió sobre `b4378650`, y los archivos citados no cambian el análisis. Documentos: `master`.
- **Marcas:** [V] = verificado en el texto citado; [I] = inferido o pendiente de confirmar. «borrador:N» = línea N del borrador.
- No se modificó el repositorio, no se compiló nada y no se ejecutó ninguna consulta.

---

## 1. Alcance y superficie revisada

| Superficie | Qué se revisó |
|---|---|
| Principales SQL | `gpos_lectura` (`gpos_lec_*`), `gpos_reportes` (`gpos_rpt_*`) y `gpos_app` frente al esquema `imp` y a `conf.FormatoImpresion` |
| 31 vistas `imp` | Columnas expuestas, enmascarado C-1, separación de montos (C-2, `vercostos` y `vercuadrecaja`) y llaves de lectura |
| DD-11 | `GuardadoPorSuper`, `Huella binary(32)` y `CK_FormatoImpresion_HuellaRazor`, frente al render Razor de la API de reportes (ADR-110) |
| Migración | P0 (dueño `dbo` y sinónimos), P1 a P4, permisos generados y reversión |
| Fuera de alcance | La lógica de autorización de T4-11 (no existe). Aquí solo se fijan los requisitos que T4-11 debe cumplir |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | V/I |
|---|---|---|---|
| S-01 | **Alta** | La huella de DD-11 es SHA-256 sin llave. Quien escriba en `conf` (con `gpos_app` o más) puede marcar un Razor como guardado por el SUPER y lograr que se ejecute código en la API de reportes | V (mecanismo); I (probabilidad) |
| S-02 | **Alta** | Un formato `VISUAL` con `Diseno` en NULL compila `Plantilla` como Razor y esquiva DD-11, que solo mira `Modo = 'RAZOR'` | V |
| S-03 | Media | C-1 imprime la cédula íntegra en todo documento, también en los no fiscales y en consumo final. Por la (re)impresión, la cédula llega a quien no tiene `verdatospersonales`. Hay tensión con el principio de mínimos de la Ley 172-13 | V (exposición); I (lectura legal) |
| S-04 | Media | El enmascarado del ticket y del documento de venta cae al tipo del maestro (`COALESCE`), mientras que `rpt` enmascara cuando el tipo de la venta es NULL. Además, la nota y el cheque devuelto usan la identificación actual del maestro | V |
| S-05 | Media | `RncReceptor` se imprime íntegro sin validar su forma. `fiscal.Comprobante.RncReceptor` no tiene CHECK, así que un pasaporte guardado allí saldría completo (ADR-115: «nunca se muestra») | V (sin CHECK); I (que ocurra) |
| S-06 | Media | Todo el aislamiento por sucursal, permiso por tipo y privilegio por vista recae en T4-11. Las vistas hijas y las `*Costo` no traen ni sucursal ni tipo, y el plan de pruebas no tiene ninguna prueba negativa de autorización | V |
| S-07 | Baja | Cuando se aplique RS-05 o ADR-115 (cédula y pasaporte cifrados en reposo), `RIGHT(Identificacion, 4)` sobre el texto cifrado deja de funcionar. Falta la columna «últimos 4» | V (dependencia) |
| S-08 | Baja | `imp.CierreCuadre` entrega subárboles JSON opacos (`varchar(max)`) que el contrato no puede declarar ni probar | V |
| S-09 | Baja | `LogoTipo` llega al render sin una lista blanca en la vista | I |
| S-10 | Baja | Exposiciones que hereda del comportamiento actual: el costo de compra sin `vercostos` y la existencia teórica en la hoja de conteo | V |

**Resultado:** dos hallazgos Altos (S-01 y S-02), los dos en DD-11.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Hallazgos |
|---|---|---|
| A01 Control de acceso | **Con hallazgos.** Lo que hace el motor está bien (`gpos_rpt` niega `imp`; solo `gpos_lec` lo lee); lo que hace la aplicación está sin especificar | S-03, S-06, S-10 |
| A02 Fallas criptográficas | **Con hallazgo.** La huella no tiene llave | S-01, S-07 |
| A03 Inyección | Sin hallazgos en las vistas: no hay SQL dinámico, sinónimos ni nombres de tres partes (borrador:73). El SQL dinámico de los permisos usa `QUOTENAME` sobre `sys.schemas` [V] `PermisosLecturaReportes.cs:61-70`. Inyección de plantilla: ver A08 | — |
| A04 Diseño inseguro | **Con hallazgos.** El render confía en la base para decidir qué compila | S-01, S-02, S-08 |
| A05 Configuración | Sin hallazgos. P0 falla cerrada si el dueño no es `dbo` o hay sinónimos (borrador:131-135); P3 vuelve a aplicar el lote (HD-3) | — |
| A06 Componentes vulnerables | No aplica a T4-10 (no agrega paquetes). `Razor.RuntimeCompilation 10.0.12` ya está en la API de reportes [V] `GPOS.Reportes.Api.csproj:20` | — |
| A07 Autenticación | No aplica (sin cambios en tokens ni en sesiones) | — |
| A08 Integridad de software y datos | **Con hallazgos.** Código Razor guardado en la base y ejecutado sin una verificación de autenticidad | S-01, S-02 |
| A09 Registro y monitoreo | Sin hallazgos en T4-10. La reimpresión la registra la principal (borrador:100; ADR-109 cl. 7). Recomendación en S-03: registrar también la reimpresión con datos personales | — |
| A10 SSRF | No aplica. Chromium solo admite `data:` (ADR-110 cl. 7) | — |

## 4. Hallazgos

### S-01 · Alta · La huella de DD-11 sin llave no protege contra quien escribe en la base

- **Riesgo.** El render de la API de reportes compila en su propio proceso la plantilla Razor que lee de `imp.Formato`: es C# con todos los permisos de la cuenta del servicio. Por diseño (ADR-109 cl. 5), ese proceso puede abrir los sobres de lectura de todas las empresas del sitio y entrar a `GPOS_SYSDATA` con `gpos_rpt_sis`. Con SHA-256 sin llave, quien pueda escribir en `conf.FormatoImpresion` también puede calcular una huella válida y poner `GuardadoPorSuper = 1`. Esa escritura puede venir de una inyección SQL en la API principal, de la cadena de `gpos_app` filtrada, de un DBA o de la bajada de configuración a un nodo. Así, un permiso de escritura de datos **en una empresa** se convierte en **ejecución de código en el servidor** y en lectura de **todas** las empresas del sitio. Es justo el salto de frontera que ADR-109 quiere evitar. La probabilidad es baja (requiere escribir en `conf`) y el impacto es crítico; de ahí la severidad Alta.
- **Evidencia.**
  - [V] borrador:76 («SHA-256 de los bytes UTF-8 de `Plantilla`, que calcula la API principal»), borrador:149-151 y borrador:829 (el propio R5 lo reconoce).
  - [V] `gpos_app` tiene `SELECT, INSERT, UPDATE ON SCHEMA::conf`: `database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql:428`.
  - [V] Compilación en el proceso: `src/GPOS.Reportes.Api/Impresion/ServiciosRender.cs:34` (`AddRazorRuntimeCompilation`) y `ServicioRender.cs:46` (`razor.RenderizarAsync(plantilla, …)`).
  - [V] ADR-110, precisión del 2026-10-20 (`docs/adr/ADR-110.md:36`): «la rechaza si la marca falta o la huella no coincide». El texto no dice si la huella lleva llave; la firma no lo exige ni lo descarta.
- **Remediación (recomendada).** **Sello con llave que guarda quien verifica:**
  1. Al guardar un Razor, la principal pide el sello a la API de reportes del sitio con el token del SUPER (con `otp`, ADR-81).
  2. La API de reportes valida nivel SUPER y sesión, y calcula `HMAC-SHA256(llave, versión ‖ Id ‖ TipoDocumento ‖ Modo ‖ Papel ‖ UTF-8(Plantilla))`. La llave vive en su propio anillo (`CifradorAnillo`, que la cl. 5 ya admite «si la API de reportes llega a necesitar Data Protection»).
  3. La principal guarda el sello en `Huella` sin conocer la llave.
  4. Al renderizar, la API de reportes recalcula y compara con `CryptographicOperations.FixedTimeEquals`. Si falla, rechaza (falla cerrada, como firma DD-11).

  Incluir `Id` y `TipoDocumento` impide trasplantar una plantilla sellada a otra fila u otro tipo. Esfuerzo [I]: de 1 a 1,5 dp sobre los 0,75 dp de DD-11 del borrador. Costo en dinero: USD 0.
- **Alternativas descartadas.**
  - (a) SHA-256 sin llave (el borrador): solo detecta corrupción accidental.
  - (b) HMAC con una llave del anillo de la principal: la API de reportes tendría que tener ese anillo, lo que contradice la cl. 5.
  - (c) Firma ECDSA de la principal y verificación con la llave pública en reportes: protege igual contra quien escribe en la base, pero obliga a custodiar una llave privada nueva en la principal. Es la opción si el propietario prefiere no agregar un punto de reportes.
  - (d) Aislar el render Razor en un proceso sin acceso a los sobres: es más fuerte, pero cuesta varias semanas-persona y Razor es legado con retiro previsto (ADR-110 cl. 3).
- **Defensa en profundidad.** Mientras el sello no esté, mantener lo firmado en C-3: la API de reportes **rechaza todo Razor** leído por `imp`.
- **Requiere decisión.** Es una precisión de DD-11 (llave y custodia). Va en Decisiones candidatas a ADR.

### S-02 · Alta · `VISUAL` con `Diseno` NULL compila `Plantilla` y esquiva la comprobación de DD-11

- **Riesgo.** El render elige qué compilar así: `f.Modo == ModoVisual && f.Diseno is not null ? GeneradorRazor.Generar(...) : f.Plantilla`. Una fila `Modo = 'VISUAL'` con `Diseno` NULL compila `Plantilla` como Razor libre. El CHECK propuesto (`Modo <> 'RAZOR' OR …`) y la regla del render («rechaza el modo Razor si…») se fijan en `Modo`, así que esa fila pasa los dos controles. La API principal no deja guardar esa combinación, pero una escritura directa en la base sí (los mismos actores de S-01).
- **Evidencia.**
  - [V] `src/GPOS.Reportes.Api/Impresion/ServicioRender.cs:38-41`.
  - [V] `src/GPOS.Core/Servicios/FormatosService.cs:78`: la validación existe solo en la API.
  - [V] borrador:77 y borrador:150-151: el CHECK solo condiciona a `RAZOR`.
  - [V] El esquema no tiene ningún CHECK que una `VISUAL` con `Diseno` (`esquema-empresa.sql:532-551`).
- **Remediación.**
  1. En el render, la regla debe ser «**todo texto que se compile y no salga de `GeneradorRazor` exige la marca y el sello**», sin importar `Modo`. Si es `VISUAL` sin `Diseno`, se rechaza.
  2. En la DDL de P2, agregar `CK_FormatoImpresion_VisualConDiseno CHECK (Modo = 'RAZOR' OR Diseno IS NOT NULL)`. Antes, comprobar que ninguna fila lo viole y fallar con un mensaje claro si alguna lo hace.
  3. Agregar una prueba de que una fila `VISUAL` con `Diseno` NULL insertada por SQL no se renderiza.

  Esfuerzo [I]: 0,25 dp.
- **Control correcto relacionado [V].** El modo gráfico codifica el texto del diseño y escapa la arroba (`GeneradorRazor.cs:149-152`), y los campos salen de un catálogo cerrado (`:124-143`). Así, `Diseno` no es una vía de inyección mientras pase por el generador.

### S-03 · Media · C-1: la cédula íntegra en todo impreso excede lo necesario y abre una lectura sin `verdatospersonales`

- **Riesgo.** El borrador aplica «RNC y cédula íntegros» a toda vista de encabezado: cotización, pedido, cheque devuelto y ticket de consumo sin comprobante que pida identificación.
  - En `rpt` la cédula va enmascarada para todos, y en `rptc` va completa solo con `verdatospersonales`.
  - Quien solo tiene «Punto de venta» puede reimprimir cualquier ticket de su sucursal y leer la cédula completa de cada cliente: la impresión se vuelve un canal de lectura masiva que esquiva RS-01. La reimpresión deja la marca «COPIA n» (control de detección), pero no hay control preventivo.
  - **Ley 172-13 [I: lectura propia, no es opinión legal]:** sus principios de calidad (datos adecuados, pertinentes y no excesivos para la finalidad) y de finalidad piden limitar el dato al uso necesario. El tratamiento sin consentimiento se justifica cuando lo exige una obligación legal. La obligación fiscal (RS-03, firmada: RNC o cédula en los tipos 01, 14, 15, 31, 44 y 45) **justifica la cédula íntegra en esos comprobantes y en la constancia de retención**, pero no en una cotización, un pedido o un consumo final sin receptor.
  - El RNC de 9 dígitos está en el padrón público de la DGII, así que imprimirlo íntegro no plantea problema, aunque el contribuyente sea persona física. Por eso M-5 de C afecta a `rpt`, no a `imp`.
- **Evidencia.**
  - [V] borrador:29, borrador:219-226, borrador:259-265, borrador:434-436, borrador:679-681, borrador:348-350.
  - [V] `rptc` exige `verdatospersonales` (`GPOS-NG-Equipos/traspasos/C/2026-10-22-inventario-reportes-identificacion-tercero.md`, filas 2 y 4).
  - [V] RS-01 y RS-05 en `docs/adr/ADR-109.md:48,51`.
  - [V] C-1 en `docs/adr/ADR-109.md:127` y en la hoja del tramo 4, punto C-1 (justificada por RS-03).
  - [V] El permiso para imprimir un ticket es `PuntoVenta` o `Devoluciones` (`src/GPOS.Contracts/Impresion/ModeloImpresion.cs:169-171`).
- **Remediación (precisión de C-1, menor, para que la firme el propietario).**
  - RNC (`R`): íntegro siempre.
  - Cédula (`C`): íntegra **solo** si el documento tiene un comprobante cuyo `RncReceptor` es esa cédula (el dato fiscal), en la constancia de retención y en el gasto de caja chica con NCF. En cualquier otro caso, `*******` más los últimos 4, como en `rpt`.
  - Pasaporte: sin cambios.

  En SQL basta con una rama más del `CASE`, que compare con `c.RncReceptor`. Esfuerzo [I]: 0,25 dp; el contador debe confirmar los tipos (DGII 01, 14, 15, 31, 44 y 45, más las facturas de consumo por encima del umbral que exige receptor [I]).
- **Alternativa descartada.** Mantener C-1 tal como está y exigir `verdatospersonales` para reimprimir. Rompe la operación del cajero: no podría reimprimir un ticket de crédito fiscal.
- **Defensa en profundidad.** Registrar en la bitácora la reimpresión de documentos con identificación personal (ya existe `doc.Impresion`). En T4-11, poner un tope de reimpresiones por usuario y por hora con alerta [I: cifra a definir].

### S-04 · Media · Enmascarado que cae al tipo del maestro y datos actuales en la reimpresión

- **Riesgo.**
  - En `imp.Ticket` e `imp.DocumentoVenta`, si la venta tiene `IdentificacionCliente` y `TipoIdentificacionCliente` es NULL (filas anteriores a la migración `Ola5TipoIdentificacionCliente`, u orígenes que no capturan el tipo), el tipo se toma **del maestro actual**. Si el maestro es `C` o `R`, la identificación de la venta (que puede ser un pasaporte) sale íntegra. `rpt` hace lo contrario: con el tipo de la venta en NULL enmascara, porque `NULL IN (...)` cae en `ELSE`.
  - `imp.NotaCxc` e `imp.ChequeDevuelto` leen `cl.Identificacion`, es decir, el dato de **hoy** y no el registrado en el documento. Una reimpresión fiscal mostraría otra identificación que la emitida (integridad).
- **Evidencia.**
  - [V] borrador:221 y borrador:261 (`COALESCE(v.TipoIdentificacionCliente, cl.TipoIdentificacion)`).
  - [V] El patrón de `rpt` está en `esquema-empresa.sql:13313-13315` (`CASE WHEN v.IdentificacionCliente IS NOT NULL THEN v.TipoIdentificacionCliente ELSE cl.TipoIdentificacion END`).
  - [V] borrador:434-436 y borrador:679-681.
  - [V] `ventas.Venta.TipoIdentificacionCliente` es NULL-able (`esquema-empresa.sql:12687, 12695`).
- **Remediación.** Copiar el `CROSS APPLY idc` de `rpt`: la identificación y su tipo salen **del mismo origen**, y un tipo NULL enmascara. Usar `v.IdentificacionCliente` y `v.TipoIdentificacionCliente` también en la nota y el cheque devuelto, que están en `ventas.Venta`. Así, la regla de C-1 vive en un solo patrón. Prueba 8 del borrador: agregar el caso «venta con identificación y tipo NULL, maestro C, se enmascara». Esfuerzo [I]: 0,1 dp.

### S-05 · Media · `RncReceptor` íntegro sin validar su forma

- **Riesgo.** C-1 manda imprimir íntegro el `RncReceptor`, pero la columna no tiene restricción de forma. Si un flujo (exportación B16/E46, importaciones, conectores e-CF) guarda allí un pasaporte de 11 caracteres o menos, el impreso lo mostraría completo. Eso contradice ADR-115 («el número completo del pasaporte nunca se muestra»).
- **Evidencia.**
  - [V] `fiscal.Comprobante` no tiene un CHECK sobre `RncReceptor` (`esquema-empresa.sql:3082-3108`).
  - [V] borrador:214, borrador:257 y borrador:432.
  - [V] `docs/adr/ADR-115.md:72`.
- **Remediación.** En la vista: `CASE WHEN c.RncReceptor NOT LIKE '%[^0-9]%' AND LEN(c.RncReceptor) IN (9, 11) THEN c.RncReceptor ELSE '*******' + RIGHT(c.RncReceptor, 4) END`, que falla cerrada. Entregar al arquitecto-datos un CHECK equivalente en `fiscal.Comprobante`, fuera de T4-10.

### S-06 · Media · La autorización depende del código; sin pruebas negativas y con hijas sin contexto

- **Riesgo.**
  - El borrador delega en T4-11 tres controles: la sucursal de la membresía (ADR-13), el permiso por tipo (`TiposFormato.Permisos`) y el privilegio por vista (`vercostos`, `vercuadrecaja`). Es correcto, porque la vista no conoce al usuario.
  - Las vistas hijas (`imp.VentaLinea`, `imp.*Aplicacion`, `imp.DocInventarioLineaCosto`, `imp.ConteoLineaCosto`, `imp.CierreCuadre`) se leen solo por `DocumentoId`, sin sucursal ni tipo. Si una consulta registrada lee una hija sin haber validado antes el encabezado, se filtran líneas, costos o cuadres de otra sucursal o de un tipo sin permiso.
  - Las pruebas 1 a 13 (borrador:857-873) son de estructura: ninguna prueba que un usuario de la sucursal A **no** obtenga un documento de B, ni que un usuario sin `vercostos` no reciba columnas de costo.
  - La regla «solo por llave» (C-1) se cumple con una prueba estática (borrador:819), que es aceptable porque la credencial `gpos_lec` nunca llega al usuario (cl. 6).
- **Evidencia.**
  - [V] borrador:27, borrador:491-495, borrador:526-529, borrador:729-745, borrador:817-819 y borrador:857-873.
  - [V] Lo que se hace hoy: `src/GPOS.Api/Impresion/FabricaModelo.cs:136,165` (`sesion.VerCostos()`).
- **Remediación.**
  1. En T4-11, un **único lector** que (a) lee el encabezado por la vista del tipo pedido, (b) valida la sucursal (origen o destino en la transferencia), el permiso del tipo y el estado, y (c) solo después lee las hijas, con el mismo `DocumentoId`. Las vistas con privilegio se leen solo si el privilegio está vigente.
  2. Prueba estática: ninguna consulta registrada nombra una hija o una vista con privilegio fuera de ese lector.
  3. Pruebas negativas (con la API real y bases `GPOS_TEST_*`):
     - un documento de otra sucursal da 404 en los 20 tipos, más X/Z y el conduce;
     - sin `vercostos`, el modelo no trae costo;
     - sin `vercuadrecaja`, el X no trae cuadre;
     - un cajero sin `vercuadrecaja` no imprime el cierre de otra jornada [I: regla a confirmar con el especialista-pos].
  4. Opcional, por ser barato: agregar `SucursalId` a las hijas con privilegio (`*Costo` y `CierreCuadre`) para que el filtro también se pueda escribir en la consulta. Es una búsqueda puntual más por la PK.

  Esfuerzo [I]: de 0,5 a 0,75 dp en T4-11.

### S-07 · Baja · Dependencia con el cifrado en reposo (RS-05 y ADR-115)

- **Riesgo.** ADR-115 manda sellar el pasaporte con «últimos 4 en claro», y RS-05 manda cifrar la cédula antes de la primera instalación fuera de desarrollo. Cuando eso se construya, `RIGHT(Identificacion, 4)` aplicado al texto cifrado devolverá basura, o la vista dejará de servir. También cambiará cómo se resuelve S-03.
- **Evidencia.** [V] `docs/adr/ADR-115.md:16,40`; `docs/adr/ADR-109.md:51`; las ramas `ELSE '*******' + RIGHT(...)` del borrador.
- **Remediación.** Registrarlo como dependencia en el diseño del cifrado: una columna `IdentificacionUltimos4 char(4)` (o la que se elija) que las vistas `imp`, `rpt` y `rptc` usen en lugar de `RIGHT`. No cambia T4-10 hoy.

### S-08 · Baja · Subárboles JSON opacos en `imp.CierreCuadre`

- **Riesgo.** `FormasPagoJson`, `DesgloseImpuestosJson`, `MovimientosEfectivoJson`, `ConteoJson` y `EfectivoMonedasJson` pasan tal cual el `Detalle`. Si `CuadreCajaDto` agrega una propiedad sensible, sale sin que el contrato ni la prueba de columnas lo detecten. Además, R3 (borrador:827): los nombres de ruta que cambian devuelven NULL sin aviso.
- **Evidencia.** [V] borrador:740-744.
- **Remediación.** En T4-11, deserializar a un DTO cerrado con solo los campos que imprime el X o Z e ignorar el resto. Prueba de «todas las propiedades no nulas» del cierre real (ya es la mitigación de R3).

### S-09 · Baja · `LogoTipo` sin una lista blanca en la vista

- **Riesgo.** `imp.Empresa.LogoTipo varchar(30)` alimenta el `data:` URI del logo. ADR-110 cl. 7 limita las imágenes a PNG, JPEG, GIF y WebP «al guardar y al renderizar».
- **Evidencia.** [V] borrador:166-167. [I] cómo lo arma `FabricaModeloImp` (no existe).
- **Remediación.** En T4-11, validar `LogoTipo` contra la lista blanca y los bytes mágicos antes de armar el URI. Si no pasa, imprimir sin logo y registrar el evento, como RQ-R12.

### S-10 · Baja · Exposiciones que vienen del comportamiento actual

- `imp.CompraLinea.CostoUnitario` y `imp.PagoAplicacion.BaseRetencion` no exigen `vercostos`. Hoy el documento de compra se imprime con sus precios a quien tenga el permiso del tipo (borrador:378) [V]. El precio de compra es, en la práctica, el último costo. Confirmar con el propietario que `vercostos` no alcanza los documentos de compra (comportamiento de BP2).
- `imp.ConteoLinea.ExistenciaCorte` y `Diferencia` no exigen ningún privilegio, como hoy (`FabricaModelo.cs:161-171`) [V]. Si alguna vez se pide un conteo de inventario a ciegas, la hoja impresa antes de `CapturaCerradaEn` lo anularía [I]. Va al especialista-pos.
- Los nombres de usuario (`AnuladoPor`, `CreadoPor`, `Cajero`, `Supervisor`) se imprimen hoy. Aceptable: son datos internos de la empresa.

## 5. Controles bien implementados

- [V] **Separación de principales:** `gpos_reportes` tiene `DENY SELECT ON SCHEMA::imp`, solo `gpos_lectura` lo lee, y `gpos_app` no recibe nada sobre `imp` (`PermisosLecturaReportes.cs:53-57`; borrador:812-816). Si P3 no se aplica, las dos credenciales quedan sin acceso (falla cerrada).
- [V] **Negaciones generadas desde el catálogo** con `QUOTENAME` y reaplicadas por `crear-lectura` (`PermisosLecturaReportes.cs:60-70`). HD-3 detecta bien que hay que reaplicarlas después de crear `imp`.
- [V] **P0** extiende V-R1 a `imp` (dueño `dbo` y sin sinónimos), con `THROW` (borrador:131-135). El encadenamiento de propiedad no cruza bases: no hay nombres de tres partes.
- [V] **Partición por tipo:** cada vista de encabezado filtra `t.Codigo`, así que pedir un `FCP` por `imp.DocumentoVenta` no devuelve nada. Eso impide la confusión de tipo en el motor.
- [V] **Montos con privilegio separados en vistas propias:** las `*Costo` y `CierreCuadre`. `imp.VentaLinea` no expone `CostoUnitario` (borrador:290), y la tarjeta solo va con sus últimos 4 (borrador:323).
- [V] **C-2 más estricto que lo firmado:** `imp.Cierre` no lleva ningún monto (borrador:700-727). En seguridad es la decisión correcta, porque `caja.ConteoCiego` (`esquema-empresa.sql:3456`) indica un arqueo a ciegas, y los totales de venta permitirían estimar el efectivo esperado. Se recomienda que el propietario firme esa precisión (es la decisión candidata (b) del borrador).
- [V] **Enmascarado que falla cerrado** cuando el tipo es NULL, en las vistas que no usan `COALESCE` (compra, constancia, nota y cheque devuelto); el `CHECK` del maestro limita P a entre 5 y 20 caracteres (`esquema-empresa.sql`, `CK_Cliente_Identificacion`).
- [V] **Generador gráfico** con codificación HTML, escape de la arroba y catálogo cerrado de campos (`GeneradorRazor.cs:124-152`).
- [V] La reimpresión y la bitácora del conduce las registra la principal antes del PDF (borrador:100).

## 6. Remediaciones priorizadas

| # | Acción | Hallazgo | Cuándo | Esfuerzo [I] |
|---|---|---|---|---|
| 1 | Sello con llave (HMAC de la API de reportes, u opción (c)) en lugar de SHA-256; comparación en tiempo constante; sello ligado a `Id` y `TipoDocumento` | S-01 | **Antes de construir T4-10** (decisión del propietario) | 1-1,5 dp |
| 2 | Regla del render «todo lo que se compila fuera del generador exige sello» más `CK_FormatoImpresion_VisualConDiseno` | S-02 | **Antes de construir T4-10** | 0,25 dp |
| 3 | Patrón `idc` de `rpt` en ticket y venta; identificación de la venta en la nota y el cheque devuelto | S-04 | En T4-10 | 0,1 dp |
| 4 | `RncReceptor` enmascarado si no tiene la forma de RNC o cédula | S-05 | En T4-10 | 0,05 dp |
| 5 | Precisión de C-1: cédula íntegra solo si es el receptor fiscal | S-03 | Firma del propietario antes de unir T4-10 | 0,25 dp |
| 6 | Lector único, prueba estática y pruebas negativas de autorización | S-06 | T4-11 (requisitos fijados ahora) | 0,5-0,75 dp |
| 7 | S-07, S-08, S-09 y S-10 | — | T4-11 y diseño del cifrado | < 0,5 dp |

Total adicional [I]: de 2,5 a 3,4 dp (±40 %). Costo en dinero: USD 0.

## 7. Recomendación

**Rechazado en la forma actual. Corregir antes de construir T4-10** (C3: quedan dos hallazgos Altos, S-01 y S-02, los dos en DD-11). El diseño de las vistas (principales, partición por tipo, separación de costo y cuadre, P0 y P3) es sólido. S-03 a S-06 se pueden corregir dentro de T4-10 y T4-11, sin bloquear el inicio, si S-01 y S-02 quedan resueltos o el propietario decide de forma explícita. Es una recomendación técnica: la decisión es del propietario (C2).

---

### Cierre
- Estado: Rechazado (recomendación técnica; corregir S-01 y S-02 antes de construir)
- Artefactos: C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\revision-previa-seguridad-t4-10.md
- Supuestos:
  - El borrador se revisó contra `origin/feature/modelo-ng` en `5237e11b` (el borrador cita `b4378650`); los archivos citados no cambian el análisis.
  - La lectura de la Ley 172-13 es técnica [I] y no sustituye una opinión legal.
  - El umbral de identificación en consumo final es [I].
  - T4-11 aún no existe: S-06 fija requisitos, no evalúa código.
- Decisiones candidatas a ADR:
  - Precisión de DD-11 (ADR-110): sello con llave, quién lo calcula y dónde vive la llave. Opción elegida: HMAC calculado por la API de reportes con su propio anillo. Descartadas: SHA-256 sin llave, HMAC del anillo de la principal, aislar el render. Alternativa válida: ECDSA de la principal.
  - Precisión de C-1 (ADR-109 cl. 4): cédula íntegra solo como receptor fiscal y en la constancia de retención; enmascarada en lo demás.
  - Precisión de C-2: X sin ningún monto (la candidata (b) del borrador), que se respalda en la seguridad.
- Entregas a otros agentes:
  - arquitecto-datos → S-02 (CHECK), S-04 y S-05 en la DDL; CHECK de forma en `fiscal.Comprobante.RncReceptor`; columna de los últimos 4 en el diseño del cifrado (S-07).
  - arquitecto-maestro → preparar las precisiones de DD-11, C-1 y C-2 para que las firme el propietario.
  - desarrollador-backend (B) → el sello de S-01 y la regla de S-02 en `ServicioRender`, `FormatosService` y la API de reportes; el lector único de S-06 en T4-11.
  - qa-automatizado → pruebas negativas de S-06 y casos nuevos de las pruebas 8 y 13.
  - especialista-pos → la regla de quién imprime qué cierre (S-06) y el conteo de inventario a ciegas (S-10).
  - contador o asesor legal → los tipos de comprobante que exigen la cédula y la lectura de la Ley 172-13 (S-03).
- Próximo paso recomendado: que el propietario decida la llave del sello de DD-11 (S-01) y la precisión de C-1; con eso, el arquitecto-datos ajusta P2 y las vistas, y T4-10 puede empezar.
