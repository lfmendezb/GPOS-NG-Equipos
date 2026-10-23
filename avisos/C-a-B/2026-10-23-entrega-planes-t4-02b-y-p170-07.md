```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tareas 3 y 4 de `B-a-C/2026-10-23-tareas-nuevas-para-c-4.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG (planes; sin código)
Estado: Abierto
```

# Entrega: plan de pruebas de T4-02b y tabla adversaria de P170-07

Adelantados respecto de las fechas del acuse (borrador 28-oct). Solo documentos; no se compiló ni se ejecutó nada, y la espiga `e112ae91` se leyó pero no se corrió.

- `traspasos/C/2026-10-23-plan-pruebas-t4-02b.md`: C-2, C-3, C-4, C-6 y C-7; las pruebas del 503 (11 casos) y del reintento (12 casos); adaptación de los 10 archivos (6 casos nuevos); prueba transitiva; medición «después». 30 mutaciones (M-T01 a M-T30). Esfuerzo ~3,5 dp.
- `traspasos/C/2026-10-23-plan-tabla-adversaria-p170-07.md`: 54 casos (TA-01 a TA-54), 10 pruebas de opciones del PDF, M-a a M-e más 22 mutaciones. Esfuerzo ~2,0 dp.

**Hallazgos:** `Si_el_render_falla_el_reintento_no_cuenta_otra_copia` nace verde en la impresión fiscal (H-T402-02; se sostiene con M-T01 a M-T04). P-T402-01 firmada en (a): la variante para el conduce es obligatoria. La espiga documenta mal `PreferCSSPageSize=false`; la mitigación real es la guarda C-1. Una plantilla puede pintar una marca falsa (TA-31, riesgo residual para A).

**Dudas para B** (sección final de cada plan): dónde se archiva la línea base de C-3; código del 503 (`REPORTES_NO_DISPONIBLE` o `NAVEGADOR_NO_DISPONIBLE`); 10 o 13 archivos de pruebas; regla del reintento libre (R429-06); lista final de la prueba transitiva; código de error cuando C-1 rechaza; doble banda con QuestPDF; margen de la guarda fijo (10 mm) o por papel; resultados de la espiga para TA-27, TA-43 y TA-54 (si alguno rompe la opción (b), la hoja manda pasar a (c) más CDP).

Respuesta requerida: respuestas a las dudas antes del 3-nov.
