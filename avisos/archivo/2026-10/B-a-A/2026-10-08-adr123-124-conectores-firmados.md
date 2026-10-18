```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso (registro en master)
Prioridad: Alta
Repositorio y rama: GPOS-NG master (afa7519)
Estado: Abierto
```

# ADR-123 y 124 (conectores) firmados y registrados en master

El propietario firmó la hoja de los conectores («Todo según recomendación») y precisó PO-01 después de la firma: el precio de Polaris no detiene el desarrollo, y la custodia del XML la garantiza Polaris por contrato, igual que IQ. Registro en master `afa7519`:
- **ADR-123:** ambiente productivo de todo conector. Solo en Release, fuera del perfil de pruebas, con parámetro sin valor por omisión y credencial marcada. IQ quita `Produccion` por omisión.
- **ADR-124:** conector de e-CF con Polaris EDI, aceptado con condiciones. Sin puerta comercial. Pasa a preferido frente a IQ, para los clientes sin AdmCloud, al pasar la puerta técnica C-3 a C-6. El cliente de AdmCloud emite por AdmCloud (PO-02). B lo construye después de K1.
- **Precisiones:**
  - ADR-51: un solo emisor de e-CF por empresa, con «Sustituir el emisor»; custodia y autorización de la DGII exigidas a todo proveedor.
  - ADR-58: el alta del conector la hace solo el SUPER, también después de la v1; empresa con e-CF y sin conector, solo aviso; empresas de Demostración sin conectores.
  - ADR-59: GS-P4, con los límites del auditor.
  - ADR-108: el núcleo decide por campos canónicos, nunca por códigos `ECF-IQ-…`; kit común.
  - ADR-116 (`ECF_REQUIERE_ERP`), ADR-117 y nota en ADR-73 (73.7.3).
- Antecedentes en `docs/integraciones/`: diseño de Polaris y guardas por superficie.

## Para el núcleo (sección 9 de la hoja)
- Las guardas A-GS-1 a A-GS-8 (aviso `lic-v32-y-guardas-por-superficie`).
- **El punto 8 (C-PO-6) se aplica antes de diseñar T-29c.**
- La guarda de un solo emisor, con «Sustituir el emisor» (0,07 sp).

## Texto propuesto para `CLAUDE.md` (línea de ADR de «Documentación», antes del paréntesis final)
«; ADR-123 y 124 (equipo B), firmados el 2026-10-08 con la hoja de los conectores (`docs/decisiones/2026-10-08-hoja-firma-conectores-polaris-guardas.md`, «Todo según recomendación»): ambiente productivo de todo conector solo en Release, fuera del perfil de pruebas, con parámetro sin valor por omisión y credencial marcada; IQ quita `Produccion` por omisión (ADR-123), y conector de e-CF con Polaris EDI, aceptado con condiciones (ADR-124). Por la precisión del propietario a PO-01, posterior a la firma, no hay puerta comercial: Polaris se puede construir sin esperar sus respuestas y pasa a ser el preferido frente a IQ para los clientes sin AdmCloud al pasar la puerta técnica (C-3 a C-6); el cliente de AdmCloud emite por AdmCloud (PO-02). Precisan ADR-51 (un solo emisor de e-CF por empresa con «Sustituir el emisor»; custodia y autorización de la DGII exigidas a todo proveedor), ADR-58 (el alta de un conector la hace solo el SUPER, también después de la versión 1; aviso de empresa con e-CF sin conector, sin bloquear la venta), ADR-59 (renovar las credenciales del conector de e-CF en solo consulta con los límites del auditor), ADR-108 (el núcleo decide por campos canónicos, nunca por códigos `ECF-IQ-…`; kit común), ADR-116 (`ECF_REQUIERE_ERP`) y ADR-117, con nota en ADR-73 (73.7.3); decididos, no implementados; ADR-125 a 129 libres»
