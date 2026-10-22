```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 7: plan de pruebas de E-1 de ADR-93, tarjetas sin foto)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (E-1 se construye allí, TB-01)
Estado: Abierto (sin revisión del auditor-seguridad; es un plan, sin código)
```

# Plan de pruebas de E-1 · ADR-93 (tarjetas de Artículos sin foto)

**Fuentes.** ADR-93 (`b/adr93-tarjetas-foto`: TA-01, TA-02, TA-04, TB-06 a TB-09, TN-01), precisión de TA-P08 (`b/adr93-ta-p08-confidencialidad`), entrega de A `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (P-0, R-01 a R-14, D-1 a D-4), boceto v2.2 (solo apoyo visual; manda el ADR). Sin compilar ni ejecutar nada: es un plan. Las líneas de código que cita A son de `feature/modelo-ng` @ `e3e729c1`; el desarrollador las verifica al construir.

## 0. Convenciones

- **Clave de tipo** (columna «Tipo»): **SQL** = necesita base `GPOS_TEST_*` (`GPOST_TEST_SERVER`); **HTTP** = API en proceso con base (también SQL); **TX** = texto/reflexión/contrato, sin base; **UI** = componente Razor (bUnit) en `GPOS.Web.Tests` y espejo en `GPOS.UI.MAUI.Tests` (ADR-04); **MAN** = prueba manual del propietario.
- **Dependencia** (columna «Dep.»): `—` = nada abierto; `D-1`, `D-2`, `D-3`, `D-4` = decisión de B pendiente (A, §5); `TA-P04` = fórmula inicial, se afinará; `DB7` = depende de cuentas/membresías de D1 de DB-7.
- Trait propuesto: `Esquema=NG`, `Categoria=Inventario` o `Categoria=Tarjetas`, para filtrar sin tocar `Transicion!=Ola5&Transicion!=Defecto`. Un archivo por área: `ArticulosPaginaTests`, `ArticulosAlertaTests`, `AlcanceAlmacenesTests`, `ArticulosPreferenciasTests`, `ArticuloTarjetaContratoTests`, `CategoriaColorTests`.
- **Fixture común.** Empresa con 2 sucursales (S1 principal, S2), 2 almacenes por sucursal (A1, A2 en S1; A3, A4 en S2), 130 artículos de inventario con descripciones repetidas (para el desempate por `Id`), un servicio y un artículo no inventariable; usuarios: GLOBAL (`RestringirSucursal=0`), R1 (restringido a S1), R-SIN (restringido sin sucursal resoluble), R-VIEJO (restringido con token de la sucursal anterior), SIN-COSTOS (sin «Ver costos») y CON-COSTOS.
- Las pruebas de carga y los 50 000 artículos (V-5) **no** se corren en OSHIN-LEGION; van a la máquina de B o a `LFMB`.

## 1. Listado paginado (TB-06)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| P-01 | `GET /api/maestros/articulos/pagina` devuelve `PaginaDto(Filas, Total, Pagina, Tamano)`; con 130 artículos y tamaño 24: 6 páginas, la última con 10 filas | HTTP | — |
| P-02 | Tamaños válidos 12, 24, 48, 96; cualquier otro (0, 25, 500, negativo, no numérico) responde 400, nunca recorta ni toma uno por omisión silencioso | HTTP | — |
| P-03 | Página 0, negativa, mayor que M: definir y fijar el contrato (400 o lista vacía con `Total` correcto); la prueba fija lo que decida el desarrollador, pero **nunca** una excepción 500 | HTTP | pregunta a A: ¿400 o vacía? |
| P-04 | Orden fijo `DescripcionClave, Id`: con 40 artículos de igual descripción, recorrer todas las páginas no repite ni pierde ninguna fila (unión de páginas = conjunto completo, sin duplicados) | SQL | — |
| P-05 | Estabilidad con inserción concurrente: insertar un artículo entre la lectura de la página 1 y la 2 no genera duplicados (puede desplazar una fila, no repetirla de forma inconsistente más allá de lo que el orden permite) | SQL | — |
| P-06 | `Total` coincide con `COUNT` de los filtros actuales: búsqueda por texto, categoría, inhabilitados, tipo; `Total` no depende de la página pedida | SQL | — |
| P-07 | Cada filtro de hoy (texto, referencia, código de barras alterno de `cat.ArticuloCodigo`) da el mismo conjunto que `GET /api/maestros/articulos` congelado, comparado para ≤ 500 artículos | SQL | — |
| P-08 | Desaparece el tope silencioso: con 700 artículos la suma de las páginas es 700 (el endpoint viejo sigue en 500, sin cambio: TB-06) | SQL | — |
| P-09 | `ArticuloFila` y `GET /api/maestros/articulos` **no cambian**: comparar por reflexión las propiedades de `ArticuloFila` contra una lista congelada y una respuesta dorada de ejemplo | TX + HTTP | — |
| P-10 | Sin parámetros SQL `nvarchar` contra columnas `varchar` (ADR-50): la consulta paginada declara tipo y largo en cada parámetro; la vigila CP-169/`LongitudesColumnas` y una prueba que inspecciona el plan (sin `CONVERT_IMPLICIT` en `ArticuloCodigo`/`Descripcion`) | SQL | — |
| P-11 | Permiso: sin el privilegio de Artículos responde 403; con empresa distinta a la del token no sale nada de otra empresa | HTTP | — |
| P-12 | La Tabla (mismo endpoint) conserva columnas y apariencia: prueba de componente que compara el HTML renderizado antes/después con el mismo conjunto de filas | UI | — |
| P-13 | «Página N de M» y «Cargar más» (teléfono, tamaño 12): se muestran bien con 0, 1, 12 y 13 filas; con 0 filas, «sin resultados» y no «Página 1 de 0» | UI | — |
| P-14 | Rendimiento (V-5): `COUNT` y orden usan `IX_Articulo_DescripcionClave` con 50 000 artículos y filtro de almacenes de sucursal; informe del plan, sin tiempo absoluto en OSHIN-LEGION | SQL (manual en máquina de B) | V-5 |

## 2. Alcance de almacenes, alerta y rombos (TB-07, TA-P05, TA-P08)

### 2.1 Pieza común P-0 (`IAlcanceAlmacenes`)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| AL-01 | GLOBAL (`RestringirSucursal=0`) ⇒ `Global`, aunque la sesión tenga sucursal (PREGUNTA-4) | SQL | — |
| AL-02 | R1 ⇒ `Sucursal(S1)` y se calcula con los datos del **servidor**, no del token | HTTP | — |
| AL-03 | R-VIEJO (token con S2, servidor dice S1): el resultado usa S1 y queda un aviso en el registro | HTTP | — |
| AL-04 | R-SIN (restringido, `SucursalDefault` nula o a una sucursal inexistente) ⇒ `Vacio`, **nunca** `Global`; la respuesta no contiene filas de existencia y no es un 500 | HTTP | — |
| AL-05 | Error al leer el estado del usuario (la lectura de `RevocacionSesiones` falla) ⇒ `Vacio`, falla cerrada | SQL (inyectando falla) | — |
| AL-06 | Cualquier parámetro del cliente (`?almacen=`, `?sucursal=`, cabecera) no amplía el alcance | HTTP | — |
| AL-07 | Cambio en caliente: el ADMIN cambia la restricción o la sucursal de R1; dentro de la ventana de 15 s de caché el comportamiento es el anterior y después el nuevo (documentar el valor exacto; no debe tardar más de la caché) | HTTP | — |
| AL-08 | Patrón SQL de falla cerrada: con `@global` o `@sucursalAlcance` ausentes/`NULL` la consulta devuelve **cero filas** (prueba directa sobre el SQL con los parámetros en `NULL`) | SQL | — |
| AL-09 | `Almacen.SucursalId` no nulo: no hay fuga por `NULL` (comprobación de esquema) | TX | — |
| AL-10 | Alcance `Consulta` (solo almacenes de la sucursal) frente a `Operativo` (más `SucursalAlmacenPermitido`) devuelven conjuntos distintos en un fixture con un permitido | SQL | D-1 |

### 2.2 Alerta por almacén y rombos

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| AM-01 | `BajoMinimo` = `Minimo > 0` y `Existencia < Minimo`; con `Minimo=0` jamás alerta; con `Existencia == Minimo` no alerta | SQL | — |
| AM-02 | **TA-P05**: almacén con `Minimo=10` y **sin ningún movimiento** (sin fila en `inv.Existencia`) cuenta como bajo mínimo | SQL | — |
| AM-03 | `AlmacenesBajoMinimo` cuenta solo los del alcance: GLOBAL ve 3, R1 ve los de S1 | SQL | — |
| AM-04 | Cálculo de `PorcReorden` = `round(100 × Σ_A max(Existencia,0) / Σ_A Reorden)` con tope 999; A = almacenes del alcance con `Reorden > 0` | SQL | TA-P04 |
| AM-05 | Almacenes con `Reorden = 0` no suman existencia (no inflan el porcentaje) | SQL | — |
| AM-06 | Saldo negativo cuenta como 0 en la suma | SQL | — |
| AM-07 | Rombos = `min(7, ceil(PorcReorden/25))`, 0 solo si la existencia es 0: tabla de valores límite (0, 1, 25, 26, 50, 100 ⇒ 4, 150 ⇒ 6, 151 ⇒ 7, 999 ⇒ 7); prueba parametrizada **aislada en una sola función pura** para que el afinado futuro de TA-P04 solo cambie esa tabla | TX | TA-P04 |
| AM-08 | A vacío (ningún almacén con reorden en el alcance), servicio o artículo no inventariable ⇒ sin rombos y sin porcentaje | SQL | — |
| AM-09 | Un restringido cuyo alcance excluye los únicos almacenes con reorden ⇒ sin rombos (no se «filtra» el porcentaje global) | SQL | — |
| AM-10 | Coherencia: el total, la alerta y los rombos usan el mismo alcance (prueba que compara las tres cifras con un cálculo independiente del test sobre los mismos datos) | SQL | — |
| AM-11 | **Pestaña Almacenes alineada con TA-P05**: `ExistenciasAsync` incluye el almacén con mínimo y sin existencia (fila con existencia 0, mínimo 10, alerta) | SQL | — |
| AM-12 | Sin bloqueos: la consulta no usa `NOLOCK`, `UPDLOCK` ni transacción explícita (inspección del SQL del texto) y funciona bajo RCSI mientras otra transacción escribe `inv.Existencia` sin bloquearse | SQL | — |
| AM-13 | El texto accesible y el de la tarjeta dan el porcentaje real (999 ⇒ «999 %»), no el número de rombos | UI | — |
| AM-14 | Etiqueta «Existencia en su sucursal» solo para restringidos; global ve el rótulo normal | UI | texto exacto por UX |
| AM-15 | Existencia de sólo-lectura bajo la tarjeta de un servicio: no aparece recuadro | UI | — |

## 3. Frontera de confidencialidad (precisión de TA-P08; lista de A)

Para cada ruta se corre la misma matriz: **GLOBAL, R1, R-SIN, R-VIEJO**, sobre un fixture en el que S2 tiene existencias, costos y movimientos distintos de los de S1, de modo que cualquier fuga sea numéricamente detectable. Oráculo: la respuesta de R1 es **idéntica** a la que obtendría GLOBAL si S2 no existiera, y R-SIN recibe vacío (o 403/404 donde A lo define).

| ID | Ruta (A) | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|---|
| F-01 | R-01 `GET /api/inventario/existencias` | R1 solo ve A1 y A2; `?almacen=A3` ⇒ lista vacía idéntica a un almacén inexistente (no 403, para no revelar existencia); costo/valor `[DatoCosto]` sigue oculto sin permiso | HTTP | — |
| F-02 | R-02 `GET /api/inventario/kardex/{articulo}` | sin `almacen`: solo movimientos de la sucursal y `SaldoAntes` solo de ella; con `A3`: `[]` | HTTP | — |
| F-03 | R-02 (falla abierta) | un código de almacén **desconocido** devuelve `[]` para **todos** (también GLOBAL), no «todos los almacenes» | HTTP | — |
| F-04 | R-04 lectura `GET /api/maestros/articulos/{id}` | pestaña Almacenes y `dto.Existencia` limitados al alcance `Consulta`; el total es la suma del alcance | HTTP | — |
| F-05 | R-04 **escritura** `POST` del artículo | **trampa de A:** R1 guarda el artículo ⇒ las filas de `ArticuloAlmacen` de S2 (mínimos, máximos, reorden, ubicación) quedan **intactas** (comparar antes/después, fila a fila) | SQL | — |
| F-06 | R-04 escritura | una fila del DTO con almacén de S2 enviada por R1 ⇒ 422 y no se guarda nada (atómico) | HTTP | — |
| F-07 | R-04 escritura | GLOBAL sigue reemplazando todas las filas como hoy (regresión) | SQL | — |
| F-08 | R-04 escritura | R1 que quita una fila de su sucursal la borra; no toca las demás; el `rowversion` del artículo cambia solo si cambia el artículo | SQL | — |
| F-09 | R-04 escritura | R-SIN no puede guardar niveles (alcance vacío ⇒ ni lectura ni borrado de filas) y no borra los de nadie | SQL | — |
| F-10 | R-03 lista de artículos | `Existencia` = suma del alcance | HTTP | fuera del estimado de A: si B no la incluye, la prueba se marca **omitida con motivo** |
| F-11 | R-05 `/api/catalogos/articulos/{codigo}/linea` | alcance `Operativo`; almacén fuera ⇒ `Existencia = 0`; sin almacén ⇒ suma del alcance; almacén desconocido ⇒ 0, no la suma global | HTTP | D-1 |
| F-12 | R-06 `lotes-disponibles` | almacén fuera de alcance `Operativo` ⇒ 404 igual que «no existe» | HTTP | D-1 |
| F-13 | R-07 `conteos/preparar` | almacén fuera ⇒ «Almacén incorrecto» idéntico al inexistente | HTTP | D-1 |
| F-14 | R-08 conteos (lista y detalle) | lista por alcance; detalle de otro almacén ⇒ 404 | HTTP | — |
| F-15 | R-09 documentos de inventario | lista y detalle por alcance (coherente con R-02) | HTTP | D-2 |
| F-16 | R-10 revisiones de lote | lista, detalle y `abiertas/cantidad` por alcance | HTTP | — |
| F-17 | R-11 tablero | «Valor del inventario» = suma del alcance | HTTP | — |
| F-18 | R-12 avisos del tablero | solo la sucursal del restringido | HTTP | — |
| F-19 | R-13 conciliación | restringido ⇒ 403; global/SUPER como hoy | HTTP | D-3 |
| F-20 | R-14 reportes sin reenvío | restringido ⇒ 403 `SUCURSAL_NO_PERMITIDA` en el camino local | HTTP | — |
| F-21 | Transferencias (residuo 1 y 2) | sucursal nula o desconocida **no** se convierte en la principal; R-VIEJO usa la sucursal del servidor; R-SIN ⇒ 404 | HTTP | — |
| F-22 | Barrido por reflexión (anti-olvido) | recorrer los endpoints de `GPOS.Api` que devuelven existencias/niveles/movimientos (lista blanca mantenida en la prueba) y fallar si aparece una ruta de inventario nueva sin pasar por `IAlcanceAlmacenes` | TX | — |
| F-23 | Selector de almacenes (UX opcional) | `Existencias.razor` ofrece solo los almacenes del alcance a R1 | UI | opcional (A, §3.4) |
| F-24 | `GET /api/catalogos/Almacenes` y `/almacenes` de transferencias | siguen devolviendo solo código y nombre, sin existencias (no cambia) | HTTP | — |

**Vectores adversarios que cada prueba de F-01 a F-21 repite** (una sola vez cada uno, no por ruta, vía una prueba parametrizada sobre la capa común): código de almacén con mayúsculas/minúsculas distintas, con espacios al final, con `%`/`_` (comodines), con inyección de comillas, el `Id` numérico en lugar del código, parámetro repetido (`?almacen=A1&almacen=A3`) y cabeceras de sucursal falsificadas.

## 4. Sin datos de costo (TA-01)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| C-01 | Reflexión: ninguna propiedad de `ArticuloTarjeta` (ni de sus tipos anidados) lleva `[DatoCosto]` ni se llama Costo/CostoPromedio/Valor/Margen | TX | — |
| C-02 | La respuesta de `/pagina` es **byte a byte igual** para SIN-COSTOS y CON-COSTOS (mismo fixture) | HTTP | — |
| C-03 | El JSON no contiene las cadenas `costo`, `margen`, `valorInventario` (comprobación de seguridad contra una propiedad agregada por error) | HTTP | — |
| C-04 | `ArticuloFila` y `GET /api/maestros/articulos` quedan como están (ver P-09) | TX | — |
| C-05 | Ninguna alerta/rombo revela el costo indirectamente (el recuadro muestra existencia y mínimo, no valores monetarios) | UI | — |

## 5. Preferencias por usuario y empresa (TB-08, TA-01)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| PR-01 | Valores por omisión: sin fila ⇒ vista `tabla` y nivel `1` | SQL | — |
| PR-02 | Guardar `articulos.vista` ∈ {`tabla`,`tarjetas`} y `articulos.nivelPrecio` ∈ {`1`,`2`,`3`}; relee lo mismo | SQL | — |
| PR-03 | Clave o valor fuera de la lista cerrada ⇒ 400; no se guarda | HTTP | — |
| PR-04 | Aislamiento: usuario A no lee ni escribe las preferencias de B (ni siquiera el SUPER) ⇒ 403/404; el identificador de cuenta lo da el token, nunca el cuerpo | HTTP | — |
| PR-05 | Por empresa: la misma cuenta tiene preferencias distintas en E1 y E2 (el nivel apunta al catálogo de esa empresa) | SQL | DB7 |
| PR-06 | **Caída a Precio 1**: si el nivel guardado ya no existe, la lectura devuelve 1 y la pantalla muestra Precio 1 sin error (y no reescribe silenciosamente) | SQL + UI | — |
| PR-07 | El nivel de precio cambia solo lo que se **muestra**, nunca el precio con que se factura (TA-07): una factura de prueba con el nivel 3 elegido factura al precio vigente | HTTP | — |
| PR-08 | Persistencia entre sesiones: cerrar y volver a iniciar sesión conserva la vista | HTTP | — |
| PR-09 | La tabla vive en `GPOS_SYSDATA` (no en la base de empresa); `GPOS_SYSDATA` se crea idempotente dos veces seguidas sin error | SQL | — |
| PR-10 | Clave alineada con D1 de DB-7 (V-6): prueba de contrato que falla si cambia el tipo de la columna de cuenta | TX | V-6, DB7 |
| PR-11 | Concurrencia: dos escrituras simultáneas de la misma clave no producen duplicado ni excepción (última gana) | SQL | — |
| PR-12 | El conmutador Tabla/Tarjetas recuerda la última vista y por omisión muestra la Tabla | UI | — |

## 6. Color de categoría y píldora (TB-09, TA-02)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| CL-01 | Columna `ColorContorno varchar(7) NOT NULL DEFAULT '#FFFFFF'` con `CHECK #[0-9A-F]{6}` en mayúsculas; el guion es idempotente | SQL | — |
| CL-02 | Servidor rechaza (400/422): `#fff`, `#ffffff` en minúsculas (o lo normaliza a mayúsculas: fijar una sola decisión), `red`, `#GGGGGG`, `#12345`, `#1234567`, `url(...)`, `;`, comillas, `expression(`, vacío, nulo | HTTP | decisión: ¿normaliza o rechaza minúsculas? |
| CL-03 | La base rechaza el valor inválido aunque se salte la API (insert directo ⇒ error del `CHECK`) | SQL | — |
| CL-04 | Artículo sin categoría ⇒ blanco; categoría sin color asignado ⇒ blanco | SQL | — |
| CL-05 | El cliente **vuelve a validar** antes de poner el valor en `style`: dado un valor hostil en el DTO, el HTML renderizado no contiene el texto hostil y cae a blanco | UI | — |
| CL-06 | Píldora: texto largo se recorta con puntos suspensivos (clase/CSS `text-overflow`), el texto completo queda en `title` o en el texto accesible; sin desbordar la tarjeta (prueba de marcado, no visual) | UI | — |
| CL-07 | Cambiar el color de la categoría requiere el privilegio de editar categorías (no el de ver artículos) | HTTP | pregunta a B: ¿qué privilegio? |
| CL-08 | Cambiar el color de una categoría no modifica el `rowversion` de los artículos (no genera historial de 50 000 filas) | SQL | — |

## 7. Tarjeta, conmutador y estado de medios (TA-01, TA-02, TN-01)

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| T-01 | Contenido de la tarjeta: píldora, `[Tipo · Impuesto]`, precio del nivel elegido, código de barras como tercera métrica, recuadro de existencia, rombos; nada más | UI | — |
| T-02 | Sin foto (E-1): se muestra el **ícono de la categoría**, sin estado de error ni mensaje (TA-04, mínimo natural) | UI | — |
| T-03 | Estado de medios `NoAplica`: las Tarjetas están disponibles; la prueba fija que el servicio de estado devuelve `NoAplica` en la central y el conmutador aparece | UI + TX | — |
| T-04 | Los estados AUSENTE y SIN ESPACIO **no existen** en E-1 (entrega 2): la prueba no debe pedir su comportamiento; queda anotada como no aplicable hasta la entrega 2 para que nadie la invente | TX | entrega 2 |
| T-05 | «Sin conexión» no es un estado de las tarjetas (TA-P10): no existe un caso ni un texto «sin conexión» propio de tarjetas | TX | — |
| T-06 | Existencia en 0 con mínimo > 0: recuadro en alerta; existencia en 0 y mínimo = 0: sin alerta, sin rombos | UI | — |
| T-07 | Web y MAUI muestran lo mismo (misma prueba corrida sobre los dos proyectos, ADR-04) | UI | — |
| T-08 | Escritorio usa tamaño 24 y teléfono 12 por omisión | UI | — |
| T-09 | Accesibilidad básica: cada tarjeta tiene nombre accesible (descripción + código), la píldora y los rombos tienen texto alternativo | UI | — |
| T-10 | Con 96 tarjetas por página el renderizado no excede un presupuesto de nodos del DOM razonable (medir, sin umbral en OSHIN-LEGION) | UI (manual) | — |
| T-11 | Prueba manual del propietario del boceto v2.2 contra la pantalla real (contorno, píldora, rombos, conmutador, Precio 1/2/3) | MAN | — |

## 8. Seguridad, bitácora y contratos transversales

| ID | Qué se comprueba | Tipo | Dep. |
|---|---|---|---|
| S-01 | Ningún DTO nuevo expone rutas de archivo (aún no hay fotos en E-1; la prueba protege que `ArticuloTarjeta` no tenga propiedades de ruta) | TX | — |
| S-02 | Aislamiento entre empresas: un token de E1 no obtiene páginas, preferencias ni colores de E2 aunque envíe el id de empresa de E2 | HTTP | — |
| S-03 | Alcance y paginación juntos: R1 pide la página 2 de un listado donde la mitad de las existencias son de S2; `Total` no se altera por el alcance (el alcance filtra existencias, no artículos) — **ver pregunta Q-3** | HTTP | pregunta Q-3 |
| S-04 | Registro: el aviso de discrepancia token/servidor (AL-03) no incluye datos sensibles | TX | — |
| S-05 | Respuesta de errores: todo error de alcance usa el mismo formato que «no existe» (sin canal lateral por mensaje distinto) | HTTP | — |

## 9. Reparto por costo de ejecución

| Grupo | Pruebas | Dónde |
|---|---|---|
| Sin base (TX y UI) | P-09, P-12, P-13, AL-09, AM-07, AM-13..15, C-01, C-04, C-05, PR-10, PR-12, CL-05, CL-06, T-01..T-10, F-22, F-23, S-01, S-04 | cualquier equipo, incluido OSHIN-LEGION, con filtro por clase |
| Con base (SQL/HTTP) | el resto | máquina de B o `LFMB`; en OSHIN-LEGION solo por clase y sin suite completa |
| Carga/plan | P-14 (V-5), T-10 | máquina de B |
| Manual | T-11 | propietario |

## 10. Preguntas que dejo a B (no bloquean el plan)

- **Q-1.** P-03: ¿página fuera de rango es 400 o lista vacía? Recomiendo 400 para valores < 1 y lista vacía con `Total` correcto para valores > M.
- **Q-2.** CL-02: ¿el servidor normaliza `#aabbcc` a mayúsculas o lo rechaza? Recomiendo normalizar (menos fricción) y que el `CHECK` quede como red de seguridad.
- **Q-3.** S-03/AM-03: para el restringido, ¿`Total` cuenta todos los artículos (el artículo existe, solo se filtra la existencia) o solo los que tienen niveles en su sucursal? El ADR dice que el alcance filtra almacenes, no artículos: lo trato como «todos» y lo fijo con una prueba.
- **Q-4.** CL-07: ¿qué privilegio edita el color de la categoría?
- **Q-5.** F-10 a F-21: las rutas fuera de la precisión (R-03, R-05 a R-14 y transferencias) dependen de lo que B decida meter en E-1 (D-1 a D-3). Dejo la matriz completa y marco cada fila con su dependencia; las que B no incluya se marcan omitidas con el motivo, no se borran.
- **Q-6.** La prueba de barrido F-22 necesita una lista blanca mantenida a mano: ¿prefiere B una convención (atributo `[AlcanceAlmacenes]`) para que la prueba sea automática?

## 11. Orden de construcción sugerido de las pruebas

1. `AlcanceAlmacenesTests` (AL-01..10) junto con P-0: es la pieza común y la falla cerrada.
2. F-01, F-02, F-03, F-04, F-05..F-09 (lo que nombra la precisión de TA-P08, 1,45 dp de A).
3. Paginación (P-01..P-11) y alerta/rombos (AM-01..12).
4. Contrato sin costos (C-01..05) y preferencias (PR).
5. Color (CL) y componentes (T, AM-13..15, P-12, P-13).
6. Resto de rutas (F-10 a F-21) según D-1 a D-3.

## 12. Honestidad del plan

- **No se ejecutó ni compiló nada.** Los números de línea y nombres de clase de producción son los de A y del ADR; no los verifiqué contra el código vivo. Todos los esfuerzos son [I].
- Falta revisar con el arquitecto-datos el nombre real de las tablas (`cat.ArticuloImagen` no interviene en E-1; `UsuariosPreferencias` y `cat.Categoria.ColorContorno` sí).
- Las tablas de valores límite de AM-07 dependen de TA-P04 (fórmula inicial): al afinar se cambia una sola tabla.
