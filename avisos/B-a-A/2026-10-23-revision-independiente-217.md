Para: A        De: B        Fecha: 2026-10-23
Tipo: Entrega (revisión de seguridad independiente del #217, de solo lectura) y encargo
Prioridad: Alta (unión antes del 11-nov)
Estado: Abierto

# #217: aprobado con observaciones; recomendación **unir** tras cerrar M-1

Revisión de un auditor de B (distinto del autor) sobre `d618bdf4`: 19 archivos leídos del diff completo, contexto de las dependencias y pruebas ejecutadas. **Sin Críticos ni Altos.** Controles comprobados leyendo el diff: valor y registro de la sesión técnica (32 bytes aleatorios, `sid` `tec-`, búsqueda solo por SHA-256, vigencia exacta de 5 min, tope de 1.000 sesiones con falla cerrada), emisión con falla cerrada y revocación al desechar, reglas de la cuenta, introspección, despacho de `gpos-prg.` solo por la rama de servicio, sin caché del token, ruta cerrada por omisión, eventos 4791 a 4793 sin el valor del token. **El rebase no debilitó nada** (`Evaluar` conserva el orden cuenta → `SucursalAjena` → `sid` → `jti`).
**Pruebas ejecutadas por el revisor:** `GPOS.Reportes.Tests` dirigidas 37/37 y la completa 819/819; `GPOS.Tests` dirigidas 45/45 y 11/11; unión local con `feature/modelo-ng` (`b9efa9fb`) limpia, 51/51. Mutaciones (quitar `EsSuper` del validador; quitar la revocación por `iat`): fallan como deben.

## Hallazgos y a quién le tocan
- **M-1 (Media) — tuyo, antes de unir o en un PR inmediato (~0,5 dp).** La emisión y la introspección no aplican `RevocacionSesiones.SucursalAjena` (`AccesoAutor.cs:56-68` y `ValidadorTokenServicio.cs:29-40`; la sesión interactiva sí, `RevocacionSesiones.cs:171`). Una cuenta restringida sin sucursal, o con otra empresa asignada (TBS-04/S168-05), recibe token y la principal lo acepta; hoy lo frena solo `ProveedorContexto.cs:78` (leído, no probado) con caché de 15 s. Remedio: añadir `SucursalAjena(estado.Cuenta, estado.Cuenta.SucursalDefault, empresa)` en `MotivoDenegacion` y en el validador (`EstadoSesionUsuario` ya trae los datos; `Restringida` excluye al SUPER); motivo sugerido `autor-sin-acceso`; dos pruebas (emisión y `ProveedorContextoTests`: programado restringido sin sucursal da 403).
- **B-1 (Baja) — tuyo.** La rama JWT de la introspección deja pasar cualquier claim (`ValidadorTokenPrincipal.cs:57`): un JWT con `prg` se saltaría la comparación del `sid` (`ProveedorContexto.cs:97`). Rechazar `prg` y `prg_rpt` en la rama JWT y endurecer `EsProgramado` (`amr = prg` y `sid` con prefijo `tec-`).
- **B-2 (Baja) — tuyo.** La prueba con el emisor real (P175-02 (1)) vive en un parche de diagnóstico (`traspasos/A/p175-02-emisor-real-prueba.patch`, rotulado «SCRATCH», sin aserciones `Denegaciones`); en el PR `NotificacionesReportesTests` sigue usando la reproducción de B. Incorpora una versión limpia (con el emisor real, afirmando el motivo y `Registro.Vivas == 0`), en este PR o justo después.
- **M-2 (Media, **preexistente**; propuesta de B, firma del propietario):** el camino P-2 (`TrabajoNotificaciones.cs:109-113`) envía una regla del SUPER o de un autor inhabilitado sin pasar por el emisor, y `Caracterizacion_pendiente_hoy_…` (`NotificacionesReportesTests.cs:931-959`) sigue afirmando `Enviado = true`. Contradice P-1 (a) en los reportes P-2. **Propuesta: no lo corregimos aquí; T4-06 lo invierte (ya está en tu plan, con la lista P-2 vacía y P-2 (a) falla cerrada), y se registra como riesgo aceptado con T4-06 como fecha de cierre, junto a O175-01.** Lo confirmo con el propietario y te aviso.
- **B-3 (Baja, por diseño F-5):** el token es reusable durante sus 5 min dentro de su ruta, por loopback. Aceptado; conviene que ADR-109 cl. 7 diga que «una ejecución» significa «hasta 5 min o hasta desecharlo» (lo anoto yo en `master`).

**Lo que el revisor no verificó:** la suite completa de `GPOS.Tests`, un envío programado real contra servicios, más de un servidor de API, Linux, y una prueba de programado restringido sin sucursal (M-1 sale de leer el código).

## Qué pido
1. M-1, B-1 y B-2 en `a/t4-04-emisor`, y avísame del sha.
2. Confirmo en cuanto el propietario decida M-2; la unión del #217 es orden suya (antes del 11-nov).

Respuesta requerida: acuse con fecha.
