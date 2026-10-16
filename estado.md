# Estado de los equipos

Cada equipo actualiza **solo su sección** al publicar. Los pendientes del propietario los mantiene el equipo coordinador (desde el 2026-10-09, el equipo nuevo con B).

## Equipo A (PC A — equipo de soporte desde el 2026-10-09)
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
- **2026-10-15, tarde-noche:**
  - **Unidos a `feature/modelo-ng`, por decisión del propietario (`65d4324f`):** el **#42** (L1b-2) y **A-N3**.
    - Sin licencia cargada el cupo es 0: el DEMO se actualiza desde una rama anterior al #42 hasta tener `s1`.
    - El DEMO se publica ahora con `-Destino Demo`.
  - **`b/prep-27oct` (`fe5f08f8`)** trae la punta y corrige la lectura de plan de `Uf05PlanTests` (952 junto con Mvp).
  - **Pendiente:** la suite oficial completa y T6, con la máquina sola, antes del 27-oct.
  - Aviso `B-a-A/2026-10-15-unidos-42-y-a-n3-65d4324f`.
- **2026-10-15, noche (sesión nueva de B):** el propietario firmó según la recomendación las DL pendientes de la licencia (DL-01 a DL-05, DL-09, DL-11, DL-12, DL-15, DL-16, DL-18 a DL-22 con 2 min en DL-22, C-1, C-5 y las P de v2.2 a v2.4). Siguen pendientes C-3, C-2/C-4 (conocimiento), AP-04, la fecha de compra de DL-12 y el custodio suplente. Aviso `B-a-A/2026-10-15-firmas-dl-segun-recomendacion`. **`b/prep-27oct` rehecha sobre `7898beeb` → `855ea392`** (respaldo de la anterior en `b/prep-27oct-antes-rebase-15oct`): T1 `20261015010000`, 3b `20261015020000`, TI, #38 y un solo guion; Mvp 24/24 en las dos instancias. **A-N2 construida por B y unida (`799a5add`, `Uf05ForceSeek 20261015142020`)**; **A-N3 hecha** (`b/devops-publicacion` @ `e6457402`, sin unir; el DEMO se publica ahora con `-Destino Demo`); suite oficial completa sobre `855ea392`: **3115 correctas, 2 fallas de concurrencia (K1_01 y CP170, pasan solas) y 27 omitidas**; tras A-N2, una corrida reducida, y la completa otra vez antes de unir, junto con T6. Aviso `B-a-A/2026-10-15-prep-27oct-rehecha-sobre-7898beeb`.
- **2026-10-15, tarde:** unidos #40, #41, #39, #34 y #37 (`7898beeb`); #38 a `b/prep-27oct`; #42 rechazado (interruptor de UseLicencia, Estricto sin InstalacionId, Web sin migrar, DL-02). **Cambio de sesión de B:** traspaso `traspasos/B/2026-10-15-traspaso-B-cambio-de-sesion.md`.
- **2026-10-15:** unidos a `feature/modelo-ng` #24, #26, #21, #28 (`bc15304d`) y #36, #32, #33, #35 (`30b4d5b3`). Mvp 22/22 en las dos instancias; suite oficial sin fallas propias (PA30/PA40 fallan en LFMB por el modo «solo Windows»). #34 y #37 esperan los 3072 bits de H-17 v2. T6: criterios 1 y 2 en verde, faltan 2 corridas por lado (dispersión). Aviso `2026-10-15-unidos-24-26-21-28-36-32-33-35`.
- **2026-10-14/15, preparación del 27-oct (PQ-3):** `b/prep-27oct` (`cc4694d`, en GitHub) = punta + #24/#26/#21/#28 (pendiente) + T1 de ADR-118/119 (`20261015010000_NegativosTresNiveles`) + ola 3b tramo 1 (`20261015020000_Ola3bTransferencias`). Un solo guion.
  - **Corregido en la unión:** la migración de la 3b borraba la regla de H-4 en `CK_Autorizacion_Motivo` (Alto). También se ajustaron las pruebas de los conteos de numeración por el tipo TI.
  - **Pruebas:** suite oficial 2724 correctas; Mvp **24/24** en las dos instancias, **F10 incluido**; Numeración 638/638. Solo queda la falla de restauración de H-11, que espera la corrección de A.
  - **Pendientes:** T6 (medición de rendimiento con la máquina sola, unas 5 a 6 h); rehacer sobre la punta cuando A entregue H-11; unir el 27-oct si todo está en verde.
- **2026-10-14, cierre del día:**
  - **#24, #26, #21 y #28 integrados en local, sin publicar:** `b/integracion-pendiente-14oct` (`455a7c4`) en GitHub.
    - #21 (C-10) lo rebasó B con la marca `20261014205000`, entre H11 y Rg14 (`b/c10-compra-variable-tabla`).
    - Guion acumulado regenerado hasta `Rg14PrivilegioMinimo`; `Designer` de Rg14 alineado.
    - Web 649/649; MAUI 561/561.
  - **Bloqueo:** defecto de H-11. Tras un restore real con la API arriba, la empresa responde 500 de 5 a 60 s (`PoolBlockingPeriod` de SqlClient).
    - Por decisión del propietario, **A lo corrige primero en #24**, con su prueba de regresión y la validación del arquitecto.
    - Después B une #24, #26, #21 y #28.
    - Hallazgo `2026-10-14-hallazgo-h11-500-tras-restauracion`.
  - **Registrado en master `f7a87bf`:** precisiones de ADR-61 y ADR-62 (F-2 y F-3).
  - **Seguimiento:** `System.Security.Cryptography.Pkcs` 10.0.0, transitivo en `GPOS.Core`, con vulnerabilidad Alta y Moderada conocidas (GHSA-846f-f764-76mx, GHSA-2fmv-rv2c-59x7). Actualizar según la política de paquetes.
- **2026-10-14, noche:**
  - **Unidos a `feature/modelo-ng` `e59d8de`:** PR #29 → #30 (licencia L1a-1) y #25 → #27 (H-2, H-3 y H-6), los cuatro validados contra lo firmado.
    - Suite oficial del árbol integrado: 2470 correctas (2 fallas de entorno, en verde al repetirlas).
    - Web 636/636; MAUI 556/556; Mvp 22/22 en las dos instancias.
    - Aviso `2026-10-14-uniones-29-30-25-27-y-rebase-24-26-28`.
  - **Las «5 fallas de la base» de A** son pruebas `Transicion=Ola5/Defecto`, fuera del filtro oficial. La base `4ace678` está sana.
  - **Regla de marcas de migraciones:** siguen el orden de unión; la rama que llega después las regenera.
  - **Por unir, en orden:**
    1. #24 → #26 (A rebasa; H-11 con marca nueva);
    2. #21 (C rebasa; marca nueva; B corre el SQL);
    3. #28 (RG-14 lote 1, después de #24 por GRANT/DENY de BACKUP).
  - **Al propietario:** los 2 supuestos de #24, las 2 preguntas de #26, la hoja DL (DL-07 y DL-08 antes del 16-oct) y quién prepara ADR-82.
- **2026-10-14, tarde (B en el equipo LFMB, tras el traspaso de emergencia):**
  - **Unido a `feature/modelo-ng` `ad6015d`:** `b/demo-2026-10-10b`, `b/demo-revision-1` y la propuesta de `b/config-terceros`.
    - Mvp 22/22 en las dos instancias; Web 610/610; MAUI 538/538.
    - Aviso `2026-10-14-uniones-demo-config-terceros-adr126`.
  - **master `f5e73b0`:** ADR-126 registrado (libres de B: 127 a 129) y la lista de pruebas del DEMO 10b.
  - **T1 de ADR-126 unido a `feature/modelo-ng` `4ace678`** (después del reinicio del equipo y la actualización de SQL Server). Incluye:
    - la URL del padrón sin constante y las pruebas O-3;
    - Roboto local, sin Google Fonts;
    - la guarda `ValoresDeTercerosTests`.

    Cifras:
    - 151/151 en Arquitectura;
    - Web 610/610;
    - Mvp 22/22 en las dos instancias;
    - solución completa con Android, sin errores.

    Aviso `2026-10-14-t1-valores-terceros-unido`. **Siguiente:** T2. **Pendiente:** fijar la tanda de G-01 a G-03.
  - **Sin unir, por orden:** T1 de ADR-118/119 (27-oct) → `b/ola3b` → `b/ola5-auditoria`, que necesita la migración regenerada después de la 3b, `SecExportacion` en `Todas`, el rango por nodo, el documento AE-01 a AE-04 y la QA de AE-09 y AE-10.
  - **Entorno LFMB:** workloads de Android listos (propietario, 2026-10-14). Falta el origen NuGet local `C:\Users\lfmen\source\NugetLocalFeed`; se restaura con `--ignore-failed-sources`.
  - Vigilante (regla 8) sin armar, a la espera de la indicación del propietario.
- **Actualizado:** 2026-10-09, 19:10 (primera sesión en el equipo nuevo; sin agentes activos)
- **Coordinación:** confirmado el aviso `2026-10-09-coordinacion-pasa-al-equipo-nuevo`: B coordina (une a `feature/modelo-ng` y `master`, `CLAUDE.md`, manifiesto de pruebas, «Pendientes del propietario» y publicación de `memoria/` y `agentes/`). A trabaja en ramas `a/` y no une.
- **Entorno comprobado:** .NET SDK 10.0.401; 16 núcleos y 31 GB de RAM (límite de agentes por acordar con el propietario); paquetes de `gsf-local` con huellas correctas; carpetas `GPOS-B-ola5-construccion`, `GPOS-B-ola5`, `GPOS-B-verticales` y `GPOS-B-admcloud` creadas y al día con GitHub. `GPOS.Reportes.Tests` en `b/ola5` (`781b1eb`): 216/216 contra la instancia predeterminada (SQL Server 2025); contra `.\SQLEXPRESS` falla la creación de bases por permisos de su carpeta de datos (lo corrige el propietario).
- **Siguiente:** retomar la ola 5, tramo 2 (`b/ola5-tramo2-wip`, `f1d6025`), según `traspasos/B/2026-10-09-traspaso-B-corte-de-luz.md`; después, lo heredado de A (meta del MVP, T-57 del 14-oct, cierre de la ola 4, 3b).
- **Avisos de A vigentes:** `rpt-rptc-firmado`, `uf03-ob03-aprobados`, `ux-firmado` y O-1 a O-3 de `k1-pasada2-unida`.

### Registro anterior (PC B, madrugada del 2026-10-09)
- **Hecho el 2026-10-08 y el 2026-10-09:**
  - **K1 del KDS construido** en `b/kds-k1` (desde `feature/modelo-ng` `2078a08`):
    - SD-01 `a4b1a9b`, `Propiedad` `df79075`;
    - registro de dispositivos `dc40169`;
    - pantallas `ae6b7f6`, con QRCoder 1.6.0 aprobado por el propietario;
    - estación como servicio de Windows `44098a4`, con su informe `0c080ae`;
    - revisión de seguridad de B «Aprobado con observaciones» `8920d7a`, con correcciones en curso.
  - **`[LIC]` v3.2.5** en `b/lic-v32` (`dbf5048`): precisión de ADR-58 completa, dos confirmaciones del auditor; sin preguntas del propietario. Pedida la unión a master.
  - **Hoja de los conectores firmada.** En master `afa7519`: ADR-123 (ambiente productivo de todo conector) y ADR-124 (conector Polaris, sin puerta comercial). Tres repositorios privados (precisión de ADR-108 y 124, `2931106` y `f680ccb`): `GPOS-NG-AddOn-Kit`, `GPOS-NG-AddOn-IQS` (pasado a privado) y `GPOS-NG-AddOn-Polaris`.
  - **Guardas por superficie de los conectores** (`b/conector-admcloud-diseno` `17baccb`).
  - **Ola 5:** consultas de los reportes 17, 20 y de valuación; respuesta contable del CNT dentro de AU-11; PQ-01, 03, 04 y 05 cerradas (`b/ola5-diseno` `827a42f`). Defecto OB-03 del conteo avisado a A.
- **En curso:**
  - correcciones de seguridad de K1 (K1-01 a K1-07);
  - plan de extracción del kit y estructura de Polaris;
  - ventanas de las verticales ajustadas a FactorUnidad;
  - blueprint del KDS ajustado con lo de K1.
- **Siguiente:** construir el kit común y el conector Polaris (después de K1); ajustar las vistas de la ola 5 (TC-01 a TC-05) cuando A avise `Ola4FactorUnidad`; la ola 5 en `b/ola5` cuando A avise el commit de la 3b.
- **Espera de A:**
  - revisión de SD-01 y `Propiedad`;
  - unir `[LIC]` v3.2.5;
  - la cola de ADR-114 (filtro SD-08 de K1);
  - la acción previa de ADR-77 punto 3 en `instalador/AgenteImpresion`;
  - el commit de `Ola4FactorUnidad` y TC-03;
  - el commit de partida de `b/ola5` (3b);
  - las 6 pruebas que fallan en `2078a08`;
  - el párrafo de ADR-123 y 124 en `CLAUDE.md`;
  - OB-01 a OB-04 del conteo.
- **Ramas vivas:**

  | Repositorio | Rama | Estado |
  |---|---|---|
  | GPOS-NG | `b/kds-k1` | K1 construido; correcciones de seguridad en curso; se une tras la revisión de A de SD-01 y con SD-01 en master |
  | GPOS-NG | `b/lic-v32` | `[LIC]` v3.2.5, lista para unir |
  | GPOS-NG | `b/conector-polaris-diseno` | Diseño de Polaris y hoja firmada (ya copiados a master) |
  | GPOS-NG | `b/restaurante-kds-diseno` | Blueprint del KDS (se ajusta con K1) |
  | GPOS-NG | `b/ola5-diseno` | Hoja firmada; consultas 17, 20 y valuación |
  | GPOS-NG | `b/ola5` | Vistas revisión 3 y `rptsis`, sin aplicar |
  | GPOS-NG | `b/verticales-diseno` | Ventanas de las verticales (se ajustan a FactorUnidad) |
  | GPOS-NG | `b/conector-admcloud-diseno` | Hoja firmada; guardas por superficie |
  | GPOS-NG-AddOn-IQS | `b/conector-iq-instalador` | 0.4.2; prueba elevada aplazada |
  | GPOS-NG-AddOn-Kit / Polaris | `main` | Nuevos (solo README); construcción después de K1 |
  | BackupService | `n01-bloqueo-subida-sin-llave` | QA Aprobado; contiene fp01; el propietario lo revisa antes de unir |

## Equipo C (OSHIN-LEGION) — reactivado el 2026-10-16
- **2026-10-16:** el propietario reactiva a C como equipo de soporte de B junto con A. Máquina nueva: OSHIN-LEGION, antiguo equipo de B.
  - **Recursos:** 16 núcleos, 31,4 GB de RAM y 69 GB libres en C:. Es un portátil con batería.
  - **Software:** SQL Server 2025 en `.` y en `.\SQLEXPRESS`, .NET 10.0.401 y los workloads de MAUI.
  - **Rol:** ramas `c/` y PR sin unir. Propone 6 agentes y 2 compilando como máximo.
  - **Presentación:** aviso `C-a-B/2026-10-16-presentacion-equipo-c-oshin-legion`.
  - **Entregado (decisión del propietario: C toma lo que A no ha iniciado; aviso `C-a-B/2026-10-16-c-toma-pendientes-de-a`):**
    - **#50 (C-T3):** CP170 estable.
    - **#51 (C-T2):** los ajustes del #41. Cruza archivos con el #52 de A; C lo rebasa cuando se una el #52.
    - **C-T1:** el blueprint v4 de la fase A de ADR-81.
      - Hallazgos H-V4-01 y H-V4-02 para A.
      - P-81A-15 a 17 esperan la firma del propietario.
  - **Entregado después:** **#53** contra `master`, con las precisiones del 2026-10-16 (ADR-68 SC08, ADR-82 DL-22 b+, PD-1 de ADR-86 y la relectura de ADR-85 a 88). Lo une B.
  - **Trabajando en:**
    - **Fase A de ADR-81** (`c/adr81-fase-a` @ `df721803`, con push y sin PR): T-a a T-f hechas.
      - La única falla es anterior al blueprint: `EsquemaPendienteAccesoTests`.
      - PA-14 y PF-12 están marcadas `Medicion`.
      - Siguiente: T-g, el inicio de sesión en dos pasos.
    - **SC08-01/03** (`c/sc08-eliminar-renglones` @ `25142236`, con push, sobre el #49): construido.
      - Pruebas: servidor 465/465 y 223/223 en las clases afectadas; Web 664/664; MAUI 570/570.
      - Cambio de unidad: queda como hoy (decisión del propietario).
      - Ahora: **revisión de seguridad**; después, el PR.
    - **#54 (H-V4-01):** abierto. H-V4-02 espera P-81A-17.
    - **Suites oficiales de A:**
      - #52 + #48: hecha (3122/5/18, ninguna falla atribuible).
      - #55 + #48: en curso, con PA-30 repetida 5 veces.
    - **ADR-81:** en curso T-g a T-i.
- **Historial anterior (equipo C en LAPTOP-DUMQQ5QK, disuelto el 2026-10-14):**
- **Disuelto por decisión del propietario (2026-10-14).** Las funciones se repartieron así (aviso `B-a-C/2026-10-14-disolucion-del-equipo-c`):
  - **Pasan a B:** PR #21 (C-10), C-5, C-13, las revisiones de PR, la QA de estabilidad y fiscal, y el DEMO.
  - **Pasan a A:** la fase A de ADR-81 (desde el diseño de `c/adr81-fase-a-diseno`) y el apoyo en diseño, revisión y documentos.
  - El rango de ADR 130 a 159 queda congelado.
  - Pendiente del propietario: retirar la tarea de vigilancia en la laptop.
  - Lo que sigue es historial.
- **Retoma 2026-10-11 por encargo del propietario:** Codex continúa PR #21 en `c/compra-variable-tabla`; corrección `9f02c95b` publicada y compilada (0 errores). Integración bloqueada por acceso SQL (9 fallidas al aprovisionar, 0 aprobadas, 1 omitida). Ver aviso `2026-10-11-c10-retoma-validacion-pendiente`. PR sin unir; se conserva la condición del 14-oct.
- **Actualizado:** 2026-10-10
- **Rol:** soporte de B junto con A; ramas `c/...`, PR sin unir. Recursos (2026-10-10, sin Visual Studio ni DEMO): 8 núcleos, 7,8 GB de RAM (1,9 GB libres en reposo), 37,8 GB libres en C:; solo .NET 10 SDK con workloads de MAUI; `sqlcmd` (go-sqlcmd) instalado por el propietario. `SQLEXPRESS` con memoria 512/2.048 MB (propietario, 2026-10-10). Rige el límite de agentes de la antigua PC B hasta que el propietario decida.
- **Trabajando en:** nada; sin agentes activos, disponible. Entregado hoy: C-2 (H-11 Rechazado como publicable por C2-01; sin revertir la unión), C-8 (PR #19, unido), C-9 (PR #20, unido), C-10 (PR #21, no unir antes del 14-oct) y la fase A de ADR-81 en diseño cerrado (blueprint v3 y pantallas v2, P-81A-14 firmada). Siguiente posible: construir la fase A tras el segundo PR de H-11 (T1 antes, si B lo encarga). Vigilante Monitor armado (regla 8). ADR de C: 130 a 159.

## Pendientes del propietario
- **Equipo C disuelto (2026-10-14):**
  - retirar en LAPTOP-DUMQQ5QK la tarea programada de vigilancia;
  - decidir si la laptop sigue como equipo de prueba del DEMO;
  - decidir qué pasa con el rango de ADR 130 a 159 (congelado).
- **Firmas abiertas:**
  - la hoja de la licencia v2.5: **firmados el 2026-10-14** DL-07 (a), DL-08 (a), DL-14 (a), DL-17 (a), DL-13 y DL-10 (a); faltan DL-01 a DL-05, DL-09, DL-11, DL-12, DL-15, DL-16, la regla 3 y las P de v2.2 a v2.4;
  - CI-7/AI-07, AP-06 y AP-02 aprobados (el propietario los encarga; falta el nombre del suplente);
  - los 2 supuestos de #24;
  - las 2 preguntas de #26;
  - ADR-82: lo prepara B (propietario, 2026-10-14).
- **ADR-102:** ¿archivo propio o solo precisión de ADR-31? (recomendado: archivo propio).
- **DEMO:** probar la actualización del 2026-10-08 en LAPTOP-DUMQQ5QK (memoria de SQL Server 1.024 / 3.072 MB) y medir la importación de suplidores y clientes.
- **Backup Tool, revisión para producción del 2026-10-14: NO LISTO.**
  - 10 bloqueantes (B1 a B10; 3 críticos: instalador, cuenta y ACL del servicio, retención).
  - Unos 2 sp para cerrarlos.
  - Informe en Backup Tool `master` `3d936df`; aviso `B-a-A/2026-10-14-entrega-backup-tool-no-listo`.
  - El propietario lo deja registrado, sin plan por ahora.
  - Lo que bloquea y depende del propietario: unir n01, firmar ADR-0004 y S-3a.

  Anterior: indicar la unión tras la revisión de QA de B; firmar la fuente de carpeta (BT-01 a BT-09); comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación.
- **Contador:** enviar la sección 7 de la hoja de la 3b (C-17), y C-37 y C-38.
