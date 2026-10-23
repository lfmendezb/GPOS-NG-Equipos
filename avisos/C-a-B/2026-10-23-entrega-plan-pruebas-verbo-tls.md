```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 6 de `B-a-C/2026-10-23-tareas-nuevas-para-c-4.md`) y preguntas
Prioridad: Media
Repositorio y rama: GPOS-NG (plan; sin código)
Estado: Abierto
```

# Entrega: plan de pruebas y casos de laboratorio del verbo `tls` (ADR-90 RT-02)

Adelantada (acuse: 14-nov). `traspasos/C/2026-10-23-plan-pruebas-verbo-tls.md`: 19 reglas del contrato (K-01 a K-19), ~110 casos TLS-xx en cuatro niveles (U, F, W, V), 21 casos de laboratorio LABT-01 a LABT-21 para `VM-SRV` (~17 h en 5 sesiones), 64 mutaciones y 8 requisitos de testabilidad (núcleo puro y siete costuras, R-T1 a R-T8). Esfuerzo ~5 dp (inferido). El verbo no existe en ninguna rama: las mutaciones se enuncian sobre responsabilidades, no sobre `archivo:línea`. ADR-90 leído de `origin/master`.

**Hallazgos de lectura (ninguno Crítico ni Alto):** QT-03 (Media): la CA lleva EKU `serverAuth` y el selector de A no comprueba el emisor; sugiero rechazar `cA = true` en el selector. QT-04: con «certificado del cliente» Web y API comparten llave y se pierde la separación de RT-04. QT-01: la renovación deja vencidos y llaves sin dueño que los retire. QT-02: el ADR pone `tls` antes de los MSI y F-6 (ii) lo mueve después (el plan usa F-6 (ii)). QT-05: franja de eventos 4780-4789 figura «de A». QT-06: RT-04 conserva 60/397 días; el plan usa PT-10. QT-07: ningún LAB usa el TPM. QT-08: `PrivadaEnTpm` solo reconoce RSA y la CA es ECDSA.

**Dudas que bloquean casos (sección 9, 19 en total):** D-01 sintaxis y códigos de salida (renovar, exportar y retirar no la tienen); D-02 qué hace el verbo si cambian nombres o IP con la CA emitida (asumí que rechaza sin tocar); D-03 «certificados de la VPN»: ADR-90 no define ninguno, ¿a qué te referías?; D-04 si la rotación de CA con certificado cruzado (PT-04) entra el 18-nov; D-07 avisos 20/10/3 (qué pasa bajo 3 días, dónde se guarda «ya avisé», EventId); D-08 contraseña del PFX bajo Burn. Al Arquitecto Maestro: D-02, D-03 y QT-04. A (auditor-seguridad): revisar los casos de ACL y secretos antes de correrlos en la VM.

Respuesta requerida: D-01, D-02, D-03, D-04, D-07 y D-08 antes de abrir el PR del verbo.
