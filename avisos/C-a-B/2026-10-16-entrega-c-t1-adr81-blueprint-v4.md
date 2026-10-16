```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr81-fase-a @ 3d26fdef (con push, sin PR todavía)
Estado: Abierto
```

# C-T1, parte 1: el diseño de la fase A de ADR-81 está al día (blueprint v4); T-a y T-b en construcción

## Qué se entregó
- `docs/arquitectura/2026-10-16-adr81-fase-a-blueprint-v4.md`: cambios V4-01 a V4-16 frente a la v3, cada uno con su evidencia en el código de `ce33b2a8`.
- `docs/decisiones/2026-10-16-preguntas-adr81-fase-a-v4.md`.

**Cambios principales:**
- El SQL va en `Consultas/Sistema/SegundoFactor/` y se engancha por `ExtensionesEsquemaSistema`.
- `EsquemaSistema.Version` sube de 3 a 4. Lo aplica `GPOS.Migracion sistema`, así que P-81A-03 ya se cumple.
- `BitacoraSeguridad` reutiliza la tabla de A (#26) y le agrega la purga, el limitador y la consulta.
- El catálogo de eventos incluye los de DL-04.
- `ISelladoCuenta` es un enganche para no depender de SL.
- Las rutas declaran su clase de licencia.

**Esfuerzo:** 18 tandas, T-a a T-r, ≈ 8,5 sp (±30 %).

**Unión:** después de T1, T2 y T4 de ADR-118/119, que todavía no están en `feature/modelo-ng`.

**En construcción ahora:** T-a (fundamentos TOTP, sin base de datos) y T-b (esquema). Ninguna de las dos depende de las preguntas abiertas.

## Hallazgos para A (verificados en el código)
- **H-V4-01 (Alta):** en el modo Estricto, `gpos_api` no tiene `EXECUTE` sobre `ReconciliarRestauracionSistema` ni sobre `LiberarCandadoRestauracion` (`PrivilegioMinimoSistema.cs:124-137`). Si se restaura `GPOS_SYSDATA`, el SUPER queda sin salida. Hoy no afecta porque nadie usa Estricto. El lote de permisos de C lo incluye de forma idempotente, pero lo propio es que A lo agregue en S1.
- **H-V4-02 (Media):** la ruta `liberar` del candado no declara clase de licencia (`RestauracionEndpoints.cs:65-75`). Con `UseLicencia` activo caería en Operativa.
- **PR #49:** no comparte archivos con la fase A. Solo cambia la expectativa de la prueba PF-18.

## Preguntas para firma del propietario (el diseño sigue la opción (a) recomendada)
- **P-81A-15:** con la vía (b), que `restablecer-factor` vuelva a sellar, con la misma excepción que ya tienen los verbos de `GPOS.Migracion` (ADR-83). Hace falta antes de T-j.
- **P-81A-16:** S-02 a S-04 piden autenticación reciente (ADR-81, punto 14) y no `CodigoSegundoFactor` en el DTO. Afecta los DTO de A.
- **P-81A-17:** marcar como Esencial las siete rutas del factor y la liberación del candado. Hace falta antes de activar `UseLicencia`.

## Para B
- Asignar el número de la marca de esquema al unir.
- Llevar las preguntas P-81A-15 a 17 a la firma del propietario.
