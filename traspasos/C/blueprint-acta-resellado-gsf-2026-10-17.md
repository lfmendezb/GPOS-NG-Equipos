# [Blueprint Técnico] Acta de `sellos --resellar` firmada por GSF y reporte del resellado en L-06/L-07

- **Fecha:** 2026-10-17 · **Autor:** arquitecto-software, equipo C · **Encargo:** tarea 4 de `avisos/A-a-B/2026-10-17-encargo-para-c.md`.
- **Versión: 1.1** (2026-10-17). Incorpora la revisión del auditor-seguridad `traspasos/C/revision-seguridad-acta-resellado-2026-10-17.md` (en adelante **`[SEG-AR]`**, «Aprobado con observaciones», AR-01 a AR-12). Ver «Cambios de la v1.1». La v1.0 se escribió contra `a/sl-resellar-candado` @ `bc67ec9d`; la v1.1 usa **`130306c0`**.
- **Estado del documento:** diseño, solo lectura del código. Las decisiones nuevas de la sección 12 (**AG-01 a AG-07**) fueron **firmadas por el propietario el 2026-10-17, todas según la recomendación**, en la sesión de C: «Firmo: AG-01 a AG-07 según la recomendación». Nada de lo que aquí se describe existe en el código, salvo lo indicado como ya construido en `130306c0`. Construcción: A. Según `[SEG-AR]` §9, no hace falta otra revisión completa del diseño: los cuatro puntos Medios se verifican en la revisión del código.
- **Firma de origen** (aviso `avisos/A-a-B/2026-10-17-firma-slf01-acta-gsf.md`, precisiones de ADR-83, punto 7):
  1. **SLF-01:** `--resellar` se niega si `Licencia.SelloInicial` verifica, o si falta y hay alguna licencia aceptada, y reescribe `SelloInicial` con origen `RESELLAR`.
  2. **Antes de la primera licencia de pago:** el acta del resellado es una **autorización firmada por GSF y ligada a la instalación**, y el resellado **se reporta a GSF en L-06/L-07**.
- **Fuentes leídas:**
  - `[SEG-SLF]` `traspasos/A/revision-seguridad-sl-f1-f2-2026-10-17.md`; `[VAL-SLF]` `traspasos/A/validacion-sl-f1-f2-2026-10-17.md` (C-2, C-3, R-1, R-3); `[VAL-SL]` `traspasos/A/validacion-sl-sello-padron-2026-10-17.md`.
  - `[BP-L2]` `traspasos/A/blueprint-licencia-lote2-2026-10-14.md` v2.9: §2.3 y §2.5, §5, §8, §9.1 y §9.2, §10.3 a §10.6.
  - `[LIC]` `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` v3.2 (8.4; 7.3 con Q-08). `[PSF]` `docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md` 4A.6.
  - ADR-58 a 66, ADR-81 (punto 7, (b+)) y ADR-83 (precisiones del 2026-10-17), en `origin/master`.
  - `[EV]` `traspasos/A/revision-seguridad-emisor-verificarcompacto-2026-10-17.md`. `[SEG-AR]`.
- **Código leído (solo lectura, `git show`):**
  - `origin/a/rn-cambio-rnc` @ `da474174`: `FormatoLicencia.cs`, `ContratosJws.cs`, `VerificadorJws.cs`, `AutorizacionRegresoNivel.cs`.
  - `origin/a/sl-resellar-candado` @ **`130306c0`**: ya trae SLF-01 (1) (`SellosService.InstalacionNoResellableAsync`), `--acta <ref>` de texto (`SellosService.ExigirActa`, de 6 a 60 caracteres), `SelloInicial` con `OrigenResellar = "RESELLAR"`, versión del padrón en segundos Unix (`cambio.Crear(…ToUnixTimeSeconds())`) y `ResellarAsync` `internal` [V, commit `002e24d9`]. Además `ComandoSellos.cs`, `LicenciaDtos.cs`, `EstadoLicenciaService.cs`, `LicenciaEndpoints.cs` y `AnilloDataProtection.cs`; `ReproteccionSecretos.cs` lo cita `[SEG-AR]` AR-06.
- **`GSF.EmisorLicencias` no está accesible en este equipo** (según `[EV]`, vive en otro equipo, local y sin remoto). Diseño contra `GPOS.Contracts/Licencia` (que el emisor enlaza) y contra `[BP-L2]` §9.2; los nombres de clases del emisor son **[I]**.
- **Etiquetas:** [V] verificado en el código; [I] inferido. dp = días-persona. Actores (de `[SEG-AR]` §1): **A1** `sysadmin` de SQL sin anillo ni disco; **A2** administrador de Windows con el anillo (residual R-S2 / CP-4); **A3** el propio cliente que pide el acta; **A4** un tercero en el canal de correo.

---

## Cambios de la v1.1

| AR | Sev. | Qué cambia en el diseño | Secciones |
|---|---|---|---|
| **AR-01** | Media | Se declara que **SLF-01 se elude con un `UPDATE`** que estropee `SelloInicial`: la rama «existe y no verifica» permite resellar sin mirar las licencias [V `InstalacionNoResellableAsync`]. La barrera real frente a A2 y A3 es la firma de GSF y su política de emisión. **Con esta pieza, ningún resellado se hace sin acta, en ninguna rama.** La solicitud informa el estado observado de `SelloInicial` (`Verifica`, `Ausente` o `NoVerifica`) y si hay licencias aceptadas. La precisión opcional AR-01 (3) va a firma como AG-07 | 1, 6.2, 12 |
| **AR-02** | Media | **Solo la causa `AnilloIncompleto` levanta la condición «`SelloInicial` verifica» de SLF-01.** `PadronIlegible` **sale del catálogo**: con el anillo entero, el camino es restaurar el respaldo y legitimar. Se agrega `InstalacionNueva` (AR-12), que no levanta esa condición. La solicitud lleva un **diagnóstico** de los dos padrones (`Ausente`, `LlaveAusente`, `MacInvalido`, `Verifica`) y el acta lo **liga** en el miembro `estado`; la instalación lo recalcula y lo compara (`ACTA_NO_COINCIDE`). El emisor aplica un criterio por causa | 4, 5.1, 5.2, 6.1, 6.2, 6.4 |
| **AR-03** | Media | **`HuellaContenido`** en `ReselladoPendiente`, con MAC: SHA-256 canónico de los campos que cubre el sello, más perfiles y excepciones. Se recalcula en la transacción y no viaja a GSF. El emisor exige **confirmar cada SUPER** que no figure en un registro anterior (sin registro, todos). Procedimiento: **restablecer las contraseñas** de todo SUPER y ADMIN después de resellar (y la inscripción TOTP cuando exista ADR-81) | 4, 5.3, 6.1, 6.2, 6.4, 11 |
| **AR-04** | Media | **AG-05 (b) por omisión:** el acta no autoriza un exceso de cupo, salvo que **el último L-06 registrado ya reportara** un `PadronConsumoNoSuper` mayor o igual que el `noSuper` del acta. Las cuentas sobrantes se excluyen con `--excluir` en la solicitud. Las huellas se calculan **después de las exclusiones** | 5.2, 5.3, 6.2, 6.4, 12 |
| AR-05 | Baja | En la transacción: `ReselladoPendiente` y `SelloInicial` se leen con `UPDLOCK, HOLDLOCK` después de tomar el padrón; `--solicitud` también toma el padrón; se relee la licencia vigente; las huellas salen de **la misma lista** que se sella, leída una sola vez y ordenada en memoria con `StringComparer.Ordinal` (no con el `OrderBy` de EF, que usa la intercalación CI) | 6.2, 10.2 |
| AR-06 | Baja | `Licencia.SelloInicial`, `Licencia.ReselladoPendiente` y el padrón entran en `ReproteccionSecretosSistema.FilasConfiguracion`, con prueba. Asignado al núcleo del sello; puede ir ya en el PR de SL-F1/SL-F2. Alternativa operativa (devops): respaldar el anillo cada vez que se crea una llave | 11, 14 |
| AR-07 | Baja | Párrafo del uso único reescrito: las capas **impiden** la repetición por A1, por A4 y por error; **frente a A2 solo se detecta** en GSF. Regla nueva del emisor: `RESELLADO_REPETIDO`. En el acta: `sec` mayor que `secLicencia` y no mayor que la hora protegida + 48 h (INV-6) | 6.1, 6.2, 6.4 |
| AR-08 | Baja | La tabla del emisor ya no se presenta como detección de A2. Regla nueva: una `PadronVersion` (segundos Unix) posterior al último reporte, sin `aid` emitido, da `RESELLADO_NO_AUTORIZADO`. Un acta vencida sin reportar da un **aviso** al soporte, no un cierre silencioso. **L-07 `PorResellado` se aplaza** hasta que L confirme la derivación. Se mantiene el registro de eventos de Windows | 5.4, 6.4, 13.1, 14 |
| AR-09 | Baja | El piso sale de `PisoNivelFirma.Efectivo`; si no se puede calcular, se trata como Avanzado. Se corrige una afirmación de la v1.0: con la causa `AusenciaCustodios` puede no haber llave Avanzada disponible, y una instalación con piso Avanzado **no puede recibir un acta** (falla cerrada; pérdida de servicio declarada en R-AG6). Asignado a L y al documentador | 5.1, 6.1, 13.1 |
| AR-10 | Baja | El emisor arma el encabezado protegido **desde una constante por operación**; la confirmación desde los bytes muestra el `typ` decodificado. Vectores V-03b a V-03e. Asignado a I y a QA | 6.4, 10.1 |
| AR-11 | Baja | El emisor **no conserva** la lista ni el archivo `.gposresol` después de emitir (solo la huella y los totales en el registro). Se quita `huellaEntorno` de la solicitud. El canal y la retención van en AP-03 (documentador) | 5.2, 6.4, 11 |
| AR-12 | Baja | Flujo de la **instalación nueva** (anillo perdido del todo) descrito de punta a punta, con prueba dirigida | 6.5, 10.2 |

Estimación: de 1,45 dp a **≈ 1,6 dp (±30 %)**, más 0,25 dp de revisión del código (sección 14).

---

## 0. Resumen para el propietario

1. El acta es un **JWS compacto** (`typ: "gpos-acta-resellado+jws"`) firmado con la **misma llave de licencias** (`s1` hoy; `a1` o `b1` en Avanzado). No hacen falta llaves ni hardware nuevos: USD 0.
2. Va ligada a la instalación, a la licencia vigente, a un **número de un solo uso** que genera la instalación al pedirla, a la **lista exacta de cuentas** (por su huella), al **estado observado** del sello inicial y de los padrones, y a una vigencia de **24 h**.
3. Flujo: `sellos --resellar --solicitud` (no cambia nada) → GSF revisa la lista con el cliente, confirma cada SUPER y firma → `sellos --resellar --acta <archivo> --confirmar`. Después se restablecen las contraseñas de SUPER y ADMIN.
4. **La regla local SLF-01 se puede saltar con una escritura SQL** (AR-01). Lo que de verdad protege es que GSF firme solo en el caso legítimo. Por eso solo la causa «anillo incompleto», con el diagnóstico que la respalda, levanta SLF-01 (AG-01 (a′)), y el acta **no devuelve cupo** que GSF no haya visto antes (AG-05 (b)).
5. La siguiente solicitud de licencia (L-06) le dice a GSF qué acta se usó y la versión del padrón; el emisor se detiene ante un resellado que no autorizó. Frente a un administrador con el anillo que programe por su cuenta, esto **detecta, no impide** (es el residual ya aceptado R-S2).
6. Estimación: **≈ 1,6 dp (±30 %)** más 0,25 dp de revisión. Siete preguntas para firma (AG-01 a AG-07).

---

## 1. Contexto y alcance

**Problema** (`[SEG-SLF]` SLF-01). `sellos --resellar` es la única herramienta que crea un padrón desde las filas (ADR-83, punto 7). Quien tenga el anillo y acceso de Windows puede destruir los padrones y resellar: así legitima cuentas creadas por SQL o recupera cupo después de una reducción (SEG-L2-07).

**Lo que ya hace el código (`130306c0`) y su límite (AR-01):**
- `InstalacionNoResellableAsync` niega si `SelloInicial` **verifica**, o si **falta** y hay licencias aceptadas [V].
- Si la fila **existe y no verifica**, permite resellar sin mirar las licencias [V]. Basta un `UPDATE` que estropee un byte de la fila para saltar SLF-01. No se puede cerrar sin romper el caso legítimo de la instalación nueva, cuya `SelloInicial` vieja tampoco verifica.
- Conclusión: SLF-01 solo frena a quien no sabe reescribir una fila. **Frente a A2 y A3, la barrera real es la firma de GSF y su política de emisión** (secciones 6.4 y 12).

**Regla de esta pieza:** desde la versión que la incluya, **ningún resellado se hace sin un acta válida de GSF, en ninguna rama**. Vale también para «existe y no verifica» y para Debug, donde lo único distinto es que se admite `gsf-lic-dev`.

**Alcance:** formato del acta y de la solicitud; regla 11 del emisor; verificación en el verbo y orden respecto de SL-F2 y SLF-01; reporte en L-06 (L-07 aplazado); riesgos, vectores, estimación y reparto.

**Fuera de alcance:** lo que A ya construyó en `130306c0`; la vía (b+) de ADR-81 (queda preparada, 6.3); la telemetría (Q-08).

**Momento:** condición previa a la primera licencia de pago (fecha más temprana estimada: 2026-12-14 [I], `[BP-L2]` §10.3).

**Restricciones verificadas:**
- `VerificarCompacto` solo admite los `typ` de `FuncionPorTypCompacto` [V]; agregar el acta exige una entrada en `GPOS.Criptografia`. El `typ` se compara en forma ordinal y va dentro de la entrada firmada; `Verificar` (serialización general) solo admite la licencia [V, confirmado por `[SEG-AR]` AR-10].
- Mientras el padrón no verifica, nadie entra a la API, así que L-06 no está disponible: la solicitud la produce `GPOS.Migracion` [I].
- El cupo del resellado es el global, `CupoUsuarios(null)` [V].
- Sin telemetría (Q-08): el reporte viaja en la solicitud L-06 de cada renovación.

---

## 2. Módulos y dependencias

| Módulo | Qué agrega | Dueño |
|---|---|---|
| `GPOS.Contracts/Licencia` | `FormatoActaResellado` (constantes, catálogo de causas, estados del diagnóstico y **listas del modelo cerrado**), `ContenidoActaResellado`, `SolicitudResellado`, `ReselladoSolicitudDto`; campos de `SolicitudLicenciaDto` | L |
| `GPOS.Criptografia/Jws` | `TiposJws.ActaResellado` en `FuncionPorTypCompacto` (función `Licencia`) | L |
| `GPOS.Core/Sistema/Licencia` | `ActaResellado.Verificar`, pura e `internal` (`InternalsVisibleTo` solo para `GPOS.Migracion` y `GPOS.Tests`); `LeerActa`; `HuellaCuentas` canónica; bloque del resellado en `SolicitudAsync` (L-06) | L |
| `GPOS.Core/Sistema/Usuarios` | `SolicitarReselladoAsync`, `ResellarAsync` con acta, `DiagnosticoPadrones`, `HuellaContenido`, fila `Licencia.ReselladoPendiente`, `FilaSelloInicial` v2 y la entrada en la reprotección (AR-06) | Núcleo del sello (desarrollador de identidades) |
| `GPOS.Migracion/Sellos` | `--solicitud <ruta> [--excluir …]`, `--acta <archivo>` y el registro de eventos de Windows | Núcleo del sello |
| `GSF.EmisorLicencias` | Regla 11, registro `ACTA_RESELLADO` y comparación de L-06 | I (emisor) |
| `instalador/` | Origen del registro de eventos de Windows para `GPOS.Migracion`, si no existe | I (instalador, devops) |

**Sin ciclos:** `Contracts` y `Criptografia` ← `Core` ← (`Api`, `Migracion`). El emisor no referencia `GPOS.Core`: repite la verificación posterior con `VerificarCompacto` y las listas de `FormatoActaResellado` (lección EV-01: las listas viven solo en Contracts).

**La API no verifica actas**: solo lee `SelloInicial` para L-06. La prueba de arquitectura `La_API_nunca_resella` se extiende a `ActaResellado` sobre todo `src`, salvo `GPOS.Migracion` (R-2 de `[VAL-SLF]`).

---

## 3. C4

No hay contenedores nuevos (`[LIC]` 8.2 y 8.3). Flujo fuera de banda:

```
Técnico (servidor del cliente)                         GSF (cuenta gsf-firma, equipo emisor)
GPOS.Migracion sellos --resellar --solicitud ──.gposresol──▶ Emisor: regla 11, confirmación (cada SUPER), firma
                      ◀──.gposacta (JWS compacto)──────────── registro encadenado ACTA_RESELLADO (sin la lista)
GPOS.Migracion sellos --resellar --acta … --confirmar
API (después): L-06 ──correo──▶ Emisor: regla 8 + comparación del resellado
```

---

## 4. Modelo de dominio

| Concepto | Qué es | Invariantes |
|---|---|---|
| **Solicitud de resellado** | JSON sin secretos que produce `GPOS.Migracion` | Solo si se cumplen las condiciones de SL-F2. Lleva el `nonce` nuevo, la lista (ya sin las excluidas), el estado observado y el diagnóstico |
| **Resellado pendiente** | Fila con MAC `Licencia.ReselladoPendiente`: `{ InstalacionId, Nonce, GeneradaUtc, CuentasHuella, HuellaContenido, Excluidas[], Estado }` | Hay una sola. Una solicitud nueva la reemplaza y deja inservible el acta anterior. Se borra en la transacción del resellado. Entra en la reprotección del anillo (AR-06) |
| **Estado observado** | `{ selloInicial: Verifica\|Ausente\|NoVerifica, licenciasAceptadas: bool, padronBase, padronDisco: Ausente\|LlaveAusente\|MacInvalido\|Verifica, llaveMasNuevaUtc }` | Es informativo (A2 lo puede fabricar), pero queda ligado al acta: al usarla, el estado tiene que ser el mismo que evaluó GSF |
| **Acta de resellado** | JWS compacto firmado por GSF | Una instalación, una licencia vigente, un `nonce`, una lista, un estado y 24 h. Se consume una sola vez |
| **Sello inicial v2** | `FilaSelloInicial` con `Origen = RESELLAR` [V, ya existe], más `Aid`, `ActaRef`, `KidActa` y `CuentasHuella` (nulos en los demás orígenes) | Es la fuente del reporte de L-06 |
| **Evento `PADRON_RESELLADO`** | Ya existe [V] | El detalle suma `aid`, acta, `kid`, nivel, causa, huella y versión del padrón |

**Diagnóstico de un padrón** (AR-02): se lee la cabecera del blob de Data Protection. Si el identificador de llave no está en el anillo, el resultado es `LlaveAusente`; si la llave está y el `Unprotect` falla, `MacInvalido`. Como control no vale, porque A2 puede fabricar un blob con otra llave (por eso `[SEG-SLF]` lo descartó como regla). Como **criterio de emisión** para GSF, sí sirve.

---

## 5. Contratos

### 5.1 Acta: `gpos-acta-resellado+jws`

**Serialización:** JWS **compacto**, con una sola firma. Máximo **8 KB**, comprobado en `GPOS.Core` antes de llamar al verificador.

**Encabezado protegido:** `{ "alg": "ES256", "typ": "gpos-acta-resellado+jws", "kid": "<kid>", "nivel": "basico|avanzado" }`, sin `crit`, `b64` ni encabezado no protegido (el verificador ya lo exige [V]).

**Llave y nivel** (ADR-61, ADR-62):
- llaves de la función **`Licencia`**: `gsf-lic-s1` (Básico, precisión del 2026-10-14 de ADR-62) o `gsf-lic-a1`/`b1` (Avanzado);
- **piso:** se toma de `PisoNivelFirma.Efectivo`, que también sale de las licencias firmadas, así que A2 no lo baja sin borrarlas. Si no se puede calcular, se trata como **Avanzado** (falla cerrada). Con piso Avanzado se exige firma Avanzada propia (AR-09);
- **sin llaves `latente`** (`s2`): el acta no lleva `autNivel`. *Corrección de la v1.0 (AR-09):* durante un regreso temporal con causa `AusenciaCustodios` puede no haber ninguna llave Avanzada disponible durante hasta 30 días (60 acumulados [V `AutorizacionRegresoNivel`]). En esa ventana, una instalación con piso Avanzado no recibe acta (R-AG6);
- `gsf-lic-dev*` solo en Debug (NV-05).
- *Descartada:* una llave propia de actas. Suma una ceremonia y un custodio sin ganancia frente a R-B11.

**Contenido** (modelo cerrado; `crit` ausente o vacío):

| Miembro | Tipo | Regla |
|---|---|---|
| `fmt` | int | `1` |
| `tipo` | string | `"RESELLAR"` (defensa en profundidad además del `typ`) |
| `aid` | uuid | Identificador del acta |
| `sec` | long | Segundos UTC × 100 + contador, de la hora NTP del emisor. **Mayor que `secLicencia` y no mayor que la hora protegida + 48 h** (INV-6, AR-07) |
| `emitida` | UTC | Hora NTP − 10 min |
| `hasta` | UTC | Hora NTP + 24 h. `hasta − emitida ≤ 24 h 10 min` |
| `emisor` | string | `"GSF"` |
| `instalacion` | string | `InstalacionId`, comparación ordinal |
| `secLicencia`, `sha256Licencia` | long, hex 64 | Licencia vigente (`sha256` del **contenido**, SEG-L2-18) |
| `nonce` | base64url, 16 bytes | El de la solicitud |
| `acta` | string 6–60 | Referencia del caso en GSF. Sustituye al `--acta <ref>` de texto que hoy exige `ExigirActa` [V] |
| `causa` | string | Catálogo **cerrado** (AR-02): `AnilloIncompleto` (se recuperó un anillo anterior: verifica `InstalacionId` y falta la llave de los padrones) o `InstalacionNueva` (anillo perdido del todo; nueva `InstalacionId` con licencia nueva de GSF; ver 6.5). **`PadronIlegible` se retira** |
| `estado` | objeto | El estado observado de la sección 4, tal como lo evaluó GSF |
| `cuentas` | objeto | `{ "total", "noSuper", "huella" }` (5.3), **después de las exclusiones** |
| `cupo` | int | Cupo vigente usado para el cálculo |
| `enExceso` | bool | `noSuper > cupo`. Solo puede ser `true` con la excepción del histórico (AR-04, 6.4) |

Sin datos personales ni secretos: la lista no viaja en el acta, solo su huella.

### 5.2 Solicitud de resellado (`.gposresol`)

```
sellos --resellar --solicitud <ruta> --motivo "<10–200>" [--excluir <código,…>]
```

```json
{ "fmt": 1, "tipo": "SOLICITUD_RESELLAR",
  "instalacion": "…", "secLicencia": 0, "sha256Licencia": "…",
  "nonce": "…", "generada": "2026-12-14T15:00:00Z",
  "estado": { "selloInicial": "Verifica", "licenciasAceptadas": true,
              "padronBase": "LlaveAusente", "padronDisco": "LlaveAusente", "llaveMasNuevaUtc": "…" },
  "cuentas": [ { "codigo": "ADMIN", "nivel": "ADMIN" } ],
  "excluidas": 0, "total": 0, "noSuper": 0, "cupo": 0, "enExceso": false,
  "version": "<binarios>" }
```

- `cuentas`: solo código y nivel de las habilitadas que se sellarían, **ya sin las excluidas** (AR-04); `excluidas` es solo un número. Sin nombres ni hashes (AG-04, AR-11).
- **Sin `huellaEntorno`** (AR-11: el emisor no la usa).
- Solo se genera si se cumplen las condiciones de SL-F2 (ningún padrón verifica; el disco falla cerrado) y si hay una licencia vigente legible. **No** se niega por SLF-01: el estado de `SelloInicial` se informa y GSF lo juzga según la causa.
- Al generarla, el verbo toma el padrón (AR-05), escribe `ReselladoPendiente` con `nonce`, `CuentasHuella`, `HuellaContenido`, `Excluidas` y `Estado`, y deja el evento `RESELLADO_SOLICITADO` (I).

### 5.3 Huellas

**`CuentasHuella`** (viaja en la solicitud y en el acta): `hex(SHA-256(UTF-8(concat(CODIGO + "\t" + NIVEL + "\n"))))`. Los códigos van en mayúsculas invariantes, en orden **ordinal en memoria** (`StringComparer.Ordinal`, nunca el `OrderBy` de EF con la intercalación CI de `GPOS_SYSDATA`, AR-05). Solo cuentas habilitadas **no excluidas**.

**`HuellaContenido`** (solo local, en `ReselladoPendiente`; no viaja, AR-03): mismo orden y mismo conjunto. Por cuenta: `CODIGO \t NIVEL \t INHABILITADO \t RESTRINGIR_SUCURSAL \t SHA256(PasswordHash) \t FACTOR_ALTA \t PERFILES(ordinal, ";") \t EXCEPCIONES(ordinal, ";") \n`. Son los campos que cubre el sello (ADR-83, puntos 1 y 6), más los permisos granulares: el sello no los protege, pero no deben cambiar entre la solicitud y el resellado, porque en ese intervalo nadie entra a la API. El formato exacto de cada campo lo fija el núcleo del sello con vectores propios.

### 5.4 Reporte en L-06 (L-07 aplazado)

**L-06** `GET /api/super/licencia/solicitud` (la ruta, el permiso y la clase no cambian [V]). `SolicitudLicenciaDto` suma campos **opcionales**:

```csharp
long? PadronVersion,            // versión del padrón vigente (segundos Unix desde R-1; null si no verifica)
int? PadronConsumoNoSuper,      // entradas no SUPER del padrón
ReselladoSolicitudDto? UltimoResellado;
public sealed record ReselladoSolicitudDto(Guid Aid, string ActaRef, DateTime ReselladoUtc, string KidActa,
    string CuentasHuella, int Cuentas, long PadronVersionInicial);
```

- Fuente: `SelloInicial` v2 (MAC), nunca `BitacoraSeguridad`. Sin secretos ni datos personales.
- **No es íntegro frente a A2** (R-AG4): la instalación no tiene ninguna llave que GSF pueda verificar. Sirve contra A3 sin conocimientos técnicos, contra los errores y contra el uso del verbo con datos borrados a mano.

**L-07 `PorResellado`: aplazado** (AR-08). Su derivación por `HabilitadoUtc` es [I], no viaja a GSF y no es un control. Se retoma si L confirma la derivación y el soporte lo pide. La firma («se reporta en L-06/L-07») se cumple con L-06; si el propietario exige L-07 en esta pieza, cuesta 0,05 dp (anotado en AG-02).

### 5.5 Códigos y eventos

| Código / evento | Estado | Cuándo |
|---|---|---|
| `ACTA_INVALIDA` | 422, salida 1 | Firma, `typ`, modelo, `fmt`, causa, nivel o piso, tamaño, `sec` fuera de rango |
| `ACTA_NO_APLICA` | 409, salida 1 | Instalación, licencia vigente, `nonce`, vigencia o uso único (sin decir cuál, C10) |
| `ACTA_NO_COINCIDE` | 409, salida 1 | Cuentas (huella, totales, `HuellaContenido`), estado observado, exceso, o causa incompatible con el estado |
| `ACTA_REQUERIDA` | 422 | Sin `--acta`. Ya existe como `ActaRequerida` para el texto [V]; pasa a exigir el archivo |
| `PADRON_VERIFICA` | 409 | Ya existe [V]: SL-F2, y SLF-01 cuando la causa no la levanta |
| `RESELLADO_SOLICITADO` | evento I | Se generó una solicitud |
| `ACTA_RESELLADO_RECHAZADA` | evento A | Se presentó un acta y se rechazó (`aid` si se pudo leer, `kid` y regla) |
| `PADRON_RESELLADO` | evento A | Ya existe [V]; detalle ampliado |

---

## 6. Interfaces entre módulos

### 6.1 Verificación pura (L)

```csharp
internal static class ActaResellado
{
    public const int TamanoMaximo = 8 * 1024;
    public static readonly TimeSpan VigenciaMaxima = TimeSpan.FromHours(24) + TimeSpan.FromMinutes(10);
    internal static ResultadoActa Verificar(string jwsCompacto, ContextoActa contexto, ConjuntoLlaves llaves, IVerificadorJws verificador);
}
internal sealed record ContextoActa(string InstalacionId, long SecLicenciaVigente, string Sha256LicenciaVigente,
    ReselladoPendiente? Pendiente, NivelPiso PisoEfectivo /* Avanzado si no se calcula */, DateTime HoraProtegida,
    EstadoObservado EstadoHoy, string CuentasHuellaHoy, string HuellaContenidoHoy, int TotalHoy, int NoSuperHoy, int CupoHoy,
    Guid? AidYaConsumido);
```

**Orden** (falla en la primera):
1. Tamaño ≤ 8 KB → `ACTA_INVALIDA`.
2. `VerificarCompacto(acta, TiposJws.ActaResellado, llaves)` → `ACTA_INVALIDA`.
3. Firmante no `latente`; con piso Avanzado, firma Avanzada propia (`NivelFirmaLicencia.EsAvanzadaPropia` [V]) → `ACTA_INVALIDA`.
4. Lectura estricta: modelo cerrado de Contracts, causa del catálogo, `acta` de 6 a 60 caracteres sin caracteres de control, vigencia ≤ 24 h 10 min, `sec` mayor que `secLicencia` y no mayor que `HoraProtegida` + 48 h → `ACTA_INVALIDA`.
5. Vínculos: instalación; `secLicencia` y `sha256Licencia`; `Pendiente` presente y con el mismo `nonce`; `emitida ≤ HoraProtegida ≤ hasta`; `aid ≠ AidYaConsumido` → `ACTA_NO_APLICA`.
6. Coincidencias → `ACTA_NO_COINCIDE`:
   - `cuentas.huella` y los totales son iguales a los de hoy y a `Pendiente.CuentasHuella`;
   - `HuellaContenidoHoy` es igual a `Pendiente.HuellaContenido`;
   - el `estado` del acta es igual a `EstadoHoy` y a `Pendiente.Estado`;
   - `enExceso` es igual a `NoSuperHoy > CupoHoy`;
   - **la causa es compatible con el estado**: `AnilloIncompleto` exige `padronBase = padronDisco = LlaveAusente`; `InstalacionNueva` exige `selloInicial` en `NoVerifica` o `Ausente` y los dos padrones en `LlaveAusente` o `Ausente`.

`HoraProtegida` es la de `IRelojProtegido` (H-16 v2.1); nunca la hora local ni la `emitida` de otra cosa (EV-03).

### 6.2 Flujo de `sellos --resellar --acta` (núcleo del sello)

```
sellos --resellar --acta <archivo.gposacta> --motivo "<10–200>" [--confirmar]
```

`--acta` deja de ser la referencia de texto que hoy exige `ExigirActa` [V] y pasa a ser **la ruta del archivo firmado**, en todas las compilaciones y sin interruptor (ADR-60, punto 6). La referencia humana sale del campo `acta` firmado.

| # | Paso | Falla con |
|---|---|---|
| 1 | `--motivo` (`ExigirMotivo` [V]) y `--acta` presentes | 422 |
| 2 | `ExigirAnilloAsync`: `InstalacionId` verifica [V] | salida 1 |
| 3 | Lectura del archivo con tope de 8 KB + 1 byte | `ACTA_INVALIDA` |
| 4 | Licencia vigente en Estricto (`LicenciaVigenteAsync` [V]); sin licencia legible no hay resellado | `ACTA_NO_APLICA` |
| 5 | `ActaResellado.Verificar` fuera de la transacción (6.1) | códigos de 6.1 y evento `ACTA_RESELLADO_RECHAZADA` |
| 6 | **SL-F2:** ningún padrón verifica, ni en la base ni en el disco (el disco falla cerrado, SLF-02 [V]) | `PADRON_VERIFICA` |
| 7 | **SLF-01 con acta** (AG-01 (a′)): «`SelloInicial` verifica» niega, **salvo** con la causa `AnilloIncompleto`; «falta y hay licencias aceptadas» niega, salvo con la causa `InstalacionNueva` (ahí la licencia aceptada es la nueva, 6.5). «Existe y no verifica» ya no basta por sí sola: **el acta es obligatoria en toda rama** (AR-01) | `PADRON_VERIFICA` |
| 8 | Muestra la lista, el consumo, el cupo, el exceso y las excluidas; sin `--confirmar` sale con 2 | — |
| 9 | Con `--confirmar`, transacción serializable (AR-05):<br>- toma el padrón (`TomarAsync`);<br>- lee `ReselladoPendiente` y `SelloInicial` con `UPDLOCK, HOLDLOCK`;<br>- **relee la licencia vigente** (`sec` y SHA-256);<br>- lee **una sola vez** los usuarios habilitados no excluidos y los ordena en memoria (ordinal);<br>- con **esa lista** recalcula `CuentasHuella` y `HuellaContenido` y repite los pasos 5 a 7;<br>- sella esa misma lista;<br>- crea el padrón (versión en segundos Unix [V]);<br>- escribe `SelloInicial` v2 (`RESELLAR` y `aid`);<br>- borra `ReselladoPendiente`;<br>- registra `PADRON_RESELLADO` y confirma | `PADRON_VERIFICA`, `ACTA_NO_APLICA`, `ACTA_NO_COINCIDE` |
| 10 | Después de confirmar: copia del padrón en el disco [V] y evento en el registro de Windows (`EventId` que asigna L). Una falla aquí se informa y no deshace nada | aviso |
| 11 | El verbo recuerda el paso obligatorio del procedimiento: **restablecer las contraseñas de todo SUPER y ADMIN**, y la inscripción TOTP cuando exista (AR-03) | — |

**Orden:** el acta va antes que SL-F2 y SLF-01, porque sin un acta válida no hay nada que comprobar. SL-F2 manda siempre: un acta nunca sustituye un padrón que verifica.

**`--solicitud` también toma el padrón** antes de escribir `ReselladoPendiente`. Así una solicitud y un resellado concurrentes se serializan sobre el mismo recurso y dejan exactamente uno de los dos efectos (AR-05).

**Uso único** (AR-07, texto corregido). Las capas son cuatro:
- el `nonce` de `ReselladoPendiente`, que se borra en la transacción y que una solicitud nueva reemplaza;
- el vínculo con la licencia vigente;
- las 24 h, medidas con la hora protegida;
- el `aid` guardado en `SelloInicial` v2.

**Estas capas impiden la repetición por A1, por A4 y por error. Frente a A2, que tiene el anillo y puede reescribir esas filas con un MAC válido, la repetición no se impide: se detecta en GSF** (`RESELLADO_REPETIDO` y `RESELLADO_NO_AUTORIZADO`, 6.4). Es el mismo residual que R-S2 y R-AG1.

**Exceso de cupo** (AR-04, AG-05 (b)):
- Por omisión, el acta trae `enExceso: false` y la instalación lo comprueba.
- Si las cuentas superan el cupo, el técnico vuelve a pedir la solicitud con `--excluir`. Las cuentas excluidas quedan `FueraDePadron` y se legitiman después, dentro del cupo.
- Única excepción: el emisor admite `enExceso: true` si el último L-06 registrado ya reportaba un `PadronConsumoNoSuper` mayor o igual que el `noSuper` del acta. En ese caso la empresa queda `EnExceso`, como firmó SL-F2 (b).

### 6.3 Preparado para la vía (b+) de ADR-81

La (b+) es de la misma familia: una autorización de servidor firmada por GSF, ligada a la instalación y a 24 h. Se reutilizan la lectura estricta, el contexto de hora, el vínculo con la licencia y el registro del emisor. **Cada propósito tendrá su propio `typ`** (por ejemplo, `gpos-acta-factor+jws`), nunca un `typ` genérico con un campo `tipo` (RFC 8725, 3.11). `[SEG-AR]` AR-10 confirma que el verificador ya separa los `typ` [V].

### 6.4 Emisor: regla 11 de `[BP-L2]` §9.2 (I)

**Entrada:** el archivo `.gposresol` y la referencia del caso.

**Controles, en orden:**
1. **Condiciones de una licencia** (reglas 4, 6 y 7): NTP en dos fuentes con desvío ≤ 1 min, sesión de `gsf-firma`, PIN y *handle* por firma.
2. **Instalación y licencia:** la instalación está en el registro, y `secLicencia` y `sha256Licencia` son los de la última licencia emitida (regla 8). Si no, `LICENCIA_NO_EMITIDA_POR_GSF` → AP-03.
3. **Causa y estado** (AR-02):
   - `AnilloIncompleto`, solo con los dos padrones en `LlaveAusente`;
   - `InstalacionNueva`, solo si la instalación es nueva en el registro y ya tiene una licencia emitida (6.5);
   - con cualquier `MacInvalido`, **no se emite sin el propietario** (indicio de manipulación);
   - con `AnilloIncompleto` y el padrón del disco `Ausente`, también hace falta el propietario.
4. **Una sola acta viva** por instalación: la nueva sustituye a la anterior en el registro.
5. **Revisión de la lista** con el contacto registrado del cliente, no con quien envió el archivo. **Cada SUPER** que no figure en un registro anterior de esa instalación exige una confirmación propia; si no hay registro anterior, todos la exigen (AR-03).
6. **Exceso** (AR-04): si `noSuper > cupo`, el emisor **se niega**, salvo que el último L-06 registrado reportara un `PadronConsumoNoSuper` mayor o igual que `noSuper`.
7. **Frecuencia** (AG-06): se cuentan las actas **emitidas**; una segunda en 365 días exige al propietario en la misma sesión.
8. **Armado del acta:**
   - el encabezado protegido sale **de una constante por operación**, nunca de la solicitud (AR-10);
   - `aid` nuevo;
   - `sec`, `emitida` y `hasta`, de la hora NTP (EV-03);
   - `estado` copiado de la solicitud **después** de que el operador lo aceptó;
   - la huella la **recalcula el emisor** desde la lista.
9. **Confirmación desde los bytes** (SEG-L2-19): el custodio ve el `typ` decodificado, la instalación, el cliente, el caso, la causa, el estado, las cuentas, los SUPER, el cupo, el exceso y `hasta`.
10. **Verificación posterior** con `VerificarCompacto`, el `LlavesGsf.json` publicado y las listas de Contracts.
11. **Registro encadenado** `ACTA_RESELLADO`: `aid`, instalación, `sec`, SHA-256 del contenido, `kid`, nivel, caso, operador, causa, estado, totales, cupo, exceso, huella, `hasta` y SHA-256 del `nonce`. **La lista y el archivo `.gposresol` no se conservan** después de emitir (AR-11).
12. **Salida:** `resellado-<instalacion>-<aid>.gposacta`, entregado al contacto registrado.

**Comparación al recibir una L-06** (extensión de la regla 8). Sirve contra A3, contra los errores y contra el uso del verbo con datos borrados a mano; **no contra un A2 que programe** (R-AG4):

| Lo que trae L-06 | Lo que hace el emisor |
|---|---|
| `UltimoResellado.Aid` emitido para esa instalación, con la misma huella, en su primer reporte | Marca el acta como consumida |
| Un `Aid` ya consumido, con otro `ReselladoUtc` u otra `PadronVersionInicial` | **Se detiene** con `RESELLADO_REPETIDO` → AP-03 (AR-07) |
| Un `Aid` desconocido, de otra instalación o con otra huella | **Se detiene** con `RESELLADO_NO_AUTORIZADO` → AP-03 |
| `PadronVersion` ≥ 10⁹, con una marca de tiempo posterior al último reporte y sin ningún `aid` emitido en ese intervalo | **Se detiene** con `RESELLADO_NO_AUTORIZADO` (AR-08) |
| `PadronVersion` menor que la última reportada, sin un resellado nuevo | Alerta `PADRON_RETROCEDIDO_EN_GSF` |
| Un acta emitida, vencida y sin reportar | **Aviso al soporte** (AR-08) para confirmar con el cliente que no la usó |
| `PadronConsumoNoSuper` mayor que el cupo emitido | Marca la instalación en exceso; es el histórico de AR-04 |
| Una solicitud sin los campos (binarios anteriores) | Aviso «sin datos del padrón» |

### 6.5 Flujo de la instalación nueva (AR-12)

Caso: el anillo se perdió del todo. `InstalacionId` deja de verificar y el verbo se niega (`ExigirAnilloAsync` [V]); la licencia está ligada a la instalación anterior.
1. Se genera una `InstalacionId` nueva con el anillo nuevo, por el procedimiento que fije el núcleo del sello. Hoy `sistema` no la reemplaza [V `ComandoSistema.cs`, citado por `[SEG-SLF]`]. **[I]** Si ese procedimiento todavía no existe, es una entrega al núcleo del sello.
2. L-06 no está disponible porque nadie entra, así que el técnico exporta la solicitud de licencia con `GPOS.Migracion` (entrega a L: el mismo `SolicitudAsync`, llamado desde el verbo).
3. GSF emite la licencia nueva para la nueva `InstalacionId` (regla 8, con el procedimiento AP-03 de reinstalación).
4. El técnico copia el `.gposlic` en la carpeta de la licencia, y el arranque la acepta desde el disco (`vigente.gposlic` o `Procesados` [V `EstadoLicenciaService.cs:290-298`, según `[SEG-AR]`]). Que lo haga mientras el padrón no está disponible es [I].
5. `sellos --resellar --solicitud`. Estado esperado: `selloInicial = NoVerifica`, padrones en `LlaveAusente` y `licenciasAceptadas = true` (la licencia nueva).
6. GSF emite el acta con la causa `InstalacionNueva`; la regla 2 se cumple con la licencia recién emitida.
7. `sellos --resellar --acta … --confirmar`, y después el restablecimiento de contraseñas.

---

## 7. Estructura de proyectos y carpetas

Sin proyectos nuevos (H0 §4.2; ADR-109, cláusula 1).

```
src/GPOS.Contracts/Licencia/FormatoActaResellado.cs        (nuevo, enlazado por el emisor)
src/GPOS.Contracts/Licencia/LicenciaDtos.cs                (campos de L-06)
src/GPOS.Criptografia/Jws/ContratosJws.cs, VerificadorJws.cs (typ)
src/GPOS.Core/Sistema/Licencia/ActaResellado.cs            (nuevo, internal)
src/GPOS.Core/Sistema/Licencia/LectorContenidoLicencia.cs  (LeerActa)
src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs    (SolicitudAsync)
src/GPOS.Core/Sistema/Usuarios/SellosService.cs            (solicitud, resellado con acta, diagnóstico, huellas, SelloInicial v2)
src/GPOS.Core/Sistema/Usuarios/PadronSellos.cs             (ClavesSellos)
src/GPOS.Core/.../ReproteccionSecretos.cs                  (filas de AR-06)
src/GPOS.Migracion/Sellos/ComandoSellos.cs, Program.cs     (--solicitud, --excluir, --acta <archivo>)
docs/contratos/vectores/acta-resellado.v1.json             (nuevo)
GSF.EmisorLicencias: Emision/ReglasEmisor.cs, Emision/ServicioEmision.cs, registro (nombres [I])
```

---

## 8. Requisitos de seguridad de arquitectura

| Tema | Requisito |
|---|---|
| Autenticación | El verbo exige acceso de Windows y el anillo [V]; se suma la firma de GSF |
| Autorización | **Ningún resellado sin un acta válida, en ninguna rama** (AR-01). SL-F2 siempre; SLF-01 solo la levanta `AnilloIncompleto` (AG-01 (a′)). La emisión exige `gsf-firma`, PIN por firma, confirmación desde los bytes, cada SUPER confirmado, ningún exceso salvo el histórico y el propietario para una segunda acta en el año |
| Aislamiento | El acta es de instalación (`instalacion` exacta). Con la versión 1 (ADR-83, punto 9) el padrón pasa a la membresía y el acta tendrá que llevar `empresa` (pendiente; no se construye ahora) |
| Secretos | Ninguno nuevo. `HuellaContenido` es local y no viaja. El `nonce` se guarda en hash en el registro de GSF |
| Datos personales | Los códigos de usuario pueden serlo (Ley 172-13): solo van en la solicitud, no en el acta ni en el registro, y el emisor no conserva la lista (AR-11) |
| Integridad | `ReselladoPendiente` y `SelloInicial` v2 con MAC y dentro de la reprotección del anillo (AR-06); acta con ES256; registro del emisor encadenado y anclado |
| Configuración | Sin interruptores (ADR-60, punto 6); `gsf-lic-dev` solo en Debug |
| Detección | `PADRON_RESELLADO`, registro de eventos de Windows (borrarlo deja el evento 1102 [I]), `SelloInicial` v2 y la comparación de L-06 |

---

## 9. Sincronización

No aplica: los nodos de sucursal son de la entrega 2.

---

## 10. Pruebas exigidas

### 10.1 Vectores `docs/contratos/vectores/acta-resellado.v1.json`

Los consumen `GPOS.Tests` (en Debug) y el emisor. Van firmados con una llave de prueba publicada en el propio archivo (`kid` de desarrollo).

| # | Caso | Esperado |
|---|---|---|
| V-01 | Acta válida `AnilloIncompleto`, piso Básico | Aplica |
| V-01b | Acta válida `InstalacionNueva` | Aplica |
| V-02 | Firma maleada (r, n − s) | Verifica, con el mismo `Sha256Contenido` |
| V-03 | `typ` de licencia o de autorización de nivel | `ACTA_INVALIDA` |
| V-03b | Acta en serialización general presentada a `Verificar` como licencia | Rechazo |
| V-03c | Acta dentro de `autNivel` | Rechazo |
| V-03d | Autorización de nivel presentada como acta | `ACTA_INVALIDA` |
| V-03e | `typ` con otra capitalización | `ACTA_INVALIDA` |
| V-04 | `kid` de otra función | `ACTA_INVALIDA` |
| V-05 | `kid` `latente` | `ACTA_INVALIDA` |
| V-06 | `nivel` incoherente | `ACTA_INVALIDA` |
| V-07 | Piso efectivo Avanzado (o no calculable) con firma Básica | `ACTA_INVALIDA` |
| V-08 | Miembro desconocido, obligatorio ausente, `crit` no vacío, `fmt: 2`, causa `PadronIlegible` u otra, `acta` de 5 o de 61 caracteres | `ACTA_INVALIDA` |
| V-09 | Más de 8 KB | `ACTA_INVALIDA` |
| V-10 | Vigencia de 24 h 11 min; `sec` ≤ `secLicencia`; `sec` > hora + 48 h | `ACTA_INVALIDA` |
| V-11 | Otra instalación, `secLicencia`, `sha256Licencia` o `nonce`; sin pendiente | `ACTA_NO_APLICA` |
| V-12 | Hora protegida antes de `emitida` o después de `hasta` | `ACTA_NO_APLICA` |
| V-13 | `aid` ya consumido | `ACTA_NO_APLICA` |
| V-14 | Una cuenta de más o de menos, un nivel distinto, `enExceso` incoherente | `ACTA_NO_COINCIDE` |
| V-14b | `estado` distinto del de hoy; `AnilloIncompleto` con un padrón `MacInvalido`; `InstalacionNueva` con `selloInicial = Verifica` | `ACTA_NO_COINCIDE` |
| V-15 | Huella canónica: minúsculas, orden ordinal con dígitos y guion bajo (distinto del orden CI), lista vacía, lista tras exclusiones | Huellas fijas |

### 10.2 Pruebas del núcleo y de la API (dirigidas)

- Sin `--acta`, también con `SelloInicial` estropeada por SQL (AR-01): se niega.
- Con acta válida: padrón nuevo, `SelloInicial` v2, pendiente borrada y evento sin secretos.
- Repetir con la misma acta, generar una segunda solicitud o cargar una licencia nueva entre la solicitud y el acta: `ACTA_NO_APLICA`.
- **Cambio por SQL del hash, de un perfil o del nivel de una cuenta entre la solicitud y el resellado:** `ACTA_NO_COINCIDE` (AR-03).
- **SUPER insertado por SQL entre la solicitud y el resellado:** `ACTA_NO_COINCIDE`.
- Padrón que verifica: `PADRON_VERIFICA`, aunque el acta sea válida.
- SLF-01: `SelloInicial` que verifica con `AnilloIncompleto` → resella; con `InstalacionNueva` → niega.
- **`--solicitud` concurrente con `--confirmar`:** exactamente uno de los dos efectos (AR-05).
- Dos resellados concurrentes con la misma acta (con la fila del padrón presente y borrada): uno solo escribe.
- Exceso: sin histórico, el acta trae `enExceso: false` y una instalación en exceso da `ACTA_NO_COINCIDE`; con `--excluir`, resella dentro del cupo y las excluidas quedan `FueraDePadron`.
- Reprotección del anillo y revocación de la llave heredada: `SelloInicial` y `ReselladoPendiente` siguen verificando (AR-06).
- **Instalación nueva de punta a punta** (6.5), con la licencia aceptada desde el disco (AR-12).
- L-06 lleva los campos nuevos; con `SelloInicial` alterada, `UltimoResellado = null`.
- Arquitectura: `ActaResellado` solo se usa desde `GPOS.Migracion` y es `internal`.
- `VerificadorJwsCompactoTests`: el `typ` nuevo solo acepta llaves de la función `Licencia`.

### 10.3 Pruebas del emisor

- Los vectores V-01 a V-15 en la verificación posterior.
- La regla 2, y el criterio por causa con `MacInvalido`.
- Cada SUPER sin registro previo pide confirmación.
- El exceso se niega sin histórico y se admite con él.
- Encabezado constante; `hasta` calculado desde NTP; huella recalculada.
- La lista y el archivo no quedan en disco.
- La tabla de comparación de 6.4, incluidos `RESELLADO_REPETIDO` y la versión Unix sin `aid`.

---

## 11. Necesidades para Datos, Integraciones y otros

| Agente | Necesita |
|---|---|
| arquitecto-datos | Sin DDL: `Licencia.ReselladoPendiente` (nueva) y `SelloInicial` v2 en `dbo.Configuracion`, con la lectura de la fila v1 compatible |
| Núcleo del sello (desarrollador de identidades) | AR-05 y AR-06 (la reprotección puede ir ya en el PR de SL-F1/SL-F2); el procedimiento para generar una `InstalacionId` nueva, si no existe (6.5) |
| Desarrollador L | AR-09 (piso efectivo); la derivación de L-07 si se retoma; `SolicitudAsync` exportable desde `GPOS.Migracion` (6.5) |
| Emisor (I) | AR-03 (2), AR-04, AR-07, AR-08 y AR-10 (sección 6.4) |
| devops / instalador | Origen del registro de eventos de Windows. Alternativa de AR-06: respaldar el anillo al crear cada llave, o hacerlo con Backup Tool (MD-54) |
| documentador-tecnico | Procedimiento del resellado con acta, con SLF-06 y el **restablecimiento de contraseñas de SUPER y ADMIN** (AR-03 (3)); procedimiento de GSF para emitir (contacto registrado, SUPER, exceso, retención y canal, AR-11); excepción de `AusenciaCustodios` con piso Avanzado (AR-09). Todo dentro de AP-03 |
| qa-automatizado | Vectores de 10.1 (con V-03b a V-03e) y pruebas de 10.2 |
| auditor-seguridad | Revisión del código (0,25 dp), verificando AR-01 a AR-04 |
| Integraciones | No aplica |

---

## 12. Preguntas para firma del propietario

**AG-01 · ¿El acta de GSF levanta SLF-01?**
- **Contexto:**
  - SLF-01 se salta con una escritura SQL (AR-01), así que frente a A2 y A3 la barrera real es la política de emisión de GSF.
  - El caso legítimo más probable es recuperar un anillo anterior: verifica `InstalacionId` y `SelloInicial`, pero no los padrones. Esto es [I]: depende de la rotación de llaves y de cuándo se reprotegió (AR-06).
  - En ese caso nadie entra, `--legitimar` no sirve y SLF-01 niega el resellado.
- **(a′) Recomendada** (postura de `[SEG-AR]` §6). Con un acta válida se levanta **solo** la condición «`SelloInicial` verifica», y **solo** con la causa `AnilloIncompleto`, bajo cuatro condiciones:
  1. solo `AnilloIncompleto` la levanta; `PadronIlegible` sale del catálogo;
  2. el estado observado (`SelloInicial` y el diagnóstico de los padrones) viaja en la solicitud y queda ligado en el acta;
  3. el acta no autoriza un exceso que GSF no haya visto antes (AG-05);
  4. con esta pieza, ningún resellado se hace sin acta, en ninguna rama.

  La causa `InstalacionNueva` no levanta esa condición (en ese caso `SelloInicial` no verifica). Las condiciones de SL-F2 se aplican siempre. **Qué rompe:** nada de lo construido; precisa la lectura de SLF-01.
- **(b)** Acta y SLF-01 a la vez. El caso del anillo anterior solo se resuelve con un parche, a cambio de una protección que A2 salta con un `UPDATE`.

**AG-02 · Alcance del acta.**
- **(a) Recomendada.** Completa: solicitud, `nonce`, lista, estado y `HuellaContenido` local. Unos 1,6 dp. L-07 `PorResellado` queda aplazado (si se exige ahora, +0,05 dp).
- **(b)** Reducida: instalación, licencia vigente, `aid` y 24 h. Unos 0,9 dp. Deja que A1 legitime cuentas entre la emisión y el uso; el auditor no la recomienda.

**AG-03 · Vigencia.**
- **(a) Recomendada.** 24 h, como la (b+) de ADR-81. Excepción de servicio declarada: con piso Avanzado, durante un regreso temporal por `AusenciaCustodios`, no hay acta posible hasta que vuelva un custodio.
- **(b)** 72 h.

**AG-04 · Datos de las cuentas que recibe GSF.**
- **(a) Recomendada.** Código y nivel, sin nombres; el emisor no conserva la lista ni el archivo; sin `huellaEntorno`.
- **(b)** Solo totales y huella: GSF firma a ciegas.

**AG-05 · Exceso de cupo.**
- **(b) Recomendada, por omisión.** El acta no autoriza un exceso: las cuentas sobrantes se excluyen con `--excluir` y se legitiman después, dentro del cupo. **Excepción:** el último L-06 registrado ya reportaba un consumo mayor o igual que el del acta, es decir, el cliente ya estaba en exceso de forma legítima.
- **(a)** Permitir el exceso con confirmación y motivo. Descartada: convierte el acta en una recuperación de cupo firmada por GSF a pedido del interesado (AR-04, SEG-L2-07).

**AG-06 · Frecuencia.**
- **(a) Recomendada.** Se cuentan las actas **emitidas**. Una segunda en 365 días, o cualquier solicitud con un padrón `MacInvalido`, exige al propietario.
- **(b)** Sin límite.

**AG-07 · Precisión opcional de SLF-01 en el PR de SL-F1/SL-F2 (AR-01 (3)).**
- **Contexto.** Hasta que exista el acta, tratar «`SelloInicial` existe y no verifica, con licencias aceptadas de la instalación vigente» igual que «falta». Cuesta unos 0,02 dp. Con el acta deja de importar.
- **(b) Recomendada: no aplicarla.** Antes del acta no hay clientes de pago, y aplicarla cerraría también la única salida de la instalación nueva en el DEMO y en desarrollo.
- **(a)** Aplicarla ya: cierra el salto por `UPDATE` en el DEMO, a cambio de esa salida.

---

## 13. Riesgos y decisiones candidatas a ADR

### 13.1 Riesgos residuales

| # | Riesgo | Prob. / impacto | Tratamiento |
|---|---|---|---|
| R-AG1 | A2 programa el resellado con las API de `GPOS.Core`, o repite un acta reescribiendo filas con el anillo (AR-07) | Baja / Medio | No se impide (residual de CP-4, AP-04). Que el método sea `internal` lo encarece; GSF lo detecta en parte en L-06 (6.4) |
| R-AG2 | Compromiso de `s1`: actas falsas | Baja-Media / Alto | Sin capacidad nueva (R-B11); E-1 a E-15 y DL-14 |
| R-AG3 | A3 (el propio cliente) pide un acta para recuperar cupo o legitimar cuentas | Media / Medio | Criterio por causa y estado, ningún exceso salvo el histórico, cada SUPER confirmado y el propietario para una segunda acta. A2 puede fabricar el diagnóstico: es un criterio, no un control |
| R-AG4 | A2 omite o altera L-06 | Media / Medio | No es íntegro. Detecta errores, a A3 sin conocimientos y el uso del verbo con datos borrados; a un A2 que programa, no. La detección llega con la renovación (como máximo 200 días, DL-14) |
| R-AG5 | Reloj del servidor más de 10 min atrasado | Baja / Bajo | Falla cerrada; se corrige el reloj o GSF reemite |
| R-AG6 | Tiempo sin servicio mientras GSF emite. **Sin acta posible con piso Avanzado durante un regreso por `AusenciaCustodios`** (AR-09) | Media / Medio | 24 h y emisión en minutos; procedimiento de guardia. En el caso de los custodios, se espera al custodio o se aplica el procedimiento 2 de `[LIC]` 7.4 |
| R-AG7 | Códigos de usuario (datos personales, Ley 172-13) enviados por correo | Baja / Bajo | Minimización y no retención (AR-11) |
| R-AG8 | Divergencia de reglas entre el emisor y la API | Media / Bajo | Listas en Contracts y vectores compartidos; falla cerrada |
| R-AG9 | Hashes o perfiles alterados **antes** de la solicitud, que `HuellaContenido` no ve (AR-03) | Baja / Medio | Restablecer las contraseñas de SUPER y ADMIN después de resellar (procedimiento); el ADMIN revisa los perfiles después |

### 13.2 Decisiones candidatas a ADR (precisión de ADR-83, punto 7)

1. **Formato del acta** (5.1). *Descartadas:* llave propia, serialización general y texto libre.
2. **Un `typ` por propósito** para las autorizaciones de servidor de GSF. *Descartado:* un `typ` genérico con `tipo`.
3. **Solo `AnilloIncompleto` levanta SLF-01, y el acta liga el estado observado** (AG-01 (a′)). *Descartada:* levantarla con cualquier causa.
4. **El acta no autoriza un exceso que no se haya visto en un L-06 anterior** (AG-05 (b)). *Descartada:* AG-05 (a).
5. **`HuellaContenido` local** en `ReselladoPendiente`. *Descartado:* enviar hashes a GSF.
6. **Reporte en L-06** sin telemetría, con detención en el emisor. *Descartado:* leerlo de la bitácora.

---

## 14. Estimación y reparto (inferida, ±30 %)

| Parte | Contenido | dp |
|---|---|---|
| **L** (licencia, en el núcleo) | Contracts (0,1); `typ` y su prueba (0,05); `ActaResellado.Verificar`, `LeerActa`, estado y causa (0,25); campos de L-06 (0,08); piso efectivo (0,02) | **0,5** |
| **Núcleo del sello** | `--solicitud`, `--excluir`, pendiente y diagnóstico (0,12); flujo con acta, bloqueos y relectura (0,2); `HuellaContenido` (0,05); reprotección (0,03); registro de Windows (0,05); pruebas (0,1) | **0,55** |
| **I** (emisor e instalador) | Regla 11 (0,25); reglas nuevas: SUPER, exceso con histórico, `aid` repetido, versión Unix y aviso (0,1); comparación de L-06 (0,05); origen de eventos en el instalador (0,05) | **0,45** |
| QA | Vectores (con V-03b a V-03e y V-14b) | 0,1 |
| Documentador | Procedimientos (AR-03 (3), AR-09, AR-11) | 0,05 |
| **Total** | | **≈ 1,65 (≈ 1,6 ± 30 %)** |

- Coincide con `[SEG-AR]` §7 (unos 1,6 dp, ±30 %): +0,2 dp de AR-02 a AR-08 sobre la v1.0 y −0,05 dp por aplazar L-07.
- **Aparte:** 0,25 dp de revisión de seguridad del código. **Dinero:** USD 0.
- **Recorte aceptable con presión de plazo** (`[SEG-AR]` §7): diferir el registro de eventos de Windows y su origen en el instalador (0,1 dp). Conviene que entre antes de la primera licencia de pago, porque aporta detección frente a A2.
- **Opción reducida (AG-02 (b)):** unos 0,9 dp; no recomendada.
- **Orden:** después de unir el PR de SL-F1/SL-F2 (`a/sl-resellar-candado`, que ya trae SLF-01, C-2 a C-4 y SLF-02 a SLF-07) y el submódulo del emisor (después del #65); antes de la primera licencia de pago. B lo ubica en el plan.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\blueprint-acta-resellado-gsf-2026-10-17.md` (v1.1)
- Supuestos:
  - `GSF.EmisorLicencias` no está en este equipo: los nombres del emisor son [I];
  - son [I]: el caso del anillo anterior (rotación de llaves y momento de la reprotección), que el arranque acepte la licencia desde el disco sin padrón y el evento 1102 al borrar el registro de Windows;
  - el procedimiento para generar una `InstalacionId` nueva puede no existir todavía (6.5);
  - código leído: `a/sl-resellar-candado` @ `130306c0` y `a/rn-cambio-rnc` @ `da474174`;
  - no compilé ni ejecuté pruebas.
- Decisiones candidatas a ADR: las seis de 13.2 (precisión de ADR-83, punto 7).
- Entregas a otros agentes:
  - núcleo del sello → AR-05, AR-06 y 6.5;
  - L → 6.1, 5.4 y AR-09;
  - emisor (I) → 6.4 (AR-03 (2), AR-04, AR-07, AR-08 y AR-10);
  - arquitecto-datos → claves de `dbo.Configuracion`;
  - devops → origen de eventos y respaldo del anillo;
  - documentador → procedimientos de la sección 11;
  - QA → vectores y pruebas;
  - auditor → revisión del código con AR-01 a AR-04;
  - Arquitecto Maestro → hoja de firma de AG-01 a AG-07 y precisión de ADR-83;
  - B → ubicarlo en el plan.
- Próximo paso recomendado: el Maestro lleva AG-01 (a′) a AG-07 a firma; después construye A.
