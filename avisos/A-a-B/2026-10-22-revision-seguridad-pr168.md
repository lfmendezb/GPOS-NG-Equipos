Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión de seguridad del #168, punta `30ad5c4e`)
Prioridad: Media
Repositorio y rama: GPOS-NG #168 `b/e1-adr93-alcance-sucursal`

# #168: Aprobar con condiciones (sin hallazgos Altos causados por el PR)

Informe: `traspasos/A/revision-seguridad-pr168-e1-adr93-2026-10-22.md` (revisión estática por el auditor-seguridad; verifiqué yo por lectura S168-01 y S168-03 en `AdminEndpoints.cs`). No se ejecutaron pruebas ni mutaciones.

**Correcto:** alcance leído de la cuenta en el servidor, fallo cerrado ante estado ausente, R-01/R-02/R-04 sin evasión por `?almacen=`, sin SQL dinámico, token restringido con 401 de Q-A2, M-168-1 y M-168-2 (con su residuo) construidos como se firmaron en las cinco rutas.

**Medios**
- **S168-01 (lo que declaraste no cubierto es real):** `POST/DELETE /api/admin/pos/usuarios` deja a un ADMIN restringido poner a un cajero de otra sucursal descuento del 100 %, cambio de precios u otra caja (fraude con cómplice); además `GET /usuarios` lista todas las cuentas y `politicas/efectiva` sirve para cualquiera. Remediación: la misma regla de `ExigirCuentaEnAlcanceAsync` y auditar los 403 (~0,15 dp).
- **S168-02 (anterior al PR):** fuera de la gestión de cuentas, `/api/admin` no mira la restricción: adjuntos de la cola de correo por id, servidor SMTP, perfiles (en `GPOS_SYSDATA`, afectan a todas las empresas), cierre y reapertura de otras sucursales, bitácora y parámetros. Alto si el propietario entiende D-3 como frontera de confidencialidad. (a) política `AdminSinRestriccion` en el grupo con lista de excepciones (~0,4 dp), o (b) declarar por escrito que la restricción del ADMIN es orientativa.
- **S168-03 (latente):** `POST /api/admin/almacenes-permitidos` deja a un ADMIN restringido darse almacenes de otras sucursales en el alcance `Operativo`; hoy nada lo usa, pero R-05/R-06 de S-16b sí. Cerrar antes (~0,05 dp).

**Bajos:** S168-04 (carrera en `DesbloquearAsync`/`ForzarNuevoInicioAsync`: como mucho reinicia el contador o cierra una sesión), S168-05 (B-168-3: el alcance compara solo el código de sucursal), S168-06 (oráculos menores: 400 vs 403, mensaje que revela una cuenta SUPER), S168-07 (B-168-5), S168-08 (faltan pruebas de cuenta inhabilitada o nula; invertir el orden de las comprobaciones en `GuardarAsync:525-526` probablemente no se detectaría).

**Condiciones para unir:** (1) registrar S168-01 y S168-02 como riesgo residual de ADR-93; mientras no se cierren, no presentar la restricción del ADMIN como control de confidencialidad (para el USER sí vale); (2) S168-03 como requisito de entrada de S-16b; (3) el propietario decide qué es un ADMIN restringido (administrador de su sucursal u orientativo) y S168-05.

**Tarea 7 (`Usuarios.razor`):** la construyo sobre esta punta; si S168-01 cambia la firma de rutas, la rebaso.

Respuesta requerida: B lleva la decisión al propietario.
