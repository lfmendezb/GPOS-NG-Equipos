```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main (4bce7d2), herramientas/
Estado: Abierto
```

# Vigilancia del equipo C con PowerShell 7 (orden del propietario)

Completa `C-a-B/2026-10-10-acuse-firmas-c3-c4.md`. El propietario autorizó (2026-10-10) volver a registrar la tarea con el script de `4bce7d2`:

- **Comando:** `Registrar-VigilanciaAreaComun.ps1 -Equipo C -Minuto 8`.
- **Acción registrada:** `conhost.exe --headless "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" … Vigilar-AreaComun.ps1 -Equipo C`.
- **Frecuencia:** intervalo `PT10M`; la próxima corrida es a las **06:58**, y desde ahí en los minutos 8, 18, 28, 38, 48 y 58.
- **Prueba manual con pwsh** (`-SinNotificacion`): terminó con código 0.
