---
name: fips-y-perfiles-seguridad
description: "Pedido del propietario (2026-10-05): toda la criptografía del sistema endurecida para FIPS 140-3 y un interruptor Seguridad Básica / Seguridad Avanzada (FIPS), excluyentes, empezando por la firma de licencias"
metadata:
  node_type: memory
  type: project
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-05T18:46:42.738Z
---

El 2026-10-05 el propietario pidió: «todo lo que esté cifrado por el sistema esté reforzado y endurecido para FIPS y cumplimiento», con una alternativa inicial menos segura pero funcional para firmar licencias, como **interruptor: Seguridad Básica y Seguridad Avanzada (FIPS); si una está activa, la otra se detiene**. Compra dos YubiKey 5 FIPS 140-3 (condición CP-1 de la licencia).

**Why:** cumplimiento y credibilidad ante clientes y contratos desde el principio, sin bloquearse mientras llegan las llaves.

**How to apply:**
- Al pasar a Avanzada, la llave básica debe quedar **retirada en todas las instalaciones** (retiro de `kid`), no solo apagada en el equipo de GSF; el regreso a Básica no debe abrir una puerta (por ejemplo, autorizado solo por la llave avanzada).
- En las instalaciones, un perfil que solo **restringe** (algoritmos y módulos aprobados) es compatible con la regla del auditor de no tener interruptores que desactiven controles (LV-07/C-4).
- Usos con cifrado propio sin validación FIPS a revisar: 7-Zip AES y LiteDB en la herramienta de respaldos; MD5 como suma de Drive es uso no criptográfico.
- En curso (2026-10-05): inventario criptográfico y brecha FIPS del auditor-seguridad en `GPOS NG/docs/seguridad/2026-10-05-inventario-cripto-y-brecha-fips.md`; después diseño del arquitecto-software y consolidación del maestro.

Relacionado: [[licencia-por-vigencia]], [[actualizacion-automatica]], [[sin-access-ni-texto-plano]].

**Estado (2026-10-05):** inventario del auditor listo (lo de GPOS NG ya usa algoritmos aprobados vía CNG; brechas en 7-Zip, SMTP, NTLM y `TrustServerCertificate`; Altos FP-01 contraseña de 7-Zip en la línea de comandos en Backup Tool y FP-02 Web del demo por HTTP en la red). Diseño del arquitecto en `GPOS NG/docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md`: dos interruptores (firma de GSF Básico con TPM / Avanzado con YubiKey FIPS; perfil de la instalación que solo restringe), caducidad técnica del modo Básico desde el 2026-12-31, regreso a Básico solo para licencias con autorización de la llave Avanzada, **cuatro YubiKeys FIPS** (dos para licencias y dos para el manifiesto, unos USD 352), **ceremonia CP-1 adelantada: objetivo 2026-11-13, límite 2026-12-04**, ADR-62 a 66 y preguntas P-F1 a P-F14. ~5,1 sp. Revisión del auditor en curso; luego consolidación del maestro junto con la licencia y H-16.

**Actualización (2026-10-05):** diseño v1.1 (P-F1 a P-F19, ~5,9 sp) **Aprobado con observaciones** por el auditor; PFS-01 cerrado; condiciones D-1 a D-5 (CV-01 a CV-03; D-1 y D-2 antes de la enmienda `[LIC]` del 2026-10-16). Declarar FIPS o activar Avanzada sigue Rechazado mientras FP-01, FP-02 y §12.6 estén abiertos. Hoja única **FIRMADA COMPLETA por el propietario el 2026-10-05** (ADR-58 a 66, H-09, H-16 v2.1, H-17 v2, precisión H-05; Q-19 (a): mini-PC emisor 8.ª gen+ con Secure Boot, no el equipo de desarrollo DEVLAB00 i5-7500T; pruebas del modo FIPS en VM o mini-PC; ~13,6 sp en total; FY-01..16, Q-01..25, AI-01..09, AP-01..10; hallazgos: H-16/H-17 sin firmar, `GPOS.Criptografia` choca con H-05, H-09 urgente): `docs/decisiones/2026-10-05-hoja-firma-seguridad.md` (licencia + H-16 + FIPS). Precisiones P-01 a P-03 (`docs/decisiones/2026-10-05-precisiones-tras-hoja-seguridad.md`) firmadas el 2026-10-05; A-1 a A-3 (aceptación de riesgos CP-4, CP-5, R-L11/R-F11) se firman tras R-E11 en verde y antes de la primera licencia de pago. Renovación automática = L4, depende de la propuesta formal del agente de actualización (no pedida aún).
