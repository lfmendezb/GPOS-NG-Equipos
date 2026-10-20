[Informe de Seguridad] Revisión del diseño del laboratorio de ADR-90 (PT-07): Name Constraints, CA fijada y renovación sin reinicio

- **Fecha:** 2026-10-20 · **Revisor:** auditor-seguridad del equipo C (OSHIN-LEGION).
- **Objeto:** `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md` (en adelante, «diseño», citado como `diseño:línea`). No lo modifiqué.
- **Insumos:** `origin/master` `45a9ab75`, con `docs/adr/ADR-090.md`, `docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md` (la «hoja») y `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` (REV), más `docs/adr/ADR-129.md`. Código: `origin/feature/modelo-ng` `b8f166db`. Todo leído con `git show` y `git grep`, sin *checkout*.
- **Tipo:** solo revisión. No compilé, no ejecuté pruebas, no instalé nada y no toqué bases de datos.
- **Marcas:** [V] = verificado en el código o en el texto citado. [I] = inferido: comportamiento de CryptoAPI, OpenSSL, Java, Chromium, NSS o .NET que no comprobé en esta sesión. Para confirmarlo existe el laboratorio.

> Esto es una recomendación técnica (C2). Los cambios al diseño los hace su autor. Las precisiones de ADR-90 las prepara el Arquitecto Maestro y las firma el propietario.

---

## 1. Alcance y superficie revisada

- **Política de validación** (`diseño:146-182`): P-FIJADA, criterio de aceptación y modo sin CA fijada.
- **Perfiles y matriz** (`diseño:186-382`): bloques N, F, V, R, B y M.
- **Hallazgos sobre el código** F-01 a F-08 y **observaciones** O-01 a O-06 (`diseño:57-94`).
- **Preguntas** Q-LAB-01 y Q-LAB-02 (`diseño:486-519`).
- **Arnés, entorno y riesgos** (`diseño:98-142`, `:386-452`).

**Superficie que prueba el laboratorio:**
- clientes TLS de GPOS NG: la Web hacia la API, MAUI en Windows, el agente en modo estación y, más adelante, Android e iOS;
- navegadores con la raíz en `LocalMachine\Root`;
- el selector de certificado de Kestrel con la huella en el registro;
- la tarea de renovación como SYSTEM;
- las CA de prueba instaladas en los almacenes de máquina de las VM.

**Fuera de alcance:**
- PT-04, salvo lo que afecta a `pathLen` y al EKU (LS-13);
- PT-05 y PT-06;
- perfiles de red.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Responsable |
|---|---|---|---|
| LS-01 | Media | LAB-23 no demuestra la exclusividad: CA-S no está en el almacén cuando el caso corre en memoria | Diseño |
| LS-02 | Media | «`ExtraStore` vacío» no excluye las intermedias que envía el servidor; LAB-18 puede aprobar sin probar `pathLen` | Diseño (política y LAB-18) y A (validador) |
| LS-03 | Media | La política no fija de dónde sale el certificado de la CA de `CustomTrustStore`: el QR solo trae el SPKI | Diseño y A (contrato SD-10 v2) |
| LS-04 | Media | Falta el bloque Linux, aunque ADR-129 (aceptado) pone la Web y la estación en Linux | Diseño; B (VM Linux) |
| LS-05 | Media | Modo sin CA fijada: las condiciones 3 y 4 rompen los certificados públicos con comodín o con varios SAN, y la 4 no añade seguridad | Diseño y A |
| LS-06 | Media | `NotBefore` igual a la hora de emisión: un puesto con el reloj atrasado rechaza cada renovación (cada 60 días) | Diseño y A (verbo) |
| LS-07 | Media | LAB-30 está mal construido: H-CODE (`CN=Prueba`, sin SAN) puede fallar por las NC y no por el EKU; falta el caso S/MIME | Diseño |
| LS-08 | Baja | Casos de ataque que faltan en la matriz (intermedia laxa, mismo SKI, hoja sin EKU, URI y correo, extensiones críticas, mayúsculas, punto final, IDN, entre otros) | Diseño |
| LS-09 | Baja | La condición 4 no define qué es un «nombre» ni cómo se normaliza | Diseño y A |
| LS-10 | Baja | F-02 se queda corto: una llave de servidor robada vale para siempre ante las estaciones | A |
| LS-11 | Baja | Arnés: guardas de VM débiles, limpieza incompleta y redacción de la evidencia sin definir | B (devops) y A (qa) |
| LS-12 | Baja | Modo sin CA fijada con descargas activas: recuperaciones AIA desde la red local sin Internet | Diseño, A y B |
| LS-13 | Baja | Q-LAB-01 (a) tiene consecuencias no declaradas sobre la sucesora, el certificado cruzado y `pathLen = 0` | Diseño y Arquitecto Maestro |
| LS-14 | Baja | Origen y actualización de la lista de nombres del sitio; un cambio de nombre o de IP exige una CA nueva | Diseño, A y Arquitecto Maestro |
| LS-15 | Baja | Bloque R: la licencia por vigencia (construida) contamina los resultados al adelantar el reloj 91 a 95 días | Diseño y B |
| LS-16 | Baja | Una prueba de arquitectura por patrones es frágil: conviene un único validador y la prohibición de esas API fuera de él | A |
| LS-17 | Baja | Inexactitudes de evidencia en el diseño (F-03, F-05, F-06, sección 7) y una probabilidad optimista en la sección 8 | Diseño |

**Recuento:** ningún hallazgo Crítico ni Alto; 7 Medios y 10 Bajos.

---

## 3. Checklist OWASP Top 10 (2021), aplicado al diseño del laboratorio

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | No aplica directamente. LS-15 (rutas operativas bloqueadas por la licencia durante el bloque R) |
| A02 Fallas criptográficas | Observaciones LS-01 a LS-09, LS-12 a LS-14. La base es correcta: `CustomRootTrust`, `NoFlag`, sin descargas, `serverAuth`, sin CN |
| A03 Inyección | No aplica |
| A04 Diseño inseguro | Observaciones LS-03, LS-05, LS-06 y LS-14 (contratos que empujarían a relajar la validación) |
| A05 Configuración | Observaciones LS-11 (VM, almacenes y limpieza) y LS-12 |
| A06 Componentes vulnerables | No aplica: sin dependencias nuevas (`System.Formats.Asn1` y `System.Security.Cryptography` son del marco) |
| A07 Identificación y autenticación | Observaciones LS-03 (anclas de confianza) y LS-10 |
| A08 Integridad de software y datos | Observaciones LS-07 y LS-13 (firma de código con la CA del sitio) |
| A09 Registro y monitoreo | Bien: CAPI2, JSON por caso y eventos de N-8. Observación LS-11 (redacción de la evidencia) |
| A10 SSRF | Observación LS-12: recuperaciones AIA hacia URL que trae un certificado no confiable |

---

## 4. Dictamen por punto

### 4.1 Política de validación (punto 1)

**Veredicto:** el núcleo de P-FIJADA es correcto para .NET en Windows, pero está **incompleto**. A puede adoptarla como contrato solo con las correcciones de LS-02, LS-03, LS-06 y LS-09 y con la regla de EKU explícito (LS-08, caso H-SINEKU).

| Ajuste | Dictamen |
|---|---|
| `CustomRootTrust` con la vigente y la sucesora | **Correcto.** Falta fijar que los certificados del almacén son los DER guardados al emparejar y nunca los que trae el saludo (LS-03). También falta que `TrustMode` y `CustomTrustStore` vayan siempre juntos: con `TrustMode = System`, .NET ignora `CustomTrustStore` [I] y el código parece fijado sin estarlo (LS-16) |
| `ExtraStore` vacío | **La justificación es incorrecta** (`diseño:156`). `SslStream` agrega al `ExtraStore` de la cadena los certificados que envía el servidor en el saludo [I]. La barrera real es `pathLen = 0` de la CA más una comprobación propia de que la cadena tiene 2 elementos (LS-02) |
| `DisableCertificateDownloads = true` | **Correcto.** LAB-27 no lo demuestra tal como está (LS-08, LAB-27b) |
| `RevocationMode = NoCheck` | **Correcto** y coherente con RT-04, que firmó «sin CRL ni OCSP». Evita las marcas `Ignore*RevocationUnknown` |
| `VerificationFlags = NoFlag` | **Correcto.** Con `NoFlag`, cualquier estado de NC, incluidos `HasNotSupportedNameConstraint` y `HasNotDefinedNameConstraint`, hace fallar la cadena. Es falla cerrada, como debe ser |
| `ApplicationPolicy serverAuth` | **Necesario pero no suficiente.** CryptoAPI trata una hoja **sin** extensión EKU como válida para cualquier uso [I], así que `serverAuth` en la política no exige que la hoja lo declare. Hace falta una comprobación explícita: la hoja tiene EKU, contiene `serverAuth` y no contiene `anyExtendedKeyUsage` (LS-08) |
| `ChainStatus` vacío | **Correcto.** No se acepta ninguna marca, ni siquiera `PartialChain`, y no hay reintentos «completando» la cadena |
| `MatchesHostname(host, false, false)` | **Correcto en el modo con CA fijada.** En el modo público rompe los comodines (LS-05). No está documentado cómo trata el punto final ni las U-labels [I] (LS-09) |
| Todo el SAN dentro de la lista del sitio | **Correcto como defensa** con CA fijada. Falta definir qué tipos de nombre cuentan y cómo se normalizan (LS-09) y de dónde sale la lista y cómo se actualiza (LS-14). Con certificado público no aporta seguridad y rompe certificados legítimos (LS-05) |

**¿`X509Chain` aplica de verdad las NC con `CustomRootTrust`?**
- **No se puede afirmar sin el laboratorio [I].** RFC 5280 no obliga a procesar las extensiones del ancla. Que CryptoAPI aplique las NC de la raíz cuando el ancla viene de un motor de raíz exclusiva (lo que usa .NET para `CustomRootTrust` [I]) es justo lo que deben decidir LAB-04 y LAB-05. Con LAB-05 como control, el diseño los plantea bien.
- **Calificación de la sección 8.** La probabilidad «Baja [I]» de que no se apliquen (`diseño:432`) no tiene base. ADR-90 y la hoja la tratan como Media hasta el laboratorio (hoja, tabla de riesgos, «Media / Medio»). Recomiendo «Media [I]» (LS-17).
- **IP.** LAB-03, LAB-11, LAB-12 y LAB-13 las cubren bien.
- **CN.** LAB-02, LAB-15 y LAB-16 lo registran. La condición 3 (`allowCommonName: false`) cierra el caso en el validador aunque Windows recurra al CN [I]. La política de SSL de Windows sí recurre al CN cuando no hay SAN [I], y por eso `sslPolicyErrors == None` no basta por sí solo.

**¿Algún flag o estado las debilita?**
- `IgnoreInvalidName` anula las NC.
- `AllowUnknownCertificateAuthority` anula la exclusividad del ancla.
- `IgnoreNotTimeValid` e `IgnoreWrongUsage` anulan el vencimiento y el EKU.
- Además:
  - `TrustMode = System` con `CustomTrustStore` lleno;
  - una `ApplicationPolicy` vacía;
  - cualquier tratamiento especial de `PartialChain`.
- La lista de la sección 4 (`diseño:177-182`) se completa en LS-16.

**`NotTimeValid`.**
- Aplica a la hoja y también al ancla [I]: una CA fijada vencida, o aún no vigente, debe rechazar. Falta ese caso (LS-08).
- No se debe fijar `VerificationTime` a partir de datos del servidor: se deja la hora local por omisión (`VerificationTimeIgnore = true`).
- Riesgo operativo con la hoja recién emitida: ver LS-06.

**`PartialChain`.** Con P-FIJADA, una hoja de otra raíz da `PartialChain` o `UntrustedRoot`, según CryptoAPI encuentre o no al emisor en los almacenes del sistema [I]. El validador no distingue entre los dos: rechaza ambos, y el criterio de LAB-24 a LAB-26 («rechazo») es correcto.

**Plataformas que no son Windows:**
- **Linux:** está en el alcance por ADR-129 (la Web, la API y la estación). .NET usa la cadena de OpenSSL. `CustomRootTrust` y `DisableCertificateDownloads` funcionan [I], y OpenSSL aplica las NC de toda la cadena, incluida el ancla [I]. Hace falta un bloque N-L (LS-04).
- **Android:** con el manejador de Java (PKIX), las NC del ancla probablemente **no** se aplican [I]. La condición 4 pasa a ser el control que sostiene la seguridad y LAB-64 debe incluir la variante de dos niveles.
- **iOS:** depende de `SecTrust` [I]. Ya está declarado en LAB-65.
- **macOS:** no aloja ningún componente del producto. Sus navegadores quedan como instalación manual, fuera del laboratorio.

### 4.2 Cobertura de la matriz (punto 2)

Faltan casos relevantes; el detalle está en LS-07 y LS-08. Respuesta a lo pedido:

| Caso pedido | Hoy | Dictamen |
|---|---|---|
| Intermedia con restricciones más laxas que la raíz | No está (Sub-A solo prueba `pathLen`) | **Falta.** Hace falta para el punto 2 de la sección 8 y para demostrar que las NC de la raíz se aplican también por debajo de una intermedia. LS-08, N-A |
| `excludedSubtrees` | Solo IP (CA-A0, LAB-13 y LAB-14) | Suficiente para el perfil del verbo. Falta la IPv4 mapeada contra CA-A0 (LS-08, N-F) |
| IDN o punycode, mayúsculas y punto final | No están | **Faltan.** LS-08, N-G y N-H; LS-09 |
| SAN con `URI` o `email` | No están | **Faltan.** También como medida del riesgo de O-05 (S/MIME). LS-07 y LS-08, N-D |
| Extensiones críticas desconocidas | No están | **Faltan**, en la hoja y en la CA. LS-08, N-E |

**Resultados esperados que corregir:**
- **LAB-23** no discrimina en memoria (LS-01).
- **LAB-18** puede aprobar por `PartialChain` y no por `pathLen` (LS-02).
- **LAB-27** no prueba la desactivación de descargas, porque la cadena ya está completa (LS-08, LAB-27b).
- **LAB-30:** con H-CODE (`CN=Prueba`), «`Valid` demuestra el riesgo» puede salir «no válido» por las NC y llevar a la conclusión falsa de que no hay riesgo (LS-07).
- **Resto:** los resultados de LAB-01 a LAB-22, LAB-24 a LAB-26, LAB-28, LAB-29, LAB-31 y del bloque B son correctos. LAB-12 está bien razonado: 16 octetos no casan con una restricción de 8.

### 4.3 Hallazgos F-01 a F-06 contra el código (punto 3)

| Id | Dictamen | Evidencia [V] | Severidad |
|---|---|---|---|
| F-01 | **Confirmado.** `if (errores == SslPolicyErrors.None) return true;` acepta todo lo que valida el almacén del sistema, antes de mirar el SPKI | `src/GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:67` | **Media** (equivale a H-03; lo sustituye PT-03; no hay clientes) |
| F-02 | **Confirmado, con más alcance del declarado.** Si el único error es la cadena y el SPKI de la **hoja** está fijado, acepta: vencida, aún no vigente, sin `serverAuth` o de una raíz desconocida. Además de ocultar una renovación fallida, una llave de servidor robada sirve **para siempre** ante las estaciones, lo que anula H-11 (90 días) para ellas. Ver LS-10 | `ClienteDispositivo.cs:68-69`; el SPKI se calcula sobre la hoja en `:72-73` y `:81` | **Baja** (sin clientes; desaparece con PT-03 si no se conserva como respaldo) |
| F-03 | **Confirmado en lo sustancial**: no hay verbo `tls`, ni HTTPS ni selector en Kestrel, ni `NameConstraints`, `X509Chain`, `CustomRootTrust`, `CertificateChainPolicy` o `MatchesHostname` en `src`. **Inexacto en la letra:** `git grep UseHttps` sí devuelve `app.UseHttpsRedirection()` | `git ls-tree src/GPOS.Migracion` sin `tls`; `src/GPOS.Web/Program.cs:109` | Informativo |
| F-04 | **Confirmado.** `HttpClient` de la fábrica sin manejador propio; URL en `Preferences` con `http://` por omisión (`10.0.2.2` en Android), también en Release | `GPOS.UI.MAUI/MauiProgram.cs:19-23`; `GPOS.UI.MAUI/Servicios/ConfiguracionApi.cs:6-12` | **Baja** (es H-09, ya firmado en PT-10) |
| F-05 | **Confirmado, con una precisión.**<br>- El `ConnectCallback` citado abre una **canalización con nombre** con comprobación del dueño, no un socket TCP a *loopback*: sirve de precedente de la API, no del patrón de PT-01.<br>- El rechazo de `Kestrel:Endpoints` y la comprobación de direcciones efectivas, confirmados.<br>- `HuellaCertificado.Sha256`, confirmado.<br>- `PrivadaEnTpm` solo reconoce RSA (`GetRSAPrivateKey()` y `RSACng`) | `src/GPOS.Api/Endpoints/ReenvioReportes.cs:267-276`; `src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:83-84` y `:157-179`; `src/GPOS.Criptografia/Anillo/CifradorAnillo.cs:31-33`; `src/GPOS.Core/Infraestructura/Anillo/OrigenCertificadosAnillo.cs:50-56` | Informativo |
| F-06 | **Confirmado.** Tolerancia de 5 min, salto máximo de 48 h y marca de inconsistencia al retroceder. El diseño cita los comentarios del contrato (`:19-22`, `:77-81`) y no la implementación. **Omisión:** `Ahora()` es el máximo entre el reloj del sistema y el ancla (`:14`), así que la **licencia por vigencia**, ya construida, ve el reloj adelantado (LS-15) | `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs:88`, `:91` y `:275`; `src/GPOS.Api/Seguridad/ModoLicencia.cs` | Informativo; el efecto en el laboratorio está en LS-15 |

F-07 y F-08 también están confirmados:
- F-07: `ClienteDispositivo.cs:77`.
- F-08: `tests/GPOS.Tests/GPOS.Tests.csproj:15` (xUnit 2.9.3).

Hay precedentes del atributo de omisión que conviene citar: `FactBp2Attribute`, `FactDemoAttribute` y `FactModoMixtoAttribute` (`tests/GPOS.Tests/ModeloNg/ExtraccionBp2Tests.cs:13`, `ImplantacionDemoTests.cs:12` y `Rg14Lote2Tests.cs:18`).

### 4.4 Observaciones O-01 a O-04 y preguntas Q-LAB-01 y Q-LAB-02 (punto 4)

**Observaciones:**

| Id | Acuerdo | Riesgos no declarados |
|---|---|---|
| O-01 | **De acuerdo** (RFC 5280, 4.2.1.10). La nota de lectura basta | La forma con punto inicial (`.srv-c01…`) **no** sirve para excluir solo los subdominios: no es portable entre verificadores [I]. No usarla |
| O-02 | **De acuerdo** | Sin ningún subárbol `dNSName`, una CA no limita los nombres DNS. El verbo debe rechazar ese caso (LAB-33), y `comprobar-servidor` debe comprobar que la CA instalada tiene al menos un subárbol `dNSName` y uno `iPAddress` (permitido, o excluido `/0`) |
| O-03 | **De acuerdo** | `HuellaAnterior` debe pasar las mismas validaciones que la vigente (LAB-41). El orden de escritura debe ser: primero `HuellaAnterior`, después `Huella`. Una interrupción entre las dos escrituras no debe dejar ninguna huella apuntando a un certificado sin validar |
| O-04 | **De acuerdo** | La Web lee la CA del sitio de `%ProgramData%\GPOS NG\Servidor\tls\`, que solo escriben Administradores y SYSTEM (H-12): su integridad es la del ACL, lo que es aceptable. En Linux (ADR-129) hace falta el equivalente (raíz 0644 en `/etc/gpos-ng/`) [I] |

**Q-LAB-01 · De acuerdo con (a)**, con las condiciones de LS-07 y LS-13.
- Una CA con NC en `dNSName` e `iPAddress` y con EKU sin `anyExtendedKeyUsage` es lo que la política de raíces de Mozilla (5.3.1) y los BR del CA/Browser Forum llaman CA «técnicamente restringida» [I].
- **Riesgos no declarados:**
  1. La sucesora y su certificado cruzado deben llevar un EKU igual o más estrecho (LS-13).
  2. Con solo `serverAuth`, la CA del sitio no podrá emitir nunca certificados de cliente, por ejemplo para un futuro TLS mutuo de las estaciones. Hoy nada lo prevé: ADR-53 autentica el nodo con la llave del TPM.
  3. Java PKIX (Android) probablemente ignora el EKU del ancla [I]. No hace daño.
  4. LAB-30, tal como está, no demuestra el riesgo que justifica la pregunta (LS-07).

**Q-LAB-02 · De acuerdo con (a) en la v1**, con estas precisiones:
1. **El residual depende del tipo de CA y debe declararse por separado:**
   - con una CA pública, el máximo es de 200 días hoy y de 100 días desde marzo de 2027 [I, SC-081];
   - con la CA de dominio del cliente (AD CS), las vigencias suelen ser de 1 a 2 años [I], así que el residual es mayor.
2. **Mitigaciones sin costo:**
   - `comprobar-servidor` avisa si el certificado del cliente dura más de 200 días;
   - `NoCheck` nunca se combina con ninguna marca `Ignore*`.
3. **Alternativa descartada: (d) `Online` con falla abierta en código propio** (rechazar solo `Revoked`).
   - No exige marcas `Ignore*`.
   - Un atacante en la red bloquea la consulta.
   - Cuando la CRL no se alcanza, añade el tiempo de espera de la recuperación a cada conexión nueva [I].
4. **Ver LS-12:** las descargas también deberían desactivarse en este modo.

### 4.5 Arnés (punto 5)

**Veredicto:** el planteamiento es correcto:
- sin proyectos nuevos;
- atributo de omisión con `GPOS_LAB_TLS`;
- doble guarda para los almacenes;
- oráculo independiente del verbo;
- llaves no exportables y sin PFX;
- red interna sin Internet.

Le faltan guardas, limpieza y redacción, que detalla **LS-11**.
- **Filtración de llaves al repositorio:** el riesgo es bajo, porque las llaves se generan en ejecución. Aun así, `.gitignore` solo cubre `*.pfx` (`.gitignore:239`, árbol de trabajo de `master`).
- **CA de prueba en `LocalMachine\Root`:** la limpieza debe hacerse por marcador y terminar restaurando el punto de control. Nunca se usa `CurrentUser\Root`.
- **R-1:** promover a la suite los casos en memoria es razonable, salvo:
  - LAB-23, que debe pasar a la VM (LS-01);
  - los casos informativos, cuyo resultado depende de la versión de Windows. Solo se promueven los de resultado exacto, y con la plataforma registrada.

---

## 5. Hallazgos

### LS-01 · Media · LAB-23 no demuestra que `SslStream` excluya el almacén del sistema
- **Riesgo.** LAB-23 quiere confirmar que `SslStream` usa la política dada «y no el almacén» (`diseño:275`). La primera mitad (CA-A en la política) sí discrimina. La segunda (una hoja de CA-S → `RemoteCertificateChainErrors`) da el mismo resultado se use o no el almacén si CA-S **no** está instalada, y R-1 trata LAB-23 como caso en memoria (`diseño:401`, `:529`). Justo la propiedad de PT-03 («nunca las dos a la vez») quedaría sin probar en `SslStream`.
- **Evidencia.** `diseño:275`, `:401`, `:529`.
- **Corrección.**
  - Dividir el caso:
    - LAB-23a, en memoria: CA-A en la política → `None`;
    - LAB-23b, solo en la VM: CA-S instalada en `LocalMachine\Root`, con el control `TrustMode = System` → `None` y P-FIJADA → `RemoteCertificateChainErrors`.
  - Sacar LAB-23b de R-1.
- **Responsable:** el diseño.

### LS-02 · Media · `ExtraStore` vacío no excluye las intermedias del saludo; LAB-18 puede aprobar sin probar `pathLen`
- **Riesgo.** La política justifica `ExtraStore` vacío con «No se aceptan intermedias que traiga el servidor» (`diseño:156`). Pero:
  - `SslStream` agrega a la cadena los certificados que el servidor envía en el saludo [I];
  - un `X509ChainPolicy` compartido entre conexiones podría acumular esos certificados si la plataforma lo modifica en lugar de copiarlo [I].
- **Consecuencias para LAB-18:**
  - si corre con `X509Chain` y el `ExtraStore` vacío, falla por `PartialChain`, no por `pathLen`, y «`Build = false`» aprueba sin demostrar nada (`diseño:270`);
  - si `pathLen` no se aplicara, el diseño no lo vería.
- **Corrección.**
  1. **Política.** El validador construye **su propia** cadena en la devolución de llamada, con una política nueva por conexión y el `ExtraStore` realmente vacío, a partir de la hoja. Exige `ChainElements.Count == 2` (hoja → CA fijada) hasta que PT-04 defina el caso del certificado cruzado. `CertificateChainPolicy` se sigue pasando a `SslStream`, para que su propio cálculo no use el almacén.
  2. **LAB-18.** Sub-A se entrega por `ExtraStore` y, en un segundo paso, en el saludo de un Kestrel de prueba. Criterio: marca `InvalidBasicConstraints` en el elemento de CA-A [I sobre el nombre exacto] **y** el control «CA-X sin `pathLen` + Sub-X + hoja → válida». La cadena del validador debe rechazar por longitud aunque la plataforma no aplicara `pathLen`.
- **Responsable:** el diseño (texto de la política y LAB-18) y A (validador compartido).

### LS-03 · Media · De dónde sale el certificado de la CA fijada
- **Riesgo.**
  - `CustomTrustStore` necesita el **certificado** de la CA, pero el QR de RT-10 punto 4 lleva «los SPKI de la CA vigente y de la sucesora» y el alta manual, 128 bits del SHA-256 del SPKI (ADR-090.md:119 y PT-08).
  - Si A resuelve el hueco tomando en cada conexión la raíz que envía el servidor y comparando solo su SPKI, quien tenga la llave filtrada de la CA puede presentar una raíz **autofirmada con el mismo SPKI y sin Name Constraints**, sin el EKU de Q-LAB-01 o con otra vigencia, y anular esas defensas en los clientes de GPOS NG.
  - La condición 4 seguiría limitando los nombres a la lista del sitio, y por eso no es Alto.
  - Es justo el escenario contra el que existen las NC.
- **Evidencia.** `diseño:155` y `:165`; ADR-090.md:119 y :131; hoja, PT-08.
- **Corrección (contrato de A, versión nueva del formato SD-10):**
  1. **Al emparejar**, el cliente obtiene el DER de la CA, por el QR o por una ruta de solo lectura, y comprueba que el SHA-256 de su SPKI coincide con el del QR o con el alta manual.
  2. **Valida el perfil:**
     - NC crítica, con al menos un `dNSName`;
     - `pathLen = 0`;
     - autofirma válida;
     - vigencia;
     - EKU, si se firma Q-LAB-01.
  3. **Guarda el DER** junto a la URL en el almacén seguro (PT-03).
  4. **Condición 2:** la raíz de la cadena es **idéntica por DER**, o por su SHA-256, a una de las guardadas.
  5. **Nunca** se toma un ancla del saludo.
  6. **Caso nuevo de la matriz:** el servidor presenta una raíz con el mismo SPKI que CA-A y sin NC, y el validador la rechaza.
- **Responsable:** el diseño (añadirlo a la sección 4 y a la matriz) y A (arquitecto-software: SD-10 v2).

### LS-04 · Media · Falta el bloque Linux
- **Riesgo.** ADR-129 (aceptado, PL-01 a PL-15) admite en Linux `GPOS.Api`, el proceso servidor de `GPOS.Web` y la estación en modo servicio (ADR-129.md:23 y :74-77).
  - Sus validadores (la Web hacia la API por O-04, y la estación) usan en Linux la cadena de OpenSSL, con otras marcas y otro trato del CN [I].
  - El diseño solo declara Windows y la fase móvil (`diseño:22-29`).
  - El atributo comprueba la VM con `Win32_ComputerSystem` (`diseño:399`), que no existe en Linux.
- **Corrección.**
  1. Un bloque **N-L**: LAB-01 a LAB-23 (en memoria) y LAB-28 en una VM Linux de la distribución de ADR-129, con el mismo oráculo y el mismo JSON, y la marca de plataforma en la evidencia.
  2. Guarda equivalente en Linux (`systemd-detect-virt` más el marcador de LS-11).
  3. Declarar un bloque **R-L** pendiente para cuando A construya el selector en Linux, donde no hay registro de Windows; PT-02 necesitará su equivalente [I].
  - Costo inferido: de 0,02 a 0,03 sp.
- **Responsable:** el diseño; B (VM Linux).

### LS-05 · Media · Modo sin CA fijada: las condiciones 3 y 4 no encajan con un certificado público
- **Riesgo.** Para el «certificado del cliente», el diseño aplica «las mismas condiciones 3 y 4» (`diseño:169-173`).
  - **Comodines:** `allowWildcards: false` rechaza `*.cliente.com`, habitual en los certificados públicos y de dominio.
  - **Varios SAN:** la condición 4 rechaza cualquier certificado con nombres fuera de la lista del QR (por ejemplo, `www` y `mail` en el mismo certificado).
  - **Sin aporte de seguridad:** la condición 4 compensa la debilidad de las NC de la CA propia (O-01), pero una CA pública no tiene NC y cualquier certificado fraudulento llevaría justo el nombre del sitio.
  - **Consecuencia:** RT-10 punto 3, el camino recomendado para clientes con muchos móviles, fallaría con certificados legítimos, y la presión iría a «aceptar errores de nombre», que RT-10 punto 5 prohíbe.
- **Corrección.**
  - **Sin CA fijada:**
    - condición 3 con comodín permitido solo en la etiqueta izquierda (RFC 6125) y sin CN;
    - **sin** condición 4;
    - si la presencia del comodín se considera un cambio de lo firmado, va como nota de lectura de RT-10 punto 5 para el Arquitecto Maestro.
  - **Con CA fijada:** sin cambios.
  - **Casos nuevos:** hoja de CA-S con comodín y hoja con 3 SAN en el modo público (aceptadas), y comodín en el modo con CA fijada (rechazado).
- **Responsable:** el diseño y A.

### LS-06 · Media · `NotBefore` y el reloj de los puestos
- **Riesgo.** Con hojas de 90 días y renovación cuando faltan 30 (H-11), cada sitio cambia de certificado cada 60 días.
  - Si `NotBefore` es la hora de emisión, un puesto o una estación con el reloj atrasado unos minutos, algo frecuente en los puestos de venta [I], recibe una hoja «aún no vigente» (`NotTimeValid`) en cuanto el servidor la publica.
  - El servicio la adopta en 5 min o menos (PT-02).
  - El efecto es una caída parcial recurrente que empuja a `IgnoreNotTimeValid`.
  - Ningún caso lo prueba: LAB-20 usa H-FUT, que está muy en el futuro.
- **Corrección.**
  - Contrato del verbo: `NotBefore` = emisión − 1 h (práctica habitual de las CA públicas [I]). Esto no alarga la vida útil, porque `NotAfter` sigue a 90 días de la emisión.
  - LAB-32 comprueba `NotBefore`.
  - LAB-38b: `VM-PUESTO` con el reloj 10 min por detrás durante la renovación; criterio: cero errores en la sonda y en la estación.
- **Responsable:** el diseño y A (verbo).

### LS-07 · Media · LAB-30 no mide el riesgo de O-05 y falta S/MIME
- **Riesgo.** H-CODE tiene `CN=Prueba` y no tiene SAN (`diseño:227`), y CA-A tiene NC.
  - Si Windows marca el sujeto con `HasNotDefinedNameConstraint` o compara el CN con las restricciones [I], la firma sale «no válida» **por las NC** y no por la falta de EKU en la CA. LAB-30 concluiría que no hay riesgo, y CA-AE «rechazaría» sin demostrar que el EKU es la causa.
  - Un atacante con la llave elegiría una hoja **dentro** de las NC.
  - O-05 menciona S/MIME, pero ningún caso lo mide.
- **Corrección.**
  1. **H-CODE-NC:** sujeto vacío, o CN igual a `srv-c01…`, con SAN `srv-c01…` y EKU `codeSigning`, emitida por CA-A y por CA-AE. Control: H-CODE emitida por CA-X (sin NC ni EKU) → `Valid`.
  2. **H-MAIL**, informativo: SAN `srv-c01…` más un `rfc822Name` de prueba y EKU `emailProtection`, emitida por CA-A y por CA-AE. Se verifica con `certutil -verify` y la política básica [I].
  3. **Criterio:** solo si H-CODE-NC con CA-A da `Valid` y con CA-AE no, Q-LAB-01 (a) está demostrada.
- **Responsable:** el diseño.

### LS-08 · Baja · Casos de ataque que faltan
Cada caso nuevo sigue el criterio general de la sección 6: si un cliente de GPOS NG acepta lo que debía rechazar, el hallazgo es Alto.

| Caso | Entrada | Esperado |
|---|---|---|
| N-A · Intermedia laxa | Raíz CA-N1 con NC `srv-c01…` y `pathLen = 1` → intermedia **sin NC**, o con NC que permite `www.banco-prueba.test` → hoja `www.banco-prueba.test` | Rechazo por las NC de la raíz. Necesario para el punto 2 de la sección 8 |
| N-B · Mismo SKI | CA-I2: mismo sujeto **y mismo SKI** que CA-A, otra llave; hoja de CA-I2; P-FIJADA con {CA-A} | Rechazo por firma. Demuestra que no se elige el emisor solo por el identificador |
| N-C · EKU de la hoja | Hoja **sin** extensión EKU; hoja con `anyExtendedKeyUsage` | `X509Chain` puede aceptarlas [I]; **el validador rechaza** (EKU explícito con `serverAuth`) |
| N-D · Otros tipos de nombre en el SAN | SAN `srv-c01…` más `URI` `https://www.banco-prueba.test/`; más `rfc822Name`; más `otherName` UPN | Registrar la cadena. **El validador rechaza** cualquier tipo distinto de `dNSName` o `iPAddress` (LS-09) |
| N-E · Extensión crítica desconocida | En la hoja; en la CA | Rechazo (`HasNotSupportedCriticalExtension` [I]) |
| N-F · IPv4 mapeada contra exclusiones | CA-A0 + hoja `::ffff:192.168.50.10` | Rechazo |
| N-G · Mayúsculas | SAN `SRV-C01.GPOSLAB.TEST` con las NC en minúsculas | Válida en la cadena y en el validador (DNS sin distinción de mayúsculas) |
| N-H · Punto final e IDN | URL `https://srv-c01.gposlab.test.:p`; SAN con punto final; SAN con U-label en `IA5String`; nombre en A-label | Comportamiento definido por LS-09: rechazo de la U-label y del SAN con punto final; URL con punto final normalizada o rechazada, nunca aceptada por una vía y rechazada por otra |
| N-I · CA fijada vencida o futura | CA-A vencida, y CA-A2 con `NotBefore` futuro, en `CustomTrustStore` | Rechazo |
| N-J · Raíz con el mismo SPKI y sin NC | Ver LS-03 | Rechazo |
| LAB-27b · Descarga necesaria | Hoja de una intermedia que no se entrega, con AIA `caIssuers` al escucha | `PartialChain`, **cero** peticiones. LAB-27 no lo prueba, porque su cadena está completa |
| LAB-29b · Rotación con el mismo DN | CA-A2 con el **mismo DN** que CA-A (la forma probable de la rotación) | Cada hoja construye contra su CA |
| LAB-35b · Respaldo heredado | La estación nueva ante una hoja cuyo SPKI de hoja estaba fijado (formato anterior) pero de CA-S o vencida | Rechazo (LS-10) |
| LAB-35c · Cambio de modo | El servidor pasa de la CA propia a un certificado del cliente | La estación y MAUI rechazan hasta volver a emparejar (falla cerrada) |
| LAB-37b · Escritura de la huella | La cuenta `NT SERVICE\GPOS.Api` intenta escribir la clave del registro | Denegado |
| LAB-41b · Huella de otra CA | Huella de una hoja válida de CA-S en `LocalMachine\My` | El selector no la adopta en el modo con CA propia |
| B-MEZCLA · Navegadores | Bloque B con H-MEZCLA, entrando por `srv-c01…` | Error en los tres. Demuestra que se comprueban **todos** los nombres y no solo el pedido |

- **Edge.** No recomiendo la opción barata de Edge con 4 casos (`diseño:340`, `:475`). Edge es el navegador por omisión de los puestos y, aunque comparte el verificador de Chromium, su almacén y su política difieren [I]. El ahorro es de unas 0,01 sp.
- **Costo de esta tabla:** inferido, de 0,01 a 0,02 sp.
- **Responsable:** el diseño.

### LS-09 · Baja · La condición 4 no define qué es un «nombre»
- **Riesgo.** «Todos sus nombres están en la lista del sitio» (`diseño:167`) no dice:
  - qué tipos de nombre cuentan;
  - cómo se comparan.
  Dos implementaciones (estación y MAUI, y Linux y Windows) podrían diferir.
- **Corrección (contrato):**
  1. Se admiten solo `dNSName` e `iPAddress`; cualquier otro tipo → rechazo.
  2. **DNS:** solo ASCII; se compara con `OrdinalIgnoreCase`. Una etiqueta no ASCII, un punto final en el SAN o un comodín → rechazo.
  3. **IP:** se compara por octetos. Una IPv4 mapeada en IPv6 → rechazo.
  4. **Host de la URL:** sin punto final. El validador lo normaliza o lo rechaza **antes** de pasarlo a `TargetHost` y a `MatchesHostname`, para que las dos comprobaciones vean el mismo nombre.
  5. El verbo aplica las mismas reglas a `NOMBRES_SERVIDOR` (LAB-33: añadir mayúsculas, punto final y no ASCII).
- **Responsable:** el diseño y A.

### LS-10 · Baja · F-02: la llave de servidor robada no caduca ante las estaciones
- **Riesgo.** Ver 4.3. Con el SPKI de la hoja fijado y la aceptación de errores de cadena:
  - una llave robada sirve después de vencer el certificado;
  - el atacante puede presentarla con una cadena cualquiera.
  Esto anula H-11 (90 días) para las estaciones.
- **Evidencia.** `src/GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:68-69`, `:72-73` y `:81`.
- **Corrección.**
  - Al aplicar PT-03, eliminar el camino «el SPKI fijado prevalece sobre los errores de cadena». No conservarlo como respaldo de transición.
  - Las estaciones se vuelven a emparejar (PT-03, «Cómo se migra»).
  - LAB-35b lo comprueba.
- **Responsable:** A (desarrollador-backend).

### LS-11 · Baja · Arnés: guardas, limpieza y redacción de la evidencia
- **Riesgo y correcciones:**
  1. **Guarda de VM.** El modelo «Virtual Machine» de WMI (`diseño:399`) es débil: también lo devuelve cualquier VM de desarrollo. Hay que añadir un marcador que solo crea `Preparar-Vm.ps1` (por ejemplo, `HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id`, igual a una variable de entorno de la sesión) y una lista de nombres de VM admitidos. `Preparar-Anfitrion.ps1` y `Adelantar-Reloj.ps1` comprueban el nombre del anfitrión o de la VM contra una lista y, si no coincide, se detienen sin tocar nada.
  2. **Nunca `CurrentUser\Root`.** Instalar ahí abre un diálogo modal de Windows, lo que choca con la regla de no abrir ventanas. Solo se usan almacenes `LocalMachine`, en una consola elevada.
  3. **Limpieza por marcador.** Toda CA y hoja del oráculo lleva un marcador, por ejemplo `O=GPOS-LAB-TLS`. Un `Limpiar-Laboratorio.ps1` retira todo lo marcado de:
     - `LocalMachine\Root`, `\CA` y `\My`;
     - las vinculaciones de HTTP.sys (`netsh http delete sslcert`);
     - las entradas de `hosts`;
     - la caché de URL de CryptoAPI (`certutil -urlcache * delete`).
     El dispositivo de pruebas comprueba que el estado está limpio **antes** de empezar. Al final de cada fase se restaura el punto de control base, que es la limpieza definitiva.
  4. **Procesos separados.** Los casos que modifican almacenes corren cada uno en su propio proceso, porque CryptoAPI guarda en caché las cadenas del motor por omisión [I] y LAB-24 (a) podría contaminar el caso siguiente.
  5. **Llaves de las CA de prueba.** Son efímeras: se destruyen después de emitir. Si hace falta conservarlas para el bloque B, se guardan como CNG no exportables en `VM-SRV`. Hay que dejarlo escrito: hoy solo se dice para las hojas (`diseño:137`).
  6. **Repositorio.** Añadir a `.gitignore` `*.p12`, `*.key`, `*.pem` (salvo que el proyecto ya los use) y `tests/laboratorio-adr090/salida/`. Hoy solo está `*.pfx` (`.gitignore:239`). La evidencia en bruto no va a `GPOS NG`.
  7. **Redacción antes de publicar en el área común.** `Recoger-Evidencia.ps1` no copia:
     - códigos de emparejamiento ni el `Secreto` de la estación;
     - tokens `disp+jwt`;
     - cadenas de conexión;
     - el contenido del almacén DPAPI de LAB-36, del que solo se registra la presencia y una huella.
     Además, se revocan los dispositivos de laboratorio al terminar. Hoy LAB-36 dice «lectura del almacén» (`diseño:300`) sin límites.
- **Responsable:** B (devops: puntos 1, 3 y 5 a 7) y A (qa: puntos 2 y 4).

### LS-12 · Baja · Descargas activas en el modo sin CA fijada
- **Riesgo.** `DisableCertificateDownloads = false` (`diseño:171`) hace que el cliente recupere por HTTP URL que trae un certificado todavía no validado. Además, en una red local sin Internet, cada conexión nueva espera el tiempo de recuperación [I].
- **Corrección.**
  - Descargas desactivadas también en este modo.
  - El paquete comprueba al importar el «certificado del cliente» que las intermedias están en `LocalMachine\CA` y que Kestrel envía la cadena completa (`SslStreamCertificateContext`) [I].
  - Caso LAB-31b: hoja pública con la intermedia enviada por el servidor y descargas desactivadas → válida.
- **Responsable:** el diseño, A (Kestrel) y B (paquete).

### LS-13 · Baja · Q-LAB-01 (a) frente a la sucesora y a `pathLen = 0`
- **Riesgo.**
  - Windows trata el EKU de una CA como límite de lo que emite [I]. Si el certificado cruzado o la sucesora de PT-04 llevan otro EKU, las hojas de la sucesora fallarían.
  - Con `pathLen = 0` en la vigente, una cadena hoja → cruzado → vigente viola la restricción, salvo que el cruzado sea «autoemitido» (mismo DN de sujeto y emisor, RFC 5280, 6.1.4) o que el cliente valide el cruzado aparte, como en PT-04, sin incluirlo en la cadena del saludo.
- **Corrección.**
  - Nota para el laboratorio de rotación y para el contrato de PT-04: la sucesora y el cruzado llevan un EKU igual o más estrecho, además de las NC.
  - El cruzado nunca va en la cadena del saludo.
  - LAB-29b cubre el mismo DN.
- **Responsable:** el diseño (sección 1, fuera de alcance, con remisión) y el Arquitecto Maestro (texto de PT-04).

### LS-14 · Baja · Lista de nombres del sitio: origen, actualización y cambios de nombre o de IP
- **Riesgo.**
  - **Actualización de la lista.** PT-07 suma la lista al QR, pero no dice cómo cambia. Si se actualiza por la conexión validada, reaparece H-05: quien tenga la llave del servidor la amplía.
  - **NC fijas.** Las NC quedan fijadas en la CA durante 10 años. Un cambio de IP del servidor (con IP en el SAN) o de un nombre exige una **CA nueva** y volver a distribuirla, no solo «reemisión con el verbo», como dice la tabla de riesgos de ADR-90 (ADR-090.md:181). Esto empuja a usar subredes o a quitar las NC.
- **Corrección.**
  1. La lista solo llega por el QR, por el alta manual o firmada por la CA (como PT-04).
  2. Al emparejar, el cliente comprueba que la lista está contenida en los subárboles `dNSName` e `iPAddress` de la CA fijada, con igualdad exacta.
  3. Nota de lectura en ADR-90:
     - un cambio de nombre o de IP del SAN es una rotación de CA;
     - se recomiendan nombres DNS estables por sitio (PT-03) y evitar IP en el SAN.
  4. Caso informativo en el bloque V: renombrar el servidor → el verbo se niega a emitir fuera de las NC.
- **Responsable:** el diseño, A y el Arquitecto Maestro.

### LS-15 · Baja · Bloque R y licencia por vigencia
- **Riesgo.**
  - La licencia por vigencia está construida en `feature/modelo-ng` (`src/GPOS.Api/Seguridad/ModoLicencia.cs`; `src/GPOS.Core/Sistema/Licencia/EstadosLicencia.cs`).
  - El reloj protegido devuelve el máximo con el reloj del sistema (`RelojProtegido.cs:14`).
  - Al adelantar a `T0+91` o `T0+95`, la licencia de laboratorio puede pasar a gracia o a solo consulta [I: depende de las fechas de la licencia que se cargue]. Las rutas operativas devolverían 403 y contaminarían los criterios «sin errores» de LAB-44 y LAB-48.
- **Corrección.**
  - La licencia de laboratorio tiene vigencia de al menos `T0+120 d`.
  - La sonda usa una ruta anónima (`/api/salud`) además de la operativa.
  - Un 403 de licencia se registra como evento ajeno al TLS.
  - Mencionarlo en F-06.
- **Responsable:** el diseño y B.

### LS-16 · Baja · Prueba de arquitectura por patrones
- **Riesgo.** Una lista de patrones (`diseño:177-182`) no detecta formas equivalentes:
  - `errores & ~SslPolicyErrors.RemoteCertificateNameMismatch`;
  - `TrustMode = System` con `CustomTrustStore` lleno;
  - una `ApplicationPolicy` vacía;
  - `ServerCertificateCustomValidationCallback` o `DangerousAcceptAnyServerCertificateValidator`;
  - añadir al `ExtraStore` o al `CustomTrustStore` certificados que llegan por la red.
- **Corrección.**
  - Un **único** validador compartido (MAUI, estación y Web) es el único lugar donde se permiten `X509Chain`, `X509ChainPolicy`, `SslPolicyErrors`, `RemoteCertificateValidationCallback`, `ServerCertificateCustomValidationCallback` y `X509VerificationFlags`.
  - La prueba de arquitectura prohíbe esos tipos en el resto del código de los clientes.
  - Dentro del validador, exige el literal `X509VerificationFlags.NoFlag` y `X509ChainTrustMode.CustomRootTrust` en la rama fijada.
  - Es más barato y más robusto que crecer la lista.
- **Responsable:** A (arquitecto-software).

### LS-17 · Baja · Inexactitudes de evidencia y una probabilidad optimista
- **Inexactitudes y correcciones:**
  - **F-03:** `UseHttps` sí aparece (`src/GPOS.Web/Program.cs:109`, `UseHttpsRedirection`). Decir: «sin `ListenAnyIP`, `ServerCertificate*` ni `UseHttps(`».
  - **F-05:** el `ConnectCallback` de `ReenvioReportes.cs:267` es de canalización con nombre, no de TCP a *loopback*.
  - **F-06:** citar también la implementación (`RelojProtegido.cs:88`, `:91` y `:275`) y el efecto en la licencia (LS-15).
  - **Sección 7:** `tests/GPOS.EnsayoImplantacion` **es** un proyecto (`GPOS.EnsayoImplantacion.csproj`), no una «carpeta sin proyecto».
  - **Sección 8:** «Baja [I]» para que Windows no aplique las NC de la raíz con `CustomRootTrust` (`diseño:432`) no tiene base. Usar «Media [I] hasta LAB-04 y LAB-05», como la hoja.
- **Responsable:** el diseño.

---

## 6. Controles bien diseñados

- **Política.** `CustomRootTrust` exclusivo, `NoFlag`, sin descargas, `NoCheck` justificado por RT-04 y la prohibición explícita de `Ignore*` y `AllowUnknownCertificateAuthority`.
- **Criterio de aceptación.** La política se mantiene y se cambia el perfil de la hoja cuando Windows marca algo (`diseño:164`); es la decisión correcta.
- **Nombres.** `MatchesHostname` sin comodines ni CN, más la condición 4 como defensa independiente de las NC (la base de O-01 y del punto 1 de la sección 8).
- **Controles negativos.** LAB-05 y LAB-52 están, y el autor se niega a recortarlos (`diseño:478`).
- **Oráculo.** Es independiente del verbo (`diseño:135`) y no comparte el escritor ASN.1.
- **Entorno.**
  - Red interna sin Internet durante los casos, que prueba que no hay descargas y aísla de AuthRoot.
  - Llaves de las hojas no exportables, sin PFX y sin contraseñas (ADR-44).
  - Solo la parte pública de las CA viaja a `VM-PUESTO`.
- **Bloque R.**
  - Contador monótono para la caché (LAB-46).
  - `HuellaAnterior` con falla cerrada (O-03).
  - Fallo inyectado en el verbo (LAB-43).
  - Puntos de control y prohibición de emitir documentos fiscales con el reloj adelantado.
- **Ejecución.** Fuera de la PC del propietario y de OSHIN-LEGION. El filtro oficial de la suite no cambia.

---

## 7. Remediaciones priorizadas

1. **Antes de publicar el diseño** (texto del autor, sin firma). Esfuerzo de redacción: medio día.
   - LS-01: LAB-23 en dos partes.
   - LS-02: justificación de `ExtraStore`, cadena de 2 elementos y LAB-18 con control.
   - LS-03: origen del DER de la CA y condición 2 por DER.
   - LS-04: bloque N-L y guarda de Linux.
   - LS-05: condiciones del modo público.
   - LS-06: `NotBefore` retroactivo y LAB-38b.
   - LS-07: H-CODE-NC, el control con CA-X y H-MAIL.
   - LS-09: definición de la condición 4.
   - LS-17: correcciones de texto.
2. **En la misma revisión del diseño, recomendado:**
   - LS-08 (casos nuevos);
   - LS-11 (guardas, limpieza y redacción);
   - LS-15 (licencia del laboratorio).
   - Costo de laboratorio inferido: de 0,03 a 0,05 sp más.
3. **Entregas a A, al construir:** LS-10, LS-12, LS-16 y los contratos de LS-03 y LS-09.
4. **Al Arquitecto Maestro:**
   - LS-13: EKU y certificado cruzado en el contrato de PT-04;
   - LS-14: nota de lectura sobre los cambios de nombre o de IP;
   - LS-05: el comodín en el modo público, si lo considera un cambio de RT-10 punto 5.

**Presupuesto.**
- El diseño estima el laboratorio completo entre 0,42 y 0,46 sp (`diseño:472`). Con estas correcciones quedaría entre **0,45 y 0,51 sp** [I]: de 0,10 a 0,16 sp sobre las 0,35 de ADR-90, es decir, de USD 150 a 320 a USD 1.500 a 2.000 por sp.
- La única rebaja que no debilita las pruebas es ejecutar Firefox ESR solo en los casos de NC (LAB-49 a LAB-58). Ahorra unas 0,01 sp. No recomiendo recortar Edge (LS-08).

---

## 8. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario). No hay hallazgos Críticos ni Altos. El diseño es sólido y proporcionado, y la política P-FIJADA es la correcta en lo esencial.

Recomiendo **no publicarlo ni empezar la fase 1 sin corregir LS-01 a LS-07, LS-09 y LS-17**. Varios casos (LAB-18, LAB-23, LAB-27 y LAB-30) podrían aprobar sin demostrar lo que dicen, y la política, tal como está escrita, dejaría a A tres huecos de contrato:
- el origen del ancla;
- el modo público;
- `NotBefore`.

### Supuestos
- El comportamiento citado con [I] no se verificó en esta sesión. En particular:
  - que CryptoAPI aplique las NC del ancla con `CustomRootTrust`;
  - que `SslStream` agregue al `ExtraStore` los certificados del saludo;
  - el trato de la hoja sin EKU;
  - el comportamiento de OpenSSL y de Java PKIX con el ancla;
  - el de Chromium y NSS con EKU y NC en raíces locales;
  - el punto final y las IDN en `MatchesHostname`.
- ADR-129 está aceptado, y su alcance (la Web, la API y la estación en Linux) hace que Linux entre en este laboratorio.
- Las fechas de la licencia de laboratorio (LS-15) no se conocen.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-seguridad-laboratorio-adr090.md`
- Supuestos: los de la sección 8 (comportamientos [I] de las bibliotecas, alcance Linux por ADR-129 y fechas de la licencia de laboratorio).
- Decisiones candidatas a ADR: ninguna nueva. Hay precisiones o notas de lectura de ADR-90 para el Arquitecto Maestro: LS-05 (comodín en el modo público, RT-10 punto 5), LS-13 (EKU y certificado cruzado en PT-04) y LS-14 (un cambio de nombre o de IP es una rotación de CA).
- Entregas a otros agentes:
  - arquitecto-software de C (autor del diseño): LS-01 a LS-09, LS-15 y LS-17;
  - arquitecto-software de A: contratos de LS-03, LS-09 y LS-16;
  - desarrollador-backend de A: LS-10 y LS-12 (Kestrel);
  - devops de B: LS-04 (VM Linux), LS-11 y LS-12 (paquete);
  - qa de A: LS-08 y LS-11 (puntos 2 y 4);
  - Arquitecto Maestro: LS-05, LS-13 y LS-14.
- Próximo paso recomendado: que el autor corrija el diseño con LS-01 a LS-07, LS-09 y LS-17 y lo publique; después, la fase 1 en las VM.

---

## Verificación de la versión 2

- **Fecha:** 2026-10-20.
- **Objeto:** `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`, versión 2, de 799 líneas (en adelante «v2», citado como `v2:línea`). No lo modifiqué.
- **Contraste:** ADR-129 (`origin/master` `45a9ab75`, líneas 23-24, 54 y 93) y `src/GPOS.Api/Program.cs:393-397` en `origin/feature/modelo-ng` (ruta anónima `/api/salud`), los dos [V].
- **Método:** solo lectura; no ejecuté nada.

### V.1 Dictamen final

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

- Todos los LS obligatorios y recomendados están atendidos **en la política y en el texto**, salvo uno:
  - **LS-03** queda abierto **en la prueba**: LAB-80 tiene un resultado esperado equivocado y no ejerce el ataque (LS-18).
- Las correcciones introducen cuatro observaciones nuevas, ninguna Crítica ni Alta:
  - una Media: **LS-18**;
  - tres Bajas: **LS-19**, **LS-20** y **LS-21**;
  - más una lista de detalles menores, también Baja: **LS-22**.

**Antes de publicar:** recomiendo corregir **LS-18** (reescribir LAB-80) y **LS-19** (criterios de LAB-18 (b) y LAB-71), que son cambios de texto de unos minutos. LS-20 a LS-22 pueden atenderse antes de ejecutar la fase 1, o como entregas a A.

### V.2 Estado de cada LS

| LS | Estado en la v2 | Comentario |
|---|---|---|
| LS-01 | **Cerrado** | LAB-23a en memoria y LAB-23b en la VM con CA-S instalada y control `System`; LAB-23b queda fuera de R-1 (`v2:334-335`, `:574-578`). Los resultados esperados son correctos |
| LS-02 | **Cerrado en la política; parcial en la matriz** | Cadena propia por conexión, `ExtraStore` vacío y longitud igual a 2 (`v2:188-196`): correcto. Pero LAB-18 (b) y LAB-71 esperan resultados que la cadena propia no puede dar (LS-19) |
| LS-03 | **Cerrado en la política; abierto en la prueba** | La regla del ancla por DER (`v2:175-186`, condición 2 en `:207`) es correcta. LAB-80 está mal planteado (LS-18). El contrato de alta tiene dos huecos (LS-20) |
| LS-04 | **Cerrado** | Bloque N-L con .NET y con la línea de órdenes de OpenSSL, guarda de Linux y R-L pendiente (`v2:367-397`). Las citas de ADR-129 son correctas (Ubuntu 24.04, punto 2 de bloqueo, C15). La segunda mitad de LAB-99 no prueba nada (LS-22) |
| LS-05 | **Cerrado, con observaciones** | Comodín solo a la izquierda, sin CN y sin la condición 4 en el modo público (`v2:218-226`); LAB-81. Faltan casos negativos y un mínimo de etiquetas, y la bajada de modo al dar de alta no está cubierta (LS-21) |
| LS-06 | **Cerrado** | `NotBefore` − 1 h (`v2:112-114`, `:239`), LAB-20b (correcto: H-AHORA rechazada y H-DNS válida con el reloj 10 min por detrás), LAB-32 y LAB-38b. Falta el margen también en la CA (LS-22) |
| LS-07 | **Cerrado** | H-CODE-NC dentro de las NC, control CA-X y criterio «solo si CA-A da `Valid` y CA-AE no» (`v2:360`). LAB-30b necesita el OID de correo en `certutil` (LS-22) |
| LS-08 | **Cerrado, con ajustes** | Están todos los casos pedidos y Edge va completo. Hay ajustes en LAB-71 (LS-19), LAB-72, LAB-75 y LAB-80 (LS-18 y LS-22) |
| LS-09 | **Cerrado, con una precisión** | Definición de «nombre» completa (`v2:209-214`). En LAB-78 recomiendo rechazar el punto final en lugar de normalizarlo (LS-22) |
| LS-10, LS-12, LS-13, LS-14, LS-16 | **Entregados** (sección 11) | Es el tratamiento que pedí. LS-13 queda bien declarado en Q-LAB-01 (a) |
| LS-11 | **Cerrado, salvo Linux** | Cuatro guardas, solo `LocalMachine`, limpieza por marcador, un proceso por caso, `.gitignore` y redacción de la evidencia (`v2:514-552`). Falta la limpieza de `update-ca-certificates` en `VM-LNX` (LS-22) |
| LS-15 | **Cerrado** | Licencia hasta `T0+120 d`, sonda por `/api/salud` [V] y 403 registrado aparte (`v2:143`, `:413-417`) |
| LS-17 | **Cerrado** | Correcciones de F-03, F-05, F-06 y de la sección 7.2 (`instalador/Demo/scripts/` existe [V]); probabilidad «Media [I]» |

**Verificación de los cálculos de la sección 9:**
- 0,39 + (0,08 a 0,12) = 0,47 a 0,51 sp.
- Exceso sobre 0,35 sp: 0,12 a 0,16 sp, es decir, de USD 180 a 320.

Son correctos y coinciden con mi estimación.

### V.3 Hallazgos nuevos

#### LS-18 · Media · LAB-80 no ejerce el ataque de LS-03 y su resultado esperado es erróneo
- **Riesgo.** LAB-80 presenta **H-DNS**, que es una hoja **dentro** de las NC, con CA-SPKI en la cadena del saludo, y espera «Rechazo (condición 2: el DER no coincide)» (`v2:364`).
  - Con la política de la v2, el validador construye su propia cadena **sin** `ExtraStore`. Encuentra el DER guardado de CA-A y la firma de H-DNS verifica, porque es la misma llave. La raíz es idéntica por DER, así que **acepta**, y es lo correcto: una hoja legítima con un certificado de más en el saludo.
  - Por tanto, el caso fallaría con una implementación buena. Peor aún: animaría a añadir una regla ad hoc para «aprobarlo».
  - Lo que LS-03 tiene que demostrar es otra cosa: que una hoja **fuera** de las NC de CA-A, firmada con la llave filtrada, no se acepta aunque el saludo traiga un ancla sin NC con la misma llave. Así como está, LS-03 queda **sin prueba**, y el caso está en la lista de R-1 (`v2:574`).
- **Corrección.**
  - **LAB-80a:** H-FUERA, o una hoja con SAN `a.srv-c01…` fuera de la lista, firmada con la llave de CA-A, más CA-SPKI en el saludo y el DER de CA-A guardado → **rechazo** (NC de CA-A en la cadena propia, o condición 4).
  - **LAB-80b, control:** la misma hoja verificada con CA-SPKI como ancla → la cadena se acepta. Demuestra lo que se descarta.
  - **LAB-80c:** H-DNS con CA-SPKI en el saludo → **se acepta**. Demuestra que el saludo no cambia el ancla.
  - Ajustar R-1 en consecuencia.
- **Responsable:** el diseño.

#### LS-19 · Baja · LAB-18 (b) y LAB-71 no son coherentes con la cadena propia del validador
- **Riesgo.** La cadena del validador **no** ve las intermedias del saludo (`v2:195`).
  - **LAB-18 (b)** espera que el validador rechace «por `pathLen` **y** por longitud distinta de 2» y, a la vez, que no valga un rechazo por `PartialChain` (`v2:328`). Pero la cadena propia sale `PartialChain` (Sub-A no está), y la marca de `pathLen` solo puede aparecer en la cadena de `SslStream` (`RemoteCertificateChainErrors` [I]).
  - **LAB-71** («Rechazo por las NC de la raíz», `v2:336`) solo demuestra algo si Sub-N se entrega en el `ExtraStore` de una cadena de prueba del oráculo.
- **Corrección.**
  - **LAB-18 (b):** se espera `sslPolicyErrors = RemoteCertificateChainErrors`, la cadena propia `PartialChain` y el validador rechaza. La exigencia «no vale `PartialChain`» queda solo para (a).
  - **LAB-18 (a):** la marca `InvalidBasicConstraints` «en cualquier elemento» [I], no necesariamente en el de CA-A.
  - **LAB-71:** se ejecuta con `X509Chain` del oráculo y Sub-N en `ExtraStore`. Criterio: `Build = false` con una marca de NC (no `PartialChain`), más el control. El validador, además, rechaza por longitud.
- **Responsable:** el diseño.

#### LS-20 · Baja · El contrato de alta del ancla (LS-03) tiene dos huecos
1. **El perfil validado no basta si la llave ya está filtrada.**
   - El cliente comprueba el SPKI y que haya «NC crítica con al menos un `dNSName`» (`v2:176-182`).
   - Durante el alta por la ruta de solo lectura, quien tenga la llave de la CA puede servir una autofirmada con el **mismo SPKI** y NC **amplias**, por ejemplo con `dNSName` `test` o con `iPAddress` `0.0.0.0/0` permitida, y quedar fijada.
   - **Corrección:**
     - al dar de alta, los subárboles permitidos de la CA deben ser **exactamente** los nombres de la lista del sitio que trae el QR, más la exclusión de `/0` si no hay IP, y el EKU si se firma Q-LAB-01;
     - opcionalmente, el QR lleva el SHA-256 del **DER** además del SPKI.
     - El alta manual (PT-08, solo SPKI) depende de la primera regla.
2. **Orden de las operaciones.** La ruta de la CA se consulta en una conexión todavía sin validar.
   - Ahí **no** debe viajar ninguna credencial. El código de emparejamiento de la estación (`ClienteDispositivo.cs:130`) y el inicio de sesión de MAUI solo se envían por una conexión **nueva**, validada con P-FIJADA después de guardar el ancla.
   - Si no, un atacante en la red durante el alta se lleva el código, aunque el cliente rechace su CA después.
   - **Caso nuevo:** alta contra un servidor impostor → el cliente rechaza la CA y el impostor no recibe el código.
- **Responsable:** A (arquitecto-software, SD-10 v2); el diseño añade el caso.

#### LS-21 · Baja · Modo sin CA fijada: casos negativos del comodín y bajada de modo
- **Lo que falta en LAB-81** (`v2:365`). Hoy solo tiene casos positivos. Faltan:
  - un comodín parcial (`f*.cliente-prueba.test`);
  - un comodín sobre el apex (`cliente-prueba.test` contra `*.cliente-prueba.test`);
  - un comodín sobre dos niveles (`a.b.cliente-prueba.test`);
  - un comodín con solo dos etiquetas (`*.test`);
  - un host de URL que es una IP ante un SAN con comodín.

  Todos deben rechazarse.
- **Regla propia.** `MatchesHostname` no consulta la lista de sufijos públicos [I]. Exigir al menos dos etiquetas después del comodín (`*.a.b`) cuesta poco. En el modo `System`, una raíz corporativa del almacén podría emitir `*.test`.
- **Bajada de modo.** RT-10 punto 4 exige la huella en el alta manual, pero el modo público «no fija nada».
  - Si el alta manual sin huella activa el modo público, un usuario o un atacante que lo induzca deja un MAUI con CA propia validando contra **todo** el almacén del sistema.
  - **Regla:** el modo lo fija solo el QR, o una opción explícita «certificado del cliente» que ve el técnico.
  - **Caso nuevo:** alta manual sin huella contra un servidor con CA propia → se rechaza.
  - Va con la entrega de LS-05 al Arquitecto Maestro y a A.
- **Responsable:** el diseño (casos) y A (reglas).

#### LS-22 · Baja · Detalles menores

| Detalle | Corrección |
|---|---|
| LAB-99, segunda mitad: «CA-SPKI con `-CAfile` CA-A» no tiene un resultado definido. Lo más probable es `X509_V_ERR_INVALID_PURPOSE`, porque la KU de la CA no sirve para `sslserver` [I], y no prueba nada | Sustituir por «H-FUERA con `-CAfile` CA-SPKI → `OK`» (informativo: muestra por qué se fija el DER) |
| LAB-72 espera «rechazo por firma» | CryptoAPI puede descartar al candidato y dar `PartialChain` [I]. El criterio debe ser «rechazo» |
| LAB-75 con CA-CRIT: es dudoso que CryptoAPI revise las extensiones críticas del **ancla** [I] | Para la cadena, CA-CRIT es informativo. La validación del perfil al dar de alta (sección 4.1) debe rechazar una CA con extensiones críticas desconocidas |
| LAB-30b con «la política básica»: `certutil -verify` no comprueba el uso de correo si no se le pide [I] | Pasar `1.3.6.1.5.5.7.3.4` como lista de políticas de aplicación |
| LAB-78: normalizar el punto final de la URL obliga a hacerlo **antes** de crear la petición, porque `SocketsHttpHandler` toma `TargetHost` de la URI | Más simple y en falla cerrada: guardar la URL sin punto final y **rechazar** una URL con punto final |
| `NotBefore` − 1 h solo en las hojas | Aplicarlo también a la CA, porque un puesto atrasado rechazaría una CA recién creada; LAB-32 lo comprueba |
| Limpieza en `VM-LNX`: LAB-24-L a LAB-26-L instalan raíces con `update-ca-certificates` (`v2:377`), pero solo hay `Limpiar-Laboratorio.ps1` | Añadir `limpiar-laboratorio.sh`, que retire lo marcado de `/usr/local/share/ca-certificates/` y vuelva a ejecutar `update-ca-certificates`, más la restauración del punto de control |
| Marcador en las hojas de sujeto vacío, «en un campo propio de la extensión de notas» (`v2:157`) | Debe ser una extensión **no crítica**; si no, todos los casos fallan por LAB-75. Alternativa: limpiar por la lista de huellas registrada al crear |
| Nombres `*.cliente-prueba.test` de LAB-81 | Añadirlos a `hosts` (sección 3) |

### V.4 ¿Las correcciones introducen riesgos nuevos?

- **Comodín en el modo público (LS-05).**
  - El cambio es correcto y no debilita el modo con CA fijada, que sigue sin comodines (rechazo de H-COMODIN en LAB-81).
  - Introduce dos riesgos acotados: la falta de un mínimo de etiquetas y la bajada de modo en el alta manual (LS-21).
  - Si el Arquitecto Maestro considera que el comodín cambia RT-10 punto 5, la regla técnica ya está bien delimitada para la nota de lectura.
- **Raíz por DER (LS-03).**
  - La regla es correcta y cierra el ataque en la conexión.
  - Desplaza el riesgo al **alta** (LS-20): NC amplias con el mismo SPKI, y credenciales enviadas por la conexión sin validar.
  - Su caso de prueba está mal planteado (LS-18).
- **Cadena propia del validador (LS-02).** Es correcta. Su efecto colateral son los criterios incoherentes de LAB-18 (b) y LAB-71 (LS-19).
- **Sonda con ruta operativa (LS-15).** La sonda maneja un token. Está cubierta por la redacción de la evidencia (`v2:540-546`).
- **Bloque N-L.**
  - Instala raíces en el almacén de la distribución de la VM Linux, sin limpieza propia (LS-22).
  - La guarda de cuatro condiciones también rige ahí (`v2:374`, `:514-520`): correcto.

### V.5 Opinión sobre Q-LAB-03 (presupuesto)

**De acuerdo con (a)**, con un matiz barato.

- **El exceso está justificado.**
  - Las cifras, verificadas, son de 0,12 a 0,16 sp: de USD 180 a 320 sobre las 0,35 de ADR-90.
  - Casi todo viene de controles que evitan aprobados sin prueba y de casos de ataque que faltaban.
  - La opción (c) quitaría LAB-45, la única prueba de que un vencimiento sin renovar se detecta y se recupera (el riesgo Alto de H-02), y la mitad de los navegadores. No la recomiendo.
- **Ejecutar N-L con el tramo Linux es coherente con ADR-129, punto 2:** una garantía sin equivalente aprobado **bloquea** la función en Linux (ADR-129.md:24 [V]). Hasta entonces no hay validador Linux que probar contra el producto.
- **Matiz.** El validador único lo escribe A **antes** del tramo Linux. Si OpenSSL se comporta distinto, por ejemplo con el CN frente a las NC (LAB-95) o con la traducción de las marcas, el validador tendría que cambiar después.
  - Propongo ejecutar ya, en la fase 1, solo el **subconjunto en memoria** de N-L (LAB-01-L a LAB-23a-L, LAB-28-L y LAB-71-L a LAB-80-L). Reutiliza el oráculo y la misma `dotnet test` en una VM Ubuntu sin escritorio.
  - Costo inferido: unas 0,01 sp.
  - LAB-91 a LAB-99 (línea de órdenes), LAB-24-L a LAB-26-L (almacén) y R-L quedan para el tramo Linux.
  - Así, A conoce el comportamiento de OpenSSL antes de fijar el validador, por un tercio del costo de la opción (b).

### Cierre de la verificación
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-seguridad-laboratorio-adr090.md` (sección añadida al final).
- Supuestos: los comportamientos [I] citados en V.3 (cadena de `SslStream` frente a la propia, `PartialChain` frente a la firma, extensiones críticas del ancla, `certutil` y las políticas, `MatchesHostname` y los sufijos públicos, propósito de OpenSSL).
- Decisiones candidatas a ADR: ninguna nueva. La regla de bajada de modo de LS-21 se suma a la entrega de LS-05 al Arquitecto Maestro.
- Entregas a otros agentes:
  - arquitecto-software de C: LS-18, LS-19, LS-22 y los casos de LS-20 y LS-21;
  - arquitecto-software de A: contratos de LS-20 (subárboles exactos y orden del alta) y de LS-21;
  - Arquitecto Maestro: LS-21, junto con LS-05.
- Próximo paso recomendado: corregir LAB-80 (LS-18) y los criterios de LAB-18 (b) y LAB-71 (LS-19), publicar la v2 y llevar Q-LAB-01 a Q-LAB-03 a la firma.
