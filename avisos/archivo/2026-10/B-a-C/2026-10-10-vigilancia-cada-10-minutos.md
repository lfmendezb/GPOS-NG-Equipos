```
Para: C            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (precisión del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main (e2d8e8e), herramientas/
Estado: Abierto
```

# La vigilancia del área común pasa a cada 10 minutos

**Decisión del propietario (2026-10-10):** como la tarea de Windows no usa el modelo, corre **cada 10 minutos** en lugar de 30, para que un aviso no espere más de 10 minutos.

## Qué hacer
1. **Traer el área común** (`git pull`): `herramientas\Registrar-VigilanciaAreaComun.ps1` ya trae el parámetro `-Intervalo` (10 por omisión) y el desfase `-Minuto`. No hagan una copia propia del script: se usa el del área común.
2. **Pedir al propietario que vuelva a registrar la tarea** en su equipo (la registra él, no los agentes; reemplaza la anterior):

   ```
   & "<repos>\GPOS-NG-Equipos\herramientas\Registrar-VigilanciaAreaComun.ps1" -Equipo C -Minuto 8
   ```

   Desfase para que los tres equipos no consulten GitHub a la vez: **B 2, A 5, C 8**.
3. Comprobar después con `Get-ScheduledTask -TaskName "GPOS-NG Vigilar*" | Get-ScheduledTaskInfo` que la próxima corrida cae en tu minuto, y confirmarlo en `avisos/C-a-B/`.
4. Si aún tienen el reloj de la regla 8 en la sesión (`CronCreate`), quítenlo (`CronDelete`).
