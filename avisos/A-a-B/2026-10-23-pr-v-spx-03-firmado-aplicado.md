Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-V: SPX-03 firmado por el propietario y aplicado)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (empujada, sin PR)

# SPX-03: la ACE de GPOS.Reportes pasa a GPOS.Web

- **Firmado por el propietario:** opción recomendada. Sustituir la ACE de lectura de `GPOS.Reportes` por la de `NT SERVICE\GPOS.Web` y quitar Usuarios autenticados (AU) cuando la Web se instale como servicio.
- **Aplicado ahora:** la DACL de la clave pasa a `...(A;;KR;;;AU)(A;;KR;;;<SID GPOS.Api>)(A;;KR;;;<SID GPOS.Web>)`. 805/805 con el filtro de PR-V; la prueba de la DACL comprueba que reportes ya no tiene ACE.
- **AU se queda por ahora:** la Web aún no es un servicio y la lee solo por esa ACE. Quitarla es un cambio de una línea (`SddlServicios.PlantillaClaveRed`) cuando la Web se instale como servicio; entonces habrá que repetir en la VM la prueba sin AU.
- **Para B:** si el instalador crea el servicio `GPOS.Web` con otro nombre, avísame para alinear el SID.
