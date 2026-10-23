# Diseño del sello HMAC de DD-11′ en la API de reportes (sin compilar) · equipo A · 2026-10-22

Responde a la tarea 3 de `avisos/B-a-A/2026-10-22-encargo-tareas-1-3-4-7.md`. Insumos leídos: sección 3.2 de `docs/datos/2026-10-22-t4-10-vistas-imp.md` (PR #178, rama `b/datos-t4-10`), la hoja del #179, ADR-109 cl. 5 y 6, `CifradorAnillo.cs` en `origin/feature/modelo-ng`. Marcas: [V] verificado por lectura; [I] inferido, a comprobar al construir. Nada de esto está construido.

## 0. Resumen
1. El mensaje canónico de la sección 3.2 de B **se adopta tal cual**; añado dos cosas: un `Kid` (versión de la llave) dentro del sello y una revisión de fila fuera del mensaje solo para auditoría (ver 6, R-SELLO-1).
2. **Hallazgo de diseño:** `CifradorAnillo` **no** guarda secretos arbitrarios: cifra el XML de las llaves del anillo de Data Protection con AES-256-GCM y RSA-OAEP-SHA256 [V]. «La llave del sello vive en el anillo» se traduce a: la API de reportes tiene **su propio anillo de Data Protection** (cuyo cifrado de llaves usa `CifradorAnillo`, como la principal) y la llave `K_sello` se guarda **protegida por un `IDataProtector` de ese anillo**. Eso crea el anillo propio de la API de reportes, que ADR-109 cl. 5 admite pero que **hoy no existe**: es trabajo nuevo (carpeta, ACL, instalador de la API de reportes).
3. La ruta que sella es **el punto más sensible de la API de reportes**: sellar equivale a autorizar la ejecución de C# en un proceso que abre los sobres de todas las empresas. Va restringida a SUPER con `otp` reciente, solo por la canalización, sin token de servicio, con tope de tamaño, límite de frecuencia y evento.
4. La principal **no mantiene una transacción abierta durante la llamada HTTP**: guarda la fila sin marca (inerte), pide el sello y actualiza con una guarda de concurrencia.
5. Falla cerrada en todos los casos: sin marca, sin sello, sello inválido, llave no disponible o sin API de reportes → no se compila el Razor y sale el formato estándar.

## 1. Dónde vive la llave
- **Anillo propio de la API de reportes** (ADR-109 cl. 5): carpeta y DACL de la cuenta virtual del servicio de reportes; las llaves del anillo se cifran con `CifradorAnillo` para el certificado del servidor (y el de recuperación), igual que en la principal. La API de reportes **no** puede abrir el anillo de la principal ni al revés [V, cl. 5].
- **`K_sello`:** 32 bytes de `RandomNumberGenerator`, generados la primera vez que hace falta sellar. Se guardan en `sello-razor.v{Kid}.bin` dentro de la carpeta del anillo, como `IDataProtector("GPOS.Reportes.SelloRazor.Llave.v1").Protect(K)`. Se cargan en memoria al primer uso y se ponen a cero al detener el servicio.
- **Subllave por uso:** no se usa `K` directamente. `K_hmac = HKDF-SHA256(K, info = "GPOS.Imp.Sello.v1")`. Una futura segunda función (otro tipo de sello) deriva otra subllave.
- **`Kid`:** un byte que identifica la llave. El sello guardado es `Huella = Kid(1 byte) ‖ HMAC(32 bytes)`, **33 bytes**, no los 32 de la columna `binary(32)` que propone B. **Cambia el DDL:** `Huella binary(33) NULL` (la hoja del #178 lo debe ajustar antes de construir).
- **Rotación:** se genera una llave nueva con `Kid + 1`; las anteriores se conservan solo para verificar durante la ventana que decida el SUPER; vencida, los formatos con el `Kid` viejo dejan de imprimir Razor hasta guardarse de nuevo. Sin rotación automática en esta etapa.
- **Respaldo y restauración:** la llave es del sitio. Si se pierde la carpeta del anillo o se restaura una copia anterior, **los sellos no verifican y el Razor sale como estándar** hasta que un SUPER guarde de nuevo; esa es la falla cerrada esperada. Va en el procedimiento operativo (devops/documentador).
- FIPS: HMAC-SHA256, HKDF-SHA256 y AES-GCM son algoritmos aprobados; la comparación es `CryptographicOperations.FixedTimeEquals`.

## 2. Mensaje canónico (adoptado de B, sección 3.2)
Sin cambios: `ASCII("GPOS.Imp.Sello.v1") ‖ 0x00 ‖ int32 BE (Id) ‖ uint16 BE + ASCII(TipoDocumento) ‖ uint16 BE + ASCII(Modo) ‖ uint32 BE + UTF-8(Plantilla)`. Reglas de implementación:
- UTF-8 **estricto** (`UTF8Encoding(false, throwOnInvalidBytes: true)`): una plantilla con sustitutos sin par se rechaza al sellar y al verificar.
- Sin normalización Unicode ni cambio de saltos de línea: la plantilla se sella y se verifica **tal cual está en la base**.
- Tope de `Plantilla`: 256 KB en el sello y en la verificación (más de eso → rechazo; no se calcula HMAC sobre entrada sin tope).
- `TipoDocumento` y `Modo` solo ASCII; cualquier otro carácter rechaza.
- **`Papel` entra al mensaje** (lo adoptó B en la revisión 4 del #178; antes lo dejé condicionado a que el render no lo compile). `Orientacion` queda fuera: no se compila. Verificar al construir si el render usa algún otro campo de la fila para armar lo que compila, y entonces también entra.

## 3. Contrato de la ruta que sella
`POST /api/impresion/formatos/sello` en `GPOS.Reportes.Api`, solo por la canalización de la principal.

**Solicitud (JSON):** `{ "version": 1, "id": 123, "tipoDocumento": "FACTURA", "modo": "RAZOR", "plantilla": "…" }`.
**Respuesta 200:** `{ "huella": "<base64url de 33 bytes>", "kid": 1 }`. **Errores:** 401 (sin sesión o `X-GPOS-Sesion`), 403 `SELLO_SOLO_SUPER` (nivel distinto de SUPER) o `SELLO_REQUIERE_OTP` / `SELLO_AUTENTICACION_ANTIGUA`, 413 `SELLO_PLANTILLA_GRANDE`, 422 `SELLO_PLANTILLA_INVALIDA` (UTF-8 inválido, Modo distinto de `RAZOR`), 429, 503 `SELLO_LLAVE_NO_DISPONIBLE`.

**Quién puede llamarla (todas, en este orden, falla cerrada):**
1. Autenticación por introspección (el esquema `GPOS.Introspeccion` de siempre); el token lo reenvía la principal tal como lo recibió del SUPER.
2. **Nivel SUPER** estricto: no ADMIN, no el menor de dos niveles. 
3. **`amr` contiene `otp`**, exigido por la propia ruta con la misma regla que `ExigeOtpSuper` [V `AutenticacionIntrospeccion.cs:110-115`], **sin** una vía más débil: si en Debug `ExigeOtpSuper` está apagado, la ruta sigue pidiendo `otp` salvo que la configuración de desarrollo diga explícitamente lo contrario y registre el evento al arrancar.
4. **Autenticación reciente:** el claim `auth_time` no más viejo que 5 minutos [I: confirmar que la introspección v1 lo devuelve para el token interactivo; si no, el claim se agrega]. Evita sellar con una sesión desatendida.
5. **No es un token de servicio:** la ruta no lleva `PermiteTokenProgramado` (cerrado por omisión) [V, A-4], y un `prg` en la solicitud da 401.
6. **Origen:** solo por la canalización (la ruta no se publica en el puerto de la Web ni en el reenvío del navegador). La principal es la única que la llama.
7. **Tope de frecuencia:** 20 por minuto y por usuario; sellar no es una operación de volumen.

**Qué hace y qué no:** valida forma, calcula el HMAC y responde. **No** compila ni ejecuta la plantilla, **no** lee `GPOS_SYSDATA` ni las bases de empresa, **no** guarda nada (la API de reportes sigue sin escribir, ADR-109). Registra el EventId de sellado (ver 7) con `Id`, SHA-256 de la plantilla, usuario y resultado; **nunca** el contenido.

## 4. Flujo de guardado en la principal (`FormatosService`)
B propone guardar la fila y pedir el sello «en la misma transacción». Lo corrijo: **no se debe tener una transacción de base abierta durante una llamada HTTP a otro proceso** (bloqueos largos, y un fallo de la red deja la transacción pendiente).
1. Transacción corta: `INSERT/UPDATE` de la fila con `GuardadoPorSuper = 0` y `Huella = NULL` (inerte: el CHECK `CK_FormatoImpresion_HuellaRazor` lo permite). Se obtiene `Id` y una revisión de la fila (`rowversion`).
2. Sin transacción: `POST …/sello` con el `Id`, `TipoDocumento`, `Modo` y la plantilla **exactos** que se guardaron.
3. Transacción corta: `UPDATE … SET Huella = @h, GuardadoPorSuper = 1 WHERE Id = @id AND rowversion = @rv`. Si afecta 0 filas (alguien guardó mientras tanto) no se aplica el sello y el SUPER recibe «el formato cambió; vuelva a guardar».
4. Si la API de reportes no responde: **el guardado falla visiblemente** (decidido por B, falla cerrada firmada): la fila Razor no queda guardada (se retira la fila inerte del paso 1 si era nueva, o se conserva la versión anterior sellada si era una edición) y se avisa al SUPER; no se reintenta solo.
5. La principal valida que la respuesta tenga `huella` de 33 bytes y `kid` coherente; no interpreta el sello.
6. Evento en `BitacoraSeguridad` (`FORMATO_RAZOR_SELLADO`, con `Id`, SHA-256 de la plantilla y el caso del ingreso del SUPER): **necesita estar en el catálogo cerrado de T1-1** (se construye desde el 2-nov). Hay que pedirlo ya al arquitecto-datos.

## 5. Verificación al renderizar (`ServicioRender.HtmlAsync`)
Para todo texto que compile y no salga de `GeneradorRazor` (S-02, sin importar `Modo`):
1. `imp.Formato` entrega `GuardadoPorSuper`, `Huella`, `Id`, `TipoDocumento`, `Modo` y la plantilla.
2. Exige `GuardadoPorSuper = 1`, `Huella` de 33 bytes y `Kid` conocido; si no, rechaza con motivo `SinMarca`, `SinSello` o `KidDesconocido`.
3. Recalcula el HMAC con `K_hmac` del `Kid` y compara con `FixedTimeEquals`; si no coincide, `SelloNoCoincide`.
4. Si `K_sello` no se puede abrir (anillo caído o sin acceso), `LlaveNoDisponible`: rechaza.
5. En todo rechazo: formato estándar, EventId de rechazo con `Id` y motivo (no la plantilla) y **una sola vez por formato y por hora** para que un formato malo no inunde el registro.
6. La verificación ocurre **antes** de pasar el texto al compilador y sobre los **mismos bytes** que se compilan (se lee la plantilla una vez y se usa esa referencia en las dos operaciones, sin releer la base entre medias).

## 6. Casos y riesgos
| Caso | Qué ocurre |
|---|---|
| A-1 (camino temporal de la principal) | No tiene `K_sello`: rechaza todo Razor leído de su base, hasta T4-11 (lo dice B en 3.2) |
| Nodo con su propia API de reportes | **Decidido por el propietario (chat, 2026-10-22):** la API de reportes de un nodo **no acepta** el sello de la central (llave distinta); el Razor se rechaza y sale el formato estándar. Es la opción (1) de la versión anterior de este documento; no se aprovisiona la misma llave en los nodos |
| Nodo sin API de reportes | Razor rechazado; estándar |
| Formatos Razor existentes | La migración los deja sin marca; no imprimen hasta que un SUPER los vuelva a guardar (ya firmado) |
| Reportes caída al guardar | No hay sello; ver 4.4 |

- **R-SELLO-1 (Baja, aceptado) repetición:** quien escribe en `conf` puede restituir una plantilla vieja con su sello válido (un triple `Id, Plantilla, Huella` anterior). Impacto limitado: era código que un SUPER ya había autorizado alguna vez. Mitigación sin estado nuevo: `imp.Formato` entrega también una revisión (`Revision int`, la incrementa la principal en cada guardado) **solo para auditoría**: el evento de rechazo/éxito de render la registra y una revisión que baja se detecta en el registro. Cerrarlo del todo exigiría que la API de reportes guarde estado (último sello por `Id`), lo que rompe «ninguna escritura» (ADR-109); queda como mejora posterior.
- **R-SELLO-2 (Media):** el sellador es un oráculo para quien controla una sesión de SUPER con `otp`. Es inherente a DD-11 (el SUPER es de confianza); los controles de la sección 3 lo acotan (reciente, limitado, auditado).
- **R-SELLO-3 (Media):** la principal comprometida en ejecución puede reenviar un token de SUPER robado y sellar. Igual que B (B3.2: «ninguna opción resiste a una principal comprometida»).
- **R-SELLO-4 (Baja):** el anillo propio de la API de reportes es trabajo nuevo no planificado (carpeta, DACL, certificado de recuperación). Sin él no hay Razor sellado; no bloquea el resto de T4-10.

## 7. EventId (actualizado tras la respuesta de B del 2026-10-22)
El #170 conserva 5117 a 5119 (5118 reservado a T4-03b). **T4-10 usa 5150 a 5152** (`ImpresionLecturaInconsistente` 5150, `ImpresionCopiaNoRegistrada` 5151, `SelloRazorRechazado` 5152); 5130 a 5149 están reservados al instalador (N-8). Para el sellado concedido y denegado, B asigna dos más junto a esos (propongo 5153 y 5154) o los reúne en 5152 con un motivo; se verifica con `git grep` en todas las ramas el día que se construya (regla de ADR-82, precisión 2026-10-19). La primera propuesta de este documento (5134 a 5139) queda **descartada**.

## 8. Pruebas mínimas
En `GPOS.Reportes.Tests`: `Sello_igual_para_el_mismo_mensaje`, `Cambiar_Id_TipoDocumento_Modo_o_Plantilla_cambia_el_sello`, `Plantilla_con_UTF8_invalido_se_rechaza`, `Plantilla_de_mas_de_256KB_se_rechaza`, `Sin_otp_no_sella`, `Un_ADMIN_no_sella`, `Autenticacion_antigua_no_sella`, `Un_token_programado_no_sella`, `Fuera_de_la_canalizacion_no_se_alcanza`, `Kid_desconocido_rechaza`, `Llave_no_disponible_rechaza_y_no_compila`, `Razor_sin_marca_o_con_sello_alterado_no_se_compila` (con una plantilla que dejaría un archivo si se compilara), `Visual_sin_Diseno_se_rechaza` (S-02), `El_registro_no_contiene_la_plantilla`, `Rotar_la_llave_invalida_los_sellos_anteriores_tras_la_ventana`. En `GPOS.Tests`: `Guardar_Razor_no_mantiene_transaccion_abierta_durante_la_llamada`, `Guardar_con_fila_cambiada_no_aplica_el_sello`, `A1_rechaza_todo_Razor`. Mutación obligatoria: quitar la comprobación de `otp` o de nivel debe hacer fallar una prueba.

## 9. Esfuerzo y dependencias
- Anillo propio, `K_sello` y HKDF: 0,5 dp. Ruta, controles y evento: 0,5 dp. Verificación en el render y rechazos: 0,4 dp. Guardado en la principal (dos pasos, guarda de concurrencia): 0,3 dp. Pruebas: 0,5 dp. **Total 2,2 dp ±30 %**, por encima de los 1 a 1,5 dp de la hoja (la diferencia es el anillo propio, que la hoja no cuenta). El auditor-seguridad revisa el PR.
- Antes de construir: `Huella binary(33)` en el DDL del #178; **agregar la lectura de `auth_time`** (hoy `GPOS.Reportes.Api` no lo lee en ningún sitio [V, 22-oct]: sin él la ruta de sellado falla cerrada; costo mío, no contado en la hoja); pedir `FORMATO_RAZOR_SELLADO` a T1-1; decidir 4.4; instalador de la API de reportes crea la carpeta y la DACL del anillo.

## Cierre
- Estado: Completado (diseño, sin compilar). Entrega a: arquitecto-software de B (4.4, nodos, EventId), arquitecto-datos de B (`binary(33)`, `Revision`, catálogo de T1-1), devops (anillo propio), auditor-seguridad (revisión del PR).
- No verificado: que `ServicioRender` no compile nada que dependa de `Papel`; que la introspección v1 devuelva `auth_time`; la integración de Data Protection en `GPOS.Reportes.Api` sin referenciar `GPOS.Core`.
