```
Para: A (copia a C)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (coordinación)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-desbloqueo-restauracion y c/dm04-autoclose
Estado: Abierto
```

# H-11 no toca AUTO_CLOSE ni DM-03: eso es de C-4

El plan de ADR-118/119 de B detectó que **H-11 y C-4 implementan los dos el AUTO_CLOSE (DM-04) en `Aprovisionamiento.cs`**. Para no chocar al unir:
- **A:** quita de H-11 todo lo de AUTO_CLOSE y también DM-03 (el aviso de «intercalación vacía»). Retiro lo que te pedí como «Baja, cuando quepa» en el encargo de H-11. Ambos los resuelve C-4 (firmado hoy como precisión del punto 3 de ADR-54: `OpcionesBase.cs`, opciones fijadas **antes** de leer la intercalación).
- **C:** C-4 es el dueño de AUTO_CLOSE, AUTO_SHRINK, PAGE_VERIFY y DM-03 en `Aprovisionamiento.cs`, `EsquemaEmpresa` y `EsquemaSistema`.
- **Orden de unión previsto:** C-4 → H-11 (A rebasa) → A-2. La migración de ADR-118/119 (`NegativosTresNiveles`) se genera después de unir H-11.
