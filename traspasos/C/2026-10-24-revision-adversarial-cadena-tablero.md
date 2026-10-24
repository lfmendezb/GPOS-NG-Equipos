```
Para: B        De: C (auditor de seguridad)        Fecha: 2026-10-24 (trabajo del 2026-10-23)
Tipo: Entrega (tanda 8, punto 3: revisión adversarial de punta a punta de la cadena del tablero)
Encargo: avisos/B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md, punto 3
Base revisada: origin/feature/modelo-ng @ 1b310591 (incluye #202, #205, #206, #212 y #217); #220 en origin/a/menu-restringir-sucursal @ 2ee29cc7
Anexo: 2026-10-24-revision-adversarial-cadena-tablero.cs.txt (4 pruebas ejecutadas contra SQL Server local; sin commit ni push)
Estado: Aprobado con observaciones (recomendación técnica; decide el propietario, C2)
```

# Informe de seguridad: la cadena del tablero de punta a punta

## 1. Alcance y superficie revisada

**Cadena revisada:**
- D-03 (tablero, 2026-10-23) y TBS-01 a TBS-06 (hoja `docs/decisiones/2026-10-23-hoja-firma-d-03-tablero-sucursal.md`);
- #202 (T4-07 en la API de reportes), #205 (interfaz), #206 (TBS-06, avisos), #212 (`SesionInfo.RestringirSucursal`);
- #220 (menú; abierto).

**Superficie expuesta:**

| Proceso | Ruta | Control |
|---|---|---|
| API de reportes | `GET /api/reportes/dashboard/indicadores` | `EndpointsReportes.cs:66-67` |
| API de reportes | las otras 6 rutas de `MapReportes` | `EndpointsReportes.cs:51-120`, mismo `ProveedorContexto` (TBS-04) |
| API de reportes | 4 rutas `/interno/render/*` | solo por la canalización interna |
| Principal | `GET /api/reportes/dashboard/indicadores` | reenvío o 503 (`ReportesEndpoints.cs:81-86`) |
| Principal | `GET /api/reportes/dashboard/avisos` | `ReportesEndpoints.cs:89` |
| Principal | rutas a las que **enlaza** el tablero | `Tablero.razor:188-197` (gráficos DASHBOARD) y `:216-223` (enlaces de las tarjetas) |
| Interfaz | `Tablero.razor` (Web y MAUI, idénticos byte a byte salvo el espacio de nombres; comprobado con `diff`) y `NavMenu.razor` (#220) | — |

**Foco del encargo:**
- fuga entre sucursales (existencias, CxC, avisos, reportes, exportaciones, nombres, conteos);
- cuenta restringida frente a ADMIN y SUPER;
- envenenamiento de la caché entre alcances;
- IDOR por parámetros;
- rutas sin la política;
- interfaz Web y MAUI.

**Revisiones previas leídas, para no repetirlas:**
- `traspasos/A/revision-seguridad-pr170-94f5df64-y-pr202-t4-07-2026-10-23.md` (T4-07-01 a 03);
- `traspasos/A/revision-pr205-tablero-ui-2026-10-23.md` (R205-01 a 05);
- `traspasos/A/revision-seguridad-pr206-tbs-06-2026-10-23.md` (R206-01 a 03);
- `avisos/A-a-B/2026-10-23-revision-212-y-211.md` (R212-01);
- `avisos/A-a-B/2026-10-23-menu-restringir-sucursal-pr220.md`;
- `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (R-01 a R-14);
- `traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md` (R-14 se cierra con T4-06).

Lo que esas revisiones ya dicen no se repite aquí; solo se cita cuando un hallazgo nuevo se apoya en ello.

**Ejecutado (C6), sobre `.\SQLEXPRESS`, una compilación a la vez:**

| Suite | Filtro | Resultado |
|---|---|---|
| `GPOS.Tests` | mis 4 pruebas (anexo) + `ModeloNg.TableroReportesTests` + `AvisosTableroRestringidoTests` + `InyeccionAlcanceTests` + `CierreSucursalExistenciasTests` | **19/19** |
| `GPOS.Reportes.Tests` | `TableroReportesTests` + `ProveedorContextoTests` + `EndpointsReportesTests` | **53/53** |
| `GPOS.Web.Tests` | `~Tablero` | **28/28** |

- Antes del verde, mis pruebas pasaron por dos rojos de preparación, que dejo registrados porque explican la forma final:
  - CT02 leía la definición de `GPOS_SYSDATA`, que no existe en la base de prueba («Invalid object name 'Reportes'»).
  - CT03 usaba el mismo usuario en paralelo y se topó con el turno por usuario (`ConsultaEnCursoException`).
- El archivo de pruebas se quitó del árbol después de copiarlo al anexo; el worktree quedó limpio.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| **C-T01** | **Media** | Los enlaces de las tarjetas «Cuentas por cobrar» y «Ventas» llevan al restringido a la consulta de facturas, que no aplica la restricción: lista, detalle por número (IDOR) y exportación de facturas de otras sucursales | **Verificado** (CT01) |
| C-T02 | Baja | El gráfico `DASH-CXC-ANTIGUEDAD` del propio tablero lo ejecuta la principal (lista P-2) sin alcance. Hoy no hay fuga en el modelo nuevo porque la vista heredada viene vacía (y por eso el gráfico sale vacío para todos). Es R-14 en el tablero; se cierra con T4-06 (#225) | Verificado (CT02) |
| C-T03 | Baja | La prueba de ruta de TBS-04 cubre 3 de las 7 rutas de datos de la API de reportes; las 7 sí pasan por `ProveedorContexto` (guarda de fuente CT04) | Verificado (CT04) |
| C-T04 | Informativa | La anotación de la hoja D-03 dice que el 403 de TBS-04 alcanza «todas las rutas de la API de reportes». Las 4 de `/interno/render` no pasan por el contexto, porque no leen datos de la empresa | Verificado (CT04 y lectura) |

**Descartado con evidencia** (sección 5):
- envenenamiento de la caché entre alcances, también en paralelo (CT03);
- IDOR por parámetros en el tablero;
- sucursal tomada del token;
- exención del SUPER;
- TBS-04 con mayúsculas o espacios;
- caché en el cliente;
- paridad Web/MAUI.

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP

| Punto | Resultado |
|---|---|
| A01 Control de acceso | **Observación.** La cadena del tablero filtra bien (sección 5). La consulta de facturas, a la que el tablero enlaza, no aplica la restricción (C-T01). La ruta P-2 de la principal ignora el alcance (C-T02, latente) |
| A02 Criptografía | No aplica (la cadena no cambia el token ni la firma; HS256 hoy, ES256 es la versión 1) |
| A03 Inyección | Correcto. `@sucursal smallint` y los rangos van como parámetros registrados (`ConsultasTablero.cs:24-95`); el código de sucursal se resuelve por consulta registrada con largo acotado (`ResolutorCatalogos.cs:96-104`) |
| A04 Diseño inseguro | Correcto en la cadena: la falla es cerrada (TBS-05: 403 antes de la caché y de la sesión, `TableroReportes.cs:40-45`). La observación de diseño es C-T01: la frontera de D-03 no se extendió a las pantallas a las que enlaza el tablero |
| A05 Configuración | Correcto. Sin reenvío, el tablero responde 503 y la interfaz no pide los gráficos (`Tablero.razor:184`). R-14, sin reenvío, sigue abierto y es conocido |
| A06 Componentes vulnerables | No aplica (sin paquetes nuevos) |
| A07 Autenticación | Correcto. Mismo token, introspección y `ProveedorContexto` (sesión, revocación e `iat`); no cambia en la cadena |
| A08 Integridad | No aplica |
| A09 Registro y monitoreo | Correcto para lo revisado: el evento 5110 deja constancia de una sucursal del token desactualizada (`ProveedorContexto.cs:94-96`); el 403 de TBS-04 no se registra en la API de reportes (igual que T2-03; sin cambio) |
| A10 SSRF | No aplica (el reenvío usa una dirección fija por canalización; ruta y cadena de consulta copiadas de una ruta ya resuelta, `ReenvioReportes.cs:81`) |

## 4. Hallazgos

### C-T01 (Media, verificado): el tablero enlaza al restringido con una consulta de facturas sin restricción de sucursal

**Riesgo.** Una cuenta restringida (USER o ADMIN con `RestringirSucursal`, nunca el SUPER) con «Facturación», «Reportes de ventas» o «Cobros» ve en el tablero solo su sucursal (TBS-01). Pero los enlaces de las tarjetas la llevan a `ventas/consulta`:
- «Ver facturas vencidas» (`Tablero.razor:218`);
- «Consultar las facturas del período» (`:219-220`).

Allí recibe las facturas de **todas** las sucursales: número, cliente, RNC, vendedor, caja y cajero, total y saldo. Además:
- el detalle de cualquier factura por su número (`GET /api/ventas/facturas/{numero}/detalle`, IDOR por parámetro);
- la búsqueda por número (`/buscar-numero`);
- la exportación (`/exportar/{formato}`);
- los contadores por estado.

Es la frontera de confidencialidad que D-03 (tablero) cierra en la tarjeta y deja abierta un clic más allá. La cifra de la pantalla tampoco cuadra con la de la tarjeta, lo que además confunde al encargado.

**Evidencia [V]:**
- `src/GPOS.Core/Servicios/ConsultaFacturasService.cs:16`: el constructor solo recibe la fábrica y la sesión; no hay `IAlcanceAlmacenes` ni lectura de la cuenta.
- `:91-95`: el único recorte es el del cajero que solo tiene `PuntoVenta` (sus jornadas), no la sucursal.
- `:194`: `DetalleAsync` usa la misma consulta.
- `src/GPOS.Api/Endpoints/ConsultaFacturasEndpoints.cs:23-34`: las 4 rutas exigen solo uno de los cuatro permisos (`RequiereAlgunPermiso`).
- Menú: «Consulta de Facturas» sigue visible para el restringido en Web y MAUI (`NavMenu.razor:150`). Es coherente con el servidor, que la sirve; el #220 no la oculta.
- **Prueba CT01 (verde, anexo).** Sucursal nueva S2 con una factura de 236; otra factura de 118 en la sucursal de siempre. Cuenta restringida a S2 con «Reportes de ventas» y «Cobros»:
  - tarjeta «Cuentas por cobrar» = 236 (correcto, TBS-01);
  - `BuscarAsync` devuelve `FC00000002 saldo 236.00, FC00000001 saldo 118.00; suma de saldos 354.00`;
  - `DetalleAsync` de la factura ajena devuelve el detalle.
- No encontré esta ruta en las listas previas: R-01 a R-14 son de inventario y reportes, y T4-08 solo menciona el truncado de 10.000 filas. Por eso lo considero nuevo.

**Por qué Media y no Alta:**
- exige una cuenta autenticada de la misma empresa con permisos de ventas;
- no hay escritura;
- ninguna hoja firmada nombra expresamente la consulta de facturas dentro de la frontera. TA-P08 dice «existencias … por ninguna ruta»; D-03 habla de los reportes y del tablero.

Si el propietario confirma que la frontera de D-03 cubre toda lectura de ventas del restringido, sube a **Alta** y bloquearía la publicación con cuentas restringidas.

**Remediación (en orden de costo):**
1. **Decisión del propietario (sin costo):** ¿la restricción de sucursal rige en la consulta de facturas? Dos opciones:
   - (a) sí, ya;
   - (b) se acepta el riesgo hasta T4-08 (enero), que mueve la consulta a la API de reportes, donde `ContextoLectura.Sucursal` ya impone la sucursal.
   Recomiendo (a), por coherencia con D-03 y TBS-01.
2. **Corrección mínima (a), unos 0,5 dp con pruebas [I]:**
   - inyectar `IAlcanceAlmacenes` en `ConsultaFacturasService` (mismo patrón que `AvisosTableroService` y `ReportesService`, con constructor `internal` sin alcance para las pruebas);
   - filtrar `Consulta(u)` por la sucursal del documento con la regla de falla cerrada (`Vacio` sin filas, nunca `Global`). Es la columna de la que sale `rpt.VentaDocumento.SucursalId`; el nombre exacto en `ng.Documentos` está por confirmar [I];
   - para el detalle y la búsqueda por número, 404 o vacío para una factura fuera del alcance;
   - en la exportación, el mismo filtro (sale gratis al reutilizar `BuscarAsync`).
3. **Paliativo que no cierra la ruta (unos 0,1 dp):** con `AlcanceSucursal` no nulo, quitar el enlace de las tarjetas. Evita la incoherencia visible, pero la consulta sigue abierta por el menú. **No lo recomiendo solo.**
4. **Defensa en profundidad:** cuando T4-08 lleve la consulta a la API de reportes, que la prueba de partición (las sucursales suman la empresa) se repita para la consulta, igual que en el tablero.

### C-T02 (Baja, verificado): el gráfico de antigüedad de CxC del tablero corre en la principal sin alcance

**Riesgo.** Tras las tarjetas, `Tablero.razor:191-195` pide todos los reportes de tipo DASHBOARD y los ejecuta. `DASH-CXC-ANTIGUEDAD`:
- está en `ReportesSemilla.EnLaPrincipal` (`ReportesSemilla.cs:136-140`; definición en `:352-355`);
- por eso, **aun con el reenvío habilitado**, la principal no lo reenvía (`ReportesEndpoints.cs:40-47`);
- la principal lo ejecuta con `ReportesService.EjecutarAsync`, que no usa el alcance (`ReportesService.cs:276-285` y `:318`).

Los otros tres gráficos DASHBOARD van a la API de reportes, que sí restringe (`EjecutorDisenador.cs:283-338`).

**Lo que pasa hoy [V, CT02]:** en una base del modelo nuevo, `dbo.vw_GPost_DocumentosCxC` existe pero viene vacía (`SUM(Balance) = 0`, aun con 354 de saldo en `rpt.CxcDocumento`). El gráfico sale **vacío para todos**:
- **no hay fuga de datos NG hoy**;
- sí hay un defecto funcional: el gráfico de antigüedad del tablero no muestra nada en `feature/modelo-ng`.

La ruta de ejecución sigue sin alcance. Si antes de T4-06 alguien hiciera que la vista heredada leyera el modelo nuevo, el restringido vería la antigüedad de toda la empresa junto a una tarjeta que dice «su sucursal».

**Relación con lo ya conocido:** es R-14 (`blueprint-t4-06-lista-p2-2026-10-22.md:355`) en el tablero mismo. Se cierra **por construcción** con T4-06 (#225, lista P-2 vacía).

**Remediación:**
- Ninguna aparte de T4-06.
- Pido que la revisión del #225 (mi punto 1 de la tanda 8) compruebe que, después de T4-06, `DASH-CXC-ANTIGUEDAD` se ejecuta en la API de reportes y que un restringido ve solo su sucursal (`rpt.CxcDocumento.SucursalId`, TBS-01).
- CT02 queda en el anexo como **caracterización**. Su aserción `Assert.Equal(0m, total)` se pone roja si la vista empieza a traer datos antes de T4-06.

### C-T03 (Baja, verificado): la prueba de ruta de TBS-04 no cubre todas las rutas

**Riesgo.** `EndpointsReportesTests.TBS_04_un_restringido_con_token_de_otra_empresa_recibe_403_en_todas_las_rutas` (`:368-382`) comprueba 3 rutas: la lista, `ejecutar` y el tablero. No comprueba:
- `GET /api/reportes/{id}`;
- `POST /api/admin/reportes/detectar`;
- `POST /api/admin/reportes/vista-previa`;
- `GET /api/reportes/{id}/exportar/{formato}` por el canal.

Hoy las 7 llaman a `contexto.ObtenerAsync(http.User, ct)` antes de usar el servicio. Eso lo verifica **CT04**, la guarda de fuente del anexo, que encuentra exactamente 7 rutas y las 7 con la llamada. Una ruta nueva que use el servicio sin el contexto no la detecta ninguna prueba de ruta.

**Remediación (0,25 dp):**
- agregar las 4 rutas a la prueba de TBS-04 (la exportación con `canal: true`);
- o dejar la guarda de fuente de CT04 en `GPOS.Reportes.Tests`, más barata, con el conteo de rutas como alarma: una ruta nueva obliga a mirarla.

### C-T04 (Informativa): «todas las rutas» de la hoja tiene una excepción que conviene escribir

La anotación de la hoja D-03 («el 403 `SUCURSAL_NO_PERMITIDA` de TBS-04 alcanza a **todas** las rutas de la API de reportes») no se cumple en las 4 rutas `/interno/render/*`:
- no pasan por `ProveedorContexto` (`EndpointsRender.cs:46-62`; CT04 lo fija);
- solo validan el token por introspección.

No es una fuga, por tres razones [V]:
- solo existen por la canalización interna, con 404 antes de autenticar por HTTP (`:30-38` y `:79`);
- reciben los datos ya armados por la principal;
- la empresa del token solo se usa para el registro (`ServicioRender.cs:24`).

**Remedio:** en el barrido de ADR-91, precisar la frase: «todas las rutas de datos (`/api/reportes` y `/api/admin/reportes`); las de render reciben los datos de la principal».

## 5. Controles que están bien implementados (verificado)

1. **La sucursal sale de `rptsis`, no del token.** Para el restringido, `ProveedorContexto.Sucursal` usa `SesionUsuario.SucursalDefault` y registra el evento 5110 si el token difiere (`ProveedorContexto.cs:90-98`). La ruta del tablero no acepta un parámetro de sucursal (`EndpointsReportes.cs:66`), y un `?sucursal=` agregado se ignora. **No hay IDOR por parámetro en el tablero.**
2. **TBS-04.** `SucursalAjena` exige la empresa del token, la empresa asignada y una sucursal asignada (`ProveedorContexto.cs:115-116`). Compara sin mayúsculas ni espacios de los extremos y falla cerrada si falta un valor (`UsuarioAlcance.cs:22-26`). Se aplica antes de armar el contexto en las 7 rutas de datos (CT04) y también al token de servicio de los programados (M-1 del #217).
3. **SUPER y ADMIN.** `Restringe` exime solo al SUPER con el nivel guardado (`UsuarioAlcance.cs:15`). Un nivel desconocido no exime, así que el error va hacia el lado restrictivo. El ADMIN con la bandera queda restringido y no diseña (`ContextoReportes.PuedeDisenar`).
4. **Falla cerrada (TBS-05).** Restringido sin sucursal, o con un código que no existe en la empresa: 403 antes de la caché y de abrir la sesión (`SucursalPropia.cs:22-48`, `TableroReportes.cs:40-45`). Solo se guardan en la caché de catálogos los aciertos (`ResolutorCatalogos.cs:100-103`).
5. **Filtro SQL.** Las 6 consultas declaran `@sucursal smallint` y filtran por la sucursal del propio documento (`ConsultasTablero.cs:24-95`). La guarda estática de B impide una tarjeta sin filtro. La partición (las sucursales suman la empresa) está probada contra la base por B (`ModeloNg/TableroReportesTests.cs`) y la volví a correr en verde.
6. **Caché.** La clave lleva empresa, sucursal restringida y huella, y se vuelve a comparar al leer (`CacheTablero.cs:47-61`). Los privilegios se comprueban **antes** de la caché (`TableroReportes.cs:110-115`). **CT03** (contra la base, una sola `CacheTablero` y un solo `ResolutorCatalogos`, como los singleton): 60 peticiones en paralelo e intercaladas de un ADMIN global, del restringido a S2 y del restringido a la sucursal de siempre; cada una recibió exactamente la cifra de su alcance calculada sobre `rpt` y su `AlcanceSucursal`. **Envenenamiento descartado.**
7. **Avisos (TBS-06).** El alcance sale de la cuenta (`AlcanceAlmacenes`), con S168-05 y falla cerrada. Lo revisó A (R206-01 a 03, sin cambios). Volví a correr `AvisosTableroRestringidoTests` en verde. Los avisos muestran solo el código, el nombre y el conteo de la sucursal propia. **No encontré otra ruta del tablero que revele nombres ni conteos de otras sucursales.**
8. **Sin reenvío.** El tablero responde 503 y la interfaz no pide los gráficos (`Tablero.razor:184`). Así, en el DEMO de procesos el tablero no ejecuta reportes P-2 ni del diseñador para nadie. R-14 sigue abierto por el menú de reportes (conocido, T4-06).
9. **Interfaz.**
   - `Tablero.razor` de Web y MAUI son idénticos.
   - Los textos de error son constantes y Razor codifica `AlcanceSucursal` (R205).
   - No hay caché de indicadores en el cliente: el `ApiClient` solo guarda en memoria impuestos, monedas, términos y formas de pago.
   - #220 solo oculta y es coherente con la política del servidor. Las opciones fuera de `admin/` (consulta de facturas, existencias) siguen visibles porque el servidor las atiende; ver C-T01 y R-01 a R-14.
   - R212-01 (el menú no cambia hasta el siguiente inicio de sesión) se acepta, porque el campo solo oculta.
10. **El lector de la API de reportes** no usa `SucursalRestringida` para nada que no sea `Sucursal(pedida)` y la clave de la caché (sin contexto de sesión SQL). Abrir la sesión con `contexto.Lectura(null)` antes de resolver el alcance no amplía lo que se lee, porque cada consulta lleva `@sucursal` (`TableroReportes.cs:42-48`).

## 6. Remediaciones priorizadas

| # | Hallazgo | Acción | Responsable | Esfuerzo / costo [I] |
|---|---|---|---|---|
| 1 | C-T01 | Decisión del propietario: la restricción rige ya en la consulta de facturas (a) o se acepta hasta T4-08 (b). Recomiendo (a) | propietario (prepara B) | 0 |
| 2 | C-T01 | Con (a): alcance en `ConsultaFacturasService` (lista, detalle, búsqueda por número y exportación) con falla cerrada, y pruebas con el escenario de CT01 | desarrollador del área de ventas (A o B) | ≈ 0,5 dp (USD 150 a 200 al valor del plan del tramo 4) |
| 3 | C-T02 | Comprobar en el #225 que `DASH-CXC-ANTIGUEDAD` pasa a la API de reportes con TBS-01; dejar CT02 como caracterización hasta entonces | C (punto 1 de la tanda 8) | incluido |
| 4 | C-T03 | Completar la prueba de ruta de TBS-04 o adoptar la guarda de fuente CT04 | B | ≈ 0,25 dp |
| 5 | C-T04 | Precisar «todas las rutas de datos» en la anotación de la hoja D-03 | documentador / barrido de ADR-91 | ≈ 0,05 dp |

**Alternativa descartada para C-T01:** solo quitar el enlace de la tarjeta (0,1 dp). Es más barata, pero deja la ruta y el menú abiertos y oculta el síntoma en lugar de cerrar la frontera.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; decide el propietario, C2).

- La cadena del tablero, de punta a punta, aplica D-03 y TBS-01 a TBS-06 tal como están firmadas, y no encontré fuga dentro de ella:
  - tarjetas, avisos, caché y TBS-04;
  - Web y MAUI;
  - el #220, que **desde la seguridad se puede unir** tras el #212.
- La observación de fondo es **C-T01 (Media)**: el tablero enlaza a una pantalla que no respeta la frontera que el propio tablero aplica. Necesita una decisión del propietario antes de habilitar cuentas restringidas con permisos de ventas en una instalación real.
- C-T02 se cierra con T4-06. C-T03 y C-T04 son de pruebas y de documentación.

## Supuestos
- **Columna de sucursal en la consulta de facturas.** La de `ng.Documentos` es la que alimenta `rpt.VentaDocumento.SucursalId` [I]. Si una factura del POS se registra con la sucursal de la jornada, el filtro de C-T01 debe usar esa misma regla; lo confirma quien lo construya.
- **Cifras de esfuerzo.** Usan el valor del plan del tramo 4 que cita la hoja D-03 (27,5 dp = USD 8.250 a 11.000) [I].
- **#220.** Revisé el diff de `NavMenu.razor` (Web; MAUI es idéntico según A). No lo compilé ni corrí sus pruebas en esta sesión: A informa 5/5 y 955/955.

## Decisiones candidatas a ADR
- Precisión de ADR-93 (TA-P08) o de ADR-109 (D-03), que fije si la frontera de la sucursal rige en la consulta de facturas (y, por extensión, en toda lectura de ventas del restringido) antes de T4-08. Hay dos alternativas: (a) ya, en la principal; (b) riesgo aceptado hasta T4-08. Recomendación: (a).

## Entregas a otros agentes
- **B (coordinación):** presentar al propietario la pregunta de C-T01 con la recomendación (a), y asignar la corrección de C-T01 y la prueba de C-T03.
- **A:** la frase de C-T04 en el barrido de ADR-91; que T4-08 herede el escenario de CT01 como prueba de partición.
- **QA (C, punto 1 de la tanda 8):** en la revisión del #225, comprobar C-T02 (el gráfico pasa a la API de reportes con TBS-01).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-cadena-tablero.md`; `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-cadena-tablero.cs.txt`
- Supuestos: los tres de la sección «Supuestos»
- Decisiones candidatas a ADR: precisión de ADR-93 o ADR-109 sobre la consulta de facturas del restringido (C-T01)
- Entregas a otros agentes: B → decisión del propietario y asignación de C-T01 y C-T03; A → frase de C-T04 y escenario de CT01 en T4-08; C → C-T02 en la revisión del #225
- Próximo paso recomendado: que el propietario decida C-T01 (a o b) antes de habilitar cuentas restringidas con permisos de ventas.
