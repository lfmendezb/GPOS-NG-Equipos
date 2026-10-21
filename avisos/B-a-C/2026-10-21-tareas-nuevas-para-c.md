```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Encargo (tareas nuevas; propuesta)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` y `master` (según la tarea)
Estado: Abierto
```

# Tareas nuevas para C

Lo anterior sigue vigente y va primero: scripts del laboratorio (1-nov), revisión crítica del #127 (29-oct), PR de documentos P126 (3-nov) y plan de pruebas de E-1 de ADR-93 (5-nov). Estas tareas son **después**, o en paralelo solo si la capacidad lo permite. **Nada se une sin orden expresa del propietario.** Las fechas son propuestas de B; díganme si no caben.

## Tarea 1: archivos dorados de T4-01 (Ola 5, tramo 4)
- **Qué:** un archivo dorado por tipo de formato y papel, para detectar si el HTML o el PDF cambia al mover el render a la API de reportes (riesgo R-T4-05, formatos fiscales).
- **Fuente:** `docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md`, sección de T4-01.
- **Dependencia:** puede empezar antes de que T4-01 compile. B avisa cuando abra el PR de T4-01 (previsto hacia el 27-oct). T1-7 (#119) ya está unida.
- **Fecha propuesta:** 2026-11-06.

## Tarea 2: pruebas que fallan en la suite y pasan solas
- **Qué:** diagnosticar y arreglar, un commit por causa:
  - `BaseNoDisponibleApiTests.H11S01`
  - `Rg14Lote2Tests.Estricto_exige`
  - `NumeracionMotorTests.CP103`
  - `CompraVariableTablaTests.C10`
- **Por qué es de C:** hizo #125 (pruebas inestables). Quita ruido de cada unión, y la suite oficial es la evidencia de los PR.
- **Condición:** solo pruebas, sin código de producción, salvo que la causa lo exija (en ese caso, avisar antes).
- **Fecha propuesta:** 2026-11-13.

## Tarea 3: casos del laboratorio para Chromium y las comprobaciones del paquete
- **Qué:** casos de laboratorio para Chromium bajo la cuenta virtual del servicio (R-T4-07: sin Edge ni Chrome en el servidor, perfil sin permisos, sandbox que no arranca) y las comprobaciones R1 a R10 del paquete único.
- **Fuente:** `docs/operaciones/2026-10-19-diseno-instalador-reportes.md` y el plan del tramo 4.
- **Cuidado:** el laboratorio corre en `LFMB` con VirtualBox y por bloques (una VM a la vez). No presupongan más memoria de la que dejó la tarea anterior.
- **Fecha propuesta:** antes del 2026-11-20, porque el laboratorio fase 1 debe estar listo antes de RT-02 (2026-11-23).

## Tarea 4: borradores de los cuestionarios de catering y del contador (CC-01 a CC-05)
- **Qué:** redactar los cuestionarios, sin enviarlos, para que el propietario los revise. Hoy los prepara B.
- **Fecha propuesta:** 2026-11-06.

## Tarea 5: revisión crítica de los PR de D1 de DB-7 (T1-1 a T1-4)
- **Qué:** revisión crítica de cada PR, con el plan de pruebas de D1 que C entregó el 2026-10-20.
- **Fecha:** 5 días hábiles desde que B avise de cada PR (T1-1 entre el 11-02 y el 11-03).

Respuesta requerida: acuse con fechas, indicando cuáles aceptan.
