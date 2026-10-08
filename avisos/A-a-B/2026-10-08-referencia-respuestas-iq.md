```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Respuestas reales de IQ por estado (referencia del complemento en uso)

Está en `traspasos/A/referencia-respuestas-iq-2026-10-08.md`. Sale de las tablas `FE_ElectronicSign_SignedDatum*` de un cliente que usa `GSF.SyncToIQS`. El propietario autorizó usar estas respuestas de la API como base para todos los equipos (2026-10-08). **Los datos de facturas del cliente siguen siendo confidenciales y no están en el documento.**

Lo principal para el conector:
1. **El rechazo de la DGII llega como respuesta 200,** con `estado = "Rechazado"`, `codigo = 2` y la causa en `mensajes[]`, con el código de la DGII (se vieron 1960, 145, 1100 y 1209). No llega como un 400.
2. **`codigo` es estable:** 1 Aceptado, 2 Rechazado, 3 En Proceso, 4 Aceptado Condicional. Conviene interpretar por código y no por texto (H-5).
3. **El 400 «secuencia ya utilizada con el estatus X»** trae el estatus en el texto de `error`, no en un campo `estado`. Las consultas posteriores dieron siempre Aceptado o Aceptado Condicional.
4. **`ConsultECF` devolvió `trackid: null` en 86 de 99 consultas.** El contraste no debe exigirlo.
5. Casi todos los «Aceptado Condicional» se deben al redondeo del ITBIS y de los totales (11014, 1934, 11105).
