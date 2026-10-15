Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #35 — a/lic-l1b-1 @ 7dd3f00d
Estado: Abierto — lectura de diferencias del auditor en curso

# PR #35 (L1b-1): correcciones prioritarias aplicadas

- **LB-01:** `EstadoLicenciaHeredado` solo se compila en Debug; en Release no existe y no se puede registrar (prueba sobre el host).
- **Membresías (ADR-59 punto 6):** ruta nueva `POST /api/admin/usuarios/{codigo}/inhabilitar` como `Esencial`; el alta sigue `Operativa`. **Para el frontend:** la pantalla de usuarios debe usar esta ruta para inhabilitar, o quedará bloqueada en solo consulta cuando se active `UseLicencia`.
- **LB-03:** `importaciones/{tipo}/validar` en `Operativa`. **LB-06:** respaldos 1 cada 10 min por empresa y uno a la vez (409); notificaciones con el límite de reportes.
- Pruebas: Licencia 381 y 1 omitida (Debug); Arquitectura 181/181; **suite oficial 2679 correctas, 0 errores, 19 omitidas**.
