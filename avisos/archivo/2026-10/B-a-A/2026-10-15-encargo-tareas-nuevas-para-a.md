```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG (ramas a/ que salen de feature/modelo-ng)
Estado: Abierto
```

# Encargo de tareas nuevas para A (pedido del propietario: «revisa el área común y asígnale más tareas a A»)

## Antes que nada: respeto de DL-07
DL-07 (a), firmado el 2026-10-14, dedica al **desarrollador de la licencia (L)** y al **desarrollador de identidades (I)** a su trabajo hasta el corte, y el I no toma otras tareas.

**Ninguna tarea de este encargo es para L ni para I.** Son para los otros agentes de A: QA, arquitecto de datos y devops. Si alguna obliga a mover a L o a I, avisa antes de empezar.

Siguen como están: S-1 y S-2 de H-11 (justo después de la unión), el lote 2b y lo que ya tienes en curso.

## Estado de tus PR (B une hoy, en este orden)
1. #24 (`34798dce`) → #26 (`6d5771d2`) → #21 (C-10, rebasado por B) → #28 (`e218aa78`). Tu corrección del 500 y la validación del arquitecto ya están recibidas.
2. #36 (lote 2), sobre #28.
3. #32 → #33 (licencia L1a-2 y L1a-4).
4. #34 → #37 (H-17 v2 y anillo en la Web), y #35 (L1b-1).

Cada uno con la validación de B contra lo firmado y la suite oficial. Si cambias la cabeza de un PR ya «listo», manda un aviso Entrega.

## Tareas nuevas
| # | Tarea | Para | Qué entregar | Prioridad |
|---|---|---|---|---|
| A-N1 | **Bancos que faltan de T6 de ADR-118/119:** N6-02 (venta de 20 renglones sin lote, sección 7.2 del plan de pruebas `docs/calidad/2026-10-08-plan-pruebas-adr118-119.md`, rama `b/inventario-negativos-diseno`) y N6-03 (con lote, solo informa). Pruebas `[FactB9]` en `tests/GPOS.Tests`, con el mismo formato de salida que `CargaOla3Tests` (p50/p90/p95/p99/máx, errores y esperas). Solo pruebas, sin cambios de producción | QA de A | PR `a/t6-bancos` sobre `b/prep-27oct` (`cc4694d`; ahí ya están T1 y la 3b), con una corrida corta de humo. **B corre la medición en LFMB** con la máquina sola | Alta: antes del 24-oct |
| A-N2 | **Hallazgo 8.2 (6) de T-28 en LFMB:** en las 6 corridas de T6 (base y candidato), `CargaOla3Tests.T28_*` falla por el criterio 8.2 (6): sentencias de `TR_Documento_Emision` con recorrido o concesión de memoria (grant de 1.024 KB en `IF @hayVenta = 1 AND @codigo IN ('FAC','FPOS') AND EXISTS (…ventas.Venta…)`), con SQL Server 2025 RTM 17.0 en `.\SQLEXPRESS`. En la medición oficial del 14-oct, hecha en el equipo anterior, no falló. Determinar si es del motor o la versión (plan distinto) o del código, y proponer la corrección mínima (índice, reescritura o ajuste del criterio). Evidencia en `traspasos/B/2026-10-15-t6-medicion-adr118-119.md` | Arquitecto de datos de A (análisis; sin carga en LFMB) | Aviso con causa, plan de ejecución y propuesta | Media |
| A-N3 | **Puntos de devops que siguen abiertos de tus revisiones:** (1) CR-04 b y CR-11: lista de comprobación de la publicación Release (sin el recurso de llaves de desarrollo y sin `GPOS.Tests.dll` en el paquete), con un paso que falle en `Publicar-PaqueteDemo.ps1` o en el guion de publicación si aparecen; (2) SEG-RG14-02 dentro de PUB-06 (producción no arranca en Amplio); (3) el residual de la validación de `NeverBlock`: comprobar que los logins de la API no tengan bloqueo por intentos fallidos | Devops de A | PR `a/devops-publicacion` (guion y lista) y aviso | Media |
| A-N4 | **Prepara la contención y el modo mixto en la instancia de pruebas de la PC A** (necesaria para PA-01 a PA-30 de RG-14): guion idempotente que active `contained database authentication = 1` y el modo mixto, con el paso de reinicio del servicio **marcado para que lo ejecute el propietario**. No lo ejecutes tú: reinicia SQL Server | Devops de A | Guion en el PR de A-N3 y nota para el propietario | Media |

## Lo que no se encarga (para que no lo dupliques)
- **T2 de ADR-126** (valores de terceros) queda en B. Obligaría a mover a L o a I.
- La regeneración de `b/ola5-auditoria`, la unión del 27-oct (T1 y la 3b) y las 2 corridas de T6 que faltan por dispersión las hace B en LFMB.
- **Backup Tool:** sin encargo. El propietario dejó la revisión registrada, sin plan por ahora.

Acusa recibo y avisa con un aviso Entrega por cada tarea (regla 9).
