---
name: modulo-analisis-estrella
description: "Decisión del propietario (2026-10-04): modelo analítico en estrella como módulo de análisis adicional y opcional, con privilegios exclusivos; rpt sigue siendo la opción por defecto"
metadata:
  node_type: memory
  type: project
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-04T21:02:35.841Z
---

El 2026-10-04 el propietario preguntó si el modelo nuevo podía tener un OLTP en 3FN y un modelo para análisis OLAP. Decidió: **encargar la propuesta del modelo analítico en estrella como un módulo de análisis adicional, con un apartado de privilegios exclusivo para él, y mantener las vistas de reportes `rpt` como la opción por defecto del sistema en general.**

**Why:** quiere análisis más eficientes sin que compitan con el punto de venta, sin cambiar el camino por defecto de los reportes.

**How to apply:**
- `rpt` sobre el OLTP es el camino por defecto de todos los reportes; el módulo de análisis es opcional, activable por empresa, solo en la central (no en los nodos).
- Privilegios del módulo en un área propia, separada de los permisos `rpt:<id>`, respetando ADR-11, 12 (Ver costos), 32 y 34-36.
- Propuestas encargadas el 2026-10-04: datos en `GPOS NG/docs/propuestas/2026-10-04-modulo-analisis-estrella-datos.md` y software en `GPOS NG/docs/arquitectura/2026-10-04-modulo-analisis-diseno.md`; luego el arquitecto-maestro las lleva a firma.
- La estrella sería la fuente natural del futuro MCP de IA (ver [[mcp-modelos-ia-pendiente]]).

Relacionado: [[decision-modelo-datos-propio-pendiente]].

**Respuestas del propietario (2026-10-04) a las preguntas del diseño del módulo:**
1. El módulo **se licencia aparte**.
2. **Versión completa** (con explorador), no la reducida.
3. Perfiles sugeridos **Gerente, Analista y Auditor** aceptados, **extensibles** según lo que pida cada cliente (las empresas pueden crear perfiles propios con los permisos del grupo «Análisis»).
4. **Precisión del propietario:** la «versión reducida» del módulo es, en la práctica, el marco actual de reportes `rpt`, porque ya permite generar reportes a medida. Por eso el módulo de análisis se construye solo en su versión completa y no se diseña una variante reducida aparte.

**Consolidado del maestro (2026-10-04):** `GPOS NG/docs/decisiones/2026-10-04-decision-modulo-analisis.md`, Aprobar con observaciones. Hoja AN-01 a AN-17 (AN-01 índice `IX_Documento_Version` antes de la ola 3, 2026-10-28; AN-02 vistas de extracción en esquema `ext` antes de la ola 5, 2026-11-16; AN-03 a AN-17 antes de construir el módulo, después del corte del 2026-12-02). ADR-55 a 57 en estado Propuesto (números provisionales). Costo ~13,0 sp, USD 0 en licencias. Venta del módulo condicionada a la versión 1 del acceso multiempresa (SA-01). Pendiente del propietario: gracia al vencer la licencia (K-AN-03). Error 468 de tempdb: incluir como punto (7) de H-08 antes de la ola 1.
