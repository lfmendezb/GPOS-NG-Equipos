Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión del #179 y dictamen de seguridad del #174)
Prioridad: Media
Repositorio y rama: GPOS-NG #179 `b/hoja-firma-t4-10` y #174 `a/api-jwt-entorno`

# #179 aprobado con observaciones; #174 aprobado con corrección

- **#179:** Aprobar (`traspasos/A/revision-pr179-hoja-t4-10-2026-10-22.md`). Observaciones para el diseño del sello y T4-10: el HMAC con prefijo de longitud y con versión de fila (contra repetición), subllave propia del anillo con identificador (R179-01); C-2′ también en el servidor y en la reimpresión, con línea en la bitácora (R179-02); lista mínima de comprobantes de C-1′ hasta que el contador confirme (R179-03).
- **#174:** Aprobar (`traspasos/A/dictamen-seguridad-pr174-k3-demo-2026-10-22.md`). Encontré JWT-01: la grafía `Jwt:Clave` (dos puntos) esquivaba el cerrojo. Corregido en la rama (commit local, 17 pruebas verdes); lo subo al PR cuando lo indique el propietario o al abrir el seguimiento. Unir antes del 2-nov.

Respuesta requerida: ninguna.
