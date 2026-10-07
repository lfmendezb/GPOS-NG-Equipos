# Nota de traspaso del equipo A (actualizada al cierre de la sesión del 2026-10-06)

Pegue en la sesión nueva de esta PC: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\Solucion GPOS NG\traspaso-A-2026-10-07.md` y retoma desde ahí».

## Estado

| Árbol | Rama | Estado |
|---|---|---|
| `GPOS-NG-numeracion` | `feature/modelo-ng` | En GitHub (`90deebb`). Ola 3 cerrada (`7e54716`). `master` unido (`10dec57`): ronda 1 visual + ADR en `docs/adr/`. Suite 1.433/0/8, Web 238, MAUI 344. Diseño de la ola 4 confirmado (`6cf8daf`) y su hoja de firma (`90deebb`) |
| `GPOS NG` | `master` | Commit local **sin subir**: `e8220d1` (ADR partidos en `docs/adr/` + ADR-68 a 72 + precisiones de ADR-17, 45 y 53). Falta la autorización del propietario para el push |
| `GPOS-NG-mejoras` | `feature/mejoras-demo-ronda2` | Ronda 2 visual sin push; espera revisión del propietario |
| `Backup Tool` | `fp01-clave-7zip` | En GitHub; carpeta `deploy/` sin seguimiento (del propietario) |

Árboles temporales de agentes: limpiados (2026-10-06). La PC B **no está lista**: todo se hace en la PC A.

## Agente nuevo
`especialista-contable` (NIIF/NIIF PYMES, contabilidad gubernamental RD, auditoría NIA/NOBACI/COSO). Usarlo ANTES del diseño de lo que genere o afecte registros contables. En la ola 4 conviene que revise: retenciones, CxP, notas de suplidor, costo de inventario, 606, conciliaciones bancarias y la pista de auditoría (y las notas de crédito y saldos a favor de ADR-70 ya construidas).

## Ola 4: en espera de la firma del propietario
- Documentos: `docs/pos/2026-10-06-reglas-ola4-compras-cxp-bancos.md`, `docs/arquitectura/2026-10-06-ola4-blueprint.md`, `docs/datos/2026-10-06-ola4-modelo-datos.md`, **hoja** `docs/decisiones/2026-10-06-hoja-firma-ola4.md`.
- Alcance D-3: 11,5 sp (centro firmado 3,0); el corte del 2026-12-02 no se mueve (inferido).
- Para abrir la construcción bastan PO-01, PO-05, PO-09, PO-11 y el bloque técnico (D-5, DQ-1 a DQ-4, DQ-6, DQ-7, TX-1, TX-2).
- Tres preguntas de hecho al propietario: PO-07 (¿BP2 tenía conciliación bancaria?), PO-15 (¿pagos al exterior/B17?), ¿BP2 tenía devolución a suplidor?
- Construcción: T-41 a T-62; empezar por T-50 y T-41; la compra emite como última sentencia; un solo agente de código en el árbol; carga T-57 con la máquina sola.

## Pendiente de respuesta del propietario
1. Firma de la hoja de la ola 4 (y las tres preguntas).
2. ¿Subir `master` (`e8220d1`) a GitHub?
3. ¿Preparar el segundo informe al contador con C-22 a C-36 (retenciones, B11/B13/B17, 606, cheques, exterior)? Se recomienda que estén respondidas antes de la primera implantación.
4. Revisión manual en la empresa DEMO tras unir `master`: Tablero (consulta del período = tarjeta Ventas; texto nuevo de la aclaración), Facturación Ágil plegada (apertura tras Z, pago con nota de crédito, avisos RNC/NCF), Recibos («Crear Recibo» + saldo a favor), modo oscuro, Enter en Clientes y Suplidores.

## Otros pendientes (sin bloqueo)
- Preparar las precisiones de ADR-58 (licencia por empresa por usuarios) y ADR-45 (serie por caja, entrega 2).
- Actualizar `CLAUDE.md` en `master` y en la rama: orden de bloqueos del modelo nuevo y ola 3 cerrada (el documentador no lo tocó).
- Backlog de la ola 3: H-QA3-25, O-QA3-26, O-QA3-27; huecos de API del frontend; revisión de seguridad de ADR-68 antes del corte.
- Respuesta del contador al primer informe (enviado el 2026-10-06; grupos 1 y 2 antes del 2026-10-28).
- Arrancar la PC B con `paquete-pc-b\instrucciones-pc-b.md` cuando el propietario lo decida.
