# Plan del DEMO con la API de reportes (tarea 3 del aviso de B, riesgo R-2 de T4-06)

**Estado del documento:** Completado (plan de devops; solo lectura, nada construido ni ejecutado). **Autor:** devops de A. **Fecha:** 2026-10-22.
**Hay un hallazgo que cambia el alcance (sección 2.1, D-1): con solo instalar la API de reportes y dar la dirección de reenvío, el DEMO seguiría sin reportes. La principal también tiene que correr como servicio con cuenta virtual. El esfuerzo de la HOJA (2 a 3 dp) no alcanza.**

**Nota de revisión (2026-10-22, rev. 2):** incorpora el dictamen del auditor-seguridad (`traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md`, DM-01 a DM-16) y las respuestas del propietario en chat del mismo día (P-1, P-3, P-4 y P-7 aprobadas; sección 7). Cambios: (a) 2.2 y D-3 corregidos: la DACL protegida va sobre la **clave** `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`, no sobre un «`\Environment`» que es un valor (DM-01); (b) cuatro cerrojos que limitan la excepción K3 al DEMO y su ADR con caducidad (DM-02, 2.2.1); (c) escalera de privilegios SQL (DM-03, 2.2.2); (d) diseño de verbos y scripts de DM-04 a DM-16 (2.2.3 a 2.2.5 y tablas 2.1, 2.3 y 2.4); (e) casos DE-10 a DE-16 (sección 5); (f) esfuerzo total 7,25 a 9,0 dp (antes 6,5 a 8,0; 6.1) y fechas (6.2). Con estos cambios el dictamen pasa de «Rechazado» a «Aprobado con observaciones» [V: dictamen, sección 7]; sigue siendo una recomendación técnica y la firma de la excepción es del propietario (C2).

**Base leída** (solo `git show`, `git grep` y `gh`; sin cambiar de rama, sin compilar, sin ejecutar nada):
- código: `origin/feature/modelo-ng` `b4378650` (incluye #124 `bc05f541`, #136 `d0801fd4`, #146 `b4378650`);
- PR-4 `origin/a/adr90-pr4-cableado-api` (#139, abierto) y T4-01 `origin/b/ola5-t4-01-render` (#152, abierto);
- DEMO publicado: `origin/demo/2026-10-15` `f1d1a650`;
- documentos: blueprint de T4-06 (`traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md`), aviso de B (tarea 3), HOJA A-5 (`docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md:164-179`), INS (`docs/operaciones/2026-10-19-diseno-instalador-reportes.md`), ADR-109 (cl. 1, 8, 12 y nota del tramo 4) y ADR-77 (puntos 1 a 4), casos de C (`traspasos/C/2026-10-22-casos-laboratorio-chromium-y-comprobaciones-paquete.md`).

**Convenciones:** [V] = verificado con `ruta:línea`; [I] = inferido; [?] = se desconoce y hay que probarlo. dp = días-persona con agente. Toda cifra de esfuerzo es [I], ±40 %. Rutas de código relativas a `GPOS-NG`; las de scripts, a la misma raíz y a `origin/feature/modelo-ng` `b4378650`.

---

## 1. Inventario: qué arranca la principal en Release y exige o prohíbe la dirección de reenvío

Regla de T4-06 (Q-6): en Release, sin `GPOS:Reportes:Reenvio:Direccion` la principal lanza `InvalidOperationException` al registrar el reenvío. **Hoy esa regla no existe en el código** [V: `src/GPOS.Api/Endpoints/ReenvioReportes.cs:27-41` solo valida la dirección si `Habilitado`; no hay `ValidarModo` ni `CompilacionDepuracion`]. La agrega T4-06 (blueprint 7.1, TA-3) [I: pendiente].

| # | Qué | Evidencia | ¿Exige o prohíbe la dirección? | Efecto con T4-06 [I] |
|---|---|---|---|---|
| 1 | **Paquete del DEMO** (`Publicar-PaqueteDemo.ps1`) | No publica `GPOS.Reportes.Api` (`:89-92`, solo api, web, migracion, maui); `IncluyeApiReportes = $false` (`:118`); **prohíbe** la dirección en `app\api\appsettings.json` (`:129-135`) | Prohíbe | El paquete se arma, pero no arranca (filas 2 y 3) |
| 2 | **Scripts del DEMO** (`Iniciar-Demo.ps1`, `Instalar-Demo.ps1`, `Comun-Demo.ps1`) | `Entorno-Api` no pone la dirección (`Comun-Demo.ps1:341-358`); la principal se lanza como proceso de consola del usuario (`Iniciar-ProcesoOculto`, `:314-331`; `Iniciar-Demo.ps1:63-72`); el primer arranque del paso 5 igual (`Instalar-Demo.ps1:147-168`) | No la pone | La principal no arranca: `Esperar-Url /api/salud` agota los 120 s y los scripts abortan (`Iniciar-Demo.ps1:67-71`; `Instalar-Demo.ps1:156-162`) |
| 3 | **LEEME del DEMO** | `LEEME.md:19` («no se instalan servicios»), `:63-64` (DM-10) y `:69-71` (aviso `crit ServidorIntrospeccion` «esperado») | — | Documentación falsa |
| 4 | **¿Qué DEMO se publica hoy?** | Los paquetes salen de `demo/2026-10-15` (anterior al #42, por la licencia s1 pendiente): `Instalar-Demo.ps1:17-19`; commit `f1d1a650` «los paquetes salen de demo/2026-10-15» | — | **Los paquetes ya publicados no cambian** (son binarios autocontenidos con su configuración). La rama `demo/*` no tiene Q-6 (Q-6 aún no existe). El riesgo es **la próxima publicación desde `feature/modelo-ng`** |
| 5 | **Ensayo corto** (`tests/GPOS.EnsayoImplantacion/iniciar-api.ps1`) | `:36` arranca `src\GPOS.Api\bin\Release\net10.0\GPOS.Api.dll` con `ASPNETCORE_ENVIRONMENT=Production` (`:22`) y sin dirección; `README.md:17-18` manda compilar con `-c Release` | No la pone | No arranca. Arreglo: Debug (sección 3.3) |
| 6 | **Laboratorio de ADR-90** (#146, unido) | `tests/laboratorio-adr090/LEEME.md`: solo los guiones del **anfitrión** (VirtualBox); los guiones que corren dentro de las VM están «fuera de este PR» y sin escribir | — | Sin impacto hoy. [I] Los guiones de dentro de la VM, cuando existan, deben instalar la principal con la API de reportes (mismos verbos) |
| 7 | **Instalador** (#124, unido en `bc05f541`) | `instalador/Comun/GPOS.Instalador.Acciones` (O-1 y O-3) y `instalador/AgenteImpresion`. **No existe MSI de la principal, ni de reportes, ni *bundle***: `instalador/Reportes` no está en ninguna rama remota [V: recorrí `git ls-tree` de todas] | — | Sin impacto: ningún instalador arranca la principal |
| 8 | **Pruebas** | La suite compila Debug, donde no se exige la dirección. `ReportesF9Tests.cs:52` y `ReenvioReportesSeguridadTests.cs:28` ya la fijan (Debug) | Fijan | Sin impacto, salvo `ValoresDeTercerosTests.cs:92` (lista de permitidos de `Publicar-PaqueteDemo.ps1`: un valor literal nuevo en los scripts exige entrada nueva) |
| 9 | **`ModoServicioApi`** (N-1, #136) | Define que **consola** = «desarrollo, DEMO, pruebas» sin comprobar identidad (`src/GPOS.Api/Servicio/ModoServicioApi.cs:11-14`, `:125-141`) | — | Ver D-1 |

### 2.1 Hallazgo D-1 (Alta para el plan): la dirección sola no devuelve los reportes al DEMO

En Release, la introspección de la principal exige identidad exclusiva:
- `ServiciosIntrospeccion.ModoDesarrollo` es `false` en Release sin importar `ASPNETCORE_ENVIRONMENT` (`src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs:109-117`) [V];
- `ServidorIntrospeccion.ComprobarCuentas` rechaza a la principal si no corre como `NT SERVICE\<servicio>` (`src/GPOS.Comun/Introspeccion/ServidorIntrospeccion.cs:96-112`) y rechaza al cliente si no es una cuenta virtual `S-1-5-80-*` (`:106-109`) [V];
- si lo rechaza, deja un evento crítico, **la principal sigue y la API de reportes responde 503** (`src/GPOS.Comun/Introspeccion/LEEME-enganche-principal.md:88`) [V]. Es la línea `crit ... ServidorIntrospeccion` que el LEEME del DEMO llama «esperada» (`LEEME.md:69-71`);
- la API de reportes, fuera de desarrollo, exige `GPOS:Introspeccion:CuentaServidor` con el SID `S-1-5-80-*` de la principal (`src/GPOS.Reportes.Api/Program.cs:29-31`; `appsettings.json:19`) y no arranca sin él [V].

**Consecuencia:** para que el DEMO muestre reportes (y luego imprima, con T4-02), **la principal del DEMO tiene que correr como servicio `NT SERVICE\GPOS.Api`** y la de reportes como `NT SERVICE\GPOS.Reportes`. El DEMO deja de ser «solo procesos del usuario, sin elevación» y se parece mucho al servidor de cliente. La HOJA A-5 lo describe como «dos servicios con elevación» (`hoja:172`), pero no mide lo que eso arrastra (D-2 a D-6).

| # | Arrastre | Evidencia | Estado |
|---|---|---|---|
| D-2 | **Datos de la principal bajo una cuenta virtual.** Hoy el DEMO entra a SQL con la cuenta de Windows de quien instaló, en modo Amplio, y la API «al iniciar actualiza GPOS_SYSDATA» (`Iniciar-Demo.ps1:12-13`; `Instalar-Demo.ps1:128-130`). Una cuenta virtual no es `sysadmin` ni `dbcreator`: necesita su inicio de sesión y sus permisos (`sistema --login-api "NT SERVICE\GPOS.Api"`, `aprovisionar`, `login-servicio`: `src/GPOS.Migracion/Program.cs:13-20`, `:502`) y el esquema lo debe migrar `GPOS.Migracion`, no la API | INS N-6 (orden de S0, `sistema` y empresas, sin confirmar) | [?] **Es la mayor incertidumbre**: no sé si la principal en Amplio con `NT SERVICE\GPOS.Api` arranca y atiende. Spike 1 (sección 6) |
| D-3 | **Clave JWT sin canal seguro.** La principal exige `Jwt:Clave` de ≥ 32 caracteres desde la configuración (`src/GPOS.Api/Program.cs:67`; `Seguridad.cs:14-22`, HS256). El DEMO la pasa por entorno del proceso (`Comun-Demo.ps1:350`) y la guarda con DPAPI del usuario (`config\secretos.dpapi`). Un servicio no puede leer DPAPI del usuario. El archivo de instalación solo admite `GPOS:RncDgii` (`ArchivoInstalacion.cs:27`) | INS 3.2, 7 y K3 («sin secretos en variables de entorno de los servicios») | **Rev. 2:** P-3 aprobada por el propietario según la recomendación (opción a, entorno del servicio con DACL protegida **sobre la clave del servicio**, solo DEMO), sujeta al dictamen (DM-01 a DM-06, DM-15) y a la firma de la excepción con caducidad, aún pendiente. Diseño en 2.2 y 2.2.1 |
| D-4 | **Data Protection bajo una cuenta virtual.** El DEMO usa `DpapiDemo = true` (DPAPI del usuario) (`Comun-Demo.ps1:349`; `ProteccionDatosInstalacion.cs:73-80`). Release sin certificado de anillo solo admite eso | [?] no sé si DPAPI de usuario funciona con el perfil de una cuenta virtual. Spike 1 |
| D-5 | **Binarios de un servicio en una carpeta escribible por el usuario.** El DEMO se extrae en una carpeta del usuario (`LEEME.md:23`). Un servicio que ejecuta un `.exe` que el usuario puede reemplazar es una escalada de privilegios | [I] Los servicios deben vivir en `%ProgramFiles%\GPOS NG\Demo\` (ACL de administradores). Cada actualización del DEMO pasa a exigir elevación |
| D-6 | **Modo de red de PR-4 (#139).** Con PR-4, la escucha de la principal sale de `HKLM\SOFTWARE\GPOS NG\Servidor` (verbo `red`) y `FijarEscuchaPorOmision` (transitorio, `ModoServicioApi.cs:69-81`) desaparece | [?] Qué hace una principal-servicio sin esos valores. [I] El DEMO tendrá que ejecutar `GPOS.Migracion red` en modo «un equipo». Pregunta P-6 |

---

## 2. Diseño del DEMO con la API de reportes

### 2.1 Qué se instala y arranca

| Pieza | Valor propuesto | Origen |
|---|---|---|
| Servicio `GPOS.Reportes` | Cuenta `NT SERVICE\GPOS.Reportes` (virtual, sin contraseña, tipo de SID sin restricción); `SeChangeNotifyPrivilege` como único privilegio (sin `SeImpersonatePrivilege`); inicio **manual** (el DEMO se arranca a mano, como hoy, `LEEME.md:19`); recuperación de 1 min, 3 veces, **solo con acciones de reinicio** (`sc failure` sin `command=`; DM-14). Binarios en `%ProgramFiles%\GPOS NG\Demo\reportes\` | INS 2.1; ADR-76 PA-76-1; D-5 |
| Servicio `GPOS.Api` | Cuenta `NT SERVICE\GPOS.Api`; argumento `--servicio` (`ModoServicioApi.ArgumentoServicio`, `:41`); único privilegio `SeChangeNotifyPrivilege` (`:19`). Binarios en `%ProgramFiles%\GPOS NG\Demo\api\` | `ModoServicioApi.cs:19`, `:41`; D-5 |
| `GPOS.Web` y MAUI | **Siguen como procesos del usuario**, en la carpeta del DEMO (N-4 del INS: la Web no es servicio) | `Comun-Demo.ps1:371-384` |
| Puertos | 5071 (API), 5054 (Web), **5073 (reportes, solo loopback)**; todos solo en el propio equipo. `Test-PuertoOcupado` también para 5073 | `appsettings.json` de reportes `Urls`; `LEEME.md:16` |
| Canalizaciones | `GPOS.Api.Introspeccion` (dueña: la principal; cliente: `NT SERVICE\GPOS.Reportes`, Deny a NETWORK) y `GPOS.Reportes.Exportacion` (dueña: reportes; cliente: la principal). Las crean los propios servicios con su ACL; el DEMO **no las toca** | `ServidorIntrospeccion.cs:114-123`; `ServiciosReportes.cs:98-135` |
| Carpetas | Raíz `%ProgramData%\GPOS NG` con la DACL de ADR-77 punto 1 (`O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)`), creada **en una sola operación con su DACL** por el paso elevado (punto 2); `\Reportes` con `0x1301bf` para `NT SERVICE\GPOS.Reportes` y sin herencia (INS 2.1); `\Reportes\temp` lo crea el servicio (P-77-4) y se valida al arrancar (`Program.cs:75-83`); `\Api` para la principal, con `\Api\anillo`, `\Api\registros` (lectura para administradores) y `\Api\temp`; **ninguna ruta del entorno de los servicios cae bajo el perfil del usuario** (DM-10). La acción previa de ADR-77 punto 3 es de MSI (#124); para el DEMO la hace `implantar-servidor` (C#, mismos vectores), no PowerShell | ADR-77 pts. 1 a 4; INS 2.1 y 2.2 |
| Anillo y licencia | Hoy el anillo está en `datos\llaves-api` del DEMO y la licencia en `%ProgramData%\GPOS NG\Licencia` (`Instalar-Demo.ps1:134-135`). Un servicio no lee `datos\` del usuario: el anillo pasa a `%ProgramData%\GPOS NG\Api\anillo` (ACL de ADR-77 punto 4: lectores solo SYSTEM, administradores y la identidad del proceso). **Rev. 2 (DM-07): en el DEMO con servicios el anillo usa certificado (H-17 v2)**: certificado en `LocalMachine\My`, llave privada con ACL SYSTEM + administradores + `NT SERVICE\GPOS.Api` (`ProteccionDatosInstalacion.cs:63-69` [V dictamen]), anclado con `anillo --anclar` (`Program.cs:16`) por `implantar-servidor`, **sin `DpapiDemo` y sin `DpapiMaquina`**. Motivo: `GPOS.Migracion` (administrador) y la API (cuenta virtual) comparten el anillo y con DPAPI de usuario no pueden abrirse entre sí (`Comun-Demo.ps1:360-367`, `ComandoSistema.cs:36`) [V dictamen]. Cierra D-4. `GPOS.Web` sigue con `DpapiDemo` como proceso del usuario. Alternativa descartada: ejecutar `GPOS.Migracion` bajo la cuenta virtual (tarea programada o servicio temporal; más superficie) | ADR-77 pt. 4; DM-07 |
| Chromium (T4-01, #152) | Lo toma de Edge o Chrome instalados (`ServicioRender`: `Candidatos()`, `GPOS:Reportes:Render:Navegador`) [V en el diff del #152]. Windows 10/11 trae Edge [I]. **El perfil va a `Path.GetTempPath()\gpos-pdf-navegador\<id>`** [V en el diff]: [?] para una cuenta virtual ese TEMP puede no ser escribible (CH-02 de C). Se pide a B/T4-01 mover el perfil a `%ProgramData%\GPOS NG\Reportes\render` (P-CH-2 de C; P-7 aprobada). **Condiciones de DM-11 (rev. 2):** (i) DACL heredada de `\Reportes`, protegida y **sin lectura para usuarios autenticados**: `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Reportes>)`; (ii) al arrancar, comprobar que `render` no es punto de reanálisis y su dueño; (iii) subcarpeta por arranque con nombre **aleatorio de 128 bits** (no 8 hex); (iv) borrarla al cerrar el navegador y purgar restos al iniciar (hoy el perfil **nunca se borra** [V dictamen, DM-11]); (v) defensa sin código: `TMP` y `TEMP` del servicio fijados a `%ProgramData%\GPOS NG\Reportes\temp` y, para la principal, a `%ProgramData%\GPOS NG\Api\temp` (cubre también `gpos-rnc-*`). El filtro de salida de Chromium (solo `data:`/`about:` y recursos embebidos) es de T4-01; en el DEMO queda como AVISO R7 (DM-12). Nunca `--no-sandbox` | Casos CH-01 a CH-06 de C; DM-11, DM-12 |
| QuestPDF | En proceso dentro de `GPOS.Reportes.Api` (paquete `QuestPDF 2026.9.0`, #152); no instala nada aparte. El `.7z` crece lo que pese un `GPOS.Reportes.Api` autocontenido [I: de 80 a 120 MB, INS 8] | #152 |
| Cortafuegos | **No se agrega regla en el DEMO.** Solo loopback, sin regla de entrada; `comprobar-servidor` (R4) verifica que 5071 y 5073 escuchan **solo** en `127.0.0.1`/`::1` (nunca `0.0.0.0`, `[::]` ni `+`), también con PR-4 y `red --modo un-equipo` (DM-12). La regla de salida por servicio está sin resolver en el INS (O-5: WiX no la expone, «inferido») y el DEMO no es el lugar para resolverla. Queda como AVISO documentado en R7 | INS O-5, R7 |
| Memoria | +300 a 550 MB por la API de reportes (ADR-109) y la principal ya no es proceso oculto sino servicio; los 8 GB recomendados (`LEEME.md:15`) se mantienen [I] | ADR-109 |
| Marca `Configurado` | **No usarla**: no existe en el código [V: `git grep Configurado` sin resultados en `src/GPOS.Reportes.Api`, `GPOS.Comun`, `GPOS.Reportes`]. Es diseño del INS. Reportes arranca sin ella | INS 3.1 pasos 4 y 5 |
| Evento de origen | Los orígenes `GPOS.Api` y `GPOS.Reportes` los declara el MSI; sin MSI, el paso elevado debe registrarlos (`RegistroEventosReserva.OrigenRegistrado`, `ModoServicioApi.cs:218-220`: la cuenta virtual no puede crearlos). Si no, los eventos de arranque rechazado no llegan al Visor | `ModoServicioApi.cs:206-224` [V parcial]. **P-11 resuelta en el dictamen (DM-13):** sí, la fase elevada registra `GPOS.Api` y `GPOS.Reportes`; `EventMessageFile` apunta a una DLL en ruta protegida (la del marco de .NET en `%WINDIR%` o una copia en `Program Files`), **nunca** a la carpeta del usuario; la desinstalación puede conservarlos o quitarlos |

### 2.2 Cómo se configura la dirección de reenvío

- **No va en `appsettings.json` del paquete.** La comprobación de `Publicar-PaqueteDemo.ps1:129-135` **se conserva tal cual**, solo cambia su texto: la dirección la pone el instalador del equipo, no el paquete.
- La pone `implantar-servidor` en el entorno del **servicio** `GPOS.Api`: el **valor** `Environment` (`REG_MULTI_SZ`) de la clave `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api` (no es una subclave; rev. 2, DM-01), con `GPOS__Reportes__Reenvio__Direccion=http://localhost:5073` (mismo mecanismo que INS 2.1, fila «Entorno»). Es una variable, no un secreto.
- `GPOS__Introspeccion__CuentaCliente` **no se configura**: el valor por omisión es `NT SERVICE\GPOS.Reportes` (`LEEME-enganche-principal.md:89`).
- En la API de reportes: `urls=http://localhost:5073`, `GPOS__Introspeccion__CuentaServidor=<SID de NT SERVICE\GPOS.Api>` (obtenido de la identidad real, no del nombre: `LEEME-enganche-principal.md:90`; el SID no es secreto), `GPOS__Reportes__Sistema__Servidor` y `__BaseDatos`, `GPOS__Reportes__Lectura__Sitio` y `__Servidores__0` (INS 2.1).
- **La clave JWT** (D-3, P-3 aprobada con la opción a): va en el mismo valor `Environment` como `Jwt__Clave`, **protegida por la DACL de la clave entera del servicio**, no del valor (rev. 2, DM-01):
  - SDDL: `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`, es decir dueño SYSTEM, **protegida** (sin herencia), solo SYSTEM y administradores. Sin `Users`, `Authenticated Users`, `CREATOR OWNER`, `ALL APPLICATION PACKAGES` ni la cuenta del propio servicio (el Administrador de servicios lee el entorno como SYSTEM; la principal no necesita leer su clave) [I: confirmar en el spike que arranca]. La DACL por omisión de las claves de servicio concede lectura a `BUILTIN\Users` [I: confirmar con `Get-Acl` en el spike], de ahí el orden.
  - **Orden obligatorio** en `--fase servicios`: crear el servicio → aplicar la DACL protegida → **comprobarla** → solo entonces escribir el valor `Environment` (con la clave). Nunca al revés (ventana de lectura).
  - `comprobar-servidor` revisa la DACL en cada `Iniciar-Demo` (una actualización en el lugar de Windows puede rehacer claves de servicio [I]): con `Jwt__Clave` presente y una ACE de lectura para cualquier otro SID → **FALLA** (código 4). Si se restringe una subclave, la comprobación también debe fallar: importa quién puede leer el *valor*.
  - Es una excepción al K3 del INS que solo sirve para el DEMO (modo Amplio, no se entrega a clientes, `Publicar-PaqueteDemo.ps1:19-22`), limitada por los cuatro cerrojos de 2.2.1 y registrada en un ADR con caducidad.
- Q-6 queda cumplida porque el servicio siempre tiene dirección; `ValidarModo` no cambia.

#### 2.2.1 Cuatro cerrojos que limitan la excepción K3 al DEMO (DM-02, Alta)

Hoy nada impide reutilizar la excepción copiando el verbo; el ancla existente es que Amplio no arranca con licencia de producción o beta (`Inicializacion.cs:94-98`) [V dictamen]. Se exigen los cuatro (defensa en profundidad):

| # | Cerrojo | Qué hace | Prueba | Dónde |
|---|---|---|---|---|
| 1 | **Verbo** | `implantar-servidor` escribe `Jwt__Clave` **solo** con `--perfil demo` **y** `GPOS__Seguridad__ModoIdentidad=Amplio` en ese mismo entorno; con otro perfil el código que la escribe no es alcanzable | Prueba de arquitectura: el literal `Jwt__Clave` aparece en un único método, el del perfil demo | PR-V |
| 2 | **API** | Al arrancar como servicio, si `Jwt__Clave` está en el entorno del proceso y el modo **no** es Amplio, no arranca (evento 4767, sin el valor) | Arranque en Estricto con `Jwt__Clave` → no arranca | PR pequeño de la API (~0,25 dp con DM-04) |
| 3 | **Publicación** | `Publicar-PaqueteDemo.ps1 -Destino Cliente` ya rechaza Amplio en guiones y configuración (`:60-62`, `:139-141`) [V dictamen]; se añade el rechazo textual de `Jwt__Clave` en los guiones del paquete de cliente | Prueba textual de Publicar | PR-D2 |
| 4 | **Comprobación** | `comprobar-servidor` con perfil distinto de `demo` → **FALLA** si `Jwt__Clave` (o cualquier nombre con `Clave`, `Password`, `Secret`, o una cadena con `Password=`) está en el entorno de un servicio (K3 tal cual) | `comprobar-servidor` con perfil no demo → FALLA | PR-V |

- **ADR con caducidad:** la excepción se registra en un ADR (candidato 2 del Cierre) que **caduca** cuando exista ES256 (ADR-41) o la opción (c) (archivo protegido `%ProgramData%\GPOS NG\Api\secretos\` leído con `KeyPerFile`, ~0,5 a 1 dp [I]). Criterio del auditor (C13.3): si la versión de cliente necesita un canal antes de ES256, debe ser (c), no (a). Alternativas descartadas: (b) esperar ES256 (no llega antes de D4, ADR-41 «decidido, no implementado») y (c) para el DEMO (+~0,5 dp y el propietario eligió (a)).
- R8 queda como **AVISO conocido** que nombra la variable, nunca su valor, un fragmento ni un hash corto (DM-15); se suma la comprobación de DACL, que sí es FALLA.

#### 2.2.2 Privilegios SQL de `NT SERVICE\GPOS.Api` (DM-03, Alta; D-2)

En Amplio la principal hace DDL al arrancar (`Inicializacion.cs:94-103`) y un endpoint puede ejecutar `CREATE DATABASE` (`AdminEndpoints.cs:319-320`; `EsquemaEmpresa.cs:216`); S1 lanza 51606 si el login de la API es dueño de la base (`PrivilegioMinimoSistema.cs:151`) [V dictamen]. Escalera, **en este orden y midiendo en el spike la primera que funcione**:

1. **Preferida:** esquema y bases por `GPOS.Migracion` con la cuenta del administrador (`--fase esquema`) y `sistema --login-api "NT SERVICE\GPOS.Api"` (rol `gpos_api` con sus DENY). Medir si Amplio arranca así (lo que no tiene permiso, ¿falla o avisa?).
2. Si Amplio exige DDL al arrancar: `db_owner` **solo** en `GPOS_SYSDATA` y en las bases `GPOS_*` del DEMO (anula los DENY de S1, `PrivilegioMinimoSistema.cs:14`; aceptado en Amplio). Las bases siguen con dueño `sa` (S1, D-03).
3. `dbcreator` **solo** si el DEMO necesita crear empresas desde la interfaz; si no, las crea el script.
4. **Prohibido** `sysadmin`, `CONTROL SERVER`, `securityadmin`, `serveradmin`, `ALTER ANY LOGIN` e `IMPERSONATE`. Si el spike solo funciona con alguno, es **FALLA** del spike y se escala; no se «arregla» ni se prueba «para ver si arranca».

- **`TRUSTWORTHY OFF`:** con `db_owner` + dueño `sa`, una base con `TRUSTWORTHY ON` permite escalar a `sysadmin` [I]. `comprobar-servidor` comprueba `is_trustworthy_on = 0` en `GPOS_SYSDATA` y en todas las `GPOS_*` (FALLA si no) y que el login no tenga roles de servidor (DE-14).
- El login es solo de Windows, local, sin login SQL ni contraseña: **no se usa `login-servicio` en el DEMO**.
- El verbo concede exactamente el nivel medido en el spike y nada por encima de `db_owner` por base.

#### 2.2.3 Generación, ciclo de vida y herencia de la clave (DM-04, DM-05, DM-06)

- **Generación (DM-05):** en el verbo C#, con `RandomNumberGenerator` (válido en FIPS), **48 bytes** → 64 caracteres Base64 (como hoy, `Instalar-Demo.ps1:101`). Nunca desde texto elegido por una persona (la validación de la API mide caracteres, no entropía). Se escribe con `Microsoft.Win32.Registry` desde el mismo proceso. **Prohibido** pasar el valor por la línea de comandos (`reg.exe`, `sc`, argumentos del verbo; queda en el evento 4688) o como parámetro de un cmdlet de PowerShell (registro de módulos 4103) [I]. No va en `version.json`, `config\`, el archivo de instalación, la salida del verbo ni la evidencia: `Recoger-Evidencia.ps1` vuelca solo nombres y **está prohibido `reg query`/`reg export` de la clave del servicio**. El paquete sigue sin clave (`Publicar:127`).
- **Única por instalación (DM-06):** se genera en cada `Instalar-Demo` (fase servicios); nunca se reutiliza la de `config\secretos.dpapi` del modo consola.
- **Rotación:** en cada reinstalación (obligatoria) y con `implantar-servidor --perfil demo --rotar-jwt` (tras una demostración en equipo ajeno o sospecha de exposición); la actualización normal **no** rota. Invalida los tokens vigentes (12 h por omisión), lo deseado.
- **Desinstalación:** detener el servicio → **borrar el valor `Environment`** → `sc delete` → comprobar que la clave del servicio ya no existe; si queda marcada para eliminación (error 1072), avisar que hace falta reiniciar. Copias en registros de transacciones e instantáneas VSS: riesgo residual aceptado (DM-16).
- **Clones:** **prohibido distribuir una imagen con el DEMO ya instalado**; tras clonar una VM, `--rotar-jwt`.
- **Herencia a hijos (DM-04):** la principal **borra `Jwt__Clave` de su entorno de proceso** justo después de construir la configuración (una línea; el valor ya está en `JwtOpciones`), con prueba, para que Chromium y sus procesos de render no la hereden. Es el cerrojo 2 compartido en el mismo PR de la API; válido también para el modo consola.
- **Riesgo residual (DM-16, aceptado):** con (a) leen la clave SYSTEM, administradores, Operadores de copia, copias del subárbol y volcados de memoria; todos ya controlan la máquina.

#### 2.2.4 SDDL de los servicios, carpetas del usuario y privilegios (DM-09, DM-10, DM-14)

- **SDDL de cada servicio** (`sc sdset`): conceder al **SID del usuario que instala** (no a `IU`, `AU` ni `BU`) solo `SERVICE_START` (RP), `SERVICE_STOP` (WP), `SERVICE_QUERY_STATUS` (LC), `SERVICE_INTERROGATE` (LO), `SERVICE_QUERY_CONFIG` (CC) y `READ_CONTROL` (RC). **Nunca** `SERVICE_CHANGE_CONFIG` (DC), `WRITE_DAC` (WD), `WRITE_OWNER` (WO) ni `DELETE` (SD): con DC se cambia la cuenta o el binario del servicio. `comprobar-servidor` lo verifica con `sc sdshow` (DE-05 ampliado: puede iniciar y detener, **no** reconfigurar; DE-11).
- **Nada de la carpeta del usuario:** archivo de instalación en `%ProgramData%\GPOS NG\config` (ADR-77), anillo en `Api\anillo`, registros en `Api\registros`; DE-06 se amplía a «ninguna ruta del entorno de los servicios cae bajo el perfil del usuario».
- **Privilegios:** `SeChangeNotifyPrivilege` como único (R1); sin `SeImpersonatePrivilege`; `sc failure` solo con reinicio; inicio manual.

#### 2.2.5 Binarios en `Program Files` (DM-08, D-5)

- Si `GPOS NG` o `Demo` ya existen: comprobar dueño (SYSTEM, administradores o TrustedInstaller), que no sean punto de reanálisis y que ningún SID ajeno tenga escritura; si no, **abortar** (criterio de ADR-77 punto 3). Nunca «arreglar» la ACL de una carpeta ajena.
- La copia la hace el proceso elevado y la **verificación de huellas (SHA-256 por archivo, manifiesto de `Publicar`) se hace en el destino**, no en la carpeta extraída del usuario (que puede cambiar entre la verificación y la copia).
- La copia previa para la reversión va a `%ProgramFiles%\GPOS NG\Demo\.anterior` o a `%ProgramData%\GPOS NG\Demo\anterior`, con ACL solo SYSTEM + administradores; **nunca** a la carpeta del usuario (restaurar desde allí plantaría binarios).
- `appsettings.json` de los servicios en `Program Files` (solo administradores escriben).

### 2.3 Cómo se usan los verbos N-3

Hoy **no existen** `implantar-servidor` ni `comprobar-servidor` [V: `git grep` en `origin/feature/modelo-ng` y `origin/a/instalador-o1-o3`, sin resultados]. Existen las piezas: `llave-sitio`, `crear-lectura-sistema`, `crear-lectura`, `rotar-lectura`, `sistema --login-api`, `login-servicio`, `credencial-app`, `aprovisionar`, `verificar` (`Program.cs:13-20`, `:499-520`) [V]. Los verbos las componen; el DEMO los llama como el *bundle* futuro.

| Verbo | Qué hace en el DEMO | Elevación |
|---|---|---|
| `implantar-servidor --perfil demo --fase carpetas` | Crea la raíz de ProgramData con la DACL de ADR-77 y las carpetas de `\Api` y `\Reportes` (punto 3: rechaza uniones o dueños ajenos) | Sí |
| `implantar-servidor --perfil demo --fase servicios` | Comprueba la carpeta de destino y verifica huellas en el destino (2.2.5); copia los binarios a `%ProgramFiles%\GPOS NG\Demo\` (con copia previa protegida); `sc create` con `obj= "NT SERVICE\<nombre>"`, `sc privs`, `sc failure` (solo reinicio); **DACL protegida de la clave del servicio → comprobarla → generar la clave (48 bytes, CSPRNG, en C#) y escribir `Environment`** (2.2, 2.2.3; solo con `--perfil demo` y Amplio, cerrojo 1); `TMP`/`TEMP` de los servicios (DM-11); origen de eventos (`EventMessageFile` en ruta protegida, DM-13); SDDL de los servicios para el usuario que instala (2.2.4). Opción `--rotar-jwt` (rotación; DM-06) | Sí |
| `implantar-servidor --perfil demo --fase esquema` | `sistema --login-api` (escalera de 2.2.2; sin roles de servidor, `TRUSTWORTHY OFF`), `actualizar` de la empresa (con `crear` en una instalación nueva) y vistas `rpt`; anclaje del certificado del anillo (`anillo --anclar`, DM-07) | Cuenta de Windows con `sysadmin` o `dbcreator` (como hoy) |
| `implantar-servidor --perfil demo --fase lectura` | `crear-lectura-sistema --cuenta "NT SERVICE\GPOS.Reportes"`, `llave-sitio` (almacén de máquina, ACL a la cuenta), `crear-lectura --todas`, `red` (modo un equipo, P-6) | Sí (almacén de máquina) |
| `comprobar-servidor --perfil demo` | R1 a R6, R8 y R10, P1, P4 a P6, P8 y K3 (sección 5); además, rev. 2: DACL de la clave del servicio (DM-01), cerrojo 4 (2.2.1), `is_trustworthy_on = 0` y roles de servidor vacíos (DM-03), SDDL de los servicios (DM-09), loopback (DM-12), rutas fuera del perfil del usuario (DM-10); códigos de salida 0 / 2 (avisos) / 4 (crítico) | Solo lectura; el sondeo de `sc qprivs` y `icacls` puede pedir elevación |

**Quién lo escribe:** el código de los verbos es de `GPOS.Migracion` (arquitecto-software de A y desarrollador; 0,30 sp del INS ≈ 1,5 dp [I], con 1 sp = 5 dp, más 0,5 a 0,75 dp de rev. 2). El cambio en `GPOS.Api` (cerrojo 2 y borrado de `Jwt__Clave` del entorno, DM-04) es un PR pequeño del desarrollador de la API (~0,25 dp). El perfil de Chromium (DM-11) es de B en T4-01. Devops escribe los scripts que los llaman. Orden de PR en 3.2.

### 2.4 Cambios de scripts (rutas:líneas en `feature/modelo-ng` `b4378650`)

| Archivo | Líneas | Cambio |
|---|---|---|
| `instalador/Demo/Publicar-PaqueteDemo.ps1` | `:30-40` (parámetros) | Agregar `[switch]$ConApiReportes` |
| ídem | `:89-92` | Con la bandera: `Publicar 'src\GPOS.Reportes.Api\GPOS.Reportes.Api.csproj' 'reportes' $autocontenido` |
| ídem | `:8-13` (encabezado) y `:118` | Texto de DM-10 actualizado; `IncluyeApiReportes = [bool]$ConApiReportes` (el campo ya existe) |
| ídem | `:128-135` | Se conserva la prohibición de la dirección en el `appsettings.json` publicado; cambia solo el comentario y el mensaje |
| ídem | tras `:63` y `:118` | **Guarda de coherencia** (3.2): árbol con Q-6 y sin `-ConApiReportes` → `throw`; `-ConApiReportes` sin el proyecto en el árbol → `throw` |
| ídem | tras `:127` y `:139-141` | Rev. 2 (cerrojo 3, DM-02): con `-Destino Cliente`, rechazo textual de `Jwt__Clave` en los guiones del paquete |
| ídem | `:124-125` | `Comprobar-PublicacionRelease.ps1 -Ruta app` ya recorre todas las carpetas; verificar que incluye `app\reportes` y que no aparecen `*.Tests.dll` |
| `instalador/Demo/scripts/herramientas/Comun-Demo.ps1` | `:333-339` | `Get-ProcesosDemo` agrega `GPOS.Reportes.Api` y deja de filtrar por la carpeta del DEMO cuando son servicios (la ruta es `Program Files`); agregar `Get-ModoDemo`, `Test-Elevado`, `Iniciar-ServiciosDemo`, `Detener-ServiciosDemo` (`Start-Service`/`Stop-Service` + espera de `/api/salud` en 5071 y 5073) |
| ídem | `:341-358`, `:360-369` | `Entorno-Api` sigue para el modo consola (paquetes de `demo/*`); nuevo `Entorno-Servicio-Api` y `Entorno-Servicio-Reportes` (2.2), que `implantar-servidor` escribe en el registro |
| `instalador/Demo/scripts/Instalar-Demo.ps1` | `:6`, `:72-75`, `:85-87`, `:147-168` | Encabezado con los dos modos; si `IncluyeApiReportes` es true: **exige elevación** (hoy avisa lo contrario en `:72-75`), comprueba también el puerto 5073, y reemplaza los pasos 2 (JWT) y 5 (primer arranque por proceso) por las fases de `implantar-servidor`. El primer arranque pasa a ser un `Start-Service GPOS.Api` |
| `instalador/Demo/scripts/Iniciar-Demo.ps1` | `:9-11`, `:63-77` | Con servicios: `Iniciar-ServiciosDemo` + `comprobar-servidor`; la Web y MAUI como hoy. El aviso de DM-10 (`:73-77`) solo en modo consola |
| `instalador/Demo/scripts/Detener-Demo.ps1` | `:11-27` | `Stop-Service` de los dos servicios además de los procesos |
| `instalador/Demo/scripts/Actualizar-Demo.ps1` | `:51-53`, `:94-96`, `:129-135` | Con servicios: **elevación**, detener, copiar a `Program Files`, `actualizar`, `comprobar-servidor`. Un paquete que cambia de modo (consola a servicios) se rechaza con el mensaje «desinstale (conserva las bases) e instale de nuevo» (HOJA A-5: «el DEMO se reinstala; sus bases se conservan») |
| `instalador/Demo/scripts/Desinstalar-Demo.ps1` | `:48` | Detener, **borrar el valor `Environment`**, `sc delete` y comprobar que la clave del servicio desapareció (error 1072: avisar de reinicio; DM-06); **conserva** bases, `ProgramData\GPOS NG`, la llave CNG y los usuarios contenidos (INS 6) |
| `instalador/Demo/scripts/Revertir-Actualizacion.ps1` | `:100` | Restaurar también los binarios de `Program Files` desde la copia previa **protegida** (SYSTEM + administradores; nunca desde la carpeta del usuario; DM-08) |
| `instalador/Demo/LEEME.md` | `:19`, `:63-64`, `:69-71`, sección 1 (requisitos) | Instalar y actualizar con elevación; 27 de 27 reportes; quitar el aviso del `crit`; cortafuegos y Edge como requisito |
| `tests/GPOS.EnsayoImplantacion/iniciar-api.ps1` | `:36` | `bin\Debug\net10.0` (sección 3.3) |
| `tests/GPOS.EnsayoImplantacion/README.md` | `:17-18` | `dotnet build src/GPOS.Api -c Debug` |
| `tests/GPOS.Tests/Arquitectura/ValoresDeTercerosTests.cs` | `:92` | Entradas nuevas para los literales de los scripts (`Program Files`, nombres de servicio) |
| Pruebas nuevas (estilo `EstacionInstaladorTests`, B-13 del INS) | — | `[Parser]::ParseFile` de todos los `.ps1`; textual: ningún `.ps1` escribe contraseñas ni la clave JWT en texto plano, ni contiene `Jwt__Clave` con un valor, ni la pasa a `reg.exe` ni a `Set-ItemProperty` (DM-05); `Recoger-Evidencia.ps1` no hace `reg query`/`reg export` de la clave del servicio; `Publicar` rechaza las combinaciones incoherentes (tabla de 3.2) |

---

## 3. Secuencia segura

### 3.1 Qué está en juego

- **Ninguna versión ya publicada queda sin arrancar**: salen de `demo/2026-10-15`, que no tendrá Q-6 [V fila 4 del inventario].
- **Lo que hay que impedir** es que alguien publique desde `feature/modelo-ng` después de unir T4-06 sin el DEMO con reportes. Hoy eso se detectaría solo al instalar. La solución es detectarlo **al publicar**.

### 3.2 Orden de PR en `feature/modelo-ng` y banderas

```
PR-4 (#139) -> PR-D1 (guardas, 0,5 dp) -> T4-06 (unión antes del 11-11) -> T4-04 -> T1-5 -> T4-02 -> PR-V (verbos) -> PR-D2 (DEMO con reportes) -> D4
```

Detalle:

1. **PR-D1, antes de T4-06** (plazo: unido el 11-10, un día antes que T4-06). Solo scripts y texto, sin compilar (`a/demo-guardas-q6`):
   - `Publicar-PaqueteDemo.ps1` agrega `-ConApiReportes` y **la guarda bidireccional**:

     | Árbol | Sin `-ConApiReportes` | Con `-ConApiReportes` |
     |---|---|---|
     | Sin Q-6 (hoy) | Publica como hoy | Publica con reportes (permite ensayar antes de T4-06) |
     | Con Q-6 | **Rechaza**: «este árbol exige la API de reportes (ADR-109 cl. 8, Q-6); use `demo/2026-10-15` o espere el DEMO con reportes» | Publica |

   - El marcador de Q-6 es textual: `src\GPOS.Api\Endpoints\ReenvioReportes.cs` contiene `CompilacionDepuracion` [I: nombre que fija el blueprint de T4-06, 7.1; pedir a B que lo conserve o que el PR de T4-06 agregue una constante con ese nombre; pregunta P-4].
   - `iniciar-api.ps1:36` y `README.md:17-18` a Debug (3.3).
   - Resultado: **mientras PR-D2 no exista, publicar desde `feature/modelo-ng` falla con un mensaje claro en vez de producir un DEMO que no arranca.** Ninguna combinación produce un paquete que no arranca.
2. **T4-06**: sin cambios de scripts (blueprint 7.2). Si PR-D1 no llegó, B no debe unir T4-06 sin él (regla de esta sección; pregunta P-4).
3. **T4-02**: ya cubierto por la guarda. Con PR-D2 aún no unido, el DEMO de `feature/modelo-ng` no se publica (la ventana en que P-D1-02 ya lo prohíbe).
4. **PR-V** (verbos en `GPOS.Migracion`, compila) y **PR-D2** (scripts del DEMO). Se pueden **desarrollar y ensayar desde ya contra el árbol actual**, porque hoy el reenvío con dirección ya funciona: no esperan a T4-06. Se unen antes que D4.
5. **Banderas:**
   - `version.json`: `IncluyeApiReportes` (ya existe, `Publicar:118`) pasa a ser la bandera de modo. `true` = modo servicios (elevación); `false` o ausente = modo consola (paquetes de `demo/*`).
   - Compatibilidad Debug y Release: el DEMO es siempre Release (CR-04 b, `Publicar:48-52`); el modo «sin dirección» solo existe en Debug (ensayo y pruebas). No se agrega ninguna bandera de runtime nueva: la API no distingue modos (Q-6 lo prohíbe).

### 3.3 Ensayo corto y laboratorio

- **Ensayo corto:** pasa a Debug (`-c Debug`, ruta `bin\Debug`). Con `ASPNETCORE_ENVIRONMENT=Production`, Debug acepta no tener dirección (`ValidarModo(depuracion: true)`) y DPAPI sin indicador del DEMO (`ProteccionDatosInstalacion.cs:77-80`). La introspección sigue rechazando la cuenta del usuario como hoy (línea `crit`), igual que ahora. [I] El ensayo prueba numeración e importación, no el empaquetado, así que perder fidelidad de Release es aceptable; si QA quiere Release, la alternativa es instalar los servicios, que cuesta una VM por ensayo.
- **Laboratorio de ADR-90:** sin acción hoy (fila 6). Cuando C escriba los guiones de dentro de la VM, llaman a `implantar-servidor` y `comprobar-servidor` y no arrancan la principal Release a mano.

---

## 4. Quién ejecuta cada paso

| Paso | Quién | Dónde | Nota |
|---|---|---|---|
| Escribir scripts, verbos y pruebas textuales | Agentes de A | PC de A | Solo análisis y compilación de `GPOS.Migracion`; **no** se ejecutan servicios ni instaladores (regla del 2026-10-08) |
| Spike 1, ensayos de instalación, `Instalar-Demo`, `Actualizar-Demo`, `comprobar-servidor` | **Propietario o técnico** con elevación | **VM `VM-SRV` en `LFMB`** (Windows Server 2025, 3 584 MB, 2 CPU, 60 GB, con SQL Server Express dentro; C estima ≤ 4,5 GB con SQL) | **No en la PC de A (8 GB)**. B detiene su trabajo en `LFMB` mientras corre la VM [I: lo pide `laboratorio-adr090/LEEME.md`]; pregunta P-8 |
| Publicar el `.7z` | Quien arma el paquete (copia limpia, 7-Zip, MAUI) | Equipo de publicación | Ya es así hoy (`Publicar:6`) |
| Instalar el DEMO final | Propietario o técnico, con elevación | Equipo del propietario | **Cada instalación y actualización del DEMO con servicios exige elevación** |
| Evidencia | C recoge; A y C comparten formato | `M:\VM\evidencia` | Ver abajo |

**Formato de evidencia compartido con C:** reutilizar el de C (`2026-10-22-casos-laboratorio-chromium-y-comprobaciones-paquete.md`):
- tabla `ID | Caso | Cómo | Resultado esperado | Marca [V] [I] [?]`, con IDs nuevos `DE-01` a `DE-nn` para los casos propios del DEMO y los de C (`PK-R1a`, `CH-01`…) citados por su ID;
- punto de control `base` antes de cada caso; `Recoger-Evidencia.ps1` con redacción de secretos y `manifiesto.json`;
- por ejecución se anota: `version.json` del paquete (con su SHA-256), nombre del punto de control, salida completa de `comprobar-servidor` (tabla OK, FALLA, AVISO), eventos de «Aplicación» de los orígenes `GPOS.Api`, `GPOS.Reportes` y `GPOS.Instalacion`, `sc qc`, `sc qprivs`, `sc sdshow`, `icacls` de `ProgramData\GPOS NG` y `Program Files\GPOS NG\Demo`, y el listado de sockets de 5071, 5073 y 5054;
- sin cadenas de conexión, claves ni valores del entorno del servicio (se vuelcan solo los **nombres** de las variables; C10).

---

## 5. Comprobaciones R1 a R10 aplicables al DEMO

| # | Comprobación (INS 4.1) | Aplica al DEMO | Esperado en el DEMO |
|---|---|---|---|
| R1 | `sc qprivs GPOS.Reportes` | Sí | Solo `SeChangeNotifyPrivilege` |
| R2 | cuenta, inicio, SID | Sí, con cambio | Cuenta virtual; **inicio manual** (no diferido); SID sin restricción |
| R3 | `icacls` de `ProgramData\GPOS NG`, `\Reportes`, `\Reportes\render`, `\Api\anillo` y `\config` | Sí, con cambio | Vector de ADR-77; `\config` pasa a `%ProgramData%\GPOS NG\config` (rev. 2, DM-10; ya no en la carpeta del usuario); `render` sin lectura para usuarios autenticados y sin uniones |
| R4 | Sockets y canalización | Sí | `127.0.0.1:5073`; las dos canalizaciones con su dueño |
| R5 | `/api/salud` con versión | Condicional | Depende del cambio aditivo de `/api/salud` (nota del INS; O-12). Sin él: solo 200 |
| R6 | Sin eventos 5106 y 5112 a 5116 en 15 min | Sí | Sin eventos |
| R7 | Regla de salida | **No** | AVISO fijo «sin regla de salida en el DEMO» (2.1) |
| R8 | Variables de entorno y archivos sin credenciales | Parcial | **AVISO conocido** que nombra la variable (nunca valor, fragmento ni hash): la clave JWT en el entorno del servicio (D-3, P-3 aprobada). Se valida que el resto no tenga cadenas con `Password=`. **FALLA** (código 4) si la DACL de la clave del servicio concede lectura a cualquier SID que no sea SYSTEM o administradores (DM-01) y, con perfil distinto de `demo`, si hay `Jwt__Clave` o nombres con `Clave`/`Password`/`Secret` (cerrojo 4) |
| R9 | `GPOS.Migracion verificar --estricto` | **No** (modo Amplio) | Se usa `verificar` sin `--estricto` (como `Iniciar-Demo.ps1:41`); la regla de `sa`, contención y roles no es del DEMO |
| R10 | Reporte 1, uno del diseñador y uno de la P-2 | Sí | 200 con datos; añadir `CXC-ANTIGUEDAD` (reporte 8) para cubrir lo que mueve T4-06; ninguna escritura posible |

Se suman: P1 (cuenta, privilegios), P4 (`/api/salud` de la principal), P5 (la canalización de introspección existe y es de `NT SERVICE\GPOS.Api`, sin eventos 5122), P6, **P7 (modo de identidad: en el DEMO es Amplio y es AVISO esperado, no FALLA)**, P8 (un reporte pedido a la principal llega y vuelve) y K3 (sin secretos en el registro de la instalación). Del bloque CH de C aplican CH-01 a CH-06 y CH-10, cuando T4-01 (#152) esté unido.

Casos propios del DEMO (`DE-nn`): DE-01 spike (principal servicio en Amplio y DPAPI, D-2 y D-4); DE-02 instalación nueva con bases existentes; DE-03 reinstalación conservando bases (`Desinstalar` + `Instalar`); DE-04 actualización desde un paquete en modo consola (debe rechazarse, 2.4); DE-05 el usuario inicia y detiene sin elevación (y, rev. 2, `sc sdshow` sin `DC`/`WD`/`WO`/`SD`); DE-06 un usuario sin privilegios no puede reemplazar el binario del servicio (D-5) y ninguna ruta del entorno de los servicios cae bajo el perfil del usuario (DM-10); DE-07 `comprobar-servidor` falla cerrado si falta el SID en `CuentaServidor`; DE-08 los 27 reportes del sistema responden 200; DE-09 imprimir ticket y factura cuando exista T4-02.

Casos añadidos por el dictamen de seguridad (rev. 2), todos en la VM `VM-SRV` y dentro del spike; la evidencia es solo «presente/ausente» y la SDDL, nunca el valor de la clave:

| ID | Caso | Resultado esperado | Origen |
|---|---|---|---|
| DE-10 | Un usuario estándar intenta leer el valor `Environment` de `GPOS.Api` | Acceso denegado; la SDDL de la clave coincide con `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)` | DM-01 |
| DE-11 | El usuario que instala inicia y detiene los servicios pero intenta reconfigurarlos (`sc config`) | Inicia y detiene; reconfigurar es denegado | DM-09 |
| DE-12 | Un usuario estándar intenta listar o leer `Reportes\render`, `Api\anillo` y `config` | Denegado en los tres | DM-10, DM-11 |
| DE-13 | El proceso Chromium hijo de la principal: ¿tiene `Jwt__Clave` en su entorno? (anotar solo presente/ausente) | Ausente | DM-04 |
| DE-14 | `is_trustworthy_on` en `GPOS_SYSDATA` y las `GPOS_*`; roles de servidor del login `NT SERVICE\GPOS.Api` | `is_trustworthy_on = 0`; roles de servidor vacíos | DM-03 |
| DE-15 | Sockets de 5071 y 5073 | Solo `127.0.0.1`/`::1` | DM-12 |
| DE-16 | Tras `Desinstalar-Demo` | Sin clave de servicio ni valor `Environment` (si 1072, aviso de reinicio) | DM-06 |

Condiciones del spike (DE-01 y DE-10 a DE-16): solo en la VM, desde el punto de control `base`, nunca en la PC de A ni en la del propietario; datos solo de demostración; clave generada por el verbo o por el script del spike, nunca escrita a mano; **prohibido dar a la cuenta virtual `sysadmin` o cualquier rol de servidor «para ver si arranca»** (si no arranca sin ellos, se anota FALLA con el error y se escala); evidencia con `Get-Acl` de la clave (solo la SDDL), `sc qc`, `sc qprivs`, `sc qsidtype`, `sc sdshow`, `icacls` y roles y permisos SQL del login; nunca `reg query` del valor.

---

## 6. Esfuerzo, fechas y dependencias

### 6.1 Esfuerzo (dp, [I], ±40 %)

| Pieza | dp |
|---|---|
| PR-D1: guardas de Publicar, ensayo corto a Debug, LEEME | 0,5 |
| Spike 1 en VM (DE-01: ¿la principal arranca como `NT SERVICE\GPOS.Api` en Amplio con DPAPI de usuario?) | 0,5 (+ una sesión de VM con el técnico) |
| PR-V: verbos `implantar-servidor` y `comprobar-servidor` (INS 9.2: 0,30 sp con 21 comprobaciones; aquí 11 y perfil demo) | 1,5 |
| PR-D2: scripts de 2.4, pruebas textuales, LEEME | 2,5 a 3,0 (la cifra de la HOJA) |
| Sobrecarga por D-2 a D-6 (esquema como servicio, JWT, anillo, modo de red): ajustes en scripts y verbos | 1,0 a 1,5 |
| Ensayos en VM y evidencia (A prepara, el técnico ejecuta) | 1,0 |
| Rev. 2, dictamen de seguridad: DM-02 a DM-07, DM-09, DM-13 y DM-14 en `GPOS.Migracion` (+0,5 a 0,75: cerrojos 1 y 4, generación y rotación de la clave, anillo con certificado, SDDL, orígenes de eventos) y PR pequeño de la API (cerrojo 2 y DM-04, 0,25); corrección del plan (0,1, ya hecha en esta revisión) y DM-08/DM-10/DM-12/DM-15 dentro de PR-D2. Los DE-10 a DE-16 caben en los 0,5 del spike. DM-11 es de B (T4-01, 0,25 a 0,5), no suma aquí | 0,75 a 1,0 |
| **Total** | **7,25 a 9,0 dp** (rev. 1: 6,5 a 8,0; HOJA: 2 a 3 dp) |

La HOJA cubre solo la fila de PR-D2 [V: `hoja:176` trata los verbos como un adelanto aparte, 0,30 sp]. Si el spike falla (D-2), el plan cambia entero (alternativas en 6.3). Costo de infraestructura: USD 0 (VM existente, Edge y SQL Express ya requeridos).

### 6.2 Fechas

| Fecha | Hito |
|---|---|
| Hasta el 11-02 | Nada de este plan: A cierra PR-4 y los arreglos del #124 (aviso de B). Solo respuestas a las preguntas |
| **11-03 a 11-06** | PR-D1 (sin compilar), en paralelo con T4-06 |
| **11-10 (fecha límite real)** | PR-D1 **unido**. T4-06 se une el 11-11: sin PR-D1, T4-06 no debe unirse |
| Primera semana con VM libre (a más tardar 11-13) | Spike 1. Si falla, avisar a B ese día (cambia la HOJA A-5) |
| 11-06 a 11-13 (rev. 2) | PR pequeño de la API (cerrojo 2 y DM-04, ~0,25 dp); el spike incluye DE-10 a DE-16 sin conceder roles de servidor |
| 11-09 a 11-23 (rev. 2; antes 11-20) | PR-V (compila solo `GPOS.Migracion`; +0,5 a 0,75 dp) y borrador de PR-D2; revisión del auditor-seguridad sobre el diff antes de unir |
| 11-16 a 11-27 | PR-D2 y ensayos en VM (2 pasadas: sin T4-02 y con T4-02 si ya está) |
| **Antes de D4 (hacia fines de nov; G-O5-T4 el 12-04)** | PR-D2 unido y evidencia entregada |

Holgura: PR-D2 tiene unos 5 días hábiles hasta el 12-04; con la sobrecarga de 6.1 y el +0,75 a 1,0 dp de rev. 2 es **muy justo** (el total sube a 7,25 a 9,0 dp [I, ±40 %]). Se adelanta empezando PR-V, el PR de la API y el spike antes del 11-09. Si el spike mide que la escalera de 2.2.2 llega al punto 4 (necesita rol de servidor), es FALLA y se escala: no se continúa con PR-V.

### 6.3 Dependencias y alternativas

- **#124:** ya unido (`bc05f541`); aporta O-1 y O-3, pero son para el MSI. No hay MSI de la principal ni de reportes (fila 7), así que el DEMO **no puede esperarlos** y usa verbos y scripts.
- **ADR-77, acción previa:** el DEMO la sustituye con `implantar-servidor --fase carpetas` (punto 3). No es la acción del MSI; la revisión del auditor-seguridad debe aceptar que el DEMO no la tiene en un MSI.
- **N-3:** son los verbos de PR-V.
- **PR-4 (#139):** D-6.
- **T4-01 (#152):** el DEMO necesita Edge o Chrome; el perfil en TEMP (2.1).
- **Alternativa descartada: (b) de la HOJA** (congelar el DEMO). Es la opción más barata (0 dp) y es la de respaldo si el spike falla: el DEMO sigue saliendo de `demo/2026-10-15` hasta que exista el paquete único. Costo: ningún DEMO nuevo con funciones posteriores al #42.
- **Alternativa descartada: (c) de la HOJA** (render y reportes locales en Release solo para el DEMO): contradice Q-6 y la cl. 1.
- **Alternativa descartada: publicar el DEMO en Debug:** contradice CR-04 (b) y la lista de publicación Release.

---

## 7. Preguntas abiertas

**Estado (rev. 2):** P-1, P-3, P-4 y P-7 quedan **APROBADAS por el propietario en chat el 2026-10-22**. P-3 fue aprobada según la recomendación (opción a), **sujeta al dictamen de seguridad y a la firma de la excepción con caducidad, aún pendiente** (hasta entonces no se escribe «aceptada» como hecho consumado; C2). Siguen abiertas P-2, P-5, P-6, P-8, P-9, P-10 y P-11 (esta última resuelta técnicamente por DM-13, a confirmar en PR-V).

| # | A quién | Pregunta | Recomendación de A | Antes de |
|---|---|---|---|---|
| P-1 | B y propietario | **APROBADA (propietario, chat, 2026-10-22).** D-1: ¿se acepta que el DEMO pase a **dos servicios con elevación en cada instalación y actualización**, y que su esfuerzo real sea de 6,5 a 8 dp? (rev. 2: 7,25 a 9,0 dp con el dictamen) | Sí, con el spike como punto de decisión | 11-03 |
| P-2 | B (arquitecto-software) | D-2: ¿la principal puede correr en modo Amplio con `NT SERVICE\GPOS.Api` (login, permisos, esquema migrado por `GPOS.Migracion`)? N-6 del INS (orden de S0, `sistema` y empresas) | Confirmar el orden y que Amplio sea compatible; si no lo es, el DEMO con servicios exige el modo Estricto y su `credencial-app` | Spike |
| P-3 | Auditor-seguridad y propietario | **APROBADA (propietario, chat, 2026-10-22), según la recomendación; sujeta al dictamen y a la firma de la excepción con caducidad (pendiente).** D-3: ¿cómo llega la clave JWT al servicio del DEMO? (a) entorno del servicio con DACL restringida (excepción solo del DEMO); (b) esperar ES256 (ADR-41); (c) archivo protegido, que exige código. Dictamen: (a) aceptable solo en el DEMO, con DM-01, DM-02, DM-04, DM-05, DM-06 y DM-15; (c) recomendada para clientes si se necesita un canal antes de ES256 | (a) para el DEMO, con los cuatro cerrojos y aviso R8 | PR-D2 |
| P-4 | B | **APROBADA (propietario, chat, 2026-10-22).** Q-6: que T4-06 conserve el nombre `CompilacionDepuracion` (marcador de la guarda de Publicar) y que **no se una antes de PR-D1**. También: que no se publique ningún DEMO de `feature/modelo-ng` entre la unión de T4-06 y PR-D2 (P-4 del blueprint de T4-06) | Sí a las dos | 11-06 |
| P-5 | B (arquitecto-software) | D-4: DPAPI del usuario con el perfil de una cuenta virtual, [?] | Spike; si falla, certificado de anillo de H-17 v2 también en el DEMO (rechaza `DpapiDemo` solo en Estricto) | Spike |
| P-6 | B | D-6: con PR-4, ¿qué hace una principal-servicio sin `HKLM\SOFTWARE\GPOS NG\Servidor`? ¿El DEMO ejecuta `GPOS.Migracion red --modo un-equipo`? | Sí, en `--fase lectura` | PR-V |
| P-7 | B (T4-01) | **APROBADA (propietario, chat, 2026-10-22), con las condiciones de DM-11 (2.1: DACL sin lectura para autenticados, subcarpeta de 128 bits, borrado al cerrar, purga al iniciar, `TMP`/`TEMP`).** El perfil de Chromium va a `Path.GetTempPath()` (#152); pedir `%ProgramData%\GPOS NG\Reportes\render` con la DACL de ADR-77 (P-CH-2 de C) | Sí | Antes de unir T4-01 |
| P-8 | B y C | ¿Cuándo hay VM libre en `LFMB` para el spike y los dos ensayos? ¿Quién teclea dentro de la VM: el propietario, el técnico o B? ¿Hay imagen de Windows Server 2025 con Edge y sin él (Q-5 de C)? | Spike en la primera semana libre; técnico o propietario | 11-09 |
| P-9 | Propietario | El DEMO publicado sigue saliendo de `demo/2026-10-15` hasta que haya licencia s1 (`Instalar-Demo.ps1:17-19`). ¿Se quiere que PR-D2 espere esa licencia, o se ensaya con licencia de prueba? | Ensayar con lo que haya; PR-D2 no espera | PR-D2 |
| P-10 | B (QA/C) | R5 y R10 dependen del cambio aditivo de `/api/salud` (O-12) y de O-8: ¿la comprobación vive en `verificar` ampliado o en `comprobar-servidor`? (Q-3 de C) | En `comprobar-servidor` | PR-V |
| P-11 | Auditor-seguridad | Orígenes de eventos sin MSI: ¿lo registra el paso elevado del DEMO? Sin él, 4767 y los eventos de arranque no llegan al Visor | Sí, en `--fase servicios`. **Respondida por el dictamen (DM-13):** sí, con `EventMessageFile` en ruta protegida | PR-V |

---

### Cierre
- Estado: Completado (rev. 2, 2026-10-22: incorpora el dictamen de seguridad; con ello el dictamen pasa de Rechazado a Aprobado con observaciones, recomendación técnica; la firma es del propietario)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\plan-demo-con-api-de-reportes-2026-10-22.md`
- Dictamen registrado: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\dictamen-seguridad-demo-jwt-d5-2026-10-22.md` (auditor-seguridad, 2026-10-22; DM-01 a DM-03 Altas, DM-04 a DM-11 Medias, DM-12 a DM-16 Bajas; opción (a) de P-3 aceptable solo en el DEMO y con condiciones)
- Supuestos (rev. 2, además de los siguientes, los del dictamen, a confirmar en el spike DE-01 y DE-10 a DE-16: DACL por omisión de las claves de servicio con lectura para Usuarios; el Administrador de servicios lee `Environment` como SYSTEM y la principal no necesita leer su clave; los hijos de PuppeteerSharp heredan el entorno; el perfil de la cuenta virtual se carga; `TEMP` de la cuenta virtual puede resolver a una ruta compartida; costos ±40 %):
  - 1 sp = 5 dp para convertir el 0,30 sp del INS;
  - el marcador de Q-6 es `CompilacionDepuracion` (nombre que fija el blueprint de T4-06, aún sin construir);
  - la principal con `--servicio` y cuenta virtual atiende en modo Amplio (no probado: es el spike);
  - DPAPI del usuario funciona bajo la cuenta virtual (no probado);
  - los paquetes de `demo/*` no recibirán Q-6;
  - Edge está presente en Windows 10 y 11;
  - la memoria de la VM `VM-SRV` alcanza con SQL Express (cifra de C).
- Decisiones candidatas a ADR:
  - (1) el DEMO pasa a modo servicios, con `IncluyeApiReportes` como bandera de modo y la guarda bidireccional de Publicar (alternativa descartada: congelar el DEMO, (b) de la HOJA, que queda como respaldo);
  - (2) excepción K3-DEMO: `Jwt__Clave` en el entorno del servicio con DACL protegida sobre la clave del servicio, atada a `--perfil demo` + Amplio por los cuatro cerrojos, **con caducidad** al existir ES256 (ADR-41) o la opción (c) (P-3; alternativas descartadas: esperar ES256 por plazo y (c) por costo, que queda como camino para clientes); firma del propietario pendiente;
  - (3) los verbos de implantación reemplazan para el DEMO la acción previa de ADR-77 punto 3 (sin MSI);
  - (4) anillo con certificado (H-17 v2) también en el DEMO con servicios, en lugar de `DpapiDemo` (alternativa descartada: ejecutar `GPOS.Migracion` bajo la cuenta virtual);
  - (5) techo de privilegios SQL de la cuenta virtual en Amplio: `db_owner` por base y `dbcreator` solo justificado, nunca roles de servidor administrativos, `TRUSTWORTHY OFF`.
- Entregas a otros agentes:
  - arquitecto-software de B → P-2, P-5, P-6 (P-1, P-4 y P-7 ya aprobadas); T4-01 (#152) → DM-11 (perfil de Chromium en `%ProgramData%\GPOS NG\Reportes\render`, subcarpeta aleatoria, borrado y purga) y filtro de salida (DM-12);
  - auditor-seguridad → revisión del diff de PR-V y PR-D2 antes de unir (P-3 y P-11 respondidas; D-5 dictaminada);
  - propietario → **firma de la excepción K3-DEMO con caducidad** (pendiente), P-8 y P-9 (VM y licencia de prueba);
  - arquitecto-maestro → ADR candidatos (2), (4) y (5) como `Propuesto`;
  - C → formato de evidencia (sección 4), casos `DE-01` a `DE-16` y los guiones de dentro de la VM con los verbos;
  - arquitecto-software de A y desarrollador → PR-V (verbos de `GPOS.Migracion`, con DM-02 cerrojos 1 y 4, DM-05, DM-06, DM-07, DM-09, DM-13, DM-14); desarrollador (API) → cerrojo 2 de DM-02 y DM-04;
  - devops de A → PR-D1 y PR-D2.
- Próximo paso recomendado: que B reciba P-1, P-4 y P-7 ya aprobadas (sin PR-D1 unido el 11-10, T4-06 no debe unirse), que el propietario firme la excepción K3-DEMO con caducidad y que se reserve una VM de `LFMB` para el spike (DE-01 y DE-10 a DE-16, sin roles de servidor) en la primera semana libre.

---

## Registro de firma (2026-10-22, tarde)

**El propietario firmó en chat la excepción de K3 para el DEMO** (clave JWT en el entorno del servicio, con la DACL protegida de DM-01, solo en el perfil `demo` y modo Amplio, con los cuatro cerrojos de DM-02 y caducidad: termina cuando llegue ES256 o el archivo protegido). Con esto P-3 pasa de «aprobada según la recomendación» a **firmada**; ya se puede construir el verbo de la clave en PR-V. Queda pendiente el ADR que la registra (arquitecto-maestro de B, estado Propuesto → Aceptado con esta firma).
