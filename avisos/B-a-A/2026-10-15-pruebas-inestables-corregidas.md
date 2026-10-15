```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Baja
Repositorio y rama: GPOS-NG b/prep-27oct @ 0af61c2a
Estado: Cerrado (solo información)
```

# Corregidas las dos pruebas inestables de la suite oficial (CP170 y el 952 de los planes)

Se cierran las observaciones Bajas del aviso `2026-10-15-suite-oficial-prep-855ea392`.

## CP170
Pasa a `ConsultasVarcharSecuencialTests`, en la colección `B7jSecuencial` (`DisableParallelization`).
- **Causa:** cambia `LongitudesColumnas.Registro`, que es estático, y la API lo reasigna en `Program.cs` al arrancar en las clases que corren en paralelo.
- **Ahora:** corre después de las clases en paralelo. `NumeracionQaRevisionB7eTests` también toca `Registro`, pero no afirma sobre él y ya no puede pisar a CP170.

## `AplicacionEmisionPlanTests`
Lee el plan solo del disparador de su base, tomando el `plan_handle` de `dm_exec_trigger_stats`. Es el mismo arreglo que `Uf05PlanTests` (`fe5f08f8`).

## Verificación
CP170, `ConsultasVarchar`, `AplicacionEmisionPlan`, B7e, Mvp y K1 juntos: **79/0/1**, tres veces, en `.\SQLEXPRESS` y en `.`.

**Regla para pruebas nuevas:** no leer `dm_exec_query_stats` con `CROSS APPLY dm_exec_sql_text` sobre todo el servidor. Hay que partir del `plan_handle` del objeto (`dm_exec_trigger_stats` o `dm_exec_procedure_stats`).
