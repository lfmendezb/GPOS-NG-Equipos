Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `A-a-B/2026-10-22-adenda-s16-v-riesgo-1-y-f25.md`, Q-A1 a Q-A5) y encargo
Prioridad: Alta (Q-A1 y Q-A2 desbloquean P-0 de E-1)
Repositorio y rama: GPOS-NG ADR-93 (E-1) y precisión de TA-P08
Estado: Abierto

# Respuestas a Q-A1 a Q-A5 de S-16

**El propietario aprobó en el chat (2026-10-22): «Aprobado según recomendaciones: Q-A1 a Q-A5 de S-16».** Respuestas:

| # | Respuesta |
|---|---|
| **Q-A1** | **Sí.** R-07 pasa de `Operativo` a `Consulta` (corrige D-1 de B del mismo día). `Operativo` solo en R-05 y R-06. |
| **Q-A2** | **Sí.** 401 `credenciales` en `RevocacionSesiones.Evaluar` si el usuario está restringido y la sucursal del token no es su `SucursalDefault`. |
| **Q-A3** | **Sí.** El ADMIN restringido tampoco puede detectar, ver la vista previa, guardar ni eliminar definiciones de reportes (paridad con `PuedeDisenar`). Va en E-1. |
| **Q-A4** | **Sí.** R-14 pasa a T4-06, con la condición de que `IDetectorColumnas` en Release propague el 403 (no un 503), con la fila nueva en el contrato de Guardar. |
| **Q-A5** | **El SUPER con bandera de restricción no se restringe nunca** (el SUPER es global, ADR-35 y ADR-36). Una sola regla para P-0 y para la API de reportes. |

## Lo que pido a A
1. **Confirmar Q-A5** y decir qué cambia en la API de reportes (hoy restringe al SUPER con la bandera: `ContextoReportes`). Si el cambio es de ella, entra en E-1/P-0 o en T4-06; dime dónde.
2. **Registrar** las decisiones 1 a 3 de tu adenda y Q-A1 a Q-A5 como precisión de TA-P08 (ADR-93); B las anota con la hoja de firma.
3. Con esto, P-0 de E-1 queda desbloqueada. Esfuerzo total de la adenda: +0,35 dp (E-1 +0,25, S-16b +0,05, T4-06 +0,05).

Respuesta requerida: acuse y la ubicación del cambio de Q-A5.
