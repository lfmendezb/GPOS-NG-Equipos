---
name: conector-polaris-preferido
description: "2026-10-08: conector de e-CF Polaris EDI (firmado directo), posible solución preferida antes que IQ; diseño encargado en cuanto haya lugar en la PC B"
metadata:
  type: project
---

El propietario (2026-10-08) agregó **Polaris EDI** como conector de e-CF firmado directo, similar al de IQ, y dijo que **«hasta puede que este sea nuestra solución preferida antes que IQ»**. Ordenó lanzar su diseño (arquitecto-integraciones, Opus) **en cuanto haya lugar** en la PC B, sobre el mismo núcleo común de conectores.

**Why:** Polaris tiene documentación pública y ambientes propios: 0 Desarrollo (sin empresa ni certificado), 1 Pruebas DGII, 2 Certificación y 3 Producción, todos en el mismo dominio y elegidos por el parámetro `ambiente`. IQ solo se prueba con mock y su prueba elevada está aplazada.

**How to apply:**
- Complemento enchufable que no toca el núcleo (ADR-73.7), con el módulo `CONECTOR_ECF`.
- Guardas: el ambiente 3 solo en Release con perfil de producción, y las pruebas automáticas fijas en 0.
- El token de acceso viaja en la query: nada de URL completas en bitácoras.
- Pruebas con mock local más el ambiente 0, este solo bajo pedido.
- Si el diseño confirma la ventaja, preparar con el arquitecto-maestro la recomendación de prioridad Polaris frente a IQ para que el propietario la firme.

Relacionado: [[ecf-conectores-enchufables]], [[referencias-api-erp]], [[pruebas-proveedores-con-mock]].

**Precisión del propietario (2026-10-08):** Polaris y AdmCloud son de la misma familia de empresas, pero el propietario no sabe si comparten todo: verificarlo contra la documentación, sin darlo por supuesto. El diseño debe comprobar qué comparte con la superficie e-CF de AdmCloud (ADR-116): el formato JSON, los códigos de estado y quizá el mismo motor de firma. También debe ver si el mapeo puede ser común en el núcleo de conectores, sin perder la independencia de cada conector, y cómo conviven `CONECTOR_ERP` (AdmCloud) y `CONECTOR_ECF` (Polaris) en una misma empresa, sin enviar dos veces el mismo e-CF.

**Alcance (propietario, 2026-10-08):** el cliente que tiene AdmCloud **no necesita Polaris**; emite su e-CF por AdmCloud. Polaris es para clientes de GPOS NG sin AdmCloud que necesitan integrar facturación electrónica, como el servicio de IQS. Polaris compite con IQ, no con AdmCloud. PO-02 = no.

**Firma de la hoja de conectores (2026-10-08, «todo según recomendación») y precisión del propietario:** el precio de Polaris **no detiene el desarrollo** del conector (es un asunto entre el cliente y Polaris; paga el cliente). Polaris garantiza por contrato la custodia del XML, igual que IQ. Sin puerta comercial: el conector se puede construir ya. ADR-123 es la norma del ambiente productivo y ADR-124 el conector Polaris. La puerta técnica (C-3 a C-6) decide cuándo pasa a preferido frente a IQ.

**Repositorios (propietario, 2026-10-09):** son tres repositorios privados, porque «cada uno evoluciona a un ritmo distinto»: `lfmendezb/GPOS-NG-AddOn-Kit` (kit común, paquete `GPOS.AddOn.Kit` con versión), `lfmendezb/GPOS-NG-AddOn-IQS` (conector IQ; era público y se pasó a privado el 2026-10-09) y `lfmendezb/GPOS-NG-AddOn-Polaris`. Las copias locales están en la carpeta `repos` del usuario, junto a `Solucion GPOS NG`. Construcción de Polaris: después de K1. Primero se extrae el kit desde IQ 0.4.2 y luego se arma Polaris sobre ese kit.

**Canal (propietario, 2026-10-09):** solo el canal JSON (`/{Tipo}/Firmar`, Polaris firma y custodia). Se **desestimó** `/ComprobantesElectronicos/Enviar` (XML propio firmado con el .p12 del cliente); no volver a proponerlo salvo que el propietario lo reabra. Registrado en ADR-124 (master 1ad8b9e). PQ-25: la guía «Inicio rápido» se siguió tal cual y falla; la vía sugerida es una empresa de pruebas registrada en el portal de Polaris (ambiente 1).
