# Informe de Seguridad: PR #29 y PR #30, `GPOS.Criptografia` y contratos de la licencia firmada

**Fecha:** 2026-10-14 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Fuentes revisadas**
- PR #29 `a/lic-l1a-1` @ `4c3d8760` → `feature/modelo-ng` @ `ad6015d7`
- PR #30 `a/lic-l1a-1-verificador` @ `1068bd36` → `a/lic-l1a-1`
- Árbol `GPOS-NG-lic`, leído con `git show` y `git diff ad6015d7..1068bd36` (21 archivos, +2 374 líneas)
- Referencias: `[BP2]` = `blueprint-licencia-lote2-2026-10-14.md` v2.1 (§3, §4.1 L1a-1, §5.2, §14), `[SEG]` = `revision-seguridad-blueprint-licencia-lote2-2026-10-14.md` (SEG-L2-18, -19 y -24), `[LIC]` = `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` §3.1, §3.1.1, §3.2 y §3.6

**Método:** no compilé ni ejecuté pruebas, por indicación del encargo. Las cifras de prueba (121/121 en Debug y en Release, 111/111 de arquitectura) son las que declara el PR #30 y **no las reproduje**. Las rutas citadas son relativas a la raíz del repositorio en `1068bd36`, salvo que se indique otro commit.

---

## 1. Alcance y superficie revisada

| Superficie | Exposición | Archivos |
|---|---|---|
| Verificador JWS (`[LIC]` 3.1.1, puntos 1 a 4, 6 y 9) | Recibe bytes **no confiables**: la carga manual L-03 (SUPER) y el archivo que baja el agente desde Drive (origen `AGENTE`) | `src/GPOS.Criptografia/Jws/VerificadorJws.cs`, `LectorJsonEstricto.cs`, `ContratosJws.cs` |
| Ancla de confianza (llaves públicas de GSF) | Interna. Integridad crítica: quien agrega una llave emite licencias | `Jws/ConjuntoLlaves.cs`, `Llaves/RecursoLlavesGsf.cs`, `Llaves/LlaveGsf.cs`, `Llaves/*.json`, `GPOS.Criptografia.csproj` |
| Punto 5 e identidad por contenido | Interna (función pura) | `src/GPOS.Core/Sistema/Licencia/ReglaSecuencia.cs`, `VerificadorJws.HuellaContenido` y `HuellaArchivo` |
| Contratos (DTO, códigos y formato) | Formas de respuesta de L-01 a L-07 y S-01 a S-04 (las rutas no existen todavía) | `src/GPOS.Contracts/Licencia/*.cs` |
| Repositorio | Secretos, llaves privadas y fin de línea | `.gitattributes` y todo el árbol |

**Fuera de alcance:** las reglas de aceptación (L1a-2), la persistencia y el registro en la API (L1a-4), el emisor (EM, otro repositorio) y el cifrador del anillo (H-17 v2).

---

## 2. Tabla resumen de hallazgos

No hay hallazgos Críticos, Altos ni Medios.

| ID | Severidad | Título | PR |
|---|---|---|---|
| CR-01 | Baja | `ConjuntoLlaves` no es inmutable: `Llaves` y `Buscar` entregan los arreglos internos de la llave pública | #29 |
| CR-02 | Baja | `kid` y `nivel` del encabezado sin forma ni largo: textos del atacante llegan a `KidsIgnorados` (y de ahí a bitácora y logs) | #30 |
| CR-03 | Baja | `VerifyData` sin captura de excepciones criptográficas: un caso límite daría 500 en lugar de 422 | #30 |
| CR-04 | Baja | La admisión de llaves de desarrollo depende de dos mecanismos distintos (`$(Configuration)` y el símbolo `DEBUG`) | #29 |
| CR-05 | Baja | `ReglaSecuencia` y las huellas son `string` sin tipo propio, y la excepción de SEG-L2-24 no queda anclada | #30 |
| CR-06 | Baja | `ResultadoJws` tiene un constructor público: cualquier código puede fabricar un resultado «válido» | #29 |
| CR-07 | Baja | La guarda LV-07 es una búsqueda de texto y no vigila la E/S ni las dependencias de `GPOS.Criptografia` | #30 |
| CR-08 | Baja | Huecos en los vectores negativos: `b64` en el encabezado no protegido, y `r`/`s` nulos o ≥ n | #30 |
| CR-09 | Baja | `RecursoLlavesGsf.Leer` puede lanzar `FormatException` en lugar de `InvalidDataException` (contrato de `DesdeRecurso`) | #30 |
| CR-10 | Baja | `EstadoLicenciaDto` es un solo DTO para USER y para roles altos: la reducción depende de dejar campos en null | #29 |
| CR-11 | Informativa | `InternalsVisibleTo("GPOS.Tests")` viaja en Release, sin llave pública | #29 |
| CR-12 | Informativa | Diferencia posible entre el lector estricto y el deserializador de L1a-2 (mayúsculas y minúsculas, duplicados) | #29/#30 → L1a-2 |

---

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Evidencia |
|---|---|---|
| A01 Control de acceso | **No aplica** a este código (no hay rutas). Los DTO marcan los campos de SUPER (R-E10, LV-18); ver CR-10 | `LicenciaDtos.cs:7-21` |
| A02 Fallas criptográficas | **Bien**, con observaciones. Solo ES256 (P-256 y SHA-256 de la biblioteca base, aprobados por FIPS 140-3), P1363 de 64 bytes, punto en la curva validado, sin parte privada. Nada casero. Ver CR-01 y CR-03 | `VerificadorJws.cs:131-137`, `ConjuntoLlaves.cs:91-106` |
| A03 Inyección | **Observación** CR-02 (log injection por `kid`). No hay SQL ni plantillas | `VerificadorJws.cs:208-211` |
| A04 Diseño inseguro | **Bien**. Falla cerrado (juego vacío o recurso dudoso), identidad por contenido (SEG-L2-18) y nivel tomado del recurso. Ver CR-05 y CR-06 | `VerificadorJws.cs:124-127`, `RecursoLlavesGsf.cs:23-47` |
| A05 Configuración | **Observación** CR-04 (Debug/Release) y CR-11 | `GPOS.Criptografia.csproj:19-26`, `LlaveGsf.cs:76-83` |
| A06 Componentes vulnerables | **No aplica**: sin paquetes nuevos (solo la biblioteca base) | `GPOS.Criptografia.csproj` |
| A07 Autenticación | **No aplica** | — |
| A08 Integridad de software y datos | **Bien**. Llaves solo desde un recurso incrustado, recurso de desarrollo solo en Debug, huella del recurso fijada en una prueba y `eol=lf`. Ver CR-01 y CR-07 | `RecursoLlavesGsf.cs:54-62`, `.gitattributes:75-76`, `RecursoLlavesGsfTests.cs:22,45-51` |
| A09 Registro y monitoreo | **Observación** CR-02 | — |
| A10 SSRF | **No aplica**: el verificador ignora `jku`, `x5u`, `jwk` y `x5c` y no hace E/S de red | `VerificadorJws.cs:197-213` |

### Checklist específico del encargo

| Punto | Resultado | Evidencia |
|---|---|---|
| Tope de 64 KB antes de interpretar | Verificado: `> 65 536` se rechaza antes de cualquier lectura; 65 536 exactos se interpretan | `VerificadorJws.cs:88-89`; prueba `VerificadorJwsTests.cs:100-119` |
| Lectura acotada del flujo | Verificado: el búfer es de 64 KB + 1 y no lee más de un byte de exceso. **Su uso en la ruta queda para L1a-4** (ver Entregas) | `VerificadorJws.cs:67-79` |
| JSON estricto sobre `Utf8JsonReader` | Verificado: sin comentarios ni comas finales, `MaxDepth = 8` y el bloque final rechaza los datos después de la raíz (`isFinalBlock` por omisión) | `LectorJsonEstricto.cs:15-28, 31-80` |
| Duplicados, también con escapes | Verificado: un conjunto de nombres por objeto, con `GetString()` (desescapa y compara en ordinal) | `LectorJsonEstricto.cs:58-62` |
| UTF-8 inválido | Verificado: `GetString()` sobre cada nombre y cada valor de texto, y captura de `InvalidOperationException` (también las sustitutas sueltas escritas con escape) | `LectorJsonEstricto.cs:60, 64, 75-79` |
| Contenedor, encabezado y contenido estrictos | Verificado: se aplica a los tres | `VerificadorJws.cs:149, 159-160, 200` |
| Solo la serialización general | Verificado: la raíz admite solo `payload` y `signatures`, y cada firma solo `protected`, `signature` y `header` | `VerificadorJws.cs:154-155, 170` |
| `alg`, `typ`, `kid` y `nivel` solo del encabezado protegido | Verificado: el encabezado no protegido que traiga `alg`, `kid`, `typ`, `nivel`, `crit` o `b64` rechaza el archivo. `alg == "ES256"` y `typ` exactos. Se rechazan `crit` y `b64` | `VerificadorJws.cs:40, 174-176, 204-208` |
| Base64url canónico | Verificado: alfabeto url, sin relleno, y la recodificación tiene que dar el mismo texto | `LectorJsonEstricto.cs:89-107` |
| P1363 de 64 bytes | Verificado: largo distinto de 64 → no verifica; `IeeeP1363FixedFieldConcatenation` explícito | `VerificadorJws.cs:131-137` |
| INV-9 | Verificado: un kid conocido, de la función y no retirado que no verifica (o con un `nivel` incoherente) rechaza el archivo. Desconocidos, retirados y de otra función se ignoran. Hace falta al menos una válida. Un kid repetido rechaza el archivo | `VerificadorJws.cs:103-125, 186` |
| Kid de desarrollo en Release | Verificado: se rechaza por prefijo **antes** de buscar la llave, aunque el juego no la conozca. `simularRelease` solo endurece (`Admitidas && !simular`). `Compilacion.Depuracion` es `const`: en Release el valor `false` queda fijo en el IL y ningún camino interno lo reabre. `InternalsVisibleTo` no abre ninguna vía hacia llaves de desarrollo en Release: tanto el constructor interno del recurso como `ConjuntoLlaves.Validar` las rechazan. Ver CR-04 y CR-11 | `VerificadorJws.cs:52, 96-97`; `LlaveGsf.cs:72, 76-83`; `RecursoLlavesGsf.cs:32-33`; `ConjuntoLlaves.cs:88-89` |
| `PlatformNotSupportedException` en puntos fuera de la curva | Verificado al importar (se captura junto con `CryptographicException`). Al verificar no hay captura (CR-03) | `ConjuntoLlaves.cs:99-106` |
| Solo un recurso incrustado; el de desarrollo solo en Debug | Verificado: `GetManifestResourceStream`, con el `EmbeddedResource` de desarrollo bajo `Condition == 'Debug'`. Ver CR-04 | `RecursoLlavesGsf.cs:54-62`; `GPOS.Criptografia.csproj:16-21` |
| INV-2 | Verificado: `aceptarHasta` solo en llaves `lic` de nivel `basico` | `ConjuntoLlaves.cs:80-82` |
| `DesdeRecurso` | Verificado: mismas reglas que el recurso, `desarrollo: false` siempre, sin `InternalsVisibleTo` hacia el emisor (L1-5) | `ConjuntoLlaves.cs:41-52` |
| Nada inyecta llaves desde configuración o disco | Verificado: el constructor de `ConjuntoLlaves` es interno, y desde fuera solo se puede restringir (`DeFuncion`, `ConRetiros`). `DesdeRecurso` es la única fábrica pública, y una prueba vigila que nadie la use en `src`. `GPOS.Criptografia` no usa `File`, `Directory`, `Environment` ni `IConfiguration` (búsqueda sin resultados). Ver CR-01 y CR-07 | `ConjuntoLlaves.cs:22, 68, 71`; `RecursoLlavesGsfTests.cs:234-246` |
| `HuellaContenido` frente a SEG-L2-18 | Verificado: SHA-256 de los bytes decodificados del `payload`, que la firma cubre. No depende de las firmas ni del contenedor JSON. La firma maleada (r, n − s) se documenta con un vector | `VerificadorJws.cs:58, 61`; `VerificadorJwsTests.cs:603-627` |
| `ReglaSecuencia` (punto 5) | Verificado: misma `sec` y mismo SHA-256 del contenido → recarga; otro contenido → 409. Ver CR-05 (SEG-L2-24) | `ReglaSecuencia.cs:31-39` |
| Contratos sin datos de más | Verificado, con la observación CR-10. `SolicitudLicenciaDto` declara «sin secretos ni conexiones» y cumple | `LicenciaDtos.cs` |
| Sin llaves privadas ni secretos en el repositorio | Verificado: los recursos `LlavesGsf*.json` están vacíos; no hay `.pem`, `.key`, `.pfx`, `.p12`, `.snk` ni `.jwk` en el árbol; no hay JWK con `"d"` ni bloques `PRIVATE KEY`. Las pruebas generan las llaves en memoria (`FabricaJws.cs:18`) | `git ls-tree` y `git grep` sobre `1068bd36` |
| `.gitattributes` | Verificado: `src/GPOS.Criptografia/Llaves/*.json text eol=lf` y `git check-attr` lo confirma. El blob de `LlavesGsf.json` usa LF, no tiene BOM, y su SHA-256 es `3e32777f…b662b`, igual al que fija la prueba | `.gitattributes:75-76`; `RecursoLlavesGsfTests.cs:22` |

---

## 4. Hallazgos

### CR-01 · Baja · `ConjuntoLlaves` no es inmutable

- **Riesgo:** el comentario promete «Inmutable» y «nadie puede cambiar la llave de un juego ya creado», pero `Copia` solo protege contra cambios en la **entrada**. `Llaves` y `Buscar` devuelven el registro interno, cuyo `ECParameters.Q.X` y `Q.Y` son los mismos `byte[]` que usa `VerificaFirma` en cada verificación. Cualquier componente con acceso a `IRecursoLlavesGsf.Efectivo` (el singleton de la API) puede cambiar en sitio la llave pública del ancla de confianza. Si es por error (por ejemplo, un diagnóstico que limpia o reutiliza búferes), ninguna licencia verifica. Si es a propósito, hace falta código propio dentro del proceso, que ya podría hacer cualquier otra cosa. Por eso es Baja, pero el contrato documentado es falso.
- **Evidencia:** `src/GPOS.Criptografia/Jws/ConjuntoLlaves.cs:55, 58, 117-125`; `VerificadorJws.cs:105, 135`. La prueba `RecursoLlavesGsfTests.cs:273-282` solo cubre la mutación de la entrada.
- **Remediación (≈ 0,1 dp):** guardar las coordenadas como `ImmutableArray<byte>` o `ReadOnlyMemory<byte>`, o devolver copias desde `Llaves`/`Buscar`. Otra opción es importar cada llave una vez en un `ECDsa` privado del juego y no exponer los arreglos. Agregar una prueba que mute el resultado de `Buscar` y compruebe que la verificación sigue igual.

### CR-02 · Baja · `kid` y `nivel` sin forma ni largo

- **Riesgo:** `kid` es texto libre del archivo, de hasta casi 64 KB, con saltos de línea y caracteres de control. Los kids desconocidos o retirados vuelven en `ResultadoJws.KidsIgnorados`, que L1a-4 registrará en el historial, la bitácora o los logs. El archivo puede llegar **sin autenticar** por el agente (origen `AGENTE`), así que el texto lo controla quien manipule el canal. El riesgo es de falsificación o saturación de registros (A09), no de aceptación.
- **Evidencia:** `VerificadorJws.cs:107-108, 113, 208-211`; `ContratosJws.cs:14-16`.
- **Remediación (≈ 0,05 dp):** en `LeerEncabezado`, exigir que `kid` cumpla `^[a-z0-9-]{1,32}$` y que `nivel` sea uno de los valores de `NivelesLlave`, o rechazar con `LICENCIA_FORMATO`. Agregar un vector negativo.

### CR-03 · Baja · `VerifyData` sin captura de excepciones criptográficas

- **Riesgo:** `VerificaFirma` no captura nada. En las plataformas de .NET 10, una firma de 64 bytes con `r` o `s` nulos o ≥ n debería devolver `false` [inferido: no lo verifiqué ni hay vector, ver CR-08]. Si un proveedor (CNG, OpenSSL o un proveedor FIPS) lanzara `CryptographicException`, la carga respondería 500 en lugar de 422. El archivo se rechazaría igual, así que no hay riesgo de aceptación, pero el código de error y la bitácora serían distintos.
- **Evidencia:** `VerificadorJws.cs:131-137`.
- **Remediación (≈ 0,02 dp):** `try { … } catch (CryptographicException) { return false; }` dentro de `VerificaFirma`. La firma inválida de un kid conocido sigue rechazando el archivo por INV-9.

### CR-04 · Baja · La admisión de llaves de desarrollo depende de dos mecanismos

- **Riesgo:** el recurso de desarrollo se incrusta cuando `$(Configuration) == 'Debug'`, mientras que el verificador y el juego admiten llaves de desarrollo cuando está definido el símbolo `DEBUG`. Con las configuraciones estándar coinciden. Una configuración propia (por ejemplo, `Beta` con `DEBUG` definido, o `Debug` con `DefineConstants` cambiado) los separa en silencio. El caso grave es la distribución de un binario Debug a un cliente (Demostración o Beta): ahí la llave `gsf-lic-dev`, que es de software y está en el equipo del desarrollador, firmaría licencias válidas en ese binario. La parte `anillo` de NV-05 (L1a-2) no lo cubre si el binario es Debug.
- **Evidencia:** `GPOS.Criptografia.csproj:19-21`; `LlaveGsf.cs:72, 76-83`.
- **Remediación (≈ 0,05 dp más devops):** (a) usar un solo criterio en el `.csproj`, por ejemplo `Condition="$(DefineConstants.Contains('DEBUG'))"`, o fallar la compilación si los dos difieren; (b) **devops:** la canalización de publicación exige `-c Release` y comprueba que el ensamblado publicado no tiene el recurso `…Desarrollo.json`. Es la inspección QA-L17 de NV-05 (a), que conviene automatizar.

### CR-05 · Baja · Huellas sin tipo propio y SEG-L2-24 sin anclar

- **Riesgo:** `HuellaContenido` y `HuellaArchivo` devuelven `string`, y `ReglaSecuencia.MismaSec` recibe `string`. Si L1a-2 o L1a-4 confunden una con otra, vuelve el problema de SEG-L2-18: una firma maleada o un contenedor con otros espacios daría otra «identidad». Además, `MismaSec` devuelve `RecargaIdempotente` aunque la carga traiga una firma de **nivel superior**. La excepción de SEG-L2-24 está diferida a L1a-2 y L1a-4 por `[BP2]` §5.2, pero ni el código ni sus pruebas la recuerdan.
- **Evidencia:** `VerificadorJws.cs:58, 61`; `ReglaSecuencia.cs:29-39`; `ReglaSecuenciaTests.cs`.
- **Remediación (≈ 0,05 dp):** (a) usar un tipo `readonly record struct Sha256Contenido(string Hex)` que solo cree `HuellaContenido` y que pida `ReglaSecuencia`; validar 64 caracteres hexadecimales; (b) agregar al `summary` de `MismaSec` una referencia explícita a SEG-L2-24 y una prueba omitida (`Skip = "SEG-L2-24, versión con llaves Avanzadas"`) que fije el caso.

### CR-06 · Baja · `ResultadoJws` con constructor público

- **Riesgo:** las reglas de aceptación de L1a-2 recibirán un `ResultadoJws`. Con el constructor público, cualquier código de `GPOS.Core` o de la API puede construir `new ResultadoJws(true, null, contenido, [new FirmaVerificada("gsf-lic-a1", "avanzado")], [])` y saltarse el verificador. Sería un error de programación, no un ataque externo. Hoy cuesta poco cerrarlo; después de L1a-2 cuesta más.
- **Evidencia:** `ContratosJws.cs:4, 15-20`.
- **Remediación (≈ 0,02 dp):** constructores `internal` para `ResultadoJws` y `FirmaVerificada`. Así solo el verificador los produce, y las pruebas los siguen viendo por `InternalsVisibleTo`.

### CR-07 · Baja · La guarda LV-07 es estrecha

- **Riesgo:** la prueba de arquitectura busca el texto `DesdeRecurso` en `src` fuera de `GPOS.Criptografia`. No vigila que **dentro** de `GPOS.Criptografia` nadie agregue una lectura de disco, del registro o de la configuración para las llaves. Tampoco vigila la promesa del `.csproj` de no referenciar `GPOS.Contracts` ni `GPOS.Core` ni paquetes. No encontré ninguna prueba de arquitectura que mencione `GPOS.Criptografia`.
- **Evidencia:** `RecursoLlavesGsfTests.cs:234-246`; `GPOS.Criptografia.csproj:9-12`. `git grep` de `Criptografia` en `tests/GPOS.Tests/Arquitectura` no da resultados.
- **Remediación (≈ 0,1 dp):** agregar una prueba de arquitectura que compruebe tres cosas: (a) el ensamblado `GPOS.Criptografia` solo referencia ensamblados del marco; (b) sus tipos no usan `System.IO.File`, `Directory`, `Microsoft.Win32.Registry`, `Environment.GetEnvironmentVariable` ni `Microsoft.Extensions.Configuration`; (c) solo `RecursoLlavesGsf` llama a `GetManifestResourceStream`.

### CR-08 · Baja · Huecos en los vectores negativos

- **Riesgo:** el código cubre los casos, pero sin vector una regresión pasaría desapercibida.
  - `b64` en el encabezado **no protegido** no tiene vector: la teoría prueba `alg`, `kid`, `typ`, `nivel` y `crit` (`VerificadorJwsTests.cs:302-312`).
  - No hay firmas de 64 bytes con `r = 0`, `s = 0`, `r ≥ n` o `s ≥ n`, ni de 64 bytes en cero. La teoría de largos solo prueba 63, 65 y 0 (`:401-411`). Esto confirmaría CR-03.
  - No hay duplicados con escapes en el **contenido** ni en el **encabezado protegido** (sí en el contenedor, `:142-148`). Es la misma función, así que el riesgo es menor.
  - Lo que sí dicen los vectores, y verifiqué: tamaño exacto y +1, flujo acotado, duplicados en el contenedor, en el contenido y en el encabezado, escapes, comentarios, comas finales, profundidad 8 y 9, datos tras la raíz, UTF-8 inválido, BOM, serialización compacta y plana, miembros desconocidos, `alg` y `typ`, `crit` y `b64` protegidos, más de 8 firmas, kid repetido, base64 con relleno, estándar o no canónico, DER, firma alterada, INV-9 en los dos órdenes, kids desconocidos, retirados y de otra función, nivel incoherente, desarrollo en Release (simulado y real en `#else`), firma maleada, ceros a la izquierda y vigencia de 201 días.
- **Remediación (≈ 0,05 dp):** agregar los tres grupos de vectores.

### CR-09 · Baja · `FormatException` en lugar de `InvalidDataException`

- **Riesgo:** `GetInt32()` sobre `"version": 1.0` o sobre un número fuera de rango lanza `FormatException`, que `Leer` no envuelve. En el arranque la API falla cerrada igual. En cambio, `DesdeRecurso` documenta solo `InvalidDataException`, y el emisor podría no capturar la otra.
- **Evidencia:** `RecursoLlavesGsf.cs:73`; `ConjuntoLlaves.cs:40`.
- **Remediación (≈ 0,01 dp):** `TryGetInt32(out var v) && v == 1` o rechazo con `Invalido("versión no admitida")`. Agregar el caso a `RecursosInvalidos`.

### CR-10 · Baja · `EstadoLicenciaDto` compartido entre USER y roles altos

- **Riesgo:** LV-18 limita al USER a un `Estado` reducido y a la `Franja`, pero el DTO tiene `Motivo`, `Vence`, `DiasRestantes`, `GraciaHastaUtc` y `Mensaje`. La reducción depende de que el código de la ruta los deje en null. Un descuido expone el motivo (por ejemplo, `LlaveRetirada` o `Entorno`) y las fechas a todo usuario. Pasa lo mismo con `LicenciaEmpresaDto.PisoNivelFirma`, que es solo del SUPER (R-E10).
- **Evidencia:** `LicenciaDtos.cs:7-10, 18-21`.
- **Remediación (≈ 0,05 dp):** un DTO propio para el USER (`EstadoLicenciaUsuarioDto(string Estado, bool Franja)`), o al menos una prueba de contrato en L1a-3/L1b que serialice la respuesta como USER y compruebe que solo vienen esos dos campos.

### CR-11 · Informativa · `InternalsVisibleTo` en Release

- `GPOS.Criptografia` concede sus miembros internos a cualquier ensamblado llamado `GPOS.Tests`, y lo hace también en Release. Verifiqué que no abre ninguna vía hacia llaves de desarrollo (ver el checklist). Lo único que permite es armar un juego con llaves arbitrarias **que no son de desarrollo**, y para eso hace falta código propio cargado en el proceso, con el que ya se puede hacer cualquier cosa. Lo dejo como informativo. **Devops:** que la publicación no copie `GPOS.Tests.dll` (ver Entregas).
- **Evidencia:** `GPOS.Criptografia.csproj:24-26`.

### CR-12 · Informativa · Diferencia entre lectores (para L1a-2)

- El lector estricto compara los nombres en ordinal: `vence` y `Vence` son dos miembros distintos y pasan. Si L1a-2 deserializa `ContenidoLicencia` con opciones que no distinguen mayúsculas (por ejemplo, `JsonSerializerOptions.Web`), los dos irían al mismo campo y ganaría el último. El contenido está firmado, así que es un riesgo de **diferencia entre el emisor y el verificador**, no de un tercero.
- **Remediación:** en L1a-2, opciones explícitas: `PropertyNameCaseInsensitive = false`, `NumberHandling = Strict` y, si la versión lo trae, `AllowDuplicateProperties = false`. Según mi conocimiento, .NET 10 agregó `AllowDuplicateProperties` a `JsonSerializerOptions` y a `JsonDocumentOptions` [inferido, por verificar en la versión instalada]. Si existe, conviene ponerlo también en `LectorJsonEstricto.OpcionesDocumento` como defensa en profundidad, sin quitar la comprobación propia.

---

## 5. Controles bien implementados

- **Orden del rechazo:** tamaño, después estructura, después desarrollo en Release y por último las firmas. El kid de desarrollo se rechaza por prefijo antes de buscar la llave, así que no depende de que el juego la conozca (`VerificadorJws.cs:88-97`).
- **El nivel se toma del recurso, nunca del encabezado.** Un encabezado incoherente rechaza el archivo antes de verificar la firma (`:117-118, 121`).
- **La función de la llave separa licencias y manifiesto (R-E1):** una llave `upd` cuenta como desconocida (`:32-35, 106`).
- **Entrada de firma según RFC 7515 §5.2** con los textos tal como vienen y validados en ASCII. No hay canonicalización (`:190`).
- **Base64url canónico:** cada valor tiene una sola escritura (`LectorJsonEstricto.cs:105-106`).
- **Ancla de confianza cerrada:** constructor interno, fábrica pública sin desarrollo, solo restricción desde fuera, sin parte privada, P-256 con nombre, coordenadas de 32 bytes, punto en la curva y kid único (`ConjuntoLlaves.cs`).
- **Recurso con modelo cerrado y estricto,** que falla cerrado al arrancar. La huella del recurso de producción está fijada en una prueba y es estable gracias a `eol=lf` (`RecursoLlavesGsf.cs`, `.gitattributes:75-76`).
- **Identidad por contenido (SEG-L2-18)** implementada y documentada con el vector de firma maleada. Se rechazó con criterio la regla de `s` bajo.
- **Ninguna llave privada en el repositorio:** todas las de prueba se generan en memoria.
- **FIPS:** solo ECDSA P-256 y SHA-256 de `System.Security.Cryptography`, sin implementación propia ni paquetes.

---

## 6. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | CR-06, CR-01 | Antes de unir el PR #29: son contratos, y después de L1a-2 cuestan más | ≈ 0,12 dp |
| 2 | CR-02, CR-03, CR-08, CR-09 | Antes de unir el PR #30 o en un PR de seguimiento antes de L1a-2 | ≈ 0,13 dp |
| 3 | CR-05, CR-07 | Antes de L1a-2 | ≈ 0,15 dp |
| 4 | CR-04 | `.csproj` ahora; la comprobación de la canalización la hace devops antes de la primera publicación | ≈ 0,05 dp más devops |
| 5 | CR-10, CR-12 | En L1a-2, L1a-3 y L1b | ≈ 0,05 dp |

Total aproximado: 0,5 dp del desarrollador L (±30 %).

---

## 7. Recomendación

| PR | Recomendación | Motivo |
|---|---|---|
| **#29** (`a/lic-l1a-1` → `feature/modelo-ng`) | **Aprobado con observaciones** | Sin hallazgos Medios o superiores. CR-01 y CR-06 son baratos y conviene hacerlos antes de unir; CR-04, CR-10 y CR-11 son observaciones |
| **#30** (`a/lic-l1a-1-verificador` → `a/lic-l1a-1`) | **Aprobado con observaciones** | Cumple `[LIC]` 3.1.1, puntos 1 a 4, 6 y 9, INV-2, LV-07, L1-5 a L1-7 y SEG-L2-18. Sin hallazgos Medios o superiores. Quedan CR-02, CR-03, CR-05, CR-07, CR-08 y CR-09 |

Es una recomendación técnica. La decisión de unir la toma el propietario (C2).

---

### Cierre
- Estado: Aprobado con observaciones (PR #29 y PR #30)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr29-pr30-criptografia-2026-10-14.md`
- Supuestos: los resultados de compilación y de pruebas son los que declara el PR #30 (no los ejecuté, por indicación); que `VerifyData` devuelva `false` con `r`/`s` fuera de rango es inferido; la existencia de `AllowDuplicateProperties` en .NET 10 es inferida.
- Decisiones candidatas a ADR: Ninguna (CR-04 precisa la implementación de NV-05; no es una decisión nueva).
- Entregas a otros agentes:
  - desarrollador-backend (L): CR-01 a CR-03, CR-05 a CR-09 en L1a-1; CR-12 en L1a-2; en L1a-4, leer el cuerpo con `LeerConLimiteAsync` (o fijar `MaxRequestBodySize` en 64 KB en la ruta) y no con un `IFormFile` sin límite.
  - devops: CR-04 (b), la publicación solo con `-c Release` y la comprobación automática de que el ensamblado no trae `LlavesGsf.Desarrollo.json` (QA-L17); CR-11, que la salida publicada no incluya `GPOS.Tests.dll`.
  - qa-automatizado: los vectores de CR-08 y la prueba de contrato de CR-10.
- Próximo paso recomendado: que el desarrollador L aplique CR-06 y CR-01 en el PR #29 y el resto en el PR #30 o en uno de seguimiento antes de empezar L1a-2.
