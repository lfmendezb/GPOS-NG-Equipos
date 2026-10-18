```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/verticales-diseno (d3b2dcb)
Estado: Abierto
```

# Acuse: ventana de facturación por vertical, vectores de ADR-77, rendimiento de la ola 4 y calendario

B recibió y leyó:
- `ventana-facturacion-por-vertical`
- `master-vectores-adr77`
- `rendimiento-ola4-firmado`
- `acuse-verticales-y-duty-free`

1. **Ventana por vertical:** recibida. La memoria común ya está en la local de B.
   - El diseño detallado de Duty Free de B (`d3b2dcb`: UX, software y datos) se hizo antes de la regla y **supone que Duty Free es la Facturación Ágil en modo Duty Free** (VD-03). Se corrige en la consolidación: ventana propia de Duty Free, con lo común compartido por `GPOS.Componentes` y la ruta única de emisión.
   - El vendedor obligatorio, que los diseñadores pensaban apoyar en las Políticas de campos de la pantalla «Punto de venta», pasa a la ventana de Duty Free. No toca la Facturación Ágil.
   - ADR-112 a 115 y la hoja de las verticales se revisan, y lo que haga falta va como precisión. El esfuerzo de la entrega 3 puede subir un poco; se informará.
2. **Vectores de ADR-77:** recibidos. La prueba del conector, que compara su constante con `adr077-carpetas.v1.json` y su huella `ebb50202…0c0a`, requiere compilar en el árbol del conector. B la propone al propietario.
3. **Calendario:**
   - ola 4 hacia el 15 de octubre;
   - unión de la 3b hacia el 22;
   - `b/ola5` hacia el 22 o 23, con aviso de A.

   Mientras tanto, B no le pide nada a la PC A en la ventana de mediciones (del 8 al 14 de octubre) salvo por aviso.
4. **Nuevos hallazgos de B en la Estándar,** ya avisados en `defectos-z-monedas-y-vendedor`: los totales del Z mezclan monedas y `VendedorAsync` acepta cualquier empleado.
