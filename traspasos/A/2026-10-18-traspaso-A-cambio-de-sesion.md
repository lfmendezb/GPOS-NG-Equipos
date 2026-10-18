# Nota de traspaso del equipo A (cambio de sesión, 2026-10-18)

Pegue en la sesión nueva de la PC A: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-18-traspaso-A-cambio-de-sesion.md` y retoma desde ahí».

Sustituye al traspaso del 2026-10-17. Al cerrar no quedaban agentes ni pruebas en marcha. El hook del modelo por agente estuvo activo en toda la sesión.

## 1. Estado de los PR de A (todos rebasados sobre `feature/modelo-ng` @ `17ecc9b9`)
| PR | Rama (árbol) | Punta | Base en GitHub | Nota |
|---|---|---|---|---|
| #52 | `a/dl22-rotacion` (`GPOS-NG-dl22`) | `1e56c5ec` | `feature/modelo-ng` | 30/1/0. La que falla es PA28, que se cierra con el #48 |
| #55 | `a/dl22-bmas` (`GPOS-NG-dl22b`) | `2f05721b` | `a/dl22-rotacion` | 51617 confirmado |
| #45 | `a/lic-activar` (`GPOS-NG-activar`) | `948bdda9` | `feature/modelo-ng` (reapuntado) | 616/0/1 |
| #48 | `a/rg14-contencion-indice` (`GPOS-NG-cont`) | `5c7e5acd` | `feature/modelo-ng` | Migración regenerada `20261018042207_Rg14ContencionMotivoAnulacion`, con su guion acumulado |
| #60 | `a/d04-pa28-contencion` (`GPOS-NG-d04`) | `847f6e13` | `a/rg14-contencion-indice` | Solo cambia un comentario. B decide si lo une o lo cierra. Con el #48: 244/0/2 y PA28 pasa en SQL 2019 |
| #63 | `a/sl-sello-padron` (`GPOS-NG-sl`) | `e2f39aea` | `feature/modelo-ng` | 701/0/1 |
| #67 | `a/rn-cambio-rnc` (`GPOS-NG-rn`) | `e0a99019` | `a/sl-sello-padron` | `ErrorOtroCambio` pasa a **51618**, porque el 51616 es del #48. 371/0/0 |
| #68 | `a/sl-resellar-candado` (`GPOS-NG-slf`) | `34cf88fd` | `a/rn-cambio-rnc` | 792/0/1 |
| **#73** | `a/rs-anillo-sellos` (`GPOS-NG-rs`) | `e55a7478` | `a/sl-resellar-candado` | RS-01 a RS-03, más RSV-01, 04, 05, 07 y 09. Seguridad: Aprobado con observaciones. 810/0/1. EventId **4722** |
| #58 | `a/seg-fa-06-via-b-perfil` (`GPOS-NG-fa06`) | `045b136c` | — | **Sin tocar:** se rebasa cuando se una el #57 de C |

**Orden de unión (lo hace B):** #52 → #55 → #51 (C) → #45 → #48 → #60 → #63 → #67 → #68 → #73 → #57 (C) → #58.

## 2. Marcas y números reservados
- **Migraciones:** la última marca es `20261018042207` (#48). Toda migración nueva o regenerada lleva una marca posterior.
- **Errores SQL:** 51616 (#48), 51617 (#55), 51618 (#67). El siguiente libre es el **51619**.
- **EventId:** 4720 (`AnilloReintento`), 4721 (`EntornoLecturaFallida`), 4722 (`LicenciaFuenteIlegible`, #73). El siguiente libre es el **4723**.

## 3. Emisor `GSF.EmisorLicencias`
- **EM-01 hecha:** `github.com/lfmendezb/GSF.EmisorLicencias`, privado, con `main` en `8ce6cd7`. La historia se revisó antes de subirla y no tiene secretos.
- El submódulo apunta a `17ecc9b9` y usa `FormatoLicencia.Autorizacion` (EV-01). 95/95 en Debug y en Release.
- Toda subida del submódulo va en un commit propio, con la huella de `LlavesGsf.json` (ver el README).

## 4. Pendiente (nada de esto lo puede hacer A sola)
- **Esperar a B:** las uniones, la suite oficial en SQL 2025, el registro de 51618 y 4722 en ADR-82 y decidir qué hacer con el #60.
- **Esperar a C:** el #57, rebasado sobre el #68. Después A rebasa el #58. C debe heredar el 51618 en `c/adr81-tn-sobre-rn` y `c/pantallas-sl-rn`.
- **Para el arquitecto-maestro, si B lo encarga (posibles ADR para firma):**
  - RSV-03: reprotección conjunta del padrón y los sellos. Sin ella, en una instalación sellada `--cambiar-recuperacion` queda siempre bloqueado.
  - RSV-02: exigir la API detenida durante el mantenimiento del anillo.
  - RSV-10 y RSV-13: límite de antigüedad de la instantánea de la licencia.
- **Diferidas del #73 (Bajas):** RSV-06, RSV-08, RSV-11, RSV-12 y el caso 1 de RSV-07. Detalle en `traspasos/A/revision-seguridad-rs01-rs03-2026-10-18.md`.
- **Después del orden de unión:** el acta de resellado firmada por GSF, según `traspasos/C/blueprint-acta-resellado-gsf-2026-10-17.md` (v1.1, AG-01 a AG-07). Son unos 1,6 dp y va antes de la primera licencia de pago.
- **Regla operativa vigente:** no cambiar la recuperación del anillo en una instalación sellada, ni con la API en marcha.

## 5. Notas de la PC A
- **PA28** necesita el #48 en SQL 2019. Sobre la punta limpia falla con 5061 o 12834.
- **Para regenerar migraciones:** el manifiesto `dotnet-tools.json` está marcado como descargado de internet y no se desbloqueó. Se usa `dotnet ~/.nuget/packages/dotnet-ef/10.0.12/tools/net8.0/any/dotnet-ef.dll`, con `--project src/GPOS.Core --startup-project src/GPOS.Core --context EmpresaNgDbContext`.
- **Árbol `GPOS-NG-numeracion`:** queda en `feature/modelo-ng` @ `5b47e019`. Se usó como línea base.
- **Ediciones locales sin subir** en `GPOS-NG-Equipos/agentes/especialista-pos.md` y `orquestador.md`: solo son comillas en la descripción y ya estaban de antes.

## 6. Firmas
A no tiene firmas pendientes.
