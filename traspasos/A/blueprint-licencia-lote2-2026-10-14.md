# [Blueprint Técnico] Licencia firmada en el lote 2 de RG-14: cierre de AI-01, sello de habilitación, piezas construibles, calendario hasta el corte, ceremonia sin hardware y licencias de pago en nivel Básico

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A.
- **Versión: 2.** Incorpora el dictamen del auditor-seguridad sobre la v1 (`revision-seguridad-blueprint-licencia-lote2-2026-10-14.md`, en adelante **`[SEG]`**), que la v1 recibió como **Rechazado** por SEG-L2-01, SEG-L2-02 y SEG-L2-03. La v1 ya incorporaba las tres precisiones del propietario del 2026-10-14 listadas en «Entradas».
- **Estado del documento:** diseño. Las decisiones nuevas de este documento quedan **Pendientes de firma** (sección 13). Nada de lo que aquí se describe existe en el código, salvo lo que el desarrollador L lleva construido de L1a-1 (sección 14). La hoja de firma la rehace aparte el arquitecto-maestro; la sección 13 solo dice qué tiene que constar en ella.
- **Entradas:**
  - RG-14 firmado el 2026-10-14: D-01 a D-11, D-04 precisada y **L-01** (la licencia firmada de ADR-58 a 66 entra en el lote 2). Fuente: `datos-t3-12-rg14-2026-10-14.md` v2 (`[DAT]`).
  - Decisión del propietario: dos desarrolladores en paralelo, uno para las identidades y otro dedicado a la licencia, hasta el corte de mediados de diciembre de 2026.
  - **Precisiones del propietario del 2026-10-14, recibidas por el coordinador:**
    - **(a)** «montemos todo, que solo sea un tema de utilizar las YubiKeys». **Las YubiKeys todavía no se han comprado.** Se incorpora en las secciones 9 y 10.
    - **(b) Firmada:** precisión de ADR-62 (AP-05). Las licencias **de pago** se pueden firmar en nivel Básico con el TPM mientras no existan las YubiKeys. Al llegar, se hace la ceremonia (AP-01), el paso a Avanzado (AP-05) y la reemisión en Avanzado. El riesgo Medio ya está aceptado por escrito (P-F1, FY-15). Se incorpora en 10.3 y 10.5.
    - **(c) Firmada:** **Q-19 cambia de la opción (a) a una variante de la (b).** El equipo emisor es el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar. No habrá mini-PC por ahora. Se incorpora en 10.6.
  - **`[SEG]`**: SEG-L2-01 a SEG-L2-23, condiciones E-1 a E-15 y condiciones para la hoja de firma (sección 9 de `[SEG]`).
  - Documentos: `[LIC]` = `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` v3.1; `[DLV]` = `docs/decisiones/2026-10-05-decision-licencia-por-vigencia.md`; `[HOJA]` = `docs/decisiones/2026-10-05-hoja-firma-seguridad.md`; `[PSF]` = `docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md` v1.3; ADR-58 a 66, ADR-77 y ADR-81; `CLAUDE.md`.
- **Código leído, solo lectura:**
  - v1: `GPOS-NG-h11b` @ `768f0a61`, que contiene `4d376a6c` (comprobado con `git merge-base --is-ancestor`).
  - v2: la copia de trabajo `GPOS-NG-lic` (rama `a/lic-l1a-1`, cambios **sin confirmar** sobre `ad6015d7`), solo para medir el impacto en L1a-1 (sección 14).
  - No toqué `GPOS-NG-rg14`, `GPOS-NG-lic`, ninguna base ni la instancia. No compilé ni ejecuté pruebas.
- **Etiquetas:** **[V]** verificado en el código con `ruta:línea`; **[I]** inferido. **dp** = días-persona; 1 sp = 5 dp.

---

## Registro de cambios v2 (respuesta a `[SEG]`)

**Criterio:** acepto todo lo que cierra un hueco con un costo proporcional. Ajusto dos remediaciones donde encontré una opción más simple o más completa (SEG-L2-12 y SEG-L2-18). No rechazo ningún hallazgo. Las piezas son las de 4.1; L = desarrollador de la licencia, I = desarrollador de las identidades (reparto DL-07 sin cambios).

| Hallazgo | Sev. | Respuesta | Secciones modificadas | Pieza y costo |
|---|---|---|---|---|
| **SEG-L2-01** | Alta | **Acepta.** El cupo se cuenta con las entradas no SUPER del padrón verificado, cada una con su nivel. El padrón se actualiza por diferencias y solo con acciones de la API. Una fila borrada sigue contando hasta la purga del SUPER (ruta nueva S-04) | 2.2 (SH-1), **2.3**, 2.4, 5.1 (S-04), 5.2, 6.3, 13.1 (DL-01) | SL +0,35 (I): 0,25 de `[SEG]` + 0,1 de S-04 |
| **SEG-L2-02** | Alta | **Acepta. DL-14 nueva:** en un archivo sin firma Avanzada propia, cada `vence` ≤ `emitida` + 200 días; si no, 422 `LICENCIA_VIGENCIA_BASICA` | 0, 5.2, **9.2 (regla 5)**, 10.3, **10.5**, 13.1 (DL-14) | L1a-2 +0,25 (L); EM +0,1 (I); QA +0,1 |
| **SEG-L2-03** | Alta | **Acepta. DL-13 pasa a obligatoria y previa a AI-09.** Vector de R-B13 corregido: un programa con privilegios de administrador que capture el PIN una vez puede firmar en silencio en cualquier momento | 0, **10.5 (R-B13)**, **10.6**, 11.3 (AI-09 pasa a S6-S7), 13.1, 13.2 | Devops +0,25 (E-1 a E-15) |
| SEG-L2-04 | Media | **Acepta.** SH-2 baja a Media: las políticas leen el nivel del *token*. Se anota que el sello no cubre los permisos granulares | **2.2 (SH-2)**, 8 | 0 |
| SEG-L2-05 | Media | **Acepta.** En Release, **ningún modo** (tampoco Amplio) sella ni crea cuentas en la API; con una licencia de `anillo` `Produccion` o `Beta`, la API no arranca en Amplio | **2.2 (SH-3)**, 2.5 (R-S3), **8**, 13.1 (DL-02) | SL +0,25 (I); L1a-4 +0,1 (L); devops +0,25 (instalador del DEMO) |
| SEG-L2-06 | Media | **Acepta. DL-05 pasa a obligatoria:** el sello cubre la huella del `PasswordHash` y, en los SUPER, «factor dado de alta». **Descarto** la variante con `SelloSeguridad` (motivo en 2.2, SH-5) | 2.2 (SH-5), 6.3, 13.1 (DL-05) | SL +0,75 (I): los 0,5 que eran opcionales + 0,25 |
| SEG-L2-07 | Media | **Acepta**, con un orden de escritura que evita que el disco adelante a la base | **2.3** | SL +0,25 (I) |
| SEG-L2-08 | Media | **Acepta.** Compilación reproducible fuera del equipo emisor; la autocomprobación queda como «detección de corrupción accidental»; revisión de código del auditor sobre EM y `GPOS.Criptografia` | 10.3, 10.6 (E-11), 13.1 (DL-07) | Devops +0,5; auditor ≈ 1,0 [I] |
| SEG-L2-09 | Media | **Acepta.** `SolicitudLicenciaDto` lleva `sec`, `lid` y SHA-256 del contenido vigente; el emisor los compara con su registro antes de emitir | 5.2, 9.2 (regla 8), 10.6 (E-14), **14** | L1a-4 +0,15 (L); EM +0,35 (I) |
| SEG-L2-10 | Media | **Acepta.** *Handle* de la llave abierto y cerrado en cada firma; TPM revisado; prueba negativa; AP-03 adaptado | 9.2 (regla 7), 10.6 (E-6, E-7, E-15) | EM +0,1 (I); devops dentro de E |
| SEG-L2-11 | Media | **Acepta.** DL-10 cubre la **pérdida**, no el compromiso; condiciones del segundo equipo. Se agrega la alternativa SEG-L2-23 | 10.5 (INV-3, R-B12), 13.1 (DL-10) | 0 |
| SEG-L2-12 | Media | **Acepta con ajuste.** S-02 y S-03 no se publican hasta unir la fase A de ADR-81. Mientras tanto, legitimar y cambiar el RNC se hace **en el servidor** con dos verbos de `GPOS.Migracion` (el auditor solo nombraba el del RNC; sin el de legitimar no hay forma de recuperar una cuenta) | **5.1 (S-02, S-03)**, 13.1 (DL-03) | RN +0,35 (I) |
| SEG-L2-13 | Media | **Acepta.** DL-12 fija fecha de compra y fecha de revisión de la aceptación (máximo 2027-03-31); al llegar sin ceremonia, la aceptación vence | 10.5 (R-B14), 13.1 (DL-12) | 0 |
| SEG-L2-14 | Baja | **Acepta.** El ancla la envía el propietario desde otro dispositivo; `gsf-firma` sin escritura en carpetas sincronizadas | 10.6 (E-2, E-12) | 0 |
| SEG-L2-15 | Baja | **Acepta.** L-08 solo para el SUPER, con ruta `/api/super/licencia/vigente`. Se documenta que L-03 de un ADMIN afecta a todas las empresas | **5.1 (L-03, L-08)** | L1b +0,1 (L) |
| SEG-L2-16 | Baja | **Acepta.** S-03 (y su verbo provisional) es idempotente; el motor solo da por vigente el cambio cuando el RNC de la empresa es igual a `RncNuevo` | **5.1 (S-03)** | RN +0,15 (I); L1a-3 +0,1 (L) |
| SEG-L2-17 | Baja | **Acepta.** El sello se comprueba antes que la contraseña; si falla, hash ficticio | 2.4, 5.1 | SL +0,1 (I) |
| SEG-L2-18 | Baja | **Ajusta.** Elijo la segunda opción del auditor, ampliada: la identidad de «ya aceptado» es el **SHA-256 del contenido** (el `payload` decodificado). **Rechazo la regla de `s` bajo** como control principal (motivo en 5.2) | **5.2**, 14 | L1a-1 +0,05; L1a-4 +0,1 (L); datos +0,1 |
| SEG-L2-19 | Baja | **Acepta.** El resumen sale de `entradaFirma`; el emisor verifica después de firmar con `VerificadorJws` y el `LlavesGsf.json` publicado; vectores con ceros a la izquierda | 3, 9.2 (regla 6), **14** | EM +0,25 (I); L1a-1 +0,05 (L) |
| SEG-L2-20 | Baja | **Acepta.** Caché global del padrón verificado | 2.3, 2.4 | SL +0,15 (I) |
| SEG-L2-21 | Inf. | Toma nota (Q-21 se mantiene) | 8 | 0 |
| SEG-L2-22 | Inf. | **Acepta** como recomendación de DL-11: cofirma `s1` + `a1` en la reemisión de transición | 9.2 (regla 9), 10.3, 13.1 (DL-11) | +0,25 en EM **después de la ceremonia** (fuera del corte) |
| SEG-L2-23 | Inf. | Se presenta como **alternativa (b) de DL-10** | 10.6, 13.1 (DL-10) | USD ≈ 110 [I] si se elige |

**Efecto en la carga (11.2):** L +0,9 dp (23,4 → 24,3); I +3,15 dp (23,0 → 26,1); otros +2,6 dp (devops +1,0, QA +0,5, auditor ≈ 1,0, datos +0,1). Total de la licencia ≈ 61,7 dp, frente a 55 en la v1. Es más de los «unos 4 dp» de `[SEG]` §8 porque sumo DL-05, que en la v1 estaba fuera del total por ser opcional (0,5), la revisión del auditor (≈ 1,0), S-04 y los verbos provisionales de SEG-L2-12. **Con el recorte 1 anticipado (11.4), cabe también en el peor caso.**

**Cambia L1a-1** (en construcción): sí, en cinco puntos menores de contratos y en los vectores del verificador; **la lógica del verificador no cambia**. Detalle en la sección 14.

---

## 0. Resumen para el propietario

1. **AI-01 queda cerrado en lo documental, con 11 correcciones** (sección 1, sin cambios en la v2). Las tres que importan: no existe ninguna bitácora del sistema (se usa `BitacoraSeguridad` de ADR-81); NV-07 necesita una fila con MAC porque **hoy el ADMIN edita el RNC** [V]; y H-17 v2 (`GPOS.Criptografia`) pasa a ser condición del modo Estricto.
2. **El sello de habilitación queda cerrado frente a un `sysadmin` de SQL** (sección 2), con las precisiones del auditor:
   - **El cupo se cuenta desde el padrón de sellos**, no desde las columnas `Inhabilitado` y `Nivel`. Así no se puede duplicar el cupo ni repitiendo un sello viejo (SH-1) ni cambiando columnas por un rato (SEG-L2-01).
   - **El padrón tiene una copia en el disco** del servidor y prevalece la versión mayor: volver atrás la base ya no restaura las cuentas anteriores a una reducción de cupo (SEG-L2-07).
   - **El sello cubre la contraseña** y, en los SUPER, el estado del segundo factor (DL-05, ahora obligatoria).
   - **En Release, la API nunca crea ni sella cuentas**, en ningún modo (SEG-L2-05).
   - Lo que el sello **no** cubre son los permisos granulares (perfiles y excepciones): frente a un `sysadmin` son el residual de CP-4 (SEG-L2-04).
3. **La licencia queda en 9 piezas** (sección 4). Pueden empezar ya: contratos, `GPOS.Criptografia` con el verificador JWS estricto (en construcción), reglas de aceptación, motor de estados, emisor con la abstracción del proveedor de llave y kit de la ceremonia.
4. **Calendario (sección 11): cabe, con el reparto DL-07 y adelantando el recorte 1** (tablero, CSV de pagos y subida a Drive del emisor pasan a enero; no requiere firma). Cada desarrollador tiene unos 34,4 dp efectivos hasta el 2026-12-15.

   | Reparto | L (licencia, API) | I (identidades) | ¿Cabe? |
   |---|---|---|---|
   | **Propuesto v2, con el recorte 1 anticipado** | ≈ 24,3 dp (+35 %: 32,8) | ≈ 24,1 dp (+35 %: 32,5) | **Sí**: 70 % de la capacidad en el centro, y unos 1,6 a 1,9 dp de margen en el peor caso |
   | Propuesto v2, sin recorte | ≈ 24,3 dp | ≈ 26,1 dp (+35 %: 35,2) | En el centro sí; en el peor caso I se pasa en ≈ 0,8 dp |
   | Literal: toda la licencia en L | ≈ 41 dp | ≈ 6 dp | **No** |

   El riesgo real del calendario sigue **fuera** de los dos desarrolladores: la toma nueva de la ola 3, AI-07, la fase A de ADR-81, QA y frontend.
5. **Ni el corte ni la primera licencia de pago dependen del hardware.** Pero la primera licencia de pago **ya no puede salir en la semana 8**: necesita además la revisión de código del auditor sobre el emisor y `GPOS.Criptografia` (SEG-L2-08), que se hace con el emisor completo. Fecha más temprana: **2026-12-14** [I], si se cumple todo 10.3; si no, en enero.
6. **Riesgo de firmar licencias de pago con `s1` en el TPM del equipo principal** (10.5 y 10.6), con la estimación del auditor:
   - **Medio-Alto** tal como estaba en la v1, y también con DL-13 sola (baja la probabilidad, no el impacto).
   - **Medio**, igual que lo aceptado en FY-15, solo con **DL-13 obligatoria antes de generar `s1`**, **DL-14** (tope de 200 días), emisor reproducible y revisado, comparación de `sec` y `lid`, TPM revisado y caducidad de la aceptación (DL-12).
   - **El vector corregido:** un programa con privilegios de administrador en el equipo que capture el PIN **una vez** puede usar `s1` en cualquier momento, sin abrir la cuenta de firma y sin que el propietario vea ningún resumen. Por eso la cuenta diaria del propietario tiene que pasar a estándar **antes** de generar `s1`.
   - **Dos de las cinco mitigaciones de FY-15 ya no existen** (la caducidad del 2026-12-31 y las vigencias mensuales, que nunca fueron técnicas). El texto adaptado de AP-04 tiene que decirlo.
   - Alternativa barata que baja el riesgo a Bajo-Medio: `s1` en una YubiKey **no FIPS** con toque obligatorio (unos USD 55 cada una [I]), alternativa (b) de DL-10.
7. **Firmas y acciones pendientes del propietario:** sección 13 (DL-01 a DL-14). Ninguna está firmada por este documento. **No generar `s1` (AI-09) hasta cumplir DL-13.**

---

## 1. Cierre de AI-01: CI-1 a CI-5, D-1 y D-2 contra el código y `[DAT]` v2

### 1.1 Confirmación

| Condición | En `[LIC]` v3.1 / `[PSF]` v1.3 | Contraste con el código y `[DAT]` v2 | Resultado |
|---|---|---|---|
| **CI-1 (NV-01)** | 3.3.1, 3.5, 4.1, 4.1.2 | `[DAT]` 6.3 pone el fin de gracia y las marcas de inicio en la fila con MAC `Licencia.Gracias`. La carpeta del disco está mal escrita (C-03) | **Confirmada, con C-03** |
| **CI-2 (NV-02)** | 4.1.1 | La hora de aceptación es `Licencias.RecibidaUtc`, la hora protegida (`[DAT]` 6.3). La hora del cambio de RNC dependía de una bitácora que no existe (C-05) | **Confirmada, con C-05** |
| **CI-3 (NV-04)** | 3.3.1 | `[DAT]` 6.3 confirma `@@SERVERNAME` y `recovery_fork_guid` y no recomienda más datos, pero marca [I] que `gpos_sistema` lea el fork sin ser dueño (PA-47). El código de H-11 ya trata un fork NULL como «restaurada» (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesH11.cs:27`) [V]: es una señal de que el NULL es posible. Plan de reserva en C-07 | **Confirmada, condicionada a PA-47** |
| **CI-4 (NV-05)** | 3.1.1 punto 9, 5.5 | El código ya separa por compilación (`#if DEBUG` para OpenAPI, `src/GPOS.Api/Program.cs:250-253`) [V]. La defensa (c), en la canalización, es de devops | **Confirmada** |
| **CI-5 (NV-06, NV-08, K-LV-01)** | 3.1.1 punto 7, 3.6, 2.3 | `LicenciaLlavesRetiradas.FuenteRef` (`[DAT]` 6.3) cubre CV-08 y NV-08. K-LV-01 no aplica: el módulo de análisis no está en el lote 2 | **Confirmada** |
| **CI-5 (NV-07)** | 3.3, 4.1.1 | **El ADMIN edita hoy el RNC** (`src/GPOS.Core/Servicios/AdministracionService.cs:64`, `:109`) [V]. La prueba de la «ruta del SUPER» no puede ser una fila de bitácora insertable con SQL | **Confirmada en el diseño; requiere C-05 y C-06** |
| **D-1** (INV-3 sobre la acción, ADR-63) | `[LIC]` 3.6 con CW-01; `[PSF]` 4A | Sin agente en el lote 2, los únicos retiros de origen `MANIFIESTO` llegarían con L4 | **Confirmada.** En el lote 2 solo se construyen los orígenes `BINARIOS` y `AUTORIZACIONVENCIDA`; el verificador del manifiesto va con L4 (C-10) |
| **D-2** (piso mayor sin firma Avanzada: se ignora, `PisoHeredado`) | `[LIC]` 3.2, 6.2, L-03; `[PSF]` 4A.4 y 4A.10 | Sin conflicto con el código | **Confirmada** |

### 1.2 Correcciones (precisiones técnicas; ninguna cambia una decisión firmada)

| # | Corrección | Evidencia | Efecto |
|---|---|---|---|
| **C-01** | Las citas de código de `[LIC]` están desfasadas. `UsuariosAutorizados` está hoy en `UsuariosService.cs:219-223` (lectura), `:225` (consumo), `:243-260` (cambio) y `:280-286` (alta al arrancar). Las rutas están en `AdminEndpoints.cs:135` (`GET /api/admin/usuarios/licencia`) y `:275-277` (`GET` y `POST /api/super/licencia`) | [V] | Ninguno funcional. La prueba de arquitectura de LV-17 busca la clave, no las líneas |
| **C-02** | El *pipeline* creció: `UseCambioClaveObligatorio` (`Program.cs:260`), `UseModoEsquemaPendiente` (`:262`), `UseVersionEsquemaEmpresa` (`:264`), `UseModoCandadoRestauracion` (`:266`) y `UseGuardaSitio` (`:268`). **`UseLicencia` va al final, después de `UseGuardaSitio`.** Las respuestas de infraestructura (503 de esquema, candado y sitio) tienen prioridad, y la licencia solo responde 403 cuando la operación se habría permitido. Hay **unas 270 rutas**: 267 `Map*` en `feature/modelo-ng` y 274 en `h11b` [V, conteo con `git grep`], no 205 | [V] | La lista aprobada de clasificación se dimensiona con unas 270 rutas |
| **C-03** | La carpeta del disco es `%ProgramData%\GPOS NG\Licencia\` (ADR-77, punto «ADR-58»), no `%ProgramData%\GPOS\licencia\`. Subcarpetas `Entrada`, `Procesados`, `Rechazados` y `Aceptaciones` (sellos `.acept`), y archivos `vigente.gposlic`, `secmax`, `estado` y `pisonivel`. **Cada carpeta se crea con su DACL protegida en una sola operación** (ADR-77, B-3) | `docs/adr/ADR-077.md:16`, `:37`, `:42-43` [V] | Pieza L1a-4 |
| **C-04** | `IRelojProtegido.Ahora()` devuelve `DateTime` UTC, no `DateTimeOffset` como dice `[LIC]` 8.5. Además, H-16 no expone cómo recibir una hora confiable: el propio código dice que la corroboración llega «con el agente de actualización y la licencia» | `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs:17`, `:58-60` [V] | Contrato nuevo `ICorroboracionHora` (6.2), en L1b |
| **C-05** | **No existe ninguna bitácora del sistema en el código.** No hay `BitacoraSistema` (ADR-37, que llega con la versión 1 del acceso multiempresa) ni `BitacoraSeguridad` (ADR-81, firmado el 2026-10-09, sin construir); solo `dbo.DispositivosBitacora` (`EsquemaSistema.cs:172`). Propongo que los eventos de la licencia y del sello vayan a **`dbo.BitacoraSeguridad`** de ADR-81 (`GPOS_SYSDATA`, solo inserción, retención de 2 años). La crea quien llegue primero, la licencia o ADR-81, con la DDL que fije el arquitecto de datos; cuando exista `BitacoraSistema`, se decide si se unen | `git grep` en `src` de `master` y de `h11b` [V]; `master:docs/adr/ADR-081.md` puntos 5 y 12 [V] | Decisión **DL-04** (sección 13). 0,5 dp |
| **C-06** | **NV-07 robusto.** La prueba de que el SUPER cambió el RNC es una **fila con MAC** `Licencia.CambiosRnc` (por empresa: RNC anterior, RNC nuevo, hora protegida y usuario), además del evento de bitácora. Un `sysadmin` puede insertar una fila de bitácora, pero no rehacer un MAC sin el anillo. El RNC sale de la configuración del ADMIN (`AdministracionService` rechaza un cambio de RNC con 409 `RNC_SOLO_SUPER`) y pasa a la ruta S-03. **Cambia lo que ve el ADMIN** | `AdministracionService.cs:64`, `:109` [V] | Decisión **DL-03**. 0,75 dp |
| **C-07** | **Huella (CI-3), plan de reserva.** Si PA-47 da NULL para `gpos_sistema`, los dos componentes se leen con un procedimiento `dbo.usp_LeerHuellaEntorno WITH EXECUTE AS OWNER` (S1 de `[DAT]`), con `GRANT EXECUTE` a `gpos_api`. Si tampoco funciona, rige la regla NV-04 de lectura fallida (se conserva la última huella). PA-47 se puede probar **hoy** (15 minutos) | `SqlMigracionesH11.cs:27` [V]; `[DAT]` 6.3 [I] | Entrega al arquitecto de datos |
| **C-08** | **El `InstalacionId` solo lo genera `GPOS.Migracion sistema` en Estricto** (`[DAT]` 6.3). En Amplio (desarrollo, pruebas y DEMO) lo genera la API al arrancar si falta, como dice `[LIC]` 2.2. En Estricto, sin el identificador, la API no arranca: «Ejecute GPOS.Migracion sistema» | `Inicializacion.cs:17-19` [V]: hoy la API hace `EnsureCreated` | L1a-4 |
| **C-09** | **Reutilizar las marcas de clase.** Ya existe la marca `SoloConsulta` de los POST que solo leen, la del candado de restauración, con su lista vigilada por PF-36 (`ModoCandadoRestauracion.cs:11-14`) [V]. La licencia la acepta como clase `Consulta`, así que hay **una sola lista** de POST de lectura. Además, la regla LV-16 («ningún `GET` escribe») tiene que admitir las escrituras de auditoría que PF-36 ya lista, como la copia de impresión (PC-4, `ModoCandadoRestauracion.cs:34-36`) [V]; si no, la prueba de LV-16 falla con el código actual | [V] | L1b; ahorra unos 0,5 dp |
| **C-10** | **Alcance de los retiros en el lote 2:** solo los orígenes `BINARIOS` y `AUTORIZACIONVENCIDA`. `VerificadorManifiesto`, el origen `MANIFIESTO` y la cofirma de D-1 van con L4, porque sin agente no hay manifiesto que guardar. El verificador JWS de `GPOS.Criptografia` sí es común desde ya (ADR-77, R-1, condición 1) | `docs/adr/ADR-077.md:75-76` [V] | Ahorra unos 1,5 dp en el lote 2 [I] |
| **C-11** | **La DDL de la licencia va en una constante compartida** `SqlLicenciaSistema` (`GPOS.Core/Data/Sistema/`). La aplican `EsquemaSistema` en Amplio y `GPOS.Migracion sistema` en Estricto. Los permisos (`DENY` de S1) los aplica solo `GPOS.Migracion`. Así se evita que los dos desarrolladores editen el mismo archivo | `Inicializacion.cs:19` [V]; `[DAT]` 6.3 | Reparto de 4.3 |

**Conclusión:** **AI-01 queda Completado** en lo documental. C-01 a C-11 se aplican al construir, y las que cambian algo visible o un criterio de seguridad van a firma (DL-01 a DL-05).

---

## 2. Revisión del sello de habilitación (`[DAT]` 6.3)

### 2.1 Lo que el diseño de datos resuelve bien

- El sello es `Protect` del anillo con su propio propósito (`GPOS.Usuarios.Sello.v1`). Lleva el `InstalacionId` y el código, así que no sirve en otra cuenta ni en otra instalación.
- Un `sysadmin` sin el anillo no lo fabrica. El anillo está en el equipo de la API, protegido con DPAPI hoy y con H-17 v2 después.
- Contar solo a los habilitados con un sello válido impide ampliar el cupo insertando filas, y cubre también a los SUPER.
- El costo es bajo: un `Unprotect` cuesta unos microsegundos [I].

### 2.2 Huecos encontrados

| # | Hueco | Evidencia | Severidad | Tratamiento |
|---|---|---|---|---|
| **SH-1** | **Repetición del sello.** El sello de una cuenta habilitada sigue valiendo para siempre. Con SQL: se copia el sello de A, se inhabilita A por la API (libera el cupo), se da de alta B (sellada), y se restauran el sello copiado de A con `Inhabilitado = 0`. Resultado: A y B habilitadas y **el cupo duplicado**. **Variante (v2, SEG-L2-01):** sin tocar el sello, se cambia por un rato la columna `Inhabilitado` o `Nivel` de A, se da de alta B dentro del cupo aparente y se devuelve la columna; o se borra la fila de A y se reinserta | `[DAT]` 6.3: el sello no tiene generación ni lista de vigentes. El cupo actual cuenta por columnas: `UsuariosService.cs:154`, `:163-172`, `:225` [V, `768f0a61`] | **Alta**: anula el propósito firmado de 6.3 | **Padrón de sellos con MAC como fuente del cupo** (2.3). Decisión **DL-01**, con las precisiones (a) y (b) de `[SEG]` |
| **SH-2** | **El sello no se verifica en cada petición.** `RevocacionSesiones` vuelve a leer el nivel y la habilitación de la base cada 15 s, pero **solo revoca cuando el nivel del token supera al de la cuenta**, y las políticas «admin» y «super» leen el nivel del *claim* del token, no de la base. Por eso un `UPDATE Nivel = 'ADMIN'` por SQL **no** eleva la sesión abierta: surte efecto en el siguiente inicio de sesión, donde el sello lo detiene. Lo que sí queda sin cubrir es una cuenta cuyo sello deja de valer mientras tiene la sesión abierta (por ejemplo, la restaurada de SH-1). **Lo que el sello no cubre:** los permisos granulares (perfiles y excepciones), que se leen de la base en cada petición (caché de 30 s) y cambian por SQL sin token nuevo | `src/GPOS.Api/Program.cs:91-92`; `src/GPOS.Api/Seguridad/Seguridad.cs:158`, `:177-179`; `RevocacionSesiones.cs:50`, `:81-89` (`:86`); `PermisosServidor.cs:10-26`; `UsuariosService.cs:322-327` [V, citado por `[SEG]` SEG-L2-04] | **Media** (v1 decía Alta; corregida con la razón del auditor) | `EstadoSesionUsuario` lleva el resultado del sello. Un sello que no verifica da 401 `credenciales` (el mismo valor de R-3). Se calcula con la misma lectura y la misma caché de 15 s. **El sello protege el cupo, el nivel, la sucursal, la contraseña (DL-05) y el estado del factor del SUPER; no protege los permisos granulares**, que frente a un `sysadmin` son el residual de CP-4. *Descartado:* sellar los permisos (cada cambio de perfil obligaría a volver a sellar a todos sus usuarios, sin beneficio para la licencia). Se anota en el modelo de amenazas de `[DAT]` 6.2 (entrega al arquitecto de datos) |
| **SH-3** | **La API crea cuentas privilegiadas sin sello previo.** `AsegurarSuperUsuarioAsync` crea `GSF` si no hay ningún SUPER, y `AsegurarAdministradorAsync` crea `ADMIN` si no hay ningún usuario. Borrar los SUPER por SQL y reiniciar **fabrica un SUPER**, que la API sellaría | `UsuariosService.cs:266-287`, `:421-433`; `Inicializacion.cs:32-33`, `:122-129` [V] | **Alta** (frente a la meta «no se puede crear un SUPER por SQL») | **v2 (SEG-L2-05): en una compilación Release, ningún modo, tampoco Amplio, crea ni sella cuentas en la API.** Las cuentas iniciales y el sellado inicial los hace solo `GPOS.Migracion sistema --cuentas-iniciales`, la primera vez y antes de `Licencia.SelloInicial`; el DEMO, que se compila en Release, lo hace desde su instalador. La creación y el sellado al arrancar quedan solo en `Debug` (`#if DEBUG`, como T3-09). Además, con una licencia vigente de `anillo` `Produccion` o `Beta`, **la API no arranca en Amplio** (evento crítico `ArranqueAmplioBloqueado`). Decisión **DL-02** |
| **SH-4** | **El autorizante de supervisor no pasa por el sello.** `ValidarAutorizanteAsync` valida a un ADMIN insertado a mano | `UsuariosService.cs:79-89` [V] | Media | Exigir un sello válido. Sin sello, el mismo tratamiento que una cuenta inexistente: hash ficticio y sin oráculo de tiempo (O-2) |
| **SH-5** | **Se puede tomar una cuenta sellada.** El sello no cubre el hash de la contraseña. Un `sysadmin` cambia el `PasswordHash` del SUPER por uno conocido y entra como SUPER. Con ADR-81 sin construir, o con la fila del factor borrada, quien entra da de alta su propio factor (`[SEG]` SEG-L2-06) | `[DAT]` 6.3 (contenido del sello); `UsuariosService.cs:48`; `ADR-081.md:30`, `:59` [V, citado por `[SEG]`] | Media | **DL-05, obligatoria en la v2:** el sello incluye el SHA-256 del `PasswordHash` y, en los SUPER, `FactorAlta` (sí/no). Se vuelve a sellar al cambiar o restablecer la contraseña, al rehacer el hash al entrar (`UsuariosService.cs:48`) y al dar de alta o de baja el factor (ADR-81). Un SUPER con `FactorAlta = sí` cuya fila de factor desaparece no entra; se restablece solo por la vía (a) o (b) de ADR-81, punto 7. **Descartado:** usar el `SelloSeguridad` de CS-1 en lugar del hash (lo sugería SH-8 de la v1): un `sysadmin` cambia el `PasswordHash` sin tocar el `SelloSeguridad`, y el sello seguiría coincidiendo |
| **SH-6** | **Legitimar una cuenta por la vía equivocada.** Si cualquier `GuardarAsync` vuelve a sellar, un ADMIN que edite una cuenta insertada a mano la legitima | `UsuariosService.cs:131-214` [V] | Media | Sobre una cuenta sin sello válido, `GuardarAsync` responde 409 `USUARIO_SIN_SELLO`. Solo el SUPER la legitima: con la ruta S-02 cuando exista la fase A de ADR-81, y mientras tanto con `GPOS.Migracion sellos --legitimar` en el servidor (5.1) |
| **SH-7** | **Ejecutar de nuevo el sellado inicial.** Si un `sysadmin` borra la fila `Licencia.SelloInicial` y GSF vuelve a ejecutar `sistema`, se sellarían las cuentas insertadas | `[DAT]` 6.3, R-RG14-12 | Baja | `sistema` solo sella si no hay **ninguna** licencia aceptada en `Licencias` ni en `Procesados`, y si el padrón no existe ni en la base ni en el disco (2.3). Muestra la lista de cuentas y pide `--confirmar-sellado` con motivo, y deja el evento en la bitácora |
| **SH-8** | **Confusión de nombres** con el «sello de seguridad» de CS-1 e IDN-04, que es el valor aleatorio que se renueva al cambiar la credencial (`RevocacionSesiones.cs:44`) [V] | — | Baja | Nombres distintos en el código: `SelloHabilitacion` (MAC) frente a `SelloSeguridad` (aleatorio). *(v2: ya no se propone usar el `SelloSeguridad` dentro del sello; ver SH-5)* |

### 2.3 Padrón de sellos (DL-01, v2)

- **Fila con MAC** `Licencia.PadronSellos` en `dbo.Configuracion`. `Valor` es `nvarchar(max)` (`EsquemaSistema.cs:102`) [V].
- **Contenido:** `Protect("GPOS.Usuarios.Padron.v1", { InstalacionId, Version, Entradas: { Codigo → { Huella: SHA-256(sello)[0..12], Nivel } } })`. **El nivel va en cada entrada** (SEG-L2-01).
- **El padrón es la fuente del cupo (SEG-L2-01):** el consumo de usuarios es el **número de entradas con `Nivel` distinto de SUPER del padrón vigente**. Las columnas `Inhabilitado` y `Nivel` de la fila **no intervienen** en el conteo.
- **Se actualiza solo por diferencias y solo con acciones de la API** (o de los verbos de `GPOS.Migracion` de 5.1), en la **misma transacción serializable** de la acción. `Version` sube de uno en uno.

  | Acción | Cambio en el padrón |
  |---|---|
  | Alta y rehabilitación | Agrega la entrada (con control del cupo en la misma transacción) |
  | Cambio de nivel, de sucursal o de contraseña; alta o baja del factor (DL-05) | Reemplaza la huella (y el nivel) de la entrada |
  | Inhabilitación | Retira la entrada |
  | Legitimación (S-02 o `sellos --legitimar`) | Agrega la entrada, con control del cupo |
  | **Purga (S-04, nueva)** | Retira la entrada de una cuenta **cuya fila ya no existe**, con motivo y segundo factor del SUPER |

  **Nunca se reconstruye a partir de las filas**: ningún proceso recorre la tabla de usuarios para regenerarlo. Solo `sellos --resellar` (R-S1) crea un padrón nuevo, con acta.
- **Una cuenta entra** solo si se cumplen las tres condiciones: (1) el sello verifica; (2) los campos del sello coinciden con la fila; (3) el padrón contiene `Codigo` con la huella de ese sello **y el mismo nivel**.
- **Casos de manipulación por SQL (resultado esperado):**

  | Manipulación | Resultado |
  |---|---|
  | Cambiar por un rato `Inhabilitado` o `Nivel` de una cuenta sellada | Sigue contando (su entrada está en el padrón); mientras las columnas no coincidan, no entra (`CamposNoCoinciden`) |
  | Borrar la fila | Su entrada sigue contando (`FilaAusente`) hasta la purga S-04 |
  | Borrar y reinsertar la fila con el sello viejo | Si coincide con la entrada, es la misma cuenta: no duplica. Si no, no entra |
  | Restaurar el sello de una cuenta inhabilitada (SH-1) | No está en el padrón: no entra ni cuenta (`FueraDePadron`) |
  | Insertar una cuenta nueva | No está en el padrón: no entra ni cuenta |

- **Reducción del cupo:** no toca el padrón. Si el consumo supera el cupo nuevo, rige ADR-58, punto 9: `EnExceso`, nadie pierde la sesión y no se admiten altas ni rehabilitaciones hasta bajar del cupo.
- **Copia en el disco (SEG-L2-07):** archivo `padron` en `%ProgramData%\GPOS NG\Licencia\` (carpeta de C-03, con DACL protegida), con el mismo contenido protegido.
  - **Orden de escritura:** primero se confirma la transacción y después se escribe el archivo por reemplazo atómico (temporal y `File.Replace`). Si el proceso cae entre los dos pasos, la base queda con una versión mayor que el disco y la API reescribe el disco al leer. **Nunca** se escribe el disco antes de confirmar: el disco no puede adelantar a la base con un estado que no se confirmó.
  - **Lectura:** **prevalece la mayor `Version` que verifique**, sea la de la base o la del disco. Si la del disco es mayor, se usa la del disco, se vuelve a escribir en la base, se registra `PadronRetrocedido` y se avisa al SUPER. Si falta el archivo, se reescribe desde la base y se registra el evento.
  - Un `sysadmin` de SQL sin acceso al sistema de archivos del servidor de la API ya no puede volver atrás. Un administrador de Windows sí puede retroceder las dos copias: es el residual de CP-4 (R-S2).
- **Caché global (SEG-L2-20):** la API guarda en memoria un único padrón verificado. Cada 15 s, como máximo, relee la fila y compara el SHA-256 del valor protegido con el de la caché; solo hace `Unprotect` si cambió. El sello de cada usuario se sigue verificando con la lectura de su sesión.
- **Tamaño:** con 1 000 cuentas, unos 55 KB en claro y unos 85 KB en Base64 [I]. Solo se escribe al administrar usuarios y, rara vez, al rehacer el hash de una contraseña al entrar; nunca al vender.
- **Alternativas descartadas:**
  - limitar el inicio de sesión a las N cuentas más antiguas cuando hay exceso de cupo: choca con ADR-58, punto 9, y permite turnar cuentas;
  - guardar las revocaciones en la bitácora: un `sysadmin` borra filas de bitácora;
  - **reconstruir el padrón a partir de las filas** o contar el cupo por columnas: es lo que permite la variante de SEG-L2-01.

### 2.4 Puntos de verificación (dónde se comprueba el sello)

| Punto | Qué comprueba | Código actual |
|---|---|---|
| Inicio de sesión | **Primero** el sello, el padrón y los campos; **después** la contraseña (SEG-L2-17). Si el sello no verifica, se verifica un hash ficticio (mismo costo, como `ValidarAutorizanteAsync`, `UsuariosService.cs:83-86` [V]) y se da el error genérico idéntico al de una contraseña incorrecta, **sin** contar el intento, con el evento `USUARIO_SIN_SELLO` y la alerta. Sin oráculo por tiempo ni por contador | `UsuariosService.ValidarAsync` (`:27-54`) |
| Cada petición, con caché de 15 s | Sello y campos contra el padrón de la caché global: 401 `credenciales` | `RevocacionSesiones.Evaluar` (`:81-89`); `EstadoSesionAsync` (`:322-327`) |
| Autorizante de supervisor (ADR-68) | Lo mismo; sin oráculo de tiempo | `ValidarAutorizanteAsync` (`:79-89`) |
| Cupo | **Entradas no SUPER del padrón vigente** (2.3), dentro de la transacción serializable que ya existe | `UsuariosService.cs:140`, `:154`, `:162-172` (hoy por columnas) |
| Instantánea de la licencia (cada 60 s) | Consumo por empresa desde el padrón; lista de cuentas sin sello, fuera del padrón y de entradas sin fila (`FilaAusente`) para el SUPER | Nuevo |
| `GPOS.Migracion verificar` | Cuentas habilitadas sin sello, entradas sin fila, padrón que no verifica y diferencia de versión entre la base y el disco, con la condición `CUENTA_SIN_SELLO` | Agregar a S4 de `[DAT]` |

**Costo de verificar:** con 1 000 cuentas, unos 10 a 30 ms en la instantánea y en el alta [I]; 1 `Unprotect` del sello por usuario cada 15 s y 1 `Unprotect` del padrón solo cuando cambia. Lo mide QA.

### 2.5 Riesgos del sello

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-S1 | Se pierde o se cambia el anillo (falla de H-17 o del TPM): ningún sello verifica y nadie entra | Baja / Alto | H-17 v2, puntos 3 y 5: recuperación anclada y `recuperar-anillo`. Verbo `GPOS.Migracion sellos --resellar --motivo` con acta (R-RG14-13 de `[DAT]`) |
| R-S2 | Un administrador de Windows con `sysadmin` rehace sellos y padrón, o retrocede la base y el disco a la vez | Media / Medio | No se impide: se detecta. Es el residual de CP-4 (AP-04) y la regla (iii) |
| R-S3 | En las instalaciones de desarrollo y DEMO hay cuentas sin sello al pasar a la versión nueva | Alta / Bajo | **v2:** en `Debug`, la API sella al arrancar si falta `Licencia.SelloInicial`. En Release (DEMO incluido) **nunca**: el instalador del DEMO ejecuta `GPOS.Migracion sistema --cuentas-iniciales` y el sellado inicial (devops) |
| R-S4 | Conflictos de edición entre los dos desarrolladores en `UsuariosService` | Media / Medio | El sello lo construye **un solo** desarrollador, el de identidades (4.3). La licencia solo expone `IEstadoLicencia.CupoUsuarios`. El archivo `padron` del disco lo escribe `PadronSellos` (I) en la carpeta que crea `AlmacenLicenciaDisco` (L) |
| R-S5 | La fase A de ADR-81 no llega antes del corte: S-02, S-03 y S-04 no se publican | Media / Bajo | Verbos de `GPOS.Migracion` en el servidor (5.1). Lo pierde solo la comodidad del SUPER |

---

## 3. Módulos y dependencias

| Módulo | Responsabilidad | Depende de |
|---|---|---|
| `GPOS.Contracts/Licencia` | `FormatoLicencia` (compartido con el emisor), DTO y `CodigosLicencia` | — |
| `GPOS.Criptografia` (proyecto nuevo, excepción H-17 v2) | `VerificadorJws` estricto (serialización general, ES256, P1363), `RecursoLlavesGsf` (recurso incrustado con la huella fija), `CifradorAnillo` (H-17 v2). **Sin dependencias de negocio** | Biblioteca base de .NET |
| `GPOS.Core/Sistema/Licencia` | Reglas de aceptación (INV-1 a INV-11), motor de estados puro, `EstadoLicenciaService`, repositorio, almacén de disco, huella, solicitud e importador de la carpeta de entrada | `GPOS.Contracts`, `GPOS.Criptografia`, `IRelojProtegido`, Data Protection, `IBitacoraSeguridad` |
| `GPOS.Core/Sistema/Usuarios` (sello) | `SellosHabilitacion` y `PadronSellos`; el cupo lo pide a `IEstadoLicencia` | Data Protection, `IEstadoLicencia` |
| `GPOS.Core` numeración (heredada y del modelo nuevo) | Segunda barrera: `IEstadoLicencia.ExigirOperativa` | `IEstadoLicencia` |
| `GPOS.Api/Seguridad/ModoLicencia.cs` | *Middleware*, marca `ClaseLicencia` y encabezado `X-GPOS-Licencia` | `IEstadoLicencia` |
| `GPOS.Api/Endpoints/LicenciaEndpoints.cs` | Rutas L-01 a L-09 y S-01 a S-04 (v2) | `GPOS.Core` |
| `GPOS.Migracion` | `sistema` (DDL y permisos), `--cuentas-iniciales`, sellado inicial, `sellos --resellar`, `recuperar-anillo` | `GPOS.Core`, `GPOS.Criptografia` |
| `GSF.EmisorLicencias` (repositorio privado aparte) | Emitir, firmar a través de `IProveedorLlaveFirma`, registrar, comparar la solicitud con el registro (SEG-L2-09), verificar después de firmar (SEG-L2-19) y ceremonia | `FormatoLicencia` (archivo enlazado) y el ensamblado `GPOS.Criptografia` (solo el verificador, v2). **No** referencia `GPOS.Core` |

**Sin ciclos:** `Contracts` y `Criptografia` ← `Core` ← (`Api`, `Migracion`). `GPOS.Criptografia` no referencia a `GPOS.Contracts`: el verificador devuelve los bytes del contenido y los `kid` verificados, y `Core` interpreta `FormatoLicencia`.

**C4 (contexto y contenedores):** los de `[LIC]` 8.2 y 8.3 siguen vigentes, con dos cambios:
- la carpeta es la de C-03;
- el emisor tiene tres proveedores de llave (sección 9).

---

## 4. Piezas construibles

### 4.1 Lista, orden y dependencias

Los añadidos de la v2 van marcados con **(v2)** y el hallazgo de `[SEG]` que los origina.

| Pieza | Contenido | Depende de | ¿Puede empezar ya? | dp |
|---|---|---|---|---|
| **L1a-1 Contratos y verificador** | Los DTO y códigos de 5.2; el proyecto `GPOS.Criptografia` (PR pequeño, unido **en los primeros 3 días** porque H-17 v2 se monta encima); `VerificadorJws` con 3.1.1 puntos 1 a 6 y 9; `RecursoLlavesGsf` (en las pruebas solo la llave de software; la de desarrollo solo en `Debug`); vectores negativos. **(v2)** Cambios de contratos de la sección 14; vectores de firma maleada y de `r`/`s` con ceros a la izquierda (SEG-L2-18, SEG-L2-19); fábrica pública de `ConjuntoLlaves` desde los bytes de `LlavesGsf.json` para el emisor | — | **Sí** (en construcción) | 4,1 |
| **L1a-2 Reglas de aceptación** | INV-1 a INV-11, `nivel` y piso con D-2, `autNivel` con `instalaciones` (Q-17), CW-02, NV-05, NV-06 y techo de 48 h, todo como funciones puras sobre (archivo, licencia vigente, recurso de llaves, hora de referencia). **(v2)** **DL-14:** tope de vigencia de los archivos sin firma Avanzada propia (9.2, regla 5, y 10.5) | L1a-1 | **Sí** | 4,25 |
| **L1a-3 Motor de estados** | Estados y motivos de gracia, NV-01, NV-02, NV-07 (con la fila MAC de C-06 como dato de entrada), NV-08, ilegible, entorno y transición. **Puro**, probado con fechas fijas. **(v2)** NV-07 solo da por vigente un cambio de RNC cuando el RNC de la empresa es igual a `RncNuevo` (SEG-L2-16) | L1a-1 | **Sí** | 2,5 |
| **L1a-4 Persistencia y arranque** | `SqlLicenciaSistema` (C-11), repositorio, almacén de disco con DACL (C-03), arranque con la mayor `sec` (LV-21), sellos `.acept` (INV-7), `sec` máxima efectiva, filas con MAC, refresco de 60 s, importador (20 por hora), huella (C-07), `InstalacionId` (C-08), solicitud L-06, carga manual L-03 de punta a punta en Amplio. **(v2)** «Ya aceptado» por SHA-256 del contenido (SEG-L2-18); `sec`, `lid` y SHA-256 vigentes en la solicitud (SEG-L2-09); la API no arranca en Amplio con una licencia `Produccion` o `Beta` (SEG-L2-05) | L1a-2 y L1a-3. DDL de `[DAT]` 6.3. `IBitacoraSeguridad` (C-05) | Sí, con Amplio | 2,85 |
| **L1b Aplicación** | `UseLicencia` al final del *pipeline* (C-02); clasificación de unas 270 rutas con la lista aprobada; reutilizar `SoloConsulta` (C-09); segunda barrera en la toma; L-01 a L-09; encabezado; avisos y correo; excepciones legales; prueba de arquitectura «sin interruptores» (QA-L06 y QA-L17 sobre Release); H-16 con `ICorroboracionHora` alimentada por `emitida`; `IEstadoLicencia.CupoUsuarios` hacia el sello; retiro de `UsuariosAutorizados` (LV-17). **(v2)** L-08 solo para el SUPER (SEG-L2-15) | L1a-4. **Toma nueva unida** (ola 3, H-04). **AI-07** antes de clasificar. Ramas de las olas unidas | **No**: desde el 2026-11-16 | 9,6 |
| **SL Sello y padrón** | Secciones 2.3 y 2.4; SH-2 a SH-4, SH-6 y SH-7; rutas S-01, S-02 y S-04; `--cuentas-iniciales` y sellado inicial. **(v2)** Cupo desde el padrón, padrón por diferencias con el nivel en cada entrada (SEG-L2-01, +0,25); S-04 y `sellos --purgar` (+0,1); sin creación ni sellado en Release (SEG-L2-05, +0,25); **DL-05 obligatoria** con `FactorAlta` (SEG-L2-06, +0,75); copia en disco (SEG-L2-07, +0,25); orden sello→contraseña (SEG-L2-17, +0,1); caché global (SEG-L2-20, +0,15) | `IEstadoLicencia` (la interfaz basta, con un sustituto que lee el cupo heredado hasta L1b). S1 de `[DAT]`. H-17 v2 para el sellado desde `GPOS.Migracion` en Estricto. Carpeta de C-03 (L1a-4; un sustituto hasta entonces) | Sí, en Amplio | 4,35 |
| **CR H-17 v2** | `CifradorAnillo` en `GPOS.Criptografia`, recuperación anclada (D-3), decorador CV-05, `recuperar-anillo` y migración desde DPAPI | Proyecto creado en L1a-1; certificados de devops | Sí, cuando exista el proyecto | 2,2 |
| **RN Cambio de RNC** | S-03, fila con MAC `Licencia.CambiosRnc`, 409 en la configuración del ADMIN (C-06). **(v2)** Verbos provisionales `GPOS.Migracion empresa --cambiar-rnc` y `sellos --legitimar` mientras no esté la fase A de ADR-81 (SEG-L2-12, +0,35); S-03 y el verbo idempotentes, con prueba de fallo inyectado (SEG-L2-16, +0,15) | DL-03 firmada; `IBitacoraSeguridad`; H-17 v2 para los verbos en Estricto | Diseño sí; código tras la firma | 1,25 |
| **EM Emisor y kit de la ceremonia** | `GSF.EmisorLicencias` con `IProveedorLlaveFirma` (TPM, YubiKey y software), registro con cadena de hashes, NTP en dos fuentes, resumen y SHA-256 antes de firmar, conversión DER a P1363, catálogo, CSV de pagos, tablero mínimo y subida manual a Drive; guion, scripts, modo de ensayo y lista de aceptación (secciones 9 y 10). **(v2)** Tope de vigencia Básica (DL-14, +0,1); comparación de la solicitud con el registro (SEG-L2-09, +0,35); *handle* por firma (SEG-L2-10, +0,1); resumen desde `entradaFirma` y verificación posterior (SEG-L2-19, +0,25) | `FormatoLicencia` (L1a-1, día 2) y `GPOS.Criptografia` (verificador). `s1` en el TPM de la cuenta dedicada (AI-09, 10.6) solo para la primera licencia real; antes, el proveedor de software | **Sí** (otro repositorio, sin conflictos) | 11,3 (9,3 con el recorte 1 anticipado, 11.4) |
| L4 Agente | Renovación, detector, reversión, manifiesto con D-1 | El agente (propuesta formal pendiente) | No: después del corte | 2,8 (integraciones) |

**Orden:**

```
L1a-1 → (L1a-2 ‖ L1a-3) → L1a-4 → L1b ──────────────┐
   └→ CR (H-17 v2) → SL (Estricto) ─────────────────┤→ PA-12 con licencia (criterio de salida)
EM (en paralelo, desde el día 2) ───────────────────┤
S0/S1 de RG-14 + `sistema` → SL, L1a-4 (Estricto) ──┘
```

### 4.2 Dependencias con las identidades del lote 2

| La licencia necesita | De | Cuándo |
|---|---|---|
| `GPOS.Migracion sistema` con S1 y la llamada a `SqlLicenciaSistema` | Desarrollador de identidades | Antes del 2026-11-13, para L1a-4 en Estricto (en Amplio no hace falta) |
| `gpos_sistema` sin DDL; `DENY UPDATE, DELETE` sobre `Licencias` | S1 de `[DAT]` | Para PA-41 |
| H-17 v2: anillo común entre la API, que corre con `NT SERVICE\GPOS.Api`, y `GPOS.Migracion`, que ejecuta el técnico | CR | **Antes de usar Estricto en cualquier entorno.** También lo necesita `credencial-app` de RG-14 (`[DAT]` S2, paso 4) |
| PA-47, la lectura del fork como `gpos_sistema` | Desarrollador de identidades o QA | Semana 1 |

### 4.3 Reparto entre los dos desarrolladores (para evitar conflictos de edición)

| Archivo o zona | Dueño |
|---|---|
| `GPOS.Contracts/Licencia`, `GPOS.Core/Sistema/Licencia`, `ModoLicencia.cs`, `LicenciaEndpoints.cs`, `SqlLicenciaSistema.cs` y `GPOS.Criptografia/Jws` | Desarrollador de la licencia (**L**) |
| `UsuariosService`, `RevocacionSesiones`, `Inicializacion`, `GPOS.Migracion`, `GPOS.Criptografia/Anillo`, `AdministracionService` (RNC) y el repositorio del emisor | Desarrollador de las identidades (**I**) |
| `Program.cs` y `GPOS-NG.slnx` | L los toca una sola vez en L1a-1 y otra en L1b; I, en CR. Se unen por separado |

Cada desarrollador trabaja en **su propia copia de trabajo y su rama** (un solo editor por árbol), por ejemplo `a/licencia-l1` y `a/rg14-lote2`. Ninguno toca `GPOS-NG-rg14` mientras lo edite el otro agente.

---

## 5. Contratos de la API interna

### 5.1 Rutas

Todas responden con `ProblemDetails` y `codigo`. La empresa sale del token, salvo en las rutas del SUPER con `{empresa}` o `{codigo}`. Las de `[LIC]` 8.4 siguen tal cual, con las precisiones marcadas.

| # | Ruta | Método | Entrada → salida | Validaciones | Errores | Permiso y clase | Aislamiento |
|---|---|---|---|---|---|---|---|
| L-01 | `/api/licencia/estado` | GET | → `EstadoLicenciaDto` | — | 401 | Autenticado. `Consulta` | Empresa del token; al USER, solo `opera`/`soloConsulta` y la franja |
| L-02 | `/api/admin/licencia` | GET | → `LicenciaEmpresaDto` | — | 401, 403 | ADMIN o SUPER. `Consulta` | Empresa del token. **Sustituye** `GET /api/admin/usuarios/licencia` (`AdminEndpoints.cs:135`) en el mismo PR; el único cliente es la Web (`ApiClient.Modulos.cs`) [V] |
| L-03 | `/api/admin/licencia/archivo` | POST multipart | `.gposlic` → `ResultadoCargaLicenciaDto` | Orden de `[LIC]` 6.2 y 3.1.1, más DL-14 (9.2, regla 5) | Los de `[LIC]` L-03 (413, 400, 409 y 422), más 422 `LICENCIA_VIGENCIA_BASICA` | ADMIN o SUPER. `Esencial`. 10 por hora por cuenta | La respuesta muestra solo la empresa del token. **(v2, SEG-L2-15)** La licencia es de instalación: **el archivo que carga un ADMIN afecta a todas las empresas de la instalación**. Es aceptable porque solo se aceptan archivos firmados por GSF; el evento de la bitácora registra todas las empresas afectadas |
| L-04 | `/api/super/licencia` | GET | → `LicenciaInstalacionDto` | — | 401, 403 | SUPER. `Consulta` | Instalación. **Misma ruta que hoy, con otro DTO** (`AdminEndpoints.cs:275`) |
| L-05 | `/api/super/licencia/historial` | GET | `?desde&hasta` → `CargaLicenciaDto[]` | Rango de 2 años como máximo | 400, 401, 403 | SUPER. `Consulta` | Instalación |
| L-06 | `/api/super/licencia/solicitud` | GET | → `SolicitudLicenciaDto` (archivo JSON) | — | 401, 403, 503 `LICENCIA_SIN_INSTALACION` (en Estricto, sin `InstalacionId`) | SUPER. `Consulta` | Instalación, sin secretos. **(v2)** Lleva `sec`, `lid` y SHA-256 del contenido de la licencia vigente (SEG-L2-09) |
| L-07 | `/api/super/licencia/{empresa}/consumidores` | GET | → `ConsumidorLicenciaDto[]` | La empresa existe | 404 | SUPER. `Consulta` | Empresa de la ruta |
| **L-08 (v2)** | **`/api/super/licencia/vigente`** (v1: `/api/admin/licencia/vigente`) | GET | → bytes del JWS | — | 401, 403, 404 | **Solo SUPER** (SEG-L2-15). `Consulta` | Instalación. El JWS contiene todas las empresas, con su RNC, cupo y módulos: un ADMIN de la empresa A no debe ver los de la B |
| **L-09** | `/api/super/licencia` | POST | → 410 `LICENCIA_RUTA_RETIRADA` durante una versión | — | 410 | SUPER | — |
| **S-01** | `/api/super/usuarios/sin-sello` | GET | → `CuentaSinSelloDto[]` | — | 401, 403 | SUPER. `Consulta` | Instalación. **(v2)** Incluye las entradas del padrón sin fila (`FilaAusente`) |
| **S-02** | `/api/super/usuarios/{codigo}/legitimar` | POST | `LegitimarCuentaRequest { Motivo, CodigoSegundoFactor }` → `UsuarioDto` | Motivo de 10 a 200 caracteres; la cuenta existe y no tiene sello válido; cupo (en la misma transacción serializable, contado desde el padrón) | 404; 409 `USUARIO_CON_SELLO`; 409 `LICENCIA_CUPO_AGOTADO`; 422 `MOTIVO_REQUERIDO`; 403 `SEGUNDO_FACTOR` (ADR-81) | SUPER con segundo factor. `Operativa` | Instalación; evento `CuentaLegitimada`. **(v2) No se publica hasta unir la fase A de ADR-81** (SEG-L2-12) |
| **S-03** | `/api/super/empresas/{codigo}/rnc` | PUT | `CambiarRncRequest { Rnc, Motivo, CodigoSegundoFactor }` → `EmpresaRncDto` | RNC de 9 u 11 dígitos con dígito verificador; motivo de 10 a 200 caracteres | 404; 409 `RNC_SIN_CAMBIO`; 422 `RNC_INVALIDO`; 403 `SEGUNDO_FACTOR` | SUPER con segundo factor. **`Esencial`**: es la salida de `Invalida` (`[LIC]` 4.2) | Empresa de la ruta. Escribe primero la fila MAC en `GPOS_SYSDATA` y después el RNC en la base de la empresa. **(v2, SEG-L2-16) Idempotente:** si ya existe la fila `CambiosRnc` con el mismo `RncNuevo` y la base de la empresa no lo tiene, repetir completa la segunda escritura sin fila nueva (no responde `RNC_SIN_CAMBIO` en ese caso). El motor (L1a-3) solo da por vigente el cambio cuando el RNC de la empresa es igual a `RncNuevo`. **(v2) No se publica hasta unir la fase A de ADR-81** (SEG-L2-12) |
| **S-04 (v2)** | `/api/super/usuarios/padron/{codigo}/purgar` | POST | `PurgarEntradaPadronRequest { Motivo, CodigoSegundoFactor }` → 204 | Motivo de 10 a 200 caracteres; la entrada existe en el padrón y **la fila de la cuenta no existe** | 404 `PADRON_SIN_ENTRADA`; 409 `USUARIO_CON_FILA` (si la fila existe, se inhabilita por la vía normal); 422 `MOTIVO_REQUERIDO`; 403 `SEGUNDO_FACTOR` | SUPER con segundo factor. `Operativa` | Instalación; evento `PadronEntradaPurgada` (SEG-L2-01). No se publica hasta unir la fase A de ADR-81 |
| — | Configuración de la empresa (ADMIN) | existente | Si el RNC cambia → 409 `RNC_SOLO_SUPER` | — | — | — | DL-03 |

**Mientras no esté la fase A de ADR-81 (SEG-L2-12, ajuste de la v2):**
- S-02, S-03 y S-04 se construyen y se prueban, pero **no se mapean** en la API hasta que la fase A esté unida. No es un interruptor: el `Map*` se agrega en el PR que se une después de ADR-81.
- Las mismas operaciones se hacen **en el servidor de la API** con `GPOS.Migracion`, que exige acceso de Windows al servidor y al anillo (H-17 v2 en Estricto):
  - `GPOS.Migracion empresa --cambiar-rnc <empresa> <rnc> --motivo "<texto>"`: escribe la fila con MAC y el RNC, idempotente como S-03;
  - `GPOS.Migracion sellos --legitimar <codigo> --motivo "<texto>"`: como S-02, con el control del cupo;
  - `GPOS.Migracion sellos --purgar <codigo> --motivo "<texto>"`: como S-04.
- Los tres dejan el mismo evento en la bitácora, con el usuario de Windows que los ejecutó. Un `sysadmin` de SQL sin acceso al anillo no puede usarlos; un administrador de Windows sí, que es el residual de CP-4.
- El `CodigoSegundoFactor` **nunca** va a los registros de peticiones (ADR-81, punto 5).

**Inicio de sesión de una cuenta sin sello:** el sello se comprueba **antes** que la contraseña; si no verifica, se verifica un hash ficticio y se da la misma respuesta que con una contraseña incorrecta. No cuenta el intento y registra el evento `USUARIO_SIN_SELLO` (2.4, SEG-L2-17).

### 5.2 DTO y códigos (`GPOS.Contracts/Licencia`)

```csharp
public sealed record EstadoLicenciaDto(string Estado, string? Motivo, DateOnly? Vence, int? DiasRestantes, DateTime? GraciaHastaUtc, string? Mensaje, bool Franja);
public sealed record UsuariosLicenciaDto(int Autorizados, int Consumidos, bool EnExceso);   // v2: Consumidos sale del padrón (2.3)
public sealed record ModuloLicenciaDto(string Codigo, DateOnly Vence, string Estado);
public sealed record LicenciaEmpresaDto(string Cliente, string Estado, string? Motivo, DateOnly? Vence, DateTime? GraciaHastaUtc,
    UsuariosLicenciaDto Usuarios, IReadOnlyList<ModuloLicenciaDto> Modulos, CargaLicenciaDto? UltimaCarga, string? NivelFirma,
    string? PisoNivelFirma /* solo SUPER */, DateTime? AutorizacionBasicaHastaUtc);
public sealed record ResultadoCargaLicenciaDto(bool Aceptada, Guid? Lid, long? Sec, string? Codigo, string? Motivo, string EstadoEmpresa, bool PisoHeredado, bool CorteIgnorado);
public sealed record LicenciaInstalacionDto(string Cliente, string InstalacionId, string HuellaVigente, string HuellaActual, long Sec, DateTime EmitidaUtc,
    ParametrosLicenciaDto Parametros, IReadOnlyList<LicenciaEmpresaDto> Empresas, string? NivelFirma, string? PisoNivelFirma,
    string PerfilMinVigente, bool PerfilMinHeredado, IReadOnlyList<string> MachineGuidInformativos);
public sealed record ParametrosLicenciaDto(int GraciaDias, int AvisoDias, TimeOnly HoraCorte, string Anillo);
// v2 (SEG-L2-18): Sha256 → Sha256Contenido = SHA-256 de los bytes del contenido (payload decodificado), no del archivo
public sealed record CargaLicenciaDto(Guid? Lid, long? Sec, string Origen, string? Usuario, DateTime RecibidaUtc, char Resultado, string? Motivo, string Sha256Contenido);
// v2 (SEG-L2-09): sec, lid y SHA-256 del contenido de la licencia vigente; null si no hay ninguna aceptada
public sealed record SolicitudLicenciaDto(string InstalacionId, string Huella, IReadOnlyList<EmpresaSolicitudDto> Empresas, string Version, IReadOnlyList<string> MachineGuids,
    long? SecVigente, Guid? LidVigente, string? Sha256ContenidoVigente);
public sealed record EmpresaSolicitudDto(string Codigo, string? Rnc);
public sealed record ConsumidorLicenciaDto(string Codigo, string Descripcion, string Nivel, DateTime? UltimoAcceso);
public sealed record CuentaSinSelloDto(string Codigo, string Nivel, bool Inhabilitado, string Motivo /* SinSello|SelloInvalido|FueraDePadron|CamposNoCoinciden|FilaAusente (v2) */, DateTime DetectadaUtc);
public sealed record LegitimarCuentaRequest(string Motivo, string CodigoSegundoFactor);
public sealed record PurgarEntradaPadronRequest(string Motivo, string CodigoSegundoFactor);   // v2, S-04
public sealed record CambiarRncRequest(string Rnc, string Motivo, string CodigoSegundoFactor);
public sealed record EmpresaRncDto(string Codigo, string Rnc, DateTime CambiadoUtc, string Usuario);
```

**`CodigosLicencia` (constantes `string`):**
- Bloqueo, con 403: los 6 de `[LIC]` 4.5 (`LICENCIA_SOLO_CONSULTA`, `LICENCIA_EMPRESA_NO_LICENCIADA`, `LICENCIA_RNC_NO_COINCIDE`, `LICENCIA_ILEGIBLE`, `LICENCIA_MODULO_VENCIDO` y `LICENCIA_ENTORNO`).
- Carga, en L-03: los de `[LIC]` L-03, **más `LICENCIA_VIGENCIA_BASICA` (422, v2, DL-14)**.
- Nuevos de este documento: `LICENCIA_RUTA_RETIRADA`, `LICENCIA_SIN_INSTALACION`, `LICENCIA_CUPO_AGOTADO`, `USUARIO_SIN_SELLO`, `USUARIO_CON_SELLO`, `RNC_SOLO_SUPER`, `RNC_INVALIDO` y `RNC_SIN_CAMBIO`; **v2:** `PADRON_SIN_ENTRADA` y `USUARIO_CON_FILA` (S-04).

**Eventos nuevos de la bitácora:** `USUARIO_SIN_SELLO`, `CuentaLegitimada`, `PadronRetrocedido`, `SelladoInicial`, `CambioRncSuper` y `CuentasInicialesCreadas`; **v2:** `PadronEntradaPurgada`, `ArranqueAmplioBloqueado` (crítico) y `LicenciaCargadaInstalacion` con la lista de empresas afectadas (SEG-L2-15).

**Identidad de «ya aceptado» (v2, SEG-L2-18, ajuste):**
- `UX_Licencias_Aceptada` y la comparación de la regla «`sec` duplicada con otro contenido» (`[LIC]` 3.1.1, punto 7) usan el **SHA-256 del contenido** (`ResultadoJws.Contenido`, que ya devuelve el verificador), no el del archivo. El SHA-256 del archivo se conserva como dato informativo (entrega al arquitecto de datos).
- **Motivo:** el SHA-256 del archivo es maleable por **dos** vías, no solo por la de ECDSA que señala el auditor: (r, n − s) verifica con la misma firma, y además la envoltura JSON de la serialización general admite otros espacios y otro orden de miembros sin tocar ninguna firma. El contenido está cubierto por la firma, así que su SHA-256 no se puede variar sin la llave.
- **Rechazo de la regla de `s` bajo como control principal:** CNG, el proveedor PCP del TPM y la YubiKey no normalizan `s` [I]. Exigirlo obligaría a normalizar en cada proveedor del emisor; un proveedor que lo olvide produce un rechazo aleatorio en la mitad de las firmas en el cliente, un modo de falla frágil. Y no cerraría la vía de la envoltura JSON.
- El emisor guarda en su registro el mismo SHA-256 del contenido, que es lo que compara con `Sha256ContenidoVigente` (SEG-L2-09).
- L1a-1 agrega un vector que documenta el comportamiento: la firma maleada (r, n − s) **verifica** y devuelve el mismo `Contenido` (14).

### 5.3 Marca de clase

`ClaseLicencia(ClaseOperacion)` es metadato de la ruta, igual que `RolSitioRuta`.

| Caso | Clase |
|---|---|
| `GET` y `HEAD` | `Consulta` por omisión |
| Marca existente `SoloConsulta` (la del candado) | `Consulta` (C-09) |
| `Esencial` y `Preparacion` | Marca explícita, y la ruta tiene que figurar en `tests/GPOS.Tests/Licencia/RutasLicenciaAprobadas.json` |
| Todo lo demás | `Operativa`: si se olvida la marca, la ruta queda bloqueada (falla cerrado) |

**Ojo con los nombres:** la marca `SoloConsulta` de la ruta y el estado `EstadoLicenciaEmpresa.SoloConsulta` (firmado en ADR-59) se llaman igual. En el código se citan con su nombre completo.

---

## 6. Interfaces entre módulos

### 6.1 Licencia

```csharp
// GPOS.Criptografia
public sealed record FirmaVerificada(string Kid, string Nivel);
public sealed record ResultadoJws(bool Valido, string? Codigo, ReadOnlyMemory<byte> Contenido, IReadOnlyList<FirmaVerificada> Firmas, IReadOnlyList<string> KidsIgnorados);
public interface IVerificadorJws { ResultadoJws Verificar(ReadOnlySpan<byte> jws, string typEsperado, ConjuntoLlaves llaves); }  // 3.1.1 puntos 1-6
public sealed record LlaveGsf(string Kid, string Funcion /* lic|upd */, string Nivel, string Estado, DateOnly Desde, DateOnly? AceptarHasta, ECParameters Publica);
public interface IRecursoLlavesGsf { ConjuntoLlaves Efectivo { get; } string HuellaRecurso { get; } }   // QA-L17 inspecciona Efectivo (NV-05 a)

// GPOS.Core/Sistema/Licencia
public interface IEstadoLicencia                      // [LIC] 8.5, con:
{
    EstadoLicenciaEmpresa Estado(string empresa);
    MotivoGracia? Motivo(string empresa);
    bool Permite(string empresa, ClaseOperacion clase, string nivelUsuario);
    void ExigirOperativa(string empresa, string tipoDocumento);   // segunda barrera; lanza LicenciaException
    int CupoUsuarios(string? empresa);                            // null = límite global antes de la versión 1 (suma de cupos, [LIC] 2.2); 0 sin licencia
    EstadoModulo? Modulo(string empresa, string codigoModulo);
    long SecVigente { get; }
}
public interface IHuellaEntorno { Task<HuellaLeida> LeerAsync(CancellationToken ct); }        // C-07
public interface IAlmacenLicenciaDisco { /* C-03: Entrada, Procesados, Rechazados, Aceptaciones, vigente, secmax, estado, pisonivel */ }
public interface IBitacoraSeguridad { Task RegistrarAsync(EventoSeguridad e, CancellationToken ct); }   // C-05; en la misma transacción si la hay
```

### 6.2 Reloj (cierre de H-16, C-04)

```csharp
public interface ICorroboracionHora
{
    // fuente: "emitida" (L1b) o "agente-date" (L4). Solo permite avanzar la hora más alta hasta
    // mín(reloj del sistema, hora confiable + tolerancia); nunca la siembra por encima del reloj (LIC 4.1.3).
    void Corroborar(DateTime horaConfiableUtc, string fuente);
}
```

### 6.3 Sello y padrón (desarrollador de identidades; v2)

```csharp
public enum ResultadoSello { Valido, SinSello, SelloInvalido, FueraDePadron, CamposNoCoinciden, FilaAusente /* v2 */ }

// Contenido protegido del sello ("GPOS.Usuarios.Sello.v1"):
//   InstalacionId, Codigo, Nivel, Inhabilitado (= false), Sucursal, HabilitadoUtc,
//   HuellaClave = SHA-256(PasswordHash)          (v2, DL-05 obligatoria; no el SelloSeguridad, ver SH-5)
//   FactorAlta  = bool, solo en los SUPER          (v2, SEG-L2-06; false mientras no exista ADR-81 fase A)

public sealed record EntradaPadron(ReadOnlyMemory<byte> HuellaSello /* 12 bytes */, string Nivel);   // v2: con el nivel
public sealed record PadronSellos(Guid InstalacionId, long Version, IReadOnlyDictionary<string, EntradaPadron> Entradas)
{
    public int ConsumoNoSuper => Entradas.Values.Count(e => e.Nivel != NivelUsuario.Super);   // v2: fuente del cupo
}

public interface IPadronSellos
{
    PadronSellos Vigente();   // caché global; mayor Version que verifica entre la base y el disco (2.3)
    // Solo por diferencias, dentro de la transacción serializable de la acción. Nunca reconstruye desde las filas.
    void Poner(string codigo, EntradaPadron entrada, IDbTransaction tx);
    void Quitar(string codigo, string motivo, IDbTransaction tx);
    void TrasConfirmar();     // escribe la copia del disco después del commit (reemplazo atómico)
}

public interface ISellosHabilitacion
{
    byte[] Sellar(Usuario u, DateTime habilitadoUtc, bool factorAlta);   // dentro de la transacción del cambio; actualiza el padrón con Poner
    ResultadoSello Verificar(Usuario u, PadronSellos padron);
}
// EstadoSesionUsuario gana: ResultadoSello Sello  →  Evaluar() devuelve ValorCredenciales si no es Valido (SH-2)
// IEstadoLicencia.CupoUsuarios(empresa) se compara con PadronSellos.ConsumoNoSuper (por empresa cuando llegue la versión 1)
```

**Cuándo se vuelve a sellar (v2):** alta, rehabilitación, cambio de nivel o de sucursal, cambio o restablecimiento de contraseña, nuevo hash al entrar (`UsuariosService.cs:48`, raro: solo al subir los parámetros de PBKDF2), alta o baja del factor (ADR-81) y legitimación. Cada uno actualiza la entrada del padrón en la misma transacción.

### 6.4 Agente de actualización (L4, para después del corte)

Lo que la API espera del agente:
- deja los archivos en `Licencia\Entrada\`;
- escribe la hora confiable en `Licencia\HoraConfiable.json` (`{ utc, fuente, obtenidaUtc }`), que la API pasa a `ICorroboracionHora`;
- escribe el resultado del detector en `Licencia\Integridad.json`.

Lo que la API expone al agente:
- `Licencia\Estado\verificacion.json`, que el agente lee después de cada actualización para decidir la reversión.

Hasta que exista el agente:
- la renovación es manual (ADR-60, punto 9);
- H-16 solo corrobora con `emitida`: un salto de más de 48 h no mueve la hora alta, que es la falla del lado seguro.

---

## 7. Estructura de proyectos y carpetas

```
src/GPOS.Criptografia/                         (proyecto nuevo, la excepción de H-17 v2; GPOS.Core y GPOS.Web lo referencian)
    Jws/VerificadorJws.cs, LectorJsonEstricto.cs, ConjuntoLlaves.cs
    Llaves/RecursoLlavesGsf.cs, LlavesGsf.json (recurso incrustado; las de prueba NO van aquí)
    Anillo/CifradorAnillo.cs, DecoradorAnilloConforme.cs, RecuperacionAnclada.cs   (H-17 v2)
src/GPOS.Contracts/Licencia/                   FormatoLicencia.cs, LicenciaDtos.cs, CodigosLicencia.cs
src/GPOS.Core/Sistema/Licencia/                ReglasAceptacion.cs, MotorEstados.cs, EstadoLicenciaService.cs, RepositorioLicencias.cs,
                                               AlmacenLicenciaDisco.cs, HuellaEntorno.cs, SolicitudLicencia.cs, ImportadorCarpetaEntrada.cs,
                                               TrabajoAvisosLicencia.cs, FilasProtegidas.cs
src/GPOS.Core/Sistema/Usuarios/                SellosHabilitacion.cs, PadronSellos.cs
src/GPOS.Core/Data/Sistema/                    SqlLicenciaSistema.cs (C-11)
src/GPOS.Core/Infraestructura/Bitacora/        BitacoraSeguridad.cs (C-05)
src/GPOS.Api/Seguridad/                        ModoLicencia.cs, ClaseLicencia.cs
src/GPOS.Api/Endpoints/                        LicenciaEndpoints.cs, SellosEndpoints.cs
src/GPOS.Migracion/                            Sistema/CuentasIniciales.cs, Sistema/SelladoInicial.cs, Anillo/RecuperarAnillo.cs
src/GPOS.Web/Components/Pages/Admin/Licencia.razor  (sustituye a LicenciaUsuarios.razor; frontend)
tests/GPOS.Tests/Criptografia/   tests/GPOS.Tests/Licencia/   tests/GPOS.Tests/Usuarios/Sellos/   (sin proyectos de prueba nuevos)

Repositorio privado GSF.EmisorLicencias (fuera de GPOS-NG.slnx):
    src/Emisor/ Proveedores/{ProveedorTpm, ProveedorYubiKeyPiv, ProveedorSoftware}.cs, Registro/, Ntp/, Catalogo/
    ceremonia/ Ceremonia.ps1, Comun.ps1, Acta.md.plantilla, ListaAceptacion.md, raices/yubico-piv-root.pem
```

- **No se crea `GPOS.Licencia`.** Se cumple la convención `GPOS.{Área}`.
- Una prueba de arquitectura comprueba que ningún proyecto de `GPOS-NG.slnx` contiene código de firma ni referencia al emisor.

---

## 8. Requisitos de seguridad de arquitectura (v2)

| Tema | Requisito |
|---|---|
| Autenticación | Sin cambios (ADR-36 y ADR-41), más el sello en el inicio de sesión (**antes** que la contraseña, con hash ficticio si falla), en cada petición y en el autorizante (2.4). El sello cubre la huella del `PasswordHash` y, en los SUPER, el estado del factor (DL-05, obligatoria) |
| Autorización | La licencia se evalúa después de los permisos y solo restringe. S-02, S-03 y S-04 son solo del SUPER, con el segundo factor de ADR-81, y **no se publican antes de su fase A**; mientras tanto, verbos de `GPOS.Migracion` en el servidor (5.1). L-08 solo del SUPER. **Límite declarado (SEG-L2-04):** el sello protege el cupo, el nivel, la sucursal, la contraseña y el factor del SUPER; **no** protege los permisos granulares (perfiles y excepciones), que un `sysadmin` puede cambiar y que son el residual de CP-4 |
| Aislamiento entre empresas | Igual que `[LIC]` 9. S-03 actúa sobre la empresa de la ruta y deja el evento con esa empresa. L-08 ya no expone a un ADMIN los datos de las demás empresas. L-03 de un ADMIN afecta a toda la instalación y el evento lista las empresas afectadas (SEG-L2-15) |
| Secretos | La instalación no guarda ningún secreto de la licencia: solo llaves públicas en los binarios. Los sellos, el padrón (base y disco) y las filas protegidas usan el anillo (H-17 v2). El PIN, el PUK y la llave de gestión de las YubiKeys, el **PIN de `s1`** y la contraseña de `gsf-firma` **nunca** van en scripts, parámetros, registros ni actas, ni se guardan en el equipo emisor (sección 10, E-2 y E-6). El `CodigoSegundoFactor` nunca va a los registros de peticiones |
| Integridad | `Licencias` y `LicenciaLlavesRetiradas` son de solo inserción; filas con MAC; padrón como fuente del cupo, actualizado por diferencias, con copia en el disco y la mayor versión que verifica (DL-01); RNC con MAC e idempotente (C-06); «ya aceptado» por SHA-256 del contenido (SEG-L2-18) |
| Configuración | Sin interruptores (ADR-60, punto 6). **El modo Amplio no relaja la licencia ni el sello: en una compilación Release ningún modo crea ni sella cuentas en la API**, y con una licencia de `anillo` `Produccion` o `Beta` la API no arranca en Amplio (SEG-L2-05, DL-02). Ni el proveedor de software ni la llave `gsf-lic-dev` están en Release (9.3) |
| Vigencia (v2) | Un archivo sin firma Avanzada propia no puede tener ningún `vence` posterior a `emitida` + 200 días (DL-14). Acota el daño de una licencia falsificada con `s1` en un cliente que no actualiza los binarios |
| Criptografía (SEG-L2-21) | ES256 con `ECDsa` de la plataforma (CNG), sin bibliotecas JOSE de terceros; Data Protection con los algoritmos por omisión; PBKDF2. Conforme con `[PSF]`. El TPM de un equipo de consumo no tiene validación FIPS 140-3 [I]: Q-21 se mantiene y nada firmado en Básico se presenta como «validado» |

---

## 9. Emisor sin hardware: abstracción del proveedor de llave (precisión del propietario, punto 1)

### 9.1 Contrato

```csharp
public interface IProveedorLlaveFirma
{
    string Kid { get; }                         // gsf-lic-s1, gsf-lic-a1, gsf-lic-b1, gsf-lic-dev…
    string Nivel { get; }                       // basico | avanzado | desarrollo
    string Tipo { get; }                        // Tpm | YubiKeyPiv | Software
    ECParameters LlavePublica();                // P-256
    byte[] Firmar(ReadOnlySpan<byte> entradaFirma, IConfirmacionCustodio confirmacion); // devuelve P1363 (r‖s, 64 bytes)
    Atestacion? Atestacion();                   // YubiKey: certificado de atestación y el intermedio F9; TPM: null o EK/AIK si se decide
}
public interface IConfirmacionCustodio { bool Confirmar(ResumenFirma resumen /* cliente, empresas, fechas, cupos, corte, SHA-256 */); }
```

| Proveedor | Nivel | Implementación | Utilizable |
|---|---|---|---|
| **TPM** | Básico (`s1`, `s1r` de DL-10 y `s2`) | CNG con «Microsoft Platform Crypto Provider», ECDSA P-256 no exportable, PIN de la llave (`NCRYPT_UI_POLICY`) [I] | **Ya**, en la cuenta dedicada del equipo principal del propietario (10.6, AI-09); también en el equipo de desarrollo para las pruebas, si tiene TPM 2.0 |
| **YubiKey PIV** | Avanzado (`a1` y `b1`) | Ranura 9c, P-256, PIN y toque «always». Opción recomendada: **Yubico .NET SDK** (`Yubico.YubiKey`, paquete NuGet de Yubico) [I]. Alternativa: PKCS#11 con `ykcs11` y `Pkcs11Interop`. La YubiKey devuelve DER, que se convierte a P1363 | Código y pruebas **con un doble simulado**; prueba real el día de la ceremonia |
| **Software** | Desarrollo | `ECDsa` en memoria o en un archivo protegido con DPAPI del usuario (nunca en el repositorio) | Desarrollo y pruebas. **Firma solo `anillo: "Desarrollo"` con `kid` `gsf-lic-dev*`** |

**La API no depende del proveedor.** La verificación es ES256 sobre los bytes, con la llave pública del recurso. El nivel lo da el recurso por `kid` (`[LIC]` 3.1), nunca el proveedor ni el encabezado. Por eso las pruebas de la API usan el proveedor de software sin perder cobertura.

### 9.2 Reglas del emisor que impiden emitir licencias indebidas

1. **Release del emisor:** el proveedor de software solo se puede cargar para `anillo: "Desarrollo"`. Con otro anillo, el emisor no arranca la emisión: `PROVEEDOR_NO_ADMITIDO`.
2. **Nivel Básico (TPM), con la precisión firmada (b):** firma todos los anillos admitidos en Release (`Produccion`, `Beta` y `Demostracion`), **también las licencias de pago**.
   - El registro marca cada emisión con su nivel.
   - El tablero lista los clientes de pago con licencia vigente Básica: es la lista de reemisión de AP-05. *(Con el recorte 1 anticipado, el tablero pasa a enero; hasta entonces la lista sale de una consulta sobre el registro, que ya marca el nivel.)*
   - *Retirada:* la regla de la versión anterior de este documento (el emisor Básico no firmaba producción) queda sustituida por la firma del propietario.
3. **CW-02 (firmada):** el nivel Básico no ofrece `corte: "inmediato"`. Para los clientes de pago en Básico, una revocación anticipada siempre pasa por la gracia de transición, de al menos 72 h (10.5).
4. **Siempre:** la hora NTP en dos fuentes, el desvío de 1 minuto como máximo, `sec` derivada del tiempo, el resumen y el SHA-256 antes de cada firma, y el registro con cadena de hashes. El registro guarda el **SHA-256 del contenido**, el mismo que usa la API (5.2).
5. **(v2) DL-14, tope de vigencia Básica (SEG-L2-02).**
   - **Regla:** en un archivo **sin firma Avanzada propia** (ninguna de sus firmas verificadas es de una llave de nivel `avanzado` según el recurso, `FirmaVerificada.Nivel`), cada `vence`, de empresa y de módulo, cumple `vence ≤ fecha(emitida) + 200 días`.
   - **Dónde se verifica:**
     - **En la API, en las reglas de aceptación (L1a-2)**, como función pura sobre el contenido y las firmas verificadas; se evalúa después de la firma, del nivel y del piso (D-2), y antes de persistir. Si falla: 422 `LICENCIA_VIGENCIA_BASICA`, el archivo va a `Rechazados` y queda el evento. Se aplica a la carga manual (L-03) y al importador de la carpeta de entrada por igual.
     - **En el emisor (EM)**, como defensa propia: en Básico, `vence = mín(fin del período pagado, emitida + 200 días)`, y el emisor se niega a firmar un `vence` mayor. A los clientes anuales les emite **archivos semestrales** mientras dure el nivel Básico.
   - **Por qué alcanza:** `emitida` está firmada y acotada por el techo de 48 h sobre la hora protegida (`[LIC]`:303). Un falsificador no puede adelantar `emitida`, así que una licencia falsificada con `s1` vale como mucho unos 200 días más 48 h en un cliente que no actualiza.
   - **No aplica** a los archivos con firma Avanzada propia (después de la ceremonia), ni cambia el piso (INV-4). Los archivos de desarrollo (`gsf-lic-dev`) también lo cumplen: los datos de prueba tienen que respetarlo.
   - **Costo:** 0,25 dp en L1a-2, 0,1 dp en EM y 0,1 dp de QA. **Costo operativo:** los clientes anuales cargan un archivo dos veces al año mientras no haya agente (L4); el aviso de vencimiento (`AvisoDias`) tiene que decir «renovar el archivo», no «renovar el pago».
   - *Alternativas descartadas:* 62 días (emisión mensual para todos: obliga a cargar un archivo al mes sin agente) y 400 días (compatible con un archivo anual, pero acota poco). 200 días cubre el refresco semestral de PA-8 con margen [I].
6. **(v2) Lo que se confirma es lo que se firma (SEG-L2-19).**
   - El resumen y el SHA-256 que muestra `IConfirmacionCustodio` se calculan **decodificando la propia `entradaFirma`** (encabezado protegido y contenido en base64url), no a partir del objeto con el que se construyó.
   - Después de firmar y **antes de escribir el archivo**, el emisor verifica el JWS completo con `GPOS.Criptografia.VerificadorJws` y la llave pública del **`LlavesGsf.json` publicado** de la versión vigente (fábrica pública de `ConjuntoLlaves`, sección 14). Si no verifica, no escribe nada y registra el fallo.
   - Pruebas de la conversión DER a P1363 con `r` o `s` que empiezan con ceros (cada valor, 32 bytes exactos).
7. **(v2) *Handle* por firma (SEG-L2-10):** el proveedor TPM abre y cierra el *handle* de la llave en cada firma, para que la autorización no quede en caché. El ensayo comprueba que **dos firmas seguidas piden el PIN dos veces**.
8. **(v2) Comparación con el registro (SEG-L2-09):** en cada emisión o renovación, el emisor lee `SecVigente`, `LidVigente` y `Sha256ContenidoVigente` de la solicitud (L-06) y los compara con su registro para esa instalación. Si la `sec` o el `lid` no están en el registro, o el SHA-256 no coincide, **detiene la emisión** con la alerta «licencia no emitida por GSF en esta instalación» (`LICENCIA_NO_EMITIDA_POR_GSF`, código del emisor) y el caso pasa al procedimiento de compromiso de AP-03. El soporte de GSF hace la misma comparación con L-04 en cada visita.
9. **(v2) Cofirma de transición (SEG-L2-22, recomendado para DL-11):** en la reemisión posterior a la ceremonia, el archivo lleva dos firmas, `s1` y `a1` (serialización general). Lo aceptan los binarios antiguos y los nuevos, y los 45 días de DL-11 dejan de ser críticos para quien actualiza tarde. El verificador ya admite varias firmas (`VerificadorJwsLimites.FirmasMaximas = 8` [V, `GPOS-NG-lic`, sin confirmar]). **El archivo cofirmado tiene que cumplir también DL-14**: en los binarios antiguos `a1` es un `kid` desconocido que se ignora, así que el archivo cuenta como Básico. Costo: 0,25 dp en EM después de la ceremonia.

### 9.3 Garantías en la API (ya firmadas, solo se recuerdan)

- Release rechaza `anillo: "Desarrollo"` y los `kid` con prefijo de desarrollo (NV-05, b).
- QA-L17 lo comprueba sobre la compilación Release.
- La canalización rechaza los ensamblados de depuración (NV-05, c).

---

## 10. Ceremonia lista para ejecutar, ensayo y lista de aceptación (puntos 2 y 3)

### 10.1 Guion (`ceremonia/Ceremonia.ps1`)

Hay una ejecución por llave: `-Funcion lic -Rol titular|suplente`. Las del manifiesto (`upd-a1` y `upd-b1`) siguen el mismo guion con `-Funcion upd`. Cada paso escribe su línea en el **borrador del acta**, con la hora, el resultado y los SHA-256, y **nunca** un PIN, un PUK ni una llave de gestión. Los comandos usan `ykman` (YubiKey Manager CLI) [I: la sintaxis exacta se fija contra la versión instalada el día del ensayo].

| Paso | Qué hace | Con YubiKey | En ensayo (TPM o software) |
|---|---|---|---|
| 0. Preparación | Equipo limpio sin red; versión de `ykman` y SHA-256 de los scripts en el acta | — | Igual |
| 1. Identificación | `ykman info`: número de serie, firmware ≥ 5.7, serie FIPS y estado «FIPS approved» por aplicación. **Si el firmware es menor que 5.7, se detiene** (EUCLEAK) | Real | Simulado: «NO VERIFICADO EN ENSAYO» |
| 2. Verificación CMVP | El custodio anota el número de certificado CMVP 140-3 de la serie y del firmware recibidos (consulta manual). Si solo figura «en proceso», se registra (AP-01) | Manual | Se marca «no aplica» |
| 3. Restablecer PIV | `ykman piv reset` (solo en una llave nueva) | Real | Se recrea el contenedor o la llave de software |
| 4. Llave de gestión | `ykman piv access change-management-key --algorithm AES256 --generate --protect`: la llave queda protegida por el PIN y no se muestra [I] | Real | Simulado |
| 5. PIN y PUK | `change-pin` y `change-puk` **interactivos**: el script no recibe los valores; los escribe el custodio. Intentos: PIN 3, PUK 3 [I] | Real | TPM: PIN de la llave CNG; software: contraseña de DPAPI |
| 6. Modo FIPS | Comprobar que la aplicación PIV quedó «FIPS approved» después de los pasos 4 y 5 [I: en la serie 140-3, el modo aprobado exige cambiar las credenciales por omisión]. Si no, se detiene | Real | «NO VERIFICADO EN ENSAYO» |
| 7. Generación | `ykman piv keys generate --algorithm ECCP256 --pin-policy ALWAYS --touch-policy ALWAYS 9c publica.pem`: la llave se genera en la propia YubiKey y no se puede exportar | Real | TPM: `NCryptCreatePersistedKey`, no exportable; software: en memoria |
| 8. Atestación | `ykman piv keys attest 9c atestacion.pem` y `ykman piv certificates export f9 intermedio.pem`. El script verifica la cadena hasta `raices/yubico-piv-root.pem` y que la pública atestada sea la del paso 7. Anota las políticas de PIN y de toque de la extensión de atestación | Real | Se marca «sin atestación (ensayo)» |
| 9. Publicación de la pública | Exporta `kid`, función, nivel, `desde` y la pública (JWK) a `LlavesGsf.<kid>.json`, con su SHA-256 en el acta. Se incorpora a `src/GPOS.Criptografia/Llaves/LlavesGsf.json` con un PR firmado **y requiere una versión nueva de los binarios** | Real | Escribe en una carpeta de ensayo; nunca en el repositorio |
| 10. Firma y verificación | Firma un **vector de prueba fijo** (licencia de prueba con `anillo: "Desarrollo"` e `instalacion` de prueba). Lo verifica con `GPOS.Criptografia.VerificadorJws` (la misma biblioteca de la API, como herramienta) y comprueba que se pidieron el PIN y el toque | Real | Firma y verifica |
| 11. Bloqueo | Prueba de que un PIN incorrecto descuenta intentos (**un solo** intento fallido y luego el correcto). **No se agota el PIN** | Real | «NO VERIFICADO EN ENSAYO» |
| 12. Custodia | La titular queda con el titular. La suplente va en una bolsa con precinto numerado hasta su entrega (AP-02), y el suplente cambia el PIN, el PUK y la llave de gestión en la entrega, con una segunda acta | Manual | Se marca «no aplica» |
| 13. Acta | Genera `Acta-<fecha>-<kid>.md` desde la plantilla: firmware, serie, CMVP, SHA-256 de la pública, de la atestación y de los scripts, resultado de cada paso y firmas de los presentes. Se guarda con el registro del emisor y una copia fuera de Drive | Real | Acta marcada **ENSAYO, SIN VALIDEZ** |

**Modo de ensayo:** `Ceremonia.ps1 -Ensayo -Proveedor Tpm|Software`.
- Corre los pasos 0 a 13 con el mismo código.
- Los pasos que dependen del hardware se informan como «NO VERIFICADO EN ENSAYO» en la salida y en el acta.
- Se puede ejecutar **hoy** en el equipo de desarrollo y en el equipo principal del propietario, y QA lo automatiza.

### 10.2 Lo que no se puede probar sin el hardware, y cómo se valida ese día

| No verificable antes | Riesgo si falla | Comprobación de aceptación el día de la ceremonia |
|---|---|---|
| Atestación real y cadena hasta la raíz de Yubico | Llave no nacida en el dispositivo | Paso 8 en verde; la pública atestada es igual a la publicada |
| Firmware ≥ 5.7 y serie FIPS 140-3 | EUCLEAK o un nivel Avanzado que no es «hardware validado» | Paso 1 y certificado CMVP anotado (paso 2). Si no hay certificado, la declaración se limita según Q-21 y AP-09 |
| Modo FIPS aprobado del PIV | Declaración inexacta | Paso 6 en verde |
| PIN «always», toque «always» y sin caché | Firma por lote posible | Paso 10: dos firmas seguidas piden el PIN y el toque cada vez; políticas leídas de la atestación |
| Contador de intentos y bloqueo | Bloqueo no documentado | Paso 11 (un fallo controlado) |
| Formato de la firma (DER desde la YubiKey) | La API rechaza la firma | Paso 10, con el verificador de la API |
| Comportamiento real del SDK o de PKCS#11 con el dispositivo | Error de integración | Paso 10. Si falla, se usa la alternativa PKCS#11 (9.1) sin cambiar la API |

**Lista de aceptación:** los 13 pasos en verde para `lic-a1` y `lic-b1` (y para `upd-*`), el acta firmada y el PR del recurso de llaves revisado. Sin eso, la llave no se publica.

### 10.3 Calendario y licencias mientras no haya YubiKeys (punto 4, con la precisión (b); v2)

- **La ceremonia (AP-01) y el paso a Avanzado (AP-05) son acciones del propietario sin fecha**, salvo la fecha de compra y la de revisión que fija DL-12.
  - Las YubiKeys **no se han comprado**, según la precisión del 2026-10-14; `[LIC]` 0.10 decía «compradas el 2026-10-06». Lo vigente es lo que dice hoy el propietario.
  - Nada del calendario hasta el corte las espera.
- **La versión del corte sale en el escenario B** (`[PSF]` 4A.3): el recurso de llaves solo trae `s1` (y `upd-s1` si ya hay agente), más la llave de reserva si se firma DL-10.
- **Licencias que se pueden emitir antes de la ceremonia:**
  - con `gsf-lic-dev` (software): desarrollo, pruebas automáticas y equipos de desarrollo (solo `Debug`);
  - con `s1` (TPM, cuenta dedicada del equipo principal, 10.6): el DEMO, las demostraciones, las empresas Beta, las instalaciones de prueba de GSF y, **por la precisión firmada (b), las de pago**. Todas con el tope de DL-14.
- **Lo que hace falta para la primera licencia de pago en Básico** (nada depende del hardware; en negrita lo nuevo de la v2):

  | Condición | Quién | Cuándo (11.3) |
  |---|---|---|
  | El código del lote 2 construido, con PA-12 y QA-L01 a L17 en verde | Desarrolladores y QA | H-4 y S9-S10 |
  | **AI-08:** R-E11 (a) a (s) en verde sobre Release antes de la primera licencia Básica | QA | S8 |
  | **DL-13 cumplida (E-1) antes de AI-09** | Propietario con devops | S1 a S4 |
  | **AI-09:** `s1` generada en el TPM con el guion de 10.1 en modo real, con acta que incluya **E-2 a E-7, E-9, E-10 y E-13**: TPM revisado frente a TPM-FAIL, prueba negativa desde otra cuenta administradora y PIN por firma comprobado | Devops con el propietario | **S6-S7** (v1: S3-S4) |
  | **DL-14 construida** en L1a-2 y en el emisor | L e I | H-2 y H-4 |
  | **Emisor reproducible (E-11)** y **revisión de código del auditor-seguridad sobre EM y `GPOS.Criptografia`** (SEG-L2-08) | Devops y auditor | Criptografía tras H-2; EM en S9 |
  | **Comparación de `sec`, `lid` y SHA-256 en la solicitud, construida** (SEG-L2-09) | L e I | H-4 |
  | **E-8, E-12 y E-14 vigentes** (confirmación desde los bytes, ancla desde otro dispositivo, auditoría de usos de la llave) | Devops con el propietario | S8 |
  | **AP-03:** procedimientos escritos y ensayados, **adaptados a Básico**: compromiso de `s1`, pérdida de `s1` o del equipo, ausencia del titular y **E-15** (sin reinicio del fTPM ni borrado del TPM, protocolo antes de actualizar el BIOS, firma de prueba trimestral) | Devops con el propietario | Antes de la primera licencia de pago |
  | **AP-04:** CP-4 y CP-5 sin cambios, y un **texto adaptado de P-F1 / FY-15 y de R-L11 / R-F11** que nombre las mitigaciones retiradas (equipo dedicado y caducidad del 2026-12-31; las vigencias mensuales, que nunca fueron técnicas), las que las sustituyen (DL-13, DL-14 y E-1 a E-15) y el **vector corregido**: «en cualquier momento, si un programa con privilegios de administrador del equipo captura el PIN». Lo redacta el Maestro y lo firma el propietario | Propietario | Antes de la primera licencia de pago |
  | **DL-12 con fecha de revisión de la aceptación** (como máximo 2027-03-31) | Propietario | En la hoja de firma |
  | **AP-06:** contrato revisado por el asesor legal | Propietario y asesor legal | Antes del primer cliente |
  | Recomendado, sin bloquear: **DL-10**, alternativa (a) llave Básica de reserva en otro TPM o (b) `s1` en YubiKey no FIPS | Firma | — |

  **Fecha más temprana de la primera licencia de pago: 2026-12-14** [I], tras la revisión del auditor en S9. Las licencias del DEMO y Beta pueden salir en S8, después de AI-08 y AI-09.

  **AP-02** (suplente) deja de ser condición mientras no haya `b1`, salvo que se firme DL-10 y la llave de reserva quede con un suplente.
- **Al llegar las YubiKeys:**
  1. ceremonia con el guion (10.1);
  2. PR del recurso con `a1`, `b1` y `upd-a*`, y la `aceptarHasta` de `s1` según DL-11;
  3. versión de los binarios;
  4. reemisión en Avanzado de todos los clientes de pago con `nivelMin: "avanzado"` y firma Avanzada propia, **cofirmada con `s1` y `a1`** (9.2, regla 9), lo que cierra `s1` para cada instalación por el piso monótono (INV-4) en cuanto tenga los binarios nuevos;
  5. retiro de `s1` con los binarios (AP-05).

  Son unos **0,75 dp** de desarrollo (0,5 de la v1 más 0,25 de la cofirma) más la publicación, más **unos 5 a 10 minutos de toques al mes** por cada 50 clientes.

### 10.4 Costo de las secciones 9 y 10 (punto 5; v2)

| Parte | dp |
|---|---|
| Abstracción del proveedor y proveedor TPM | 1,5 |
| Proveedor YubiKey (SDK, conversión DER a P1363, doble simulado) | 1,5 |
| Proveedor de software y su rechazo en Release | 0,5 |
| Guion, scripts, modo de ensayo, plantilla del acta y lista de aceptación | 2,0 |
| Verificación de la atestación (cadena hasta Yubico) | 0,5 |
| **Subtotal kit** | **6,0** |
| Resto del emisor (registro, NTP, catálogo, CSV, resumen, tablero mínimo) | 4,5 |
| **(v2)** DL-14 en el emisor | 0,1 |
| **(v2)** Comparación de la solicitud con el registro (SEG-L2-09) | 0,35 |
| **(v2)** *Handle* por firma (SEG-L2-10) | 0,1 |
| **(v2)** Resumen desde `entradaFirma`, verificación posterior y vectores (SEG-L2-19) | 0,25 |
| **Emisor completo (EM)** | **11,3** (9,3 si el tablero, el CSV y la subida a Drive pasan a enero, recorte 1) |
| Después de la ceremonia: PR del recurso, versión y cofirma (SEG-L2-22) | 0,75 |
| Revisión del guion por devops y ensayo con QA | 0,75 (devops y QA) |

**Devops (v2):** condiciones E-1 a E-15 en la cuenta y el equipo: 0,75 dp (0,5 de la v1 más 0,25); compilación reproducible del emisor (E-11): 0,5 dp; instalador del DEMO con `GPOS.Migracion sistema --cuentas-iniciales` y el sellado inicial (SEG-L2-05): 0,25 dp; llave de reserva (DL-10 (a)): 0,25 dp.

**Auditor-seguridad (v2):** revisión de código de EM y `GPOS.Criptografia` (SEG-L2-08): unos 1,0 dp [I], en dos tandas (criptografía tras H-2, emisor en S9).

**Desarrollo para DL-10 (a):** 0,25 dp.

En dinero, el mini-PC ya no se compra: **ahorro de USD 300 a 500**. Si se elige DL-10 (b), dos YubiKey no FIPS: unos **USD 110** [I: precio de lista, sin verificar].

*Referencia de la v1:* antes de las precisiones, el emisor costaba 7,6 dp (1,0 sp del emisor más mi reparto de las adiciones de `[PSF]`); el kit agregó unos 2,9 dp netos [I].

### 10.5 Licencias de pago en nivel Básico: invariantes que cambian y riesgos (v2, con la estimación de `[SEG]`)

**Invariantes:**

| Invariante | Antes (licencias de pago solo en Avanzado) | Con la precisión (b) y el escenario B | Propuesta |
|---|---|---|---|
| **INV-1 y Q-16:** `aceptarHasta` de `s1` el 2026-12-31 | Cerraba la ventana Básica de forma técnica | **No rige** mientras el recurso no tenga una llave Avanzada activa (`LlaveBasicaSinRelevo`). `s1` sirve sin fecha de fin. Si la versión con `a1` y `b1` sale después del 2026-12-31 con esa fecha fija, todo archivo nuevo solo con `s1` se rechaza desde el primer día, también las reemisiones de transición | **DL-11:** la `aceptarHasta` de `s1` la fija **la versión que incorpora las llaves Avanzadas**, en publicación + 45 días. Precisa Q-16. Con la cofirma (9.2, regla 9) la ventana deja de ser crítica |
| **INV-3 con D-1** | Retirar `s1` era posible con un manifiesto Avanzado | Con solo `s1`, ningún manifiesto puede retirarla: es la última llave aceptable, y un manifiesto Básico no retira llaves de licencias. **Solo la retiran los binarios** | **v2 (SEG-L2-11):** DL-10 cubre la **pérdida** (R-B12), no el compromiso: retirar `s1` sigue exigiendo binarios. El **compromiso lo acota DL-14**. Más el procedimiento de emergencia por binarios (AP-03) |
| **INV-4 con D-2** (piso monótono) | — | Las licencias de pago llevan `nivelMin: "basico"`. La reemisión con firma Avanzada propia sube el piso y cierra `s1` en esa instalación | Sin cambio de regla; es el mecanismo de la reemisión de 10.3 |
| **INV-5 y CW-02** (corte inmediato) | Disponible para los clientes de pago | **No disponible** mientras estén en Básico: un fraude o un fin de contrato tarda al menos `máx(graciaDias, 72 h)` contado desde `emitida` | Aceptar (residual Bajo). Ya era la consecuencia firmada de CW-02 |
| **(v2) Vigencia de un archivo Básico** | Sin tope (`[LIC]`:916); las «vigencias mensuales» eran una práctica comercial, no una regla técnica | Una licencia falsificada con `s1` podía tener un `vence` arbitrario | **DL-14:** `vence ≤ emitida + 200 días` en todo archivo sin firma Avanzada propia (9.2, regla 5) |
| `s2` y `autNivel` (regreso temporal) | Para cuando falte la YubiKey | No aplican en el escenario B; el código se construye (Q-24, plan completo) y queda inactivo | Sin cambio |
| **Q-21** (declaraciones) | — | Nada firmado en Básico se presenta como «hardware validado» ni FIPS | Sin cambio |
| NV-08 (retiro efectivo) | — | Una licencia falsificada con `s1` vale hasta el retiro efectivo, que exige que el cliente **instale** los binarios nuevos | **v2:** en un cliente que no actualiza, vale como máximo hasta `emitida` + 200 días (más el techo de 48 h), no hasta un `vence` lejano elegido por el falsificador |

**Riesgos nuevos o agravados** (la estimación del auditor sustituye la de la v1 donde difieren):

| # | Riesgo | Prob. / impacto | Antes | Mitigación |
|---|---|---|---|---|
| **R-B11** | **Compromiso de `s1`:** quien la use fabrica licencias de pago para cualquier instalación (el `InstalacionId` viaja en la solicitud), sin telemetría (Q-08). No se revocan en un cliente que no instala binarios nuevos | Baja-Media / Alto | Medio, acotado a Beta y DEMO y con fin el 2026-12-31 | E-1 a E-15 (10.6); **DL-14** acota la duración; **comparación de `sec` y `lid`** (SEG-L2-09) y auditoría de usos (E-14) dan detección; registro encadenado con ancla enviada desde otro dispositivo; DL-11; comprar las YubiKeys (DL-12) |
| **R-B12** | **Pérdida de `s1`:** el TPM se borra, se reinstala Windows, una actualización del BIOS reinicia el fTPM o falla el equipo. GSF no puede renovar hasta publicar binarios con una llave nueva | Media / Alto | No afectaba a clientes de pago | **DL-10** (cubre la pérdida): (a) llave `gsf-lic-s1r` en el TPM de **otro** equipo que no es de desarrollo, con cuenta deshabilitada salvo prueba y emergencia, o (b) `s1` y su reserva en YubiKeys no FIPS. E-15 (sin reinicio del fTPM, protocolo de BIOS, firma de prueba trimestral). AP-03 y texto adaptado de R-L11 (AP-04) |
| **R-B13** | **Equipo de uso diario. Vector corregido (v2, SEG-L2-03):** el proveedor PCP guarda la llave como un *blob* envuelto por el TPM en el perfil de `gsf-firma` [I]. **Un programa con privilegios de administrador** en el equipo puede leer ese *blob* y cargarlo en el TPM **desde cualquier sesión y en cualquier momento** si conoce el PIN; **le basta capturar el PIN una vez** (por ejemplo, con un registrador de teclas). Desde ahí firma en silencio, sin abrir la sesión de `gsf-firma` y sin que el propietario vea ningún resumen. No necesita extraer la llave: la **usa**. También puede alterar el emisor para mostrar un resumen y firmar otro. El PIN por firma protege frente al robo del equipo y frente a un programa sin privilegios de otra cuenta, **no frente a un administrador comprometido**. En el equipo principal corren compilaciones, paquetes con *scripts* de instalación y agentes de IA que procesan contenido externo | Baja-Media / Alto | Bajo con el mini-PC dedicado | **DL-13 obligatoria y previa a AI-09** (cuenta diaria estándar; administradora aparte, sin navegar, compilar ni ejecutar agentes): si `s1` se genera con la cuenta diaria administradora, el PIN puede quedar capturado desde el primer día. E-3 a E-5 (sesión solo para firmar, red restringida, sin acceso remoto); E-7 (prueba negativa desde otra cuenta administradora, cuyo resultado queda en el acta y en el texto de AP-04); E-11 (emisor reproducible) |
| R-B14 | **Ventana sin fin:** sin fecha para las YubiKeys, el nivel Básico de pago se prolonga sin límite | Media / Medio | — | **v2 (SEG-L2-13): DL-12** fija una fecha de compra y una **fecha de revisión de la aceptación**, como máximo 2027-03-31. Llegada sin ceremonia, la aceptación **vence** y se vuelve a firmar con la estimación de ese momento (no se detiene la emisión). El registro (y el tablero, en enero) muestra los clientes de pago en Básico |
| R-B15 | Sin corte inmediato para los clientes de pago en Básico | Baja / Bajo | — | Gracia de transición (CW-02). El auditor coincide |

**Estimación conjunta de R-B11 y R-B13 (uso indebido de `s1`), de `[SEG]` SEG-L2-03:**

| Escenario | Riesgo |
|---|---|
| Como en la v1, con la cuenta diaria administradora | **Medio-Alto** |
| Con DL-13 sola | **Medio-Alto**: baja la probabilidad, no el impacto |
| **Con DL-13 + DL-14 + emisor reproducible y revisado (SEG-L2-08) + comparación de `sec` y `lid` (SEG-L2-09) + TPM revisado (SEG-L2-10) + caducidad de la aceptación (DL-12)** | **Medio**, igual que lo aceptado en FY-15. **Es el escenario que propone la v2** |
| Con `s1` en una YubiKey no FIPS con toque obligatorio (DL-10 (b)) más DL-14 | Bajo-Medio |

La v1 sobrestimaba el efecto de DL-13 sola («baja R-B13 de Medio-Alto a Medio»). Queda corregido.

### 10.6 Equipo emisor: cuenta dedicada en el equipo principal del propietario (precisión (c), variante de Q-19 (b); v2)

**Condiciones mínimas E-1 a E-15** (de `[SEG]` §6, que sustituyen a las 9 condiciones de la v1). Las verifica y documenta devops con el propietario y quedan en el acta de AI-09. **[N]** = nueva respecto de la v1.

| # | Condición (resumen) | Cuándo |
|---|---|---|
| **E-1** | **Cuenta diaria del propietario estándar** y cuenta administradora aparte, con otra contraseña, solo para mantenimiento: nunca navegar, leer correo, compilar ni ejecutar agentes. UAC en «notificar siempre», con credenciales en el escritorio seguro. **Obligatoria (DL-13)** | **Antes de AI-09** |
| E-2 | `gsf-firma`: cuenta **local** del grupo Usuarios, sin cuenta Microsoft, sin escritorio remoto, sin correo, navegador ni sincronización, **sin escritura en ninguna carpeta sincronizada**. Contraseña de 16 caracteres o más, única y no guardada en el equipo | Antes de AI-09 |
| E-3 [N] | Sesión solo para firmar: entrar, firmar y **cerrar la sesión** (no cambiar de usuario dejándola abierta) | Antes de AI-09 y siempre |
| E-4 [N] | Red de `gsf-firma` restringida con una regla del Firewall de Windows por usuario: solo UDP/123 hacia las dos fuentes NTP del emisor [I] | Antes de AI-09 |
| E-5 [N] | Ninguna herramienta de acceso remoto activa durante una sesión de firma; recomendado, ninguna instalada | Antes de AI-09 y siempre |
| E-6 | `s1` en el TPM, no exportable, **PIN en cada firma** (comprobado con dos firmas seguidas), PIN de 8 caracteres alfanuméricos o más, único y no guardado en el equipo | En AI-09 |
| E-7 [N] | TPM revisado: fabricante, modelo y firmware en el acta; no afectado por TPM-FAIL (CVE-2019-11090, CVE-2019-16863) ni por avisos posteriores sin corregir. **Un TPM afectado sin firmware corregido no se usa para `s1`.** Prueba negativa: usar la llave de `gsf-firma` desde la cuenta administradora con el PIN correcto; el resultado alimenta el texto de AP-04 | En AI-09 |
| E-8 | Confirmación de cada firma con un resumen **derivado de los bytes que se firman** y verificación posterior con la llave pública del recurso (9.2, regla 6) | Antes de la primera licencia de pago |
| E-9 | Carpeta `PCPKSP` de `gsf-firma` fuera de los respaldos, las instantáneas y la sincronización **desde la generación** | Antes de AI-09 |
| E-10 | BitLocker con TPM y **PIN de arranque**; clave de recuperación fuera del equipo | Antes de AI-09 |
| E-11 | **Emisor reproducible:** compilado desde una etiqueta del repositorio privado, **fuera del equipo emisor**, con el hash comparado en un segundo dispositivo e instalado en `Program Files` con la cuenta administradora; `gsf-firma` sin escritura ahí. Se repite en cada actualización del emisor. **La autocomprobación del SHA-256 al arrancar queda solo como detección de corrupción accidental, no como control** (SEG-L2-08) | Antes de la primera licencia de pago |
| E-12 | Registro encadenado en una carpeta que solo escribe `gsf-firma`. **El emisor muestra el hash del ancla y el propietario lo envía desde otro dispositivo** (por ejemplo, el teléfono). Los `.gposlic` y la copia semanal del registro salen por una carpeta de intercambio que lee la cuenta diaria; la copia semanal va fuera de Drive (SEG-L2-14) | Antes de la primera licencia de pago |
| E-13 | Arranque seguro, **integridad de memoria (HVCI)**, Defender con protección contra alteraciones, Windows Update al día y `w32time` contra una fuente confiable [I: disponibles en Windows 11 Pro] | Antes de AI-09 |
| E-14 [N] | Auditoría de los usos de la llave (eventos 5058/5061 [I]) y **comparación mensual** del número de usos con el registro del emisor. Detección débil (un administrador comprometido puede borrar el registro de eventos) pero gratuita | Se activa en AI-09; primera comparación al mes |
| E-15 [N] | AP-03 adaptado: no aceptar nunca un reinicio del fTPM ni un borrado del TPM; suspender BitLocker y revisar el aviso del fabricante antes de cada actualización del BIOS; **firma de prueba trimestral** con `s1` (y `s1r`) | Antes de la primera licencia de pago |

**Costo:** USD 0. Unos 0,75 dp de devops (10.4). El costo de uso es cambiar de sesión para firmar y cambiar a la cuenta administradora para mantener el equipo.

**Riesgo residual frente al mini-PC dedicado:**
- **Igual:** la llave no es exportable; la custodia y la confirmación son las mismas.
- **Mayor:** la superficie de ataque (el equipo navega, recibe correo y ejecuta herramientas de desarrollo y agentes). Con E-1, ninguna de esas herramientas corre con privilegios de administrador.
- **Estimación (de `[SEG]`):** **Medio** con DL-13, DL-14 y las condiciones de 10.3; **Medio-Alto** si falta cualquiera de ellas (10.5).
- **Detección de firmas hechas fuera del emisor (v2):** ya no depende de que «aparezca» una licencia desconocida. La dan la comparación de `sec`, `lid` y SHA-256 en cada solicitud (9.2, regla 8), la misma comparación del soporte con L-04 y la comparación mensual de E-14.
- **Ahorro:** de USD 300 a 500.
- *Alternativa descartada por el propietario:* el mini-PC dedicado de Q-19 (a).
- *Alternativa barata (SEG-L2-23), DL-10 (b):* `s1` en una YubiKey 5 **no FIPS** (unos USD 55 cada una [I]) con PIN y **toque obligatorio** en cada firma, usando el proveedor `YubiKeyPiv` que ya se construye (9.1) con un `kid` de nivel Básico. **Elimina la firma silenciosa de R-B13** (haría falta el toque físico) y, con dos llaves, sustituye a la llave de reserva en otro TPM. Bajaría R-B11 y R-B13 a Bajo-Medio con DL-14. Mismo esfuerzo que AI-09; no cambia la API.

---

## 11. Calendario hasta el corte con dos desarrolladores (v2)

### 11.1 Capacidad

| Dato | Valor | Origen |
|---|---|---|
| Días hábiles del 2026-10-15 al 2026-12-15 | **43** por desarrollador (44 menos el feriado del 6 de noviembre, trasladado al lunes 9 [I: Ley 139-97]) | Calendario |
| Factor productivo (revisiones, uniones, rondas del auditor) | 0,8 | [I] |
| **Capacidad efectiva** | **≈ 34,4 dp por desarrollador** | |

### 11.2 Carga (central, con un margen de ±35 % según `[DLV]`)

| Desarrollador | Piezas (dp) | v1 | **v2** | v2 +35 % |
|---|---|---|---|---|
| **L (licencia, API)** | L1a-1 4,1; L1a-2 4,25; L1a-3 2,5; L1a-4 2,85; L1b con H-16 9,6; C-03 y C-05 1,0 | 23,4 | **24,3** | 32,8 |
| **I (identidades)**, sin recorte | RG-14, backend de los lotes 1 y 2 6,0; SL 4,35; CR H-17 v2 2,2; RN 1,25; DDL y retiro de `UsuariosAutorizados` 0,75; EM 11,3; llave de reserva DL-10 0,25 | 23,0 | **26,1** | 35,2 |
| **I (identidades), con el recorte 1 anticipado** | Igual, con EM 9,3 | — | **24,1** | 32,5 |
| Otros agentes | Frontend 2,5; QA 6,5 (v1: 6,0); devops 4,5 (v1: 3,5); datos 1,1 (v1: 1,0); **auditor ≈ 1,0 (nuevo)** | 13,0 | **15,6** | — |
| Después del corte | L4 (2,8, integraciones); emisor: tablero, CSV de pagos y subida a Drive (2,0, recorte 1); cofirma y PR del recurso tras la ceremonia (0,75) | — | — | — |

**Dónde cae cada remediación** (respeta DL-07: L no toca el sello, el emisor ni `GPOS.Migracion`; I no toca los contratos ni las reglas de la licencia):

| Pieza (dueño) | Remediaciones de `[SEG]` | +dp |
|---|---|---|
| L1a-1 (L) | Contratos de la sección 14; vectores de SEG-L2-18 y SEG-L2-19; fábrica pública de `ConjuntoLlaves` | 0,1 |
| L1a-2 (L) | **DL-14** (SEG-L2-02) | 0,25 |
| L1a-3 (L) | NV-07 con `RncNuevo` (SEG-L2-16) | 0,1 |
| L1a-4 (L) | Identidad por contenido (SEG-L2-18); solicitud con `sec`, `lid` y SHA-256 (SEG-L2-09); no arrancar en Amplio con licencia `Produccion`/`Beta` (SEG-L2-05) | 0,35 |
| L1b (L) | L-08 solo SUPER (SEG-L2-15) | 0,1 |
| SL (I) | Cupo desde el padrón y S-04 (SEG-L2-01); Release sin creación ni sellado (SEG-L2-05); DL-05 con `FactorAlta` (SEG-L2-06); copia en disco (SEG-L2-07); orden sello→contraseña (SEG-L2-17); caché global (SEG-L2-20) | 1,85 |
| RN (I) | Verbos provisionales (SEG-L2-12); idempotencia (SEG-L2-16) | 0,5 |
| EM (I) | DL-14 en el emisor; comparación de la solicitud (SEG-L2-09); *handle* por firma (SEG-L2-10); resumen desde los bytes y verificación posterior (SEG-L2-19) | 0,8 |
| Devops | E-1 a E-15 (+0,25); emisor reproducible (+0,5); instalador del DEMO (+0,25) | 1,0 |
| QA | Variantes de PA-45 (columnas, borrado y reinserción), retroceso del padrón, Amplio en Release, firma maleada, tope de vigencia Básica, S-03 con fallo inyectado, sello antes de la contraseña | 0,5 |
| Auditor | Revisión de código de EM y `GPOS.Criptografia` (SEG-L2-08) | ≈ 1,0 |
| Datos | Nivel en la entrada del padrón; `UX_Licencias_Aceptada` sobre el SHA-256 del contenido; modelo de amenazas (SH-2) | 0,1 |

**Total de la licencia en esta versión:** unos **61,7 dp** contando todos los roles (v1: 55). La diferencia, +6,65 dp: L +0,9, I +3,15 (de los cuales 0,5 son DL-05, que la v1 dejaba fuera por opcional) y otros +2,6. En dinero (USD 1 500 a 2 000 por sp): unos **USD 18 500 a 24 700** (v1: 16 200 a 21 600). **Sin infraestructura nueva** salvo, si se elige DL-10 (b), unos USD 110 [I]; las YubiKeys FIPS (unos USD 352) ya estaban presupuestadas (U-01), y el mini-PC no se compra (ahorro de USD 300 a 500).

### 11.3 Plan semanal (v2)

| Semana | Desarrollador L | Desarrollador I | Devops, propietario y auditor | Hito |
|---|---|---|---|---|
| S1: 10-15 y 10-16 | L1a-1: contratos **con los cambios de la sección 14**; PR de `GPOS.Criptografia` | Lote 1 de RG-14; PA-47 | Firma de DL-13; el propietario pasa su cuenta diaria a estándar (E-1) | — |
| S2: 10-19 a 10-23 | L1a-1: verificador y vectores (maleada y ceros a la izquierda) | Lote 1; S0/S1; arranca EM (abstracción y proveedor de software) | — | **H-1 (10-23):** verificador en verde |
| S3-S4: 10-26 a 11-06 | L1a-2 (con **DL-14**) y L1a-3 | CR (H-17 v2); `GPOS.Migracion sistema` con `SqlLicenciaSistema`; EM con TPM y el guion en **modo de ensayo** | E-2 a E-5, E-9, E-10 y E-13 en el equipo principal; revisión del TPM (E-7); certificados de H-17 v2 (antes del 11-02) | **H-2 (11-06):** motor de estados y anillo. Auditor: revisión de `GPOS.Criptografia` |
| S5: 11-10 a 11-13 | L1a-4: carga manual en Amplio | SL: padrón como fuente del cupo, copia en disco, caché | — | **H-3 (11-13):** L-03, L-04 y L-06 de punta a punta |
| S6-S7: 11-16 a 11-27 | L1b: *middleware*, clasificación, segunda barrera y rutas | SL en Estricto, DL-05, Release sin creación; RN con los verbos provisionales (si DL-03 está firmada); `credencial-app` y `aprovisionar` | **AI-09 real:** `s1` en el TPM con DL-13 cumplida y acta (E-6, E-7, E-14) | Requiere la toma nueva unida y AI-07 el 11-16 |
| S8: 11-30 a 12-04 | L1b: avisos, excepciones, Release (QA-L06 y QA-L17), H-16 | EM: kit de la ceremonia con ensayo, comparación de la solicitud, verificación posterior | Compilación reproducible del emisor (E-11); E-8, E-12 y E-14 vigentes; AI-08 (QA). Primeras licencias Básicas reales del **DEMO y Beta** | **H-4 (12-04):** código completo |
| S9-S10: 12-07 a 12-15 | Estabilización: PA-12 en Estricto con la licencia, QA-L01 a L17 y PA-41 a PA-48 | Brechas de PA-12 y de la revisión del auditor; PA-38 a PA-40 | **Auditor: revisión de código de EM (12-07 a 12-11).** Primera licencia **de pago** desde el 12-14 si 10.3 está completo | **Corte (12-15)** |

### 11.4 ¿Cabe?

- **Con el reparto DL-07 y el recorte 1 anticipado: sí.**
  - En el centro, L usa el 71 % de su capacidad (24,3 de 34,4) e I el 70 % (24,1).
  - En el peor caso (+35 %), L llega a 32,8 e I a 32,5 de 34,4: cabe, con unos 1,6 y 1,9 dp de margen.
- **Sin el recorte 1:** cabe en el centro (I al 76 %), pero en el peor caso I llega a 35,2 y se pasa en unos 0,8 dp. **Recomiendo adelantar el recorte 1 desde ya.** No requiere firma y su costo funcional es bajo: el tablero de reemisión solo hace falta para AP-05, que no tiene fecha, y hasta enero la lista sale de una consulta sobre el registro, que ya marca el nivel de cada emisión.
- **Con el reparto literal** (L hace toda la licencia, emisor y sello incluidos): L ≈ 24,3 + 11,3 + 4,35 + 1,25 ≈ 41 dp, **no cabe**, e I queda con unos 28 dp ociosos.
- **No se mueve ninguna pieza entre desarrolladores para absorber las remediaciones:** el exceso cae en I (SL y EM), y moverlo a L rompería la propiedad de archivos de 4.3 (`UsuariosService`, `GPOS.Migracion` y el repositorio del emisor).
- **El riesgo real está fuera de los dos desarrolladores:**
  - la toma nueva de la ola 3 unida antes del 2026-11-16 (segunda barrera);
  - AI-07 (especialista-pos y asesor legal) antes del 2026-11-16;
  - QA y frontend disponibles desde el 2026-11-23;
  - certificados de H-17 v2 (devops) antes del 2026-11-02;
  - **(v2)** el propietario cumple E-1 antes de AI-09 (S6-S7);
  - **(v2)** el auditor disponible en S9 para la revisión del emisor: si se atrasa, la primera licencia de pago pasa a enero (no afecta al corte);
  - **(v2)** la fase A de ADR-81: si no llega, S-02 a S-04 no se publican y rigen los verbos de `GPOS.Migracion` (no afecta al corte).

  Si una de las tres primeras se atrasa una semana, se recorta en este orden:

| Orden | Recorte | Ahorro | ¿Necesita firma? |
|---|---|---|---|
| 1 | **(v2: anticipado, recomendado desde ya)** Tablero, CSV de pagos y subida a Drive del emisor a enero; queda la emisión unitaria manual | ≈ 2 dp (I) | No |
| 2 | Correo diario de avisos a enero; la franja y el encabezado se quedan | ≈ 0,5 dp (L) | No |
| 3 | Franja en MAUI a enero; la Web se queda | ≈ 1 dp (frontend) | No |
| 4 | Opción reducida de Q-24: sin la autorización de regreso `autNivel`. Es segura porque `autNivel` va en `crit`, así que unos binarios que no la entienden rechazan el archivo | ≈ 1,75 dp (L) | **Sí** (Q-24 firmó el plan completo) |
| 5 | Segunda barrera solo en la toma nueva, no en la heredada `NumeracionService` (`src/GPOS.Core/Servicios/NumeracionService.cs:20`) [V], si la heredada sale de uso con el corte | ≈ 0,5 dp | Lo decide el Maestro con el plan del corte |

**No se recortan** las condiciones C-1 a C-4, la segunda barrera en la toma nueva, el sello con el padrón como fuente del cupo y su copia en disco, DL-05, DL-14, la ausencia de interruptores, H-17 v2, ni las condiciones de 10.3 para la primera licencia de pago.

**Cambio de calendario firmado:**
- Q-24 y Q-25 fijaban el inicio el 2026-11-02 y la publicación en la primera semana de enero de 2027.
- Con la decisión del 2026-10-14, el código se completa para el corte del 2026-12-15.
- **La primera licencia de pago ya no depende del hardware** (precisión (b)). Queda sujeta a 10.3. **v2:** AI-09 pasa de S3-S4 a S6-S7 (DL-13 previa), y la fecha más temprana de la primera licencia de pago es el 2026-12-14, tras la revisión del auditor. AP-01 y AP-05 quedan sin fecha, con la fecha de revisión de DL-12.
- El orquestador debe registrar el cambio (G-1.6).

---

## 12. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-B1 | La toma nueva (ola 3) no está unida el 2026-11-16 | Media / Alto | Recortes 2 y 3; L1b empieza por el *middleware* y la segunda barrera entra la última semana |
| R-B2 | AI-07 no llega a tiempo | Media / Medio | Las tres excepciones legales se marcan `Operativa`, que falla cerrado, y se agregan con la validación. La regla firmada no se viola: queda más restrictiva |
| R-B3 | PA-47: el fork da NULL para `gpos_sistema` | Media / Bajo | C-07 |
| R-B4 | H-17 v2 se atrasa y el modo Estricto no funciona con identidades distintas | Media / Alto | CR va primero en la carga de I; mientras tanto, Amplio en desarrollo (y en el DEMO, sin sellado de la API en Release: el instalador usa `GPOS.Migracion`) |
| R-B5 | Conflictos de edición entre los dos desarrolladores | Media / Medio | Propiedad de los archivos (4.3) y PR pequeños. Los cambios de contratos de la v2 los hace L en L1a-1 (sección 14), no I |
| R-B6 | El SDK de YubiKey no se comporta como el doble simulado | Media / Bajo | La alternativa PKCS#11 y la lista de aceptación. La API no cambia |
| R-B7 | Se publica en Release el proveedor de software o `gsf-lic-dev` | Baja / Crítico | 9.2 y 9.3; QA-L17 sobre Release |
| R-B8 | Clientes de pago firmados en Básico que no se reemiten tras la ceremonia | Media / Bajo | Registro con el nivel de cada emisión (tablero en enero); piso monótono (INV-4); DL-14 obliga a reemitir cada 200 días como máximo |
| R-B9 | La ceremonia se aplaza indefinidamente | Media / Medio | DL-12 con fecha de revisión: la aceptación vence (R-B14) |
| R-B10 | Las cifras de `[PSF]` repartidas entre el verificador y el emisor (4,0 y 2,6) no son exactas | Media / Bajo | Es un reparto mío; la estimación total no cambia |
| R-B11 a R-B15 | Riesgos de las licencias de pago en Básico y del equipo emisor de uso diario | Ver 10.5 | 10.5, 10.6 |
| **R-B16 (v2)** | I excede su capacidad en el peor caso si no se adelanta el recorte 1 | Media / Medio | Adelantar el recorte 1 (11.4) |
| **R-B17 (v2)** | La fase A de ADR-81 no llega antes del corte | Media / Bajo | S-02 a S-04 sin publicar; verbos de `GPOS.Migracion` (5.1) |
| **R-B18 (v2)** | La revisión del auditor del emisor se atrasa o encuentra hallazgos Altos | Media / Medio | La primera licencia de pago pasa a enero; el corte no depende de ella. Revisión de `GPOS.Criptografia` adelantada a H-2 |
| **R-B19 (v2)** | Los clientes anuales tienen que cargar un archivo dos veces al año mientras dure el nivel Básico y no haya agente | Alta / Bajo | Aviso «renovar el archivo» (`AvisoDias`); emisión semestral programada en el emisor; desaparece con la ceremonia (firma Avanzada) o con L4 |

---

## 13. Lo que sigue requiriendo firma o acción del propietario (nada de esto queda firmado aquí)

La hoja de firma la rehace el arquitecto-maestro. Esta tabla dice qué recomienda la v2 y **qué condición tiene que constar** en cada DL, según `[SEG]` §9.

### 13.1 Firmas nuevas que propone este documento (v2)

| # | Decisión | Recomendación | Condición que debe constar (v2) | Costo |
|---|---|---|---|---|
| **DL-01** | Padrón de sellos con MAC contra la repetición (2.3). Precisa ADR-58, punto 9, y `[DAT]` 6.3 | **Sí** | **(a)** El consumo del cupo se calcula desde las entradas no SUPER del padrón verificado, no desde las columnas; cada entrada lleva el nivel; el padrón se actualiza por diferencias y solo con acciones de la API (o los verbos de `GPOS.Migracion`); una fila borrada o alterada sigue contando hasta que el SUPER la purgue con motivo y segundo factor (S-04). **(b)** Copia completa del padrón en el disco; prevalece la mayor versión que verifique | 1,6 dp en SL (v1: 1,0) |
| **DL-02** | Las cuentas iniciales y el sellado inicial los hace `GPOS.Migracion sistema --cuentas-iniciales` (SH-3). Precisa SEC-07 y SES-16 | **Sí** | **En una compilación Release, ningún modo (tampoco Amplio) sella ni crea cuentas al arrancar.** Con una licencia vigente de `anillo` `Produccion` o `Beta`, la API no arranca en Amplio | 0,85 dp (v1: 0,5) + 0,25 devops |
| **DL-03** | El RNC de la empresa solo lo cambia el SUPER, con motivo y segundo factor (S-03); el ADMIN recibe 409. **Cambia lo que ve el ADMIN** | **Sí** | S-02, S-03 y S-04 no se publican antes de unir la fase A de ADR-81; mientras tanto, verbos de `GPOS.Migracion` en el servidor. S-03 es idempotente y el motor solo da por vigente el cambio cuando el RNC de la empresa es igual a `RncNuevo` | 1,25 dp (v1: 0,75) + ajuste de pantalla |
| DL-04 | Los eventos de la licencia y del sello van a `BitacoraSeguridad` (ADR-81) hasta que exista `BitacoraSistema` (ADR-37) | **Sí** | — | 0,5 dp |
| **DL-05** | El sello cubre la huella del `PasswordHash` (SH-5) | **Sí, obligatoria** (v1: opcional) | Y, en los SUPER, el estado «factor dado de alta». Sin la variante con `SelloSeguridad` | 0,75 dp |
| ~~DL-06~~ | *Retirada:* la sustituye la precisión firmada (b) de ADR-62 / AP-05 | — | — | — |
| **DL-07** | Reparto: el desarrollador de identidades toma SL, CR, RN y EM (11.2) | **Sí** | Revisión de código del auditor sobre EM y `GPOS.Criptografia` antes de la primera licencia de pago. Recorte 1 anticipado (11.4) | ≈ 1,0 dp del auditor |
| **DL-08** | Calendario: el código de la licencia se completa para el corte; sustituye las fechas de Q-24 y Q-25. Con (b), la primera licencia de pago queda sujeta a 10.3, no al hardware | Registrar | AI-09 en S6-S7; primera licencia de pago no antes del 2026-12-14 | — |
| DL-09 (condicional) | Opción reducida de Q-24, solo si hace falta el recorte 4 | Solo si se confirma un atraso | — | −1,75 dp |
| **DL-10** | Respaldo de `s1` frente a la **pérdida** (R-B12). **(a)** Llave Básica de reserva `gsf-lic-s1r`, activa, en el TPM de **otro** equipo; o **(b)** `s1` y su reserva en dos YubiKey 5 no FIPS con toque obligatorio (SEG-L2-23) | **Sí; (b) si el propietario acepta USD ≈ 110** [I], porque además baja R-B13 | Para (a): el segundo equipo no es de desarrollo ni ejecuta agentes; cumple E-1 a E-15; la cuenta de `s1r` queda deshabilitada salvo en la prueba trimestral y en una emergencia; el PIN lo custodia otra persona (AP-02) o un sobre precintado. En los dos casos: DL-10 cubre la pérdida, no el compromiso | (a) 0,5 dp; (b) el mismo de AI-09 y USD ≈ 110 |
| **DL-11** | La `aceptarHasta` de `s1` (y de `s1r`) la fija la versión que incorpora las llaves Avanzadas: publicación + 45 días. Precisa Q-16 e INV-1 | **Sí** | Recomendado: cofirma `s1` + `a1` en la reemisión de transición, con el tope de DL-14 | 0,75 dp tras la ceremonia |
| **DL-12** | Fecha de compra de las YubiKeys y de la ceremonia (R-B14) | **Fijarla** | **Y fecha de revisión de la aceptación, como máximo 2027-03-31.** Al llegar sin ceremonia, la aceptación vence y se vuelve a firmar con la estimación de ese momento (sin detener la emisión) | USD 352, ya presupuestados |
| **DL-13** | Cuenta diaria del propietario estándar y cuenta administradora aparte en el equipo emisor | **Sí, obligatoria** (v1: recomendada) | **Previa a AI-09** (la generación de `s1`), no solo a la primera licencia de pago, con las condiciones E-1 a E-15 (10.6). Con DL-13 sola el riesgo sigue Medio-Alto; baja a Medio con el conjunto de 10.5 | USD 0; 0,75 dp de devops |
| **DL-14 (nueva)** | **Tope de vigencia de las licencias sin firma Avanzada propia:** cada `vence` ≤ `emitida` + 200 días; si no, 422 `LICENCIA_VIGENCIA_BASICA`. El emisor Básico emite a los clientes anuales archivos semestrales. Precisa ADR-62 e INV-1 | **Sí** | Se verifica en la API (reglas de aceptación, L1a-2) y en el emisor. Es condición de la primera licencia de pago y del texto adaptado de AP-04 | 0,25 dp (L1a-2) + 0,1 dp (EM) + 0,1 dp (QA) |

### 13.2 Condiciones ya firmadas que siguen abiertas

| # | Qué | Quién | Estado o fecha |
|---|---|---|---|
| **AP-01 (CP-1)** | Compra de las cuatro YubiKey 5 FIPS 140-3 y ceremonia con el guion de 10.1 | Propietario y devops | **Sin fecha**, salvo la de DL-12; ya no condiciona la primera licencia de pago (precisión (b)) |
| AP-02 | Custodio suplente de `lic-b1`, `upd-b1` y Authenticode | Propietario | Antes de la ceremonia. Si se firma DL-10 (a), conviene designarlo ya para custodiar el PIN de `s1r` |
| **AP-03** | Procedimientos escritos y ensayados, **adaptados a Básico**: compromiso y pérdida de `s1`, ausencia del titular y E-15 | Devops con el propietario | **Antes de la primera licencia de pago** |
| **AP-04** | Aceptación escrita de **CP-4** y **CP-5** y de un **texto adaptado de P-F1 / FY-15 y de R-L11 / R-F11** con las mitigaciones retiradas y las sustitutas y el vector corregido de R-B13 (10.3). Lo redacta el Maestro | Propietario | **Antes de la primera licencia de pago** |
| AP-05 | Paso a Avanzado y reemisión en Avanzado de los clientes de pago (10.3) | Propietario y devops | Después de AP-01 |
| **AP-06** | Contrato de suscripción revisado por el asesor legal, con la cláusula del último período y la regla (iii) | Propietario y asesor legal | Antes del primer cliente |
| **CI-7 / AI-07** | Validación legal de las tres excepciones de LV-12 | Especialista-pos y asesor legal | **2026-11-16** (antes de clasificar las rutas) |
| AI-08 | R-E11 (a) a (s) en verde sobre Release antes de la primera licencia Básica | QA | S8, antes de la primera licencia, sea del DEMO, Beta o de pago |
| **AI-09** | `s1` en el TPM de la cuenta dedicada del equipo principal, con acta y las condiciones de 10.6 que le corresponden | Devops con el propietario | **v2: solo después de cumplir DL-13 (E-1)**; previsto en S6-S7. **No generar `s1` antes** |
| — | **Revisión de código del auditor-seguridad sobre EM y `GPOS.Criptografia`** (SEG-L2-08) | Auditor-seguridad | Criptografía tras H-2; EM en S9 |
| — | **Registro de las precisiones firmadas (b) y (c)**: ADR-62 / AP-05 y Q-19. Revisión de FY-15 / P-F1 para el alcance nuevo | Arquitecto-maestro y documentador | Antes de la primera licencia de pago |
| — | Precisión de ADR-58 «licencia por empresa contando usuarios» y cláusula de módulos | Arquitecto-maestro → propietario | Por preparar; hasta entonces rige la suma de cupos |
| — | ADR-82 (RG-14) | Arquitecto-maestro → propietario | Por preparar |
| — | Activar `contained database authentication` en la PC A para la suite `Rg14` (`[DAT]` 3) | Propietario o devops | Antes de PA-12 |
| — | Certificado del servidor y certificado de recuperación de H-17 v2, con la custodia de Q-22 | Propietario (custodia) y devops | Antes del 2026-11-02 para CR |

---

## 14. Impacto en L1a-1 (rama `a/lic-l1a-1`, en construcción)

Contrastado, solo lectura, con la copia de trabajo `GPOS-NG-lic` (cambios sin confirmar sobre `ad6015d7`): `src/GPOS.Contracts/Licencia/{CodigosLicencia,FormatoLicencia,LicenciaDtos}.cs`, `src/GPOS.Criptografia/Jws/{ContratosJws,ConjuntoLlaves}.cs`, `src/GPOS.Criptografia/Llaves/LlaveGsf.cs` [V, sin confirmar: el estado puede haber avanzado].

**La lógica del verificador no cambia.** No se agrega la regla de `s` bajo (5.2), y `ResultadoJws` ya devuelve `Contenido` y `Firmas` con el `Nivel` del recurso, que es todo lo que necesitan DL-14 y la identidad por contenido. Los cambios son de contratos y de pruebas, y conviene hacerlos **antes de unir L1a-1** para no abrir un segundo PR sobre los mismos archivos.

| # | Archivo | Cambio | Origen | ¿Bloquea la unión? |
|---|---|---|---|---|
| **L1-1** | `LicenciaDtos.cs` | `SolicitudLicenciaDto` agrega al final `long? SecVigente, Guid? LidVigente, string? Sha256ContenidoVigente` | SEG-L2-09 | Sí, si se une antes: cambiaría la forma de L-06 |
| **L1-2** | `LicenciaDtos.cs` | `CargaLicenciaDto.Sha256` pasa a llamarse **`Sha256Contenido`** y su comentario dice «SHA-256 de los bytes del contenido (payload decodificado), no del archivo» | SEG-L2-18 | Sí (renombre de contrato; barato ahora) |
| **L1-3** | `LicenciaDtos.cs` | Nuevo `PurgarEntradaPadronRequest(string Motivo, string CodigoSegundoFactor)`. `MotivosCuentaSinSello` agrega `FilaAusente`; el comentario de `FueraDePadron` deja de decir «pendiente de firma» solo cuando se firme DL-01 | SEG-L2-01 | No (aditivo) |
| **L1-4** | `CodigosLicencia.cs` | Nuevos `VigenciaBasica = "LICENCIA_VIGENCIA_BASICA"` (422, DL-14), `PadronSinEntrada = "PADRON_SIN_ENTRADA"` (404) y `UsuarioConFila = "USUARIO_CON_FILA"` (409) | SEG-L2-02, SEG-L2-01 | No (aditivo) |
| **L1-5** | `ConjuntoLlaves.cs` | El constructor es `internal` (`ConjuntoLlaves.cs:22` [V]). El emisor, que está en otro repositorio, necesita construirlo desde el `LlavesGsf.json` publicado para verificar después de firmar. Agregar una **fábrica pública** que lea y valide los bytes del recurso con las mismas reglas que `RecursoLlavesGsf` (por ejemplo, `ConjuntoLlaves.DesdeRecurso(ReadOnlySpan<byte> json)`), sin incluir nunca las llaves de desarrollo en Release. No usar `InternalsVisibleTo` hacia el emisor | SEG-L2-19 | No; la necesita EM en S8 |
| **L1-6** | Pruebas de `tests/GPOS.Tests/Licencia` (o `Criptografia`) | Vectores nuevos: (a) firma maleada (r, n − s) de un archivo válido: **verifica** y devuelve el mismo `Contenido` (documenta por qué la identidad es por contenido); (b) `r` o `s` con ceros a la izquierda en P1363 de 64 bytes: verifica; (c) firma de 63 o 65 bytes: rechazo | SEG-L2-18, SEG-L2-19 | No |
| **L1-7** | Datos de prueba (licencias de ejemplo) | Que todas las licencias de prueba «válidas» cumplan `vence ≤ emitida + 200 días`; si no, fallarán en L1a-2 con DL-14. Al menos un vector con `vence` = `emitida` + 201 días para L1a-2 | SEG-L2-02 | No |
| **L1-8** | Prueba de igualdad de códigos | La prueba que compara `CodigosJws` con `CodigosLicencia` no cambia: los códigos nuevos son de las reglas de aceptación y de las rutas, no del verificador | — | — |

**Sin impacto en L1a-1:** el padrón y el sello (SL, de I), L-08 (L1b), S-03 idempotente (RN y L1a-3), la API que no arranca en Amplio (L1a-4), las reglas del emisor y todas las condiciones E-1 a E-15.

**Costo:** unos 0,1 dp dentro de L1a-1 (ya contado en 11.2).

---

## Supuestos

1. **El desarrollador de identidades no tiene otras tareas asignadas hasta el corte**, salvo RG-14. Si tiene otras (por ejemplo, el segundo PR de H-11), el reparto DL-07 se rehace y vuelve a no caber.
2. Factor productivo 0,8 y feriado el lunes 9 de noviembre [I].
3. QA, frontend y devops están disponibles en las semanas de 11.3; **el auditor-seguridad, en H-2 y en S9** (v2).
4. La sintaxis de `ykman`, el modo FIPS de la serie 140-3, el comportamiento del SDK de Yubico, la política de PIN por uso del proveedor TPM de CNG, la ruta `PCPKSP`, el uso del *blob* desde otra cuenta administradora, los eventos 5058/5061 y la regla de firewall por usuario son [I]; se fijan en el ensayo y en AI-09.
5. El reparto de las 1,32 sp de `[PSF]` entre el verificador y el emisor (unos 4,0 y 2,6 dp) es mío.
6. Las cifras de `[DAT]` y `[LIC]` son las firmadas (±35 %). Las de las remediaciones de la v2 son de `[SEG]` §8, con mis ajustes donde difieren (registro de cambios) [I].
7. Lo que dice hoy el propietario prevalece sobre `[LIC]` 0.10 («compradas el 2026-10-06») y sobre Q-19 (a). Las precisiones (b) y (c) las recibí del coordinador como firmadas en la sesión de A del 2026-10-14; no vi el texto firmado.
8. Hay un segundo equipo con TPM 2.0 que no es de desarrollo ni ejecuta agentes, para DL-10 (a) [I]. Si no lo hay, DL-10 (b) es la opción.
9. `feature/modelo-ng` ya está en `59921ba0`. Las citas de código son de `768f0a61`; las rutas de los archivos citados existen en las dos.
10. **(v2)** CNG, el proveedor PCP del TPM y la YubiKey no normalizan `s` en ECDSA [I]; es la base del rechazo de la regla de `s` bajo (5.2).
11. **(v2)** El estado de L1a-1 de la sección 14 es el de la copia de trabajo sin confirmar que leí hoy; el desarrollador puede haber avanzado.
12. **(v2)** El precio de la YubiKey 5 no FIPS (unos USD 55) es de lista y no está verificado.
13. **(v2)** El refresco semestral de PA-8 es compatible con 200 días [I, como en `[SEG]`].

### Cierre
- Estado: Completado. Versión 2 del blueprint con los 23 hallazgos de `[SEG]` respondidos: 21 aceptados, 2 aceptados con ajuste (SEG-L2-12 y SEG-L2-18) y ninguno rechazado; los tres Altos (SEG-L2-01, 02 y 03) quedan remediados en el diseño. El paso de `[SEG]` a «Aprobado con observaciones» depende de la lectura de diferencias del auditor y de la hoja de firma del arquitecto-maestro. DL-01 a DL-14 siguen Pendientes de firma (DL-06, retirada).
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (v2, mismo archivo).
- Supuestos: los trece de la sección «Supuestos» (10 a 13, nuevos).
- Decisiones candidatas a ADR:
  - **ADR-83 · Sello de habilitación de cuentas con padrón protegido como fuente del cupo** (DL-01 con (a) y (b), DL-02 con la regla de Release, DL-05 obligatoria con el estado del factor; SH-1 a SH-8). Precisa ADR-58 (punto 9), ADR-36 (R-3), ADR-68 y SEC-07. *Descartadas:* limitar por antigüedad en exceso de cupo, las revocaciones en la bitácora, reconstruir el padrón desde las filas, sellar los permisos granulares y usar el `SelloSeguridad` en el sello.
  - **ADR-84 · Emisión en nivel Básico sin fecha de fin, con equipo emisor de cuenta dedicada y proveedor de llave intercambiable** (secciones 9, 10.5 y 10.6; DL-10 a DL-14; E-1 a E-15; caducidad de la aceptación). Recoge las precisiones firmadas (b) y (c), y precisa ADR-61, ADR-62, Q-16, Q-19 e INV-1. *Descartadas:* mini-PC dedicado (por el propietario), firmar con la llave real en desarrollo, fecha fija de caducidad de `s1`, topes de 62 y de 400 días.
  - **Precisiones, no ADR:** ADR-59 / NV-07 (fila MAC e idempotencia, DL-03); ADR-81 (bitácora común y rutas del SUPER condicionadas a su fase A); ADR-60 (clase de la ruta, C-02 y C-09); `[LIC]` 3.5 (carpeta de ADR-77, C-03); `[LIC]` 3.1.1 punto 7 (identidad de «ya aceptado» por el contenido).
- Entregas a otros agentes:
  - **auditor-seguridad:** lectura de diferencias de la v2 (registro de cambios, 2.2, 2.3, 5.1, 5.2, 8, 9.2, 10.3, 10.5, 10.6 y 13.1), en especial el ajuste de SEG-L2-18 (identidad por contenido en lugar de `s` bajo) y el de SEG-L2-12 (verbos provisionales); después, revisión de código de `GPOS.Criptografia` (tras H-2) y de EM (S9).
  - **arquitecto-maestro:** hoja de firma DL-01 a DL-14 con las condiciones de 13.1; texto adaptado de P-F1 / FY-15 y R-L11 / R-F11 (AP-04) con el vector corregido; ADR-83 y ADR-84 con sus precisiones; registro del cambio de calendario (AI-09 en S6-S7, primera licencia de pago desde el 2026-12-14).
  - **desarrollador-backend (L):** cambios L1-1 a L1-8 de la sección 14 **antes de unir L1a-1**; DL-14 en L1a-2; L1a-3, L1a-4 y L1b según 4.1.
  - **desarrollador-backend (I):** SL con el padrón como fuente del cupo, copia en disco y DL-05; RN con verbos provisionales e idempotencia; EM con las reglas 5 a 8 de 9.2; recorte 1 anticipado.
  - **arquitecto-datos:** entrada del padrón con el nivel; `UX_Licencias_Aceptada` sobre el SHA-256 del contenido (con el del archivo como dato informativo); límite del sello frente a los permisos granulares en el modelo de amenazas de `[DAT]` 6.2; condición `CUENTA_SIN_SELLO` con `FilaAusente` y diferencia de versión base/disco en S4.
  - **devops:** E-1 a E-15 con el reparto «antes de AI-09» / «antes de la primera licencia de pago»; compilación reproducible del emisor; instalador del DEMO con `GPOS.Migracion sistema --cuentas-iniciales` y sellado inicial; AP-03 adaptado; DL-10 (a) o (b).
  - **qa-automatizado:** casos de 11.2 (variantes de PA-45, retroceso del padrón con disco, Amplio en Release, firma maleada, DL-14, S-03 con fallo inyectado, orden sello→contraseña) además de los de la v1.
  - **desarrollador-frontend:** S-01 en la Web; S-02 a S-04 solo después de la fase A de ADR-81; L-08 fuera de la vista del ADMIN; aviso «renovar el archivo».
  - **orquestador:** plan de 11.3 v2, recorte 1 anticipado y dependencias externas de 11.4.
- Próximo paso recomendado: que el desarrollador L incorpore L1-1 a L1-8 antes de unir L1a-1, que el auditor haga la lectura de diferencias de la v2 y que el propietario cumpla DL-13 (E-1) antes de cualquier intento de generar `s1`.
