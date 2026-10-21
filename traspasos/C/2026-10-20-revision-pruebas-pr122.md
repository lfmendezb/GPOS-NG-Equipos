# Revisión de las pruebas del PR #122 (ADR-90, RT-01 / PT-06, PR-1a)

- **Fecha:** 2026-10-20 · **Autor:** QA del equipo C (OSHIN-LEGION) · **Encargo:** B, `avisos/B-a-C/2026-10-20-cola-de-tareas-para-c.md`, tarea 1 ampliada.
- **Objeto:** PR #122 `a/adr90-rt01-modo-red` @ `1b552cab` (dos commits: `e840bae3` y `1b552cab`, correcciones S-01, S-04 y S-06), contra `feature/modelo-ng` @ `b8f166db`. 14 archivos: 8 de código en `src/GPOS.Comun/Red` y 5 de pruebas en `tests/GPOS.Tests/Red` y `Arquitectura`.
- **Método:** solo lectura (`gh pr view`, `git fetch`, `git show`, `git grep`). No compilé ni corrí las pruebas del repositorio; el «148 correctas» es del mensaje del commit de A. Para tres comportamientos del marco ejecuté una línea de `pwsh` 7.6.7 sobre .NET 10.0.13 (el mismo `net10.0` de `GPOS.Comun.csproj`): `IPAddress.TryParse`, `Uri` y las expresiones regulares. Esos tres están marcados [V]; lo demás que no leí en el código es [I].
- **Insumos leídos:** `docs/adr/ADR-090.md` (RT-01 y PT-06), blueprint v2 de A (4.1, 4.3, 5.1, 9), revisión de seguridad del PR-1a (S-01 a S-09) y diseño del laboratorio de C (2.1 y 11).

## Dictamen: Suficiente con observaciones

La lógica pura de la falla cerrada está bien cubierta (la tabla de fuentes de la regla 1, el modo único de la regla 3, Estricto y «sin modo», las direcciones efectivas y las correcciones S-01, S-04 y S-06 tienen pruebas con la intención correcta). Lo que falta no es volumen sino cuatro huecos con riesgo real:

1. **P122-01 (Alta):** el caso normal de `IpNodos` vacío nunca se lee del registro real; si la lectura de un `REG_MULTI_SZ` vacío difiere de lo que supone el código, todo nodo y todo sitio único quedaría sin arrancar (4743).
2. **P122-02 y P122-03 (Media):** dos huecos de validación que el código acepta hoy y que ninguna prueba cubre (IP no canónicas en `NombresServidor`; un salto de línea final que burla la huella, `.local` y `localhost`). Son defectos reales, no solo pruebas ausentes.
3. **P122-04 a P122-07 (Media):** `PuertoWeb` contra 5073 y 17654, la rama de error de la fuente de Windows, la decisión denegada en `DireccionesNoPermitidas` y la matriz Estricto / no Estricto con modo válido.

Recomendación técnica (C2; decide el propietario vía B): unir tras P122-01, P122-02 y P122-03 (las pruebas son baratas, unas 0,3 dp en total [I]); el resto puede entrar en el mismo PR o en PR-1b.

## 1. Hallazgo de B: confirmado en dos partes, refutado en una

| Afirmación de B | Veredicto | Evidencia |
|---|---|---|
| `ArranqueRed.Exigir` y `ComprobarDirecciones` (4743, 4745, 4746 y `ArranqueRedException`) no tienen prueba | **Refutada en la existencia; confirmada en la profundidad (P122-08)** | Hay tres pruebas desde el primer commit (`e840bae3`) y siguen en `1b552cab`: `tests/GPOS.Tests/Red/ArranqueRedTests.cs:289-299` `Exigir_registra_el_critico_y_lanza_si_esta_denegado` (lanza `ArranqueRedException`, `Evento.Id` 4743, una entrada `Critical` con 4743); `:301-313` `Exigir_deja_el_aviso_4745_sin_modo_y_nada_con_modo` (4745 `Warning`; con modo, cero entradas); `:315-325` `ComprobarDirecciones_registra_4746_por_cada_direccion_no_permitida` (devuelve true sin entradas, false con dos entradas `Critical` 4746 `RedDireccionNoPermitida`). `git grep` de `ArranqueRed.Exigir`, `ComprobarDirecciones` y `ArranqueRedException` en `tests/GPOS.Tests/Red` da 5 coincidencias en las dos puntas. Lo que sí falta es lo de P122-06 y P122-08 |
| Faltan casos de `PuertoWeb` contra 5073 y 17654 | **Confirmada** (P122-04) | Los dos puertos solo se prueban contra `PuertoApi` (`InterpretacionRedTests.cs:129-130`). `PuertoWeb` solo se acota a 1-65535 (`InterpretacionRed.cs:41-46`) y el blueprint 4.1 dice lo mismo (fila `PuertoWeb`), de modo que además es una pregunta de contrato |
| Faltan IP no canónicas en `NombresServidor` | **Confirmada y es un defecto de código** (P122-02) | `InterpretacionRed.cs:92` clasifica como IP con `IPAddress.TryParse` sin forma canónica; la S-01 de seguridad lo anticipó para `NombresServidor` («en menor grado») y no se aplicó ahí |

## 2. Hallazgos

Convenciones: ids `P122-nn`; evidencia con archivo y línea en `1b552cab`; [V] verificado con `pwsh` sobre .NET 10.0.13. Las pruebas propuestas van con nombre exacto; todas son `[Fact]` o `[Theory]` en la clase indicada, con `[Trait("Esquema","Neutral")]` como las existentes.

### P122-01 · Alta · `IpNodos` vacío como `REG_MULTI_SZ` real nunca se lee

- **Por qué importa.** El blueprint 4.1 dice que el paquete escribe `IpNodos` **siempre** y vacío en los nodos y en el sitio único; en «servidor de sitio» un valor ausente es 4743 (HB-05). El vacío es entonces el valor más común. La prueba del vacío usa un arreglo en memoria (`InterpretacionRedTests.cs:221-227`). La traducción real de `REG_MULTI_SZ` vive en `FuenteConfiguracionRed.Windows.cs:62` y la prueba contra el registro **no escribe** `IpNodos` vacío (`FuenteConfiguracionRedWindowsTests.cs:31-50` escribe un `IpNodos` con un elemento; `:99-111` lo deja ausente).
- **Riesgo [I].** Un `REG_MULTI_SZ` vacío puede quedar como datos de longitud cero, `"\0"` o `"\0\0"` según quién lo escriba (la API de .NET, el verbo `red`, un MSI o `reg.exe`). Si alguna forma vuelve como `[""]` o como `ValorTipoNoAdmitido`, el código lo rechaza (`InterpretacionRed.cs:72-77`; la entrada `""` es inválida, `InterpretacionRedTests.cs:241`) y el servicio no arranca. No lo ejecuté.
- **Pruebas propuestas** (`FuenteConfiguracionRedWindowsTests`, solo Windows, con subclave temporal de `HKCU` como las existentes):
  - `IpNodos_vacio_como_REG_MULTI_SZ_se_lee_como_conjunto_vacio_y_es_valido`: `SetValue(IpNodos, new string[0], MultiString)` con `ServidorSitio`, `NombresServidor` válido y `PuertoApi` 5071; afirma `LecturaRed.Valida` y `Red.IpNodos` vacío.
  - `IpNodos_con_una_sola_entrada_vacia_no_es_valido`: `SetValue(IpNodos, new[] { "" }, MultiString)`; afirma `Invalida(IpNodos)`. Fija en qué lado cae la forma ambigua.
  - `NombresServidor_vacio_como_REG_MULTI_SZ_en_servidor_de_sitio_no_es_valido`: igual con `NombresServidor`.
- **Entrega a B:** el verbo `red` debe tener una prueba que escriba el vacío con su propio escritor y lo lea con `FuenteConfiguracionRed` (misma forma de datos que el MSI). Es la costura donde se rompería.

### P122-02 · Media · Entradas de `NombresServidor` que son IP no se validan en forma canónica

- **Evidencia.** `InterpretacionRed.cs:92`: `var esIp = n.Length > 0 && !n.Any(char.IsWhiteSpace) && IPAddress.TryParse(n, out _)`, y `:93` acepta toda entrada que sea «IP» (solo la primera se rechaza por ser IP). Ninguna prueba en `InterpretacionRedTests.cs:163-199` usa una IP no canónica en las posiciones 2 a 16 (`Sitio()` usa `10.0.0.10`, `:20`).
- **Verificado [V]** con `IPAddress.TryParse` en .NET 10.0.13: `010.0.0.1` → `8.0.0.1` (octal); `10.1` → `10.0.0.1`; `167772161` → `10.0.0.1`; `1234` → `0.0.4.210`; `1.2.3` → `1.2.0.3`; `0x0A.0.0.1` → `10.0.0.1`; `[fd00::5]` y `[fd00::5]:80` → `fd00::5` (con el puerto ignorado); `0.0.0.0` y `::ffff:0.0.0.0` se aceptan. Todas pasarían hoy como nombre válido en las entradas 2 a 16.
- **Efecto.** `NombresServidor` alimenta `AllowedHosts`, la URL de la API y el SAN (blueprint 4.1; lab 4.1 condición 4). Una entrada como `010.0.0.1` es un texto que ningún cliente envía y que, leído por otra pieza, es otra IP: la misma clase de error que S-01 corrigió en `IpNodos`.
- **Pregunta de contrato para A (no la resuelvo yo):** ¿se admiten en las posiciones 2 a 16 una IP de *loopback*, `0.0.0.0`, `::` o el nombre `localhost`? Hoy se aceptan (`localhost` solo se rechaza en la posición 1, `:96`), y el PT-01 dice que el SAN de la API «no lleva `localhost`».
- **Pruebas propuestas** (`InterpretacionRedTests`, rojas hoy):
  - `NombresServidor_con_una_IP_no_canonica_en_una_entrada_posterior_no_es_valido` (Theory): `010.0.0.1`, `10.1`, `167772161`, `1234`, `0x0A.0.0.1`, `1.2.3`, `[fd00::5]`, `[fd00::5]:80`, `fd00:0:0:0:0:0:0:5`, `fe80::1%3`. Con `NombresServidor = ["gpos-s01.prueba", entrada]` afirma `Invalida(NombresServidor)` y que el motivo no repite la entrada.
  - `NombresServidor_con_una_IP_no_canonica_como_primera_entrada_no_es_valido` (Theory): las mismas, en la posición 1 (hoy pasa por la regla de «es una IP»; fija que no cambie).
  - `NombresServidor_con_una_IP_canonica_en_una_entrada_posterior_es_valido` (Theory): `10.0.0.10`, `fd00::10`, `192.168.1.5`. Fija lo que sí vale.
  - Según la respuesta de A: `NombresServidor_con_loopback_localhost_o_sin_especificar_en_una_entrada_posterior_...` (valido o no, pero fijado).
- **Arreglo del código (para A):** reutilizar el criterio de ida y vuelta de `DireccionIp` en esa entrada (sin la exclusión de *loopback* si A decide admitirlo).

### P122-03 · Media · Un salto de línea final burla la huella, `.local` y `localhost`

- **Evidencia.** `InterpretacionRed.cs:17-18` (`^[0-9A-F]{64}$`) y `:20-21` (`^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$`). En .NET, `$` sin `Multiline` coincide también antes de un `\n` final. **Verificado [V]:** la huella de 64 hexadecimales más `"\n"` da `True`, y la etiqueta `"prueba\n"` da `True` (con `"\r"` da `False`).
- **Consecuencias.**
  - `HuellaApi`/`HuellaWeb` = 64 hexadecimales + `\n` se acepta como válida (`:113`) y se guarda con el salto.
  - `EsNombreDns` (`:103-105`) no revisa espacios en blanco: `gpos.local\n` no termina en `.local` (`:94`) y su última etiqueta pasa la expresión, de modo que **se burla la regla PT-03**. Con `localhost\n` como primera entrada se burla `:96`.
  - Impacto acotado (el valor llega por el verbo `red`, no por un usuario); lo dejo en Media porque son reglas firmadas (PT-03) con un arreglo de un carácter (`\z` en lugar de `$`) y sin prueba.
- **Pruebas propuestas** (`InterpretacionRedTests`, rojas hoy):
  - `Huella_con_salto_de_linea_o_espacios_alrededor_no_es_valida` (Theory sobre `HuellaApi` y `HuellaWeb`): la huella válida más `"\n"`, `"\r\n"`, `" "`, y con espacio inicial. Afirma `Invalida(<la huella>)`.
  - `Nombre_con_salto_de_linea_o_caracter_de_control_no_es_valido` (Theory): `gpos.prueba\n`, `gpos.local\n`, `localhost\n` (primera entrada), `gpos.prueba\t`, `gpos.prueba\0`. Afirma `Invalida(NombresServidor)`.

### P122-04 · Media · `PuertoWeb` contra 5073 y 17654 (hallazgo de B, confirmado)

- **Evidencia.** `InterpretacionRed.cs:40-46` acota `PuertoWeb` a 1-65535 y no lo compara con `PuertoReportes` ni `PuertoAgente` (`ValoresRegistroServidor.cs:40,43`). `PuertoApi` sí (`:52-53`, con pruebas `InterpretacionRedTests.cs:129-130`).
- **Por qué es más que una prueba ausente.** En «un equipo» el agente de impresión corre en el mismo PC (17654) y la API de reportes en el mismo anfitrión (5073): una Web en esos puertos falla al enlazar en RT-05, no en RT-01, con un error de socket en vez del 4743 que da el resto de la validación. Pregunta para A: ¿regla del contrato? El blueprint 4.1 solo pone 1-65535 para `PuertoWeb`.
- **Pruebas propuestas** (`InterpretacionRedTests`):
  - `PuertoWeb_igual_al_de_reportes_o_al_del_agente_no_es_valido` (Theory 5073, 17654): `Sitio()` con `PuertoWeb` = el puerto; afirma `Invalida(PuertoWeb)`. Rojas hoy; si A decide admitirlo, se invierte y se llama `PuertoWeb_en_5073_o_17654_se_admite` (que fija la decisión).
  - `PuertoWeb_443_con_PuertoApi_distinto_es_valido` (la regla por omisión no se rompe).

### P122-05 · Media · La rama de error de la fuente de Windows no tiene prueba

- **Evidencia.** `FuenteConfiguracionRed.Windows.cs:44-47`: `catch (e) when (e is SecurityException or UnauthorizedAccessException or IOException)` devuelve `Invalida(Clave, "no se pudo leer la clave (…)")`, y la documentación (`:9`) lo presenta como propiedad de seguridad («un error al abrir la clave no se toma por “sin modo”»). Ninguna de las 6 pruebas de `FuenteConfiguracionRedWindowsTests.cs` provoca esa excepción. La inyección `ParaPruebas(Func<RegistryKey>, string)` permite hacerlo sin ACL reales (sirve de base para LAB-43b).
- **Pruebas propuestas** (`FuenteConfiguracionRedWindowsTests`, solo Windows):
  - `Un_error_de_permisos_o_de_E_S_al_abrir_la_clave_no_es_sin_modo` (Theory sobre `UnauthorizedAccessException`, `SecurityException`, `IOException`): `ParaPruebas(() => throw …, _subclave)`; afirma `Invalida` con `Valor == ValoresRegistroServidor.Clave`, que el motivo contiene el nombre del tipo de la excepción y **no** el `Message` de la excepción; y que con la decisión (`ArranqueRed.Evaluar(.., estricto: false)`) el resultado es `Denegado`/4743.
  - `Una_excepcion_no_prevista_al_abrir_la_clave_se_propaga` o `..._es_Invalida` según lo que decida A (S-07 de seguridad pide un `catch` general con 4743): hoy un `ArgumentException` tumba el proceso sin evento. La prueba fija la decisión.

### P122-06 · Media · `DireccionesNoPermitidas` con la decisión denegada, lista vacía y cadenas vacías

- **Evidencia.** El comentario de `ArranqueRed.cs:128` promete «Con la decisión denegada, ninguna» y `:176` lo implementa. `ArranqueRedTests.cs` no llama a `DireccionesNoPermitidas` ni a `ComprobarDirecciones` con una decisión `Denegado` (revisé todas las llamadas: `:237,251,258-259,276,283,320,322`). Tampoco con lista vacía ni con `""`/`" "` (`:177`).
- **Pruebas propuestas** (`ArranqueRedTests`):
  - `Con_la_decision_denegada_ninguna_direccion_se_admite` (Theory sobre `https://127.0.0.1:5071`, `https://[::]:5071`, `http://localhost:5071`): `Evaluar(SinModo, estricto: true)` y afirma que `DireccionesNoPermitidas` devuelve las tres.
  - `ComprobarDirecciones_con_decision_denegada_devuelve_false_y_registra_4746_por_cada_direccion`.
  - `Sin_direcciones_efectivas_la_comprobacion_pasa_y_no_registra` (lista vacía → true, cero entradas). Fija que «Kestrel no enlazó nada» no es un 4746 (y deja claro, para PR-1b, que esa situación la detecta otra pieza).
  - `Una_direccion_vacia_o_en_blanco_no_se_admite` (Theory `""`, `" "`, `"\t"`).

### P122-07 · Media · Estricto y no Estricto con modo válido

- **Evidencia.** El ayudante `ConModo` fija `estricto = true` por omisión (`ArranqueRedTests.cs:33-34`) y las pruebas de las reglas 1 y 3 con modo presente lo usan sin cambiarlo (`:66,87,100,106,132,138,146-147`). Ninguna prueba con `LecturaRed.Valida` y `estricto: false` (`grep` de `estricto: false`: solo con `SinModo`, `SinPlataforma` o `Invalida`). Lo firmado es que, con modo presente, las reglas rigen siempre; el caso práctico es una PC de desarrollo con el registro puesto y `ASPNETCORE_URLS` en `launchSettings`.
- **Pruebas propuestas** (`ArranqueRedTests`):
  - `Con_modo_valido_el_resultado_no_depende_de_Estricto` (Theory true/false): `ConModo` sin otras fuentes → `ConModo` en ambos.
  - `Con_modo_valido_y_sin_Estricto_las_fuentes_de_direcciones_siguen_rechazadas_4744` (Theory true/false × `urls`, `ASPNETCORE_URLS`).
  - `Con_modo_valido_y_sin_Estricto_un_modo_distinto_en_el_entorno_sigue_siendo_4743`.

### P122-08 · Baja · Profundidad de `Exigir` y `ComprobarDirecciones` (resto del hallazgo de B)

- `Exigir` solo se prueba denegado por 4743 (`ArranqueRedTests.cs:289-299`). No se prueba que propague `decision.Evento` cuando es 4744 (`ArranqueRed.cs:152-153` usa `decision.Evento`); un cambio a un evento fijo no lo detectaría. Tampoco que el mensaje de la excepción y el registro nombren el servicio y no contengan el valor rechazado.
- `ComprobarDirecciones` no comprueba que el registro lleve el `Servicio` y la `Direccion` como estructura (solo nivel, `Id` y nombre, `:324`).
- **Pruebas propuestas** (`ArranqueRedTests`):
  - `Exigir_denegado_por_fuente_de_escucha_registra_y_lanza_el_4744`: `ConModo(RedSitio, Config(("urls","https://0.0.0.0:5071")))` → `ArranqueRedException.Evento.Id == 4744` y una entrada `Critical` 4744.
  - `Exigir_denegado_nombra_el_servicio_y_no_repite_el_valor_rechazado`: `e.Message` contiene `Web`/`Api` y no contiene `https://0.0.0.0:5071`; igual el mensaje del registro.
  - `ComprobarDirecciones_nombra_el_servicio_y_la_direccion_en_el_registro`: el mensaje de cada entrada contiene `Api` y la dirección.
  - `Exigir_y_ComprobarDirecciones_rechazan_argumentos_nulos` (opcional, trivial).

### P122-09 · Baja · Pruebas que pasan por la razón equivocada o sin discriminar

1. `Un_modo_en_el_entorno_sin_registro_no_arranca` con `estricto = true` (`ArranqueRedTests.cs:152-162`): el 4743 sale de la regla de Estricto (`ArranqueRed.cs:96-100`) y no de «el entorno declara un modo sin registro» (`:100-101`); la fila pasaría aunque se borrara esa regla. Solo la fila `false` la ejercita, y no afirma el motivo. **Arreglo:** afirmar en la fila `false` que `Motivo` contiene `GPOS_MODO_RED` (y `GPOS:Red:Modo` en la segunda parte).
2. `SinPlataforma` con un modo declarado y sin Estricto no se prueba (la regla de `:100` también la alcanza). `Un_modo_en_el_entorno_sin_fuente_de_plataforma_y_sin_Estricto_no_arranca`.
3. Precedencia entre 4743 y 4744: con un modo distinto **y** una fuente de escucha, gana el 4743 (`:87-91`), lo que importa a las alertas por número. `Con_modo_distinto_y_fuente_de_escucha_gana_el_4743`.
4. La matriz de la regla 1 afirma el `Id` (4744) pero no cuál fuente nombra el motivo (`:62-74`); un cambio que nombrara siempre la primera de la lista pasaría. **Arreglo:** `Assert.Contains(clave, d.Motivo)` ignorando mayúsculas en el Theory de configuración (el de entorno ya lo hace, `:90`).
5. `Los_EventId_de_RT01_estan_en_la_franja_de_ADR90` (`:327-332`) solo comprueba el rango; los números exactos y los nombres sí quedan afirmados en otras pruebas (4743, 4744, 4745, 4746). No hay problema, pero la unicidad global la da `EventIdUnicosTests` (que escanea `src/`), y esa prueba detectará un choque solo si el patrón de declaración coincide (`EventosRed.cs:14-24` lo cumple).

### P122-10 · Baja · Pruebas de Windows que pasan sin ejecutarse

- **Evidencia.** `FuenteConfiguracionRedWindowsTests.cs:34,55,64,83,102` hacen `if (!OperatingSystem.IsWindows()) return;`: en Linux (ADR-129, fase futura) figuran como aprobadas sin haber corrido. También `:117-118` (la rama no Windows de la fábrica solo se ejecuta fuera de Windows). Hoy no hay CI de Linux, así que el efecto es futuro.
- **Propuesta (sin tecnología nueva):** un `FactWindowsAttribute : FactAttribute` que asigne `Skip` fuera de Windows, igual que los precedentes del repositorio `FactBp2Attribute`, `FactDemoAttribute`, `FactModoMixtoAttribute` y `FactB9Attribute`. Así aparece «omitida» y no «aprobada». xUnit es 2.9.3 (`GPOS.Tests.csproj:15`), sin `Assert.Skip`. Si no se cambia, dejar un comentario con la limitación.

### P122-11 · Baja · Tipos y asimetrías entre `HuellaApi` y `HuellaWeb`

- **Evidencia.** Solo `ModoRed` se prueba con `ValorTipoNoAdmitido` (`InterpretacionRedTests.cs:115-122`). `PuertoWeb` no se prueba con un tipo equivocado (solo `PuertoApi` como texto, `:139-147`); `HuellaApi` no se prueba **nunca** como inválida (solo `HuellaWeb`, `:206-211`), aunque las dos líneas son distintas (`InterpretacionRed.cs:64-65`): un cruce `Invalido(HuellaApi, mWeb)` no se detectaría. `NombresServidor` e `IpNodos` solo con `REG_SZ`.
- **Pruebas propuestas** (`InterpretacionRedTests`):
  - `Un_valor_de_tipo_no_admitido_en_cualquier_valor_conocido_es_invalido` (Theory sobre `PuertoApi`, `PuertoWeb`, `NombresServidor`, `IpNodos`, `HuellaApi`, `HuellaWeb`, y los tipos `ValorTipoNoAdmitido("Binary")`, `int` o `string[]` según el valor): afirma `Invalida(<ese valor>)`.
  - `Huella_de_la_API_que_no_es_valida_nombra_a_HuellaApi` (misma Theory de `:201-211`, aplicada a `HuellaApi`).
  - `Huella_como_REG_DWORD_no_es_valida` (`:112`, rama «no es REG_SZ»).
  - `PuertoApi_y_PuertoWeb_como_REG_DWORD_con_el_bit_alto_se_leen_negativos_y_no_son_validos` (`unchecked((int)0x80000000)`; en el registro real, `REG_DWORD` 0xFFFFFFFF se lee como -1).

### P122-12 · Baja · Puertos en los límites

- **Evidencia.** `InterpretacionRedTests.cs:124-137`: inválidos 0, 1023, 70000, -1, 5073, 17654, 443. Faltan los **válidos** en los extremos y los inválidos justo fuera (`InterpretacionRed.cs:44,50`).
- **Pruebas propuestas:** `PuertoApi_en_los_limites_1024_y_65535_es_valido`, `PuertoApi_65536_no_es_valido`, `PuertoWeb_en_los_limites_1_y_65535_es_valido` (con `PuertoApi` 5071), `PuertoWeb_negativo_no_es_valido`.

### P122-13 · Baja · Direcciones efectivas: casos de borde

Evidencia: `ArranqueRedTests.cs:223-285` (y `ArranqueRed.cs:174-192`). Verifiqué [V] con `Uri` en .NET 10.0.13 cómo se normalizan estas formas: `https://127.1:5071` → host `127.0.0.1`; `https://0:5071` → `0.0.0.0`; `https://[0:0:0:0:0:0:0:0]:5071` → `[::]`; `HTTPS://LOCALHOST:5071` → `localhost`; `https://localhost.:5071` → `localhost.` (no coincide: falla cerrada); `https://127.0.0.1` y `https://[::]` sin puerto → puerto 443.

- **Pruebas propuestas** (`ArranqueRedTests`):
  - `Un_equipo_admite_loopback_en_formas_equivalentes` (Theory true): `https://[::ffff:127.0.0.1]:5071`, `https://127.0.0.2:5071`, `https://127.1:5071`, `HTTPS://LOCALHOST:5071`. Hoy la IPv4 mapeada solo se prueba en «sin modo» (`:266`).
  - `Un_equipo_rechaza_formas_equivalentes_de_no_loopback` (Theory false): `https://[::ffff:192.168.1.10]:5071`, `https://0:5071`, `https://[0:0:0:0:0:0:0:0]:5071`, `https://localhost.:5071`, `https://[fe80::1%3]:5071`.
  - `Una_direccion_que_no_es_http_ni_https_no_se_admite_en_ningun_modo` (Theory): `unix:/tmp/gpos.sock`, `pipe:gpos`, `ftp://127.0.0.1:5071`, `127.0.0.1:5071`, `https://127.0.0.1:99999`, y también en «sin modo».
  - `Una_direccion_sin_puerto_se_juzga_con_el_puerto_por_omision_del_esquema`: `https://127.0.0.1` en `Web` (443) permitida; en `Api` (5071) no. Fija el caso que `Uri.Port` devuelve 443 sin que Kestrel lo haya escrito.
  - `Servidor_de_sitio_admite_https_en_una_IP_concreta_en_su_puerto`: `https://192.168.1.10:5071` → permitida (el contrato dice «HTTPS y puerto»). Si A no lo quiere, la prueba lo invierte; hoy es comportamiento sin fijar.
  - `Servidor_de_sitio_rechaza_http_en_loopback_en_el_puerto_de_la_web` (Web, `http://localhost:443`).

### P122-14 · Baja · `DireccionIp`: casos de borde

Evidencia: `DireccionIpTests.cs:25-111` y `DireccionIp.cs:33-71`. Varias filas rechazan por otra regla distinta de la que anuncia el comentario (por ejemplo, `0x0A.9.0.5` cae en el filtro de caracteres `:73-74` y no en la ida y vuelta; `::ffff:010.9.0.5` en `TryParse`, [V] que da `False`), sin consecuencia, pero la prueba de la ida y vuelta de IPv4 queda sostenida solo por las tres filas con cero a la izquierda válido en octal.

- **Pruebas propuestas** (`DireccionIpTests`):
  - `TryParseHost_admite_rangos_privados_y_de_VPN` (Theory): `172.16.0.1`, `172.31.255.254`, `100.64.0.1`, `192.168.0.1`, `fc00::1`, `fd12:3456:789a::5`. Son las que el sitio y la VPN de las sucursales usan (ADR-90, PT-05).
  - `TryParseHost_rechaza_IPv4_mapeada_de_direcciones_que_no_son_de_un_nodo` (Theory): `::ffff:0.0.0.0`, `::ffff:255.255.255.255`, `::ffff:169.254.1.1`, `::ffff:224.0.0.1`.
  - `TryParseHost_rechaza_el_prefijo_equivocado_para_la_forma_escrita`: `::ffff:10.9.0.5/32` (la forma mapeada lleva `/128`, `:48-50`), `10.9.0.5/32/32`, `10.9.0.5/+32`, `fd00::5/0128`.
  - `TryParseHost_rechaza_texto_con_digitos_no_ASCII_controles_o_largo_excesivo`: dígitos árabes, `\t`, `\0`, `\n`, 65 caracteres.
  - `TryParseHost_en_los_limites_del_rango_de_nodo`: `223.255.255.254` ya está; agregar `224.0.0.0` (rechazo) y `1.0.0.0` (admisión).

### P122-15 · Baja · `IpNodos` con duplicados, formas equivalentes y sin tope

- **Evidencia.** `HashSet<IPAddress>` (`InterpretacionRed.cs:68,77`) colapsa las repetidas, y `Servidor_de_sitio_valido_con_IpNodos_normalizadas...` (`InterpretacionRedTests.cs:71-87`) cubre tres entradas distintas. No hay prueba de duplicados. `IpNodos` no tiene tope, mientras que `NombresServidor` sí (16).
- **Pruebas propuestas** (`InterpretacionRedTests`):
  - `IpNodos_con_formas_equivalentes_de_la_misma_IP_dan_un_solo_elemento`: `["10.9.0.5", "10.9.0.5/32", "::ffff:10.9.0.5"]` → `Count == 1`.
  - `IpNodos_con_la_misma_IP_repetida_no_es_error` (documenta que un duplicado no invalida).
  - `IpNodos_solo_con_entradas_validas_acepta_muchas_entradas` (por ejemplo 200) y pregunta a A si fijar un tope; hoy, sin tope, una lista enorme solo cuesta memoria.

### P122-16 · Baja · `NombresServidor`: bordes

Evidencia: `InterpretacionRedTests.cs:163-199`.

- **Pruebas propuestas** (`InterpretacionRedTests`):
  - `NombresServidor_con_exactamente_16_entradas_es_valido` (el límite superior; hoy solo se prueba 17, `:189`).
  - `Una_etiqueta_de_63_caracteres_es_valida_y_una_de_64_no` y `Un_nombre_de_253_caracteres_es_valido_y_uno_de_254_no` (`InterpretacionRed.cs:20,104`).
  - `Un_nombre_con_punto_final_o_no_ASCII_no_es_valido` (`gpos.prueba.`, `gpós.prueba`): lo exige el LAB-33, que da por hecho el rechazo en el servicio.
  - `Un_nombre_en_mayusculas_se_admite_y_se_conserva_tal_cual` (o se normaliza; es decisión de A: LAB-33 dice que el **verbo** normaliza a minúsculas, y el servicio hoy no lo hace).
  - `Un_nombre_de_una_sola_etiqueta_se_admite`: `gpos-s01` (hoy válido, `:104`).
  - `NombresServidor_con_entradas_duplicadas`: `["a.prueba","A.PRUEBA"]`; el contrato calla, se fija.
  - `En_un_equipo_NombresServidor_presente_e_invalido_tambien_es_invalido` y `En_un_equipo_NombresServidor_presente_y_vacio_es_invalido`: el código valida si está presente, sea cual sea el modo (`:56-61`) mientras el blueprint dice «UnEquipo: no se usa». Si el paquete escribe un vacío en «un equipo», no arranca. Pregunta a A/B.

### P122-17 · Baja · Copia defensiva, valores ajenos y nombres sin distinguir mayúsculas

- `nombres = Array.AsReadOnly((string[])lista.Clone())` (`InterpretacionRed.cs:60`) es una copia deliberada; no hay prueba. `NombresServidor_se_copia_y_no_cambia_si_se_modifica_el_arreglo_de_origen`.
- El blueprint 4.1 lista `Version`, `FechaInstalacion`, `RegistroInstalacion` como valores que **no afectan** al arranque. Nada lo prueba y el diccionario de la fuente real incluye todos los valores, con su tipo (`FuenteConfiguracionRed.Windows.cs:54-64`). `Valores_ajenos_del_registro_se_ignoran_aunque_su_tipo_no_se_admita` (Interpretar con `Version = ValorTipoNoAdmitido("QWord")`, `FechaInstalacion = 5`, `HuellaAnterior = "x"`) y su versión de registro real con `REG_QWORD` y `REG_BINARY` (se vuelve necesario si A agrega `HuellaAnterior`, LAB-41).
- La fuente crea el diccionario con `StringComparer.OrdinalIgnoreCase` (`:53`) «porque los nombres del registro no distinguen mayúsculas»; no hay prueba. `Los_nombres_de_valores_del_registro_no_distinguen_mayusculas` (escribe `modored`, `PUERTOAPI` y espera `Valida`).
- `ConfiguracionRed.IpNodos` y `DecisionArranqueRed.IpNodos` exponen `IReadOnlySet` sobre un `HashSet`; el conjunto «vacío» de las decisiones sin modo es una instancia estática compartida (`ArranqueRed.cs:23`). Un `HashSet<IPAddress>` por encima del tipo declarado es mutable por conversión. No es un defecto hoy; no propongo prueba salvo que A quiera `FrozenSet` o `ImmutableHashSet` (no propongo nada nuevo).

### P122-18 · Baja · Línea de comandos y `preferHostingUrls`

- PT-06 enumera `--urls` entre las fuentes a rechazar. Ninguna prueba usa un proveedor de línea de comandos (`git grep` de `AddCommandLine`, `--urls` en `tests/GPOS.Tests/Red`: sin resultados). La S-03 de seguridad lo deja a PR-1b con el `WebApplicationBuilder`; con `ConfigurationBuilder` y el proveedor de línea de comandos (que ya está en el marco compartido que referencia `GPOS.Tests` por `GPOS.Api` [I]) se puede fijar hoy: `Urls_por_linea_de_comandos_se_rechazan_con_modo` (Theory `--urls=http://0.0.0.0:80`, `--urls http://0.0.0.0:80`, `/urls=http://0.0.0.0:80`, `--http_ports=80`).
- `preferHostingUrls`: `Verdadero("")` y `Verdadero("no")` dan `true` (falla cerrada, `ArranqueRed.cs:204-206`), a diferencia del marco, que solo acepta `true` y `1` (leído en la nota del código; [I]). No hay prueba; `PreferHostingUrls_vacio_o_ilegible_se_rechaza_por_falla_cerrada` (`""`, `"no"`, `" "`) lo fija. Y `DOTNET_PREFERHOSTINGURLS` en falso no se prueba (`:94-101` usa solo `ASPNETCORE_`).

### P122-19 · Baja · La prueba de lectura real no incluye las huellas

- **Evidencia.** `FuenteConfiguracionRedWindowsTests.cs:31-50` escribe `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor` e `IpNodos`, pero no `HuellaApi` ni `HuellaWeb`. Los LAB-37 a LAB-41 dependen de leerlas como `REG_SZ`.
- **Prueba propuesta:** `Lee_HuellaApi_y_HuellaWeb_como_REG_SZ_en_mayusculas` (y `Huella_escrita_como_REG_EXPAND_SZ_no_es_valida`, para que la renovación de B no la cambie de tipo por error).

## 3. Cruce con los casos LAB-xx del diseño del laboratorio

| Caso | Depende de este código | Estado y qué hace falta |
|---|---|---|
| LAB-37 (huellas presentes; solo Administradores y SYSTEM escriben) | `FuenteConfiguracionRed` lee `HuellaApi`/`HuellaWeb`; la ACL es del verbo de B | La lectura real de huellas no tiene prueba (P122-19). La ACL no es de este PR |
| LAB-37b (`NT SERVICE\GPOS.Api` intenta escribir) | La fuente abre con `writable: false` (`:41`) | Nada que probar aquí; el caso es de B |
| LAB-39 / LAB-40 (huella ilegible o inexistente, sigue con la anterior) | `InterpretacionRed.LeerHuella` (`:107-116`) | Una huella con formato malo vuelve **toda** la lectura `Invalida` (`Valor = HuellaWeb`), no solo esa huella. El refresco de RT-05 debe decidir por `Invalida.Valor` y no abandonar también la API por una huella de la Web. Entrega a A: contrato del refresco (la `LecturaRed` no separa servicios). Y P122-03 (la huella con `\n` hoy sí pasa) |
| LAB-41 / LAB-41b (huella de un certificado vencido o de otra raíz) | No es de RT-01: es del selector | Sin cambios aquí |
| LAB-42 / C-A2 (`HuellaAnterior`) | `InterpretacionRed` no conoce `HuellaAnterior` | Si A adopta la propuesta O-03, se agrega el valor con **las mismas** validaciones (P122-03, P122-11, P122-17) y su orden de escritura. Hoy el valor se ignora (P122-17) |
| LAB-43 (b) (escritura de la clave denegada a SYSTEM) | Lado de lectura: `Leer()` con acceso denegado | La rama de error de la fuente no tiene prueba (P122-05) |
| LAB-33 (el verbo con `.local`, comodín, mayúsculas, punto final, no ASCII) | `InterpretacionRed.ValidarNombres` es pública y el verbo puede reutilizarla | Punto final y no ASCII sin prueba (P122-16); `.local` con salto final burla (P122-03). El LAB-33 dice que el verbo normaliza mayúsculas; el servicio no |
| Lista del blueprint 9 («Laboratorio de QA»): registro borrado con Estricto → 4743; `IpNodos` borrado en «servidor de sitio» → no arranca | `ArranqueRed.Evaluar` + `InterpretacionRed` | La lógica pura sí está cubierta (`ArranqueRedTests.cs:166-173,206-219`). Falta la costura con lo que el **paquete** escribe (P122-01) |
| Diseño del lab, 2.1 y 11 (R-L) | «BP-A devuelve `SinModo` en Linux (4.2)» | **Corrección mía:** la v2 de A y el código usan `SinPlataforma` (`ModoRed.cs:55`) y con Estricto no arrancan (HB-03). Actualizaré 2.1 y R-L en mi diseño |

## 4. Lo que está bien (para no romperlo al corregir)

- La matriz de la regla 1 cubre las seis variables, las dos de `PREFERHOSTINGURLS`, `Kestrel:Endpoints` y `Kestrel:Certificates`, el valor vacío, las claves sin distinguir mayúsculas y que el motivo no repite el valor (`ArranqueRedTests.cs:50-92`).
- `Otras_secciones_de_Kestrel_que_no_fijan_direcciones_se_admiten` (`:103-108`) deja anotado el límite de la S-03 (`EndpointDefaults`); si A lo rechaza en PR-2, esta prueba deberá cambiar.
- S-01 tiene pruebas en dos niveles (`DireccionIpTests.cs:44-90` y `InterpretacionRedTests.cs:229-252`), con una comprobación del marco que evita que la prueba pase por la razón equivocada en IPv6 (`:66`).
- S-04 tiene dos pruebas de arquitectura (tipo interno, ningún constructor accesible con parámetros, nadie usa `ParaPruebas` en `src/`) y S-06 tiene prueba en lógica pura y en el registro real.
- `Registro_ausente_con_Estricto…`, `Fuera_de_Windows_con_Estricto…` y `La_clave_sin_ModoRed_no_arranca_ni_sin_Estricto` fijan HB-03, HB-04 y S-06 con el evento correcto.

## 5. Riesgos no cubiertos por estas pruebas (fuera del PR-1a)

- Lectura real de `HKLM` en la vista de 64 bits (las pruebas usan `HKCU`; la ACL y la vista son de B y del laboratorio).
- `Evaluar` con el entorno real del proceso (`entorno ??= Environment.GetEnvironmentVariable`, `ArranqueRed.cs:79`): todas las pruebas inyectan el entorno. PR-1b debe probarlo con `WebApplication.CreateBuilder` (S-03).
- Integración con Kestrel: 4746 con enlaces reales, recarga en caliente (S-02) y el orden de `Evaluar` respecto de `AgregarArchivoInstalacion` (S-03).
- La fábrica `FuenteConfiguracionRed.Crear` en Linux (sin CI de Linux).

## 6. Texto de comentario para el PR #122

> **Revisión de pruebas (QA, equipo C).** Dictamen: **Suficiente con observaciones**. Solo lectura; no compilé ni corrí la suite. Informe completo: `GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pruebas-pr122.md`.
>
> - La lógica de falla cerrada está bien cubierta (regla 1, fuente única, Estricto, «sin modo», direcciones efectivas, S-01, S-04 y S-06).
> - `Exigir` y `ComprobarDirecciones` **sí tienen prueba** (`ArranqueRedTests.cs:289-325`, 4743, 4745, 4746 y `ArranqueRedException`); lo que falta es profundidad: `Exigir` por 4744, nombrar el servicio sin repetir el valor y la decisión denegada en `DireccionesNoPermitidas` (P122-06, P122-08).
> - **P122-01 (Alta):** `IpNodos` vacío es el valor normal del paquete y solo se prueba en memoria. Falta leerlo de un `REG_MULTI_SZ` real (`SetValue(.., new string[0], MultiString)`); una lectura distinta de `[]` dejaría sin arrancar a todo nodo y sitio único.
> - **P122-02 (Media, defecto):** en `NombresServidor`, las entradas 2 a 16 que son IP no se validan en forma canónica (`InterpretacionRed.cs:92`). Verificado en .NET 10.0.13: `010.0.0.1` → `8.0.0.1`, `1234` → `0.0.4.210`, `[fd00::5]:80` se acepta.
> - **P122-03 (Media, defecto):** `^…$` acepta un `\n` final: huella de 64 hexadecimales más `\n` es válida y `gpos.local\n` / `localhost\n` burlan PT-03. Usar `\z` y agregar las pruebas.
> - **P122-04 (Media):** `PuertoWeb` contra 5073 y 17654 no se prueba y el código lo admite (`:41-46`); A decide si se rechaza o se fija como permitido.
> - **P122-05 / 07 (Media):** la rama de error de la fuente de Windows (`UnauthorizedAccess`, `Security`, `IO`) y la matriz Estricto / no Estricto con modo válido no tienen prueba.
> - Baja: puertos en los límites, bordes de direcciones y de `DireccionIp`, duplicados en `IpNodos`, `--urls` por línea de comandos, y las pruebas de Windows que hacen `return` fuera de Windows (pasan sin correr).
>
> Cada hallazgo trae el nombre exacto de la prueba propuesta. Mi recomendación técnica es unir tras P122-01 a P122-03; la decisión es de B y del propietario.

### Cierre
- Estado: Aprobado con observaciones (dictamen: Suficiente con observaciones; recomendación técnica, la decisión es de B y del propietario)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr122.md`
- Supuestos: se revisó la punta `1b552cab`; las pruebas no se compilaron ni se corrieron (el «148 correctas» es del commit de A); el comportamiento del registro real con `REG_MULTI_SZ` vacío y el de ASP.NET con `preferHostingUrls` son [I]; `IPAddress.TryParse`, `Uri` y las expresiones regulares están verificados con `pwsh` sobre .NET 10.0.13.
- Decisiones candidatas a ADR: Ninguna (las preguntas de contrato de P122-02, P122-04 y P122-16 son precisiones técnicas del blueprint de A).
- Entregas a otros agentes: A (arquitecto-software) → decidir `PuertoWeb` ante 5073 y 17654, `localhost` e IP de *loopback* en `NombresServidor` posteriores, `NombresServidor` presente en «un equipo» y normalización de mayúsculas, el `catch` general (S-07) y, si adopta `HuellaAnterior`, su validación; A (desarrollador-backend) → corregir `$` por `\z` y la forma canónica de las IP en `NombresServidor`, y agregar las pruebas de P122-01 a P122-07; B (devops, verbo `red`) → prueba que lea con `FuenteConfiguracionRed` lo que el verbo y el MSI escriben (vacíos de `IpNodos` y `NombresServidor`); C → corregir 2.1 y R-L de mi diseño del laboratorio (`SinPlataforma`, no `SinModo`).
- Próximo paso recomendado: B publica el comentario del PR #122 y A cierra P122-01 a P122-03 antes de unir.
