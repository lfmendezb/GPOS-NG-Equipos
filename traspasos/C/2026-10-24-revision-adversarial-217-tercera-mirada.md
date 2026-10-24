Para: B        De: C        Fecha: 2026-10-24
Tipo: Revisión adversarial (tanda 8, punto 2: `avisos/B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`)
Prioridad: Alta
Repositorio y rama: GPOS-NG #217 (T4-04, emisor del token de servicio), ya unido: `origin/feature/modelo-ng` @ `1b310591` (cabeza de la rama `11a1e822`). Solo lectura.
Estado: Abierto

Convención: [V] lo comprobé leyendo el código con `git show` o `git grep` sobre `origin/feature/modelo-ng`; [I] es inferido. **No compilé ni corrí pruebas** (lo pedía el encargo). No cambié el checkout de `GPOS-NG` ni hice commits.

Antes de empezar leí lo que ya se revisó, para no repetirlo: `traspasos/A/revision-seguridad-pr217-emisor-2026-10-23.md` (S217-01 a S217-04), `avisos/B-a-A/2026-10-23-revision-independiente-217.md` (M-1, M-2, B-1 a B-3), `avisos/A-a-B/2026-10-23-217-m1-b1-b2-cerrados.md` y `avisos/B-a-A/2026-10-23-s217-02-h210-msi-y-f2-f3-firmados.md` (S217-02 firmada en (a)).

# Veredicto

**Aprobado con observaciones.** Es una recomendación técnica: la decisión es del propietario (C2).

- No hay hallazgos Críticos ni Altos. Los cierres de A (`9f6b2b1c` y `11a1e822`) son correctos en lo que declaran.
- Encontré **6 hallazgos Bajos y 1 informativo**. Ninguno lo vieron los dos auditores anteriores. Tres afectan a garantías que el código y los informes dan por cumplidas y que no se cumplen del todo:
  - **C217-01:** la paridad de sucursal de M-1 con la sesión interactiva.
  - **C217-02:** «sin caché» en la API de reportes.
  - **C217-03:** S217-01 «corregido».
- **S217-02 sigue abierto en el código:** está firmada en (a), pero `1b310591` aún pone el nivel vigente. Propongo que el PR de seguimiento de A cierre en el mismo cambio C217-01, que es el mismo principio aplicado a la sucursal.

| ID | Severidad | Título |
|---|---|---|
| C217-01 | Baja | M-1 no logra paridad con la sesión interactiva: la sesión técnica no guarda la sucursal de la emisión, así que un cambio de sucursal dentro de la misma empresa no invalida el token y el token sigue a la sucursal nueva |
| C217-02 | Baja | F-2 («sin caché») no se cumple en la API de reportes: para el programado, `AccesoPermitido`, los permisos y el nivel de `rptsis` se toman de una caché de 15 s |
| C217-03 | Baja | S217-01 quedó cerrado a medias: un valor `gpos-prg.` bien formado pero inventado sigue llegando a la principal y dejando un Warning 4793 por petición, sin límite de ritmo |
| C217-04 | Baja (pruebas) | El doble del emisor (#215) emite valores fuera del contrato (73 caracteres hexadecimales) que la API de reportes real rechazaría sin preguntar; la API simulada no lo nota |
| C217-05 | Baja (pruebas) | B-2 solo cubre con el emisor real los dos motivos que el doble ya reproducía; los motivos en que difieren, y el camino positivo con revocación real, no tienen prueba de integración |
| C217-06 | Baja (registro) | Eventos: el tope o la colisión no dejan 4792; 4792 mezcla la denegación de negocio con la falla de la base; el rechazo por ruta en la API de reportes no tiene EventId |
| C217-07 | Informativa | La comprobación de M-1 y el claim de sucursal salen de dos lecturas distintas de `dbo.Usuarios` |

# 1. Qué comprobé que está bien (para no repetirlo)

- **Orden de las comprobaciones** [V]:
  - Emisión (`AccesoAutor.cs:56-71`): inexistente → inhabilitada → sello de habilitación o falta de `sst` → empresa → cambio de clave → SUPER → `SucursalAjena`.
  - Introspección (`ValidadorTokenServicio.cs:29-42`): forma y registro → revocada → vencida (las tres sin tocar la base) → `EvaluarCuenta` → empresa → cambio de clave → SUPER → `SucursalAjena`.
  - Que M-1 vaya después del SUPER no deja ningún hueco: el SUPER nunca está `Restringida` (`UsuariosService.cs:1095`).
- **Reglas del autor** [V]:
  - Cambio de clave forzado: `DebeCambiarClave` en las dos partes.
  - Cambio de contraseña: `sst` renovado, `RevocacionSesiones.cs:193`.
  - Inhabilitación: `:188`.
  - Bajada de nivel: `:191`.
  - «Forzar nuevo inicio de sesión»: `:192`, por `iat`.
  - Subida a SUPER: `ValidadorTokenServicio.cs:40`.
  - Todo se evalúa en vivo. `UsuariosService.EstadoSesionAsync` no tiene caché (`UsuariosService.cs:810-829`) y `EmpresasService.BuscarAsync` tampoco (`EmpresasService.cs:199`).
- **Revocación y reuso:** la revocación se aplica al desechar el token, con `await using` antes de encolar el correo (`TrabajoNotificaciones.cs:131`). También se revoca si el token no es admisible (`:183-185`). La comprobación de `Revocada` en la principal no usa caché (`ValidadorTokenServicio.cs:30`). B-3, la reutilización durante los 5 min, sigue aceptada por diseño.
- **Vida del token:** 300 s desde la emisión truncada al segundo (`RegistroSesionesTecnicas.cs:114-115`). `Admisible` impide un `VenceUtc` mayor de 5 min (`TokenServicioProgramado.cs:19`).
- **Transporte:** solo por *loopback* y por la canalización, con verificación del servidor (`ReenvioReportes.cs:415-419`, `:322`). Las cabeceras se ocultan en el registro (`:427`).
- **Empresa del token:** sale de la sesión técnica (`ValidadorTokenServicio.cs:50`), sin forma de cambiarla desde el cliente.
- **B-1** [V]: la rama JWT rechaza `prg`, `prg_rpt` y `amr=prg` antes de leer la sesión (`ValidadorTokenPrincipal.cs:49-51`), y `EsProgramado` es estricto (`ProveedorContexto.cs:118-121`). La restricción de ruta usa la marca laxa (`PermiteTokenProgramado.cs:51`): es más restrictiva, así que también falla cerrada. Ningún otro consumidor de `prg` concede nada (busqué con `git grep` de `ClaimsSesion.Programado|EsProgramado(|ProgramadoReporte` en `src`).
- **M-1** [V]: es correcto para los tres casos que declara: restringida sin sucursal, empresa sin sucursal y sucursal de otra empresa.
- **EventIds** [V]:
  - 4791 a 4793 no chocan en ninguna rama remota (`git grep` en todas).
  - 4790 lo usan las dos impresiones con el mismo nombre (`ServicioImpresion.cs:18`, `ServicioRender.cs:19`), fuera de este PR.
  - 5128 y 5129 son de `TrabajoNotificaciones`.

# 2. Hallazgos

## C217-01 (Baja): M-1 no da paridad de sucursal con la sesión interactiva

- **Evidencia** [V]:
  - `ValidadorTokenServicio.cs:42` llama a `SucursalAjena(e.Cuenta, e.Cuenta.SucursalDefault, s.Empresa)`: compara la sucursal **vigente** con la sucursal **vigente**, así que la mitad de sucursal de `MismaSucursal` siempre es cierta.
  - La interactiva compara con la sucursal **del token** (`RevocacionSesiones.cs:172`).
  - `SesionTecnica` no guarda sucursal (`RegistroSesionesTecnicas.cs:18-31`).
  - El claim de sucursal se arma con la lectura vigente (`ValidadorTokenServicio.cs:60`).
- **Efecto:**
  - Si el ADMIN cambia la sucursal de una cuenta restringida de S1 a S2 dentro de la misma empresa mientras el token está vivo, el JWT interactivo recibe 401 «credenciales» (comportamiento de TA-P08).
  - El token de servicio, en cambio, sigue valiendo y ejecuta el resto de la corrida sobre S2.
  - El comentario de `:41` («como la interactiva») y la prueba `M1_la_cuenta_restringida_…_si_la_pierde_deja_de_valer` (`TokenServicioTests.cs:410`) solo cubren perder la sucursal o cambiar de empresa, no el cambio dentro de la misma empresa.
- **Riesgo:** no hay escalada. S2 es el alcance vigente y legítimo del autor, y la API de reportes manda con `rptsis` para el restringido (`ProveedorContexto.cs:124-131`). Es la misma incoherencia de semántica que S217-02 («lo vigente» en lugar de «lo emitido»): el propietario la resolvió para el nivel con (a), pero la decisión no alcanza a la sucursal.
- **Remediación (unos 20 min y 1 prueba):**
  1. Guardar `estado.Sucursal` en `SesionTecnica` al emitir.
  2. En la introspección, usar `SucursalAjena(e.Cuenta, s.Sucursal, s.Empresa)`.
  3. Emitir el claim de sucursal desde `s.Sucursal`.
  4. Añadir la prueba del cambio S1 → S2 en la misma empresa (que dé `revocada`).

  Así quedan cubiertos con paridad exacta los tres casos: cambio lateral, restricción añadida después (sin sucursal en la emisión, rechazada) y pérdida de la sucursal. Propongo que vaya en el mismo PR de S217-02, como precisión de F-1 o ADR candidata (ver el Cierre).

## C217-02 (Baja): F-2 («sin caché») no se cumple en la API de reportes

- **Evidencia** [V]:
  - `VerificadorIntrospeccion.cs:104-105` afirma: «al revocarlo (o al perder el autor su acceso) deja de valer en la siguiente petición, no 15 s después». A también escribió «sin caché en ninguna API» (aviso A-a-B del #217), y el informe de A dice lo mismo en su §6.
  - Es cierto para la introspección. Pero `ProveedorContexto.ObtenerAsync` lee el paquete `rptsis` con caché de 15 s por (usuario, empresa) también para el programado (`ProveedorContexto.cs:64` y `:135-148`; `forzar` solo se activa en la relectura T2-08, que no aplica al programado).
  - De ese paquete salen tres cosas: `AccesoPermitido` (`:74`), los permisos (`:79`) y el nivel de `rptsis` para el nivel efectivo (`:76`).
- **Efecto:**
  - La principal **no** comprueba la membresía (S217-03). Por eso, si al autor le quitan el acceso a la empresa o un permiso de reporte, el token programado sigue valiendo hasta 15 s.
  - Con M-1, la restricción de sucursal ya se comprueba en vivo en la principal, así que esa parte quedó cubierta. El resto no.
- **Riesgo:** ventana de 15 s, la misma que la sesión interactiva. No es explotable por un tercero. Lo que falla es una garantía escrita, que los dos auditores dieron por buena.
- **Remediación (5 min):** en `ObtenerAsync`, llamar `PaqueteAsync(codigo, empresa, forzar: EsProgramado(usuario), ct)`. Cuesta 1 o 2 lecturas de `rptsis` por ejecución programada; una petición interactiva no puede forzarla, porque `EsProgramado` es estricto y solo lo cumple un token que validó la principal. Alternativa más barata: corregir el texto de F-2 y del comentario a «la introspección sin caché; el paquete de `rptsis`, 15 s». La descarto porque deja el hueco de membresía hasta D1.

## C217-03 (Baja): S217-01 quedó cerrado a medias

- **Evidencia** [V]:
  - `9f6b2b1c` solo rechaza en la API de reportes los valores **mal formados** (`VerificadorIntrospeccion.cs:109`).
  - Un valor inventado con la forma exacta (prefijo más 43 caracteres Base64Url, `TokenProgramado.cs:33-39`) pasa ese filtro y llega a la principal. Esta no lo encuentra en el registro (`ValidadorTokenServicio.cs:29`) y deja un `LogWarning` 4793 «(desconocida)» por petición (`:67`).
  - `UseRateLimiter` sigue después de `UseAuthentication` (`src/GPOS.Reportes.Api/Program.cs:110-112`).
  - La remediación 2 del auditor de A (registrar los desconocidos en `Debug` o agrupados) no se aplicó, y el aviso de A lo da por «corregido».
- **Riesgo:** para inundar el registro y tapar los 4793 legítimos hay que hacer lo mismo que antes, solo que con un valor de la forma correcta. No da acceso a datos ni lecturas de la base.
- **Remediación (unos 30 min):**
  - En `ValidadorTokenServicio.Rechazar` con `s is null`, bajar el registro a `Debug`, o contarlo y emitir un solo Warning por minuto con la cantidad.
  - Mantener el 4793 Warning solo para sesiones técnicas conocidas (revocada, vencida o cambio de cuenta), que son la señal real de reuso.

## C217-04 (Baja, pruebas): el doble del emisor emite valores fuera del contrato

- **Evidencia** [V]:
  - `EmisorTokenServicioPrueba` arma `TokenServicio.Prefijo + Convert.ToHexString(32 bytes)`, es decir, 9 + 64 = 73 caracteres (`NotificacionesReportesTests.cs:80`). `TokenProgramado.Largo` es 52, así que `TieneForma` da false.
  - Desde `9f6b2b1c`, la API de reportes real rechaza ese valor sin preguntar a la principal (`VerificadorIntrospeccion.cs:109`).
  - La API simulada (`ApiReportesSimulada`, `NotificacionesReportesTests.cs:178-202`) no valida el token. Las pruebas del camino feliz afirman que se envió `"Bearer " + UltimoValor` (`:423`, `:847`), que es un valor que el sistema real nunca aceptaría.
  - El constructor de `TokenServicio` solo valida el prefijo (`IEmisorTokenServicio.cs:40`). `ContratoTokenServicioTests.cs:13` también usa un valor de 65 caracteres.
- **Riesgo:** ninguno en producción. Lo que falla es la fidelidad de las pruebas: si el formato del emisor real cambiara, ninguna prueba de integración de las notificaciones lo notaría. La cadena hoy solo está cubierta por piezas: el emisor da la forma (`TokenServicioTests.cs:370-376`) y la forma se acepta (`VerificadorIntrospeccionTests`).
- **Remediación (10 min):**
  1. El doble emite `Prefijo + Base64Url(32 bytes)`.
  2. `ApiReportesSimulada` afirma `TokenProgramado.TieneForma` sobre el `Authorization` que recibe cuando el valor empieza por `gpos-prg.`.
  3. Opcional: el constructor de `TokenServicio` exige `TieneForma` (hay que ajustar `ContratoTokenServicioTests`).

## C217-05 (Baja, pruebas): B-2 cubre lo que el doble ya cubría

- **Evidencia** [V]:
  - Las dos pruebas con el emisor real (`NotificacionesReportesTests.cs:940` y `:976`) son la del SUPER y la del inhabilitado. Son justo los dos motivos que el doble ya reproducía (`:106-112`).
  - Los motivos en que el doble y el real difieren no tienen ninguna prueba de integración con el emisor real y `VerificadorAccesoAutorActual` contra `GPOS_SYSDATA`. El propio doble lo declara (`:33-37`). Son:
    - sello de habilitación inválido o falta de `sst`;
    - empresa inhabilitada;
    - `AutorCambioClave`;
    - M-1, que depende de que `ConsultaEstadoSesion` traiga `RestringirSucursal`, `EmpresaDefault` y `SucursalDefault`.
  - Tampoco hay un camino positivo con el emisor real, es decir, una regla de un ADMIN que llegue a la API simulada con un valor de forma válida, termine con `registro.Vivas == 0` y cuyo valor, presentado después a `ValidadorTokenServicio`, dé `revocada`. Esa sería la prueba de reuso de punta a punta.
  - Hay dos aserciones débiles:
    - `Assert.Equal(revocadas, api.Tokens.Revocaciones.Count)` (`:958`, `:994`) es tautológica con el delegado: el doble no anota revocaciones cuando delega.
    - `registro.Vivas == 0` en un camino de denegación solo detecta que el token se haya creado antes de decidir. Es útil, pero no prueba la revocación.
- **Remediación (unos 0,5 dp):**
  - Añadir con el emisor real los casos de cambio de clave y de cuenta restringida sin sucursal, más el positivo con reuso tras el envío.
  - Quitar la aserción tautológica o cambiarla por una sobre el registro real.

## C217-06 (Baja, registro): huecos en los eventos

- **Evidencia** [V]:
  - Tope de sesiones o colisión: `registro.Crear` lanza `TokenServicioNoDisponibleException` desde `EmisorTokenServicio.cs:61`, fuera del `try`, así que no queda 4792. Solo queda el 5129 genérico del llamador (`TrabajoNotificaciones.cs`, `EventoTokenNoDisponible`). Que se llegue al tope de 1.000 es justo la señal de una fuga de sesiones o de un abuso, y hoy no se distingue.
  - 4792 cubre dos cosas distintas: la denegación de negocio (`:75`) y la base que no responde (`:52`, con la excepción). Un monitor no puede alertar solo por infraestructura.
  - El rechazo de un token de servicio en una ruta que no lo admite (`AutenticacionIntrospeccion.cs:84`) es un `LogWarning` sin EventId: la señal más directa de reuso fuera de su ruta queda con el evento 0.
- **Remediación (unos 30 min):**
  - Registrar 4792, o un 4794 nuevo de la franja libre, cuando se llega al tope.
  - Separar «no disponible» de «denegado» con un EventId propio.
  - Darle un EventId al rechazo por ruta en la API de reportes.
  - Comprobar la franja con `git grep` en todas las ramas, como hizo A.

## C217-07 (Informativa): dos lecturas para la misma decisión

- **Evidencia** [V]:
  - `VerificadorAccesoAutorActual.LeerAsync` lee la cuenta con `EstadoSesionAsync`, que trae `RestringirSucursal`, `SucursalDefault` y `EmpresaDefault` (`AccesoAutor.cs:39`).
  - Después vuelve a leer `RestringirSucursal` y `SucursalDefault` con EF para armar `Sucursal` (`:41-46`).
  - M-1 decide con la primera lectura (`:70`, `ValidadorTokenServicio.cs:42`) y el claim sale de la segunda (`:60`).
- **Impacto:** nulo hoy [I]. Un cambio entre las dos lecturas solo mezcla estados vigentes, y la API de reportes usa `rptsis` para el restringido. Aun así, es fuente doble de la misma verdad.
- **Remedio:** derivar `Sucursal` de `cuenta` (`Restringida ? SucursalDefault : null`) y quitar las dos columnas de la segunda consulta. Encaja con C217-01.

# 3. Nivel del token (S217-02): estado y nota para el PR de A

- **Estado** [V]: firmada en (a) el 2026-10-23, pero **no implementada** en `1b310591`. `ValidadorTokenServicio.cs:49` sigue emitiendo `e.Cuenta.Nivel`. No existe ninguna rama remota de seguimiento (revisé `git branch -r`).
- **Nota para la implementación:**
  - Como `EvaluarCuenta` ya rechaza las bajadas (`RevocacionSesiones.cs:191`), «el menor entre emisión y vigente» es exactamente `s.Nivel`; no hace falta calcular un mínimo.
  - La prueba que falta (S217-04): de USER a ADMIN después de emitir, el claim debe seguir siendo USER, y en la API de reportes `NivelEfectivo(USER, ADMIN)` debe dar USER (`ProveedorContexto.cs:173-174`).
  - Conviene que el mismo PR cierre C217-01 y C217-07, que aplican el mismo principio a la sucursal.

# 4. Lo que no verifiqué

- No compilé ni corrí pruebas: las cifras de pruebas son las de A (822/822 y 92/92) y las de B. Tampoco medí el volumen de C217-03.
- No revisé `ConsultaEstadoSesion` por dentro (que traiga `EmpresaDefault` lo doy por hecho por el constructor de `UsuariosService.cs:827-828`).
- No leí `LeerPaqueteAsync` de `rptsis` (cómo se calcula `AccesoPermitido`).
- No probé ningún envío programado real.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-217-tercera-mirada.md`
- Supuestos: `origin/feature/modelo-ng` @ `1b310591` es lo unido del #217 (cabeza `11a1e822`), sin cambios posteriores en estos archivos.
- Decisiones candidatas a ADR: precisión de F-1 que extiende S217-02 (a) a la sucursal: el token de servicio conserva la sucursal de la emisión y un cambio la invalida, como el JWT (C217-01). Precisión de F-2: lo que abarca «sin caché» (C217-02).
- Entregas a otros agentes: A (autor de T4-04) → C217-01, C217-02, C217-07 junto con S217-02 en el PR de seguimiento; C217-03 y C217-06 (registro); C217-04 y C217-05 (pruebas). Responsable de D1/T1-5 → nada nuevo (S217-03 sigue igual).
- Próximo paso recomendado: que B le pida a A un único PR de seguimiento con S217-02, C217-01 y C217-02 (menos de 1 dp con pruebas), y que lleve C217-03 a C217-06 como seguimientos de baja prioridad.
