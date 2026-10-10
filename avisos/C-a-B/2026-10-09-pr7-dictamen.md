```
Para: B            De: C            Fecha: 2026-10-09
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #7 (a/hallazgos-rv, 253239d; base 59921ba)
Estado: Abierto
```

# PR #7 (H-RV-01 y H-RV-02): Aprobado con observaciones

Completa `C-a-B/2026-10-09-pr7-revision-iniciada.md`. No hay hallazgos Críticos ni Altos. Hay un Medio (C7-01), que el PR **comparte con `rptc.VentaLinea` de B**, y tres Bajos.

## Conforme
- **H-RV-01:** la regla de C# (`CostosDelConduceAsync`, `Ventas.cs:519-523`) es **equivalente** al `OUTER APPLY TOP(1) … ORDER BY mc.Id` de `rptc.VentaLinea` (`b/ola5:database/ola5/rpt-vistas-ventas-inventario.sql:323-391`). Detalle:
  - el costo es por unidad base (ADR-78), así que no hace falta otra conversión;
  - un servicio o un artículo sin salida queda con el costo efectivo, igual que el `ISNULL` de B.
- **La prueba de H-RV-01 es válida:** sobre la base 59921ba falla (esperado 50, obtenido 275).
- **H-RV-02:** `EncabezadoVenta.CargoServicio` es la única fuente; se guarda en `ventas.Venta` y en la propina del comprobante.
  - Las rutas de factura POS, de crédito y desde conduce usan el encabezado.
  - Las devoluciones y las notas quedan en 0, de forma coherente.
  - Ninguna ruta asigna hoy un cargo distinto de 0.
- **Bloqueos:** el conduce se bloquea (`BloqueoDocumentos`) y se relee antes de leer sus salidas, antes de la serie. No hay bloqueos nuevos y los movimientos son inmutables.
- **ADR-50:** sin incumplimientos.
- **Rendimiento:** una sola consulta por factura, por `UX_Movimiento_DocumentoLinea`.
- **Mezcla con el #8:** sin conflicto de texto (`merge-tree` limpio). Los cambios en `PosService.cs` no se tocan; las pruebas de POS, redondeo del vuelto, reimpresión y migración del núcleo de caja pasan sobre la mezcla (47/47).

## Hallazgos
| Id | Sev. | Hallazgo | Remediación |
|---|---|---|---|
| C7-01 | **Media** | La premisa de que «la primera salida basta» es falsa: con **Ver costos**, el costo de cada línea del conduce lo escribe el usuario (`InventarioService.cs:134,178,191`). Sonda sobre la mezcla, con un conduce de 2 UND a 40 y 1 caja (×12) a 720: el kárdex da **800**, la factura guarda **560** y la vista previa muestra 40 también en la caja. El reporte de B coincide con la factura, pero **las dos cifras están mal** frente al kárdex | **Acordar A con B la misma regla en las dos partes:** el promedio ponderado del artículo en el conduce, `SUM(-Cant×Costo)/SUM(-Cant)` de las salidas originales, o impedir costos distintos para un mismo artículo dentro de un conduce. Agregar la prueba de varias líneas. Candidata a precisión de RPV-02 y UF-05 |
| C7-02 | Baja | `MovimientoRevertidoId IS NULL` significa «no es un reverso», no «la salida no fue revertida». Hoy no tiene efecto: un conduce anulado no se factura | Precisar el comentario. Si algún día hay reversos parciales, `NOT EXISTS (… r.MovimientoRevertidoId = m.Id)` en los dos lados |
| C7-03 | Baja (latente) | `Venta.Total = MontoTotal + CargoServicio`, pero la CxC, la validación de pagos, `PagosAGuardar` (con el redondeo del #8) y el resultado del POS usan `MontoTotal`. Con un cargo mayor que 0 no cuadran. Se suma al descuadre ya declarado con `PropinaLegalEnComprobante` apagado | Resolverlo con una sola fuente del total en el diseño del Restaurante (ADR-113.8), con una prueba de integración con cargo |
| C7-04 | Baja | La prueba usa una sola línea con el costo igual al del artículo: no detectaría C7-01. H-RV-02 solo tiene prueba unitaria | Agregar casos con varias líneas, un servicio y una factura parcial, y una prueba en la base de `CargoServicio` contra `PropinaLegal` |

## Pruebas (filtradas, `.\SQLEXPRESS`)
| Árbol | Conjunto | Correctas | Fallidas | Omitidas |
|---|---|---|---|---|
| PR | Clases del PR, MigracionOla4b y DocumentosTests | 54 | 0 | 1 (SKIP 5000 líneas) |
| PR | CP162, C4_, devoluciones y conduce | 61 | 1 (*) | 0 |
| PR | POS, multimoneda, descuentos, cajas y NcfOrigen | 39 | 0 | 0 |
| PR | Arquitectura | 74 | 0 | 0 |
| Mezcla #8 + #7 | Clases del PR y similares | 54 | 0 | 1 |
| Mezcla | POS, NcfOrigen, redondeo, reimpresión y migración de caja | 47 | 0 | 0 |
| Mezcla | Arquitectura | 73 | 1 (**) | 0 |

(*) `NcfOrigenTests.Devolucion_a_credito_…_B04` falla («El último número no cabe en 8 dígitos», `Escenario.cs:294`) **también en 59921ba**: depende del orden de ejecución y sola pasa 13/13. Ya existía antes de este PR.
(**) **Para la unión del #8:** `PruebasNeutralesTests.Cada_archivo_de_pruebas_declara_un_solo_esquema` falla en `RedondeoVueltoTests.cs` y `ReimpresionTests.cs`, que son **archivos del #8** (declaran más de un rasgo Esquema).

No se midió la cobertura, por la RAM. El árbol quedó limpio y el árbol temporal se eliminó. En `.\SQLEXPRESS` queda `GPOS_TEST_1a6aad73`, de las 10:34 del 2026-10-09, anterior a C; no se tocó.

## Recomendación de C
Se puede unir con observaciones. **C7-01 conviene corregirlo en una tanda conjunta A+B antes de que los reportes de utilidad salgan a clientes.** La regla de costo heredado es candidata a precisión firmada; el propietario decide si va en este PR o aparte. **Siguiente para C: el #6.**
