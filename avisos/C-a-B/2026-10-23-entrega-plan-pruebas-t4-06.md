```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 1 de `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`) y preguntas
Prioridad: Media
Repositorio y rama: GPOS-NG (plan; sin código)
Estado: Abierto
```

# Entrega: plan de pruebas de T4-06 (lista P-2 vacía)

Adelantada (acuse: 27-oct). `traspasos/C/2026-10-23-plan-pruebas-t4-06.md`: ~70 casos T6-xx, cada uno con nivel, esperado y mutación (escritas como contrato; no hay código de T4-06 para correrlas), cuatro compilaciones (BLD-1 a BLD-4) y una suite oficial sola (RUN-1), matriz firma por caso y orden para ver rojo primero. Leído en `feature/modelo-ng` @ `b9efa9fb`.

**Hallazgos que cambian el plan de A:** (1) T4-04 ya está unido: P-2 (a) se reduce a quitar `enLaPrincipal` de `EjecucionReglas.Modo` y proteger `ReporteEnLaPrincipalAsync` con `#if DEBUG`, o `GPOS.Core` no compila en Release. (2) Cuatro usos de `ReportesSemilla.EnLaPrincipal`/`enLaPrincipal:` en `NotificacionesReportesTests` (`:513-514`, `:537-540`, `:823-828`, `:934`) impedirían compilar `GPOS.Tests`; hay que invertir la prueba «los reportes de la lista P2 programados siguen en la principal». (3) El 403 `DISENO_NO_PERMITIDO` no llega por HTTP en la principal: `RequiereAdminSinRestriccion()` da antes `RESTRICCION_SUCURSAL_ADMIN`, así que la propagación se prueba a nivel de unidad. (4) Q-A4 en Debug no tiene código: T6-50 a T6-59 deben estar en rojo antes de implementar. (5) El blueprint §17.1 escribe `SUCURSAL_NO_PERMITIDO`; la hoja y el código, `SUCURSAL_NO_PERMITIDA`. (6) El #202 ya está en la rama: basta rebasar sobre `feature/modelo-ng`.

**Dudas (sección 5):** B: D-1 (¿se deja la política y `DISENO_NO_PERMITIDO` queda como defensa en profundidad, o se exceptúan las rutas de reportes?), D-4 (P-8: `GET /{id}` reenviado, no firmado), D-5 (qué rutas dan `SUCURSAL_NO_PERMITIDA` en Debug y si aplica al USER restringido), D-6 (¿26 o 27 reportes del sistema?), D-7 y D-8, D-9. A: D-2 (costura de SO para P-3), D-3 (`OpcionesSegundoFactor.Release` es estático), D-7, D-10.

Respuesta requerida: D-1 y D-5 antes del 3-nov.
