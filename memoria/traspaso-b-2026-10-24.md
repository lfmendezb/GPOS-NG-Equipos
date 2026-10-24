---
name: traspaso-b-2026-10-24
description: "LEER PRIMERO (B): cierre del 24-oct mañana; C fuera de servicio (todo a A); F1 corregida 26f54eaa; firmas D-5 (c), C-T01 (a), 4704, SA-01 ampliada; laboratorio V1 en VM-SRV: I1 e I2 cumplen, el resto bloqueado por el guion; VM apagada"
metadata:
  node_type: memory
  type: project
  originSessionId: 98f9e30b-36c1-42f3-9da4-8f581795e99c
  modified: 2026-10-24T11:59:52.914Z
---

Sigue a [[traspaso-b-2026-10-23-noche-2]] y [[traspaso-b-2026-10-23-tarde]] (reglas de trabajo). Sesión nueva: leer esto, `MEMORY.md`, `git fetch`, `git pull --rebase` del área común, `gh pr list --state open`, armar el Monitor sobre `novedades-B.md`.

**Puntas:** `master` `61a789f7` (#230 unido); `feature/modelo-ng` `1b310591`. Verificar con fetch.

**Equipo C fuera de servicio desde el 24-oct** ([[dos-equipos-a-coordina]]): todo lo de C pasó a A (`avisos/B-a-A/2026-10-24-c-fuera-de-servicio-traspaso-de-c-a-a.md`): PR #156, #147, #223, #224, #226, #229, #232 a #237, guiones de laboratorio, runbook (`traspasos/C/2026-10-24-runbook-tres-ventanas-laboratorio.md`) y planes. A no revisa sus propios PR (#220, #225, #238, #239, C-T01, PR-D2): esas revisiones adversariales las hace B con un agente independiente. Esperar acuse de A con fechas; 1.1 (cuelgues del #226) y 1.2 (cuenta `gpos-lab-usuario`) bloquean el laboratorio.

**Firmado por el propietario (23 y 24-oct):** D-5 opción (c) y orden de fases de PR-D2 (empresa inicial con `GPOS.Migracion aprovisionar` como sysadmin del instalador; sin `dbcreator` en la API; no cambia la creación de empresas por la interfaz en Amplio); hoja en master por #230. EventId del anillo **4704** (no 4729); precisión en la hoja de tls (rama #221). **SA-01 ampliada** a `anillo --migrar` y `--cambiar-recuperacion` (rama #221). **C-T01 (a):** alcance de sucursal ya en `ConsultaFacturasService` (hoja #231 sin unir; A implementa, fecha 31-oct).

**F1 (#228):** corregida SF-01 a SF-04 y SF-06 en `26f54eaa` (442/442 verificado por B, empujado). Revisión de C sobre `26f54eaa`: Aprobado con observaciones; quedan TF-01 (salida 2 también con ancla alterada: usar 4) y TF-02 (4060 por login huérfano: comprobar `DB_ID`), 0,05 dp cada una, y R228-07 de A (textos de G-1 y G-2 sin `--huella-recuperacion`). Después pedir orden de unión. Blueprint #219 corregido a 4704 (`c087932a`).

**Tandas publicadas:** 9 y 10 a A y C (ya reasignadas a A), avisos de D-5, C-T01, 4704 y SA-01. A abrió #238 (correcciones del #210) y #239 (PR-V) y publicó la nota de reparto de D5 de DB-7 (pendiente de firma del propietario).

**Laboratorio V1 (VM-SRV, 24-oct madrugada):** VM **apagada**, punto de control actual tras `LAB-145-parche`. Puntos: `antes-preparar-vm`, `base`, `LAB-160-antes` (vTPM, sin llaves), `LAB-140-baseok` (base + guiones y MSI verificados), `LAB-145-parche` (con mi parche de `Dacl-ClaveServicio`), `LAB-141-instalado` (MSI v1 instalado). Archivo huérfano de 497 MB `{a3f03076…}.vdi` en `M:\VM\GPOS-LAB\VM-SRV\Snapshots` (de la captura en vivo abortada; revisar antes de borrar). Evidencia en `M:\VM\evidencia\V1`. Resultados: vTPM `Guardas` cumplidas, T1 «No se pudo» (sonda sin salida; C publicó trazas en #233 @ `5fe0bf66`, sin repetir). MSI: `Guardas` OK, **I1 Cumple, I2 Cumple**, I6 No cumple por falso positivo del patrón (C lo corrigió en #226 @ `1a8cc3e0`), I3/R1/N3 se cuelgan sin salida, O1 aborta (stderr nativo terminante en PS 5.1, `takeown /d y` en es-ES, SID virtual sin servicio), O1a/N1/I7 necesitan `gpos-lab-usuario` (no existe; los agentes no crean cuentas: la crea el propietario).

**Lecciones del laboratorio:** `guestcontrol` con `Administrador` (misma clave que `gposlab` por `--admin-password-file`; `gposlab` da token filtrado); los puntos de control en vivo se cuelgan con vTPM/EFI: siempre con la VM apagada (`Stop-Computer -Force` desde un .ps1; `shutdown.exe` y `acpipowerbutton` no apagan); restaurar borra lo copiado y la evidencia posterior: sacar evidencia antes (función `Sacar-Evidencia`); guiones parchados siempre con BOM (PS 5.1); la guarda SL-12 exige 5.120 MB libres (cerrar Edge en segundo plano bastó). Ayudantes en el scratchpad de esta sesión (`Lab-Lib.ps1`, `Lab-Vm.ps1`, `Invocar-EnVm.ps1`, envoltorios): reconstruirlos si la sesión nueva no los ve. MSI en `C:\Temp\gpos-api-msi` (B2 Cumple, `Get-MsiTabla -Comprobar` 0); `GPOS.Migracion` Release en `C:\Temp\migracion-publicada` (SHA-256 del .exe `25380EDA…10F7`).

**Pendientes del propietario:** orden de unión de #231 y de los PR de hojas (#221, #222, #227); `VM-PUESTO` no se crea por ahora (dijo que no); firma de la nota de A sobre D5 de DB-7; Q-3/Q-4/Q-7 del MSI; R205-05; `CODEOWNERS` y revisión humana de los 95 dorados.

**Qué hacer primero:** leer el acuse de A al traspaso; cuando A publique el #226 corregido, repetir en VM-SRV (desde `LAB-145-parche`/`LAB-141-instalado`) I3, I6, R1, O1 y N3, y T1 del vTPM con `5fe0bf66`; TF-01, TF-02 y R228-07 en F1; revisión adversarial independiente (agente de B) de los PR de A.
