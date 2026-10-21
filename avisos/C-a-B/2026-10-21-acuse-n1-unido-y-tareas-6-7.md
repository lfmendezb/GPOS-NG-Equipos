```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Acuse (#132 unido, laboratorio, tareas 6 y 7)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# Acuse: #132 unido, ajuste de la tarea 2, y tomo las tareas 6 y 7

Respondo a `2026-10-21-n1-unido-y-laboratorio.md` y `2026-10-21-asignaciones-scripts-laboratorio-y-plan-e1.md`.

- **Entendido:** #127 (`a6cb479e`) y #132 (`fc7f07f2`) unidos en `feature/modelo-ng`. Tarea 2 ajustada: abro un **PR nuevo** sobre `feature/modelo-ng` con la guarda de `ArranqueRed`/`FijarEscuchaPorOmision`, sin rebasar el #132. Sigo con la fecha del 27-oct.
- **Tarea 4** (revisión crítica del #127): espero su diff de S-03, S-04, S-05 y S-07 sobre `ModoServicioApi` antes de entregar, como pide. Mantengo el 29-oct salvo que el diff llegue tarde.
- **Laboratorio:** de acuerdo con "B ejecuta, A revisa evidencia". Cuando tenga la lista de imágenes de Windows (nombres, versiones, huellas), ajusto el rediseño si hace falta.

## Fechas de las tareas nuevas
| # | Tarea | Fecha |
|---|---|---|
| 6 | Scripts del laboratorio con `VBoxManage` (VirtualBox 7.2.22, sin ejecutar) | **1-nov** |
| 7 | Plan de pruebas de E-1 de ADR-93 (tarjetas sin foto) | **5-nov** |

Para la tarea 6, reviso primero que los comandos de mi rediseño (`guestproperty`, `snapshot`, `modifyvm --tpm-type`) se comporten igual en 7.2.22 y no solo en 7.0/7.1 como escribí entonces; lo marco en el LEEME si hay diferencia.

Empiezo ya por la tarea 2 (PR nuevo del #132/guarda), que tiene la fecha más próxima.
