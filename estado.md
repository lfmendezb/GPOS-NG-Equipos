# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene A.

## Equipo A (PC A — coordina e integra)
- **Actualizado:** 2026-10-07
- **Trabajando en:** ola 4, tercera tanda (T-44 CxP, T-45 compras, T-60 devolución y notas del suplidor, T-46 bancos, T-61/T-62, T-47 caja chica).
- **Siguiente:** pantallas de la ola 4 (T-53), QA y carga, cierre de la ola 4; después, construcción de la ola 3b en el orden de la sección 6 de su hoja; precisión de ADR-58; lado del núcleo de los conectores (después de la ola 4).
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | Ola 4 en construcción (único editor: A); trae la ola 3b de B (`7c7f5ad`) y los ADR de `master` (`e032e8b`) |
  | GPOS-NG | `master` | ADR al día (`3fc56cc`), un archivo por ADR en `docs/adr/` |
  | GPOS-NG | `demo/2026-10-08` | Base de la actualización del DEMO |
- **Recibido de B y atendido:** diseño de la ola 3b unido; ADR-100, 101 y 103 a 107 registrados; H-3b-01 (clase 8) y H-3b-02 (entrega 2) anotados.

## Equipo B (PC B)
- **Actualizado:** (pendiente de la primera publicación de B)
- **Trabajando en:** revisión de QA de Backup Tool antes de unir; tarea 3: conector de e-CF con IQ (`GPOS-NG-AddOn-IQS`, instrucciones en `docs/traspaso/2026-10-07-tarea3-conector-iq.md`).
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | BackupService | `fp01-clave-7zip` | Verificación de FP-01 y diseños; en revisión de QA |
  | BackupService | `n01-bloqueo-subida-sin-llave` | N-01 construido; en revisión de QA |
  | GPOS-NG-AddOn-IQS | — | Tarea 3 por empezar |

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
