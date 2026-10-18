```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng ad6015d; master f5e73b0
Estado: Abierto
```

# Unidos a feature/modelo-ng (ad6015d): DEMO 10b, revisión del DEMO y valores de terceros; ADR-126 registrado en master

B reanuda en el equipo nuevo (LFMB) tras el traspaso de emergencia del 2026-10-14.

## Qué se unió (por encargo del propietario del 2026-10-14)
- **`feature/modelo-ng` `4d376a6..ad6015d`**, en este orden:
  1. `b/demo-2026-10-10b` (`4e98949`): los scripts del DEMO corregidos tras el ensayo (DM-09, DM-11 y DM-12), la actualización con `-Demo`, el LEEME y la guía. **DM-10 sigue abierto.**
  2. `b/demo-revision-1` (`bb18382`): los puntos 1 a 3 de la revisión del propietario, en Web y MAUI.
  3. `b/config-terceros` (`ad6015d`): solo la propuesta firmada VT-01 a VT-12. La construcción va en T1.
- **Sin conflictos.** Ninguna migración ni contrato de la API cambia.

## Cómo se verificó (sobre ad6015d)
- **Compilación:** 0 errores en `GPOS.Tests`, `GPOS.Web.Tests`, `GPOS.UI.MAUI.Tests`, `GPOS.Reportes.Tests` y `GPOS.AgenteImpresion`.
  - En el equipo nuevo falta el origen NuGet local (`C:\Users\lfmen\source\NugetLocalFeed`), así que la restauración se hizo con `--ignore-failed-sources`.
  - `GPOS.UI.MAUI` no compila para Android en este equipo: el SDK 10.0.301 no ve los workloads de la banda 10.0.100. Lo resuelve el propietario.
- **Pruebas:**
  - `GPOS.Web.Tests`: 610/610.
  - `GPOS.UI.MAUI.Tests`: 538/538.
  - `GPOS.Tests --filter Categoria=Mvp`: 22/22 en `.\SQLEXPRESS` y 22/22 en `.`.
  - **No se corrió la suite completa**: el cambio es de interfaz, scripts y documentos.

## master (f5e73b0)
- **ADR-126**, «Ningún valor de un tercero en el código», registrado con el índice y `CLAUDE.md`. Quedan libres para B: 127 a 129.
- La lista de pruebas del DEMO 10b pasó a commit normal.
- El WIP de la URL del padrón quedó como commit normal en `b/config-terceros` (`c6b7193`). Le faltan las dos pruebas de O-3 (T1).
- **Las ramas `respaldo/2026-10-11-*` siguen en origin.** Su contenido ya está en esos commits; se borran cuando el propietario lo confirme.

## Lo que NO se unió y por qué
| Rama | Motivo |
|---|---|
| `b/adr118-119-t1` y `-ui` | PQ-3 de ADR-119: la unión es el 27-oct, solo con todo en verde |
| `b/ola3b` | Contiene T1. Va después de T1 |
| `b/ola5-auditoria` | El auditor-seguridad dio «Aprobado con observaciones», pero no encontró el documento firmado de AE-01 a AE-04. El arquitecto-datos dio «Confirmado con cambios»: la migración `20261010171353` cae entre T1 (`…153018`) y la 3b (`…183053`), así que hay que **regenerarla después de la 3b**. Además, la unión automática con la 3b deja `SecExportacion` dentro de `SecuenciasNodo.Fundamentos` (debe ir en `Todas`), y en un nodo distinto de 1 la secuencia nace con el rango del nodo 1. Falta la QA de AE-09 y AE-10 |
| Ramas de diseño (`verticales-diseno`, `conector-*`, `ola5-diseno`, `restaurante-kds-diseno`, `farmacia-principio-activo`, `inventario-negativos-diseno`) | Solo documentos; no forman parte de esta tanda |

## Para A
- Las ramas que salen de `feature/modelo-ng` (por ejemplo `a/rg14-lote1`, desde `4d376a6c`) pueden traer `ad6015d` sin riesgo: solo cambia `instalador/Demo`, seis pantallas Razor (Web y MAUI) y documentos.
- **Pregunta de ADR-82** (aviso `2026-10-14-rg14-firmado`): la paso al propietario. Mientras decide, B no lo prepara.
