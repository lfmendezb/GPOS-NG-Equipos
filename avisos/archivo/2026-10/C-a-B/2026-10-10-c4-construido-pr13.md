```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/dm04-autoclose (fe2124e), PR #13 hacia feature/modelo-ng
Estado: Abierto
```

# C-4 construido: AUTO_CLOSE OFF en el aprovisionamiento (PR #13)

Completa `C-a-B/2026-10-10-c4-propuesta-autoclose-y-memoria.md`. **PR #13:** https://github.com/lfmendezb/GPOS-NG/pull/13. Se une sin conflictos con `feature/modelo-ng` `ce51c10`. C no une.

## Qué hace
- **`OpcionesBase.AsegurarAsync`** (`Infraestructura/Motor`): lote idempotente que solo emite el `ALTER DATABASE … WITH NO_WAIT` de lo que falta: AUTO_CLOSE OFF, AUTO_SHRINK OFF y PAGE_VERIFY CHECKSUM. Usa el error **51990** si la base no existe; se buscó en todas las ramas y está libre.
- **`Aprovisionamiento`:**
  - `FijarOpcionesAsync` lo llama, así que cubre `crear` y `actualizar`;
  - **DM-03:** fija las opciones antes de leer la intercalación y la lee conectado a la propia base, en `ActualizarAsync` y en `CrearAsync`;
  - `verificar` informa AUTO_CLOSE sin cambiar el código de salida.
- **`EsquemaEmpresa.CrearBaseAsync`:** fija las opciones solo si acaba de crear la base.
- **`GPOS_SYSDATA`:** se corrige al iniciar la API. Si falta el permiso (5011), queda un aviso en el log y la API arranca igual (D-C4-02).

## Pruebas (filtradas, `.\SQLEXPRESS`)
| Conjunto | Correctas | Fallidas | Omitidas |
|---|---|---|---|
| `OpcionesBaseTests` (8 casos en 9 pruebas) | 9 | 0 | 0 |
| Aprovisionamiento, versión de esquema, migraciones, arquitectura y claves iniciales | 143 | 0 | 0 |
| Pruebas que arrancan la API | 52 | 0 | 0 |

No hay advertencias nuevas y no se corrió la suite completa.

## Desviaciones de la especificación (sección 7.6 del documento)
- El aviso de la API no contiene el texto «ALTER DATABASE», porque `SqlSoloEnLugaresPermitidosTests` lo marca como DDL en `GPOS.Api`.
- La prueba 7 lleva el rasgo NG, porque necesita SQL.
- La prueba 8 se reforzó.

## Riesgos para QA
- Un 5061 por `NO_WAIT` detiene el arranque de la API; solo el 5011 se trata como aviso.
- El aviso sin permiso no se probó con un login real sin ALTER sobre `GPOS_SYSDATA`; se probó con `EXECUTE AS USER`.
- Una base restaurada desde un respaldo anterior vuelve con AUTO_CLOSE ON hasta el siguiente `actualizar`; `verificar` lo informa.

## Al unir
- **Firmas pendientes:** D-C4-01 a 03 y D-MEM-01 a 03 (se aplicaron según la recomendación).
- **Paquete del DEMO (PR #12):** cuando se una el #13, se puede retirar la mitigación temporal de DM-04 de `Comun-Demo.ps1`.

## Estado del encargo C-1 a C-4
| Tarea | Estado |
|---|---|
| C-1 | PR #12 |
| C-3 | Entregado; P-81A-01 a 10 para firma |
| C-4 | PR #13 |
| C-2 | Espera el PR de H-11 de A |

C queda sin agentes activos.
