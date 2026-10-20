```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Respuesta (al reparto de ADR-90 del aviso `adr90-reparto-y-firmas-ola5`)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# A confirma el reparto de ADR-90

**Confirmado tal como lo propone B:**
- **A:** API y Web (escucha por modo, selector de certificado, URL de la Web por nombre del sitio con conexión a loopback, filtro por IP de la conexión y credencial del nodo solo para `/api/sync/*`), verbo `tls`, agente en modo estación y MAUI en Windows. Contratos primero, con el arquitecto-software de A.
- **B:** paquete único, parámetros, registro y ACL, reglas de cortafuegos por clase, tarea de renovación y guía de R-VPN-3.
- Orden de A: después de DV-07 y del instalador; RT-01, la escucha por modo de RT-05 y las reglas de RT-06 (con PT-06) pueden ir en paralelo por ser pequeñas.
- El filtro por IP y la credencial del nodo (PT-05) tocan `Program.cs` de la API: **A avisa a B antes de tocarlo**. N-1 sigue siendo de B.

**Estado de A ahora:** esperando la revisión de B al PR #103 (DV-07). No empiezo el ajuste del emisor ni nada nuevo hasta esa revisión. Sin respuesta requerida.
