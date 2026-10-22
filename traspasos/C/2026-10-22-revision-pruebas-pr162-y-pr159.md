```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de pruebas (PR #162 blueprint de datos del ADR-161; PR #159 hoja de firma T4-03 y EF-1)
Repositorio y rama: GPOS-NG `origin/b/adr161-datos` @ c2394b85 (base master bf40ad88) y `origin/b/hoja-t4-03-y-ef` @ cef99c26 (base master bf40ad88); contraste con `origin/feature/modelo-ng` @ 2fa6843b y `origin/b/claude-md-migraciones-ef` @ 4f3b795a (#160)
Estado: Abierto
```

# Revisión de pruebas de los PR #162 y #159

**Método.** Solo lectura. Leí con `git show` el blueprint del #162 (353 líneas), los tres archivos del #159 (`ADR-007.md`, `ADR-110.md`, hoja de firma), el CLAUDE.md del #160, el plan del tramo 4 en `origin/master`, `ConvertidorPdf.cs` de `master`, `AprovisionamientoTests.cs`, `Terceros.cs` y `ConsultasVarcharTests.cs` de `modelo-ng`, mis dos documentos de casos y la revisión de la DDL de B. **No compilé ni ejecuté nada.** Los dos PR apuntan a `master` (`gh pr view`); `git diff origin/master...rama` sale vacío o ruidoso porque `master` avanzó, así que comparé contra la base de cada rama (`bf40ad88`). El #160 apunta a `feature/modelo-ng`.
**Marcas:** [V] visto en el código o documento citado; [I] inferido; [?] no comprobado.

---

## A. PR #162: blueprint de datos del ADR-161

### A.1 Resumen

El blueprint es **probable de probar en su capa de datos**: casi todo lo declarativo (tablas, CHECK, índices filtrados, FK sin cascada, siembra, relleno, orden del `Up`, `Down`) trae un nombre de objeto y un caso que lo ejerce, y B adoptó mis casos MG, ID, LP-01 a LP-03, V, U-07/09/12 y M3 (§14). Resolvió A-1, M-1 a M-4 y B-1 a B-6 de su revisión. Lo que **no** es verificable todavía es lo que el blueprint deja en reglas de servicio sin criterio medible (concurrencia 3.2.9, derivación sin destino, importación, copia entre empresas) y lo que sigue pendiente de firma (Q-TI-8 y Q-TI-9). No hay hallazgo Alto: ninguno impide construir; los Medios deben quedar resueltos o con criterio antes de que el desarrollador escriba el servicio.

| ID | Sev. | Qué |
|---|---|---|
| P162-01 | Media | Se puede **borrar** un tipo con `LetraPorOmision` si no tiene uso (3.2.7): la derivación queda sin destino; el CHECK solo cubre inhabilitar |
| P162-02 | Media | Reglas de configuración incompletas para la letra `P` y para `SoloDigitos` (3.2.3 solo cubre `R` y `C`): la derivación puede quedar sin destino válido sin que ninguna regla lo impida |
| P162-03 | Media | `CK_Cliente_TipoIdentificador` contra la importación y la edición que **limpian la identificación**: el tipo conservado da error 547 |
| P162-04 | Media | 3.2.9 (concurrencia alta/cambio de reglas) sin criterio medible y con riesgo de interbloqueo; no está en el orden único de bloqueos de CLAUDE.md |
| P162-05 | Media | La `Version` del padre protege la edición de rangos solo si el padre realmente se actualiza; reemplazar rangos con el mismo `Desde` puede chocar con la PK |
| P162-06 | Media | Q-TI-8 y Q-TI-9 pendientes, y `LetraPorOmision`/A-1/CHECK de rangos aún no firmados: PF-01 a PF-04, PF-07, BT-03 y M5-* no se pueden dar por ejecutables |
| P162-07 | Media | El 409 (Q-TI-5/M-2) no fija tope de la lista ni si la respuesta incluye la identificación; riesgo de fuga y de respuesta ilimitada |
| P162-08 | Media | CP-169 solo recorre `EmpresaDbContext` (heredado); no hay prueba equivalente para `EmpresaNgDbContext`: ADR-50 queda sin vigilancia en el modelo nuevo |
| P162-09 | Media | Copia entre empresas (Q-TI-7): sin criterio para fallo parcial entre dos bases; `LetraPorOmision` casi nunca se copia; mi PR-08 sobre «mismo dueño» es trivial por ADR-43 |
| P162-10 | Media | Reglas de servicio sin definir que condicionan pruebas: mayúsculas del `Codigo`, tipo inhabilitado asignable por la API, tipo sin identificación (Q4), Unicode fuera de 1252 (Q5), A1-08 |
| P162-11 | Baja | Verificabilidad de la migración: bitácora del relleno (JSON, repetición con `Down`+`Up`), `IDENTITY` tras la siembra, Id en nodo; pruebas nuevas sugeridas |
| P162-12 | Baja | La estimación de pruebas cubre ~40 de ~130 casos; el resto (servicio, HTTP, privilegios, bitácora) queda «aparte» sin cifra |
| P162-13 | Baja | Citas cruzadas: el supuesto 1 («no localicé EF-1») queda resuelto por el #159; el riesgo R-3 se cita a sí mismo como fuente de la firma |

### A.2 Hallazgos

**P162-01 (Media) Borrar un tipo con letra por omisión.**
3.2.7 dice que un tipo **sin uso** se borra «junto con sus rangos». `CK_TipoIdentificadorFiscal_LetraActiva` solo impide `Inhabilitado = 1` con letra; un `DELETE` de `EMPRESA`, `PERSONA_FISICA` o `PASAPORTE_OTROS` recién migrados (sin clientes) lo permite y deja la derivación sin tipo (R-2). Es contradicción interna: R-2 promete que «el motor» lo garantiza; el motor solo garantiza la mitad. LP-08 evita el error 500, pero el SUPER descubre la falla al primer alta, no al configurar.
Pruebas sugeridas:
- HTTP: `DELETE` del tipo con letra y sin uso responde 409 «reasigne la letra antes»; con la letra reasignada, 200 (nuevo, **TI-S1**).
- SQL: documentar que no hay protección de base para el `DELETE` (o agregarla); si B agrega un `FOREIGN KEY` o disparador, prueba directa.
- Mutación: quitar la comprobación hace fallar TI-S1.

**P162-02 (Media) Configuración que deja la derivación sin destino válido.**
3.2.3 exige que el tipo con `R` admita 9 y el de `C` admita 11. No dice qué debe cumplir el de `P`, que recibe **todo** valor no vacío que no sea solo dígitos de 9 u 11: es decir, textos con letras de cualquier largo de 5 a 20, y solo dígitos de otros largos. Con `SoloDigitos = 1` en el tipo `P`, `'AB12345'` se deriva a `P`, el tipo lo rechaza por `SoloDigitos` y el alta da 422. Igual para `R` y `C` con `SoloDigitos = 0` (admiten, no dañan). Además, el rango del tipo `P` puede excluir un largo (por ejemplo 5-8), y `'AB1234567890'` quedaría sin destino. Ninguna de esas combinaciones se rechaza al configurar.
Pruebas sugeridas (extienden LP-07):
- HTTP: asignar `P` a un tipo con `SoloDigitos = 1` o con rangos que no cubran 5-20 (salvo 9 y 11 de solo dígitos): 409 al configurar (**TI-S2a**).
- HTTP: quitar a `R` el rango 9 o poner `SoloDigitos = 0` no es problema; poner a `R`/`C` un rango que excluye 9/11 sí: 409 (LP-07 ya lo prevé para `R`/`C`).
- TX: por cada combinación de configuración aceptada, derivar 9 dígitos, 11 dígitos, `'AB1234567'`, `'1234567890'` y `'ABCDE'` y comprobar que **ninguna** produce 422 (propiedad: «lo derivado siempre pasa su propia validación»; **TI-S2b**, repetible con configuraciones generadas).

**P162-03 (Media) CHECK de cliente/suplidor contra la importación y la edición.**
`CK_Cliente_TipoIdentificador` exige `TipoIdentificadorId IS NULL OR Identificacion IS NOT NULL`. 7.5 dice que el `UPDATE` de la importación **conserva** el tipo guardado si sigue siendo válido para la identificación nueva; si la plantilla trae la identificación vacía (o la edición la borra), el tipo conservado deja la fila con tipo e identificación nula: error 547 en el lote. VL-06 (mi pregunta 4) sigue sin respuesta en el servicio.
Pruebas sugeridas:
- TX: importar una fila de un cliente existente con tipo y con identificación vacía: el tipo pasa a nulo (o la fila se rechaza con error de fila), nunca 547 (**TI-I1**).
- HTTP: `PUT` que borra la identificación de un cliente con tipo: 200 con tipo nulo o 422, y la regla documentada (**TI-I2**; resuelve VL-06).
- Lo mismo para suplidor.

**P162-04 (Media) Concurrencia alta ↔ cambio de reglas (3.2.9).**
La regla está marcada [I] y su criterio es «no entra un cliente validado con la regla vieja mientras se guarda la nueva», sin forma de medirlo. Además: el alta mantiene una fila del tipo bajo `REPEATABLEREAD` (lock `S` retenido) y luego inserta en `cat.Cliente`; el cambio del SUPER toma `UPDLOCK` en el tipo y recorre `IX_Cliente_TipoIdentificador` con locks que, si el nivel de aislamiento retiene lecturas, bloquean la inserción del alta, mientras su `UPDATE` del padre espera el `S` del alta: ciclo posible (1205) [I, no ejecutado]. CLAUDE.md fija un **orden único de bloqueos** obligatorio en código nuevo (jornada → almacenes → documentos → configuración → series → NCF → MovimientoCaja → inv_Articulos); el blueprint no ubica el lock del tipo ni dice si el alta de cliente lo toma antes o después de la numeración del maestro (Q-TI-... de maestros por secuencia).
Pruebas sugeridas (con barreras deterministas, no con `Sleep`):
- **TI-C1**: hilo A abre el alta y lee el tipo (`S` retenido); hilo B intenta cambiar el rango. Esperado: B espera y, al terminar A, rechaza con 409 si A creó un incumplidor; **nunca** un 500 por 1205 sin traducir.
- **TI-C2**: orden inverso (B bloquea primero); A espera y valida con la regla nueva (422).
- **TI-C3**: 20 altas simultáneas de clientes con el tipo mientras el SUPER guarda 5 veces: cero interbloqueos sin reintento y cero filas incumplidoras al final (consulta de incumplidores).
- Documentar en el blueprint dónde cae el lock del tipo en el orden único; si cae fuera, una prueba ARQ del orden.

**P162-05 (Media) `Version` del padre y reemplazo de rangos.**
2.2 dice que el servicio reemplaza los rangos y «marca el padre como modificado» para que su `Version` cambie. En EF, marcar el estado `Modified` sin cambiar valores puede no emitir `UPDATE` (según cómo se marque) y entonces `rowversion` no cambia; además, borrar e insertar filas hijas con la **misma** PK `(TipoIdentificadorId, Desde)` en un solo `SaveChanges` (por ejemplo, cambiar solo `Hasta` de 5-20 a 5-15) puede fallar por clave duplicada o por seguimiento de dos instancias con la misma llave [I].
Pruebas sugeridas:
- HTTP: dos clientes cargan el tipo; A cambia solo un rango; B envía con la `Version` anterior: 409 `REGISTRO_MODIFICADO` (**TI-V1**; si no cambia la `Version`, B pasaría).
- SQL/TX: editar rangos conservando un `Desde` (5-20 → 5-15) y reordenando (9-9, 11-11 → 11-11, 9-9): OK, sin violar la PK (**TI-V2**).
- TX: reemplazo que falla a la mitad (rango inválido en la segunda fila): no queda ningún rango parcial (atomicidad).

**P162-06 (Media) Pendientes de firma que bloquean casos.**
Q-TI-8 (M-2) y Q-TI-9 (M-5) siguen pendientes (§15). Mientras tanto no son ejecutables: PF-01 a PF-04 (con (a)) o PF-07 y BT-03 (con (b)); M5-01 a M5-03. Además, «puede incorporar como precisiones de TI-05 y TI-06: `LetraPorOmision`, A-1 y el CHECK de rangos» (§15): esos casos A1-*, LP-*, A1-09/10 siguen siendo [R] hasta la firma del ADR-161 completo. Las pruebas pueden escribirse, pero **no deben integrarse como obligatorias** (marcar con un rasgo `Pendiente=Q-TI-8` para el filtro de la suite).
Sugerencia: escribir PF-01/PF-04/PF-05/PF-08/PF-09 hoy (no dependen de Q-TI-8 salvo el campo `EsPersonaFisica`); dejar PF-02 y PF-03 de `EsPersonaFisica` condicionados.

**P162-07 (Media) Contenido y tamaño del 409.**
4 lista `SELECT TOP (@n) Id, Identificacion` para el 409, pero `@n` no tiene valor; no se dice si la respuesta incluye la identificación del cliente (dato personal, ADR-92) o solo el código/Id, ni si indica «y N más». BT-06 prohíbe la identificación en la **bitácora**, no en la respuesta; PF-01 espera «código/Id».
Pruebas sugeridas:
- HTTP: 409 con 5 incumplidores: el cuerpo trae `codigo` y `id`, **no** la identificación (**TI-4a**), salvo decisión contraria firmada.
- HTTP: 1 200 incumplidores: la lista se corta en el tope y trae el total real (`total`, `truncada = true`) (**TI-4b**); el tiempo de respuesta con 100 000 clientes del tipo queda bajo un tope razonable (PF-11, *seek*).
- BT-06 se mantiene: la línea de bitácora tiene solo la cantidad.

**P162-08 (Media) Vigilancia ADR-50 del modelo nuevo.**
El blueprint reconoce que CP-169 recorre `EmpresaDbContext` (heredado, rasgo `Esquema=BP2`) [V: `ConsultasVarcharTests.cs:24-33` en `modelo-ng`]. En `tests/GPOS.Tests/ModeloNg` no encontré ninguna prueba equivalente para `EmpresaNgDbContext` (`git grep AreUnicode|IsUnicode` solo da parámetros `NVarChar` de pruebas; búsqueda acotada a esa carpeta [?]). Mi V-01 decía «CP-169 existente»: **es incorrecto para las tablas nuevas**; el blueprint (V-01/V-02) lo corrige para dos tablas, pero la brecha es general: todo el modelo NG (cientos de columnas) no tiene vigilancia contra `nvarchar` accidentales.
Pruebas sugeridas:
- **TI-V0** (general): recorrer `EmpresaNgDbContext.Model` y comparar tipo Unicode y largo de cada propiedad de texto contra `sys.columns` de la base creada con las migraciones. Cubre ADR-161 sin pruebas específicas.
- V-02 de mi lista queda como caso concreto (las dos tablas nuevas no tienen `nvarchar`), y V-03 (parámetros Dapper del 409 y de `Codigo` como `AnsiString`) se mantiene.
- Pedir al desarrollador que, si TI-V0 sale en rojo por tablas previas, se abra aparte; no bloquea este PR.

**P162-09 (Media) Copia entre empresas.**
6 define: una transacción en el destino, una línea de bitácora en cada base, sin transacción distribuida; `LetraPorOmision` se copia «solo si en el destino ninguna fila tiene esa letra». Dos consecuencias para las pruebas:
- Casi toda empresa destino ya tiene las tres letras (las siembra la migración); la copia **no** copia letras en la práctica. Mi LP-09 («mismas letras») queda mal: debe leerse «no sobrescribe, informa y respeta la unicidad de letra» (**LP-09′**).
- Fallo entre las dos bases: si el destino falla, ¿hay línea en el origen? Si el destino confirma y la bitácora del origen falla, ¿se deshace el destino? No hay criterio.
- Mi PR-08 («solo del mismo dueño») es trivial: ADR-43 da un único dueño por instalación; el caso real es «origen y destino son empresas de la instalación, existentes y activas, y el usuario es SUPER» y la identidad del destino se toma del servidor (nunca del cuerpo).
Pruebas sugeridas: **TI-X1** destino con un código ya existente: no se sobrescribe y el informe lo lista; **TI-X2** destino que falla a la mitad (rango inválido en el tercer tipo): destino sin cambios, origen con una línea «fallida» o sin línea, según se fije; **TI-X3** copia con `Id` distintos en destino y los rangos enlazados al `Id` del destino; **TI-X4** copia a una empresa inexistente/inhabilitada: 404/409.

**P162-10 (Media) Reglas de servicio sin definir que condicionan pruebas.**
Preguntas de mi documento que el blueprint **no** contesta (las que sí contesta, abajo, en A.3):
1. **Mayúsculas del `Codigo`** (U-02, V-05): el CHECK rechaza minúsculas en la base; no dice si el servicio pone en mayúsculas (200) o rechaza (400). Los casos U-02 y V-05 se escriben según lo que se decida; la importación (`COLLATE DATABASE_DEFAULT`, CI) sí resuelve `'empresa'` a `EMPRESA`, lo que podría contradecir un 400 de la API.
2. **Tipo inhabilitado asignable por la API**: la FK no mira `Inhabilitado` (§6, U-16). Falta decir que el servicio rechaza **asignar** un tipo inhabilitado en un alta nueva (pero no al editar otros campos de un cliente que ya lo tiene). Prueba **TI-A1**: `POST` con el `Id` de un tipo inhabilitado: 422; `PUT` de otro campo del cliente que ya tiene ese tipo: 200.
3. **Pedido con tipo y sin identificación** (VL-06 / Q4): sin respuesta (ver P162-03).
4. **Unicode fuera de 1252** (V-07 / Q5): sin respuesta.
5. **A1-08** (`PASAPORTE_OTROS` con 9 dígitos puros, letra `R`): sin respuesta explícita; TI-05 «no se exige que coincidan» implica aceptarlo. Confirmar para fijar el resultado esperado.
6. **Privilegios de lectura del catálogo y motivo del SUPER** (PR-05, PR-07): sin respuesta; §9 solo dice «rutas `/api/super/...`».
7. **Normalización de la identificación**: `Rnc.Normalizar` quita guiones y espacios [V: `Empresa.cs:164-169` según el blueprint]; en un pasaporte, quitar el guion cambia el dato guardado (`'AB-12345'` → `'AB12345'`). Probar VL-05 también con `PASAPORTE_OTROS` y decidir si el tipo `SoloDigitos = 0` conserva guiones.

**P162-11 (Baja) Verificabilidad de la migración: pruebas nuevas sugeridas.**
- **TI-M1**: tras el `Up` en base nueva, el primer tipo que crea el SUPER tiene `Id = 5` (con `IDENTITY_INSERT` de los Id 1 a 4, la semilla de identidad pasa a 4) [I, comportamiento del motor; la prueba lo confirma]. Sin esto, el supuesto de §6 («los tipos nuevos nacen con Id 5 en adelante») es solo texto.
- **TI-M2**: `Detalle` de la línea de bitácora del relleno es JSON válido (`ISJSON = 1`) con `clientes` y `suplidores` correctos, y solo se escribe si hubo filas (MG-01 vs MG-04).
- **TI-M3**: `Down` + `Up` sobre una base con clientes: la bitácora tiene **dos** líneas de relleno (esperado, `Down` no la toca) y el tipo de cada cliente queda igual que antes del `Down` salvo las correcciones manuales (que se pierden, dicho en 7.4).
- **TI-M4**: relleno con `TipoIdentificacion` nulo o inesperado y `Identificacion` no nula: la fila queda sin tipo, el CHECK la admite (`IS NULL`), no hay 547.
- **TI-M5**: la migración corre en una base con 30 000 clientes y suplidores sintéticos sin superar un tope de tiempo acordado y sin escalado que bloquee lecturas durante la prueba (R-4 hoy es «segundos [I]»; dar una cifra medida o quitar la promesa).
- **TI-M6** (nodo): dos bases creadas con la misma migración tienen los mismos `Id` y `Codigo` en los cuatro tipos (M4-02 parcial; la bajada por `CHANGE_TRACKING` no existe y M4-02/04 siguen diferidos).
- **TI-M7** (R-4/T-bloqueo): el guion idempotente aplicado a una base **a medias** (columna creada, relleno hecho) no repite la bitácora en exceso: documentar el comportamiento.

**P162-12 (Baja) Estimación de pruebas.**
§13 reserva 1 a 1,5 dp para MG, ID, LP-01 a LP-03, V, U-07/09/12, M3 (~40 casos). Quedan fuera ~90 casos de servicio, HTTP, privilegios, bitácora, validación y fiscales (A1, LP-04+, PF, U-01+, VL, PR, BT, FI), «aparte» sin cifra. Mi estimado total sigue en 0,35 a 0,5 sp (1,75 a 2,5 dp), más las pruebas nuevas de arriba (~0,3 a 0,5 dp). Pedir que el plan de construcción reserve esa parte explícitamente, para que no se recorte al final.

**P162-13 (Baja) Citas.**
El supuesto 1 («no localicé EF-1») queda resuelto si se une el #159 (hoja con EF-1 firmada el 2026-10-22). El riesgo R-3 cita como «fuente» el propio documento y su apartado «Decisiones pendientes»: referencia circular; apuntar a la hoja de firma cuando exista. El orden de unión importa: las marcas de `Adr161TipoIdentificadorFiscal` y de `Ola5VistasImp` (T4-10) deben regenerarse según quien se una después (ver P159-09).

### A.3 Contradicciones internas y con la revisión de la DDL

| # | Dónde | Contradicción o brecha |
|---|---|---|
| 1 | 3.1 `LetraActiva` y R-2 contra 3.2.7 | El motor impide inhabilitar un tipo con letra, pero 3.2.7 permite borrarlo si no tiene uso (P162-01) |
| 2 | 3.2.3 contra 3.2.4 | `R` y `C` exigen cobertura de 9/11; `P` no exige nada, aunque 3.2.4 le manda todo lo no numérico (P162-02) |
| 3 | 3.1 `CK_Cliente_TipoIdentificador` contra 7.5 (conservar tipo en la importación) | Con identificación vaciada, el tipo conservado da 547 (P162-03) |
| 4 | 3.2.9 contra el orden único de bloqueos de CLAUDE.md | El lock del tipo no está ubicado en el orden; riesgo de ciclo (P162-04) |
| 5 | Revisión de la DDL, M-1: «el servicio rechaza inhabilitar un tipo con letra» contra el blueprint (lo delega al CHECK) | Si el servicio no se anticipa, el error 547 sale como 500; LP-05 espera 409 con mensaje. Fijar que el servicio revisa antes y traduce el 547 (**TI-D1b**: forzar la carrera: el servicio revisa, otro hilo cambia la letra, el CHECK dispara; la API responde 409, no 500) |
| 6 | 3.2.4 contra 7.3 | La derivación en línea usa `LetraPorOmision`; el relleno de la migración usa `Codigo`. Es deliberado (7.3 lo explica), pero la prueba MG-01 a MG-03 debe ejecutarse con una base cuyos `LetraPorOmision` hayan sido tocados **antes** del relleno (imposible hoy, porque el relleno corre al crear la tabla) [I]: no hay caso que distinga ambas rutas; no es defecto |
| 7 | 6 contra 3.2.7/U-05 | «Un `Codigo` inhabilitado no se reutiliza» (U-05) solo vale mientras no se borre: un tipo inhabilitado y sin uso se puede borrar y su código reutilizar. Decidir si U-05 sigue y cómo |
| 8 | Revisión de la DDL, M-4 («mismo mecanismo de bajada de los demás catálogos») contra §6 (la bajada no existe, [V]) | Consistente (el blueprint lo reconoce); queda M4-02 como diferido |
| 9 | 3.1 contra 14 | 14 cita `TI-D1` y `TI-D2` como pruebas nuevas; con P162-01/02 conviene `TI-D3` (borrado) y `TI-D4` (P/SoloDigitos) |

Coherencias confirmadas con la revisión de la DDL: A-1 (a) y (b), M-1 (columna, CHECK, índice único filtrado), M-3 (índices y CHECK), B-1 (forma de `CatalogoSimple`), B-2 (PK, FK sin cascada), B-3 (`EXEC(N'...')`, `Codigo` en lugar de Id literal), B-4 (historial sin apagar versionado), B-5 (CHECK de `Codigo`, `varchar`), B-6 (sin `GRANT`).

### A.4 Qué casos de mis ~130 siguen siendo válidos y cuáles cambian

Cuentas por fila de mi documento (conteo mío, ±3).

| Grupo | Situación |
|---|---|
| **A1-01 a A1-07, A1-11 a A1-14** | Válidos tal cual (el blueprint adopta A-1 (a) y la mutación). |
| **A1-08** | Sigue abierto (P162-10-5). |
| **A1-09, A1-10** | Válidos; el CHECK es `Desde BETWEEN 5 AND 20 AND Hasta BETWEEN Desde AND 20`. |
| **LP-01 a LP-03** | Válidos (siembra, CHECK, índice único filtrado). |
| **LP-04, LP-06** | Válidos. |
| **LP-05** | Cambia: dos capas (servicio 409 + CHECK). Añadir TI-D1b (P162 A.3-5). |
| **LP-07** | Se amplía (P162-02: `P` y `SoloDigitos`). |
| **LP-08** | Válido; el blueprint fija 422 con mensaje de configuración. |
| **LP-09** | Cambia a LP-09′ (P162-09). |
| **PF-05, PF-06, PF-08, PF-09, PF-10, PF-11** | Válidos. |
| **PF-01 a PF-04, PF-07** | Condicionados a Q-TI-8 (P162-06); PF-01 además al contenido del 409 (P162-07). |
| **MG-01 a MG-14** | Válidos y adoptados (§14). MG-14 ya tiene precedente: `El_script_embebido_es_el_que_genera_EF` (ver P159-09). |
| **ID-01 a ID-06** | Válidos y adoptados. |
| **V-01** | Cambia: no es «CP-169 existente» (P162-08). **V-02, V-03, V-04, V-06** válidos. **V-05** depende de P162-10-1. **V-07** abierto (P162-10-4). |
| **U-01, U-03, U-06 a U-10, U-12, U-14 a U-17** | Válidos. **U-02** depende de P162-10-1. **U-04**: contestado («regla del servicio, sin disparador»): queda como documentación, sin prueba de rechazo. **U-05** ver A.3-7. **U-11**: contestado (se borra sin uso), pero ver P162-01 para el tipo con letra. **U-13** válido. |
| **VL-01 a VL-05, VL-07 a VL-13** | Válidos. **VL-06** abierto (P162-03). |
| **PR-01 a PR-04, PR-06, PR-09, PR-10** | Válidos. **PR-05, PR-07** abiertos. **PR-08** se reescribe (P162-09). |
| **BT-01 a BT-07** | Contestados por el blueprint (`audit.Bitacora`, `Entidad = Codigo`, `Detalle` con antes y después, 409 sin línea, sin identificación, una línea por base). **BT-03** condicionado a Q-TI-8 (b). |
| **M3-01, M3-02, B1-01** | Válidos. |
| **M4-01** | Válido y adoptado. **M4-02, M4-04** siguen diferidos; M4-02 se cubre en parte con TI-M1 y TI-M6. **M4-03** ver LP-09′. |
| **M5-01 a M5-03** | Esperan Q-TI-9. |
| **FI-01 a FI-09** | Válidos como no regresión (el blueprint confirma «Fiscal: sin cambio»). FI-03/FI-07 siguen en la pregunta 9 (R-8). |

**Pruebas nuevas que hacen falta** (resumen): TI-D1b, TI-D3, TI-D4 (A.3), TI-S1, TI-S2a/b (P162-01/02), TI-I1, TI-I2 (P162-03), TI-C1 a TI-C3 (P162-04), TI-V0, TI-V1, TI-V2 (P162-05/08), TI-4a, TI-4b (P162-07), TI-X1 a TI-X4 (P162-09), TI-A1 (P162-10), TI-M1 a TI-M7 (P162-11). En total unas 28 pruebas nuevas (~0,25 a 0,35 sp).

### A.5 Qué no verifiqué (#162)

- No compilé ni ejecuté nada: no sé si el motor reproduce lo que digo sobre `IDENTITY_INSERT`, bloqueos o `rowversion` [I].
- Verifiqué en `modelo-ng` solo `TiposIdentificacion.TipoDe` (`Terceros.cs:116-122`, coincide con el blueprint) y el comentario de CP-169 (`ConsultasVarcharTests.cs`). No releí `MaestrosService`, `ImportacionMaestros`, `ComandosImportacion`, `MaeConfiguracion` ni `CfgConfiguracion`: las líneas que el blueprint cita de ellos las tomo como dichas por B.
- No verifiqué el esquema real de `audit.Bitacora` (columnas, nulabilidad, posible `CHECK ISJSON`); P162-11 depende de ello.
- Mi afirmación de que no hay vigilancia ADR-50 para el modelo NG sale de un `git grep` limitado a `tests/GPOS.Tests/ModeloNg` [?]; puede existir en otra carpeta.
- No medí tiempos (relleno de 30 000 filas) ni el tamaño del índice.
- La posibilidad de interbloqueo (P162-04) es razonamiento sobre aislamiento y bloqueos, sin plan de ejecución real.

---

## B. PR #159: hoja de firma de T4-03 (D-T403-1, D-T403-2) y EF-1

### B.1 Resumen

El PR solo contiene documentos (hoja firmada, nota en ADR-7, precisión en ADR-110 cl. 7): no hay código que probar, pero las decisiones fijan **condiciones de aceptación** que hoy son enunciados, no pruebas. El hallazgo mayor es que la coincidencia del alto del rollo (D-T403-2) no tiene criterio numérico: si la prueba no se define antes, la decisión «sujeta a la prueba» no se puede cerrar. Sobre EF-1, la protección ya existente es buena para el guion acumulado (`AprovisionamientoTests.El_script_embebido_es_el_que_genera_EF`), pero hay huecos de orden de marcas, instantánea y idempotencia de SQL propio.

| ID | Sev. | Qué |
|---|---|---|
| P159-01 | Alta | D-T403-2 «sujeto a la prueba del rollo»: sin criterio medible de coincidencia (tolerancia, medios, tipos, papeles) |
| P159-02 | Media | JavaScript apagado: no se asigna a T4-03a ni a T4-03b, y la CSP (que podría reforzarlo) está en 3b (recortable); la prueba debe medir «no se ejecuta», no «evaluate falla» |
| P159-03 | Media | Las tres pruebas del plan para T4-03 no bastan como condición de unir T4-02: faltan esquemas (`file:`, `blob:`, redirecciones), CSS y registro de bloqueos |
| P159-04 | Media | El sandbox (ADR-110 cl. 7 / A-6) y el origen del navegador (Q-1, Q-2 de mis casos) no aparecen en T4-03a ni en T4-03b |
| P159-05 | Media | El perfil de Chromium tiene tres rutas distintas entre hoja, plan y vector ADR-77 v2; el código actual crea perfiles en `Temp` y no los borra |
| P159-06 | Media | Logo e imágenes «revalidados al renderizar»: sin pruebas (formatos, magia, tamaño, TOCTOU, dimensiones) |
| P159-07 | Media | Mis casos de laboratorio CH-03, CH-07, CH-08, CH-09, CH-10 y CH-13 cambian de resultado esperado con D-T403-1 y D-T403-2 |
| P159-08 | Baja | Desfases entre hoja y plan: 2 dp contra 1,6 + 1,0 dp; línea 389 del plan («T4-03 no lo apaga»); ADR-109 cl. 12 listado y no editado |
| P159-09 | Media | EF-1: hay prueba del guion, pero faltan orden de marcas, instantánea al día, idempotencia del SQL propio y equivalencia `Migrate()` ↔ guion; CP-169 no cubre el modelo nuevo |

### B.2 Hallazgos T4-03

**P159-01 (Alta) Criterio de coincidencia del rollo.**
D-T403-2 se firma «sujeto a una prueba de que la medición del alto del rollo por `DOM.getBoxModel` coincide con los dorados de T4-01; si no coincide, se vuelve al propietario». El código actual mide con `Math.ceil(document.body.getBoundingClientRect().height)` y suma 10 mm, mínimo 40 mm (`ConvertidorPdf.cs:37-42` en `master` [V]). Sin definir qué es «coincide», la decisión puede quedar abierta o discutirse. Puntos que la prueba debe fijar antes de correr:
- **Tolerancia:** propuesta de C [I, B decide]: igual alto en milímetros del `Height` que se pasa a `PdfDataAsync` (formato `0.##mm`), diferencia 0 en el caso de igualdad de caja; si hay diferencia, ≤ 1 px (0,26 mm) y mismo número de páginas.
- **Equivalencia teórica:** `getBoundingClientRect().height` de `body` = alto de la caja de borde de `body`, que es lo que `DOM.getBoxModel` devuelve (`border`); el margen de `body` y el colapso de márgenes con `html` son la diferencia posible. La prueba debe cubrir plantillas con `margin` en `body` y con `margin-top` colapsado.
- **Medio:** `getBoxModel` mide con la emulación de medios por omisión (pantalla); el PDF se imprime con medios `print`. Una plantilla con `@media print` distinto cambia el alto. Probar con y sin `@media print` y con `Emulation.setEmulatedMedia('print')`.
- **Corpus:** los trece tipos de `FabricaModelo` (80 mm continuo) y variantes: 1 línea, 40 líneas, 300 líneas, nombre de artículo largo (salto de línea), logo grande en `data:` y sin logo, fuentes del sistema; Carta y media carta (no rollo) para comprobar que no se mide.
- **Espera de carga:** con JS apagado no hay `window.onload` útil; imágenes `data:` y fuentes deben estar listas antes de medir (esperar `Page.loadEventFired` o `document.fonts.ready` no es posible sin JS: definir la espera).
Pruebas: `RolloSinJavaScriptTests.El_alto_por_getBoxModel_iguala_al_dorado_en_los_13_tipos` (parametrizada por tipo y número de líneas, con tolerancia declarada), `...con_margen_en_body`, `...con_media_print`, `...fallo_de_getBoxModel_devuelve_error_no_alto_cero` (nodo ausente: 503/error claro, no una página de 40 mm). Resultado distinto del dorado ⇒ vuelve al propietario, como dice la hoja, pero con el número en la mano.

**P159-02 (Media) Dónde se aplica «sin JavaScript».**
La hoja define T4-03a (solo `data:`/`about:blank`, argumentos sin red, perfil, `Pipe = true`, imágenes revalidadas) y T4-03b (Job Object, CSP, comprobación de la regla del cortafuegos, ruta del navegador). D-T403-2 apaga JavaScript en Razor pero **no dice en cuál de las dos**. La CSP, que sí bloquea `<script>` aunque la bandera falle, queda en 3b, «recortable». Si 3b se recorta y la bandera de JavaScript no se asigna a 3a, T4-02 se une con JavaScript activo en Razor.
Pruebas (condición de unir T4-02, no de 3b):
- `JavaScriptApagadoTests.Un_script_en_linea_no_se_ejecuta`: la plantilla pone un marcador en el DOM desde `<script>`; el DOM medido no lo tiene. **Medir esto, no que `EvaluateExpressionAsync` falle**: con JavaScript desactivado en la página, la evaluación disparada por el arnés (CDP) sigue funcionando [I]; el reflejo es distinto.
- `... Un_controlador_onerror_onload_no_se_ejecuta`, `... Un_enlace_javascript_no_se_ejecuta`, `... meta_refresh_no_navega`, `... SVG_con_script_no_se_ejecuta`.
- `... SetContent_funciona_con_JavaScript_apagado`: Puppeteer inserta el HTML con una evaluación; verificar que la carga de la plantilla sigue funcionando [I, riesgo de regresión].
- Mutación: quitar la bandera ⇒ falla la primera; quitar la CSP no debe hacer fallar la primera (defensa en profundidad separada).

**P159-03 (Media) Pruebas de T4-03a como condición de unir T4-02.**
El plan lista tres pruebas (`Una_imagen_http_en_un_formato_no_sale_a_la_red`, `Los_argumentos_nunca_desactivan_el_sandbox`, `El_navegador_corre_en_un_Job_Object`); la última pasa a 3b. Para que T4-03a sea condición real hacen falta, como mínimo (todas con servidor de escucha local que cuenta conexiones, una por esquema):
- Esquemas bloqueados: `http:`, `https:`, `ftp:`, `ws:`, `file:///` (lectura de archivos locales por `<img>`, `<link>`, `<iframe>`), `blob:`, `filesystem:`, `chrome://`, `view-source:`. Esperado: abortados y registrados; el PDF no contiene contenido del archivo.
- Vías de CSS y HTML: `<link rel=stylesheet>`, `@import`, `url()` en CSS, `@font-face`, `srcset`, `<object>`, `<embed>`, `<iframe src>`, `<base href>`, `<form action>`, `<video poster>`, `<link rel=preconnect|dns-prefetch>` (no son peticiones interceptables: ver argumentos de Chromium y cortafuegos; la prueba lo documenta).
- Redirecciones: un `data:` que apunta a `http:` y un `about:blank` que abre una ventana.
- `data:` permitidos: una imagen PNG/JPEG de varios cientos de KB y una fuente `data:` siguen funcionando (no sobrebloquear).
- Registro de bloqueos: una línea por intento con el esquema y el host, **sin** la ruta ni la cadena de consulta (pueden traer credenciales); con tope por render (una plantilla con 10 000 `<img>` no inunda el registro ni la memoria). Prueba de redacción y de tope.
- Intercepción en todos los objetivos: subtramas (iframe) y, si existieran, trabajadores; la intercepción debe estar habilitada antes de la primera navegación.
- `Pipe = true`: sin puerto de depuración (`Get-NetTCPConnection` del proceso del navegador sin escuchas) y los argumentos son una lista permitida (no solo «no contiene `--no-sandbox`»).
- Puerta de unión: definir qué pruebas son la **condición** de T4-02 (propuesta: todas las anteriores salvo Job Object, CSP y regla del cortafuegos), y un chequeo en el PR de T4-02 que falle si faltan.

**P159-04 (Media) Sandbox y navegador.**
ADR-110 cl. 7 (A-6) dice que el sandbox queda activo y que «la prueba de instalación lo comprueba con la cuenta del servicio». La hoja no menciona sandbox, y el plan decía «nunca `--no-sandbox`». R-T4-07 reconoce que el sandbox puede no arrancar con la cuenta virtual. Mis preguntas Q-1 (origen del Chromium: Edge/Chrome instalado o descargado) y Q-2 (¿se acepta `--no-sandbox` si falla?) siguen sin respuesta. D-T403-1 recorta «ruta del navegador limitada» a 3b.
Pruebas: `ChromiumAisladoTests.Los_argumentos_nunca_desactivan_el_sandbox` se mantiene en 3a (no 3b); `...El_navegador_arranca_con_sandbox_bajo_la_cuenta_del_servicio` es laboratorio (CH-04); si falla, no se baja a `--no-sandbox` sin firma (Q-2). Con 3b: `...La_ruta_del_navegador_viene_de_una_lista_permitida` (una `Impresion:Navegador` fuera de la lista se rechaza; hoy `RutasConocidas` y la configurada tienen prioridad, `ConvertidorPdf.cs`).

**P159-05 (Media) Ruta del perfil de Chromium.**
Tres versiones: hoja `%ProgramData%\GPOS NG\Reportes\render`; plan T4-03 `%ProgramData%\GPOS NG\Reportes\temp`; vector `adr077-carpetas.v2.json`: subcarpeta `Render\{INST}\{EMP}` «render de P7C, incluye su TEMP» [V]. El vector es el contrato que R3 (`icacls`) y la comprobación previa del MSI (código 1603 `ESCRITOR_NO_PERMITIDO`) verifican; una carpeta fuera de ese vector con escritor propio puede fallar R3 o no estar protegida. El código actual crea el perfil en `Path.GetTempPath()\gpos-pdf-navegador\{GUID}` por arranque y no lo borra [V, `ConvertidorPdf.cs`].
Pruebas: ARQ: la ruta del perfil sale de una única constante y coincide con el vector v2; SQL/archivos: tras 20 renders y reinicio del navegador el directorio tiene como máximo un perfil; `icacls` de la carpeta del perfil = solo la cuenta del servicio, SYSTEM y Administradores (CH-03); aislamiento entre empresas: dos renders de empresas distintas no comparten archivos (la ruta del vector lleva `{EMP}`; la hoja no).

**P159-06 (Media) Logo e imágenes revalidados al renderizar.**
T4-03a dice que el logo y las imágenes se revalidan al renderizar; ADR-110 cl. 7 los limita a PNG, JPEG, GIF y WebP, validados al guardar y al renderizar, sin SVG del usuario. Pruebas:
- `ImagenesRenderTests.Un_SVG_como_logo_se_rechaza`; `...Un_archivo_con_extension_png_pero_otros_bytes_se_rechaza` (firma/magia, no extensión).
- Tamaño en bytes y dimensiones máximas (bomba de descompresión: PNG de 20 000 × 20 000 comprimible a pocos KB), con el tope de memoria del render.
- TOCTOU: el logo válido al guardar y sustituido en disco antes del render se revalida (cambiar bytes entre medio ⇒ rechazo).
- Conversión a `data:` sin pasar por URL: una imagen con `file:`/`http:` en la plantilla no se resuelve; el logo de la empresa siempre sale por `data:`.
- Corpus real: los 13 tipos con su logo; un logo corrupto produce un documento sin logo y un aviso, no un 500 (decidir).

**P159-07 (Media) Efecto en mis casos de laboratorio.**
| Caso | Cambio |
|---|---|
| **CH-03** | La ruta del perfil pasa a la de P159-05; verificar la ACL contra el vector v2 y que no se cree el perfil en `Temp`. |
| **CH-07** (aislamiento de red) | Se ejecuta en tres variantes: (1) intercepción activa y regla de cortafuegos desactivada (prueba 3a sola); (2) intercepción apagada por una opción de prueba y regla activa (prueba la regla sola, defensa en profundidad); (3) ambas. Con D-T403-2, añadir **CH-07b**: plantilla Razor con `<script>` que hace `fetch`, `XMLHttpRequest`, `WebSocket` y `navigator.sendBeacon`: ningún paquete sale y el script no corre. |
| **CH-08** (regla de cortafuegos) | «Sin la regla, documenta qué saldría (evidencia)» cambia: con 3a la salida **no** debe existir ni sin regla; sale solo `preconnect`/DNS si el navegador lo intenta. Resultado esperado nuevo: sin regla y con 3a, cero paquetes; con 3a desactivada y regla, cero paquetes. |
| **CH-09** (huérfanos) | El Job Object es 3b (recortable): sin 3b, el resultado esperado es «el navegador termina al cerrarse la tubería (`Pipe = true`)» [I]; con 3b, además muere con el servicio. El caso se parte en CH-09a (3a) y CH-09b (3b). |
| **CH-10** (memoria) | El límite de memoria del Job Object es de 3b; sin él se mide la memoria del navegador sin tope. |
| **CH-13** (versión del navegador) | La «ruta limitada» es 3b: hasta entonces, la versión se prueba con la configuración actual. |
| **CH-04/CH-05** | Sin cambios (P159-04). Q-1 y Q-2 siguen abiertas. |
| **PK-R7** | La comprobación de la regla al arrancar es de 3b; R7 del paquete (cortafuegos) sigue siendo del instalador (devops). |

**P159-08 (Baja) Desfases.**
- La hoja suma ≈ 2,6 dp (1,6 + 1,0); el plan del tramo 4 dice 2 dp para T4-03 y calendariza «T4-03: L 11-23 a V 12-04»; la ficha del plan no se actualizó.
- Plan, línea 389: «T4-03 no lo [JavaScript] apaga; lo resuelve la v2» contradice D-T403-2 (la v2 queda para el motor v2; para Razor se apaga ya).
- La hoja lista ADR-109 (cl. 12) entre los ADR que se precisan, pero el PR solo edita ADR-007 y ADR-110. Si la precisión de ADR-109 es la separación 3a/3b, falta anotarla; si no, quitar el listado.
- La hoja dice «Hoy no hay clientes afectados», pero los 13 formatos estándar y los dorados de T4-01 deben revisarse: prueba ARQ `Los_formatos_estandar_no_contienen_script_ni_URL_externa` (busca `<script`, `src=http`, `href=http`, `url(http` en formatos estándar y en el corpus de dorados) y aviso al SUPER al guardar una plantilla Razor con `<script>` o URL externa (hoy se rompería en silencio: imagen ausente, sin mensaje).

### B.3 Hallazgo EF-1

**P159-09 (Media) Pruebas que protegen «el esquema se migra con EF, no con SQL a mano».**
**Ya existe** [V: `tests/GPOS.Tests/ModeloNg/AprovisionamientoTests.cs:151-166`, `modelo-ng`]: `El_script_embebido_es_el_que_genera_EF` compara `IMigrator.GenerateScript(Idempotent)` con el guion embebido (`ScriptEmpresa`) y exige un único recurso `gpos-empresa-*.sql`. Eso protege el guion acumulado (nombre y contenido) contra migraciones añadidas sin regenerarlo y contra ediciones a mano. Hay además pruebas por migración de ida y vuelta (`GenerateScript` entre marcas) en `BusquedaSinTildesTests`, `FactorUnidadAjustesTests` y `CompraVariableTablaTests` [V]. Faltan:
1. **Instantánea al día:** ninguna prueba llama `HasPendingModelChanges()` (o equivalente) [V: sin coincidencias en `tests/` de `modelo-ng`]. Prueba: `El_modelo_coincide_con_la_instantanea` (si cambia una entidad y se olvida la migración, falla). Es la defensa directa de «el esquema se migra con EF».
2. **Orden de marcas = orden de unión** (regla del 2026-10-14, guía de PR, regla 4): prueba ARQ `Las_marcas_estan_en_orden_unico_y_la_ultima_es_la_del_guion`: ids de migración en orden ordinal sin repetidos, `[Migration("...")]` igual al nombre de archivo, `[DbContext]` correcto, el nombre del guion = la mayor marca. En CI, un guion de PR: toda marca nueva del diff es mayor que la mayor de la rama base (`git diff --name-only` sobre `Migraciones/`); falla si una rama se une con una marca menor que la ya presente. Dos migraciones en vuelo (`Adr161TipoIdentificadorFiscal` y `Ola5VistasImp`): la segunda en unirse regenera marca, instantánea y guion; la prueba del punto 2 lo detecta.
3. **Idempotencia del SQL propio** (`SqlMigraciones*.cs`: `Rg14`, `Rs03`, `Ola5Tramo4`, `Adr161*`, `Imp*`): cada `migrationBuilder.Sql` se ejecuta dos veces sobre la misma base y el esquema/datos quedan iguales (mi ID-01 a ID-06, generalizado). Regla ARQ: todo `CREATE VIEW` va como `CREATE OR ALTER` o con guarda; todo `UPDATE` de relleno con `WHERE ... IS NULL`.
4. **Equivalencia de caminos:** base creada con `Migrate()` y base creada aplicando el guion acumulado: mismas tablas, columnas (tipo, nulabilidad, intercalación), índices, CHECK y vistas (comparación de `sys.*` normalizada). Evita que el guion generado diverja del modelo (nombres de CHECK, `EXEC(N'...')`).
5. **Aplicación del guion dos veces** (ID-01) a nivel de la suite general, no solo ADR-161.
6. **Compatibilidad con la pantalla «Crear / actualizar esquema»** (ADR-7, precisión del 2026-10-19): la pantalla en `modelo-ng` debe usar el mismo camino que `Aprovisionamiento` y el guion; prueba: crear una empresa por la pantalla y por `GPOS.Migracion` produce el mismo esquema (punto 4) [?: no leí la pantalla].
7. **`GPOS_SYSDATA` sin EF:** el CLAUDE.md del #160 afirma que no usa migraciones de EF; prueba ARQ: no existe `__EFMigrationsHistory` en la base del sistema ni un `DbContext` de migraciones para ella.
8. **CP-169 / ADR-50 en el modelo nuevo** (P162-08): `TI-V0`.
9. **Regla de dónde va el esquema:** ARQ en `modelo-ng`: no se agregan cambios de empresa a `database/01_*` ni `02_*` (si existen en la rama; no verifiqué si siguen en el árbol) y `database/empresa/` solo contiene guiones generados (lo cubre el punto 2 por nombre y contenido).
10. **T4-10 `Ola5VistasImp`** sigue la regla de las vistas: `MigracionOla5VistasTests` exige que `database/ola5` coincida con la migración [V citado por B]; para `imp`, misma prueba más `ContratoImpresionVistasTests` del plan.

Sobre los documentos: la nota de ADR-7 y el CLAUDE.md del #160 coinciden en el fondo (el #160 apunta a `feature/modelo-ng`; la nota está en `master`). La hoja afirma que `SqlMigracionesOla5Tramo4.cs` existe: [V] existe en `src/GPOS.Core/Datos/Empresa/Migraciones/`.

### B.4 Qué no verifiqué (#159)

- No compilé ni ejecuté nada; no sé si `DOM.getBoxModel` iguala la medición actual (es la prueba que pide la hoja y que no existe).
- No leí el código de T4-01 en `b/ola5-t4-01-render` (render en la API de reportes), solo el `ConvertidorPdf.cs` de `master`; la forma real de la intercepción, la bandera de JavaScript y `Pipe = true` en esa rama [?].
- No leí `instalador/Reportes` ni `diseno-instalador-reportes.md` completo; el vector v2 lo leí solo en la parte de subcarpetas (`Render\{INST}\{EMP}`).
- Los comportamientos de Chromium (evaluación del arnés con JavaScript apagado, `preconnect`, cierre por tubería, sandbox bajo la cuenta virtual) son [I]: conocimiento general, sin documentación del fabricante a mano.
- No comprobé si `HasPendingModelChanges` o una prueba equivalente existe en otro proyecto de pruebas (mi búsqueda fue en `tests/` de `modelo-ng` por nombres, no una lectura completa).
- No revisé el diff del #160 más allá del cambio de una línea del CLAUDE.md.

---

### Cierre
- Estado: Completado (revisión de pruebas; sin veredicto sobre los PR)
- Artefactos: `C:/Users/lfmen/source/repos/GPOS-NG-Equipos/traspasos/C/2026-10-22-revision-pruebas-pr162-y-pr159.md`
- Supuestos: contraste con `origin/feature/modelo-ng` @ 2fa6843b; el #162 se juzga contra su base `bf40ad88`
- Decisiones candidatas a ADR: ninguna
- Entregas a otros agentes: B (arquitecto-datos y desarrollador-backend) → resolver P162-01 a P162-05 y P162-10 antes de construir; B (arquitecto-software) → criterio numérico de P159-01, asignación de JavaScript apagado (P159-02) y ruta del perfil (P159-05)
- Próximo paso recomendado: B fija el criterio del rollo y la ruta del perfil, y C convierte A.4 y B.2 en el plan de pruebas de T4-03a y del servicio del ADR-161
