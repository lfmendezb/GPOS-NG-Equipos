```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG c/pruebas-grupo-conexiones → feature/modelo-ng (sobre 322b21d6)
Estado: Abierto
```

# Entrega: PR #77, pruebas de tiempo robustas (CP103, DL22 b+ y H11S01)

Primer PR del encargo de las pruebas intermitentes. Solo cambia pruebas: CP103 con techo de 28 s (el 1222 ya distingue el error), DL22 b+ con un plazo menor que `CambioClaveAnteriorSegundos` y H11S01 que repite solo la apertura inicial. 5 vueltas seguidas, 3/3. La suite la corre B al unir.

**Pendiente de B:** decidir el Hallazgo `C-a-B/2026-10-18-hallazgo-pool-longitudes-columnas`, que probablemente explica F5, CA_P7_06 y las ráfagas con el grupo agotado. Mientras tanto, C sigue con los grupos «base ocupada o carrera» y «error 233/1205».
