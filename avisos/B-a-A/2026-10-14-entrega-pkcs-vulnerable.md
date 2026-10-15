```
Para: A            De: B            Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG b/seguridad-pkcs (bbe9349, sale de feature/modelo-ng e59d8de)
Estado: Abierto
```

# System.Security.Cryptography.Pkcs vulnerable, fijado en versiones parcheadas (rama lista, sin unir)

Esto corrige la advertencia NU1903/NU1902 que apareció al compilar la integración de los PR de A. No la causó ninguna unión. Viene de un paquete transitivo.

## Avisos de seguridad
- **GHSA-846f-f764-76mx** (CVE-2026-84008, gravedad alta) y **GHSA-2fmv-rv2c-59x7** (CVE-2026-70162, gravedad moderada).
- Las dos son de denegación de servicio en .NET y se publicaron el 2026-10-13.
- Versiones afectadas: 10.0.0 a 10.0.12 y 9.0.0 a 9.0.20.
- Versiones parcheadas: **10.0.13** y **9.0.21**.

## Qué se hizo
| Proyecto | Antes | De dónde viene | Después |
|---|---|---|---|
| `src/GPOS.Core` | 10.0.0 | MailKit 4.18.1 → MimeKit 4.18.1, y EF Core SqlServer 10.0.12 → Microsoft.Data.SqlClient 6.1.6 | **10.0.13**, con un `PackageReference` explícito |
| `src/GPOS.Reportes` (llega también a `GPOS.Reportes.Api` y `GPOS.Reportes.Tests`) | 9.0.18 | Microsoft.Data.SqlClient 7.1.0 | **9.0.21**, con un `PackageReference` explícito |

- Se fijó el paquete transitivo en lugar de subir un paquete directo:
  - En GPOS.Core, el paquete llega por dos rutas, así que subir MailKit no corregía la ruta de SqlClient.
  - En los dos casos, el parche de la misma línea es el cambio más pequeño.
- **Ningún paquete directo cambia de versión.**
- **El caso de GPOS.Reportes no estaba en el encargo original.** Se encontró al revisar toda la solución.

## Cómo se verificó (sobre bbe9349)
- `dotnet list GPOS-NG.slnx package --vulnerable --include-transitive`: **0 vulnerables en los 16 proyectos**.
- La restauración se hizo con `--ignore-failed-sources`, porque en LFMB falta `C:\Users\lfmen\source\NugetLocalFeed`.
- `dotnet build GPOS-NG.slnx`: **0 errores**. Las 52 advertencias ya existían (CA1416, EF1003 y otras) y ya no aparece ninguna NU190x.
- Pruebas con `--filter "Transicion!=Ola5&Transicion!=Defecto"`, una suite a la vez:
  - `GPOS.Web.Tests`: **636/636**.
  - `GPOS.UI.MAUI.Tests`: **556/556**.
  - `GPOS.Tests` en `.\SQLEXPRESS`: **2471 superadas, 19 omitidas y 1 con error, de 2491** (7 min 47 s).
    - La que falló es `AplicacionEmisionPlanTests.La_lectura_unificada_de_la_emision_busca_en_UQ_Aplicacion_sin_recorrer_la_tabla_vacia`, con «Database 'GPOS_TEST_…' is in transition».
    - Es una falla de carga transitoria: repetida sola dos veces, pasó las dos.
  - `GPOS.Reportes.Tests` (sin filtro, porque se tocó GPOS.Reportes): **432/432**.

## Riesgos y pendientes
- **El runtime compartido también hay que parchearlo.** Esta rama corrige los paquetes NuGet, pero las CVE son de .NET. En los equipos que ejecutan la API y los servicios hay que instalar el runtime de .NET 10 y ASP.NET Core que salió con el parche (10.0.13 o posterior). Esto no se verificó; lo decide el propietario.
- Al fijar estas versiones, la actualización ya no sigue sola a MimeKit ni a SqlClient. Cuando esos paquetes pidan una versión de Pkcs mayor, NuGet avisará con NU1605 (bajada de versión) y habrá que subir o quitar esta línea.
- No se ejecutó la suite completa sin filtro, ni GPOS.UI.MAUI para Android: en LFMB faltan los workloads.
- **No está unida.** La une el coordinador en `feature/modelo-ng`.
