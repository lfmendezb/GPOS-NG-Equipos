# Revisión de seguridad de DAT-D1, revisión 3 (DB-7, acceso multiempresa) · PR #167

- **Fecha:** 2026-10-22 · **Revisor:** auditor-seguridad (equipo A) · **Modo:** solo lectura. No se compiló, no se ejecutó SQL, no se cambió de rama ni se tocó el repositorio.
- **Fuentes** (`git show origin/b/dat-d1-rev3:<ruta>`, `fb58e286`):
  - **DAT**: `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` (1426 líneas). Las líneas citadas son las de esa versión.
  - **PLAN**: `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md`.
  - **HOJA**: `docs/decisiones/2026-10-22-hoja-firma-p-d1-06-y-h-13.md`.
  - El diff de la revisión 3 se tomó contra `942e2d63`, el padre de la cadena del PR. El `...` contra `feature/modelo-ng` muestra los archivos enteros porque la rama sale de `master`.
  - Código de contraste: `origin/feature/modelo-ng`. La búsqueda de números se hizo en todas las ramas de `origin`.
- **Revisión anterior:** `traspasos/A/revision-seguridad-diseno-d1-db7-2026-10-21.md` (**REV-A**, D1-01 a D1-15).
- **Convención:** [V] verificado en el texto o en el código citado. [I] inferido o pendiente de comprobar en el PR.

## 1. Veredicto

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

- No hay hallazgos Críticos ni Altos. Quedan 3 Medios y 6 Bajos.
- La revisión 3 cierra bien D1-06 y la parte de datos de D1-01 y D1-02.
- Tres condiciones deben estar en los PR:
  - **R3-01** antes de unir T1-1;
  - **R3-02** y **R3-03** antes de unir T1-4.
- Si T1-4 se une sin R3-02, D1-03 sigue abierto y la recomendación para ese PR pasa a **Rechazado**, por el mismo motivo de REV-A §7: un sobreacceso ADMIN quedaría registrado como legítimo en una instalación real.

## 2. Cierre de las condiciones D1-01 a D1-06

| ID | Estado | Evidencia | Qué falta |
|---|---|---|---|
| D1-01 | **Cerrada** (diseño) | Las rutas responden 503 `ACCESOS_NO_CONVERTIDOS` sin la marca (PLAN:222 [V]). Precondición 10 con cuatro tablas y 51622, primero en la vista previa y después bajo `TABLOCKX, HOLDLOCK` en el paso 1 (DAT:1197-1213 [V]). Gana la precondición 1 (DAT:1197 [V]) | P-D1-05 (etiqueta) sigue **pendiente de firma** (PLAN:540 [V]). No bloquea: el 503 cierra por sí solo la ventana anterior a T1-5 |
| D1-02 | **Parcial**: cerrada en la decisión, abierta en el detalle | Opción (a) firmada (HOJA, fila P-D1-06 [V]). Marca `MEMBRESIA.v1-sin-sello` la última, en la misma transacción. `ConversionAccesos` con `DENY SELECT/INSERT/UPDATE/DELETE` para `gpos_api` (DAT:1060-1066, :1094, :1216-1229 [V]) | El formato y el propósito de la protección de `Membresias` quedan para «el arquitecto de software con D3» (DAT:1226 y S-13 [V]): R3-03. La marca vive en una tabla que la API escribe: R3-04. La instantánea no la verifica Q23: R3-05. PLAN:257 todavía dice «Falta elegir (P-D1-06)» [V] |
| D1-03 | **Parcial** | Rechazo con 51622 antes del paso 0. Vista previa por empresa (DAT:1233-1249 [V]), con la misma regla que Q23 (DAT:541-549 frente a :1236-1247 [V], coinciden) | La guarda prevista no falla cerrada sin licencia vigente: R3-02. La cita `Program.cs:441-442` está desactualizada: hoy esas líneas son `MapCambioRnc` y `MapEventosServidor` [V]. La confirmación escrita (número de empresas o `DEMO`) no está diseñada: se delegó como Q-V2-08 (DAT, 11 b.3 [V]) |
| D1-04 | **Cerrada** (en PLAN) | Condición y prueba de arquitectura en T1-2 (PLAN:190 y :204 [V]) | Comprobarla en el PR de T1-2 |
| D1-05 | **Cerrada** (en PLAN) | Evaluador como lista blanca y pruebas para USER, ADMIN y SUPER (PLAN:191 y :198 [V]) | La regla de ADR-35 para el SUPER en una empresa inhabilitada sigue sin texto («o la regla de ADR-35», PLAN:191 [V]). Debe fijarse antes del PR de T1-2 |
| D1-06 | **Cerrada** | `IF UPDATE(UsuarioCodigo) OR UPDATE(EmpresaCodigo) THROW 51619` después del `RETURN` con `inserted` vacío. El emparejamiento posterior es por la PK, ya fija (DAT:853-863 [V]). C-10 y pruebas del intercambio, de `SET k = k` y de cero filas (DAT:172 y :1181 [V]) | Nada |

**Las Bajas de REV-A**:
- **D1-07 y D1-12:** siguen **abiertas** y se aplazan de forma explícita (DAT, 11 b.4 [V]).
- **D1-08, D1-09, D1-10, D1-11, D1-13 y D1-15:** no figuran como condiciones en PLAN (búsqueda en PLAN: 0 menciones [V]). D1-11 aparece solo en DAT:1249. Hay que agregarlas a las condiciones de T1-2, T1-3 y T1-4 del PLAN para que no se pierdan.
- **D1-14:** se aplica a `ConversionAccesos`: la prueba es solo en Estricto (DAT:1099 y :1191 [V]).

## 3. Checklist OWASP (solo lo que cambia en la revisión 3)

| Categoría | Estado | Nota |
|---|---|---|
| A01 Control de acceso | Observaciones | `DENY` total de `ConversionAccesos` a `gpos_api` [V]. R3-04: la marca sigue en una tabla que la API escribe |
| A02 Fallas criptográficas | Observaciones | R3-03: falta el vínculo de la instantánea protegida |
| A03 Inyección | Correcto | El SQL dinámico del bloque 5 b concatena solo constantes del código (`@texto` y `@nombre` salen de `@ck`, DAT:980-1031 [V]). El caso viaja como `varchar(30)` con parámetro (DAT:193 [V]). Los comodines y los corchetes de `LIKE` quedan fuera del alfabeto (DAT:985 [V]) |
| A04 Diseño inseguro | Observaciones | R3-02 y R3-05 |
| A05 Configuración | Observaciones | D1-14 sigue vigente: en Amplio la API puede deshabilitar las `CHECK` del caso. La reaplicación las restituye porque exige `is_disabled = 0` y `is_not_trusted = 0` (DAT:1009-1013 [V]) |
| A06 Componentes | No aplica | Sin paquetes nuevos |
| A07 Autenticación | Observaciones | R3-09: el ingreso del SUPER debe fallar cerrado si no se registra |
| A08 Integridad | Observaciones | La comparación de definiciones contra una plantilla y el 51627 son un buen control (DAT:988-1033 [V]). R3-01 |
| A09 Registro y monitoreo | Observaciones | R3-06 (rechazos del verbo sin evento) y R3-07 (retención) |
| A10 SSRF | No aplica | Sin llamadas salientes |

## 4. Análisis pedido

**(1) CS-P2 y H-13: evasión, inyección y repetición.**
- **Inyección:** no la hay [V]. El texto de las `CHECK` es constante. `NumeroCaso` es `varchar(30) COLLATE Latin1_General_BIN2`, de modo que `[A-Z]` no admite minúsculas ni acentos.
- **Largo y espacios:** `DATALENGTH` cuenta los espacios finales (DAT:138 [V]). Con 31 caracteres da 2628 o 547 (DAT:1184).
- **Evasión 1, el texto que manda:** el bloque 5 b, que es el texto que se va a construir, **no tiene la regla firmada de H-13** (R3-01).
- **Evasión 2, el truncado:** un `SqlParameter` con `Size = 30` trunca en silencio [I] (DAT:193). Por eso la validación de C# es obligatoria y debe correr **antes** de armar el parámetro.
- **Evasión 3, la normalización:** el orden «recortar → `ToUpperInvariant` → solo ASCII» (DAT:193 [V]) convierte en ASCII algunos caracteres que no lo son. Por ejemplo, U+0131 «ı» pasa a «I» y U+017F «ſ» pasa a «S» [I]. Así, un texto tecleado que no es ASCII acaba guardado como un caso válido. Impacto bajo; la corrección va en R3-01.
- **Repetición:** es posible y está **aceptada por diseño**. No hay unicidad, y CS-09 propone de nuevo el último caso usado (ADR-092.md:66 [V]). La base garantiza la forma del caso, no que exista. El control real es detectivo: CS-07 (el ADMIN lo ve) y CS-05 y CS-06 (cierre y urgencias abiertas, fase CS-2). Riesgo residual aceptado por ADR-92 (ADR-092.md:91 [V]). Recomendación, fuera de D1: en D2, rechazar un caso **cerrado** (CS-P3) como justificación de un ingreso nuevo.

**(2) Conversión, marca y `ConversionAccesos`.**
- **Atomicidad, correcta [V]:**
  - Una sola transacción `SERIALIZABLE` con `XACT_ABORT`.
  - La instantánea va antes de la marca, en el mismo paso 9 (DAT:1216-1224).
  - La precondición 10 se repite bajo `TABLOCKX`.
  - Una base a medio convertir no puede quedar con la marca puesta: o se confirma todo o se revierte todo.
- **Idempotencia, correcta en el camino normal [V]:** con la marca, en cualquiera de sus valores, el verbo sale con código 0 (DAT:645 y :1230). Con filas previas, 51622.
- **Camino anómalo (R3-04):** la marca está en `Configuracion`, que `gpos_api` puede escribir y borrar por S1 (DAT:1227 [V]).
  - Marca sin instantánea: el verbo responde «ya convertido» con código 0.
  - Instantánea sin marca: la precondición 10 la detecta, pero el reverso 7.4 borra `ConversionAccesos` sin preguntar (DAT:1148 [V]).
- **Sellado en D3:** puede saltarse o aplicarse a la instantánea equivocada si la protección no la vincula a su conversión (R3-03).

**(3) Disparadores, `CHECK`, `DENY` y SQL dinámico.**
- 51619 está bien (D1-06).
- El bloque 5 b toma la tabla, comprueba las filas y después hace `DROP` y `ADD`, todo en una transacción. Si hay filas que no cumplen, el 51627 deja en su sitio la `CHECK` anterior. Así se falla cerrado (DAT:1015-1031 [V]).
- La plantilla en una tabla temporal no pide permisos (DAT:1077 [V]).
- Si la normalización difiere (S-9 [I]), la `CHECK` se recrea en **cada** arranque, con `TABLOCKX` y un recorrido de la bitácora (de 1 a 3 s con un millón de filas, DAT:1075 [I]). Es un problema de disponibilidad, no de seguridad, y lo vigila la prueba de reaplicación (DAT:1183).
- `gpos_api` no recibe permisos nuevos (DAT:1099 y :1268 [V]).

**(4) Bitácora.**
- Es de solo inserción (`DENY UPDATE, DELETE`, 52001).
- El caso va en todos los eventos del verbo (DAT:1251 [V]).
- El número de caso no es un dato personal según CS-07 (DAT:106 [V]).
- Huecos: R3-06 (los rechazos del verbo no dejan evento), R3-07 (retención indefinida de la instantánea) y R3-09.

**(5) Números y marcas.**
- Sin colisiones [V] (búsqueda en `src`, `database` y `tests` de todas las ramas de `origin`):
  - 51619 a 51644: 0 usos.
  - 51618: lo usa `ComandosCambioRnc.ErrorOtroCambio`, que está fuera de D1 y no colisiona.
  - 51639 y 51640: reservados por el diseño de las vistas de impresión de Ola 5 (`docs/datos/2026-10-19-ola5-vistas-imp-ddl.md:43` [V]).
  - `EsquemaSistema.Version`: el máximo es 5 en todas las ramas, así que el 6 está libre.
- Hay datos desactualizados: R3-08.

## 5. Hallazgos nuevos

### R3-01 · Media (condición para unir T1-1) · H-13 firmada, pero el texto normativo de D7-A no la incorpora
- **Evidencia:**
  - La constante `@ckCaso` del bloque 5 b sigue siendo la de antes, sin `LIKE '%[A-Z0-9]%'` ni `NOT LIKE '-%'` (DAT:982-985 [V]).
  - El texto firmado aparece solo como ejemplo en 11 b.1, que todavía se titula «(propuesta)» (DAT:1326 y :1339-1345 [V]).
  - La tabla 3.1 dice «es solo una propuesta» (DAT:138 [V]).
  - El encabezado dice que «dos puntos esperan decisión» (DAT:3 [V]).
  - La prueba `CK_Caso_rechaza_alfabeto_y_largo_invalidos` no incluye `------`, `-ABC12` ni `--MOTIVO` (DAT:1184 [V]). PLAN:172 describe la `CHECK` sin H-13 [V].
  - La validación de C# (DAT:193) no repite la regla de H-13 [V].
- **Escenario:** el desarrollador construye T1-1 desde el bloque 5 b, que es el texto «para construir», y las pruebas quedan en verde. La base acepta `--MOTIVO` como número de caso de un `INGRESO_SUPER` o de `accesos --convertir`, porque el analizador tomó una opción como valor. El ingreso queda sin un caso que enlace con un hilo de correo, que es justo lo que H-13 prohíbe. La autorización humana firmada no tiene control técnico.
- **Remediación (unos 0,05 d):**
  - Sustituir `@ckCaso` en DAT:982-985 por el texto de 11 b.1 y quitar «propuesta» de DAT:3, :138 y :1326.
  - Agregar a la prueba de DAT:1184 los casos `------`, `-ABC12` y `--MOTIVO`, que deben rechazarse, y `A-----`, que debe aceptarse.
  - Escribir en DAT:193 que C# aplica la misma regla y comprueba que todo sea ASCII **antes** de `ToUpperInvariant`.
  - Actualizar PLAN:172.

### R3-02 · Media (condición para unir T1-4) · La guarda del modo DEMO no falla cerrada sin licencia vigente
- **Evidencia:**
  - DAT:1233 [V] remite a «la misma función con la que la API se niega a arrancar en Amplio» y reconoce que no la verificó.
  - Esa comprobación está en `EstadoLicenciaService.ArrancarAsync` y es `_instantanea.Vigente?.Contenido.Anillo is Produccion or Beta` (`src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:425-426` [V]). Con `Vigente` en NULL, la condición es falsa y la guarda **deja pasar**.
  - Además, es un método de instancia del servicio de la API, que trabaja sobre la instantánea en memoria, y no una función que `GPOS.Migracion` pueda reutilizar [V].
- **Escenario:** en la instalación de un cliente con licencia de Producción vencida, o con la carpeta de licencias ilegible para la identidad de `GPOS.Migracion` [I], no hay licencia vigente. Un técnico ejecuta `accesos --convertir --instalacion-demo`, y todas las cuentas con nivel global ADMIN quedan como ADMIN de **todas** las empresas habilitadas (DAT:543-547 [V]). Es el sobreacceso de H-01 y H-02, que D3 sellaría desde la instantánea.
- **Remediación (unos 0,15 d):**
  - Usar una lista blanca, no una lista negra: `--instalacion-demo` solo con una licencia **leída y verificada** (firma comprobada) del anillo `Desarrollo` o `Demostracion` (`FormatoLicencia.cs:38-39` [V]).
  - Sin licencia legible, vencida o de otro anillo, 51622.
  - Además, se rechaza si alguna vez hubo una licencia de Producción o Beta en la instalación (historial de la licencia en `GPOS_SYSDATA`) [I].
  - Diseñar en el PLAN la confirmación escrita de Q-V2-08: `--confirmar DEMO:<n.º de empresas>`.
  - Corregir la cita a `EstadoLicenciaService.cs:425`.
  - Prueba: `…Modo_DEMO_sin_licencia_vigente_se_detiene_con_51622`.

### R3-03 · Media (condición para unir T1-4) · Instantánea protegida sin vínculo con su conversión: se puede reemplazar por otra
- **Evidencia:** `Membresias` va «protegido con el anillo», pero el propósito y el formato se dejan para D3 (DAT:1226 y S-13 [V]). `PadronV1` se copia «tal cual» (DAT:1220-1222 [V]). D3 sellará «desde `PadronV1` y `Membresias`, nunca desde las filas» (DAT:1229 [V]).
- **Escenario:**
  - Alguien con DML sobre `GPOS_SYSDATA` reemplaza la fila de `ConversionAccesos` antes de D3. Puede ser `dbo`, o la API en Amplio, que tiene `CONTROL` (D1-14).
  - Usa la fila de una copia de la base restaurada en la misma instancia, donde se convirtió en modo DEMO o con `Usuarios` alterado. Como la copia comparte el anillo y el `InstalacionId`, la protección es válida [I].
  - `--completar-sellos` sella entonces ese sobreacceso como legítimo. Es precisamente lo que ADR-83, punto 2, quiere impedir: que alguien con permisos sobre la base pero sin las llaves fabrique accesos.
- **Remediación (unos 0,1 d de diseño; T1-4 la fija aunque D3 la consuma):**
  - El propósito incluye `InstalacionId`, `MomentoUtc`, `Modo`, el SHA-256 de `PadronV1` y un identificador de la base (`database_guid` [I]).
  - El SHA-256 del texto protegido va además en `ValorNuevo` de `ACCESOS_CONVERTIDOS_INSTALACION` (bitácora de solo inserción) como segunda referencia.
  - D3 comprueba las dos cosas antes de sellar.
  - Decidir esto en el PLAN de T1-4, no en D3: si llega tarde, las bases convertidas en D1 se quedan con un formato sin vínculo.

### R3-04 · Baja · Marca en una tabla que la API escribe, y sin comprobación de coherencia con la instantánea
- **Evidencia:**
  - `gpos_api` escribe `Configuracion` por S1 (DAT:1227 [V]). Hay escritores con clave por parámetro (`ConsultasSellos.cs:31-35` [V]).
  - La precondición 1 solo mira la clave (DAT:1230 [V]).
  - El reverso no mira `ConversionAccesos` ni `ConversionReportes` y las borra (DAT:1119-1124 y :1148 [V]).
- **Escenario:**
  - Un fallo de la API, o una identidad comprometida, borra `Accesos.Modelo`. En una instalación sin cuentas que no sean SUPER, la conversión no deja membresías, así que el reverso pasa y borra la instantánea, que es la única evidencia que D3 necesita.
  - Al revés: una marca insertada sin conversión hace que el verbo responda «ya convertido» con código 0, y se abren las rutas de T1-3 en una base sin convertir. No escala privilegios, porque esa identidad ya tiene DML, pero sí engaña al operador.
- **Remediación (minutos):**
  - La precondición 1 y el arranque exigen que la marca y la fila de `ConversionAccesos` existan **las dos o ninguna**. Si no, 51622 «estado de conversión incoherente», nunca código 0.
  - El reverso se niega si `ConversionAccesos` o `ConversionReportes` tienen filas.
  - D3 toma como fuente de verdad `ConversionAccesos.SellosCompletadosUtc` (con `DENY` para la API), no el valor de la marca.

### R3-05 · Baja · Q23 no verifica la instantánea
- **Evidencia:** `@membresias` se arma en C# a partir de «cada membresía creada en el paso 3» (DAT:1226 [V]). Q23 compara las tablas con la regla (E1, DAT:551-562), no con la instantánea [V].
- **Escenario:** un error en C# hace que la instantánea no coincida con las filas validadas. D3 sella desde la instantánea, lo que falla cerrado en Q1 si el sello no coincide [I], o sella un nivel distinto del que Q23 aprobó.
- **Remediación:** construir `@membresias` con un `SELECT` sobre `UsuariosEmpresas` **después** de Q23, dentro de la transacción, o agregar a Q23 un chequeo E9 de la instantánea antes de protegerla contra la tabla.

### R3-06 · Baja · Los rechazos del verbo no dejan evento en la bitácora
- **Evidencia:** el fallo del verbo solo va a `ILogger` con 4739. El evento en la bitácora queda «si el arquitecto lo quiere» (DAT, 11 b.3, Q-V2-16 [V]).
- **Escenario:** un intento de `--instalacion-demo` con licencia de Producción, rechazado con 51622 (justo el control detectivo de D1-03), o un 51621 de equivalencia, solo queda en un registro local rotativo. No aparece en la bitácora que revisan el SUPER y el ADMIN.
- **Remediación:** agregar `ACCESOS_CONVERSION_RECHAZADA` (`SISTEMA`, con el caso, el motivo cerrado y sin texto libre) al catálogo **en T1-1**, porque el catálogo es cerrado. Se escribe fuera de la transacción (SD0-07).

### R3-07 · Baja · Retención indefinida de la instantánea (Ley 172-13)
- **Evidencia:** «`ConversionAccesos` no se purga» (DAT:1260 [V]). Guarda códigos de cuenta (identifican empleados), niveles y sucursales, además del padrón v1.
- **Riesgo:** conservar sin plazo datos personales que ya no hacen falta después de D3, en contra del principio de minimización.
- **Remediación:** cuando `--completar-sellos` termina, `Membresias` y `PadronV1` se sustituyen por sus SHA-256 en la misma transacción. Así sigue habiendo evidencia, sin los datos. Queda anotado para el diseño de D3.

### R3-08 · Baja (documental) · Numeración y marcas desactualizadas
- **Evidencia [V]:**
  - «Siguiente libre: 4742» (PLAN:102 y DAT:50). Sin embargo, `EventId 4742` lo usa `origin/a/dv07-formato-licencia` (`EstadoLicenciaService.cs:145`), y `4743` y `4744` los usa `feature/modelo-ng` (`src/GPOS.Comun/Red/EventosRed.cs:14-20`).
  - Las marcas de EF: DAT:51 da como última `20261019171025_Rs03RncObligatorio`, pero hoy es `20261021001638_Ola5VistasTramo4` (`feature/modelo-ng`).
  - «Reserva hasta 51638» (DAT:48 y :157) contradice la reducción de DX-10 de BP3 (`2026-10-18-db7-blueprint-v3.md:344`). El encargo habla de 51618 a 51644, pero 51618 es del cambio de RNC y de 51639 a 51644 los reserva el diseño de las vistas de impresión de Ola 5.
- **Impacto:** ninguno hoy. D1 no usa 4742, no agrega migraciones de EF y no tiene colisiones. Sin embargo, quien tome «siguiente libre» al pie de la letra chocará.
- **Remediación:** el documentador corrige esos datos y deja la franja de B escrita como «51619 a 51638 de DB-7, de 51639 a 51644 de Ola 5».

### R3-09 · Baja (condición para D2) · El ingreso del SUPER debe fallar cerrado si su registro falla
- **Evidencia:**
  - La base exige el caso en `INGRESO_SUPER` (DAT:986-987 [V]).
  - Las rutas de fallo escriben la bitácora después, y si no se escribe, «la respuesta no cambia» (DAT:521 [V]).
  - El índice filtrado agrega una causa nueva de fallo de escritura: el error 1934 (R-D1D-15, DAT:1292 [V]).
- **Escenario [I]:** si D2 trata el `INSERT` de `INGRESO_SUPER` como una ruta de fallo, con 4741 y sin cambiar la respuesta, un 547 (sin caso) o un 1934 dejan entrar al SUPER **sin rastro**. Los controles de CS-P2 se saltarían con solo provocar el error.
- **Remediación:** escribir en PLAN, como condición de D2, que `INGRESO_SUPER` se inserta **antes** de emitir la sesión de la empresa y en su misma transacción, y que si falla la respuesta es 503 y no hay sesión. Prueba: `…Ingreso_SUPER_sin_registro_no_emite_sesion`.

## 6. Controles bien diseñados en la revisión 3
- 51619 por `UPDATE()` de la clave: más simple y cierra el intercambio de claves (DAT:853-855 [V]).
- Comparación de definiciones contra una plantilla creada por el propio motor, con restitución de `CHECK` deshabilitadas o que no son de confianza, y 51627 sin cambiar nada (DAT:988-1033 [V]).
- `ConversionAccesos` con una sola fila (`CHECK Id = 1`), sin FK y con `DENY` total para la API (DAT:1060-1066 y :1094 [V]).
- La precondición 10 incluye las tablas que solo escribe el verbo, para detectar bases manipuladas o restauradas a medias (DAT:1212 [V]).
- La vista previa por empresa usa la regla de Q23 y no la sustituye (DAT:1233-1248 [V]).
- Parámetro `varchar(30)` contra la columna `varchar`, sin conversión implícita (DAT:193 [V]).

## 7. Remediaciones priorizadas

| Prioridad | Hallazgo | PR | Esfuerzo [I] |
|---|---|---|---|
| 1 | R3-01 (H-13 en el texto normativo y en las pruebas) | T1-1 (antes de empezar el 2026-11-02) | 0,05 d |
| 2 | R3-02 (DEMO con lista blanca y confirmación escrita) | T1-4 | 0,15 d |
| 3 | R3-03 (vínculo de la instantánea) | T1-4, con el arquitecto de software | 0,1 d |
| 4 | R3-06 (evento de rechazo en el catálogo) | T1-1 | 0,05 d |
| 5 | R3-04 y R3-05 | T1-4 | 0,1 d |
| 6 | R3-09 | D2 (anotar en PLAN ahora) | dentro de D2 |
| 7 | R3-07 y R3-08; pasar D1-07 a D1-15 al PLAN | D3 y documentador | 0,05 d |

**Total:** unos 0,55 días-persona (±50 %). Costo de infraestructura: USD 0.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-dat-d1-rev3-2026-10-22.md`
- Supuestos:
  - El PR #167 equivale a `origin/b/dat-d1-rev3` en `fb58e286`.
  - Quedan sin ejecutar y marcados [I]: el truncado del `SqlParameter`, la normalización Unicode de `ToUpperInvariant`, que una copia restaurada comparta el anillo y el `InstalacionId`, y la estabilidad de la plantilla de `sys.check_constraints`.
- Decisiones candidatas a ADR:
  - (R3-02) El modo DEMO solo con una licencia verificada de Desarrollo o Demostración (lista blanca). Precisión de SD0-10 y ADR-39.
  - (R3-03) La protección de la instantánea vinculada a la instalación, la base, el momento y el padrón. Precisión de ADR-83, punto 2.
- Entregas a otros agentes:
  - arquitecto-datos (B): R3-01, R3-04, R3-05, R3-08, D1-07 y D1-12.
  - arquitecto-software (B): R3-02 (con Q-V2-08), R3-03, R3-06 y R3-09 en PLAN; la regla de ADR-35 de D1-05; quitar «Falta elegir» de PLAN:257.
  - documentador: R3-08 (ADR-82: EventId, franjas y marca de EF).
  - qa (C): los casos de R3-01 y las pruebas de R3-02 y R3-09.
- Próximo paso recomendado: que B incorpore R3-01 a DAT y R3-02 y R3-03 a PLAN (T1-4) antes del 2026-11-02, y que A revise el PR de T1-1 cuando se abra.
