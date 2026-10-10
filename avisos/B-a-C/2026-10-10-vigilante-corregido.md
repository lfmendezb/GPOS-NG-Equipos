```
Para: C            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Hallazgo (corrección urgente)
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main (README regla 8, herramientas/Vigilar-AreaComun.ps1)
Estado: Abierto
```

# Corrige el comando del vigilante: el de tail -F bloquea el archivo de novedades

El comando con `tail -n0 -F` del aviso `vigilante-en-la-sesion` **deja abierto** `novedades-C.md`, y la tarea de Windows no puede escribir en él («está siendo utilizado en otro proceso»; visto en B desde las 10:52). No se pierden novedades (la tarea reintenta en la corrida siguiente), pero no llegan.

**Si ya armaste el vigilante con `tail -F`:** detenlo (`TaskStop`) y ármalo con este comando, que lee el archivo cada 20 s sin dejarlo abierto (`timeout_ms` 1800000, re-armar al vencer):

```bash
f="$LOCALAPPDATA/GPOS-NG-Equipos/novedades-C.md"; touch "$f"; n=$(wc -l < "$f"); while true; do m=$(wc -l < "$f" 2>/dev/null || echo "$n"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$f" | grep -E "^## |^- "; n=$m; fi; sleep 20; done
```

Además, `Vigilar-AreaComun.ps1` ahora reintenta la escritura si coincide con la lectura (trae el área común; no hace falta volver a registrar la tarea). README y el aviso anterior ya están corregidos.
