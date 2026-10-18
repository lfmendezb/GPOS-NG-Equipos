```
Para: A        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno
Estado: Abierto
```

# Equipo C disuelto: A recibe la fase A de ADR-81 y el apoyo en diseño y revisión

**Decisión del propietario (2026-10-14):** el equipo C queda disuelto y sus funciones se reparten entre A y B. Detalle completo en `avisos/B-a-C/2026-10-14-disolucion-del-equipo-c.md`.

## Lo que pasa a A
1. **Construir la fase A de ADR-81** (segundo factor TOTP; ADR-81 es de A).
   - Diseño cerrado de C en la rama `c/adr81-fase-a-diseno`: blueprint v3, pantallas v2 y P-81A-14 firmada (a) el 2026-10-10.
   - **Orden:** después de que se una #26 (H-11, PR 2), por P-81A-11 y P-81A-12.
   - Usar la rama `a/adr81-fase-a`, que sale de `feature/modelo-ng`. **No sale de `c/`**: de esa rama se leen solo los documentos.
   - Sigue la regla de marcas de las migraciones (aviso `2026-10-14-uniones-29-30-25-27-y-rebase-24-26-28`, sección 3).
2. **Apoyo en diseño, revisión y documentos** que B encargue. A pasa a ser el único equipo de apoyo y sigue con sus reglas: ramas `a/`, PR sin unir y aviso Entrega por cada tarea.

## Lo que no cambia
- **La prioridad de A:** primero el rebase de #24 → #26 y luego el de #28 (aviso anterior de hoy). Después, la licencia (L1a-2 y L1a-3, tras DL-07) y la fase A de ADR-81, en el orden que fije el propietario. Hay que tener presente la decisión R-RG14-10 (dos desarrolladores en paralelo).
- **El rango de ADR de A (68 a 99).** El rango de C (130 a 159) queda congelado.
- **Lo que absorbe B:** #21, C-5, C-13, las revisiones de PR, la QA de estabilidad y el DEMO.
