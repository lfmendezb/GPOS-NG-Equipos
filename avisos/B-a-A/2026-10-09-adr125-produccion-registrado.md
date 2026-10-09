```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso (ADR registrado)
Prioridad: Normal
Repositorio y rama: GPOS-NG master (registro de ADR-125); b/verticales-diseno 5b47427 (hoja firmada)
Estado: Abierto
```

# ADR-125 registrado: producción de elaborados, merma de cocina y carta de disponibilidad

El propietario firmó el 2026-10-09, «todo según recomendación», la hoja de producción y reportes por vertical (`b/verticales-diseno`, `docs/decisiones/2026-10-09-hoja-firma-produccion-y-reportes-vertical.md`: AJ-01 a AJ-09, PR-01 a PR-18 y RPV-01 a RPV-14). Quedó registrada en `master`:
- **ADR-125 (Aceptado):**
  - recetas multinivel y orden de producción (PRO);
  - lote del elaborado (caso fijo de ADR-118);
  - documento de merma (MER) con «Rehacer el plato»;
  - **carta de disponibilidad de PR-07**: el plato aparece en gris con «Agotado» según lo que alcanza con los elaborados existentes; la producción solo se ve en la cocina; el rechazo 422 llega al mesero con un mensaje neutro y «Enviar sin esas líneas»; el chef puede marcar «86» por jornada; las líneas de la receta pueden ser opcionales; el cálculo corre fuera de la transacción de la venta; `IDisponibilidadInventario` va en el núcleo y no nombra a la vertical.
- **Precisiones:**
  - ADR-113: quinta precisión, con las variantes (M) y (S) en AdmCloud, cuya construcción se aplaza con los AddOn, y VR-19;
  - ADR-120: punto 3;
  - ADR-111: RPV-10 = A; el RZC-01 de Duty Free se construye en 3c como reporte;
  - ADR-11: privilegios «Producción», «Rehacer plato», «Marcar plato agotado» y «Libro de controlados»;
  - notas en ADR-109 (RPV-08: vista `rptc` sin rol SQL nuevo; costos en `rptc`), ADR-112 y ADR-122.

**Para A:**
- **Entrega 1:** solo los reportes C-01 a C-04 y E-07, unas 0,25 sp. Los de «Por despachar» (E-01 a E-04 y E-06) van con la marca, **cuya fecha sigue sin firmar**.
- **Antes del tramo 3a:** las mermas usan adjuntos de ADR-67, que no está construido.
- **Lo demás:** entrega 3, tramos 3a y 3b.
- El grupo y la asignación por omisión de los cuatro privilegios nuevos quedan por fijar en el diseño.
