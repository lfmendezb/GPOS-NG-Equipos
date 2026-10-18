```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/lic-v32 (dbf5048, desde master f550250)
Estado: Abierto
```

# `[LIC]` v3.2.5 lista para unir a master: sin preguntas abiertas para el propietario

`docs/arquitectura/2026-10-05-licencia-por-vigencia.md` pasó de la v3.1 a la **v3.2.5** en `b/lic-v32` (solo documentos). Contiene:
- la precisión de ADR-58 firmada el 2026-10-08 (PL-01 a PL-07);
- dos confirmaciones ligeras del auditor-seguridad de B, las dos «Aprobado con observaciones», con las observaciones incorporadas: `docs/seguridad/2026-10-08-confirmacion-lic-v32.md` y `docs/seguridad/2026-10-08-confirmacion-lic-v323.md`;
- las respuestas del propietario del 2026-10-08, todas cerradas:
  - **PA-1:** se rechaza el archivo con un código de módulo repetido.
  - **PA-2:** se ignora el `vence` de los conectores, con un evento.
  - **PA-5:** el complemento es por empresa; tras un cambio de RNC por el SUPER rige un plazo de 30 días para reemitir.
  - **PA-7 (CL-01):** el archivo anual vale 6 meses y se reemite cada semestre; aviso de 30 días y gracia de 30; envío por correo a los clientes sin agente.
  - **PA-8 a PA-14:** refresco a −45 días; campo `periodo` y plazos por empresa; los 30 días solo para el vencimiento anual; cola firmada en sesión; señal del instalador del agente; sin acuse de carga.
  - **PA-15 y PA-16:** el módulo sigue el estado de la empresa; los mismos textos al fin del año.
  - **PA-17:** tope mensual de 1 mes y 15 días; los meses pagados por adelantado se emiten mes a mes.
- Peor caso aceptado: unos **260 días** en la anual y unos **55** en la mensual. Costo: la licencia queda en unas **7,8 sp**, sin cambio de calendario.
- Abiertas, todas técnicas: **PA-3, PA-4 y PA-6**, para el Maestro o el sincronizador.

**Pedido:** ¿une A `b/lic-v32` a master, o lo une B? Es documento de A; la rama trae solo `docs/`. Con la unión, el documentador registra las precisiones de ADR-58 (punto 0 y PL-01: `periodo`, plazos por empresa, archivo anual de 6 meses), de ADR-59 (peor caso de PL-07, plazo de RNC de NV-07) y la nota de ADR-61 (cola firmada en sesión).

**Antes de L1a (2026-11-02), para quien construye:**
- las validaciones del emisor (CL-07);
- devops: SPF, DKIM y DMARC del remitente de licencias (CL-08);
- arquitecto-integraciones: forma de la señal de agente habilitado.
