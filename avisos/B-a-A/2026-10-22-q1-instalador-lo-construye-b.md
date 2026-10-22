Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `A-a-B/2026-10-22-blueprint-tarea1-instalador-servicio.md`, Q-1)
Prioridad: Alta (plazo: 2026-10-28)
Repositorio y rama: GPOS-NG `feature/modelo-ng`, `instalador/Api`
Estado: Abierto

# Q-1: el MSI mínimo de la API lo construye el equipo B

**Decisión del propietario (chat, 2026-10-22): «El equipo B»** construye el MSI de la API (`instalador/Api/`), con el devops de B; no A. Esto reordena la tarea 1 de A:

| Pieza | Quién | Notas |
|---|---|---|
| MSI mínimo de la API en `instalador/Api/` (servicio con `--servicio`, lista exacta de privilegios, sin `ServiceSid`, sin escribir entorno, `urls`, JWT ni reenvío) | **B (devops)** | Parte de tu blueprint (contrato del servicio de «Diseño en pocas líneas»); B lo construye como T1-b y lo apila sobre tu T1-a |
| T1-a: módulo de firma `instalador/Comun/Firma-Instalador.ps1`, guarda G-PR4, comprobación de la tabla `Binary` y nombre `-SINFIRMA` | **A** | Sin cambio; 1,75 a 2,0 dp |
| T1-c: documentos, procedimiento y guion de laboratorio de P-O1-7 con FIPS, plantilla de evidencia | **A** | Sin cambio |
| Laboratorio L-1 a L-2e en la VM de LFMB | A entrega el guion; lo ejecuta el técnico del propietario con C | |

## Lo que pido a A
- Entregar a B **antes de que B empiece T1-b** la lista exacta de lo que el MSI debe y no debe hacer (tu sección de contrato del servicio), como documento breve en el área común, y avisar cuándo T1-a esté abierto para apilar.
- Mantener tu fecha del 13-nov para T1-a y T1-c; B informa la suya para T1-b (depende de la capacidad de devops de B tras T4-04).
- Sigue valiendo G-PR4: `GPOS.Api.msi` no se firma mientras `ModoServicioApi.cs` contenga `FijarEscuchaPorOmision`.

## Pendiente de B (no respondido todavía)
Q-2 (G-PR4), Q-5 (SDDL), Q-6 (ventana de la VM), Q-8 (inicio `auto` o `delayed-auto`) y las del propietario Q-3, Q-4 y Q-7 (proveedor de firma, nombre legal, qué se firma). B responde antes del 3-nov.

Respuesta requerida: acuse y el documento de contrato del servicio.
