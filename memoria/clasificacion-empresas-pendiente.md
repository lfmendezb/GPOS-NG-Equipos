---
name: clasificacion-empresas-pendiente
description: "Funcionalidad pedida para después de master: clasificar cada empresa como Desarrollo, Beta, Producción o Demostración, con implicaciones distintas"
metadata:
  node_type: memory
  type: project
  originSessionId: f996b5de-a7ff-414c-a94d-a243315ed78c
  modified: 2026-10-03T16:59:20.498Z
---

El propietario pidió el 2026-10-02 una funcionalidad para **después de la unión de numeración a master**: indicar la clasificación de cada empresa.

| Clasificación | Qué es | Pérdida |
|---|---|---|
| **Desarrollo** | Las bases con que se desarrolla hoy | Se pueden borrar sin consecuencia |
| **Beta** | Empresas sobre la rama master, donde el propietario o un probador físico hacen QA | No es grave |
| **Producción** | El sistema en manos de clientes | Catastrófica para la empresa y su credibilidad |
| **Demostración** | Para presentar el sistema y formar a los agentes de integración, con datos ficticios | No es grave, pero las manejan terceros: siempre debe dar la mejor impresión y proteger la credibilidad de la institución |

**Why:** hoy no hay ninguna empresa en producción; todo es desarrollo. Por eso cambios como editar los dígitos de NCF (N-3) no tienen riesgo hoy, pero lo tendrán en Producción.

**How to apply:**
- Al diseñarla, que la clasificación gobierne las protecciones: confirmaciones antes de borrar, cambios fiscales delicados y avisos.
- Producción y Demostración son las de más cuidado.

**Datos de muestra (pedido del 2026-10-03):** las empresas clasificadas como **Demostración** deben tener la opción de **cargar datos de muestra** (artículos, clientes, suplidores, existencias y lo necesario para vender) para usar el sistema en presentaciones. Hoy no hay forma: la empresa DEV está vacía y no hay respaldos `.bak` en el equipo nuevo. Las plantillas de importación (J-3) pueden servir de base.

Pendientes del mismo lote, después de master:
- N-1: maestro de puntos de emisión;
- N-2: un punto de emisión por sucursal;
- N-3: dígitos de NCF editables;
- N-4: devoluciones y notas por detalle de productos.

Relacionado: [[devoluciones-son-notas-de-credito]].
