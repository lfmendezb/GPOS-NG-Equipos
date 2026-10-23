```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 4 de B-a-C/2026-10-23-tareas-nuevas-para-c-5: plan de pruebas del anillo DM-07)
Prioridad: Media
Repositorio y rama: GPOS-NG `origin/b/blueprint-tls-anillo` (`b5328331`, blueprint), `origin/master` (ADR-90, ADR-77, hoja de seguridad H-17 v2) y `origin/feature/modelo-ng` (código, solo lectura); área común
Estado: Abierto (15 dudas para B, sección 9; 4 bloquean casos)
```

# Plan de pruebas del anillo del servicio (DM-07; H-17 v2; blueprint de `tls` y anillo, F1)

**Qué es.** Plan para que B construya F1 del blueprint (`anillo --preparar`, el archivo `GPOS.Api.anillo.json`, las guardas G-1 y G-2 y la costura `IAlmacenMaquina`) con las pruebas en la mano: certificado propio no exportable en `LocalMachine\My`, su ACL, la recuperación (`--recuperacion`), la rotación, la falla cerrada y que `sistema --cuentas-iniciales` use **el mismo anillo que el servicio**. Tabla caso por caso con su mutación, niveles U/F/W/V, casos de laboratorio para `VM-SRV`, requisitos de testabilidad y dudas. Complementa (no repite) mi plan del verbo `tls` (`traspasos/C/2026-10-23-plan-pruebas-verbo-tls.md`): `tls` y anillo comparten `IAlmacenMaquina`, pero no se reutilizan llaves (RT-09).

**Método y límites.** Solo lectura: `git show` sobre `origin/b/blueprint-tls-anillo` (documento `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md`), `origin/master` (ADR-90 RT-09, ADR-77 punto 4, hoja de seguridad 3.1.2 = texto de H-17 v2, hoja PR-D2-1/1b) y `origin/feature/modelo-ng` `b9efa9fb` (código: `ComprobacionAnillo.cs`, `OrigenCertificadosAnillo.cs`, `ComandosAnillo.cs`, `ProteccionDatosInstalacion.cs`, `CarpetaAnillo.cs`, `AnilloPrueba.cs`, `Program.cs` de `GPOS.Migracion`). No compilé ni ejecuté nada, no toqué ningún árbol. **`anillo --preparar`, `ArchivoAnillo`, `IAlmacenMaquina`, G-1/G-2 y el evento 4729 no existen en ninguna rama** [V: `git grep` de `4729` y `4733` en `src` de `feature/modelo-ng`: sin resultados; `ComandosAnillo.cs` lista las acciones `anclar, migrar, revocar-heredadas, cambiar-recuperacion, reproteger-sellos, recuperar, comprobar`, sin `preparar`]. Por eso las mutaciones se enuncian sobre **responsabilidades**; B las convierte en `archivo:línea` al construir. Marcas: **[V]** leído en el texto o código citado; **[I]** inferido o conocimiento general de Windows, CNG o .NET, por confirmar con casos W/V; **[D]** depende de una duda de la sección 9.

**Fuentes.** Blueprint (secciones 3.1 a 3.5, 6, 7.1, 8 y 12); H-17 v2 (hoja de seguridad 3.1.2: ocho puntos, ancla D-3, `CifradorAnillo` con RSA-OAEP-SHA256 de 3072 bits); ADR-90 RT-09 (`ADR-090.md:100`: tres llaves que no se reutilizan); ADR-77 punto 4 (comprobación al arrancar, lectores de la carpeta del anillo, Release sin `DpapiMaquina`); `ComprobacionAnillo.cs:120-262` (carpeta, certificados, ancla, creación de llave); `OrigenCertificadosAnillo.cs:40-120` (búsqueda por SHA-256 en `LocalMachine\My`, recuperación solo pública, `ConPrivada` busca también en `CurrentUser`); `ProteccionDatosInstalacion.cs:51-85` (AN-05, PA-77-3); `AnilloPrueba.cs` (arnés existente). **La hoja de firma que cita el blueprint (`docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md`, P-1 a P-9) no está en `origin/b/blueprint-tls-anillo` ni en `origin/master`** [V: `git ls-tree`]: tomo como firmado lo que el blueprint declara firmado (P-1 a P-8 y F1), sin poder verificarlo (duda D-AN-01).

## 0. Resumen para decidir

1. **El contrato está bien repartido, con huecos concretos** (sección 9). Los que cambian el resultado esperado: qué hace `--preparar` si el archivo existe pero el certificado falta, venció o el propio archivo es inválido (D-AN-03); si la API debe negarse a arrancar con llaves restauradas de otro principal antes de `--recuperar` (D-AN-08, hoy `ComprobacionAnillo` crea una llave nueva en ese caso, QA-AN-01); y si hay exclusión mutua entre dos `--preparar` (D-AN-04, el blueprint la pone en `tls` y no en el anillo). Escribí los casos con el supuesto más probable y los marqué **[D]**.
2. **Lo más caro de equivocarse no se ve en "preparar y ver que el servicio arranca".** Seis defectos que pasan ese camino feliz: (a) la llave creada y **luego** protegida (ventana) o con `GENERIC_ALL` para la cuenta; (b) el descriptor comprobado con "contiene" en vez de "es exactamente"; (c) el certificado con llave efímera (se agrega a `My` pero la llave no es la persistida de la máquina) o exportable; (d) `GPOS.Migracion` que **no** lee el archivo, o lo lee y una variable del shell del técnico gana: `sistema --cuentas-iniciales` escribiría `Licencia.InstalacionId` con otro anillo y el servicio no lo descifraría (P-01 del spike); (e) el archivo del anillo que se ignora cuando es inválido (la semántica del archivo de instalación, `ArchivoInstalacion.cs:148-150`) y degrada a DPAPI; (f) la publicación del archivo antes de verificar la llave. Los casos ANI-L03, L04, A01, M01, M03, F03, F09 y O01 los matan.
3. **Cuatro niveles** (sección 2): U puro (suite oficial), F con falsos (suite oficial), W real en `LocalMachine` (solo VM) y V laboratorio en `VM-SRV`. Casi todo cae en U y F **si B entrega las costuras R-A1 a R-A8** (sección 8). Una de ellas es nueva y fácil de olvidar: **la suite corre en Debug**, y el comportamiento de Release (AN-05, rechazo de `DpapiMaquina`, "sin archivo no hay anillo") hoy solo se prueba dentro de `if (CompilacionDepuracion)` [V: `AnilloDataProtectionTests.cs:334,342,352`]. Sin una costura (R-A1) o sin ejecutar la suite en Release, ANI-F01 y ANI-X07 no prueban nada.
4. **Oráculo independiente.** Los casos de perfil decodifican con `AsnReader` y vectores fijos (propongo `docs/contratos/vectores/anillo-dm07.v1.json`, precedente `adr077-carpetas.v1.json`), **nunca con el constructor de `PrepararAnillo`**; el descriptor esperado se escribe a mano en SDDL en el vector.
5. **Mutaciones:** 77 en la sección 6, cada una con el caso que la mata. Como el código no existe, son la lista de comprobación del revisor cuando B abra el PR.
6. **Hallazgos de lectura** (QA-AN-01 a QA-AN-08, sección 7): ninguno Crítico ni Alto. El que merece decisión antes de construir es QA-AN-01 (Media: llaves restauradas de otro principal) y QA-AN-03 (Media: el orden de `Program.cs` está vigilado por `OrdenProgramaApiTests`).
7. **Esfuerzo [I, ±40 %]:** escribir las pruebas U/F/W unos **2,6 dp**; guiones del laboratorio 0,4 dp; ejecución en `VM-SRV` unas **10 h** en 4 sesiones. Plazos: U/F antes de que B abra el PR de F1 (revisión de seguridad del 2 al 3-nov); sesión de laboratorio 1 con la VM del 16-nov (ensayo de PR-D2 de A); el plan completo antes del 18-nov.

## 1. Lo que se prueba: el contrato (oráculo) y su origen

`Estado`: **F** = firmado (H-17 v2, ADR-77, ADR-90) o código existente [V]; **B** = blueprint de B (P-1 a P-8 firmadas según el propio blueprint, sin ver la hoja); **[D]** = abierto.

| # | Regla | Origen | Estado |
|---|---|---|---|
| K-01 | Certificado propio **autofirmado** por instalación de la API, en `LocalMachine\My`, ligado a una llave persistida de máquina; RSA de 3072 bits o más, `ExportPolicy = None`, proveedor de software (Básica) | DM-07; blueprint 3.1 pasos 6 y 8; H-17 v2 punto 2 | B |
| K-02 | Descriptor de la llave fijado **en la misma llamada** que la crea: dueño Administradores; DACL protegida con `GENERIC_ALL` para SYSTEM y Administradores y **solo `GENERIC_READ`** para `NT SERVICE\GPOS.Api`; "exactamente estas tres entradas" | blueprint 3.1 pasos 6 y 9 | B |
| K-03 | Perfil: v3, serie de 16 bytes aleatorios positiva, RSA con SHA-256 PKCS#1 v1.5, sujeto `CN=GPOS NG Anillo GPOS.Api <equipo> <AAAAMMDD>`, `basicConstraints` crítica `cA = false`, KU crítica solo `keyEncipherment`, EKU solo *Document Encryption* `1.3.6.1.4.1.311.80.1` (**sin `serverAuth` ni `clientAuth`**), `NotBefore` = ahora − 1 h, `NotAfter` = ahora + 5 años (P-4), `FriendlyName` `GPOS NG Anillo GPOS.Api` | blueprint 3.1 paso 7 y 8 | B |
| K-04 | `--recuperacion <.cer>`: un solo certificado, **sin privada**, RSA de 3072 bits o más (`CifradorAnillo.BitsMinimos`), vigente; se muestra su SHA-256; se copia a `config\GPOS.Api.recuperacion.cer` con escritura atómica y comparación del SHA-256 | blueprint 3.1 pasos 2 y 10; `CifradorAnillo.cs:70` [V] | B |
| K-05 | Orden obligatorio de los 12 pasos; la **publicación del archivo del anillo es el último paso antes de la comprobación final**; no toca el ancla (sin `--acta`) y no abre la base de datos | blueprint 3.1 | B |
| K-06 | Idempotencia: con archivo válido, certificado de esa huella con llave, descriptor exacto, RSA ≥ 3072, más de 180 días de vigencia y misma recuperación: no hace nada (0). Otra recuperación: **4**. Menos de 180 días: 0 con aviso | blueprint 3.1 paso 5 | B |
| K-07 | Archivo `config\GPOS.Api.anillo.json`: JSON estricto con exactamente 7 propiedades (`v`, `servicio`, `carpeta`, `certificadoServidor`, `certificadosServidorAnteriores`, `certificadoRecuperacion`, `identidadServicio`); se traduce a las 5 claves `GPOS:DataProtection:*` que ya existen | blueprint 3.2 | B |
| K-08 | Falla cerrada del archivo (6 reglas): ausente = comportamiento de hoy; presente e inválido, ajeno, en conflicto con otra fuente, o con `DpapiDemo`/`DpapiMaquina` = la API no arranca (evento **4729**); sin recarga | blueprint 3.2 | B |
| K-09 | `GPOS.Migracion` agrega **el mismo archivo con el mismo código** (`AgregarArchivoAnillo("GPOS.Api")` después de `AddEnvironmentVariables()`), así `sistema --cuentas-iniciales` usa el mismo certificado, carpeta e identidad | blueprint 3.2 y 3.3 | B |
| K-10 | G-1: con el servicio `GPOS.Api` instalado y el archivo ausente, ocho verbos (`sistema --cuentas-iniciales`, `--confirmar-sellado`, `sellos`, `empresa`, `login-servicio`, `credencial-app`, `restablecer-factor`, `anillo` salvo `--preparar`) salen con 4 | blueprint 3.3 | B |
| K-11 | G-2: `sistema --cuentas-iniciales` y `--confirmar-sellado` exigen ancla `Anclada`; si no, 4 con "ejecute `anillo --anclar --acta --motivo`" | blueprint 3.3 | B |
| K-12 | Recuperación: solo el `.cer` público en el servidor; la privada, fuera de línea, importada en `CurrentUser\My` de soporte solo durante `anillo --recuperar`; `--preparar` en un servidor con carpeta restaurada de otro principal crea certificado nuevo, publica el archivo, **no toca esas llaves** y sale con **2** | blueprint 3.4; H-17 v2 puntos 3 y 5 | B / F |
| K-13 | Rotación: las llaves del anillo se crean cada 90 días (existente); aviso a menos de 180 días del certificado; `--renovar-certificado` (reenvolver con el principal anterior, publicar, borrar el anterior tras `--comprobar`) es **F4**, no F1 | blueprint 3.5 | B |
| K-14 | Falla cerrada transversal: sin ancla, recuperación cambiada, carpeta no conforme, certificado no válido, Release sin anillo (AN-05) o con `DpapiMaquina` (PA-77-3): no se crean llaves o la API no arranca; nunca se cae a DPAPI | blueprint 6; `ComprobacionAnillo.cs`; `ProteccionDatosInstalacion.cs:60-79` [V] | F |
| K-15 | Códigos de salida de `anillo --preparar`: 0 hecho o ya estaba; 1 error, sin elevación o fuera de Windows; 2 recuperación pendiente; 4 guarda (raíz o `config` ajenas, cuenta virtual inexistente, otra recuperación) | blueprint 3.1 | B [D-AN-02] |
| K-16 | Solo Windows (H-L1/H-L2); ningún PFX ni PKCS#8 toca el disco (ADR-44); ningún secreto en archivos, argumentos, variables, eventos ni salida | blueprint 3.1 y 6; ADR-44 | F |
| K-17 | Eventos: reutiliza 4716 (`AnilloMantenimiento`); 4717 (`AnilloComprobado`) al arrancar; **4729** `AnilloConfiguracionNoConforme` (crítico) nuevo; 4733 sigue reservado a DB-7 | blueprint 4.7 y 5 | B |

## 2. Niveles de ejecución, reglas y qué se reutiliza

| Nivel | Qué es | Dónde corre | Atributo |
|---|---|---|---|
| **U** | Núcleo puro: constructor del certificado (`CertificateRequest`), constructor del descriptor SDDL, esquema y traducción del archivo, reglas de recuperación, con llaves en memoria y `TimeProvider` falso. Sin almacenes, ACL ni registro | Suite oficial, cualquier equipo | `[Fact]`, `[Trait("Esquema","Neutral")]` |
| **F** | `anillo --preparar`, el cargador y las guardas completos contra falsos de las costuras (`IAlmacenMaquina` en memoria, sistema de archivos, `IEstadoServicios`, `SistemaServidorFalso`, `DbContext` falso). Incluye el `CifradorAnillo` y `ComprobacionAnillo` **reales** con `AnilloPrueba` | Suite oficial | `[Fact]` neutral |
| **W** | `LocalMachine\My`, CNG, ACL y archivos **reales**. Escribe en la máquina | **Solo en la VM**, con las guardas del diseño v3 (7.1, LS-11) | `[FactLaboratorioAnillo]` (omite sin `GPOS_LAB_ANILLO=1`) |
| **V** | Laboratorio: producto publicado, servicios reales, `VM-SRV` de `LFMB`, una VM a la vez | Operado por B | Casos LABA-xx, sección 5 |

**Reglas.** (1) Un caso W corre en su propio proceso y deja el estado limpio antes y después (`Limpiar-Laboratorio.ps1`, marcador `O=GPOS-LAB-ANILLO` en el sujeto: `CN=GPOS NG Anillo GPOS.Api LAB-…`). (2) Sin `Thread.Sleep`: todo el tiempo por `TimeProvider`; **hoy `AnilloPrueba.Anclar` usa `DateTime.UtcNow`** [V: `AnilloPrueba.cs:90`] y `ComprobacionAnillo` recibe `ahora` como parámetro (bien); el verbo nuevo debe recibirlo igual. (3) Nada escribe un PFX ni una llave a disco (ADR-44); el par de recuperación de las pruebas es efímero, y el de laboratorio, desechable y con contraseña centinela falsa. (4) Un caso nunca se anota "Cumple" si su precondición no existía: `No se pudo`. (5) El oráculo no importa el código del verbo. (6) Carpetas: `tests/GPOS.Tests/Criptografia/Anillo/` (U/F, junto a las existentes) y `tests/GPOS.Tests/Laboratorio/Anillo/` (W). (7) **No corren a la vez la suite completa y el laboratorio** (CLAUDE.md).

**Reutilizable hoy** [V, `feature/modelo-ng`]: `AnilloPrueba` (carpeta temporal, certificados de 3072 bits en memoria, `Config(...)`, `Proceso(...)`, `Anclar(...)`), `OrigenPrueba`, `CertificadosPrueba.SoloPublica`, `AnilloDataProtectionTests`, `MantenimientoAnilloTests`, `ConformidadAnilloTests`, `CifradorAnilloTests`, `AnilloArquitecturaTests`, `AnilloFueraDeWindowsTests`, `AnilloWebTests`, `EventIdUnicosTests`, `OrdenProgramaApiTests` (ver QA-AN-03). **No sirve como oráculo del perfil**: `CertificadosPrueba.Crear` genera un certificado de prueba con otro perfil.

## 3. Bloques de casos

Columnas: **ID** · entrada · esperado · nivel · mutación que lo mata (MU-AN-xx, sección 6). "Mut." vacío = control o informativo. Los casos que ya cubren las pruebas existentes (llaves, ancla, cifrador) no se repiten: aquí se prueban las piezas nuevas y su empalme con las existentes.

### 3.1 Entradas y guardas de `anillo --preparar`

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-E01 | Plataforma distinta de Windows (`esWindows = false`) | Salida 1 con el mensaje de H-L1; 0 archivos, 0 certificados, 0 llaves | U, F | MU-AN-01 |
| ANI-E02 | Sin elevación (usuario estándar; administrador con token filtrado) | Salida 1 **antes** de tocar nada (ni almacén, ni carpeta, ni archivo); el falso registra 0 llamadas | F, V | MU-AN-02 |
| ANI-E03 | Sin `--recuperacion`; con la opción repetida; con una opción desconocida; con `--servicio web` (F4) o `--servicio xyz` | Error de uso con ayuda; nada creado; `web` dice "no disponible todavía" | U, F | MU-AN-03 |
| ANI-E04 | `.cer` válido: RSA 3072 y RSA 4096 | Aceptados; se muestra el SHA-256 (64 hex minúsculas, `HuellaCertificado.Sha256`) | U | |
| ANI-E05 | RSA 2048, RSA 3071, ECDSA P-256, ECDSA P-384, Ed25519 | Rechazo de todos, mensaje con los bits requeridos; nada creado. (ECDSA: la variante ECDH está reservada, `CifradorAnillo.cs:60-61` [V]; D-AN-09) | U | MU-AN-04 |
| ANI-E06 | Certificado con **llave privada** (PFX; cert de `My` con privada exportado como `.cer` es público, no cuenta) | Rechazo; el PFX ni siquiera se carga (`LoadCertificateFromFile` solo admite un certificado [I]); mensaje sin repetir la ruta completa ni bytes | U, F | MU-AN-05 |
| ANI-E07 | Vencido; `NotBefore` futuro; vence en 1 día; vence en 29 días | Vencido y futuro: rechazo. 1 y 29 días: aceptado con aviso, o rechazo [D-AN-10] | U | MU-AN-06 |
| ANI-E08 | Archivo inexistente, vacío, de 1 byte, DER truncado, basura, directorio, PKCS#7 con varios certificados, PEM con dos certificados, PEM de uno, DER de uno | Los seis primeros y los dos de varios certificados: rechazo con mensaje; PEM de uno y DER de uno: aceptan [I, el cargador admite ambos]. Nada creado en ningún caso | U, F | MU-AN-07 |
| ANI-E09 | Ruta: relativa, con `..`, UNC `\\srv\x\r.cer`, con flujo `r.cer:s`, nombre de dispositivo (`NUL`, `CON`), enlace simbólico o unión a otro archivo | Rechazo o aviso; **no** se sigue un punto de reanálisis; el verbo elevado no lee de una ruta que un no administrador controle sin avisar [D-AN-11] | F, W | MU-AN-08 |
| ANI-E10 | Recuperación **igual** a un certificado ya presente como principal (el `.cer` exportado del propio certificado del anillo en una segunda ejecución) | Rechazo: el destinatario de recuperación no puede ser el principal (anularía la custodia fuera de línea) | U | MU-AN-09 |
| ANI-E11 | La raíz `%ProgramData%\GPOS NG` o `config` no existen | Salida **4**, mensaje "ejecute la fase carpetas"; **no** las crea | F, W | MU-AN-10 |
| ANI-E12 | Raíz o `config` con: dueño un usuario estándar; ACE de escritura para `Users`, `Authenticated Users`, `Everyone` o la cuenta del servicio; punto de reanálisis; ya es un archivo | Salida 4 en cada una; no corrige ni escribe; ninguna llave creada | F, W | MU-AN-11 |
| ANI-E13 | `Api\anillo` no existe | Se crea con `CarpetaAnillo.Crear` (DACL protegida en una sola operación, ADR-77 punto 2) y se comprueba con `CarpetaAnillo.Comprobar` con la identidad `NT SERVICE\GPOS.Api`. El falso registra una sola llamada de creación con descriptor, ninguna de "proteger después" | F, W | MU-AN-12 |
| ANI-E14 | `Api\anillo` existe con escritor ajeno, lectores de más (`Authenticated Users` hereda de la raíz) o es unión | Salida 4; no corrige. Los lectores del anillo son solo SYSTEM, Administradores y la identidad del servicio (ADR-77 punto 4 [V]) | F, W | MU-AN-11 |
| ANI-E15 | La cuenta `NT SERVICE\GPOS.Api` no se resuelve (servicio no creado) | Salida 4 "ejecute antes la fase servicios"; **sin respaldo** a `Users`, `Everyone` ni al ejecutor; nada creado | F, W | MU-AN-13 |
| ANI-E16 | Sin cadena de conexión a la base del sistema, sin SQL Server, sin ancla | `--preparar` termina 0: no abre la base (K-05) | F | MU-AN-14 |
| ANI-E17 | Salida estándar y de error de una ejecución correcta y de cada fallo | Contiene el SHA-256 del principal y de la recuperación (para el acta) y el siguiente comando; **nunca** bytes de llave, `-----BEGIN`, rutas del contenedor de CNG ni cadenas base64 largas | F | MU-AN-15 |

### 3.2 Perfil del certificado (oráculo con `AsnReader`)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-C01 | Perfil completo decodificado con `AsnReader` en DER estricto | v3; serie ≥ 16 octetos, positiva, sin bit alto sin relleno; firma `sha256WithRSAEncryption` (PKCS#1 v1.5, que es una **firma**; la prohibición de H-17 v2 es del transporte, blueprint 3.1 paso 7); emisor = sujeto; SPKI RSA ≥ 3072; `basicConstraints` crítica con `cA = false` y sin `pathLen`; KU crítica solo `keyEncipherment`; EKU solo `1.3.6.1.4.1.311.80.1`; SKI; **conjunto exacto de extensiones** (sin SAN, CDP, AIA, políticas ni NC) | U | MU-AN-16 a MU-AN-21 |
| ANI-C02 | Sujeto | `CN=GPOS NG Anillo GPOS.Api <equipo> <AAAAMMDD>` con el `TimeProvider` falso; nombre de equipo de 15 caracteres, con guion y con mayúsculas; el CN no excede 64 caracteres; fecha en UTC [D-AN-12 sobre UTC o local] | U | MU-AN-22 |
| ANI-C03 | Vigencia con `FakeTimeProvider` en cuatro fechas (1 de enero, 29 de febrero de 2028, 31 de diciembre, medianoche UTC) | `NotBefore` = ahora − 1 h exacto; `NotAfter` = ahora + 5 años (mismo día; el 29-feb: 28-feb o 1-mar, sin excepción) [D-AN-12] | U | MU-AN-23 |
| ANI-C04 | Sin `serverAuth`, `clientAuth` ni `anyExtendedKeyUsage` | Confirmado en C01; además, el `SelectorCertificadoServidor` **real** de A, con `HuellaApi` apuntando a este certificado, no lo adopta (4748) | U, F | MU-AN-18 |
| ANI-C05 | 1000 emisiones con la misma llave | 1000 series distintas | U | MU-AN-24 |
| ANI-C06 | Huella | SHA-256 del DER en 64 hex **minúsculas** (la del anillo, `HuellaCertificado.Sha256`), no `Thumbprint` (SHA-1) ni mayúsculas (las de `tls` van en mayúsculas en el registro: no se mezclan) | U | MU-AN-25 |
| ANI-C07 | El certificado recién creado pasa `ComprobacionAnillo` con `ahora` real; y con el reloj del servidor atrasado 30 min, 70 min y 2 h | Pasa con 0 y 30 min (el `NotBefore` − 1 h absorbe); con 70 min y 2 h: `AnilloCertificadoNoValido` ("no está vigente"), no se crean llaves, el mensaje habla del reloj [I] | F | MU-AN-26 |
| ANI-C08 | Round trip con el cifrador real | `CifradorAnillo.Cifrar` para el principal nuevo y la recuperación; `Descifrar` con la privada del principal abre; con una privada ajena, no. (Paso 9 de 3.1) | F | |

### 3.3 Llave, ACL y no exportable

Oráculo: K-01 y K-02. El descriptor esperado se escribe a mano en SDDL en el vector (`O:BAD:P(A;;GA;;;SY)(A;;GA;;;BA)(A;;GR;;;<SID de NT SERVICE\GPOS.Api>)` [I: forma exacta]; el SID de una cuenta virtual de servicio se deriva del nombre y es el mismo tras reinstalar [I], ver LABA-18).

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-L01 | Parámetros de creación de la llave (el falso registra la llamada) | RSA, 3072 bits (no 2048 ni 4096 por descuido), *Microsoft Software Key Storage Provider*, indicador de máquina, `ExportPolicy = None`, `KeyUsage = Decryption \| Signing`, nombre `GPOS.Anillo.Api.<AAAAMMDDhhmmss>`, sin sobrescritura | F | MU-AN-27, MU-AN-28 |
| ANI-L02 | Descriptor en la **misma** llamada | El falso rechaza cualquier cambio de seguridad posterior a la creación y el verbo no lo intenta; el descriptor que recibe `Create` ya es el final | F | MU-AN-29 |
| ANI-L03 | Constructor del descriptor, función pura, contra el vector | Dueño Administradores; DACL protegida (sin herencia); exactamente 3 ACE de tipo permitir: SY `GA`, BA `GA`, servicio `GR`; ninguna otra (ni `CREATOR OWNER`, ni `Users`, `Authenticated Users`, `Everyone`, ni `NT SERVICE\GPOS.Web`); el servicio **no** tiene `WRITE_DAC`, `WRITE_OWNER` ni `DELETE` | U | MU-AN-30 a MU-AN-32 |
| ANI-L04 | Verificación del paso 9 con descriptores desviados: ACE extra de lectura para `Users`; servicio con `GA`; falta SY; dueño distinto de BA; DACL no protegida; ACE de la Web; orden de ACE cambiado | La verificación compara **igualdad exacta como conjunto** y falla en cada una de las seis primeras; el orden de ACE no importa (la última es control). Al fallar: no se publica, se retiran certificado y llave creados, salida ≠ 0 | F | MU-AN-33 |
| ANI-L05 | La llave es de máquina (`MachineKey`) y de software (Básica), no de usuario ni del TPM | En W: el contenedor está bajo `C:\ProgramData\Microsoft\Crypto\…` [I] y no en el perfil del ejecutor; el proveedor es el de software | W | MU-AN-34 |
| ANI-L06 | No exportable | `ExportPkcs8PrivateKey()`, `ExportParameters(true)`, `Export(Pfx)` y `certutil -exportPFX` fallan con `CryptographicException`/error de "no exportable" | F, W | MU-AN-27 |
| ANI-L07 | DACL real del archivo de llave (`icacls`) | Las entradas efectivas son SYSTEM, Administradores y el servicio con lectura; el SID de la Web no aparece | W, V | MU-AN-30 |
| ANI-L08 | Derechos efectivos del SID del servicio sobre su llave | Puede **usar** la llave (descifrar) y no puede borrarla, cambiar su ACL ni exportarla. Se evalúa el acceso efectivo teniendo en cuenta que el token de una cuenta virtual contiene `Everyone`, `Authenticated Users` y `Users` [I]: si el descriptor concediera algo a esos grupos, el servicio lo heredaría | W, V | MU-AN-31 |
| ANI-L09 | Dos ejecuciones en el mismo segundo (mismo nombre de contenedor) | Error limpio, sin dejar certificado ni llave huérfanos (QA-AN-05) | F | MU-AN-35 |
| ANI-L10 | Fallo al crear la llave (sin permiso, disco, KSP no disponible) | Salida ≠ 0; nada publicado; sin certificado | F | |

### 3.4 Almacén de certificados y secretos en disco

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-A01 | Certificado en `LocalMachine\My` | Presente una vez, `HasPrivateKey`, `FriendlyName` correcto; **ausente** de `CurrentUser\*`, `Root`, `CA`, `TrustedPeople`. Reabierto por SHA-256 desde **otro proceso**, `GetRSAPrivateKey()` abre la misma llave persistida y firma/descifra (W-AN-01) | W | MU-AN-36, MU-AN-37 |
| ANI-A02 | Certificado agregado con la llave **efímera** (copia en memoria sin enlace al contenedor) | El caso A01 con proceso nuevo falla: el certificado quedó sin su llave | W | MU-AN-36 |
| ANI-A03 | El certificado no se instala como de confianza | 0 certificados en `Root`/`TrustedPeople` con el sujeto del anillo | W | MU-AN-37 |
| ANI-A04 | Archivos creados por una ejecución (correcta y fallida) | Ningún `.pfx`, `.p12`, `.pem`, `.key` ni PKCS#8 en `%TEMP%`, `%ProgramData%\GPOS NG`, el directorio actual, `config` ni `Api\anillo`; se compara el árbol antes/después y se buscan `-----BEGIN` y la firma de PKCS#12 | W | MU-AN-38 |
| ANI-A05 | Paso 9, cada verificación falla por separado: no se reabre por SHA-256; `GetRSAPrivateKey()` nulo; `ExportPolicy` ≠ `None`; descriptor distinto; el sobre de prueba no abre | Cada una: no se publica nada (ni `.cer` en `config` ni archivo del anillo), se retiran certificado y llave, salida ≠ 0, evento | F | MU-AN-39 |
| ANI-A06 | `FriendlyName` y sujeto del laboratorio | El marcador `O=GPOS-LAB-ANILLO` (de las guardas) no aparece en producción | U | |

### 3.5 Orden, atomicidad e idempotencia

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-O01 | Secuencia de llamadas a las costuras de una ejecución correcta | Exactamente: elevación → plataforma → leer recuperación → comprobar raíz/`config`/`Api\anillo` → resolver cuenta → idempotencia → crear llave con descriptor → emitir → agregar a `My` → verificar (reabrir, descriptor, sobre) → copiar `.cer` a `config` → escribir archivo → comprobación final → evento 4716. Se afirma el **orden** | F | MU-AN-40 |
| ANI-O02 | Fallo inyectado en **cada** paso de O01 | Salida ≠ 0; el archivo anterior (si lo había) intacto byte a byte; sin más de un certificado/llave huérfano o retirados; una segunda ejecución converge (D-AN-03) | F | MU-AN-40, MU-AN-41 |
| ANI-O03 | Terminación del proceso entre agregar a `My` y escribir el archivo | La siguiente ejecución converge sin dos certificados vigentes del anillo ni dos contenedores `GPOS.Anillo.Api.*` [D-AN-03] | F, V | MU-AN-41 |
| ANI-O04 | Escritura atómica de `GPOS.Api.anillo.json` y de `GPOS.Api.recuperacion.cer` | Se escribe un temporal **dentro de `config`** y se reemplaza; muerte súbita a la mitad deja el archivo anterior entero; el temporal se limpia; no sigue enlaces; se compara el SHA-256 de lo escrito; el **dueño** del archivo resultante sigue siendo Administradores/SYSTEM tras el reemplazo (regla 3 del cargador) | F, W | MU-AN-42 |
| ANI-O05 | `config\GPOS.Api.recuperacion.cer` ya existe con otro contenido | Salida 4 ("para cambiarla, `anillo --cambiar-recuperacion`"); no se sobrescribe | F | MU-AN-43 |
| ANI-O06 | Segunda ejecución completa | Salida 0, "ya estaba"; diff vacío del estado observable (`My`, `config`, archivo con su fecha, `Api\anillo`, ACL); sin certificado ni contenedor nuevos | F, V | MU-AN-44 |
| ANI-O07 | Segunda ejecución con otra recuperación | Salida 4; nada cambia | F | MU-AN-43 |
| ANI-O08 | Reloj a 181, 180 y 179 días del vencimiento del certificado | 181 y 180: 0 sin aviso; 179: 0 con aviso que nombra `--renovar-certificado`; en ningún caso crea otro certificado | F | MU-AN-45 |
| ANI-O09 | Archivo presente y válido, pero el certificado **no está** en `My`, venció o no tiene privada | **[D-AN-03]**. Mientras no se decida: debe ser una salida ≠ 0 que no cree un segundo principal sin reenvolver las llaves | F | MU-AN-46 |
| ANI-O10 | Archivo presente pero inválido (esquema, `v` distinta) | **[D-AN-03]** Recomendación: salida 4 sin reemplazarlo (lo repara una acción explícita) | F | MU-AN-46 |
| ANI-O11 | Dos `--preparar` a la vez (dos hilos en F, dos procesos en W) | Una espera o aborta con mensaje; nunca dos certificados vigentes del anillo; al final el archivo apunta a un certificado que existe y se abre **[D-AN-04]** | F, W | MU-AN-47 |
| ANI-O12 | `--preparar` con carpeta `Api\anillo` ya con llaves conformes del principal actual | No las toca (hash de cada `key-*.xml` igual) | F | MU-AN-48 |

### 3.6 Archivo del anillo y su carga en la API

El cargador es `ArchivoAnillo` (Core). Todas las fallas son `InvalidOperationException` en `Configurar` con el evento 4729 y la API no arranca.

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-F01 | Archivo **ausente**, en cuatro modos: Debug; DEMO con `DpapiDemo=true`; Release sin indicador; Release con `DpapiMaquina=true` | Debug y DEMO como hoy; Release sin indicador: **no arranca** (AN-05); Release con `DpapiMaquina`: no arranca (PA-77-3). El archivo ausente nunca abre un camino a DPAPI en Release. En la suite (Debug) exige R-A1 | U | MU-AN-49 |
| ANI-F02 | Archivo válido | Se traduce a las 5 claves exactas (`Carpeta`, `Anillo:CertificadoServidor`, `:CertificadosServidorAnteriores` unidas por `;`, `:CertificadoRecuperacion`, `:IdentidadServicio`) con los valores del archivo; `Configurar` termina con el anillo con certificado (`AnilloDataProtection`); la lógica de `ProteccionDatosInstalacion` no cambia | U, F | MU-AN-50 |
| ANI-F03 | Esquema: propiedad de más; falta una; `v` = 2, `v` = "1" (cadena), `v` ausente; `servicio` = "GPOS.Web"; JSON con comentarios, coma final, BOM, UTF-16; propiedad repetida (dos `certificadoServidor`); mayúsculas en nombres de propiedad; raíz que es arreglo o `null` | Rechazo de cada una con 4729; **nunca se ignora el archivo entero** como hace el archivo de instalación | U | MU-AN-51 |
| ANI-F04 | `certificadoServidor`: 63 y 65 hex, mayúsculas, con `:` o espacios, no hexadecimal, vacío, `null`, número | Rechazo; mayúsculas según D-AN-13 | U | MU-AN-52 |
| ANI-F05 | `certificadosServidorAnteriores`: lista vacía (válida), una huella, tres, una inválida, repetida, igual a la actual | Válidas: vacía, una, tres. Inválida: rechazo. Repetida e igual a la actual: rechazo o se normaliza [D-AN-13] | U | MU-AN-52 |
| ANI-F06 | `carpeta` y `certificadoRecuperacion`: relativa, con `..`, UNC, `\\?\`, vacía, apunta fuera de `%ProgramData%\GPOS NG` | Relativa, `..`, UNC, vacía: rechazo. Fuera de `GPOS NG`: ADR-77 punto 4 dice que el anillo se comprueba en la ruta configurada, esté o no bajo `GPOS NG`; si se admite o no [D-AN-14] | U | MU-AN-53 |
| ANI-F07 | `identidadServicio` ≠ `NT SERVICE\GPOS.Api` | Rechazo (el cargador es del servicio `GPOS.Api`, K-07) [D-AN-14] | U | MU-AN-53 |
| ANI-F08 | Seguridad del archivo y de `config`: dueño un usuario estándar; ACE de escritura para otra cuenta (incluida `NT SERVICE\GPOS.Api`); punto de reanálisis en `config`; archivo con enlace simbólico o duro; lectura de `Authenticated Users` | Todas las primeras: rechazo; la lectura de `Authenticated Users`: **admitida** (nada ahí es secreto). Falso del lector de seguridad (R-A4) y W | F, W | MU-AN-54 |
| ANI-F09 | **Conflicto con otras fuentes**: para cada una de las 5 claves, un valor distinto en: variable de entorno, `appsettings.json`, `appsettings.Production.json`, línea de comandos, archivo de instalación `GPOS.Api.json`, `GPOS.Migracion.json`, `dotnet user-secrets` | Rechazo en las 35 combinaciones, con la clave y la fuente en el mensaje y **sin** valores. Mismo valor en la otra fuente: ¿acepta? [D-AN-05] | U | MU-AN-55 |
| ANI-F10 | `DpapiDemo` y `DpapiMaquina` en `true`, `True`, `1`, `yes` en cualquier fuente, con archivo presente | Rechazo (regla 5); `false` explícito: acepta | U | MU-AN-56 |
| ANI-F11 | Sin recarga: el archivo cambia con la API en marcha | El proveedor no registra `IChangeToken`; el anillo no cambia hasta reiniciar; ningún evento | F | MU-AN-57 |
| ANI-F12 | Cambio entre la comprobación de seguridad y la lectura (TOCTOU): el falso sustituye el archivo tras la comprobación | Se lee **una vez** desde el mismo identificador (mismo `handle`) o se rechaza; nunca se acepta un archivo comprobado distinto del leído | F | MU-AN-58 |
| ANI-F13 | Archivo de 1 KB, 64 KB, 10 MB y con anidamiento de 10 000 niveles | Hasta el tamaño razonable que fije B: acepta lo bien formado; lo demás: rechazo sin agotar memoria | U | |
| ANI-F14 | Evento 4729 | Nivel crítico, origen de la API, id único (`EventIdUnicosTests`), **sin** valores de configuración, huellas completas ni rutas fuera de la raíz; 4733 no usado | U | MU-AN-59 |
| ANI-F15 | Fuera de Windows con el archivo presente | El mensaje de H-L1 gana (no se lee el archivo) | U | MU-AN-01 |
| ANI-F16 | Orden de registro en la API | `AgregarArchivoAnillo` queda **después** de `AgregarArchivoInstalacion` y **antes** de `ProteccionDatos.Configurar` en `Program.cs`; `OrdenProgramaApiTests` actualizado (QA-AN-03) | U | MU-AN-60 |
| ANI-F17 | La Web (F4 aún no) con el archivo de la API presente | La Web no cambia de comportamiento; la Web no agrega la fuente (AR06) | F | |

### 3.7 `sistema --cuentas-iniciales` y los demás verbos usan el mismo anillo

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-M01 | Dos fábricas de configuración (la de `GPOS.Api` y `Programa.Main` de `GPOS.Migracion`) con el mismo archivo y entorno limpio | Las 5 claves `GPOS:DataProtection:*` tienen los mismos valores; `ProteccionDatosInstalacion.Configurar` en ambos produce el mismo certificado, carpeta e identidad | U | MU-AN-61 |
| ANI-M02 | `GPOS.Migracion`: `AgregarArchivoAnillo` va **después** de `AddEnvironmentVariables()` (`Program.cs:40` [V]) y antes de construir `config` | Orden verificado por prueba de arquitectura de texto (como `OrdenProgramaApiTests`) | U | MU-AN-61 |
| ANI-M03 | Variable `GPOS__DataProtection__Carpeta` (o `…Anillo__CertificadoServidor`) en el **shell del técnico** con otro valor; `GPOS.Migracion.json` con `DpapiDemo=true` | `sistema --cuentas-iniciales` y los otros verbos: salida ≠ 0 con la regla 4/5, **antes** de abrir la base. No se usa "el que gane" | F | MU-AN-55 |
| ANI-M04 | Escritura cruzada con el cifrador real: dos `ServiceProvider` (API y Migracion) sobre la misma carpeta y el mismo archivo; Migracion protege `Licencia.InstalacionId`/un secreto de prueba y la API lo descifra, y a la inversa | Se descifra en los dos sentidos; `CifradorAnillo.Destinatarios` de **cada** `key-*.xml` es (huella del archivo, huella anclada) | F | MU-AN-61 |
| ANI-M05 | Llaves creadas por `GPOS.Migracion` (administrador) | Heredan la DACL de `Api\anillo` (SYSTEM, Administradores, cuenta de la API, `SddlServicios.PlantillaComponente`); el servicio puede leerlas. Dueño y ACL del archivo `key-*.xml`: en W, `icacls` | F, W | MU-AN-62 |
| ANI-M06 | **G-1**, matriz de 9 verbos (los 8 de K-10 más `anillo --anclar`): servicio instalado + archivo ausente | Cada uno sale con 4 sin abrir la base, sin crear llaves y sin tocar `Api\anillo`. `anillo --preparar` **sí** corre | F | MU-AN-63 |
| ANI-M07 | G-1 con: servicio no instalado y archivo ausente; servicio instalado y archivo presente; `IEstadoServicios` lanza (SCM sin acceso) | Primero y segundo: sigue como hoy. Tercero: falla cerrada (4) [D-AN-06] | F | MU-AN-63 |
| ANI-M08 | **G-2**: ancla en `SinAncla`, `NoVerifica`, `RecuperacionCambiada` y `Anclada`, con `--cuentas-iniciales` y con `--confirmar-sellado` | Las tres primeras: 4 con "ejecute `anillo --anclar --acta --motivo`" y **0 escrituras** en `GPOS_SYSDATA`; la cuarta procede. `--cuentas-iniciales` sin `--confirmar-sellado`: ¿exige ancla? [D-AN-07] | F | MU-AN-64 |
| ANI-M09 | Tras un 4 de G-1 o G-2 | `Api\anillo` sin llaves nuevas; el falso de `DbContext` registra 0 comandos | F | MU-AN-64 |
| ANI-M10 | Cada verbo que obtiene el proveedor (`EmpresasSistema.Proveedor()`, `Program.cs:333-336` [V]) pasa por G-1 | Prueba de texto/reflexión: ninguna llamada a `ProteccionDatosInstalacion.Configurar` en `src/GPOS.Migracion` fuera de la guarda común (AR08) | U | MU-AN-63 |
| ANI-M11 | Orden de PR-D2 con `SistemaServidorFalso`: `carpetas` → `servicios` → `anillo --preparar` → `esquema` (`--login-api`, `actualizar --todas`, vistas `rpt`, `--anclar` si falta, `--cuentas-iniciales --confirmar-sellado`) → `lectura` | Se afirma el orden de las llamadas; sin `--recuperacion` y con el anillo no preparado, `implantar-servidor` falla **antes** de `actualizar --todas`. (La pieza es de A: lo que se prueba es el contrato) | F | MU-AN-65 |
| ANI-M12 | Técnico sin elevar (administrador con token filtrado) o usuario estándar ejecuta `sistema --cuentas-iniciales` | No puede abrir la privada (BA solo "deny-only" en el token filtrado [I]); mensaje claro "ejecute elevado"; no cae a DPAPI ni a otro certificado | F, V | MU-AN-66 |
| ANI-M13 | `ConPrivada(huella)` busca también en `CurrentUser\My` (`OrigenCertificadosAnillo.cs:103-107` [V]) | Solo se usa para el destinatario de recuperación durante `--recuperar`; un `Principal()` nunca se resuelve en `CurrentUser` | F | MU-AN-67 |
| ANI-M14 | Punta a punta (W-AN-03) | Tras el paso `esquema`, el servicio arranca, registra 4717 y `restablecer-factor` verifica `Licencia.InstalacionId` escrito por `GPOS.Migracion` | V | MU-AN-61 |

### 3.8 Recuperación (`--recuperacion` y `anillo --recuperar`)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-R01 | Solo el `.cer` entra al servidor | Después de `--preparar` no hay certificado con privada de recuperación en ningún almacén ni archivo; `config` solo tiene el `.cer`. Tras `--recuperar` (correcto o fallido) la privada importada en `CurrentUser\My` de soporte **no queda**, o el procedimiento exige borrarla y `--comprobar` lo verifica [D-AN-08b] | F, W, V | MU-AN-68 |
| ANI-R02 | Servidor nuevo: `Api\anillo` restaurada con llaves de **otro** principal, ancla restaurada, sin archivo | `--preparar` crea el certificado nuevo, publica el archivo y sale con **2** y el comando siguiente; el `SHA-256` de cada `key-*.xml` queda igual (no borra ni reenvuelve) | F, V | MU-AN-69 |
| ANI-R03 | La API arranca en ese estado (R02) **antes** de `--recuperar` | **[D-AN-08]** Hoy `ComprobacionAnillo` descarta las llaves "ajenas" con `AnilloRecuperacionCambiada` y, al no quedar una conforme y admitida, **crea una llave nueva** (`CreateNewKey`, QA-AN-01). Esperado: ninguna llave se borra; los secretos antiguos no se leen hasta `--recuperar`; tras `--recuperar` se leen todos | F | MU-AN-70 |
| ANI-R04 | `--recuperar` con la privada correcta | Todas las llaves conformes reenvueltas al principal nuevo y a la recuperación anclada; `NoRecuperables = 0`; los secretos y MAC siguen verificando (solo cambia la envoltura); segunda ejecución sin cambios; `--comprobar` 0 | F | MU-AN-71 |
| ANI-R05 | `--huella-recuperacion` equivocada; la del principal; la de otro `.cer`; en mayúsculas; PFX de otro certificado | Rechazo sin cambios; mayúsculas según la normalización de `HuellaCertificado.Normalizar` (existe) | F | |
| ANI-R06 | `--recuperar` sin ancla (SYSDATA no restaurada) o con ancla de otra recuperación | Rechazo (4); ninguna llave reenvuelta | F | MU-AN-72 |
| ANI-R07 | Servidor restaurado y `--preparar --recuperacion otro.cer` (distinto del anclado) | `--preparar` no consulta la base (K-05) y publica; **la API arranca con `AnilloRecuperacionCambiada`, sin crear llaves nuevas** (existente) y `anillo --comprobar` sale 1. Se afirma ese empalme [D-AN-15] | F | MU-AN-73 |
| ANI-R08 | Cambiar la recuperación sin acta | `--preparar --recuperacion otro.cer` (ya preparado): 4; solo `--cambiar-recuperacion` con acta | F | MU-AN-43 |
| ANI-R09 | Pérdida del certificado en el mismo servidor (borrado de `My`) con archivo y carpeta íntegros | **[D-AN-03]** Ver O09. El procedimiento documentado debe existir y estar probado en LABA-10 | F, V | MU-AN-46 |
| ANI-R10 | Procedimiento completo de 6 pasos (3.4 del blueprint) en la VM | LABA-10 | V | |

### 3.9 Rotación

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-T01 | Llaves cada 90 días con el archivo nuevo (regresión): reloj a +60, +88 y +91 días | A +88 (menos de 2 días de margen) se crea una llave nueva envuelta para (principal del archivo, recuperación anclada); la anterior sigue descifrando; a +91 la anterior expiró y sigue en la carpeta | F | MU-AN-74 |
| ANI-T02 | Aviso de 180 días en `anillo --comprobar` y en `comprobar-servidor` | Sin aviso con más de 180 días; aviso a 179; ¿cambia el código de salida de `--comprobar`? [D-AN-10b] | F | MU-AN-45 |
| ANI-T03 | Certificado vencido (reloj +5 años + 1 día) | `AnilloCertificadoNoValido`, no se crean llaves nuevas (hoy: `certificadosValidos = false`); lo ya cifrado **sigue descifrando**; el servicio no cae por el vencimiento sin aviso previo [D-AN-10c] | F | MU-AN-26 |
| ANI-T04 | Reloj atrasado/adelantado 10 min | Cero fallos (`NotBefore` − 1 h) | F | MU-AN-23 |
| ANI-T05 | `--renovar-certificado` (**F4, condicional**) | Cuando entre: crea el nuevo (pasos 6 a 9), reenvuelve cada llave abriéndola con la privada del principal **anterior**, publica el archivo con el anterior en `certificadosServidorAnteriores`, borra el anterior (certificado **y llave CNG**) solo cuando `--comprobar` cumple; exige servicios detenidos (ADR-79); interrupción tras el reenvoltorio y antes de publicar: el anterior sigue funcionando. No se escribe hasta que B fije el contrato | F, V | MU-AN-75 |
| ANI-T06 | Tres llaves de uso distinto no se reutilizan (RT-09) | El certificado del anillo no aparece en el selector TLS ni en `tls`; `tls` no importa `Anillo` ni al revés (AR02); la llave ES256 de los tokens no es la del anillo | U | |

### 3.10 Falla cerrada transversal

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-X01 | Matriz: archivo inválido → 4729 y no arranca; carpeta no conforme → `AnilloCarpetaNoConforme`, sin llaves (y en modo Estricto no arranca); certificado no válido → `AnilloCertificadoNoValido`, sin llaves; sin ancla → `AnilloSinAncla`; ancla que no verifica → `AnilloRecuperacionCambiada`; Release sin anillo → AN-05 | Cada fila: el efecto y el evento de la tabla; ninguna crea llave ni degrada. Las seis últimas ya existen [V]: se verifica el empalme con el archivo nuevo | F | MU-AN-76 |
| ANI-X02 | Búsqueda de `catch` que continúe | Prueba de texto: en `ProteccionDatosInstalacion`, `ArchivoAnillo` y `PrepararAnillo`, ningún `catch` que registre y siga con DPAPI | U | MU-AN-76 |
| ANI-X03 | Certificado borrado de `My` (servicio instalado, archivo presente) | La API no arranca ("no está en LocalMachine\My o su privada no es accesible", `OrigenCertificadosAnillo.cs:75-80` [V]); **no** regenera uno nuevo sola | F, V | MU-AN-77 |
| ANI-X04 | ACE del servicio quitada de la llave | La API no arranca con un error de acceso claro; restaurar la ACE recupera sin reiniciar el equipo | W, V | MU-AN-30 |
| ANI-X05 | Archivo borrado (servicio instalado, Release) | La API no arranca (AN-05) y **no** cae a DPAPI; `GPOS.Migracion` sale 4 (G-1) | F, V | MU-AN-49, MU-AN-63 |
| ANI-X06 | Carpeta `Api\anillo` con ACE de escritura de más o lectura de `Authenticated Users` | `AnilloCarpetaNoConforme`; no se crean llaves | F, W | MU-AN-11 |
| ANI-X07 | Release en la suite | Con R-A1 (o ejecutando la suite en Release, ver sección 8): `Configurar` sin archivo ni `DpapiDemo` lanza AN-05; con `DpapiMaquina` lanza PA-77-3 | U | MU-AN-49 |

### 3.11 Secretos (ADR-44)

| ID | Entrada | Esperado | Nivel | Mut. |
|---|---|---|---|---|
| ANI-S01 | Una ejecución correcta y cada fallo | stdout, stderr, eventos 4716/4729, el archivo y el `.cer`: sin bytes de llave, PKCS#8, `-----BEGIN PRIVATE` ni base64 de más de 64 caracteres seguidos | F, V | MU-AN-15 |
| ANI-S02 | Contenido de `GPOS.Api.anillo.json` | Solo huellas y rutas de las 7 propiedades fijas (ADR-44: nada sensible en texto plano) | U | MU-AN-51 |
| ANI-S03 | La privada de recuperación de las pruebas | Ningún caso la escribe a disco; en LABA se importa con contraseña centinela tecleada y se borra | V | MU-AN-68 |

### 3.12 Pruebas de arquitectura

| ID | Qué comprueba | Mut. |
|---|---|---|
| ANI-AR01 | Solo `AlmacenMaquinaWindows` usa `CngKey`, `X509Store` con escritura y `CertificateRequest`+`CopyWithPrivateKey`; ningún `Export(X509ContentType.Pfx/Pkcs12)`, `ExportPkcs8PrivateKey`, `X509KeyStorageFlags.Exportable`, ni `File.Write*` con material de llave en `src/GPOS.Migracion/Anillo` | MU-AN-27, MU-AN-38 |
| ANI-AR02 | `Anillo` no referencia `Tls` ni al revés | |
| ANI-AR03 | Ninguna llamada a `DateTime.Now/UtcNow` ni `DateTimeOffset.Now/UtcNow` en `PrepararAnillo` ni `ArchivoAnillo` (solo `TimeProvider`) | MU-AN-23 |
| ANI-AR04 | Los nombres de las 5 claves salen de constantes (`OrigenCertificadosAlmacen.ClaveServidor`, `ClaveRecuperacion`, `ClaveServidoresAnteriores`, `ProteccionDatosInstalacion.ClaveCarpeta`, `CarpetaAnillo.ClaveIdentidadServicio`) y no de literales repetidos | MU-AN-50 |
| ANI-AR05 | 4729 declarado como `public static readonly EventId` en `EventosAnillo`, único (`EventIdUnicosTests`) y fuera de 4733 | MU-AN-59 |
| ANI-AR06 | `GPOS.Web` compila `ArchivoAnillo` como vínculo y **no** agrega la fuente | |
| ANI-AR07 | `GPOS.Migracion` no referencia `GPOS.Api`; `ArchivoAnillo` en `GPOS.Core` sin dependencias de negocio | |
| ANI-AR08 | Una sola guarda G-1: toda llamada a `ProteccionDatosInstalacion.Configurar` o `EmpresasSistema.Proveedor()` en `src/GPOS.Migracion` pasa por ella | MU-AN-63 |

## 4. Trazabilidad con el blueprint (7.1) y con W-AN-xx

| Blueprint 7.1 (nombre de la prueba) | Aquí |
|---|---|
| `Preparar_crea_la_llave_no_exportable_con_el_descriptor_exacto_en_la_misma_llamada` | ANI-L01 a L04, L06 |
| `Preparar_sin_la_cuenta_del_servicio_sale_con_4_sin_crear_nada` | ANI-E15 |
| `Preparar_rechaza_un_cer_con_privada_RSA_menor_de_3072_o_vencido` | ANI-E05 a E08 |
| `Preparar_publica_el_archivo_como_ultimo_paso` | ANI-O01, O02 |
| `Preparar_dos_veces_no_cambia_nada` / `Preparar_con_otra_recuperacion_sale_con_4` | ANI-O06, O07 |
| `Preparar_con_llaves_de_otro_principal_termina_con_2_y_no_las_toca` | ANI-R02, O12 |
| `El_certificado_del_anillo_no_tiene_serverAuth_ni_es_CA` | ANI-C01, C04 |
| `Archivo_anillo_inexistente_deja_el_comportamiento_de_hoy` | ANI-F01 (con R-A1) |
| `Archivo_anillo_invalido_o_con_propiedad_de_mas_no_arranca_con_4729` | ANI-F03, F14 |
| `Archivo_anillo_con_DACL_ajena_o_reanalisis_no_arranca` | ANI-F08 |
| `Archivo_anillo_y_variable_con_otro_valor_no_arranca` | ANI-F09 (35 combinaciones, no una) |
| `Archivo_anillo_con_DpapiDemo_no_arranca` | ANI-F10 (más `DpapiMaquina` y las variantes) |
| `Migracion_y_Api_leen_las_mismas_claves_del_anillo` | ANI-M01, M02, M04 |
| `Con_el_servicio_instalado_y_sin_archivo_cuentas_iniciales_sale_con_4` (G-1) | ANI-M06, M07 |
| `Cuentas_iniciales_sin_ancla_sale_con_4` (G-2) | ANI-M08, M09 |
| Arquitectura: `Solo_AlmacenMaquinaWindows…` y `Tls_y_Anillo_no_se_referencian` | ANI-AR01, AR02 |
| W-AN-01 (enlace certificado-llave; `certutil -exportPFX` falla) | ANI-A01, A02, L06; LABA-01, LABA-02 |
| W-AN-02 (`icacls` del contenedor) | ANI-L05, L07, L08; LABA-03 |
| W-AN-03 (punta a punta) | ANI-M14; LABA-06 |
| W-AN-04 (recuperación en punto de control limpio) | ANI-R10; LABA-10 |
| W-AN-05 (servicio con archivo alterado no arranca, 4729) | ANI-F03, F08, F09; LABA-07 |

**Lo que el blueprint no tiene y este plan agrega:** idempotencia con archivo roto o certificado ausente (O09, O10), exclusión mutua (O11), conflicto con las 7 fuentes (F09, 35 combinaciones), TOCTOU (F12), `DpapiMaquina` y variantes de `true` (F10), recuperación igual al principal (E10), llaves ajenas y arranque antes de `--recuperar` (R03), reloj atrasado y vencimiento (C07, T03), Release en la suite (X07), la guarda G-1 como regla de código único (M10, AR08), nombre de llave repetido (L09).

## 5. Casos de laboratorio en `VM-SRV` (VirtualBox, `LFMB`)

**Reglas heredadas** (mis planes de T1-b y del verbo `tls`): solo en `VM-SRV`, desde el punto de control `base`; una VM a la vez; un punto de control por bloque (`Puntos-Control.ps1 -Accion Tomar -Nombre LABA-<ID>` y, al terminar, `Restaurar -Nombre base -Apagar`); `Preparar-Vm.ps1` ya existe y crea el marcador de las guardas [V, plan de `tls`]; ningún agente ejecuta esto, lo opera B; si algo falla no se corrige a mano, se anota y se restaura; cada `msiexec` con `/l*v`; **ningún secreto en la evidencia**: contraseña centinela falsa y visible (`CLAVE-DE-LABORATORIO-NO-SECRETA-…`), nunca `reg export` de claves de servicio ni copia del contenido de un archivo de llave, `Probar-Redaccion.ps1` sobre toda la evidencia antes de copiarla fuera.

**Precondiciones** (si falta una, el caso es `No se pudo`, nunca `Cumple`): F1 publicado (`GPOS.Migracion.exe` con `anillo --preparar`); `GPOS.Api.msi` instalado o la fase `servicios` ejecutada (existe `NT SERVICE\GPOS.Api`); la fase `carpetas` (raíz protegida y `config`); un **par de recuperación desechable** generado en la VM con el arnés (P-2 del blueprint: se pierde al revertir; no sirve para un cliente); SQL Server Express solo para LABA-04 a LABA-09, LABA-17 y LABA-18 (el resto va sin SQL para ahorrar memoria).

**Función de apoyo** (PowerShell elevado; solo lectura):

```powershell
$E = 'C:\GPOS-LAB\evidencia'
function EstadoAnillo([string]$id){      # estado observable, sin llaves ni contraseñas
  $d = New-Item -ItemType Directory -Force "$E\$id"
  foreach($s in 'My','Root','CA','TrustedPeople'){ Get-ChildItem "Cert:\LocalMachine\$s" | Where-Object { $_.Subject -match 'GPOS NG Anillo' -or $_.FriendlyName -match 'GPOS NG Anillo' } |
     Select-Object Subject,NotBefore,NotAfter,HasPrivateKey,FriendlyName,@{n='Sha256';e={[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($_.RawData)).Replace('-','').ToLower()}},
       @{n='Eku';e={($_.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }).EnhancedKeyUsages.Value -join ';'}} |
     Export-Csv "$d\almacen-$s.csv" -NoTypeInformation }
  Get-ChildItem 'Cert:\CurrentUser\My' | Select-Object Subject,HasPrivateKey | Export-Csv "$d\currentuser-my.csv" -NoTypeInformation   # la privada de recuperación no debe quedar aquí
  icacls 'C:\ProgramData\GPOS NG\config'            2>&1 | Out-File "$d\acl-config.txt"
  icacls 'C:\ProgramData\GPOS NG\Api\anillo'        2>&1 | Out-File "$d\acl-anillo.txt"
  Get-ChildItem 'C:\ProgramData\GPOS NG\config','C:\ProgramData\GPOS NG\Api\anillo' -Force | Select-Object FullName,Length,LastWriteTimeUtc,@{n='Sha256';e={(Get-FileHash $_.FullName -Algorithm SHA256).Hash}} | Export-Csv "$d\archivos.csv" -NoTypeInformation
  Get-Content 'C:\ProgramData\GPOS NG\config\GPOS.Api.anillo.json' -ErrorAction SilentlyContinue | Out-File "$d\anillo.json"    # solo huellas y rutas (ANI-S02)
  Get-WinEvent -FilterHashtable @{LogName='Application';Id=4716,4717,4729} -MaxEvents 50 -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,LevelDisplayName | Export-Csv "$d\eventos.csv" -NoTypeInformation
}
```

| ID | Caso | Cómo | Esperado | Evidencia | Mapea | Marca |
|---|---|---|---|---|---|---|
| LABA-01 | Preparar, camino feliz | `EstadoAnillo` antes; `GPOS.Migracion anillo --preparar --recuperacion C:\GPOS-LAB\rec.cer`; `EstadoAnillo` después; sacar el DER público del certificado y decodificarlo con el `AsnReader` del arnés | Salida 0; un certificado en `My` con `HasPrivateKey`; EKU solo `1.3.6.1.4.1.311.80.1`; sin `serverAuth`; vigencia 5 años; archivo del anillo con las 7 propiedades; `.cer` de recuperación en `config` con el mismo SHA-256; 4716 | `EstadoAnillo`, volcado de `certutil -dump` (sin llaves) | W-AN-01; ANI-C01, A01, K-05 | [V] procedimiento; [I] volcados |
| LABA-02 | No exportable | `certutil -exportPFX -p x My <sha1> C:\x.pfx`; `Export-PfxCertificate`; script .NET con `ExportPkcs8PrivateKey` y `ExportParameters(true)`; comprobar que no apareció ningún archivo | Todos fallan; ningún `.pfx`/`.p12`/`.pem` en `C:\`, `%TEMP%` ni `ProgramData` | Salidas, listado de archivos | W-AN-01; ANI-L06, A04 | |
| LABA-03 | ACL real de la llave | `certutil -store -v My <sha1>` para hallar el contenedor; `icacls` sobre el archivo de llave (bajo `C:\ProgramData\Microsoft\Crypto\…`) sin copiar el contenido; cálculo de derechos efectivos del SID de `NT SERVICE\GPOS.Api` (con sus grupos implícitos) | SYSTEM y Administradores control total; el servicio solo lectura; sin `Users`, `Authenticated Users`, `Everyone` ni la Web; el servicio sin `WRITE_DAC`/`DELETE` | Salida de `icacls` | W-AN-02; ANI-L07, L08 | [I] ruta exacta del contenedor |
| LABA-04 | El servicio usa la llave | Iniciar `GPOS.Api` (con SQL y el `esquema` hecho); mirar 4717 y una operación que descifre una cadena de conexión de empresa | Arranca sin errores del anillo; 4717 con la huella del archivo; las empresas se abren | Visor, sonda | ANI-M14 | |
| LABA-05 | Falla cerrada por ACL | `icacls <llave> /remove "NT SERVICE\GPOS.Api"`; reiniciar el servicio; restaurar el ACE y reiniciar | Con la ACE quitada: no arranca, error de acceso a la llave, sin 4717, **sin llaves nuevas en `Api\anillo`**; restaurada: arranca sin reiniciar el equipo | Visor, `archivos.csv` antes/después | ANI-X04 | Se modifica la ACL a mano en el laboratorio, con punto de control |
| LABA-06 | Cuentas iniciales con el mismo anillo | Ejecutar los pasos de `esquema` de PR-D2 con el anillo preparado (`--anclar` + `sistema --cuentas-iniciales --confirmar-sellado`); iniciar `GPOS.Api`; `restablecer-factor` | El servicio descifra lo que escribió `GPOS.Migracion`; las llaves nuevas en `Api\anillo` tienen la ACL heredada con el servicio; `Licencia.InstalacionId` verifica | `archivos.csv`, `acl-anillo.txt` | W-AN-03; ANI-M01, M04, M05, M14 | |
| LABA-07 | Archivo alterado | Cinco alteraciones, una por vez con restauración: (1) JSON inválido; (2) una propiedad de más; (3) huella de otro certificado; (4) escritura para `Users` en el archivo (`icacls /grant Users:(W)`); (5) `GPOS__DataProtection__Carpeta` en el `Environment` del servicio con otro valor (`reg add HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api /v Environment`); y (6) un archivo con `DpapiDemo=true` en el entorno | En cada una la API no arranca, 4729 en el Visor sin valores, **sin llaves nuevas** y sin caída a DPAPI | Visor, `archivos.csv` | W-AN-05; ANI-F03, F08, F09, F10 | La (5) es la que A descartó por escribir el entorno: aquí solo prueba el conflicto |
| LABA-08 | Guarda G-1 | Mover el archivo fuera de `config`; `sistema --cuentas-iniciales ...`, `sellos`, `restablecer-factor`; luego restaurar el archivo | Cada verbo sale con 4 sin abrir la base ni tocar `Api\anillo`; restaurado: procede | Salidas, `archivos.csv` | ANI-M06 | |
| LABA-09 | Guarda G-2 | Sin ancla en `GPOS_SYSDATA`, `sistema --cuentas-iniciales --confirmar-sellado` | 4 con el comando de `--anclar`; 0 escrituras en SYSDATA | Salida, consulta de recuento de filas | ANI-M08, M09 | |
| LABA-10 | Recuperación completa | Punto de control limpio. Respaldar `Api\anillo`, `GPOS_SYSDATA`, `rec.cer`. Restaurar la VM a `base` (sin certificado). Restaurar los tres respaldos. `--preparar --recuperacion rec.cer` (esperar **2**). Importar el PFX desechable en `CurrentUser\My` de la cuenta de soporte (contraseña centinela **tecleada**). `anillo --recuperar --huella-recuperacion <sha256> --acta --motivo`. Borrar el PFX. `anillo --comprobar`. Iniciar la API | Salida 2 con el comando; las llaves restauradas no cambian de SHA-256 hasta `--recuperar`; después `NoRecuperables = 0`, `--comprobar` 0, la API arranca y las empresas se abren; **ninguna privada de recuperación queda en ningún almacén**; la contraseña no aparece en ningún canal | `EstadoAnillo` en cada paso, hashes de `key-*.xml` | W-AN-04; ANI-R01 a R04, R10 | La contraseña se teclea a mano |
| LABA-11 | Recuperación bloqueada | Con el estado de LABA-10: `--recuperar` con una huella equivocada; con el PFX de otro certificado; `--preparar --recuperacion otro.cer` | Rechazos sin cambios; el segundo caso termina con `AnilloRecuperacionCambiada` al arrancar la API y sin llaves nuevas | Visor, `archivos.csv` | ANI-R05, R07, R08 | |
| LABA-12 | Rotación de las llaves a 90 días | Puntos de control `T0` y `T0+88d` (reloj de la VM; licencia de laboratorio válida hasta `T0+120d`, LS-15); reiniciar la API en `T0+88d` | Aparece un `key-*.xml` nuevo; sus destinatarios son (principal del archivo, recuperación anclada); la anterior sigue; los secretos antiguos descifran | `archivos.csv`, `CifradorAnillo.Destinatarios` por llave (herramienta del arnés, sin contenido) | ANI-T01 | |
| LABA-13 | Idempotencia y diff | Ejecutar `--preparar` dos veces; `EstadoAnillo` antes y después | Salida 0 y diff vacío en la segunda; la huella no cambia | `diff` de `EstadoAnillo` | ANI-O06 | |
| LABA-14 | Sin privilegios | `--preparar` como usuario estándar (`runas /user:%COMPUTERNAME%\gpos-lab-usuario`) y como administrador sin elevar; `sistema --cuentas-iniciales` sin elevar | Rechazo antes de tocar nada (E02); el administrador sin elevar no abre la privada (M12), mensaje claro | Salidas, `EstadoAnillo` idéntico | ANI-E02, M12 | |
| LABA-15 | Muerte súbita | 30 veces: lanzar `--preparar` y `Stop-Process -Force` tras un retardo aleatorio de 0 a 2 s; después una ejecución normal; contar certificados y contenedores `GPOS.Anillo.Api.*` | Tras la ejecución normal el archivo apunta a un certificado que existe y se abre; no hay más de un huérfano (o ninguno) [D-AN-03]; el archivo y el `.cer` siempre enteros | `EstadoAnillo` por iteración (solo huellas) | ANI-O03, O04 | No necesita ganchos en el código de producción |
| LABA-16 | Reinicio del equipo | Reiniciar `VM-SRV` | La API arranca sola con el mismo certificado; 4717; el archivo y la llave no cambian | Visor | ANI-A01 | |
| LABA-17 | Reinstalar y actualizar el MSI de la API | Desinstalar `GPOS.Api.msi` y volver a instalar; luego actualizar a una versión posterior (tarea 3) | La desinstalación no borra certificado, llave, archivo ni carpeta del anillo; tras reinstalar, la cuenta virtual recupera el acceso (mismo SID derivado del nombre [I]) y la API arranca sin `--preparar` | `EstadoAnillo`, `icacls` antes/después | ANI-L03 (SID estable); D-AN-11b | [D-AN-11b] |
| LABA-18 | Sin salida de red | Con la VM sin NAT (como todos los casos), correr `--preparar` y arrancar la API | Ningún intento de DNS, descarga de CRL/OCSP ni conexión (el certificado es autofirmado y no usa cadena) | Contador de interfaz o `pktmon` | ANI-C01 | |
| LABA-19 | Linux | En `VM-LNX`, si se publica allí: `anillo --preparar` y arrancar la API con el archivo | "Fuera de Windows" (H-L1), salida ≠ 0, 0 archivos | Salida | ANI-E01, F15 | Solo si se publica |
| LABA-20 | Rotación del certificado (**F4**) | Condicional a ANI-T05 | Según T05 | | K-13 | Condicional |

**Reparto por sesión y duración [I, ±50 %, a refinar con la primera ejecución].**

| Sesión | Bloque | VM | Casos | Horas |
|---|---|---|---|---|
| 1 | Certificado, llave y ACL (sin SQL) | `VM-SRV` sola (3 a 3,5 GB) | LABA-01, 02, 03, 13, 14, 15, 18 | 3,0 |
| 2 | Servicio real y guardas (con SQL Express) | `VM-SRV` | LABA-04, 05, 06, 07, 08, 09, 16, 17 | 3,5 |
| 3 | Recuperación | `VM-SRV` | LABA-10, 11 | 2,0 |
| 4 | Reloj | `VM-SRV`; puntos de control a `T0+88d` | LABA-12 | 1,5 |

Total unas 10 h. **La sesión 1 es lo mínimo para el ensayo de PR-D2 del 16-nov** (certificado, llave y ACL); las sesiones 2 y 3 dependen de que A haya escrito el paso `anillo --preparar` en `FaseEsquema` (5 al 9-nov, blueprint sección 8).

## 6. Mutaciones que el plan debe matar

El código no existe; cada fila es una **responsabilidad** de F1. B la convierte en `archivo:línea` al abrir el PR. Procedimiento (el de S168-08/P168-14): aplicar la mutación a una copia, correr los casos de la columna "Lo mata" y registrar cuál falla; una mutación que sobrevive es un caso que falta.

| ID | Responsabilidad | Mutación | Lo mata |
|---|---|---|---|
| MU-AN-01 | Plataforma | Fuera de Windows crear algo o fallar sin el mensaje de H-L1 | ANI-E01, F15 |
| MU-AN-02 | Elevación | Comprobarla después de tocar algo, o no comprobarla | ANI-E02; LABA-14 |
| MU-AN-03 | Argumentos | Aceptar `--servicio web` en F1 o ignorar una opción desconocida | ANI-E03 |
| MU-AN-04 | Recuperación | Bits mínimos 2048 en vez de 3072, o aceptar ECDSA | ANI-E05 |
| MU-AN-05 | Recuperación | Aceptar un certificado con privada (cargar PFX) | ANI-E06 |
| MU-AN-06 | Recuperación | No comprobar vigencia (`NotBefore`/`NotAfter`) | ANI-E07 |
| MU-AN-07 | Recuperación | Tomar el primero de un PKCS#7 o de un PEM con varios | ANI-E08 |
| MU-AN-08 | Recuperación | Seguir un punto de reanálisis o aceptar ruta UNC/relativa sin aviso | ANI-E09 |
| MU-AN-09 | Recuperación | Aceptar como recuperación el `.cer` del propio principal | ANI-E10 |
| MU-AN-10 | Carpetas | Crear la raíz o `config` si faltan | ANI-E11 |
| MU-AN-11 | Carpetas | No comprobar dueño, escritores, lectores ni reanálisis; o "corregir" en vez de parar | ANI-E12, E14, X06 |
| MU-AN-12 | `Api\anillo` | Crear y después proteger (dos pasos) | ANI-E13 |
| MU-AN-13 | Cuenta | Respaldo a `Users`/`Everyone`/ejecutor si el SID no se resuelve | ANI-E15 |
| MU-AN-14 | Base de datos | `--preparar` abre `GPOS_SYSDATA` o exige ancla | ANI-E16 |
| MU-AN-15 | Salida | Imprimir ruta del contenedor, bytes o base64 de llave | ANI-E17, S01 |
| MU-AN-16 | Perfil | `basicConstraints` con `cA = true` o con `pathLen` | ANI-C01 |
| MU-AN-17 | Perfil | `basicConstraints` o KU no críticas; KU con `digitalSignature` o `keyCertSign` | ANI-C01 |
| MU-AN-18 | Perfil | EKU con `serverAuth`, `clientAuth` o `anyExtendedKeyUsage` | ANI-C01, C04 |
| MU-AN-19 | Perfil | Sin el EKU *Document Encryption* | ANI-C01 |
| MU-AN-20 | Perfil | Extensiones de más (SAN, AIA, CDP) | ANI-C01 |
| MU-AN-21 | Perfil | Firma ECDSA o PSS en lugar de RSA-SHA256 PKCS#1 v1.5; llave de 2048 | ANI-C01 |
| MU-AN-22 | Sujeto | Sin equipo o sin fecha; CN de más de 64 caracteres | ANI-C02 |
| MU-AN-23 | Vigencia | `NotBefore` = ahora (sin − 1 h); 1 o 10 años en vez de 5; reloj del sistema directo | ANI-C03, T04, AR03 |
| MU-AN-24 | Serie | Fija, corta o con bit alto sin relleno | ANI-C05 |
| MU-AN-25 | Huella | SHA-1, mayúsculas o hash del SPKI | ANI-C06 |
| MU-AN-26 | Vigencia | No comprobar `NotBefore`/`NotAfter` en la verificación del paso 9, o permitir crear llaves con el certificado vencido | ANI-C07, T03 |
| MU-AN-27 | Exportabilidad | `ExportPolicy` distinta de `None` o llave exportable | ANI-L01, L06; AR01 |
| MU-AN-28 | Llave | Tamaño o proveedor distinto del de K-01; `KeyUsage` solo `Signing` | ANI-L01 |
| MU-AN-29 | Descriptor | Fijarlo después de crear la llave | ANI-L02 |
| MU-AN-30 | Descriptor | Dar a `Users`, `Authenticated Users` o `Everyone`, o dejar `CREATOR OWNER` | ANI-L03, L07; X04 |
| MU-AN-31 | Descriptor | `GENERIC_ALL`, `WRITE_DAC` o `DELETE` al servicio | ANI-L03, L08 |
| MU-AN-32 | Descriptor | Dar también al servicio de la Web (`GPOS.Web`) | ANI-L03 |
| MU-AN-33 | Verificación | Comprobar "contiene" las tres entradas en vez de "exactamente"; comparar texto SDDL con orden | ANI-L04 |
| MU-AN-34 | Llave | Guardarla en el almacén del usuario | ANI-L05 |
| MU-AN-35 | Nombre de llave | Reutilizar el nombre (sobrescribir) o dejar huérfano al chocar | ANI-L09 |
| MU-AN-36 | Almacén | `CopyWithPrivateKey` con llave efímera: el certificado queda sin enlace persistente | ANI-A01, A02 |
| MU-AN-37 | Almacén | Agregar a `CurrentUser` o a `Root`/`TrustedPeople` | ANI-A01, A03 |
| MU-AN-38 | Disco | Un PFX/PKCS#8 temporal | ANI-A04; AR01 |
| MU-AN-39 | Verificación | Omitir una verificación del paso 9 o no limpiar al fallar | ANI-A05, O02 |
| MU-AN-40 | Orden | Publicar el archivo antes del paso 9 o antes de copiar el `.cer` | ANI-O01, O02 |
| MU-AN-41 | Convergencia | No limpiar huérfanos tras un fallo; crear otro certificado al reintentar | ANI-O02, O03; LABA-15 |
| MU-AN-42 | Escritura | Archivo no atómico; temporal fuera de `config`; seguir enlaces; dueño del reemplazo cambia | ANI-O04 |
| MU-AN-43 | Recuperación | Sobrescribir el `.cer` existente o cambiar la recuperación sin acta | ANI-O05, O07, R08 |
| MU-AN-44 | Idempotencia | Regenerar el certificado si ya existe y es válido | ANI-O06 |
| MU-AN-45 | Aviso de 180 días | Umbral de 90 o 365; crear otro certificado al avisar | ANI-O08, T02 |
| MU-AN-46 | Archivo roto o certificado ausente | Crear un segundo principal sin reenvolver las llaves | ANI-O09, O10, R09 |
| MU-AN-47 | Concurrencia | Sin exclusión mutua | ANI-O11 |
| MU-AN-48 | Carpeta | Tocar, borrar o reenvolver llaves existentes | ANI-O12, R02 |
| MU-AN-49 | Archivo ausente | Caer a DPAPI en Release o dejar `DpapiDemo` implícito | ANI-F01, X05, X07 |
| MU-AN-50 | Traducción | Perder `:CertificadosServidorAnteriores` o usar `,` en lugar de `;`; literales de clave distintos de las constantes | ANI-F02; AR04 |
| MU-AN-51 | Esquema | Ignorar propiedades de más, comentarios o duplicadas; tratar el error como el archivo de instalación (ignorar el archivo) | ANI-F03, S02 |
| MU-AN-52 | Huellas | No validar longitud, hex o duplicados | ANI-F04, F05 |
| MU-AN-53 | Rutas | Aceptar relativa, `..`, UNC o `identidadServicio` ajena | ANI-F06, F07 |
| MU-AN-54 | Seguridad del archivo | No comprobar dueño, escritura de otras cuentas o reanálisis; o prohibir la lectura de `Authenticated Users` | ANI-F08 |
| MU-AN-55 | Conflicto | Gana la variable de entorno; o el conflicto solo se detecta contra algunas fuentes | ANI-F09, M03 |
| MU-AN-56 | `DpapiDemo`/`DpapiMaquina` | Solo reconocer `true` en minúsculas | ANI-F10 |
| MU-AN-57 | Recarga | `ReloadOnChange = true` | ANI-F11 |
| MU-AN-58 | TOCTOU | Abrir el archivo dos veces (comprobar y luego leer) | ANI-F12 |
| MU-AN-59 | Evento | 4729 repetido, otro nivel, con valores de configuración o 4733 usado | ANI-F14; AR05 |
| MU-AN-60 | Orden en `Program.cs` | La fuente antes de `AgregarArchivoInstalacion` o después de `ProteccionDatos.Configurar` | ANI-F16 |
| MU-AN-61 | Migracion | `GPOS.Migracion` no agrega el archivo, lo agrega antes de las variables, o con otro nombre de servicio | ANI-M01, M02, M04, M14 |
| MU-AN-62 | Llaves del técnico | Crear las llaves con la DACL del técnico en vez de la heredada | ANI-M05 |
| MU-AN-63 | G-1 | Sin la guarda, o con una lista de verbos incompleta, o `anillo --preparar` también bloqueado | ANI-M06, M07, M10, AR08, X05 |
| MU-AN-64 | G-2 | Sin la guarda, o escribir en la base antes de comprobar | ANI-M08, M09 |
| MU-AN-65 | PR-D2 | Preparar el anillo después de `esquema` | ANI-M11 |
| MU-AN-66 | Elevación de Migracion | Caer a DPAPI o a otro certificado si no abre la privada | ANI-M12 |
| MU-AN-67 | Origen | `Principal()` buscado en `CurrentUser` | ANI-M13 |
| MU-AN-68 | Recuperación | La privada de recuperación llega al servidor o queda tras `--recuperar` | ANI-R01, S03 |
| MU-AN-69 | Servidor nuevo | `--preparar` borra o reenvuelve llaves ajenas; salida 0 en vez de 2 | ANI-R02 |
| MU-AN-70 | Arranque sin recuperar | Borrar llaves "ajenas" o descartar secretos antiguos al crear la llave nueva | ANI-R03 |
| MU-AN-71 | `--recuperar` | Reenvolver para el principal viejo, omitir la recuperación anclada o dejar `NoRecuperables` sin avisar | ANI-R04 |
| MU-AN-72 | `--recuperar` | Aceptar sin ancla | ANI-R06 |
| MU-AN-73 | Recuperación cambiada | `--preparar` con `.cer` distinto del anclado y la API crea llaves | ANI-R07 |
| MU-AN-74 | Rotación de llaves | Margen de 2 días mal contado; llave nueva sin recuperación | ANI-T01 |
| MU-AN-75 | `--renovar-certificado` (F4) | Borrar el anterior antes de `--comprobar` | ANI-T05 |
| MU-AN-76 | Falla cerrada | Un `catch` que sigue con DPAPI o con el certificado por omisión | ANI-X01, X02 |
| MU-AN-77 | Certificado ausente | La API genera uno nuevo sola | ANI-X03 |

## 7. Hallazgos de lectura (de este plan)

| ID | Sev. | Hallazgo | Evidencia |
|---|---|---|---|
| QA-AN-01 | Media | **Llaves restauradas de otro principal y la API arranca antes de `--recuperar`.** `ComprobacionAnillo` descarta como "ajenas" las llaves con otro principal y, al no quedar ninguna conforme y admitida vigente, crea una llave nueva (`CreateNewKey`). No pierde datos (`--recuperar` reenvuelve las antiguas), pero la API arranca sin poder descifrar las cadenas de conexión de las empresas, y el blueprint no dice si debe negarse a arrancar. Decisión de B (D-AN-08) | `ComprobacionAnillo.cs` (bloque "Punto 4": `CreateNewKey` si no hay conforme y admitida); blueprint 3.1 "Caso de recuperación en otro servidor" |
| QA-AN-02 | Baja | **Idempotencia incompleta.** El paso 5 solo define el camino "archivo válido y todo en orden". No define archivo presente con certificado ausente, vencido o sin privada, ni archivo inválido. Cada caso puede dejar dos principales con llaves envueltas para el anterior | blueprint 3.1 paso 5 |
| QA-AN-03 | Media | **`OrdenProgramaApiTests` vigila el orden de `Program.cs` de la API** (analiza el texto sin `#if DEBUG`). La línea nueva `AgregarArchivoAnillo` entre `AgregarArchivoInstalacion` y `ProteccionDatos.Configurar` caerá en esa prueba. B pide "coordinar la ventana" con DB-7 (F-5), pero no cita la prueba. Hay que actualizarla en el mismo PR | `tests/GPOS.Tests/Arquitectura/OrdenProgramaApiTests.cs`, `ProgramaApiTexto.cs`; blueprint 3.2 "Dónde se agrega" |
| QA-AN-04 | Baja | **Sin exclusión mutua en el anillo.** El blueprint define `Global\GPOS.Migracion.tls` para `tls` (4.1) y nada para `anillo --preparar`. Dos ejecuciones (técnico y script) pueden crear dos certificados | blueprint 3.1 y 4.1 |
| QA-AN-05 | Baja | **Nombre de contenedor con resolución de un segundo.** `GPOS.Anillo.Api.<AAAAMMDDhhmmss>` choca si hay dos ejecuciones en el mismo segundo; tampoco dice si la hora es UTC o local | blueprint 3.1 paso 6 |
| QA-AN-06 | Baja | **La suite corre en Debug.** El comportamiento de Release (AN-05, PA-77-3) hoy se prueba solo dentro de `if (CompilacionDepuracion)`; en Debug esas ramas no se ejecutan. Para la parte nueva (archivo ausente en Release) hace falta una costura o una pasada de la suite en Release | `AnilloDataProtectionTests.cs:334,342,352`; `ProteccionDatosInstalacion.cs:90-95` |
| QA-AN-07 | Baja | **`AnilloPrueba.Anclar` usa `DateTime.UtcNow`** (no `TimeProvider`); las pruebas de reloj del anillo dependen del reloj real para el ancla. No es un defecto de producción; limita ANI-T01 y T03 | `AnilloPrueba.cs:90` |
| QA-AN-08 | Baja | **Cuenta virtual y token.** El token de una cuenta virtual de servicio incluye `Everyone`, `Authenticated Users` y `Users` [I]; la lectura de `Authenticated Users` que la raíz de ADR-77 concede por herencia no debe llegar a `Api\anillo` ni a la llave (el descriptor está protegido, bien), pero conviene que el cálculo de derechos efectivos de LABA-03 tenga en cuenta esos grupos. Informativo | ADR-77 punto 1 y 4 |

Ninguno es Crítico ni Alto: **sin hallazgos que impidan** empezar la construcción.

## 8. Requisitos de testabilidad para B (condición del nivel U y F)

Sin estas costuras los casos F pasan a W y el laboratorio se llena. Propongo el patrón de `ISistemaServidor`/`SistemaServidorFalso` de A [V, `a/pr-v-verbos-servidor`], y la costura `IAlmacenMaquina` que ya prevé el blueprint (sección 5).

| ID | Costura | Para qué |
|---|---|---|
| R-A1 | **Release inyectable:** `ProteccionDatosInstalacion.Configurar(servicios, config, esWindows, esDepuracion)` (hoy `CompilacionDepuracion` es constante de compilación; la costura `esWindows` ya existe) y el mismo en `ArchivoAnillo` | ANI-F01, F10, X07: probar Release desde la suite en Debug. Alternativa: una pasada de la suite en Release en CI |
| R-A2 | **Constructor del descriptor como función pura** `DescriptorLlaveAnillo.Construir(SecurityIdentifier servicio)` → SDDL | ANI-L03, L04; el oráculo compara con el SDDL escrito a mano |
| R-A3 | **`IAlmacenMaquina` con falso en memoria** que modela: crear llave con descriptor y política de exportación, **rechazar** cambios de seguridad posteriores, listar/abrir/borrar llaves, agregar/quitar/buscar certificados en `My`/`Root`/`CA`/`TrustedPeople`, y registrar el **orden** de las llamadas | O01, O02, L01, L02, A05 |
| R-A4 | **Lector de seguridad del sistema de archivos** (dueño, ACE, reanálisis, lectores) abstraído, con falso que se puede sustituir **entre** la comprobación y la lectura | ANI-E12, E14, F08, F12 |
| R-A5 | **`IEstadoServicios`** (existe) con falso que también puede lanzar, y un servicio de resolución de cuenta (`NTAccount` → SID) abstraído | ANI-E15, M06, M07 |
| R-A6 | **`TimeProvider`** en `PrepararAnillo` y `ArchivoAnillo` (y en el `Anclar` de `AnilloPrueba`, QA-AN-07) | C03, C07, O08, T01 a T04 |
| R-A7 | **Escritura atómica de archivos** (`config`) detrás de una costura que permite simular la muerte a mitad y verificar el dueño | ANI-O04 |
| R-A8 | **Un único punto de entrada de G-1** (`GuardaAnillo.ComprobarOSalir(verbo)`) que llama todo verbo que use el proveedor de Data Protection, más una lista de verbos protegidos en un solo lugar | ANI-M06, M10, AR08 |
| R-A9 | **Exclusión mutua nombrada** detrás de una costura (como `Global\GPOS.Migracion.tls`), si se adopta D-AN-04 | ANI-O11 |
| R-A10 | **Vectores** `docs/contratos/vectores/anillo-dm07.v1.json` con perfil esperado, SDDL esperado y 35 combinaciones de conflicto | C01, L03, F09 |

## 9. Dudas para B

**Bloquean casos (escribir o ejecutar sin respuesta es adivinar):**

| ID | Duda | Qué hice mientras tanto | Bloquea |
|---|---|---|---|
| **D-AN-01** | **La hoja de firma** `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` que cita el blueprint (P-1 a P-9) no está en `origin/b/blueprint-tls-anillo` ni en `origin/master`. ¿Dónde está? Mientras tanto tomé como firmado lo que el blueprint declara firmado (P-1 a P-8 y F1) | Escribí el plan con P-1 (archivo propio), P-4 (5 años) y P-5 como firmados | Todo el plan, si alguna cambió |
| **D-AN-03** | **Idempotencia incompleta (QA-AN-02).** ¿Qué hace `--preparar` si (a) el archivo existe y es válido pero el certificado falta en `My`, venció o no tiene privada; (b) el archivo existe pero es inválido; (c) hay un certificado y una llave del anillo en `My` sin archivo (ejecución interrumpida)? Recomiendo: (a) y (b) salida 4 sin reemplazar (lo repara una acción explícita, `--renovar-certificado` o un procedimiento de restauración); (c) reutilizarlo o retirarlo, nunca crear un segundo | Casos con el esperado "no crea un segundo principal sin reenvolver" | ANI-O02, O03, O09, O10, R09; LABA-15 |
| **D-AN-04** | **¿Hay exclusión mutua en `--preparar`?** (QA-AN-04). Recomiendo `Global\GPOS.Migracion.anillo`, espera de 60 s y salida 1, como `tls` | ANI-O11 con ese supuesto | ANI-O11; R-A9 |
| **D-AN-08** | **API con llaves restauradas de otro principal antes de `--recuperar` (QA-AN-01).** ¿Debe negarse a arrancar (falla cerrada) o puede arrancar creando una llave nueva y sin poder leer los secretos antiguos? Recomiendo negarse a arrancar con un mensaje que nombre `anillo --recuperar` (hoy el comportamiento es el segundo). **D-AN-08b:** la privada de recuperación importada en `CurrentUser\My`, ¿la borra `--recuperar` o el procedimiento manual (paso 5 del blueprint)? | Caso R03 con el comportamiento actual como mínimo (no borra nada) | ANI-R03, R01 |

**No bloquean, pero cambian el esperado:**

| ID | Duda |
|---|---|
| D-AN-02 | Códigos de salida de `anillo --preparar`: el blueprint da 0, 1, 2 y 4 en el texto pero no hay una tabla como la de `tls` (4.1). ¿Se documentan en `--ayuda`? ¿Un aviso (menos de 180 días) es 0 o 2? ¿Y los otros verbos del grupo `anillo`, que hoy devuelven 0 o 1? |
| D-AN-05 | Conflicto con otra fuente: la regla 4 dice "con **otro** valor". ¿Un valor idéntico en `appsettings` o en el entorno es válido o también conflicto? Recomiendo conflicto siempre ("una sola fuente", como PT-06): más fácil de probar y más difícil de equivocar |
| D-AN-06 | G-1 cuando `IEstadoServicios` no puede consultar el SCM (sin acceso): ¿falla cerrada (4) o se asume "no instalado"? Recomiendo falla cerrada |
| D-AN-07 | G-2: ¿`sistema --cuentas-iniciales` **sin** `--confirmar-sellado` también exige ancla? ¿Y `sellos`, `empresa`, `credencial-app`? El blueprint nombra solo `--cuentas-iniciales` y `--confirmar-sellado` |
| D-AN-09 | Recuperación ECDSA: `CifradorAnillo` reserva la variante ECDH P-256 (`CifradorAnillo.cs:60-61`). ¿`--recuperacion` rechaza ECDSA hoy (supuesto de ANI-E05) o lo admitirá cuando exista la variante? |
| D-AN-10 | (a) Vigencia mínima de la recuperación (1 día, 29 días): ¿se acepta? (b) El aviso a 180 días de `--comprobar`: ¿cambia el código de salida? (c) Certificado del anillo vencido: ¿la API arranca (sin crear llaves) o no? Hoy `ComprobacionAnillo` lo trata como no válido y no crea llaves |
| D-AN-11 | (a) Ruta de `--recuperacion` en un directorio escribible por no administradores o UNC: ¿rechazo o aviso? (b) Desinstalar el MSI de la API: ¿conserva certificado, llave, archivo y carpeta del anillo (supuesto de LABA-17), y la reinstalación conserva el SID de la cuenta virtual? |
| D-AN-12 | Sujeto y vigencia: ¿la fecha del CN es UTC o local? ¿`NotAfter` = "ahora + 5 años" de calendario o 1826 días? ¿Qué hace el 29 de febrero? |
| D-AN-13 | Huellas en el archivo: ¿mayúsculas rechazadas o normalizadas? (el blueprint dice "minúsculas"; `HuellaCertificado.Normalizar` existe). ¿Repetidas o igual a la actual en `certificadosServidorAnteriores`? |
| D-AN-14 | `carpeta` fuera de `%ProgramData%\GPOS NG` y `identidadServicio` distinta de `NT SERVICE\GPOS.Api` en el archivo: ¿se admiten (ADR-77 punto 4 permite "esté o no bajo `GPOS NG`") o el cargador del servicio `GPOS.Api` las fija? |
| D-AN-15 | `--preparar` con una `--recuperacion` distinta de la anclada en un servidor restaurado: ¿debe consultar el ancla y avisar (hoy no abre la base, K-05) o el aviso lo da solo la API al arrancar (supuesto de ANI-R07)? |

## 10. Esfuerzo, orden y dependencias [I, ±40 %]

| Tanda | Contenido | dp |
|---|---|---|
| T0 | Vectores y oráculo (`anillo-dm07.v1.json`, lector `AsnReader`, SDDL), ANI-C, ANI-L03, ANI-F03 a F05, F09 (35 combinaciones), pruebas de arquitectura AR: puros | 0,9 |
| T1 | Falsos (`AlmacenMaquinaFalso` de B; yo uso el de B) y los casos F: E, O, M (G-1, G-2), R, T, X | 1,2 |
| T2 | Casos W (almacén, ACL y archivos reales) con guardas | 0,5 |
| T3 | Guiones del laboratorio (`EstadoAnillo.ps1`, hallar el contenedor, derechos efectivos, bucle de muerte súbita) | 0,4 |
| T4 | Ejecución en `VM-SRV` (B opera, C revisa evidencia redactada): 4 sesiones, unas 10 h | (B) |
| | **Total de escritura de pruebas** | **≈ 3,0 dp** (2,6 de pruebas + 0,4 de guiones) |

Orden: T0 mientras B construye (R-A2 y R-A10 primero); T1 al recibir R-A3; T2 al cerrar F1; T3 antes de la sesión 1 (VM del 16-nov); T4 con la VM del instalador (18-nov). Estas 3,0 dp **no** están en los 0,5 dp de pruebas de F1 del blueprint (sección 8, tabla de fases), que cubren las 16 pruebas de 7.1 (cubro esas, más unos 100 más). No corren a la vez la suite completa y el laboratorio en `LFMB`.

**Recorte si no alcanza (propongo, no impongo):** primero T2 (los casos W se cubren con LABA 01-03), luego ANI-F12 y ANI-O11, y al final los casos de T05 (que son F4).

## 11. Qué no verifiqué

- Que `CertificateRequest` + `CopyWithPrivateKey` con una `CngKey` persistida de máquina deje el certificado ligado al contenedor al agregarlo a `LocalMachine\My` (blueprint 3.1 paso 8; W-AN-01). Es el supuesto que sostiene ANI-A01 y A02.
- Que `GENERIC_READ` sobre una llave de CNG baste para **usar** la llave (descifrar con RSA-OAEP) y no sea más amplio (ANI-L08, LABA-03/04).
- La ruta exacta de los contenedores de CNG para `icacls` (LABA-03).
- Cómo se evalúa el acceso efectivo del SID de una cuenta virtual desde una sesión de laboratorio: no encontré cómo ejecutar código "como" `NT SERVICE\GPOS.Api` sin un servicio real; los casos negativos de ANI-L08 se resuelven por cálculo sobre la DACL y por LABA-05 (efecto sobre el servicio real).
- Que `X509CertificateLoader.LoadCertificateFromFile` acepte PEM de un solo certificado (ANI-E08) [I].
- El texto completo de la hoja de firma de B (D-AN-01), ADR-126 más allá de lo que cita el blueprint, y el código de `PR-V` (`DisposicionServidor`, `SddlServicios`).
- No compilé ni ejecuté nada. Las mutaciones y los 35 casos de F09 se enuncian; no se han corrido.

### Cierre
- Estado: Completado (plan; no se compiló ni se ejecutó nada)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-pruebas-anillo-dm07.md`
- Supuestos: P-1 (archivo propio), P-4 (5 años) y el resto de P-1 a P-8 firmados como declara el blueprint (hoja no vista); el anillo de la API es F1 y el de la Web, `--renovar-certificado` y `--importar --pfx` son F4; el verbo es solo Windows; las cifras de esfuerzo son [I].
- Decisiones candidatas a ADR: ninguna nueva. D-AN-08 (API con llaves ajenas antes de recuperar) y D-AN-14 (ruta del anillo fuera de `GPOS NG`) merecen precisión en la nota de lectura de H-17 v2 / ADR-77 del Arquitecto Maestro.
- Entregas a otros agentes: B (desarrollador) → D-AN-01 a D-AN-15 y R-A1 a R-A10; B (arquitecto-software) → QA-AN-01 (D-AN-08) y QA-AN-02 (D-AN-03) antes de construir; A (desarrollador) → actualizar `OrdenProgramaApiTests` por la línea nueva (QA-AN-03) y el paso `anillo --preparar` en `FaseEsquema` (ANI-M11); auditor-seguridad → revisar ANI-L03, L04, F08, F09 y S01 antes de la ejecución en la VM; Arquitecto Maestro → D-AN-08 y D-AN-14.
- Próximo paso recomendado: B responde D-AN-01, D-AN-03, D-AN-04 y D-AN-08 y entrega R-A2 (descriptor puro) y R-A3 (`AlmacenMaquinaFalso`) en el primer commit de F1.
