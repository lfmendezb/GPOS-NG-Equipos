```
Para: A (y todos los equipos)      De: B (por encargo del propietario)      Fecha: 2026-10-09
Tipo: Aviso (directiva del propietario)
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Directiva: código fuente bien documentado (el propietario lo revisará a mano)

Palabras del propietario (2026-10-09):

> «Quiero que el código fuente quede bien documentado. Me dispongo a revisar el trabajo de los equipos manualmente por mi cuenta. Porque necesito entender qué pasa debajo del capó de mi sistema.»

El propietario aprobó este estándar y la guía de recorrido, y pidió comunicarlos aquí.

## Estándar de documentación (rige desde hoy para todo código nuevo o modificado)
1. **Comentario XML en español** (`/// <summary>`) en toda clase, interfaz, método y propiedad públicos: qué hace y para qué.
2. **El porqué, no solo el qué.** Donde el código aplica una regla de negocio o una decisión, el comentario la explica y **cita el ADR o la regla**. Ejemplos:
   - `// Orden único de bloqueos (precisión de ADR-45): almacenes → documentos → configuración → series.`
   - `// Caso fijo de ADR-118: el elaborado con lote nunca queda negativo.`
3. **Un README por módulo o carpeta principal:**
   - para qué sirve;
   - cómo fluye una operación típica;
   - qué ADR aplica;
   - dónde están sus pruebas;
   - qué falta construir (decidido, no implementado).
4. **Sin relleno.** No se comenta lo obvio («suma 1»); se comenta lo que alguien que no escribió el código no podría deducir: la intención, la regla, el riesgo, la alternativa descartada.
5. **SQL a mano y migraciones:** comentario de cabecera con el propósito, el ADR y si es idempotente; en consultas críticas, por qué se eligió ese índice, bloqueo o aislamiento.
6. **Pruebas:** el nombre o un comentario dice qué regla protege.
7. **Los encargos a los desarrolladores incluyen este estándar.** QA y los revisores lo verifican en cada entrega.

## Código existente
- Se documenta **por módulos, en el orden de los flujos del MVP**: venta, caja y cierre Z, inventario y kárdex, compra, numeración y NCF, reportes.
- **`feature/modelo-ng` lo documenta A** en sus tandas, porque es el único editor de ese árbol. No hace falta frenar la construcción: puede ir como tanda de documentación entre corridas o junto con el código que se toca.
- **B documenta sus propias ramas**, empezando por la API de reportes (`b/ola5`).

## Guía de recorrido «Bajo el capó de GPOS Argón» (aprobada)
- La prepara B (documentador técnico) **leyendo `feature/modelo-ng` en modo de solo lectura**, sin tocar el árbol de A.
- **Primera entrega:** el mapa de los proyectos y cómo se conectan, y **el recorrido de una venta**, desde «Cobrar» hasta el NCF, el kárdex y la caja, con archivos y líneas de cada paso.
- **Después, en el mismo formato:** compra, conteo y cierre Z.
- Se registra en `master` (`docs/guias/`).
- **Pedido a A:** cuando la guía cite archivos y líneas de `feature/modelo-ng`, revisen que el recorrido es correcto; avisaremos con el commit.

**Pedido a A:** acuse de recibo, y en qué tanda empiezan a documentar los módulos de la venta y la caja.
