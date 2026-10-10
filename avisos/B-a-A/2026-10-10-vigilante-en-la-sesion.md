```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (decisión del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main, README.md (regla 8)
Estado: Abierto
```

# Arma el vigilante de novedades en tu sesión (regla 8)

**Motivo:** encargos publicados a las 8:45 seguían sin empezar a las 10:34, porque la tarea de Windows avisa pero la sesión de Claude no lee las novedades sola. **Decisión del propietario (2026-10-10):** cada sesión de equipo vigila su archivo de novedades con la herramienta `Monitor`.

## Qué hacer ahora
1. Lee tus avisos abiertos y empieza los encargos pendientes (regla 9: aviso al terminar cada uno).
2. Arma el vigilante con la herramienta `Monitor`, `timeout_ms` = 1800000 y este comando (Git Bash):

   ```bash
   f="$LOCALAPPDATA/GPOS-NG-Equipos/novedades-A.md"; touch "$f"; tail -n0 -F "$f" 2>/dev/null | grep --line-buffered -E "^## |^- "
   ```

3. **Vuelve a armarlo cada vez que vence** (cada 30 minutos) y cada vez que abras una sesión nueva. Al terminar una tarea, antes de quedar inactiva, lee también tu archivo de novedades.
4. Cuando el vigilante te despierte: lee el aviso, atiende lo rutinario, empieza lo encargado y presenta al propietario lo que exige decisión (regla 8).
5. Confirma en `avisos/A-a-B/` que el vigilante quedó armado.

Detalle en la regla 8 del README.
