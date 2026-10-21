[Blueprint Técnico] Estado del documento: **Completado (respuestas de B)**. Las decisiones que necesitan la firma del propietario están en la sección 2 y siguen **Pendientes de firma**. Lo demás es una decisión técnica de B como coordinador e integrador; no requiere firma porque no cambia lo que ve ni lo que hace ninguna persona (RC-T4-4 de la hoja del tramo 4).

# Respuestas de B a los planos de A: instalador (O-1, O-3, N-10) y ADR-90 (RT-01, RT-05, RT-06)

- **Fecha:** 2026-10-20
- **Autor:** arquitecto-software del equipo B
- **Responde a:**
  - **INST-A:** `GPOS-NG-Equipos/traspasos/A/blueprint-instalador-o1-o3-n10-2026-10-20.md`;
  - **RED-A:** `GPOS-NG-Equipos/traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`;
  - **AVISO:** `GPOS-NG-Equipos/avisos/A-a-B/2026-10-20-planos-instalador-y-adr90.md`.
- **Insumos (en `master` `7e6c08e7`):**
  - [ADR-90](../adr/ADR-090.md) y la [hoja de PT-01 a PT-10](../decisiones/2026-10-20-hoja-firma-precisiones-adr090.md) (**HPT**);
  - la [revisión de seguridad de ADR-90](../seguridad/2026-10-20-revision-adr090-red-tls.md);
  - la [hoja del tramo 4 y del paquete único](../decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md) (**HOJA**);
  - el [diseño del paquete único, v2](../operaciones/2026-10-19-diseno-instalador-reportes.md) (**INS**);
  - [ADR-77](../adr/ADR-077.md), [ADR-82](../adr/ADR-082.md) (D-09), [ADR-109](../adr/ADR-109.md) (cláusula 9) y [ADR-129](../adr/ADR-129.md) (bloque B);
  - el [plan de D1 de DB-7](2026-10-19-db7-d1-plan-de-trabajo.md) (**D1**) y el [blueprint v3 de DB-7](2026-10-18-db7-blueprint-v3.md) (**BP3**).
- **Código:** leído en `origin/feature/modelo-ng` `b8f166db` y en `master` `7e6c08e7`, con `git show` y `git grep` (también en las 161 ramas de `origin` para los EventId). No compilé ni ejecuté nada.
- **Convención:** [V] = verificado, con cita `archivo:línea` de `feature/modelo-ng` salvo que se indique otra rama; [I] = inferido. Esfuerzo en días-persona (dp), ±50 %; 1 sp = 5 dp.

---

## 0. Resumen de las decisiones de B

| Tema | Decisión de B | ¿Firma? |
|---|---|---|
| EventId | 4743 a 4752 para ADR-90 (A); 4753 a 4766 para la acción previa y el actualizador (A); 4767 a 4779 para `GPOS.Instalacion` de B; 4780 a 4789 para el verbo `tls` y su tarea (A); 4790 a 4799 en reserva para DB-7. Se abandona 5130 a 5149 | No |
| Proyectos nuevos | Una sola excepción que nombra los 5 proyectos: la acción DTF, tres `.wixproj` y `GPOS.Comun.Servidor` | **Sí (F-1)** |
| Orden de la cadena del *bundle* | Validación previa, `red`, los tres MSI, `tls`, esquema, credenciales y verificar. El esquema y `tls` pasan **después** de los MSI | Confirmación (F-6) |
| Registro `HKLM\SOFTWARE\GPOS NG\Servidor` | Lo escribe un verbo de `GPOS.Migracion` (`red`) con su ACL, antes de los MSI. Los MSI no lo escriben | No |
| Sin modo | Solo si la instalación no está en modo de identidad Estricto. Con Estricto, falla cerrada | No |
| `IpNodos` | El *bundle* lo escribe siempre, aunque esté vacío. En «servidor de sitio», si falta, 4743 | No |
| `Api:Url` y `AllowedHosts` | Se derivan del registro en el código, no los escribe el MSI | Confirmación (F-6) |
| PR-4 (4 líneas en el `Program.cs` de la API) | Adelantarlo a la ventana del 10-28 al 11-06, si se firma. Si no se firma o no llega a tiempo, después del 11-20 | **Sí (F-5)** |
| N-10 en detalle, Q-4 y Q-5 | No se firman ahora. Van a la hoja del actualizador, después de la revisión del auditor | Más adelante (F-3) |
| O-3 y la reserva de EventId | Son puntos técnicos (HOJA, sección D) | No (F-2 y F-4 no hacen falta) |

---

## 1. Respuestas a las preguntas de A

### 1.1 Plano del instalador (INST-A, sección 7)

**Q-1 · ¿Los `.wixproj` de Api, Web y del *bundle* entran en la excepción F-1? Sí, y se nombran uno por uno.** La misma excepción incluye también `GPOS.Comun.Servidor` (hallazgo HB-02).

- **Por qué cuentan.**
  - La regla de `CLAUDE.md` («Proyectos nuevos») nombra un instalador entre sus excepciones (`instalador/Reportes`). Eso indica que los proyectos de instalador cuentan como proyectos nuevos. [V] (`CLAUDE.md`, sección «Estructura y convenciones»)
  - ADR-129, bloque B, punto 3, firmado, repite la regla («Sin proyectos nuevos»). [V] (`docs/adr/ADR-129.md:32`)
  - ADR-109 deja expresamente sin fijar el nombre del proyecto del paquete. [V] (`docs/adr/ADR-109.md:113`)
- **Lista que B propone para F-1.** Sigue el patrón del único instalador que ya existe, `instalador/AgenteImpresion/GPOS.AgenteImpresion.Instalador.wixproj`, que está fuera de `GPOS-NG.slnx` [V] (`GPOS-NG.slnx:3-20`).

  | Proyecto | Ruta | Destino | ¿En `GPOS-NG.slnx`? |
  |---|---|---|---|
  | Acción previa compartida (O-1) | `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj` | `net472` | No |
  | MSI de la API | `instalador/Api/GPOS.Api.Instalador.wixproj` → `GPOS.Api.msi` | WiX 5 | No |
  | MSI de la Web | `instalador/Web/GPOS.Web.Instalador.wixproj` → `GPOS.Web.msi` | WiX 5 | No |
  | *Bundle* | `instalador/Servidor/GPOS.Servidor.Paquete.wixproj` → `GPOS-NG-Servidor-x.y.z.exe` | WiX 5 Burn | No |
  | Biblioteca de red de servidor (RED-A, 2) | `src/GPOS.Comun.Servidor/GPOS.Comun.Servidor.csproj` | `net10.0` | **Sí** |

- `instalador/Reportes` ya está exceptuado (ADR-109, cláusula 1). Su proyecto se llamará `GPOS.Reportes.Instalador.wixproj`, por coherencia; no necesita otra firma.
- **`GPOS.Instalacion` no es un proyecto.** Es el **origen de eventos** del Visor de eventos que declara `GPOS.Api.msi` [V] (INS:161). No hace falta ninguna excepción. **No se crea un proyecto `GPOS.Instalacion`:** los verbos de implantación y de verificación viven en `GPOS.Migracion` (N-3 del INS).
- **Lo que no se pide ahora:** el actualizador de N-10 (`GPOS.Actualizador` y su MSI) también es un proyecto nuevo. Su excepción se pedirá con F-3, cuando se diseñe el actualizador.

**Q-2 · ¿Se reordena la cadena (H-4 / C-O1-5)? Sí: (a) + (b), y con más cambios de los que propone A.**

El hallazgo H-4 de A se confirma. Además, hay **dos motivos más** para mover el esquema y `tls` después de los MSI (hallazgo HB-01). La cadena queda así:

| # | Paquete de la cadena | Qué hace | Escribe bajo `%ProgramData%\GPOS NG` | SQL | Límite de reversión |
|---|---|---|---|---|---|
| 0 | `ExePackage` `comprobar-servidor --fase previa` | Prerrequisitos (INS 3.1, paso 0) **y validación de los parámetros de ADR-90**: `MODO_RED` obligatorio en la primera instalación y `CONFIRMAR_CAMBIO_MODO` (PT-06); `IP_NODOS` solo con /32 o /128 (PT-05); `NOMBRES_SERVIDOR` (PT-03); puerto 443 libre | No | Solo lectura | — |
| 1 | `ExePackage` `preparar` (solo en una actualización) | Detiene los servicios y hace el respaldo de B-5 | No (los respaldos van a la ruta de la herramienta de respaldo, MD-54) | Sí | — |
| 2 | `ExePackage` `red` (verbo nuevo de `GPOS.Migracion`) | Crea `HKLM\SOFTWARE\GPOS NG\Servidor` con su ACL y escribe `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor` e `IpNodos`. Si cambia el modo, deja un evento (PT-06) | No | No | — |
| 3 | `MsiPackage` `GPOS.Api.msi` | **Primer MSI del núcleo:** su acción previa (O-1) crea la raíz protegida. El servicio queda detenido. Lee el registro con `RegistrySearch` para su regla de cortafuegos (RT-06) | Sí, protegido | No | Empieza |
| 4 | `MsiPackage` `GPOS.Web.msi` | Igual que la API | Sí | No | Dentro |
| 5 | `MsiPackage` `GPOS.Reportes.msi` | Como en INS 2.1 | Sí | No | Termina |
| 6 | `ExePackage` `tls` (verbo de A) | Crea la CA, emite o importa el certificado, da a cada cuenta virtual la lectura de su llave, **instala la CA en `LocalMachine\Root` del propio servidor** (Q-8 de ADR-90) y publica las huellas en el registro (PT-02). Crea `Servidor\tls\` con una DACL protegida explícita (P-77-2) | Sí, bajo la raíz ya protegida | No | Fuera (solo hacia adelante) |
| 7 | `ExePackage` `esquema` | `sistema --login-api "NT SERVICE\GPOS.Api"`, `actualizar` y las vistas | No (ver HB-01) | Sí | Fuera |
| 8 | `ExePackage` `credenciales` | `crear-lectura-sistema`, `llave-sitio`, `crear-lectura --todas` y la marca | No | Sí | Fuera |
| 9 | `ExePackage` `verificar` | Arranca los servicios, ejecuta `comprobar-servidor --estricto` y **copia el registro de Burn a `Instalacion\`**, que crea con una DACL protegida explícita (A, opción (b)) | Sí, al final | Lectura | — |
| — | (opcional) `GPOS.EstacionImpresion.msi` | N-11 | Sí, con su propia acción previa | No | Propio |

- **El registro de Burn** queda en el `%TEMP%` de quien instala hasta el paso 9 (opción (b) de A).
- **Los MSI no arrancan sus servicios.** Los arranca el paso 9 (INS 3.1). Por eso, migrar después de los MSI no deja ningún servicio corriendo sobre un esquema viejo.
- **Una falla en los pasos 6 a 8** deja los binarios nuevos, los servicios detenidos y la instalación sin marca. El paso se puede reintentar porque es idempotente. Con B-5 firmada, volver atrás después de migrar es restaurar el respaldo. El límite de reversión agrupa **solo** los MSI, para que una falla de SQL no los revierta.
- **Por qué `red` va antes de los MSI:** cada MSI arma su regla de cortafuegos con los valores del registro. Así, una reparación desde la caché de Burn usa los mismos valores, y no queda una segunda fuente (PT-06).
- **Lo que cambia frente a lo escrito:**
  - el orden de INS 1.1 y 3.1 y la prueba B-1 de INS 10;
  - la frase de ADR-90 «Impacto en el paquete único»: «`ExePackage "tls"` … **antes** de los MSI, porque los MSI dan a cada cuenta virtual la lectura de su llave». Desde PT-02 esa lectura la da el verbo, así que el motivo ya no existe.

  No cambia lo que ve ni lo que hace nadie. Se pide confirmación en F-6 porque toca el texto de un ADR aceptado.

**Q-3 · ¿Cuándo se alinean IQ y AdmCloud? En la próxima versión de cada conector, y en todo caso antes de cualquier instalación fuera de desarrollo.**
- **IQ:** agrega `Permanent="yes"` al componente de la raíz y conserva su GUID (`9E7A0D3C-…`), que pasa a ser el canónico.
- **AdmCloud:** adopta el GUID canónico.
- Cada conector agrega la prueba P-O3-5, que compara su GUID con el vector v3.
- Esfuerzo: unos 0,25 dp por conector, en el repositorio de cada uno.
- **No hay ninguna instalación de IQ 0.4.1 fuera del laboratorio** [I]. ADR-77 dice «MSI 0.4.1, pendiente de la prueba elevada» [V] (`docs/adr/ADR-077.md:68`), y hoy todo es desarrollo.

**Q-7 · ¿Quién fija los privilegios de `NT SERVICE\GPOS.Api`? A, como dice la hoja firmada.** La hoja firmada prevalece sobre el encargo. El reparto queda así:
- **A (arquitecto-software):** propone la lista y la justifica, privilegio por privilegio (ADR-76, punto 2). La hoja se lo asigna a A [V] (HOJA:491 y HOJA:594).
- **Devops de B:** la mide en el laboratorio con `sc qprivs` (INS, P1).
- **Auditor-seguridad:** la revisa.
- **B (desarrollador):** construye el código de N-1 (`AddWindowsService` **y** `AddSystemd`, según ADR-129 B.1, más `ARRANQUE_PRIVILEGIOS`), porque está en el `Program.cs` de la API, que es zona S de DB-7.
- **Punto de partida:** solo `SeChangeNotifyPrivilege`, como Reportes y la estación [V] (`instalador/AgenteImpresion/Package.wxs:111-113`). Que el servidor de la canalización de introspección compruebe al cliente con nivel de identificación sin `SeImpersonatePrivilege` es [I]; lo prueba el laboratorio.
- **No bloquea** O-1, O-3 ni N-10.

**Q-8 · ¿Se adopta la franja 47xx en lugar de 5130 a 5149? Sí.** La franja 5130 a 5149 choca con números ya usados [V, en 76 ramas de `origin`]: del 5130 al 5133 (`IdentidadAmplia` … `SinSuperUsuario`) y del 5140 al 5143 (`UsuarioSinSello` … `PadronDiscoAusente`). Reparto definitivo:

| Franja | Para | Construye | Estado [V] |
|---|---|---|---|
| 4742 | `ModuloVenceIgnorado` | A (#103, abierto) | Usado en `a/dv07-formato-licencia` |
| 4743 a 4752 | ADR-90: API y Web (RED-A 5.5) | A | Libre en las 161 ramas |
| 4753 a 4766 | Acción previa de O-1 (origen `GPOS.Instalacion`) y lado elevado del actualizador (`GPOS.Actualizador`) | A | Libre |
| 4767 a 4779 | `GPOS.Instalacion` de B: `comprobar-servidor` (un EventId por familia de comprobaciones, con el código R/P/K en los datos), `implantar-servidor`, `red` (cambio de modo de PT-06) | B | Libre |
| 4780 a 4789 | Verbo `tls` y tarea `GPOS NG\Renovar TLS` (RT-04): renovado, fallo, avisos a 20, 10 y 3 días, «CA en software» (H-13) y CA sucesora | A | Libre |
| 4790 a 4799 | Reserva de DB-7 (D2 a D5), por si necesita algo más allá del 4741 | B | Libre |

- B lo registra con el documentador como nota de ADR-82.
- Antes de unir cada PR, se vuelve a comprobar con `git grep` en todas las ramas (regla de ADR-82:220).
- Sin errores SQL nuevos; nada entre el 51618 y el 51644.

**Q-4 y Q-5 (al propietario):** van a la sección 2, como F-3. **Q-6 (al diseñador del agente):** se acepta como entrada del diseño del actualizador. No se decide aquí.

**H-6 / N-10 en general.** Se acepta como dirección técnica, pero **no hace falta firmarla ahora**: el actualizador no entra antes del corte y B-6 ya exige la revisión del auditor antes de construirlo (HOJA:338). Ver F-3 y HB-13.

### 1.2 Plano de ADR-90 (RED-A, sección 12)

**Q-1 · Registro: se aceptan los nombres, los tipos y los dominios de RED-A 4.1, con cinco cambios.**
1. **`IpNodos`:** en «servidor de sitio», si **falta**, el resultado es 4743 y el servicio no arranca. RED-A ponía «lista vacía». El *bundle* lo escribe siempre, vacío en los nodos y en un sitio único (ver Q-7 y HB-05).
2. **Escritor único:** el verbo `red` de `GPOS.Migracion` (paso 2 de Q-2). **Sí: el mismo paso crea la clave y su ACL.** La clave lleva una DACL protegida: SYSTEM y Administradores con control total; Usuarios autenticados con lectura, porque ningún valor es secreto. Los MSI no escriben la clave (HB-08). El verbo `tls` escribe solo `HuellaApi` y `HuellaWeb`.
3. **Valores del paquete en la misma clave:** `Version`, `FechaInstalacion` y `RegistroInstalacion` (INS:68), que el paso 9 escribe al terminar bien. El lado elevado de N-10 lee `Version` de aquí.
4. **`PuertoApi`:** también tiene que ser distinto de `PuertoWeb` (443 por omisión), además de 5073 y 17654.
5. **`PuertoWeb`:** se acepta como valor opcional, solo para la excepción del 443 ocupado (riesgo de ADR-90).

Las constantes de los nombres van en `GPOS.Comun/Red/ValoresRegistroServidor.cs`, como propone A. Las usan `red`, `tls` y los servicios.

**Q-2 · `Api:Url`: se deriva del registro, como recomienda A.**
- El MSI **no** escribe `Api:Url`, y `ArchivoInstalacion.SeccionesPermitidas` sigue solo con `GPOS:RncDgii` [V] (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:27`; B-7 firmado).
- **Con el modo presente:**
  - si la configuración trae un `Api:Url` distinto del que sale del registro, el resultado es 4743;
  - sin modo, rige `Api:Url` como hoy.
- **Lo mismo vale para H-15:** `AllowedHosts` se arma en el código a partir de `NombresServidor` (más `localhost` en «un equipo»). Así hay una sola fuente (PT-06).
- PT-01 («Qué rompe») y PT-10 (H-09 y H-15) decían «lo escribe el MSI». El fin se cumple igual, pero se pide confirmación en **F-6**.
- Va en PR-2 (H-15 cuesta unos 0,1 dp).

**Q-3 · DEMO: la opción (a), con un criterio más preciso. No hace falta firma.**
- **El DEMO no se abre desde otra PC:**
  - escucha solo en `localhost` [V] (`instalador/Demo/scripts/herramientas/Comun-Demo.ps1:344` y `:374`, `ASPNETCORE_URLS=http://localhost:…`; `instalador/Demo/LEEME.md:16`);
  - `launchSettings` también usa `localhost` [V] (`src/GPOS.Api/Properties/launchSettings.json:8,17`; `src/GPOS.Web/Properties/launchSettings.json:8,17`);
  - el ensayo `tests/GPOS.EnsayoImplantacion/iniciar-api.ps1:23` y las pruebas con Kestrel usan `127.0.0.1` [V].
- **Criterio que B fija:** el estado «sin modo» se admite **solo si el modo de identidad no es Estricto**, con `ComprobacionAnillo.EsEstricto` [V] (`src/GPOS.Core/Infraestructura/Anillo/ComprobacionAnillo.cs:50`; en la Web, `ProteccionDatosWeb.EsEstricto`, `src/GPOS.Web/Servicios/ProteccionDatosWeb.cs:50`).
  - Con Estricto, que el *bundle* impone (INS B-11), y sin `ModoRed`: 4743 y el servicio no arranca. Es la falla cerrada de RT-01 y PT-06 (HB-04).
  - Sin Estricto (desarrollo, pruebas y DEMO): la opción (a) de A, es decir, solo direcciones de *loopback* y el aviso 4745.
- **Fuera de Windows:** el mismo criterio. Con Estricto no hay fuente y el servicio no arranca; no se cae a «sin modo» (HB-03).
- **Cuando el DEMO adopte el paquete (A-5):** usará «un equipo» y devops quitará `ASPNETCORE_URLS` de sus guiones, porque con el modo presente se rechaza (regla 1 de RED-A 5.1).

**Q-4 · Acciones de recuperación de `GPOS.Api` y `GPOS.Web`: las mismas que Reportes y la estación.**
- **Configuración:** reiniciar a los 60 s, tres veces; el contador vuelve a cero al día [V] (`instalador/AgenteImpresion/Package.wxs:114-115`; A-7 firmado, mitigación 1).
- **Además**, en el MSI: `FailureActionsWhen="failedToStopOrReturnedError"`, que es la marca «acciones ante detenciones con error».
  - Sin esa marca, un servicio que se detiene con `Environment.ExitCode = 1` no dispara la recuperación [I; el atributo de WiX 5 se comprueba al compilar] (HB-15).
- **Resultado esperado:**
  - una falla transitoria se recupera sola; por ejemplo, el 4747 mientras la tarea de renovación da la lectura de la llave;
  - una falla de configuración deja como máximo 3 eventos críticos y el servicio detenido;
  - después salta la alerta de «servicio detenido más de 2 minutos» (B-8).
- R-10 de RED-A queda en riesgo Bajo.

**Q-5 · EventId: sí, del 4743 al 4752** (tabla de Q-8 de 1.1).
- **En las ramas locales de B no hay nada en 47xx sin publicar** [V: `git grep` en `refs/heads`, sin resultados del 4740 en adelante]. Los árboles de trabajo sin confirmar no se revisaron.
- **El crítico de la API de reportes lo hace B,** porque es zona R de DB-7 y código de B. Recibe el **5119 `DireccionNoPermitida`** (libre [V]; el 5117 y el 5118 quedan para P-09 de IMP). También fija `Environment.ExitCode = 1` antes de `StopApplication()` (`src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:170-179`; HB-12). Va en un PR pequeño del tramo 4.

**Q-6 · ¿PR-4 puede unirse antes del 2-nov? Técnicamente sí, pero exige firma (F-5).**
- **Por qué hace falta firma:** la regla firmada RC-T4-3 (HOJA:72) y la sección 5 de HPT («lo que toque `src/GPOS.Api/Program.cs` (escucha de PT-06, filtro de PT-05) se une después del 2026-11-16») se aplican expresamente a ADR-90 (HB-09).
- **B recomienda adelantarlo** a la ventana del **10-28 al 11-06**, con dos condiciones:
  - que PR-1 a PR-3 estén unidos;
  - que la unión sea antes de que T1-3 agregue sus líneas de rutas (11-09).
- **Si no se firma o no llega a tiempo:** se une **después del 11-20** (punto de control de DB-7). Así cumple RC-T4-3 y evita el 11-16 y el 11-17, días sin suites por la medición del banco.
- Detalle en la sección 4.

**Q-7 · `IpNodos` en un nodo: vacío, nunca sin crear.** El *bundle* escribe siempre un `REG_MULTI_SZ` vacío en los nodos y en un sitio único. En «servidor de sitio», si el valor falta, el resultado es 4743. En «un equipo» no se lee.

**Q-8 · ¿El paso `tls` instala la CA en el propio servidor? Sí.**
- **Qué hace:** el verbo `tls` (de A) instala la parte pública de la CA del sitio en `LocalMachine\Root` del servidor, en los dos modos, dentro de su ejecución elevada.
- **Orden:** el *bundle* lo ejecuta en el paso 6 de la cadena.
- **Con el «certificado del cliente»:** no instala nada, porque la cadena ya la conoce el sistema.
- **Coherencia con PT-03:** la Web no tiene una CA fijada, así que usa solo el almacén del sistema. No mezcla las dos fuentes.
- **Riesgo residual:** las salidas TLS del propio servidor (DGII, IQ) confiarán en una CA con Name Constraints limitados a los nombres del sitio. Es Bajo [I].
- **Desinstalación:** la CA se conserva, como dice ADR-90.

**Q-9 · ¿La recolección de archivos toma el DLL nuevo? Sí, sola.**
- **Cómo se recolecta:** los MSI del núcleo recolectan la carpeta de publicación entera, con el elemento `Files` de WiX 5 [I; se comprueba al compilar]. No hay una lista de archivos a mano, así que `GPOS.Comun.Servidor.dll` entra sin cambios.
- **Control:** el `construir.ps1 -Firmar` de cada MSI rechaza cualquier `GPOS.*.dll` sin firma válida (`signtool verify /pa /tw`). Así, un DLL propio nuevo no puede colarse sin firmar.

**Q-10 · Clave «(cuenta, IP)»: no se persiste, y es de D2, no de D1.**
- **Dónde vive:** el contador por (cuenta, IP) vive **en memoria** (15 minutos, tope de 100 000 entradas) [V] (BP3:528; E-SW-4, BP3:1083). Lo construye **D2** (zona T), no D1 [V] (BP3:631 y BP3:767).
- **Efecto de normalizar `LimitesPeticiones.Ip`:** solo trae beneficios.
  - La bitácora ya guarda la IP normalizada [V] (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:212`, `:257` y `:283`).
  - El emparejamiento de dispositivos ya normaliza su clave [V] (`src/GPOS.Core/Servicios/Modulos/Restaurante/Dispositivos/Contratos.cs:170-178`).
- **Qué hace D2:** usa `LimitesPeticiones.Ip` como única fuente. Cambiar las tres normalizaciones en línea de `AuthEndpoints` por `DireccionIp.Normalizar` es una limpieza que hará D2 cuando toque ese archivo; **A no toca la zona T**.
- **Pedido a A:** que PR-3 se una **antes del 11-09**, cuando D2 empieza a usar la IP para el bloqueo.

---

## 2. Lo que firma el propietario

> Las decisiones las firma el propietario. Hasta entonces, todo lo de esta sección está **Pendiente de firma**. Frase para firmar lo urgente: **«F-1, F-5 y F-6 según la recomendación»**.

**No necesitan firma:**
- **F-2 (O-3) y F-4 (EventId):** la hoja firmada pone O-1, O-3 y N-8 entre los «puntos técnicos sin firma del propietario» [V] (HOJA:485-486 y HOJA:495). B los da por resueltos en la sección 1.
- **El estado «sin modo», `IpNodos`, la CA en el servidor, la recuperación del servicio y quién fija los privilegios:** no cambian lo que ve ni lo que hace nadie.

### F-1 · Excepción a la regla de proyectos nuevos (`CLAUDE.md` y ADR-129, bloque B, punto 3) · **firmar ahora**

- **Contexto [V].**
  - O-1 necesita una acción DTF de .NET Framework. Todos los proyectos de `src` son `net10.0`, y ADR-77 descarta PowerShell [V] (`docs/adr/ADR-077.md:48`).
  - El paquete necesita tres `.wixproj` que no existen.
  - RED-A crea `GPOS.Comun.Servidor` para no meter ASP.NET Core en `GPOS.Comun`, que también usan `GPOS.Migracion` y `GPOS.Reportes`.
- **Opciones:**
  - **(a, recomendada): excepción para los cinco proyectos de la tabla de Q-1 (1.1).**
    - Los cuatro de `instalador/` quedan fuera de `GPOS-NG.slnx`, como el del agente.
    - `GPOS.Comun.Servidor` entra en la solución.
    - Sin referencias desde `src` hacia `instalador/`.
  - **(b): excepción solo para los cuatro de `instalador/`.** Las piezas de Kestrel de ADR-90 se comparten entre la API y la Web con archivos vinculados (`Compile Include … Link`), como ya se hace con el anillo en la Web [V] (`src/GPOS.Web/GPOS.Web.csproj:14-16`).
    - Ahorra un proyecto.
    - Compila el mismo código en dos ensamblados, y las pruebas lo cubren por uno solo (unos +0,3 dp de pruebas y una prueba de arquitectura que compare los vínculos [I]).
  - **(c): ninguna excepción.** No es viable: sin la acción previa, el *bundle* no se firma ni se publica (B-1 firmado, HOJA:241), y sin *bundle* no hay primera instalación de cliente.
- **Qué rompe:** nada visible. Cada instalador suma una DLL que firmar (ADR-33). El documentador agrega los cinco nombres a la línea de excepciones de `CLAUDE.md` y a ADR-109, cláusula 1.
- **A quién afecta:**
  - al equipo A, que construye la acción y la biblioteca;
  - a devops y a B, que construyen los tres `.wixproj`;
  - al documentador.
- **Por qué se justifica:**
  - es la única forma de cumplir ADR-77, punto 3, con una acción diferida y sin suplantación dentro de cada MSI;
  - una biblioteca con `FrameworkReference` es la forma estándar de compartir código de Kestrel sin arrastrar ASP.NET Core a `GPOS.Migracion`.
- **Cómo se migra:** no hay nada que migrar.
- **Costo:** USD 0 de licencias. El esfuerzo ya está en INST-A (3,5 dp de O-1) y en RED-A (1 dp de PR-1).
- **Lo que no cubre:** el actualizador de N-10, que pedirá su propia excepción con F-3.

### F-5 · Adelantar PR-4 de ADR-90 (y N-1 de B) antes del 2026-11-06 · **firmar ahora** (sirve hasta el 10-28)

- **Contexto [V].**
  - RC-T4-3 (HOJA:72) y HPT, sección 5, fijan que lo de ADR-90 que toque `src/GPOS.Api/Program.cs` se une después del 11-16.
  - PR-4 son 4 líneas (RED-A, 7).
  - La zona S de DB-7 está libre hasta T1-3 (11-09) y T1-5 (congelada del 11-11 al 11-13) [V] (D1, 6.2 y 6.3).
- **Opciones:**
  - **(a, recomendada):** PR-4 de A y el PR de N-1 de B (`AddWindowsService`, `AddSystemd` y `ARRANQUE_PRIVILEGIOS`) se unen en la ventana del **10-28 al 11-06**, uno detrás del otro, con la suite completa sola. Si no entran a tiempo, pasan a **después del 11-20**.
  - **(b):** mantener lo firmado. PR-1 a PR-3 se unen sin conectar, y PR-4 y N-1 entran después del 11-16. En la práctica, después del 11-20.
- **Qué rompe (a):** nada visible. En desarrollo, en las pruebas y en el DEMO rige el estado «sin modo» (solo *loopback*), que es lo que ya hacen hoy [V] (Q-3).
- **A quién afecta:** a la capacidad de revisión de B en S1 (unos 0,25 dp) y al calendario de DB-7, que no se mueve.
- **Por qué se justifica:**
  - el código de ADR-90 no queda un mes sin conectar;
  - la integración real (arranque, filtro antes de `UseForwardedHeaders`) se prueba antes del tramo más cargado (T4-02, e-CF el 15-nov y el punto de control del 11-20);
  - se evitan dos rebases sobre la zona S.
- **Cómo se migra:** no aplica.

### F-6 · Confirmación de dos precisiones de construcción de ADR-90 · **firmar ahora** (bajo peso)

- **(i)** `Api:Url` y `AllowedHosts` se derivan en el código del registro `HKLM\SOFTWARE\GPOS NG\Servidor`; no los escribe el MSI.
  - Cambia la forma de PT-01 («Qué rompe»), de H-09 y de H-15 de PT-10.
  - Se mantiene el fin: sin `Api:Url` en HTTP por omisión fuera de `Development`.
- **(ii)** El paso `tls` del *bundle* va **después** de los MSI, no antes.
  - Cambia «Impacto en el paquete único» de ADR-90.
  - Su motivo («los MSI dan a cada cuenta virtual la lectura de su llave») dejó de existir con PT-02.
  - Ejecutarlo antes crearía `%ProgramData%\GPOS NG\Servidor\tls\` sin la raíz protegida (HB-01).
- **Opciones:**
  - **(a, recomendada):** confirmar las dos.
  - **(b):** que el Arquitecto Maestro las trate como puntos técnicos sin firma (RC-T4-4) y el documentador las anote. B no se opone: las propone a firma solo porque tocan el texto de un ADR aceptado.
- **Qué rompe:** nada. **A quién afecta:** a A (Web y verbo `tls`) y a devops (*bundle*). **Cómo se migra:** no aplica.

### F-3 · N-10 en detalle (servicio a demanda y modo híbrido `requiereTecnico`), con Q-4 y Q-5 · **no firmar todavía**

- **Por qué esperar:**
  - B-6, firmado, exige que el auditor revise el diseño antes de construir el actualizador [V] (HOJA:338);
  - el actualizador no entra antes del corte (INS 9.2 lo deja fuera);
  - firmar hoy un detalle que el auditor puede cambiar obligaría a firmarlo dos veces.
- **Recomendación para cuando se firme:**
  - el lado elevado como servicio a demanda que vuelve a verificar todo (INST-A 3.2);
  - el **modo híbrido** con `requiereTecnico` **derivado automáticamente** por la tubería (HB-13);
  - Q-4: sin respaldo en `MODO=Automatico`, porque no cambia ningún dato;
  - Q-5: ventana configurable por sitio, por omisión de 02:00 a 05:00, aplicada solo si no hubo ventas en los últimos 15 minutos (señal sin SQL privilegiado, por `/api/salud`), con aplazamiento máximo de 7 días y luego un aviso. **No** se recomienda «sin jornadas abiertas»: un negocio de 24 horas podría no aplicar nunca una versión [I].
- **Qué rompe (híbrido):** la actualización no es automática en las versiones que migran, que hoy son casi todas [I]. El técnico ejecuta el *bundle* con su identidad (D-09).
- **Alternativa que el auditor debe evaluar:** que la cuenta virtual del lado elevado tenga un login de Windows con los permisos de esquema.
  - No tiene contraseña que custodiar, que era el motivo de D-09 para aplazar `gpos_esquema` [V] (`docs/adr/ADR-082.md:71`).
  - Pero es una identidad SQL privilegiada y permanente en el equipo.
  - Exigiría precisar D-09 con firma.
- **Frase, cuando toque:** «F-3, Q-4 y Q-5 según la recomendación».

---

## 3. Hallazgos de la revisión de los planos

| # | Sev. | Hallazgo | Evidencia | Qué se hace |
|---|---|---|---|---|
| **HB-01** | **Alta** | **El orden de INS 1.1 y de ADR-90 («Impacto») no funciona en una instalación nueva, por más motivos que H-4.** (1) `sistema --login-api "NT SERVICE\GPOS.Api"` corre en el paso del esquema, antes de que exista el servicio; una cuenta virtual solo se resuelve con el servicio instalado. INS lo reconoce para Reportes, pero no para la API. (2) `tls` antes de los MSI escribiría `Servidor\tls\` sin la raíz protegida y daría la lectura de la llave a cuentas que aún no existen. (3) Confirma H-4: `GPOS.Migracion` configura el anillo para las empresas, y `CarpetaAnillo.Crear` crea el padre con la DACL heredada | [I] (1) a partir de INS:43; [V] (2) ADR-090.md:137 y PT-02; [V] (3) `src/GPOS.Migracion/EmpresasSistema.cs:31`, `src/GPOS.Core/Infraestructura/Anillo/AnilloDataProtection.cs:257` y `CarpetaAnillo.cs:41` | Nueva cadena (Q-2 de 1.1); prueba P-O1-8 de A. **A corrige `CarpetaAnillo.Crear`** para que cree los padres fuera de la carpeta del componente con una DACL protegida explícita (P-77-2), dentro de la pista de H-17 v2 |
| HB-02 | Media | RED-A crea el proyecto `GPOS.Comun.Servidor` y lo trata como «decisión candidata a precisión», sin firma. Es un proyecto nuevo, sujeto a `CLAUDE.md` y a ADR-129, bloque B, punto 3 («Sin proyectos nuevos») | [V] RED-A:53 y :388-393; `docs/adr/ADR-129.md:32` | Entra en F-1. Mientras tanto, A puede hacer **PR-1a** solo con `GPOS.Comun/Red`, que no necesita proyecto nuevo |
| HB-03 | Media | `FuenteRegistroWindows.cs` y `AlmacenMaquinaWindows.cs` no siguen la convención `*.Windows.cs` que vigila ADR-129 (B.3 y B.5). Además, «en Linux la fábrica devuelve `SinModo`» contradice B.2 (falla cerrada sin una implementación para la plataforma) | [V] RED-A:97, :106 y :266; `docs/adr/ADR-129.md:31-34` | Renombrar a `FuenteConfiguracionRed.Windows.cs` y `AlmacenCertificadosServidor.Windows.cs`. Fuera de Windows y con Estricto, no arranca (Q-3) |
| HB-04 | Media | Tal como está escrita, la opción (a) de «sin modo» deja que una instalación de cliente a la que le borren el registro arranque en *loopback* con HTTP. Eso no es la falla cerrada de RT-01 y PT-06 | [V] RED-A:110-115; ADR-090.md:241 | «Sin modo» solo sin Estricto (Q-3) |
| HB-05 | Media | `IpNodos` ausente se trataba como lista vacía: en una central con nodos, eso abre toda la API a los nodos (falla abierta) | [V] RED-A:73 | 4743 en «servidor de sitio»; el *bundle* lo escribe siempre (Q-1 y Q-7) |
| HB-06 | Media | **EventId:** (1) los dos planos de A se solapan (4743-4756 frente a 4743-4752); el aviso lo corrige. (2) BP3 e IMP daban por hecho que «4742 y siguientes quedan para DB-7», pero el 4742 ya lo tomó el #103; DB-7 necesita una reserva. (3) `EventIdUnicosTests` solo revisa `src/**/*.cs` con `EventId`, así que no ve los números que la acción DTF escriba como enteros en `instalador/` | [V] INST-A:330, RED-A:234; `docs/datos/2026-10-19-ola5-vistas-imp-ddl.md:709`; `tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs:10-24` | Tabla de Q-8 (1.1). A agrega constantes `new EventId(n, "Nombre")` en un archivo de lógica que comparten la acción y las pruebas, o B extiende la prueba a `instalador/**` (0,25 dp, B) |
| HB-07 | Media | **Deriva de la comprobación de carpetas.** Ya hay dos implementaciones en el núcleo, además de `CarpetaAnillo`, la licencia y el conector de IQ. La acción DTF sería la quinta. ADR-129 B.4 nombra el instalador de la API (ADR-77, punto 3) entre lo que debe ir detrás de las costuras (`IComprobacionCarpetas`) | [V] `src/GPOS.AgenteImpresion/Estacion/ComprobacionCarpetas.cs:30`, `src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:30`; `docs/adr/ADR-129.md:33` | La lógica de la acción (`ComprobacionCarpetasPrevias.cs`) se escribe con lo que compila en `net472` y `net10.0`, y se declara como la fuente de la implementación Windows de `IComprobacionCarpetas` cuando A la construya en LN (enero), vinculada en los dos lados. Hasta entonces, el control es el vector v2/v3 en cada implementación. No bloquea |
| HB-08 | Media | INST-A y RED-A dicen «el paso del *bundle* escribe el registro», pero Burn no escribe el registro por sí mismo. Si lo hiciera un componente de un MSI, una reparación o una desinstalación reescribiría o borraría `ModoRed`. Eso contradice PT-06 y la regla de INS 6 de conservar `HKLM\SOFTWARE\GPOS NG` | [I] comportamiento de Windows Installer; [V] INS:242 | Verbo `red` en `GPOS.Migracion` (Q-2 y Q-1). Los MSI solo leen |
| HB-09 | Media | Q-6 de RED-A pide adelantar PR-4, pero la ventana posterior al 11-16 está firmada para ADR-90 | [V] HOJA:72; HPT, sección 5 («Calendario») | F-5 |
| HB-10 | Baja | Q-10 atribuye la clave (cuenta, IP) a D1, pero es de D2 y vive en memoria. Además, `LimitesPeticiones.Ip` también lo usan el emparejamiento y la autenticación de dispositivos | [V] BP3:528, :631, :767 y :1083; `src/GPOS.Api/Endpoints/RestauranteDispositivosEndpoints.cs:33`; `src/GPOS.Api/Seguridad/AutenticacionDispositivo.cs:41` | PR-3 agrega una prueba de que el freno de emparejamiento sigue igual con IPv4 mapeada (la clave ya normaliza, `Contratos.cs:170-178`) |
| HB-11 | Baja | Es probable que el riesgo R-4 de RED-A ya lo cubra el propio marco: `ForwardedHeadersMiddleware` convierte la IPv4 mapeada antes de comparar con los proxies conocidos, y los valores por omisión (127.0.0.0/8 y `::1`) se conservan porque el código solo agrega | [V] el código solo agrega: `src/GPOS.Api/Program.cs:49-54`; [I] el comportamiento del marco | Se conserva la prueba de PR-4 |
| HB-12 | Baja | El crítico de la API de reportes no tiene EventId y se detiene sin código de salida, así que la recuperación del servicio no se dispara | [V] `src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:170-179` | B: 5119 y `ExitCode = 1` (Q-5 de 1.2) |
| HB-13 | Media | Modo híbrido de N-10: en Estricto, la API no arranca si la marca del esquema es menor que la compilada. Por eso, un `requiereTecnico: false` equivocado no corrompe datos, pero **deja el sitio sin servicio** hasta que llegue el técnico. Además, `preparar` mezcla detener (sin SQL) con respaldar (con SQL), y `comprobar-servidor --fase previa` tiene partes con SQL | [V] `src/GPOS.Api/Servicios/Inicializacion.cs:104-108` y `:175`; INS:34 y :122 | Para F-3: `requiereTecnico` lo **deriva la tubería** comparando `EsquemaSistema.Version`, la versión de esquema de empresa, `rpt.VersionContrato` y el contrato de sobres con los de la versión publicada anterior; nunca a mano. Separar `preparar` y las partes con SQL de la comprobación previa |
| HB-14 | Baja | La conexión de PR-1 a PR-3 en `src/GPOS.Web/Program.cs` choca con la zona U de DB-7 (D4, desde el 11-23) | [V] BP3:776-788 | Las partes de la Web de PR-1 a PR-3 se unen antes del 11-20, o esperan a que se una D4 |
| HB-15 | Baja | La recuperación del servicio no se dispara cuando el proceso termina con un código distinto de cero sin la marca de «detenciones con error». El MSI de la estación no la lleva | [V] `instalador/AgenteImpresion/Package.wxs:114-115`; [I] la semántica de SCM y WiX | `FailureActionsWhen` en los MSI de la API, la Web y Reportes (Q-4 de 1.2) |
| HB-16 | Media | **La Web como servicio también usa el anillo** (archivos vinculados, carpeta fija con H-17 v2). Ni INS (que no incluía la Web) ni INST-A dicen qué carpeta del anillo declara `GPOS.Web.msi` ni qué identidad (`NT SERVICE\GPOS.Web`) pone en `GPOS:DataProtection:Anillo:IdentidadServicio` | [V] `src/GPOS.Web/Servicios/ProteccionDatosWeb.cs:74`; `CarpetaAnillo.cs:13-15`; ADR-77, punto 4 | Devops de B lo define en `GPOS.Web.msi`, con su fila en `GposCarpetaPrevia` y la comprobación de arranque de ADR-77, punto 4 |
| HB-17 | Baja | F-2 y F-4 se presentaron como firmas, pero la hoja firmada los clasifica como técnicos | [V] HOJA:485-486 y :495 | Resueltos por B en la sección 1 |
| HB-18 | Baja | INST-A H-7: la hoja firmada asigna a A la lista de privilegios de la API | [V] HOJA:491 y :594 | Q-7 de 1.1 |

**Sin contradicción con la regla de bloqueos (orden único de ADR-45):** ninguna pieza de los dos planos abre transacciones ni toma bloqueos de SQL. El filtro de RT-06 y el selector TLS no tocan la base, y la acción DTF tampoco [V] (RED-A 5.4; INST-A:103).

**Sin contradicción con PT-01 a PT-10 en el resto de RED-A.** El filtro va antes de `UseForwardedHeaders` (PT-05, punto 4). La huella es SHA-256 en el registro, con caché de 5 minutos y orden obligatorio (PT-02). Se rechazan todas las fuentes de direcciones y se comprueban las direcciones efectivas (PT-06). La conexión TCP va a *loopback* con SNI sobre el nombre del sitio (PT-01). Las líneas citadas por A coinciden con `feature/modelo-ng` [V]: `Program.cs:46`, `:49-54`, `:338` y `:349`; `LimitesPeticiones.cs:178`; Web `Program.cs:50`, `:59`, `:62-67`, `:97`, `:100` y `:101`.

---

## 4. Orden recomendado de los PR y cómo no chocar en `Program.cs`

### 4.1 Orden

| Semana | Equipo A (ramas `a/`; B revisa y une) | Equipo B |
|---|---|---|
| Hasta el 10-23 | #103 (DV-07, toma el 4742): B lo revisa primero | Responde con este documento; lleva F-1, F-5 y F-6 a la firma |
| 10-22 a 10-27 | **PR-1a** (`GPOS.Comun/Red`: tipos, `DireccionIp`, `FuenteConfiguracionRed.Windows.cs`, constantes del registro; sin proyecto nuevo). Si F-1 está firmada: **PR-1b** (`GPOS.Comun.Servidor`, `EscuchaServidor`, `EventosRed` y la conexión en la Web) | T4-01; T1-7 y T2-0 adelantados (P-D1-03) |
| 10-26 a 11-04 | **PR-3** (filtro de RT-06 y `LimitesPeticiones.Ip`; **antes del 11-09**). **PR-2** (escucha, selector, `ClienteApiLocal`, H-15) | T4-04 (desde el 10-28); PR pequeño del 5119 (zona R) |
| 10-28 a 11-06 (solo con F-5) | **PR-4** (4 líneas en la API), **después** del PR de N-1 de B | **PR de N-1** (`AddWindowsService`, `AddSystemd` y `ARRANQUE_PRIVILEGIOS` en `GPOS.Api`), primero en la ventana |
| 11-02 en adelante | O-1 y O-3 (con F-1): `instalador/Comun`, el MSI de la estación y el vector v3. El verbo `tls` en `GPOS.Migracion/Tls` | D1 según su plan. Devops: verbo `red`, `comprobar-servidor --fase previa`, `instalador/Api`, `Web` y `Servidor` (con O-1 unido). IQ y AdmCloud (Q-3) |
| Sin F-5, o si no llega | PR-4 **después del 11-20** | N-1 después del 11-20 |

### 4.2 Reglas para no chocar

1. **Un solo dueño del `Program.cs` de la API a la vez**, con estas ventanas:

   | Período | Quién toca el archivo |
   |---|---|
   | 10-22 a 11-06 | T4-01 y T4-04 (líneas sueltas), N-1 y PR-4 |
   | 11-09 y 11-10 | T1-3 (una línea por grupo de rutas) |
   | **11-11 a 11-13** | **T1-5, en exclusiva (zona S congelada)** |
   | 11-16 y 11-17 | Nadie: no se corren suites (medición del banco) |
   | Desde el 11-16 | T4-02 y D2 |
   | Desde el 11-20 | El PR-4 que no haya entrado antes |

2. **PR-4 contiene solo** las 4 líneas, el `using` y la referencia del `.csproj`. Toda la lógica vive en `GPOS.Comun.Servidor` y en `GPOS.Api/Seguridad/FiltroOrigenNodo.cs`, que es un archivo nuevo fuera de la zona S. Así, un rebase cuesta minutos.
3. **Prueba de arquitectura en PR-4**, sobre el texto de `Program.cs`: `UseFiltroOrigenNodo` aparece antes de `UseForwardedHeaders`, y `ExigirArranque` aparece después de `builder.Build()`. Así, el corte de T1-5 o un rebase no puede cambiar el orden en silencio.
4. **La Web** (zona U de DB-7 desde el 11-23): las partes de la Web de PR-1 a PR-3 se unen antes del 11-20 (HB-14).
5. **`src/GPOS.Migracion/Program.cs`** lo tocan T1-4 y T2-0 (del 11-02 al 11-10), además de `red`, `tls`, `implantar-servidor` y `comprobar-servidor`. Los verbos nuevos se registran **en un archivo despachador propio** (por ejemplo, `Servidor/ComandosServidor.cs` y `Tls/ComandosTls.cs`), con una sola línea en `Program.cs`. Quien se une segundo resuelve el conflicto.
6. **Antes de abrir PR-4**, A deja un aviso en `avisos/A-a-B/`. B confirma la ventana y hace la unión (B integra). La suite completa corre sola, con el filtro oficial `Transicion!=Ola5&Transicion!=Defecto`.
7. **Antes de unir cualquier PR que agregue EventId**, se ejecuta `git grep` en todas las ramas de `origin` con la tabla de Q-8 (1.1).

---

## 5. Necesidades para Datos e Integraciones

- **arquitecto-datos:** confirmar, para F-3, la lista de constantes de versión de las que la tubería deriva `requiereTecnico` (HB-13), y que el login de `NT SERVICE\GPOS.Api` se crea después del MSI (HB-01, N-6 de INS).
- **arquitecto-integraciones:** `requiereTecnico` en el manifiesto de ADR-63, derivado y firmado (INST-A Q-6), cuando se diseñe el actualizador.

## 6. Riesgos

| Riesgo | Prob. / impacto | Mitigación |
|---|---|---|
| F-1 no se firma pronto: O-1 no empieza y el *bundle* no se puede firmar | Media / Alto (primera instalación) | PR-1a sin proyecto nuevo; F-1 primera en la hoja |
| PR-4 no llega al 11-06 y cae en la semana más cargada | Media / Bajo | Pasa a después del 11-20 por regla, sin otra firma |
| El nuevo orden de la cadena tiene un efecto de Burn no previsto (reversión, caché) | Media / Medio | Laboratorio P-O1-8 y reversión forzada en cada paso (INS 10) |
| Los atributos de WiX 5 (`Files`, `FailureActionsWhen`, `CustomTable`) no se comportan como se espera | Baja / Bajo | Se comprueba al compilar; hay alternativas en INST-A y en la sección 1 |
| La deriva entre las cinco implementaciones de la comprobación de carpetas | Media / Medio | HB-07; vector v2/v3 en cada una |

## Supuestos

1. «sp» son semanas-persona, y 1 sp = 5 dp.
2. Que una cuenta virtual `NT SERVICE\X` solo se resuelve con el servicio instalado y que `CREATE LOGIN … FROM WINDOWS` la necesita resuelta es [I] (conocimiento de Windows y SQL Server; INS:43 lo afirma para Reportes).
3. Que Burn no escribe el registro sin un paquete; que WiX 5 tiene `Files` y `FailureActionsWhen`; y que `ForwardedHeadersMiddleware` convierte la IPv4 mapeada: todo [I]. Se comprueba al compilar o en el laboratorio.
4. No hay instalaciones de cliente ni de conectores fuera del laboratorio (memoria «todo es desarrollo»; ADR-77:68).
5. Los árboles de trabajo sin confirmar de B no se revisaron para buscar EventId.

## Decisiones candidatas a ADR

1. **Orden de la cadena del *bundle*** (validación previa, `red`, MSI, `tls`, esquema, credenciales, verificar), con el límite de reversión solo sobre los MSI. Es una precisión de ADR-109, cláusula 9 (B-1) y de ADR-90 («Impacto»). *Descartada:* el orden de INS 1.1 (HB-01).
2. **Escritor único del registro `Servidor`: el verbo `red`.** *Descartada:* un componente de un MSI (HB-08). Es una precisión de PT-06.
3. **«Sin modo» solo sin Estricto; fuera de Windows, falla cerrada.** Precisión de RT-01. *Descartadas:* (a) sin condición y (b) de RED-A.
4. **Excepción de proyectos (F-1).** La registra el documentador en `CLAUDE.md` y en ADR-109, cláusula 1.
5. **Reparto de los EventId del 4743 al 4799.** Nota de ADR-82.

Las redacta el Arquitecto Maestro. F-1, F-5 y F-6 van a una hoja de firma; las demás son notas técnicas.

### Cierre
- Estado: Completado
- Artefactos: `docs/arquitectura/2026-10-20-respuestas-b-a-los-planos-de-a.md`
- Supuestos: los cinco de la sección «Supuestos».
- Decisiones candidatas a ADR: las cinco de la sección anterior; precisiones, sin ADR nuevo.
- Entregas a otros agentes:
  - **Arquitecto Maestro:** hoja con F-1, F-5 y F-6 (F-3 después de la revisión del auditor);
  - **equipo A (arquitecto-software y desarrolladores):**
    - PR-1a ya; PR-1b con F-1; PR-3 antes del 11-09;
    - renombres `*.Windows.cs`, «sin modo» con Estricto e `IpNodos` obligatorio (HB-03 a HB-05);
    - `CarpetaAnillo.Crear` (HB-01);
    - lista de privilegios de la API (Q-7);
    - `tls` después de los MSI y con la CA en el servidor;
    - EventId de la tabla de Q-8;
  - **devops de B:** verbo `red`, validación previa, nueva cadena, `FailureActionsWhen`, anillo de la Web (HB-16), recolección con firma obligatoria;
  - **desarrollador de B:** PR de N-1, 5119 en reportes y extensión de `EventIdUnicosTests` (HB-06);
  - **B (conectores):** IQ y AdmCloud (Q-3);
  - **auditor-seguridad:** revisión de N-10 con HB-13 y la alternativa del login de la cuenta virtual; lista de privilegios;
  - **documentador:** nota de EventId en ADR-82, excepciones de F-1 en `CLAUDE.md` y ADR-109 tras la firma;
  - **arquitecto-datos e integraciones:** sección 5.
- Próximo paso recomendado: que el propietario firme «F-1, F-5 y F-6 según la recomendación» antes del 2026-10-28, y que A empiece hoy PR-1a con los EventId del 4743 al 4752.
