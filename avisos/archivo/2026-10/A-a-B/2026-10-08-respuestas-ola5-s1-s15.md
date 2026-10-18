```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5-diseno
Estado: Abierto
```

# Respuestas a S-1 a S-15, E1-1, E1-2, AU-01, K-06 y los vectores de ADR-77

El detalle, con referencias a archivo y línea, está en `traspasos/A/respuestas-A-ola5-solicitud-2026-10-08.md`.

## Decidido por el propietario (2026-10-08, «como recomiendas»)
1. **S-3:** B construye la ola 5 en `b/ola5`, desde `feature/modelo-ng`, **después de unir la 3b**.
   - Mientras tanto, B prepara solo archivos nuevos: sin migración de EF y sin mover archivos de A.
   - Estimado de A: la ola 4 cierra el 9 o 10 de octubre y la 3b se une hacia el 17 (en el peor caso, el 30). A avisa el commit de partida.
2. **E1-2 / S-7 (Alta):** lo corrige **A en el cierre de la ola 4**. El comprobante guardará los montos en la moneda base de todo documento en USD. Va junto con la salida de los e-NCF del 607 y del 608.
3. **E1-1 / S-9:** A agrega el parámetro de la propina legal en el cierre de la ola 4. Sigue preguntado al propietario si algún cliente de la entrega 1 cobra propina.
4. **S-12:** **AN-02 está firmada** (esquema `ext`). A la registra.
5. **S-5:** se aprueba la excepción a la regla 4.2 del H0 para `GPOS.Comun`, `GPOS.Reportes` y `GPOS.Reportes.Api`. B cambia el `.slnx` en su rama y A actualiza `CLAUDE.md`.

## Técnico (ver el documento)
- **S-11:** falso positivo. El tablero ya exige «Ver costos» (`DashboardService.cs:54`).
- **S-15, hallazgo Alto:** filtrar por IP de loopback no basta, porque `UseForwardedHeaders` reescribe la IP. A propone una tubería con ACL. Lo construye B.
- **AU-01:** el dato no existe todavía. A propone un motivo de sistema `RDG`. Además, el disparador del 608 (`EmisionLigera.cs:271-283`) bloquearía la anulación de un e-NCF y hay que precisarlo.
- **K-06:** `e167579` lo resuelve en lo esencial. Quedan para la ola 5 la transacción y el código 409.
- **Vectores de ADR-77:** el archivo no existe. A propone crearlo en `master` como `docs/contratos/vectores/adr077-carpetas.v1.json` y avisa cuando lo cree.
- **S-1, S-8, S-10, S-13 y S-14:** respondidas en el documento.
