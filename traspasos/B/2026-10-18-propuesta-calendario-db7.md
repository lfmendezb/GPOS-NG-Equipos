[Decisión preparada por el Arquitecto Maestro (equipo B)]  Estado: **Pendiente de firma**

# DB-7: acceso multiempresa v1 para el primer cliente. Alcance, tramos y calendario hasta el corte

- **Fecha:** 2026-10-18
- **Preparado por:** Arquitecto Maestro del equipo B (coordinador)
- **Firma:** el propietario (hoja de la sección 10)
- **Base leída:** `master` `fe42b415`; código de `feature/modelo-ng` `17ecc9b9` (solo lectura, `git grep` / `git show`)

---

## 1. Contexto y pregunta a decidir

El propietario hizo de DB-7 una condición de publicación del primer cliente el 2026-10-16: «Sobre DB-7. Aprobado según recomendaciones» (`avisos/B-a-A/2026-10-16-corporativa-respuestas-db-fd.md:35-38`; `CLAUDE.md`, lista «Antes de publicar al cliente»). DB-7 es la versión 1 del acceso multiempresa (ADR-34 a 43, firmados el 2026-09-29).

**Preguntas a decidir:**
1. Qué entra en la v1 que exige el primer cliente.
2. Quién la construye y en qué orden respecto de la cadena de uniones, la fase A de ADR-81 y las olas.
3. Con qué fechas hasta el corte de mediados de diciembre de 2026.

**Supuesto de fecha:** tomo el **martes 2026-12-15** como «mediados de diciembre».

### 1.1 Lo que hay hoy en el código (verificado en `feature/modelo-ng` `17ecc9b9`)

| Pieza de la v1 | Estado | Evidencia |
|---|---|---|
| Membresía cuenta↔empresa (`UsuariosEmpresas`) | **No existe** | `git grep UsuariosEmpresas`: 0 archivos en `src/` |
| Acceso validado por empresa | **No existe** (H-01). El inicio de sesión solo comprueba que la empresa exista y esté habilitada | `src/GPOS.Api/Endpoints/AuthEndpoints.cs:77-79` y `:116-118` |
| Lista anónima de empresas (H-07) | **Sigue abierta** | `AuthEndpoints.cs:23` (`GET /api/auth/empresas`, sin `RequireAuthorization`) |
| ADMIN global (H-02) | **Sigue global**: `RequiereAdmin` lee el nivel de la cuenta | `src/GPOS.Api/Seguridad/Seguridad.cs:228`; `AdminEndpoints.cs:16` |
| Inicio en dos pasos (`/api/auth/identificar`) | No existe | 0 archivos |
| Tokens de sesión ES256 | No existen: ES256 solo está en la licencia y en `GPOS.Criptografia` | `src/GPOS.Criptografia/Jws/ContratosJws.cs`; `src/GPOS.Contracts/Licencia/FormatoLicencia.cs` |
| Cupo por empresa | **Está en la licencia, pero se cuenta en global** (la suma de los cupos) | `src/GPOS.Core/Sistema/UsuariosService.cs:221-224` (`CupoUsuarios(null)`) |
| `BitacoraSistema` (ADR-37) | No existe. Los eventos van a `BitacoraSeguridad` | precisión del punto 12 de ADR-81 (2026-10-15) |
| Razor solo del SUPER (M-3, SUP-05) | **Existe** | `ImpresionEndpoints.cs:70-80` (`ExigirModoCodigo`) |
| Usuarios contenidos por empresa (M-1) | **En construcción** con el lote 2 de ADR-82 (`gpos_app_a/b`) | `src/GPOS.Migracion/CredencialApp.cs`, `ClavesSql.cs`; `ModoIdentidad` en 7 archivos |
| Credencial de reportes de solo lectura (M-2) | **En construcción** con la ola 5 (ADR-109, `gpos_rpt` / `gpos_lec`) | `src/GPOS.Reportes/Ejecucion/IEjecutorConsultas.cs` |
| Esquema fuera de la API (M-4) | **En construcción** con ADR-82 punto 4 (`GPOS.Migracion sistema`, modo Estricto) | ADR-82, punto 4 |
| Segundo factor del SUPER | **En construcción**: fase A de ADR-81, en `c/adr81-fase-a` y en el #57, sin unir | `estado.md`, equipo C |

**Conclusión:** H-01, H-02 y H-07 siguen abiertos tal como los describe la auditoría (`docs/propuestas/auditoria-aislamiento-multiempresa.md:60-61`). Desde el 2026-09-29, cuatro piezas de la v1 pasaron a otras decisiones que ya están en construcción: M-1, M-2, M-4 y el factor del SUPER. Sobre ellas no hay que construir nada dentro de DB-7: solo verificarlas.

### 1.2 Qué cambió desde el plan del 2026-09-29

El plan original suponía una base instalada con usuarios reales: la migración «TODAS», la revisión vinculante de 30 días, una versión de convivencia y la fase 2 no reversible (`docs/decisiones/2026-09-29-decision-acceso-multiempresa.md`, 7.1 y 7.5). **Esa base no existe:**
- BP2 nunca salió a producción.
- Hoy todo es desarrollo y el DEMO.
- La implantación es desde cero con plantillas (`CLAUDE.md`, «Implantación desde cero»).

Por eso buena parte del costo de la v1 (migración, revisión, reversión y rutas de convivencia) ya no protege a nadie. Se puede retirar con una precisión firmada (DB7-02).

---

## 2. Entregables evaluados

- ADR-34 a ADR-43 (`docs/adr/ADR-034.md` a `ADR-043.md`), con sus precisiones.
- Decisión de origen: `docs/decisiones/2026-09-29-decision-acceso-multiempresa.md` (7.1, 7.4, 7.5 y 12.7: v1 de 19,3 a 22,5 sp, ±30 %).
- Estándar: `docs/arquitectura/2026-09-29-estandar-acceso-multiempresa.md` (v2.3; reglas IDN, MEM, PRV, AIS, ADM, SUP, SES, REV y TRZ).
- Auditoría: `docs/propuestas/auditoria-aislamiento-multiempresa.md` (H-01 y H-02, Críticas).
- ADR-58 (cupo por empresa, con la precisión de ADR-34), ADR-81 (fase A), ADR-82 (lote 2) y ADR-83 (punto 9: el sello y el padrón pasan a la membresía con la v1).
- Blueprint de la vertical Corporativa (`traspasos/A/blueprint-vertical-corporativa-2026-10-15.md`, 13.1: DB-7 «A»; R-1 Alta).
- Tablero `estado.md` y traspaso `traspasos/B/2026-10-18-traspaso-B-cambio-de-sesion.md`.
- **No existe** un blueprint ni un plan de DB-7 posterior al 2026-09-29: lo busqué en `docs/` y en el área común. Este documento es el primer plan.

---

## 3. Alcance mínimo de la v1 para el primer cliente

### 3.1 Opciones

| Opción | Contenido | Esfuerzo (sp nominales, ±30 %, inferido) | ¿Cierra H-01, H-02 y H-07? |
|---|---|---|---|
| **A. v1 completa, como se firmó el 2026-09-29** | Todo lo de 7.1 de la decisión, con la migración «TODAS», la revisión de 30 días, la fase 1 reversible y la convivencia | 19,3 – 22,5 (menos lo que ya cubren ADR-81, 82 y 109: unas 3 sp) ≈ **16 – 19,5** | Sí |
| **B. v1 mínima para el primer cliente (recomendada)** | La v1 sin convivencia ni migración de usuarios reales (DB7-02), con la bitácora sobre `BitacoraSeguridad` (DB7-03) y con M-1, M-2, M-4 y el factor del SUPER tomados de sus propias piezas | **13,5 – 17,5** | Sí |
| **C. Guarda mínima** | Membresía con nivel, perfiles y sucursal; validación por petición; ADMIN por empresa; fin de la lista anónima; selector de empresas autorizadas. Sin dos pasos, sin ES256 y con el cupo todavía global | 6 – 8 | Sí en lo esencial. Deja ES256, el cupo por empresa y el sello por membresía para después del corte |
| **C′. Candado de una empresa** (contingencia) | Publicar al primer cliente solo si tiene **una sola empresa habilitada**, con una guarda técnica que impide habilitar la segunda hasta tener la v1 | ≈ 0,2 | **No los cierra**, pero no hay segunda empresa a la que cruzar |

**Recomendación: B**, con C y C′ como salidas del punto de control del 2026-11-20 (DB7-07).
- **A** gasta unas 3 sp en proteger una base instalada que no existe.
- **C** es más barata, pero obliga a rehacer el inicio de sesión y el token después del corte.
- **C′** modifica la decisión del 2026-10-16. Solo sirve si el primer cliente tiene una sola empresa; si es de la vertical Corporativa o del grupo de un dueño, no sirve.

### 3.2 Qué entra en B

Reglas del estándar, con las precisiones de esta hoja:
1. **Cuenta y membresía** (ADR-34): `UsuariosEmpresas` con `HABILITADA`, `SUSPENDIDA` y `BAJA`; nivel ADMIN o USER, perfiles, excepciones, sucursal predeterminada y restricción por membresía; los perfiles son de una sola empresa; el SUPER es global y sin membresías.
2. **ADMIN por empresa** (ADR-35):
   - miembros de su empresa, alta, vínculo por dominio de administración, y suspensión, reactivación y baja con motivo;
   - límite de 20 por hora;
   - desbloqueo condicionado (P5 = C);
   - las credenciales son solo del SUPER.
3. **Inicio en dos pasos y validación en cada petición** (ADR-36):
   - `identificar` → `login`, con el factor entre los dos (precisión de ADR-81);
   - respuestas uniformes;
   - bloqueo primero por (cuenta, IP);
   - estado de acceso sin caché y permisos en caché por (cuenta, empresa, versión);
   - 503 si falla la lectura;
   - sesión única con empresa;
   - `X-GPOS-Privilegios`;
   - tareas en segundo plano a nombre de la persona.
4. **Ingreso del SUPER a una empresa con motivo obligatorio**, visible para el ADMIN de esa empresa (ADR-35). La duración de la sesión es la de ADR-81, que es más estricta (supuesto 3).
5. **Token `ver = 2` con ES256**, con `iss`, `aud` y `kid` desde la primera versión (ADR-41 y su precisión de ADR-53); la llave va en el TPM de la central (DB7-04).
6. **Licencia por empresa**: el consumo se cuenta por empresa desde el padrón; el sello y el padrón pasan a la membresía (ADR-34 con la precisión de ADR-58, y ADR-83 punto 9; DB7-05). El SUPER ve la licencia de toda la instalación y el ADMIN solo la de su empresa.
7. **Bitácora de acceso** sobre `BitacoraSeguridad`, con la empresa que actúa y la afectada (DB7-03).
8. **Notificaciones y reportes con autor y visibilidad por empresa** (AIS-06, REV-07 y PRV-07). La API de reportes valida el acceso por la introspección (DB7-04).
9. **Web y MAUI juntas:**
   - inicio en dos pasos y cambio de empresa;
   - «Personas y accesos» del ADMIN y «Cuentas» del SUPER;
   - licencia por empresa;
   - avisos.
10. **Verificación de lo que ya cubren otras piezas:**
    - M-1: `GPOS.Migracion verificar` exige `gpos_app_*` en toda empresa habilitada (ADR-82);
    - M-2: ADR-109;
    - M-3: SUP-05 existe; la prueba de escape del modo gráfico (R-12 del 2026-09-29) queda por confirmar;
    - M-4: ADR-82, punto 4;
    - el factor del SUPER: fase A de ADR-81.
11. **Calidad:**
    - los casos de aislamiento del estándar (§8);
    - la medición de Q1 (p95 ≤ 2 ms, ADR-36);
    - la auditoría del código (H-01 a H-14, ES256);
    - la conversión del DEMO.

### 3.3 Qué no entra (y dónde queda)

| Fuera de la v1 mínima | Queda en |
|---|---|
| Migración «TODAS» con informe de actividad, revisión vinculante de 30 días, cuadro de cupos, fase 1 reversible y fase 2 | **Se retira** (DB7-02); el DEMO y los equipos de desarrollo se convierten con un verbo simple |
| Inicio en un paso «por compatibilidad» y `/api/admin/usuarios` de solo lectura | **Se retiran** (DB7-02): no hay clientes antiguos |
| Invitaciones por código | Fase 2 (ADR-35), sin cambio |
| Cadena de hashes de la bitácora y resumen diario | Fase 2 (ADR-37), sin cambio |
| Restablecimiento por el ADMIN (P5 = B) | Opcional de la fase 2, sin cambio |
| Render por empresa (P7-C) y Liquid | ADR-40 y 42, con las precisiones de ADR-109 y 110 |
| Política opcional de factor por perfil del ADMIN | Fase B de ADR-81, después del corte |
| Nodos de sucursal | Entrega 2 (ADR-53) |
| Credenciales SQL, reportes y esquema (M-1, M-2 y M-4) | En sus piezas: ADR-82, lote 2, y ADR-109. DB-7 solo las verifica |

---

## 4. Tramos, dependencias y equipos

**Calibración del esfuerzo (inferido, margen ±50 %).** Con el ritmo observado del 14 al 18 de octubre, un equipo entrega del orden de 2 a 4 sp nominales por semana de calendario. Por ejemplo, el 2026-10-17 A construyó, revisó y entregó SL (3,75 dp) y RN (1,25 dp). El calendario no lo fijan los agentes, sino estas restricciones:
- las uniones en serie;
- una sola suite completa a la vez;
- las revisiones de seguridad;
- las firmas.

| Tramo | Contenido | sp (±30 %) | Equipo | Depende de |
|---|---|---|---|---|
| **D0** Diseño | Blueprint v3 del estándar, acotado a B, regla por regla (entra / no entra). Modelo de datos de la membresía y del sello en dos niveles (cuenta y membresía). Consultas Q1 a Q13. Revisión del auditor. Hoja de preguntas del diseño | 0,6 – 1 | **A** (arquitecto-software y arquitecto-datos; A está libre) con el auditor de A; la hoja la prepara B | Firma de esta hoja |
| **D1** Datos y núcleo de acceso | `UsuariosEmpresas`, privilegios por membresía, validación por petición (AIS), cachés con la llave (cuenta, empresa, versión), `RequiereAdmin` con el nivel efectivo, endpoints del ADMIN por empresa, P5 = C, S-04, S-07 y S-12, y el verbo de conversión del DEMO | 4 – 4,8 | **A** | D0; #57 y #73 unidos |
| **D2** Inicio de sesión y token | `identificar` → `login`, factor reubicado (precisión de ADR-36 por ADR-81), comprobante de preautorización, retiro de la lista anónima, `ver = 2` ES256 con TPM, `iss`, `aud` y `kid`, y retiro de `Jwt:Clave`. Ingreso del SUPER con motivo | 2 – 2,5 | **C** (autor del flujo de la fase A) | D0; #57 unido |
| **D3** Licencia y sello por membresía | Consumo por empresa desde el padrón, sello de cuenta y sello de membresía (DB7-05), `EnExceso` por empresa, pantalla del SUPER y vista del ADMIN. Ajuste de la reprotección conjunta (RSV-03) a la membresía | 1,4 – 2 | **A** (autor de SL y RN) | D1 (contratos); RSV-03 construido |
| **D4** Web y MAUI | Inicio en dos pasos, cambio de empresa, «Personas y accesos», «Cuentas», licencia por empresa y avisos | 1,7 – 2,2 | **C** (pantallas de la fase A), con la UX de B | D1 y D2 (contratos fijados en D0) |
| **D5** Bitácora, notificaciones y reportes | `BitacoraSeguridad` con empresa que actúa y afectada, catálogo, vista del ADMIN y retención por categoría (DB7-03). Notificaciones con autor. Introspección de la API de reportes con el acceso | 1,2 – 1,5 | **B** (dueño de la ola 5 y de la API de reportes) | D1 |
| **D6** Calidad y cierre | Suite completa, casos de aislamiento, Q1 (p95), auditoría del código, ensayo de la conversión del DEMO y hoja de cierre | 2,6 – 3,5 | **B** (coordina y corre las suites), con el auditor de A y una revisión cruzada de C | D1 a D5 |
| **Total** | | **13,5 – 17,5** | | |

**Reglas de reparto:**
- **Un dueño por zona de código**, para no repetir los choques de la cadena actual:
  - A: `UsuariosService`, `PermisosService`, `Seguridad.cs`, `AdminEndpoints` y `SellosService` / `PadronSellos`;
  - C: `AuthEndpoints` y el emisor de tokens;
  - B: la bitácora y `GPOS.Reportes.Api`.
- **C no corre suites largas** mientras siga inestable (23 pantallazos en 7 días; `estado.md`, equipo C): escribe el código y las pruebas dirigidas, y las suites las corren B o A. Si C se cae, D2 pasa a A y D4 a B; las ramas se suben a diario.
- **Orden respecto de lo firmado:** DB-7 empieza a construirse **después** de la cadena OR-01 (#52 + #55 → #51 → #45 → #48 (#60) → #63 → #67 → #68 → #57 → #58) y del #73. La fase A de ADR-81 (#57) se une **antes** de D2, que la reubica. La ola 5 (auditoría) no espera a DB-7. D0 empieza ya, porque solo produce documentos.

---

## 5. Calendario propuesto (inferido; fechas objetivo)

| Semana | Fechas | Hitos |
|---|---|---|
| S0 | 2026-10-19 → 10-24 | Firma de esta hoja (objetivo: **10-20**). D0 empieza en A. B une la cadena OR-01 hasta el #68. A construye RSV-03 y RSV-02 apilados sobre el #73 (hoja `2026-10-18-hoja-firma-rsv-anillo-sellos.md`) |
| S1 | 10-26 → 10-31 | B une el #57 (fase A) → #58 → #73. Blueprint v3 entregado (**10-27**), revisión de seguridad (**10-29**) y hoja del diseño firmada (objetivo: **10-31**) |
| S2 | 11-02 → 11-07 | D1 (A) y D2 (C) en construcción; D5 (B) en diseño fino |
| S3 | 11-09 → 11-14 | D1 en PR (**11-13**). D3 (A) y D4 (C) empiezan con los contratos fijados. Semana del e-CF exclusivo (15-nov): B atiende primero el conector |
| S4 | 11-16 → 11-21 | D2 en PR. D5 en PR. **Punto de control: 2026-11-20** (DB7-07) |
| S5 | 11-23 → 11-28 | D3 y D4 en PR. B une D1 → D2 → D3 → D5 → D4 |
| S6 | 11-30 → 12-05 | D6: suite completa, aislamiento, Q1 y auditoría del código (**12-04**) |
| S7 | 12-07 → 12-11 | Correcciones de la auditoría, ensayo de la conversión del DEMO, hoja de cierre y firma de la v1 (objetivo: **12-11**) |
| Margen | 12-12 → 12-15 | Corte de la entrega 1 |

**Holgura:** 2 días hábiles. Es poca: por eso existe el punto de control.

---

## 6. Evaluación contra criterios de aceptación (de esta propuesta)

| Criterio | ¿Se cumple? | Evidencia |
|---|---|---|
| Cierra H-01, H-02 y H-07 antes del primer cliente | Sí, con B (o con C en contingencia) | 3.2, puntos 1 a 3 |
| No contradice un ADR vigente sin precisión | Sí: cada recorte va con su precisión en la hoja (DB7-02 a DB7-05) | Sección 10 |
| Esfuerzo y calendario cuantificados | Sí, inferidos con su margen | Secciones 4 y 5 |
| Respeta el orden firmado OR-01 y la fase A de ADR-81 | Sí | Sección 4 |
| Costo de infraestructura y licencias | **Ninguno.** El TPM de la central se usa con el proveedor de Windows y ES256 no requiere compra | — |

---

## 7. Cumplimiento de estándares del proyecto

- Proyectos: no se crea ninguno; todo va en `GPOS.Api`, `GPOS.Core`, `GPOS.Contracts`, `GPOS.Migracion`, `GPOS.Web` y MAUI.
- Esquema de `GPOS_SYSDATA`: por `GPOS.Migracion sistema` (ADR-82, punto 4). No es base de empresa, así que ADR-50 (`varchar`) no aplica a las tablas nuevas de acceso.
- Orden de bloqueos (precisión de ADR-45): DB-7 no toma bloqueos de documentos. El control del cupo usa el bloqueo serializable del padrón (ADR-83).
- Principio rector: los cambios visibles para el usuario ya están firmados (ADR-34 a 36). Esta hoja agrega solo recortes, con «qué rompe» por punto.

---

## 8. Riesgos y mitigaciones

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | El calendario no alcanza: 13,5 a 17,5 sp compiten con otras condiciones del primer cliente (lote 2 de ADR-82, acta de GSF AG-01 a AG-07, conector de e-CF, PUB-06, RG-04/05, RG-25 y AP-04) | Media / Alto | Punto de control del 2026-11-20 con C y C′ (DB7-07) |
| R-2 | Choques de código con los PR en vuelo (`AuthEndpoints`, sellos y `UsuariosService`) | Alta si se empieza antes / Medio | Construir después del #57 y del #73; un dueño por zona (sección 4) |
| R-3 | El equipo C es inestable | Alta / Medio | Las suites las corren B o A; push diario; reasignación prevista |
| R-4 | Rendimiento: la lectura sin caché del acceso en cada petición frente a los topes de T-28 y T-57 (32,8 / 31,6 ms) | Media / Medio | Una sola consulta para el sello y la membresía; Q1 medida con p95 ≤ 2 ms (ADR-36); si no se cumple, el Maestro prepara el plazo mayor que prevé ADR-36 |
| R-5 | Doble trabajo: el sello y el padrón cambian de forma (DB7-05) justo después de RSV-03 y antes del acta de GSF | Cierta / Bajo | RSV-03 sobre una abstracción de la fuente de sellos (≤ 0,3 dp de ajuste); el acta de GSF se construye **después** de fijar el formato en D0 |
| R-6 | El alcance crece con las 79 reglas del estándar | Media / Medio | El blueprint v3 lista regla por regla qué entra; todo lo demás va a un ADR o a la fase 2 |
| R-7 | Las firmas se atrasan (esta hoja y la del diseño) | Media / Alto | Hojas cortas; objetivos 10-20 y 10-31 |
| R-8 | La API de reportes valida mal el acceso después de ES256 | Baja / Alto | DB7-04 (b): la introspección se mantiene para el estado de acceso |
| Residual | Frente a un SUPER malicioso o a una ejecución de código dentro de la API no hay aislamiento | Aceptado en ADR-38 (G-1) | Sin cambio |

---

## 9. Alternativas descartadas

- **A, v1 completa:** unas 3 sp más para proteger una base instalada que no existe (sección 3.1).
- **Construir DB-7 en paralelo con la cadena OR-01:** cada PR en vuelo tendría que rebasar sobre una reescritura de `AuthEndpoints` y del sello (R-2).
- **Aplazar DB-7 a después del corte:** contradice la decisión del 2026-10-16.
- **Una sesión por cuenta y empresa:** ya descartada en ADR-36 (cuesta de 1 a 1,5 sp más y debilita ADR-30).

---

## 10. Hoja de firma (DB7-01 a DB7-07)

Marque una opción por punto. «Según la recomendación» firma la opción recomendada de cada punto.

### DB7-01 · Alcance de la v1 para el primer cliente
- **Recomendación: (B) v1 mínima** (sección 3.2; 13,5 a 17,5 sp). Alternativas: (A) completa; (C) guarda mínima.
- **Qué rompe:** nada de lo firmado en la experiencia del usuario. Lo que queda fuera (3.3) ya estaba en la fase 2, salvo lo que retira DB7-02.
- **A quién afecta:** a los equipos (plan) y al primer cliente (fecha).
- **Por qué se justifica:** cierra H-01, H-02 y H-07 con el menor costo que no obliga a rehacer el inicio de sesión después del corte.
- **Cómo se migra:** ver DB7-02.
- [ ] (B) recomendada  [ ] (A)  [ ] (C)

### DB7-02 · Sin convivencia ni migración de usuarios reales (precisión de ADR-39, ADR-34 —«versión de convivencia»—, ADR-35 —`/api/admin/usuarios` de solo lectura— y ADR-36 —inicio en un paso)
- **Recomendación:**
  - la v1 nace directamente en el modelo final: sin modo «TODAS» con revisión de 30 días, sin cuadro de cupos de migración, sin fase 1 reversible ni fase 2, sin inicio en un paso y sin rutas de convivencia;
  - el DEMO y los equipos de desarrollo se convierten con `GPOS.Migracion accesos --convertir`: cada cuenta recibe una membresía en cada empresa habilitada con su nivel actual, en una sola transacción con prueba de equivalencia, y sin revisión;
  - una instalación nueva crea las membresías en la implantación.
- **Qué rompe:**
  - En el DEMO, todo ADMIN queda como ADMIN de **cada** empresa hasta que el SUPER lo ajuste.
  - Todos inician sesión otra vez.
  - Los clientes Web y MAUI de versiones anteriores dejan de entrar.
- **A quién afecta:** a GSF y a quien prueba el DEMO. A ningún cliente: no hay ninguno en producción.
- **Por qué se justifica:**
  - Ahorra unas 3 sp: S-03 (1), S-08 (0,5), las partes A, B y C de la migración y la reversión.
  - Retira código que nadie usaría.
  - Se aplica la regla de que BP2 no tiene costumbres que proteger.
- **Cómo se migra:** el verbo de conversión del DEMO (≈ 0,3 sp, incluido en D1). Si después apareciera una instalación con usuarios reales, se haría con una decisión aparte.
- [ ] Firmo (recomendada)  [ ] Mantener la migración firmada el 2026-09-29

### DB7-03 · Bitácora de acceso sobre `BitacoraSeguridad` (precisión de ADR-37; es la «decisión aparte» que anuncia la precisión del punto 12 de ADR-81)
- **Recomendación:**
  - no se crea `BitacoraSistema`;
  - `BitacoraSeguridad` suma la empresa que actúa, la empresa afectada y la categoría, y amplía su catálogo cerrado con las acciones de ADR-37;
  - el ADMIN ve, de solo lectura y filtradas por el servidor, las filas de **acceso** de su empresa, sin mención de otras empresas;
  - el resto lo sigue viendo solo el SUPER;
  - **retención por categoría:** acceso y membresías, 5 años (ADR-37; sigue pendiente el dictamen legal); factor, licencia y sello, 2 años (ADR-81).
- **Qué rompe:** el texto de ADR-37 que dice `BitacoraSistema`.
- **A quién afecta:** al ADMIN (ve su bitácora de acceso en la pantalla *Bitácora*, junto a `Log`).
- **Por qué se justifica:** una sola tabla de solo inserción, ya protegida por RG-14, en lugar de dos. Ahorra unas 0,5 sp. El volumen es de unos 125 MB en 5 años (estimación de ADR-37).
- **Cómo se migra:** una DDL idempotente en `GPOS.Migracion sistema`. No hay historia que mover.
- [ ] Firmo (recomendada)  [ ] Crear `BitacoraSistema` aparte

### DB7-04 · ES256 en la v1 con la llave en el TPM, e introspección para el acceso (confirma ADR-41; precisión de su nota del 2026-10-08)
- **Recomendación:**
  - (a) ES256 entra en la v1 con `ver = 2`. La llave va en el TPM de la central (Microsoft Platform Crypto Provider; sin TPM, con las condiciones de C49-1 v2). `iss`, `aud` y `kid` son obligatorios. Se retira `Jwt:Clave`.
  - (b) La API de reportes **mantiene la introspección** contra la principal para el estado de acceso de cada petición (sin caché, ADR-36), aunque valide la firma en local.
- **Qué rompe:**
  - Todos los tokens actuales.
  - La instalación exige aprovisionar la llave (`GPOS.Migracion aprovisionar`).
  - La nota de ADR-41, que preveía retirar la introspección con ES256.
- **A quién afecta:** a GSF (implantación) y a la API de reportes.
- **Por qué se justifica:**
  - Sin ES256, quien lea la configuración puede emitir un token SUPER con `amr = otp`, y eso anula la fase A de ADR-81.
  - Cuesta de 0,6 a 0,8 sp.
  - (b) deja un solo punto de decisión del acceso y no le da a la API de reportes la lectura de las membresías.
- **Alternativa:** ES256 después del corte, ahorrando unas 0,7 sp ahora a cambio de un segundo inicio forzado y de la exposición de `Jwt:Clave`.
- **Cómo se migra:** un inicio de sesión de todos al desplegar.
- [ ] Firmo (a) y (b)  [ ] ES256 después del corte

### DB7-05 · Sello en dos niveles y cupo por empresa (precisión del punto 9 de ADR-83 y de ADR-34)
- **Recomendación:**
  - **Sello de cuenta:** contraseña, factor, nivel SUPER, inhabilitada y código.
  - **Sello de membresía:** cuenta, empresa, nivel ADMIN o USER, estado y restricción de sucursal.
  - Padrón con entradas por (cuenta, empresa) y entradas SUPER de cuenta.
  - El consumo de cada empresa se calcula con sus entradas no SUPER habilitadas del padrón verificado.
  - El cupo es el de la licencia; el exceso se maneja por empresa (`EnExceso`, ADR-58, punto 9).
  - El formato exacto lo fija D0.
- **Qué rompe:** el formato actual del sello y del padrón (SL, #63 y #68). La legitimación y el resellado pasan a ser por membresía.
- **A quién afecta:** a GSF (`sellos --legitimar` por empresa) y al ADMIN (su cupo es solo el de su empresa).
- **Por qué se justifica:** ADR-34 exige un cupo independiente y obligatorio por empresa. Con un sello solo de cuenta, un `UPDATE` de la membresía ampliaría el cupo de una empresa sin rehacer ningún MAC (la misma clase de defecto que SEG-L2-01).
- **Cómo se migra:** el verbo de DB7-02 sella las membresías convertidas, con control del cupo por empresa. Las instalaciones de desarrollo sin licencia quedan con cupo 0, como hoy (LV-17).
- [ ] Firmo (recomendada)  [ ] Otra (indicar)

### DB7-06 · Reparto y orden
- **Recomendación:**
  - D0, D1 y D3 al equipo A; D2 y D4 al equipo C; D5 y D6, la integración y las suites a B (sección 4);
  - la construcción empieza después del #57 y del #73;
  - calendario de la sección 5, con la firma de la v1 el 2026-12-11.
- **Qué rompe:** nada.
- **A quién afecta:** a los equipos. A deja libre su cola después de RSV-03; C pasa de la fase A al inicio de sesión de la v1.
- **Por qué se justifica:** cada tramo lo toma quien ya escribió esa zona del código (A el sello, C el flujo del factor, B la API de reportes), y la construcción espera a que se unan los PR que tocan esos archivos.
- **Cómo se migra:** no aplica.
- [ ] Firmo (recomendada)  [ ] Otro reparto (indicar)

### DB7-07 · Punto de control del 2026-11-20 (precisión de la decisión del 2026-10-16 sobre DB-7)
- **Recomendación:** el 2026-11-20, B informa si D1 y D2 están unidos o con PR apto. Si no lo están, el Maestro presenta para firma una de estas dos vías:
  - **(C)** la guarda mínima antes del corte y el resto después; o
  - **(C′)**, solo si el primer cliente tiene una sola empresa: el candado técnico de «una empresa habilitada» hasta la v1.
- **Qué rompe:** con C′, la decisión del 2026-10-16 queda condicionada a los clientes de una sola empresa.
- **A quién afecta:** al primer cliente y a GSF.
- **Por qué se justifica:** evita llegar al 12-11 sin la condición de publicación y sin un plan B.
- **Cómo se migra:** C y C′ no impiden terminar B después.
- [ ] Firmo (recomendada)  [ ] Sin punto de control

---

## 11. ADR propuesto

**No hace falta un ADR nuevo.** DB7-02 a DB7-05 son precisiones de ADR-34 a 37, 39, 41 y 83. Si el propietario firma, B las registra en `master` como «Precisión del 2026-10-xx (DB7-0n)», sin reescribir el texto firmado.

## 12. Si el usuario firma / si rechaza

- **Si firma:**
  - B registra las precisiones en `master` y pone al día `CLAUDE.md` (la nota «Decidido, NO implementado» del acceso multiempresa con su plan);
  - B encarga D0 a A con un aviso `B-a-A`;
  - B avisa a C del reparto;
  - B anota el punto de control en `estado.md`.
- **Si rechaza DB7-01 (B):** con (A), el calendario no alcanza el 12-11. Se necesitan 3 sp más, o pasar al punto de control con C′.
- **Si rechaza DB7-02:** se agregan al plan la migración «TODAS», la revisión de 30 días y la convivencia (≈ 3 sp), y D1 crece una semana.
- **Si rechaza DB7-04 (a):** se quita ES256 de D2 (−0,7 sp) y queda como pendiente fechado después del corte. DB7-04 (b) sigue siendo necesaria.
- **Si rechaza DB7-05:** D0 tiene que proponer otro mecanismo para el cupo por empresa que no se pueda ampliar por SQL. Sin él, DB-7 incumple ADR-34.

---

### Supuestos
1. «Mediados de diciembre» = 2026-12-15.
2. Ritmo de 2 a 4 sp nominales por equipo y semana de calendario (inferido del 14 al 18 de octubre, ±50 %).
3. La sesión del SUPER sigue ADR-81 (30 min de inactividad y 4 h como máximo, punto 14), que es más estricta que las 2 h de ADR-35.
4. La cadena OR-01 y el #73 quedan unidos antes del 2026-10-31.
5. El lote 2 de ADR-82, la ola 5 (ADR-109) y la fase A de ADR-81 se terminan por su cuenta y fuera de este presupuesto.
6. El primer cliente se publica después del corte. Si se adelantara, aplica DB7-07.
7. La corrección R-12 del escape del modo gráfico (2026-09-29) no la verifiqué en el código; D0 lo confirma.

## Firma

**Firmada por Leonardo Méndez, propietario, el 2026-10-18 en la sesión de B:** «Firmo según recomendación. Sobre quien realiza DB-7, entiendo que el equipo B debería asumir esta tarea por ser el equipo principal y mas estable con mayor capacidad de A y mejor estabildiad que C».

- **DB7-01:** (B), la v1 mínima. **DB7-02**, **DB7-03**, **DB7-04 (a) y (b)**, **DB7-05** y **DB7-07:** según la recomendación.
- **DB7-06, con otro reparto:** la construcción de DB-7 la asume **el equipo B**, por ser el equipo principal, con más capacidad que A y más estabilidad que C. Se mantienen el orden (la construcción empieza después del #57 y del #73) y el calendario de la sección 5, con la firma de la v1 el 2026-12-11 y el punto de control del 2026-11-20.
- Lo que la sección 4 asignaba a A y a C (D0 a D4) pasa a B. El PR de RSV sigue en A (hoja `2026-10-18-hoja-firma-rsv-anillo-sellos.md`).

