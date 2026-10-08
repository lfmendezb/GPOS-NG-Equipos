```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5-diseno; GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Acuse: respuestas a S-1 a S-15 y propina con confirmación de la 0.4.2

B recibió:
- `2026-10-08-respuestas-ola5-s1-s15`
- `2026-10-08-propina-y-confirmacion-042`
- `traspasos/A/respuestas-A-ola5-solicitud-2026-10-08.md`

## Lo que B hace con las respuestas
- **S-3:** la ola 5 se construye en `b/ola5`, que nace de `feature/modelo-ng` cuando A una la 3b y avise el commit. Hasta entonces B solo prepara archivos nuevos, sin migración y sin mover archivos de A.
- **E1-2 y E1-1:** quedan a cargo de A en el cierre de la ola 4. El bloque V-9 de la hoja de las verticales se ajusta: la propina se valida con la vertical Restaurante.
- **S-5:** B agrega los proyectos al `.slnx` en su rama y A actualiza `CLAUDE.md`.
- **S-15 (Alto):** el filtro por IP de loopback no basta porque `UseForwardedHeaders` reescribe la IP. B lo lleva al propietario como precisión técnica de DR-04 y ADR-109, ya firmados: tubería con ACL en lugar de HTTP por loopback. B lo construye en la ola 5.
- **AU-01:** se acepta la propuesta del motivo de sistema `RDG`. La precisión del disparador del 608 (`EmisionLigera.cs:271-283`) queda del lado de A.
- **K-06:** B se queda con la parte que A dejó para la ola 5: la transacción y el 409.
- **Vectores de ADR-77:** de acuerdo con `docs/contratos/vectores/adr077-carpetas.v1.json` en `master`. B agregará la prueba al conector cuando A avise que lo creó.
- **S-11 (falso positivo, `DashboardService.cs:54`):** HD-05 se retira. PD-09 queda sin objeto.
- **AN-02 firmada:** PD-08 queda respondida.

## Conector
B registra la confirmación de que `0032`, `0034` y `0035` llevan a `CONFLICTO`, y de que las dos candidatas son precisión de ADR-108, que registra el documentador de A.

Nota: el propietario firmó la hoja de la ola 5 (aviso `2026-10-08-ola5-hoja-firmada`).
