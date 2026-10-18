```
Para: A y C        De: B            Fecha: 2026-10-17
Tipo: Aviso (unión y firmas)
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng @ 5b47e019; master @ fe42b415
Estado: Abierto
```

# `b/prep-27oct` unida a `feature/modelo-ng` (adelantada) y hoja de B firmada

## La unión
El propietario firmó UN-01 (a) y la unión se adelantó al 2026-10-17.
- **`feature/modelo-ng` = `5b47e019`:**
  - `53e22eca` une `b/prep-27oct` (`d67f5a33`): T1 de ADR-118/119, ola 3b tramo 1, A-N2 completo, el FORCESEEK de CA-12, R-02 y `KardexCosto`;
  - `5b47e019` une el #66 (afinidad del banco).
- Es el mismo árbol que el ensayo (`5abeaf16`): suite oficial 3231/1/28, con la C-10 intermitente, que sola pasa.
- **El #66 se cerró a mano,** porque su base era `b/prep-27oct`.
- **Marcas de migración:** la última de la punta es `Uf05ForceSeek 20261015142020`. Toda migración nueva o regenerada lleva una marca posterior.

## Qué sigue (orden firmado)
Toda rama que siga se rebasa sobre `5b47e019`.
1. **#52 + #55 (A, DL-22):** rebasar y confirmar la renumeración del 51616 al 51617.
2. **#51 (C):** rebasar sobre el #55, con las pruebas de carga.
3. **#45 (A):** activación de `UseLicencia`.
4. **#48 (A, 12834):** regenerar con una marca posterior a `20261015142020`. **El #60 va con él.**
5. **#63 → #67 → #68 (A) → #57 (C) → #58 (A).** El #57 se rebasa sobre la punta que deje el #68.
- **#59 y #65 (A):** en cualquier hueco.
- **#64 (C):** ya puede reapuntarse a `feature/modelo-ng`. Lo une B.
- **C, LP-01 a LP-04:** puede empezar ahora, en una rama `c/` desde `5b47e019`.
- **C, #61:** rebasar sobre `5b47e019` y aplicar **SE-02 (a)**: un tipo E elegido a mano en contingencia se rechaza, con mensaje neutro. SE-01 (a) ya está. La medición de la ruta E la hace B al tener el rebase.
- **B:** `b/ola5-auditoria-r` con la migración regenerada.

## Firmas de la hoja de B (registradas en `master` `fe42b415`)
- **SE-01 y SE-02** (ADR-51); **CB-01** (ADR-54: nivel mínimo 130, con la vigilancia en `ComprobadorEsquemaEmpresas`, en un PR aparte).
- **RS-01** (ADR-83): no revocar llaves ni cambiar la recuperación en una instalación con sellos hasta que A haga RS-01 a RS-03, en un PR aparte detrás del #68. **OR-01:** #63 → #67 → #68 → #57 → #58.
- **BM-01:** T-28, T-57 y N6-02 se miden con `GPOST_B9_AFINIDAD=auto` en base y candidato. Los topes de la medición del 14-oct no cambian.
- **EM-01:** repositorio privado en GitHub para `GSF.EmisorLicencias`, en la cuenta del propietario y sin secretos. Lo crea el propietario, o A con su autorización expresa.
