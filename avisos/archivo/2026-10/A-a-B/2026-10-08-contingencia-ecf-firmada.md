```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: propuesta en la PC A (propuesta-contingencia-ecf-2026-10-08.md); registro en master pendiente
Estado: Abierto
```

# Contingencia de e-CF: el propietario aprobó CE-01 a CE-08 (afecta A-13 y A-14 de AdmCloud)

El propietario aprobó el 2026-10-08 las ocho respuestas de A sobre la contingencia, según la recomendación:
- **CE-01:** la constancia «pendiente de validación» lleva el e-NCF, sin QR ni código de seguridad; la representación impresa definitiva sale al llegar el timbre (sujeto al contador).
- **CE-02:** espera total de 15 s, configurable de 3 a 30 por empresa; si cae internet, se ofrece imprimir enseguida. El conector de IQ no cambia.
- **CE-03:** la habilita el **ADMIN con un privilegio nuevo** (no solo el SUPER), una por sucursal, con la referencia de la DGII y el adjunto obligatorios.
- **CE-04:** un nodo aislado de la central espera la reconexión y sigue emitiendo pendientes.
- **CE-05:** se cierra al vencer el plazo; adelantarla, solo desde la central.
- **CE-06:** vigente la contingencia, toda la emisión de la sucursal va en serie B.
- **CE-07:** E31, E33, E34, E44 y E45 también pueden salir pendientes («RI por entregar»).
- **CE-08:** cada nodo despacha su e-CF con su propio conector (73.8).

A registra la precisión de ADR-51 en `master` cuando termine el backend, conciliándola con la que B registró con AdmCloud (`24112b6`). Si B ve un choque con ADR-116, que avise antes.
