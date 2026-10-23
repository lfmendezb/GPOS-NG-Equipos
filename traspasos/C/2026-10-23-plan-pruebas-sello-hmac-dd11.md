Para: B (copia a A, constructor del sello antes de T4-11)        De: C        Fecha: 2026-10-23
Tipo: Entrega (punto 9 de B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7: plan de pruebas del sello HMAC de DD-11')
Prioridad: Media (antes de construir; A lo construye antes de T4-11)
Repositorio y rama: GPOS-NG, lectura de `origin/master` y `origin/feature/modelo-ng`
Estado: Abierto (plan, sin código)

# Plan de pruebas del sello HMAC de DD-11' en la API de reportes

**Método:** solo lectura. Fuente: `traspasos/A/diseno-sello-hmac-dd11-api-reportes-2026-10-22.md` (en adelante DS; secciones 1 a 9), ADR-109 cláusulas 5 y 6 (`origin/master:docs/adr/ADR-109.md`) y la sección 3.2 de `docs/datos/2026-10-22-t4-10-vistas-imp.md` que DS cita (no la releí; adopto lo que DS dice de ella). **No compilé ni ejecuté nada; ninguna mutación está corrida** (el código no existe). Marcas: `[V]` visto en un documento o código; `[I]` inferido. El ADR-74 es otro sello (comprobantes fiscales) y no se mezcla con éste.

**Qué se prueba:** (1) el cálculo del mensaje canónico y del HMAC; (2) la ruta `POST /api/impresion/formatos/sello` en `GPOS.Reportes.Api`; (3) la verificación al renderizar (`ServicioRender.HtmlAsync`); (4) el guardado en dos pasos de `FormatosService`; (5) la llave (anillo propio, `Kid`, rotación). Dueño del código: A. Proyectos: `GPOS.Reportes.Tests` (1, 2, 3, 5) y `GPOS.Tests` (4), como fija DS sección 8.

## 0. Hallazgos al leer el diseño (afectan las pruebas)

| # | Hallazgo | Evidencia | Efecto |
|---|---|---|---|
| H-1 | **El mensaje no lleva empresa ni sitio.** `Id` es el identificador de la fila en la base de cada empresa, así que dos empresas del mismo sitio pueden tener un `Id = 7` con la misma plantilla. Un sello válido de la empresa X se copia a la fila equivalente de la empresa Y y verifica (misma llave del sitio). Quien puede escribir en `conf` de Y ya puede escribir `Plantilla` y `Huella`; el cruce solo exige que la plantilla ya haya sido autorizada en X | DS 2 (mensaje) y 1 (una llave por sitio) [V] | Los casos de cruce entre empresas (SH-60 a SH-63) **no pueden afirmar rechazo** con el diseño actual. Se escriben como caracterización y como prueba roja si B decide meter `EmpresaId` en el mensaje. Duda D-1 |
| H-2 | **DS 2 lista el mensaje sin `Papel`, pero dice que `Papel` entra.** El texto de la fórmula es `... Id, TipoDocumento, Modo, Plantilla`; la nota «`Papel` entra al mensaje» no dice en qué posición ni con qué codificación | DS 2, líneas 22 y 27 [V] | Sin posición no se puede escribir el vector de prueba. Duda D-2; SH-05 queda condicionado |
| H-3 | **`Kid` no está dentro del HMAC**, solo en el prefijo de `Huella` (1 byte + 32). Cambiar el byte `Kid` por otro **conocido** durante la ventana de rotación hace que se verifique con otra llave: debe dar `SelloNoCoincide`, no éxito | DS 1 y 5 [V] | SH-40 a SH-42 |
| H-4 | **«Vencido» no existe como atributo del sello:** el sello no lleva fecha. Lo que vence es (a) `auth_time` de 5 minutos para sellar, (b) la ventana de la llave vieja tras la rotación. No hay reloj en la verificación | DS 3.4, 1 [V] | «Vencido» se prueba en esos dos sitios (SH-24, SH-25, SH-45); se pide a A que **no** agregue caducidad por tiempo a la verificación sin decisión |
| H-5 | **«Repetido»:** el sello repetido (mismo triple `Id, Plantilla, Huella`) verifica siempre; la repetición es R-SELLO-1 (Baja, aceptada). La API de reportes no guarda estado | DS 6 [V] | SH-70 a SH-73 caracterizan lo aceptado y prueban la mitigación (revisión solo para auditoría) |
| H-6 | La ruta de sellado hace valer `otp` **por sí misma**, aun con `ExigeOtpSuper` apagado en Debug, salvo configuración explícita que registra un evento al arrancar | DS 3.3 [V] | SH-21 y SH-22 son casos de la mutación obligatoria de DS 8 |
| H-7 | `Huella` es `binary(33)` (DS 1), no `binary(32)`. La hoja del #178 debe ajustarse antes de construir | DS 1 y 9 [V] | SH-90 verifica el DDL; si aún dice 32, el caso falla |
| H-8 | DS 8 enumera 15 pruebas de `GPOS.Reportes.Tests` y 3 de `GPOS.Tests`. Este plan las contiene todas (columna Origen) y agrega las que faltan (ver sección 6) | DS 8 [V] | |

## 1. Convenciones

- **Nivel:** U = unidad sin base ni proceso; S = servicio con doble del repositorio de `imp.Formato`; H = HTTP contra `GPOS.Reportes.Api` en proceso (como el fixture de la API de reportes en `GPOS.Reportes.Tests`) con introspección doble; P = prueba en la principal (`GPOS.Tests`, `ApiMvpFactory`); TX = textual sobre fuentes; BLD = compilación (criterio de PR).
- **Mutación:** cambio mínimo al código de sellado que **debe** poner la prueba en rojo. `*` = imprescindible: A anota el resultado en el PR. Hoy ninguna está corrida.
- **Plantilla trampa:** donde diga «trampa», la plantilla Razor, de compilarse, crea un archivo (`File.WriteAllText` a una ruta de la carpeta de la prueba). La prueba afirma que el archivo **no existe** (mismo recurso de DS 8, `Razor_sin_marca_o_con_sello_alterado_no_se_compila`). Es la única forma de probar «no se compila» sin depender de un contador del compilador.
- **Llave de prueba:** llave de 32 bytes fija por prueba, inyectada por la costura de testabilidad TB-1. Nunca la del anillo real.
- Sin `Thread.Sleep`; el reloj se inyecta (TB-2).

## 2. Cálculo del mensaje y del HMAC (U)

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-01* | `Sello_igual_para_el_mismo_mensaje`: dos cálculos con la misma llave y los mismos campos dan los mismos 33 bytes | U | iguales | Meter un `Guid` o un contador en el mensaje: rojo | DS 8 |
| SH-02* | **Vector fijo:** con llave de bytes `00..1F`, `Kid = 1`, `Id = 1`, `FACTURA`, `RAZOR`, plantilla `"x"`, la `Huella` es un valor literal calculado **independientemente** (HMAC con otra herramienta, p. ej. PowerShell, no con el código de A) y se guarda como constante. Incluye el HKDF intermedio (`info = "GPOS.Imp.Sello.v1"`) | U | igual al literal | Cambiar `info` a `v2` o saltar HKDF: rojo | DS 1, 2 |
| SH-03* | `Cambiar_Id_TipoDocumento_Modo_o_Plantilla_cambia_el_sello`: teoría de 4 cambios de **un byte** (Id+1, `FACTURA`→`FACTURB`, `RAZOR`→`RAZOS`, un carácter de la plantilla); cada uno cambia el sello. Más `Papel` (SH-05) | U | los 4 distintos del original | Dejar `Modo` fuera del mensaje: el cambio de `Modo` no cambia el sello (rojo) | DS 8 |
| SH-04* | **Ambigüedad de límites:** pares de campos que concatenados son iguales pero con otros límites (`TipoDocumento="AB"`,`Modo="C"` frente a `"A"`,`"BC"`; y `Plantilla` que empieza con los bytes de un `uint16`) dan sellos distintos gracias a los prefijos de largo | U | distintos | Quitar el prefijo `uint16` de `TipoDocumento`: los pares colisionan (rojo) | DS 2 |
| SH-05 | `Papel` entra al mensaje: cambiar `Papel` cambia el sello; `Orientacion` **no** lo cambia (queda fuera: no se compila) | U | `Papel` cambia; `Orientacion` no | Excluir `Papel`: rojo. **Condicionado a D-2** (posición y codificación) | DS 2 |
| SH-06 | Orden de bytes: `Id = 1` y `Id = 16777216` (`0x01000000`) dan sellos distintos y el mensaje serializado de `Id=1` contiene `00 00 00 01` (BE). Idem el largo `uint32` de la plantilla | U | big-endian | Little-endian: el vector SH-02 cambia (rojo) | DS 2 |
| SH-07* | `Plantilla_con_UTF8_invalido_se_rechaza`: sustituto sin par (`"\uD800"`) al sellar **y** al verificar da el rechazo de forma (422 `SELLO_PLANTILLA_INVALIDA` al sellar; `SelloNoCoincide` o motivo propio al verificar), sin calcular HMAC ni compilar (trampa) | U, H | rechazo | `throwOnInvalidBytes: false`: el `\uD800` se reemplaza por `U+FFFD` y se sella (rojo) | DS 8 |
| SH-08* | `Plantilla_de_mas_de_256KB_se_rechaza`: 262 144 bytes UTF-8 pasan; 262 145 dan 413 `SELLO_PLANTILLA_GRANDE` al sellar y rechazo al verificar. El tope es en **bytes UTF-8**, no en caracteres (probar con 131 073 caracteres de 2 bytes) | U, H | borde exacto | Medir en `string.Length`: el caso multibyte pasa (rojo) | DS 8, 2 |
| SH-09 | `TipoDocumento` y `Modo` solo ASCII: `"FACTURÁ"` rechaza al sellar y al verificar. `Modo != "RAZOR"` da 422 al sellar | U, H | rechazo | Codificar con `Encoding.UTF8` sin validar: sella (rojo) | DS 2, 3 |
| SH-10 | Sin normalización: `"é"` precompuesto (`U+00E9`) y descompuesto (`e + U+0301`), y `\n` frente a `\r\n`, dan sellos **distintos** | U | distintos | Normalizar a FormC o cambiar saltos de línea: igualan (rojo) | DS 2 |
| SH-11 | Plantilla vacía: se define (rechaza con 422 o se sella un mensaje con largo 0). **Duda D-3**; hasta entonces la prueba es de caracterización | U | por decidir | n/a | |
| SH-12 | La huella devuelta es de 33 bytes con `Kid` en el primer byte; el base64url de la respuesta no lleva `=` ni `+` ni `/` | U, H | forma correcta | Devolver base64 estándar: rojo | DS 1, 3 |

## 3. La ruta que sella (H)

Introspección doble que devuelve `nivel`, `amr`, `auth_time`, `prg` configurables. Cada caso comprueba además que **no se calculó HMAC** (contador del servicio de sellado = 0) cuando el resultado es rechazo.

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-20* | Camino feliz: SUPER, `amr=otp`, `auth_time` de hace 1 minuto, plantilla válida → 200 con `huella` de 33 bytes y `kid` | H | 200 | n/a | DS 3 |
| SH-21* | `Sin_otp_no_sella`: SUPER sin `otp` en `amr` → 403 `SELLO_REQUIERE_OTP` | H | 403 | **Mutación obligatoria de DS 8:** quitar la comprobación de `otp`: rojo | DS 8 |
| SH-22* | Con `ExigeOtpSuper` apagado (configuración de Debug) la ruta sigue pidiendo `otp`; solo una configuración de desarrollo explícita lo relaja y **escribe el evento al arrancar** | H | 403 sin `otp`; con la bandera explícita, 200 y evento de arranque | Hacer que la ruta lea `ExigeOtpSuper`: pasa sin `otp` (rojo) | DS 3.3 |
| SH-23* | `Un_ADMIN_no_sella`: ADMIN con `otp` y `auth_time` reciente → 403 `SELLO_SOLO_SUPER`; también USER | H | 403 | **Mutación obligatoria:** cambiar `== SUPER` por `>= ADMIN`: rojo | DS 8 |
| SH-24* | `Autenticacion_antigua_no_sella`: `auth_time` de hace 301 s → 403 `SELLO_AUTENTICACION_ANTIGUA`; de hace 299 s → 200 (borde); sin el claim → 403 (falla cerrada) | H | borde exacto en 300 s | Quitar la comprobación: rojo; comparar `>` por `>=` con el reloj fijo en 300 s exactos: caso de borde cae | DS 3.4, 8 |
| SH-25 | Reloj: `auth_time` **en el futuro** (+10 min) o `auth_time` no numérico / negativo / `long.MaxValue` → 403 `SELLO_AUTENTICACION_ANTIGUA` (no 500, no pasa). Tolerancia de desfase hacia el futuro, la que decida A (D-4); sin decisión, se prueba solo +10 min | H | 403 | Aceptar futuro: pasa con +10 min (rojo) | DS 3.4; D-4 |
| SH-26* | `Un_token_programado_no_sella`: claim `prg` (token de servicio) → 401; la ruta no lleva `PermiteTokenProgramado` (TX: la declaración de la ruta no contiene esa llamada) | H, TX | 401; TX verde | Agregar `PermiteTokenProgramado`: rojo | DS 3.5, 8 |
| SH-27 | Sin sesión / sin `X-GPOS-Sesion` / token inválido / introspección caída → 401 (la caída falla cerrada, **no** 200 con caché vencida) | H | 401 | Aceptar con la caché vencida: rojo | DS 3.1 |
| SH-28* | `Fuera_de_la_canalizacion_no_se_alcanza`: la ruta no está publicada en el puerto de la Web ni en el reenvío del navegador. Caso 1: TX sobre el mapa de rutas del reenvío de la Web y de `ReenvioReportes` (no contienen `/api/impresion/formatos/sello`). Caso 2: petición por el transporte no canalizado (TCP/HTTP del fixture, si existe) → no se alcanza (404/conexión rechazada) | TX, H | no alcanzable | Agregar la ruta a la lista del reenvío del navegador: rojo | DS 3.6, 8 |
| SH-29 | Tope de frecuencia: la solicitud 21 en un minuto del mismo usuario → 429; otro usuario SUPER sigue en 200; tras avanzar el reloj 60 s vuelve a 200 | H | 429 en la 21 | Límite global en vez de por usuario: el segundo SUPER recibe 429 (rojo) | DS 3.7 |
| SH-30* | **La ruta no compila ni ejecuta ni guarda ni lee bases** (trampa en la plantilla; el doble de conexiones a `GPOS_SYSDATA` y a empresa registra 0 usos; el fixture no tiene credencial de escritura) | H | archivo no creado; 0 conexiones | Compilar la plantilla para «validarla»: la trampa crea el archivo (rojo) | DS 3 «Qué hace y qué no» |
| SH-31* | `El_registro_no_contiene_la_plantilla`: tras sellar (éxito, 403, 413, 422) ningún mensaje del `ILogger` doble contiene un fragmento reconocible de la plantilla (se usa una marca `MARCA-NO-REGISTRAR-7f3a`); sí contiene `Id`, SHA-256 de la plantilla, usuario y resultado | H | marca ausente; campos presentes | Registrar la plantilla en el 422: rojo | DS 3, 8 |
| SH-32 | EventId: el sellado concedido y el denegado usan ids dentro de 5150-5154; el id no choca con otro `EventId` del repositorio (TX/ARQ sobre las constantes; el `git grep` en todas las ramas lo hace A el día de construir, regla de ADR-82) | TX | únicos | Duplicar 5152 en otro evento: rojo | DS 7 |
| SH-33 | Un `version` distinto de 1 en la solicitud → 400/422 con código propio; campos desconocidos o falta de `id`/`plantilla` → 400 sin calcular | H | rechazo | Ignorar `version`: pasa (rojo) | DS 3 |
| SH-34 | `llave no disponible` al sellar (anillo caído) → 503 `SELLO_LLAVE_NO_DISPONIBLE`; no se devuelve un sello calculado con llave vacía ni cero | H | 503 | Capturar la excepción y usar `new byte[32]`: sella con llave cero (rojo) | DS 3 |
| SH-35 | Cuerpo de errores sin ruta interna, excepción ni carpeta del anillo | H | sin fuga | Poner `ex.Message` en el detalle: rojo | |

## 4. Verificación al renderizar (S, con trampa)

Base: `ServicioRender.HtmlAsync` con repositorio doble de `imp.Formato` y llave inyectada. Cada rechazo: salida = formato **estándar**, trampa sin crear, un EventId de rechazo con `Id` y motivo (nunca la plantilla).

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-30b* | Camino feliz: Razor con `GuardadoPorSuper=1` y huella correcta compila y renderiza | S | HTML de la plantilla | n/a | DS 5 |
| SH-31b* | `Razor_sin_marca_o_con_sello_alterado_no_se_compila`: teoría: (a) `GuardadoPorSuper=0` con huella válida → `SinMarca`; (b) marca 1 y `Huella` NULL → `SinSello`; (c) huella de 32 bytes o de 34 bytes → `SinSello` (o motivo de forma, D-5); (d) un bit cambiado en cada una de las 33 posiciones (inclúyase el byte `Kid`, que da `KidDesconocido` o `SelloNoCoincide` según el caso) → rechazo; (e) plantilla modificada tras sellar (un carácter) → `SelloNoCoincide`; (f) `Id`, `TipoDocumento`, `Modo` o `Papel` cambiados en la fila → `SelloNoCoincide`. En todos: trampa sin crear | S | rechazo + estándar | Compilar antes de verificar: la trampa se crea (rojo); verificar solo si `GuardadoPorSuper=1` y no el HMAC: (d)(e)(f) pasan (rojo) | DS 8, 5 |
| SH-32b* | **Comparación en tiempo constante (estructural):** TX o ARQ sobre el verificador: usa `CryptographicOperations.FixedTimeEquals` y no contiene `SequenceEqual`, `==` entre `byte[]`, `Convert.ToBase64String(...) ==` ni `string.Equals` sobre la huella. Un doble de la comparación (TB-3) cuenta llamadas: una por verificación, **también** cuando el largo no coincide | TX, S | solo `FixedTimeEquals` | Sustituir por `SequenceEqual`: rojo (TX) | DS 1 (FIPS), 5.3 |
| SH-33b | Temporal (no estadístico): se descarta medir tiempos de la comparación (inestable en CI). La garantía es SH-32b y la revisión del auditor-seguridad. Se deja anotado para no pedir lo que no se puede probar con rigor | n/a | n/a | n/a | |
| SH-34b* | `Visual_sin_Diseno_se_rechaza` (S-02): texto que compila y no sale de `GeneradorRazor` (modo `VISUAL` con `Plantilla` manipulada, sin `Diseno`) → rechazo aunque tenga marca y sello válidos del contenido; el sello **no** valida lo que no es Razor autorizado | S | rechazo + trampa | Verificar solo si `Modo = RAZOR`: el caso VISUAL con plantilla trampa compila (rojo) | DS 8, 5 |
| SH-35b* | `Llave_no_disponible_rechaza_y_no_compila`: el almacén de llave lanza; el verificador devuelve `LlaveNoDisponible`, estándar, trampa sin crear. Si la excepción es otra (p. ej. `CryptographicException`), también rechazo y no 500 | S | rechazo | Capturar y continuar sin verificar: rojo | DS 8, 5.4 |
| SH-36* | **Mismos bytes:** el texto verificado es el texto compilado. Doble del repositorio que devuelve la plantilla A la primera lectura y B a la segunda (TOCTOU); la compilación recibe A, no B. Si el código relee, la trampa de B se crea | S | compila solo A (o rechaza) | Releer la plantilla entre verificar y compilar: la trampa de B se crea (rojo) | DS 5.6 |
| SH-37 | Una sola lectura: el repositorio doble cuenta lecturas de la fila = 1 por render | S | 1 | Dos lecturas: rojo | DS 5.6 |
| SH-38 | Rechazo registrado **una vez por formato y hora**: 50 renders del mismo formato malo en el mismo instante registran 1 evento; al avanzar 61 min, otro; dos formatos distintos registran 1 cada uno. El evento lleva `Id` y motivo, no plantilla | S | 1 / 1 / 2 | Quitar la deduplicación: 50 eventos (rojo); deduplicar por hora global y no por formato: el segundo formato no se registra (rojo) | DS 5.5 |
| SH-39 | Memoria de la deduplicación acotada: 100 000 formatos malos distintos no hacen crecer el diccionario sin límite (tope documentado por A) | S | acotado | Diccionario sin tope: rojo (D-6) | [I] |

## 5. Llave, `Kid` y rotación

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-40* | `Kid_desconocido_rechaza`: huella con `Kid = 9` (sin llave) → `KidDesconocido`; trampa sin crear | S | rechazo | Usar la llave actual si el `Kid` no existe: verifica con la actual y falla por otra razón o, peor, pasa (rojo) | DS 8 |
| SH-41* | Cambiar solo el byte `Kid` de una huella válida por otro `Kid` **conocido** (durante la ventana) → `SelloNoCoincide` (H-3) | S | rechazo | Verificar con la llave del `Kid` actual en vez del declarado: según la mutación, un sello de la llave vieja pasa como nueva (rojo en SH-43) | H-3 |
| SH-42 | `K_hmac` por HKDF: la llave de sellado y otra subllave con distinto `info` producen HMAC distintos del mismo mensaje (hoy no hay segunda función; la prueba fija que el `info` está en el cálculo) | U | distintos | Usar `K` directo sin HKDF: SH-02 en rojo | DS 1 |
| SH-43* | `Rotar_la_llave_invalida_los_sellos_anteriores_tras_la_ventana`: (a) tras rotar, `Kid + 1` sella y verifica; (b) dentro de la ventana, el sello `Kid` viejo aún verifica; (c) con la ventana vencida (reloj +1 s sobre el fin), el mismo sello da `KidDesconocido` o motivo propio y el Razor sale estándar; (d) el sellado nuevo siempre usa el `Kid` mayor | S | (a)(b) verde, (c) rechazo | No expirar la llave vieja: (c) falla; sellar con la vieja: (d) falla | DS 8, 1 |
| SH-44 | Ventana de rotación: el borde (último instante válido y el siguiente) con reloj fijo; la ventana la fija el SUPER, no vale 0 ni negativa | S | borde exacto | `<=` por `<`: rojo | DS 1 (H-4) |
| SH-45 | `Kid` pasa de 255 a 0 (un byte): rotar la llave 256 veces no reutiliza un `Kid` activo: se rechaza la rotación 256 con error claro o se documenta el tope. **Duda D-7** | U | por decidir | n/a | [I] |
| SH-46 | La llave se genera la primera vez que hace falta sellar: 32 bytes, de `RandomNumberGenerator`; dos instalaciones distintas generan llaves distintas; no se genera al verificar (verificar sin llave → `LlaveNoDisponible`, **no** crea una llave nueva que luego «valide» algo) | S | no crea al verificar | Crear la llave en `Verificar`: SH-35b en rojo | DS 1 |
| SH-47 | Archivo `sello-razor.v{Kid}.bin`: contiene `Protect(K)`; el contenido no incluye `K` en claro (buscar los 32 bytes de la llave en el archivo); si el archivo se corrompe, `LlaveNoDisponible` | S | llave protegida | Guardar `K` sin proteger: rojo | DS 1 |
| SH-48 | Propósito de Data Protection `GPOS.Reportes.SelloRazor.Llave.v1`: un protector con otro propósito del mismo anillo no abre el archivo | S | `CryptographicException` | Usar propósito genérico: se abre (rojo) | DS 1 |
| SH-49 | Aislamiento del anillo (ADR-109 cl. 5): el anillo de la API de reportes está en carpeta distinta que el de la principal, y la principal no puede descifrar `sello-razor` (TX sobre rutas + ARQ: `GPOS.Reportes.Api` no referencia `GPOS.Core`). Cae a VM/instalador para la DACL | TX, ARQ | verde | Apuntar al anillo de la principal: rojo | ADR-109 cl. 5 |
| SH-50 | Respaldo/restauración (falla cerrada): se reemplaza la carpeta del anillo por una vacía o con otra llave → los formatos Razor sellados salen estándar, el resto de los reportes y formatos Visual sigue igual; un SUPER vuelve a guardar y vuelve a funcionar | S | estándar, luego recupera | n/a (es el procedimiento operativo) | DS 1 |
| SH-51 | Nodo con API de reportes propia (decisión del propietario, 22-oct): el sello de la central **no** verifica con la llave del nodo → Razor rechazado, estándar. Dos llaves distintas en dos fixtures: sello de uno presentado al otro → `SelloNoCoincide`. Nodo sin API de reportes: estándar | S | rechazo | Aprovisionar la misma llave: pasa (rojo; es el comportamiento prohibido) | DS 6 |

## 6. Cruce, repetición y reloj

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-60 | **Cruce de `Id` entre dos formatos de la misma empresa:** copiar `Huella` del formato 5 al 6 (distinto `Id`, misma plantilla) → `SelloNoCoincide` | S | rechazo | Excluir `Id` del mensaje: pasa (rojo) | DS 2 |
| SH-61 | **Cruce entre `TipoDocumento`** (FACTURA→COTIZACION con la misma plantilla y huella) → `SelloNoCoincide` | S | rechazo | Excluir `TipoDocumento`: rojo | DS 2 |
| SH-62 | **Cruce entre empresas del mismo sitio (H-1):** fila de la empresa Y con el mismo `Id`, `TipoDocumento`, `Modo`, `Papel` y `Plantilla` y la `Huella` de la empresa X. Con el diseño actual **verifica**. Caso de caracterización con `Trait("Decidido","no-implementado")` que afirma el comportamiento actual y su duplicado rojo `SH-62r` que afirma rechazo si B decide meter `EmpresaId` en el mensaje | S | caracterización: verifica; `SH-62r`: rechazo | Meter `EmpresaId`: SH-62 cambia de resultado (el equipo decide) | H-1, D-1 |
| SH-63 | **Cruce entre sucursales:** igual que SH-62 entre la base central y la de una sucursal con la misma API de reportes del sitio. Las sucursales autosuficientes tienen su propia API (SH-51); el caso solo aplica si comparten API | S | por decidir (D-1) | | H-1 |
| SH-70 | **Repetido (R-SELLO-1):** restituir un triple `(Id, Plantilla, Huella)` anterior (revisión menor) **verifica** (aceptado). La prueba lo fija y exige que el evento de render registre la `Revision` | S | verifica; el evento lleva `Revision` | n/a (caracteriza el riesgo aceptado) | DS 6 |
| SH-71 | Una revisión que **baja** respecto de la última vista por `Id` se detecta en el registro (mismo proceso: el diccionario de última revisión); se señala el evento, pero **no se rechaza** (no hay estado persistente) | S | evento de revisión regresiva | Rechazar por revisión: rojo (se rompe «sin escritura/estado») | DS 6 |
| SH-72 | El sello es válido tras reiniciar la API de reportes (no depende de memoria): reconstruir el servicio con la misma carpeta de llave y verificar | S | verifica | Llave solo en memoria: rojo | DS 1 |
| SH-73 | La misma solicitud de sellado enviada dos veces da la misma huella (idempotente, sin nonce) y se registra dos veces (concedido) | H | igual huella | Agregar un nonce: rojo | DS 2 |
| SH-74 | **Reloj de sellado:** `auth_time` se compara con el reloj inyectado, no con el `DateTime.UtcNow` real (TB-2); tras mover el reloj de la prueba, el borde de SH-24 se mueve | H | usa el reloj inyectado | Usar `UtcNow` directo: SH-24 inestable/rojo | DS 3.4 |
| SH-75 | El reloj del sistema retrocede 10 min (cambio de hora) con `auth_time` reciente → no da 500; el resultado es determinista (se acepta o 403, nunca excepción) | H | sin 500 | n/a | [I] |

## 7. Guardado en la principal (P, `GPOS.Tests`)

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| SH-80* | `Guardar_Razor_no_mantiene_transaccion_abierta_durante_la_llamada`: al llegar la llamada al doble de la API de reportes, `Database.CurrentTransaction == null` (y ningún bloqueo de aplicación `GPOS.*` tomado) | P | sin transacción | Envolver todo en `BeginTransaction`: rojo | DS 8, 4 |
| SH-81* | `Guardar_con_fila_cambiada_no_aplica_el_sello`: desde el doble de la API se modifica la fila (otra sesión sube la `rowversion`) antes del paso 3; el `UPDATE ... WHERE rowversion` afecta 0 filas; la fila queda `GuardadoPorSuper=0`, `Huella=NULL`; el SUPER recibe «el formato cambió; vuelva a guardar» | P | no se aplica | Quitar `AND rowversion = @rv`: el sello se aplica a una plantilla que no sello (rojo) | DS 8, 4.3 |
| SH-82* | `A1_rechaza_todo_Razor`: el camino temporal de la principal sin `K_sello` rechaza cualquier Razor leído de su base hasta T4-11 (trampa sin crear) | P | estándar | Verificar con llave vacía: pasa un sello cero (rojo) | DS 6, 8 |
| SH-83 | Paso 1 inerte: tras el paso 1 (antes del sello) la fila tiene `GuardadoPorSuper=0` y `Huella NULL`, y **no se renderiza** como Razor (CHECK `CK_FormatoImpresion_HuellaRazor` lo permite) | P | inerte | Marcar `GuardadoPorSuper=1` en el paso 1: rojo | DS 4.1 |
| SH-84* | API de reportes caída al guardar: el guardado falla visible; fila **nueva** retirada; edición conserva la **versión anterior sellada** (la huella anterior sigue verificando con su plantilla anterior); sin reintento automático (el doble cuenta 1 llamada) | P | falla; versión anterior intacta | Dejar la fila inerte sin retirar: rojo; sobrescribir la plantilla anterior con la nueva sin sello: la anterior deja de verificar (rojo) | DS 4.4 |
| SH-85 | La principal valida la respuesta: `huella` de 32 o 34 bytes, base64 inválido o `kid` fuera de rango → no aplica, guardado falla, no guarda `Huella` | P | falla | No validar el largo: guarda 34 bytes y revienta el `binary(33)` o guarda basura (rojo) | DS 4.5 |
| SH-86 | La principal guarda **exactamente** lo que envió: la plantilla enviada al sellado es igual, byte a byte, a la persistida (normalizaciones del ORM o del `nvarchar`, saltos de línea, recorte de espacios; con acento, emoji y `\r\n`) | P | idénticos | Recortar (`Trim`) antes de enviar: el sello no verifica después (rojo) | DS 4, 2 |
| SH-87 | Eventos: `FORMATO_RAZOR_SELLADO` en `BitacoraSeguridad` con `Id`, SHA-256 de la plantilla y usuario; está en el catálogo cerrado de T1-1 (TX sobre el catálogo). Sin plantilla en la bitácora | P, TX | presente | Escribir la plantilla: rojo | DS 4.6 |
| SH-88 | Un ADMIN que guarda un formato Razor por la ruta de la principal: la fila queda `GuardadoPorSuper=0`, sin llamada de sellado; imprime como estándar (consistente con el nivel de SH-23). Ni el ADMIN ni la principal pueden escribir `GuardadoPorSuper=1` ni `Huella` por otra ruta (ARQ/TX: solo `FormatosService` paso 3) | P | sin sello | Aceptar `GuardadoPorSuper` del cuerpo de la petición: rojo | DS 3.2, 4 |
| SH-89 | Migración: formatos Razor existentes quedan sin marca y no imprimen Razor hasta que un SUPER los guarda (ya firmado); formatos Visual no cambian | P | estándar para Razor | n/a | DS 6 |
| SH-90 | DDL: la columna `Huella` es `binary(33) NULL` y el CHECK impide `GuardadoPorSuper=1` con `Huella NULL` en Razor y `Huella` con `GuardadoPorSuper=0` si ése es el contrato de B (D-8) | P/TX | 33 | Dejar `binary(32)`: el insert de 33 bytes trunca o falla (rojo) | H-7 |

## 8. Compilación y criterio de PR

| ID | Comando | Esperado |
|---|---|---|
| BLD-1 | `dotnet build src/GPOS.Reportes.Api -c Release` y `-c Debug` | 0 errores. En Release la ruta no tiene ninguna rama `#if DEBUG` que omita `otp` ni `auth_time` (TX, SH-22) |
| BLD-2 | `dotnet build tests/GPOS.Reportes.Tests` | 0 errores |
| RUN-1 | `GPOS.Reportes.Tests`, y después `GPOS.Tests` (filtro oficial `Transicion!=Ola5&Transicion!=Defecto`), **solas y una a la vez** | Cifras reales; las mutaciones `*` anotadas en el PR |

Orden sugerido: SH-02 (vector independiente) primero y ver que falla sin implementación; luego SH-21/23/24 con la mutación obligatoria; luego SH-31b/36/40; el resto.

## 9. Requisitos de testabilidad para A

| # | Requisito | Para |
|---|---|---|
| TB-1 | El almacén de la llave detrás de una interfaz pequeña (`IAlmacenLlaveSello`: `ObtenerActual()`, `Obtener(kid)`, `Rotar()`, `LlavesVigentes`) con doble en memoria; la implementación real sobre Data Protection | SH-02, 34, 35b, 40 a 51 |
| TB-2 | `TimeProvider` (o `IReloj`) inyectado en la ruta, en el verificador (ventana de rotación y deduplicación horaria) y en el límite de frecuencia. Prohibido `DateTime.UtcNow` y `Task.Delay` en esos tres | SH-24, 25, 29, 38, 43, 44, 74, 75 |
| TB-3 | La función de comparación detrás de un delegado o una clase pequeña (`IComparadorSello`) con una implementación que cuenta llamadas, o bien prueba TX estricta; sin medir tiempos | SH-32b |
| TB-4 | El cálculo del mensaje en una función **pura y pública a la suite** (`ConstruirMensaje(id, tipo, modo, papel, plantilla)` devolviendo `byte[]`) para fijar los vectores sin pasar por la llave | SH-02 a SH-06, 10 |
| TB-5 | El compilador de Razor detrás de una interfaz (`ICompiladorPlantilla`) para contar invocaciones, además de la plantilla trampa. La trampa es la prueba principal; el contador evita depender del sistema de archivos | SH-30 a SH-37 |
| TB-6 | La introspección con doble configurable (`nivel`, `amr`, `auth_time`, `prg`, y el fallo) en `GPOS.Reportes.Tests` | SH-20 a SH-29 |
| TB-7 | Repositorio de `imp.Formato` con doble que cuente lecturas y permita devolver dos versiones consecutivas (TOCTOU) | SH-36, 37 |
| TB-8 | Los motivos de rechazo como `enum` público (`SinMarca`, `SinSello`, `KidDesconocido`, `SelloNoCoincide`, `LlaveNoDisponible`) y no cadenas, para aserciones exactas; el EventId y su plantilla de mensaje también como constantes | SH-31b, 35b, 38 |
| TB-9 | Un `ILogger` doble que guarde el texto formateado y los parámetros (para buscar la `MARCA-NO-REGISTRAR`) | SH-31, 38 |
| TB-10 | En la principal, el cliente HTTP a la API de reportes por interfaz (`IClienteSelloRazor`), con doble que ejecute código en el punto de la llamada (SH-80, 81, 84) | SH-80 a SH-86 |
| TB-11 | Ninguna dependencia de `GPOS.Core` en `GPOS.Reportes.Api` ni en sus pruebas (DS «No verificado», ADR-109) | SH-49 |

## 10. Dudas para B y A (no las inventé)

| # | Para | Duda | Efecto |
|---|---|---|---|
| D-1 | B / A | El mensaje canónico no lleva `EmpresaId` ni sitio y el `Id` es local a cada base. Un sello válido de la empresa X sobre la fila del mismo `Id`, `TipoDocumento`, `Modo`, `Papel` y `Plantilla` de la empresa Y verifica (H-1). ¿Es aceptable (riesgo de confinamiento: quien escribe en Y ya puede escribir cualquier cosa, y el sello solo prueba que algún SUPER del sitio autorizó esa plantilla) o se agrega `EmpresaId` (o `Guid` de la empresa) al mensaje? Es un cambio de formato `v1`, mejor antes de construir | SH-62/63/62r |
| D-2 | A | `Papel` entra al mensaje (DS 2) pero la fórmula no lo muestra. ¿En qué posición, con qué tipo (texto ASCII con `uint16` de largo, como `Modo`?) y valores (¿puede ser NULL?)? | SH-05; el vector SH-02 queda sin `Papel` hasta entonces |
| D-3 | A | Plantilla vacía o solo espacios: ¿se sella o se rechaza (422)? | SH-11 |
| D-4 | A | Tolerancia de desfase de reloj hacia el futuro para `auth_time` (¿0, 30 s, 60 s?) | SH-25 |
| D-5 | A | ¿Una huella de largo incorrecto (32 o 34) se reporta como `SinSello` o con un motivo propio (`SelloMalFormado`)? | SH-31b(c) |
| D-6 | A | La deduplicación «una vez por formato y hora»: ¿en memoria y con tope? Un reinicio la reinicia. ¿Cuántos formatos como máximo? | SH-39 |
| D-7 | A / B | `Kid` es un byte: ¿qué pasa en la rotación 256? ¿Tope de rotaciones documentado? | SH-45 |
| D-8 | B | CHECK de `imp.Formato` (`CK_FormatoImpresion_HuellaRazor`): ¿qué combinaciones prohíbe exactamente (`GuardadoPorSuper=1` sin huella; `Huella` sin marca)? Lo leí solo referido en DS 4.1 | SH-83, 90 |
| D-9 | B | `HKDF info`, nombre de archivo y propósito de Data Protection son parte del contrato: ¿se fijan como constantes públicas para que las pruebas las comparen, o se prueban solo por comportamiento? | SH-02, 42, 47, 48 |
| D-10 | A | Los EventId 5153 y 5154 (concedido/denegado) son «propuesta» en DS 7: ¿cuál es la decisión final? | SH-32 |
| D-11 | A | ¿La ventana de rotación vive en configuración, en el archivo de llaves o en la base? Quién la escribe (el SUPER, por qué ruta) no está en DS y es una ruta más que probar y asegurar | SH-43, 44 |

## 11. Lo que no verifiqué

- No compilé ni ejecuté nada; ninguna mutación fue corrida.
- No releí la sección 3.2 de `docs/datos/2026-10-22-t4-10-vistas-imp.md` (PR #178, rama `b/datos-t4-10`): tomo de DS lo que B dijo. El vector SH-02 y D-2/D-8 dependen de ella.
- No verifiqué en el código que `ResultadoIntrospeccion.Claims` entregue `auth_time` ni que el fixture de la API de reportes permita una introspección doble configurable (DS lo da por [V] en 3.4; lo uso como tal).
- No verifiqué la DACL ni el aislamiento real del anillo: SH-49 cubre solo lo textual; el resto va a laboratorio/instalador.
- Medir tiempos de la comparación no se prueba (SH-33b): la garantía de tiempo constante es la revisión del auditor-seguridad más SH-32b.
