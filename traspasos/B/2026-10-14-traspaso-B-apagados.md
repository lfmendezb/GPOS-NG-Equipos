# Traspaso del equipo B — 2026-10-14 (el equipo se apaga de repente)

Segundo traspaso de emergencia (el primero fue el 2026-10-11). **Sin agentes activos al cerrar.**

## Estado de los repositorios (verificado al cerrar)
- **Todo el código está en GitHub.** Las 15 ramas de los árboles de trabajo coinciden con `origin`; `GPOS-NG-Equipos`, `GPOS-NG-AddOn-Kit`, `-IQS`, `-Polaris` y `Backup Tool` están limpios y sin commits por subir.
- Cambios sin commit, ya respaldados:
  - `master`: `docs/operaciones/2026-10-10-lista-pruebas-demo.md`, idéntico en `respaldo/2026-10-11-master-lista-pruebas-demo`.
  - `GPOS-B-config-terceros`: `TrabajoRncDgii.cs` y `appsettings.json` (URL del padrón RNC a la configuración, VT), idénticos en `respaldo/2026-10-11-b-config-terceros-wip`.
  - `GPOS-B-admcloud`: `GPOS.Api.csproj` con una línea `ProjectExtensions` de Visual Studio, ruido que se descarta.
- `GPOS-B-carga` está en un HEAD suelto en `4d376a6` (`feature/modelo-ng` después de unir #22 y #23), que ya está en GitHub.

## Respaldo fuera de GitHub
OneDrive `Instalador\GPOS ARGON\Respaldo equipo B 2026-10-14\`: agentes, skills, memoria (66 archivos, con la medición del 14-oct), `settings.json`, `.claude` del proyecto y resultados `Oficial-14oct-r2` de T-28/T-57. Se restaura igual que el del 11-oct (LEEME incluido).

## Ramas de B
| Rama | Commit | Estado |
|---|---|---|
| `b/adr118-119-t1` | f7d5206 | T1 + T2 + T4 servidor y seguridad; sin unir (unión prevista el 27-oct) |
| `b/adr118-119-ui` | 0308ce7 | T4 de interfaz; sin unir, junto con T1 |
| `b/ola3b` | 7971d9e | tramo 1 rebasado sobre T1, F10 en verde; falta la suite completa |
| `b/ola5-auditoria` | 67b0629 | lote AE-01 a AE-04; falta la revisión del auditor, AE-09/AE-10 (QA) y confirmar con arquitecto-datos el cambio de la migración `Ola5AuditExportacion` |
| `b/config-terceros` | f209a70 | VT-01 a VT-12 firmadas; ADR-126 por registrar en master; T1 desde el 14-oct |
| `b/demo-revision-1` | aca9b04 | revisión del DEMO 10b, puntos 1 a 3; sin unir |
| `b/demo-2026-10-10b` | 1e1a393 | paquete DEMO publicado; DM-10 abierto (reportes sin la API aparte) |
| `b/rendimiento-14oct` | de3e814 | recalibración 8.2 (5) de T-28 |
| `b/ola5`, `b/ola5-visor`, `b/ola5-diseno`, `b/verticales-diseno`, `b/conector-admcloud-diseno`, `b/d-mvp-02` | — | sin cambios desde el último traspaso |

## Hecho el 14-oct
- Medición oficial T-28/T-57 r2: todas las metas en verde (`2026-10-14-medicion-oficial-t28-t57.md`, 59b1984). Topes del +5 % para T1: T-28 ≤ 33,4 ms y venta T-57 ≤ 84,0 ms.

## Al reanudar (en este u otro equipo)
1. Clonar o actualizar los repositorios; recrear los árboles de trabajo de las ramas de arriba. Restaurar agentes, skills y memoria desde OneDrive si es otro equipo.
2. Pasar a commits normales el contenido de las dos ramas `respaldo/2026-10-11-*` y luego borrarlas.
3. Camino crítico: unión de T1 (27-oct) → `b/ola3b` → `b/ola5-auditoria` → H-11 parte 2 y H-2 de A → PR #21.
4. Encargo pendiente del propietario: `Iniciar-Demo.ps1 -RedLocal` (Web en `0.0.0.0:5054`, API con HTTPS en la red, firewall solo en el perfil Private, que crea el propietario).
5. Volver a armar el Monitor del área común solo cuando lo indique el propietario.
