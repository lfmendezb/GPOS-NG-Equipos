# Dictamen de seguridad: DEMO con dos servicios, clave JWT (P-3, opción a), D-2, D-4, D-5, spike y PR-D2

**Autor:** auditor-seguridad (equipo A). **Fecha:** 2026-10-22. **Modo:** solo lectura (`git show`/`git grep` sobre `origin/feature/modelo-ng` `b4378650`, `origin/b/ola5-t4-01-render` `cf6ccf98` (#152) y `origin/master`; no se compiló, no se ejecutó nada y no se cambió de rama).
**Entrada:** `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md` (D-1 a D-6, 2.1, 2.2, 2.3, 5 R8, P-3, P-5, P-7, P-11).
**Decisión del propietario (chat, citada por el que encarga):** DEMO con dos servicios con elevación (`NT SERVICE\GPOS.Api` y `NT SERVICE\GPOS.Reportes`) y, para D-3, la opción (a) como **excepción solo del DEMO** al K3 del INS. Este dictamen fija las condiciones; la firma sigue siendo del propietario (C2).

**Convenciones:** [V] verificado con `ruta:línea` (código en `b4378650` salvo que se indique otra rama); [I] inferido (comportamiento de Windows, SQL Server o Chromium que hay que confirmar en el spike); [?] sin dato. Sin secretos, sin pasos de explotación (C10).

---

## 1. Alcance y superficie revisada

| Superficie | Exposición en el DEMO con servicios |
|---|---|
| `GPOS.Api` como servicio (`NT SERVICE\GPOS.Api`), puerto 5071 | Solo loopback; emite y valida tokens HS256 de usuario **y de dispositivo** con la misma clave (`src/GPOS.Api/Program.cs:65-67`, `:72-77`) [V] |
| `GPOS.Reportes` como servicio, puerto 5073 | Solo loopback; valida por introspección (canalización con ACL), nunca recibe la clave (ADR-41, nota del 2026-10-08) [V `docs/adr/ADR-041.md:29`] |
| Entorno del servicio en el registro | Lleva la dirección de reenvío y, con (a), `Jwt__Clave` |
| `%ProgramFiles%\GPOS NG\Demo`, `%ProgramData%\GPOS NG\{Api,Reportes}` | Binarios y datos de cuentas de servicio |
| SQL Server local | Inicio de sesión `NT SERVICE\GPOS.Api` en modo Amplio |
| Chromium hijo (PuppeteerSharp) | Lo lanza la principal (`src/GPOS.Api/Impresion/ConvertidorPdf.cs:66-75`) [V] y reportes (#152, `src/GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs:101-109`) [V] |
| Verbos `implantar-servidor` / `comprobar-servidor` y scripts del DEMO | No existen todavía (plan 2.3) [V según el plan]; se dictaminan sus condiciones |

**Impacto de la clave JWT si se filtra** [V `src/GPOS.Api/Seguridad/Seguridad.cs:19-22`]: quien la tenga firma tokens válidos de cualquier usuario, incluido el Super Usuario, y de cualquier dispositivo. En el DEMO el daño queda acotado a datos de demostración **porque** el modo Amplio no arranca con una licencia de producción o beta aceptada [V `src/GPOS.Api/Servicios/Inicializacion.cs:94-98`]. Ese ancla es la que hace aceptable (a), y por eso se exige que la excepción quede atada a Amplio (DM-02).

---

## 2. Tabla resumen de hallazgos

| ID | Sev. | Título | Evid. |
|---|---|---|---|
| DM-01 | **Alta** | La DACL va en la **clave del servicio** `...\Services\GPOS.Api` (protegida, antes de escribir el valor), no en un «`\Environment`» que es un *valor*; la clave por omisión es legible por Usuarios | [V] plan 2.2 (`:75`, `:78`); [I] ACL por omisión |
| DM-02 | **Alta** | No hay todavía ningún cerrojo que limite la excepción al DEMO: hacen falta cuatro (verbo, API, Publicar, `comprobar-servidor`) | [V] `Inicializacion.cs:94-98`, `Publicar-PaqueteDemo.ps1:60-62`, `:139-141` |
| DM-03 | **Alta** | Privilegios SQL de `NT SERVICE\GPOS.Api` sin acotar: Amplio hace DDL al arrancar y `CREATE DATABASE` desde un endpoint; riesgo de «arreglarlo» con `sysadmin` | [V] `Inicializacion.cs:94-103`, `EsquemaEmpresa.cs:216`, `AdminEndpoints.cs:319-320` |
| DM-04 | Media | La clave pasa a los procesos hijos (Chromium) por herencia del entorno | [V] `src/GPOS.Api/Impresion/ConvertidorPdf.cs:66-75` |
| DM-05 | Media | Generación y escritura de la clave: en C# y en memoria; nunca por PowerShell con el valor como parámetro, `reg.exe` ni línea de comandos | [V] `Instalar-Demo.ps1:101`; [I] registro de módulos de PowerShell y 4688 |
| DM-06 | Media | Ciclo de vida de la clave: única por instalación, rotación, desinstalación y clones de VM | [V] `Comun-Demo.ps1:61-66`; [I] |
| DM-07 | Media | D-4: la principal (cuenta virtual) y `GPOS.Migracion` (administrador) comparten el anillo; con DPAPI de usuario no pueden; la salida rápida (`DpapiMaquina`, ACL más laxa) degrada | [V] `Comun-Demo.ps1:360-367`, `ProteccionDatosInstalacion.cs:60-62`, `:73-79` |
| DM-08 | Media | D-5: binarios en `Program Files` correctos, pero faltan: carpeta preexistente, verificación en destino, copia de reversión y `EventMessageFile` | [V] plan 2.4 (`Revertir-Actualizacion.ps1:100`); [I] |
| DM-09 | Media | SDDL de los servicios para el usuario que instala: solo iniciar, detener y consultar; nunca cambiar configuración | [V] plan 2.3 (`--fase servicios`) |
| DM-10 | Media | Los servicios no deben leer ni escribir nada de la carpeta del usuario (archivo de instalación, anillo, registros) | [V] `Comun-Demo.ps1:356` |
| DM-11 | Media | Perfil de Chromium en `TEMP` y **nunca se borra** (deja HTML y caché de documentos con datos) | [V] #152 `ConvertidorPdf.cs:101-109` y principal `:66` |
| DM-12 | Baja | Cortafuegos y escucha: confirmar solo loopback (también con PR-4); salida de Chromium sin filtrar | [V] plan 2.1 «Cortafuegos»; [I] |
| DM-13 | Baja | P-11: orígenes de eventos sin MSI | [V] `ModoServicioApi.cs:206-224` (plan) |
| DM-14 | Baja | Privilegios y recuperación del servicio | [V] `ModoServicioApi.cs:19` |
| DM-15 | Baja | R8/K3 en el DEMO: AVISO por nombre y comprobación de la DACL, no del valor | [V] INS `origin/master:docs/operaciones/2026-10-19-diseno-instalador-reportes.md:174`, `:199` |
| DM-16 | Baja (riesgo residual aceptado) | Lectores legítimos de la clave con (a): SYSTEM, administradores, copias del subárbol, volcados | [I] |

---

## 3. Checklist OWASP (Top 10 2021) aplicado al cambio

| # | Categoría | Resultado |
|---|---|---|
| A01 | Control de acceso | Hallazgos DM-01, DM-08, DM-09, DM-10, DM-11 (ACL de registro, archivos y servicio) |
| A02 | Fallas criptográficas | DM-04, DM-05, DM-06, DM-07. HS256 con 48 bytes de CSPRNG es suficiente [V `Instalar-Demo.ps1:101`, `Comun-Demo.ps1:61-66`] |
| A03 | Inyección | No aplica al cambio (no hay consultas nuevas; los verbos usan parámetros, `ComandoSistema.cs:79`) [V] |
| A04 | Diseño inseguro | DM-02 (excepción sin cerrojo), DM-03 |
| A05 | Configuración de seguridad | DM-03, DM-12, DM-14 |
| A06 | Componentes vulnerables | Edge/Chrome del sistema (se actualizan solos) [I]; QuestPDF 2026.9.0 (#152): sin revisión de avisos en este dictamen. No aplica más allá |
| A07 | Identificación y autenticación | DM-01 a DM-06 (la clave firma todas las sesiones) |
| A08 | Integridad de software y datos | DM-08 (binarios ejecutados por servicios; reversión) |
| A09 | Registro y monitoreo | DM-05 (la clave no debe llegar a ningún registro), DM-13, DM-15 |
| A10 | SSRF | DM-12 (Chromium carga HTML de plantillas y puede salir a la red) — sospecha, a confirmar en T4-01 |

---

## 4. Hallazgos y condiciones

### (1) P-3: ¿es aceptable la opción (a)?

**Dictamen: sí, para el DEMO y solo para él, con las condiciones DM-01, DM-02, DM-04, DM-05, DM-06 y DM-15.** Motivos: la clave ya vive hoy en el entorno de un proceso (`Comun-Demo.ps1:350`) [V]; (a) la saca del perfil del usuario y la deja legible solo para SYSTEM y administradores, que de todos modos controlan la máquina; el daño máximo está acotado por el ancla de Amplio sin licencia de cliente (`Inicializacion.cs:94-98`) [V]. Costo: ~0,5 dp dentro de PR-V/PR-D2 (DM-02 añade ~0,25 dp de código en la API) [I, ±40 %].

**Comparación breve**

| Opción | Seguridad | Costo / plazo | Dictamen |
|---|---|---|---|
| (a) Entorno del servicio con DACL | Legible por SYSTEM y administradores; se hereda a los hijos (DM-04) y aparece en volcados de memoria; contradice K3 | ~0,5 dp; sin código nuevo salvo los cerrojos | **Aceptable solo en DEMO**, con caducidad |
| (b) Esperar ES256 (ADR-41) | La mejor: llave privada en CNG/TPM, sin secreto compartido | ADR-41 está «decidido, no implementado» y el propietario no lo adelanta [V `docs/adr/ADR-041.md:17`, `:29`]: no llega antes de D4 | Descartada por plazo |
| (c) Archivo protegido (`%ProgramData%\GPOS NG\Api\secretos\`, ACL SYSTEM + administradores + lectura de `NT SERVICE\GPOS.Api`, leído con `Microsoft.Extensions.Configuration.KeyPerFile`) | Igual exposición ante administradores; **no** se hereda a los hijos; cumple K3 y sirve también para producción hasta ES256 | ~0,5 a 1 dp de código y pruebas [I] | Mejor relación costo/beneficio a mediano plazo; recomendada para la entrega a clientes mientras no exista ES256 |

Criterio propio (C13.3): (c) cuesta solo ~0,5 dp más que (a) y evita crear una excepción. Respeto la decisión del propietario por (a) para el DEMO, pero dejo constancia de que, si la versión de cliente necesita un canal antes de ES256, debe ser (c), no (a).

**DM-01 (Alta) — DACL exacta y orden.** `Environment` es un **valor** `REG_MULTI_SZ` de la clave `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`, no una subclave [I: documentación de Windows]; el plan lo escribe como ruta (`plan:75`, `:78`) [V]. La DACL por omisión de las claves de servicio concede lectura a `BUILTIN\Users` [I: confirmar en el spike con `Get-Acl`]. Remediación:
- DACL de la clave `...\Services\GPOS.Api`, **protegida** (sin herencia), dueño SYSTEM: `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`. Sin `Users`, `Authenticated Users`, `CREATOR OWNER`, `ALL APPLICATION PACKAGES` ni la cuenta del propio servicio (el Administrador de servicios lee el entorno como SYSTEM; la principal no necesita leer su clave) [I: confirmar en el spike que arranca].
- Orden obligatorio en `--fase servicios`: crear el servicio → aplicar la DACL protegida → comprobarla → **solo entonces** escribir `Environment`. Nunca al revés (ventana de lectura).
- Si en algún momento se restringe una subclave, la comprobación debe fallar: lo que importa es quién puede leer el *valor*.
- `comprobar-servidor` verifica la DACL en cada `Iniciar-Demo` (una actualización en el lugar de Windows puede rehacer claves de servicio [I]); con `Jwt__Clave` presente y una ACE de lectura para cualquier otro SID → **FALLA** (código 4).

**DM-02 (Alta) — Cerrojos que limitan la excepción al DEMO.** Hoy nada lo impide; la excepción es reutilizable con copiar el verbo. Remediación (las cuatro, defensa en profundidad):
1. **Verbo.** `implantar-servidor` escribe `Jwt__Clave` en el entorno **solo** con `--perfil demo` **y** `GPOS__Seguridad__ModoIdentidad=Amplio` en ese mismo entorno; con cualquier otro perfil, el código que escribe la clave no es alcanzable (prueba de arquitectura: el literal `Jwt__Clave` aparece en un único método, del perfil demo).
2. **API.** Al arrancar como servicio, si `Jwt__Clave` está en el entorno del proceso y el modo **no** es Amplio → no arranca (evento 4767, sin el valor). Así la excepción hereda el ancla ya existente: Amplio no arranca con licencia de producción o beta (`Inicializacion.cs:94-98`) [V]. ~0,25 dp.
3. **Publicación.** `Publicar-PaqueteDemo.ps1 -Destino Cliente` ya rechaza Amplio en guiones y configuración (`:60-62`, `:139-141`) [V]; añadir el rechazo textual de `Jwt__Clave` en guiones del paquete de cliente.
4. **Comprobación.** `comprobar-servidor` con perfil distinto de `demo` → **FALLA** si `Jwt__Clave` (o cualquier nombre con `Clave`, `Password`, `Secret` o una cadena con `Password=`) está en el entorno de un servicio (K3 tal cual).
- Registrar la excepción en el ADR con **caducidad**: desaparece cuando exista ES256 (ADR-41) o (c).

**DM-04 (Media) — Herencia a procesos hijos.** La principal lanza Chromium con PuppeteerSharp (`ConvertidorPdf.cs:66-75`) [V]; un hijo hereda el entorno del padre por omisión y los procesos de render de Chromium también [I]. Un fallo explotable en el motor de render, con HTML de plantillas que edita un usuario con permiso de formatos, podría leer su propio entorno y obtener la clave (escalada de «editor de plantillas» a Super Usuario). Remediación: la principal **borra `Jwt__Clave` de su entorno de proceso** justo después de construir la configuración (una línea; el valor ya está en `JwtOpciones`); prueba que lo compruebe. Válido también para el DEMO en modo consola de hoy. No añadir `--no-sandbox` nunca (hoy no está: `:74` y #152 `:109`) [V].

**DM-05 (Media) — Generación y escritura.**
- Generar en el verbo C# con `RandomNumberGenerator` (válido en FIPS, perfil Avanzado), **48 bytes** → 64 caracteres Base64, como hoy (`Instalar-Demo.ps1:101`) [V]. Mínimo absoluto 32 bytes de entropía; la validación de la API (`Program.cs:67`, ≥ 32 *caracteres*, `Seguridad.cs:22` usa los bytes UTF-8) [V] no mide entropía: no generar nunca la clave desde texto elegido por una persona.
- Escribir con `Microsoft.Win32.Registry` desde el mismo proceso. **Prohibido:** pasar el valor por la línea de comandos (`reg.exe`, `sc`, argumentos del verbo) —queda en el evento 4688 si está activa la auditoría de procesos— o como parámetro de un cmdlet de PowerShell —queda en el registro de módulos (4103) si está activo— [I].
- No se escribe en `version.json`, en `config\`, en el archivo de instalación (`ArchivoInstalacion` solo admite `GPOS:RncDgii`) [V plan D-3], en la salida del verbo ni en la evidencia: `Recoger-Evidencia.ps1` vuelca **solo nombres** de variables (plan 4) [V]; prohibido `reg query`/`reg export` de la clave del servicio en la evidencia.
- El paquete sigue sin clave: `Publicar:127` rechaza `"Clave": "<valor>"` en los `appsettings.json` [V].

**DM-06 (Media) — Ciclo de vida.**
- **Única por instalación**: se genera en cada `Instalar-Demo` (fase servicios). Nunca se reutiliza la de `config\secretos.dpapi` del modo consola (al pasar de modo, clave nueva).
- **Rotación**: en cada reinstalación (obligatoria) y con una opción explícita (`implantar-servidor --perfil demo --rotar-jwt`) tras una demostración en equipo ajeno o si se sospecha exposición; la actualización normal **no** rota (evita cerrar sesiones). Rotar invalida los tokens vigentes (12 h por omisión, `Seguridad.cs:20`) [V], que es lo deseado.
- **Desinstalación**: detener el servicio → **borrar el valor `Environment`** → `sc delete` → comprobar que la clave del servicio ya no existe; si queda marcada para eliminación (error 1072), avisar que hace falta reiniciar. Quedan copias en los registros de transacciones del subárbol `SYSTEM` y en instantáneas VSS (solo administradores): riesgo residual aceptado (DM-16), cubierto porque la reinstalación genera otra.
- **Clones**: una VM o imagen clonada con el DEMO instalado comparte la clave. En el laboratorio es aceptable (datos de prueba, VM desechable); **prohibido distribuir una imagen con el DEMO ya instalado**; tras clonar, `--rotar-jwt`.

**DM-15 (Baja) — R8/K3 del DEMO.** R8 queda como **AVISO conocido** que nombra la variable, nunca su valor ni un fragmento ni un hash corto. Se suma la comprobación de DACL de DM-01 (FALLA si no se cumple). El resto del entorno: sin `Password=` (plan 5 R8) [V].

**DM-16 (Baja, residual aceptado).** Con (a) pueden leer la clave: SYSTEM, administradores, Operadores de copia de seguridad (`SeBackupPrivilege`), copias del subárbol y volcados de memoria de la principal (incluyen el bloque de entorno; WER los guarda en rutas de administradores) [I]. Todos ellos ya controlan la máquina; aceptable en un DEMO sin licencia de cliente.

### (2) D-5: binarios, cuentas, privilegios, cortafuegos y carpetas

**DM-08 (Media) — Binarios.** `%ProgramFiles%\GPOS NG\Demo` hereda la ACL de `Program Files` (administradores, SYSTEM y TrustedInstaller con control total; Usuarios lectura y ejecución) [I]: correcto. Condiciones:
- Si `GPOS NG` o `Demo` ya existen: comprobar dueño (SYSTEM, administradores o TrustedInstaller), que no sean punto de reanálisis (unión o enlace) y que ningún SID ajeno tenga escritura; si no, abortar (mismo criterio que ADR-77 punto 3). Nunca «arreglar» la ACL de una carpeta ajena.
- La copia la hace el proceso elevado; la **verificación de huellas se hace en el destino**, contra un manifiesto de `Publicar` (SHA-256 por archivo), no en la carpeta extraída del usuario (que el usuario o cualquier proceso suyo puede cambiar entre la verificación y la copia).
- `Revertir-Actualizacion.ps1` (`:100`, plan 2.4) [V]: la copia previa de los binarios va a `%ProgramFiles%\GPOS NG\Demo\.anterior` o a `%ProgramData%\GPOS NG\Demo\anterior` con ACL solo SYSTEM + administradores; **nunca** a la carpeta del usuario (restaurar desde allí plantaría binarios).
- `appsettings.json` de los servicios en `Program Files` (solo administradores escriben): correcto.

**DM-09 (Media) — SDDL del servicio para el usuario que instala.** Conceder al **SID del usuario que instala** (no a `IU`, `AU` ni `BU`): `SERVICE_START` (RP), `SERVICE_STOP` (WP), `SERVICE_QUERY_STATUS` (LC), `SERVICE_INTERROGATE` (LO), `SERVICE_QUERY_CONFIG` (CC) y `READ_CONTROL` (RC). **Nunca** `SERVICE_CHANGE_CONFIG` (DC), `WRITE_DAC` (WD), `WRITE_OWNER` (WO) ni `DELETE` (SD): con DC se cambia la cuenta o el binario del servicio y es escalada directa. `comprobar-servidor` lo verifica con `sc sdshow` (DE-05 del plan, ampliar con «no puede reconfigurar»).

**DM-10 (Media) — Nada de la carpeta del usuario.** Hoy `GPOS__ArchivoInstalacion__Carpeta` apunta a `config\` del DEMO (`Comun-Demo.ps1:356`) [V]. Con servicios: archivo de instalación en `%ProgramData%\GPOS NG\config` (ADR-77), anillo en `%ProgramData%\GPOS NG\Api\anillo` (plan 2.1, ADR-77 punto 4), registros de archivo (si los hay) en `%ProgramData%\GPOS NG\Api\registros` con lectura para administradores. La prueba DE-06 se amplía: ninguna ruta del entorno de los servicios cae bajo el perfil del usuario.

**Cuentas virtuales y privilegios (DM-14, Baja).** Correcto el diseño: `NT SERVICE\GPOS.Api` y `NT SERVICE\GPOS.Reportes`, sin contraseña, `SeChangeNotifyPrivilege` como único privilegio (`ModoServicioApi.cs:19`) [V], tipo de SID sin restricción (necesario para las ACL por `NT SERVICE\…`). Condiciones: `sc failure` solo con acciones de **reinicio** (sin `command=`/«ejecutar programa»); inicio manual; sin `SeImpersonatePrivilege` ni otros (R1 ya lo comprueba).

**DM-12 (Baja) — Cortafuegos y escucha.** Correcto no crear reglas de entrada. Condiciones: `comprobar-servidor` R4 comprueba que 5071 y 5073 escuchan **solo** en `127.0.0.1`/`::1` (nunca `0.0.0.0`, `[::]` ni `+`); con PR-4 (D-6) el modo `red --modo un-equipo` debe dejar loopback. Salida: Chromium carga HTML de plantillas y podría pedir recursos externos (SSRF o fuga de datos del documento) [I]; en T4-01, interceptar peticiones y permitir solo `data:`/`about:` y recursos embebidos. En el DEMO queda como AVISO R7, como dice el plan.

**DM-11 (Media) — Perfil de Chromium y temporales (P-7).** Hoy el perfil va a `Path.GetTempPath()\gpos-pdf-navegador\<8 hex>` y **no se borra nunca** (no hay borrado en ninguno de los dos `ConvertidorPdf`) [V]; ahí quedan caché y estado de documentos con datos de clientes. Si `TEMP` resolviera a `C:\Windows\Temp`, cualquier usuario puede crear antes la carpeta `gpos-pdf-navegador` con su ACL [I]. **Confirmo la ACL recomendada** para `%ProgramData%\GPOS NG\Reportes\render`: hereda de `\Reportes` (protegida, sin `AU`), es decir `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Reportes>)`; **sin** lectura para usuarios autenticados (a diferencia de la raíz). Condiciones: (i) al arrancar, comprobar que `render` no es punto de reanálisis y su dueño; (ii) subcarpeta por arranque con nombre aleatorio de 128 bits (no 8 hex); (iii) borrarla al cerrar el navegador y purgar restos al iniciar; (iv) como defensa barata sin código, fijar `TMP` y `TEMP` del servicio a `%ProgramData%\GPOS NG\Reportes\temp` (ya existe, P-77-4) y, para la principal si sigue renderizando, `%ProgramData%\GPOS NG\Api\temp` con el mismo patrón (también cubre `gpos-rnc-*`, `RncDgiiEndpoints.cs:40`) [V #152].

**DM-13 (Baja) — P-11.** Sí: la fase elevada registra los orígenes `GPOS.Api` y `GPOS.Reportes` (la cuenta virtual no puede, `ModoServicioApi.cs:206-224`). Condición: `EventMessageFile` apunta a una DLL en ruta protegida (la del marco de .NET en `%WINDIR%` o una copia en `Program Files`), nunca a la carpeta del usuario: el Visor de eventos de un administrador cargaría esa DLL. La desinstalación los conserva (historial) o los quita; cualquiera de las dos es aceptable.

### (3) D-2 y D-4

**DM-03 (Alta) — Permisos SQL mínimos del inicio de sesión de la cuenta virtual.** En Amplio la principal, al arrancar, crea y actualiza `GPOS_SYSDATA`, fija opciones y sube la marca (`Inicializacion.cs:94-103`) [V], y el endpoint de esquema puede ejecutar `CREATE DATABASE` (`AdminEndpoints.cs:319-320`; `EsquemaEmpresa.cs:216`) [V]. Con el login del usuario (`sysadmin`/`dbcreator`) eso funcionaba; con la cuenta virtual, la tentación al fallar el spike será darle `sysadmin`, y una API web con `sysadmin` es control del sistema operativo vía SQL Server. Además S1 lanza 51606 si el login de la API es dueño de la base (`PrivilegioMinimoSistema.cs:151`) [V]. Remediación, en este orden y midiendo en el spike la primera que funcione:
1. Preferido: esquema y bases por `GPOS.Migracion` con la cuenta del administrador (`--fase esquema`), y `sistema --login-api "NT SERVICE\GPOS.Api"` (rol `gpos_api` con sus DENY). Medir si Amplio arranca con eso (lo que no tiene permiso, ¿falla o avisa?).
2. Si Amplio exige DDL al arrancar: `db_owner` **solo** en `GPOS_SYSDATA` y en las bases `GPOS_*` del DEMO (anula los DENY de S1, `PrivilegioMinimoSistema.cs:14` [V]; aceptado en Amplio). Las bases siguen con dueño `sa` (S1, D-03).
3. `dbcreator` **solo** si el DEMO necesita crear empresas desde la interfaz; si no, las crea el script.
4. **Nunca** `sysadmin`, `CONTROL SERVER`, `securityadmin`, `serveradmin`, `ALTER ANY LOGIN` ni `IMPERSONATE`. Si el spike solo funciona con alguno, es **FALLA** del spike y se escala, no se «arregla».
- Con `db_owner` + dueño `sa`, una base con `TRUSTWORTHY ON` permite escalar a `sysadmin` [I: comportamiento conocido de SQL Server]. `comprobar-servidor` comprueba `is_trustworthy_on = 0` en `GPOS_SYSDATA` y todas las `GPOS_*` (FALLA si no).
- El login queda solo como inicio de sesión de Windows del equipo local; sin login SQL ni contraseña (no usar `login-servicio` en el DEMO).

**DM-07 (Media) — D-4 (DPAPI bajo cuenta virtual; P-5).** Dos cuestiones:
- *Funcionamiento* [I]: DPAPI de usuario con una cuenta virtual funciona si el Administrador de servicios carga su perfil (bajo `%WINDIR%\ServiceProfiles\`); su llave maestra queda protegida por el secreto DPAPI del sistema, así que SYSTEM y administradores pueden descifrarla y otros usuarios no. Es aceptable en el DEMO. Spike DE-01.
- *Conflicto* [V]: `GPOS.Migracion` usa **el mismo anillo** que la API (fila `Licencia.InstalacionId`; `Comun-Demo.ps1:360-367`; `ComandoSistema.cs:36`), y los verbos `sellos` y `empresa` «exigen el anillo de la API» (`Program.cs`, ayuda) [V]. Un anillo protegido con DPAPI de `NT SERVICE\GPOS.Api` no lo abre el administrador que ejecuta `GPOS.Migracion`, y viceversa. Las salidas rápidas son peores: `DpapiMaquina` (cualquier proceso del equipo descifra; Release lo rechaza, `ProteccionDatosInstalacion.cs:60-62` [V]), o abrir la ACL del anillo. **Recomendación:** en el modo servicios del DEMO, anillo con certificado (H-17 v2: certificado en `LocalMachine\My`, llave privada con ACL SYSTEM + administradores + `NT SERVICE\GPOS.Api`; `ProteccionDatosInstalacion.cs:63-69` [V]) y sin `DpapiDemo`. Así coincide con producción y elimina D-4. Costo: lo que cueste en `implantar-servidor` crear o anclar el certificado (`anillo --anclar` ya existe [V `Program.cs:16`]); ~0,5 dp [I]. Alternativa descartada: ejecutar `GPOS.Migracion` bajo la cuenta virtual (exige una tarea programada o un servicio temporal; más complejo y más superficie).
- `GPOS.Web` sigue como proceso del usuario con `DpapiDemo` (`Comun-Demo.ps1:379`) [V]: sin cambio.

### (4) Condiciones para el spike (DE-01) y para PR-D2

**Spike (VM `VM-SRV`):**
1. Solo en la VM, desde el punto de control `base`; nunca en la PC de A ni en la del propietario; datos solo de demostración; la VM se revierte al terminar.
2. Clave JWT generada por el verbo o el script del spike, nunca escrita a mano; no aparece en la evidencia (solo «presente/ausente» y la DACL).
3. Prohibido dar a la cuenta virtual `sysadmin` o cualquier rol de DM-03 punto 4 para «ver si arranca»: si no arranca sin ellos, se anota FALLA con el error y se escala.
4. Casos que debe cubrir, además de DE-01 a DE-09 del plan: **DE-10** un usuario estándar no puede leer el valor `Environment` de `GPOS.Api` (DM-01); **DE-11** el usuario que instala puede iniciar y detener pero no reconfigurar el servicio (DM-09); **DE-12** un usuario estándar no lista ni lee `Reportes\render`, `Api\anillo` ni `config` (DM-10, DM-11); **DE-13** el proceso Chromium hijo de la principal **no** tiene `Jwt__Clave` en su entorno (DM-04; anotar solo presente/ausente); **DE-14** `is_trustworthy_on = 0` y roles de servidor del login vacíos (DM-03); **DE-15** 5071 y 5073 solo en loopback (DM-12); **DE-16** la desinstalación deja sin clave de servicio ni valor `Environment` (DM-06).
5. Evidencia: `Get-Acl` de la clave del servicio (solo la SDDL), `sc qc`, `sc qprivs`, `sc qsidtype`, `sc sdshow`, `icacls`, roles y permisos SQL del login; nunca `reg query` del valor.

**PR-V y PR-D2 (condiciones de aceptación de seguridad):**
1. DM-01: DACL protegida en la clave del servicio, aplicada antes de escribir el valor; comprobada por `comprobar-servidor`.
2. DM-02: los cuatro cerrojos, con pruebas (arquitectura del verbo, arranque de la API en Estricto con `Jwt__Clave` → no arranca, `Publicar -Destino Cliente`, `comprobar-servidor` con perfil no demo → FALLA).
3. DM-04: la principal borra `Jwt__Clave` de su entorno tras leer la configuración, con prueba.
4. DM-05: clave generada y escrita en C#; prueba textual de que ningún `.ps1` contiene `Jwt__Clave` con un valor ni lo pasa a `reg.exe`/`Set-ItemProperty` (amplía la prueba textual del plan 2.4).
5. DM-06: rotación en reinstalación y con `--rotar-jwt`; desinstalación con borrado del valor y comprobación.
6. DM-03: el verbo concede exactamente el nivel medido en el spike y nada por encima de `db_owner` por base (más `dbcreator` solo si se justifica); comprobación de `TRUSTWORTHY`.
7. DM-07: anillo con certificado en modo servicios (o, si el propietario elige DPAPI de la cuenta virtual, decisión explícita sobre cómo `GPOS.Migracion` usa el anillo, sin `DpapiMaquina`).
8. DM-08 a DM-11 y DM-13: tal como están descritos.
9. Revisión del auditor-seguridad sobre el diff de PR-V y PR-D2 antes de unir.

---

## 5. Controles que están bien implementados

- El paquete del DEMO no lleva secretos y lo comprueba al publicar (`Publicar-PaqueteDemo.ps1:127`) [V].
- La clave JWT se genera con CSPRNG, 48 bytes, por instalación (`Comun-Demo.ps1:61-66`, `Instalar-Demo.ps1:101`) [V].
- Amplio no arranca con licencia de producción o beta (`Inicializacion.cs:94-98`) y `-Destino Cliente` rechaza Amplio (`Publicar:60-62`, `:139-141`) [V]: es la base sobre la que se ancla la excepción.
- Release rechaza `DpapiMaquina` y exige el anillo con certificado salvo `DpapiDemo`, que Estricto rechaza (`ProteccionDatosInstalacion.cs:60-79`) [V].
- Único privilegio declarado `SeChangeNotifyPrivilege` y comprobación de identidad y privilegios al arrancar como servicio (`ModoServicioApi.cs:19`; regla `Decidir`, mismo archivo) [V].
- La API de reportes nunca recibe la clave: introspección por canalización con ACL solo para `NT SERVICE\GPOS.Reportes` (ADR-41, nota del 2026-10-08) [V].
- Chromium sin `--no-sandbox` y sin extensiones (`ConvertidorPdf.cs:74`) [V].
- El plan ya prevé evidencia con solo nombres de variables (plan 4) y loopback para 5073 (plan 2.1) [V].

## 6. Remediaciones priorizadas

| Prioridad | IDs | Dónde | Esfuerzo [I, ±40 %] |
|---|---|---|---|
| 1 (antes de PR-V; solo texto del plan) | DM-01, DM-02, DM-03 | Plan 2.2, 2.3 y 5; diseño de PR-V | 0,1 dp |
| 2 (spike) | DE-10 a DE-16, DM-03 escalera, DM-07 | VM `VM-SRV` | dentro de los 0,5 dp del spike |
| 3 (PR-V) | DM-02 (1, 4), DM-05, DM-06, DM-07, DM-09, DM-13, DM-14 | `GPOS.Migracion` | +0,5 a 0,75 dp sobre lo planificado |
| 4 (API, PR pequeño) | DM-02 (2), DM-04 | `GPOS.Api` | 0,25 dp |
| 5 (PR-D2) | DM-02 (3), DM-08, DM-10, DM-12, DM-15 | Scripts del DEMO | dentro de PR-D2 |
| 6 (T4-01, B) | DM-11, DM-12 (salida) | `GPOS.Reportes.Api` (#152) | 0,25 a 0,5 dp |

## 7. Recomendación

**Opción (a) para P-3: aceptable solo en el DEMO, con las condiciones de este dictamen.** **El plan, tal como está escrito: Rechazado**, por tres hallazgos Altos (DM-01, DM-02, DM-03) que se cierran **sin código**, corrigiendo el texto del plan antes de PR-V. Con esa corrección, la recomendación pasa a **Aprobado con observaciones** (las Medias se verifican en el spike y en la revisión de PR-V y PR-D2). Es una recomendación técnica: la decisión es del propietario (C2).

---

### Cierre
- Estado: Rechazado (el plan en su redacción actual; pasa a Aprobado con observaciones al incorporar DM-01, DM-02 y DM-03). Opción (a) de P-3: aceptable solo en el DEMO, con condiciones.
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\dictamen-seguridad-demo-jwt-d5-2026-10-22.md`
- Supuestos: la DACL por omisión de las claves de servicio concede lectura a Usuarios; el Administrador de servicios lee `Environment` como SYSTEM y la principal no necesita leer su propia clave de registro; los hijos de PuppeteerSharp heredan el entorno; el perfil de la cuenta virtual se carga y DPAPI de usuario funciona; `TEMP` de la cuenta virtual puede resolver a una ruta compartida; costos ±40 %. Todos se confirman en el spike (DE-01, DE-10 a DE-16).
- Decisiones candidatas a ADR: (1) excepción K3-DEMO: `Jwt__Clave` en el entorno del servicio con DACL protegida, atada a `--perfil demo` + Amplio, con caducidad al llegar ES256 (ADR-41) o (c); alternativas descartadas: (b) por plazo y (c) por costo, que queda como camino para clientes; (2) anillo con certificado (H-17 v2) también en el DEMO con servicios, en lugar de `DpapiDemo` (alternativa descartada: ejecutar `GPOS.Migracion` bajo la cuenta virtual); (3) techo de privilegios SQL de la cuenta virtual en Amplio: `db_owner` por base y `dbcreator` solo justificado, nunca roles de servidor administrativos.
- Entregas a otros agentes: devops de A → corregir plan 2.2, 2.3 y 5 (DM-01, DM-02, DM-03, DE-10 a DE-16); arquitecto-software de A y desarrollador → PR-V con DM-02 (1, 4), DM-05, DM-06, DM-07, DM-09, DM-13 y DM-14; desarrollador (API) → DM-02 (2) y DM-04; arquitecto-software de B (T4-01, #152) → DM-11 y filtro de salida de Chromium (DM-12), respuesta a P-7; B/C → casos DE-10 a DE-16 en el spike; arquitecto-maestro → ADR candidatos (1) a (3); propietario → firma de la excepción con caducidad.
- Próximo paso recomendado: que devops de A incorpore DM-01, DM-02 y DM-03 al plan antes de empezar PR-V, y que el spike DE-01 incluya DE-10 a DE-16 sin conceder roles de servidor a la cuenta virtual.
