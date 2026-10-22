```
Para: B        De: C (devops)        Fecha: 2026-10-22
Tipo: Entrega (tarea 3 del aviso 2026-10-21: casos de laboratorio para Chromium y las comprobaciones R1 a R10 del paquete único)
Prioridad: Media
Repositorio y rama: no aplica (diseño en el área común); los guiones irían en `tests/laboratorio-adr090/` (PR #146) o en un directorio hermano
Estado: Abierto (casos redactados; nada ejecutado)
```

# Casos de laboratorio: Chromium bajo la cuenta del servicio y comprobaciones R1 a R10 del paquete único

- **Qué es:** diseño de casos para el laboratorio en `LFMB` con VirtualBox (rediseño del 2026-10-21, PR #146). **No se instaló ni se ejecutó nada**; no leí código de Chromium/PuppeteerSharp de la API de reportes (aún no existe en `feature/modelo-ng`; lo traslada T4-01).
- **Fuentes leídas:** `docs/operaciones/2026-10-19-diseno-instalador-reportes.md` (§3, §4.1 R1 a R10, §10 y §13), plan del tramo 4 (T4-01, T4-03, R-T4-07, H-T4-09), `traspasos/C/2026-10-21-rediseno-laboratorio-adr090-virtualbox.md` (VM, memoria, guarda `LFMB`).
- **Marcas:** [V] verificado en un documento leído; [I] inferido o de conocimiento general, sin verificar contra la documentación del fabricante; [?] depende de algo que no existe todavía.

## 0. Reglas de este laboratorio (heredadas)
- Solo en `LFMB`, con `Preparar-Anfitrion.ps1` (comprobación positiva del nombre y de la memoria libre real). Nunca en la PC del propietario ni en OSHIN-LEGION.
- **Una VM a la vez** para todo este documento: `VM-SRV` sola (Windows Server 2025, sin escritorio de usuario salvo el bloque CH-E). Memoria: 3,0 a 3,5 GB sin SQL; **3,5 a 4,5 GB con SQL Express arrancado** (casos que lo marcan).
- Punto de control base antes de cada caso y por caso (guiones `Puntos-Control.ps1`); evidencia con redacción de secretos (`Recoger-Evidencia.ps1`). Reloj de la VM sin sincronizar con el anfitrión (`Ajustar-Reloj.ps1`).
- Credenciales de la VM: fuera del repositorio; el guion las pide con `Leer-Credencial.ps1`.
- Los MSI y el *bundle* se instalan **solo en la VM** (la regla de que agentes no ejecutan MSI es sobre la PC del propietario, no sobre una VM aislada del laboratorio; B ejecuta, C no).

## 1. Bloque CH: Chromium bajo la cuenta virtual del servicio (R-T4-07, H-T4-09, T4-03)

**Contexto [V]:** la API de reportes (`NT SERVICE\GPOS.Reportes`, cuenta virtual, `SeChangeNotifyPrivilege` como único privilegio) hospedará Chromium vía PuppeteerSharp. El plan señala el riesgo R-T4-07: *sin Edge ni Chrome en el servidor, perfil sin permisos, o sandbox que no arranca* [V]; en Windows Server, Edge no siempre está instalado [I]. T4-03 exige Chromium sin red (solo `data:`).

### 1.1 Precondiciones (no son casos; son datos que el laboratorio debe fijar)
| P | Qué fijar | Por qué |
|---|---|---|
| P-CH-1 | **¿De dónde sale el Chromium?** Edge instalado, Chrome instalado, o un Chromium descargado por PuppeteerSharp a una carpeta propia | Cada origen cambia los casos CH-01..CH-06. El diseño de T4-01 no lo dice en lo que leí; **B/A deben fijarlo** (pregunta Q-1) |
| P-CH-2 | Carpeta del perfil/`user-data-dir` y su ACL | La cuenta virtual no tiene perfil de usuario; el perfil debe vivir bajo `%ProgramData%\GPOS NG\Reportes\...` con la DACL de ADR-77 |
| P-CH-3 | Argumentos de arranque (`--no-sandbox` sí/no, `--disable-gpu`, `--headless=new`, `--remote-debugging-pipe`) | `--no-sandbox` desactiva la defensa principal del navegador; **no debe aceptarse sin decisión firmada** (Q-2) |

### 1.2 Casos

| ID | Caso | Cómo (resumen) | Resultado esperado | Marca |
|---|---|---|---|---|
| CH-01 | **Sin ningún navegador en el servidor** | Server limpio, sin Edge/Chrome ni carpeta descargada; arrancar la API de reportes | La API **arranca** (el render no es de arranque) y la comprobación del paquete informa «sin navegador» como **fallo crítico claro** (no un 500 al primer render); `/api/salud` indica render no disponible | [?] según Q-1 |
| CH-02 | **Edge presente, perfil sin permisos** | Instalar Edge; cuenta del servicio sin permiso de escritura en el `user-data-dir` | Render falla con error definido (503 `RENDER_NO_DISPONIBLE`), evento crítico con causa «perfil», **no** crea perfil en `C:\Users\...` ni en `%TEMP%` de otra cuenta | [I] |
| CH-03 | **Perfil con permisos correctos** | `user-data-dir` en `%ProgramData%\GPOS NG\Reportes\render` con ACL de la cuenta | Render de un ticket de 80 mm y de una factura Carta responde; el perfil no queda con archivos legibles por otra cuenta (`icacls` sobre la carpeta tras 20 renders) | [I] |
| CH-04 | **Sandbox de Chromium bajo la cuenta virtual** | Arrancar sin `--no-sandbox` | Documentar: ¿arranca el sandbox bajo `NT SERVICE\...` con solo `SeChangeNotifyPrivilege`? Si **no**, el caso termina con evidencia y B decide (Q-2) | [I]: no sé si arranca; es justo lo que el caso averigua |
| CH-05 | **Con `--no-sandbox` (solo si CH-04 falla)** | Repetir con el argumento y con el contenido controlado | Registrar riesgo residual; el caso pasa a «aceptado con condiciones» solo si el contenido que renderiza es **solo `data:` generado por la API** (T4-03). Nunca se acepta con URLs externas | [I] |
| CH-06 | **Cuenta del servicio no puede lanzar procesos de otro usuario ni abrir ventanas** | Intentar render con sesión de usuario cerrada y sin escritorio interactivo (servicio en sesión 0) | Render funciona en *headless* sin escritorio; no aparece ventana en la consola de la VM | [I] |
| CH-07 | **Aislamiento de red (T4-03, H-T4-09)** | Plantilla con `<img src="http://10.0.2.2/x.png">` y `<link href=...>`, con la red interna `GPOS-LAB` sin salida | La petición **no sale**: ningún paquete al anfitrión (captura en `VM-SRV`), la plantilla se renderiza con la imagen rota; evento de bloqueo registrado | [?] T4-03 no construido |
| CH-08 | **Regla de cortafuegos de salida por servicio (R7)** | Probar con la regla de salida del *bundle* y sin ella | Con regla: Chromium y el proceso no abren conexiones salientes (solo SQL local); sin regla: el caso documenta qué saldría (es evidencia, no un fallo) | [I] |
| CH-09 | **Huérfanos** | Matar el proceso de la API en pleno render (`taskkill /f`) y luego reiniciar el servicio | No quedan procesos `chrome`/`msedge` huérfanos; el reinicio no se bloquea por el perfil ocupado (`SingletonLock`) | [I] |
| CH-10 | **Memoria bajo `HeapHardLimit` de 768 MB** | 50 renders seguidos de Carta y 200 de 80 mm; medir memoria del proceso de la API **y** de Chromium | Reportar ambos por separado (el límite de 768 MB aplica solo al proceso .NET, no a Chromium); detectar fuga (memoria creciente) | [I] mide R-T4-03; no sustituye `MedicionRender` de B |
| CH-11 | **Concurrencia** | 10 renders simultáneos de usuarios distintos | Ninguno mezcla contenido; el grupo de concurrencia del render (T4-01) devuelve 429 al exceder; los 30 s se cumplen | [?] |
| CH-12 | **Cuenta virtual sin red de dominio / sin cuenta de usuario** | VM sin dominio, sin sesión | El render funciona igual; no depende de credenciales de usuario ni de la red | [I] |
| CH-13 | **Actualización del navegador** | Actualizar Edge/Chrome a una versión más nueva (si es posible en la VM) | La API sigue renderizando o falla con error claro de versión incompatible con PuppeteerSharp; documentar la versión mínima/máxima | [I] |
| CH-14 | **Desinstalación** | Desinstalar el *bundle* | No quita `ProgramData\GPOS NG`; el perfil de render queda o se limpia según lo decidido (ver pregunta Q-4) | [?] |

### 1.3 Qué NO prueba este bloque
- Contenido del PDF (lo cubren los dorados de T4-01).
- Rendimiento oficial (`MedicionRender` corre sola en `LFMB`, con la memoria del proceso).
- Linux (`VM-LNX`): Chromium bajo `systemd` con usuario de servicio es otro bloque; no entra en esta entrega.

## 2. Bloque PK: comprobaciones R1 a R10 del paquete único

**Contexto [V]:** las diez comprobaciones están en el diseño del paquete (§4.1) y las ejecuta `GPOS.Migracion comprobar-servidor --estricto` al final del *bundle*. El diseño marca **«Probado: no»** el comportamiento exacto de Burn (reversión, reinicios, `Permanent`, límites) y deja explícitamente como **laboratorio elevado** `sc qprivs`, `icacls`, cortafuegos, orden de arranque, reversión por paso, recuperación del servicio, *roll-forward* y actualización [V, §10].

**Dependencia dura [?]:** nada de este bloque se puede ejecutar hasta que existan `GPOS.Reportes.msi` (la v1, `instalador/Reportes`, existe en parte), `GPOS.Api.msi` (**no existe hoy** [V, §2.2]), el *bundle* y los verbos `implantar-servidor`/`comprobar-servidor` (**no existen**). Los casos están redactados para que cuando existan se ejecuten sin rediseñar. Mientras tanto, el único insumo ejecutable ya es la v1 `GPOS.Reportes.msi` con R1 a R4 y R6 a R8.

### 2.1 Una columna por comprobación: casos positivo y negativo
Cada comprobación necesita **dos** casos: el estado correcto (debe dar `OK`) y **una violación inducida** (debe dar `FALLA` con el código de salida 4 y el EventId definido). Una comprobación que no se prueba con su violación puede estar siempre verde.

| ID | Comprobación (R) | Caso positivo | Violación inducida (debe dar FALLA) | Marca |
|---|---|---|---|---|
| PK-R1a / R1b | R1 `sc qprivs` solo `SeChangeNotifyPrivilege` | Instalado por el MSI | `sc privs GPOS.Reportes SeChangeNotifyPrivilege/SeImpersonatePrivilege` ⇒ R1 FALLA, servicio detenido, marca quitada | [V] diseño §3.3; [I] el comportamiento de `sc privs` |
| PK-R2a / R2b | R2 cuenta, inicio diferido, SID sin restricción | Instalado | `sc config` a `LocalSystem`; `sc sidtype ... restricted` | [I] |
| PK-R3a / R3b | R3 `icacls` de `ProgramData\GPOS NG`, `\Reportes`, `\config` = vector v2 de ADR-77, sin puntos de reanálisis | Instalado | Agregar `Users:(W)` en `\config`; crear una unión (`mklink /J`) dentro de `\Reportes` | [V] vector `adr077-carpetas.v2.json` |
| PK-R4a / R4b | R4 solo `127.0.0.1:{puerto}`; la canalización es de la cuenta del servicio | Instalado | Cambiar el `urls` a `0.0.0.0`; crear la canalización con otra cuenta propietaria | [I] |
| PK-R5a / R5b | R5 `/api/salud` 200 con versión y `VersionContrato` | Instalado | Bajar `rpt.VersionContrato` en la base; levantar un binario de versión distinta | [?] cambio aditivo de `/api/salud` pendiente (nota del diseño) |
| PK-R6a / R6b | R6 sin eventos 5112 a 5116 y 5106 en 15 min | Arranque limpio | Provocar un 5113 (por ejemplo, sin la marca de arranque) y ver que R6 lo ve; probar también que un evento **viejo (>15 min)** ya no cuenta | [V] números de evento del diseño; [I] el filtro por tiempo |
| PK-R7a / R7b | R7 regla de cortafuegos de salida ligada al servicio | Con la regla del *bundle* | Borrar la regla (`netsh advfirewall`) ⇒ FALLA; regla con otro programa ⇒ FALLA | [I] |
| PK-R8a / R8b | R8 variables de entorno y archivo de instalación sin cadenas con credenciales | Instalado | Añadir `ConnectionStrings__X=...;Password=...` al entorno del servicio; añadir una clave en `config\*.json` | [V] T-4 del diseño |
| PK-R9a / R9b | R9 `GPOS.Migracion verificar --estricto` = 0 | Esquema y roles correctos | `sa` habilitado, un usuario con permiso de escritura en `gpos_lec`, versión de esquema atrasada, compatibilidad ≠ 130 | [V] lista del diseño; **con SQL Express arrancado** (3,5 a 4,5 GB) |
| PK-R10a / R10b | R10 reporte 1 y uno del diseñador responden 200 con datos; ninguna escritura posible | Con datos de prueba | Dar `INSERT` al rol de lectura ⇒ R10 debe fallar al intentar escribir; quitar permisos de lectura ⇒ 403/500 explícito | **SQL Express arrancado**; [?] O-8 (dónde vive la comprobación) |

### 2.2 Ensayos de Burn (explícitamente «probados: no» en el diseño §3.3)
| ID | Caso | Esperado según el diseño | Marca |
|---|---|---|---|
| PK-B1 | Falla del MSI 2 (`GPOS.Reportes.msi`) en el paso 3 | Windows Installer revierte ese MSI; Burn revierte `GPOS.Api.msi` (un solo `RollbackBoundary`); sin servicios, sin marca | [I] **inferido por el diseño**; este caso es el ensayo |
| PK-B2 | Falla en el paso 4 (credenciales) | Los MSI **no** se revierten; servicios detenidos y **sin marca**; `Reintentar` y `Reparar` reejecutan el paso 4 idempotente | [I] |
| PK-B3 | Falla en el paso 5 (arranque) | Servicios detenidos por el *bundle*; la marca permanece | [I] |
| PK-B4 | Falla crítica en el paso 6 | `GPOS.Reportes` detenido, **marca quitada**, resultado «No listo»; falla cerrada | [I] |
| PK-B5 | Reinicio del equipo a mitad del *bundle* | Burn reanuda o limpia; documentar cuál | [I] **desconocido**, el diseño lo declara no probado |
| PK-B6 | Degradación (`DowngradeErrorMessage`) | Se niega instalar una versión menor | [I] |
| PK-B7 | Orden de actualización «parar → respaldo → migrar → reportes → principal → verificar» y *roll-forward* tras fallo del paso migrar | Estado final siempre seguro (§3.3, §5.2) | [I] |
| PK-B8 | Desinstalación conjunta | No quita bases, `ProgramData\GPOS NG`, anillo ni licencia (B-12) | [V] diseño §6 |

### 2.3 Orden de ejecución propuesto (una VM a la vez)
1. Punto de control `base-limpia` (Server sin nada).
2. PK-R1..R4, R6..R8 con la v1 de `GPOS.Reportes.msi` (lo único que existe hoy).
3. Con el *bundle*: PK-B1..B4, luego PK-R5, R9, R10 (con SQL).
4. CH-01..CH-06 y CH-08..CH-09 (sin SQL).
5. PK-B5..B8 al final (los destructivos), cada uno desde `base-limpia`.
6. CH-10 y CH-11 al final, solos (miden memoria).

## 3. Estimación y dependencias
| Bloque | Casos | Esfuerzo de escribir los guiones [I] | Depende de |
|---|---|---|---|
| CH | 14 | ~1,0 dp | P-CH-1 (origen de Chromium), T4-01/T4-03 construidos |
| PK-R | 20 (10 × 2) | ~1,2 dp | verbo `comprobar-servidor` y el *bundle* |
| PK-B | 8 | ~0,8 dp | el *bundle* con `RollbackBoundary` |
Total ≈ 3,0 dp (±50 %) **de C**, a escribir después de que existan los instaladores; hoy están redactados los casos, no los guiones. Memoria: todos caben con `VM-SRV` sola (≤ 4,5 GB con SQL). **Ninguno necesita `VM-PUESTO`.** Fecha del aviso: antes del 20-nov; el laboratorio fase 1 debe estar listo antes de RT-02 (2026-11-23).

## 4. Preguntas para B
- **Q-1.** ¿De dónde sale Chromium en el servidor: Edge/Chrome instalado, o descargado por PuppeteerSharp a una carpeta propia? Cambia CH-01, CH-13 y el instalador (¿lo trae el MSI?).
- **Q-2.** ¿Se acepta `--no-sandbox` si el sandbox no arranca bajo la cuenta virtual (CH-04/CH-05), con la condición de «solo `data:`»? Es una decisión de seguridad; recomiendo que la tome el propietario con el auditor.
- **Q-3.** PK-R5/R10 dependen de O-8: ¿la comprobación vive en `verificar` ampliado o en `comprobar-servidor`?
- **Q-4.** CH-14: el perfil de render ¿se borra al desinstalar o se conserva como datos?
- **Q-5.** ¿Hay una imagen de Windows Server 2025 **con Edge** y otra sin él, o se instala en la VM? El laboratorio necesita ambas para CH-01 y CH-02.

## 5. Lo que no verifiqué
- Nada se ejecutó. Los comportamientos de `sc`, Burn, Chromium en sesión 0, el sandbox y el cortafuegos son [I]: **conocimiento general, no comprobado aquí ni contra documentación oficial** (no hubo acceso a documentación en esta sesión).
- No leí `GPOS.Migracion` ni el código de la API de reportes (el render no está trasladado); los verbos y eventos son los del diseño.
- No confirmé la lista de eventos 5101 a 5122 contra el código.
