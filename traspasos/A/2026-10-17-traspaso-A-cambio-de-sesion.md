# Nota de traspaso del equipo A (cambio de sesión, 2026-10-17 ~23:59)

Pegue en la sesión nueva de la PC A: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-17-traspaso-A-cambio-de-sesion.md` y retoma desde ahí».

**Por qué se cambia de sesión:** el hook que impone el modelo por agente (instalado el 2026-10-17, respaldo `settings.json.respaldo-20261017-164515`) solo entra en vigor al reiniciar. Al abrir, comprobar que el hook está activo; si no lo está, avisar al propietario antes de lanzar agentes.

## 1. Lo que cambió esta noche
- **Unión adelantada por UN-01 (a):** `feature/modelo-ng` = **`5b47e019`** (`53e22eca` une `b/prep-27oct` `d67f5a33` + `5b47e019` une el #66). Suite oficial del mismo árbol: 3231/1/28 (C-10 intermitente). Aviso `avisos/B-a-A/2026-10-17-union-prep27-hecha.md`.
- **Última marca de migración de la punta:** `Uf05ForceSeek 20261015142020`. Toda migración nueva o regenerada lleva marca posterior.
- **Hoja de B firmada** (`master` `fe42b415`): SE-01/SE-02, CB-01, RS-01, OR-01, BM-01, EM-01. Detalle en `traspasos/B/hoja-firma-b-2026-10-17.md`.
- **Suite oficial de #63 + #67 en SQL 2025 (B):** 3217/4/24, las 4 pasan solas → aptos (aviso `B-a-A/2026-10-17-suite-oficial-63-67`).

## 2. Cadena de rebases firmada (todo sobre `5b47e019`)
Una rama a la vez por árbol; como máximo 2 actividades pesadas en la PC A. Tras compilar, borrar `testhost.exe`. En SQL 2019 (PC A) siguen las 5 fallas del 12834 hasta el #48.

| Paso | PR | Rama (árbol) | Punta actual | Qué hacer |
|---|---|---|---|---|
| 1 | #52 + #55 | `a/dl22-rotacion` (`GPOS-NG-dl22`) + `a/dl22-bmas` (`GPOS-NG-dl22b`) | `cd480ddd` / `27ca3e2c` | Rebasar; confirmar la renumeración 51616 → 51617 |
| 2 | #51 | (C) | — | C lo rebasa sobre el #55 |
| 3 | #45 | `a/lic-activar` (`GPOS-NG-activar`) | `330d5c71` | Activación de `UseLicencia`. **Su base en GitHub sigue siendo `a/reimpresion-post` (#46 ya unido): reapuntar a `feature/modelo-ng`** |
| 4 | #48 + #60 | `a/rg14-contencion-indice` (`GPOS-NG-cont`) + `a/d04-pa28-contencion` (`GPOS-NG-d04`) | `808cbe0a` / `b4a87f09` | Regenerar la migración del #48 con marca > `20261015142020`; el #60 va con él (PA28 en SQL 2019 si C no puede) |
| 5 | #63 | `a/sl-sello-padron` (`GPOS-NG-sl`) | `afc8bdb1` | Rebasar |
| 6 | #67 | `a/rn-cambio-rnc` (`GPOS-NG-rn`) | `da474174` | Tras unir el #63, reapuntar a `feature/modelo-ng` |
| 7 | #68 | `a/sl-resellar-candado` (`GPOS-NG-slf`) | `73418632` | Va entre #67 y #57 (OR-01). El #69 de C está apilado encima |
| 8 | #57 | (C) | — | C lo rebasa sobre la punta que deje el #68 |
| 9 | #58 | `a/seg-fa-06-via-b-perfil` (`GPOS-NG-fa06`) | `045b136c` | Hoy apilado sobre `c/adr81-fase-a`; rebasar tras el #57 |
| hueco | #59 | `a/d03-anillo-canalizacion` (`GPOS-NG-d03`) | `54749b4f` | Cuando haya hueco |
| hueco | #65 | `a/ev01-miembros-autorizacion` (`GPOS-NG-ev01`) | `7776c641` | Cuando haya hueco; **al unirse**, ver §3 |

B une; A rebasa, corre pruebas dirigidas y avisa (Entrega) por cada PR.

## 3. Emisor `GSF.EmisorLicencias` (`C:\Users\lfmen\source\repos\GSF.EmisorLicencias`, solo local, `06d153e`)
- **EM-01 firmada:** repositorio privado en GitHub, cuenta del propietario, sin secretos (llaves en TPM/YubiKeys). Lo crea el propietario, **o A solo con su autorización expresa en chat**. Antes de subir: revisar que no haya secretos en la historia.
- **Tras unir el #65:** mover el submódulo a ese commit; quitar `ObligatoriosAutorizacion` y `MiembrosAutorizacion` de `LlavesPublicadas.cs` y usar `FormatoLicencia.Autorizacion`; ajustar `ReglasEmisorTests.cs:294`.

## 4. RS-01 a RS-03 (firmada RS-01 (a))
- PR aparte de A **detrás del #68**, unos 0,5 dp, antes del primer mantenimiento real del anillo. Origen: revisión de seguridad del acta (C) y aviso `A-a-B/2026-10-17-pr68-ar01-ar06`.
- Núcleo: `RevocarHeredadasAsync` y `CambiarRecuperacionAsync` no miran el padrón ni los sellos.
- **Regla operativa vigente:** no revocar llaves ni cambiar la recuperación en una instalación con sellos hasta que esté unido.

## 5. Después del orden de unión
- **Acta de resellado firmada por GSF:** construir según `traspasos/C/blueprint-acta-resellado-gsf-2026-10-17.md` (v1.1) con AG-01 a AG-07 firmadas; ~1,6 dp + 0,25 dp de revisión; antes de la primera licencia de pago. Confirmar los nombres de clases del emisor (C los infirió).

## 6. Sin bloqueo (opcional)
- **Suite oficial de T-n de C** (`c/adr81-tn-sobre-rn` @ `d6a1edba`, TN-01, 7(b), 7(d)): «para B o A». En la PC A saldrán las 5 del 12834; B la puede correr en SQL 2025.

## 7. Firmas
A no tiene firmas pendientes.
