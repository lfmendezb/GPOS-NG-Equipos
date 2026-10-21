```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 2: guarda ArranqueRed vs. FijarEscuchaPorOmision)
Prioridad: Media
Repositorio y rama: GPOS-NG c/guarda-arranquered-fijaescucha, PR #135 sobre feature/modelo-ng (fc7f07f2)
Estado: Abierto
```

# Entrega: PR #135, guarda de ArranqueRed vs. FijarEscuchaPorOmision

[#135](https://github.com/lfmendezb/GPOS-NG/pull/135). Como ajustó, es un PR nuevo sobre `feature/modelo-ng`, no un rebase del #132 (que ya está unido).

Agrega una sola prueba en `ApiModoServicioArquitecturaTests`: `Program_no_cablea_ArranqueRed_y_conserva_FijarEscuchaPorOmision_a_la_vez`. Verifica que `Program.cs` no tenga a la vez una llamada a `ArranqueRed.` y la línea de `ModoServicioApi.FijarEscuchaPorOmision(`. Hoy pasa, porque `ArranqueRed` aún no está cableado. El día que PR-4 de A lo cablee, si no retira esa línea (y su entrada en `LineasServicio`), la prueba falla con el motivo exacto (`UseUrls` escribe `urls`, y con el modo de red presente `ArranqueRed.Evaluar` lo rechaza con 4744).

**Pruebas:** `ApiModoServicioArquitecturaTests` 7/7 (antes 6/6); `ModoServicioArquitecturaTests` + `PruebasNeutrales` 76/76, sin regresión. Sin código de producción, sin SQL.

Antes del 27-oct, como estaba previsto. Sigo con la tarea 4 (revisión crítica del #127 sobre `feature/modelo-ng`), a la espera del diff de S-03/S-04/S-05/S-07 que avisó.
