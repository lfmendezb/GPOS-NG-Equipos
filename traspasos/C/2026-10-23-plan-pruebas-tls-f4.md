```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (punto 8 de B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7: plan de pruebas de F4 de `tls` y anillo)
Prioridad: Media (F4 se construye "antes de la primera instalación real"; no hay fecha)
Repositorio y rama: GPOS-NG `origin/b/blueprint-tls-anillo` (`b5328331`, blueprint), `origin/b/hoja-firma-tls-anillo` (`ecacd985`, hoja del PR #221), `origin/master` (`fcb7b47b`, ADR-90) y `origin/feature/modelo-ng` (`b9efa9fb`, código, solo lectura); área común
Estado: Abierto (21 dudas para B, sección 9; 8 bloquean casos)
```

# Plan de pruebas de F4: `anillo --renovar-certificado`, `tls --importar --pfx` y el aviso a 180 días

**Qué es.** Plan para que B construya F4 con las pruebas en la mano. Complementa, sin repetir, mis planes del anillo F1 (`2026-10-23-plan-pruebas-anillo-dm07.md`, casos ANI-xx, MU-AN-xx, LABA-xx) y del verbo `tls` F2/F3 (`2026-10-23-plan-pruebas-verbo-tls.md`, casos TLS-xx, MU-xx, LABT-xx). Tres bloques: **RC** (renovación del certificado del anillo), **AV** (aviso a 180 días) y **PF** (importación de un PFX del cliente). Tabla caso por caso con nivel y mutación, casos de laboratorio para `VM-SRV`, hallazgos de lectura, requisitos de testabilidad y dudas.

**Método y límites.** Solo lectura: `git show` sobre el blueprint (`docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md`, secciones 1, 3.1, 3.5, 4.5, 4.6, 7, 8 y 12), la hoja del PR #221 (`docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md`, rama `b/hoja-firma-tls-anillo`; **no está en `master`**), `ADR-090.md:136` y, en `feature/modelo-ng`, `CifradorAnillo.cs:145-151` (`Reenvolver`), `RecuperarAnillo.cs` (el único reenvoltorio que existe), `OrigenCertificadosAnillo.cs:30-90`, `ComprobacionAnillo.cs:140-155` y `Program.cs:502-516` (`Argumentos.LeerClave`). No compilé ni ejecuté nada, no toqué ningún árbol del repositorio. **Nada de F4 existe en ninguna rama** [V: el blueprint lo declara "nada de esto está construido"; `ComandosAnillo.cs` no lista `preparar` ni `renovar-certificado`]. Por eso las mutaciones se enuncian sobre **responsabilidades**; B las convierte en `archivo:línea` al construir. Marcas: **[V]** leído; **[I]** inferido o conocimiento general de Windows, CNG o .NET, por confirmar con casos W o V; **[D]** depende de una duda de la sección 9.

**Dos precisiones de alcance (ver D-F4-01).**
1. En el blueprint `--renovar-certificado` es una acción del verbo **`anillo`** (3.5: `anillo --renovar-certificado --acta --motivo`), no de `tls`. El encargo lo agrupa bajo "`tls` F4" por la fase; este plan lo prueba como acción de `anillo`. Lo único de F4 que es de `tls` es `--importar --pfx`.
2. El aviso a 180 días es del **certificado del anillo** (3.1 paso 5 y 3.5), no de las hojas TLS (esas avisan a 20, 10 y 3 días, 4.5; ya están en TLS-R09).

**Dependencia de firma.** `--importar --pfx` se apoya en `--importar --huella` de **F3**, cuya aprobación sigue **pendiente** (hoja del PR #221, sección "Pendiente": P-9 para F2 y F3). F4 firmada en principio (P-4, P-5); su construcción no empieza hasta que F2 y F3 existan.

## 0. Resumen para decidir

1. **Tres piezas, tres riesgos distintos.** (a) La renovación del certificado del anillo reescribe todas las llaves de Data Protection: si se interrumpe a la mitad, la API puede quedar sin poder abrir sus propias llaves (QF4-01). (b) El aviso a 180 días hoy no tiene evento, ni deduplicación, ni quién lo vea: el blueprint reutiliza el 4716, que "va al registro de consola y a la salida, no al Visor" (`MantenimientoAnillo.Evento`, blueprint 3.1 paso 12) y no hay tarea que ejecute `anillo --comprobar`; un certificado de 5 años con un aviso que nadie lee es un vencimiento sorpresa (QF4-03). (c) La contraseña del PFX: el ayudante existente `Argumentos.LeerClave` devuelve un `string` y **acepta la entrada redirigida** a propósito ("O-1", `Program.cs:499-505`), lo que contradice "tecleada, sin eco" (QF4-02).
2. **Lo más caro de equivocarse no se ve en "renovar y ver que arranca".** Defectos que pasan ese camino feliz: (i) llaves reenvueltas solo para el principal nuevo mientras el archivo aún apunta al viejo; (ii) borrar el certificado anterior sin su llave CNG, o por sujeto en vez de por huella; (iii) el nombre del contenedor `GPOS.Anillo.Api.<AAAAMMDDhhmmss>` repetido en el mismo segundo y la llave vieja sobrescrita; (iv) importar el PFX con `Exportable` o con la ACL por omisión de la plataforma, o importar antes de validar y dejar restos; (v) PKCS#12 sin límites de carga; (vi) el aviso tratado como error en el modo Estricto de la API. Los casos RC-O02, RC-P03, RC-O04, PF-08, PF-09, PF-10, PF-06 y AV-04 los matan.
3. **Cuatro niveles** como en mis planes anteriores: U puro, F con falsos (suite oficial), W real en `LocalMachine` (solo VM) y V laboratorio en `VM-SRV`. Casi todo cae en U y F **si B entrega las costuras R-F1 a R-F10** (sección 8). Dos son nuevas y fáciles de olvidar: **inyección de fallo por paso y por archivo** en el almacén y en el repositorio de llaves, y **el lector de contraseña como costura** (hoy es un método estático sobre `Console`).
4. **Casos: 79** (RC 37, AV 12, PF 22, arquitectura 8, más 20 de laboratorio aparte) y **52 mutaciones** (sección 6), cada una con el caso que la mata. Al no existir el código, ninguna está "viva"; son la lista de comprobación del revisor.
5. **Hallazgos de lectura** (QF4-01 a QF4-06, sección 7): ninguno Crítico. Tres Medios que conviene decidir **antes** de construir: QF4-01 (orden de la reescritura), QF4-02 (entrada redirigida) y QF4-03 (aviso sin canal).
6. **Esfuerzo [I, ±40 %]:** pruebas U/F/W unos **2,2 dp** (RC 1,0; AV 0,25; PF 0,6; arnés, vectores y arquitectura 0,35); laboratorio 20 casos en `VM-SRV`, unas **9,5 h** en 3 sesiones. Detalle en la sección 10.

## 1. Lo que se prueba: el contrato (oráculo) y su origen

`Estado`: **F** = firmado (hoja del PR #221: P-4, P-5; ADR-90 `:136`; H-17 v2); **B** = blueprint de B; **E** = código existente [V]; **[D]** = abierto.

| # | Regla | Origen | Estado |
|---|---|---|---|
| K-F01 | Certificado del anillo con vigencia de **5 años**; aviso a **180 días**; `--renovar-certificado` en F4, "debe existir antes de la primera instalación real" | P-4 (hoja); blueprint 3.1 paso 5 y 3.5 | F |
| K-F02 | `anillo --renovar-certificado --acta --motivo`, **con los servicios detenidos** como ADR-79 | blueprint 3.5 | B |
| K-F03 | Pasos de la renovación: (1) certificado nuevo con los pasos 6 a 9 de 3.1; (2) **reenvuelve** cada llave del anillo para el principal nuevo y la recuperación anclada, abriéndola con la privada del principal **anterior** (`CifradorAnillo.Reenvolver`, el camino de `--recuperar`); (3) publica el archivo con el principal nuevo; (4) borra el certificado y la llave anteriores **solo cuando `anillo --comprobar` cumple** | blueprint 3.5 | B |
| K-F04 | Red de seguridad: `CertificadosServidorAnteriores` "si el reenvoltorio se interrumpe"; el archivo admite la lista | blueprint 3.5; `OrigenCertificadosAnillo.cs:76-85` [V] | B [D-F4-05] |
| K-F05 | El certificado nuevo cumple el perfil de F1: RSA 3072, `ExportPolicy = None`, descriptor exacto (dueño Administradores; `GENERIC_ALL` SYSTEM y Administradores; solo `GENERIC_READ` a `NT SERVICE\GPOS.Api`) fijado en la misma llamada que crea la llave; EKU solo *Document Encryption*, sin `serverAuth`; KU solo `keyEncipherment`; `cA = false`; serie de 16 bytes aleatorios | blueprint 3.1 pasos 6 a 9 (K-01 a K-03 de mi plan del anillo) | B |
| K-F06 | La recuperación (`.cer`) y su ancla **no cambian** con la renovación; para cambiarla existe `--cambiar-recuperacion` con acta | blueprint 3.4 y 3.5 | B |
| K-F07 | Aviso: `anillo --comprobar` **y** `comprobar-servidor` avisan con menos de 180 días; `anillo --preparar` idempotente: "salida 0 con un aviso"; certificado vencido: `AnilloCertificadoNoValido` y no se crean llaves, lo ya cifrado sigue descifrando | blueprint 3.1 paso 5 y 3.5; `ComprobacionAnillo.cs:150-151` [V] | B / E |
| K-F08 | `tls --importar --pfx`: **solo manual**; contraseña tecleada en la consola, **sin eco**; rechazada **antes de abrir el archivo** si llega por argumento o por variable; la copia importada es no exportable | blueprint 4.6; ADR-90 `:136`; N-7 de la hoja del ADR | F / B |
| K-F09 | El *bundle* **deja de aceptar `PFX_CLIENTE`**; acepta `CERTIFICADO_CLIENTE` (huella) | P-5 (hoja) | F |
| K-F10 | Un PFX importado pasa por las mismas reglas de `--huella` (4.6, A5 de ADR-64): `serverAuth` sin `anyExtendedKeyUsage`; nombres del sitio en el SAN comparados por etiquetas; RSA ≥ 2048 o ECDSA P-256/P-384 con SHA-256 o más; vigente; cadena sin descargas (si no, aviso 2); no crea CA, no instala nada en `Root`, no escribe `tls\` | blueprint 4.6 (TLS-I01, I02, I07 de mi plan) | B |
| K-F11 | Misma publicación que cualquier hoja (PT-02): llave con ACL de lectura **solo** a la cuenta del servicio, comprobar que la abre, publicar `HuellaApi`/`HuellaWeb`; llave compartida solo con `--aceptar-llave-compartida` y evento 4788 | blueprint 4.4 y 4.6; P-8 | F / B |
| K-F12 | Ningún PFX ni PKCS#8 toca el disco; ningún secreto en archivos, argumentos, variables, eventos ni salida | blueprint 6; ADR-44 | F |

## 2. Niveles, reglas y qué se reutiliza

Los niveles U, F, W y V y sus reglas son los de mis dos planes anteriores (secciones 2 de ambos). Específico de F4:

- **W** usa las mismas guardas del diseño v3 (7.1, LS-11) y el atributo `[FactLaboratorioAnillo]` / `[FactLaboratorioTls]` (omiten sin `GPOS_LAB_ANILLO=1` / `GPOS_LAB_TLS=1`).
- **Reglas añadidas.** (1) **Los PFX de las pruebas se generan en memoria durante la prueba** y nunca se guardan en el repositorio (un PFX con contraseña conocida dispara los escáneres de secretos y contradice ADR-44); en el laboratorio se generan en la VM con el arnés y mueren al revertir. (2) La contraseña centinela es `CLAVE-DE-LABORATORIO-NO-SECRETA-<n>` y se busca en todos los canales. (3) La prueba de fallo "por paso" recorre **todos** los pasos numerados y no una muestra: la lista de pasos sale de la costura (R-F4), no de la prueba. (4) Carpetas: `tests/GPOS.Tests/Criptografia/Anillo/Renovacion/`, `tests/GPOS.Tests/Tls/Pfx/` y `tests/GPOS.Tests/Laboratorio/Anillo/` y `.../Tls/` para W.

**Reutilizable hoy** [V, `feature/modelo-ng`]: `AnilloPrueba`, `CertificadosPrueba`, `CifradorAnilloTests`, `MantenimientoAnilloTests` (el patrón de `RecuperarAnillo`), `CertificadoPrueba` y `SoporteTls.cs` (certificados de hoja en memoria), `EventIdUnicosTests`. **Reutilizable cuando existan F1 a F3** (blueprint 7): `AlmacenMaquinaFalso`, `SistemaServidorFalso`, `TareasProgramadasFalsas`, `EstadoServiciosFalso`, `PkiLaboratorio` (A), los vectores `anillo-dm07.v1.json` y `adr090-tls.v1.json`.

## 3. Bloques de casos

Columnas: **ID** · entrada · esperado · nivel · mutación que lo mata (MF-xx, sección 6). "Mut." vacío = control o informativo.

### 3.1 RC: `anillo --renovar-certificado`

#### 3.1.1 Entradas y guardas

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| RC-E01 | Fuera de Windows; sin elevación (usuario estándar; administrador con token filtrado); sin `--acta`; sin `--motivo`; con acta o motivo vacíos o en blanco; opción desconocida; opción repetida | Salida 1 (o la de uso, [D-F4-02]) **antes de tocar nada** (el falso registra 0 llamadas a almacén, carpeta, archivo y servicios). Acta y motivo obligatorios con el mismo mensaje que `RecuperarAnillo` ("Indique --acta y --motivo…") | U, F | MF-01, MF-02 |
| RC-E02 | Estado de `GPOS.Api`: `Running`, `StartPending`, `StopPending`, `Paused`, `ContinuePending`, `PausePending`; `Stopped`; no instalado; `IEstadoServicios` lanza | Todos los activos y el error: rechazo (4) sin cambios; `Stopped`: procede; no instalado: procede [D-F4-03]; la consulta que falla **no** se interpreta como "detenido" | F | MF-03 |
| RC-E03 | Precondiciones: archivo del anillo ausente; inválido; certificado del archivo no está en `LocalMachine\My`; está sin privada; privada que esta cuenta no abre; ancla distinta de `Anclada`; recuperación del archivo distinta de la anclada | Rechazo con el motivo, sin tocar nada. Certificado perdido: el mensaje manda a `--recuperar`, no a "reintente". Recuperación distinta: `AnilloRecuperacionCambiada` (4) | F | MF-04 |
| RC-E04 | Certificado anterior vencido (reloj +5 años +1 día); aún no vigente (reloj atrasado) | Vencido: procede [D-F4-07] (es el caso real de un aviso ignorado; abrir con la privada no exige vigencia). No vigente: rechazo con aviso de reloj | F | MF-22 |
| RC-E05 | Cuándo se admite: restan 400, 181, 180 días+1 s, 180, 179, 1 día; con y sin `--forzar` | Según [D-F4-03]. Recomendado: sin `--forzar` solo con 180 días o menos; con más de 180, salida 0 "no hace falta" y sin cambios | F | MF-22 |
| RC-E06 | `--servicio web` y `--servicio xyz` | `web`: según [D-F4-01] (anillo de la Web, también F4); `xyz`: error de uso | U, F | |

#### 3.1.2 Certificado y llave nuevos

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| RC-P01 | Perfil del certificado nuevo, decodificado con `AsnReader` y el vector de F1 | El mismo perfil de F1 (ANI-C01 a C07): v3, serie ≥ 16 octetos aleatorios positiva, RSA 3072 SHA-256 PKCS#1 v1.5, `cA = false`, KU solo `keyEncipherment`, EKU solo `1.3.6.1.4.1.311.80.1`, `NotBefore` = ahora − 1 h, `NotAfter` = ahora + 5 años; sujeto con la fecha nueva | U | MF-21 |
| RC-P02 | Contra el anterior | SPKI, serie, huella y nombre de contenedor **distintos**; llave nueva (no se reutiliza la anterior); `FriendlyName` igual | U, F | MF-05, MF-06 |
| RC-P03 | Dos renovaciones con el mismo reloj (mismo segundo); el contenedor `GPOS.Anillo.Api.<AAAAMMDDhhmmss>` ya existe | La segunda **falla cerrada** o toma un sufijo; **nunca** sobrescribe la llave existente (no se usa `OverwriteExistingKey`); la llave y el certificado anteriores intactos | F, W | MF-07 |
| RC-P04 | Llave nueva: `ExportPolicy = None`, `MachineKey`, proveedor de software; descriptor exacto (SDDL del vector de F1) fijado **en la misma llamada** que crea la llave; el falso rechaza cambios de seguridad posteriores | Cumple; con la mutación "descriptor después" el falso lo hace fallar | F, W | MF-20 |
| RC-P05 | El certificado nuevo en `My` | Se abre por SHA-256 con llave y como quien ejecuta; `ExportPkcs8PrivateKey` y `certutil -exportPFX` fallan; ningún archivo `.pfx`, `.p12`, `.pem` ni PKCS#8 aparece en el árbol (antes/después) | F, W | MF-20 |

#### 3.1.3 Reenvoltorio de las llaves

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| RC-R01 | Carpeta con N llaves conformes (N = 0, 1, 5, 40) envueltas para (viejo, recuperación anclada) | Cada sobre queda para (**nuevo**, **la misma** recuperación anclada), con las huellas en los destinatarios y en el AAD; `Descifrar` con la privada nueva devuelve el **mismo XML de llave** (`XNode.DeepEquals`) | F | MF-08, MF-09 |
| RC-R02 | Lo ya protegido: antes de renovar se protege un secreto con `IDataProtector`, se firma un sello y se escribe la fila del ancla | Después de renovar y reabrir con el principal nuevo: el secreto se descifra, el MAC verifica y el ancla verifica (solo cambia la envoltura) | F | MF-09 |
| RC-R03 | Llaves no conformes (heredadas, revocadas, de otra recuperación, XML malformado, truncadas) mezcladas con conformes | Se decide **todo o nada** [D-F4-06]. Recomendado: una llave **conforme que no se pueda abrir** aborta antes de escribir nada; las ya no conformes se informan y se dejan (como `RecuperarAnillo`) | F | MF-10 |
| RC-R04 | Carpeta sin ninguna llave (instalación preparada que nunca arrancó la API) | Renueva el certificado y publica el archivo; no falla con "nada que recuperar" como `RecuperarAnillo` [D-F4-06] | F | |
| RC-R05 | Carpeta restaurada con llaves de **otro principal** que ni el viejo ni el nuevo abren | No las toca y avisa; no aborta por ellas ni las reenvuelve (K-12 de mi plan del anillo) [D-F4-06] | F | MF-10 |
| RC-R06 | Verificación **antes** de escribir: para cada sobre nuevo se descifra con la privada nueva y se compara con el claro; se inyecta un fallo de cifrado en la llave k | No se escribe **ninguna** llave (ni las k−1 anteriores) | F | MF-11 |
| RC-R07 | Fila del ancla ausente; ancla que no verifica con el anillo reenvuelto; ancla con otra recuperación | Rechazo sin escribir (paso 2 de `RecuperarAnillo`); mensaje con el motivo | F | MF-04 |
| RC-R08 | Llave de 90 días vencida sin renovar dentro de la carpeta (T+91) | Se reenvuelve igual (sigue descifrando lo antiguo); no se crea una nueva por efecto de la renovación | F | |

#### 3.1.4 Orden, atomicidad y fallos

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| RC-O01 | Orden de las llamadas al falso en el camino feliz | Exactamente: comprobar servicios → crear llave con descriptor → emitir → agregar a `My` → verificar (abrir, descriptor exacto, sobre de prueba) → reenvolver **en memoria** y verificar → escribir llaves → publicar el archivo → `--comprobar` → borrar el certificado anterior **y su llave**. Se afirma la **lista** | F | MF-12, MF-13 |
| RC-O02 | **Fallo inyectado en cada paso** de RC-O01 y, dentro de "escribir llaves", **tras la llave j de N** (N = 5) | Tras cada fallo valen cuatro invariantes con `ComprobacionAnillo` y `OrigenCertificadosAlmacen` reales: (I1) cada llave conforme es descifrable por algún principal cuya privada existe y se abre; (I2) el archivo apunta a un certificado que existe y se abre; (I3) no se borró ningún certificado del que dependa una llave; (I4) una segunda ejecución converge al estado final sin intervención. Es el caso de QF4-01 | F | MF-14, MF-13 |
| RC-O03 | Ventana con el archivo publicado: principal nuevo, `certificadosServidorAnteriores` = [viejo] | Mientras dure: la API (simulada) abre llaves envueltas para cualquiera de los dos; al terminar con éxito, la lista queda vacía o sin el viejo [D-F4-05] | F | MF-14 |
| RC-O04 | `--comprobar` final falla (inyectado): el viejo | **Se conserva** (certificado y llave), salida de error, evento; el nuevo queda en `My` sin publicarse o publicado según [D-F4-05]; reintentar converge | F | MF-12 |
| RC-O05 | Borrado del anterior | Por **huella** (SHA-256 del DER), nunca por sujeto ni por `FriendlyName`; se borra también el contenedor CNG (no queda llave sin certificado); un certificado ajeno en `My` con el mismo sujeto y `FriendlyName` sobrevive | F, W | MF-15, MF-16 |
| RC-O06 | Segunda ejecución inmediata, con y sin `--forzar` | Sin `--forzar` y con más de 180 días: no hace nada (0), diff vacío. Con `--forzar` dos veces: dos certificados nuevos en secuencia, y quedan 1 en `My` (se borran los intermedios) | F | MF-22 |
| RC-O07 | Dos procesos a la vez: renovar y renovar; renovar y `anillo --preparar`; renovar y `sistema --cuentas-iniciales`; renovar y arranque de la API | Exclusión mutua nombrada (como `Global\GPOS.Migracion.tls`) o rechazo claro; nunca dos escrituras de llaves; la API que arranca durante la renovación (servicios detenidos, pero alguien los inicia) o se niega o ve un estado coherente [D-F4-04] | F, W | MF-17 |
| RC-O08 | Temporales de escritura (`*.xml.tmp`) tras una muerte a mitad | No los lee la API (el repositorio toma `*.xml`); tienen la DACL heredada de `Api\anillo` (sin escritura para no administradores); la ejecución siguiente los elimina o los sobrescribe | F, W | MF-19 |
| RC-O09 | El proceso muere (kill) entre cualquier par de pasos, 30 veces con retardo aleatorio | En W/V (LABF-04); en F lo cubre RC-O02 | W, V | MF-14 |

#### 3.1.5 Trazabilidad, interacción y plataforma

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| RC-A01 | Evento de mantenimiento | 4716 con el acta, el motivo, las huellas cortas (12) del viejo y del nuevo y el número de llaves; **sin** huellas completas de recuperación ni rutas con usuarios ni claro. Va al Visor o a la salida según [D-F4-08] | F | MF-31 |
| RC-A02 | Códigos de salida | 0 hecho o "no hace falta"; 1 error, sin elevación o fuera de Windows; 2 hecho con aviso; 4 guarda (servicios activos, archivo ausente, recuperación distinta, cuenta virtual inexistente). Documentados en `--ayuda` [D-F4-02] | U, F | |
| RC-A03 | Mensajes de F1 (`--preparar` con menos de 180 días) | Mientras F4 no esté construido, el mensaje **no recomienda** un comando inexistente (QF4-04); cuando exista, el texto lo nombra exactamente como la ayuda | U | MF-24 |
| RC-C01 | Después de renovar: `anillo --recuperar` con el `.cer` de siempre (LABA-10) | Funciona: la recuperación se conservó como destinatario | F, V | MF-08 |
| RC-C02 | Después de renovar: `--cambiar-recuperacion`, `--migrar`, `--comprobar` | Funcionan con el principal nuevo; `--comprobar` 0 | F | |
| RC-C03 | Renovar a los 85 días de la última llave y arrancar la API | La llave de 90 días se crea envuelta para (principal **nuevo**, recuperación anclada) | F | MF-08 |
| RC-C04 | Respaldo de `Api\anillo` tomado **antes** de renovar y restaurado después | Las llaves del respaldo están envueltas para el principal viejo que ya no existe: solo se recuperan con la privada de recuperación (`--recuperar`); el caso documenta el hecho y exige que el procedimiento diga "respalde de nuevo tras renovar" [D-F4-11] | F, V | |
| RC-C05 | Principal en TPM (Avanzada) | Condicional a [D-F4-09]: el certificado nuevo nace en el TPM; sin TPM en Avanzada, rechazo | F, T | |
| RC-T01 | Todo el tiempo sale de `TimeProvider`; prueba de arquitectura de `DateTime.Now/UtcNow` en el código nuevo | Cumple; caso con el reloj en 2031 | U | MF-23 |

### 3.2 AV: aviso a 180 días

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| AV-01 | Umbral: restan 181 d, 180 d + 1 s, 180 d exactos, 179 d 23 h 59 min 59 s, 90, 30, 7, 1 d, 0, vencido, aún no vigente | Sin aviso con 180 d exactos o más; **aviso desde 179 d 23:59:59** ("menos de 180 días", blueprint 3.1) [D-F4-12]. Vencido y no vigente: mensajes distintos del aviso (AV-05, AV-09) | F | MF-25, MF-30 |
| AV-02 | Las cuatro superficies: `anillo --comprobar`, `comprobar-servidor`, `anillo --preparar` idempotente, arranque de la API | Las cuatro avisan con el mismo texto base: días restantes, huella corta (12) y el comando (cuando exista). La API **no** deja de arrancar | F | MF-27 |
| AV-03 | Códigos de salida con aviso | `--comprobar`: 0 (el aviso no es fallo) o 2 [D-F4-12]; `comprobar-servidor`: AVISO sin rojo hasta que A fije un umbral rojo del anillo (hoy ninguno: la regla de 20 días es de las hojas TLS) | F | MF-18 |
| AV-04 | **La API en modo Estricto con 100 días restantes y con 10 días restantes** | Arranca; 4717 `AnilloComprobado`; el aviso no cae en la ruta `throw` de `ComprobacionAnillo` (que hoy lanza en Estricto con `AnilloCarpetaNoConforme`) | F | MF-18 |
| AV-05 | Certificado vencido (reloj +5 años +1 d) | `AnilloCertificadoNoValido` (crítico), no se crean llaves, lo ya cifrado **descifra**, el mensaje manda a `--renovar-certificado` (que según RC-E04 funciona vencido) | F | MF-29 |
| AV-06 | Qué certificado se mide | El **principal del archivo**; no los `certificadosServidorAnteriores`, no la recuperación (que tiene su propia vigencia), no las hojas TLS ni la CA de `tls`. Con anteriores presentes tras una renovación interrumpida: aviso aparte de "renovación incompleta" [D-F4-05] | U, F | MF-26 |
| AV-07 | Evento y deduplicación | Hay un EventId asignado [D-F4-08]; una segunda corrida el mismo día no repite el **evento**, pero la **salida de consola** siempre lo muestra; no se guarda "ya avisé" en un lugar editable por usuarios (la consulta al Visor, `ISistemaServidor.ContarEventos`, como 4.5) | F | MF-28 |
| AV-08 | Escalado si se adopta (180, 90, 30, 7 días) | Un evento por umbral y de nivel creciente; el 7 y menos en nivel crítico; sin escalado: un solo umbral y sin repetición diaria [D-F4-12] | F | MF-25 |
| AV-09 | Reloj atrasado años; adelantado años | Atrasado: aviso de reloj, no "faltan 5 años 300 días" incoherentes; adelantado: el aviso aparece (benigno) y se corrige al volver el reloj | F | MF-30 |
| AV-10 | Contenido del mensaje | Días, huella corta y comando; **ninguna** ruta de archivo de llave, huella de recuperación completa ni usuario | U | MF-31 |
| AV-11 | Renovación exitosa | Sin aviso en la ejecución siguiente (el nuevo tiene 5 años); el viejo borrado no se vuelve a medir | F | MF-26 |
| AV-12 | Visibilidad (QF4-03) | Existe **al menos una** superficie que el técnico vea sin pedirla: evento en el Visor, línea en `comprobar-servidor` que corre la tarea, o el estado que ve el SUPER. Prueba de aceptación, no unitaria: el aviso con menos de 180 días llega a un canal persistente [D-F4-08] | F, V | MF-27 |

### 3.3 PF: `tls --importar --pfx`

Comparte la validación del certificado con `--huella` (TLS-I01 a I03, I07 a I10); aquí se prueba lo que añade el PFX: la contraseña, el archivo, la importación y el estado intermedio.

#### 3.3.1 Entradas y contraseña

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| PF-01 | Sintaxis: `--pfx` junto a `--huella`; ninguno de los dos; `--pfx` sin ruta; `--pfx` repetido; alias de contraseña `--password`, `--clave`, `--contrasena`, `-p`, `--pfx-password=x`, `/p:x`, `--password-file` | Los dos juntos y ninguno: error de uso; **cualquier forma de contraseña por argumento se rechaza antes de abrir el archivo**: el falso del sistema de archivos registra **0 aperturas**; el mensaje no repite el valor | U, F | MF-32, MF-52 |
| PF-02 | Variables de entorno con la contraseña centinela (`PFX_PASSWORD`, `PFX_CLIENTE_CLAVE`, `GPOS_PFX_CLAVE`, `GPOS_TLS_PFX`, las de [D-F4-13]) | El verbo no lee ninguna: con la variable puesta y sin consola, falla por falta de consola; con la variable puesta y una contraseña distinta por consola, usa la de consola. Si [D-F4-13] fija nombres que se **rechazan**, el rechazo es antes de abrir el archivo | F | MF-33 |
| PF-03 | Lector de contraseña: teclas con `intercept = true`; backspace; Ctrl+C; Enter vacío; contraseña de 1, 127, 1000 caracteres y con Unicode; salida estándar redirigida | Ningún carácter ni punto de eco en la salida; backspace correcto; Ctrl+C cancela sin importar nada; vacía: se intenta como "sin contraseña" solo si [D-F4-14]; el aviso para teclear va a la **salida de error** | F | MF-35 |
| PF-04 | **Entrada redirigida** (`echo clave \| GPOS.Migracion tls --importar --pfx x.pfx`, tubería, archivo, `Start-Process -RedirectStandardInput`) | Según [D-F4-15]. Hoy `Argumentos.LeerClave` la acepta (O-1). Recomendado para el PFX: **rechazo** con mensaje claro ("la contraseña del PFX se teclea en la consola"); QF4-02 | F | MF-34 |
| PF-05 | Contraseña errónea 1, 2, 3 veces; luego correcta; luego errónea 4 veces [D-F4-14] | Mensaje genérico idéntico (sin decir si falló el MAC o el formato, ni el número de caracteres); máximo de intentos documentado; el archivo queda **sin handle abierto** (se puede borrar); ningún certificado ni llave parcial en `My` | F | MF-36 |
| PF-06 | Sin consola: tarea de SYSTEM, `Start-Process` sin ventana, entrada y salida redirigidas, bajo el paquete (Burn) | Salida 1 con "ejecute esto en una consola elevada"; **nada cambia**; no se pide por otro canal (ventana, archivo, registro, variable) | F, V | MF-50 |

#### 3.3.2 El archivo y su carga

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| PF-07 | Ruta: inexistente, vacío, directorio, 1 byte, truncado, PEM, DER de un solo certificado, PKCS#7, relativa, con `..`, UNC, flujo alterno, nombre de dispositivo, enlace simbólico o unión | Rechazo con el motivo, sin repetir la ruta completa ni bytes; relativas, UNC y con reanálisis: rechazo o aviso [D-F4-16]; ninguna creación en `My` | F, W | MF-37 |
| PF-08 | **Paridad con `--huella`:** el mismo vector de certificados (TLS-I01, I02: sin llave, sin EKU, `anyExtendedKeyUsage`, `clientAuth`, SAN sin el nombre, SAN con nombre parecido, RSA 1024, SHA-1, vencido, no vigente; y los aceptables) entra por las dos vías | **Mismo veredicto** en ambas, caso por caso. La validación ocurre **sobre el certificado en memoria antes de importarlo**; un rechazado deja `My` idéntico (diff vacío) | U, F | MF-40, MF-41 |
| PF-09 | Lectura única: el archivo cambia entre la validación y la carga (el falso sustituye los bytes en la segunda lectura) | El verbo lee los bytes **una sola vez**, valida y carga **esos** bytes; el cambio no tiene efecto. Un PFX en una carpeta que un no administrador puede escribir: aviso (el contenido ya está validado, el riesgo es otro) | F | MF-37 |
| PF-10 | Límites de carga del PKCS#12 (`Pkcs12LoaderLimits`): iteraciones de MAC o de derivación excesivas (p. ej. 100 millones), estructuras anidadas, 10 000 certificados, archivo de 10 y de 100 MB [I] | Rechazo en menos de 2 s con memoria acotada; **no** `Pkcs12LoaderLimits.DangerousNoLimits`; el tamaño máximo documentado [D-F4-14]. Un PFX hostil no es un DoS del verbo elevado | F | MF-38 |
| PF-11 | Contenido: hoja + intermedia + raíz con privada solo en la hoja; PFX sin ninguna privada; con dos certificados con privada; hoja de otro nombre y la correcta | Solo la hoja que cumple va a `My`; la **intermedia y la raíz no se instalan en `Root`** ni en `CurrentUser`; intermedias: `LocalMachine\CA` solo si [D-F4-17], si no, aviso 2 (TLS-I07); sin privada: rechazo; dos con privada: rechazo o la que cubre los nombres [D-F4-17] | F, W | MF-39, MF-51 |

#### 3.3.3 Importación, ACL y publicación

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| PF-12 | Banderas de importación | `MachineKeySet \| PersistKeySet`, **sin** `Exportable`, sin `UserKeySet`; el almacén falso registra las banderas. Tras importar: `ExportPolicy = None` en el contenedor y `ExportPkcs8PrivateKey` lanza. Si la plataforma importa la llave como exportable (p. ej. proveedor heredado) [I], el verbo falla cerrado y retira lo importado | F, W | MF-42 |
| PF-13 | ACL de la llave importada | Descriptor exacto: dueño Administradores; SYSTEM y Administradores control total; `NT SERVICE\GPOS.Api` o `GPOS.Web` solo lectura; **nadie más**. La ACL por omisión de `MachineKeys` puede ser más laxa [I]: se fija explícitamente **antes de publicar**. Con `--aceptar-llave-compartida`: las dos cuentas con lectura y evento 4788 | F, W, V | MF-43 |
| PF-14 | Orden (PT-02) y fallos: importar → ACL → comprobar que la abre → comprobar cadena → publicar `HuellaX`; fallo inyectado en cada paso | Como TLS-P01 y TLS-P02: el valor anterior del registro intacto; el certificado vigente anterior intacto y servible; **lo importado por este intento y no publicado se retira junto con su llave** [D-F4-18]; lo que ya existía no se toca | F | MF-44, MF-48 |
| PF-15 | Idempotencia: el mismo PFX dos veces; el mismo certificado ya en `My` (importado a mano antes, con llave exportable); otro PFX con el mismo sujeto y emisor y mayor `NotBefore` | Mismo: sin duplicar (misma huella), salida 0. Ya en `My` y exportable: rechazo o aviso [D-F4-18] (el verbo no puede "des-exportar" una llave). Otro más reciente: toma el de mayor `NotBefore` (TLS-I08) y **conserva** el anterior hasta que venza | F | MF-45 |
| PF-16 | Cambio de origen (CA propia ↔ certificado del cliente) con PFX | La CA propia no se borra; evento 4788; mensaje de volver a emparejar estaciones y MAUI (TLS-I12). Modo "un equipo" con PFX según [D-F4-19] | F | |
| PF-17 | La tarea `--renovar` ante un certificado importado por PFX | No lo renueva (no hay CA que emita); avisa a 20, 10 y 3 días (TLS-I10); necesita saber que el origen es "cliente" sin que lo escriba nadie más [D-F4-20] | F | |
| PF-18 | Guardas previas: sin elevación; fuera de Windows; `ModoRed` ausente; claves del registro con otro dueño; `Global\GPOS.Migracion.tls` ocupado | 1, 1, 4, 4 y espera de 60 s y 1: **antes** de abrir el archivo ni pedir la contraseña (no se le pide la contraseña a quien no va a poder importar) | F | MF-01 |

#### 3.3.4 Secretos

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| PF-19 | Contraseña centinela en cada canal, con éxito, contraseña errónea, archivo corrupto y fallo en cada paso | Ni un byte en stdout, stderr, EventLog, `*.log`, el registro de Burn, el volcado de excepciones ni el árbol de archivos (se busca la cadena en todo) | F, V | MF-47 |
| PF-20 | Manejo en memoria | El lector devuelve `char[]` (no `string`), se pone a cero tras abrir el PFX con `CryptographicOperations.ZeroMemory`/`Array.Clear`; el falso comprueba el buffer; el mensaje de excepción no incluye la contraseña [I: .NET no garantiza que no queden copias] | F | MF-46 |
| PF-21 | El archivo `.pfx` del técnico | El verbo no lo copia, no lo mueve y no lo borra (no es suyo); aviso final "elimine el PFX de origen cuando termine" [D-F4-16]; ningún `.tmp` ni copia en `%TEMP%`, `ProgramData` ni el directorio actual | F, W | MF-49 |
| PF-22 | Bundle (P-5, T1-b): el paquete recibe `PFX_CLIENTE=…` | El paquete lo **rechaza al inicio**, con un mensaje que manda a `tls --importar --pfx` o a `CERTIFICADO_CLIENTE`, antes de instalar nada; el parámetro no existe en el verbo | V | MF-50 |

### 3.4 Pruebas de arquitectura de F4

| ID | Qué comprueba | Mut. |
|---|---|---|
| AR-F01 | En el código nuevo del anillo y de `tls`: sin `DateTime.Now/UtcNow` ni `DateTimeOffset.Now/UtcNow` (solo `TimeProvider`) | MF-23, MF-30 |
| AR-F02 | Sin `X509KeyStorageFlags.Exportable`, `Export(X509ContentType.Pfx/Pkcs12)`, `ExportPkcs8PrivateKey`, `Pkcs12LoaderLimits.DangerousNoLimits`, `File.Delete`/`File.Move` sobre rutas de `--pfx`, ni `Environment.GetEnvironmentVariable` para contraseñas (extiende TLS-AR02) | MF-38, MF-42, MF-49 |
| AR-F03 | Solo la implementación de Windows de `IAlmacenMaquina` usa `CngKey` y `X509Store` con escritura; la renovación y el PFX pasan por la costura | |
| AR-F04 | `Console.ReadKey`/`Console.In` solo dentro del lector de contraseña (R-F2) | MF-34, MF-35 |
| AR-F05 | El anillo y `tls` no se referencian entre sí (RT-09); el PFX importado nunca se usa como principal del anillo ni al revés | |
| AR-F06 | EventId del aviso y de la renovación declarados con `public static readonly EventId`, sin repetir (`EventIdUnicosTests`), dentro de la franja asignada [D-F4-08] | |
| AR-F07 | `anillo --renovar-certificado` y `tls --importar --pfx` constan en la lista de verbos con exclusión mutua y con G-1 (los ocho verbos protegidos más `anillo`), en un solo lugar (R-A8) | MF-17 |
| AR-F08 | Ningún mensaje de F1 nombra un comando que no exista en el binario publicado (lee la ayuda y los textos) | MF-24 |

## 4. Trazabilidad con los planes y el blueprint

| Origen | Qué prueba allí | Aquí |
|---|---|---|
| Blueprint 3.1 paso 5 (idempotencia, 180 días) | Plan del anillo ANI-A, ANI-T02 | AV-01 a AV-12, RC-E05 |
| Blueprint 3.5 (rotación del certificado) | ANI-T05 y LABA-20, "condicional, no se escribe hasta que B fije el contrato" | RC-xx: **sustituye** a ANI-T05; LABF-01 a LABF-09 sustituyen a LABA-20 |
| Blueprint 3.5 (aviso) | ANI-T02 | AV-xx |
| Blueprint 4.6 (PFX) | TLS-I04 a I06, TLS-O04 | PF-01 a PF-06, PF-19 (los I04 a I06 "pasan a F4 con P-5", blueprint 7.2) |
| Blueprint 7.2 (LABT-19 y LABT-21 pasan a F4) | LABT-19 bundle; LABT-21 rotación de CA | LABF-17 (bundle, bloqueado); **LABT-21 (sucesora con cruzado) sigue condicional, P-6 sin fecha, y no se trata aquí** |
| Hoja P-5, P-8 | TLS-I13 | PF-13, PF-22 |
| `RecuperarAnillo.cs` (reenvoltorio existente) | ANI-R01 a R10, LABA-10 | RC-R01 a R08 reutilizan su oráculo; RC-C01 es la regresión |

## 5. Casos de laboratorio en `VM-SRV` (VirtualBox, `LFMB`)

**Reglas heredadas** (planes del anillo y de `tls`): solo `VM-SRV` desde el punto de control `base`; una VM a la vez; un punto de control por bloque (`Puntos-Control.ps1 -Accion Tomar -Nombre LABF-<ID>` y, al terminar, `Restaurar -Nombre base -Apagar`); `Preparar-Vm.ps1` crea el marcador de las guardas [V]; ningún agente ejecuta esto, lo opera B; si algo falla no se corrige a mano, se anota y se restaura; cada `msiexec` con `/l*v`; **ningún secreto en la evidencia** (contraseña centinela falsa y visible, nunca `reg export` de claves de servicio ni copia del contenido de un archivo de llave); `Probar-Redaccion.ps1` sobre toda la evidencia antes de copiarla fuera.

**Precondiciones** (si falta una, el caso es `No se pudo`, nunca `Cumple`): F1 publicado (`anillo --preparar` y el anillo en marcha); F4 publicado (`anillo --renovar-certificado`, `tls --importar --pfx`); F3 publicado para PF; `GPOS.Api.msi` instalado (existe `NT SERVICE\GPOS.Api`); SQL Server Express para los casos marcados SQL; el par de recuperación desechable de F1; `GPOS_SYSDATA` con el ancla puesta (`anillo --anclar`).

**Funciones de apoyo** (PowerShell elevado; solo lectura). Se reutiliza `EstadoAnillo` de LABA (plan del anillo, sección 5) y `EstadoTls` de LABT. Se añade:

```powershell
$E = 'C:\GPOS-LAB\evidencia'
function ContenedoresAnillo([string]$id){      # nombres de llaves CNG de máquina del anillo, sin contenido
  $d = New-Item -ItemType Directory -Force "$E\$id"
  Get-ChildItem 'C:\ProgramData\Microsoft\Crypto\Keys','C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys' -Force -ErrorAction SilentlyContinue |
     Select-Object Name,Length,LastWriteTimeUtc | Export-Csv "$d\contenedores.csv" -NoTypeInformation   # se cuenta; no se copia contenido
  certutil -store -v My 2>&1 | Select-String -Pattern 'Subject|Serial|Cert Hash\(sha256\)|Provider|Container' | Out-File "$d\certutil-my.txt"
}
function BuscarCentinela([string]$id,[string]$centinela){   # la contraseña de laboratorio no debe aparecer en ningún sitio
  $d = New-Item -ItemType Directory -Force "$E\$id"
  Get-ChildItem 'C:\GPOS-LAB','C:\ProgramData\GPOS NG',$env:TEMP,'C:\Windows\Temp' -Recurse -File -Force -ErrorAction SilentlyContinue |
     Select-String -SimpleMatch $centinela -ErrorAction SilentlyContinue | Select-Object Path | Out-File "$d\archivos-con-centinela.txt"
  Get-WinEvent -LogName Application -MaxEvents 500 -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*$centinela*" } | Select-Object Id,TimeCreated | Out-File "$d\eventos-con-centinela.txt"
  Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue | Select-String -SimpleMatch $centinela | Out-File "$d\historial-con-centinela.txt"
}
```

| ID | Caso | Cómo | Esperado | Evidencia | Mapea | Marca |
|---|---|---|---|---|---|---|
| LABF-01 | Renovación de punta a punta | `EstadoAnillo` y `ContenedoresAnillo` antes; proteger una cadena y escribir las cuentas iniciales (PR-D2); **detener** `GPOS.Api`; `anillo --renovar-certificado --acta LAB --motivo prueba`; `anillo --comprobar`; iniciar la API; `restablecer-factor` | Salida 0; un certificado nuevo en `My` con llave; el viejo y **su contenedor** desaparecen (el recuento de contenedores `GPOS.Anillo.Api.*` vuelve a 1); el archivo apunta al nuevo; 4716 con el acta; la API arranca (4717) y descifra lo anterior; `Licencia.InstalacionId` verifica | `EstadoAnillo` antes/después, `contenedores.csv`, Visor | RC-R01, R02, O01, O05 | SQL |
| LABF-02 | Servicio activo | Con `GPOS.Api` en `Running`: `--renovar-certificado`; luego en `StopPending` (si se logra) | Rechazo con 4; ningún cambio (diff vacío de `EstadoAnillo` y de los hashes de `key-*.xml`) | Salidas, `archivos.csv` | RC-E02 | SQL |
| LABF-03 | ACL y no exportable del certificado nuevo | `certutil -exportPFX`; `Export-PfxCertificate`; script .NET con `ExportPkcs8PrivateKey`; `icacls` sobre el archivo de llave (sin copiar contenido); derechos efectivos de `NT SERVICE\GPOS.Api` | Todo falla; ningún `.pfx`/`.p12`/`.pem` en `C:\`, `%TEMP%` ni `ProgramData`; ACL exacta del vector de F1; el servicio solo lectura (sin `WRITE_DAC`/`DELETE`) | `icacls`, listado de archivos | RC-P04, P05; LABA-02, 03 | [I] ruta del contenedor |
| LABF-04 | Muerte súbita durante la renovación | Con 40 llaves en `Api\anillo` (la API arrancada, luego detenida; llaves generadas con el reloj): 30 veces, lanzar la renovación y `Stop-Process -Force` tras 0 a 3 s aleatorios; después `anillo --comprobar`, iniciar la API, y una renovación normal | Tras **cada** muerte: la API arranca y descifra (sin llaves ilegibles), el archivo apunta a un certificado que existe y se abre, no hay más de un contenedor huérfano; la renovación normal siguiente converge a un estado con un solo certificado | `EstadoAnillo` por iteración, `contenedores.csv`, `anillo --comprobar` | RC-O02, O09; QF4-01 | SQL; **es el caso que decide QF4-01**; sin ganchos en el código de producción |
| LABF-05 | Certificado anterior vencido | Punto de control `T0`; adelantar el reloj de la VM a `NotAfter + 1 d` (desactivar la sincronización de Guest Additions); `--comprobar` (esperado `AnilloCertificadoNoValido`); detener la API; `--renovar-certificado` | Antes: `AnilloCertificadoNoValido`, sin llaves nuevas, lo cifrado descifra; la renovación procede y deja un certificado vigente por 5 años desde el reloj de la VM | Visor, `EstadoAnillo` | RC-E04, AV-05 | SQL; la licencia de laboratorio puede vencer con el reloj movido (LS-15): usar la licencia de laboratorio larga o la API detenida [I] |
| LABF-06 | Certificado anterior perdido | Borrar el certificado y su llave de `My` a mano (con punto de control); `--renovar-certificado` | Rechazo con el motivo y la indicación `--recuperar`; sin cambios | Salida, `EstadoAnillo` | RC-E03 | SQL |
| LABF-07 | Aviso a 180 días | `T0`; reloj a `NotAfter − 181 d`, `− 180 d + 1 min`, `− 179 d`, `− 30 d`; en cada uno `anillo --comprobar`, `comprobar-servidor`, `--preparar` (idempotente) e iniciar la API en modo Estricto | Aviso exactamente desde `< 180 d`; las cuatro superficies avisan; la API arranca en las cuatro; un evento por día como mucho; el aviso está en un canal persistente (AV-12) | Visor, salidas | AV-01 a AV-04, AV-07, AV-12 | SQL; reloj movido, ver LABF-05 |
| LABF-08 | Recuperación después de renovar | Con el estado de LABF-01: respaldar `Api\anillo`, `GPOS_SYSDATA` y `rec.cer`; restaurar la VM a `base`; restaurar; `--preparar --recuperacion rec.cer` (2); importar el PFX de recuperación desechable con la contraseña tecleada; `anillo --recuperar … --acta --motivo`; borrar el PFX; `--comprobar` | Las llaves reenvueltas para el principal **nuevo** se recuperan con la misma recuperación; `NoRecuperables = 0`; la API arranca | `EstadoAnillo`, hashes de `key-*.xml` | RC-C01, LABA-10 | SQL; contraseña tecleada a mano |
| LABF-09 | Respaldo anterior a la renovación | Respaldo de `Api\anillo` antes de LABF-01; renovar; restaurar **solo** `Api\anillo` anterior a una VM restaurada sin certificado | Llaves del principal viejo inexistente: la API no las abre; `--recuperar` sí | Salidas | RC-C04; D-F4-11 | SQL |
| LABF-10 | Importar un PFX (camino feliz) | En la VM, el arnés genera un PFX de cliente (hoja ECDSA P-256 con `serverAuth`, SAN con el nombre del sitio, firmada por una CA de laboratorio) con la contraseña centinela; la CA de laboratorio en `LocalMachine\Root` de la VM y del puesto; `tls --importar --pfx C:\GPOS-LAB\cli.pfx` tecleando la contraseña; luego `tls --comprobar` y `Invoke-WebRequest https://<nombre>` desde `VM-PUESTO` | Salida 0; un certificado en `My` con llave; `certutil -exportPFX` falla; ACL exacta (solo la cuenta del servicio con lectura); `HuellaApi`/`HuellaWeb` publicadas; el sitio responde con el certificado importado; 4780 (y 4788 si compartido) | `EstadoTls`, `contenedores.csv`, `icacls`, respuesta | PF-08, 12, 13, 14 | Contraseña tecleada a mano; requiere F2 y F3 |
| LABF-11 | Canales de la contraseña | Después de LABF-10, y con una contraseña errónea y un PFX corrupto: `BuscarCentinela` | La centinela no aparece en archivos, Visor, historial de PowerShell ni salida; ningún archivo temporal con material de llave | `archivos-con-centinela.txt`, `eventos-con-centinela.txt` | PF-19, 20, 21 | |
| LABF-12 | Contraseña por argumento, variable y tubería | `tls --importar --pfx x.pfx --password CENTINELA`; `$env:PFX_PASSWORD='CENTINELA'`; `'CENTINELA' \| GPOS.Migracion tls --importar --pfx x.pfx` | Argumento y variable: rechazo antes de abrir el archivo (el monitor de procesos, `procmon`, no muestra lectura del `.pfx`); tubería: rechazo [D-F4-15] | Salidas, `procmon` filtrado | PF-01, 02, 04 | `procmon` en la VM [I] |
| LABF-13 | Sin consola | `schtasks /create /ru SYSTEM` con el verbo y `--pfx`; `Start-Process -NoNewWindow -RedirectStandardInput` | Salida 1 con el mensaje; ninguna ventana ni archivo pidiendo la contraseña; `My` sin cambios | Salida, `EstadoTls` | PF-06 | |
| LABF-14 | PFX hostil | PFX con iteraciones enormes (el arnés lo genera); PFX de 100 MB; PFX con cadena completa (hoja + intermedia + raíz) | El hostil y el grande: rechazo en menos de 2 s sin consumir memoria apreciable (Administrador de tareas); cadena completa: solo la hoja en `My`, nada nuevo en `Root`/`CA`/`CurrentUser` | `EstadoTls` antes/después, medida de memoria | PF-10, PF-11 | [I] los tiempos |
| LABF-15 | Fallo a la mitad de la importación | Muerte súbita del proceso 20 veces con retardo aleatorio durante `--importar --pfx` (contraseña tecleada por un guion `SendKeys` desechable, o `PtyHost` equivalente [I]); luego una importación normal | Sin certificados huérfanos en `My`, sin contenedores CNG huérfanos (o a lo sumo uno, retirado por la ejecución siguiente), `HuellaX` anterior intacta tras cada muerte; la siguiente importación termina | `EstadoTls`, `contenedores.csv` | PF-14, PF-19 | La entrada automatizada contradice "tecleada": solo en el laboratorio; si B no ofrece forma, queda "No se pudo" |
| LABF-16 | Importar dos veces, y mismo certificado ya en `My` exportable | Importar el mismo PFX dos veces; importar con `certutil -importPFX` (exportable) y luego con el verbo | Dos veces: sin duplicados; exportable previo: rechazo o aviso según [D-F4-18] | `EstadoTls` | PF-15 | |
| LABF-17 | *Bundle* con `PFX_CLIENTE` | El paquete con `PFX_CLIENTE=…` y con `CERTIFICADO_CLIENTE=<huella>` | `PFX_CLIENTE`: rechazo al inicio, nada instalado; huella: sigue | Registro de Burn (`/l*v`) | PF-22; LABT-19 | **Bloqueado hasta T1-b** |
| LABF-18 | Linux | En `VM-LNX`, si se publica allí: `anillo --renovar-certificado` y `tls --importar --pfx` | "Fuera de Windows", salida ≠ 0, 0 archivos | Salida | RC-E01, PF-18 | Solo si se publica en Linux |
| LABF-19 | Renovar con Avanzada y TPM | Condicional a [D-F4-09] | Según RC-C05 | | RC-C05 | Condicional |
| LABF-20 | Reinicio del equipo tras renovar y tras importar | Reiniciar `VM-SRV` | La API y la Web arrancan solas con el certificado nuevo / importado; el archivo, las huellas y la llave no cambian; 4717 | Visor | RC-O01, PF-14 | |

**Reparto por sesión y duración [I, ±50 %, a refinar con la primera ejecución].**

| Sesión | Bloque | VM | Casos | Horas |
|---|---|---|---|---|
| 1 | Renovación del certificado (con SQL) | `VM-SRV` | LABF-01, 02, 03, 06, 20 | 3,0 |
| 2 | Interrupciones, reloj y recuperación | `VM-SRV` | LABF-04, 05, 07, 08, 09 | 3,5 |
| 3 | PFX | `VM-SRV` y `VM-PUESTO` | LABF-10 a 16 | 3,0 |

Total unas 9,5 h. LABF-17 (bundle), 18 y 19 dependen de T1-b, de que se publique en Linux y de [D-F4-09].

## 6. Mutaciones que el plan debe matar

Cada una se aplica a la implementación y el caso indicado debe fallar. Todas son [I] hasta que B las convierta en líneas.

| ID | Bloque | Mutación | Casos que la matan |
|---|---|---|---|
| MF-01 | RC, PF | Se toca el almacén, el archivo o se pide la contraseña antes de comprobar plataforma y elevación | RC-E01, PF-18 |
| MF-02 | RC | `--acta` o `--motivo` opcionales o en blanco | RC-E01 |
| MF-03 | RC | No se comprueba el servicio, solo se mira `Running`, o un error de la consulta se toma como "detenido" | RC-E02 |
| MF-04 | RC | Renueva con la recuperación del archivo distinta de la anclada, sin ancla o con el ancla sin verificar | RC-E03, RC-R07 |
| MF-05 | RC | Reutiliza la llave del certificado anterior | RC-P02 |
| MF-06 | RC | Mismo sujeto o misma serie (reloj o aleatorio fijo) | RC-P02 |
| MF-07 | RC | Contenedor repetido: `OverwriteExistingKey` o sin comprobar existencia | RC-P03 |
| MF-08 | RC | Reenvuelve solo para el principal nuevo (omite la recuperación) o para la recuperación del archivo en lugar de la anclada | RC-R01, RC-C01, RC-C03 |
| MF-09 | RC | Regenera el material de las llaves en lugar de reenvolverlas | RC-R01, RC-R02 |
| MF-10 | RC | Continúa tras una llave conforme que no se abre y la deja sin reenvolver, o reenvuelve las no conformes | RC-R03, RC-R05 |
| MF-11 | RC | Escribe cada llave antes de verificar todas | RC-R06 |
| MF-12 | RC | Borra el certificado anterior antes de `--comprobar` o aunque falle | RC-O01, RC-O04 |
| MF-13 | RC | Publica el archivo antes de reenvolver, o reenvuelve y nunca publica | RC-O01, RC-O02 |
| MF-14 | RC | Escritura de llaves sin red: tras una interrupción el archivo no admite al principal que algunas llaves nombran (QF4-01) | RC-O02, RC-O03, RC-O09, LABF-04 |
| MF-15 | RC | Borra el certificado pero deja la llave CNG | RC-O05, LABF-01 |
| MF-16 | RC | Borra por sujeto o `FriendlyName` | RC-O05 |
| MF-17 | RC, AR | Sin exclusión mutua con `preparar`, `cuentas-iniciales`, `renovar` | RC-O07, AR-F07 |
| MF-18 | AV | El aviso de 180 días se trata como error: salida ≠ 0 o la API no arranca en Estricto | AV-03, AV-04 |
| MF-19 | RC | Deja `.xml.tmp` con otra DACL, o la API los lee como llaves | RC-O08 |
| MF-20 | RC | Descriptor fijado después de crear la llave; o `Exportable` | RC-P04, RC-P05 |
| MF-21 | RC | Perfil distinto del de F1 (EKU `serverAuth`, `cA = true`, otra KU, vigencia de 397 días) | RC-P01 |
| MF-22 | RC | Renueva siempre (ignora el umbral) o nunca sin `--forzar`; rechaza el certificado vencido | RC-E04, RC-E05, RC-O06 |
| MF-23 | RC, AV | Reloj del sistema directo | RC-T01, AR-F01 |
| MF-24 | RC | Un mensaje de F1 recomienda un comando que no existe, o F4 lo nombra distinto de la ayuda | RC-A03, AR-F08 |
| MF-25 | AV | Umbral `<=` en lugar de `<`, o "6 meses" calendario, o 183 días | AV-01, AV-08 |
| MF-26 | AV | Mide el certificado equivocado (anterior, recuperación, hoja TLS, CA) | AV-06, AV-11 |
| MF-27 | AV | Aviso en una sola superficie, o solo en la salida de consola | AV-02, AV-12 |
| MF-28 | AV | Sin deduplicación; o deduplicación en un archivo editable; o la deduplicación suprime también la consola | AV-07 |
| MF-29 | AV | Vencido tratado igual que "quedan días" | AV-05 |
| MF-30 | AV | `DateTime.UtcNow`; cuenta mal con el reloj atrasado | AV-01, AV-09, AR-F01 |
| MF-31 | RC, AV | Mensaje o evento con huellas completas, rutas o claro | RC-A01, AV-10 |
| MF-32 | PF | Acepta contraseña por argumento (cualquier alias) | PF-01 |
| MF-33 | PF | Lee la contraseña de una variable de entorno | PF-02, AR-F02 |
| MF-34 | PF | Acepta la entrada redirigida | PF-04, AR-F04 |
| MF-35 | PF | Eco de la contraseña (`intercept: false`) o eco de marcadores | PF-03, AR-F04 |
| MF-36 | PF | Mensaje distinto para MAC y formato; intentos ilimitados; handle del archivo abierto | PF-05 |
| MF-37 | PF | Valida sobre una lectura y carga otra (dos lecturas del archivo); sigue enlaces | PF-07, PF-09 |
| MF-38 | PF | `Pkcs12LoaderLimits.DangerousNoLimits` o sin tope de tamaño | PF-10, AR-F02 |
| MF-39 | PF | Importa la cadena completa (intermedias o raíz a `Root`/`CA`/`CurrentUser`) | PF-11 |
| MF-40 | PF | La rama PFX omite alguna regla de `--huella` (A5, SAN por etiquetas, EKU, vigencia) | PF-08 |
| MF-41 | PF | Importa a `My` antes de validar | PF-08, PF-14 |
| MF-42 | PF | `Exportable`, `UserKeySet` o sin `PersistKeySet`/`MachineKeySet` | PF-12, AR-F02 |
| MF-43 | PF | ACL por omisión de la plataforma, o fijada después de publicar | PF-13 |
| MF-44 | PF | Publica sin comprobar que la cuenta abre la llave | PF-14 |
| MF-45 | PF | Duplica al reimportar, o sustituye el vigente sin conservarlo | PF-15 |
| MF-46 | PF | Contraseña en `string` retenido, o sin limpiar | PF-20 |
| MF-47 | PF | Contraseña en salida, eventos o excepciones | PF-19, LABF-11 |
| MF-48 | PF | Deja huérfano lo importado cuando el paso siguiente falla | PF-14, LABF-15 |
| MF-49 | PF | Copia, mueve o borra el `.pfx` del técnico, o deja temporales | PF-21, AR-F02 |
| MF-50 | PF | Sin consola, pide la contraseña por otro canal; el paquete acepta `PFX_CLIENTE` | PF-06, PF-22 |
| MF-51 | PF | Acepta un PFX con la hoja sin privada o con varias privadas sin criterio | PF-11 |
| MF-52 | PF | Acepta `--pfx` y `--huella` juntos | PF-01 |

## 7. Hallazgos de lectura (de este plan)

Ninguno Crítico ni Alto. Los tres Medios deben decidirse antes de construir.

| ID | Severidad | Hallazgo | Evidencia | Qué se pide |
|---|---|---|---|---|
| QF4-01 | **Media** | **Orden de la renovación y estado intermedio.** El blueprint 3.5 reenvuelve y escribe cada llave (2) y recién después publica el archivo (3); la "red de seguridad" `CertificadosServidorAnteriores` cubre el caso inverso (el archivo ya apunta al nuevo y quedan sobres del viejo). Si el proceso muere con k de N llaves ya reenvueltas **para el principal nuevo** y el archivo aún apunta al **viejo**, esas k llaves nombran como principal un certificado que `PrincipalesAdmitidos()` (principal del archivo + anteriores) no admite, y el viejo no puede abrirlas. Además `RecuperarAnillo` escribe archivo por archivo con `.tmp` y `File.Move` (sin transacción entre archivos) y es el patrón que F4 reutiliza | `blueprint 3.5, pasos 2 y 3`; `OrigenCertificadosAnillo.cs:30-50, 76-85` [V]; `RecuperarAnillo.cs` "3. Escribir" [V]; la API necesita abrir con la privada del principal que el sobre nombra [I] | Que el diseño garantice los invariantes I1 a I4 de RC-O02: por ejemplo, publicar **primero** el archivo con el nuevo como principal y el viejo en `anteriores` (admitiendo los dos), y que el cargador de la API abra un sobre con la privada de cualquiera de los admitidos; o un reenvoltorio que añada el principal nuevo como destinatario sin quitar el viejo hasta el final. Decide B; LABF-04 y RC-O02 lo comprueban |
| QF4-02 | **Media** | **La contraseña del PFX puede llegar por tubería.** `Argumentos.LeerClave` devuelve un `string` y, con la entrada redirigida, lee la primera línea (`Program.cs:499-505`, comentario "O-1"). Es correcto para la contraseña de SQL en automatización, pero si `--importar --pfx` reutiliza el ayudante, un guion o una variable de Burn podrían pasar la contraseña por la tubería, que es exactamente el canal que N-7 y ADR-90 `:136` quieren excluir ("la pide el verbo en la consola elevada y no se registra"). Tampoco es `char[]` | `Program.cs:499-516` [V]; `ADR-090.md:136` [V]; blueprint 4.6 | Decidir si el PFX rechaza la entrada redirigida (recomendado) y usar un lector propio con `char[]` (R-F2) |
| QF4-03 | **Media** | **El aviso a 180 días no tiene canal.** El blueprint dice que `anillo --comprobar` y `comprobar-servidor` avisan, pero ambos son verbos que alguien debe ejecutar; no hay tarea programada del anillo (la de `tls` renueva hojas) ni evento propio; el 4716 se reutiliza y "hoy va al registro de consola y a la salida, no al Visor". Un certificado de 5 años con un aviso que nadie recibe llega al vencimiento: la API deja de crear llaves (`ComprobacionAnillo.cs:150-151`), no cae, pero el siguiente ciclo de 90 días falla y el técnico no sabe por qué | blueprint 3.1 paso 12 y 3.5; `ComprobacionAnillo.cs:150-151` [V] | EventId propio en el Visor (la API lo emite al arrancar con avisos), o ampliar la tarea `Renovar TLS` para que ejecute la comprobación del anillo; AV-12 es la prueba de aceptación |
| QF4-04 | Baja | El paso 5 de `--preparar` (F1) imprime "renueve con `--renovar-certificado`, F4" cuando el comando todavía no existe | blueprint 3.1 paso 5 | Texto sin comando hasta F4 (RC-A03, AR-F08) |
| QF4-05 | Baja | `--importar --pfx` importa a `LocalMachine\My`; la ACL por omisión de `MachineKeys` y si la plataforma conserva la bandera de no exportable al importar un PKCS#12 con proveedor heredado dependen del proveedor que elija .NET [I, sin verificar] | blueprint 4.6 | PF-12 y PF-13 en W y V antes de cerrar F4; si no se cumple, el diseño debe cambiar a "crear la llave nueva con el descriptor y reimportar el material" (que no cabe con no exportable) o aceptar el residual con la misma redacción de H-13 |
| QF4-06 | Baja | La CA de `tls` vive 10 años y la sucesora está fuera (P-6); no existe aviso para la CA (el de 180 días es del anillo y el de 20/10/3 de las hojas). A los 9 años no avisa nadie | blueprint 1 y 4.5; hoja P-6 | Ampliar el aviso de la CA a 365 o 180 días, o anotarlo como residual en la hoja de P-6 (no se prueba aquí) |

## 8. Requisitos de testabilidad para B (condición del nivel U y F)

Se suman a R-A1 a R-A10 (plan del anillo) y R-T1 a R-T8 (plan de `tls`).

| ID | Costura | Para qué |
|---|---|---|
| R-F1 | `IAlmacenMaquina` ampliada: **importar un PKCS#12 desde bytes y `char[]`** devolviendo el certificado y registrando las banderas; consultar `ExportPolicy` y el descriptor de la llave; borrar un certificado **con su contenedor** por huella; nombrar contenedor con detección de colisión | RC-P03, RC-O05, PF-12, PF-13 |
| R-F2 | **Lector de contraseña** como interfaz (`ILectorClave.Leer()` → `char[]`; propiedades `EntradaRedirigida`, `SalidaRedirigida`, `HayConsola`), con falso que registra `intercept`, eco y buffers | PF-03 a PF-06, PF-20, AR-F04 |
| R-F3 | **Lector de archivos de entrada** (bytes únicos, tamaño, atributos de reanálisis, ACL) con falso que sustituye el contenido entre lecturas y cuenta aperturas | PF-01, PF-07, PF-09 |
| R-F4 | **Inyección de fallo por paso numerado**: la renovación y la importación se expresan como una lista de pasos con nombre que el falso puede recorrer (`FallarEn(n)`), y el repositorio de llaves admite `FallarTrasEscribir(j)` | RC-O02, RC-O03, PF-14 |
| R-F5 | **Repositorio de llaves del anillo** detrás de una interfaz que escribe cada archivo con `.tmp` + `Move` y se puede sustituir por uno que muere a mitad | RC-O02, RC-O08 |
| R-F6 | **`TimeProvider`** en la renovación, el aviso y el cálculo de vigencia; y en `AnilloPrueba.Anclar` (QA-AN-07) | RC-T01, AV-01, AV-09 |
| R-F7 | **El validador del certificado del cliente como función única** (`ValidadorCertificadoCliente.Validar(X509Certificate2, nombres, ahora)`) usada por `--huella` y `--pfx`; la prueba de paridad la llama por las dos vías | PF-08, MF-40 |
| R-F8 | **Evento y deduplicación del aviso** detrás de `ISistemaServidor.ContarEventos` y escritura de evento (existen en PR-V [V]), con el EventId del aviso declarado | AV-07, AR-F06 |
| R-F9 | **Comprobación final de la renovación** (`--comprobar`) invocable como función con el origen de certificados en memoria, para RC-O04 | RC-O04 |
| R-F10 | **Vectores**: ampliar `anillo-dm07.v1.json` con el perfil de renovación y `adr090-tls.v1.json` con los certificados de cliente (los 14 de TLS-I01/I02) y un generador de PFX en memoria (hostil, con cadena, sin privada, con dos privadas) en `PkiLaboratorio` | RC-P01, PF-08, PF-10, PF-11 |

## 9. Dudas para B

No inventé el contrato: donde falta, escribí el caso con el supuesto más probable (**[D]**). Las marcadas **(bloquea)** impiden escribir el caso o su esperado.

| ID | Duda | Supuesto | Casos |
|---|---|---|---|
| **D-F4-01** | **(bloquea)** ¿`--renovar-certificado` es una acción de `anillo` (blueprint 3.5) y no de `tls`, como sugiere el encargo? ¿Aplica también a `--servicio web` (anillo de la Web, F4, 0,5 dp) o solo a `api`? | Es de `anillo`; la Web queda aparte | RC-E06 |
| **D-F4-02** | **(bloquea)** Sintaxis y códigos de salida de `--renovar-certificado` (hoy no se enumeran) | 0 hecho o no hace falta; 1 error; 2 hecho con aviso; 4 guarda | RC-E01, RC-A02 |
| D-F4-03 | ¿Cuándo se permite: siempre, solo con 180 días o menos, o con `--forzar`? ¿Con el servicio **no instalado** se permite (instalación sin MSI)? | Solo con ≤ 180 d salvo `--forzar`; sin servicio: procede | RC-E02, RC-E05, RC-O06 |
| D-F4-04 | ¿Qué impide que alguien inicie la API durante la renovación (servicios "detenidos" solo se comprueba al empezar)? ¿Exclusión mutua nombrada compartida con `preparar`? | Mutex `Global\GPOS.Migracion.anillo` y comprobación de servicios también justo antes de publicar | RC-O07 |
| **D-F4-05** | **(bloquea)** Orden de reescritura y significado de `certificadosServidorAnteriores` durante y después de la renovación (QF4-01): ¿qué se publica primero?, ¿la API abre un sobre con la privada de un principal "anterior"?, ¿cuándo se vacía la lista? | Archivo con nuevo y viejo antes de reenvolver; se vacía tras `--comprobar` | RC-O02, RC-O03, AV-06 |
| D-F4-06 | **(bloquea)** Todo o nada con llaves no conformes o no legibles; qué hace con 0 llaves; con llaves de otro principal | Todo o nada para las conformes; las demás se informan; 0 llaves procede; otro principal: no las toca | RC-R03 a R05 |
| D-F4-07 | ¿Se permite renovar con el certificado anterior **vencido**? | Sí (abrir con la privada no exige vigencia) | RC-E04, AV-05 |
| **D-F4-08** | **(bloquea)** Aviso a 180 días: EventId y nivel; ¿quién lo emite (verbo, API al arrancar, `comprobar-servidor` de A)?; deduplicación; ¿hay tarea periódica que lo ejecute?; ¿llega al Visor? (QF4-03) | Evento propio (franja por asignar), emitido por la API al arrancar y por `comprobar-servidor` | AV-02, AV-07, AV-12, RC-A01 |
| D-F4-09 | ¿Qué hace la renovación con el principal en TPM (Avanzada, punto 8 de H-17 v2, "F4 y después de AP-10")? ¿Entra ahora o después? | Después de AP-10; ahora solo Básica | RC-C05, LABF-19 |
| D-F4-10 | ¿Colisión del contenedor `<AAAAMMDDhhmmss>` en el mismo segundo: sufijo o error? | Error, sin sobrescribir | RC-P03 |
| D-F4-11 | ¿El procedimiento exige un **respaldo nuevo de `Api\anillo`** después de renovar (H-17 v2 punto 1)? ¿Lo dice el mensaje final? | Sí, y el mensaje lo dice | RC-C04, LABF-09 |
| **D-F4-12** | **(bloquea)** Umbral exacto del aviso (`< 180 d`), código de salida con aviso en `--comprobar` y `comprobar-servidor` (AVISO no rojo), ¿escalado a 90, 30 y 7 días? | Un umbral de 180 d, salida 0, sin rojo; un solo aviso diario | AV-01, AV-03, AV-08 |
| **D-F4-13** | **(bloquea)** ¿Qué nombres de variable de entorno se "rechazan" (el blueprint dice "rechazada si llega por argumento o por variable") y qué alias de argumento? ¿O el verbo simplemente no los lee? | No los lee; los alias `--password`, `-p`, `--clave` se rechazan por lista cerrada | PF-01, PF-02 |
| D-F4-14 | Intentos permitidos, tamaño máximo del PFX, límites de PKCS#12, ¿contraseña vacía admitida? | 3 intentos, 1 MB, `Pkcs12LoaderLimits` por omisión, vacía solo si el PFX no tiene contraseña | PF-03, PF-05, PF-10 |
| **D-F4-15** | **(bloquea)** ¿Se acepta la contraseña del PFX por **entrada redirigida**? (`LeerClave` la acepta hoy para SQL) | No; QF4-02 | PF-04, LABF-12 |
| D-F4-16 | Ruta del PFX: relativa, UNC, en carpeta escribible por no administradores, enlaces; ¿el verbo avisa de borrar el PFX al terminar? | Rechaza UNC, relativa, reanálisis; avisa de borrar | PF-07, PF-21 |
| D-F4-17 | PFX con cadena: ¿intermedias a `LocalMachine\CA` o solo aviso (TLS-I07)? PFX con dos privadas: ¿rechazo o la que cubre los nombres? | Solo aviso 2; rechazo | PF-11 |
| D-F4-18 | Lo importado y no publicado, ¿se retira? Mismo certificado ya en `My` con llave exportable: ¿rechazo o aviso? | Se retira lo propio; rechazo | PF-14, PF-15, LABF-16 |
| D-F4-19 | ¿`--pfx` se admite en modo `UnEquipo`? ¿Y en Avanzada con RSA 2048 (A5) frente a ECDSA P-256 (RT-09, D-16bis)? | Solo en `ServidorSitio`; Avanzada según A5 | PF-16 |
| D-F4-20 | ¿Dónde se guarda que el certificado vigente es "del cliente" para que la tarea `--renovar` no intente renovarlo? ¿Un valor del registro (lo escribe solo el verbo)? | Valor `OrigenTls` en la clave `Servidor`, escritor único `tls` | PF-17 |
| D-F4-21 | **Dependencia de firma:** F2 y F3 siguen pendientes de firma (hoja del PR #221). ¿Se escribe ya el código de prueba de PF o se espera? | Se esperan; se escribe antes RC y AV, que dependen solo de F1 | PF-xx |

## 10. Esfuerzo, orden y dependencias [I, ±40 %]

| Bloque | dp | Cuándo |
|---|---|---|
| RC: U/F/W (37 casos, 24 mutaciones) | 1,0 | Con F4 del anillo; después de F1 |
| AV: U/F (12 casos) | 0,25 | Con F1 si el aviso entra con `--preparar`; el resto con F4 |
| PF: U/F/W (22 casos, 21 mutaciones) | 0,6 | Después de F3 (`--importar --huella`) |
| Arnés: R-F1 a R-F10, vectores, generador de PFX, arquitectura | 0,35 | Antes que RC y PF |
| Laboratorio: 20 casos en 3 sesiones | unas 9,5 h | Con la VM del instalador (T1-b) y F4 publicado |

Total pruebas unos 2,2 dp. **Orden:** decidir D-F4-05 (QF4-01), D-F4-08 y D-F4-15 antes de abrir el PR de F4; R-F1 a R-F4 en el primer commit; AV con F1; RC y PF en el PR de F4; laboratorio antes de la primera instalación real. No corren a la vez la suite completa y el laboratorio (CLAUDE.md).

## 11. Qué no verifiqué

- Que `X509CertificateLoader.LoadPkcs12` con `MachineKeySet | PersistKeySet` deje la llave no exportable y con qué ACL por defecto en Windows 11 / Server 2022 y 2025 (QF4-05, PF-12, PF-13) [I].
- Que `Pkcs12LoaderLimits.Default` rechace en menos de 2 s un PFX con iteraciones enormes (PF-10) [I].
- Que la API, al arrancar, abra un sobre con la privada de un certificado listado en `certificadosServidorAnteriores`; `OrigenCertificadosAlmacen.PrincipalesAdmitidos` lo **admite como principal**, pero `Principal()` devuelve uno solo (D-F4-05) [V el código; I el efecto].
- Si VirtualBox permite mover el reloj de la VM con la licencia de laboratorio y los certificados del sistema sin romper otros casos (LABF-05, LABF-07).
- Si existe una forma desechable de teclear una contraseña en un proceso para el laboratorio (LABF-15).
- La hoja de firma del PR #221 existe solo en la rama `b/hoja-firma-tls-anillo` (`ecacd985`); no la vi en `master`.
- Ninguna prueba se ejecutó; nada compiló.

### Cierre
- Estado: Completado (plan entregado; 8 dudas bloquean casos)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-pruebas-tls-f4.md`
- Supuestos: F4 se construye sobre F1 a F3 tal como los describe el blueprint `b5328331`; `--renovar-certificado` es del verbo `anillo`; las mutaciones se enuncian sobre responsabilidades porque el código no existe
- Decisiones candidatas a ADR: Ninguna (QF4-01 y QF4-02 podrían terminar como precisión de H-17 v2 y de N-7)
- Entregas a otros agentes: B (arquitecto-software) → responder D-F4-01, 02, 05, 06, 08, 12, 13 y 15 y decidir QF4-01 a QF4-03 antes del PR de F4; A (arquitecto-software) → umbral del anillo en `comprobar-servidor` y franja de EventId para el aviso; devops (T1-b) → rechazo de `PFX_CLIENTE` en el paquete (LABF-17)
- Próximo paso recomendado: B responde las 8 dudas bloqueantes y decide el orden de reescritura de QF4-01; después C escribe RC y AV con F1
