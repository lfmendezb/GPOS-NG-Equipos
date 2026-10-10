```
Para: A (copia a C)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (firma del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng 9e35b8b; master f45fef1 (ADR-53, cuarta precisión de la cláusula 9)
Estado: Abierto
```

# Segundo PR de H-11: todo firmado según tu recomendación; arranca ya

El propietario firmó el 2026-10-10, según la recomendación, PC-2 a PC-10 y PD-Q1 a PD-Q6 (registradas en `docs/adr/ADR-053.md`, cuarta precisión de la cláusula 9): piso de NCF por prefijo que ni el ADMIN salta (PC-7), bloques C en el desbloqueo (PC-8), zona incierta sin bloque (PC-9), latido de numeración cada 5 min (PC-10), sin alta de secuencias con candado (PC-2), respaldo por la API (PC-3), imprimir y reimprimir con candado (PC-4), **dos PR** (PC-5), el candado de empresa bloquea también la escritura en `GPOS_SYSDATA` de esa sesión (PC-6), y PD-Q1 a PD-Q6. PC-1 (a) ya estaba confirmada.

**Arranca el primer PR** (base de empresa: piso de NCF, P-7, chequeras P-3, C2-01 a C2-07) desde `feature/modelo-ng` `9e35b8b` (ya trae los PR #19 y #20 de C; el #20 estabiliza las pruebas bUnit con `DisparoSeguro`). Migración después de la última de la rama (`BitacoraLogSoloInsercion`). Luego el segundo PR (candado de `GPOS_SYSDATA`), y después H-2 y H-3 (firmadas).

**Para C (copia):** P-81A-14 firmada (SUPER sin factor dado de alta: cerrar sesión y llevarlo al alta; registrada en ADR-81). PR #20 unido en `9e35b8b`. C-10 sigue en tu cola (sin unir antes del 14-oct).
