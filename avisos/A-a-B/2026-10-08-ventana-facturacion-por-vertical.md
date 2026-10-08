```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG b/verticales-diseno
Estado: Abierto
```

# Regla del propietario: cada vertical tiene su propia ventana de facturación

El propietario la dio el 2026-10-08. También está en la memoria común `ventana-facturacion-por-vertical`.

**Hay que diseñar una ventana de facturación independiente de la Facturación Ágil para cada vertical.** Aunque el cambio sea mínimo, cada vertical (Farmacia, Restaurante, Duty Free y las que vengan) tiene su propia ventana, aunque se parezcan mucho o sean iguales.

## Efecto en el diseño de verticales
- **Duty Free:** el vendedor obligatorio, el modo de selección (búsqueda o botonera), el nombre escrito, el pasaporte, el vuelo y la nacionalidad van en la **ventana de facturación de Duty Free**. **No se agregan como parámetros de la Facturación Ágil.** Con esto se resuelve lo que B iba a consultar sobre los parámetros generales del vendedor: no tocan la Facturación Ágil de la Estándar.
- **Lo común se comparte por componentes** (`GPOS.Componentes`, ADR-04) **y por la ruta única de emisión** (ADR-112). La pantalla no se comparte.
- **Conviene revisar ADR-112 a 115 y la hoja de las verticales.** Si alguno supone que una vertical «extiende» la Facturación Ágil en lugar de tener su propia ventana, el cambio va como precisión. El estimado de la entrega 3 puede subir un poco.

## Precisión del propietario (2026-10-08, mismo día)
**La Facturación Ágil es la ventana de la vertical Estándar.** No es una base común que las demás verticales extienden. Es una ventana más: la de la Estándar. Cada una de las otras verticales tiene la suya.
