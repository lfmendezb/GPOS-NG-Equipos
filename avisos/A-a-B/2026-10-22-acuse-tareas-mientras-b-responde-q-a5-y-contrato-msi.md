Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse y respuestas (a `B-a-A/2026-10-22-tareas-mientras-b-responde`, `respuesta-q-a1-a-q-a5-s16`, `q1-instalador-lo-construye-b` y `uniones-152-154-155-157-158`)
Prioridad: Alta (Q-A5 desbloquea P-0 de E-1)
Repositorio y rama: GPOS-NG ADR-93 (E-1, TA-P08); área común `traspasos/A/`
Estado: Abierto

# Acuse de A

Enterados de las uniones (#152, #154, #155, #157, #158) y de la decisión de Q-1: **el MSI de la API lo construye B**.

| Encargo | Estado de A |
|---|---|
| 1. Subir la deuda al #140 | **Hecho**: punta `fe8dbc9c2dd9457e277f81b18d3ef7584c10078f` (`A-a-B/2026-10-22-deuda-subida-al-pr140-punta-fe8dbc9c.md`). Relectura de seguridad de P140-03, `338d899f` y `89f03411`: **aprobada** (`2026-10-22-relectura-seguridad-p140-03-aprobada.md`). La suite oficial completa sobre esa punta es de B; A corrió solo las dirigidas (886 correctas, 0 con error) |
| 2. Documento de contrato del servicio del MSI | **Hecho**: `traspasos/A/contrato-servicio-msi-api-2026-10-22.md` (Q-1) |
| 3. Blueprint del token de servicio | **Entregado** el 22-oct: `traspasos/A/propuesta-frontera-token-servicio-t4-04-2026-10-22.md`. Espero F-1 a F-5 de B (antes del 28-oct); el token, antes del 10-nov |
| 4. T1-a y T1-c del instalador | **Aceptadas**, 13-nov. T1-a abre en los huecos de PR-4 (27-oct a 2-nov); A avisa cuando esté abierto para apilar T1-b. Sin cambio: G-PR4 |
| 5. PR-D1 y spike del modo Amplio | En los huecos antes del 3-nov |
| Revisiones adelantadas | Acepto las vistas `imp` (T4-10), DAT-D1 rev. 3, el ADR-161 y T4-04 cuando B los publique: 3 días hábiles cada una |

## Q-A5: confirmo, y dónde está el cambio
**Confirmado.** El SUPER es global (ADR-35 y ADR-36): la bandera `RestringirSucursal` no lo restringe nunca. Leí `origin/feature/modelo-ng`:

- **API de reportes:** el cambio es de ella y cabe en dos líneas de `ProveedorContexto` (`src/GPOS.Reportes/Contexto/ProveedorContexto.cs`): `ObtenerAsync` (`:74`) pasa `u.RestringirSucursal` a `ContextoReportes`, y `Sucursal(...)` (`:92`) aplica `u.RestringirSucursal` para imponer la sucursal de `rptsis`. Ambas deben usar `restringe = u.RestringirSucursal && u.Nivel != NivelesUsuario.Super`. Con eso `PuedeDisenar`, `ResolverAsync`, `EjecutorDisenador` y `ServicioReportes` (que leen `ctx.RestringirSucursal`) quedan correctos sin tocarlos.
- **Principal:** no existe hoy una excepción del SUPER en `GPOS.Core` ni en `GPOS.Api` (no encontré referencias que cruzaran `RestringirSucursal` con el SUPER). Para P-0 de E-1 hay que aplicar la misma regla en el punto único donde la principal resuelve la sucursal restringida.
- **Dónde va:** **dentro de E-1 (P-0)**, no de T4-06, para que la principal y la API de reportes lean una sola función (`UsuarioAlcance.Restringe(nivel, bandera)` en `GPOS.Core`, que `ProveedorContexto` usa). Coste ya incluido en tu +0,35 dp; la prueba mínima es USER y ADMIN restringidos (se restringen), SUPER con la bandera (no se restringe) y SUPER sin ella.

## Q-A1 a Q-A5 como precisión de TA-P08 (texto para tu hoja)
> **Precisión de TA-P08 (ADR-93), 2026-10-22, aprobada «según recomendaciones».** (1) R-05 y R-06 usan alcance `Operativo` (sucursales propias más permitidas); R-07 y las demás rutas de lectura, `Consulta` (propias). (2) `RevocacionSesiones.Evaluar` responde 401 `credenciales` si el usuario está restringido y la sucursal del token difiere de su `SucursalDefault`. (3) Un ADMIN con `RestringirSucursal` no puede detectar columnas, ver la vista previa, guardar ni eliminar definiciones de reportes (paridad con `PuedeDisenar`); va en E-1. (4) R-14 (`diseno/detectar`) pasa a T4-06, con 403 propagado por `IDetectorColumnas` en Release (no 503) y fila nueva en el contrato de Guardar. (5) El SUPER no se restringe nunca por `RestringirSucursal`; una sola regla para P-0 y para la API de reportes. Decisiones 1 a 3 de la adenda de A (`2026-10-22-adenda-s16-v-riesgo-1-y-f25.md`) incluidas.

Respuesta requerida: ninguna (B anota la precisión con su hoja de firma).
