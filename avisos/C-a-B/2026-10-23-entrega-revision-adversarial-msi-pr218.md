```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (punto 3 del backlog de `B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7.md`) y hallazgos
Prioridad: Alta (H218-01 conviene corregirlo antes de unir el #218 y antes de correr A2 y A7 en la VM)
Repositorio y rama: GPOS-NG #218 (`b/t1b-api-msi` @ `57ba6585`); sin cambios al PR
Estado: Abierto
```

# Revisión adversarial del `GPOS.Api.msi` (#218): Rechazado para unir tal como está; el `-SINFIRMA` sirve para el laboratorio

Informe: `traspasos/C/2026-10-23-revision-adversarial-msi-pr218.md`. Es una recomendación técnica; la decisión es del propietario. Con H218-01 y H218-02 resueltos pasaría a Aprobado con observaciones. Sin mutar, las tres clases de pruebas del instalador dan 38/38, como dice el PR. No pude correr WiX 5.0.2 (no está en este equipo y no lo descargué): no construí el MSI, no leí sus tablas ni vi el texto real de `WIX1149`; tampoco pude lanzar `construir.ps1` desde la consola (G-PR4 la ejercí a través de las pruebas T1-09).

**Mutaciones.** Las cinco que declara el PR (`--urls x`, `Start="install"`, BU por WD, quitar `FailureActionsWhen`, G-PR4) se detectan, y mis cuatro mutaciones de la guarda (G1 a G4) mueren. De mis 17 mutaciones del paquete y del guion, **10 sobreviven a las 38 pruebas** y una es equivalente (C15: `construir.ps1:65` es código muerto). Las que importan: todo `MajorUpgrade` (quitarlo, permitir degradar, cambiar el calendario: C01 a C03), el GUID del componente del servicio (C07), un `util:PermissionEx` extra que da control total a Usuarios sobre `Api\` (C10), un directorio padre público `INSTALLDIR` (C05), `Files` sin recursión (C04), el MSI en ámbito por usuario (C06) y tres pasos de `construir.ps1`: limpiar `publicacion\` (C12), borrar el `.msi` sin firma si la firma falla (C14) y borrar los `.msi` previos (C16).

| ID | Sev. | Hallazgo |
|---|---|---|
| **H218-01** | **Alta** | Confirma L-02 y lo agrava. `MajorUpgrade` no declara calendario (`Package.wxs:34`) y el servicio se borra al desinstalar (`:71`): cada actualización borra y recrea el servicio y se pierden `Environment`, la DACL de la clave y el tipo de inicio. **Además** O-1 corre después de que ya se quitó la versión anterior (`ComprobacionCarpetasPrevias.wxs:72-75`): si rechaza, el equipo queda **sin API** (el caso A7). Remedio: `Schedule="afterInstallExecute"` con el GUID de `ProgramaApi` fijado, ~3 h más A1, A2 y A7 en la VM. [I], confianza alta. |
| H218-02 | Media (pruebas) | Ninguna prueba fija `MajorUpgrade` ni el GUID de `ProgramaApi` (C01 a C03 y C07 sobreviven). |
| H218-03 | Media | Sin `-Version` todo MSI es 1.0.0 (el `.csproj` no declara versión): dos compilaciones se instalan una al lado de la otra y las `GPOS*.dll` nuevas no reemplazan a las instaladas; `-Firmar` lo permite. Hace falta un caso A6b con una recompilación. |
| H218-04 | Baja | `WIX1149`: nada lee `MsiServiceConfig` después de construir. El servicio falla cerrado (`ModoServicioApi.cs:200-201`) pero entra en bucle de reinicios (L-01). |
| H218-05 | Baja, informativa | La ACE de BU `0x2008D` es correcta (CC, LC, SW, LO y RC; sin CR, RP, WP, DT ni SD); solo la fija el texto del `.wxs`. Q-5 amplía la consulta del servicio de IU/SU a BU, que incluye inicios de sesión de red; Q-5 está firmada y no pido cambio. No se sabe si sobrevive la auditoría (SACL) por omisión (lo mide I7). El spike crea el servicio sin el SDDL de Q-5. |
| H218-06 | Baja (pruebas) | Pasan sin probar lo que dice su nombre: T1-07 solo lee `Package.wxs` (el MSI sí lleva acciones personalizadas); T1-10 pasa en vacío; las últimas afirmaciones de la prueba de Q-5 son tautológicas; una de T1-08 pasa en vacío. |
| H218-07 | Baja (pruebas) | Mutantes vivos, cada uno con la afirmación que lo mataría (en el informe). |
| H218-08 | Baja | El origen de eventos compartido `GPOS.Instalacion` lo posee este MSI con un GUID propio: al actualizar se borra antes de O-1 y otros MSI lo perderían al desinstalar. Propongo moverlo al fragmento común. |
| H218-09 | Media (diseño) | Tu propuesta para L-04 (`demand` y la implantación lo pasa a `auto`) choca con las actualizaciones: cada una lo devolvería a `demand`. Recomiendo mantener `auto` y resolverlo con L-01 («reiniciar, reiniciar, ninguna»). |
| H218-10 | Informativa | Comentarios falsos: el DEMO no crea servicios (`instalador/Demo/LEEME.md:19`); los reinicios no son «tres veces»; G-PR4 habla de un texto que ya no existe. |

**Reparto:** B: H218-01 a H218-04 y H218-07 en la segunda pasada del `.wxs`. A: H218-09 (con Q-3 y Q-7), H218-05 punto 2 (para el propietario) y H218-08. Laboratorio: agregar A6b y ampliar A1 con `publicacion.sha256`; correr A2 y A7 con el MSI corregido antes de unir.

Respuesta requerida: decisión sobre H218-01 a H218-10.
