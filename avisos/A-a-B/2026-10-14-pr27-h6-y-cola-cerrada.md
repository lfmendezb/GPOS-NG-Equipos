Para: B (conocimiento de C)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG a/h6-motivo-sin-ncf (b0d4d34a), PR 27 (base: a/h2-ncf-historico, PR 25)
Estado: Abierto

# PR 27: H-6 de aplicación. La cola de A queda cerrada salvo las firmas

## PR 27
- https://github.com/lfmendezb/GPOS-NG/pull/27, apilado sobre el PR 25.
- **Qué hace:** el motivo del usuario es obligatorio al elegir «No generar comprobante»:
  - 15 caracteres como mínimo (P-9) y 200 bytes como máximo; si no, 422 `MOTIVO_NO_GENERAR_INVALIDO`;
  - el motivo se guarda en la autorización `SIN_NCF` y en `_LOG`;
  - lo piden la Web y MAUI;
  - se mantienen el privilegio y H-7.
- **Pruebas:**
  - GPOS.Tests: 2257 aprobadas, 5 fallidas (las de la base) y 1 de la guarda de textos, ya corregida (53/53);
  - Web: 636/636;
  - MAUI: 556/556.
- **Nota:** en `_LOG` el motivo se recorta a partir de 108 caracteres (varchar(200)); el texto completo queda en `doc.Autorizacion` y en `audit.Bitacora`.

## Estado de la cola de A al cierre del 14-oct
| Tarea | Estado |
|---|---|
| H-2 y H-3 (con H-4, H-6 datos, H-7 y CT-1) | PR 25 |
| PR 24 (H-11, PR 1) | Suite limpia; PDS-06 con firma pendiente |
| PR-2b de H-11 | PR 26, apilado sobre el 24 |
| H-6 de aplicación | PR 27, apilado sobre el 25 |
| T3-06, T3-08, T3-12 y RG-14 | Diseño listo; hoja D-01 a D-11 por firmar |

**Orden de unión sugerido:** 25, 27, 24 y 26.

## Pendiente de B, C o el propietario
- **Firma de PDS-06:** paso 1 o 2 del plan de reserva.
- **Firma de D-01 a D-11 (RG-14).**
- **Respuestas para el PR 26:** `Ambos` o `Sistema`, y `ESTADO_CANDADO_NO_DISPONIBLE` en el candado del sistema.
- **Las 5 fallas de `feature/modelo-ng`:** asignar quién las corrige.

A queda **sin tareas en curso**, esperando las firmas o un encargo nuevo.
