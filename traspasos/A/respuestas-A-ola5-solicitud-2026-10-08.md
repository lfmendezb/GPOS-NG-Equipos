# Respuestas de A a la solicitud de la ola 5 (S-1 a S-15), E1-1, E1-2, AU-01, K-06 y vectores de ADR-77

**Fecha:** 2026-10-08 · **Autor:** arquitecto-software (equipo A) · **Para:** equipo B (arquitecto-maestro de B, hoja de firma de la ola 5) y el propietario
**Estado:** Completado (respuestas técnicas). Lo marcado como «decide el propietario» queda **pendiente de firma**. Nada de esto se ha aprobado en nombre del propietario.

**Fuentes leídas (solo lectura; no se compiló ni se ejecutó nada; hay una carga de rendimiento en curso):**
- Avisos de B: `GPOS-NG-Equipos/avisos/B-a-A/2026-10-07-ola5-solicitud-informacion.md`, `2026-10-08-propina-y-montos-usd-comprobante.md`, `2026-10-08-acuse-decisiones-ecf-iq-p04.md` y `2026-10-08-acuse-push-master-adr77.md`.
- Diseños de B en `origin/b/ola5-diseno` (`0a285e4`): `docs/datos/2026-10-07-ola5-vistas-reportes.md` (en adelante [DAT5]), `docs/arquitectura/2026-10-07-ola5-api-reportes-diseno.md` ([SW5]) y `docs/decisiones/2026-10-07-hoja-firma-ola5.md` ([HOJA5]).
- Código: `GPOS-NG-numeracion`, `feature/modelo-ng`, `f21b788` (igual a `origin/feature/modelo-ng`; árbol limpio). Todas las rutas `src/...` de este documento son de ese commit.
- ADR en `GPOS NG/docs/adr` (`master`, `b403f32`). Contexto de A: `decisiones-por-registrar-2026-10-07.md` y `-2026-10-08.md`, `hoja-firma-api-reportes-2026-10-07.md` y `propuesta-api-reportes-solo-lectura-2026-10-07.md`.

**Convención.** *Verificado:* leído hoy en la fuente citada. *Inferido:* conclusión o estimación mía, con su base. **sp** = semanas-persona (±40 %).

**Decisiones del propietario que no se reabren aquí:** B consolida la API de reportes (ADR-109 a 111; S-6 resuelta); corte de la entrega 1 a mediados de diciembre; A excluye todo e-NCF del 607 y del 608 después de la carga T-57; B toma H-R02 (serie B), HD-10 y H-R03 a H-R09 en la ola 5; ningún documento con e-NCF se anula salvo el rechazo de la DGII.

---

## 0. Resumen

| N.º | Respuesta corta | ¿Decide el propietario? | ¿Trabajo para A? (sp) |
|---|---|---|---|
| **S-1** | Lo único del propietario que A registró y no está en el aviso de B: el aislamiento alcanza también el **tablero, los KPI y las consultas** (consulta de facturas, *drill-down*), no solo la pantalla de Reportes. El resto de la hoja de A eran propuestas de A, ya absorbidas en ADR-109 | No | No |
| **S-2** | Hecho: `traspasos/A/blueprint-razor-jsoncanon-v2.md` (commit `89418fa` del área común), idéntico al original | No | No |
| **S-3** | Fechas estimadas (inferidas): **cierre de la ola 4: 9 o 10 de octubre**; **unión de la 3b: hacia el 17 de octubre** (del 15 al 23; peor caso, 30 de octubre). Recomiendo la propuesta de B (construir en `b/ola5` después de la 3b), y que B pueda adelantar desde ya lo que **solo crea archivos nuevos** | **Sí** | No (A informa cuándo une) |
| **S-4** | Ya resuelto: H-R01 lo hizo A (`f21b788`). H-R02, HD-10, la fecha de H-R04 y H-R03 a H-R09 son de B. A solo agrega la exclusión de los e-NCF después de T-57 y lo avisa | No (ya decidido) | 0,05 (ya planificado) |
| **S-5** | B agrega sus proyectos a `GPOS-NG.slnx` en su rama y A lo acepta al unir. Los cambios de `CLAUDE.md` los propone B en su nota de traspaso y los aplica A. La excepción a [H0] 4.2 se firma con DR-01 / ADR-109 | **Sí, en parte** (DR-01 en la hoja de B) | ≈ 0,02 (aplicar `CLAUDE.md`) |
| **S-6** | Resuelta (decisión del propietario) | No | No |
| **S-7** | **En la moneda del documento.** El comprobante no aplica la tasa, mientras que el 606 sí la aplica. Es E1-2 | Ver E1-2 | Ver E1-2 |
| **S-8** | Ninguna de las fuentes existe. Hay nombres de tabla para todas, pero ninguna tiene fecha dentro de la ola 5. Las reservadas siguen reservadas (detalle en 2.4) | No | Las construye A en su pista; no hay trabajo nuevo |
| **S-9** | Es lo mismo que E1-1 | Ver E1-1 | Ver E1-1 |
| **S-10** | A **acepta** `AUTHORIZATION dbo`, V-R1 con 51399 y `CONTAINMENT = PARTIAL`, con tres condiciones. Lo construye B en la ola 5 dentro de `GPOS.Migracion` | No (PD-07, la autenticación contenida, sigue en la hoja de B) | Solo revisión (≈ 0,02) |
| **S-11** | **Falso positivo:** el valor del inventario ya exige «Ver costos» desde el primer commit (`DashboardService.cs:54`). PD-09 no hace falta | No | No |
| **S-12** | **AN-02 no está firmada** (verificado). Recomiendo firmarla con el esquema `ext` antes de construir la ola 5 | **Sí** | No |
| **S-13** | Desde `b1874f0` no cambiaron `ModeloImpresion`, `ImpresionDatosService`, `FabricaModelo` ni `FormatosService`. **Sí cambiaron** `ReportesSemilla.cs` (compras, CxP y bancos sobre el modelo nuevo), `ReportesService.cs` (K-06), `rpt.Formato607` (H-R01) y el tablero (aviso de sucursal cerrada). Hay cinco cambios más anunciados | No | No |
| **S-14** | El banco son tres piezas: CA-42 (script SQL de H0), T-28 (`CargaOla3Tests`) y T-57 (`CargaOla4Tests`). El costo de escribir un índice lo mide T-28, no CA-42. Lo corre B antes y después, con la máquina sola, y A lo repite en la PC A al unir | No | ≈ 0,05 (una corrida de T-28 al unir) |
| **S-15** | Recomiendo que lo construya **B en la ola 5**. Con una condición de seguridad: un *listener* propio (canalización con nombre y ACL del servicio, o puerto de *loopback* dedicado), **nunca un filtro por `RemoteIpAddress`** | No | Solo revisión (≈ 0,02) |
| **E1-1** | **No es un defecto hoy:** ninguna venta llena el cargo de servicio. Es una reserva: en el cierre de la ola 4 se agrega el parámetro `PropinaLegal` (vale 0); el cálculo de la propina va con el restaurante (entrega 3), salvo que PD-03 diga otra cosa | **Sí** (PD-03: ¿algún cliente de la entrega 1 cobra propina?) | 0,03 |
| **E1-2** | **Defecto real, severidad Alta** si se emite en otra moneda. Afecta a la factura del POS y de la oficina, a las notas y a la caja chica. **Recomiendo corregirlo en el cierre de la ola 4** | **Sí** (que entre en el cierre de la ola 4) | 0,10 a 0,15 |
| **AU-01** | Hoy **no existe** en el núcleo. Propuesta: un motivo de anulación de sistema reservado (`RDG`) más `fiscal.Ecf.Estado = 'RECHAZADO'`. Hay un choque con el disparador del 608 que A debe resolver en su diseño | No (se presenta con el diseño de la anulación automática) | Dentro de T-29c; ≈ 0,02 para fijar el código ya |
| **K-06** | `e167579` **lo resuelve en lo esencial**: pistas y `OPTION` prohibidas, 30 s y `LOCK_TIMEOUT` de 2 s. Quedan para la ola 5: la transacción explícita, el código 409 y cuatro construcciones de ADR-78.1 | No | No |
| **Vectores ADR-77** | El archivo **todavía no existe**. Propuesta: `GPOS-NG` `master`, `docs/contratos/vectores/adr077-carpetas.v1.json`, con su SHA-256. A lo publica en el próximo envío a `master` | No | 0,02 |

**Decide el propietario (cinco puntos):**
1. **S-3:** cuándo y cómo construye B la ola 5.
2. **S-12:** firmar AN-02.
3. **E1-2:** que la corrección entre en el cierre de la ola 4.
4. **E1-1 (PD-03):** si algún cliente de la entrega 1 cobra propina legal.
5. **S-5:** solo la excepción a [H0] 4.2, que ya está en DR-01 de la hoja de B.

**Trabajo nuevo para A (inferido):** de 0,2 a 0,3 sp, casi todo en el cierre de la ola 4 (E1-2 y E1-1). El resto es revisión.

---

## 1. Origen y alcance

### S-1 · Conversación con el propietario
- **Registrado por A (verificado):** `propuesta-api-reportes-solo-lectura-2026-10-07.md:5` y `hoja-firma-api-reportes-2026-10-07.md:6` resumen el pedido así: «una API dedicada solo a reportes, con usuario de solo lectura, y que los reportes `rpt` de la propia aplicación (**pantallas de Reportes, tablero y KPI, consultas**) trabajen con ese mismo aislamiento».
- **Lo que agrega al aviso de B:** el alcance explícito incluye el **tablero, los KPI y la consulta de facturas**, además del diseñador y los 27 reportes.
  - [SW5] ya los pone en la API de reportes. Pero el tablero tiene código nuevo desde `b1874f0` (ver S-13), que la migración debe llevarse.
- **Lo que no era del propietario:** lo demás de la hoja de A eran propuestas de A, ya absorbidas por B en ADR-109 o en sus PD-12 a PD-15:
  - el proceso aparte después del corte;
  - ES256;
  - el canal externo, el MCP y las claves;
  - los 120 s.
- **Memorias del propietario que rigen igual (verificado en la memoria del proyecto):**
  - `rpt` es el camino por omisión y el módulo de análisis es opcional, solo en la central y con sus propios privilegios;
  - el MCP va después de la entrega 1, siempre sobre la API, nunca sobre la base;
  - ningún secreto en texto plano;
  - perfiles de seguridad Básica / Avanzada (FIPS): HS256 y SHA-256 son algoritmos aprobados (inferido del inventario del auditor del 2026-10-05).
- *Límite de esta respuesta:* A no tiene constancia de nada más que el propietario haya dicho de palabra. Si recuerda algo más, que lo agregue a la hoja de B.

### S-2 · Blueprint v2
Publicado: `GPOS-NG-Equipos/traspasos/A/blueprint-razor-jsoncanon-v2.md`, commit `89418fa`. Verifiqué hoy con `cmp` que es idéntico a `Solucion GPOS NG\blueprint-razor-jsoncanon-v2.md`.

---

## 2. Plan y reparto

### S-3 · Quién construye la ola 5 y desde cuándo (**decide el propietario**)

**Estado verificado del árbol:**
- `feature/modelo-ng` = `f21b788`. La ola 4 se construyó el 2026-10-07: 59 commits ese día.
- **La carga T-57 corre hoy**: `carga-ola4-2026-10-08/bitacora.txt`; a las 08:51 se repetía `t28-2`, tras descartar una corrida contaminada.
- La 3b **no ha empezado a construirse**: su diseño está unido (`7c7f5ad`) y su hoja firmada (`0fefbab`).

**Lo que falta para cerrar la ola 4:**
- la carga T-57;
- la exclusión de los e-NCF del 607 y del 608 (0,05 sp);
- E1-2 y E1-1, si el propietario aprueba que entren (0,15 sp);
- la hoja de cierre con su firma.

**Fechas estimadas (inferidas, con su base):**

| Hito | Estimación | Base |
|---|---|---|
| **Cierre de la ola 4** | **9 o 10 de octubre de 2026** | Velocidad observada: 11,5 sp construidas en un día y la ola 3, unas 15 sp en 13 h (`docs/decisiones/2026-10-06-hoja-firma-ola4.md:137`). **Si T-57 no cumple sus metas**, sumar de 2 a 4 días de corrección y una corrida nueva |
| **Unión de la 3b** | **Hacia el 17 de octubre** (rango del 15 al 23) | 12,30 sp (`docs/decisiones/2026-10-07-hoja-firma-ola3b.md`, X-7 y sección 6) a la velocidad observada: de 12 a 16 h de construcción, más QA, la carga de concurrencia PB-3b-12 y la firma. **Peor caso: 30 de octubre**, a la velocidad del plan (4,6 sp por semana). La pista e-CF del núcleo (T-29) y el núcleo de ADR-77 compiten por el mismo árbol |

**Con esas fechas, el corte no está en riesgo (inferido):**
- la ola 5 de B (8,65 sp de núcleo según [HOJA5] B10, más 1,3 sp de vistas) cabe con holgura;
- si empieza el 17 de octubre, aun a la velocidad del plan termina a principios de noviembre;
- eso deja unas 5 semanas hasta mediados de diciembre.

**Opciones:**

| Opción | Qué es | Pros | Contras |
|---|---|---|---|
| **A (la propuesta de B), con preparación limitada. Recomendada** | B crea `b/ola5` desde `feature/modelo-ng` **en el commit de la unión de la 3b**, que A avisa. Mientras tanto puede preparar en su árbol **solo archivos nuevos**: `GPOS.Comun`, `GPOS.Reportes` y `GPOS.Reportes.Api` vacíos o con código propio, la prueba ScriptDom (DR-12) y el SQL de las vistas en archivos `SqlMigracionesOla5*.cs` nuevos. **Sin migración de EF ni *snapshot*, y sin mover ni borrar archivos de A** | Respeta la regla 4 al pie de la letra; cero choques de *snapshot*; el calendario no lo necesita | B empieza a integrar unos 7 días después que con la opción B |
| B (la alternativa de B) | B construye ya en paralelo la API, `GPOS.Comun` y las pruebas sobre el commit del cierre de la ola 4; las migraciones entran al liberar el turno | Gana de 5 a 7 días de calendario (inferido) | **Choques reales con la 3b** (ver abajo); exige rebasar dos veces; el ahorro no hace falta para el corte |
| C | A construye la ola 5 | Ninguno: el diseño y el contexto son de B | Retrasa la 3b y la pista e-CF |

**Por qué no recomiendo B, verificado en el blueprint de la 3b (`docs/arquitectura/2026-10-07-ola3b-blueprint.md`):** la 3b toca justo lo que la ola 5 traslada.
- crea **vistas `rpt` nuevas**: tránsito, diferencias, pérdidas por imputar, lotes y series, `rpt.ConciliacionTransito` y `rpt.DespachosReconstruidos` (:87, :402, :529);
- crea **rutas de reportes** `/api/transferencias/reportes/*` (:234);
- crea la **impresión del conduce** en PDF, con QR (:111, :233).

La ola 5 de B mueve `ReportesService`, el tablero, `FabricaModelo` y las rutas `/api/reportes/*` e `/api/impresion/*` a los proyectos nuevos ([SW5] 7). En paralelo, cada pieza de la 3b sería un choque de fusión, o una vista sin sus permisos de `gpos_lectura`.

**Regla para las dos opciones:**
- Durante la 3b, A no cambia vistas `rpt` existentes ni el modelo de impresión sin avisar antes en el área común. Las excepciones ya anunciadas son la exclusión de los e-NCF y E1-2.
- Las vistas nuevas de la 3b entran al inventario de [DAT5] 3 cuando B rebase.

### S-4 · Fallos fiscales del código de A
Resuelto por el propietario el 2026-10-08 (`decisiones-por-registrar-2026-10-08.md`, «Coordinación con el equipo B», punto 3, y «Como recomiendas, las tres», punto 1).

- **H-R01:** hecho por A en `f21b788`. `rpt.Formato607` informa solo el rol `O` (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla4Reemplazo607.cs:10-16`, migración `20261008111851_Ola4Reemplazo607`).
- **Exclusión de todo e-NCF del 607 y del 608:** la hace A después de T-57, en el cierre de la ola 4, y lo avisa con su commit. B construye sus vistas sobre ese commit para no hacer el trabajo dos veces.
- **Son de B, y A no los toca:** H-R02 (serie B), HD-10, la fecha de emisión de los B anulados (lo que sigue vivo de H-R04) y H-R03, H-R05 a H-R09.
- **Aviso:** si el propietario aprueba E1-2 en el cierre de la ola 4, esa corrección **también cambia `rpt.Formato607`**, porque las formas de pago pasan a la moneda base (ver E1-2). Va en la misma migración que la exclusión de los e-NCF, para que B tenga un solo punto de partida.

### S-5 · Archivos compartidos (**decide el propietario solo la excepción a [H0] 4.2**)
- **`GPOS-NG.slnx`:** hoy tiene 8 proyectos en `src` y 3 de pruebas (verificado). B agrega en `b/ola5` sus tres proyectos y el de pruebas, si lo hay. Son líneas nuevas en la carpeta `/src/`, así que no chocan con la 3b, que no agrega proyectos (inferido de su blueprint). A acepta el cambio al unir.
- **`CLAUDE.md`:** sigue la regla del plan (`plan-dos-equipos.md:43`). B anota el texto en su nota de traspaso y A lo aplica en la unión. Hay que agregar:
  - los tres proyectos y su frontera, por ejemplo: «`GPOS.Reportes` no referencia `GPOS.Core` ni EF»;
  - la regla «solo vistas» (DR-12);
  - el servicio nuevo y su MSI.
- **La excepción a [H0] 4.2** (solo `GPOS.Migracion`) se firma con DR-01 / ADR-109 en la hoja de B. Hay precedente: `GPOS.Criptografia` ya se aceptó como proyecto nuevo con H-17 v2 (`CLAUDE.md:39`).
- **MSI de `GPOS.Reportes.Api`:** un MSI propio por servicio, coherente con ADR-63 (manifiesto) y ADR-76. Debe cumplir ADR-77 desde el primer día:
  - carpeta `%ProgramData%\GPOS NG\Reportes` y render en `GPOS NG\Render\{INST}\{EMP}\` (ADR-077, punto 7);
  - comprobación previa en el MSI y al arrancar (puntos 3 y 4);
  - prueba contra el archivo de vectores (ver la sección 6).
- **Opinión de A sobre `GPOS.Comun` (inferido):** está justificado. Las políticas de ASP.NET no pueden ir en `GPOS.Contracts`, que comparte MAUI, sin arrastrar dependencias de servidor a la aplicación móvil.

---

## 3. Datos del núcleo

### S-7 · Moneda de `fiscal.Comprobante` (verificado: **moneda del documento**)
- El comprobante se arma con las bases de las líneas y los totales, **sin tasa**: `src/GPOS.Core/Servicios/Nucleo/VentasNg.cs:87-91`.
- La moneda de la venta POS es la del usuario de caja, o la base si no tiene (`src/GPOS.Core/Servicios/PosService.cs:241`, `:450-453`). El comprobante se arma en `:265`.
- La venta guarda su `Tasa` (`VentasNg.cs:39`). Los pagos van «en la moneda del documento y en la del pago» (`VentasNg.cs:73`).
- **Contraste:** el 606 **sí** convierte: `Calculadora.Redondear(v * doc.Tasa)` en `src/GPOS.Core/Servicios/DocumentosComercialesService.Compras.cs:287-293`, y `Base(...)` en `EfectivoService.CajaChica.cs:84`. El criterio fiscal del núcleo es la moneda base, pero el 607 no lo sigue.
- `rpt.Formato607` no convierte ni el comprobante ni las formas de pago (`p.Monto`): `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla4b.cs:542-569`.

Consecuencia y corrección: ver **E1-2**. Con E1-2 corregido, RG-04 de [DAT5] 4.1 («el TXT multiplica por la tasa») **sobra**, y si se mantuviera, **convertiría dos veces**. B debe quitarla en cuanto A avise.

### S-8 · Fuentes que todavía no existen (HD-09)
Verificado: ninguna existe en `src` (`f21b788`). Los nombres salen de los diseños de A ya firmados o recomendados.

| Vista reservada | Tabla de origen (nombre previsto) | Tarea y fecha (inferida) | Fuente |
|---|---|---|---|
| `rpt.EcfEstado` | `fiscal.Ecf`, con PK `(DocumentoId, Rol, Generacion)` y columna `Emision`; `fiscal.EcfEvento`; vista `fiscal.ComprobanteVigente` | T-29b (DDL) y T-29c (despachador), en la **pista e-CF del núcleo**, «después de unir la ola 4 y en paralelo con la ola 5». Sin fecha firmada; inferido: de finales de octubre a mediados de noviembre | `docs/integraciones/2026-10-07-ecf-enchufable.md:324-336`, `:560-561`; `respuestas-A-k16-k18-k19-2026-10-07.md:42-45`; `respuestas-A-conector-iq-2026-10-07.md:276` |
| `rpt.Anecf` | `fiscal.Anecf` (rangos, motivo, estado y respuesta) | T-29b y T-29c, como la anterior. Depende además de C-47 (pregunta 11 del contador; se envía una sola vez) | `ecf-enchufable.md:335` |
| `rpt.CambioTipoComprobante` y la columna `EsRefacturacion` | **No hay nombre fijado.** Propuesta de A (inferida): `ventas.Venta.DocumentoOrigenId` (ya existe, `VentasNg.cs:41`) más una marca `ventas.Venta.Refacturacion bit` (o un tipo de relación) que el arquitecto-datos de A fija en T-29b. La E34 se enlaza por `fiscal.Comprobante.NcfModificado` | Flujo y aviso en la pista e-CF; el reporte, en la ola 5 (0,05 sp) | `respuestas-A-conector-iq-2026-10-07.md:189`, `:276-278`, `:291` (P-A2) |
| `integ.Envio` | `integ.Envio` (conector, tipo, clave, `IdExterno`, estado, intentos, huella, error) y `integ.Cursor` | Publicador y conectores ERP: **después del corte** (después de la fase 1 de e-CF) | `docs/decisiones/2026-10-07-hoja-firma-adr073-auxiliar-contable.md:157`, `:164`, `:244` |
| `rptsis.AccesoSuper` | `dbo.BitacoraSistema` en `GPOS_SYSDATA` (ADR-37; incluye «ingreso del Super Usuario con su motivo») | Con L1. Hoy no existe: `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs:75` dice «`BitacoraSistema` llega con L1» | `ADR-037.md:10-11`; ADR-35 |
| `rptsis.LicenciaVigente`, `rptsis.RelojSitio` | Los de L1 y H-16 v2.1 | L1: objetivo **2026-12-15** | `docs/decisiones/2026-10-05-decision-licencia-por-vigencia.md:51` |

**Conclusión:** ninguna de las seis llega dentro de la ola 5 con certeza. Que sigan reservadas, como propone [DAT5] 3.6, es lo correcto.

**Aviso para B (K-16):** cuando llegue T-29b, `fiscal.Comprobante` pasa a la PK `(DocumentoId, Rol, Emision)`. El rol `O` siempre tendrá `Emision = 1`, así que las vistas que filtran `Rol = 'O'` no cambian (inferido de `respuestas-A-k16-k18-k19-2026-10-07.md:42`, :60). Las que lean el rol `R` deben usar `fiscal.ComprobanteVigente`.

### S-9 · `PropinaLegal = 0`
Es E1-1 (ver la sección 5).

### S-10 · Dueño de los esquemas y contención (HD-01, HD-02)
**Verificado:**
- `Fundamentos.cs:15` crea los esquemas con `EnsureSchema`, sin `AUTHORIZATION`.
- `GPOS.Migracion` aplica el esquema con la cuenta de Windows de quien la ejecuta, o con `--login` (`src/GPOS.Migracion/EmpresasSistema.cs:70-75`).
- `CREATE DATABASE` va sin `CONTAINMENT` (`src/GPOS.Migracion/Aprovisionamiento.cs:62`).

**A acepta la sección 2 de [DAT5]** (`AUTHORIZATION dbo` en los esquemas nuevos, la comprobación V-R1 que falla cerrada con 51399, la corrección de bases mezcladas y `CONTAINMENT = PARTIAL`), con tres condiciones:
1. **`CONTAINMENT = PARTIAL` sigue el patrón de RCSI** (`Aprovisionamiento.cs:293-299`): se aplica en «aprovisionar» y en «actualizar», con el aviso «ejecute con la API detenida» y `WITH ROLLBACK IMMEDIATE`. Así se cubren las bases de desarrollo, el DEMO y la del socio.
   - Si la instancia no tiene `contained database authentication = 1`, la herramienta **no falla**: usa la alternativa de [DAT5] 2.4 (un inicio de sesión por usuario) y lo informa. Lo decide PD-07.
2. **51399** es la convención de A para «falla clara de migración» (`20261006170943_Ola3EmisionLigera.cs:19`, `20261007072312_Ola4bImplantacion.cs:37`): usarlo en V-R1 es coherente. El mensaje debe nombrar el esquema o el objeto con otro dueño.
3. **Lo construye B en la ola 5**, en `GPOS.Migracion`, con pruebas en `GPOS_TEST_*`. A solo revisa (≈ 0,02 sp). La 3b no toca `Aprovisionamiento.cs` (inferido de su blueprint), así que no hay choque.

### S-11 · Valor del inventario en el tablero (HD-05): **falso positivo**
- `src/GPOS.Core/Servicios/DashboardService.cs:53-54`: «El valor del inventario es al costo: requiere además el privilegio Ver costos (CO-3)». Exige `ReportesInventario` **y** `sesion.VerCostos()`.
- `VerCostos()` es `TienePermiso(Permisos.VerCostos)` (`src/GPOS.Core/Infraestructura/Sesion.cs:64`).
- La condición está igual en `b1874f0` y viene del primer commit (`e2f59ba`).
- **Conclusión:** HD-05 se retira y PD-09 sobra.
- Lo único pendiente es el **privilegio efectivo** de DA-02 (`CostosSoloEnCentral`), que todavía no existe en el código (búsqueda sin resultados). Llega con la 3b-1. Cuando el tablero pase a `rptc`, B debe conservar esa condición y leer el privilegio efectivo, no solo el permiso.

### S-12 · AN-02 (PD-08) (**decide el propietario**)
**Verificado: no está firmada.**
- `GPOS NG/docs/decisiones/2026-10-04-decision-modulo-analisis.md:3` dice «Estado: Pendiente de firma».
- La fila de AN-01 dice «FIRMADA el 2026-10-05» (:137); la de AN-02 (:143) no lleva marca de firma.
- No la encontré en ningún registro de decisiones de `Solucion GPOS NG`.

**Recomendación:** firmar AN-02 con el esquema `ext` antes de que B genere la migración de la ola 5. El propio documento lo pedía antes de la ola 5 (:42, :171, :269).
- *Si no se firma:* la migración crea los `DENY` solo para los esquemas que existan (K-08 de A).

### S-13 · Cambios después de `b1874f0` (verificado con `git diff b1874f0 f21b788`, 42 commits)

| Elemento | ¿Cambió? | Detalle |
|---|---|---|
| `ModeloImpresion`, `ImpresionDatosService`, `Api/Impresion/FabricaModelo.cs`, `FormatosService` | **No** | Sin diferencias |
| `ReportesService.cs` | **Sí** | `e167579` (K-06): pistas, 30 s y `LOCK_TIMEOUT` |
| `ReportesSemilla.cs` | **Sí** | `76917ac`: `SaldosCxp`, `Compras` y `DocsBancarios` pasan de las tablas heredadas (`vw_GPost_DocumentosCxP`, `cxp_Facturas_e`, `EF_Cheques_e`) al modelo nuevo (`cxp.Cuenta`, `compras.Compra`, `fiscal.Registro606`, `banco`, `caja`) |
| Vistas `rpt` | **Sí, una** | `rpt.Formato607` (H-R01), migración `Ola4Reemplazo607`. Las otras 5 migraciones nuevas (`Ola4Conversion`, `Ola4Retiro`, `Ola4Huecos`, `Ola4AjusteCerrada`, `Ola4IndiceKardex`) no tocan `rpt` |
| Tablero | **Sí** | Nuevo `DashboardService.AvisosAsync` (`DashboardService.cs:64-77`), ruta `/dashboard/avisos` (`src/GPOS.Api/Endpoints/ReportesEndpoints.cs:34`), consulta `ConsultasCierreSucursal.CerradasConExistencias` (aviso E-2 del cierre de sucursal). Entra en el traslado del tablero |

**Cambios anunciados que todavía no están en el árbol:**
1. La exclusión de los e-NCF en `rpt.Formato607` y `Formato608` (después de T-57).
2. E1-2: conversión a la moneda base en el comprobante y en las formas de pago del 607, si se aprueba.
3. Las vistas `rpt`, las rutas de reportes y el conduce en PDF de la 3b (ver S-3).
4. K-16 en T-29b (ver S-8).
5. Las rutas de ADR-77 en el núcleo (render y licencia bajo `%ProgramData%\GPOS NG`).

---

## 4. Medición

### S-14 · Banco de CA-42 y línea base B9
- **CA-42** es una **prueba de planes** del Z (lectura) sobre una base de 2.000.011 movimientos: `docs/datos/scripts/2026-10-04-h0-pruebas-entrega1.sql:848-971`. Resultado: p95 de 41,9 ms (`docs/datos/2026-10-04-h0-modelo-datos-entrega1.md:335`).
  - **No mide el costo de escribir en un índice.** Sirve para comprobar que I-02 o el columnstore no empeoran el Z.
- **La línea base de carga (B9)** son dos pruebas que solo corren con `GPOST_B9`:
  - `tests/GPOS.Tests/ModeloNg/CargaOla3Tests.cs` (T-28; :14-32): con `GPOST_B9=medir` solo informa; con `=1` exige las metas;
  - `tests/GPOS.Tests/ModeloNg/CargaOla4Tests.cs` (T-57).
  - La meta que vigila la venta es la **meta 1**: p95 de la venta ≤ 52 ms, o la contingencia F-c (commit `896551c`). **Es la que mide el +11 % de filas de índice.**
- **Quién la corre y cómo (recomendación, no requiere firma):**
  1. **B**, en la PC B y con la máquina sola (regla de la PC B: lo pesado de SQL Server corre solo), corre T-28 con `GPOST_B9=medir` **dos veces sin y dos veces con** I-01 a I-04, en el mismo commit. Informa la diferencia relativa del p95 de la venta y los disparadores por tramo. El criterio de [DAT5] V-D5 es «no empeora más que el ruido entre corridas», que hoy anda en unos ±5 % (inferido de la bitácora de hoy, que necesitó repetir una corrida). Repite CA-42 si agrega el columnstore.
  2. **A** repite T-28 en la PC A al unir la ola 5, con el procedimiento de C-1: 15 minutos de enfriamiento y sin otras cargas. La PC A tiene la línea base absoluta (`carga-ola4-2026-10-08`). ≈ 0,05 sp de máquina.
- Las metas absolutas solo valen en la misma máquina. Entre las dos PC, se comparan diferencias, no cifras.

### S-15 · `/api/interno/token/verificar` (recomendación: **lo construye B en la ola 5**)
**Por qué B:**
- lo consume y lo retira B, con ES256;
- su prueba de extremo a extremo vive con `GPOS.Reportes.Api`;
- son unas 0,1 sp (inferido): un archivo nuevo de rutas y una línea en `Program.cs`, sin choque con la 3b.

A revisa (≈ 0,02 sp).

**Condición de seguridad (hallazgo, severidad Alta si se construye como dice [SW5] 5.2):** [SW5] 5.2 lo protege con «solo responde a `127.0.0.1` o `::1`». **No basta en la API principal:**
- `Program.cs:45-49` y `:186` activan `UseForwardedHeaders` con `X-Forwarded-For`, así que `RemoteIpAddress` **se reescribe** con lo que diga un proxy confiable.
- ASP.NET Core trae el *loopback* como proxy conocido por omisión (inferido de la documentación del *middleware*).
- Con IIS o cualquier proxy inverso en la misma máquina (ADR-24), una petición externa puede llegar **desde** `127.0.0.1` si el proxy no agrega el encabezado (inferido).
- El resultado sería un oráculo de tokens expuesto a la red.

**Diseño que recomiendo (cualquiera de los dos):**
1. **Canalización con nombre en Kestrel** (`ListenNamedPipe`, desde .NET 8; el proyecto usa `net10.0`, `GPOS.Api.csproj:4`). Su ACL permite solo a `NT SERVICE\GPOS.Reportes.Api`, la identidad de ADR-75 y ADR-76. Se ajusta con `NamedPipeTransportOptions.PipeSecurity` (inferido; hay que verificarlo en net10). La ruta se mapea **solo** en ese *endpoint* (`RequireHost` o un filtro por `LocalEndPoint`). **Es la preferida:** el sistema operativo autentica al que llama, sin secreto nuevo.
2. Un puerto dedicado con `ListenLocalhost`, filtrado por el **puerto local** (`HttpContext.Connection.LocalPort`), nunca por la IP remota, y fuera de IIS.

**Además:**
- no registrar el token en el *log* (solo su SHA-256);
- responder solo `{ valido, sub, empresa, sucursal, sid, exp }`, sin el resto de las *claims*;
- límite de frecuencia propio;
- prueba que confirme que la ruta da 404 por el *listener* público.

---

## 5. E1-1 y E1-2: código de A en el comprobante

### E1-2 · Montos del comprobante en USD sin tasa: **defecto real, severidad Alta** (**decide el propietario** si entra en el cierre de la ola 4)

**Evidencia (verificado):**

| Origen | Línea | ¿Convierte? |
|---|---|---|
| Factura POS | `PosService.cs:265` → `VentasNg.Comprobante` (`VentasNg.cs:87-91`) | **No** |
| Factura y nota de crédito de oficina | `DocumentosComercialesService.Ventas.cs:258`, `:266` | **No** |
| Nota de crédito o débito de CxC | `CobrosService.cs:398` | **No** |
| B13 de caja chica (comprobante) | `EfectivoService.CajaChica.cs:88` | **No** (su 606, en `:84`, sí) |
| B11 de compras (comprobante) | `DocumentosComercialesService.Compras.cs:201` | **No** (su 606, en `:287-293`, sí) |
| 607: formas de pago | `SqlMigracionesOla4b.cs:553-561` (`p.Monto`, en la moneda del documento) | **No** |

**Cuándo ocurre:** siempre que el documento esté en una moneda distinta de la base.
- **POS:** el usuario de caja configurado en USD (`PosService.cs:241`), que es el caso típico de Duty Free.
- **Oficina:** la factura o la nota en USD.
- **No ocurre** cuando la venta es en pesos y solo **se cobra** en dólares (pago multimoneda): ahí el documento y el comprobante quedan en pesos.

**Efecto:** el 607 informa los montos en dólares como si fueran pesos. El ingreso y el ITBIS quedan subdeclarados en la proporción de la tasa. Lo mismo pasaría con el umbral de RD$250.000 y con el e-CF, que lleva los montos en DOP y la otra moneda solo como dato (inferido del Formato e-CF).

**Severidad:**
- **Alta** para todo cliente que emita en otra moneda: es un dato fiscal mal informado (Código Tributario, deberes formales; inferido).
- **Hoy no hay daño**: no hay producción (`bp2-nunca-en-produccion`, `todo-es-desarrollo`).

**Recomendación: corregirlo en el cierre de la ola 4**, en el mismo commit que la exclusión de los e-NCF. Motivos:
1. El comprobante es **solo de inserción**: corregirlo después exige migrar datos.
2. Las vistas de la ola 5 de B dependen de este dato. Si se corrige después, B tendría que convertir en la vista (RG-04) y luego quitar esa conversión.
3. Es poco trabajo.

**Corrección propuesta (≈ 0,10 a 0,15 sp; inferido):**
- **Un solo punto:** `EmisionNcfNg` recibe la tasa del documento y la tasa de la moneda base (la misma regla de `PosService.cs:357`, `tasa / tasaBase`), y convierte `Gravado`, `Exento`, `Itbis`, `PropinaLegal` y `Total` con `Calculadora.Redondear`, igual que el 606.
  - La diferencia de centavos va al componente mayor, para que **gravado + exento + ITBIS + propina = total**, como en POS-7.
  - Los cinco puntos de la tabla dejan de calcular por su cuenta.
- **`rpt.Formato607`:** las formas de pago y el crédito se convierten con la `Tasa` de la venta y se ajustan para que sumen el `MontoTotal` convertido, de modo que F-02 (`rpt.Cuadre607FormasPago`) dé 0 filas.
  - Va en la misma migración que la exclusión de los e-NCF.
  - La vista expone `MonedaId` y `Tasa` del documento para la auditoría, como propone [DAT5].
- **Pruebas:**
  - venta POS con usuario en USD;
  - factura y nota de oficina en USD;
  - B13 en USD;
  - venta en pesos cobrada en USD (no debe cambiar);
  - el 607 cuadra con las formas de pago.
- **Datos existentes:** solo hay bases de desarrollo, del DEMO y del socio.
  - La migración puede recalcular los comprobantes con `Tasa <> 1`, con la identidad de esquema, porque `gpos_app` tiene `DENY UPDATE`.
  - O dejarlos así, porque no tienen valor fiscal.
  - **Recomiendo recalcularlos** (+0,02 sp), para que el DEMO no muestre un 607 erróneo.
- **Lo que sobra en B:** RG-04 de [DAT5] 4.1, la conversión en el TXT. Riesgo de convertir dos veces: B la quita con el aviso de A.

*Alternativa descartada:* dejar el comprobante en la moneda del documento y convertir en las vistas (RG-04 de B). Tiene tres problemas:
- el comprobante quedaría distinto del 606, que ya está en pesos;
- el e-CF y el umbral tendrían que convertir por su cuenta, en tres lugares;
- la tasa de la vista sería la de la venta, sin control sobre el redondeo del dato fiscal.

### E1-1 · Propina legal en 0: **no es un defecto hoy (severidad Baja)**; es una reserva (**PD-03, decide el propietario**)

**Evidencia (verificado):**
- el `INSERT` pone `0` (`src/GPOS.Core/Consultas/Fiscal/ConsultasFiscal.cs:30-37`);
- **ninguna venta llena el cargo de servicio**:
  - `VentasNg.Agregar` no asigna `CargoServicio` (`VentasNg.cs:35-42`);
  - el único que lo usa es el **cheque devuelto**, para el cargo del banco (`CobrosService.cs:544`), y no emite comprobante;
  - el parámetro `PorcentajeCargoServicio` (`src/GPOS.Core/Dominio/Configuracion/Empresa.cs:54`) no lo lee ninguna venta.
- Hoy el 607 informa 0 porque **ninguna venta cobra propina**. Es coherente.

**Riesgo futuro:** **Alta** cuando se active el restaurante (entrega 3), o si un cliente de la entrega 1 cobra el 10 % de ley.

**Recomendación:**
1. **En el cierre de la ola 4, junto con E1-2** (son las mismas líneas): `DatosComprobante` gana `PropinaLegal`, que vale 0, y el `INSERT` usa `@propina`. Con su prueba. ≈ 0,03 sp.
2. **No hay que asignar `Venta.CargoServicio` a la propina sin más:** esa columna ya lleva el cargo del banco del cheque devuelto. La propina necesita un origen propio, por ejemplo un componente «propina legal» del cálculo de la venta, que diseña el especialista-pos con el restaurante.
3. **PD-03 al propietario:** «¿Algún cliente de la entrega 1 cobra propina legal?».
   - **No** (lo que espero, inferido de que el restaurante va en la entrega 3): el cálculo va en la entrega 3.
   - **Sí:** entra en la ola 5, con unas 0,15 a 0,25 sp (cálculo, pantalla del POS, impresión e ITBIS de la propina), y hay que ordenarlo antes del corte.

---

## 6. Preguntas de los acuses del 2026-10-08

### AU-01 · De dónde sale «anulado por rechazo de la DGII»
**Verificado: hoy no existe en el núcleo.**
- no hay `fiscal.Ecf` (`src/GPOS.Core/Datos/Empresa/Configuracion/FisConfiguracion.cs:9`);
- no hay marca ni motivo de sistema para el rechazo (búsqueda en `src`).

La anulación automática por rechazo está decidida: 2026-10-07, con A, B, C, X-1, X-2 y P-04-a. Su diseño está pendiente en A y va en la pista e-CF (T-29c).

**Propuesta de A para el diseño (inferido; se cierra con el arquitecto-datos de A en T-29b):**
1. **Motivo de anulación de sistema reservado** en `cat.MotivoAnulacion`:
   - código `RDG` («Rechazado por la DGII»);
   - no editable ni inhabilitable;
   - **solo lo puede usar la identidad `SISTEMA`**: el disparador rechaza que una sesión de usuario lo use.
   - La anulación automática pone `MotivoAnulacionId = RDG` y `AnuladoPor = 'SISTEMA'`.
2. **Evidencia:** la generación de `fiscal.Ecf` con `Estado = 'RECHAZADO'`, enlazada al documento.
3. **Para `rpt.Anulacion`:** `OrigenAnulacion = CASE WHEN m.Codigo = 'RDG' THEN 'R' ELSE 'M' END`.
   - El control de B («e-NCF anulados a mano = 0 filas») queda así: serie E, `Estado = 2` y motivo distinto de `RDG`.
   - Opcionalmente se cruza con `fiscal.Ecf` para detectar un `RDG` sin rechazo registrado.

**Choque que A debe resolver en ese diseño (hallazgo, Media):**
- el disparador `doc.TR_Documento_Motivo608` exige motivo **y** `CodigoAnulacion608` a todo documento anulado con comprobante (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla3EmisionLigera.cs:271-283`, error 51312);
- [HOJA5] (AU-01) supone que `CodigoAnulacion608` **queda vacío en la serie E**;
- tal como está el disparador, la anulación por rechazo de un e-NCF fallaría.

**Propuesta:** precisar el disparador. En un comprobante de la serie E basta el motivo, y `CodigoAnulacion608` debe ir en `NULL`, porque los e-NCF no van al 608 (regla del 2026-10-08). A lo hace junto con la exclusión de los e-NCF o en T-29b. ≈ 0,02 sp.

**Para que B no espere:** A puede fijar ya el código `RDG` y la regla del disparador en el cierre de la ola 4. Así la vista A-01 de B se construye sobre el dato definitivo, aunque la anulación automática llegue con T-29c.

### K-06 · ¿`e167579` lo resuelve? **Sí, en lo esencial (bloqueo y tiempo)**
Verificado en `src/GPOS.Core/Servicios/ReportesService.cs`:
- **Pistas y `OPTION` prohibidas** (`:36-38`): `TABLOCK(X)`, `UPDLOCK`, `HOLDLOCK`, `XLOCK`, `PAGLOCK`, `ROWLOCK`, `NOLOCK`, `READPAST`, `NOWAIT`, los niveles de aislamiento, `SNAPSHOT`, `FORCESEEK`, `FORCESCAN`, `NOEXPAND` y `OPTION`.
  - Se buscan fuera de los literales y de los nombres entre corchetes (`:205-208`).
  - `SET` ya estaba prohibido (`:27`), así que el usuario no puede cambiar `LOCK_TIMEOUT`.
- **30 s** (`:44`, `:392`).
- **`SET LOCK_TIMEOUT 2000`** (`:41`, `:386`), que se repone a −1 antes de devolver la conexión al grupo (`:415`).
- 1222 y el tiempo agotado tienen mensajes propios (`:397-404`).
- La vista previa del diseñador (`EsquemaAsync`) pasa por el mismo ejecutor.

**Queda para la ola 5 (ADR-109 o B8 de B):**
1. Sigue la **transacción explícita** (`:378`). Con RCSI no toma bloqueos compartidos, así que el riesgo es bajo (inferido). ADR-78.3 pedía *autocommit*.
2. **Códigos de error:** 1222 y el tiempo agotado salen como `ReglaNegocioException`, es decir, **400** (`src/GPOS.Api/Program.cs:266`), no 409 `REPORTE_BLOQUEADO`.
3. **No se prohíben** `INDEX(`, `TABLESAMPLE`, `FOR XML` ni `FOR JSON`, que estaban en la lista de ADR-78.1. Ninguno bloquea la operación. Son de costo o de tamaño, y los cubren los límites de la ola 5.
4. **Lo prohibido rige solo para el SQL del ADMIN.** El tablero y las consultas registradas usan el tiempo del contexto, 60 s (`Sesion.cs:110`; inferido que es la fábrica que usa `AbrirUnidadAsync`). B debe llevarlos a 30 s al pasarlos a la API de reportes.

### Archivo de vectores de ADR-77, punto 6
**Verificado: no existe.** Busqué en `GPOS-NG` `master` y en el área común: el SDDL `0x1200a9` solo aparece en ADR-77 y en su hoja.

**Propuesta (no requiere firma; A la ejecuta):**
- **Ubicación canónica:** `GPOS-NG`, rama `master`, `docs/contratos/vectores/adr077-carpetas.v1.json`. Contiene:
  - el SDDL de la raíz;
  - la lista blanca de dueños (SYSTEM, Administradores, TrustedInstaller);
  - los escritores admitidos por componente, con su identidad de servicio declarada;
  - los casos de rechazo de la comprobación previa (punto de reanálisis, no carpeta, dueño ajeno, escritor ajeno);
  - un campo `version`.
- **Cómo lo usa cada repositorio:**
  - el conector de IQ, la API, el agente y `GPOS.Reportes.Api` **copian** el archivo en su proyecto de pruebas, con su SHA-256 en un comentario o en un archivo `.sha256`;
  - la prueba compara la constante del instalador con la copia;
  - un script del área común (`herramientas/`) compara la huella de cada copia con la canónica. No se lee otro repositorio al compilar.
- **Cuándo:** A lo publica en el próximo envío a `master`, que será cuando termine la carga, y lo avisa. ≈ 0,02 sp.
- La misma carpeta servirá para los vectores de `gpos-jcs-1` (ADR-74, fase 0) cuando existan.

---

## Supuestos
- Las fechas de S-3 son inferidas de la velocidad observada en las olas 3 y 4. Dependen de que T-57 cumpla sus metas y de que la pista e-CF no se lleve el árbol antes de la 3b.
- Que la 3b no agregue proyectos ni toque `Aprovisionamiento.cs` está inferido de su blueprint; no lo comprobé contra código, porque no existe todavía.
- Que el *loopback* sea proxy conocido por omisión en `ForwardedHeadersOptions`, y que exista `NamedPipeTransportOptions.PipeSecurity` en .NET 10, sale de la documentación de ASP.NET Core; no lo probé.
- Que el e-CF lleve los montos en DOP con la otra moneda como dato está inferido del Formato e-CF. Lo confirma el arquitecto-integraciones.
- El ruido de ±5 % entre corridas de T-28 es una estimación, no una medición.
- Supongo que la moneda base de las empresas dominicanas es el peso. Si una empresa tuviera otra moneda base, el 607 igual exige pesos y la conversión de E1-2 debe apuntar a DOP; habría que verificarlo con el especialista-contable.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\respuestas-A-ola5-solicitud-2026-10-08.md`
- Supuestos: los de la sección «Supuestos».
- Decisiones candidatas a ADR:
  - ninguna nueva de A;
  - la excepción a [H0] 4.2 va en DR-01 / ADR-109 de B;
  - la precisión de `doc.TR_Documento_Motivo608` para la serie E entra en el diseño de la anulación automática (T-29), como precisión de ADR-108 si el maestro lo estima necesario.
- Entregas a otros agentes:
  - **desarrollador-backend (A):** E1-2, E1-1 (parámetro), el motivo `RDG` y la regla del disparador, en el cierre de la ola 4, si el propietario lo aprueba;
  - **arquitecto-datos (A):** nombre del vínculo de refacturación y de `fiscal.Anecf` en T-29b;
  - **documentador-tecnico (A):** archivo de vectores de ADR-77 en `master`;
  - **arquitecto-maestro (B):** quitar PD-09 y HD-05, retirar RG-04 tras E1-2, incorporar las condiciones de S-10 y S-15, y AU-01 con `RDG`;
  - **auditor-seguridad (B):** revisar el *listener* de S-15;
  - **especialista-contable:** confirmar que la moneda base es siempre DOP y PD-03;
  - **qa-automatizado (B):** el protocolo de T-28 con y sin índices de S-14.
- Próximo paso recomendado: que el propietario responda S-3, S-12, E1-2, PD-03 y DR-01, y que A anuncie en el área común el commit del cierre de la ola 4 con la exclusión de los e-NCF y E1-2.
