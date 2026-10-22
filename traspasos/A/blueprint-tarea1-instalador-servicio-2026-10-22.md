# Blueprint previo: Tarea 1 de B (instalador con `--servicio`, firma de la `.CA.dll` y P-O1-7 con FIPS)

- **Fecha:** 2026-10-22 · **Agente:** arquitecto-software (equipo A) · **Estado:** propuesta técnica previa a construir. Lo que exige firma queda **Pendiente de firma** del propietario (C2).
- **Encargo:** aviso B-a-A `avisos/B-a-A/2026-10-21-tareas-nuevas-para-a.md`, Tarea 1. Fecha prometida a B: **2026-11-13**.
- **Método:** solo lectura con `git show`, `git grep` y `gh pr view` sobre `origin/feature/modelo-ng` (`b4378650`, contiene #124 = `bc05f541` y #136 = `d0801fd4`) y `origin/master` (`b1bc9ba8`) de `GPOS-NG`. No se usaron árboles de trabajo y no se compiló ni se ejecutó nada.
- **Marcas:** **[V]** = verificado en el código o en el documento, con cita `ruta:línea` (de `origin/feature/modelo-ng` salvo que diga `master` o un documento del área común). **[I]** = inferido, se confirma al construir o en el laboratorio.
- **Fuentes:**
  - Revisión de #127 (`traspasos/A/revision-seguridad-pr127-n1-2026-10-21.md`, S-01 a S-07).
  - Revisión de #136 (`traspasos/A/revision-seguridad-n1-endurecimiento-2026-10-21.md`, R-01 a R-06).
  - Revisión y relectura de #124 (`revision-seguridad-o1-o3-2026-10-20.md`, S-03 y S-04; `relectura-seguridad-o1-o3-2026-10-21.md`, R-02 y R-04).
  - Operaciones de la API como servicio (`traspasos/A/operaciones-gpos-api-servicio-2026-10-21.md`, **OPS-API**, L-1 a L-16).
  - Plano O-1/O-3 (`blueprint-instalador-o1-o3-n10-2026-10-20.md`, P-O1-6 y P-O1-7).
  - `docs/operaciones/2026-10-19-diseno-instalador-reportes.md` en `master` (**INS**).
  - Hoja del tramo 4 en `master` (`docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md`, **HOJA**).
  - ADR-33, ADR-76 y ADR-77 en `master`.
  - Plan del DEMO (`traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md`, **DEMO**).
  - Blueprint de T4-06 (`traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md`).

---

## 0. Resumen

1. **El supuesto del encargo no se cumple: `GPOS.Api.msi` no existe** (hallazgo H-1). No hay ningún `ServiceInstall` de `GPOS.Api` donde poner `Arguments="--servicio"`. Para cerrar R-01 hace falta **construir un MSI mínimo de la API**, o dejar solo un contrato que el MSI futuro tendrá que cumplir. Recomiendo el MSI mínimo (`instalador/Api/`), que es la primera pieza del paquete único firmado (B-1) y la que necesitan L-1 y L-2. **Lo decide B (Q-1).**
2. **La firma de la `.CA.dll` solo está «viva» en un MSI que siempre lleve la acción.** En el agente, la acción solo se compila con `-EstacionDesarrollo`, y esa compilación no admite `-Firmar` (K1-02). Firmar ahí sería código muerto hasta que el propietario retire K1-02. Con `GPOS.Api.msi`, que lleva la acción siempre (ADR-77, punto 3), la firma se usa de verdad desde el primer día. En el agente se deja lista y latente.
3. **Hoy no existe un certificado de firma** (ADR-33: falta el nombre legal y, con él, la solicitud; las YubiKeys llegan hacia el 11-03). El PR entrega la tubería de firma, sus pruebas y un ensayo en la VM con un certificado de laboratorio desechable. **La primera firma real es del custodio**, cuando exista el certificado.
4. **P-O1-7 es una prueba elevada de laboratorio.** Ningún agente la ejecuta (incidente del 2026-10-08). A entrega el procedimiento, el guion de casos (incluido FIPS) y la plantilla de evidencia. La ejecuta el técnico en la VM de `LFMB` cuando haya ventana.
5. **Esfuerzo:** de 3,5 a 4,0 dp de A [I, ±40 %] con el MSI mínimo; 1,75 dp sin él. Se divide en tres PR pequeños (sección 9). **El 11-13 es viable para abrir los PR, no para tener la evidencia del laboratorio**, que depende de la ventana de la VM.
6. **Choques:** ninguno de archivo con PR-4 (#139) ni con PR-2 (#140), porque no tocan `instalador/`. Sí hay choques funcionales:
   - PR-4 retira `FijarEscuchaPorOmision`: por S-01 y S-02, un MSI de la API firmado no debe existir antes de PR-4 (guarda G-PR4).
   - Q-6 de T4-06: sin la dirección del reenvío, la principal Release no arranca.
   - PR-V del DEMO: `sc create` de `GPOS.Api` con los mismos argumentos, privilegios y SDDL que el MSI. Se resuelve con una prueba de coherencia.

---

## 1. Hallazgos previos que cambian el alcance

| # | Hallazgo | Evidencia | Efecto |
|---|---|---|---|
| H-1 | **No hay MSI de la principal, ni de reportes, ni *bundle*.** Solo existen `instalador/AgenteImpresion`, `Comun`, `Demo`, `Publicacion` y `SqlServer`. Ninguna rama remota tiene `instalador/Api` | [V] `git ls-tree` de `instalador/` en `origin/feature/modelo-ng` y en todas las ramas remotas; INS:95-109 en `master` («`GPOS.Api.msi` (**nuevo; no existe hoy**)»); DEMO, fila 7 | R-01 no se puede cerrar con una sola línea. Q-1 |
| H-2 | **Quién iba a construir `GPOS.Api.msi`:** el devops de B, dentro del paquete único y fuera del calendario del tramo 4 | [V] HOJA:533 en `master`; OPS-API, Cierre («devops de B → `GPOS.Api.msi` con `RequiredPrivilege`, `util:EventSource`…») | Si A lo construye, hay que acordarlo con B para no duplicar (Q-1) |
| H-3 | **Contención de S-04 en el agente:** la acción solo se compila dentro de `if ($EstacionDesarrollo)`, y `-EstacionDesarrollo` no admite `-Firmar` | [V] `instalador/AgenteImpresion/construir.ps1:50`, `:96-99`; la prueba de la contención está en `tests/GPOS.Tests/Instalador/FragmentosInstaladorTests.cs:518-528` | Una firma en el agente no se ejecutaría hasta retirar K1-02 (sección 4.2) |
| H-4 | **La prueba estricta con `Skip`** es `Construir_ps1_con_Firmar_compila_la_accion_con_SigntoolFirma_firma_la_CA_dll_y_falla_si_no_esta_firmada` y solo mira el guion del agente (`GuionAgente()`). La prueba fusionada de R-04 ya exige la firma si se quita la contención | [V] `FragmentosInstaladorTests.cs:599-606` (`Skip`), `:566-593` (fusionada), `:537-559` (`FaltasFirmaDeLaAccion`, que busca el `.wixproj` del agente por nombre en `:551`) | Quitar el `Skip` sin más fallaría mientras rija K1-02. Se generaliza (sección 6) |
| H-5 | **No hay certificado de firma.** El nombre legal está pendiente y «el certificado no se solicita hasta tenerlo». La custodia (titular y suplente) está designada, pero sin dispositivos | [V] `docs/adr/ADR-033.md:12-18`, `:29-31`, `:35` en `master` | La firma real queda fuera de la fecha (Q-3, Q-4) |
| H-6 | **El documento de operaciones de la API (L-1 a L-16) no está en el repositorio:** sigue en `traspasos/A/`. ADR-76, punto 2, lo exige por escrito antes de la primera instalación | [V] no hay `docs/operaciones/*api-servicio*` en ninguna rama; OPS-API:197-198 (L-1, L-2) | Se lleva a `docs/operaciones/` con las adiciones de R-01 (PR T1-c) |
| H-7 | **Tarea 1 no depende técnicamente de PR-4.** Solo lee `ModoServicioApi.ArgumentoServicio`, que ya está unido. Empezar después de PR-4 es una decisión de capacidad | [V] `src/GPOS.Api/Servicio/ModoServicioApi.cs:41`; ningún archivo de `instalador/` en #139 ni en #140 (`gh pr view`) | Las partes T1-a y T1-c se pueden adelantar si la PC A tiene un cupo libre |
| H-8 | **Un servicio instalado solo con el MSI no llega a atender.** Le faltan la clave JWT (`Program.cs:67`, HS256 hasta ADR-41, o la llave de T2-0 del #120) y, tras T4-06, la dirección del reenvío (Q-6). La comprobación de arranque (`Program.cs:30`) sí corre antes de ambas | [V] DEMO:46-47; blueprint de T4-06:139-141; revisión de #127, sección 5 | L-1, L-2 y el camino de reserva se prueban con solo el MSI. L-4 en adelante necesitan `implantar-servidor` (PR-V) o el #120 |

---

## 2. Alcance y piezas

| Pieza | Qué | Dueño propuesto | PR |
|---|---|---|---|
| (a) | `GPOS.Api.msi` mínimo con `ServiceInstall/@Arguments="--servicio"`, lista exacta de privilegios, recuperación, orígenes `GPOS.Api` y `GPOS.Instalacion`, raíz, `config\`, carpeta `Api\` y comprobación previa O-1. **Sin red** (la fija `red`/`tls` de ADR-90), **sin secretos**, **sin *bundle*** y sin arrancar el servicio al instalar | A, si B acepta Q-1 | T1-b |
| (b) | Firma de la `.CA.dll` (interna y exterior) en `construir.ps1`, con un módulo de firma compartido, y retiro del `Skip` generalizando la prueba | A | T1-a |
| (c) | Procedimiento de laboratorio: P-O1-7 (con FIPS, `ADDSOURCE` y `ADVERTISE`), L-1/L-2 ampliados (`ImagePath` con `--servicio`, origen `GPOS.Api` y camino de reserva del 4767) y ensayo de la firma con un certificado de laboratorio. Incluye pasar OPS-API a `docs/operaciones/` | A redacta; el técnico ejecuta en la VM de `LFMB` | T1-c |

**Fuera de alcance:**
- retirar K1-02, que es decisión del propietario con la evidencia de P-O1-7;
- el *bundle* de Burn, `GPOS.Reportes.msi` y `GPOS.Web.msi` (B y devops);
- los verbos `implantar-servidor` y `comprobar-servidor` (PR-V del DEMO);
- la red y el TLS de la principal (ADR-90);
- la firma con el certificado real (el custodio);
- `AuthEndpoints.cs:82` y R-05 de #136 (sus dueños).

---

## 3. Contrato del servicio `GPOS.Api` en el MSI (pieza a)

Cada fila es una aserción de la prueba nueva (sección 6). La fuente de verdad son las constantes del código, nunca un literal repetido.

| Atributo | Valor | Fuente de verdad | Origen |
|---|---|---|---|
| `ServiceInstall/@Name` | `GPOS.Api` | `ServiciosWindows.Api` (`src/GPOS.Comun/Servicios/ServiciosWindows.cs:14`) [V] | RSVB-04 |
| `@Account` | `NT SERVICE\GPOS.Api`, sin `Password` | ídem | ADR-76; ADR-82, punto 2 |
| **`@Arguments`** | **exactamente** `--servicio`: un solo elemento, sin `--urls`, `--environment` ni otros | `ModoServicioApi.ArgumentoServicio` (`ModoServicioApi.cs:41`) [V] | **R-01** (#136), S-03 (#127) |
| `@Start` | `auto` (`delayed-auto` si L-15 lo pide) | OPS-API, 7.2 | L-15 |
| `@Type`, `@ErrorControl`, `@Vital` | `ownProcess`, `normal`, `yes` | patrón de la estación (`instalador/AgenteImpresion/Package.wxs:114-117`) [V] | — |
| `ServiceConfig` | `OnInstall="yes" OnReinstall="yes"`; `RequiredPrivilege` = la lista exacta; **sin `ServiceSid`** | `ModoServicioApi.PrivilegiosDeclarados` (`:19`) [V] | ADR-76, puntos 1, 3 y 5 |
| `util:ServiceConfig` | reinicio, reinicio, reinicio, 60 s, reinicio del contador en 1 día; **sin acción de comando** | `Package.wxs:125-126` del agente [V] | DM-14 del DEMO |
| `ServiceControl` | `Stop="both" Remove="uninstall" Wait="yes"`, **sin `Start`** (el servicio queda detenido: lo arranca la cadena o el técnico) | INS 3.1, paso 2 | INS |
| Entorno del servicio | **ninguno** desde el MSI: ni `urls`, ni `Kestrel`, ni `Jwt__Clave`, ni `Reenvio__Direccion` | — | S-01, K3, ADR-90 (la escucha la fija `red`) |
| Origen de eventos | `util:EventSource Log="Application" Name="GPOS.Api"`, `EventMessageFile="[WindowsFolder]Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll"` (ruta protegida) | `ServiciosWindows.Api`; patrón de `Package.wxs:151-155` [V] | S-04 de #127; DM-13 |
| Origen de instalación | `util:EventSource Name="GPOS.Instalacion"`, igual | `ComprobacionCarpetasPrevias.OrigenEventos` (`instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs:168`) [V] | Los eventos 4753-4755 los escribe la acción solo si este origen existe (`AccionesInstalador.cs:146-156`) [V] |
| Binarios | `%ProgramFiles%\GPOS NG\Api\`, publicación Release `win-x64` autocontenida **en carpeta** | INS 2.2 y 8; O-7 firmado («GPOS NG») | — |
| Datos | `%ProgramData%\GPOS NG\Api\` con `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Api>)`. El SID lo calcula la prueba con `IdentidadProceso.SidDeServicio` | ADR-77, puntos 1 y 4; vector v3 | — |
| Raíz y `config\` | `ComponentGroupRef` `GrupoRaizGposNg` y `GrupoConfigGposNg` en la *feature* de la API | `instalador/Comun/Fragmentos/RaizGposNg.wxs:33-39`, `:57-63` [V]; vector v3, `componentesCompartidos` | O-3; D-1 |
| Comprobación previa | `ComprobacionCarpetasPrevias.wxs` con `GposFeatureCarpetas=Api`; fila `GposCarpetaPrevia` de `Api\` (`Servicio=GPOS.Api`, `CrearSiFalta=0`) | `instalador/AgenteImpresion/GPOS.AgenteImpresion.Instalador.wixproj:18` como patrón [V] | O-1; ADR-77, punto 3 |
| *Feature* | `Api`, `Level=1`, `AllowAbsent="no"`, `AllowAdvertise="no"` | R-02 de la relectura de #124 | — |
| Producto | `Scope="perMachine"`, `UpgradeCode` nuevo (`New-Guid`), `MajorUpgrade` con `DowngradeErrorMessage`, versión `!(bind.FileVersion.ApiExe)`, `Manufacturer="GSF"` como el agente (`Package.wxs:44-46`) hasta que exista el nombre legal (Q-4) | ADR-33, línea 18 | — |
| Carpetas que **no** declara | anillo, `Licencia\Entrada`, `temp`, `registros` y nada de otro componente | ADR-77, puntos 4 y 5; P-77-4 | — |

**SDDL del objeto de servicio (DM-09 en producción):** no se fija en este PR. Se deja el valor por omisión del Administrador de servicios, en el que los usuarios interactivos consultan pero no inician ni detienen [I]. Q-5 propone fijarlo de forma explícita para que `comprobar-servidor` lo compare con un valor conocido.

### 3.1 Cómo se comprueba el origen y el camino de reserva (R-01, S-04 de #127, R-02 de #136)

1. **En el MSI:** la prueba exige los dos `util:EventSource` con los nombres de las constantes y `EventMessageFile` bajo `[WindowsFolder]`.
2. **En L-1/L-2, en el laboratorio** (pasan a `docs/operaciones/`, PR T1-c):
   - **L-1 bis:** `sc qc GPOS.Api` → `BINARY_PATH_NAME` = `"C:\Program Files\GPOS NG\Api\GPOS.Api.exe" --servicio`. Se comprueba con la clave `ImagePath`: termina exactamente en ` --servicio` y no tiene otros argumentos.
   - **L-2 bis:** existe `HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application\GPOS.Api` y también la de `GPOS.Instalacion`, y su `EventMessageFile` apunta a un archivo existente bajo `%WINDIR%`.
   - **L-2c (reserva con origen):** desde una consola de administrador, `GPOS.Api.exe --servicio` → rechazo inmediato. Se espera el 4767 «con el argumento y sin el Administrador de servicios», salida 1 y el mismo texto en `Console.Error`.
     - Es la rama de `ModoServicioApi.cs:143-146` [V en la revisión de #136, 5.1]. No hace falta tocar el servicio.
     - El detector B-08 lo prohíbe en `tests/*.cs` (`tests/GPOS.Tests/Arquitectura/ModoServicioArquitecturaTests.cs:206-226`), no en el procedimiento manual.
   - **L-2d (reserva sin origen, solo en la VM):** punto de control, borrar la clave del origen `GPOS.Api` y repetir L-2c. El 4767 debe aparecer igual por `RegistroEventosReserva` (`RegisterEventSource` sin origen registrado; el visor dice «no se encuentra la descripción» pero muestra el texto [I]).
     - Después, `msiexec /fa` (reparación) restaura el origen: se repite L-2 bis.
     - Se vuelve al punto de control.
   - **L-2e (privilegio de más):** `sc privs GPOS.Api SeChangeNotifyPrivilege/SeCreateGlobalPrivilege` y arrancar → 4767 `ARRANQUE_PRIVILEGIOS`.
     - La reparación (`OnReinstall="yes"`) restablece la lista; repetir L-2.
     - Es la parte de L-8 que ya pedía OPS-API:204.
3. **En PR-V (DEMO), como entrega:** `comprobar-servidor`, comprobación P6, agrega «origen `GPOS.Api` registrado y `ImagePath` termina en `--servicio`». Con eso el sitio instalado lo verifica en cada arranque del DEMO, no solo en el laboratorio.

---

## 4. Firma de la `.CA.dll` (pieza b)

### 4.1 Diseño de la tubería

Se crea un módulo compartido, **`instalador/Comun/Firma-Instalador.ps1`**, que cada `construir.ps1` carga con *dot-sourcing*. ADR-77 descarta PowerShell para las **acciones** del MSI (`docs/adr/ADR-077.md:48`), no para los guiones de construcción.

El módulo contiene lo que hoy está en `construir.ps1:55-84` del agente [V]:
- `Resolver-Firma`: ubica `signtool`, normaliza la huella y busca el certificado con clave privada en `CurrentUser\My` o `LocalMachine\My`;
- `Firmar-Archivo`: `sign /fd SHA256 /tr <sello> /td SHA256 /sha1 <huella>`, luego `verify /pa /tw` y `Get-AuthenticodeSignature` con el mismo firmante y sello, y lanza ante cualquier fallo;
- y una función nueva, **`Compilar-AccionFirmada`**.

Orden con `-Firmar` (cumple S-04, puntos 1 a 4, de la revisión de #124):
1. Borrar `instalador\Comun\GPOS.Instalador.Acciones\bin\<Config>\net472\` y `obj\`, para que el `.wixproj` no tome una `.CA.dll` vieja.
2. `dotnet build GPOS.Instalador.Acciones.csproj -c <Config> -p:SigntoolFirma=<ruta> -p:HuellaFirma=<huella> -p:ServidorSelloFirma=<url> [-p:AlmacenEquipoFirma=true]`.
   - La firma interna la hace el *target* ya existente `FirmarEnsambladoInterno`, antes de `PackCustomAction` (`instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj:51-62`) [V], con su `verify /pa /tw`.
3. `Firmar-Archivo <bin>\GPOS.Instalador.Acciones.CA.dll` (la DLL exterior de SfxCA), **antes** de compilar el `.wixproj`.
4. Guardar el SHA-256 de la `.CA.dll` firmada y pasar su carpeta al `.wixproj` de forma explícita (`-p:GposAcciones=<carpeta>`). Nunca se deja que la tome por omisión (`GPOS.AgenteImpresion.Instalador.wixproj:14`).
5. Después de `wix build`, **extraer la tabla `Binary` del `.msi`** y comparar el SHA-256 de `GposAcciones` con el del paso 4. Si difieren, se borra el `.msi` y se lanza. Cierra «el `.wixproj` la toma de `bin` sin verificar la firma» (S-04 de #124).
   - [I] Con `wix msi decompile -x <carpeta>` de WiX 5; si no extrae binarios, con `WindowsInstaller.Installer` por COM de solo lectura (`SELECT Data FROM Binary`). Se decide al construir.
6. Firmar el `.exe` propio antes de empaquetar (como hoy) y **todas las `GPOS*.dll` propias** de la publicación de la API. Las de terceros no se refirman (Q-7).
7. Firmar el `.msi` y verificarlo (como hoy, `construir.ps1:106-111`).
8. Imprimir el registro de firma (ADR-33): fecha, versión, SHA-256 del `.msi` y de la `.CA.dll`, huella del certificado. **Nunca el PIN** (lo pide el token y el guion no lo recibe).

Sin `-Firmar`, la acción se compila igual (MSI de laboratorio, sin firma), pero el `.msi` resultante se nombra `GPOS.Api-SINFIRMA.msi`, para que no pueda confundirse con uno distribuible (mismo criterio que `-DESARROLLO` del agente, `construir.ps1:51`).

**Guarda G-PR4 (S-01 y S-02):** `instalador/Api/construir.ps1 -Firmar` falla si `src/GPOS.Api/Servicio/ModoServicioApi.cs` todavía contiene `FijarEscuchaPorOmision`, es decir, si PR-4 no está unido. Así no puede existir un `GPOS.Api.msi` firmado (distribuible) con la escucha transitoria. Sin firma (laboratorio) se permite. Cuesta una línea y una prueba; se retira sola cuando PR-4 se une. *Alternativa descartada:* una condición de lanzamiento en el MSI, porque no distingue un equipo de laboratorio de uno de cliente.

### 4.2 El agente (K1-02)

- `instalador/AgenteImpresion/construir.ps1` carga el mismo módulo. La compilación de la acción **sigue dentro de `if ($EstacionDesarrollo)`**, ahora con `@propiedadesFirmaAccion` (vacío sin `-Firmar`) y la línea `if ($Firmar) { Firmar-Archivo …CA.dll }` antes del `.wixproj`.
- La línea `if ($EstacionDesarrollo -and $Firmar) { throw …` (`:50`) **no se toca**: retirarla es retirar K1-02, que es decisión del propietario con P-O1-7 en verde.
- Hasta entonces la firma del agente queda **latente pero completa**. El día en que se retire K1-02 solo se borra el `throw` y la `Launch Condition` (`Package.wxs:172-175`), y la prueba fusionada (`:566-593`) confirma que la firma estaba.
- *Alternativa descartada:* un interruptor `-Estacion` firmable ya en este PR. Retiraría K1-02 de hecho, sin la firma del propietario.

### 4.3 De dónde sale el certificado (sin secretos en el repositorio)

| Opción | Cómo se conecta al guion | Costo | Estado |
|---|---|---|---|
| **(A) Certificado OV con la clave en un token FIPS 140-3** (ADR-33, línea 12 y precisión (a), línea 29) | Ya soportado: `-HuellaCertificado <SHA-1>`. El certificado aparece en `CurrentUser\My` con el *middleware* del token y el PIN lo pide el token | USD 120 a 620 al año más el token [V ADR-33]. [I] Hay que confirmar con la CA si acepta la YubiKey 5 FIPS para firma de código (las reglas del CA/B Forum exigen un dispositivo certificado y a veces piden su atestación) | Sin solicitar: falta el nombre legal |
| **(B) Firma en la nube de Microsoft (Artifact Signing, antes Trusted Signing)** (preferida si GSF es elegible, ADR-33, línea 30) | **No implementada** (`construir.ps1:18-19`) [V]. Exige `signtool sign /dlib <Azure.CodeSigning.Dlib.dll> /dmdf <metadata.json>`, con el punto de conexión, la cuenta y el perfil (datos no secretos) en un archivo **fuera del repositorio**, y autenticación de Entra ID con segundo factor en el momento de firmar (sin secreto de cliente). Agregarla es +0,5 dp | Cerca de USD 10 al mes [V ADR-33] | La elegibilidad de GSF no está confirmada |
| (C) Certificado autofirmado de laboratorio | Solo dentro de la VM: se crea con `New-SelfSignedCertificate -Type CodeSigningCert` en `CurrentUser\My` de la VM y su raíz va a `Root` **de la VM**. Se descarta con el punto de control | USD 0 | Es para ensayar la tubería (T1-c), **nunca** para distribuir |

**Reglas que el PR mantiene:**
- ningún `.pfx`, contraseña, PIN ni secreto de Entra en el repositorio, en los parámetros o en la salida (ADR-33, línea 13);
- se firma en un equipo distinto del que publica el manifiesto (precisión (c), línea 31);
- el sello de tiempo es RFC 3161 y es obligatorio (`/tw` rechaza firmar sin él).

**Decide el propietario:**
- Q-3, el proveedor: (A) o (B);
- Q-4, el nombre legal (`Manufacturer`) y la solicitud del certificado;
- quién firma y en qué equipo: el titular o, con dispositivo propio, el suplente.

---

## 5. Archivos a tocar

| Archivo | Líneas | Cambio | PR | Marca |
|---|---|---|---|---|
| `instalador/Comun/Firma-Instalador.ps1` (nuevo) | — | `Resolver-Firma`, `Firmar-Archivo`, `Compilar-AccionFirmada`, `Comprobar-BinarioEnMsi` (4.1) | T1-a | [I] |
| `instalador/AgenteImpresion/construir.ps1` | `:53-84` (pasan al módulo), `:96-99` (compilación con propiedades de firma y `Firmar-Archivo` de la `.CA.dll`), `:101` (`-p:GposAcciones` explícito); **`:50` sin cambios** | Carga el módulo y deja la firma latente (4.2) | T1-a | [V] líneas actuales |
| `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj` | `:56-62` | Sin cambio funcional. Opcional: `Condition` que exija `HuellaFirma` y `ServidorSelloFirma` si viene `SigntoolFirma` (falla temprano) | T1-a | [V] |
| `tests/GPOS.Tests/Instalador/FragmentosInstaladorTests.cs` | `:508-509`, `:511` (`GuionAgente`: leer el guion **más** el módulo cargado), `:537-559` (`FaltasFirmaDeLaAccion`: `.wixproj` genérico en `:551`, `Firmar-Archivo` buscado en el módulo), `:599-606` (**se quita el `Skip`** y pasa a `Theory` sobre cada `instalador/*/construir.ps1` que compile la acción) | Sección 6 | T1-a | [V] |
| `instalador/Api/Package.wxs` (nuevo) | — | Contrato de la sección 3 | T1-b | [I] |
| `instalador/Api/GPOS.Api.Instalador.wixproj` (nuevo) | — | `WixToolset.Sdk/5.0.2`, `Util.wixext 5.0.2`; `DefineConstants` con `Publicacion`, `GposAcciones` y `GposFeatureCarpetas=Api`; `Compile Include` de los dos fragmentos comunes | T1-b | [I]; está dentro de la excepción F-1 («tres `.wixproj`», plano O-1/O-3, 1.2; firmada, aviso `B-a-A/2026-10-20-f1-firmada-opcion-b.md`) |
| `instalador/Api/construir.ps1` (nuevo) | — | `dotnet publish src/GPOS.Api` (Release, `win-x64`, autocontenida, en carpeta, `DebugType=none`) → `instalador/Publicacion/Comprobar-PublicacionRelease.ps1` → firma de lo propio → `Compilar-AccionFirmada` → `wix build` → comprobación de la tabla `Binary` → firma del `.msi`; guarda G-PR4 | T1-b | [I] |
| `tests/GPOS.Tests/Instalador/ApiInstaladorTests.cs` (nuevo) | — | Sección 6 (archivo nuevo, para no chocar con los de PR-4) | T1-b | [I] |
| `docs/contratos/vectores/adr077-carpetas.v3.json` | — | **Sin cambio** salvo que la carpeta `Api\` exija una fila nueva [I]: si la hiciera falta, sería una v4 aditiva y una pregunta para B | — | [I] |
| `docs/operaciones/2026-10-21-gpos-api-servicio.md` (nuevo, a partir de OPS-API) | OPS-API:197-214 | L-1 bis, L-2 bis y L-2c a L-2e (3.1); corrección de S-05 en la sección 9 y de S-02 en la sección 8 (pedidas en la revisión de #127, sección 6, punto 5) | T1-c | [V] OPS-API |
| `docs/operaciones/2026-10-20-raiz-gpos-ng-instalador.md` | `:3`, `:44-50` | Enlace al procedimiento P-O1-7; mención de `GPOS.Api.msi` como segundo consumidor | T1-c | [V] |
| `tests/laboratorio-adr090/invitado/Probar-Instalador.ps1` (o la ruta que diga C) | — | Guion de casos de P-O1-7 y L-1/L-2 **para dentro de la VM** (nunca en la PC del propietario) que produce la evidencia en el formato de `Recoger-Evidencia.ps1` (#146) | T1-c | [I]; Q-6 |
| `instalador/AgenteImpresion/Package.wxs` | `:33-36` | Comentario de K1-02 al día («firma de la `.CA.dll` implementada; falta P-O1-7 y la orden del propietario»); **sin cambio funcional** | T1-a | [V] |

**No se tocan:**
- `src/GPOS.Api/Servicio/ModoServicioApi.cs` ni `Program.cs` (los toca PR-4);
- `src/GPOS.Comun/Servicios/ServiciosWindows.cs`;
- los fragmentos comunes (`RaizGposNg.wxs`, `ComprobacionCarpetasPrevias.wxs`): se consumen tal cual.

---

## 6. Pruebas

### 6.1 Automáticas (suite oficial con el filtro `Transicion!=Ola5&Transicion!=Defecto`; textuales, sin instalar nada)

| ID | Prueba | Archivo | Tipo |
|---|---|---|---|
| T1-01 | **Se quita el `Skip`**: `Construir_ps1_con_Firmar_…` pasa a `Theory` sobre todo `instalador/*/construir.ps1` que compila la acción. Exige `FaltasFirmaDeLaAccion == 0`. Hoy son el del agente (firma latente pero completa) y el de la API | `FragmentosInstaladorTests.cs:599-606` | Reactivada |
| T1-02 | Prueba fusionada R-04 (`:566-593`) **sin cambio de lógica**. El detector lee el guion junto con el módulo cargado: una mención en un comentario sigue sin contar como firma | ídem | Ajuste |
| T1-03 | En el módulo, `Firmar-Archivo` hace `verify /pa /tw` y `Get-AuthenticodeSignature` y comprueba la huella y el sello; no hay `.pfx`, `-Password`, `/p ` ni `/f ` (firma por archivo) | nuevo, en `FragmentosInstaladorTests` | Nueva |
| T1-04 | En cada `construir.ps1`, la `.CA.dll` se firma después de compilar la acción y antes del `.wixproj`. `-p:GposAcciones` es explícito y hay comprobación de la tabla `Binary` después de `wix build` | ídem | Nueva |
| T1-05 | `ServiceInstall` de la API: `Name`, `Account`, **`Arguments == ModoServicioApi.ArgumentoServicio` con un solo elemento**, `Start`, sin `Password`, `RequiredPrivilege == PrivilegiosDeclarados`, sin `ServiceSid`, `util:ServiceConfig` sin comando, `ServiceControl` sin `Start` | `ApiInstaladorTests.cs` | Nueva (patrón de `EstacionInstaladorTests.cs:73-100`) |
| T1-06 | Orígenes `GPOS.Api` y `GPOS.Instalacion` declarados con los nombres de las constantes y `EventMessageFile` bajo `[WindowsFolder]` | ídem | Nueva |
| T1-07 | Ningún `RegistryValue` bajo `Services\GPOS.Api` (sin `Environment`), y ninguna aparición de `urls`, `Kestrel`, `Jwt`, `Password`, `Secret` ni `Reenvio` en el `.wxs` | ídem | Nueva |
| T1-08 | SDDL de `Api\` con el SID calculado por `IdentidadProceso.SidDeServicio(ServiciosWindows.Api)`; `GrupoRaizGposNg` y `GrupoConfigGposNg` en la *feature* `Api`; fila `GposCarpetaPrevia` de `Api\`; `GposFeatureCarpetas` nombra la *feature* que trae las carpetas (la prueba genérica R-01 de #124 ya lo cubre si recorre los `.wixproj`) | ídem | Nueva |
| T1-09 | Guarda G-PR4: el guion de la API con `-Firmar` lanza si `ModoServicioApi.cs` contiene `FijarEscuchaPorOmision`; hay un caso sintético en cada sentido | ídem | Nueva |
| T1-10 | **Coherencia con PR-V:** si `src/GPOS.Migracion` crea el servicio `GPOS.Api` (`sc create` o API de SCM), el argumento, los privilegios y las acciones de recuperación coinciden con las constantes y con el `.wxs`. Pasa en vacío hasta PR-V, y por eso **PR-V la hace estricta** al unirse | ídem | Nueva |
| T1-11 | `[Parser]::ParseFile` sin errores en `construir.ps1` de la API y en `Firma-Instalador.ps1` (B-13 del INS) | ídem | Nueva |
| — | Se mantienen: S-03 de código fuente sin hashes administrados (`FragmentosInstaladorTests.cs:613-626`) y el detector B-08 (ningún `.cs` de `tests/` instala servicios) | — | Sin cambio |

**Compilación prevista en la PC A:** `dotnet build` de `GPOS.Tests` y la suite filtrada `Instalador|Arquitectura`, **un agente compilando**. Un `wix build` del MSI de la API (publica la API: unos 2 a 4 min y de 1 a 1,5 GB de RAM [I]) **solo una vez**, para comprobar que compila. **No se ejecuta el MSI.** La suite oficial completa la corre C o B (`LFMB`), como en los PR anteriores.

### 6.2 Laboratorio (manual, en la VM de `LFMB`, ejecuta el técnico; A prepara)

| Caso | Qué | Esperado |
|---|---|---|
| P-O1-7.1 a .5 | Con `GPOS.Api-SINFIRMA.msi`, y con el MSI de desarrollo del agente para los casos de la *feature* `EstacionImpresion`: raíz plantada por un usuario, unión plantada, dueño ajeno, escritor ajeno | 1603 con 25101, **sin cambios** en el disco; con `/l*v` |
| P-O1-7.6 | Raíz ausente | Se crea con el SDDL exacto de `raiz.sddl`; 4755 con la huella si el origen existe (en la primera instalación no existe todavía, y el registro del MSI lo dice) |
| **P-O1-7.7 (FIPS)** | Punto de control → directiva «Criptografía de sistema: usar algoritmos compatibles con FIPS» activa (`HKLM\SYSTEM\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy\Enabled=1`), reinicio → se repiten .1 y .6. Además arranca el servicio `GPOS.Api` (el cálculo SHA-1 del SID en `IdentidadProceso`) hasta el punto de la comprobación de arranque | Primera instalación **sin** `InvalidOperationException` en el registro del MSI (`SHA256CryptoServiceProvider`, `ComprobacionCarpetasPrevias.cs:233-256`) [V código; I conducta]. La identidad se acepta (sin 4767 de identidad). [I] .NET 10 no aplica la directiva al SHA-1 de CNG para *hash* |
| P-O1-7.8 | `ADDSOURCE=EstacionImpresion` y `ADVERTISE=EstacionImpresion` (agente, desarrollo) | La comprobación corre con `&F = 4`; `ADVERTISE` se rechaza por `AllowAdvertise="no"` (R-02 de #124; `docs/operaciones/2026-10-20-raiz-gpos-ng-instalador.md:44-45`) |
| P-O1-7.9 | Reparación y cambio de *feature* con la estación instalada | La comprobación corre (`raiz-gpos-ng-instalador.md:50`) |
| L-1, L-1 bis, L-2, L-2 bis y L-2c a L-2e | Sección 3.1 | `--servicio` en `ImagePath`; `sc qprivs` exactamente `SeChangeNotifyPrivilege`; 4767 por los dos caminos |
| F-1 (firma de laboratorio) | En la VM, con el certificado (C) y la raíz de la VM: `construir.ps1 -Firmar` de la API y del agente (este último sigue rechazando `-EstacionDesarrollo -Firmar`) | `signtool verify /pa /tw` correcto en el `.exe`, las `GPOS*.dll`, la `.CA.dll` interna y exterior y el `.msi`; la tabla `Binary` coincide; firmar con una huella inexistente falla y no deja `.msi` |
| F-2 (opcional) | WDAC en modo auditoría, con una regla por editor del certificado de laboratorio | Sin eventos de bloqueo de la `.CA.dll` (CodeIntegrity 3076/3077) [I] |

La evidencia sigue el formato del #146 (`Recoger-Evidencia.ps1`): sin valores del entorno de los servicios y sin `reg export` de la clave del servicio (DM-05). **Criterio para que el propietario pueda retirar K1-02:** P-O1-7.1 a .9 en verde y la firma real de la `.CA.dll` (la F-1 con el certificado de laboratorio no basta).

---

## 7. Choques

| Con | Choque | Resolución |
|---|---|---|
| **PR-4 (#139)** | Sin choque de archivos: toca `ModoServicioApi.cs`, `Program.cs` y cuatro pruebas de `Arquitectura/` [V `gh pr view 139`]. **Funcional:** hasta su unión siguen abiertos S-01 y S-02 | Guarda G-PR4 (4.1). Las pruebas nuevas van en archivos nuevos. La guarda lee el texto de `ModoServicioApi.cs` y funciona en cualquier orden de unión |
| **PR-2 (#140)** | Sin choque de archivos [V]. El certificado TLS del servicio lo pone el verbo `tls`, no el MSI | Ninguno. L-16 (cadena completa) espera a PR-2/PR-4 |
| **T4-06** | Q-6: la principal Release sin `GPOS:Reportes:Reenvio:Direccion` no arranca (blueprint de T4-06:130 y :141) | El MSI no escribe la dirección; la escribe `implantar-servidor` (PR-V), igual que en el DEMO (DEMO:77). L-1/L-2 no se ven afectados (la comprobación de arranque va antes, `Program.cs:30`). L-4 en adelante exigen PR-V |
| **DEMO y PR-V** | PR-V crea `GPOS.Api` con `sc create` en `%ProgramFiles%\GPOS NG\Demo\api\` (DEMO:61, :144), con el mismo nombre de servicio que el MSI | (1) T1-10 obliga a la coherencia de argumento, privilegios y recuperación. (2) **DEMO y MSI son excluyentes en un mismo equipo:** si existe un `GPOS.Api` que no es del MSI, `ServiceInstall` falla [I]. Se documenta en las operaciones y `comprobar-servidor` lo informa (entrega a PR-V). (3) DM-09: en el DEMO, el SDDL del servicio da inicio y parada al usuario que instala; en producción no (Q-5) |
| **DM-09 (SDDL de servicios)** | Si el MSI fija un SDDL, debe ser el de producción y no el del DEMO | Q-5. Si se aprueba, la constante vive en una sola prueba y PR-V la comparte |
| **#120 (T2-0, llave de firma)** | Sin la llave o la clave JWT, el servicio del MSI no atiende | Dependencia de L-4 en adelante, no de este PR |
| **Laboratorio de ADR-90 (C, #146)** | La VM `VM-SRV` es la misma, por bloques y no en paralelo (`LFMB`, 13,9 GB) | P-O1-7 y L-1/L-2 se piden como **bloque propio** de la ventana de la VM (Q-6) |
| **Capacidad de A** | Del 11-03 al 11-13 coinciden T4-06, PR-D1, el PR pequeño de la API, el *spike* del DEMO y el arranque de PR-V | Orden de la sección 9. T1-a y T1-c no compilan casi nada y se pueden adelantar a los huecos de la semana del 10-26 (H-7) |

---

## 8. Riesgos

| ID | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| RT1-1 | B prefiere construir `GPOS.Api.msi` dentro del *bundle* y el MSI mínimo de A se duplica | Media / Medio | Q-1 antes de empezar T1-b. Plan B: solo T1-a, T1-c y un contrato de prueba (T1-05 a T1-08 sobre el `.wxs` de B), con 1,75 dp |
| RT1-2 | WiX 5 no recoge una carpeta de publicación (cientos de archivos) sin `heat` [I] | Media / Medio | Probar primero con la versión que fija el repositorio (`WixToolset.Sdk 5.0.2`). Alternativa: `HarvestDirectory` de `WixToolset.Heat` 5.0.2 (obsoleto pero disponible) [I]. Descartado: publicar en un solo archivo, por la compilación de Razor en tiempo de ejecución y las bibliotecas nativas de PuppeteerSharp y QuestPDF [I] |
| RT1-3 | La extracción de la tabla `Binary` no funciona con WiX 5 | Baja / Bajo | Plan COM de solo lectura (4.1, paso 5) |
| RT1-4 | No hay certificado antes de diciembre: la firma real y la retirada de K1-02 se atrasan | Alta / Medio | La tubería se ensaya con (C) en la VM; Q-3 y Q-4 al propietario ya |
| RT1-5 | No hay ventana de la VM antes del 11-13 | Alta / Bajo para el PR, Medio para K1-02 | El PR no depende de la evidencia; P-O1-7 se entrega aparte |
| RT1-6 | La YubiKey 5 FIPS no sirve para la CA elegida | Media / Medio | Preguntar a la CA antes de comprar; la opción (B) no necesita token propio |
| RT1-7 | La firma de la `.CA.dll` exterior invalida el contenido de SfxCA o cambia su carga [I] | Baja / Alto | Es la práctica habitual de WiX (Authenticode sobre el PE exterior). F-1 en la VM: instalar el MSI firmado y comprobar 25101 y 4755 |
| RT1-8 | `--servicio` duplicado o con comillas mal puestas en `ImagePath` | Baja / Medio | T1-05 exige un solo elemento; L-1 bis compara `ImagePath` |
| RT1-9 | En un mismo equipo se instalan el DEMO y el MSI (mismo nombre de servicio) | Baja / Medio | Exclusión documentada; `comprobar-servidor` lo informa |

---

## 9. Esfuerzo, orden y fechas

| # | Tarea pequeña | dp [I, ±40 %] | Compila en la PC A | Ventana propuesta |
|---|---|---|---|---|
| 1 | T1-a.1: `Firma-Instalador.ps1` extraído del agente, sin cambio de conducta | 0,25 | No | 10-27 a 10-29, en huecos de PR-4 |
| 2 | T1-a.2: `Compilar-AccionFirmada`, `-p:GposAcciones`, comprobación de la tabla `Binary`; firma latente en el agente | 0,5 | No | ídem |
| 3 | T1-a.3: pruebas T1-01 a T1-04 y T1-11; **quitar el `Skip`** | 0,25 | Sí (`GPOS.Tests`, filtrada) | 10-30 o 11-02 |
| 4 | T1-c.1: OPS-API a `docs/operaciones/` con L-1 bis, L-2 bis y L-2c a L-2e, y las correcciones de S-02 y S-05 | 0,25 | No | 10-28 |
| 5 | T1-c.2: procedimiento y guion de la VM para P-O1-7 (FIPS, `ADDSOURCE`, `ADVERTISE`) y F-1 | 0,5 | No | 11-02 a 11-04 |
| 6 | T1-b.1: `instalador/Api/Package.wxs` y `.wixproj` | 0,75 | No | 11-04 a 11-06 (si Q-1 = sí) |
| 7 | T1-b.2: `instalador/Api/construir.ps1` con la guarda G-PR4 | 0,5 | Una vez (`wix build`) | 11-09 |
| 8 | T1-b.3: pruebas T1-05 a T1-10 | 0,5 | Sí (filtrada) | 11-10 a 11-11 |
| 9 | Revisión de seguridad propia del diff (auditor de A) y correcciones | 0,25 a 0,5 | — | 11-12 |
| **Total** | | **3,75 a 4,0 dp** (sin el MSI, pasos 1 a 5 y 9: **1,75 a 2,0 dp**) | | **PR abiertos el 2026-11-13** |

**PR propuestos:**
- **T1-a**, firma: pasos 1 a 3, unos 70 % de líneas en `instalador/` y `tests/`;
- **T1-b**, MSI de la API: pasos 6 a 8, apilado sobre T1-a;
- **T1-c**, documentos y guion de laboratorio: pasos 4 y 5, sin compilar.

Cada uno cita ADR-33, ADR-76 (punto 4) y ADR-77 (punto 3). **Nada se une sin la orden del propietario.**

**Costo:** USD 0 en licencias (WiX y `signtool` son gratuitos). El certificado es el de ADR-33: de USD 120 a 620 al año (opción A), o cerca de USD 120 al año (opción B, unos USD 10 al mes); lo decide el propietario. El laboratorio usa la VM existente.

**Opción más barata que cumple R-01 en la letra:** solo T1-a y T1-c, más el contrato T1-05 a T1-08 para el `.wxs` que haga B: 1,75 a 2,0 dp. La desventaja es que R-01 sigue abierto en la práctica hasta que B construya el MSI, y L-1/L-2 no se pueden ejecutar.

---

## 10. Preguntas abiertas

| # | Pregunta | Para | Recomendación |
|---|---|---|---|
| **Q-1** | `GPOS.Api.msi` no existe. ¿Lo construye A como MSI mínimo en `instalador/Api/` (primera pieza de B-1, sin *bundle* ni red), o lo construye el devops de B y A entrega solo la firma, el contrato y el laboratorio? | **B** | **A construye el MSI mínimo** (T1-b): R-01 queda cerrado de verdad, la firma de la `.CA.dll` se usa desde el primer día y L-1/L-2 se pueden ejecutar. B lo integra después en la cadena del *bundle* |
| Q-2 | ¿Se acepta la guarda G-PR4 (no hay `GPOS.Api.msi` firmado mientras exista `FijarEscuchaPorOmision`)? | B | Sí: aplica S-01(a) sin costo |
| **Q-3** | Proveedor de firma: (A) OV con token FIPS 140-3 o (B) Artifact Signing (si GSF es elegible). Con (B), A añade `/dlib` al módulo (+0,5 dp) | **Propietario** | Pedir hoy la verificación de elegibilidad de (B), que ADR-33 prefiere por costo, y decidir antes del 11-30 |
| **Q-4** | Nombre legal (`Manufacturer`) y solicitud del certificado (ADR-33, línea 18). Mientras tanto, ¿`Manufacturer="GSF"` como el agente? | **Propietario** | Sí a «GSF» de forma provisional; el nombre legal, antes de solicitar el certificado |
| Q-5 | ¿El MSI fija un SDDL explícito del objeto de servicio en producción (solo Administradores y SYSTEM inician, detienen o reconfiguran; los usuarios, solo consultar), distinto del de DM-09 para el DEMO? | B y auditor (A) | Sí, en T1-b (+0,25 dp), con la constante compartida con PR-V |
| Q-6 | Ventana de la VM de `LFMB` para el bloque «instalador» (P-O1-7, L-1/L-2 y F-1; 1 sesión de unas 3 h [I]) y quién la opera. ¿El guion de la VM va en `tests/laboratorio-adr090/invitado/` (C) o en una carpeta propia? | B, C y propietario | La primera ventana después del 11-13. El guion en la carpeta de C para reutilizar `Recoger-Evidencia` |
| Q-7 | ¿Se firman solo los binarios propios (`GPOS*.exe`/`GPOS*.dll`) o también las DLL de terceros sin firma de la publicación (por WDAC)? | Propietario (vía B) | Solo los propios. Las de terceros se cubren con una regla por *hash* si un cliente usa WDAC |
| Q-8 | `Start="auto"` o `delayed-auto` | B (devops) | `auto` hasta medir L-15 |

---

### Cierre
- **Estado:** Completado. Es un blueprint previo; la construcción espera Q-1.
- **Artefactos:** `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-tarea1-instalador-servicio-2026-10-22.md`
- **Supuestos:**
  - Sobre WiX 5.0.2: recolección de carpetas, extracción de la tabla `Binary`, comillas de `ImagePath`, fallo de `ServiceInstall` si el servicio ya existe, y que la firma exterior de SfxCA no altera la carga.
  - Sobre Windows y .NET: DACL por omisión del objeto de servicio; conducta de `RegisterEventSource` sin origen; .NET 10 no aplica la directiva FIPS al SHA-1 de CNG para *hash*.
  - Sobre los proveedores de firma: costo y requisitos de Artifact Signing; aceptación de la YubiKey 5 FIPS por la CA.
  - Esfuerzos con ±40 %. Todo lo [I] se confirma al construir o en la VM. No se compiló ni se ejecutó nada.
- **Decisiones candidatas a ADR:**
  - (1) Precisión de ADR-33: módulo de firma compartido, comprobación de la tabla `Binary` y nombre `-SINFIRMA` para los MSI sin firmar.
  - (2) Nota de aplicación de ADR-76, punto 4: el argumento `--servicio` en todo servicio del núcleo creado por MSI o por un verbo, con una prueba de coherencia.
  - (3) Guarda G-PR4 como condición de publicación de `GPOS.Api.msi`.
  - Las redacta el arquitecto-maestro si B las adopta. Ninguna cambia lo firmado.
- **Entregas a otros agentes:**
  - B → Q-1, Q-2, Q-5, Q-6 y Q-8.
  - Propietario (vía B) → Q-3, Q-4 y Q-7.
  - C → ubicación del guion de la VM y bloque en el diseño de VirtualBox.
  - A (PR-V) → P6 con el origen y `--servicio`, T1-10 estricta y exclusión DEMO/MSI.
  - Auditor-seguridad de A → revisión del diff de T1-a y T1-b.
  - Desarrollador de B → nada nuevo.
- **Próximo paso recomendado:** que B responda Q-1 antes del 10-28. Con eso, A empieza T1-a y T1-c en los huecos de PR-4 y T1-b el 11-04.
