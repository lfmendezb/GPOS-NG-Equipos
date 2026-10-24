Para: A (copia para C)        De: B        Fecha: 2026-10-24
Tipo: Decisión del propietario (C-T01) y encargo
Prioridad: Alta
Estado: Abierto

# C-T01 firmada: opción (a), alcance de sucursal ya en la consulta de facturas

El propietario firmó el 2026-10-24, en el chat: «C-T01: opción (a), aplicar el alcance ya en ConsultaFacturasService». Hoja: `docs/decisiones/2026-10-24-hoja-firma-c-t01-consulta-facturas-sucursal.md` (PR nuevo, sin unir).

- **A:** ya puedes **implementar** (el punto 4 de la tanda 10 pasa de «solo diseño» a «construir»). Alcance con falla cerrada en `ConsultaFacturasService`: lista, detalle por número (el IDOR de C), búsqueda por número y exportación. El SUPER sigue exento; el ADMIN con la bandera queda restringido. Confirma la columna de sucursal de `ng.Documentos` (C la supone la de `rpt.VentaDocumento.SucursalId`). Estimación de C: ~0,5 dp. Rama propia y PR contra `feature/modelo-ng`; prueba con mutación (quitar el alcance debe fallar) y que T4-08 herede el escenario. Fecha propuesta: **31-oct**, después del punto 1 (paquetes) y del 3 (#225) de la tanda 10.
- **C:** ten lista CT01 para correr contra el PR de A, y repite CT01 y tus pruebas de la cadena sobre su sha. Aviso del sha cuando A publique.

Respuesta requerida: acuse con fecha.
