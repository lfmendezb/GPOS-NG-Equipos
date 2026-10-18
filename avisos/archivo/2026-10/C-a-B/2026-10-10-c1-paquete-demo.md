```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/paquete-demo (f22035b), PR #12 hacia feature/modelo-ng
Estado: Abierto
```

# C-1: paquete del DEMO desde `demo/2026-10-10` (DM-05)

Entregado por el devops de C. **PR #12:** https://github.com/lfmendezb/GPOS-NG/pull/12. C no une.

## Paquete (fuera del repositorio, en el equipo C)
- `C:\Users\lfmen\source\repos\paquetes-demo\GPOS-Demo-2026-10-10.7z`, con su `.sha256` al lado.
- **Tamaño:** 164,6 MB; extraído ocupa 766 MB en 2.168 archivos. Comprobado con `7z t`, sin errores.
- **SHA-256:** `12810A008B1D7DFC84C183F10D8534E34F351D43E4C89EACA0F1D80EC85E75BA`
- **Código:** `42e13b6` (`demo/2026-10-10`) más los scripts (`99d2200`).
  - API, Web, GPOS.Migracion y MAUI para Windows, en Release, autocontenidos win-x64, con .NET 10.0.12.
  - **29 migraciones**, hasta `20261010035415_Ola4BusquedaSinTildes`: son **21 más** que el paquete del 2026-10-07.
  - **La ronda 2 va incluida**, así que DM-06 queda resuelto.
- **Cómo pasarlo al equipo A:** el propietario lo copia (vía OneDrive u otra), porque C no tiene acceso al equipo A.

## En el repositorio (`instalador/Demo/`)
| Script | Qué hace |
|---|---|
| `Instalar-Demo.ps1` | Instalación nueva: genera la clave JWT aleatoria (DPAPI del usuario); ejecuta `crear --respaldo-inicial` (DM-07); hace el primer arranque de la API con las claves iniciales tecleadas, sin guardarlas; pone AUTO_CLOSE OFF |
| `Iniciar-Demo.ps1` | No arranca si quedan migraciones pendientes; **advierte si la base fue RESTAURADA** (DM-02); arranca la API (5071), la Web (5054) y MAUI |
| `Detener-Demo.ps1` | Detiene solo los procesos de esa carpeta |
| `Actualizar-Demo.ps1` | Respaldo `COPY_ONLY` con `CHECKSUM` y `VERIFYONLY`; huella de antes y después; `actualizar` y `verificar` |
| `Revertir-Actualizacion.ps1` | Explica DM-01; restaura solo con `-RestaurarBases` y confirmación escrita, y avisa que la base no emitirá hasta H-11 |
| `Desinstalar-Demo.ps1` | Hace un respaldo final y elimina las bases con confirmación por nombre |

- **Funciones comunes:** el SQL va por `System.Data.SqlClient`, sin sqlcmd (DM-08), e incluye la mitigación temporal de DM-04.
- **`Publicar-PaqueteDemo.ps1`:** arma el paquete de forma reproducible y rechaza secretos en `appsettings`.
- **Guía:** `docs/operaciones/2026-10-10-guia-actualizacion-demo.md`.

## Pasos de instalación en el equipo A (para el propietario)
1. Comprobar el SHA-256 con `Get-FileHash` y extraer el paquete.
2. **Copiar a `datos-demo\` las 8 plantillas `.xlsx` del paquete del 2026-10-07.**
3. En PowerShell normal (no como administrador), ejecutar `Unblock-File` y luego `.\Instalar-Demo.ps1` (en una instancia predeterminada, `-Instancia '.'`).
4. Ejecutar `.\Iniciar-Demo.ps1`, entrar como ADMIN, cambiar la clave e importar las plantillas del 01 al 08.
5. Respaldar aparte `config\` y `datos\`.

**Se usa siempre el mismo usuario de Windows**, porque los secretos quedan cifrados con DPAPI de ese usuario.

## Limitaciones y riesgos
- **P-01 (Media): los scripts no se han ejecutado de verdad.** Por regla, C no instala nada. Solo los revisó el analizador de PowerShell 7.6 y 5.1, sin errores, y se probaron las funciones que no tocan SQL. **La primera prueba real es la instalación del propietario.**
- **Las plantillas `datos-demo` no van en el paquete:** solo están en los .7z de OneDrive, que en este equipo son archivos solo en la nube con OneDrive detenido. Los scripts originales tampoco se pudieron leer y se reconstruyeron a partir de la guía y del código.
- **El agente de impresión no va incluido:** cambió con K1 y su MSI no se armó.
- **DM-01 sigue vigente:** la reversión recomendada para el DEMO es reinstalar.
- **MAUI va sin firma Authenticode:** SmartScreen puede advertir.

**Sin secretos** en el paquete ni en el commit: búsquedas por nombre de archivo y por claves en `appsettings`, sin resultados. No se ejecutó nada del paquete.

**Pendiente de C:**
- C-4: implementación y prueba en curso (`c/dm04-autoclose`).
- C-2: espera el PR de H-11.
