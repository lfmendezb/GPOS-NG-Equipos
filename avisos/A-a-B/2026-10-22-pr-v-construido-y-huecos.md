Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (PR-V construido; huecos del contrato decididos; lo que es tuyo)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (`65a69068`, empujada, sin PR; 3 commits de PR-V más 1 de las decisiones, sobre `d3b12c27`)

# PR-V: `implantar-servidor` y `comprobar-servidor` construidos; decisiones del 22-oct

- **Pruebas:** 754/754 en las clases de Servidor, Arquitectura y `ComprobacionCarpetasPreviasTests` (incluye `EventIdUnicosTests`, 5134 a 5138 libres). Todo con un doble en memoria: no ejecuté servicios, `sc` ni `icacls`. Lo real, en el spike de la VM (P-8). Una mutación (quitar la comparación de huella de `lectura`) la detecta la prueba.
- **Decisiones del propietario (22-oct, «adopta las cuatro»):** (1) `esquema` pide `--acta`/`--motivo` solo si el ancla no está fijada; sin ellos, 4. (2) `esquema` no crea empresas, solo `actualizar --todas`. (3) `lectura` publica la llave pública en `config\llave-sitio.pub` y compara su huella antes de `crear-lectura --todas`. (4) Se elimina `--confirmar`. Blueprint actualizado.
- **Tuyo, para que PR-V cierre:**
  - **Verbo `red` (modo un equipo):** no existe en `feature/modelo-ng`; `lectura` termina con 1 hasta que exista (a propósito, para que un guion no la dé por completa).
  - **Origen de eventos `GPOS.Instalacion`:** los eventos 5134 a 5138 no se escriben en el DEMO sin MSI; hoy el plan solo registra `GPOS.Api` y `GPOS.Reportes`. Dime si el DEMO lo registra.
  - **Configuración del anillo con certificado (DM-07):** el entorno de `GPOS.Api` no la lleva; falta la definición de cómo se crean los certificados y sus huellas.
- **De PR-D2 (devops):** generar `manifiesto.sha256` (formato `<hash>  <ruta>`) en `Publicar-PaqueteDemo.ps1`; la fase `servicios` verifica contra él.
- **Pendiente mío:** revisión de seguridad del diff (≈3.600 líneas) y rebase sobre `feature/modelo-ng` (va 19 commits adelante) antes de abrir PR; el PR, con orden del propietario.
