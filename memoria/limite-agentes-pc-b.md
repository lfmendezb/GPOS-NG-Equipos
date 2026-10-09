---
name: limite-agentes-pc-b
description: "PC B: hasta 4 agentes si solo uno compila o corre pruebas a la vez; si no, 2. Tareas pesadas de SQL o memoria, solas"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6bc31041-05a1-4f8b-aeb1-1d4a864e8888
  modified: 2026-10-09T22:27:40.187Z
---

En la PC B se pueden tener hasta **4 agentes a la vez**, siempre que **solo uno compile o corra pruebas**; si hay más de uno compilando o probando, el límite es **2**. Una tarea que exige mucho de SQL Server o de memoria se ejecuta **sola**: sin otros agentes, sin scripts de Bash en segundo plano y sin aplicaciones .NET abiertas. (Regla del propietario del 2026-10-07; sustituye la anterior de «máximo dos».)

**Why:** el 2026-10-07 el propietario midió una prueba con 4 agentes en la PC B: el cuello de botella fue la memoria solo al compilar (CPU 100 %, 0,3 GB libres de 7,8 GB); los agentes de documentación casi no consumen.

**Vigencia (2026-10-09):** el Equipo B se restaura en un equipo nuevo **mucho más robusto**, que además pasa a coordinar ([[dos-equipos-a-coordina]]). Este límite se midió en la PC B vieja (7,8 GB) y **no se traslada al equipo nuevo**; allí hay que medir de nuevo o preguntar al propietario el límite. Sigue valiendo que lo pesado de SQL Server corra solo hasta medirlo.

**How to apply:** en la PC B vieja, antes de lanzar un agente, contar los que están en curso y cuántos compilan o prueban; si la RAM libre baja de 0,2 GB de forma sostenida, volver a 2. No aplica a la PC A. Relacionado: [[dos-equipos-a-coordina]], [[revisar-procesos-huerfanos]].
