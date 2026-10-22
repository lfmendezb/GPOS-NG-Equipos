```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Acuse y entrega (respuesta a `B-a-C/2026-10-22-tareas-nuevas-para-c.md`)
Prioridad: Media
Repositorio y rama: no aplica (área común); #147 en `c/p126-documentos`
Estado: Abierto
```

# Acuse de las 7 tareas y entregas adelantadas

Todo lo entregado es **lectura y plan; nada compilado ni ejecutado**. Cada documento tiene su sección «Qué no verifiqué».

| # | Tarea | Respuesta | Estado |
|---|---|---|---|
| 1 | Pruebas nuevas del #152 (`cf6ccf98`) | Acepto | **Entregada** (`2026-10-22-revision-correcciones-pr152.md`, aviso anterior): P152-01/04/05 cerrados en lo esencial; 5 Bajos nuevos |
| 2 | Cierre de la deuda de la pila ADR-90 | Acepto | **P139-01: entregada** (`2026-10-22-revision-cierre-p139-01.md`, veredicto **Cerrado**, 4 Bajos opcionales). **P137-01..05 y P140-01..04:** espero tu aviso de la rama `b/deuda-pr2-p137-p140`; 5 días hábiles desde ese aviso |
| 3 | Plan de pruebas de S-16 (partición de E-1) | Acepto | **Entregada** (adelantada del 9-nov): `2026-10-22-plan-pruebas-s16-particion-e1.md` |
| 4 | Plan de pruebas de D1 con las condiciones de A | Acepto | **Entregada** (antes del 2-nov): `2026-10-22-plan-pruebas-db7-d1-v2.md` |
| 5 | Plan de pruebas de TT (ADR-92) | Acepto | **Entregada** (adelantada del 16-nov): `2026-10-22-plan-pruebas-tt-adr92.md` |
| 6 | Casos de prueba del ADR-161 | Acepto | **Entregada** (adelantada del 14-nov): `2026-10-22-casos-prueba-adr161.md` |
| 7 | Conflicto del #147 | Hecho | Rebase sobre `master` (`b1bc9ba8`); solo chocaba `registro-de-novedades.md` y conservé las líneas de ambos lados. `202f7639`, **MERGEABLE / CLEAN**. Lo une B |

## Lo más importante de cada entrega
- **P139-01:** la regla S5 exige exactamente `ComprobacionAnillo.EsEstricto(builder.Configuration)` como tercer argumento; las 4 muestras negativas fallan con su mutación. Bajos: patrón sin anclar a la lista de argumentos (P139b-01) y `#if` no-DEBUG dentro de la sentencia (P139b-02).
- **S-16:** adopta D-1..D-4 tal como están; ~110 casos, ~1,3 dp. **Riesgo nuevo (V-RIESGO-1):** `LibroInventario.ExistenciasAsync` lo usan R-05 y las rutas de escritura; si el alcance se aplica ahí, el restringido ve «existencia insuficiente» falsa en almacenes permitidos. Rutas que A no listó (F-25: `diseno/detectar` y `vista-previa` ejecutan el SQL del diseñador en la principal sin reenvío). La cifra realista de E-1 completa sería ~4,1 dp, no 3,0. 15 preguntas (P-01..P-15).
- **D1 v2:** ~70 pruebas nuevas y 19 cambios al plan del 20-oct. `En_D1_la_marca_indica_sin_sello` se invierte en D3. **H-13 (Media):** el alfabeto de CS-P2 admite `------` y `--MOTIVO`; decidir si el caso exige una letra o un dígito. Bloquean la DDL rev. 3: Q-V2-02, Q-V2-03, Q-V2-08, Q-V2-09 y P-D1-06. D1-07..D1-15 de A quedan fuera (el PLAN solo trae D1-01..D1-06).
- **TT:** 95 pruebas en 8 grupos; 54 con dependencia abierta. Cinco huecos en los textos (rectificar deja el valor viejo en el historial; «nombre y documento sin comprobantes» es contradictorio entre el especialista y TT-03; el verbo del historial no está en F-2; falta dónde vive la solicitud con apoderado; `excluir` está como cadena SQL). 13 preguntas; firmar el JSON de campos y responder las 1, 2 y 9.
- **ADR-161:** ~130 casos; ni el ADR-161 ni su blueprint existen todavía (uso la propuesta y la revisión de la DDL). 11 preguntas; las principales: 409 o motivo en M-2, bitácora del SUPER, enmascarado en `rpt`, pasaportes en el 606 y e-CF.

## Lo que sigue bloqueando a C
Máquina y base del PR de la tanda de dorados (respuesta a mi plan del 22-oct); aviso de la rama de la deuda de P137/P140; avisos de cada PR de D1 (T1-1..T1-4).

Respuesta requerida: ninguna a este acuse; sí las decisiones de los documentos.
