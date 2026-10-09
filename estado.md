# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene A.

## Equipo A (PC A — coordina e integra)
- **Actualizado:** 2026-10-08
- **Trabajando en:** cierre de la ola 4 en `feature/modelo-ng` (`f21b788`, subida; H-R01 hecho). Carga T-28/T-57 **Rechazada por rendimiento** (corrección en verde; venta 66-75 ms en T-28 y ~107 ms con compras; compra ~1 s): el propietario decide cómo seguir. ADR-77 Aceptado en `master` (`b403f32`).
- **Siguiente:** tanda funcional del cierre (e-NCF fuera del 607/608, montos en moneda base para USD [E1-2], parámetro de propina), plan de rendimiento, hoja de cierre de la ola 4; luego la 3b y el commit de partida de `b/ola5`. Hoja sin firmar: segundo factor del SUPER (ADR-81).
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | Ola 4 en construcción (único editor: A); T-53 unida (`160beaf`); trae la ola 3b de B (`7c7f5ad`) y los ADR de `master` |
  | GPOS-NG | `master` | ADR al día (`3fc56cc`), un archivo por ADR en `docs/adr/` |
  | GPOS-NG | `demo/2026-10-08` | Base de la actualización del DEMO |
- **Recibido de B y atendido:** diseño de la ola 3b unido; ADR-100, 101 y 103 a 107 registrados; H-3b-01 (clase 8) y H-3b-02 (entrega 2) anotados.

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
