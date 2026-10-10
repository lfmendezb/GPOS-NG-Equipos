```
Para: B            De: C            Fecha: 2026-10-09
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #9 (a/busqueda-sin-tildes, 5319396; base 59921ba)
Estado: Abierto
```

# PR #9 (búsqueda sin tildes): Aprobado con observaciones

Responde a la primera tarea (`B-a-C/2026-10-09-bienvenida-y-primera-tarea.md`) y completa `C-a-B/2026-10-09-pr9-revision-iniciada.md`. Revisión de C con un agente de QA (Opus), sin hallazgos Críticos ni Altos. Habilita F2 y F4.

## Conforme con lo firmado
- **Regla única.** `TextoBusqueda.Clave` (Contracts) y el relleno T-SQL usan la misma tabla. Se comparó carácter por carácter: 79 = 79 y ningún par incoherente. La paridad P-2 (1.000 textos) pasa.
- **Ñ-1.** «name» no encuentra «Ñame». El CHECK rechaza «ñAME».
- **Columna e índices.** `varchar(150) BIN2_UTF8 NOT NULL` con CHECK; índice cubriente; `IX_Articulo_Referencia` filtrado. El snapshot coincide con el modelo.
- **ADR-50.** Dapper con `varchar(150)` y `varchar(20)`. En EF, `ToQueryString` da `varchar(150)`. En el plan real, la única conversión cae sobre el patrón y nunca sobre la columna.
- **Contiene por palabra.** Hasta 4 palabras, en cualquier orden. LIKE escapado (`\ % _ [`) y sin inyección.
- **Rutas de escritura.** Todas actualizan la clave: alta y edición, importación (también el MERGE) y el diagnóstico. No queda ninguna búsqueda de artículos por `Descripcion`.
- **Migración.** Idempotente: P-6 la corre dos veces y compara la huella del esquema. El relleno no genera historia ni mueve `ValidoDesde`, y el Down vuelve al esquema exacto.
- **Bloqueos.** Solo el diagnóstico toma bloqueos X sobre `cat.Articulo`, por lotes. No choca con el orden único.

## Hallazgos
| Id | Sev. | Hallazgo | Remediación |
|---|---|---|---|
| C9-00 | **Unión** | Conflicto de migraciones con el **#8**: las fechas se intercalan (`233424` < **`234501`** < `20261010000121`) y hay un rename/rename del guion de `database/empresa/` | Unir el #8 primero. Después, A rebasa el #9 y **regenera la migración** con una fecha posterior, junto con el Designer, el snapshot y el guion |
| C9-01 | Media | Con 20.000 artículos, `CatalogoArticulos` (`ConsultasMaestros.cs:38,59`) hace Clustered Index Scan más Sort y no usa `IX_Articulo_DescripcionClave`. Causas: el subselect de precio pide `UnidadVentaId`, que no está en el INCLUDE, y el `ORDER BY DescripcionClave, Codigo` impide que el TOP corte. El comentario de la línea 38 no se cumple. Probablemente no es regresión (inferido, no medido) | Medirlo en P-7, que está pendiente. Si pesa, agregar `UnidadVentaId` al INCLUDE u ordenar por `(DescripcionClave, Id)`. Corregir el comentario |
| C9-02 | Baja | El diagnóstico 3.6 (`ClavesBusquedaService`) no tiene registro en DI ni ruta: hoy solo lo usan las pruebas | Ruta y pantalla en Diagnóstico (arquitecto-software) |
| C9-03 | Baja | En una base **sin UTF-8** (CP1), una clave de 150 caracteres con Ñ mide 151 bytes y se trunca en silencio. Si el corte deja un espacio al final, el CHECK la rechaza (547). `Aprovisionamiento` admite esas bases con solo un aviso | No aplicar el esquema NG sin UTF-8, o recortar la clave a 150 bytes en C# y en T-SQL. Como mínimo, documentarlo |
| C9-04 | Baja | `SET XACT_ABORT ON` queda activo en la conexión de `Aprovisionamiento.cs:175` para los pasos siguientes. Hoy no rompe nada | Apagarlo en un `finally` o documentarlo |
| C9-05 | Baja | Cambio visible sin declarar (ADR-52): con BIN2, «Ñame» sale después de «Zanahoria» y los TOP 200, 500 y 3000 eligen filas según ese orden | Declarar qué rompe y a quién afecta, u ordenar la salida en memoria con es-DO |
| C9-06 | Baja | Faltan pruebas con tildes en `ListasPreciosService`, `OfertasService` y la hoja de conteo (verificadas con la sonda EF, sin cubrir). P-7 no se corrió. El comentario de P-4 dice «varchar UTF-8», pero el parámetro es `NVarChar`. P-8 no revisa `Servicios/**` ni `GPOS.Migracion` | Agregar las pruebas y ampliar P-8 |
| C9-07 | Info | Ø, Æ, Œ, ß, Ł y las ligaduras se vuelven espacio: «Œuf» queda «UF». Desde la quinta palabra se ignoran. Lo acepta el diseño (R-2, §3.4) | Documentarlo para el usuario |

## Pruebas (filtradas, `.\SQLEXPRESS`, filtro oficial más clases)
| Corrida | Correctas | Fallidas | Omitidas |
|---|---|---|---|
| BusquedaSinTildes, su arquitectura y TextoBusqueda | 60 | 0 | 0 |
| MigracionOla4, Ola4b, Aprovisionamiento y NumeracionQa2Otros | 41 | 0 | 0 |
| Contrato, varchar, modelo, SQL permitido, maestros, importaciones, existencias y precios | 80 | 0 | 1 (`[FactB9]`, ambiental) |
| Inventario y QA de las olas 2 y 3 | 30 | 0 | 0 |
| MigracionesTests y espacio de nombres Arquitectura | 100 | 0 | 0 |
| Web: VistaPreciosTests | 22 | 0 | 0 |
| MAUI: precios y ofertas | 6 | 0 | 0 |

Compilación sin errores. No se midió la cobertura: no se corrió la suite completa por el límite de RAM. Las bases de las sondas se borraron, el árbol de revisión quedó limpio y no hubo commits ni comentarios en GitHub.

## Recomendación de C
Se puede unir **después del #8**, con C9-00 resuelto. Antes, A corrige el comentario de C9-01. Como seguimiento: C9-03 y C9-05, que pueden exigir una decisión del propietario, y P-7 en B. **Siguiente para C: el #7.**
