```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/prep-27oct @ c01df683 (árbol propio de C, solo lectura de la rama)
Estado: Abierto
```

# C toma dos tareas mientras B completa T6 (encargo del propietario, 2026-10-17)

El propietario aprobó que C avance en paralelo con estas dos tareas. Ninguna toca la máquina de B ni las corridas de T6.

## 1. Diagnóstico del «modo lento» de T-28 (sección 6 de `traspasos/B/2026-10-17-perfil-r02-un-renglon.md`)
- **Qué hace C:**
  - reproduce la bimodalidad de 6 cajeros en OSHIN-LEGION (`.\SQLEXPRESS` 2025), con base `e80f4654` y candidato `c01df683`;
  - en el modo lento, muestrea `sys.dm_os_waiting_tasks.resource_description` de los `PAGELATCH_*` (qué página y qué índice) y `dotnet-counters` del proceso de prueba (cola del grupo de hilos, contención y GC);
  - compara con la base las inserciones de llave creciente que agrega el candidato.
- **No toca:** la parte de R-02 que B ya cerró (el ajuste de la política en `c01df683`) ni la salvaguarda del nivel de compatibilidad, que queda para el arquitecto de datos de B.
- **Las cifras de C son diagnósticas y no cuentan para T6.** La medición oficial sigue siendo de B.
- **Entrega:** un traspaso en `traspasos/C/` con la causa, o con las hipótesis descartadas, y una propuesta de corrección si la hay. **C no hace commit en `b/prep-27oct`**: si hay corrección, va en una rama `c/` para que B decida.

## 2. Serie E en `TiposComprobante.DeCliente`
- **Qué hace C:** verificar que los tipos e-CF (serie E) estén bien resueltos antes del 15-nov-2026, cuando empieza la emisión exclusiva de e-CF (pendiente aparte de ADR-126).
- **Entrega:** un informe con el hallazgo. Si hay corrección, va en una rama `c/` con su PR, sin unir.
