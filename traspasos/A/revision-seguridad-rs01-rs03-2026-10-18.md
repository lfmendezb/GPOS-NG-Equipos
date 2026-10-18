# Revisión de seguridad: RS-01 a RS-03 (rama `a/rs-anillo-sellos`)

- **Fecha:** 2026-10-18
- **Revisor:** auditor-seguridad (equipo A)
- **Alcance:** `git diff 34cf88fd..5df479b6`. Son los commits `9419741a` (RS-01 y RS-02) y `5df479b6` (RS-03), sobre la punta del PR #68.
- **Origen:** observaciones RS-01 a RS-03 de mi revisión del #68 (aviso `avisos/A-a-B/2026-10-17-pr68-ar01-ar06.md`).
- **Decisión firmada RS-01 (a):** la revocación falla cerrada mientras queden el padrón o sellos de cuentas con las llaves que se van a revocar.
- **Veredicto: Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Se recomienda corregir RSV-01 antes de abrir el PR: el propio RS-03 abre ese camino nuevo de falla.

## 1. Alcance y superficie revisada

**Superficie:** solo verbos del técnico (`GPOS.Migracion anillo --revocar-heredadas` y `--cambiar-recuperacion`), el arranque de la API (LV-21) y la decisión de SLF-01 (sellado inicial y resellado). No hay endpoints anónimos nuevos.

**Revisado:**
- `src/GPOS.Core/Infraestructura/Anillo/ReproteccionSecretos.cs:96-134` (`SellosConLlavesAsync`) y `:215-216` (`IdLlave(ReadOnlySpan<byte>)`).
- `src/GPOS.Migracion/Anillo/MantenimientoAnillo.cs:147`, `:182-194` y `:209-218`.
- `src/GPOS.Migracion/Anillo/ComandosAnillo.cs:39`, `:72-83`.
- `src/GPOS.Core/Sistema/Licencia/AlmacenLicenciaDisco.cs:158-171`.
- `src/GPOS.Core/Sistema/Usuarios/SellosService.cs:172-175`, `:358` y `:365-376`.
- Las 12 pruebas nuevas.

**Contexto leído:**
- El decorador del anillo y su estado: `AnilloDataProtection.cs:62-91` y `:179-203`.
- Quién escribe sellos y padrón: `SellosCuentas.cs:58-71` y `PadronSellos.cs:104-189`.
- `EstadoLicenciaService.cs:232-241` y `:294-299`.
- `Program.cs:382-389` de la API.

**Ejecutado:**
- `dotnet test` con el filtro `(MantenimientoAnilloTests|SellosReselladoTests|AlmacenLicenciaDiscoTests)&Transicion!=Ola5&Transicion!=Defecto`: **36/0/0**.
- La primera corrida se anuló por `testhost.exe` (lo conocido de la PC A). Lo borré y repetí con `--no-build`; borrado otra vez al terminar.
- No corrí la suite completa: el 804/0/1 lo informa el desarrollador y no lo verifiqué.
- No modifiqué la rama.

## 2. Tabla resumen

| ID | Severidad | Título | ¿Antes del PR? |
|---|---|---|---|
| RSV-01 | Media | En `--cambiar-recuperacion`, las fallas posteriores al cambio del ancla (la nueva de RS-03 en el disco y la 2.ª comprobación) dejan un estado sin reintento y con un mensaje engañoso | **Sí** |
| RSV-02 | Media (sospecha fundada, ya existía) | `--cambiar-recuperacion` con la API en marcha: la API sigue protegiendo con la llave anterior después de reproteger y de revocar | No; bloquea el primer cambio real |
| RSV-03 | Media | Con sellos, `--cambiar-recuperacion` queda bloqueado siempre: no hay remedio ante una recuperación comprometida mientras no exista la reprotección conjunta | No; va al arquitecto |
| RSV-04 | Baja | `LeerProtegido`, `LeerSello` y `LeerVigente` con `File.Exists`: falla abierta en `ConLlavesDisco` y omisión silenciosa en `ReprotegerDisco` | Recomendado (barato) |
| RSV-05 | Baja | `ComandosAnillo.DiscoLicencia` con `Directory.Exists`: si el técnico no ve la carpeta, los verbos se saltan el disco entero | Recomendado (barato) |
| RSV-06 | Baja | «Sin encabezado = dependiente»: correcto, pero el mensaje no distingue «ilegible con cualquier llave» de «con una llave a revocar» | Puede esperar |
| RSV-07 | Baja | Faltan pruebas de la 2.ª comprobación, del archivo `padron` ilegible y del valor sin encabezado | Parcial (dos casos baratos) |
| RSV-08 | Baja | Arranque de la API: RS-03 propaga una `UnauthorizedAccessException` cruda | Puede esperar |

## 3. Checklist OWASP (aplicado al cambio)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Sin cambios. Los verbos son del técnico, con acta. Ver RSV-05: el permiso de carpeta se toma como «no existe». |
| A02 Criptografía | Revisado. `IdLlave` lee el encabezado documentado de la carga de Data Protection (magia `0x09F0C9F0` y GUID). Ver RSV-02 y RSV-03. |
| A03 Inyección | No aplica (consultas LINQ sin texto dinámico). |
| A04 Diseño inseguro | RSV-01, RSV-02 y RSV-03: orden de los pasos del cambio de recuperación y ausencia de un verbo de reprotección de sellos. |
| A05 Configuración | RSV-05: la carpeta de la licencia se resuelve de la configuración. Si no se ve, se omite. |
| A06 Componentes vulnerables | No aplica (sin dependencias nuevas). |
| A07 Autenticación | Indirecto. Protege los sellos de habilitación de cuentas (ADR-83). Correcto en lo que cubre. |
| A08 Integridad | Correcto: falla cerrada ante padrón o sellos con llaves a revocar. RSV-04: archivos ilegibles del disco. |
| A09 Registro y monitoreo | Los mensajes no filtran secretos ni rutas sensibles (sección 5). RSV-08: falta un evento claro al arrancar. |
| A10 SSRF | No aplica. |

**Aislamiento entre tenants:** no aplica. `GPOS_SYSDATA` y la carpeta de la licencia son de la instalación.

## 4. Hallazgos

### RSV-01 (Media) — En `--cambiar-recuperacion`, las fallas posteriores al cambio del ancla dejan un estado sin reintento y el mensaje engaña

**Riesgo.** Desde `MantenimientoAnillo.cs:183-184`, la fila del ancla ya tiene la huella nueva y existe la llave nueva.

El estado de transición (`RecuperacionTransicion`) vive solo en la memoria del proceso de `GPOS.Migracion`: `AnilloDataProtection.cs:66` y `:90-91`, un `volatile` sin persistencia.

Si algo falla después, el decorador de la API descarta las llaves de la recuperación anterior en cuanto vuelve a arrancar con el ancla nueva. Las descarta aunque no se hayan revocado (`AnilloDataProtection.cs:194` y `:201`; AN-01). Todo lo que siga protegido con ellas queda ilegible.

El reintento tampoco sirve: la huella nueva ya es la anclada, así que el verbo se niega con «ya es el anclado» (`:175`).

Hay tres caminos de falla posteriores al ancla:
1. `ReprotegerAsync`, `:185-187`, con `Fallos`. Ya existía.
2. **RS-03 agrega uno nuevo.** `ReprotegerDisco` llama a `disco.Procesados()` (`ReproteccionSecretos.cs:175`), que ahora lanza `UnauthorizedAccessException` o `IOException` (`AlmacenLicenciaDisco.cs:158-168`). La excepción sale de `:185` sin pasar a `Fallos`, con el ancla ya cambiada y con la base ya reprotegida (`SaveChanges` antes del disco, `:252-255`). Antes de RS-03 ese caso se omitía en silencio. Lanzar es mejor que eso, pero en este punto deja el peor estado.
3. La 2.ª comprobación (`:189-192`). Su mensaje, «Las llaves anteriores no se revocan», da a entender que lo dependiente se salvó. No es así: al reiniciar la API, el decorador deja de usar esas llaves. Lo único que se conserva es la posibilidad de una vuelta atrás con GSF (configurar de nuevo la recuperación anterior y repetir el verbo, *inferido, no ensayado*).

**Evidencia:** `MantenimientoAnillo.cs:182-194` y `:250-255`; `ReproteccionSecretos.cs:175`; `AlmacenLicenciaDisco.cs:158-168`; `AnilloDataProtection.cs:66`, `:90` y `:194-202`.

**Sobre la pregunta 1:** ¿la 2.ª comprobación deja un estado peor que antes? Frente a no tenerla, no: sin ella se revocarían llaves con dependientes y no habría vuelta atrás. Frente a hacerlo todo antes del ancla, sí, pero esa comprobación no se puede adelantar del todo: vigila escrituras concurrentes. Lo que sí se puede y se debe adelantar es todo lo que falla cerrado por legibilidad.

**Remediación (≈0,2 dp; antes del PR):**
1. **Comprobación previa de legibilidad del disco antes de `:183`.** Enumerar `Procesados` y leer los protegidos y los `.acept`, sin cambiar nada. Cualquier `IOException` o `UnauthorizedAccessException` se convierte en `ReglaNegocioException` «No se cambia la recuperación: no se pudo leer la carpeta de la licencia. No se cambió nada». Basta con ejecutar `ConLlavesDisco` con un conjunto vacío dentro de un `try`, porque recorre lo mismo que `ReprotegerDisco`.
2. **En `ReprotegerAsync` (`:250-255`), atrapar las excepciones de E/S y de acceso de `ReprotegerDisco`** y agregarlas a `Fallos`, para que el camino de `:186-187` informe con el mismo texto y no revoque.
3. **Corregir los mensajes de `:187` y `:191`** para que digan el estado real: «El ancla ya cambió; las llaves anteriores no se revocaron, pero la API dejará de usarlas al reiniciar. No reinicie la API; comuníquese con GSF para la vuelta atrás». Sin rutas ni valores.
4. **Prueba:** `Procesados` ilegible en `--cambiar-recuperacion`; afirmar que el ancla no cambia (ver RSV-07).

**Alternativa descartada:** persistir el estado de transición en `GPOS_SYSDATA` (fila con MAC) para que el verbo se pueda reanudar. Es lo correcto a la larga, pero cuesta 1-1,5 dp y toca el decorador de la API. Lo dejo como candidata a ADR junto con RSV-03.

### RSV-02 (Media; sospecha fundada, ya existía, requiere confirmación con un ensayo) — `--cambiar-recuperacion` con la API en marcha

**Riesgo.** La API corre en otro proceso. Su anillo de Data Protection en caché conserva la llave predeterminada anterior hasta que refresca, y eso ocurre a lo sumo cada 24 horas o cuando vence la predeterminada (comportamiento de `KeyRingProvider`; *inferido para .NET 10, no medido*). Ver la llave nueva y la revocación hechas por `GPOS.Migracion` no la obliga a refrescar.

Su `EstadoAnclaAnillo` también sigue con la huella anterior hasta reiniciar. Entre la reprotección (`:185`) y el reinicio, la API sigue protegiendo con la llave anterior todo lo que escribe:
- filas `Licencia.*`;
- el reloj de H-16;
- los archivos de la licencia;
- el padrón y los sellos.

Después de `RevokeKey` (`:193`) y del reinicio, esos valores no se pueden leer. La 2.ª comprobación de RS-01 mira solo los sellos y solo en un instante (`:190`), así que no cierra esa ventana.

**El TOCTOU de los sellos, en la práctica, está cerrado** (verificado). La API solo sella si hay un padrón que verifica:
- `Poner` y `Quitar` exigen `Actual` (`PadronSellos.cs:145-160` y `:186-189`);
- solo el sellado inicial lo crea (`:124` y `:161-170`), además del sellado de desarrollo al arrancar en Debug.

Con padrón, la 1.ª comprobación ya bloquea. La 2.ª solo protege de un `sellos` inicial del técnico ejecutado a la vez, o de la API de Debug.

**Evidencia:** `MantenimientoAnillo.cs:183-194`. No hay ningún aviso ni comprobación de «API detenida»: busqué en `src/GPOS.Migracion/Anillo` y en `docs/` y no aparece para este verbo.

**Remediación** (no es de este PR; debe estar antes del primer `--cambiar-recuperacion` real):
1. **Lo más barato (≈0,1 dp).** El procedimiento y el texto del verbo exigen detener la API (y la de reportes, ADR-109) antes de ejecutarlo y reiniciarla después. Es el mismo patrón de SN-02. Entrega a devops para el procedimiento.
2. **Control técnico (≈0,5 dp).** La API toma un `sp_getapplock` compartido de sesión en `GPOS_SYSDATA` mientras está viva; el verbo lo pide exclusivo con espera cero y se niega si no lo obtiene.
3. **Solo para los sellos (≈0,2 dp), defensa en profundidad.** Mantener `UPDLOCK, HOLDLOCK` sobre la fila del padrón desde `:182` hasta `:193`, el mismo bloqueo que toma `TomarAsync` (`PadronSellos.cs:91`). Eso serializa cualquier escritura de sellos con el verbo.

**Alternativa descartada:** forzar el refresco del anillo en la API con un aviso entre procesos. Es más complejo y no cubre una API que no responde.

### RSV-03 (Media) — Con sellos, `--cambiar-recuperacion` queda bloqueado siempre

**Riesgo.** Los sellos y el padrón se protegen con la llave predeterminada, que en una instalación anclada siempre es una conforme de la recuperación anclada. Por eso `viejas` (`:179-180`) siempre contiene la llave de cada sello. En toda instalación sellada, la 1.ª comprobación (`:182`) se niega sin excepción.

Lo mismo pasa con `--revocar-heredadas` si el sellado se hizo antes de migrar desde DPAPI. *Inferido; depende del orden de implantación.*

Esto se ajusta a RS-01 (a) como medida provisional: falla cerrada, sin daño. La consecuencia de seguridad es que **el remedio de 4C.4 bis ante una recuperación comprometida o un cambio de custodio queda indisponible** en toda instalación con sellos. Mientras tanto, quien tenga la privada de recuperación anterior puede abrir todas las llaves vigentes.

**Evidencia:** `MantenimientoAnillo.cs:179-182`; `SellosCuentas.cs:70` y `:78` (los sellos se escriben con el protector vigente); la nota `ReproteccionSecretos.cs:28-29` («el padrón se agrega aparte»).

**Remediación.** Para el arquitecto-maestro: una pieza de **reprotección conjunta de padrón y sellos** (≈1,5-2 dp con pruebas), con este diseño:
1. Con la API detenida (RSV-02), una transacción que toma el padrón con `UPDLOCK, HOLDLOCK`.
2. Para cada cuenta: `Unprotect` del sello (incluidas las llaves en transición) y `Protect` con la predeterminada nueva.
3. Recalcular `HuellaSello` en la entrada del padrón.
4. Escribir el padrón con la versión siguiente y confirmar.
5. Después de confirmar, reemplazar el archivo `padron` de forma atómica, como en `PadronSellos.cs:425-433`.
6. Si un sello no abre, se aborta todo y no se revoca.

Esa pieza se llama desde `ReprotegerAsync` y deja la 1.ª comprobación como red de seguridad.

**Hasta entonces** se mantiene el aviso de RS-01: no cambiar la recuperación en una instalación sellada. Ante una recuperación comprometida, interviene GSF por procedimiento manual. Debe constar en el procedimiento de devops.

**Alternativa descartada:** excluir los sellos de la comprobación y volver a sellar todo con `--resellar` después. Se descarta porque `--resellar` se niega con `SelloInicial` vigente (SLF-01 y AR-06), y abrir esa puerta debilita SLF-01.

### RSV-04 (Baja) — `LeerProtegido`, `LeerSello` y `LeerVigente` con `File.Exists`

**Riesgo.** `File.Exists` da `false` también cuando no hay permiso, y así un archivo ilegible cuenta como ausente:
- `ConLlavesDisco` (`ReproteccionSecretos.cs:165-166`) no lo lista y la revocación avanza;
- `ReprotegerDisco` (`:146` y `:152`) lo omite sin informar el fallo.

Revocada la llave, el archivo queda inservible. Ocurre con `secmax`, `estado` y `pisonivel`, y con un `.acept`:
- secmax y estado tienen copia en la base, que sí se reprotege;
- un `.acept` perdido hace que LV-21 trate la licencia del disco como nueva (`EstadoLicenciaService.cs:290-292`).

Un archivo bloqueado, en cambio, da `true` en `File.Exists` y lanza al leerlo, o sea, falla cerrada. Es la misma clase de defecto que RS-03.

La probabilidad es baja: la DACL protegida da control total a SYSTEM, a Administradores y a la identidad que la creó (`AlmacenLicenciaDisco.cs:100-112`), así que hace falta una DACL alterada en el archivo.

**Evidencia:** `AlmacenLicenciaDisco.cs:170-171`; `ReproteccionSecretos.cs:146`, `:152` y `:165-166`.

**Remediación (≈0,1 dp + 1 prueba).** El mismo patrón que `Listar`: leer dentro de un `try`; `FileNotFoundException` y `DirectoryNotFoundException` dan `null`; el resto se propaga. En la API eso hace que el arranque falle cerrado con un archivo ilegible, coherente con RS-03 y RSV-08.

**Recomiendo que entre en este PR**, porque cierra la misma clase de defecto con un cambio pequeño. No bloquea.

### RSV-05 (Baja) — `ComandosAnillo.DiscoLicencia` decide con `Directory.Exists`

**Riesgo.** Si el técnico no ve la carpeta de la licencia, `_discoLicencia` queda en `null` (`ComandosAnillo.cs:82`). Entonces `--revocar-heredadas` omite `ConLlavesDisco` (`MantenimientoAnillo.cs:151`) y la reprotección omite el disco (`:252`), todo en silencio.

El archivo `padron` sí falla cerrado (`ReproteccionSecretos.cs:125-128`), pero solo si existe. *Inferido:* con la carpeta padre `%ProgramData%\GPOS NG` legible, `Directory.Exists` suele dar `true`, así que la probabilidad es baja.

**Evidencia:** `ComandosAnillo.cs:79-83`.

**Remediación (≈0,05 dp).** Construir siempre `AlmacenLicenciaDisco(carpeta)`. Con RS-03 y RSV-04, una carpeta inexistente ya da vacío y `null`, y una ilegible lanza. Así el `null` queda solo para las pruebas.

**Recomiendo que entre en este PR.**

### RSV-06 (Baja) — Regla «valor sin encabezado = dependiente» (pregunta 2)

**Valoración.** Fallar cerrado es correcto y lo mantengo:
- es coherente con `ConLlavesAsync` (`ReproteccionSecretos.cs:88-90`);
- evita decidir sobre un valor que no se entiende;
- un sello `Protect(byte[])` legítimo siempre lleva el encabezado.

La denegación del mantenimiento con un `UPDATE` de basura no preocupa. Exige escritura en `GPOS_SYSDATA.Configuracion` o `dbo.Usuarios`, y con eso el atacante ya puede hacer cosas peores: borrar el ancla o invalidar todos los sellos. El efecto es solo bloquear un verbo del técnico, con un mensaje explícito.

En rigor, un valor sin encabezado no depende de ninguna llave, porque ya no abre con ninguna. Por eso conviene que el técnico sepa qué tipo de pendiente tiene.

**Evidencia:** `ReproteccionSecretos.cs:112`, `:114` y `:131`.

**Remediación (≈0,1 dp; puede esperar).** Contar por separado «con una llave a revocar» e «ilegible (sin encabezado)». En el segundo caso, el mensaje indica el remedio: `sellos --legitimar` de la cuenta, o restaurar la fila. Sin valores ni códigos de cuenta en la salida; basta el recuento.

### RSV-07 (Baja) — Pruebas que faltan

**Qué cubren y qué no.** Las 12 pruebas cubren lo afirmado: fila, archivo y sello en los dos verbos; RS-02; RS-03 en el almacén y en el sellado inicial. Verificado: 36/0/0 en las tres clases. Faltan estos casos:
1. La 2.ª comprobación de `--cambiar-recuperacion` (`:189-192`): un sello escrito con la llave anterior después de `:182`, por ejemplo con un `IAlmacenLicenciaDisco` o un decorador de prueba que lo inserte al reproteger.
2. Archivo `padron` que existe y no se puede leer (rama `:125-128`).
3. Fila o sello sin encabezado.
4. RSV-01: `Procesados` ilegible en `--cambiar-recuperacion`, con el ancla sin cambiar.

**Antes del PR:** 2, 3 y 4 (≈0,2 dp). El 1 puede esperar.

### RSV-08 (Baja) — Efecto de RS-03 en el arranque de la API (pregunta 3)

**Valoración.** Aceptable. Una carpeta `Procesados` ilegible hacía que LV-21 ignorara licencias aceptadas del disco, o sea, fallaba abierta en INV-7. Además, la API ya no arrancaba con un archivo ilegible dentro de `Procesados` (`EstadoLicenciaService.cs:298-299`, `ReadAllBytesAsync`). Ahora la carpeta se comporta igual que sus archivos.

En la práctica, la carpeta es de la propia identidad de la API (DACL protegida), así que solo una DACL alterada o un fallo del disco la vuelven ilegible. Fallar cerrado ahí es lo esperado de la licencia.

`ConLlavesDisco` y `ReprotegerDisco` fallando cerrados en los verbos también es correcto, salvo el orden señalado en RSV-01.

El problema es de forma: `Program.cs:386` no traduce la excepción. El arranque muere con una `UnauthorizedAccessException` y su traza, sin evento propio.

**Evidencia:** `AlmacenLicenciaDisco.cs:158-168`; `EstadoLicenciaService.cs:240` y `:294-299`; `src/GPOS.Api/Program.cs:386`.

**Remediación (≈0,1 dp; puede esperar).** En `RestaurarDesdeDiscoAsync`, convertir `IOException` y `UnauthorizedAccessException` en `LicenciaArranqueException` («no se pudo leer la carpeta de la licencia; revise sus permisos»), con un evento crítico. La ruta puede ir en el registro del servidor; no es un dato sensible.

## 5. Controles bien implementados

- **La guarda cubre lo que RS-01 pedía:**
  - la fila `Licencia.PadronSellos`;
  - el archivo `padron`, buscado aunque la carpeta no exista (`ComandosAnillo.cs:39` y `:72-73`; `MantenimientoAnillo.cs:54-55`);
  - todos los `dbo.Usuarios.SelloHabilitacion`.

  Revisé los otros caminos y no tocan los ids de llave: no hay más `RevokeKey` que los dos (`:156` y `:193`), y `--recuperar` solo cambia la envoltura (`RecuperarAnillo.cs:16-27`).
- **`--revocar-heredadas` no tiene TOCTOU:** las heredadas nunca son la predeterminada (AN-02), así que nadie escribe con ellas entre la comprobación y la revocación.
- **La 1.ª comprobación de `--cambiar-recuperacion` va antes de cualquier efecto:** el ancla, las llaves, el estado y el evento. La prueba lo afirma, incluidos los archivos de llave sin cambios y sin `revocation-*.xml`.
- **Mensajes (pregunta 4):** solo nombran claves de configuración, el nombre del archivo y un recuento de sellos. No llevan valores protegidos, códigos de cuenta, rutas completas ni cadenas de conexión. El texto de SLF-01 (`SellosService.cs:174`) tampoco lleva ruta.
- **RS-03 bien resuelto en las decisiones:**
  - `InstalacionNoResellableAsync` trata el `null` como «hay licencias» (`SellosService.cs:358`);
  - el sellado inicial se niega (`:172-174`);
  - `Listar` solo traga `DirectoryNotFoundException`.
- **`IdLlave` valida la longitud mínima antes de leer el encabezado:** con menos de 20 bytes devuelve `null`, nunca lee fuera de rango.

## 6. Remediaciones priorizadas

**Antes de abrir el PR** (≈0,5 dp en total):
1. **RSV-01:** comprobación previa de legibilidad del disco antes de `:183`, excepciones de `ReprotegerDisco` a `Fallos` y mensajes de `:187` y `:191` con el estado real.
2. **RSV-07:** pruebas 2, 3 y 4.
3. **RSV-04 y RSV-05**, recomendados: la misma clase que RS-03 y unas pocas líneas.

**Después del PR, antes del primer cambio real de recuperación:**
4. **RSV-02:** API detenida, por procedimiento (devops) y, mejor, con control técnico (applock).
5. **RSV-03:** pieza de reprotección conjunta de padrón y sellos (arquitecto-maestro). Sin ella, la recuperación no se puede cambiar en instalaciones selladas.

**Puede esperar:** RSV-06, RSV-08 y la prueba 1 de RSV-07.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario). RS-01, RS-02 y RS-03 quedan cerrados en lo que pedían.

Sigue vigente la restricción operativa: **no cambiar la recuperación en una instalación sellada ni con la API en marcha** hasta resolver RSV-02 y RSV-03.

## Supuestos

- El comportamiento de caché del anillo de Data Protection en la API (refresco de hasta 24 horas, sin aviso entre procesos) es el documentado por ASP.NET Core; no lo medí en .NET 10.
- Se supone que el sellado de una instalación real va después de su migración desde DPAPI; si fuera al revés, `--revocar-heredadas` también queda bloqueado (RSV-03).
- La vuelta atrás de RSV-01 (configurar de nuevo la recuperación anterior y repetir el verbo) es inferida; no está ensayada.

## Decisiones candidatas a ADR

- **Reprotección conjunta de padrón y sellos** (RSV-03).
  - Opción: verbo transaccional con `UPDLOCK` del padrón, recálculo de huellas y disco después de confirmar.
  - Descartada: excluir los sellos y volver a sellar con `--resellar`, porque debilita SLF-01.
- **Persistir el estado de transición del cambio de recuperación** (RSV-01).
  - Opción: fila con MAC que el decorador de la API lee.
  - Descartada: dejarlo solo en memoria, que no admite reanudar.
- **Exclusión técnica «API detenida»** para los verbos del anillo que crean o revocan llaves (RSV-02).
  - Opción: `sp_getapplock` compartido en la API y exclusivo en el verbo.
  - Descartada: forzar el refresco entre procesos.

## Entregas a otros agentes

- **Desarrollador backend (A):** RSV-01, RSV-04, RSV-05 y RSV-07 en esta rama, antes del PR.
- **Arquitecto-maestro:** RSV-03 (pieza de reprotección conjunta), RSV-02 (control técnico de API detenida) y las tres candidatas a ADR.
- **Devops:** en el procedimiento de mantenimiento del anillo, detener la API y la de reportes antes de `--cambiar-recuperacion` y reiniciarlas después. Hasta RSV-03, el remedio ante una recuperación comprometida en una instalación sellada es un procedimiento con GSF.
- **qa-automatizado:** un ensayo de `--cambiar-recuperacion` con la API en marcha, para confirmar o descartar RSV-02.


---

## Relectura 2026-10-18 (correcciones `f8aa7a32` y `cfba2219` sobre `5df479b6`)

- **Alcance:** `git diff 5df479b6..cfba2219`. Solo lectura.
- **Contexto revisado:** todos los usos de `Leer`, `LeerTexto` y `Listar` en la API (`EstadoLicenciaService.cs:297`, `:313`, `:377`, `:705`, `:752` y `:759`; `ImportadorCarpetaEntrada.cs:20-44` y `:58-72`) y los usos restantes de `File.Exists` sobre el padrón.
- **Ejecutado:**
  - compilación de `tests/GPOS.Tests`: 0 errores;
  - `dotnet test --no-build` con `(MantenimientoAnilloTests|SellosReselladoTests|AlmacenLicenciaDiscoTests|Licencia)&Transicion!=Ola5&Transicion!=Defecto`: **533 correctas, 0 con error, 1 omitida** (la de siempre, `ReglaSecuenciaTests`);
  - `testhost.exe` borrado antes y después.
- **Sin verificar:** el 809/0/1 de la suite completa lo informa el desarrollador.
- **Estado de la rama:** el árbol de trabajo quedó en `a/rs-anillo-sellos @ cfba2219`, sin cambios. Durante la lectura lo dejé un momento en HEAD separado sobre ese mismo commit y lo devolví a la rama.

**Veredicto de la relectura: Aprobado con observaciones**, con una condición: **corregir RSV-09 antes de abrir el PR**. Es Media, pero es una regresión que introduce el propio RSV-04 en la API.

### Estado de los hallazgos anteriores

| ID | Estado | Evidencia |
|---|---|---|
| RSV-01 | **Cerrado** (residuo en RSV-11) | Se detalla abajo. |
| RSV-04 | **Cerrado** | `AlmacenLicenciaDisco.cs:174-187`: `SiExiste` solo traga `FileNotFoundException` y `DirectoryNotFoundException`. Prueba `RSV04_un_archivo_de_la_licencia_que_no_se_puede_ver_no_cuenta_como_ausente`. Efecto en la API: ver RSV-09. |
| RSV-05 | **Cerrado** | `ComandosAnillo.cs:80`: el almacén se construye siempre. Con la carpeta inexistente, `Procesados` da vacío y las lecturas dan `null`; `ReprotegerDisco` solo escribe lo que leyó, así que no crea nada. |
| RSV-07 (2-4) | **Cerrado** | Casos nuevos de la teoría: `archivo-ilegible`, `fila-sin-encabezado` y `sello-sin-encabezado`. Prueba `RSV01_cambiar_la_recuperacion_con_Procesados_ilegible_se_niega_sin_cambiar_el_ancla`: afirma el ancla, los archivos de llave y la ausencia de revocaciones. El caso 1 (2.ª comprobación) sigue pendiente, como estaba previsto. |

**Detalle de RSV-01:**
- `ExigirDiscoLegible` (`MantenimientoAnillo.cs:233-246`) recorre con `ConLlavesDisco` lo mismo que lee `ReprotegerDisco`: los tres protegidos y los `.acept` de cada licencia de `Procesados` (`ReproteccionSecretos.cs:146-155` frente a `:165-168`). Se llama antes de `FijarTransicion` y del ancla (`:185`) y en `--revocar-heredadas` (`:148`).
- Las excepciones de E/S de `ReprotegerDisco` pasan a `Fallos` (`:282-291`).
- Los mensajes de `:190` y `:194` usan `TrasCambiarElAncla` (`:226-228`), que describe el estado real sin rutas ni valores.

### Huecos de la comprobación previa frente a `ReprotegerDisco`

- **Lecturas:** ningún hueco. `ExigirDiscoLegible` y `ReprotegerDisco` recorren los mismos archivos.
- **Escrituras:** la comprobación previa no las cubre, porque es solo de lectura. Ver RSV-11.

### Hallazgos nuevos

#### RSV-09 (Media; regresión de RSV-04) — En la API, un archivo `estado` ilegible congela la instantánea de la licencia

**Riesgo.** `RefrescarAsync` lee `ArchivosLicencia.Estado` en cada refresco (`EstadoLicenciaService.cs:377`). Antes de RSV-04, un archivo ilegible daba `null` y el refresco seguía sin esa fuente. Ahora lanza la excepción.

`TrabajoLicencia` la atrapa y conserva la instantánea anterior (`ImportadorCarpetaEntrada.cs:62-71`: «La instantánea anterior se conserva»). No hay límite de antigüedad. `Estado`, `Permite`, `CodigoBloqueo` y `ExigirOperativa` leen los estados guardados en esa instantánea (`EstadoLicenciaService.cs:151-176`), y solo `Modulo` recalcula con la hora actual (`:198-207`).

Mientras la API siga en marcha, ni el vencimiento ni las gracias avanzan: es una **falla abierta en el tiempo** de toda la licencia. El arranque, en cambio, falla cerrado (`:241`).

En la licencia, el adversario es el administrador del servidor del cliente. Ese administrador puede negarle a la identidad de la API la lectura de un solo archivo, aunque la carpeta tenga la DACL protegida (Administradores tienen control total, `AlmacenLicenciaDisco.cs:100-112`). Mantener la API sin reiniciar durante semanas es plausible.

La misma clase de problema ya existía por otras vías (RSV-10). Este PR agrega una vía nueva y barata, y empeora lo que había antes: perder una fuente redundante pasa a ser congelar el estado.

**Evidencia:** `EstadoLicenciaService.cs:377`, `:151-176` y `:241`; `ImportadorCarpetaEntrada.cs:62-71`; `AlmacenLicenciaDisco.cs:184-187`.

**Remediación (≈0,15 dp + 1 prueba; antes del PR):**
1. En `RefrescarAsync`, envolver la lectura del archivo `estado` en un `try` para `IOException` y `UnauthorizedAccessException`. Ante una de ellas: registrar un evento crítico (`LicenciaFuenteIlegible`, sin la ruta en el mensaje al cliente) y tratar la fuente como **inválida**, como ya se hace con el piso de nivel (`FuentesInvalidas`, `:761-766`), sin abortar el refresco. Si `AGuardadas` y `Entorno` tienen una interpretación más restrictiva para «fuente inválida», usar esa.
2. En `TrabajoLicencia`, separar `importador.ProcesarAsync` y `RefrescarAsync` en dos `try`. Hoy un archivo ilegible en `Entrada` (`ImportadorCarpetaEntrada.cs:35`, ya existía) también impide el refresco.
3. **Prueba:** con `estado` ilegible, el refresco sigue y la empresa vence a su hora.

La interpretación no cambia en el resto de lugares, que fallan cerrados en momentos aceptables:
- el arranque (`:297` y `:313`; ver RSV-08);
- la carga dentro de la transacción (`:752` y `:759`): se rechaza y se deshace;
- la carga después de confirmar (`:705`): responde 500 al SUPER, con la licencia ya aceptada en la base y el disco atrasado. C-03 lo permite.

#### RSV-10 (Media; ya existía; para el arquitecto) — La instantánea de la licencia no tiene límite de antigüedad

**Riesgo.** Toda falla persistente del refresco congela el estado mientras la API corra. Por ejemplo:
- `DENY SELECT` sobre `dbo.Licencias` para el login de la API: falla `MaxIdAsync` (`:365`) y el resto de la aplicación sigue funcionando;
- un archivo ilegible en `Entrada` (`ImportadorCarpetaEntrada.cs:35`), que además nunca se mueve.

**Evidencia:** `ImportadorCarpetaEntrada.cs:62-71`; `EstadoLicenciaService.cs:121` y `:151-176`; `CalculadaUtc` existe en la instantánea (`:55`), pero nadie lo consulta.

**Remediación (≈0,3-0,5 dp).** Si `CalculadaUtc` tiene más de N intervalos (por ejemplo, 15 minutos), evaluar los estados con `MotorEstados` y la hora actual sobre la última cadena conocida. Si pasan más de X horas sin un refresco correcto, pasar a `SoloConsulta` con un evento crítico.

No bloquea este PR. **Alternativa descartada:** reiniciar la API ante la falla, porque el arranque fallaría cerrado y dejaría al cliente sin servicio.

#### RSV-11 (Baja; residuo de RSV-01) — Fallas de escritura después de cambiar el ancla

**Riesgo.** `ExigirDiscoLegible` solo lee. Si una escritura de `ReprotegerDisco` falla (sin permiso de escritura o disco lleno), la falla se registra en `Fallos`, pero el disco puede quedar a medias: algunos archivos con la llave nueva y otros con la anterior. Las llaves no se revocan y el mensaje es el correcto.

Además, una `SqlException` o `DbUpdateException` de `SaveChangesAsync` en `ReproteccionSecretosSistema.ReprotegerAsync` (`ReproteccionSecretos.cs:83`) sale después del ancla sin el texto `TrasCambiarElAncla`. Esto ya existía.

**Evidencia:** `MantenimientoAnillo.cs:185-190` y `:278-291`.

**Remediación (≈0,1 dp; puede esperar):**
- en `ExigirDiscoLegible`, comprobar la escritura creando y borrando un temporal en `Carpeta` y en `Aceptaciones`;
- en `ReprotegerAsync` (Migración), atrapar `DbUpdateException` y `SqlException` y pasarlas a `Fallos`.

#### RSV-12 (Baja; ya existía) — Quedan `File.Exists` sobre el archivo `padron`

**Riesgo.**
- **Sellado inicial** (`SellosService.cs:179`): un `padron` ilegible en el disco cuenta como ausente. Solo es alcanzable en una instalación sin `SelloInicial`, sin padrón en la base y sin ninguna licencia aceptada nunca (`dbo.Licencias` es de solo inserción), así que el impacto es bajo.
- **Diagnóstico** `verificar` (`ComandoSellos.cs:164`): informaría «no verifica» en vez de «no se pudo leer».

**Remediación (≈0,05 dp; puede esperar).** El mismo patrón que `DiscoAsync` (`SellosService.cs:387-397`), que ya distingue «no se pudo leer».

### Resumen para abrir el PR

- **Antes de abrir:** RSV-09, los pasos 1 a 3.
- **Puede esperar:** RSV-10 (arquitecto), RSV-11, RSV-12 y lo que ya estaba diferido (RSV-02, RSV-03, RSV-06, RSV-08 y el caso 1 de RSV-07).
- **Restricción operativa vigente:** no cambiar la recuperación en una instalación sellada ni con la API en marcha.

**Entregas nuevas:**
- Desarrollador de A → RSV-09.
- Arquitecto-maestro → RSV-10, que puede ir a ADR: límite de antigüedad de la instantánea de la licencia, con reevaluación por hora y paso a `SoloConsulta`; alternativa descartada, el reinicio automático.


---

## Relectura RSV-09 (2026-10-18; commit `e55a7478` sobre `cfba2219`)

- **Alcance:** `git diff cfba2219..e55a7478`, es decir:
  - `EstadoLicenciaService.cs`: `:100`, `:379`, `:554-597`;
  - `ImportadorCarpetaEntrada.cs:61-80`;
  - la prueba nueva de `PersistenciaLicenciaTests`.
- **Contexto revisado:**
  - `FilasProtegidas.cs:151-160` (`AGuardadas`);
  - `MotorEstados.cs:139-146` (`MarcaMasRestrictiva`) y `:414` (`GraciaIlegible`);
  - `EstadoLicenciaService.cs:617-654` (`Entorno`).
- **Ejecutado:**
  - compilación;
  - `dotnet test --no-build` con `(Licencia|MantenimientoAnilloTests)&Transicion!=Ola5&Transicion!=Defecto`: **519 correctas, 0 con error, 1 omitida** (la de siempre);
  - `testhost.exe` borrado.
- **Sin verificar:** el 810/0/1 de la suite completa lo informa el desarrollador.
- **Estado de la rama:** el árbol queda en `a/rs-anillo-sellos @ e55a7478`, sin cambios.

**Veredicto: Aprobado con observaciones. RSV-09 queda cerrado y no bloquea abrir el PR.**

### ¿Falla cerrada? (verificado)

Hay que comparar el valor guardado en memoria con dos referencias: no tener archivo (`null`) y leer el archivo real.

**`AGuardadas`** (`FilasProtegidas.cs:158`):
- La marca es `min(fila, archivo)`, y se usa como origen de `GraciaIlegible` (`MotorEstados.cs:414`). Cuanto más antigua es la marca, antes termina la gracia, así que más antigua es más restrictiva.
- Frente a `null`: `min(fila, guardado) ≤ fila`, igual o más restrictivo.
- Frente al archivo real: el archivo solo lo escribe este servicio, después de la fila y con la misma hora (`:553-557`). El valor guardado es la última lectura buena, así que es igual o anterior al del disco, y por lo tanto igual o más restrictivo.

**Marca de entorno** (`:620-621`):
- Se toma la `PrimeraDeteccionUtc` más antigua. Una marca guardada solo puede adelantar el inicio de la gracia, nunca atrasarlo.
- Una marca ya resuelta que siga en el valor guardado no se arrastra cuando la lectura es correcta y coincide (`:653`). Si el entorno vuelve a cambiar, adelanta el inicio de la nueva gracia, lo que sigue siendo más restrictivo.

**Huella guardada** (`:622-623`, solo cuando falla la lectura de la huella):
- Se elige la de `Utc` mayor entre la fila y el archivo. La fila siempre es igual o más reciente que el valor guardado, por el orden de escritura.
- El único caso en que manda la del valor guardado es con la fila `Gracias` ilegible. Aun así, con lectura fallida, `:653` devuelve solo la marca previa, igual que con `null` (`:645`), y no puede ocultar un cambio de entorno que `null` sí mostraría.
- Un cambio de entorno real con la huella leída bien se detecta con la huella actual (`:628-632` y `:647-651`), con independencia del archivo.

**Conclusión:** el argumento del desarrollador es correcto. El valor guardado nunca es más permisivo que `null` ni que el archivo legible.

### EventId 4722

Lo busqué con `git grep` en `origin/feature/modelo-ng`, en todas las ramas remotas `a/`, `b/` y `c/` y en las locales, después de un `git fetch`.

- Ocupados: 4720 (`AnilloReintento`, del #59 y sus variantes) y 4721 (`EntornoLecturaFallida`, `HuellaEntorno.cs:26`).
- **4722 solo aparece en esta rama.** No hay colisión.

**Aviso para la unión:** cualquier evento nuevo del intervalo 47xx en otra rama abierta debe empezar en 4723.

### Los dos `try` de `TrabajoLicencia`

No ocultan nada:
- Antes, una falla del importador se registraba como «falló el refresco periódico» y además impedía el refresco.
- Ahora se registra en su propio `LogError`, con un texto que la distingue, y el refresco corre igual. El `catch` del refresco no cambió.
- Ninguno de los dos traga `OperationCanceledException`.
- No se pierde ningún efecto de falla cerrada: el importador no protegía nada al abortar el refresco.

### Escritura atrapada (`:554-563`)

La fila ya está confirmada cuando falla el disco. Seguir adelante con el evento es coherente con C-03 («el disco nunca adelanta a la base») y evita el congelamiento por esa vía. El mensaje del evento nombra el archivo y no la ruta. La ruta completa solo va en la excepción adjunta, en el registro del servidor, y eso es aceptable.

### Observaciones (no bloquean)

**RSV-13 (Baja; ya existía).** En el arranque, `_ultimoEstadoDisco` está vacío. Con `estado` ilegible, la licencia se evalúa sin el archivo y la API arranca: antes de RSV-09, el arranque fallaba cerrado.
- **Impacto real:** es el mismo que el de **borrar** el archivo, que el administrador del servidor siempre pudo hacer y que hoy tampoco se detecta. No es una exposición nueva frente a la base del #68.
- **El hueco de fondo:** la copia en el disco existe como defensa contra la restauración de una copia vieja de la base. Su ausencia, o su ilegibilidad, mientras exista la fila `Gracias` no se trata como «fuente ausente que debería existir», que es lo que hace RA-02 con el piso de nivel.
- **Remediación (≈0,1-0,2 dp; para después o para el diseño de la licencia):** con la fila `Gracias` presente y el archivo ausente o ilegible, emitir el evento y reescribir el archivo con los valores de la fila, como en RA-02.

**RSV-14 (Baja).** El aviso diario lo comparten la lectura y la escritura (`_ultimoAvisoEstadoIlegible`). Si falla primero la escritura, la falla de lectura del mismo día no genera un segundo evento. Es aceptable, porque el texto cubre las dos («leer o escribir»). No requiere cambio.

### Resumen

- RSV-09 queda cerrado.
- **No hay nada que bloquee abrir el PR.**
- Siguen diferidos: RSV-02, RSV-03, RSV-06, RSV-08, RSV-10, RSV-11, RSV-12, RSV-13 y el caso 1 de RSV-07.
- Sigue vigente la restricción operativa: no cambiar la recuperación en una instalación sellada ni con la API en marcha.
