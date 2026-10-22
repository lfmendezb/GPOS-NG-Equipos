# Notas de diseño: tarjeta de Artículos (boceto 2, inspirada en la carta de referencia)

[V] verificado en `origin/master`; [I] inferido. Boceto: `tarjetas-articulos.html` (JS mínimo embebido: color por categoría, nivel de precio, conmutador).

## Decisiones del propietario ya tomadas (según el coordinador)
- Tabla por omisión; la última vista se recuerda por usuario. Una foto por artículo. Alerta de existencia baja por almacén. Precio 1 por omisión con nivel elegible por usuario. Paginación del lado del servidor en teléfono. Foto reutilizable en cotizaciones y pedidos y habilitable por formato según el cliente. Imagen de referencia: propia, uso autorizado.

## Mapa campo -> tarjeta (`ArticuloFila`, `src/GPOS.Contracts/Tablas/Maestros.cs:171`) [V]
| Tarjeta | Campo | Estado |
|---|---|---|
| Píldora (arriba der.) | `Categoria` (nombre de la categoría) | existe |
| Nombre en mayúsculas / subtítulo cursiva | `Descripcion` / `Marca` | existe (Marca en ArticuloFila es texto) |
| Línea `[ Tipo · Impuesto ]` | `Tipo` (Artículo o Servicio), `IdImpuesto` | existe |
| Párrafo | `CodigoBarras` y Referencia; se omite si no hay | Referencia NO está en ArticuloFila (sí en ArticuloDto) [V]: campo nuevo |
| Recuadro EXISTENCIA | `Existencia` total + BajoMinimo por almacén | falta: nº de almacenes bajo mínimo (regla `Inventario.cs:91`: Mínimo > 0 y Existencia < Mínimo) |
| Pie PRECIO (nivel 1/2/3) | `Precio1`; Precio2/3 | Precio2/3 no vienen en el listado [V]: campos nuevos |
| Pie EXISTENCIA / IMPUESTO | `Existencia` / `IdImpuesto` | existe |
| Código abajo a la derecha | `Id` | existe |
| Foto | (ninguna) | no existe campo de foto [V]: decisión de datos pendiente |
| Rombos de nivel | Existencia frente a Máximo (o Mínimo) | `Maximo` solo existe por almacén (`ArticuloAlmacenDto`) [V]; sin dato, no se dibujan (servicios, artículos sin niveles) |
| Contorno | color de la categoría | configuración de la empresa, sin decidir dónde se guarda |

Servicio: sin rombos, existencia «—» y recuadro «No aplica inventario». Inhabilitado: gris con cinta «INHABILITADO».
Decisiones del propietario sobre v2.1 (2026-10-21): la categoría larga se recorta con puntos suspensivos en la píldora; la tercera métrica del pie es el CÓDIGO DE BARRAS (el impuesto queda solo en la línea de corchetes); el párrafo ya no repite el código de barras.

## Pendiente de contrato (para arquitecto-software)
Referencia, Precio2/Precio3, almacenes bajo mínimo (conteo), Máximo/porcentaje de nivel, foto (miniatura), paginación del servidor (página y total), y el color de categoría (catálogo o configuración).

## Teclado y accesibilidad
- Tarjeta enfocable (Tab), Enter/Espacio abre el detalle; foco de 3 px; el conmutador, el nivel de precio y la paleta usan `aria-pressed` / `role=radio` con nombre de color.
- `aria-label` por tarjeta (nombre, categoría, precio, estado de existencia); rombos con `role=img` y texto «nivel n de 7».
- Contraste: texto claro sobre panel oscuro fijo; el estado nunca depende solo del color (texto «Bajo mínimo», «Sin existencia», cinta). El contorno por categoría no lleva información crítica. Verificar 4.5:1 con colores elegidos por el usuario (paleta de 8 acotada) y la foto detrás del nombre (degradado oscuro).
- Teléfono: 1 columna, «Página 1 de N» y «Cargar más». Tema claro/oscuro: la tarjeta conserva su panel oscuro (como la referencia).

## No se cambia
La tabla actual, la edición del artículo y la ventana de facturación del POS. Solo MudBlazor y CSS; sin librerías.

## Preguntas que quedan
1. ¿Tamaño y formato de la foto (miniatura, peso máximo), quién la sube, y si va como columna o adjunto? (ADR pendiente).
2. ¿Tercera métrica: Impuesto (repetido) u otra?
3. ¿Los rombos miden contra el Máximo o contra el Mínimo, y cómo se agregan varios almacenes?
4. ¿Paleta de 8 colores fija o libre? ¿Color por defecto de categorías nuevas?
5. ¿Se muestra la tarjeta a quien no ve costos igual? (no lleva costos).
6. ¿Pie «Cargar más» o «Página N de M» en teléfono, o ambos?

## Esfuerzo grueso (días-persona, ±50 %)
- Sin foto: 6 a 9 d (tarjeta estilizada 2; color por categoría y su pantalla 1,5; nivel de precio y conmutador con recuerdo 1; rombos y alerta por almacén 1; responsivo, MAUI y paginación móvil 1,5; estados, accesibilidad y pruebas 1,5). Más los campos nuevos del contrato (trabajo aparte del arquitecto-software).
- Con foto (adicional): 8 a 14 d (columna o adjunto, subida y redimensión, miniatura, visor, importación, permisos, reutilización en cotizaciones/pedidos y habilitación por formato). Sin diseño de backend.
