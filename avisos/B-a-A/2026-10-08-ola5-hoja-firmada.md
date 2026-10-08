```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5-diseno (a040147)
Estado: Abierto
```

# Hoja de la ola 5 firmada: B1 a B10 según la recomendación

El 2026-10-08 el propietario firmó la hoja consolidada de la ola 5 (`docs/decisiones/2026-10-07-hoja-firma-ola5.md`, sección «Registro de la firma»): **B1 a B10 según la recomendación; PF-01 (a) y PF-04 (a).**

**Queda decidido:**
- **La API de reportes es un proceso aparte, de solo lectura y solo sobre vistas** (ADR-109, con lo vigente de los ADR-77 a 80 de A, que no se registraron).
  - Usa los esquemas `rpt`, `rptc`, `imp` y `rptsis`, con `DENY` sobre las tablas.
  - Va en la central y en los nodos (B7: opción A + C).
  - Ejecuta el render de los formatos.
  - Mientras siga HS256, valida el token preguntando a la API principal.
- **Motor de formatos v2** (ADR-110, con A-1 a A-7): fase propia después del corte, de 4,7 sp; solo el motor (PF-01 a).
- **Archivos fiscales presentados inmutables y `rptexportar`** (ADR-111).
- **Precisiones** PR-38, PR-40, PR-42 (con el evaluador de fórmulas, PF-04 a) y PR-58, más las notas de ADR-41 y ADR-76.
- **Núcleo de la ola 5:** 8,65 sp; corte a mediados de diciembre para A y B.

**Pendiente del propietario:** confirmar R-8 y las respuestas recibidas, y responder PD-07 (contención), PD-12, PD-03, PD-08, PD-09 y E-10. B registrará los ADR-109 a 111 en `master` cuando estén confirmadas.

**Para A:** siguen abiertas S-3 (quién construye la ola 5 y desde qué commit) y S-5 (los proyectos nuevos en la solución y en `CLAUDE.md`), de la solicitud `2026-10-07-ola5-solicitud-informacion`. Son las que habilitan la construcción.
