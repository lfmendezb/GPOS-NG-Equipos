Para: B (copia a A)        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 2 de B-a-C/2026-10-23-tareas-nuevas-para-c-6 y punto 6 del backlog autónomo de la tanda 7)
Prioridad: Alta (antes del 2-nov; B construye desde el 2-nov, punto de control 2026-11-20)
Repositorio y rama: GPOS-NG `master` `fcb7b47b` (documentos) y `feature/modelo-ng` `b9efa9fb` (código y pruebas), solo lectura con `git show` y `git grep`
Estado: Abierto (plan, sin código; no se compiló ni se ejecutó nada)

# Plan de pruebas de DB-7 v1 (acceso multiempresa), tramos D2, D3, D5, D4 y D6, más el índice de D1

## 0. Qué ya existe y qué falta (la comprobación que pidió B)

**Sí existe un plan de pruebas de DB-7, pero solo del tramo D1.** Lo escribí yo:
- `traspasos/C/2026-10-20-plan-pruebas-db7-d1.md` (**P20**): T1-1 a T1-4, 205 pruebas nuevas y 13 cambios en pruebas existentes.
- `traspasos/C/2026-10-22-plan-pruebas-db7-d1-v2.md` (**V2**): complementa P20 con D1-01 a D1-06, CS-P2 y `--caso`; P20 pasa a unas 275 pruebas nuevas.
- Búsqueda: `grep -il "db-?7"` en `traspasos/A`, `traspasos/B`, `traspasos/C` y `avisos/`; no hay otro plan de pruebas de DB-7 de A ni de B. En `docs/` de `master` y de `feature/modelo-ng` (`git ls-tree`) no hay ningún plan de pruebas de DB-7 (solo el blueprint, el modelo de datos, la decisión, la revisión de seguridad y el plan de trabajo de D1).

**Qué cubre (verificado en los índices de P20 y V2):** el esquema v6 de `GPOS_SYSDATA`, las restricciones y disparadores (51619 a 51625), el catálogo y la purga de la bitácora, Q1 y `ICupoEmpresas` provisional, permisos y bitácora de acceso, `MembresiasService`, Q3-P, Q13, Q9, Q10, los 22 endpoints del ADMIN y del SUPER en su parte de datos, y el verbo `accesos --convertir` sin sellar (Q23).

**Qué falta (esto es lo que entrega este documento):**
1. **D2** (`identificar`, `login`, preautorización, cambio de empresa, ingreso del SUPER, bloqueo por (cuenta, IP), ES256, llave en el TPM, retiro de `Jwt:Clave`): sin plan.
2. **D3** (sello de cuenta v2, sello de membresía, padrón v2, cupo definitivo, `EnExceso`, ADR-79 sobre dos fuentes): P20 solo tiene *centinelas* `Centinela=D3`.
3. **D5** (purga por categoría en uso, vista del ADMIN, notificaciones con el principal real, introspección v2, reportes por empresa): sin plan.
4. **D4** (Web y MAUI): sin plan.
5. **D6** (la lista de aislamiento de EST §8, Q1 p95, ensayos): P20 cita QA-17, 19, 21, 58, 94 y ADM-13 dentro de T1-3, pero **no hay una suite de aislamiento con las cuentas P, Q, R, S, T, V y W**, que es la condición de publicación (RQ-R12 y D6).
6. **Pruebas transversales** de la canalización de cada petición (`ValidacionAcceso`, orden de motivos, 503), que P20 reparte entre T1-2 y T1-5 sin dueño claro.

**Premisa:** este plan no repite casos de P20 ni de V2; los cita por su número. Donde un caso de aislamiento ya está en P20 lo marco «P20 T1-3 n.º N» y el caso de aquí solo agrega la capa HTTP de punta a punta.

## 1. Resumen ejecutivo

- **Casos nuevos de este plan:** ver el conteo en la sección 11. Cada fila tiene nivel, esperado y mutación.
- **v1 mínima completa (propuesta de orden, sección 9):** se divide en **P0** (lo que prueba la guarda mínima de la vía C del punto de control del 20-nov: validación por petición, fin de la lista anónima, selector de empresas autorizadas, ADMIN por empresa), **P1** (resto de D2, D3 y D5, exigible para la firma de la v1) y **P2** (D4 y las mediciones de D6). Si el 20-nov solo hay D1 y D2 en PR, **P0 basta para decidir la vía C**.
- **Diez hallazgos de QA al leer el diseño** (sección 10). Los que cambian una prueba:
  - **H-1:** QA-62 dice «S usa su token después de 2 h → 401», pero el blueprint (SUP-02) y ADR-81 fijan 30 min de inactividad y 4 h como máximo. La prueba debe medir lo segundo.
  - **H-2:** el texto de ADR-36 que leí dice «se mantiene el inicio en un paso» y el blueprint (login v2) lo retira. No está definido qué responde `login` si llega `Clave` (pregunta P-2).
  - **H-4:** el `jti` de la preautorización vive en memoria; con **dos instancias** de la API (que exige EST §8 para SES-12) una preautorización se puede consumir una vez en cada instancia (pregunta P-3).
  - **H-6:** Q1 en `READ COMMITTED` espera detrás de una transacción de administración y vence en 2 s; el riesgo R-DB7-12 no tiene prueba (caso INT-503).
- **Preguntas para B:** sección 12 (13 preguntas; cada una dice qué detiene y qué supuse).

## 2. Fuentes leídas

- `docs/decisiones/2026-10-18-decision-db7-calendario.md` completo (DB7-01 a DB7-07, tramos, calendario, vía C y C′, precisiones del 2026-10-19).
- `docs/arquitectura/2026-10-18-db7-blueprint-v3.md`: secciones 4 (113 reglas), 5.1 a 5.5 (contratos), 6 (pipeline, cachés, eventos), 7, 8 (seguridad, ES256, sello), 10, 13. **No leí** las secciones 11, 12 y 14 a 15 (necesidades de datos, preguntas, conciliación, respuesta a la revisión), salvo lo que cita la sección 13.
- `docs/arquitectura/2026-09-29-estandar-acceso-multiempresa.md`: sección 8 completa (QA-01 a QA-94) y 2.1; **no leí** las demás reglas 2.2 a 2.11 salvo por el mapa del blueprint (sección 4).
- ADR-34, 35, 36 y 43: solo el texto de «Decisión», truncado a unos 3 500 caracteres cada uno (no leí sus «Consecuencias»).
- No leí `docs/datos/2026-10-18-db7-d0-modelo-datos.md` ni la revisión de seguridad D0 (SD0-xx) salvo lo que el blueprint cita. Donde un caso depende del texto exacto de una SD0, lo marco *(inferido)*.
- Código: `origin/feature/modelo-ng` `b9efa9fb`, por `git ls-tree` y `git grep`: `ApiMvpFactory.cs` (cabecera), existencia de `ILlaveFirmaTokens`, `ProveedorLlavesFirma`, `ComandoLlaveFirma` y sus pruebas (`tests/GPOS.Tests/Acceso/`), `TimeProvider` en 8 archivos de `GPOS.Api`, `bunit 2.*` en `GPOS.Web.Tests` (68 archivos). **No existe todavía** ningún símbolo de `ValidacionAcceso`, `Preautorizacion`, `EstadoAccesoService` ni `CupoEmpresas` (verificado por la ausencia en `git ls-tree`).

## 3. Convenciones

**Nivel:** U = unidad sin base. S = servicio con base `GPOS_TEST_*`. H = HTTP con la API real en memoria (`ApiMvpFactory` o su sucesora). **H2** = HTTP con **dos instancias** de la API sobre la misma base del sistema. ARQ = prueba de arquitectura sobre ensamblados o fuentes. TX = prueba textual. UI = bUnit en `GPOS.Web.Tests`. MED = medición (no corre en la suite normal). VM = laboratorio.

**Mutación:** el cambio mínimo al código de producción que debe poner la prueba en rojo. Regla de B/C: el desarrollador corre cada mutación marcada con `*` **una vez** localmente y lo anota en el PR. Todas están sin ejecutar (no hay código).

**Prioridad:** P0, P1, P2 (sección 9).

**Escenario común (EST §8), clase `EscenarioAcceso` (propuesta, `tests/GPOS.Tests/Acceso/`):**

| Pieza | Contenido |
|---|---|
| Empresas | **A** habilitada, cupo 3. **B** habilitada, cupo 10. **C** inhabilitada. Cada una con su base de empresa temporal y una sucursal «01» en A y en B (mismo código, para QA-13) y «02» en B |
| P | USER en A; sin membresía en B |
| Q | ADMIN en A y USER en B |
| R | ADMIN en B |
| S | SUPER (con TOTP sembrado) |
| T | sin membresías |
| V | miembro de A y de B, ADMIN solo en B |
| W | USER en A y `SUSPENDIDA` en B |

- Los códigos de cuenta y empresa llevan `Datos.Id` (único por prueba), como en P20 y T6.
- Una fixture compartida por clase (creación de bases cuesta), salvo las pruebas que mutan el escenario: esas usan su propia fixture o restauran con un `ReiniciarEscenarioAsync` que corre en transacción.
- **Reloj:** toda prueba de tiempo usa `TimeProvider` fake. `GPOS.Api` ya usa `TimeProvider` en 8 archivos (`RevocacionSesiones`, `DesafiosFactor`, `Program`, etc.). Supuesto: `ValidacionAcceso`, `Preautorizacion` y `PoliticaBloqueo` lo reciben por constructor (pregunta P-5). Sin `Thread.Sleep`.
- **Llave de firma en la suite:** en Debug la prueba usa la llave del almacén del usuario (`aprovisionar --llave-firma --desarrollo`, blueprint 8.2) o una llave ES256 de software registrada en `ProveedorLlavesFirma` por una costura de pruebas (pregunta P-1). La suite **no** depende de un TPM.
- **Una suite completa a la vez** (regla del proyecto). Las pruebas H2 y MED no corren dentro de la suite de integración continua; ver sección 9.

## 4. Suite de aislamiento (EST §8): qué QA se cubren, con qué nivel y qué mutante

Es la suite de D6, pero **se escribe por tramos**: cada fila dice desde qué tramo puede ponerse en verde. La fixture es `EscenarioAcceso`. «Ajuste» marca dónde el blueprint cambia el resultado esperado respecto de EST §8.

**Excluidas con motivo:** QA-09, 09b, 09c a 09e (fase 2, invitaciones); QA-67, 68, 74 a 76 y 85 (reglas retiradas por DB7-02, lista del blueprint 13.2); **QA-39 y QA-72** (migración «TODAS» y su reversión: no entran, DB7-01 3.3; las sustituye el ensayo CNV-xx de la sección 8) y **QA-70** (TRZ-07, fase 2: *inferido* de la sección 4.9 del blueprint, que lo marca «No entra»). **QA-49 a 54, 77 a 80, 91 a 93** son de ADR-82 y ADR-109: DB-7 solo las verifica (sección 8, VER-xx). **QA-71** cambia (ahora `/api/admin/usuarios*` responde 410 en GET y POST).

### 4.1 Identidad, inicio de sesión y selector de empresas

| ID | Caso (QA) | Nivel | Tramo / Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| AIS-01* | QA-01: P llama `identificar` | H | D2 / P0 | 200; `Empresas` = solo A; `SinEmpresas = false`; `EmpresaPreferida` solo si está en la lista | Q2 sin filtro de membresía: la lista trae B (rojo) |
| AIS-02* | QA-02: P pide `login` con empresa B, con C (inhabilitada) y con «ZZZ» | H | D2 / P0 | Los tres: 401 `INICIO_NO_VALIDO`, mismo cuerpo (comparado byte a byte tras quitar `traceId`) y tiempos del mismo orden (aserción laxa, no el umbral de QA-63) | Devolver 404 para «ZZZ»: cuerpo distinto |
| AIS-03* | QA-03: token de P (empresa A) con la firma alterada para decir `empresa=B` | H | D2 / P0 | 401 | `ValidateIssuerSigningKey = false`: 200 con datos de B |
| AIS-04 | QA-04: P llama `POST /api/auth/empresa {B}` | H | D2 / P0 | 404 `EMPRESA_NO_VALIDA`; una fila `ACCESO_EMPRESA_DENEGADO` en la bitácora **del sistema**, con `Empresa` NULL; cero filas en la base de B | Escribir la empresa afectada = B: la bitácora de B la mencionaría (rojo en QA-28b) |
| AIS-05 | QA-05: Q cambia de A a B | H | D2 / P0 | Token de B con nivel efectivo USER; `/api/admin/miembros` en B: 403; `SesionInfo.NivelEfectivo = USER` | Tomar el nivel de la cuenta en vez de la membresía: ADMIN en B |
| AIS-06 | QA-06: T se identifica | H | D2 / P0 | 200, `SinEmpresas = true`, mensaje de SES-11, **sin** preautorización | Emitir preautorización con lista vacía |
| AIS-07* | QA-07: anónimo, `GET /api/auth/empresas` y `GET /empresas/A/sucursales` | H | D2 / P0 | 410 `CLIENTE_DESACTUALIZADO` y 401; **ninguna conexión a la base de A** (contador en `EmpresasService` o traza del doble de la conexión) | Dejar la ruta con `AllowAnonymous`: lista de empresas (rojo) |
| AIS-08 | QA-08: Q crea la persona «R» (código existente) | H | D1 / P0 | 409 `CODIGO_NO_DISPONIBLE` sin detalle de dónde existe; fila `ALTA_NO_DISPONIBLE` en el sistema con `EmpresaActua` | Mensaje con «ya existe en la empresa B» |
| AIS-31 | QA-31: preautorización después de 5 min, y después de cambiar la clave | H | D2 / P0 | 401 `PREAUTORIZACION_VENCIDA` en los dos casos; con reloj fake (+5 min y +1 s) | Vigencia de 15 min; o no ligar al `SelloSeguridad` (la segunda variante) |
| AIS-32* | QA-32: 409 de sesión en uso para A; reenviar la confirmación con empresa B | H | D2 / P0 | 401; no se abre sesión; la sesión anterior queda intacta | El comprobante sin empresa: se abre sesión en B |
| AIS-33 | QA-33: Q entra a A (Web) y luego a B (MAUI) | H | D2 / P1 | 409 `SesionEnUso`; al confirmar, la sesión anterior pasa a `reemplazada` | Confirmación sin revocar |
| AIS-35 | QA-35: token de la versión anterior (HS256 y `ver = 1`) | H | D2 / P0 | 401 | Aceptar tokens sin `ver` |
| AIS-62 | QA-62 (ajuste H-1): S entra sin motivo; S inactivo 31 min; S con actividad hasta 4 h 01 | H | D2 / P1 | 400 `MOTIVO_INVALIDO`; 401 `inactiva`; 401 al pasar 4 h; **no** a las 2 h | Dejar 2 h: rojo en las dos últimas |
| AIS-65 | QA-65: `X-GPOS-Cliente` menor que la mínima; cliente viejo con `GET /empresas` | H | D2 / P0 | 426; 410 | Sin `VersionMinimaCliente` |
| AIS-71 | QA-71 (ajuste): `GET` y `POST /api/admin/usuarios` | H | D1 / P0 | 410 `RUTA_RETIRADA_ACCESO` en ambos; `GET /api/admin/usuarios/licencia` también | Dejar el GET de solo lectura (rojo) |

### 4.2 Membresía, privilegios y administración por empresa (la capa HTTP encima de P20)

| ID | Caso (QA) | Nivel | Tramo / Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| AIS-10 | QA-10: se vincula R a A (por el SUPER) | H | D1 / P1 | R sin perfiles ni excepciones en A | Copiar los perfiles de B |
| AIS-11 | QA-11: asignar en A un perfil de B | H | D1 / P0 | 400 `PERFIL_NO_VALIDO` | Validar solo que el perfil exista |
| AIS-12 | QA-12: política NIVEL=ADMIN en A, evaluada para Q en A y en B | H | D1 / P1 | Aplica en A, no en B | Leer `Usuarios.Nivel` |
| AIS-13 | QA-13: P restringido a la sucursal «01» de A (existe «01» en B) | H | D1+D2 / P0 | P entra a A/01; `POST /empresa {B}` falla por membresía; A/02: `SUCURSAL_NO_PERMITIDA` | Comparar la sucursal solo por código sin empresa |
| AIS-14* | QA-14: Q suspende a P mientras trabaja en A (misma instancia) | H | D1 / P0 | La **siguiente** petición de P: 401 `X-GPOS-Sesion: sin-acceso` | Caché de 15 s del estado |
| AIS-15 | QA-15 y QA-15b: Q suspende a V en A / fuerza su cierre en A mientras V está en B | H | D1 / P0 | La sesión de V en B sigue; un token de V para A emitido antes de la revocación: 401 `revocada` | Revocación global de la cuenta |
| AIS-16* | QA-16: Q degrada a otro ADMIN de A a USER en sesión | H | D1 / P0 | 403 en `/api/admin/*` desde la siguiente petición; `X-GPOS-Privilegios` cambia | `nivel` leído del token (AIS-03) |
| AIS-17 | QA-17 y QA-17b: Q lista las personas de A; Q se suspende a sí mismo; suspende al último ADMIN | H | D1 / P0 | Solo miembros de A (habilitados y suspendidos), sin R ni S; los dos intentos: 409 `ACCION_SOBRE_SI_MISMO` / `ULTIMO_ADMIN` | Listar por la cuenta sin filtrar la empresa |
| AIS-18 | QA-18: JSON de `MiembroDto` de V visto por Q | H | D1 / P0 | Sin empresa preferida, último acceso global, origen de la sesión ni otras empresas. **Prueba textual del JSON** contra una lista blanca de campos de `MiembroDto` (blueprint 5.3) | Agregar `Empresas` al DTO |
| AIS-19* | QA-19 y QA-94: Q vincula a R (R solo en B), a un código inexistente, y a otro en una empresa sin cupo | H | D1 / P0 | Mismo 404 `VINCULO_NO_ENCONTRADO` en los tres, **no** el 409 de cupo | Verificar cupo antes del ámbito |
| AIS-20 | QA-19b: Q configura el POS de «R» y pide la política efectiva de «R» en A | H | D1 / P0 | 404 `PERSONA_NO_EXISTE` | Dejar `/pos/usuarios` confirmando existencia |
| AIS-21 | QA-20: reporte personalizado de B por Id desde A; reenviar `rpt:{id}` de B | H | D5 / P1 | 404 idéntico al de un Id inexistente | Reportes sin `EmpresaCodigo` |
| AIS-22* | QA-21: Q intenta restablecer clave, inhabilitar o cambiar el nombre de P o V | H | D1 / P0 | 403 / 404 en todos; la ruta de restablecer no existe en `/api/admin` | Exponer el restablecimiento al ADMIN |
| AIS-23 | QA-22 y QA-22b: Q llama `/api/super/*`, carga del padrón RNC, edición de reporte del sistema; intenta crear o ver una cuenta SUPER | H | D1 / P0 | 403 (o variante); S no aparece en listas; `MEM-05`: `SUPER_SIN_MEMBRESIAS` | `RequiereAdmin` en la carga RNC |
| AIS-24 | QA-23: Q edita el perfil CAJERO en A | H | D1 / P1 | CAJERO de B intacto | Perfil sin llave de empresa |
| AIS-25* | QA-24 y QA-47: Q recorre todas las rutas de `/api/admin` buscando cifras de B o globales | H | D3 / P0 | `Autorizados`, `Consumidos`, `EnExceso` solo de A; ningún campo global (comparación del JSON contra una lista blanca) | `LicenciaEndpoints` devuelve el total de la instalación |
| AIS-27 | QA-27: alta, cambio de privilegios, suspensión y baja en A | S/H | D1 / P0 | Cuatro filas en la bitácora de acceso de A, con antes y después, **en la misma transacción**: se prueba abortando (fallo inyectado después del cambio y antes de `COMMIT`: no queda ni el cambio ni la fila) | Escribir la bitácora en otra conexión |
| AIS-27b | QA-27b: bitácora después de restablecer una clave y crear una cuenta | S | D1 / P0 | Sin claves, hashes, sellos ni comprobantes: la prueba busca el hash de la clave y el sello en todas las columnas de texto | Registrar `ValorDespues` con la entidad completa |
| AIS-27c | QA-27c: S inhabilita a P | H | D1 / P1 | Fila en la bitácora del sistema; ninguna visible en `GET /api/admin/bitacora` de A | `Empresa` = A en el evento de cuenta |
| AIS-28 | QA-28 y QA-28b: Q vincula a V; P intenta entrar a B | H | D1 / P0 | La bitácora de A no menciona B; la de B no tiene registros del intento | Texto del vínculo con el nombre de la empresa de origen |
| AIS-29 | QA-29: S entra a A con un motivo | H | D2 / P0 | El ADMIN de A ve «Ingreso del Super Usuario: <motivo>» en `GET /bitacora?fuente=acceso`; el campo de empresa que actúa se omite (TRZ-06) | Mostrarlo solo al SUPER |
| AIS-30* | QA-30: base del sistema inaccesible con token válido tras una petición exitosa | H | D1 / P0 | 503 `ACCESO_NO_DISPONIBLE` con `Retry-After: 5`; **cero** datos de empresa; EventId 4724 en el registro; no 401 | Usar el estado anterior (fail-open) |
| AIS-36 | QA-36: S inhabilita la cuenta de V en sesión | H | D1 / P0 | 401 `cuenta-inhabilitada` en la siguiente petición | Revisar solo al iniciar sesión |
| AIS-37* | QA-37: S inhabilita la empresa A | H | D1 / P0 | Sesiones en A: 401 `sin-acceso`; `EmpresasService` y `CachePermisos` vacíos para A; los dispositivos de A dejan de autenticar (SD0-12) | No llamar a `QuitarEmpresa` |
| AIS-38 | QA-38: S restablece la clave de P en sesión | H | D1 / P0 | Sesión cerrada (`credenciales`); al entrar, solo puede cambiar la clave | No renovar el sello |
| AIS-40 | QA-40: revisión estática | ARQ/TX | D1 / P0 | Ninguna ruta fuera de `/api/auth` y `/api/super/empresas/{c}/…` recibe empresa; ninguna autorización lee `Claims.Nivel` | Una ruta con `?empresa=` |
| AIS-41 | QA-41: P con `HABILITADA` en A, B y D | S | D3 / P0 | Consume 1 cupo en cada una | Cupo global |
| AIS-42 | QA-42: A sin cupo; el ADMIN de B da de alta | H | D3 / P1 | El alta en B no se afecta | Cupo compartido |
| AIS-43 | QA-43: S habilita una cuenta con `HABILITADA` en A (sin cupo) y en B | H | D3 / P0 | 409 con la lista de empresas (solo al SUPER); la cuenta sigue inhabilitada; consumo de B sin cambio | Habilitar y luego verificar |
| AIS-44 | QA-44 y QA-45: (ajuste) el cupo **ya no lo fija el SUPER** | TX | D3 / P1 | No existe `PUT /empresas/{c}/licencia`: 404 o 405. El cupo lo trae la licencia (ADR-58) | Dejar la ruta |
| AIS-46* | QA-46: dos ADMIN de A crean una persona a la vez con un solo cupo libre | S/H | D3 / P0 | Exactamente uno 201 y uno 409 `CUPO_EMPRESA_AGOTADO`; el consumo final es el cupo; 20 repeticiones. **Más** prueba de arquitectura: toda ruta que habilita llama a `ICupoEmpresas.VerificarAsync` (ver CUP-09) | `VerificarAsync` fuera de la transacción o sin tomar el padrón |
| AIS-48 | QA-48: baja o suspensión libera cupo; reactivar sin cupo | H | D3 / P0 | Libera; reactivar sin cupo: 409 | Contar `SUSPENDIDA` |
| AIS-55 | QA-55: HS256 con la clave anterior; `alg: none`; ES256 con `jwk`, `jku`, `x5u` o `x5c` | H | D2 / P0 | 401 en todos; la llave del encabezado jamás se usa (la prueba firma con una llave ajena y la inserta en `jwk`) | `TryAllIssuerSigningKeys = true` o aceptar `jwk` |
| AIS-56 | QA-56: ES256 con `kid` retirado | H | D2 / P0 | 401 | Resolver sin `kid` |
| AIS-57 | QA-57 (ajuste a TPM): Release sin llave, con llave exportable o `Jwt:KidsValidos` sin la huella | S/ARQ | D2 / P1 | La API no arranca; EventId 4728. En la suite solo por la **costura** del validador de arranque (`ValidarArranque(opciones, proveedor)`); en el TPM real, VM | Arrancar con un aviso |
| AIS-58* | QA-58: Q desbloquea a W (suspendida en B) y a P (bloqueo global) | H | D1 / P0 | W: 403 `DESBLOQUEO_NO_PERMITIDO`; P: 204, `BloqueadoHasta` vacío y `FallosVentana = 0`; el siguiente fallo no la bloquea | Desbloquear sin revisar las otras membresías (P20 T1-3 #38 cubre Q10) |
| AIS-59 | QA-59: cuenta con «debe cambiar la clave» llama `/api/reportes` y `/api/admin/miembros` | H | D1 / P0 | 403 `CAMBIO_CLAVE_OBLIGATORIO`; `/api/auth/clave`, `/salir` y `/sesion` funcionan | Leer el claim, no el estado |
| AIS-60* | QA-60: dos instancias; Q suspende a P en la 1 mientras P trabaja en la 2 | **H2** | D1 / P1 | La siguiente petición de P en la 2: 401 `sin-acceso` (0 s) | Caché de estado de 15 s (rojo solo con dos instancias) |
| AIS-64 | QA-64: 5 fallidos de P desde IP 1; P entra desde IP 2; 5 fallidos de un código inexistente; 20 fallidos de P desde varias IP; 10 + acierto + 10 en la misma ventana | H | D2 / P0 | IP 1 bloqueada (423 neutro) e IP 2 entra; el inexistente recibe el mismo 423; global con `CuentaBloqueada`; en el último caso hay bloqueo global (el acierto no reinicia la ventana, D-9). La IP viene de `LimitesPeticiones.Ip` (`X-Forwarded-For` falso no engaña) | Bloqueo solo por cuenta |
| AIS-66 | QA-66: baja de P en A y nuevo vínculo | S | D1 / P0 | Fila conservada en `BAJA` con motivo; al volver, versión mayor | (cubierto en P20 T1-3; aquí solo HTTP) |
| AIS-69 | QA-69: Q hace 21 altas o vínculos en una hora | H | D1 / P0 | La 21.ª: 429; a la hora y 1 s (reloj fake): vuelve a permitir; cuenta por ADMIN, no por IP | Límite por IP |
| AIS-81 | QA-81: 20 fallidos desde varias IP con un código inexistente; después, una IP nueva | H | D2 / P1 | Mismo 423 que una cuenta real | 401 distinto |
| AIS-84 | QA-84: clave de 7 caracteres, de la lista de comunes (mayúsculas y espacios) y con el código de la cuenta; entrar con clave vigente de 6 | H | D1 / P1 | 400 (SES-16) en los tres; la vigente entra. **Más** el caso SD0-04: persona ADMIN en A y USER en B cambia su clave desde B: se exigen 12 caracteres | Política por nivel de la sesión, no de la persona |
| AIS-86 | QA-86: cambio de un permiso por SQL sin subir la versión | S/H | D1 / P1 | Aplica a más tardar a los 5 min (reloj fake a 5 min 1 s) | `CachePermisos` sin vencimiento |
| AIS-87 | QA-87: `INSERT` de `BitacoraAcceso` | TX/S | D1 / P1 | El texto SQL generado no incluye `Fecha`; el `INSERT` con fecha de hace 1 h falla por el `CHECK` | `Fecha = DateTime.Now` desde C# |
| AIS-88 | QA-88 (parcial): ACL del archivo de configuración y de la carpeta del anillo | VM | D6 / P2 | Solo administradores escriben; la identidad de la API lee | — |

## 5. D2 · Inicio de sesión, preautorización, token y llave

Fuente: blueprint 5.2, 6.1, 8.1, 8.2. Los casos «AIS-xx» de arriba son la capa de aislamiento; estos son los de contrato y de seguridad de D2.

### 5.1 `identificar`, preautorización y `login`

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| PRE-01* | Contenido de la preautorización | U | P0 | Protegida con el propósito `GPOS.Login.Preautorizacion`; trae `{v:1, cuenta, selloSeguridad, amr, authTime, jti}`; vigencia 5 min exactos (borde: válida a +4:59, vencida a +5:01) | Otro propósito: se podría descifrar con el de otro componente (prueba cruzada con otros propósitos del anillo) |
| PRE-02* | Un solo uso en `login` | H | P0 | Segundo `login` con la misma preautorización: 401; `GET /sucursales` **no** la consume (se puede llamar tres veces y luego hacer `login`) | Consumir en `sucursales` o no consumir en `login` |
| PRE-03* | Cambio de `SelloSeguridad` invalida (IDN-04) | H | P0 | Tras cambiar la clave, restablecer o inhabilitar-habilitar, la preautorización previa da 401 | No comparar el sello |
| PRE-04 | Preautorización de la cuenta X usada con `Usuario = Y` | H | P0 | 401 `INICIO_NO_VALIDO` | No comparar cuenta con `Usuario` |
| PRE-05 | Preautorización con `amr` sin `otp` para el SUPER | H | P0 | `login` del SUPER sin `otp`: 401 / 202 según contrato (pregunta P-7); jamás token | Ignorar `amr` |
| PRE-06 | Reinicio de la API (nueva instancia de `Preautorizacion`) | U | P2 | **Caracterización** de R-DB7-14: tras reinicio, una preautorización no vencida **vale** (la prueba documenta el residual; si se cierra, se invierte) | — |
| PRE-07 | Empresas de la lista con sello de membresía inválido | H | P1 (D3) | Una membresía cuyo sello no verifica no aparece en `identificar` (Q2 con SD0-03) | Listar por columna `Estado` sin sello |
| PRE-08 | `identificar` del SUPER | H | P1 | Ve todas las empresas habilitadas (A, B; no C); `EsSuper = true` | Filtrar por membresías |
| PRE-09 | 202 con desafío cuando la cuenta exige factor; `identificar/factor` entrega la preautorización con `amr = [pwd, otp]` | H | P1 | Contrato de la fase A reubicado; `login/alta` y `login/factor` antiguos: 404 o 410 *(inferido; pregunta P-7)* | Dejar las rutas viejas vivas |
| PRE-10 | `SISTEMA_RESTAURADO`: 503 a quien no es SUPER **después** de la contraseña | H | P2 | Sin la contraseña correcta no se revela el estado | Responder 503 antes de validar |
| LOG-01* | `login` v2 exige exactamente uno de `Preautorizacion` o `Confirmacion` | H | P0 | Ninguno o ambos: 400; con `Clave` en el cuerpo: respuesta fijada por P-2 (supuesto: `Clave` se ignora y se exige la preautorización; nunca autentica) | Aceptar `Clave` como en un paso |
| LOG-02 | `Motivo` obligatorio para el SUPER (10 a 500 caracteres, validado **después** de la preautorización) | H | P0 | 9 y 501 caracteres: 400 `MOTIVO_INVALIDO`; 10 y 500: pasa; sin preautorización válida: 401, no 400 | Validar el motivo primero (oráculo de cuenta) |
| LOG-03* | El 409 `SesionEnUso` va **después** de validar la membresía (SES-04) | H | P0 | P pide B con sesión activa en otra parte: 401 `INICIO_NO_VALIDO`, no 409 | 409 antes de la membresía: filtra que la cuenta tiene sesión |
| LOG-04 | Comprobante del 409 ligado a cuenta, empresa, sucursal, sello y `amr` | H | P0 | Cambiar cualquiera de los cinco: 401 (una variante por campo, teoría) | Omitir `amr` del ligado |
| LOG-05 | Hash ficticio en todo camino de fallo (SES-02) | U | P1 | Con cuenta inexistente, inhabilitada, sin sello y bloqueada se invoca el verificador de hash exactamente una vez (doble del verificador con contador) | Retorno anticipado sin hash |
| LOG-06 | Tiempos (QA-63 y QA-82) | **MED** | P2 | 100 muestras por caso; diferencia de medianas < 20 % (propuesta de QA-63, a confirmar). **No va en la suite**: es ruidosa | — |
| LOG-07 | `SucursalDefault` y `RestringirSucursal` salen de la **membresía** | H | P0 | Dos empresas con sucursal predeterminada distinta: el token de cada una trae la suya | Leer de la cuenta |
| LOG-08 | `GET /empresas/mias` | H | P1 | Solo membresías `HABILITADA` con sello válido; con empresa inhabilitada, no aparece | Incluir `SUSPENDIDA` |
| LOG-09 | `POST /clave` revalida la membresía antes de emitir | H | P1 | Membresía suspendida entre el login y el cambio: 401, sin token nuevo | Emitir sin revisar |
| LOG-10 | `GET /sesion` y `/sesion/info` | H | P1 | 204 + `X-GPOS-Privilegios`; `SesionInfo` con nivel efectivo, accesos, áreas y versión; con cambio de clave pendiente `/sesion/info` da 403 | Nivel del token |

### 5.2 Cambio de empresa y SUPER

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| EMP-01* | Cambiar de A a B conserva `sid`, `amr` y `auth_time` | H | P0 | Mismo `sid`; sesión única: la anterior de la cuenta sigue siendo esta | Nuevo `sid`: la sesión se reemplaza a sí misma |
| EMP-02 | Tras el cambio, el token de A deja de valer | H | P1 | Token de A: 401 `reemplazada` o equivalente *(inferido; pregunta P-8)* | Dos tokens vigentes |
| EMP-03* | SUPER: `Motivo` obligatorio **en cada cambio** de empresa | H | P0 | Sin motivo: 400; con motivo: una fila `INGRESO_SUPER` por cambio, con la empresa afectada | Motivo solo en el primer ingreso |
| EMP-04 | SUPER sin membresías entra a A | H | P0 | Nivel efectivo SUPER; **no** consume cupo; no aparece en `GET /miembros` | Crear membresía implícita |
| EMP-05 | Cambio a una empresa inhabilitada o sin membresía | H | P0 | 404 `EMPRESA_NO_VALIDA`, igual para los dos casos y para una inexistente | Mensajes distintos |
| EMP-06 | Cambio de empresa con sucursal restringida de la membresía de destino | H | P1 | `SUCURSAL_NO_PERMITIDA` si pide otra | Validar con la de origen |

### 5.3 Bloqueo, versión mínima y rutas retiradas

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| BLQ-01 | Contadores (cuenta, IP) vencen a los 15 min | U | P0 | Reloj fake +15:00 libera; +14:59 no | Ventana deslizante |
| BLQ-02 | Tope de 100 000 entradas | U | P1 | 120 000 códigos distintos: no supera el tope, la API sigue respondiendo; alerta al SUPER (QA-83). Prueba con tope reducido por opciones (supuesto) para que corra en segundos | Sin tope: memoria sin límite |
| BLQ-03* | Los contadores se confirman en su propia sentencia y el evento se escribe después | S | P0 | Con el evento retirado del catálogo (o `INSERT` de bitácora fallando), el bloqueo se aplica igual, la respuesta es la misma y queda el EventId 4734 en el registro (SD0-07) | Una transacción para ambos: el bloqueo se pierde |
| BLQ-04 | El bloqueo de una cuenta no se levanta con un inicio exitoso de otra IP en la misma ventana (D-9) | H | P0 | (Parte de AIS-64) | Reiniciar contadores en el acierto |
| ACC-01* | Precedencia de motivos en la canalización (6.1 paso 3) | H | P0 | Teoría: cuenta inhabilitada + sello de membresía inválido, sesión reemplazada + membresía suspendida, `iat` revocado + empresa inhabilitada: gana el primer motivo de la tabla (`cuenta-inhabilitada`, `reemplazada`, `revocada`); sin 503 ni 500 | Evaluar membresía antes que cuenta |
| VER-01 | `VersionMinimaCliente` | H | P0 | `X-GPOS-Cliente` ausente, mal formado o menor: 426; igual: pasa | Comparar como texto (`1.10` < `1.9`) |
| VER-02 | `Jwt:Clave` | S/TX | P0 | `JwtOpciones.Clave` no existe (reflexión); con `Jwt:Clave` con valor en Release la API no arranca (por la costura); ningún `appsettings*.json` la trae | Dejar la propiedad |
| VER-03 | Token de dispositivo (SD0-12) | H | P1 | Firmado con ES256 por `kid`; emisión con empresa inhabilitada o módulo inactivo: rechazada; un token HS256 de dispositivo: 401 | Seguir con `Jwt:Clave` |

### 5.4 Token ES256 y llave de firma

(`ILlaveFirmaTokens`, `ProveedorLlavesFirma` y `ComandoLlaveFirma` ya existen con pruebas en `tests/GPOS.Tests/Acceso/`; no las repito. Esto es lo que agrega D2.)

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| TOK-01* | Encabezado y claims | U/H | P0 | `alg=ES256`, `typ=JWT`, `kid` = SHA-256 hex mayúsculas de la llave pública; `iss`, `aud` (dos audiencias), `ver=2`, `sid`, `jti`, `iat`, `nbf`, `exp` presentes | Sin `ver` |
| TOK-02* | `iss` y `aud` se validan | H | P0 | Token firmado con la llave válida pero con otro `iss` o sin la audiencia de la API: 401 | `ValidateIssuer = false` |
| TOK-03* | `TryAllIssuerSigningKeys = false`: token sin `kid` | H | P0 | 401 aunque la firma sea válida con la llave activa | Probar todas las llaves |
| TOK-04 | `ValidTypes = [JWT]` | H | P1 | `typ` distinto: 401 | Sin la restricción |
| TOK-05* | `nivel`, `cambiar_clave` y los claims `permiso` del token **no autorizan** | H | P0 | Token válido (firmado con la llave de pruebas) con `nivel=ADMIN`, `permiso=*` y `nivel_efectivo=ADMIN` en la identidad del token, para P: `/api/admin/miembros` da 403. Esto cubre 6.1 paso 5 y SD0-15 | `HasClaim` en todas las identidades (como hoy, `Seguridad.cs:240-246`) |
| TOK-06 | `exp` | U | P1 | `Jwt:HorasVigencia` = 12 h; SUPER: el tope de `OpcionesSesion`; con `Jwt:Firma:SinTpm` = 8 h y 1 h | Vigencia fija |
| TOK-07 | Rotación normal | H | P1 | Con dos `kid` válidos, tokens de ambos pasan; al retirar el viejo, 401 solo a los del viejo | Cache de llave sin invalidar |
| TOK-08 | Rotación de emergencia | H/VM | P2 | Solo el `kid` nuevo + reinicio: todo token anterior 401; objetivo de 15 min es VM | — |
| LLV-01 | Arranque en Release: falta la llave activa, llave exportable, `kid` de la lista sin llave, identidad sin permiso de uso, `KidsValidos` vacía o sin el `kid` activo | S | P1 | No arranca; EventId 4728 en cada caso (teoría de 6 filas sobre la costura de validación de arranque) | Arrancar con aviso |
| LLV-02 | `--sin-tpm` sin `--motivo` o con motivo de 9 caracteres | S | P1 | `aprovisionar` rechaza; con `--motivo` de 10 a 200 deja `Jwt:Firma:SinTpm` con fecha; nunca cae solo al Software KSP | Caer solo al KSP |
| LLV-03 | Con la marca `SinTpm`: aviso por llave de más de 30 días y EventId 4735 en cada arranque | S | P2 | Con reloj fake +31 días: aviso; 4735 y un evento `SISTEMA` por arranque | Sin evento |
| LLV-04 | `verificar` informa proveedor y antigüedad de la llave | S | P2 | Salida contiene ambos datos | — |
| LLV-05 | Firma con TPM real | VM | P2 | Ensayo de D6 en equipo con TPM: crea, firma, `exportable = no` (`certutil`/CNG), rota; medir firma (R-DB7-05) | — |

## 6. D3 · Sellos, padrón y cupo

Fuente: blueprint 8.4, 6.1 (pasos g), 8.3. P20 solo tiene los centinelas `Centinela=D3` (T1-2 #8, T1-3 #37, #39, #41 y la prueba `En_D1_la_marca_indica_sin_sello`); **cada uno se invierte en D3** (lista en la sección 7).

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| SEL-01* | Sello de cuenta v2: contenido y propósito | U | P0 | Propósito `GPOS.Usuarios.Sello.v2`; campos `InstalacionId, Codigo, EsSuper, Inhabilitado=0, HuellaClave, FactorAlta, HabilitadoUtc`; cambiar uno cualquiera en la fila y verificar da `credenciales` (teoría por campo) | No incluir `HuellaClave`: un `UPDATE PasswordHash` pasa |
| SEL-02* | Sello de membresía v1: subpropósito `{Codigo}\|{Empresa}` | U | P0 | Un sello copiado de la fila (c, A) a la fila (c, B) no verifica (desciframiento falla) | Subpropósito fijo: reutilizable entre empresas |
| SEL-03* | `UPDATE` por SQL de la membresía | S | P0 | Cambiar `Nivel` USER→ADMIN, `Estado` SUSPENDIDA→HABILITADA, `RestringirSucursal` o la sucursal por SQL: petición 401 `credenciales`; `MEMBRESIA_SIN_SELLO` en la bitácora (clase SEG-L2-01) | Comparar solo contra la fila |
| SEL-04* | Sello de otra cuenta pegado a la membresía | S | P0 | `Valido` falso (el campo `c` no coincide) | No comparar `c` |
| SEL-05 | `m(c,E)` ausente del padrón verificado | S | P0 | `FueraDePadron` = rechazo; el acceso se niega | Tratar ausencia como válido |
| SEL-06* | Cuenta SUPER o inexistente en `Cuentas` | S | P0 | Membresía de `c` con `a(c)` ausente o `EsSuper`: rechazo (SD0-03) | No exigir `a(c)` |
| SEL-07 | Toda transición sella | S | P0 | `HABILITADA`↔`SUSPENDIDA`→`BAJA`, cambio de nivel, de restricción o de sucursal: el sello nuevo coincide con la fila y el padrón se reescribe (teoría de 6 transiciones) | Olvidar sellar en `reactivar` |
| SEL-08 | Reactivar por SQL deja el estado sellado en SUSPENDIDA | S | P0 | (SEL-03 variante) | — |
| SEL-09 | `BAJA` sale del padrón y su fila queda sellada con `BAJA`; volver reutiliza la fila, sube la versión y pasa por el cupo | S | P0 | Consumo no cuenta `BAJA`; reutilizar da versión mayor | Dejar la membresía en el padrón |
| SEL-10 | Entrada de cuenta por **cada** cuenta habilitada y sellada, SUPER o no (P-D0-D01) | S | P0 | Reponer un par antiguo (hash, sello) de una cuenta que no es SUPER: rechazado por huella12 distinta | Solo entradas del SUPER |
| SEL-11 | Inhabilitar una cuenta la quita de `Cuentas` y deja de contar | S | P0 | Sus membresías siguen en el padrón; consumo de A baja en 1 | Seguir contando |
| SEL-12 | Memoria criptográfica: llave `(SHA-256 del sello, versión del padrón, época del anillo)` | U | P1 | Cambiar una columna de la fila **no** reutiliza un resultado viejo (la comparación con la fila se rehace); cambiar el sello cambia la llave; tope de 20 000 y vencimiento de 5 min (reloj fake); `época++` vacía | Memorizar el resultado de la comparación con la fila |
| SEL-13 | La memoria no guarda estado de la fila | ARQ/TX | P1 | La llave y el valor memorizados solo contienen el resultado de `Unprotect` y la versión | Guardar `Nivel` |
| SEL-14 | Padrón v2: cabe con 1 000 cuentas y 5 empresas | S | P1 | Sirve la fila y el archivo; tamaño ≈ 0,7 MB (aserción ≤ 1,5 MB); escritura < 50 ms (aviso, no falla) | Tipo de columna corto |
| SEL-15 | Padrón: archivo `Licencia\padron` ausente | S | P1 | `PadronDiscoAusente` hasta repetir (R-DB7-15); la conversión sale con código ≠ 0 | Silenciar el fallo |
| SEL-16 | Orden de bloqueos padrón → `Usuarios` → `UsuariosEmpresas` → bitácora | S/H | P0 | 20 hilos mezclando alta, vínculo, suspender, reactivar, baja y habilitar cuenta: **cero interbloqueos 1205** y consumo final consistente | Tomar `UsuariosEmpresas` antes del padrón: 1205 |
| SEL-17 | `sellos --legitimar --empresa` / `POST …/legitimar` | H | P1 | Exige motivo, factor y cupo; sin cupo: 409; registra `MEMBRESIA_LEGITIMADA` | Legitimar sin cupo |
| SEL-18 | ADR-79: la reprotección conjunta recorre los dos tipos de sello | S | P1 | Tras `reproteger`, cuentas **y membresías** verifican con el anillo nuevo; si una falla, no cambia ninguna (todo o nada); la época sube | Recorrer solo cuentas |
| SEL-19 | `accesos --convertir` sella (D3) | S | P0 | Invierte `En_D1_la_marca_indica_sin_sello`: marca `MEMBRESIA.v1` final; todas las membresías verifican; padrón escrito después del `COMMIT` | Seguir sin sellar |
| CUP-01 | Consumo desde el padrón, no desde las columnas | S | P0 | Reactivar por SQL una membresía no suma consumo (porque su sello no verifica) | Contar columnas |
| CUP-02 | `EnExceso` por empresa | S | P0 | Cupo licencia 2, consumidos 3 (licencia bajada): `EnExceso = true` solo en esa empresa; nadie pierde la sesión; altas, vínculos, reactivaciones y habilitar cuenta: 409 (cuatro rutas, teoría) | Cortar sesiones |
| CUP-03 | El SUPER no consume ni se cuenta en `Autorizados` | S | P0 | — | Contarlo |
| CUP-04 | El cupo viene de la licencia por empresa (ADR-58); empresa sin cupo en la licencia | S | P1 | Sin entrada de licencia: habilitar la empresa falla (QA-45 ajustado) | Cupo infinito |
| CUP-05* | `ICupoEmpresas.VerificarAsync` se invoca con el padrón tomado y dentro de la transacción | S | P0 | Fallo inyectado después de verificar y antes del `COMMIT`: el cupo no se consumió; el padrón no cambió | Verificar fuera de la transacción |
| CUP-06 | Orden autorización → ámbito → cupo (QA-94) | H | P0 | Teoría de 3 casos sin permiso/fuera de ámbito/sin cupo: 403/404/409 respectivamente, cada uno solo | Cupo antes del ámbito |
| CUP-07 | Habilitar una cuenta: todo o nada en N empresas | S | P0 | Con 3 empresas, una sin cupo: ninguna cambia (QA-43 a nivel servicio); la respuesta lista las empresas solo al SUPER | Habilitar y compensar |
| CUP-08 | Concurrencia: SUPER habilita la cuenta mientras un ADMIN da de alta en la misma empresa con un solo cupo | S | P1 | Uno gana, el otro 409; sin 1205 | Dos bloqueos distintos |
| CUP-09* | Arquitectura: toda ruta que habilita llama al método único (CMB-10) | ARQ | P0 | Los métodos que escriben `Estado = 'HABILITADA'` o `Habilitado = 1` solo existen dentro de `CupoEmpresas`/`MembresiasService` tras `VerificarAsync` (análisis de IL o texto de las constantes SQL) | Un `UPDATE … SET Estado='HABILITADA'` nuevo en otro servicio |
| CUP-10 | `GET /api/super/licencia/{empresa}/consumidores` | H | P1 | Solo consumidores de esa empresa | Los de la instalación |
| CUP-11 | `LicenciaEmpresaDto` del ADMIN | H | P0 | (Parte de AIS-25) | — |

## 7. Centinelas de D1 que D3 invierte (lista para el desarrollador)

De P20 y V2 (cito su número): T1-2 #8 `D1_el_sello_de_membresia_aun_no_se_exige`; T1-3 #37, #39 y #41 (`D1_*`); T1-4 `En_D1_la_marca_indica_sin_sello` (V2 4.1). Cada una debe invertirse en el PR de D3 y el desarrollador pega en el PR el «antes (verde por la caracterización) / después (verde por la regla nueva)». Si alguna sigue verde sin tocarla, D3 no hizo su trabajo. La prueba de arquitectura `Centinela_D3_ninguno_pendiente_al_unir_D3` (TX: ningún atributo `Centinela=D3` en `tests/`) cierra la lista.

## 8. D5 · Bitácora, notificaciones, introspección; D4 · interfaces; D6 · cierre

### 8.1 D5

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| BIT-01* | Purga por categoría | S | P1 | `ACCESO`/`MEMBRESIA`/`CUENTA`/`NOTIFICACION`: 5 años; `SISTEMA`: 2 años salvo `ACCESOS_CONVERTIDOS_INSTALACION` (5); `FACTOR`/`SELLO`/`LICENCIA`: 2. Con reloj fake en 5 años menos un día y más un día. P20 T1-1 fase 6 cubre el procedimiento; aquí, que **la tarea de purga lo invoque** y no el DELETE de 2 años fijos (`EsquemaRestauracionSistema.cs:49-53`) | Mantener los 2 años fijos |
| BIT-02 | La API no puede `UPDATE`/`DELETE` sobre la bitácora | S | P1 | (QA-53b) con el login de la API: 229/ error de permiso | Dar `db_datawriter` |
| BIT-03* | Visibilidad del ADMIN | H | P0 | `GET /bitacora?fuente=acceso`: solo `ACCESO` y `MEMBRESIA` con `Empresa` = la suya; `fuente=ambas` agrega el `Log` de negocio; nunca filas de B; en cada fila el campo de empresa que actúa se omite | Filtrar solo por `Empresa` sin categoría: veria `CUENTA` |
| BIT-04 | `INGRESO_SUPER` visible; `ACCESO_EMPRESA_DENEGADO` no | H | P0 | (AIS-29, AIS-04) | — |
| BIT-05 | Catálogo al arrancar | S | P1 | Evento de `EventosSeguridad` sin fila en `CatalogoEventosSeguridad`: Release no arranca, EventId 4733 (P20 T1-1 #56) | — |
| BIT-06 | Bitácora del SUPER | H | P1 | `GET /api/super/bitacora` con filtros cuenta/empresa/categoría; el ADMIN: 403 | — |
| NOT-01* | `TrabajoNotificaciones` ejecuta con el estado real del autor | S/H | P0 | Autor USER **sin** «Ver costos» programa un reporte con costos: el archivo enviado **no** trae costos (SD0-05, cierra O175-01) | Principal sintético de ADMIN (código actual) |
| NOT-02* | Autor dado de baja o suspendido en la empresa | S | P0 | La regla no corre; queda suspendida con `REGLA_NOTIFICACION_SUSPENDIDA` (QA-25) | Ejecutar igual |
| NOT-03 | Autor con membresía sin sello válido | S | P1 | La regla se suspende | Validar sin sello |
| NOT-04 | Autor sin permiso del reporte | S | P0 | No corre (QA-26) | — |
| NOT-05 | Identidad de cola y reintentos | S | P1 | `SISTEMA`, sin nivel ADMIN y sin acceso a reportes | Reintentar como ADMIN |
| NOT-06 | Aislamiento de reglas entre empresas | S | P0 | Regla de A no se ejecuta con datos de B aunque el autor sea Q (ADMIN de A, USER de B) | Empresa de la sesión del autor al azar |
| INT-01* | Introspección v2 sin caché del acceso | H/S | P0 | Suspender la membresía y llamar de inmediato a la API de reportes: rechazada con `sin-acceso`; se quitó la caché de 15 s (`VerificadorIntrospeccion.cs:29-30`) | Dejar la caché |
| INT-02* | La API de reportes decide solo con la respuesta v2 | H | P0 | Un token con `nivel=ADMIN` falso en el claim (llave de pruebas) para P (USER): no puede diseñar; `cambio_clave` rechazado por el estado, no por el claim | Leer el claim `nivel` (`AutenticacionIntrospeccion.cs:77`) |
| INT-03* | Restricción de sucursal en reportes | H | P0 | Membresía restringida a S1: la API de reportes no devuelve filas de S2 (prueba de D5, blueprint 5.5) | Restricción solo en la principal |
| INT-04 | Versión 1 de la solicitud | H | P1 | Rechazada tras el despliegue (`Version: 1`) | Aceptar v1 |
| INT-05 | Motivos de rechazo | U | P1 | Teoría con los 11 motivos; los de sesión viajan en `X-GPOS-Sesion` | — |
| INT-06 | `rptsis.PermisoEfectivo` v2 | S | P1 | Llave `(Usuario, EmpresaCodigo)`; el mismo usuario con permisos distintos en A y B devuelve cada uno | Sin `EmpresaCodigo` |
| INT-07 | `rptsis.Membresia` y `SesionUsuario` no autorizan | ARQ/TX | P1 | Ninguna rama de autorización de `GPOS.Reportes.Api` los lee | — |
| INT-503 | Q1 detrás de una transacción de administración (R-DB7-12, SD0-16) | S/H | P1 | Una transacción de `MembresiasService` mantenida abierta 3 s con el padrón tomado: la petición de otro usuario responde 503 `ACCESO_NO_DISPONIBLE` a los 2 s (`CommandTimeout`), **no 401** y no usa estado viejo; al liberar, vuelve a 200 | Capturar el timeout como 401 |
| INT-08 | Reportes por empresa (PRV-07, P-D0-08) | H | P1 | Un reporte creado en A no existe en B; `rpt:{id}` de A usado en B: 404 (AIS-21) | — |

### 8.2 D4 (Web y MAUI), con bUnit en `GPOS.Web.Tests` (ya referenciado) y sin dispositivo

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| UIX-01 | `Login`: dos pasos | UI | P1 | Paso 1 muestra usuario y clave; con respuesta `Empresas` de N elementos, paso 2 ofrece solo esas; con `SinEmpresas`, el mensaje de SES-11; con 202, pide el factor | Mostrar un campo de empresa libre |
| UIX-02 | Sin lista anónima | UI/TX | P1 | La pantalla no llama a `GET /api/auth/empresas`; el cliente HTTP no tiene ese método | Dejar la llamada |
| UIX-03* | `X-GPOS-Sesion` | UI | P1 | `sin-acceso` y `cuenta-inhabilitada` llevan a la pantalla de ingreso con su mensaje; `inactiva`, `reemplazada`, `revocada` cada uno el suyo | Tratarlos todos como «sesión vencida» |
| UIX-04* | `X-GPOS-Privilegios` distinto recarga `GET /sesion/info` y redibuja el menú | UI | P1 | El menú oculta «Personas y accesos» al perder ADMIN en la siguiente respuesta | No recargar |
| UIX-05 | Cambio de empresa descarta estado (SES-09) | UI | P1 | Menú, `EstadoReportes`, catálogos y `SesionInfo` se reinician; no queda ningún dato de A en B (sembrar un valor centinela en cada servicio con estado) | Reutilizar el servicio de catálogos |
| UIX-06 | «Personas y accesos» | UI | P1 | Lista solo `MiembroDto`; errores `CUPO_EMPRESA_AGOTADO`, `ULTIMO_ADMIN`, `VERSION_PRIVILEGIOS` con su mensaje; la baja pide motivo | — |
| UIX-07 | «Cuentas» visible solo para SUPER | UI | P1 | Sin SUPER no se ve la ruta | — |
| UIX-08 | `LicenciaUsuarios.razor` muestra solo la empresa de la sesión | UI | P1 | — | Totales globales |
| UIX-09 | `X-GPOS-Cliente` en todas las peticiones; 426 muestra «Actualice la aplicación» | UI | P1 | — | Omitir la cabecera |
| UIX-10 | MAUI | VM | P2 | Los componentes Razor compartidos corren en `GPOS.UI.MAUI.Tests` (si existe cobertura); la prueba en dispositivo es manual (siguiente fase del `CLAUDE.md`) | — |

### 8.3 D6 · Mediciones, ensayos y verificaciones sin construcción

| ID | Caso | Nivel | Prio | Esperado | Mutación |
|---|---|---|---|---|---|
| MED-01 | Q1 p95 (QA-61, ADR-36, R-DB7-01) | MED | P1 (D1) | 10 000 llamadas con 1 000 cuentas y 5 empresas, base con datos (no vacía), plan en caché caliente y frío. Se informa p50/p95/p99, **lecturas lógicas** y número de viajes. Umbral: p95 ≤ 2 ms (ADR-36); además T-28 y T-57 dentro de sus topes. **Medir en D1, no esperar a D6** (R-DB7-01). Instancia: la de pruebas (Express o Standard, a anotar) | — |
| MED-02 | Firma ES256 con TPM (R-DB7-05) | MED/VM | P2 | 100 firmas; p95 < 100 ms | — |
| MED-03 | Escritura del padrón (R-DB7-06) | MED | P2 | < 50 ms con 1 000 cuentas | — |
| MED-04 | Ráfaga de inicios de sesión | MED | P2 | 50 `identificar` + `login` en paralelo: sin 1205 ni 503 | — |
| CNV-01 | Ensayo de `accesos --convertir` sobre una copia del DEMO | S/VM | P0 (D6) | Q23 sin diferencias (P20 T1-4 #2); idempotencia (segunda corrida informa «ya convertido»); `ACCESOS_CONVERTIDOS` por empresa y `ACCESOS_CONVERTIDOS_INSTALACION`; todos los accesos verifican sello | — |
| CNV-02 | Tras convertir, el escenario EST §8 corre completo | S | P0 | Reconstruir P…W **con el verbo** (no con inserciones) y ejecutar la sección 4: la conversión no deja un estado que la suite de aislamiento no ve | — |
| CNV-03 | Cuenta con ADMIN en la base anterior queda ADMIN en las empresas con acceso | S | P0 | (P20 T1-4 #2 lo cubre en datos; aquí la capa de sellos y petición) | — |
| VER-04 | M-1: `GPOS.Migracion verificar` exige `gpos_app_*` | S | P2 | Verificación, no construcción (ADR-82) | — |
| VER-05 | M-2 y M-4 (ADR-109, punto 4 de ADR-82) | TX | P2 | Solo se comprueba que las pruebas de esas piezas existan y estén verdes | — |
| VER-06 | M-3: SUP-05 y RQ-R12 | H/ARQ | P0 | ADMIN en modo código: 403 en crear, editar, importar, previsualizar y aprobar (QA-52). Escape: valor centinela `@{…}` y la imagen con `svg+xml`/no base64/mayor de 2 MB en **todas** las propiedades de texto de `DisenoVisual` por reflexión; la plantilla generada no tiene arroba sin escapar (QA-53) | Dejar `GeneradorRazor.cs:99-100` como hoy |
| VER-07 | Factor del SUPER (fase A) | H | P1 | `/api/super/*` sin `otp` en `amr`: 403 `factor` | — |
| VER-08 | AIS-03 en el código de DB-7 | ARQ | P0 | Ningún `Claims.Nivel`, `FindFirst("nivel")` ni `IsInRole("ADMIN")` en `GPOS.Api` y `GPOS.Reportes.Api` fuera de la interfaz informativa | Una política nueva con `nivel` |
| VER-09 | Autorizante de supervisor (SD0-06) | H | P0 | Los dos caminos (`POST /api/pos/autorizar` y `AutorizadorSupervisor.ValidarAsync`): un ADMIN de B **no** autoriza en A; SUPER no autoriza; cuenta con clave por cambiar no autoriza; sello inválido no autoriza | Un solo camino corregido |
| VER-10 | `RequiereAdmin` = ADMIN de la empresa del token o SUPER | ARQ | P0 | Ningún endpoint de `/api/admin` usa otra política | — |
| VER-11 | Siembra de permisos por empresa (R-DB7-10) | S | P0 | Empresa nueva (alta por SUPER) tiene perfiles; dos empresas: editar una no cambia la otra; la siembra es idempotente | Siembra global una vez |
| VER-12 | Retiro de rutas | H | P0 | `/api/admin/usuarios*` y `GET /api/auth/empresas`: 410 (AIS-71, AIS-07) | — |

## 9. Orden de escritura, prioridades y qué es la «v1 mínima» de pruebas

**Idea:** las pruebas siguen el orden de construcción de B (D1 → D2 → D3 → D5 → D4 → D6, blueprint 10.1), pero la **suite de aislamiento se escribe junto a D1** (rojo primero) y se completa con cada tramo. Así, el 20-nov hay evidencia objetiva de qué parte del aislamiento está en verde.

| Bloque | Qué | Cuándo (calendario de B) | Prio | Criterio de salida |
|---|---|---|---|---|
| 0 | `EscenarioAcceso` (P…W) + reloj fake + llave de pruebas + doble de la API de reportes | S2 (2-nov), primer commit | P0 | El escenario se crea y se limpia en < 30 s; 3 corridas sin diferencias |
| 1 | P20 + V2 (D1) | S2-S3 | P0 | Como en sus propios planes |
| 2 | **Aislamiento P0 de la sección 4** (los que dicen D1/D2 y P0) | S2-S3, junto a D1 y D2 | P0 | Verdes o rojos justificados |
| 3 | D2 P0: PRE-01 a 05, LOG-01 a 04 y 07, EMP-01 a 05, BLQ-01, 03, 04, VER-01 y 02, TOK-01 a 03 y 05 | S3-S4 | P0 | PR de D2 apto |
| 4 | D3 P0: SEL-01 a 11, SEL-16, SEL-19, CUP-01 a 03, 05 a 07, 09 | S3-S5 | P0 | |
| 5 | D5 P0: BIT-03, NOT-01, 02, 04, 06, INT-01 a 03 | S4-S5 | P0 | |
| 6 | P1 de todos los tramos | S4-S6 | P1 | Para la firma de la v1 (11-dic) |
| 7 | D6: CNV-01 a 03, VER-06, 08 a 12, MED-01, ensayos VM | S6-S7 | P0/P2 | Hoja de cierre |

**Qué le pido a B para el punto de control del 20-nov:** el estado de los bloques 0 a 3. Si D1 y D2 están en PR, los bloques 0 a 3 en verde **son** la evidencia de que la guarda mínima (vía C) funciona: membresía con nivel, perfiles y sucursal; validación por petición con 503; ADMIN por empresa; fin de la lista anónima; selector de empresas autorizadas. Las filas de sellos (D3) no son necesarias para la vía C porque, en D1/D2, `Valido` es «no aplica» (centinela).

**v1 mínima si el tiempo no alcanza (recorte, en este orden de exclusión):** primero MAUI (UIX-10), luego D4 completo salvo UIX-01 y 03, luego MED-02 a 04, luego las pruebas de dos instancias, luego tiempos (LOG-06). **No se recortan:** AIS-14, 16, 19, 30, 37, 46, 55, SEL-03, SEL-16, CUP-05, NOT-01, INT-01, VER-09 (son las que protegen los hallazgos H-01, H-02, H-09, H-14 y R-DB7-09).

**Las H2 (dos instancias):** una por tramo (AIS-60 y la de permisos). Cuestan una fixture más pesada; propongo correrlas en el job nocturno o a mano antes del cierre, no en cada PR (pregunta P-4).

## 10. Hallazgos de QA al leer el diseño

| # | Hallazgo | Evidencia | Efecto |
|---|---|---|---|
| H-1 | **QA-62 contradice SUP-02.** EST dice token del SUPER 2 h; el blueprint (4.6 SUP-02 y 8.3) fija 30 min de inactividad y 4 h como máximo (ADR-81 punto 14), y la fila ADR-35 conserva «vence a las 2 horas» | EST §8 QA-62; blueprint 4.6 y 8.3; ADR-35 «Ingreso del Super Usuario» | AIS-62 mide 30 min / 4 h. Si el propietario quiere 2 h, se invierte |
| H-2 | **ADR-36 dice «se mantiene el inicio en un paso»; el blueprint lo retira** (DB7-02, login v2 sin `Clave`) | ADR-36 «Decisión» (texto leído); blueprint 5.2 | LOG-01 fija qué responde con `Clave`. Pregunta P-2. La precisión del 2026-10-18 de ADR-36 existe según la decisión (sección 2), pero **no leí** si ya está en el ADR |
| H-3 | **La tabla 6.1 repite la letra «g» tres veces** (membresía, sello, revocación de membresía) y la «h» sigue; el orden de evaluación entre pasos no tiene prueba posible sin letras distintas | blueprint 6.1 | Caso ACC-01 (sección 5.3): con dos fallos a la vez (cuenta inhabilitada y sello de membresía inválido) gana el primero de la tabla (`cuenta-inhabilitada`). Si B reordena, lo ve la prueba |
| H-4 | **`jti` consumido en memoria** y EST exige probar con **dos instancias**: una preautorización puede usarse una vez en cada instancia | blueprint 5.2 (ADR-24: un solo servidor), EST §8 | Pregunta P-3. Hoy la prueba H2 no la cubre; la dejo como caracterización PRE-06 y la pregunta |
| H-5 | **QA-63 deja el umbral a QA** y las mediciones de tiempo son ruidosas | EST §8 QA-63, QA-82 | LOG-06 es MED, no suite. Propongo < 20 % de diferencia de medianas con 100 muestras y reintento una vez |
| H-6 | **R-DB7-12 sin prueba:** Q1 detrás de una transacción de administración | blueprint 13.1 | INT-503 |
| H-7 | **QA-44/45 caducan:** el cupo ya no lo fija el SUPER | blueprint 4.6 SUP-01 y 5.4 | AIS-44 pasa a verificar que la ruta no existe |
| H-8 | **QA-57 habla de «certificado» y el blueprint usa llave CNG en el TPM**, sin certificado | blueprint 8.2 vs EST §8 QA-57 | AIS-57 se reescribe con la llave y `Jwt:KidsValidos` de huellas |
| H-9 | **QA-39, 70, 71 y 72 dependen de reglas retiradas o de fase 2** pero el blueprint 13.2 solo excluye 67, 68, 74 a 76, 85 y 09a a 09e | blueprint 13.2 y 4.9 | Los trato como en la sección 4 (QA-71 cambia; 39, 70 y 72 excluidos). Pregunta P-10 |
| H-10 | **La FK del catálogo y la ausencia de claims** ya están en P20; lo nuevo aquí: `nivel_efectivo`, `permiso` y `acceso` de la identidad del token se **ignoran** (6.1 paso 5), y esto no tenía prueba | blueprint 6.1 | TOK-05 |

## 11. Conteo y cobertura

- **Aislamiento (sección 4):** 61 filas (algunas agrupan dos QA): P0 45, P1 15, P2 1 (contadas con `grep` sobre este archivo).
- **D2 (sección 5):** PRE 10 + LOG 10 + EMP 6 + BLQ 4 + ACC 1 + VER 3 + TOK 8 + LLV 5 = 47.
- **D3 (sección 6):** SEL 19 + CUP 11 = 30.
- **D5, D4 y D6 (sección 8):** BIT 6 + NOT 6 + INT 9 = 21; UIX 10; MED 4 + CNV 3 + VER 9 = 16; total 47.
- **Total de filas: 61 + 47 + 30 + 47 = 185** (contadas con `grep`; las filas VER-04 a 12 son de D6). Varias son teorías con 3 a 12 variantes, así que los métodos serán más. Junto a P20 + V2 (unas 275 pruebas nuevas), la v1 llega a unas 450 a 500 pruebas, *inferido*.
- **Trazabilidad:** los casos de EST §8 están cubiertos, excluidos con motivo o remitidos a verificación sin construcción en la sección 4 y en VER-xx, **salvo QA-73, 82, 83 (parcial en BLQ-02), 89 y 90 (formatos de impresión, M-3/ADR-110), que no clasifiqué y quedan para B/A**; las 113 reglas del blueprint están referenciadas por los casos de aislamiento y de tramo (las reglas retiradas o de fase 2 no tienen prueba, salvo que dejen de existir: AIS-44, AIS-71, VER-12).
- **Cobertura:** política por omisión de QA, 70 % de líneas del código modificado en módulos críticos (seguridad y aislamiento). Se mide en B, no en la PC de C: `dotnet test --collect:"XPlat Code Coverage"` sobre `GPOS.Core/Sistema/Acceso/*`, `Sistema/Usuarios/Sellos*`, `GPOS.Api/Seguridad/*` (`ValidacionAcceso`, `Preautorizacion`, `ProveedorLlavesFirma`), `GPOS.Reportes.Api/Seguridad/*`. Las constantes SQL se miden por rama (como en P20).
- **Esfuerzo de escribir estas pruebas (inferido, ±40 %):** bloque 0: 1 a 1,5 días; aislamiento: 4 a 5 días; D2: 3 días; D3: 3 a 4; D5: 2 a 3; D4: 1,5 a 2; D6: 1,5. Suma aproximada: **16 a 20 días-persona** además de los de P20 + V2. Es más que el 15 % típico de pruebas dentro de los 2,6 a 3,5 sp de D6 del calendario de B: **hay que repartirlo dentro de cada tramo, no dejarlo a D6**, o el plan de DB7-01 se queda corto *(riesgo para el cálculo de los sp; lo reporto, no lo decido)*.

## 12. Mutaciones imprescindibles (`*`), en una lista

AIS-03, 07, 14, 16, 19, 22, 25, 30, 32, 37, 46, 58, 60; PRE-01 a 03; LOG-01, 03; EMP-01, 03; BLQ-03; TOK-01 a 03, 05; SEL-01 a 04, 06; CUP-05, 09; BIT-01, 03; NOT-01, 02; INT-01 a 03; UIX-03, 04. El desarrollador corre cada una una vez y pega el resultado.

## 13. Qué no cubre este plan

1. **Rendimiento real con el hardware del cliente** (solo MED en la máquina de B).
2. **TPM real en CI**: la suite usa la costura; el TPM va a laboratorio (VM con TPM virtual o equipo físico).
3. **Dos instancias en la misma máquina** no prueban la latencia de red entre ellas.
4. **Un SUPER malicioso o ejecución de código dentro de la API** (aceptado, ADR-38 G-1).
5. **Columnas sin sello** (R-DB7-11): `DebeCambiarClave`, `SesionesRevocadas*`, `BloqueadoHasta`, `FallosVentana*`, `AdministradaPorSuper`, perfiles y excepciones se pueden cambiar por SQL; la prueba lo **caracteriza** (SEL-03 variante: esas columnas sí cambian el comportamiento y el diseño lo acepta) pero no lo evita.
6. **Revisión legal de la retención de 5 años** (TRZ-08): pendiente del dictamen.
7. **Pantallas MAUI en dispositivo** y accesibilidad.
8. **Convivencia con la entrega 2 (nodos)**: `iss` y llave por sitio quedan solo previstos.
9. **No leí** las secciones 11, 12, 14 y 15 del blueprint ni el modelo de datos D0 ni la revisión D0: puede haber casos de SD0-xx que no vi.
10. **Ninguna prueba se ejecutó**: todo «rojo hoy» sale de que los símbolos no existen en `b9efa9fb`.

## 14. Preguntas para B

| # | Pregunta | Detiene | Supuesto de este plan |
|---|---|---|---|
| P-1 | ¿Cómo registra la suite una llave ES256 en `ProveedorLlavesFirma`: con `aprovisionar --llave-firma --desarrollo` (almacén del usuario) o con una costura de software? | Todas las TOK, AIS-55/56 | Costura `internal` solo en Debug |
| P-2 | ¿Qué responde `login` v2 si llega `Clave` (cliente viejo con 426 saltado)? | LOG-01 | Se ignora y exige preautorización; 400 si no hay ninguna |
| P-3 | ¿Debe el `jti` de la preautorización ser único entre instancias? (ADR-24 dice un solo servidor) | PRE-06 | No; residual documentado |
| P-4 | ¿Se aceptan pruebas H2 fuera de cada PR (nocturno o antes del cierre)? | AIS-60 y otras | Sí |
| P-5 | ¿`ValidacionAcceso`, `Preautorizacion` y `PoliticaBloqueo` reciben `TimeProvider`? | Todas las pruebas de tiempo | Sí |
| P-6 | ¿Dónde vive `EscenarioAcceso`, y B quiere reutilizar `ApiMvpFactory` o crear una fábrica nueva con el modelo de membresía? | Bloque 0 | `tests/GPOS.Tests/Acceso/` y una fábrica que hereda de `ApiMvpFactory` |
| P-7 | ¿Qué responde `login` del SUPER con una preautorización sin `otp` (202 con desafío o 401)? Y las rutas viejas `login/alta` y `login/factor`: ¿404 o 410? | PRE-05, PRE-09 | 401 `factor`; 410 |
| P-8 | Tras `POST /empresa`, ¿el token de la empresa anterior queda inválido (mismo `sid`)? | EMP-02 | No hay nada que invalidar: es el mismo `sid` y la empresa viaja en el token; el token viejo sigue siendo de A hasta su vencimiento. Si es así, EMP-02 pasa a «caracterización» |
| P-9 | ¿Se puede mantener una transacción de administración abierta 3 s con una costura para INT-503? | INT-503 | Un `ICapturador` de pruebas dentro de `MembresiasService` |
| P-10 | ¿Confirma excluir QA-39, 70 y 72 y reescribir QA-71 y QA-44/45? | Sección 4 | Sí |
| P-11 | ¿Quién escribe las pruebas de D2 a D6? El calendario da toda la construcción a B; este plan supone que cada tramo lleva las suyas, y que C revisa (como el #170) | Plan de esfuerzo | B escribe; C hace revisión adversarial en cada PR |
| P-12 | ¿En qué instancia se mide Q1 (Express o Standard) y con cuántos datos? | MED-01 | Instancia de pruebas con 1 000 cuentas y 5 empresas |
| P-13 | ¿La fuente de la hoja del diseño firmada (objetivo 10-31) trae cambios a los contratos? Si cambia algo de 5.2 a 5.5, este plan se ajusta | Todas | Sin cambios |

### Cierre
- Estado: Completado (plan sin código; recomendación sujeta a las preguntas)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-pruebas-db7-v1.md`
- Supuestos: los de la sección 14; cada caso con dependencia del texto de una SD0 que no leí está marcado *(inferido)*
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → responder P-1 a P-13; arquitecto-software → H-1 (duración del SUPER), H-2 (login con `Clave`) y H-3 (letras de la tabla 6.1)
- Próximo paso recomendado: B responde P-1, P-5 y P-6 antes del 2-nov para escribir el bloque 0
