```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5
Estado: Abierto
```

# Datos sensibles en las vistas de reportes: firmado; B corrige antes de la unión de la ola 5

Revisión del auditor de A: `traspasos/A/revision-rpt-rptc-sensibles-2026-10-09.md`. El propietario firmó el 2026-10-09:
1. **Privilegios nuevos:** «Ver datos personales» y «Ver cuadre de caja». Por omisión: SUPERVISOR y CONTADOR sí; CAJERO no.
2. **`rptc` cubre costos, bitácora y datos sensibles** (precisión de ADR-109, cláusula 4; la registra A).
3. **El pasaporte completo nunca se muestra en todo el sistema**, salvo el flujo de Duty Free (generaliza DO-02 de ADR-115); en `rptc` solo los últimos 4.
4. **Solo diseña reportes en SQL quien tiene acceso a todas las sucursales.**
5. **Cédula y pasaporte en claro: no se acepta como riesgo.** A diseña el cifrado de esas columnas (arquitecto-datos y auditor) antes de la primera instalación fuera de desarrollo, sin frenar la entrega 1; te aviso el diseño.

**Para B en `b/ola5`, antes de que A una la migración de la ola 5:**
- **RS-01:** en las seis columnas de las seis vistas `rpt` (`VentaDocumento` ×2, `Cotizacion`, `ConsultaFactura`, `CatCliente`, `CatSuplidor`), RNC de 9 dígitos íntegro y el resto enmascarado (`*******` + últimos 4), columna con sufijo `Enmascarada`; valor completo en superconjuntos `rptc` con «Ver datos personales» (pasaporte nunca completo).
- **RS-02:** `EfectivoEsperado`, `EfectivoDeclarado`, `Contado` y `Diferencia` a `rptc.CierreCaja`/`rptc.CierreCajaConteo` con «Ver cuadre de caja»; en `rpt`, `Esperado` solo en los Z no anulados (conteo ciego de ADR-17); el nombre del cajero sigue en `rpt`.
- **RS-03:** mapa de privilegio por vista en el contrato (hoy todo `rptc` se abre con «Ver costos»).
- **RS-07:** completar la lista del LEEME con las tres vistas omitidas.
- RS-04 (`rpt.Formato606/607` con RNC y cédula completos) queda con los fiscales aplazados; RS-06 (el diseñador ve todas las sucursales) queda cubierto por el punto 4.
Recalcula la huella del contrato y avísame el commit.
