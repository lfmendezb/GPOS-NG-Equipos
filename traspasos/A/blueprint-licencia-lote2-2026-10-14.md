# [Blueprint Técnico] Licencia firmada en el lote 2 de RG-14: cierre de AI-01, sello de habilitación, piezas construibles, calendario hasta el corte, ceremonia sin hardware y licencias de pago en nivel Básico

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A. **Versión:** 1, que incorpora las tres precisiones del propietario del 2026-10-14 listadas en «Entradas».
- **Estado del documento:** diseño. Las decisiones nuevas de este documento quedan **Pendientes de firma** (sección 13). Nada de lo que aquí se describe existe en el código.
- **Entradas:**
  - RG-14 firmado el 2026-10-14: D-01 a D-11, D-04 precisada y **L-01** (la licencia firmada de ADR-58 a 66 entra en el lote 2). Fuente: `datos-t3-12-rg14-2026-10-14.md` v2 (`[DAT]`).
  - Decisión del propietario: dos desarrolladores en paralelo, uno para las identidades y otro dedicado a la licencia, hasta el corte de mediados de diciembre de 2026.
  - **Precisiones del propietario del 2026-10-14, recibidas por el coordinador:**
    - **(a)** «montemos todo, que solo sea un tema de utilizar las YubiKeys». **Las YubiKeys todavía no se han comprado.** Se incorpora en las secciones 9 y 10.
    - **(b) Firmada:** precisión de ADR-62 (AP-05). Las licencias **de pago** se pueden firmar en nivel Básico con el TPM mientras no existan las YubiKeys. Al llegar, se hace la ceremonia (AP-01), el paso a Avanzado (AP-05) y la reemisión en Avanzado. El riesgo Medio ya está aceptado por escrito (P-F1, FY-15). Se incorpora en 10.3 y 10.5.
    - **(c) Firmada:** **Q-19 cambia de la opción (a) a una variante de la (b).** El equipo emisor es el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar. No habrá mini-PC por ahora. Se incorpora en 10.6.
  - Documentos: `[LIC]` = `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` v3.1; `[DLV]` = `docs/decisiones/2026-10-05-decision-licencia-por-vigencia.md`; `[HOJA]` = `docs/decisiones/2026-10-05-hoja-firma-seguridad.md`; `[PSF]` = `docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md` v1.3; ADR-58 a 66, ADR-77 y ADR-81; `CLAUDE.md`.
- **Código leído, solo lectura:** `GPOS-NG-h11b` @ `768f0a61`, que contiene `4d376a6c` (comprobado con `git merge-base --is-ancestor`). No toqué `GPOS-NG-rg14`, ninguna base ni la instancia. No compilé ni ejecuté pruebas.
- **Etiquetas:** **[V]** verificado en el código con `ruta:línea`; **[I]** inferido. **dp** = días-persona; 1 sp = 5 dp.

---

## 0. Resumen para el propietario

1. **AI-01 queda cerrado en lo documental, con 11 correcciones.** CI-1 a CI-5, D-1 y D-2 están en `[LIC]` v3.1, y el auditor los confirmó (W.2). Contrastados con el código actual y con `[DAT]` v2, salen 11 correcciones (sección 1). Ninguna cambia una decisión firmada. Las tres que importan:
   - **No existe ninguna bitácora del sistema.** `BitacoraSistema` (ADR-37) y `BitacoraSeguridad` (ADR-81) no están en el código [V]. Propongo usar `BitacoraSeguridad` de ADR-81 para la licencia y el sello.
   - **NV-07 se puede falsear con SQL.** La prueba de que el SUPER cambió el RNC no puede ser una fila de bitácora que un `sysadmin` inserta. Tiene que ser una fila con MAC. Además, hoy **el ADMIN edita el RNC** [V].
   - **Data Protection.** `GPOS.Migracion` escribe con el anillo de la API, pero con RG-14 la API corre con su propia cuenta de servicio y la persona que ejecuta `GPOS.Migracion` es otra. Así, **H-17 v2 (`GPOS.Criptografia`) pasa a ser condición del modo Estricto**, no solo de la licencia.
2. **El sello de habilitación funciona, pero le faltan cuatro cosas** (sección 2):
   - **No impide repetir un sello anterior.** Con SQL se puede inhabilitar a un usuario, dar de alta a otro y luego restaurar el sello viejo del primero: el cupo se duplica. Hace falta un **padrón de sellos con MAC**.
   - **La API vuelve a leer el nivel en cada petición** (caché de 15 s) sin mirar el sello [V]. Subir de nivel por SQL tendría efecto en la sesión abierta.
   - **La API crea un SUPER o un ADMIN si no hay ninguno** [V]. Borrar los SUPER por SQL y reiniciar fabrica uno, y además lo sella.
   - **El autorizante de supervisor** (ADR-68) no pasa por el sello.

   Hay además una decisión opcional: atar el sello al hash de la contraseña, para que no se pueda tomar una cuenta sellada cambiando el hash.
3. **La licencia queda en 9 piezas** (sección 4). **Pueden empezar ya, sin esperar al lote 2:** los contratos, `GPOS.Criptografia` con el verificador JWS estricto, las reglas de aceptación, el motor de estados (puro), el emisor con la abstracción del proveedor de llave y el kit de la ceremonia.
4. **Calendario (sección 11): cabe, con un reparto distinto del literal.** Cada desarrollador tiene 43 días hábiles hasta el 2026-12-15, unos 34 efectivos.

   | Reparto | Desarrollador de la licencia (API) | Desarrollador de las identidades | ¿Cabe? |
   |---|---|---|---|
   | **Propuesto:** las identidades toman además el sello, H-17 v2 y el emisor | ≈ 23,4 dp | ≈ 23,0 dp | **Sí**, con un 32 % de holgura en el centro y unos 2 a 3 dp en el peor caso (+35 %) |
   | Literal: toda la licencia, emisor incluido, en el desarrollador dedicado | ≈ 37 dp | ≈ 6 dp | **No** en el centro (37 frente a 34,4) |

   El riesgo real del calendario está **fuera** de los dos desarrolladores: la toma nueva de la ola 3, AI-07, QA y frontend.
5. **Ni el corte ni la primera licencia de pago dependen del hardware.**
   - Todo se construye y se prueba **sin las YubiKeys** (secciones 9 y 10): el emisor firma a través de una abstracción con proveedores TPM, YubiKey y software, y la API verifica sin saber quién firmó.
   - Con la precisión (b), las licencias de pago se firman en Básico con `s1` en el TPM del equipo principal del propietario (10.6). Además de construir y probar el código, la primera exige AP-03 y AP-04 con textos adaptados, AP-06 y AI-08 (10.3).
   - La ceremonia, el paso a Avanzado y la reemisión quedan **sin fecha**, con un guion listo y ensayado.
   - Después de la ceremonia hace falta **una versión de los binarios** que incorpore las llaves Avanzadas, porque ninguna configuración ni manifiesto puede agregar llaves (LV-07 y LV-14).
6. **La precisión (b) cambia invariantes e introduce riesgos nuevos** (10.5), que el auditor-seguridad debe revisar:
   - la caducidad técnica de `s1` (INV-1 y Q-16) no rige hasta que haya llaves Avanzadas en los binarios, así que el 2026-12-31 pierde efecto;
   - con solo `s1`, ninguna llave se puede retirar sin publicar binarios (INV-3);
   - **comprometer o perder `s1` ahora alcanza a los clientes de pago** y no tiene fecha de fin.

   Estimo que el riesgo **sube de Medio a Medio-Alto** con el equipo de uso diario. Propongo una segunda llave Básica en otro TPM y fijar de nuevo la caducidad (DL-10 y DL-11).
7. **Firmas y acciones pendientes del propietario:** sección 13. Ninguna está firmada por este documento.

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
| **SH-1** | **Repetición del sello.** El sello de una cuenta habilitada sigue valiendo para siempre. Con SQL: se copia el sello de A, se inhabilita A por la API (libera el cupo), se da de alta B (sellada), y se restauran el sello copiado de A con `Inhabilitado = 0`. Resultado: A y B habilitadas y **el cupo duplicado**. Repetible sin límite | `[DAT]` 6.3: el sello no tiene ninguna generación ni lista de vigentes | **Alta**: anula el propósito firmado de 6.3 | **Padrón de sellos con MAC** (2.3). Decisión **DL-01** |
| **SH-2** | **El sello no se verifica en cada petición.** `RevocacionSesiones` vuelve a leer el nivel y la habilitación de la base cada 15 s. Un `UPDATE Nivel = 'ADMIN'` por SQL da permisos de ADMIN a la sesión abierta en su siguiente petición sin token nuevo, porque el token puede tener nivel menor o igual | `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:50`, `:81-89`; `UsuariosService.cs:322-327` [V] | **Alta** | `EstadoSesionUsuario` lleva el resultado del sello. Un sello que no verifica da 401 `credenciales` (el mismo valor de R-3). Se calcula con la misma lectura y la misma caché de 15 s: sin consultas adicionales |
| **SH-3** | **La API crea cuentas privilegiadas sin sello previo.** `AsegurarSuperUsuarioAsync` crea `GSF` si no hay ningún SUPER, y `AsegurarAdministradorAsync` crea `ADMIN` si no hay ningún usuario. Borrar los SUPER por SQL y reiniciar **fabrica un SUPER**, que la API sellaría | `UsuariosService.cs:266-287`, `:421-433`; `Inicializacion.cs:32-33` [V] | **Alta** (frente a la meta «no se puede crear un SUPER por SQL») | En Estricto, la API **nunca** crea cuentas al arrancar: lo hace solo `GPOS.Migracion sistema --cuentas-iniciales`, la primera vez y antes de `Licencia.SelloInicial`. En Amplio sigue como hoy. Decisión **DL-02** |
| **SH-4** | **El autorizante de supervisor no pasa por el sello.** `ValidarAutorizanteAsync` valida a un ADMIN insertado a mano | `UsuariosService.cs:79-89` [V] | Media | Exigir un sello válido. Sin sello, el mismo tratamiento que una cuenta inexistente: hash ficticio y sin oráculo de tiempo (O-2) |
| **SH-5** | **Se puede tomar una cuenta sellada.** El sello no cubre el hash de la contraseña. Un `sysadmin` cambia el `PasswordHash` del SUPER por uno conocido y entra como SUPER. No amplía el cupo, pero contradice el espíritu de «no se puede crear un SUPER por SQL» | `[DAT]` 6.3 (contenido del sello) | Media | **Opcional, DL-05:** incluir en el sello el SHA-256 del `PasswordHash`. Hay que volver a sellar al cambiar o restablecer la contraseña y al rehacer el hash al entrar (`UsuariosService.cs:48`). +0,5 dp. Con ADR-81, el SUPER además tiene el segundo factor, que se custodia con el anillo: el residual baja a Bajo aunque no se firme DL-05 |
| **SH-6** | **Legitimar una cuenta por la vía equivocada.** Si cualquier `GuardarAsync` vuelve a sellar, un ADMIN que edite una cuenta insertada a mano la legitima | `UsuariosService.cs:131-214` [V] | Media | Sobre una cuenta sin sello válido, `GuardarAsync` responde 409 `USUARIO_SIN_SELLO`. Solo el SUPER la legitima con la ruta S-02, con motivo, segundo factor (ADR-81) y control del cupo |
| **SH-7** | **Ejecutar de nuevo el sellado inicial.** Si un `sysadmin` borra la fila `Licencia.SelloInicial` y GSF vuelve a ejecutar `sistema`, se sellarían las cuentas insertadas | `[DAT]` 6.3, R-RG14-12 | Baja | `sistema` solo sella si no hay **ninguna** licencia aceptada en `Licencias` ni en `Procesados`. Muestra la lista de cuentas y pide `--confirmar-sellado` con motivo, y deja el evento en la bitácora |
| **SH-8** | **Confusión de nombres** con el «sello de seguridad» de CS-1 e IDN-04, que es el valor aleatorio que se renueva al cambiar la credencial (`RevocacionSesiones.cs:44`; estándar de acceso, IDN-04) [V] | — | Baja | Nombres distintos en el código: `SelloHabilitacion` (MAC) frente a `SelloSeguridad` (aleatorio). Si se firma DL-05, el sello de habilitación puede incluir el `SelloSeguridad` en lugar del hash |

### 2.3 Padrón de sellos (DL-01)

- **Fila con MAC** `Licencia.PadronSellos` en `dbo.Configuracion`. `Valor` es `nvarchar(max)` (`EsquemaSistema.cs:102`) [V].
- **Contenido:** `Protect("GPOS.Usuarios.Padron.v1", { InstalacionId, Version, Cuentas: { Codigo → SHA-256(sello)[0..12] } })`.
- **Cuándo se escribe:** en la **misma transacción serializable** que escribe o borra un sello: alta, rehabilitación, cambio de nivel, inhabilitación y legitimación. `Version` sube de uno en uno.
- **Una cuenta cuenta y entra** solo si se cumplen las tres condiciones:
  1. el sello verifica;
  2. los campos del sello coinciden con la fila;
  3. el padrón verifica y contiene `Codigo → huella del sello`.
- **Volver atrás el padrón** completo con SQL devuelve un estado anterior **legítimo**: cada estado guardado respetó el cupo de su momento. La versión también se guarda en el archivo `estado` del disco (C-03). Si la versión de la base es menor que la del disco, se registra `PadronRetrocedido` y se avisa al SUPER (no bloquea).
- **Tamaño:** con 1 000 cuentas, unos 45 KB en claro y unos 70 KB en Base64 [I]. Solo se escribe al administrar usuarios, no al vender.
- **Alternativa descartada:** limitar el inicio de sesión a las N cuentas más antiguas cuando hay exceso de cupo. Choca con ADR-58, punto 9 («nadie pierde la sesión»), y permite turnar cuentas.
- **Alternativa descartada:** guardar las revocaciones en la bitácora. Un `sysadmin` borra filas de bitácora.

### 2.4 Puntos de verificación (dónde se comprueba el sello)

| Punto | Qué comprueba | Código actual |
|---|---|---|
| Inicio de sesión | Sello, padrón y campos. Si no verifican: error genérico idéntico al de una contraseña incorrecta, **sin** contar el intento, evento `USUARIO_SIN_SELLO` y alerta | `UsuariosService.ValidarAsync` (`:27-54`) |
| Cada petición, con caché de 15 s | Lo mismo: 401 `credenciales` | `RevocacionSesiones.Evaluar` (`:81-89`); `EstadoSesionAsync` (`:322-327`) |
| Autorizante de supervisor (ADR-68) | Lo mismo; sin oráculo de tiempo | `ValidarAutorizanteAsync` (`:79-89`) |
| Cupo | Habilitados no SUPER con sello válido y en el padrón; dentro de la transacción serializable que ya existe | `UsuariosService.cs:140`, `:162-172` |
| Instantánea de la licencia (cada 60 s) | Consumo por empresa y lista de cuentas sin sello para el SUPER | Nuevo |
| `GPOS.Migracion verificar` | Cuentas habilitadas sin sello y padrón que no verifica, con la condición `CUENTA_SIN_SELLO` | Agregar a S4 de `[DAT]` |

**Costo de verificar:** con 1 000 cuentas, unos 10 a 30 ms en la instantánea y en el alta [I]; 1 `Unprotect` por usuario cada 15 s en las peticiones. Lo mide QA.

### 2.5 Riesgos del sello

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-S1 | Se pierde o se cambia el anillo (falla de H-17 o del TPM): ningún sello verifica y nadie entra | Baja / Alto | H-17 v2, puntos 3 y 5: recuperación anclada y `recuperar-anillo`. Verbo `GPOS.Migracion sellos --resellar --motivo` con acta (R-RG14-13 de `[DAT]`) |
| R-S2 | Un administrador de Windows con `sysadmin` rehace sellos y padrón | Media / Medio | No se impide: se detecta. Es el residual de CP-4 (AP-04) y la regla (iii) |
| R-S3 | En las instalaciones de desarrollo y DEMO hay cuentas sin sello al pasar a la versión nueva | Alta / Bajo | En Amplio, la API sella al arrancar si falta `Licencia.SelloInicial`; en Estricto, nunca |
| R-S4 | Conflictos de edición entre los dos desarrolladores en `UsuariosService` | Media / Medio | El sello lo construye **un solo** desarrollador, el de identidades (4.3). La licencia solo expone `IEstadoLicencia.CupoUsuarios` |

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
| `GPOS.Api/Endpoints/LicenciaEndpoints.cs` | Rutas L-01 a L-09 y S-01 a S-03 | `GPOS.Core` |
| `GPOS.Migracion` | `sistema` (DDL y permisos), `--cuentas-iniciales`, sellado inicial, `sellos --resellar`, `recuperar-anillo` | `GPOS.Core`, `GPOS.Criptografia` |
| `GSF.EmisorLicencias` (repositorio privado aparte) | Emitir, firmar a través de `IProveedorLlaveFirma`, registrar y ceremonia | `FormatoLicencia` (archivo enlazado). **No** referencia `GPOS.Core` |

**Sin ciclos:** `Contracts` y `Criptografia` ← `Core` ← (`Api`, `Migracion`). `GPOS.Criptografia` no referencia a `GPOS.Contracts`: el verificador devuelve los bytes del contenido y los `kid` verificados, y `Core` interpreta `FormatoLicencia`.

**C4 (contexto y contenedores):** los de `[LIC]` 8.2 y 8.3 siguen vigentes, con dos cambios:
- la carpeta es la de C-03;
- el emisor tiene tres proveedores de llave (sección 9).

---

## 4. Piezas construibles

### 4.1 Lista, orden y dependencias

| Pieza | Contenido | Depende de | ¿Puede empezar ya? | dp |
|---|---|---|---|---|
| **L1a-1 Contratos y verificador** | Los DTO y códigos de 5.2; el proyecto `GPOS.Criptografia` (PR pequeño, unido **en los primeros 3 días** porque H-17 v2 se monta encima); `VerificadorJws` con 3.1.1 puntos 1 a 6 y 9; `RecursoLlavesGsf` (en las pruebas solo la llave de software; la de desarrollo solo en `Debug`); vectores negativos | — | **Sí** | 4,0 |
| **L1a-2 Reglas de aceptación** | INV-1 a INV-11, `nivel` y piso con D-2, `autNivel` con `instalaciones` (Q-17), CW-02, NV-05, NV-06 y techo de 48 h, todo como funciones puras sobre (archivo, licencia vigente, recurso de llaves, hora de referencia) | L1a-1 | **Sí** | 4,0 |
| **L1a-3 Motor de estados** | Estados y motivos de gracia, NV-01, NV-02, NV-07 (con la fila MAC de C-06 como dato de entrada), NV-08, ilegible, entorno y transición. **Puro**, probado con fechas fijas | L1a-1 | **Sí** | 2,4 |
| **L1a-4 Persistencia y arranque** | `SqlLicenciaSistema` (C-11), repositorio, almacén de disco con DACL (C-03), arranque con la mayor `sec` (LV-21), sellos `.acept` (INV-7), `sec` máxima efectiva, filas con MAC, refresco de 60 s, importador (20 por hora), huella (C-07), `InstalacionId` (C-08), solicitud L-06, carga manual L-03 de punta a punta en Amplio | L1a-2 y L1a-3. DDL de `[DAT]` 6.3 (ya diseñada). `IBitacoraSeguridad` (C-05) | Sí, con Amplio | 2,5 |
| **L1b Aplicación** | `UseLicencia` al final del *pipeline* (C-02); clasificación de unas 270 rutas con la lista aprobada; reutilizar `SoloConsulta` (C-09); segunda barrera en la toma; L-01 a L-09; encabezado; avisos y correo; excepciones legales; prueba de arquitectura «sin interruptores» (QA-L06 y QA-L17 sobre Release); H-16 con `ICorroboracionHora` alimentada por `emitida`; `IEstadoLicencia.CupoUsuarios` hacia el sello; retiro de `UsuariosAutorizados` (LV-17) | L1a-4. **Toma nueva unida** (ola 3, H-04). **AI-07** antes de clasificar. Ramas de las olas unidas (para no clasificar dos veces) | **No**: desde el 2026-11-16 | 9,5 |
| **SL Sello y padrón** | Secciones 2.3 y 2.4; SH-2 a SH-4, SH-6 y SH-7; rutas S-01 y S-02; `--cuentas-iniciales` y sellado inicial; DL-05 si se firma | `IEstadoLicencia` (la interfaz basta, con un sustituto que lee el cupo heredado hasta L1b). S1 de `[DAT]`. H-17 v2 para el sellado desde `GPOS.Migracion` en Estricto | Sí, en Amplio | 2,5 (+0,5 con DL-05) |
| **CR H-17 v2** | `CifradorAnillo` en `GPOS.Criptografia`, recuperación anclada (D-3), decorador CV-05, `recuperar-anillo` y migración desde DPAPI | Proyecto creado en L1a-1; certificados de devops | Sí, cuando exista el proyecto | 2,2 |
| **RN Cambio de RNC** | S-03, fila con MAC `Licencia.CambiosRnc`, 409 en la configuración del ADMIN (C-06) | DL-03 firmada; `IBitacoraSeguridad` | Diseño sí; código tras la firma | 0,75 |
| **EM Emisor y kit de la ceremonia** | `GSF.EmisorLicencias` con `IProveedorLlaveFirma` (TPM, YubiKey y software), registro con cadena de hashes, NTP en dos fuentes, resumen y SHA-256 antes de firmar, conversión DER a P1363, catálogo, CSV de pagos, tablero mínimo y subida manual a Drive; guion, scripts, modo de ensayo y lista de aceptación (secciones 9 y 10) | `FormatoLicencia` (L1a-1, día 2). `s1` en el TPM de la cuenta dedicada del equipo principal (AI-09, 10.6) solo para la primera licencia real; antes, el proveedor de software | **Sí** (otro repositorio, sin conflictos) | 10,5 |
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
| L-03 | `/api/admin/licencia/archivo` | POST multipart | `.gposlic` → `ResultadoCargaLicenciaDto` | Orden de `[LIC]` 6.2 y 3.1.1 | Los de `[LIC]` L-03 (413, 400, 409 y 422) | ADMIN o SUPER. `Esencial`. 10 por hora por cuenta | La respuesta muestra solo la empresa del token |
| L-04 | `/api/super/licencia` | GET | → `LicenciaInstalacionDto` | — | 401, 403 | SUPER. `Consulta` | Instalación. **Misma ruta que hoy, con otro DTO** (`AdminEndpoints.cs:275`) |
| L-05 | `/api/super/licencia/historial` | GET | `?desde&hasta` → `CargaLicenciaDto[]` | Rango de 2 años como máximo | 400, 401, 403 | SUPER. `Consulta` | Instalación |
| L-06 | `/api/super/licencia/solicitud` | GET | → `SolicitudLicenciaDto` (archivo JSON) | — | 401, 403, 503 `LICENCIA_SIN_INSTALACION` (en Estricto, sin `InstalacionId`) | SUPER. `Consulta` | Instalación, sin secretos |
| L-07 | `/api/super/licencia/{empresa}/consumidores` | GET | → `ConsumidorLicenciaDto[]` | La empresa existe | 404 | SUPER. `Consulta` | Empresa de la ruta |
| L-08 | `/api/admin/licencia/vigente` | GET | → bytes del JWS | — | 401, 403, 404 | ADMIN o SUPER. `Consulta` | Instalación |
| **L-09** | `/api/super/licencia` | POST | → 410 `LICENCIA_RUTA_RETIRADA` durante una versión | — | 410 | SUPER | — |
| **S-01** | `/api/super/usuarios/sin-sello` | GET | → `CuentaSinSelloDto[]` | — | 401, 403 | SUPER. `Consulta` | Instalación |
| **S-02** | `/api/super/usuarios/{codigo}/legitimar` | POST | `LegitimarCuentaRequest { Motivo, CodigoSegundoFactor }` → `UsuarioDto` | Motivo de 10 a 200 caracteres; la cuenta existe y no tiene sello válido; cupo (en la misma transacción serializable) | 404; 409 `USUARIO_CON_SELLO`; 409 `LICENCIA_CUPO_AGOTADO`; 422 `MOTIVO_REQUERIDO`; 403 `SEGUNDO_FACTOR` (ADR-81) | SUPER con segundo factor. `Operativa` | Instalación; evento `CuentaLegitimada` |
| **S-03** | `/api/super/empresas/{codigo}/rnc` | PUT | `CambiarRncRequest { Rnc, Motivo, CodigoSegundoFactor }` → `EmpresaRncDto` | RNC de 9 u 11 dígitos con dígito verificador; motivo de 10 a 200 caracteres | 404; 409 `RNC_SIN_CAMBIO`; 422 `RNC_INVALIDO`; 403 `SEGUNDO_FACTOR` | SUPER con segundo factor. **`Esencial`**: es la salida de `Invalida` (`[LIC]` 4.2) | Empresa de la ruta. Escribe primero la fila MAC en `GPOS_SYSDATA` y después el RNC en la base de la empresa |
| — | Configuración de la empresa (ADMIN) | existente | Si el RNC cambia → 409 `RNC_SOLO_SUPER` | — | — | — | DL-03 |

**Inicio de sesión de una cuenta sin sello:** la misma respuesta que con una contraseña incorrecta. No cuenta el intento y registra el evento `USUARIO_SIN_SELLO` (2.4).

### 5.2 DTO y códigos (`GPOS.Contracts/Licencia`)

```csharp
public sealed record EstadoLicenciaDto(string Estado, string? Motivo, DateOnly? Vence, int? DiasRestantes, DateTime? GraciaHastaUtc, string? Mensaje, bool Franja);
public sealed record UsuariosLicenciaDto(int Autorizados, int Consumidos, bool EnExceso);
public sealed record ModuloLicenciaDto(string Codigo, DateOnly Vence, string Estado);
public sealed record LicenciaEmpresaDto(string Cliente, string Estado, string? Motivo, DateOnly? Vence, DateTime? GraciaHastaUtc,
    UsuariosLicenciaDto Usuarios, IReadOnlyList<ModuloLicenciaDto> Modulos, CargaLicenciaDto? UltimaCarga, string? NivelFirma,
    string? PisoNivelFirma /* solo SUPER */, DateTime? AutorizacionBasicaHastaUtc);
public sealed record ResultadoCargaLicenciaDto(bool Aceptada, Guid? Lid, long? Sec, string? Codigo, string? Motivo, string EstadoEmpresa, bool PisoHeredado, bool CorteIgnorado);
public sealed record LicenciaInstalacionDto(string Cliente, string InstalacionId, string HuellaVigente, string HuellaActual, long Sec, DateTime EmitidaUtc,
    ParametrosLicenciaDto Parametros, IReadOnlyList<LicenciaEmpresaDto> Empresas, string? NivelFirma, string? PisoNivelFirma,
    string PerfilMinVigente, bool PerfilMinHeredado, IReadOnlyList<string> MachineGuidInformativos);
public sealed record ParametrosLicenciaDto(int GraciaDias, int AvisoDias, TimeOnly HoraCorte, string Anillo);
public sealed record CargaLicenciaDto(Guid? Lid, long? Sec, string Origen, string? Usuario, DateTime RecibidaUtc, char Resultado, string? Motivo, string Sha256);
public sealed record SolicitudLicenciaDto(string InstalacionId, string Huella, IReadOnlyList<EmpresaSolicitudDto> Empresas, string Version, IReadOnlyList<string> MachineGuids);
public sealed record EmpresaSolicitudDto(string Codigo, string? Rnc);
public sealed record ConsumidorLicenciaDto(string Codigo, string Descripcion, string Nivel, DateTime? UltimoAcceso);
public sealed record CuentaSinSelloDto(string Codigo, string Nivel, bool Inhabilitado, string Motivo /* SinSello|SelloInvalido|FueraDePadron|CamposNoCoinciden */, DateTime DetectadaUtc);
public sealed record LegitimarCuentaRequest(string Motivo, string CodigoSegundoFactor);
public sealed record CambiarRncRequest(string Rnc, string Motivo, string CodigoSegundoFactor);
public sealed record EmpresaRncDto(string Codigo, string Rnc, DateTime CambiadoUtc, string Usuario);
```

**`CodigosLicencia` (constantes `string`):**
- Bloqueo, con 403: los 6 de `[LIC]` 4.5 (`LICENCIA_SOLO_CONSULTA`, `LICENCIA_EMPRESA_NO_LICENCIADA`, `LICENCIA_RNC_NO_COINCIDE`, `LICENCIA_ILEGIBLE`, `LICENCIA_MODULO_VENCIDO` y `LICENCIA_ENTORNO`).
- Carga, en L-03: los de `[LIC]` L-03.
- Nuevos de este documento: `LICENCIA_RUTA_RETIRADA`, `LICENCIA_SIN_INSTALACION`, `LICENCIA_CUPO_AGOTADO`, `USUARIO_SIN_SELLO`, `USUARIO_CON_SELLO`, `RNC_SOLO_SUPER`, `RNC_INVALIDO` y `RNC_SIN_CAMBIO`.

**Eventos nuevos de la bitácora:** `USUARIO_SIN_SELLO`, `CuentaLegitimada`, `PadronRetrocedido`, `SelladoInicial`, `CambioRncSuper` y `CuentasInicialesCreadas`.

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

### 6.3 Sello (desarrollador de identidades)

```csharp
public enum ResultadoSello { Valido, SinSello, SelloInvalido, FueraDePadron, CamposNoCoinciden }
public interface ISellosHabilitacion
{
    byte[] Sellar(Usuario u, DateTime habilitadoUtc);   // dentro de la transacción del cambio; actualiza el padrón
    ResultadoSello Verificar(Usuario u, PadronSellos padron);
}
// EstadoSesionUsuario gana: ResultadoSello Sello  →  Evaluar() devuelve ValorCredenciales si no es Valido (SH-2)
```

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

## 8. Requisitos de seguridad de arquitectura

| Tema | Requisito |
|---|---|
| Autenticación | Sin cambios (ADR-36 y ADR-41), más el sello en el inicio de sesión, en cada petición y en el autorizante (2.4) |
| Autorización | La licencia se evalúa después de los permisos y solo restringe. S-02 y S-03 son solo del SUPER, con el segundo factor de ADR-81 |
| Aislamiento entre empresas | Igual que `[LIC]` 9. S-03 actúa sobre la empresa de la ruta y deja el evento con esa empresa |
| Secretos | La instalación no guarda ningún secreto de la licencia: solo llaves públicas en los binarios. Los sellos, el padrón y las filas protegidas usan el anillo (H-17 v2). El PIN, el PUK y la llave de gestión de las YubiKeys **nunca** van en scripts, parámetros, registros ni actas (sección 10). |
| Integridad | `Licencias` y `LicenciaLlavesRetiradas` son de solo inserción; filas con MAC; padrón (DL-01); RNC con MAC (C-06) |
| Configuración | Sin interruptores (ADR-60, punto 6). El modo Amplio no relaja la licencia. Ni el proveedor de software ni la llave `gsf-lic-dev` están en Release (9.3) |

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
   - El tablero lista los clientes de pago con licencia vigente Básica: es la lista de reemisión de AP-05.
   - *Retirada:* la regla de la versión anterior de este documento (el emisor Básico no firmaba producción) queda sustituida por la firma del propietario.
3. **CW-02 (firmada):** el nivel Básico no ofrece `corte: "inmediato"`. Para los clientes de pago en Básico, una revocación anticipada siempre pasa por la gracia de transición, de al menos 72 h (10.5).
4. **Siempre:** la hora NTP en dos fuentes, el desvío de 1 minuto como máximo, `sec` derivada del tiempo, el resumen y el SHA-256 antes de cada firma, y el registro con cadena de hashes.

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

### 10.3 Calendario y licencias mientras no haya YubiKeys (punto 4, con la precisión (b))

- **La ceremonia (AP-01) y el paso a Avanzado (AP-05) son acciones del propietario sin fecha.**
  - Las YubiKeys **no se han comprado**, según la precisión del 2026-10-14; `[LIC]` 0.10 decía «compradas el 2026-10-06». Lo vigente es lo que dice hoy el propietario.
  - Nada del calendario hasta el corte las espera.
- **La versión del corte sale en el escenario B** (`[PSF]` 4A.3): el recurso de llaves solo trae `s1` (y `upd-s1` si ya hay agente), más la llave de reserva si se firma DL-10.
- **Licencias que se pueden emitir antes de la ceremonia:**
  - con `gsf-lic-dev` (software): desarrollo, pruebas automáticas y equipos de desarrollo (solo `Debug`);
  - con `s1` (TPM, cuenta dedicada del equipo principal, 10.6): el DEMO, las demostraciones, las empresas Beta, las instalaciones de prueba de GSF y, **por la precisión firmada (b), las de pago**.
- **Lo que hace falta para la primera licencia de pago en Básico** (nada depende del hardware):

  | Condición | Estado |
  |---|---|
  | El código del lote 2 construido, con PA-12 y QA-L01 a L17 en verde | Plan de 11.3 |
  | **AI-08:** R-E11 (a) a (s) en verde sobre Release antes de la primera licencia Básica | QA |
  | **AI-09:** `s1` generada en el TPM con el guion de 10.1 en modo real con el proveedor TPM, con acta y las condiciones de 10.6 | Devops con el propietario; se puede hacer ya |
  | **AP-03:** procedimientos escritos y ensayados. Con Básico hay que **adaptarlos**: compromiso de `s1`, pérdida de `s1` o del equipo, y ausencia del titular | Devops con el propietario |
  | **AP-04:** CP-4 y CP-5 sin cambios. El texto de **R-L11 / R-F11** habla de «las dos YubiKeys»: en Básico el riesgo es perder `s1` (el TPM o el equipo). **Hace falta un texto adaptado**, que redacta el Maestro y firma el propietario | Propietario |
  | **AP-06:** contrato revisado por el asesor legal | Propietario y asesor legal |
  | Recomendado, sin bloquear: **DL-10**, llave Básica de reserva en otro TPM | Firma |

  **AP-02** (suplente) deja de ser condición mientras no haya `b1`, salvo que se firme DL-10 y la llave de reserva quede con un suplente.
- **Al llegar las YubiKeys:**
  1. ceremonia con el guion (10.1);
  2. PR del recurso con `a1`, `b1` y `upd-a*`, y la `aceptarHasta` de `s1` según DL-11;
  3. versión de los binarios;
  4. reemisión en Avanzado de todos los clientes de pago con `nivelMin: "avanzado"` y firma Avanzada propia, lo que cierra `s1` para cada instalación por el piso monótono (INV-4);
  5. retiro de `s1` con los binarios (AP-05).

  Son unos **0,5 dp** de desarrollo más la publicación, más **unos 5 a 10 minutos de toques al mes** por cada 50 clientes.

### 10.4 Costo de las secciones 9 y 10 (punto 5)

| Parte | dp |
|---|---|
| Abstracción del proveedor y proveedor TPM | 1,5 |
| Proveedor YubiKey (SDK, conversión DER a P1363, doble simulado) | 1,5 |
| Proveedor de software y su rechazo en Release | 0,5 |
| Guion, scripts, modo de ensayo, plantilla del acta y lista de aceptación | 2,0 |
| Verificación de la atestación (cadena hasta Yubico) | 0,5 |
| **Subtotal kit** | **6,0** |
| Resto del emisor (registro, NTP, catálogo, CSV, resumen, tablero mínimo) | 4,5 |
| **Emisor completo (EM)** | **10,5** |
| Después de la ceremonia: PR del recurso y versión | 0,5 |
| Revisión del guion por devops y ensayo con QA | 0,75 (devops y QA) |


**Agregado con las precisiones (b) y (c):**
- condiciones de 10.6 en la cuenta y el equipo: 0,5 dp de devops;
- llave de reserva (DL-10): 0,25 dp de desarrollo más 0,25 de devops;
- tablero de reemisión: dentro de EM.

En dinero, el mini-PC ya no se compra: **ahorro de USD 300 a 500**.

### 10.5 Licencias de pago en nivel Básico: invariantes que cambian y riesgos nuevos (para el auditor-seguridad)

**Invariantes:**

| Invariante | Antes (licencias de pago solo en Avanzado) | Con la precisión (b) y el escenario B | Propuesta |
|---|---|---|---|
| **INV-1 y Q-16:** `aceptarHasta` de `s1` el 2026-12-31 | Cerraba la ventana Básica de forma técnica | **No rige** mientras el recurso no tenga una llave Avanzada activa (`LlaveBasicaSinRelevo`). `s1` sirve sin fecha de fin. Si la versión con `a1` y `b1` sale después del 2026-12-31 con esa fecha fija, todo archivo nuevo solo con `s1` se rechaza desde el primer día, también las reemisiones de transición | **DL-11:** la `aceptarHasta` de `s1` la fija **la versión que incorpora las llaves Avanzadas**, en publicación + 45 días (un ciclo mensual, la gracia y margen). Precisa Q-16 |
| **INV-3 con D-1** | Retirar `s1` era posible con un manifiesto Avanzado | Con solo `s1`, ningún manifiesto puede retirarla: es la última llave aceptable, y un manifiesto Básico no retira llaves de licencias. **Solo la retiran los binarios** | Lo cubre DL-10, que da una segunda llave aceptable, más el procedimiento de emergencia por binarios (AP-03) |
| **INV-4 con D-2** (piso monótono) | — | Las licencias de pago llevan `nivelMin: "basico"`. La reemisión con firma Avanzada propia sube el piso y cierra `s1` en esa instalación | Sin cambio de regla; es el mecanismo de la reemisión de 10.3 |
| **INV-5 y CW-02** (corte inmediato) | Disponible para los clientes de pago | **No disponible** mientras estén en Básico: un fraude o un fin de contrato tarda al menos `máx(graciaDias, 72 h)` contado desde `emitida` | Aceptar (residual Bajo). Ya era la consecuencia firmada de CW-02 |
| `s2` y `autNivel` (regreso temporal) | Para cuando falte la YubiKey | No aplican en el escenario B; el código se construye (Q-24, plan completo) y queda inactivo | Sin cambio |
| **Q-21** (declaraciones) | — | Nada firmado en Básico se presenta como «hardware validado» ni FIPS | Sin cambio |
| NV-08 (retiro efectivo) | — | Una licencia falsificada con `s1` vale hasta el retiro efectivo, que exige que el cliente **instale** los binarios nuevos. **Un cliente que no actualiza la conserva hasta su `vence`**, que el falsificador puede poner lejano | Riesgo R-B11 |

**Riesgos nuevos o agravados** (estimación del arquitecto; los confirma o corrige el auditor):

| # | Riesgo | Prob. / impacto | Antes | Mitigación |
|---|---|---|---|---|
| **R-B11** | **Compromiso de `s1`:** quien la use fabrica licencias de pago para cualquier instalación (el `InstalacionId` viaja en la solicitud), sin telemetría que lo detecte (Q-08). No se revocan en un cliente que bloquea las actualizaciones | Baja-Media / Alto | Medio, acotado a Beta y DEMO y con fin el 2026-12-31 | Condiciones de 10.6; registro encadenado con ancla por correo (Q-14); DL-10; DL-11; comprar las YubiKeys pronto. **Estimado: Medio-Alto** |
| **R-B12** | **Pérdida de `s1`:** el TPM se borra, se reinstala Windows o falla el equipo. GSF no puede renovar hasta publicar binarios con una llave nueva, y los clientes pasan a la gracia y después a solo consulta | Media / Alto | No afectaba a clientes de pago | **DL-10:** llave de reserva `gsf-lic-s1r`, activa, en el TPM de **otro** equipo, con su propia cuenta dedicada y acta; procedimiento de AP-03; texto adaptado de R-L11 (AP-04) |
| **R-B13** | **Equipo de uso diario:** el malware de la cuenta administradora del propietario puede capturar el PIN y usar la llave desde la sesión de firma, o alterar el emisor para mostrar un resumen y firmar otro. No puede extraer la llave del TPM | Media / Alto | Bajo con el mini-PC dedicado | 10.6, puntos 6 a 9 |
| R-B14 | **Ventana sin fin:** sin fecha para las YubiKeys, el nivel Básico de pago se prolonga sin límite | Media / Medio | — | Recomiendo que el propietario fije una **fecha objetivo** de compra, sin que bloquee nada; el tablero muestra los clientes de pago en Básico |
| R-B15 | Sin corte inmediato para los clientes de pago en Básico | Baja / Bajo | — | Gracia de transición (CW-02) |

### 10.6 Equipo emisor: cuenta dedicada en el equipo principal del propietario (precisión (c), variante de Q-19 (b))

**Condiciones mínimas** (las verifica y documenta devops con el propietario antes de generar `s1`, y quedan en el acta de AI-09):

| # | Condición | Detalle |
|---|---|---|
| 1 | **Cuenta estándar dedicada** | Cuenta **local**, por ejemplo `gsf-firma`, del grupo Usuarios. **No** es administradora, **no** es una cuenta Microsoft, no está en Usuarios de escritorio remoto, no tiene correo, navegador ni sincronización con OneDrive o Drive, y no ejecuta otros programas. Contraseña larga, distinta de cualquier otra |
| 2 | **Llave en el TPM, no exportable** | «Microsoft Platform Crypto Provider», ECDSA P-256, sin política de exportación y con una **política de interfaz que pide el PIN de la llave en cada uso** (protección alta de CNG) [I: se confirma en el ensayo]. La generación la hace el guion de 10.1 en modo real con el proveedor TPM, con acta |
| 3 | **Confirmación de cada firma** | El emisor muestra el resumen (cliente, empresas, fechas, cupos) y el SHA-256 antes de cada firma (`IConfirmacionCustodio`); sin firma por lote |
| 4 | **Fuera de los respaldos e instantáneas** (AI-09) | La carpeta del proveedor de la cuenta (`%LOCALAPPDATA%\Microsoft\Crypto\PCPKSP` de `gsf-firma` [I]) queda excluida del Historial de archivos, OneDrive, las imágenes del sistema y las instantáneas, **desde la generación**. El blob solo sirve en ese TPM, pero se cumple igual lo firmado |
| 5 | **BitLocker** | En el volumen del sistema, con TPM y **PIN de arranque**. La clave de recuperación queda fuera del equipo, con custodia del propietario |
| 6 | **Administración separada** | Recomendado: la cuenta diaria del propietario pasa a estándar, y una cuenta administradora aparte se usa solo para mantenimiento. Es la medida que más baja R-B13 |
| 7 | **Integridad del emisor** | El emisor se instala en `Program Files` con la cuenta administradora; `gsf-firma` no puede modificarlo. El SHA-256 de los binarios del emisor queda en el acta, y el emisor lo comprueba al arrancar contra el registro |
| 8 | **Registro encadenado** | JSON por línea con el SHA-256 de la línea anterior (`[LIC]` 7.3), en una carpeta que solo escribe `gsf-firma`. Ancla por correo al propietario tras cada lote (Q-14); copia semanal fuera de Drive |
| 9 | **Equipo** | TPM 2.0 con el firmware actualizado (avisos del fabricante sobre ECDSA en el TPM [I]); arranque seguro; Windows Update y Defender activos; `w32time` contra una fuente confiable, más las dos fuentes NTP del emisor |

**Riesgo residual frente al mini-PC dedicado:**
- **Igual:** la llave no es exportable, y la custodia y la confirmación son las mismas.
- **Mayor:** la superficie de ataque. El equipo navega, recibe correo y tiene una cuenta administradora en uso diario, y quien la comprometa puede usar la llave (no copiarla) o engañar a la pantalla del emisor.
- **Estimación:**
  - **Medio-Alto** con la cuenta diaria administradora;
  - **Medio**, igual que lo aceptado en FY-15, con la condición 6.
- Las firmas hechas fuera del emisor no quedan en el registro: **se detectan solo cuando aparece una licencia que GSF no reconoce**.
- **Ahorro:** de USD 300 a 500.
- *Alternativa descartada por el propietario:* el mini-PC dedicado de Q-19 (a). Sigue siendo la mejora más barata frente a R-B13 si el auditor no acepta el residual.
Antes, el emisor costaba 7,6 dp: 1,0 sp del emisor más mi reparto de las adiciones de `[PSF]`. El kit agrega unos 2,9 dp netos [I].

---

## 11. Calendario hasta el corte con dos desarrolladores

### 11.1 Capacidad

| Dato | Valor | Origen |
|---|---|---|
| Días hábiles del 2026-10-15 al 2026-12-15 | **43** por desarrollador (44 menos el feriado del 6 de noviembre, trasladado al lunes 9 [I: Ley 139-97]) | Calendario |
| Factor productivo (revisiones, uniones, rondas del auditor) | 0,8 | [I] |
| **Capacidad efectiva** | **≈ 34,4 dp por desarrollador** | |

### 11.2 Carga (central, con un margen de ±35 % según `[DLV]`)

| Desarrollador | Piezas | dp central | +35 % |
|---|---|---|---|
| **L (licencia, API)** | L1a-1 a L1a-4 (12,9 = 7,5 de `[DAT]` + 1,4 de NV + unos 4,0 del verificador de `[PSF]`), L1b con H-16 (9,5), C-03 y C-05 (1,0) | **23,4** | 31,6 |
| **I (identidades)** | RG-14, parte de backend de los lotes 1 y 2 (≈ 6,0, `[DAT]` §7), SL (2,5), CR H-17 v2 (2,2), RN (0,75), DDL y retiro de `UsuariosAutorizados` (0,75), EM (10,5), llave de reserva DL-10 (0,25) | **23,0** | 31,1 |
| Otros agentes | Frontend 2,5; QA 5,5 + 0,5 (sello y kit); devops 3,0 + 0,5; datos 1,0 (6.3 más el padrón, `CambiosRnc`, `BitacoraSeguridad` y C-07) | 13,0 | — |
| Después del corte | L4 (2,8, integraciones); emisor: tablero completo y subida a Drive automática si se recortan | — | — |

**Total de la licencia en esta versión:** unos **55 dp** contando todos los roles (con 10.6 y DL-10), frente a los 41,2 de `[DAT]` 6.7. La diferencia:
- +2,9 del kit de la ceremonia;
- +2,2 de H-17 v2, que ya estaba presupuestado en la entrega 1 pero no tenía dueño;
- +4,25 del endurecimiento del sello, RNC, bitácora y carpetas;
- +4,0 del verificador de `[PSF]`, que `[DAT]` contaba en el emisor;
- −1,5 por C-10.

En dinero (USD 1 500 a 2 000 por sp): unos **USD 16 200 a 21 600**. **Sin infraestructura nueva:** las YubiKeys (unos USD 352) ya estaban presupuestadas (U-01), y el mini-PC ya no se compra (Q-19, variante de (b)): **ahorro de USD 300 a 500**.

### 11.3 Plan semanal

| Semana | Desarrollador L | Desarrollador I | Hito |
|---|---|---|---|
| S1: 10-15 y 10-16 | L1a-1: contratos; PR de `GPOS.Criptografia` | Lote 1 de RG-14; PA-47 | — |
| S2: 10-19 a 10-23 | L1a-1: verificador y vectores | Lote 1; S0/S1; arranca EM (abstracción y proveedor de software) | **H-1 (10-23):** verificador en verde |
| S3-S4: 10-26 a 11-06 | L1a-2 y L1a-3 | CR (H-17 v2); `GPOS.Migracion sistema` con `SqlLicenciaSistema`; EM con TPM; `s1` generada con el guion en modo real (AI-09, condiciones de 10.6) | **H-2 (11-06):** motor de estados y anillo |
| S5: 11-10 a 11-13 | L1a-4: carga manual en Amplio | SL (sello y padrón) | **H-3 (11-13):** L-03, L-04 y L-06 de punta a punta |
| S6-S7: 11-16 a 11-27 | L1b: *middleware*, clasificación, segunda barrera y rutas | SL en Estricto; RN (si DL-03 está firmada); `credencial-app` y `aprovisionar` | Requiere la toma nueva unida y AI-07 el 11-16 |
| S8: 11-30 a 12-04 | L1b: avisos, excepciones, Release (QA-L06 y QA-L17), H-16 | EM: kit de la ceremonia con ensayo; primera licencia Básica real tras AI-08 (DEMO y, con 10.3 cumplido, de pago) | **H-4 (12-04):** código completo |
| S9-S10: 12-07 a 12-15 | Estabilización: PA-12 en Estricto con la licencia, QA-L01 a L17 y PA-41 a PA-48 | Brechas de PA-12; PA-38 a PA-40 | **Corte (12-15)** |

### 11.4 ¿Cabe?

- **Con el reparto propuesto: sí.**
  - En el centro, L usa el 68 % de su capacidad y I el 66 %.
  - En el peor caso del rango (+35 %), L llega a 31,6 de 34,4 e I a 31,1 de 34,4: cabe, con unos 3 dp de margen cada uno.
- **Con el reparto literal** (L hace toda la licencia, emisor y sello incluidos; I solo RG-14):
  - L = 23,4 + 10,5 + 2,5 + 0,75 ≈ 37 dp: **no cabe en el centro** (37 frente a 34,4), e I queda con unos 28 dp ociosos.
- **El riesgo real está fuera de los dos desarrolladores:**
  - la toma nueva de la ola 3 unida antes del 2026-11-16 (segunda barrera);
  - AI-07 (especialista-pos y asesor legal) antes del 2026-11-16;
  - QA y frontend disponibles desde el 2026-11-23;
  - certificados de H-17 v2 (devops) antes del 2026-11-02;
  - `s1` en la cuenta dedicada del equipo principal (AI-09, 10.6), que se puede generar ya.

  Si una de estas se atrasa una semana, se recorta en este orden.

| Orden | Recorte | Ahorro | ¿Necesita firma? |
|---|---|---|---|
| 1 | Tablero, CSV de pagos y subida a Drive del emisor a enero; queda la emisión unitaria manual | ≈ 2 dp (I) | No |
| 2 | Correo diario de avisos a enero; la franja y el encabezado se quedan | ≈ 0,5 dp (L) | No |
| 3 | Franja en MAUI a enero; la Web se queda | ≈ 1 dp (frontend) | No |
| 4 | Opción reducida de Q-24: sin la autorización de regreso `autNivel`. Es segura porque `autNivel` va en `crit`, así que unos binarios que no la entienden rechazan el archivo | ≈ 1,75 dp (L) | **Sí** (Q-24 firmó el plan completo) |
| 5 | Segunda barrera solo en la toma nueva, no en la heredada `NumeracionService` (`src/GPOS.Core/Servicios/NumeracionService.cs:20`) [V], si la heredada sale de uso con el corte | ≈ 0,5 dp | Lo decide el Maestro con el plan del corte |

**No se recortan** las condiciones C-1 a C-4, la segunda barrera en la toma nueva, el sello con el padrón, la ausencia de interruptores ni H-17 v2.

**Cambio de calendario firmado:**
- Q-24 y Q-25 fijaban el inicio el 2026-11-02 y la publicación en la primera semana de enero de 2027.
- Con la decisión del 2026-10-14, el código se completa para el corte del 2026-12-15.
- **La primera licencia de pago ya no depende del hardware** (precisión (b)). Queda sujeta a 10.3: AI-08, AI-09, AP-03 y AP-04 adaptados y AP-06, todos alcanzables antes del corte. AP-01 y AP-05 quedan sin fecha.
- El orquestador debe registrar el cambio (G-1.6).

---

## 12. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-B1 | La toma nueva (ola 3) no está unida el 2026-11-16 | Media / Alto | Recortes 1 a 3; L1b empieza por el *middleware* y la segunda barrera entra la última semana |
| R-B2 | AI-07 no llega a tiempo | Media / Medio | Las tres excepciones legales se marcan `Operativa`, que falla cerrado, y se agregan con la validación. La regla firmada no se viola: queda más restrictiva |
| R-B3 | PA-47: el fork da NULL para `gpos_sistema` | Media / Bajo | C-07 |
| R-B4 | H-17 v2 se atrasa y el modo Estricto no funciona con identidades distintas | Media / Alto | CR va primero en la carga de I; mientras tanto, Amplio en desarrollo y DEMO (D-06) |
| R-B5 | Conflictos de edición entre los dos desarrolladores | Media / Medio | Propiedad de los archivos (4.3) y PR pequeños |
| R-B6 | El SDK de YubiKey no se comporta como el doble simulado | Media / Bajo | La alternativa PKCS#11 y la lista de aceptación. La API no cambia |
| R-B7 | Se publica en Release el proveedor de software o `gsf-lic-dev` | Baja / Crítico | 9.2 y 9.3; QA-L17 sobre Release |
| R-B8 | Clientes de pago firmados en Básico que no se reemiten tras la ceremonia | Media / Bajo | Tablero de reemisión (9.2); piso monótono (INV-4) |
| R-B9 | La ceremonia se aplaza indefinidamente | Media / Medio | Ver R-B14 y DL-12 |
| R-B11 a R-B15 | Riesgos de las licencias de pago en Básico y del equipo emisor de uso diario | Ver 10.5 | 10.5, 10.6; revisión del auditor-seguridad |
| R-B10 | Las cifras de `[PSF]` repartidas entre el verificador y el emisor (4,0 y 2,6) no son exactas | Media / Bajo | Es un reparto mío; la estimación total no cambia |

---

## 13. Lo que sigue requiriendo firma o acción del propietario (nada de esto queda firmado aquí)

### 13.1 Firmas nuevas que propone este documento

| # | Decisión | Recomendación | Costo |
|---|---|---|---|
| **DL-01** | Padrón de sellos con MAC contra la repetición (2.3). Precisa ADR-58, punto 9, y `[DAT]` 6.3 | **Sí**: sin él, el sello no cumple su propósito | 1,0 dp en SL |
| **DL-02** | En Estricto, la API no crea cuentas al arrancar; las iniciales las crea `GPOS.Migracion sistema --cuentas-iniciales` (SH-3). Precisa SEC-07 y SES-16 | **Sí** | 0,5 dp |
| **DL-03** | El RNC de la empresa solo lo cambia el SUPER, con motivo y segundo factor (S-03); el ADMIN recibe 409. **Cambia lo que ve el ADMIN** | **Sí**: es lo que exige NV-07 | 0,75 dp más un ajuste de pantalla |
| **DL-04** | Los eventos de la licencia y del sello van a `BitacoraSeguridad` (ADR-81) hasta que exista `BitacoraSistema` (ADR-37) | **Sí** | 0,5 dp |
| **DL-05** | El sello cubre también la huella del hash de la contraseña (SH-5) | Opcional. Recomiendo **sí** si el SUPER no tendrá el segundo factor antes del corte | +0,5 dp |
| ~~DL-06~~ | *Retirada:* la sustituye la precisión firmada (b) de ADR-62 / AP-05 | — | — |
| **DL-07** | Reparto: el desarrollador de identidades toma SL, CR, RN y EM (11.2) | **Sí**: es lo que hace caber el calendario | — |
| **DL-08** | Calendario: el código de la licencia se completa para el corte; sustituye las fechas de Q-24 y Q-25. Con (b), la primera licencia de pago queda sujeta a 10.3, no al hardware | Registrar | — |
| DL-09 (condicional) | Opción reducida de Q-24, solo si hace falta el recorte 4 | Solo si se confirma un atraso | −1,75 dp |
| **DL-10** | **Llave Básica de reserva** `gsf-lic-s1r`, activa, en el TPM de **otro** equipo con su cuenta dedicada y las condiciones de 10.6, incorporada a los binarios desde el corte (R-B12, INV-3) | **Sí** | 0,5 dp; equipo existente [I] |
| **DL-11** | La `aceptarHasta` de `s1` (y de `s1r`) la fija la versión que incorpora las llaves Avanzadas: publicación + 45 días. Precisa Q-16 e INV-1 | **Sí** | Dentro de los 0,5 dp de 10.3 |
| **DL-12** | **Fecha objetivo** de compra de las YubiKeys y de la ceremonia (R-B14), sin que bloquee nada | Fijarla | USD 352, ya presupuestados |
| **DL-13** | Condición 6 de 10.6: cuenta diaria estándar y cuenta administradora aparte en el equipo emisor | **Sí**: baja R-B13 de Medio-Alto a Medio | 0 |

### 13.2 Condiciones ya firmadas que siguen abiertas

| # | Qué | Quién | Estado o fecha |
|---|---|---|---|
| **AP-01 (CP-1)** | Compra de las cuatro YubiKey 5 FIPS 140-3 y ceremonia con el guion de 10.1 | Propietario y devops | **Sin fecha**; ya no condiciona la primera licencia de pago (precisión (b)) |
| AP-02 | Custodio suplente de `lic-b1`, `upd-b1` y Authenticode | Propietario | Antes de la ceremonia. Si se firma DL-10, conviene designarlo ya para custodiar `s1r` |
| **AP-03** | Procedimientos escritos y ensayados, **adaptados a Básico**: compromiso y pérdida de `s1`, y ausencia del titular | Devops con el propietario | **Antes de la primera licencia de pago** |
| **AP-04** | Aceptación escrita de **CP-4** y **CP-5** (textos literales de `[HOJA]`) y de un **texto adaptado de R-L11 / R-F11** para la pérdida de `s1` (lo redacta el Maestro) | Propietario | **Antes de la primera licencia de pago** |
| AP-05 | Paso a Avanzado y reemisión en Avanzado de los clientes de pago (10.3) | Propietario y devops | Después de AP-01, sin fecha |
| **AP-06** | Contrato de suscripción revisado por el asesor legal, con la cláusula del último período y la regla (iii) | Propietario y asesor legal | Antes del primer cliente |
| **CI-7 / AI-07** | Validación legal de las tres excepciones de LV-12 | Especialista-pos y asesor legal | **2026-11-16** (antes de clasificar las rutas) |
| AI-08 | R-E11 (a) a (s) en verde sobre Release antes de la primera licencia Básica | QA | Antes de la primera licencia, sea del DEMO, Beta o de pago |
| **AI-09** | `s1` en el TPM de la cuenta dedicada del equipo principal, con las condiciones de 10.6 y acta | Devops con el propietario | **Se puede hacer ya** (no espera a ningún mini-PC) |
| — | **Registro de las precisiones firmadas (b) y (c)**: ADR-62 / AP-05 y Q-19. Revisión de FY-15 / P-F1 para el alcance nuevo (licencias de pago, sin fecha de fin, equipo de uso diario) | Arquitecto-maestro y documentador, con la revisión del auditor | Antes de la primera licencia de pago |
| — | Precisión de ADR-58 «licencia por empresa contando usuarios» y cláusula de módulos | Arquitecto-maestro → propietario | Por preparar; hasta entonces rige la suma de cupos |
| — | ADR-82 (RG-14) | Arquitecto-maestro → propietario | Por preparar |
| — | Activar `contained database authentication` en la PC A para la suite `Rg14` (`[DAT]` 3) | Propietario o devops | Antes de PA-12 |
| — | Certificado del servidor y certificado de recuperación de H-17 v2, con la custodia de Q-22 | Propietario (custodia) y devops | Antes del 2026-11-02 para CR |

---

## Supuestos

1. **El desarrollador de identidades no tiene otras tareas asignadas hasta el corte**, salvo RG-14. Si tiene otras (por ejemplo, el segundo PR de H-11), el reparto DL-07 se rehace y vuelve a no caber.
2. Factor productivo 0,8 y feriado el lunes 9 de noviembre [I].
3. QA, frontend y devops están disponibles en las semanas de 11.3.
4. La sintaxis de `ykman`, el modo FIPS de la serie 140-3, el comportamiento del SDK de Yubico, la política de PIN por uso del proveedor TPM de CNG y la ruta `PCPKSP` son [I]; se fijan en el ensayo y el día de la ceremonia.
5. El reparto de las 1,32 sp de `[PSF]` entre el verificador y el emisor (unos 4,0 y 2,6 dp) es mío.
6. Las cifras de `[DAT]` y `[LIC]` son las firmadas (±35 %).
7. Lo que dice hoy el propietario prevalece sobre `[LIC]` 0.10 («compradas el 2026-10-06») y sobre Q-19 (a). Las precisiones (b) y (c) las recibí del coordinador como firmadas en la sesión de A del 2026-10-14; no vi el texto firmado.
8. Hay un segundo equipo con TPM 2.0 para la llave de reserva (DL-10) [I].
9. `feature/modelo-ng` ya está en `59921ba0`. Las citas son de `768f0a61`; las rutas de los archivos citados existen en las dos.

### Cierre
- Estado: Completado. AI-01 queda cerrado en lo documental con las correcciones C-01 a C-11. Incorpora las precisiones del propietario del 2026-10-14 (a), (b) y (c). Las decisiones DL-01 a DL-13 están Pendientes de firma (DL-06, retirada).
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md`
- Supuestos: los nueve de la sección «Supuestos».
- Decisiones candidatas a ADR:
  - **ADR-83 · Sello de habilitación de cuentas con padrón protegido y verificación en el inicio de sesión, en cada petición y en el autorizante** (DL-01, DL-02 y DL-05; SH-1 a SH-8). Precisa ADR-58 (punto 9), ADR-36 (R-3), ADR-68 y SEC-07. *Descartadas:* limitar por antigüedad en exceso de cupo, y las revocaciones en la bitácora.
  - **ADR-84 · Emisión en nivel Básico sin fecha de fin, con equipo emisor de cuenta dedicada y proveedor de llave intercambiable** (secciones 9, 10.5 y 10.6; DL-10 a DL-13). Recoge las precisiones firmadas (b) y (c), y precisa ADR-61, ADR-62, Q-16, Q-19 e INV-1. *Descartadas:* mini-PC dedicado (por el propietario), firmar con la llave real en desarrollo y fecha fija de caducidad de `s1`.
  - **Precisiones, no ADR:** ADR-59 / NV-07 (prueba del cambio de RNC con fila MAC, DL-03); ADR-81 (la bitácora común también para la licencia, DL-04); ADR-60 (clase de la ruta con la marca `SoloConsulta` compartida y el *pipeline*, C-02 y C-09); `[LIC]` 3.5 con la carpeta de ADR-77 (C-03).
  - ADR-82 queda reservado para RG-14 (lo prepara el arquitecto-maestro). ADR-80 sigue libre.
- Entregas a otros agentes:
  - **auditor-seguridad (prioritaria):** revisar 10.5 y 10.6 (R-B11 a R-B15, la estimación Medio-Alto, DL-10, DL-11 y DL-13) y si P-F1 / FY-15 cubre el alcance nuevo; además, SH-1 a SH-8, DL-01 a DL-05 y las secciones 9 y 10 antes de unir SL y EM.
  - **arquitecto-maestro:** hoja de firma DL-01 a DL-13; registro de las precisiones (b) y (c); texto adaptado de R-L11 / R-F11 para AP-04; ADR-83 y ADR-84; ADR-82; precisión de ADR-58 sobre la licencia por empresa contando usuarios; registro del cambio de calendario (G-1.6).
  - **arquitecto-datos:** DDL de `BitacoraSeguridad` común (C-05); filas `Licencia.PadronSellos` y `Licencia.CambiosRnc` (C-06, DL-01); `usp_LeerHuellaEntorno` de reserva (C-07); `SqlLicenciaSistema` compartida (C-11); condición `CUENTA_SIN_SELLO` en S4.
  - **desarrollador-backend (L):** L1a-1 a L1b, desde ya.
  - **desarrollador-backend (I):** RG-14 más SL, CR, RN y EM (con el tablero de reemisión y la llave de reserva), con PA-47 en la semana 1.
  - **desarrollador-frontend:** `Licencia.razor`, la franja, S-01 a S-03 en la Web desde el 2026-11-23, y el ajuste de la pantalla de configuración (DL-03).
  - **qa-automatizado:** QA-L01 a L17, PA-41 a PA-48, más los casos nuevos de repetición del sello, sello por petición, cuentas iniciales en Estricto, autorizante, RNC por SQL, ensayo de la ceremonia y aceptación de licencias de pago firmadas con `s1` sin llave Avanzada (INV-1 ignorada, `LlaveBasicaSinRelevo`).
  - **devops:** condiciones de 10.6 y acta de AI-09 en el equipo principal; llave de reserva (DL-10); procedimientos adaptados (AP-03); certificados de H-17 v2; revisión del guion de la ceremonia; canalización Release (NV-05 c); DACL de ADR-77.
  - **arquitecto-integraciones:** contrato del agente (6.4) para L4; aviso a quien lleve T-29c de que el verificador JWS lo construye L1a (ADR-77, R-1).
  - **especialista-pos y asesor legal:** AI-07 antes del 2026-11-16; AP-06.
  - **orquestador:** el plan de 11.3 y las dependencias externas de 11.4.
- Próximo paso recomendado: arrancar hoy L1a-1 (desarrollador L) y el lote 1 con PA-47 (desarrollador I), pasar 10.5 y 10.6 al auditor-seguridad, y que el arquitecto-maestro prepare la hoja DL-01 a DL-13.
