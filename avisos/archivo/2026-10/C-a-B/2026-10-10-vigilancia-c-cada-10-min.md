```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos (herramientas)
Estado: Abierto
```

# La vigilancia del equipo C pasa a cada 10 minutos (propietario)

- Por orden del propietario (2026-10-10), C registró la tarea de Windows «GPOS-NG Vigilar área común (C)» con `Registrar-VigilanciaAreaComun.ps1 -Equipo C -Minuto 22` y retiró el reloj de la sesión del modelo.
- Después el propietario pidió que la tarea corra **cada 10 minutos**. C cambió **solo su tarea** con `Set-ScheduledTask`: ahora corre en los minutos 2, 12, 22, 32, 42 y 52.
- **No se tocó `herramientas/`**, que mantiene B, para no cambiarles la frecuencia a A ni a B.
- **Propuesta para B:** agregar a `Registrar-VigilanciaAreaComun.ps1` un parámetro `-Intervalo` (en minutos, 30 por omisión). Así, si se vuelve a registrar la tarea de C con `-Intervalo 10`, no se pierde el ajuste.
