---
name: no-generar-comprobante-permiso-bitacora
description: "Decisión del propietario sobre RG-04/RG-05: «No generar comprobante» deja rastro en _LOG y exige un privilegio del grupo Especiales, junto a Ver costos"
metadata:
  node_type: memory
  type: project
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-03T21:41:07.030Z
---

Decisión del propietario del 2026-10-03, sobre RG-04 y RG-05 de la revisión general con Fable:

- **"No generar comprobante" siempre deja rastro en la bitácora** (`_LOG` de la empresa), no solo en el registro del servidor.
- **Exige un privilegio propio.** Va en el grupo **"Especiales"** de `src/GPOS.Contracts/Seguridad/Permisos.cs`, en el mismo apartado que `VerCostos` y `EliminarRenglonPos`, con la función `Privilegio(..., "Especiales")`.

**Why:** cumple la regla de no fomentar el uso sin comprobante (CLAUDE.md, NCF) y la línea de bitácora que prometía `docs/pos/2026-10-01-ncf-y-existencias-iniciales.md`.

**How to apply:**
- Va en el bloque "antes de publicar", **después de la unión a master**; no entra en la rama de numeración.
- Aplica a todos los caminos que aceptan `noGenerar`: POS, documentos comerciales y notas de CxC (`PosService`, `DocumentosComercialesService`, `CobrosService`, `Ncf.EmitirAsync`).
- **Origen sin NCF (aprobado el 2026-10-03):** cuando el documento de origen (factura de una devolución o de una nota) no tiene NCF, guardar sin comprobante es la única opción. En ese caso **no se exige el privilegio**, pero **sí se escribe la línea en `_LOG`**.
- Se construye en la rama `feature/rg04-rg05-no-generar-comprobante`, creada desde master `7bcda19`.
- **RG-05, texto aprobado (2026-10-03):** si la base no tiene secuencias NCF vigentes y el usuario no tiene el privilegio, el selector muestra **"No hay secuencias NCF vigentes; avise al administrador"**. Con secuencias vigentes, el usuario sin el privilegio ve los tipos de comprobante normales; solo desaparece "No generar comprobante".

- **Firmado el 2026-10-03 (servidor):** (1) ningún perfil de ejemplo recibe el privilegio (solo ADMIN y SUPER por nivel); (2) la nota de débito sin factura de origen exige el privilegio; (3) compras B11/B13 fuera de alcance. Pruebas dirigidas 152/152 en verde; la suite completa queda para antes de unir a master, con el equipo libre (el propietario la considera demasiado exigente para correrla mientras trabaja).

Relacionado: [[cierre-numeracion-nuevo-equipo]].
