```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 3 del aviso B-a-C/2026-10-22-respuesta-dorados-y-tareas-nuevas-2: plan de la prueba de arquitectura de CamposPersonalesTitular.json, ADR-92 TT-05/F-4)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (esquema de destino; TT lo construye B con L1b desde 2026-11-16); fuentes leidas con `git show origin/...`
Estado: Abierto (versión 2, 2026-10-22: ajustada con los hechos verificados en el código y el inventario de salidas; plan, sin código; adelantado respecto de la fecha 9-nov)
```

# Plan de la prueba de arquitectura de `CamposPersonalesTitular.json` (TT-01 a TT-03), versión 2

**Fuentes leidas:** (1) mi `traspasos/C/2026-10-22-plan-pruebas-tt-adr92.md`, grupo A (ARQ-01..ARQ-14) y sus D-n; (2) `traspasos/B/2026-10-22-respuesta-especialista-pos-tt.md` completa (lista de campos de TT-02, JSON propuesto en su 1.7); (3) ADR-92, bloque TT y precision del 2026-10-22, y la hoja `2026-10-22-hoja-firma-adr92-precisiones.md` (F-4, F-5, F-7, F-9, P-2, Q-TT1-a), ambos de `origin/master`; (4) **codigo vivo en `origin/feature/modelo-ng`, marcado [V]** (ver 11): `Terceros.cs`, `Personas.cs`, `MaeConfiguracion.cs` (mapeo de `Cliente`), `CfgConfiguracion.cs` (mapeo de `Empleado`), `PuenteMae.cs` (cabecera), `TablasEndpoints.cs` (grupos de `/api/maestros`), y las pruebas modelo `ClasificacionRutasLicenciaTests`, `CambioRncEnLaApiTests`, `ContratoConsultasTests`, `RutasLicenciaAprobadas.json`. Nada compilado ni ejecutado.

**Clave.** [V] verificado en codigo (archivo, rama); [I] inferido; [P1], [P2], [P9] = depende de las preguntas 1, 2 y 9 de mi plan de TT, que B lleva al propietario; [D-n] = decision abierta de la seccion 1 de ese plan (D-2 espejo, D-4 lista final de anonimizacion, D-5 deuda F-9, D-6 deduccion de persona fisica, D-7 comensales, D-8 firma del JSON, D-10 rectificar un bloqueado). **Falla si...** = la mutacion mental: la linea de produccion o del JSON que, cambiada, debe poner la prueba en rojo.

## Cambios de la versión 2

Insumos nuevos: `verificacion-codigo-hechos-tt.md` (hechos [V] sobre `b4378650`), `inventario-reportes-identificacion-tercero.md` (22 salidas) y el aviso de B del 2026-10-22 (las preguntas 1, 2 y 9 de mi plan de TT **aún no se han llevado al propietario**). Hice `git fetch`: `origin/feature/modelo-ng` está en `2fa6843b` y, según `git diff --name-only`, ningún archivo citado por los hechos cambió desde `b4378650`; releí `PuenteMae.ClienteAsync/SuplidorAsync/EliminarMaestroAsync` en `2fa6843b`. Nada compilado ni ejecutado.

| ID | Qué cambió | Por qué |
|---|---|---|
| §7.2, ARQ-09 | El centinela del espejo es **real**: `PuenteMae` existe en `2fa6843b`. Se describe qué copia, qué no copia y qué nunca escribe | Hecho 5 (`PuenteMae.cs:143-162`) |
| ARQ-10 | Ya no pide que el puente exponga `ColumnasPersonalesCopiadas` (pregunta 9 cerrada): descubre las columnas copiadas **por comportamiento** (centinelas) | Hecho 5 |
| §2.1 regla 3, JSON | `espejoHeredado.extra` (`Telefono3`, `CorreoElectronico3`, `IdDireccion`) **se sustituye** por `extraNoEscritas` solo documental: el puente nunca las escribe | Hecho 5; hallazgo H-A8 |
| §2.6 G-1, G-3 | G-1: la constante existe y nadie más la usa (cuidado con el otro `CodigoContado` de `Catalogos.cs:63`); G-3: la semilla está en `SqlMigracionesMae.cs:56-58`, ya no «ubicación [I]» | Hecho 4 |
| §6.4, S-7 | El interceptor se registra en **dos** contextos (`u.Ng` y `u.Heredado`): el puente escribe con otro `DbContext` | Hecho 5 |
| §7.5 (nuevo) | **Clase 5 · centinela de salidas con identificación**: `SalidasIdentificacionTercero.json` versionado, casos Z-1 a Z-6, mutaciones M-28 a M-30 | Inventario de 22 salidas (ARQ-17 del plan de TT) |
| §7.6 (nuevo) | Centinelas del estado «bloqueado»: X-5 (escritores de `Inhabilitado`) y X-6 (consumidores de un tercero, `ConsumidoresTerceroBloqueo.json`); mutaciones M-31 y M-32 | Hecho 0 y hechos 1 a 3, 6, 7 (ARQ-15 y ARQ-16 del plan de TT) |
| §4.1 | M-28 a M-33 nuevas | Los centinelas anteriores |
| §9 | **Revisión de H-A1 a H-A7** (todas vigentes; H-A4 ajustada) y H-A8, H-A9 nuevos | Hechos 0 y 5; inventario |
| §10 | Pregunta 9 **cerrada**; 7 precisada (P1, P2, P9 siguen pendientes del propietario); preguntas 11 a 13 nuevas | — |
| §0, §11, §13 | Casos (39), esfuerzo (3,4 dp) y «Qué no verifiqué» actualizados | — |

**Pendiente del propietario (ningún hecho lo resuelve):** **P1** (¿rectificar purga el historial?: cambia una clave del JSON), **P2** (sin comprobantes, ¿se anonimizan nombre y documento?: cambia las listas condicionales) y **P9** (¿TT escribe el espejo o espera la eliminación del puente?: decide si el JSON lleva `espejoHeredado` o si las rutas se desactivan). Los hechos reducen el costo de P9 (el puente es reutilizable y escribe solo 13 columnas) pero no la deciden.

## 0. Resumen

- **Un conjunto de 5 clases de prueba** (no una sola; la quinta es nueva en la v2), con 39 casos (31 del v1 + 6 de la clase 5 + 2 centinelas X-5/X-6), porque cada una exige un entorno distinto: dos corren sin base (texto y modelo EF), una necesita la API en proceso con solo la base del sistema, y una necesita base de empresa. Asi la parte barata (a, b, e, g y la mayor parte de c) corre en segundos y en cualquier maquina, incluida OSHIN-LEGION.
- **Lo que se sostiene hoy [V]:** el modelo de EF se puede leer sin conectarse a la base (`EmpresaNgDbContext` es un `DbContext` con `DbContextOptions`; hay mapeo con largos y tipos), la API se puede recorrer sin empresas (`ApiRutasLicenciaFactory`, patron de `ClasificacionRutasLicenciaTests`) y ya existe la lista aprobada de rutas `RutasLicenciaAprobadas.json`. No existe todavia `/api/titulares`, ni `TitularBloqueadoEn`, ni el privilegio, ni el JSON en ninguna rama (busqueda sin resultados [V]).
- **Cuatro hallazgos del plan (seccion 9):** (H-A1) el JSON propuesto por el especialista **viola** la regla `conservarBloqueado ⊆ rectificar` de mi ARQ-05 (`TipoIdentificacion`); (H-A2) la lista `nunca` no tiene motivo por columna, lo que impide el criterio «declarada no personal con motivo»; (H-A3) `excluir` como cadena SQL es un hueco que ninguna prueba cierra (H-6 de mi plan); (H-A4) la deteccion de lecturas fuera de la lista exige que TT no use SQL a mano en la API: hay que fijarlo como regla de construccion.
- **(v2) Hechos que cambian el plan:** el estado «cliente bloqueado» no existe en operación y ninguna barrera de documento nuevo lee la marca (X-5, X-6); el puente existe y escribe 13 columnas, nunca `Telefono3`/`CorreoElectronico3`/`IdDireccion` y no copia `Inhabilitado` (ARQ-10); y 22 salidas muestran la identificación del tercero, de las cuales 606, 607, la impresión de comprobantes y la retención **no se enmascaran** (clase 5).
- **Dependencias:** [P1] cambia el esquema del JSON (si rectificar purga el historial), [P2] cambia las listas `conservarBloqueado` (condicional a que existan comprobantes), [P9] decide si el JSON lleva `espejoHeredado` o si TT se desactiva mientras exista `PuenteMae`. El plan se escribe con la lista del especialista; los casos marcados cambian de resultado esperado, no de estructura.
- **Esfuerzo (inferido de C, ±40 %):** 3,4 días-persona de pruebas para las clases 1 a 5 sin el espejo ni comensales (el v1 decía 2,0 para a..h; +0,25 de X-5/X-6, +0,6 de la clase 5, +0,3 de ajustes y mutaciones nuevas); +0,5 dp si P9 pide el espejo (ARQ-09/10 por comportamiento, ya sin pedir cambios al puente); +0,25 dp para el centinela de comensales. Sin costo de infraestructura; sin paquetes nuevos (la clase 5 usa `sys.columns`/`sys.sql_modules` y reflexión).

## 1. Ubicacion de los archivos (propuesta, siguiendo la estructura que ya existe [V])

El patron del repositorio es `tests/GPOS.Tests/Arquitectura/` para las pruebas de arquitectura y un JSON junto a la prueba que lo vigila (`tests/GPOS.Tests/Licencia/RutasLicenciaAprobadas.json`, que leen con `PruebasNeutralesTests.CarpetaPruebas()`). Propongo lo mismo:

| Archivo | Que es | Quien lo toca |
|---|---|---|
| `src/GPOS.Core/Titulares/CamposPersonalesTitular.json` (recurso incrustado) | La **lista de produccion**; la lee el servicio de TT y el verbo `titulares --anonimizar-historial` de `GPOS.Migracion` (una sola fuente: F-4, F-5) | B (L1b) |
| `tests/GPOS.Tests/Titulares/CamposPersonalesTitular.dorado.json` | **Copia dorada** versionada: lo que la prueba cree que debe decir el JSON | B, junto con el JSON, siempre |
| `tests/GPOS.Tests/Titulares/CAMBIOS.md` | Bitacora de cambios de la lista (una entrada por `version`): fecha, motivo, referencia de firma, hash canonico | B, junto con los dos |
| `tests/GPOS.Tests/Titulares/ClasificacionColumnas.json` | Columnas **no personales declaradas con motivo** (resuelve H-A2); ver 3.3 | B, junto con los anteriores |
| `tests/GPOS.Tests/Arquitectura/CamposPersonalesTitularContratoTests.cs` | Clase 1: esquema, dorado, guarda, intersecciones, GENERICO (a, b, e, g) | C |
| `tests/GPOS.Tests/Arquitectura/CamposPersonalesTitularCoberturaTests.cs` | Clase 2: modelo EF contra el JSON (c) | C |
| `tests/GPOS.Tests/Arquitectura/RutasTitularArquitecturaTests.cs` | Clase 3: rutas, DTO, clase `Esencial`, servidor decide (d, f) | C |
| `tests/GPOS.Tests/Arquitectura/AccesoDatosTitularTests.cs` | Clase 4: interceptor de SQL (d en ejecucion) | C |
| `tests/GPOS.Tests/Titulares/SalidasIdentificacionTercero.json` (v2) | Lista versionada de las salidas con identificación y su política (§7.5); misma guarda dorado + `CAMBIOS.md` que el JSON de TT | B, con la firma del contador para las obligatorias |
| `tests/GPOS.Tests/Titulares/ConsumidoresTerceroBloqueo.json` (v2) | Lista versionada de los consumidores de cliente y suplidor y su decisión ante un bloqueado (§7.6) | B |
| `tests/GPOS.Tests/Arquitectura/SalidasIdentificacionTests.cs` y `EstadoBloqueadoArquitecturaTests.cs` (v2) | Clase 5 y centinelas X-5, X-6 | C |

La carpeta `Titulares` de pruebas se incluye en el proyecto como `CopyToOutputDirectory` si hace falta; basta con leer por `Raiz()` como hace `CambioRncEnLaApiTests` [V] (busca `GPOS-NG.slnx` hacia arriba).

**Etiquetas:** `Trait("Esquema","Neutral")` y `Trait("Categoria","Titulares")`, como las pruebas vecinas [V]. Las clases 1 y 2 sin fixture de base; la clase 3 con `ApiRutasLicenciaFactory` o una derivada; la clase 4 con `BaseDatosFixture`.

## 2. Clase 1 · Contrato del JSON y guarda de cambios (a, b, e, g)

### 2.1 Esquema del JSON (a)

El JSON se deserializa con un modelo **cerrado** (`JsonUnmappedMemberHandling.Disallow` en la prueba, no `Skip` como el lector de licencias [V `LectorContenidoLicencia.cs:43`]) y sin `PropertyNameCaseInsensitive`. Reglas, cada una un caso de la prueba `Esquema_del_JSON`:

1. Propiedades permitidas de la raiz: `version`, `fuente`, `maestros`, `nunca`, `reglas`. Cualquier otra → falla (un campo nuevo exige subir el esquema y esta prueba).
2. `version`: entero ≥ 1. Debe ser **igual** a la version de la copia dorada y a la ultima entrada de `CAMBIOS.md`.
3. `maestros`: exactamente las claves `clientes`, `suplidores`, `empleados` (y `comensales` solo con `estado = "pendiente-entrega-3"`; [D-7]). Cada maestro: propiedades permitidas `tabla`, `personaFisica`, `excluirCodigos` (ver H-A3), `rectificar`, `anonimizarAlSuprimir`, `conservarBloqueado`, `alias`, `espejoHeredado`, `historial`, `estado`. Con [P2] se suma una (por ejemplo `conservarSoloConComprobantes`) y con [D-5] otra para la deuda; **cada propiedad nueva se agrega al conjunto permitido en el mismo PR que sube `version`**.
4. **Sin duplicados:** dentro de cada lista, ninguna columna dos veces (comparacion ordinal, sin distinguir mayusculas: la intercalacion de las bases es `CI_AS`, asi que `telefono` y `Telefono` son la misma columna); ninguna columna en dos listas **excepto** las excepciones declaradas en 2.4. Claves duplicadas en el texto del JSON: el lector estandar toma la ultima, asi que la prueba abre el JSON con `JsonDocument` + `AllowDuplicateProperties = false` (.NET 9+ [I: version de .NET del proyecto no verificada; si no existe esa opcion, se recorre con `Utf8JsonReader` contando claves]).
5. **Ordenado:** cada arreglo en orden ordinal ascendente y las claves de `maestros` y `alias` tambien. **Esto cambia la lista del especialista**, que esta en orden logico (RazonSocial, NombreComercial, Identificacion…): hay que ordenarla una vez al firmar `version: 1`. Motivo: un diff de una linea es revisable y el hash canonico es estable. Alternativa descartada: no exigir orden y ordenar solo para el hash; se pierde la revisabilidad del diff y el orden «logico» no es verificable.
6. Cada nombre de columna cumple `^[A-Za-z][A-Za-z0-9]*$` (rechaza espacios, corchetes, comillas, comas, puntos y `;`: es lo que cierra la inyeccion si algun dia el verbo arma SQL con estos nombres, y obliga a que el nombre sea un identificador, no una expresion).
7. `alias`: el valor distinto de la clave, sin ciclos, y la clave es una columna de `rectificar`.
8. `reglas.identificacionTipoResultante` = `["C","N","P"]` exacto, `reglas.rechazarCamposFuera` = `"CAMPO_NO_PERSONAL"` [V: codigo dado por F-4], `reglas.identificacionNoVaciaSiTipoComprobanteRequiereRnc` = true.

### 2.2 Copia dorada y guarda de cambios (b)

Mismo principio que la guarda G-1..G-6 de la tanda de dorados de T4-01 (mi plan `2026-10-22-plan-tanda-dorados-t4-01.md`), pero **mas simple porque aqui no hay modo «regenerar»**: el dorado es un archivo pequeno que una persona edita a mano. Piezas:

| # | Pieza | Caso de prueba | Falla si… |
|---|---|---|---|
| B-1 | Igualdad semantica: JSON de produccion == dorado, comparados como arboles canonicos (claves ordenadas, sin espacios), no como texto | `El_JSON_coincide_con_la_copia_dorada` | alguien agrega, quita o mueve una columna en el JSON y no toca el dorado (o al reves) |
| B-2 | `version` igual en ambos y **estrictamente mayor que la de la entrada anterior** de `CAMBIOS.md` cuando el hash canonico cambia | `Cambiar_la_lista_exige_subir_la_version` | se cambia el contenido sin subir la version |
| B-3 | `CAMBIOS.md` tiene una entrada por cada `version` 1..N, sin saltos, cada una con fecha, motivo no vacio, referencia de firma (hoja, ADR o aviso) y el hash SHA-256 del JSON canonico de esa version; el hash de la **ultima** entrada coincide con el JSON actual | `Cada_version_tiene_entrada_en_CAMBIOS_con_su_hash` | se edita el JSON y el dorado pero se omite o se inventa la entrada |
| B-4 | Anti-edicion silenciosa del historial: los hashes de las entradas anteriores no se pueden reescribir sin dejar rastro. No se puede verificar solo con los archivos (quien edita todo puede reescribir todo); se cubre con revision humana: `CAMBIOS.md`, el dorado y el JSON figuran en `CODEOWNERS` (o la regla del LEEME de la carpeta) a nombre del propietario/arquitecto-software | prueba de texto del LEEME de la carpeta: menciona los tres archivos y la regla | — (limite declarado en 10) |
| B-5 | Mensaje del fallo: dice **que archivo falta** y que para cambiar la lista hay que (1) editar el JSON, (2) copiar al dorado, (3) subir `version`, (4) agregar la entrada, (5) citar la firma | (todas) | el mensaje es opaco y alguien «arregla» la prueba |

Por que dos copias y no una: con una sola, cualquier cambio del JSON pasa su propia prueba. La copia dorada convierte el cambio en un diff de dos archivos mas una entrada: **tres lugares que un revisor ve juntos** (misma tecnica que `RutasLicenciaAprobadas.json` [V]: «Cada cambio de esta lista se revisa como un cambio de seguridad»).

### 2.3 Intersecciones y reglas de conjunto (e)

Para cada maestro, sobre los conjuntos de columnas (comparacion ordinal-ignore-case):

| Regla | Caso | Falla si… |
|---|---|---|
| E-1 `rectificar ∩ nunca = ∅` (`nunca` = `comunes` ∪ las del maestro) | `Rectificar_no_toca_las_columnas_nunca` | `LimiteCredito`, `TerminoId`, `Codigo`, `Version`, `Inhabilitado`, `TitularBloqueadoEn` entran a `rectificar` |
| E-2 `anonimizarAlSuprimir ∩ conservarBloqueado = ∅` | `Anonimizar_y_conservar_no_se_cruzan` | un campo se anonimiza y se conserva a la vez |
| E-3 `anonimizarAlSuprimir ∩ nunca = ∅` | idem | se anonimiza una columna de negocio |
| E-4 `conservarBloqueado ⊆ rectificar ∪ derivadas` donde `derivadas` es una lista declarada (hoy solo `TipoIdentificacion`, recalculada por el servidor) | `Lo_conservado_es_rectificable_o_derivado` | nombre o documento se conservan sin poder rectificarse (el titular no podria corregirlos) |
| E-5 **Interseccion vacia con los campos `Esencial`** (ver abajo) | `Ninguna_columna_personal_es_Esencial` | una columna de TT esta ademas en la lista de columnas esenciales |
| E-6 `anonimizarAlSuprimir ∪ conservarBloqueado ⊇ rectificar` salvo `Nota` y las declaradas «solo rectificar»: lo que se puede rectificar se trata al suprimir (si no, un dato personal rectificable sobrevive a la supresion) | `Todo_lo_rectificable_se_trata_al_suprimir` | se agrega un campo a `rectificar` y se olvida decir que pasa al suprimir |

**Sobre E-5, «campos `Esencial`»:** en el plan de TT lo escribi como «intersección vacía con campos `Esencial`»; en el codigo vivo **`Esencial` es una clase de ruta/operacion de la licencia (`ClaseOperacion.Esencial`), no una clase de campo** [V `RutasLicenciaAprobadas.json`, `ClasificacionRutasLicenciaTests`]. No existe hoy un atributo de columnas esenciales. Interpretaciones posibles, para que B elija: (i) **Esencial = lo que la licencia en `SoloConsulta` permite escribir**: la interseccion se lee como «la ruta de TT escribe solo columnas personales; ninguna de las que otra ruta `Esencial` ya escribe» (p. ej. `Inhabilitado` por «inhabilitar» de usuarios no, pero si cualquier campo de las rutas de cierre de caja); (ii) **Esencial = columnas del esquema marcadas esenciales para la operacion fiscal** (NCF, montos, `Codigo`): equivale a `nunca`, y E-1 ya la cubre. **Propongo (ii) con la lista `nunca` como definicion** y una prueba mas modesta de (i): que la ruta de TT clasificada `Esencial` no pueda tocar, por lo que escribe, nada de `ventas`, `inv`, `caja` ni `fis` (ver 5.2, regla R-T3). Pregunta 4 en 10. [D-8]

### 2.4 Excepciones declaradas del conjunto

- `TipoIdentificacion` esta en `conservarBloqueado` y en `nunca` (el especialista lo escribe asi): es una **derivada**, no una columna editable. La prueba exige que sea la unica derivada declarada y que el JSON la liste en `reglas.derivadas`; otra derivada exige subir la version. Resuelve H-A1 sin mutar la lista del especialista (solo agrega esa clave).
- `Nota`: en `anonimizarAlSuprimir` y no en `rectificar` (E-6 la tolera por la lista `soloAnonimizar`: `["Nota"]`, tambien declarada).

### 2.5 Solo personas fisicas decidido en el servidor (f, parte de datos)

En la clase 1 solo se verifica el JSON: `personaFisica` es exactamente `"TipoIdentificacion IN ('C','P','N')"` para clientes y suplidores y `"siempre"` para empleados (cadenas cerradas del esquema; una expresion distinta falla). **Lo que se decide en el servidor se prueba en la clase 3** (5.4), con el codigo que lee `TipoIdentificacion` de la base y no del pedido. [D-6]: cuando llegue el maestro de ADR-161, esta clave cambia de forma; la prueba lo exige con el mismo mecanismo de version.

### 2.6 `GENERICO` excluido por constante (g)

El plan de TT (ARQ-08) decia leer `excluir: ["Codigo = 'GENERICO'"]` como texto. **No lo hago asi**: una condicion en forma de cadena SQL no se puede evaluar con seguridad (H-6 del plan de TT, ahora H-A3). Propuesta: `"excluirCodigos": ["GENERICO"]` (lista de valores, no expresion). Casos:

| Caso | Verifica | Falla si… |
|---|---|---|
| G-1 `Excluir_GENERICO_coincide_con_la_constante` | `clientes.excluirCodigos` contiene exactamente `Cliente.CodigoContado` (por reflexion: `typeof(Cliente).GetField("CodigoContado").GetRawConstantValue()`) [V: la constante existe, `Terceros.cs:17`, valor `"GENERICO"`, y en `2fa6843b` no se referencia en ningún otro lugar de `src` ni `tests`; **no confundir** con el `CodigoContado` de `Catalogos.cs:63`, valor `"CONTADO"`, de otro catálogo: la reflexión es sobre el tipo `Cliente`] | se renombra la constante y el JSON queda atras, o el JSON la quita |
| G-2 `El_servicio_usa_la_constante_no_un_literal` | busqueda por simbolo/texto en `src/GPOS.Core/Titulares/**`: no aparece el literal `"GENERICO"` fuera del JSON y de la constante | alguien copia el literal en el servicio |
| G-3 `Todo_registro_sembrado_de_sistema_esta_excluido` | recorre los datos iniciales ([V] `SqlMigracionesMae.cs:56-58` y `database/02_actualizacion_gpos.sql:256`, según la verificación; más los sembradores de `GPOS.Migracion` [I]) y, para cliente/suplidor/empleado con `TipoIdentificacion IN ('C','P','N')` o empleado, cada `Codigo` sembrado figura en `excluirCodigos` | se siembra otro registro de sistema («CLIENTE RAPIDO») y no se excluye |
| G-4 (clase 4, con base) `GENERICO_nunca_lo_toca_TT` | ver 6.4 | la ruta lo lee o lo escribe |

La mayuscula/minuscula (`generico`): la comparacion del servicio debe ser la de la base (CI). Se prueba por comportamiento (HTTP-09 del plan de TT), no aqui; aqui solo se prohibe `==` en memoria sobre el codigo en el servicio de TT (busqueda de simbolos: ningun `string.Equals`/`==` con la constante dentro de `Titulares`; la exclusion va dentro de la consulta). [I: heuristica de texto, ver falsos positivos en 8]

## 3. Clase 2 · Cobertura de columnas por reflexion sobre el modelo (c)

### 3.1 De donde sale la lista de columnas

No de las entidades `Cliente`, `Suplidor`, `Empleado` por reflexion directa sino del **modelo de EF** (`IEntityType` para `cat.Cliente`, `cat.Suplidor`, `rrhh.Empleado`): incluye propiedades sombra (`ValidoDesde`, `ValidoHasta` [V `MaeConfiguracion.cs`]), columnas calculadas y propiedades propias de tipos poseidos (JSON anidado, ver evasiones). El modelo se obtiene **sin conexion**: construir `EmpresaNgDbContext` con `UseSqlServer` a una cadena ficticia y leer `GetService<IDesignTimeModel>().Model` (no abre la conexion al pedir el modelo [I: es el comportamiento documentado de EF Core, no lo ejecute aqui]). Para cada propiedad: nombre de columna (`GetColumnName(StoreObjectIdentifier.Table(...))`), tipo CLR, `MaxLength`, `IsUnicode`, `ValueGenerated`/`ComputedColumnSql`.

La **segunda fuente** (opcional, defensa en profundidad) es el esquema real de una base temporal (`INFORMATION_SCHEMA.COLUMNS`), como hizo mi ARQ-06; solo se corre en la clase 4 porque necesita base. Sirve para detectar columnas que existen en el esquema pero no en el modelo (SQL a mano agregado a una migracion).

### 3.2 Regla de clasificacion

Una propiedad **debe estar clasificada** si es: de tipo `string`; de tipo `byte[]` distinto de `Version`/rowversion; o cuyo nombre case con el patron de datos personales `(?i)(nacim|foto|imagen|edad|sexo|genero|nacionalidad|pasaporte|cedula|telefono|movil|celular|correo|mail|direccion|domicilio|whatsapp|firma|huella)` aunque no sea texto. Un campo numerico, de fecha o booleano no necesita estar clasificado salvo por patron. «Clasificada» significa: figura en `rectificar`, `anonimizarAlSuprimir`, `conservarBloqueado`, `nunca` o en `ClasificacionColumnas.json` con **motivo**. Esto cierra el criterio «cubierta por la lista o declarada no personal con motivo».

### 3.3 `ClasificacionColumnas.json` (archivo nuevo, resuelve H-A2)

La lista `nunca` del especialista dice **que** no se toca, no **por que**. Para las columnas de texto que el modelo ya tiene y no son personales, hay que declarar el motivo. Contenido inicial derivable de lo que lei [V]:

| Maestro | Columna de texto | Clasificacion propuesta | Motivo |
|---|---|---|---|
| cliente | `Codigo` | noPersonal | identificador operativo asignado por la serie; inmutable con movimientos |
| cliente | `TipoComprobanteCodigo` | noPersonal | codigo de catalogo fiscal (`char(2)`) |
| cliente | `TipoIdentificacion` | derivada | `char(1)` recalculado por el servidor del largo del numero |
| cliente | `CreadoPor`, `ModificadoPor` | noPersonal (usuario del sistema) | codigo de usuario de la empresa, no del titular; **Q: el codigo de usuario ¿es dato personal del empleado que lo usa? Es de otro registro y de otro regimen (ADR-34 a 36)** |
| suplidor | `Codigo`, `TipoBienServicio606`, `Clase` | noPersonal | catalogos y numeracion |
| suplidor | `CreadoPor`, `ModificadoPor` | noPersonal | idem |
| empleado | `Codigo`, `CodigoEmpleado`, `TipoComision` | noPersonal | identificadores operativos de nomina y regla de comision |
| los tres | `Version` (rowversion) | noPersonal | token de concurrencia |

Esta tabla **sale del codigo leido [V]** (columnas de texto de `Cliente` lineas 325-392 de `MaeConfiguracion.cs`; `Empleado` lineas 270-300 de `CfgConfiguracion.cs`); el mapeo de `Suplidor` (`MaeConfiguracion.cs`, desde la linea 394) **no lo lei**: las columnas de `Suplidor` las tomo de `Terceros.cs` [V], no de su mapeo; los largos no los confirme. [I]

### 3.4 Casos

| ID | Caso | Falla si… |
|---|---|---|
| C-1 | `Toda_columna_de_texto_esta_clasificada`: para cada maestro, el conjunto de propiedades obligatorias menos el conjunto clasificado es vacio. Mensaje: lista las columnas y las dos salidas posibles (agregarla a una lista del JSON, o declararla no personal con motivo en `ClasificacionColumnas.json`) | **«agregar una columna personal nueva al maestro sin clasificarla»**: `Whatsapp`, `Direccion2`, `Observaciones`, `FechaNacimiento` (por patron) |
| C-2 | `Toda_columna_del_JSON_existe_en_el_modelo`: cada nombre de las listas existe como columna de su tabla (insensible a mayusculas) y es de texto, salvo `TipoIdentificacion` | typo en el JSON; o una columna renombrada en el modelo (`Movil`→`Celular`) que deja a TT sin rectificar ese dato |
| C-3 | `Los_largos_son_los_del_mapeo` (CP-169): el largo maximo de cada campo de `rectificar` que el DTO de TT acepta es igual al `MaxLength` del modelo [V MaeConfiguracion: 150/150/20/30/30/30/30/100/200/200/200/250 en cliente] | el DTO de TT valida otro largo y el `UPDATE` trunca o falla tarde |
| C-4 | `Las_columnas_clasificadas_no_personales_no_son_de_texto_personal_por_patron`: ninguna columna declarada noPersonal casa con el patron de 3.2 (evita declarar `Telefono` como no personal) | alguien «clasifica» `Correo3` como no personal para hacer pasar C-1 |
| C-5 | `ClasificacionColumnas.json`: cada entrada con motivo de al menos 15 caracteres, sin duplicados, ordenado, y **cubierta por el dorado y CAMBIOS** igual que el JSON (misma guarda, 2.2) | se declara no personal una columna sin motivo o sin pasar por revision |
| C-6 | `Alias_coinciden_con_el_contrato`: cada alias existe como propiedad del DTO de `/api/maestros/clientes` y `/suplidores` (por reflexion sobre los tipos de respuesta/pedido del grupo, [V grupos en `TablasEndpoints.cs:13,24`]; los DTO exactos [I] no los lei) | el contrato renombra `Mobil` y TT deja de mapear ese campo |
| C-7 | `Tablas_historial_espejan_a_los_maestros`: `cat.ClienteHistorial` y `cat.SuplidorHistorial` (temporales, [V `IsTemporal` + `UseHistoryTable`]) tienen las mismas columnas que su maestro, asi la lista del verbo F-5 cubre el historial; `rrhh.Empleado` no es temporal ([V]: sin `IsTemporal`) y `historial: null` | cambia la estructura temporal y el verbo deja una columna personal sin anonimizar |

## 4. Mutaciones: por elemento de la lista (h)

La tabla siguiente es el «plan de mutacion» de la prueba. Cada fila: lo que se hace al JSON, al modelo o al codigo, la prueba que debe ponerse en rojo y por que. Se ejecutan **una sola vez al construir** (ver 4.2), no en cada corrida.

### 4.1 Mutaciones de la lista (una por elemento)

| ID | Mutacion | Debe fallar | Elemento cubierto |
|---|---|---|---|
| M-01 | Agregar una columna personal nueva al maestro (`Whatsapp` a `Cliente`) sin clasificarla | C-1 | clasificacion total (c) |
| M-02 | Agregar la misma columna al JSON en `rectificar` sin tocar el dorado | B-1 | copia dorada (b) |
| M-03 | Agregar la columna al JSON y al dorado, sin subir `version` | B-2 | guarda de version |
| M-04 | Subir `version` en JSON y dorado, sin entrada en `CAMBIOS.md` | B-3 | bitacora |
| M-05 | Quitar `Correo` de `anonimizarAlSuprimir` (en JSON, dorado y CAMBIOS bien hechos) | E-6 | lo rectificable se trata al suprimir |
| M-06 | Agregar `LimiteCredito` a `rectificar` (con dorado y CAMBIOS) | E-1 y C-2 (no es de texto) | nunca el negocio |
| M-07 | Agregar `Nota` a `rectificar` | E-6/regla `soloAnonimizar` | Nota solo se limpia |
| M-08 | Poner `Codigo` en `conservarBloqueado` | E-4 | solo lo rectificable se conserva |
| M-09 | Duplicar `Telefono` en `rectificar` | esquema (a), regla 4 | sin duplicados |
| M-10 | Poner `Telefono` y `telefono` (distinta mayuscula) | esquema (a), regla 4 | intercalacion CI |
| M-11 | Desordenar `Correo`/`Correo2` | esquema, regla 5 | ordenado |
| M-12 | Agregar la propiedad `"permitirTodo": true` en un maestro | esquema, regla 3 | propiedades permitidas |
| M-13 | Cambiar `version` a `0`, a `"1"` (texto) o quitarla | esquema, regla 2 | version |
| M-14 | Cambiar `personaFisica` a `"siempre"` en `clientes` | esquema/2.5 | solo personas fisicas |
| M-15 | Quitar `GENERICO` de `excluirCodigos` | G-1 | exclusion por constante |
| M-16 | Renombrar `Cliente.CodigoContado` a `"CONTADO"` | G-1 | idem |
| M-17 | Sembrar un cliente de sistema (`Codigo = 'CLIENTE-RAPIDO'`, tipo `N`) sin excluirlo | G-3 | sembrados excluidos |
| M-18 | Renombrar el alias `Movil` a otro | C-6 | alias del contrato |
| M-19 | Quitar una entrada del dorado y del JSON a la vez, sin CAMBIOS | B-3 | idem |
| M-20 | Editar un hash de una entrada vieja de CAMBIOS | B-3 | (solo la ultima se compara con el JSON; las anteriores se detectan en revision, ver B-4: **limite declarado**) |
| M-21 | Declarar `Telefono2` como noPersonal en `ClasificacionColumnas.json` | C-4 | no esquivar con la declaracion |
| M-22 | Agregar `TitularBloqueadoEn` a `rectificar` | E-1 | marca solo la escribe TT |
| M-23 | Cambiar `reglas.rechazarCamposFuera` | esquema, regla 8 | contrato de error |
| M-24 | Agregar una derivada nueva a `reglas.derivadas` | B-1 (dorado) y regla propia | derivadas cerradas |
| M-25 | Quitar `espejoHeredado` mientras exista `PuenteMae` | ARQ-09 (7.2) [P9][D-2] | espejo |
| M-26 | Dejar `espejoHeredado` cuando `PuenteMae` ya no existe | ARQ-09 (7.2) [P9][D-2] | centinela de dos sentidos |
| M-27 | Agregar a `com.Comensal` una columna `Cedula` | ARQ-13 (7.3) [D-7] | comensal sin identificadores ajenos |
| M-28 | **(v2)** Crear una vista `rpt.X` con una columna `RncCliente` sin ponerla en `SalidasIdentificacionTercero.json` | Z-1 | salidas nuevas clasificadas |
| M-29 | **(v2)** Cambiar la política de `rpt.Formato606` a `enmascarable`, o enmascarar su `RncCedula` | Z-3 (y SQL-80 del plan de TT) | el 606 y el 607 no se enmascaran |
| M-30 | **(v2)** Agregar a `ReportesSemilla.cs` un reporte con SQL directo sobre `caja.CajaChica.RncCedula` sin clasificar | Z-2 | reportes con SQL directo |
| M-31 | **(v2)** Agregar una ruta que ponga `cat.Cliente.Inhabilitado` fuera de TT | X-5 | escritores de `Inhabilitado` |
| M-32 | **(v2)** Agregar un servicio que llame a `ReferenciasNg.ClienteAsync` sin listarlo en `ConsumidoresTerceroBloqueo.json` | X-6 | consumidores de un tercero |
| M-33 | **(v2)** Que `PuenteMae.ClienteAsync` asigne `Telefono3` (o cualquier columna heredada no clasificada) | ARQ-10 | espejo por comportamiento |

### 4.2 Como se ejecutan las mutaciones sin dejarlas en el codigo

Mismo tratamiento que en el plan de dorados: **la mutacion se hace en un arbol temporal o en memoria, no en el repositorio**. Dos formas, en este orden de preferencia:

1. **En memoria (preferida):** las clases 1 y 2 reciben el JSON, el dorado, CAMBIOS y el modelo como **valores** (un metodo `Validar(contrato, dorado, cambios, modelo)` puro); una prueba parametrizada `Mutaciones` aplica M-01..M-27 sobre copias en memoria y exige que `Validar` devuelva el error esperado. Es una prueba **corriente** (siempre corre), no una verificacion de una sola vez; cuesta ~0,3 dp mas pero convierte la lista de mutaciones en un guardian permanente del propio guardian. Es la respuesta a «¿quien vigila al vigilante?».
2. **En un arbol temporal (para las que dependen del codigo, M-17, M-25..M-27, G-2):** copiar `src` y `tests` relevantes a un directorio temporal, editar y correr solo esa clase. Solo al construir; se anota en `CAMBIOS.md` del proyecto de pruebas.

**Aceptacion del plan:** una mutacion que no hace fallar la prueba esperada es un defecto de la prueba, no del codigo.

## 5. Clase 3 · Rutas, DTO y servidor decide (d, f)

### 5.1 Como se detecta una ruta de TT

Tres mecanismos que se **exigen a la vez** (cualquiera por si solo es evadible):

1. **Convencion de prefijo:** toda ruta cuyo patron empieza con `/api/titulares/` es una ruta de TT.
2. **Atributo/metadato propio:** un `TitularRutaAttribute`/metadato de endpoint (`.TitularRuta(TitularAccion.Rectificar)`) que marca la ruta y declara el verbo logico; lo agrega el grupo de TT y se lee con `e.Metadata.GetMetadata<TitularRutaMetadata>()`. Es un metadato nuevo de L1b (como `ClaseLicencia`, `RequiereAutenticacionReciente` [V]).
3. **Lista blanca en la prueba:** el conjunto exacto esperado, escrito en el dorado de rutas (puede ir dentro de `CamposPersonalesTitular.dorado.json` como `rutas`, o en `RutasLicenciaAprobadas.json` la parte `Esencial`): `GET /api/titulares/{maestro}/{codigo}`, `POST|PUT … /rectificar`, `POST … /suprimir` [V: rutas de F-4; verbos HTTP exactos de rectificar/suprimir **[I]**, la hoja no los fija: pregunta 1 en 10].

Casos:

| ID | Caso | Falla si… |
|---|---|---|
| R-1 | `Las_rutas_de_TT_son_exactamente_las_de_la_lista`: el conjunto de rutas con prefijo `/api/titulares/` (de `EndpointDataSource`, como `api.Rutas()` [V]) == la lista blanca; ninguna ruta tiene el metadato sin el prefijo ni el prefijo sin el metadato | se agrega `DELETE /api/titulares/...` o una ruta de TT bajo `/api/maestros/...` |
| R-2 | `Ninguna_ruta_de_edicion_normal_acepta_solo_campos_personales_ni_se_marca_Esencial`: las rutas de `/api/maestros/clientes|suplidores` y empleados siguen `Operativa`; el test existente ya lo asegura para `POST /api/maestros/clientes` [V `Rutas_que_siguen_operativas`]; aqui se agrega que `PUT/PATCH` de esos grupos tambien | alguien marca `Esencial` la edicion normal y abre la edicion de maestros en solo consulta |
| R-3 | `Las_rutas_de_TT_son_Esencial_y_estan_en_la_lista_aprobada`: las tres, con clase `Esencial`, figuran en `RutasLicenciaAprobadas.json` con motivo que cita F-4/TT-05, y la lista tiene exactamente esas entradas con prefijo `/api/titulares/` [V mecanismo: `Toda_ruta_relajada_esta_en_la_lista_aprobada…`] | ruta de TT queda `Operativa` (se bloquea en `SoloConsulta`: viola TT-05) |
| R-4 | `La_ruta_exige_el_privilegio_solicitudestitulares`: el endpoint tiene `RequierePermiso(Permisos.SolicitudesTitulares)` (o el equivalente) y no el permiso del maestro (`Permisos.Clientes`) | se usa el permiso de edicion de clientes: cualquier usuario que edite clientes ve y borra datos de titulares |
| R-5 | `Suprimir_exige_autenticacion_reciente_o_confirmacion` [I]: la hoja dice «teclear el codigo del registro» (confirmacion en el cuerpo); si B tambien exige `RequiereAutenticacionReciente()` (como `S-03` [V]) la prueba lo fija | se quita la proteccion de una accion irreversible |

### 5.2 DTO cerrados (sin campos extra) por reflexion

El delegado de cada endpoint es un `MethodInfo` (`e.Metadata.GetMetadata<MethodInfo>()`); sus parametros que vienen del cuerpo son los DTO. Reglas, aplicadas **recursivamente** a cada tipo alcanzable:

| ID | Regla | Evasion que cierra |
|---|---|---|
| D-1 | Las propiedades publicas de los DTO de `rectificar` son **un subconjunto de** `rectificar` (por alias, el nombre del contrato) ∪ `{Motivo, FechaRecepcion, Apoderado, Poder (datos), Version}`; las de `suprimir`, de `{Motivo, FechaRecepcion, Apoderado, Poder, CodigoConfirmacion, Opcion (F-9)}`; ninguna mas. La lista de la derecha tambien va en el dorado (`campos del acto`) | DTO que gana `LimiteCredito`, `TipoIdentificacion`, `EsPersonaFisica` |
| D-2 | Se usa el **nombre JSON** (`[JsonPropertyName]` o la politica del serializador de la API), no el nombre CLR: un `[JsonPropertyName("limite")] decimal Importe` no pasa por llamarse distinto | renombrar la propiedad |
| D-3 | Prohibidos en el DTO: `JsonElement`, `JsonNode`, `object`, `dynamic`, `Dictionary<,>`, `IDictionary`, `[JsonExtensionData]`, y cualquier tipo anidado no listado | JSON anidado/diccionario que arrastra campos |
| D-4 | El DTO se deserializa con `UnmappedMemberHandling = Disallow` **para estas rutas**; la prueba comprueba que el serializador efectivo de la ruta (la opcion `JsonOptions` del endpoint o un lector propio) lo tiene. **[V: el lector de licencias usa `Skip` (`LectorContenidoLicencia.cs:43`); no encontre `Disallow` en `src`** — hay que construirlo; por omision ASP.NET ignora silenciosamente lo desconocido] | cuerpo con campos extra que se ignoran y llegan al servicio por otro camino |
| D-5 | Prueba de comportamiento (clase 4, 6.2): cuerpo con cada columna de `nunca` (una por caso, con la grafia exacta, en MAYUSCULAS, en minusculas, con espacios al final, con clave duplicada) → `400 CAMPO_NO_PERSONAL`, base intacta | mayusculas, claves duplicadas |
| D-6 | DTO de **respuesta** del `GET` y de los demas: propiedades ⊆ `rectificar` ∪ `conservarBloqueado` ∪ `{Codigo, Version, Tipo/estado de bloqueo, plazo, avisos}`; **sin saldos, credito ni terminos** (HTTP-46 del plan de TT) | el GET filtra datos del negocio |
| D-7 | Ningun DTO (pedido ni respuesta) de TT tiene `TipoIdentificacion`, `EsPersonaFisica` o `Tipo` como **entrada**; en la respuesta puede ir como dato de solo lectura | el tipo viaja en el pedido (F-4: «lo decide el servidor, no el pedido») |
| D-8 | `[FromQuery]`, `[FromRoute]`, `[FromHeader]` solo para `maestro` (valor de lista cerrada) y `codigo`; ningun otro parametro de query puede alterar que campos se tocan | un `?campos=` o `?incluirJuridicas=true` |

### 5.3 Solo personas fisicas decidido en el servidor (f)

| ID | Caso | Falla si… |
|---|---|---|
| F-1 | **Arquitectura:** el servicio de TT, por simbolos, lee `TipoIdentificacion` **de la entidad/base**, nunca de un DTO de pedido (D-7 + busqueda: ninguna referencia a una propiedad `TipoIdentificacion` de un tipo de pedido en `Titulares`) | el tipo del pedido decide |
| F-2 | **Arquitectura:** el filtro `TipoIdentificacion IN (C,P,N)` se aplica en la **consulta** (predicado dentro del `Where` de EF), no despues en memoria. Prueba con el interceptor (6.3): el `SELECT` de cada accion contiene la condicion sobre `TipoIdentificacion` | se carga el registro `R` y se decide despues (y algun camino lo escribe) |
| F-3 | **Comportamiento** (clase 4): registro `R` → `GET/rectificar/suprimir` rechazados, **cero** sentencias `UPDATE` sobre la tabla (interceptor), base intacta | exclusion solo en la interfaz |
| F-4 | El recalculo de `TipoIdentificacion` tras rectificar usa `TiposIdentificacion.TipoDe` [V `Terceros.cs`] (la misma funcion que el alta); la prueba exige que el resultado ∈ `reglas.identificacionTipoResultante`; si es `R` → rechazo | rectificar convierte a la persona en juridica y la saca de TT |

**Limite declarado:** F-1 por busqueda de simbolos detecta el uso directo, no un uso a traves de un metodo auxiliar generico; lo respalda F-3, que es de comportamiento.

## 6. Clase 4 · Ninguna ruta lee ni escribe fuera de la lista (d, en ejecucion)

### 6.1 Idea

Una **interceptor de comandos de EF** (`DbCommandInterceptor`, registrado solo en la prueba) captura el SQL que ejecuta cada llamada a `/api/titulares/...` y extrae, con un analizador sencillo, (a) las **columnas del `SET`** de cada `UPDATE`/`INSERT` y (b) las **columnas del `SELECT`** de las tablas del maestro. Esas columnas deben estar en el conjunto permitido por accion. Es una prueba de **caja gris**: valida el SQL realmente emitido, y se cumple sin importar como se llame cada propiedad del DTO.

Condicion previa (**regla de construccion que se propone a B, H-A4**): el codigo de TT dentro de la API **no usa SQL a mano (Dapper, `FromSqlRaw`, `ExecuteSqlRaw`, `SqlCommand`)** para los maestros; todo pasa por EF, de modo que el interceptor lo ve todo. Una prueba de arquitectura lo hace cumplir (6.5). El verbo de `GPOS.Migracion` si usa SQL a mano (apaga/enciende el versionado temporal), pero **genera la lista de columnas del JSON**, no la escribe a mano (6.6).

### 6.2 Conjuntos permitidos por accion

| Accion | Escritura permitida (SET/INSERT) | Lectura permitida (SELECT) |
|---|---|---|
| `GET` | ninguna (solo la auditoria de acceso, en otra tabla: `audit.Bitacora`, ver abajo) | `rectificar` ∪ `conservarBloqueado` ∪ técnicas `{Id, Codigo, Version, TipoIdentificacion, Inhabilitado, TitularBloqueadoEn, FusionadoEnId}` |
| `rectificar` | `rectificar` ∪ `{ModificadoEn, ModificadoPor}` (y las de periodo de la temporal) | las del `GET` |
| `suprimir` | `anonimizarAlSuprimir` ∪ `{Inhabilitado, TitularBloqueadoEn, ModificadoEn, ModificadoPor}` | las del `GET` + (F-9) saldos de CxC/CxP |

Las **tablas auxiliares** (`audit.Bitacora`, la tabla de solicitud/apoderado [H-4 del plan de TT: aun sin ubicar], el adjunto del poder, los saldos para F-9) se declaran en una lista `tablasAuxiliares` **dentro del dorado**, con columnas de lectura/escritura permitidas, y se prueba aparte (no se escribe nada de `ventas`, `inv`, `caja`, `fis` ni de `cat.*` fuera de los tres maestros: regla R-T3 del punto 2.3(i)). El nombre del apoderado no va a `audit.Bitacora` (SQL-62 del plan de TT). [D-5][H-4]

### 6.3 Casos

| ID | Caso | Falla si… |
|---|---|---|
| S-1 | `Rectificar_cada_campo_solo_emite_UPDATE_de_ese_campo`: para cada columna de `rectificar` (una por caso), el `UPDATE` emitido tiene en el `SET` esa columna (y las de auditoria permitidas) y ninguna otra | el servicio hace `UPDATE` de la entidad completa con valores por omisión (SQL-01 del plan de TT, desde otro angulo) |
| S-2 | `Suprimir_solo_toca_anonimizar_mas_bloqueo` | se anonimiza una columna de `conservarBloqueado` o se toca `LimiteCredito` |
| S-3 | `GET_no_lee_columnas_de_negocio`: el `SELECT` no incluye `LimiteCredito`, `ListaPrecioId`, `TerminoId`, `Nota`… | el servicio materializa la entidad completa (`SELECT *`-equivalente) |
| S-4 | `GENERICO_nunca_lo_toca` (G-4): `GET/rectificar/suprimir` sobre `GENERICO` → rechazo y **cero** `UPDATE`; el `SELECT` incluye la exclusion en el `WHERE` | la exclusion se hace en memoria |
| S-5 | `Registro_juridico_cero_UPDATE` (F-3) | idem |
| S-6 | `Cuerpo_con_campo_extra_cero_sentencias`: cualquier cuerpo con campo extra → `400 CAMPO_NO_PERSONAL` y **ningun comando SQL de escritura** (el interceptor no ve `UPDATE`/`INSERT`/`DELETE`) | el campo se rechaza *despues* de abrir transaccion o escribir bitacora |
| S-7 | `La_ruta_no_toca_otras_tablas`: el conjunto de tablas escritas ⊆ {maestro, `ClienteHistorial` (solo a traves del versionado), `audit.Bitacora`, tabla de solicitud, adjuntos}; ninguna de `ventas.*`, `compras.*`, `inv.*`, `caja.*`, `fis.*`, `Clientes`/`Suplidores` heredadas **salvo [P9]** | TT-04: propaga el cambio a los comprobantes emitidos (SQL-04 del plan de TT) |
| S-8 | `Parametros_con_tipo_y_largo` (ADR-50): todo parametro de texto de esos comandos es `varchar(n)` con el largo de su columna, tomando el atributo `DbType`/`Size` del `DbCommand` capturado (la misma forma de `ContratoConsultasTests`, [V]) | `nvarchar` degrada a scan |

### 6.4 Reglas para el analizador de SQL del interceptor

- Se usa un analizador reducido propio sobre el texto que genera EF para SQL Server (`UPDATE [cat].[Cliente] SET [Telefono] = @p0, ... WHERE ...`; `SELECT [c].[Id], [c].[Codigo]...`) **o**, si el equipo tiene `Microsoft.SqlServer.TransactSql.ScriptDom`, ese. Costo del paquete: licencia MIT y ya en el ecosistema de SQL [I: no verificado si ya esta referenciado; **politica de paquetes: solo si B lo aprueba**]. La alternativa sin paquete: contar con que EF emite siempre `[alias].[Columna]`/`SET [Col] =` y extraer con expresiones regulares, **cubriendo solo lo que EF emite**; las sentencias que no calzan con el patron hacen fallar la prueba («no entiendo este SQL»), nunca la pasan en vacio.
- El interceptor lee `DbCommand.CommandText` en `ReaderExecuting`/`NonQueryExecuting`/`ScalarExecuting` y su `Parameters`.
- Registra por solicitud (correlacion con `AsyncLocal` o un `ILogger` de la prueba).
- **(v2) Se registra en los dos contextos de la unidad de trabajo:** `u.Ng` (modelo nuevo) y `u.Heredado` (el puente escribe `Clientes`/`Suplidores` con otro `DbContext` [V `PuenteMae.cs:143-162`]). Un interceptor solo en `u.Ng` no vería nunca la escritura del espejo y S-7 pasaría en vacío. `PuenteMae` usa EF y no SQL a mano [V], por lo que no viola X-1.
- **(v2) Implicación de diseño [I]:** si el servicio de TT rectificara llamando a `MaestrosService.GuardarClienteNgAsync` (que escribe el DTO completo y llama al puente), S-1 fallaría y un campo omitido podría quedar en blanco. El diseño que cumple S-1 es: `UPDATE` propio de las columnas de la lista, y luego `PuenteMae.ClienteAsync` con un DTO reconstruido de la fila ya actualizada.

### 6.5 Reglas de arquitectura que sostienen a la clase 4

| ID | Regla | Falla si… |
|---|---|---|
| X-1 | En el namespace de TT (`GPOS.Core.Titulares`, `GPOS.Api…Titulares`) no se referencian `Dapper`, `FromSqlRaw`, `FromSqlInterpolated`, `ExecuteSqlRaw`, `ExecuteSqlInterpolated`, `SqlCommand`, `DbCommand`, `SqlBulkCopy` (busqueda en el ensamblado, por referencias a miembros, no por texto) | TT escribe SQL a mano y escapa al interceptor |
| X-2 | `GPOS.Api` no concede a la API `ALTER` sobre las tablas temporales: el servicio de TT no contiene `SYSTEM_VERSIONING` (texto del ensamblado y de las fuentes) (SQL-18 del plan) | alguien «arregla» TT dando DDL a la API |
| X-3 | El verbo de `GPOS.Migracion` `titulares --anonimizar-historial` **construye sus sentencias a partir del JSON** (llama al lector del recurso incrustado) y no contiene los nombres de columna como literales: busqueda en el codigo del verbo de cualquier nombre de columna de `anonimizarAlSuprimir`/`conservarBloqueado` entre comillas | el verbo y el servicio divergen (el servicio anonimiza una columna y el verbo olvida el historial) |
| X-4 | `TitularBloqueadoEn` solo lo asigna el servicio de TT (ARQ-11 del plan de TT): busqueda por simbolos de escritura de esa propiedad fuera de `Titulares` | la edicion normal del maestro reactiva |

### 6.6 `excluir` / `excluirCodigos` y el hueco de la cadena SQL

El JSON del especialista trae `excluir: ["Codigo = 'GENERICO'"]` y `personaFisica: "TipoIdentificacion IN ('C','P','N')"`: ambos son **cadenas con forma de SQL**. Si el servicio las *concatenara* en una consulta, serian una inyeccion en potencia y ninguna de las pruebas anteriores lo veria (el interceptor veria el SQL resultante, que casi siempre seria *correcto*). Postura de la prueba:

1. **El servicio no interpreta cadenas del JSON como SQL.** X-1 prohibe SQL a mano; el predicado se escribe en C# (`c.TipoIdentificacion == "C" || ...`), y el JSON solo documenta.
2. Para eso, el JSON deja de tener expresiones: `personaFisica` pasa a `{"tipos": ["C","N","P"]}` (o `"siempre"`), y `excluir` a `excluirCodigos` (lista). **Es un cambio a la propuesta del especialista**; pregunta 2 en 10.
3. Si B decide conservar la cadena, la prueba **no puede cerrar el hueco** y queda registrado como riesgo no cubierto (seccion 10): la unica defensa seria que ningun codigo la use.

## 7. Cuatro areas que dependen de decisiones abiertas

### 7.1 [P1] Rectificar y el historial temporal

Si la respuesta es «rectificar purga la version anterior del historial», el JSON necesita una clave por maestro (`rectificarPurgaHistorial: true`) y el verbo de `GPOS.Migracion` deberia correr tambien para rectificar. Impacto en esta prueba: (i) esquema (a): una propiedad mas permitida; (ii) X-3: el verbo se invoca desde dos acciones; (iii) C-7 sin cambio. Si la respuesta es «el valor viejo queda hasta el verbo de F-5», no cambia nada de la lista (SQL-05 del plan de TT lo afirma como comportamiento). **La prueba de arquitectura es indiferente; el esquema del JSON, no.**

### 7.2 [P9][D-2] Espejo heredado (`PuenteMae`) — reescrita en la v2

**Lo verificado en `2fa6843b` [V]** (`src/GPOS.Core/Infraestructura/Transicion/PuenteMae.cs`, releído por mí; coincide con la verificación de `b4378650`):

- `PuenteMae` existe y «se elimina en la ola 3» (cabecera). Sigue siendo un centinela real, no hipotético.
- `ClienteAsync(u, ClienteDto d, ct)` (líneas 143-152) y `SuplidorAsync` (154-162) **reciben el DTO completo** y lo copian a la fila heredada de `Clientes`/`Suplidores` en la misma unidad de trabajo. Copian: razón social, nombre comercial, RNC (el DTO ya trae solo dígitos, `MaestrosService.cs:166, 204`), `Telefono1`, `Telefono2`, `Mobil`, `Fax`, `Contacto`, `Direccion`, `CorreoElectronico1`, `CorreoElectronico2`, `PaginaWeb`, `Nota` y los catálogos y condiciones comerciales.
- **No escriben** `Telefono3`, `CorreoElectronico3` ni `IdDireccion` (no hay asignación en el texto): en filas creadas por el puente quedan `NULL`. El plan v1 y el JSON del especialista los trataban como «columnas extra» a anonimizar: no hay nada que anonimizar.
- **No copian `Inhabilitado`** ni `LimiteCredito` (verificación, hecho 5): la fila heredada nunca ve un bloqueo.
- `EliminarMaestroAsync` (líneas ~247-252) **borra** la fila heredada; TT bloquea y no elimina, así que no debe llamarla (SQL-25 del plan de TT).

**Consecuencias para la prueba:**

1. **ARQ-09 (centinela de dos sentidos), sin cambio de fondo:** `Type.GetType("GPOS.Core.Infraestructura.Transicion.PuenteMae, GPOS.Core")`. Si existe: o el JSON tiene `espejoHeredado` en clientes y suplidores (`{tabla, extraNoEscritas, vigenteHasta}`), o declara `estado: "aplazado-hasta-eliminar-puente"` y la clase 3 comprueba que las rutas de TT están desactivadas (R-1 espera lista vacía); lo decide **P9**. Si no existe: el JSON no debe llevar `espejoHeredado`. Mutaciones M-25 y M-26.
2. **ARQ-10 por comportamiento (sustituye la petición de `ColumnasPersonalesCopiadas`; pregunta 9 de la v1 cerrada):** un contexto heredado de prueba (en memoria; [I] se puede instanciar), un `ClienteDto` y un `SuplidorDto` con un **centinela único** en cada propiedad de texto, una llamada al puente y la lectura de qué columnas de `Clientes`/`Suplidores` contienen un centinela. Cada una debe corresponder a una columna **clasificada** del modelo nuevo; `Telefono3`, `CorreoElectronico3` e `IdDireccion` no deben contener ninguno. Si el puente empieza a copiar un campo nuevo (M-33) la prueba lo atrapa sin analizar texto de código.
3. **Interceptor y espejo:** S-7 amplía las tablas permitidas a `Clientes`/`Suplidores` y las columnas a las que ARQ-10 descubre **solo si P9 = «TT escribe el espejo»**; si P9 = «TT espera», S-7 las prohíbe. El interceptor debe estar registrado en `u.Heredado` (§6.4).
4. **JSON:** `espejoHeredado.extra` del especialista se sustituye por `extraNoEscritas` (documental, verificada por ARQ-10: debe seguir `NULL`). Es un cambio a la propuesta del especialista que firma B (H-A8).
5. **Qué no resuelve el hecho:** no decide P9. Reduce su costo (el puente es reutilizable en una llamada) pero el propietario, con B, decide si TT sale antes de la ola 3 con el espejo o se aplaza hasta eliminarlo.

### 7.3 [D-7] Comensales

- ARQ-12/13/14 como en el plan de TT, pero con la **deteccion por tipo**: `Type.GetType("GPOS.Core.Dominio.Comedor.Comensal, GPOS.Core")` es `null` hoy [V: no existe en ninguna rama]. Cuando exista el tipo y el JSON siga con `estado: "pendiente-entrega-3"` → falla (centinela). Con el tipo presente: `com.Comensal` y `com.ComensalAsignacion` sin columnas de cedula/telefono/correo/direccion/nacimiento (patron de 3.2) y toda columna de texto en el JSON o en `ClasificacionColumnas.json` (C-1 se extiende a la tabla). El nombre real del tipo y del espacio de nombres **no lo se**: la prueba busca por nombre de tabla en el modelo EF (`IEntityType.GetTableName() == "Comensal"` en esquema `com`), que es independiente del espacio de nombres.

### 7.4 [D-4][D-5] Lista final de anonimizacion y deuda F-9

Con [D-4] la lista de `anonimizarAlSuprimir` puede perder `NombreComercial`, `Contacto`, `PaginaWeb` o `Nota`. Para la prueba no cambia estructura: el cambio pasa por la guarda 2.2. Con [D-5] se suma una lista `conservarPorDeuda` (nombre, documento y un medio de contacto, propuesta de B no firmada). Regla: `conservarPorDeuda ⊆ rectificar ∪ derivadas` y `conservarPorDeuda ∩ anonimizarAlSuprimir` solo puede contener las columnas que se anonimizan *despues* (supresion aplazada): hasta firmar, **la clave no esta permitida en el esquema** (regla 3 de 2.1), y la prueba lo afirma para no dejar pasar una lista no firmada.

### 7.5 (v2) Clase 5 · Centinela de salidas que exponen identificación (ARQ-17 del plan de TT)

**Para qué.** El inventario contó 22 salidas que muestran la identificación del tercero y encontró una fuga que el enmascarado de `rpt.CajaChica` no cubre (`EF-CAJA-CHICA`, `ReportesSemilla.cs:303-304`). Hoy nada obliga a que una salida nueva se clasifique. La lista versionada `SalidasIdentificacionTercero.json` hace que toda vista, consulta, reporte de la semilla o modelo de impresión que exponga identificación, contacto o dirección de un tercero **deba figurar con su política**, de modo que agregar una obliga a decidir.

**Forma de la lista** (misma guarda de dorado y `CAMBIOS.md` que el JSON de TT, §2.2; por ello el cambio se ve en tres lugares):

```json
{ "version": 1,
  "salidas": [
    { "id": "rpt.Formato606", "inventario": 11, "tipo": "vista",
      "columnas": ["RncCedula"], "politica": "obligatoria-no-enmascarar",
      "fuente": "copia-en-documento", "dependeDe": "ninguna", "privilegio": null,
      "motivo": "Formato DGII; se protege por acceso (RS-04), no por enmascarado" },
    { "id": "rpt.CatCliente", "inventario": 6, "tipo": "vista",
      "columnas": ["Identificacion"], "politica": "enmascarable",
      "fuente": "maestro", "dependeDe": "letra", "privilegio": null, "motivo": "..." } ] }
```

Valores cerrados: `politica` ∈ {`enmascarable`, `obligatoria-no-enmascarar`, `restringida-por-privilegio`}; `fuente` ∈ {`maestro`, `copia-en-documento`, `texto-libre`}; `dependeDe` ∈ {`letra`, `largo`, `ninguna`, `EsPersonaFisica`}. La columna `fuente` es la que importa para TT: lo que lee del **maestro** muestra lo anonimizado tras suprimir; lo que lee la **copia en el documento** conserva el valor sellado (TT-04, ADR-74); `texto-libre` (caja chica) queda fuera de TT (D-14).

| ID | Caso | Cómo se detecta | Falla si… |
|---|---|---|---|
| Z-1 | `Toda_vista_con_identificacion_esta_clasificada`: en una base temporal con las migraciones aplicadas, toda columna de salida de las vistas de `rpt`, `rptc` y `ext` (este último, ADR-109) cuyo nombre case con el patrón de identificación o contacto (`(?i)(rnc|cedula|identificacion|pasaporte|documento|telefono|movil|correo|direccion)`) figura en la lista | `sys.columns` de las vistas: da la definición **vigente**, lo que resuelve que haya dos definiciones de `rpt.ConsultaFactura` y tres de `Formato607` en los guiones | una vista nueva expone RNC sin política (M-28) |
| Z-2 | `Todo_reporte_de_la_semilla_con_SQL_directo_esta_clasificado`: para cada reporte de `ReportesSemilla.cs` cuyo SQL nombra una tabla base (no `rpt.`/`rptc.`) que tiene una columna de identificación, el par (reporte, tabla.columna) figura. La lista de «tablas con identificación» sale del **modelo de EF**: todas las columnas de texto cuyo nombre case con el patrón, en cualquier entidad (esto descubre `caja.CajaChica.RncCedula`) | modelo EF sin conexión (§3.1) + extracción de `esquema.tabla` del texto SQL | `EF-CAJA-CHICA` o un reporte semejante vuelve a eludir el enmascarado (M-30) |
| Z-3 | `Las_obligatorias_no_se_enmascaran`: para las entradas `obligatoria-no-enmascarar` (606, 607, impresión de comprobantes, retención, verificación de exportación) la definición de la vista (`sys.sql_modules`) no aplica el patrón de enmascarado (`'*******'`, `RIGHT(..., 4)`) a la columna listada; el modelo de impresión no pasa el valor por una función de enmascarado | texto de `sys.sql_modules` + reflexión; el comportamiento lo cubren SQL-80/81/82/83 del plan de TT | alguien enmascara «todo lo que muestre la identificación» y rompe el 606 o el comprobante (M-29) |
| Z-4 | `Los_modelos_de_impresion_estan_clasificados`: las propiedades con patrón de identificación o contacto de los tipos de `GPOS.Contracts.Impresion` y de `FabricaModelo` (cliente, retención, caja chica) figuran con su política | reflexión sobre los tipos del modelo de formato | un campo de tercero nuevo sale impreso sin política |
| Z-5 | `Las_tablas_con_identificacion_estan_clasificadas` (v2): cada tabla con columna de identificación del modelo de EF figura en `tablasConIdentificacion` como `maestro`, `copia-en-documento` o `texto-libre`; una tabla nueva obliga a decidir si TT-04 (copias selladas) o TT-P3 la alcanza | modelo EF | se agrega `fis.Retencion.NombreBeneficiario` o una tabla con cédula sin decidir si la supresión debe tratarla |
| Z-6 | `La_lista_de_salidas_no_tiene_entradas_muertas_ni_incompletas`: cada entrada existe todavía (vista, reporte o tipo), tiene `motivo` de al menos 15 caracteres y, si es `restringida-por-privilegio`, el privilegio nombrado existe (`verdatospersonales`) | base y reflexión | la lista envejece y deja de vigilar |

**Límites declarados.** (i) Z-1 y Z-2 necesitan base y modelo; Z-3/Z-4/Z-5/Z-6 corren sin base salvo la parte de vistas. (ii) El patrón detecta nombres, no contenido: una columna llamada `Doc` con una cédula escapa (se cubre solo con revisión humana de la lista). (iii) El diseñador de reportes permite elegir cualquier columna: lo que un usuario construya en la base de datos del cliente queda fuera de la lista; es el riesgo aparte que ya anota el inventario. (iv) Qué se enmascara y cómo es decisión de ADR-161 (M-5), no de esta prueba: la clase 5 solo obliga a que la decisión exista por salida.

### 7.6 (v2) Centinelas del estado «bloqueado» (ARQ-15 y ARQ-16 del plan de TT)

- **X-5 `Escritores_de_Inhabilitado`.** Por símbolos de escritura sobre `Cliente.Inhabilitado`: hoy [V] ninguna ruta lo pone en 1 (`ClienteDto` no lo tiene, `GuardarClienteNgAsync` no lo escribe, `MaestrosService.cs:137-210`); el conjunto de escritores debe ser exactamente {servicio de TT}. Para `Suplidor` el editor sí lo escribe (`MaestrosService.cs:358`): el conjunto es {editor, TT} y el editor **no puede quitar una marca de TT** (HTTP-50 del plan de TT, por comportamiento). Falla si: se agrega «inhabilitar cliente» fuera de TT (M-31).
- **X-6 `Consumidores_de_un_tercero_estan_clasificados`.** `ConsumidoresTerceroBloqueo.json` lista cada punto que lee un cliente o suplidor para un documento (`ReferenciasNg.ClienteAsync`, `PartidasCxp.SuplidorAsync` y las lecturas directas del DbSet) con `decision` ∈ {`rechaza-documento-nuevo`, `permite-liquidacion`} y el archivo y método; hoy [V] ninguno de cliente lee la marca, y de suplidor unos validan (`Notas.cs:68`, `Bancos.cs:73`, `Compras.cs:444`) y otros no (`Bancos.cs:370`, `Aplicaciones.cs:52`, `Devoluciones.cs:71`). La detección es por texto (llamadas a esas dos funciones y al DbSet) con clave `archivo::método`: [I] heurística, con falsos positivos que se resuelven agregando la entrada, no relajando la regla. Falla si un servicio nuevo lee el tercero sin decidir (M-32). Sirve también para que HTTP-31a del plan de TT sea una prueba parametrizada sobre la lista y no una enumeración a mano.
- **Orden de firma.** Los dos JSON nuevos (§1) los firma B junto con `CamposPersonalesTitular.json` (D-8); el contador firma la política de las salidas `obligatoria-no-enmascarar`.

## 8. Evasiones previstas y falsos positivos

### 8.1 Evasiones

| Evasion | Defensa | Caso |
|---|---|---|
| Renombrar la propiedad del DTO (`Importe` con `[JsonPropertyName("limite")]`) | Se compara el **nombre JSON**, no el CLR | D-2, M-06 |
| Columna calculada (`NombreCompleto AS Nombres + Apellidos`; `HasComputedColumnSql`) | C-1 usa el modelo: las calculadas entran; debe clasificarse como `derivada` con `derivadaDe` o noPersonal con motivo; una calculada de texto personal no esta en ninguna lista y falla | C-1, M-01 |
| JSON anidado: `Contacto` como `OwnsOne(...).ToJson()` o DTO anidado `{ "Direccion": { "Calle": ... } }` | El modelo se aplana: se recorren los tipos poseidos y sus columnas; D-3 prohibe tipos anidados no listados y `JsonElement`/diccionarios | C-1, D-1, D-3 |
| Mayusculas / minusculas / acentos / espacios / Unicode normalizado de otra forma | Comparacion ordinal-ignore-case con `string.Normalize(NormalizationForm.FormC)` y `Trim()`; el cuerpo con `LIMITECREDITO` o `limitecredito ` debe dar `400`. El serializador con `PropertyNameCaseInsensitive` acepta el de arriba; por eso D-4 lo rechaza como desconocido | D-5, M-10 |
| Clave duplicada en el cuerpo (`"Telefono":"1","LimiteCredito":2,"Telefono":"3"`) | El lector con `AllowDuplicateProperties=false` o un recorrido con `Utf8JsonReader` | D-5 |
| Campo extra en query string o cabecera | D-8 | D-8 |
| Un segundo endpoint que escribe las mismas columnas fuera de `/api/titulares` (otra ruta que hace `UPDATE` de `Telefono` con otro privilegio) | Fuera del alcance de «las rutas de TT»; es la edicion normal del maestro, que existe y es legitima (`Operativa`). La prueba R-2 asegura que no es `Esencial`. **El riesgo es el inverso:** que TT *no* sea el unico camino para escribir `TitularBloqueadoEn` (X-4) | X-4 |
| Editar el JSON y el dorado con una IA sin entender | Guarda 2.2, mensaje claro (B-5), `CODEOWNERS` | B-1..B-5 |
| Cambio de la intercalacion (de `CI_AS` a `BIN2`) | Fuera del alcance; si pasa, la comparacion de `GENERICO` en la base cambia y HTTP-09 del plan de TT lo detecta | — |
| Una columna personal en la tabla de historial no presente en el maestro | C-7 | C-7 |
| La API pierde el filtro por empresa: TT lee otra empresa | No es una prueba de arquitectura de esta lista; lo cubre HTTP-43 del plan de TT | — |

### 8.2 Falsos positivos y como se evitan

| Riesgo | Mitigacion |
|---|---|
| `comunes` incluye `CreadoPor`/`CreadoEn`/`ModificadoPor` y `TitularBloqueadoEn`, que `Empleado` **no tiene** [V: `Empleado` carece de `CreadoEn/Por`] y `TitularBloqueadoEn` aun no existe en el modelo | `comunes` se interpreta como «si existe en la tabla»; C-2 exige que las columnas de `rectificar`/`anonimizar`/`conservar` **existan**, pero no las de `nunca`. Una columna de `nunca` que no existe es un aviso, no un fallo. Para `TitularBloqueadoEn`: la prueba la espera solo cuando la migracion de F-7 exista (si existe en el modelo debe estar en `nunca`) |
| Propiedades sombra del modelo (`ValidoDesde`, `ValidoHasta`) y `rowversion` | No son texto; no obligan; y estan en `ClasificacionColumnas.json` como tecnicas |
| El patron de datos personales (3.2) marca columnas inocuas (`TelefonoCliente` de `ventas.Venta`, o `DireccionIP`) | El patron solo se aplica a las tres tablas de los maestros; el resto del esquema es TT-P3, que no es esta prueba. Una columna que casa con el patron y no es personal se declara con motivo, no se desactiva el patron |
| Orden de columnas distinto entre maquinas | Siempre se comparan conjuntos ordenados ordinalmente |
| Cambios de formato (espacios, saltos de linea) | Comparacion por arbol canonico, hash sobre texto canonico (UTF-8 sin BOM, `\n`, claves ordenadas) |
| El nombre del archivo o el JSON cambia de ubicacion al mover el proyecto | Busqueda hacia arriba de `GPOS-NG.slnx` [V patron de `Raiz()`] |
| El interceptor ve sentencias de `SET`/`SELECT` del propio motor (`SELECT @@SPID`, `sp_getapplock`, `SET LOCK_TIMEOUT`) | Se filtran por prefijo explicito de una lista corta; cualquier sentencia no reconocida **falla con mensaje**, para no pasar en vacio |
| La prueba depende de la version de EF (formato del SQL) | El analizador se prueba con 6 sentencias dadas (casos de oro propios, sin base): si EF cambia el formato, falla ese caso con un mensaje claro y no los demas |
| Dos suites completas corriendo a la vez vuelven inestable la carga (CLAUDE.md) | Las clases 1 y 2 no abren la base; 3 y 4 usan `GPOS_TEST_*` propios y se corren con `--filter` por clase |
| Un campo nuevo legitimo (p. ej. `Telefono3`) rompe cuatro pruebas a la vez | Los mensajes de las cuatro apuntan al mismo procedimiento (2.2 B-5); el cambio es un unico PR con 4 archivos |

## 9. Hallazgos de este plan sobre la lista del especialista

- **H-A1. El JSON propuesto viola E-4 / «conservarBloqueado ⊆ rectificar»** (ARQ-05 de mi plan): `TipoIdentificacion` esta en `conservarBloqueado` y en `nunca`, y no en `rectificar`. No es un error de fondo (es una columna derivada), pero la prueba necesita que el JSON lo diga (`reglas.derivadas`, 2.4). Propuesta: agregar la clave; el contenido de las listas no cambia.
- **H-A2. `nunca` no explica nada.** El criterio de la tarea («declarada no personal con motivo») no se puede satisfacer con una lista sin motivos. Se resuelve con `ClasificacionColumnas.json` (3.3), que es nuevo y no esta en la propuesta del especialista; costo: un archivo mas que firmar (D-8).
- **H-A3. `excluir` y `personaFisica` son cadenas con forma de SQL** (ya senalado como H-6). Propuesta: `excluirCodigos` y `personaFisica: {tipos: [...]}`. Si B las conserva, queda como riesgo no cubierto.
- **H-A4. El interceptor solo protege si TT no usa SQL a mano en la API.** Hay que fijarlo como regla de construccion antes de escribir TT (X-1).
- **H-A5. «Esencial» no es una clase de campo** [V]: aclarado en 2.3; pregunta 4.
- **H-A6. Fallo posible en la lista del especialista, sin consecuencia para la prueba:** el texto de su 1.5 habla de «cuatro datos» y enumera cinco para el empleado (H-5 de mi plan de TT).
- **H-A7. Aviso de seguridad menor:** `alias` incluye `Identificacion → RNC` para suplidores y clientes, pero la columna `Identificacion` del empleado se llama `Cedula`; el JSON no tiene alias para `Cedula`, asi que el DTO de empleados usara `Cedula` y el de clientes `RNC`. Esta bien, pero C-6 debe distinguir por maestro, no usar un mapa global.

### Revisión de H-A1 a H-A7 en la v2

| Hallazgo | Veredicto | Ajuste |
|---|---|---|
| H-A1 (`TipoIdentificacion` viola `conservarBloqueado ⊆ rectificar`) | **Vigente** | Sin cambio: `reglas.derivadas` sigue siendo la propuesta. La verificación no tocó esta columna |
| H-A2 (`nunca` sin motivo por columna) | **Vigente, reforzada** | Las columnas que la verificación hizo visibles (`Inhabilitado`, `FusionadoEnId`, `Prospecto`) necesitan motivo; `Inhabilitado` además **no está en el DTO del cliente** (hecho 0), de modo que C-6 y el mapa de alias nunca la ven |
| H-A3 (`excluir` y `personaFisica` como cadena SQL) | **Vigente, reforzada** | Confirmado que la constante `Cliente.CodigoContado` existe y nadie más la usa: `excluirCodigos` es comparable por reflexión (G-1) |
| H-A4 (el interceptor solo protege si TT no usa SQL a mano) | **Vigente, ajustada** | `PuenteMae` usa EF, no SQL a mano [V]; pero escribe con **otro contexto** (`u.Heredado`): el interceptor debe registrarse en los dos (§6.4). Además `GuardarClienteNgAsync` escribe el DTO completo: TT no puede rectificar a través de él sin romper S-1 |
| H-A5 («Esencial» no es clase de campo) | **Vigente** | Sin hecho nuevo; pregunta 4 abierta |
| H-A6 («cuatro datos» frente a cinco del empleado) | **Vigente** | Sin consecuencia para la prueba |
| H-A7 (alias `Identificacion→RNC` frente a `Cedula` del empleado) | **Vigente** | C-6 por maestro, no mapa global |

- **H-A8 (v2). `espejoHeredado.extra` del JSON del especialista es innecesario.** El puente nunca escribe `Telefono3`, `CorreoElectronico3` ni `IdDireccion` [V]; el JSON debe llevar `extraNoEscritas` documental y dejar que ARQ-10 compruebe por comportamiento. Pedir a B que lo firme así.
- **H-A9 (v2). Dos JSON más que firmar.** `SalidasIdentificacionTercero.json` y `ConsumidoresTerceroBloqueo.json` se suman a D-8; sin ellos, X-6 y la clase 5 no tienen contra qué comparar.

## 10. Preguntas para B y dependencias

Estado tras la v2: **CERRADA** = la contesta un hecho verificado; **PENDIENTE (propietario)** = B debe llevarla; **ABIERTA** = decide B o un agente.

1. **ABIERTA.** ¿Los verbos HTTP de `rectificar` y `suprimir` (PUT o POST)? La lista blanca de R-1 los necesita exactos.
2. **ABIERTA.** ¿B acepta cambiar a `excluirCodigos` y `personaFisica: {tipos}` (H-A3)? (= pregunta 10 de mi plan de TT.) La constante verificada la hace viable.
3. **ABIERTA.** ¿B acepta agregar `reglas.derivadas`, `soloAnonimizar`, `extraNoEscritas` y `ClasificacionColumnas.json` al JSON de `version: 1` (H-A1, H-A2, H-A8)?
4. **ABIERTA.** «Intersección vacía con campos `Esencial`» (E-5): ¿`nunca` (propuesta, 2.3) o las columnas que otras rutas `Esencial` ya escriben?
5. **ABIERTA.** Regla X-1: TT sin SQL a mano en la API. Ahora con evidencia: `PuenteMae` usa EF, así que no la viola.
6. **ABIERTA.** ¿B aprueba depender de `Microsoft.SqlServer.TransactSql.ScriptDom` o usar el analizador reducido (6.4)? Política de paquetes.
7. **PENDIENTE (propietario): P1, P2, P9.** Cambian, respectivamente: una clave del JSON (rectificar y el historial), las listas condicionales de `conservarBloqueado` (sin comprobantes) y la presencia de `espejoHeredado` o la desactivación de TT. Ningún hecho verificado las resuelve; el de P9 reduce su costo (§7.2). Pido que B me avise cuando las tenga.
8. **ABIERTA.** ¿Dónde vive la tabla de la solicitud del titular? (H-4 del plan de TT.) Sin ella `tablasAuxiliares` (6.2) queda incompleto.
9. **CERRADA (v2).** ¿`PuenteMae` expondrá su mapa de columnas? **No hace falta:** ARQ-10 descubre las columnas copiadas por comportamiento (centinelas). Sin trabajo para B.
10. **ABIERTA.** Cuando llegue ADR-161, `personaFisica` cambia de forma (D-6) y las políticas `enmascarable` de la clase 5 pasan a depender de `EsPersonaFisica`: ¿B me avisa?
11. **Nueva (v2), ABIERTA.** ¿B firma `SalidasIdentificacionTercero.json` y `ConsumidoresTerceroBloqueo.json` junto con el JSON de TT (H-A9) y el contador la política de las salidas obligatorias?
12. **Nueva (v2), ABIERTA.** El inventario no miró teléfono, correo ni dirección: ¿se amplía el inventario para que Z-1 parta de una lista completa, o la clase 5 la descubre y se firma después?
13. **Nueva (v2), ABIERTA.** X-6 detecta consumidores por texto (`archivo::método`): ¿B prefiere un metadato en los servicios (más robusto, toca código de producción) o la heurística de texto?

## 11. Orden de construccion y esfuerzo

Esfuerzo **inferido** de C, ±40 %, en dias-persona de pruebas, sin contar el codigo de produccion:

| Orden | Que | Depende de | Dias |
|---|---|---|---|
| 1 | Esquema del JSON (2.1) + dorado + `CAMBIOS.md` + guarda (2.2) y el metodo puro `Validar` | D-8 (JSON firmado, ordenado, con `reglas.derivadas`) | 0,5 |
| 2 | Intersecciones E-1..E-6 y `GENERICO` G-1..G-3 | 1 | 0,25 |
| 3 | Mutaciones en memoria M-01..M-24 (4.2) | 1 y 2 | 0,3 |
| 4 | Clase 2: lectura del modelo EF sin conexion y C-1..C-7 + `ClasificacionColumnas.json` | modelo de F-7 (`TitularBloqueadoEn`) para C-2/E-1; si falta, esa parte espera | 0,5 |
| 5 | Clase 3: rutas y DTO (R-1..R-5, D-1..D-8, F-1) | rutas de L1b construidas (desde 2026-11-16) | 0,4 |
| 6 | Clase 4: interceptor + analizador + S-1..S-8 y X-1..X-4 | servicio de TT construido; base temporal | 0,6 |
| 7 | Espejo (ARQ-09/10 por comportamiento, M-25/26/33) | [P9] | 0,5 (si hay espejo) |
| 6b | (v2) Centinelas X-5 y X-6 y sus JSON | JSON firmados (H-A9); no dependen de P9 | 0,25 |
| 6c | (v2) Clase 5: Z-1 a Z-6 y M-28 a M-30 | `SalidasIdentificacionTercero.json` firmado; base temporal para Z-1 | 0,6 |
| 8 | Comensales (ARQ-12..14, M-27) | [D-7]; entrega 3 | 0,25 |

**Total (v2): 3,4 dp (de 2,0 a 4,8 con el margen; el v1 decía 2,55) para los pasos 1-6c, mas 0,75 dp condicionales (7 y 8).** Los pasos 1 a 3 se pueden escribir **hoy** con el JSON del especialista (previa firma, D-8) y correr sin base. Los pasos 4 a 6 esperan al codigo de TT. No hace falta mas infraestructura que la existente.

**Corrida sugerida:** clases 1 y 2 con `--filter "FullyQualifiedName~CamposPersonalesTitular"`; clases 3 y 4 con `--filter "Categoria=Titulares"`; siempre junto al filtro oficial (`Transicion!=Ola5&Transicion!=Defecto`) en la maquina de B, no en OSHIN-LEGION (donde solo corren las clases 1 y 2, que no usan base).

## 12. Alternativas descartadas

| Alternativa | Motivo |
|---|---|
| Una sola clase de prueba | Mezcla pruebas sin base con pruebas con base y API; la mitad corre en OSHIN-LEGION y la otra no |
| Generar el JSON a partir de atributos `[CampoPersonal]` en las entidades | Mueve la lista a 3 archivos de dominio y quita el diff unico que el propietario revisa; el JSON es el contrato firmado |
| Verificar solo el JSON (sin modelo ni interceptor) | La lista seria verdad por decreto: no detecta una columna nueva ni un `UPDATE` de mas |
| Validar con analizador completo de T-SQL en toda prueba | Dependencia nueva para algo que EF emite con un formato muy regular; se deja como opcion (pregunta 6) |
| Detectar las rutas solo por convencion de nombre (`/api/titulares`) | Una ruta con otro prefijo escapa; el metadato y la lista blanca la atrapan |
| Mutacion con herramienta externa (Stryker.NET) | Dependencia y tiempo de corrida desproporcionados para ~30 mutaciones conocidas; la tabla 4.1 hace el mismo trabajo, dirigido |

## 13. Qué no verifiqué

- **No compile ni ejecute nada.** Ningun resultado esperado se corrio; las firmas de las pruebas son diseño.
- **Lei codigo vivo solo en parte** (`git show origin/feature/modelo-ng:...`): [V] `Terceros.cs` completo para `Cliente` y `Suplidor`; `Personas.cs` (`Empleado`); `MaeConfiguracion.cs` lineas 325-392 (mapeo de `Cliente`); `CfgConfiguracion.cs` lineas 270-300 (mapeo de `Empleado`); `PuenteMae.cs` primeras ~40 lineas; `TablasEndpoints.cs` solo las lineas que citan `/api/maestros/...`; `ClasificacionRutasLicenciaTests.cs` (hasta la linea ~140), `CambioRncEnLaApiTests.cs` y `ContratoConsultasTests.cs` (inicio), `RutasLicenciaAprobadas.json` (inicio). **No lei:** el mapeo de `Suplidor` (`MaeConfiguracion.cs` desde la linea 394; los largos de `Suplidor` son los del especialista), `MaestrosService`, el cuerpo de `PuenteMae.ClienteAsync`/`SuplidorAsync` (que columnas copia exactamente), los DTO de `/api/maestros/...`, `EmpresaNgDbContext` mas alla de su cabecera, `BaseDatosFixture`, ni la lista de privilegios.
- **No verifique que el modelo de EF se pueda leer sin abrir conexion** ni que `IDesignTimeModel`/`GetService` sea el camino adecuado en la version de EF del proyecto: lo infiero del comportamiento documentado de EF Core. Tampoco verifique la version de .NET (afecta a `AllowDuplicateProperties`).
- **No verifique** que `ASP.NET` minimal API respete una configuracion `Disallow` por ruta: lo dejo como regla D-4 y como parte de la construccion de TT. Solo comprobe que **no se usa `Disallow` hoy** en `src` (busqueda de `UnmappedMemberHandling`: unico resultado `Skip` en el lector de licencias).
- **No verifique** la existencia de `database/*.sql` como fuente de datos iniciales de G-3 en `feature/modelo-ng` (el esquema lo dan las migraciones de EF en esa rama, [V] por el comentario de `EmpresaNgDbContext`), por lo que **G-3 se leera de los sembradores de `GPOS.Migracion`, no de `database/*.sql`**: la ubicacion exacta es [I].
- **No verifique** nada del grupo de columnas del heredado (`Clientes`, `Suplidores`: `Telefono3`, `CorreoElectronico3`, `IdDireccion`): vienen del especialista.
- **No lei** los bloques UR y CS de ADR-92 completos, ni `traspasos/A/adr92-respuestas-datos` ni `-software`; el bloque TT y la precision del 2026-10-22 si.
- **No verifique** datos legales ni de la DGII (siguen siendo del especialista y de la hoja).
- Los conteos de la seccion 0 («31 casos») son una estimacion contada en este documento (clase 1: ~12; clase 2: 7; clase 3: ~13; clase 4: ~8, con solapes), no una cifra auditada.
- **(v2) De la verificación de código:** releí yo `PuenteMae.ClienteAsync`, `SuplidorAsync` y `EliminarMaestroAsync` en `2fa6843b`; los demás hechos (consumidores de `ClienteRef`, `Notas.cs:68`, `Bancos.cs:73`, `Compras.cs:444`, `MaestrosService.cs:137-210` y `:358`) son del agente de lectura y de `b4378650`, sin releer; comprobé con `git diff --name-only` que esos archivos no cambiaron hasta `2fa6843b`. No sé si el contexto heredado se puede instanciar en memoria para ARQ-10 (infiero que sí).
- **(v2) Del inventario:** búsqueda por texto, no lectura completa; faltan por leer `ReportesVentasRegistrados.cs`, `ReportesInventarioRegistrados.cs`, `Definiciones/` y el diseñador de reportes; no sé qué vistas exponen teléfono, correo o dirección (el inventario buscó identificación); no confirmé cuál definición de `rpt.ConsultaFactura` y `Formato607` está vigente (Z-1 la resuelve con `sys.columns` en una base real, sin ejecutar aún). La detección de consumidores de X-6 y de SQL de la semilla en Z-2 es por texto y no la probé.
- **(v2)** Los conteos de la §0 (39 casos: 31 del v1, 6 de la clase 5 y 2 centinelas X-5/X-6) son una estimación contada en este documento, no una cifra auditada.

### Cierre
- Estado: Completado (plan, sin ejecucion; no aplica recomendacion de QA sobre codigo todavia)
- Artefactos: `C:/Users/lfmen/source/repos/GPOS-NG-Equipos/traspasos/C/2026-10-22-plan-prueba-arquitectura-campos-personales-titular.md`
- Supuestos: el contenido de `CamposPersonalesTitular.json` es el propuesto por el especialista (1.7), no firmado (D-8); [P1], [P2], [P9] sin respuesta; los verbos HTTP, los nombres de metadato y de tipos de TT son simbolicos; todo lo marcado [I]
- Decisiones candidatas a ADR: ninguna nueva; precisan el diseño de TT (no ADR) las propuestas de 2.4, 3.3 y 6.6 (cambios al JSON del especialista) y la regla X-1 (sin SQL a mano en TT), que B decide
- Entregas a otros agentes: B (arquitecto-software/desarrollador-backend) → preguntas 1-10 de la seccion 10, en especial el cambio de forma del JSON (H-A1..H-A3), la regla X-1 y la clase de `Esencial`; especialista-pos → ordenar la lista y agregar `derivadas`/`soloAnonimizar`/`excluirCodigos` al firmar `version: 1`; arquitecto-datos → ubicacion de la tabla de solicitud y de la migracion de `TitularBloqueadoEn` (C-2/E-1)
- Proximo paso recomendado: que B lleve al propietario P1, P2 y P9 y firme la forma del JSON y los dos JSON nuevos (preguntas 2, 3 y 11); C escribe primero las clases 1 y 2 (sin base) y X-5/X-6 con el JSON firmado.
