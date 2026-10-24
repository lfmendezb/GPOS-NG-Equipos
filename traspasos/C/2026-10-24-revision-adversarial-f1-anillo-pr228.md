```
Para: B (copia para A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (tanda 6, punto 1, y tanda 8, punto 4: revisión adversarial de F1, el anillo del servicio, PR #228)
Prioridad: Alta (unión antes del 5-nov; A escribe PR-D2 sobre F1 del 5 al 9-nov)
Repositorio y rama: GPOS-NG origin/b/f1-anillo @ e1c6f516 (base feature/modelo-ng b9efa9fb), en el worktree de C, sin commit ni push
Estado: Abierto
```

# Revisión adversarial de F1 (DM-07): `anillo --preparar`, archivo del anillo, G-1, G-2 y SA-01 a SA-06 (PR #228)

**Método.** Hice checkout de `origin/b/f1-anillo` (`e1c6f516`) en mi worktree, leí los 28 archivos del diff y lo contrasté con el blueprint (#219, `origin/b/blueprint-tls-anillo`), con el aviso de B de los SA firmados y con mis dos documentos de referencia: la revisión del blueprint (SA-01 a SA-15) y el plan de pruebas DM-07 (QA-AN, K-01 a K-17, MU-AN). Hice tres cosas:

- **11 pruebas propias** (anexo `2026-10-24-revision-adversarial-f1-anillo-pr228-pruebas.cs.txt`). Cada una afirma el comportamiento actual: si pasa, el hallazgo queda demostrado.
- **31 mutaciones**, aplicadas una a la vez y restauradas con `git checkout` después de cada una (la tabla está en la sección 7).
- **El subconjunto del anillo** de la suite, contra SQL Server (`GPOST_TEST_SERVER=.`).

No cambié el PR ni lo comenté. Hubo una sola compilación a la vez.

**Lo que no pude correr.** La consola no está elevada, así que no corrí nada que exija administrador:

- crear una llave de CNG de la máquina;
- escribir en `LocalMachine\My`;
- `icacls` sobre el contenedor;
- servicios reales.

Eso cubre W-AN-01 a W-AN-05 y LABA-xx, que corre B en la VM. Lo que depende de esos casos lo razono por línea y lo marco **[I]**. **[V]** = verificado en el código o ejecutado.

**Resultado ejecutado.**

- Subconjunto (`Categoria=Anillo`, arquitectura del anillo, `EventIdUnicos`, `OrdenProgramaApi`, `ArchivoInstalacionTests`) con mis 11 pruebas: **412 de 412 correctas** en 3 min 24 s.
- Mutaciones: **24 muertas y 7 sobreviven**.

## 1. Alcance y superficie revisada

| Superficie | Archivo | Revisada |
|---|---|---|
| `anillo --preparar`: pasos 1 a 12, SA-01 (huella dictada), SA-02 (vencido = aviso), SA-03 (regenerar) | `src/GPOS.Migracion/Anillo/PrepararAnillo.cs` | Sí, línea a línea |
| Llave de CNG, descriptor y almacén | `Certificados/AlmacenMaquinaWindows.cs`, `DescriptorLlave.cs`, `IAlmacenMaquina.cs` | Sí. Lo real se ve en W, en la VM |
| Archivo `GPOS.Api.anillo.json`: esquema, regla 3, conflicto de fuentes, SA-03 | `src/GPOS.Core/Infraestructura/Anillo/ArchivoAnillo.cs` | Sí |
| API: fuente del archivo, evento 4704, ancla al arrancar, aviso SA-06 | `src/GPOS.Api/Program.cs:37`, `Servicios/ProteccionDatos.cs`, `ComprobacionAnillo.cs:78-98, 189-196` | Sí |
| `GPOS.Migracion`: el mismo archivo, G-1, G-2, `--anclar` con huella, salida de `--comprobar` | `ConfiguracionMigracion.cs`, `Program.cs:56-61, 334-345`, `GuardasAnillo.cs`, `MantenimientoAnillo.cs`, `ComandosAnillo.cs` | Sí |
| Endpoints HTTP | — | No aplica: F1 no agrega ni cambia endpoints |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Prueba que lo demuestra |
|---|---|---|---|
| SF-01 | **Alta** | SA-01 queda abierta en los otros dos caminos que anclan: `anillo --cambiar-recuperacion` y `anillo --migrar` anclan el `.cer` configurado sin huella dictada | `SF01a_…`, `SF01b_…` (correctas) |
| SF-02 | Media | `sistema` sin `--cuentas-iniciales` ni `--confirmar-sellado` escribe `Licencia.InstalacionId` con el anillo del proceso, y G-1 no lo cubre | `SF02_…` (correcta) |
| SF-03 | Media | Con el orden de 3.3 (PR-D2), `sistema --login-api` corre antes de `--anclar` y en una instalación nueva falla con `AnilloSinAncla` a mitad del verbo | `SF03_…` (correcta) |
| SF-04 | Baja | Si la fila del ancla no se puede leer al arrancar, SA-03 no aplica la falla cerrada: solo deja un aviso y la API sigue con DPAPI | `SF04_…` (correcta) |
| SF-05 | Baja | Una instalación con el anillo configurado por claves sueltas (antes de F1) y llaves en `Api\anillo` deja de arrancar al actualizar, y la reparación puede exigir la ceremonia de recuperación | `SF05_…` (correcta) |
| SF-06 | Media | El cableado de G-1 y G-2 en `GPOS.Migracion/Program.cs` no tiene prueba: si se quita, ninguna prueba falla | MC-23 y MC-24 sobreviven |
| SF-07 | Baja | Cinco huecos de prueba más: el conflicto de fuentes solo se prueba en 2 de 5 claves; la máscara traducida de control total se acepta para la cuenta; el sobre de prueba; el principal vencido en la idempotencia; el aviso de 180 días en `--preparar` | MC-07, 09, 18, 29 y 31 sobreviven |
| SF-08 | Baja | El esquema del archivo admite rutas UNC y huellas anteriores repetidas o iguales a la vigente (D-AN-13 y D-AN-14 sin cerrar) | `SF06_…` (correcta) |
| SF-09 | Baja (informativa) | `DescriptorLlave.Comprobar` no exige `SE_DACL_PROTECTED`, aunque `Crear` sí lo pone | `SF07_…` (correcta) |

Ningún hallazgo Crítico.

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Bien: descriptor de la llave en la misma llamada [V, `AlmacenMaquinaWindows.cs:30-42`], comprobación exacta de tres entradas (MC-08 muerta), regla 3 del archivo y de `config` (MC-10 y MC-15 muertas). Pendiente de W: el efecto real de `GENERIC_READ` y la ACL del contenedor (W-AN-02). Observaciones: SF-06 y SF-09 |
| A02 Fallas criptográficas | Perfil correcto (RSA 3072, PKCS#1 v1.5 solo en la autofirma, EKU *Document Encryption*, `cA = false`, serie de 16 bytes) [V, `PrepararAnillo.cs:199-212`, prueba de perfil]. Distribución de llaves: SF-01 |
| A03 Inyección | No aplica: no hay SQL nuevo con texto del usuario. El JSON es estricto (`MaxDepth = 4`, sin comentarios ni comas finales, 16 KB) [V, `ArchivoAnillo.cs:49-53`]. El XML de las llaves se lee con DTD prohibido [V, `:276`] |
| A04 Diseño inseguro | SF-01, SF-02 y SF-03 |
| A05 Configuración insegura | Bien: una sola fuente (MC-06 muerta) y DPAPI rechazado con el archivo (MC-21 muerta). Observaciones: SF-04, SF-07 (MC-07) y SF-08 |
| A06 Componentes vulnerables | No aplica: solo la BCL de .NET 10 |
| A07 Identificación y autenticación | No aplica: no toca el inicio de sesión ni los tokens |
| A08 Integridad de software y datos | SF-01 (integridad de la llave pública de recuperación) y SF-02 (integridad de `Licencia.InstalacionId`) |
| A09 Registro y monitoreo | Bien: el 4704 es único y no vuelca valores (prueba de control, SA-11 cerrado), y el aviso de 180 días va al 4717 como Warning [V, `ComprobacionAnillo.cs:191-195`]. Observación: SF-04 deja un Warning donde la regla pide un 4704 crítico |
| A10 SSRF | No aplica |

## 4. Hallazgos

### SF-01 · Alta · SA-01 abierta en `--cambiar-recuperacion` y `--migrar`

- **Riesgo.** Es el mismo de SA-01 y con la misma severidad que le di en el blueprint (probabilidad baja, impacto crítico). F1 exige la huella dictada por un segundo canal en `--preparar` y en `--anclar`, pero otros dos verbos también fijan el ancla con la recuperación configurada y no la piden:
  - **`--cambiar-recuperacion`** reenvuelve la llave predeterminada para la recuperación nueva, revoca las anteriores y re-ancla. Si el `.cer` nuevo se sustituye en tránsito, quien tenga después una copia de `Api\anillo` y de `GPOS_SYSDATA` descifra todo sin el servidor, y el ancla consagra la llave ajena.
  - **`--migrar`** (desde DPAPI, sin ancla previa) ancla igual que `--anclar`, pero sin la comprobación.
  - Además, con el archivo del anillo **no hay camino soportado para entregar el `.cer` nuevo**: `--preparar` devuelve 4 («para cambiarla, `--cambiar-recuperacion`»), la ruta fija es `config\GPOS.Api.recuperacion.cer` y la regla 4 impide indicarla por otra fuente. El técnico tendría que sobrescribir a mano un archivo de `config`, y el blueprint dice que no se edita a mano.
- **Evidencia [V].**
  - `MantenimientoAnillo.cs:147-148` (`--migrar`: `FijarAnclaAsync(HuellaRecuperacionConfigurada(), …)` sin huella esperada).
  - `MantenimientoAnillo.cs:214, 229` (`--cambiar-recuperacion`: `var nueva = HuellaRecuperacionConfigurada();` → `FijarAnclaAsync(nueva, …)`).
  - `ComandosAnillo.cs:59-66`: solo `anclar` recibe `huella-recuperacion`.
  - Pruebas `SF01a_cambiar_recuperacion_ancla_un_cer_sustituido_sin_huella_dictada` (el ancla queda con la huella ajena, `Cumple = true`, y la llave conforme nueva va envuelta para ella) y `SF01b_migrar_desde_DPAPI_ancla_sin_huella_dictada`: correctas.
  - B lo anticipó en su aviso para `--migrar`.
- **Remediación** (≈0,1 dp; sin tecnología nueva):
  1. `--migrar` (cuando no hay ancla) y `--cambiar-recuperacion` exigen `--huella-recuperacion` y la comparan con `HuellaDictada`, como `AnclarAsync` (`MantenimientoAnillo.cs:102-108`).
  2. `--cambiar-recuperacion --recuperacion <nuevo.cer> --huella-recuperacion <sha256>` lee el `.cer` una vez, lo verifica y lo escribe con `EscribirAtomico` en `config\GPOS.Api.recuperacion.cer` antes de re-anclar. Así hay un solo escritor y nadie edita `config` a mano.
  3. Pruebas: los mismos `SF01a` y `SF01b`, invertidos (salida de error y ancla intacta).
- **Al propietario:** amplía SA-01 a los verbos que anclan, con el mismo criterio de ADR-63. Si prefiere no hacerlo en F1, puede aceptar el residuo por escrito para estos dos verbos, que son de uso raro; entonces lo bajo a Media.

### SF-02 · Media · `sistema` sin banderas escribe `Licencia.InstalacionId` y G-1 no lo cubre

- **Riesgo.** El blueprint justifica G-1 así: «nunca se escribe `Licencia.InstalacionId` … con un anillo de DPAPI del técnico». Pero `ComandoSistema.AplicarAsync` llama a `AsegurarInstalacionAsync` **siempre** que recibe el proveedor, y `Program.cs` se lo pasa siempre. Por eso `sistema --login-api` (el primer paso de `esquema` en PR-D2) escribe la fila sin pasar por G-1.
- **Cuándo pasa:** con el servicio instalado, sin el archivo del anillo y con `GPOS.Migracion` en DPAPI (DEMO con `DpapiDemo` en `GPOS.Migracion.json`, o claves sueltas). La fila queda protegida con la DPAPI del técnico. Desde ahí, el servicio no la verifica y **nadie la reemplaza** («existe pero no verifica … no se reemplaza»): la identidad de la instalación queda rota hasta que alguien edite la base a mano.
- **Evidencia [V].**
  - `GuardasAnillo.cs:31`: `"sistema" => o.Contains("cuentas-iniciales") || o.Contains("confirmar-sellado")`.
  - `ComandoSistema.cs:93`: `if (proteccion is not null) informar(await AsegurarInstalacionAsync(…))`.
  - `Program.cs:334, 344`: el proveedor se pasa siempre.
  - Prueba `SF02_…`: correcta. La fila escrita con DPAPI hace que el anillo con certificado lance «no verifica».
  - En Release sin `DpapiDemo`, AN-05 ya lo impide antes [V, `ProteccionDatosInstalacion.cs:84-87`]: por eso es Media.
- **Remediación** (≈0,05 dp): `UsaElAnillo("sistema", …)` devuelve `true` siempre (todo `sistema` usa el anillo por `AsegurarInstalacionAsync`), o `sistema` solo asegura `InstalacionId` con `--cuentas-iniciales`, ya pasada G-2. Lo segundo cierra también SF-03.

### SF-03 · Media (funcional) · El orden de 3.3 falla en `sistema --login-api` en una instalación nueva

- **Riesgo.** El orden de PR-D2 en el blueprint, paso 4 (`esquema`), es `sistema --login-api` → `actualizar --todas` → `rpt` → `anillo --anclar` → `sistema --cuentas-iniciales --confirmar-sellado`. `--anclar` no puede ir antes, porque `sistema` es quien crea `GPOS_SYSDATA` (`ComandoSistema.cs:50`, `EnsureCreatedAsync`).
- **Qué pasa.** Con el anillo con certificado ya preparado (paso 3) y la carpeta sin llaves, `sistema --login-api` llega a `AsegurarInstalacionAsync`. La primera protección necesita crear una llave, y el cifrador se niega sin ancla (`AnilloSinAncla`, `AnilloDataProtection.cs:126-127`). El verbo sale con error **después** de crear la base y aplicar S1, pero sin `InstalacionId` y sin `SubirMarca`.
- **Consecuencia.** `implantar-servidor` falla en el primer paso de `esquema`. Una segunda pasada después de `--anclar` sí funciona, porque `--anclar` crea la primera llave al proteger su fila.
- **Evidencia [V].**
  - Prueba `SF03_sistema_login_api_antes_de_anclar_falla_en_una_instalacion_nueva_con_el_anillo_con_certificado`: correcta. Lanza con `AnilloSinAncla`; después de `--anclar`, «generado».
  - No lo vería nadie hasta W-AN-03 o el ensayo del 16-nov.
- **Remediación** (≈0,1 dp, B o A):
  - **(a) Recomendada:** `AsegurarInstalacionAsync` solo con `--cuentas-iniciales`, después de G-2. Si el anillo con certificado está en `SinAncla`, `sistema` informa «`InstalacionId` pendiente hasta `anillo --anclar`» y sale con 2.
  - **(b) Alternativa:** que A ponga en `FaseEsquema` el orden `sistema --login-api` (que tolera el `SinAncla`) → `--anclar` → resto.

  Es una precisión del 3.3 del blueprint que debe llegar a A antes del 5-nov.

### SF-04 · Baja · Fila del ancla ilegible al arrancar: aviso, no falla cerrada

- **Riesgo.** La SA-03 firmada dice que la API no arranca sin el archivo si existe la fila del ancla. Si la lectura de esa fila falla (la base no responde porque SQL Server arranca después del servicio, o hay un error transitorio), el arranque solo registra `LogWarning` y sigue con DPAPI. El camino solo existe con `DpapiDemo` o en Debug, sin llaves en `Api\anillo`: en Release sin `DpapiDemo` manda AN-05.
- **Evidencia [V].** `ComprobacionAnillo.cs:83-92` (`catch (Exception ex) when (ex is not OperationCanceledException) { log?.LogWarning(…) }`). Prueba `SF04_…`: correcta, `EjecutarAlArrancarAsync` no lanza.
- **Remediación** (0,02 dp): en ese `catch`, lanzar `ArchivoAnilloNoConformeException` («no se pudo comprobar el ancla sin el archivo del anillo») con el 4704. Las acciones de recuperación del servicio (`restart, restart, none`, MSI `1232d0af`) cubren un SQL lento. Sin la base, la API tampoco sirve, así que fallar cerrado no cuesta disponibilidad real.

### SF-05 · Baja · Actualizar a F1 una instalación con el anillo por claves sueltas

- **Riesgo.** La regla 1 dice que, sin el archivo, todo sigue como hoy. Pero `Validar` comprueba SA-03 **antes** de mirar si el anillo viene por claves sueltas: una instalación que ya usaba el anillo con certificado por `GPOS:DataProtection:*` (laboratorio o DEMO de `feature/modelo-ng`), con llaves en `%ProgramData%\GPOS NG\Api\anillo`, no arranca al actualizar.
- **La reparación que se ofrece puede costar la ceremonia de recuperación.** `--preparar` solo regenera el archivo si el principal pasa `MotivoCertificado` (descriptor exacto, proveedor de software, de la máquina). Un principal creado antes de F1 por otro medio no lo pasa, y `--preparar` crea un segundo principal y sale con 2. Eso es lo que SA-03 quería evitar.
- **Evidencia [V].** `ArchivoAnillo.cs:307-312`; `PrepararAnillo.cs:320-326`. Prueba `SF05_…`: correcta. La salida 2 sin la privada ya la prueba B (`Preparar_sin_el_archivo_y_sin_la_privada_del_principal_crea_otro_y_sale_con_2`).
- **Remediación:** decir en las notas de F1 que en producción no hay instalaciones con el anillo por claves sueltas [I: lo confirma B]. Para las VM y los DEMO, un procedimiento corto: reconstruir desde cero o adoptar el principal existente con acta (`--preparar --adoptar <huella>`, que avisa en lugar de exigir el descriptor exacto). 0 dp si se documenta; 0,1 dp si se agrega la opción.

### SF-06 · Media · G-1 y G-2 sin prueba de su cableado

- **Riesgo.** Las guardas tienen buenas pruebas como funciones (MC-13, MC-14 y MC-22 muertas). Pero si alguien quita su llamada en `GPOS.Migracion/Program.cs`, ninguna prueba falla:
  - MC-23 (`if (false && … ComprobarArchivo(`) sobrevive;
  - MC-24 (`if (false && await … ComprobarAnclaAsync`) sobrevive.

  Son controles de seguridad, y `Program.cs` es zona compartida (DB-7, PR-D2): el riesgo de regresión es real. Es ANI-AR08/M10 de mi plan.
- **Remediación** (0,05 dp): una prueba de texto como `OrdenProgramaApiTests`. Afirma que `ComprobarArchivo` corre antes del primer `EmpresasSistema(` y que todo `EmpresasSistema(config).Servicios()/Proveedor()` de `sistema` pasa por `ComprobarAnclaAsync` cuando hay banderas. Mejor todavía: un punto único `GuardasAnillo.Proveedor(verbo, …)` del que salga el proveedor (R-A8).

### SF-07 · Baja · Mutantes que sobreviven (huecos de prueba)

| Mutante | Qué cambia | Por qué importa | Prueba que falta |
|---|---|---|---|
| MC-07 | La regla 4 deja de comparar `CertificadoRecuperacion`, `IdentidadServicio` y `CertificadosServidorAnteriores` | Una variable con otra recuperación pasaría sin conflicto (el archivo gana por ser la última fuente, pero la regla promete una sola fuente) | ANI-F09: las 5 claves × las fuentes |
| MC-09 | Acepta `0x001F01FF` (control total traducido) como máscara de la cuenta del servicio | Si el KSP guarda los derechos traducidos [I, W-AN-02], la cuenta podría borrar la llave o cambiar su ACL sin que el paso 9 lo vea | Un caso de la teoría del descriptor con la máscara traducida |
| MC-18 | Quita `ProbarSobre` del paso 9 | La tercera verificación del paso 9 no tiene prueba (en el doble siempre abre) | Un doble cuya privada no abra el sobre |
| MC-29 | La idempotencia acepta un principal vencido como «ya estaba» (0) | `--preparar` repetido no avisaría de un anillo sin certificado vigente | ANI-O08 o T03 |
| MC-31 | Quita el aviso de 180 días de `--preparar` | Ídem, el aviso del paso 5 | ANI-O08 (179, 180 y 181 días) |

Esfuerzo de las cinco: ≈0,15 dp.

### SF-08 · Baja · El esquema admite UNC y huellas anteriores repetidas

- **Qué admite.** `Absoluta()` acepta `\\servidor\recurso\…` en `carpeta` y en `certificadoRecuperacion`, y la lista de anteriores admite repetidas y la vigente [V, `ArchivoAnillo.cs:79-84, 130`; prueba `SF06_…`].
- **Por qué es Baja.** Solo un administrador escribe el archivo, y `--preparar` siempre pone rutas locales. Pero una carpeta UNC haría que la API lea las llaves por la red con la cuenta de máquina.
- **Remediación** (0,03 dp): `carpeta` bajo `%ProgramData%\GPOS NG` (o al menos local, sin `\\`); `certificadoRecuperacion` igual a `config\<servicio>.recuperacion.cer`; anteriores sin repetidas y distintas de la vigente. Cierra D-AN-13 y D-AN-14.

### SF-09 · Baja (informativa) · `Comprobar` no exige la DACL protegida

`DescriptorLlave.Comprobar` acepta el mismo descriptor sin `SE_DACL_PROTECTED` [V, prueba `SF07_…`]. El efecto práctico es mínimo: una ACE heredada de otra cuenta aparecería como entrada de más y se rechazaría igual; una heredada de SYSTEM o Administradores se rechazaría como «repetida». Para que el paso 9 sea igual a lo que `Crear` pone, basta una línea: `if (!sd.ControlFlags.HasFlag(ControlFlags.DiscretionaryAclProtected)) return "…"`.

## 5. Controles bien implementados (verificados)

- **SA-01 en `--preparar` y `--anclar`:**
  - huella obligatoria, comparada antes de tocar nada; con otra huella, salida 4 [V, `PrepararAnillo.cs:103-122`; MC-01 muerta];
  - `--anclar` rechaza una huella distinta [V, `MantenimientoAnillo.cs:102-108`; MC-02b muerta];
  - el `.cer` se lee una sola vez y se copian esos mismos bytes (`recuperacion.RawData`) [V, `:117-118, 166`]. El TOCTOU que señalé en SA-01 queda cerrado.
- **SA-02:** un `.cer` vencido es solo aviso [V, `:306-310`; MC-03 muerta].
- **SA-03:**
  - sin archivo y con llaves, la API no arranca, también con `DpapiDemo` [MC-04 muerta];
  - sin archivo y con la fila del ancla, no arranca [MC-05 muerta, contra SQL];
  - `--preparar` regenera el archivo con el principal existente sin crear otro, y rechaza llaves con otra recuperación [MC-11 muerta];
  - el mensaje de AN-05 nombra `--preparar` [V, `ProteccionDatosInstalacion.cs:85-87`].
- **SA-06:** `--comprobar` sale con 2 cuando quedan menos de 180 días [MC-12 muerta], el arranque deja un Warning en el 4717 y `ResultadoComprobacionAnillo.CodigoSalida` está listo para PR-V.
- **SA-11 (para el 4704):** el mensaje del conflicto nombra la clave y no el valor (prueba de control con centinela).
- **SA-15:** fuera de Windows, la regla 3 falla antes de interpretar el archivo [V, `ArchivoAnillo.cs:154, 247`].
- **K-01, K-02 y K-16:** la llave es RSA 3072 en el proveedor de software, `MachineKey`, `ExportPolicy = None` (no es un parámetro: `ParametrosLlaveRsa.Exportable => false`), con el descriptor en la misma llamada [V, `IAlmacenMaquina.cs:7-17`, `AlmacenMaquinaWindows.cs:30-42`; MC-16 muerta]. El nombre de la llave lleva un sufijo aleatorio (QA-AN-05 cerrado).
- **El paso 9 rechaza:** llave exportable, de usuario, de otro proveedor, de menos de 3072 bits o con un descriptor distinto [MC-08 y MC-17 muertas]. Si algo falla, quita el certificado y la llave [MC-25 muerta].
- **K-03:** perfil del certificado completo en la prueba de B. Nota: no afirma el conjunto exacto de extensiones (un SAN de más no lo vería).
- **K-05:** `--preparar` no abre la base [V, `ComandosAnillo.cs:28`]. No crea la raíz ni `config` [V, `:124-125`]. La cuenta tiene que ser `S-1-5-80-…` [MC-20 muerta]. Exige elevación [MC-19 muerta].
- **K-07 y K-08:**
  - JSON estricto de 7 propiedades, `v = 1`, huellas en minúsculas, identidad del servicio [MC-28 muerta];
  - regla 3 del archivo y de `config` [MC-10 y MC-15 muertas];
  - una sola fuente [MC-06 muerta];
  - DPAPI rechazado con el archivo [MC-21 muerta];
  - sin recarga;
  - el archivo se lee con el identificador ya abierto y sin compartir el borrado [V, `ArchivoAnillo.cs:234-251`]. ANI-F12 queda bien resuelto.
- **K-09:** `GPOS.Migracion` agrega el archivo como **última** fuente, después del entorno [MC-26 muerta]. El anfitrión real de ASP.NET expone el proveedor del archivo a la comprobación del arranque (prueba de control con `WebApplication.CreateBuilder`).
- **QA-AN-03:** la línea nueva de la API está vigilada por la prueba de arquitectura [MC-27 muerta].
- **Evento:** el 4704 es único y el 4729 no se usa en `src` [V, `grep`].
- **G-1 y G-2 como funciones:**
  - G-1 falla cerrada si el SCM no responde (D-AN-06) [MC-14 muerta];
  - la lista de verbos está probada [MC-13 muerta];
  - G-2 exige `Anclada` [MC-22 muerta].
- Se corrigió `OpcionesComando["sistema"]` (`--cuentas-iniciales`, `--confirmar-sellado`, `--motivo`) [V, `OpcionesComando.cs:25`].

## 6. Estado de mis hallazgos y planes anteriores

**Revisión del blueprint (SA-01 a SA-15)**

| ID | Estado en `e1c6f516` |
|---|---|
| SA-01 | **Cerrada** en `--preparar` y `--anclar`. **Abierta** en `--cambiar-recuperacion` y `--migrar` (SF-01) |
| SA-02 | **Cerrada** en el código. El procedimiento de P-2 (30 años, 3072 bits, AES-256) es un documento: no lo verifiqué en el PR; el mensaje del aviso lo cita |
| SA-03 | **Cerrada** (las tres partes), con dos residuos: SF-04 y SF-05. El punto 4 (respaldar `config\*.anillo.json` y el `.cer` con `Api\anillo`) no está en el código; es de procedimiento (H-17 v2) y de A en `restaurar` |
| SA-04, SA-05, SA-07, SA-08, SA-09, SA-13 | Abiertas, fuera de F1 (no firmadas, o son de F2, F4, devops o propietario) |
| SA-06 | **Cerrada** en la parte firmada (`--comprobar` con 2 y Warning al arrancar). `comprobar-servidor` es de A (PR-V). Sin aviso diario ni guarda del reloj (no firmados) |
| SA-10 | **Mitigada en parte:** una variable de usuario con otro valor de las 5 claves del anillo se rechaza (regla 4). `ConnectionStrings__Sistema` y `GPOS__Seguridad__ModoIdentidad` siguen entrando desde el entorno del usuario (A) |
| SA-11 | **Cerrada** para el 4704 |
| SA-12 | Abierta, sin cambios: la carpeta no conforme solo impide el arranque en Estricto |
| SA-14 | Abierta (A) |
| SA-15 | **Cerrada** para F1 (Linux, falla antes de interpretar). La parte de la entrega 2 sigue como nota |

**Plan de pruebas DM-07**

| ID | Estado |
|---|---|
| QA-AN-01 | Abierta: con llaves de otro principal antes de `--recuperar`, `ComprobacionAnillo` sigue creando una llave nueva (sin cambios en F1) |
| QA-AN-02 | Cerrada: archivo inválido y certificado ausente salen con 4 sin tocar nada |
| QA-AN-03 | Cerrada (MC-27) |
| QA-AN-04 | Abierta, Baja: no hay exclusión mutua en `--preparar`. Dos ejecuciones dejan un certificado huérfano; el último archivo gana |
| QA-AN-05 | Cerrada: sufijo aleatorio |
| QA-AN-06 | Abierta: no hay costura `esDepuracion`; AN-05 en Release sigue sin probarse desde la suite en Debug |
| QA-AN-07 | Abierta: `AnilloPrueba.Anclar` sigue con `DateTime.UtcNow` |
| QA-AN-08 | Informativa: se mira en W-AN-02 |

**K-01 a K-17**

| ID | Estado |
|---|---|
| K-01, K-02 | Cumplen en el código; falta W-AN-01 y W-AN-02 en la VM. K-02: ver MC-09 |
| K-03 | Cumple |
| K-04 | Cumple (vencido = aviso, SA-02) |
| K-05 | Cumple |
| K-06 | Cumple, con los huecos MC-29 y MC-31 |
| K-07, K-08 | Cumplen. Evento 4704 en lugar del 4729 (desviación conocida) |
| K-09 | Cumple |
| K-10 | Cumple como función; falta `sistema` sin banderas (SF-02) y el cableado no tiene prueba (SF-06) |
| K-11 | Cumple como función; cableado sin prueba |
| K-12 | Cumple (salida 2). R03 = QA-AN-01 |
| K-13 | Cumple |
| K-14 | Cumple, salvo SF-04 |
| K-15 | 0, 1, 2 y 4. Sin `--huella-recuperacion`, 1; con otra huella, 4 |
| K-16 | Cumple: ningún PFX ni PKCS#8 a disco (prueba de arquitectura `Solo_AlmacenMaquinaWindows…`) |
| K-17 | Cumple con el 4704 |

**Mutaciones MU-AN:** las 31 que corrí cubren las responsabilidades de MU-AN-01 a 14, 27 a 33, 39, 40, 43 a 45, 49 a 51, 53 a 56, 61, 63 y 64. Las de W (MU-AN-34, 36 a 38, 42 y 62) quedan para la VM.

## 7. Mutaciones ejecutadas (una a la vez, restauradas)

El guion `mutar.sh` hace lo siguiente en cada mutación:

1. reemplaza texto literal con `perl`;
2. compila `tests/GPOS.Tests`;
3. corre el filtro;
4. restaura con `git checkout -- <archivo>`.

`git status` quedó limpio, salvo mi archivo de pruebas.

| ID | Archivo | Mutación | Resultado | Lo mata |
|---|---|---|---|---|
| MC-01 | `PrepararAnillo.cs` | Sin comparar la huella dictada | Muerta | `Preparar_sin_la_huella_dictada_o_con_otra_no_toca_nada` |
| MC-02b | `MantenimientoAnillo.cs` | `--anclar` sin comparar la huella | Muerta | `Anclar_con_otra_huella_dictada_no_ancla` |
| MC-03 | `PrepararAnillo.cs` | Rechazar el `.cer` vencido | Muerta | `Preparar_con_la_recuperacion_anclada_vencida_continua_con_aviso` |
| MC-04 | `ArchivoAnillo.cs` | Sin la falla cerrada por llaves (SA-03) | Muerta | `Sin_el_archivo_y_con_llaves_del_anillo_en_Api_anillo_no_arranca` (×2) |
| MC-05 | `ComprobacionAnillo.cs` | Ignorar la fila del ancla | Muerta | `Sin_el_archivo_del_anillo_y_con_el_ancla_en_la_base_la_API_no_arranca` |
| MC-06 | `ArchivoAnillo.cs` | Sin la regla 4 | Muerta | `Archivo_anillo_y_variable_con_otro_valor_no_arranca` |
| MC-07 | `ArchivoAnillo.cs` | Regla 4 solo para 2 de 5 claves | **Sobrevive** | — (SF-07) |
| MC-08 | `DescriptorLlave.cs` | «Contiene» en vez de «exactamente» | Muerta | `El_descriptor_de_la_llave_se_rechaza_…` |
| MC-09 | `DescriptorLlave.cs` | Control total traducido para la cuenta | **Sobrevive** | — (SF-07) |
| MC-10 | `ArchivoAnillo.cs` | Sin comprobar el dueño (regla 3) | Muerta | `La_regla_3_admite_lectura_…` |
| MC-11 | `PrepararAnillo.cs` | Regenerar con otra recuperación | Muerta | `Preparar_sin_el_archivo_y_con_llaves_de_otra_recuperacion_sale_con_4` |
| MC-12 | `ComprobacionAnillo.cs` | Aviso a 90 días | Muerta | `El_aviso_de_los_180_dias_sale_con_2_…` |
| MC-13 | `GuardasAnillo.cs` | G-1 sin `empresa` | Muerta | `Con_el_servicio_instalado_y_sin_archivo_…` |
| MC-14 | `GuardasAnillo.cs` | G-1 abierta si el SCM no responde | Muerta | ídem (10 casos) |
| MC-15 | `ArchivoAnillo.cs` | Sin comprobar `config` | Muerta | `Archivo_anillo_con_DACL_ajena_o_reanalisis_no_arranca` |
| MC-16 | `AlmacenMaquinaWindows.cs` | `AllowExport` | Muerta | `La_version_Windows_pide_a_CNG_…` |
| MC-17 | `PrepararAnillo.cs` | El paso 9 no mira la exportabilidad | Muerta | `Preparar_no_publica_nada_si_la_comprobacion_falla_…` |
| MC-18 | `PrepararAnillo.cs` | Sin el sobre de prueba | **Sobrevive** | — (SF-07) |
| MC-19 | `PrepararAnillo.cs` | Sin exigir elevación | Muerta | `Preparar_sin_elevacion_…` |
| MC-20 | `PrepararAnillo.cs` | Cualquier SID como cuenta | Muerta | `Preparar_sin_la_cuenta_del_servicio_…(caeEnUsers)` |
| MC-21 | `ProteccionDatosInstalacion.cs` | DPAPI junto al archivo | Muerta | `Archivo_anillo_con_DpapiDemo_no_arranca` (×2) |
| MC-22 | `GuardasAnillo.cs` | G-2 siempre pasa | Muerta | `Cuentas_iniciales_sin_ancla_sale_con_4` |
| MC-23 | `GPOS.Migracion/Program.cs` | Sin la llamada a G-1 | **Sobrevive** | — (SF-06) |
| MC-24 | `GPOS.Migracion/Program.cs` | Sin la llamada a G-2 | **Sobrevive** | — (SF-06) |
| MC-25 | `PrepararAnillo.cs` | Sin `Deshacer` | Muerta | `Preparar_no_publica_nada_…` |
| MC-26 | `ConfiguracionMigracion.cs` | Entorno después del archivo | Muerta | `Migracion_y_Api_leen_las_mismas_claves_del_anillo` |
| MC-27 | `GPOS.Api/Program.cs` | Sin la fuente del archivo | Muerta | `La_API_agrega_el_archivo_del_anillo_…` |
| MC-28 | `ArchivoAnillo.cs` | Cualquier `identidadServicio` | Muerta | `Archivo_anillo_invalido_…` |
| MC-29 | `PrepararAnillo.cs` | Principal vencido como «ya estaba» | **Sobrevive** | — (SF-07) |
| MC-30 | `PrepararAnillo.cs` | Recuperación de 2048 bits | Muerta | `Preparar_rechaza_un_cer_con_privada_o_RSA_menor_de_3072` |
| MC-31 | `PrepararAnillo.cs` | Sin el aviso de 180 días en `--preparar` | **Sobrevive** | — (SF-07) |

**Notas de procedimiento:**

- La primera pasada de MC-02 usó un filtro que no incluía la parte parcial de `MantenimientoAnilloTests` y la anoté como sobreviviente. La repetí como MC-02b con el filtro correcto y murió. Cuento solo MC-02b.
- MC-03 y MC-26 no se aplicaron al primer intento por los fines de línea CRLF. Las repetí con un ancla de una sola línea.

## 8. Remediaciones priorizadas

| Prioridad | ID | Acción | Esfuerzo [I, ±40 %] | Quién y cuándo |
|---|---|---|---|---|
| 1 | SF-01 | `--huella-recuperacion` obligatoria en `--migrar` y `--cambiar-recuperacion`; `--cambiar-recuperacion --recuperacion <cer>` escribe el `.cer` con `EscribirAtomico` | 0,1 dp | B, en F1, antes de unir (o el propietario acepta el residuo por escrito) |
| 2 | SF-03 | `sistema` solo asegura `InstalacionId` con el ancla en regla (o la difiere a `--cuentas-iniciales` con un mensaje claro) | 0,1 dp | B; aviso a A antes del 5-nov (orden de `FaseEsquema`) |
| 3 | SF-02 | G-1 para todo `sistema` (lo cierra también la opción a de SF-03) | 0,05 dp | B, en F1 |
| 4 | SF-06 | Prueba del cableado de G-1 y G-2 en `Program.cs` (o un punto único, R-A8) | 0,05 dp | B, en F1 |
| 5 | SF-04 | Falla cerrada con el 4704 si la fila del ancla no se puede leer sin el archivo | 0,02 dp | B, en F1 |
| 6 | SF-07 | Las cinco pruebas que faltan | 0,15 dp | B; puede ir después de unir |
| 7 | SF-08, SF-09 | Endurecer el esquema (rutas locales y huellas) y exigir la DACL protegida | 0,05 dp | B; puede ir después de unir |
| 8 | SF-05 | Nota de F1 y procedimiento para las VM y los DEMO con claves sueltas | 0 a 0,1 dp | B |

Lo que recomiendo dentro de F1 (prioridades 1 a 5) suma unos **0,3 dp**: unos USD 90 a 120 a la tasa del blueprint [I].

## 9. Recomendación

**Rechazado mientras SF-01 (Alta) siga abierta**, por el criterio de que un Alto sin resolver impide recomendar el avance. Es una recomendación técnica. La corrección es pequeña (≈0,1 dp) y no cambia la arquitectura.

Con SF-01 cerrada (o con el residuo de esos dos verbos aceptado por escrito por el propietario) y con SF-03 resuelta o asignada a A antes del 5-nov, mi recomendación pasa a **Aprobado con observaciones** (SF-02, SF-04 y SF-06 en F1; el resto, después).

Lo construido es sólido en lo esencial:

- SA-01, SA-02, SA-03 y SA-06 están cerrados en lo firmado;
- 24 de las 31 mutaciones mueren;
- la falla cerrada del archivo está bien probada.

Queda pendiente de la VM todo lo W (W-AN-01 a W-AN-05).

## Supuestos

- La hoja firmada (#221) y el aviso de B del 2026-10-23 fijan el alcance de SA-01 a SA-03 y SA-06. Mi SF-01 propone ampliarlo; no lo da por firmado.
- No hay instalaciones de producción con el anillo con certificado por claves sueltas (SF-05) [I].
- Lo marcado [I] (máscaras traducidas por el KSP, efecto real de `GENERIC_READ`, enlace certificado-llave de la máquina) se confirma en W-AN-01 y W-AN-02.
- La tasa de dp del blueprint se mantiene.

### Cierre
- Estado: Rechazado (recomendación técnica; pasa a Aprobado con observaciones con SF-01 cerrada o aceptada y SF-03 asignada).
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-f1-anillo-pr228.md`;
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-f1-anillo-pr228-pruebas.cs.txt`.
- Supuestos: los de la sección anterior.
- Decisiones candidatas a ADR:
  1. Huella dictada por un segundo canal en todo verbo que fije o cambie el ancla (`--anclar`, `--migrar`, `--cambiar-recuperacion`), con el criterio de ADR-63; precisa H-17 v2 y SA-01. Alternativa descartada: dejarlo solo en `--preparar` y `--anclar` (deja el mismo riesgo en la rotación).
  2. Cuándo se escribe `Licencia.InstalacionId` con el anillo con certificado (SF-03); precisa C-08 y el 3.3 del blueprint.
- Entregas a otros agentes:
  - B (desarrollador) → SF-01 a SF-09.
  - B (arquitecto) → precisión del 3.3 por SF-03 y del 3.2 por SF-08 (D-AN-13 y D-AN-14).
  - A → orden de `FaseEsquema` en PR-D2 (SF-03); SA-10 (resto), SA-14 y el uso de `CodigoSalida` y `VencePronto` en `comprobar-servidor`.
  - Arquitecto Maestro → pregunta al propietario sobre SF-01 (ampliar SA-01 o aceptar el residuo por escrito).
- Próximo paso recomendado: que B cierre SF-01 y SF-03 (≈0,2 dp) en `b/f1-anillo` y que yo vuelva a correr `SF01a`, `SF01b`, `SF02` y `SF03` invertidas, junto con MC-23 y MC-24, sobre el sha nuevo.

## Anexo: guion de mutaciones (resumen)

```bash
# mutar.sh <id> <archivo> <filtro>; DESDE y HACIA por variables de entorno (texto literal)
perl -0pi -e 's/\Q$ENV{DESDE}\E/$ENV{HACIA}/' "$archivo"
dotnet build tests/GPOS.Tests/GPOS.Tests.csproj -c Debug -v q
GPOST_TEST_SERVER=. dotnet test tests/GPOS.Tests/GPOS.Tests.csproj --no-build --filter "$filtro"
git checkout -- "$archivo"
```
