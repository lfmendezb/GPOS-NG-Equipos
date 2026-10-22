Para: B
De: C (OSHIN-LEGION)
Fecha: 2026-10-22

# Diagnóstico de las 4 pruebas que fallan en la suite y pasan solas

Rama `c/pruebas-inestables-4`, que sale de `origin/feature/modelo-ng` @ `e3e729c1`, publicada en origin y sin PR. Tiene dos commits, uno por causa. Solo se tocaron pruebas: ninguna de las causas exige cambiar código de producción.

| Prueba | Causa | Commit |
|---|---|---|
| `CompraVariableTablaTests.C10_Las_reglas_de_CXP_leen_cxp_Aplicacion_sin_buscar_la_llave` | La consulta de la caché de planes abría el texto de los planes de **otras** bases (924/952) | `81c8cddb` |
| `BaseNoDisponibleApiTests.H11S01_solo_el_pool_agotado_pasa_a_base_no_disponible` | Otras clases llaman `SqlConnection.ClearAllPools()` en paralelo | `f14d670c` |
| `NumeracionMotorTests.CP103_La_espera_de_un_bloqueo_vence_a_los_10_segundos_con_el_error_1222` | La misma | `f14d670c` |
| `Rg14Lote2Tests.Estricto_exige_la_marca_del_sistema_y_Amplio_la_sube` | La misma | `f14d670c` |

Los antecedentes (#77 `b4105ce1`, #82 `ba9a7a29` y la rama `c/pruebas-inestables-r02-super-dl22`) atacaban el tiempo y la carga. Estas dos causas son otras y no se solapan con ellos.

## Causa A: `ClearAllPools()` de las clases en paralelo (H11S01, CP103, Estricto_exige)

**Mecanismo.** Hay 15 archivos de `GPOS.Tests` que llaman `SqlConnection.ClearAllPools()`, 38 llamadas en total. Están en Rg14*, SegundoFactor, Sellos, Dl02, `RespaldoPosteriorFork` y `CredencialesLecturaRevocacion`. La llamada vacía los grupos de **todo el proceso** mientras otras clases corren en paralelo (xUnit corre en paralelo cada clase que no tiene colección). El vaciado **sustituye** el grupo, y eso tiene dos efectos:
- una apertura que coincide con el vaciado falla al instante con «Valor de tiempo de espera caducado… obtener una conexión del grupo» (`InvalidOperationException`), aunque el grupo esté vacío;
- una conexión que estaba en uso ya no cuenta en el grupo nuevo ni vuelve a él.

`BasesTemporales.cs` ya describía este efecto. Las llamadas siguieron en esas 15 clases.

**Confirmación.** Hice una sonda temporal, que no subí: una clase que llama `ClearAllPools()` en bucle mientras corre la prueba. Sin la corrección:
- **H11S01** falla con `BaseNoDisponibleException` (interna: tiempo de espera del grupo) en la **primera** apertura, que solo repetía `SqlException`. El otro modo de fallo también quedó medido: si el vaciado llega con la primera conexión abierta o durante la espera de 2 s de la segunda, la segunda **entra** (`Assert.IsType() Failure: Value is null`).
- **CP103** falla con `Assert.Equal() Failure` en `ClientConnectionId`: la conexión física reutilizada es otra.
- **Estricto_exige** falla con el tiempo de espera del grupo dentro de `EnsureCreatedAsync` → `SqlServerDatabaseCreator.ExistsAsync`, en la línea 239. EF abre la base muchas veces mientras espera a que exista.

**Arreglo** (`f14d670c`):
- **H11S01:** el caso se repite, hasta 5 veces y con un grupo nuevo, solo en dos situaciones: si la primera apertura falla con el grupo vacío (`SqlException` o `BaseNoDisponibleException`), o si la segunda conexión entra, porque entonces el grupo ya no estaba agotado. Con el grupo de verdad agotado, las aserciones son las de antes. Un defecto real, que sale siempre igual, sigue fallando en el quinto intento.
- **CP103:** la apertura del grupo propio repite solo el `InvalidOperationException`. El caso completo (la espera de 10 s y el 1222) se repite, hasta 3 veces, solo si la conexión física reutilizada es otra. Con la misma conexión, las aserciones son las de siempre.
- **Estricto_exige:** la cadena va con `Pooling=false`. La prueba no verifica nada del grupo: el 4060 y la marca son los mismos con grupo o sin él. Además dejó de llamar `ClearAllPools()` en su `finally`, así que hay una fuente menos para las demás clases.

**Evidencia con la corrección:**
- Con la sonda: Estricto pasó 3/3 con la sonda cada 15 ms. H11S01 pasó 3/3 con la sonda cada 6 s. CP103 pasó 3/3 con la sonda cada 15 a 20 s; en una de esas corridas tardó 20 s, es decir, repitió una vez y pasó.
- Sin la sonda, con el filtro oficial, tres veces seguidas cada clase: `NumeracionMotorTests` 8/8, `BaseNoDisponibleApiTests` 7/7 y `Rg14Lote2Tests` 14/14.

**Límite que hay que conocer.** Con una sonda **más agresiva**, H11S01 corregida todavía falla: cada 2 s, o cada 300 ms. Su ventana es la espera de 2 s del grupo agotado, y un vaciado dentro de esa ventana deja entrar a la segunda conexión en los 5 intentos. La corrección supone que en la suite los vaciados son mucho menos frecuentes que uno cada pocos segundos. Ese ritmo es inferido: no lo medí en la suite.

**Causa: confirmada como mecanismo** (la sonda reproduce los mismos síntomas). Que **esta** sea la causa de los fallos de la suite es **inferido**: no tengo los mensajes de error de la corrida de B del 2026-10-21. Coincide con los síntomas que B y A anotaron antes: «grupo de conexiones» en H11S01, y CP103 fallando después del #77, que ya había quitado el problema del tiempo.

## Causa B: la caché de planes de toda la instancia (C10)

**Síntoma registrado:**
- 2026-10-17: «Database … is already open and can only have one user at a time» (924);
- 2026-10-21: «Database in transition» (952).

**Causa.** `RevisarPlanesCxpAsync` aplicaba `sys.dm_exec_sql_text` a **toda** `sys.dm_exec_query_stats` y filtraba por base después. Pasa lo siguiente:
1. `BasesTemporales.EliminarAsync` deja una base de otra clase en `SINGLE_USER` antes del `DROP`.
2. Esa base todavía tiene un plan suyo en caché.
3. La lectura del texto de ese plan falla con 924.

El 924 no estaba en la lista de errores que se repiten. La lista sí incluye el 952, pero con solo 5 intentos.

**Confirmación con una corrida:**
- Con sqlcmd: una base `GPOS_TEST_C10SONDA` en `SINGLE_USER`, retenida por otra sesión y con un plan en caché, hace fallar la consulta original con el 924 exacto. La consulta nueva no falla.
- Con la prueba compilada, bajo la misma condición: la versión anterior **falla** con `SqlException : Database 'GPOS_TEST_C10SONDA' is already open and can only have one user at a time` y la nueva **pasa** (1/1).

**Arreglo** (`81c8cddb`). Los planes salen de `sys.dm_exec_trigger_stats` filtrados por `database_id` y `object_id`. Son columnas, así que la consulta no abre ninguna base. El texto se pide por el `plan_handle` de esos planes. Las aserciones no cambian y el reintento ante 952/1205/233/109/232 se conserva.

**Evidencia:** `CompraVariableTablaTests` 8/8, tres veces seguidas, con el filtro oficial. La prueba encontró operadores en todas las corridas: si no los hubiera, la aserción `Contains` habría fallado.

**Causa: confirmada para el 924.** Para el 952 es **inferido**: es la misma lectura de otras bases durante un cambio de estado, pero no lo reproduje.

## Decisiones que se piden a B

1. **Recomendación (sin urgencia): sustituir los 38 `SqlConnection.ClearAllPools()`** de las 15 clases por `ClearPool` de las cadenas propias, como ya hace `BasesTemporales`, o reunir esas clases en una colección que no corra en paralelo. Mientras sigan ahí, cualquier prueba de la suite puede recibir al azar el tiempo de espera instantáneo del grupo. Estas tres pruebas eran las más expuestas porque dependen de la identidad o del agotamiento del grupo, o porque abren muchas veces seguidas. No lo hice porque cambia 15 clases ajenas al encargo, y algunas usan `ClearAllPools` a propósito (por ejemplo, para soltar conexiones de inicios de sesión que se borran). Esfuerzo estimado: entre 0,5 y 1 día-persona, más una suite completa.
2. No hace falta ningún cambio de producción.

## Qué no verifiqué

- **No corrí la suite completa** (regla de la PC de C). No sé si las 4 pruebas quedan en verde dentro de la suite; eso lo dirá la próxima corrida oficial de B.
- No tengo los mensajes de error de la corrida del 2026-10-21. Para H11S01, CP103 y Estricto, que la causa sea la que describo es una inferencia apoyada en la reproducción con la sonda, no en el registro de la suite.
- No medí cuántas veces se llama `ClearAllPools()` durante la suite ni cada cuánto. El margen de H11S01 depende de ese ritmo (ver «Límite que hay que conocer»).
- No reproduje el 952 de C10, solo el 924.
- No corrí las otras clases de la colección `bd-numeracion` (`NumeracionApiHttpTests`, `NumeracionPrefijosComunTests`, `NumeracionSubseriesConcurrenciaTests` y `RegistroErroresEsperadosTests`). El cambio solo toca CP103 y un método privado nuevo de `NumeracionMotorTests`.
- Instancia usada: `.\SQLEXPRESS` (SQL Server 2025 Express). No dejé bases `GPOS_TEST_*` huérfanas: lo comprobé al terminar.
