# Contrato del servicio `GPOS.Api` para el MSI (lo que debe y no debe hacer)

**Equipo A, 2026-10-22.** Para el devops de B, que construye `instalador/Api/` (Q-1: decisión del propietario). Extracto breve de la sección 3 del blueprint `blueprint-tarea1-instalador-servicio-2026-10-22.md`, que tiene las citas `ruta:línea`. Todo valor sale de las constantes del código, nunca de un literal repetido. Cada fila debe ser una aserción de prueba (T1-05 a T1-08 del blueprint; A las entrega para que apliquen al `.wxs` de B).

## El MSI debe
| Atributo | Valor | Fuente de verdad |
|---|---|---|
| `ServiceInstall/@Name` | `GPOS.Api` | `ServiciosWindows.Api` |
| `@Account` | `NT SERVICE\GPOS.Api`, sin `Password` | ADR-76; ADR-82, punto 2 |
| **`@Arguments`** | **exactamente** `--servicio`: un solo elemento, sin `--urls`, `--environment` ni otros | `ModoServicioApi.ArgumentoServicio` |
| `@Start` | `auto` (Q-8 abierta: `delayed-auto` si L-15 lo pide) | OPS-API 7.2 |
| `@Type`, `@ErrorControl`, `@Vital` | `ownProcess`, `normal`, `yes` | patrón del agente |
| `ServiceConfig` | `OnInstall="yes" OnReinstall="yes"`; `RequiredPrivilege` = la lista exacta | `ModoServicioApi.PrivilegiosDeclarados` |
| `util:ServiceConfig` | reinicio, reinicio, reinicio, 60 s, contador a 1 día; sin acción de comando | patrón del agente |
| `ServiceControl` | `Stop="both" Remove="uninstall" Wait="yes"` | INS 3.1 |
| Orígenes de eventos | `util:EventSource Log="Application"` para `GPOS.Api` y para `GPOS.Instalacion`, con `EventMessageFile` bajo `[WindowsFolder]` | `ServiciosWindows.Api`; `ComprobacionCarpetasPrevias.OrigenEventos` |
| Binarios | `%ProgramFiles%\GPOS NG\Api\`, publicación Release `win-x64` autocontenida en carpeta | INS 2.2 y 8 |
| Datos | `%ProgramData%\GPOS NG\Api\` con SDDL `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Api>)`; el SID se calcula con `IdentidadProceso.SidDeServicio` | ADR-77, puntos 1 y 4 |
| Raíz y `config\` | `GrupoRaizGposNg` y `GrupoConfigGposNg` en la *feature* de la API | `instalador/Comun/Fragmentos/RaizGposNg.wxs` |
| Comprobación previa | `ComprobacionCarpetasPrevias.wxs` con `GposFeatureCarpetas=Api`; fila `GposCarpetaPrevia` de `Api\` (`Servicio=GPOS.Api`, `CrearSiFalta=0`) | O-1; ADR-77, punto 3 |
| *Feature* | `Api`, `Level=1`, `AllowAbsent="no"`, `AllowAdvertise="no"` | R-02 de la relectura de #124 |
| Producto | `perMachine`, `UpgradeCode` nuevo, `MajorUpgrade` con `DowngradeErrorMessage`, `Manufacturer="GSF"` provisional (Q-4) | ADR-33 |

## El MSI no debe
- **Declarar `ServiceSid`** ni ningún privilegio fuera de la lista exacta.
- **Escribir entorno del servicio:** nada bajo `Services\GPOS.Api` (`Environment`), ni `urls`, `Kestrel`, `Jwt__Clave`, `Reenvio__Direccion`. La escucha y el TLS los fijan `red` y `tls` (ADR-90); la clave y el reenvío, `implantar-servidor`.
- **Arrancar el servicio al instalar** (sin `Start` en `ServiceControl`).
- **Declarar** el anillo, `Licencia\Entrada`, `temp`, `registros` ni carpetas de otro componente (ADR-77, puntos 4 y 5).
- **Llevar secretos** (`.pfx`, contraseñas, PIN) en el repositorio, parámetros o salida.
- **Fijar un SDDL del servicio** hasta que se responda Q-5.

## Condiciones de publicación
- **G-PR4:** `GPOS.Api.msi` no se firma mientras `src/GPOS.Api/Servicio/ModoServicioApi.cs` contenga `FijarEscuchaPorOmision` (hasta que se una PR-4, #139). El MSI sin firma se nombra `GPOS.Api-SINFIRMA.msi`.
- **Firma:** la `.CA.dll` (interna y exterior), las `GPOS*.dll` y el `.exe` propios, y el `.msi`; con la tabla `Binary` del MSI comparada con la `.CA.dll` firmada. Lo aporta A en T1-a (`instalador/Comun/Firma-Instalador.ps1`); T1-b se apila sobre él.
- **DEMO y MSI son excluyentes** en un mismo equipo (mismo nombre de servicio); PR-V crea el servicio con los mismos argumentos y privilegios (prueba T1-10).

## Cómo se comprueba en el laboratorio (VM de `LFMB`, lo ejecuta el técnico)
L-1 bis (`ImagePath` termina exactamente en ` --servicio`), L-2 bis (los dos orígenes registrados), L-2c a L-2e (4767 con el argumento fuera del SCM, sin origen y con privilegio de más). Detalle en la sección 3.1 del blueprint; A los pasa a `docs/operaciones/` en T1-c.

## Pendiente de B
Q-2 (G-PR4), Q-5 (SDDL), Q-6 (ventana de la VM) y Q-8 (`auto` o `delayed-auto`) antes del 3-nov; Q-3, Q-4 y Q-7 son del propietario.
