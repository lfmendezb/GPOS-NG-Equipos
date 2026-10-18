```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto
```

# Decisiones del propietario: API de reportes, corte y vistas fiscales

Responde a `avisos/B-a-A/2026-10-07-api-reportes-solo-lectura.md`, `2026-10-07-ola5-corte-mediados-diciembre.md` y `2026-10-07-fallos-vistas-fiscales-607.md`. El propietario firmó las tres recomendaciones de A el 2026-10-08.

1. **API de reportes de solo lectura: consolida B.** Una sola hoja de firma, del arquitecto-maestro de B, con números del **rango de B**. Los ADR-77 a 80 de A quedan libres (nunca se registraron). Como insumo, A deja su hoja y la propuesta del arquitecto-software en `traspasos/A/hoja-firma-api-reportes-2026-10-07.md` y `traspasos/A/propuesta-api-reportes-solo-lectura-2026-10-07.md`. Las partes que suponían el corte del 2 de diciembre, el proceso aparte después del corte, solo la central y ES256 quedan superadas por las respuestas del propietario a B. **Hallazgos que siguen vigentes y conviene incorporar:**
   - **K-02:** un propósito de Data Protection no aísla. El proceso aparte necesita su propio anillo de llaves y solo las cadenas `gpos_rpt*`. Si no, no reduce el daño posible, que es su razón de ser.
   - **K-01:** los 120 s chocan con ADR-38 M-2. Hace falta una precisión, solo para los reportes programados.
   - **K-03:** DA-02 es condicional. `rptc` en los nodos solo con `CostosSoloEnCentral` apagado.
   - **K-07:** `gpos_app` no tiene `SELECT` sobre `rpt`, y el dominio lee `rpt.Conciliacion*`.
   - Además K-08 (AN-02 sin firmar), K-09 (claves de Power BI fuera de la consulta) y K-12 (`rpt` como lista blanca de ADR-40 R1).
2. **Corte de la entrega 1 a mediados de diciembre**, también para el plan de A.
3. **Vistas fiscales:**
   - **H-R01** (el 607 duplica los reemplazos de contingencia, rol R) lo corrige **A en el cierre de la ola 4**, en `feature/modelo-ng`. A avisa del commit para que las vistas de la ola 5 partan de él.
   - **H-R02 y H-R03 a H-R09** van a las vistas de la ola 5 de B.
