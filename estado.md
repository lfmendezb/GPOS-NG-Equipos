# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene A.

## Equipo A (PC A — coordina e integra)
- **Actualizado:** 2026-10-09 (madrugada)
- **Hecho el 2026-10-08:** tanda del cierre de la ola 4 (607/608 sin e-NCF, moneda base, propina, Z, vendedor); rendimiento I-2 (`c92d858`; T-28 cumple, meta 1 de T-57 pendiente del 14-oct); vendedor obligatorio solo por la Política de campos (`c19f7ed`, `2078a08`); `FactorUnidad` en la venta (`d431973`). `feature/modelo-ng` en `origin` = `2078a08` (suite 1.662/0). En `master`: precisiones de ADR-51 (contingencia), 68 (reimpresión), 11, 04, 77 (P-77-2, P-77-4, vector v2) y `CLAUDE.md` al día.
- **Trabajando en:**
  - backend: corrección completa de `FactorUnidad` y del kárdex (migración `Ola4FactorUnidad`, reglas 51380-51386 y 51394, D-K1), antes del 14-oct;
  - documentador: ADR-078 (factor de unidad y auditoría del kárdex), F-3 de ADR-68, redondeo del vuelto (VF-06/VF-19), nota de la búsqueda sin tildes;
  - diseño: búsqueda sin tildes (arquitecto-datos), UX de equivalencias, reimpresión, kárdex en unidad base y conteo con unidad; auditor: `rpt` o `rptc` para identificaciones y diferencias de caja.
- **Siguiente:** 14-oct corridas oficiales de QA y decisión de la meta 1; commit de partida definitivo de `b/ola5`; 15-oct ADR-118/119 (T1, T2, T4); búsqueda sin tildes; tanda de núcleo de caja (reimpresión y redondeo); tanda 3: tabla de equivalencias (≈19 sp; sale de la entrega 1 si no cabe); ~22-23 oct integrar `rptsis`.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | `2078a08` en origin; `Ola4FactorUnidad` en construcción (único editor: A) |
  | GPOS-NG | `master` | ADR al día; un archivo por ADR en `docs/adr/` |
  | GPOS-NG | `demo/2026-10-08` | Base de la actualización del DEMO |
- **Espera de B:** SD-01 y `Propiedad` en `b/kds-k1` (revisa el auditor de A antes de unir); correcciones de las vistas de la ola 5 y `rptsis`; conector IQ (R-5 y modo de pruebas solo en Debug) antes de la primera instalación fuera de desarrollo.

## Equipo B (PC B)
- **Actualizado:** 2026-10-09 (madrugada; con agentes activos)
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

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
