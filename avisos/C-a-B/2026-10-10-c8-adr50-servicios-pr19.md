```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr50-servicios (22aa0b8), PR #19 hacia feature/modelo-ng
Estado: Abierto
```

# C-8: ADR-50 en cuatro servicios (PR #19)

**PR #19:** https://github.com/lfmendezb/GPOS-NG/pull/19. Se une sin conflictos con `feature/modelo-ng` `e7f1f96`. C no une.

## Qué se hizo
**Problema:** Dapper no declara el tipo de los `DateTime`. SqlClient los mandaba como `nvarchar(4000)` (nulos) o `datetime`, contra columnas `date`.

**Corrección**, con el estilo del PR #14 (`DynamicParameters` con `DbType.Date`):
- **InventarioService:** búsqueda, conteos y kárdex (saldo previo y movimientos).
- **ComprasNg:**
  - búsqueda y caja chica;
  - tasa de recepción;
  - 606, conservando `decimal(18,6)`;
  - último costo, con el ayudante nuevo `Sql.Fecha`, porque `LoteComandos` no admite `DynamicParameters`.
- **LibroBanco:** búsqueda, movimientos y solicitudes.
- **CierresCajaService:** búsqueda, y `@tipo` siempre como `char(1)`.

**Defecto real encontrado y corregido:** la búsqueda de **Cuadre de Caja** sin tipo de cierre (`CuadreCaja.razor:245`, en Web y MAUI) lanzaba en Dapper «Member 'tipo' is an ICustomQueryParameter and cannot be null». Según el código, eso terminaba en un 500 de la API; se reprodujo con el código original, pero no se probó contra la API.

## Cómo se verificó (`.\SQLEXPRESS`, filtrado)
| Conjunto | Correctas | Fallidas | Omitidas |
|---|---|---|---|
| `ParametrosTipadosServiciosTests` (nueva, 4 pruebas), antes de corregir | 0 | 4 | 0 |
| La misma, después de corregir | 4 | 0 | 0 |
| Arquitectura, clases de los cuatro servicios y consultas varchar (18 clases) | 301 | 0 | 1 (Skip ya existente) |

La compilación terminó con 0 errores y sin advertencias nuevas. No se corrió la suite completa.

## Pendiente o a decidir
- **B:** ¿se aceptan los dos estilos para fechas (`DynamicParameters` en las consultas sueltas y `Sql.Fecha` en los lotes), o se unifica?
- **QA:** confirmar en la interfaz que Cuadre de Caja busca sin error cuando no hay tipo de cierre.
- **Fuera de alcance:** `@numeros` viaja como `varchar(max)` hacia `OPENJSON`, sin compararse con ninguna columna, así que no afecta al índice.

**Siguiente para C:**
- **C-2:** sigue en curso.
- **C-9:** empieza cuando termine C-2, porque necesita la máquina sola.
- **Después:** C-10 y la precisión C-1 de ADR-81.
