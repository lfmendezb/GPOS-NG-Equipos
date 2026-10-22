Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (relectura de seguridad; respuesta a `B-a-A/2026-10-22-condiciones-r3-aprobadas`)
Prioridad: Media
Repositorio y rama: GPOS-NG #176 `b/dat-d1-r3`
Estado: Abierto

# Relectura del #176: aprobar con correcciones menores; R3-03 hay que corregirla

Informe: `traspasos/A/relectura-seguridad-pr176-r3-01-a-r3-03-2026-10-22.md`. Recomendación: **Aprobar el #176 con correcciones menores y corregir R3-03 antes de construir T1-4.**

- **R3-01: cerrada con dos restos.** DAT:138 y DAT:3 aún llaman «propuesta» o punto pendiente a H-13; DAT:193 debe decir que C# aplica la misma regla y valida ASCII antes de `ToUpperInvariant`.
- **R3-02: aceptada con un resto.** El párrafo de D1-03 (DAT:1241) sigue remitiendo a la comprobación de `Program.cs:441-442`, que es lista negra y deja pasar sin licencia vigente. Reescribirlo y exponer un verificador de licencia que `GPOS.Migracion` pueda llamar.
- **R3-03: corregir.** `ConversionId`, `service_broker_guid` y `create_date` como columnas en claro no impiden reemplazar la fila (quien escribe la fila escribe también esos valores). Deben ir dentro del texto autenticado de la protección, junto con el anillo, `Modo` y el SHA-256 del padrón. `RESTORE` conserva el `service_broker_guid` salvo `NEW_BROKER` (inferido; probar en instancia real, igual que `create_date`). Restituir el SHA-256 en `ValorNuevo` del evento de la bitácora. Prueba nueva con copia restaurada (con y sin `NEW_BROKER`).

**Para unir:** el #176 se puede unir si corrigen los restos; si se une ya, R3-03 queda como condición de T1-4. T1-4 sin R3-02 y sin R3-03 corregida: Rechazado.

Respuesta requerida: confirmar si las correcciones van en el #176 o en un seguimiento antes del 2026-11-02.
