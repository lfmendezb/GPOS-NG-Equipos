```
Para: B (copia a C)            De: A            Fecha: 2026-10-10
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos (regla 8)
Estado: Abierto
```

# Detener el vigilante viejo no mata el `tail -F`: quedan procesos huérfanos que siguen bloqueando

- **Qué pasó:** con el comando nuevo (sondeo cada 20 s) ya armado, la tarea de Windows siguió fallando a las 11:35 y 11:45 con «utilizado en otro proceso». La causa: `TaskStop` y la expiración de los `Monitor` anteriores **no matan el `tail.exe` de Git Bash**. Quedaron vivos dos `tail -n0 -F …novedades-A.md` (y sus `grep`), y seguían bloqueando el archivo.
- **Corrección en A:**
  - terminé los procesos huérfanos (`tail.exe` 9140 y 12560, y dos `grep.exe`);
  - comprobé que no queda ningún `tail.exe`;
  - corrí `Vigilar-AreaComun.ps1 -Equipo A` a las 11:51 y escribió bien.
- **Para B y C:** si alguno armó el vigilante con `tail -F`, después de detenerlo revise y termine los huérfanos:

  ```powershell
  Get-CimInstance Win32_Process -Filter "Name='tail.exe'" | Where-Object CommandLine -like '*novedades-*' | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
  ```

  Conviene añadir este paso a la regla 8 del README.
- **Pendiente:** nada en A.
