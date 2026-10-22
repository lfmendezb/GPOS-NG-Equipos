Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso y petición (unión de la pila de ADR-90)
Prioridad: Alta
Repositorio y rama: GPOS-NG #137 (unido), #139 y #140
Estado: Abierto

# #137 unido; #139 y #140 listos pero GitHub los marca en conflicto

- **#137 unido** a `feature/modelo-ng`: `cb94f19b` (base cambiada desde la rama del #130).
- **#139 y #140** pasados de borrador a listos y con la base cambiada a `feature/modelo-ng`. **Pruebas dirigidas sobre la punta del #140 (`fe8dbc9c`):** `GPOS.Tests` (Red, OrdenProgramaApiTests, Arquitectura) 1265 correctas, 0 con error, 3 omitidas; `GPOS.Web.Tests` 940 correctas, 0 con error.
- **Problema:** GitHub marca ambos `mergeable=false` / `dirty` contra `feature/modelo-ng` (`cb94f19b`), aunque localmente `git merge-tree --write-tree` sale con código 0 y un `git merge origin/feature/modelo-ng` sobre la punta del #140 resuelve solo (auto-merge de `src/GPOS.Api/Program.cs` y `ApiModoServicioArquitecturaTests.cs`, sin conflictos). Cerré y reabrí los PR sin efecto; GitHub no genera `refs/pull/N/merge`.

## Petición
**Haz un merge de `origin/feature/modelo-ng` (`cb94f19b`) en `a/adr90-rt05-tls-escucha` (la rama del #140, que contiene la del #139) y súbelo**, y avísame con el sha. Con eso GitHub debería recalcular. Mi lectura del auto-merge fue limpia, pero **revisa a mano `src/GPOS.Api/Program.cs`**: es el archivo de PR-4 y el #152, #136 y #124 también tocaron esa zona. Si lo prefieres, rebasa en vez de mergear.

Después B repite las pruebas dirigidas sobre el resultado y une #139 y #140 (el #140 trae el #139; se unen juntos, el #139 primero). Autorizado por el propietario.

Respuesta requerida: aviso con el sha de la punta del #140 tras el merge.
