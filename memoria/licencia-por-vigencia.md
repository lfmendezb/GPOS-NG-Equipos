---
name: licencia-por-vigencia
description: "Pedido del propietario (2026-10-05): GPOS NG se vende como suscripción mensual; agregar vigencia de licencia por empresa (no por usuario) y decidir si hace falta un agente validador aparte"
metadata:
  type: project
---

El 2026-10-05 el propietario aclaró que GPOS NG se ofrece como **suscripción mensual** («SaaS» en sentido comercial; técnicamente sigue siendo una instalación por dueño, ADR-43) y pidió **vigencia de licencia que afecte a la empresa en conjunto**, además del cupo de usuarios de ADR-34, y saber si hace falta un **agente validador aparte**.

Orientación aceptada: archivo de licencia firmado por GSF (cliente, empresas, vencimiento por empresa, cupo de usuarios, módulos como el de análisis), gracia configurable, avisos previos, al vencer **solo consulta** (nunca bloquear consultar, imprimir ni exportar la historia: obligación fiscal), validación **dentro de la API** (no un servicio aparte), funcionamiento sin conexión con el reloj protegido, renovación por el **agente de actualización** (Drive) o carga manual, llave de licencias distinta de la de actualizaciones.

**Why:** modelo comercial por suscripción; sin vigencia no hay forma de cobrar ni de suspender.

**How to apply:** propuesta formal en curso (2026-10-05): arquitecto-software escribe `GPOS NG/docs/arquitectura/2026-10-05-licencia-por-vigencia.md`; luego revisión del auditor-seguridad y consolidación del arquitecto-maestro para firma. Encaja con la versión 1 del acceso multiempresa (licencia por empresa de ADR-34). Resolver junto con la gracia del módulo de análisis (K-AN-03).

Relacionado: [[actualizacion-automatica]], [[modulo-analisis-estrella]], [[decision-modelo-datos-propio-pendiente]].

**Estado (2026-10-05):** diseño v2 aprobado con observaciones por el auditor; decisión consolidada por el maestro en `GPOS NG/docs/decisiones/2026-10-05-decision-licencia-por-vigencia.md` (pendiente de firma). Para firmar ya: ADR-58 a 61 (huella solo de SQL Server; gracia especial que nunca mejora el estado; Release rechaza solo el anillo Desarrollo), P-L1 a P-L19 (P-L14 dividida en a/b; P-L19 cambia ADR-57 del módulo de análisis) y **H-16 v2 (reloj protegido)**, recomendado firmar ya porque la ola 3 lo necesita. Condiciones antes de implementar L1: CI-1 a CI-7; antes de la primera licencia de pago: CP-1 a CP-6 (suplente antes del 2026-11-30). Costo ~7,5 sp. L1a empieza el 2026-11-02 con un desarrollador dedicado en copia aparte, después del G-1 de la ola 2; si se usa el mismo desarrollador de la entrega 1, el corte pasa a ~2026-12-10. Hasta L4, renovación manual por correo.
- **2026-10-05:** el propietario comprará **dos YubiKey 5 FIPS 140-3** (unos USD 176) para las llaves de firma; anotado en la condición CP-1 de la decisión de la licencia, con los pasos del modo FIPS en la ceremonia.

**2026-10-07 (B-5 de ADR-73):** la licencia debe llevar una **cláusula de módulos contratados** (por ejemplo, conectores ERP o e-CF) que viaje con la vigencia y se pueda cambiar de forma dinámica. Hoy el conector se cobra como pago único en la implementación; lo comercial puede cambiar y **no debe alterar el calendario de desarrollo**. Junto con la licencia por empresa contando usuarios ([[sucursal-en-linea-sqlite-y-licencia]]), va en la precisión de ADR-58 por preparar.
