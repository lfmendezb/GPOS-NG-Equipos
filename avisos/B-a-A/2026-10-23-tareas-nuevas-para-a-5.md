Para: A        De: B        Fecha: 2026-10-23
Tipo: Encargo (tareas nuevas; el propietario aprobó la asignación)
Prioridad: Media
Estado: Abierto

# Tareas para A (además de lo que ya tienes en cola)

Ya en tu cola (no cambia): el PR del emisor (`a/t4-04-emisor`, antes del 11-nov), el PR de R-04 (`.aplicando`) solo con el código de arranque, la línea de la guía del DEMO sobre el tablero, T4-06 desde el 3-nov (con las respuestas firmadas hoy) y el resto de PR-D2 cuando exista el anillo (mío, antes del 16-nov).

1. **Menú de `NavMenu.razor` (ambas copias) con `Info.RestringirSucursal`** (~0,15 dp). Desbloqueado: el **#212 está unido** a `feature/modelo-ng`. La autoridad sigue en el servidor; el campo solo oculta lo que no es de la sucursal para el ADMIN restringido.
2. **Revisión de seguridad del #210** (T4-02a: `ClienteRender` y `ContratoRender` en `GPOS.Contracts`): el camino del token, el dueño de la canalización verificado antes del primer byte (5122), los topes de 16 MB, 32 MB y 64 KB, el plazo de 35 s, la tabla 5.3 de 14 filas y las desviaciones D-1 a D-4 declaradas en el PR. C hace una revisión adversarial aparte (27-oct).
3. **Revisión de seguridad de dos piezas mías cuando terminen** (te aviso con sha): el blueprint del verbo `tls` y del anillo del servicio (DM-07), y el `GPOS.Api.msi` mínimo (T1-b, con la guarda G-PR4 y la prueba T1-09). Las construye un agente mío; no se unen sin tu revisión y la orden del propietario.
4. **Pregunta abierta: ¿quién construye el sello HMAC de DD-11′ y cuándo?** Lo diseñaste (2,2 dp ±30 %, `diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`). Antes de construir, falta `Huella binary(33)` (ya está en las vistas `imp` del #193/#194), leer `auth_time` de `ResultadoIntrospeccion.Claims` en la ruta de sellado (R20) y el evento `FORMATO_RAZOR_SELLADO` en el catálogo de T1-1. Dime si lo quieres tú o lo toma B, y la fecha; va antes de T4-11 (enero), no antes del corte de la entrega 1. No empieces sin mi respuesta.
5. **SPV-03 (b), más adelante:** el manifiesto firmado con llave anclada, con el *bundle* y la actualización automática, no antes de D4.

Respuesta requerida: acuse con fecha, y tu respuesta al punto 4.
