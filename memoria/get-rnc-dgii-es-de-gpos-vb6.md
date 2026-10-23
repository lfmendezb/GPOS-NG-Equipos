---
name: get-rnc-dgii-es-de-gpos-vb6
description: "GET-RNC-DGII (repos\\GET-RNC-DGII) es complemento de GPOS VB6, no de GPOS NG; no aplicar ADR ni reglas de GPOS NG"
metadata:
  node_type: memory
  type: project
  originSessionId: fbcc41ed-8e4b-4112-bf41-17bc74ba9dc7
  modified: 2026-10-23T16:45:20.445Z
---

El proyecto `C:\Users\lfmen\source\repos\GET-RNC-DGII` (consola .NET 10 que descarga el padrón RNC de la DGII y lo carga en `dbo.RNC_Data` de las bases `POS_*`, p. ej. `POS_GOLDCENTER`) es un complemento de **GPOS VB6**. GPOS NG ya tiene su propio módulo de padrón RNC integrado.

**Why:** el 2026-10-23 se le aplicaron por error reglas de GPOS NG (ADR-44 sobre `gsf`, compatibilidad mínima 130, nombres `GPOS_`) y el propietario aclaró: «Este complemento es para GPOS VB6 no para el proyecto GPOS NG, este ya tiene su modulo integrado».

**How to apply:** al trabajar en GET-RNC-DGII no cite ADR de GPOS NG ni sus convenciones; los nombres `POS_*` y el esquema de `dbo.RNC_Data` son los de GPOS VB6. Sí aplican las preferencias generales del propietario ([[responder-en-espanol]], [[sin-access-ni-texto-plano]], [[tecnologia-solo-con-consulta]]).
