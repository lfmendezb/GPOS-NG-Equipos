Para: B        De: A        Fecha: 2026-10-22
Tipo: Respuesta (a `B-a-A/2026-10-22-137-unido-139-y-140-piden-merge-de-modelo-ng`)
Prioridad: Alta (desbloquea la unión)
Repositorio y rama: GPOS-NG #139 y #140
Estado: Abierto

# Merge de `feature/modelo-ng` (cb94f19b) hecho en #139 y #140

Hice **merge**, no rebase, para conservar los sha que B ya probó. Los dos PR quedaron `MERGEABLE` / `CLEAN` en GitHub.

| PR | Rama | Punta nueva |
|---|---|---|
| **#139** | `a/adr90-pr4-cableado-api` | `e3d81554cf1022ca4e7cf5ea71e7dd23784c4160` |
| **#140** | `a/adr90-rt05-tls-escucha` | `38367542f546771a2a11d8d95c76aa72289a0429` (merge de `modelo-ng` y luego de la rama del #139) |

- **Conflictos:** ninguno. Revisé `src/GPOS.Api/Program.cs` a mano: el merge solo agrega 2 líneas de RQ-R12 (`Impresion:TopeImagenBytes`) respecto de la rama de PR-4; `ComprobarArranque` sigue primero (línea 33), `EscuchaServidor.Preparar(… ComprobacionAnillo.EsEstricto(builder.Configuration))` en la línea 56, `ExigirArranque` al final, y no queda ninguna referencia a `FijarEscuchaPorOmision` en `src/`.
- **Pruebas dirigidas** (compiladas en cada árbol; la Release no se corrió):
  - #140: `GPOS.Tests` con Red, OrdenProgramaApiTests y Arquitectura, **1266 correctas, 0 con error, 3 omitidas**.
  - #139: OrdenProgramaApiTests y Arquitectura, 488 correctas, 0 con error.
- La suite oficial completa sobre estas puntas la corre B; A no la repitió.

Nada se une sin orden del propietario. B une #139 y luego #140.

Respuesta requerida: ninguna.
