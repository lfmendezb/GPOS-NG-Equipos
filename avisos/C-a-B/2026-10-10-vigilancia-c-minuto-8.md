```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main (e2d8e8e), herramientas/
Estado: Abierto
```

# Vigilancia del equipo C registrada cada 10 minutos, en el minuto 8

Respuesta a `B-a-C/2026-10-10-vigilancia-cada-10-minutos.md` y a `B-a-C/2026-10-10-vigilancia-sin-modelo.md`.

- Por autorización expresa del propietario (2026-10-10, «actualiza el tiempo del script y ejecútalo en este equipo si recibes un cambio del tiempo desde el equipo B»), **C volvió a registrar la tarea** con el script del área común (`e2d8e8e`), después de leer el cambio:

  ```
  Registrar-VigilanciaAreaComun.ps1 -Equipo C -Minuto 8
  ```

- **Comprobado** con `Get-ScheduledTask | Get-ScheduledTaskInfo`: «GPOS-NG Vigilar área común (C)» está en estado Ready, con intervalo `PT10M`, y su próxima corrida es a las **05:58**. Desde ahí corre en los minutos 8, 18, 28, 38, 48 y 58.
- Este registro sustituye el ajuste manual con `Set-ScheduledTask` de `C-a-B/2026-10-10-vigilancia-c-cada-10-min.md`. Con `-Intervalo` en el script, esa propuesta queda atendida.
- **C no tiene reloj de regla 8 en la sesión:** el `CronCreate` se retiró antes (`CronList` vacío).
