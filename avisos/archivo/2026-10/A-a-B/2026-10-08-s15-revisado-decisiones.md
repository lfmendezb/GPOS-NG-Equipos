```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5 (6a93823)
Estado: Abierto
```

# S-15 revisado: Aprobado con observaciones; el propietario decidió las tres preguntas

Informe completo del auditor-seguridad de A: `traspasos/A/revision-s15-ola5-2026-10-08.md`. Sin hallazgos Críticos ni Altos; 5 Medios y 6 Bajos.

**Decisiones del propietario (2026-10-08):**
- **(a)** Reportes **no** acepta el token del modo limitado: la principal lo rechaza con motivo `esquema_pendiente`, reportes responde **503 `ESQUEMA_PENDIENTE`** (no 401) y además comprueba el claim, que se agrega a `ClaimsSesion`.
- **(b)** La principal pasa a `GPOS.Comun.Sesion.ClaimsSesion` para los claims del token; `permiso` y `acceso` quedan en `GPOS.Api`; `RevocacionSesiones.Valor*` usa `ProtocoloIntrospeccion.Motivo*`; prueba de arquitectura contra la duplicación.
- **(c)** `CuentaServidor` **sin valor por omisión**; la principal corre con identidad exclusiva (`NT SERVICE\GPOS.Api` o `IIS APPPOOL\GPOS.Api` sin solapamiento); fuera de desarrollo solo se aceptan SID `S-1-5-80-*` o `S-1-5-82-*`; el instalador escribe el SID (devops de A).

**Para B en `b/ola5`:**
- **Antes de unir el enganche:** S15-01, S15-02, S15-08 (`ValidAlgorithms`, parámetros JWT sin duplicar), S15-11.
- **Antes de producción:** S15-03 (reintento de la canalización), S15-05 (privilegios al arrancar, PA-76-1), S15-07, S15-09 (prueba elevada con dos cuentas virtuales; la prepara QA).
- **Antes de exponer reportes fuera del equipo:** S15-04 (limitación y prevalidación).
- S15-06 y S15-10: controles y notas; A registra la nota de ADR-109 cl. 6 cuando corresponda.
