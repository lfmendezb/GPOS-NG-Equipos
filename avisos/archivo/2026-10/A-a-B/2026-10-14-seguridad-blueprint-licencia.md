Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: área común traspasos/A/revision-seguridad-blueprint-licencia-lote2-2026-10-14.md
Estado: Abierto

# Seguridad del blueprint de la licencia del lote 2: Rechazado en v1 por 3 Altos (≈0,6 días-persona para corregir)

Pasa a «Aprobado con observaciones» si la hoja de firma incorpora las condiciones (sección 9 del informe); basta una lectura de diferencias.

## Altos
- **SEG-L2-01 (bloquea DL-01 tal como está):** el cupo se cuenta con `Inhabilitado`/`Nivel` de la tabla de usuarios; un `sysadmin` puede sacar del conteo una cuenta sellada, dar de alta otra y restaurar la columna: cupo duplicado sin rehacer ningún MAC. Remedio: contar el consumo desde el padrón.
- **SEG-L2-02:** sin tope de vigencia para licencias firmadas solo en Básico; una falsificada con `s1` dura lo que diga su `vence`. Remedio: **DL-14 nueva**, tope de 200 días (coincide con la O-3 del maestro).
- **SEG-L2-03:** la premisa de R-B13 solo vale si el programa malicioso no es administrador. **DL-13 (cuenta diaria estándar) obligatoria antes de generar `s1` (AI-09).** El Medio-Alto aceptado es correcto; DL-13 sola no lo baja a Medio.

## Otras condiciones
DL-02 sin sellar ni crear cuentas en Release en ningún modo; DL-03 tras la fase A de ADR-81; DL-05 obligatoria; DL-10 con cuenta `s1r` deshabilitada salvo prueba o emergencia; DL-12 con revisión a más tardar el 2027-03-31; condiciones E-1 a E-15 para la cuenta de firma.

## En A ahora
- El arquitecto-maestro rehace la hoja como v2 (DL-01 a DL-14) con estas condiciones y el texto de AP-04.
- El arquitecto-software actualiza el blueprint (§2.2, §2.3, §8, §10.5, §10.6 y DL-14).
- **No generar `s1` (AI-09) hasta cumplir DL-13.**
