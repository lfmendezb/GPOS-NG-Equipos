# [Informe de Seguridad] SEG-CORP-08: el servidor rechaza la autorización «de otra persona» con la credencial propia

- **Fecha:** 2026-10-16 · **Revisor:** auditor-seguridad (equipo A)
- **Árbol:** `GPOS-NG-autoriz` · **Rama:** `a/autorizacion-otra-persona` · **Commit:** `3f953c9c` sobre `ce33b2a8`
- **Origen:** SEG-CORP-08 (`traspasos/A/revision-seguridad-diseno-corporativa-2026-10-15.md`, línea 190), aviso `avisos/A-a-B/2026-10-15-hallazgo-autorizacion-otra-persona.md` y encargo `avisos/B-a-A/2026-10-16-encargos-autorizacion-y-t6.md`, §1
- **Método:** lectura del diff y de los archivos completos tocados, y búsqueda de todas las rutas de autorización. No compilé ni ejecuté pruebas: las corre otro proceso. No modifiqué código.

**Dictamen (recomendación técnica, C2): Aprobado con observaciones.** El cambio cierra SEG-CORP-08 en el núcleo, en todas las rutas que validan la autorización en el servidor. No hay hallazgos Críticos ni Altos. Las observaciones son, sobre todo, deudas que ya existían o que vienen después (la eliminación de renglones del POS y el modo «solo otra persona» de la Corporativa). Ninguna bloquea la unión.

---

## 1. Alcance y superficie revisada

| Superficie | Archivo | Qué hace |
|---|---|---|
| Validador común (forma A y forma B) | `src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs` | Archivo completo |
| `POST /api/pos/autorizar` (eliminar renglones) | `src/GPOS.Api/Endpoints/PosEndpoints.cs:44-80` | Respuesta verdadero o falso; no emite ficha |
| Autorizador de credenciales | `src/GPOS.Core/Sistema/AutorizadorSupervisor.cs`, `src/GPOS.Core/Sistema/UsuariosService.cs:28-90` | Sin cambios; revisado por la comparación y el conteo de intentos |
| Llamadores del validador | `DocumentosComercialesService.Ventas.cs:166-176` (P-2 y P-4 de crédito), `PosService.cs:618-624` (P-4 del POS), `ReimpresionService.cs:65-72` (VE-01), `ImpresionEndpoints.cs:185-195` | Sin cambios |
| Interfaz | `src/GPOS.Web/Components/Compartidos/DialogoAutorizacion.razor`, `DialogoAutorizacionSupervisor.razor`, `Servicios/VistaAutorizacionSupervisor.cs` y sus copias en `GPOS.UI.MAUI` | Sin cambios |
| Identidad de la sesión | `src/GPOS.Api/Seguridad/Seguridad.cs:71` y `:105`, `AuthEndpoints.cs:62` | Sin cambios |
| Contratos | `AutorizacionSupervisor.cs`, `CodigosDocumento.cs` | Solo documentación |
| Pruebas | `AutorizacionSupervisorTests.cs`, `ReimpresionTests.cs`, `FlujosMvpTests.cs` | 6 pruebas nuevas |

**Rutas de autorización «de otra persona» en el núcleo (búsqueda de `AutorizacionesSupervisor`, `IAutorizadorSupervisor`, `ValidarAutorizanteAsync` y «supervisor» en `src`):**

| Operación | Entrada | ¿Aplica el rechazo? |
|---|---|---|
| P-2: factura a crédito que excede el límite | `DocumentosComercialesService.Ventas.cs:175` → `ValidarAsync` | Sí |
| P-4: devolución de crédito fuera de plazo | Misma línea (opción Devoluciones) | Sí |
| P-4: devolución del POS fuera de plazo | `PosService.cs:623` → `ValidarAsync` | Sí |
| VE-01: reimpresión con autorización | `ReimpresionService.cs:70` → `ValidarAsync` | Sí |
| Eliminar renglones del POS | `PosEndpoints.cs:63` y `:65` | Sí, pero el control lo decide el cliente (SC08-01) |
| Reversos, descuentos, «sin carné» | No existen en el núcleo actual; son de la vertical Corporativa (entrega 3) | No aplica hoy (SC08-02) |
| Cierres X y Z | `CierresCajaService.cs:408-411` | No aplica: es un permiso de la sesión, sin credencial de otra persona |
| `FECHA_ANTERIOR`, `SIN_NCF`, `BAJA_DEVOLUCION`, `RECIBE_NO_RECIBIDO`, `DIF_PRECIO_COMPRA` | `FechasDocumento.cs:82`, `DocumentosComercialesService.Compras.cs:275`, `:409`, `:415`, `CuentasPorPagarService.Notas.cs:304` | No aplica: por diseño son privilegio propio, y el autorizante es `sesion.Usuario` |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| SC08-01 | Media | Eliminación de renglones del POS: el servidor no ata la autorización a la operación ni registra la autorización concedida. El rechazo nuevo solo frena a la interfaz honesta | Ya existía (ADR-68, P-11); fuera del alcance del PR |
| SC08-02 | Baja (Media al construir la Corporativa) | El validador no tiene un modo «solo otra persona»: la forma B siempre vale, así que no sirve todavía para reversos y «sin carné» | Diseño pendiente |
| SC08-03 | Baja | Eliminar renglones: el servidor acepta «Punto de venta · Autorizar» como privilegio, pero la interfaz no lo trata como privilegio propio. Ese usuario queda sin forma de autorizar | Funcional y de coherencia |
| SC08-04 | Baja | Pruebas: el chequeo posterior con el código canónico se prueba solo con un autorizador simulado. Hay SQL concatenado en una prueba | Higiene de pruebas |

Total: 0 Críticas, 0 Altas, 1 Media, 3 Bajas.

## 3. Checklist OWASP Top 10 (2021), limitado al cambio

| Categoría | Resultado | Evidencia |
|---|---|---|
| A01 Control de acceso roto | **Bien** en el validador común. Observación en la eliminación de renglones (SC08-01) y en el modo «solo otra persona» (SC08-02) | `AutorizacionesSupervisor.cs:94-105`, `:135`; `PosEndpoints.cs:63`, `:65`, `:76-79` |
| A02 Fallas criptográficas | No aplica: el cambio no toca hashes ni llaves (PBKDF2 sin cambios, `UsuariosService.cs:16-17`) | — |
| A03 Inyección | Bien en producción: la bitácora usa el código ya normalizado e igual al de la sesión. Observación de higiene en una prueba (SC08-04) | `AutorizacionesSupervisor.cs:143`, `:158`; `ReimpresionTests.cs:127` |
| A04 Diseño inseguro | Bien: se comprueba en el servidor y la interfaz no decide. Observación: SC08-02 | — |
| A05 Configuración de seguridad | No aplica | — |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos | — |
| A07 Identificación y autenticación | Bien: el rechazo previo a la contraseña no cuenta intentos y no crea un oráculo (sección 5) | `AutorizacionesSupervisor.cs:105`; `UsuariosService.cs:80-90` |
| A08 Integridad de software y datos | No aplica | — |
| A09 Registro y monitoreo | Bien: cada rechazo deja su línea en la bitácora y un aviso en el registro, sin la contraseña. Observación: SC08-01 (la eliminación autorizada no deja rastro) | `AutorizacionesSupervisor.cs:139-160`; `PosEndpoints.cs:53-62` |
| A10 SSRF | No aplica | — |

## 4. Hallazgos

### SC08-01 · Media · Eliminar renglones del POS: la autorización la decide el cliente y el servidor no la registra

- **Riesgo (verificado; ya existía).** `POST /api/pos/autorizar` responde verdadero o falso (`PosEndpoints.cs:76-79`). La pantalla decide con esa respuesta (`DialogoAutorizacion.razor:47`; `PuntoVenta.razor:495-503`). El renglón eliminado nunca llega al servidor y la autorización concedida no deja línea en la bitácora: solo el rechazo deja un aviso en el registro (`PosEndpoints.cs:78`). Es el patrón que ADR-68 descartó como «opción D» y que dejó pendiente con P-11 (`docs/adr/ADR-068.md`, Contexto y Consecuencias). El fraude del dominio es la anulación de renglones en la caja (*sweethearting*: se escanea el artículo, se cobra y se elimina el renglón). Con un cliente modificado se elimina sin pedir nada. Por eso el rechazo de SEG-CORP-08 en esta ruta es correcto, pero solo frena a la interfaz honesta.
- **Remediación (fuera de este PR).**
  - Que `VentaPos` lleve las eliminaciones de renglones posteriores al escaneo, cada una con su `AutorizacionSupervisor`.
  - Validarlas con `AutorizacionesSupervisor.ValidarAsync` (opción Punto de venta) dentro de `VenderAsync`.
  - Registrarlas en `doc.Autorizacion` con un tipo nuevo (por ejemplo, `ELIMINA_RENGLON`; amplía `CK_Autorizacion_Tipo`).
  - Dejar `/api/pos/autorizar` solo como verificación previa de la interfaz, o retirarlo.
  - Defensa en profundidad: el reporte de eliminaciones por cajero (RC-05 o equivalente).
  - Costo: unas 0,3 a 0,5 sp (inferido, ±50 %).
- **Alternativa descartada:** una ficha de un solo uso emitida por `/api/pos/autorizar` (la opción C de ADR-68). Tiene más piezas y la eliminación sigue sin quedar registrada en el documento.

### SC08-02 · Baja hoy (Media cuando se construya la Corporativa) · No hay un modo «solo otra persona»

- **Riesgo (verificado).** `ValidarAsync` siempre acepta la forma B cuando la sesión tiene «Autorizar» en la opción (`AutorizacionesSupervisor.cs:95-101`), y el autorizante queda como `sesion.Usuario`. Es lo firmado para P-2, P-4 y la reimpresión (ADR-68, Q-5, A + B), así que **hoy no es un defecto**. En la reimpresión, la forma B ni siquiera se alcanza: la autorización solo se pide si la sesión no tiene el privilegio (`ReglasReimpresion.cs:41`). Pero SEG-CORP-08 (remediación 1) pedía para la Corporativa comparar `Autorizante` con la sesión en las operaciones que exigen segregación (reverso, identificación sin carné). Allí «mirar `PorCredencial` no basta», porque la forma B también da `Autorizante == sesión`. El validador no tiene ningún parámetro para excluir la forma B, y el commit no lo agrega. El código de error también difiere de lo sugerido (`AUTORIZANTE_MISMO_USUARIO`). Elegir `AUTORIZACION_INVALIDA` es razonable: mantiene el diálogo abierto en la Web y en MAUI sin cambiar la interfaz.
- **Remediación.**
  - Cuando se construya la Corporativa: un parámetro `soloOtraPersona` en `ValidarAsync` (o una sobrecarga) que rechace la forma B con 422 `AUTORIZACION_INVALIDA` y un texto propio.
  - Una prueba por cada operación que lo use (reverso, sin carné).
  - Registrar en la Corporativa qué operaciones exigen segregación estricta.
  - Costo: unas 0,05 sp.

### SC08-03 · Baja · Eliminar renglones: la interfaz y el servidor no coinciden en el privilegio propio

- **Riesgo (verificado).** El servidor acepta como autorizante a quien es ADMIN, tiene `eliminarrenglon` o tiene «Punto de venta · Autorizar» (`PosEndpoints.cs:77`). La interfaz omite el diálogo solo con `EliminarArticulos` o `eliminarrenglon` (`PuntoVenta.razor:497`), y el diálogo no tiene forma B (`DialogoAutorizacion.razor:40-52`). Un perfil a medida con «Punto de venta · Autorizar» y sin `eliminarrenglon` antes se autorizaba con su propia credencial. Ahora recibe el 422 con «Pida la autorización de un supervisor» (`PosEndpoints.cs:59`, `MensajeMismoUsuario(null)`), aunque el servidor lo considera apto para autorizar a otros. No abre ninguna brecha (es más estricto), pero confunde y empuja a compartir contraseñas. El perfil de ejemplo «Supervisor» trae `eliminarrenglon` (`PermisosService.cs:356`), así que el caso solo aparece con perfiles a medida.
- **Remediación.** Elegir una de dos:
  - que la pantalla trate `PuedeAccion(PuntoVenta, Autorizar)` como privilegio propio y omita el diálogo; o
  - quitar esa acción de la condición del servidor (`PosEndpoints.cs:77`), para que solo autoricen ADMIN y `eliminarrenglon`.

  La segunda es la más simple y coincide con la descripción del privilegio («Eliminar renglones en POS sin autorización», `Permisos.cs:269`). Costo: menos de 0,05 sp.

### SC08-04 · Baja · Pruebas: falta el caso con la intercalación real y hay SQL concatenado

- **Riesgo (verificado).** El chequeo posterior con el código canónico (`AutorizacionesSupervisor.cs:135`; `PosEndpoints.cs:65`) es lo que cubre la intercalación de la base, que no distingue mayúsculas, acentos ni ancho (`UsuariosService.cs:119-121`). Solo se prueba con un autorizador simulado que devuelve «JOSÉ» (`ReimpresionTests.cs:163-184`). No hay ninguna prueba de integración con la base real (un código escrito con otro ancho o sin tilde contra la propia cuenta), ni del chequeo posterior en `/api/pos/autorizar`. Además, `ReimpresionTests.cs:127` arma el SQL concatenando el código. Hoy es una constante y no hay riesgo, pero es un mal ejemplo.
- **Remediación.**
  - Una prueba en `FlujosMvpTests` que entre como un usuario y envíe su código con una variante que la intercalación iguale (con la contraseña correcta). Debe esperar 422 con «mismo usuario» y la línea en la bitácora.
  - Parametrizar la consulta de `ReimpresionTests.cs:127`.
  - Costo: unas 0,05 sp.

## 5. Controles que están bien implementados

1. **El rechazo está en el validador común.** Las cuatro operaciones que validan la autorización en el servidor pasan por `ValidarAsync`: P-2, P-4 de crédito, P-4 del POS y la reimpresión (sección 1). La ruta del POS replica la regla con las mismas funciones (`EsUsuarioSesion`, `MensajeMismoUsuario`, `CausaMismoUsuario`).
2. **Comparación del usuario.**
   - La identidad de la sesión es el código canónico de la base: el token lleva `u.Codigo` (`Seguridad.cs:71`), que sale de la entidad validada (`AuthEndpoints.cs:62`, `:89`).
   - La comparación quita los espacios de los extremos y no distingue mayúsculas (`AutorizacionesSupervisor.cs:64-65`).
   - Si lo escrito difiere de la sesión pero la intercalación lo iguala, se compara el código que devuelve la base (`:135`; `PosEndpoints.cs:65`), así que tampoco pasa.
   - Los espacios internos o los caracteres de otro ancho no permiten eludir la regla: o no encuentran la cuenta (credencial incorrecta) o el chequeo posterior los iguala.
3. **Varias empresas.** Los usuarios son globales en `GPOS_SYSDATA` (SEG-CORP-01). El mismo código es la misma persona en cualquier empresa, así que no hace falta comparar la empresa. Un token de dispositivo no lleva usuario (`AutenticacionDispositivo.cs:50-68`): `EsUsuarioSesion` da falso con la sesión vacía y la forma B no tiene privilegio. Además, SD-03 rechaza antes la comandera personal (`AutorizacionesSupervisor.cs:86-88`).
4. **Sin enumeración ni evasión del conteo.**
   - El rechazo previo a la contraseña solo responde algo distinto cuando el código es el del propio usuario, que ya lo conoce. No revela si existen otras cuentas ni en qué estado están.
   - No valida la contraseña de la propia cuenta, así que no crea un oráculo.
   - No toca el conteo de intentos de ninguna otra cuenta.
   - En el chequeo posterior la contraseña sí se valida y cuenta con el flujo normal (`UsuariosService.cs:35-54`), lo cual es aceptable.
   - Para inundar la bitácora con rechazos haría falta una sesión válida, y lo acota el limitador global por usuario (`LimitesPeticiones.cs:132-137`).
5. **Bitácora.** Cada rechazo deja una línea en `audit.Bitacora` con la pantalla «Autorización de supervisor», el código como entidad y la causa «credencial del mismo usuario de la sesión». Se escribe en su propia transacción y sin la contraseña (`AutorizacionesSupervisor.cs:139-160`), y va con su aviso en el registro del servidor (`:155`). La contraseña sale de la petición antes de la huella (`SepararClave`, sin cambios).
6. **Código y mensaje coherentes con la interfaz.**
   - El código es el mismo 422 `AUTORIZACION_INVALIDA` de siempre.
   - `DialogoAutorizacionSupervisor` lo mantiene en el diálogo (`VistaAutorizacionSupervisor.cs:70`) y muestra el detalle del problema (`ApiClient.cs:214`).
   - `DialogoAutorizacion` muestra el mensaje del `ApiException` (`DialogoAutorizacion.razor:50`).
   - Las copias de MAUI son idénticas a las de la Web (verificado con `diff`).
   - El texto indica la forma B cuando la sesión tiene el privilegio (`:57-61`, `:144`).
7. **Forma B conforme a lo firmado.** Se usa sin usuario, o con el propio usuario sin contraseña; exige `PuedeAccion(opción, Autorizar)` de la sesión y queda como «privilegio propio» (`AutorizacionesSupervisor.cs:95-101`, `:172`). Coincide con ADR-68, Q-5 (A + B). La forma A con otro usuario y sin contraseña sigue rechazándose (`:106`).
8. **Pruebas por operación.**
   - P-2, con la forma B como contraprueba (`AutorizacionSupervisorTests.cs:425-442`).
   - P-4 de crédito (`:445-459`).
   - P-4 del POS (`:462-480`).
   - Reimpresión, con un espía que comprueba que no se llamó al autorizador (`ReimpresionTests.cs:136-158`).
   - Código canónico (`:164-174`).
   - `/api/pos/autorizar`, con espacios y minúsculas y el conteo de intentos en 0 (`FlujosMvpTests.cs:180-212`).
   - Todas comprueban el 422, el texto, el conteo de intentos y la línea de la bitácora. No las ejecuté (C6).

## 6. Remediaciones priorizadas

| Prioridad | Hallazgo | Acción | Costo (inferido) | Cuándo |
|---|---|---|---|---|
| 1 | SC08-01 | Eliminaciones de renglones en `VentaPos`, validadas con `ValidarAsync` y en `doc.Autorizacion`; retirar la respuesta verdadero o falso | 0,3-0,5 sp | Antes del primer cliente (cierra P-11 de ADR-68) |
| 2 | SC08-03 | Alinear el privilegio de eliminar renglones entre la interfaz y el servidor | < 0,05 sp | Con SC08-01 o en un PR corto |
| 3 | SC08-04 | Prueba de integración con una variante de la intercalación; parametrizar la prueba | 0,05 sp | Puede ir en este mismo PR |
| 4 | SC08-02 | `soloOtraPersona` en el validador para reverso y «sin carné» | 0,05 sp | Al construir la Corporativa (entrega 3) |

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la unión la decide el propietario por medio de B). El commit `3f953c9c` cumple el encargo: el servidor rechaza la forma A con la credencial propia en todas las rutas que validan la autorización en el servidor, antes de la contraseña, con su bitácora y con un código que la Web y MAUI ya manejan. Las observaciones no lo bloquean.

---

### Supuestos
- Las pruebas nuevas pasan: no las ejecuté por indicación del encargo.
- La intercalación de `GPOS_SYSDATA` no distingue mayúsculas, acentos ni ancho, según el comentario de `UsuariosService.cs:119-121`. No lo verifiqué en la base.

### Entregas a otros agentes
- Desarrollador del núcleo (A) → SC08-01 y SC08-03: eliminaciones de renglones autorizadas en el servidor y privilegio alineado.
- qa-automatizado → SC08-04: prueba de integración con la intercalación real.
- arquitecto (Corporativa) → SC08-02: modo «solo otra persona» en el diseño del reverso y de la identificación sin carné.
