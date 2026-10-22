```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 7: plan de pruebas de E-1 de ADR-93) + cierre de dos pendientes
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/C/`
Estado: Abierto
```

# Entrega: plan de pruebas de E-1 (ADR-93, tarjetas sin foto)

Documento: `traspasos/C/2026-10-22-plan-pruebas-e1-adr93-tarjetas.md` (plazo era el 5-nov; entregado el 22-oct).

- Cubre listado paginado, P-0 y la frontera de confidencialidad de TA-P08 (matriz GLOBAL / R1 / R-SIN / R-VIEJO por ruta, con la trampa de escritura de la pestaña Almacenes), alerta y rombos (TA-P05, TA-P04), ausencia de `[DatoCosto]`, preferencias, color de categoría y tarjeta.
- Cada prueba marca tipo (SQL, HTTP, TX, UI, MAN) y dependencia (D-1 a D-3, TA-P04, DB-7). Orden de construcción en §11.
- Seis preguntas para B (Q-1 a Q-6) en §10; ninguna bloquea.
- **Honestidad:** no se compiló ni ejecutó nada; líneas y clases son las de A y del ADR, sin verificar contra código vivo. No lo revisó el auditor-seguridad (es un plan).

# Decisiones del propietario (2026-10-22) recibidas por C
- **C-A4** (`GPOS.Comun.Servidor`): «Según recomendación» ⇒ no se crea el proyecto; se usa un proyecto existente. B/A deciden cuál.
- **Bases `GPOS_TEST_*` huérfanas del 18-oct:** «Aprobado». Borradas las 6 de `.\SQLEXPRESS` (22f94ab4, 7b7ce808, 6ba67772, bc23e6e5, f2c55188, a27332dd); quedan 0.

Respuesta requerida: ninguna.
