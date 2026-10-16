# Blueprint de datos: vertical Corporativa y capacidad común de comensales

[Blueprint de Datos] · Arquitecto de datos (equipo A) · 2026-10-15 · **Estado: diseño para la entrega 3, con los puntos FD-01 a FD-15 Pendientes de firma** · Sin commit · No toqué código ni bases.

**Fuente de verdad:** `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md` (citada **[HF]**), firmada el 2026-10-15: H-01 a H-03 y H-05 a H-11 en (a); F-1 a F-4, PF-1, PF-3 y PF-4 firmadas; **H-04 abierta**. Se suma **F-5** (propietario, por el coordinador, 2026-10-15): «En la pantalla al cajero debe presentarle cuanto le resta del consumo del subsidio por empleado. Y en el ticket de impresión también debe indicar cuanto le resta después de cada consumo.»
**Insumos:** [POS] `traspasos/A/pos-vertical-corporativa-2026-10-15.md`; [CONT] `traspasos/A/contable-vertical-corporativa-2026-10-15.md`; [CE] `origin/b/verticales-diseno:docs/decisiones/2026-10-09-hoja-firma-catering-y-ejecutivos.md`.
**Esquema base:** `origin/feature/modelo-ng` en `ce33b2a8` (2026-10-15 18:52), leído con `git archive`. Lo cito como `[NG] ruta:línea`.

**Convención:** *verificado* = leído en esta sesión con `ruta:línea`; *inferido* = estimación sin medir. El DDL es de referencia: **no lo ejecuté** en ninguna base (sección 11).

---

## 1. Contexto y modelo de tenencia aplicado

### 1.1 Tenencia
- **Base por empresa** (`GPOS_<EMP>`), sin columna discriminadora: es el modelo vigente ([NG] `src/GPOS.Core/Datos/Empresa/EmpresaNgDbContext.cs:21`, un contexto por base de empresa). Todas las tablas nuevas viven en la base de la empresa dueña de la cafetería (H-01 (a)). **No hay datos de dos empresas en una base**, así que el aislamiento entre tenants lo da la base; ninguna tabla nueva lleva `EmpresaId`.
- Dentro de la empresa, el aislamiento por **sede** es `SucursalId` (las franjas, el ticket y la serie son de una sede), como en `doc.Documento.SucursalId` ([NG] `Datos/Empresa/Configuracion/DocConfiguracion.cs:113`).
- En el modelo B (`CARGO_EMPRESA`, restaurante concesionario), el padrón es **de cada cliente** del restaurante: `com.Comensal.ClienteId` lo separa. En la Corporativa va siempre en `NULL` (la empresa propia).

### 1.2 Convenciones del esquema NG que respeto (verificadas)
| Convención | Evidencia | Cómo la aplico |
|---|---|---|
| `varchar` por omisión; Unicode columna por columna (ADR-50) | `EmpresaNgDbContext.cs:178` (`AreUnicode(false)`) | Todo `varchar`. Los nombres con tilde caben en la página 1252 |
| Sin borrado en cascada | `EmpresaNgDbContext.cs:186` | Todas las FK `NO ACTION` |
| Llave de rango del nodo para lo que se crea en un nodo (MD-36) | `Datos/Empresa/SecuenciasNodo.cs:14-19` | El ticket y el reverso toman `doc.SecDocumento`; el libro de saldos usa una **secuencia nueva** `com.SecMovimiento` (14.ª de la lista) |
| `rowversion` en maestros y filas con concurrencia | `DocConfiguracion.cs:118`, `NumConfiguracion.cs:48` | `Version rowversion` en todo maestro y en `com.Saldo` |
| Fechas UTC del motor (RD-10), `datetime2(3)` | `DocConfiguracion.cs:96`, `Infraestructura/HoraLocal.cs:3-9` | `…En datetime2(3)` en UTC; las fechas de negocio (`FechaServicio`) en `date` local |
| Hora del servidor protegida | `Infraestructura/Reloj/RelojProtegido.cs:11-23` | La franja se compara con `IRelojProtegido.Ahora()` llevado a la hora local; nunca con la hora del equipo |
| Historia de maestros con tablas temporales | `MaeConfiguracion.cs:144-149` (`cat.Articulo`) | Franjas, coberturas, composición, parámetros de la vertical y montos: `SYSTEM_VERSIONING` |
| Búsqueda sin tildes con clave binaria | `MaeConfiguracion.cs:124`, `:157-161` (`Latin1_General_100_BIN2_UTF8`) | `com.Comensal.NombreClave` con la misma intercalación y el mismo `CHECK` de forma |
| Bitácora solo inserción (`audit.Bitacora`, el `_LOG` del modelo nuevo) | `Dominio/Configuracion/Bitacora.cs:3-8`; `SqlMigracionesCfg.cs:15` | Cambios de padrón, foto, carné, beneficios, modo fiscal y excepciones |
| **RG-14 D-04 (a):** ninguna tabla con 2 o más columnas calculadas lleva índices filtrados | `traspasos/A/precision-rg14-d04-indice-2026-10-15.md` (firmada hoy) | **Ninguna tabla nueva tiene columnas calculadas.** Los saldos se guardan, no se calculan. Así los índices filtrados que propongo son legales con cualquier versión del motor. No agrego índices a `doc.Documento` (2 calculadas, `DocConfiguracion.cs:94`, `:121`) ni filtrados a `ventas.Venta` |

### 1.3 Volumen de diseño (inferido, ±50 %)
- Comensales: 300 (caso de cálculo) a 2.000 por empresa.
- **150 comidas por franja y por sede** (encargo), 2 franjas de comida + consumos sueltos: **unos 500 a 700 tickets por sede y día**, 3 líneas por ticket.
- Por sede y año (260 días): ≈ 180.000 tickets, ≈ 540.000 líneas, ≈ 400.000 movimientos de saldo.
- Tamaño (inferido): ≈ 1,1 KB por ticket con sus líneas, pagos, documento, movimientos e índices → **≈ 200 MB por sede y año**. Fotos: 2.000 × 45 KB ≈ **90 MB** en total.
- **Costo:** con SQL Server Express (tope de 10 GB por base) una empresa de 2 sedes llena el 4 % del tope por año; no hay costo de licencia nuevo. Una empresa con 5 sedes llegaría al tope en unos 9 años, antes que el plazo de conservación de 10 años (MD-61): se le debe recomendar Standard o un archivado (riesgo R-06).

---

## 2. Tablas y relaciones

### 2.1 Dos esquemas nuevos (FD-01)
| Esquema | Contenido | Quién lo usa |
|---|---|---|
| **`com`** («comensales», capacidad común de H-02 (a)) | Padrón, categorías, centros de costo con vigencia, carnés, foto, montos por categoría y por persona, **saldos con `UPDATE` condicional**, uso del beneficio por franja y su libro de movimientos | `CORPORATIVA` y `CARGO_EMPRESA` (modelo B). Ninguna referencia a `res` ni a `corp` (ADR-112, punto 6) |
| **`corp`** (vertical Corporativa) | Parámetros, sedes, franjas por artículo, composición del almuerzo y la cena, cobertura de la bolsa, ticket interno y su reverso, pagos, corte de nómina y la **costura fiscal** | Solo `CORPORATIVA` |

*Alternativas descartadas:* todo en un esquema (`corp`), porque obliga al restaurante a leer un esquema de otra vertical; el padrón en `res.ClienteEmpleado` ([CE] CE-04), porque la Estándar no puede depender de `res` ([HF] 6.1); el padrón en `rrhh` (2.3).

Las tablas existen en toda base de empresa, vacías si no se usa el módulo (ADR-112, punto 5).

### 2.2 Mapa
```
com.Categoria ─┐                    com.CentroCosto
               ├─< com.ComensalAsignacion >─┘   (vigencia: categoría, centro de costo, sede de referencia)
com.Comensal ──┤
   │ ├─ rrhh.Empleado (0..1, opcional)          cat.Cliente (0..1, solo modelo B)
   │ ├─< com.Carne            (uno activo por comensal; identificador como HMAC)
   │ ├── com.ComensalFoto     (1:0..1; cifrada en la aplicación)
   │ ├─< com.MontoComensal    (excepción por persona, con vigencia)
   │ ├─< com.Saldo            (bolsa mensual BM, cupo de nómina CN; reservados para B: TD, TP)
   │ │     └─< com.SaldoMovimiento (libro, solo inserción)
   │ └─< com.UsoBeneficio     (almuerzo/cena al 100 %: uno por comensal, fecha de servicio y franja)
com.Categoria ─< com.MontoCategoria (bolsa y cupo por categoría, con vigencia)

corp.Parametros (1 fila)    corp.Sede (por org.Sucursal)    corp.FormaPagoHabilitada
corp.Franja (por sede) ─< corp.ArticuloFranja >─ cat.Articulo
          └─< corp.ComposicionGrupo ─< corp.ComposicionArticulo >─ cat.Articulo
          └─< corp.CategoriaFranja >─ com.Categoria
corp.ArticuloCobertura (1:0..1 con cat.Articulo; sin fila = 100 %)

doc.Documento (TCI) ── corp.Consumo ─< corp.ConsumoLinea
                                    └─< corp.ConsumoPago
doc.Documento (RCI) ── corp.Reverso ─< corp.ReversoLinea     (enlazado a corp.Consumo; doc.LineaSaldo clase 'I')
corp.ConsumoComprobante ─< corp.ConsumoComprobanteLinea  (costura fiscal → ventas.Venta / E32 o E34)
corp.CorteNomina (por período)
```

### 2.3 Padrón y su relación con `rrhh.Empleado` (FD-02)
**Decisión propuesta:** padrón propio `com.Comensal`, con un enlace **opcional y único** `EmpleadoId` → `rrhh.Empleado`.

**Por qué no usar `rrhh.Empleado` como padrón** (verificado en [NG] `Dominio/Configuracion/Personas.cs:11-31` y `Datos/Empresa/Configuracion/CfgConfiguracion.cs:253-280`):
1. `rrhh.Empleado` es el personal y los vendedores del POS (MD-30), con comisiones y selectores; 2.000 comensales los inundarían.
2. En el modelo B los comensales son empleados **de un cliente** del restaurante: no pueden ser `rrhh.Empleado` de la base del restaurante.
3. `rrhh.Empleado` guarda la cédula (`CK_Empleado_Cedula`, `:259`); la hoja prohíbe guardarla para el comensal (H-08 (a)). El padrón no la tiene y ninguna vista `rpt` une el enlace con la cédula.
4. El personal de servicio (contratistas) tampoco es empleado de la empresa.

**Para qué sirve el enlace:** un ejecutivo que además es vendedor o usuario del sistema, sin duplicar la persona. Es opcional; la llave operativa es el **código de nómina** (`Codigo`), inmutable y nunca reutilizado ([POS] 7).

### 2.4 Categorías y centros de costo con vigencia
- `com.Categoria`: catálogo de la empresa con una **clase fija** (`E` empleado, `X` ejecutivo, `S` servicio, F-03). La empresa crea las que quiera («Empleado nocturno», clase `E`).
- `com.CentroCosto`: código, descripción, `CodigoErp` opcional y `EsExterno` (la organización externa del personal de servicio, [POS] F-03).
- `com.ComensalAsignacion`: **una fila por cambio** (`ComensalId`, `VigenteDesde`) con categoría, centro de costo, sede de referencia y departamento. La vigente a una fecha es la de `VigenteDesde` máximo ≤ fecha (búsqueda por la PK). El ticket **congela** la categoría y el centro de costo ([POS] 7).
- *Alternativa descartada:* `VigenteDesde`/`VigenteHasta` con solapes que validar; la fila siguiente cierra la anterior y no hay solape posible.

### 2.5 Carné (H-08 (a)) (FD-04)
- `com.Carne` guarda el identificador **como HMAC-SHA-256** con una llave por empresa protegida con Data Protection (`IdentificadorHmac binary(32)`, único), más los últimos 4 caracteres para la pantalla. La lectura calcula el HMAC y busca por el índice único: una sola búsqueda.
  - Motivo: el identificador de un carné de proximidad (UID) se clona con el dato; si la base se filtra, el HMAC no sirve para clonar. Costo: un HMAC por lectura (microsegundos).
  - *Alternativa descartada:* el identificador en claro (riesgo de clonación con una copia de la base); cifrado reversible (no hace falta descifrarlo nunca).
- Tecnología: `Q` QR, `R` RFID 125 kHz, `M` Mifare (UID), `B` código de barras.
- Estados: `A` activo, `B` bloqueado, `P` perdido, `R` reemplazado, `V` vencido ([POS] 7). **Un solo activo por comensal** (índice único filtrado). Un carné reemplazado **nunca vuelve** a activo (disparador). El identificador nunca se reutiliza (índice único sin filtro).
- `VenceEn` para el personal de servicio.

### 2.6 Foto (H-08 (a)) (FD-03; la revisa el auditor-seguridad)
**Propuesta:** dentro de la base de empresa, en una **tabla aparte** `com.ComensalFoto` (1:0..1), con el contenido **cifrado en la aplicación**:
- **AES-256-GCM con la construcción de ADR-67, punto 3** (DEK por foto, envuelta con la KEK de la empresa, sitio y versión). Una sola construcción criptográfica en el código y válida en el perfil FIPS (AES-GCM es un algoritmo aprobado).
- JPEG reducido a 300 × 400 px (30 a 50 KB) antes de cifrar. `Huella` = SHA-256 del texto cifrado; `VersionFoto` sube en cada cambio. El ticket guarda `VersionFoto` (qué foto vio el cajero), no la imagen.
- **Una sola foto vigente:** cambiarla sobrescribe el contenido; no hay historial de fotos.
- **Borrado a los 90 días de la baja:** `DELETE` físico por el proceso de retención (único `DELETE` concedido en `com`), con una línea en la bitácora sin la imagen. Ninguna FK apunta a la foto, así que cumple la precisión de ADR-08 (sin referencias).
- **Fuera de todo reporte:** ninguna vista `rpt` ni `rptc` la lee (CA-13); los roles de lectura tienen `DENY` sobre `com` (sección 9).

| Opción | Pro | Contra | Decisión |
|---|---|---|---|
| **Base, tabla aparte, cifrado en la app** | Atómica con el padrón; viaja en el respaldo y al nodo con el mismo canal; 90 MB = 0,9 % del tope de Express | Los respaldos conservan la foto borrada hasta que vencen (dato para el auditor) | **Recomendada** |
| Almacén de adjuntos de ADR-67 (fuera de la base) | Reutiliza la papelera y la cuota | ADR-67, punto 2, ancla todo adjunto a un **documento emitido**; la foto no lo es: exigiría precisar ADR-67. Un archivo por comensal en otra unidad para servirlo en < 1 s | Descartada |
| TDE o `ENCRYPTBYKEY` en el motor | Sin código de cifrado | TDE no existe en Express; con `ENCRYPTBYKEY` las llaves viven en la misma base y el DBA descifra | Descartada |

### 2.7 Beneficios
| Pieza | Tabla | Regla firmada |
|---|---|---|
| Franja por artículo (PF-1, F-1) | `corp.Franja` (por sede: hora de inicio y fin, días de la semana) y `corp.ArticuloFranja` (artículo × franja) | Un artículo **con al menos una franja en la sede** solo se vende dentro de alguna de ellas; sin filas en esa sede, se vende a toda hora (FD-07). Igual para empleado y visitante. Tolerancia 0. Una franja que cruza la medianoche (`HoraFin < HoraInicio`) se asigna a la **fecha de inicio** (R-H1) |
| Cobertura de la bolsa (F-2) | `corp.ArticuloCobertura` (`Porcentaje` 0, 50 o 100; **sin fila = 100**) | FD-05: `CHECK IN (0, 50, 100)`, la lista firmada. Ampliarla a 0..100 es una migración trivial |
| Almuerzo y cena al 100 % (H-05 (a)) | `corp.Franja.EsComida = 1`; `corp.ComposicionGrupo` (grupo y cantidad) y `corp.ComposicionArticulo` (qué artículos admite cada grupo) | FD-06: un artículo está en **un solo grupo** por franja, y una línea del ticket **entra completa o no entra** (el servidor parte la línea de 2 jugos en 1 + 1). Así el reparto es determinista y se comprueba con un `CHECK` |
| Qué franjas al 100 % tiene cada categoría (B-5, H-06) | `corp.CategoriaFranja` | El doble turno se resuelve por categoría |
| Una vez por franja y por día (H-06 (a)) | `com.UsoBeneficio` con índice **único** filtrado (`ComensalId`, `FechaServicio`, `FranjaId`) sobre los usos no revertidos | Sección 4 |
| Bolsa mensual (F-3, PF-3, H-07) | `com.MontoCategoria` (concepto `BM`), `com.MontoComensal` (excepción), `com.Saldo` (concepto `BM`, `Desde` = día 1) | 2.8 |
| Cupo de nómina (PF-4) | `com.MontoCategoria` y `com.MontoComensal` (concepto `CN`); `com.Saldo` (concepto `CN`, `Desde`/`Hasta` = el período de nómina) | **Sin monto configurado para la categoría ni excepción, no se ofrece la nómina** (PF-4): no hay fila de saldo `CN` |

### 2.8 Bolsa: monto, renovación y alta proporcional (FD-13)
- **Monto del mes** = el de `com.MontoComensal` vigente el día 1, si existe; si no, el de `com.MontoCategoria` de la categoría vigente el día 1 (A-B1).
- **Renovación (PF-3):** la fila del mes nuevo nace con `LimiteInicial` = el monto del mes, `Usado = 0`. **No se le suma el sobrante.** El mes anterior no se cierra con una escritura: un saldo de un mes pasado ya no admite consumo porque la condición del `UPDATE` exige el período vigente; lo perdido es `LimiteInicial + Ajustes − Usado` de ese mes, y lo calcula la vista (RC-02).
- **Quién crea la fila:** el proceso idempotente «Asegurar bolsas del mes» (`INSERT … WHERE NOT EXISTS` sobre la PK) para todos los comensales activos, al arrancar la API y cada día a las 00:05 del servidor; y, como respaldo, la propia transacción del ticket si no la encuentra. Repetirlo no cambia nada (CA-10). *Alternativa descartada:* un cierre que escribe el día 1 (AT-8 de [POS]); si el nodo estaba apagado hay que recuperar el cierre, y con la regla del período vigente no hace falta.
- **Alta a mitad de mes (H-07 (a)):** `LimiteInicial = ROUND(monto × DiasDerecho / DiasMes, 2)`, con `DiasDerecho = DiasMes − día de alta + 1` (alta el 16 de un mes de 30 = 15/30 = 50 %). `DiasMes` y `DiasDerecho` se guardan en la fila para explicar el monto.
- **Baja:** desde `FechaBaja` el comensal no está activo y el servidor no consume su bolsa (R-E2); lo consumido no se reclama.
- **Ajustes manuales** (con motivo, [CONT] 6.4): suman o restan en `Ajustes` y dejan una fila `A` en el libro.

### 2.9 Documentos
| Documento | Supertipo | Extensión |
|---|---|---|
| **Ticket de consumo interno** (H-03 (a)) | `doc.Documento`, tipo nuevo `TCI`, familia nueva `CIN`, `LlevaNcf = 0`, `AfectaInventario = -1` | `corp.Consumo`, `corp.ConsumoLinea`, `corp.ConsumoPago` |
| **Reverso de consumo** (F-04; no es nota de crédito) | `doc.Documento`, tipo `RCI`, familia `CIN`, `AfectaInventario = 1` | `corp.Reverso`, `corp.ReversoLinea`, y sus pagos en `corp.ConsumoPago` con montos negativos |

- **Serie propia sin huecos (CA-06):** `num.Serie` de clase `DOC` con `TipoCodigo` `ConsumoInterno` y `ReversoConsumo`, **por sucursal** (`SucursalId`), con prefijo propio (por omisión `CI` y `RC`). La toma del número es la de ADR-45 (fila de la serie bloqueada dentro de la transacción del ticket): un fallo deshace también el número, así que no hay huecos ([NG] `NumConfiguracion.cs:24-68`). Nunca toma un número de `fiscal.SecuenciaNcf`: el tipo no lleva NCF y el disparador de emisión no lo pide (`LlevaNcf = 0`).
- **Por qué un tipo de documento del supertipo:** reutiliza la numeración, el `Uid` y la `HuellaSolicitud` (idempotencia, K-58), la inmutabilidad del emitido (`TR_Documento_Inmutable`, [NG] `SqlMigracionesOla3.cs:83-98`), la guarda de restauración (51330) y el índice por tipo y fecha. **Por qué no en `ventas.Venta`:** el ticket no es una venta ([CONT] 6.4); en `ventas` entraría en los resúmenes del Z por `FPOS`/`DEV` ([NG] `Consultas/Caja/ConsultasCaja.cs:160-207`) y en las vistas de ventas.
- **Familia nueva `CIN`** (FD-08): amplía `CK_TipoDocumento_Familia` ([NG] `DocConfiguracion.cs:17`). *Alternativa:* familia `INV`, más barata, pero mezcla los tickets con los documentos de inventario en los filtros por familia.
- **Ids de tipo:** el último sembrado en `feature/modelo-ng` es el 30 (`SqlMigracionesOla4.cs:73`). Propongo **40 (`TCI`) y 41 (`RCI`)**, para dejar 31 a 39 a la ola 3b y a las verticales de B; se confirman con B al construir.
- **Precio completo:** la línea guarda el precio de lista, su ITBIS informativo y el total; los beneficios son **formas de liquidación**, no descuentos (R-P3). El reparto se hace sobre el **total de la línea** (lo que ve el comensal).
- **Costo congelado** por unidad base, como `ventas.VentaLinea.CostoUnitario` ([NG] `VenConfiguracion.cs:116`).

### 2.10 Reparto por línea
Cada línea de `corp.ConsumoLinea` lleva tres importes cuya suma es su total (`CK_ConsumoLinea_Reparto`):
- `MontoBeneficio`: 0 o el total (entra completa en la composición de la franja, FD-06);
- `MontoBolsa`: entre 0 y `PorcionBolsa` (= `ROUND(Total × CoberturaPorcentaje / 100, 2)`, guardada);
- `MontoEmpleado`: el resto.

El encabezado guarda las sumas y el `CHECK` del encabezado más el disparador de emisión comprueban que cuadran. El pago de `MontoEmpleado` se reparte en `corp.ConsumoPago` por medio: `D` dinero (efectivo o tarjeta, con `FormaPagoId` habilitada en `corp.FormaPagoHabilitada`) y `N` nómina (con el período). Combinables (F-4).

### 2.11 Vínculo con la factura del visitante
El visitante **no toca `corp`**: su factura es una `FPOS` normal por la ruta única (F-02), con la lista de precios de visitante de `corp.Sede`. Lo único que la une a la vertical es la caja y la jornada. Un empleado que pide factura con NCF por una compra se atiende igual, sin `ComensalId` ([POS] F-02). **No hay tabla de vínculo**: no hace falta.

### 2.12 La costura fiscal (H-04 abierta; no elijo opción) (FD-09, FD-10)
Lo que el modelo deja listo para **P-0, S-1, S-2 y S-6** sin migrar de nuevo:

| Pieza | Para qué |
|---|---|
| `corp.Parametros.ModoFiscalPorcion char(2) NULL` con `CHECK IN ('P0','S1','S2','S6')`, tabla temporal (historia de cada cambio) y una línea en la bitácora con el motivo. La cambia **solo el SUPER** (lo exige la API; la base deja la historia) | El valor que firme el propietario |
| `corp.Consumo.ModoFiscal` (congelado al emitir; `NULL` si el ticket no tiene dinero del empleado) | Saber qué régimen tuvo cada ticket. «Encenderla no corrige el pasado» ([HF] 5.3) queda visible |
| `corp.ConsumoComprobante` (ticket o reverso → documento de `ventas`: E32, o E34 en el reverso) y `corp.ConsumoComprobanteLinea` (qué línea del ticket ampara cada línea del e-CF y por cuánto) | S-1 (1 ticket : 1 E32, con índice único filtrado) y S-2 (N tickets : 1 E32 global por caja y día) con la misma tabla |
| `corp.ConsumoLinea.ImpuestoId`, `PorcentajeImpuesto`, `Importe`, `Impuesto` (congelados) | Construir la E32 **solo por la porción pagada**: base e ITBIS de `MontoEmpleado` línea por línea, con el redondeo en la porción pagada ([CONT] D-04) |
| `ventas.Venta.InventarioDescargadoPorId bigint NULL` → `doc.Documento` (columna nueva del núcleo, genérica) | La marca «inventario ya descargado por el ticket»: la E32 no vuelve a mover el kárdex. **La misma marca que necesita el Restaurante** (ADR-112, consecuencias: «la ruta única necesita la marca “inventario ya descargado por la orden”»). Se diseña una vez con B (FD-10) |

**Valor `NULL` = sin definir (FD-09):** con `NULL`, el servidor **rechaza** el ticket con dinero del empleado (`MontoEmpleado > 0`) y admite los totalmente subsidiados. Es una falla cerrada que obliga a fijar H-04 antes del primer cliente, como recomienda [HF] 5.3, **sin elegir ninguna opción**; en desarrollo el SUPER pone el valor que pruebe. Con `S6`, el ticket con dinero del empleado también se rechaza. *Alternativa descartada:* `P0` por omisión, que equivale a elegir P-0.

Qué hace cada valor (lo construye el arquitecto-software en la extensión; el dato es el mismo):
- `P0`: nada más; el ticket ampara todo.
- `S1`: en la misma transacción, una `FPOS` E32 con el cliente genérico solo por `MontoEmpleado`, enlazada en `corp.ConsumoComprobante`, con `InventarioDescargadoPorId` = el ticket. En el reverso, una E34 enlazada al reverso.
- `S2`: los tickets con `ModoFiscal = 'S2'` sin fila en `corp.ConsumoComprobante` se agrupan al cierre de la caja en una E32 por caja y día.
- `S6`: no hay dinero del empleado.

### 2.13 Salida de inventario al costo de la porción subsidiada
- **El ticket mueve el inventario una sola vez** (ADR-112, punto 10; H-03 (a)): una fila de `inv.Movimiento` por línea inventariable, **clase 5** con el motivo `CONSUMO` (`EsConsumoInterno = 1`, ya sembrado: [POS] [MOT], `database/empresa/gpos-empresa-20261015003000_Rg14RespaldoTope.sql:10617`), `DocumentoId` = el ticket, `Linea` = la línea, al costo promedio vigente. `CK_Movimiento_Ajuste` exige el motivo en la clase 5 ([NG] `InvConfiguracion.cs:84`).
- **Toda la línea sale por la clase 5**, también la porción pagada por el empleado: la unidad física es una. La parte fiscal del retiro se obtiene en la vista (sección 7) con el costo × (beneficio + bolsa) / total de cada línea. Con S-1 la E32 lleva la marca y no mueve el kárdex.
- **Reverso «no se sirvió»:** el movimiento inverso con `MovimientoRevertidoId` (patrón de anulación del kárdex, `InvConfiguracion.cs:120`). **«Sí se sirvió»:** no se toca el kárdex del ticket; se crea un **borrador de merma** (`AJU`, motivo de merma) que confirma el encargado ([POS] F-04).
- Las líneas no inventariables (servicios) no mueven nada.

---

## 3. Restricciones e integridad (resumen; el detalle está en el DDL)

| Regla | Dónde |
|---|---|
| Código del comensal inmutable y único por cliente (`NULL` = empresa propia) | `UQ_Comensal_Codigo` (sin filtro: dos `NULL` chocan, como se quiere) + disparador |
| Un carné activo por comensal; un reemplazado no se reactiva | `UX_Carne_ComensalActivo` + `TR_Carne_Estado` |
| Sin cédula | No hay columna |
| Un almuerzo/cena al 100 % por comensal, fecha y franja | `UX_UsoBeneficio_Franja` (único filtrado) |
| La bolsa y el cupo nunca negativos | `CK_Saldo_Limite` (`Usado <= LimiteInicial + Ajustes`) + `UPDATE` condicional |
| Reparto de cada línea = su total; beneficio 0 o total; bolsa ≤ su porción | `CK_ConsumoLinea_*` |
| F-5: el saldo impreso es el real | `CK_Consumo_Bolsa` (`BolsaDespues = BolsaAntes − MontoBolsa`) y la regla 51811 del disparador de emisión (`BolsaDespues` = saldo de `com.Saldo` en la misma transacción) |
| Pagos = dinero del empleado; nómina con período abierto y cupo | Disparador de emisión (51812, 51813) |
| Medio de pago habilitado por la empresa (F-4) | Disparador (51814) contra `corp.FormaPagoHabilitada` y `corp.Parametros.NominaHabilitada` |
| Modo fiscal sin definir o `S6` con dinero del empleado | Disparador (51815) |
| Identidad confirmada antes de emitir (CA-01) | `CK_Consumo_Identidad` (`IdentidadConfirmadaPor` y `En` obligatorios con comensal) |
| Reverso: autoriza otra persona (ADR-68) | `doc.Autorizacion` tipo nuevo `REVERSO_CONSUMO` (amplía `CK_Autorizacion_Tipo`, `DocConfiguracion.cs:132-137`) + disparador (51820: el autorizador no es el creador) |
| Reverso parcial: no se revierte más de lo consumido | `doc.LineaSaldo` con la **clase nueva `I`** (amplía `CK_LineaSaldo_Clase`, `DocConfiguracion.cs:158`): el contador atómico que ya usan las devoluciones |
| La bolsa de un mes pasado no se reabre | 51821: un reverso de un consumo de otro mes devuelve `MontoBolsa = 0` |
| Corte de nómina cerrado inmutable | `TR_CorteNomina_Cerrado` (51830) |
| Vale de contingencia único por sede | `UX_Consumo_Vale` (único filtrado) |

Rango de errores propuesto: **51800 a 51849** (no aparece en `feature/modelo-ng`, verificado con `grep 518` en las migraciones; confirmar con B).

---

## 4. Concurrencia e idempotencia (dos cajas a la vez y el reintento)

### 4.1 Orden de bloqueos (FD-11, precisión de ADR-45)
Dentro del nivel «saldos» ([NG] `docs/adr/ADR-045.md:61`), después de crédito → cuenta → saldo del cliente: **`com.UsoBeneficio` (inserción) → `com.Saldo` BM → `com.Saldo` CN**, en orden de llave. La serie del ticket se toma antes, en el nivel de documentos, como en la venta.

### 4.2 «Una vez por franja» (CA-03)
La transacción del ticket **inserta** la fila de `com.UsoBeneficio` antes de calcular nada que dependa de ella. Dos cajas con el mismo comensal: la segunda espera el bloqueo de la llave del índice único y, al confirmar la primera, recibe el error 2601. El servicio lo traduce en «Ya almorzó a las 12:14 en la Caja 2» y **no reintenta solo** (AT-9): devuelve el reparto nuevo (sin el 100 %) para que el cajero lo confirme. No hay lectura previa con carrera: la garantía es el índice.

### 4.3 Saldo de la bolsa y del cupo (CA-04, F-5)
**Guarda optimista con el saldo que vio el cajero:**
```sql
UPDATE com.Saldo
   SET Usado = Usado + @monto
 OUTPUT deleted.LimiteInicial + deleted.Ajustes - deleted.Usado  AS Antes,
        inserted.LimiteInicial + inserted.Ajustes - inserted.Usado AS Despues
 WHERE ComensalId = @c AND Concepto = 'BM' AND Desde = @periodoVigente
   AND Usado = @usadoVisto                          -- el saldo que se le mostró al cajero
   AND Usado + @monto <= LimiteInicial + Ajustes;   -- respaldo: nunca negativo
```
- Si devuelve 0 filas, otra caja consumió esa bolsa entre la cotización y la emisión: el ticket se deshace entero (sin número, sin marca, sin kárdex: CA-07) y la API responde 409 con el reparto nuevo. **El «antes» y el «después» que se imprimen salen del `OUTPUT`**, así que coinciden con el saldo real (F-5), y el disparador lo comprueba (51811).
- Con 2 cajas por cada 300 comensales ([POS] 1), que un mismo comensal esté en dos cajas a la vez es una excepción (R-D3, posible clonación): la guarda optimista no penaliza el caso normal.
- *Alternativa descartada:* `UPDLOCK` en la cotización (retiene el saldo mientras el cajero cobra con tarjeta: decenas de segundos).

### 4.4 Reintento (AT-2)
- La caja genera el `Uid` del documento antes del primer envío; `UQ_Documento_Uid` y `HuellaSolicitud` (K-58) devuelven el ticket ya emitido con la misma llave, o 409 si cambió el contenido ([NG] `DocConfiguracion.cs:117-120`, `:65`).
- El reintento de un ticket ya emitido **no vuelve a consumir** la bolsa: la transacción entera no se ejecuta.
- Tarjeta autorizada y emisión fallida: procedimiento de la Estándar (`REVERSO_TARJETA`), sin cambio.

### 4.5 Consulta del saldo vigente al validar el carné (F-5)
Tres búsquedas por llave, sin recalcular el mes (≤ 1 ms cada una, inferido):
1. `com.Carne` por `UQ_Carne_Identificador` → comensal y estado;
2. `com.Saldo` por la PK (`ComensalId`, `'BM'`, día 1 del mes) y (`'CN'`, período vigente);
3. `com.UsoBeneficio` por `UX_UsoBeneficio_Franja` (`ComensalId`, hoy) → franjas ya usadas, con la hora y la caja del ticket.

Si la fila de la bolsa del mes no existe todavía, el saldo es el monto del mes (2.8) y se crea en el ticket.

### 4.6 Lo que el ticket imprime (F-5)
`corp.Consumo` guarda, **inmutables**: `BolsaAntes`, `BolsaDespues`, `CupoNominaAntes`, `CupoNominaDespues`, `EstadoBeneficio` (`U` usado en este ticket, `Y` ya usado antes, `N` no aplica) y `BeneficioPrevioId` (el ticket que lo usó). La reimpresión lee esas columnas, nunca el saldo actual. El reverso guarda su propio antes y después.
- **Cupo de nómina en el ticket (FD-12):** parámetro `corp.Parametros.MostrarCupoNomina`, **sí por omisión** cuando la nómina está habilitada: el ticket es del propio comensal y le evita pasar el cupo sin saberlo. El dato se guarda siempre; el parámetro solo decide si se imprime.

---

## 5. Sin conexión (H-10 (a))

Hoy una sucursal en línea sin internet no vende (ADR-53) y los nodos llegan en la entrega 2. Para una sede **con nodo**:

| Dirección | Qué viaja | Prioridad |
|---|---|---|
| Central → nodo | **Bloqueos y bajas:** `com.Carne.Estado`, `com.Comensal.Estado` | **Alta** (R-O4) |
| Central → nodo | Padrón de los comensales de la sede de referencia y de los que consumen allí: `com.Comensal`, `com.ComensalAsignacion`, `com.Categoria`, `com.CentroCosto`, montos | Normal |
| Central → nodo | `com.ComensalFoto` cifrada; **la DEK se envuelve de nuevo para la KEK del nodo** (como ADR-67, punto 9, en sentido inverso) | Baja, por trozos |
| Central → nodo | La llave HMAC del carné, envuelta para el nodo (sin ella el nodo no resuelve carnés) | Alta, una vez |
| Central → nodo | `corp.Parametros` (incluido el modo fiscal), `corp.Sede`, `corp.Franja`, `ArticuloFranja`, `Composicion*`, `CategoriaFranja`, `ArticuloCobertura`, `FormaPagoHabilitada`, listas de precios | Normal |
| Central ↔ nodo | **`com.Saldo` del comensal:** lo escribe solo el **sitio de la sede de referencia** (dueño, cláusula 2 de ADR-53); la central recibe sus movimientos (`com.SaldoMovimiento`), no sobrescribe el saldo | — |
| Nodo → central | Tickets y reversos (documento, extensión, líneas, pagos), `com.UsoBeneficio`, `com.SaldoMovimiento`, `inv.Movimiento`, bitácora | Normal |

- **Fuera de su sede, sin conexión entre nodos (R-O3):** el 100 % sí, con la marca local; **bolsa no**; el resto con dinero. La conciliación marca los usos duplicados como excepción (`com.UsoBeneficio.Excepcion = 1`, fuera del índice único) sin revertir lo servido.
- **Contingencia en papel (sede sin nodo):** el lote se digita con privilegio como tickets con `Origen = 'L'` en `corp.Consumo`, el número del vale (`ValeNumero`, único por sede) y la fecha real (`doc.Documento.Fecha` anterior con la autorización `FECHA_ANTERIOR` que ya existe). Si un vale choca con una regla (almuerzo ya usado), entra con `Excepcion = 1` y sale en RC-05; no se rechaza (R-O5).
- La SQLite local de la sucursal en línea (después de las olas) necesita el mismo subconjunto (R-O6).

---

## 6. Índices y consultas que los justifican

Carga de diseño: 150 comidas por franja y sede; pico de 5 tickets por minuto por cada 300 comensales ([POS] 1). Por ticket se escriben ≈ 20 entradas de índice (documento 5, extensión 3, líneas 3 × 1, pagos 1, uso 2, saldo 1, libro 2, kárdex 3): a 5 tickets por minuto es carga despreciable; el cuello sigue siendo la serie retenida (≈ 6 ms por emisión, ADR-45, precisión de T-28), y la serie es **por sede**.

| Índice | Consulta | Costo de escritura |
|---|---|---|
| `UQ_Carne_Identificador (IdentificadorHmac)` | Lectura del carné (F-01 paso 2), < 1 s p95 | 1 por carné emitido |
| `UX_Carne_ComensalActivo (ComensalId) WHERE Estado = 'A'` | Integridad + «carné vigente» de la tarjeta | Igual |
| `UQ_Comensal_Codigo (ClienteId, Codigo)` | Identificación sin carné por código (F-08) e importación por plantilla | Alta y cambios del padrón |
| `IX_Comensal_NombreClave (NombreClave) INCLUDE (Codigo, Estado)` | Búsqueda por nombre sin tildes (F-08) | Igual |
| `UX_Comensal_Empleado (EmpleadoId) WHERE EmpleadoId IS NOT NULL` | Integridad del enlace 0..1 | Mínimo |
| PK `com.Saldo (ComensalId, Concepto, Desde)` | Saldo vigente (4.5) y `UPDATE` condicional (4.3) | 1 por ticket con bolsa |
| `UX_UsoBeneficio_Franja (ComensalId, FechaServicio, FranjaId) WHERE ReversoDocumentoId IS NULL AND Excepcion = 0` | «Una vez por franja» (4.2) y «ya almorzó» (4.5) | 1 por almuerzo/cena |
| `IX_SaldoMovimiento_Periodo (Concepto, Desde, ComensalId) INCLUDE (Monto, Tipo, DocumentoId)` | Corte de nómina (RC-03) y detalle de la bolsa del mes (RC-02) | 1 a 2 por ticket |
| `IX_Consumo_Comensal (ComensalId, FechaServicio) INCLUDE (Total, MontoBeneficio, MontoBolsa, MontoEmpleado, ModoIdentificacion)` | RC-01; límite de 3 identificaciones sin carné por mes (F-08); estado de cuenta del comensal | 1 por ticket |
| `IX_Consumo_Jornada (JornadaId) INCLUDE (MontoBeneficio, MontoBolsa, MontoEmpleado, MontoNomina)` | Bloques del Z de la Corporativa (CA-08), por el patrón de rango de la jornada ([NG] `ConsultasCaja.cs:152-156`) | 1 por ticket |
| `UX_Consumo_Vale (SucursalId, ValeNumero) WHERE ValeNumero IS NOT NULL` | Un vale de contingencia no se digita dos veces | Solo en contingencia |
| `UX_ConsumoComprobante_S1 (VentaDocumentoId) WHERE Modo = 'S1'` y `IX_ConsumoComprobante_Venta (VentaDocumentoId)` | Del e-CF al ticket (auditoría, E34 del reverso) | Solo con S-1/S-2 |
| `IX_ArticuloFranja_Franja (FranjaId)` | Botonera de la franja (artículos de la franja vigente) | Configuración |

**Sin índice nuevo** para RC-04, RC-06 y el retiro al costo: recorren el período por `IX_Documento_TipoFecha (TipoDocumentoId, Fecha) INCLUDE (Estado, SucursalId)` ([NG] `DocConfiguracion.cs:123-124`) y unen por la PK de `corp.Consumo` y de `corp.ConsumoLinea`. Con ≈ 15.000 tickets por sede y mes, es un rango contiguo (inferido < 200 ms). Sin índice especulativo por centro de costo: se agrega solo si la medición lo pide.

---

## 7. Reportes de origen: vistas mínimas

Siguen ADR-109 (`rpt` general, `rptc` con costos o datos personales; los lee solo `gpos_lectura`). **Ninguna lee `com.ComensalFoto` ni la cédula (CA-13).** Las que muestran personas van en `rptc`, para que el perfil del tercero (que no tiene el privilegio de esas vistas) no las vea ([POS] 9).

| Vista | Reporte | Grano |
|---|---|---|
| `rptc.CorpConsumoEmpleado` | RC-01 consumo por empleado | Línea del ticket (y del reverso, con signo) |
| `rptc.CorpBolsaMes` | RC-02 bolsa frente al tope | Comensal × mes: asignado, ajustes, usado, **perdido**, almuerzos y cenas tomados |
| `rptc.CorpCorteNomina` | RC-03 corte de nómina | Comensal × período de nómina, con el estado del corte |
| `rpt.CorpLiquidacionAdministrador` | RC-06 liquidación al administrador (sin personas) | Sede × fecha × franja: comidas al 100 %, importes de beneficio, bolsa y dinero, reversos |
| `rptc.CorpRetiroCosto` | Retiro al costo para el IT-1 (apoyo; el IT-1 sigue aplazado al ERP) | Mes × sede × centro de costo: costo de lo servido y **costo de la porción subsidiada** |

RC-04 (por centro de costo) y RC-05 (excepciones) se construyen con las mismas tablas y no piden índices nuevos; quedan para el tramo de reportes.

---

## 8. Respaldo, restauración y retención
- Todo vive en la base de empresa: el respaldo vigente (ADR-65, AES-256-GCM) lo cubre, **fotos incluidas** (cifradas dos veces: en la app y en el respaldo). No hay almacén aparte que respaldar.
- **Restauración:** los tickets son documentos del supertipo: la guarda 51330 bloquea la emisión hasta reconciliar (MD-59). Los saldos se reconstruyen desde el libro si hiciera falta: `Usado = SUM(com.SaldoMovimiento.Monto)` por saldo (comprobación de cuadre propuesta para la reconciliación).
- **Retención:** tickets, reversos, libro y cortes: el plazo legal de conservación (MD-61, 10 años por omisión), sin purga. Foto: borrado a los 90 días de la baja. Los respaldos guardan la foto borrada hasta que vencen: **dato para el auditor-seguridad** (Ley 172-13).
- **Corte de nómina:** el archivo exportado se guarda en `corp.CorteNomina.Contenido` con su huella SHA-256, para devolver exactamente el mismo archivo (AT-7). Lleva códigos, nombres y montos (dato personal, sin cédula ni foto).

---

## 9. Privilegios de base de datos

| Cuenta o rol | `com` | `corp` | Motivo |
|---|---|---|---|
| `gpos_app` | `SELECT, INSERT, UPDATE` | `SELECT, INSERT, UPDATE` | Patrón por esquema de [NG] `SqlMigraciones.cs:30-45` |
| `gpos_app`, `DELETE` | Solo `com.ComensalFoto` (retención) | Solo las tablas de configuración sin referencias: `ArticuloFranja`, `ComposicionArticulo`, `ComposicionGrupo`, `CategoriaFranja`, `ArticuloCobertura`, `FormaPagoHabilitada` (su historia queda en la tabla temporal o en la bitácora) | Precisión de ADR-08 |
| `gpos_app`, `DENY UPDATE, DELETE` | `com.SaldoMovimiento`; `com.UsoBeneficio` salvo `GRANT UPDATE (ReversoDocumentoId)` | `ConsumoLinea`, `ConsumoPago`, `ReversoLinea`, `ConsumoComprobante`, `ConsumoComprobanteLinea` | Solo inserción |
| `gpos_app`, `DENY ALTER ON SCHEMA` | Sí | Sí | Como `num` y `sync` |
| `gpos_reportes`, `gpos_lectura` | `DENY` (lo genera `PermisosLecturaReportes` desde `sys.schemas`, [NG] `Migraciones/PermisosLecturaReportes.cs:15-17`) | `DENY` | Leen solo `rpt`/`rptc` por encadenamiento de propiedad |

La migración debe **volver a aplicar** `PermisosLecturaReportes.Sql` al final, para que los esquemas nuevos queden denegados.

---

## 10. Script de migración y reversión (referencia)

### 10.1 Secuencia para la entrega 3 (tramo de la Corporativa, después de 3a)
| # | Migración | Contenido | Datos existentes | Reversión |
|---|---|---|---|---|
| M1 | `CorpComensales` | Esquema `com`, secuencia `com.SecMovimiento` (también en `SecuenciasNodo.Todas`, con el rango del nodo), padrón, categorías, centros de costo, asignación, carné, foto, montos, saldos, uso, libro; permisos | Ninguno: tablas nuevas | `Down` borra los objetos; **se niega (51840) si hay filas** |
| M2 | `CorpConfiguracion` | Esquema `corp`: parámetros (con el modo fiscal en `NULL`), sede, formas habilitadas, franjas, composición, categorías × franja, cobertura (temporales); siembra de la fila única de parámetros | Ninguno | Igual |
| M3 | `CorpDocumentos` | Amplía `CK_TipoDocumento_Familia` (`CIN`), `CK_LineaSaldo_Clase` (`I`) y `CK_Autorizacion_Tipo` (`REVERSO_CONSUMO`); siembra los tipos 40 y 41 y su catálogo de numeración; tablas del ticket, reverso, pagos y corte; disparadores 51810 a 51830 | Las ampliaciones de un `CHECK` son compatibles con las filas actuales (solo agregan valores) | `Down` vuelve a los `CHECK` anteriores **solo si** ninguna fila usa los valores nuevos |
| M4 | `CorpCosturaFiscal` | `ventas.Venta.InventarioDescargadoPorId` (columna `NULL`: cambio de metadatos, instantáneo) y su regla en la emisión; tablas de la costura | `ventas.Venta` con filas: la columna nace `NULL` en todas, sin reescribir la tabla | Se niega si alguna fila tiene valor |
| M5 | `CorpVistasReportes` | Las 5 vistas, el contrato de vistas y la reaplicación de `PermisosLecturaReportes.Sql` | — | `DROP VIEW` |

- **Idempotencia:** como todo el esquema NG, el script idempotente lo genera EF desde las migraciones (MD-07) y los lotes SQL van en `EXEC(N'…')` ([NG] `SqlMigracionesOla3.cs:9`). El DDL de abajo usa `IF … IS NULL` para leerse igual.
- **M4 se coordina con B** antes de construir (la marca la necesita el Restaurante, FD-10). Si B la diseña antes con otro nombre, M4 usa la de B.
- **Bloqueos durante la migración:** M1, M2 y M5 crean objetos nuevos (sin bloqueo de tablas existentes). M3 toma un `Sch-M` breve sobre `doc.TipoDocumento`, `doc.LineaSaldo` y `doc.Autorizacion` al cambiar sus `CHECK` y revalida sus filas (con `WITH CHECK`; cientos de miles de filas en `LineaSaldo`: segundos). M4 toma un `Sch-M` breve sobre `ventas.Venta`. **Se aplica con la API detenida**, como `actualizar` hoy.

### 10.2 DDL de referencia
```sql
------------------------------------------------------------------------- M1 · com
IF SCHEMA_ID(N'com') IS NULL EXEC(N'CREATE SCHEMA com AUTHORIZATION dbo');
IF OBJECT_ID(N'com.SecMovimiento', N'SO') IS NULL
    CREATE SEQUENCE com.SecMovimiento AS bigint START WITH 1000000000000 INCREMENT BY 1
        MINVALUE 1000000000000 MAXVALUE 1999999999999 CACHE 50;   -- rango del nodo 1; «crear --nodo n» lo fija (K-57)

CREATE TABLE com.Categoria (
    Id            smallint IDENTITY CONSTRAINT PK_ComCategoria PRIMARY KEY,
    Codigo        varchar(20) NOT NULL CONSTRAINT UQ_ComCategoria_Codigo UNIQUE,
    Descripcion   varchar(60) NOT NULL,
    Clase         char(1) NOT NULL CONSTRAINT CK_ComCategoria_Clase CHECK (Clase IN ('E', 'X', 'S')),
    PermiteNomina bit NOT NULL CONSTRAINT DF_ComCategoria_Nomina DEFAULT 1,   -- el personal de servicio, 0 ([POS] F-03)
    Inhabilitada  bit NOT NULL CONSTRAINT DF_ComCategoria_Inh DEFAULT 0,
    Version       rowversion);

CREATE TABLE com.CentroCosto (
    Id           smallint IDENTITY CONSTRAINT PK_ComCentroCosto PRIMARY KEY,
    Codigo       varchar(20) NOT NULL CONSTRAINT UQ_ComCentroCosto_Codigo UNIQUE,
    Descripcion  varchar(80) NOT NULL,
    CodigoErp    varchar(30) NULL,
    EsExterno    bit NOT NULL CONSTRAINT DF_ComCentroCosto_Ext DEFAULT 0,
    Inhabilitado bit NOT NULL CONSTRAINT DF_ComCentroCosto_Inh DEFAULT 0,
    Version      rowversion);

CREATE TABLE com.Comensal (
    Id          int IDENTITY CONSTRAINT PK_Comensal PRIMARY KEY,
    ClienteId   bigint NULL CONSTRAINT FK_Comensal_Cliente REFERENCES cat.Cliente (Id),     -- solo modelo B
    Codigo      varchar(30) NOT NULL,                                                       -- código de nómina, inmutable
    Nombres     varchar(60) NOT NULL,
    Apellidos   varchar(60) NOT NULL,
    NombreClave varchar(130) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL,                 -- PA-D-07
    EmpleadoId  int NULL CONSTRAINT FK_Comensal_Empleado REFERENCES rrhh.Empleado (Id),
    Estado      char(1) NOT NULL CONSTRAINT DF_Comensal_Estado DEFAULT 'A'
                CONSTRAINT CK_Comensal_Estado CHECK (Estado IN ('A', 'S', 'B', 'I')),          -- activo, suspendido, de baja, inhabilitado
    SuspendidoHasta date NULL,
    FechaAlta   date NOT NULL,
    FechaBaja   date NULL,
    CreadoPor   varchar(60) NOT NULL,
    CreadoEn    datetime2(3) NOT NULL CONSTRAINT DF_Comensal_Creado DEFAULT SYSUTCDATETIME(),
    ModificadoPor varchar(60) NULL,
    ModificadoEn  datetime2(3) NULL,
    Version     rowversion,
    CONSTRAINT CK_Comensal_Baja CHECK ((Estado = 'B') = (FechaBaja IS NOT NULL) AND (FechaBaja IS NULL OR FechaBaja >= FechaAlta)),
    CONSTRAINT CK_Comensal_Suspension CHECK (Estado = 'S' OR SuspendidoHasta IS NULL),
    CONSTRAINT CK_Comensal_NombreClave CHECK (NombreClave NOT LIKE N'%[^A-Z0-9 Ñ]%' AND CHARINDEX('  ', NombreClave) = 0));
CREATE UNIQUE INDEX UQ_Comensal_Codigo ON com.Comensal (ClienteId, Codigo);                -- sin filtro a propósito
CREATE INDEX IX_Comensal_NombreClave ON com.Comensal (NombreClave) INCLUDE (Codigo, Estado, ClienteId);
CREATE UNIQUE INDEX UX_Comensal_Empleado ON com.Comensal (EmpleadoId) WHERE EmpleadoId IS NOT NULL;

CREATE TABLE com.ComensalAsignacion (
    ComensalId     int NOT NULL CONSTRAINT FK_ComAsig_Comensal REFERENCES com.Comensal (Id),
    VigenteDesde   date NOT NULL,
    CategoriaId    smallint NOT NULL CONSTRAINT FK_ComAsig_Categoria REFERENCES com.Categoria (Id),
    CentroCostoId  smallint NOT NULL CONSTRAINT FK_ComAsig_CentroCosto REFERENCES com.CentroCosto (Id),
    SedeReferenciaId smallint NOT NULL CONSTRAINT FK_ComAsig_Sede REFERENCES org.Sucursal (Id),
    Departamento   varchar(60) NULL,
    AsignadoPor    varchar(60) NOT NULL,
    AsignadoEn     datetime2(3) NOT NULL CONSTRAINT DF_ComAsig_En DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ComensalAsignacion PRIMARY KEY (ComensalId, VigenteDesde));

CREATE TABLE com.Carne (
    Id               int IDENTITY CONSTRAINT PK_Carne PRIMARY KEY,
    ComensalId       int NOT NULL CONSTRAINT FK_Carne_Comensal REFERENCES com.Comensal (Id),
    IdentificadorHmac binary(32) NOT NULL CONSTRAINT UQ_Carne_Identificador UNIQUE,      -- HMAC-SHA-256, llave por empresa
    Ultimos4         char(4) NOT NULL,
    Tecnologia       char(1) NOT NULL CONSTRAINT CK_Carne_Tecnologia CHECK (Tecnologia IN ('Q', 'R', 'M', 'B')),
    Estado           char(1) NOT NULL CONSTRAINT DF_Carne_Estado DEFAULT 'A'
                     CONSTRAINT CK_Carne_Estado CHECK (Estado IN ('A', 'B', 'P', 'R', 'V')),
    EmitidoEn        date NOT NULL,
    VenceEn          date NULL,
    MotivoEstado     varchar(200) NULL,
    CambiadoPor      varchar(60) NULL,
    CambiadoEn       datetime2(3) NULL,
    Version          rowversion,
    CONSTRAINT CK_Carne_Motivo CHECK (Estado = 'A' OR LEN(LTRIM(RTRIM(ISNULL(MotivoEstado, '')))) > 0));
CREATE UNIQUE INDEX UX_Carne_ComensalActivo ON com.Carne (ComensalId) WHERE Estado = 'A';
-- TR_Carne_Estado (51801): R y V no vuelven a A; el identificador y el comensal no cambian.

CREATE TABLE com.ComensalFoto (
    ComensalId  int NOT NULL CONSTRAINT PK_ComensalFoto PRIMARY KEY
                CONSTRAINT FK_ComensalFoto_Comensal REFERENCES com.Comensal (Id),
    Contenido   varbinary(max) NOT NULL,          -- sobre de ADR-67 + JPEG 300×400 cifrado (AES-256-GCM)
    KekVersion  int NOT NULL,
    Huella      binary(32) NOT NULL,              -- SHA-256 del texto cifrado
    VersionFoto int NOT NULL CONSTRAINT DF_ComensalFoto_Version DEFAULT 1,
    TomadaEn    date NOT NULL,                    -- aviso «Foto antigua» a los 3 años
    CargadaPor  varchar(60) NOT NULL,
    CargadaEn   datetime2(3) NOT NULL CONSTRAINT DF_ComensalFoto_En DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_ComensalFoto_Tamano CHECK (DATALENGTH(Contenido) BETWEEN 1 AND 131072));   -- 128 KB

-- Montos con vigencia (bolsa BM y cupo de nómina CN). La vigencia termina con la fila siguiente.
CREATE TABLE com.MontoCategoria (
    CategoriaId  smallint NOT NULL CONSTRAINT FK_ComMontoCat_Categoria REFERENCES com.Categoria (Id),
    Concepto     char(2) NOT NULL CONSTRAINT CK_ComMontoCat_Concepto CHECK (Concepto IN ('BM', 'CN')),
    VigenteDesde date NOT NULL,
    Monto        decimal(19, 2) NOT NULL CONSTRAINT CK_ComMontoCat_Monto CHECK (Monto >= 0),
    CONSTRAINT PK_ComMontoCategoria PRIMARY KEY (CategoriaId, Concepto, VigenteDesde));
CREATE TABLE com.MontoComensal (
    ComensalId   int NOT NULL CONSTRAINT FK_ComMontoCom_Comensal REFERENCES com.Comensal (Id),
    Concepto     char(2) NOT NULL CONSTRAINT CK_ComMontoCom_Concepto CHECK (Concepto IN ('BM', 'CN')),
    VigenteDesde date NOT NULL,
    Monto        decimal(19, 2) NOT NULL CONSTRAINT CK_ComMontoCom_Monto CHECK (Monto >= 0),
    Motivo       varchar(200) NOT NULL,
    CONSTRAINT PK_ComMontoComensal PRIMARY KEY (ComensalId, Concepto, VigenteDesde));

-- Saldos con UPDATE condicional (ADR-45, nivel «saldos»). BM: Desde = día 1 del mes. CN: el período de nómina.
-- TD y TP quedan reservados para los topes de CARGO_EMPRESA (CE-04.3), que diseña B.
CREATE TABLE com.Saldo (
    ComensalId    int NOT NULL CONSTRAINT FK_ComSaldo_Comensal REFERENCES com.Comensal (Id),
    Concepto      char(2) NOT NULL CONSTRAINT CK_ComSaldo_Concepto CHECK (Concepto IN ('BM', 'CN', 'TD', 'TP')),
    Desde         date NOT NULL,
    Hasta         date NOT NULL,
    LimiteInicial decimal(19, 2) NOT NULL,
    Ajustes       decimal(19, 2) NOT NULL CONSTRAINT DF_ComSaldo_Ajustes DEFAULT 0,
    Usado         decimal(19, 2) NOT NULL CONSTRAINT DF_ComSaldo_Usado DEFAULT 0,
    DiasMes       tinyint NULL,                    -- H-07: alta proporcional
    DiasDerecho   tinyint NULL,
    CreadoEn      datetime2(3) NOT NULL CONSTRAINT DF_ComSaldo_Creado DEFAULT SYSUTCDATETIME(),
    Version       rowversion,
    CONSTRAINT PK_ComSaldo PRIMARY KEY (ComensalId, Concepto, Desde),
    CONSTRAINT CK_ComSaldo_Rango CHECK (Hasta >= Desde),
    CONSTRAINT CK_ComSaldo_Limite CHECK (LimiteInicial >= 0 AND LimiteInicial + Ajustes >= 0 AND Usado >= 0 AND Usado <= LimiteInicial + Ajustes),
    CONSTRAINT CK_ComSaldo_Dias CHECK ((DiasMes IS NULL AND DiasDerecho IS NULL) OR (DiasDerecho BETWEEN 1 AND DiasMes AND DiasMes BETWEEN 28 AND 31)));

CREATE TABLE com.SaldoMovimiento (
    Id          bigint NOT NULL CONSTRAINT DF_ComSaldoMov_Id DEFAULT (NEXT VALUE FOR com.SecMovimiento)
                CONSTRAINT PK_ComSaldoMovimiento PRIMARY KEY,
    ComensalId  int NOT NULL,
    Concepto    char(2) NOT NULL,
    Desde       date NOT NULL,
    Tipo        char(1) NOT NULL CONSTRAINT CK_ComSaldoMov_Tipo CHECK (Tipo IN ('C', 'R', 'A')),   -- consumo, reverso, ajuste
    Monto       decimal(19, 2) NOT NULL CONSTRAINT CK_ComSaldoMov_Monto CHECK (Monto <> 0),        -- suma a Usado (reverso negativo)
    DocumentoId bigint NULL CONSTRAINT FK_ComSaldoMov_Documento REFERENCES doc.Documento (Id),
    Motivo      varchar(200) NULL,
    Usuario     varchar(60) NOT NULL,
    RegistradoEn datetime2(3) NOT NULL CONSTRAINT DF_ComSaldoMov_En DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ComSaldoMov_Saldo FOREIGN KEY (ComensalId, Concepto, Desde) REFERENCES com.Saldo (ComensalId, Concepto, Desde),
    CONSTRAINT CK_ComSaldoMov_Origen CHECK ((Tipo = 'A' AND DocumentoId IS NULL AND LEN(LTRIM(RTRIM(ISNULL(Motivo, '')))) > 0)
                                          OR (Tipo IN ('C', 'R') AND DocumentoId IS NOT NULL)));
CREATE INDEX IX_SaldoMovimiento_Periodo ON com.SaldoMovimiento (Concepto, Desde, ComensalId) INCLUDE (Monto, Tipo, DocumentoId);

-- Almuerzo y cena al 100 %: uno por comensal, fecha de servicio y franja (H-06 (a)).
CREATE TABLE com.UsoBeneficio (
    DocumentoId       bigint NOT NULL CONSTRAINT FK_ComUso_Documento REFERENCES doc.Documento (Id),
    FranjaId          smallint NOT NULL,          -- FK a corp.Franja la agrega M2 (com no depende de corp en M1)
    ComensalId        int NOT NULL CONSTRAINT FK_ComUso_Comensal REFERENCES com.Comensal (Id),
    FechaServicio     date NOT NULL,
    Excepcion         bit NOT NULL CONSTRAINT DF_ComUso_Excepcion DEFAULT 0,   -- contingencia o nodo aislado (R-O3, R-O5)
    ReversoDocumentoId bigint NULL CONSTRAINT FK_ComUso_Reverso REFERENCES doc.Documento (Id),
    RegistradoEn      datetime2(3) NOT NULL CONSTRAINT DF_ComUso_En DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ComUsoBeneficio PRIMARY KEY (DocumentoId, FranjaId));
CREATE UNIQUE INDEX UX_UsoBeneficio_Franja ON com.UsoBeneficio (ComensalId, FechaServicio, FranjaId)
    WHERE ReversoDocumentoId IS NULL AND Excepcion = 0;
```
> Nota: `FK_ComUso_Franja` hacia `corp.Franja` rompe la regla «`com` no referencia a `corp`». La dejo **sin FK** y con la validación en el disparador de emisión de `corp`; con B, `FranjaId` puede apuntar a otra tabla de franjas. Es parte de FD-01.

```sql
------------------------------------------------------------------------- M2 · corp (configuración)
IF SCHEMA_ID(N'corp') IS NULL EXEC(N'CREATE SCHEMA corp AUTHORIZATION dbo');

CREATE TABLE corp.Parametros (
    Id                 tinyint NOT NULL CONSTRAINT PK_CorpParametros PRIMARY KEY CONSTRAINT CK_CorpParametros_Id CHECK (Id = 1),
    ModoFiscalPorcion  char(2) NULL CONSTRAINT CK_CorpParametros_Modo CHECK (ModoFiscalPorcion IN ('P0', 'S1', 'S2', 'S6')),  -- H-04: NULL = sin definir
    NominaHabilitada   bit NOT NULL CONSTRAINT DF_CorpPar_Nomina DEFAULT 0,
    Periodicidad       char(1) NOT NULL CONSTRAINT DF_CorpPar_Period DEFAULT 'Q' CONSTRAINT CK_CorpPar_Period CHECK (Periodicidad IN ('Q', 'M')),
    MostrarCupoNomina  bit NOT NULL CONSTRAINT DF_CorpPar_Cupo DEFAULT 1,      -- FD-12
    LimiteSinCarneMes  tinyint NOT NULL CONSTRAINT DF_CorpPar_SinCarne DEFAULT 3,
    DiasBorradoFoto    smallint NOT NULL CONSTRAINT DF_CorpPar_Foto DEFAULT 90,
    AniosRenovarFoto   tinyint NOT NULL CONSTRAINT DF_CorpPar_Renovar DEFAULT 3,
    ModificadoPor      varchar(60) NULL,
    MotivoCambio       varchar(200) NULL,
    ValidoDesde datetime2(3) GENERATED ALWAYS AS ROW START NOT NULL,
    ValidoHasta datetime2(3) GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta),
    Version rowversion)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = corp.ParametrosHistorial));
INSERT corp.Parametros (Id) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM corp.Parametros);

CREATE TABLE corp.Sede (
    SucursalId           smallint NOT NULL CONSTRAINT PK_CorpSede PRIMARY KEY CONSTRAINT FK_CorpSede_Sucursal REFERENCES org.Sucursal (Id),
    ListaPrecioComensalId  smallint NOT NULL CONSTRAINT FK_CorpSede_ListaCom REFERENCES cat.ListaPrecio (Id),
    ListaPrecioVisitanteId smallint NOT NULL CONSTRAINT FK_CorpSede_ListaVis REFERENCES cat.ListaPrecio (Id),
    Version rowversion);

CREATE TABLE corp.FormaPagoHabilitada (
    FormaPagoId smallint NOT NULL CONSTRAINT PK_CorpFormaPago PRIMARY KEY CONSTRAINT FK_CorpFormaPago_Forma REFERENCES cat.FormaPago (Id));

CREATE TABLE corp.Franja (
    Id          smallint IDENTITY CONSTRAINT PK_CorpFranja PRIMARY KEY,
    SucursalId  smallint NOT NULL CONSTRAINT FK_CorpFranja_Sucursal REFERENCES org.Sucursal (Id),
    Codigo      varchar(20) NOT NULL,
    Descripcion varchar(60) NOT NULL,
    HoraInicio  time(0) NOT NULL,
    HoraFin     time(0) NOT NULL,                 -- HoraFin < HoraInicio: cruza la medianoche (fecha de inicio, R-H1)
    DiasSemana  tinyint NOT NULL CONSTRAINT CK_CorpFranja_Dias CHECK (DiasSemana BETWEEN 1 AND 127),   -- 1 lunes … 64 domingo
    EsComida    bit NOT NULL CONSTRAINT DF_CorpFranja_Comida DEFAULT 0,   -- tiene composición al 100 %
    Inhabilitada bit NOT NULL CONSTRAINT DF_CorpFranja_Inh DEFAULT 0,
    ValidoDesde datetime2(3) GENERATED ALWAYS AS ROW START NOT NULL,
    ValidoHasta datetime2(3) GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta),
    Version rowversion,
    CONSTRAINT UQ_CorpFranja_Codigo UNIQUE (SucursalId, Codigo),
    CONSTRAINT CK_CorpFranja_Horas CHECK (HoraInicio <> HoraFin))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = corp.FranjaHistorial));

CREATE TABLE corp.ArticuloFranja (
    ArticuloId int NOT NULL CONSTRAINT FK_CorpArtFranja_Articulo REFERENCES cat.Articulo (Id),
    FranjaId   smallint NOT NULL CONSTRAINT FK_CorpArtFranja_Franja REFERENCES corp.Franja (Id),
    CONSTRAINT PK_CorpArticuloFranja PRIMARY KEY (ArticuloId, FranjaId));
CREATE INDEX IX_ArticuloFranja_Franja ON corp.ArticuloFranja (FranjaId);

CREATE TABLE corp.ComposicionGrupo (
    FranjaId    smallint NOT NULL CONSTRAINT FK_CorpCompGrupo_Franja REFERENCES corp.Franja (Id),
    Grupo       tinyint NOT NULL,
    Descripcion varchar(40) NOT NULL,             -- «Plato fuerte», «Acompañante», «Bebida»
    Cantidad    tinyint NOT NULL CONSTRAINT CK_CorpCompGrupo_Cant CHECK (Cantidad BETWEEN 1 AND 9),
    CONSTRAINT PK_CorpComposicionGrupo PRIMARY KEY (FranjaId, Grupo));
CREATE TABLE corp.ComposicionArticulo (
    FranjaId   smallint NOT NULL,
    Grupo      tinyint NOT NULL,
    ArticuloId int NOT NULL CONSTRAINT FK_CorpCompArt_Articulo REFERENCES cat.Articulo (Id),
    CONSTRAINT PK_CorpComposicionArticulo PRIMARY KEY (FranjaId, Grupo, ArticuloId),
    CONSTRAINT UQ_CorpCompArt_UnGrupo UNIQUE (FranjaId, ArticuloId),       -- FD-06
    CONSTRAINT FK_CorpCompArt_Grupo FOREIGN KEY (FranjaId, Grupo) REFERENCES corp.ComposicionGrupo (FranjaId, Grupo));

CREATE TABLE corp.CategoriaFranja (
    CategoriaId smallint NOT NULL CONSTRAINT FK_CorpCatFranja_Categoria REFERENCES com.Categoria (Id),
    FranjaId    smallint NOT NULL CONSTRAINT FK_CorpCatFranja_Franja REFERENCES corp.Franja (Id),
    CONSTRAINT PK_CorpCategoriaFranja PRIMARY KEY (CategoriaId, FranjaId));

CREATE TABLE corp.ArticuloCobertura (
    ArticuloId int NOT NULL CONSTRAINT PK_CorpArticuloCobertura PRIMARY KEY CONSTRAINT FK_CorpCobertura_Articulo REFERENCES cat.Articulo (Id),
    Porcentaje tinyint NOT NULL CONSTRAINT CK_CorpCobertura_Porc CHECK (Porcentaje IN (0, 50, 100)),   -- FD-05; sin fila = 100
    ValidoDesde datetime2(3) GENERATED ALWAYS AS ROW START NOT NULL,
    ValidoHasta datetime2(3) GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta))
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = corp.ArticuloCoberturaHistorial));
```
> La composición y las franjas por artículo se borran por fila (configuración sin referencias); su historia la conservan la bitácora (antes/después en JSON) y, en `Franja` y `ArticuloCobertura`, la tabla temporal. Si el auditor pide la historia exacta de la composición, se vuelve temporal también: es aditivo.

```sql
------------------------------------------------------------------------- M3 · documentos
ALTER TABLE doc.TipoDocumento DROP CONSTRAINT CK_TipoDocumento_Familia;
ALTER TABLE doc.TipoDocumento WITH CHECK ADD CONSTRAINT CK_TipoDocumento_Familia
    CHECK (Familia IN ('VEN', 'CXC', 'COM', 'CXP', 'INV', 'CAJ', 'BAN', 'CIN'));
-- Igual con CK_LineaSaldo_Clase (+ 'I') y CK_Autorizacion_Tipo (+ 'REVERSO_CONSUMO', con motivo obligatorio).
INSERT INTO doc.TipoDocumento (Id, Codigo, Descripcion, Familia, TipoNumeracion, AfectaInventario, AfectaSaldo, LlevaNcf, Editable, SoloCentral, NcfOpcional, ControlFecha)
SELECT s.* FROM (VALUES (40, 'TCI', 'Ticket de consumo interno', 'CIN', 'ConsumoInterno', -1, 0, 0, 0, 0, 0, 1),
                        (41, 'RCI', 'Reverso de consumo interno', 'CIN', 'ReversoConsumo',  1, 0, 0, 0, 0, 0, 1)) s (Id, Codigo, Descripcion, Familia, TipoNumeracion, Inv, Saldo, Ncf, Editable, SoloCentral, NcfOpcional, ControlFecha)
 WHERE NOT EXISTS (SELECT 1 FROM doc.TipoDocumento t WHERE t.Id = s.Id);
-- ControlFecha 1 = fecha del servidor; la digitación del lote de contingencia usa FECHA_ANTERIOR.

CREATE TABLE corp.Consumo (
    DocumentoId       bigint NOT NULL CONSTRAINT PK_CorpConsumo PRIMARY KEY CONSTRAINT FK_CorpConsumo_Documento REFERENCES doc.Documento (Id),
    ComensalId        int NOT NULL CONSTRAINT FK_CorpConsumo_Comensal REFERENCES com.Comensal (Id),
    CategoriaId       smallint NOT NULL CONSTRAINT FK_CorpConsumo_Categoria REFERENCES com.Categoria (Id),        -- congelada
    CentroCostoId     smallint NOT NULL CONSTRAINT FK_CorpConsumo_CentroCosto REFERENCES com.CentroCosto (Id),    -- congelado
    SucursalId        smallint NOT NULL,
    CajaId            smallint NOT NULL,
    JornadaId         bigint NOT NULL,
    AlmacenId         smallint NOT NULL CONSTRAINT FK_CorpConsumo_Almacen REFERENCES org.Almacen (Id),
    ListaPrecioId     smallint NOT NULL CONSTRAINT FK_CorpConsumo_Lista REFERENCES cat.ListaPrecio (Id),
    FechaServicio     date NOT NULL,                       -- fecha de inicio de la franja (R-H1); la fiscal es doc.Documento.Fecha
    Origen            char(1) NOT NULL CONSTRAINT DF_CorpConsumo_Origen DEFAULT 'N'
                      CONSTRAINT CK_CorpConsumo_Origen CHECK (Origen IN ('N', 'L')),          -- normal, lote de contingencia
    ValeNumero        varchar(20) NULL,
    ModoIdentificacion char(1) NOT NULL CONSTRAINT CK_CorpConsumo_ModoId CHECK (ModoIdentificacion IN ('C', 'M', 'L')),  -- carné, manual con autorización, lote
    CarneId           int NULL CONSTRAINT FK_CorpConsumo_Carne REFERENCES com.Carne (Id),
    VersionFoto       int NULL,
    IdentidadConfirmadaPor varchar(60) NOT NULL,
    IdentidadConfirmadaEn  datetime2(3) NOT NULL,
    Total             decimal(19, 2) NOT NULL,
    MontoBeneficio    decimal(19, 2) NOT NULL,
    MontoBolsa        decimal(19, 2) NOT NULL,
    MontoEmpleado     decimal(19, 2) NOT NULL,
    MontoNomina       decimal(19, 2) NOT NULL CONSTRAINT DF_CorpConsumo_Nomina DEFAULT 0,
    BolsaAntes        decimal(19, 2) NULL,                 -- F-5: instantánea impresa
    BolsaDespues      decimal(19, 2) NULL,
    CupoNominaAntes   decimal(19, 2) NULL,
    CupoNominaDespues decimal(19, 2) NULL,
    EstadoBeneficio   char(1) NOT NULL CONSTRAINT CK_CorpConsumo_EstBen CHECK (EstadoBeneficio IN ('U', 'Y', 'N')),
    FranjaComidaId    smallint NULL CONSTRAINT FK_CorpConsumo_FranjaComida REFERENCES corp.Franja (Id),
    BeneficioPrevioId bigint NULL CONSTRAINT FK_CorpConsumo_Previo REFERENCES doc.Documento (Id),
    ModoFiscal        char(2) NULL CONSTRAINT CK_CorpConsumo_ModoFiscal CHECK (ModoFiscal IN ('P0', 'S1', 'S2')),
    CONSTRAINT FK_CorpConsumo_Jornada FOREIGN KEY (JornadaId, CajaId) REFERENCES caja.Jornada (Id, CajaId),
    CONSTRAINT FK_CorpConsumo_Caja FOREIGN KEY (CajaId) REFERENCES org.Caja (Id),
    CONSTRAINT CK_CorpConsumo_Montos CHECK (MontoBeneficio >= 0 AND MontoBolsa >= 0 AND MontoEmpleado >= 0
                                            AND MontoNomina BETWEEN 0 AND MontoEmpleado
                                            AND Total = MontoBeneficio + MontoBolsa + MontoEmpleado),
    CONSTRAINT CK_CorpConsumo_Bolsa CHECK ((BolsaAntes IS NULL AND BolsaDespues IS NULL AND MontoBolsa = 0)
                                           OR (BolsaDespues = BolsaAntes - MontoBolsa AND BolsaDespues >= 0)),
    CONSTRAINT CK_CorpConsumo_Cupo CHECK ((CupoNominaAntes IS NULL AND CupoNominaDespues IS NULL AND MontoNomina = 0)
                                          OR (CupoNominaDespues = CupoNominaAntes - MontoNomina AND CupoNominaDespues >= 0)),
    CONSTRAINT CK_CorpConsumo_Identidad CHECK (ModoIdentificacion <> 'C' OR CarneId IS NOT NULL),
    CONSTRAINT CK_CorpConsumo_Vale CHECK ((Origen = 'L') = (ValeNumero IS NOT NULL) AND (Origen = 'L') = (ModoIdentificacion = 'L')),
    CONSTRAINT CK_CorpConsumo_Fiscal CHECK ((MontoEmpleado = 0 AND ModoFiscal IS NULL) OR (MontoEmpleado > 0 AND ModoFiscal IS NOT NULL)),
    CONSTRAINT CK_CorpConsumo_Previo CHECK (EstadoBeneficio = 'Y' OR BeneficioPrevioId IS NULL));
CREATE INDEX IX_Consumo_Comensal ON corp.Consumo (ComensalId, FechaServicio)
    INCLUDE (Total, MontoBeneficio, MontoBolsa, MontoEmpleado, ModoIdentificacion);
CREATE INDEX IX_Consumo_Jornada ON corp.Consumo (JornadaId) INCLUDE (MontoBeneficio, MontoBolsa, MontoEmpleado, MontoNomina);
CREATE UNIQUE INDEX UX_Consumo_Vale ON corp.Consumo (SucursalId, ValeNumero) WHERE ValeNumero IS NOT NULL;

CREATE TABLE corp.ConsumoLinea (
    DocumentoId        bigint NOT NULL CONSTRAINT FK_CorpLinea_Consumo REFERENCES corp.Consumo (DocumentoId),
    Linea              smallint NOT NULL,
    ArticuloId         int NOT NULL,
    UnidadId           smallint NOT NULL,
    FactorUnidad       decimal(19, 6) NOT NULL CONSTRAINT CK_CorpLinea_Factor CHECK (FactorUnidad > 0),
    Descripcion        varchar(150) NOT NULL,
    AlmacenId          smallint NOT NULL CONSTRAINT FK_CorpLinea_Almacen REFERENCES org.Almacen (Id),
    LoteId             bigint NULL CONSTRAINT FK_CorpLinea_Lote REFERENCES inv.Lote (Id),
    Cantidad           decimal(18, 6) NOT NULL CONSTRAINT CK_CorpLinea_Cantidad CHECK (Cantidad > 0),
    PrecioUnitario     decimal(19, 6) NOT NULL CONSTRAINT CK_CorpLinea_Precio CHECK (PrecioUnitario >= 0),
    Importe            decimal(19, 2) NOT NULL,            -- base, como ventas.VentaLinea
    ImpuestoId         tinyint NOT NULL CONSTRAINT FK_CorpLinea_Impuesto REFERENCES fiscal.Impuesto (Id),
    PorcentajeImpuesto decimal(7, 4) NOT NULL,
    Impuesto           decimal(19, 2) NOT NULL CONSTRAINT CK_CorpLinea_Impuesto CHECK (Impuesto >= 0),   -- informativo
    Total              decimal(19, 2) NOT NULL,            -- lo que ve el comensal
    CostoUnitario      decimal(19, 6) NOT NULL CONSTRAINT CK_CorpLinea_Costo CHECK (CostoUnitario >= 0),  -- congelado, unidad base
    FranjaId           smallint NULL CONSTRAINT FK_CorpLinea_Franja REFERENCES corp.Franja (Id),        -- la que habilitó la venta
    ValidadaEn         datetime2(3) NOT NULL,              -- hora del servidor (UTC) al agregar la línea (PF-1)
    ComposicionGrupo   tinyint NULL,                       -- con FranjaComida del encabezado: entró al 100 %
    CoberturaPorcentaje tinyint NOT NULL CONSTRAINT CK_CorpLinea_Cob CHECK (CoberturaPorcentaje IN (0, 50, 100)),
    PorcionBolsa       decimal(19, 2) NOT NULL,
    MontoBeneficio     decimal(19, 2) NOT NULL,
    MontoBolsa         decimal(19, 2) NOT NULL,
    MontoEmpleado      decimal(19, 2) NOT NULL,
    CONSTRAINT PK_CorpConsumoLinea PRIMARY KEY (DocumentoId, Linea),
    CONSTRAINT FK_CorpLinea_ArticuloUnidad FOREIGN KEY (ArticuloId, UnidadId) REFERENCES cat.ArticuloUnidad (ArticuloId, UnidadId),
    CONSTRAINT CK_CorpLinea_Importe CHECK (Importe = ROUND(Cantidad * PrecioUnitario, 2) AND Importe >= 0 AND Total = Importe + Impuesto),
    CONSTRAINT CK_CorpLinea_Porcion CHECK (PorcionBolsa = ROUND(Total * CoberturaPorcentaje / 100.0, 2)),
    CONSTRAINT CK_CorpLinea_Reparto CHECK (MontoBeneficio IN (0, Total) AND MontoBolsa >= 0 AND MontoEmpleado >= 0
                                           AND MontoBolsa <= PorcionBolsa
                                           AND MontoBeneficio + MontoBolsa + MontoEmpleado = Total),
    CONSTRAINT CK_CorpLinea_Beneficio CHECK ((MontoBeneficio > 0) = (ComposicionGrupo IS NOT NULL) OR (Total = 0)));

CREATE TABLE corp.ConsumoPago (               -- también los del reverso (montos negativos), como DEV en ventas
    DocumentoId bigint NOT NULL CONSTRAINT FK_CorpPago_Documento REFERENCES doc.Documento (Id),
    Linea       tinyint NOT NULL,
    Medio       char(1) NOT NULL CONSTRAINT CK_CorpPago_Medio CHECK (Medio IN ('D', 'N')),   -- dinero, nómina
    FormaPagoId smallint NULL CONSTRAINT FK_CorpPago_Forma REFERENCES cat.FormaPago (Id),
    MonedaId    smallint NOT NULL CONSTRAINT FK_CorpPago_Moneda REFERENCES cat.Moneda (Id),
    Tasa        decimal(19, 6) NOT NULL CONSTRAINT CK_CorpPago_Tasa CHECK (Tasa > 0),
    MontoMoneda decimal(19, 2) NOT NULL,
    Monto       decimal(19, 2) NOT NULL CONSTRAINT CK_CorpPago_Monto CHECK (Monto <> 0),
    PeriodoNominaDesde date NULL,
    Referencia  varchar(50) NULL,
    Autorizacion varchar(20) NULL,
    Ultimos4    char(4) NULL CONSTRAINT CK_CorpPago_Ultimos4 CHECK (Ultimos4 IS NULL OR Ultimos4 NOT LIKE '%[^0-9]%'),
    Marca       varchar(20) NULL,
    Terminal    varchar(20) NULL,
    CONSTRAINT PK_CorpConsumoPago PRIMARY KEY (DocumentoId, Linea),
    CONSTRAINT CK_CorpPago_Coherencia CHECK ((Medio = 'D' AND FormaPagoId IS NOT NULL AND PeriodoNominaDesde IS NULL)
                                             OR (Medio = 'N' AND FormaPagoId IS NULL AND PeriodoNominaDesde IS NOT NULL)));

CREATE TABLE corp.Reverso (
    DocumentoId        bigint NOT NULL CONSTRAINT PK_CorpReverso PRIMARY KEY CONSTRAINT FK_CorpReverso_Documento REFERENCES doc.Documento (Id),
    ConsumoDocumentoId bigint NOT NULL CONSTRAINT FK_CorpReverso_Consumo REFERENCES corp.Consumo (DocumentoId),
    CajaId             smallint NOT NULL,
    JornadaId          bigint NOT NULL,                 -- donde se devuelve el dinero
    Parcial            bit NOT NULL,
    Motivo             varchar(200) NOT NULL CONSTRAINT CK_CorpReverso_Motivo CHECK (LEN(LTRIM(RTRIM(Motivo))) > 0),
    MontoBeneficio     decimal(19, 2) NOT NULL,
    MontoBolsa         decimal(19, 2) NOT NULL,
    MontoEmpleado      decimal(19, 2) NOT NULL,
    MontoNomina        decimal(19, 2) NOT NULL,
    BolsaAntes         decimal(19, 2) NULL,              -- F-5 del reverso
    BolsaDespues       decimal(19, 2) NULL,
    CupoNominaAntes    decimal(19, 2) NULL,
    CupoNominaDespues  decimal(19, 2) NULL,
    CONSTRAINT FK_CorpReverso_Jornada FOREIGN KEY (JornadaId, CajaId) REFERENCES caja.Jornada (Id, CajaId),
    CONSTRAINT CK_CorpReverso_Montos CHECK (MontoBeneficio >= 0 AND MontoBolsa >= 0 AND MontoEmpleado >= 0 AND MontoNomina BETWEEN 0 AND MontoEmpleado),
    CONSTRAINT CK_CorpReverso_Bolsa CHECK ((BolsaAntes IS NULL AND BolsaDespues IS NULL AND MontoBolsa = 0) OR BolsaDespues = BolsaAntes + MontoBolsa),
    CONSTRAINT CK_CorpReverso_Cupo CHECK ((CupoNominaAntes IS NULL AND CupoNominaDespues IS NULL) OR CupoNominaDespues >= CupoNominaAntes));
CREATE INDEX IX_Reverso_Consumo ON corp.Reverso (ConsumoDocumentoId);
CREATE INDEX IX_Reverso_Jornada ON corp.Reverso (JornadaId) INCLUDE (MontoEmpleado, MontoNomina);

CREATE TABLE corp.ReversoLinea (
    DocumentoId   bigint NOT NULL CONSTRAINT FK_CorpRevLinea_Reverso REFERENCES corp.Reverso (DocumentoId),
    Linea         smallint NOT NULL,
    ConsumoDocumentoId bigint NOT NULL,
    ConsumoLinea  smallint NOT NULL,
    Cantidad      decimal(18, 6) NOT NULL CONSTRAINT CK_CorpRevLinea_Cant CHECK (Cantidad > 0),
    Servido       bit NOT NULL,                        -- sí: borrador de merma; no: vuelve a la existencia
    MontoBeneficio decimal(19, 2) NOT NULL,
    MontoBolsa    decimal(19, 2) NOT NULL,
    MontoEmpleado decimal(19, 2) NOT NULL,
    CONSTRAINT PK_CorpReversoLinea PRIMARY KEY (DocumentoId, Linea),
    CONSTRAINT FK_CorpRevLinea_Linea FOREIGN KEY (ConsumoDocumentoId, ConsumoLinea) REFERENCES corp.ConsumoLinea (DocumentoId, Linea),
    CONSTRAINT CK_CorpRevLinea_Montos CHECK (MontoBeneficio >= 0 AND MontoBolsa >= 0 AND MontoEmpleado >= 0));

CREATE TABLE corp.CorteNomina (
    Desde        date NOT NULL CONSTRAINT PK_CorpCorteNomina PRIMARY KEY,
    Hasta        date NOT NULL,
    Estado       char(1) NOT NULL CONSTRAINT DF_CorpCorte_Estado DEFAULT 'A' CONSTRAINT CK_CorpCorte_Estado CHECK (Estado IN ('A', 'C')),
    ExportadoPor varchar(60) NULL,
    ExportadoEn  datetime2(3) NULL,
    Huella       binary(32) NULL,
    Contenido    varbinary(max) NULL,
    CONSTRAINT CK_CorpCorte_Rango CHECK (Hasta >= Desde),
    CONSTRAINT CK_CorpCorte_Cierre CHECK ((Estado = 'A' AND ExportadoEn IS NULL AND Huella IS NULL AND Contenido IS NULL)
                                          OR (Estado = 'C' AND ExportadoEn IS NOT NULL AND ExportadoPor IS NOT NULL AND Huella IS NOT NULL AND Contenido IS NOT NULL)));
-- TR_CorteNomina_Cerrado (51830): un corte en C no cambia ni se borra; los ajustes van al período siguiente
-- (com.SaldoMovimiento tipo A del concepto CN con el motivo y la referencia del reverso).

------------------------------------------------------------------------- M4 · costura fiscal (H-04 abierta)
IF COL_LENGTH(N'ventas.Venta', N'InventarioDescargadoPorId') IS NULL
    ALTER TABLE ventas.Venta ADD InventarioDescargadoPorId bigint NULL
        CONSTRAINT FK_Venta_InventarioDescargadoPor REFERENCES doc.Documento (Id);
-- Regla nueva en TR_Documento_Emision (coordinada con B): una venta con InventarioDescargadoPorId no tiene filas en inv.Movimiento.

CREATE TABLE corp.ConsumoComprobante (
    DocumentoId      bigint NOT NULL CONSTRAINT PK_CorpConsComp PRIMARY KEY CONSTRAINT FK_CorpConsComp_Documento REFERENCES doc.Documento (Id),  -- TCI o RCI
    VentaDocumentoId bigint NOT NULL CONSTRAINT FK_CorpConsComp_Venta REFERENCES ventas.Venta (DocumentoId),                               -- E32, o E34 del reverso
    Modo             char(2) NOT NULL CONSTRAINT CK_CorpConsComp_Modo CHECK (Modo IN ('S1', 'S2')),
    Monto            decimal(19, 2) NOT NULL CONSTRAINT CK_CorpConsComp_Monto CHECK (Monto > 0),
    RegistradoEn     datetime2(3) NOT NULL CONSTRAINT DF_CorpConsComp_En DEFAULT SYSUTCDATETIME());
CREATE UNIQUE INDEX UX_ConsumoComprobante_S1 ON corp.ConsumoComprobante (VentaDocumentoId) WHERE Modo = 'S1';
CREATE INDEX IX_ConsumoComprobante_Venta ON corp.ConsumoComprobante (VentaDocumentoId);

CREATE TABLE corp.ConsumoComprobanteLinea (
    DocumentoId      bigint NOT NULL,              -- TCI o RCI
    Linea            smallint NOT NULL,            -- línea del ticket (o del reverso)
    VentaDocumentoId bigint NOT NULL,
    VentaLinea       smallint NOT NULL,
    Monto            decimal(19, 2) NOT NULL,      -- la porción de MontoEmpleado amparada
    CONSTRAINT PK_CorpConsCompLinea PRIMARY KEY (DocumentoId, Linea, VentaDocumentoId),
    CONSTRAINT FK_CorpConsCompLinea_Cab FOREIGN KEY (DocumentoId) REFERENCES corp.ConsumoComprobante (DocumentoId),
    CONSTRAINT FK_CorpConsCompLinea_Venta FOREIGN KEY (VentaDocumentoId, VentaLinea) REFERENCES ventas.VentaLinea (DocumentoId, Linea));
```

**Disparador de emisión de `corp` (`corp.TR_Consumo_Emision`, sobre `doc.Documento` al pasar de 0 a 1, tipos `TCI`/`RCI`)** — reglas, en el estilo de `TR_Documento_Emision` ([NG] `SqlMigracionesOla3.cs:100-140`):
- 51810: encabezado = suma de las líneas (beneficio, bolsa, empleado, total).
- 51811: `BolsaDespues` = `LimiteInicial + Ajustes − Usado` del saldo BM del período, y `CupoNominaDespues` igual con el CN (F-5); y `SUM(com.SaldoMovimiento)` del documento = `MontoBolsa` / `MontoNomina`.
- 51812: `SUM(corp.ConsumoPago.Monto)` = `MontoEmpleado` (reverso: = −`MontoEmpleado`); `SUM` de los pagos `N` = `MontoNomina`.
- 51813: el período de nómina del pago existe en `com.Saldo` (CN) y su corte está abierto.
- 51814: forma de pago habilitada (`corp.FormaPagoHabilitada`, clase `E` o `T` en la fase 1) y nómina habilitada si hay pago `N`.
- 51815: `MontoEmpleado > 0` exige `corp.Parametros.ModoFiscalPorcion IN ('P0','S1','S2')` y `Consumo.ModoFiscal` = ese valor.
- 51816: si `EstadoBeneficio = 'U'`, hay fila en `com.UsoBeneficio` del documento con `FranjaComidaId`, y la categoría del ticket tiene esa franja (`corp.CategoriaFranja`).
- 51817: la línea con `FranjaId` cae en la franja con la hora local de `ValidadaEn` (`AT TIME ZONE 'SA Western Standard Time'`, UTC−4 sin horario de verano) y el día de la semana; toda línea de un artículo con franja en la sede tiene `FranjaId`.
- 51818: con `S1`, el ticket con `MontoEmpleado > 0` tiene su fila en `corp.ConsumoComprobante` en la misma transacción.
- 51819: el comensal estaba activo (`Estado = 'A'`) y el carné activo.
- 51820 / 51821: reverso autorizado por otra persona; bolsa no devuelta si el consumo es de otro mes.

---

## 11. Vistas de referencia (M5)
```sql
CREATE OR ALTER VIEW rptc.CorpConsumoEmpleado AS         -- RC-01
SELECT d.Fecha, c.FechaServicio, d.Numero AS Ticket, d.Estado, s.Codigo AS Sede, cm.Codigo AS CodigoComensal,
       cm.Nombres + ' ' + cm.Apellidos AS Comensal, cat.Codigo AS Categoria, cc.Codigo AS CentroCosto,
       l.Linea, a.Codigo AS Articulo, l.Descripcion, l.Cantidad, l.Total, l.MontoBeneficio, l.MontoBolsa, l.MontoEmpleado,
       c.ModoIdentificacion, c.Origen, CONVERT(bit, CASE WHEN c.ModoIdentificacion = 'C' THEN 0 ELSE 1 END) AS SinCarne
  FROM corp.Consumo c
  JOIN doc.Documento d ON d.Id = c.DocumentoId AND d.Estado IN (1, 2)
  JOIN corp.ConsumoLinea l ON l.DocumentoId = c.DocumentoId
  JOIN com.Comensal cm ON cm.Id = c.ComensalId
  JOIN com.Categoria cat ON cat.Id = c.CategoriaId
  JOIN com.CentroCosto cc ON cc.Id = c.CentroCostoId
  JOIN org.Sucursal s ON s.Id = c.SucursalId
  JOIN cat.Articulo a ON a.Id = l.ArticuloId
UNION ALL
SELECT d.Fecha, c.FechaServicio, d.Numero, d.Estado, s.Codigo, cm.Codigo, cm.Nombres + ' ' + cm.Apellidos, cat.Codigo, cc.Codigo,
       rl.ConsumoLinea, a.Codigo, l.Descripcion, -rl.Cantidad, -(rl.MontoBeneficio + rl.MontoBolsa + rl.MontoEmpleado),
       -rl.MontoBeneficio, -rl.MontoBolsa, -rl.MontoEmpleado, c.ModoIdentificacion, c.Origen, CONVERT(bit, 0)
  FROM corp.Reverso r
  JOIN doc.Documento d ON d.Id = r.DocumentoId AND d.Estado = 1
  JOIN corp.ReversoLinea rl ON rl.DocumentoId = r.DocumentoId
  JOIN corp.ConsumoLinea l ON l.DocumentoId = rl.ConsumoDocumentoId AND l.Linea = rl.ConsumoLinea
  JOIN corp.Consumo c ON c.DocumentoId = r.ConsumoDocumentoId
  JOIN com.Comensal cm ON cm.Id = c.ComensalId
  JOIN com.Categoria cat ON cat.Id = c.CategoriaId
  JOIN com.CentroCosto cc ON cc.Id = c.CentroCostoId
  JOIN org.Sucursal s ON s.Id = c.SucursalId
  JOIN cat.Articulo a ON a.Id = l.ArticuloId;
GO
CREATE OR ALTER VIEW rptc.CorpBolsaMes AS                -- RC-02
SELECT sa.Desde AS Mes, cm.Codigo AS CodigoComensal, cm.Nombres + ' ' + cm.Apellidos AS Comensal,
       sa.LimiteInicial AS Asignado, sa.Ajustes, sa.Usado,
       CASE WHEN sa.Hasta < CONVERT(date, SYSDATETIMEOFFSET() AT TIME ZONE 'SA Western Standard Time')
            THEN sa.LimiteInicial + sa.Ajustes - sa.Usado ELSE 0 END AS Perdido,
       sa.LimiteInicial + sa.Ajustes - sa.Usado AS SaldoActual, sa.DiasMes, sa.DiasDerecho,
       (SELECT COUNT(*) FROM com.UsoBeneficio u
         WHERE u.ComensalId = sa.ComensalId AND u.FechaServicio BETWEEN sa.Desde AND sa.Hasta AND u.ReversoDocumentoId IS NULL) AS ComidasTomadas
  FROM com.Saldo sa JOIN com.Comensal cm ON cm.Id = sa.ComensalId
 WHERE sa.Concepto = 'BM' AND cm.ClienteId IS NULL;
GO
CREATE OR ALTER VIEW rptc.CorpCorteNomina AS             -- RC-03
SELECT m.Desde AS PeriodoDesde, sa.Hasta AS PeriodoHasta, cm.Codigo AS CodigoComensal, cm.Nombres + ' ' + cm.Apellidos AS Comensal,
       SUM(m.Monto) AS Monto, SUM(CASE WHEN m.Tipo = 'C' THEN 1 ELSE 0 END) AS Tickets,
       SUM(CASE WHEN m.Tipo IN ('R', 'A') THEN m.Monto ELSE 0 END) AS AjustesYReversos,
       ISNULL(k.Estado, 'A') AS EstadoCorte, k.Huella
  FROM com.SaldoMovimiento m
  JOIN com.Saldo sa ON sa.ComensalId = m.ComensalId AND sa.Concepto = m.Concepto AND sa.Desde = m.Desde
  JOIN com.Comensal cm ON cm.Id = m.ComensalId
  LEFT JOIN corp.CorteNomina k ON k.Desde = m.Desde
 WHERE m.Concepto = 'CN'
 GROUP BY m.Desde, sa.Hasta, cm.Codigo, cm.Nombres, cm.Apellidos, k.Estado, k.Huella;
GO
CREATE OR ALTER VIEW rpt.CorpLiquidacionAdministrador AS -- RC-06, sin personas
SELECT c.FechaServicio, s.Codigo AS Sede, f.Codigo AS Franja,
       COUNT(*) AS Tickets, SUM(CASE WHEN c.EstadoBeneficio = 'U' THEN 1 ELSE 0 END) AS ComidasAl100,
       SUM(c.MontoBeneficio) AS ImporteBeneficio, SUM(c.MontoBolsa) AS ImporteBolsa,
       SUM(c.MontoEmpleado - c.MontoNomina) AS DineroCobrado, SUM(c.MontoNomina) AS Nomina,
       SUM(CASE WHEN c.ModoIdentificacion <> 'C' THEN 1 ELSE 0 END) AS SinCarne
  FROM corp.Consumo c
  JOIN doc.Documento d ON d.Id = c.DocumentoId AND d.Estado = 1
  JOIN org.Sucursal s ON s.Id = c.SucursalId
  LEFT JOIN corp.Franja f ON f.Id = c.FranjaComidaId
 GROUP BY c.FechaServicio, s.Codigo, f.Codigo;
GO
CREATE OR ALTER VIEW rptc.CorpRetiroCosto AS             -- apoyo del IT-1 (el IT-1 sigue en el ERP)
SELECT DATEFROMPARTS(YEAR(d.Fecha), MONTH(d.Fecha), 1) AS Mes, s.Codigo AS Sede, cc.Codigo AS CentroCosto,
       SUM(ROUND(l.Cantidad * l.FactorUnidad * l.CostoUnitario, 2)) AS CostoServido,
       SUM(CASE WHEN l.Total = 0 THEN 0
                ELSE ROUND(l.Cantidad * l.FactorUnidad * l.CostoUnitario * (l.MontoBeneficio + l.MontoBolsa) / l.Total, 2) END) AS CostoSubsidiado,
       SUM(l.MontoBeneficio + l.MontoBolsa) AS SubsidioPrecioLista
  FROM corp.Consumo c
  JOIN doc.Documento d ON d.Id = c.DocumentoId AND d.Estado = 1
  JOIN corp.ConsumoLinea l ON l.DocumentoId = c.DocumentoId
  JOIN com.CentroCosto cc ON cc.Id = c.CentroCostoId
  JOIN org.Sucursal s ON s.Id = c.SucursalId
 GROUP BY DATEFROMPARTS(YEAR(d.Fecha), MONTH(d.Fecha), 1), s.Codigo, cc.Codigo;
```
- Los reversos restan en RC-01; en RC-06 y en el retiro al costo los descuento en la versión de construcción (los dejé fuera aquí para no alargar el DDL de referencia).
- `CorpRetiroCosto` usa la fecha fiscal (`doc.Documento.Fecha`) y el costo congelado, como pide [CONT] D-05.

**Sin ejecutar:** no creé la base `GPOS_TEST_*` para probar el DDL. Los tipos de llave están verificados en el dominio de [NG]: `cat.ListaPrecio.Id smallint` (`Dominio/Maestros/Precios.cs`), `fiscal.Impuesto.Id tinyint` (`Dominio/Fiscal/Catalogos.cs:34`), `inv.Lote.Id bigint` (`Dominio/Inventario/Inventario.cs:6`), `org.Almacen.Id smallint`, `cat.Moneda.Id smallint`, `cat.Cliente.Id bigint` (`Terceros.cs:18`) y la PK de `cat.ArticuloUnidad` (`Articulo.cs:101-102`). La sintaxis del DDL no está probada.

---

## 12. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Dos cajas y el mismo comensal: reparto desactualizado | Media | Guarda optimista + índice único; 409 con el reparto nuevo; CA-03 y CA-04 como pruebas de concurrencia |
| R-02 | La foto expuesta (Ley 172-13) | Alta | Cifrado en la app, tabla aparte, `DENY` a los roles de lectura, borrado a los 90 días; queda en respaldos hasta su vencimiento → **auditor-seguridad** |
| R-03 | Clonación del carné | Media | HMAC en la base, foto y confirmación, RC-05 |
| R-04 | El modo fiscal queda en `NULL` y la cafetería no cobra dinero | Baja (desarrollo) | Es intencional (FD-09); se fija con H-04 antes del primer cliente |
| R-05 | Choque de ids de tipo de documento, del rango de errores o del nombre de la marca de inventario con B | Media | Ids 40 y 41, errores 518xx y M4 se confirman con B antes de construir |
| R-06 | Express llega a 10 GB en empresas con muchas sedes | Media | ≈ 200 MB por sede y año; recomendar Standard a partir de 4 o 5 sedes, o archivado |
| R-07 | M3 revalida `CHECK` sobre tablas grandes | Baja | Segundos; con la API detenida |
| R-08 | Pérdida de datos | Baja | Solo tablas y columnas nuevas; los `Down` se niegan con datos |
| R-09 | Franja mal configurada (cruce de medianoche, días) bloquea el almuerzo | Media | `CHECK` de horas y días; la pantalla de franjas muestra la próxima ventana; historia temporal |

---

## 13. Puntos que necesitan firma (FD-01 a FD-15)

| # | Punto | Recomendación |
|---|---|---|
| **FD-01** | Esquemas `com` (común, sin depender de `corp` ni `res`) y `corp` (vertical) | Sí |
| **FD-02** | Padrón propio `com.Comensal`, con enlace opcional y único a `rrhh.Empleado`; sin cédula | Sí |
| **FD-03** | Foto dentro de la base, tabla aparte, AES-256-GCM en la app con la construcción de ADR-67; una sola versión; borrado físico a los 90 días de la baja | Sí, sujeto al auditor-seguridad |
| **FD-04** | Identificador del carné guardado como HMAC-SHA-256 con llave por empresa | Sí |
| **FD-05** | Cobertura limitada a 0, 50 y 100 % | Sí (la lista firmada en F-2) |
| **FD-06** | Un artículo en un solo grupo por franja; la línea entra completa o no entra en la composición | Sí |
| **FD-07** | Artículo sin franja en la sede = sin restricción en esa sede; franja que cruza la medianoche, a la fecha de inicio | Sí |
| **FD-08** | Familia nueva `CIN`, tipos `TCI` (40) y `RCI` (41), series por sede con prefijos `CI` y `RC` | Sí |
| **FD-09** | Modo fiscal `NULL` = sin definir: se rechaza el ticket con dinero del empleado hasta fijar H-04 (no elige opción) | Sí |
| **FD-10** | Columna genérica `ventas.Venta.InventarioDescargadoPorId`, compartida con el Restaurante y diseñada con B | Sí |
| **FD-11** | Precisión de ADR-45: en el nivel «saldos», `com.UsoBeneficio` → `com.Saldo` BM → `com.Saldo` CN | Sí |
| **FD-12** | El cupo de nómina restante se imprime en el ticket, configurable, sí por omisión (F-5) | Sí |
| **FD-13** | Bolsa sin proceso de cierre: el mes pasado se cierra por la regla del período vigente; proceso idempotente que asegura las bolsas del mes | Sí |
| **FD-14** | Vistas por persona en `rptc`; la liquidación al administrador, sin personas, en `rpt` | Sí |
| **FD-15** | El reparto se aplica al **total con ITBIS** de la línea (lo que ve el comensal); el ITBIS de la línea del ticket es informativo y sirve a la costura | Sí |

---

## Resumen breve
- **Dos esquemas:** `com`, la capacidad común de comensales (padrón propio enlazable con `rrhh.Empleado`, categorías y centros de costo con vigencia, carné con identificador opaco guardado como HMAC, foto cifrada en la app, montos y **saldos con `UPDATE` condicional**), y `corp`, la vertical (franjas por artículo, composición, cobertura 0/50/100, ticket y reverso internos, pagos combinables, corte de nómina, costura fiscal).
- **El ticket es un documento del supertipo** (`TCI`, familia `CIN`, serie por sede sin huecos, sin NCF), con el reparto por línea en tres importes que suman el total y la salida del inventario por la clase 5 con el motivo `CONSUMO`.
- **F-5:** el ticket y el reverso guardan el saldo de la bolsa (y el cupo) **antes y después**, inmutables; el «después» sale del `OUTPUT` del `UPDATE` condicional y el disparador lo coteja con el saldo real, así que coincide aunque dos cajas consuman la misma bolsa.
- **Concurrencia:** índice único filtrado para «una vez por franja y día» y guarda optimista sobre el saldo; el reintento con el mismo `Uid` devuelve el ticket ya emitido.
- **H-04 sigue abierta:** la costura deja listos P-0, S-1, S-2 y S-6 sin migrar de nuevo; con el valor `NULL` se rechaza el dinero del empleado hasta que el propietario decida.
- **RG-14:** ninguna tabla nueva tiene columnas calculadas; no toco índices de `doc.Documento`.
- **15 puntos para firmar** (FD-01 a FD-15). Migración en 5 pasos (M1 a M5) para la entrega 3, todos aditivos.

### Cierre
- Estado: Completado (diseño; FD-01 a FD-15 **Pendientes de firma**; H-04 sigue abierta)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\datos-vertical-corporativa-2026-10-15.md` (sin commit)
- Supuestos: volúmenes y tamaños inferidos (±50 %); los ids 40/41 y el rango 51800-51849 están libres en `feature/modelo-ng` pero sin confirmar con B; zona horaria del servidor `SA Western Standard Time` (UTC−4); el DDL no se ejecutó
- Decisiones candidatas a ADR: precisión de ADR-45 (FD-11); en ADR-88, el detalle de `com` (FD-01 a FD-04); en ADR-87, la costura con el valor sin definir (FD-09) y la marca `InventarioDescargadoPorId` (FD-10, compartida con ADR-112/113)
- Entregas a otros agentes: arquitecto-software → extensión de la costura, guarda optimista y 409, proceso «Asegurar bolsas», bloques del Z con `corp`; auditor-seguridad → FD-03 y FD-04 (foto, HMAC, respaldos con fotos borradas, Ley 172-13); B (arquitecto-datos) → FD-10, ids de tipo 40/41, rango 518xx y saldos `TD`/`TP` de `CARGO_EMPRESA`; documentador-tecnico (vía B) → registrar las precisiones al firmar
- Próximo paso recomendado: que el propietario firme FD-01 a FD-15 (en especial FD-03, FD-09 y FD-10) y que B confirme ids, errores y la marca de inventario
