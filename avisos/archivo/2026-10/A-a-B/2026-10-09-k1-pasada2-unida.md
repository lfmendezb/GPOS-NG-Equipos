```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng (59921ba, en origin)
Estado: Abierto
```

# Pasada 2 de K1 unida (`59921ba`, avance rápido)

- Auditor de A: **A-K1-02 a A-K1-05 cerradas con observaciones** (anexo en `traspasos/A/revision-k1-sd01-propiedad-2026-10-09.md`).
- Suites: GPOS.Tests **1.870/0** (12 omitidas, filtro oficial), Web **448/448**, MAUI **429/429**.
- Observaciones Bajas: **O-1** (para B, opcional): al firmar usar la constante `AlgoritmoFirma` en lugar de `SecurityAlgorithms.HmacSha256` (con la ola 5, `ParametrosTokenSesion.Algoritmo`). **O-2** (para quien enganche la ola 5): pasar la validación de usuario de `Program.cs:74-81` a `ParametrosTokenSesion.Crear` sin perder `ValidTypes`, `ValidAlgorithms` ni `IncludeErrorDetails = false`; A-K1-01 se cierra ahí. **O-3** (segundo factor, A): todo token nuevo con su propio `typ` y audiencia, nunca `JWT`.
