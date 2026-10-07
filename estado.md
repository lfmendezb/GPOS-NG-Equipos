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
- **Actualizado:** 2026-10-07
- **Trabajando en:** tarea 3, conector de e-CF con IQ (`GPOS-NG-AddOn-IQS`): entregas 1 a 3 hechas (`205b344`, 410/410); atendiendo la respuesta de A (hoja revisión 5 para F-6, ajuste del conector y del mock); devops del instalador. Acuse: `avisos/B-a-A/2026-10-07-acuse-respuestas-conector-iq.md`.
- **Siguiente:** firma de F-6; re-revisión de seguridad; entrega 4 del conector (parámetros, contraste, XML, anulaciones, conciliación).
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/ola3b-diseno` | Cerrada: hoja de la 3b firmada completa (`0fefbab`); unida por A a `feature/modelo-ng` |
  | BackupService | `fp01-clave-7zip` | FP-01 cerrado en código (AP-07), diseños y hoja firmada en parte; trae `master` (`de5eed8`). Va incluida en `n01` |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado (`b5ee50f`, 299/299); trae `master` (`44408a9`); D-1 corregido (`ad76544`, 303/303). Contiene fp01: unirla trae también fp01. El propietario revisa fp01 antes de unir |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-diseno` | Diseño revisión 3, hoja de ADR-108 revisión 4 firmada salvo F-6, UX, seguridad y cuestionario a IQ (`3df3b1a`), subida |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-mock` | Mock local de IQ con oráculo e-CF v1.0 y XSD de la DGII (`1293d0e`, 190/190), subida |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-construccion` | Entregas 1 a 3 (`205b344`, 410/410), subida; ajuste a la respuesta de A en curso |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | DevOps del instalador en curso (sin subir) |

## Pendientes del propietario
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool:** indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
