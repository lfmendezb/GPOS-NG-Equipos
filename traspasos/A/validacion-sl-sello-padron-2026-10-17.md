# Validación de la pieza SL «Sello y padrón» contra el blueprint de la licencia del lote 2

**Fecha:** 2026-10-17 · **Valida:** arquitecto-software (equipo A) · **Rama:** `a/sl-sello-padron`, árbol `GPOS-NG-sl`, `git diff e80f4654..27d49c95` (commits `994e0fcb` y `27d49c95`; 23 archivos, +2 724 / −49)
**Fuentes:** blueprint `blueprint-licencia-lote2-2026-10-14.md` (§2.3, §2.4, §2.5, §4.1 fila SL, §4.3, §5.1, §5.2 y §6.3); `[DAT]` `datos-t3-12-rg14-2026-10-14.md` y `datos-licencia-l1a4-2026-10-14.md`; hoja `GPOS-NG-Equipos/traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md` v2.13 (DL-01 (a)+(b), DL-02 (a), DL-04 (a), DL-05 (a)); ADR-83 con las precisiones del 2026-10-15 y del 2026-10-16 (`docs/adr/ADR-083.md` en `b02ab689`; P-81A-15 (a) y P-81A-16 (a)).
**Método:** solo lectura del diff, del código circundante, del instalador del DEMO y de la rama `origin/c/adr81-fase-a` (`4e5bc446`). **No compilé ni ejecuté pruebas**: la rama no se tocó. *[V]* = verificado en el código; *[I]* = inferido.

---

## 1. Veredicto

**Conforme con correcciones.** El núcleo cumple el diseño firmado:
- el cupo se cuenta desde el padrón;
- el padrón se cambia por diferencias en la transacción serializable, con el bloqueo tomado primero;
- hay copia en el disco, que nunca adelanta a la base;
- la caché global es de 15 s;
- el sello se comprueba antes que la contraseña y con hash ficticio;
- en cada petición, el sello da 401 `credenciales`;
- el autorizante pasa por el sello;
- `GuardarAsync` no legitima;
- en Release no se crea ni se sella nada;
- DL-05 cubre la contraseña y `FactorAlta`.

Hay **cinco correcciones obligatorias antes del PR** (sección 5). Tres tocan el punto de conexión con la fase A de ADR-81: una contradice la precisión P-81A-16 (a), firmada el 2026-10-16, y otra es un defecto de concurrencia y de caché. Las otras dos son una herramienta de recuperación que falta y el instalador del DEMO, que se rompe. Hay **dos asuntos para firma** (sección 7).

## 2. Conformidad con el diseño

| Requisito | Resultado | Evidencia |
|---|---|---|
| Sello con propósito `GPOS.Usuarios.Sello.v1`, con instalación, código, nivel, habilitación, sucursal, hora, `HuellaClave` (DL-05) y `FactorAlta` solo en el SUPER | Conforme | `SellosHabilitacion.cs` (`ContenidoSello`, `Contenido`, `Verificar`) |
| Tres condiciones para entrar (sello que verifica, campos iguales y padrón con la huella **y el nivel**) | Conforme | `SellosHabilitacion.Verificar` |
| Padrón `Protect("GPOS.Usuarios.Padron.v1", …)`, huella de 12 bytes y nivel por entrada; consumo = entradas no SUPER | Conforme | `PadronSellos.cs:19-30`, `:214-245` |
| Por diferencias, en la misma transacción serializable y **nunca** reconstruido desde las filas | Conforme. `TomarAsync` exige una transacción en curso y toma `UPDLOCK, HOLDLOCK` primero | `PadronSellos.cs:292-302`; `ConsultasSellos.cs:21`; `UsuariosService.cs` (`GuardarAsync`) |
| Copia en el disco: se escribe después del commit, por reemplazo atómico, prevalece la mayor versión y `PadronRetrocedido` | Conforme, con una observación (R-2) | `PadronSellos.cs:304-309`, `:326-334`, `:386-406` |
| Caché global de 15 s que solo descifra si cambió el SHA-256 (SEG-L2-20) | Conforme | `PadronSellos.cs:249-286` |
| Inicio de sesión: sello antes que la contraseña y que el bloqueo, hash ficticio, sin contar el intento, evento limitado (SEG-L2-17) | Conforme | `UsuariosService.cs:46`, `SelloEnOrdenAsync` |
| SH-2: cada petición, 401 `credenciales` | Conforme | `RevocacionSesiones.cs` (línea agregada antes del nivel); `EstadoSesionAsync` |
| SH-4: autorizante | Conforme | `ValidarAutorizanteAsync` |
| SH-6: `GuardarAsync` responde 409 `USUARIO_SIN_SELLO` y no legitima | Conforme. Inhabilitar sí se permite y solo retira la entrada (correcto) | `UsuariosService.cs` (`GuardarAsync`, bloque SH-6) |
| SH-7: sellado inicial solo sin licencia aceptada (base y `Procesados`) ni padrón (base y disco), con la lista, `--confirmar-sellado` y motivo | Conforme | `SellosService.EstadoSelladoInicialAsync`; `ComandoSellos.SelladoInicialAsync` |
| DL-02 (a): sin creación ni sellado en Release; sellado de desarrollo solo en `Debug` | Conforme, con una prueba de arquitectura | `Inicializacion.SellaAlArrancar`; `SellosEnLaApiTests` |
| Rehacer el hash al entrar y cambiar la contraseña vuelven a sellar (DL-05) | Conforme | `UsuariosService.cs` (`ValidarAsync` con `SuccessRehashNeeded` y `CambiarClaveAsync`) |
| S-01 publicada (SUPER, `Consulta`, con `FilaAusente`) | Conforme | `SellosEndpoints.MapSellos` |
| S-02 y S-04 construidas y **no mapeadas** | Conforme en la publicación. **No conforme** en el mecanismo del segundo factor: ver C-1 | `SellosEndpoints.cs:32-66` |
| `sellos --purgar`: exige el anillo y deja un evento crítico con la cuenta, el SID y el equipo | Conforme | `ComandoSellos.EjecutarAsync`, `ExigirAnilloAsync`, `ActorWindows` |
| `verificar`: `CUENTA_SIN_SELLO`, padrón que no verifica y versión distinta, en solo lectura | Conforme | `ComandoSellos.VerificarAsync`; `GPOS.Migracion/Program.cs` |
| L-02 y L-07 cuentan desde el padrón | Conforme: `LicenciaEndpoints.cs:110` y `:144` llaman a `UsuariosService.LicenciaAsync`, que ahora lee el padrón | `UsuariosService.LicenciaAsync` |
| Sin ciclos: `Sistema/Usuarios` → `Sistema/Licencia`, nunca al revés | Conforme. Búsqueda de `Sistema.Usuarios` en `Sistema/Licencia` sin resultados *[V]* | — |
| Pruebas de SEG-L2-01, 05, 06, 07, 17 y 20 | Presentes (39 pruebas en `tests/GPOS.Tests/Usuarios/Sellos/`); **no las ejecuté** | — |

## 3. Desviaciones declaradas

| # | Desviación | Dictamen | Motivo |
|---|---|---|---|
| (a) | Eventos en `MAYÚSCULAS_CON_GUION`; la purga se llama `PADRON_PURGADO` | **Aceptar** | Es la convención de la tabla (`EventosSeguridad`: `SISTEMA_RESTAURADO`, `CANDADO_RESTAURACION_LIBERADO`, `BitacoraSeguridad.cs:20-23`), y las reglas del proyecto prevalecen (C1.3). El nombre sigue al **ADR-83, punto 8** (`PadronPurgado`), firmado, que prevalece sobre mi blueprint (`PadronEntradaPurgada`). Caben en `Evento varchar(40)`. Sin firma: se agrega como nota de registro en ADR-83, punto 8 (tabla de nombres), y el blueprint se corrige en la v2.10 |
| (b) | `PADRON_NO_DISPONIBLE`, `MOTIVO_REQUERIDO` y `SEGUNDO_FACTOR` en `ClavesSellos` y no en `CodigosLicencia` | **Aceptar** `PADRON_NO_DISPONIBLE` y `MOTIVO_REQUERIDO`. **Eliminar** `SEGUNDO_FACTOR` (C-1) | Respeta §4.3: `Contracts/Licencia` es de L. `PADRON_NO_DISPONIBLE` es un añadido correcto: falla cerrada sin padrón, y el blueprint no lo traía. Condición: cuando la Web los consuma (pantalla de S-01 o el mensaje de Usuarios), L los pasa a `CodigosLicencia` con el **mismo literal** y `ClavesSellos` los referencia; nunca dos definiciones. RN reutiliza `MOTIVO_REQUERIDO` para S-03 |
| (c) | Sucursal sellada como huella SHA-256 de 8 bytes de empresa + sucursal predeterminadas, solo con la restricción | **Aceptar** | Cubre lo que la restricción protege: cambiar por SQL la sucursal de una cuenta restringida invalida el sello (prueba `Con_la_sucursal_restringida_cambiarla_por_SQL_invalida_el_sello`). Truncar a 64 bits no abre nada práctico: haría falta una segunda preimagen entre las sucursales existentes. Sin la restricción, la sucursal predeterminada no da ningún privilegio, así que no se sella y no obliga a volver a sellar. Ahorra unos 60 bytes con el código más largo *[I]* |
| (d) | `IPadronSellos` como `TomarAsync` → `CambioPadron.Poner/Quitar/GuardarAsync` → `TrasConfirmar`, en lugar de `Poner(codigo, entrada, tx)` | **Aceptar** | Equivale a 6.3 y es mejor: hace explícita la unidad de trabajo, garantiza el orden de bloqueos (padrón → filas) y sube `Version` una sola vez por acción. El motivo, que §6.3 ponía en `Quitar`, va al evento de la bitácora en el servicio, que es donde se audita. **Única excepción:** la participación en la transacción de quien llama (`ResellarAsync`), que sí falla (C-2) |

## 4. Puntos para decidir

| # | Punto | Dictamen |
|---|---|---|
| (1) | Restaurar `GPOS_SYSDATA` desde un respaldo legítimo deja cuentas `FueraDePadron` y solo `--legitimar` las recupera. ¿Lo trata la reconciliación CR-01 de H-11? | **No, por diseño. Va a firma como confirmación (SL-F1).** Reconciliar en la liberación del candado volvería a sellar las filas restauradas: es «reconstruir desde las filas», que DL-01 prohíbe, y reabre SEG-L2-07 (restaurar un respaldo para recuperar el cupo después de una reducción). La salida es legitimar cuenta por cuenta, con el control del cupo. Hasta la fase A de ADR-81, eso exige `sellos --legitimar`, que hoy no existe: por eso pasa a SL (C-4). El candado CR-01 solo debe **informar** cuántas cuentas quedan en S-01 al liberar (entrega a H-11, unos 0,1 dp) |
| (2) | `GPOS.Migracion sistema` ya no crea cuentas sin `--cuentas-iniciales` | **Aceptar: es lo firmado.** DL-02 (a) y ADR-83, punto 3, dicen literalmente «`GPOS.Migracion sistema --cuentas-iniciales`», y «Qué rompe» ya anuncia el cambio del DEMO. Lo que se unió en RG-14 lote 2 era una implementación provisional. **Pero rompe el instalador** (C-5) |
| (3) | El sellado inicial sella también las inhabilitadas, fuera del padrón (`[DAT]` decía «los habilitados») | **Aceptar** como precisión técnica sin firma. No amplía el cupo: quedan fuera del padrón y su rehabilitación pasa por el cupo (`GuardarAsync` → `ExigirCupo`). Evita que cada cuenta inactiva legítima necesite `--legitimar` para volver. Una fila inhabilitada insertada por SQL **antes** del sellado inicial queda sellada, igual que una habilitada: es el mismo residual de SH-7, mitigado con la lista a la vista. Entrega a datos: corregir el texto de `[DAT]` 6.3 |
| (4) | Una cuenta inexistente, inhabilitada o sin hash no verifica el hash ficticio al iniciar sesión (oráculo anterior) | **Corregir en este PR, como recomendada (R-1), sin firma.** SL cumple SEG-L2-17: el estado del sello no se distingue de una contraseña incorrecta. El oráculo de **existencia** viene de antes (`UsuariosService.cs:42`), pero hoy hay tres clases de tiempo y `ValidarAutorizanteAsync` ya lo resuelve (O-2). Son 3 líneas en un archivo de I, ≈ 0,05 dp. No bloquea el PR |
| (5) | `sellos --resellar` (R-S1, ADR-83, punto 7) no está asignado ni a SL ni a RN | **Va a firma (SL-F2).** Es un hueco de mi blueprint: §2.5 R-S1 y §2.3 lo nombran, pero §4.1 no lo asigna. Es la única excepción a «nunca se reconstruye desde las filas», así que sus condiciones son de política (qué pasa si las filas superan el cupo) y no solo de código |

## 5. Correcciones obligatorias antes del PR

| # | Corrección | Severidad | Evidencia | Esfuerzo *[I]* |
|---|---|---|---|---|
| **C-1** | **S-02 y S-04 con la autenticación reciente de ADR-81, punto 14 (P-81A-16 (a), firmada el 2026-10-16), no con un código en la petición.**<br>- Retirar `IVerificadorSegundoFactor` (`FactorSuper.cs:33`), `ClavesSellos.SegundoFactor` (`PadronSellos.cs:54`) y la lectura de `req.CodigoSegundoFactor` (`SellosEndpoints.cs:47`, `:60`).<br>- `MapSellosConSegundoFactor` pasa a mapear con `RequiereSuper()` + `.RequiereAutenticacionReciente()`, el filtro que ya usa la rama `origin/c/adr81-fase-a` (`AdminEndpoints.cs:209`). El nombre de la extensión lo fija la fase A; mientras tanto, se documenta en el método.<br>- Ajustar `SellosEnLaApiTests` (hoy afirma la ausencia de `IVerificadorSegundoFactor`).<br>- El campo de los DTO lo quita L (entrega) | Media: contradice una firma y crea un segundo camino de verificación que P-81A-16 descartó | ADR-83, precisión del 2026-10-16, punto 2 | 0,1 dp |
| **C-2** | **Punto de conexión del factor: tomar el padrón antes de escribir el factor y publicar la copia después del commit.**<br>`ResellarAsync` participa en la transacción de quien llama (`UsuariosService.cs:113-135` y `:142`). Eso tiene dos defectos:<br>(i) **Orden de bloqueos invertido.** La fase A escribe `UsuariosFactor` y después toma el padrón con `UPDLOCK`. `GuardarAsync` sobre un SUPER toma el padrón y después lee `UsuariosFactor` en serializable (`SellosCuentas.FactorAsync`). Es un interbloqueo posible (error 1205) *[I]*.<br>(ii) **Caché vieja.** Sin `TrasConfirmar`, la caché global conserva hasta 15 s el padrón anterior, y el SUPER que acaba de dar de alta su factor recibe 401 `credenciales` (`FueraDePadron`) en su siguiente evaluación *[I, por lectura de `VigenteAsync`, `PadronSellos.cs:252`]*.<br>**Corrección:** sustituir `ResellarAsync(codigo)` por una entrada que abre o recibe la transacción, **toma el padrón primero**, ejecuta la escritura del factor que pasa la fase A (por ejemplo, `CambiarFactorAsync(codigo, Func<SistemaDbContext, CancellationToken, Task> escribirFactor)`), vuelve a sellar, confirma y llama a `TrasConfirmar`. Si la fase A necesita su propia transacción, la entrada recibe la transacción y devuelve el `CambioPadron` para llamar a `TrasConfirmar` después del commit; nunca `Olvidar()` antes del commit. La misma entrada la usa `GPOS.Migracion restablecer-factor` (P-81A-15 (a)). Agregar una prueba: alta del factor simulada → la sesión del SUPER sigue válida de inmediato | Media | `FactorSuper.cs:7-12` (documentación del punto de conexión) | 0,2 dp |
| **C-3** | **Un solo punto para `IFactorSuper` en `GPOS.Migracion`.** `ComandoSellos.Servicio` recibe `factor`, pero las tres llamadas usan el valor por omisión (`ComandoSellos.cs:67`, `:104` y `:141`). Con la fase A, el sellado inicial sellaría `FactorAlta = false` y `verificar` daría `CamposNoCoinciden` a un SUPER con factor, salvo que C encuentre y cambie los tres sitios. **Corrección:** un único proveedor en `ComandoSellos` (método o propiedad estática documentada) que usan las tres llamadas | Baja | — | 0,05 dp |
| **C-4** | **`sellos --legitimar <código> --motivo` pasa de RN a SL.** Sin él, lo que se une en SL deja cuentas fuera sin ningún remedio fuera de `Debug`: restauración (punto 1), DEMO con una licencia aceptada (punto C-5), un SUPER recreado con `--cuentas-iniciales` después del sellado (el propio mensaje de `Inicializacion` pide «legitímelo en el servidor»). `SellosService.LegitimarAsync` ya existe y tiene pruebas. Solo falta el verbo, con las mismas condiciones de `--purgar` (anillo, evento crítico con SID y equipo). RN conserva `--cambiar-rnc` y la visibilidad de los eventos de los verbos para el SUPER (condición 1, [SEG-D] D.2). Es un cambio de reparto **dentro del mismo desarrollador (I)**: no requiere firma | Media | `ComandoSellos.cs` (la documentación remite la legitimación a RN); `Inicializacion.cs` (mensaje `SinSuperUsuario`) | 0,1 dp (sale de RN: neutro) |
| **C-5** | **No unir sin el cambio del instalador del DEMO (devops), en el mismo PR o en uno coordinado.**<br>- `Instalar-Demo.ps1:129` llama `sistema` sin opciones. Con SL no crea cuentas y sale con 2, así que la instalación se detiene en `:132` (y en `:134`). Debe llamar `sistema --cuentas-iniciales --confirmar-sellado --motivo "Instalación del DEMO"`.<br>- `Actualizar-Demo.ps1` no ejecuta `sistema`. Un DEMO ya instalado que se actualice a una compilación Release con SL queda **sin nadie que entre** (`SinSelladoInicial`). Debe ejecutar el sellado inicial, y si SH-7 lo impide (licencia aceptada), `sellos --legitimar` (C-4) por cuenta.<br>- Actualizar `instalador/Demo/LEEME.md:33` | Alta para el DEMO; nula para el código | `instalador/Demo/scripts/Instalar-Demo.ps1:123-135` | 0,25 dp de devops |

## 6. Correcciones recomendadas (no bloquean)

| # | Recomendación | Evidencia | Esfuerzo |
|---|---|---|---|
| R-1 | Hash ficticio también para una cuenta inexistente, inhabilitada o sin hash en `ValidarAsync` (punto 4) | `UsuariosService.cs:42` | 0,05 dp |
| R-2 | Registrar el evento cuando falta el archivo `padron` y se reescribe desde la base (§2.3: «si falta el archivo, se reescribe desde la base y se registra el evento»). Hoy se reescribe en silencio | `PadronSellos.cs:332-333`, `:274-278` | 0,05 dp |
| R-3 | La prueba de los 512 bytes, también con el protector configurado como la API (anillo con `CifradorAnillo` y algoritmo del perfil vigente), como pide ADR-83, punto 1. Con CBC + HMAC, el caso peor ronda los 400 bytes *[I]*, así que no se espera falla | `SellosHabilitacionTests.cs:127-138` | 0,05 dp |
| R-4 | **Orden de unión con la fase A.** `origin/c/adr81-fase-a` cambia los mismos archivos: `UsuariosService` +198, `RevocacionSesiones` +185, `AuthEndpoints` +172, `Program.cs` +59 y `GPOS.Migracion/Program.cs` +59 *[V, `git diff --stat`]*. Recomiendo unir **SL primero**: la fase A tiene que conectarse a `IFactorSuper`, a la entrada de C-2 y a `MapSellos…` de todos modos, y lo hace al rebasar. Coordinar por el área común antes de abrir el PR | — | Coordinación |

## 7. Lo que va a firma (texto corto para la hoja)

### SL-F1 · Restaurar `GPOS_SYSDATA` no devuelve cuentas automáticamente (confirmación)

**Qué se decide.** Si se restaura `GPOS_SYSDATA` desde un respaldo, las cuentas cambiadas después del respaldo (contraseña, nivel, alta o baja) no entran, porque el padrón del disco es más nuevo. ¿Se arreglan solas al liberar el candado de la restauración, o las legitima el SUPER una por una?

| Opción | Consecuencia |
|---|---|
| **(a) El SUPER las legitima una por una, con control del cupo (recomendada)** | Al liberar el candado (R3) se muestra cuántas cuentas quedaron fuera (S-01). Hasta la fase A de ADR-81, las legitima el técnico de GSF en el servidor (`sellos --legitimar`). Si el propio SUPER quedó fuera, solo sirve el verbo en el servidor. Costo ≈ 0,1 dp (el aviso en R3) |
| (b) La liberación del candado vuelve a sellar las cuentas restauradas dentro del cupo | Reconstruye el padrón desde las filas (contra DL-01) y permite recuperar cupo restaurando un respaldo viejo después de una reducción (SEG-L2-07). **No recomendada** |

### SL-F2 · Quién construye `sellos --resellar` y cuándo

**Qué se decide.** ADR-83, punto 7, prevé el verbo `sellos --resellar --motivo` con acta para cuando se pierde el anillo y la recuperación anclada (H-17 v2) no alcanza. Ninguna pieza lo construye. Es la única herramienta que crea un padrón nuevo desde las filas, así que necesita reglas:
- solo funciona si ni la base ni el disco tienen un padrón que verifique con el anillo vigente, y si `Licencia.InstalacionId` verifica;
- muestra la lista y pide `--confirmar` y motivo;
- deja un evento crítico con la cuenta de Windows;
- sella solo las cuentas habilitadas;
- **si superan el cupo, la empresa queda `EnExceso`** (ADR-58, punto 9): nadie pierde la sesión, pero no se admiten altas.

| Opción | Consecuencia |
|---|---|
| (a) Antes del corte de mediados de diciembre | ≈ 0,4 dp más para el desarrollador I antes del corte |
| **(b) Antes de la primera licencia de pago, con las reglas de arriba (recomendada)** | Se agrega a «Lo que exige la primera licencia de pago». Hasta entonces, perder el anillo sin recuperación anclada deja a todos fuera hasta un parche (probabilidad Baja, impacto Alto; solo hay instalaciones de desarrollo y DEMO) |
| (c) Sin verbo: solo la recuperación anclada | Exige una precisión de ADR-83, punto 7. No recomendada: sin salida si falla H-17 |

## 8. Lo que se acepta

- Las desviaciones (a), (c) y (d), y la (b) salvo `SEGUNDO_FACTOR`.
- Los puntos (2) y (3).
- **Reparto L/I (§4.3):**
  - SL no modifica ningún archivo de L: ni `GPOS.Contracts/Licencia`, ni `GPOS.Core/Sistema/Licencia`, ni `LicenciaEndpoints.cs`, `ModoLicencia.cs` o `SqlLicenciaSistema.cs`. Solo usa sus API públicas: `IEstadoLicencia.CupoUsuarios`, `ProtectorLicencia`, `ClavesLicencia`, `AlmacenLicenciaDisco.Preparar/Procesados/CarpetaPorOmision` y los códigos de `CodigosLicencia`.
  - **Toca `GPOS.Api/Program.cs`** (+16 líneas: registros, `MapSellos` y `SellarAlArrancarAsync`). §4.3 no lo previó para SL, pero es inevitable y está en un bloque propio: **se acepta**, rebasando sobre la última versión de la rama de destino antes del PR.
  - Las rutas S-01, S-02 y S-04 en `SellosEndpoints.cs` (de I) y no en `LicenciaEndpoints.cs` (de L) **mejoran** el reparto: se acepta.
- **Punto de conexión de `FactorAlta` (fase A de ADR-81):**
  - `IFactorSuper` registrado sin condición (`Program.cs:255`, con `SinFactorSuper`) y documentado (`FactorSuper.cs:7-12`): correcto.
  - `ComandoSellos.Servicio(…, factor)`: correcto, con C-3.
  - `UsuariosService.ResellarAsync`: **no conforme**, ver C-2. Su protección contra la legitimación (`EsCambioDeFactor`) sí es correcta.
  - `MapSellosConSegundoFactor`: **no conforme**, ver C-1.
- La legitimación de una cuenta inhabilitada la sella fuera del padrón (`SellosService.cs:99-100`). Es coherente con el punto (3).

## 9. Entregas a otros agentes

| Agente | Qué necesita |
|---|---|
| Desarrollador L | Quitar `CodigoSegundoFactor` de `LegitimarCuentaRequest` y `PurgarEntradaPadronRequest` (P-81A-16 (a)). Agregar `PADRON_NO_DISPONIBLE` y `MOTIVO_REQUERIDO` a `CodigosLicencia` cuando la Web los consuma, con el mismo literal |
| Devops | C-5: `Instalar-Demo.ps1`, `Actualizar-Demo.ps1` y `LEEME.md` del DEMO |
| Equipo C (fase A de ADR-81) | Conectar la implementación de `IFactorSuper` en la API y en `ComandoSellos` (C-3); usar la entrada de C-2 en el alta, la baja y el restablecimiento del factor; mapear S-02 y S-04 con `RequiereAutenticacionReciente()` en el PR posterior a la fase A; rebasar después de SL (R-4) |
| H-11 (candado CR-01) | Si se firma SL-F1 (a): el aviso del número de cuentas S-01 al liberar el candado de `GPOS_SYSDATA` |
| Arquitecto de datos | `[DAT]` 6.3: el sellado inicial sella también las inhabilitadas, fuera del padrón (punto 3) |
| Arquitecto Maestro y documentador | Nota de registro en ADR-83, punto 8 (nombres de eventos en mayúsculas); llevar SL-F1 y SL-F2 a la hoja |
| QA | Ejecutar la suite oficial con las 39 pruebas de `Usuarios/Sellos` y la prueba de C-2, después de las correcciones |

---

### Cierre
- Estado: Aprobado con observaciones (veredicto de la pieza: **Conforme con correcciones**; C-1 a C-5 antes del PR)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-sl-sello-padron-2026-10-17.md`
- Supuestos: no se compiló ni se ejecutaron pruebas; el interbloqueo de C-2 (i) y la sesión revocada de C-2 (ii) son inferencias por lectura del código; los 400 bytes del sello más largo son una estimación.
- Decisiones candidatas a ADR: SL-F1 (confirmación de ADR-83, punto 2, ante una restauración); SL-F2 (precisión de ADR-83, punto 7: reglas y momento de `sellos --resellar`).
- Entregas a otros agentes: ver la sección 9.
- Próximo paso recomendado: el desarrollador I aplica C-1 a C-4 y coordina C-5 con devops; después, PR de SL antes de rebasar la fase A.
