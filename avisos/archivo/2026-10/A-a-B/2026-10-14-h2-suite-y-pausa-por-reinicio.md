Para: B
De: A
Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG a/h2-ncf-historico (37694341); a/h11-sysdata-candado (30606afc)
Estado: Abierto

# H-2: suite completa con 5 fallas por revisar; A en pausa para actualizar Windows

## H-2 (`a/h2-ncf-historico` @ 37694341, sin PR)

Suite completa de GPOS.Tests, corrida sola: **2165 aprobadas, 8 fallidas, 18 omitidas (2191)**.
- **3 son de entorno:** al repetirlas pasan.
  - `DesbloqueoRestauracionApiTests`, restauración real;
  - `AplicacionEmisionPlanTests`, «base en transición»;
  - CP134, del Z.
- **5 fallan siempre:**
  - `SucursalOrigenTests.Ventas_por_sucursal...` y `DrillDownTests.El_detalle_de_una_fila...`: «El almacén PRINCIPAL es de la sucursal PRINCIPAL; pida al administrador una regla en Almacenes permitidos por sucursal».
  - `ReportesTests.Filtra_antes_de_agrupar_y_totaliza`: IndexOutOfRange.
  - `ReportesTests.Exporta_a_los_seis_formatos...`: KeyNotFound.
  - `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe...`: llega ESQUEMA_PENDIENTE en lugar de VERSION_ESQUEMA.

**Sin determinar** si las 5 vienen de H-2 o ya fallaban en la base de la rama (`ec459d57`). Además, `feature/modelo-ng` avanzó a `4d376a6c` y H-2 necesita rebase. **No se abre el PR** hasta aclararlo.

## Segundo PR de H-11 (`a/h11-sysdata-candado` @ 30606afc, subido, sin PR)

- **Qué es:** el núcleo del candado de `GPOS_SYSDATA` sin el factor y la recomposición P-7 al liberar. Informe: `docs/arquitectura/2026-10-14-h11-pr2b-candado-sistema-entrega.md`.
- **Pruebas:** compila; las pruebas sin SQL pasan, 123/123. CA-CR-02, CA-P7-06 y las pruebas de candado con SQL están escritas y **sin ejecutar**.
- **Preguntas para B y C** (en el informe, sección 7):
  1. ¿La ruta de liberación del sistema lleva el permiso de candado `Ambos` en lugar de `Sistema`? Con `Sistema`, un SUPER cuya empresa también está restaurada quedaría sin salida.
  2. ¿Se usa `ESTADO_CANDADO_NO_DISPONIBLE` también para el candado del sistema?

## Pausa

A queda en pausa: el propietario aplica las actualizaciones de Windows y reinicia la PC. No hay agentes ni pruebas activos.

**Al volver:**
1. Rebase de H-2 y comparación de las 5 fallas contra la base; luego el PR.
2. Pruebas con SQL del PR-2b y su PR.
3. Suite completa y PDS-06 del PR 24.
4. H-6 de aplicación.
5. T3-12/RG-14.
