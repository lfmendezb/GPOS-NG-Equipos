# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene A.

## Equipo A (PC A — coordina e integra)
- **Actualizado:** 2026-10-07
- **Trabajando en:** QA de la ola 4 completa y carga T-57. Hechas: tandas tercera a sexta (huecos de API, cierre de sucursal, parámetros, B-1 a B-3) y pantallas T-53, en `feature/modelo-ng` (`80b5f37`, sin push).
- **Siguiente:** cierre de sucursal (diseño aprobado por el propietario, al final de la ola 4), QA y carga T-57, hoja de cierre de la ola 4; después, construcción de la ola 3b; lado del núcleo de los conectores. Respuestas a A-01 a A-19 del conector de IQ: en preparación por el arquitecto-software.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | Ola 4 en construcción (único editor: A); T-53 unida (`160beaf`); trae la ola 3b de B (`7c7f5ad`) y los ADR de `master` |
  | GPOS-NG | `master` | ADR al día (`3fc56cc`), un archivo por ADR en `docs/adr/` |
  | GPOS-NG | `demo/2026-10-08` | Base de la actualización del DEMO |
- **Recibido de B y atendido:** diseño de la ola 3b unido; ADR-100, 101 y 103 a 107 registrados; H-3b-01 (clase 8) y H-3b-02 (entrega 2) anotados.

## Equipo B (PC B)
- **Actualizado:** 2026-10-07 (noche)
- **Trabajando en:**
  - **Conector IQ:** MSI **0.4.1** sin firma (`80b667d`, 533/533). Trae SF-01 a SF-14, ADR-74, 75 y 76 en el conector, K-16, K-18 y K-19, y la acción `ComprobarCarpetasPrevias` contra las uniones. La verificación del auditor de 0.3.1 y 0.3.2 está unida (`49f38b7`).
  - **Diseño de la ola 5** (aprobado por el propietario), en `b/ola5-diseno`: API de reportes de solo lectura sobre vistas, requisitos contables y vistas (`edafb2f`). Las respuestas del propietario están en `07eb6e9`, y **el corte de la entrega 1 pasa a mediados de diciembre**. El arquitecto-maestro prepara la hoja de firma.
  - **Diseño de las ventanas por vertical** (aprobado), en `b/verticales-diseno`: Estándar, Farmacia, Restaurante con mesas y comandas (se reabre MD-31) y Duty Free. Se mantiene el cronograma: se construyen en la entrega 3.
- **Siguiente:** hojas de firma de la ola 5 y de las verticales; auditor de 0.4.0 y 0.4.1; prueba elevada del propietario (paso 0 y luego §10); entrega 4 del conector.
- **Avisos de B pendientes de lectura por A** (todos del 2026-10-07):
  - `sf02-identidad-servidor-tuberia`
  - `conector-iq-032-manifiesto-y-servicio`
  - `acuse-adr108-k16-k19-y-sf02`
  - `conector-iq-040-para-el-nucleo`: P-04 y P-05
  - `conector-iq-041-instalado-y-carpetas`
  - `api-reportes-solo-lectura`: orientación del propietario
  - `fallos-vistas-fiscales-607`: **Alta**, H-R01, H-R02 y HD-10 en código de A
  - `ola5-corte-mediados-diciembre`: **Alta**, afecta el plan de A
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/ola5-diseno` | Diseño de la ola 5 (solo `docs/`), subida; hoja de firma en preparación |
  | GPOS-NG | `b/verticales-diseno` | Diseño de las ventanas por vertical (solo `docs/`), en curso |
  | GPOS-NG | `b/ola3b-diseno` | Cerrada; unida por A a `feature/modelo-ng` |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado (`ad76544`, 303/303). Contiene fp01; el propietario lo revisa antes de unir |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-diseno` | ADR-108 Aceptado; fila F-6 marcada (`4a05291`) |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-mock` | Mock de IQ (`1293d0e`) |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-construccion` | Entregas 1 a 3 (`c3db950`); quedó atrás de la rama del instalador |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | **0.4.1** (`80b667d`): es la rama viva del conector |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-auditoria-032` | Unida al instalador (`49f38b7`) |

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
