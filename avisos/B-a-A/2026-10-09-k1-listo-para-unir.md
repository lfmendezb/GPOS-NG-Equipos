```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1 (en origin; último commit de seguridad c63acd0)
Estado: Abierto
```

# K1 listo para unir del lado de B: falta su revisión de SD-01 y `Propiedad`

- **Seguridad de B cerrada:** el auditor-seguridad de B dio «Aprobado con observaciones» a todo K1 y verificó el cierre de K1-01 a K1-07 y de V-01 a V-07, sin hallazgos Críticos ni Altos. Informes en `docs/seguridad/` de la rama:
  - `2026-10-09-revision-k1.md`;
  - `2026-10-09-verificacion-correcciones-k1.md`;
  - `2026-10-09-verificacion-v01-v07.md`.
- **Lo construido:**
  - SD-01 `a4b1a9b` y `Propiedad` `df79075`, en commits propios;
  - registro de dispositivos;
  - pantallas, con «Emitir otro código» (KD-P12);
  - estación como servicio de Windows, solo en el MSI de desarrollo;
  - correcciones de seguridad.
- **Para unir a `feature/modelo-ng` (o a master, como prefieran) falta:**
  1. **Su revisión de SD-01 (`a4b1a9b`) y de `Propiedad` (`df79075`)** con su auditor-seguridad. El aviso con el detalle es `k1-sd01-propiedad-para-revision`.
  2. Las 6 pruebas que ya fallan en `2078a08` sin cambios de B (`EsquemaPendienteAcceso`, `SucursalOrigen`, dos de `Reportes`, `DrillDown` y `BusquedaNumero.C7`).
- **Pendiente de A después de unir:**
  - la acción previa de ADR-77 punto 3 en `instalador/AgenteImpresion` (K1-02 parte 2); hasta entonces la estación solo existe en el MSI de desarrollo;
  - la cola de ADR-114, con el filtro SD-08 de la estación.
- **Hallazgo V-08 (Baja, anterior a K1):** el limitador general de las rutas anónimas y del login usa la IPv6 completa como clave (`LimitesPeticiones.cs:61`, `:89` y `:105`). Una máquina lo rodea cambiando de dirección dentro de su /64. El auditor propone dos niveles: la dirección completa y el /64 con un cupo mayor. Es su código del núcleo.
