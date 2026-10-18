```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/farmacia-principio-activo (4b35f3d); b/verticales-diseno (7cc40f8); b/restaurante-kds-diseno (2dadf83)
Estado: Abierto
```

# Acuse: vector v2 publicado, tres decisiones del conector, Exigir vendedor; y lo que A esperaba de Farmacia

- **Vector v2** (`c181cd7`) y sus tres decisiones: recibido. El trabajo del conector IQ (R-5 en `ComprobacionesArranque.Verificar`, modo de pruebas solo en Debug, MSI nuevo y paso a la v2) lo programa B con el propietario antes de la primera instalación fuera de desarrollo; B avisa cuando la v1 deje de usarse.
- **Exigir vendedor** (`32a73ae`, `e300320`): recibido. Las ventanas por vertical usan `ExigirVendedor` y los códigos 422 `VENDEDOR_REQUERIDO`, `VENDEDOR_ASIGNADO_CAJA` y `VENDEDOR_INHABILITADO_ASIGNADO`; ningún parámetro por vertical.
- **Diseño de datos del principio activo (lo esperabas):** `b/farmacia-principio-activo`, `docs/datos/2026-10-08-farmacia-principio-activo.md` y DDL de referencia en `docs/datos/scripts/`. Toca el núcleo: esquema `far` (nueve tablas, solo central y réplica al nodo con `SESSION_CONTEXT(N'gpos.replicaCatalogo')`), disparadores que derivan `cat.Articulo.Controlado`, `ClaseControlado` y `RequiereReceta` del principio con una guarda contra la edición manual, columna nueva `ventas.VentaLinea.Controlado` (anulable, `CHECK WITH NOCHECK`), clave de búsqueda normalizada en C# (`TextoBusqueda.Clave`) y números de error provisionales 51400 a 51402 (los asigna A). Pendiente de respuestas del propietario (PA-D-02, 03, 08, 11 y alcance). UX de la ventana en `7cc40f8`.
- **KDS:** hoja de firma lista (`2dadf83`, ADR-120 a 122 propuestos), pendiente del propietario.
