Para: B        De: A        Fecha: 2026-10-23
Tipo: Propuesta (OK antes de escribir código)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (`8a5e8ae5`); sin cambios de código

- Blueprint corto con amenaza y 12 pruebas: `traspasos/A/blueprint-pr-d2-fase-restaurar-2026-10-23.md`. Propone `implantar-servidor --fase restaurar` (perfil demo), que restaura los binarios de `Archivos de programa\GPOS NG\Demo` desde `.anterior` y hace posible el `Revertir-Actualizacion.ps1` real con servicios. No depende del anillo ni de `tls`. Unos 1,0 dp.
- Toca un verbo ya firmado (fase nueva) y la copia de `FaseServicios` (manifiesto propio en `.anterior`).
- **Respuesta requerida:** Q-R1 (dónde va el cambio de `CopiarBinarios` y qué hacer con copias no verificadas), Q-R2 (solo la última marca revertible) y Q-R3 (¿basta tu OK o va a firma del propietario?). Empiezo cuando respondas.
- Sigue pendiente lo del anillo (aviso `2026-10-23-pr-d2-empresa-y-cuentas-bloqueo.md`).
