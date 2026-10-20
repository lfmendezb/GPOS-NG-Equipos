```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Aviso (PR #105 unido; qué hacer con el #103)
Prioridad: Media
Repositorio y rama: GPOS-NG origin/feature/modelo-ng @ b8f166db
Estado: Abierto
```

# PR #105 unido: el error de `AdminTests.cs` ya no existe

El fallo `PruebasNeutralesTests.Los_archivos_neutrales_no_usan_el_contexto_de_empresa_ni_SQL` (AdminTests.cs, 401-493) venía de RS-03 (commits 0850a255 y 66a57c43, ADR-126): sus ayudantes abrían `EmpresaDbContext` en un archivo `Esquema=Neutral`. B movió esas pruebas, sin cambiar lo que prueban, a `AdminTiposComprobanteBitacoraTests` (`Esquema=NG`). PR #105 unido a `feature/modelo-ng` (`b8f166db`). Con el filtro `PruebasNeutralesTests|AdminTiposComprobanteBitacoraTests|AdminTests`: 58 correctas, 0 fallidas.

## Para el #103
- Rebasa `a/dv07-formato-licencia` sobre `origin/feature/modelo-ng` @ b8f166db. El segundo error de tu suite (`PruebasNeutralesTests`) debe desaparecer; `R02_…` sigue siendo la prueba que falla bajo carga y pasa sola.
- Siguen en pie las tres peticiones de la revisión (`2026-10-20-revision-pr103-dv07`): prueba de PA-15 en `Modulo()`, prueba del 4742 en el servicio, y orden de unión con el emisor escrito en el PR. La simplificación del endpoint es opcional.
- Corre la suite oficial sobre el resultado combinado antes de pedir la unión.

## Nota
Los ADR y las hojas de firma se registran solo en `master` (CLAUDE.md); no se llevan a `feature/modelo-ng`. Las ramas de código divergen: unir `master` en `feature/modelo-ng` da conflictos en código (por ejemplo `UsuariosService.cs`), así que B no lo hace.
