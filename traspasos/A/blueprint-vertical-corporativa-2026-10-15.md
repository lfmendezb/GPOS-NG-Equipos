# Blueprint técnico: vertical Corporativa y capacidad común de comensales

[Blueprint Técnico] · Arquitecto de software (equipo A) · 2026-10-15 · **Estado: diseño para la entrega 3; SW-01 a SW-18 Pendientes de firma; H-04 sigue abierta** · Sin commit · No toqué código, configuración ni bases.

**Fuente de verdad:** `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md` (**[HF]**): H-01 a H-03 y H-05 a H-11 firmadas en (a); F-1 a F-5, PF-1, PF-3 y PF-4 firmadas; **H-04 abierta**. ADR-85, 86 y 88 en Aceptado; ADR-87 en Propuesto, con la costura aceptada.
**Insumos:** **[DAT]** `traspasos/A/datos-vertical-corporativa-2026-10-15.md` (FD-01 a FD-15, pendientes de firma); **[POS]** `traspasos/A/pos-vertical-corporativa-2026-10-15.md`; **[CONT]** `traspasos/A/contable-vertical-corporativa-2026-10-15.md`; **[VRT]** `origin/b/verticales-diseno:docs/arquitectura/2026-10-07-verticales-diseno.md`; **[DF]** `origin/b/verticales-diseno:docs/arquitectura/2026-10-08-duty-free-diseno.md`; **[UX]** `traspasos/A/ux-vertical-corporativa-2026-10-15.md` (P-1 a P-12, D-1 a D-5, UQ-1 a UQ-9), con el que este documento está alineado en la sección 16.
**Código:** `GPOS NG`, rama `origin/feature/modelo-ng` en `ce33b2a8`, leído con `git show` sin cambiar el árbol de trabajo. Lo cito como `[NG] ruta:línea`.
**Convención:** *verificado* = leído en esta sesión con `ruta:línea`; *inferido* = estimación sin medir. No compilé ni ejecuté pruebas.

---

## 1. Contexto y alcance

### 1.1 Qué se diseña
La fase 1 de [HF] 2.4: módulo `CORPORATIVA` con su ventana «Facturación Corporativa», carné con foto y confirmación, padrón, franja por artículo, motor de beneficios en el servidor, ticket de consumo interno con su reverso, cobro combinado con nómina, costura fiscal sin opción elegida, perfiles del tercero, bloques del Z, corte de nómina, reportes RC-01 a RC-06, contingencia en papel y sincronización al nodo. Todo se construye en la entrega 3 (H-11).

### 1.2 Lo que existe hoy en el código (verificado)
| Pieza | Estado en `ce33b2a8` | Evidencia |
|---|---|---|
| Mecanismo de verticales (módulo, activación por el SUPER, modo de caja, `IExtensionVenta`) | **Decidido, no implementado** (tramo 3c) | [NG] `docs/adr/ADR-112.md`, «Estado de implementación» y nota del registro |
| Guarda de módulo | Solo un enganche provisional del Restaurante que da todo por activo | [NG] `src/GPOS.Core/Servicios/Modulos/Restaurante/Dispositivos/Contratos.cs:30-45` (`ModulosRestauranteProvisional`) |
| `GPOS.Componentes` | **No existe** («se crea con la entrega 3») | [NG] `docs/adr/ADR-004.md`, precisiones V-3 y DY-14 |
| Pagos combinados en la venta POS | Sí: `List<PagoPos> Pagos` | [NG] `src/GPOS.Contracts/Ventas/Pos.cs:180` ([HF] cita la línea 145 de `master`) |
| Clase de licencia por ruta | Sí: `ClaseLicencia(ClaseOperacion)`; sin marca, `POST` es `Operativa` (falla cerrada) | [NG] `src/GPOS.Api/Seguridad/ClaseLicencia.cs:23-38`; `src/GPOS.Core/Sistema/Licencia/IEstadoLicencia.cs:11-25` |
| Estado del módulo en la licencia | Sí: `IEstadoLicencia.Modulo(empresa, codigo)` → `EstadoModulo(Codigo, Vence, Estado)` | [NG] `IEstadoLicencia.cs:27`, `:63` |
| Candado de restauración | Sí: toda escritura no marcada responde 503; `PermitidaConCandado` y `SoloConsulta` | [NG] `src/GPOS.Api/Seguridad/ModoCandadoRestauracion.cs:10-16`, `:172-180` |
| Rol de sitio por ruta | Sí: `Libre`, `SoloCentral`, `SoloSucursal`; sin declaración = `SoloCentral` | [NG] `src/GPOS.Api/Seguridad/SitioRutas.cs:9-37` |
| Límites de peticiones | Sí: global 600/min por usuario, reportes 30, importaciones 10, búsqueda por número 60 | [NG] `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:10-35` |
| Reimpresión por `POST` | En la rama `origin/a/reimpresion-post` (`cd44b958`), **no unida** a `ce33b2a8` | `git merge-base --is-ancestor` negativo |
| Arqueo y resúmenes del Z | Solo suman `ventas.Venta` (`FPOS`, `DEV`), `ventas.VentaPago` y `caja.Movimiento` | [NG] `src/GPOS.Core/Consultas/Caja/ConsultasCaja.cs:152-207` |
| Reglas de módulos | Niveles 0 a 6; `Restaurante` = 6, «el núcleo nunca depende de RES» | [NG] `tests/GPOS.Tests/Arquitectura/ArquitecturaModulosTests.cs:24-40` |
| Reloj protegido | `IRelojProtegido.Ahora()` nunca retrocede | [NG] `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs:11-23` |
| Autorización de otra persona | `AutorizacionSupervisor` en la misma petición; forma B (privilegio propio, sin credencial) | [NG] `src/GPOS.Contracts/Documentos/AutorizacionSupervisor.cs:3-27` |
| ADMIN y SUPER | «Tienen todos los permisos» | [NG] `src/GPOS.Contracts/Seguridad/Permisos.cs:45` |
| Acceso multiempresa v1 | **Decidido, no implementado**: hoy cualquier usuario autenticado entra a cualquier empresa | [NG] `CLAUDE.md`, «Acceso multiempresa», nota final |

### 1.3 Principios que gobiernan el diseño
1. **El servidor decide; la pantalla presenta** (ADR-01; [VRT] 2.2). El reparto, la franja, la identidad confirmada y el modo fiscal se calculan y se comprueban en la API.
2. **La Facturación Ágil no se toca** (precisión DY-14 de ADR-112). La Corporativa tiene su página, su sesión y su guarda; lo común sale de `GPOS.Componentes` y de la ruta única.
3. **El ticket interno no es una venta** ([DAT] 2.9; [CONT] 6.4): no pasa por `POST /api/pos/ventas`. **Toda factura sí**: el visitante y el E32 de la costura salen por la ruta única.
4. **Sin estado de caja en el servidor.** No hay carrito persistido. La identidad confirmada y la cotización viajan como tokens firmados de vida corta (SW-02).
5. **Reglas declarativas primero** (ADR-52): lo que la base puede garantizar ([DAT] 3) lo garantiza. El código solo hace el reparto y la orquestación.

---

## 2. Módulos, proyectos y dependencias

### 2.1 Los tres códigos de licencia y la capacidad común (H-02 (a))
| Código | Qué es | Quién lo activa | Qué habilita |
|---|---|---|---|
| `CORPORATIVA` | **Módulo de vertical** (ADR-112, punto 1), con el modo de caja «Corporativa» | Solo el SUPER (ADR-112, punto 2) | La ventana «Facturación Corporativa», el ticket interno, el motor, la costura, el corte de nómina y los reportes RC |
| `CARGO_EMPRESA` | **Complemento del Restaurante** (antes `CORPORATIVO`, [CE] CE-06, precisado por H-02) | Solo el SUPER; requiere `RESTAURANTE` | El cargo a la empresa de [CE] CE-03 (modelo B). **Lo diseña y construye B**; aquí solo se fija su contrato con `com` |
| (sin código) `Comensales` | **Capacidad común** (como las recetas, ADR-112, punto 7): padrón, carné, foto, categorías, centros de costo, montos y saldos | Se habilita si la empresa tiene activo `CORPORATIVA` **o** `CARGO_EMPRESA` | Las rutas `/api/comensales/*` |

### 2.2 Módulos de `GPOS.Core` (SW-01)
| Módulo (carpeta) | Responsabilidad única | Depende de | Nivel propuesto en `ArquitecturaModulosTests` |
|---|---|---|---|
| **COM** `Comensales` | Padrón, carnés (resolución por HMAC), foto cifrada, categorías, centros de costo con vigencia, montos, **saldos con `UPDATE` condicional** y **uso del beneficio por franja**. No sabe qué es un almuerzo ni un ticket | `Configuracion` (sucursal, `rrhh.Empleado`), `Maestros` (`cat.Cliente`, solo modelo B), `Sistema`/`Criptografia` (HMAC, cifrado) | **5** |
| **CORP** `Corporativa` | Política de la vertical (franjas, composición, cobertura, sedes, medios, modo fiscal), **motor de beneficios**, emisión y reverso del ticket interno, costura fiscal, aporte al Z, corte de nómina, contingencia | `Comensales`, `Ventas` (ruta única, por interfaz), `Caja`, `Inventario`, `Numeracion`, `Fiscal`, `Maestros`, `Configuracion`, `Verticales` | **6** (igual que `Restaurante`) |
| `Restaurante` (B) | Usa `Comensales` para `CARGO_EMPRESA` | `Comensales` y lo suyo | 6 |
| `Verticales` (B, tramo 3c) | Catálogo, estado efectivo, guarda, registro de extensiones | `Configuracion`, licencia | Lo fija B |

**Reglas nuevas de la prueba de arquitectura** (además de la de niveles, que ya impide que el núcleo dependa de COM o CORP):
- `Comensales` no referencia `Corporativa` ni `Restaurante` (lo garantiza el nivel 5 < 6).
- **Ninguna vertical depende de otra** ([VRT] 3.2): `Corporativa` ↔ `Restaurante` prohibido en los dos sentidos. Hoy la prueba solo impide ciclos; esta regla es explícita.
- `Reportes`, `Notificaciones` e `Impresion` siguen sin recibir dependencias (regla vigente).

*Alternativas descartadas:* `Comensales` dentro de `Corporativa` (obliga al Restaurante a depender de otra vertical, contra H-02 (a)); `Comensales` en el nivel 3 junto a `Caja` (es una capacidad que el núcleo no usa; subirlo al 5 deja claro que solo lo consumen las verticales).

### 2.3 Qué va en cada proyecto
| Proyecto | Qué lleva | Qué **no** lleva |
|---|---|---|
| `GPOS.Contracts` | `Comensales/*.cs` (DTO del padrón, carnés, saldos, montos); `Corporativa/*.cs` (lectura, identificación, cotización, consumo, reverso, corte, configuración, códigos de error `CodigosCorporativa`); permisos nuevos en `Seguridad/Permisos.cs` | Lógica |
| `GPOS.Core` | `Dominio/Comensales`, `Dominio/Corporativa` (entidades y el **motor puro**); `Servicios/Modulos/Comensales`, `Servicios/Modulos/Corporativa` (orquestación transaccional); `Consultas/Comensales`, `Consultas/Corporativa` (Dapper); mapeo EF en `Datos/Empresa/Configuracion/ComConfiguracion.cs` y `CorpConfiguracion.cs` (patrón de `DocConfiguracion.cs`); `ExtensionVentaCorporativa` (visitante y costura); `AporteCierreCorporativa` | Referencias de los módulos del núcleo a COM o CORP |
| `GPOS.Criptografia` | Nada nuevo: HMAC-SHA-256 y AES-256-GCM ya son primitivas aprobadas (perfil FIPS) | Llaves en texto plano |
| `GPOS.Api` | `Endpoints/ComensalesEndpoints.cs`, `CorporativaCajaEndpoints.cs`, `CorporativaAdminEndpoints.cs`; tres políticas nuevas en `LimitesPeticiones.cs`; protector de tokens de caja (`Seguridad/TokensCorporativa.cs`) | Reglas de negocio |
| `GPOS.Reportes` y `GPOS.Reportes.Api` (B) | `Definiciones/Registrados/ReportesCorporativaRegistrados.cs` y `Consultas/Reportes/ConsultasCorporativaReportes.cs` (fuente `REG`, sobre las vistas `rpt`/`rptc` de [DAT] 7) | Lectura de `com` o `corp` directa: solo vistas |
| `GPOS.Componentes` (nuevo en la entrega 3, ADR-04 V-3) | `TarjetaComensal`, `BotoneraFranja`, `RepartoBeneficios`, `SaldoComensal`, `LectorCarne` (componente más el módulo JS `lectorCarne.js`), `DialogoSinCarne`; y, en el `PanelCobro` compartido de Duty Free, el medio «Nómina» como parámetro aditivo | Páginas |
| `GPOS.Web` | `Components/Pages/Corporativa/FacturacionCorporativa.razor` (ventana), `ReversoConsumo.razor`, y el back-office en `Components/Pages/Corporativa/Admin/` (padrón, importación, carnés, fotos, categorías, centros de costo, montos, franjas, composición, coberturas, medios, parámetros, corte de nómina) | Cambios a `Pages/Ventas/PuntoVenta.razor` ni a su pantalla de políticas |
| `GPOS.UI.MAUI` | `Components/Pages/Corporativa/FacturacionCorporativa.razor`, `ReversoConsumo.razor` y la reimpresión; **sin back-office en la fase 1** (SW-13) | Caché de fotos en disco |
| `GPOS.AgenteImpresion` | Sin cambios: recibe el trabajo ESC/POS como hoy | — |

### 2.4 La ventana propia y la Facturación Ágil
- Ruta Web y MAUI: `/ventas/corporativa`, opción de menú propia, guarda de módulo (patrón DY-01 de Duty Free).
- El modo de la caja decide la ventana (ADR-112, precisión DY-14): una caja en modo «Corporativa» abre `FacturacionCorporativa.razor`; la Facturación Ágil nunca la ve.
- **Contra la evasión por la ruta común:** una `VentaPos` enviada desde una caja en modo «Corporativa» activa siempre `ExtensionVentaCorporativa` (6.6), que aplica la franja (PF-1) y la lista de visitante. No se puede vender un plato fuera de franja llamando directamente a `POST /api/pos/ventas`.
- Prueba propuesta: ningún archivo de `Pages/Corporativa` referencia componentes de `Pages/Ventas/PuntoVenta*`, y `PuntoVenta.razor` no referencia nada de `Corporativa` (lectura de las referencias de los `.razor` compilados, como la prueba de módulos).

---

## 3. C4 (al nivel útil)

### 3.1 Contexto
```
 [Comensal]──carné──>[Lector HID]──teclado──┐
 [Visitante]                                 │
 [Cajero del tercero]──────────────┐         ▼
 [Supervisor del tercero]──────────┼──>  ( GPOS NG )  ──e-CF (visitante; S-1 si se firma)──> [Proveedor e-CF (IQ)] ──> [DGII]
 [Administrador del beneficio]─────┤        │  │
 [Finanzas de la empresa]──────────┤        │  └──archivo del corte con huella──> [Nómina / RR. HH.] (fase 2: conector)
 [SUPER de GSF]──activa el módulo y fija el modo fiscal (con motivo)
                                            └──ticket ESC/POS──> [Impresora térmica 80 mm]   [Pinpad] (el de la Estándar)
```

### 3.2 Contenedores
```
┌──────────── Sede (caja) ────────────┐        ┌──────────────── Central de la instalación ────────────────┐
│ GPOS.Web (Blazor Server)  o          │  HTTPS │ GPOS.Api (rol central)       GPOS.Reportes.Api (solo lectura)│
│ GPOS.UI.MAUI (Blazor Hybrid)         │───────>│   │  EF/Dapper                  │ vistas rpt/rptc          │
│  └ lectorCarne.js (captura la ráfaga)│        │   ▼                             ▼                          │
│ GPOS.AgenteImpresion (ESC/POS)       │        │ GPOS_SYSDATA   GPOS_<EMP> (com, corp, doc, ventas, inv, caja)│
└──────────────────────────────────────┘        └──────────────────────────────▲──────────────────────────────┘
          │ (si la sede tiene nodo, la caja habla con el nodo)                  │ sincronizador (entrega 2, ADR-53)
          ▼                                                                    │ bandeja transaccional ↑ / CHANGE_TRACKING ↓
┌──────── Nodo de sede (opcional, H-10) ────────┐                              │
│ GPOS.Api (rol sucursal) + GPOS_<EMP> local ───┼──────────────────────────────┘
└───────────────────────────────────────────────┘
```

### 3.3 Componentes (solo donde aportan: la emisión del ticket)
```
CorporativaCajaEndpoints
  ├─ ServicioLecturas ───────────> IComensales (COM): ResolverCarne(HMAC) · Tarjeta · SaldoVigente · UsoDelDia
  │                                IFotosComensal (COM): Descifrar(comensal, versión)
  ├─ ServicioCotizacion ─────────> MotorBeneficios (puro, Dominio/Corporativa)  <── PoliticaCorporativa (franjas, composición, cobertura)
  └─ EmisorConsumo ──────────────> IPoliticaPorcionPagada (costura: P0 · S1 · S2 · S6 · SinDefinir)
        ├─ Camino A (sin e-CF en el acto) ──> RegistradorConsumo ──> INumeracion · IComensales (saldos) · IInventario (clase 5) · bitácora
        └─ Camino B (S-1 con dinero) ──────> IEmisionVentaPos (VEN, ruta única) + ExtensionTicketAmparado ──> RegistradorConsumo (mismo)
AporteCierreCorporativa ──implementa──> IAporteCierreCaja (CAJ, nuevo)      ExtensionVentaCorporativa ──implementa──> IExtensionVenta (VEN)
```

---

## 4. Modelo de dominio

### 4.1 Agregados
| Agregado | Raíz y partes | Invariantes (dónde se garantizan) |
|---|---|---|
| **Comensal** (COM) | `Comensal` + historia de `Asignacion` (categoría, centro de costo, sede de referencia) + `Carne` (entidad) + referencia a la foto + `MontoComensal` | Código inmutable y nunca reutilizado; un solo carné activo; un carné reemplazado no vuelve; sin cédula; baja con fecha ([DAT] 3) |
| **Categoria** / **CentroCosto** (COM) | Catálogos con `MontoCategoria` (BM, CN) con vigencia | Clase fija `E`/`X`/`S`; montos ≥ 0 |
| **Saldo** (COM) | `Saldo` (comensal × concepto × período) + libro `SaldoMovimiento` | `Usado ≤ Límite + Ajustes`; solo cambia por consumo, reverso o ajuste con movimiento; lo escribe solo el sitio dueño (9.2) |
| **UsoBeneficio** (COM) | Una fila por comensal, fecha de servicio y franja | Único mientras no se revierta (índice único filtrado) |
| **PoliticaCorporativa** (CORP) | `Parametros`, `Sede` (listas), `FormaPagoHabilitada`, `ArticuloCobertura` | Cobertura ∈ {0, 50, 100}; sin fila = 100; modo fiscal ∈ {NULL, P0, S1, S2, S6} |
| **Franja** (CORP) | `Franja` (sede, horas, días, `EsComida`) + `ArticuloFranja` + `ComposicionGrupo`/`ComposicionArticulo` + `CategoriaFranja` | Un artículo en un solo grupo por franja (FD-06); un grupo marcado «principal» por franja de comida (SW-05) |
| **ConsumoInterno** (CORP) | Documento `TCI` + `ConsumoLinea` + `ConsumoPago` + instantánea F-5 + modo fiscal congelado | Inmutable al emitirse; reparto por línea = total; pagos = dinero del empleado; instantánea = saldo real ([DAT] 3, disparador 51810 a 51819) |
| **ReversoConsumo** (CORP) | Documento `RCI` + `ReversoLinea` + pagos negativos | No revierte más de lo consumido (`doc.LineaSaldo` clase `I`); autoriza otra persona; la bolsa de un mes pasado no se reabre |
| **CorteNomina** (CORP) | Período con estado y archivo con huella | Cerrado = inmutable; reexportar devuelve el mismo archivo |

### 4.2 Objetos de valor y servicios de dominio
- `Dinero` (decimal(19,2), redondeo **alejado de cero**, igual que `ROUND` de SQL Server: el `CHECK CK_CorpLinea_Porcion` de [DAT] lo exige; `Math.Round` por omisión usa redondeo bancario y daría diferencias de un centavo).
- `Reparto` por línea (`Beneficio`, `Bolsa`, `Empleado`) y su suma.
- `Periodo` (mes de la bolsa; quincena o mes del cupo de nómina).
- `IdentidadConfirmada` (comensal, carné, versión de la foto, modo de identificación, quién y cuándo): contenido del token de identificación.
- **`MotorBeneficios.Repartir(...)`**: función pura, sin base de datos (sección 5). Es lo que prueban CA-05 y los ejemplos E-1 a E-7.
- `RelojFranjas.FranjaDe(articulo, sede, ahoraLocal)`: con `IRelojProtegido.Ahora()` llevado a la hora local de `HoraLocal` (UTC−4).

### 4.3 Eventos de dominio (dentro de la transacción; no son mensajes asíncronos)
`ConsumoEmitido`, `ConsumoRevertido`, `BeneficioUsado`, `SaldoConsumido`, `SaldoAjustado`, `CarneBloqueado` (incluye «No es la persona»), `ComensalDadoDeBaja`, `IdentificacionSinCarne`, `ModoFiscalCambiado`, `CorteNominaCerrado`. Los consume la misma transacción para la bitácora (`audit.Bitacora`) y para la bandeja de salida de la sincronización (ADR-53, cláusula 3). *Alternativa descartada:* publicarlos después del `commit` ([VRT] 3.3: abre ventanas de inconsistencia).

---

## 5. Motor de beneficios en el servidor

### 5.1 Entradas
- Las líneas, con el artículo, la unidad, la cantidad y el **total con ITBIS de la lista de comensal de la sede** (FD-15; el precio sale del maestro, nunca de la pantalla, como en `PosService`).
- La hora local del servidor (`IRelojProtegido.Ahora()` → `HoraLocal`).
- La categoría vigente del comensal, sus franjas al 100 % (`CategoriaFranja`), el uso del beneficio de hoy, el saldo de la bolsa y el del cupo, y su estado.

### 5.2 Orden de aplicación (F-2, H-05 a H-07, PF-1; sustituye [POS] 2.4)
| Paso | Qué hace | Regla firmada |
|---|---|---|
| **0. Franja por artículo** | Para cada línea: si el artículo tiene al menos una franja en la sede (FD-07) y **ninguna contiene la hora del servidor**, la línea se rechaza con `ARTICULO_FUERA_DE_FRANJA` y el horario de la franja. Tolerancia 0. Vale igual para el visitante. La línea guarda la franja que la habilitó y la hora de la validación (`ValidadaEn`) | F-1, PF-1 |
| **1. Estado del comensal** | Si no está activo (suspendido, de baja o inhabilitado) o el carné no está activo: ni beneficio, ni bolsa, ni nómina; la pantalla ofrece atenderlo como visitante | [POS] R-E2 |
| **2. Partición** | Una línea de un artículo de la composición con cantidad entera mayor que la capacidad libre de su grupo se parte (2 jugos con capacidad 1 = 1 + 1). Una cantidad fraccionada entra entera o no entra | FD-06 |
| **3. Almuerzo o cena al 100 %** | Solo si hay una franja de comida vigente para la categoría, el comensal no la usó hoy y **la cotización incluye al menos una línea del grupo principal** (SW-05). Se llenan los grupos con las líneas candidatas **de mayor a menor importe** (empate: orden de la línea). Lo que entra: `Beneficio = Total`. Si nada entra, no se marca el uso | H-05 (a), H-06 (a) |
| **4. Bolsa** | A cada línea restante le corresponde `Porción = ROUND(Total × Cobertura / 100, 2)`. Se ordenan las porciones de mayor a menor (empate: orden de la línea) y la bolsa paga `mín(porción, saldo restante)` hasta agotarse; la última puede quedar parcial | F-2, F-3 |
| **5. Dinero del empleado** | `Empleado = Total − Beneficio − Bolsa` por línea. Se cobra con los medios habilitados (efectivo, tarjeta, nómina), combinables, con la nómina hasta el cupo del período | F-4, PF-4 |

**Comprobación con [HF] 3.6:** E-2 (galletas 120 + mitad del postre 40 = 160 de bolsa; 40 de dinero), E-3 (bolsa 100 a las galletas; dinero 20 + 80 = 100), E-4 (bolsa 25 al postre; dinero 40 + 15 = 55), E-6 (un jugo entra en la composición, el otro paga 60) y E-7 (rechazo a las 16:00) salen exactos con este orden. E-1 y E-5 también. La invariante de [HF] 3.5 se cumple: el dinero total = total − beneficio − mín(saldo, Σ porciones), porque el paso 4 llena hasta el saldo.

**ITBIS de la porción pagada** (lo usa la costura, sección 7): por línea, `Base = ROUND(Empleado / (1 + tasa), 2)` e `ITBIS = Empleado − Base`; el redondeo queda en la porción pagada ([CONT] D-04).

### 5.3 Dónde corre y qué garantiza la base
- El motor corre **dos veces**: en la cotización (para mostrar) y dentro de la transacción de la emisión (para registrar). La segunda es la que vale.
- La base garantiza el resto: el índice único de `com.UsoBeneficio` (CA-03), el `UPDATE` condicional del saldo (CA-04) y los `CHECK` y disparadores del reparto ([DAT] 3).
- **Rendimiento (inferido):** el motor es lineal en las líneas (≤ 20 por ticket): microsegundos. La cotización hace 3 a 5 búsquedas por llave (≤ 1 ms cada una, [DAT] 4.5) más la lectura de la política, que se guarda en memoria por sede con invalidación por `rowversion` (60 s como máximo de desfase; un cambio de franja se ve en la caja en menos de un minuto).

### 5.4 Validez de la línea validada (SW-06)
PF-1 dice que la franja se comprueba **al agregar** el artículo. Como no hay carrito en el servidor, «agregar» es la cotización: cada línea recibe su `ValidadaEn` dentro del token de cotización. La emisión acepta esa hora si la línea se validó hace **3 minutos o menos**; si no, la vuelve a validar con la hora de la emisión. Así, un plato agregado a las 14:29:50 y cobrado a las 14:30:20 se despacha, pero un token viejo no sirve para vender el almuerzo a las 16:00. *Alternativa descartada:* revalidar siempre al emitir, que rechaza en la caja un plato ya servido por un cobro con tarjeta de 30 segundos.

---

## 6. Contratos de la API interna

### 6.1 Convenciones comunes
- **Errores:** `ProblemDetails` con `extensions.codigo` (patrón vigente, [NG] `ModoCandadoRestauracion.cs:160-162`). Códigos nuevos en `GPOS.Contracts/Corporativa/CodigosCorporativa.cs`; los errores 51800 a 51849 de [DAT] se traducen a esos códigos.
- **Orden de las barreras:** licencia (`ClaseLicencia`) → candado de restauración → sitio → **módulo** (404 `MODULO_NO_ACTIVO`) → permiso (403) → reglas (422/409). El módulo antes que el permiso es ADR-112, punto 3.
- **Empresa:** siempre del token, nunca de la ruta (como la API de reportes).
- **Concurrencia de maestros:** `Version` opaca (`rowversion`) → 409 `REGISTRO_MODIFICADO` (código vigente, [NG] `Contracts/Documentos/CodigosConflicto.cs:13`).
- **Idempotencia:** `ClaveIdempotencia` generada en la caja antes del primer envío → mismo resultado con el mismo contenido; 409 `IDEMPOTENCIA_CONFLICTO` con otro contenido ([NG] `CodigosConflicto.cs:10`). La idempotencia se evalúa **antes** que los tokens: un reintento devuelve el ticket aunque el token ya venció.
- **Licencia sin marca:** un `POST` es `Operativa` (falla cerrada). Toda ruta de escritura marcada `Consulta` o `Esencial` entra en `tests/GPOS.Tests/Licencia/RutasLicenciaAprobadas.json` y se revisa como un cambio de seguridad ([NG] `ClaseLicencia.cs:18-21`).

### 6.2 Privilegios nuevos (en `Permisos.cs`, cada uno con la vertical que lo exige)
| Clave | Tipo | Para quién (H-09) |
|---|---|---|
| `corp-consumo` | Pantalla (Agregar) + acción Autorizar | Cajero de cafetería: leer el carné, confirmar, cotizar, emitir. Autorizar: el supervisor |
| `corp-reverso` | Pantalla (Agregar) + acción Autorizar | Cajero (solicita); supervisor (autoriza; nunca el mismo) |
| `corp-contingencia` | Privilegio | **Administrador del beneficio por omisión** ([UX] UQ-6): reservar el talonario y digitar el lote. Se puede dar al supervisor del tercero, con el riesgo de que infle su liquidación ([POS] RO-3) |
| `corp-beneficios` | Pantalla (Modificar) | Administrador del beneficio: franjas, composición, coberturas, medios, parámetros, montos |
| `com-padron` | Pantalla (Modificar) | Administrador del beneficio: padrón, importación, categorías, centros de costo, carnés |
| `com-foto` | Privilegio | Administrador del beneficio: cargar, ver y borrar fotos (cada vista va a la bitácora) |
| `com-ajuste-saldo` | Privilegio | Administrador del beneficio: ajustes de bolsa y cupo con motivo |
| `corp-nomina` | Pantalla | Nómina o RR. HH.: cerrar y reexportar el corte |
| `rep-corporativa` | Reporte | RC-06 (sin personas) y el Z: tercero y empresa |
| `rep-corporativa-personas` | Reporte | RC-01 a RC-05 y el retiro al costo (`rptc`): solo la empresa |

El Z, el arqueo y la apertura usan los privilegios vigentes de caja. El modo fiscal **no** es un privilegio: lo cambia solo el nivel SUPER.

### 6.3 Operación de la caja
| # | Método y ruta | Uso | Privilegio | `ClaseLicencia` | Límite | Sitio | Candado |
|---|---|---|---|---|---|---|---|
| C-1 | `GET /api/corporativa/sesion` | Sesión de la ventana | `corp-consumo` | Consulta (GET) | Global | `Libre` | Pasa |
| C-2 | `POST /api/corporativa/lecturas` | Lectura del carné: tarjeta, saldo y franja (F-5) | `corp-consumo` | **Consulta** + `SoloConsulta` | **`comensal-lectura`: 30/min por usuario** | `SoloSucursal` | Pasa |
| C-3 | `GET /api/corporativa/foto` (token en el encabezado `X-GPOS-Lectura`) | Foto de la lectura | `corp-consumo` | Consulta | **`comensal-foto`: 60/min por usuario** | `SoloSucursal` | Pasa |
| C-4 | `POST /api/corporativa/identificaciones` | «Confirmar identidad» | `corp-consumo` | Operativa | Global | `SoloSucursal` | Bloqueado |
| C-5 | `POST /api/corporativa/identificaciones/rechazo` | «No es la persona»: bloqueo preventivo del carné | `corp-consumo` | **Esencial** (es una medida de seguridad) | Global | `SoloSucursal` | Bloqueado |
| C-6 | `POST /api/corporativa/sin-carne/busqueda` | Búsqueda por código o nombre (F-08) | `corp-consumo` | Consulta + `SoloConsulta` | **`comensal-busqueda`: 20/min por usuario** | `SoloSucursal` | Pasa |
| C-7 | `POST /api/corporativa/sin-carne` | Identificación sin carné con autorización de otra persona | `corp-consumo` + autorizante con Autorizar | Operativa | Global | `SoloSucursal` | Bloqueado |
| C-8 | `POST /api/corporativa/consumos/cotizar` | Cotización del reparto | `corp-consumo` | **Operativa** | Global | `SoloSucursal` | Bloqueado |
| C-9 | `POST /api/corporativa/consumos` | **Emisión idempotente** del ticket | `corp-consumo` | Operativa | Global | `SoloSucursal` | Bloqueado |
| C-10 | `GET /api/corporativa/consumos/{numero}` y `GET /api/corporativa/consumos?jornada=&texto=` | Consulta | `corp-consumo` o `corp-reverso` | Consulta | Global; la búsqueda por número, `busqueda-numero` (60) | `Libre` | Pasa |
| C-11 | `POST /api/corporativa/consumos/{numero}/reversos` | Reverso | `corp-reverso` + autorizante | Operativa | Global | `SoloSucursal` | Bloqueado |
| C-12 | `POST /api/corporativa/contingencia/lotes` | Lote de vales de papel (H-10) | `corp-contingencia` + `FECHA_ANTERIOR` | Operativa | `importaciones` (10) | `SoloSucursal` | Bloqueado |
| C-13 | `POST /api/corporativa/contingencia/talonarios` · `GET /api/corporativa/contingencia/talonarios?sede=` | Reserva de un rango de vales por sede y su PDF ([UX] AC-14, P-10); el lote solo acepta números de un rango reservado y no usado (SW-18) | `corp-contingencia` | Operativa (reserva); Consulta (lista) | `importaciones` (10) | `SoloCentral` | Bloqueado |
| C-14 | `GET /api/corporativa/consumos/{numero}/reversable` | Lo que se puede devolver, por línea, **antes** de pedir la autorización ([UX] P-12) | `corp-reverso` | Consulta | Global | `Libre` | Pasa |

**Por qué la cotización es `Operativa` y no `Consulta`:** con la tarjeta, el cobro se autoriza antes de emitir ([POS] AT-4). Si la licencia o el candado bloquearan solo la emisión, el cajero cobraría la tarjeta y tendría que reversarla. Bloqueando en la cotización, el aviso llega antes de cobrar.
**Por qué la lectura es `Consulta`:** no escribe y es útil para atender como visitante; la vertical vencida (ADR-112, punto 4) la bloquea en la guarda de módulo para lo nuevo.
**Por qué la lectura es `POST`:** el identificador del carné no debe quedar en la URL ni en los registros de acceso.

#### DTO principales (resumen; los nombres siguen la convención de `GPOS.Contracts`)
```csharp
// C-2
public record LecturaCarneRequest(string Lectura, string? Tecnologia);          // la cadena completa de la ráfaga, sin prefijo ni sufijo
public record LecturaCarneDto(
    string LecturaToken, DateTime Expira,                                         // 2 min; atado a usuario, caja, empresa y comensal
    TarjetaComensalDto Comensal, FranjaVigenteDto? Franja,
    EstadoBeneficioDto Beneficio,                                                 // Disponible | Usado (hora, caja, ticket) | NoAplica
    SaldoDto? Bolsa,                                                              // F-5: saldo vigente, asignado y mes
    SaldoDto? CupoNomina,                                                         // null si no hay cupo (PF-4) o no se muestra
    IReadOnlyList<string> MediosHabilitados, bool AdmiteDineroEmpleado,           // false con el modo fiscal sin definir o S6 (FD-09)
    IReadOnlyList<AvisoDto> Avisos,                                               // foto antigua, carné por vencer, padrón desactualizado en el nodo
    UsoRecienteDto? UsoReciente,                                                  // [UX] EC-06b: el mismo carné en otra caja en los últimos 2 min (caja y hora)
    int SinCarneMes, int LimiteSinCarneMes);                                      // «Sin carné: 2 de 3 este mes»
// Carné bloqueado o comensal inactivo: no se devuelve LecturaCarneDto sino el 422 con solo el estado, la fecha y los últimos 4 (PV-5 de [UX]).
// El «usado visto» de la bolsa no viaja a la pantalla ([UX] P-1 lo pedía): va dentro del token de cotización, que la pantalla no puede alterar.
public record TarjetaComensalDto(string Codigo, string NombreCorto, string Categoria, string ClaseCategoria, string CentroCosto,
    string Estado, string CarneUltimos4, bool TieneFoto, int? VersionFoto);       // sin cédula, sin datos de contacto
public record SaldoDto(decimal Saldo, decimal Asignado, DateOnly Desde, DateOnly Hasta);

// C-4
public record ConfirmarIdentidadRequest(string LecturaToken);
public record IdentificacionDto(string IdentificacionToken, DateTime Expira);    // 10 min

// C-7
public record SinCarneRequest(int ComensalId, AutorizacionSupervisor Autorizacion);  // solo forma A: otra persona con su credencial
// responde LecturaCarneDto con ModoIdentificacion = 'M'; después, foto (C-3) y confirmación (C-4) como con carné

// C-8
public record CotizarConsumoRequest(string IdentificacionToken, IReadOnlyList<LineaConsumoRequest> Lineas,
    long Secuencia, string? CotizacionAnterior);                                  // [UX] 8.3: la pantalla descarta respuestas de una secuencia menor; con la anterior, el servidor marca lo que cambió
public record LineaConsumoRequest(string Articulo, string? Unidad, decimal Cantidad, int? Linea);
public record CotizacionDto(
    string CotizacionToken, DateTime Expira,                                      // 3 min; lleva el saldo visto (BM y CN), el uso, el modo fiscal y la huella del reparto
    IReadOnlyList<LineaRepartoDto> Lineas,
    decimal Total, decimal Beneficio, decimal Bolsa, decimal Empleado,
    SaldoDto? BolsaDespues, SaldoDto? CupoNomina,                                 // F-5: la pantalla muestra lo que quedaría
    EstadoBeneficioDto Beneficio100, IReadOnlyList<AvisoDto> Avisos,
    long Secuencia, IReadOnlyList<AvanceGrupoDto> AvanceComposicion,              // «Plato fuerte 1/1 ✓»
    FranjaVigenteDto? Franja,                                                     // con la hora del servidor y los minutos que faltan para el fin
    bool AdmiteDineroEmpleado);                                                   // false con el modo fiscal sin definir o S6; nunca expone el valor fiscal
public record LineaRepartoDto(int Linea, string Articulo, string Descripcion, decimal Cantidad, decimal Total,
    int Cobertura, string? Franja, string? GrupoComposicion, decimal Beneficio, decimal Bolsa, decimal Empleado,
    bool Cambio, int? LineaOrigen);                                               // Cambio: el reparto de la línea difiere de la cotización anterior; LineaOrigen: línea partida (FD-06)

// C-9
public record EmitirConsumoRequest(Guid ClaveIdempotencia, string IdentificacionToken, string CotizacionToken,
    IReadOnlyList<LineaConsumoRequest> Lineas, IReadOnlyList<PagoConsumoRequest> Pagos);
public record PagoConsumoRequest(string Medio /* D | N */, string? FormaPago, decimal Monto, string? Moneda, string? Referencia,
    DatosTarjetaDto? Tarjeta);                                                    // autorización, últimos 4, marca, terminal (pinpad de la Estándar)
public record ResultadoConsumoDto(string Numero, long DocumentoId, DateTime Fecha,
    decimal Total, decimal Beneficio, decimal Bolsa, decimal Empleado, decimal Nomina,
    SaldoDto? BolsaAntes, SaldoDto? BolsaDespues, SaldoDto? CupoAntes, SaldoDto? CupoDespues, string EstadoBeneficio,
    ComprobanteAmparoDto? Comprobante,                                            // solo con S-1: tipo, e-NCF y número de la E32
    decimal Cambio, string? Aviso);
```

```csharp
// C-1 ([UX] P-11 y D-2, D-3 y D-5 de [UX])
public record SesionCorporativaDto(string Caja, string Sede, long? JornadaId, bool CajaAbierta, string ModoCaja /* "CORPORATIVA" */,
    FranjaVigenteDto? Franja, IReadOnlyList<FranjaDelDiaDto> Franjas,           // con la botonera ordenada y agrupada (D-1 de [UX])
    IReadOnlyList<string> MediosHabilitados, IReadOnlyList<string> OrdenMedios,  // UQ-5
    bool NominaHabilitada, bool AdmiteDineroEmpleado, bool MostrarCupoNomina, bool MostrarEstadoComidas, bool TicketEsValeRetiro,
    ConfigLectorDto Lector,                                                      // prefijo, sufijo, umbral en ms y sonidos de la caja (D-2 de [UX])
    DateTime? PadronSincronizadoEn, DateTime? FotosSincronizadasEn,              // solo en un nodo (D-5 de [UX])
    string? Aviso);

// C-14 ([UX] P-12)
public record ConsumoReversableDto(string Numero, DateTime Fecha, string Comensal /* código y nombre corto */,
    IReadOnlyList<LineaReversableDto> Lineas, bool MesBolsaCerrado, bool CorteNominaExportado, bool DespuesDelZ);
public record LineaReversableDto(int Linea, string Descripcion, decimal Cantidad, decimal YaRevertido, decimal Beneficio, decimal Bolsa, decimal Empleado);

// C-13 ([UX] P-10)
public record ReservarTalonarioRequest(short Sucursal, int Cantidad);            // de 1 a 500 vales por reserva
public record TalonarioDto(long Id, short Sucursal, string Desde, string Hasta, int Usados, DateTime ReservadoEn, string ReservadoPor);
```

#### Errores de la operación de la caja
#### Errores de la operación de la caja
| Código | HTTP | Cuándo |
|---|---|---|
| `MODULO_NO_ACTIVO` | 404 | `CORPORATIVA` no licenciado, no activo o vencido tras la gracia (para lo nuevo) |
| `CAJA_MODO_DISTINTO` | 422 | La caja de la jornada no está en modo «Corporativa» (código de [DF] 6.2) |
| `CARNE_LECTURA_INVALIDA` | 400 | La cadena no cumple el formato de su tecnología (7.3); nunca se busca por coincidencia parcial |
| `CARNE_NO_REGISTRADO` | 404 | No hay carné con ese HMAC (mismo tiempo de respuesta que un acierto) |
| `CARNE_BLOQUEADO` | 422 | Bloqueado, perdido, reemplazado o vencido; lleva **solo** el estado y los últimos 4, sin nombre ni foto ([UX] PV-5), y «retenga el carné» |
| `COMENSAL_INACTIVO` | 422 | Suspendido, de baja o inhabilitado; lleva el estado y la fecha (`SuspendidoHasta` o `FechaBaja`), **sin el motivo** ([UX] PV-5) |
| `LECTURA_VENCIDA` / `IDENTIFICACION_VENCIDA` / `COTIZACION_VENCIDA` | 422 | Token vencido, de otro usuario, de otra caja o de otra empresa |
| `IDENTIDAD_NO_CONFIRMADA` | 422 | Cotizar o emitir sin token de identificación (CA-01) |
| `SIN_FOTO` | 422 | Sin foto: solo con la identificación sin carné (F-08) |
| `AUTORIZACION_INVALIDA` / `AUTORIZANTE_MISMO_USUARIO` | 422 | Credencial mala, sin la acción Autorizar, o el autorizante es el cajero |
| `LIMITE_SIN_CARNE` | 422 | Pasó el límite mensual (3 por omisión) de identificaciones sin carné (SW-17) |
| `ARTICULO_FUERA_DE_FRANJA` | 422 | Con el artículo, la franja y el horario (F-1, E-7) |
| `MODO_FISCAL_SIN_DEFINIR` | 422 | Dinero del empleado > 0 y el modo fiscal en `NULL` (FD-09) |
| `SIN_DINERO_EMPLEADO` | 422 | Dinero del empleado > 0 con S-6 |
| `MEDIO_NO_HABILITADO` / `NOMINA_NO_DISPONIBLE` / `CUPO_NOMINA_EXCEDIDO` | 422 | F-4 y PF-4 |
| `PAGO_NO_CUADRA` | 422 | Los pagos no suman el dinero del empleado (con el vuelto en efectivo) |
| **`REPARTO_CAMBIO`** | **409** | Lleva `motivo` (`SALDO`, `CUPO`, `BENEFICIO` o `MODO_FISCAL`) y los saldos de antes y de ahora. En la emisión, el saldo de la bolsa o del cupo cambió desde la cotización (otra caja), el almuerzo ya se usó o el modo fiscal cambió. **Lleva la cotización nueva**; la caja la muestra y el cajero vuelve a confirmar. No se reintenta solo ([POS] AT-9) |
| `IDEMPOTENCIA_CONFLICTO` | 409 | Misma clave con otro contenido |
| `JORNADA_CERRADA` | 409 | La jornada se cerró entre la cotización y la emisión |

**Emisión: qué responde el 409 `REPARTO_CAMBIO`.** Dentro de la transacción, el `UPDATE` condicional del saldo exige el `Usado` que vio el cajero ([DAT] 4.3). Si devuelve cero filas, o la inserción del uso del beneficio choca (error 2601), la transacción se deshace entera (sin número, sin marca, sin kárdex: CA-07), el servicio recalcula la cotización **fuera** de la transacción y responde 409 con ella. Con la tarjeta ya autorizada, la caja ofrece cobrar la diferencia o reversar la tarjeta por el procedimiento de la Estándar (`REVERSO_TARJETA`).

### 6.4 Reverso
`POST /api/corporativa/consumos/{numero}/reversos`
```csharp
public record ReversoConsumoRequest(Guid ClaveIdempotencia, IReadOnlyList<LineaReversoRequest> Lineas /* vacía = total */,
    string Motivo, AutorizacionSupervisor Autorizacion, string? FormaDevolucion /* null = la original */);
public record LineaReversoRequest(int Linea, decimal Cantidad, bool Servido);   // Servido: borrador de merma; no servido: vuelve a la existencia
public record ResultadoReversoDto(string Numero, decimal Beneficio, decimal Bolsa, decimal Empleado, decimal Nomina,
    SaldoDto? BolsaAntes, SaldoDto? BolsaDespues, SaldoDto? CupoAntes, SaldoDto? CupoDespues,
    ComprobanteAmparoDto? NotaCredito /* E34, solo si el ticket tiene E32 */, string? Aviso);
```
- Orden de devolución ([POS] F-04): primero el dinero del empleado, después la bolsa y por último el beneficio.
- Errores: `REVERSO_EXCEDE` (422, más de lo consumido; lo garantiza `doc.LineaSaldo` clase `I`), `AUTORIZANTE_MISMO_USUARIO` (422; lo garantiza también el disparador 51820), `CORTE_CERRADO` (409: la nómina va como ajuste del período siguiente, no se toca el corte), `MES_CERRADO` (no es error: la bolsa devuelta es 0 y el resultado lo dice en `Aviso`; regla 51821).
- Con la licencia del módulo vencida tras la gracia, el reverso **sigue permitido** (ADR-112, punto 4: lo abierto se anula). Con la empresa en solo consulta, no (como la devolución de la Estándar).

### 6.5 Corte de nómina (RC-03)
| Método y ruta | Uso | Privilegio | `ClaseLicencia` | Límite | Sitio |
|---|---|---|---|---|---|
| `GET /api/corporativa/nomina/periodos` | Períodos y su estado | `corp-nomina` | Consulta | Global | `SoloCentral` (lectura libre) |
| `POST /api/corporativa/nomina/periodos/{desde}/vista-previa` | Detalle antes de cerrar | `corp-nomina` | Consulta + `SoloConsulta` | `reportes` (30) | `SoloCentral` |
| `POST /api/corporativa/nomina/periodos/{desde}/cierre` | **Cierre y exportación en una sola operación** (AT-7), CSV o Excel, con huella SHA-256 en `X-GPOS-Huella` | `corp-nomina` | **Esencial** (SW-14) | `reportes` (30) | `SoloCentral` |
| `GET /api/corporativa/nomina/periodos/{desde}/archivo` | El mismo archivo guardado | `corp-nomina` | Consulta | `reportes` | `Libre` |

- El cierre es idempotente: un segundo cierre del mismo período devuelve el mismo archivo y la misma huella.
- **No se cierra con la sincronización atrasada:** si algún nodo con comensales del período no confirmó su bandeja hasta el fin del período, 409 `CORTE_SINCRONIZACION_PENDIENTE` con la lista de sedes. Los nodos dejan de aceptar pagos de nómina de un período ya terminado (regla del período vigente).
- Otros errores: `CORTE_PERIODO_ABIERTO` (409, el período no terminó), `CORTE_CERRADO` (no es error en el cierre: devuelve el archivo).

### 6.6 Visitante por la ruta única
- La ventana envía una `VentaPos` normal a `POST /api/pos/ventas` (sin cambios de ruta). `ExtensionVentaCorporativa` (`Vertical = "CORPORATIVA"`, `Aplica`: la caja de la jornada está en modo «Corporativa»):
  - `ValidarAsync`: la franja por artículo (PF-1 vale para el visitante);
  - `AjustarLineas`: el precio de la lista de visitante de `corp.Sede` (contrato aditivo de [DF] 6.1);
  - nada más: comprobante, NCF, inventario y «No generar comprobante» siguen la regla vigente.
- El perfil «Cajero de cafetería» necesita además el privilegio `pos` para el visitante. No le abre la Facturación Ágil: la ventana la decide el modo de la caja.

### 6.7 Administración del padrón, carnés, franjas, cobertura y montos
Todas: guarda de módulo (`CORPORATIVA` o `CARGO_EMPRESA` para `/api/comensales`; `CORPORATIVA` para `/api/corporativa`), **`SoloCentral`** (los maestros son de la central, ADR-53, cláusula 2), `Operativa` salvo que se indique, límite global salvo que se indique, y bitácora con el antes y el después.

| Recurso | Rutas | Privilegio | Particularidades |
|---|---|---|---|
| Padrón | `GET /api/comensales?texto=&estado=&categoria=&pagina=` · `GET /{id}` · `POST /` · `PUT /{id}` · `POST /{id}/estado` · `POST /{id}/asignaciones` | `com-padron` | Sin foto ni cédula en ninguna respuesta. `409 CODIGO_COMENSAL_DUPLICADO`; el código no se cambia (`422 CODIGO_INMUTABLE`). La baja con fecha; un comensal con movimientos no se elimina (precisión de ADR-08) |
| Importación por plantilla | `POST /api/comensales/importaciones/validar` (CSV o Excel ≤ 10 MB) → vista previa con altas, cambios, bajas y errores y un token · `POST /api/comensales/importaciones/{token}/aplicar` | `com-padron` | `importaciones` (10/min); `LimiteCuerpo(10 MB)`; sin fotos en la plantilla |
| Carnés | `GET /api/comensales/{id}/carnes` · `POST /api/comensales/{id}/carnes` · `POST /api/comensales/carnes/{carneId}/estado` | `com-padron` | Alta con la lectura del carné de proximidad existente, o **generación de un QR** de 128 bits aleatorios (SW-07): el contenido del QR se devuelve **una sola vez** para imprimir el plástico y nunca más (solo se guarda el HMAC). Reimprimir un QR = carné nuevo y el anterior queda «Reemplazado» |
| Foto | `PUT /api/comensales/{id}/foto` · `GET /api/comensales/{id}/foto` · `DELETE /api/comensales/{id}/foto` | `com-foto` | JPEG o PNG de hasta 2 MB (`LimiteCuerpo`, `415 FOTO_FORMATO`, `413`); el servidor la reduce a 300 × 400, **quita los metadatos (EXIF, incluida la ubicación)**, la vuelve a codificar en JPEG y la cifra (FD-03). Cada `GET` deja una línea en la bitácora. `importaciones` (10/min) |
| Categorías y centros de costo | `/api/comensales/categorias` y `/api/comensales/centros-costo` (`GET`, `POST`, `PUT /{id}`, inhabilitar) | `com-padron` | La clase de la categoría (`E`, `X`, `S`) no cambia con comensales asignados |
| Montos | `GET/POST /api/comensales/montos` (categoría × concepto × vigente desde) · `GET/POST /api/comensales/{id}/montos` (excepción con motivo) | `corp-beneficios` | Sin borrado: la vigencia la cierra la fila siguiente |
| Saldos | `GET /api/comensales/{id}/saldos` · `POST /api/comensales/{id}/saldos/ajustes` | lectura: `com-padron`; ajuste: `com-ajuste-saldo` | El ajuste se acepta solo en el **sitio dueño del saldo** (9.2): si no, `409 SALDO_EN_OTRO_SITIO`. Sitio `Libre` con la comprobación en el servicio |
| Franjas | `GET/POST /api/corporativa/franjas?sede=` · `PUT /{id}` · `PUT /{id}/articulos` · `PUT /{id}/composicion` · `PUT /{id}/categorias` | `corp-beneficios` | `422 FRANJA_INVALIDA` (horas iguales, sin días). La respuesta trae la **próxima ventana** para que el administrador vea el efecto ([DAT] R-09). `422 COMPOSICION_SIN_PRINCIPAL` (SW-05) |
| Cobertura | `GET /api/corporativa/coberturas` · `PUT /api/corporativa/coberturas/{articulo}` (0, 50 o 100) · `DELETE` (vuelve a 100) | `corp-beneficios` | FD-05 |
| Sedes, medios y parámetros | `GET/PUT /api/corporativa/sedes/{sucursal}` (listas de comensal y de visitante) · `GET/PUT /api/corporativa/formas-pago` · `GET/PUT /api/corporativa/parametros` | `corp-beneficios` | `parametros` no incluye el modo fiscal |
| **Modo fiscal** | `GET /api/corporativa/modo-fiscal` (valor e historia) · `PUT /api/corporativa/modo-fiscal` (`{ valor, motivo }`) | **Solo SUPER** (403 a cualquier otro nivel, también al ADMIN) | `ClaseLicencia(Preparacion)`; motivo obligatorio; línea en la bitácora; sección 7 |

**Precios (H-01, sub-decisión):** el tercero no tiene privilegio sobre precios ni listas. En la fase 1 la empresa registra en las listas del núcleo los precios que el tercero le propone, con la bitácora vigente. *Alternativa descartada por ahora:* un flujo de propuesta y aprobación dentro de GPOS NG (unas 0,4 sp, inferido); se agrega si un cliente lo pide (SW-10).

### 6.8 Reportes por la API de reportes
- Reportes registrados (`Fuente = 'REG'`, [NG] `src/GPOS.Reportes/Definiciones/Registrados/IReporteRegistrado.cs`), área «Corporativa», sobre las vistas de [DAT] 7:

| Clave | Reporte | Vista | Privilegio | Lo ve el tercero |
|---|---|---|---|---|
| `CORP-CONSUMO-EMPLEADO@1` | RC-01 | `rptc.CorpConsumoEmpleado` | `rep-corporativa-personas` | No |
| `CORP-BOLSA-MES@1` | RC-02 | `rptc.CorpBolsaMes` | `rep-corporativa-personas` | No |
| `CORP-CORTE-NOMINA@1` | RC-03 (consulta; el archivo sale de 6.5) | `rptc.CorpCorteNomina` | `rep-corporativa-personas` | No |
| `CORP-CENTRO-COSTO@1` | RC-04 | vista nueva en `rptc` (tramo de reportes) | `rep-corporativa-personas` | No |
| `CORP-EXCEPCIONES@1` | RC-05 | vista nueva en `rptc` | `rep-corporativa-personas` | No |
| `CORP-LIQUIDACION@1` | RC-06 | `rpt.CorpLiquidacionAdministrador` | `rep-corporativa` | Sí |
| `CORP-RETIRO-COSTO@1` | Apoyo del IT-1 (no es un reporte fiscal nuevo) | `rptc.CorpRetiroCosto` | `rep-corporativa-personas` + «Ver costos» | No |

- Rutas, ritmo y cuerpo: los vigentes de la API de reportes (`POST /api/reportes/{id}/ejecutar` con la política `reportes`, 30 por minuto por usuario; cuerpo ≤ 64 KB; exportación solo por el canal interno; [NG] `src/GPOS.Reportes.Api/Endpoints/EndpointsReportes.cs:20-60`). `ClaseLicencia`: Consulta (siempre permitidos).
- **Guarda de módulo en la API de reportes:** el reporte registrado declara `Modulo = "CORPORATIVA"`; la lista no lo muestra y la ejecución responde 404 si el módulo no está activo. Para eso la introspección de la sesión debe traer los módulos activos de la empresa (cambio aditivo; lo decide B, que consolida esa API).
- Ninguna vista lee la foto ni la cédula (CA-13).

---

## 7. La costura fiscal con H-04 abierta

### 7.1 Forma: una estrategia por modo, elegida en el servidor
```csharp
// Dominio/Corporativa: la elige EmisorConsumo con el valor congelado de corp.Parametros.ModoFiscalPorcion
public interface IPoliticaPorcionPagada
{
    string? Modo { get; }                                   // null (sin definir), "P0", "S1", "S2", "S6"
    void Validar(Cotizacion c);                             // FD-09: null o S6 con dinero > 0 → MODO_FISCAL_SIN_DEFINIR / SIN_DINERO_EMPLEADO
    bool AmparaEnElActo(Cotizacion c);                      // S1 con dinero > 0 → true: camino B
    Task AlCerrarJornadaAsync(IUnidadTrabajo u, long jornadaId, CancellationToken ct);  // S2: la E32 global; los demás, nada
}
```
- **Ninguna opción está elegida.** Las cinco implementaciones se construyen y se prueban en la fase 1 (la sección 5.3 de [HF] lo pide). El valor lo pone el propietario con H-04; en desarrollo, el SUPER pone el que se esté probando.
- **La ventana no cambia con el modo** ([HF] 5.3): la ventana solo lee `AdmiteDineroEmpleado` y, con S-1, muestra el e-NCF del resultado.
- **Falla cerrada (FD-09):** con el valor en `NULL`, la cotización ya responde `MODO_FISCAL_SIN_DEFINIR` cuando hay dinero del empleado (antes de cobrar la tarjeta) y el disparador 51815 lo vuelve a comprobar en la emisión. Los consumos cubiertos por completo se despachan. El mensaje no sugiere ninguna forma de evitarlo: «El pago del empleado todavía no está habilitado en esta empresa. Solo se pueden despachar consumos cubiertos por completo.»
- **Cambio de modo:** solo el SUPER, con motivo y bitácora ([HF] 5.3). La cotización lleva el modo en su token: si cambió antes de emitir, 409 `REPARTO_CAMBIO`. El modo queda congelado en `corp.Consumo.ModoFiscal`: encenderlo no corrige el pasado, y queda visible.

### 7.2 Dos caminos y un solo registrador (SW-03)
| Camino | Cuándo | Transacción |
|---|---|---|
| **A** | Sin dinero del empleado; o con dinero y modo P-0 o S-2 | `EmisorConsumo` abre la transacción y llama a `RegistradorConsumo` en el orden de 7.3 |
| **B** | Con dinero del empleado y modo S-1 | `EmisorConsumo` arma una `VentaPos` E32 **solo por la porción pagada** y la emite por la **ruta única** (`IEmisionVentaPos`), pasándole una extensión **interna** `ExtensionTicketAmparado` que registra el ticket con el mismo `RegistradorConsumo`, dentro de la misma transacción. El E32 lleva `InventarioDescargadoPorId` = el ticket (FD-10): no mueve el kárdex |

- La extensión del camino B **no** viaja en el contrato HTTP: la recibe `IEmisionVentaPos` por una sobrecarga interna del servidor. Un cliente no puede pedir «inventario ya descargado» desde `POST /api/pos/ventas`.
- **Las líneas del E32:** el mismo artículo y la misma cantidad que la línea del ticket; el importe es la base de la porción pagada (5.2). El precio unitario se calcula para que `ROUND(cantidad × precio, 2)` dé la base exacta; con 6 decimales de precio eso siempre es posible para cantidades menores de 10.000 (el paso de 10⁻⁶ × cantidad es menor que un centavo). Cliente genérico (por debajo de RD$250.000, ADR-108). Pagos: los del ticket; la nómina, con una forma de pago de clase «nómina» (necesidad para Datos y para el contable, sección 12).
- **Sin secuencia E32 disponible:** la ruta única rechaza y el ticket con dinero no se emite (falla cerrada, como toda factura). Los consumos cubiertos por completo siguen por el camino A.
- **S-2:** el ticket sigue el camino A con `ModoFiscal = 'S2'`; `AlCerrarJornadaAsync` emite, dentro del Z, un E32 por caja y día por la ruta única y llena `corp.ConsumoComprobante` (N tickets : 1 E32). **Falta en FD-10:** la marca `InventarioDescargadoPorId` es 1:1 y no sirve para un E32 que ampara N tickets. Se resuelve con Datos y B solo si se firma S-2 (sección 12).
- **Reverso con S-1:** además del `RCI`, una **E34** enlazada al E32 por la ruta única de la nota de crédito, sin mover el kárdex (lo mueve el reverso) y **con el reembolso hecho por el reverso**. Hoy la devolución POS emite la nota como saldo a favor con vencimiento (Q-4, [NG] `Pos.cs`, `ResultadoDevolucionPos`); hace falta una variante aditiva del núcleo para la nota «reembolsada por un documento acompañante» (sección 12).
- *Alternativas descartadas:*
  - la ruta única en fases con un plan de bloqueos combinado: refactoriza lo más probado del núcleo;
  - el E32 en una segunda transacción por la bandeja: deja dinero cobrado sin comprobante si falla, contra [CONT] 6.6, punto 4, y el disparador 51818;
  - que la Corporativa arme el E32 por su cuenta: es la «ruta de facturación propia» que ADR-112 descarta.

### 7.3 Orden de bloqueos del ticket (precisión de ADR-45; FD-11 y SW-04)
1. **jornada** (apertura implícita, como la venta);
2. **documentos**: el `GPOS.Doc:` del consumo en el reverso; ninguno en la emisión;
3. **configuración**: compartido de la guarda de emisión y lectura de `corp.Parametros` (modo fiscal);
4. **series**: en el camino A, la de `TCI`; en el camino B, la de `FPOS` (la toma la ruta única) y después la de `TCI` (la aporta la extensión con el método aditivo `SeriesAdicionales`), en orden ordinal del código del tipo;
5. **NCF** (solo camino B);
6. **caja**;
7. **saldos**: `com.UsoBeneficio` (inserción) → `com.Saldo` BM → `com.Saldo` CN, en orden de llave (aditivo `RegistrarSaldosAsync` en el camino B);
8. **filas**: los movimientos de la clase 5 por `IInventario`, con la política de negativos de la empresa (ADR-112, punto 8).

Los dos caminos usan el mismo orden. Una prueba compara las secuencias de recursos de los dos caminos con la de la venta. **Cambios aditivos a `IExtensionVenta`** (los decide B, dueño del contrato): `SeriesAdicionales`, `RegistrarSaldosAsync` y los movimientos de inventario de un documento acompañante, con implementación vacía por omisión, como `AjustarLineas` en [DF] 6.1.

**Costo del tramo retenido (inferido):** con la serie por sede, unos 6 ms por emisión (ADR-45, T-28). Una sede de 2.000 comensales en el pico llega a unos 35 tickets por minuto: 0,6 por segundo × 6 ms ≈ 0,4 % del tiempo con la serie tomada. El camino B suma la serie FPOS y el NCF: unos 12 ms, todavía menos del 1 %.

---

## 8. Seguridad de arquitectura

### 8.1 Autenticación y sesión
- La sesión vigente (token JWT con usuario, nivel, empresa y sucursal; los permisos se leen en el servidor). La ventana no introduce credenciales nuevas.
- **Tokens de la caja (SW-02):** `LecturaToken` (2 min), `IdentificacionToken` (10 min) y `CotizacionToken` (3 min), protegidos con Data Protection (propósito `GPOS.Corporativa.Caja.v1` más el código de la empresa) y atados a usuario, caja, empresa y comensal. No se guardan en la base. Con un token de otro usuario, caja o empresa, o vencido: 422. *Alternativa descartada:* una tabla de identificaciones confirmadas, que escribe en la base en cada lectura (unas 700 filas por sede y día que nadie consulta) y debe sincronizarse.

### 8.2 Perfiles del tercero (H-09 (a))
| Perfil | Privilegios | Nunca |
|---|---|---|
| Cajero de cafetería | `corp-consumo`, `corp-reverso` (solicita), `pos` (visitante), apertura y X de su caja | Padrón, foto fuera de la identificación, beneficios, montos, franjas, coberturas, precios, reportes con personas |
| Supervisor de cafetería | Lo del cajero + acción Autorizar en `corp-consumo` y `corp-reverso`, Z y arqueo; `corp-contingencia` solo si la empresa se lo da (UQ-6), `rep-corporativa` | Lo mismo que el cajero |
| Administrador del beneficio (empresa) | `com-padron`, `com-foto`, `com-ajuste-saldo`, `corp-beneficios`, `corp-contingencia`, `rep-corporativa-personas` | Caja |
| Nómina (empresa) | `corp-nomina`, `rep-corporativa-personas` | Caja y beneficios |

- **Riesgo verificado:** ADMIN y SUPER tienen todos los permisos ([NG] `Permisos.cs:45`). Un usuario del tercero con nivel ADMIN rompería la segregación. **SW-09:** marcar la cuenta (y, cuando exista, la membresía) como «Personal del administrador externo»; el servidor le **recorta** siempre el nivel ADMIN y los privilegios `com-*`, `corp-beneficios`, `corp-nomina`, precios y listas, aunque un perfil se los dé. CA-09 se prueba también con un perfil mal configurado. Costo: unas 0,2 sp (inferido). *Alternativa:* solo el control procedimental y el reporte de cambios de permisos en RC-05 (más barato, pero depende de que nadie se equivoque).
- **Autorizaciones:** el reverso y la identificación sin carné exigen la **forma A** de `AutorizacionSupervisor` (otra persona con su credencial). La forma B (el privilegio del propio usuario) se rechaza en estos dos casos, porque H-08 y H-09 piden otra persona: 422 `AUTORIZANTE_MISMO_USUARIO`, y en el reverso además el disparador 51820. **En la pantalla**, `DialogoAutorizacionSupervisor` recibe un parámetro aditivo `PermitirPropio = false` que oculta «Autorizo yo» ([UX] P-6); la regla vale igual sin él, porque la decide el servidor. El SUPER no autoriza por credencial (ADR-81, punto 8, vigente en `PosEndpoints.cs`).
- **«No es la persona» desde la caja** ([UX] P-7, UQ-1): el perfil del cajero puede hacer **solo** la transición del carné de Activo a Bloqueado con el motivo fijo «No es la persona en la caja» (C-5); desbloquear o reemplazar es de la empresa (`com-padron`). Si el propietario responde UQ-1 con «solo registrar», C-5 deja la línea en RC-05 sin cambiar el estado; el contrato no cambia.

### 8.3 Aislamiento entre empresas
- **Base por empresa** ([DAT] 1.1): ninguna tabla nueva lleva `EmpresaId`; la conexión sale de la empresa del token.
- **Llave HMAC del carné por empresa:** el mismo UID de proximidad da HMAC distintos en dos empresas; una lectura en la empresa A nunca resuelve un comensal de la B.
- **Tokens de la caja** con la empresa en el propósito: un token de A no se abre en B.
- **Modelo B (`CARGO_EMPRESA`):** toda consulta de `com` en el Restaurante filtra por `ClienteId` de la cuenta; en la Corporativa, `ClienteId IS NULL` siempre (lo fija el repositorio de COM con un parámetro obligatorio; prueba de arquitectura sobre las consultas registradas).
- **Riesgo Alto, verificado en `CLAUDE.md`:** el acceso multiempresa v1 no está implementado y hoy un usuario autenticado puede entrar a otra empresa del mismo dueño. Un cajero del tercero podría entrar a otra empresa de la instalación. **Condición antes del primer cliente:** la versión 1 del acceso multiempresa (membresía por empresa) o una instalación por empresa cliente.

### 8.4 El lector del carné como teclado
| Riesgo | Control |
|---|---|
| **Inyección de teclas:** un QR falsificado puede traer `Enter` o combinaciones que disparen «Confirmar identidad» o «Despachar» sin que el cajero mire la foto | `lectorCarne.js` captura la ráfaga en la fase de captura del documento, desde el **prefijo** hasta el **sufijo** del lector (configurados por caja, D-2 de [UX]), y **descarta toda tecla de la ráfaga**, incluido `Enter`. La confirmación es **`Enter` como propone [UX] 2.2**, pero solo una pulsación **posterior** al fin de la ráfaga y al menos 500 ms después de que la foto se pintó; antes, `Enter` no hace nada (SW-07) |
| **Contenido malicioso** (texto largo, caracteres de control, marcado) | El servidor valida el formato por tecnología: QR `^GPC:[A-Z2-7]{26}$` (el prefijo de contenido de [UX] 6.3 más 128 bits en base32), proximidad `^[0-9A-F]{8,20}$`, barras `^[0-9A-Z]{6,30}$`; si no cumple, 400 sin buscar. Nunca se busca por coincidencia parcial ([POS] H-1). El valor no se muestra (Blazor codifica la salida de todos modos), no se escribe en los registros (solo los últimos 4 y el comienzo del HMAC) y viaja en parámetros tipados (`varchar` con su largo, ADR-50) |
| **Carné tecleado a mano** (el cajero conoce un número y lo escribe) | Para la API, una ráfaga y un tecleo son iguales: el control del cliente es solo una barrera. Por eso: (1) el QR lleva 128 bits aleatorios que genera el sistema y se entregan una sola vez; el número del carné de proximidad no está impreso; (2) el JS rechaza entradas con más de 35 ms entre teclas y sin prefijo; (3) límite de 30 lecturas por minuto y por usuario, y alerta en RC-05 a partir de 5 carnés desconocidos seguidos; (4) RC-05 marca el mismo carné en dos cajas o en dos sedes en pocos minutos. **Riesgo residual: Medio** con carnés de proximidad de 125 kHz o Mifare por UID, que se clonan (lo dice [POS] H-1). Se cierra con DESFire o con la tableta con PIN (fase 2) |
| **El prefijo que distingue el lector de carné del de artículos** ([UX] 6.3: prefijo y sufijo configurados en el lector por caja, por ejemplo `F13` o `~C` y `Enter`; o `GPC:` dentro del contenido del QR que genera GPOS; sin prefijo, el tiempo entre teclas) | **Validado como lo que es: un control de enrutamiento, no de autenticidad.** (1) Sirve para que la ráfaga no caiga en el campo con el foco ni dispare atajos: la captura global descarta todas las teclas entre el prefijo y el sufijo, **incluido el `Enter` del sufijo y cualquier `Enter` que traiga un QR falsificado**, así que la inyección de teclas queda cerrada en los tres modos. (2) **No** prueba que hubo un carné: `~C` y `GPC:` se teclean, y un QR con `GPC:` lo fabrica cualquiera. Por eso: se recomienda, donde el lector lo admita, un prefijo **que un teclado común no produce** (`F13` a `F24` o un carácter de control); `GPC:` solo se usa con un lector de mano compartido. (3) **Sin prefijo** (tiempo entre teclas), el riesgo de confundir una lectura con lo tecleado sube: la configuración de la caja lo avisa ([UX] 6.3) y el servidor exige igual el formato estricto. (4) El servidor **no recibe ni confía** en el modo de captura: los controles reales son el formato estricto, los 128 bits del QR, el límite de lecturas y RC-05 (fila anterior). Riesgo residual sin cambio: **Medio** con carnés de proximidad clonables |
| **Rotación de la llave HMAC** | Solo se guarda el HMAC, así que no se puede recalcular sin el carné. La llave lleva versión; la lectura prueba la vigente y, si falla, la anterior, y al acertar reescribe el HMAC con la vigente (migración perezosa). Necesita la columna de versión de la llave en `com.Carne` (sección 12) |

### 8.5 Custodia de la foto (se entrega al auditor-seguridad)
- **En reposo:** dentro de la base, en su tabla aparte, AES-256-GCM con la construcción de ADR-67, punto 3 (FD-03).
- **En tránsito:** solo por C-3, con un `LecturaToken` vigente, atado al comensal y a la versión, con un máximo de 3 lecturas por token. Respuesta con `Cache-Control: no-store, private`, `X-Content-Type-Options: nosniff`, sin nombre de archivo. No hay ruta que liste fotos ni que entregue una por el `Id` del comensal a la caja.
- **En el cliente:** en la Web (Blazor Server) la foto la pide el servidor Web y llega al navegador como `data:` dentro del componente: no hay URL que copiar ni caché del navegador. En MAUI, solo en memoria, con un máximo de 50 fotos por sesión, y se descarta al cerrar la sesión. **No hay caché en disco** (contra la sugerencia de 15 MB en caché de [POS] H-2; el ahorro es poco: unos 45 KB por lectura en la red local, inferido < 10 ms).
- **Vista administrativa:** solo con `com-foto`, y cada vista va a la bitácora.
- **Borrado:** a los 90 días de la baja, por el trabajo de retención (único `DELETE` en `com`). Los respaldos la conservan hasta que vencen ([DAT] 8).
- **Para el auditor-seguridad:** Ley 172-13 (si la foto es un dato sensible y si hace falta un consentimiento escrito), la retención en los respaldos, el borrado en los nodos y la vista administrativa.

### 8.6 Secretos
| Secreto | Dónde vive | Quién lo recibe |
|---|---|---|
| Llave HMAC del carné, por empresa y versión | Generada al activar el módulo; envuelta con el anillo de Data Protection (H-17 v2, `CifradorAnillo`) en la base de la empresa | La API de la central y, envuelta para él, el nodo (9.2) |
| KEK de las fotos | La de ADR-67 | Igual |
| Propósitos de Data Protection de los tokens | Anillo del sitio | Solo la API que los emitió (cada sitio tiene su anillo; ADR-53, cláusula 6) |

Ninguno va en `appsettings` ni en texto plano (ADR-44). Ninguno cambia el perfil FIPS: HMAC-SHA-256 y AES-256-GCM son algoritmos aprobados.

---

## 9. Sin conexión y sincronización al nodo (H-10 (a))

### 9.1 Qué hace cada sede
| Sede | Sin internet |
|---|---|
| **Con nodo** (recomendado desde unas 150 comidas por franja) | Todo funciona contra el nodo: padrón, carnés, fotos, franjas, beneficios y los saldos de los comensales cuya sede de referencia es esa. La sincronización sube después |
| Sin nodo | No hay venta (ADR-53): contingencia en papel con vales y el lote de C-12; los visitantes no se atienden. La SQLite local llega después de las olas (ADR-53; [DAT] R-O6) |

### 9.2 Quién es dueño de qué (ADR-53, cláusula 2)
| Dato | Dueño | Dirección |
|---|---|---|
| Padrón, categorías, centros de costo, montos, franjas, composición, coberturas, parámetros (con el modo fiscal) | Central | Central → nodo |
| **Bloqueos y bajas** (`com.Carne.Estado`, `com.Comensal.Estado`) | Central | Central → nodo, en la **clase de seguridad** de la cláusula 7 (5 minutos p95 con conexión), antes que el resto |
| Fotos | Central | Central → nodo, canal de baja prioridad por trozos; la DEK se **vuelve a envolver** para la KEK del nodo |
| Llave HMAC | Central | Central → nodo, envuelta para el nodo, una vez por versión |
| **`com.Saldo`** | El **sitio de la sede de referencia** del comensal (su nodo, o la central si la sede no tiene nodo) | Lo escribe solo el dueño; los demás reciben su libro |
| Tickets, reversos, usos, movimientos de saldo, kárdex, bitácora | El sitio que los emite | Nodo → central por la bandeja |

- **Fuera de su sede de referencia** (fase 1), con o sin conexión: el almuerzo y la cena sí, con la marca local; **la bolsa y la nómina no**; el resto, con dinero. Los saldos consolidados entre sedes son la fase 2 ([HF] 2.5, punto 8) (SW-15).
- **Conflicto del uso duplicado:** cuando la central recibe un `UsoBeneficio` que choca con otro de la misma fecha y franja (dos sitios aislados), lo inserta con `Excepcion = 1` (fuera del índice único) y sale en RC-05. No se rechaza: «la venta siempre gana» (ADR-53, cláusula 5).
- **«Asegurar bolsas del mes»** corre en el sitio dueño (al arrancar y a las 00:05 del servidor); es idempotente ([DAT] 2.8).
- **Corte de nómina:** solo en la central y con la sincronización al día (6.5).
- **Revocación con el nodo aislado:** un carné perdido puede consumir en un nodo aislado hasta la reconexión (riesgo aceptado en [POS] R-O4); la foto lo mitiga.
- **Costo:** registrar las tablas de `com` y `corp` en el catálogo de la sincronización, la clase de seguridad y la nueva envoltura de llaves: unas 0,4 sp (inferido). **No estaba en la estimación de [HF] 8.1.**

---

## 10. Impresión del ticket interno (F-5)

### 10.1 Contenido
- Encabezado fijo **«CONSUMO INTERNO – NO ES UN COMPROBANTE FISCAL»** ([HF] H-03 (a)). **Lo pone el motor de impresión, fuera de la plantilla**, como la marca «sin valor fiscal» de la vista previa: el ADMIN no puede quitarlo con el diseñador gráfico (SW-11).
- Número de la serie interna, fecha y hora, sede y caja, código y nombre corto del comensal (sin cédula ni foto), franja, líneas, reparto (Almuerzo/Cena, Bolsa, Pagado con cada forma) y cajero.
- **Saldo de la bolsa antes y después** (`corp.Consumo.BolsaAntes` y `BolsaDespues`), del `OUTPUT` del `UPDATE` condicional ([DAT] 4.3): lo impreso es el saldo real aunque dos cajas consuman la misma bolsa.
- El cupo de nómina restante, si `MostrarCupoNomina` (FD-12), y el estado del almuerzo o la cena de la franja.
- Formatos nuevos en `TiposFormato`: `TicketConsumo` y `TicketReversoConsumo`. El reverso imprime su propio saldo resultante.

### 10.2 Impresión y reimpresión por `POST` (patrón de `cd44b958`)
- `POST /api/impresion/consumo/{numero}` y `POST /api/impresion/reverso-consumo/{numero}` con `{ formato, papel, reintento }`; `ClaseLicencia(Consulta)` + `SoloConsulta`, en `RutasLicenciaAprobadas.json` y en la lista aprobada del candado. Sitio `Libre`. Privilegio `corp-consumo`.
- La **reimpresión lee la instantánea guardada**, nunca el saldo actual: muestra lo mismo que se imprimió, con la marca «COPIA n» del punto siguiente.
- **Copias contadas del ticket como vale de comida (SW-11, [UX] P-8 y UQ-3).** Hoy un documento sin NCF se imprime libre y no se cuenta: `EstadoImpresionDto` devuelve 0 impresiones sin NCF (verificado, [NG] `src/GPOS.Contracts/Impresion/Reimpresion.cs:15-19`), y `ReglasReimpresion.Decidir` solo se aplica a los comprobantes fiscales ([NG] `src/GPOS.Core/Servicios/Nucleo/ReglasReimpresion.cs:15-34`). Para el `TCI` y el `RCI`:
  1. **toda impresión se registra en `doc.Impresion`** con la misma decisión de `ReglasReimpresion` (original, reintento o «COPIA n»), incluido el reintento por falla de la impresora (hasta 2 en 10 minutos, por quien imprimió);
  2. con `TicketEsValeRetiro` (parámetro de la empresa, **sí por omisión**, D-3 de [UX]), la copia dice **«COPIA n · NO VÁLIDA PARA RETIRAR ALIMENTOS»**, la pone el motor de impresión (no la plantilla) y sale en RC-05; sin el parámetro, solo «COPIA n»;
  3. la copia **no pide autorización**: la marca ya le quita el valor de vale, y pedir un supervisor en la hora pico frena la fila. `EstadoImpresionDto` cuenta también estos dos tipos (cambio aditivo: la regla es «fiscal **o** vale»), para que el botón diga «Impreso n veces»;
  4. el reintento tras una falla imprime como original solo dentro de esa ventana; así, decir «falló la impresora» para obtener dos vales queda acotado a 2 y en la bitácora (H-4 de la revisión de VE-01).
  *Alternativa descartada:* exigir la autorización de VE-01 (lo que proponía la primera versión de este blueprint): cierra lo mismo con más fricción.
- **Con S-1, dos piezas en el mismo trabajo:** el ticket interno (con la leyenda) y la representación impresa del E32 en el formato de la Estándar (sin la leyenda), separadas por un corte. La leyenda nunca aparece sobre el E32. Lo confirma el especialista-contable.
- La impresión no forma parte de la transacción ([POS] AT-3).

---

## 11. Estructura de proyectos y carpetas
```
src/GPOS.Contracts/
  Comensales/        Padron.cs  Carnes.cs  Saldos.cs  Montos.cs
  Corporativa/       Caja.cs (lectura, identificación, cotización, consumo)  Reversos.cs  Nomina.cs  Configuracion.cs  CodigosCorporativa.cs
  Seguridad/Permisos.cs                              (privilegios nuevos de 6.2)
src/GPOS.Core/
  Dominio/Comensales/      Comensal.cs  Carne.cs  Saldo.cs  UsoBeneficio.cs  Categoria.cs  CentroCosto.cs
  Dominio/Corporativa/     Franja.cs  Composicion.cs  PoliticaCorporativa.cs  ConsumoInterno.cs  ReversoConsumo.cs
                           MotorBeneficios.cs  RelojFranjas.cs  IPoliticaPorcionPagada.cs
  Servicios/Modulos/Comensales/   ServicioPadron.cs  ServicioCarnes.cs  ServicioFotos.cs  ServicioSaldos.cs  AseguradorBolsas.cs  IComensales.cs
  Servicios/Modulos/Corporativa/  ServicioLecturas.cs  ServicioCotizacion.cs  EmisorConsumo.cs  RegistradorConsumo.cs
                                  PoliticasPorcion/ (SinDefinir, P0, S1, S2, S6)  ExtensionVentaCorporativa.cs  ExtensionTicketAmparado.cs
                                  ServicioReversos.cs  ServicioCorteNomina.cs  ServicioContingencia.cs  AporteCierreCorporativa.cs
  Consultas/Comensales/  Consultas/Corporativa/
  Datos/Empresa/Configuracion/    ComConfiguracion.cs  CorpConfiguracion.cs
src/GPOS.Api/Endpoints/   ComensalesEndpoints.cs  CorporativaCajaEndpoints.cs  CorporativaAdminEndpoints.cs
src/GPOS.Api/Seguridad/   TokensCorporativa.cs   (y las tres políticas en LimitesPeticiones.cs)
src/GPOS.Componentes/     Corporativa/ TarjetaComensal.razor  BotoneraFranja.razor  RepartoBeneficios.razor  SaldoComensal.razor
                          LectorCarne.razor  DialogoSinCarne.razor   wwwroot/lectorCarne.js
src/GPOS.Web/Components/Pages/Corporativa/   FacturacionCorporativa.razor  ReversoConsumo.razor  Admin/…
GPOS.UI.MAUI/Components/Pages/Corporativa/   FacturacionCorporativa.razor  ReversoConsumo.razor
src/GPOS.Reportes/        Definiciones/Registrados/ReportesCorporativaRegistrados.cs  Consultas/Reportes/ConsultasCorporativaReportes.cs
tests/GPOS.Tests/         Corporativa/ (motor E-1 a E-7, concurrencia CA-03 y CA-04, atomicidad CA-07, orden de bloqueos)  Arquitectura/ (reglas de 2.2 y 2.4)
```
Ningún proyecto nuevo salvo `GPOS.Componentes`, que ya está decidido (ADR-04, V-3). Se respeta la convención `GPOS.{Área}` de `CLAUDE.md`.

---

## 12. Necesidades para Datos, Integraciones y el núcleo

| Para | Necesidad | Por qué |
|---|---|---|
| arquitecto-datos | `corp.ComposicionGrupo.EsPrincipal bit` con un `CHECK` (exactamente un grupo principal por franja de comida) | SW-05 |
| arquitecto-datos | `com.Carne.HmacVersion tinyint` | Rotación de la llave (8.4) |
| arquitecto-datos | Forma de pago de clase «nómina» en `cat.FormaPago` (no entra en el arqueo) | Camino B: la porción por nómina dentro del E32 |
| arquitecto-datos y B | La marca de FD-10 para S-2 (un E32 que ampara N tickets) | 7.2; solo si se firma S-2 |
| arquitecto-datos | **D-1 de [UX]:** botonera por sede y franja: `corp.BotonArticulo` (sede, franja o «siempre disponible», grupo visual, orden, artículo), configuración sin referencias (se borra por fila, con la bitácora). Viaja al nodo con la configuración y llega a la pantalla en `SesionCorporativaDto.Franjas` | VC-02; la sesión de C-1 |
| arquitecto-datos | **D-2 de [UX]:** lector por caja: `corp.CajaLector` (caja, prefijo, sufijo, umbral en ms, sonidos), configurada en la central; el prefijo no es un secreto (8.4) | 8.4 y C-1 |
| arquitecto-datos | **D-3 de [UX]:** en `corp.Parametros`: `MostrarEstadoComidas` (sí), `TicketEsValeRetiro` (sí, SW-11), `FirmaNomina` (no, hasta UQ-4) y `OrdenMedios` (efectivo primero, UQ-5); tabla temporal como el resto de los parámetros | 10.1, 10.2 y el cobro |
| arquitecto-datos | **D-4 de [UX]:** talonario: `corp.Talonario` (sede, desde, hasta, reservado por y en) con rangos sin solape por sede (restricción o disparador) y `corp.Consumo.ValeNumero` validado contra un rango reservado en el disparador de emisión del lote | C-12, C-13 y SW-18 |
| arquitecto-datos | **D-5 de [UX]:** en el nodo, la fecha de la última aplicación de la bajada por conjunto (padrón y fotos). La lleva el catálogo de la sincronización de la entrega 2 (no es una tabla de `com`); la sesión de C-1 la expone | 9.2 y C-1 |
| arquitecto-datos | Contar las impresiones del `TCI` y del `RCI` en `doc.Impresion` (hoy solo se cuentan los fiscales) | SW-11 |
| arquitecto-datos | Confirmar que `rptc` de RC-04 y RC-05 sale de las tablas de [DAT] sin índices nuevos | 6.8 |
| especialista-contable | La forma de pago de la nómina en el E32 y la impresión en dos piezas con S-1 | 7.2 y 10.2 |
| arquitecto-integraciones | Ninguna en la fase 1: el E32 y la E34 salen por la ruta única y su conector de e-CF vigente; el corte de nómina es un archivo. El conector de nómina es la fase 2 | — |
| núcleo de ventas (dueño de la ruta única) | Sobrecarga interna de `IEmisionVentaPos` con extensiones del servidor; métodos aditivos de 7.3; nota de crédito «reembolsada por un documento acompañante» y sin kárdex | Camino B y reverso con S-1 |
| núcleo de caja | `IAporteCierreCaja` en `Caja`: dinero esperado por forma y moneda (entra en el arqueo) y bloques informativos (no entran) | El Z de hoy solo suma ventas y movimientos ([NG] `ConsultasCaja.cs:152-207`) |

**Regla del Z (SW-12): cada peso del empleado cuenta una sola vez.** Si un E32 ampara el dinero (S-1, o S-2 ya emitido), el núcleo lo cuenta por `ventas.VentaPago`; si no (P-0), lo cuenta el aporte de la Corporativa por `corp.ConsumoPago`. La nómina nunca entra en el arqueo. Prueba: CA-08 y CA-11 con los cuatro modos.

---

## 13. Tramos de construcción y estimación (entrega 3, después de 3c)

### 13.1 Dependencias con B (bloqueantes salvo que se diga)
| # | Dependencia | Dueño | Efecto si no está |
|---|---|---|---|
| DB-1 | **Mecanismo de verticales** (3c): módulo, activación por el SUPER, modo de caja, guarda, `IExtensionVenta`, regla de arquitectura | B | No se puede empezar T4 ni T5 |
| DB-2 | `GPOS.Componentes` y el `PanelCobro` de Duty Free, con el medio «Nómina» como parámetro aditivo | B (Duty Free) | T4 tendría que escribir su propio panel (+0,3 sp, inferido) |
| DB-3 | **FD-10**, la marca de inventario compartida con el Restaurante (3b), y los métodos aditivos de 7.3 | B con A | Bloquea el camino B (S-1); el camino A no lo necesita |
| DB-4 | Ids de tipo 40 y 41, rango de errores 51800 a 51849 y los saldos `TD`/`TP` de `CARGO_EMPRESA` | B | Choques al unir |
| DB-5 | Módulos activos en la introspección de la API de reportes | B | Los reportes RC se verían sin el módulo (no bloquea T9) |
| DB-6 | Sincronizador de la entrega 2 (ADR-53) | Quien construya la entrega 2 | T11 no tiene sobre qué registrarse |
| DB-7 | **Acceso multiempresa v1** | A | Riesgo Alto de 8.3 antes del primer cliente (no bloquea la construcción) |

### 13.2 Tramos (inferido, ±40 %)
| Tramo | Contenido | sp | Depende de |
|---|---|---|---|
| T1 | Capacidad `com`: M1 de [DAT], padrón, importación, categorías, centros de costo, carnés con HMAC y QR, foto (reducción, sin metadatos, cifrado), privilegios, back-office Web | 1,4 | — (puede empezar antes de 3c) |
| T2 | Configuración `corp`: M2, franjas, composición con grupo principal, coberturas, sedes, medios, parámetros, modo fiscal del SUPER, back-office Web | 0,6 | T1 |
| T3 | Motor de beneficios puro + saldos (`UPDATE` condicional, uso del beneficio, «Asegurar bolsas», alta proporcional, cupo) con E-1 a E-7, CA-03 y CA-04 | 1,05 | T1, T2 |
| T4 | Ventana Web y MAUI: lectura, tokens, foto servida, confirmación, sin carné, `lectorCarne.js`, componentes, visitante (`ExtensionVentaCorporativa`) | 1,2 | DB-1, DB-2, T3 |
| T5 | Emisión atómica: M3, camino A, estrategias de la costura (todas), FD-09, impresión F-5; métodos aditivos de 7.3 y prueba del orden | 1,2 | DB-1, T3 |
| T6 | Reverso (antes y después del Z, después del mes y del corte) | 0,4 | T5 |
| T7 | Nómina: cupo, medio combinable, corte con huella y bloqueo | 0,5 | T5 |
| T8 | `IAporteCierreCaja`, bloques del Z, perfiles del tercero y el recorte del personal externo (SW-09) | 0,85 | T5 |
| T9 | Reportes RC-01, 02, 04, 05, 06 y el retiro al costo (M5) por la API de reportes | 0,95 | T5, DB-5 |
| T10 | Contingencia en papel: lote y talonario de vales (SW-18) | 0,25 | T5 |
| T11 | Sincronización al nodo (9.2) | 0,4 | DB-6 |
| **Total sin el camino B** | | **8,8 sp** (de 5,3 a 12,3) | |
| T12 (si H-04 = S-1) | Camino B, E32 por la porción, E34 en el reverso | +0,5 | DB-3 |
| **Total con S-1** | | **9,3 sp** (de 5,6 a 13,0) · unas **7,75 semanas-persona** a 1,2 sp por semana | |

**Diferencia con [HF] 8.1 (7,7 sp de base con la contingencia; 8,0 con S-1):** +1,1 sp por lo que el diseño encontró y la hoja no contaba: métodos aditivos y prueba del orden (0,2), `IAporteCierreCaja` (0,15), sincronización (0,4), recorte del personal externo (0,2), grupo principal (0,05), guarda en los reportes (0,05) y talonario (0,05); con S-1, +0,2 más por la E34 con reembolso acompañante. Si la capacidad común ya la construyó [CE], T1 baja unas 1,2 sp, como dice [HF]. Licencias e infraestructura de GSF: 0 adicional. El precio por e-CF de S-1 sigue sin verificar ([HF] 5.2).

**Opción más barata, si se necesita recortar:** sin SW-09 (−0,2, con el control procedimental) y sin T11 hasta que exista un cliente con nodo (−0,4): 8,2 sp sin el camino B.

---

## 14. Riesgos
| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-1 | Acceso multiempresa v1 sin construir: un usuario del tercero entra a otra empresa | **Alta** | Condición antes del primer cliente (8.3) |
| R-2 | Carné de proximidad clonado o tecleado | Media | 8.4; DESFire o PIN en la fase 2 |
| R-3 | Un usuario del tercero con nivel ADMIN | Alta si ocurre | SW-09 |
| R-4 | El camino B depende de cambios en la ruta única (DB-3) que B aún no diseñó | Media | El camino A no depende; S-1 se puede encender después sin tocar la ventana |
| R-5 | Doble conteo del dinero en el Z con S-1 o S-2 | Media | SW-12 y sus pruebas |
| R-6 | Inyección de `Enter` desde un QR falsificado | Media | 8.4 y SW-07 |
| R-7 | El almuerzo se consume con un jugo y el comensal pierde el plato | Media (operativa) | SW-05 |
| R-8 | Fotos en caché de la caja o en los respaldos (Ley 172-13) | Alta | 8.5; auditor-seguridad |
| R-9 | Ninguna caja cobra dinero del empleado por FD-09 al llegar el primer cliente | Baja (intencional) | H-04 antes del primer cliente |
| R-10 | La entrega 3 crece unas 9 sp | Media | Capacidad común con [CE]; la opción más barata de 13.2 |

---

## 15. Decisiones que requieren firma (SW-01 a SW-18)
| # | Decisión | Recomendación | Alternativa descartada |
|---|---|---|---|
| **SW-01** | Módulos `Comensales` (nivel 5) y `Corporativa` (nivel 6) y la regla «ninguna vertical depende de otra» | Sí | `Comensales` dentro de `Corporativa` |
| **SW-02** | Sin carrito en el servidor: tokens firmados de lectura (2 min), identificación (10 min) y cotización (3 min) | Sí | Tabla de identificaciones |
| **SW-03** | Costura por estrategia de modo; S-1 con el E32 por la ruta única y el ticket como documento acompañante (dos caminos, un registrador) | Sí | Ruta única en fases; E32 en otra transacción; E32 armado por la vertical |
| **SW-04** | Orden de bloqueos del ticket de 7.3 (precisión de ADR-45 que incluye FD-11) | Sí | — |
| **SW-05** | El 100 % exige una línea del grupo principal y se asigna de mayor a menor importe | Sí | Cualquier línea de la composición (un jugo consume el almuerzo); orden de captura (lo decide el cajero) |
| **SW-06** | La línea validada en franja vale 3 minutos en la emisión | Sí | Revalidar siempre al emitir |
| **SW-07** | Captura de la ráfaga con prefijo y sufijo por caja (el prefijo enruta, no autentica); confirmación con `Enter` solo después de la ráfaga y 500 ms después de la foto; formato estricto; QR de 128 bits entregado una vez | Sí | Campo de texto con foco |
| **SW-08** | Foto solo tras una lectura, sin caché persistente, sin metadatos, vista administrativa con bitácora | Sí | Caché de 15 MB en la caja |
| **SW-09** | Recorte en el servidor del personal del administrador externo (nunca ADMIN ni beneficios) | Sí (0,2 sp) | Solo control procedimental |
| **SW-10** | Precios: sin flujo de propuestas del tercero en la fase 1 (responde [UX] P-9: AC-09 solo muestra los vigentes) | Sí | Flujo de propuesta y aprobación (0,4 sp) |
| **SW-11** | Leyenda puesta por el motor de impresión; **copias del ticket interno contadas** y marcadas «COPIA n · NO VÁLIDA PARA RETIRAR ALIMENTOS» con `TicketEsValeRetiro` (sí por omisión), sin autorización ([UX] P-8 y UQ-3) | Sí | Leyenda en la plantilla; copia libre sin contar (hoy); copia con la autorización de VE-01 (más fricción en la hora pico) |
| **SW-12** | `IAporteCierreCaja` y «cada peso cuenta una vez» | Sí | Escribir el dinero del ticket en `caja.Movimiento` (mezcla el ticket con los movimientos manuales) |
| **SW-13** | MAUI solo con la ventana, el reverso, la reimpresión y el Z; back-office solo en la Web en la fase 1 | Sí (ahorra unas 0,5 sp, inferido) | Copiar el back-office a MAUI |
| **SW-14** | Corte de nómina `Esencial` y solo con la sincronización al día | Sí | `Operativa` (RR. HH. no podría cerrar con la licencia vencida) |
| **SW-15** | Bolsa y nómina solo en el sitio dueño del saldo; fuera, solo el 100 % | Sí (fase 1) | Consultar el saldo remoto en línea |
| **SW-16** | Con S-1, dos piezas impresas en el mismo trabajo | Sí, sujeto al contable | Una sola pieza con el e-NCF bajo la leyenda |
| **SW-17** | El límite de 3 identificaciones sin carné por mes es un tope duro; después, se atiende como visitante (coincide con [UX] UQ-2) | Sí | Tope con autorización adicional (ya hay autorización siempre) |
| **SW-18** | Talonario de vales con rangos reservados por sede; el lote solo acepta vales de un rango reservado, una vez (C-13, [UX] P-10) | Sí (incluido en T10; +0,05 sp) | Vales con cualquier número (un vale inventado entra como excepción y nada lo detecta) |

### Candidatas a ADR (las redacta el Arquitecto Maestro; el propietario firma)
1. **Precisión de ADR-45** (SW-04 con FD-11): orden del ticket interno en los dos caminos.
2. **Precisión de ADR-112** (SW-03 y SW-12): métodos aditivos de `IExtensionVenta`, la extensión interna del documento acompañante y el aporte al cierre de caja. Sin ellos la ruta única no puede amparar un documento que no es una venta.
3. **ADR-87** (Propuesto): el diseño de la costura de la sección 7 (estrategias, falla cerrada y caminos), sin la opción, que sigue en H-04.
4. **ADR-88** (Aceptado): precisión con SW-01 (módulo y nivel), SW-08 (custodia de la foto) y la versión de la llave HMAC.
5. **ADR-85** (Aceptado): precisión con SW-02, SW-07, SW-09, SW-11 y SW-13.

---

## 16. Alineación con el diseño UX ([UX])

[UX] se escribió sin este blueprint y marcó sus endpoints y códigos como provisionales ([UX] 9). **Mandan los de aquí**; esta es la correspondencia.

### 16.1 Puntos de contacto P-1 a P-12
| [UX] | Lo que pide | Contrato de este blueprint | Diferencia |
|---|---|---|---|
| P-1 | Resolver el carné (`POST /api/corp/carne/resolver`) con todo en ≤ 1 s | **C-2** `POST /api/corporativa/lecturas` → `LecturaCarneDto` (tarjeta, estados, versión de la foto, bolsa, cupo, almuerzo y cena, `UsoReciente` de EC-06b, `SinCarneMes`); **C-3** para la foto | El «usado visto» **no** viaja a la pantalla: va dentro del `CotizacionToken`. Carné bloqueado: 422 con solo el estado y los últimos 4 (PV-5) |
| P-2 | Token de confirmación o borrador en el servidor | **C-4** → `IdentificacionToken` (10 min), exigido por C-8 y C-9 (CA-01) | Token, no borrador (SW-02) |
| P-3 | Cotizar ≤ 300 ms, con cambio por línea, partición, avance, proyección y franja | **C-8** `POST /api/corporativa/consumos/cotizar` → `CotizacionDto` con `Secuencia`, `Cambio` y `LineaOrigen` por línea, `AvanceComposicion`, `BolsaDespues`, `Franja` y `AdmiteDineroEmpleado` | Ninguna |
| P-4 | 409 y 422 con códigos | `SALDO_CAMBIADO` y `BENEFICIO_YA_USADO` → **`REPARTO_CAMBIO`** (409) con `motivo` = `SALDO` o `BENEFICIO` (también `CUPO` y `MODO_FISCAL`); `CUPO_NOMINA_INSUFICIENTE` → **`CUPO_NOMINA_EXCEDIDO`**; `CARNE_NO_ACTIVO` → **`CARNE_BLOQUEADO`**; `MODO_FISCAL_SIN_DEFINIR`, `MEDIO_NO_HABILITADO`, `ARTICULO_FUERA_DE_FRANJA` y `COMENSAL_INACTIVO`, iguales | Un solo 409 con motivo en lugar de dos códigos: la pantalla hace lo mismo en los dos casos (muestra el reparto nuevo y pide aceptar) |
| P-5 | Foto por URL de un solo uso, `no-store`, servida por el nodo | **C-3** con el `LecturaToken` en el encabezado (máximo 3 lecturas, 2 min), `no-store`; `SoloSucursal`, así que en una sede con nodo la sirve el nodo. En la Web llega como `data:`; en MAUI, el `blob:` que [UX] revoca al emitir | Encabezado en lugar de URL firmada: el token no queda en los registros de acceso |
| P-6 | Diálogo sin «Autorizo yo» | `DialogoAutorizacionSupervisor` con `PermitirPropio = false` (aditivo) y rechazo de la forma B en el servidor (8.2) | Ninguna |
| P-7 | «No es la persona» desde la caja | **C-5**: solo Activo → Bloqueado con el motivo fijo; `Esencial`; desbloquear es de la empresa | Coincide con la recomendación de UQ-1; si el propietario elige «solo registrar», el contrato no cambia |
| P-8 | Contar las copias del ticket | SW-11 y 10.2: `doc.Impresion` también para `TCI`/`RCI`; «COPIA n · NO VÁLIDA PARA RETIRAR ALIMENTOS» con `TicketEsValeRetiro`; sin autorización | Adoptada tal cual; sustituye la propuesta de VE-01 de la primera versión |
| P-9 | Propuestas de precio del tercero | Fuera de la fase 1 (SW-10) | AC-09 solo muestra los precios vigentes, como ya dice [UX] |
| P-10 | Talonario y lote | **C-13** (talonario, rangos reservados) y **C-12** (lote con `Origen = 'L'` y excepciones sin rechazo); SW-18. Privilegio `corp-contingencia`, de la empresa por omisión (UQ-6) | Ninguna |
| P-11 | Modo de la caja y parámetros en la sesión | **C-1** `GET /api/corporativa/sesion` → `SesionCorporativaDto` (modo, sede, franjas con la botonera, medios y su orden, nómina, `AdmiteDineroEmpleado` sin el valor fiscal, lector de la caja y fechas de sincronización del nodo) | Sesión propia, no `SesionPos`: no se toca la de la Facturación Ágil |
| P-12 | Lo que se puede devolver antes de autorizar | **C-14** `GET /api/corporativa/consumos/{numero}/reversable` → `ConsumoReversableDto` | Ninguna |

### 16.2 Otros puntos de [UX]
| Tema | Decisión aquí |
|---|---|
| `Enter` para confirmar ([UX] 2.2 y 6.1) | Se mantiene, con la condición de SW-07: solo después de la ráfaga y 500 ms después de pintar la foto |
| Prefijo del lector ([UX] 6.3) | Validado en 8.4: enruta la ráfaga y cierra la inyección de teclas; no prueba que hubo un carné. Se recomienda `F13` a `F24` o un carácter de control; `GPC:` dentro del QR solo con un lector compartido |
| `Uid` del ticket generado al confirmar y reutilizado ([UX] 8.3) | Es la `ClaveIdempotencia` de C-9 |
| La pantalla descarta las cotizaciones viejas ([UX] 8.3) | `Secuencia` en la petición y en la respuesta |
| D-1 a D-5 ([UX] 8.4) | Requisitos para el arquitecto-datos en la sección 12 |
| UQ-2 (límite sin carné) | Rechazo (SW-17), igual que [UX] |
| UQ-3 (ticket como vale) | `TicketEsValeRetiro`, sí por omisión (SW-11) |
| UQ-6 (quién digita el lote) | La empresa por omisión |
| UQ-8 («No usar mi bolsa») | Fuera de la fase 1, igual que [UX] |
| UQ-9 (atender como visitante con el modo fiscal sin definir) | De acuerdo: la API no lo ofrece; `AdmiteDineroEmpleado = false` solo deshabilita el cobro |
| Latencias ([UX] 1.1) | Lectura p95 ≤ 300 ms y foto p95 ≤ 300 ms en la red local (inferido: 3 búsquedas por llave, descifrado de unos 45 KB en menos de 1 ms y unos 60 KB en base64 por SignalR en 10 a 30 ms), dentro del objetivo de 1 s de [POS] 1 |
| Back-office solo en la Web en la fase 1 (SW-13) | **Diferencia con [UX] 8.3, punto 9**, que pone las mismas páginas en los dos anfitriones y la cámara de AC-05 en MAUI. La toma de la foto con cámara queda para la fase 2 o se resuelve cargando el archivo en la Web; lo decide el propietario con SW-13 |

## Resumen breve
- **Tres piezas:** la capacidad `Comensales` (nivel 5, compartida con `CARGO_EMPRESA`), la vertical `Corporativa` (nivel 6) y su ventana propia, que no toca la Facturación Ágil. El visitante sale por la ruta única con una extensión que aplica la franja y la lista de visitante.
- **El servidor decide todo:** sin carrito, con tokens firmados de vida corta; el motor es una función pura (franja → 100 % con grupo principal → bolsa de mayor a menor → dinero) que corre en la cotización y otra vez dentro de la transacción. El 409 `REPARTO_CAMBIO` trae la cotización nueva.
- **La costura no elige:** cinco estrategias con falla cerrada en `NULL`. S-1 emite el E32 por la ruta única con el ticket como documento acompañante; eso exige métodos aditivos en `IExtensionVenta`, la marca FD-10 y una nota de crédito acompañante: se coordinan con B.
- **Seguridad:** perfiles del tercero con recorte en el servidor, llave HMAC por empresa, ráfaga del lector que descarta `Enter`, foto sin caché y entregada solo tras una lectura. El acceso multiempresa v1 sigue siendo una condición antes del primer cliente.
- **Alineado con [UX]:** P-1 a P-12 tienen contrato (16.1); se adoptan las copias contadas del ticket (P-8), el diálogo sin «Autorizo yo» (P-6) y D-1 a D-5 como requisitos para Datos; el prefijo del lector queda validado como enrutamiento, no como prueba de que hubo un carné.
- **Estimación revisada:** 8,8 sp sin S-1 y 9,3 con S-1 (unas 7,75 semanas-persona), 1,1 sp más que la hoja, sobre todo por la sincronización y los enganches del núcleo. 18 decisiones SW por firmar.

### Cierre
- Estado: Completado (diseño; SW-01 a SW-18 **Pendientes de firma**; H-04 sigue abierta; FD-01 a FD-15 de Datos siguen pendientes)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-vertical-corporativa-2026-10-15.md` (sin commit)
- Supuestos: sp, latencias y volúmenes inferidos (±40 %); FD-01 a FD-15 se firman como los recomienda Datos; el contrato `IExtensionVenta` es el de [DF] 6.1 más los métodos aditivos de 7.3; el patrón de reimpresión por `POST` es el de `cd44b958` (no unido a `ce33b2a8`); los nombres provisionales de [UX] se sustituyen por los de este documento (16.1)
- Decisiones candidatas a ADR: precisión de ADR-45 (SW-04); precisión de ADR-112 (SW-03, SW-12); ADR-87 con el diseño de la costura; precisiones de ADR-85 y ADR-88
- Entregas a otros agentes: arquitecto-datos → `EsPrincipal`, `HmacVersion`, forma de pago de nómina, la marca de S-2, D-1 a D-5 de [UX] (botonera, lector por caja, parámetros, talonario, fecha de sincronización) y el conteo de copias en `doc.Impresion`; B → DB-1 a DB-5 (mecanismo, `PanelCobro`, FD-10 y métodos aditivos, ids y errores, módulos en los reportes); auditor-seguridad → 8.4 y 8.5 (lector, foto, Ley 172-13, SW-09); especialista-contable → nómina en el E32 y las dos piezas impresas (SW-16); disenador-ux-ui → adoptar los nombres de 16.1 y revisar SW-07 (Enter tras la ráfaga) y SW-13 (back-office solo en la Web, cámara de AC-05); Arquitecto Maestro → hoja de firma de SW-01 a SW-18 y los ADR candidatos
- Próximo paso recomendado: que el Maestro prepare la firma de SW-01 a SW-18 junto con FD-01 a FD-15, y que B confirme DB-1 y DB-3 antes de planificar el tramo en la entrega 3
