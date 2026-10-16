# Precisión del punto 1 de DL-22 (a): la API deja el grupo viejo antes de tocar la credencial anterior

**Fecha:** 2026-10-16 (v2: integra la opinión del auditor de seguridad y la variante B+) · **Equipo:** A (arquitecto de software) · **Estado:** **Firmada (b+) por el propietario el 2026-10-16 en la sesión de A** (v2.1)

**Precisa:** el punto 1 y el «Riesgo aceptado» de la precisión del 2026-10-15 del punto 3 de ADR-82 (DL-22 (a), plazo de 2 min), en `traspasos/A/adr-licencia-2026-10-15/ADR-082-precisiones-2026-10-15.md`. Hoja de firma DL-01 a DL-22 v2.13 (`traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`, DL-22).

**Fuentes**
- Código: `Solucion GPOS NG\GPOS-NG-dl22`, rama `a/dl22-rotacion`, commit `367128f0` (diff contra `ce33b2a8`). Solo lectura: no se compiló ni se ejecutaron pruebas en esta revisión.
- Informe del auditor: `traspasos/A/revision-seguridad-dl22-rotacion-2026-10-16.md`, secciones 4 y 8.

**Decide y firma:** el propietario (Leonardo Méndez). Este documento no aprueba nada.

| Versión | Cambio |
|---|---|
| 1 | Opciones (a) y (b) del desarrollador; recomendación (a) |
| 2 | Agrega (b+) del auditor. Compara las tres opciones en exposición de la credencial, exposición de las sesiones, costo, qué rompe y comportamiento ante una interrupción. Separa la recomendación de cada especialista. Incorpora las condiciones del auditor (tope fijo de la espera, caché con caducidad, `--urgente` sin espera, S05) y S02 y S03 como condición para unir. **La recomendación final pasa a (b+), precisada** |
| 2.1 | **Firma del propietario: (b+)** (2026-10-16, sesión de A, «Firmo (b+)»). Sin otros cambios |

---

## 1. Qué pasó

La construcción de DL-22 (a) cumplió los puntos 1 a 6, pero **el punto 7 (PA-30: dos rotaciones bajo carga sin ningún 500) no se cumple**. En 6 de 6 corridas salieron entre 6 y 10 respuestas 500, y alguna 503, de 750 a 2600 peticiones. Casi todas aparecen en el instante del `DENY CONNECT` y alguna en el `KILL` al vencer el plazo. La prueba quedó marcada `Transicion=Defecto` (`tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs:772-782`).

El desarrollador verificó en SQL Server 2019 Express, con una base contenida temporal, cómo se comporta el motor (`Rg14Lote2Tests.cs:772-778`). El auditor lo cita y no lo reprodujo.

| Acción sobre la generación anterior | Sesión ya abierta | Conexión del grupo que se reutiliza |
|---|---|---|
| `DENY CONNECT` | **Cada lote siguiente falla con el 916** | Falla con el **18456 en su primer comando** (el reinicio viaja con él) |
| `ALTER USER … WITH PASSWORD` | **Sigue funcionando** | Falla igual, con el 18456 en su primer comando |

La premisa del texto firmado («la generación anterior conserva sus sesiones durante el plazo») es falsa con el `DENY`. Según la tabla, solo se cumple con el cambio de contraseña.

## 2. Por qué el grupo sigue usando la generación anterior

`gpos_app_a` y `gpos_app_b` son usuarios distintos, con cadenas distintas y, por lo tanto, con grupos de conexiones distintos. **Lo que no cambia a tiempo es la cadena que entrega la API.** Esto está verificado en el código:

| Hecho | Evidencia |
|---|---|
| La caché de cadenas es estática, por proceso, y **no vence nunca** | `src/GPOS.Core/Sistema/EmpresasService.cs:24` y `:30` |
| Solo se renueva al guardar desde la pantalla o **después de un fallo** (`Olvidar` ante un 18456) | `EmpresasService.cs:102`, `:48-51`; `src/GPOS.Api/Program.cs:405-408` |
| La sesión de EF toma la cadena al crearse | `src/GPOS.Core/Infraestructura/Sesion.cs:109-112` |
| La reapertura solo cubre el 18456 **de la apertura** | `src/GPOS.Core/Infraestructura/Motor/ReaperturaConexionEmpresa.cs:20-53` |
| El candado de restauración usa su propio `SqlConnection`. Un 18456 del comando no provoca la relectura: la API responde «no disponible» | `src/GPOS.Core/Infraestructura/CandadoEmpresas.cs:56-69`; `src/GPOS.Api/Seguridad/ModoCandadoRestauracion.cs:76`. Es la causa probable de los 503 [I] |
| Los trabajos en segundo plano usan la misma caché, con otro grupo | `EmpresasService.cs:40`; `src/GPOS.Core/Infraestructura/CadenaConexion.cs:57-59` |
| Todas las rutas ADO.NET propias que abren la base de la empresa toman la cadena de esa misma caché (`ObtenerAsync`) | Llamadas en `ModoCandadoRestauracion.cs:66`, `VersionEsquemaEmpresa.cs:39/51`, `TrabajoVigilanciaRestauracion.cs:107/112`, `TrabajoNotificaciones.cs:114` |

**Conclusión, en la que coinciden el desarrollador y el auditor.** El problema es **de secuencia**, no de plazo. Ninguna forma de invalidar la credencial anterior (`DENY` o contraseña) evita los 500 mientras la API siga sacando conexiones del grupo viejo. La condición necesaria es que **la API pase a la cadena nueva antes de que se toque la anterior**. Como todas las rutas leen la misma caché, basta con arreglarlo en un solo lugar (`EmpresasService`).

## 3. Las tres opciones

**Condiciones comunes a las tres** (las pide el auditor y las acepto):
- **Tiempos fijos en el código, con tope.** Ninguna espera es configurable hacia arriba, y la espera hasta el `DENY` es como máximo de 15 s. Son constantes de `GPOS.Core` (`CadenaConexion`), compartidas por la API y `GPOS.Migracion`.
- **`--urgente` sin espera:** `DENY`, cambio de contraseña y `KILL` en el acto. Además, falla si no puede ver o cerrar las sesiones (S02).
- **Permisos (`VIEW SERVER STATE` y `ALTER ANY CONNECTION`) comprobados antes de rotar** (S03). Si una ejecución anterior quedó a medias, `credencial-app` completa el retiro sin volver a rotar.
- **S4 (S05):** una sesión de la generación anterior es un aviso dentro de los 6 min y un hallazgo (código 4 con `--estricto`) después. Lo mismo vale para una generación anterior que conserve `CONNECT` pasado ese tiempo.
- **El `KILL` sigue a los 2 min** (rango firmado de 2 a 6) y su bucle tiene un tope (S06).

### (a) Opción A del desarrollador: la caché vence a los 5 s y el `DENY` se aplica a los 10 s

`credencial-app`: guarda la cadena nueva → espera 10 s → `DENY CONNECT` → `KILL` a los 2 min.
En la API, la caché de la cadena vence a los 5 s y se relee una sola vez por empresa. Si la cadena cambió, se llama a `LimpiarGrupos` de la anterior. Si GPOS_SYSDATA no responde, se conserva la cadena vigente.

### (b) Opción B del desarrollador: contraseña en el acto, `DENY` y `KILL` al plazo, sondeo en cada apertura

`credencial-app`: guarda la cadena nueva y cambia en el acto la contraseña de la anterior por una aleatoria que se descarta. `DENY` y `KILL` al vencer el plazo.
En la API, cada apertura hace un `SELECT 1` contra la base de la empresa (el sondeo), que fuerza el reinicio de la conexión. Si da 18456, se hace `ClearPool`, se relee la cadena y se vuelve a abrir. La API sigue enterándose de la rotación por un fallo.

### (b+) Variante del auditor, precisada: la API deja el grupo viejo en 1 s, la contraseña se cambia a los 3 s y el `DENY` se aplica a los 15 s

`credencial-app`: guarda la cadena nueva → **3 s** → cambia la contraseña de la anterior por una aleatoria que se descarta → **15 s** (contados desde el guardado) → `DENY CONNECT` → `KILL` a los 2 min del `DENY`.

En la API, la caché comprueba si la cadena cambió **cada 1 s como máximo**, una sola vez por empresa. Si cambió, la descifra, la reemplaza y llama a `LimpiarGrupos` de la anterior. Si GPOS_SYSDATA no responde, conserva la vigente.

**Dos precisiones mías sobre la propuesta del auditor:**
1. **La contraseña no se cambia «en el acto» del guardado sino a los 3 s.** Antes de que la API haya pasado a la cadena nueva (1 s de vigencia más el margen), la tabla de la sección 1 muestra que el cambio de contraseña rompe la conexión reutilizada y devuelve los 500.
2. **Para detectar el cambio no hace falta un `rowversion`.** `dbo.Empresas` no lo tiene (`src/GPOS.Core/Data/Sistema/SistemaDbContext.cs:189-195`), así que agregarlo exigiría una migración de GPOS_SYSDATA. Basta con comparar `ConexionCifrada` con la última leída: unos cientos de bytes, sin descifrar si no cambió y sin migración. Tampoco hay sondeo contra la base de la empresa, así que (b+) **no tiene** el costo permanente de (b).

En el fondo, (b+) es (a) con una vigencia más corta y un paso de contraseña antes del `DENY`.

### Comparación

| Criterio | (a) A del desarrollador | (b) B del desarrollador | **(b+) del auditor, precisada** | Lo firmado (referencia) |
|---|---|---|---|---|
| **Exposición de la credencial anterior** (sigue sirviendo para sesiones nuevas) | **≈ 10 s** (hasta el `DENY`) | **≈ 0 s** | **≈ 3 s** (hasta el cambio de contraseña) | ≈ 0 s |
| **Exposición de las sesiones abiertas** de la anterior (siguen ejecutando sentencias) | ≈ 10 s; después, 916 hasta el `KILL` | **Hasta el plazo: 2 min** (es el riesgo ya firmado); el `KILL` las corta | **≈ 15 s**; después, 916 hasta el `KILL` | ≈ 0 s (916 en el acto) |
| **500 en una rotación de rutina** | Ninguno esperado [I]. Residual: una petición de más de 10 s que empezó antes del cambio | Ninguno en las rutas EF [I]. **Sí en las 7 rutas ADO.NET sin sondeo** (candado, `IdentidadSql`, `FuentesHoraEmpresa`, `VigilanciaNumeracion`, `SucursalesEmpresa`, `RncDgiiService`, `EsquemaEmpresasNg`). Y en el `KILL`, si alguna sesión sigue en uso a los 2 min (S07) | Ninguno esperado [I]. Residual: una petición de más de 15 s que empezó antes del cambio, o un proceso de API que no relea en 3 s | 6 a 10 por corrida (medido) |
| **Ante una interrupción** (Ctrl+C, caída de la conexión o del servidor) | Si ocurre entre el guardado y el `DENY` (10 s), la anterior queda válida **sin límite** con su contraseña. Esa contraseña está en la cadena cifrada anterior, que pueden conservar los respaldos de GPOS_SYSDATA. S4 lo detecta | Inofensiva: la contraseña ya cambió y nadie la conoce | Inofensiva desde los 3 s. Antes de los 3 s, igual que (a) durante 3 s. S4 lo detecta y una nueva ejecución completa el retiro | Ventana de milisegundos |
| **Costo de construcción** [I] | ≈ 0,3 dp (el auditor estima 0,2) | ≈ 0,4-0,5 dp | ≈ 0,35-0,4 dp (el auditor estima 0,3-0,4) | — |
| **Costo de operación** [I] | 1 lectura de GPOS_SYSDATA cada 5 s por empresa activa y por proceso (≤ 1 ms) | **1 viaje más por apertura, para siempre.** EF abre en cada consulta fuera de una transacción, así que es casi un viaje por consulta: 0,1-0,3 ms en local y 1-5 ms o más en remoto o en nodos de ADR-53 | 1 lectura pequeña de GPOS_SYSDATA cada 1 s por empresa activa y por proceso (con 20 empresas y 3 procesos, unas 60 por segundo, de ≤ 1 ms) | — |
| **Qué rompe o cambia** | Punto 1 firmado (`DENY` a los 10 s); la caché deja de ser permanente; +10 s por empresa en `credencial-app` | Punto 1 firmado; las sesiones viven 2 min (más que hoy); `Connection Lifetime` con margen (≈ 90 s, S07); sondeo en las 7 rutas ADO.NET o se aceptan 503 y 500 en ellas | Punto 1 firmado (contraseña a los 3 s, `DENY` a los 15 s); la caché deja de ser permanente; +15 s por empresa | — |
| **En las tres** | Se ajustan las pruebas que suponen el `DENY` inmediato (por ejemplo, alrededor de `Rg14Lote2Tests.cs:530`). PA-30 «ningún 500» vuelve a la suite oficial. **Condición:** todo proceso de API lee la misma `dbo.Empresas` que escribe `credencial-app`. Si un nodo de ADR-53 leyera una copia replicada, las esperas tendrían que cubrir el retraso de réplica | | | |

### Descartadas (en esto coinciden los tres especialistas)
- **Reintentar la petición o el comando** (incluido `EnableRetryOnFailure`): reintenta escrituras y transacciones a medias, con riesgo para la numeración NCF y el inventario (`ReaperturaConexionEmpresa.cs:11`).
- **Subir el plazo hacia 6 min:** se midió y no ayuda, porque los 500 salen en el `DENY`, no en el `KILL`. Además alarga la exposición (DL22-S01).
- **Mantener lo firmado y aceptar los 500:** es lo más estricto, pero contradice el punto 7 y la intención firmada («sin errores visibles para el cajero en una rotación de rutina»).
- **Una señal enviada a cada proceso** en lugar de la vigencia: requiere un canal nuevo hacia la API, sus trabajos y los futuros nodos, y no aporta nada frente a la vigencia. Si alguna vez existe, solo debe provocar la relectura y nunca transportar la cadena (condición del auditor).

## 4. Recomendaciones, por especialista

| Especialista | Recomienda | Motivo principal |
|---|---|---|
| **Desarrollador de identidades** (informe de DL-22) | **(a)** | Es lo más simple. No cambia el comportamiento de las sesiones abiertas. Cuesta unos 0,3 dp |
| **Auditor de seguridad** (`revision-seguridad-dl22-rotacion-2026-10-16.md`, sección 8) | **(b) o (b+)**, con (b+) como la que reduce también la ventana de sesiones | Cierra en el acto la ventana más peligrosa (una credencial conocida que sigue autenticando) y resiste mejor una interrupción. Lo que cede en (b) es lo que el propietario ya firmó |
| **Arquitecto de software** (este documento; en la v1 recomendaba (a)) | **(b+), precisada:** contraseña a los 3 s y `DENY` a los 15 s, detección por comparación de `ConexionCifrada` (sin migración ni sondeo en la base de la empresa) | Ver abajo |

**Por qué cambio de (a) a (b+).** El auditor señala un punto débil de (a) que yo no había ponderado: **una interrupción entre el guardado y el `DENY` deja la credencial anterior válida sin límite**, y su contraseña sigue existiendo en la cadena cifrada que pueden conservar los respaldos de GPOS_SYSDATA. (b+) lo resuelve con un paso más en `credencial-app` (≈ 0,05-0,1 dp sobre (a)). La ventana de la credencial baja de unos 10 s a unos 3 s y la de las sesiones queda en unos 15 s, mucho menos que los 2 min que el propietario ya aceptó.

Frente a (b), (b+) gana por tres motivos:
- no paga un viaje más por apertura de forma permanente;
- cubre las 7 rutas ADO.NET sin tocarlas, porque todas leen la misma caché;
- deja vivas las sesiones de la anterior 15 s y no 2 min.

El precio de (b+) frente a (a) es poco: una lectura de GPOS_SYSDATA por segundo en lugar de cada 5 s, y 5 s más por empresa en `credencial-app`.

## 5. Texto de la precisión, listo para registrar (si se firma (b+))

> **Precisión del 2026-10-16 del punto 1 de la precisión del 2026-10-15 del punto 3 (DL-22 (a)): la API deja el grupo de conexiones de la generación anterior antes de que esta pierda el acceso.** Firmada por Leonardo Méndez, propietario, el 2026-10-16, en la sesión de A: «Firmo (b+)».
>
> La construcción de DL-22 (a) verificó en SQL Server 2019, con un usuario contenido, que:
> - `DENY CONNECT` hace fallar con el 916 cada lote siguiente de las sesiones abiertas;
> - tanto `DENY CONNECT` como el cambio de contraseña hacen fallar con el 18456 el primer comando de una conexión reutilizada del grupo;
> - con el orden firmado, PA-30 daba de 6 a 10 errores 500 por corrida.
>
> Sin cambiar el texto firmado de arriba, el punto 1 se cumple así:
> 1. **La API comprueba la cadena de cada empresa cada 1 s como máximo** (compara `ConexionCifrada`, con una sola relectura por empresa a la vez). Si cambió, la toma y vacía los grupos de conexiones de la anterior (`LimpiarGrupos`). Si GPOS_SYSDATA no responde, conserva la vigente.
> 2. **`credencial-app` guarda la cadena nueva; a los 3 s cambia la contraseña de la generación anterior por una aleatoria que no se guarda; a los 15 s del guardado le aplica `DENY CONNECT`.** El `KILL` diferido y obligatorio corre a los 2 minutos del `DENY` (rango firmado de 2 a 6) y tiene un tope. Los tiempos son fijos en el código.
> 3. **`--urgente`:** `DENY CONNECT`, cambio de contraseña y `KILL` sin espera. Falla si no puede ver o cerrar las sesiones.
> 4. Los permisos se comprueban antes de rotar. Una ejecución interrumpida se completa sin volver a rotar.
> 5. **S4:** una sesión de la generación anterior, o una generación anterior con `CONNECT`, es un aviso dentro de los 6 min y un hallazgo después.
> 6. Los puntos 2 a 7 siguen como están. PA-30 (punto 7) vuelve a la suite oficial y mide, además de los 500, que la credencial anterior deja de servir a los 3 s y que sus sesiones dejan de ejecutar sentencias a los 15 s.
>
> **Riesgo aceptado (sustituye al del 2026-10-15):**
> - la credencial anterior sirve para sesiones nuevas durante unos 3 s después del cambio de cadena;
> - las sesiones abiertas de la generación anterior ejecutan sentencias durante unos 15 s y, desde el `DENY`, ya no ejecutan nada hasta el `KILL`;
> - una petición de más de unos 15 s que empezó con la cadena anterior puede fallar en la rotación.
>
> Ante un compromiso se usa `--urgente`.
>
> **Condición:** todo proceso de API lee la cadena de la misma `dbo.Empresas` que escribe `credencial-app`. Con nodos de ADR-53 que lean una copia replicada, las esperas deben cubrir el retraso de réplica.
>
> *Descartados:*
> - la A del desarrollador (`DENY` a los 10 s, sin cambio de contraseña): una interrupción deja la credencial anterior válida sin límite;
> - la B del desarrollador (sondeo en cada apertura): un viaje más permanente, no cubre las rutas ADO.NET propias y deja las sesiones vivas 2 min;
> - reintentar la petición o el comando;
> - subir el plazo (medido: no ayuda);
> - una señal hacia cada proceso.
>
> Costo: unos 0,35-0,4 dp del desarrollador de identidades [I], sin migración ni infraestructura. **Decidido, no implementado.**

*Si se firma (a) o (b), el texto se adapta con los tiempos y el riesgo de su columna en la tabla de la sección 3.*

## 6. Casilla de firma

| Opción | En una línea | Credencial | Sesiones | Costo [I] |
|---|---|---|---|---|
| (a) | Caché de 5 s; `DENY` a los 10 s; `KILL` a los 2 min | ≈ 10 s | ≈ 10 s | ≈ 0,3 dp |
| (b) | Contraseña en el acto; `DENY` y `KILL` a los 2 min; sondeo en cada apertura | ≈ 0 s | 2 min | ≈ 0,4-0,5 dp + latencia permanente |
| **(b+) (recomendada por el arquitecto; el auditor la propone)** | Caché de 1 s; contraseña a los 3 s; `DENY` a los 15 s; `KILL` a los 2 min | ≈ 3 s | ≈ 15 s | ≈ 0,35-0,4 dp |

`[ ] (a)` · `[ ] (b)` · `[x] (b+)` — firmada por el propietario el 2026-10-16 en la sesión de A: «Firmo (b+)» · `[ ] Ninguna: se mantiene el orden firmado y PA-30 «ningún 500» sigue en Defecto`

## 7. ¿Se puede unir ya el PR actual (puntos 1-6 y PA-30 de sesiones)?

**Recomendación técnica: sí, después de corregir S02 y S03 en la misma rama**, como pide el auditor (≈ 0,1 dp). La decisión de unir es de B y del propietario.

- Implementa los puntos 1 a 6 tal como están firmados. Todo lo construido sirve para cualquiera de las tres opciones: plazo, `--urgente`, `Connection Lifetime`, `LimpiarGrupos`, S4 y `DEADLOCK_PRIORITY LOW` con reintento del 1205.
- No empeora lo anterior: el `KILL` inmediato previo ya daba 500 bajo carga.
- La marca `Transicion=Defecto` sigue la regla de la suite oficial (filtro `Transicion!=Ola5&!=Defecto`). Hoy no hay producción.

**Condiciones para unir**
1. Corregir **S02**: `--urgente` falla si no puede ver o cerrar las sesiones. Es el camino de contención y hoy sale con código 0 aunque no haya cerrado nada.
2. Corregir **S03**: los permisos se comprueban antes de rotar.
3. Que la descripción del PR y la nota de ADR-82 digan «implementado salvo el punto 7, pendiente de la precisión del punto 1 del 2026-10-16».
4. Que B no registre como cumplido el «Riesgo aceptado» del 2026-10-15, porque su premisa resultó falsa.

**Después de unir**, en la rama de la opción firmada: S04 a S07. S07 solo aplica si se firma (b). S08 va en el lote del parser.

**Observaciones de severidad Baja**
- La ayuda de `credencial-app` (`src/GPOS.Migracion/Program.cs`) da a entender que solo `--urgente` produce 500. No es exacto hasta construir la opción firmada.
- `--todas` rota las empresas una tras otra, con el plazo dentro de cada una (`Program.cs:263-268`): N empresas tardan unos N × 2 min. Más adelante conviene procesarlas por fases en lote.

## 8. Entregas

- **Propietario (vía B):** firmar la casilla de la sección 6.
- **Arquitecto Maestro / documentador (B):** con la firma, registrar en `docs/adr/ADR-082.md` el texto de la sección 5 (o el de la opción firmada), después de la precisión del 2026-10-15, y ajustar la fila 82 del índice.
- **Desarrollador de identidades (A):** antes de unir, corregir S02 y S03 en `a/dl22-rotacion`. Con la firma, construir la opción en una rama nueva: caché con vigencia en `EmpresasService`, nuevo orden en `CredencialApp.AplicarAsync`, S4 (S05), tope del `KILL` (S06), pruebas, y quitar `Transicion=Defecto` de PA-30.
- **QA automatizado:** PA-30 mide también la ventana de la credencial y la de las sesiones, además de los 500, y comprueba la relectura con GPOS_SYSDATA caída.
- **Arquitecto de datos / sincronización (ADR-53):** dejar anotada la condición del retraso de réplica de GPOS_SYSDATA frente a las esperas (3 s y 15 s).
