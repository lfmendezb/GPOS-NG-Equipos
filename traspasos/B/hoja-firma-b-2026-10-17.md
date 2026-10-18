# Hoja de firma de B (2026-10-17, noche)

> **FIRMADA** por Leonardo Méndez, propietario, el 2026-10-17 en la sesión de B: «Firmo la hoja de B del 2026-10-17 según la recomendación: UN-01 (a), BM-01 (a), SE-01 (a), SE-02 (a), CB-01 (a), EM-01 (a), RS-01 (a) y OR-01.» Registro: SE-01 y SE-02 en ADR-51, CB-01 en ADR-54, RS-01 y OR-01 en ADR-83 (`master` `fe42b415`). UN-01: unión hecha en `feature/modelo-ng` `5b47e019`. BM-01: norma del banco desde ya. EM-01: lo crea el propietario.

**Preparada por:** B, en LFMB. **Firma:** el propietario. Cada punto se puede firmar por separado («Firmo X según la recomendación» o con otra opción).

Las decisiones que ya están firmadas en otras sesiones no entran aquí: SLF-01, el acta de GSF, AG-01 a AG-07, TN-01, 7(b), 7(d) y EV-03 (a), registradas en `master` `5cbbb12b`.

---

## UN-01 · Adelantar la unión de `b/prep-27oct`
**Contexto:** T6 quedó en verde el 2026-10-17 (informe `2026-10-16-t6-segunda-tanda.md`: T-28 1,008 con afinidad, T-57, compra y 5b en verde, N6-02 1,049). El ensayo local de la unión (`b/prep-27oct` + #66 sobre la punta) compila sin cambios de modelo pendientes. La suite oficial del ensayo no tiene fallas atribuibles (nota al pie).

| Opción | Consecuencia |
|---|---|
| **(a) Unir ya, en cuanto la suite del ensayo salga limpia (recomendada)** | Destraba diez días antes la cadena firmada: #52 + #55, #51, #45, #48 con el #60, #63 → #67 → #68 → #57 → #58, la ola 5, LP-01 y la serie E. Con el e-CF exclusivo desde el 15-nov, el margen importa. |
| (b) Mantener el 27-oct | Sin riesgo nuevo, pero la cadena espera diez días con todo listo. Solo se justifica si el 27-oct depende de algo fuera de T6, por ejemplo de la disponibilidad de A. |

## BM-01 · Afinidad del cliente como norma del banco de rendimiento
**Contexto:** el modo lento de T-28 venía de que los hilos del cliente compartían núcleos con el Express (C, 2026-10-17). Con `GPOST_B9_AFINIDAD=auto` (#66), base y candidato miden igual y la CPU por venta es comparable.

| Opción | Consecuencia |
|---|---|
| **(a) Las mediciones de T-28, T-57 y N6-02 se hacen con `GPOST_B9_AFINIDAD=auto` desde ya, en base y candidato (recomendada)** | Menos tandas repetidas por ruido. La medición firmada del 14-oct sigue siendo el tope (T-28 ≤ 32,8 y T-57 ≤ 31,6); solo cambia el procedimiento del control de atribución. |
| (b) Sin afinidad, como hasta ahora | Se mantiene el riesgo de tandas bimodales y de repetir. |

*Esto es del banco, no del producto. La afinidad en una instalación real (API y Express en el mismo equipo) no se recomienda sin medirla con la API real; queda para la ronda de rendimiento previa al primer cliente.*

## SE-01 · Selector del POS con el e-CF activo (#61 de C)
| Opción | Consecuencia |
|---|---|
| **(a) Con el e-CF activo y sin contingencia, el selector ofrece solo tipos E (recomendada)** | Coherente con ADR-51: la serie B no se emite fuera de contingencia, y un tipo B elegido a mano ya se rechaza con un mensaje neutro. |
| (b) Ofrecer B y E | El cajero vería opciones que el servidor rechaza. |

## SE-02 · Tipo E elegido a mano en contingencia (#61)
| Opción | Consecuencia |
|---|---|
| **(a) Se rechaza: en contingencia solo se emite la serie B (recomendada)** | Simétrico con SE-01 y con la regla de contingencia de ADR-51. El mensaje es neutro y no sugiere «No generar comprobante». |
| (b) Se admite, como hoy | Un comprobante E en contingencia quedaría pendiente de un envío que no puede salir. |

*Recomendación a confirmar con el especialista POS y el arquitecto de integraciones al rebasar el #61 (después de la unión).*

## CB-01 · Nivel de compatibilidad mínimo 130 en toda base de GPOS NG (precisión de ADR-54/DM-04, por el #64)
| Opción | Consecuencia |
|---|---|
| **(a) Toda base de GPOS NG (sistema, empresa y sucursal) exige el nivel 130 o más (recomendada)** | Lo exigen `STRING_SPLIT` (R-02) y `OPENJSON`. Una base nueva sube al nivel nativo de la instancia; una existente con menos se rechaza con el `ALTER` para corregirla. Además, B pide que `ComprobadorEsquemaEmpresas` lo vigile para que Diagnóstico lo muestre al SUPER (propuesta de C). |
| (b) Sin mínimo declarado | Una base con un nivel bajo falla con el 208 en plena venta. |

## EM-01 · Remoto privado para el emisor de licencias (`GSF.EmisorLicencias`)
**Contexto:** el repositorio del emisor solo existe en la PC A, que no tiene UPS.

| Opción | Consecuencia |
|---|---|
| **(a) Crear un repositorio privado en GitHub, en la cuenta del propietario, sin secretos (recomendada)** | El código del emisor deja de depender de un solo disco. Las llaves siguen en el TPM y en las YubiKeys, nunca en el repositorio. Lo crea el propietario, o A con su autorización expresa. |
| (b) Respaldo cifrado en OneDrive | Protege el disco, pero sin historia compartida ni revisión. |

## RS-01 · Revocación del anillo con sellos vigentes (observación del auditor sobre el #68)
**Contexto:** `RevocarHeredadasAsync` y `CambiarRecuperacionAsync` no miran el padrón ni los sellos. Un mantenimiento legítimo del anillo podría dejar la instalación fuera, y solo GSF la sacaría de ese estado.

| Opción | Consecuencia |
|---|---|
| **(a) PR aparte de A, detrás del #68, con RS-01 a RS-03, antes del primer mantenimiento real del anillo; hasta entonces, regla operativa: no revocar llaves ni cambiar la recuperación en una instalación con sellos (recomendada)** | El #68 no crece y su revisión sigue valiendo. Unos 0,5 dp. |
| (b) Dentro del #68 | Obliga a repetir la revisión del #68. |

## OR-01 · El #68 en el orden de unión
El #68 (SL-F1, SL-F2, SLF-01, AR-01 y AR-06) está apilado sobre el #67. **Recomendación:** ratificar que va entre el #67 y el #57: #63 → #67 → **#68** → #57 → #58. No cambia nada más del orden firmado el 2026-10-17.

---

**Nota al pie, ensayo de la unión (2026-10-17, noche):** rama local `b/ensayo-27oct` en `GPOS-B-integracion` (`960b7f97` = punta `e80f4654` + `b/prep-27oct` `d67f5a33` + #66 `e5e63f41`), sin conflictos y sin cambios de modelo pendientes. **Suite oficial (Debug, `.SQLEXPRESS`): 3231 correctas, 1 fallida y 28 omitidas.** La fallida es la C-10 intermitente conocida (`CompraVariableTablaTests.C10_…`), que sola pasa 1/1. **Sin fallas atribuibles: la unión está lista.**
