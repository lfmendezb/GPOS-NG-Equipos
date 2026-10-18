# Revisión de seguridad corta: guarda de largos por la conexión de EF (condición 4 de B)

- Fecha: 2026-10-18 · Revisor: auditor-seguridad (equipo C)
- **Veredicto (recomendación técnica, C2): Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Hay cinco Bajos: dos los introduce el cambio y tres vienen de antes.
- Las líneas citan la versión nueva (`scratchpad/lc-despues.cs`, que equivale a `src/GPOS.Core/Infraestructura/LongitudesColumnas.cs` del worktree `GPOS-C-intermitentes`). No leí el archivo vivo del worktree, que estaba cambiando por la corrida de pruebas. No compilé ni ejecuté pruebas. La prueba nueva la leí, no la corrí.

## 1. Alcance y superficie
- Archivos: `LongitudesColumnas.cs` (antes, después y el diff), `EmpresaDbContext.cs:134-150` (las dos rutas de `SaveChanges`), `UnidadTrabajo.cs`, `CadenaConexion.cs`, `EsquemaEmpresa.cs:180-205` (llamada a `Limpiar`) y la prueba `tests/GPOS.Tests/LongitudesColumnasConexionTests.cs`.
- Superficie: toda escritura de `EmpresaDbContext` que pasa por SaveChanges. No hay entrada del usuario en el SQL. Fuera de alcance: `ExecuteUpdate` y el SQL escrito a mano, que la guarda no cubre (ya documentado en `:23`).

## 2. Resumen

| ID | Severidad | Título | Origen |
|---|---|---|---|
| LC-01 | Baja | Quien cancela su propia lectura sale mientras esa lectura sigue usando su contexto y su conexión | Nuevo |
| LC-02 | Baja | Una espera cancelada saca de la caché una lectura ajena que está sana | Nuevo |
| LC-03 | Baja | La clave de la caché es la cadena completa, con contraseña, y vive en memoria sin límite tras cada rotación | Preexistente |
| LC-04 | Baja | Comportamiento abierto ante una columna que no aparece o un esquema vacío (permisos de metadatos) | Preexistente |
| LC-05 | Baja | Carrera entre `Limpiar()` y una lectura en curso: puede quedar en la caché un esquema anterior al DDL | Preexistente |

## 3. Respuesta a las cinco preguntas

**P1. ¿Se puede saltar la guarda? No, verificado.**
- El `Lazy` usa el modo por omisión, `ExecutionAndPublication` (`:92`). Como `LeerAsync` es `async` (`:108`), toda excepción, incluso una que se lance antes del primer `await`, queda dentro de la `Task`. El `Lazy` no guarda ninguna excepción sincrónica.
- Una tarea que falla o se cancela nunca produce un `Esquema`. Cada llamador recibe la excepción: o reintenta (`:95-99`) o la vuelve a lanzar (`:100-104`). En ambos casos SaveChanges se aborta, así que la guarda falla cerrada.
- La ruta sincrónica solo usa la caché si `IsCompletedSuccessfully` (`:82`). Solo agrega a la caché después de una lectura correcta (`:135`). `TryRemove(KeyValuePair)` compara por referencia (`:98`, `:102`) y no borra una entrada más nueva de otro llamador.
- El diccionario de columnas no se modifica después de construirse (`:116-119`).
- Riesgo residual: LC-04 y LC-05, que ya existían.

**P2. Aislamiento entre empresas: correcto, verificado.**
- La clave incluye `Initial Catalog`, `Data Source` y `User ID`, así que dos bases distintas nunca comparten entrada. La lectura sale por la conexión del propio contexto (`:141-146`), es decir, de la base real de esa cadena.
- Quien espera la lectura ajena (`:93`) solo la comparte si la cadena es idéntica, o sea, la misma base.
- En `src` no hay `ChangeDatabase` ni `USE`. `CrearBaseAsync` exige `Initial Catalog` (`EsquemaEmpresa.cs:210-211`).
- Mejora respecto de antes: la conexión nueva del código anterior podía caer en la base por omisión del login si la conexión de EF hubiera cambiado de base. La lectura nueva lee la base real.
- La lectura ajena corre en la transacción de otro llamador de la misma base. El DDL del esquema va por su propia `SqlConnection` (`EsquemaEmpresa.cs:184`), no por esa transacción, así que esa lectura no ve un DDL sin confirmar.

**P3. SQL: correcto.**
- La consulta es una constante sin parámetros ni concatenación (`:46-51`). Las comillas van duplicadas como corresponde dentro de `N'...'`. No hay riesgo de inyección.
- Según la documentación de SQL Server (*SET Statements*), los `SET` de un lote ejecutado con `sp_executesql` se restauran al volver el control. Por eso el nivel de la sesión y la transacción del llamador no cambian.
- Los bloqueos que la transacción SERIALIZABLE ya tomó se conservan. La lectura de metadatos solo toma bloqueos cortos.
- La prueba lo comprueba: el nivel sigue en 4 después del guardado (`LongitudesColumnasConexionTests.cs:57`, `:62`).
- Cambiar a READ COMMITTED también está permitido desde SNAPSHOT y evita el error 3961 de metadatos. Esto es inferido, no lo probé.
- Mensajes: un `SqlException` de esta lectura no lleva la cadena. Los mensajes de `Verificar` (`:214-220`) solo muestran el nombre de la columna, el largo y 40 caracteres del propio valor del usuario. No revelan nada del motor.

**P4. Disponibilidad: sin cuelgue ni giro sin fin. Hay dos observaciones (LC-01 y LC-02).**
- La espera ajena queda acotada por el `ct` propio y por el tiempo de espera del comando. El comando de `CreateCommand()` no hereda el `CommandTimeout(60)` de EF, así que usa los 30 s por omisión de `SqlCommand` (inferido). Sin token, la espera dura como máximo esos 30 s más la apertura.
- El bucle (`:90-105`) solo repite cuando falla una lectura ajena. Cada vuelta espera una E/S real, no gira en caliente. Si falla la lectura propia, la excepción sale (`:100-103`). El número de vueltas está acotado por las lecturas ajenas que fallan a la vez.

**P5. La cadena no llega a registros ni mensajes. Verificado.**
- El único registro (`:171-173`) escribe solo `InitialCatalog`, las columnas y la página de códigos. Ninguna excepción incluye la clave.
- Queda en memoria (LC-03).

## 4. Hallazgos

### LC-01 · Baja · La lectura propia sigue corriendo después de que su dueño se va (nuevo)
- **Riesgo:** `await lectura.Value.WaitAsync(ct)` (`:94`) también se aplica a la lectura propia. Si se cancela el `ct` de la petición, el llamador sale de inmediato, mientras `LeerAsync` sigue un momento sobre **su** `DbContext` y **su** conexión (`:111-121`). Después, el rollback o el desecho del contexto pueden coincidir con ese comando. El resultado son excepciones de uso concurrente o de objeto desechado. No hay datos que se salten la guarda. Solo pasa cuando un cliente aborta en ese instante.
- **Remediación (una línea):** si `ReferenceEquals(lectura, propia)`, esperar `await lectura.Value` sin `WaitAsync`; el `ct` ya llega al comando por `LeerAsync`. Dejar `WaitAsync(ct)` solo para la espera ajena.

### LC-02 · Baja · Una cancelación expulsa una lectura ajena sana (nuevo)
- **Riesgo:** con el `ct` propio cancelado mientras se espera una lectura ajena, el segundo `catch` (`:100-102`) quita esa entrada aunque siga en curso y vaya a terminar bien. Cada petición que se cancela durante un arranque en frío provoca, como mucho, una lectura de metadatos más. No compromete la integridad: la amplificación es pequeña y acotada.
- **Remediación:** en el `catch` general, quitar la entrada solo si es la propia o si `lectura.Value.IsFaulted || lectura.Value.IsCanceled`.

### LC-03 · Baja · La contraseña queda en la clave de la caché estática (preexistente)
- **Riesgo:** `Cache` (`:36`) guarda la cadena completa, con contraseña, durante toda la vida del proceso. Con la rotación de DL-22 se acumula una entrada por generación de credencial. No se registra ni se expone, pero aparece en un volcado de memoria. El cambio no lo agrava: antes pasaba igual.
- **Remediación (cuando convenga):** usar como clave `DataSource + InitialCatalog + UserID`, normalizados con `SqlConnectionStringBuilder`. `UserID` se incluye porque la visibilidad de `INFORMATION_SCHEMA` depende de los permisos. Alternativa: el SHA-256 de la cadena. Opcionalmente, vaciar la entrada en `CadenaConexion.LimpiarGrupos`. Esfuerzo: menos de 0,5 día.

### LC-04 · Baja · Abierta ante columnas no visibles (preexistente, informativo)
- **Riesgo:** si una columna no aparece en el esquema leído, `Verificar` la salta (`:210`). Si el login de la API no ve los metadatos (RG-14, privilegio mínimo), el esquema queda vacío, se guarda en la caché y la guarda no valida nada. Los largos los sigue imponiendo SQL Server (error de truncado, sin datos guardados). Lo que se pierde es el control de caracteres Unicode en columnas `nvarchar` que el modelo trata como `varchar`, donde la pérdida es silenciosa.
- **Remediación:** si `columnas.Count == 0`, no guardar en la caché y registrar un aviso. Alternativa más estricta: rechazar el guardado.

### LC-05 · Baja · `Limpiar()` frente a una lectura en curso (preexistente)
- **Riesgo:** una lectura que empieza antes del DDL o durante él (`EsquemaEmpresa.cs:180-204`) y termina después de `Cache.Clear()` no queda en la caché por la ruta asíncrona, porque su entrada ya se quitó. En cambio, una que entra con `GetOrAdd` durante el DDL, o el `TryAdd` sincrónico (`:135`), sí puede dejar un esquema anterior. Si la columna se ensanchó, la guarda rechaza datos válidos (falla cerrada). Si pasó a Unicode, se omite el control Unicode. La ventana es estrecha y la abre una acción del administrador.
- **Remediación:** un contador de generación que `Limpiar` incrementa. Solo se publica una lectura si la generación no cambió desde que empezó.

## 5. Controles bien implementados
- La lectura usa la conexión y la transacción de EF, sin pedir una segunda conexión al grupo. Elimina el agotamiento y pasa por los interceptores de EF (`:63-67`, `:141-146`).
- Hay una sola lectura por cadena y las lecturas fallidas se quitan de la caché (`:88-106`).
- READ COMMITTED queda acotado al lote dinámico. La prueba lo verifica con un grupo de una sola conexión (`LongitudesColumnasConexionTests.cs:21`, `:57-66`).
- `Validar` (sincrónico) no espera tareas asíncronas, así que no hay bloqueo de sincronía sobre asincronía (`:81-84`).
- El registro no incluye secretos (`:171-173`).

## 6. Remediaciones priorizadas
1. LC-01 y LC-02: un cambio de unas 5 líneas en `EsquemaAsync`. Se puede hacer ahora o en el siguiente lote. No bloquea.
2. LC-04: no guardar en la caché un esquema vacío y avisar. Conviene antes de aplicar el privilegio mínimo de RG-14.
3. LC-03 y LC-05: deuda preexistente, para el siguiente endurecimiento.

## 7. Recomendación
**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\revision-seguridad-longitudes-columnas-2026-10-18.md
- Supuestos: el texto revisado es `lc-despues.cs`; el tiempo de espera de 30 s del comando y el comportamiento con SNAPSHOT son inferidos, no probados; no se ejecutaron pruebas.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: desarrollador backend → LC-01 y LC-02 (ajuste de `EsquemaAsync`) y LC-04 (no guardar en la caché un esquema vacío)
- Próximo paso recomendado: aplicar LC-01 y LC-02 en el mismo PR si el costo es menor que otra corrida; si no, registrarlos como seguimiento.
