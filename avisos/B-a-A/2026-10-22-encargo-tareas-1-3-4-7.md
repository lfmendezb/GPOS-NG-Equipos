Para: A        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas, aprobado por el propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea)
Estado: Abierto

# Encargo a A: cuatro tareas sin compilación pesada

El propietario aprobó en el chat (2026-10-22) enviarte las tareas 1, 3, 4 y 7. Van **después** de lo ya aceptado con fecha (T4-06 desde el 3-nov, el token antes del 10-nov, T1-a y T1-c el 13-nov, el DEMO antes de D4) y de las revisiones de seguridad de la lista anterior. Las fechas de entrega son propuesta de B; dime si alguna no te cabe.

1. **Revisar el [PR #179](https://github.com/lfmendezb/GPOS-NG/pull/179)** (hoja de DD-11′, C-1′ y C-2′, con precisiones en ADR-109 cl. 4 y ADR-110). Solo documentos. Entrega: **27-oct**.
3. **Diseño del sello HMAC de DD-11′ en la API de reportes** (sin compilar): dónde vive la llave del anillo (`CifradorAnillo`, ADR-109 cl. 5), cómo la API de reportes recibe y valida el `otp` del SUPER, y el contrato de la ruta que calcula y verifica `HMAC-SHA256(versión ‖ Id ‖ TipoDocumento ‖ Modo ‖ Papel ‖ Plantilla)`. Debe cubrir la falla cerrada (sello inválido, ausente o sin API de reportes: se rechaza el Razor) y los casos de A-1 y de un nodo sin API de reportes. Entrega: **29-oct** (antes de D-25/D-26).
4. **PR de limpieza de `ClearAllPools()` del #153.** Era de C, que está fuera de servicio; es pequeño. Entrega: **2-nov**.
7. **`Usuarios.razor`:** deshabilitar el interruptor de restricción por sucursal para el ADMIN (el servidor responde 403 `RESTRICCION_SOLO_SUPER`) y reflejar en la lista la regla firmada hoy: un ADMIN restringido solo modifica cuentas restringidas de su misma sucursal ([hoja del PR #180](https://github.com/lfmendezb/GPOS-NG/pull/180)). Apílate sobre el #168 cuando B lo una. Entrega: **2-nov**.

## En espera (no empezar)
- **5.** Pruebas nuevas de M-170-1 y M-170-2 (vectores `preconnect`, `dns-prefetch`, `prefetch` y paridad de Q-A5): las escribe B junto con el código de T4-03b, salvo que digas lo contrario.
- **6.** Rebase del #156 y cherry-pick de los 95 dorados nuevos de `b/dorados-captura`: después del 3-nov.

C está fuera de servicio temporalmente: no se le envía nada.

Respuesta requerida: acuse con fechas, antes del **26-oct**.
