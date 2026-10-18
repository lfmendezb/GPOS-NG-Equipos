Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/datos-t3-12-rg14-2026-10-14.md
Estado: Abierto — requiere firma D-01 a D-11

# T3-06, T3-08, T3-12 y RG-14: diseño listo, 11 decisiones para firmar

Diseño del arquitecto de datos de A: `traspasos/A/datos-t3-12-rg14-2026-10-14.md`. Solo se leyó código y catálogo: no se cambió código, bases ni la instancia.

## Lo esencial
- **Hoy la API es administradora total** en desarrollo y en el DEMO: entra con la cuenta Windows `sysadmin` y es dueña de las bases. Con eso, ningún `DENY` (T3-08, T3-12, AE-01, ADR-74) tiene efecto.
- **Qué hace la API hoy:**
  - crea bases (`GPOS_SYSDATA` y las de empresa);
  - hace DDL en cada arranque;
  - respalda;
  - hace un `TRUNCATE` del padrón.
- **T3-06 ya está corregido en reportes** (`e4711cc0`). Queda un resto: la exportación de la consulta de facturas no exige «Exportar reportes» (D-10).
- **El modelo propuesto aplica lo firmado el 2026-09-29** (ADR-44 AC-4, M-1, M-4, AIS-12/16, SEC-05) y nunca construido:
  - API en `GPOS_SYSDATA`: `NT SERVICE\GPOS.Api` con el rol `gpos_api`, sin DDL y con `DENY` sobre `ConexionLectura` (T3-08).
  - API en las empresas: usuarios contenidos `gpos_app_a|b` por empresa.
  - Esquema del sistema: lo aplica `GPOS.Migracion sistema`.
  - Respaldo: por un procedimiento con `EXECUTE AS OWNER`.
  - Dueño de las bases: `sa`, deshabilitado.
  - `ALTER ANY USER`, en capas.
  - T3-12: `DENY VIEW DEFINITION`/`SHOWPLAN` y otros a los tres roles de lectura.
  - Modo **Estricto** por omisión y **Amplio** explícito para desarrollo, pruebas y DEMO.
- **Estimación:** 7,5 a 8,5 días-persona en dos lotes.
  - El lote 1 (unos 2 días-persona) no cambia ningún entorno.
  - El lote 2 va antes del primer cliente.

## Decisiones para firmar (recomendación entre paréntesis)
- **D-01:** cierre de RG-14 (en dos lotes).
- **D-02:** el esquema de `GPOS_SYSDATA` sale de la API (ahora).
- **D-03:** dueño de las bases (`sa`).
- **D-04:** credencial de la API en las empresas (`gpos_app_a|b` contenidos).
- **D-05:** respaldo desde la API (por procedimiento).
- **D-06:** modo Amplio (clave explícita, no admitida en la versión publicada).
- **D-07:** texto nuevo del error sin permiso (aprobar o corregir la propuesta).
- **D-08:** Backup Tool (`CREATE ANY DATABASE` más `db_backupoperator`, nunca `sysadmin`).
- **D-09:** identidad de `GPOS.Migracion` (la de Windows del técnico).
- **D-10:** exportar la consulta de facturas exige «Exportar reportes» (sí).
- **D-11:** plan de reserva del `DENY VIEW DEFINITION` (autorizarlo ya).

**Candidato a ADR:** ADR-82, «Identidades SQL y privilegio mínimo» (rango de A).

## Hallazgos nuevos (detalle en el diseño)
- **H-RG14-01:** la comprobación de `CREATE SEQUENCE` nunca dispara.
- **H-RG14-02:** el resto de T3-06.
- **H-RG14-03:** el texto aprobado pide dar `db_owner`.
- **H-RG14-04:** `public` lee `msdb.restorehistory`, lo que afecta a R-D13 de H-11.
- **H-RG14-05:** `BUILTIN\Usuarios` entra a la instancia de la PC A, pero sin acceso a las bases.
- **H-RG14-06:** `gpos_app` puede escribir `conf.__EFMigrationsHistory`.

**Afecta a C:**
- el PR 26 de H-11 usa `GRANT BACKUP DATABASE` y pasaría al procedimiento;
- las concesiones de la fase A de ADR-81 ya están incluidas en el SQL.

A no construye nada de esto hasta la firma, y sigue con H-6.
