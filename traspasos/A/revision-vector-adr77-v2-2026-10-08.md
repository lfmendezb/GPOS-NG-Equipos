# Revisión del vector de ADR-77, versión 2 (`adr077-carpetas.v2.json`)

**Fecha:** 2026-10-08 · **Revisa:** arquitecto-software (equipo A) · **Para:** Arquitecto Maestro y propietario · **Origen:** aviso B-a-A `2026-10-08-vector-adr77-v2-para-revision.md`
**Estado de la revisión:** Aprobado con observaciones (recomendación técnica). La precisión de ADR-77 de la sección 5 está en estado **Propuesto** y queda **Pendiente de firma** del propietario.

## 0. Resumen

| # | Tema | Resultado | Severidad / costo | ¿Firma del propietario? |
|---|---|---|---|---|
| — | **Veredicto** | **Aceptar con cambios** (CB-1 a CB-5). La v2 es compatible con la v1, la huella es correcta y V2-2 a V2-5 son correctos | — | Solo por VV-01 y VV-04 |
| C-1 | Compatibilidad con v1 | **Verificada**: solo cambian `version`, `descripcion` y `fuentes` (2 → 4 elementos, las 2 de v1 intactas); el resto son campos o propiedades nuevos | — | No |
| C-2 | SHA-256 `139fb288…43ac`, UTF-8 sin BOM, LF | **Verificado** byte a byte sobre el objeto git; `.gitattributes` fija `eol=lf` en `master` y en la rama de B | — | No |
| V2-1 | Identidad del proceso como dueña al arrancar | **Correcto en seguridad con condiciones**; faltan dos (CB-1, CB-2) | Media (si se implementa sin CB-1) | **Sí (VV-01)** |
| V2-2 | `SEGURIDAD_ILEGIBLE`, falla cerrada, 1603 | **Correcto**; falta escribir la carrera «ya existe» (CB-4) | Baja | No |
| V2-3 | `CREATOR OWNER` como plantilla no escritora | **Correcto** (S-1-3-0, S-1-3-1 y S-1-3-4 bien tratados) | — | No (enterado) |
| V2-4 | Códigos estables del MSI | **Correcto**; coinciden con el conector | — | No |
| V2-5 | Máscara `0x500D0156` | **Correcta** (recalculada); el SDDL de la raíz es coherente con ella (AU `0x1200a9` no es escritor) | — | No |
| VV-01 | Generalizar SF-04 | **Sí**, como precisión del punto 4 de ADR-77, con CB-1 a CB-3 | — | **Sí** |
| VV-02 | Identidad declarada de la API | `HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi` (SID), verificada antes de `builder.Build()` | +0,03 sp en N-14 | No (diseño) |
| VV-03 | No declarar en el MSI lo que crea el proceso | **Sí, en v2** (campo aditivo) | 0 | No |
| VV-04 | Carpeta creada por herencia | **Sí, con condiciones**, como precisión del punto 2 | 0 (evita 0,05 sp y un MSI a B) | **Sí** |
| VV-05 | Mapa `sids` | **v3**, con N-11 (instalador de la API) | 0 ahora | No |
| VV-06 | Unificar códigos | **Solo los del MSI** | 0 | No |
| VV-07 | Publicación | v1 se queda en `master`; v2 se publica **después de la firma y con CB-1 a CB-5**, con huella nueva | 0,01 sp | No |
| — | **Esfuerzo** | A: **+0,03 sp** (N-14, ya sujeto a la regla de deslizamiento); B: 0,02 sp de edición + 0,05 sp de pruebas | **Nada se adelanta en el núcleo antes del corte** | — |

**Prioridad (ventas e inventario primero).** Lo único que toca el núcleo antes del corte es V2-1 dentro de N-14 (+0,03 sp sobre 0,10 sp), que ya va con H-17 v2 y ya tiene la regla firmada de PA-77-3: si no cabe, pasa a condición antes de la primera instalación fuera de desarrollo. **Recomiendo no adelantar nada más**: VV-02 completo (registro escrito por el MSI) cae en N-11, que no es del corte.

---

## 1. Fuentes y método

- Vector v2 y nota: `GPOS NG`, `origin/b/conector-admcloud-diseno` (commit `7b36a74`), `docs/contratos/vectores/adr077-carpetas.v2.json` y `2026-10-08-adr077-vector-v2-notas.md`. Solo `git fetch` y `git show`.
- v1: la misma ruta en `origin/master` (`d00199d`) y en la rama de B: SHA-256 `ebb50202…0c0a` en las dos (verificado), igual al que declara `versionAnterior.sha256` de v2.
- ADR-77: `origin/master:docs/adr/ADR-077.md`. **Nota:** en `master` ADR-77 ya figura **Aceptado** (firmado el 2026-10-08); la copia local `Solucion GPOS NG\hoja-firma-adr77-carpetas-2026-10-08.md` sigue diciendo «Pendiente de firma» (copia de trabajo previa a la firma; no afecta a esta revisión).
- Conector de IQ: `GPOS-NG-AddOn-IQS`, commit `7ec54c4` (el que cita B), leído con `git show`.
- No compilé ni ejecuté pruebas. Python no está instalado; la comparación recursiva v1/v2 se hizo con un script de PowerShell en el directorio temporal de la sesión.

*Verificado* = leído o calculado hoy. *Inferido* = conclusión o estimación (sp ±50 %).

## 2. Verificaciones

### 2.1 Compatibilidad real con v1 (C-1) — verificada

Comparación recursiva campo a campo (v1 ⊂ v2). Resultado literal:

```
VALOR $.version            VALOR $.descripcion        LARGO $.fuentes 2 4
NUEVO $.comprobacionPrevia.rechazaSiLaCarpetaYaExisteY[0..3].codigo
NUEVO $.comprobacionPrevia.fallaCerrada   NUEVO $.comprobacionPrevia.comoLee
NUEVO $.comprobacionAlArrancar.fallaCerrada   NUEVO $.comprobacionAlArrancar.duenoAdicional
NUEVO $.versionAnterior  NUEVO $.cambiosDesdeV1  NUEVO $.escritura  NUEVO $.identidadesEspeciales
```

- Ningún campo de v1 falta ni cambia de valor, salvo los tres previstos. Los elementos 0 y 1 de `fuentes` son idénticos a los de v1.
- `escritoresAdmitidos.lista`, `duenosAdmitidos`, `sddl` y los cuatro `caso` quedan iguales: la prueba del conector que los compara (`InstaladorVectorAdr077Tests.cs:139-142` y `:237-238`, citadas por B) no se rompe por contenido, solo por la ruta, la huella y `version`, como B ya prevé.
- Un lector con esquema cerrado (`additionalProperties: false`) sí se rompería; no hay ninguno en GSF (inferido: ni el conector ni el núcleo validan el vector con esquema).

### 2.2 Huella y codificación (C-2) — verificada

- `git show origin/b/conector-admcloud-diseno:docs/contratos/vectores/adr077-carpetas.v2.json | sha256sum` → `139fb288dfa1fb51bee16ecacac1922038993d1e865f0b836ce5d2a9074443ac`. Coincide.
- Primer byte `{` (sin BOM), 0 retornos de carro, termina en `}\n`.
- `.gitattributes:65-66` (en `master` y en la rama de B): `docs/contratos/vectores/** text eol=lf`. La huella es estable al extraer en Windows.

### 2.3 V2-1 a V2-5 en seguridad

**V2-5, máscara `0x500D0156` — correcta.**
- Recalculada: `0x2|0x4|0x10|0x40|0x100|0x10000|0x40000|0x80000|0x10000000|0x40000000 = 0x500D0156`. Igual a `MascaraEscritura` del conector (`ComprobacionCarpetas.cs`, constante con esos mismos bits).
- Coherencia con el SDDL de la raíz: `0x1200a9 & 0x500D0156 = 0` (SYNCHRONIZE, READ_CONTROL, lectura y ejecución), así que AU no cuenta como escritor; `FA` (`0x1F01FF`) sí.
- Exclusiones correctas: `ACCESS_SYSTEM_SECURITY` (`0x01000000`, solo la SACL, exige `SeSecurityPrivilege`) y `MAXIMUM_ALLOWED` no son derechos de escritura de una ACE.
- Contar las ACE «inherit-only» es lo correcto: una `(A;OICIIO;FA;;;BU)` no da escritura sobre el padre pero sí sobre todo hijo nuevo.
- No contar las denegaciones es conservador (solo puede rechazar de más, nunca admitir de más).

**V2-3, `CREATOR OWNER` — correcto.**
- S-1-3-0 no aparece en ningún token; una ACE suya que no sea solo heredable no concede nada sobre el objeto mismo (inferido, igual que B; coincide con el modelo de acceso de Windows). Al heredarse, Windows la sustituye por el dueño real, que se comprueba con las mismas listas: la plantilla no amplía la lista.
- `CREATOR GROUP` (S-1-3-1) y `OWNER RIGHTS` (S-1-3-4) como `escritor_no_admitido`: correcto y conservador. Nombrarlos evita la analogía con S-1-3-0.
- No se agrega S-1-3-0 a `escritoresAdmitidos.lista`: correcto (mantiene v1 y no sugiere que pueda ser dueño).
- Caso límite que el vector no menciona (Baja, enterado): con la directiva «Propietario predeterminado de los objetos creados por miembros del grupo Administradores = creador del objeto», un administrador que crea un hijo lo deja con su SID personal como dueño y la comprobación lo rechaza (`DUENO_NO_PERMITIDO`). Es falla cerrada; basta con documentarlo en operaciones.

**V2-2 y V2-4, falla cerrada con 1603 — correctos.**
- 1603 (`ERROR_INSTALL_FAILURE`) es lo que devuelve `msiexec` cuando una acción diferida devuelve fallo; coherente con el punto 3 de ADR-77.
- `SEGURIDAD_ILEGIBLE` en un campo aparte: correcto por semántica («no se pudo saber» ≠ «existe y es insegura») y por compatibilidad.
- Los cuatro códigos coinciden con `Rechazo.Codigo` del conector (`ComprobacionCarpetas.cs:84-91`, verificado); el quinto es la rama por omisión del mismo `switch`.
- `comoLee` refleja lo que hace `ComprobarUna` (verificado): `CreateFileW` con `FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS`, atributos con `GetFileInformationByHandle` y descriptor con `GetSecurityInfo` sobre el **mismo** identificador; `NO_EXISTE` solo con `ERROR_FILE_NOT_FOUND`/`ERROR_PATH_NOT_FOUND`.
- **Falta escribir un caso (CB-4, Baja):** si al crear la raíz la llamada devuelve «ya existe» (otra creación ganó la carrera), el conector la comprueba como existente (`ComprobarUna`: `error != ErrorYaExiste` → ilegible; si no, sigue a la comprobación). El vector solo lo da a entender; dos instaladores podrían tratarlo distinto.
- Al arrancar: `fallaCerrada` es correcto. Observación para B (Baja, inferida, no bloquea): el arranque del conector evalúa las ACE con `GetAccessRules` de .NET y no con `RawSecurityDescriptor` como el MSI; no verifiqué que una ACE de tipo no evaluable llegue a «escritor ajeno» como dice `escritura.siempreEscritorAjeno`. Conviene una prueba en `InstaladorVectorAdr077Tests` o alinear el arranque con `Evaluar`.

**V2-1, dueño adicional al arrancar — correcto con condiciones; necesita firma.**
- La premisa es verdadera: Windows hace dueño de lo creado al dueño por omisión del token (verificado por B con una cuenta normal; para cuentas virtuales, inferido por el mismo mecanismo). Con la v1 al pie de la letra, toda carpeta o archivo creado por el servicio falla su propia comprobación; esto alcanza a N-14 (los archivos de llaves del anillo de la API los crea la identidad de la API).
- El argumento de «no da poder nuevo» es correcto mientras la identidad ya tenga control total: el dueño solo suma `READ_CONTROL` y `WRITE_DAC` implícitos.
- La condición de verificar antes la identidad está bien puesta y el conector la cumple (`ServicioConector.cs:58-68`, orden fijo; `ComprobacionesArranque.cs:83-96`, `IDENTIDAD_PROCESO`; verificado).
- Faltan dos cosas:
  - **CB-1 (Media).** «Cuenta de servicio o virtual» deja pasar `NT AUTHORITY\NETWORK SERVICE` (S-1-5-20) y `LOCAL SERVICE` (S-1-5-19), que son **compartidas** por muchos servicios del equipo: cualquiera de ellos quedaría admitido como dueño y escritor. Y no dice de dónde sale la identidad declarada: si la fuente la puede escribir alguien que no es administrador, la verificación previa no protege nada.
  - **CB-2 (Media).** El ámbito dice «la carpeta de datos propia del componente». El anillo de la API, la Web y `GPOS.Migracion` se comprueba «en la ruta configurada, esté o no bajo `GPOS NG`» (ADR-77, punto 4). Si el anillo está fuera de la carpeta del componente, sus archivos de llaves (dueño: la identidad de la API) quedan fuera del ámbito y N-14 rechazaría su propio anillo.
  - **CB-3 (Baja).** El conector omite la verificación de identidad en `ModoPruebas` pero sigue admitiendo a `IdentidadDelProceso()` como dueña en `VerificarCarpeta` (`ServicioConector.cs:136-146`). Es aceptable en pruebas; el vector debe decir que, si se omite la verificación, el dueño adicional no se admite fuera del perfil de pruebas y ese perfil no existe en Release.

## 3. Cambios pedidos a la v2 (CB-1 a CB-5)

Todos son aditivos o precisan texto de campos nuevos de v2; ninguno toca un campo de v1. Cambian la huella.

| # | Campo | Cambio |
|---|---|---|
| CB-1 | `comprobacionAlArrancar.duenoAdicional.condiciones` | Sustituir la segunda condición por: «La identidad declarada es una cuenta virtual dedicada (`NT SERVICE\…`, S-1-5-80-…; `IIS APPPOOL\…`, S-1-5-82-…) o una gMSA o cuenta de dominio dedicada al componente; nunca LOCAL SERVICE (S-1-5-19), NETWORK SERVICE (S-1-5-20), la cuenta de una persona ni un grupo». Agregar: «La identidad declarada se lee como SID de una fuente que solo pueden escribir SYSTEM y Administradores (la clave de HKLM que escribe el MSI del componente)». |
| CB-2 | `comprobacionAlArrancar.duenoAdicional.ambito` | «Solo la carpeta de datos propia del componente y su contenido a cualquier profundidad, **y la carpeta del anillo de Data Protection configurada para ese proceso y su contenido**, donde esa identidad ya es escritora declarada». |
| CB-3 | `comprobacionAlArrancar.duenoAdicional.condiciones` | Agregar: «Si un perfil de pruebas omite la verificación de identidad, no se admite el dueño adicional fuera de ese perfil, y la compilación Release no admite ese perfil». |
| CB-4 | `comprobacionPrevia.comoLee` | Agregar: «si al crear la raíz la llamada falla porque ya existe, se comprueba como carpeta existente». |
| CB-5 | nuevos (VV-03 y, si se firma, VV-04) | `comprobacionPrevia.noDeclara` y `creacionPorHerencia` (sección 4, VV-03 y VV-04). Agregar las dos a `cambiosDesdeV1` (V2-6 y V2-7). |

**Quién edita:** B (el borrador es de B y está en su rama; un solo editor por árbol). Unas 0,02 sp. A publica en `master` con la huella final.

## 4. Respuestas a VV-01 a VV-07

**VV-01. Generalizar SF-04 como regla del vector (V2-1).**
- **Recomendación: Sí, como precisión del punto 4 de ADR-77, con CB-1 a CB-3, y con firma del propietario.** Es una ampliación de lo que se admite al arrancar en un criterio de seguridad de un ADR aceptado; no la puede introducir un vector por su cuenta.
- *Alternativa descartada:* dejarla como desviación solo del conector. A tendría que repetirla en la API, la Web y cada servicio, contra el punto 6 («una sola definición»).
- *Alternativa descartada:* que el MSI cree todo de antemano. No cubre los archivos de llaves nuevos ni las entradas de la licencia.
- *Alternativa descartada:* dar `SeRestorePrivilege` para fijar otro dueño. Contradice ADR-76.
- Texto propuesto: sección 5, P-77-4.

**VV-02. Identidad declarada de la API y su verificación.**
- **Dónde se declara:** `HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi`, el contrato A-04 que ya usa ADR-75 (`ADR-075.md:21`). El valor es el **SID** (no el nombre), escrito por el MSI de la API (N-11) con la clave escribible solo por SYSTEM y Administradores.
  - Bajo IIS: `IIS APPPOOL\<grupo de {INST}>` (S-1-5-82-…), un grupo propio por instalación (P7C `:921`).
  - Como servicio: `NT SERVICE\<servicio de {INST}>` (S-1-5-80-…).
  - En otra máquina del dominio: gMSA o cuenta dedicada (estándar multiempresa `:878`).
  - El MSI resuelve el SID con `LookupAccountName` al instalar; no se recalcula en la API (evita depender del algoritmo de los SID S-1-5-82, que es inferido).
- **Cuándo se verifica:** en `VerificacionIdentidades` (`GPOS.Api/Seguridad`, estándar multiempresa `:850`), **antes de `builder.Build()`**, porque cualquier servicio que se resuelva en la construcción puede cargar el anillo. Orden fijo, protegido por una prueba de arquitectura:
  1. el SID de usuario del token es igual a `IdentidadApi` y su tipo es uno de los de CB-1;
  2. privilegios del token (ADR-76);
  3. carpetas (`Licencia`, anillo) con el dueño adicional;
  4. configuración de Data Protection (`CifradorAnillo`, H-17 v2) y rechazo de `DpapiMaquina` (N-15).
- **Web:** necesita su propio valor (`IdentidadWeb`) si tiene identidad propia; se fija en N-11. **`GPOS.Migracion`:** la ejecuta un operador; no tiene identidad declarada, **no usa el dueño adicional** y debe correr elevado (dueño por omisión BA, ya admitido) o fallar cerrado.
- **Antes del corte (sin MSI de la API):** N-14 lee la misma clave; en Debug sin clave, advierte y sigue (desarrollo); en Release sin clave, no arranca. La clave la escribe el script de devops del entorno de prueba.
- **Costo:** +0,03 sp en N-14 (inferido). No es firma: es diseño dentro de lo firmado.

**VV-03. Regla «un instalador no declara las carpetas que su proceso crea en tiempo de ejecución».**
- **Recomendación: Sí, en v2** (CB-5), como `comprobacionPrevia.noDeclara`. Es la consecuencia directa de V2-1: si el MSI las declarara, una reparación las encontraría con dueño = identidad del servicio y fallaría con `DUENO_NO_PERMITIDO` (1603). Es un defecto operativo seguro que conviene evitar desde el primer instalador (N-11).
- *Alternativa descartada:* admitir el dueño adicional también en el MSI. Amplía la comprobación previa, que es la que ve lo plantado antes de instalar.
- *Alternativa descartada:* esperar a v3. Obligaría a otra huella y otra actualización de pruebas sin motivo, porque v2 ya se rehace por CB-1 a CB-4.
- No requiere firma: aplica el punto 3 de ADR-77 sin cambiarlo.

**VV-04. Carpeta creada por herencia dentro de la carpeta de componente protegida.**
- **Recomendación: admitirla, con condiciones, como precisión del punto 2 de ADR-77 (firma del propietario).** El objetivo del punto 2 (B-3) es que no haya ventana entre crear y proteger. Si el padre tiene la DACL protegida, ya pasó la comprobación de ese arranque y no tiene escritores ajenos, nadie ajeno puede crear ni sustituir el hijo, y la DACL del hijo queda fijada en la misma llamada de creación. Pero el texto firmado dice «con su DACL protegida», y la herencia no pone la marca de protección: por eso es una precisión y no una lectura.
- Condiciones:
  1. solo dentro de la carpeta de datos del propio componente;
  2. el padre tiene DACL protegida y pasó la comprobación de arranque de ese mismo proceso;
  3. si es el anillo de la API, la Web o `GPOS.Migracion`, los lectores heredados cumplen el punto 4 (SYSTEM, Administradores y la identidad); si no, se crea con DACL protegida explícita;
  4. fuera de la carpeta de componente (por ejemplo, un anillo en una ruta configurada fuera de la raíz), siempre DACL protegida explícita (N-16).
- **Efecto:** el anillo del conector (`Anillo.cs:23`, `Directory.CreateDirectory` dentro de la carpeta de datos) cumple sin cambios. Si el propietario dice **No**: B cambia el conector, unas 0,05 sp y un MSI nuevo; el núcleo no cambia (N-16 ya crea con DACL explícita).
- Texto propuesto: sección 5, P-77-2.

**VV-05. Mapa `sids`.**
- **Recomendación: v3, junto con N-11** (el primer instalador de A que lo consumiría). Solo los SID bien conocidos e independientes de la instalación (S-1-5-18, S-1-5-32-544, TrustedInstaller S-1-5-80-956008885-…, S-1-5-32-545, S-1-5-11, S-1-1-0). Hoy hay un solo consumidor y ya los traduce y prueba; no aporta antes del corte.

**VV-06. Unificar los códigos del arranque.**
- **Recomendación: solo los del MSI (V2-4)**, como propone B. Los eventos de arranque son propios de cada componente y tienen otros consumidores (registro de eventos, soporte). Reabrir si aparece una consola común de diagnóstico.

**VV-07. Publicación.**
- **Recomendación:**
  - v1 se queda en `master` sin cambios (`ebb50202…0c0a`, verificado); los vectores son inmutables por versión.
  - **No se publica la v2 de `139fb288…43ac`**: se publica la v2 con CB-1 a CB-5, **después de la firma de P-77-4 (y P-77-2)**, porque V2-1 amplía un criterio de un ADR aceptado. Si el propietario rechaza P-77-2, se publica sin `creacionPorHerencia`.
  - A avisa a B la huella final; B actualiza `InstaladorVectorAdr077Tests` (0,05 sp).
  - Mientras tanto, el conector sigue con SF-04 como desviación aceptada; esperar no rompe nada (riesgo 3 de la nota de B).

## 5. Texto propuesto para la firma (estado: Propuesto)

> **Precisiones de ADR-77 (2026-10-08) · Estado: Propuesto · Pendiente de firma del propietario**
>
> **P-77-4. Dueño adicional al arrancar (precisa el punto 4).** Al arrancar, además de SYSTEM, Administradores y TrustedInstaller, se admite como **dueña** la identidad declarada del proceso, solo en la carpeta de datos de su propio componente y en la carpeta del anillo de Data Protection configurada para ese proceso, y en su contenido a cualquier profundidad. No se admite en la raíz, en `Conectores`, en `Conectores\registro`, en carpetas de otro componente ni en la comprobación previa del MSI (punto 3), que sigue sin cambios. Condiciones:
> 1. Antes, y en un orden fijo protegido por una prueba de arquitectura, el proceso verifica que el SID de su token es el declarado. El SID declarado se lee de una clave de HKLM escrita por el MSI del componente y escribible solo por SYSTEM y Administradores (para la API, `HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi`, ADR-75).
> 2. La identidad declarada es una cuenta virtual dedicada (`NT SERVICE\…` o `IIS APPPOOL\…`) o una gMSA o cuenta de dominio dedicada al componente; nunca LOCAL SERVICE, NETWORK SERVICE, la cuenta de una persona ni un grupo.
> 3. Si un perfil de pruebas omite la verificación de identidad, el dueño adicional no se admite fuera de ese perfil, y la compilación Release no admite ese perfil.
> 4. Un instalador no declara las carpetas que el proceso de su componente crea en tiempo de ejecución.
>
> *Motivo:* Windows hace dueña de lo que crea un proceso a su identidad, y el punto 2 admite que un servicio cree carpetas; sin esta precisión, toda carpeta o llave creada en tiempo de ejecución falla su propia comprobación. Ser dueña no da a esa identidad poder nuevo: ya escribe con control total. *Origen:* SF-04 del conector de IQ (desviación aceptada), generalizada. *Alternativas descartadas:* desviación por componente (contradice el punto 6); crear todo desde el MSI (no cubre llaves ni entradas nuevas); `SeRestorePrivilege` (contradice ADR-76).
>
> **P-77-2. Creación por herencia (precisa el punto 2).** Una carpeta creada en tiempo de ejecución **dentro de la carpeta de datos de su propio componente** puede crearse heredando la DACL de su padre, en una sola llamada, si el padre tiene DACL protegida y pasó la comprobación de arranque de ese proceso. Si es el anillo de la API, la Web o `GPOS.Migracion`, los lectores heredados deben cumplir el punto 4; si no, se crea con DACL protegida explícita. Fuera de la carpeta de componente, toda carpeta se crea con DACL protegida explícita.
>
> *Motivo:* el punto 2 busca que no haya ventana entre crear y proteger; con el padre protegido y sin escritores ajenos, esa ventana no existe. *Alternativa descartada:* exigir DACL explícita también dentro (cuesta 0,05 sp y un MSI nuevo al conector de IQ sin reducir riesgo).
>
> **Costo:** A, +0,03 sp en N-14 (dentro de H-17 v2, con la regla de PA-77-3 si no cabe en el corte). B, 0,02 sp para editar v2 y 0,05 sp de pruebas. Infraestructura: USD 0.

| # | Qué se firma | Recomendación | Firma |
|---|---|---|---|
| **P-77-4** | Dueño adicional al arrancar (VV-01, con VV-03) | **Sí** | [ ] Sí · [ ] No: ______ |
| **P-77-2** | Creación por herencia dentro de la carpeta de componente (VV-04) | **Sí** | [ ] Sí · [ ] No (B cambia el conector, 0,05 sp) |
| Enterado | V2-2 a V2-5 (falla cerrada, códigos, `CREATOR OWNER`, máscara) aplican ADR-77 sin cambiarlo | Enterado | [ ] Enterado |

**Si el propietario rechaza P-77-4:** la v2 se publica sin `duenoAdicional`, el conector conserva SF-04 como desviación propia, y N-14 debe crear el anillo y sus llaves de modo que el dueño sea SYSTEM o Administradores, lo que hoy no tiene camino sin `SeRestorePrivilege` (contradice ADR-76). En la práctica, N-14 no podría comprobar el contenido del anillo: **recomiendo firmar**.

## 6. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-1 | V2-1 se implementa sin verificar la identidad, o con una identidad compartida (NETWORK SERVICE) | Alta si ocurre | CB-1 y CB-3 en el vector; prueba de arquitectura del orden en cada componente |
| R-2 | N-14 rechaza el anillo de la API fuera de la carpeta de componente | Media | CB-2 |
| R-3 | Reparación del MSI falla con `DUENO_NO_PERMITIDO` | Media (operación) | VV-03 / P-77-4, condición 4 |
| R-4 | Dos instaladores tratan distinto la carrera al crear la raíz | Baja | CB-4 |
| R-5 | El arranque del conector no trata una ACE no evaluable como escritor ajeno (inferido) | Baja | Prueba en el conector (B) |
| R-6 | Se publica la v2 antes de la firma | Media | VV-07: publicar solo después de P-77-4 |

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica: aceptar la v2 con CB-1 a CB-5; P-77-4 y P-77-2 Pendientes de firma)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-vector-adr77-v2-2026-10-08.md`
- Supuestos: cifras en sp inferidas (±50 %); que una cuenta virtual queda como dueña de lo que crea (inferido, igual que B); que ningún consumidor valida el vector con esquema cerrado (inferido); que el arranque del conector trata bien las ACE no evaluables (no verificado).
- Decisiones candidatas a ADR: P-77-4 (precisión del punto 4 de ADR-77, dueño adicional al arrancar) y P-77-2 (precisión del punto 2, creación por herencia); las redacta como precisión el Arquitecto Maestro.
- Entregas a otros agentes: arquitecto-maestro → llevar P-77-4 y P-77-2 a la firma; equipo B (arquitecto de software) → CB-1 a CB-5 en la v2 y prueba de ACE no evaluables en el arranque; documentador-tecnico → publicar la v2 final en `master` junto a la v1 y anotar las precisiones en ADR-77 tras la firma; desarrollador-backend → VV-02 dentro de N-14 (+0,03 sp); devops → `IdentidadApi` en N-11 y en el script del entorno de prueba.
- Próximo paso recomendado: el propietario firma P-77-4 y P-77-2; B ajusta la v2 y A la publica con la huella final.

---
**Firma del propietario (2026-10-08):** «Como recomiendas, firmo las dos». **P-77-4: Sí. P-77-2: Sí.** V2-2 a V2-5: enterado. Estado de las precisiones: **Aceptado**.
