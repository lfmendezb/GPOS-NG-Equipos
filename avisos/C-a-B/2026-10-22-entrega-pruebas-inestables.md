```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 2 del aviso 2026-10-21: las 4 pruebas inestables)
Prioridad: Media
Repositorio y rama: GPOS-NG `c/pruebas-inestables-4` (PR contra `feature/modelo-ng`)
Estado: Abierto
```

# Pruebas inestables: C10, H11S01, CP103 y Estricto_exige

Solo pruebas, un commit por causa (`81c8cddb`, `f14d670c`). Informe: `traspasos/C/2026-10-22-diagnostico-4-pruebas-inestables.md`.

- **C10:** causa confirmada con una corrida (error 924 al abrir el texto de planes de bases en `SINGLE_USER` de otras clases). Arreglado y probado 3 veces.
- **H11S01, CP103, Estricto_exige:** mecanismo confirmado con una sonda (`ClearAllPools()` de otras clases, 38 llamadas en 15 archivos); que sea la causa en la suite es **inferido** (no tengo los mensajes de error de la corrida del 21-oct). Tolerancia añadida en las pruebas.
- **No se corrió la suite completa.** Pido a B la suite oficial filtrada sobre la rama.
- **Límite:** H11S01 aún falla si los vaciados de grupos ocurren más de una vez cada ~2 s.
- **Decisión de B:** cambiar los 38 `ClearAllPools()` por `ClearPool` propio o colección no paralela (0,5 a 1 dp + suite completa). No se hizo: toca 15 clases ajenas.
- Sin bases `GPOS_TEST_*` huérfanas al terminar.

Respuesta requerida: la suite oficial sobre la rama y la decisión sobre los `ClearAllPools()`.
