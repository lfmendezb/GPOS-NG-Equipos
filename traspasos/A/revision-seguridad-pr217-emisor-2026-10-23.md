# Informe de seguridad: PR #217 (T4-04, emisor del token de servicio de los envíos programados)

- Fecha: 2026-10-23
- Revisor: auditor-seguridad (agente de A). Solo lectura: no se modificó código del producto.
- Rama: `a/t4-04-emisor` (HEAD `d618bdf4`, rebasada sobre `feature/modelo-ng`); árbol `C:\Users\lfmen\source\repos\GPOS-NG-t404`.
- Decisiones de referencia: frontera F-1 a F-5 (2026-10-22), Q-T4-04 (a), P-1 (a) (el SUPER no tiene envío programado), ADR-109 cl. 6 y 7.
- Ya conocido y fuera de este informe: el token de servicio no pasa por `SucursalAjena` en la principal (lo cubren T4-06 y T4-07-02).

## 1. Alcance y superficie revisada

Diff `origin/feature/modelo-ng...HEAD` en `src/` (14 archivos) y sus pruebas (5 archivos):

- Emisión (principal, en el trabajo de notificaciones): `src/GPOS.Api/Seguridad/Programados/EmisorTokenServicio.cs`, `AccesoAutor.cs`, `RegistroSesionesTecnicas.cs`, `IEmisorTokenServicio.cs`; quien llama: `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:118-186`.
- Introspección (principal, canalización con ACL): `ValidadorTokenServicio.cs`, `src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs:38-42`, `RevocacionSesiones.cs:167-195`.
- Consumo (API de reportes): `src/GPOS.Reportes.Api/Seguridad/{AutenticacionIntrospeccion,PermiteTokenProgramado,VerificadorIntrospeccion}.cs`, `Endpoints/EndpointsReportes.cs:69-96`, `src/GPOS.Reportes/Contexto/ProveedorContexto.cs:92-117`.
- Comunes: `src/GPOS.Comun/Introspeccion/TokenProgramado.cs`, `src/GPOS.Comun/Sesion/ClaimsSesion.cs:61-71`.

Superficie: el token no lo emite ningún endpoint (solo el trabajo en segundo plano); se presenta en la API de reportes, que escucha en `localhost` (`src/GPOS.Reportes.Api/appsettings.json:15`) y cuya exportación solo existe por el canal interno de la principal (`EndpointsReportes.cs:72`, `PorCanalInterno`).

Pruebas ejecutadas (sin recompilar; binarios de 18:20-18:22, posteriores al último commit de 18:19):
- `tests/GPOS.Tests`: `dotnet test --no-build --filter FullyQualifiedName~TokenServicio` → 52 superadas, 0 con error.
- `tests/GPOS.Reportes.Tests`: filtro `VerificadorIntrospeccion|AutenticacionIntrospeccion|ProveedorContexto` → 37 superadas, 0 con error.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| S217-01 | Baja | Un valor `gpos-prg.` repetido o mal formado evita la caché, llega siempre a la principal y deja un Warning 4793 por petición, sin límite de ritmo previo |
| S217-02 | Baja | El claim `nivel` del token de servicio es el vigente, no el menor entre el de la emisión y el vigente: un ascenso posterior a la emisión se aplica de inmediato (distinto del JWT) |
| S217-03 | Baja | La emisión no comprueba el acceso del autor a la empresa (solo que exista y esté habilitada); lo frena la API de reportes, tarde |
| S217-04 | Baja | Huecos de prueba: el ascenso de nivel sin pasar a SUPER, el valor `gpos-prg.` mal formado en la API de reportes y la colisión de huella |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021)

| Punto | Estado | Evidencia |
|---|---|---|
| A01 Control de acceso | Correcto con observaciones (S217-02, S217-03) | Ruta cerrada por omisión: `PermiteTokenProgramado.cs:49-56`; reporte y formato atados: `:22-31`; empresa del claim = empresa de la sesión técnica: `ValidadorTokenServicio.cs:49`; `AccesoPermitido` y `SucursalAjena` en reportes: `ProveedorContexto.cs:74,78` |
| A02 Criptografía | Correcto | 256 bits de `RandomNumberGenerator`: `RegistroSesionesTecnicas.cs:340`; solo se guarda SHA-256: `:344,363` |
| A03 Inyección | No aplica | No hay consultas dinámicas nuevas; las lecturas son LINQ por clave (`AccesoAutor.cs:45-51`) |
| A04 Diseño inseguro | Correcto | Vida de 5 min sin tolerancia, revocación al desechar, sesión técnica aparte de la interactiva, sin caché en ninguna de las dos API |
| A05 Configuración | Correcto | Sin el validador registrado, todo `gpos-prg.` se rechaza: `ValidadorTokenPrincipal.cs:41-42`; el emisor de A reemplaza al ausente de B: `EmisorTokenServicio.cs:190-197` |
| A06 Componentes vulnerables | No aplica | El PR no cambia paquetes |
| A07 Identificación y autenticación | Correcto | Comprobaciones de cuenta compartidas con el JWT (`RevocacionSesiones.cs:180-195`); el SUPER denegado al emitir y al validar (`AccesoAutor.cs:73`, `ValidadorTokenServicio.cs:51`) |
| A08 Integridad | Correcto | El claim `prg` solo lo pone la principal; ningún JWT lo lleva (`Seguridad/Seguridad.cs:121-136`, `AutenticacionDispositivo.cs:74-83`) |
| A09 Registro y monitoreo | Correcto con observación (S217-01) | 4791-4793 sin el valor del token: `EmisorTokenServicio.cs:153-178`, `ValidadorTokenServicio.cs:73-78`; prueba 12 |
| A10 SSRF | No aplica | No hay peticiones salientes nuevas a destinos variables |

## 4. Verificación por punto pedido

### 4.1 Emisión (para quién y en qué orden)
- **Verificado.** Orden de `ReglasAccesoAutor.MotivoDenegacion` (`AccesoAutor.cs:62-75`): cuenta inexistente → inhabilitada → sello de habilitación distinto de `Valido` o sin sello de seguridad → empresa inexistente o inhabilitada → `DebeCambiarClave` → SUPER. Todos los casos devuelven un motivo; ninguno deja pasar. El SUPER se deniega aunque tenga además el cambio de contraseña pendiente (en ese caso el motivo informado es «cambio de clave», lo que solo afecta al texto).
- **Verificado.** Sin empresa o sin autor no hay token (`EmisorTokenServicio.cs:136-139`). El autor es `regla.UsuarioModificacion`, que solo lo pone el servidor desde la sesión de quien guarda la regla (`src/GPOS.Core/Servicios/Correo/NotificacionesService.cs:338`). El trabajo nunca lo pide a nombre de `SISTEMA` (`TrabajoNotificaciones.cs:182`).
- **Verificado. Falla cerrada:** cualquier excepción de la lectura (salvo una cancelación pedida) termina en `TokenServicioNoDisponibleException`, sin token (`EmisorTokenServicio.cs:142-159`); prueba 10.
- **TOCTOU entre la lectura y la creación:** existe (tres lecturas no atómicas en `AccesoAutor.cs:45-51` y luego `Crear`), pero no se puede explotar. La introspección vuelve a leer la cuenta en vivo en cada uso (`ValidadorTokenServicio.cs:43`), sin caché en la principal y sin caché en la API de reportes (`VerificadorIntrospeccion.cs:106-115`). Una inhabilitación ocurrida en esa ventana surte efecto en la primera petición.
- **Observación:** S217-03 (la membresía de la empresa).

### 4.2 El token
- **Entropía:** 32 bytes de un generador criptográfico (CSPRNG) en Base64Url; `sid` de 16 bytes aparte (`RegistroSesionesTecnicas.cs:340-341`). Verificado.
- **Almacenamiento:** solo la SHA-256 del valor. `ToString` no expone ni la huella ni el sello (`:292`); el valor en claro vive únicamente en `TokenServicio._valor` (`IEmisorTokenServicio.cs:30`), y `ToString` tampoco lo muestra (`:79`). Verificado.
- **Comparación:** la búsqueda se hace por la SHA-256 en un diccionario (`:351-352`). Con un secreto de 256 bits, una diferencia de tiempo al comparar huellas no da información útil (habría que encontrar una preimagen). No hace falta una comparación en tiempo constante. El `sid` no es una credencial: nada se busca por él.
- **Vida y revocación:** 300 s exactos con el reloj inyectado (`:308,343-344`); `Revocar` es idempotente y la entrada se conserva hasta vencer, para que un reuso dé `revocada` (`:355`). El trabajo lo desecha con `await using` antes de encolar el correo (`TrabajoNotificaciones.cs:128`). Un reinicio revoca todo (memoria). Verificado; pruebas 1, 7 y 9.
- **Colisión:** `TryAdd` falla y lanza `InvalidOperationException` (`:345`). La probabilidad es despreciable (2^-256). Ver S217-04.
- **Agotamiento:** tope de 1 000 vivas con purga bajo un `lock` (`:332-339`). Solo el trabajo emite, una regla tras otra; un atacante no puede crear sesiones técnicas. Los valores desconocidos no insertan nada ni leen la base (`ValidadorTokenServicio.cs:41`; prueba 9). Verificado.

### 4.3 Introspección
- **Qué devuelve:** usuario, nombre, nivel vigente, empresa, `sid` técnico, `iat`, `sst`, `cambiar_clave=0`, `amr=prg`, `prg` (regla), `prg_rpt` (reporte) y la sucursal si la cuenta está restringida (`ValidadorTokenServicio.cs:54-71`). Es el mismo conjunto de datos que ya lleva un JWT de sesión. Solo lo recibe el cliente de la canalización con ACL (sin cambios en este PR).
- **Otras rutas, reportes o formatos:** la ruta está cerrada por omisión. Solo la abre la exportación marcada, con `id` igual a `prg_rpt` único y el formato en `pdf|xlsx|csv` (`PermiteTokenProgramado.cs:22-31,49-56`; `EndpointsReportes.cs:96`). El enrutamiento corre antes de la autenticación en el `Program` real (prueba `En_el_programa_real_...`). La exportación tampoco existe por HTTP fuera del canal interno (`EndpointsReportes.cs:72`). El token no sirve en la API principal (prueba `La_API_principal_rechaza_el_token_de_servicio_con_401`).
- **Otra empresa:** la empresa del claim sale de la sesión técnica y se valida contra la base (`ValidadorTokenServicio.cs:43,49`); la API de reportes elige la base por ese claim. No hay forma de cambiarla desde el cliente.
- **Otra regla:** la API de reportes no usa `prg` para autorizar, solo `prg_rpt`. Es lo esperado por F-3: la regla solo sirve para la correlación.
- **Interactivo que se hace pasar por programado, o al revés:** el claim `prg` lo pone solamente `ValidadorTokenServicio`. Los JWT de usuario y de dispositivo se arman con listas cerradas que no lo incluyen (`Seguridad.cs:121-136`, `AutenticacionDispositivo.cs:74-83`) y van firmados. La rama JWT copia todos los claims del JWT (`ValidadorTokenPrincipal.cs:57`), pero un JWT válido no puede traer `prg` sin la clave de firma. Al revés: un `gpos-prg.` nunca entra en la rama JWT (`:41`). La API de reportes aplica la restricción de ruta por el valor **o** por la marca (`PermiteTokenProgramado.cs:51`). Verificado.
- **Observación:** S217-01.

### 4.4 Revocación por `iat` y cambios del autor después de emitido
- `EvaluarCuenta` aplica, en vivo y en cada uso, lo siguiente: cuenta inexistente, inhabilitada, sello de habilitación, nivel emitido mayor que el vigente, revocación con `iat` truncado al segundo y `sst` (`RevocacionSesiones.cs:180-195`). Después se comprueban la empresa, el cambio de contraseña y el SUPER (`ValidadorTokenServicio.cs:47-51`). Las pruebas 6 y 11 cubren todos estos casos, salvo el ascenso de nivel (S217-02).
- En la API de reportes, el token programado sigue sujeto a la inhabilitación, a la revocación por `iat` (sin `iat` se rechaza), a `AccesoPermitido`, al nivel efectivo y a `SucursalAjena` (`ProveedorContexto.cs:92-99,74-78`).
- Una revocación en el mismo segundo de la emisión no invalida el token (`emitido < truncado`). Es la misma semántica del JWT (`UsuariosService.TokenRevocado`); no es nueva.

### 4.5 Fuga de información
- 4791, 4792 y 4793 registran el `sid` técnico, la regla, el reporte, la empresa, el autor y el motivo; nunca el valor del token (verificado en el código y en la prueba 12). El mensaje que queda en el resultado de la regla solo lleva el código del usuario (`AccesoAutor.cs:80-94`). 4792 adjunta la excepción de la base (`EmisorTokenServicio.cs:153`), que puede incluir el nombre del servidor o de la base, como el resto de los registros del producto. El registro va al visor de eventos, no a un cliente. No se considera hallazgo.
- El rechazo por ruta en la API de reportes registra el método y la ruta, sin el token (`AutenticacionIntrospeccion.cs:84-86`).

### 4.6 Fusión con modelo-ng
- `Evaluar` conserva el orden anterior: cuenta (ahora en `EvaluarCuenta`) → `SucursalAjena` → `sid` → `jti` (`RevocacionSesiones.cs:169-175`). La extracción no cambió ningún resultado del camino JWT; la prueba `EvaluarCuenta_es_la_parte_de_cuenta_de_Evaluar` compara las dos funciones caso por caso.
- `ProveedorContexto`: el atajo para el token programado (`:97`) solo omite la comparación del `sid` interactivo. TBS-04/`SucursalAjena` (`:78,113-114`) y `AccesoPermitido` (`:74`) siguen aplicándose también al token programado. La resolución del conflicto no dejó brechas.

### 4.7 Pruebas
- Las pruebas revisadas comprueban lo que su nombre declara. Destacan: la prueba 4, que cuenta las lecturas, los cierres y las anotaciones de la sesión interactiva; la 12, que busca la parte aleatoria del valor en todos los textos del registro; y la de la caché, que corre por la canalización real. Los huecos están en S217-04.

## 5. Hallazgos

### S217-01 (Baja): un valor `gpos-prg.` repetido o mal formado llega siempre a la principal y deja un Warning
- **Riesgo:** un proceso local (la API de reportes escucha en `localhost`) puede enviar muchas peticiones con `Authorization: Bearer gpos-prg.<cualquier cosa>`. Con F-2 ese valor no usa la caché, ni siquiera cuando ya fue rechazado (`VerificadorIntrospeccion.cs:106-115`). Cada petición hace un viaje por la canalización y deja un Warning 4793 «(desconocida)» en la principal (`ValidadorTokenServicio.cs:41,73-78`). `UseRateLimiter` va después de `UseAuthentication` (`src/GPOS.Reportes.Api/Program.cs:110-112`), así que ningún límite de ritmo frena esas peticiones. El impacto es saturar el registro y ocultar 4793 legítimos (los reusos reales). No se leen datos, no se accede a la base y no hay escalada de privilegios. Con JWT aleatorios distintos ya se podían forzar viajes, pero no generaban un Warning por petición.
- **Evidencia:** las líneas citadas. Verificado en el código; el volumen no se midió.
- **Remediación mínima (unas 0,5 h):**
  1. En `VerificadorIntrospeccion.ValidarAsync`, devolver `invalido` sin preguntar a la principal cuando `EsTokenServicio(token) && !TieneForma(token)`.
  2. En `ValidadorTokenServicio`, registrar el rechazo de un valor desconocido (`s is null`) en `Debug`, o agruparlo con un contador por minuto, y dejar el Warning 4793 para las sesiones técnicas conocidas (revocada, vencida, cambio de cuenta).

### S217-02 (Baja): el nivel del token es el vigente, no el menor
- **Riesgo:** `ValidadorTokenServicio.cs:47` pone en `nivel` el nivel **vigente** de la cuenta. `EvaluarCuenta` rechaza las bajadas de nivel, pero deja pasar las subidas (`RevocacionSesiones.cs:187`). Si al autor lo ascienden de USER a ADMIN durante los 5 minutos de vida del token, el resto de las peticiones de esa ejecución corre como ADMIN. En `ProveedorContexto` el nivel efectivo es el menor entre el claim y `rptsis`, que ya es ADMIN, así que el ascenso se aplica. Con el JWT, la regla firmada es «subir aplica al iniciar sesión» (`ProveedorContexto.cs:168`; `ProveedorContextoTests.cs:81`). El impacto es acotado: es el nivel real y legítimo del autor, la ventana dura 5 minutos y el pase a SUPER se rechaza (`:51`). Es una incoherencia de semántica, no una escalada sobre un tercero.
- **Remediación mínima (unos 15 min):** emitir el menor entre `s.Nivel` y `e.Cuenta.Nivel` (o directamente `s.Nivel`, porque las bajadas ya se rechazan) y añadir la prueba del ascenso. Si el propietario prefiere «el nivel real al ejecutar», basta con documentarlo como precisión de F-1.

### S217-03 (Baja): la emisión no comprueba la membresía del autor en la empresa
- **Riesgo:** `VerificadorAccesoAutorActual` solo comprueba que la empresa exista y esté habilitada (`AccesoAutor.cs:51-54,70`). No mira `AccesoEmpresa` ni la empresa asignada. No se puede explotar: la API de reportes rechaza con 403 cuando falta `AccesoPermitido` o cuando la sucursal es ajena (`ProveedorContexto.cs:74,78`), y el autor guardó la regla desde una sesión en esa empresa. Lo que falta es defensa en profundidad y un motivo claro: la regla falla con un 403 genérico en lugar de `autor-sin-acceso`, y se emite un token que nunca debió existir. El propio código lo deja para D1 (T1-5), según el comentario de `AccesoAutor.cs:24-26`.
- **Remediación mínima:** no se recomienda trabajo ahora. Cuando D1 sustituya `IVerificadorAccesoAutor`, incluir la membresía en `MotivoDenegacion` y en la introspección, y añadir el caso a la prueba 5. Registrarlo como dependencia de T1-5.

### S217-04 (Baja): huecos de prueba
- **Ascenso de nivel sin pasar a SUPER** después de emitido el token: ninguna prueba lo cubre. La prueba 6 solo baja el nivel (`TokenServicioTests.cs:254`) y la 11 sube a SUPER (`:334`). Es la prueba que fijaría la decisión de S217-02.
- **Valor `gpos-prg.` mal formado en la API de reportes:** `El_prefijo_decide_quien_es_token_de_servicio` comprueba el prefijo, pero no que un valor sin la forma correcta deje de llegar a la principal. La prueba se necesita si se aplica S217-01.
- **Colisión de huella:** lanza `InvalidOperationException` (`RegistroSesionesTecnicas.cs:345`) en lugar de `TokenServicioNoDisponibleException`, que es la excepción del contrato (`IEmisorTokenServicio.cs:13`). Con una probabilidad de 2^-256 no tiene impacto práctico. Conviene alinear el tipo de excepción, sin añadir prueba.

## 6. Controles bien implementados
- El valor es opaco, de 256 bits y no es un JWT. Nunca se valida en local; solo por introspección.
- Solo se guarda su huella SHA-256 y nunca aparece en registros ni en `ToString`.
- La sesión técnica `tec-` está separada de la interactiva: no la lee, no la cierra y no anota actividad (prueba 4 y prueba de API).
- Falla cerrada en todo el recorrido: si la base no responde no hay token; en la introspección se lanza la excepción y la API de reportes responde 503; sin emisor no hay programado; si se llega al tope no se emite.
- Sin caché en las dos API (F-2), así que la revocación y los cambios de la cuenta se aplican en la siguiente petición.
- La ruta está cerrada por omisión y atada al reporte y al formato, con el enrutamiento resuelto antes de la autenticación. Además, la exportación solo existe por el canal interno.
- Las comprobaciones de cuenta son una sola función compartida con el JWT (`EvaluarCuenta`), así que ninguno de los dos caminos acepta lo que el otro rechaza.
- El SUPER se deniega al emitir y al validar (P-1 (a)).
- El tope de 1 000 sesiones vivas, con purga, limita la memoria del registro.

## 7. Remediaciones priorizadas
1. S217-01: cortocircuito por la forma del valor en la API de reportes y registro de los desconocidos en `Debug` o agrupados (unas 0,5 h).
2. S217-02 y su prueba de S217-04: limitar el claim de nivel al de la emisión, o documentar la precisión (unos 15 min más la prueba).
3. S217-04, colisión: cambiar el tipo de excepción (5 min).
4. S217-03: con D1/T1-5, sin trabajo ahora.

Ninguna remediación cambia infraestructura ni tiene costo externo.

## 8. Recomendación técnica
**Aprobado con observaciones.** No hay hallazgos Críticos ni Altos, y los cuatro Bajos pueden resolverse en este PR o en uno siguiente. Es una recomendación técnica: la decisión de unir la rama es del propietario, a través de B.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr217-emisor-2026-10-23.md`
- Supuestos: los binarios de prueba usados (18:20-18:22) corresponden a HEAD `d618bdf4` (son posteriores al commit de 18:19 y el árbol no tenía cambios sin commit). La canalización de la introspección mantiene la ACL revisada antes (no cambia en este PR).
- Decisiones candidatas a ADR: precisión de F-1 sobre el nivel del token de servicio, «el menor entre la emisión y el vigente» o «el vigente» (S217-02).
- Entregas a otros agentes: desarrollador de A (autor de T4-04) → S217-01, S217-02 y S217-04; responsable de D1/T1-5 → membresía en `IVerificadorAccesoAutor` (S217-03).
- Próximo paso recomendado: aplicar S217-01 y S217-02 en el mismo PR (menos de 1 h) y pasarlo a B para la unión.
