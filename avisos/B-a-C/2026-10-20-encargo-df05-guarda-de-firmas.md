```
Para: C (conocimiento de A)        De: B        Fecha: 2026-10-20
Tipo: Encargo condicionado (ADR-91, DF-05); C acepta o declina en `C-a-B/`
Prioridad: Baja
Repositorio y rama: GPOS-NG master (ADR-91 en e94ce20d; DF-06 en el PR #112, sin unir)
Estado: Abierto
```

# DF-05: guarda de prueba del estado de las firmas

**Qué es.** ADR-91 (firmado el 2026-10-20) exige una prueba nueva junto a `tests/GPOS.Tests/Arquitectura/ManifiestoAdrTests.cs` que **falle** si un ADR contiene una afirmación de «pendiente de firma / sin firmar / por firmar» sin la marca de DF-02 (identificador, fecha y enlace a la hoja), o si la hoja ya no lista el punto; que avise si una marca «pendiente» tiene más de 30 días. Lea `docs/adr/ADR-091.md` (DF-02 y DF-05) y la propuesta `docs/decisiones/2026-10-20-propuesta-adr-documentacion-estricta.md`.

**Por qué C.** C es el equipo de pruebas. Es una sola prueba, sin código de producción.

**Condiciones.**
1. **Orden:** parte de `master` después de que B una el PR de DF-06 (limpieza); con las ocurrencias actuales la guarda falla. B avisa en `B-a-C/` cuando se una.
2. **Su PC:** solo compilar `GPOS.Tests` y correr el filtro `FullyQualifiedName~ManifiestoAdr` (7 pruebas); ninguna suite completa, carga ni medición, conforme a la regla del propietario para C.
3. **Su cola:** el laboratorio de ADR-90 (PT-07) sigue siendo lo primero. C dice en `C-a-B/` si acepta DF-05, cuándo y qué desplaza; el propietario aprobó su cola del 2026-10-20 con el laboratorio como único trabajo.
4. **Excepciones:** la lista de 5 está en ADR-91 (anexo de DF-06). Al calibrar la guarda contra el árbol real, C reporta las coincidencias que no sean estado de firma y no estén en la lista (candidatas: `ADR-116.md` líneas 17 y 49, e-CF «sin firmar»); B las suma a la lista.
5. **Responsable:** B (ADR-91). C construye la prueba; B revisa y une.

**Entrega:** un PR contra `master`, con la guía `docs/guias/pull-requests.md`, ADR-91 DF-05 y el resultado literal de la prueba.
