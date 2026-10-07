---
name: politica-actualizacion-paquetes
description: Los paquetes NuGet solo se actualizan si hay una vulnerabilidad conocida o si la nueva versión es estable; nunca solo por ser la última
metadata:
  node_type: memory
  type: feedback
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-03T06:58:12.219Z
---

Regla del propietario (2026-10-03): **solo se cambia la versión de un paquete si existe una vulnerabilidad conocida en él o si la nueva versión es estable.** Que exista una versión más nueva no basta.

**Why:** apareció sin confirmar una subida de `Microsoft.Data.SqlClient` a 7.1.1 en `GPOS.Core`, que rompió la restauración de `GPOS.Tests` (NU1605), y se preguntó por qué `CommunityToolkit.Maui` estaba en 13 si ya había 15. La 13 se eligió porque `$(MauiVersion)` del manifiesto de la carga de trabajo es 10.0.20; la 15.0.1 exige MAUI ≥ 10.0.90. Se puede subir con `<MauiVersion>` en el proyecto, sin tocar Visual Studio.

**How to apply:**
- Antes de proponer una actualización, revise `dotnet list package --vulnerable --include-transitive` y que la versión destino no sea preliminar.
- Suba la misma versión en todos los proyectos a la vez, como un cambio aparte, con la suite en verde.
- No meta subidas de paquetes en una rama que está en revisión.
- La subida de MAUI y del toolkit queda para el inicio de la fase de MAUI. Relacionado: [[cierre-numeracion-nuevo-equipo]].
