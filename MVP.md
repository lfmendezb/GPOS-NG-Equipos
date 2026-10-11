# Objetivos del MVP de GPOS Argón

**Fecha de documentación:** 11 de octubre de 2026. **Coordinación:** equipo B.

La lista F1–F10 y la meta fueron aprobadas por el propietario el 9 de octubre de 2026. Este documento consolida esas decisiones y sus últimos informes de avance; no añade objetivos ni modifica el alcance firmado.

## Meta y medición

- **Fecha de medición:** 1 de noviembre de 2026.
- **Meta mínima:** 70 % = **7 de los 10 flujos** completos.
- **Qué se mide:** flujos funcionando de punta a punta en la aplicación real, con sus pruebas; no porcentaje de código, pantallas ni tareas terminadas.
- **Cálculo:** flujos que cumplen su criterio / 10 × 100. Cada flujo cuenta una vez; un flujo parcial no suma.
- **Evidencia por flujo:** rama y commit integrados, escenario ejecutado, resultado esperado y obtenido, pruebas y defectos pendientes que impidan el recorrido.
- B consolida la medición; la aceptación final corresponde al propietario.

## Lista de objetivos

Los resultados esperados siguientes resumen la lista aprobada y la evidencia técnica publicada. No sustituyen los contratos ni las reglas de negocio de cada módulo.

| ID | Objetivo | Resultado esperado de punta a punta | Último estado documentado |
|---|---|---|---|
| **F1** | Inicio de sesión, usuarios y permisos | El administrador crea usuarios y asigna perfiles; el usuario inicia sesión y solo realiza operaciones autorizadas. La API exige cambiar la contraseña inicial antes de operar y aplica las restricciones de la cuenta. | Cuenta, según los informes de F1–F8 y la unión de sus correcciones. |
| **F2** | Alta de maestros | Crear, consultar y buscar artículos, clientes y suplidores; los datos quedan persistidos y disponibles para los flujos comerciales. | Cuenta, según los informes de F1–F8. |
| **F3** | Compra y recepción | Recibir una compra y facturarla, con existencia, costo promedio, kárdex y CxP coherentes. Facturar una orden ya recibida no duplica la existencia; las diferencias de precio aplican sus controles. | Cuenta desde la corrección D-MVP-02, integrada el 10-oct. |
| **F4** | Venta en Facturación Ágil con NCF | Un cajero vende desde su caja, emite la factura con NCF y registra correctamente el cobro y la salida de inventario. | Cuenta, según los informes de F1–F8. |
| **F5** | Factura de crédito y cobro por CxC | Emitir una factura a crédito, generar su cuenta por cobrar y aplicar un cobro con saldo y registros consistentes. | Cuenta, según los informes de F1–F8. |
| **F6** | Devolución con nota de crédito | Registrar la devolución contra la venta y emitir la nota de crédito, con los efectos correspondientes en inventario y en el cobro o la CxC. | Cuenta, según los informes de F1–F8. |
| **F7** | Caja: apertura, cierre y Z, con reimpresión | Abrir caja, registrar ventas y cobros, realizar el cierre y obtener el Z. Incluye la reimpresión de facturas: reimprimir únicamente el Z no satisface este objetivo. | Cuenta tras integrar el núcleo de caja (PR #8). |
| **F8** | Conteo, ajuste y kárdex | Aplicar un conteo físico, registrar el ajuste de existencia y verificar la trazabilidad y los saldos resultantes en el kárdex. | Cuenta, según los informes de F1–F8. |
| **F9** | Reportes básicos por la API de reportes | Consultar los reportes básicos mediante la API separada de solo lectura, sobre las vistas autorizadas, con el visor y los permisos correspondientes. | Cuenta desde la unión de la ola 5, `feature/modelo-ng` en `9fe5476`. |
| **F10** | Transferencias entre almacenes y sucursales (ola 3b) | Completar despacho, confirmación de salida y recepción por otro usuario; mantener tránsito, existencia global y costo coherentes, sin duplicar movimientos al reintentar. Incluye traslado entre almacenes de la misma sucursal. | Pendiente en los últimos informes consultados. Construye B; A revisa el núcleo. |

### Alcance firmado de F10

La precisión del 10 de octubre establece **F10 = tramo 1 sin diferencias**. Comprende el despacho y la recepción por sesión entre sucursales y el traslado entre almacenes de la misma sucursal. El despacho nunca deja negativa la existencia del origen.

El plan de prueba comprueba segregación entre despachador y receptor, reintentos idempotentes, tránsito en cero al completar la recepción y costo promedio sin cambio. Las diferencias, pérdidas y sobrantes de la transferencia pertenecen al tramo posterior y no condicionan que F10 cuente en esta medición. El plan admite la prueba de API para contabilizar F10; el recorrido Web es opcional para ese criterio.

## Avance publicado y límites de la evidencia

| Corte | Flujos que cuentan | Resultado | Evidencia |
|---|---|---|---|
| 9-oct-2026 | F1, F2, F4, F5, F6 y F8 | 6/10 = 60 % | Línea base QA en `e3a1d2b`; F3 bloqueado por duplicación de existencia y F7 por reimpresión de facturas. |
| 10-oct-2026, tras F3 y F7 | F1–F8 | 8/10 = 80 % | Núcleo de caja y D-MVP-02 integrados; referencia `97fde26`. |
| 10-oct-2026, tras la ola 5 | F1–F9 | **9/10 = 90 %** | Unión `9fe5476`; el coordinador informa MVP + F9 + arquitectura: 50/50. |

El último avance publicado supera la meta mínima del 70 %. **Es un estado reportado por el coordinador**, no una nueva ejecución de pruebas ni la aceptación final del MVP del 1 de noviembre. Para la medición final se debe verificar la rama integrada vigente y registrar sus resultados. Los conteos de suites completas que aparecen en los avisos son evidencia complementaria; no equivalen por sí solos al número de flujos completos.

## Alcance y prioridades relacionadas

- La prioridad del producto es **POS operativo, ventas e inventario**, con sus verticales; cada vertical tiene su propia ventana de facturación.
- **«Por despachar» no cuenta** para la meta del 1 de noviembre.
- El 70 % es el mínimo aprobado; completar F10 elevaría la lista a 10/10, sujeto a verificación.
- Esta lista no convierte todo el producto, todas las verticales ni todos los conectores en requisitos adicionales para la medición de diez flujos.
- Los reportes fiscales 606/607/608 y los apoyos IT-1/IR-17 están aplazados. La emisión NCF/e-CF, las secuencias y el cierre Z mantienen su prioridad operativa.
- El corte de la entrega 1 es **a mediados de diciembre de 2026**; es un hito distinto del MVP del 1 de noviembre.

## Fuentes

1. [Meta y lista F1–F10 aprobadas por el propietario](avisos/B-a-A/2026-10-09-mvp-70-por-ciento-1-nov.md).
2. [Línea base del MVP y bloqueos de F3 y F7](avisos/B-a-A/2026-10-09-mvp-linea-base-y-d-mvp-01.md).
3. [D-MVP-02 integrado: avance a 8/10](avisos/B-a-A/2026-10-10-d-mvp-02-unido.md).
4. [Ola 5 integrada: avance a 9/10](avisos/B-a-A/2026-10-10-ola5-unida.md).
5. [Precisión firmada de F10 y responsables](avisos/B-a-A/2026-10-10-ola3b-construye-b.md).
6. [Plan y escenarios de prueba de F10](traspasos/B/2026-10-10-plan-ola3b.md), sección 3, tramo 1.
7. [Prioridad de ventas e inventario](memoria/prioridad-ventas-inventario.md), [reportes fiscales aplazados](memoria/reportes-fiscales-aplazados.md) y [corte de la entrega 1](memoria/corte-entrega1-mediados-diciembre.md).

Al actualizar el avance, conservar la fecha, el commit y la evidencia; mantener esta lista y [la memoria del MVP](memoria/mvp-fecha-medicion.md) coherentes.
