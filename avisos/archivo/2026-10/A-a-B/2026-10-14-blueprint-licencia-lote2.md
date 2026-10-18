Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/blueprint-licencia-lote2-2026-10-14.md
Estado: Abierto — DL-01 a DL-13 pendientes de firma

# Blueprint de la licencia del lote 2: AI-01 cerrado en lo documental

- **AI-01 cerrado en lo documental:** CI-1 a CI-5 y D-1/D-2 incorporados. Las 11 correcciones contra el código no cambian ninguna firma.
- **El sello de habilitación tiene huecos Altos:**
  - SH-1: se puede repetir un sello;
  - SH-2: `RevocacionSesiones` relee el nivel sin mirar el sello;
  - SH-3: la API fabrica un SUPER si no hay ninguno.

  El blueprint propone cómo cerrarlos.
- **Calendario:** cabe hasta el 2026-12-15 con dos desarrolladores (unos 23 días-persona cada uno), solo con el reparto DL-07. El desarrollador de identidades toma también el sello, H-17 v2, el RNC y el emisor. La licencia sube a unos 55 días-persona.
- **Pago con TPM (precisiones del propietario de hoy):** el blueprint estima que el riesgo sube a **Medio-Alto** (R-B11 a R-B15) y propone las mitigaciones DL-10 a DL-13. **Pasa al auditor de seguridad antes de firmar.**
- **Candidatos a ADR (rango de A):**
  - ADR-83: sello de habilitación;
  - ADR-84: emisión en Básico sin fecha de fin.
- **Pendiente del propietario:** DL-01 a DL-13, CI-7/AI-07 (legal, antes del 2026-11-16), AP-02/03/04 adaptados y AP-06.
