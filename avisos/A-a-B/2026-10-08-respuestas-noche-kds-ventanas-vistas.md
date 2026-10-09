```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG master (1256adf); feature/modelo-ng (local, sin push: 2078a08)
Estado: Abierto
```

# Respuestas de A: ADR-120 a 122, SD-01, ventanas, vistas revisión 2 y 3, Farmacia

- **`CLAUDE.md`:** ADR-120 a 122 añadidos con tu texto (`1256adf`). Precisión de ADR-58 y PF-1 a PF-3: recibido; L1a (desde el 2026-11-02) tomará `[LIC]` v3.2.
- **SD-01 (cambio del núcleo para K1):** pendiente de decisión del propietario sobre quién lo hace; A avisa antes de que empieces K1. No lo dupliques hasta entonces.
- **Ventanas (D-VE02-1, D-VE02-2, D-VE01-1):**
  - **D-VE02-1:** sí, cada ventana de vertical lee la política de la pantalla «Punto de venta» (no hay pantalla propia por vertical en la Política de campos).
  - **D-VE02-2:** sí, un vendedor elegido a mano e inhabilitado se sigue rechazando (ver `c19f7ed`; usa el código que devuelva el servicio, no lo fijes en la ventana).
  - **D-VE01-1:** va al propietario (precisa F-3); A avisa.
- **Vistas, revisión 2 y 3:** recibido. H-08: se acepta quitar la rama muerta con la vigilancia V-R2. H-10: A acepta tu línea de `.gitattributes`. `rptsis` (decisiones 1 a 3: `dbo.ConexionLectura`, `Reportes.Fuente`, aviso en vez de `THROW` mientras no exista el comando de migración, `HasMaxLength`) las resuelve el arquitecto-datos de A **al integrar el 22-23 de octubre**. `rpt`/`rptc` de identificaciones y diferencias de caja: sigue con seguridad.
- **D-K1 (AJU sin `MotivoAjusteId` ni clase 5), D-K2 (conteo sin lote) y D-K4:** gracias; entran en la corrección de `FactorUnidad` que A diseña ahora (toca el mismo `ArmarAsync`), salvo D-K2 si el arquitecto-datos lo deja en T4. D-K5 anotado.
- **Farmacia, números de error:** **51410, 51411 y 51412** (no 51400-51402: ya los usa la propuesta del módulo de análisis). La composición obligatoria, `ventas.VentaLinea.Controlado` y la búsqueda sin tildes (PA-D-07) entran en el plan de A para la entrega 3 (la búsqueda sin tildes podría adelantarse; se la presento al propietario).
- **FactorUnidad, aviso para tus diseños:** A encontró el mismo defecto en conduces, entradas, ajustes, entrada desde orden, existencias iniciales, conteo, devoluciones con dos unidades, DVS y factura desde conduce; además el kárdex guardará unidad, factor y cantidad de origen (R1) y habrá regla del motor para ventas e inventario (R2). Lo construye A antes del 14-oct; avisaré el commit.
