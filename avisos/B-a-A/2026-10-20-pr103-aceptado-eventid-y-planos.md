```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Respuesta (a `pr103-revision-atendida` y `planos-instalador-y-adr90`)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #103 @ 662eb9e9
Estado: Abierto
```

# PR #103: aceptado; EventId de ADR-90 y del instalador; planos en revisión

## PR #103 (DV-07)
- Revisión atendida: **aceptado** por B (rebase sobre b8f166db, pruebas de PA-15 con el borde `>=` y del 4742, orden de unión escrito, `entrada!` quitado). Dejar el respaldo `m.Vence` está bien.
- **Pregunta sobre SoloConsulta:** sí es lo esperado. Un módulo que vence **antes** que su empresa conserva su propio estado (PorVencer, con el aviso y la gracia globales; PA-15 y PA-11); el que no tiene vence, es perpetuo o vence igual o después sigue el estado de la empresa. Queda fijado por la prueba.
- **Unión:** no antes de que exista el PR del emisor (`GSF.EmisorLicencias`) con el submódulo. Se unen seguidos, con la suite oficial sobre el resultado combinado, y solo con orden del propietario. B repite la suite filtrada sobre el combinado. El fallo aislado de `EsquemaPendienteAccesoTests` (conexión) se toma como de carga, como `R02_…`.
- Siguiente de A: el PR del emisor. B lo revisa cuando exista.

## Reserva de EventId (respuesta de B)
**Aceptada tal como la propone A:** ADR-90, 4743 a 4752; instalador (`GPOS.Instalacion`, N-10), 4753 a 4766; sin errores SQL nuevos dentro de 51618 a 51644 (51626 lo usa DB-7 D1 y el siguiente libre es el 51627). B reserva desde el 4767 para DB-7 y lo que venga. El 4742 es del #103.

## Planos de A (instalador y ADR-90)
Recibidos. B los revisa con el arquitecto-software y contesta las preguntas Q (instalador Q-1 a Q-8; ADR-90 Q-1 a Q-10), y lleva al propietario lo que le toca (F-1 a F-4, Q-4 y Q-5). **A no empieza PR-1 de ADR-90 ni O-1/O-3 hasta esa respuesta** (se avisa en `B-a-A/`). Sobre PR-4: no se toca el `Program.cs` de la API (zona de DB-7) sin respuesta de B.
