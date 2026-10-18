```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/hoja-firma-diseno-corporativa-2026-10-15.md (+ revision-seguridad-diseno-corporativa-2026-10-15.md)
Estado: Abierto — D-01 a D-28 por firmar; el auditor confirma la §4
```

# Vertical Corporativa: hoja única de firma del diseño (D-01 a D-28)

## Qué trae la hoja
- **Una sola lista:** fusiona FD-01 a FD-15, SW-01 a SW-18 y UQ-1 a UQ-9 en D-01 a D-28. La procedencia está en la §3.0.
- **Seguridad:**
  - SW-09 v2 en D-01 y SW-02 v2 en D-02, con las remediaciones del auditor (§6.1);
  - la matriz para su confirmación, en la §4.
- **Puesta en marcha:** las condiciones PM-01 a PM-10, en la §5. Las principales:
  - el acceso multiempresa v1, o una sola empresa habilitada;
  - ADR-67 implementado;
  - H-04 decidida;
  - la respuesta del contador;
  - la revisión legal de la Ley 172-13;
  - un simulacro de restauración.
- **Estimación:** 9,8 sp, o de 10,3 a 10,6 con S-1. La entrega 3 queda entre 47,6 y 50,1 sp. El tramo va después de 3c.

## Para B
- **La §7 (SEG-CORP-08) está verificada en `ce33b2a8`:**
  - `AutorizacionesSupervisor.cs:109` devuelve `PorCredencial = true` aunque el autorizante sea el mismo usuario de la sesión;
  - en `:137`, la bitácora lo anota como «(supervisor presente)».

  La remediación cuesta unas 0,05 sp y es una precisión de ADR-68 (ver el hallazgo `2026-10-15-hallazgo-autorizacion-otra-persona`).
- **DB-1 a DB-8:** DB-8 es ADR-67, que no está implementado.
- **ADR-67, punto 9:** la entrega de llaves al nodo necesita una precisión firmada antes de T11.
- **Al firmar, registrar en `master`:** las precisiones de ADR-45, 67, 68, 85, 87, 88 y 112.
