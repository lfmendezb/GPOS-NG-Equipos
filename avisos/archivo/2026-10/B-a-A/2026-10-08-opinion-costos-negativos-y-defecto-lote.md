```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng; opinión en b/conector-admcloud-diseno (docs/contabilidad/2026-10-08-opinion-costos-e-inventario-negativo.md)
Estado: Abierto
```

# Opinión contable sobre costos e inventario negativo (entrada para A-11) y un defecto en la existencia por lote

El propietario le pidió al especialista-contable de B una opinión sobre la opción sin costos y el inventario negativo. El documento está en la rama `b/conector-admcloud-diseno`. **Las recomendaciones están pendientes de decisión del propietario.**

## Defecto (Alto) en código de A
- **La existencia por lote admite negativos siempre** (`ConsultasInventario.cs:37-47`; verificado en la base de `feature/modelo-ng` que trae la rama `b/verticales-diseno`).
- **Contradice DO-07,** firmado para Duty Free: sin negativos por lote aduanero.
- También afecta a farmacia (FEFO) y a cualquier lote con vencimiento.
- **Recomendación (P-09):** que la salida por lote respete la política de negativos, y que en Duty Free, en los lotes con vencimiento y en los números de serie los rechace siempre.

## Entradas para el diseño de A-11 (opción sin costos)
- **P-02, acta de apertura de costos:** al encender o reencender el cálculo, el costo inicial lo fija el contador del cliente, con un privilegio propio. Son las cantidades de GPOS NG a la fecha de corte por el costo unitario del ERP. Sin ella, la primera compra valúa toda la existencia (`CalculoCostoPromedio.cs:30-32` y `:45`).
  - **«Ignorar lo anterior a la fecha de corte» no existe hoy:** el recálculo recorre el kárdex desde el principio (`CostoPromedioNg.cs:81-89`).
  - Esfuerzo estimado: de 0,3 a 0,5 sp de A.
- **P-03, condiciones para encender:**
  - corte el primer día de un mes y período cerrado (ADR-69);
  - nodos sincronizados;
  - negativos medidos a la fecha de corte, por almacén, por lote y en global;
  - conteo según el riesgo.
- **P-04, al apagar:** también hay corte y foto de la valuación final, y **el costo se guarda nulo, nunca cero**, para que la utilidad no salga al 100 %.
- **P-05, negativos:** prohibidos por omisión en las empresas nuevas y permitidos por artículo (ingredientes, granel). **Hoy el código los permite por omisión** (`Empresa.cs:45`, `CfgConfiguracion.cs:111`, `ConsultasInventario.cs:79-82`).
- **P-08, motivos de salida por su efecto fiscal:** según la NG 09-2021, el consumo propio no está gravado con ITBIS, mientras que los retiros a terceros y el robo sí. **Esto corrige HC-19.** El CPA lo confirma (CO-09).

B avisará las decisiones del propietario sobre CO-01 a CO-07 antes de que A redacte el ADR de A-11.
