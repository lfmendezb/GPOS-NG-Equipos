```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso y preguntas
Prioridad: Alta (antes de unir la ola 5)
Repositorio y rama: GPOS-NG b/ola5 (a4588ee a e1a8724, en origin)
Estado: Abierto
```

# Vistas de la ola 5, revisión 4: FactorUnidad (TC-01 a TC-05) y datos sensibles (RS-01 a RS-03 y RS-07)

- Revisión hecha sobre `472d078`.
- **Huella nueva del contrato: `429E5D4DB2CBB7930AE98B344B8D0599D23BFFEAD5B9F7B7CCDEC11546CAA2E4`.** Sustituye a `DC024084…26E60A22`. El contrato sigue en la 1.0 sin publicar, con 41 vistas y 713 columnas.
- **Commits:**
  - `a4588ee`: TC;
  - `e968de3`: RS-01 y RS-02;
  - `784f1fe`: RS-03, campo `privilegio` por vista;
  - `64dd373`: LEEME y RS-07;
  - `e1a8724`: informe `docs/construccion/2026-10-09-vistas-tc-rs-informe.md`.
- **Corrección extra:** `rptc.VentaLinea.CostoBase` ahora va en unidad base. Antes, una venta por caja de 12 se costeaba a la doceava parte.
- La precondición del script exige `Ola4FactorUnidadAjustes`. El motivo se llama «Pérdida».

## Preguntas (sección 4 del informe)
1. ¿Se agrega el tipo de identificación, o se sella el pasaporte, en `ventas.Venta` y `fiscal.Comprobante`? Sin eso, un pasaporte de 9 dígitos tecleado en la venta de un cliente genérico sale como RNC. Riesgo Medio, abierto con RS-05.
2. ¿La línea de una factura de conduce trae su costo aunque no tenga kárdex propio?
3. ¿El movimiento de clase 7 del conteo lleva el costo del renglón, y su unidad cuando se contó en cajas?
4. ¿`caja.Cierre.Anulado` coincide siempre con el estado 2 del documento?
5. ¿Qué identificador usa el catálogo de privilegios? En el contrato van los nombres visibles; cambiarlos después altera la huella.
6. ¿`RncReceptorEnmascarada` (sufijo uniforme, como la decisión firmada) o `RncReceptorEnmascarado`?

## Para A al unir
- Los dos privilegios nuevos en el catálogo.
- Las pruebas V-D1b ampliada, V-D18 a V-D23 y V-C1 con motor.
