# ADR-81 · Precisión del 2026-10-15 para registrar (DL-04: eventos de la licencia y del sello en `BitacoraSeguridad`)

**Para quien registra (B), no se copia al ADR.**
- **No estaba en el encargo:** la hoja dice que DL-04 «es una precisión de ADR-81 (punto 12) y de ADR-60 (punto 8)».
- **Salvedad:** DL-04 está firmada **según la interpretación de B** (no figuraba por nombre en la lista que vio el propietario). Conviene registrarla cuando B confirme que el propietario no la corrigió; si la corrige, se descarta.
- **Dónde va:** al final de `docs/adr/ADR-081.md`.
- **ADR-60, punto 8:** no preparo un texto aparte. El punto 8 nombra `BitacoraSistema` solo para la evidencia del detector de integridad del agente de actualización (L4), que no está en la entrega 1. Si B quiere una nota en ADR-60, basta esta frase: «Mientras no exista `BitacoraSistema`, la evidencia del detector de integridad del punto 8 va a `BitacoraSeguridad` (DL-04, precisión de ADR-81 del 2026-10-15)». Es mi lectura [I], no un texto que haya visto el propietario.
- **Fuente:** hoja DL-01 a DL-22 v2.13 (`traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`), DL-04 y sección 7.

---

> **Precisión del 2026-10-15 del punto 12: `BitacoraSeguridad` recibe también los eventos de la licencia y del sello de habilitación (DL-04 (a) de la hoja de firma DL-01 a DL-22 v2.13, en el área común `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`\*; registrada como firmada el 2026-10-15 por el coordinador (B) según su interpretación de la respuesta del propietario: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.»; B se lo indicó al propietario en el mismo turno).** Sin cambiar el texto firmado de arriba:
> 1. `BitacoraSistema` no existe en el código. Los eventos de la licencia ([ADR-58](ADR-058.md) a [ADR-62](ADR-062.md)) y del sello de habilitación ([ADR-83](ADR-083.md), punto 8) se registran en `GPOS_SYSDATA.dbo.BitacoraSeguridad`, con sus mismas reglas: solo inserción (real con RG-14) y retención de 2 años.
> 2. Hay **una sola DDL**, del arquitecto de datos, aplicada por `GPOS.Migracion sistema` ([ADR-82](ADR-082.md), punto 4).
> 3. Cuando exista `BitacoraSistema`, las dos se unen con una decisión aparte.
>
> *Descartados:* construir ya `BitacoraSistema` (trabajo sin dueño ni calendario) y usar solo el Visor de eventos (no viaja con los respaldos y se puede borrar). Costo: unos 0,5 dp. **Decidido, no implementado.**
>
> \* *La hoja vive en el área común; no está copiada en `master`.*
