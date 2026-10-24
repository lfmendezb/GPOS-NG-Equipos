```
Para: B (copia a A)        De: C        Fecha: 2026-10-24 (redactado el 2026-10-23)
Tipo: Entrega (tanda 9, punto 3, y tanda 10, punto 1: runbook de las tres ventanas y lista de verificación previa de VM-SRV)
Prioridad: Alta (lo necesitas antes de la primera ventana)
Repositorio y rama: GPOS-NG, solo lectura con `git show origin/<rama>:tests/laboratorio-adr090/...` (checkout sin tocar, sin commits); área común `traspasos/C/` y `avisos/`
Estado: Abierto (documento; nada compilado ni ejecutado)
```

# Runbook de las tres ventanas de laboratorio en `VM-SRV` (5 a 6 h cada una) y lista de verificación previa

**Quién opera:** B, en `LFMB`. C no ejecuta nada; revisa la evidencia ya redactada.
**Marcas:** [V] = leído en el código o en el documento citado; [I] = inferido, se confirma en la VM; [?] = depende de algo que aún no existe o que alguien debe decidir.
**Reglas que rigen todo el documento:** SL-11 (sin VRDE ni carpetas compartidas: nada se copia por una carpeta compartida), LS-11 (guardas: `GPOS_LAB_TLS_VM=1`, marcador igual a `GPOS_LAB_TLS_ID`, VirtualBox, elevación), LS-15 (la licencia de laboratorio vale hasta `T0+120 d`; el reloj solo se mueve en los casos que lo piden y se restablece), `revision-evidencia.md` (secciones A a E) y "si algo falla no se corrige a mano para que pase: se anota y se restaura el punto de control".

---

## 0. Resumen para decidir

1. **Tres ventanas no alcanzan para todo lo escrito.** Lo que hay (guiones y planes) suma unas **65 h** de laboratorio [I, ±50 %]; tres ventanas de 5 a 6 h dan unas **13 a 14 h netas** de casos (el resto es verificación previa, restauraciones y cierre). Propongo repartir por riesgo y por dependencia (sección 4) y dejar explícito lo que queda fuera (sección 5, unas 50 h).
2. **Reparto propuesto (B decide):**

   | Ventana | Contenido | Casos netos [I] | Total con previa, restauraciones y cierre |
   |---|---|---|---|
   | **V1** | Ensayo de la llave de firma con vTPM (`Probar-LlaveFirmaTpm.ps1`, #233) y núcleo del `GPOS.Api.msi` (`Probar-GposApiMsi.ps1`, #226). Sin SQL. | 100 + 190 min | ≈ 6 h 15 |
   | **V2** | Anillo de F1 (`Probar-Anillo.ps1`, #234): SA-01, W-AN-01 a 05, G-1, G-2, SA-03a, SF-01a, SF-03. Con SQL Express y disco de traspaso. | 260 min | ≈ 5 h 55 |
   | **V3** | `restaurar` de PR-D2 nivel V (`Probar-Restaurar.ps1`, #223): PRE-3, RS-01 a RS-06. Sin SQL. | 250 min | ≈ 5 h 50 |

3. **Ninguna línea comparte estado con otra.** MSI, TPM, anillo, `restaurar` y el spike crean cada uno un servicio llamado `GPOS.Api` (el de `restaurar` también `GPOS.Reportes`) y sus guardas se niegan si hay uno ajeno. Cada línea parte de `base`, o de su propio punto de control, y se restaura `base` al cambiar de línea (sección 3).
4. **Hallazgo que bloquea la toma de puntos de control (Media, [V]):** `Puntos-Control.ps1` solo acepta `base`, `T0`, `T0+Nd` y `LAB-NN[letra][-L][-sufijo]` con **un solo tramo** de sufijo (`Comun-Laboratorio.ps1:56`). **Diez de los nombres que usan los documentos no pasan**: `LAB-D2-LISTO`, `LAB-D2-A`, `LAB-D2-A2B`, `LABA-base-f1`, `LABA-anillo-listo`, `LAB-140-base-ok`, `LAB-150-sql-listo`, `LAB-151-spike-verde`, `LAB-152-msi-configurado` y `LAB-162-con-llave` (probados contra la expresión con `grep -P`; sección 2.4). Además, `Probar-GposApiMsi.ps1:89` y `Probar-LlaveFirmaTpm.ps1:74` rechazan esos mismos nombres como valor de `-PuntoControl`, y el ejemplo del encabezado de `Probar-GposApiMsi.ps1` usa `LAB-140-base-ok`, que su propia validación rechaza. **Es defecto mío** (los nombres salieron de mis documentos). Remedio propuesto en 2.4: nombres alias que sí pasan; lo decide B (D-R1) y lo aplico yo en un PR chico de `tests/` (≈ 0,2 dp).
5. **RAM:** la VM no arranca si el anfitrión no tiene libres `memoria de la VM + 1 536 MB`: **5 120 MB** para `VM-SRV` sola (3 584 + 1 536) y **9 216 MB** si además se enciende `VM-PUESTO` (4 096) [V, `Comun-Laboratorio.ps1:31,36-38,277-283`]. Con el trabajo de B abierto, el 2026-10-21 había 4,4 GB libres: **no alcanza hoy**. B tiene que cerrar WSL2, Docker y lo suyo antes de cada ventana (2.1).
6. **vTPM:** el punto de control guarda también la configuración de la VM [I]. Si el vTPM se habilita **después** de tomar `base`, restaurar `base` lo quita. El orden correcto es: habilitar el vTPM con la VM apagada, comprobar `Get-Tpm` y **solo entonces** tomar `LAB-160-antes` (2.2).
7. **Pruebas pendientes de escribir (lo que falta):** guion de `Instalar-Demo.ps1` nivel G (`Probar-InstalarDemo.ps1`, no se escribe hasta que A fije la corrección de O-1; ≈ 1,5 dp), cambio `-ServicioDelMsi` del spike DE-01 (≈ 0,25 dp), guiones de laboratorio de F2 de `tls` (≈ 0,3 dp; el verbo se construye del 3 al 10-nov), plan de `aprovisionar` de D-5 (c) (tanda 10, punto 6) y `VM-LNX` (no instala todavía).
8. **Estimaciones que no cuadran entre documentos:** las filas de la tabla de `Probar-Anillo.ps1` suman **375 min (6 h 15)** y el LEEME dice "unas 5 h 30"; la suma de las tres sesiones de mi plan del MSI es 12 h 45 y el resumen dice 12,5 h. Uso las sumas de las filas.
9. **El sha de #234:** el aviso dice `5b5cfab7`; `origin/c/guion-probar-anillo` está en `29237917`. Los dos tienen **el mismo árbol** (`git diff` entre ambos, vacío) y el mismo padre (`1b310591`); cambia solo el commit. El SHA-256 del guion es el mismo. Para el acta, B anota el SHA-256 del archivo (2.6).

---

## 1. Inventario: lo listo y lo que falta

### 1.1 Listo (escrito, **ninguno ejecutado en una VM**)

| Línea | PR / rama @ sha | Guion (`tests/laboratorio-adr090/invitado/`) | Casos | Duración completa [I] | Necesita SQL | Documento de casos |
|---|---|---|---|---|---|---|
| MSI de la API | #226 `c/guiones-gpos-api-msi` @ `9f297ad8` | `Probar-GposApiMsi.ps1`, `Get-MsiTabla.ps1` | 50 casos LAB-API (B1 a FIR-1) más A6b y A1 ampliado; A5, D3, R2 y FIR-1 salen `Bloqueado` por diseño | 12 h 45 en 3 sesiones | No | `2026-10-23-casos-laboratorio-gpos-api-msi.md`; LEEME del PR |
| `restaurar` (PR-D2, nivel V) | #223 `c/guion-restaurar` @ `850dc799` | `Probar-Restaurar.ps1` (+ `LEEME-Probar-Restaurar.md`) | LAB-RS-01 a RS-12 | 6 h 30 (S6) | No | `2026-10-23-casos-laboratorio-pr-d2.md` |
| Anillo de F1 | #234 `c/guion-probar-anillo` @ `29237917` (el aviso dice `5b5cfab7`, mismo árbol) | `Probar-Anillo.ps1` (+ `LEEME-Probar-Anillo.md`) | W-AN-01 a 05, G-1, G-2, SA-01 a 03, SA-06, SF-01 a SF-09; LABA-05, 11, 12, 14 a 20 quedan fuera | 6 h 15 (suma de las filas) | Sí | `2026-10-23-plan-pruebas-anillo-dm07.md`; LEEME del PR |
| Llave de firma con vTPM | #233 `c/guion-llave-firma-tpm` @ `67058ecb` | `Probar-LlaveFirmaTpm.ps1` (+ `LEEME-llave-firma-tpm.md`) | T1 a T5, T5-tras-reinicio, Sonda-Consola, Decision, Limpiar | 1 h 40 | No | LEEME del PR; `2026-10-23-revision-adversarial-pr120-posterior.md` |
| `VM-LNX` (solo cuando exista) | #224 `c/preparar-vm-lnx` @ `798fcf00`; #229 `c/limpiar-laboratorio-lnx` @ `0f64b8a5` (incluye la lista `huellas.txt`) | `preparar-vm.sh`, `limpiar-laboratorio.sh` | PVL-01 a PVL-20, LLL-01 a LLL-11 | ≈ 2 h [I, sin fuente] | No | `preparar-vm-lnx.md` |
| Base común (ya en `feature/modelo-ng` @ `1b310591`) | #146, #165, #173, #198 | `Preparar-Vm.ps1`, `Probar-Instalador.ps1`, `Probar-Spike-Amplio.ps1` | guardas, preparación, spike #173 | — | `Probar-Spike-Amplio.ps1` sí | `revision-evidencia.md` |

**Estado de verificación de los guiones [V]:** análisis de sintaxis sin errores con el analizador de Windows PowerShell 5.1 y de PowerShell 7 para MSI, anillo y TPM (arnés C# que llama a `Parser.ParseFile`); **para `Probar-Restaurar.ps1` ni siquiera el análisis se pudo correr** (el entorno bloqueó `powershell.exe` y `pwsh`). Antes de copiar a la VM, B corre el fragmento del LEEME de `Probar-Restaurar.ps1` en `LFMB` para los cuatro guiones (2.1, paso 9).

### 1.2 Lo que falta (y de quién depende)

| Línea | Qué falta | Quién | Cuándo [fuente] | Efecto en el runbook |
|---|---|---|---|---|
| `Instalar-Demo.ps1` nivel G | `Probar-InstalarDemo.ps1` (ID-02 a ID-09, ≈ 1,5 dp); RS-10f/g/h/i dentro de `Probar-Restaurar.ps1` (≈ 0,3 dp). Esperan la corrección de A (O-1 a O-3, antes del 28-oct) y el contrato D-1; el instalador de servicios termina del 5 al 9-nov y con D-5 (c) su criterio de `ID-02` cambia (ya no termina en "BORRADOR") | C (escribe), A (contrato) | Después de A | Fuera de las tres ventanas (sección 5). Las ampliaciones de `restaurar` no están en el #223 |
| Spike DE-01 | Cambio `-ServicioDelMsi` de `Probar-Spike-Amplio.ps1` (Q-3), P-03/P-04/P-10/P-11 del #173 y SP-01/SP-02 sin atender; VM-PUESTO sin crear; fecha 23-nov sin confirmar | C o A (guion), B (VM) | 23-nov propuesto | Fuera de las tres ventanas por defecto; ver intercambio en 5.2 |
| F2 de `tls` | Verbo `tls` (B lo construye del 3 al 10-nov); 18 dudas D-F2-xx; guiones LABT/W-TLS (≈ 0,3 dp, se escriben con el verbo) | B (verbo), C (guiones) | Después del 10-nov | Fuera de las tres ventanas |
| D-5 (c) | Plan de pruebas de `aprovisionar` (tanda 10, punto 6); AP-01 a AP-08 ya están en `2026-10-24-contraste-adversarial-d5.md` y sustituyen a EM-01, EM-02 y EM-07 | C | Pendiente | Nivel A de PR-D2 (S8): fuera |
| Anillo | Remedios de B para SF-01 a SF-04 y SF-06 (nuevo sha); cuatro decisiones del #234 (Environment en memoria, disco VDI writethrough, SF-03 (a) o (b), publicación self-contained) | B | Antes de la primera ventana | V2 depende de esto (sección 8) |
| PR-V | Casos LABP-10, LABP-13, LABP-15 (laboratorio) | C (guion), A (verbos) | Después de PR-V | Fuera |
| `VM-LNX` | La VM no instala (Ubuntu 24.04 se cuelga en el instalador, aviso de B del 2026-10-23) | B | — | Los pasos de LNX son condicionales |

---

## 2. Lista de verificación previa de `VM-SRV` (se repite antes de **cada** ventana)

Marca cada punto con la hora y el resultado en el acta (2.8). Si un punto "Parar" falla, no se arranca la ventana.

### 2.1 Anfitrión `LFMB` (B)

| # | Comprobación | Cómo | Esperado | Parar si |
|---|---|---|---|---|
| 1 | Nadie más usa `LFMB` | Sin suites, compilaciones ni agentes; la suite completa y las cargas SQL corren solas (regla del proyecto) | Ninguna carga | Hay una suite corriendo: se espera o se aplaza |
| 2 | **RAM libre real** | `Preparar-Anfitrion.ps1 -Bloque N` (VM-SRV sola). Con `VM-PUESTO`: `-Bloque B`, `V` o `R`. Internamente: `FreePhysicalMemory` ≥ memoria de las VM del bloque + 1 536 MB | `VM-SRV`: **≥ 5 120 MB**. `VM-SRV` + `VM-PUESTO`: **≥ 9 216 MB** | Falla: la VM no arranca (`Confirmar-ArranquePermitido` se detiene antes de `-Arrancar`). No se baja el margen. Cerrar WSL2 (`wsl --shutdown`, el proceso `vmmem` [I]), salir de Docker Desktop, parar las instancias SQL locales de B (son suyas; el laboratorio no las toca) y los agentes. Con 13,9 GB en total y 4,4 GB libres medidos el 2026-10-21, **hoy falla** |
| 3 | Disco en `M:` | El mismo guion (`-EspacioMinimoGB`, 150 por omisión) | ≥ 150 GB libres (el 2026-10-21 había 547) | Menos: borrar puntos de control viejos |
| 4 | Solo las VM del bloque encendidas | `VBoxManage list runningvms` (lo repite el guion) | Ninguna ajena | Hay una ajena: apagarla |
| 5 | `VBoxManage` 7.2.22 con firma de Oracle; equipo `LFMB` | Lo comprueba `Iniciar-Guion` en todos los guiones | OK | Falla cualquiera |
| 6 | Redacción en verde | `Probar-Redaccion.ps1` (42 casos) con la versión de los guiones que se va a usar | 42 de 42 | Falla: no se copia nada |
| 7 | Historial del portapapeles apagado (Win+V) mientras se use `Leer-Credencial.ps1` | A mano | Apagado | — |
| 8 | Hora del anfitrión | `Get-Date` y zona | Correcta | Mal: las horas de la evidencia no valdrán (`revision-evidencia.md` D) |
| 9 | **Análisis de sintaxis** de cada guion copiado, en 5.1 y 7 | Fragmento del LEEME de `Probar-Restaurar.ps1` (`Parser.ParseFile`) aplicado a los cuatro `.ps1` de la ventana | 0 errores en las dos versiones | Algún error: no se copia ese guion y se me avisa |

### 2.2 `VM-SRV` apagada: configuración (B)

| # | Comprobación | Cómo | Esperado | Parar si |
|---|---|---|---|---|
| 10 | Memoria, CPU, firmware, red | `VBoxManage showvminfo VM-SRV --machinereadable` (claves `memory`, `nic1`, `intnet1`, `nic2`, `vrde`, `firmware`) | 3 584 MB, 2 CPU, EFI; solo la red interna `GPOS-LAB` (nic1); **sin NAT, sin VRDE** | Hay NAT o VRDE: es SL-11; `Cerrar-Preparacion.ps1` lo vuelve a comprobar |
| 11 | **Sin carpetas compartidas** (SL-11) | La misma salida: ninguna clave `SharedFolderName…`; el DVD en `emptydrive` | Ninguna | Aparece una: se quita antes de continuar |
| 12 | **vTPM 2.0 habilitado** (solo ventana con TPM, V1) | `VBoxManage showvminfo VM-SRV --machinereadable \| Select-String 'tpm\|firmware'`; si dice `none`: `VBoxManage modifyvm VM-SRV --tpm-type=2.0` con la VM **apagada** [I: valores de `--tpm-type`: `none`, `1.2`, `2.0`, `host`, `swtpm`] | `2.0` y firmware EFI | `1.2` (el PCP no admite ECDSA P-256, H120P-04). **No cambiar el firmware de una VM instalada**: si no es EFI, se crea de nuevo |
| 13 | El vTPM sobrevive a la restauración | Después de habilitarlo: arrancar, `Get-Tpm` (`TpmPresent` y `TpmReady` en `True`), apagar, **tomar `LAB-160-antes`**, restaurar `base` y volver a mirar `showvminfo`; luego restaurar `LAB-160-antes` y mirar otra vez [I] | Con `LAB-160-antes` restaurado, el TPM sigue en `2.0`. Con `base` restaurado puede volver a `none`, y está bien | Si `LAB-160-antes` restaurado vuelve sin TPM, `Guardas` del guion lo dirá; no seguir con T1 |
| 14 | Si cambias la memoria con `modifyvm --memory`, el cambio se pierde al restaurar un punto anterior [I] | Hacerlo antes de tomar los puntos de la ventana | — | — |
| 15 | Disco de traspaso (solo V2, W-AN-04) | Con la VM apagada y **antes** de tomar `LAB-164-basef1`: `VBoxManage createmedium disk --filename M:\VM\VM-SRV\traspaso.vdi --size 2048` y `storageattach … --mtype writethrough` (ejemplo del LEEME del #234). Dentro, asignar la letra `T:` (nunca `C:`) | `T:` presente; el disco es de tipo writethrough, así que **no** entra en los puntos de control [I] | Si el disco se adjuntó después de tomar el punto, restaurarlo lo desacopla: adjuntarlo antes de tomarlo |

### 2.3 Dentro de `VM-SRV`, ya restaurada y encendida

| # | Comprobación | Cómo | Esperado | Parar si |
|---|---|---|---|---|
| 16 | Marcador y preparación | Consola **elevada** como el `Administrador` integrado (`gposlab` no corre elevada): `powershell.exe -ExecutionPolicy Bypass -File .\Preparar-Vm.ps1 -Vm VM-SRV -Comprobar` | Todo en `OK`, también después de restaurar `base` (lo confirma el LEEME como pendiente de verificar [I]) | Algo en `FALTA`: no hay marcador y los guiones no corren. Se vuelve a preparar y se toma un `base` nuevo antes de seguir |
| 17 | Variables de la sesión | `$env:GPOS_LAB_TLS_VM = '1'` y `$env:GPOS_LAB_TLS_ID = 'LAB-…'` (el que imprimió `Preparar-Vm.ps1`; no son secretas). **Se pierden al reiniciar la VM y al abrir otra consola** | Fijadas en cada consola | Tras un reinicio (R3, O6, T5-tras-reinicio, RS-07) hay que repetirlas |
| 18 | Guardas de cada guion | `.\Probar-Instalador.ps1 -Caso Guardas`; `.\Probar-GposApiMsi.ps1 -Caso Guardas`; el mismo `-Caso Guardas` de `Probar-Restaurar.ps1`, `Probar-LlaveFirmaTpm.ps1` o `.\Probar-Anillo.ps1 -Caso Guardas` | `Guardas: cumplidas` | Alguna se niega: se anota el mensaje y la línea queda `Bloqueado` |
| 19 | Hora y licencia de evaluación | `Get-Date` frente al anfitrión (±2 min); `w32time` detenido (`Preparar-Vm.ps1` lo hace); `Ajustar-Reloj.ps1 -Vm VM-SRV -Accion Ver` en `LFMB`; días que le quedan a la evaluación de Windows Server (`slmgr /dli` [I]) | Hora correcta; evaluación con más de 30 días (apaga el equipo cada hora al vencer) | Reloj movido sin motivo: restaurar `base` |
| 20 | Espacio en `C:` | `Get-PSDrive C` | ≥ 3 GB libres para V3 (dos paquetes con `relleno.bin` de 400 MB, destino, `.anterior`, `.preparacion`); ≥ 2 GB en las demás | Menos |
| 21 | Runtime de .NET | `dotnet --list-runtimes` | `Microsoft.NETCore.App 10.x` si se copia un `GPOS.Migracion` dependiente del marco (T2 del TPM). La VM tiene ASP.NET Core 10.0.13 según B; que traiga también `Microsoft.NETCore.App` es [I] | Falta: T2 queda `Bloqueado`. Alternativa: publicarlo self-contained (decisión 4 del #234) |
| 22 | SQL Server | `Get-Service 'MSSQL$SQLEXPRESS'`. V2: **en `Running`**. V1 y V3: no hace falta | Según la ventana | — |
| 23 | Cuentas | `gpos-lab-usuario` (estándar; el técnico teclea la contraseña, no se guarda) para MSI, spike y `restaurar`. Las claves iniciales del anillo son centinelas visibles | Existe | — |
| 24 | Windows Update y Defender | Sin cambios de la ventana anterior (un antivirus puede bloquear archivos y falsear RS-05/RS-06) | — | [I] |

### 2.4 Puntos de control: nombres, orden y el conflicto de patrón

`Puntos-Control.ps1` solo toma, restaura y borra nombres que cumplen `^(base|T0|T0\+\d{1,3}d|LAB-\d{2,3}[a-z]?(-L)?(-[a-z0-9]{1,20})?)$` (en minúsculas, **un** tramo de sufijo). Resultado de aplicar la expresión a cada nombre de los documentos (comprobado con `grep -P`, sin ejecutar PowerShell):

| Línea | Nombre en los documentos | ¿Pasa? | Alias que sí pasa (propuesta, D-R1) | Cuándo se toma |
|---|---|---|---|---|
| Común | `base` | sí | — | Ya existe (lo toma `Cerrar-Preparacion.ps1`) |
| MSI | `LAB-140-base-ok` | **no** | `LAB-140-baseok` | `base` restaurada + `gpos-lab-usuario` + archivos copiados y verificados, antes de instalar nada |
| MSI | `LAB-141-instalado` | sí | — | Tras I1 en verde |
| MSI | `LAB-142-fips` | sí | — | Antes de O6, desde el anfitrión (fuera de V1) |
| MSI | `LAB-143-v1` | sí | — | Tras instalar la versión 1 con centinelas |
| MSI | `LAB-144-sinorigen` | sí | — | Antes de S3 (fuera de V1) |
| Spike | `LAB-150-sql-listo` | **no** | `LAB-150-sqllisto` | Tras SPK-P0 |
| Spike | `LAB-151-spike-verde` | **no** | `LAB-151-spikeverde` | Solo si DE-01 dio `Running` y 200 |
| Spike | `LAB-152-msi-configurado` | **no** | `LAB-152-msiconfigurado` | Rama del MSI, nunca arrancado |
| TPM | `LAB-160-antes` | sí | — | vTPM habilitado y comprobado, sin MSI ni servicio `GPOS.Api` |
| TPM | `LAB-161-preparado` | sí | — | Tras `Preparar` (con `-EnVivo`) |
| TPM | `LAB-162-con-llave` | **no** | `LAB-162-conllave` | Tras T2 y T3 (con `-EnVivo`) |
| TPM | `LAB-163-despues` | sí | — | Tras T5-tras-reinicio (con `-EnVivo`) |
| Anillo | `LABA-base-f1` | **no** (no empieza por `LAB-` + dígitos) | `LAB-164-basef1` | `base` + SQL + `DE-01-preparar` (sin `DE-01-probar`) + `Par-Recuperacion` + disco `T:` adjunto |
| Anillo | `LABA-anillo-listo` | **no** | `LAB-165-anillolisto` | Tras W-AN-03 |
| PR-D2 | `LAB-D2-LISTO` | **no** | `LAB-170-listo` | Tras `Preparar-Paquetes` |
| PR-D2 | `LAB-D2-A` | **no** | `LAB-171-a` | Tras `Montar-A` |
| PR-D2 | `LAB-D2-A2B` | **no** | `LAB-172-a2b` | Tras `Montar-A2B` |
| PR-D2 (G) | `LAB-D2-ID-LISTO`, `LAB-D2-G-A`, `LAB-D2-G-A2B`, `LAB-D2-ANILLO` | **no** | `LAB-173-idlisto`, `LAB-174-ga`, `LAB-175-ga2b`, `LAB-176-anillo` | Fuera de las tres ventanas |
| `tls` F2 | (sin nombres todavía) | — | Reservo `LAB-180` a `LAB-189` | — |

**Numeración libre y ocupada:** 140 a 149 (MSI), 150 a 159 (spike), 160 a 163 (TPM; 164 a 169 reservo para el anillo), 170 a 179 (PR-D2), 180 a 189 (`tls` F2). No hay solape de números entre líneas [V: `grep` de `LAB-1xx` en `avisos` y `traspasos/C`]. El conflicto es de **forma**, no de numeración.

**Remedio recomendado (D-R1):** alias que pasan el patrón, sin tocar la lista de permitidos (SL-06). Cambios: `Probar-Anillo.ps1:86` (acepta `LABA-…`, pasaría a aceptar `LAB-164`/`LAB-165`), los textos "tome el punto LAB-D2-…" de `Probar-Restaurar.ps1`, el ejemplo de `Probar-GposApiMsi.ps1` y el LEEME de `Probar-LlaveFirmaTpm.ps1` (T4). **Alternativa descartada:** ensanchar `PatronPuntoControl` en `Comun-Laboratorio.ps1` y los tres `ValidatePattern` de `-PuntoControl`; vuelve a abrir SL-06 (nombres por UUID, lista permitida) y toca tu código del anfitrión. **Mientras no decidas, este runbook usa los alias** y en el acta se anota el nombre del documento junto al alias.

**Reglas de la secuencia de puntos:**
- Antes de la ventana: `Puntos-Control.ps1 -Vm VM-SRV -Accion Listar`; deben existir `base` y, como mucho, los puntos de la ventana anterior ya recogidos. Los demás se borran con `Limpiar-Anfitrion.ps1 -Accion PuntosControl -Vm VM-SRV -WhatIf` y luego sin `-WhatIf`.
- Un nombre repetido detiene el guion (SL-06): no se reusa un nombre sin borrar el anterior.
- Cada línea cuelga de `base` (ramas del árbol de instantáneas; una cadena profunda hace más lento el disco [I]).
- Con la VM encendida solo se toma con `-EnVivo` (lo pide el guion del TPM para 161, 162 y 163).
- Un punto de control guarda la configuración de la VM, incluido el desplazamiento del reloj (`Ajustar-Reloj.ps1`) y, [I], el TPM.

### 2.5 Marcador y guardas (LS-11)

- Marcador: `HKLM\SOFTWARE\GPOS NG\LaboratorioTls` (vista de 64 bits) con `Vm`, `Preparado`, `VersionGuion` e `Id`; lo crea `Preparar-Vm.ps1` y viaja en `base`. Si una ejecución de `Preparar-Vm.ps1` falló, el `Id` queda retirado (`IdRetirado`) y **ningún guion corre**.
- Cada consola: las dos variables de 2.3 (#17). Las guardas de todos los guiones son las mismas: variable, marcador igual a la variable, modelo VirtualBox, elevación (excepciones: `I7-cuenta` y `N1b-ejecutar`, que miden lo que puede una cuenta sin elevar).
- `Probar-Restaurar.ps1` exige además equipo `VM-SRV`, marcador `Vm=VM-SRV` y proceso de 64 bits.

### 2.6 Qué se copia, de dónde y con qué hash

**Método de exportación (importa por el hash):** el SHA-256 de abajo es el del **blob de git**, tal como queda con `git show origin/<rama>:<ruta>` sin conversión de fin de línea. Exportar con `cmd /c "git show origin/<rama>:<ruta> > <destino>"` o con `git archive`; **no** con `>` de Windows PowerShell 5.1 (reescribe en UTF-16) ni desde un árbol con `core.autocrlf=true` (cambia los saltos de línea). Los `.ps1` del TPM, el MSI y el anillo van en UTF-8 con BOM; los `.sh` en LF (`.gitattributes`). B anota **SHA-256 en `LFMB` antes de copiar** y **SHA-256 en la VM después**; deben coincidir.

| Artefacto | De dónde | Destino en la VM | SHA-256 del blob | Ventana |
|---|---|---|---|---|
| `Probar-GposApiMsi.ps1` (154 653 B) | `origin/c/guiones-gpos-api-msi` @ `9f297ad8` | `C:\GPOS-LAB\` | `894281d200cbe9ab7715a8d523a14b1ce9a3fd08c84445177ddc45ac4b701120` | V1 |
| `Get-MsiTabla.ps1` (26 417 B) | ídem | `C:\GPOS-LAB\` | `ed09fcb9fb05645617e387fa256521396be701e37dab017d74a3c388537fb218` | V1 |
| `Probar-Instalador.ps1` (25 303 B; igual en todas las ramas de C y en `feature/modelo-ng` @ `1b310591`) | `origin/feature/modelo-ng` | `C:\GPOS-LAB\` | `63d3c695b102a99ecda20566e92a25189f0368e2b56c7e19e40a4d82c1fdcc6e` | V1 (O6 lo usa) |
| `Probar-LlaveFirmaTpm.ps1` (80 267 B) | `origin/c/guion-llave-firma-tpm` @ `67058ecb` | `C:\GPOS-LAB\guiones\` | `f9c049747a0c5caf4bee4356cbe53865adaa1c59a6f68646ab4e30d00eb0825a` | V1 |
| `GPOS.Migracion` publicado en Release (con el #120 unido) | `dotnet publish` de `origin/feature/modelo-ng` | `C:\GPOS-LAB\migracion\` | Hash de cada archivo; en el acta, el de `GPOS.Migracion.exe` | V1 (T2) |
| `GPOS.Api-SINFIRMA.msi` (v1), `…-v2.msi` (`-Version 1.0.1`), `…-recompilado.msi`, `publicacion.sha256`, `publicacion-v2.sha256`, `publicacion-recompilado.sha256`, `SHA256SUMS.txt` | `Probar-GposApiMsi.ps1 -Caso B2 -CopiaRepositorio <copia sin .git> -SalidaConstruccion <carpeta>` en la PC de construcción de B, sobre `origin/b/t1b-api-msi` @ `1232d0af` | `C:\GPOS-LAB\msi\` | **No se fija**: dos compilaciones del mismo código no dan el mismo hash. B anota el de cada MSI en `LFMB` y lo compara en la VM | V1 (v1 y v2; el recompilado solo si entra A6b) |
| `Probar-Anillo.ps1` (111 488 B) | `origin/c/guion-probar-anillo` @ `29237917` (o `5b5cfab7`: mismo archivo) | `C:\GPOS-LAB\` | `8f2e9d5d15fed0c7c47ce53320b7451ebc926840ff5c5fa87ea3a9ddb267bec4` | V2 |
| `Probar-Spike-Amplio.ps1` (21 896 B) | `origin/feature/modelo-ng` | `C:\GPOS-LAB\` | `65ff31633635a4de90a5a547b1085aabce4b4fe53f0dbd8305fdb6f73e2c712b` | V2 (`DE-01-preparar`) |
| `GPOS.Migracion` de F1 **self-contained** (`dotnet publish src/GPOS.Migracion -c Release -r win-x64 --self-contained`) + `GPOS.Migracion.json` (solo `ConnectionStrings:Sistema` con seguridad integrada, sin secretos) | `origin/b/f1-anillo`. El LEEME del #234 cita `e1c6f516`; **B corrige SF-01 a SF-04 y SF-06 en un sha nuevo**: se usa el que B indique | `C:\GPOS-LAB\f1\` | Hash de `GPOS.Migracion.exe` y de `GPOS.Migracion.json`; los copia el guion a la evidencia | V2 |
| Paquete del DEMO de `b/f1-anillo` (`instalador/Demo`; esa rama no trae `instalador/Api`), extraído | Publicación de B | `C:\GPOS-LAB\paquete\GPOS-Demo` | SHA-256 del `.7z` y de `manifiesto.sha256`; `version.json` | V2 |
| `Probar-Restaurar.ps1` (99 523 B) | `origin/c/guion-restaurar` @ `850dc799` | `C:\GPOS-LAB\guiones\` | `a730c081a33800f9e563dd666217efd35a1d91bdbf9398794dca0b75fb7b928b` | V3 |
| Paquetes **PQ-A y PQ-B** publicados con `Publicar-PaqueteDemo.ps1 -Destino Demo -ConApiReportes` (Release) desde `a/pr-d2-manifiesto`, **extraídos** (`cd44043c` o `812d1790`; el sha final de A tras R-04, R-09, P-D2-04, D-4, O-1 a O-3 lo avisa A, fecha 28-oct). **No** desde `feature/modelo-ng` tras T4-06 | Publicación de A / B | `C:\GPOS-LAB\publicado\A` y `…\B` (fuera de OneDrive y del perfil; escribe solo SYSTEM y Administradores) | SHA-256 del `.7z` y de `manifiesto.sha256` de cada uno | V3 |
| `Preparar-Vm.ps1` (38 136 B) | ya viaja en `base` | — | `6ec34acac3e3859b827c46e06216e693612e11b415dd3b4b4fe07b48b91dda30` (el JSON `preparar-vm-VM-SRV-*.json` lo registra) | todas |
| `preparar-vm.sh` (41 930 B), `limpiar-laboratorio.sh` (30 922 B), copiados **juntos** | `origin/c/limpiar-laboratorio-lnx` @ `0f64b8a5` | `VM-LNX` | `e50dd06285dd464e4055e9c233a2693e158914dd4bae51f7a9ecaf325654671d` y `593ecd06085d6b3e13b26ba0f1bc21fa26b92cb30c86f8f55bb47cff809925d5` | solo cuando exista `VM-LNX` |

**Cómo se copia sin carpetas compartidas (SL-11):** `VBoxManage guestcontrol VM-SRV copyto …` (B ya la usa con `gposlab`, aviso del 2026-10-23) [I: opciones exactas por confirmar; la clave no va en la línea de órdenes: `--password-file` o `Leer-Credencial.ps1`]. Alternativa sin red ni carpeta compartida: un disco o imagen **de solo lectura** adjuntado con la VM apagada y retirado después. Nunca `sharedfolder add`. Las copias entran **antes** de tomar `LAB-140-baseok`, `LAB-164-basef1` o `LAB-170-listo`, así viajan en el punto de control; B comprueba el hash **después de restaurar**, no solo después de copiar.

### 2.7 Qué no hacer durante la ventana

Nada de `reg query` ni `reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`; no imprimir `Get-Item` de esa clave sin `.GetValueNames()`; ninguna captura de la pestaña *Environment* de un visor de procesos; ninguna clave, PFX ni cadena de conexión en consola, historial o evidencia; no arrancar una segunda VM salvo que la ventana lo pida; no instalar nada de Internet (la VM no tiene salida).

### 2.8 Acta de la ventana (plantilla)

Fecha y hora de inicio y fin · técnico · VM y punto de partida · RAM libre en `LFMB` al arrancar · `Id` del marcador · versión de Windows con la UBR, FIPS sí o no, edición de SQL · SHA-256 de cada archivo copiado (2.6) y comprobación después de restaurar · commit de cada guion y del código bajo prueba (MSI: `1232d0af`; anillo: sha de F1; `restaurar`: sha de A) · nombres de los puntos de control con el alias y el nombre del documento · incidentes (qué se restauró y por qué) · lista de casos con `resultado` · quién recogió la evidencia y dónde quedó.

---

## 3. Qué comparte VM restaurada y qué necesita la base

Regla de lectura: **"comparte X"** quiere decir que los casos parten del mismo punto de control X y se restauran **entre sí** (X → caso → X → otro caso), sin volver a `base`. **"Necesita base"** quiere decir que exige un equipo sin servicio `GPOS.Api`, sin `%ProgramData%\GPOS NG` y sin `HKLM\SOFTWARE\GPOS NG\Servidor`, o que lo ensucia sin remedio.

| Línea | Comparten un mismo punto de control | Necesitan `base` (o `LAB-140-baseok`) | Dejan la VM sucia: van al final y se restaura después |
|---|---|---|---|
| **MSI** | **`LAB-141-instalado`:** I2 a I9, S1, S2, I3 o S4, S5, P1 y los que no desinstalan. **R1 y R4 parten de `LAB-141-instalado` restaurado** (los arranques fallidos de I3, S1 y S5 cuentan en el contador del día [I]). **`LAB-143-v1`:** A1, A2, A3, A6, A6b, A7 (A4 después de A1) y P2 (necesita el `Environment` centinela del paso 1 de A2) | I1 (instalación limpia), O1 (cada subcaso parte de su propia carpeta plantada), O2, O3, N1, N2, N3 (servicio preexistente `sc create`), N4, N5, N6 | O6 con FIPS (`LAB-142-fips`, dos reinicios), S3 (`LAB-144-sinorigen`), R3 y D4 (reinicio) |
| **TPM** | Acumulativo: `LAB-160-antes` → `LAB-161-preparado` → `LAB-162-conllave` → `LAB-163-despues`. Dentro de la línea se puede volver a 161/162/163 para repetir una lectura | `LAB-160-antes` exige **sin MSI y sin servicio `GPOS.Api`** (el guion crea uno propio con `powershell.exe` y se niega si hay el del MSI, salvo `-PrestarServicioMsi`) | T5-tras-reinicio y el vTPM (llaves de máquina en el TPM, que el punto de control puede no restaurar [I]): `Limpiar` y restaurar `LAB-160-antes` o `base` |
| **Anillo** | **`LAB-164-basef1`:** SA-01, y de ahí W-AN-01, W-AN-02, SF-03 y G-2 sin restaurar entre sí (cada uno parte del estado que dejó SA-01). **`LAB-165-anillolisto`:** G-1, W-AN-05 (doce variantes restauradas por el propio guion), SF-08, SA-03a, SA-03b, SF-04, W-AN-04-respaldar, SF-01a | SF-02, SF-01b, SA-02, SA-06 (parten de `LAB-164-basef1`, restaurando entre uno y otro); W-AN-04-recuperar (`LAB-164-basef1` + `T:`) | SA-06 (mueve el reloj: va **último** y la hora se comprueba después), SF-01a (re-ancla al sustituto con `e1c6f516`), SF-04 (detiene SQL Server) |
| **`restaurar` (nivel V)** | **`LAB-172-a2b`:** RS-01 y RS-02 seguidos (sin restaurar entre ambos), RS-03, RS-04b y e a i, RS-05a a e y h, RS-06, RS-08 a RS-12. **`LAB-171-a`:** RS-04a, RS-04c y RS-04d | `Preparar-Paquetes` y `Montar-A` (parten de `base`) | RS-05f y RS-05g ("dejan la VM sucia: restaurar el punto"); **RS-07 al final** (corte de energía con `poweroff`) |
| **Spike DE-01** | `LAB-150-sqllisto` (rama pura y rama del MSI); `LAB-151-spikeverde` (negativos DE-01-N1 a N6, cada uno desde ese punto, Chromium, DE-16 al final); `LAB-152-msiconfigurado` (A5, R2/R4, D3/D5, R3, cada uno restaurando el punto) | SPK-P0 | DE-16 |
| **`tls` F2** | Las sesiones F2-A y F2-C con `VM-SRV` sola; F2-B con `VM-SRV` y `VM-PUESTO` | W-TLS-01 a 04 antes de LABT-01 | LABT-08(c) (50 muertes súbitas), LABT-13 (TPM) |

**Entre líneas no se comparte nada.** Cada una crea sus propios servicios y exige que no haya otros: `Probar-LlaveFirmaTpm.ps1 Preparar` crea un servicio `GPOS.Api` temporal; el MSI crea `GPOS.Api`; `DE-01-preparar` crea `GPOS.Api` con `sc create`; la fase `servicios` de `restaurar` crea `GPOS.Api` y `GPOS.Reportes`. Al cambiar de línea: apagar, restaurar `base`, arrancar y repetir 2.3 (#16 a #18).

**Lo que sí se comparte entre dos líneas:** el SQL Express preparado y el usuario `gpos-lab-usuario` (spike y anillo): un punto como `LAB-150-sqllisto` puede servir de arranque a las dos **si el paquete del DEMO se extrae después** (el del anillo sale de `b/f1-anillo` y el del spike de un commit con #174 y PR-4 de `feature/modelo-ng`; son paquetes distintos).

---

## 4. Las tres ventanas

Convenciones: **Min** = minutos de casos según la fuente [I, ±50 %]; las restauraciones se cuentan aparte (unos 3 min cada una [I]). "Parte de" es el punto de control. "Toma" y "Restaura" son acciones de B con `Puntos-Control.ps1` (alias de 2.4). Todos los casos corren con las variables de 2.3 (#17) en una consola elevada de 64 bits, salvo los que dicen lo contrario. **Orden de recorte** al final de cada ventana: lo último de la lista se corta primero.

### 4.1 V1: llave de firma con vTPM y núcleo del `GPOS.Api.msi` (≈ 6 h 15; sin SQL)

**Antes (B, fuera de la ventana):** compilar los MSI en la PC de construcción (`-Caso B2`, 15 min, más B1 y B3, 15 min: guarda G-PR4 y firma, no tocan la VM); publicar `GPOS.Migracion` (Release); habilitar el vTPM y tomar `LAB-160-antes` (2.2, #12 y #13); resolver D-R1.

**Parte A: TPM (100 min, `evidencia\TPM`).** Estado: `LAB-160-antes` (vTPM 2.0, sin MSI). Guion: `Probar-LlaveFirmaTpm.ps1`.

| # | Paso | Min | Toma / restaura | Qué decide |
|---|---|---|---|---|
| A1 | Verificación previa (2.1 a 2.3) con `LAB-160-antes` restaurado; `-Caso Lista`, `-Caso Guardas` | 10 | — | Stop si `Guardas` dice que no hay TPM 2.0 listo o que hay llaves del producto ya presentes en el TPM |
| A2 | `-Caso Preparar -PuntoControl LAB-160-antes`; B toma `LAB-161-preparado -EnVivo` | 10 | toma 161 | — |
| A3 | Opcional: `-Caso Sonda-Consola` en una consola **sin elevar** (repite la medida de mi PC) | 5 | — | — |
| A4 | `-Caso T1 -PuntoControl LAB-161-preparado` (sin llave de máquina) | 10 | — | H120P-01 (a) y (d) |
| A5 | `-Caso T2 -Migracion C:\GPOS-LAB\migracion\GPOS.Migracion.exe` (verbo real); `-Caso T3` | 20 | toma `LAB-162-conllave -EnVivo` | S120-02 (c) |
| A6 | `-Caso T4 -PuntoControl LAB-162-conllave` | 10 | — | H120P-01 (b) |
| A7 | `-Caso T5`; reiniciar; variables otra vez; `-Caso T5-tras-reinicio`; B toma `LAB-163-despues -EnVivo` | 20 | toma 163 | H120P-01 (d) |
| A8 | `-Caso Decision`; `-Caso Limpiar`; copiar `C:\GPOS-LAB\evidencia\TPM` al anfitrión | 10 | restaura `LAB-160-antes`, `Guardas` (ninguna llave en el PCP) y luego `base` | — |

*Criterio de parada de la parte A:* `Guardas` con `TpmReady = False` o TPM 1.2 → `Bloqueado`, se pasa a la parte B y se me avisa; un "No se pudo" por control sin distinguir **no** se convierte a mano en "Cumple". La salida de `Decision` es una **recomendación** (decide B con el arquitecto, firma el propietario); `T2` en `Bloqueado` (sin runtime) deja solo la réplica de `Crear` (T3) y obliga a repetir T2.

**Parte B: núcleo del MSI (≈ 192 min, `evidencia\API`).** Estado de partida: `base` restaurada, `gpos-lab-usuario`, archivos copiados y verificados → `LAB-140-baseok`. Guion: `Probar-GposApiMsi.ps1` (con `Probar-Instalador.ps1` en `Guardas`).

| # | Caso | Parte de | Min | Toma / restaura | Notas |
|---|---|---|---|---|---|
| B0 | `Guardas` en `Probar-Instalador.ps1` y `Probar-GposApiMsi.ps1`; anotar MSI y SHA-256 | `LAB-140-baseok` | 5 | toma 140 (una vez, antes) | — |
| B1 | **I1** instalación limpia (Crítica) | 140 | 25 | toma `LAB-141-instalado` | Si I1 da `No cumple`: Crítica, ver parada |
| B2 | **I2** publicación = `publicacion.sha256`; **I3** privilegios exactos; **I6** el MSI no escribe entorno, red ni secretos | 141 (restaurar entre uno y otro) | 15 + 20 + 15 | restaura 141 tras I3 (el control añade un privilegio de más) | I2, I3 e I6 son Crítica |
| B3 | **R1** cuántas veces se reinicia (usa `-Minutos`, 10 por omisión) | **141 restaurado** | 25 | restaura 141 después | Control incluido: `sc failure … none` |
| B4 | **O1** subcasos `a,c,d,e,h` (`-Subcasos a,c,d,e,h`; **h** es el control positivo: sin h no hay `Cumple`) | 140 | 22 | restaura 140 entre subcasos que planten carpetas | — |
| B5 | **N1** (usuario estándar y administrador sin elevar; `N1a-instrucciones`, `N1b-ejecutar` sin elevar) y **N3** (servicio preexistente) | 140 | 30 | restaura 140 | N1 es Crítica |
| B6 | `Sembrar-Centinelas`; instalar v1 → B toma `LAB-143-v1`; **A2** (`Environment` sobrevive a la actualización) y **P2** (la reparación no borra la configuración) | 140 → 143 | 40 | toma 143 | A2 usa `GPOS.Api-SINFIRMA-v2.msi` |
| — | Reserva si sobra: **D1 + D2** (20), **I7** con `I7-cuenta` sin elevar (25), **P1** (20), **S1** (20) | 141 / 143 | — | — | Ver orden de recorte |

*Orden de recorte de V1:* primero se cae N3, después P2, después O1, después B6 entero; **I1, I2, I3, I6, R1 y N1 no se cortan.**

**Cierre de V1 (30 min):** recoger `TPM` y `API` (7), restaurar `base -Apagar`, borrar `LAB-14x` y `LAB-16x` si ya se recogieron, acta.

**Criterio de parada de V1:** I1, I3 o I6 `No cumple` (Crítica): se detiene la parte B, se restaura 141 o 140, se anota y se avisa antes de seguir; el resto de V1 no se corre sobre un servicio instalado con defecto. Un fallo de `Guardas` o un `Id` de marcador distinto detiene todo. Cualquier secreto visible en consola o historial: se detiene, no se archiva ese archivo y se avisa al auditor.

### 4.2 V2: anillo de F1 (≈ 5 h 55; con SQL Express)

**Antes (B, fuera de la ventana):** F1 con SF-01 a SF-04 y SF-06 corregidos (nuevo sha); responder las cuatro decisiones del #234 (D-R4 a D-R7); publicar `GPOS.Migracion` self-contained y el paquete del DEMO de `b/f1-anillo`; adjuntar el disco `T:` (2.2, #15).

**Preparación específica (en la ventana, dentro de los 30 min previos):** SQL Express en `Running`; `Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -Paquete C:\GPOS-LAB\paquete\GPOS-Demo` **sin** `DE-01-probar` (la API no debe haber arrancado con DPAPI: `Api\anillo` vacío); `Probar-Anillo.ps1 -Caso Guardas`; `-Caso Par-Recuperacion` (anotar la huella de `rec.cer`: es la "dictada" de SA-01); B toma `LAB-164-basef1`.

| # | Caso | Parte de | Min | Toma / restaura | Notas |
|---|---|---|---|---|---|
| 0 | `Guardas`, `Par-Recuperacion` | `base` + DE-01-preparar | 15 | toma `LAB-164-basef1` | — |
| 1 | **SA-01** `-HuellaRecuperacion <huella dictada>` (cinco negativas y la positiva; Crítica) | 164 | 15 | — | Stop si da `No cumple` |
| 2 | **W-AN-01**, **W-AN-02** (perfil, no exportable, descriptor y ACL del contenedor; Crítica) | tras SA-01 | 35 | — | Stop si dan `No cumple` |
| 3 | **SF-03** (`-Sentido hallazgo` con `e1c6f516`; `remedio` con el sha corregido) | tras SA-01, sin `GPOS_SYSDATA` | 10 | — | Crea la base |
| 4 | **G-2** | tras SF-03 | 10 | — | — |
| 5 | `Entorno-Anillo`, **W-AN-03** (con SF-03 abierto el paso `sistema` falla: se anota y se sigue con `--anclar` y `--cuentas-iniciales`) | tras G-2 | 30 | toma `LAB-165-anillolisto` | — |
| 6 | **G-1** | 165 | 20 | restaura el archivo | — |
| 7 | **W-AN-05** (doce variantes; usa la lectura en memoria del `Environment`, decisión D-R4) | 165 | 45 | cada variante restaurada por el guion | Si no, `-Variantes` excluye las que lo necesitan |
| 8 | **SA-03a** | 165 | 15 | — | — |
| 9 | **W-AN-04-respaldar** (a `T:`); restaurar `LAB-164-basef1`; **W-AN-04-recuperar** (el custodio teclea la contraseña del PFX; se borra el PFX de `T:` al terminar) | 165 → 164 + `T:` | 50 | restaura 164 | Sin `T:` este caso es `No se pudo` |
| 10 | **SF-01a** (destructivo con `e1c6f516`) | 165 | 15 | restaura 165 después | Va último |

Total de casos: 260 min. *Orden de recorte:* SF-01a, SA-03a, W-AN-04 (los dos pasos juntos), G-1; **SA-01, W-AN-01, W-AN-02, W-AN-03 y W-AN-05 no se cortan.** Quedan fuera: SF-08 (15), SA-03b y SF-04 (30), SF-02, SF-01b, SA-02, SA-06 (70, el último cambia el reloj) y LABA-05, 11, 12 y 14 a 20 (sin guion).

**Criterio de parada de V2** (el del LEEME del #234): SA-01, W-AN-01 o W-AN-02 en `No cumple` es Crítica: se detiene la ventana y se avisa. Un caso con `restaurado = false`: se restaura el punto antes de seguir. Si algo falla no se corrige a mano. Una `Sentido` equivocada (`remedio` frente a `hallazgo`) invalida el caso: B anota con qué sha corrió.

### 4.3 V3: `restaurar` de PR-D2, nivel V (≈ 5 h 50; sin SQL ni anillo)

**Antes (B/A, fuera de la ventana):** el sha final de `a/pr-d2-manifiesto` y los paquetes PQ-A y PQ-B (A, 28-oct); análisis de sintaxis de `Probar-Restaurar.ps1` (no se pudo correr); decidir si se publica además una línea base en `812d1790` para comparar O-1/O-3 antes y después (D-R8).

| # | Caso | Parte de | Min | Toma / restaura | Notas |
|---|---|---|---|---|---|
| 0 | `Guardas`; `Preparar-Paquetes -PublicadoA C:\GPOS-LAB\publicado\A -PublicadoB C:\GPOS-LAB\publicado\B`; B toma `LAB-170-listo`; `Montar-A` → `LAB-171-a`; `Montar-A2B` → `LAB-172-a2b` | `base` | 60 | toma 170, 171, 172 | PRE-3; `Montar-A` y `Montar-A2B` arrancan **sin** `--origen` en `--fase carpetas` (O-1) |
| 1 | **RS-01** (camino feliz) y **RS-02** (idempotencia), seguidos | 172 | 35 | — | **RS-01 tiene que quedar en `Cumple`:** es el control externo de los subcasos que no pueden deshacer lo plantado. Si no, se detiene la ventana |
| 2 | **RS-03** (proceso suelto) | 172 | 20 | restaura 172 | — |
| 3 | **RS-04a** a **RS-04i** (cada rechazo de la copia previa) | a, c, d desde 171; el resto desde 172 | 45 | restaura entre subcasos | `--forzar` y `--sin-verificar` en RS-04c |
| 4 | **RS-05a** a **RS-05h** (carpetas y objetos peligrosos) | 172 | 50 | restaura 172; RS-05f y RS-05g dejan la VM sucia | RS-05f/g documentan P-D2-04 |
| 5 | **RS-06a**, **b**, **c** (archivo bloqueado, marca `.aplicando`) | 172 | 40 | restaura 172 | Registra el estado real de R-04 |

Total de casos: 250 min. *Orden de recorte:* RS-06c, RS-05f/g, RS-04 (g, h, i), RS-03; **RS-01, RS-02, RS-05 a e y RS-06a/b no se cortan.** Quedan fuera: RS-08 (20), RS-09 (25), RS-10 (15, más 35 de RS-10f/g/h/i que el #223 aún no trae), RS-11 (20), RS-12 (30) y **RS-07** (30, corte de energía, va al final de la sesión que lo incluya).

**Criterio de parada de V3:** RS-01 `No cumple` (el instrumento no ve la diferencia: nada de lo que sigue vale); cualquier escritura fuera del destino en RS-05 (se anota y se restaura, no se sigue sobre una VM con un archivo escrito fuera); paquete cuyo SHA-256 no coincide con el anotado.

---

## 5. Lo que queda fuera de las tres ventanas

### 5.1 Pendiente por línea (unas 50 h netas [I, ±50 %])

| Línea | Qué queda | Horas | Condición |
|---|---|---|---|
| MSI | Resto de las sesiones S-1 a S-3: A1, A3, A4, A6, A6b, A7, P1, P3, D1, D2, D4 a D6, R3, R4, S2 a S5, I4, I5, I7 a I9, O2 a O5, N2, N4 a N6, O6 (FIPS, al final), FIR-1 (Q-6) | ≈ 9,5 | — |
| Anillo | SF-08, SA-03b, SF-04, SF-02, SF-01b, SA-02, SA-06 (cambia el reloj: mide MC-12, MC-29, MC-31) y los LABA sin guion | ≈ 2 (+ guion) | Nuevo sha de F1 |
| `restaurar` | RS-07, RS-08 a RS-12 y RS-10f/g/h/i | ≈ 3 | — |
| Spike DE-01 | S-1 (3 h 20), S-2 (4 h 25, con `VM-PUESTO`), S-3 (3 h 25, rama del MSI) | ≈ 11 | `-ServicioDelMsi`, `VM-PUESTO`, fecha |
| `Instalar-Demo.ps1` nivel G | ID-02 a ID-09 y ajustes de RV-06, RV-08, RV-09 | ≈ 4,5 | Guion y corrección de A |
| PR-D2 nivel G y A | S7 (≈ 6 h) y S8 (≈ 6 h; EM sustituido por AP-01 a AP-08 de D-5 (c)) | ≈ 12 | Instalador de servicios y F1 unida |
| `tls` F2 | F2-A, F2-B, F2-C | ≈ 9,5 | Verbo construido (10-nov) |
| PR-V | LABP-10, 13, 15 y los que haya | [?] | PR-V unido |
| `VM-LNX` | PVL-01 a 20 y LLL-01 a 11 | ≈ 2 | La VM instala |

### 5.2 Intercambios razonables si el propietario prioriza otra cosa

Los bloques siguientes pesan lo mismo y se pueden cambiar sin romper dependencias:

| Si se prioriza | Sale | Entra | Nota |
|---|---|---|---|
| **El spike (decide D-2 y D-4, "antes de D4")** | V3 (`restaurar`) | S-1 del spike (3 h 20) más el resto del MSI de V1 que se cortó | S-1 solo exige `VM-SRV`; S-2 y S-3 piden `VM-PUESTO` y el cambio de guion |
| **La llave de firma antes de conectarla en D2** | nada: ya está en V1 | — | Si V1 se aplaza, hacer el TPM solo (1 h 40) en cualquier hueco |
| **Menos riesgo de que A espere** | V2 (anillo) | `restaurar` completo (RS-07 a RS-12) | El PR-D2 de A depende de RS-01 a RS-06 y del sha final |

**No recomiendo** ensanchar una ventana a más de 6 h: el laboratorio pierde calidad de atención (decisiones a mano, restauraciones saltadas) y la evidencia queda fuera del orden previsto (`revision-evidencia.md` D).

---

## 6. Criterios de parada generales

1. **Parar la ventana:** falla `Guardas` o `Preparar-Vm.ps1 -Comprobar` tras restaurar `base`; el SHA-256 de un archivo copiado no coincide (se recopia una vez; si vuelve a fallar, se para); el marcador tiene `Id` retirado; aparece un secreto en la consola, el historial o un archivo que se iba a archivar; `LFMB` se queda sin RAM o sin disco a media sesión; llega una suite o una compilación al anfitrión.
2. **Parar una línea y pasar a la siguiente:** el primer `No cumple` Crítico de esa línea (listados en 4.1 a 4.3). Se restaura el punto, se anota y se avisa antes de seguir **dentro** de la misma línea.
3. **No se corrige a mano para que pase.** Un caso que falla por una precondición ausente es `No se pudo` (nunca `Cumple`). Los casos `Bloqueado` por diseño (MSI: A5, D3, R2, FIR-1) no se intentan.
4. **Ningún caso empieza** si no puede terminar 30 min antes del final de la ventana (hace falta cerrar, recoger y restaurar). A las 6 h 30 se cierra aunque queden casos.
5. **Un caso sin control medido no da `Cumple`** (regla de todos los guiones). Si el control no distingue, el guion da `No se pudo`.
6. **Reloj (LS-15):** ningún caso de las tres ventanas mueve el reloj (SA-06 queda fuera). Si se añade SA-06 en otra ventana: va último, `Set-Date` no pasa de los 3 días del caso, se comprueba la hora después de restaurar (el guion del anillo explica por qué no se adelanta solo el reloj) y el acta anota que las horas de `ANILLO\SA-06.json` están desplazadas.

---

## 7. Evidencia: qué se archiva, cómo y quién la revisa

**Dónde se genera (dentro de la VM, `C:\GPOS-LAB\evidencia\`):**

| Línea | Carpeta | Contenido |
|---|---|---|
| Preparación | `preparar-vm-VM-SRV-<fecha>.json` | Comprobaciones, SHA-256 del guion y de `hosts`, UBR, FIPS, SQL |
| TPM | `TPM\` | `<caso>.json`, `Preparar.json`, `Decision.json`, `T2-verbo-salida.txt`, `T2-verbo-errores.txt`, `estado.json` |
| MSI | `API\` | `<caso>.json`, los `.log` de `msiexec /l*v`, carpetas `Foto` |
| Anillo | `ANILLO\` | `<caso>.json` con `procedencia` (SHA-256 del guion, de `GPOS.Migracion.exe` y de `GPOS.Api.exe`) |
| `restaurar` | `D2\` | `<caso>.json`, `<caso>-salida-N.txt` y `<caso>-*.snap` |

**Cómo sale y se revisa:**

1. En la VM, copiar la carpeta de la línea (por `guestcontrol copyfrom` [I]) a `M:\VM\traido\VM-SRV\<AAAA-MM-DD>-V<n>\`.
2. En `LFMB`: `Recoger-Evidencia.ps1 -Vm VM-SRV -CarpetaInvitado M:\VM\traido\VM-SRV\<AAAA-MM-DD>-V<n>`. Escribe **solo** dentro de `M:\VM\evidencia`, redactada y con `manifiesto.json`. Los binarios no se copian salvo `-IncluirBinarios` por nombre, y quedan marcados para revisión visual.
3. SHA-256 de cada MSI, paquete y guion en el acta; el `.json` ya lleva el del guion y de los ejecutables.
4. Revisión con `revision-evidencia.md`: **A** procedencia (cabecera completa, `preparar-vm-*.json` con todo en `cumple: true`, SHA-256 coincidentes, cada caso desde el punto que pide el plan), **B** guardas (G-N1 a G-N4 corridos, `Guardas: cumplidas` en cada guion), **C** secretos (nada de `Jwt__Clave`, `Environment`, cadenas de conexión, tokens, PFX, contenido del anillo; solo presencia y huella; los registros de `msiexec` no muestran propiedades sensibles; `Probar-Redaccion.ps1` en verde), **D** resultado de cada caso (el `resultado` sale de lo `observado`; en los Críticos y Altos se recalcula a mano; `No se pudo` y `Bloqueado` nunca cuentan como `Cumple`; horas dentro de la ventana y en el orden del plan), **E** recomendación técnica (`Rechazado` con un hallazgo Crítico o Alto; `Aprobado con observaciones` con Media, Baja o `Bloqueado`; `Aprobado` solo con todo `Cumple`; **la decisión es de B y del propietario**).
5. El auditor de seguridad de A revisa antes de publicar fuera del área común. La evidencia en bruto no va al repositorio `GPOS NG`.

**Casos con revisión reforzada (sección D de `revision-evidencia.md`):** los de severidad Crítica o Alta de cada línea: I1, I2, I3, I6, N1 (MSI); SA-01, W-AN-01, W-AN-02, W-AN-03 (anillo); RS-01, RS-05 (restaurar); T1 a T4 (TPM, hallazgos Alta).

**Entregable de cierre por ventana (B, mismo día):** informe con tabla caso → resultado → severidad si no cumple, lista de `No se pudo` y `Bloqueado` con motivo, puntos de control tomados y restaurados, y las desviaciones del runbook. Yo reviso la evidencia ya redactada y devuelvo observaciones.

---

## 8. Dependencias y conflictos

| # | Qué | Efecto | De quién |
|---|---|---|---|
| X-1 | **Patrón de nombres de puntos de control** (2.4): 10 nombres no pasan `Puntos-Control.ps1`; `-PuntoControl` de `Probar-GposApiMsi.ps1` y `Probar-LlaveFirmaTpm.ps1` rechaza los mismos; el ejemplo de `Probar-GposApiMsi.ps1` usa un nombre inválido | Sin remedio, B no puede tomar `LAB-D2-*`, `LABA-*`, `LAB-140`, `LAB-150` a `LAB-152` ni `LAB-162` con la herramienta | C (defecto propio), B decide D-R1 |
| X-2 | **Solo un `GPOS.Api` a la vez:** MSI, TPM, spike, anillo y `restaurar` se excluyen entre sí | Restaurar `base` entre líneas; ninguna ventana mezcla dos líneas sin restauración | Diseño |
| X-3 | **TPM y MSI:** el guion del TPM se niega si el MSI está instalado (salvo `-PrestarServicioMsi`) | El TPM va **antes** del MSI en V1 y desde `LAB-160-antes` | C |
| X-4 | **vTPM y puntos de control:** el vTPM debe estar en la configuración del punto (2.2 #13). Las llaves de máquina quedan en el vTPM y puede que no se restauren | `Limpiar` del guion antes de restaurar; `Guardas` tras restaurar | B |
| X-5 | **Anillo (V2) espera a B:** SF-01 (Alta) a SF-04 y SF-06 en un sha nuevo; hasta entonces `-Sentido hallazgo` en SF-01a y SF-03 | Hasta el sha nuevo, los casos SF dan `No cumple` en `remedio`; no son ruido: son el residuo reproducido | B |
| X-6 | **Cuatro decisiones del #234** (D-R4 a D-R7) | Sin ellas, W-AN-05 puede perder variantes y W-AN-04 no tiene medio | B |
| X-7 | **`restaurar` (V3) espera a A:** sha final de PR-D2 y paquetes PQ-A/PQ-B (28-oct) | Sin paquetes no se corre RS-01 a RS-12 (aviso de B del 2026-10-24) | A |
| X-8 | **Paquete del spike frente a la restricción de PR-D2:** el spike pide un DEMO de `feature/modelo-ng` con #174 y PR-4; B prohíbe publicar un DEMO desde `feature/modelo-ng` tras T4-06 | Para el spike hay que fijar el commit (anterior a T4-06 o una rama con #174 sin T4-06) [?] | B |
| X-9 | **Spike frente a SPK-P0:** el spike crea el servicio con `sc create`, no con el MSI; A5, D3 y R2 del MSI exigen la rama del MSI con `-ServicioDelMsi` | Mientras no esté el cambio de guion, esos casos siguen `Bloqueado` | C/A, Q-3 |
| X-10 | **VM-PUESTO sin crear y `VM-LNX` sin instalar** | Spike S-2, `tls` F2-B y SPK-C5 quedan `No se pudo`; las líneas de V1 a V3 no las necesitan | B |
| X-11 | **`Instalar-Demo.ps1` y D-5 (c):** `ID-02` se escribió para "llegar al BORRADOR"; con D-5 (c) el instalador gana el paso `aprovisionar` (orden: `servicios` → `anillo --preparar` → `esquema` → empresa → `lectura`) y la comprobación de sysadmin previa (C-1 del contraste) | `Probar-InstalarDemo.ps1` se escribe después del 9-nov contra el contrato nuevo, no contra `812d1790` | A, C |
| X-12 | **EM-01, EM-02, EM-07 sustituidos por AP-01 a AP-08** | El bloque EM de `2026-10-23-casos-laboratorio-pr-d2.md` no se corre | C |
| X-13 | **F2 de `tls` necesita** `GPOS.Api.msi` **y** `GPOS.Web.msi` instalados (cuentas virtuales) y el verbo `red` de PR-V con `ModoRed=ServidorSitio` | `GPOS.Web.msi` no aparece en ningún inventario que leí [?]; sin él LABT-xx quedan `No se pudo` | B/A |
| X-14 | **Estimaciones:** el anillo suma 6 h 15 (no 5 h 30) y el MSI 12 h 45 (no 12,5) | Se corrige el LEEME del #234 cuando decidas D-R1 | C |
| X-15 | **sha de #234:** `5b5cfab7` (aviso) frente a `29237917` (rama remota), mismo árbol | El acta anota el SHA-256 del archivo, no el commit | B |
| X-16 | **LNX:** `limpiar-laboratorio.sh --huellas` exige `huellas.txt` en 64 hexadecimales en minúscula, ruta real dentro de `/var/lib/gpos-lab/evidencia`, dueño root | Cuando exista `VM-LNX`; el generador de B debe escribir ese formato | B |

---

## 9. Dudas para B (D-R1 a D-R10)

- **D-R1.** Puntos de control: ¿aceptas los alias de 2.4 (cambian `Probar-Anillo.ps1:86`, textos de `Probar-Restaurar.ps1`, el ejemplo del MSI y el LEEME del TPM; ≈ 0,2 dp, un PR de `tests/` mío) o prefieres ensanchar `PatronPuntoControl` (más código tuyo y SL-06 vuelve a revisión)? Recomiendo los alias.
- **D-R2.** ¿Cuál es la **primera** ventana? Los avisos dicen "tu primera ventana" para el MSI (#226) y "primera ventana de F1" para el anillo (#234). Propongo V1 = TPM + MSI, V2 = anillo, V3 = `restaurar`.
- **D-R3.** ¿El spike DE-01 entra en las tres ventanas (23-nov propuesto) o queda para una cuarta? Decide D-2 y D-4.
- **D-R4 a D-R7.** Las cuatro decisiones del #234: lectura en memoria del `Environment`; disco VDI writethrough para `T:` (las carpetas compartidas están prohibidas, SL-11); SF-03 (a) en F1 o (b) en el orden interno de `FaseEsquema`; `GPOS.Migracion` self-contained.
- **D-R8.** ¿Se publica además una línea base en `812d1790` para comparar O-1/O-3 antes y después de la corrección de A?
- **D-R9.** Fechas de las tres ventanas dentro del 16 al 27-nov, quién teclea las contraseñas y quién recoge la evidencia (D-9 de mi plan de PR-D2).
- **D-R10.** Copia a la VM: ¿`guestcontrol copyto` con `--password-file` o disco de solo lectura? ¿El `LFMB` mantiene `M:\VM\paquetes\<ventana>\` con los hashes?
- **D-R11.** ¿`VM-SRV` ya tiene el vTPM? ¿`Microsoft.NETCore.App 10` está en la VM o se publica self-contained también para el TPM (T2)?
- **D-R12.** ¿Se puede disponer de `LFMB` sin WSL2/Docker para llegar a 5 120 MB libres? Si no, la ventana no arranca.

---

## 10. Qué no verifiqué

- No ejecuté ni compilé nada; no corrí PowerShell ni `VBoxManage`. La comprobación de los nombres de puntos de control es de la **expresión regular** (`grep -P`) leída de `Comun-Laboratorio.ps1:56`, no del script en acción.
- Las duraciones son las de mis documentos, que se escribieron sin ejecutar los casos; no sé si incluyen las restauraciones (los conté aparte). El total de 65 h y el de 50 h son sumas mías de esas cifras.
- `guestcontrol copyto/copyfrom`, `--password-file`, `--tpm-type`, la restauración del vTPM por un punto de control, el comportamiento de un disco writethrough en una VM con instantáneas, `slmgr /dli` y `wsl --shutdown` son [I].
- No leí `GPOS.Web.msi` (no sé si existe), ni el árbol real de instantáneas de `VM-SRV`, ni los puntos que ya existen.
- Los SHA-256 son los de los blobs de las ramas remotas al 2026-10-23; si una rama se actualiza, cambian. El acta debe registrar el commit y el SHA-256 de lo que B copia.

### Cierre
- Estado: Completado (runbook redactado; nada ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-runbook-tres-ventanas-laboratorio.md`
- Supuestos: tres ventanas de 5 a 6 h con los guiones de #223, #226, #233 y #234 como núcleo; duraciones de mis documentos [I, ±50 %]; la VM es `VM-SRV` con 3 584 MB y la ventana no usa `VM-PUESTO`.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → D-R1 a D-R12 (nombres de puntos de control, primera ventana, spike, decisiones del #234, copia a la VM, RAM de `LFMB`); A → sha final de PR-D2 y paquetes PQ-A/PQ-B (28-oct), contrato de la corrección de O-1; C (yo) → PR chico de `tests/` con los alias de puntos de control cuando B decida D-R1.
- Próximo paso recomendado: decidir D-R1 y D-R2 y, con eso, aplicar los alias de puntos de control antes de que B tome el primero.
