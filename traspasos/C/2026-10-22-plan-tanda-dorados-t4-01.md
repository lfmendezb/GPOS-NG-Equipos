```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Plan (tarea 1: tanda de los 26 dorados nuevos con la guarda de P152-16), respuesta a `B-a-C/2026-10-22-respuesta-revision-pr152-y-dorados.md`
Prioridad: Media
Repositorio y rama: GPOS-NG; la tanda iría en un PR de C sobre `b/ola5-t4-01-render` (o sobre `feature/modelo-ng` cuando el #152 se una; B decide)
Estado: Abierto (plan, nada construido)
```

# Plan de la tanda de dorados de T4-01, con la guarda de «regenerar»

**Fuentes:** mi revisión (`2026-10-22-revision-pruebas-pr152-t4-01-y-dorados.md`: P152-16..20 y la lista D-01..D-26) y la respuesta de B (se aceptan P152-16 y la tanda; D-25 y D-26 esperan a A). **No leí de nuevo el código de los dorados**; lo que sigue se apoya en lo que ya verifiqué en esa revisión (62 HTML y 16 PDF, captura en `f8897418`, modo `GPOST_TEST_DORADOS=regenerar`, normalización de CRLF y de las fechas del PDF). Nada compilado ni ejecutado.

## 1. La guarda de P152-16 (va primero, en su propio commit)

**Objetivo:** que nadie pueda hacer pasar una prueba regenerando el dorado sin que quede constancia y sin que la prueba falle.

| # | Pieza | Comportamiento exigido | Prueba que la protege (debe fallar si se quita la línea) |
|---|---|---|---|
| G-1 | Modo `regenerar` | Escribe los archivos, pero **la prueba falla siempre al final** con un mensaje que dice qué archivos cambió y que debe revisarse el diff. Nunca termina en verde | `Regenerar_siempre_falla`: ejecuta el comparador en modo regenerar sobre un directorio temporal y exige el fallo |
| G-2 | Motivo obligatorio | Sin una variable `GPOS_TEST_DORADOS_MOTIVO` no regenera (falla antes de escribir) | `Regenerar_sin_motivo_no_escribe_nada` (el directorio temporal queda intacto) |
| G-3 | `CAMBIOS.md` del directorio | Cada regeneración **agrega** una entrada (fecha UTC, motivo, lista de archivos, hash anterior → nuevo). La prueba de integridad exige que cada archivo cambiado desde su última captura tenga entrada | `Todo_dorado_cambiado_tiene_entrada_en_CAMBIOS` (usa el manifiesto, G-4) |
| G-4 | Manifiesto de hashes `manifiesto.json` | SHA-256 de cada dorado más las versiones que lo producen (QuestPDF, motor Razor, PuppeteerSharp si aplica, .NET). Una prueba recalcula los hashes y los compara | `Los_dorados_coinciden_con_el_manifiesto`: editar un dorado a mano (un byte) sin pasar por el modo regenerar hace fallar esta prueba |
| G-5 | Revisión humana forzada | El manifiesto está en `CODEOWNERS` o equivalente de revisión del repositorio (si existe); si no, regla en el LEEME de la carpeta | — (prueba de texto: el LEEME menciona el modo, el motivo y CAMBIOS.md) |
| G-6 | Regenerar en CI | La variable `GPOS_TEST_DORADOS` y su motivo **no existen** en el entorno del pipeline; si aparecen, la prueba falla (`Regenerar_no_se_acepta_en_integracion_continua`) | prueba que simula el entorno de CI |

Mutaciones mentales: quitar G-1 deja verde la regeneración (G-1 lo detecta); borrar una entrada de `CAMBIOS.md` (G-3); cambiar un dorado a mano (G-4); regenerar en el pipeline (G-6).

## 2. Protocolo de captura (cada dorado, en este orden)

1. **El oráculo es la principal sin tocar.** Capturar con la rama del #152 y verificar con la prueba de equivalencia existente (principal vs copia) que ambas producen lo mismo antes de guardar nada.
2. **Dos corridas.** Capturar dos veces seguidas en la misma máquina; los dos archivos deben ser idénticos (el hash coincide). Si no, el dorado no es determinista y **no se guarda**: se reemplaza por una comprobación estructural (como indica el informe para PDF con emoji o Chromium).
3. **Mutación de aceptación.** Alterar un carácter del formato base correspondiente en un árbol temporal y comprobar que la prueba cae (esto es lo que B pidió en la tarea 1). Se anota el resultado por dorado en `CAMBIOS.md`, no se deja la mutación en el código.
4. **Fechas y reloj fijos.** Todo dato de entrada con fecha usa una fecha fija; ningún dorado depende de la hora actual ni de la cultura del hilo (fijar la cultura de la prueba; D-12 la verifica bajo `es-DO`, `en-US` y `de-DE`).
5. **Un commit por grupo** (ver §3), con la lista de dorados nuevos y el hash del manifiesto.

## 3. Tanda: grupos, orden y dependencias

| Grupo | Dorados | Se puede hacer ya | Condición |
|---|---|---|---|
| **0 · Guarda** | G-1..G-6 | Sí | Primero y sola; no se captura nada hasta que esté en verde |
| **1 · Fiscales** | D-01 Anulada, D-02 B02, D-03 B14, D-04 B15, D-05 B16_USD, D-06 B04, D-08 retenciones, D-09 constancia real, D-10 original | Sí | Nada abierto (D-05: confirmar el título con el maestro de tipos de NCF) |
| **2 · Marcas y copia** | D-11 vista previa, D-12 `MarcarCopia` (con las tres culturas) | Sí | D-12: decisión chica de B/A sobre la cultura |
| **3 · Contenido** | D-13 logo PNG/WEBP, D-16 caracteres, D-17 150 líneas, D-19 mínimos, D-24 pago mixto, D-23 número largo | Sí | D-16 y D-17: PDF estructural, no bytes (emoji y fuentes del sistema) |
| **4 · Documentos de inventario** | D-18 sin ver costos, D-21 conduces, D-20 cierres | Sí | D-18 fija el comportamiento actual (el factory pone ceros); D-21: confirmar los estados reales del DTO |
| **5 · Diseñador gráfico** | D-14 imágenes con evento 4790, D-15 ticket 58 y carta horizontal | Sí | D-14: marcar `Trait("Transicion","v2")`, caduca con la v2 (SVG) |
| **6 · Reportes** | D-22 `FormatoReporte` (25, 0 y 120 filas) | Sí | Con la hora inyectada; tras T4-02 es la única línea base |
| **7 · A decidir** | D-07 e-CF (solo ancho), D-25 papeles A4/Oficio/MediaCarta, D-26 Chromium estructural | **No** | D-07: ADR-51/108/124. **D-25: no capturar** hasta decidir si es defecto (congelarlo lo vuelve intocable). D-26: método de comparación (recomiendo estructural con PdfPig) y `[FactConNavegador]` |

**Orden:** 0 → 1 → 2 → 3 → 4 → 5 → 6; el grupo 7 espera a A. Cada grupo es un commit, y cada commit deja la carpeta con manifiesto y `CAMBIOS.md` coherentes.

## 4. Dónde y cómo se ejecuta
- **Máquina:** B pide confirmar cuál antes de que empiece C (su respuesta). Mi recomendación: **la tanda completa en `LFMB` o en otra máquina estable**; en OSHIN-LEGION solo la guarda (grupo 0) y capturas dirigidas por clase si B las pide, porque la captura necesita dos corridas por dorado y la PC es inestable.
- **Filtro:** siempre por clase (`FullyQualifiedName~Dorados`) con el filtro oficial; nunca la suite completa en OSHIN-LEGION.
- **Chromium (D-26):** necesita navegador en la máquina; sin él, la prueba se omite con motivo (`[FactConNavegador]`), nunca pasa en vacío.
- **Esfuerzo (inferido, ±40 %):** guarda 0,5 dp; grupos 1 a 6 ~2,0 dp (la mayor parte es la doble corrida y la mutación por dorado); grupo 7 ~0,5 dp después de las decisiones. Total ≈ 3,0 dp.

## 5. Qué necesito de B / A
- **B:** confirmar la máquina; confirmar si el PR de la tanda va sobre `b/ola5-t4-01-render` o espera a que el #152 se una; decidir D-12 (cultura invariante) y dónde queda `CODEOWNERS`.
- **A:** D-25 (¿defecto o diseño?), D-26 (método de comparación) y D-07 (qué se vigila del e-CF).
- **Conflictos:** la guarda toca el comparador que usa `RenderTrasladoTests`; coordinar con el agente de B que corrige P152-01/04/05 para no editar el mismo archivo a la vez.

## 6. Lo que no verifiqué
No volví a leer el comparador ni el LEEME de la carpeta de dorados; los nombres `GPOS_TEST_DORADOS` y `manifiesto.json` son los de mi revisión o propuestas nuevas. No sé si el pipeline define alguna variable que choque con G-6.
