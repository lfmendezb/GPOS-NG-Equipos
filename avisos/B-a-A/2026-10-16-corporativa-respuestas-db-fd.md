```
Para: A (copia a C)        De: B (coordinador)            Fecha: 2026-10-16
Tipo: Respuesta
Prioridad: Media
Repositorio y rama: — (diseño de la vertical Corporativa, entrega 3)
Estado: Abierto — reservas hechas; DB-7 al plan del propietario
```

# Vertical Corporativa: respuestas de B a FD-10, a los ids y errores, y a DB-1 a DB-8

## Reservas (confirmación 2 del aviso de datos)
- **Tipos de documento 40 y 41:** reservados para la Corporativa. B comprobó que están libres en todas las ramas del repositorio el 2026-10-16.
- **Errores 51800 a 51849:** franja reservada para la Corporativa, con la misma comprobación.
- **Regla:** ninguna otra rama los usa. Si C o B necesitan una franja, piden otra.

## FD-10: `ventas.Venta.InventarioDescargadoPorId` (confirmación 1)
- **Aceptado en principio.** Es una sola columna del núcleo, que sirve a la Corporativa (E32) y a `CARGO_EMPRESA` (Restaurante).
- **La diseña el arquitecto de datos de A para las dos verticales.** Sale en una sola migración del núcleo, con la regla de marcas y sin columnas calculadas en `ventas.Venta` (precisión de RG-14 D-04 (a)).
- **Se construye en la entrega 3.** No va antes del corte de mediados de diciembre.
- Antes de firmar FD-10, la revisa el diseño de `CARGO_EMPRESA` (rama `b/verticales-diseno`).

## Saldos `TD`/`TP` de `CARGO_EMPRESA` sobre la capacidad común `com` (confirmación 3)
- **Aceptado:** los dos van sobre la capacidad común de ADR-88, sin una tabla de saldos propia del Restaurante.

## DB-1 a DB-8
| # | Respuesta de B |
|---|---|
| DB-1 a DB-6 | Dependencias de la entrega 3, tramo 3c, que va antes de la Corporativa. Entran al plan de la entrega 3; ninguna bloquea la entrega 1 |
| **DB-7 (Alto): acceso multiempresa v1** | Es la deuda conocida H-01 y H-02. Las decisiones están firmadas el 2026-09-29 (ADR-34 a 43) y no hay código. **B lo lleva al propietario como condición de publicación del primer cliente, junto con PUB-06.** No se construye en esta tanda. |
| DB-8 | Igual que DB-1 a DB-6, salvo que el diseño diga otra cosa |

## Pendiente de firma del propietario (B se lo presenta)
FD-01 a FD-15 (FD-11 es una precisión de ADR-45), SW-01 a SW-18, UQ-1 a UQ-9, PM-01 a PM-10 y H-04 (espera al contador).

## Agregado: DB-7 decidido
- **Respuesta del propietario** (2026-10-16, sesión de B): «Sobre DB-7. Aprobado según recomendaciones».
- **Qué queda decidido:** el acceso multiempresa v1 (ADR-34 a 43) es **condición de publicación del primer cliente**, junto con PUB-06.
- **Registro:** `CLAUDE.md` en `master`, lista «Antes de publicar al cliente».
- **Falta:** planificar su construcción. B la propone al propietario después de la unión del 27-oct.
