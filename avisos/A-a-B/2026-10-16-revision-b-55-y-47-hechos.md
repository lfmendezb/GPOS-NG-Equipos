```
Para: B y C        De: A                          Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG a/dl22-bmas @ 32a594ae (PR #55); a/limpieza-firmas-bajas @ 38c4e88e (PR #47)
Estado: Cerrado por A — espera tu validación y la unión
```

# Entrega: los dos encargos de la revisión de B (`2026-10-16-revision-pr43-a-pr55`)

## 1. PR #55: el error 51616 pasa a 51617
- **Commit:** `32a594ae`, encima de `afbfdb29`, sin reescribir la historia.
- **Cambio:** `CredencialApp.ErrorSentenciaNula` = **51617**. Cambia en `CredencialApp.cs:310` y `:329`, y en `CredencialesLectura.cs:221`. El 51616 queda solo para `ErrorReversoContenida` del #48.
- **51617 libre:** lo comprobé con `git grep` en `master`, `feature/modelo-ng` y todas las ramas `a/`, `b/` y `c/` de origin. **B:** regístralo en la tabla de errores de ADR-82.
- **Verificación:**
  - `GPOS.Migracion` y `GPOS.Tests` compilan sin errores.
  - Pruebas dirigidas: `Rg14Lote2Tests` y `Rg14VerificarTests` dan 22 de 23. La que falla es `PA28_un_usuario_contenido_ajeno…`, con el 12834 (`NumeroInv` y `mod` al pasar la base a contenida en SQL 2019). Es la falla conocida del #55 cuando no está el #48. Con el #48 dio 23 de 23. No la causa este cambio.
- **C:** tu suite del #55 con el #48 corre sobre `afbfdb29`. Este commit solo cambia un número, así que no hace falta repetirla. Si ya terminó, basta con anotar el commit nuevo.

## 2. PR #47 detrás del #46
- **Rebase:** el #47 queda directamente sobre el #46 (`cd44b958`), sin los commits del #45. Fue limpio y ahora está en `38c4e88e`. Lo subí con `--force-with-lease`.
- **Base del PR:** ahora es `a/reimpresion-post`, la rama del #46. GitHub la cambia a `feature/modelo-ng` cuando se una el #46. Si prefieres que apunte a `feature/modelo-ng` desde ya, avísame.
- **Verificación:**
  - Sin el #45, compila sin errores.
  - Pruebas dirigidas, con los filtros `CandadoNoDisponibleTests`, `CandadoSistemaUnitariasTests`, `Licencia` y `Arquitectura`: 632 correctas, 0 fallidas y 1 omitida.

## Sin acción de A (espero tu decisión con el propietario)
Las bajas del #52 y el #55 se pueden construir en una tanda corta, cuando las decidas:
- **S18:** agregar `AND Inhabilitado = 0` en `ComprobarAsync`.
- **`--urgente`:** intentar el `KILL` antes de lanzar el error.
- **`ComprobarAsync`:** limitarlo a las cadenas `gpos_app_*`.
- **Nota para el instalador:** `ExigirPermisosRetiroAsync` también se aplica en `aprovisionar`.

El #48 se regenera después del 27-oct, con una marca posterior a `Uf05ForceSeek` y `Anterior` al día en `Rg14ContencionTests`. Queda en la cola de A.
