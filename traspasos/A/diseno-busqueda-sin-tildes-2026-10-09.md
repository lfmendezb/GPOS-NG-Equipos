# Blueprint de datos: búsqueda de artículos sin tildes en el núcleo (PA-D-07)

**Fecha:** 2026-10-09 · **Autor:** arquitecto-datos (equipo A) · **Estado de la decisión:** Pendiente de firma del propietario
**Alcance:** núcleo de A, entrega 1, todas las verticales. Va **después** de la migración `20261009022600_Ola4FactorUnidad`.
**Fuentes:** árbol `GPOS-NG-numeracion` (commit `7302d9d`), diseño de B `origin/b/farmacia-principio-activo:docs/datos/2026-10-08-farmacia-principio-activo.md` (§3.2, §4.3, PA-D-07), respuestas del propietario `…/docs/decisiones/2026-10-08-respuestas-propietario-farmacia.md:11`, mediciones V-04 de `docs/datos/2026-10-04-h0-modelo-datos-entrega1.md:302-320`.

## 0. Resumen

| Tema | Decisión propuesta | Requiere firma |
|---|---|---|
| Técnica | Clave normalizada **calculada en C#** (`TextoBusqueda.Clave`) y **guardada al grabar** en `cat.Articulo.DescripcionClave`; la misma función que B usa en Farmacia | Sí (ratifica DC-2 de B para el núcleo) |
| Dónde vive la función | `GPOS.Contracts` (no `GPOS.Core`): la usan también los filtros en memoria de `GPOS.Web` | No (técnica); aviso a B |
| Regla | Mayúsculas, sin tildes ni diéresis (tabla **cerrada** compartida C#/SQL), todo lo que no sea `A-Z`, `0-9` o `Ñ` → espacio, espacios colapsados y recortados | Sí, por la ñ |
| La ñ | **Recomendado: Ñ-1, no igualar ñ con n** (`ÑAME` ≠ `NAME`, `AÑO` ≠ `ANO`). Alternativas: Ñ-2 asimétrica («n» encuentra n y ñ; «ñ» solo ñ) y Ñ-3 igualar (lo que hace hoy el diseño de B) | **Sí** |
| Columna | `DescripcionClave varchar(150) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL` + `CK_Articulo_DescripcionClave` (forma) | Incluido en la firma |
| Índice | `IX_Articulo_DescripcionClave (DescripcionClave) INCLUDE (Codigo, Descripcion, Referencia, Inhabilitado)`; **sustituye** a `IX_Articulo_Descripcion` | No |
| Semántica de la búsqueda | «Contiene» **por palabra** sobre la clave (cada palabra escrita debe aparecer; AND); códigos, referencia y códigos alternos siguen con «contiene» literal como hoy | Sí (cambio visible menor: «leche entera» encuentra «Leche UHT Entera») |
| Escáner | **No cambia**: igualdad exacta sobre `Codigo`, `cat.ArticuloCodigo.Codigo` y `Referencia` (`CatalogoService.cs:153-161`) | No |
| Sincronización (ADR-53) | La clave viaja como dato con el artículo (catálogo de solo central); el nodo y SQLite nunca la recalculan | No |
| Migración | `Ola4BusquedaSinTildes`: columna, relleno en T-SQL con la misma tabla cerrada **sin generar historia temporal**, `NOT NULL`, `CHECK`, índice; `Down` completo | No |
| Esfuerzo | **≈ 0,5 sp** (0,4 a 0,7; inferido). B estimó 0,2 sp solo para la columna | — |
| Riesgo principal | Que algún camino de escritura no actualice la clave → se evita poniéndola en el *setter* del dominio + `CHECK` de forma + diagnóstico | — |

---

## 1. Contexto y modelo de tenencia aplicado

### 1.1 Lo verificado

| # | Hecho | Evidencia |
|---|---|---|
| V-1 | Intercalación de las bases de empresa: `Latin1_General_100_CI_AS_SC_UTF8` → **insensible a mayúsculas, sensible a tildes**. «cafe» no encuentra «Café»; «CAFE» sí encuentra «cafe» | `src/GPOS.Migracion/Aprovisionamiento.cs:45`, `:62` |
| V-2 | Texto `varchar` por convención (ADR-50); todo `LIKE` lleva parámetro `varchar` del largo de la columna (`LargoBusqueda = 150`) | `src/GPOS.Core/Datos/Empresa/EmpresaNgDbContext.cs:172-175`; `src/GPOS.Core/Consultas/Maestros/ConsultasMaestros.cs:8`, `:13` |
| V-3 | `cat.Articulo`: `Codigo varchar(20)` con `UQ_Articulo_Codigo`; `Descripcion varchar(150)` con `IX_Articulo_Descripcion (Descripcion) INCLUDE (Codigo, Inhabilitado)`; `Referencia varchar(30)` **sin índice**; tabla temporal (`cat.ArticuloHistorial`), disparadores `TR_Articulo_Codigo` y `TR_Articulo_UnidadBase` (este último de Ola4FactorUnidad) | `src/GPOS.Core/Datos/Empresa/Configuracion/MaeConfiguracion.cs:125-150` |
| V-4 | `cat.ArticuloCodigo` (barras, PLU, suplidor): PK `Codigo varchar(30)`, `IX_ArticuloCodigo_Articulo` | `MaeConfiguracion.cs:204-213` |
| V-5 | **No hay columna «nombre comercial» aparte**: el nombre comercial es `Descripcion` (así lo trata B en Farmacia). `DescripcionCorta varchar(40)` no se busca hoy | `src/GPOS.Core/Dominio/Maestros/Articulo.cs:18-20`; diseño de B, PA-D-07 |
| V-6 | **Escáner del POS y de documentos:** `GET api/catalogos/articulos/{codigo}/linea` → `CatalogoService.ArticuloLineaAsync` → `ArticuloAsync`: igualdad `Codigo = c`, luego `ArticuloCodigo.Codigo = c`, luego `Referencia = c` | `src/GPOS.Api/Endpoints/DocumentosEndpoints.cs:41-44`; `src/GPOS.Core/Servicios/CatalogoService.cs:153-161`, `:185` |
| V-7 | **Búsqueda F3 del POS, documentos e inventario:** `DialogoBuscarArticulo` (busca mientras se escribe, 300 ms de espera) → `Catalogo.Articulos` → `ConsultasMaestros.CatalogoArticulos`: `TOP 200`, `LIKE '%'+@texto+'%'` sobre `Codigo`, `Descripcion`, `Referencia` y `EXISTS` sobre `ArticuloCodigo.Codigo`, `ORDER BY a.Descripcion` | `src/GPOS.Web/Components/Compartidos/DialogoBuscarArticulo.razor:6-7`, `:41`; `CatalogoService.cs:115-117`; `ConsultasMaestros.cs:37-49` |
| V-8 | Otras búsquedas de artículos con «contiene» sensible a tildes: Existencias (SQL), maestro de artículos, inventario, listas de precios y ofertas (EF `Contains`) y la vista de precios (en memoria, `OrdinalIgnoreCase`) | `src/GPOS.Core/Consultas/Inventario/ConsultasDocInventario.cs:85-86`; `src/GPOS.Core/Servicios/MaestrosService.Articulos.cs:38-39`; `InventarioService.cs:344`; `ListasPreciosService.cs:83`; `OfertasService.cs:34`; `src/GPOS.Web/Servicios/VistaPrecios.cs:97-98` |
| V-9 | Todas las escrituras de `cat.Articulo.Descripcion` pasan por la entidad de EF (alta/edición y las dos rutas de importación); `ComandosImportacion` solo inserta en `ArticuloUnidad` y `ArticuloCodigo` con SQL | `MaestrosService.Articulos.cs:317`; `src/GPOS.Core/Servicios/Importacion/ImportacionMaestros.cs:390`, `:531`; `src/GPOS.Core/Consultas/Maestros/ComandosImportacion.cs:256`, `:269` |
| V-10 | `Articulo`, `ArticuloCodigo` y `ArticuloUnidad` son `ISoloCentral` (no se editan en un nodo; bajan por la réplica) | `src/GPOS.Core/Dominio/Maestros/Articulo.cs:15`, `:93` |
| V-11 | Ningún `GPOS.Web` referencia a `GPOS.Core`: solo a `GPOS.Contracts` | `src/GPOS.Web/GPOS.Web.csproj:4` |
| V-12 | **«E11» es la búsqueda de documentos por número**, no de artículos: no tiene texto con tildes y queda **fuera** de este diseño | `src/GPOS.Core/Infraestructura/Numeracion/BusquedaNumero.cs:4`; `PosService.cs:546` |
| V-13 | Medición V-04 con 50.003 artículos: `LIKE 'prefijo%'` con `varchar(150)` busca en 4 lecturas; el «contiene» recorre el índice (≈ 368 páginas, ≈ 3 ms inferido) | `docs/datos/2026-10-04-h0-modelo-datos-entrega1.md:306-319` |
| V-14 | B propone `TextoBusqueda.Clave` en `GPOS.Core` con NFD + quitar marcas `Mn` (**la ñ queda en N**) y `CHECK` con `Latin1_General_100_BIN2_UTF8 NOT LIKE '%[^A-Z0-9 ]%'` | diseño de B §3.2 (líneas 202-216) |

### 1.2 Tenencia

Base por empresa (ADR-52): la columna y el índice viven en `cat.Articulo` de cada base de empresa, sin columna de tenant; el aislamiento lo da la base. No hay datos compartidos entre empresas.

### 1.3 Lo que busca hoy cada pantalla

| Pantalla / ruta | Campos | Forma | Sensible a tildes | Ruta caliente |
|---|---|---|---|---|
| Escáner (POS, facturas, compras, inventario) | `Codigo`, `ArticuloCodigo.Codigo`, `Referencia` | Igualdad | No aplica (códigos) | **Sí**: una petición por línea |
| F3 / diálogo de búsqueda (POS y documentos) | `Codigo`, `Descripcion`, `Referencia`, `ArticuloCodigo.Codigo` | `LIKE '%x%'` | Sí, en `Descripcion` | Media: lo pide el cajero, varias veces por búsqueda (300 ms) |
| Existencias | `Codigo`, `Descripcion`, `ArticuloCodigo.Codigo` | `LIKE '%x%'` | Sí | No |
| Maestro de artículos, inventario, listas de precios, ofertas | `Codigo`, `Descripcion` (+ `Referencia`, códigos en el maestro) | EF `Contains` → `LIKE '%x%'` | Sí | No |
| Vista de precios (Web, en memoria) | código y descripción del renglón | `Contains(OrdinalIgnoreCase)` | Sí | No |

---

## 2. Alternativas evaluadas

| Opción | Cómo | Rendimiento (50.000 art.) | Sincronización / SQLite | Misma clave C# y SQL | Farmacia | Esfuerzo | Veredicto |
|---|---|---|---|---|---|---|---|
| **A. Clave en C# guardada al grabar (recomendada)** | `DescripcionClave` escrita por el dominio; `CHECK` de forma; índice cubriente en intercalación binaria | Igual o mejor que hoy: mismo recorrido de un índice estrecho, pero comparación **binaria** en lugar de lingüística UTF-8 (de 3 a 8 veces menos CPU por fila, **inferido**); `TOP 200` en el orden del índice corta temprano cuando hay muchas coincidencias | Viaja como dato; el nodo SQL Server y SQLite solo comparan bytes en mayúsculas | **Sí**, por construcción (misma función; prueba de paridad con la expresión T-SQL del relleno) | La misma función que `far.PrincipioNombre.NombreClave`: una sola regla en todo el producto | ≈ 0,5 sp | **Sí** |
| B. `COLLATE …_CI_AI` en la consulta | `a.Descripcion COLLATE Modern_Spanish_100_CI_AI_SC_UTF8 LIKE '%'+@t+'%'` | Recorrido con comparación lingüística insensible a tildes: algo **más** cara que hoy (inferido); sin índice útil | No existe en SQLite; cada filtro en memoria necesitaría su propia regla | **No**: la base iguala y la aplicación no | Distinta de la de B: «5-aminosalicílico» ≠ «5 aminosalicilico» | 0,1 sp | No. Solo como plan de contingencia si el propietario no quiere cambio de esquema en la entrega 1 |
| C. Columna calculada persistida con `COLLATE …_CI_AI` | `DescripcionAI AS Descripcion COLLATE … PERSISTED` + índice | Como A en lecturas, pero comparación lingüística | La columna calculada no viaja: SQLite tendría otra regla | No | No trata signos ni guiones | 0,2 sp + complejidad de la tabla temporal | No |
| C′. Columna calculada con función escalar T-SQL idéntica a la de C# | `PERSISTED` con UDF `SCHEMABINDING` | Una UDF escalar en una columna calculada **impide planes paralelos** en las consultas sobre la tabla (inferido, comportamiento conocido del motor; la integración de UDF de 2019 no aplica a columnas calculadas) | Igual que C | Sí | Sí | 0,3 sp | No: castiga reportes sobre `cat.Articulo` |
| D. Texto completo | `CONTAINS` con `ACCENT_SENSITIVITY = OFF` | Bajo por consulta | Población asíncrona, componente aparte en cada instancia y nodo, no existe en SQLite | No | — | 0,5 sp + operación | No (mismo motivo que B en §4.3) |

**Ñ con intercalaciones (para la opción B):** en `Latin1_General_*_AI` la ñ se compara igual que la n (inferido); en `Modern_Spanish_*_AI` la ñ es letra propia y no se iguala (inferido). Verificar con `sys.fn_helpcollations()` y una prueba si alguna vez se usa B.

---

## 3. Diseño recomendado

### 3.1 Regla de normalización (una sola, compartida)

`TextoBusqueda.Clave(string? texto) → string` en **`GPOS.Contracts`** (función pura, sin dependencias). Pasos, en este orden:

1. `null` → `""`.
2. Mayúsculas invariantes (`ToUpperInvariant`; en T-SQL, `UPPER` con la intercalación de la base).
3. Sustitución por **tabla cerrada** (constantes públicas `TextoBusqueda.ConMarca` / `TextoBusqueda.SinMarca`, las mismas que usa el relleno T-SQL con `TRANSLATE`):
   `ÁÀÂÄÃÅ→A`, `ÉÈÊË→E`, `ÍÌÎÏ→I`, `ÓÒÔÖÕ→O`, `ÚÙÛÜ→U`, `Ç→C`, `ÝŸ→Y`. **La Ñ no está en la tabla** (opción Ñ-1).
4. Todo carácter fuera de `A-Z`, `0-9`, `Ñ` → espacio.
5. Colapsar espacios repetidos y recortar.

Ejemplos: «Café» / «cafe» / «CAFÉ» → `CAFE`; «Ñame» → `ÑAME`; «Pingüino» → `PINGUINO`; «Coca-Cola 2L» → `COCA COLA 2L`; «Jamón «Serrano» ½ lb» → `JAMON SERRANO LB`; «***» → `""`.

**Por qué tabla cerrada y no NFD (cambio frente al diseño de B):** con NFD, C# quita marcas de cientos de letras (Ş, Ő, Ł…) que un `TRANSLATE` en T-SQL no cubre; con una tabla cerrada, C# y SQL dan **exactamente** la misma clave, lo que permite rellenar en la migración y probar la paridad. Las letras fuera de la tabla se vuelven espacio en los dos lados (en el mercado dominicano no aparecen en descripciones de artículos; inferido). La tabla se amplía si hace falta, junto con el diagnóstico (3.6).

**Ñ (requiere firma):**

| Opción | Efecto | Recomendación |
|---|---|---|
| **Ñ-1. No igualar** | La clave conserva `Ñ`. «ñame» encuentra «Ñame»; «name» **no** encuentra «Ñame»; «ano» no encuentra «Año» | **Recomendada**: la ñ es letra del español, no tilde; evita falsos positivos (AÑO/ANO, PEÑA/PENA, CAÑA/CANA) |
| Ñ-2. Asimétrica | Clave con `Ñ`; al buscar, cada `N` escrita se convierte en `[NÑ]` en el patrón (`PI[NÑ]A`). «pina» encuentra «Piña» y «Pina»; «piña» solo «Piña» | Alternativa si en los POS hay teclados sin ñ (teclado inglés). +0,05 sp. El patrón deja de ser literal: hay que generar el `LIKE` con cuidado y en SQLite usar `GLOB` |
| Ñ-3. Igualar | `Ñ → N` en la clave (lo que hace hoy NFD en el diseño de B) | No recomendada |

La decisión **alcanza también a Farmacia** (B, prueba P-F03 con «Ñ»): una sola regla para todo el producto.

### 3.2 Columna y restricción

```sql
-- cat.Articulo (y la misma columna, sin CHECK, en cat.ArticuloHistorial)
DescripcionClave varchar(150) COLLATE Latin1_General_100_BIN2_UTF8 NOT NULL

CONSTRAINT CK_Articulo_DescripcionClave CHECK (
    DescripcionClave NOT LIKE '%[^A-Z0-9 Ñ]%'          -- solo mayúsculas sin tilde, dígitos, Ñ y espacio (Ñ-1/Ñ-2)
    AND CHARINDEX('  ', DescripcionClave) = 0          -- sin espacios dobles
    AND DATALENGTH(DescripcionClave) = DATALENGTH(LTRIM(RTRIM(DescripcionClave))))  -- sin espacios al borde
```

- **Largo:** la clave nunca es más larga que `Descripcion` en bytes (una vocal con tilde ocupa 2 bytes en UTF-8 y queda en 1; la Ñ sigue en 2; los signos se vuelven un espacio y se colapsan). `varchar(150)` basta.
- **Intercalación binaria en la columna:** la clave ya está normalizada, así que la comparación binaria es exacta y la más barata. La consulta compara contra parámetros `varchar`: el parámetro toma la intercalación de la columna (precedencia implícita), sin `COLLATE` en el SQL. **Cuidado (H-08, punto 7):** si algún día se compara esta columna con una columna de una tabla temporal (`CargaMasiva`), declarar ahí la misma intercalación; hoy no hay tal comparación.
- **Clave vacía permitida** (descripciones solo con signos); el artículo se encuentra por código.
- Con Ñ-3 el `CHECK` queda `'%[^A-Z0-9 ]%'`, como el de B.
- **Verificar en la prueba P-4** que la clase `[^A-Z0-9 Ñ]` con `BIN2_UTF8` trata `Ñ` (2 bytes) como un carácter (inferido; documentado para UTF-8 pero no medido aquí).

### 3.3 Quién escribe la clave

- **En el dominio**, no en cada servicio: `Articulo.Descripcion` con *setter* que asigna `DescripcionClave = TextoBusqueda.Clave(value)`; `DescripcionClave` con *setter* privado. EF materializa por el campo de respaldo, así que leer no recalcula. Cubre alta, edición y las dos rutas de importación (V-9) sin tocarlas.
- Prueba de arquitectura: ningún SQL propio (`Consultas/**`, `Migraciones/Sql*.cs`) hace `INSERT`/`UPDATE` de `cat.Articulo` con `Descripcion` sin `DescripcionClave`.
- En un nodo nunca se escribe (V-10).

### 3.4 Consultas

**F3 / `CatalogoArticulos` (sustituye `ConsultasMaestros.cs:38-49`):**

```sql
-- @texto varchar(150): el texto tal cual, con %, _ y [ escapados (para códigos)
-- @p1..@p4 varchar(150): las palabras de TextoBusqueda.Clave(@texto) (las que falten, NULL; más de 4 se ignoran)
SELECT TOP (200) a.Codigo, a.Descripcion, (…precio, sin cambios…) AS Precio
  FROM cat.Articulo a
 WHERE a.Inhabilitado = 0
   AND (@texto IS NULL
        OR (@p1 IS NOT NULL
            AND a.DescripcionClave LIKE '%' + @p1 + '%'
            AND (@p2 IS NULL OR a.DescripcionClave LIKE '%' + @p2 + '%')
            AND (@p3 IS NULL OR a.DescripcionClave LIKE '%' + @p3 + '%')
            AND (@p4 IS NULL OR a.DescripcionClave LIKE '%' + @p4 + '%'))
        OR a.Codigo LIKE '%' + @texto + '%' ESCAPE '\'
        OR a.Referencia LIKE '%' + @texto + '%' ESCAPE '\'
        OR EXISTS (SELECT 1 FROM cat.ArticuloCodigo x WHERE x.ArticuloId = a.Id AND x.Codigo LIKE '%' + @texto + '%' ESCAPE '\'))
 ORDER BY a.DescripcionClave, a.Codigo
```

- Las palabras no necesitan escape: la clave solo admite `A-Z`, `0-9`, `Ñ` y espacio. Con Ñ-2 se generan con `[NÑ]`.
- **Hoy los comodines no se escapan** (`ConsultasMaestros.cs:46`): «50%» busca «50» seguido de cualquier cosa. Se corrige de paso con el `EscaparLike` de la búsqueda por número.
- `ORDER BY DescripcionClave` en lugar de `Descripcion`: mismo orden para el usuario salvo tildes (que ahora ordenan con su vocal) y permite que `TOP 200` recorra el índice en orden y pare al llegar a 200.
- **Mismo patrón** en `ConsultasDocInventario.Existencias` (`:85-86`). En EF (maestro, inventario, listas de precios, ofertas): `a.DescripcionClave.Contains(p1) && …` con las palabras ya normalizadas; el backend confirma en el SQL generado que el parámetro sale `varchar(150)` y como `LIKE` (si EF lo traduce a `CHARINDEX`, el costo es el mismo: recorrido). En `VistaPrecios` (Web): `TextoBusqueda.Clave(descripcion).Contains(palabra, Ordinal)` por palabra.

**Prefijo frente a «contiene»:**

| Forma | Lecturas (50.000 art., inferido de V-04) | Encuentra | Uso |
|---|---|---|---|
| `DescripcionClave LIKE @p1 + '%'` | 3 a 4 (búsqueda en el índice) | Solo si la descripción **empieza** por la palabra | Se descarta como forma única: hoy el usuario escribe «entera» y encuentra «Leche entera» |
| `LIKE '%' + @p + '%'` por palabra (**recomendada**) | Recorrido del índice: ≈ 600 a 700 páginas sin coincidencias (≈ 5 MB en caché); termina antes si hay ≥ 200 coincidencias | Igual que hoy y además en cualquier orden de palabras | F3 y pantallas |
| `' ' + clave LIKE '% ' + @p + '%'` (comienzo de palabra, el paso 3 de B) | Igual que la anterior | Menos ruido («COLA» no encuentra «ESCOLAR») | Alternativa si el ruido molesta; cambio de una línea |

El costo dominante del «contiene» **ya existe hoy** (V-13) y además lo arrastra el `EXISTS` sobre 250.000 códigos alternos (hasta ≈ 1.000 páginas si el plan elige recorrerlos; no medido). Este diseño no lo empeora: cambia la comparación de lingüística a binaria. La medición P-7 confirma.

### 3.5 Escáner

**No cambia.** `ArticuloAsync` sigue con igualdades sobre el código escaneado **sin normalizar** (ceros a la izquierda, guiones y mayúsculas del código son significativos). La clave nunca participa en la lectura por código. Prueba de no regresión P-3d.

### 3.6 Diagnóstico de claves

Comando de solo lectura (SUPER/ADMIN, en Diagnóstico; el mismo que propone B §7.4, ampliado a `cat.Articulo`): recalcula `TextoBusqueda.Clave(Descripcion)` en C#, lista diferencias y, con confirmación, las corrige en lotes de 1.000 con `SYSTEM_VERSIONING` apagado (ver 7). Sirve si cambia la regla (p. ej., otra decisión sobre la ñ).

---

## 4. Índices y consultas que los justifican

| Índice | Consultas | Costo de escritura | Tamaño (50.000 art., inferido) |
|---|---|---|---|
| **`IX_Articulo_DescripcionClave (DescripcionClave) INCLUDE (Codigo, Descripcion, Referencia, Inhabilitado)`** (nuevo) | `CatalogoArticulos` (F3), `Existencias`, maestro de artículos, inventario, listas de precios y ofertas; el orden de las listas sin filtro (`OrderBy` de `MaestrosService.Articulos.cs:42`, que pasa a `DescripcionClave`) | Una entrada por alta y por cambio de descripción, código o referencia; solo mantenimiento del catálogo, **nunca la venta** | ≈ 120 bytes/fila → ≈ 6 MB (≈ 750 páginas) |
| `IX_Articulo_Descripcion` (existente) | **Se elimina** si el backend confirma que ninguna consulta ordena o filtra por `Descripcion` tras el cambio (grep de `ORDER BY a.Descripcion` y `OrderBy(a => a.Descripcion)`) | −1 entrada por escritura | −≈ 3 MB |

Neto: ≈ +3 MB por cada 50.000 artículos; costo en hosting despreciable (< 0,01 USD/mes; inferido). No se crean índices de prefijo aparte ni sobre `DescripcionCorta`.

**Hallazgo lateral (Media, fuera del alcance de PA-D-07):** el tercer paso del escáner (`Referencia = c`, `CatalogoService.cs:160`) no tiene índice: cuando un código escaneado no existe (artículo sin barras registradas), recorre `cat.Articulo` agrupada, **en la ruta caliente**. Propuesta: `IX_Articulo_Referencia (Referencia) WHERE Referencia IS NOT NULL`, de 1 a 2 MB. Confirmar con un plan real antes (no medido). Se puede incluir en la misma migración si el propietario lo acepta.

---

## 5. Auditoría y trazabilidad

`cat.Articulo` es temporal: la historia gana la columna `DescripcionClave` (sin `CHECK`). El relleno inicial **no** genera filas de historia (ver 7). Los cambios posteriores de descripción ya generan historia; la clave va en la misma fila. Sin cambios en `_LOG` ni bitácoras.

## 6. Persistencia de sincronización (ADR-53)

- `cat.Articulo` es de solo central (V-10): la clave se calcula **una vez, en la central**, y viaja con el artículo como una columna más. El nodo SQL Server recibe la misma migración; la sucursal en línea con SQLite (tras las olas) crea `DescripcionClave TEXT` con su índice y busca con `LIKE`/`GLOB` sobre bytes en mayúsculas: no necesita intercalación ni la función. La clave es idéntica en central, nodo y SQLite.
- Si la regla cambia (otra decisión sobre la ñ), el diagnóstico de la central reescribe las claves y la réplica baja **todas** las filas cambiadas (hasta 50.000 actualizaciones de artículo). Por eso la ñ se firma **antes** de construir.

---

## 7. Migración `Ola4BusquedaSinTildes` y reversión

Posterior a `20261009022600_Ola4FactorUnidad`. Por EF (columna, `CHECK`, índice en `MaeConfiguracion`) más un lote SQL en `SqlMigracionesOla4BusquedaSinTildes.cs`, siguiendo el patrón de las anteriores; el script idempotente generado se embebe en `GPOS.Migracion` (E-12 de B). El backend revisa que EF genere la secuencia temporal correcta; si no, la escribe a mano en el lote SQL.

**Up (orden):**

1. `ALTER TABLE cat.Articulo SET (SYSTEM_VERSIONING = OFF);`
2. Si `COL_LENGTH('cat.Articulo','DescripcionClave') IS NULL`: agregar `DescripcionClave varchar(150) COLLATE Latin1_General_100_BIN2_UTF8 NULL` en `cat.Articulo` **y** en `cat.ArticuloHistorial`.
3. **Relleno** en las dos tablas, con la misma regla de 3.1 (T-SQL, `WHERE DescripcionClave IS NULL`):
   - `UPPER(Descripcion)` → `TRANSLATE(…, ConMarca, SinMarca)` (las constantes de C# se insertan en el SQL al generar el lote, para que no se escriban dos veces);
   - bucle: mientras haya filas con `PATINDEX('%[^A-Z0-9 Ñ]%', clave COLLATE Latin1_General_100_BIN2_UTF8) > 0`, reemplazar ese carácter por espacio (a lo sumo 150 vueltas; cada vuelta solo toca las filas que aún tienen signos);
   - bucle de `REPLACE('  ', ' ')` y `LTRIM(RTRIM())`.
   El `UPDATE` dispara `TR_Articulo_Codigo` y `TR_Articulo_UnidadBase`; ambos solo actúan si cambian código o unidad base (no cambian). Con la versión apagada no hay historia nueva. `Version` (rowversion) cambia: sin efecto, todo es desarrollo.
4. `ALTER COLUMN … NOT NULL` en las dos tablas.
5. `CK_Articulo_DescripcionClave` en `cat.Articulo` (no en la historia).
6. `ALTER TABLE cat.Articulo SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = cat.ArticuloHistorial, DATA_CONSISTENCY_CHECK = ON));`
7. Crear `IX_Articulo_DescripcionClave`; eliminar `IX_Articulo_Descripcion` (si se confirma 4).
8. (Opcional, si se acepta el hallazgo) `IX_Articulo_Referencia` filtrado.

Pasos 1 a 6 en una transacción (si falla, la tabla queda como estaba con la versión encendida).

**Down:** recrear `IX_Articulo_Descripcion`; quitar `IX_Articulo_DescripcionClave` (y el opcional); versión `OFF`; quitar `CHECK` y la columna en las dos tablas; versión `ON` con la misma historia. Sin pérdida de datos: la clave es derivada.

**Duración y bloqueos (inferido):** en las bases de desarrollo (cientos a pocos miles de artículos), segundos. Con 50.000 artículos: el relleno ≈ 1 a 3 s, el índice < 1 s; bloqueo de esquema sobre `cat.Articulo` durante ese tiempo, es decir, **no correr con cajas vendiendo** (hoy no hay producción).

**Paridad C#/SQL:** después de migrar, el diagnóstico (3.6) en modo lectura debe dar **cero** diferencias (prueba P-2).

---

## 8. Respaldo, restauración y retención

Sin cambios. La columna es derivada y se reconstruye con el diagnóstico; los respaldos y Backup Tool no requieren nada nuevo.

## 9. Privilegios de base de datos

Sin cambios: la cuenta de aplicación ya escribe `cat.Articulo`. El `ALTER TABLE … SYSTEM_VERSIONING` lo ejecuta la identidad de esquema de `GPOS.Migracion` (nunca `sa` ni `gsf`, ADR-44). El diagnóstico que corrige claves con la versión apagada debe correr **con la identidad de esquema**, no con la de la aplicación; si eso complica, la corrección se hace con la versión encendida y se acepta la historia (decisión del backend, documentada).

---

## 10. Pruebas

| # | Prueba | Tipo |
|---|---|---|
| P-1 | `TextoBusqueda.Clave`: «Café», «cafe», «CAFÉ» → `CAFE`; «Ñame»/«ñame» → `ÑAME` y «name» → `NAME` (Ñ-1); «Pingüino» → `PINGUINO`; «Coca-Cola 2L» → `COCA COLA 2L`; espacios dobles y bordes; `null` y «***» → `""`; «ß» y emoji → espacio | Unitaria |
| P-2 | Paridad: un corpus de 1.000 descripciones (con todas las letras de la tabla, Ñ, signos y UTF-8 fuera de la tabla) normalizado por C# y por la expresión T-SQL del relleno da claves idénticas | Integración (SQL Server) |
| P-3 | Búsqueda F3: (a) «cafe», «CAFE», «café» encuentran «Café»; (b) «ñame» encuentra «Ñame», «name» no (Ñ-1; con Ñ-2, sí); (c) «leche entera» encuentra «Leche UHT Entera»; (d) **escáner**: un EAN de 13 dígitos, un código con guion y un PLU resuelven igual que antes; (e) «50%» busca el literal; (f) un código alterno parcial sigue encontrándose | Integración |
| P-4 | `CK_Articulo_DescripcionClave` rechaza minúsculas, tildes, signos, espacios dobles y bordes; acepta `Ñ` y `""` | Integración |
| P-5 | Alta, edición y las dos importaciones dejan la clave correcta (sin tocar sus servicios) | Integración |
| P-6 | Migración: `Up` con artículos con tildes rellena claves, **no** agrega filas a `cat.ArticuloHistorial`, deja la versión encendida; `Down` deja el esquema de Ola4FactorUnidad; segunda ejecución del script idempotente sin cambios | Migración |
| P-7 | Rendimiento con 50.000 artículos y 250.000 códigos: lecturas y CPU del F3 sin coincidencias, antes y después (esperado: ≤ lecturas de hoy, CPU menor); p95 de la venta con 5 búsquedas simultáneas sin cambio apreciable (≤ +10 ms) | Rendimiento |
| P-8 | Arquitectura: ningún SQL propio escribe `Descripcion` de `cat.Articulo` sin la clave; ningún `LIKE` sobre `a.Descripcion` de artículos queda en `Consultas/**` | Arquitectura |

## 11. Esfuerzo (inferido)

| Parte | sp |
|---|---|
| `TextoBusqueda` en `GPOS.Contracts` (tabla cerrada, palabras, Ñ-1) + P-1 | 0,08 |
| Dominio (*setter*) + mapeo + migración con relleno y tabla temporal + P-4, P-5, P-6 | 0,15 |
| Seis consultas/servicios + `VistaPrecios` + escape de comodines + P-3 | 0,15 |
| Paridad P-2, arquitectura P-8, diagnóstico ampliado a `cat.Articulo` | 0,07 |
| Medición P-7 | 0,05 |
| **Total** | **≈ 0,5 sp** (0,4 a 0,7) |

Variante mínima (solo F3 y maestro de artículos, sin diagnóstico ni `VistaPrecios`): ≈ 0,3 sp. Ñ-2 suma ≈ 0,05 sp. El índice opcional de `Referencia`, ≈ 0,03 sp.

## 12. Riesgos

| # | Riesgo | Prob. | Mitigación |
|---|---|---|---|
| R-1 | Un camino de escritura futuro (SQL directo) no actualiza la clave → el artículo no aparece buscando por nombre | Baja | *Setter* del dominio, P-8, `CHECK` de forma, diagnóstico |
| R-2 | Divergencia C#/SQL en letras fuera de la tabla | Baja | Tabla cerrada compartida, P-2 |
| R-3 | Cambiar la decisión de la ñ después de construir → recalcular y replicar todo el catálogo | Media si no se firma antes | Firmar Ñ-1/2/3 antes de construir |
| R-4 | Teclados sin ñ en el POS (con Ñ-1, «pina» no encuentra «Piña») | Media | Ñ-2 como alternativa; o el cajero busca por «pi» |
| R-5 | B construye su versión NFD en `GPOS.Core` por separado → dos reglas | Media | Entrega a B: adoptar la de `GPOS.Contracts` |
| R-6 | El `EXISTS` sobre códigos alternos domina el costo del F3 con catálogos grandes (preexistente) | Media | Medirlo en P-7; si pesa, buscar códigos solo cuando el texto tiene dígitos (≈ 0,05 sp) |
| R-7 | `ALTER TABLE` de la tabla temporal falla a medias | Baja | Transacción en los pasos 1 a 6; P-6 |
| R-8 | «cocacola» no encuentra «Coca-Cola» (los signos separan palabras) | Baja | Aceptado; documentar al usuario |

## 13. Qué requiere firma del propietario

1. **La ñ:** Ñ-1 (recomendada, no igualar), Ñ-2 (asimétrica) o Ñ-3 (igualar). Afecta también a Farmacia.
2. **Técnica:** clave en C# guardada al grabar (opción A) para el núcleo, como patrón único del producto (ratifica DC-2 de B para `cat.Articulo`).
3. **Semántica visible:** «contiene por palabra» en cualquier orden (recomendada) frente a «comienzo de palabra».
4. (Opcional) Índice `IX_Articulo_Referencia` por el hallazgo del escáner.

## 14. Entregas a otros agentes

- **desarrollador-backend (A):** construir según 3 a 7 y 10, después de Ola4FactorUnidad; confirmar el uso de `IX_Articulo_Descripcion` antes de eliminarlo; revisar el SQL temporal que genere EF.
- **arquitecto-datos y backend de B:** usar `TextoBusqueda.Clave` de `GPOS.Contracts` (tabla cerrada, regla de la ñ firmada) en `far.*` en lugar de la versión NFD de `GPOS.Core`; ajustar su `CHECK` si se firma Ñ-1/Ñ-2 y P-F03.
- **arquitecto-software:** ubicación de `TextoBusqueda` en `GPOS.Contracts` y regla de arquitectura P-8.
- **qa:** P-2, P-3 y P-7 en el plan de la ola.
- **arquitecto-maestro:** preparar la hoja de firma de la sección 13.

**Firma del propietario (2026-10-09, segunda):** puntos 2, 3 y 4 de la sección 13 según la recomendación: técnica A (clave en C# guardada al grabar en `cat.Articulo.DescripcionClave`, `TextoBusqueda.Clave` en `GPOS.Contracts`) como patrón único del producto; «contiene por palabra» en cualquier orden; índice `IX_Articulo_Referencia` filtrado incluido en la migración.
