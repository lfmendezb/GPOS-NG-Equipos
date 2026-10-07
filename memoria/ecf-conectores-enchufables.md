---
name: ecf-conectores-enchufables
description: "2026-10-07: e-CF y ERP (AdmCloud, Alegra, IQ Solution) como complementos enchufables que NUNCA tocan el núcleo de GPOS NG"
metadata:
  node_type: memory
  type: project
  originSessionId: fa904a7c-caf5-4d97-b5b8-dcb33eed2e83
  modified: 2026-10-06T23:48:49.079Z
---

El propietario (2026-10-07) informó que hoy GPOS VB6 (BP2) emite e-CF por dos complementos en producción:
- **AdmCloud** (`C:\Users\lfmen\source\repos\IGpostAC`): AdmCloud firma y envía; los clientes que ya usan AdmCloud siguen con esa vía.
- **IQ Solution** (`C:\Users\lfmen\source\repos\GSF.SyncToIQS` y `GSF Sync Transfer`): su API permite al POS firmar directamente.

Decidió que GPOS NG tenga una **solución enchufable, desacoplada**, para que núcleo y conectores evolucionen de forma independiente. Análisis encargado al arquitecto-integraciones (`docs/integraciones/2026-10-07-ecf-enchufable.md` en `feature/modelo-ng`).

**Why:** la DGII exige e-CF exclusivo desde el 2026-11-01 (Grandes Locales y Medianos) y el 2026-11-15 (Pequeños, Micro y No Clasificados), según HC-01 del análisis contable; el primer cliente no puede facturar sin e-CF.

**How to apply:** no acoplar GPOS NG a un proveedor; contrato estable en el núcleo y un conector por proveedor versionado aparte. Esos repositorios del propietario son de solo lectura para los agentes y pueden tener secretos: nunca copiar valores. Relacionado: [[actualizacion-automatica]], [[fips-y-perfiles-seguridad]], [[sin-access-ni-texto-plano]].

**Regla absoluta del propietario (2026-10-07):** las integraciones con AdmCloud, Alegra o cualquier otro proveedor (ERP o e-CF) son **complementos que no tocan el núcleo de GPOS NG bajo ninguna circunstancia**: nada de código, dependencias, nombres ni URL de proveedores en el núcleo; los complementos no acceden a la base; agregar o quitar un conector no cambia ni redespliega el núcleo; el núcleo solo expone un contrato genérico y versionado. Va como cláusula de ADR-73.

**2026-10-07:** el propietario aclaró que su complemento `GSF.SyncToIQS` **ya cumple con IQ Solution** en producción: el conector de GPOS NG lo replica (el contrato se toma de ese código; no hace falta esperar documentación de IQ), con las mejoras de diseño (reintentos, idempotencia, E33, contingencia, XML firmado) y **sin repetir** sus hallazgos de seguridad (SEC-02, 03, 06, 08). Pruebas solo con mock local.

**Regla del propietario para el JSON del e-CF (2026-10-07):** el JSON que se envía a IQ (y a cualquier proveedor) contiene **exclusivamente los campos que aplican** a ese tipo de documento y a esos datos. **Nunca se envía un campo en `null` ni vacío**: la DGII lo rechaza (ejemplo: no se envía `ITBIS16` en null si ningún artículo del detalle lleva ITBIS al 16 %). Los campos condicionales (tasas de ITBIS, retenciones, descuentos, montos exentos, referencia a NCF modificado, comprador, etc.) solo aparecen cuando hay dato. La serialización omite nulos y los campos opcionales se incluyen por regla del formato e-CF v1.0 y del tipo (E31, E32, E33, E34, E41, E43, E44, E45, E46, E47). El mock local debe rechazar un campo nulo o que no corresponde al tipo.

**Decisión (2026-10-07):** el conector de IQ es **nuevo, más robusto y solo para GPOS NG**, en un **repositorio nuevo** (propuesta `GPOS-Conector-IQ`), construido por el **equipo B** (nota `paquete-pc-b\traspaso-B-2026-10-07-conector-iq.md`). `GSF.SyncToIQS` queda como referencia de lectura y GPOS VB6 sigue con su complemento actual. El contrato genérico en el núcleo lo hace el equipo A después de la ola 4.
