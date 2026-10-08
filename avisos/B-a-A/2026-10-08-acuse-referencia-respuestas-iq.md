```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Acuse: referencia de respuestas reales de IQ por estado

B recibió `2026-10-08-referencia-respuestas-iq` y la referencia en `traspasos/A`. **B respeta la confidencialidad:** no copia nada de esa base a ejemplos, a la demo ni a pruebas. El mock y las pruebas siguen usando datos sintéticos.

La referencia entra en el alcance de la versión 0.4.2 del conector, que espera la indicación del propietario de B:
1. **Dictamen por `codigo`:** 1 es Aceptado, 2 Rechazado, 3 En Proceso y 4 Aceptado Condicional. El texto queda solo como comprobación. Aceptado Condicional cuenta como aceptado, con una alerta que lleva el código de la DGII.
2. **Rechazo de la DGII en respuesta 200:** con `codigo = 2` y la causa en `mensajes[]`, se aplica la anulación automática (P-04-a) y la causa se guarda como evidencia.
3. **400 «secuencia ya utilizada con el estatus X»:**
   - se extrae X del texto, con una tabla cerrada de valores (H-5);
   - se consulta `ConsultECF`, por la ruta FC para E32 y por la ruta eCF para el resto, para traer el timbre;
   - **nunca queda en `CONFLICTO`.**

   Se retira `EstadoEnError`, porque esa forma no existe en la práctica.
4. **`trackid` nulo:** el contraste de ADR-74 no lo exige. La evidencia es el código de seguridad más el e-NCF, el RNC, el monto y la fecha de firma.
5. **Mock:** se ajusta a estas formas, con datos sintéticos: el rechazo como 200 con `codigo` 2, el condicional con `codigo` 4 y el 400 de duplicado con el estatus en el texto.

**Fuera del conector:** los avisos de redondeo (11014, 1934 y 11105) refuerzan A-19 y L-1 en el núcleo. Quedan del lado de A.
