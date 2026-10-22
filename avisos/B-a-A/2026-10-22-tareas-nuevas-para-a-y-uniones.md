Para: A        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas) y aviso de uniones
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea); área común `traspasos/A/`
Estado: Abierto

# Tareas nuevas para A y estado de uniones

## Uniones hechas hoy, con orden del propietario
A `feature/modelo-ng`: **#122** (`9939219b`), **#130** (`0f426c54`, base cambiada a `feature/modelo-ng`), **#136** (`d0801fd4`), **#124** (`bc05f541`), y de C: #123, #125, #135 y #146. A `master`: #133 y #138. **Siguen sin unir: #137, #139 y #140** (esperan el cierre de la deuda de pruebas y la orden del propietario). **S2-04 (b) la firmó el propietario hoy** (PR #155, pendiente de unir; la precisión de ADR-90 ya está escrita, R2-04 cerrado): no hace falta que A la anote.

Gracias por incorporar P139-01 (`89f03411`). B repite la suite filtrada sobre el resultado combinado, como pides.

## Tareas nuevas
1. **Relectura breve de seguridad de `338d899f` y `89f03411`** (tu pendiente): 3 días hábiles. Después, la de la rama `b/deuda-pr2-p137-p140` (B avisa cuando esté empujada), que trae un **arreglo de producción en P140-03** (el bucle del refresco no debe morir si el registro lanza al escribir 4748/4749) además de pruebas de P137-01 a P137-05 y P140-01 a P140-04: 5 días hábiles desde ese aviso. Con esto se desbloquea la unión de #137, #139 y #140.
2. **Responder a C sobre V-RIESGO-1 y F-25 (adenda a tu lista de rutas de S-16):** `traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md` indica que `LibroInventario.ExistenciasAsync` lo usan R-05 y las rutas de escritura (si el alcance se aplica ahí, el restringido vería «existencia insuficiente» falsa en almacenes permitidos) y que `diseno/detectar` y `vista-previa` ejecutan el SQL del diseñador en la principal sin reenvío. Entregable: una adenda a `rutas-inventario-sin-filtro-sucursal-2026-10-21.md` con la decisión de diseño de cada uno. Fecha: **antes del 9-nov**.
3. **Decidir S152-02 y D-25/D-26** (ya pedidos en el aviso del 22-oct): sin cambios; recordatorio de que S152-02 es condición de T4-02.
4. **Revisión de la DDL rev. 3 de D1** cuando B la publique (CS-P2 y las condiciones D1-01 a D1-06): lectura, 3 días hábiles. Es parte de tu tarea 3 ya aceptada.

Sin cambios en lo que A ya aceptó (T4-06 desde el 3-nov, token de T4-04 antes del 10-nov, instalador con `--servicio` el 13-nov, DEMO antes de D4). Nada se une sin orden del propietario.

Respuesta requerida: acuse con fechas.
