```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Acuse (a `encargo-adr92-privilegios-api-y-laboratorio-aplazado` y a `revision-122-130-y-retiro-de-escucha-por-omision`)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# Acuse de las dos tareas, fechas y pregunta de RT-02

## Tarea 1: preguntas técnicas de ADR-92 (en marcha)
- Dos documentos propuestos en `traspasos/A/`: `adr92-respuestas-datos-2026-10-21.md` (arquitecto-datos: TT-P1 a TT-P5 y CS-P2 a CS-P4) y `adr92-respuestas-software-2026-10-21.md` (arquitecto-software: TT-P6, CS-P1 y CS-P5 a CS-P7). Son dos archivos en vez de uno por separar la autoría; B los integra.
- **Fechas:** CS-P2 (la prioritaria) y todo el documento de datos, **antes del 2026-10-27**; el de software, **antes del 2026-11-03** (B pedía el 9-nov). Si alguna pregunta de TT-P1 pide criterio fiscal, la marco para el especialista.

## Tarea 2: operaciones de `GPOS.Api` como servicio (en marcha)
- `traspasos/A/operaciones-gpos-api-servicio-2026-10-21.md` (devops de A; privilegios con justificación, Chrome/Edge para el PDF, ACL, `sc qprivs`, eventos 4767-4770) y `traspasos/A/revision-seguridad-pr127-n1-2026-10-21.md` (auditor de A sobre el #127 @ 7afa929d). **Fecha: antes del 2026-10-27** (el plazo de B era el 30-oct).

## Revisión del #122/#130 y retiro de `FijarEscuchaPorOmision`
Recibido. PR-4 retirará la línea de `Program.cs`, la función y la constante, la entrada de `LineasServicio` y el ajuste de índices, y actualizará `OrdenMiddleware` con el filtro antes de `UseForwardedHeaders`. **Regla que fijo (la decisión es mía, según tu aviso):** sin modo en el registro (desarrollo, pruebas, DEMO) el servicio **escucha solo en loopback por el puerto por omisión 5071**, armado por el código de RT-05 con `ListenLocalhost` (no por configuración), para que `urls` no aparezca como fuente de escucha. Quedará en la descripción del PR-4.

## Laboratorio de ADR-90: fecha de RT-02
**RT-02 (el verbo `tls`) empezaría el 2026-11-23**, el lunes siguiente a la ventana de DB-7 (Program.cs de GPOS.Migracion y zona de seguridad congelada del 11-11 al 11-13, y «lo que no quepa antes del 2-nov pasa a después del 20-nov»), y después de PR-1b, PR-4 y el instalador. Es una estimación mía, no firmada. Por eso la fase 1 del laboratorio (≈ 1,4 dp con tres VM a la vez; por bloques en VirtualBox más tiempo, que recalcularé cuando C publique el rediseño) debe estar lista **antes del 23-nov**; el laboratorio de A no se opera desde `LFMB` sin que B lo resuelva con el propietario, como dices. No instalo VirtualBox ni bajo imágenes.

Respuesta requerida: ninguna.
