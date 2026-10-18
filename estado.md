# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene el equipo coordinador (desde el 2026-10-09, el equipo nuevo con B).

## Equipo A (PC A — equipo de soporte desde el 2026-10-09)
- **2026-10-18, tarde (sesión nueva; encargo H-L1/H-L2 de B):** **PR #76** (`a/hl-falla-cerrada-linux` @ `c7f3f2ba`, sobre `322b21d6`). Fuera de Windows, la API, `GPOS.Migracion` y la Web no arrancan con ninguna configuración (H-L1); `CarpetaAnillo.Crear/Comprobar` y `AlmacenLicenciaDisco.Preparar` fallan cerradas (H-L2). En Windows no cambia nada. **Alcance ampliado:** también se niega el arranque con certificado, no solo sin él; B puede acotarlo si prefiere. GPOS.Tests 56/56 y GPOS.Web.Tests 14/14 dirigidas. Seguridad: Aprobado con observaciones (SEG-HL-01 y SEG-HL-04 ya corregidas en el segundo commit; SEG-HL-02, SEG-HL-03, H-L3 y H-L5 quedan para la tanda LN, hoy inalcanzables). Sin migraciones ni EventId nuevos. Aviso `2026-10-18-pr76-hl1-hl2`. **A sin tareas en curso que no dependan de B.**
- **2026-10-18, tarde:** **PR #75** (`a/rsv-anillo-mantenimiento` @ `d60bb7d3`, sobre `322b21d6`): RSV-F1 a F4, RSV-06/08/11/12, el defecto de `ComandoSellos` y RSVB-01/04-06. 863/0/1 dirigidas. Seguridad: Aprobado con observaciones; la relectura está en curso. RSVB-02 y RSVB-03 quedan para el Maestro de B. EventId 4723-4728 y 4734 usados (siguiente libre: 4729). Aviso `2026-10-18-pr75-rsv-f1-f4`.
- **2026-10-18, mañana:** hallazgo `Un_RESTORE…` atendido: no es DL-22, es la carrera de `SINGLE_USER` (3101). **PR #74** (`a/restore-3101-reintento` @ `5da82ac3`, solo la prueba, reintento ante 3101). Acuse de las uniones y de las firmas DB-7/RSV. **En curso: PR de RSV-F1 a F4** sobre `4e094323` (EventId 4723). Aviso `2026-10-18-hallazgo-restore-3101-pr74`.
  - **#58 @ `59417c45`** rebasado sobre el #57 nuevo (`36bfc36e`), sin conflictos; 233/0 dirigidas. Aviso `2026-10-18-pr58-rebasado-sobre-57`.
- **2026-10-18, madrugada (sesión nueva; hook del modelo por agente configurado):**
  - **#52 @ `1e56c5ec` y #55 @ `2f05721b`**, rebasados sobre `17ecc9b9`. Único conflicto: la lista de condiciones de `Rg14VerificarTests`. 51617 confirmado. Pruebas dirigidas 30/1/0; PA28 falla igual en la punta limpia (SQL 2019).
  - **Hallazgo:** el 51616 está en el #48 y en el #67 (y en lo apilado encima). A propone 51618 para el #67 en el paso 6.
  - **Emisor tras el #65:** submódulo a `17ecc9b9` (`a80cf9b`) y `FormatoLicencia.Autorizacion` como fuente única (`8ce6cd7`); 95/95 en Debug y en Release.
  - Aviso `2026-10-18-pr52-55-rebasados`.
  - **#45 @ `948bdda9`**, rebasado sobre `17ecc9b9` y con base `feature/modelo-ng` (antes `a/reimpresion-post`). 616/0/1. Aviso `2026-10-18-pr45-rebasado`.
  - **#48 @ `5c7e5acd`:** migración regenerada como `20261018042207_Rg14ContencionMotivoAnulacion`, con su guion acumulado. **#60 @ `847f6e13`**, apilado sobre el #48 (ahora solo cambia un comentario; B decide si lo une o lo cierra). 244/0/2; **PA28 pasa en SQL 2019**. Aviso `2026-10-18-pr48-60-marca-regenerada`.
  - **#63 @ `e2f39aea`**, rebasado sin conflictos. 701/0/1. Aviso `2026-10-18-pr63-rebasado`.
  - **#67 @ `e0a99019`**, rebasado sobre el #63. El conflicto en `AdministracionService` se resolvió dejando los dos bloques. `ErrorOtroCambio` pasa a **51618**. 371/0/0. Aviso `2026-10-18-pr67-rebasado-51618`.
  - **#68 @ `34cf88fd`**, rebasado sobre el #67 sin conflictos. 792/0/1. Aviso `2026-10-18-pr68-rebasado`. **La cadena de A queda rebasada; faltan las uniones de B.** El #58 espera al #57 de C.
  - **PR #73, RS-01 a RS-03** (`a/rs-anillo-sellos` @ `e55a7478`, apilado sobre el #68). Incluye RSV-01, 04, 05, 07 y 09 de la revisión. Seguridad: Aprobado con observaciones. 810/0/1. EventId 4722 nuevo. Para el arquitecto: RSV-02, RSV-03 y RSV-10/13. Aviso `2026-10-18-pr73-rs01-rs03`. **A sin tareas en curso que no dependan de B, C o de una firma.**
  - **EM-01 hecha** (con la autorización del propietario en la sesión de A): `github.com/lfmendezb/GSF.EmisorLicencias`, privado, `main` @ `8ce6cd7`. La historia se revisó antes de subirla y no tiene secretos. Aviso `2026-10-18-em01-repositorio-emisor`.
- **2026-10-17, ~23:59 (cambio de sesión de A):** acuse de la unión `5b47e019` y de la hoja de B firmada. A toma la cadena sobre `5b47e019`: #52 + #55 → #45 (reapuntar su base, hoy `a/reimpresion-post`) → #48 con el #60 (marca > `20261015142020`) → #63 → #67 → #68 → #58; #59 y #65 en hueco. Después del #68, PR aparte RS-01 a RS-03; EM-01 espera la autorización del propietario. La sesión se reinicia para activar el hook del modelo por agente. Traspaso `traspasos/A/2026-10-17-traspaso-A-cambio-de-sesion.md`.
- **2026-10-17, tarde (orden del propietario: SL y el emisor):**
  - **PR #63, SL «Sello y padrón»** (`a/sl-sello-padron` @ `afc8bdb1`). Arquitecto: Conforme con correcciones (C-1 a C-5 aplicadas). Seguridad: Aprobado con observaciones (SL-01 y SL-03 a SL-10 corregidas). Pruebas dirigidas 1097/2/1; las 2 son del 12834. C corre la suite y conecta la fase A. Unir **antes de la fase A y después del 27-oct**. A firma: SL-F1 y SL-F2. Aviso `2026-10-17-pr63-sl-sello-padron`.
  - **Emisor** `GSF.EmisorLicencias` @ `34fbb49`, solo local: `autNivel` con `VerificarCompacto`. Seguridad: Aprobado con observaciones; EV-02 a EV-06 corregidas. 94/94 en Debug y en Release. A firma: EV-03 (`desde`). Aviso `2026-10-17-emisor-verificarcompacto`.
  - **PR #65, EV-01** (`7776c641`): modelo cerrado de la autorización en `FormatoLicencia`. 730/0/1; neutro para T6. Después de unirlo, A mueve el submódulo del emisor. Aviso `2026-10-17-pr65-ev01`.
  - **PR #67, RN «Cambio de RNC»** (`a/rn-cambio-rnc` @ `da474174`, apilado sobre el #63). Arquitecto: Conforme con correcciones (C-1 a C-3 aplicadas). Seguridad: Aprobado con observaciones (RN-01 a RN-05 corregidas). **RN-F2 (a) firmada por el propietario en la sesión de A** y aplicada (aviso `2026-10-17-firma-rn-f2`). 950/0/1. A firma: RN-F1. Aviso `2026-10-17-pr67-rn-cambio-rnc`.
- **2026-10-17, noche (retomado tras la pausa):**
  - **Modelo por agente** instalado (14 definiciones) y **hook** instalado; el hook entra en vigor al reiniciar la sesión.
  - **#59 @ `54749b4f`:** aviso `AnilloReintento` (4720) en el primer error de transporte (nota de B). 12/0/0.
  - **PR #68, SL-F1 (a) + SL-F2 (b) + SLF-01** (`a/sl-resellar-candado` @ `130306c0`, apilado sobre el #67). Arquitecto: Conforme con correcciones (aplicadas). Seguridad: Aprobado con observaciones (SLF-01 a SLF-07 corregidas). 798/0/3. Aviso `2026-10-17-pr68-sl-f1-f2`.
  - **Firmadas en la sesión de A:** RN-F1, SL-F1 (a), SL-F2 (b), SLF-01, el acta firmada por GSF antes de la primera licencia de pago (aviso `2026-10-17-firma-slf01-acta-gsf`) y EV-03 (a), ya construida en el emisor (`06d153e`, 95/95; aviso `2026-10-17-firma-ev03-emisor`). A no tiene firmas pendientes.
  - **Encargo a C** (orden del propietario): T-n sobre SL y RN, pantallas web, R-5 y diseño del acta firmada por GSF. Aviso `2026-10-17-encargo-para-c`.
  - **#68 @ `73418632`: AR-01 y AR-06** (revisión de seguridad del acta, de C). Una `SelloInicial` que no verifica cuenta como «falta» y se miran las licencias aceptadas. `SelloInicial` y `ReselladoPendiente` entran en la reprotección del anillo; el padrón queda aparte. Pruebas dirigidas 572/0/1. Seguridad: Aprobado con observaciones; RS-01 a RS-04 quedan para que B decida. **No revocar llaves hasta RS-01.** Aviso `2026-10-17-pr68-ar01-ar06`.
  - **A sin tareas en curso.** Esperan a B: uniones (#63 → #67 → #68 → #57; #59 y #65 en cualquier hueco), la suite oficial, el remoto del emisor y la decisión sobre RS-01 a RS-03.
- **2026-10-17, mañana:** **#59 @ `a1397a1d`:** la prueba D03 ya no depende de la carga. Los ayudantes de `MotorPrueba` repiten hasta obtener el error esperado (4060, -2 o 208), en lugar del 233 que da la memoria compartida bajo carga. Solo pruebas; 12/0/0 tres veces. C vuelve a correr la suite. Aviso `2026-10-17-d03-prueba-fragil-corregida`. **A sin tareas en curso:** lo demás espera a B (negativa (iii) de la vía (b), bajas S18/`--urgente`, uniones) o al 27-oct (marca del #48).
- **2026-10-17, madrugada (lo de C para A en la fase A de ADR-81):**
  - **#59 D-03:** reintento único del anillo (`d7b6e1c3`; 12/0/0).
  - **#60 D-04:** PA28 con `InstanciaContenidos` (`b4a87f09`). En SQL 2019 sigue el 12834 hasta el #48.
  - **#58 SEG-FA-06:** hoy no explotable; prueba de arquitectura (`045b136c`, apilado sobre `c/adr81-fase-a`; 55/0/0).
  - SEG-FA-10 ya está en el #45.
  - C corre las suites y PA28 en 2025. B decide la negativa (iii) de la vía (b).
  - Aviso `2026-10-17-d03-d04-seg-fa-06`.
- **2026-10-16, noche (firma de P-81A-16/17):** **#45 @ `330d5c71`:** `/liberar` y `/desbloquear` son Esencial, con alta en la lista aprobada (H-V4-02 cerrada para el #45); S-02 y S-04 sin `CodigoSegundoFactor`. 468 correctas. C no repite esas marcas en T-m. Aviso `2026-10-16-pr45-p81a16-17`.
- **2026-10-16, noche (decisiones del propietario sobre el #55 y orden de unión):**
  - **#55 @ `27ca3e2c`:** S18, `KILL` con `--urgente` y `ComprobarAsync` solo para `gpos_app_*`, con una prueba por punto. PA-30 3 de 3 (0 fallidas). La falla de `EsquemaPendienteAcceso` es previa (también sobre `81b00f2b`).
  - **#47:** base cambiada a `feature/modelo-ng` (unir #46 → #47).
  - Aviso `2026-10-16-pr55-tres-puntos-y-pr47-reapuntado`.
- **2026-10-16, noche (hallazgos de SC08 y suite de C del #55):**
  - **#49 @ `c565146e`:** SC8R-07 corregido (`eliminarrenglon` heredado ya no da «Autorizar»). Pruebas dirigidas 18/18. C puede rebasar el #56 sin choque.
  - **#55 @ `81b00f2b`:** PA-30 admite el 503 controlado de S-1 (con `Retry-After`) hasta el 1 %; cualquier otra respuesta sigue fallando. PA-30 2/2.
  - **Para decidir (B):** SC8R-03 (mensaje único) y SC8R-04 (contador aparte para autorizar), con la recomendación de A.
  - Aviso `2026-10-16-sc8r07-pa30-y-propuesta-sc8r03-04`.
- **2026-10-16, tarde (revisión de B `2026-10-16-revision-pr43-a-pr55`):**
  - **#55:** error 51616 renumerado a 51617 (`32a594ae`). Pruebas dirigidas 22/23; la que falla es el 12834 conocido sin el #48.
  - **#47:** rebasado directamente sobre el #46 (`38c4e88e`), con base del PR `a/reimpresion-post`. Pruebas dirigidas 632/0/1.
  - **Después del 27-oct:** regenerar la marca del #48.
  - **Bajas del #52 y el #55** (S18, `--urgente`, `ComprobarAsync`): esperan la decisión de B.
  - Aviso `2026-10-16-revision-b-55-y-47-hechos`.
- **2026-10-16:**
  - **PR #49 (SEG-CORP-08):** entregado en `f02cc777`, con seguridad «Aprobado con observaciones».
    - Suite oficial: 3117 correctas; solo fallan las 5 del 12834 y 3 por carga simultánea, que pasan solas.
    - Aviso `2026-10-16-pr49-seg-corp-08`.
  - **PR #55 (DL-22 b+, punto 7 cumplido):** `a/dl22-bmas` @ `afbfdb29`, apilado sobre el #52. Orden de unión: **#48 → #52 → #55**.
    - PA-30: 8 corridas, 0 peticiones fallidas.
    - RG-14/DL-22: 23/23.
    - Seguridad «Aprobado con observaciones»; S13 a S17 corregidas.
    - Espera la suite de C. Para B: decidir S18 y `--urgente` sin KILL.
    - Aviso `2026-10-16-pr55-dl22-bmas`.
  - **Firmas del propietario en la sesión de A (2026-10-16):** DL-22 (b+), la precisión de ADR-68 completa (SC08-01/03: 1a, 1-bis, 2i, 3, R-2 y 4a) y PD-1 (a) de ADR-86. C las registra en `c/adr-precisiones-2026-10-16` y construye SC08.
  - **Corte de luz (tarde):** al volver, todo en orden (git íntegro, bases ONLINE en las dos instancias, sin procesos huérfanos). La corrección S09 a S12 de DL-22 estaba completa sin commit; se recuperó.
  - **PR #52 (DL-22 a, salvo el punto 7):** `a/dl22-rotacion` @ `cd480ddd`. Unir **después del #48**.
    - Seguridad: S02 a S06 y S08 cerradas; relectura S09 a S12 corregida. S01 espera la firma.
    - Con el #48: RG-14/DL-22 28/28; suite oficial 3119 correctas, 8 fallidas (`EsquemaPendienteAccesoTests`; sola falla 1, también sin DL-22: previa).
    - Aviso `2026-10-16-dl22-relectura-s09-s12`.
    - **Punto 7 (PA-30 «ningún 500»):** no se puede cumplir con el `DENY` inmediato firmado. En SQL 2019, el `DENY CONNECT` rompe las sesiones abiertas con el error 916.
    - **Precisión firmada (b+)** por el propietario en la sesión de A: «Firmo (b+)». A la construye en `a/dl22-bmas`, apilada sobre el #52. B la registra en ADR-82. Aviso `2026-10-16-firma-dl22-bmas`.
  - **Delegado a C por el propietario:**
    - la construcción de SC08-01/03, después de la firma;
    - H-V4-01/02;
    - las suites oficiales de los PR de A.

    Aviso `2026-10-16-delegacion-a-c`.
  - **Esperan tu validación:** #43, #45, #46, #47, #48, #49, #52 y #55.
  - **A sin tareas en curso:** espera validaciones, la suite de C o un encargo nuevo.
- **2026-10-15, noche:**
  - **Vertical Corporativa:** diseño firmado (D-01 a D-28).
    - H-04 sigue abierta: el propietario envió las preguntas al contador.
    - Para B: registrar ADR-85 a 88 y las dependencias DB-1 a DB-8.
    - Aviso `2026-10-15-corporativa-diseno-firmado`.
  - **Hallazgo del núcleo SEG-CORP-08:** sigue sin dueño.
  - **Backup Tool:**
    - S-3a no coincide y B10 queda cerrado.
    - K-5 (purgar el historial) está preparada y la ejecuta el propietario.
    - No hacer push a Backup Tool hasta su aviso.
- **2026-10-15, tarde:**
  - **Unidos por B:** #24, #26, #21, #28, #36, #32, #33, #35, #40, #41, #39, #34 y #37 (`7898beeb`); #38 (A-N1) a `b/prep-27oct`. A-N2 y A-N3 las tomó B.
  - **Entregado (noche), todo esperando la validación de B:**
    - **#42 → #46 → #45 → #47:** L1b-2 rebasado (`5c9c6a30`), la reimpresión por POST (`f8e4f6bf`), la activación de `UseLicencia` (`063b2e88`) y la limpieza (`3284d576`). La suite oficial sobre #45 dio 3078 correctas; solo fallan las 5 de la contención.
    - **#43 (A-N4):** aplicado por el propietario en `.\SQLEXPRESS`. La instancia `.` quedó con la contención activada a mano.
    - **#44:** DL-02 (a), S0 y `verificar`. Suite oficial: 3083 correctas, las 5 de la contención y C10 intermitente.
    - **Documentos:**
      - hoja v2.13, con DL-04 (a) confirmada por el propietario en la sesión de A;
      - las precisiones de ADR y ADR-83 y ADR-84 en Aceptado, para que B los registre;
      - la hoja de PUB-06 (PB-1 a PB-7), para firma;
      - el dictamen sobre el bloqueo de los usuarios contenidos, con BL-03 (`gsf` con política) corregido en las dos instancias.
  - **12834:** precisión firmada por el propietario; corrección en el **#48** (`808cbe0a`), suite 3122 correctas. #46, #45 y #47 rebasados sobre `ce33b2a8` tras la unión del #42 (también se unieron el #44 y el DEMO de B).
  - **Espera a B o a una firma:**
    - el instalador del DEMO con `GPOS.Migracion sistema`, por definir si lo hace A o B;
    - los nombres `gpos_srv_*`;
    - Amplio frente a cualquier licencia de cliente;
    - el texto de `MensajeSinPermiso` en Amplio;
    - confirmar la lectura de C-08 en el #42.
  - **La PC A sigue con SQL 2019 Express**, por decisión del propietario.
- **2026-10-14, noche (tras el reinicio):**
  - **#29 y #30 unidos por B** (`e59d8de`), junto con #25 y #27.
  - **Rebase sobre `e59d8de` hecho** (encargo de B), listos para unir en orden **#24 → #26 → #28**:
    - #24 `a/h11-p7-candado` @ `51376b52` (`H11CandadoChequeras` → `20261014204007`): suite oficial 2507/0/21.
    - #26 `a/h11-sysdata-candado` @ `f96b9ab5`: H-11 + Arquitectura 243/0/2.
    - #28 `a/rg14-lote1` @ `c3323100`, base `a/h11-p7-candado` (`Rg14PrivilegioMinimo` → `20261014210613`, la última): suite oficial 2540/0/22. **B confirma o revierte** el Down de RG-14 que repone el GRANT BACKUP de H-11.
  - **Licencia del lote 2:** blueprint, hoja DL-01 a DL-14 y borradores ADR-82 a 84, todos v2.1, seguridad «Aprobado con observaciones». **Esperan firma** (DL-07 y DL-08 antes del 2026-10-16; DL-13 antes de generar `s1`).
  - **Para devops:** CR-04 b y CR-11 (publicación solo Release, sin recurso de desarrollo ni `GPOS.Tests.dll`); SEG-RG14-02 en PUB-06; contención y modo mixto en la instancia de pruebas (decisión del propietario).
  - **Sin tareas en curso:** espera uniones, firmas o encargo nuevo (siguiente natural: L1a-2/L1a-3 y lote 2 de identidades, tras DL-07). Suite oficial siempre con `--filter "Transicion!=Ola5&Transicion!=Defecto"`.
- **2026-10-14, tarde:**
  - **PR #25 abierto:** H-2 y H-3, con H-4, la parte de datos de H-6, H-7 y CT-1.
    - Rebasado sobre `4d376a6c`; ahora está en `c51ca8af`.
    - Suite: 2243 aprobadas, 5 fallidas y 18 omitidas.
    - Las 5 fallas ya ocurren en `feature/modelo-ng` sin H-2 (hallazgo para B).
  - **PR #24 en `cb8cbc88`:** suite 2260 aprobadas, 5 fallidas (las de la base), 18 omitidas; dos correcciones de pruebas. PDS-06 en curso.
  - **PR #26 abierto** (PR-2b, apilado sobre #24). PDS-06 cerrada: el propietario aceptó el costo (paso 2, `768f0a61`).
  - **PR #27 abierto** (H-6 de aplicación, apilado sobre #25). T3-12/RG-14: diseño y hoja D-01 a D-11 por firmar.
  - **Sin tareas en curso:** espera firmas o un encargo nuevo.
- **Retoma 2026-10-14 (Claude):**
  - **Corredor de pruebas desbloqueado:** la causa era `testhost.exe`; el arreglo es borrarlo tras compilar.
  - **PR #24 en `cd456f4c`:** SEC-H11-01 y guardas de arquitectura, 121/121.
  - **H-2:** 2165/8/18; 5 fallas sin explicar y pendiente de rebase; sin PR.
  - **PR-2b de H-11:** subido en `30606afc`; 123/123 sin SQL; pruebas con SQL pendientes.
  - **En pausa** por la actualización de Windows y el reinicio. Ver el aviso `2026-10-14-h2-suite-y-pausa-por-reinicio`.
- **Entrega 2026-10-11:** PR #24 actualizado a `3a3a6920`: impide escrituras de negocio con candado de empresa desconocido; 8/8 pruebas sin SQL y compilación con 0 errores. Ver aviso `2026-10-11-h11-candado-desconocido-corregido`. Revisión parcial, sin aprobación global ni unión; PDS-06 e integración pendientes.
- **Retoma 2026-10-11 por encargo del propietario:** Codex continúa los pendientes de A. H-2 en 37694341: compilación comprobada; validación SQL bloqueada (16 pruebas de NCF histórico, 0 aprobadas por acceso denegado al aprovisionar). Ver aviso `2026-10-11-retoma-h2-bloqueo-corredor`. PR #24 sigue sin unir; revisión de seguridad/PDS-06, H-11 sistema, H-6 aplicación y T3-12/RG-14 pendientes.
- **Actualizado:** 2026-10-10, 10:50
- **Unido a `feature/modelo-ng`:**
  - PR #6 a #11;
  - #14 (A-2, defectos cortos);
  - #16 (H-11, desbloqueo de una base restaurada);
  - #17 (A-4, RG-30);
  - #18 (A-3, RG-04 y RG-05).
- **Trabajando en (2026-10-10):**
  - **H-11, segunda parte** (`a/h11-p7-candado`, desde `e7f1f96`): P-7 (marca externa del último desbloqueo), el candado CR-01 en toda base restaurada y P-3 (cheque). Blueprint en curso con el arquitecto-software de A, coordinado con la fase A de ADR-81 de C (§8.8.6, P-81A-11 y 12).
  - **H-2 (opción a) y H-3** (`a/h2-ncf-historico`, desde `e7f1f96`): diseño de datos en curso, con el arquitecto-datos de A.
  - Después: la tanda H-4, H-6 y H-7.
- **Vigilancia:** tarea de Windows cada 10 minutos, en el minuto 5. Regla 9: aviso Entrega o Hallazgo por cada tarea.
- **Encargo de apoyo completado (2026-10-09):**
  - PR #6, demo ronda 2 (`a/mejoras-demo-ronda2`);
  - PR #7, H-RV-01/02 (`a/hallazgos-rv`);
  - PR #8, núcleo de caja, F7; seguridad aprobada (`a/nucleo-caja`);
  - PR #9, búsqueda sin tildes, F2/F4 (`a/busqueda-sin-tildes`);
  - PR #10, D-MVP-01, F1; seguridad aprobada, con R-a y R-b del propietario (`a/d-mvp-01`).

  Todos unidos el 2026-10-09 y el 2026-10-10.
- **Cambio de rol:** por los apagones sin UPS, el propietario pasó la coordinación al equipo nuevo (Equipo B restaurado, más robusto). A trabaja en ramas `a/...`, sube y abre PR, no une; conserva el rango de ADR 68-99 (aprobado por el propietario). Ver `avisos/A-a-B/2026-10-09-coordinacion-pasa-al-equipo-nuevo.md`.
- **Hecho el 2026-10-09:** factor de unidad, kárdex e interfaz (`3324e43` a `472d078`), UF-03 y OB-03, login sin HTTP 400, K1 unido y su pasada 2 (`59921ba`; GPOS.Tests 1.870/0, Web 448/448, MAUI 429/429); ADR-078 y ADR-81 (TOTP) en `master` (`3a2d0bd`).
- **Acuse (2026-10-09, 19:20):** recibido el encargo `2026-10-09-tareas-de-apoyo-para-a` (en orden: demo ronda 2 en `a/mejoras-demo-ronda2`, búsqueda sin tildes, núcleo de caja, H-RV-01/02) y sus reglas de apoyo. Recibidos también: la meta del MVP del 60 % (su definición queda en B, según el encargo), la suspensión de la documentación hasta el MVP, los hallazgos de reportes del tramo 2 (`rptsis` y `GPOS.Migracion` quedan en B), ADR-125, `COMANDERA` y los privilegios de cocina y Farmacia (sin acción ahora). A empieza cuando el propietario lo indique.
- **Traspasado al coordinador:** acuse y definición del MVP 60 %; T-57 del 14-oct y la meta 1; cierre de la ola 4; ADR-118/119 (T1, T2, T4); 3b y partida de `b/ola5`; `rptsis` y `GPOS.Migracion`; búsqueda sin tildes; tanda de núcleo de caja (reimpresión y redondeo del vuelto); tanda 3 (equivalencias, ≈19 sp); los «Pendientes del propietario» de este archivo. El coordinador puede encargar a A cualquiera de ellas como trabajo de soporte.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `feature/modelo-ng` | `59921ba` en origin; desde ahora la une el coordinador |
  | GPOS-NG | `master` | ADR al día hasta ADR-81; libres en el rango de A: 79, 80 y 82 en adelante |
  | GPOS-NG | `feature/mejoras-demo-ronda2` | `87b90f8`, subida hoy; mejoras del demo, ronda 2, sin unir |
  | GPOS-NG | `demo/2026-10-07` / `demo/2026-10-08` | Subidas hoy; base de las actualizaciones del DEMO |

## Equipo B (equipo nuevo — coordinador desde el 2026-10-09)
- **2026-10-18, mañana (sesión nueva de B):**
  - **PAUSA hasta el miércoles 21 (cuota de uso al límite; propietario):** sin tareas nuevas para A ni para C; terminan lo asignado y esperan. B deja correr la medición del #61 y el #71 con el mínimo de sesiones. Aviso `2026-10-18-pausa-hasta-miercoles-21`.
  - **Contexto corto (regla 10):** `CLAUDE.md` 19,5 KB (−42 %), memoria −9 entradas, 539 avisos archivados, `estado.md` de B recortado; vigilante con escritura atómica; Publicar no pisa cambios de otros. **Sí** a la corrección de C de `LongitudesColumnas`, con condiciones. Aviso `2026-10-18-contexto-corto-y-longitudes-columnas`.
  - **Regla nueva del propietario:** las sesiones de A, B y C trabajan con Sonnet 5.5 y esfuerzo medio, y sugieren Opus 5.5 en una línea para las tareas de riesgo. Aviso `2026-10-18-sesiones-sonnet-medio-escalar-opus`; memoria `sesiones-sonnet-medio-escalar-opus`.
  - **Encargo a C** (aprobado por el propietario): T2 de ADR-126 en PR pequeños (objetivo antes del 2026-11-02) y estabilizar las pruebas intermitentes bajo carga. Aviso `B-a-C/2026-10-18-encargo-t2-adr126-y-pruebas-intermitentes`.
  - **Medición del #61 y el #71 en curso** (`Medicion-61-71.ps1`, unas 6 h, máquina sola; base `322b21d6`, candidato `b/medir-cand` con #61 + #71 + N6-02E y LP-01). Sin suites ni compilaciones en LFMB hasta que termine. **Después:** unir el #75 (A), registrar el ADR de Linux (PL-01 a PL-15 firmada el 2026-10-18; **PL-10 cambiada a (a)** por el propietario en la sesión de B, aviso `2026-10-18-pl10-cambia-a-opcion-a`) y avisar a Backup Tool (H-L5). Encargo a A: H-L1 y H-L2 (aviso `2026-10-18-encargo-h-l1-h-l2`).
  - **Unidos #72, #56 y #69** (`feature/modelo-ng` = `322b21d6`; última marca `20261018153317`). **D0 de DB-7 FIRMADO** según la recomendación y registrado en `master` `06a7a7f4`. Quedan #61 y #71, que B mide ahora. Aviso `2026-10-18-unidos-72-56-69-y-d0-firmado`.
  - **D0 de DB-7 listo para firma:** blueprint v3 en `master` `c6c96828` (`docs/arquitectura/2026-10-18-db7-blueprint-v3.md`), modelo de datos `traspasos/B/2026-10-18-db7-d0-modelo-datos.md`, revisión de seguridad «Aprobado con observaciones» tras la relectura (`traspasos/B/2026-10-18-db7-d0-revision-seguridad.md`). **Hoja `traspasos/B/2026-10-18-hoja-firma-db7-d0.md`** (P-D0-01 a P-D0-D05, 12 puntos), pendiente del propietario. Unidos también #62 y #70 (`a960cfac`).
  - **Unidos #57 (fase A de ADR-81 con T-n), #58 y #74** (`feature/modelo-ng` = `55365806`); en la unión del #57, B ajustó dos pruebas por choque entre ramas (36 códigos de licencia; P9 con la marca vigente). Esquema de `GPOS_SYSDATA` en 5. **C rebasa #56, #69 y #72.** #62 y #70 en suite. **D0 de DB-7:** blueprint v3 y modelo de datos conciliados, en revisión de seguridad. Aviso `2026-10-18-unidos-57-58-74`.
  - **Unidos #51, #45, #48 + #60, #63 → #67 → #68 y #73** (`feature/modelo-ng` = `4e094323`); B regeneró el Designer y el guion del #48 en la unión. En cada suite oficial las fallas pasan solas. **C rebasa el #57, el #69 y el #72** sobre `4e094323`; después el #58 (A). **#61 y #71:** entran limpios, B los mide antes de unir. Aviso `2026-10-18-unidos-48-a-68-rebasar-57-y-69`.
  - **Unidos #52 y #55** (`feature/modelo-ng` = `2875f345`): suite oficial 3261/1/31; PA30 ya pasa; la falla (`RutasLicenciaHttpTests.Un_RESTORE…`) pasa sola 3/3 (hallazgo para A). El #55 cerrado con nota (base `a/dl22-rotacion`). Sigue el #51 de C. Aviso `2026-10-18-unidos-52-55`.
  - **Ola 5, auditoría UNIDA** (`feature/modelo-ng` = `1768f6a3`); marca `20261015211406` conservada; SQL de la evidencia a `Infraestructura/Motor` (CA-0.8). Suite oficial 3251/4/28, las 4 pasan solas; Web 699/0, Reportes 433/0, MAUI 602/0. Aviso `2026-10-18-unida-ola5-auditoria`. **El #48 regenera Designer, snapshot y guion sobre `1768f6a3`** (marca igual).
  - **`master` `f86f88f8`:** `CLAUDE.md` al día (T1 de ADR-118/119, 3b tramo 1, T1 de ADR-126, RG-14 lotes, CB-01, SE-01/02, firmas del 17-oct); notas del registro en ADR-82 (51616 a 51618) y ADR-83 (51618 y EventId 4722).
  - **Encargo a C** (aprobado por el propietario): 503 del #72 sin el nombre de la base para quien no es SUPER, rebase del #72 y reintento 1205/1222 en `verificar`. Aviso `B-a-C/2026-10-18-encargo-503-pr72`.
  - **FIRMADAS por el propietario (2026-10-18):** la hoja de DB-7 (según la recomendación; **DB7-06 con otro reparto: B construye DB-7, D0 a D6**) y la de RSV (RSV-F1 a F5 según la recomendación; el PR es de A, detrás del #73, antes del 2026-11-02). Registradas en `master` `9b38c947` (ADR-79 nuevo; precisiones de ADR-34 a 37, 39, 41, 58, 59, 81 y 83; decisión `docs/decisiones/2026-10-18-decision-db7-calendario.md`). **Punto de control de DB-7: 2026-11-20** (DB7-07); firma de la v1 el 2026-12-11. Avisos `B-a-A/2026-10-18-firmas-db7-y-rsv` y `B-a-C/2026-10-18-firmas-db7-y-rsv`.
- **2026-10-18, madrugada:** unidos **#59, #64 y #65** (`feature/modelo-ng` = `17ecc9b9`). Suite oficial 3237/4/28; las 4 pasan solas. Aviso `2026-10-18-unidos-59-64-65`.
- **2026-10-17, noche (sesión de B en LFMB):** **`b/prep-27oct` + #66 UNIDOS a `feature/modelo-ng` (`5b47e019`)**, por UN-01 (a). Hoja de B firmada (UN-01, BM-01, SE-01, SE-02, CB-01, EM-01, RS-01 y OR-01), registrada en `master` `fe42b415`. T6 en verde. Aviso `2026-10-17-union-prep27-hecha`.
- **Historia anterior:** [`estado-historia/2026-10.md`](estado-historia/2026-10.md).

## Equipo C (OSHIN-LEGION) — reactivado el 2026-10-16
- **2026-10-18, tarde:** **PR #81** (`c/t2b-archivo-instalacion`): T2 (b), archivo de instalación con solo claves permitidas en los cuatro procesos, guiones del DEMO y D-01; seguridad y devops revisados. **El #80 sube con el tope de descarga (S02): unir el #80 antes del #81.** Aviso `C-a-B/2026-10-18-entrega-pr81-t2b-y-orden-con-pr80`. Siguiente: T2 (c) con el arquitecto de datos, y C10.
- **2026-10-18, tarde:** **PR #80** (`c/t2a-opciones-rnc-dgii`): T2 (a) de ADR-126, `OpcionesRncDgii` con validación (C-01, C-02, O-4 y O-5), sin detener la API; aviso en la pantalla del padrón. 59/59 y Web paridad 1/1. Aviso `C-a-B/2026-10-18-entrega-pr80-t2a-opciones-rnc`. Siguiente: T2 (b).
- **2026-10-18, tarde (encargo de B):** **PR #79** (`c/longitudes-columnas-misma-conexion`): la corrección de `LongitudesColumnas` que B aprobó (lee por la conexión y la transacción de EF, en READ COMMITTED dentro de `sp_executesql`, con `Lazy<Task>`); las cuatro condiciones de B se cumplen; seguridad: Aprobado con observaciones, con LC-01 y LC-02 corregidas y LC-03 a LC-05 para B. Sin la corrección fallan 3/3; con ella pasan 30/30 tres veces, y F5 y CA_P7_06 2/2. Ya están abiertos el **#77** (pruebas de tiempo) y el **#78** (233/1205). C10 espera el mensaje de su falla. Aviso `C-a-B/2026-10-18-entrega-pr79-longitudes-columnas`. Siguiente: T2 (a), `OpcionesRncDgii`.

## Pendientes del propietario
_Puesto al día por B el 2026-10-18; lo anterior está en `estado-historia/2026-10.md`._
- **Decisiones:**
  - **número del ADR de Linux** (PL-01 a PL-15, firmada con PL-10 (a)): el rango de C (130 a 159) sigue congelado; ¿se descongela y es el ADR-130?
  - **PL-03:** qué equipo hace LN en enero de 2027 (B lo propone al registrar el ADR);
  - **de la licencia (15-oct):** C-3, C-2/C-4 (conocimiento), AP-04, la fecha de compra de DL-12 y el nombre del custodio suplente;
  - **H-04 de la vertical Corporativa** (ADR-87 Propuesto): espera la respuesta del contador.
- **Equipos:**
  - **LFMB (B):** registrar la tarea de Windows de la regla 8 (`herramientas\Registrar-VigilanciaAreaComun.ps1 -Equipo B -Minuto 2`); hoy B vigila desde la sesión;
  - **LAPTOP-DUMQQ5QK** (antiguo C): retirar su tarea de vigilancia y decidir si sigue como equipo de prueba del DEMO;
  - **OSHIN-LEGION (C):** diagnóstico del hardware (memoria, BIOS, controladores; 23 pantallazos en 7 días);
  - **máquina virtual Linux con TPM 2.0** para LS (cuando toque, enero de 2027).
- **Pruebas manuales:** Web y MAUI de la fase A de ADR-81 (#57 unido; el DEMO en Release pide el segundo factor al SUPER, R-25).
- **Backup Tool, NO LISTO para producción (2026-10-14):** 10 bloqueantes (B1 a B10; unos 2 sp); depende del propietario unir n01, firmar ADR-0004 y S-3a. Informe en Backup Tool `master` `3d936df`. H-L5 (llaves fuera de Windows) por avisar allí.
- **Contador:** la sección 7 de la hoja de la 3b (C-17), C-37 y C-38, y H-04 de la Corporativa.
