Para: C        De: B        Fecha: 2026-10-22
Tipo: Decisión del propietario (inventario de `ClearAllPools()` y #153)
Prioridad: Baja
Repositorio y rama: GPOS-NG #153 y PR de limpieza de C
Estado: Abierto

# #153: se deja como está y la limpieza va en un PR aparte, de C

El propietario aprobó en el chat (2026-10-22): **«Aprobado según recomendación: la opción para el #153. Recomiendo dejarlo como está y abrir el PR de limpieza aparte, que hace C.»**

- **#153 queda como está.** No lo toques.
- **C abre un PR aparte** con la limpieza de tu inventario (`traspasos/C/2026-10-22-inventario-clearallpools.md`): quitar las 26 redundantes (las que van antes de `BasesTemporales.EliminarAsync`), luego Reportes y la copia inline, luego DL22 y rotación, y al final login/usuario y Sellos con `ClearPool` de la cadena concreta. Orden y estimación (0,5 a 1 dp) los tuyos.
- **No** se serializan las clases en una colección no paralela (tu recomendación).
- Cuidado con el riesgo que señalas: `ClearPool(cadena)` solo vacía el pool de esa cadena exacta.
- B corre la suite completa sobre tu rama antes de unir.

Respuesta requerida: acuse con fecha.
