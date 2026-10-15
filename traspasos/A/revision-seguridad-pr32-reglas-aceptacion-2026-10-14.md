# Informe de Seguridad: PR #32, L1a-2 «Reglas de aceptación»

**Fecha:** 2026-10-14 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé**
- PR #32: rama `a/lic-l1a-2` (`c8430507`, `e64a8077`, `a1562505`) contra su base `feature/modelo-ng` @ `e59d8de2`. Son 16 archivos y +2 227 líneas.
- Árbol `GPOS-NG-lic`, leído con `git show` y `git diff`.

**Referencias:** `[LIC]` 3.1.1, 3.2, 3.6 y 4.1.3; `[PSF]` 4A.4 a 4A.6 (`docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md`); ADR-62; blueprint del lote 2 (§9.2 regla 5, DL-14); mis informes previos (SEG-L2-02, -18 y -24; CR-01 a CR-12).

**Método:** no compilé ni ejecuté pruebas. Las cifras de pruebas que cito son las que declara el PR (130/130 nuevas en Debug y en Release; 304 de licencia con 1 omitida; 160/160 de arquitectura). **No las reproduje.**

---

## 1. Alcance y superficie revisada

| Superficie | Exposición | Archivos |
|---|---|---|
| `VerificarCompacto` | La autorización `autNivel` viaja dentro del contenido firmado de la licencia, que puede llegar sin autenticar por el agente | `src/GPOS.Criptografia/Jws/VerificadorJws.cs`, `ContratosJws.cs` |
| JSON estricto y deserializador (CR-12) | Contenido ya verificado | `LectorJsonEstricto.cs`; `src/GPOS.Core/Sistema/Licencia/LectorContenidoLicencia.cs` |
| Reglas de aceptación ([LIC] 6.2) | Deciden si un archivo se acepta, con qué nivel, qué piso deja y qué cortes aplica | `ReglasAceptacion.cs` |
| Regreso temporal a Básico | Es una excepción al piso Avanzado | `AutorizacionRegresoNivel.cs` |
| Piso de nivel (INV-11) y DL-14 | Monotonía del piso y tope de vigencia | `PisoNivelFirma.cs`, `ReglaVigenciaBasica.cs` |

**Fuera de alcance:** la persistencia, la `sec` máxima efectiva, INV-7 e INV-8, el retiro por `AutorizacionVencida` y el estado de la cadena de autorizaciones (L1a-3 y L1a-4); el manifiesto (L4).

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| RA-01 | **Media** (diseño, heredado de `[LIC]` 4.1.3) | El techo de 48 h (INV-6) se mide desde una referencia que incluye la `emitida` de la licencia vigente, así que avanza 48 h con cada carga y anula el tope de DL-14 |
| RA-02 | Baja | `PisoNivelFirma.Efectivo` no registra una fuente **ausente**: borrar una o dos fuentes no deja rastro |
| RA-03 | Baja | `ReglasAceptacion` tiene un constructor público que recibe cualquier `IVerificadorJws` |
| RA-04 | Informativa | Cierre anticipado por una autorización que acorta: solo surte efecto en la instalación que la ve |
| RA-05 | Informativa | La recarga idempotente sale antes de NV-05 y del piso |
| RA-06 | Informativa | Fronteras de fecha: INV-1 cuenta desde las 00:00 RD del `aceptarHasta`, y DL-14 usa la fecha UTC de `emitida` |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **No aplica** (no hay rutas) |
| A02 Criptografía | **Bien.** `VerificarCompacto` usa las mismas primitivas (ES256, P1363, base64url canónico); nada casero |
| A03 Inyección | **Bien.** `Detalle` solo trae nombres de campo y códigos; los `kid` ya cumplen `FormatoKid` |
| A04 Diseño inseguro | **Observación** RA-01 (techo deslizante), RA-04 |
| A05 Configuración | **Bien.** NV-05 usa la constante de compilación |
| A06 Componentes | **No aplica** (sin paquetes nuevos) |
| A07 Autenticación | **No aplica** |
| A08 Integridad | **Bien**, con RA-02 y RA-03 |
| A09 Registro y monitoreo | **Bien.** Los eventos se piden en un rechazo y en una aceptación; ver RA-02 |
| A10 SSRF | **No aplica** |

---

## 4. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| **¿Sirve `VerificarCompacto` para aceptar una licencia en forma compacta?** | **No.** `FuncionPorTypCompacto` solo admite `gpos-autorizacion-nivel+jws`, y `FuncionPorTyp` solo admite `gpos-licencia+jws`. `LeerEncabezado` exige que el `typ` **protegido** coincida, así que ni una licencia compacta pasa por el camino compacto ni una autorización pasa por el de licencias. `ReglasAceptacion` siempre llama a `Verificar(…, TiposJws.Licencia, …)` | `VerificadorJws.cs` (`FuncionPorTypCompacto`, `VerificarCompacto`); `ReglasAceptacion.cs:201`; prueba `Un_encabezado_de_licencia_no_pasa_por_autorizacion` |
| ¿Se salta algo de 3.1.1? | **No.** Comparte `LeerEncabezado` (ES256, `typ`, `FormatoKid`, `nivel` conocido, sin `crit` ni `b64`), el base64url canónico de las tres partes, el JSON estricto del contenido, el tope de tamaño, el punto 9 (desarrollo en Release), el nivel según el recurso, los retiros y P1363 con captura (`VerificarFirmas`). La forma compacta no tiene encabezado no protegido. Que la firma sea Avanzada y la llave esté activa lo exige el Core | `AutorizacionRegresoNivel.cs:74-79` |
| `AllowDuplicateProperties = false` | Verificado, como defensa en profundidad sobre la comprobación propia | `LectorJsonEstricto.cs` (`OpcionesDocumento`) |
| CR-12 en el deserializador | **Cerrado.** Distingue mayúsculas, sin duplicados, `NumberHandling.Strict`, `RespectNullableAnnotations`, opciones de solo lectura, obligatorios comprobados antes de deserializar y fechas exigidas en UTC | `LectorContenidoLicencia.cs:36-51, 107-121, 175-212` |
| `crit` y `fmt` | Un `fmt` mayor da `VERSION_NO_SOPORTADA`; un `crit` desconocido o repetido rechaza el archivo; `autNivel` presente si y solo si está en `crit` | `:85-105, 194-196` |
| Orden de [LIC] 6.2 | Verificado, en los pasos 1 a 12 | `ReglasAceptacion.cs:200-331` |
| Otra instalación | Se rechaza sin adopción, también en la primera carga; `instalacion` vacía da `FORMATO` | `:212-213`; `LectorContenidoLicencia.cs:182` |
| `sec` e identidad por contenido | Una `sec` menor da `ANTERIOR`; la misma con otro contenido, `SEC_DUPLICADA`; con el mismo contenido es una recarga. SEG-L2-24 sigue anclado | `:219-238` |
| INV-1 | La caducidad solo rige con relevo Avanzado activo y no retirado; sin relevo se registra `LlaveBasicaSinRelevo` | `:241-265`; `PisoNivelFirma.cs:23-25` |
| NV-05 y NV-06 | Verificados | `:268-273` |
| INV-6 | Implementado según `[LIC]`; ver **RA-01** | `:276-278`, `:161-162` |
| INV-10 | Llega dentro de la hora protegida (L1a-4) | `:157-162` |
| Llaves latentes | Una firma latente solo cuenta si hay una autorización válida **para ese `kid`** y ese `kid` firmó la licencia | `:258-293`; `AutorizacionRegresoNivel.cs:92-97` |
| ¿Se puede bajar el nivel? | **No.** «Avanzada propia» exige una firma sobre el contenido con una llave `lic`, `avanzado`, `activa` y no retirada (INV-5: la de la autorización no cuenta). Con piso Avanzado, un archivo sin esa firma ni autorización da `NIVEL_INSUFICIENTE` | `PisoNivelFirma.cs:15-17`; `ReglasAceptacion.cs:296-298` |
| ¿Se puede bajar el piso? | **No.** Con firma Avanzada, `Mayor(piso, nivelMin)`; sin ella, D-2 hereda el piso y registra `PisoHeredado`. INV-11 toma el máximo de las fuentes que verifican | `:304-320`; `PisoNivelFirma.cs:80-96` |
| `perfilMin` | Solo lo fija, lo baja o lo quita un archivo con firma Avanzada propia (`[LIC]` 3.2); `avanzada` exige `nivelMin` `avanzado` | `:306-309` |
| Reutilizar una autorización | Queda acotada por la ventana (`horaReferencia ≥ desde` y `horaEvaluacion ≤ hasta`), por la cadena (`sec` menor rechazada; la misma `sec` no alarga; una renovación solo si es contigua; `inicioRegreso` fijo) y por el tope de 60 días. Se ata al `kid` latente y, con lista, a la instalación. Ver RA-04 | `AutorizacionRegresoNivel.cs:99-126` |
| Q-17 | Catálogo cerrado; `SospechaEquipoEmisor` exige la lista; con lista, la instalación tiene que figurar; las entradas vacías se rechazan | `:85-90`; `LectorContenidoLicencia.cs:149-151` |
| Extender la vigencia | Con autorización, cada `vence` ≤ `hasta` + 31 días (también los de módulo). DL-14 aplica a todo lo que no tiene firma Avanzada propia. Ver **RA-01** | `AutorizacionRegresoNivel.cs:104-106`; `ReglaVigenciaBasica.cs:30-34` |
| CW-02 | El corte solo vale con firma Avanzada propia; si no, `CorteIgnorado` | `:329-331, 349-350` |
| DL-14 en un commit aislado | Verificado: `a1562505` solo toca `ReglaVigenciaBasica.cs`, su prueba y el bloque marcado. Un `git revert` lo retira limpio | `git show --stat a1562505` |
| Fallas que no restringen | No encontré ninguna. Cada `ArgumentException` de entrada es un error de programación (falla cerrado). Las excepciones de deserialización dan `FORMATO`. Toda falla de la autorización rechaza el archivo completo (`crit`) | — |

---

## 5. Hallazgos

### RA-01 · Media (diseño, heredado) · El techo de INV-6 avanza con cada carga y anula DL-14

- **Riesgo:** la hora de referencia del techo es `máx(Ahora protegido, emitida de la licencia vigente)`. La implementación sigue `[LIC]` 4.1.3 y la definición de INV-6. Así, un archivo aceptado con `emitida` cercana a referencia + 48 h sube la referencia para el siguiente, que a su vez puede llegar otras 48 h más allá, y así sucesivamente. Quien tenga la llave básica `s1` (o un lote de archivos firmados con ella para una instalación) puede, en una sola sesión de cargas, llevar `emitida`, y con ella el tope de DL-14 (`vence ≤ emitida + 200 días`), tan lejos como cargas haga. DL-14 (SEG-L2-02) busca justamente acotar lo que vale lo firmado con una llave básica comprometida, y su texto dice «200 días más el techo de 48 h», no «48 h por carga». Hay tres efectos más:
  - la hora de evaluación (con piso en `emitida`) queda en el futuro;
  - la `sec` máxima efectiva sube, así que las licencias legítimas de GSF darán `ANTERIOR` hasta que la hora real alcance a las falsas;
  - en el escenario A, INV-1 frena el avance al llegar a `aceptarHasta`, pero en el escenario B (sin relevo) nada lo frena.
- **Probabilidad:** baja. Hace falta comprometer el equipo emisor o su TPM, que es el modelo de amenaza de DL-14. **Impacto:** vigencia sin tope en un cliente que no actualiza.
- **Evidencia:** `ReglasAceptacion.cs:161-162` (`HoraReferencia`), `:276-278` (techo), `:241` (evaluación); `[LIC]` 4.1.3 (tabla «Hora de evaluación de la licencia»); 3.1.1 punto 8.
- **Remediación (≈ 0,05 dp de código más una precisión de diseño):** medir el techo de INV-6 **solo** sobre `IRelojProtegido.Ahora()`, que ya tiene el piso de compilación (INV-10) y es monótono, y dejar `máx(Ahora, emitida vigente)` solo como hora de **evaluación** del estado. GSF emite con NTP − 1 h, así que una licencia legítima solo daría `FECHA_FUTURA` con el reloj del servidor más de 47 h atrasado, y ese caso ya registra `RelojInconsistente`. Como alternativa más conservadora: techo = `Ahora + 48 h` para los archivos sin firma Avanzada propia y la referencia actual para los Avanzados. Cambia el texto firmado de INV-6, así que la decisión es del arquitecto y del propietario. **No bloquea el PR:** el código cumple la especificación firmada. Hay que resolverlo antes de que DL-14 se dé por cerrado.

### RA-02 · Baja · Una fuente del piso ausente no se registra

- **Riesgo:** `Efectivo` pasa por alto las fuentes con `Nivel == null` (archivo `pisonivel` borrado, fila de `Configuracion` ausente). INV-11 se cumple mientras quede una fuente válida, pero borrar una o dos no deja evento, y el atacante tiene que borrar las tres para bajar el piso. Sin rastro de los pasos intermedios se pierde la detección temprana que pide `[PSF]` 4A.5 («deja rastro»).
- **Evidencia:** `PisoNivelFirma.cs:86-87`.
- **Remediación (≈ 0,03 dp):** si el resultado es `avanzado` y alguna fuente no dice nada, devolverla en `FuentesInvalidas` (o en una lista de ausentes) para que L1a-4 registre el evento y regenere la fuente con su MAC.

### RA-03 · Baja · Constructor público con `IVerificadorJws`

- **Riesgo:** `IVerificadorJws` es una interfaz pública. Un `ReglasAceptacion` armado con otra implementación puede devolver resultados reales de **otro** archivo, o un resultado de licencia en `VerificarCompacto`. CR-06 impide fabricar resultados, pero no reutilizarlos. Hace falta código propio dentro del proceso, así que la severidad es Baja.
- **Evidencia:** `ReglasAceptacion.cs:150-154`.
- **Remediación (≈ 0,01 dp):** dejar `internal` el constructor que recibe el verificador (las pruebas lo ven por `InternalsVisibleTo`) y que la API solo use el constructor sin argumentos.

### RA-04 · Informativa · El cierre anticipado por autorización depende de que la instalación la vea

Una autorización de `sec` mayor que acorta la ventana solo actualiza `EstadoRegresoKid` en la instalación que la recibe dentro de una licencia. En otra instalación, quien tenga `s2` puede seguir usando la autorización anterior (sin lista, si la causa no era `SospechaEquipoEmisor`) hasta su `hasta`. Es un residual del diseño de `[PSF]` 4A.6: el cierre efectivo es el retiro de `s2` por el manifiesto (punto 6). **Procedimiento:** ante una sospecha sobre el emisor, retirar `s2` por manifiesto además de emitir la autorización que acorta.

### RA-05 · Informativa · La recarga idempotente no reevalúa

La recarga sale en el paso 4, antes de NV-05, del piso y de DL-14. Es coherente con INV-7 (lo ya aceptado no se reevalúa). **L1a-4** tiene que tratarla sin ningún efecto de estado: no reactiva ni reescribe el piso, y no cuenta como «licencia nueva».

### RA-06 · Informativa · Fronteras de fecha

- INV-1 rechaza desde las 00:00 RD del día `aceptarHasta` (`InicioDelDiaRd`). Es la lectura estricta de «desde `aceptarHasta`» y deja un día menos que la lectura «hasta ese día inclusive». Conviene que el arquitecto la confirme y que el emisor la conozca.
- DL-14 usa la fecha **UTC** de `emitida`, mientras que `vence` es un día de RD. La diferencia es de un día como máximo, en el sentido que admite un día más.

---

## 6. Controles bien implementados

- **Separación por `typ` en dos direcciones** entre la licencia (serialización general) y la autorización (compacta), con un código común en `VerificarFirmas`.
- **INV-5:** la firma Avanzada de la autorización nunca hace Avanzado el archivo. La autorización exige que el `kid` latente autorizado **haya firmado** la licencia.
- **Cadena de autorizaciones completa:** `inicioRegreso` fijo, `sec` que no retrocede, la misma `sec` no alarga, renovación contigua medida con la hora de la `sec`, tope de 60 días desde `mín(inicioRegreso, desde mínimo)` y `vence` ≤ `hasta` + 31 días, también en los módulos.
- **D-2, INV-4 y CW-02:** sin firma Avanzada propia nada sube el piso ni el perfil, ni aplica cortes; todo se registra como evento.
- **CR-12 cerrado** con las opciones verificadas en .NET 10.0.12, según el PR.
- **DL-14 aislado** en un commit que se puede revertir.

---

## 7. Remediaciones priorizadas

| Orden | ID | Responsable | Cuándo |
|---|---|---|---|
| 1 | RA-01 | arquitecto-maestro y arquitecto-software (precisión de INV-6), después desarrollador L | Antes de dar por cerrado DL-14 y antes de L1 en producción |
| 2 | RA-03, RA-02 | desarrollador L | En L1a-2 (seguimiento) o en L1a-4 |
| 3 | RA-04 a RA-06 | GSF (procedimiento), L1a-4 y arquitecto | Con L1a-4 y la ceremonia |

---

## 8. Recomendación

**PR #32: Aprobado con observaciones.**

No hay hallazgos Críticos ni Altos. El código cumple `[LIC]` 3.1.1 y 6.2, `[PSF]` 4A.4 a 4A.6 (con Q-17, CV-07, D-2, INV-1, INV-5, INV-6 e INV-11) y CR-12. `VerificarCompacto` no abre ninguna vía para aceptar una licencia ni para saltarse los controles de 3.1.1. RA-01 es Media y de diseño: no bloquea la unión, pero queda como condición antes de dar por cerrado DL-14. Es una recomendación técnica; la decisión es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr32-reglas-aceptacion-2026-10-14.md`
- Supuestos: los resultados de pruebas son los que declara el PR (sin reproducir); la probabilidad de RA-01 supone que `s1` no está comprometida hoy.
- Decisiones candidatas a ADR: precisión de INV-6 (ADR-62) y de `[LIC]` 4.1.3. El techo de 48 h se mide sobre el reloj protegido, no sobre la `emitida` vigente. Alternativa descartada: mantener la referencia actual, que deja el tope de DL-14 a merced de cargas sucesivas.
- Entregas a otros agentes:
  - arquitecto-maestro y arquitecto-software: RA-01 (precisión de INV-6) y la confirmación de RA-06.
  - desarrollador-backend (L): RA-02 y RA-03; RA-05 en L1a-4.
  - GSF y documentador: el procedimiento de RA-04 (retirar `s2` por manifiesto ante sospecha sobre el emisor).
  - qa-automatizado: un vector de cargas sucesivas con `emitida` creciente para fijar el comportamiento que se decida en RA-01.
- Próximo paso recomendado: unir el PR #32 y llevar RA-01 al arquitecto antes de la firma de DL-14.

---

## 9. Lectura de diferencias (`a1562505..9e47cc68`)

**Commits:** `af86bc45` (correcciones de validación, RA-02 y RA-03) y `9e47cc68` (DL-14 con la fecha civil de RD). Revisé solo en lectura, sin compilar.

| Punto | Estado | Evidencia y comentario |
|---|---|---|
| **RA-02** | **Cerrado** | `PisoNivelEfectivo` agrega `FuentesAusentes` y `Eventos`, con el evento nuevo `PisoFuenteAusente`. Una fuente con MAC (`Configuracion` o `pisonivel`) que falta cuenta como ausente si el piso es `avanzado` o si la otra fuente con MAC existe; en una instalación nueva no se genera ruido. Además se pide `PisoNivelFuenteInvalida` (`PisoNivelFirma.cs`, `Efectivo`). Si se borran las tres fuentes, el piso baja sin evento: es el residual que `[PSF]` 4A.5 ya acepta (requiere `sysadmin` y administrador de Windows) |
| **RA-03** | **Cerrado** | `ReglasAceptacion(IVerificadorJws)` pasa a ser `internal`; la API solo tiene `ReglasAceptacion()`, con el `VerificadorJws` real. Residual informativo: `PisoNivelFirma.EleveDesdeLicencia(…, IVerificadorJws)` y `AutorizacionRegresoNivel.Verificar(…, IVerificadorJws, …)` siguen siendo públicos con el verificador como parámetro. Es el mismo patrón y el mismo requisito (código propio dentro del proceso); conviene que L1a-4 los llame siempre con el verificador real, o dejarlos `internal` en un seguimiento |
| **`[assembly: InternalsVisibleTo("GPOS.Tests")]` en GPOS.Core** | **No abre ninguna vía en Release** | El atributo es nuevo en GPOS.Core: antes solo lo tenía `GPOS.Criptografia`. Va sin llave pública, así que cualquier ensamblado llamado `GPOS.Tests` **cargado dentro del proceso** ve los miembros internos de **todo** GPOS.Core, no solo los de la licencia. Para eso hay que poder cargar código propio en la API, y con eso ya se puede hacer cualquier cosa: no cruza ninguna frontera de confianza nueva (mismo análisis que CR-11). Las llaves de desarrollo siguen cerradas por las constantes de compilación de `GPOS.Criptografia` (CR-04). **Dos observaciones informativas:** (a) la entrega a devops de CR-11 (que la publicación no incluya `GPOS.Tests.dll`) vale ahora también para Core; (b) declararlo en `FormatoInstalacionId.cs` en lugar de en `GPOS.Core.csproj` lo deja fuera de la vista: conviene moverlo al `.csproj` cuando se libere ese archivo |
| Autorización con modelo cerrado | **Mejora** | Un miembro desconocido rechaza la autorización (no tiene `crit` ni `fmt`, así que es la única forma de no fallar abierto con un campo restrictivo futuro). Las `instalaciones` tienen que cumplir `FormatoInstalacionId` |
| La misma `sec` con otra ventana | **Mejora** | `a.Hasta != p.HastaVigente` rechaza también la misma `sec` con una ventana más corta (antes solo la más larga) |
| `InstalacionId` | **Mejora** | GUID en formato `D` y en minúsculas, comparado en ordinal, en la licencia, en la autorización y en la entrada local (que falla cerrada si no lo cumple). Cada valor tiene una sola escritura |
| DL-14 y `hasta` + 31 días con la fecha civil de RD | **Correcto y del lado restrictivo** | `VenceMaximo` y `FechaCivilRd` usan UTC−4: dan la misma fecha UTC o la del día anterior. Cierra la segunda parte de RA-06. `9e47cc68` solo toca `ReglaVigenciaBasica.cs` y su prueba, así que se puede revertir por separado |
| RA-01 | **Sigue abierto** (Media, de diseño) | Ahora hay una prueba que fija el comportamiento actual, a la espera de la decisión del arquitecto sobre INV-6. No bloquea la unión |
| RA-04, RA-05 y la primera parte de RA-06 | Sin cambio (informativos) | — |

### Dictamen final del PR #32

**Aprobado con observaciones.** RA-02 y RA-03 están cerrados, y el `InternalsVisibleTo` en Core no abre ninguna vía en Release. No quedan hallazgos Críticos ni Altos. Queda abierto RA-01 (Media, de diseño), con su prueba de comportamiento, como condición antes de dar por cerrado DL-14. Es una recomendación técnica: la decisión es del propietario.

### Cierre (lectura de diferencias)
- Estado: Aprobado con observaciones
- Artefactos: este informe (sección 9 agregada)
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir
- Decisiones candidatas a ADR: la misma de antes (precisión de INV-6, RA-01)
- Entregas a otros agentes:
  - arquitecto-maestro y arquitecto-software: RA-01;
  - desarrollador L: dejar `internal` las sobrecargas con `IVerificadorJws`, o comprometerse a usar siempre el verificador real en L1a-4, y mover el `InternalsVisibleTo` al `.csproj`;
  - devops: que la publicación no incluya `GPOS.Tests.dll`, ahora también por GPOS.Core
- Próximo paso recomendado: unir el PR #32 y decidir RA-01 antes de firmar DL-14
