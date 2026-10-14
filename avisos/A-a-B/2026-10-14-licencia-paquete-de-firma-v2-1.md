Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: área común traspasos/A/ — hoja-firma-dl01-dl13-licencia-2026-10-14.md, blueprint-licencia-lote2-2026-10-14.md, borradores-adr-082-084-2026-10-14.md y revision-seguridad-blueprint-licencia-lote2-2026-10-14.md (todos v2.1)
Estado: Abierto — listo para firma

# Licencia del lote 2: paquete de firma final (v2.1), seguridad «Aprobado con observaciones»

El auditor hizo la lectura de diferencias: los 3 Altos quedan cerrados y **nada de lo abierto bloquea la firma de DL-01 a DL-14**. La hoja, el blueprint y los borradores de ADR son coherentes entre sí (verificado con grep en DL-10).

## Qué firma el propietario
- **Antes del 2026-10-16:** DL-07 (reparto) y DL-08 (calendario). Además, adelantar el **recorte 1** (tablero, CSV de pagos y subida a Drive del emisor, a enero; no requiere firma). Sin ese recorte, I se pasa ≈1 día-persona en el peor caso.
- **DL-13 obligatoria antes de generar `s1`**, con la novedad SEG-L2-25: la cuenta diaria no puede ser `sysadmin` de ningún SQL local (hoy `DevLab00\lfmen` lo es) ni estar en grupos con efecto de administrador; `dbcreator` para pruebas e inicio de sesión nominal aparte. Devops lo verifica en el inventario O-6 antes de AI-09.
- **DL-10 (respaldo de `s1`):** (a) `s1r` en el TPM de otro equipo; (b) dos YubiKeys en Básico, separadas de las cuatro de la ceremonia, serie a elección (no FIPS ≈USD 110 o FIPS ≈USD 176); (c) sin respaldo. Recomendado: (b) si acepta el gasto y cambiar el «TPM» de F-2; si no, (a). Con (b), DL-13 pasa a «muy recomendada».
- El resto (DL-01 a DL-05, DL-09, DL-11, DL-12 con revisión ≤ 2027-03-31, DL-14 tope de 200 días): Aprobar, con las condiciones que constan en la hoja.
- **Esta semana:** encargar al asesor legal CI-7/AI-07 (plazo 2026-11-16) y AP-06.

## Cifras
Licencia ≈61,8 días-persona (v1: 55); L 24,3 e I 24,2 con el recorte 1. Primera licencia de pago, como pronto, el 2026-12-14.

## ADR
Borradores v2.1 de ADR-82, 83 y 84 en estado Propuesto, listos para quien los registre en `master`.
