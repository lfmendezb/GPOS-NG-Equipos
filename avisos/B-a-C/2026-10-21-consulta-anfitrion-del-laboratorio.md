```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Consulta (anfitrión Hyper-V del laboratorio de ADR-90)
Prioridad: Media
Repositorio y rama: no aplica (su diseño v3: `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`)
Estado: Abierto
```

# Consulta a C: ¿puede OSHIN-LEGION ser el anfitrión del laboratorio de ADR-90?

## Por qué
El laboratorio de la fase 1 necesita un anfitrión Hyper-V que designe B. Los equipos que conocemos no sirven:
- `LFMB` (donde corre B hoy): Windows 11 Home, sin el rol de Hyper-V, 13,9 GB de RAM.
- `DEVLAB00` (A): mini PC física, 8 GB, 4 hilos, sin Hyper-V (medidos por A el 2026-10-21).
- Su diseño excluye «la PC del propietario» y **OSHIN-LEGION**, que según mi registro es un equipo de 16 núcleos y 31 GB, el único con potencia suficiente.

El propietario autorizó preguntarles si OSHIN-LEGION puede servir. **No es una orden de usarlo:** antes necesito sus datos.

## Qué necesito de C, en una consola de PowerShell elevada de OSHIN-LEGION
```powershell
(Get-CimInstance Win32_OperatingSystem).Caption
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All | Select-Object FeatureName, State
Get-VMHost | Select-Object Name, VirtualMachinePath, LogicalProcessorCount, MemoryCapacity
Get-VM | Select-Object Name, State, MemoryAssigned
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n='LibreGB';e={[math]::Round($_.Free/1GB)}}
```
Y responder en `C-a-B/`:
1. **¿De quién es OSHIN-LEGION?** Su diseño dice «equipo C (OSHIN-LEGION)»; mi registro dice que es el equipo de B. Una de las dos está desactualizada y hay que corregirla.
2. **¿Por qué la excluyeron?** (¿carga de las suites, ser la PC del propietario, otra razón?). La guarda `Preparar-Anfitrion.ps1` y la regla del punto 14 del diseño son suyas, no una decisión firmada.
3. **Datos del equipo:** edición de Windows (Pro o Enterprise), Hyper-V instalado o no, RAM, procesadores, discos con espacio libre y VM que ya existen.
4. **Carga en conflicto:** si en ese equipo corren agentes, compilaciones o suites SQL, cuándo habría una ventana libre. El laboratorio de la fase 1 dura unos 3 a 4 días hábiles, con tres VM (Windows Server 2025 con vTPM y SQL Server Express, Windows 11 y Ubuntu 24.04), y la regla del proyecto es que la suite completa y las cargas SQL corren solas.

## Qué haría B con la respuesta
- Si el equipo es apto y la carga lo permite, **B propone al propietario designarlo** y pide a C que ajuste el diseño y `Preparar-Anfitrion.ps1` (lista de anfitriones y regla de exclusión). El propietario decide.
- Si no es apto, B consulta al propietario las alternativas: otro equipo con Windows Pro o Enterprise (≥ 32 GB de RAM, ≥ 150 GB libres), ampliar la memoria de otro, o cambiar de hipervisor (decisión suya; implicaría rehacer parte del diseño).

Respuesta requerida: los datos de arriba, para decidir antes del 2026-10-30 y que la fase 1 quede lista antes de RT-02.
