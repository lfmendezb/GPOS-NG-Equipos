# Revisión de seguridad del PR #228: F1, el anillo del servicio (DM-07)

- **Fecha:** 2026-10-23
- **Revisor:** A (agente auditor-seguridad), solo lectura
- **Árbol:** `C:\Users\lfmen\source\repos\GPOS-NG-f1`, `b/f1-anillo` @ `e1c6f516`, base `origin/feature/modelo-ng`
- **Fuentes:** `git diff origin/feature/modelo-ng...HEAD` (28 archivos); avisos de B `2026-10-23-f1-anillo-pr228-para-revision.md` y `2026-10-23-anillo-f1-firmado-y-en-construccion.md`; blueprint `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md`, leído de `origin/b/blueprint-tls-anillo`, secciones 3.1 a 3.5.
- **Qué no hice:** no compilé, no ejecuté pruebas y no edité código. Lo único que cambió en el árbol fue un `git fetch` para la búsqueda del EventId: actualiza las referencias remotas, pero no toca el código.
- **Recomendación técnica:** **Aprobar con condiciones**. No hay hallazgos Críticos ni Altos. La firma es del propietario (C2).

## 1. Alcance y superficie revisada

- **`GPOS.Migracion anillo --preparar`** (`PrepararAnillo.cs`, `AlmacenMaquinaWindows.cs`, `DescriptorLlave.cs`, `IAlmacenMaquina.cs`). Es un verbo para consola elevada y crea una llave CNG de la máquina, un certificado en `LocalMachine\My`, la copia del `.cer` y el archivo del anillo.
- **El archivo del anillo** (`ArchivoAnillo.cs`): el esquema, la regla 3 (`SeguridadRutas`), la fuente de configuración, `Validar` y SA-03.
- **El arranque de la API**: `Program.cs:37`, `ProteccionDatos.cs` y `ComprobacionAnillo.EjecutarAlArrancarAsync`.
- **Las guardas G-1 y G-2** (`GuardasAnillo.cs`, `GPOS.Migracion/Program.cs:55-61, 407-413`) y la lista blanca `OpcionesComando`.
- **SA-01, SA-02, SA-03 y SA-06** (`MantenimientoAnillo.cs`, `ComandosAnillo.cs`, `ComprobacionAnillo.cs`).
- **Fuera del alcance:** los casos W-AN-01 a W-AN-05 de la VM, que corre B, y F2 a F4.

## 2. Resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| R228-01 | Medio | `anillo --migrar` (sin ancla) y `--cambiar-recuperacion` anclan una recuperación sin la huella dictada (SA-01 incompleta) |
| R228-02 | Bajo | SA-03 al arrancar: si la fila del ancla no se lee, solo queda un aviso y no hay falla cerrada |
| R228-03 | Bajo | G-1 no cubre `sistema` sin opciones, que escribe `Licencia.InstalacionId` con el anillo |
| R228-04 | Bajo | La regla 3 se comprueba por ruta y no sobre el identificador abierto; no revisa la raíz `GPOS NG` ni el `.cer` de recuperación al leer |
| R228-05 | Bajo | El esquema admite cualquier ruta absoluta (incluidas las UNC) en `carpeta` y `certificadoRecuperacion` |
| R228-06 | Bajo | `anillo --preparar` no tiene exclusión mutua: dos ejecuciones simultáneas dejan un certificado huérfano |
| R228-07 | Bajo | Textos de las guardas sin `--huella-recuperacion`, y el aviso de 180 días reutiliza el 4717 |

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Revisado. La ACL de la llave es correcta. Las DACL del archivo y de `config` son correctas, con las observaciones R228-04 y R228-05. G-1 tiene un hueco (R228-03) |
| A02 Criptografía | Revisado. RSA de 3072 bits, no exportable, de la máquina, SHA-256, 5 años, EKU *Document Encryption* y `cA=false`. Correcto |
| A03 Inyección | Revisado. F1 no lanza procesos. El JSON es estricto, con profundidad 4 y 16 KB como máximo. El XML de las llaves se lee con DTD prohibida y sin resolvedor (`ArchivoAnillo.cs:276`). El SQL va con parámetros |
| A04 Diseño inseguro | Revisado: R228-01 y R228-02 |
| A05 Configuración | Revisado. Una sola fuente, con conflicto = falla cerrada, sin recarga y sin DPAPI cuando existe el archivo. Correcto |
| A06 Componentes vulnerables | No aplica: F1 no agrega paquetes |
| A07 Autenticación | No aplica: no hay endpoints nuevos. La elevación se comprueba en `PrepararAnillo.cs:115, 384-391` |
| A08 Integridad | Revisado. Huella dictada en `--preparar` y `--anclar`; escritura atómica con comparación de la SHA-256. Falta en `--migrar` y `--cambiar-recuperacion` (R228-01) |
| A09 Registro y monitoreo | Revisado. Evento 4704 único. Sin secretos en los registros. Observación R228-07 |
| A10 SSRF | No aplica. La única ruta de red posible es una UNC en `--recuperacion` o en el archivo (R228-05) |

## 4. Revisión de los puntos pedidos

### (1) ACL, creación y propiedades de la llave: verificado leyendo

- **Descriptor.** `DescriptorLlave.Crear` (`DescriptorLlave.cs:26-37`) arma el dueño Administradores y una DACL protegida con tres entradas: SYSTEM `GENERIC_ALL`, Administradores `GENERIC_ALL` y la cuenta del servicio `GENERIC_READ`.
- **Comprobación exacta.** `DescriptorLlave.Comprobar` (`:43-75`) exige exactamente esas tres:
  - rechaza ACE de otro tipo, SID ajenos, entradas repetidas, máscaras distintas, una DACL nula y entradas que falten;
  - rechaza que la cuenta del servicio sea SYSTEM o Administradores.
- **Misma llamada.** El descriptor va en `CngKeyCreationParameters.Parameters` con `OWNER|DACL` (0x5) dentro de `CngKey.Create` (`AlmacenMaquinaWindows.cs:20-42`). .NET lo aplica con `NCryptSetProperty` antes de `NCryptFinalizeKey`, así que no hay llave persistida con la ACL por omisión.
  - [I] Que el proveedor de software respete el descriptor antes de finalizar está marcado para W-AN-02.
  - Si no lo respetara, el paso 9 lo detecta con `MotivoCertificado` (`PrepararAnillo.cs:162, 243-256`) y `Deshacer` quita el certificado y la llave (`:171-174, 350-362`). No queda una llave mal protegida en silencio.
- **Propiedades fijas.** No exportable y de la máquina son propiedades fijas que el llamador no puede pedir de otra forma (`IAlmacenMaquina.cs:13-15`). Proveedor de software (`:11`). 3072 bits (`CifradorAnillo.cs:70`; `PrepararAnillo.cs:147`). Las mismas condiciones se comprueban de nuevo en el almacén (`:248-253`).
- **Certificado.** Vigencia de 5 años (`PrepararAnillo.cs:73, 210-211`), `basicConstraints` crítica con `cA=false`, KU solo `keyEncipherment`, EKU solo *Document Encryption* (`:199-212`).
- **Cuenta.** El SID tiene que ser de servicio virtual, `S-1-5-80-` (`:127`).
- [I] Que `GENERIC_READ` baste para que el servicio use la privada se confirma en la VM.

### (2) El archivo `GPOS.Api.anillo.json`: verificado leyendo, con las observaciones R228-04 y R228-05

- **Dueño y escritores ajenos.**
  - `SeguridadRutas.Evaluar` (`ArchivoAnillo.cs:174-189`) exige que el dueño sea SYSTEM o Administradores y que ninguna ACE Allow de otra cuenta tenga bits de escritura. La lista cubre WriteData, AppendData, EA, DeleteChild, Attributes, Delete, WRITE_DAC, WRITE_OWNER y los genéricos (`:149`).
  - Se aplica al archivo y a `config` (`:247-248`).
  - Al escribir, el archivo queda con dueño Administradores y DACL protegida: SYSTEM y Administradores con control total, usuarios autenticados con lectura (`PrepararAnillo.cs:435-445`).
- **Puntos de reanálisis.** Se rechazan en el archivo y en `config` (`ArchivoAnillo.cs:157-158`). La escritura atómica no reemplaza un destino que sea punto de reanálisis (`PrepararAnillo.cs:424-427`).
- **Falla cerrada.** Un archivo presente que no se abre, o que no cumple el esquema o la DACL, deja `Error` (`ArchivoAnillo.cs:240-242, 355-365`). `Validar` lanza la excepción (`:314`). La API escribe el 4704 y no arranca (`ProteccionDatos.cs:25-48`).
  - Un conflicto con otra fuente también es falla cerrada (`ArchivoAnillo.cs:315-319`). El mensaje nombra solo la clave, nunca el valor.
  - El archivo junto con DPAPI se rechaza (`ProteccionDatosInstalacion.cs:133-135`).
- **Una sola fuente de lectura.** La API (`Program.cs:37`) y `GPOS.Migracion` (`ConfiguracionMigracion.cs:299-307`) usan el mismo `AgregarArchivoAnillo("GPOS.Api")` y el mismo `ArchivoAnillo.Validar`.
  - En los dos procesos es la última fuente y no se recarga.
  - No hay otros consumidores del anillo en `src/`: lo comprobé con grep.

### (3) Guardas G-1 y G-2: verificado leyendo

- **G-1** (`GuardasAnillo.cs:40-49`; `Program.cs:55-61`):
  - corre antes de tocar la base;
  - sale con 4;
  - un estado del servicio `Desconocido` también niega, así que falla cerrada;
  - `--preparar` queda fuera, y la regla de una sola acción (`ComandosAnillo.cs:169-172`) impide combinarlo con otra acción para saltar la guarda.
  - Hueco en R228-03.
- **G-2** (`GuardasAnillo.cs:55-63`; `Program.cs:407-413`): con el anillo con certificado exige `Anclada` y sale con 4. Con DPAPI (Debug o DEMO) no exige nada, según PA-77-3.

### (4) SA-01, SA-02, SA-03 y SA-06

- **SA-01**, verificado:
  - en `--preparar` la huella es obligatoria antes de tocar nada (`ComandosAnillo.cs:212`; `PrepararAnillo.cs:102-122`), y el `.cer` se lee una sola vez y se usan los mismos bytes para la huella y para la copia (`:116-119, 166`);
  - en `--anclar` también (`MantenimientoAnillo.cs:99-108`);
  - **`--migrar` y `--cambiar-recuperacion` no la piden**: es R228-01.
- **SA-02**, verificado: un `.cer` vencido solo produce un aviso (`PrepararAnillo.cs:306-310`).
- **SA-03**, verificado:
  - sin el archivo, con llaves conformes en `Api\anillo`, `Validar` falla cerrada en la API y en `GPOS.Migracion`, también con DpapiDemo (`ArchivoAnillo.cs:307-313, 261-269`);
  - sin el archivo, con la fila del ancla, falla cerrada al arrancar (`ComprobacionAnillo.cs:80-96`);
  - el caso de la base ilegible está en R228-02;
  - `--preparar` regenera el archivo con el principal existente y no crea un segundo principal (`PrepararAnillo.cs:136-137, 320-339`).
- **SA-06**, verificado: el aviso aparece con menos de 180 días y `CodigoSalida` da 0, 2 o 1, con 2 solo si cumple (`ComprobacionAnillo.cs:28-38, 190-196`; `ComandosAnillo.cs:200-202`).

### (5) La línea nueva de `src/GPOS.Api/Program.cs`: verificado leyendo

- `Program.cs:37` queda después de `AgregarArchivoInstalacion` (`:35`), que se inserta antes de las variables de entorno.
- También queda después de la línea de comandos que agrega `WebApplication.CreateBuilder`, y antes de `ProteccionDatos.Configurar` (`:53`). Por eso es la última fuente, y entre las líneas 37 y 53 no se agrega ninguna otra (grep de `Configuration.Add` y `Sources.`).
- La línea no cambia el orden de DB-7 en la zona F-5.
- [I] `ArchivoAnillo.Proveedor` en el arranque necesita que el `IConfiguration` del contenedor sea el `ConfigurationManager` (un `IConfigurationRoot`). Así es en .NET 8, pero no lo comprobé ejecutando. Si no lo fuera, SA-03 al arrancar quedaría inerte; una prueba F lo confirmaría.

### (6) La fila del ancla no se puede leer al arrancar

Confirmado leyendo: solo queda un aviso (`ComprobacionAnillo.cs:83-91`). El análisis está en R228-02.

### (7) Evento 4704 `AnilloConfiguracionNoConforme`: verificado

- Hay una sola definición, `AnilloDataProtection.cs:47`.
- Busqué con `git grep` en todas las ramas `refs/remotes/origin/*` después del fetch. El 4704 solo aparece en `b/f1-anillo`, en el blueprint (`b/blueprint-tls-anillo`, 149, 361, 418, 447, 502, 516 y 543) y en la hoja de firma (`b/hoja-firma-tls-anillo`, 45), siempre con este significado.
- En el área común solo aparece en avisos y traspasos sobre F1.
- Nota informativa: el 4704 coincide con el Id de un evento del registro de Seguridad de Windows («se asignó un derecho de usuario»). El origen y el registro son otros, así que no hay choque real, pero una regla de SIEM que filtre solo por Id lo confundiría. Toda la serie 47xx de GPOS ya tiene esa situación; no es un hallazgo de F1.

### (8) Fugas, TOCTOU, inyección y `OpcionesComando["sistema"]`

- **Fugas**, verificado:
  - los registros y eventos llevan rutas de `%ProgramData%`, huellas SHA-256 de certificados públicos y los SID de escritores ajenos; nada de eso es secreto;
  - de las excepciones solo se registra el tipo (`ComprobacionAnillo.cs:90`), y de SQL solo el número (`MantenimientoAnillo.cs:519-520`);
  - el conflicto de fuentes no registra el valor (`ArchivoAnillo.cs:318`);
  - no hay contraseñas, PFX ni PKCS#8 en disco.
- **TOCTOU:** el archivo se abre sin compartir el borrado y después se comprueban la DACL y el reanálisis por ruta (`ArchivoAnillo.cs:234, 246-248`). El riesgo residual es bajo porque `config` no admite escritores ajenos: es R228-04.
- **Inyección en argumentos de proceso:** no aplica. F1 no lanza procesos (lo comprobé con grep del diff). El análisis de argumentos no distingue mayúsculas de forma coherente: el diccionario, las banderas y `OpcionesComando` usan `OrdinalIgnoreCase` (`Program.cs:479, 482`; `OpcionesComando.cs`), así que no hay forma de saltar G-1 o G-2 cambiando mayúsculas.
- **`OpcionesComando["sistema"]`**, verificado:
  - las tres opciones nuevas eran las que el código ya usaba (`Program.cs:409-420`) y que DL22-S08 dejaba fuera por error;
  - `--cuentas-iniciales` y `--confirmar-sellado` pasan por G-1 y G-2;
  - `--motivo` se valida en el sellado (`SellosService.cs:279`: de 10 a 400 caracteres, sin caracteres de control);
  - las claves iniciales vienen de la configuración, nunca de la línea de comandos (`ComandoSistema.cs:126-127`; `Program.cs:496-497` rechaza `--clave` y `--password`).
  - No abre una vía nueva: exige una identidad administrativa sobre GPOS_SYSDATA, igual que antes. Con DPAPI (DEMO sin servicio instalado) G-2 no exige ancla, como prevé PA-77-3.

## 5. Hallazgos

### R228-01 · Medio · `--migrar` y `--cambiar-recuperacion` anclan sin la huella dictada

- **Riesgo.** SA-01 protege el ancla contra un `.cer` de recuperación sustituido. Pero hay dos caminos que fijan el ancla con `HuellaRecuperacionConfigurada()` sin compararla con una huella dictada:
  - `anillo --migrar`, cuando no hay ancla;
  - `anillo --cambiar-recuperacion`, que cambia a la recuperación nueva.

  Quien logre que la recuperación configurada apunte a su certificado consigue que todas las llaves nuevas del anillo se envuelvan también para él, y con una copia de `Api\anillo` descifraría las cadenas de las empresas y los secretos de GPOS_SYSDATA.
  - **Con el archivo del anillo:** `--migrar` hereda la verificación de `--preparar`, porque el `.cer` de `config` se copió con la huella dictada [I, condicionado a que `config` siga sin escritores ajenos]. En cambio, `--cambiar-recuperacion` solo puede usar una recuperación nueva si alguien reemplazó a mano `config\GPOS.Api.recuperacion.cer`, y ese reemplazo no se verifica.
  - **Sin el archivo:** si el servicio no está instalado, G-1 deja pasar (`GuardasAnillo.cs:45`), y la ruta del `.cer` sale de `GPOS.Migracion.json` o de las variables de entorno, sin regla de DACL.
- **Evidencia.**
  - `MantenimientoAnillo.cs:147-148`: `FijarAnclaAsync(HuellaRecuperacionConfigurada(), …)` en `--migrar`.
  - `MantenimientoAnillo.cs:213-229`: `--cambiar-recuperacion`.
  - `ComandosAnillo.cs:194-195`: `--migrar` no recibe `huella-recuperacion`.
  - `PrepararAnillo.cs:228`: remite a `--cambiar-recuperacion`.
  - `ComandosAnillo.cs:175`: `--recuperacion` solo vale para `--preparar`.
- **Remediación**, la más barata (unas 0,25 dp con pruebas U):
  - exigir `--huella-recuperacion` en `--migrar` cuando va a fijar el ancla, y en `--cambiar-recuperacion` para la huella **nueva**;
  - reutilizar `MantenimientoAnillo.HuellaDictada` y la comparación de `AnclarAsync` (`:102-108`).
- **Defensa en profundidad:** aplicar a `config\GPOS.Api.recuperacion.cer` la regla 3 (R228-04).
- **Alternativa descartada:** prohibir `--migrar` sin el archivo. Es más restrictiva y rompe la migración del DEMO sin aportar más que la huella dictada.
- **Contexto:** SA-01, tal como se firmó, solo nombra `--preparar` y `--anclar`. Extenderla es una decisión del propietario (ver Decisiones candidatas a ADR).

### R228-02 · Bajo · SA-03 sin falla cerrada si la fila del ancla no se lee al arrancar

- **Riesgo.** El caso es este:
  - sin el archivo del anillo;
  - sin `ModoAnillo` (DPAPI, es decir, Debug o `DpapiDemo=true`);
  - sin llaves conformes en `Api\anillo`;
  - con una falla transitoria de la base al arrancar.

  Entonces la API arranca con DPAPI aunque GPOS_SYSDATA tenga el ancla, y cuando vuelve la base, lo que se proteja de nuevo queda con un anillo que la instalación con certificado no reconoce: una mezcla de anillos difícil de reparar. El alcance es estrecho: en Release, sin el archivo y sin `DpapiDemo`, la API ya no arranca por AN-05 (`ProteccionDatosInstalacion.cs:146-152`), y las llaves presentes ya fallan cerrado por `Validar`.
- **Evidencia.** `ComprobacionAnillo.cs:83-92`: el `catch` solo registra `LogWarning` y `MotivoFaltante(archivo, null)` devuelve null cuando no hay llaves.
- **Remediación.** Hay dos opciones:
  - con `!CompilacionDepuracion`, tratar una lectura fallida como falla cerrada (4704, con el motivo «no se pudo comprobar el ancla»). Una API sin base no presta servicio de todos modos;
  - o reintentar unas pocas veces con espera corta y luego fallar cerrada.

  Unas 0,1 dp.

### R228-03 · Bajo · G-1 no cubre `sistema` sin opciones

- **Riesgo.** `sistema` sin `--cuentas-iniciales` ni `--confirmar-sellado` (por ejemplo, `sistema --login-api`) escribe `Licencia.InstalacionId` protegida con el anillo cuando falta, pero G-1 lo deja pasar.
  - Con el servicio instalado, sin el archivo y con DPAPI habilitado (`DpapiDemo` o Debug), la fila queda con el DPAPI del técnico, que el servicio no descifra.
  - `AsegurarInstalacionAsync` después no la pisa, y hace falta una intervención manual.
  - Esto contradice el objetivo escrito de G-1 (`GuardasAnillo.cs:12-14`; blueprint 3.3).
  - En Release sin `DpapiDemo`, `Configurar` ya falla con salida 1, y en el orden de PR-D2 `sistema --login-api` corre después de `--preparar`, así que el camino previsto no se afecta.
- **Evidencia.** `GuardasAnillo.cs:31`; `GPOS.Migracion/Program.cs:407, 416-418`; `ComandoSistema.cs:93, 147-173`.
- **Remediación.** `"sistema" => true` en `UsaElAnillo`, porque `sistema` siempre recibe el proveedor del anillo. Unas 0,05 dp, más una prueba U.

### R228-04 · Bajo · Regla 3 por ruta, sin la raíz ni el `.cer` al leer

- **Riesgo.** La DACL y el reanálisis se comprueban por ruta después de abrir el archivo, y solo sobre el archivo y `config`:
  - la raíz `%ProgramData%\GPOS NG` solo la revisa `--preparar` (`PrepararAnillo.cs:124-125`), no la API ni `GPOS.Migracion` en cada lectura;
  - el `.cer` de recuperación que lee `OrigenCertificadosAlmacen.Recuperacion` (`OrigenCertificadosAnillo.cs:96-98`) no pasa por ninguna regla (dueño, reanálisis, escritores) ni se compara con una huella esperada antes del ancla.

  Hoy el residual es bajo, porque cambiar esas ACL exige ser administrador.
- **Evidencia.** `ArchivoAnillo.cs:155-164, 234-248`.
- **Remediación**, unas 0,25 dp:
  - leer la DACL y los atributos del identificador ya abierto: `FileSystemAclExtensions.GetAccessControl(FileStream)` y `File.GetAttributes(SafeFileHandle)`;
  - agregar la raíz a la comprobación;
  - aplicar `SeguridadRutas.Motivo` al `.cer` de `config`.

### R228-05 · Bajo · Rutas libres en el esquema

- **Riesgo.** `carpeta` y `certificadoRecuperacion` aceptan cualquier ruta absoluta, incluida una UNC, aunque `--preparar` solo escribe las rutas derivadas.
  - Si el archivo se altera, la API podría guardar llaves fuera de la raíz protegida o leer el `.cer` de un recurso de red, con autenticación saliente de la cuenta del servicio.
  - SA-03 solo mira la carpeta por omisión (`ArchivoAnillo.cs:265`; `FuenteArchivoAnillo`, `:335-336`), así que una `carpeta` distinta deja a SA-03 mirando el lugar equivocado.
- **Evidencia.** `ArchivoAnillo.cs:74, 85, 130`.
- **Remediación**, unas 0,1 dp:
  - exigir que `carpeta` sea igual a `CarpetaLlavesPorOmision` y que `certificadoRecuperacion` sea igual a `config\GPOS.Api.recuperacion.cer` (sin distinguir mayúsculas), o al menos que estén dentro de la raíz de ADR-77;
  - rechazar las UNC.

### R228-06 · Bajo · `--preparar` sin exclusión mutua

- **Riesgo.** Dos ejecuciones simultáneas ven que falta el archivo y crean cada una su llave y su certificado. Gana la última publicación, y el otro certificado queda huérfano en `LocalMachine\My` con su llave de la máquina.
  - No compromete el anillo, pero ensucia el almacén y confunde una recuperación.
  - `tls` ya prevé `Global\GPOS.Migracion.tls` (blueprint 4.1).
- **Evidencia.** `PrepararAnillo.cs:131-168`: no hay bloqueo.
- **Remediación.** Un `Mutex` `Global\GPOS.Migracion.anillo` alrededor de `Pasos`, con espera de 60 s y salida 1, como en `tls`. Unas 0,05 dp.

### R228-07 · Bajo · Textos de las guardas y aviso de vencimiento

- **Riesgo.** Es operativo y de monitoreo:
  - los textos de G-1 (`GuardasAnillo.cs:47-48`) y de G-2 (`:61`) indican `anillo --preparar --recuperacion <.cer>` y `anillo --anclar --acta --motivo` sin `--huella-recuperacion`, así que el técnico que los siga recibe un error de SA-01;
  - el aviso de 180 días se registra con el Id 4717 `AnilloComprobado` (`ComprobacionAnillo.cs:194`), y una alerta por Id no lo separa de una comprobación normal.
- **Remediación.**
  - Agregar `--huella-recuperacion <sha256>` a los dos textos, como ya hace `MotivoFaltante` (`ArchivoAnillo.cs:264`).
  - Para el aviso, usar un nombre de evento propio con el mismo Id, o reservar un Id cuando se asignen los de F4. Lo decide B por la franja de Ids.

## 6. Controles bien implementados

- El descriptor de la llave es exacto, se pasa en la misma llamada de creación y se verifica después, con reversión si falla (`DescriptorLlave.cs`; `AlmacenMaquinaWindows.cs:20-42`; `PrepararAnillo.cs:147-174`).
- Las propiedades críticas son fijas en el tipo: máquina, no exportable, software y 3072 bits (`IAlmacenMaquina.cs:8-16`).
- La huella del `.cer` se lee una sola vez y es la misma que se compara, se prueba con un sobre de prueba y se copia (`PrepararAnillo.cs:116-122, 163, 166`).
- El JSON es estricto: propiedades exactas, sin repetidas, `v=1`, servicio e identidad fijos, 16 KB como máximo (`ArchivoAnillo.cs:47-91`).
- Hay una sola fuente de configuración, con conflicto = falla cerrada, sin recarga, y el archivo excluye DPAPI (`ArchivoAnillo.cs:300-321`; `ProteccionDatosInstalacion.cs:133-135`).
- La escritura es atómica: temporal en la misma carpeta, `CreateNew`, `WriteThrough`, DACL protegida en la creación, sin seguir reanálisis y con comparación de la SHA-256 (`PrepararAnillo.cs:342-347, 412-445`).
- G-1 falla cerrada ante un estado del servicio desconocido, y la regla de una sola acción impide saltar las guardas.
- No hay secretos en los registros ni en la salida.

## 7. Remediaciones priorizadas

1. **R228-01** (Medio): antes de unir, o como condición firmada con fecha antes de PR-D2, porque PR-D2 usa `--anclar` y no `--migrar`.
2. **R228-03** y **R228-07** (textos): son cambios de una línea; conviene hacerlos en este PR.
3. **R228-02**, **R228-05** y **R228-06**: en este PR o en F4.
4. **R228-04**: en F4, junto con `--renovar-certificado`.

## 8. Verificado y supuesto

- **Verificado leyendo el código:** todo lo citado con `archivo:línea` en las secciones 4 y 5, y la unicidad del 4704 con `git grep` en `origin/*`.
- **Supuesto o inferido [I]:**
  - que el proveedor de software aplica el descriptor antes de finalizar (W-AN-02);
  - que `CopyWithPrivateKey` conserva el enlace con la llave de la máquina (W-AN-01);
  - que `GENERIC_READ` basta para usar la privada;
  - que el `IConfiguration` del contenedor de la API es un `IConfigurationRoot` (punto 5);
  - que `--migrar` con el archivo hereda la verificación de `--preparar` (R228-01).
  - No compilé ni ejecuté la suite. Las cifras de B (216/216 y 429/429) no las comprobé.

## 9. Recomendación

**Aprobar con condiciones** (recomendación técnica; la firma es del propietario).

- Condición 1: resolver R228-01, o que el propietario acepte el riesgo de forma explícita con fecha.
- Condición 2: corregir R228-03 y los textos de R228-07.
- Los demás Bajos pueden quedar registrados para F4.

## Entregas y observaciones para B (fuera del alcance de seguridad)

- **DEMO.** Con el servicio instalado y sin el archivo del anillo, G-1 bloquea en el DEMO actual (`DpapiDemo`) los verbos `sellos`, `empresa`, `credencial-app`, `restablecer-factor` y `anillo` hasta `--preparar`. Y el archivo del anillo no se combina con `DpapiDemo` (regla 5). Conviene confirmar que es lo deseado para el DEMO antes de unir.
- **Coherencia del procedimiento.** `PrepararAnillo.cs:228` remite a `--cambiar-recuperacion`, pero con el archivo presente la recuperación configurada es la del archivo, así que ese verbo no tiene cómo recibir el `.cer` nuevo. Conviene definir en F4 el camino para cambiar la recuperación, que enlaza con R228-01.
