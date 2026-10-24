```
Para: B        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 8 (a) de B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9.md: plan de pruebas de F2 de `tls`, el núcleo)
Prioridad: Alta (B construye F2 del 3 al 10-nov; las pruebas deben estar escritas antes)
Repositorio y rama: GPOS-NG `origin/b/blueprint-tls-anillo` (`c087932a`, blueprint), `origin/b/hoja-firma-tls-anillo` (`757d90c3`), `origin/b/hoja-firma-s217-h210-msi-f2f3` (`f14d89e7`), `origin/b/f1-anillo` (`e1c6f516`, lectura de `IAlmacenMaquina`), `origin/a/pr-v-verbos-servidor` (`a3c71ce1`), `origin/feature/modelo-ng` (lectura); área común
Estado: Abierto (18 dudas para B, sección 9; 6 bloquean casos)
```

# Plan de pruebas de F2 de `tls`: el núcleo (CA propia por sitio, hojas, publicación, `--crear-ca --emitir`, `--comprobar`)

**Qué es.** El recorte de mi plan general del verbo (`2026-10-23-plan-pruebas-verbo-tls.md`, casos TLS-xx, MU-01 a MU-64, LABT-01 a 21) a lo que **F2** construye según lo firmado. Define qué entra exactamente en F2, qué casos del plan general lo cubren y cuáles se mueven a F3 o F4, agrega los casos que el blueprint creó y mi plan no tenía (almacén propio `GPOS NG TLS`, "lo propio", guardas en orden, salida 3, `--comprobar`, eventos 4780 a 4782), y deja los requisitos de testabilidad, los casos para `VM-SRV`, el orden de escritura (rojo primero) y las dudas.

**Método y límites.** Solo lectura: `git show` sobre las ramas citadas (el checkout de `GPOS-NG` no se tocó, sin commits). **No compilé ni ejecuté nada.** El verbo `tls` no existe en ninguna rama [V: el blueprint lo declara; `git ls-tree` de `b/f1-anillo` no trae `Tls/`]. Por eso las mutaciones se enuncian sobre responsabilidades; B las convierte en `archivo:línea` al construir. Marcas: **[V]** leído; **[I]** inferido o conocimiento general de Windows, CNG o .NET, por confirmar con casos W o en la VM; **[D]** depende de una duda de la sección 9.

**Fuentes (todas leídas completas salvo lo indicado).** Blueprint secciones 0 a 13 (en especial 1, 4, 5, 7.2, 8, 12); hoja de F1 (P-1 a P-9 y SA-01 a SA-06) y hoja del 2026-10-23 que aprueba F2 y F3 "completas" (S217-02, H210, MSI, `tls`) [V]; mis planes: `plan-pruebas-verbo-tls.md`, `plan-pruebas-tls-f4.md` (secciones 1 a 9), `plan-pruebas-pr-v.md` (secciones 0 a 4.D, que son su "base de F2"), `plan-pruebas-anillo-dm07.md` (R-A1 a R-A10) y `revision-adversarial-blueprint-anillo-tls.md` (SA-07 a SA-09); `IAlmacenMaquina.cs` de `b/f1-anillo`; `ISistemaServidor.cs`, `ValoresRegistroServidor.cs` y `SistemaServidorFalso.cs` de `a/pr-v-verbos-servidor`; `InterpretacionRed.cs` e `InterpretacionRedTests.cs` de `feature/modelo-ng`.

---

## 0. Resumen para decidir

1. **Qué es F2, en una línea [V, blueprint 8 y hoja del 2026-10-23]:** `ComandoTls` (despacho, elevación, mutex, códigos 0 a 4), `ConstructorPki` y Name Constraints con `AsnWriter`, la CA (TPM o software) en el almacén propio `LocalMachine\GPOS NG TLS`, las hojas Web y API, la publicación según PT-02, la CA en `LocalMachine\Root` y en `Servidor\tls\ca.cer`, `--crear-ca`, `--emitir` (con `--servicio` y `--forzar`), `--comprobar` y los eventos. **Aprobada completa** por el propietario (no la alternativa barata): «servidor de sitio» entra en F2.
2. **El plan general cubre 91 de sus 122 casos en F2** (73 %): 23 pasan a F3 (renovación, tarea, avisos, `--importar --huella`, `--exportar-publica`, `--retirar`), 5 a F4 y 3 desaparecen o se absorben. A ellos se suman **39 casos nuevos (T2-xx)** por lo que el blueprint decidió después de mi plan. En total **130 casos de F2** (sección 3) y **29 mutaciones nuevas** (MU-65 a MU-93) sobre las 51 completas y 2 parciales del plan general que aplican.
3. **Tres inconsistencias del blueprint que cambian lo que se prueba y que B debe cerrar antes del 3-nov** (sección 1.3): (a) `--comprobar` aparece en F3 en la tabla de la sección 1 y en F2 en la de la sección 8; (b) la sección 4.5 dice que `--emitir` crea la tarea programada y la tarea es de F3, con lo que una F2 publicada **crearía una tarea diaria de SYSTEM que ejecuta `tls --renovar`, una acción que todavía no existe**; (c) el código de salida cuando la CA queda en software (2 «hecho con aviso» según 4.1, 0 según mi plan): la VM sin TPM lo hace el caso normal, y el paquete (Burn) decide qué hace con un 2.
4. **El mayor riesgo de testabilidad:** la costura `IAlmacenMaquina` que B dejó en F1 es **solo RSA, solo software, sin listar y sin almacenes nombrados** [V, `IAlmacenMaquina.cs` de `b/f1-anillo`: `CrearLlaveRsa`, `LeerLlave`, `BorrarLlave`, `Buscar`, `Agregar`, `Quitar`]. F2 necesita ECDSA P-256, TPM o software, el almacén `GPOS NG TLS`, `Root`, listar para reconocer "lo propio" (D-19) y evaluar el acceso de un SID (D-12). Si F2 la amplía a mano sin falso, los casos F pasan a W y el laboratorio se llena. Requisito R-2.1; QF2-01.
5. **Orden de escritura (rojo primero), sección 7:** (1) vectores y oráculo independiente, sin producto; (2) núcleo U; (3) guardas y registro; (4) CA; (5) hojas y publicación; (6) `tls\` y `--comprobar`; (7) eventos y arquitectura; (8) W y laboratorio. Para que las pruebas **compilen en rojo** desde el 3-nov, el primer commit de B es el **esqueleto** (interfaces, firmas y `NotImplementedException`), no el verbo.
6. **Esfuerzo [I, ±40 %]:** escribir las pruebas de F2 unos **2,8 dp** (oráculo y arnés 0,6; U 0,7; F 1,2; W 0,3) más **0,3 dp** de guiones de laboratorio; laboratorio de F2 unas **9,5 h** en 3 sesiones (sección 5). Dentro de los 5 dp de mi plan general, no suma.
7. **Hallazgos de lectura (QF2-01 a QF2-10, sección 8):** ninguno Crítico ni Alto; **cuatro Medios** que conviene decidir antes de construir: QF2-01 (interfaz RSA-only), QF2-02 (`--comprobar` en dos fases), QF2-03 (la tarea de una F2 sin `--renovar`) y QF2-06 (CA con certificado pero sin llave, es decir, un sitio restaurado: SA-07).

---

## 1. Qué entra exactamente en F2

### 1.1 Alcance, con la fuente de cada decisión

`Fuente`: **H** = firmado en la hoja del 2026-10-23 («F2 y F3 aprobadas completas»); **B** = blueprint (F2 definida en la tabla de la sección 8); **A90** = ADR-90 con PT-01 a PT-10; **[D]** = el blueprint es ambiguo y la decisión es de B.

| # | Capacidad | En F2 | Fuente | Nota para las pruebas |
|---|---|---|---|---|
| 1 | Despacho `GPOS.Migracion tls <acción>`, una acción por llamada salvo `--crear-ca --emitir` | Sí | B 4.1 | Acciones de F3 en una F2: ver D-F2-07 |
| 2 | Guardas en orden: plataforma, elevación, mutex `Global\GPOS.Migracion.tls` (espera 60 s, luego salida 1), registro, cuenta virtual, raíz y `tls\`, varias CA | Sí | B 4.1, 4.2, 4.8 | Bloque G |
| 3 | `ModoRed` y `NombresServidor` leídos **del registro** con `FuenteConfiguracionRedWindows` e `InterpretacionRed`; nada por línea de comandos; `IP_NODOS` y subredes nunca | Sí | B 4.1 (D-14, D-15, TLS-V03) | N, G |
| 4 | `ConstructorPki` (núcleo puro, llaves y `TimeProvider` dados) y `NameConstraints` con `AsnWriter` | Sí | B 5 (R-T1), PT-07 | U |
| 5 | CA: ECDSA P-256, Platform Crypto Provider si abre el TPM, si no software con **4781**; no exportable; DACL solo SYSTEM y Administradores; vigencia 10 años, `NotBefore` − 1 h; `pathLen = 0`; EKU `serverAuth`; NC críticas | Sí | B 4.2 (D-13, K-01 a K-04) | C |
| 6 | La CA con su llave en `LocalMachine\GPOS NG TLS`, **no** en `My` (D-16) | Sí | B 4.2 | C12 y C16 ajustados; plan B en D-F2-15 |
| 7 | Una sola CA propia por sitio; más de una: salida 4 sin elegir | Sí | B 4.2 (TLS-C10) | C |
| 8 | Parte pública de la CA en `LocalMachine\Root` y en `Servidor\tls\ca.cer` (escritura atómica, solo si cambió) | Sí | B 4.2, 4.8; F-6 (ii) | C15, X |
| 9 | Hojas Web y API: ECDSA P-256 en software, `MachineKey`, no exportable, descriptor **en la creación** (solo `NT SERVICE\GPOS.Web` o `GPOS.Api` con `GENERIC_READ`), 90 días, SAN exacto, EKU solo `serverAuth`, CN = primer SAN, `FriendlyName` `GPOS NG TLS <Api|Web> <AAAAMMDD>` | Sí | B 4.3 (PT-01, PT-07, PT-10) | S |
| 10 | Orden de publicación PT-02: crear llave con descriptor → emitir → importar a `My` → **comprobar** (descriptor exacto, abre como quien ejecuta, cadena `CustomRootTrust`, `MatchesHostname`) → publicar `HuellaApi`/`HuellaWeb` (`REG_SZ`, SHA-256 del DER, 64 hexadecimales en **mayúsculas**, vista de 64 bits) | Sí | B 4.4 | P |
| 11 | `tls` solo escribe esos dos valores y **nunca crea la clave**; sin `HuellaAnterior` | Sí | B 4.4 (D-05) | P03, P06, P08 |
| 12 | `--emitir`: emite y publica lo que **no esté vigente** (más de 30 días y SAN igual a los nombres actuales); nombres distintos que caben en las NC: reemite; que no caben: salida 3 sin tocar nada; `--servicio api\|web\|ambos`, `--forzar` | Sí | B 4.1, 4.5 (D-02, D-11) | S, T2-E |
| 13 | Salidas 0 a 4 | Sí | B 4.1 | O03 |
| 14 | Eventos 4780, 4781 y 4782 emitidos; el origen `GPOS.Instalacion`; ids únicos | Sí (emisión) | B 4.7 | Bloque EV; ver D-F2-08 sobre declarar los diez |
| 15 | `--comprobar` (solo lectura: estado, días, "CA en software", cadena, nombres y ACL; `--salida json`) | **[D]** Sí por 8; **F3 por 1** | B 1 frente a B 8 | D-F2-01 (bloquea); casos CMP en F2 con `Trait("Fase","F2-D")` |
| 16 | Tarea `\GPOS NG\Renovar TLS` (la crea `--emitir`, 4.5) | **No** en F2 por 8; **sí** por 4.5 | B 4.5 frente a B 8 | D-F2-02 (bloquea); QF2-03 |
| 17 | `--renovar`, retiro de vencidos, avisos 20/10/3 (4785 a 4787), `--importar --huella`, `--exportar-publica`, `--retirar`, `--quitar-tarea` | **No** (F3) | B 1 y 8 | Ver 1.2 |
| 18 | `--importar --pfx`, anillo de la Web, `--renovar-certificado`, sucesora con certificado cruzado, Avanzada con TPM obligatorio | **No** (F4 o sin fecha) | B 1; H (P-5, P-6) | Ver 1.2 |
| 19 | Linux: «sin plataforma», salida 1, ningún archivo | Sí | B (D-17) | O05 |
| 20 | Cerrojo con DACL (SA-08), 4784 si no se obtiene | **No firmado** | hoja de F1: «no firmado» | D-F2-06; caso T2-G09 como transición |

### 1.2 Qué se mueve a F3 y F4 (y qué deja F2 como "pin de transición")

| Destino | Casos del plan general | Observación |
|---|---|---|
| **F3** | TLS-R01, R03 (retiro de vencidos), R04, R07 a R13; TLS-I01 a I03, I07 a I13; TLS-V04, V05; TLS-O08, O09; MU-39 (la parte de `comprobar-servidor`), 42 a 45 (la parte de retiro), 48, 51 a 54, 64; LABT-06 (con `--renovar`), 09, 10, 14, 17 | R01 conserva en F2 solo el umbral de **vigente** de `--emitir` (T2-E03) |
| **F4** | TLS-C06 (Avanzada sin TPM), I04 a I06, O06 (`--pfx`); MU-49, 50; LABT-19, 21 | C06: no hay camino que lea el perfil en F2 (D-F2-17) |
| **Fuera** | TLS-N21 (sugerencia de nombre: ningún documento firmado la asigna a `tls`), R14 (rotación: no existe), P08 (`HuellaAnterior` no existe: pasa a una aserción negativa dentro de P03) | |
| **Pines de transición** | Pruebas de F2 que fijan "esto todavía no existe" y que F3 invierte a propósito: `--renovar` no disponible (T2-G03), `--emitir` no crea la tarea (T2-G08, si D-F2-02 queda en «no»), el mutex sin DACL (T2-G09) | `Trait("Transicion","F3")`, como `Transicion=F2` de PR-V (PV-F-01) |

### 1.3 Inconsistencias del blueprint que afectan a F2 (resumen; detalle en QF2-02, QF2-03 y QF2-04)

1. **`--comprobar`:** sección 1 (tabla "Entra") lo pone en F3; sección 8 (fila F2) lo pone en F2; la sección 4.1 lo describe sin fase.
2. **La tarea:** 4.5 dice que `--emitir` crea o actualiza `\GPOS NG\Renovar TLS` con acción `tls --renovar`; sección 1 y 8 ponen la tarea en F3. Si F2 se publica con la creación de la tarea, la tarea falla cada día.
3. **Exit 2:** 4.1 define 2 como «hecho con aviso, o `--comprobar` con algo en AVISO»; 4.2 dice que la CA en software deja el evento 4781 (aviso), pero no dice si la corrida termina con 0 o con 2.

---

## 2. Qué casos de mi plan general cubren F2

Resumen por bloque (los casos con ajuste llevan el cambio en la columna **Cambio**; "igual" = sin cambio):

| Bloque | Casos | En F2 | Cambio respecto de mi plan general |
|---|---|---|---|
| **N** nombres (22) | N01 a N20, N22 | 21 | **Paridad con `red`** (D-15): el veredicto aceptado/rechazado lo da `InterpretacionRed.ValidarNombres` de A [V]; N20 pasa a ser un solo caso parametrizado con todos los vectores (N03 a N17). Lo que `tls` agrega y hay que probar: **normalización a minúsculas, deduplicación, codificación en NC y SAN** (N01, N02, N11, N12, N15, N18, N19). `InterpretacionRed` **no** normaliza ni deduplica [V: `ValidarNombres` devuelve solo un motivo] y acepta `::ffff:10.0.0.10` como IP de un nodo [V, `InterpretacionRedTests.cs:255-266`]: casos T2-N01 a T2-N03. N21 sale |
| **C** CA (17) | C01 a C05, C07 a C17 | 16 | C04: salida según D-F2-03; C12 y C16: la CA **no está en `My`**, así que el selector real nunca la encuentra (la prueba pasa a «el selector no la ve ni con `HuellaApi` apuntando a ella», 4.2); C03: H-SUB (subdominio) es **válida** por RFC 5280 y es el residual declarado (4.2); la prueba lo registra, no lo exige rechazado; C06 a F4 |
| **S** hojas (14) | S01 a S14 | 14 | S01: ahora con `FriendlyName` y CN = primer SAN; S09 y S10: el descriptor va **al crear la llave** (4.4, TLS-P01 ajustado); S11: «comprobar que la abre» = evaluar el acceso del SID sobre el descriptor (D-12) y, en la VM, el selector en marcha; S13: salida 3 |
| **P** publicación (10) | P01 a P07, P09, P10 (P08 absorbido) | 9 | P01: la ACL ya no es un paso posterior; el orden es crear con descriptor → emitir → importar → comprobar (4 sub-pasos) → publicar; P08 pasa a una aserción negativa de P03 (ningún valor distinto de `HuellaApi`/`HuellaWeb`; sin `HuellaAnterior`); P07: espera 60 s y salida 1 |
| **R** renovación (14) | R02, R03 (parcial), R05, R06 | 4 | `--emitir --forzar` ya genera llave y serie nuevas (R02), conserva la hoja anterior en `My` (R03, solo "no se borra") y no toca servicios (R05); el reloj por `TimeProvider` (R06). El resto, F3 |
| **I** cliente (13) | — | 0 | F3 (I01 a I03, I07 a I13) y F4 (I04 a I06) |
| **V** VPN (6) | V01 a V03, V06 | 4 | V04 y V05 (`--exportar-publica`) a F3 |
| **X** carpeta `tls\` (7) | X01 a X07 | 7 | X04 cambia: `tls\` con DACL ajena o reanálisis es **salida 4 sin corregir** (4.8), no «se corrige o se detiene» |
| **O** operación (12) | O01 a O05, O07, O10 a O12 | 9 | O03: códigos de 4.1; O04: sin PFX, queda la parte de "ninguna llave ni material en los canales"; O08 y O09 a F3; O06 a F4 |
| **AR** arquitectura (7) | AR01 a AR07 | 7 | AR02 sin la parte de PFX (a F4); AR06: ids 4780 a 4789 (D-F2-08); AR07 ahora sobre `IAlmacenMaquina` y `ISistemaServidor` |
| **Total** | 122 | **91** (más R03 contado una vez) | 23 a F3, 5 a F4, 3 fuera (N21, R14, P08) |

**Mutaciones del plan general (MU-01 a MU-64):** 51 completas en F2 (MU-01 a 38, 40, 41, 46, 47, 55 a 63), 2 parciales (MU-39: el umbral de 30 días de "vigente"; MU-45: huérfano ante un fallo, no el retiro de vencidos), 9 a F3 (42 a 44, 48, 51 a 54, 64) y 2 a F4 (49, 50). MU-01 a MU-07 mutan código de A (`InterpretacionRed`); las mata N20 y las pruebas de A, no hay que repetirlas con otro nombre.

---

## 3. Casos de F2, uno por uno

Columnas: **ID** · entrada · esperado · nivel (U puro; U-W = puro pero en un ejecutor de Windows por `X509Chain`; F con falsos; W real, solo VM) · mutación que lo mata (MU-xx; las nuevas, en la sección 6). **\*** = imprescindible para el revisor. Los casos con ID del plan general (TLS-xx) se leen **con su fila de ese plan** y aquí solo se anota lo que cambia o se agrega.

### 3.1 G: despacho, guardas y orden (nuevo; casi todo F)

La regla del bloque: **cualquier guarda que falle deja el falso con 0 escrituras** (almacén, registro, carpeta, evento salvo 4782, tarea). El falso registra todas las llamadas.

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| T2-G01\* | Orden de guardas con cada una fallando sola: fuera de Windows; sin elevación; mutex ocupado; clave del registro ausente; clave con escritor o dueño ajeno; `ModoRed` ausente o inválido; `NombresServidor` ausente o inválido en «servidor de sitio»; cuenta virtual de un servicio pedido inexistente; raíz `%ProgramData%\GPOS NG` ausente; `tls\` con DACL ajena o reanálisis; dos CA en `GPOS NG TLS` | Cada una: código del cuadro de 4.1 (1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4), evento **4782** con el motivo y sin secretos, **0 escrituras** (ni CA, ni llave, ni `Root`, ni carpeta, ni valor) | F | MU-65, MU-83 |
| T2-G02\* | Orden entre guardas: plataforma → elevación → mutex → lecturas del registro y de la cuenta → carpetas → CA. Con dos fallando a la vez (sin elevación y sin clave), gana la primera | Ni siquiera se **lee** el registro sin elevación (el falso cuenta lecturas) | F | MU-65 |
| T2-G03 | Acciones desconocidas o mal combinadas: sin acción; `--xyz`; `--crear-ca` repetida; `--emitir --servicio xyz`; `--servicio` sin valor; `--crear-ca --renovar`; `--crear-ca --comprobar`; opciones duplicadas | Salida 1, mensaje de uso, 0 escrituras. `--crear-ca --emitir` en cualquier orden de argumentos es la **única** combinación admitida. Las acciones de F3 (`--renovar`, `--importar`, `--exportar-publica`, `--retirar`, `--quitar-tarea`): el esperado es el de D-F2-07; hasta entonces `Trait("Transicion","F3")` | U, F | MU-66 |
| T2-G04\* | Entradas solo del registro: `--nombres a.test`, `--modo`, `--puerto-api`, `IP_NODOS`, `SUBREDES_PUESTOS`, `SUBREDES_REMOTOS` por línea de comandos o por variable de entorno | Rechazados o ignorados; nunca llegan a la NC ni al SAN (TLS-V03) | F | MU-67, MU-23 |
| T2-G05 | `ModoRed` leído **una vez** y con el intérprete de `red`: dos lecturas con un cambio entre ellas (patrón SPX-01 de PV-R-12) | Se detiene con 4 «cambió mientras tls trabajaba», o usa solo la primera lectura en toda la corrida; nunca mezcla modos en una misma corrida (CA de un modo y hoja de otro) [D-F2-10] | F | MU-68 |
| T2-G06\* | Todas las guardas de la clave del registro son **las mismas** que usa `red` (la pieza compartida R-5/PV-F-02): se parametriza PV-R-10 a PV-R-14 por cliente (`red` y `tls`) | Mismo veredicto en los dos: S-05 (dueño y escritor ajenos), tipo de valor (`REG_DWORD` en lugar de `REG_SZ`), SPX-02 (padre laxo, vínculo) | F | MU-37 |
| T2-G07 | Ejecución completa dos veces como SYSTEM y como administrador interactivo (TLS-O02) | Mismo resultado y misma DACL de llaves (sin `CREATOR OWNER` ni el SID del ejecutor) | F (W en la VM) | MU-30 |
| T2-G08 | `--emitir` **no** toca el Programador de tareas en F2 (si D-F2-02 queda en «no») | 0 llamadas a `ITareasProgramadas`; el falso de tareas sin definiciones al terminar. **Si D-F2-02 queda en «sí»**: la definición cumple TLS-R07 y la acción es `tls --renovar`, que **tiene que existir** (QF2-03) | F | MU-66 |
| T2-G09 | Cerrojo (TLS-P07 + SA-08): el mutex `Global\GPOS.Migracion.tls` ocupado por otro hilo y por otra identidad; el reloj falso se adelanta 60 s | Salida 1 a los 60 s exactos (ni antes ni después), evento 4782, **sin espera infinita**; el mutex se libera si la corrida lanza una excepción. Con SA-08 firmado: DACL de SYSTEM y Administradores o cerrojo en `Servidor\tls\.cerrojo`, y 4784. Hoy: pin de transición (D-F2-06) | F | MU-86 |
| TLS-O01 | Sin elevación (usuario estándar; administrador con token filtrado) | Salida 1 **antes** de tocar nada. La excepción es `--comprobar` (T2-K02) | F, V | MU-58 |
| TLS-O03 | Códigos de salida | 0 hecho o ya estaba; 1 error, sin elevación o fuera de Windows o uso; 2 hecho con aviso; 3 hay que reemplazar la CA; 4 guarda. Cada código con su disparador, documentados en `--ayuda` (cuadro 4.1) | U, F | MU-89 |
| TLS-O05 | Linux u otra plataforma (D-17) | «Sin plataforma», salida 1, 0 archivos. La plataforma se inyecta (R-2.9) para correrlo en la suite de Windows; compila en Linux | U | MU-60 |
| TLS-O10, O11 | `ModoRed` ausente, o distinto de una corrida a otra | 4 con el mensaje de `red`; el cambio de modo con CA existente sigue T2-C06 | F | MU-61 |
| TLS-O12 | No existe `--rotar-ca` ni nada que se le parezca (P-6) | La acción es desconocida (T2-G03); no queda un camino parcial | U | |

### 3.2 N: nombres (pocos casos propios; paridad con `red`)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-N20\* | **Un solo caso parametrizado** con todos los vectores de `InterpretacionRedTests` (nombres válidos, `.local`, `localhost`, IP sin forma canónica, etiquetas, 16 y 17 nombres) más los de TLS-N03 a N17 | El mismo veredicto en `red` y en `tls`; `tls` **llama** a `InterpretacionRed.ValidarNombres` y no tiene un parser propio (prueba de arquitectura TLS-AR03bis: `tls` no declara un `Regex` de etiqueta DNS) | U | MU-07 |
| TLS-N01, N02\* | Aceptado `SRV-C01.GposLab.TEST` | En NC y SAN solo `srv-c01.gposlab.test`; ningún byte en mayúsculas en el `dNSName` | U | MU-01 |
| TLS-N11, N12\* | IPv4 `192.168.50.10`; IPv6 `fd00:50::10` y su forma larga | NC: `iPAddress` de 8 octetos (IPv4 ‖ `FF FF FF FF`) o de 32 (IPv6 ‖ 16 × `FF`); SAN: 4 o 16 octetos. Bytes contra el **vector independiente** | U | MU-10, MU-11 |
| TLS-N15\* | `a.test`, `A.test`, `a.test` y, por IP, `FD00::10` con `fd00::10` | Un solo `dNSName`/`iPAddress` en NC y SAN: `tls` deduplica (el intérprete de `red` no lo hace) | U | MU-92 |
| TLS-N18, N19\* | Solo IPv4 (más un DNS); solo DNS | Solo IPv4: la NC permite solo esa IPv4; una hoja con IPv6 en el SAN falla la cadena. Solo DNS: **exclusión** de `0.0.0.0/0` y `::/0` (8 y 32 octetos en cero), sin subárbol `iPAddress` permitido; una hoja con SAN IP falla | U-W | MU-08 |
| T2-N01\* | `::ffff:10.0.0.10` entre los nombres del sitio (`red` la acepta [V]) | Se codifica como IPv6 de **16/32 octetos** en SAN/NC, no como IPv4 de 4/8; la hoja con SAN `10.0.0.10` (IPv4) no valida bajo esa CA (H-IPMAP). Si B decide rechazarla, lo dice (D-F2-09) | U, U-W | MU-69 |
| T2-N02 | «Un equipo»: sin nombres en el registro | NC = `localhost`, `127.0.0.1/32`, `::1/128`; SAN de las dos hojas = `localhost`, `127.0.0.1`, `::1`; CN `localhost`; sin exclusión | U | MU-22 |
| T2-N03 | «Servidor de sitio» con el primer nombre del sitio y otros 15 | CA: `CN=GPOS NG CA <primer nombre> <AAAAMMDD>, O=GPOS NG`; **ninguna CA lleva `localhost`** ni `127.0.0.1` | U | MU-22 |
| TLS-N22 | Resolvedor de nombres que lanza | La corrida termina igual: no resuelve ni sale a la red (TLS-C17) | F | |

### 3.3 C: la CA

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-C01\* | Perfil de la CA decodificado con `AsnReader` en DER estricto | v3; serie ≥ 16 octetos aleatorios positiva; `ecdsa-with-SHA256`; emisor = sujeto; SPKI P-256; `NotBefore` = emisión − 1 h; `NotAfter` = + 10 años; `basicConstraints` crítica `cA` con `pathLen = 0`; KU crítica solo `keyCertSign` y `cRLSign`; EKU solo `serverAuth`; SKI; **conjunto exacto de extensiones** | U | MU-13 a MU-18 |
| TLS-C02\* | Name Constraints: seis combinaciones (DNS; DNS+IPv4; DNS+IPv6; DNS+IPv4+IPv6; «un equipo»; sin IP) contra bytes de referencia | Crítica; `permittedSubtrees` con `dNSName [2]` e `iPAddress [7]`; `excludedSubtrees` solo sin IP; sin `minimum` explícito; sin `maximum`; el decodificador estricto lee todo | U | MU-09 a MU-12 |
| TLS-C03\* | Efecto con `X509Chain` (`CustomRootTrust`, `NoFlag`, sin descargas, `RevocationMode.NoCheck`) | Válidas: `H-DNS`, `H-IP`. Rechazadas con marca de NC: `H-FUERA`, `H-MEZCLA`, `H-SUFIJO`, `H-PADRE`, `H-COMODIN`, `H-IPFUERA`, `H-IPMAP`. Control: la misma hoja bajo una CA sin NC es válida. **`H-SUB` (`a.<nombre>`) queda válida**: es el residual del `dNSName` (RFC 5280, blueprint 4.2); la prueba lo **registra** como «válida por diseño». El blueprint cita H-SUFIJO y H-PADRE como el residual; los de residual son H-SUB (QF2-09) | U-W | MU-09, MU-10 |
| TLS-C04\* | CA sin TPM (Básica) | Llave de software (`MachineKey`, `ExportPolicy = None`); `ExportPkcs8PrivateKey` lanza; evento **4781** con el motivo; salida **0 o 2** [D-F2-03] | F, W | MU-28, MU-71 |
| TLS-C05 | CA con TPM | La llave está en el Platform Crypto Provider; el proveedor se lee **con ECDSA** (no con `PrivadaEnTpm`, que solo reconoce RSA, QT-08) [V: `OrigenCertificadosAnillo.cs:50-62` según el plan de F4] | F (proveedor falso), T | MU-70 |
| T2-C01\* | TPM presente pero crear la llave **falla** (el falso lanza al crear en el proveedor TPM) | Básica: CA en software, 4781 con el **motivo** (no «sin TPM»), sin error. La rama «Avanzada: rechazo» es F4 (D-F2-17) | F | MU-71 |
| TLS-C07\* | DACL de la llave de la CA | Dueño Administradores; DACL protegida; **solo** SYSTEM y Administradores; ninguna cuenta de servicio, `Users`, `Authenticated Users`, `Everyone`; el descriptor va en la **creación** (el falso rechaza cambios de seguridad posteriores) | F, W | MU-30, MU-32 |
| TLS-C08, O07\* | Segunda ejecución completa (`--crear-ca --emitir`) | 0 certificados nuevos en `My`, `GPOS NG TLS` y `Root`; 0 llaves; misma huella de CA; **0 eventos 4780** (nada se publicó); salida 0. Diff vacío del estado observable | F, V | MU-62, MU-84 |
| TLS-C09, S13\* (T2-C06) | CA existente; el registro cambia: (a) un nombre o IP nuevos que no están en la NC; (b) menos nombres (subconjunto); (c) «un equipo» a «servidor de sitio»; (d) «servidor de sitio» a «un equipo» | (a), (c) y (d): **salida 3**, mensaje con el procedimiento `--retirar --confirmar <primer nombre>` y después `--crear-ca --emitir` y la redistribución (P-7); evento 4782; **ninguna escritura**. (b): acepta y reemite las hojas con el SAN nuevo (T2-E04) | F | MU-61, MU-89 |
| TLS-C10\* | Dos CA válidas en `GPOS NG TLS` | Salida 4, no elige ninguna; mensaje con las dos huellas cortas | F | MU-62 |
| T2-C02\* | La CA tiene su certificado en `GPOS NG TLS` pero **la llave no existe** (sitio restaurado, SA-07) | Se detiene (4) sin crear una segunda CA y sin emitir; mensaje claro (QF2-06, D-F2-04) | F | MU-73 |
| TLS-C11 | CA con menos de 30 días de vigencia, o vencida | Salida 3 («hace falta reemplazar la CA»), sin emitir; con más de 30 y menos de 90 días: toda hoja nueva lleva `NotAfter` ≤ el de la CA | U, F | MU-63, MU-90 |
| TLS-C12\* | Selector real de A con `HuellaApi` apuntando a la **CA** | El selector no la adopta: la CA no está en `My` (aunque su EKU incluya `serverAuth`); 4748 y sigue con el anterior | F | MU-72 |
| TLS-C13 | Dos sitios (códigos distintos) | Sujetos y SKI distintos; nunca el mismo DN | U | MU-62 |
| TLS-C14\* | Ningún archivo `.pfx`, `.p12`, `.pem`, `.key` ni PKCS#8 en `%TEMP%`, `%ProgramData%`, el directorio actual ni `tls\` (se compara el árbol y se buscan cabeceras `-----BEGIN`) | Cumple | W | MU-28 |
| TLS-C15, T2-C03\* | CA en `Root` (Q-8) | Solo la parte pública (`HasPrivateKey = false`), una vez, huella igual a la de la CA; **nada** en `CurrentUser\Root`; segunda ejecución no duplica | F, W | MU-46, MU-47, MU-74 |
| T2-C04 | La CA existe pero falta en `Root` (alguien la quitó) | Se vuelve a instalar, sin duplicar; el resultado (0 o 2) según D-F2-04 | F | MU-74 |
| T2-C05 | `Root` ya trae otro certificado con el **mismo sujeto** y otra llave (CA anterior de un `--retirar` incompleto) | No lo quita ni lo reemplaza; avisa o se detiene (D-F2-04) | F | MU-74 |
| TLS-C16\* | Dónde vive la CA | `LocalMachine\GPOS NG TLS` con su llave; **no** está en `My`; el verbo la halla por huella en ese almacén. Si W-TLS-01 prueba que el almacén propio no funciona: plan B de D-F2-15 | F, W | MU-72 |
| TLS-C17 | Sin salida a red | Con un manejador de red que lanza, crear, emitir y comprobar terminan igual | F | |

### 3.4 S y E: las hojas y la vigencia

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-S01\* | Perfil de la hoja con `AsnReader` | v3; serie aleatoria ≥ 16 octetos; ECDSA P-256 con SHA-256; `NotBefore` = − 1 h; `NotAfter` = + 90 d (no 397 ni 365) y **≤ el de la CA**; `cA = false` crítica; KU `digitalSignature`; EKU solo `serverAuth`; AKI = SKI de la CA; SAN presente; **CN = primer nombre del SAN** (PT-07); sin CDP, AIA ni NC; `FriendlyName` `GPOS NG TLS <Api\|Web> <AAAAMMDD>`; extensiones exactas | U | MU-19 a MU-25, MU-91 |
| TLS-S02 | 1000 emisiones con la misma CA | 1000 series distintas, ninguna con el bit alto en 1 sin relleno | U | MU-19 |
| TLS-S03, S04\* | SAN de la Web y de la API | Sitio: exactamente `NombresServidor` (DNS e IP), **sin `localhost` ni `127.0.0.1`** en ninguna de las dos (PT-01). Un equipo: `localhost`, `127.0.0.1`, `::1` | U | MU-22 |
| TLS-S05\* | Web y API en una corrida | Dos huellas y dos SPKI distintos | U, F | MU-26 |
| TLS-S06 | Sujeto de la hoja | Siempre CN ∈ SAN | U | MU-91 |
| TLS-S07\* | Cada hoja contra la CA con el validador independiente | `X509Chain` (`CustomRootTrust`) válida y `MatchesHostname(nombre, allowWildcards: false, allowCommonName: false)` para **cada** nombre del SAN; si no, no se publica | U-W, F | MU-61 |
| TLS-S08\* | Llave de la hoja | `MachineKey`, software, `ExportPolicy = None`, ECDSA P-256; nombre del contenedor sin datos del sitio ni secretos | F, W | MU-28, MU-29 |
| TLS-S09\* | DACL de la Web y de la API | Web: lectura solo `NT SERVICE\GPOS.Web` (más SYSTEM y Administradores). API: solo `NT SERVICE\GPOS.Api`. La Web no lee la llave de la API ni al revés; ni `Users` ni `Authenticated Users`; **`GENERIC_READ`, nunca control total**; dueño Administradores | F, W, V | MU-30, MU-31 |
| TLS-S10\* | La cuenta virtual no existe (MSI sin instalar) | Salida 4; **no** hay respaldo a otro grupo; no se publica nada | F, W | MU-30 |
| TLS-S11\* | «Comprobar que la abre» (D-12) | El acceso se **evalúa** sobre el descriptor con el SID de la cuenta; con la herencia denegada, falla y no publica. En la VM: el selector en marcha (LABT-05) | F, V | MU-34 |
| TLS-S12 | Hoja nunca más allá de la CA | `NotAfter` hoja ≤ `NotAfter` CA | U | MU-63 |
| TLS-S14 | NC de sitio | Sin `localhost`, `127.0.0.1` ni `::1` | U | MU-22 |
| T2-E01\* | `--servicio api`, `web` y `ambos` (por omisión) | `api` toca solo la API (llave, certificado, `HuellaApi`); `web` solo la Web; `ambos` las dos, **en el orden api → web** [D-F2-11] | F | MU-79 |
| T2-E02\* | `ambos` con la cuenta de **uno** inexistente | Todo o nada: salida 4 antes de crear nada; no se publica la API aunque su cuenta exista | F | MU-77 |
| T2-E03\* | Vigencia de «vigente» (D-11): restan 31 d, 30 d + 1 s, 30 d, 29 d, 1 d, vencida, aún no vigente, con SAN igual | Más de 30 d y SAN igual: **no hace nada** (0). 30 d o menos, vencida: reemite. Aún no vigente (reloj atrasado): no reemite y avisa del reloj. Fronteras con `FakeTimeProvider` | F | MU-39, MU-76 |
| T2-E04\* | La hoja vigente y el registro trae nombres **distintos que caben** en la NC (subconjunto) | Reemite con el SAN nuevo; la anterior sigue en `My` (no se borra) | F | MU-76 |
| T2-E05 | Comparación del SAN con los nombres: orden distinto, mayúsculas, duplicados, IP en forma larga | Se comparan **como conjunto normalizado**: no reemite por diferencias de orden o de mayúsculas [D-F2-10] | U, F | MU-76 |
| T2-E06\* | **Lo propio (D-19):** en `My` hay (a) una hoja nuestra vigente, (b) otra con el mismo `FriendlyName` firmada por **otra llave** pero con el mismo DN de emisor, (c) otra con sujeto parecido sin `FriendlyName` | Solo (a) cuenta como propia y vigente. (b) y (c) **no** cuentan y **no se tocan** nunca (ni borran ni sustituyen); la prueba verifica la firma con la llave pública de la CA, no el nombre del emisor | F | MU-75, MU-64 |
| TLS-R02\* | `--emitir --forzar` | Llave, serie, SPKI y huella nuevos; la anterior queda en `My` y se abre | U, F | MU-27, MU-44 |
| TLS-R05\* | Emitir no toca los servicios | 0 llamadas de parar, iniciar, reiniciar (prueba de arquitectura TLS-AR05) | F | MU-40 |
| TLS-R06 | Todo el tiempo sale de `TimeProvider`; reloj en 2031 | Cumple | U | MU-41 |

### 3.5 P: orden de publicación y registro (PT-02)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-P01\* | Secuencia de llamadas al falso en una emisión, por servicio | Exactamente: **crear la llave con su descriptor** → emitir → importar a `My` → comprobar (descriptor, abre, cadena, nombres) → publicar. La prueba afirma el **orden** de la lista; con la mutación «descriptor después de crear» el falso la hace fallar | F | MU-33, MU-34 |
| T2-P11\* | Cada sub-paso de la comprobación 4.4 falla **solo**: (a) el descriptor no es el exacto; (b) la llave no abre como quien ejecuta o no coincide con el certificado; (c) la cadena no valida; (d) un nombre del SAN no pasa `MatchesHostname` | No publica; salida 1; 4782; el valor anterior del registro intacto byte a byte; el certificado anterior sigue en `My` y utilizable | F | MU-34, MU-78 |
| TLS-P02\* | Fallo inyectado en **cada** paso de P01 (lista de pasos de la costura), para la Web y para la API | Valor anterior intacto; anterior sigue; una segunda ejecución converge; **lo creado por el intento fallido y no publicado se retira junto con su llave** (a lo sumo un huérfano por servicio, ver D-F2-05) | F | MU-33, MU-45, MU-78 |
| TLS-P03\* | Valor publicado | `REG_SZ`; 64 hexadecimales en mayúsculas; SHA-256 del DER (no SHA-1, no minúsculas, no el hash del SPKI); solo `HuellaApi`/`HuellaWeb`; **ningún `HuellaAnterior`** ni otro valor; el resto de los valores y la ACL de la clave, byte a byte iguales | F, W | MU-35, MU-36 |
| TLS-P04 | Vista del registro | Vista de 64 bits explícita (`reg query /reg:64` ve el valor, `/reg:32` no) | W, V | MU-35 |
| TLS-P05 | La Web falla después de publicar la API | La API ya publicada es coherente; la Web conserva su valor; el verbo informa por servicio y sale 1 | F | |
| TLS-P06\* | La clave del registro no existe, o es ajena | No la crea (escritor único: `red`); salida 4 **antes de crear nada** | F, W | MU-37 |
| TLS-P07 | Dos corridas a la vez | Una espera 60 s y, si no obtiene el cerrojo, sale 1; nunca dos emisiones simultáneas; cada `HuellaX` corresponde a un certificado que existe y se abre | F, W | MU-38 |
| TLS-P09 | Selector real de A con el registro y el almacén falsos del verbo | En ≤ 5 min (reloj adelantado) toma el nuevo: evento 4749, el anterior sirve hasta entonces | F | MU-33 |
| TLS-P10 | Atributos del certificado publicado | Llave, EKU `serverAuth` y vigencia: el selector real lo acepta; los de `CertificadoPrueba.Servidor(usoServidor: false)` y vencido, no | F | |
| T2-P12\* | `tls` y `red` en cualquier orden (PV-F-04) | Misma clave final (modo, puerto, huella); ni `red` borra `HuellaApi` ni `tls` escribe `ModoRed`, `PuertoApi` o `NombresServidor`; con modo sin huella, el arranque da 4747 (documentado) | F | MU-37 |

### 3.6 X: carpeta `Servidor\tls\` y `ca.cer`

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-X01\* | Contenido de `tls\` | Solo el DER de `ca.cer` (parseable, = `RawData`); ninguna cabecera `BEGIN PRIVATE KEY`, PKCS#8 ni PKCS#12 | F, W | MU-28 |
| TLS-X02\* | DACL de `tls\` | Creada **junto con `Servidor`** en una sola operación con su DACL: dueño Administradores; escritura solo SYSTEM y Administradores; lectura `Authenticated Users`; sin herencia de abajo hacia arriba | F, W | MU-55 |
| TLS-X03\* | Raíz `%ProgramData%\GPOS NG` ausente | Salida 4; el verbo **no** la crea | F, W | MU-55 |
| TLS-X04\* | `tls\` ya existe con DACL ajena, o es creada por un no administrador | **Salida 4 sin corregirla** (4.8; criterio de ADR-77, punto 3). El plan general decía «se corrige o se detiene»: cambia | F, W | MU-87 |
| TLS-X05 | `tls\` o `ca.cer` es punto de reanálisis (unión, enlace simbólico o duro) | No lo sigue; salida 4 | W | MU-57 |
| TLS-X06\* | Escritura atómica | Temporal **dentro** de la carpeta protegida, reemplazo; si el proceso muere a la mitad, el archivo anterior queda entero | F, W | MU-56 |
| TLS-X07 | Se reescribe solo si cambia el contenido | Fecha y DACL sin cambio en la segunda corrida | F | MU-88 |

### 3.7 K: `--comprobar` (condicionado a D-F2-01)

Solo lectura. Se escriben ya con `Trait("Fase","F2-D")` para moverlos a F3 si B lo decide.

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| T2-K01\* | Estado sano (CA, dos hojas vigentes, publicadas, con ACL exacta, nombres iguales) | Salida 0; informa estado de la CA, días que quedan de cada hoja, «CA en software» (si aplica), cadena, nombres y ACL | F | MU-81 |
| T2-K02\* | **Sin elevación** | Informa AVISO («sin elevación no se pudo comprobar la ACL de la llave») y salida 2, **nunca OK/0**; no escribe nada | F | MU-81 |
| T2-K03\* | El falso registra **0 escrituras** (almacén, registro, carpeta, evento 4780 a 4782, tarea) y no toma el mutex de escritura [D-F2-01] | Cumple | F | MU-80 |
| T2-K04 | Estados con algo mal, uno por uno: sin CA; sin hoja; hoja sin ACL del servicio; hoja con ACL ajena; publicada ≠ lo que existe; publicada apunta a la CA; CA en software; dos CA; nombres del registro que no caben; hoja con ≤ 20 días | Cada uno se reporta con su motivo y el código que fije D-F2-01 (AVISO = 2; FALLA = [D-F2-01]); ninguno se corrige | F | MU-81 |
| T2-K05 | `--salida json` | JSON válido y estable (esquema por definir [D-F2-01]); **sin** rutas de llaves, descriptores completos ni huellas más largas que las necesarias; el mismo contenido que la salida de texto | U, F | MU-82 |
| T2-K06 | Umbral de días de la hoja en `--comprobar` | El mismo que `comprobar-servidor` de A: verde con más de 20 d (20 d + 1 s) y rojo con 20 d o menos (K-11) [D-F2-01] | F | MU-39 |

### 3.8 EV: eventos (franja 4780 a 4789)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| T2-V01\* | Emisión y publicación con éxito | **4780** (Información), uno por servicio publicado, con el servicio y la huella **corta**; sin 4780 en una corrida idempotente | F | MU-84 |
| T2-V02\* | CA fuera del TPM | **4781** (Aviso) una vez, al crearla; no se repite en corridas siguientes (o se repite; D-F2-03) | F | MU-71 |
| T2-V03\* | Salidas 1, 3 y 4 | **4782** (Error) con el motivo y **sin secretos** (huella corta como mucho; nunca ruta de llave, descriptor completo, contraseña ni `e.Message` de una excepción con datos: SPX-09/PV-S-12) | F | MU-83 |
| T2-V04 | Ids | Los diez (4780 a 4789) declarados como `public static readonly EventId` en `EventosTls`, sin repetir (`EventIdUnicosTests`) y dentro de la franja; los 4783 a 4789 solo se **declaran** en F2 [D-F2-08] | U | MU-85 |
| T2-V05 | Origen | Todo evento va con el origen `GPOS.Instalacion`; ningún evento sin origen registrado | F | MU-85 |

### 3.9 AR: arquitectura (suite)

| ID | Qué comprueba | Mut. |
|---|---|---|
| TLS-AR01 | En `src/GPOS.Migracion/Tls`: ni `DateTime.Now/UtcNow` ni `DateTimeOffset.Now/UtcNow` | MU-41 |
| TLS-AR02 | Ni `Export(X509ContentType.Pfx\|Pkcs12)`, ni `ExportPkcs8PrivateKey`, ni `X509KeyStorageFlags.Exportable`, ni `File.Write*` con material de llave, ni variables de entorno para secretos | MU-28 |
| TLS-AR03 | El registro se abre con `RegistryView.Registry64`; los nombres de los valores salen de `ValoresRegistroServidor` | MU-35 |
| TLS-AR04 | Sin `SHA1`, `GetCertHashString()` sin algoritmo, `Thumbprint` como identidad, `HttpClient` ni `ServicePointManager` | MU-36 |
| TLS-AR05 | `Tls` no referencia `GPOS.Api` ni `GPOS.Web` ni `Anillo`, y `Anillo` no referencia `Tls`; no reutiliza la llave ES256 | |
| TLS-AR06 | Los diez EventId (ver T2-V04) | MU-85 |
| TLS-AR07\* | `X509Store`, `CngKey`, `CertEnroll`, `ECDsaCng` con escritura y toda E/S de registro, carpeta, tarea y servicios pasan por **`IAlmacenMaquina` e `ISistemaServidor`** (PV-F-05); ninguna clase de `Tls` los usa directo | MU-93 |
| T2-AR08 | `tls` y `red` comparten la pieza que escribe la clave (PV-F-02): `ComandoTls` no llama a `CrearClaveRed`, `ProtegerClaveRed` ni `EscribirValorRed` directo | MU-37 |
| T2-AR09 | `tls` no declara un parser de nombres propio (TLS-N20): ningún `Regex` de etiqueta DNS en `Tls/` | MU-07 |

**Cuenta:** 91 casos del plan general (varios agrupados arriba bajo una fila) más 39 `T2-xx` = 130; la tabla agrupa los del plan general que no cambian (TLS-S02, etc.) en la fila de su familia.

---

## 4. Requisitos de testabilidad para B (F2)

Se suman a R-T1 a R-T8 (plan general), R-A1 a R-A10 (anillo) y R-F1 a R-F10 (F4). Sin ellos los casos F de las secciones 3.3 a 3.6 pasan a W.

| ID | Costura | Para qué |
|---|---|---|
| **R-2.1** | **`IAlmacenMaquina` ampliada, con su falso en memoria.** Hoy (`b/f1-anillo`) solo `CrearLlaveRsa`, `LeerLlave`, `BorrarLlave`, `Buscar`, `Agregar`, `Quitar`. Falta: (a) `CrearLlaveEcdsa(ParametrosLlaveEcdsa)` con proveedor **`Tpm` o `Software` como parámetro** (hoy `ParametrosLlaveRsa.Proveedor` es fijo), con descriptor en la misma llamada; (b) `InfoLlave` con curva y proveedor para ECDSA (QT-08); (c) **`Listar(almacen)`** con sujeto, emisor, `FriendlyName`, vigencia, huella, `RawData` y `TieneLlave`, para reconocer lo propio (D-19) y las dos CA (C10); (d) **almacenes nombrados**: crear/abrir `GPOS NG TLS`, `My`, `Root`; (e) **`EvaluarAcceso(llave, sid)`** → derechos efectivos sobre el descriptor, para TLS-S11 (D-12); (f) `Quitar` con su llave y su descriptor | T2-C01/C02, C05, C07, E06, S09 a S11, P11 |
| **R-2.2** | El **falso rechaza cambios de seguridad posteriores** a la creación de la llave y **registra el orden** de todas las llamadas (el patrón de `AlmacenMaquinaFalso` de F1, R-A3) | P01, C07, S09 |
| **R-2.3** | **Inyección de fallo por paso** (`FallarEn(n)` o por nombre del paso) en la emisión, y fallo al crear en el proveedor TPM | P02, P11, C01 |
| **R-2.4** | **`ConstructorPki` puro** (R-T1): `CrearCa(firmador, sujeto, nombres, ahora)` y `EmitirHoja(...)` que reciben `ECDsa` o `X509SignatureGenerator` (la CA en el TPM no es un `ECDsa` en memoria) y `TimeProvider`; devuelven DER. Una interfaz de serie (`IGeneradorSerie`) es opcional | U |
| **R-2.5** | **Cerrojo nombrado** detrás de una costura (`ICerrojoNombrado.Obtener(TimeSpan)`) con `TimeProvider`, para el mutex y, si se firma SA-08, su DACL (R-A9 del anillo) | G09, P07 |
| **R-2.6** | **`ISistemaServidor` (PR-V) en F2:** lo que existe [V]: `Elevado`, `ResolverSid`, `LeerCarpeta`, `CrearCarpeta`, `LeerClaveRed`, `EscribirValorRed`, `EscribirEvento`, `ContarEventos`. **Falta** `EscribirArchivoAtomico(ruta, bytes)` (hoy solo `CopiarArchivo`) y una forma de simular la muerte a mitad (R-T8) | X06 |
| **R-2.7** | **Resultado estructurado:** `ComandoTls.Ejecutar` devuelve `ResultadoTls(Codigo, Mensajes, Eventos)`; `--comprobar` se construye de un DTO; la salida JSON se genera del DTO (orden estable) | K01 a K06, O03 |
| **R-2.8** | **Plataforma, elevación y entorno inyectables** (`esWindows`, `ISistemaServidor.Elevado`, lector de variables de entorno): para Linux, UAC y TLS-G04 en la suite | O05, O01, G04 |
| **R-2.9** | **Oráculo independiente:** `tests/GPOS.Tests/Tls/Oraculo/` con un lector DER estricto (`AsnReader`) y un constructor de hojas «malas» (`H-FUERA`, `H-MEZCLA`, `H-SUFIJO`, `H-PADRE`, `H-SUB`, `H-COMODIN`, `H-IPFUERA`, `H-IPMAP`) que **no importa** código del verbo; vectores `docs/contratos/vectores/adr090-tls.v1.json` (precedente `adr077-carpetas.v1.json`). Si `PkiLaboratorio` de A ya existe, se reutiliza; si no, lo escribo yo (0,2 dp) | C01 a C03, S01, N11/N12 |
| **R-2.10** | **Ejecutor de Windows en CI** para los casos U-W (`X509Chain` con `CustomRootTrust` es de la plataforma). Si CI es Linux, esos casos pasan a W (D-F2-18) | C03, S07 |
| **R-2.11** | **El primer commit de B es el esqueleto:** interfaces, `ComandoTls` con las acciones, `ConstructorPki` y `NameConstraints` con firmas y `NotImplementedException`, `EventosTls` completo. Así las pruebas **compilan y fallan en rojo** el primer día | Sección 7 |
| **R-2.12** | **`InternalsVisibleTo`** de `GPOS.Migracion` a `GPOS.Tests` (en PR-V, `ComandosServidor` es `internal` y no se puede ejercitar desde la suite, H-11 de mi plan de PR-V) | G03, G04 |
| **R-2.13** | **`ModoRed`/`NombresServidor` por una sola lectura** (`LecturaRed` inmutable que pasa a todas las piezas) | G05 |

---

## 5. Casos de laboratorio en `VM-SRV` (referencias LABT-xx)

**Reglas heredadas:** las del plan general (sección 5) y las de mis guiones: solo `VM-SRV` (y `VM-PUESTO` donde se indica) desde el punto de control `base`; una VM a la vez; `Preparar-Vm.ps1` crea el marcador de las guardas; ningún agente ejecuta esto, lo opera B; si algo falla no se corrige a mano, se anota y se restaura; evidencia sin llaves ni secretos; `Probar-Redaccion.ps1` antes de copiar fuera. **Precondiciones** (si falta una, el caso es `No se pudo`): el verbo `tls` publicado con F2; `GPOS.Api.msi` y `GPOS.Web.msi` instalados (existen las cuentas virtuales); el verbo `red` (PR-V) con `ModoRed=ServidorSitio` y `NombresServidor`; SQL no hace falta. Funciones de apoyo: `EstadoTls` del plan general (sección 5).

### 5.1 Casos del plan general que se ejecutan con F2 (sin cambios salvo lo anotado)

| ID | Qué | Cambio para F2 |
|---|---|---|
| **LABT-01** | Perfil real (DNS+IP, solo DNS, «un equipo») contra los vectores | Igual |
| **LABT-02** | Entradas inválidas en lote | Se reduce a la **paridad con `red`** (N20) y a la normalización y deduplicación; el lote sale del mismo vector |
| **LABT-03** | Cadena con CryptoAPI de la VM y CAPI2 | Igual; añade `H-SUB` (válida) |
| **LABT-04** | ACL reales de las llaves (`icacls` sobre el archivo de llave, sin copiar contenido) | CA, hoja Web y hoja API; ahora la CA está en `GPOS NG TLS`. La ruta de contenedor de ECDSA de máquina es [I] |
| **LABT-05** | La cuenta real abre la llave | Igual; el caso decide el plan B de D-F2-15 si el selector no ve la hoja |
| **LABT-06** | Renovación forzada sin reinicio | **LABT-06f2**: con `tls --emitir --forzar` (no `--renovar`); mismas medidas: PID, sonda y 4749 |
| **LABT-07** | Puesto con el reloj atrasado 10 min | Igual con `--emitir --forzar` |
| **LABT-08** | (a) sin MSI, (b) ACE que niega escribir el registro, (c) bucle de **50 muertes súbitas** | Igual; (c) sobre `--emitir`; verifica `ca.cer` entero y a lo sumo un huérfano por servicio |
| **LABT-11** | CA en `Root` y la Web a la API | Igual |
| **LABT-12** | Navegadores con la CA | Igual; solo si hay tiempo (dos horas) |
| **LABT-13** | TPM | Igual; condicionado a que VirtualBox emule TPM 2.0 [I]; si no, equipo físico de B (nunca la PC del propietario) |
| **LABT-15** | Sin privilegios | Igual |
| **LABT-16** | Idempotencia (dos corridas) | Igual |
| **LABT-18** | Sin salida a red (CAPI2, `pktmon`) | Igual |
| **LABT-20** | Linux | Solo si se publica allí |

### 5.2 Casos nuevos de F2

**Primero, antes de LABT-01:** los cuatro casos W de verificación de supuestos [I] que el blueprint declara sin verificar (sección 13). Si uno falla, hay un plan B (D-F2-15) y se cambia el diseño **antes** de seguir.

| ID | Caso | Cómo | Esperado | Evidencia | Mapea |
|---|---|---|---|---|---|
| **W-TLS-01** | Almacén propio `GPOS NG TLS` | Proceso de la VM: `X509Store("GPOS NG TLS", StoreLocation.LocalMachine)` con `OpenFlags.ReadWrite`; guardar un certificado con llave ECDSA; cerrar y reabrir **en otro proceso**; `certutil -store "GPOS NG TLS"` | El almacén se crea; el certificado vuelve **con su llave**; `My` no lo contiene; `certutil` lo lista | `certutil` sin llave, `EstadoTls` | Blueprint 4.2 [I]; TLS-C16 |
| **W-TLS-02** | ECDSA con descriptor en la creación | `CngKey.Create(ECDsaP256, nombre, parámetros)` en el proveedor de software con `MachineKey`, `ExportPolicy = None` y la propiedad `Security Descr` **en la misma llamada**; leer el descriptor; intentar cambiarlo después | Se crea con el descriptor; `ExportPkcs8PrivateKey` lanza; el cambio posterior lo decide el SO (se registra). Es el patrón de W-AN-01 aplicado a ECDSA | Salida, `icacls` | Blueprint 4.3; TLS-C07, S08 |
| **W-TLS-03** | `CopyWithPrivateKey` con `CngKey` persistida | Emitir una hoja con la llave de W-TLS-02, agregarla a `My`, reabrir por SHA-256 en otro proceso | El certificado conserva el enlace al contenedor de la máquina y la llave abre | Salida | Blueprint 13 [I]; TLS-S08 |
| **W-TLS-04** | `EvaluarAcceso` frente al SO | La implementación Windows de R-2.1(e) con el SID de `NT SERVICE\GPOS.Api` contra la llave real; luego `icacls /deny` y repetir | Coincide con el acceso real que logra el servicio (LABT-05) | Salida | D-12; TLS-S11 |
| **LABT-22** | Nombres difíciles en CryptoAPI | `NombresServidor` con `FD00::10`, `fd00::10` (duplicado) y `::ffff:10.0.0.10`; emitir; `X509Chain` y navegador por esas IP | Un solo `iPAddress` por IP; la forma `::ffff:` se valida como IPv6 (16 octetos) o se rechaza antes (D-F2-09); sin errores de NC | Volcados, JSON | T2-N01, N15 |
| **LABT-23** | Cerrojo ocupado (SA-08) | Un usuario **estándar** (`runas`) crea `Global\GPOS.Migracion.tls` y lo retiene; el administrador ejecuta `tls --emitir` | Salida 1 a los 60 s; 4782. **Mide** si un usuario estándar puede crear un mutex global (supuesto [I] de SA-08); resultado: decide si SA-08 hace falta | Salida, tiempos | T2-G09; SA-08 |
| **LABT-24** | Sitio restaurado: la CA se pierde (SA-07, informativo) | Con el estado de LABT-16: restaurar `base`, volver a instalar los MSI y ejecutar `tls --crear-ca --emitir`; el puesto conserva la CA vieja y abre `https://<nombre>` | CA nueva; el puesto con la vieja **falla** hasta reinstalar la CA; se mide cuánto toma redistribuir. Sin esperado (mide el RTO de P-7) | Capturas, tiempos | SA-07; T2-C02 |
| **LABT-25** | Salida 3 con nombres fuera de la NC | Cambiar `NombresServidor` a un nombre que no cabe; `tls --emitir` | Salida 3, mensaje del procedimiento, nada cambia (`EstadoTls` idéntico) | `EstadoTls` antes y después | T2-C06; P-7 |
| **LABT-26** | Tarea creada por una F2 (solo si D-F2-02 queda en «sí») | `schtasks /query /xml`; `schtasks /run` y `Last Result` | La acción existe y termina en 0; si no, **no se publica F2 con la tarea** | XML, código | QF2-03 |

### 5.3 Reparto por sesión y duración [I, ±50 %]

| Sesión | VM | Casos | Horas |
|---|---|---|---|
| F2-A | `VM-SRV` sola | W-TLS-01 a 04, LABT-01, 02, 04, 05, 15, 16, 18, 22, 23, 25 | 4,0 |
| F2-B | `VM-SRV` y `VM-PUESTO` a la vez (6,5 a 7,5 GB; B detiene su trabajo) | LABT-06f2, 07, 11, 12, 24 | 3,5 |
| F2-C | `VM-SRV` sola | LABT-03, 08 (a, b, c), 13, 26 (si aplica) | 2,0 |

Total unas **9,5 h**. No corren a la vez la suite completa y el laboratorio. LABT-13 depende del TPM de la VM; LABT-12 puede aplazarse a la sesión de navegadores de F3. Mapeo al reparto del plan general: F2-A + F2-C cubren la sesión 1 y la parte de fallos de la 3; F2-B, la 2.

---

## 6. Mutaciones nuevas (MU-65 a MU-93) y las del plan general que mata F2

Procedimiento (el de S168-08/P168-14): aplicar la mutación a una copia, correr los casos de la columna y registrar cuál falla. Una mutación que sobrevive es un caso que falta. Todas son responsabilidades; B las convierte en líneas.

| ID | Responsabilidad | Mutación | Lo mata |
|---|---|---|---|
| MU-65 | Orden de guardas | Crear la CA o una llave antes de comprobar elevación, registro, cuenta o carpeta | T2-G01, G02 |
| MU-66 | Alcance | `--emitir` crea la tarea programada (o una acción de F3 se admite en F2) | T2-G03, G08 |
| MU-67 | Entradas | Leer nombres, modo o `IP_NODOS` de la línea de comandos o del entorno | T2-G04 |
| MU-68 | Modo | Leer `ModoRed` dos veces y mezclar | T2-G05 |
| MU-69 | IP | `::ffff:a.b.c.d` codificada como IPv4 | T2-N01 |
| MU-70 | TPM | Detectar el proveedor con el método RSA-only (`PrivadaEnTpm`) | TLS-C05 |
| MU-71 | TPM | Falla al crear en el TPM: abortar, o seguir en software sin 4781 | T2-C01, TLS-C04, T2-V02 |
| MU-72 | Almacén | La CA en `My` en vez de `GPOS NG TLS` | TLS-C12, C16 |
| MU-73 | Una CA | Certificado de CA sin llave: crear otra CA o seguir | T2-C02 |
| MU-74 | Root | Duplicar al repetir, no reinstalar si falta, o pisar la CA ajena del mismo sujeto | TLS-C15, T2-C03 a C05 |
| MU-75 | Lo propio | Reconocer lo propio por `FriendlyName` o por el DN del emisor (sin verificar la firma) | T2-E06 |
| MU-76 | Vigente | Umbral `>=` en vez de `>` en 30 d; SAN comparado en orden o con mayúsculas; reemitir por diferencia de orden | T2-E03 a E05 |
| MU-77 | `ambos` | Publicar la API aunque la cuenta de la Web no exista | T2-E02 |
| MU-78 | Limpieza | Tras un fallo de la comprobación, dejar publicado o dejar la hoja y su llave huérfanas | T2-P11, TLS-P02 |
| MU-79 | `--servicio` | `api` también toca la Web (o al revés) | T2-E01 |
| MU-80 | `--comprobar` | Escribe (evento, valor, carpeta) o toma el mutex de escritura | T2-K03 |
| MU-81 | `--comprobar` | Sin elevación devuelve OK/0, o no detecta un estado malo | T2-K01, K02, K04 |
| MU-82 | `--comprobar` | El JSON trae rutas de llaves, descriptores o secretos | T2-K05 |
| MU-83 | Eventos | No emitir 4782 en una salida 1, 3 o 4, o emitirlo con secretos o `e.Message` | T2-G01, T2-V03 |
| MU-84 | Eventos | 4780 en una corrida idempotente, o sin servicio ni huella | T2-V01, TLS-C08 |
| MU-85 | Eventos | Ids fuera de franja, repetidos o sin origen | T2-V04, V05, TLS-AR06 |
| MU-86 | Cerrojo | Espera infinita o no liberar el mutex ante una excepción | T2-G09 |
| MU-87 | `tls\` | Corregir en silencio una DACL ajena (en vez de 4) | TLS-X04 |
| MU-88 | `ca.cer` | Reescribir siempre (cambia la fecha y la DACL) | TLS-X07 |
| MU-89 | Códigos | El 3 devuelve 1 o 4, o toca algo antes de salir con 3 | TLS-O03, T2-C06 |
| MU-90 | Vigencia | Emitir una hoja con una CA de menos de 30 d | TLS-C11 |
| MU-91 | Hoja | CN fuera del SAN, `FriendlyName` mal formado | TLS-S01, S06 |
| MU-92 | Nombres | No deduplicar IP (`FD00::10` y `fd00::10`) | TLS-N15 |
| MU-93 | Costuras | Una clase de `Tls` usa `X509Store`, `CngKey` o el registro directo | TLS-AR07 |

**Del plan general que aplican a F2:** MU-01 a 38, 40, 41, 46, 47, 55 a 63 completas; MU-39 y MU-45 parciales. **Las filas marcadas con \*** son las imprescindibles; sus mutaciones se anotan en el PR de F2 (ejecutadas y rojo/verde), como pide la regla del equipo C.

---

## 7. Orden de escritura (rojo primero) y esfuerzo

Premisa: B construye del 3 al 10-nov. Las pruebas se escriben **en una rama apilada sobre el esqueleto de B** (R-2.11) y fallan por `NotImplementedException` hasta que el código llega. No hay que esperar al verbo para empezar.

| Paso | Contenido | Casos | Nivel | Rojo contra | dp |
|---|---|---|---|---|---|
| **0** (antes del 3-nov, sin producto) | `adr090-tls.v1.json`, lector DER estricto y constructor de hojas «malas» (R-2.9); `EstadoTls.ps1` y guion de W-TLS | oráculo | — | — | 0,6 |
| **1** (con el esqueleto) | Núcleo puro: perfil CA y hoja, NC en bytes, series, SAN, N11/N12/N15/N18/N19/T2-N01 a N03, TLS-S01 a S07, R06, AR01 a AR04, AR09 | ~34 | U, U-W | `NotImplementedException` | 0,7 |
| **2** | Guardas, despacho, registro y códigos (bloque G), P06 y P12 con la pieza compartida, V01 a V03 | ~22 | F | Esqueleto de `ComandoTls` | 0,4 |
| **3** | CA: C04, C05, T2-C01 a C06, C07, C08, C10, C11, C12, C15, C16 | ~18 | F | Esqueleto de la costura | 0,4 |
| **4** | Hojas y publicación: S08 a S12, T2-E01 a E06, P01 a P05, P09 a P11, R02, R05, T2-P11 | ~26 | F | Esqueleto | 0,4 |
| **5** | `tls\`, `--comprobar` y eventos: X01 a X07, T2-K01 a K06, T2-V01 a V05, AR05 a AR08 | ~22 | F, U | Esqueleto | 0,3 |
| **6** (al cerrar B) | W: C14, S09, W-TLS-01 a 04, P04, X05, X06, mutex entre procesos | ~10 | W | Verde en la VM | 0,3 |
| **7** (con la VM) | Guiones del laboratorio y la evidencia (LABT-01 a 26) | 26 | V | — | 0,3 |
| **Mutaciones** | Las filas marcadas con \*, ejecutadas con B | — | — | — | 0,2 |
| | | **~130** | | | **≈3,3** |

(Las cifras de pruebas escritas suman 2,8 dp; las de laboratorio y mutaciones, 0,5 dp.)

**Reglas de la escritura:** (1) cada bloque se escribe **antes** del código que lo satisface (rojo), se verifica que falla por la razón correcta (un `Assert`, no un `NotImplementedException` ni un error de compilación) y se anota; (2) los pines de transición llevan `Trait("Transicion","F3")`; (3) los casos de `--comprobar` llevan `Trait("Fase","F2-D")` hasta que D-F2-01 se resuelva; (4) máximo 3 compilaciones a la vez y no corren juntas la suite completa y el laboratorio.

**Dependencias:** PR-V (`ISistemaServidor`, `DisposicionServidor`, `ValoresRegistroServidor`) debe estar unido el 3-nov o F2 se apila sobre `a/pr-v-verbos-servidor` (blueprint, sección 5: unos 0,25 dp de rebase); F1 (`IAlmacenMaquina`) unido antes del 5-nov.

---

## 8. Hallazgos de lectura (de este plan)

Ninguno Crítico ni Alto. **Cuatro Medios** que conviene decidir antes de que B construya.

| ID | Sev. | Hallazgo | Evidencia | Qué se pide |
|---|---|---|---|---|
| **QF2-01** | **Media** | **La costura `IAlmacenMaquina` de F1 no alcanza para F2.** Es RSA y software solamente (`CrearLlaveRsa`, proveedor fijo), no lista almacenes, no crea almacenes nombrados y no evalúa el acceso de un SID. F2 necesita ECDSA P-256 con TPM o software, `GPOS NG TLS`, `Root`, reconocer "lo propio" y las dos CA, y la comprobación de D-12. Si F2 la amplía sin ampliar a la vez el falso en memoria de F1, los casos F pasan a W | `IAlmacenMaquina.cs` de `b/f1-anillo` (`e1c6f516`) [V]; blueprint 4.2 a 4.4 y 5 | R-2.1: que F1 deje ya el esqueleto de la ampliación (aditiva, sin romper los tests de F1) o que F2 lo haga en su primer commit con el falso |
| **QF2-02** | **Media** | **`--comprobar` está en F3 (sección 1) y en F2 (sección 8).** El plan de pruebas lo necesita desde F2 para verificar que lo emitido es correcto sin tocar el estado, y la tabla de salidas (4.1) lo usa en la definición del código 2 | Blueprint 1 («Entra», fila F3), 4.1 y 8 (fila F2) [V] | Que B fije la fase. Mi recomendación: F2, porque `comprobar-servidor` de A y el laboratorio dependen de él |
| **QF2-03** | **Media** | **La tarea programada puede publicarse sin su acción.** 4.5 dice que `--emitir` crea o actualiza la tarea (`tls --renovar`); `--renovar` es de F3. Una F2 publicada con la tarea crearía una tarea de SYSTEM diaria que falla cada día (4782 diario, ruido que tapa avisos reales) | Blueprint 4.5 frente a 1 y 8 [V] | Que `--emitir` **no** cree la tarea en F2, o que F2 incluya una `--renovar` mínima. La prueba T2-G08 fija la decisión |
| **QF2-04** | Baja | **Código de salida con la CA en software.** 4.1: 2 = «hecho con aviso». 4.2: la CA fuera del TPM deja el aviso 4781. En una VM sin TPM (el caso normal de pruebas) el verbo terminaría con 2 en cada corrida; el paquete (Burn) y la tarea deben saber si un 2 es éxito | Blueprint 4.1 y 4.2 [V] | D-F2-03 |
| **QF2-05** | Baja | **`InterpretacionRed` no normaliza ni deduplica** y acepta `::ffff:10.0.0.10`. `tls` hereda su veredicto pero tiene que producir bytes: minúsculas, un solo nombre, IPv6 mapeada de 16 octetos | `InterpretacionRed.cs` e `InterpretacionRedTests.cs:255-266` en `feature/modelo-ng` [V] | T2-N01, TLS-N15; D-F2-09 |
| **QF2-06** | **Media** | **CA con certificado pero sin llave (sitio restaurado, SA-07).** El blueprint define "varias CA" (4) y la unicidad, pero no el caso de que la CA exista y no se pueda firmar con ella. Sin regla, el verbo podría crear una segunda CA (y, con "una por sitio", dejar a los puestos con la primera) o fallar con un error de CNG poco claro | Blueprint 4.2; mi revisión SA-07 [V] | D-F2-04; T2-C02 |
| **QF2-07** | Baja | **SA-08 no está firmado:** el mutex global sin DACL lo puede retener una cuenta que no sea administradora y la renovación y los avisos callan. F2 lo construye como está en 4.1 | Hoja de F1 («No firmado… SA-08»); blueprint 4.1 [V]; supuesto del mutex [I] | LABT-23 mide el supuesto; T2-G09 como pin |
| **QF2-08** | Baja | **El blueprint no dice qué se limpia si la emisión falla después de importar.** PT-02 y 4.4 dicen qué se conserva (el anterior) pero no el destino de la hoja nueva y su llave cuando la comprobación falla | Blueprint 4.4 | D-F2-05; TLS-P02, T2-P11 |
| **QF2-09** | Baja | **El blueprint cita H-SUFIJO y H-PADRE como el residual del `dNSName`;** esos son casos rechazados del diseño v3. El residual (subdominios permitidos por RFC 5280) es **H-SUB** | Blueprint 4.2; diseño v3 (`H-SUFIJO / H-PADRE / H-SUB`, línea 309) [V] | TLS-C03: H-SUB queda válida por diseño y se registra |
| **QF2-10** | Baja | **`--comprobar` sin elevación** debe informar AVISO (sección 6) pero necesita leer la ACL de la llave, que puede no ser legible sin elevar: el falso no lo dice, la VM sí | Blueprint 6 | T2-K02; LABT-15 |

---

## 9. Dudas para B

No inventé el contrato: donde falta, escribí el caso con el supuesto más probable (**[D]**). Las marcadas **(bloquea)** impiden escribir el caso o su esperado.

| ID | Duda | Supuesto | Casos |
|---|---|---|---|
| **D-F2-01** | **(bloquea)** `--comprobar`: ¿F2 o F3? ¿Qué toma como FALLA y AVISO y qué código da cada una? ¿Esquema del JSON? ¿Umbral de días (20 como `comprobar-servidor`)? ¿Toma el mutex? | F2; AVISO = 2; FALLA = 1; umbral de 20 d; sin mutex | T2-K01 a K06 |
| **D-F2-02** | **(bloquea)** ¿`--emitir` crea la tarea `\GPOS NG\Renovar TLS` en F2 (4.5) o solo en F3 (secciones 1 y 8)? Si F2 la crea, ¿existe `--renovar`? | No la crea en F2 | T2-G08, LABT-26, QF2-03 |
| **D-F2-03** | **(bloquea)** Salida con la CA en software: ¿0 o 2? ¿El 4781 se repite en cada corrida o solo al crear la CA? | 2 una vez al crear; 0 en las siguientes | TLS-C04, T2-V02, QF2-04 |
| **D-F2-04** | **(bloquea)** CA con certificado y sin llave (restauración): ¿salida 4 con el mensaje de «ejecute `--retirar` y `--crear-ca`»? `Root` sin la CA, o con otro certificado de mismo sujeto y otra llave: ¿reinstala, avisa o se detiene? | 4 para la CA sin llave; `Root` faltante se reinstala (0); `Root` ajeno: 4 | T2-C02 a C05, QF2-06 |
| D-F2-05 | Tras fallar la comprobación o la publicación, ¿se retira la hoja nueva y su llave en el mismo intento? ¿Cuándo se escribe `ca.cer` (antes de las hojas o después de publicar)? | Se retira lo propio de ese intento; `ca.cer` y `Root` antes de las hojas | TLS-P02, T2-P11, X |
| D-F2-06 | ¿SA-08 (cerrojo con DACL, 4784) entra en F2 o queda el mutex tal como está en 4.1? | Queda 4.1 (SA-08 sin firmar); pin de transición | T2-G09, LABT-23 |
| **D-F2-07** | **(bloquea)** Las acciones de F3 en una F2 (`--renovar`, `--importar`, `--exportar-publica`, `--retirar`, `--quitar-tarea`): ¿«no disponible» con salida 1, o acción desconocida? | Salida 1, «aún no implementada» (como `Servidor_sitio_da_1…` de PR-V) | T2-G03 |
| D-F2-08 | ¿`EventosTls` declara los diez ids en F2 o solo 4780 a 4782? | Los diez | T2-V04, AR06 |
| D-F2-09 | Normalización y deduplicación de nombres: ¿las hace `tls`? ¿`::ffff:a.b.c.d`: IPv6 de 16 octetos o rechazo? En «un equipo», ¿el primer nombre del sujeto de la CA es `localhost`? | `tls` normaliza y deduplica; mapeada = IPv6; CA `localhost` | T2-N01 a N03, TLS-N15 |
| D-F2-10 | «Vigente» (D-11): comparación del SAN como conjunto normalizado; ¿qué hace `--emitir` si `ModoRed` cambia entre dos lecturas de la misma corrida? | Conjunto; 4 «cambió mientras tls trabajaba» | T2-E03 a E05, G05 |
| D-F2-11 | `ambos` con la cuenta de un servicio inexistente: ¿todo o nada? ¿Orden api → web? | Todo o nada; api primero | T2-E01, E02, TLS-P05 |
| **D-F2-12** | **(bloquea)** `IAlmacenMaquina`: ¿la amplía F1 (esqueleto y falso) o F2 en su primer commit? ¿Quién escribe el falso? | F2, primer commit, con el falso | R-2.1, QF2-01 |
| D-F2-13 | `--emitir` sin CA (sin `--crear-ca`): ¿1 (uso) o 4 (guarda)? | 4 | T2-G01 |
| D-F2-14 | PR-V: faltan en `ISistemaServidor` la escritura atómica de archivos y el cerrojo con nombre; si PR-V no está unido el 3-nov, ¿F2 se apila sobre `a/pr-v-verbos-servidor`? | Se apila; las costuras faltantes se agregan en el esqueleto | R-2.5, R-2.6 |
| D-F2-15 | **Plan B de W-TLS-01:** si el almacén propio no funciona, el blueprint propone la CA en `My` con el rechazo de `cA = true` en el selector de A (QT-03). Ese cambio altera TLS-C12 y C16: ¿se decide en la primera sesión de VM y se reescriben esos dos casos? | Sí | TLS-C12, C16, LABT-05 |
| D-F2-16 | Residual de subdominios (H-SUB): ¿B acepta que la prueba lo registre como válido por diseño? | Sí | TLS-C03 |
| D-F2-17 | Avanzada: en F2 no hay camino que lea el perfil; ¿se confirma que ninguna prueba de F2 lo ejercita y que TLS-C06 pasa a F4? | Sí | C06 |
| D-F2-18 | CI: ¿corre la suite en un ejecutor de Windows para los casos U-W (`X509Chain` con `CustomRootTrust`)? | Sí | TLS-C03, S07 |

---

## 10. Qué no verifiqué

- Que `X509Store` con un nombre propio cree el almacén de la máquina, que `CopyWithPrivateKey` con una `CngKey` ECDSA persistida conserve el enlace, que el SO acepte el descriptor en la creación de una llave ECDSA y la ruta de contenedor de CNG para `icacls`: todos [I], van a W-TLS-01 a 04.
- Que `InterpretacionRed.ValidarNombres` rechace todos los vectores del plan general (N06, N09, N10, N14); lo que vi son sus pruebas (`InterpretacionRedTests.cs`), no su código completo, y N20 lo dirá.
- Que `LecturaCarpeta` (PR-V) traiga dueño, ACE y reanálisis; supuesto para X02 a X05.
- El código de `PkiLaboratorio` de A (si ya existe, se reutiliza; si no, lo escribo, R-2.9).
- Si VirtualBox emula TPM 2.0 (LABT-13) y si la CI es Windows (D-F2-18).
- Los 130 casos y las cifras de esfuerzo son [I, ±40 %]. Nada compiló ni se ejecutó.

### Cierre
- Estado: Completado (plan entregado; 6 dudas bloquean casos: D-F2-01, 02, 03, 04, 07 y 12)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-plan-pruebas-tls-f2.md`
- Supuestos: F2 es exactamente lo que dice la tabla de la sección 8 del blueprint, con `--comprobar` en F2 (QF2-02); F3 y F4 como en la sección 1; la CA vive en `GPOS NG TLS` (4.2); `red` y `tls` comparten la pieza que escribe la clave del registro (PV-F-02); las cifras de esfuerzo son [I]
- Decisiones candidatas a ADR: Ninguna (QF2-03 y D-F2-02 podrían terminar como nota en la hoja de F2/F3)
- Entregas a otros agentes: B (arquitecto-software) → D-F2-01 a D-F2-18, QF2-01 a QF2-06 y R-2.1 a R-2.13 antes del 3-nov, con el esqueleto de F2 como primer commit; A → que PR-V esté unido el 3-nov (o aceptar el apilado) y confirmar `EscribirArchivoAtomico` y el cerrojo en `ISistemaServidor`; auditor-seguridad → revisar T2-G01, TLS-C07, S09, X04 y T2-K05 antes de la ejecución en la VM
- Próximo paso recomendado: B responde las 6 dudas bloqueantes y deja el esqueleto de F2; C escribe los pasos 0 y 1 (oráculo y núcleo puro) antes del 3-nov
