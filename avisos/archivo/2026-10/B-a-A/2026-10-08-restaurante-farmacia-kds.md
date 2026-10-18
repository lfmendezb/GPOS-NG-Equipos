```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG master (6003b2a, 8137c7d, 9694a57, de5ceea, 8f58617, fc183c5); diseños en b/verticales-diseno (89ba610) y b/restaurante-kds-diseno (3989a43)
Estado: Abierto
```

# Decisiones del propietario de esta noche: Restaurante, Farmacia y KDS

Informativo. Nada cambia lo que A tiene en curso para la entrega 1 (ADR-118/119 desde el 15-oct), salvo lo marcado «para A».

## Restaurante (precisiones de ADR-113 en `master`)
- **Plano con muchas áreas** (columna lateral desde 7), **áreas asignadas y favoritas** (solo ordenan) y **áreas restringidas** (p. ej. VIP: solo meseros autorizados; los demás con supervisor, ADR-68, validado en el servidor) — `9694a57`.
- **Botonera de la cuenta por capas** sin límite, con **árbol de menú propio** independiente de la categoría de inventario (un plato en varias capas); menú por horario o área, después — `6003b2a`.
- **Imágenes en todos los botones** (capas y platos), opcionales, que viajan al nodo con el menú — `8137c7d`. Recomendación de datos de B: guardarlas en la base de la empresa por huella para que bajen con la réplica del menú (decisión candidata, posible precisión de ADR-53).
- VR-14, 16, 19 y 20 según la recomendación — `de5ceea`.

## Farmacia (precisión de ADR-112, `8f58617`)
Búsqueda por **principio activo** (DCI, con sinónimos), artículo ↔ varios principios con concentración, forma y vía; **equivalentes** sugeridos; **acción terapéutica**; **«controlado» marcado en el principio** y heredado por el producto. **Para A:** toca `cat.Articulo` y la venta de controlados; el diseño de datos lo hace B (`b/farmacia-principio-activo`) y te avisa.

## KDS, pantalla de despacho y comandera móvil (reabre P-03 y Q-11 de la hoja de verticales)
- K-1 convive con la impresora por estación, con respaldo automático; K-2 tramo 3b, después de la comanda impresa; K-3 módulo de licencia que activa el SUPER; K-4 navegador en pantalla o tableta con *bump bar* opcional. Área de meseros: **despacho y comandera móvil**.
- Blueprint de B (`3989a43`): misma cola de ADR-114 con salida por área; espera larga de 25 s (no hay SSE en el código); **registro único de dispositivos** que generaliza la credencial de ADR-114 punto 5; comandera recomendada en **MAUI Android** con los mismos endpoints de la caja. Unas 5,7 sp en 3b. Hoja de firma pendiente.
- **Para A (contratos que comparte la caja):** el **lote por línea en la ronda** y el **estado de cocina por línea** en el contrato de la cuenta de mesa; tenerlos en cuenta cuando se diseñe el contrato de 3b.

## Ya avisado antes
`LoteVencido = 'A'` retirado (`fb32df8`), reimpresión fiscal con privilegio o supervisor en todas las ventanas, mesero con PIN y lote del ingrediente.
