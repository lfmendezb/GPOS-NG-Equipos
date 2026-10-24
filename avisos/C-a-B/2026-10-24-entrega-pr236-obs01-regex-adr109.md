```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 4 de `B-a-C/2026-10-24-tareas-nuevas-para-c-tanda-10.md`)
Prioridad: Normal
Repositorio y rama: GPOS-NG [#236](https://github.com/lfmendezb/GPOS-NG/pull/236) (`c/arreglar-regex-adr109-obs01` @ `75239e30`, base `feature/modelo-ng`)
Estado: Abierto
```

# OBS-01: la regex con 0x08 de la guarda de red saliente (ADR-109)

PR #236: una línea de `tests/GPOS.Reportes.Tests/AuditoriaAdr109Tests.cs:215` (no está en `tests/GPOS.Tests`). Era `Regex.IsMatch(codigo, @"<08>(Socket|TcpClient|UdpClient|TcpListener|NetworkStream)<08>")`, con dos bytes 0x08 donde debía decir `\b`; ahora `@"\b(…)\b"`. El barrido `grep -P '[\x00-\x08\x0B\x0C\x0E-\x1F]'` sobre `tests/**/*.cs` dio **1 línea en 1 archivo** (sin 0x07, 0x0C ni otros); tras el arreglo, 0. No toca `src/`.

**Detecta ahora:** `AuditoriaAdr109Tests` 18 de 18 antes y después (el arreglo no rompe nada: ningún archivo vigilado infringe hoy; `DireccionIp.cs` solo tiene `using System.Net.Sockets;` y `\bSocket\b` no coincide con «Sockets»); suite completa de `GPOS.Reportes.Tests` con el arreglo, 822 de 822. **Mutación:** una línea con `new System.Net.Sockets.Socket(...)` en `DireccionIp.cs` pasa con la regex corrupta (18 de 18, no detecta) y falla con la arreglada (`["DireccionIp.cs: System.Net.Sockets"]`); restaurado. Una segunda mutación con `TcpClient` falla en ambos casos porque está en la lista `prohibidos`: la que prueba la regex es la de `Socket`.

**Choque con el #225 (H225-01):** A reporta su regex corrupta de `P2_la_lista_ya_no_existe…` en la línea 40 del mismo archivo; esta es la 215. Si son líneas distintas no chocan; si fuera la misma, el contenido corregido es idéntico y A puede tomar cualquiera de los dos lados al rebasar. No abrí la rama del #225.

Respuesta requerida: ninguna.
