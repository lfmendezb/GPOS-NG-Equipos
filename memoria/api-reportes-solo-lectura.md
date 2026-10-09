---
name: api-reportes-solo-lectura
description: "Orientación del propietario (2026-10-07): API de reportes aparte, en paralelo a la principal, solo lectura sobre vistas rpt; persistencia solo en la API principal; mismo principio para el módulo de análisis"
metadata:
  node_type: memory
  type: project
  originSessionId: befce104-4e9f-475e-b511-89ad28246638
  modified: 2026-10-08T00:56:56.021Z
---

El 2026-10-07 el propietario formalizó ante el equipo B una idea que había conversado con A sin dejarla registrada:
- La **API de reportes corre aparte**, en paralelo a la API principal.
- **Solo lectura por usuario**, y solo sobre las **vistas** (`rpt`).
- **Toda la persistencia se queda en la API principal**: definiciones, formatos y configuración.
- El **módulo de análisis** puede seguir el mismo principio.

**Why:** si alguien intenta atacar con un script malicioso a través de los reportes o de los formatos personalizados, no puede dañar la base de datos, porque esa capa no tiene permiso de escritura. Lleva al nivel del proceso el aislamiento de ADR-38 y ADR-40.

**How to apply:**
- Es una orientación, no una firma: debe convertirse en ADR.
- Es requisito del diseño de la ola 5.
- Hay que precisar cuatro puntos:
  - la licencia, porque ADR-58 dice que se valida dentro de la API;
  - la autenticación con el JWT y la lectura de `GPOS_SYSDATA`;
  - las rutas `/api/reportes` e `/api/impresion`;
  - si va en los nodos.
- Aviso a A: `avisos/B-a-A/2026-10-07-api-reportes-solo-lectura.md`.

Relacionado: [[modulo-analisis-estrella]], [[motor-reportes-blazor-pendiente]], [[licencia-por-vigencia]].

**Respuestas del propietario (2026-10-07):**
- El acceso lo gestiona el sistema: el usuario entra con su sesión normal y rigen los permisos de `GPOS_SYSDATA`, que la API de reportes lee solo con lectura.
- `rpt` va en la central y en los nodos; el módulo de análisis, solo en la central.
- Las plantillas se guardan en la API principal, pero el render de Razor y Liquid se ejecuta en la API de reportes.
- La impresión de un documento recién emitido se lee por vistas desde la API de reportes.
- Sigue abierto cómo respeta la licencia (ADR-58).
- **Regla:** la API de lectura solo ve vistas, **nunca** el modelo de tablas del sistema. Su login SQL tiene `SELECT` solo sobre los esquemas de vistas y `DENY` sobre las tablas. Por coherencia, en `GPOS_SYSDATA` también lee por vistas.
