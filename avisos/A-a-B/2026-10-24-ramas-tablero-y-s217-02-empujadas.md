Para: B        De: A        Fecha: 2026-10-24
Tipo: Entrega (ramas empujadas, sin PR; tanda 8 punto 2 y S217-02/S217-04)
Prioridad: Media
Estado: Abierto

# Ramas empujadas (sin PR: espero la orden del propietario)

| Rama | Punta | Base | Contenido |
|---|---|---|---|
| `a/tablero-r205` | `ac71e9c5` | `feature/modelo-ng` @ `1b310591` | R205-01 (`36be11d1`, web y MAUI), R205-02 (`6319bea5`), R205-03 (`ac71e9c5`) |
| `a/s217-02-nivel-token` | `3125ea59` | `feature/modelo-ng` @ `1b310591` | S217-02 (a) (`9b812c93`) y la prueba de S217-04 (`3125ea59`) |

**Evidencia (A, no la suite completa):** `TableroSucursalTests` 13/13 (antes 10); copia MAUI compila con 0 errores (`net10.0-windows10.0.19041.0`, según el agente; no filtré avisos nuevos); `TokenServicioTests` 65/65 (A) y filtro dirigido de token, introspección y notificaciones 100/100 (según el agente). Mutaciones en rojo reportadas por los agentes; A no las repitió.

## Para B
1. **R205-01 cambia lo que ve el usuario:** tras un error, al cambiar de período, los gráficos reaparecen junto a las tarjetas (es el remedio del informe). Si prefieres no hacerlo, se revierte `36be11d1`. R205-05 (el texto) sigue esperando al propietario.
2. **R205-03** se prueba por el camino de código del refresco automático (`CargarAsync()` por reflexión), no con el `PeriodicTimer` real, que no admite reloj falso.
3. **S217-02:** la regla va en la validación (`ValidadorTokenServicio`), no en la emisión: el nivel vigente solo se conoce al validar. Añade `ReglasAccesoAutor.NivelDelToken` (público, porque `GPOS.Api` no tiene `InternalsVisibleTo`). `EvaluarCuenta` ya rechaza las bajadas, así que en la práctica el claim es el nivel de emisión; el «menor» explícito evita depender de ese orden.
4. No probé el ascenso de punta a punta por `ProveedorContexto` en la API de reportes; sería una prueba aparte si la quieres.
5. **ADR candidata:** «Precisión de F-1 (S217-02 (a), firmada el 2026-10-23): el claim `nivel` del token de servicio es el menor entre el nivel guardado al emitir y el vigente al validar. Las bajadas invalidan el token; los ascensos solo valen en la siguiente emisión, igual que el JWT al iniciar sesión. Alternativa descartada: el nivel vigente al ejecutar (aplicaba el ascenso dentro de los 5 min de vida).»

Pendiente: R-04, R-09 y P-D2-04 (PR-D2); la nota de DB-7. Ramas ya empujadas sin PR: `a/tbs06-r212-pruebas`.

Respuesta requerida: ninguna.
