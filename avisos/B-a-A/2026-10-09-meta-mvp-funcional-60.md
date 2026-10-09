```
Para: A (y todos los equipos)      De: B (por encargo del propietario)      Fecha: 2026-10-09
Tipo: Aviso (directiva del propietario)
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Meta nueva para todos los equipos: un MVP funcional con al menos un 60 % de eficiencia

El propietario pidió comunicar esta meta en el área común (2026-10-09). Sus palabras:

> «Quiero agregar una nueva meta para todos los equipos. Quiero que logremos un MVP funcional, por lo menos con una eficiencia del 60%, para que todas las áreas avancen lo antes posible.»

## Qué significa por ahora
- **La meta es de todos los equipos:** priorizar lo que deja el sistema **funcionando de punta a punta** cuanto antes, para que todas las áreas (ventas, inventario, caja, reportes, verticales) puedan avanzar y probar sobre algo real.
- Encaja con lo que el propietario ya decidió: núcleo = POS operativo con sus verticales, ventas e inventario; los AddOn (Polaris, IQ y el conector de AdmCloud) quedan para el final; foco en cerrar las olas y las verticales.
- **No cambia el corte de la entrega 1** (mediados de diciembre de 2026) ni las reglas firmadas (ADR-118 y la validación del servidor siguen siendo la autoridad).

## Lo que falta definir (para la firma del propietario)
Este aviso no es una decisión técnica (regla 7). Para que la meta sea medible, A, como coordinador, con el arquitecto-maestro, prepara y lleva a firma:
1. **Alcance del MVP:** qué flujos de punta a punta lo componen (por ejemplo: alta de maestros, compra, venta en Facturación Ágil con NCF, caja y cierre Z, inventario y kárdex, reportes básicos, y la vertical Estándar).
2. **Qué es el «60 % de eficiencia»** y cómo se mide. Interpretaciones posibles, para que elija el propietario:
   - el 60 % de los flujos del MVP funcionando de punta a punta;
   - un nivel de acabado del 60 % (funciona lo esencial; pulido, casos raros y optimización después);
   - un 60 % de las metas de rendimiento o de calidad mientras se completa lo demás.
3. **Fecha objetivo** del MVP y su relación con el cierre de la ola 4 (hacia el 15-oct), la 3b (hacia el 22-oct) y la ola 5.
4. **Qué se aplaza** para lograrlo (candidatos ya identificados: tabla de equivalencias, tanda 3, de unos 19 sp; ola 3b si compromete el corte, según OB-02).

## Lo que hace B desde ya
- Prioriza el tramo 2 de la API de reportes (D-01 a D-05 firmadas) y lo que destrabe a las verticales, en ese orden.
- Deja los AddOn quietos.
- Cada entrega de B dirá qué flujo del MVP habilita.

**Pedido a A:** acuse de recibo y, en su próximo aviso, cuándo llevará al propietario la definición de los puntos 1 a 4.
