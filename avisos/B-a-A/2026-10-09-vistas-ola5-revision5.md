```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Alta (precondición para unir la ola 5)
Repositorio y rama: GPOS-NG b/ola5 (6f2542c a 3de1752, en origin)
Estado: Abierto
```

# Vistas de la ola 5, revisión 5 (respuestas 1 a 6) y A-K1-01

- **Huella nueva del contrato:** `BD78E5C1B2C59AE8326D2D3FE8C5EB62B38142D6674A7BA35DF97AC23930C421`. Sustituye a `429E5D4D…`. Siguen siendo 41 vistas y 713 columnas. La calcula y compara la prueba nueva `ContratoVistasTests`.
- **Qué incorpora la revisión 5:**
  1. El enmascarado lo decide el tipo de identificación de la venta, no el formato.
  2. El costo de la línea de una factura con conduce se hereda del conduce en `rptc.VentaLinea`.
  3. La clase 7 del conteo queda documentada.
  4. El contrato usa las claves de privilegio `vercostos`, `verdatospersonales` y `vercuadrecaja`.
  5. La columna se llama `RncReceptorEnmascarado`.
- **A-K1-01** (`6f2542c`): `ParametrosTokenSesion` exige `typ = JWT`, con 7 pruebas. `GPOS.Reportes.Tests` da 136 de 136.
- **Importante:** el script exige ahora la columna **`ventas.Venta.TipoIdentificacionCliente`** (supuesto: `char(1) NULL`, con R, C y P) y falla si no existe. **No existe en `472d078`.** Debe crearla la tanda UF-05 antes de unir la ola 5. Si cambian el nombre, B ajusta cinco vistas y la precondición, sin tocar el contrato.
- **Pendiente de A** para la ola 5:
  - guardar en la línea de la factura el costo heredado del conduce;
  - agregar `verdatospersonales` y `vercuadrecaja` al catálogo;
  - A-Q5 (`OrigenInventario`), que volverá a cambiar la huella;
  - las pruebas con motor: V-D7, V-D18, V-D19, V-D22, V-D22b, V-D23, V-D24 y V-P1.
- Unan la serie completa: la huella del script coincide con la del JSON desde `5121b51`.
