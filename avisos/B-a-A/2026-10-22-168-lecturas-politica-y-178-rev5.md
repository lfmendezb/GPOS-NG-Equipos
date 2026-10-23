Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso (#168 y #178 actualizados)
Prioridad: Media
Repositorio y rama: GPOS-NG #168 (`b/e1-adr93-alcance-sucursal`, punta `11207ad7`) y #178 (`b/datos-t4-10`, punta `af9e4123`)
Estado: Abierto

# #168 con la política AdminSinRestriccion y #178 revisión 5

## #168 (punta `11207ad7`)
- **Construido:** S168-01 (lista de usuarios y configuración POS por usuario bajo el alcance), S168-02 (política `AdminSinRestriccion` en todo `/api/admin`, cerrada por defecto, 403 `RESTRICCION_SUCURSAL_ADMIN`, evento `ACCESO_RECHAZADO_SUCURSAL`), S168-03 (`almacenes-permitidos`), S168-05 (empresa y sucursal; también rechaza el inicio de sesión en una empresa ajena) y S168-08. La política aplica a todos los grupos de `/api/admin`, incluidos los de Importaciones, Impresión, Licencia, Notificaciones, Numeración, Políticas, Precios, Reportes, Restauración y RNC.
- **Lista de excepciones aprobada por el propietario** (hoja del PR #187): permitidas las cuentas de su alcance, `usuarios/licencia`, el catálogo de `perfiles` en lectura y la configuración POS por usuario; el resto denegado y una ruta nueva nace denegada. **Efecto aceptado:** un USER restringido con conciliación, motivos de anulación, cierre de sucursal o listas de precios también recibe 403.
- Evidencia: 75 pruebas nuevas corridas por mí, 75/75; el agente reporta 182/182 en las clases dirigidas y 14 mutaciones detectadas. La suite completa no se corrió. Sin construir: S168-04, S168-06 y S168-07.
- **Tarea 7 (`Usuarios.razor`):** la Web y MAUI deben ocultar las opciones denegadas y manejar `RESTRICCION_SUCURSAL_ADMIN`; el evento nuevo no tiene etiqueta en español. Rebasa tu rama sobre esta punta.

## #178 (punta `af9e4123`, revisión 5, solo documentos)
- Incorpora tus condiciones: S178-R4-01 (DTO propio sin montos, lista exacta de campos), R4-03 a R4-07 y 5152 = `SelloRazorRechazado`. Anotado: `GPOS.Reportes.Api` no lee `auth_time`; mientras tanto la ruta de sellado falla cerrada (costo tuyo).
- **S178-R4-02 decidido por el propietario:** `GET /api/efectivo/movimientos-caja` queda para `CuadreCaja` y `ReportesEfectivo`; se quita `AperturaCaja`.
- T4-10: 11,3 dp.

Respuesta requerida: tu revisión del #168 (lista de excepciones y evento nuevo) y de las secciones cambiadas del #178.
