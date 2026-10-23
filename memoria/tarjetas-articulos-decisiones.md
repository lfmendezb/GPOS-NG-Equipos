---
name: tarjetas-articulos-decisiones
description: "2026-10-21: vista de tarjetas de Artículos (boceto v2.2 aprobado) y decisiones del propietario: foto por ruta al banco de imágenes, paginación, alerta por almacén, color por categoría"
metadata:
  node_type: memory
  type: project
  originSessionId: fa41992d-86b9-4341-98ef-a923780a09be
  modified: 2026-10-21T13:30:38.079Z
---

El propietario aprobó el **boceto v2.2** de la vista de tarjetas de Artículos (HTML en el scratchpad de la sesión del 2026-10-21; inspirado en una tarjeta de IA que él dio y autorizó usar tal cual). Decisiones suyas, en el chat:
- Conmutador **Tabla | Tarjetas**: Tabla por omisión; se recuerda la última vista por usuario. Paginación «Página N de M» en escritorio y teléfono.
- Píldora arriba a la derecha = **categoría** (recortada con puntos suspensivos); línea `[ Tipo · Impuesto ]`; tercera métrica del pie = **código de barras**.
- Contorno de la tarjeta = **color de la categoría, libre** (selector sin paleta fija); por omisión **blanco**.
- Alerta de existencia baja con Mínimo/Reorden **por almacén** (pestaña Almacenes del artículo; regla `ExistenciaDto.BajoMinimo`). Rombos = porcentaje del nivel de **reorden general de todos los almacenes** (fórmula exacta por confirmar).
- **Foto:** una por artículo; **no se guarda en la base**, el artículo apunta a la ruta del **banco de imágenes**; la sube el usuario desde la ventana maestra; el **nombre del archivo coincide con la referencia o el código de barras**; opcional: función que recorre el banco y asigna la ruta comparando nombres. Reutilizable en cotizaciones, pedidos y otros formatos, habilitable por formato según el cliente.
- **Sucursales con Nodo (afinado el 2026-10-21):** el banco de imágenes se descarga localmente en el nodo. Estados de la copia: Completa y Parcial → tarjetas disponibles (las fotos que faltan van con el ícono de la categoría); Ausente y Sin espacio → no disponibles; «Sin conexión» NO se valida (decisión final del 2026-10-21, sustituye a la firma anterior del mismo día): un cliente en línea sin conexión no ve nada de todos modos; solo cuentan los estados de la copia del banco (NoAplica, Completa, Parcial, Ausente, SinEspacio), que son el estado real del banco; una foto que no se obtiene muestra el ícono de la categoría. Sin tarjetas solo usan la Tabla. El respaldo de las imágenes (fuera de la base) sigue abierto.
- Precio 1 por omisión, con nivel elegible por usuario. La tarjeta se muestra igual a quien no ve costos (no lleva costos).

**Why:** ganar vistosidad en la ventana de artículos (el cliente pide imágenes en cotizaciones y pedidos).

**How to apply:** falta el ADR de la foto (ruta del banco, seguridad de la ruta, respaldo, sucursales), el cambio de contrato del listado (paginación, alerta, nivel de precio, miniatura) y la preferencia por usuario. No se programa hasta que el propietario firme. Relacionado: [[tecnologia-solo-con-consulta]], [[documentacion-estricta-estado-de-firmas]].

**Firmas sobre la hoja de ADR-93 (2026-10-21, chat):** TA-P01 (a) solo `feature/modelo-ng`; TA-P02 (a) miniaturas en el navegador; TA-P03 NO se amplía el respaldo (MD-54): el sistema guarda solo la ruta y proteger el banco de imágenes es responsabilidad del cliente; TA-P04 (a) fórmula recomendada de rombos, inicial, a afinar; TA-P05 pendiente de confirmar (lectura de trabajo: un almacén sin movimientos no se alerta); TA-P06 (a) asignación masiva a todos los artículos y servicios con opción de incluir o no los ya vinculados; TA-P07 el ADMIN configura la carpeta del banco y administra la carga masiva (el SUPER igual por rango), con guardas técnicas; TA-P08 el usuario de sucursal ve alertas y rombos solo de los almacenes de su sucursal, la central ve todo; TA-P09 lista aparte de ambiguos con ruta, sin asignar; TA-P10 no se valida «sin conexión»; TA-P11 el nodo copia fotos y miniaturas o solo miniaturas según la configuración del ADMIN (o del SUPER); TA-P12 pendiente (el propietario pidió contexto).

**Huecos del ADR-93 (2026-10-21, chat):** banco de la central caído → además de la bitácora, correo al ADMIN documentando el caso (verificar si existe mecanismo de correo; si no, es dependencia nueva a consultar); copiar solo las miniaturas en los nodos aprobado (evita el caso «no le cabe la versión nueva»); primera descarga en Parcial con íconos: aprobado; ADR-93 «aprobado con observaciones» (el número lo confirma el propietario al registrar). Siguen pendientes TA-P05 (¿alerta en almacén con mínimo y sin movimientos?) y TA-P12 (cómo se habilitan las fotos en los formatos).

**TA-P08 precisada (2026-10-21, chat):** la restricción por sucursal es también una **frontera de confidencialidad**, no solo de presentación: aplica a la tarjeta, `GET /api/inventario/existencias`, el kárdex y la pestaña Almacenes (+1 a 1,5 d fuera del ADR-93; S-16/S-17 de la revisión de A). Falta registrarla como precisión y avisar a A. Siguen sin respuesta PREGUNTA-1 (quién escribe en el banco; recomendación: solo administradores del servidor) y PREGUNTA-4 (sin restricción = global).
