```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Comportamiento de IQ confirmado por el propietario: sin duplicados, rechazo con causa y dos rutas de consulta

El propietario informó el 2026-10-08 cómo se comporta la API de IQ. A lo verificó en el complemento `GSF.SyncToIQS`.

1. **IQ no admite duplicados.** Si el e-NCF ya fue emitido, `SendECF` responde 400 `{"error":"Esta secuencia ya ha sido utilizada con el estatus <X>."}`.
   - En el complemento: `DocumentSignService.cs:119-125` y el ejemplo de `SignDocumentController.cs:65`.
   - El conector ya reconoce el prefijo (`FormasIq.cs:52`).
2. **Rechazo de la DGII.** Si la DGII ya rechazó el e-CF, IQ lo rechaza al reenviarlo y devuelve el mensaje y la causa. El complemento solo documenta el caso «Aceptado». La forma exacta del rechazo (400 o 200, y dónde vienen los mensajes) no está escrita: el propietario la confirma con IQ.
3. **Consultas.** `ConsultECF/FC/emitidos` es para E32 y `ConsultECF/eCF/emitidos` para los demás tipos. El conector ya lo hace (`ClienteIq.cs:265`).

## Qué cambia para el conector
- **«Secuencia ya utilizada con el estatus X» es un dictamen, no un `CONFLICTO`:**
  - con «Aceptado», se aplica **P-04-b**: adoptar ese estado tras el contraste;
  - con «Rechazado», se aplica **P-04-a**: anulación automática, con la causa que devuelva IQ guardada como evidencia.

  Solo el 400 de validación sin estatus queda en `CONFLICTO` (K-18).
- **La defensa del campo `estado` en el 400 (`EstadoEnError`) no se dispararía con la forma real.** El estatus viene en el texto de `error`. Hay que extraer *X* del texto, con una tabla cerrada de valores (H-5); un valor fuera de la tabla va a `CONFLICTO` con alerta.
- **H-1 sigue en pie:** después de un 400 de validación, «no encontrado» va a `CONFLICTO`, sin reenvío.
- **Lo que sigue preguntándose a IQ:**
  - P-02 puntos 2, 3, 5 y 6;
  - la forma exacta de la respuesta de rechazo;
  - IQ-P1 (el TrackId de la DGII) e IQ-P3 (`CancelECF`).

  Los puntos 1 y 4 de P-02 quedan respondidos en parte.
