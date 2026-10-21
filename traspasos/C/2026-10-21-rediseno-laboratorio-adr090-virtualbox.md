```
Para: B (coordinador)        De: C (devops, OSHIN-LEGION)        Fecha: 2026-10-21
Tipo: Rediseño (hipervisor Hyper-V → VirtualBox, anfitrión LFMB)
Prioridad: Media
Repositorio y rama: no aplica (documento de diseño en el área común)
Estado: Abierto — respuesta requerida de B: tabla de memoria y fecha propuesta
```

# Rediseño del laboratorio de ADR-90 con VirtualBox en `LFMB`

- **Fecha:** 2026-10-21 · **Autor:** devops de C (OSHIN-LEGION), por encargo de B (`avisos/B-a-C/2026-10-21-virtualbox-en-lfmb-confirmado.md` y `avisos/B-a-C/2026-10-21-nuevas-tareas-para-c.md`, punto 1).
- **Tipo:** solo diseño de infraestructura de laboratorio. No se instaló VirtualBox, no se descargó ninguna imagen, no se ejecutó nada en `LFMB` ni en ninguna otra máquina.
- **No se tocó** `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md` (versión 3, firmada Q-LAB-01 a 03). Este documento lo complementa; donde hay contradicción, manda la decisión del propietario del 2026-10-21 citada en el aviso de B.
- **Base leída:** diseño v3 completo (secciones 1 a 13), el aviso de confirmación de VirtualBox y la cola de tareas del 2026-10-21.
- **Marcas:** [V] = verificado contra el diseño v3 o contra datos ya medidos por B. [I] = inferido o de conocimiento general sobre VirtualBox 7, no verificado contra la documentación oficial en esta sesión (no tuve acceso a una herramienta de búsqueda web al redactar este documento).

---

## 1. Tabla «bloque → VM necesaria → memoria mínima»

Memoria de referencia: `LFMB` tiene 13,9 GB totales y **4,4 GB libres** hoy con el trabajo de B. Las cifras de memoria por VM son estimaciones de piso para que el sistema invitado y el software declarado en la sección 3 del diseño v3 arranquen con margen de maniobra, no el mínimo técnico del fabricante del SO. Las marco [I] porque no las medí en `LFMB`; son el punto de partida para que B las ajuste con la primera VM real.

| Bloque (diseño v3) | VM necesaria | ¿Corren juntas? | Memoria mínima estimada [I] | Cabe en lo libre hoy (4,4 GB) |
|---|---|---|---|---|
| N (LAB-01 a LAB-23b, LAB-71 a LAB-79) | `VM-SRV` sola (fase 1, en memoria, sin Kestrel de prueba) | Sola | 3,0 a 3,5 GB (Windows Server 2025 Core o Desktop mínimo, sin SQL arrancado) | Sí, ajustado |
| N (LAB-80a, LAB-80c, LAB-22 — necesitan Kestrel de prueba en *loopback*) | `VM-SRV` sola | Sola | 3,0 a 3,5 GB | Sí |
| F (LAB-24 a LAB-31b, LAB-80a a LAB-80c, LAB-81, LAB-85) | `VM-SRV` sola (manipula almacenes de máquina; un proceso por caso, LS-11) | Sola | 3,0 a 3,5 GB | Sí |
| S (LAB-87 a LAB-90, oráculo) | `VM-SRV` sola | Sola | 3,0 a 3,5 GB | Sí |
| N-L (subconjunto en memoria: LAB-01-L a LAB-23a-L, LAB-28-L, LAB-71-L a LAB-80c-L, LAB-85-L) | `VM-LNX` sola (Ubuntu Server 24.04, sin escritorio) | Sola | 1,0 a 1,5 GB (servidor sin GUI, .NET 10 cargado) | Sí, con margen |
| N-L tramo Linux (LAB-24-L a LAB-26-L, LAB-91 a LAB-99, línea de órdenes OpenSSL) | `VM-LNX` sola | Sola | 1,0 a 1,5 GB | Sí |
| V (LAB-32 a LAB-36, LAB-35b/c, LAB-84, LAB-86 — fase 2) | `VM-SRV` **y** `VM-PUESTO` a la vez (servidor de sitio más estación/MAUI cliente) | **Dos VM simultáneas** | `VM-SRV` 3,5 a 4,5 GB (con SQL Server Express arrancado) + `VM-PUESTO` 3,5 a 4 GB = **7 a 8,5 GB** | **No** con lo libre hoy (4,4 GB); necesita liberar memoria en `LFMB` o cerrar el trabajo de B primero (ver sección 2) |
| R (LAB-37 a LAB-48 — fase 2, renovación sin reinicio) | `VM-SRV` **y** `VM-PUESTO` (sonda) a la vez | **Dos VM simultáneas** | Igual que V: 7 a 8,5 GB | **No** con lo libre hoy; igual condición que V |
| R-L (pendiente, pospuesto con el tramo Linux) | `VM-LNX` sola, cuando exista el mecanismo | Sola | 1,0 a 1,5 GB | Sí, cuando corresponda |
| B (LAB-49 a LAB-62, LAB-83 — navegadores) | `VM-SRV` (sirve los casos) **y** `VM-PUESTO` (navegadores) a la vez | **Dos VM simultáneas** | `VM-SRV` 3,0 a 3,5 GB (sin SQL, solo HTTP.sys) + `VM-PUESTO` 3,5 a 4 GB (con Edge/Chrome/Firefox abiertos, que pesan más que el sistema base) = **6,5 a 7,5 GB** | **No** con lo libre hoy |
| M (Android/iOS) | Ninguna VM de este laboratorio; declarado, fase móvil aparte | — | No aplica | No aplica |
| LAB-80a a LAB-80c, LAB-85 (dentro de F, repetidos aquí por claridad) | `VM-SRV` sola | Sola | 3,0 a 3,5 GB | Sí |

### 1.1 Resumen de los casos de dos VM a la vez

Solo tres bloques exigen `VM-SRV` + `VM-PUESTO` simultáneas: **V, R y B**. Todos son de fase 2 (V y R) o de fase 1 pero con cliente real (B). Con las estimaciones de arriba:

- **B** (navegadores, fase 1): 6,5 a 7,5 GB. **Cabe** en el techo de «unos 8 GB» que fijó B como máximo aceptable con dos VM a la vez, siempre que en ese momento `LFMB` no tenga además SQL Server local de B, WSL2 con carga pesada o Docker Desktop con contenedores corriendo. Con los 13,9 GB totales de `LFMB`, 7,5 GB para el laboratorio deja 6,4 GB para el sistema anfitrión y el resto de procesos; es ajustado pero factible **si B detiene su trabajo mientras corre el bloque B del laboratorio** (ya es la regla vigente: laboratorio y suites de B no corren a la vez).
- **V y R** (fase 2): 7 a 8,5 GB. El extremo alto (8,5 GB, con SQL Server Express arrancado en `VM-SRV`) **rebasa** el techo de 8 GB que fijó B. Ver sección 2 para la alternativa.

## 2. Lo que no cabe hoy y alternativas propuestas

**No asumo que todo cabe.** Con los datos que dio B (13,9 GB totales, 4,4 GB libres con su trabajo actual, techo de ~8 GB para dos VM a la vez), la situación es:

1. **Bloques N, F, S, N-L y la parte en memoria de B**: caben con una sola VM activa (3 a 3,5 GB para `VM-SRV` Windows, 1 a 1,5 GB para `VM-LNX`). Esto es compatible con los 4,4 GB libres **hoy**, sin que B tenga que liberar nada adicional, siempre que B no esté a la vez usando SQL Server local de forma intensiva.

2. **Bloque B (navegadores)**: 6,5 a 7,5 GB con dos VM. No cabe en los 4,4 GB libres actuales. Cabe en el techo de 8 GB **solo si B detiene temporalmente su trabajo** (ya es la regla acordada: laboratorio y suites de B no corren a la vez), liberando memoria hacia los 13,9 GB totales.

3. **Bloques V y R (fase 2)**: en el escenario con `VM-SRV` llevando SQL Server Express arrancado, la estimación sube a 8,5 GB, que **rebasa** el techo que fijó B. Tres alternativas, sin elegir por el propietario ni por B:
   - **(a) Recortar `VM-SRV` en V y R:** no arrancar SQL Server Express durante estos bloques salvo en los casos que lo necesiten explícitamente (la sección 1 del diseño v3 dice que las bases solo se crean en la fase 2, en `VM-SRV`, para los documentos fiscales de prueba; varios casos de V y R —por ejemplo, LAB-37 a LAB-48, que son renovación de certificado y no tocan datos— no necesitan SQL arrancado). Esto bajaría la estimación a 7 a 7,5 GB, dentro del techo de 8 GB. **Recomendado** como primera opción porque no pide nada a B ni al propietario.
   - **(b) Pedir más memoria a `LFMB`:** si B puede ampliar la RAM física (por ejemplo a 16 o 32 GB) o liberar memoria reservada por WSL2/Docker Desktop (el `.wslconfig` de WSL2 por omisión puede reservar hasta el 50 % de la RAM del anfitrión [I]; ajustar `memory=` en `.wslconfig` libera margen sin desactivar WSL2). Esto es una decisión de B/propietario sobre el equipo de B, no la impongo.
   - **(c) Excluir V y R de la fase 1 de `LFMB`** y ejecutarlos en otro anfitrión cuando exista uno con más memoria, dejando en `LFMB` solo N, F, S, N-L y B. Esto coincide, de hecho, con el orden de fases que ya fija el diseño v3 (V y R son fase 2, "después de que A construya"), así que no es un retraso adicional: para cuando V y R sean ejecutables, puede haber más claridad sobre la memoria disponible.

   Mi recomendación es **(a)** como ajuste de ejecución (no arrancar SQL salvo en los casos que lo necesiten) combinada con **(c)** como red de seguridad: si aun así algún caso puntual de V o R exige SQL Server Express arrancado junto con `VM-PUESTO`, ese caso puntual se ejecuta aparte, con B deteniendo su trabajo local primero y confirmando memoria libre real con el Administrador de tareas antes de levantar las dos VM.

4. **No cabe nunca en `LFMB` tres VM a la vez.** Esto ya lo advirtió B y lo diseño v3 ya no lo necesita: ningún bloque de la tabla de la sección 1 requiere `VM-SRV` + `VM-PUESTO` + `VM-LNX` simultáneas. El bloque N-L es independiente de N, F, S y B salvo que se decida comparar resultados en vivo, lo que el diseño v3 no pide (compara JSON generados por separado).

## 3. Reescritura de la sección 3 del diseño v3 («Entorno del laboratorio») para VirtualBox

> Esta sección sustituye, solo a los fines de la ejecución en `LFMB`, el texto de la sección 3 del diseño v3. El resto del diseño v3 (secciones 1, 2, 4 a 13) no cambia de contenido técnico; solo cambia el hipervisor y las rutas.

**Dónde corre:**
- **Anfitrión fijo: `LFMB`** (la PC del equipo B). Ya no es una lista de exclusión genérica ("nunca en la PC del propietario ni en OSHIN-LEGION"); ahora es un nombre de anfitrión conocido y verificable por guion.
- Hipervisor: **VirtualBox 7.x** (versión exacta a fijar por B al instalar; recomendado usar la misma rama 7.0.x o 7.1.x en todo el laboratorio para no mezclar comportamientos de `VBoxManage` entre versiones).
- Todas las VM y sus discos viven en **`M:\VM`** (547 GB libres, carpeta vacía hoy). No se usa `C:` (53 GB, insuficiente para tres imágenes de SO más discos de trabajo) ni ninguna ruta del perfil de usuario.
- Licencias: igual que en el diseño v3 (USD 0, imágenes de evaluación de Windows Server y Windows 11, Ubuntu libre) [I: plazos no revisados en esta sesión].
- **Nadie instala VirtualBox ni descarga las imágenes sin permiso expreso del propietario** (regla de B del 2026-10-21, punto 4 del aviso de confirmación); ese permiso lo pide B cuando este rediseño quede cerrado.

| VM | Sistema | Papel | Software | Carpeta en `M:\VM` |
|---|---|---|---|---|
| `VM-SRV` | Windows Server 2025 (compilación 26100), **sin vTPM garantizado** (ver 3.1), grupo de trabajo | Servidor de sitio | Runtime de ASP.NET Core 10.0 (10.0.12 o posterior); SQL Server 2022 Express; en la fase 2, el paquete único de B | `M:\VM\VM-SRV\` |
| `VM-PUESTO` | Windows 11 24H2 o posterior, grupo de trabajo | Puesto y cliente | Edge, Chrome, Firefox estable (≥ 120) y Firefox ESR; runtime de .NET 10; en la fase 2, el agente de impresión y MAUI en Windows | `M:\VM\VM-PUESTO\` |
| `VM-LNX` | Ubuntu Server 24.04 LTS, x64 | Cliente Linux | Runtime de .NET 10 y la OpenSSL de la distribución; sin interfaz gráfica | `M:\VM\VM-LNX\` |

### 3.1 vTPM de `VM-SRV`

- [I] VirtualBox 7.0 y posteriores incluyen emulación de **TPM 1.2 y TPM 2.0** mediante un TPM de software (basado en `swtpm`), configurable con `VBoxManage modifyvm <vm> --tpm-type host|1.2|2.0 --tpm-location <ruta>`. No verifiqué esto contra la documentación oficial de Oracle en esta sesión (no tuve acceso a una herramienta de búsqueda web); lo marco `[I]` y pido a B que lo confirme con la versión exacta de VirtualBox que instale antes de que el laboratorio dependa de ello.
- **Qué depende del vTPM en el diseño v3:** revisé las secciones 1 a 13 del diseño v3 y **ningún caso del bloque N, F, S o R usa el vTPM como parte de la prueba**. El vTPM aparece en la tabla de VM del diseño v3 (sección 3 original) como atributo de `VM-SRV` ("generación 2, vTPM"), heredado de que Hyper-V exige un vTPM para ciertas configuraciones de generación 2 y porque el producto real usa un TPM físico para la llave de la CA en instalaciones reales (ADR-53, nota de la sección 9 del diseño v3: "la CA del sitio nunca podrá emitir certificados de cliente... ADR-53 autentica el nodo con la llave del TPM"). **El laboratorio de ADR-90, tal como está diseñado, no ejercita ese camino del TPM**: las llaves de las CA de prueba son efímeras y las de las hojas son no exportables en el proveedor de software (sección 3 del diseño v3, "Llaves de las CA" y "Llaves de las hojas"), no en el TPM.
- **Conclusión:** el vTPM de `VM-SRV` **no es un requisito duro** para ejecutar los casos LAB-01 a LAB-99 tal como están redactados. Si VirtualBox 7 no emula TPM 2.0 de forma satisfactoria, o si B prefiere no activarlo, **se puede quitar sin perder ningún caso del alcance actual**. Si en el futuro se diseña un caso que sí dependa del TPM (por ejemplo, para probar el camino real de ADR-53), eso se declara aparte y se verifica el soporte de VirtualBox en ese momento.

### 3.2 Red

- Igual que el diseño v3: red **interna** sin salida a Internet durante los casos, salida solo para preparar las VM.
- Equivalente de VirtualBox: una red interna (`--intnet`) llamada `GPOS-LAB`, creada con `VBoxManage modifyvm <vm> --nic1 intnet --intnet1 GPOS-LAB` en las tres VM. VirtualBox no trae DHCP en una red interna pura salvo que se configure un servicio DHCP de VirtualBox (`VBoxManage dhcpserver add --netname GPOS-LAB ...`); como el diseño v3 ya fija direcciones estáticas y usa `hosts` sin servidor DNS, **no se necesita DHCP**: cada VM se configura con IP estática dentro del invitado, igual que con Hyper-V.
- Direcciones y nombres: sin cambios respecto al diseño v3 (`VM-SRV` `192.168.50.10/24` + `.11` y `fd00:50::10/64`; `VM-PUESTO` `.20`; `VM-LNX` `.30`; mismos nombres en `hosts`).
- Para preparar las VM con salida a Internet temporal, se añade un segundo adaptador NAT (`--nic2 nat`) que se desactiva (`VBoxManage modifyvm <vm> --nic2 none` o simplemente se apaga el adaptador desde la VM) antes del punto de control base, igual que el diseño v3 retira la salida antes de empezar los casos.

### 3.3 Reloj de las VM (bloque R)

Reemplazo punto por punto del procedimiento de Hyper-V:

1. **Desactivar la sincronización de hora con el anfitrión:** en VirtualBox, el componente que sincroniza la hora del invitado con el anfitrión es el servicio de **Guest Additions** (`VBoxService`, módulo de sincronización de tiempo). Se desactiva con `VBoxManage guestproperty set <vm> "/VirtualBox/GuestAdd/VBoxService/--disable-timesync" 1` antes de arrancar la VM, o deteniendo el módulo correspondiente dentro del invitado (en Windows, el servicio "VBoxService" con el parámetro de sincronización de tiempo deshabilitado; en Linux, `VBoxClient --timesync` no se inicia). [I: la propiedad exacta de invitado puede variar entre versiones 7.0.x y 7.1.x; B debe confirmar con `VBoxManage guestproperty enumerate <vm>` tras instalar las Guest Additions].
2. En las VM, igual que el diseño v3: dejar `w32time` detenido y deshabilitado en Windows; en Linux, `timesyncd` o `chronyd` detenidos y deshabilitados (equivalente de "sin reajuste automático").
3. Mover el reloj con `Set-Date` (Windows) o `date -s` (Linux) en una consola elevada dentro del invitado, sin cambios respecto al diseño v3.
4. **Volver atrás:** solo restaurando un **punto de control** (ver 3.4), salvo en LAB-46, igual que el diseño v3.
5. Puntos de control en `T0`, `T0+50 d` y `T0+61 d`, sin cambios.
6. Si el RTC virtual de VirtualBox reajusta la hora al arrancar la VM [I: no verificado; VirtualBox normalmente respeta la hora que tenía el invitado al apagarse, salvo que la sincronización de tiempo esté activa], se aplica la misma salvaguarda del diseño v3: servicios en inicio manual y la tarea "al iniciar" lanzada con `schtasks /run` (Windows) o el equivalente `systemctl start` (Linux).

### 3.4 Puntos de control (equivalente de las instantáneas de Hyper-V)

- VirtualBox llama a esto **snapshots**. Equivalente de `Checkpoint-VM`: `VBoxManage snapshot <vm> take "<nombre>" --description "<texto>"`.
- Restaurar: `VBoxManage snapshot <vm> restore "<nombre>"` (la VM debe estar apagada).
- Listar: `VBoxManage snapshot <vm> list`.
- Borrar (limpieza por marcador, equivalente a lo que hace `Limpiar-Laboratorio.ps1` con las instantáneas obsoletas): `VBoxManage snapshot <vm> delete "<nombre>"`.
- El diseño v3 fija los puntos de control del bloque R en `T0`, `T0+50 d` y `T0+61 d`; con VirtualBox se nombran igual (`T0`, `T0+50d`, `T0+61d`) para que `Recoger-Evidencia.ps1` y los guiones de limpieza los identifiquen por nombre, no por mecanismo.
- **Diferencia a tener en cuenta:** las instantáneas de VirtualBox, a diferencia de los puntos de control de Hyper-V con disco diferencial por omisión en todos los casos, también usan discos diferenciales (`.vdi` o `.vmdk` hijos) y pueden acumular espacio si no se consolidan; con 547 GB libres en `M:`, esto no es un problema de espacio para el alcance de este laboratorio, pero B debe borrar las instantáneas obsoletas al cerrar cada fase (ya lo pide el diseño v3 en la sección 7.2, `Limpiar-Laboratorio.ps1`).

### 3.5 Convivencia con WSL2 y Docker Desktop en `LFMB`

- WSL2 usa el **mismo hipervisor subyacente de Windows (Hyper-V/WHP — Windows Hypervisor Platform)**, no VirtualBox. VirtualBox 7 puede ejecutarse en Windows 11 **con** Hyper-V/WHP activo usando su backend nativo de ejecución (NEM — Native Execution Manager), aprovechando las extensiones de virtualización de la misma forma en que lo hace WHP, en lugar de requerir acceso exclusivo al VT-x/AMD-V del procesador [I: esto cambió con VirtualBox 6.0+ precisamente para convivir con Hyper-V/WSL2/Docker Desktop; antes de esa versión, VirtualBox y Hyper-V eran mutuamente excluyentes]. **No se requiere desactivar WSL2 ni Docker Desktop** para instalar o correr VirtualBox 7 en `LFMB`.
- **Efecto esperado:** con el backend NEM, el rendimiento de las VM de VirtualBox puede ser algo menor que con acceso exclusivo al hardware de virtualización (overhead adicional de la capa de WHP) [I], pero es la única combinación viable dado que B ya usa WSL2 y Docker Desktop y el propietario no autorizó desactivarlos. Esto es compatible con la condición de B de "no se desactiva [WSL2/Docker] sin que [devops] diga el efecto esperado": el efecto esperado es una posible penalización de rendimiento, no una incompatibilidad.
- **Memoria:** Docker Desktop con WSL2 reserva memoria dinámica según `.wslconfig` (por omisión hasta el 50 % de la RAM física en versiones recientes de WSL2 [I]). Esto es relevante para la sección 2: si B no ha fijado un tope en `.wslconfig`, parte de los "4,4 GB libres" medidos hoy pueden fluctuar según la carga de los contenedores activos. Recomiendo que B confirme un tope fijo en `.wslconfig` (por ejemplo `memory=4GB`) antes de que C o quien ejecute el laboratorio dependa de la cifra de 4,4 GB libres como constante.

### 3.6 Guarda del anfitrión: `Preparar-Anfitrion.ps1`

- Cambia de una **lista de exclusión** ("nunca en la PC del propietario ni en OSHIN-LEGION") a una **comprobación positiva de un nombre fijo**: el guion ahora comprueba que `$env:COMPUTERNAME` (o `(Get-CimInstance Win32_ComputerSystem).Name`) sea exactamente `LFMB`; si no lo es, se detiene con un mensaje claro, sin excepciones ni lista.
- Mismo principio de seguridad que antes (falla cerrada: si la comprobación no puede confirmar el nombre, el guion no continúa), pero invertido: antes bastaba con no estar en una lista corta; ahora hace falta coincidir con el único nombre admitido.
- El resto de guardas del diseño v3 (LS-11: `GPOS_LAB_TLS_VM=1`, marcador en el registro o en `/etc/gpos-ng/laboratorio-tls/id`, comprobación de virtualización con `Win32_ComputerSystem` o `systemd-detect-virt`) **no cambian**: siguen operando dentro de cada VM invitada, que es independiente del hipervisor del anfitrión.

### 3.7 CA y certificados de prueba (oráculo)

Sin cambios respecto al diseño v3: el oráculo corre **dentro de las VM** y no depende del hipervisor. Las reglas de llaves efímeras, llaves no exportables, marcador `O=GPOS-LAB-TLS` y nunca escribir un PFX a disco siguen igual.

### 3.8 Evidencia común

Sin cambios de contenido; solo cambia que los volcados de configuración de red y reloj citan `VBoxManage showvminfo <vm>` en vez de `Get-VM` / `Get-VMIntegrationService` de Hyper-V.

---

## 4. Quién ejecuta y cómo (decisión abierta, no elegida aquí)

El aviso de B deja esto expresamente como pregunta abierta para B y el propietario. Enumero opciones sin elegir:

1. **El QA de A opera por escritorio remoto a `LFMB`.** Ventaja: A ya es quien construye el verbo y el validador (sección 7.4 del diseño v3, "qa de A con devops de B" para la ejecución de las fases 1 y 2), así que tiene contexto técnico directo. Riesgo: dos personas con acceso remoto al equipo de trabajo diario de B (Escritorio remoto de Windows, o una herramienta como RDP/VNC) exige que B abra ese acceso y que quede fuera del horario en que B necesita `LFMB` para sí mismo (regla vigente: laboratorio y suites de B no corren a la vez).
2. **B ejecuta los guiones y A solo revisa evidencia.** Ventaja: nadie externo opera la máquina física de B; se respeta mejor "agentes sin ventanas ni instalaciones" fuera de la máquina del propio dueño. Riesgo: depende de la disponibilidad de B para ejecutar cada fase, y B ya tiene su propia carga de trabajo (coordinación e integración de la ola 5, revisiones pendientes).
3. **Acceso remoto acotado solo para las fases del laboratorio, con una cuenta de Windows separada en `LFMB`** (no la cuenta de trabajo diario de B), que A usa solo cuando B confirma que `LFMB` está libre. Combina lo anterior: aísla el acceso remoto de la sesión de trabajo de B, pero sigue dependiendo de la ventana de tiempo libre que B señale.

No elijo ninguna: la decide B con el propietario, como pide el aviso.

## 5. Guiones de `tests/laboratorio-adr090/` (sección 7.2 del diseño v3): qué cambia y qué no

| Guion | Cambia / Igual | Detalle |
|---|---|---|
| `Preparar-Anfitrion.ps1` | **Cambia** | Comprobación positiva de `LFMB` en vez de lista de exclusión (sección 3.6 de este documento). |
| `Preparar-Vm.ps1` y `preparar-vm.sh` | Igual en su lógica interna (marcador, CAPI2, `w32time`, `hosts`); **cambia** solo si alguna línea invocaba cmdlets de Hyper-V para preparar la VM desde el anfitrión (no detecté ninguna en el texto citado del diseño v3; si las hay al escribir el guion real, se reemplazan por `VBoxManage` equivalente). |
| `Servir-CasosNavegador.ps1` | Igual | Corre dentro de `VM-SRV`; no depende del hipervisor. |
| `Adelantar-Reloj.ps1` | **Cambia** | Hoy "comprueba el nombre de la VM"; además debe desactivar la sincronización de tiempo de VirtualBox (sección 3.3, punto 1) antes de mover el reloj, paso que con Hyper-V se hacía con `Get-VMIntegrationService` **desde el anfitrión**, fuera de este guion. Con VirtualBox, ese paso puede hacerse desde el anfitrión (`VBoxManage guestproperty set`) o quedar documentado como prerrequisito manual antes de ejecutar este guion dentro de la VM; a decidir por quien lo escriba. |
| `Sondear-Certificado.ps1` | Igual | Corre dentro de `VM-PUESTO`; no depende del hipervisor. |
| `Recoger-Evidencia.ps1` | **Cambia (ligero)** | Donde recoja datos de configuración de VM (si los recoge) debe usar `VBoxManage showvminfo` en vez de cmdlets de Hyper-V. Si solo recoge evidencia generada dentro de los invitados (JSON, CAPI2, capturas), no cambia. |
| `limpiar-laboratorio.sh` | Igual | Corre dentro de `VM-LNX`; no depende del hipervisor. |
| `Limpiar-Laboratorio.ps1` | Igual en su lógica (retira marcador de almacenes, vinculaciones HTTP.sys, `hosts`, caché de CryptoAPI); **el paso nuevo** de restaurar el punto de control base usa `VBoxManage snapshot restore` en vez de `Restore-VMCheckpoint`, pero eso lo invoca quien orquesta la fase desde el anfitrión, no necesariamente el guion mismo (a confirmar con quien lo escriba, según si el guion corre dentro o fuera de la VM).

Nuevo en el equivalente de Hyper-V que **no existe como guion propio** en el diseño v3 pero conviene anotarlo: el paso "desactivar/activar la sincronización de hora del anfitrión" (`Get-VMIntegrationService` en el diseño v3 original) no es un guion de prueba sino una orden del anfitrión antes de arrancar la VM; su equivalente de VirtualBox (`VBoxManage guestproperty set .../--disable-timesync`) debe documentarse en el mismo lugar donde se documentaba para Hyper-V (sección 3 de este documento, apartado 3.3), no necesariamente como un guion `.ps1` nuevo.

---

## 6. Resumen para el propietario y para B

- **¿Cabe el laboratorio completo en `LFMB`?** Parcialmente. Los bloques N, F, S, N-L y el bloque B (navegadores, con B deteniendo su trabajo) caben con los recursos descritos. **Los bloques V y R (fase 2) no caben con seguridad** en el techo de ~8 GB que fijó B si `VM-SRV` lleva SQL Server Express arrancado a la vez que `VM-PUESTO`; la alternativa recomendada es no arrancar SQL salvo en los casos puntuales que lo exigen, y aun así confirmar memoria libre real antes de cada ejecución.
- **vTPM:** no hay evidencia de que ningún caso del alcance actual (LAB-01 a LAB-99) dependa del TPM; se puede prescindir de él en `VM-SRV` sin perder cobertura, sea o no que VirtualBox 7 lo emule bien [I].
- **Reloj y puntos de control:** tienen equivalente directo en VirtualBox (`VBoxManage guestproperty`, `VBoxManage snapshot`); no hay bloqueo técnico.
- **WSL2/Docker:** no hace falta desactivarlos; conviven con VirtualBox 7 en Windows 11 vía el backend NEM, con posible penalización de rendimiento [I].
- **Abierto:** quién ejecuta el laboratorio (sección 4) y la confirmación de B sobre si VirtualBox 7 emula TPM 2.0 de forma utilizable, aunque esto último ya no bloquea nada porque ningún caso lo necesita.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-21-rediseno-laboratorio-adr090-virtualbox.md` (nuevo)
- Supuestos: (1) Las cifras de memoria por VM son estimaciones de piso [I], no medidas en `LFMB`; B debe confirmarlas con la primera VM real. (2) VirtualBox 7 emula TPM 2.0 vía `swtpm` y convive con Hyper-V/WHP mediante el backend NEM: ambos puntos son [I], de conocimiento general, no verificados contra documentación oficial de Oracle en esta sesión (no tuve acceso a una herramienta de búsqueda web). (3) Ningún caso del alcance actual del laboratorio (LAB-01 a LAB-99) depende del vTPM, según la lectura del diseño v3 completo.
- Decisiones candidatas a ADR: Ninguna (esto es diseño de infraestructura de laboratorio, no arquitectura del producto).
- Entregas a otros agentes: B (coordinador) → confirmar con la instalación real de VirtualBox 7 en `LFMB` si el vTPM funciona y las cifras de memoria de la sección 1, y decidir con el propietario la opción de la sección 4 (quién ejecuta); auditor-seguridad → cuando B instale VirtualBox, revisar si la convivencia con WSL2/Docker Desktop (sección 3.5) introduce algún vector nuevo antes de autorizar la instalación.
- Próximo paso recomendado: B pide al propietario el permiso expreso para instalar VirtualBox 7 y descargar las tres imágenes (Windows Server 2025, Windows 11, Ubuntu 24.04 LTS), confirmando antes el tope de `.wslconfig` para no competir por memoria con WSL2/Docker.
```
