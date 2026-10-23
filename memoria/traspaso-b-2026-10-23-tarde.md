---
name: traspaso-b-2026-10-23-tarde
description: "LEER PRIMERO (B): cierre de la sesión del 23-oct (mañana a tarde); master 116f7525, modelo-ng 67b4353a; PR abiertos de B, #170 en 03bbceea, VM del laboratorio (VM-SRV lista salvo cierre; VM-LNX sin instalar), decisiones del propietario pendientes y qué hacer primero"
metadata:
  node_type: memory
  type: project
  originSessionId: 41f96ec4-6837-434a-b6fd-c75ca3221f03
  modified: 2026-10-23T14:18:22.459Z
---

Complementa a [[traspaso-b-2026-10-23]] (cierre de la noche 22-23; sigue valiendo para las reglas de trabajo y las firmas). Sesión nueva: leer ambas, `MEMORY.md`, [[t4-10-firmas-2026-10-22]]; `git fetch` en `GPOS NG` y `git pull --rebase` en `C:\Users\lfmen\source\repos\GPOS-NG-Equipos`; `gh pr list --state open`; armar el `Monitor` sobre `novedades-B.md` (re-armar cada 30 min; la tarea de Windows de vigilancia está activa) y leer las novedades. Reglas: `gh pr merge N --merge --match-head-commit <sha>` solo con orden explícita del propietario en el chat; añadir archivos por nombre (nunca `git add docs`); pie `Co-Authored-By: Claude Sonnet 5.5`; verificar yo los informes de los agentes (sha, árbol limpio, pruebas dirigidas EN EL ÁRBOL del agente); máx. 3 agentes compilando.

**Puntas:** `master` 116f7525; `feature/modelo-ng` 67b4353a. Sin uniones nuevas hoy.

**PR abiertos de B (todos sin unir):**
- **#170** T4-03a/b (`b/ola5-t4-03a`, punta **03bbceea**): P170-01 a 06 cerrados, 9 pruebas de la revisión adversarial de C (`1d44680f`), H170-03/04/05 corregidos (`MaximoPasadas` = 4). Falta la revisión de A del rango `89fce5b5..03bbceea` (aviso publicado) y la orden de unión. Abiertos: P170-07 (ticket, ver abajo), H170-06 y H170-08 (seguimiento), el 503 de `/api/salud` con navegador enclavado y el tope de 4 pasadas a vista del propietario.
- **#190/#191** (blueprint T4-02 y hoja de firma): unir #191 antes que #190.
- **#192** estado.json (efecto de #174, #168, #169, #175; ADR-93 TB-07 y ADR-109 cl. 7 a Parcial en modelo-ng). **#193/#194** T4-10 datos (1/2 esquema `imp`, 2/2 pruebas; #194 apilado sobre la rama del #193). **#195** pruebas con `Mvc.Testing` 10.0.13 (los paquetes del producto y `dotnet-tools.json` siguen en 10.0.12: decidir). **#120** T2-0.
- De C: #196 (limpieza de `ClearAllPools()`; **me toca correr la suite completa en LFMB, incluida `Rg14RotacionApiTests`**), #197 (pruebas de P175-01/02, condición para que A abra el PR del emisor), #156 (dorados, borrador), #153, #147. De A: #164, #165, #173, #103.

**Ramas con respaldo sin PR:** `b/ola5-t4-07` (87eb6369: tablero + diseño y hoja de firma de D-03; hay una fuga del tablero para usuarios restringidos, no unir sin el filtro por sucursal; hoja pendiente de TBS-01 a 06), `b/lab-firma-oracle` (7fa3854e, arreglo de la guarda de firma del laboratorio; PR contra modelo-ng pendiente).

**Decisiones aprobadas hoy por el propietario:** orden de unión de A (#164, #165, emisor tras las pruebas de C, #173 el último; cada unión con su orden explícita y mis pruebas dirigidas antes); C revisa el #173 y escribe `Preparar-Vm.ps1` (antes del 18-nov); P170-07 es ticket con dueño B; pruebas a 10.0.13; SQL Server 2025 Express (2019 en el equipo de A); corregir H170-03/04/05; P-M168-01: el oráculo es la hoja `2026-10-22-hoja-firma-admin-sin-restriccion-fija-la-restriccion.md` (la autoedición de la restricción NO está firmada).

**Decisiones del propietario pendientes:** firma de **P170-07** (decisión en `scratchpad\decision-p170-07.md`: recomienda opción (b), marca de copia en encabezado y pie de Chromium, con espiga previa de 0,25 dp, respaldo (c); construir en T4-02; más el cambio de una línea de `!important` en el pie); órdenes de unión de #164 y #165 y de lo demás; respuestas a A (verbo `tls` y para cuándo; si el DEMO adopta HTTPS con `ModoRed=UnEquipo`; si `SesionInfo` lleva `RestringirSucursal`: antes del 28-oct) y a C (P-M168-02 a 05, P-S152-xx, Q-1..Q-4 y Q-9 de T4-10); D-03 del tablero (hoja TBS-01..06); pasar los paquetes del producto a 10.0.13; SPV-03; certificados del anillo DM-07; S170-03/04 y C-02-4; tope de reimpresiones (S-03); franja 5130-5149 (R18).

**Laboratorio de ADR-90 (VirtualBox 7.2.22 en LFMB, M:\VM):**
- Worktree `GPOS-B-lab` (guiones de `feature/modelo-ng`, rama `b/lab-firma-oracle`). Fallos de los guiones sin ejecutar antes: la guarda de firma buscaba `O=Oracle` y el sujeto real es `O="Oracle America, Inc."` (arreglado en la rama); `Get-TiposSo` busca `ID:` pero 7.2 imprime `ID / Description:` (se sortea con `-TipoSo`; sin arreglar).
- **VM-SRV:** Windows Server 2025 (es-ES, imagen 2 con escritorio), 3584 MB, instalada y **APAGADA** (apagado ordenado con `shutdown /s` desde dentro, a las ~10:50 del 23-oct; arrancar con `startvm VM-SRV --type headless` y esperar unos minutos a que responda `guestcontrol`). Tiene runtime ASP.NET Core 10.0.13 (Hosting Bundle) y SQL Server 2025 Express 17.0.1000.7 (instancia SQLEXPRESS, inicio manual, parada, solo autenticación de Windows, `sa` deshabilitado; `sqlcmd` con `-C`). Falta: IP estática `192.168.50.10/24` en `Ethernet 2`, `hosts`, marcador y `w32time` (`Preparar-Vm.ps1`, lo escribe C), y `Cerrar-Preparacion.ps1` (retira el NAT, borra la clave en texto plano de `desatendida\` y toma el punto de control `base`).
- **Cómo ejecutar dentro de la VM:** `VBoxManage guestcontrol` con la cuenta integrada `Administrador` (misma clave de laboratorio, DPAPI en `M:\VM\GPOS-LAB\VM-SRV\credencial.dpapi.json`); `gposlab` no corre elevada (UAC). Ayudante `Invocar-EnVm.ps1` en el scratchpad de la sesión (puede perderse: reconstruirlo; pasa el comando con `-EncodedCommand` y la clave por archivo temporal que se borra). El instalador SSEI de SQL falla con -1 en silencio: se usó `SQLEXPR_x64_ENU.exe` (SHA-256 74aa90c1…5297) y `setup.exe`.
- **VM-LNX:** creada (3072 MB, apagada), **sin instalar**: Ubuntu 24.04.5 desatendido se cuelga en «Loading essential drivers» tanto con 1,5 como con 3 GB (la plataforma de Windows sí funciona: Windows Server instaló). Probar red virtio y otro controlador de disco sin instalación desatendida, o consolidar; no se ha decidido.
- **VM-PUESTO** (Windows 11, ISO ya en `M:\VM\imagenes`): sin crear.
- Fechas de la VM: instalador 18-nov y spike Amplio 23-nov; las opera B.

**C está activo y estable** (entrega adelantada y con evidencia; la prueba exigente la pasó). Entregó: revisiones de pruebas del #168 y #175, revisión adversarial del #170, planes de M-168, S152-02/T4-03b, T4-10/T4-11, casos de laboratorio de T1-b y del spike, revisión del #173 (P-01 y P-02 Altos, avisados a A). Pone `Claude Opus 5.5` en sus pies cuando corre Opus (no cuestionado).

**Qué hacer primero:** leer novedades (ninguna VM está en ejecución); abrir #195/#196 según orden; correr la suite completa del #196 en LFMB; responder a A (tls, HTTPS, SesionInfo) y a C con las decisiones del propietario; pedir la firma de P170-07; PR de `b/lab-firma-oracle`.
