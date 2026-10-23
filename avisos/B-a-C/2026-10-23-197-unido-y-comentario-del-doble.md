Para: C        De: B        Fecha: 2026-10-23
Tipo: Aviso (#197 unido; una corrección pendiente) y acuse
Prioridad: Baja
Estado: Abierto

# #197 unido y una nota de A pendiente

Por orden del propietario del 2026-10-23 se unieron a `feature/modelo-ng`: **#197** (pruebas de P175-01 y P175-02), **#198** (`Preparar-Vm.ps1` y la lista de revisión) y **#196** (limpieza de `ClearAllPools()`); también #202 y #204. `feature/modelo-ng` quedó en `64b1b347`.

- **#197, nota de A (aprobado con una nota):** el doble del emisor en `NotificacionesReportesTests` **no repite el orden completo del real** (le faltan `AutorSinAcceso` y `AutorCambioClave`), así que el comentario «mismo orden» es inexacto. Te toca corregir el comentario (o completar el orden) en un PR chico contra `feature/modelo-ng`. A confirma P175-02 (2) y lo invierte en T4-06.
- **#198:** A lo aprobó sin hallazgos Críticos, Altos ni Medios; tres Bajas sin cambio pedido (borrado recursivo por nombre, PowerShell de 64 bits, dos [I] de la primera sesión).
- **`Preparar-Vm.ps1` corrió en VM-SRV** (2026-10-23, con punto de control previo): `-Comprobar` pasó de 7 faltas a 7 OK, exit 0, idempotente; `-SkipAsSource` de .11 y la desaparición de la APIPA, confirmados; los restos que dejó la desatendida fueron `Panther\unattend.xml`, `unattend-original.xml` y `C:\vboxpostinstall.log` (cubiertos por tus patrones). `Cerrar-Preparacion.ps1` tomó `base`. Evidencia en `M:\VM\evidencia\preparar-vm`. Dos arreglos al laboratorio ya unidos: la guarda de firma de Oracle (#199) y `Get-TiposSo` (#200).
- **Pendiente de laboratorio:** VM-LNX (Ubuntu 24.04 se cuelga al arrancar el instalador; probar virtio y otro controlador de disco) y VM-PUESTO (sin crear).

Respuesta requerida: acuse.
