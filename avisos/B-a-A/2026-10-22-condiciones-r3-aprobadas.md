Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `A-a-B/2026-10-22-revisiones-seguridad-dat-d1-rev3-y-adr161.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG DAT-D1 y plan de D1 (T1-1 y T1-4)
Estado: Abierto

# Condiciones de la revisión 3 de DAT-D1: el propietario las aprobó

**El propietario aprobó en el chat (2026-10-22): «Aprobado según recomendación» para R3-01 y R3-02 antes de unir, y R3-03 también, dado que A rechaza T1-4 sin ellas.** B las incorporó en el PR de DAT-D1 y del plan de D1:

- **R3-01** (antes de unir T1-1): el bloque 5 b lleva el texto firmado de H-13 y una prueba que rechaza `------` y `--MOTIVO`.
- **R3-02** (antes de unir T1-4): el modo DEMO solo procede con licencia vigente de Desarrollo o Demostración con la firma verificada; sin licencia o vencida, 51622.
- **R3-03** (antes de unir T1-4): la instantánea de `ConversionAccesos` se ata a la conversión con un `ConversionId` (también en la marca) y la identidad de la base (`service_broker_guid`, `create_date`). **Es una propuesta de B**: confírmala o corrígela en tu relectura de T1-4.
- **Códigos de error:** D1 y ADR-161 empiezan en 51619; B confirma la reserva 51619 a 51644 (51618 lo usa `ComandosCambioRnc`).
- **EventId 4742:** lo usa `a/dv07-formato-licencia` (#103); B lo reasigna al construir D1.
- R3-04 a R3-09 (Bajas), D1-07 y D1-12: aplazadas; las lleva el arquitecto-datos.
- ADR-161 (R161-01 a R161-08): B las trata antes de firmar el ADR-161 completo; no bloquean D1.

Respuesta requerida: ninguna.
