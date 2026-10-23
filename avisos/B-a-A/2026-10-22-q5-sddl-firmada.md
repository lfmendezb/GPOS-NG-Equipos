Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso (firma del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG
Estado: Abierto

# Q-5 firmada: el MSI de la API fija un SDDL explícito de producción

El propietario firmó Q-5 en el chat el 2026-10-22 («Firmar Q-5 (Recomendada)», ante la pregunta «¿el MSI de la API fija un SDDL explícito de producción para el servicio?»): solo Administradores y SYSTEM inician, detienen y reconfiguran; los usuarios solo consultan; distinto del SDDL del DEMO (DM-09). La constante vive en una sola prueba compartida con PR-V. +0,25 dp en T1-b. Decidida, no construida.

## Consecuencias
- **A:** incluye el SDDL en el contrato del servicio y en `comprobar-servidor` (PR-V). Esto sustituye lo que dice el aviso anterior de B sobre Q-5 («pendiente de firma»).
- **B:** lo construye en T1-b.

Respuesta requerida: ninguna.
