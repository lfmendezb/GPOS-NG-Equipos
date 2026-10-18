```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (firma del propietario)
Prioridad: Alta (H-2 es fiscal)
Repositorio y rama: GPOS-NG, ramas a/ desde feature/modelo-ng e7f1f96; master (ADR-11, punto 3 de las precisiones del 2026-10-10)
Estado: Abierto
```

# Encargo: H-2 y H-3 de A-3, y tanda posterior H-4, H-6 y H-7

PR #18 (A-3) y #17 (A-4) unidos en `feature/modelo-ng` `e7f1f96` (guion regenerado como `gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql`, con H-11 y `Ola4AplicacionEmision` dentro). **Toda migración nueva va después de `BitacoraLogSoloInsercion`.**

Firmado por el propietario (ADR-11, precisiones del 2026-10-10, punto 3):
1. **H-2, opción (a):** el NCF de las facturas históricas importadas se registra como **comprobante histórico** en `fiscal.Comprobante` (rol propio, sin secuencia ni rango), de modo que `NcfDocumento` lo encuentre, las devoluciones y notas lleven B04 y modifiquen ese NCF, y el índice único detecte una secuencia que se solape con números anteriores a la implantación. Arquitecto de datos de A primero (diseño, incluida la importación existente y la del DEMO), luego backend y QA, y revisión de seguridad (es fiscal). Mientras no esté, la excepción «origen sin NCF» no debe aplicarse a facturas históricas.
2. **H-3:** la importación histórica exige una fecha anterior a la de implantación y deja una línea en la bitácora por lote. Puede ir en el mismo PR o en uno pequeño aparte.
3. **Tanda posterior (después de H-2):** H-4 (la base valida también los motivos O y H), H-6 (motivo obligatorio del usuario al elegir «No generar comprobante») y H-7 (evento de seguridad por cada 422 `NO_GENERAR_SIN_PRIVILEGIO`).

**Prioridad respecto de tu cola:** el segundo PR de H-11 (P-7 y candado CR-01, con P-81A-11 y 12) sigue primero; H-2 y H-3 a continuación. Si tienes capacidad, H-2 (diseño de datos) puede avanzar en paralelo en otro árbol. Regla 9: aviso al terminar cada una.
