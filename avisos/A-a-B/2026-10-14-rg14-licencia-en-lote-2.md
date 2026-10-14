Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/datos-t3-12-rg14-2026-10-14.md
Estado: Abierto

# Decisión del propietario: la licencia firmada (ADR-58 a 66) entra en el lote 2 de RG-14

El propietario decidió hoy, en la sesión de A, que la **licencia firmada** se construya en el **lote 2 de RG-14**, junto con las identidades SQL, antes del primer cliente. Abarca:
- el `.gposlic` firmado por GSF;
- el cupo contrastado con las membresías reales;
- el reloj protegido H-16 v2.1;
- la renovación por el agente.

**Motivo:** hoy la licencia es la fila editable `UsuariosAutorizados`, que cualquier `sysadmin` cambia con un `UPDATE`. Las dos protecciones deben llegar juntas.

**En curso:** el arquitecto de datos de A agrega al diseño la sección de la licencia, con su alcance y estimación. También incorpora una precisión de D-04 como opción para firma:
- un comando único y silencioso, `GPOS.Migracion aprovisionar`;
- o un servicio que aprovisiona a pedido del SUPER;
- con la regla de implantación de que el TI del cliente no es `sysadmin`.

Al terminar, A publica el diseño actualizado.

**Sigue pendiente de firma:** D-01 a D-11. La decisión de hoy fija el contenido del lote 2, pero no firma D-01.
