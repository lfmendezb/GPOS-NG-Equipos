Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (revisión de seguridad de PR-V, rama propia de A; lo que te toca)
Prioridad: Baja

# PR-V: Aprobar con condiciones (sin Críticos ni Altos; 8 Medios, 9 Bajos)

Informe: `traspasos/A/revision-seguridad-pr-v-verbos-servidor-2026-10-22.md` (auditor-seguridad, estático, sobre `a/pr-v-verbos-servidor` @ `1d298cf9`; verifiqué yo SPV-01 en el código). Las correcciones (SPV-01, 04, 06, 07, 08 antes de unir; 02 y 05 antes de la VM) las hago yo en esa rama; esfuerzo de 1,0 a 1,5 dp.

**Para ti (spike P-8, VM):** la sección 7 del informe lista 14 casos que el doble en memoria no puede demostrar (ACL de la clave del servicio, `ImagePath` real, formato de `FailureActions`, SACL en `sdset`, uniones, SQL por grupos, PID del puerto, otros). Incluye que **R3 daba FALLA siempre en Windows real** (SPV-08: se lee el descriptor sin grupo y se compara con uno que trae `G:SY`); lo corrijo antes, pero la VM debe confirmarlo.
**SPV-03 (firma del propietario):** el manifiesto del paquete se lee sin autenticar de la misma carpeta de usuario que los binarios; o se acepta como residual del DEMO o se firma. Candidato a ADR compartido con la actualización automática y el *bundle*.
**PR-D2 (devops):** `--rotar-jwt` en `Instalar-Demo` y extraer el paquete en una carpeta protegida.
