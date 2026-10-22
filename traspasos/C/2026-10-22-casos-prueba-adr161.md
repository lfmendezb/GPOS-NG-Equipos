```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 6 del aviso 2026-10-22: casos de prueba del ADR-161, maestro «Tipo de identificador fiscal») · VERSIÓN 2
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (construcción futura); fuentes en `master`
Estado: Abierto (casos, sin código; el ADR-161 sigue Propuesto; la DDL existe ya como blueprint de B, también Propuesto)
```

# Casos de prueba del ADR-161 (Tipo de identificador fiscal), versión 2

**Versión 2 (2026-10-22, tarde):** ajustada al blueprint de datos de B (PR #162, rama `origin/b/adr161-datos`, commit `c2394b85`, archivo `docs/datos/2026-10-22-adr-161-tipo-identificador-fiscal.md`, 353 líneas; leído completo con `git show FETCH_HEAD:<ruta>`). La versión 1 se escribió sin el blueprint.

**Cita del blueprint:** `bp:NNN` = número de línea del archivo del blueprint; `bp§X` = su sección.

## Cambios de la versión 2

Resumen: **177 pruebas con ID propio** (127 de la v1 + 50 nuevas, ninguna eliminada), más 6 filas de remisión sin prueba propia. Se reescribieron ID-05, U-04, V-01 y M4-02 (más ajustes de esperado en otros). Detalle:

| ID | Qué cambió | Por qué (cita) |
|---|---|---|
| Todos los marcados `[R]` | Pasan a `[B]` (resueltos por el blueprint, que sigue siendo propuesta) con la cita; `[F]` solo donde ya había firma (Q-TI-2 a 7) | `bp:3-5`: el blueprint resuelve A-1, M-1 a M-4 y B-1 a B-6; M-2 y M-5 quedan pendientes de firma (`bp:343-346`) |
| Nombres | Constraints, índices y FK con los nombres del blueprint: `PK_TipoIdentificadorFiscal`, `UQ_TipoIdentificadorFiscal_Codigo`, `CK_TipoIdentificadorFiscal_Codigo/_Letra/_LetraActiva`, `UQ_TipoIdentificadorFiscal_Letra`, `PK_TipoIdentificadorLargo`, `FK_TipoIdentificadorLargo_Tipo`, `CK_TipoIdentificadorLargo_Rango`, `FK_Cliente_TipoIdentificador`, `FK_Suplidor_TipoIdentificador`, `CK_Cliente_TipoIdentificador`, `CK_Suplidor_TipoIdentificador`, `IX_Cliente_TipoIdentificador`, `IX_Suplidor_TipoIdentificador` | `bp:30-80`, `bp:126-127` |
| LP-01, MG-11 | Siembra con **Id 1 a 4 explícitos**, `EsPersonaFisica` (0,1,1,1), `SoloDigitos` (1,1,0,0), `Inhabilitado=0` y rangos por `Codigo` | `bp:34`, `bp:167-199` |
| LP-02, LP-03 | Nombres `CK_TipoIdentificadorFiscal_Letra` y `UQ_TipoIdentificadorFiscal_Letra` | `bp:73,75` |
| LP-05 | La prohibición de inhabilitar un tipo con letra ya está **en el motor** (`CK_..._LetraActiva`), no solo en el servicio. El servicio debe traducir el 547 a 409. Se agrega TI-D1 (SQL directo) | `bp:74`, `bp:330`. Diferencia con la revisión de la DDL (M-1: «el servicio rechaza»): ver «Conflictos» |
| LP-07 | El 409 es solo mi expectativa; el blueprint dice que la regla es del servicio pero no fija el código HTTP. Se agrega LP-07b (tipo con `C` debe admitir 11) | `bp:99` |
| LP-08 | Esperado concreto: **422 con mensaje de configuración**, sin 500 | `bp:100` |
| LP-09 | Copia por `Codigo`, sin sobrescribir los existentes (se informan) y letra solo si el destino no la tiene | `bp:145` |
| PF-01 a PF-04, PF-07, BT-03 | Etiquetados con la opción de M-2: (a) 409, recomendada por B; (b) con motivo. **Sigue pendiente de firma (Q-TI-8)** | `bp:107-116`, `bp:344` |
| PF-05, PF-06 | Citan la regla de uso (tabla viva; los inhabilitados cuentan; el historial no). PF-06: como **ninguna ruta pone `Cliente.Inhabilitado=1`**, el cliente inhabilitado se siembra por SQL; el suplidor sí se inhabilita por API | `bp:103`; `traspasos/C/2026-10-22-verificacion-codigo-hechos-tt.md`, hecho 0 |
| PF-08 | Incluye un suplidor incumplidor; la consulta usa `IX_*_TipoIdentificador` | `bp:101,126` |
| PF-11 | El índice es filtrado con `INCLUDE (Identificacion)`; riesgo anotado: el optimizador podría no usar un índice filtrado con parámetro (inferido) | `bp:126` |
| MG-01 a MG-10 | Preparación fijada: migrar a la versión anterior, sembrar filas por SQL, aplicar `Adr161TipoIdentificadorFiscal`. MG-04 y MG-15: el relleno exige `Identificacion IS NOT NULL` | `bp:203-212`, `bp:152-162` |
| MG-10 | El `CK_Cliente_TipoIdentificador` se agrega **después** del relleno (paso 7 del `Up`) y el orden se prueba en el código de la migración | `bp:162` |
| MG-13 | Orden exacto del `Down`; no toca `audit.Bitacora`; la columna se quita también del historial | `bp:235-239` |
| MG-14 | Nombre de migración `AAAAMMDDhhmmss_Adr161TipoIdentificadorFiscal` y guion `gpos-empresa-<marca>_Adr161TipoIdentificadorFiscal.sql`, que **sustituye** al anterior | `bp:152-154` |
| ID-01 a ID-06 | Adaptados: la guarda del guion es **por `MigrationId`**, el SQL propio va entero en `EXEC(N'...')` y es idempotente por sí mismo. **ID-05 reescrito** (mi «base a medias» suponía guardas por objeto, que el blueprint no promete). Se agrega ID-07 | `bp:163`, `bp:228` |
| V-01 | El CP-169 existente **no cubre** las tablas nuevas (recorre el contexto heredado, no `EmpresaNgDbContext`): V-01 pasa a ser una prueba nueva sobre el contexto del modelo nuevo | `bp:132` |
| V-05 | El motor rechaza minúsculas y todo carácter fuera de `A-Z0-9_` con `CK_..._Codigo`; falta saber qué hace el servicio (400 o normalizar) | `bp:72` |
| U-02 | Con el CHECK, `'empresa'` falla por 547 (no por 2627); se agrega TI-D2 | `bp:72`, `bp:331` |
| U-04 | Reescrito como prueba de caracterización: la inmutabilidad de `Codigo` es **solo regla del servicio**, sin disparador | `bp:104` (cierra mi pregunta 6) |
| U-11 | Borrar un tipo sin uso borra también sus rangos en la misma transacción; B lo da como recomendación, no como firma | `bp:103` |
| U-17 | **Los Id 1 a 4 existen en todas las bases**: la prueba de aislamiento debe usar un Id ≥ 5 creado solo en la empresa A | `bp:34,144` |
| VL-08 | Cita 3.2.4: 9 caracteres con letras derivan a `P` y a `PASAPORTE_OTROS` | `bp:100` |
| VL-09, VL-10, VL-11 | Citan 7.5: DTO con `tipoIdentificadorId` opcional; el código se resuelve con `varchar(20) COLLATE DATABASE_DEFAULT` (comparación insensible a mayúsculas: `'empresa'` debería resolver); código inexistente = error de fila | `bp:245-246` |
| PR-09, PR-10 | Citan sección 9 del blueprint; se agrega PR-11 (cadena de propiedad de los usuarios de reportes) | `bp:257-258` |
| BT-01 a BT-07 | Fijado el destino: **`audit.Bitacora`** (`Usuario, Accion, Pantalla, Entidad=Codigo, Motivo, Detalle` JSON). Ya no se asume `_LOG`. El 409 no deja línea; las líneas no llevan identificaciones, solo cantidad; copia entre empresas = una línea en cada base | `bp:137` |
| M3-01, M3-02 | Nombres y forma de los índices y CHECK del blueprint | `bp:77-78,126-127` |
| M4-01 | Se mantiene (`ISoloCentral` en las dos entidades) | `bp:44,55,143` |
| M4-02 | **Se parte**: la bajada al nodo **no existe en el código** (sin `CHANGE_TRACKING`); lo que se prueba hoy es M4-05 (siembra idéntica en dos bases). M4-02 espera el diseño del nodo | `bp:143`, `bp:336` |
| M4-04 | La barrera es el `InterceptorSitio` (rechaza cambiar el catálogo en un nodo); el código HTTP sigue sin fijarse | `bp:143` |
| M5-01 a M5-03 | Quedan **condicionados a Q-TI-9**; la columna `TipoIdentificador` y el enmascarado van juntos en una **migración de vistas aparte**, no en la de ADR-161; `MigracionOla5VistasTests` exige que `database/ola5/` coincida | `bp:293`, `bp:345` |
| FI-01, FI-02, FI-05 | Confirmados por la sección «Fiscal: sin cambio» | `bp:139` |
| FI-03, FI-07 | Siguen abiertos: B los manda al especialista fiscal | `bp:272` (R-8) |
| **Nuevos** | A1-15 a A1-18; LP-07b, LP-10 a LP-15 y TI-D1; PF-12; CC-01 a CC-03; MG-15 a MG-18; ID-07; V-08, V-09; U-18 y TI-D2; VL-14, VL-15; PR-11; BT-08 a BT-10; B1-02; M4-05; M5-04 a M5-19 (enmascarado, M-5 del inventario); FI-10 | Detalle de cada uno en su sección |

## Fuentes leídas

1. **Blueprint de datos de B** (`bp`), completo.
2. La revisión de la DDL del arquitecto-datos (`traspasos/B/2026-10-22-revision-ddl-adr161.md`).
3. La propuesta del ADR-161 (`git show origin/master:docs/propuestas/2026-10-22-adr-161-propuesto-tipo-identificador-fiscal.md`), TI-01 a TI-09 y Q-TI-1 a Q-TI-7.
4. Mi inventario de salidas con identificación (`traspasos/C/2026-10-22-inventario-reportes-identificacion-tercero.md`, filas #1 a #22) y mi verificación de hechos de TT (`traspasos/C/2026-10-22-verificacion-codigo-hechos-tt.md`: ninguna ruta pone `Cliente.Inhabilitado=1`; `PuenteMae` copia la identificación sin `Inhabilitado`).
5. No existe `docs/adr/ADR-161.md`: el ADR sigue Propuesto (`bp:3`).

**Clave de tipo:** SQL = base `GPOS_TEST_*`; HTTP = API en proceso; TX = prueba de servicio/unidad dentro de transacción; ARQ = prueba sobre fuentes/ensamblados/mapeo.
**Dependencia:**
- `[F]` = firmada (Q-TI-2 a 7; TI-01 a 09 en su texto).
- `[B]` = definida por el blueprint de B (propuesta de diseño, **no firmada**; el ADR-161 sigue Propuesto). Va con la cita `bp:`.
- `[P]` = pendiente de firma del propietario (Q-TI-8 para M-2, Q-TI-9 para M-5).
- `[A]` = decisión abierta o inferida por mí.
- `CONFLICTO: pregunta para B` = el blueprint difiere de la revisión de la DDL.
**Convención de nombres de pruebas:** `Ti_...` (nombres sugeridos). Datos de ejemplo inventados y sintéticos.
**Filtro de suite del modelo nuevo (`bp:339`):** `--filter "Transicion!=Ola5&Transicion!=Defecto"`. No se corren dos suites a la vez.

## 1. A-1: la letra solo se deriva para identificadores solo de dígitos [B, obligatorio antes de construir; bp:87-97]

Hoy `TiposIdentificacion.TipoDe` decide por el largo (`Terceros.cs:116-122`) y `CK_Cliente_Identificacion`/`CK_Suplidor_Identificacion` exigen solo dígitos para `R` (9) y `C` (11) y 5 a 20 caracteres para `P` (`bp:19,21`). La forma propuesta es un `switch` con `v.All(char.IsAsciiDigit)` (`bp:89-96`). Tres llamadores: `MaestrosService.cs:197` y `:350` e `ImportacionMaestros.cs:218` (`bp:97`).

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| A1-01 | `Pasaporte_alfanumerico_de_9_no_recibe_R` | TX + SQL | Cliente con tipo `PASAPORTE_OTROS`, `Identificacion = 'AB1234567'` (9, con letras) | Alta OK; letra `P`; sin error 547 | `TipoDe` vuelve a decidir solo por largo (daría `R` y el CHECK rechaza) |
| A1-02 | `Pasaporte_alfanumerico_de_11_no_recibe_C` | TX + SQL | `'AB123456789'` (11) | Alta OK; letra `P` | ídem, con `C` |
| A1-03 | `Carnet_migracion_alfanumerico_de_9_u_11_se_guarda` | TX + SQL | `CARNET_MIGRACION` con `'M12345678'` (9) y `'M1234567890'` (11) | Alta OK, letra `P` | ídem |
| A1-04 | `Solo_digitos_de_9_sigue_siendo_R` (regresión) | TX + SQL | `'101234567'` con `EMPRESA` | Letra `R` | la corrección rompe el caso normal |
| A1-05 | `Solo_digitos_de_11_sigue_siendo_C` (regresión) | TX + SQL | `'00112345678'` | Letra `C` | ídem |
| A1-06 | `Cadena_con_guiones_se_normaliza_y_luego_decide` | TX | `'101-23456-7'` y `'AB-1234567'` | tras quitar guiones y espacios, `'101234567'` → `R`; `'AB1234567'` → `P` | la letra se decide antes de normalizar. (Nota: `FormatoRnc.Digitos` solo quita guiones y espacios, no letras: `bp:20`; el nombre engaña) |
| A1-07 | `Pasaporte_de_10_con_letras_es_P` (límite vecino) | TX + SQL | `'AB12345678'` | `P` | alguien «arregla» A1-01 y rompe el caso de 10 |
| A1-08 | `Pasaporte_solo_digitos_de_9_pero_tipo_pasaporte` | TX + SQL | Tipo `PASAPORTE_OTROS` con `'123456789'` (9 dígitos puros) | Letra `R` (por dígitos) y tipo `PASAPORTE_OTROS`, aceptado (TI-05: la letra no tiene que coincidir con el tipo; análogo a MG-05 y VL-13) | **[A]** pregunta 10 sigue abierta: el blueprint no la menciona. Falla si el CHECK o el servicio rechazan sin decisión |
| A1-09 | `Rango_definido_por_SUPER_menor_a_5_se_rechaza` | HTTP + SQL | SUPER crea un tipo con rango `Desde=3, Hasta=4`; y `INSERT` directo | 400/409 del servicio; en SQL directo, violación de `CK_TipoIdentificadorLargo_Rango` `[B bp:76]` | falta el CHECK o el servicio no valida |
| A1-10 | `Rango_mayor_a_20_o_invertido_se_rechaza` | HTTP + SQL | `Desde=5, Hasta=25`; `Desde=12, Hasta=8`; límites válidos `5-20` y `7-7` | los dos primeros rechazados (servicio y CHECK); `5-20` y `7-7` aceptados | CHECK incompleto (`Hasta BETWEEN Desde AND 20`) o demasiado estricto |
| A1-11 | `Importacion_con_pasaporte_alfanumerico_de_9` | TX + SQL | Fila de plantilla con `TipoIdentificador=PASAPORTE_OTROS`, id `'XY1234567'` | importada sin error 547 | la importación usa otro camino que no pasó por la corrección (`ImportacionMaestros.cs:218`) |
| A1-12 | `Suplidor_con_pasaporte_alfanumerico_de_9_u_11` | TX + SQL | igual que A1-01/02 sobre suplidor | OK | se corrige solo en cliente (`:197`) y no en suplidor (`:350`) |
| A1-13 | `Venta_copia_la_letra_correcta` | TX + SQL | Cliente de A1-01, venta | `CK_Venta_TipoIdentificacion` acepta la copia (`P`) (`bp:64`) | la venta recalcula la letra por otro método |
| A1-14 | `TipoDe_es_el_unico_punto_de_derivacion` | ARQ | búsqueda de `Length == 9`/`== 11` fuera de `TiposIdentificacion` y `FormatoRnc`; los llamadores de `TipoDe` son exactamente los tres del blueprint | ninguna otra derivación; la derivación del **tipo** (3.2.4) usa `TipoDe` y no una copia | otra clase repite la derivación por largo |
| **A1-15** | `Menos_de_5_caracteres_sin_tipo_da_422_no_547` | HTTP + TX | Alta sin tipo con `'1234'` (4) | 422 antes de guardar; ningún 547 ni 500 `[B bp:97]` | el CHECK de `P` (5 a 20) es lo único que lo detiene |
| **A1-16** | `Digitos_no_ASCII_no_cuentan_como_digitos` | TX | `'١٢٣٤٥٦٧٨٩'` (9 dígitos arábigo-índicos) | `TipoDe` da `P` (`char.IsAsciiDigit`, `bp:92-93`) | alguien cambia a `char.IsDigit` (aceptaría Unicode que el `varchar` convierte en `?`) |
| **A1-17** | `Nulo_vacio_o_solo_espacios_es_N` | TX | `null`, `""`, `"   "` (tras normalizar) | letra `N`, sin tipo, `Identificacion` nula | el `switch` trata `""` como `P` (`bp:91`) |
| **A1-18** | `Rango_fuera_de_tinyint_da_400_no_500` | HTTP | `Desde=300` o `Hasta=256` en el cuerpo | 400/422 del servicio | desbordamiento aritmético (`tinyint`, `bp:51-52`) llega como 500 |

Mutación global de A-1: revertir `TipoDe` a la versión actual → A1-01, A1-02, A1-03, A1-11 y A1-12 deben fallar (coincide con `bp:265,337`).

## 2. `LetraPorOmision` (M-1) [B; bp:40, 73-75, 100]

Columna `LetraPorOmision char(1) NULL`; `CK_TipoIdentificadorFiscal_Letra` (`R`, `C`, `P` o nulo); `CK_TipoIdentificadorFiscal_LetraActiva` (`LetraPorOmision IS NULL OR Inhabilitado = 0`); índice único filtrado `UQ_TipoIdentificadorFiscal_Letra`.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| LP-01 | `Siembra_marca_las_tres_letras` | SQL | Base nueva tras la migración | `EMPRESA→R`, `PERSONA_FISICA→C`, `PASAPORTE_OTROS→P`, `CARNET_MIGRACION→NULL` (`bp:169-172`) | la siembra olvida una marca |
| LP-02 | `CK_Letra_solo_R_C_P` | SQL | `UPDATE ... SET LetraPorOmision='N'` y `'X'` | violación de `CK_TipoIdentificadorFiscal_Letra` | CHECK ausente o con `N` |
| LP-03 | `Indice_unico_filtrado_de_letra` | SQL | Poner `R` a un segundo tipo (con `EMPRESA` activo); varias filas con NULL | el segundo `R` falla (`UQ_TipoIdentificadorFiscal_Letra`); varios NULL pasan | índice sin filtro (bloquea los NULL) o ausente |
| LP-04 | `Derivacion_usa_la_letra_por_omision_no_el_codigo` | TX | Renombrar vía SQL el `Codigo` de `EMPRESA` a `EMP2`, alta sin tipo con `'101234567'` | tipo derivado = `EMP2` (el que tiene `R`) (`bp:100`) | el servicio busca por el literal `'EMPRESA'` |
| LP-05 | `Inhabilitar_tipo_con_letra_por_omision_se_rechaza` | HTTP | SUPER inhabilita `EMPRESA` | 409 con mensaje «reasigne la letra antes» (el servicio traduce el 547 de `CK_..._LetraActiva`) | el servicio devuelve 500 por la violación del motor, o no hay control |
| **TI-D1** | `CK_LetraActiva_en_SQL_directo` (nombre de B) | SQL | `UPDATE cat.TipoIdentificadorFiscal SET Inhabilitado = 1 WHERE Codigo = 'EMPRESA'` | falla por `CK_TipoIdentificadorFiscal_LetraActiva` `[B bp:330]` | CHECK ausente |
| LP-06 | `Reasignar_la_letra_y_luego_inhabilitar` | HTTP | SUPER pasa `R` de `EMPRESA` a `EMP2`, luego inhabilita `EMPRESA` | OK; el alta por 9 dígitos deriva `EMP2` | el servicio exige que la letra siga atada a un código |
| LP-07 | `Cambio_de_regla_deja_sin_largo_el_9` | HTTP | SUPER quita el rango 9 al tipo con `R` | rechazo al configurar (esperado propuesto 409; **el código HTTP no lo fija el blueprint**, `bp:99`) | se permite y el alta falla luego, no al configurar |
| **LP-07b** | `Cambio_de_regla_deja_sin_largo_el_11` | HTTP | SUPER quita el rango 11 al tipo con `C` | rechazo, igual que LP-07 | solo se vigila la `R` |
| LP-08 | `Alta_sin_tipo_con_tipo_por_omision_inexistente` | TX | Quitar la letra `P` a todos los tipos (poner NULL) y dar de alta sin tipo `'AB123456'` | **422 con mensaje de configuración** `[B bp:100]` | `NullReferenceException` o 500 |
| LP-09 | `Copia_entre_empresas_conserva_la_letra_por_Codigo` | HTTP + SQL | Copiar tipos (Q-TI-7) de empresa A a B (B vacía de custom) | B tiene mismos códigos, rangos, `EsPersonaFisica`, `SoloDigitos` y letras, con Id propios (`bp:145`) | copia por Id o pierde la letra |
| **LP-10** | `Reasignar_letra_en_una_sola_operacion` | HTTP + SQL | `R` pasa de `EMPRESA` a `EMP2` en una sola petición | OK, sin violar el índice único en un estado intermedio (primero se libera, luego se asigna, en una transacción) | el orden de los `UPDATE` choca con `UQ_..._Letra` |
| **LP-11** | `Tipo_por_omision_que_no_admite_el_valor` | TX | El tipo con `P` tiene solo rango 5-8; alta sin tipo con 12 caracteres | 422 de configuración (`bp:100`: «si ese tipo… no admite el valor») | se guarda con un tipo que no cumple |
| **LP-12** | `Copia_no_sobrescribe_codigos_existentes` | HTTP + SQL | B ya tiene `EMPRESA` con rango distinto; copiar de A | `EMPRESA` de B intacto; la respuesta **informa** los códigos omitidos (`bp:145`) | sobrescribe, o no informa |
| **LP-13** | `Copia_de_letra_solo_si_el_destino_la_tiene_libre` | HTTP + SQL | B ya tiene la letra `P` en otro tipo; copiar un tipo con `P` | el tipo se crea con `LetraPorOmision = NULL`; el de B conserva la `P` | viola el índice único o mueve la letra |
| **LP-14** | `Letra_en_minuscula` | SQL + HTTP | `UPDATE ... SET LetraPorOmision = 'r'` | **posible hueco [I]**: el CHECK usa `IN ('R','C','P')` y la intercalación de las instalaciones es CI, así que `'r'` pasaría y chocaría con `'R'` en el índice único. Esperado: el servicio normaliza a mayúscula; documentar el resultado en SQL directo | pasa `'r'` y la derivación depende de la intercalación |
| **LP-15** | `Asignar_letra_a_tipo_inhabilitado_falla` | SQL | `UPDATE SET LetraPorOmision='C'` sobre un tipo con `Inhabilitado=1` | violación de `CK_..._LetraActiva` (`bp:74`) | CHECK de un solo sentido |

## 3. Cambio de `EsPersonaFisica`, de reglas, y concurrencia (M-2, Q-TI-5) [PF-01 a PF-04: B recomienda (a), **pendiente de firma Q-TI-8** (`bp:107-116`); Q-TI-5 es F]

Opción (a): 409 si el tipo tiene clientes o suplidores en tabla viva. Opción (b): se permite con `motivo` y línea en `audit.Bitacora` con antes, después y cantidad de registros (`bp:111-114`).

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| PF-01 | `Cambiar_EsPersonaFisica_con_clientes_da_409` **[opción (a), P]** | HTTP + SQL | `PERSONA_FISICA` con 2 clientes; SUPER pone `EsPersonaFisica=false` | 409; el cuerpo lista los 2 registros; el valor no cambia en la base | falta el control en el servicio |
| PF-02 | `Cambiar_EsPersonaFisica_con_suplidores_da_409` **[(a), P]** | HTTP + SQL | solo un suplidor usa el tipo | 409 | el control mira solo clientes |
| PF-03 | `Cambiar_EsPersonaFisica_sin_uso_es_200` | HTTP | tipo recién creado, sin filas | 200; valor cambiado (vale en (a) y (b)) | el control bloquea siempre |
| PF-04 | `Cambiar_descripcion_con_uso_no_da_409` | HTTP | cambiar solo `Descripcion` o `Notas` en un tipo usado | 200 (`bp:116`: en ambas opciones no se bloquea) | el control es demasiado amplio |
| PF-05 | `Uso_solo_en_historial_no_cuenta` | SQL + HTTP | cliente que tuvo el tipo en la tabla temporal pero hoy tiene otro | 200 (`bp:103`) | el control cuenta el historial |
| PF-06 | `Uso_cuenta_clientes_y_suplidores_inhabilitados` | HTTP + SQL | (a) cliente con `Inhabilitado=1` **sembrado por SQL** (ninguna ruta lo pone: hecho 0 de la verificación); (b) suplidor inhabilitado por la API (`Maestros.cs:115`) | 409 en ambos (`bp:103`: los inhabilitados cuentan, ADR-08) | el filtro excluye inhabilitados |
| PF-07 | `Alternativa_con_motivo` **[opción (b), P]** | HTTP + SQL | si el propietario firma (b) | 200 solo con `motivo`; línea en `audit.Bitacora` con antes, después y cantidad | **[P]** Q-TI-8 sin firma; ver pregunta 1 |
| PF-08 | `Cambio_de_regla_de_largo_con_incumplidores_da_409` (Q-TI-5, firmada) **[F, bp:101]** | HTTP + SQL | `PERSONA_FISICA` con un cliente de `'101234567'` (9) y un suplidor de 9; SUPER quita el rango 9 | 409 con ambos en la lista; la regla del tipo no cambia | falta el control de Q-TI-5 |
| PF-09 | `Cambio_de_regla_de_largo_sin_incumplidores_es_200` | HTTP | ampliar un rango | 200 | rechaza ampliaciones inocuas |
| PF-10 | `Efecto_en_TT_tras_el_cambio` | TX | cliente con tipo `PASAPORTE_OTROS` (física); tipo sin uso cambia → nuevo cliente | `EsPersonaFisica` del tipo manda (TI-07); con tipo nulo, vale la letra (`R` = jurídica, `C/P/N` = física) (de la propuesta, no del blueprint) | TI-07 no se aplica o ignora el caso nulo |
| PF-11 | `Comprobacion_de_uso_usa_el_indice` | SQL | plan de `SELECT TOP (@n) Id, Identificacion ... WHERE TipoIdentificadorId = @t` con 100 000 clientes | Seek sobre `IX_Cliente_TipoIdentificador` (`bp:126`), sin scan | **riesgo [I]**: un índice filtrado `WHERE ... IS NOT NULL` podría no usarse con parámetro; si el plan no lo usa, es un defecto del diseño (prueba opcional, rendimiento) |
| **PF-12** | `Cuerpo_del_409_y_datos_personales` | HTTP | PF-01/PF-08 | la lista del 409 trae los registros necesarios para corregirlos; **[A]** pregunta 14: ¿incluye la `Identificacion` (el índice la trae, `bp:126`) o solo Id y código? La respuesta solo llega al SUPER | el 409 expone identificaciones a quien no debe |
| **CC-01** | `Edicion_concurrente_da_409_REGISTRO_MODIFICADO` | HTTP + SQL | dos SUPER leen el tipo (misma `Version`); ambos editan | el segundo recibe 409 `REGISTRO_MODIFICADO` (K-59, `bp:42`) | falta la comprobación de `rowversion` |
| **CC-02** | `Editar_solo_los_rangos_cambia_la_Version_del_padre` | HTTP + SQL | cambiar solo los rangos, no el padre | la `Version` del padre cambia (el servicio marca el padre modificado, `bp:55`) | la edición de rangos escapa a la protección de concurrencia |
| **CC-03** | `Alta_de_cliente_vs_cambio_de_reglas` **[I, bp:105]** | TX | transacción 1: alta de cliente de 9 dígitos con `PERSONA_FISICA`; transacción 2: SUPER quita el rango 9 | nunca ambas: o el alta se hizo antes y el cambio ve el incumplidor (409), o el cambio va antes y el alta recibe 422 (`REPEATABLEREAD` / `UPDLOCK`, `bp:105`) | queda un cliente que incumple la regla nueva. Ver también pregunta 17 (orden de bloqueos) |

## 4. Migración (R→EMPRESA, C→PERSONA_FISICA, P→PASAPORTE_OTROS, N sin tipo) [B bp§7; F en el texto]

Preparación común: base en la migración anterior (`20261021001638_Ola5VistasTramo4`), filas sembradas por SQL en `cat.Cliente` y `cat.Suplidor`, luego se aplica `Adr161TipoIdentificadorFiscal`. El relleno solo toca filas con `Identificacion IS NOT NULL` y `TipoIdentificadorId IS NULL` (`bp:212,218`).

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| MG-01 | `Relleno_R_a_EMPRESA` | SQL | Cliente y suplidor con `TipoIdentificacion='R'`, id `'101234567'` | `TipoIdentificadorId` = Id de `EMPRESA`, buscado por `Codigo` (`bp:203`) | relleno por Id literal o por la letra por omisión |
| MG-02 | `Relleno_C_a_PERSONA_FISICA` | SQL | `'C'`, `'00112345678'` | Id de `PERSONA_FISICA` | ídem |
| MG-03 | `Relleno_P_a_PASAPORTE_OTROS` | SQL | `'P'`, `'AB123456'` | Id de `PASAPORTE_OTROS` (no `CARNET_MIGRACION`) | ídem |
| MG-04 | `N_queda_sin_tipo` | SQL | `'N'`, `Identificacion NULL` | `TipoIdentificadorId IS NULL` | el relleno asigna un tipo a `N` |
| MG-05 | `Persona_fisica_con_RNC_queda_EMPRESA` (límite documentado, `bp:231`) | SQL | `'R'` de 9 dígitos que en realidad es de una persona física | queda `EMPRESA` | alguien «adivina» y cambia la regla sin decisión |
| MG-06 | `Historial_no_se_rellena` | SQL | tabla de historial | filas previas con `TipoIdentificadorId IS NULL`; `SYSTEM_VERSIONING` sigue encendido (B-4, `bp:230`) | se reescribe la historia o se apagó el versionado |
| MG-07 | `Relleno_genera_historial_sin_perder_filas` | SQL | contar filas de historial antes/después | crece una fila por cliente/suplidor rellenado con el estado anterior (tipo nulo); ninguna se pierde | se apagó el versionado |
| MG-08 | `Relleno_idempotente` | SQL | Ejecutar el relleno dos veces tras corregir a mano un cliente a `PERSONA_FISICA` con RNC | la segunda pasada no pisa el cambio (`WHERE TipoIdentificadorId IS NULL`, `bp:228`) | falta la guarda |
| MG-09 | `Relleno_con_mayoria_de_filas_y_NULL_en_Identificacion` | SQL | 1 000 filas sintéticas de las 4 letras | conteo por tipo = conteo por letra anterior | pérdida o doble asignación |
| MG-10 | `CK_se_agrega_despues_del_relleno` | SQL + ARQ | (SQL) base con filas de las 4 letras; (ARQ) la migración llama `AddCheckConstraint CK_*_TipoIdentificador` **después** de `Sql(Adr161Relleno())` (`bp:162`) | sin error 547; `CK_Cliente_TipoIdentificador` y `CK_Suplidor_TipoIdentificador` presentes | el CHECK queda antes del relleno |
| MG-11 | `Siembra_de_los_cuatro_tipos_y_rangos` | SQL | base nueva | Id **1 a 4** con códigos `EMPRESA`, `PERSONA_FISICA`, `PASAPORTE_OTROS`, `CARNET_MIGRACION`; `EsPersonaFisica` 0/1/1/1; `SoloDigitos` 1/1/0/0; `Inhabilitado=0`; rangos: 9-9; 9-9 y 11-11 (sin 10); 5-20; 5-20 (`bp:167-172,188-193`) | siembra incompleta o con otros Id (rompe la copia al nodo, `bp:144`) |
| MG-12 | `Descripciones_sembradas_exactas` | SQL | | «Identificador Empresa», «Identificador Persona Física», «Pasaporte/otros», «Carnet de Migración» (acento OK en `varchar` 1252, `bp:199`) | acento corrupto |
| MG-13 | `Migracion_Down_y_Up` | SQL | aplicar `Down` y luego `Up` | `Down` quita en orden: CHECK e índices, FK y columnas (también del historial), luego `TipoIdentificadorLargo` y `TipoIdentificadorFiscal`; vuelve a quedar igual (`bp:235`) | `Down` deja residuos o falla por orden |
| MG-14 | `Marca_y_guion_acumulado_coinciden` | ARQ | marca posterior a `20261021001638_Ola5VistasTramo4`; clase `AAAAMMDDhhmmss_Adr161TipoIdentificadorFiscal`; guion `database/empresa/gpos-empresa-<marca>_Adr161TipoIdentificadorFiscal.sql` que **sustituye** al anterior y contiene la guarda por `MigrationId` (`bp:152-154`) | guion no regenerado o dos guiones acumulados |
| **MG-15** | `Letra_sin_identificacion_queda_sin_tipo` | SQL | fila con `TipoIdentificacion='R'` pero `Identificacion NULL` (si el CHECK existente lo admite; si no, documentar) | sin tipo; no viola `CK_Cliente_TipoIdentificador` (`bp:77,212`) | el relleno asigna tipo a una fila sin identificación |
| **MG-16** | `Bitacora_del_relleno` | SQL | migrar una base con filas; luego una sin filas; luego reaplicar | una línea en `audit.Bitacora` (`Usuario='MIGRACION'`, `Accion='Migrar'`, `Entidad='Adr161Relleno'`, `Detalle` JSON con `clientes` y `suplidores`); sin línea si el total es 0 y sin línea nueva en la segunda pasada (`bp:220-224`) | ausente, sin conteos, o duplicada |
| **MG-17** | `Relleno_no_toca_ModificadoPor_ni_ModificadoEn` | SQL | cliente con esos campos con valor | iguales tras el relleno (`bp:230`) | el relleno parece una edición de usuario |
| **MG-18** | `Down_no_toca_la_bitacora` | SQL | migrar, luego `Down` | las líneas de `audit.Bitacora` se conservan (`bp:239`) | `Down` borra bitácora |

## 5. Idempotencia del guion de esquema (aplicar dos veces) [B bp:163, 228]

La guarda del guion es **por `MigrationId`**; el SQL propio (`Adr161Siembra`, `Adr161Relleno`) va entero en `EXEC(N'...')` y es idempotente por sí mismo.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| ID-01 | `Guion_acumulado_dos_veces` | SQL | Aplicar el guion acumulado completo dos veces sobre la misma base | segunda ejecución sin errores y sin cambio (conteos y esquema iguales) | falta una guarda por `MigrationId` |
| ID-02 | `Siembra_no_duplica` | SQL | tras 2 aplicaciones | exactamente 4 tipos y los rangos esperados (sin duplicar la PK `(TipoIdentificadorId, Desde)`) | siembra sin `NOT EXISTS` por `Codigo` |
| ID-03 | `Guion_con_datos_de_clientes_y_dos_veces` | SQL | base con clientes ya rellenados; reaplicar | `TipoIdentificadorId` no cambia | relleno sin guarda |
| ID-04 | `Relleno_en_EXEC_dinamico` | ARQ/SQL | el guion se ejecuta en un solo lote contra una base **sin** la columna aún | compila el lote (el `UPDATE` va en `EXEC(N'...')`, `bp:163`) | error 207 «nombre de columna no válido» |
| ID-05 | `Guion_omite_lo_ya_registrado_en_MigrationId` (reescrito) | SQL | aplicar el guion; borrar a mano un tipo sembrado; reaplicar | **no** se restaura: la guarda es por migración, no por objeto. Documenta el comportamiento (mi v1 suponía recuperación de «base a medias», que el blueprint no promete) | el guion intenta rehacer una migración ya registrada |
| ID-06 | `Indice_y_CK_no_se_duplican` | SQL | `sys.indexes`/`sys.check_constraints` tras 2 pasadas | un solo `IX_Cliente_TipoIdentificador`, un solo `CK_*` | nombres sin guarda |
| **ID-07** | `SQL_propio_idempotente_por_si_mismo` | SQL | ejecutar `Adr161Siembra()` y `Adr161Relleno()` directamente, dos veces, sobre una base ya migrada | sin duplicados, sin errores, sin pisar correcciones (`bp:163`) | el SQL propio depende de la guarda externa |

## 6. `varchar` y largo de parámetros (ADR-50) [F; B-5; bp:131-132]

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| V-01 | `Largos_del_mapeo_nuevo_coinciden_con_el_esquema` (**prueba nueva** sobre `EmpresaNgDbContext`) | ARQ/SQL | `Codigo varchar(20)`, `Descripcion varchar(80)`, `Notas varchar(200)`, `LetraPorOmision char(1)` fija. El CP-169 existente recorre el contexto heredado y **no** cubre las tablas nuevas (`bp:132`) | el mapeo declara otro largo o `nvarchar` (B-1) |
| V-02 | `Columnas_son_varchar_no_nvarchar` | SQL | `sys.columns` de las dos tablas nuevas y de las dos columnas: ninguna `nvarchar` | EF mapea `string` por omisión como `nvarchar` |
| V-03 | `Parametros_Dapper_son_varchar_20` | ARQ | comandos Dapper del 409 y de la búsqueda por `Codigo`: `DbType.AnsiString`, `Size=20` | parámetro sin tipo (se infiere `nvarchar`) |
| V-04 | `Busqueda_por_codigo_usa_seek` | SQL | plan de `WHERE Codigo = @codigo` con `varchar(20)` | Scan por conversión implícita |
| V-05 | `Codigo_en_minusculas_o_con_espacio` | HTTP | `'empresa '`, `'Tipo-1'`, `'tipo_1'` | `CK_..._Codigo` rechaza minúsculas, espacio y guion en el motor (`bp:72`); **el servicio debe normalizar a mayúsculas (`'tipo_1'`→`TIPO_1`) o responder 400, no 500**. Qué elige: **[A]** pregunta 15 | el 547 llega al cliente como 500 |
| V-06 | `Acentos_en_descripcion` | HTTP + SQL | crear con `'Documento extranjero ñ'` | ida y vuelta exacta (página 1252) | pérdida de caracteres |
| V-07 | `Unicode_fuera_de_1252` | HTTP | `'日本'` en descripción | 400 o `?` documentado | pasa en silencio con datos corruptos **[A]** pregunta 5 |
| **V-08** | `Importacion_columna_temporal_smallint_y_codigo_COLLATE` | ARQ | las tablas temporales de `ComandosImportacion.cs` (`:34`, `:124`) llevan `TipoIdentificadorId smallint NULL`; el `JOIN` por código usa `varchar(20) COLLATE DATABASE_DEFAULT` (`bp:245`) | columna `nvarchar` o comparación con otra intercalación (conversión implícita, scan) |
| **V-09** | `Parametro_de_letra_es_char1` | ARQ | `@letra` como `AnsiStringFixedLength`, tamaño 1 (`bp:131`); `@t` como `smallint` | se infiere `nvarchar(1)` |

## 7. Unicidad y códigos inmutables [F para TI-01 «Codigo único»; bp:35, 72, 103-104]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| U-01 | `Codigo_duplicado_exacto_409` | HTTP | crear segundo `EMPRESA` | 409 (no 500 por violación de `UQ_TipoIdentificadorFiscal_Codigo`) | el servicio no traduce la violación 2627 |
| U-02 | `Codigo_duplicado_distinta_mayuscula` | HTTP | `'empresa'` con `EMPRESA` existente | 409 (o normalizado y luego 409); nunca 500 | `CK_..._Codigo` (547) llega sin traducir |
| **TI-D2** | `CK_Codigo_en_SQL_directo` (nombre de B) | SQL | `INSERT` con `Codigo='empresa'` | falla por `CK_TipoIdentificadorFiscal_Codigo` `[B bp:331]` | CHECK ausente |
| U-03 | `Codigo_inmutable_en_edicion` | HTTP | PUT cambiando `Codigo` | 400/409; `Codigo` intacto | el servicio acepta renombrar (rompe la copia por Código y LP-04) |
| U-04 | `Codigo_inmutable_solo_por_servicio` (caracterización) | SQL | `UPDATE ... SET Codigo` directo | **funciona**: la inmutabilidad es regla del servicio, sin disparador `[B bp:104]`. La prueba documenta que no hay disparador | alguien agrega un disparador sin decisión |
| U-05 | `Codigo_de_tipo_inhabilitado_no_se_reutiliza` | HTTP | inhabilitar y volver a crear el mismo `Codigo` | 409 (lo garantiza `UQ_..._Codigo`) | se reutiliza y confunde el historial |
| U-06 | `Rango_solapado_se_rechaza` | HTTP | `PERSONA_FISICA` con 9-11 y luego 10-12 | 400/422 (regla del servicio, `bp:99`) | falta la validación de servicio |
| U-07 | `Rango_duplicado_misma_Desde_PK` | SQL | dos filas con igual `(TipoIdentificadorId, Desde)` | violación de `PK_TipoIdentificadorLargo` | PK ausente |
| U-08 | `Tipo_activo_sin_rango_se_rechaza` | HTTP | crear tipo sin rangos | 400 (`bp:99`) | tipo inservible activo |
| U-09 | `FK_sin_cascada` | SQL | borrar un tipo con rangos o con clientes | falla por FK (`NO ACTION`; `bp:50,79`) | `ON DELETE CASCADE` (B-2) |
| U-10 | `Tipo_con_uso_no_se_borra_se_inhabilita` | HTTP | DELETE de tipo con clientes (incluido uno inhabilitado, sembrado por SQL) | 409/405; sí se puede inhabilitar (`bp:103`) | se borra con uso (ADR-08) |
| U-11 | `Tipo_sin_uso_se_borra_con_sus_rangos` | HTTP + SQL | DELETE de tipo sin uso | 200; desaparecen el tipo y sus rangos en la misma transacción (`bp:103`; recomendación de B, no firma) | rangos huérfanos o borrado parcial |
| U-12 | `CK_Cliente_TipoIdentificador` | SQL | `TipoIdentificadorId=1` con `Identificacion NULL` | violación de `CK_Cliente_TipoIdentificador` (`bp:77`) | CHECK ausente |
| U-13 | `Con_identificacion_tipo_obligatorio_en_servicio` | TX | alta con identificación y sin tipo | se deriva (TI-06) o 400 según el origen; nunca fila con identificación y tipo vacío por la pantalla (TI-04) (`bp:81`) | el servicio permite nulo desde la pantalla |
| U-14 | `Fila_antigua_con_identificacion_y_sin_tipo_es_valida` | SQL | fila previa sin tipo | admitida: **no** hay bicondicional en la DDL (`bp:81`) | alguien lo convierte en CHECK |
| U-15 | `Inhabilitado_no_aparece_en_catalogo_de_seleccion` | HTTP | `/api/catalogos/tipos-identificador` | solo activos | muestra inhabilitados |
| U-16 | `Cliente_con_tipo_inhabilitado_sigue_legible` | HTTP | cliente cuyo tipo se inhabilitó después | lectura y edición no relacionada funcionan (`bp:146`: la FK no mira `Inhabilitado`) | la inhabilitación rompe la edición del cliente |
| U-17 | `Tipo_de_otra_empresa_no_se_asigna` | HTTP + SQL | el SUPER crea en A un tipo con Id ≥ 5; empresa B referencia ese Id | rechazado por FK (el Id no existe en la base B). **Con Id 1 a 4 no sirve:** existen en todas las bases (`bp:14,144`) | el catálogo se comparte o la prueba usa un Id sembrado y no prueba nada |
| **U-18** | `Codigo_vacio_o_con_caracteres_no_permitidos` | SQL + HTTP | `''`, `'A B'`, `'Á'` | `CK_..._Codigo` (547, `LEN(Codigo) > 0`) y 400 del servicio (`bp:72`) | CHECK sin la rama `LEN` |

## 8. Validación del dato según el tipo (TI-02 y TI-04) [F; bp:98]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| VL-01 | `Persona_fisica_acepta_9_y_11_pero_no_10` | HTTP | `'101234567'`, `'00112345678'` OK; `'1012345678'` | 200, 200, 422/400 | el rango se implementó como mínimo-máximo (Q-TI-2) |
| VL-02 | `Empresa_solo_9` | HTTP | `'00112345678'` con `EMPRESA` | 422 | rango mal sembrado |
| VL-03 | `SoloDigitos_rechaza_letras` | HTTP | `'1012A4567'` con `EMPRESA` | 422 | `SoloDigitos` no se evalúa |
| VL-04 | `Pasaporte_5_y_20_limites` | HTTP | `'A1234'`, `'A'*20`; `'A123'`, `'A'*21` | OK, OK, 422, 422 | límite abierto/cerrado mal |
| VL-05 | `Identificacion_con_guiones_se_normaliza` | HTTP | `'101-23456-7'` con `EMPRESA` | guarda `101234567` | validación contra el texto con guiones |
| VL-06 | `Sin_identificacion_con_tipo` | HTTP | `Identificacion` vacía y tipo enviado | el motor ya rechaza guardar tipo sin identificación (`CK_Cliente_TipoIdentificador`); el servicio debe decidir entre ignorar el tipo y devolver 400, no 500 | **[A]** pregunta 4 |
| VL-07 | `Derivacion_propuesta_9_11_otro_vacio` (TI-06) | TX | pedido sin tipo con 9, 11, 7 y vacío (todos dígitos) | `EMPRESA`, `PERSONA_FISICA`, `PASAPORTE_OTROS`, NULL (vía letra por omisión, `bp:100`) | la derivación cambia del contrato |
| VL-08 | `Derivacion_de_9_con_letras_no_asigna_EMPRESA` | TX | sin tipo, `'AB1234567'` | `PASAPORTE_OTROS` (`bp:100`) | la derivación TI-06 repite el defecto A-1 |
| VL-09 | `Cliente_desplegado_antiguo_sin_campo` | HTTP | JSON sin `tipoIdentificadorId` | 200 con tipo derivado (`bp:246`) | el campo se vuelve obligatorio |
| VL-10 | `Importacion_columna_TipoIdentificador_opcional` | TX | plantilla sin columna, con columna válida, con código inexistente | derivado, aplicado, error de fila (no aborta el lote) (`bp:245`) | la importación aborta o ignora el código en silencio |
| VL-11 | `Importacion_codigo_en_minusculas` | TX | `'empresa'` | resuelve a `EMPRESA` (comparación con `COLLATE DATABASE_DEFAULT`, CI) **[B, inferido de bp:245]** | error de fila por mayúsculas |
| VL-12 | `Editar_identificacion_revalida_contra_el_tipo` | HTTP | cambiar `Identificacion` de 9 a 7 dígitos con tipo `EMPRESA` | 422 | solo se valida en el alta |
| VL-13 | `Reglas_nuevas_no_invalidan_la_letra` | TX | persona física `PERSONA_FISICA` con 9 dígitos | letra `R`, tipo `PERSONA_FISICA` (TI-05) | alguien exige coincidencia letra/tipo |
| **VL-14** | `Importacion_fila_existente_conserva_tipo_valido` | TX | fila existente con `PASAPORTE_OTROS`; plantilla sin columna de tipo y misma identificación | se **conserva** el tipo guardado (criterio aditivo R4-22, `bp:245`) | la importación lo pisa con el derivado |
| **VL-15** | `Importacion_fila_existente_deriva_si_el_tipo_ya_no_vale` | TX | fila existente con `EMPRESA` (9); plantilla trae identificación de 11 dígitos sin tipo | se deriva (`PERSONA_FISICA`) | queda un tipo que no admite el valor |

## 9. Privilegios (TI-03) [F: solo el SUPER define; B-6: sin permisos SQL nuevos; bp§9]

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| PR-01 | `ADMIN_no_puede_crear_tipo` (`POST /api/super/tipos-identificador`) | HTTP | 403 (regla de aplicación, `bp:259`) | la ruta usa política de ADMIN |
| PR-02 | `USER_no_puede_crear_ni_editar` | HTTP | 403 (POST, PUT, inhabilitar) | idem |
| PR-03 | `SUPER_si_puede` y exige empresa del token | HTTP | 200/201 | autorización demasiado cerrada |
| PR-04 | `SUPER_actua_sobre_la_empresa_correcta` | HTTP + SQL | SUPER de la empresa A del token no modifica el catálogo de B pasando el Id | falta aislamiento entre empresas |
| PR-05 | `Lectura_del_catalogo_para_quien_registra_clientes` | HTTP | USER con privilegio de crear clientes: 200; sin él: 403 **[A]** pregunta 3 (el blueprint no fija el privilegio de lectura) | lectura abierta a cualquier autenticado de otra empresa (H-01/H-02) |
| PR-06 | `Sin_token_401` | HTTP | 401 en ambas rutas | ruta sin `RequireAuthorization` |
| PR-07 | `SUPER_con_motivo_si_se_exige` | HTTP | **[A]** el blueprint exige `motivo` solo en la opción (b) de M-2 (`bp:114`); para el resto no dice | pregunta 3 |
| PR-08 | `Copia_entre_empresas_solo_del_mismo_dueno` (Q-TI-7) | HTTP | origen y destino de la misma instalación; empresa ajena rechazada | copia hacia empresa sin acceso |
| PR-09 | `gpos_app_sin_permiso_extra` | SQL | `SELECT/INSERT/UPDATE/DELETE` sobre las tablas nuevas sin `GRANT` extra (`bp:257`) | las tablas nacen en un esquema sin permisos |
| PR-10 | `Usuario_SQL_de_reportes_no_escribe_ni_lee_cat` | SQL | `gpos_reportes` y `gpos_lectura` no pueden `INSERT` ni `SELECT` directo en `cat.TipoIdentificadorFiscal` (`bp:258`: leen solo vistas `rpt`/`rptc`) | permisos excesivos |
| **PR-11** | `Reportes_leen_la_vista_con_el_tipo_sin_permiso_en_cat` | SQL | con la vista de TI-08/M-5 (cuando exista), `gpos_reportes` lee `rpt.CatCliente` con la columna `TipoIdentificador` aunque no tenga permiso sobre `cat` (cadena de propiedad; `bp:258` lo marca inferido) | la vista falla con 229 en producción |

## 10. Bitácora [B: `audit.Bitacora`, bp:137]

Forma de la línea: `Usuario`, `Accion`, `Pantalla`, `Entidad = Codigo` y `Detalle` JSON con antes y después de columnas y rangos; `Motivo` cuando aplica. Misma forma que la migración RS-03. **Reemplaza mi suposición de `_LOG`.**

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| BT-01 | `Alta_de_tipo_deja_linea` | HTTP + SQL | línea con usuario, `Entidad = Codigo` | falta la línea |
| BT-02 | `Cambio_de_reglas_deja_linea_con_antes_y_despues` | HTTP + SQL | rangos antes/después en `Detalle` | sin traza del SUPER |
| BT-03 | `Cambio_de_EsPersonaFisica_deja_linea_y_motivo` **[(b), P]** | HTTP + SQL | línea con motivo, antes, después y cantidad afectada (`bp:114`) | cambio silencioso |
| BT-04 | `Inhabilitar_deja_linea` | HTTP + SQL | idem | |
| BT-05 | `409_no_deja_linea_de_exito` | HTTP + SQL | el rechazo no registra un cambio que no ocurrió (`bp:137`) | bitácora escrita antes de validar |
| BT-06 | `Bitacora_sin_datos_personales` | HTTP + SQL | las líneas de un 409 llevan solo la **cantidad**, no las identificaciones (`bp:137`) | fuga de identificadores en la bitácora |
| BT-07 | `Copia_entre_empresas_deja_linea_en_ambas` | HTTP + SQL | una línea en cada base (`bp:137,145`) | solo en una |
| **BT-08** | `Reasignar_letra_deja_linea` | HTTP + SQL | línea con la letra antes y después (la reasignación está en la lista, `bp:137`) | omitida |
| **BT-09** | `Borrar_tipo_deja_linea_con_rangos` | HTTP + SQL | línea con el tipo y sus rangos en `Detalle` | se pierde la regla borrada |
| **BT-10** | `Forma_de_la_linea` | SQL | columnas `Usuario, Accion, Pantalla, Entidad, Motivo, Detalle` pobladas según `bp:137`; `Detalle` es JSON válido | línea en otra forma que la de RS-03 |

## 11. Hallazgos M-3, M-4 y bajos [B]

| ID | Hallazgo | Prueba | Tipo | Esperado | Falla si… (mutación) |
|---|---|---|---|---|---|
| M1-C | M-1 | cubierto por LP-04, LP-05 y TI-D1 | | | quitar `LetraPorOmision` y volver a derivar por código |
| M2-C | M-2 | cubierto por PF-01/02 [P] | | | quitar el 409 de `EsPersonaFisica` |
| M3-01 | M-3 | `Indices_filtrados_con_INCLUDE_existen` | SQL | `IX_Cliente_TipoIdentificador` e `IX_Suplidor_TipoIdentificador` en `sys.indexes` con filtro `TipoIdentificadorId IS NOT NULL` e `INCLUDE (Identificacion)` (`bp:126-127`) | se borra el `HasIndex` del mapeo |
| M3-02 | M-3 | `CK_Cliente_TipoIdentificador` y `CK_Suplidor_TipoIdentificador` | SQL | ver U-12; el homólogo en suplidor (`bp:78`) | CHECK solo en cliente |
| M4-01 | M-4 | `Catalogo_es_ISoloCentral` | ARQ | `TipoIdentificadorFiscal` (por `CatalogoSimple`) y `TipoIdentificadorLargo` implementan `ISoloCentral` (`bp:44,55,143`) | falta la interfaz |
| M4-02 | M-4 | `Ids_iguales_en_el_nodo` | SQL | **espera el diseño del nodo**: la bajada con `CHANGE_TRACKING` no existe en el código (`bp:143`). Cuando exista: inserta con `IDENTITY_INSERT` conservando el Id; un cliente creado en el nodo sincroniza sin romper la FK | el catálogo baja con Ids regenerados |
| **M4-05** | M-4 | `Siembra_identica_en_dos_bases` | SQL | dos bases creadas por la misma migración tienen los mismos Id 1 a 4 con los mismos códigos (`bp:144`); **sí se puede probar hoy** | la siembra depende de `IDENTITY` sin Id explícito |
| M4-03 | M-4 | `Copia_entre_empresas_por_Codigo` | HTTP + SQL | ver LP-09, LP-12, LP-13 | copia por Id |
| M4-04 | M-4 | `Nodo_no_crea_ni_edita_tipos` | TX | el `InterceptorSitio` rechaza `SaveChanges` sobre las dos tablas en un nodo (`bp:143`); **[A]** el código HTTP no se fija; entrega 2 | el nodo escribe el catálogo |
| M5-01 a M5-03 | M-5 | ver sección 12 (dependen de Q-TI-9) | | | |
| B1-01 | B-1 | `Forma_de_CatalogoSimple` | ARQ | `TipoIdentificadorFiscal : CatalogoSimple`; sin columnas de fechas ni autor; `Version rowversion` (`bp:30,44`) | se copian columnas de autoría que no existen |
| **B1-02** | B-1/B-2 | `Largo_sin_Version_propia` | ARQ | `TipoIdentificadorLargo : ISoloCentral` sin `Version` ni fechas (`bp:55`) | la concurrencia queda repartida en dos `Version` |
| B2-01 | B-2 | cubierto por U-07, U-09, A1-09/10 | | | |
| B4-01 | B-4 | cubierto por MG-06/07 | | | |
| B5-01 | B-5 | cubierto por V-01 a V-05 | | | |

## 12. M-5: enmascarado en `rpt` y salidas que NO se enmascaran [P: Q-TI-9; bp§11 y mi inventario]

**Hecho verificado en mi inventario (filas #1, #3, #5, #6, #7):** `rpt.VentaDocumento`, `rpt.Cotizacion`, `rpt.ConsultaFactura`, `rpt.CatCliente` y `rpt.CatSuplidor` dejan la identificación íntegra si la letra es `R` y enmascaran `C` y `P` (`'*******'` más los últimos 4). Una persona física con RNC de 9 dígitos conserva la `R` y sale completa a quien no tiene «Ver datos personales» (`bp:277`). Opción (b) de B: enmascarar por `EsPersonaFisica` del tipo **actual**, con caída a la letra si no hay tipo (`bp:290`). Opción (a): sin cambio. Opción (c): copiar la clasificación al documento. **Los casos M5-02 a M5-10 y M5-18 solo valen si se firma (b)**; los de la parte «no se enmascara» valen siempre. La migración de vistas va aparte de la de ADR-161 (`bp:293`).

Parte A: columna de TI-08 y contrato.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| M5-01 | `rpt_cliente_tiene_columna_TipoIdentificador` (TI-08) | SQL | `rpt.CatCliente` con cliente con tipo y otro sin tipo | devuelve `TipoIdentificador` con el código, `NULL` si no hay tipo; ambas filas presentes | columna ausente o `JOIN` interno que pierde clientes |
| M5-03 | `Subida_de_contrato_y_huella` (ADR-109 cl. 11) | ARQ | `MigracionOla5VistasTests`: `database/ola5/` coincide con la migración de vistas; versión de contrato incrementada y huella actualizada (`bp:293`) | vista cambia sin subir versión |

Parte B: enmascarado por `EsPersonaFisica` [P, solo con la opción (b)]. Usuario de `rpt` sin «Ver datos personales», salvo que se diga otra cosa.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| M5-02 | `CatCliente_enmascara_persona_fisica_con_RNC_de_9` | SQL | cliente `PERSONA_FISICA`, `'101234567'` (letra `R`) | `'*******4567'`; un cliente `EMPRESA` con la misma forma sale íntegro | la vista sigue guiándose por la letra |
| M5-04 | `CatSuplidor_enmascara_igual` | SQL | suplidor `PERSONA_FISICA` con 9 dígitos | enmascarado; `EMPRESA` íntegro | solo se corrigió el cliente |
| M5-05 | `VentaDocumento_enmascara_con_la_clasificacion_vigente` | SQL | venta vieja a un cliente que hoy es `PERSONA_FISICA` | enmascarado (`bp:290`: protege más, el documento histórico usa la clasificación vigente) | usa la letra copiada en la venta |
| M5-06 | `Cotizacion_enmascara_igual` | SQL | cotización a persona física con 9 dígitos | enmascarado | |
| M5-07 | `ConsultaFactura_enmascara_igual_en_la_definicion_vigente` | SQL | factura a persona física con 9 dígitos | enmascarado; la prueba va contra la vista **desplegada** (hay dos definiciones en el repositorio, `bp:281`) | se corrige la definición equivocada |
| M5-08 | `Sin_tipo_cae_a_la_letra` | SQL | cliente antiguo sin tipo y venta a `GENERICO` con RNC escrito a mano | `R` íntegra, `C/P` enmascarada, igual que hoy (`bp:290`) | el `LEFT JOIN` cambia el resultado de lo no clasificado |
| M5-09 | `EsPersonaFisica_falso_con_letra_C_o_P` | SQL | tipo propio `EsPersonaFisica=0`, 11 dígitos (letra `C`) | **[A]** pregunta 12: ¿se enmascara por la letra o sale íntegro? | la regla no tiene decisión |
| M5-10 | `El_JOIN_no_pierde_ni_duplica_filas` | SQL | conteo de filas de las 5 vistas con clientes con tipo, sin tipo y con tipo inhabilitado, antes y después | iguales (unión por PK, 1:1) | filas perdidas o duplicadas |
| M5-18 | `Reclasificar_cambia_el_enmascarado` | SQL + HTTP | tipo sin uso cambia `EsPersonaFisica`; luego un cliente nuevo | el enmascarado de los clientes nuevos sigue al valor vigente. Si se firmó Q-TI-8 (b) y hay uso, el cambio reclasifica a todos (documentar) | enmascarado obsoleto |

Parte C: no cambian, valen en (a), (b) y (c).

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| M5-11 | `rptc_sin_cambio` | SQL | `rptc.VentaDocumento`, `rptc.Cotizacion`, `rptc.ConsultaFactura`, `rptc.CatCliente`, `rptc.CatSuplidor` con «Ver datos personales» | R y C completas, P últimos 4, como hoy (inventario #2, #4, #5, #6, #7) | el cambio de `rpt` arrastra a `rptc` |
| M5-12 | `Formato606_no_se_enmascara` | SQL | `rpt.Formato606` con proveedor persona física | RNC/cédula íntegros (inventario #11; `bp:285`) | alguien enmascara y rompe el 606 |
| M5-13 | `Formato607_no_se_enmascara` | SQL | `rpt.Formato607` (si existe en la rama; el 607 está aplazado) | `RncReceptor` íntegro (inventario #12); **sin e-NCF** | se enmascara el 607 |
| M5-14 | `Comprobantes_impresos_no_se_enmascaran` | TX/ARQ | factura, ticket y retención con RNC del comprador y del suplidor (`FabricaModelo`, `FormatoDocumento`, `FormatoTicket`; inventario #14, #15) | RNC completo | se enmascara dato obligatorio del comprobante |
| M5-17 | `Pantallas_operativas_no_se_enmascaran` | TX | autocompletar de maestros (`ConsultasMaestros.cs:16-29`), búsqueda de facturas por RNC y consulta de compras (inventario #16 a #18) | siguen mostrando y buscando por la identificación completa | enmascarar rompe la búsqueda |
| M5-19 | `Exportaciones_heredan_el_enmascarado` | TX | exportar CSV/XLSX de `rpt.CatCliente` | el archivo sale con el mismo enmascarado que la vista (inventario #22, [I]) | la exportación lee otra fuente |

Parte D: fuga previa, independiente de ADR-161 (inventario #8 y #10).

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| M5-15 | `EF_CAJA_CHICA_no_filtra_RNC_completo` | SQL/TX | ejecutar el reporte del sistema «Gastos de caja chica» (`EF-CAJA-CHICA`, `ReportesSemilla.cs:303-304`: `g.RncCedula AS RNC` sobre `caja.CajaChica`) con un usuario sin «Ver datos personales» | **hoy falla** (RNC íntegro: elude el enmascarado de `rpt.CajaChica`, inventario #10, verificado por mí). Esperado tras corregir: enmascarado igual que `rpt.CajaChica`. **[A]** pregunta 13: no está en el blueprint; decidir si entra en este PR o aparte | el reporte sigue sin enmascarar |
| M5-16 | `CajaChica_enmascara_por_largo_no_por_letra` | SQL | `rpt.CajaChica` con RNC de 9 y cédula de 11 | no cambia con A-1 ni con el catálogo (decide por `LEN`, inventario #8; `CK_CajaChica_Rnc`) | alguien lo ata al tipo de identificador sin decisión |

## 13. Impacto en 606/607/608 y e-CF (no regresión; bp:139, 272)

La letra y el contenido de los reportes deben seguir iguales. «Fiscal: sin cambio» (`bp:139`).

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| FI-01 | `Tipo_606_sigue_por_el_largo` (`FisConfiguracion.cs:275-287`) | TX + SQL | suplidor `'101234567'` → tipo `1`; `'00112345678'` → `2` (`bp:139`) | el 606 pasa a leer `EsPersonaFisica` |
| FI-02 | `606_persona_fisica_con_RNC_9_sigue_tipo_1` | TX + SQL | suplidor `PERSONA_FISICA` con 9 dígitos conserva `1` (TI-05) | alguien sincroniza la letra con el tipo |
| FI-03 | `606_pasaporte_alfanumerico_9` | TX + SQL | suplidor extranjero (A-1): no explota; resultado según regla vigente **[A]** pregunta 9: B la manda al especialista fiscal (`bp:272` R-8; `CK_Registro606_Rnc` exige 9 u 11 dígitos, ya hoy) | excepción o tipo incorrecto |
| FI-04 | `607_608_sin_cambio` | SQL | 607/608 aplazados y sin e-NCF; si las vistas existen en la rama, mismo resultado antes y después | cambio de columnas rompe la vista |
| FI-05 | `Copia_del_tipo_en_la_venta` (`CK_Venta_TipoIdentificacion`) | SQL | la venta guarda `R`, `C` o `P` como antes (`bp:64`) | se guarda el Id del tipo en la venta |
| FI-06 | `eCF_receptor_no_cambia` | HTTP | **[A]** emisión e-CF por campos canónicos (ADR-51/108); con un cliente `CARNET_MIGRACION` (letra `P`) el JSON del receptor coincide con el de antes | el conector depende del código del tipo o de `TipoIdentificadorId` (violaría 73.7) |
| FI-07 | `eCF_receptor_extranjero_con_pasaporte` | HTTP | **[A]** mismo cuerpo que hoy | pregunta 9 |
| FI-08 | `RNC_padron_en_SYSDATA_no_cambia` | SQL | la validación de RNC contra el padrón se mantiene | `FormatoRnc.EsValido` se aplica a tipos que no son RNC |
| FI-09 | `FormatoRnc_EsValido` sigue 9 u 11 solo dígitos | TX | | cambio de contrato público de `GPOS.Contracts` |
| **FI-10** | `PuenteMae_con_tipo_e_identificacion_alfanumerica` | TX + SQL | alta de cliente `PASAPORTE_OTROS` con `'AB1234567'`: `PuenteMae` copia la identificación al heredado (mi verificación: copia el RNC, sin `Inhabilitado`) | no copia `TipoIdentificadorId` (el heredado no lo tiene) y no falla por el largo o formato de `h.RNC` con letras **[I]: no leí el esquema del heredado** | el alta falla en el puente con pasaportes |

## 14. Orden recomendado y esfuerzo

1. **Primero, sin base:** A1-01 a A1-07, A1-14 a A1-17, VL-07/VL-08 (unidad, minutos) y los ARQ (M4-01, B1-01, B1-02, V-03, V-08, V-09, MG-14, M5-03). Detectan el defecto Alto y son baratos.
2. **Segundo, SQL:** MG-*, ID-*, LP-01 a LP-03, TI-D1, TI-D2, V-01/V-02, U-07, U-09, U-12, U-18, M3-*, M4-05 (coincide con `bp:314,324-331`).
3. **Tercero, servicio y HTTP:** LP-04 a LP-15, PF-*, CC-*, U-01 a U-06, U-13 a U-17, VL-*, PR-*, BT-*, A1-09, A1-10, A1-15, A1-18.
4. **Cuarto, con decisión previa:** PF-01/02/07 y BT-03 tras Q-TI-8; M5-01, M5-02 a M5-10 y M5-18 tras Q-TI-9; FI-03/06/07 tras el especialista fiscal. M5-11 a M5-17, M5-19 pueden hacerse ya (regresión), salvo M5-13 si el 607 no existe en la rama.
5. **Después:** M4-02/04 con el diseño de nodos (entrega 2).

**Esfuerzo inferido (±40 %, 1 sp = 5 días-persona):** unas 177 pruebas.
- Datos y migración, con los nuevos (MG, ID, LP, TI-D, V, U-12, M3, M4-05): **0,2 a 0,3 sp**. El blueprint estima 1 a 1,5 dp para esta parte (`bp:314`) y yo no lo bajo de 1 dp.
- Servicio y HTTP, con CC y VL nuevos: 0,2 a 0,25 sp.
- Privilegios y bitácora: 0,07 a 0,1 sp.
- Enmascarado en reportes (M5, 17 casos sobre vistas, solo si se firma (b) en su mayor parte): 0,1 a 0,15 sp.
- **Total: 0,57 a 0,8 sp**, frente a los 0,35 a 0,5 sp de la v1 y a los 0,2 a 0,3 sp que reservaba la propuesta de B. El aumento viene de M-1/M-3/M-4 (siembra con Id, CHECK adicionales), de la concurrencia y del enmascarado M-5, que no estaba en la v1. Costo de infraestructura: USD 0. Una suite SQL con bases `GPOS_TEST_*` por clase; no dos suites a la vez.

## 15. Preguntas para B: estado tras el blueprint

| # | Pregunta | Estado | Cierre o motivo |
|---|---|---|---|
| 1 | M-2: ¿409 o motivo+bitácora? | **Abierta** | `bp:116,344`: B recomienda (a) 409; **falta la firma del propietario (Q-TI-8)**. PF-01/02 y PF-07/BT-03 se mantienen separados |
| 2 | Bitácora: ¿dónde y con qué campos? | **Cerrada** | `audit.Bitacora`, columnas y contenido en `bp:137`; BT-01 a BT-10 |
| 3 | Privilegios: lectura del catálogo y motivo del SUPER | **Abierta** (parte resuelta) | Resuelto: solo el SUPER define (`bp:259`) y sin permisos SQL nuevos (`bp:257`). Sin resolver: qué privilegio da lectura del catálogo y si la edición del SUPER exige `motivo` (solo lo exige M-2 (b)) |
| 4 | TI-04: tipo sin identificación | **Abierta** | El motor lo rechaza (`CK_Cliente_TipoIdentificador`, `bp:77`), pero el blueprint no dice si el servicio ignora el tipo o responde 400 (VL-06) |
| 5 | Unicode fuera de 1252 | **Abierta** | `bp:199` solo cubre tildes de la 1252 |
| 6 | `Codigo` inmutable: ¿servicio o base? ¿se borra sin uso? | **Cerrada** | Solo servicio, sin disparador (`bp:104`); se borra el tipo sin uso, con sus rangos (`bp:103`, recomendación). U-04 y U-11 |
| 7 | Nodos: ¿`ISoloCentral` con Id conservado? | **Cerrada (diseño)** | `bp§6` (`bp:143-146`); la bajada no existe aún, M4-02/04 esperan la entrega 2 |
| 8 | M-5: ¿enmascarado por `EsPersonaFisica`? | **Abierta** | `bp:293,345`: inclinación (b), **pendiente de Q-TI-9**. Sección 12 de estos casos |
| 9 | 606 y e-CF para extranjeros con pasaporte | **Abierta** | `bp:272` (R-8): fuera del ADR; va al especialista fiscal |
| 10 | A1-08: pasaporte de 9 dígitos puros (letra `R`) | **Abierta** | El blueprint no la menciona. Mi lectura: TI-05 lo permite |
| 11 | Nombres | **Cerrada** | `TipoIdentificadorId`, `cat.TipoIdentificadorFiscal` y además `cat.TipoIdentificadorLargo` (`bp:28-61`) |

**Resumen: cerradas 4 (2, 6, 7, 11); abiertas 7 (1, 3 en parte, 4, 5, 8, 9, 10).** De las abiertas, 1 y 8 dependen de la firma del propietario y 9 del especialista fiscal.

**Preguntas nuevas que sale del blueprint:**

12. **M-5 (b):** para un tipo con `EsPersonaFisica = 0` y letra `C` o `P` (un tipo propio del SUPER), ¿se enmascara por la letra o sale íntegro? (M5-09)
13. **`EF-CAJA-CHICA`:** el reporte del sistema muestra el RNC completo y elude el enmascarado de `rpt.CajaChica` (fuga de mi inventario #10, no del ADR-161). ¿Se corrige en el PR de M-5 o aparte? (M5-15)
14. **Cuerpo del 409 (Q-TI-5 y M-2):** ¿la lista de incumplidores lleva la `Identificacion` o solo Id y código? (PF-12)
15. **`Codigo` en minúsculas o con caracteres no permitidos:** el motor lo rechaza; ¿el servicio normaliza a mayúsculas o responde 400? Lo mismo para `LetraPorOmision` en minúscula (LP-14). (U-02, V-05)
16. **`LetraPorOmision` y `CK` con intercalación CI:** `IN ('R','C','P')` acepta `'r'` y el índice único la tomaría como igual a `'R'`; ¿se agrega `COLLATE Latin1_General_BIN` como en el CHECK del código? (LP-14)
17. **Orden de bloqueos (CLAUDE.md, «orden único de bloqueos»):** la regla 3.2.9 toma `REPEATABLEREAD` y `UPDLOCK` sobre la fila del tipo desde el alta de cliente y desde el cambio del SUPER; ¿en qué posición del orden (jornada → almacenes → documentos → configuración → series → NCF → …) va esa fila, para no crear interbloqueos? (CC-03)
18. **PuenteMae:** el heredado no tiene el tipo; ¿el puente debe copiar la identificación alfanumérica de un pasaporte tal cual (`RNC` en el heredado) o limitarla? (FI-10)

### Conflictos con la revisión de la DDL

El blueprint resuelve la revisión sin contradecirla en lo esencial (A-1, M-1 a M-4, B-1 a B-6, DDL mínima de su sección 3). Hay dos diferencias menores y una corrección de un supuesto:

1. **CONFLICTO (menor): pregunta para B.** M-1 de la revisión decía «el **servicio** rechaza inhabilitar un tipo con letra por omisión»; el blueprint lo pasa al **motor** (`CK_TipoIdentificadorFiscal_LetraActiva`, `bp:74`). No es una contradicción sino un endurecimiento, pero obliga al servicio a traducir el 547 (LP-05) y al SUPER a reasignar la letra en un orden compatible con el índice único (LP-10). Se confirma para que no se quite el CHECK al implementar.
2. **CONFLICTO (menor): pregunta para B.** La revisión (B-3 b) pedía el SQL «por `Codigo`, no por Id literal». La siembra del blueprint usa **Id 1 a 4 literales** con `IDENTITY_INSERT`, y enlaza los rangos por `Codigo` (`bp:144,197`). Lo justifica (mismos Id en central y nodo) y no genera falla, pero la condición de la siembra `t.Codigo = s.Codigo OR t.Id = s.Id` (`bp:185`) deja un caso sin probar: ¿qué pasa si ya existe el Id con otro código? Con `Codigo` inmutable no debería ocurrir; MG-11/ID-02 solo prueban el caso normal.
3. **Corrección de supuesto.** La revisión (M-4) asumía el «mismo mecanismo de bajada de los demás catálogos». El blueprint dice que **no existe** en el código (sin `CHANGE_TRACKING`, `bp:143`). Mis casos M4-02/04 quedan para la entrega 2; M4-05 cubre lo probable hoy.

## 16. Qué no verifiqué

- No se compiló ni se ejecutó nada. Los nombres de pruebas, rutas y columnas son los del blueprint; no existen en el código.
- Leí el blueprint **completo** desde `FETCH_HEAD` (`c2394b85`, rama `origin/b/adr161-datos`). **No verifiqué sus citas [V] al código** (`Terceros.cs`, `MaeConfiguracion.cs`, `MaestrosService.cs`, `ImportacionMaestros.cs`, `ComandosImportacion.cs`, `FisConfiguracion.cs`, `EmpresaNgDbContext.cs`, `InterceptorSitio.cs`, el guion acumulado, `ConsultasVarcharTests.cs`, `database/ola5/*`): las tomo como las da B. La parte de vistas de M-5 sí viene de mi propio inventario (verificado por mí solo en la fila #10).
- El comando `git diff origin/master...origin/b/adr161-datos` no devolvió salida útil en mi árbol; leí el archivo directamente con `git show FETCH_HEAD:<ruta>`. La rama trae además cambios ajenos a este tema (ADR-007/093/110, `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md`, hojas de firma de otros temas, `estado.json`) que no revisé.
- No leí las hojas de firma de Q-TI-8 y Q-TI-9 (las que cita el blueprint no se ven en la rama); el estado «pendiente» sale de `bp:267,343-346`.
- Los casos con la mayoría de lógica de servicio (LP-04 a LP-15, PF, CC, VL, PR, BT) son por inferencia del contrato de datos, no del código; no hay servicio ni API del ADR-161 todavía. Los códigos HTTP (409, 422, 400, 403) son mi expectativa salvo donde el blueprint los fija (409 de Q-TI-5 y M-2 (a), 422 de LP-08 y A1-15).
- No verifiqué la rutas `/api/super/tipos-identificador` ni `/api/catalogos/tipos-identificador`: son nombres sugeridos.
- No revisé el esquema de la tabla heredada (FI-10), la clasificación de empresas (el relleno corre en toda base), ni si el 607 existe en la rama (M5-13, FI-04).
- La cifra de «unas 177 pruebas» cuenta filas de este documento con prueba propia (IDs únicos con prueba; excluye 6 remisiones), contada con grep; no es una medición. Los volúmenes de PF-11 (100 000 clientes) son los de B.
- No leí en esta versión los archivos de reportes ni las vistas: todo lo de la sección 12 viene del inventario ya entregado (con sus huecos: `ReportesVentasRegistrados.cs`, el diseñador de reportes, etc., que pueden elegir cualquier columna).
