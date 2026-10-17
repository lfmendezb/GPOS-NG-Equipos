```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #67 (a/rn-cambio-rnc @ da474174, base a/sl-sello-padron = #63)
Estado: Abierto
```

# PR #67: RN «Cambio de RNC» (DL-03 (a) con P-3; RN-F2 (a) firmada hoy)

## Qué entra
- **Cambio del RNC, solo del SUPER**, con fila MAC en `GPOS_SYSDATA` y evento crítico.
- **P-3 con RN-F2 (a):** se conserva la hora del primer cambio, así que la renovación ya no sirve para operar con otro RNC.
- **Configuración del ADMIN:** 409 si se cambia o se vacía un RNC fijado.
- **Verbo provisional** `empresa --cambiar-rnc`: exige el anillo y acepta `--aceptar-digito`.
- **S-03:** sin mapear hasta la fase A.
- **S-05** `GET /api/super/eventos-servidor`: el SUPER ve los eventos de los verbos de RNC y de `sellos`.
- **RNC reales sin dígito verificador:** se aceptan por el padrón de la DGII (`dbo.RncDgii`) o con `--aceptar-digito`.
- **Bloqueo:** de sesión, sin pool, con 409 `CAMBIO_RNC_EN_CURSO`.
- **Eventos:** el motivo se enmascara y se marca la fila ausente.

## Verificación
- **Arquitecto:** Conforme con correcciones; C-1 a C-3 aplicadas. Informe en `traspasos/A/validacion-rn-cambio-rnc-2026-10-17.md`.
- **Seguridad:** Aprobado con observaciones, sin Críticos ni Altos; RN-01 a RN-05 corregidas. Informe en `traspasos/A/revision-seguridad-rn-cambio-rnc-2026-10-17.md`, ya con el dictamen de RN-04.
- **Pruebas dirigidas en la PC A:** 950/0/1. A las repitió tras una compilación limpia: RN + sellos, 106/106.

## Para B
- **Orden de unión:** #63 → #67. Cuando se una el #63, A reapunta el #67 a `feature/modelo-ng`.
- **No es neutro para T6** porque agrega una ruta. Va con el #63, después del 27-oct.
- **Registrar en ADR-83:** RN-F2 (a), aviso `2026-10-17-firma-rn-f2`.
- **Para firma (RN-F1):** la primera asignación del RNC por el ADMIN, en una empresa sin RNC, está permitida hoy, y DL-03 (a) dice «solo lectura desde ya».
  - **Recomendación del arquitecto y del auditor:** permitirla. Solo el ADMIN se perjudicaría, y un RNC distinto del licenciado deja la empresa `Invalida`.
  - Ya valida el dígito y el padrón, igual que S-03.

## Para C
- **Suite oficial del #67**, junto con el #63.
- **Fase A:** mapear S-03 con `RequiereAutenticacionReciente()` y darla de alta en `RutasLicenciaAprobadas.json`.

## Pendiente
- **Web:** aviso de S-05 al entrar el SUPER, la lista en Diagnóstico y el RNC de solo lectura para el ADMIN.
- **L:**
  - `CAMBIO_RNC_EN_CURSO` y `RNC_*`, en `CodigosLicencia`;
  - R-2, caché del RNC a 60 s.
- **Datos:** precisión de 2.3 sobre el bloqueo de sesión.
