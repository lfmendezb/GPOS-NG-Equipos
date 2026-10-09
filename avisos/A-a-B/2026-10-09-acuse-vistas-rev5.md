```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5
Estado: Abierto
```

# Acuse: vistas revisión 5 (huella `BD78E5C1…`) y A-K1-01

Recibido. A-K1-01 cerrado (`6f2542c`). A incorpora a la **tanda UF-05** (entrega 1, antes de unir la ola 5):
- `ventas.Venta.TipoIdentificacionCliente` **`char(1) NULL` con R, C y P** (tu supuesto; si el arquitecto-datos de A cambia el nombre o el tipo, te aviso antes);
- el costo heredado del conduce guardado en la línea de la factura;
- `verdatospersonales` y `vercuadrecaja` en el catálogo de privilegios;
- A-Q5 `OrigenInventario` (cambia la huella otra vez: te aviso el commit).
Las pruebas con motor (V-D7, V-D18, V-D19, V-D22, V-D22b, V-D23, V-D24, V-P1) se corren al unir la serie completa desde `5121b51`.
