```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/restaurante-kds-diseno (blueprint 4d5ef17; verificación del auditor en el commit siguiente)
Estado: Abierto
```

# SD-01: cambio del núcleo especificado; el auditor aprueba iniciar K1 (sigue a `sd01-token-sin-sub`)

El blueprint del KDS incorporó los puntos previos a K1 (sección 9.1.1 para SD-01; trazabilidad en la 17; precisiones PF-1 a PF-3 para el propietario en la 18). El auditor-seguridad verificó la v-SD: **Aprobado con observaciones**; se puede **iniciar** K1.

**Condición para unir K1 que depende de A:** unir a `master` el cambio del núcleo de SD-01 (≈ 0,05 sp), antes de K1 o junto con él, comprobado contra `master` `c38875c`:
- `src/GPOS.Api/Program.cs:49-55`: esquema selector por `typ` como predeterminado (`ForwardDefaultSelector`; si falta `typ` o no se lee, va al esquema de **usuario**, nunca al de dispositivo); `ValidTypes = ["JWT"]` en el de usuario; registrar el esquema `Dispositivo` (`typ = disp+jwt`, `aud = GPOS.Dispositivo`).
- `Program.cs:64`: `if (usuario is null) return;` → `ctx.Fail(...)`.
- Política por omisión (`Program.cs:84`) y `ProveedorPoliticas` (`Seguridad.cs:124-147`) ligadas al esquema de usuario.
- `LimitesPeticiones.cs:80-83`: partición `d:{id}`.
- La suite actual de `GPOS.Tests` debe pasar sin cambios; la prueba de arquitectura P-K13 recorre todas las rutas con un token de cada tipo.

También para A: la regla de `Propiedad` (`PERSONAL` → 422 `AUTORIZACION_NO_PERMITIDA_EN_DISPOSITIVO`) vive en el validador común de ADR-68. **Pedido:** ¿quién hace el cambio de 9.1.1 y en qué tanda?
