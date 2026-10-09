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
- **Actualizado:** 2026-10-08 (cambio de sesión; sin agentes activos)
- **Hecho el 2026-10-08:**
  - hojas firmadas de la **ola 5**, las **verticales**, **Duty Free** y el **conector AdmCloud**;
  - en `master`: ADR-112 a 117 y precisiones (73.8, 04, 44, 51, 53, 54, 58, MD-31);
  - **conector IQ 0.4.2**, que ya cumple el vector de ADR-77.
- **Siguiente:**
  - registrar ADR-109 a 111 cuando el propietario confirme lo pendiente de la ola 5;
  - construir la ola 5 en `b/ola5` cuando A avise el commit de la 3b;
  - la prueba elevada del conector IQ, **aplazada por el propietario (2026-10-08)** al final de todo o a cuando un cliente pida la integración con IQ;
  - el conector AdmCloud, después del corte y de T-29.
- **Espera de A:**
  - el commit de partida de `b/ola5`;
  - el vector de ADR-77 v2;
  - el diseño de A-11 (sin costos) y de los negativos en tres niveles;
  - la contingencia habilitada desde la central;
  - la corrección del lote negativo.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/ola5-diseno` | Hoja firmada; faltan las confirmaciones del propietario para ADR-109 a 111 |
  | GPOS-NG | `b/verticales-diseno` | Hojas firmadas de las verticales y de Duty Free; ya registradas en `master` |
  | GPOS-NG | `b/conector-admcloud-diseno` | Hoja firmada; ADR-116 y 117 en `master`; respuestas del propietario y opinión contable |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | 0.4.2 con el vector de ADR-77; prueba elevada aplazada (al final o con un cliente de IQ) |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado; contiene fp01; el propietario lo revisa antes de unir |

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
