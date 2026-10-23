# Guía para construir T1-b: `GPOS.Api.msi` mínimo (`instalador/Api/`)

**Equipo A, 2026-10-22.** Para el devops de B (Q-1: lo construye B). Es la parte práctica del blueprint `blueprint-tarea1-instalador-servicio-2026-10-22.md` (secciones 3, 4.1, 6.1 y 9) y del contrato `contrato-servicio-msi-api-2026-10-22.md`. **Nada de esto se compiló ni se ejecutó**: los fragmentos están copiados de `instalador/AgenteImpresion/Package.wxs` y de los fragmentos comunes en `feature/modelo-ng` @ `cb94f19b`; lo marcado [I] se confirma al construir.

**Qué ya existe para apoyarse:**
- `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs` y `RaizGposNg.wxs` (O-1 y O-3; #124, unido). Se incluyen tal cual.
- `instalador/Comun/GPOS.Instalador.Acciones` (acción previa, `net472`, excepción F-1).
- `instalador/Comun/Firma-Instalador.ps1` (T1-a, **#164, aún sin unir**): `Resolver-Firma`, `Firmar-Archivo`, `Propiedades-FirmaAccion`, `Comprobar-BinarioEnMsi`. T1-b se apila sobre #164 (o espera su unión).
- `docs/operaciones/2026-10-21-operaciones-gpos-api-servicio.md` y el procedimiento de laboratorio (#165, T1-c): lo que el MSI debe cumplir en la VM.

## 1. Archivos

```
instalador/Api/
  GPOS.Api.Instalador.wixproj
  Package.wxs
  construir.ps1
tests/GPOS.Tests/Instalador/ApiInstaladorTests.cs      (archivo nuevo, no toca los de PR-4)
```
No se tocan: `ModoServicioApi.cs`, `Program.cs`, `ServiciosWindows.cs` ni los dos fragmentos comunes.

## 2. `GPOS.Api.Instalador.wixproj`

Copiar el del agente y cambiar:
- `OutputName` = `GPOS.Api` (o `GPOS.Api-SINFIRMA` cuando no hay `-Firmar`: lo pasa `construir.ps1` con `-p:OutputName=`).
- `DefineConstants`: `Publicacion=$(Publicacion);GposAcciones=$(GposAcciones);GposFeatureCarpetas=Api`. **Literal**, no una propiedad (R-01 de #124): nombra la *feature* `Api`, que debe existir en este MSI y traer la raíz, `config\` y la carpeta con fila.
- `PackageReference WixToolset.Util.wixext 5.0.2` (la del agente).
- `Compile Include` de `..\Comun\Fragmentos\ComprobacionCarpetasPrevias.wxs` y `..\Comun\Fragmentos\RaizGposNg.wxs`.
- No lleva `EstacionDesarrollo`.

## 3. `Package.wxs`: esqueleto

```xml
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs" xmlns:util="http://wixtoolset.org/schemas/v4/wxs/util">
  <Package Name="GPOS NG API" Manufacturer="GSF" Version="!(bind.FileVersion.ApiExe)"
           UpgradeCode="{New-Guid}" Scope="perMachine" Language="3082" Codepage="1252">
    <MajorUpgrade DowngradeErrorMessage="Ya está instalada una versión más reciente de la API de GPOS NG." />
    <MediaTemplate EmbedCab="yes" />

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="DirGposNgPrograma" Name="GPOS NG">
        <Directory Id="INSTALLFOLDER" Name="Api" />
      </Directory>
    </StandardDirectory>
    <!-- DirGposNgDatos la define RaizGposNg.wxs. Id privado (con minúsculas): un Id todo en mayúsculas sería una propiedad pública (S-05) -->
    <DirectoryRef Id="DirGposNgDatos">
      <Directory Id="DirApiDatos" Name="Api" />
    </DirectoryRef>

    <Feature Id="Api" Title="API de GPOS NG" Level="1" AllowAbsent="no" AllowAdvertise="no">
      <Component Id="ProgramaApi" Directory="INSTALLFOLDER" Guid="{New-Guid}" Bitness="always64">
        <File Id="ApiExe" Name="GPOS.Api.exe" Source="$(var.Publicacion)\GPOS.Api.exe" KeyPath="yes" />
        <ServiceInstall Id="InstalarApi" Name="GPOS.Api" DisplayName="GPOS NG: API"
                        Description="API principal de GPOS NG."
                        Type="ownProcess" Start="auto" ErrorControl="normal" Vital="yes"
                        Account="NT SERVICE\GPOS.Api" Arguments="--servicio">
          <ServiceConfig OnInstall="yes" OnReinstall="yes">
            <RequiredPrivilege Name="SeChangeNotifyPrivilege" />
          </ServiceConfig>
          <util:ServiceConfig FirstFailureActionType="restart" SecondFailureActionType="restart" ThirdFailureActionType="restart"
                              RestartServiceDelayInSeconds="60" ResetPeriodInDays="1" />
        </ServiceInstall>
        <!-- Sin Start: el servicio queda detenido tras instalar (lo arranca la cadena o el técnico) -->
        <ServiceControl Id="ControlarApi" Name="GPOS.Api" Stop="both" Remove="uninstall" Wait="yes" />
      </Component>

      <!-- (aquí van TODOS los archivos de la publicación: ver el punto 4) -->

      <ComponentGroupRef Id="GrupoRaizGposNg" />
      <ComponentGroupRef Id="GrupoConfigGposNg" />

      <Component Id="DatosApi" Directory="DirApiDatos" Guid="{New-Guid}" Bitness="always64">
        <CreateFolder>
          <PermissionEx Sddl="O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;{SID de NT SERVICE\GPOS.Api})" />
        </CreateFolder>
      </Component>

      <Component Id="OrigenEventosApi" Directory="INSTALLFOLDER" Guid="{New-Guid}" Bitness="always64">
        <util:EventSource Log="Application" Name="GPOS.Api" KeyPath="yes"
                          EventMessageFile="[WindowsFolder]Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll" />
      </Component>
      <Component Id="OrigenInstalacion" Directory="INSTALLFOLDER" Guid="{New-Guid}" Bitness="always64">
        <util:EventSource Log="Application" Name="GPOS.Instalacion" KeyPath="yes"
                          EventMessageFile="[WindowsFolder]Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll" />
      </Component>
    </Feature>

    <CustomTableRef Id="GposCarpetaPrevia">
      <Row>
        <Data Column="Id" Value="DatosApi" />
        <Data Column="Directorio" Value="DirApiDatos" />
        <Data Column="Servicio" Value="GPOS.Api" />
        <Data Column="CrearSiFalta" Value="0" />
        <Data Column="Orden" Value="20" />
      </Row>
    </CustomTableRef>
  </Package>
</Wix>
```

**Reglas que el esqueleto cumple y que no se deben perder:**
- Cada GUID de componente sale de `New-Guid` (S-07: nada que siga un patrón). El de la raíz y el de `config\` ya vienen en los fragmentos (`66D68CDE-…`, `0B21B6DB-…`) y **no se cambian**.
- `Arguments="--servicio"` es **un solo elemento**; sin `--urls`, `--environment` ni más.
- **Sin `ServiceSid`**, sin otro privilegio, **sin entorno del servicio** (`urls`, `Kestrel`, `Jwt__Clave`, `Reenvio__Direccion` no se escriben aquí: la escucha y el TLS las fijan los verbos `red` y `tls`; la clave y el reenvío, `implantar-servidor`).
- La fila `GposCarpetaPrevia` de `Api\` lleva `Servicio=GPOS.Api` y **es hoja**: nada de la tabla cuelga de ella. No declarar el anillo, `Licencia\Entrada`, `temp` ni `registros` (los crea el proceso, ADR-77 puntos 4 y 5).
- El SID del SDDL se calcula, no se escribe a mano: `IdentidadProceso.SidDeServicio(ServiciosWindows.Api)`. Si el cálculo de A es correcto, es `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906`; el laboratorio lo confirma con `sc showsid GPOS.Api`.
- `Manufacturer="GSF"` hasta que el propietario dé el nombre legal (Q-4).
- No se arranca el servicio al instalar, y el MSI no escribe el *bundle*, secretos ni red.

## 4. Archivos de la publicación (el riesgo RT1-2)

La API publicada es autocontenida **en carpeta**: cientos de archivos, y descartamos un solo archivo (compilación de Razor en tiempo de ejecución y bibliotecas nativas de PuppeteerSharp y QuestPDF [I]). WiX 5 no recoge una carpeta sola:
1. Probar primero lo que fija el repositorio (`WixToolset.Sdk 5.0.2`) con una lista de `<Files Include="$(var.Publicacion)\**" />` en el `Component`/`Directory` que corresponda [I: confirmar que 5.0.2 expone `Files`].
2. Si no, `HarvestDirectory` de `WixToolset.Heat` 5.0.2 (obsoleto pero disponible) [I].
3. Sea cual sea, **el `GPOS.Api.exe` va en un componente propio con `KeyPath` (`ApiExe`)** para que `!(bind.FileVersion.ApiExe)` dé la versión del producto.

Documentar en el PR cuál funcionó.

## 5. `construir.ps1`

Patrón del agente (`instalador/AgenteImpresion/construir.ps1`), con estos pasos en este orden:
1. Parámetros iguales (`-Configuracion`, `-Version`, `-Firmar`, `-HuellaCertificado`, `-ServidorSello`). Con `-Firmar`: `. (Join-Path $aqui "..\Comun\Firma-Instalador.ps1")` y `Resolver-Firma`. **El `-ServidorSello` por omisión no va en el módulo**: queda en el parámetro de este guion.
2. **Guarda G-PR4:** con `-Firmar`, lanzar si `src\GPOS.Api\Servicio\ModoServicioApi.cs` todavía contiene `FijarEscuchaPorOmision` (PR-4, #139 y #140, sin unir). Sin firma (laboratorio) se permite. Se retira sola cuando PR-4 se une. El nombre del `.msi` sin firma es **`GPOS.Api-SINFIRMA.msi`** (`-p:OutputName=`).
3. `dotnet publish src\GPOS.Api -c Release -r win-x64 --self-contained -p:DebugType=none -o <publicacion>` (**en carpeta**, sin `PublishSingleFile`); luego `instalador\Publicacion\Comprobar-PublicacionRelease.ps1` (que existe en el repositorio).
4. Con `-Firmar`: firmar `GPOS.Api.exe` y **todas las `GPOS*.dll` propias** de la publicación (`Firmar-Archivo`). Las de terceros no se refirman (Q-7, pendiente del propietario).
5. Acción previa: borrar `bin\` y `obj\` de `GPOS.Instalador.Acciones` si hay `-Firmar`, `dotnet build … @propiedadesFirmaAccion`, luego `Firmar-Archivo …\GPOS.Instalador.Acciones.CA.dll` y guardar su SHA-256 en `$huellaCA`. **Esto es exactamente el bloque del agente** (`construir.ps1:71-90`); copiarlo, no reinventarlo, porque `FaltasFirmaDeLaAccion` de las pruebas lo reconoce por su forma.
6. `dotnet build GPOS.Api.Instalador.wixproj … -p:GposAcciones=$acciones` (**explícito**; nunca la carpeta por omisión).
7. Con `-Firmar`: `Comprobar-BinarioEnMsi $msi.FullName "GposAcciones" $huellaCA` y luego `Firmar-Archivo $msi.FullName`; si falla, borrar el `.msi`.
8. Imprimir el registro de firma (ADR-33): fecha, versión, SHA-256 del `.msi` y de la `.CA.dll`, huella. **Nunca el PIN.**

La suite ya tiene una prueba (`Construir_ps1_con_Firmar_…`, en #164) que recorre **todo** `instalador/*/construir.ps1` que compile la acción y exige ese patrón: un `construir.ps1` de la API que no lo siga la hace fallar. Es la red de seguridad contra olvidar la firma de la `.CA.dll`.

## 6. Pruebas (`ApiInstaladorTests.cs`, textuales; no instalan nada)

Patrón: `tests/GPOS.Tests/AgenteImpresion/EstacionInstaladorTests.cs:73-100`. Cada una lee `instalador/Api/Package.wxs` y compara con constantes del código:

| ID | Qué exige |
|---|---|
| T1-05 | `ServiceInstall`: `Name` = `ServiciosWindows.Api`; `Account` = `NT SERVICE\GPOS.Api` sin `Password`; **`Arguments` = `ModoServicioApi.ArgumentoServicio`, un solo elemento**; `Start`; `RequiredPrivilege` = `ModoServicioApi.PrivilegiosDeclarados`; sin `ServiceSid`; `util:ServiceConfig` con tres reinicios y sin comando; `ServiceControl` sin `Start` |
| T1-06 | Los orígenes `GPOS.Api` y `GPOS.Instalacion` (`ServiciosWindows.Api`, `ComprobacionCarpetasPrevias.OrigenEventos`), con `EventMessageFile` bajo `[WindowsFolder]` |
| T1-07 | Ningún `RegistryValue` bajo `Services\GPOS.Api` (sin `Environment`) y ninguna aparición de `urls`, `Kestrel`, `Jwt`, `Password`, `Secret` ni `Reenvio` en el `.wxs` |
| T1-08 | El SDDL de `Api\` con el SID calculado por `IdentidadProceso.SidDeServicio(ServiciosWindows.Api)`; `GrupoRaizGposNg` y `GrupoConfigGposNg` dentro de la *feature* `Api`; la fila `GposCarpetaPrevia` de `Api\` con `Servicio=GPOS.Api`; `GposFeatureCarpetas=Api` (la prueba genérica R-01 de #124 ya recorre los `.wixproj`) |
| T1-09 | G-PR4: el guion con `-Firmar` lanza si `ModoServicioApi.cs` contiene `FijarEscuchaPorOmision`; un caso sintético en cada sentido |
| T1-10 | Coherencia con PR-V (`GPOS.Migracion`): argumento, privilegios y recuperación del `sc create` coinciden con las constantes y con el `.wxs`; pasa en vacío hasta PR-V, que la hace estricta |
| T1-11 | `[Parser]::ParseFile` sin errores en el `construir.ps1` de la API (desde una prueba no se puede: se revisa a mano o con `pwsh` en el PR) |

Las pruebas de T1-05 a T1-08 dependen de que existan `Package.wxs` y `.wixproj` de la API: se entregan en el mismo PR que ellos.

## 7. Lo que no es de T1-b

- La firma real de `GPOS.Api.msi`: la hace el custodio con el certificado de ADR-33; depende de Q-3 y Q-4 del propietario. Mientras, `GPOS.Api-SINFIRMA.msi`.
- El *bundle*, `GPOS.Reportes.msi`, `GPOS.Web.msi` y los verbos `implantar-servidor` / `comprobar-servidor` (PR-V).
- Q-5 (SDDL explícito del objeto de servicio): **firmada el 22-oct**; entra en T1-b (+0,25 dp), con el texto de `contrato-servicio-msi-api-2026-10-22.md` y la prueba `El_SDDL_del_servicio_del_MSI_es_el_de_Q5`.
- Mientras `FijarEscuchaPorOmision` siga en `ModoServicioApi.cs`, el MSI **no se firma** (G-PR4) y el servicio **no debe instalarse fuera del laboratorio** (S-01/S-02 de #127).
- **DEMO y MSI son excluyentes** en un equipo: PR-V crea un servicio `GPOS.Api` con el mismo nombre; si ya existe uno que no es del MSI, `ServiceInstall` falla [I].

## 8. Lista de comprobación antes de abrir el PR

- [ ] `Package.wxs` sin GUID con aspecto manual; los de la raíz y `config\` intactos.
- [ ] `Arguments="--servicio"`, un solo elemento; sin `ServiceSid`; un solo privilegio.
- [ ] Sin entorno, sin red, sin secretos, sin `Start` en `ServiceControl`.
- [ ] `.wixproj` con `GposFeatureCarpetas=Api` literal y la *feature* `Api` trae la raíz, `config\` y la carpeta `Api\` con su fila.
- [ ] `construir.ps1`: guarda G-PR4; bloque de la acción copiado del agente; `-p:GposAcciones=` explícito; `Comprobar-BinarioEnMsi` antes de firmar el `.msi`; nombre `-SINFIRMA` sin firma.
- [ ] Pruebas T1-05 a T1-10 en verde con el filtro `Instalador|Arquitectura`.
- [ ] Un `wix build` del MSI (una sola vez, unos 2 a 4 min y 1 a 1,5 GB de RAM [I]) para comprobar que compila. **No se ejecuta el MSI** en la PC del propietario: lo prueba el técnico en la VM con `Probar-Instalador.ps1` (L-1 bis a L-2e).
- [ ] Revisión de seguridad de A del diff (auditor-seguridad) antes de unir.
