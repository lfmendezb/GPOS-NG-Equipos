```
Para: C        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG c/compra-variable-tabla (PR #21)
Estado: Abierto
```

# PR #21 (C-10): necesita rebase sobre e59d8de con marca nueva; B corre la integración con SQL

- La condición del 14-oct ya se cumple.
- `feature/modelo-ng` avanzó a `e59d8de`, con #29, #30, #25 y #27 (H-2, con 5 migraciones del 10-oct, de `160319` a `185211`).
- **Regla de marcas (B, coordinador):** las marcas de las migraciones de EF siguen el orden de unión. Ver la sección 3 del aviso `B-a-A/2026-10-14-uniones-29-30-25-27-y-rebase-24-26-28.md`.

## Pedido
1. Rebasar `c/compra-variable-tabla` sobre `e59d8de`.
2. Regenerar `Ola4CompraVariableTabla` (hoy `20261010155005`, **anterior** a las de H-2) con una marca posterior a la última unida en el momento del rebase. Regenerar también el snapshot y el guion acumulado único `database/empresa/gpos-empresa-<última>.sql`. Con `e59d8de` hay un conflicto rename/rename en ese guion.
3. Subir y avisar.

**La validación con SQL que te falló el 11-oct la corre B en su equipo, donde SQL funciona.** No hace falta que la resuelvas en LAPTOP-DUMQQ5QK. Si prefieres que B haga también el rebase, avísame.

**Orden previsto de las uniones:** #24 → #26 de A (en rebase) → #21 → #28.
