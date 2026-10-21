# Relectura de seguridad: PR #124 (O-1 y O-3 del instalador), commits posteriores a `f0aa9126`

- **Fecha:** 2026-10-21 · **Agente:** auditor-seguridad (equipo A) · **Estado de la decisión:** recomendación técnica; la decisión es del propietario (Pendiente de firma).
- **Objeto:** `C:\Users\lfmen\source\repos\GPOS-NG-o1`, rama `a/instalador-o1-o3`, `git diff f0aa9126..HEAD`: `16701cbb` (P124-01 a P124-07), `66d9127f` (S-06, S-07, S-08, P124-08) y `e05ab4b1` (D-1, D-3, D-4, P-O1-5, nota S-07).
- **Antecedentes:** informe previo `traspasos/A/revision-seguridad-o1-o3-2026-10-20.md` (S-01 a S-11); revisión de pruebas de C `traspasos/C/2026-10-20-revision-pruebas-pr124.md` (P124-01 a P124-09).
- **Método:** solo lectura (`git log`, `git diff`, `git show`, `git grep`, lectura de archivos). No compilé ni ejecuté pruebas, MSI ni nada elevado. La única ejecución fue `sha256sum` sobre el vector (lectura) para contrastar la huella fijada en las pruebas. **[V]** = verificado leyendo el código; **[I]** = inferido, a confirmar en laboratorio (P-O1-7, P-O3-4).
- **Rutas citadas** (relativas a `GPOS-NG-o1`):
  - **CCP** = `instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs`
  - **AI** = `instalador/Comun/GPOS.Instalador.Acciones/AccionesInstalador.cs`
  - **FCP** = `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`
  - **FRZ** = `instalador/Comun/Fragmentos/RaizGposNg.wxs`
  - **PKG** = `instalador/AgenteImpresion/Package.wxs`
  - **WIXPROJ** = `instalador/AgenteImpresion/GPOS.AgenteImpresion.Instalador.wixproj`
  - **V3** = `docs/contratos/vectores/adr077-carpetas.v3.json`
  - **OPS** = `docs/operaciones/2026-10-20-raiz-gpos-ng-instalador.md`
  - **PFI** = `tests/GPOS.Tests/Instalador/FragmentosInstaladorTests.cs`
  - **PCP** = `tests/GPOS.Tests/Instalador/ComprobacionCarpetasPreviasTests.cs`

## 1. Alcance y superficie revisada

| Superficie | Qué cambió y qué se revisó |
|---|---|
| Acción diferida (SYSTEM) | `ComprobarPadre` y `PadreDe` nuevos (P124-02, opción b), llamados antes de `CreateDirectoryW` de la raíz (CCP:541-560, :629-678). Releídos completos CCP y AI para confirmar S-01, S-02, S-03, S-05, S-09, S-10 y S-11 |
| Secuencia WiX | Condición nueva por *feature* en las dos acciones (FCP:68-71) con la variable `GposFeatureCarpetas` (WIXPROJ:18) |
| Componentes compartidos | GUID nuevo de la raíz (FRZ:34), `config\` separado en `GrupoConfigGposNg` (FRZ:53-73), GUID nuevo de `ProgramaEstacion` (PKG:109), MSI de la estación sin `config\` (PKG:132) |
| Vector v3 | `guidRetirados`, `grupo` y `declaran` (V3:202-247); huella fijada en PFI:28 |
| Pruebas | P-O1-5 (PCP:181-186), P124-02 (PCP:660), S-06 (PFI:300), S-07 (PFI:173, :192), S-04 (PFI:345-365) |
| Documentación | OPS (carpeta insegura, retiro manual, cambio del SDDL) y nota de registro ADR-77, punto 6 |

Fuera de la superficie: endpoints, tenants y SQL (no aplican).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Tipo |
|---|---|---|---|
| R-01 | Media | `GposFeatureCarpetas` falla cerrada si falta, pero **falla abierta** si nombra una *feature* que no existe o que no trae las carpetas; solo el MSI del agente tiene la guarda | [V] diseño, latente |
| R-02 | Baja | La condición no contempla `&F = 4` (desde el origen) ni la publicación (*advertise*); probablemente inofensivo con componentes `LocalOnly` | [I] |
| R-03 | Baja | Con el GUID nuevo, IQ 0.4.1 ya no comparte la referencia de la raíz: su desinstalación puede quitar la raíz vacía (`RemoveFolders`). Corrige el S-08 punto 4 del informe previo | [I] |
| R-04 | Baja | La guarda de S-04 se desactiva con solo mencionar el nombre de la `.CA.dll` en `construir.ps1`, y la prueba estricta sigue con `Skip` | [V] |
| R-05 | Baja | Quedan GUID con aspecto manual en componentes no compartidos (`OrigenEventosEstacion`) que el detector de patrones (pasos de ±1) no ve | [V] |
| R-06 | Baja | `config\` la leen también `GPOS.Web` y `GPOS.Migracion`, pero solo la declaran Api y Reportes: hueco funcional, sin riesgo de seguridad | [V] |

No hay hallazgos Críticos ni Altos. De S-01 a S-11, todos los que debían quedar cerrados siguen cerrados (sección 4.1).

## 3. Checklist OWASP (acción de instalador)

| Punto | Resultado |
|---|---|
| A01 Control de acceso roto | Revisado. Lista blanca sin cambios (SY, BA, TI) y servicio solo en su fila (CCP:192, :827-831). R-01 es una vía latente para saltarse la comprobación |
| A02 Fallas criptográficas | S-03 sigue cerrado: SHA-256 y SHA-1 del proveedor de Windows en net472 (CCP:236-256). SHA-1 solo deriva el SID de la cuenta virtual, como hace Windows |
| A03 Inyección | Sin cambios. `CustomActionData` y la validación de rutas igual que en `f0aa9126` (CCP:262-317, :418-433) |
| A04 Diseño inseguro | P124-02 bien resuelto (4.2). R-01 y R-02 |
| A05 Configuración insegura | R-03, R-05 y R-06 |
| A06 Componentes vulnerables | Sin cambios de paquetes en este tramo (WiX 5.0.2). No ejecuté ninguna herramienta de dependencias |
| A07 Autenticación | No aplica |
| A08 Integridad del software | S-04 sigue pendiente, contenido por K1-02. R-04 |
| A09 Registro y monitoreo | S-10 y S-11 cerrados (AI:106-118; OPS:46) |
| A10 SSRF | No aplica (rutas UNC rechazadas por `RutaCanonica`, CCP:418-433) |
| Aislamiento entre tenants | No aplica (acción de máquina) |
| Secretos | Ninguno en el código, los fragmentos, el vector ni la documentación. Los SID de las pruebas no son secretos |

## 4. Verificación por punto pedido y hallazgos

### 4.1 Punto (1): S-01, S-02, S-03, S-05, S-09, S-10 y S-11 siguen cerrados [V]

| ID | Evidencia actual | Estado |
|---|---|---|
| S-01 | `Ordenar` exige exactamente una raíz, que toda fila descienda de ella y la fila de cada antepasado (CCP:347-398). Ruta final por `GetFinalPathNameByHandleW` en cada carpeta (CCP:600-604, :686-702) | Cerrado |
| S-02 | Ninguna fila bajo una carpeta con escritor de servicio (CCP:400-408) | Cerrado |
| S-03 | `SHA256CryptoServiceProvider` y `SHA1CryptoServiceProvider` en net472 (CCP:236-256). El aviso de creación queda aislado (`Notificar`, CCP:488-505) y el texto del evento se arma dentro del `try` (AI:150-168) | Cerrado en código. Falta el caso FIPS en P-O1-7 |
| S-05 | `Id` privado `DirEstacionDatos` (PKG:96-100, :158, :166) | Cerrado |
| S-09 | Uniones reales: hoja, intermedio, raíz plantada y, ahora, padre de la raíz (PCP:660) | Cerrado (no ejecuté las pruebas) |
| S-10 | `TextoSinCambios(raizCreada)` en el registro y en los dos eventos (AI:106-118), con guarda de código (P124-01) | Cerrado |
| S-11 | Documentado: instalar siempre con `/l*v` (OPS:46) | Cerrado por documentación (opción sin costo) |

### 4.2 Punto (1): comprobación del padre de la raíz (P124-02, opción b) [V]

- **Qué hace.** Antes de `CreateDirectoryW`, abre el padre (`C:\ProgramData`) sin seguir el punto de reanálisis, con solo `FILE_READ_ATTRIBUTES` (CCP:638-639). Rechaza en estos casos:
  - el padre es un punto de reanálisis (CCP:653-656);
  - su ruta final no es la pedida, es decir, un antepasado suyo es una unión (CCP:658-659);
  - no se puede leer (`SEGURIDAD_ILEGIBLE`, CCP:640-651).
- **Falla cerrada.** Sí, en todos los caminos:
  - si el padre no existe (2 o 3), no decide, pero `CreateDirectoryW` falla con 3 y `DecidirCreacion` lo convierte en `SEGURIDAD_ILEGIBLE` (CCP:764-765);
  - cualquier otro error al abrir o leer el padre es `SEGURIDAD_ILEGIBLE`;
  - sin ruta final es `SEGURIDAD_ILEGIBLE` (CCP:688-691).
  - No hay ningún camino que devuelva `null` con un padre ilegible.
- **TOCTOU nuevo: no explotable sin privilegios.**
  - Hay una ventana entre el cierre del identificador del padre (fin de `ComprobarPadre`) y `CreateDirectoryW`. Además, el identificador se abre con `FILE_SHARE_DELETE` (CCP:902), así que tampoco impediría un cambio de nombre.
  - Para aprovecharla hay que sustituir `C:\ProgramData` (o un antepasado) por una unión, y eso exige `DELETE` sobre esa carpeta o `FILE_DELETE_CHILD` sobre `C:\`. Solo lo tienen SYSTEM, Administradores y TrustedInstaller [I: ACL por omisión de Windows]. Un usuario puede *crear* carpetas en `C:\` y en `C:\ProgramData`, pero no renombrar ni borrar `ProgramData`. Quien puede usar la ventana ya está al nivel del instalador.
  - Si aun así se ganara la carrera, la defensa posterior sigue: la ruta final de la raíz recién creada no coincide y se rechaza con `PUNTO_DE_REANALISIS` (CCP:600-604). Lo creado en el destino lleva el SDDL protegido con dueño SYSTEM, así que no da acceso a nadie.
  - Es una mejora neta frente a `f0aa9126`: antes la raíz se creaba en el destino de una unión del padre y el rechazo llegaba después.
- **Efecto secundario aceptable.** Un `C:\ProgramData` reubicado con una unión (configuración no soportada por Microsoft) hace fallar la instalación de forma cerrada. Un `CommonAppData` reubicado por el registro a una carpeta real pasa sin problema. Conviene una línea en OPS («Carpeta insegura», `PUNTO_DE_REANALISIS` en el padre).

### 4.3 Punto (2): S-06, condición por *feature*

Condición (FCP:69 y :71, idéntica en las dos acciones y fijada por PFI:300):
`NOT REMOVE ~= "ALL" AND (&F = 3 OR (!F = 3 AND NOT &F = 2))`, con `F = EstacionImpresion` (WIXPROJ:18).

Las dos acciones llevan la misma condición. Si llegaran a divergir con la inmediata omitida y la diferida ejecutada, `LeerDatos` lanzaría `FormatException` (CCP:293-296), lo que es falla cerrada.

| Escenario | `!F` / `&F` | ¿Corre? | ¿`CreateFolders` aplica DACL bajo la raíz? | Veredicto |
|---|---|---|---|---|
| Instalación nueva con la estación | 2 / 3 | Sí | Sí | Correcto |
| Instalación solo del agente (`ADDLOCAL=Agente`) | 2 / -1 | No | No (ningún componente de `Agente` está bajo la raíz; PFI:300, guarda «solo Agente») | Correcto |
| Reparación (`REINSTALL=ALL`) | 3 / 3 o -1 | Sí | Sí | Correcto |
| Mantenimiento: agregar o quitar otra *feature* | 3 / -1 | Sí | Reaplica | Correcto (conservador) |
| `REMOVE=EstacionImpresion` (D-3) | 3 / 2 | No | No (se quitan componentes, no se crean carpetas) | Correcto |
| `REMOVE=ALL` | — | No | No | Correcto |
| Actualización mayor con la estación | 2 / 3 (por `MigrateFeatureStates`) | Sí | Sí | Correcto [I] |
| Actualización mayor sin la estación | 2 / -1 | No | No; el producto anterior se quita antes (`RemoveExistingProducts` tras `InstallValidate`) | Correcto [I] |
| `ADDSOURCE=EstacionImpresion` | 2 / 4 (si Windows lo acepta) | **No** | Sí, si los componentes `LocalOnly` se instalan en local | R-02 [I] |
| `ADVERTISE=EstacionImpresion` | 2 / 1 | No | No (un componente publicado no crea carpetas) [I] | Correcto |

#### R-01 · Media · `GposFeatureCarpetas` falla abierta si nombra mal la *feature*

- **Riesgo.**
  - Si la variable **falta**, la compilación falla: WiX no admite `$(var.X)` sin definir [I: comportamiento documentado del preprocesador de WiX 4/5]. Si queda **vacía**, la condición es sintácticamente inválida y Windows Installer aborta la instalación [I]. En los dos casos falla cerrada.
  - Si **nombra una *feature* que no existe**, o una que no contiene `GrupoRaizGposNg` ni las carpetas con fila, la condición se evalúa como falsa [I] y las acciones no corren. `CreateFolders` aplica igual las DACL de las *features* reales. Se pierde en silencio la comprobación de ADR-77, punto 3, que es exactamente el ataque que esa comprobación detiene: carpeta plantada o unión.
  - Ninguna ICE de Windows Installer valida los nombres de *feature* dentro de las condiciones.
  - **Hoy no ocurre en el agente:** la variable es fija (WIXPROJ:18), no sale de una propiedad, y PFI:300 comprueba que la *feature* existe, trae la raíz y contiene todo componente con fila.
  - El fragmento indica a cada consumidor que defina su propia variable (FCP:9-12). Api, Web y Reportes no tienen esa guarda.
- **Evidencia:** FCP:9-12, :68-71; WIXPROJ:18; PFI:300 (específica del agente).
- **Remediación** (unos 0,1 dp, ±50 %):
  1. Generalizar PFI:300. Para **todo** `.wixproj` que compile `ComprobacionCarpetasPrevias.wxs`:
     - `GposFeatureCarpetas` es un literal (no `$(...)`);
     - nombra una `Feature` de su `Package.wxs`;
     - esa *feature* referencia `GrupoRaizGposNg`;
     - todo componente cuyo `Directory` tiene fila en `GposCarpetaPrevia`, y todo `CreateFolder` bajo `DirGposNgDatos`, pertenece a esa *feature*.
  2. **Defensa en profundidad (opcional, unos 0,1 dp):** en la acción inmediata, consultar la tabla `Feature` y fallar si `GposFeatureCarpetas` no existe. Para eso habría que pasar el nombre como propiedad (`SetProperty` con el literal). No cubre el caso «existe pero es otra», así que la prueba del punto 1 es la defensa principal.
  - **Alternativa descartada:** condicionar por el estado de componente (`$DatosEstacion`). Tiene el mismo problema de nombre y además obliga a elegir un componente representativo por MSI.
- **Condición:** antes de que Api, Web o Reportes consuman el fragmento (igual que S-01 y S-02 en el informe previo).

#### R-02 · Baja · Estados `&F = 4` (desde el origen) y publicación sin cubrir [I]

- **Riesgo.** Los componentes de la estación son `LocalOnly` por omisión de WiX. Lo más probable es que Windows Installer convierta `ADDSOURCE=EstacionImpresion` en una instalación local (`&F = 3`), y entonces la acción corre [I]. Si en cambio dejara `&F = 4` con los componentes en local, `CreateFolders` aplicaría las DACL sin la comprobación previa. Exige que un administrador pase `ADDSOURCE` a propósito.
- **Evidencia:** FCP:69, :71; PKG:103-152 (sin `AllowAdvertise` explícito; componentes sin `Location`).
- **Remediación** (0,05 dp):
  - incluir el 4 en la condición: `(&F = 3 OR &F = 4 OR (!F = 3 AND NOT &F = 2))`;
  - fijar `AllowAdvertise="no"` en la *feature*;
  - agregar a P-O1-7 los casos `ADDSOURCE=EstacionImpresion` y `ADVERTISE=EstacionImpresion` con `/l*v`.

### 4.4 Punto (3): S-07, GUID nuevo de la raíz, `ProgramaEstacion` y vector v3 [V]

- **GUID de la raíz.** `66D68CDE-6BFC-4590-9089-68AD56F78DD3` (FRZ:34; V3:229): versión 4 y variante RFC 4122, sin el patrón anterior.
- **`ProgramaEstacion`.** `76F80408-20A3-4E7F-BABD-828B5B31E885` (PKG:109): versión 4. Cambiar el GUID de un componente con la misma ruta clave es seguro aquí. Solo existió en compilaciones de desarrollo, y `MajorUpgrade` quita el producto anterior antes de instalar, así que no rompe las reglas de componentes [I].
- **`guidRetirados`.** Contiene `9E7A0D3C-…-0A1B2C3D4E5F` con su motivo y `sustituidoPor` (V3:236-247). La prueba ahora recorre todos los retirados, no solo el primero (P124-07):
  - ningún retirado aparece en un `.wxs`;
  - ninguno coincide con un GUID canónico.
- **SHA-256.** Calculé con `sha256sum`:
  - v3: `6879e0b2…62e89b23`, igual a la constante de PFI:28;
  - v2 en `origin/master`: `3949fbed…b271a1`, igual a `versionAnterior.sha256` (V3:13).
  - La v3 solo está en `origin/a/instalador-o1-o3` (verificado con `git log --all`), así que se pudo recalcular sin violar «las versiones publicadas no se editan».
  - **Aviso:** si B ya copió el borrador anterior de la v3 en IQ o AdmCloud (R-O3-4), sus pruebas fallarán por la huella. Es el comportamiento deseado.
- **Pendiente de firma.** La nota de registro para ADR-77, punto 6, está bien planteada como texto propuesto, sin registrar: B tomó la decisión del GUID como técnica, y queda la opción de que la firme el propietario.

#### R-03 · Baja · IQ 0.4.1 ya no comparte la referencia de la raíz [I]

- **Riesgo.**
  - Con el GUID compartido, el contador de referencias de Windows Installer protegía la raíz aunque IQ 0.4.1 no fuera `Permanent`. Con el GUID nuevo, IQ 0.4.1 queda como único cliente de `9E7A0D3C-…`.
  - Al desinstalarlo, el componente se quita y la acción `RemoveFolders` intenta borrar las carpetas de su `CreateFolder` si están vacías [I: comportamiento documentado de `RemoveFolders`].
  - Esto **corrige** el S-08 punto 4 del informe previo («no hay riesgo de borrado»), que solo miraba `RemoveFolder` explícito y era cierto solo mientras el GUID fuera compartido.
  - Consecuencia: solo si la raíz queda vacía, es decir, sin la estación ni otra carpeta de componente. Un usuario podría entonces crear `C:\ProgramData\GPOS NG` como dueño, y la siguiente instalación o el arranque de un servicio lo rechazarían (`DUENO_NO_PERMITIDO`). Es una **denegación de servicio, no una escalada**.
  - Solo laboratorio: no hay IQ 0.4.1 fuera de él, según el blueprint [I].
  - Además, OPS:17 afirma que desinstalar cualquier MSI nunca borra la raíz, y eso no vale para IQ 0.4.1.
- **Evidencia:** FRZ:34; V3:243-247; OPS:16-17; IQ `Package.wxs:181-185` (informe previo).
- **Remediación** (0,05 dp, documental):
  - matizar OPS:17 («salvo IQ 0.4.1, que no es `Permanent` y usa el GUID retirado»);
  - en el retiro de IQ 0.4.1 de laboratorio, desinstalarlo antes de instalar la estación o actualizar primero a la versión de IQ con el GUID nuevo y `Permanent` (R-O3-4);
  - agregar el caso a P-O3-4.

#### R-05 · Baja · GUID con aspecto manual en componentes no compartidos

- **Riesgo.**
  - `OrigenEventosEstacion` = `7A2C4E61-9D35-4B8F-8C17-2E5F6A9B0C42` (PKG:148) muestra secuencias de paso 2 (`A2C4E6`, `A9B0C`) típicas de un GUID escrito a mano.
  - `PatronNoAleatorio` solo detecta diferencias de ±1 o repeticiones (PFI:173-186), así que la prueba de PFI:192 lo deja pasar.
  - No es `Permanent` ni compartido, y solo existe en compilaciones de desarrollo: el impacto de una colisión es bajo y se puede corregir.
- **Remediación** (0,05 dp): regenerar con `New-Guid` mientras siga siendo de desarrollo, y ampliar el detector a diferencias de ±2. Un GUID aleatorio también puede caer en el patrón: se regenera.

### 4.5 Punto (4): D-1, `config\` fuera del MSI de la estación [V]

- **ADR-77, punto 5 («un instalador no declara carpetas de otro componente», `docs/adr/ADR-077.md:34`): se cumple mejor que antes.**
  - El MSI de la estación ya no declara ni comprueba `config\` (PKG:129-132).
  - `GrupoConfigGposNg` vive en un fragmento propio que WiX solo enlaza si se referencia (FRZ:52-73), y lo fijan PFI y `EstacionInstaladorTests`.
  - Si un MSI referenciara `GrupoConfigGposNg` sin `GrupoRaizGposNg`, la tabla quedaría sin raíz y `Ordenar` fallaría cerrada (CCP:347-352).
- **La ACL de `config\` no se debilita.**
  - Sin la API ni Reportes, `config\` no existe y nadie sin privilegios la puede plantar: la raíz da a `AU` solo `0x1200a9` (lectura y recorrido, sin `FILE_ADD_SUBDIRECTORY`), con DACL protegida (FRZ:36; V3:30).
  - Cuando la API o Reportes se instalan después, su fila `ConfigGposNg` (sin servicio, `CrearSiFalta=0`) la comprueba antes de `CreateFolders`.
  - El SDDL de `config\` sigue siendo idéntico al de la raíz, protegido y sin escritor de servicio (FRZ:58-61).

#### R-06 · Baja · Lectores de `config\` sin declararla

- **Riesgo.**
  - `ArchivoInstalacion` (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:30-33`) lo usan `GPOS.Api`, `GPOS.Reportes.Api`, `GPOS.Web` (`src/GPOS.Web/Program.cs:11`) y `GPOS.Migracion` (`src/GPOS.Migracion/Program.cs:38`).
  - `declaran` solo lista Api y Reportes (V3, componente `ConfigGposNg`).
  - **No hay riesgo de seguridad:**
    - el archivo es opcional;
    - solo admite las claves de `SeccionesPermitidas`, sin secretos (`ArchivoInstalacion.cs:25-26`);
    - con la raíz protegida, nadie sin privilegios puede plantar `config\`.
  - Sí hay un **hueco funcional**: en un servidor con solo la Web, `config\` nunca existe y la Web no puede recibir su archivo de instalación.
- **Remediación** (0,05 dp, decisión de contrato): dejar escrito en V3 u OPS que la Web y la Migración leen `config\` pero no la declaran, y que en un servidor sin API la crea el técnico; o agregar la Web a `declaran`. Le toca a B o al arquitecto maestro. No bloquea.

### 4.6 Punto (5): P-O1-5, SID de GPOS.Api, GPOS.Web y GPOS.Reportes [V]

- **La lista blanca no cambia:** sigue siendo SYSTEM, Administradores y TrustedInstaller (CCP:192).
  - El SID de un servicio solo se agrega como **escritor** y solo en **su** fila (CCP:827-831). Nunca se admite como dueño (CCP:815-819).
  - Ninguna fila nueva lleva `Servicio`: la raíz no admite servicio (CCP:355-358) y `config\` va sin servicio (FRZ:66-73).
  - P-O1-5 es **solo una prueba**: no amplía privilegios.
- **La prueba (PCP:181-186):**
  - fija los SID de `GPOS.Api`, `GPOS.Web`, `GPOS.Reportes`, `GPOS.EstacionImpresion` y `TrustedInstaller`;
  - los cruza con una tercera implementación;
  - comprueba que el SID de otro servicio en la fila es `ESCRITOR_NO_PERMITIDO`.
  - El SID de la estación coincide con el SDDL de `DatosEstacion` (PKG:138).
- **Observación sin severidad.** El comentario de la prueba dice que el SID de `GPOS.Api` «es además la que fija `IdentidadProceso` en `feature/modelo-ng`». `git grep` en `origin/feature/modelo-ng` no encuentra esa constante: `IdentidadProceso` lo **calcula** (`src/GPOS.AgenteImpresion/Estacion/IdentidadServicio.cs:42` delega en `IdentidadProceso.SidDeServicio`). Conviene corregir el texto («coincide con el cálculo de…»). La prueba en sí está bien.
- **Nota previa, fuera de este tramo:** `Evaluar` admite cualquier máscara para el SID del servicio en su fila, incluidos `WRITE_DAC` y `WRITE_OWNER`. Es lo que dice el vector («la identidad declarada del servicio dueño»). Además, `CreateFolders` reaplica después el SDDL del MSI, así que no queda abierto. Sin hallazgo.

### 4.7 Punto (6): pendientes S-04 y S-08

- **S-04 (firma de la `.CA.dll`): sigue pendiente**, Media en el informe previo y contenido por K1-02. La contención está fijada por PFI:345 (la estación de desarrollo no admite `-Firmar` y la acción solo se compila en esa rama), y la prueba que fijará la firma ya está escrita con `Skip` (PFI:361-365). Es requisito para retirar K1-02.

#### R-04 · Baja · La guarda de S-04 se puede desactivar sin querer

- **Riesgo.**
  - `FirmaDeLaAccionImplementada` devuelve verdadero si `construir.ps1` contiene `SigntoolFirma` **o** el texto `GPOS.Instalador.Acciones.CA.dll` (PFI:353-354).
  - Basta un comentario o una línea que copie la DLL, sin firmarla, para que la guarda de contención salga en PFI:345 sin comprobar nada.
  - Como la prueba estricta sigue con `Skip` (PFI:361), en ese momento **ninguna** prueba protege S-04 y un MSI firmado podría llevar la acción sin firma.
- **Remediación** (0,05 dp):
  - fusionar las dos pruebas: si el guion compila la acción fuera de `-EstacionDesarrollo` o admite `-Firmar` con la estación, se exigen las aserciones estrictas (sin `Skip`); si no, la contención;
  - o endurecer el detector: exigir `-p:SigntoolFirma=` en la línea `dotnet build` de la acción y `Firmar-Archivo` sobre la `.CA.dll`.

- **S-08: cerrado documentalmente**, con la salvedad de R-03.
  - OPS cubre el retiro manual, la regla de cambio del SDDL con vector nuevo y la coordinación de consumidores, y lo que nunca se hace.
  - Falta P-O3-5 en los conectores (de B).

## 5. Controles bien implementados [V]

- `ComprobarPadre`:
  - solo pide `FILE_READ_ATTRIBUTES` y no sigue reanálisis;
  - aplica la misma regla de ruta final que la comprobación principal y la forma larga para nombres 8.3;
  - y no lee la seguridad de una carpeta que no es de la tabla (CCP:629-660).
- La comprobación de ruta final de la raíz se conserva **después** de crearla como segunda barrera (CCP:600-604).
- Las dos acciones llevan exactamente la misma condición, y la prueba lo fija tras preprocesar la variable (PFI:300). `GposFeatureCarpetas` es un literal en el `.wixproj` y no se puede pasar como propiedad (WIXPROJ:18).
- D-3: quitar solo la estación no corre la acción, así que una desinstalación nunca crea la raíz.
- `guidRetirados` se verifica completo, y los GUID canónicos se contrastan con un detector de patrones (PFI:192).
- Huella del vector recalculada y coherente. v2 intacta en `origin/master`.
- No hay secretos ni pasos de explotación en OPS. El procedimiento de «Carpeta insegura» trata el caso primero como posible incidente y prohíbe corregir la DACL a mano.

## 6. Remediaciones priorizadas

| Prioridad | Hallazgos | Cuándo | Esfuerzo (±50 %) |
|---|---|---|---|
| 1 | S-04 (heredado) y P-O1-7 con FIPS, `ADDSOURCE` y `ADVERTISE` | Antes de retirar K1-02 | 0,25 dp + laboratorio |
| 2 | R-01 (guarda genérica de `GposFeatureCarpetas`) | Antes de que Api, Web o Reportes consuman el fragmento | 0,1 dp |
| 3 | R-04 (guarda de S-04 robusta) | Con la próxima corrección del PR | 0,05 dp |
| 4 | R-02, R-03, R-05 y R-06 | Antes de la entrega 1 (R-03, antes de retirar IQ 0.4.1 del laboratorio) | 0,2 dp |

Total de A: unos 0,4 dp (0,2 a 0,6) más el laboratorio ya previsto. Costo de infraestructura: USD 0.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

- No hay hallazgos Críticos ni Altos.
- Los siete hallazgos del informe previo que debían quedar cerrados siguen cerrados.
- P124-02 (opción b) no introduce un TOCTOU explotable sin privilegios y falla cerrada en todos los caminos.
- S-06, S-07, D-1 y P-O1-5 están bien resueltos y no amplían privilegios.

Condiciones:
- S-04 y P-O1-7 siguen siendo requisito para retirar K1-02.
- R-01 es requisito antes de que otro MSI del núcleo use el fragmento.

## Supuestos

- No compilé ni ejecuté las pruebas. Tomo como ciertos los resultados que declara el autor.
- El comportamiento de WiX ante una variable sin definir o vacía, el de Windows Installer ante `&Feature` inexistente, `ADDSOURCE` con componentes `LocalOnly` y `RemoveFolders` sobre la tabla `CreateFolder` es inferido de la documentación. Hay que confirmarlo en P-O1-7 y P-O3-4.
- Las ACL por omisión de `C:\` y `C:\ProgramData` (que los usuarios pueden crear pero no renombrar `ProgramData`) son las de una instalación estándar de Windows 10/11 [I].
- Que no hay IQ 0.4.1 fuera del laboratorio lo dice el blueprint [I].

## Decisiones candidatas a ADR

- R-06: si `GPOS.Web` (y `GPOS.Migracion`) deben figurar en `declaran` de `config\` o quedar como lectores que no la declaran. Es una precisión de ADR-77, punto 5, y del vector v3 antes de publicarlo. Le toca al arquitecto maestro con B.

## Entregas a otros agentes

- **desarrollador (A):** R-01 (prueba genérica), R-02 (condición y `AllowAdvertise="no"`), R-04, R-05 y la corrección del comentario de P-O1-5. Una línea en OPS sobre `PUNTO_DE_REANALISIS` en el padre de la raíz y la salvedad de R-03 en OPS:17.
- **devops (A y B):** S-04 (firma de la `.CA.dll` en `construir.ps1`); P-O1-7 con FIPS, `ADDSOURCE` y `ADVERTISE`; P-O3-4 con la desinstalación de IQ 0.4.1 junto a la estación (R-03).
- **B (conectores):** la huella de la v3 cambió (`6879e0b2…`); adoptar el GUID `66D68CDE-…` con `Permanent` (R-O3-4) y P-O3-5.
- **arquitecto-maestro:** R-06 y, si el propietario quiere firmarla, la nota de ADR-77, punto 6.
