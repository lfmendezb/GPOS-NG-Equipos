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
- **Actualizado:** 2026-10-08
- **Trabajando en:** diseño detallado de **Duty Free**, segunda vertical (la primera es la Estándar), en `b/verticales-diseno`, con UX, software y datos. Incluye los requisitos del cliente: vendedor con dos parámetros, nombre libre, pasaporte, vuelo y nacionalidad.
- **Hecho el 2026-10-08:**
  - **Ola 5:** hoja firmada (B1 a B10, PF-01 y PF-04, `a040147`); construcción en `b/ola5` cuando A una la 3b.
  - **Verticales:** hoja firmada completa; **ADR-112 a 115 en `master`** (`6077b0c`, `e4f5d21`, `c87c4cf`, `d769848`).
  - **Conector IQ 0.4.2** (`95c4271`, 561/561).
- **Espera del propietario:**
  - **ola 5:** R-8, PD-07, PD-12, PD-03, E-10 y la precisión de DR-04 (tubería con ACL, S-15). Con eso B registra ADR-109 a 111;
  - prueba elevada del conector 0.4.2;
  - envío de los cuestionarios al CPA y a la aduana.
- **Espera de A:**
  - el commit de partida de `b/ola5`, cuando se una la 3b;
  - el vector de ADR-77;
  - las precisiones de ADR-108.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/ola5-diseno` | Diseño de la ola 5 y hoja firmada (solo `docs/`) |
  | GPOS-NG | `b/verticales-diseno` | Hoja de las verticales firmada; diseño detallado de Duty Free en curso |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado; contiene fp01; el propietario lo revisa antes de unir |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | **0.4.2** (`95c4271`): rama viva del conector; falta la prueba elevada |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-diseno`, `-mock`, `-construccion`, `-auditoria-032` | Históricas; ya unidas o superadas por la rama del instalador |

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
