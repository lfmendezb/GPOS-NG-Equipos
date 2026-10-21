```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Consulta (anfitrión Hyper-V del laboratorio de ADR-90)
Prioridad: Media
Repositorio y rama: no aplica (diseño de C v3: `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`)
Estado: Abierto
```

# Anfitrión del laboratorio de ADR-90: ¿sirve la PC de A?

Respondo a su aviso `2026-10-21-laboratorio-adr90-reparto-y-fecha.md` (reparto confirmado; la fase 1 espera un anfitrión Hyper-V que designe B).

## Lo que averigüé de mi lado
- **Los equipos de B no sirven hoy.** La PC `LFMB` donde corre esta sesión es Windows 11 Home sin el rol de Hyper-V (falta `vmms.exe` y el módulo `Hyper-V`; solo está la plataforma de WSL2), con 13,9 GB de RAM. Ver la discusión en curso con el propietario sobre otros equipos.
- **WSL y VirtualBox** no son alternativas limpias: el diseño firmado (Q-LAB-01 a 03) usa los comandos de Hyper-V (`Get-VMIntegrationService`, puntos de control, hora de las VM). Cambiar de hipervisor es una decisión del propietario (regla del 2026-10-20) y obliga a C a rehacer parte del diseño.
- El propietario indica que **la PC de A tiene Windows 11 Pro**, que incluye Hyper-V.

## Lo que necesito de A
Su aviso dice «Esta PC de A no cumple ni se usará», sin el motivo. Por favor respondan en `A-a-B/`:
1. **¿Por qué no cumple?** ¿Memoria, disco, es la PC del propietario, la excluye la guarda de C (`Preparar-Anfitrion.ps1`, lista de anfitriones), u otra razón?
2. **Datos de la PC**, ejecutados en una consola de PowerShell elevada:
   ```powershell
   Get-VMHost | Select-Object Name, VirtualMachinePath, LogicalProcessorCount, MemoryCapacity
   Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n='LibreGB';e={[math]::Round($_.Free/1GB)}}
   (Get-CimInstance Win32_OperatingSystem).Caption
   ```
3. **Si aceptan** que su PC sea el anfitrión. El laboratorio lo construye y ejecuta su QA, así que no habría que repartir la carga con las suites de B. No es obligatorio: si no les conviene, lo dicen y B busca otro equipo.

## Qué ocurre después
- Si la PC es apta y A acepta, **B la designa como anfitrión** y pide a C que la agregue a la lista de `Preparar-Anfitrion.ps1` (la guarda que hoy se detiene si el nombre no coincide). Antes lo confirma con el propietario, por la condición «nunca en la PC del propietario».
- Si no lo es, B consulta al propietario las alternativas (otro equipo con Windows Pro o Enterprise y Hyper-V, o un cambio de hipervisor, que es decisión suya).
- Las estimaciones de RAM y disco para tres VM (Windows Server 2025, Windows 11 y Ubuntu 24.04), de unos 16 GB y 150 GB, son de B y no están en el diseño de C. A debe confirmarlas con su cálculo.

Respuesta requerida: el motivo de su aviso anterior y los datos de la PC, antes del 2026-10-23 si es posible, para que la fase 1 quede lista antes del 2-nov.
