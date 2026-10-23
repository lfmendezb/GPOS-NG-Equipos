[Informe de Seguridad] Revisión de cierre del PR #178 (T4-10), revisión 4 · equipo A · 2026-10-22

- **Objeto:** `docs/datos/2026-10-22-t4-10-vistas-imp.md`, rama `origin/b/datos-t4-10`, punta `38a80c96` (1371 líneas). Se leyó con `git show`, sin cambiar de rama, sin tocar el árbol y sin compilar.
- **Alcance:** solo las secciones 0.6, 2.3, 3.2 y 7 (más las pruebas 8, 11, 15, 21, 23 y 24 de la sección 12 y la 0.5, en la medida en que las citan). Contraste con la revisión anterior (`revision-seguridad-pr178-t4-10-2026-10-22.md`, punta `bad7714b`), con el diseño del sello de A (`diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`) y con el código de `origin/feature/modelo-ng` `dedc62ec`.
- **Marcas:** [V] = verificado por lectura («doc:NNN» son líneas del documento en `38a80c96`); [I] = inferido.
- **Decisiones del propietario del 2026-10-22 que se dan por firmadas:** el alcance de S178-01 (rutas JSON del cierre), el de S178-03 (sello para todo el sitio, revocar = rotar `Kid`, repetición aceptada como R17) y los no incorporados (tope de reimpresiones de S-03 y la franja 5130 a 5149, R18).
- **Naturaleza:** es una recomendación técnica. La decisión es del propietario (C2).

## Recomendación: **Aprobar con condiciones**

No quedan hallazgos Críticos ni Altos. S178-01, el único Alto, queda **cerrado en el diseño** (doc:203-208, prueba 21). Las demás correcciones están bien hechas y no abren la cédula, el sello ni los montos por otro lado.

Quedan dos hallazgos **Medios**, ninguno en la DDL:

- **S178-R4-01:** el DTO sin montos del X se describe con una lista abierta («cantidades»). La prueba 21 solo busca cinco nombres de campo. Así, un DTO reutilizado podría seguir entregando el efectivo por moneda, las formas de pago o la diferencia escrita dentro del texto de la lista.
- **S178-R4-02:** existe una ruta JSON vecina, `GET /api/efectivo/movimientos-caja`, que no está en la lista de S178-01. Entrega los movimientos `VENTA` con montos a quien tiene `aperturacaja`, sin filtrar por turno.

**Condiciones antes de construir T4-11 y el recorte de la principal:**

1. S178-R4-01 incorporado en el texto de 2.3 y en la prueba 21. Costo: menos de 0,1 dp de texto y unas 0,1 dp de prueba.
2. S178-R4-02, decidido por el propietario (cubrirlo o aceptarlo) y entregado al desarrollador-backend junto con S178-01. Costo: de 0,1 a 0,2 dp si se cubre.

Las Bajas se pueden resolver al construir.

## 1. Cierre de S178-01 a S178-12

| ID | Sev. | Estado en rev. 4 | Evidencia y comentario |
|---|---|---|---|
| S178-01 | Alta | **Cerrado** (diseño), con S178-R4-01 y S178-R4-02 | [V] doc:203-208. Sin `vercuadrecaja`, `POST /cierres/x`, `GET /cierres/{numero}` y `GET /cierres/` responden sin montos. El Z lleva montos solo con `movcajas`, la bitácora no guarda montos y el recorte se hace en el servidor. Pruebas en doc:1297-1299. El alcance por turno ya existe [V] `CierresCajaService.cs:172-173` y `EfectivoEndpoints.cs:77-80`. `GET /cierres/pendiente` no entrega montos [V] `CierresCajaService.cs:40-65`, solo claves de forma de pago. Las líneas que cita el documento están corridas en uno: `POST /x` está en `:81` en `dedc62ec` |
| S178-02 | Media | **Cerrado**, con S178-R4-04 (Baja) | [V] doc:276-277. `otp` siempre, sin `SinFactorExigido`. Sin `auth_time`, o con más de 5 min, responde 403 `SELLO_AUTENTICACION_ANTIGUA` y falla cerrada. Pruebas en doc:1277 y 1279. La principal conserva `auth_time` al renovar [V] `AuthEndpoints.cs:300`, así que la renovación no lo rejuvenece |
| S178-03 | Media | **Cerrado por decisión** (R17), con S178-R4-03 (Baja) | [V] doc:242-245, 269 y 1219; prueba de revocación en doc:1278. Que el sello valga para todo el sitio y que la repetición quede aceptada son decisiones firmadas por el propietario |
| S178-04 | Media | **Cerrado** | [V] doc:773-793. `ExistenciaCorte`, `Diferencia` y `ValorDiferencia` salen solo con `CapturaCerradaEn IS NOT NULL` (falla cerrada); prueba 23 en doc:1305. Hoy el corte y el cierre de la captura se escriben a la vez [V] `ConsultasDocInventario.cs:168`, y no se encontró una ruta que reabra la captura |
| S178-05 | Baja | **Cerrado** | [V] doc:660-674 y 851-864. Tipo y número salen del mismo `fiscal.Registro606`. `PK_Registro606` es `DocumentoId` (no duplica filas). `CK_Registro606_TipoId` y `CK_Registro606_TipoIdLargo` amarran el tipo `'1'`/`'2'` al largo 9/11 [V] [ESQ]:6950-6957. Si los datos vienen del maestro, la cédula nunca va completa (`DelDocumento = 1`). **No abre C-1′:** en la compra, la C completa sigue exigiendo un comprobante propio `11`/`41` (doc:671-672); en la constancia, C-1′ ya permitía R y C |
| S178-06 | Baja | **Cerrado** [I: que la DEV de CxC no lleve caja] | [V] doc:480 y 523: los predicados se excluyen entre sí por `v.CajaId`; prueba 24 en doc:1306 |
| S178-07 | Baja | **Cerrado** | [V] P1 usa 51642 (doc:389), P0 usa 51639 y 51640 (doc:1129 y 1139) y S-02 usa 51641 (doc:413). La sección 0.4 (doc:77) y la entrega al documentador (doc:1358) son coherentes. Falta la anotación en ADR-82 (entrega) |
| S178-08 | Baja | **Cerrado** en lo de T4-10; la franja de N-8 queda fuera (R18) | El 5152 se llama `SelloRazorRechazado` (doc:100), igual que en el diseño de A ya actualizado (A, línea 79, que adopta 5150 a 5154 y descarta 5134 a 5139). Queda texto desactualizado: ver S178-R4-07 |
| S178-09 | Baja | **Cerrado** en el documento | [V] doc:266: `FileMode.CreateNew` y la llave a cero al detener el servicio. [V] doc:280: el sello pedido antes de escribir entra en R17. [V] doc:281: la fila inerte no relaja la regla del predeterminado. `Papel` va en el mensaje (doc:255). **Pendiente de A:** el diseño de A todavía dice «`Papel` … queda fuera» (A, línea 27); A debe actualizar su texto |
| S178-10 | Baja | **Cerrado** (requisito) | [V] doc:201; prueba en doc:1300 |
| S178-11 | Baja | **Parcial**, por decisión | [V] doc:359: retención según el catálogo de T1-1 y textos libres sin identificaciones. El tope de reimpresiones de S-03 no se incorpora (decisión de producto ya tomada) |
| S178-12 | Baja | **Cerrado** | [V] doc:1136-1138: lista blanca de 14 esquemas; prueba en doc:1260. La lista coincide con los esquemas que leen las 45 vistas, según lo revisado en 7 |

## 2. Lo verificado en los cuatro puntos del encargo

1. **El DTO sin montos del X** (doc:204-207):
   - El texto define una lista positiva («número, caja, cajero, fechas, cantidades y folios») y una negativa («nada de totales, esperado, declarado, contado ni diferencia»).
   - `imp.Cierre` no tiene ninguna columna `decimal` [V] doc:942-964, así que en la ruta de impresión no hay fuga.
   - En las rutas JSON, el riesgo está en cómo se construya el DTO (S178-R4-01).
   - La bitácora de las denegaciones y de los recortes no guarda montos ni datos personales: guarda usuario, empresa, sucursal, ruta o número, tipo y motivo [V] doc:202 y 207.
   - Fuera de lo nuevo, la bitácora de documentos del **Z** ya escribe la venta neta y la diferencia en su descripción [V] `CierresCajaService.cs:128`; ver S178-R4-06.
2. **La ruta de sellado y el mensaje:**
   - La ruta exige `otp` sin condiciones y falla cerrada cuando `auth_time` falta o es antiguo [V] doc:276-277.
   - El mensaje canónico (doc:251-258) es el de A con `Papel` agregado, sin otras diferencias:
     - prefijo `ASCII("GPOS.Imp.Sello.v1") ‖ 0x00`;
     - `Id` como `int32 BE`;
     - `TipoDocumento`, `Modo` y `Papel` con `uint16 BE` de largo más ASCII;
     - `Plantilla` con `uint32 BE` de largo más UTF-8;
     - `K_hmac = HKDF-SHA256(K_sello[Kid], info = "GPOS.Imp.Sello.v1")`;
     - `Huella = Kid ‖ HMAC` en `binary(33)` (doc:397).
   - El `Kid` no va dentro de `m`, pero sí queda atado: elige la subllave, igual que en el diseño de A.
   - `Papel` entra porque así lo dice la fórmula firmada.
3. **`fiscal.Registro606` no abre la cédula fuera de C-1′:** ver S178-05 en la tabla. Ninguna vista entrega `RncCedula` en bruto: el valor solo pasa por los patrones `ide`/`ids` y `rc` [V] grep del documento.
4. **Choques de códigos:**
   - **Errores SQL:** 51639, 51640, 51641 y 51642 tienen un solo uso cada uno dentro del documento. 51643 y 51644 están reservados. `git grep` en `src` de todas las ramas remotas: no hay ningún 51639 a 51644 [V].
   - **EventId:** `git grep "new(515n,"` en todas las ramas remotas no devuelve nada, así que 5150 a 5154 están libres [V].
     - Fuera de la franja 5150 a 5154 están ocupados 5117 y 5119 (`b/ola5-t4-03a`), 5121 a 5129, 5130 a 5133 y 5140 a 5143. No hay solapamiento.
     - El 5123 aparece en dos archivos según la rama. Es el mismo evento (`ExportacionReporte`), que se movió de archivo, no un choque.

## 3. Hallazgos nuevos

### S178-R4-01 · Media · El DTO sin montos del X no está cerrado y la prueba 21 busca por nombres

- **Evidencia:**
  - [V] doc:204: el DTO reducido lleva «número, caja, cajero, fechas, **cantidades** y folios; nada de totales, esperado, declarado, contado ni diferencia».
  - [V] doc:1297: la prueba comprueba que «el JSON no trae totales, esperado, declarado, contado ni diferencia».
  - [V] `CuadreCajaDto` trae además `formasPago[].monto`, `efectivoMonedas[]` (el efectivo esperado por moneda), `movimientosEfectivo[].ingresos/egresos`, `desgloseImpuestos[]`, `apertura` y las notas de crédito (doc:216-222 y 971-977).
  - [V] en la lista, la diferencia no está en un campo propio: va dentro del texto de la descripción (`" · dif. {dif:N2}"`, `CierresCajaService.cs:186`).
- **Escenario:** quien construye reutiliza `CuadreCajaDto` y anula los cinco campos que nombra la prueba. La prueba pasa, pero el JSON del X sigue llevando el efectivo por moneda y los ingresos y egresos. Con eso, el cajero reconstruye el esperado. En la lista, quitar `TotalVentas` deja la diferencia dentro de la descripción.
- **Remedio:**
  1. En 2.3, nombrar un DTO **propio y cerrado** (por ejemplo, `CierreSinMontosDto`) con la lista exacta de campos, la misma de `imp.Cierre`: número, tipo, caja, cajero, supervisor, fechas, `CantidadFacturas`, `CantidadDevoluciones`, `CantidadAnuladas`, `CierresX` y folios. Sin arreglos y sin ningún campo `decimal`.
  2. Para la lista, construir la descripción **sin** el sufijo «dif.».
  3. En la prueba 21, cambiar a una comprobación estructural: por reflexión, el tipo no tiene propiedades `decimal` ni colecciones. Y además, de datos: el JSON y la descripción de la lista no contienen la cifra del esperado ni la de la diferencia de un cierre preparado.
  - **Costo:** menos de 0,1 dp de texto y unas 0,1 dp de prueba.

### S178-R4-02 · Media · `GET /movimientos-caja` entrega las ventas en efectivo con montos a quien tiene `aperturacaja`

- **Evidencia:**
  - [V] `EfectivoEndpoints.cs:89-90`: la ruta admite `movcajas`, **`aperturacaja`** o `reportesefectivo`.
  - [V] `EfectivoService.cs:126-140` y `ConsultasCaja.cs:314-325` (`MovimientosRango`): devuelve todos los `caja.Movimiento` del rango, de cualquier caja si no se indica una, sin filtro de turno ni de sucursal, con entradas y salidas.
  - [V] los tipos incluyen `APERTURA`, `VENTA`, `DEVOLUCION`, `COBRO`, `RETIRO` y `GASTO` ([ESQ], `CK_CajaMovimiento_Tipo`).
  - La ruta está en el grupo `SoloCentral` (`:13`).
  - [I] no se verificó qué roles reciben `aperturacaja`. Si el cajero abre su propia caja, la tiene.
- **Escenario:** un cajero de la central con `cierrex` y `aperturacaja`, sin `vercuadrecaja`, suma la apertura más las ventas en efectivo, menos los retiros, de su turno, y obtiene el efectivo esperado. Es justo el dato que C-2′ y S178-01 le niegan. Es una ruta anterior a T4-10 y no está en la lista de S178-01. Pero si queda abierta, el cuadre a ciegas se puede evadir igual, solo con más trabajo.
- **Remedio (la opción más barata primero):**
  1. Quitar `aperturacaja` de la ruta (queda `movcajas` o `reportesefectivo`). Costo: unas 0,05 dp más una prueba.
  2. Alternativa: con solo `aperturacaja`, limitar la respuesta al turno propio y sin montos `VENTA`/`COBRO`/`DEVOLUCION`. Costo: unas 0,2 dp.
  - Agregarla a la entrega del desarrollador-backend de S178-01 y a la prueba 21.
  - Si el propietario confirma que `aperturacaja` es solo del supervisor, baja a Baja, pero conviene dejarlo escrito.
  - **Defensa en profundidad:** el resto de rutas JSON de efectivo con montos (`/saldos-bancarios` y `/movimientos-bancarios`) no son de caja y no se tocan.

### S178-R4-03 · Baja · La revocación por `Kid` no dice cómo deja de ser «conocido» el `Kid` viejo

- **Evidencia:**
  - [V] doc:269: «rotar el `Kid` … sin ventana, el sello anterior deja de verificar al momento».
  - [V] doc:285: el render exige un «`Kid` conocido».
  - [V] doc:266-267: las llaves están en `sello-razor.v{Kid}.bin`.
  - No dice qué hace que un `Kid` deje de ser conocido. Tampoco dice qué pasa al llegar a 255 (el `Kid` es de 1 byte).
- **Escenario:** si «conocido» significa que el archivo existe, revocar sin borrar el archivo viejo no revoca. Lo mismo pasa si un respaldo del anillo lo restituye.
- **Remedio:** escribir en 3.2 que:
  - el conjunto de `Kid` aceptados es explícito (el vigente, más los que siguen dentro de la ventana);
  - revocar **destruye** el archivo `v{Kid}` (o lo marca como retirado en un archivo del mismo anillo);
  - un `Kid` nunca se reutiliza: al llegar a 255, la rotación se niega y hace falta un `Kid` de 2 bytes en una versión `v2` del mensaje.
  - Extender la prueba de revocación: restaurar el archivo viejo no revive el sello si la marca de retirado está.
  - **Costo:** menos de 0,1 dp.

### S178-R4-04 · Baja · La excepción de desarrollo del `otp` no está acotada al entorno

- **Evidencia:** [V] doc:276: «La única excepción es una opción explícita de desarrollo, que registra un evento al arrancar».
- **Escenario:** la opción se copia a la configuración de un servidor de cliente, y la ruta sella sin `otp`. Solo queda un aviso en el arranque.
- **Remedio:**
  - la opción solo se respeta si el entorno es `Development`;
  - en cualquier otro entorno, el servicio se niega a arrancar (o ignora la opción y registra un error);
  - hace falta una prueba de mutación: con la opción y el entorno `Production`, sigue sin sellar.
  - **Costo:** unas 0,05 dp.

### S178-R4-05 · Baja · Una línea de bitácora por cada recorte normal llena `BitacoraSeguridad` de ruido

- **Evidencia:** [V] doc:207: «cada respuesta recortada deja una línea … en la lista, una línea por petición».
- **Escenario:** cada X de cada cajero sin `vercuadrecaja`, y cada vez que abre la lista, es una línea. Es el flujo normal, no un intento de abuso. El volumen tapa las denegaciones reales (403 de impresión) y gasta la retención de T1-1.
- **Remedio:** registrar los recortes como evento **informativo** separado de las denegaciones, o como una sola línea por usuario y día. Las denegaciones 403 siguen con una línea cada una. Costo: nulo en diseño.

### S178-R4-06 · Baja [I] · La bitácora de documentos del Z ya lleva montos en el texto

- **Evidencia:** [V] `CierresCajaService.cs:127-128`: la descripción incluye «venta neta {N2}, diferencia {N2}». No se verificó quién lee esa bitácora [I].
- **Escenario:** si un usuario sin `movcajas` puede consultar la bitácora de documentos, lee la diferencia del Z. Es anterior a T4-10.
- **Remedio:** quitar los montos de esa descripción, o confirmar que solo la lee un administrador. Entrega al desarrollador-backend. Costo: unas 0,02 dp.

### S178-R4-07 · Baja · Texto desactualizado sobre los EventId de A

- **Evidencia:** [V] doc:107 («allí con el número 5136»), doc:109 («A propone 5134 a 5139»), doc:1216 (R13: «o A mantiene 5134 a 5139») y doc:1354. El diseño de A ya adopta 5150 a 5154 y descarta 5134 a 5139 (A, línea 79).
- **Riesgo:** solo de coordinación. Puede hacer que alguien reabra una discusión ya cerrada.
- **Remedio:** actualizar las cuatro menciones.

## 4. Lo que NO se verificó

- Las secciones fuera del alcance pedido (1, 2.1, 2.2, 3.1, 3.3 salvo su tabla, 4 a 6, 8 a 11 y 13), salvo lo citado.
- Que la DDL compile, y las columnas [I] (`v.CajaId` como discriminador de la DEV y los nombres JSON del `Detalle`).
- Qué roles reciben `aperturacaja` (S178-R4-02) y quién lee la bitácora de documentos (S178-R4-06).
- Que la introspección v1 entregue `auth_time` a la API de reportes. No se encontró ninguna referencia a `auth_time` en `GPOS.Reportes.Api` en `dedc62ec`. Por la regla de doc:277, hasta que se agregue no se sella nada (falla cerrada), y el costo de agregarlo no está en el documento.
- Si existe una ruta que reabra la captura de un conteo (solo se buscó `CapturaCerradaEn` en `src`).
- Las rutas `rpt`/`rptc` del cuadre y la interfaz MAUI/Blazor.
- La hoja firmada de T4-10: las decisiones del chat se dieron por firmadas, según el encargo.
- No se ejecutó ninguna prueba ni compilación.

### Cierre
- **Estado:** Aprobado con observaciones (recomendación técnica: aprobar con las condiciones S178-R4-01 y S178-R4-02).
- **Artefactos:** `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-cierre-pr178-t4-10-rev4-2026-10-22.md`.
- **Supuestos:** el código de `origin/feature/modelo-ng` `dedc62ec` es el que van a modificar T4-10 y T4-11; las decisiones del propietario del 2026-10-22 descritas en el encargo están firmadas.
- **Decisiones candidatas a ADR:** ninguna nueva. La de S178-R4-02 (quién ve los movimientos de caja con montos) es una precisión de C-2′, no un ADR.
- **Entregas a otros agentes:**
  - arquitecto-datos (B) → S178-R4-01, R4-03, R4-04, R4-05 y R4-07 en el texto;
  - desarrollador-backend → S178-R4-02 y R4-06, con S178-01;
  - propietario → decidir S178-R4-02 (`aperturacaja`);
  - equipo A → actualizar «`Papel` queda fuera» en su diseño del sello (S178-09);
  - documentador → 51639 a 51644 en ADR-82.
- **Próximo paso recomendado:** que B agregue S178-R4-01 en 2.3 y la prueba 21, y que lleve S178-R4-02 al propietario antes de entregar el recorte al desarrollador-backend.
