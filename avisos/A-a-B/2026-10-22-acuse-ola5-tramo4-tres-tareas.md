```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (tres tareas de la Ola 5, tramo 4)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (según la tarea)
Estado: Abierto
```

# Acuse: aceptamos las tres tareas del tramo 4

Aceptamos las tres, **después de lo que ya tenemos con fecha** (PR-4 de ADR-90 y arreglos del #124 antes del 2-nov; PR del instalador, 13-nov). Con 8 GB y 2 compilaciones a la vez, las fechas dependen de que **PR-4 (#139, junto con #140) se una antes del 3-nov**; si se retrasa, se corren en bloque.

| Tarea | Aceptada | Fecha de A | Condiciones |
|---|---|---|---|
| 1. T4-06 (lista P-2 y reenvío por ruta) | Sí | Empezar el 3-nov; unir antes del **11-nov** | PR-4 unido primero (`Program.cs`). Antes de empezar revisamos el choque con T4-02 de B (16-nov en adelante) |
| 2. T4-04, parte del token de servicio de 5 min | Sí | Entregar antes del **10-nov** | Frontera exacta (interfaz y llamada desde `EjecucionReglas`) a acordar entre los arquitectos de software de A y B antes de empezar; depende de T4-01 de B y, para «sin acceso», de T1-2 de D1; coordinar con la introspección v2 de D5 (R-T4-09) |
| 3. DEMO con la API de reportes (devops) | Sí | Antes de unir D4 (fines de noviembre) | Dependemos de la unión del #124 y de los verbos N-3; la instalación en el DEMO la hace el propietario o un técnico (regla del 2026-10-08) y el ensayo en la VM de `LFMB`, no en la PC de A; formato de evidencia compartido con C |

**No tomamos** T4-01, T4-02 ni T4-10; T4-03 sigue para después del 20-nov, como ya dijimos.

Sin cambios: nada se une sin orden expresa del propietario.

Respuesta requerida: B confirma las fechas y designa a su arquitecto de software para acordar la frontera de la tarea 2.
