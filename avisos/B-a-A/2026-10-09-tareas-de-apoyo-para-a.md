```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Encargo (por decisión del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG, ramas a/... desde feature/modelo-ng 59921ba
Estado: Abierto
```

# Tareas de apoyo para A

El propietario confirmó hoy a B: «a partir de este momento el equipo B será el que coordine y realice las integraciones de las ramas», «el equipo A queda como apoyo» y «reasigna tareas secundarias para A». B toma las actividades principales que llevaba A.

## Se quedan en B (camino crítico)
Meta del MVP del 60 % y su hoja de firma; T-57 del 14-oct y la meta 1 (carga pesada de SQL Server: va en el equipo nuevo); cierre de la ola 4; ADR-118/119 (T1, T2, T4); 3b y partida de `b/ola5`; `rptsis` y `GPOS.Migracion`; tanda 3 (equivalencias); ola 5. B une todo a `feature/modelo-ng` y `master`.

## Encargadas a A, en este orden
1. **Mejoras del demo, ronda 2** (`feature/mejoras-demo-ronda2` `87b90f8`, 3 commits): llevarlas sobre `feature/modelo-ng` `59921ba` en `a/mejoras-demo-ronda2`, resolver conflictos, correr las pruebas de Web afectadas y abrir PR. B decide la unión.
2. **Búsqueda sin tildes** (`a/busqueda-sin-tildes`): con ADR-50 (parámetros `varchar` con su largo; nada que impida usar el índice). Si el enfoque necesita una decisión (intercalación, columna normalizada o función), proponerla en un aviso antes de construir.
3. **Tanda de núcleo de caja** (`a/nucleo-caja`): reimpresión según UX-1 a UX-11 firmados (`traspasos/A/ux-equivalencias-reimpresion-kardex-2026-10-09.md`: «Reimprimir», «Impreso n veces», 422 `AUTORIZACION_REIMPRESION_REQUERIDA` con `DialogoAutorizacionSupervisor`, banda «COPIA», vista previa de un impreso cuenta como reimpresión) y redondeo del vuelto. Respetar el orden único de bloqueos.
4. **Hallazgos H-RV-01 y H-RV-02** (avisados por B en `avisos/B-a-A/2026-10-09-reportes-por-vertical-y-produccion.md`, área común `1aef73b`): costo de la venta del restaurante y de «Por despachar»; propina en 0 en `fiscal.Comprobante`. Diagnóstico con prueba que lo reproduzca y corrección en `a/hallazgos-rv`.

## Reglas para A como apoyo
- Ramas `a/...`, commit y push frecuentes (un apagón puede cortar en cualquier momento); PR al terminar cada tarea; **A no une**.
- Pruebas: solo las de lo que toca (filtradas). La suite completa de `GPOS.Tests`, las cargas y T-57 las corre B en el equipo nuevo antes de unir.
- Agentes con Opus; sin instaladores, servicios ni programas con ventanas.
- Un aviso en `avisos/A-a-B` por cada PR listo, con rama, commit y pruebas corridas.
- Si el propietario le pide a A otra prioridad, manda la del propietario; avisar a B.

Acuse: basta con confirmarlo en la sección de A de `estado.md`.
