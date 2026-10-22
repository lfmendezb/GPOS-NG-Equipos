```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (inventario de `ClearAllPools()`; insumo de tu decisión sobre el #153) y corrección de una cifra mía
Prioridad: Media
Repositorio y rama: no aplica (área común); lectura de `feature/modelo-ng`
Estado: Abierto
```

# Inventario de `ClearAllPools()`

Documento: `traspasos/C/2026-10-22-inventario-clearallpools.md`. Solo lectura; nada compilado ni ejecutado.

- **Corrección:** en el #153 y en mis avisos dije «38 llamadas en 15 archivos». Lo correcto es **43 llamadas en 19 archivos** (39 en `GPOS.Tests`, 4 en `GPOS.Reportes.Tests`). Verificado con `git grep`: las 2 que sobran en un conteo simple son comentarios de `BasesTemporales.cs`.
- **30 de las 43 son redundantes** (van antes de `BasesTemporales.EliminarAsync`, que ya vacía su pool): 26 se quitan sin más, 4 (DL22) se leen antes. 5 son de login/usuario (necesitan `ClearPool` de la cadena concreta antes del `DROP LOGIN`/`USER`), 4 de Reportes (higiene), 1 copia inline, 1 de rotación y 2 de Sellos (`ROLLBACK IMMEDIATE` deja conexiones muertas: motivo real).
- **No recomiendo la colección no paralela:** las 19 clases no tienen `[Collection]` ni `DisableParallelization` y corren en paralelo con la colección «bd» (27 clases); serializarlas entre sí no protege a las víctimas, que están en «bd».
- **Mi diagnóstico del #153 se mantiene:** `H11S01` y `CP103` no llaman a `ClearAllPools` (usan su pool propio); son víctimas, no causas.
- **Orden y esfuerzo:** quitar las 26 redundantes (~1–2 h), luego Reportes y la copia inline, luego leer DL22 y rotación, y al final login/usuario y Sellos con `ClearPool` de la cadena concreta. Dentro de los 0,5–1 dp que estimé, más una suite completa que corre B.
- **Riesgo principal:** `ClearPool(cadena)` solo vacía el pool de esa cadena exacta; si la app abre con otra (`ApplicationName`/`WorkstationID` distintos) el pool sobrevive.

Respuesta requerida: qué opción prefieres para el #153 (déjalo como está y aparte un PR de limpieza, o que lo haga yo por patrones).
