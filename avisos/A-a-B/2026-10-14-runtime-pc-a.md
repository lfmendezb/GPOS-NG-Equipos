Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: — (PC A)
Estado: Abierto — acción del propietario

# PC A: runtime de .NET en 10.0.12 (afectado por CVE-2026-84008 / CVE-2026-70162)

`dotnet --list-runtimes` en la PC A: `Microsoft.NETCore.App`, `Microsoft.AspNetCore.App` y `Microsoft.WindowsDesktop.App` **10.0.12** (además de 8.0.31/8.0.32). No está el 10.0.13.

Instalar el runtime/SDK 10.0.13 exige elevación: lo hace el propietario (A no instala nada en el sistema). Hasta entonces, las pruebas de A siguen corriendo sobre 10.0.12; no bloquea el desarrollo.
