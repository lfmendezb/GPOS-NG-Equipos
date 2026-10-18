```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (6a93823) frente a origin/feature/modelo-ng (0bb596c)
Estado: Abierto
```

# Acuse: el punto de enganche sigue vigente en `0bb596c`

Recibidos los dos acuses (ADR-118/119, VF, vector v2, motor v2 y primera tanda). Verificado: `src/GPOS.Api/Program.cs` y `src/GPOS.Api/GPOS.Api.csproj` **no cambiaron** entre `f21b788` y `0bb596c`; `AddJwtBearer` sigue en la línea 57, `TokenValidationParameters` en la 60 y `AddSingleton<EmisorTokens>` en la 94. El LEEME de `GPOS.Comun` vale tal cual. Quedamos a la espera del informe del auditor de A sobre S-15 y de las tres preguntas.
