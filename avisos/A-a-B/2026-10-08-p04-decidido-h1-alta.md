```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# P-04 y el 400 de IQ: decisiones del propietario y un defecto Alto en el conector (H-1)

Responde a la sección 3 de `avisos/B-a-A/2026-10-07-conector-iq-040-para-el-nucleo.md`. El detalle del arquitecto-integraciones de A está en `traspasos/A/respuestas-A-integraciones-p04-400-2026-10-08.md`.

## Decidido por el propietario (2026-10-08)
- **P-04, aceptado:** el «409 con el estado real» de K-18 llega como **resultado diferido** de la generación, con `ECF-IQ-0033`, no como código del `POST`. El núcleo deja la generación en `VERIFICANDO` y la sondea. No cambia nada firmado: el documentador de A registra la precisión de K-18 en ADR-108, punto 2, como segunda excepción a la regla 409.
- **P-04-a, Sí:** si al reenviar desde un `CONFLICTO` resulta que la DGII ya rechazó el e-NCF, el documento se **anula automáticamente**, con la regla de la anulación por rechazo y sus condiciones A, B y C.
- **P-04-b, Sí:** si el e-NCF ya está **aceptado**, el núcleo adopta ese estado tras el contraste.
- **H-1 se corrige antes de la prueba elevada.** El propietario envía P-02 a IQ con el texto de la sección 2.4 de la respuesta.

## Para el conector
- **H-1 (Alta):** después de `ECF-IQ-0012` (el 400), dos consultas «no encontrado» llevan la operación a `PENDIENTE` y **reenvían el mismo cuerpo** hasta 8 veces, y terminan en `AGOTADA` (`ProcesadorEmision.cs:783-797`). Eso contradice K-18.
  - **Corrección:** con origen 400, el primer «no encontrado» va a `CONFLICTO` (`ECF-IQ-0400`), sin reenvío.
  - **Prueba:** «400 con `estado` + no encontrado = `CONFLICTO` y una sola llamada a `SendECF`».
- **En la entrega siguiente:**
  - **H-2 (Media):** el resultado no trae el timbre, y no hay seguimiento si el estado real es `EN_PROCESO`.
  - **H-3 (Media):** un segundo «Reenviar corregido» se vuelve a admitir y vuelve a dar `ECF-IQ-0033`, en ciclo.
  - **H-6 (Media, inferido):** un «secuencia ya utilizada» en el primer envío puede adoptar el estado de otro documento. Hace falta un contraste antes de adoptarlo.
  - **H-4 (Baja):** alinear el texto de la sección 19.2 con estas decisiones.
  - **H-5 (Baja):** cualquier valor de `estado` dispara la consulta. Conviene limitarlo a los estados de la tabla de IQ.

P-05, el manifiesto, las carpetas y P-01 van en otro aviso, cuando terminen los agentes de A.
