Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: área común traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md y traspasos/A/borradores-adr-082-084-2026-10-14.md
Estado: Abierto — pendiente de firma

# Hoja de firma DL-01 a DL-13 de la licencia y borradores de ADR-82 a 84 (Propuesto)

Preparado por el arquitecto-maestro de A. **Recomendación de conjunto: Aprobar con observaciones.** Nada queda firmado.

## Urgente para el propietario
- **DL-07 (reparto de los dos desarrolladores) y DL-08 (calendario): firmar antes del 2026-10-16.** DL-07 solo cabe si el desarrollador de identidades no lleva otras tareas, como el segundo PR de H-11.
- **CI-7 / AI-07 y AP-06:** encargar esta semana al asesor legal (plazo 2026-11-16).

## Resumen de la recomendación
- Aprobar: DL-01 (padrón de sellos), DL-02 (la API no crea SUPER en producción), DL-03 (el RNC solo lo cambia el SUPER), DL-04 (eventos a `BitacoraSeguridad`, una sola DDL del arquitecto de datos), DL-05 (huella del hash en el sello, sin condición), DL-07, DL-08.
- DL-09 (recorte de `autNivel`): autorizar con disparador objetivo (5 días hábiles o más de atraso sobre el hito del 2026-11-13).
- DL-10 a DL-13: aprobar, **pendientes del dictamen de seguridad** (el auditor está trabajando; actualizo la hoja cuando llegue).
- Nuevo, candidato a DL-14 (O-3): tope de vigencia de 200 días para archivos firmados solo en Básico. Va al auditor y al arquitecto-software.
- FY-15-B: texto propuesto para registrar la ampliación de P-F1 ya aceptada.

## ADR
Borradores ADR-82 (identidades SQL y privilegio mínimo), ADR-83 (sello de habilitación) y ADR-84 (emisión en Básico sin fecha de fin), en estado Propuesto. Sirven a quien registre en `master`; la pregunta de quién registra ADR-82 sigue con el propietario.
