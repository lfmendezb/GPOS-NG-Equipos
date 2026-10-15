```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG master @ f6bf5914
Estado: Abierto
```

# Firmas del propietario: PUB-06, `gsf`, precisiones del #44 y C-3 (registradas en `master`, `f6bf5914`)

## Respuestas literales del propietario (2026-10-15, sesión de B)
| Punto | Respuesta | Registro |
|---|---|---|
| Hoja de PUB-06, PB-1 a PB-7 | «Aprobado con observaciones.» | Todo en la opción recomendada: PB-3 como hallazgo, PB-6 (a), PB-7 (b) para la entrega 1 y (a) con el agente. Textos 4.1 en ADR-44 y 4.2 en ADR-82 |
| `gsf` con `CHECK_POLICY = ON` (BL-03) | «Aprobado» | ADR-44. **El comando lo ejecuta el propietario**, en LFMB (`.\SQLEXPRESS`) y en la PC A |
| Precisiones del #44 | «Aprobado» | ADR-82, punto 2: logins `gpos_srv_api` y `gpos_srv_respaldo`. ADR-82, punto 9, y ADR-83, punto 3: Amplio negado ante **cualquier** licencia `Produccion` o `Beta` aceptada |
| C-3 | «Aprobado» | Se quitó la marca de pendiente en ADR-62 y ADR-84 |

**Pendiente:** la P-4 del blueprint v2.5 (`ANILLO_NO_ADMITIDO` en caliente). El propietario pidió contexto; B lo avisará cuando decida.

## Hoja de PUB-06
Actualiza su sección 7 con este registro.

## Dudas de nombres (A, por favor)
1. **`gpos_srv_api`:** se registró solo como el login SQL de la variante S. ¿Cambia también el usuario `gpos_sistema` de `NT SERVICE\GPOS.Api` (ADR-82, punto 2)?
2. La precisión de AC-4 en ADR-82 llama `gpos_respaldo_srv` al login de Backup Tool; lo firmado dice `gpos_srv_respaldo`. Si es un error de nombre, B agrega una nota del registro.

## Para B (devops)
Actualizar la lista de publicación Release (`docs/operaciones/2026-10-15-lista-publicacion-release.md`) con M3 y M5 firmados, y hacer `Instalar-Demo.ps1` con `GPOS.Migracion sistema` (#44).

## Agregado (más tarde, el mismo día)
- **P-4 del blueprint v2.5:** «Punto 5 La P-4 del blueprint v2.5 Aprobado». Registrada en ADR-83, punto 3, en `master` (`c01a4332`).
- **`gsf` en LFMB:** el propietario ejecutó `ALTER LOGIN [gsf] WITH CHECK_POLICY = ON` en `.\SQLEXPRESS`. B lo comprobó: `is_policy_checked = 1`. **Falta la PC A**, con su instancia: que lo ejecute el propietario allí.
