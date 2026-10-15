# Informe de Seguridad: PR #34, CR «H-17 v2» (`CifradorAnillo` y recuperación anclada)

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #34, rama `a/cr-h17-v2` @ `aee7f718` (worktree `GPOS-NG-cr`), contra `feature/modelo-ng`. Son 19 archivos y +2 408 líneas.

**Contrato:** H-17 v2 (hoja de firma de seguridad 3.1.2); `[PSF]` 4C.2 a 4C.5, A3, CV-05 y D-3; ADR-77 (N-14, N-15, PA-77-3); blueprint de la licencia v2.7 §4.1 «CR».

**Método:** no compilé ni ejecuté pruebas. Las cifras que menciono (38 pruebas nuevas, 222/222 de arquitectura en Release) son las que declara el PR y no las reproduje.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Sobre criptográfico y reglas puras | `src/GPOS.Criptografia/Anillo/CifradorAnillo.cs`, `ConformidadAnillo.cs` |
| Integración con Data Protection, decorador CV-05 y heredadas | `src/GPOS.Core/Infraestructura/Anillo/AnilloDataProtection.cs` |
| Ancla D-3 | `AnclaRecuperacionAnillo.cs` |
| N-14 al arrancar | `ComprobacionAnillo.cs` |
| Certificados | `OrigenCertificadosAnillo.cs` |
| Configuración y N-15 | `src/GPOS.Core/Infraestructura/ProteccionDatosInstalacion.cs` |
| Verbos de `GPOS.Migracion anillo` | `src/GPOS.Migracion/Anillo/*.cs` |

**Quién puede escribir en la carpeta del anillo**, según ADR-77: SYSTEM, Administradores y la identidad del servicio de la API. Además, cualquier camino que restaure esa carpeta desde un respaldo, y quien la cree si nadie le pone la DACL (AN-03).

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| AN-01 | **Media** (diseño) | El sobre da confidencialidad pero no autenticidad: cualquiera que pueda escribir en la carpeta y tenga las dos públicas inyecta una llave «conforme» que pasa a ser la predeterminada. El decorador admite además llaves con otra recuperación u otro principal |
| AN-02 | **Media** | La lista de heredadas (`heredadas-dpapi.json`, con su `MigradaUtc`) no está autenticada y vive en la misma carpeta, y nada impide que una heredada sea la llave predeterminada |
| AN-03 | **Media** | La carpeta del anillo se crea con `Directory.CreateDirectory` (DACL heredada) y N-14 no comprueba su dueño, su DACL ni si es un punto de reanálisis |
| AN-04 | Baja | El AAD no liga el id de la llave (desviación declarada): el sobre de una llave antigua o revocada puede reaparecer bajo otro id y otras fechas |
| AN-05 | Baja | En Release, sin `CertificadoServidor` se vuelve en silencio a DPAPI, y N-14 da «Inactivo». Contradice A3 |
| AN-06 | Informativa | El ancla se protege con el mismo anillo que ancla (circular), y `--cambiar-recuperacion` depende de la alerta a GSF (C-05 pendiente) |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Hallazgo** AN-03 (DACL de la carpeta) |
| A02 Criptografía | **Bien:** AES-256-GCM, RSA-OAEP-SHA256 ≥ 2048 bits, sin PKCS#1 v1.5 ni `EncryptedXml`, todo aprobado por FIPS. **Observación** AN-01/AN-04 sobre la autenticidad |
| A03 Inyección | **Bien:** XML sin DTD ni resolutor; consultas parametrizadas |
| A04 Diseño inseguro | **Hallazgos** AN-01 y AN-02 |
| A05 Configuración | **Hallazgos** AN-03 y AN-05; N-15 está bien |
| A06 Componentes | **No aplica** (solo la biblioteca base y Data Protection) |
| A07 Autenticación | **No aplica** directo. La API autentica con JWT, no con Data Protection; el comprobante `CerrarSesionAnterior` sí usa Data Protection (AN-01) |
| A08 Integridad | **Hallazgos** AN-01, AN-02 y AN-04 |
| A09 Registro y monitoreo | **Bien:** eventos del anillo con `EventId`; la bitácora y las alertas llegan con C-05 |
| A10 SSRF | **No aplica** |

---

## 4. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| AES-256-GCM | La llave de datos (256 bits) y el nonce (96 bits) son **nuevos en cada sobre** (`RandomNumberGenerator`), así que no puede repetirse un nonce bajo la misma llave. Etiqueta de 128 bits; la llave y el texto en claro se borran de memoria | `CifradorAnillo.cs:85-107` |
| RSA-OAEP-SHA256 a dos destinatarios | El principal y la recuperación son distintos (no puede ser el mismo certificado), con ≥ 2048 bits. Al abrir se comprueba el largo de la envuelta y que la llave de datos sea de 32 bytes | `:15-21, 82-83, 123-130, 154-156` |
| AAD | `"GPOS.Anillo.v1\|p=…\|r=…"`: cambiar o quitar un destinatario rompe la etiqueta. **No** liga el id de la llave (AN-04) | `:158` |
| Lectura del sobre | Estructura cerrada (versión, atributos contados, orden y rol de los destinatarios, tamaños). El XML interno se lee con `DtdProcessing.Prohibit` y `XmlResolver = null` | `:160-215` |
| Ancla `Licencia.HuellaAnclada` | Va con MAC de Data Protection, con un propósito propio, clave y versión. Si no verifica, la situación es `NoVerifica` y no se crean llaves. `--anclar` se niega si hay llaves conformes envueltas para otra recuperación | `AnclaRecuperacionAnillo.cs`; `MantenimientoAnillo.cs:71-83` |
| Cifrador (D-3) | No crea llaves sin un ancla comprobada, ni con una recuperación configurada distinta de la anclada (falla del lado seguro) | `AnilloDataProtection.cs:75-93` |
| Decorador CV-05 | Descarta en cada lectura las llaves sin proteger, con otro descifrador o con un sobre mal formado. **Solo comprueba la forma**: AN-01 | `:132-150`; `ConformidadAnillo.cs:267-298` |
| Heredadas DPAPI | Se admiten solo con id en la lista, descifrador DPAPI y activación ≤ `MigradaUtc`. La lista no está autenticada: AN-02 | `AnilloDataProtection.cs:169-203` |
| N-14 al arrancar | Comprueba los certificados (privada, tamaño y vigencia), la conformidad, el ancla con un proveedor de solo lectura, D-3 sobre todas las llaves activas y crea una llave conforme si falta. Es de tipo I: no detiene la API (según la especificación). No revisa la DACL de la carpeta (AN-03) | `ComprobacionAnillo.cs` |
| N-15 en Release | `DpapiMaquina = true` se rechaza en Release y no se combina con el anillo. Ver AN-05 | `ProteccionDatosInstalacion.cs:226-233` |
| Verbos | Todos exigen acta y motivo. `--revocar-heredadas` solo revoca si ningún secreto conocido sigue con ellas. `--cambiar-recuperacion` reprotege antes de revocar las llaves viejas y no revoca si hubo fallos. `--migrar` no revoca nada | `MantenimientoAnillo.cs` |
| Frontera Criptografía / Core | Verificada: `GPOS.Criptografia/Anillo` solo usa la biblioteca base (XML en memoria, sin E/S de archivos ni almacenes), y la prueba CR-07 sigue pasando. Certificados, disco, base y Data Protection quedan en Core | `CifradorAnillo.cs:9-11`; `AnilloArquitecturaTests` |
| Recuperación solo pública en el servidor | Si el `.cer` de recuperación trae privada, se rechaza | `OrigenCertificadosAnillo.cs:328-335` |

---

## 5. Hallazgos

### AN-01 · Media (diseño) · El anillo no tiene autenticidad frente a quien puede escribir en la carpeta

- **Riesgo:** el `CifradorAnillo` da confidencialidad, no autenticidad. Las públicas del servidor (en `LocalMachine\My`) y de recuperación (el `.cer`) son, por definición, legibles. Cualquiera que pueda escribir en la carpeta puede crear un elemento `key` con un `masterKey` que él elige, envuelto para el servidor y para la recuperación **anclada**. El decorador lo clasifica como `Conforme`, D-3 no lo detecta, y como Data Protection toma como predeterminada la llave de activación más reciente, desde ese momento todo lo nuevo se protege con una llave que el atacante conoce. Consecuencias:
  - **Con escritura en la base**, falsifica cualquier valor protegido: el ancla, las filas con MAC de la licencia (`Gracias`, `SecMax`, `PisoNivelFirma`, `RegresosNivel`), la fila del reloj de H-16 y el comprobante `GPOS.Login.CerrarSesionAnterior`.
  - **Con lectura de la base**, descifra los secretos que se protejan o reprotejan a partir de entonces.
  - **Variante peor:** si la llave inyectada lleva la recuperación **del atacante**, N-14 la detecta al siguiente arranque (`AnilloRecuperacionCambiada`), pero el decorador la **sigue admitiendo**, así que hasta que alguien actúe todo lo nuevo se puede abrir con el certificado del atacante. El objetivo declarado de CV-05 («una llave inyectada con activación futura no llega a ser la predeterminada», `[PSF]` 4C.3) solo se cumple con las llaves inyectadas **sin proteger**.
  - El texto firmado solo contempla la llave «sin proteger o con otro descifrador» (`[PSF]` 4C.3, punto 514), así que el código cumple lo firmado. El hueco es de diseño.
- **Evidencia:** `ConformidadAnillo.cs:282-294` (conforme = descifrador y forma); `AnilloDataProtection.cs:132-150` (el decorador no mira el principal ni la recuperación); `CifradorAnillo.cs:56-59` (el desarrollador lo declara).
- **¿Firmar las llaves o basta la DACL de ADR-77?** **La DACL sola no basta**, por tres motivos:
  1. Entre quienes escriben está la identidad de la API, así que un error de escritura de archivos en la API (adjuntos, exportaciones) se convierte en control del anillo.
  2. Restaurar la carpeta desde un respaldo manipulado (Backup Tool N-01) inyecta llaves sin tocar ninguna DACL.
  3. La DACL hoy ni siquiera se garantiza (AN-03).
  
  Firmar no protege frente a un administrador ni frente a código ejecutándose como la API, que pueden usar la privada del servidor; eso es inevitable. Sí cierra los tres casos anteriores.
- **Remediación, en dos escalones:**
  1. **Mínimo, ahora (≈ 0,1 dp):** que el decorador descarte, además, toda llave conforme cuya **recuperación** no sea la anclada (el ancla ya está en memoria en `EstadoAnclaAnillo`; mientras no haya ancla, solo con la configurada) o cuyo **principal** no sea el certificado configurado ni uno de los anteriores admitidos durante una renovación (PFS-07). Con eso cae la variante peor.
  2. **Recomendado, antes de Avanzada o de la primera licencia de pago (≈ 0,4 dp más devops):** cada llave nueva lleva una **firma RSA-PSS-SHA256 con la privada del servidor** sobre la forma canónica de (`id`, `creationDate`, `activationDate`, `expirationDate`, sobre), en un elemento propio dentro del `key` (el `IXmlEncryptor` no ve el id, pero el decorador puede añadir y comprobar la firma en `StoreElement` y `GetAllElements`). El decorador descarta toda llave conforme sin una firma válida de un principal admitido. Así se cierran AN-01 (salvo frente a un administrador o a código como la API) y AN-04. Requisito de devops: que el certificado del servidor admita `digitalSignature` además de `keyEncipherment`. Separar llaves es lo deseable, pero un segundo certificado en el TPM cuesta más y se puede dejar como alternativa. Todo es aprobado por FIPS (FIPS 186-5).
  3. **Alternativas descartadas:**
     - Una lista de ids en una tabla de solo inserción: ata cada lectura de Data Protection a que SQL esté disponible, y una caída de la base dejaría a la API sin anillo.
     - Un HMAC: no hay ningún secreto fuera del propio anillo, así que sería circular.

### AN-02 · Media · Lista de heredadas sin autenticar y heredada que puede ser predeterminada

- **Riesgo:**
  - `heredadas-dpapi.json` es JSON en claro dentro de la carpeta escribible. Su `MigradaUtc` es la **única** defensa contra que se cuele una heredada («activación posterior a la migración = inyectada»), y quien escribe la lista también la fija.
  - Una llave protegida con DPAPI **de máquina** la puede fabricar cualquier proceso local, sin certificados. Basta con declararla en la lista con `MigradaUtc` en el futuro.
  - Además, nada impide que una heredada sea la predeterminada: «se leen y no protegen nada nuevo» depende solo de que la llave conforme creada en la migración tenga una activación más reciente.
- **Evidencia:** `AnilloDataProtection.cs:169-197`; `ConformidadAnillo.cs:295-296`; `MantenimientoAnillo.cs:100`.
- **Remediación (≈ 0,1 dp):**
  1. Guardar la lista y su `MigradaUtc` fuera de la carpeta: en una fila de `Configuracion` con MAC (por ejemplo, dentro de la fila del ancla o en una propia) o firmada como en AN-01.
  2. Que el decorador devuelva cada heredada con `expirationDate = mín(original, MigradaUtc)`. Una llave expirada sigue sirviendo para descifrar, pero Data Protection nunca la toma como predeterminada, y eso cumple «nunca protegen nada nuevo» por construcción.

### AN-03 · Media · La carpeta del anillo se crea sin una DACL protegida y no se comprueba

- **Riesgo:** `Registrar` crea la carpeta con `Directory.CreateDirectory(carpeta)`, que hereda la DACL del padre. Bajo `%ProgramData%`, el grupo Usuarios puede crear archivos en las subcarpetas por herencia. Si la carpeta la crea la API o `GPOS.Migracion` (y no el instalador), un **usuario local estándar** entra en el grupo de «escritores» y puede usar AN-01 y AN-02. N-14 no comprueba el dueño, la DACL ni si la carpeta es un punto de reanálisis. Compárese con `AlmacenLicenciaDisco`, que sí crea con una DACL protegida.
  - **Sin verificar:** la ubicación por omisión de la carpeta depende de la configuración del instalador. El hallazgo aplica siempre que la carpeta quede bajo una raíz heredable.
- **Evidencia:** `AnilloDataProtection.cs:224`; `ComprobacionAnillo.cs` (sin comprobación de DACL).
- **Remediación (≈ 0,1 dp más devops):**
  1. Crear la carpeta con una DACL protegida en una sola operación (SYSTEM, Administradores e identidad del servicio, sin herencia), como hace `AlmacenLicenciaDisco.SeguridadCarpeta`.
  2. Comprobarla en N-14: dueño Administradores o SYSTEM, DACL protegida y esperada, sin `ReparseDisposition`. Si no cumple: `AnilloCarpetaNoConforme`, no se crea ninguna llave y, en Estricto, no se arranca.
  3. El instalador la prepara según ADR-77 (punto 4).

### AN-04 · Baja · El AAD no incluye el id de la llave

Quien escribe en la carpeta puede copiar el `encryptedSecret` de una llave **antigua o revocada** dentro de otro elemento `key`, con otro id y otras fechas: el AAD (solo las huellas) lo acepta. El material de una llave que se dio por retirada vuelve como activa. Exige los mismos privilegios que AN-01, que da más. Se cierra con la firma de AN-01 (paso 2), que cubre el id y las fechas. Sin la firma, queda como residual declarado.

### AN-05 · Baja · Release sin certificado vuelve a DPAPI en silencio

Sin `GPOS:DataProtection:Anillo:CertificadoServidor`, una compilación Release usa DPAPI del usuario o la ubicación por omisión, y N-14 devuelve `Inactivo` sin avisar. A3 dice que el `CifradorAnillo` rige «en los dos perfiles» y que «un certificado que falte sigue siendo un fallo de arranque en cualquier perfil». El DEMO necesita la excepción (PA-77-3).
- **Evidencia:** `ProteccionDatosInstalacion.cs:229-244`.
- **Remediación (≈ 0,05 dp):** en Release, exigir el certificado salvo con un indicador explícito de DEMO, que Estricto rechaza. Registrar `AnilloInactivo` como crítico.

### AN-06 · Informativa

- El ancla se protege con el anillo que ancla. Resiste a quien solo escribe en la base, pero no a quien domina el anillo (AN-01). Las otras dos copias (el acta y el registro de GSF) son el control independiente, y su comparación automática depende de C-05 y de la alerta a GSF, todavía pendientes.
- `--cambiar-recuperacion` es el camino legítimo y lo ejecuta un administrador. Su control es el acta más la alerta a GSF. Hasta C-05, conviene que el verbo exija una confirmación interactiva y deje el evento en el registro de Windows.

---

## 6. Controles bien implementados

- **Construcción del sobre:** llave de datos y nonce nuevos en cada sobre, OAEP-SHA256 sin PKCS#1 v1.5, borrado de memoria, lectura cerrada del sobre y XML interno sin DTD.
- **D-3 en el cifrador:** ninguna llave nueva sin un ancla verificada, ni para una recuperación distinta de la anclada.
- **N-14:** comprueba con un proveedor de solo lectura (sin el ciclo de «leer obliga a crear») y crea una llave conforme si falta.
- **N-15** en Release.
- **Recuperación sin privada en el servidor.**
- **Verbos prudentes:** con acta, reprotección antes de revocar y revocación solo tras verificar.
- **Frontera** Criptografía / Core limpia y vigilada por una prueba de arquitectura.

---

## 7. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | AN-03, AN-01 (escalón 1), AN-02 | Antes de Estricto o de la primera instalación de producción con el anillo | ≈ 0,3 dp más devops |
| 2 | AN-01 (escalón 2: firma RSA-PSS), que cierra AN-04 | Antes de Avanzada o de la primera licencia de pago; requiere un ADR | ≈ 0,4 dp más devops |
| 3 | AN-05 | En este PR o en el seguimiento | ≈ 0,05 dp |
| 4 | AN-06 | Con C-05 | — |

---

## 8. Recomendación

**PR #34: Aprobado con observaciones.**

No hay hallazgos Críticos ni Altos. La criptografía es correcta, cumple FIPS y no hay nada casero. El código cumple el texto firmado de H-17 v2. Los tres Medios vienen de que la carpeta del anillo es la única frontera de autenticidad. Recomiendo como **condición antes de Estricto o de la primera instalación de producción** el escalón 1 de AN-01, más AN-02 y AN-03, y llevar la firma de las llaves (escalón 2) a decisión. Es una recomendación técnica: la decisión es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr34-anillo-2026-10-15.md`
- Supuestos:
  - los resultados de pruebas son los declarados por el PR, sin reproducir;
  - que Data Protection tome como predeterminada la llave de activación más reciente (comportamiento documentado de .NET, igual que lo infiere `[PSF]` 4C.3);
  - la ubicación por omisión de la carpeta del anillo no la verifiqué (AN-03).
- Decisiones candidatas a ADR:
  - **Autenticidad del anillo** (precisión de H-17 v2 y CV-05): cada llave lleva una firma RSA-PSS-SHA256 con la privada del servidor sobre el id, las fechas y el sobre, y el decorador descarta las que no la traen.
  - Alternativas descartadas: solo la DACL (no cubre errores de escritura de la API ni respaldos manipulados), una lista de ids en SQL (ata cada lectura a que la base esté disponible) y un HMAC (circular).
- Entregas a otros agentes:
  - desarrollador-backend: AN-01 (escalón 1), AN-02, AN-03 (crear la carpeta y comprobarla en N-14) y AN-05.
  - devops: DACL de la carpeta del anillo en el instalador (ADR-77, punto 4) y certificado del servidor con `digitalSignature` si se firma AN-01.
  - arquitecto-software: la precisión de CV-05 (AN-01) para la hoja de firma.
  - qa-automatizado: vectores de una llave conforme inyectada con otra recuperación (debe descartarse), de una heredada con `MigradaUtc` manipulado y de una carpeta con la DACL heredada.
- Próximo paso recomendado: unir con el escalón 1 de AN-01 y AN-02/AN-03 en un seguimiento antes de Estricto, y llevar la firma de las llaves al arquitecto.

---

## 9. Lectura de diferencias (`aee7f718..386f02cc`)

**Commit:** `386f02cc`. Revisé solo en lectura, sin compilar. Las pruebas son las declaradas por el PR (Anillo 51/51; anillo, arquitectura y Data Protection 230/230 en Debug y en Release); no las reproduje.

| Hallazgo | Estado | Evidencia y comentario |
|---|---|---|
| **AN-01, escalón 1** | **Cerrado** | `ConformidadAnillo.MotivoRechazo` descarta, en **cada** lectura, las llaves conformes cuyo principal no esté entre los certificados admitidos (el configurado más `CertificadosServidorAnteriores`) o cuya recuperación no sea la anclada (o la configurada, mientras no haya ancla). La recuperación anterior solo se admite durante `--cambiar-recuperacion` y con la expiración acotada. Las revocaciones se leen de los elementos **sin filtrar**: borrar el archivo de una llave no deshace su revocación. Una llave inyectada con la recuperación del atacante ya no se usa nunca. (`AnilloDataProtection.cs`, `RepositorioAnilloConforme.GetAllElements`; `ConformidadAnillo.cs`, `MotivoRechazo` y `Revocadas`) |
| **AN-02** | **Cerrado** | La lista de heredadas pasa a la fila `Anillo.Heredadas` de `Configuracion`, con MAC y un propósito propio. Si no verifica, cuenta como lista vacía (lado restrictivo). Cada heredada se devuelve con `expirationDate = mín(original, MigradaUtc)`, así que nunca puede ser la predeterminada. Quien solo escribe en la carpeta ya no puede declarar heredadas ni mover `MigradaUtc`. (`HeredadasAnillo.cs`; `ConformidadAnillo.Acotar`) |
| **AN-03** | **Cerrado**, con una observación | La carpeta se crea con una DACL protegida en una sola operación. Al arrancar se comprueba que no sea un punto de reanálisis, que su dueño sea SYSTEM, Administradores o la identidad del servicio, que la DACL esté protegida y que ningún ACE `Allow` dé acceso a otra cuenta. Si no cumple: `AnilloCarpetaNoConforme`, el cifrador se niega a crear llaves y, en Estricto, la API no arranca. **El criterio de dueño no abre ninguna falla:** solo admite las tres identidades, y un dueño técnico (por ejemplo, una carpeta creada por `GPOS.Migracion` sin `IdentidadServicio`) hace que la API la rechace (falla cerrado). **Observaciones (Baja):** (a) sin `IdentidadServicio`, se admite la identidad del proceso; si fuera una cuenta compartida (`NETWORK SERVICE`, `LOCAL SERVICE`), otros servicios escribirían en la carpeta. Conviene exigir `IdentidadServicio` en Estricto y rechazar los SID compartidos y de grupo (Usuarios, Usuarios autenticados, Todos). (b) Solo se comprueba la carpeta, no los **archivos**: un archivo de llave anterior a la corrección con un ACE explícito permisivo se podría modificar. Conviene comprobar que los `*.xml` no tengan ACE explícitos (que todo sea heredado). (`CarpetaAnillo.cs`; `ComprobacionAnillo.cs:130-137`; `AnilloDataProtection.cs:101`) |
| **AN-05** | **Cerrado**, con una observación | En Release sin `CertificadoServidor`, la API no arranca salvo con `GPOS:DataProtection:DpapiDemo = true`, que Estricto rechaza, y `AnilloInactivo` se registra. **El indicador `DpapiDemo` no abre una falla nueva:** es configuración que solo puede cambiar un administrador, que ya domina el equipo. Hay un **riesgo de error de configuración (Baja):** Estricto se detecta con `GPOS:Seguridad:ModoIdentidad`, un valor distinto del modo de la licencia (`OpcionesLicencia.Modo`, L1a-4). Copiar el `appsettings` del DEMO a una instalación con licencia de producción dejaría el anillo en DPAPI. Remedio barato: rechazar `DpapiDemo` también cuando la licencia vigente sea del anillo `Produccion` o `Beta` (en L1b, junto con SEG-L2-05), y unificar el origen del modo cuando RG-14 lo implemente. (`ProteccionDatosInstalacion.cs:57-66`) |
| AN-04 | Sin cambio | Se cierra con el escalón 2 (DL-20) |
| AN-06 | Sin cambio | Depende de C-05 |

**Informativa (disponibilidad, no seguridad):** después de `--cambiar-recuperacion`, la API que siga en marcha conserva en memoria el ancla anterior y descarta la llave nueva, la de la recuperación nueva. Lo reprotegido con ella no se podrá abrir en la API hasta reiniciarla (falla cerrada). Hay que documentar en el procedimiento 4C.4 bis que la API se reinicia después del verbo, o hacer que vuelva a leer el ancla.

### Residual hasta DL-20 (escalón 2: firma de cada llave)

Quien pueda escribir en la carpeta puede todavía inyectar una llave conforme con **los destinatarios correctos** (un principal admitido y la recuperación anclada), elegir el material de la llave y hacerla predeterminada. Con escritura en la base, eso le permite falsificar cualquier valor protegido (ancla, `Anillo.Heredadas`, filas de la licencia, reloj de H-16). Puede además borrar archivos de revocación de llaves de los mismos destinatarios, o reutilizar sobres bajo otro id (AN-04).

Tras AN-03, el conjunto de quienes escriben en la carpeta queda en:
- SYSTEM y los administradores, frente a los que la firma tampoco protege;
- la identidad del servicio, si sufre un error de escritura de archivos en la API;
- la restauración de un respaldo manipulado de la carpeta.

**Severidad residual: Media**, con probabilidad baja. Recomiendo resolver DL-20 antes de Avanzada o de la primera licencia de pago, y que la herramienta de respaldos (N-01) verifique la integridad de la carpeta del anillo al restaurar mientras tanto.

### Dictamen final del PR #34

**Aprobado con observaciones.**
- AN-01 (escalón 1), AN-02, AN-03 y AN-05 están cerrados.
- Las correcciones fallan cerradas y no abren ninguna vía nueva.
- Quedan dos observaciones Bajas: `IdentidadServicio` y los ACE de los archivos (AN-03), y `DpapiDemo` con una licencia de producción (AN-05).
- Queda el residual Medio hasta DL-20.

No hay hallazgos Críticos ni Altos. Es una recomendación técnica: la decisión es del propietario.

### Cierre (lectura de diferencias)
- Estado: Aprobado con observaciones
- Artefactos: este informe (sección 9 agregada)
- Supuestos: los resultados de pruebas son los declarados, sin reproducir
- Decisiones candidatas a ADR: DL-20 (firma de las llaves del anillo); origen único del modo Estricto (RG-14)
- Entregas a otros agentes:
  - desarrollador-backend: exigir `IdentidadServicio` en Estricto y rechazar SID compartidos, comprobar los ACE de los archivos, y la relectura del ancla o la nota de reinicio;
  - desarrollador L (L1b): rechazar `DpapiDemo` con una licencia `Produccion` o `Beta`;
  - devops y la herramienta de respaldos: verificar la carpeta del anillo al restaurar;
  - arquitecto: DL-20
- Próximo paso recomendado: unir el PR #34 y llevar DL-20 a firma antes de Avanzada
