```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (6a93823), desde feature/modelo-ng f21b788
Estado: Abierto
```

# Ola 5, primera tanda en `b/ola5` (punto 3 del encargo): solo archivos nuevos

- **Proyectos nuevos:** `src/GPOS.Comun`, `src/GPOS.Reportes`, `src/GPOS.Reportes.Api` y `tests/GPOS.Reportes.Tests` (90 de 90 pruebas, 3 s). **Único archivo existente tocado:** `GPOS-NG.slnx` (4 líneas, S-5). No se corrió `GPOS.Tests` ni carga.
- **S-15 para tu revisión:** servidor de introspección `ServidorIntrospeccion` en `GPOS.Comun` (canalización con nombre; ACL solo para `NT SERVICE\GPOS.Reportes`; la principal solo crea instancias; sin acceso por red; `FirstPipeInstance`; comprueba la identidad del cliente; falla cerrada). Cliente en `GPOS.Reportes.Api` (caché de 15 s por SHA-256, verifica que el dueño de la canalización sea la principal; 503 `PRINCIPAL_NO_DISPONIBLE` si no responde).
- **Punto de enganche en la principal** (detalle con líneas de `f21b788` en `src/GPOS.Comun/Introspeccion/LEEME-enganche-principal.md`): referencia a `GPOS.Comun` en `GPOS.Api.csproj`; `ValidadorTokenPrincipal : IValidadorTokenLocal` con los parámetros JWT de `Program.cs:57-86` y `RevocacionSesiones`; registro tras `Program.cs:94` dentro de `OperatingSystem.IsWindows()`.
- **Para decidir A:** si el token del modo limitado (`ModoEsquemaPendiente`) se acepta en reportes; pasar la principal a `GPOS.Comun.Sesion.ClaimsSesion` (hoy copia de `GPOS.Api.Seguridad.Claims`); la cuenta de servicio de la principal (`GPOS:Introspeccion:CuentaServidor`).
- **Fuera de esta tanda:** vistas `rpt`/`rptc`/`imp`/`rptsis` (tocan tu mecanismo de esquema; al unir), credenciales selladas, migración de rutas y de `ReportesService`, reportes fiscales (aplazados) y motor v2 (después del corte).
- `b/ola5` se rebasa o une cuando avises el commit de partida definitivo tras la ola 4.
