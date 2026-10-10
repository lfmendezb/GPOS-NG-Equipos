# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene el equipo coordinador (desde el 2026-10-09, el equipo nuevo con B).

## Equipo A (PC A — equipo de soporte desde el 2026-10-09)
- **Actualizado:** 2026-10-09, noche
- **Encargo de apoyo completado (2026-10-09):**
  - PR #6, demo ronda 2 (`a/mejoras-demo-ronda2`);
  - PR #7, H-RV-01/02 (`a/hallazgos-rv`);
  - PR #8, núcleo de caja, F7; seguridad aprobada (`a/nucleo-caja`);
  - PR #9, búsqueda sin tildes, F2/F4 (`a/busqueda-sin-tildes`);
  - PR #10, D-MVP-01, F1; seguridad aprobada, con R-a y R-b del propietario (`a/d-mvp-01`).

  Ninguno está unido. Orden sugerido: #8 antes que #10 (A rebasa el #10); #8 y #9 se reordenan por migraciones.
- **Cambio de rol:** por los apagones sin UPS, el propietario pasó la coordinación al equipo nuevo (Equipo B restaurado, más robusto). A trabaja en ramas `a/...`, sube y abre PR, no une; conserva el rango de ADR 68-99 (aprobado por el propietario). Ver `avisos/A-a-B/2026-10-09-coordinacion-pasa-al-equipo-nuevo.md`.
- **Hecho el 2026-10-09:** factor de unidad, kárdex e interfaz (`3324e43` a `472d078`), UF-03 y OB-03, login sin HTTP 400, K1 unido y su pasada 2 (`59921ba`; GPOS.Tests 1.870/0, Web 448/448, MAUI 429/429); ADR-078 y ADR-81 (TOTP) en `master` (`3a2d0bd`).
- **Trabajando en:** revisión de los PR de A: #9 entregado (Aprobado con observaciones); **#7 en revisión**, luego el #6 y después el ensayo del DEMO (`B-a-C/2026-10-09-ensayo-demo`). ADR de C: 130 a 159. Regla 8 cada 30 min (minutos 22 y 52).
- **Acuse (2026-10-09, 19:20):** recibido el encargo `2026-10-09-tareas-de-apoyo-para-a` (en orden: demo ronda 2 en `a/mejoras-demo-ronda2`, búsqueda sin tildes, núcleo de caja, H-RV-01/02) y sus reglas de apoyo. Recibidos también: la meta del MVP del 60 % (su definición queda en B, según el encargo), la suspensión de la documentación hasta el MVP, los hallazgos de reportes del tramo 2 (`rptsis` y `GPOS.Migracion` quedan en B), ADR-125, `COMANDERA` y los privilegios de cocina y Farmacia (sin acción ahora). A empieza cuando el propietario lo indique.
- **Traspasado al coordinador:** acuse y definición del MVP 60 %; T-57 del 14-oct y la meta 1; cierre de la ola 4; ADR-118/119 (T1, T2, T4); 3b y partida de `b/ola5`; `rptsis` y `GPOS.Migracion`; búsqueda sin tildes; tanda de núcleo de caja (reimpresión y redondeo del vuelto); tanda 3 (equivalencias, ≈19 sp); los «Pendientes del propietario» de este archivo. El coordinador puede encargar a A cualquiera de ellas como trabajo de soporte.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | `59921ba` en origin; desde ahora la une el coordinador |
  | GPOS-NG | `master` | ADR al día hasta ADR-81; libres en el rango de A: 79, 80 y 82 en adelante |
  | GPOS-NG | `feature/mejoras-demo-ronda2` | `87b90f8`, subida hoy; mejoras del demo, ronda 2, sin unir |
  | GPOS-NG | `demo/2026-10-07` / `demo/2026-10-08` | Subidas hoy; base de las actualizaciones del DEMO |

## Equipo B (equipo nuevo — coordinador desde el 2026-10-09)
- **Actualizado:** 2026-10-09, 19:10 (primera sesión en el equipo nuevo; sin agentes activos)
- **Coordinación:** confirmado el aviso `2026-10-09-coordinacion-pasa-al-equipo-nuevo`: B coordina (une a `feature/modelo-ng` y `master`, `CLAUDE.md`, manifiesto de pruebas, «Pendientes del propietario» y publicación de `memoria/` y `agentes/`). A trabaja en ramas `a/` y no une.
- **Entorno comprobado:** .NET SDK 10.0.401; 16 núcleos y 31 GB de RAM (límite de agentes por acordar con el propietario); paquetes de `gsf-local` con huellas correctas; carpetas `GPOS-B-ola5-construccion`, `GPOS-B-ola5`, `GPOS-B-verticales` y `GPOS-B-admcloud` creadas y al día con GitHub. `GPOS.Reportes.Tests` en `b/ola5` (`781b1eb`): 216/216 contra la instancia predeterminada (SQL Server 2025); contra `.\SQLEXPRESS` falla la creación de bases por permisos de su carpeta de datos (lo corrige el propietario).
- **Siguiente:** retomar la ola 5, tramo 2 (`b/ola5-tramo2-wip`, `f1d6025`), según `traspasos/B/2026-10-09-traspaso-B-corte-de-luz.md`; después, lo heredado de A (meta del MVP, T-57 del 14-oct, cierre de la ola 4, 3b).
- **Avisos de A vigentes:** `rpt-rptc-firmado`, `uf03-ob03-aprobados`, `ux-firmado` y O-1 a O-3 de `k1-pasada2-unida`.

### Registro anterior (PC B, madrugada del 2026-10-09)
- **Hecho el 2026-10-08 y el 2026-10-09:**
  - **K1 del KDS construido** en `b/kds-k1` (desde `feature/modelo-ng` `2078a08`):
    - SD-01 `a4b1a9b`, `Propiedad` `df79075`;
    - registro de dispositivos `dc40169`;
    - pantallas `ae6b7f6`, con QRCoder 1.6.0 aprobado por el propietario;
    - estación como servicio de Windows `44098a4`, con su informe `0c080ae`;
    - revisión de seguridad de B «Aprobado con observaciones» `8920d7a`, con correcciones en curso.
  - **`[LIC]` v3.2.5** en `b/lic-v32` (`dbf5048`): precisión de ADR-58 completa, dos confirmaciones del auditor; sin preguntas del propietario. Pedida la unión a master.
  - **Hoja de los conectores firmada.** En master `afa7519`: ADR-123 (ambiente productivo de todo conector) y ADR-124 (conector Polaris, sin puerta comercial). Tres repositorios privados (precisión de ADR-108 y 124, `2931106` y `f680ccb`): `GPOS-NG-AddOn-Kit`, `GPOS-NG-AddOn-IQS` (pasado a privado) y `GPOS-NG-AddOn-Polaris`.
  - **Guardas por superficie de los conectores** (`b/conector-admcloud-diseno` `17baccb`).
  - **Ola 5:** consultas de los reportes 17, 20 y de valuación; respuesta contable del CNT dentro de AU-11; PQ-01, 03, 04 y 05 cerradas (`b/ola5-diseno` `827a42f`). Defecto OB-03 del conteo avisado a A.
- **En curso:**
  - correcciones de seguridad de K1 (K1-01 a K1-07);
  - plan de extracción del kit y estructura de Polaris;
  - ventanas de las verticales ajustadas a FactorUnidad;
  - blueprint del KDS ajustado con lo de K1.
- **Siguiente:** construir el kit común y el conector Polaris (después de K1); ajustar las vistas de la ola 5 (TC-01 a TC-05) cuando A avise `Ola4FactorUnidad`; la ola 5 en `b/ola5` cuando A avise el commit de la 3b.
- **Espera de A:**
  - revisión de SD-01 y `Propiedad`;
  - unir `[LIC]` v3.2.5;
  - la cola de ADR-114 (filtro SD-08 de K1);
  - la acción previa de ADR-77 punto 3 en `instalador/AgenteImpresion`;
  - el commit de `Ola4FactorUnidad` y TC-03;
  - el commit de partida de `b/ola5` (3b);
  - las 6 pruebas que fallan en `2078a08`;
  - el párrafo de ADR-123 y 124 en `CLAUDE.md`;
  - OB-01 a OB-04 del conteo.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/kds-k1` | K1 construido; correcciones de seguridad en curso; se une tras la revisión de A de SD-01 y con SD-01 en master |
  | GPOS-NG | `b/lic-v32` | `[LIC]` v3.2.5, lista para unir |
  | GPOS-NG | `b/conector-polaris-diseno` | Diseño de Polaris y hoja firmada (ya copiados a master) |
  | GPOS-NG | `b/restaurante-kds-diseno` | Blueprint del KDS (se ajusta con K1) |
  | GPOS-NG | `b/ola5-diseno` | Hoja firmada; consultas 17, 20 y valuación |
  | GPOS-NG | `b/ola5` | Vistas revisión 3 y `rptsis`, sin aplicar |
  | GPOS-NG | `b/verticales-diseno` | Ventanas de las verticales (se ajustan a FactorUnidad) |
  | GPOS-NG | `b/conector-admcloud-diseno` | Hoja firmada; guardas por superficie |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | 0.4.2; prueba elevada aplazada |
  | GPOS-NG-AddOn-Kit / Polaris | `main` | Nuevos (solo README); construcción después de K1 |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado; contiene fp01; el propietario lo revisa antes de unir |

## Equipo C (antigua PC B, LAPTOP-DUMQQ5QK — soporte de B desde el 2026-10-09)
- **Actualizado:** 2026-10-09, noche (primera sesión como C; sin agentes activos)
- **Rol:** soporte de B junto con A; ramas `c/...`, PR sin unir. Recursos: 8 núcleos, 7,8 GB de RAM; rige el límite de agentes de la antigua PC B.
- **Trabajando en:** revisión de los PR de A: #9 entregado (Aprobado con observaciones); **#7 en revisión**, luego el #6 y después el ensayo del DEMO (`B-a-C/2026-10-09-ensayo-demo`). ADR de C: 130 a 159. Regla 8 cada 30 min (minutos 22 y 52).

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
