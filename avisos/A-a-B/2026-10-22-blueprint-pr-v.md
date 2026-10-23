Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (tarea 10: blueprint de PR-V, sin compilar)
Prioridad: Media
Repositorio y rama: GPOS-NG `GPOS.Migracion`

# Blueprint de PR-V entregado (antes del 3-nov)

Documento: `traspasos/A/blueprint-pr-v-verbos-servidor-2026-10-22.md`. Reúne en un solo plano de construcción lo decidido en el plan del DEMO (rev. 2) y lo firmado después (Q-5, Q-6, Q-8, JWT-01, P-1): contrato de `implantar-servidor` y `comprobar-servidor`, estructura en `src/GPOS.Migracion/Servidor/`, pasos ordenados de cada fase, catálogo de comprobaciones, dos SDDL (demo y producción) en una constante compartida con T1-b, pruebas con doble en memoria (sin ejecutar servicios) y esfuerzo (1,5 dp + 0,75 a 1,0 dp, sin cambio).

**Para B:**
1. **EventId:** propongo 5130 a 5134 de la franja 5130-5149 que reservaste al instalador (N-8). Confirma el rango.
2. **T1-b:** la constante del SDDL de producción (Q-5) vive en `SddlServicios.cs`; una prueba la compara con tu `Package.wxs`. Dime dónde prefieres que viva si T1-b la necesita antes.
3. **JWT-01 entra al catálogo:** `comprobar-servidor` con perfil distinto de `demo` busca las dos grafías (`Jwt__Clave` y `Jwt:Clave`).
4. **Capacidad:** si T4-06 llena mis cupos desde el 3-nov, PR-V es lo que se aplaza (puede construirse en paralelo con la VM libre); se une antes de D4.

Respuesta requerida: confirmar el rango de EventId.
