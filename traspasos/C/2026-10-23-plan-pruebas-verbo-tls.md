```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 6 de B-a-C/2026-10-23-tareas-nuevas-para-c-4: plan de pruebas y casos de laboratorio del verbo `tls`)
Prioridad: Media
Repositorio y rama: GPOS-NG `origin/master` (ADR-90) y `origin/feature/modelo-ng` (lectura); área común
Estado: Abierto (17 dudas para B, sección 9; 6 bloquean casos)
```

# Plan de pruebas y casos de laboratorio del verbo `tls` (ADR-90, RT-02 a RT-04, PT-02, PT-03, PT-07, PT-10)

**Qué es.** Plan para que B construya `GPOS.Migracion tls` con las pruebas en la mano: nombres del sitio, autoridad certificadora (CA) propia por sitio, certificados del servicio (Web y API), certificado del cliente, renovación, tarea programada y lo que toca a la VPN. Reutiliza los casos LAB-xx del diseño v3 (`traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`, firmado Q-LAB-01 a 03) y los traduce a casos sobre el **producto**: el diseño v3 prueba un oráculo, no el verbo (sus bloques V y R traen 5 y 12 casos sobre el verbo; este plan trae unos 110 casos y 21 de laboratorio, casi todos ejecutables en la suite sin tocar el equipo).

**Método y límites.** Solo lectura: `git show` sobre `origin/master` (`b5cce2ee`, ADR-90 y hojas), `origin/feature/modelo-ng` (`4c277a29`, código y pruebas de `Red`, guiones del laboratorio) y `origin/a/pr-v-verbos-servidor` (`a3c71ce1`, el verbo `red` y el patrón `ISistemaServidor` / `SistemaServidorFalso`). No compilé ni ejecuté nada, no toqué ningún árbol. **El verbo `tls` no existe en ninguna rama** [V: `git ls-tree` de `src/GPOS.Migracion` y búsqueda de `tls`, `crear-ca`, `NameConstraints` en `origin/*`]. Por eso "las mutaciones" se enuncian sobre **responsabilidades** del verbo, no sobre `archivo:línea`; B las convierte en líneas al construir. Marcas: **[V]** leído en el texto citado; **[I]** inferido o conocimiento general de Windows, CNG o .NET, por confirmar al construir; **[D]** depende de una duda abierta de la sección 9.

**Fuentes.** `docs/adr/ADR-090.md` en `master` (RT-02: líneas 34 a 47; RT-04: 51 a 59; PT-01 a PT-10: 236 a 251; precisiones F-5 y F-6: 264 a 267; S2-04: 269); diseño v3 del laboratorio (secciones 4, 5, 6 y 11); `traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md` (4.1, 5.2 y 5.5); `traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (Q-2, Q-8); `avisos/B-a-A/2026-10-23-respuestas-tls-https-sesioninfo-y-firmas.md` (el verbo es de B, antes del 18-nov); `avisos/A-a-B/2026-10-23-pr-v-verbo-red-y-tls.md`; `docs/decisiones/2026-10-21-registro-laboratorio-adr90-virtualbox.md` y mi rediseño VirtualBox. Formato: el de mis planes de M-168 y T4-10.

## 0. Resumen para decidir

1. **El contrato del verbo está repartido en cuatro documentos** (ADR-90, PT-01 a PT-10, blueprint de A, diseño v3 del laboratorio) y tiene **huecos reales** (sección 9): sintaxis y códigos de salida, qué pasa si cambian los nombres con una CA ya emitida (las Name Constraints quedan fijas 10 años), qué se entiende por "certificados de la VPN", si la rotación de CA entra el 18-nov, cómo se entrega la contraseña de un PFX sin consola bajo Burn, y dónde se prueba el TPM. Escribí los casos con el supuesto más probable y los marqué **[D]**; no inventé el contrato.
2. **Lo más caro de equivocarse no se ve en una prueba funcional.** Cinco defectos que el verbo puede tener y que pasan "emitir, publicar y ver HTTPS": (a) Name Constraints no críticas o con la máscara mal puesta (la cadena sigue validando); (b) una llave de hoja legible por las dos cuentas de servicio o por `Users`; (c) la llave de la CA con una ACL que deja leerla a una cuenta de servicio, lo que además haría que el selector de A (que no comprueba el emisor, C-A3) sirviera la **propia CA** como certificado TLS, porque la CA lleva EKU `serverAuth` por Q-LAB-01 (a); (d) escribir el registro en la vista de 32 bits; (e) publicar la huella antes de comprobar que la cuenta abre la llave. Los casos TLS-C02, C07, C12, S08, P01 y P03 los matan.
3. **Arquitectura de pruebas en cuatro niveles** (sección 2): U puro (cualquier equipo, suite oficial), F con falsos (suite oficial), W real sobre el almacén de máquina (solo en la VM, con las guardas del diseño v3) y V laboratorio en `VM-SRV`. Casi todo está en U y F **si B parte el verbo en un núcleo puro y siete costuras** (R-T1 a R-T8, sección 8): es la condición para no cargar el laboratorio con casos que no necesitan VM.
4. **Oráculo independiente.** Los casos que decodifican certificados usan `AsnReader` y vectores de bytes fijos (propongo `docs/contratos/vectores/adr090-tls.v1.json`, precedente `adr077-carpetas.v1.json`), **nunca el constructor del verbo**. Si el verbo y la prueba comparten el escritor de Name Constraints, un error de codificación pasa en los dos lados.
5. **Mutaciones:** 64 en la sección 6, cada una con el caso que la mata. Al no existir el código, ninguna está "viva" todavía; son la lista de comprobación del revisor cuando B tenga el PR.
6. **Hallazgos de lectura** (QT-01 a QT-08, sección 7): ninguno Crítico ni Alto. Los dos que merecen decisión: QT-04 (con "certificado del cliente" las dos cuentas de servicio comparten una llave) y QT-01 (la renovación cada 60 días deja certificados y llaves que nadie retira).
7. **Esfuerzo [I, ±40 %]:** escribir las pruebas U/F/W unos **4,5 dp**; arnés y vectores 1,0 dp; ejecución del laboratorio 21 casos en `VM-SRV` unas **10 h** repartidas en 3 sesiones (más dos sesiones de reloj). Detalle en la sección 10. Los dos plazos de B: pruebas U/F antes de que B mezcle el verbo; laboratorio con la VM del instalador (18-nov).

## 1. Lo que se prueba: el contrato (oráculo) y su origen

`Estado`: **F** = firmado en ADR-90 o su hoja; **V3** = contrato del diseño v3 del laboratorio (firmado como diseño el 2026-10-20 con Q-LAB-01 a 03, pero no está en el texto de ADR-90); **A** = blueprint de A; **[D]** = abierto.

| # | Regla | Origen | Estado |
|---|---|---|---|
| K-01 | CA raíz **por sitio**, ECDSA P-256 con SHA-256, 10 años, `pathLen = 0`, `basicConstraints` crítica, KU `keyCertSign`+`cRLSign`, SKI y AKI | RT-02, RT-03, RT-04; diseño v3 secc. 5 | F / V3 |
| K-02 | Name Constraints **críticas**, escritas con `AsnWriter`: `dNSName` de los FQDN del sitio; `iPAddress` en /32 y /128; si no hay IP, `0.0.0.0/0` y `::/0` **excluidos**; en "un equipo", `localhost`, `127.0.0.1/32`, `::1/128` | RT-02; PT-07 (ADR-090.md:242) | F |
| K-03 | EKU `serverAuth` **en la CA** | Q-LAB-01 (a), firmada 2026-10-20 | F (hoja de la pregunta) |
| K-04 | `NotBefore` = emisión − 1 h en hojas **y en la CA**; `NotAfter` = emisión + 90 d (hoja) | O-07, LS-06, LS-22 | V3 [D-13] |
| K-05 | Llave de la CA en el TPM (Microsoft Platform Crypto Provider), no exportable, solo Administradores y SYSTEM, **ninguna cuenta de servicio la lee**; sin TPM, en software no exportable (solo Básica) y evento "CA en software" | RT-04; PT-10 H-13 | F |
| K-06 | Un certificado por servicio (Web y API), llaves distintas, ECDSA P-256 en el proveedor de software, no exportables, lectura **solo** para `NT SERVICE\GPOS.Web` o `NT SERVICE\GPOS.Api` | RT-02, RT-04 | F |
| K-07 | SAN de la API en "servidor de sitio" **sin `localhost`**; en "un equipo", con `localhost` | PT-01 | F |
| K-08 | Orden: emitir → dar lectura de la llave a la cuenta → comprobar que la abre → publicar la huella; el certificado anterior se conserva hasta su vencimiento | PT-02 | F |
| K-09 | Huella = SHA-256 del DER, 64 hex en mayúsculas, `REG_SZ` en `HuellaApi` y `HuellaWeb` de `HKLM\SOFTWARE\GPOS NG\Servidor` (vista de 64 bits); el verbo no escribe otro valor | blueprint 4.1 | A |
| K-10 | Tarea `GPOS NG\Renovar TLS` como SYSTEM, diaria y al iniciar el equipo; renueva con ≤ 30 días; avisos a 20, 10 y 3 días; binario bajo `Program Files\GPOS NG\…` con ruta absoluta y Authenticode | RT-04, PT-10 H-11, H-12 | F |
| K-11 | `comprobar-servidor` exige más de 20 días, subárboles `dNSName` e `iPAddress` en la CA, "CA en software" informativo | PT-10, O-02 | F / V3 |
| K-12 | Instala la parte pública de la CA en `LocalMachine\Root` del propio servidor, en los dos modos, en el paso 6 (después de los MSI); con certificado del cliente, no instala nada | Q-8 (respuestas de B); F-6 (ii) | F (F-6) |
| K-13 | `Servidor\tls\` bajo la raíz ya protegida, DACL explícita protegida: escritura solo Administradores y SYSTEM, lectura autenticados; solo la parte pública de la CA | RT-04, ADR-77, PT-10 H-12, P-77-2 | F |
| K-14 | Opción "certificado del cliente": huella en `LocalMachine\My` o PFX; comprueba EKU `serverAuth`, nombres en el SAN, algoritmo y vigencia; contraseña del PFX **no** por línea de comandos ni variable; renovación del cliente: avisa con los mismos plazos y toma el más reciente con el mismo sujeto y emisor | RT-02 (a), RT-04, hoja N-7 | F |
| K-15 | Nombres: 1 a 16; el primero DNS, no `localhost`, sin `.local`; mayúsculas a minúsculas; punto final, comodín, no ASCII y subredes rechazados; al menos un DNS | blueprint 4.1; PT-03; LAB-33 | A / V3 |
| K-16 | Idempotente: "si la CA y los certificados vigentes existen, no hace nada" | ADR-090.md (Impacto, paso `tls`) | F [D-11] |
| K-17 | La desinstalación conserva CA y certificados; retirarlos es un verbo aparte, explícito | ADR-090.md (Impacto) | F |
| K-18 | Eventos 4780 a 4789 (verbo y tarea) | blueprint 5.5; reparto de EventId | A [D-07] |
| K-19 | El verbo es solo Windows (ADR-129) | ADR-129; blueprint 4.2 | A [D-17] |

## 2. Niveles de ejecución, reglas y qué se reutiliza

| Nivel | Qué es | Dónde corre | Atributo |
|---|---|---|---|
| **U** | Núcleo puro: `CertificateRequest`, `AsnWriter` y reglas de nombres con llaves en memoria y `TimeProvider` falso. Nada de almacenes, registro, ACL ni tareas | Suite oficial, cualquier equipo | `[Fact]`, `[Trait("Esquema","Neutral")]` |
| **F** | El verbo completo contra falsos de las costuras (almacén de llaves y de certificados, registro, ACL, tareas, eventos, consola, archivos), como `SistemaServidorFalso` de `a/pr-v-verbos-servidor` [V: `tests/GPOS.Tests/Servidor/SistemaServidorFalso.cs`]. Incluye integración con el `SelectorCertificadoServidor` **real** de A y un Kestrel de prueba en *loopback* (patrón de `EscuchaTlsKestrelTests` y `CertificadoPrueba`) | Suite oficial | `[Fact]` neutral |
| **W** | Almacén de máquina, registro, ACL y tareas **reales**. Escribe en `LocalMachine` | **Solo en la VM**, con las cuatro guardas del diseño v3 (7.1, LS-11) | `[FactLaboratorioTls]` (omite sin `GPOS_LAB_TLS=1`) |
| **V** | Laboratorio: el verbo publicado, servicios reales, `VM-SRV` y `VM-PUESTO` de `LFMB`, una VM a la vez | Operado por B | Casos LABT-xx, sección 5 |
| **T** | Requiere TPM físico | Equipo con TPM 2.0 que designe B | LABT-13 [D-09] |

**Reglas.** (1) Un caso W que escribe en `LocalMachine\*` corre en su propio proceso y deja el estado limpio antes y después (`Limpiar-Laboratorio.ps1` por marcador `O=GPOS-LAB-TLS`; ver sección 5). (2) Sin `Thread.Sleep`: todo el tiempo pasa por `TimeProvider` (`FakeTimeProvider`). (3) Nada escribe un PFX ni una llave a disco (ADR-44); las llaves de CA de las pruebas son efímeras. (4) Un caso nunca se anota "Cumple" si su precondición no existía: `No se pudo`. (5) El oráculo no importa el código del verbo (sección 0, punto 4). (6) Carpeta: `tests/GPOS.Tests/Tls/` (U/F) y `tests/GPOS.Tests/Laboratorio/Tls/` (W; la del diseño v3).

**Reutilizable hoy** [V, `origin/feature/modelo-ng` `4c277a29`]: `CertificadoPrueba` (`tests/GPOS.Tests/Red/SoporteTls.cs`: ECDSA en memoria, `ConRaiz`, `ConLlaveQueNoSeAbre`), `SelectorCertificadoServidorTests`, `EscuchaTlsKestrelTests`, `AlmacenCertificadosServidorWindowsTests` (patrón de omisión `FactConCertificadoDelEquipo`), `InterpretacionRedTests` (gramática de nombres), `FuenteConfiguracionRedWindowsTests`, `EventIdUnicosTests`; y los guiones `tests/laboratorio-adr090/` (`Preparar-Vm.ps1` ya existe, `Probar-Redaccion.ps1`, `Recoger-Evidencia.ps1`, `Puntos-Control.ps1`). `CertificadoPrueba` **no sirve como oráculo del perfil** (no escribe Name Constraints ni `pathLen` correctos: `ConRaiz` pone `pathLen = 0` pero sin NC); el arnés del diseño v3 (`PkiLaboratorio`, que construye A) sí.

## 3. Bloques de casos

Columnas: **ID** · entrada · esperado · nivel · mutación que lo mata (MU-xx, sección 6). "Mut." vacío = control o caso informativo.

### 3.1 Nombres del sitio (`NOMBRES_SERVIDOR`)

Oráculo: K-15, `InterpretacionRed` del blueprint (4.1), LS-09, LAB-33 y la revisión del PR #122 (IP no canónicas). **Pregunta de fondo [D-15]:** si `tls` reutiliza el parser de `red` (recomendado) o tiene el suyo; TLS-N20 lo exige.

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-N01 | `srv-c01.gposlab.test` | Acepta; es el `dNSName` de la NC y del SAN | U | MU-01 |
| TLS-N02 | `SRV-C01.GposLab.TEST` | Normaliza a minúsculas en NC y SAN; ninguna mayúscula en los bytes | U | MU-01 |
| TLS-N03 | `srv.test.` (punto final) | Rechazo; ninguna CA creada; salida distinta de 0 | U, F | MU-02 |
| TLS-N04 | `*.gposlab.test`, `f*.gposlab.test`, `*` | Rechazo | U | MU-03 |
| TLS-N05 | `srv.local`, `SRV.LOCAL`, `srv.local.`, `a.b.local` | Rechazo (PT-03). Control: `srv.localhost.test`, `locale.test` aceptados | U | MU-04 |
| TLS-N06 | Etiqueta no ASCII (`servidór.test`); A-label `xn--servidr-9ya.test` | Primera: rechazo. Segunda: se acepta como texto ASCII y la NC lo lleva igual (LAB-78) [D-15] | U | |
| TLS-N07 | Solo IP (`192.168.50.10`), sin ningún DNS, en "servidor de sitio" | Rechazo (O-02): la CA no limitaría los DNS | U | MU-05 |
| TLS-N08 | Primer nombre es una IP; primer nombre `localhost` (sitio) | Rechazo ambos. En "un equipo" no se pasa nombre alguno y la NC lleva `localhost` | U | MU-05 |
| TLS-N09 | Etiqueta de 64 caracteres; nombre de 254; `a..b`; `-a.test`; `a-.test`; con espacio, `_`, `/`, `:`, `@`, tabulación, NUL; cadena vacía | Rechazo (el guion bajo, dato [D-15]) | U | |
| TLS-N10 | Nombre de una sola etiqueta (`srv01`) | **[D]** Decide B. Si se acepta, el SAN lleva `srv01` y la NC también; si se rechaza, el mensaje dice cómo escribir el FQDN | U | |
| TLS-N11 | IPv4 `192.168.50.10` | NC: `iPAddress` de 8 octetos (dirección ‖ `FF FF FF FF`); SAN: 4 octetos. Bytes contra el vector | U | MU-10, MU-11 |
| TLS-N12 | IPv6 `fd00:50::10`, y su forma larga `fd00:0050:0:0:0:0:0:10` | Misma salida; NC de 32 octetos (dirección ‖ 16 × `FF`); SAN de 16 octetos | U | MU-10, MU-11 |
| TLS-N13 | IP no canónica o ambigua: `010.0.0.5`, `10.1`, `167772161`, `0x0A000005`, `192.168.050.010`, `::ffff:10.0.0.5`, `fe80::1%eth0`, `192.168.50.0/24`, `192.168.50.10/32` | Rechazo todas (el prefijo `/32` explícito, dato [D-15]; `IpNodos` sí lo admite) | U | MU-07 |
| TLS-N14 | IP reservadas: `0.0.0.0`, `255.255.255.255`, `224.0.0.1`, `::`, `ff02::1`, `127.0.0.2` en sitio | Rechazo (colisionan con la exclusión `/0` o no son del servidor) [I] | U | MU-07 |
| TLS-N15 | Duplicados `a.test`, `A.test`, `a.test` | Un solo `dNSName` en NC y SAN, o rechazo con mensaje [D-15]; nunca dos entradas iguales | U | |
| TLS-N16 | 16 nombres; 17 nombres | 16 acepta (SAN con 16 entradas); 17 rechazo | U | MU-06 |
| TLS-N17 | Lista vacía, solo espacios, separadores mezclados (`;`, `,`, espacio, salto de línea) | Rechazo de la vacía; separadores según la gramática de `red` | U | |
| TLS-N18 | Solo IPv4 (más un DNS) | NC permite solo esa IPv4; una hoja con una IPv6 en el SAN falla la cadena (control con `X509Chain`) | U, W | MU-08 |
| TLS-N19 | Solo DNS (sin IP) | NC con **exclusión** `0.0.0.0/0` (8 octetos en cero) y `::/0` (32 en cero); sin subárbol `iPAddress` permitido. Hoja con SAN IP: falla la cadena (LAB-13/14) | U, W | MU-08 |
| TLS-N20 | Un mismo vector de entradas (el de `InterpretacionRedTests` más los de arriba) a `red` y a `tls` | El mismo veredicto aceptado/rechazado en ambos [D-15] | U | MU-07 |
| TLS-N21 | Sugerencia de nombre (PT-03: "incluye el código del sitio, sin `.local`") **[D-01]** | El nombre sugerido cumple N01 a N09, contiene el código del sitio en minúsculas y no termina en `.local` | U | |
| TLS-N22 | Los nombres no se resuelven: sin consulta DNS ni de red durante la validación | Con un resolvedor que falla, el verbo valida igual | F | |

### 3.2 Autoridad propia por sitio (CA)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-C01 | Perfil de la CA, decodificado con `AsnReader` en DER estricto | v3; serie ≥ 16 octetos aleatorios, positiva; firma `ecdsa-with-SHA256`; emisor = sujeto; SPKI ECDSA P-256; `NotBefore` = emisión − 1 h (± 2 min); `NotAfter` = emisión + 10 años (± 1 d); `basicConstraints` crítica `cA` con `pathLen = 0`; KU crítica solo `keyCertSign` y `cRLSign`; EKU solo `serverAuth`; SKI; **conjunto exacto de extensiones** (ninguna de más: sin SAN, CDP, AIA, políticas) | U | MU-13 a MU-18 |
| TLS-C02 | Name Constraints: seis combinaciones (DNS; DNS+IPv4; DNS+IPv6; DNS+IPv4+IPv6; "un equipo"; sin IP) contra bytes de referencia | **Crítica**; `permittedSubtrees` con `dNSName` `[2]` y `iPAddress` `[7]`; `excludedSubtrees` solo cuando no hay IP; sin `minimum` explícito (DEFAULT 0 se omite en DER); sin `maximum`; orden de subárboles el de entrada; el decodificador estricto lee todo | U | MU-09 a MU-12 |
| TLS-C03 | Efecto: cada CA de C02 con las hojas del perfil, validadas con `X509Chain` (`CustomRootTrust`, `NoFlag`, sin descargas, `RevocationMode.NoCheck`) | Válidas: `H-DNS`, `H-IP`. Rechazadas con marca de NC: `H-FUERA`, `H-MEZCLA`, `H-SUFIJO`, `H-PADRE`, `H-COMODIN`, `H-IPFUERA`, `H-IPMAP` (nombres del diseño v3, secc. 5). Control: la misma hoja bajo una CA sin NC es válida (si no, el caso no prueba nada, LAB-05) | U (Windows) / W | MU-09, MU-10 |
| TLS-C04 | CA sin TPM | Llave en el proveedor de software de CNG (`MachineKey`), `ExportPolicy = None`; `ExportPkcs8PrivateKey()` lanza; evento "CA en software" (H-13); salida 0 en Básica | F, W | MU-28 |
| TLS-C05 | CA con TPM | La llave está en `Microsoft Platform Crypto Provider`, no exportable; el verbo firma las hojas con ella [D-09] | F (proveedor falso), T | |
| TLS-C06 | Avanzada sin TPM | Rechazo, sin CA (RT-09). **[D-09]** si el verbo recibe el perfil o lo lee del sistema | F | |
| TLS-C07 | DACL de la llave de la CA | Solo SYSTEM y Administradores; **ninguna** cuenta de servicio, `Users`, `Authenticated Users` ni `Everyone`; sin herencia de una DACL laxa | W | MU-30, MU-32 |
| TLS-C08 | Segunda ejecución con CA vigente | Misma huella, 0 certificados nuevos en `My` y `Root`, 0 llaves nuevas, salida 0, mensaje "ya existe" | F, W | MU-62 |
| TLS-C09 | CA existente y nombres que **no** están en su NC (agregar un nombre o una IP) **[D-02]** | Rechazo con mensaje que dice que la CA no los cubre y que hace falta rotar; salida distinta de 0; ningún certificado emitido; nada cambia. Subconjunto de los nombres de la NC: acepta | U, F | MU-61 |
| TLS-C10 | Dos certificados que parecen la CA propia en `My` (restauración, intervención) | Se detiene (falla cerrada); no elige el primero ni el más reciente | F | MU-62 |
| TLS-C11 | CA vencida o con menos vigencia que 90 días **[D-06]** | No emite hojas con `NotAfter` mayor que el de la CA; o se detiene pidiendo rotación | U, F | MU-63 |
| TLS-C12 | Selector real de A con la **CA** publicada por error como `HuellaApi` | El selector no la adopta: la cuenta del servicio no abre la llave de la CA (4748, sigue con el anterior). Falso: almacén que refleja la ACL; luego W/V | F, W | MU-32 |
| TLS-C13 | Dos ejecuciones con códigos de sitio distintos (central y nodo, o dos laboratorios) | Sujetos distintos y SKI distintos; nunca el mismo DN: un puesto que visita dos sitios no confunde la CA (PA-1, LAB-29b) [D-10] | U | MU-62 |
| TLS-C14 | Archivos creados por la ejecución | Ningún `.pfx`, `.p12`, `.pem`, `.key` ni PKCS#8 en `%TEMP%`, `%ProgramData%`, directorio actual ni `tls\` (se compara el árbol antes/después y se buscan cabeceras `-----BEGIN` y PKCS#12) | W | MU-28 |
| TLS-C15 | CA en `LocalMachine\Root` (Q-8) | Solo el certificado público (`HasPrivateKey = false`), una sola vez, huella igual a la de la CA; **nada** en `CurrentUser\Root` (abriría un diálogo); segunda ejecución no duplica | W | MU-46, MU-47 |
| TLS-C16 | Dónde guarda la CA con llave **[D-16]** | Si en `LocalMachine\My`: la comprobación de C12; si en un contenedor sin certificado: el verbo la halla por nombre | F, W | |
| TLS-C17 | Sin salida a red | La creación no hace consultas (AIA, CRL, OCSP, DNS); con un manejador que falla, termina igual | F | |

### 3.3 Certificados del servicio (Web y API)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-S01 | Perfil de la hoja, `AsnReader` | v3; serie aleatoria ≥ 16 octetos, positiva; ECDSA P-256 con SHA-256; `NotBefore` = emisión − 1 h; `NotAfter` = emisión + 90 d (no 397, no 365); `basicConstraints` crítica `cA = false`; KU `digitalSignature` (sin `keyEncipherment`); EKU **solo** `serverAuth` (ni `clientAuth` ni `anyExtendedKeyUsage`); AKI = SKI de la CA; SAN presente; sin CDP, AIA ni NC; extensiones exactas | U | MU-19 a MU-25 |
| TLS-S02 | 1000 emisiones seguidas con la misma CA | 1000 series distintas; ninguna con el bit alto en 1 sin relleno | U | MU-19 |
| TLS-S03 | SAN de la Web | "Servidor de sitio": exactamente `NOMBRES_SERVIDOR` (DNS e IP), sin `localhost`. "Un equipo": `localhost`, `127.0.0.1`, `::1` | U | |
| TLS-S04 | SAN de la API | "Servidor de sitio": los nombres, **sin `localhost` ni `127.0.0.1`** (PT-01); "un equipo": con `localhost`. Mismas IP que la Web | U | MU-22 |
| TLS-S05 | Web y API en una ejecución | Dos huellas distintas y dos SPKI distintos (llaves distintas) | U, F | MU-26 |
| TLS-S06 | Sujeto | Vacío con SAN crítico, o `CN` ∈ SAN; nunca un `CN` que no esté en el SAN (LAB-02, LAB-16) [D-10] | U | |
| TLS-S07 | La hoja contra la CA con el validador independiente | Cada hoja valida contra la CA con la política de TLS-C03 y `MatchesHostname(nombre, allowWildcards: false, allowCommonName: false)` para cada nombre del SAN; si no, no se publica (alimenta TLS-P01) | U (Windows), F | MU-61 |
| TLS-S08 | Llave de la hoja | Persistente, `MachineKey`, proveedor de software, `ExportPolicy = None`; el nombre del contenedor no lleva datos del sitio ni secretos | F, W | MU-28, MU-29 |
| TLS-S09 | DACL de la llave de la Web / de la API | Web: lectura solo `NT SERVICE\GPOS.Web` (+ SYSTEM y Administradores). API: solo `NT SERVICE\GPOS.Api`. La Web **no** lee la llave de la API ni al revés; ni `Users`, ni `Authenticated Users`; permiso de lectura, no control total | F, W, V | MU-30, MU-31 |
| TLS-S10 | La cuenta virtual no existe (MSI no instalado) | Rechazo con mensaje; **no** hay respaldo a otro grupo (`Users`, `Everyone`); no se publica nada (LAB-43 a) | F, W | MU-30 |
| TLS-S11 | "Comprobar que la abre" **[D-12]** | Con la ACL correcta y la cuenta que **no** la tiene efectiva (herencia denegada), el paso falla y no publica. Con el falso `ConLlaveQueNoSeAbre` de `CertificadoPrueba`, el selector responde 4748 | F, V | MU-34 |
| TLS-S12 | Hoja nunca más allá de la CA | `NotAfter` de la hoja ≤ `NotAfter` de la CA (TLS-C11) | U | MU-63 |
| TLS-S13 | Cambio de modo (PT-06) de "un equipo" a "servidor de sitio" con CA existente | Los nombres no están en la NC de la CA: rechazo (TLS-C09) **[D-02]**. Al revés: igual (la NC de sitio no lleva `localhost`) | F | MU-61 |
| TLS-S14 | NC de "servidor de sitio" | Sin `localhost`, `127.0.0.1` ni `::1` [D-11 sobre si el administrador abre la Web desde el servidor por `localhost`] | U | MU-22 |

### 3.4 Orden de publicación y registro (PT-02)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-P01 | Secuencia de llamadas a las costuras en una renovación | Exactamente: crear llave → emitir → importar a `My` → dar ACL a la cuenta → comprobar que la abre → comprobar la cadena (TLS-S07) → publicar `HuellaX`. Se afirma el **orden** de la lista de llamadas del falso | F | MU-33, MU-34 |
| TLS-P02 | Fallo inyectado en **cada** paso de P01, para la Web y para la API | Salida distinta de 0; evento de fallo; el valor del registro anterior intacto byte a byte; el certificado anterior sigue en `My` y utilizable; una segunda ejecución converge, sin más de un certificado huérfano por servicio (o los retira); sin llave CNG sin certificado | F | MU-33, MU-45 |
| TLS-P03 | Valor publicado | `REG_SZ`, 64 hex en mayúsculas, SHA-256 del DER (no SHA-1, no minúsculas, no el hash del SPKI); solo `HuellaApi` / `HuellaWeb`; el resto de los valores y la ACL de la clave, byte a byte iguales | F, W | MU-35, MU-36 |
| TLS-P04 | Vista del registro | Escribe en la vista de 64 bits: en W, `reg query /reg:64` ve el valor y `/reg:32` (`WOW6432Node`) no ve la clave | W, V | MU-35 |
| TLS-P05 | Web falla después de publicar la API | La API ya publicada es coherente (cert existe y es abrible); la Web conserva su valor anterior; el verbo lo informa por servicio | F | |
| TLS-P06 | La clave del registro no existe (`red` no corrió), o existe con otro dueño o escritor ajeno | No la crea (escritor único: `red`); salida 4 (como `red`); mensaje claro; ningún certificado emitido (se comprueba antes de crear nada) **[D-14]** | F, W | MU-37 |
| TLS-P07 | Dos ejecuciones a la vez (tarea y técnico) | Una espera o aborta con mensaje; nunca dos emisiones simultáneas; al final cada `HuellaX` corresponde a un certificado que existe en `My` y se abre. En F con dos hilos; en W con dos procesos | F, W | MU-38 |
| TLS-P08 | `HuellaAnterior` **[D-05]** | Si B lo adopta: se escribe **antes** que `HuellaX`, con las mismas validaciones. Interrupción entre las dos escrituras: ninguna apunta a un certificado sin validar (O-03). Si no, que no exista el valor | F | |
| TLS-P09 | Selector real de A con el registro y el almacén falsos del verbo | Tras publicar, en ≤ 5 min (reloj adelantado), el selector toma el nuevo: evento 4749, `OpcionesVigentes` cambia, el anterior sirve hasta entonces; sin errores en la sonda (Kestrel de prueba) | F | MU-33 |
| TLS-P10 | Atributos del certificado publicado para el selector | Tiene llave, EKU `serverAuth` y vigencia que usa el selector (`NotBefore ≤ ahora < NotAfter`): el selector real lo acepta; los de `CertificadoPrueba.Servidor(usoServidor: false)` y vencido no | F | |

### 3.5 Renovación, tarea programada y avisos

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-R01 | Umbral con `FakeTimeProvider`: faltan 31 d, 30 d + 1 s, 30 d, 29 d, 1 d, vencido, aún no vigente (reloj atrasado) | No renueva, no renueva, renueva, renueva, renueva, renueva, no renueva y avisa del reloj. Salida 0 salvo error | F | MU-39 |
| TLS-R02 | Llave nueva | La renovación genera llave y serie nuevas: SPKI, serie y huella distintos del anterior | U, F | MU-27 |
| TLS-R03 | El anterior | Sigue en `My`, abrible por la cuenta, hasta su vencimiento; se retira solo el ya vencido, **con su llave CNG** (no queda contenedor sin certificado) **[D-06]** | F, W | MU-44, MU-45 |
| TLS-R04 | Tres renovaciones sucesivas (reloj +60, +120, +180 d) | `My` no acumula certificados vencidos ni llaves; a lo sumo vigente + anterior por servicio | F | MU-45 |
| TLS-R05 | La renovación no toca los servicios | El falso de servicios registra 0 llamadas de parar, iniciar o reiniciar | F | MU-40 |
| TLS-R06 | Todo el tiempo sale de `TimeProvider` | Prueba de arquitectura TLS-AR01 y un caso con el reloj falso en 2031 | U | MU-41 |
| TLS-R07 | Definición de la tarea (XML exportado) | Nombre `\GPOS NG\Renovar TLS`; principal SYSTEM (S-1-5-18), `RunLevel Highest`, `ServiceAccount`; disparadores: diario **y** al iniciar el equipo; `StartWhenAvailable = true`; `MultipleInstancesPolicy = IgnoreNew`; `ExecutionTimeLimit` finito; acción: ruta **absoluta** bajo `%ProgramFiles%\GPOS NG\`, argumentos `tls --renovar` (o lo que fije [D-01]) sin secretos; el binario con Authenticode válido y la carpeta no modificable por no administradores (H-12). Falso: el XML que genera el verbo; W: el del Programador | F, W | MU-42 |
| TLS-R08 | Crear la tarea dos veces; reinstalar | Una sola tarea; la definición se actualiza (no duplica) | F, W | MU-42 |
| TLS-R09 | Avisos de vencimiento (renovación bloqueada): 21, 20, 19, 11, 10, 9, 4, 3, 2, 1, 0 días y vencido | 21: nada. 20: aviso (20). 19 a 11: no repite. 10: aviso (10). 9 a 4: no repite. 3: aviso (3). Menos de 3 y vencido **[D-07]**. Una segunda ejecución el mismo día no duplica el evento; el estado de "ya avisado" no se guarda en un lugar editable por usuarios | F | MU-43 |
| TLS-R10 | Si la renovación tuvo éxito | Sin avisos de vencimiento aunque quedara ≤ 20 d en el anterior | F | MU-43 |
| TLS-R11 | Fallo de renovación | Evento crítico con el motivo **sin** datos sensibles; salida ≠ 0; el vigente intacto; el día siguiente reintenta | F | |
| TLS-R12 | `comprobar-servidor` con el certificado publicado | Verde con más de 20 d (20 d + 1 s); rojo con 20 d o menos; "CA en software" informativo; falla si la CA no tiene subárbol `dNSName` o `iPAddress` (O-02, K-11) | F | MU-39 |
| TLS-R13 | Reloj atrasado en el servidor (retroceso) | No renueva de más ni borra el vigente porque "ya está vencido" según el reloj; informa. LAB-46 en el laboratorio | F | MU-41 |
| TLS-R14 | Renovar con la CA pendiente de rotar **[D-04]** | Condicional a la rotación (sección 3.8) | F | |

### 3.6 Certificado del cliente (`--importar`)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-I01 | Huella en `My`: sin llave privada; sin EKU; con `anyExtendedKeyUsage` solo; solo `clientAuth`; SAN sin uno de los `NOMBRES_SERVIDOR`; SAN con un nombre parecido (`xsrv-c01…`, `srv-c01.gposlab.test.evil`); RSA 1024; firma SHA-1; vencido; aún no vigente | Rechazo de cada una con su motivo; nada se publica | U, F | MU-51, MU-52 |
| TLS-I02 | Aceptables: ECDSA P-256; ECDSA P-384; RSA 2048/3072 con SHA-256; SAN con comodín de una etiqueta (`*.cliente-prueba.test`) que cubre el nombre; SAN con IP | Aceptado (según A5); el comodín se evalúa con las reglas de LAB-81 (una etiqueta, ≥ 2 tras el `*`, nunca IP) | U, F | MU-52 |
| TLS-I03 | Avanzada | Solo lo que cumple A5 de ADR-64 (RT-09 dice ECDSA P-256 con SHA-256; A5 admite RSA ≥ 2048) [D-16bis] | F | |
| TLS-I04 | PFX | Contraseña solo por consola, sin eco; `--password`, variable de entorno o argumento: **rechazado antes de abrir el archivo**; la copia importada es `NonExportable`, `MachineKeySet`, `PersistKeySet`, en `My`; ningún archivo temporal | F, W | MU-49, MU-50 |
| TLS-I05 | Contraseña centinela de laboratorio | No aparece en stdout, stderr, eventos, registro de Burn ni archivos (TLS-O04) | F, V | MU-59 |
| TLS-I06 | Contraseña bajo un *bundle* sin consola **[D-08]** | Según la respuesta; sin consola y sin PFX: error claro, nunca una contraseña por otro canal | F | MU-49 |
| TLS-I07 | Intermedias | Con las intermedias ausentes de `LocalMachine\CA`, el verbo avisa (Kestrel enviará una cadena incompleta y los clientes sin descargas fallarán, LS-12) **[D-LS12]**; no instala la raíz | F | |
| TLS-I08 | Selección del "más reciente con el mismo sujeto y emisor": varios en `My`: mismos sujeto y emisor, otro emisor, vencido, aún no vigente, sin llave, sin `serverAuth`, empate de fecha | Toma el utilizable de mayor `NotBefore` **[D-18: "más reciente"]**; ignora los demás; empate resuelto por huella en orden ordinal (determinista) | U, F | MU-53 |
| TLS-I09 | Renovación por el cliente que **cambia de emisor** | No lo toma solo; avisa (evita sustituir por un certificado de otra CA, C-A3) | F | MU-53 |
| TLS-I10 | Avisos del cliente | Mismos umbrales 20/10/3 (TLS-R09) y aviso informativo si el certificado vive más de 200 d (Q-LAB-02 (a)) | F | MU-43 |
| TLS-I11 | Modo cliente | No crea CA, no instala nada en `Root`, no escribe `tls\` con CA; `exportar-publica` responde error claro | F, W | MU-48 |
| TLS-I12 | Cambio de CA propia a cliente y al revés | La CA propia no se borra; evento de cambio; el mensaje avisa de volver a emparejar estaciones y MAUI (LAB-35c) | F | |
| TLS-I13 | Una sola llave para las dos cuentas **[QT-04]** | Con un único certificado para Web y API, la ACL da lectura a las dos cuentas; el caso documenta el hecho y exige que el verbo no lo oculte (el mensaje de salida lo dice) | F, W | MU-31 |

### 3.7 VPN **[D-03]**

ADR-90 no define certificados de la VPN: la provee el cliente (RT-07, PA-4), y PT-07 sacó las subredes de la VPN de las Name Constraints. Los casos cubren lo que **sí** toca al verbo; si B pensaba en otra cosa, ver D-03.

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-V01 | Nombre con el que los puestos llegan por la VPN (`srv-c01.vpn.gposlab.test`) en `NOMBRES_SERVIDOR` | Entra a NC y SAN como `dNSName` exacto; vale N01 | U | |
| TLS-V02 | IP del servidor en la subred del túnel (`10.8.0.1`) | Entra como /32; una subred de la VPN (`10.8.0.0/24`) se rechaza (PT-07: efecto de PA-1 sin efecto) | U | MU-10 |
| TLS-V03 | Si llegan al verbo `IP_NODOS`, `SUBREDES_PUESTOS` o `SUBREDES_REMOTOS` (PT-05) | No aparecen en NC ni SAN; se ignoran o se rechazan, nunca se leen como nombres [D-01] | U, F | MU-23 |
| TLS-V04 | Central y nodo: la CA de la central que fija el nodo (RT-07) | `exportar-publica` da el DER, el SHA-256 del **SPKI** (64 hex), la huella corta de 128 bits (32 hex, grupos de 4, PT-08) y la lista del sitio. El SPKI se recalcula en la prueba por separado; la huella corta es el prefijo del SPKI. Renovar la CA con la **misma llave** deja el SPKI igual y cambia el hash del certificado: la prueba los distingue | U, F | MU-54 |
| TLS-V05 | Lista del sitio exportada (LS-20) | Igual, como conjunto, a los subárboles permitidos decodificados de la NC; ni un nombre más (y la exclusión `/0` si no hay IP) | U | MU-54 |
| TLS-V06 | Dos sitios en la misma red (LAB: central y nodo) | Dos CA con sujetos distintos (TLS-C13); la CA de uno no valida las hojas del otro (LAB-25) | U (Windows) | MU-62 |

### 3.8 Rotación de la CA sucesora (PT-04) **[D-04, condicional]**

ADR-90 cita la rotación a 12 meses, la sucesora y el certificado cruzado firmado por la CA vigente, pero el listado del verbo (crear, emitir, renovar, importar, exportar) no la incluye. Si entra el 18-nov: TLS-C20 genera sucesora + cruzado y los valida con el oráculo del bloque S (LAB-87 a LAB-90): sujeto/SPKI del cruzado igual a la sucesora, firmado por la vigente (la llave de CA en el TPM firma), NC y EKU iguales o más estrechos que los de la vigente, `pathLen` que permite la validación aparte, máximo dos CA, el cruzado fuera de la cadena del saludo. Mutaciones a matar: cruzado con NC más amplias, sucesora sin EKU, cruzado firmado por otra llave. Si no entra, el verbo no ofrece la opción y TLS-O12 comprueba que no queda un camino parcial.

### 3.9 Parte pública y carpeta `Servidor\tls\`

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-X01 | Contenido de `tls\` | Solo el DER de la CA (parseable, = `RawData`); ninguna cabecera `BEGIN PRIVATE KEY`, PKCS#8 ni PKCS#12 en los bytes | F, W | MU-28 |
| TLS-X02 | DACL de `tls\` | Protegida (sin herencia), dueño Administradores; escritura solo Administradores y SYSTEM; lectura `Authenticated Users`; nadie más | F, W | MU-55 |
| TLS-X03 | La raíz `%ProgramData%\GPOS NG` no existe (el MSI no corrió) | Rechazo; el verbo **no** la crea (la crea la acción previa de O-1 con su DACL) | F, W | MU-55 |
| TLS-X04 | `tls\` ya existe con DACL ajena, o fue creada por un no administrador | Se corrige (con evento) o se detiene; nunca escribe confiando en ella (comprobación de carpetas de ADR-77) | F, W | MU-55 |
| TLS-X05 | `tls\` o el archivo de destino es un punto de reanálisis (*junction*, enlace simbólico, enlace duro) | No lo sigue; rechazo; el verbo elevado no escribe donde no debe | W | MU-57 |
| TLS-X06 | Escritura atómica | Se escribe a un temporal **dentro** de la carpeta ya protegida y se reemplaza; si el proceso muere a la mitad, el archivo anterior queda entero (bucle de muerte súbita en LABT-08) | F, W | MU-56 |
| TLS-X07 | Se reescribe solo si cambia el contenido | Fecha del archivo y DACL sin cambio en una segunda ejecución | F | |

### 3.10 Operación, secretos y plataforma

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| TLS-O01 | Sin elevación | Salida ≠ 0 **antes** de tocar nada (ni almacén, ni registro, ni carpeta), mensaje claro; usuario estándar y administrador con token filtrado (UAC) | F, V | MU-58 |
| TLS-O02 | Misma ejecución como SYSTEM (tarea) y como administrador interactivo | Misma salida; la ACL de la llave no depende de quién ejecuta (sin `CREATOR OWNER` ni SID del ejecutor) | W, V | MU-30 |
| TLS-O03 | Códigos de salida | 0 éxito/sin cambios; 1 error; 4 guarda (como `red`); un código propio para "necesita rotar" **[D-01]**; los códigos documentados en `--ayuda` | U, F | |
| TLS-O04 | Contraseña de PFX y llave centinela | Ningún byte en stdout, stderr, eventos ni archivos; se verifica en cada canal | F, V | MU-59 |
| TLS-O05 | Linux u otra plataforma (ADR-129) | `tls` responde "sin plataforma", salida ≠ 0, 0 archivos creados; en `VM-LNX` con el publicado, si se publica allí | U, V | MU-60 |
| TLS-O06 | Rutas | `--pfx` relativo, con `..`, UNC o en una carpeta escribible por no administradores: rechazo o aviso | F | |
| TLS-O07 | Segunda ejecución completa | Diff vacío del estado observable (`My`, `Root`, ACL, registro, tarea, `tls\`) | F, V | MU-62 |
| TLS-O08 | Desinstalación | Quita reglas y tarea; la CA, los certificados, `Root` y el registro quedan; una reinstalación mantiene la huella de la CA | F, V | |
| TLS-O09 | `retirar` (verbo aparte) | Pide confirmación explícita; quita **solo lo propio** (CA, hojas, `Root`, la tarea); un certificado ajeno en `My` con sujeto parecido sobrevive. Cómo reconoce lo propio **[D-19]** | F, W | MU-64 |
| TLS-O10 | Idempotencia con la clave del registro con otro modo | Si `ModoRed` falta, rechazo con el mensaje de `red` primero [D-14] | F | |
| TLS-O11 | Registro sin modo / modo cambiado entre ejecuciones | El cambio de modo con CA existente sigue TLS-C09 y S13 | F | |
| TLS-O12 | Sin rotación en la v1 | No existe `--rotar-ca` o equivale a "no soportado" [D-04] | U | |

### 3.11 Pruebas de arquitectura (estilo `ValoresPorOmisionDistribuidosTests`)

| ID | Qué comprueba | Mut. |
|---|---|---|
| TLS-AR01 | En `src/GPOS.Migracion/Tls`: ninguna llamada a `DateTime.Now/UtcNow` ni `DateTimeOffset.Now/UtcNow` (solo `TimeProvider`) | MU-41 |
| TLS-AR02 | Ningún `Export(X509ContentType.Pfx` / `Pkcs12`, `ExportPkcs8PrivateKey`, `X509KeyStorageFlags.Exportable`, `File.Write*` con material de llave, ni `Environment.GetEnvironmentVariable` para contraseñas | MU-28, MU-49, MU-50 |
| TLS-AR03 | El registro se abre con `RegistryView.Registry64` explícito; los nombres de los valores salen de `ValoresRegistroServidor` (no literales repetidos) | MU-35 |
| TLS-AR04 | Sin `SHA1`, `GetCertHashString()` sin algoritmo, `Thumbprint` como identidad, `HttpClient` ni `ServicePointManager` en el verbo | MU-36 |
| TLS-AR05 | No referencia `GPOS.Api` ni `GPOS.Web`; no reutiliza la llave de firma de tokens ES256 ni el anillo (RT-09, "lo que no cambia") | |
| TLS-AR06 | Los EventId 4780 a 4789 declarados con `public static readonly EventId` y sin repetir (`EventIdUnicosTests`); ningún número fuera de la franja que se asigne [D-07] | |
| TLS-AR07 | Todo acceso a almacén, registro, ACL, tareas y servicios pasa por las costuras R-T2 a R-T6 (ninguna llamada directa fuera de la implementación de Windows) | |

## 4. Trazabilidad con los LAB-xx del diseño v3

| LAB (diseño v3) | Qué prueba allí | Aquí |
|---|---|---|
| LAB-01 a 23b, 71 a 79 (bloque N) | El oráculo contra CryptoAPI | TLS-C03 y TLS-S07 repiten los casos clave **con la CA y las hojas del verbo**; el resto sigue siendo del oráculo de A |
| LAB-24 a 31b, 80 a 85 (bloque F) | La política del cliente | No es del verbo; LAB-34 los repite con el validador de A |
| LAB-32 | Perfil emitido por el verbo | TLS-C01, C02, S01 a S06 (en U) y LABT-01 (la verificación real) |
| LAB-33 | Entradas inválidas | TLS-N01 a N22 y LABT-02 |
| LAB-34 | Bloque N con el validador único y las hojas del verbo | TLS-C03 (con X509Chain) y LABT-03 |
| LAB-35 a 36, 84, 86 | Estación, MAUI, alta contra impostor | No son del verbo; consumen `exportar-publica` (TLS-V04, V05) |
| LAB-37, 37b | Estado inicial, permisos del registro | TLS-P03, P04, P06; LABT-05, LABT-06 |
| LAB-38, 38b | Renovación sin reinicio; reloj del puesto atrasado | TLS-P01, P09, R05; LABT-06, LABT-07 |
| LAB-39, 40, 41, 41b | Huella con llave que no se abre, inexistente, no válida, de otra raíz | TLS-S11, C12; LABT-05 (con la cuenta real) |
| LAB-42 | Reinicio con la vigente rota | TLS-P08 [D-05]; LABT-05 |
| LAB-43 | Fallos inyectados en el verbo | TLS-P02, S10; LABT-08 (con muerte súbita) |
| LAB-44, 45, 46, 48 | Reloj adelantado, camino feliz y de fallo, atrás, apagado | TLS-R01, R09, R13; LABT-09 |
| LAB-47 | Blazor durante la renovación | No es del verbo (se mantiene en el bloque R de A) |
| LAB-49 a 62, 83 | Navegadores | LABT-12 con la CA del verbo |
| LAB-22 | Web a la API por el nombre del sitio | LABT-11 con el producto |
| LAB-30, 30b, 62 | EKU en la CA (Q-LAB-01) | TLS-C01 (EKU presente) y LABT-01; el efecto lo mide el oráculo |
| LAB-87 a 90 | Sucesora y cruzado | Sección 3.8 [D-04] |
| LAB-91 a 99 | OpenSSL | No aplica: el verbo es solo Windows |

## 5. Casos de laboratorio en `VM-SRV` (VirtualBox, `LFMB`)

**Reglas heredadas** (mis casos de T1-b y el rediseño VirtualBox): solo en `VM-SRV` de `LFMB` o en `VM-PUESTO`, desde el punto de control `base`; las VM corren **por bloques, no en paralelo**; un punto de control por bloque (`Puntos-Control.ps1 -Accion Tomar -Nombre LAB-TLS-<ID>` y, al terminar, `Restaurar -Nombre base -Apagar`); `Preparar-Vm.ps1` ya existe en `feature/modelo-ng` y crea el marcador que exigen las guardas [V]; ningún agente ejecuta esto, lo opera B; si algo falla no se corrige a mano, se anota y se restaura; cada `msiexec` con `/l*v`; **ningún secreto en la evidencia**: contraseñas centinela falsas y visibles (`CLAVE-DE-LABORATORIO-NO-SECRETA-…`), nunca `reg export` de claves de servicio, y `Probar-Redaccion.ps1` sobre toda la evidencia antes de copiarla fuera.

**Precondiciones** (si falta una, el caso es `No se pudo`, nunca `Cumple`): el verbo `tls` publicado; `GPOS.Api.msi` y `GPOS.Web.msi` (para que existan las cuentas virtuales); el verbo `red` (rama `a/pr-v-verbos-servidor`, sin PR a la fecha) y `ModoRed=ServidorSitio` en el registro; `Preparar-Vm.ps1`; SQL Server no hace falta para estos casos (ahorra memoria, mi rediseño 2.(a)).

**Funciones de apoyo** (PowerShell elevado; solo lectura salvo donde se dice):

```powershell
$E = 'C:\GPOS-LAB\evidencia'
function EstadoTls([string]$id){        # estado observable, sin llaves ni contraseñas
  $d = New-Item -ItemType Directory -Force "$E\$id"
  foreach($s in 'My','Root','CA'){ Get-ChildItem "Cert:\LocalMachine\$s" | Where-Object { $_.Subject -match 'GPOS' -or $_.Issuer -match 'GPOS' } |
     Select-Object Subject,Issuer,NotBefore,NotAfter,HasPrivateKey,@{n='Sha256';e={[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($_.RawData)).Replace('-','')}} |
     Export-Csv "$d\almacen-$s.csv" -NoTypeInformation }
  (Get-Item 'HKLM:\SOFTWARE\GPOS NG\Servidor').GetValueNames() | Out-File "$d\registro-nombres.txt"
  foreach($v in 'HuellaApi','HuellaWeb','HuellaAnterior'){ "$v=" + (Get-ItemProperty 'HKLM:\SOFTWARE\GPOS NG\Servidor' -Name $v -ErrorAction SilentlyContinue).$v } | Out-File "$d\huellas.txt"
  schtasks /query /tn '\GPOS NG\Renovar TLS' /xml 2>&1 | Out-File "$d\tarea.xml"
  icacls 'C:\ProgramData\GPOS NG\Servidor\tls' 2>&1 | Out-File "$d\acl-tls.txt"
}
```

| ID | Caso | Cómo | Esperado | Evidencia | Mapea | Marca |
|---|---|---|---|---|---|---|
| LABT-01 | Perfil real del verbo | Ejecutar el verbo con DNS+IP, solo DNS y "un equipo"; sacar los DER públicos (`certutil -dump` y la parte pública copiada a la VM del oráculo); decodificar con `AsnReader` del arnés de A y comparar con los vectores de TLS-C01, C02, S01 | Los campos de K-01 a K-04, K-06, K-07, sin diferencias | `certutil -dump` (sin llaves), JSON del oráculo | LAB-32 | [V] el procedimiento; [I] los volcados |
| LABT-02 | Entradas inválidas en el verbo real | La tabla de TLS-N01 a N19 como lote (un archivo de entradas) | Salida ≠ 0, ninguna CA ni certificado creado, mensaje claro; las mayúsculas se normalizan | Salidas, `EstadoTls` antes/después iguales | LAB-33 | |
| LABT-03 | Cadena del verbo con el validador | Con la CA y las hojas del verbo, correr el oráculo de A (bloques N y F) y, cuando exista, el validador único: `H-DNS`, `H-IP` válidas; `H-FUERA`, `H-SUFIJO`, `H-IPFUERA`, `H-MEZCLA` rechazadas; control sin NC válido | Igual que TLS-C03, ahora con CryptoAPI de la VM y el CAPI2 activo | JSON por caso, extracto CAPI2 | LAB-34 | |
| LABT-04 | ACL reales de las llaves | `certutil -store -v My <huella>` para hallar el contenedor; `icacls` sobre el archivo de llave (`C:\ProgramData\Microsoft\Crypto\…`), sin copiar el contenido: CA, hoja Web, hoja API | CA: solo SYSTEM y Administradores. Web: + `NT SERVICE\GPOS.Web` lectura. API: + `NT SERVICE\GPOS.Api` lectura. Ni `Users` ni `Authenticated Users` ni `Everyone`. La Web no está en la ACL de la API | Salidas de `icacls` | TLS-C07, S09 | [I] ruta exacta del contenedor |
| LABT-05 | La cuenta real abre la llave | Tras `tls`, iniciar `GPOS.Api` y `GPOS.Web`; sonda a `/api/salud` por TLS con el nombre del sitio; luego `icacls <llave API> /remove "NT SERVICE\GPOS.Api"`, reiniciar y mirar el evento; restaurar y comprobar de nuevo | Arranca sin 4747 ni 4748; el servicio con la ACL quitada: 4747 y no arranca (falla cerrada); la huella publicada de un certificado cuya llave no abre la cuenta no se adopta | Visor (4747 a 4749), respuesta de la sonda | LAB-39, 40, 42; TLS-S11 | |
| LABT-06 | Renovación forzada | Estado inicial (`EstadoTls`). Con la sonda cada 5 s desde `VM-PUESTO`: `tls --renovar --forzar` **[D-01]**; esperar 5 min 30 s | Registro apunta al B; A sigue en `My`; 4749 en ≤ 5 min 30 s; **PID de los dos servicios sin cambio**; cero errores TLS en la sonda; el orden de publicación se ve en las marcas de tiempo del registro de eventos del verbo | CSV de la sonda, PID por minuto, `EstadoTls` antes/después | LAB-37, 38 | |
| LABT-07 | Puesto con el reloj atrasado | Como LABT-06, con `VM-PUESTO` 10 min por detrás (Guest Additions sin sincronización, `w32time` apagado) | Cero errores en la sonda y en la estación: el `NotBefore` − 1 h absorbe el desfase. Control: una hoja emitida con `NotBefore = ahora` (la del oráculo) sí falla | Sonda | LAB-38b, 20b | |
| LABT-08 | Fallos y muerte súbita | (a) Ejecutar `tls` sin los MSI (no existe `NT SERVICE\GPOS.Web`). (b) ACE temporal que niega a SYSTEM escribir en `HKLM\SOFTWARE\GPOS NG\Servidor`. (c) **Bucle de muerte súbita:** 50 veces, lanzar el verbo y `Stop-Process -Force` tras un retardo aleatorio de 0 a 1,5 s; después, una ejecución normal | (a) y (b): salida ≠ 0, evento, huella publicada sin cambio, el servicio sigue con A. (c): tras cada muerte el registro apunta a un certificado que existe y se abre; el archivo `ca.cer` entero; tras la ejecución normal, `EstadoTls` converge y no queda más de un huérfano por servicio | `EstadoTls` por iteración (solo huellas), eventos | LAB-43; TLS-P02, X06 | La (c) no necesita ganchos en el código de producción |
| LABT-09 | Reloj adelantado con la tarea real | Puntos de control `T0`, `T0+50d`, `T0+61d`. Camino feliz: `T0`→`T0+61d`, reinicio (la tarea "al iniciar"), sonda; luego `T0+91d`. Camino de fallo: tarea deshabilitada, `T0+70d`, `+80d`, `+87d`, `+91d`; habilitar y `schtasks /run` | Feliz: renueva en el arranque, a `T0+91d` sin errores TLS y PID estable; `comprobar-servidor` verde. Fallo: avisos a 20, 10 y 3 días (eventos 478x), rojo bajo 20 d, a `T0+91d` todos los clientes rechazan (hoy la estación aceptaría una hoja vencida por su SPKI fijado: F-02 del diseño v3), y al habilitar la tarea se recupera sin reiniciar en ≤ 5 min 30 s. La licencia de laboratorio debe valer hasta `T0+120d` (LS-15) | Visor, sonda, `comprobar-servidor` | LAB-44, 45, 48 | |
| LABT-10 | Tarea programada real | `schtasks /query /xml`; `schtasks /run` y `Last Result`; como usuario estándar (`runas /user:%COMPUTERNAME%\gpos-lab-usuario`): `schtasks /change` y modificar el binario del verbo bajo `Program Files` | XML igual a TLS-R07; `Last Result 0`; el usuario estándar recibe "denegado" en ambos (H-12); `signtool verify /pa` válido sobre el binario | XML, códigos, "denegado" | TLS-R07, R08 | |
| LABT-11 | CA en `Root` y la Web a la API | `Get-ChildItem Cert:\LocalMachine\Root`; `Get-Item` de la CA (`HasPrivateKey = False`); desde la cuenta de la Web (el servicio), `https://<nombre>:<PuertoApi>` por *loopback* con el producto; con "certificado del cliente" (LABT-14) la raíz no se instala | La CA pública está una vez; la Web valida a la API por el nombre con el almacén del sistema; sin `localhost` en el SAN de la API | Salida de PowerShell, respuesta | LAB-22; TLS-C15 | |
| LABT-12 | Navegadores con la CA del verbo | En `VM-PUESTO`, instalar solo la parte pública (`certutil -addstore -f Root ca.cer`, o el MSI del agente cuando exista); Edge, Chrome y Firefox (≥ 120 y ESR): `https://<nombre>` y `https://192.168.50.10`; control: nombre trampa `xsrv-c01…` | Carga sin aviso por nombre y por IP; el nombre trampa falla (error de nombre); LAB-49, 50, 53, 57, 83 con el producto | Capturas, versión de cada navegador | LAB-49 a 62 | Edge completo (no se recorta) |
| LABT-13 | TPM | En `VM-SRV` con TPM 2.0 de VirtualBox si lo emula **[I, sin verificar]**: `Get-Tpm`; el verbo; `certutil -store -v My <huella CA>` muestra el proveedor `Microsoft Platform Crypto Provider`. Sin TPM: evento "CA en software". Si VirtualBox no da TPM, el caso pasa al equipo físico **[D-09]** | Con TPM: llave en el TPM, ninguna cuenta de servicio la lee, las hojas firman bien; sin TPM: Básica funciona con aviso, Avanzada rechaza | `Get-Tpm`, volcado de `certutil` | K-05; C04 a C06 | Ningún LAB del diseño v3 usa el TPM (mi rediseño 3.1) |
| LABT-14 | Certificado del cliente | Con la CA-S del oráculo emitir una hoja con PFX; importar en `My` (contraseña centinela tecleada en consola, nunca en el guion); `tls --importar --huella <h>` y la variante PFX; casos de TLS-I01 a I10 (hoja sin EKU, SAN incompleto, vencida, otro emisor, dos candidatas) | Aceptados/rechazados como en I01 y I02; la contraseña no aparece (correr `Probar-Redaccion.ps1`); la raíz no se instala; renovación = toma la más reciente | Salidas, eventos | K-14 | La contraseña se teclea a mano |
| LABT-15 | Sin privilegios | El verbo con un usuario estándar y con un administrador sin elevar | Rechazo antes de tocar nada; `EstadoTls` idéntico | Salidas | TLS-O01 | |
| LABT-16 | Idempotencia | Ejecutar completo dos veces; `EstadoTls` y diff | Sin cambios en la segunda; la CA no cambia de huella al reinstalar los MSI | `diff` de `EstadoTls` | TLS-C08, O07, O08 | |
| LABT-17 | Desinstalar y retirar | Desinstalar MSI; luego el verbo de retirada con confirmación; sembrar un certificado ajeno en `My` con un sujeto que contiene `GPOS` | Desinstalar conserva CA y certificados; retirar quita solo lo propio y deja el ajeno | `EstadoTls` | TLS-O08, O09 | [D-19] |
| LABT-18 | Sin salida | Con la VM sin NAT (como en todos los casos) y CAPI2 activo: ejecutar crear, emitir, renovar | Ningún evento de recuperación de URL en CAPI2; sin intentos de DNS ni conexión (`pktmon` o el contador de la interfaz) | Extracto CAPI2 | TLS-C17 | |
| LABT-19 | *Bundle* | Con el paquete único (B): el paso `tls` corre **después** de los MSI (F-6 (ii)), sin consola; la raíz protegida ya existe; `tls\` nace con su DACL | La cadena termina; `HuellaApi` y `HuellaWeb` presentes; con "certificado del cliente" por PFX: según la respuesta de D-08 | Registro de Burn (`/l*v`) | TLS-X03; D-08 | Bloqueado hasta el paquete |
| LABT-20 | Linux | En `VM-LNX`, si se publica allí: ejecutar `tls` | "Sin plataforma", salida ≠ 0, 0 archivos | Salida | TLS-O05; ADR-129 | Solo si se publica el verbo en Linux |
| LABT-21 | Rotación de la CA **[D-04]** | Condicional a la sección 3.8: sucesora + cruzado y los casos LAB-87 a 90 con los artefactos del verbo | Según 3.8 | | PT-04 | Condicional |

**Reparto por VM y duración [I, ±50 %, a refinar con la primera ejecución].**

| Sesión | Bloque | VM | Casos | Horas |
|---|---|---|---|---|
| 1 | Perfil y ACL | `VM-SRV` sola (3 a 3,5 GB, sin SQL) | LABT-01, 02, 04, 05, 15, 16, 18 | 3,5 |
| 2 | Renovación y navegadores | `VM-SRV` y `VM-PUESTO` a la vez (6,5 a 7,5 GB; B detiene su trabajo) | LABT-06, 07, 11, 12 | 4,0 |
| 3 | Fallos, cliente, desinstalación | `VM-SRV` sola | LABT-03, 08, 10, 14, 17 | 3,5 |
| 4 | Reloj | `VM-SRV` y `VM-PUESTO`; puntos de control a `T0+50d` y `T0+61d` | LABT-09 | 2,5 |
| 5 | TPM y *bundle* | Según [D-09] y el paquete | LABT-13, 19 | 1,5 + 1,0 |

## 6. Mutaciones que el plan debe matar

El código no existe, así que cada fila es una **responsabilidad** del verbo; B la convierte en `archivo:línea` cuando abra el PR. Procedimiento (el de S168-08/P168-14): aplicar la mutación a una copia, correr los casos de la columna "Lo mata" y registrar cuál falla; una mutación que sobrevive es un caso que falta.

| ID | Responsabilidad | Mutación | Lo mata |
|---|---|---|---|
| MU-01 | Normalización de nombres | Quitar el paso a minúsculas | TLS-N02 |
| MU-02 | Normalización de nombres | Aceptar el punto final | TLS-N03 |
| MU-03 | Validación de nombres | Aceptar `*` (comodín) | TLS-N04 |
| MU-04 | Validación de nombres | `.local` solo exacto y en minúsculas, o `EndsWith` sin `.` previo | TLS-N05 |
| MU-05 | Validación de nombres | Aceptar una lista sin DNS o con IP/`localhost` como primer nombre | TLS-N07, N08 |
| MU-06 | Tope de nombres | `<= 16` por `<= 17`, o sin tope | TLS-N16 |
| MU-07 | Parser de IP | `IPAddress.TryParse` sin forma canónica (octal, decimal, `0x`, mapeada, zona, prefijo) | TLS-N13, N14, N20 |
| MU-08 | Exclusión sin IP | No escribir `0.0.0.0/0` y `::/0` excluidos; o escribir el permitido IPv6 cuando solo hay IPv4 | TLS-N18, N19, C03 |
| MU-09 | Name Constraints | Extensión no crítica | TLS-C02 (bytes) |
| MU-10 | Name Constraints, IP | Máscara `/24` (o `/128` por `/64`) en vez de la completa | TLS-C02, C03 (`H-IPFUERA`), V02 |
| MU-11 | Name Constraints, IP | Máscara y dirección en orden invertido | TLS-C02, N11, N12 |
| MU-12 | Name Constraints, DER | `minimum` explícito en 0 (viola DER) o subárboles en `SET` sin ordenar | TLS-C02 (lector DER estricto) |
| MU-13 | Perfil de la CA | `pathLen` ausente o 1 | TLS-C01, C03 (`H-PATH`) |
| MU-14 | Perfil de la CA | `basicConstraints` no crítica | TLS-C01 |
| MU-15 | Perfil de la CA | Sin EKU `serverAuth` (Q-LAB-01 a) | TLS-C01 |
| MU-16 | Perfil de la CA | EKU con `anyExtendedKeyUsage` o `clientAuth` | TLS-C01 |
| MU-17 | Perfil de la CA | `NotBefore` = ahora (sin − 1 h) | TLS-C01 |
| MU-18 | Perfil de la CA | Vigencia de 1 o 100 años en vez de 10 | TLS-C01 |
| MU-19 | Serie | Fija, corta o con el bit alto en 1 | TLS-S01, S02 |
| MU-20 | Hoja | Vigencia 397 o 365 días | TLS-S01 |
| MU-21 | Hoja | `NotBefore` = ahora | TLS-S01; LABT-07 |
| MU-22 | SAN de la API/NC de sitio | Agregar `localhost` o `127.0.0.1` en "servidor de sitio" | TLS-S04, S14 |
| MU-23 | SAN | Agregar `IP_NODOS` o subredes | TLS-V03 |
| MU-24 | Hoja | EKU con `clientAuth` o `anyExtendedKeyUsage` | TLS-S01 |
| MU-25 | Hoja | `cA = true` | TLS-S01 |
| MU-26 | Llaves | Reutilizar la llave entre Web y API | TLS-S05 |
| MU-27 | Renovación | Reutilizar la llave en cada renovación | TLS-R02 |
| MU-28 | Exportabilidad | Llave exportable o PFX temporal | TLS-C04, C14, S08, X01, AR02 |
| MU-29 | Llave de la hoja | Guardarla en el almacén del usuario (no `MachineKey`) | TLS-S08; LABT-05 (la cuenta no la abre) |
| MU-30 | ACL de la hoja | Conceder a `Users`, `Authenticated Users` o `Everyone`, o respaldo a otro grupo si la cuenta no existe | TLS-S09, S10, O02; LABT-04 |
| MU-31 | ACL de la hoja | Dar a las dos cuentas ambas llaves | TLS-S09 (salvo el caso de I13, que lo documenta) |
| MU-32 | ACL de la CA | Dejar lectura a una cuenta de servicio | TLS-C07, C12; LABT-04 |
| MU-33 | Orden de PT-02 | Publicar antes de la ACL o de la comprobación | TLS-P01, P02, P09 |
| MU-34 | Comprobación | Omitir "comprobar que la abre" | TLS-S11, P01; LABT-05 |
| MU-35 | Registro | Abrirlo en la vista por omisión (32 bits) | TLS-P04, AR03 |
| MU-36 | Huella | SHA-1, minúsculas o hash del SPKI | TLS-P03, AR04 |
| MU-37 | Registro | `CreateSubKey` si falta la clave | TLS-P06 |
| MU-38 | Concurrencia | Sin exclusión mutua entre tarea y técnico | TLS-P07 |
| MU-39 | Umbral | `<` por `<=`, 20 o 60 en vez de 30; `comprobar-servidor` con 30 en vez de 20 | TLS-R01, R12 |
| MU-40 | Renovación | Reiniciar o parar los servicios | TLS-R05; LABT-06 (PID) |
| MU-41 | Reloj | `DateTime.UtcNow` directo | TLS-R06, R13, AR01 |
| MU-42 | Tarea | Principal usuario; sin disparador al iniciar; ruta relativa; sin `StartWhenAvailable`; duplicar al repetir | TLS-R07, R08; LABT-10 |
| MU-43 | Avisos | Umbrales 21/11/4; repetir cada día; avisar tras renovar | TLS-R09, R10, I10 |
| MU-44 | Retención | Borrar el anterior al publicar el nuevo | TLS-R03; LABT-06 |
| MU-45 | Limpieza | Borrar el certificado sin borrar su llave, o no limpiar huérfanos | TLS-P02, R03, R04 |
| MU-46 | CA en `Root` | Instalar en `CurrentUser\Root` | TLS-C15 |
| MU-47 | CA en `Root` | Instalar con llave privada o duplicar | TLS-C15 |
| MU-48 | Modo cliente | Instalar la CA o crear una con "certificado del cliente" | TLS-I11 |
| MU-49 | PFX | Aceptar contraseña por argumento o variable | TLS-I04, I06, AR02 |
| MU-50 | PFX | Importar con `Exportable` | TLS-I04, AR02 |
| MU-51 | Certificado del cliente | Aceptar sin EKU, con `anyExtendedKeyUsage` o sin llave | TLS-I01 |
| MU-52 | Certificado del cliente | Nombres con `Contains` o `EndsWith` en vez de etiquetas | TLS-I01, I02 |
| MU-53 | "Más reciente" | Primero encontrado, mayor `NotAfter`, o tomar otro emisor | TLS-I08, I09 |
| MU-54 | Exportación | SHA-256 del DER en vez del SPKI; lista distinta de la NC | TLS-V04, V05 |
| MU-55 | Carpeta `tls\` | Crearla con herencia, antes de la raíz protegida, o crear la raíz | TLS-X02, X03, X04 |
| MU-56 | Archivo público | Escritura no atómica | TLS-X06; LABT-08 (c) |
| MU-57 | Archivo público | Seguir un punto de reanálisis | TLS-X05 |
| MU-58 | Elevación | Comprobarla después de tocar algo, o no comprobarla | TLS-O01; LABT-15 |
| MU-59 | Secretos | Contraseña o llave en la salida/registro | TLS-I05, O04 |
| MU-60 | Plataforma | Crear archivos o fallar sin mensaje fuera de Windows | TLS-O05 |
| MU-61 | Emisión | Emitir una hoja con nombres fuera de la NC de la CA | TLS-C09, S07, S13 |
| MU-62 | CA | Elegir una CA al azar si hay varias, crear otra si ya existe, o mismo DN en dos sitios | TLS-C08, C10, C13, V06, O07 |
| MU-63 | Vigencias | Hoja con `NotAfter` mayor que el de la CA | TLS-C11, S12 |
| MU-64 | Retirada | Borrar por sujeto genérico (ajeno incluido) | TLS-O09; LABT-17 |

## 7. Hallazgos de lectura (de este plan)

| ID | Sev. | Hallazgo | Evidencia |
|---|---|---|---|
| QT-01 | Baja | La renovación se hace con llave nueva cada ≤ 60 días y el anterior se conserva "hasta su vencimiento"; **nada dice quién retira** los vencidos ni sus llaves CNG. Con el tiempo `My` y el almacén de llaves acumulan certificados y contenedores huérfanos | ADR-090.md:55 y 237 |
| QT-02 | Baja | El texto original del ADR todavía dice "`ExePackage tls` **antes** de los MSI"; la precisión F-6 (ii) lo mueve al paso 6, después de los MSI. El plan usa F-6 (ii). Si alguien construye según el texto del ADR, la carpeta `tls\` nacería sin raíz protegida (HB-01) | ADR-090.md:137, 265 |
| QT-03 | Media | La CA lleva EKU `serverAuth` (Q-LAB-01 a) y vive con su llave en el equipo; el selector de A no comprueba el emisor ni la jerarquía (C-A3). Si una ACL de la CA queda mal, publicar por error la huella de la CA pasaría los criterios de "utilizable". Se cubre con TLS-C07 y C12; conviene que A además rechace en el selector un certificado con `cA = true` | blueprint 5.2; diseño v3, C-A3 |
| QT-04 | Baja | Con la opción "certificado del cliente" (RT-02) hay **un solo certificado** para los dos servicios: las dos cuentas virtuales comparten la llave y se pierde la separación de RT-04 ("llaves distintas"). Es una consecuencia, no un error, pero no está escrita | ADR-090.md:36, 38, 53 |
| QT-05 | Baja | La franja 4780-4789 figura "de A" en el blueprint y en los acuses; el verbo pasó a B el 2026-10-23 | `B-a-A/2026-10-23-respuestas-tls…` punto 1 |
| QT-06 | Baja | El texto de RT-04 conserva 60 días, 397 días y avisos a 60/30/7; los vigentes son los de PT-10 (30 d, 90 d, avisos 20/10/3). El plan usa PT-10 | ADR-090.md:54, 55, 245 a 251 |
| QT-07 | Baja | Ningún caso del diseño v3 usa el TPM, pero el producto sí (K-05). Sin LABT-13 la llave de la CA en el TPM no se verifica nunca antes de la primera instalación | mi rediseño VirtualBox 3.1; diseño v3, F-05 |
| QT-08 | Baja | `PrivadaEnTpm` solo reconoce llaves RSA (`CifradorAnillo.cs:31`) [V, diseño v3, F-05]: con la CA ECDSA en el TPM, B necesita un camino ECDSA propio (`ECDsaCng` sobre `CngKey` del proveedor de la plataforma) | diseño v3, F-05 |

Ninguno es Crítico ni Alto; **sin hallazgos que impidan** empezar la construcción.

## 8. Requisitos de testabilidad para B (condición del nivel U y F)

Sin estas costuras los casos F pasan a W y el laboratorio se llena. Propongo el patrón de `ISistemaServidor` y `SistemaServidorFalso` de A [V, `a/pr-v-verbos-servidor`].

| ID | Costura | Para qué |
|---|---|---|
| R-T1 | **Núcleo puro** `ConstructorPki`: entrada = llaves `ECDsa` ya creadas, nombres normalizados, `TimeProvider`; salida = DER. Sin SO | Casos U; el oráculo lo decodifica por separado |
| R-T2 | Almacén de llaves: crear (no exportable, `MachineKey`, proveedor TPM o software), poner ACL, borrar | TLS-C04 a C07, S08 a S10 |
| R-T3 | Almacén de certificados con escritura: buscar, agregar y quitar en `My`, `Root`, `CA` | C15, R03, O09 |
| R-T4 | Registro del servidor: leer `ModoRed` y `NombresServidor`, escribir solo `HuellaApi`/`HuellaWeb` (vista de 64 bits) | P03, P04, P06 |
| R-T5 | Programador de tareas y servicios (este último solo para afirmar que no se toca) | R05, R07, R08 |
| R-T6 | Bitácora de eventos con los EventId de la franja | R09, R11 |
| R-T7 | Lector de contraseña (consola) | I04 a I06 |
| R-T8 | Sistema de archivos de `tls\` (DACL, reanálisis, reemplazo atómico) y exclusión mutua nombrada | P07, X02 a X07 |

## 9. Dudas para B

**Bloquean casos (escribir/ejecutar sin respuesta es adivinar):**

| ID | Duda | Qué hice mientras tanto | Bloquea |
|---|---|---|---|
| **D-01** | **Sintaxis, parámetros y códigos de salida.** ADR-90 solo dice `GPOS.Migracion tls --crear-ca --emitir` y `--importar`; "renovar, importar, exportar la parte pública" aparecen como funciones y "retirar" como "verbo aparte". ¿Subcomandos o banderas? ¿`--renovar`, `--exportar-publica`, `--forzar`, `--retirar`, `--comprobar`? ¿Qué reciben (nombres por línea de comandos o los lee del registro de `red`)? ¿Códigos: 0, 1, 4 como `red`, y uno propio para "hace falta rotar"? ¿Si llegan `IP_NODOS` y las subredes, se ignoran o se rechazan? | Usé los nombres de arriba y los códigos de `red` | TLS-O03, V03, R07, LABT-06 |
| **D-02** | **Cambio de nombres o IP con una CA existente.** Las NC quedan fijas 10 años (RFC 5280: la hoja debe estar dentro); el ADR dice que si cambian el nombre o la IP "se emiten de nuevo los certificados (lo hace el verbo, en minutos)". Son incompatibles si el nombre nuevo no está en la NC. La nota de lectura de LS-14 (un cambio de nombre es rotación de CA) quedó como entrega al Arquitecto Maestro y no vi su respuesta. ¿El verbo rechaza, rota la CA solo, o pide `--rotar`? | Rechaza sin tocar nada (TLS-C09) | C09, S13, N-casos de cambio |
| **D-03** | **"Certificados de la VPN".** ADR-90 no define ninguno: la VPN la provee el cliente (RT-07, PA-4), GSF no la opera, y PT-07 sacó las subredes de las NC. ¿Qué querías cubrir? Mi lectura: (a) nombres/IP por los que se llega por la VPN en `NOMBRES_SERVIDOR`, (b) la CA de la central que fija el nodo, (c) que `IP_NODOS` y las subredes no entren a NC/SAN. Si pensabas en emitir certificados para un punto de la VPN o en una CA del dueño en la central (RT-03 (b), revisable), no hay contrato y no inventé casos | Sección 3.7 | V01 a V06 |
| **D-04** | **¿La rotación de CA (sucesora + certificado cruzado, PT-04) entra el 18-nov?** El listado del verbo no la nombra. Si entra, falta decir quién genera el cruzado (la CA vigente en el TPM firma) y con qué EKU/NC | Sección 3.8 condicional; TLS-O12 | 3.8, LABT-21 |
| **D-07** | **Avisos 20/10/3 y eventos.** ¿Qué hace la tarea por debajo de 3 días y vencido (diario, crítico)? ¿Dónde se guarda "ya avisé" (no puede ser editable por usuarios)? ¿Un EventId por umbral, de qué franja (el 4780-4789 era "de A")? ¿Se avisa si ya renovó? | Interpreté "una vez por umbral" | R09, R10, AR06 |
| **D-08** | **Contraseña del PFX bajo Burn.** El ADR dice que el verbo la pide "en la consola elevada"; un `ExePackage` no tiene consola. ¿`PFX_CLIENTE` solo se admite en una ejecución manual y el *bundle* solo acepta `CERTIFICADO_CLIENTE` (huella)? | Error claro sin consola (I06) | I06, LABT-14, LABT-19 |

**No bloquean, pero cambian el esperado:**

| ID | Duda |
|---|---|
| D-05 | ¿Se escribe `HuellaAnterior` (O-03 / C-A2 del diseño v3), antes de `HuellaX`? Cambia LAB-42 y TLS-P08 |
| D-06 | Política de limpieza de vencidos y de llaves CNG (QT-01) y qué hace el verbo si la CA vence antes que la hoja (TLS-C11) |
| D-09 | CA en TPM: proveedor/algoritmo exacto (Microsoft Platform Crypto Provider, ECDSA P-256 [I]); qué hace si hay TPM pero falla (¿software con aviso o error?); cómo recibe el perfil Avanzada; **dónde se prueba**: VirtualBox 7 emula TPM 2.0 [I sin verificar] y no sé si `LFMB` tiene TPM físico. Si no, ¿quién lo verifica y antes de qué instalación? |
| D-10 | Sujeto de la CA y de la hoja: ¿incluye el código del sitio? Hoja con sujeto vacío o `CN` (LAB-02 sigue sin resolver en el laboratorio). Mi recomendación: DN de CA único por sitio (TLS-C13) |
| D-11 | "Idempotente": ¿qué es "vigente"? Si la hoja tiene 25 días, ¿`--emitir` la renueva o no hace nada? ¿Y el administrador que abre la Web desde el servidor por `localhost` en "servidor de sitio"? (K-02 solo lo lleva en "un equipo") |
| D-12 | "Comprobar que la abre": el verbo corre como SYSTEM y no puede iniciar sesión como la cuenta virtual. ¿Cómo lo comprueba (evaluación de acceso sobre la DACL con el SID del servicio [I])? Determina TLS-S11 |
| D-13 | `NotBefore` − 1 h y el mismo margen en la CA (O-07, LS-06, LS-22) están en el diseño v3, no en el texto de ADR-90. ¿Se adoptan como contrato del verbo? |
| D-14 | Orden con `red`: ¿el verbo lee `ModoRed` y `NombresServidor` del registro y se detiene con 4 si faltan? |
| D-15 | Gramática de `NOMBRES_SERVIDOR`: ¿se reutiliza el parser de `red`? Casos que dependen: una etiqueta (`srv01`), guion bajo, A-label, `/32` explícito, duplicados (TLS-N06, N09, N10, N13, N15) |
| D-16 | ¿Dónde reside la CA con su llave: certificado en `LocalMachine\My` o contenedor propio? (TLS-C16, QT-03). **D-16bis:** RT-09 pide ECDSA P-256 en Avanzada y A5 admite RSA ≥ 2048: ¿cuál rige para el certificado del cliente? |
| D-17 | Linux: ¿`tls` responde "sin plataforma" (ADR-129) o ni se compila allí? |
| D-18 | "El más reciente con el mismo sujeto y emisor" (RT-04): ¿mayor `NotBefore` o mayor `NotAfter`? |
| D-19 | ¿Cómo reconoce el verbo lo suyo para `retirar` y para no tocar certificados ajenos? Propongo un `FriendlyName` `GPOS NG TLS <servicio> <sitio>` más una extensión privada no crítica |
| D-LS12 | Descargas e intermedias con "certificado del cliente" (LS-12 del diseño v3): ¿el verbo comprueba `LocalMachine\CA` y avisa? |

## 10. Esfuerzo, orden y dependencias [I, ±40 %]

| Tanda | Contenido | dp |
|---|---|---|
| T0 | Vectores y oráculo de decodificación (`adr090-tls.v1.json`, lector `AsnReader`), TLS-N, C01 a C03, S01 a S07, AR: puros | 1,5 |
| T1 | Costuras y falsos (R-T2 a R-T8) y los casos F: P, R, I, V, X, O | 2,0 |
| T2 | Casos W (almacén, ACL, registro, tarea reales) con guardas | 1,0 |
| T3 | Laboratorio: preparar `EstadoTls.ps1` y los guiones de ejecución (C) | 0,5 |
| T4 | Ejecución en `VM-SRV` (B opera, C revisa evidencia redactada): 5 sesiones, unas 17 h | (B) |
| | **Total de escritura de pruebas** | **≈ 5,0 dp** (4,5 de pruebas + 0,5 de guiones) |

Orden: T0 y T1 mientras B construye el núcleo (R-T1 primero); T2 al terminar el verbo; T3 y T4 con la VM del instalador (18-nov) y después del paquete (LABT-19). No corren a la vez la suite completa y el laboratorio en `LFMB`. Estos 5 dp están **fuera** de las 0,35 sp del laboratorio de ADR-90 (que cubren el oráculo) y de la 0,60 sp del verbo; dentro de lo que ADR-90 llama laboratorio, son los bloques V y R del diseño v3, ampliados.

## 11. Qué no verifiqué

- Que el verbo siga el nombre `GPOS.Migracion/Tls` (blueprint de B del 2026-10-20) y su sintaxis: todo en D-01.
- El comportamiento real de CryptoAPI, CNG y el Programador de tareas ante cada caso: están marcados [I] y por eso hay casos W y V.
- Que VirtualBox emule TPM 2.0 (LABT-13).
- La ruta exacta de los archivos de llave de CNG para `icacls` (LABT-04).
- No leí la hoja de firma de PT-01 a PT-10 ni el diseño del instalador del paquete único completo; usé el ADR registrado y las respuestas de B.
- No abrí el PR de `a/pr-v-verbos-servidor` más allá de la lista de archivos y los avisos de A.

### Cierre
- Estado: Completado (plan; no se compiló ni se ejecutó nada)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-pruebas-verbo-tls.md`
- Supuestos: sintaxis del verbo (D-01) y gramática de nombres (D-15) tomadas de `red` y del ADR; el verbo es solo Windows; PT-10 prevalece sobre el texto original de RT-04; Q-LAB-01 (a) y Q-LAB-02 (a) aplican al producto; las cifras de esfuerzo son [I].
- Decisiones candidatas a ADR: ninguna nueva. D-02 (cambio de nombres con CA fija) y QT-04 (llave compartida con el certificado del cliente) merecen nota de lectura en ADR-90 del Arquitecto Maestro.
- Entregas a otros agentes: B (desarrollador) → D-01 a D-19 y R-T1 a R-T8; arquitecto-software de A → QT-03 (el selector podría rechazar un certificado con `cA = true`) y la franja 4780-4789 (QT-05); Arquitecto Maestro → D-02, D-03 y QT-04; auditor-seguridad → revisar los casos de ACL y de secretos (TLS-C07, S09, O04) antes de la ejecución en la VM.
- Próximo paso recomendado: B responde D-01, D-02, D-03, D-07 y D-08 (las que bloquean) antes de abrir el PR del verbo, y define las costuras R-T1 a R-T8 en el primer commit.
