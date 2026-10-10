```
Para: C            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Encargo (aprobado por el propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG demo/2026-10-08 (6f07a7f) y feature/modelo-ng (ebd121a)
Estado: Suspendido por el propietario el 2026-10-09 — NO iniciar
```

# Encargo: ensayo de la actualización del DEMO en el equipo C

> **SUSPENDIDO (2026-10-09):** el propietario pidió detener este ensayo inmediatamente después de publicarlo («espera, detén ese ensayo»). **No lo inicies ni toques nada del DEMO.** Si ya empezaste, detente, no modifiques nada más y avisa en `avisos/C-a-B/` qué alcanzaste a hacer. B avisará si se reanuda.

El propietario aprobó el 2026-10-09 que C haga el ensayo de la actualización del DEMO en LAPTOP-DUMQQ5QK (pendiente suyo: «probar la actualización del 2026-10-08 y medir la importación de suplidores y clientes»). Va **después** de tu primera tarea (revisión de los PR #9, #7 y #6), salvo que el propietario te pida otro orden.

## Alcance
1. **Inventario** de lo que hay instalado del DEMO en tu equipo (versión, bases, configuración de memoria de SQL Server: hoy 1.024 / 3.072 MB) y de qué trae la actualización (`demo/2026-10-08` `6f07a7f`; dile al propietario si conviene actualizar ya a lo que hoy tiene `feature/modelo-ng` `ebd121a`, con la ronda 2 y el PR #8).
2. **Ensayo sobre una copia, nunca sobre las bases reales:** respaldo `COPY_ONLY` de las bases del DEMO, restauradas con otro nombre (`GPOS_TEST_DEMO_*`), y aplicación de los scripts de actualización (SQL idempotente) sobre la copia, dos veces para comprobar la idempotencia. Verificación con pruebas automatizadas o consultas de solo lectura.
3. **Medición de la importación** de suplidores y clientes con el volumen del DEMO sobre la copia (las pruebas `ImportacionTercerosTiempoTests` sirven de guía), con la máquina sola.
4. **Guía paso a paso** para que el propietario aplique la actualización real (respaldo previo, orden, verificación y cómo revertir), en `traspasos/C/`.

## Límites (obligatorios)
- **Las bases reales del DEMO son intocables:** no se modifican ni se borran; solo se respaldan con `COPY_ONLY`. La actualización real la ejecuta el propietario con tu guía, o con una orden expresa suya.
- **Sin instaladores, servicios ni programas que abran ventanas**, y nada que pida elevación (regla del 2026-10-08). Cambiar la memoria de SQL Server es configuración del equipo: proponla, no la apliques.
- Sin suites completas ni cargas mientras corran otros agentes en tu equipo.
- Resultado en `avisos/C-a-B/` con lo encontrado, las cifras y la guía.
