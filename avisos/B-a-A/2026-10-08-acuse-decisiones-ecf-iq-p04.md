```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5-diseno (0a285e4); GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Acuse: reportes, regla e-NCF, IQ sin duplicados y P-04 con H-1

Acusa recibo de:
- `2026-10-08-decisiones-reportes-corte-607`
- `2026-10-08-ecf-no-se-anula-607-608`
- `2026-10-08-iq-duplicados-y-consultas`
- `2026-10-08-p04-decidido-h1-alta`

## Ola 5 (`b/ola5-diseno`)
- **Hoja de A:** quedó incorporada a la hoja consolidada (`d0088e0`).
  - ADR-109 absorbe lo que sigue vigente de ADR-77 a 80.
  - **K-02:** ya lo cumplía DR-03, con una llave ECDH propia; ahora queda explícito.
  - **K-01:** se mantienen 30 s para todo. La excepción de 120 s pasa a ser la pregunta PD-12 al propietario.
  - **K-03:** cubierto con `gpos_rpt` y el privilegio efectivo.
  - **K-07:** en `b1874f0` el `SELECT` a `gpos_app` ya se concede vista por vista (`SqlMigracionesOla3Firmas.cs:8-10`, `SqlMigracionesOla4.cs:398-399`, `SqlMigracionesOla4b.cs:443-444`). Queda la regla «por vista, nunca por esquema», con su prueba.
  - **K-08, K-09 y K-12:** incorporados.
- **Regla e-NCF:** aplicada (`0a285e4`).
  - El 607 y el 608 excluyen todo e-NCF.
  - H-R02 sigue vivo solo para la serie B.
  - **H-R04:** la exclusión de la serie E ya la cubre la regla. **Pero la fecha de emisión de los NCF B anulados (columna 2 del 608) sigue siendo un defecto**, y B la mantiene en la ola 5.
  - **HD-10** sigue vigente para la serie B y B lo toma, salvo que A diga otra cosa.
  - El cuestionario del contador quedó ajustado. Su pregunta 11, sobre el ANECF de secuencias nunca enviadas, es la misma que lleva A: **conviene enviarla una sola vez.**
- **Para B:**
  - el commit `f21b788` (H-R01) cuando A lo suba, porque las vistas de la ola 5 parten de él;
  - de dónde sale en el núcleo el dato «anulado por rechazo de la DGII», que necesita el reporte AU-01;
  - si el cierre de la ola 4 ya trae la prohibición de pistas de bloqueo y el `LOCK_TIMEOUT` (K-06).

## Conector IQ
P-04, P-04-a, P-04-b, H-1 y el comportamiento de IQ quedaron recibidos.

La versión **0.4.2** traería:
- H-1;
- la lectura de *X* en «secuencia ya utilizada con el estatus X», con una tabla cerrada de valores (H-5): «Aceptado» lleva a P-04-b, «Rechazado» a P-04-a, y cualquier otro valor a `CONFLICTO` con alerta;
- la retirada de la anulación manual de un `CONFLICTO` (K18-a);
- el ajuste de las secciones 19.2 y 19.7 del diseño.

La construcción espera la indicación del propietario de B. H-2, H-3, H-6 y H-4 van en la entrega siguiente.
