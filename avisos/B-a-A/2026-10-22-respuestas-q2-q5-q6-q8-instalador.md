Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (recomendaciones de B; Q-5 y Q-6 esperan la firma del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG
Estado: Abierto

# Respuestas a Q-2, Q-5, Q-6 y Q-8 del blueprint de la tarea 1 del instalador

Fuente: `traspasos/A/blueprint-tarea1-instalador-servicio-2026-10-22.md` (tabla de preguntas). Respondo antes del 3-nov, como pediste.

| # | Respuesta de B | Estado |
|---|---|---|
| **Q-2** (G-PR4) | **Sí.** No hay `GPOS.Api.msi` firmado mientras exista `FijarEscuchaPorOmision`. Aplica S-01(a) sin costo | B lo acepta; es suyo (el MSI de la API lo construye B, Q-1 firmada) |
| **Q-5** (SDDL en producción) | **Sí.** El MSI fija un SDDL explícito: solo Administradores y SYSTEM inician, detienen o reconfiguran; los usuarios, solo consultan. Distinto del de DM-09 del DEMO. La constante vive en una sola prueba y PR-V la comparte. **+0,25 dp en T1-b** | Recomendación de B: pendiente de la firma del propietario (cambia el alcance) |
| **Q-6** (ventana de la VM) | El bloque «instalador» (P-O1-7, L-1/L-2 y F-1; 1 sesión de ~3 h [I]) es la **primera ventana después del 11-13**, en `VM-SRV` de LFMB. El guion va en `tests/laboratorio-adr090/invitado/`, **sin depender de C** (fuera de servicio): lo escribes tú (T1-c) reutilizando `Recoger-Evidencia.ps1` del #146 | Recomendación de B: la fecha y quién opera la VM las fija el propietario |
| **Q-8** | **`auto`** hasta medir L-15; `delayed-auto` solo si la medición lo pide | B (devops) |

## Consecuencias
- **A:** puedes cerrar el contrato del servicio con Q-2 y Q-8 firmes; Q-5 entra al contrato en cuanto el propietario firme.
- **B:** T1-b incluye el SDDL de Q-5 si se firma.

Respuesta requerida: ninguna.
