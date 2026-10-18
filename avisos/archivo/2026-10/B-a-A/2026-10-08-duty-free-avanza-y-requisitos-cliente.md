```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG master (d769848, c87c4cf); diseño en b/verticales-diseno
Estado: Abierto
```

# Duty Free avanza sin el cuestionario aduanal; requisitos del cliente; dos puntos para A

## 1. Precisiones del propietario en `master`
- **`c87c4cf`:** la **primera vertical es la Estándar**, que es el POS de la entrega 1. **Duty Free es la segunda** y la primera que se construye en la entrega 3. ADR-115 queda **Aceptado con condiciones**, confirmado por el propietario.
- **`d769848`, precisión de ADR-115:** Duty Free se diseña y se construye **sin esperar el cuestionario aduanal**. El propietario considera que es más administrativo que técnico. La **venta de llegada** se diseña con un tratamiento fiscal **parametrizable** por empresa.
- **El cliente real:** tres tiendas en aeropuerto que venden a pasajeros de salida y de llegada, sin mercado local.
- **El cronograma no cambia:** se construye en la entrega 3.

## 2. Diseño detallado de Duty Free en curso en B (solo `docs/`, rama `b/verticales-diseno`)
UX, software y datos. El cliente exige en la factura:
1. **Vendedor,** con dos parámetros:
   - uno que, al activarse, **impide guardar la factura sin vendedor**, validado en el servidor;
   - otro para el **modo de selección**: búsqueda estándar o **ventana emergente con un botón por vendedor**.
2. **Nombre del cliente,** con el mecanismo actual de nombre escrito sin crear el cliente en la maestra.
3. **Pasaporte, vuelo y nacionalidad.**

**Pide atención de A:** si los arquitectos de B proponen que los dos parámetros del vendedor sean **generales de la empresa** y no solo del modo Duty Free, tocarían la Facturación Ágil de la Estándar, que es código de A en la entrega 1. B lo avisará con la propuesta antes de que nadie lo construya.

## 3. Para la clasificación de empresas (pendiente de A, después de `master`)
El propietario pidió el 2026-10-08 que, cuando exista la clasificación de empresas (Desarrollo, Beta, Producción, Demostración), una empresa **de Desarrollo** tenga un **apartado solo para el SUPER** que permita pruebas como apuntar el conector de e-CF al **mock**. Hay tres condiciones:
- no debe poder activarse en Beta, Producción ni Demostración;
- debe quedar en la bitácora;
- no debe debilitar SD-15: el servicio instalado rechaza el simulador a propósito.

Para eso sirve, por ejemplo, un modo de pruebas que se active solo con la clasificación Desarrollo, o un servicio de pruebas aparte. Hoy no se construye ninguna herramienta de demostración.

## 4. Condición de V-3, para el plan
Al aprobar la biblioteca `GPOS.Componentes` (ADR-04), el propietario dejó pendiente **diseñar cómo agregar pantallas exclusivas de una empresa**. No tiene fecha. Lo anotamos para que no se pierda.
