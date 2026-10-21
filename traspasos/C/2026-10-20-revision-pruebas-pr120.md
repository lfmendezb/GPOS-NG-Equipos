```
Para: B                         De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión de pruebas, solo lectura (tarea 1 de la cola del 2026-10-20)
PR: #120 (T2-0 de DB-7), rama b/t2-0-llave-firma, contra feature/modelo-ng @ b8f166db
Estado: Abierto
```

# Revisión de pruebas del PR #120 (T2-0 · `ILlaveFirmaTokens`, `ProveedorLlavesFirma`, `aprovisionar --llave-firma`)

## Dictamen: Suficiente con observaciones (con una observación Alta que B debe decidir antes de unir)

Las ocho pruebas que nombra el plan de D1 para T2-0 existen y cubren las seis condiciones de arranque de `ProveedorLlavesFirma` en su camino principal, la regla «nunca cae solo al Software KSP» y el orden «bitácora antes de crear la llave». El almacén en memoria permite probar sin TPM y la prueba con Software KSP real firma y valida un token ES256 de verdad.

Pero hay un hueco de diseño-y-prueba que no es el de la ACL de creación que B ya declaró: **`AlmacenLlavesFirmaWindows.Abrir` no comprueba dueño ni ACL de la llave que abre** (a diferencia de `LlaveSitio.Abrir`, T3-07), y por eso no hay prueba que lo cubra (P120-01, Alta). El resto son ramas de fallo sin prueba, fallos sin el evento 4740 y límites del motivo.

Alcance de la revisión: lectura de `git diff b8f166db origin/b/t2-0-llave-firma` y del código de la rama; no se compiló ni se ejecutó nada. Lo marcado *inferido* no se verificó.

## Lo que está bien (verificado en la rama)

- Las ocho pruebas del plan (`docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md`, T2-0) están: `El_kid_es_el_SHA256…`, `Una_firma_ES256_verifica…`, `Una_llave_exportable_no_se_acepta`, `Un_kid_de_la_lista_sin_llave_impide_arrancar`, `Fuera_de_Windows_falla_cerrada`, `Sin_TPM_y_sin_la_opcion_sin_tpm_no_cae_al_Software_KSP`, `La_opcion_desarrollo_solo_funciona_en_Debug` y `ProveedorLlavesFirma_solo_usa_ILlaveFirmaTokens`.
- `ComandoLlaveFirmaTests.cs:30-36`: el callback de la bitácora afirma `Assert.Empty(_almacen.Creadas)` en el momento de escribir, así que prueba el **orden** (aceptación antes de crear), no solo que ocurrió; y `:122-128` prueba que si la bitácora falla no se crea nada.
- `LlaveFirmaTokensTests.cs:55` y `:129`: la no exportabilidad se comprueba con el proveedor real (`ExportParameters(true)` falla) y con una llave exportable creada aparte; la prueba de CNG limpia sus llaves (`Dispose`, `:23-28`) con un prefijo único por instancia.
- `:77-101`: el token ES256 se firma con la llave del almacén, se valida con la parte pública y se comprueba el largo P1363 de 64 bytes.
- `AssertCritico` (`:267-272`) exige exactamente una entrada `Critical` con id 4740 y nombre `LlaveFirmaArranque` en cada fallo.

## Hallazgos

### P120-01 · Alta · `Abrir` no verifica dueño ni ACL de la llave; no hay prueba que lo exija
- **Evidencia:** `src/GPOS.Comun/Firma/LlaveFirmaTokens.Windows.cs:64-90` (solo comprueba proveedor, grupo ECDSA, curva y política de exportación). Compárese con `src/GPOS.Comun/Sobres/LlaveSitio.cs:84-125` y `:127-157` (`ComprobarSeguridad`: dueño Administradores o SYSTEM, sin ACE que dé acceso a otra cuenta, T3-07), cuyo patrón BP3 8.2 dice seguir («es el mismo patrón de `LlaveSitio`, con otro proveedor»). Pruebas del patrón original: `tests/GPOS.Reportes.Tests/SobreLecturaTests.cs:169-174`.
- **Por qué importa (nuevo respecto a lo que B ya sabe):** B declaró que no verificó la ACL de **creación** con `NT SERVICE\GPOS.Api`. Esto es la ACL al **abrir**: `ProveedorLlavesFirma` busca por nombre y por `kid`; una llave `GPOS.Api.Firma.*` ya existente con ACL ancha (creada a mano, restaurada o con otra herramienta) se acepta si es ECDSA P-256 y no exportable, y firma los tokens de toda la instalación. `LlaveSitio` cerró exactamente ese hueco con T3-07. Con el Software KSP (la vía `--sin-tpm`), la llave es un archivo en `ProgramData`, donde la ACL es la única defensa. *Inferido*: el almacén de claves del TPM puede no exponer `Security Descr` igual que el KSP de software; B debe decidir si la comprobación aplica a los dos proveedores o solo al de software.
- **Decisión que necesita B:** (a) llamar a `LlaveSitio.ComprobarSeguridad(descriptor, identidadAPI)` en `Abrir` cuando `Maquina` es true y fallar cerrado con `CryptographicException` (la API ya traduce eso a 4740); o (b) documentar en el PR por qué no se hace y pasar la comprobación a D6.
- **Pruebas propuestas:**
  - `LlaveFirmaTokensTests.El_descriptor_que_se_aplica_al_crear_pasa_la_comprobacion_de_seguridad_al_abrir`: sin administrador. `LlaveSitio.ComprobarSeguridad(LlaveSitio.Descriptor(CuentaServicioVirtual.Resolver(@"NT SERVICE\GPOS.Api")), CuentaServicioVirtual.Resolver(@"NT SERVICE\GPOS.Api"))` no lanza, y con un descriptor que añade `Users` o `Everyone` con `GenericRead` lanza `CryptographicException`. Fija que lo que `Crear` escribe y lo que `Abrir` exigiría son compatibles.
  - `LlaveFirmaTokensTests.Abrir_rechaza_una_llave_de_la_maquina_cuya_ACL_da_acceso_a_otra_cuenta` con `[Trait("Requiere","Admin")]` (el equipo de B ya sabe que la creación en el almacén de la máquina pide consola elevada): crea con el descriptor de `LlaveSitio.Dacl` más un ACE para `Users`, y afirma que `ProveedorLlavesFirma.Abrir` falla con 4740 y el mensaje nombra el SID sobrante.

### P120-02 · Media · `Crear` no sobrescribe una llave existente: solo por omisión del indicador, sin prueba
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:92-120` (no se pasa `CngKeyCreationOptions.OverwriteExistingKey`); `ComandoLlaveFirma.cs:109` (el nombre se elige con `Existe`, pero entre `NombreNuevo` y `Crear` hay una ventana: dos consolas a la vez eligen el mismo nombre); `LlaveFirmaTokensTests.cs:61` solo prueba que `NombreNuevo` da `.2`.
- **Detalle:** sobrescribir la llave activa invalida todos los tokens vigentes sin aviso. Hoy lo evita el valor por omisión de CNG; una refactorización lo rompería sin que ninguna prueba falle.
- **Prueba propuesta:** `LlaveFirmaTokensTests.Crear_con_un_nombre_existente_falla_y_no_cambia_el_kid` (Software KSP del usuario): crea, anota el `kid`, intenta crear otra vez con el mismo nombre → `CryptographicException`, y al reabrir el `kid` es el original. Variante sin escritura: `…Existe_ve_la_llave_recien_creada_en_cualquiera_de_los_dos_proveedores`.

### P120-03 · Media · `Abrir` rechaza lo que no es ECDSA P-256, y no hay prueba
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:76-82` (`AlgorithmGroup`, `EsP256`), `:131-135`.
- **Detalle:** son dos controles de seguridad (un RSA o una ECDSA P-384 con el prefijo y el kid listado no deben firmar tokens ES256) sin ninguna prueba. Se pueden probar sin administrador ni TPM, en el almacén del usuario (Software KSP), con el mismo patrón que `Una_llave_exportable_no_se_acepta` (`:118-124`).
- **Pruebas propuestas:** `LlaveFirmaTokensTests.Abrir_rechaza_una_llave_RSA` y `…Abrir_rechaza_una_llave_ECDSA_P384`: `CngKey.Create(CngAlgorithm.Rsa / ECDsaP384, _prefijo + "20261102", …Software KSP, no exportable)`; afirman `CryptographicException` con «no es ECDSA P-256», y que `ProveedorLlavesFirma.Abrir` con ese nombre como activa termina en 4740.

### P120-04 · Media · La condición «exportable» solo se prueba con la llave activa
- **Evidencia:** `ProveedorLlavesFirma.cs:143-144` evalúa todas las `conservadas`; `LlaveFirmaTokensTests.cs:104-136` usa solo la activa.
- **Detalle:** en una rotación (activa + anterior en `Jwt:KidsValidos`) una anterior exportable debe impedir arrancar igual: valida tokens con una llave que alguien pudo copiar.
- **Prueba propuesta:** `LlaveFirmaTokensTests.Una_llave_anterior_exportable_de_la_lista_tambien_impide_arrancar`: activa no exportable + anterior `exportable: true`, ambas en la lista → `InvalidOperationException` con el nombre de la anterior y un 4740. Y su contraria: anterior exportable **fuera** de la lista no estorba (se descarta antes de la comprobación).

### P120-05 · Media · Las llaves retiradas que no se abren no tienen prueba; la rama del `warning` es invisible
- **Evidencia:** `ProveedorLlavesFirma.cs:123-130` (la llave no activa que lanza `CryptographicException` se ignora con `LogWarning` 4740 y sigue); `LlaveFirmaTokensTests.cs:194-196` solo prueba la activa (`NoSeAbren`).
- **Pruebas propuestas:**
  - `Una_llave_retirada_que_no_se_abre_se_ignora_con_un_aviso_si_su_kid_no_esta_en_la_lista`: activa válida + otra en `NoSeAbren`; arranca; una entrada `Warning` 4740 con el nombre de la ignorada.
  - `Una_llave_anterior_que_no_se_abre_pero_esta_en_la_lista_impide_arrancar`: la misma, con su kid en la lista (el comentario de `:127` dice que lo detecta la condición 5); afirma el mensaje «kid(s) sin llave» y el 4740 crítico. Además del `Warning`, así `AssertCritico` (que exige una sola entrada crítica) sigue siendo válido.

### P120-06 · Media · Fallos sin el evento 4740: kid duplicado y excepciones que no son `CryptographicException`
- **Evidencia:** `ProveedorLlavesFirma.cs:71` (`llaves.ToDictionary(l => l.Kid)` lanza `ArgumentException` si dos llaves conservadas tienen el mismo `kid`, por ejemplo la misma llave copiada con otro nombre); `:119-130` y `:168-184` solo capturan `CryptographicException` (un `UnauthorizedAccessException`, `NotSupportedException` o `PlatformNotSupportedException` al abrir o firmar escapa sin pasar por `Fallar`).
- **Detalle:** la API sigue sin arrancar (falla cerrada: la excepción sube), pero P-D1-01 promete el 4740 en todo fallo de arranque por la llave; la alerta por EventId quedaría muda en estos casos. *Inferido* por lectura; no se ejecutó.
- **Pruebas propuestas:**
  - `LlaveFirmaTokensTests.Dos_llaves_con_el_mismo_kid_impiden_arrancar_con_4740` (dos nombres que apuntan al mismo `ECDsa`; `AlmacenLlavesMemoria.Agregar(nombre, llave: mismaLlave)`).
  - `…Una_excepcion_inesperada_al_abrir_o_al_firmar_registra_4740_y_no_arranca` (un almacén cuyo `Abrir` lanza `UnauthorizedAccessException` y un `ECDsa` cuyo `SignHash` lanza `NotSupportedException`): afirma `InvalidOperationException` o la excepción original según decida B, pero siempre una entrada `Critical` 4740.

### P120-07 · Media · Los dobles de prueba ocultan la liberación de las llaves
- **Evidencia:** `tests/GPOS.Tests/Acceso/LlavesFirmaPruebas.cs:15` (`Liberada` nunca se lee en ninguna prueba), `:17` (`Dispose` solo marca la bandera) y `:49` (`Abrir` entrega un `LlaveMemoria` nuevo cada vez, sin guardar la referencia); código de producción: `ProveedorLlavesFirma.cs:133` (descarta las que no están en la lista), `:160-164` (libera las conservadas si algo falla) y `:192-195`.
- **Detalle:** las ramas de `Dispose` del proveedor son la parte que más importa con CNG (manejadores del TPM, que son un recurso escaso) y ninguna prueba las verifica. Además `LlaveMemoria.Dispose` no libera el `ECDsa` compartido, así que un "uso después de liberar" tampoco se detectaría.
- **Pruebas propuestas** (el almacén en memoria debe guardar la lista de `LlaveMemoria` abiertas):
  - `El_proveedor_libera_las_llaves_que_descarta_por_no_estar_en_la_lista`.
  - `Si_el_arranque_falla_se_liberan_todas_las_llaves_abiertas`.
  - `Dispose_del_proveedor_libera_la_activa_y_las_anteriores`.

### P120-08 · Media · Los límites del motivo no están parametrizados y los bordes no se ejercen
- **Evidencia:** `ComandoLlaveFirmaTests.cs:108-120`; `ComandoLlaveFirma.cs:89-91`.
- **Detalle:** (1) las líneas `:115-118` están dentro del cuerpo del `Theory` pero no dependen de los datos, así que se ejecutan tres veces lo mismo; (2) `"corto"` tiene 5 caracteres, no 9: el borde bajo no se prueba, y `"         "` son 9 espacios, así que no prueba que el recorte se haga antes de contar (10 o más espacios deben rechazarse); (3) los bordes aceptados (10 y 200) no se prueban; (4) un motivo con saltos de línea o caracteres de control va a la bitácora sin comprobación.
- **Pruebas propuestas:** `Sin_tpm_acepta_motivos_de_10_y_200_caracteres_y_rechaza_9_y_201` (`[Theory]` con `10, 200` aceptados y `9, 201` rechazados; el aceptado afirma que el evento lleva exactamente ese motivo); `Un_motivo_de_solo_espacios_se_rechaza_aunque_tenga_12_caracteres`; `Un_motivo_con_espacios_alrededor_se_recorta_antes_de_contar` (200 caracteres + 5 espacios → acepta; 9 + 10 espacios → rechaza). Si B decide limpiar controles: `Un_motivo_con_salto_de_linea_se_rechaza`.

### P120-09 · Media · Si `Crear` falla después de escribir la aceptación, queda un evento «sin llave»; y el mensaje siempre culpa a la consola elevada
- **Evidencia:** `ComandoLlaveFirma.cs:110-116` (el evento se escribe antes de crear, por diseño P-D1-04) y `:119-126` (cualquier `CryptographicException` se reescribe como «ejecute el verbo desde una consola de administrador»); `ComandoLlaveFirma.cs:129` (rama «quedó exportable») sin prueba; el doble `AlmacenLlavesMemoria.Crear` (`LlavesFirmaPruebas.cs:52-57`) nunca falla ni devuelve exportable.
- **Detalle:** el mensaje es erróneo cuando la causa es otra (nombre existente, TPM en bloqueo, `NTE_EXISTS`); y la bitácora conserva «se aceptó crear la llave X» aunque no se creó. Que el evento vaya antes es lo firmado; lo que falta es fijar qué ocurre después.
- **Pruebas propuestas:**
  - `Si_Crear_falla_despues_de_registrar_la_aceptacion_el_error_conserva_la_causa_y_el_evento_queda` (el almacén lanza `CryptographicException("NTE_EXISTS")`; afirma `ReglaNegocioException` con el texto original y un solo evento; B decide si el mensaje de «consola de administrador» se condiciona a un `UnauthorizedAccessException` o al código de acceso denegado).
  - `Una_llave_que_queda_exportable_tras_crearse_se_rechaza` (el almacén devuelve `EsExportable = true`; afirma el mensaje de `:129` y, si B lo decide, que la llave se elimina).

### P120-10 · Media · El cableado real de la bitácora y de la consola no tiene prueba sin base de datos
- **Evidencia:** `ComandoLlaveFirma.cs:140-146` (`EjecutarConsolaAsync`) y `:148-156` (`RegistrarAsync`, con el mensaje de «configure ConnectionStrings:Sistema»); las pruebas inyectan un `registrarAceptacion` falso (`ComandoLlaveFirmaTests.cs:26-36`). `Program.cs:84-97` (la mezcla y el verbo) tampoco se prueba de punta a punta.
- **Detalle:** B ya dijo que `BitacoraSeguridadTests.PF46` no se corrió. Esto es distinto: ningún test escribe el evento `FIRMA_SIN_TPM_ACEPTADA` por `BitacoraSeguridadService` ni comprueba que la consulta 5.11 lo devuelve con `Canal = "CONSOLA"`, severidad `A` y motivo; y la ruta sin cadena de conexión no se prueba. Una excepción en `RegistrarAsync` (por ejemplo `SqlException`) sube hasta `Program.cs` y debe dejar la llave sin crear (`Si_la_bitacora_no_se_escribe…` lo prueba solo con un delegado falso).
- **Pruebas propuestas:**
  - `BitacoraSeguridadTests.FirmaSinTpmAceptada_se_escribe_y_la_consulta_la_devuelve` (patrón de `PF46_la_consulta_devuelve…`, con `BaseDatosFixture`; filtra por `Evento = FIRMA_SIN_TPM_ACEPTADA` y afirma canal, severidad, actor y motivo; añade un `Actor` de 200 caracteres para fijar el recorte a 128, `BitacoraSeguridad.cs:58-63` y `:116`).
  - `ComandoLlaveFirmaTests.Sin_cadena_de_conexion_a_Sistema_con_sin_tpm_no_crea_la_llave_y_explica_que_configurar`: requiere que B extraiga un `internal` que acepte el almacén (hoy `EjecutarConsolaAsync` llama a `AlmacenesLlavesFirma.Plataforma` directo, `:143`), con `InternalsVisibleTo` si hace falta; sin base ni TPM.

### P120-11 · Media · El almacén de la máquina se lee en producción (`verificar`, `Nombres()`), y nada lo ejercita
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:50` (`OpcionesApertura`), `:154-186` (`NCryptEnumKeys` con `NcryptMachineKeyFlag`); `Program.cs:144` llama a `AlmacenesLlavesFirma.Plataforma(maquina: true)` en cada `verificar`; todas las pruebas de Windows usan `maquina: false` (`LlaveFirmaTokensTests.cs:26,43,69,125,252`; `git grep "maquina: true"` solo da `Plataforma(...)` de la prueba de «fuera de Windows»).
- **Detalle:** con `maquina: true` cambia la bandera del enumerador, el flag de apertura y la ruta de `Crear` (que exige la identidad). La lectura (`Nombres`, `Existe`) no necesita administrador, así que sí es probable sin consola elevada. Es un camino que ejecutará el instalador y `verificar` el primer día.
- **Pruebas propuestas:** `LlaveFirmaTokensTests.El_almacen_de_la_maquina_se_enumera_sin_administrador_y_sin_llaves_de_prueba` (prefijo aleatorio; `new AlmacenLlavesFirmaWindows(maquina: true, _prefijo).Nombres()` devuelve vacío sin lanzar, `Existe("x")` es false, `HayTpm` no lanza); y `Crear_en_la_maquina_sin_identidad_lanza_ArgumentNullException` (ya está implementado en `:105-106` y no se prueba; también `Crear` con `identidadServicio = "  "`). Nota: `ComandoLlaveFirma.cs:117` pasa `o.Cuenta ?? default`; con `--cuenta ""` llega una cadena vacía y el `ArgumentNullException` sale sin mensaje de usuario: prueba `Cuenta_vacia_se_rechaza_con_un_mensaje_claro`.

### P120-12 · Baja · Casos de borde de rotación, nombres y configuración sin prueba
- **Evidencia:** `ProveedorLlavesFirma.cs:94` (`> DiasRotacionSinTpm`), `LlavesFirma.Fecha/Antiguedad/NombreNuevo` (`ILlaveFirmaTokens.cs:87-107`), `OpcionesLlavesFirma.Desde` (`ProveedorLlavesFirma.cs:17-24`); en las pruebas solo hay 13 y 62 días (`LlaveFirmaTokensTests.cs:231,241`) y `Fecha(nombre + ".2")`.
- **Pruebas propuestas:**
  - `Rotacion_vencida_en_el_borde_de_30_y_31_dias` (30 → false; 31 → true; nombre sin fecha → true; fecha futura → antigüedad negativa, `RotacionVencida` false: fijar si es lo deseado).
  - `Fecha_rechaza_nombres_mal_formados`: `prefijo2026110` (7 dígitos), `prefijo20261102x`, `prefijo20261302`, `prefijo20261102.` y `prefijo20261102.abc` (hoy este último **sí** devuelve la fecha).
  - `NombreNuevo_falla_a_las_99_llaves_del_mismo_dia` (el `n < 100` de `:91`).
  - `OpcionesLlavesFirma.Desde` con la lista como texto separado por comas y por punto y coma, como arreglo (`Jwt:KidsValidos:0`), con espacios y con minúsculas (el `kid` en minúsculas debe fallar por mal formado, `ProveedorLlavesFirma.cs:108`), y con la llave activa con espacios alrededor. Hoy `Desde` no tiene ningún test.
  - `La_comparacion_del_nombre_de_la_llave_activa_ignora_mayusculas`, solo si B decide que CNG las trata igual (*inferido*): hoy se compara `Ordinal` (`ProveedorLlavesFirma.cs:125,137`) y, si el nombre de la configuración difiere solo en mayúsculas, el mensaje dice que el `kid` de la activa no está en la lista, que es engañoso.

### P120-13 · Baja · La firma de prueba solo se prueba cuando «no se puede firmar»
- **Evidencia:** `ProveedorLlavesFirma.cs:167-184` (condición 6: firma y verifica); `LlavesFirmaPruebas.cs:66-78` (`ECDsaSinUso` solo lanza en `SignHash`).
- **Prueba propuesta:** `La_firma_de_prueba_que_no_verifica_impide_arrancar`: un `ECDsa` envoltorio que firma con otra llave y exporta la pública de la primera; afirma el mensaje «la firma de prueba no verifica» y 4740.

### P120-14 · Baja · La prueba con TPM «pasa» sin ejecutarse
- **Evidencia:** `LlaveFirmaTokensTests.cs:246-265` (`if (!almacen.HayTpm) return;`), y `:251` para no-Windows; el rasgo `Requiere=Tpm` es solo una etiqueta.
- **Detalle:** el plan decía «se omiten sin él». Un equipo sin TPM (el servidor de B, CI) la reporta como aprobada. B sí la corrió en su equipo con TPM, así que no es un defecto del PR, sino de lo que el informe de una máquina sin TPM dice.
- **Propuesta:** el patrón del proyecto ya existe (`Rg14Lote2Tests.cs:24` asigna `Skip` desde un atributo propio con xUnit 2.9.3): `HechoConTpmAttribute : FactAttribute` que pone `Skip = "Sin TPM utilizable (R-D1-09)"` cuando `new AlmacenLlavesFirmaWindows(false).HayTpm` es false, y lo mismo para las ramas «solo Windows». Así el recuento de omitidas muestra lo que no corrió.

### P120-15 · Baja · `CosturasDb7Tests` tiene huecos de patrón y la lista de archivos es manual
- **Evidencia:** `CosturasDb7Tests.cs:14-19` (`Neutros` a mano), `:22-28` (patrón `\bCng\w*\b`), `:44-46` (el recorte de comentarios corta en cualquier `//`, también dentro de una cadena como `"https://…"`), `:58`.
- **Detalle:** (1) `\bCng\w*\b` no coincide con `ECDsaCng` o `RSACng` (no hay frontera de palabra entre `a` y `C`): solo la prueba de `ProveedorLlavesFirma` los busca aparte (`DoesNotMatch`), no la de `Neutros`, así que `ILlaveFirmaTokens.cs` o `ComandoLlaveFirma.cs` podrían usar `ECDsaCng` sin que falle; (2) un archivo nuevo neutro en `src/GPOS.Comun/Firma/` (por ejemplo la implementación de Linux del siguiente PR) no entra en la guarda hasta que alguien lo agregue a `Neutros`; (3) una línea con `"//"` en una cadena oculta lo que sigue.
- **Pruebas propuestas:** `Los_archivos_neutros_de_Firma_se_descubren_por_carpeta` (todo `*.cs` de `src/GPOS.Comun/Firma/` que no termine en `.Windows.cs` entra en la guarda); ampliar el patrón a `\w*Cng\b|\bCng\w*\b`; y un caso fijo de que el recorte de comentarios no borra el código tras una cadena con `//` (`CosturasDb7Tests.Codigo_no_pierde_lo_que_sigue_a_una_cadena_con_doble_barra`).

### P120-16 · Baja · Concurrencia: la llave activa se comparte y no se prueba firmar en paralelo
- **Evidencia:** `ProveedorLlavesFirma.cs:76` (`Activa` única, de larga vida); BP3 8.2 («se firma al iniciar sesión… nunca en cada petición»); ninguna prueba firma desde varios hilos.
- **Propuesta:** `LlaveFirmaTokensTests.Firmar_en_paralelo_con_la_llave_activa_verifica_todas_las_firmas` (Software KSP del usuario; 8 hilos × 25 firmas; cada una verifica con la pública). Es la única prueba que puede detectar un manejador de CNG no apto para uso concurrente; con el TPM real (serializado) se mide en D6.

## Lo que no encontré (para tranquilidad de B)

- Las seis condiciones de BP3 8.2 se mapean 1:1 a líneas de `Abrir` (`ProveedorLlavesFirma.cs:104-149`) y las pruebas de `:171-214` ejercitan cada una; no hay una que apruebe por la razón equivocada en el sentido de un `Assert` débil.
- `AssertCritico` exige una sola entrada crítica con el nombre exacto del evento; es lo bastante estricto.
- P-D1-04 (límites derivados del proveedor, sin marca en la configuración): `:217-244` lo prueba con ambos proveedores y comprueba que no hay aviso `rótela` con 13 días.
- No vi cambios en `EventosSeguridad.Todos` que rompan `SegundoFactorSuperPantallasTests.cs:231` (`Take(25)`): `FIRMA_SIN_TPM_ACEPTADA` queda en la posición 44, después de los 25 con nombre en español. Si T1-1 reordena el catálogo, esa prueba se romperá; conviene anotarlo en el conflicto previsto con T1-1.
- `PF46_el_catalogo_incluye…` (`BitacoraSeguridadTests.cs:52-68`) debería seguir pasando: el nombre mide 22 caracteres (límite 40) y está en `Todos`. *Inferido por lectura*; no se corrió (B ya lo dijo).

## Riesgos que las pruebas no cubren
- ACL de uso con `NT SERVICE\GPOS.Api` y la política de exportación del TPM (B lo declaró); P120-01 propone cómo cubrir la parte que no necesita administrador.
- Comportamiento real de `Security Descr` en el Platform Crypto Provider.
- Rotación de emergencia (solo el `kid` nuevo + reinicio, objetivo menor de 15 minutos): no hay prueba de la secuencia completa; es de D6.

---

## Texto de comentario para el PR #120

```
Revisión de pruebas (QA del equipo C, solo lectura; no se compiló ni se corrió nada). Dictamen: Suficiente con observaciones, con una Alta a decidir antes de unir. Informe completo: traspasos/C/2026-10-20-revision-pruebas-pr120.md.

Lo bueno: están las ocho pruebas del plan; el orden «bitácora antes de crear» se prueba de verdad (el callback afirma que Creadas está vacío); la firma ES256 se valida con la llave pública; AssertCritico es estricto.

- P120-01 (Alta): AlmacenLlavesFirmaWindows.Abrir (LlaveFirmaTokens.Windows.cs:64-90) no comprueba dueño ni ACL de la llave, a diferencia de LlaveSitio.Abrir (T3-07). Es distinto de la ACL de creación que ya declaran. Hay una prueba sin administrador (el descriptor de Crear pasa LlaveSitio.ComprobarSeguridad; uno con Users no) y otra con Requiere=Admin. Hace falta decidir si Abrir verifica o si se documenta y pasa a D6.
- P120-02/03/04/05 (Media): Crear no sobrescribe solo por omisión (sin prueba); Abrir rechaza RSA/P-384 sin prueba (se puede con el Software KSP del usuario); «exportable» solo con la activa; la llave anterior que no abre (aviso 4740) sin prueba.
- P120-06 (Media): dos llaves con el mismo kid lanzan ArgumentException (ToDictionary) y excepciones distintas de CryptographicException escapan sin 4740.
- P120-07 (Media): LlaveMemoria.Liberada nunca se lee; el Dispose del proveedor (descartes, fallo, final) no se verifica.
- P120-08 (Media): Theory del motivo con asserts fuera de los datos; «corto» son 5 caracteres, no 9; faltan 10 y 200 aceptados y el recorte antes de contar (12 espacios).
- P120-09/10/11 (Media): si Crear falla tras la aceptación queda el evento y el mensaje siempre culpa a la consola elevada; EjecutarConsolaAsync/RegistrarAsync no tienen prueba (falta un seam para el almacén); el almacén de la máquina (maquina: true) nunca se ejercita, ni siquiera la lectura que hace verificar.
- Bajas: bordes de 30/31 días, Fecha() con nombres mal formados y OpcionesLlavesFirma.Desde sin pruebas (P120-12); firma de prueba que no verifica (P120-13); la prueba con TPM pasa sin ejecutarse, mejor con Skip por atributo (P120-14); CosturasDb7Tests no ve ECDsaCng, la lista Neutros es manual y el recorte de // rompe con cadenas (P120-15); firma en paralelo (P120-16).
```

### Cierre
- Estado: Aprobado con observaciones (para las pruebas del PR #120; recomendación técnica, no decisión). Hay una observación Alta (P120-01) que B debe resolver o documentar antes de unir.
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr120.md`
- Supuestos: números de línea tomados de `origin/b/t2-0-llave-firma` (fetch del 2026-10-20); nada compilado ni ejecutado; P120-01 *infiere* que el TPM puede no exponer `Security Descr` igual que el Software KSP.
- Decisiones candidatas a ADR: Ninguna (P120-01 es una decisión de B/auditor-seguridad sobre T2-0, dentro de BP3 8.2).
- Entregas a otros agentes: auditor-seguridad → opinar sobre P120-01 (ACL al abrir, TPM frente a Software KSP) y P120-06 (4740 en todo fallo); desarrollador (B) → P120-02 a P120-16 y un seam para el almacén en `EjecutarConsolaAsync`.
- Próximo paso recomendado: B decide P120-01 (verificar en `Abrir` o documentarlo) y publica el comentario en el PR #120.
