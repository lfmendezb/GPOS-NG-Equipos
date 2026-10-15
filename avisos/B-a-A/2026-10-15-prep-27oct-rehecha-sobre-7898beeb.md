```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG b/prep-27oct @ 855ea392 (antes 0400b2c7, conservada en b/prep-27oct-antes-rebase-15oct)
Estado: Abierto
```

# `b/prep-27oct` rehecha sobre `7898beeb` (punta de `feature/modelo-ng`)

## Qué cambió
La rama se reconstruyó desde `7898beeb`. Ya no lleva su copia propia de #24, #26, #21 y #28: esos PR vienen ahora de la punta, en su versión unida.
1. `c0acbb15`: une `origin/b/adr118-119-ui` (T1, T2 y T4 de ADR-118/119). `NegativosTresNiveles` queda en `20261015010000`.
2. `e1786b79`: une `origin/b/ola3b` (tramo 1). `Ola3bTransferencias` queda en `20261015020000`. Se conserva la corrección de la regla de H-4 en `CK_Autorizacion_Motivo`, y `LimitesPeticiones` mantiene `Escaneos` y `Respaldos`.
3. `2ab00504`: conteos de numeración con el tipo TI (antes `cc4694de`).
4. `93496591`: #38, bancos N6-02 y N6-03 de T6 (antes `7df4f75e`).
5. `855ea392`: un solo guion acumulado, regenerado con `dotnet ef migrations script --idempotent` hasta `Ola3bTransferencias`. Respecto del guion anterior, solo suma el bloque de `Rg14RespaldoTope`.

## Regla de marcas
- La última migración unida en la punta es `Rg14RespaldoTope 20261015003000`. Las dos de la rama son posteriores.
- `has-pending-model-changes`: sin cambios.
- Los `Designer` de las dos migraciones llevan el `INCLUDE` de `UQ_CxpAplicacion`.

## Verificación
- Solución compilada sin errores.
- `GPOS.Tests --filter Categoria=Mvp`: **24/24** en `.\SQLEXPRESS` y **24/24** en `.`, con F10 incluido.
- Pruebas de migración, de la 3b y de negativos (`Migracion|Ola3b|Negativos`, con el filtro oficial): 93 correctas, 0 fallidas y 2 omitidas.
- Falta la suite oficial completa; se corre antes de la unión del 27-oct.

## Para A
- **Las ramas que partan de `b/prep-27oct` deben rebasarse sobre `855ea392`.** Esto incluye la corrección A-N2 (`FORCESEEK` en UF-05 de `TR_Documento_Emision`), cuando B la encargue.
- `a/t6-bancos` (#38) ya está dentro de la rama.
