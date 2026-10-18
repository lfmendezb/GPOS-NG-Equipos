```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5-diseno (a909501)
Estado: Abierto
```

# Ola 5: el corte de la entrega 1 pasa a mediados de diciembre (respuesta del propietario)

El propietario aprobó el diseño de la ola 5 en B (rama `b/ola5-diseno`, solo `docs/`) con la API de reportes de solo lectura como requisito, e incluyó el blueprint v2 de reportes. El 2026-10-07 respondió las preguntas del blueprint de software (`docs/decisiones/2026-10-07-respuestas-propietario-ola5.md`):

1. **Calendario: el corte de la entrega 1 se mueve a mediados de diciembre**, con la API de reportes separada desde la entrega 1.
   - La ola 5 sube de 2,5 a unas 5,0 sp, sin contar las vistas, que estima el arquitecto-datos.
   - **Afecta el plan de A.**
2. **Token:** mientras la firma sea HS256, la API de reportes valida cada token preguntando a la API principal por loopback (`/api/interno/token/verificar`). Es temporal: ES256 (ADR-41) no se adelanta.
3. **La API de reportes va en el mismo equipo que la API principal de su sitio,** de momento.
4. **Razor del SUPER** corre en la API de reportes sin aislarse por empresa, todavía sin fecha de retiro.
5. **Formatos v2** (JSON con Blazor, Liquid y evaluador de fórmulas): van en una fase propia después del corte, de unas 4,0 sp. En la ola 5 entran solo la prueba de concepto de paginación y el esquema del contrato.

## Documentos en `b/ola5-diseno`
- `docs/arquitectura/2026-10-07-ola5-api-reportes-diseno.md`: decisiones DR-01 a DR-14. Choca con tres decisiones firmadas, que van como precisiones:
  - ADR-40 había descartado un proceso aparte para los reportes;
  - el diseño del análisis (7.1) también lo había descartado;
  - ADR-42 dice que el diseño gráfico genera Liquid.
- `docs/contabilidad/2026-10-07-ola5-requisitos-reportes.md`: requisitos contables y fiscales (ver el aviso `2026-10-07-fallos-vistas-fiscales-607`).
- `docs/datos/2026-10-07-ola5-vistas-reportes.md`: en preparación por el arquitecto-datos.

Después viene la hoja de firma del arquitecto-maestro de B, con los ADR propuestos en el rango de B: la API de reportes y el motor de formatos v2.
