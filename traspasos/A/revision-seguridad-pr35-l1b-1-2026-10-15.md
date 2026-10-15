# Informe de Seguridad: PR #35, L1b-1 (clase de operación, sustituto y corroboración de la hora)

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #35, rama `a/lic-l1b-1` @ `8a4e86ee` (worktree `GPOS-NG-l1b`), comparada con `origin/feature/modelo-ng`. Son 17 archivos y +730 líneas.

**Referencias:** `[LIC]` 4.3, 4.5, 5.1 y 5.5; blueprint de la licencia v2.8 (§4.1 fila L1b, §5.3, §6.1 y §6.2); H-16 v2.1; DL-17; mis informes previos (RA-01, PA-*).

**Método:** no compilé ni ejecuté pruebas. Las cifras que menciono (106 pruebas nuevas; 376 de licencia con 1 omitida en Debug y en Release; arquitectura 181/181) son las que declara el PR y no las reproduje.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Contrato y regla pura de la primera barrera | `src/GPOS.Core/Sistema/Licencia/IEstadoLicencia.cs` |
| Marca de ruta y su resolución | `src/GPOS.Api/Seguridad/ClaseLicencia.cs` |
| Rutas relajadas | `tests/GPOS.Tests/Licencia/RutasLicenciaAprobadas.json` y las marcas en `src/GPOS.Api/Endpoints/*.cs` |
| Sin interruptores (QA-L06 y QA-L17) | `tests/GPOS.Tests/Arquitectura/LicenciaSinInterruptoresTests.cs` |
| Corroboración de la hora | `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs` |

`UseLicencia` y el registro en el contenedor de dependencias **no** forman parte de este PR. Los hallazgos LB-01 y LB-02 son condiciones para cuando se cableen.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| LB-01 | **Media** | `EstadoLicenciaHeredado` es público y nada impide registrarlo en una compilación que se distribuya: anularía la licencia entera |
| LB-02 | **Media** (diseño) | Corroborar la hora con `emitida` vuelve a abrir el techo deslizante de RA-01, que DL-17 cerró, a través del reloj protegido |
| LB-03 | Baja | `POST /importaciones/{tipo}/validar` como `Consulta` ejecuta las mismas escrituras dentro de una transacción que se revierte |
| LB-04 | Baja | Las rutas `Preparacion` con `{codigo}` actúan sobre otra empresa: `UseLicencia` tiene que evaluar la empresa destino |
| LB-05 | Baja | No hay ninguna guarda que vigile «GET sin efecto» en el valor por omisión `Consulta` |
| LB-06 | Informativa | Observaciones sobre `respaldos`, `notificaciones/documento` y `espejo/sincronizar` |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Bien**, con LB-03 y LB-04: la regla falla cerrada, la marca es explícita, la lista aprobada está versionada y el valor por omisión es `Operativa` para todo lo que no es GET/HEAD |
| A02 Criptografía | **No aplica** |
| A03 Inyección | **No aplica** |
| A04 Diseño inseguro | **Hallazgos** LB-01 y LB-02 |
| A05 Configuración | **Bien:** no hay interruptores (QA-L06), con la salvedad del registro de LB-01 |
| A06 Componentes | **No aplica** |
| A07 Autenticación | **No aplica** (las rutas anónimas no se evalúan, igual que con el esquema pendiente) |
| A08 Integridad | **Hallazgo** LB-02 |
| A09 Registro y monitoreo | **Bien:** `RelojCorroborado` queda en el registro |
| A10 SSRF | **No aplica** |

---

## 4. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| `ReglaClaseLicencia.Permite` | Verificada. `Consulta` y `Esencial`: siempre. `Operativa`: solo si la empresa opera (`Vigente`, `PorVencer` o `EnGracia`), **también para el SUPER**. `Preparacion`: si opera, o si la empresa es `NoLicenciada` y el usuario es el SUPER. Una clase desconocida da `false` | `IEstadoLicencia.cs:65-83` |
| Valor por omisión sin marca | La marca explícita manda. Sin marca, `GET`/`HEAD` son `Consulta` y todo lo demás es `Operativa`. Una ruta nueva olvidada queda bloqueada, nunca abierta | `ClaseLicencia.cs:148-154` |
| GET con efecto que quede como `Consulta` | **No encontré ninguno** con una búsqueda heurística sobre los 149 mapeos (handlers de `MapGet` que llamen a métodos de escritura). `GET …/desde/{origen}/{numero}` (`CrearDesdeAsync`) arma un borrador en memoria (inferido de la lectura: no confirma nada). No es una verificación exhaustiva: LB-05 | `DocumentosEndpoints.cs:121-122` |
| Las 24 rutas relajadas | Revisadas una por una. **Ninguna escritura de negocio** (ventas, compras, cobros, inventario, toma de números) pasa como `Consulta` o `Esencial`. Las `Esencial` coinciden con `[LIC]` 4.3 (sesión, cierres X y Z, soporte del SUPER), salvo `respaldos`, que está pendiente del arquitecto (LB-06). Las 12 `Consulta` son lecturas por POST, vistas previas, reimpresión y validación (ver LB-03 sobre la validación). Las tres excepciones legales de LV-12 siguen en `Operativa` (R-B2) | `RutasLicenciaAprobadas.json`; marcas en `*Endpoints.cs` |
| QA-L06 / QA-L17 | Correctas: leen el IL y el texto de los tipos de la licencia y de la marca, y corren sobre Release. **No cubren el registro en el contenedor de dependencias** (`Program.cs`), que es donde un interruptor tendría efecto: LB-01 | `LicenciaSinInterruptoresTests.cs` |
| `EstadoLicenciaHeredado` | Todo `Vigente`, `ExigirOperativa` no hace nada y el cupo sale de la fila editable `UsuariosAutorizados`: LB-01 | `IEstadoLicencia.cs:92-118` |
| `Corroborar` | Solo sube la hora: lleva la hora más alta a mín(reloj del sistema, hora confiable + 5 min), nunca la baja y no resuelve un retroceso. Con una `emitida` firmada, nadie sin la llave de GSF la puede adelantar. **Pero** ver LB-02 | `RelojProtegido.cs:243-271` |

---

## 5. Hallazgos

### LB-01 · Media · El sustituto `EstadoLicenciaHeredado` puede acabar registrado en producción

- **Riesgo:** si el sustituto queda registrado como `IEstadoLicencia` en una compilación que se distribuye, la licencia deja de existir en la práctica:
  - `Permite` siempre permite, porque el estado es siempre `Vigente`;
  - la segunda barrera (`ExigirOperativa`) no hace nada;
  - el cupo del sello sale de `UsuariosAutorizados`, una fila que cualquiera con acceso a la base puede editar (justo lo que LV-17 elimina).
  
  El PR propone que SL lo use en su propio registro «si el coordinador lo acuerda». Una vez en `Program.cs`, nada lo detecta: QA-L06 mira el código de los tipos, no qué implementación queda registrada. Hoy no está registrado en ninguna parte (verificado), así que es un riesgo latente.
- **Evidencia:** `IEstadoLicencia.cs:92-118`; la descripción del PR (sección «Sin registrar en DI»).
- **Remediación (≈ 0,05 dp):**
  1. Una prueba de arquitectura o de integración que resuelva `IEstadoLicencia` desde el host real de la API y falle si es `EstadoLicenciaHeredado` (o cualquier otro que no sea el servicio de L1a-4), al menos sobre Release.
  2. Mientras exista, marcar el tipo como `[Obsolete("Sustituto de L1b; no se registra en la API", error: true)]` fuera de las pruebas, o compilarlo solo en Debug.
  3. Borrarlo en el mismo PR que registre `EstadoLicenciaService`.

### LB-02 · Media (diseño) · Corroborar con `emitida` reabre el techo deslizante que cerró DL-17

- **Riesgo:** DL-17 midió el techo de 48 h de INV-6 solo sobre la hora protegida para que «una carga aceptada no suba el techo de la siguiente» (RA-01). `Corroborar(emitida)` sube la hora protegida hasta mín(reloj del sistema, `emitida` + 5 min). Quien tenga la llave básica `s1` (o archivos firmados con ella) **y** sea administrador del servidor puede repetir este ciclo:
  1. adelantar el reloj del sistema unas 47 h;
  2. cargar una licencia con `emitida` ≈ +47 h (cabe bajo el techo vigente);
  3. corroborar con esa `emitida`, lo que deja la hora protegida en ≈ +47 h;
  4. el siguiente techo queda en ≈ +95 h, y se repite.
  
  Así vuelve el escenario de RA-01: el tope de DL-14 se estira con cada carga en un cliente que no actualiza, donde INV-1 no frena por no haber relevo. La regla de los saltos de más de 48 h de H-16 no lo impide, porque el salto queda «corroborado» por la propia licencia falsificada. Es un hueco de diseño entre H-16 v2.1 (que nombra `emitida` como fuente confiable) y DL-17, y el código de este PR cumple ambos textos. El cableado (quién llama a `Corroborar` y con qué) llega con L1b, así que conviene decidirlo ahora. Probabilidad baja: exige la llave básica y administrador.
- **Evidencia:** `RelojProtegido.cs:243-266`; `FuentesHoraConfiable.Emitida`; `ReglasAceptacion.HoraReferencia(ahora)` (DL-17).
- **Remediación (≈ 0,1 dp más una precisión de H-16/DL-17 para el arquitecto). Opciones, de más simple a más fina:**
  1. **Recomendada:** que la corroboración por `emitida` solo valga para licencias **con firma Avanzada propia**; la cabecera `Date` del agente (L4) sigue valiendo siempre. Con `s1` comprometida no hay corroboración.
  2. Que el techo de INV-6 use una hora protegida **sin** los avances corroborados por `emitida` (un valor aparte en el reloj). Cumple DL-17 al pie de la letra.
  3. Cada corroboración por `emitida` solo puede subir la hora hasta `emitida` de una licencia aceptada cuando la hora protegida ya era ≥ `emitida` − 48 h, sin encadenar. Es más compleja.
  
  Prueba de QA: tres cargas con `emitida` creciente en 47 h y el reloj adelantado; la tercera tiene que dar `LICENCIA_FECHA_FUTURA`.

### LB-03 · Baja · «Validar una importación» como `Consulta` ejecuta escrituras que luego revierte

`ProcesarAsync(…, guardar: false)` ejecuta las escrituras masivas (paso por tabla intermedia, `MERGE`, bitácora) y también `AntesDeConfirmar` (el adelanto del contador K-2) dentro de la transacción, que después **no se confirma**. Con la licencia en solo consulta, esto se permite. No queda ningún cambio de datos, salvo los efectos que no siguen la transacción (un `SEQUENCE`, huecos de identidad o cualquier llamada externa futura), y la carga y los bloqueos de una importación grande sí ocurren.
- **Evidencia:** `ImportacionesEndpoints.cs:33-39`; `ImportacionesService.cs:151-200`.
- **Remediación:** como validar solo sirve antes de importar (que es `Operativa`), dejar `validar` en `Operativa` al menos para los tipos que generan documentos (facturas históricas, existencias iniciales y CxP pendientes), o comprobar y documentar que ninguna escritura de la validación queda fuera de la transacción.

### LB-04 · Baja · `Preparacion` sobre la empresa destino

`POST /api/admin/empresas/{codigo}/esquema` (y el alta) actúan sobre una empresa que puede no ser la del token. Si `UseLicencia` evalúa la empresa **del token**, un ADMIN de una empresa que opera recibe `Preparacion` permitida y prepara una empresa `NoLicenciada`, cuando LV-16 lo reserva al SUPER. A la inversa, el SUPER no puede dar de alta una empresa estando en una en solo consulta. Hoy la seguridad depende de los permisos de la ruta (`RequiereSuper` o el grupo de administración).
- **Remediación (L1b, `UseLicencia`):** para las rutas `Preparacion` con `{codigo}`, evaluar la empresa destino; para el alta (sin destino), exigir el SUPER explícitamente.

### LB-05 · Baja · Ninguna guarda vigila «GET sin efecto»

El valor por omisión (`GET` = `Consulta`) es correcto y no encontré ningún GET con escrituras (ver el punto 4), pero nada impide que mañana se agregue uno, que quedaría permitido en solo consulta.
- **Remediación (≈ 0,05 dp):** una prueba de arquitectura que falle si el handler de un `MapGet` llama a métodos de escritura conocidos (`Guardar*`, `Registrar*`, `Anular*`, `Tomar*`, `SaveChanges`…), o que exija una marca explícita en todo GET de los módulos que escriben.

### LB-06 · Informativa

- `POST /api/admin/respaldos` como `Esencial`: aceptable (conserva la información). Tiene que mantener su límite de peticiones para no convertirse en una vía de llenar el disco. El arquitecto lo confirma.
- `POST /api/notificaciones/documento` como `Consulta`: equivale a exportar, pero envía correo hacia fuera. Que conserve el límite de peticiones y solo acepte documentos emitidos.
- `POST /api/admin/numeracion/espejo/sincronizar` como `Esencial` (solo el SUPER): conviene confirmar que no consume números (el espejo `_CNumeracion` es una copia).

---

## 6. Controles bien implementados

- **Regla pura que falla cerrada,** incluido el SUPER en `Operativa`.
- **Marca de ruta con prioridad** sobre el valor por omisión, y **lista aprobada versionada** con el motivo de cada relajación, tratada como un cambio de seguridad.
- **Las excepciones legales de LV-12** siguen en `Operativa` hasta AI-07.
- **QA-L06 por IL y por texto**, también sobre Release.
- **`Corroborar` solo sube**, acotado por el reloj del sistema, y no toca la inconsistencia por retroceso.

---

## 7. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | LB-01 | Antes de que cualquier rama registre `IEstadoLicencia` (SL o L1b) | ≈ 0,05 dp |
| 2 | LB-02 | Antes de cablear `Corroborar` con `emitida` en L1b; precisión para el arquitecto | ≈ 0,1 dp |
| 3 | LB-04 | Con `UseLicencia` (L1b) | ≈ 0,05 dp |
| 4 | LB-03, LB-05 | En L1b | ≈ 0,1 dp |

---

## 8. Recomendación

**PR #35: Aprobado con observaciones.**

No hay hallazgos Críticos ni Altos. La regla, la marca, la lista aprobada y QA-L06 son correctas. LB-01 y LB-02 son Medios y latentes (nada está registrado ni cableado todavía); recomiendo resolverlos **como condición del PR de L1b que registre el estado y la corroboración**. Es una recomendación técnica: la decisión es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr35-l1b-1-2026-10-15.md`
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir; la búsqueda de GET con efecto fue heurística, no exhaustiva; que `CrearDesdeAsync` no escribe lo infiero de la lectura.
- Decisiones candidatas a ADR: precisión de H-16 v2.1 con DL-17 (LB-02): la corroboración por `emitida` solo con firma Avanzada propia, o un techo de INV-6 sin los avances corroborados por licencia. Alternativa descartada: dejarlo como está, que reabre RA-01 para quien tenga `s1` y sea administrador.
- Entregas a otros agentes:
  - desarrollador-backend (L): LB-01 (guarda y `[Obsolete]`), LB-03, LB-04 en `UseLicencia` y LB-05.
  - arquitecto-software: LB-02 y la confirmación de LB-06.
  - coordinador: que SL no registre `EstadoLicenciaHeredado` en `Program.cs` sin la guarda de LB-01.
  - qa-automatizado: el vector de LB-02 (tres cargas con `emitida` creciente).
- Próximo paso recomendado: unir el PR #35 y llevar LB-02 al arquitecto antes del PR de L1b que cablea `Corroborar` y registra `IEstadoLicencia`.

---

## 9. Lectura de diferencias (`8a4e86ee..7dd3f00d`)

**Commits:** `24960ed7` y `7dd3f00d`. Revisé solo en lectura, sin compilar. Las pruebas son las que declara el PR (Licencia 381 en Debug y 380 en Release, con 1 omitida; Arquitectura 181/181; suite 2679/0/19); **no las reproduje**.

| Punto | Estado | Evidencia y comentario |
|---|---|---|
| **LB-01** | **Cerrado** | `EstadoLicenciaHeredado` queda dentro de `#if DEBUG`: en Release el tipo no existe y no se puede registrar. Además, una prueba falla si el host de la API resuelve `IEstadoLicencia` a ese tipo. Hay que borrarlo en el PR que registre `EstadoLicenciaService` (`IEstadoLicencia.cs`) |
| **LB-03** | **Cerrado** | `POST /importaciones/{tipo}/validar` pierde la marca y queda `Operativa`, igual que importar, para todos los tipos (`ImportacionesEndpoints.cs`) |
| **LB-06** | **Cerrado** | `POST /api/admin/respaldos`: un respaldo cada 10 minutos por empresa (`LimitesPeticiones.Respaldos`, por empresa de la sesión o por IP) y uno a la vez por empresa (semáforo; 409 `RESPALDO_EN_CURSO`). El semáforo vive en el proceso: con varias instancias de la API, cada una tiene el suyo, y el tope de `usp_RespaldoCopia` sigue siendo el freno de fondo (PR #36, RG2-01). `POST /api/notificaciones/documento` queda con el límite de reportes |
| **Ruta nueva `POST /api/admin/usuarios/{codigo}/inhabilitar` (`Esencial`)** | **Correcta; no permite escalar ni operar** | Ver el detalle abajo |
| LB-02 | Sigue abierto (Media, de diseño) | Pendiente de la decisión del arquitecto antes de conectar `Corroborar` con `emitida` |
| LB-04, LB-05 | Siguen abiertos (Bajos) | Van con `UseLicencia` (L1b) |

**Análisis de `inhabilitar`**, en `AdminEndpoints.cs` (la ruta nueva) y `UsuariosService.GuardarAsync` (las reglas que reutiliza):
- **Autorización:** está en el grupo `/api/admin` (`RequiereAdmin`, solo la central), el mismo que `POST /usuarios`.
- **Propia cuenta:** se rechaza, comparando con la cuenta que resuelve la base (el mismo criterio H-1 de `POST /usuarios`).
- **SUPER:** un ADMIN no los ve (`ListarAsync(sesion.EsSuper)` → «no existe»). Y aunque los viera, `GuardarAsync` impide que un no SUPER modifique a un SUPER, y mantiene las guardas de «al menos un administrador» y «al menos un Super Usuario habilitado».
- **Sin entrada del cliente salvo el código:** la ficha la arma el servidor a partir de la cuenta guardada, y solo cambian `Inhabilitado = true`, `EsNuevo = false` y `ClaveNueva = null`. No se puede cambiar el nivel, los perfiles ni la contraseña por esta vía, y no permite habilitar: rehabilitar sigue en `POST /usuarios`, que es `Operativa` y se bloquea en solo consulta. Por eso, en solo consulta solo sirve para dejar de consumir cupo (ADR-59, punto 6), no para operar.
- **Efectos:** invalida la caché de permisos, revoca las sesiones (`ForzarNuevoInicioAsync`) y deja dos líneas de auditoría.
- **Observación sin severidad:** hacer el viaje de ida y vuelta con la ficha completa depende de que `ListarAsync` devuelva todos los campos que `GuardarAsync` escribe. Si en el futuro la lista omite uno, inhabilitar lo borraría. Lo cubre la prueba `MembresiasLicenciaHttpTests` (perfiles conservados); conviene que la misma prueba compare la ficha completa antes y después.

### Dictamen final del PR #35

**Aprobado con observaciones.** LB-01, LB-03 y LB-06 están cerrados. La ruta `inhabilitar` es segura. Siguen abiertos LB-02 (Media, de diseño, como condición antes de conectar `Corroborar` con `emitida` en L1b) y LB-04 y LB-05 (Bajos, con `UseLicencia`). No hay hallazgos Críticos ni Altos. Es una recomendación técnica: la decisión es del propietario.

### Cierre (lectura de diferencias)
- Estado: Aprobado con observaciones
- Artefactos: este informe (sección 9 agregada)
- Supuestos: los resultados de pruebas son los declarados, sin reproducir
- Decisiones candidatas a ADR: LB-02, como antes
- Entregas a otros agentes:
  - arquitecto-software: LB-02;
  - desarrollador L: LB-04 y LB-05 en `UseLicencia`, borrar el sustituto al registrar `EstadoLicenciaService`, y la comparación de la ficha completa en la prueba de `inhabilitar`
- Próximo paso recomendado: unir el PR #35 y decidir LB-02 antes del PR de L1b que conecte `Corroborar`
