```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 6 del aviso 2026-10-22: casos de prueba del ADR-161, maestro «Tipo de identificador fiscal»)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (construcción futura); fuentes en `master`
Estado: Abierto (casos, sin código; el ADR-161 sigue Propuesto y la DDL no existe como artefacto)
```

# Casos de prueba del ADR-161 (Tipo de identificador fiscal)

**Fuentes leídas:**
1. La revisión de la DDL del arquitecto-datos (`traspasos/B/2026-10-22-revision-ddl-adr161.md`): hallazgos A-1, M-1 a M-5, B-1 a B-6 y la DDL mínima de su sección 3.
2. La propuesta del ADR-161, leída con `git show origin/master:docs/propuestas/2026-10-22-adr-161-propuesto-tipo-identificador-fiscal.md` (en mi árbol local de `master` no está; está en `origin/master`). Cubre TI-01 a TI-09 y Q-TI-1 a Q-TI-7.
3. No existe `docs/adr/ADR-161.md` ni `docs/datos/...adr-161...` (`git ls-tree origin/master` solo da la propuesta; `git branch -r | grep 161` sin resultado). **La DDL real no existe**: trabajo con la DDL mínima recomendada de la revisión (§3), que es la que B probablemente adopte. Todo lo que dependa de ella va marcado.

**Clave de tipo:** SQL = base `GPOS_TEST_*`; HTTP = API en proceso; TX = prueba de servicio/unidad dentro de transacción; ARQ = prueba sobre fuentes/ensamblados/mapeo.
**Dependencia:** `[F]` = firmada (Q-TI-2 a 7, TI-01 a 09 en su texto); `[R]` = viene de la revisión del arquitecto-datos, aún no decidida por B ni firmada; `[A]` = decisión abierta o inferida.
**Convención de nombres de pruebas:** `Ti_...` (nombres sugeridos). Datos de ejemplo son inventados y sintéticos.

## 1. A-1: la letra solo se deriva para identificadores solo de dígitos [R, obligatorio antes de construir]

Hoy `TiposIdentificacion.TipoDe` decide por el largo (9→`R`, 11→`C`, otro→`P`) y `CK_Cliente_Identificacion`/`CK_Suplidor_Identificacion` exigen solo dígitos para `R` y `C` y 5 a 20 caracteres para `P`.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| A1-01 | `Pasaporte_alfanumerico_de_9_no_recibe_R` | TX + SQL | Cliente con tipo `PASAPORTE_OTROS`, `Identificacion = 'AB1234567'` (9, con letras) | Alta OK; letra `P`; sin error 547 | `TipoDe` vuelve a decidir solo por largo (daría `R` y el CHECK rechaza) |
| A1-02 | `Pasaporte_alfanumerico_de_11_no_recibe_C` | TX + SQL | `'AB123456789'` (11) | Alta OK; letra `P` | ídem, con `C` |
| A1-03 | `Carnet_migracion_alfanumerico_de_9_u_11_se_guarda` | TX + SQL | `CARNET_MIGRACION`, `'M12345678'` y `'M1234567890'`... usar uno de 9 y otro de 11 caracteres | Alta OK, letra `P` | ídem |
| A1-04 | `Solo_digitos_de_9_sigue_siendo_R` (regresión) | TX + SQL | `'101234567'` con `EMPRESA` | Letra `R` | la corrección rompe el caso normal |
| A1-05 | `Solo_digitos_de_11_sigue_siendo_C` (regresión) | TX + SQL | `'00112345678'` | Letra `C` | ídem |
| A1-06 | `Cadena_con_guiones_se_normaliza_y_luego_decide` | TX | `'101-23456-7'` | tras `FormatoRnc.Digitos`, 9 dígitos → `R`; `'AB-1234567'` → no solo dígitos → `P` | la letra se decide antes de normalizar, o `Digitos` deja pasar letras como dígitos |
| A1-07 | `Pasaporte_de_10_con_letras_es_P` (límite vecino) | TX + SQL | `'AB12345678'` | `P` | alguien «arregla» A1-01 y rompe el caso de 10 |
| A1-08 | `Pasaporte_solo_digitos_de_9_pero_tipo_pasaporte` | TX + SQL | Tipo `PASAPORTE_OTROS` con `'123456789'` (9 dígitos puros) | Documentar el resultado; esperado propuesto: letra `R` (por dígitos) y tipo `PASAPORTE_OTROS`, aceptado (TI-05: «no se exige que coincidan») | [A] pregunta P-3: ¿es válido? Falla si el CHECK o el servicio rechazan sin decisión |
| A1-09 | `Rango_definido_por_SUPER_menor_a_5_se_rechaza` | HTTP + SQL | SUPER crea un tipo con rango `Desde=3, Hasta=4` | 400/409 del servicio y, en la base, violación de `CK_TipoIdentificadorLargo_Rango` (insertando directo por SQL) | falta el CHECK (b) de la revisión o el servicio no valida |
| A1-10 | `Rango_mayor_a_20_o_invertido_se_rechaza` | HTTP + SQL | `Desde=5, Hasta=25`; `Desde=12, Hasta=8` | rechazo en servicio y por CHECK en SQL directo | CHECK incompleto (`Hasta BETWEEN Desde AND 20`) |
| A1-11 | `Importacion_con_pasaporte_alfanumerico_de_9` | TX + SQL | Fila de plantilla con `TipoIdentificador=PASAPORTE_OTROS`, id `'XY1234567'` | importada sin error 547 | la importación usa otro camino que no pasó por la corrección |
| A1-12 | `Suplidor_con_pasaporte_alfanumerico_de_9_u_11` | TX + SQL | igual que A1-01/02 sobre suplidor | OK | se corrige solo en cliente (`MaestrosService.cs:197`) y no en suplidor (`:350`) |
| A1-13 | `Venta_copia_la_letra_correcta` | TX + SQL | Cliente de A1-01, venta | `CK_Venta_TipoIdentificacion` acepta la copia (`P`) | la venta recalcula la letra por otro método |
| A1-14 | ARQ `TipoDe_es_el_unico_punto_de_derivacion` | ARQ | búsqueda por símbolos de `Length == 9`/`== 11` fuera de `TiposIdentificacion` y `FormatoRnc` | ninguno | otra clase repite la derivación por largo |

Mutación global de A-1: revertir `TipoDe` a la versión actual → A1-01, A1-02, A1-03, A1-11 y A1-12 deben fallar.

## 2. `LetraPorOmision` (M-1) [R; depende de que B acepte la columna]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| LP-01 | `Siembra_marca_las_tres_letras` | SQL | Base nueva tras la migración | `EMPRESA→R`, `PERSONA_FISICA→C`, `PASAPORTE_OTROS→P`, `CARNET_MIGRACION→NULL` | la siembra olvida una marca |
| LP-02 | `CK_LetraPorOmision_solo_R_C_P` | SQL | `UPDATE ... SET LetraPorOmision='N'` y `'X'` | violación de CHECK | CHECK ausente o con `N` |
| LP-03 | `Indice_unico_filtrado_de_letra` | SQL | Poner `R` a un segundo tipo; poner varias filas con NULL | el segundo `R` falla (único); varios NULL pasan | índice sin filtro (bloquea los NULL) o ausente |
| LP-04 | `Derivacion_usa_la_letra_por_omision_no_el_codigo` | TX | Renombrar vía SQL el `Codigo` de `EMPRESA` a `EMP2`, alta sin tipo con `'101234567'` | tipo derivado = `EMP2` (el que tiene `R`) | el servicio busca por el literal `'EMPRESA'` |
| LP-05 | `Inhabilitar_tipo_con_letra_por_omision_se_rechaza` | HTTP | SUPER inhabilita `EMPRESA` | 409 con mensaje «reasigne la letra antes» | falta la comprobación (M-1) |
| LP-06 | `Reasignar_la_letra_y_luego_inhabilitar` | HTTP | SUPER pasa `R` de `EMPRESA` a `EMP2`, luego inhabilita `EMPRESA` | OK; el alta por 9 dígitos deriva `EMP2` | el servicio exige que la letra siga atada a un código |
| LP-07 | `Cambio_de_regla_deja_sin_largo_el_9` | HTTP | SUPER quita el rango 9 al tipo con `R` | 409 (la derivación por omisión quedaría sin destino) | se permite y el alta falla luego, no al configurar |
| LP-08 | `Alta_sin_tipo_con_tipo_por_omision_inexistente` | TX | Quitar la letra `P` a todos | error claro de configuración, no `NullReferenceException` ni 500 | excepción sin controlar |
| LP-09 | `Copia_entre_empresas_conserva_la_letra_por_Codigo` | HTTP + SQL | Copiar tipos (Q-TI-7) de empresa A a B | B tiene mismos códigos y mismas letras, Ids propios | copia por Id o pierde la letra |

## 3. 409 al cambiar `EsPersonaFisica` en un tipo usado (M-2) [R; la regla de Q-TI-5 es F, la extensión a `EsPersonaFisica` es R]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| PF-01 | `Cambiar_EsPersonaFisica_con_clientes_da_409` | HTTP + SQL | `PERSONA_FISICA` con 2 clientes; SUPER pone `EsPersonaFisica=false` | 409; el cuerpo lista los 2 clientes (código/Id); el valor no cambia en la base | falta el control en el servicio |
| PF-02 | `Cambiar_EsPersonaFisica_con_suplidores_da_409` | HTTP + SQL | solo hay un suplidor usando el tipo | 409 | el control mira solo clientes |
| PF-03 | `Cambiar_EsPersonaFisica_sin_uso_es_200` | HTTP | tipo recién creado, sin filas | 200; valor cambiado | el control bloquea siempre |
| PF-04 | `Cambiar_descripcion_con_uso_no_da_409` | HTTP | cambiar solo `Descripcion` en un tipo usado | 200 | el control es demasiado amplio |
| PF-05 | `Uso_solo_en_historial_no_cuenta` | SQL + HTTP | cliente que tuvo el tipo en la tabla temporal pero hoy tiene otro | 200 | el control cuenta el historial en vez de la tabla viva |
| PF-06 | `Uso_cuenta_clientes_inhabilitados` | HTTP + SQL | cliente inhabilitado con el tipo | 409 (sigue siendo uso, ADR-08) | el filtro excluye inhabilitados |
| PF-07 | `Alternativa_con_motivo` | HTTP | si B elige «permitir con motivo y bitácora» en vez de 409 | 200 solo con `motivo` y línea en bitácora | **[A]** B no ha elegido; ver pregunta 1 |
| PF-08 | `Cambio_de_regla_de_largo_con_incumplidores_da_409` (Q-TI-5, firmada) | HTTP + SQL | `PERSONA_FISICA` con cliente de `'101234567'` (9); SUPER quita el rango 9 | 409 con ese cliente en la lista | falta el control de Q-TI-5 [F] |
| PF-09 | `Cambio_de_regla_de_largo_sin_incumplidores_es_200` | HTTP | ampliar un rango | 200 | rechaza ampliaciones inocuas |
| PF-10 | `Efecto_en_TT_tras_el_cambio` | TX | cliente con tipo `PASAPORTE_OTROS` (física); tipo cambia sin uso → nuevo cliente | `EsPersonaFisica` del tipo manda (TI-07); con tipo nulo, vale la letra (`R` = jurídica, `C/P/N` = física) | TI-07 no se aplica o ignora el caso nulo |
| PF-11 | `Comprobacion_de_uso_usa_el_indice` | SQL | plan de ejecución de la consulta de uso con 100 000 clientes de prueba | Seek sobre `IX_Cliente_TipoIdentificador`, sin scan de tabla | falta el índice de M-3 (prueba de rendimiento, solo si B la quiere) |

## 4. Migración (R→EMPRESA, C→PERSONA_FISICA, P→PASAPORTE_OTROS, N sin tipo) [F en el texto; el detalle idempotente es R]

Preparación común: base con el esquema anterior a la migración y filas sembradas por SQL en `cat.Cliente` y `cat.Suplidor`.

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| MG-01 | `Relleno_R_a_EMPRESA` | SQL | Cliente y suplidor con `TipoIdentificacion='R'`, id `'101234567'` | `TipoIdentificadorId` = Id de `EMPRESA` (buscado por `Codigo`) | relleno por Id literal o por otro mapeo |
| MG-02 | `Relleno_C_a_PERSONA_FISICA` | SQL | `'C'`, `'00112345678'` | Id de `PERSONA_FISICA` | ídem |
| MG-03 | `Relleno_P_a_PASAPORTE_OTROS` | SQL | `'P'`, `'AB123456'` | Id de `PASAPORTE_OTROS` (no `CARNET_MIGRACION`) | ídem |
| MG-04 | `N_queda_sin_tipo` | SQL | `'N'`, `Identificacion NULL` | `TipoIdentificadorId IS NULL` | el relleno asigna un tipo a `N` |
| MG-05 | `Persona_fisica_con_RNC_queda_EMPRESA` (límite documentado) | SQL | `'R'` de 9 dígitos que en realidad es de una persona física | queda `EMPRESA` | alguien «adivina» y cambia la regla sin decisión |
| MG-06 | `Historial_no_se_rellena` | SQL | tabla de historial de cliente | `TipoIdentificadorId IS NULL` en todas las filas previas | el relleno borra/reescribe historia (o se apagó `SYSTEM_VERSIONING`, B-4) |
| MG-07 | `Relleno_genera_historial_sin_perder_filas` (B-4) | SQL | contar filas de historial antes/después | historial crece una fila por cliente/suplidor; ninguna se pierde | se apagó el versionado |
| MG-08 | `Relleno_idempotente` | SQL | Ejecutar el relleno dos veces tras corregir manualmente un cliente a `PERSONA_FISICA` con RNC | la segunda pasada no pisa el cambio (`WHERE TipoIdentificadorId IS NULL`) | el `UPDATE` no tiene la guarda (B-3b) |
| MG-09 | `Relleno_con_mayoria_de_filas_y_NULL_en_Identificacion` | SQL | Mezcla: 1 000 filas sintéticas de las 4 letras | conteo por tipo = conteo por letra anterior | pérdida o doble asignación |
| MG-10 | `Relleno_tras_CK_nuevo_no_viola` | SQL | filas con las 4 letras tras agregar `CK_Cliente_TipoIdentificador` | sin error 547 | el CHECK se agrega antes del relleno y falla (orden) |
| MG-11 | `Siembra_de_los_cuatro_tipos_y_rangos` | SQL | base nueva | 4 tipos con códigos exactos; rangos: `EMPRESA` 9; `PERSONA_FISICA` 9 y 11 (dos filas, sin 10); `PASAPORTE_OTROS` 5-20; `CARNET_MIGRACION` 5-20; `SoloDigitos` coherente (solo `EMPRESA` y `PERSONA_FISICA` verdaderos) | siembra incompleta; `PERSONA_FISICA` admite 10 |
| MG-12 | `Descripciones_sembradas_exactas` | SQL | | «Identificador Empresa», «Identificador Persona Física», «Pasaporte/otros», «Carnet de Migración» (con acento: cabe en `varchar` 1252) | acento corrupto por parámetro `nvarchar` mal cargado |
| MG-13 | `Migracion_Down_y_Up` | SQL | aplicar `Down` y luego `Up` | sin residuos; vuelve a quedar igual | `Down` no borra columna/FK/índices |
| MG-14 | ARQ `Marca_y_guion_acumulado_coinciden` | ARQ | marca de migración posterior a `20261021001638_Ola5VistasTramo4`; guion `database/empresa/gpos-empresa-<última>.sql` contiene la guarda por `MigrationId` | coinciden | guion no regenerado (propuesta «Cómo se migra») |

## 5. Idempotencia del guion de esquema (aplicar dos veces) [R, B-3]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| ID-01 | `Guion_acumulado_dos_veces` | SQL | Aplicar el guion acumulado completo dos veces sobre la misma base | segunda ejecución sin errores y sin cambio (conteos de filas y esquema iguales) | falta una guarda por `MigrationId` |
| ID-02 | `Siembra_no_duplica` | SQL | tras 2 aplicaciones | exactamente 4 tipos y los rangos esperados (sin duplicar la PK `(TipoIdentificadorId, Desde)`) | siembra sin `IF NOT EXISTS` / por `Codigo` |
| ID-03 | `Guion_con_datos_de_clientes_y_dos_veces` | SQL | base con clientes ya rellenados; reaplicar | `TipoIdentificadorId` no cambia | relleno sin guarda |
| ID-04 | `Relleno_en_EXEC_dinamico` | ARQ/SQL | el guion se ejecuta en un solo lote contra una base **sin** la columna aún | compila el lote (el `UPDATE` va en `EXEC(N'...')`) | error 207 «nombre de columna no válido» al compilar (B-3a) |
| ID-05 | `Guion_con_base_a_medias` | SQL | Simular tabla creada pero sin columna en cliente | el guion completa lo que falta | guardas por tabla en lugar de por objeto |
| ID-06 | `Indice_y_CK_no_se_duplican` | SQL | `sys.indexes`/`sys.check_constraints` tras 2 pasadas | un solo `IX_Cliente_TipoIdentificador`, un solo `CK_*` | nombres sin guarda |

## 6. `varchar` y largo de parámetros (ADR-50) [F; B-5]

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| V-01 | `CP169_largos_del_mapeo_coinciden` (`ConsultasVarcharTests`, CP-169, existente) | ARQ/SQL | `Codigo varchar(20)`, `Descripcion varchar(80)`, `Notas varchar(200)`; LetraPorOmision `char(1)` | el mapeo declara otro largo o `nvarchar` (B-1) |
| V-02 | `Columnas_son_varchar_no_nvarchar` | SQL | `sys.columns`/`INFORMATION_SCHEMA` de las dos tablas nuevas: ninguna `nvarchar` | EF mapea `string` por omisión como `nvarchar` |
| V-03 | `Parametros_del_409_son_varchar_20` | ARQ | análisis de los comandos Dapper del 409 y de la búsqueda por `Codigo`: `DbType.AnsiString`, `Size=20` | parámetro sin tipo (se infiere `nvarchar`) |
| V-04 | `Busqueda_por_codigo_usa_seek` | SQL | plan de `WHERE Codigo = @c` con `varchar(20)` | Scan por conversión implícita |
| V-05 | `Codigo_en_minusculas_o_con_espacio` | HTTP | `'empresa '`, `'Tipo-1'` | normalizado a mayúsculas o 400 (según B) | sin CK/normalización (B-5), por intercalación CI quedaría duplicado por mayúsculas: ver U-02 |
| V-06 | `Acentos_en_descripcion` | HTTP + SQL | crear con `'Documento extranjero ñ'` | ida y vuelta exacta (página 1252) | pérdida de caracteres |
| V-07 | `Unicode_fuera_de_1252` | HTTP | `'日本'` en descripción | 400 o `?` documentado | pasa en silencio con datos corruptos **[A]** pregunta 5 |

## 7. Unicidad y códigos inmutables [F para TI-01 «Codigo único»; la inmutabilidad es el principio general de códigos inmutables de las respuestas P-1 a P-11]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| U-01 | `Codigo_duplicado_exacto_409` | HTTP | crear segundo `EMPRESA` | 409 (no 500 por violación de `UQ_..._Codigo`) | el servicio no traduce la violación 2627 |
| U-02 | `Codigo_duplicado_distinta_mayuscula` | HTTP | `'empresa'` con `EMPRESA` existente | 409 | no hay normalización y la intercalación CI lo detecta solo en SQL (error 2627 como 500) |
| U-03 | `Codigo_inmutable_en_edicion` | HTTP | PUT cambiando `Codigo` | 400/409; `Codigo` intacto | el servicio acepta renombrar (rompe copia por Código y LP-04) |
| U-04 | `Codigo_inmutable_en_SQL_directo` | SQL | `UPDATE ... SET Codigo` | **[A]** solo si B agrega un disparador/regla; si no, se documenta que es regla del servicio | pregunta 6 |
| U-05 | `Codigo_de_tipo_inhabilitado_no_se_reutiliza` | HTTP | inhabilitar y volver a crear el mismo `Codigo` | 409 | se reutiliza y confunde el historial |
| U-06 | `Rango_solapado_se_rechaza` | HTTP | `PERSONA_FISICA` con 9-11 y luego 10-12 | 400 (no declarable en DDL; es del servicio, B-2) | falta la validación de servicio |
| U-07 | `Rango_duplicado_misma_Desde_PK` | SQL | insertar dos filas con igual `(TipoIdentificadorId, Desde)` | violación de PK | PK ausente |
| U-08 | `Tipo_activo_sin_rango_se_rechaza` | HTTP | crear tipo sin rangos | 400 | tipo inservible activo |
| U-09 | `FK_sin_cascada` | SQL | borrar un tipo con rangos o con clientes | falla por FK (no borra en cascada) | `ON DELETE CASCADE` (B-2) |
| U-10 | `Tipo_con_uso_no_se_borra_se_inhabilita` | HTTP | DELETE de tipo con clientes | 409/405; sí se puede inhabilitar | se borra con uso (ADR-08) |
| U-11 | `Tipo_sin_uso_se_borra` | HTTP | DELETE de tipo sin uso | **[A]** ADR-08 «eliminar solo sin referencias»; esperado 200 | pregunta 6 |
| U-12 | `CK_Cliente_TipoIdentificador` | SQL | `TipoIdentificadorId=1` con `Identificacion NULL` | violación de CHECK (M-3) | CHECK ausente |
| U-13 | `Con_identificacion_tipo_obligatorio_en_servicio` | TX | alta con identificación y sin tipo | se deriva (TI-06) o 400 según el origen; nunca fila con identificación y tipo vacío por la pantalla (TI-04) | el servicio permite nulo desde la pantalla |
| U-14 | `Fila_antigua_con_identificacion_y_sin_tipo_es_valida` | SQL | fila previa sin tipo | admitida (no hay bicondicional en DDL) | alguien lo convierte en CHECK y rompe nodos/historial (M-3) |
| U-15 | `Inhabilitado_no_aparece_en_catalogo_de_seleccion` | HTTP | `/api/catalogos/tipos-identificador` | solo activos | muestra inhabilitados |
| U-16 | `Cliente_con_tipo_inhabilitado_sigue_legible` | HTTP | cliente cuyo tipo se inhabilitó después | lectura y edición no relacionada funcionan | la inhabilitación rompe la edición del cliente |
| U-17 | `Tipo_de_otra_empresa_no_se_asigna` | HTTP + SQL | empresa B referencia un Id de un tipo de A (TI-01) | rechazado (el Id no existe en la base B o no es el suyo) | FK apunta a otra base por error; el catálogo se comparte |

## 8. Validación del dato según el tipo (TI-02 y TI-04) [F]

| ID | Prueba | Tipo | Entrada | Esperado | Falla si… |
|---|---|---|---|---|---|
| VL-01 | `Persona_fisica_acepta_9_y_11_pero_no_10` | HTTP | `'101234567'`, `'00112345678'` OK; `'1012345678'` | 200, 200, 422/400 | el rango se implementó como mínimo-máximo (Q-TI-2) |
| VL-02 | `Empresa_solo_9` | HTTP | `'00112345678'` con `EMPRESA` | 422 | rango mal sembrado |
| VL-03 | `SoloDigitos_rechaza_letras` | HTTP | `'1012A4567'` con `EMPRESA` | 422 | `SoloDigitos` no se evalúa |
| VL-04 | `Pasaporte_5_y_20_limites` | HTTP | `'A1234'`, `'A'*20`; `'A123'`, `'A'*21` | OK, OK, 422, 422 | límite abierto/cerrado mal |
| VL-05 | `Identificacion_con_guiones_se_normaliza` | HTTP | `'101-23456-7'` con `EMPRESA` | guarda `101234567` | validación contra el texto con guiones |
| VL-06 | `Sin_identificacion_sin_tipo` | HTTP | `Identificacion` vacía y tipo enviado | 400 o tipo ignorado (decisión de B) | **[A]** pregunta 4 |
| VL-07 | `Derivacion_propuesta_9_11_otro_vacio` (TI-06) | TX | pedido sin tipo con 9, 11, 7 y vacío | `EMPRESA`, `PERSONA_FISICA`, `PASAPORTE_OTROS`, NULL | la derivación cambia del contrato (cliente antiguo) |
| VL-08 | `Derivacion_de_9_con_letras_no_asigna_EMPRESA` | TX | sin tipo, `'AB1234567'` | `PASAPORTE_OTROS` (consistente con A-1) | la derivación TI-06 repite el defecto A-1 |
| VL-09 | `Cliente_desplegado_antiguo_sin_campo` | HTTP | JSON sin `tipoIdentificadorId` (compatibilidad) | 200 con tipo derivado | el campo se vuelve obligatorio |
| VL-10 | `Importacion_columna_TipoIdentificador_opcional` | TX | plantilla sin columna, con columna válida, con código inexistente | derivado, aplicado, error de fila (no aborta todo el lote) | la importación aborta o ignora el código en silencio |
| VL-11 | `Importacion_codigo_en_minusculas` | TX | `'empresa'` | resuelve a `EMPRESA` o error claro | depende de normalización |
| VL-12 | `Editar_identificacion_revalida_contra_el_tipo` | HTTP | cambiar `Identificacion` de 9 a 7 dígitos con tipo `EMPRESA` | 422 | solo se valida en el alta |
| VL-13 | `Reglas_nuevas_no_invalidan_la_letra` | TX | persona física `PERSONA_FISICA` con 9 dígitos | letra `R`, tipo `PERSONA_FISICA` (TI-05) | alguien exige coincidencia letra/tipo |

## 9. Privilegios (TI-03) [F: solo el SUPER define; B-6: sin permisos SQL nuevos]

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| PR-01 | `ADMIN_no_puede_crear_tipo` (`POST /api/super/tipos-identificador`) | HTTP | 403 | la ruta usa política de ADMIN |
| PR-02 | `USER_no_puede_crear_ni_editar` | HTTP | 403 (POST, PUT, inhabilitar) | idem |
| PR-03 | `SUPER_si_puede` y exige empresa del token | HTTP | 200/201 | autorización demasiado cerrada |
| PR-04 | `SUPER_actua_sobre_la_empresa_correcta` | HTTP + SQL | SUPER de la empresa A del token no modifica el catálogo de B pasando el Id | falta aislamiento entre empresas |
| PR-05 | `Lectura_del_catalogo_para_quien_registra_clientes` | HTTP | USER con privilegio de crear clientes: 200; USER sin él: 403 **[A]** pregunta 3 | lectura abierta a cualquier autenticado de otra empresa (H-01/H-02) |
| PR-06 | `Sin_token_401` | HTTP | 401 en ambas rutas | ruta sin `RequireAuthorization` |
| PR-07 | `SUPER_con_motivo_si_ADR_lo_exige` | HTTP | **[A]** el SUPER entra a empresas con motivo (ADR-35); si la edición exige motivo, falta → 400 | pregunta 3 |
| PR-08 | `Copia_entre_empresas_solo_del_mismo_dueno` (Q-TI-7) | HTTP | origen y destino de la misma instalación; empresa ajena rechazada | copia hacia empresa sin acceso |
| PR-09 | `gpos_app_sin_permiso_extra` | SQL | `SELECT/INSERT/UPDATE/DELETE` sobre las tablas nuevas funcionan sin `GRANT` extra (B-6) | las tablas nacen en un esquema sin permisos |
| PR-10 | `Usuario_SQL_de_reportes_no_escribe` | SQL | el usuario de solo lectura de `rpt` no puede `INSERT` en el catálogo | permisos excesivos |

## 10. Bitácora [R en M-2; el resto A]

La revisión nombra la bitácora solo para M-2. La propuesta no define bitácora; se asume `_LOG` (como RG-04/05) o la del SUPER.

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| BT-01 | `Alta_de_tipo_deja_linea` | HTTP + SQL | línea con usuario, empresa, código | **[A]** pregunta 2 |
| BT-02 | `Cambio_de_reglas_deja_linea_con_antes_y_despues` | HTTP + SQL | rangos antes/después | sin traza del SUPER |
| BT-03 | `Cambio_de_EsPersonaFisica_deja_linea_y_motivo` (M-2) | HTTP + SQL | línea con motivo (si B elige esa opción) | cambio silencioso |
| BT-04 | `Inhabilitar_deja_linea` | HTTP + SQL | idem | |
| BT-05 | `409_no_deja_linea_de_exito` | HTTP + SQL | el rechazo no registra un cambio que no ocurrió | bitácora escrita antes de validar |
| BT-06 | `Bitacora_sin_datos_personales` | HTTP + SQL | las líneas no incluyen la identificación de los 409 listados | fuga de identificadores en la bitácora |
| BT-07 | `Copia_entre_empresas_deja_linea_en_ambas` | HTTP + SQL | origen y destino | **[A]** |

## 11. Hallazgos M-3, M-4, M-5 y bajos (un caso por hallazgo, mutación que lo detecta)

| ID | Hallazgo | Prueba | Tipo | Esperado | Falla si… (mutación) |
|---|---|---|---|---|---|
| M1-C | M-1 | cubierto por LP-04 y LP-05 | | | quitar `LetraPorOmision` y volver a derivar por código |
| M2-C | M-2 | cubierto por PF-01/02 | | | quitar el 409 de `EsPersonaFisica` |
| M3-01 | M-3 | `Indice_FK_cliente_y_suplidor_existen` | SQL | `IX_Cliente_TipoIdentificador` y `IX_Suplidor_TipoIdentificador` (filtrados, `INCLUDE Identificacion`) en `sys.indexes` | se borra el `HasIndex` del mapeo |
| M3-02 | M-3 | `CK_Cliente_TipoIdentificador` y homólogo en suplidor | SQL | ver U-12 | CHECK solo en cliente |
| M4-01 | M-4 | `Catalogo_es_ISoloCentral` | ARQ | las dos entidades implementan `ISoloCentral` (búsqueda por reflexión en las entidades) | falta la interfaz y el nodo podría escribir el catálogo |
| M4-02 | M-4 | `Ids_iguales_en_el_nodo` | SQL | Con una copia de nodo simulada (central y nodo): el Id del tipo es el mismo y un cliente creado en el nodo con `TipoIdentificadorId` válido sincroniza sin romper la FK | el catálogo baja con Ids regenerados (`IDENTITY`) |
| M4-03 | M-4 | `Copia_entre_empresas_por_Codigo` | HTTP + SQL | ver LP-09 | copia por Id |
| M4-04 | M-4 | `Nodo_no_crea_ni_edita_tipos` | HTTP | **[A]** TI-09 es [I]: 403/405 en el nodo | pregunta 7; nodo es entrega 2, no probar antes del diseño |
| M5-01 | M-5 | `rpt_cliente_tiene_columna_TipoIdentificador` (TI-08) | SQL | vista devuelve `TipoIdentificador` con el código, `NULL` si no hay tipo | columna ausente o sin `LEFT JOIN` (pierde clientes sin tipo) |
| M5-02 | M-5 | `Enmascarado_de_persona_fisica_con_RNC` | SQL | **[A]** pregunta 8: si se decide guiar por `EsPersonaFisica`, persona física con letra `R` sale enmascarada; si no, íntegra (hoy). Documentar el que se decida | el cambio de regla de enmascarado queda sin prueba |
| M5-03 | M-5 | `Subida_de_contrato_y_huella` (ADR-109 cl. 11) | ARQ | versión del contrato incrementada y huella del script actualizada | vista cambia sin subir versión |
| B1-01 | B-1 | `Forma_de_CatalogoSimple` | ARQ | hereda de `CatalogoSimple`; sin columnas de fechas ni autor; `Version rowversion` | se copian columnas de autoría que no existen |
| B2-01 | B-2 | cubierto por U-07, U-09, A1-09/10 | | | |
| B4-01 | B-4 | cubierto por MG-06/07 | | | |
| B5-01 | B-5 | cubierto por V-01 a V-05 | | | |

## 12. Impacto en 606/607/608 y e-CF

La revisión no nombra e-CF; nombra el 606 y las vistas `rpt` solo por la propuesta (TI-05, TI-08). Estos casos son de **no regresión**: la letra y el contenido de los reportes deben seguir iguales.

| ID | Prueba | Tipo | Esperado | Falla si… |
|---|---|---|---|---|
| FI-01 | `Tipo_606_sigue_por_el_largo` (`ComprasNg.cs:17`, `FisConfiguracion.cs:275,287`) | TX + SQL | suplidor `'101234567'` → tipo `1`; `'00112345678'` → `2` | el 606 pasa a leer `EsPersonaFisica` |
| FI-02 | `606_persona_fisica_con_RNC_9_sigue_tipo_1` | TX + SQL | suplidor `PERSONA_FISICA` con 9 dígitos conserva `1` (TI-05; no se exige coincidencia) | alguien sincroniza la letra con el tipo |
| FI-03 | `606_pasaporte_alfanumerico_9` | TX + SQL | suplidor extranjero (A-1): no explota; resultado del 606 conforme a la regla vigente **[A]** pregunta 9 (el 606 solo prevé tipos 1 y 2) | exportador lanza excepción o emite tipo incorrecto |
| FI-04 | `607_608_sin_cambio` | SQL | **[A]** 607/608 están aplazados (memoria de aplazamiento fiscal) y 607/608 sin e-NCF; si las vistas existen en la rama, mismo resultado antes y después | cambio de columnas rompe la vista (solo si existe) |
| FI-05 | `Copia_del_tipo_en_la_venta` (`CK_Venta_TipoIdentificacion`) | SQL | la venta guarda `R`, `C` o `P` como antes | se intenta guardar el Id del tipo en la columna de la venta |
| FI-06 | `eCF_receptor_no_cambia` | HTTP | **[A]** la emisión e-CF (ADR-51/108) usa los campos canónicos del núcleo; con el cliente de un tipo nuevo (`CARNET_MIGRACION`, letra `P`) el JSON del receptor coincide con el de antes | el conector depende del código del tipo o de `TipoIdentificadorId` (violaría 73.7: el núcleo no conoce códigos del conector) |
| FI-07 | `eCF_receptor_extranjero_con_pasaporte` | HTTP | **[A]** mismo cuerpo que hoy | pregunta 9 |
| FI-08 | `RNC_padron_en_SYSDATA_no_cambia` | SQL | la validación de RNC contra el padrón se mantiene | `FormatoRnc.EsValido` se aplica a tipos que no son RNC |
| FI-09 | `FormatoRnc_EsValido` sigue 9 u 11 solo dígitos | TX | | cambio de contrato público de `GPOS.Contracts` |

## 13. Orden recomendado y esfuerzo

1. **Primero, sin base:** A1-01 a A1-07, A1-14, VL-07/VL-08 (unidad, minutos) y los ARQ (M4-01, B1-01, V-03). Detectan el defecto Alto y son baratos.
2. **Segundo, SQL:** MG-*, ID-*, LP-01 a LP-03, V-01/V-02, U-07, U-09, U-12 (la parte de DDL).
3. **Tercero, servicio y HTTP:** LP-04 a LP-09, PF-*, U-01 a U-06, U-13 a U-17, VL-*, PR-*, BT-*.
4. **Cuarto:** FI-* y M5-* cuando B decida TI-08 y el enmascarado.
5. **Después:** M4-02/04 con el diseño de nodos (entrega 2).

**Esfuerzo inferido (±40 %, 1 sp = 5 días-persona):** unas 130 pruebas. La propuesta de B reserva 0,2 a 0,3 sp para pruebas; mi estimado es de 0,35 a 0,5 sp (datos y migración 0,1 a 0,15; servicio y HTTP 0,15 a 0,2; privilegios, bitácora y reportes 0,1 a 0,15), por lo que sube unos 0,1 a 0,2 sp sobre la reserva. Costo de infraestructura: USD 0. Una suite SQL con bases `GPOS_TEST_*` por clase, no dos suites a la vez.

## 14. Preguntas para B

1. **M-2:** ¿el cambio de `EsPersonaFisica` con uso se rechaza con 409 (como Q-TI-5) o se permite con motivo y bitácora? Cambia PF-01 y PF-07.
2. **Bitácora:** ¿dónde se registran los cambios del SUPER sobre el maestro (`_LOG`, bitácora de seguridad, otra) y con qué campos?
3. **Privilegios:** ¿la lectura del catálogo exige algún privilegio concreto de cliente/suplidor, y la edición del SUPER exige motivo?
4. **TI-04:** ¿qué pasa si el pedido trae tipo y no trae identificación: se ignora el tipo o se rechaza?
5. **Unicode:** ¿se rechazan en el servicio las descripciones con caracteres fuera de la 1252?
6. **Códigos inmutables:** ¿la inmutabilidad de `Codigo` es solo regla de servicio o también de base? ¿Se borra un tipo sin uso o solo se inhabilita?
7. **Nodos (TI-09):** ¿el catálogo se declara `ISoloCentral` con Id conservado (M-4)? Los casos M4-02/04 quedan pendientes.
8. **M-5:** ¿el enmascarado en `rpt` se guía por `EsPersonaFisica`? Decisión de reportes y seguridad.
9. **606 y e-CF:** ¿cómo se declara a un suplidor/cliente extranjero con pasaporte en el 606 y en el receptor e-CF? ¿Hay regla para ellos?
10. **A1-08:** ¿es válido un `PASAPORTE_OTROS` con 9 dígitos puros (letra `R`)?
11. **Nombres:** ¿se mantiene `TipoIdentificadorId` y `cat.TipoIdentificadorFiscal`, o la DDL final cambia los nombres de mi lista?

## 15. Qué no verifiqué

- No se compiló ni se ejecutó nada. Los nombres de pruebas, rutas y columnas son los de la propuesta y de la DDL mínima de la revisión; no existen todavía en el código.
- **No leí el código vivo** de `TiposIdentificacion.TipoDe`, `MaestrosService`, `ImportacionMaestros`, `ComprasNg`, `FisConfiguracion`, `MaeConfiguracion` ni las vistas `rpt`. Todo lo que digo de ellos viene de las citas de la revisión y de la propuesta de B (`Terceros.cs:108-122`, `MaestrosService.cs:197,350`, `MaeConfiguracion.cs:326-335,398-407`, etc.). Tampoco leí `ConsultasVarcharTests.cs`, ni el guion `gpos-empresa-20261021001638_Ola5VistasTramo4.sql`.
- No hay ADR-161 firmado ni documento de datos en `docs/datos/`: los casos marcados `[R]` dependen de que B acepte la revisión, y los `[A]` de las preguntas de la sección 14.
- No revisé el esquema de bitácora, las políticas de autorización existentes ni el mecanismo de sincronización a los nodos; los casos BT-*, PR-05/07 y M4-* son por inferencia.
- No leí las hojas de firma de 606/607/608 ni de e-CF; FI-04, FI-06 y FI-07 se apoyan en CLAUDE.md y en la memoria (607/608 aplazados, 73.7), no en el código.
- No verifiqué conteos reales de tablas ni el volumen de 100 000 clientes de PF-11 (cifra de la revisión).
- La cifra de "unas 130 pruebas" cuenta filas de este documento, redondeada; no es una medición.
