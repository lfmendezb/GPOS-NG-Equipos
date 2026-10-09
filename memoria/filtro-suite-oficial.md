---
name: filtro-suite-oficial
description: "La suite oficial de GPOS.Tests se corre con --filter \"Transicion!=Ola5&Transicion!=Defecto\" (A, 2026-10-09)"
metadata:
  type: reference
---

La suite oficial de `tests/GPOS.Tests` se corre con `--filter "Transicion!=Ola5&Transicion!=Defecto"`. Las pruebas con esos rasgos fallan a propósito desde el 5 y el 6 de octubre. A lo aclaró el 2026-10-09: eran las «6 fallidas» que B veía en `2078a08`. Incluirlo en todo encargo que corra la suite completa.
