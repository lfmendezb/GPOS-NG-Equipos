---
name: sucursal-en-linea-sqlite-y-licencia
description: "2026-10-06 precisión ADR-53: sucursales con nodo o en línea (elegible, ambos sentidos); la en línea tendrá SQLite local de contingencia DESPUÉS de las olas; licencia por empresa contando usuarios; SUPER es siempre agente de la plataforma"
metadata:
  node_type: memory
  type: project
  originSessionId: f2c0a692-b405-4953-8a6f-70fec2b01360
  modified: 2026-10-06T19:20:29.135Z
---

Respuestas del propietario a la precisión de ADR-53 (`GPOS NG/docs/decisiones/2026-10-06-precision-adr53-nodo-por-sucursal.md`, commit local `8a2a85d` en master):
- Cada sucursal elige entre nodo propio o «en línea» contra la central, con cambio en los dos sentidos; solo el SUPER lo cambia.
- **La sucursal en línea tendrá una base local SQLite** para seguir operando el día sin conexión hasta recuperar la principal o el 4G/5G. **Se diseña y construye después de completar las olas**, para no mover el cronograma. Exige precisión de ADR-54 (segundo motor), bloques de NCF propios (los no usados mantienen su vigencia hasta agotarse; no van al 608), cifrado y sincronización como la del nodo.
- **Licencia por empresa:** sucursales en línea y nodos comparten una licencia; el límite es de usuarios habilitados en toda la empresa (cambia P-L5 de ADR-58, que contaba nodos).
- **El SUPER nunca pertenece a la empresa del cliente:** siempre es un agente de la plataforma.
- VPN obligatoria para la sucursal en línea fuera de la red; esperar transferencias en tránsito antes de cambiar el modo.

**Why:** el propietario quiere que ninguna sucursal deje de vender por la conexión, sin frenar las olas.

**How to apply:** no proponer SQLite antes del fin de las olas; al llegar, preparar ADR (precisión de ADR-54 y ADR-53) y la precisión de ADR-58. Relacionado: [[licencia-por-vigencia]], [[motor-sql-server-decidido]], [[litedb-configuracion-embebida]].
