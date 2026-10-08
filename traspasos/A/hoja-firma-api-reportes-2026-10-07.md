# Hoja de firma de la API de reportes de solo lectura: ADR-77 a ADR-80, P-1, P-2 y PR-1 a PR-4

**Fecha:** 2026-10-07 · **Preparada por:** Arquitecto Maestro (equipo A) · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado: Pendiente de firma.** Los cuatro ADR y las dos precisiones están en estado **Propuesto**. Nada de esto existe todavía en el código: los reportes corren hoy con la conexión de la aplicación.

**Para qué sirve.** Reúne en una hoja lo que el propietario pidió el 2026-10-07: una API dedicada a reportes con un usuario de solo lectura, y que los reportes `rpt` de la propia aplicación (pantallas de Reportes, tablero y KPI, consultas) trabajen con ese mismo aislamiento. La propuesta técnica es del arquitecto-software. Aquí se firma el texto de cada decisión, con las correcciones que encontré al cruzarla con los ADR vigentes y con lo que el propietario ya decidió.

**Lo que no se firma aquí (ya en curso en la ola 4, según el encargo):** la prohibición de pistas de bloqueo y de `OPTION` en el SQL de los reportes, el tiempo máximo de 30 s (ADR-38 M-2, ya firmado) y el `LOCK_TIMEOUT`. ADR-78 los cita como «ya corregido en la ola 4» y no los somete a firma.

**Fuentes (leídas hoy, solo lectura; ningún repositorio se modificó)**
- `[PRO]` = `Solucion GPOS NG\propuesta-api-reportes-solo-lectura-2026-10-07.md` (arquitecto-software; secciones 0 a 10).
- `[DEC]` = `Solucion GPOS NG\decisiones-por-registrar-2026-10-07.md`, sección final («noche»), :43-68.
- `[ANL-D]` = `GPOS NG\docs\decisiones\2026-10-04-decision-modulo-analisis.md` (ADR-55 a 57 propuestos en :278-330; AN-02 en :143; AN-05 en :151; SA-01 en :181; [ANL] 7.9 en :36).
- ADR-11, 12, 24, 34, 38, 40, 41, 53, 58 y 73 en `GPOS NG\docs\adr` (`master`, `01223d1`).
- Código, `GPOS-NG-numeracion`, rama `feature/modelo-ng` (`bd7eb27`), solo lectura: `src/GPOS.Core/Servicios/ReportesService.cs`, `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigraciones.cs`, `src/GPOS.Api/Seguridad/Seguridad.cs`, `src/GPOS.Api/Endpoints/ReportesEndpoints.cs`.
- Memorias del proyecto: módulo de análisis en estrella, MCP para modelos de IA, licencia por vigencia, sucursal en línea y licencia, perfiles de seguridad (FIPS), sin texto plano.

**Convención.** *Verificado:* leído hoy en la fuente citada. *Inferido:* conclusión o estimación mía, con su base. **sp** = semanas-persona. Dinero a USD 1.500 a 2.000 por sp (base de la hoja de seguridad del 2026-10-05).

---

## 1. Resumen ejecutivo

| Punto | Qué decide | Recomendación | Costo (inferido) | Cuándo se construye | Firmar antes de |
|---|---|---|---|---|---|
| **ADR-77** · Aislamiento de lectura en el motor | Todo SQL de reportes corre con `gpos_rpt_<EMP>` (o `gpos_rptc_<EMP>`), que solo lee `rpt` y tiene `DENY` en todo lo demás. Nunca con la conexión principal | **Aprobar** | Dentro de la ola 5 ya planificada (2,5 sp) + 0,25 sp | Ola 5 (2026-11-16 a 11-24) | **2026-11-16** |
| **P-1** · Precisión de PR-ADR38 (`rptc`) | Las vistas con costos van al esquema `rptc`; las lee solo `gpos_rptc_<EMP>`, cuando la API ya evaluó el privilegio efectivo de costos | **Aprobar**, con la corrección K-03 (nodos) | 0,1 sp (en las 0,25 de ADR-77) | Ola 5 | **2026-11-16** |
| **ADR-78** · Límites para proteger la operación | Sin transacción explícita, `MAXDOP` y `MAX_GRANT_PERCENT`, límite del optimizador, concurrencia por empresa y por usuario, bytes, paginación, totales en el servidor y exportación en streaming. **Precisa ADR-38 M-2** (120 s solo para programados fuera de horario, K-01) | **Aprobar** | 0,35 sp | Ola 5 | **2026-11-16** |
| **ADR-79** · Escrituras fuera del login de reportes | Preferencias en `GPOS.Api`; bitácora `rep.Ejecucion` en `GPOS_SYSDATA`, solo inserción, 13 meses | **Aprobar** | 0,1 sp | Ola 5 (la bitácora puede pasar a F2 si falta tiempo) | **2026-11-16** |
| **ADR-80** · Proceso aparte y exposición externa | `GPOS.Api.Reportes` solo en la central, para Power BI, Excel, el contador y el MCP; con ES256, **anillo de llaves propio** (K-02) y, con varias empresas, la versión 1 del acceso multiempresa. Claves con alcance; nunca un login SQL para terceros. **Precisa ADR-40 y ADR-24** | **Aprobar (a) y (c); (b) «No por ahora»** | 1,1 a 1,2 sp (F2) + 1,0 sp (F3) | Después del corte del 2026-12-02 | Antes de abrir F2 (puede firmarse hoy) |
| **P-2** · Análisis y MCP como clientes de esta API | Una sola superficie de lectura en la central; el MCP nunca entra a la base | **Aprobar en principio** | MCP 0,8 a 1,2 sp | Después de la entrega 1 | Con AN-03 a AN-17 |
| **PR-1** · Claves y cupo de licencia | Las claves de empresa no ocupan cupo de usuario; tope de claves activas en la licencia | **No ocupan cupo**, tope en la cláusula de módulos de ADR-58 | 0 | F3 | Con la precisión de ADR-58 |
| **PR-2** · Acceso externo | Solo por VPN (o un *gateway* local de Power BI), sin publicar en internet | **Solo VPN** | 0 | F3 | Antes de F3 |
| **PR-3** · Privilegio `rptexportar` | Nuevo privilegio, concedido por omisión a quien hoy exporta | **Sí** | Dentro de ADR-78 | Ola 5 | **2026-11-16** |
| **PR-4** (nueva, K-03) · Costos en los nodos | `rptc` en un nodo solo si la empresa tiene `CostosSoloEnCentral` apagado | **Sí** | ≈ 0,02 sp | Ola 5 | **2026-11-16** |

**Totales.** Ola 5: **+0,8 sp** (de 0,5 a 1,1) sobre lo planificado, unos **USD 1.200 a 1.600** (rango de 750 a 2.200), y un día de calendario. Después del corte: **3,4 a 3,5 sp** (de 2,6 a 5,1), unos **USD 5.100 a 7.000**, sin la copia de lectura opcional. Infraestructura: USD 0. **El corte del 2026-12-02 no se mueve.**

---

## 2. Contradicciones y huecos detectados al consolidar

| # | Hallazgo | Evidencia | Severidad | Cómo queda en el texto |
|---|---|---|---|---|
| **K-01** | **ADR-78 contradice ADR-38 M-2.** M-2 fija «un tiempo de espera de 30 s» para todo SQL del cliente. `[PRO]` 4.2 propone 120 s para programados y exportaciones grandes. Lo presenta como «corrige el desvío de 120 s», pero introduce una excepción a un texto firmado | `ADR-038.md:11`; `[PRO]`:210 y :317 | **Alta** (normativa: no se puede construir contra un ADR aceptado sin precisarlo) | ADR-78, punto 2: **precisión de ADR-38 M-2**, solo para reportes programados, fuera del horario de caja que fije la empresa y con una sola ejecución a la vez por empresa. Las exportaciones desde la pantalla quedan en 30 s (más estricto que `[PRO]`). Se firma con FR-78 |
| **K-02** | **Un propósito de Data Protection no aísla secretos.** `[PRO]` 5 dice que el proceso aparte no tendrá «el anillo de la API principal» porque el propósito `GPOS.Reportes.Conexion` le da «solo esas conexiones». El propósito deriva una subllave del **mismo** anillo: quien tiene el anillo descifra cualquier propósito, incluidas las cadenas `gpos_app_<EMP>` de todas las empresas. Es justo el segundo argumento con que ADR-40 descartó R2 («exige un almacén de secretos propio») | `[PRO]`:108 y :263; `ADR-040.md:66`. Inferido del diseño de Data Protection (las subllaves por propósito salen de las llaves maestras del anillo), no probado | **Alta para F2** (sin corregir, el proceso aparte no reduce el radio de daño, que es su razón de ser) | ADR-80, punto 3: el proceso tiene **su propio anillo** (`CifradorAnillo` de H-17 v2, carpeta y ACL propias), y `GPOS.Migracion` le entrega solo las cadenas `gpos_rpt`, `gpos_rptc` y `gpos_rptsys`, cifradas para ese anillo. Costo: +0,1 a 0,2 sp en F2 (inferido). En la ola 5 no cambia nada: el módulo sigue dentro de la API |
| **K-03** | **DA-02 es condicional, `[PRO]` lo lee como absoluto.** `[PRO]` 2.2 dice «`gpos_rptc_<EMP>` no se crea en los nodos (DA-02: costos solo en la central)». DA-02 solo rige con `CostosSoloEnCentral` encendido; apagado, «este ADR rige sin cambios» y un usuario con Ver costos ve costos en cualquier sucursal | `[PRO]`:95; `ADR-012.md:14` y :21 | Media (con el parámetro apagado, un nodo perdería los reportes de costo que hoy tiene) | **PR-4**: en un nodo, `rptc` y `gpos_rptc_<EMP>` existen solo si el parámetro está apagado; al encenderlo, `GPOS.Migracion` retira la credencial. El arquitecto-datos confirma si la base del nodo tiene costos que mostrar |
| **K-04** | ADR-53, cláusula 6: cada sitio valida solo los tokens con `iss` y `aud` iguales a su identidad. `[PRO]` 2.3 pide `rep` en `aud`. No es aceptación cruzada (mismo sitio), pero el texto debe decirlo | `ADR-041.md` (precisión de ADR-53); `[PRO]`:101 | Baja | ADR-80, punto 2: mismo `iss` que la API de la central; `aud` incluye `rep`; ningún token de un nodo se acepta en el proceso de la central |
| **K-05** | ADR-73.7 (los complementos no tocan el núcleo; «el núcleo inicia toda llamada»). Power BI, el contador y el servidor MCP **llaman** a GPOS NG. No son complementos de 73.7, sino clientes autenticados de una API del núcleo. Si no se dice, alguien puede leer el MCP como un conector y exigirle el protocolo de conectores | `ADR-073.md`, 73.7.2; `[PRO]` 6 | Baja | ADR-80, punto 6 y P-2: los clientes externos y el MCP no son complementos de 73.7; nunca leen la base. Además, la **exportación simple de auxiliares** de la ola 5 (73.6) usa `IEjecutorConsultas` (ADR-77, punto 1) |
| **K-06** | La corrección de la ola 4 (pistas, 30 s, `LOCK_TIMEOUT`) **no está todavía en el árbol** a la hora de leerlo: `ReportesService.cs` no figura entre los archivos modificados y conserva `CommandTimeout = 120` y la transacción. No es una contradicción: es trabajo en curso | `ReportesService.cs:27`, :359, :365 (`bd7eb27`, `git status`) | Baja (seguimiento) | ADR-78 los da por corregidos en la ola 4. Si no entran, vuelven a R5-4 de la ola 5 y su prueba de regresión sigue siendo criterio de salida |
| **K-07** | El rol `gpos_app` no tiene `SELECT` sobre `rpt`, y el dominio lee `rpt.Conciliacion*`. Al cerrar RG-14, CxC, CxP, existencia y cierre de período fallarían con el error 229. Si alguna lectura del dominio usa una vista `…Costos`, también necesitará `rptc` | `SqlMigraciones.cs:29-47` (verificado: sin `GRANT … rpt TO gpos_app`); `[PRO]` H-RPT-02 | Media (latente) | No requiere firma. R5-8 de la ola 5, ampliado a `rptc` si hace falta (arquitecto-datos) |
| **K-08** | ADR-77 pone `DENY` sobre el esquema `ext` de AN-02. **No consta que AN-02 esté firmada** (sí AN-01). Su plazo también es el 2026-11-16 | `[ANL-D]`:143 y :171; búsqueda de «AN-02» sin firma registrada | Media (calendario) | Firmar AN-02 en la misma sesión. Si no se firma, la migración crea el `DENY` solo para los esquemas que existan, y la prueba de permisos sigue con denegación por omisión |
| **K-09** | Clave de Power BI en texto plano. Si la clave va en un encabezado escrito dentro de la consulta de Power Query, queda legible en el archivo `.pbix` o en el libro de Excel del cliente. Choca con la regla del propietario de no dejar secretos en texto plano | `[PRO]`:102; memoria «sin texto plano». Inferido: depende de cómo guarde la herramienta la credencial | Media (para F3, no ahora) | ADR-80, punto 4: la clave debe poder guardarse en el **almacén de credenciales de la herramienta** (por ejemplo, Basic con `<id>` como usuario y el secreto como contraseña, sobre HTTPS), nunca escrita en la consulta. El arquitecto-integraciones lo verifica con Power BI y Excel antes de F3 |
| **K-10** | Con **solo VPN** (PR-2), Power BI Desktop funciona dentro de la VPN, pero la **actualización programada en el servicio de Power BI** necesita un *gateway* de datos local instalado en la red del cliente | Inferido del funcionamiento de Power BI | Baja (informativa) | PR-2 lo menciona. El *gateway* no tiene costo de licencia (inferido); la licencia de Power BI la paga el cliente |
| **K-11** | ADR-55 (propuesto), punto 4, pone la carga del análisis en la API de la central; P-2 permite moverla al proceso de reportes. Punto 6: el MCP usa «la identidad del usuario»; P-2 usa una clave personal ligada al usuario. Son compatibles | `[ANL-D]`:291 y :293 | Baja | Como ADR-55 sigue sin firmar, P-2 se incorpora a su texto al firmar AN-03 a AN-17, sin un ADR aparte |
| **K-12** | ADR-40 R1 pide un «catálogo por lista blanca de tablas y columnas» y `DEFAULT_SCHEMA = rpt`. ADR-77 lo cumple con el esquema `rpt` como lista blanca y `DENY` por esquema. Conviene decirlo para que nadie construya una segunda lista | `ADR-040.md:47` | Baja | ADR-77, punto 2 |
| **K-13** | Números. ADR-74, 75 y 76 están firmados (`[DEC]`:68), pero el índice de `master` aún dice «75 a 99 libres». No hay archivos ni usos de ADR-77 a 80 | `README.md:99-100`; listado de `docs/adr` | Baja | El documentador registra primero 74 a 76 y después 77 a 80 |
| **K-14** | **ES256 no tiene fecha.** `[PRO]` pone F2 «después del corte; requiere ES256», pero ADR-41 entra con la versión 1 del acceso multiempresa, que no está planificada (K-63 y R-H0-C del cierre de H0). En la práctica, F2, F3 y F4 esperan a esa versión, no solo al corte | `GPOS NG\docs\decisiones\2026-10-04-cierre-h0.md`:97 y :333; `ADR-041.md` (estado: no implementado) | Media (calendario comercial de Power BI y del MCP) | ADR-80, punto 8, ya lo pone como condición. Si el propietario quiere el canal externo antes, la única vía es adelantar ES256 (parte de la versión 1); se decide al ordenar esa versión, no en esta hoja |

**No hay otra contradicción** con un ADR vigente. ADR-77 y ADR-79 desarrollan ADR-38 M-2 y ADR-40 R1 sin cambiarlos. ADR-78 precisa M-2 (K-01). ADR-80 precisa ADR-40 (reabre R2 por un motivo nuevo) y ADR-24 (un servicio más). P-1 precisa PR-ADR38.

---

## 3. Hoja de firma

Columnas:
- **Modifica:** qué decisión firmada cambia o precisa la fila.
- **Reversible:** hoy todo lo es (nada construido, sin clientes; `bp2-nunca-en-produccion`). Se anota lo que deja de serlo.
- **Recomendación** del Maestro. La decisión es del propietario.

| # | Qué se firma | Modifica | Reversible | Recomendación | Firma |
|---|---|---|---|---|---|
| **FR-77** | **Texto de ADR-77** (3.1) | Ninguno. Desarrolla ADR-38 M-2 y ADR-40 R1 | Sí | **Aprobar** | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |
| **FR-P1** | **Texto de P-1** (3.2), precisión de PR-ADR38 | **Precisa PR-ADR38** (ADR-38) y aplica ADR-12 / DA-02 | Sí | **Aprobar** (con PR-4) | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |
| **FR-78** | **Texto de ADR-78** (3.3) | **Precisa ADR-38 M-2** (120 s solo para programados fuera de horario; K-01) | Sí. Los valores los ajusta QA sin firma nueva | **Aprobar** | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |
| **FR-79** | **Texto de ADR-79** (3.4) | Ninguno | Sí. La bitácora, una vez en uso, se conserva 13 meses | **Aprobar** | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |
| **FR-80** | **Texto de ADR-80** (3.5): (a) proceso aparte para lo externo y el MCP; (b) pantallas en el proceso; (c) claves con alcance | **Precisa ADR-40** (R2) y **ADR-24** | Sí, hasta entregar la primera clave a un tercero. Después, retirar el canal externo rompe sus informes | **(a) y (c) Aprobar; (b) No por ahora** | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |
| **FR-P2** | **Texto de P-2** (3.6), en principio | Precisa [ANL] 7.9 y AN-05 / ADR-55 (propuestos) | Sí | **Aprobar en principio** | [ ] Firmo como se recomienda · [ ] Firmo con cambios: ______ · [ ] Rechazo |

### 3.1 Texto propuesto de ADR-77

> [Índice de ADR](README.md)
>
> # ADR-77 · Aislamiento de lectura de los reportes en el motor de base de datos
>
> **Estado:** Propuesto · **Fecha:** 2026-10-07 · **Equipo:** A · **Desarrolla:** [ADR-38](ADR-038.md) M-1 y M-2, [ADR-40](ADR-040.md) R1 (P-05 y P-06.1) · **Precisado por:** P-1 (esquema `rptc`) · **Relacionado:** [ADR-12](ADR-012.md) (DA-02), [ADR-44](ADR-044.md), [ADR-53](ADR-053.md), [ADR-73](ADR-073.md) (73.6), ADR-78, ADR-79, ADR-80 · **Fuente:** `propuesta-api-reportes-solo-lectura-2026-10-07.md` (arquitecto-software), secciones 2.4, 2.6, 2.7 y 7.1
>
> **Contexto.** El motor de reportes ejecuta SQL escrito por el ADMIN con la conexión de la empresa de la aplicación, dentro de una transacción que se revierte; la «solo lectura» depende de una expresión regular (`ReportesService.cs:27`, :356-366). Una lista negra no impide leer cualquier tabla de la empresa ni tomar bloqueos. ADR-38 M-2 y ADR-40 R1 ya exigen una credencial de reportes y una única interfaz de ejecución; ninguna de las dos existe en el código. El rol `gpos_reportes` existe sin miembros (`SqlMigraciones.cs:24-49`).
>
> **Decisión.**
> 1. **Única puerta de lectura.** Todo SQL de reportes se ejecuta por `IEjecutorConsultas`: los reportes del sistema y a medida, el diseñador (detectar y vista previa), el tablero y sus KPI, el *drill-down*, la consulta de facturas, los reportes programados y la exportación simple de auxiliares de ADR-73 (73.6). La conciliación del ADMIN y las lecturas del dominio sobre `rpt.Conciliacion*` **no** son reportes y siguen con la credencial de la aplicación.
> 2. **Credencial por empresa.** `gpos_rpt_<EMP>`, miembro de `gpos_reportes`, usuario contenido de su base (o login con usuario solo en esa base, si devops no habilita la autenticación contenida). Permisos: `GRANT SELECT ON SCHEMA::rpt`; `DENY SELECT` sobre **cada** esquema base, incluidos `ext` y `rptc`; `DENY` de escritura, ejecución, alteración, control y `VIEW DEFINITION` sobre la base; miembro de `db_denydatawriter`; **no** miembro de `db_denydatareader`. El esquema `rpt` es la lista blanca de tablas y columnas de ADR-40 R1; no hay una segunda lista.
> 3. **Lo impone el motor.** `rpt` y `rptc` pertenecen a `dbo`, como las tablas; sus vistas no usan SQL dinámico ni otras bases (encadenamiento de propiedad). Una prueba de permisos efectivos en la integración continua falla si aparece un esquema sin `DENY` explícito o si una vista cambia de dueño. La credencial no existe en `GPOS_SYSDATA` ni en otra empresa; `guest` revocado; P-06.1 comprobado por `GPOS.Migracion`.
> 4. **Sin respaldo.** Si la credencial no está configurada o falla: **503 `CREDENCIAL_REPORTES_NO_DISPONIBLE`**. Nunca se vuelve a la conexión principal.
> 5. **Biblioteca `GPOS.Reportes`** con frontera estricta: catálogo, validación, armado de la consulta, `IEjecutorConsultas`, límites, exportación y bitácora. No puede referenciar `EmpresaDbContext`, `EmpresaNgDbContext`, `IEmpresaDbFactory` ni ninguna conexión de escritura; lo vigila una prueba de arquitectura. En la ola 5 se hospeda dentro de `GPOS.Api`.
> 6. **Credenciales.** Generadas por `GPOS.Migracion`, cifradas (ADR-44), nunca en `appsettings` ni en texto plano.
> 7. **Nodos de sucursal (ADR-53).** El nodo ejecuta sus reportes locales con su propio `gpos_rpt_<EMP>` en su base.
>
> **Alternativas descartadas.**
> - La expresión regular y la transacción revertida (lo de hoy): no impide leer el resto de la base ni bloquear.
> - `db_denydatareader`: deniega también las vistas `rpt`.
> - Una credencial con lectura de todas las tablas: no aísla.
> - Activarlo todo de una vez: si la reescritura de los 27 reportes se atrasa, la ola 5 no podría imponerlo. Se activa reporte por reporte, con una lista de excepciones que debe quedar **vacía en el corte**.
>
> **Qué rompe y a quién afecta.** Un reporte a medida que lea tablas fuera de `rpt` deja de funcionar y el diseñador lo dice («La consulta lee fuera de `rpt`»). No hay clientes en producción (BP2 nunca salió). Los 27 reportes del sistema se reescriben sobre `rpt` en la ola 5 (ya planificado).
>
> **Consecuencias.**
> - Esfuerzo (inferido): dentro de la ola 5 ya planificada (2,5 sp) más 0,25 sp (biblioteca, `DENY` por esquema, prueba de permisos).
> - **Criterios de salida de la ola 5:** ninguna ejecución de reporte, tablero, consulta de facturas, vista previa o programado abre la conexión principal (prueba con un interceptor que falla); `gpos_rpt_<EMP>` no lee fuera de `rpt` ni escribe; la lista de excepciones está vacía.
> - El rol `gpos_app` recibe `SELECT` sobre `rpt` (y sobre `rptc` si el dominio lo necesita) para sus lecturas de conciliación, dentro de RG-14.
> - No protege frente a un compromiso del proceso de la API, que sigue teniendo las demás credenciales (ADR-38, consecuencias). Eso lo reduce ADR-80 para el tráfico externo.
>
> **Estado de implementación:** decidido, no implementado (pendiente de la firma del texto).

### 3.2 Texto propuesto de P-1 (precisión de PR-ADR38, en ADR-38)

> **Precisión del 2026-10-07 (P-1, hoja de firma de la API de reportes).** Donde PR-ADR38 dice «las vistas `rpt` con costos (`…Costos`) no se conceden al usuario SQL de solo lectura de reportes; solo las lee la API», se lee:
> 1. Las vistas con costos viven en un esquema propio, **`rptc`**, con dueño `dbo`. `rpt.HistorialTransferenciaCostos` se mueve allí, y toda vista futura con costos se crea allí.
> 2. «Solo las lee la API» significa: **la API, con la credencial `gpos_rptc_<EMP>`** (rol `gpos_reportes_costo` = lo de `gpos_reportes` + `SELECT ON SCHEMA::rptc`), y solo cuando ya evaluó el **privilegio efectivo** de costos de DA-02. **Nunca** con la conexión principal.
> 3. `gpos_rpt_<EMP>` tiene `DENY SELECT ON SCHEMA::rptc`. Si un reporte a medida lee `rptc` y quien lo ejecuta no tiene el privilegio efectivo, el motor lo rechaza y la API lo traduce como «Este reporte usa datos de costo».
> 4. `gpos_rptc_<EMP>` se crea en la base de la central. En un **nodo** se crea solo si la empresa tiene `CostosSoloEnCentral` **apagado**; al encenderlo, `GPOS.Migracion` la retira (PR-4).
>
> *Alternativas descartadas:* dejar las vistas en `rpt` con `DENY` vista por vista (una vista nueva sin `DENY` filtra costos); leerlas con la conexión principal (rompe el aislamiento de ADR-77). **Decidido, no implementado:** ola 5.

### 3.3 Texto propuesto de ADR-78

> [Índice de ADR](README.md)
>
> # ADR-78 · Protección de la operación frente a los reportes
>
> **Estado:** Propuesto · **Fecha:** 2026-10-07 · **Equipo:** A · **Precisa:** [ADR-38](ADR-038.md) M-2 (tiempo máximo de los programados) · **Relacionado:** ADR-45, ADR-72, ADR-77, ADR-79 · **Fuente:** `propuesta-api-reportes-solo-lectura-2026-10-07.md`, secciones 4.1 a 4.5
>
> **Contexto.** SQL Server Express (4 núcleos, 1.410 MB de memoria intermedia, sin Resource Governor) es el motor de la mayoría de las centrales. Un reporte compite con el POS por la CPU, la memoria y `tempdb`, aunque solo lea; con pistas de bloqueo, además, lo detiene. La única palanca es lo que el ejecutor envía en cada consulta. La QA de la ola 4 midió la CPU al 89 %.
>
> **Decisión.**
> 1. **Ya corregido en la ola 4** (sin firma nueva): prohibición de pistas de tabla, `OPTION`, `NOLOCK`, `READPAST`, `INDEX(`, `FORCESEEK`, `TABLESAMPLE`, `FOR XML`, `FOR JSON` y `OPENJSON` (el `WITH` de una CTE al principio sigue permitido); tiempo máximo de 30 s (ADR-38 M-2); `SET LOCK_TIMEOUT` enviado por el ejecutor (409 `REPORTE_BLOQUEADO`).
> 2. **Precisión de ADR-38 M-2.** El tiempo máximo es de **30 s** para todo SQL del cliente, incluidas las exportaciones desde la pantalla. **Única excepción:** los reportes programados pueden llegar a **120 s** si corren fuera del horario de caja que configure la empresa, de a uno por empresa. Ningún otro canal admite más de 30 s.
> 3. **Lectura sin transacción explícita** (*autocommit*): cada bloqueo termina con la sentencia.
> 4. **Paralelismo, memoria y costo:** el envoltorio agrega `OPTION (MAXDOP 2, MAX_GRANT_PERCENT = 10)` y la sesión fija `QUERY_GOVERNOR_COST_LIMIT`; un plan que supera el costo se rechaza antes de ejecutarse.
> 5. **Tamaño:** páginas de hasta 1.000 filas en pantalla; exportación CSV hasta 200.000, XLSX hasta 100.000 y PDF hasta 10.000 filas; 50 MB por respuesta y 200 MB por exportación (413 `REPORTE_DEMASIADO_GRANDE`).
> 6. **Concurrencia:** por empresa, 2 consultas a la vez en Express y 4 en Standard; por usuario o clave, 1. Quien espera recibe 429 `REPORTE_EN_CURSO` con `Retry-After`, sin cola larga. Se mantiene el límite de frecuencia actual (30 por minuto y usuario).
> 7. **Totales, paginación y exportación:** totales globales en el servidor con una consulta de agregación aparte y los mismos límites; paginación con `OFFSET … FETCH` y `HayMas`, sin `COUNT(*)` salvo que se pida; CSV y XLSX en *streaming*, fila por fila; conversión de moneda en la consulta con la tasa de `rpt.Tasa`.
> 8. **Caché** en memoria por huella (empresa, reporte, versión, filtros, columnas, costos, sensibles y página): 60 s en el tablero y los KPI; 0 en los reportes, salvo períodos cerrados (5 min). Nunca entre empresas. Sin caché distribuida.
> 9. **Cancelación:** si el usuario abandona la petición, el ejecutor cancela el comando en el motor.
> 10. **Valores:** los de los puntos 4 a 8 son iniciales; QA los ajusta con B9 y T-28 sin firma nueva. El de los puntos 1 y 2 (tiempos) solo cambia con firma.
>
> **Alternativas descartadas.**
> - Resource Governor: no existe en Express.
> - Solo el límite de frecuencia de hoy: no limita la concurrencia ni el bloqueo.
> - Una segunda instancia o copia de lectura por omisión: operación sin necesidad medida. Queda como opción (copia `STANDBY` con los respaldos de registro de Backup Tool) cuando QA mida una degradación del POS en una central grande.
> - 120 s también en las exportaciones desde la pantalla (`[PRO]` 4.2): una exportación de 120 s en horario de caja es justo el caso que hay que evitar.
> - Totales en el cliente o con `SUM() OVER()`: incorrectos con paginación o más caros en `tempdb`.
>
> **Qué rompe y a quién afecta.** Un reporte legítimo de una central grande que tarde más de 30 s deja de verse en pantalla: se programa fuera de horario, se resuelve con la estrella del módulo de análisis o, si QA lo justifica, con la copia de lectura. Los cajeros no notan nada.
>
> **Consecuencias.**
> - Esfuerzo (inferido): 0,35 sp en la ola 5 (ejecutor, concurrencia y cancelación, *streaming*), más lo ya planificado (paginación y totales).
> - **Criterio de salida de la ola 5:** un reporte de 25 s en paralelo con T-28 no sube el p95 de la venta más de un 10 %; un reporte con `TABLOCKX` se rechaza.
> - La bitácora de ADR-79 permite encontrar los reportes caros.
>
> **Estado de implementación:** puntos 1 y 2 (30 s), en la corrección de la ola 4; el resto, decidido, no implementado.

### 3.4 Texto propuesto de ADR-79

> [Índice de ADR](README.md)
>
> # ADR-79 · Escrituras de los reportes fuera del login de solo lectura
>
> **Estado:** Propuesto · **Fecha:** 2026-10-07 · **Equipo:** A · **Relacionado:** ADR-34, ADR-35, ADR-77, ADR-78, ADR-80 · **Fuente:** `propuesta-api-reportes-solo-lectura-2026-10-07.md`, sección 3
>
> **Contexto.** Para que `gpos_rpt_<EMP>` sea de solo lectura de verdad, nada de lo que los reportes escriben puede ir con esa credencial ni a la base de la empresa.
>
> **Decisión.**
> 1. **Definiciones de reportes** (diseñador): `GPOS_SYSDATA`, desde `GPOS.Api`, con la identidad de sistema. Solo la ejecución de prueba usa `gpos_rpt`.
> 2. **Preferencias por usuario** (columnas, orden, filtros guardados): `GPOS_SYSDATA`, `rep.PreferenciaUsuario`, por usuario, empresa y reporte; se escriben desde `GPOS.Api` (`GET/PUT /api/reportes/{id}/preferencias`).
> 3. **Bitácora de ejecución y exportación:** `GPOS_SYSDATA`, `rep.Ejecucion`, **solo inserción**: quién (usuario o clave), empresa, sitio, reporte, **huella** de los filtros (nunca su texto), columnas, formato, canal (`UI`, `Programado`, `Clave`, `MCP`), filas, bytes, duración, resultado y código de error. Escritura asíncrona con cola acotada: si la cola se llena, **la exportación se rechaza** y la ejecución en pantalla sigue con una advertencia. Retención de 13 meses; la purga la hace el comando de mantenimiento, no la API.
> 4. **`_LOG` de la empresa sin cambios:** sigue siendo de los documentos. La auditoría de lectura es `rep.Ejecucion`.
> 5. **Claves externas** (cuando existan, ADR-80): `GPOS_SYSDATA`, `rep.ClaveAcceso`; se crean y revocan en `GPOS.Api`. El proceso de reportes solo marca el «último uso» con un procedimiento que actualiza esa columna, como mucho una vez por minuto.
> 6. «Solo inserción» se declara cuando RG-14 y PUB-06 estén aplicados; hasta entonces es defensa en profundidad.
>
> **Alternativas descartadas.**
> - Un procedimiento de bitácora en la base de la empresa con `EXECUTE` para `gpos_rpt`: rompe la solo lectura, mete auditoría de lectura en los respaldos de 15 minutos y en el libro fiscal, y obliga a una excepción en la prueba de permisos.
> - Bitácora solo en archivos de registro: el ADMIN no la puede consultar.
>
> **Qué rompe y a quién afecta.** Nada visible. El ADMIN gana una consulta de quién ejecutó o exportó qué.
>
> **Consecuencias.** Esfuerzo (inferido): 0,1 sp en la ola 5 (bitácora); las preferencias ya estaban planificadas. Si la ola 5 se aprieta, la bitácora pasa a F2 (−0,1 sp) sin cambiar el texto. Volumen (inferido): unos 200 B por ejecución; con 2.000 ejecuciones diarias por empresa, unos 145 MB en 13 meses.
>
> **Estado de implementación:** decidido, no implementado (pendiente de la firma del texto).

### 3.5 Texto propuesto de ADR-80

> [Índice de ADR](README.md)
>
> # ADR-80 · Proceso `GPOS.Api.Reportes` y exposición externa de los reportes
>
> **Estado:** Propuesto · **Fecha:** 2026-10-07 · **Equipo:** A · **Precisa:** [ADR-40](ADR-040.md) (reabre R2, «reportes en un proceso aparte», por un motivo nuevo) y [ADR-24](ADR-024.md) (un servicio más en la central; acceso externo por VPN) · **Depende de:** [ADR-41](ADR-041.md) (ES256, con la precisión de ADR-53, cláusula 6), H-17 v2 (`CifradorAnillo`), versión 1 del acceso multiempresa (SA-01) · **Relacionado:** ADR-33, ADR-34, ADR-58, ADR-63, ADR-73 (73.7), ADR-76 (PA-76-1), ADR-77, ADR-78, ADR-79 · **Fuente:** `propuesta-api-reportes-solo-lectura-2026-10-07.md`, secciones 2.2, 2.3, 5 y 7.2
>
> **Contexto.** ADR-40 descartó R2 porque «no agrega seguridad y exige un almacén de secretos propio». Aparecieron dos motivos que ADR-40 no contemplaba: herramientas de terceros (Power BI, Excel, el sistema del contador) y el futuro servidor MCP de IA. Exponer la API del POS a ese tráfico aumenta su superficie. Con HS256, un proceso aparte que valida tokens podría también emitirlos; con ES256 solo recibe la llave pública. El aislamiento de los datos ya lo da el motor (ADR-77); el proceso aparte reduce el radio de daño de lo expuesto y aleja de la API del POS las exportaciones de terceros.
>
> **Decisión.**
> 1. **(a) Proceso aparte, solo en la central** (rol `Central` o `Ambos`), que hospeda `GPOS.Reportes` para las claves externas y el MCP. En un nodo, `/api/reportes/externo/*` responde 503 `REQUIERE_CENTRAL`. Se construye después del corte del 2026-12-02.
> 2. **Autenticación de usuarios:** el mismo JWT de GPOS, validado **solo con la llave pública ES256**, el mismo `iss` que la API de la central y `rep` en `aud`. Ningún token emitido por un nodo se acepta (ADR-53, cláusula 6). **No se habilita con HS256.**
> 3. **Secretos propios.** El proceso tiene **su propio anillo de llaves** (`CifradorAnillo` de H-17 v2, carpeta y ACL propias). `GPOS.Migracion` le entrega solo las cadenas `gpos_rpt_<EMP>`, `gpos_rptc_<EMP>` y `gpos_rptsys`, cifradas para ese anillo. No tiene la llave privada del JWT, ni las credenciales `gpos_app_<EMP>`, ni el anillo de la API principal. Un propósito de Data Protection distinto **no** basta.
> 4. **(c) Claves con alcance; nunca un login SQL para terceros.**
>    - **Clave de empresa** (Power BI, Excel, contador) y **clave personal** (MCP, ligada a un usuario: sus permisos son la intersección entre los del usuario en esa empresa y el alcance de la clave; se revoca al inhabilitar al usuario o su membresía).
>    - Secreto de 256 bits mostrado una sola vez; se guarda solo su huella SHA-256 con sal.
>    - Alcance: empresa (sale de la clave, nunca de un parámetro), lista de reportes por código estable, costos (sí o no; solo en la central y solo si quien la emite tiene el privilegio efectivo), datos sensibles (sí o no), vigencia de hasta 12 meses, redes permitidas y cuota diaria. Costos y sensibles, **fuera por omisión**.
>    - La emite el ADMIN de esa empresa (privilegio `rptclaves`) o el SUPER con motivo.
>    - La herramienta del cliente guarda la clave en su almacén de credenciales; la guía de implantación nunca la escribe dentro de una consulta.
> 5. **Exposición:** puerto propio detrás de IIS con HTTPS. Desde fuera de la red del cliente, **solo por VPN** (ADR-24) o con el *gateway* local de Power BI (PR-2). Cuenta virtual `NT SERVICE\GPOS.Api.Reportes` con `RequiredPrivilege` mínimo (ADR-76, PA-76-1), binario firmado (ADR-33) y declarado en el manifiesto (ADR-63).
> 6. **Clientes, no complementos.** Las herramientas externas y el servidor MCP son clientes autenticados de esta API: no son complementos de ADR-73.7 y nunca leen la base.
> 7. **(b) Pantallas de Web y MAUI:** siguen en `GPOS.Api`. Se reabre si QA mide que los reportes en la API principal afectan al POS; el contrato `/api/reportes/*` no cambia en ningún caso.
> 8. **Condiciones de publicación:** ES256 implementado; anillo propio; y, en una instalación con más de una empresa habilitada, la versión 1 del acceso multiempresa (SA-01): hoy el permiso se guarda en caché por usuario y no por membresía.
> 9. **MCP:** activación expresa por empresa (SUPER o ADMIN, con aviso de que los datos salen hacia un proveedor de IA); como máximo 500 filas por llamada; sin costos ni sensibles salvo un alcance explícito firmado; canal `MCP` en la bitácora. El privilegio `rptia` queda reservado.
>
> **Alternativas descartadas.**
> - Todo dentro de la API principal, también lo externo: la API del POS queda expuesta a Power BI y a la IA.
> - Proceso aparte ya en la ola 5: con HS256 tendría la clave de firma y podría emitir tokens; 1 sp más arriesgaría el corte.
> - Proceso aparte con el anillo de la API y un propósito propio: el anillo descifra todos los propósitos; no reduce el radio de daño.
> - OAuth `client_credentials`: exige un servidor de autorización. Se reconsidera si un ERP lo pide.
> - Login SQL de solo lectura para Power BI: salta permisos, límites y bitácora, y la consulta directa cargaría la base del POS.
> - Mover también las pantallas al proceso ya: sin una medición que lo pida, agrega una URL y un servicio más para MAUI y la Web.
>
> **Qué rompe y a quién afecta.** Nada para los usuarios de las pantallas. La central opera un servicio más. El ADMIN administra claves. El contador recibe una clave limitada a los reportes fiscales (606, 607, 608, 609), sin costos ni sensibles, con vigencia de 3 a 12 meses.
>
> **Consecuencias.**
> - Esfuerzo (inferido): F2 (proceso, ES256, anillo propio, reenvío desde la Web) de 1,1 a 1,2 sp (de 0,9 a 1,7); F3 (claves, `externo/v1`, guía de Power BI y Excel, alertas) 1,0 sp (de 0,7 a 1,4); F4 (MCP) de 0,8 a 1,2 sp, en la etapa que elija el propietario. Infraestructura USD 0. La licencia de Power BI la paga el cliente.
> - Memoria adicional en la central: del orden de 100 a 200 MB para el proceso (inferido).
> - ADR-24: la central agrega un servicio y una regla de cortafuegos interna.
>
> **Estado de implementación:** decidido, no implementado (pendiente de la firma del texto). Se construye después del corte.

### 3.6 Texto propuesto de P-2 (en principio; se incorpora a ADR-55 y ADR-56 al firmar AN-03 a AN-17)

> **P-2 · El módulo de análisis y el MCP son clientes de la API de reportes.**
> 1. `GPOS.Api.Reportes` es la superficie de lectura de la central: `rpt` por omisión y, con el módulo de análisis activo, las rutas `/api/analisis/*` del explorador, con sus credenciales propias sobre `GPOS_<EMP>_ANALISIS`. Comparten el autorizador, los límites, la bitácora, las claves, la exportación en *streaming* y la caché. **La frontera de ADR-55 a 57 no cambia:** los permisos `anl:*` no heredan de `rpt:<id>` ni al revés.
> 2. La carga del análisis (`TrabajoCargaAnalitica`, con `gpos_ext_<EMP>` sobre `ext`) **puede** vivir en ese proceso en lugar de la API de la central (ADR-55, punto 4); se decide al construir el módulo.
> 3. El MCP consume las rutas con la clave personal del usuario (ADR-80, punto 4), que es «la identidad del usuario» de ADR-55, punto 6. Nunca entra a la base.
>
> *Alternativa descartada:* una API propia para el análisis o para el MCP (tres superficies que autenticar, limitar y auditar en lugar de una).

---

## 4. Preguntas abiertas (una casilla por pregunta)

| # | Pregunta | Recomendación | Alternativa descartada | Firma |
|---|---|---|---|---|
| **PR-1** | ¿Las claves de empresa (Power BI, contador) **ocupan un cupo** de la licencia por usuarios (ADR-34, ADR-58)? | **No.** Se fija un **tope de claves de empresa activas** por empresa en la licencia (por omisión 3), dentro de la cláusula de módulos contratados de ADR-58 que ya está por preparar (B-5 de ADR-73). Así el canal externo se puede vender o incluir sin tocar el código. La clave personal (MCP) va ligada a un usuario que ya ocupa su cupo. Costo 0 sp adicional (entra en la precisión de ADR-58) | Que cada clave ocupe un cupo: más simple de explicar, pero el cliente paga un «usuario» por una hoja de Excel y nadie controla cuántas claves hay | [ ] Sí, como se recomienda · [ ] No: cada clave ocupa un cupo · [ ] Otro: ______ |
| **PR-2** | ¿El acceso externo es **solo por VPN** (ADR-24) o se publica `GPOS.Api.Reportes` en internet detrás de un WAF? | **Solo VPN** hasta la versión en la nube. Power BI Desktop funciona dentro de la VPN; la actualización programada del servicio de Power BI usa el *gateway* de datos local en la red del cliente (K-10), sin abrir puertos | Publicar en internet con WAF: un WAF cuesta del orden de USD 20 a 50 al mes por instalación (inferido) y abre la central a internet, lo que ADR-24 prohíbe para la API | [ ] Sí, solo VPN · [ ] No: publicar con WAF |
| **PR-3** | ¿Se acepta el privilegio nuevo **`rptexportar`** (grupo Reportes), concedido por omisión a quien hoy tiene acceso a reportes? | **Sí.** Nadie pierde la exportación con la actualización; el ADMIN puede quitarla a quien solo deba consultar. Con la licencia vencida, exportar la historia sigue permitido (solo consulta, ADR-59). Se registra como precisión de ADR-11, junto con `rptclaves` y `rptia` (reservado) | Exportar ligado al permiso de ver el reporte (lo de hoy): no permite separar consultar de sacar los datos del sistema | [ ] Sí, como se recomienda · [ ] No |
| **PR-4** (K-03) | En un **nodo**, ¿`rptc` y `gpos_rptc_<EMP>` existen solo si la empresa tiene `CostosSoloEnCentral` **apagado**? | **Sí.** Respeta DA-02 tal como está firmado: con el parámetro apagado, quien tiene Ver costos los ve en su sucursal. Al encenderlo, `GPOS.Migracion` retira la credencial del nodo. Costo ≈ 0,02 sp | Nunca en los nodos (`[PRO]`): con el parámetro apagado, los reportes de costo del nodo dejarían de funcionar, contra ADR-12 | [ ] Sí, como se recomienda · [ ] No: nunca en los nodos |

---

## 5. Qué debe firmarse antes del 2026-11-16 y qué puede esperar

| Plazo | Puntos | Por qué |
|---|---|---|
| **Antes del 2026-11-16** (inicio de la ola 5) | **FR-77, FR-P1, FR-78, FR-79, PR-3 y PR-4.** Además, **AN-02** de la hoja del módulo de análisis (K-08) | La ola 5 construye la credencial, los `DENY`, `rptc`, los límites, la bitácora y la exportación en *streaming*. Sin firma, el backend construiría contra ADR-38 M-2 (K-01) o tendría que adivinar |
| Antes de abrir F2 (después del 2026-12-02) | **FR-80** | Nada de la ola 5 depende de él. Firmarlo hoy fija la dirección y evita que la ola 5 deje acoplado `GPOS.Reportes` a la API |
| Con la precisión de ADR-58 (cláusula de módulos contratados) | **PR-1** | El tope de claves vive en la licencia |
| Antes de F3 | **PR-2** | Solo afecta a la exposición externa |
| Con AN-03 a AN-17 | **FR-P2** | Se incorpora al texto de ADR-55 y ADR-56 |

---

## 6. Costo: ola 5 frente a después del corte

| Fase | Contenido | sp (rango) | USD (inferido) | Cuándo |
|---|---|---|---|---|
| Ola 4 (ya en curso) | Pistas y `OPTION` prohibidos, 30 s, `LOCK_TIMEOUT` | ≈ 0,05 (sale de R5-4) | ≈ 75 a 100 | Corrección de la ola 4 |
| **Ola 5, agregado** | Biblioteca y prueba de arquitectura (0,10); `DENY` por esquema, `rptc` y prueba de permisos (0,15); resto del endurecimiento (0,10); concurrencia y cancelación (0,10); *streaming* (0,10); bitácora (0,10); `gpos_app` sobre `rpt` (0,02); PR-4 (0,02) | **≈ 0,8** (de 0,5 a 1,1) | **1.200 a 1.600** (750 a 2.200) | 2026-11-16 a 11-24; ≈ 1 día de calendario; la holgura hasta el corte es del 25-nov al 2-dic |
| F2 · Proceso aparte | Servicio, ES256, **anillo propio (K-02, +0,1 a 0,2)**, `gpos_rptsys`, reenvío, salud, manifiesto | 1,1 a 1,2 (de 0,9 a 1,7) | 1.650 a 2.400 | Tras el corte; requiere ES256, que llega con la versión 1 del acceso multiempresa (K-14) |
| F3 · Claves externas | `rep.ClaveAcceso`, administración, `externo/v1`, guía de Power BI y Excel, alertas | 1,0 (de 0,7 a 1,4) | 1.500 a 2.000 | Tras F2 y la versión 1 del acceso multiempresa (o instalación con una empresa) |
| F4 · MCP | Servidor MCP como cliente, clave personal, activación por empresa | 0,8 a 1,2 | 1.200 a 2.400 | Tras la entrega 1, en la etapa que elija el propietario |
| **Total después del corte** | F2 + F3 + F4 | **3,4 a 3,5** (de 2,6 a 5,1) | **5.100 a 7.000** | — |
| F5 · Copia de lectura (opcional) | `STANDBY` con Backup Tool, fuente por reporte | 0,5 a 0,8 + equipo si va en otro servidor | 750 a 1.600 + equipo | Solo si QA mide degradación |

**Opción más barata en la ola 5:** pasar la concurrencia (R5-5) y la bitácora (R5-7) a F2: −0,2 sp. **No la recomiendo para R5-5**, porque el límite de concurrencia es lo que impide que dos ADMIN con reportes pesados frenen el POS en Express. La bitácora sí puede esperar sin riesgo para la operación.

---

## 7. Relación con los ADR citados

| ADR | ADR-77 | P-1 | ADR-78 | ADR-79 | ADR-80 | P-2 |
|---|---|---|---|---|---|---|
| **38** (M-1, M-2, PR-ADR38) | Cumple M-1 y M-2 | **Precisa PR-ADR38** | **Precisa M-2** (K-01) | Cumple M-2 (sin escritura) | — | — |
| **40** (R1, R2, P-05, P-06.1) | Implementa R1; el esquema `rpt` es la lista blanca (K-12) | — | — | — | **Precisa: reabre R2** con un motivo nuevo y responde a sus dos argumentos (ES256 y anillo propio, K-02) | — |
| **24** (despliegue) | — | — | — | — | **Precisa:** un servicio más; acceso externo por VPN (PR-2) | — |
| **41 / 53 cl. 6** (ES256) | — | — | — | — | Depende de ES256; mismo `iss`, `rep` en `aud`, sin tokens de nodos (K-04) | — |
| **12 / DA-02** (costos) | — | Privilegio efectivo antes de usar `rptc`; nodos según el parámetro (PR-4) | — | — | Costos fuera por omisión en las claves | `anlcostos` sigue aparte |
| **55 a 57** (propuestos) | `DENY` sobre `ext` (AN-02, K-08) | — | — | — | — | Precisa ADR-55, puntos 4 y 6 (K-11), sin cambiar la frontera |
| **73** (73.6, 73.7, 73.8) | La exportación simple de auxiliares usa `IEjecutorConsultas` | — | — | — | Clientes externos y MCP no son complementos (K-05); solo en la central, como 73.8 | — |
| **34 / 58** (cupos, licencia) | — | — | — | — | — | PR-1: tope de claves en la cláusula de módulos |
| **11** (privilegios) | — | — | — | — | `rptclaves`, `rptia` reservado | PR-3: `rptexportar` |

---

## 8. Riesgos que el propietario acepta al firmar

| # | Riesgo | Nivel | Mitigación | Residual |
|---|---|---|---|---|
| H-RPT-01 | Pistas de bloqueo en el SQL del ADMIN detienen el POS | Alta | Corrección de la ola 4 + `LOCK_TIMEOUT` + sin transacción (ADR-78) + prueba de regresión | Bajo |
| H-RPT-03 | La reescritura de los 27 reportes se atrasa y la ola 5 no puede imponer el aislamiento | Media | Activación reporte por reporte; lista de excepciones vacía en el corte | Bajo |
| H-RPT-04 | Claves o MCP en una instalación con varias empresas antes de la versión 1 del acceso multiempresa cruzan datos | Alta | Condición de publicación (ADR-80, punto 8) | Bajo con la compuerta |
| H-RPT-05 / K-02 | Proceso aparte con HS256 o con el anillo de la API | Alta | ES256 y anillo propio como condiciones de F2 | Bajo |
| H-RPT-06 | Reportes legítimos de más de 30 s en una central grande | Media | Programados fuera de horario (120 s), estrella o copia de lectura | Medio, aceptado: algunos reportes pasan a programados |
| H-RPT-08 | La IA envía datos del cliente a un proveedor externo | Media | Activación expresa, sin costos ni sensibles por omisión, bitácora | Medio, decisión del cliente al activarlo |
| K-09 | Clave de Power BI en texto plano en el archivo del cliente | Media | Almacén de credenciales de la herramienta; guía de implantación | Bajo |
| — | Ley 172-13 (datos personales) en lo que sale por claves y MCP | Media | Sensibles fuera por omisión; confirmar con el asesor del propietario (inferido) | Por confirmar |

---

## 9. Si el propietario firma / si rechaza

**Si firma FR-77, FR-P1, FR-78, FR-79, PR-3 y PR-4 (y AN-02):**
1. El documentador técnico registra ADR-77, 78 y 79 en `master` (después de ADR-74 a 76, K-13), anota P-1 y la precisión de M-2 en ADR-38, y la precisión de ADR-11 (`rptexportar`, `rptclaves`, `rptia` reservado).
2. El arquitecto-datos diseña para la ola 5: roles y credenciales, `DENY` por esquema, `rptc` (con PR-4), `rep.Ejecucion` y `rep.PreferenciaUsuario`, `gpos_app` sobre `rpt` (K-07) y los índices de los 27 reportes.
3. El backend de la ola 5 construye R5-1 a R5-8 con los criterios de salida de ADR-77 y ADR-78.
4. QA prepara la prueba del interceptor, la de permisos efectivos y la de T-28 con reportes en paralelo.

**Si además firma FR-80 y FR-P2:** el arquitecto-software ajusta el diseño de F2 con el anillo propio (K-02) y la validación de `iss` y `aud` (K-04); el arquitecto-integraciones prepara el contrato `externo/v1` y verifica K-09 con Power BI y Excel; devops, el servicio, la cuenta virtual y la regla de cortafuegos.

**Si rechaza alguno:**
- **FR-77:** la ola 5 no puede cumplir ADR-38 M-2, que es condición de la versión multiempresa; los reportes siguen pudiendo leer toda la base de la empresa. Corrección mínima: los puntos 1, 2 y 4.
- **FR-P1:** las vistas con costos no tienen credencial definida; o se leen con la conexión principal (rompe ADR-77) o no se pueden leer. Corrección mínima: el punto 2.
- **FR-78:** quedan solo las correcciones de la ola 4; con 30 s para todo (M-2 literal), los programados largos fallan. Corrección mínima: decidir el punto 2 (30 s para todo o la excepción de programados).
- **FR-79:** el backend necesita saber dónde guardar las preferencias, que ya están planificadas en la ola 5. Corrección mínima: el punto 2.
- **FR-80:** no hay canal externo. Power BI y el MCP esperan; nada de la entrega 1 cambia.

---

## Supuestos

- Que un propósito de Data Protection no aísla frente a quien tiene el anillo (K-02) es **inferido** del diseño de la biblioteca; el auditor-seguridad lo confirma al revisar F2.
- El *gateway* local de Power BI y la forma en que Power BI y Excel guardan credenciales (K-09, K-10) son **inferidos**; el arquitecto-integraciones los verifica antes de F3.
- `MAXDOP`, `MAX_GRANT_PERCENT` y `QUERY_GOVERNOR_COST_LIMIT` en SQL Server 2019 Express: **inferido** de la documentación; QA lo verifica.
- La corrección de la ola 4 (pistas, 30 s, `LOCK_TIMEOUT`) se da por hecha según el encargo; a la hora de leer el árbol (`bd7eb27`) aún no estaba (K-06).
- Que AN-02 no está firmada se deduce de no encontrar su firma en los documentos leídos; si ya se firmó, K-08 se cierra.
- Las cifras de esfuerzo son las de `[PRO]` (±35 %) más mis ajustes de K-02 y PR-4; el costo en dinero usa USD 1.500 a 2.000 por sp. Volumen de la bitácora y memoria del proceso: inferidos.

### Cierre
- Estado: Completado (textos de ADR-77 a ADR-80, P-1 y P-2 en estado Propuesto). Recomendación: **Aprobar** ADR-77, P-1, ADR-78, ADR-79; ADR-80 (a) y (c), (b) no por ahora; P-2 en principio; PR-1 a PR-4 como se recomienda. **Pendiente de firma.**
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\hoja-firma-api-reportes-2026-10-07.md`
- Supuestos: los de la sección «Supuestos».
- Decisiones candidatas a ADR: ADR-77, ADR-78 (con la precisión de ADR-38 M-2), ADR-79, ADR-80 (precisa ADR-40 y ADR-24); P-1 (precisión de PR-ADR38); precisión de ADR-11 (`rptexportar`, `rptclaves`, `rptia`); P-2 dentro de ADR-55 y 56; tope de claves dentro de la precisión de ADR-58.
- Entregas a otros agentes:
  - documentador-tecnico → registrar 74 a 76 y después 77 a 80, P-1, la precisión de M-2 y la de ADR-11 tras la firma;
  - arquitecto-datos → roles, `DENY`, `rptc` con PR-4, tablas `rep.*`, `gpos_app` sobre `rpt` (K-07), índices;
  - arquitecto-software → anillo propio y validación de `iss`/`aud` en el diseño de F2 (K-02, K-04);
  - arquitecto-integraciones → `externo/v1`, credenciales de Power BI y Excel (K-09, K-10), contrato del MCP;
  - auditor-seguridad → confirmar K-02 y revisar ADR-77 y ADR-80;
  - qa-automatizado → interceptor, permisos efectivos, T-28 con reportes, regresión de H-RPT-01;
  - devops → `tempdb`, autenticación contenida, servicio y cuenta virtual (F2).
- Próximo paso recomendado: que el propietario marque FR-77, FR-P1, FR-78, FR-79, PR-3 y PR-4 (y AN-02) antes del 2026-11-16; FR-80, FR-P2, PR-1 y PR-2 pueden firmarse hoy o en su plazo.
