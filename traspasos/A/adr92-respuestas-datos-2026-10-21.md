# ADR-92: respuestas del arquitecto de datos (equipo A) a TT-P1 a TT-P5 y CS-P2 a CS-P4

- **Fecha:** 2026-10-21 · **Autor:** arquitecto-datos del equipo A · **Encargo:** `avisos/B-a-A/2026-10-21-encargo-adr92-privilegios-api-y-laboratorio-aplazado.md`, tarea 1.
- **Naturaleza:** **propuesta técnica**. No decide nada. B la integra como precisión de ADR-92. Lo que cambie lo que ve o hace una persona (marcado **[firma]**) va a la firma del propietario.
- **Plazos:** CS-P2 antes del **2026-11-02** (entra en la DDL de D1 de DB-7). El resto, antes del 2026-11-09.
- **Base leída (solo lectura, sin cambiar de rama ni tocar código):**
  - ADR-92: `origin/b/adr92-dp1-dp3-dp5:docs/adr/ADR-092.md` (en adelante **ADR92**).
  - DDL de D1, rev. 2: `origin/master:docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` (en adelante **D1**).
  - Código: `origin/feature/modelo-ng` @ `b8f166db` (en adelante **MNG**).
  - ADR-37, 67, 88, 115 y 128 en `origin/master`.
- **Convención:** [V] = verificado en `archivo:línea`; [I] = inferido.
- **Nombres:** no cambio ningún nombre de D1. Agrego dos columnas, dos restricciones y un índice nuevos (sección CS-P2), y amplío el texto de `CK_BitacoraSeguridad_IngresoSuper` sin cambiarle el nombre, tal como anticipa ADR92:77.

---

## CS-P2 (prioritaria): columnas del caso, restricciones, índice y colación

### Hechos de partida
- `BitacoraSeguridad` vive en `GPOS_SYSDATA`. Sus columnas de código son ASCII y `varchar`: `Evento varchar(40)`, `Sesion varchar(32)`, `Ip varchar(45)` y `Canal varchar(10)`. `Motivo` es `nvarchar(400)` [V MNG `src/GPOS.Core/Consultas/Sistema/Restauracion/EsquemaRestauracionSistema.cs:30-38`].
- La intercalación de las instancias es `SQL_Latin1_General_CP1_CI_AS` [V `CLAUDE.md:37`]. El proyecto ya usa `COLLATE Latin1_General_BIN2` en columnas de identificadores con `CHECK` de alfabeto (`Jti`) [V MNG `src/GPOS.Core/Consultas/Sistema/SegundoFactor/EsquemaSegundoFactor.cs:74-75`]. D1 hace lo mismo en el catálogo [V D1:113 y :890].
- La forma firmada en CS-02 es: de 6 a 30 caracteres, solo letras mayúsculas sin acentos, dígitos y guion, sin espacios [V ADR92:51]. La convención de GSF es `GSF-AAMMDD-NN`, con 13 caracteres [V ADR92:127].
- CS-03 pide dos columnas propias, en la DDL de D1 y sin un segundo `ALTER` [V ADR92:55].
- La historia de la fase A no tiene caso: las columnas admiten nulo y la restricción solo se aplica a los eventos que la exigen [V ADR92:84].
- `BitacoraSeguridad` no está mapeada en EF (no hay `HasTrigger` que tocar) [V D1:60]. Todo lo que cita una columna nueva va dentro de `EXEC`, porque el lote se compila entero [V D1:721].

### Recomendación

**1. Columnas.**
- **`NumeroCaso varchar(30) COLLATE Latin1_General_BIN2 NULL`**
  - **Tipo:** `varchar` y no `nvarchar`, porque el alfabeto permitido es ASCII. Ahorra la mitad de los bytes y sigue el precedente de `Evento`, `Sesion` e `Ip`.
  - **Largo:** 30, el máximo de CS-02.
  - **Colación BIN2**, por tres motivos:
    - con la intercalación CI de la instancia, `[A-Z]` acepta minúsculas;
    - en una intercalación no binaria, el rango sigue el orden lingüístico y deja pasar letras acentuadas (`á` cae entre `a` y `b`) [I, comportamiento documentado de `LIKE` con rangos];
    - la búsqueda por igualdad queda exacta y usa el índice.
- **`Urgencia bit NULL`**
  - `0` significa «Con aprobación por correo» y `1`, «Urgencia».
  - `NULL` significa que el evento no lleva caso.
  - Son dos modalidades firmadas y cerradas [V ADR92:59]. El texto que se muestra es tarea de la interfaz (CS-P7).

**2. Restricciones.** Las tres son declarativas, sin función ni disparador.

| Restricción | Regla | Por qué |
|---|---|---|
| `CK_BitacoraSeguridad_Caso` (nueva) | Si hay caso, va con su modalidad y viceversa. Si hay caso, debe tener la forma de CS-02 | Valida la forma en la base, sea quien sea el que escribe |
| `CK_BitacoraSeguridad_IngresoSuper` (texto ampliado; **mismo nombre**) | `INGRESO_SUPER` exige un motivo de 10 o más caracteres **y** el número de caso | Es la ampliación que anuncia ADR92:77. La modalidad queda exigida por la restricción anterior |
| `CK_BitacoraSeguridad_CierreUrgencia` (nueva, opcional en D1; ver CS-P3) | Los dos eventos de cierre llevan caso y `Urgencia = 1` | Evita un segundo `ALTER` en la fase CS-2 |

La longitud se mide con `DATALENGTH` y no con `LEN`: `LEN` no cuenta los espacios finales, y en `varchar` `DATALENGTH` coincide con el número de caracteres. Además, `LIKE '%[^A-Z0-9-]%'` rechaza cualquier espacio, también al final. El guion va al final del corchete para que sea literal.

**3. Índice.** Es un índice filtrado y pequeño:

`IX_BitacoraSeguridad_Caso ON dbo.BitacoraSeguridad (NumeroCaso, Id) INCLUDE (Evento, Empresa, Urgencia, MomentoUtc) WHERE NumeroCaso IS NOT NULL`

- **Consultas que lo justifican:**
  - **(a)** las urgencias abiertas al iniciar sesión el SUPER (CS-06), en **cada** inicio de sesión del SUPER;
  - **(b)** la comprobación del cierre (CS-P3);
  - **(c)** la búsqueda por caso del SUPER y del ADMIN.
- **Volumen:** de 2 a 5 ingresos del SUPER al mes por instalación [V ADR92:90]. En 5 años son unas 300 filas con caso: el índice ocupa unos 20 KB, de 3 a 5 páginas [I].
- **Sin el índice**, (a) recorre toda la bitácora: unos 125 MB en 5 años [V `ADR-037.md:18`], es decir, unas 16 000 páginas en cada inicio de sesión del SUPER. Serían de 100 a 300 ms en frío y desplazarían caché [I, ±50 %].
- **Costo de escritura:** solo las filas con caso, unas pocas al mes. Es despreciable.
- **Precedente:** ya hay un índice filtrado en `GPOS_SYSDATA` (`IX_Dispositivos_Pendientes`) [V MNG `src/GPOS.Core/Data/Sistema/EsquemaSistema.cs:182`].
- **Opciones SET:** todos los que escriben usan SqlClient (`ANSI_NULLS`, `QUOTED_IDENTIFIER` y `ANSI_WARNINGS` en `ON`; `ARITHABORT` queda implícito con el nivel 90 o más). Un `sqlcmd` sin `-I` fallaría al insertar (error 1934). No encontré escritores con `sqlcmd` en `src` [V `git grep sqlcmd` en MNG: solo un comentario en `src/GPOS.Migracion/LoginServicio.cs:25`].
- **`IX_BitacoraSeguridad_Empresa` no cambia.** Q8-a ya hace búsquedas de clave para `Motivo`, `Ip` y `Canal`, y agregar `NumeroCaso` y `Urgencia` a su `INCLUDE` no evita esas búsquedas.

**4. DDL exacta.** Sustituye las líneas D1:924-926 y se agrega al bloque 5 de D7-A, después de D1:934:

```sql
-- 5 b. ADR-92, fase CS-1 (CS-02 y CS-03): número de caso y modalidad. Columnas nulas: la historia de la fase A no tiene caso.
IF COL_LENGTH(N'dbo.BitacoraSeguridad', N'NumeroCaso') IS NULL
    ALTER TABLE dbo.BitacoraSeguridad ADD NumeroCaso varchar(30) COLLATE Latin1_General_BIN2 NULL;
IF COL_LENGTH(N'dbo.BitacoraSeguridad', N'Urgencia') IS NULL
    ALTER TABLE dbo.BitacoraSeguridad ADD Urgencia bit NULL;
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_Caso', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_Caso
            CHECK ((NumeroCaso IS NULL AND Urgencia IS NULL)
                OR (NumeroCaso IS NOT NULL AND Urgencia IS NOT NULL
                    AND DATALENGTH(NumeroCaso) BETWEEN 6 AND 30
                    AND NumeroCaso NOT LIKE ''%[^A-Z0-9-]%'' COLLATE Latin1_General_BIN2)));');
-- Sustituye el texto de D1:924-926 (mismo nombre; D1 no está construido, no hay versión anterior que reemplazar).
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_IngresoSuper', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_IngresoSuper
            CHECK (Evento <> ''INGRESO_SUPER''
                OR (Motivo IS NOT NULL AND LEN(LTRIM(RTRIM(Motivo))) >= 10 AND NumeroCaso IS NOT NULL)));');
-- Opcional en D1 (CS-P3): evita un segundo ALTER en CS-2. Los eventos aún no están en el catálogo; el CHECK solo nombra literales.
IF OBJECT_ID(N'dbo.CK_BitacoraSeguridad_CierreUrgencia', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.BitacoraSeguridad ADD CONSTRAINT CK_BitacoraSeguridad_CierreUrgencia
            CHECK (Evento NOT IN (''URGENCIA_CERRADA_RESPONDIDA'', ''URGENCIA_CERRADA_RETICENCIA'')
                OR (NumeroCaso IS NOT NULL AND Urgencia = 1)));');
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BitacoraSeguridad_Caso' AND object_id = OBJECT_ID(N'dbo.BitacoraSeguridad'))
    EXEC (N'CREATE INDEX IX_BitacoraSeguridad_Caso ON dbo.BitacoraSeguridad (NumeroCaso, Id)
            INCLUDE (Evento, Empresa, Urgencia, MomentoUtc) WHERE NumeroCaso IS NOT NULL;');
```

- **Idempotencia:**
  - El lote sigue el patrón de D1: «crear si falta» [V D1:721].
  - **Riesgo:** si alguna base de desarrollo llegara a tener `CK_BitacoraSeguridad_IngresoSuper` con el texto anterior (un borrador de T1-1 aplicado antes de este cambio), el `IF OBJECT_ID … IS NULL` no la actualizaría.
  - **Mitigación propuesta:** en T1-1, comprobar `sys.check_constraints.definition LIKE '%NumeroCaso%'`; si no aparece, `DROP` y `ADD`. La tabla de desarrollo tiene pocas filas, así que es inmediato.
- **Bloqueos y duración:**
  - `ADD` de una columna nula es solo de metadatos en todas las ediciones, Express incluida.
  - Cada `ADD CONSTRAINT … CHECK` (con `WITH CHECK` por omisión) recorre la tabla una vez bajo Sch-M. En desarrollo son pocas filas, así que tarda milisegundos. Pasa con la historia porque toda tiene `NumeroCaso` y `Urgencia` nulos, y `INGRESO_SUPER` es un evento nuevo de DB-7 [V D1:642].
  - Crear el índice filtrado sobre 0 filas con caso también es inmediato.
- **Parámetros (regla 4.1 de D1):**
  - `@numeroCaso varchar(30)` → `DbString { IsAnsi = true, Length = 30 }`;
  - `@urgencia bit`.
  - `RegistrarEvento` [V D1:477-480] suma las dos columnas a su `INSERT`.
- **Normalización en la API (D2):** el servidor pasa el caso a mayúsculas (`ToUpperInvariant`) y quita los espacios de los extremos **antes** de validarlo y de buscar. Con BIN2, una búsqueda en minúsculas no encuentra nada. Si la interfaz convierte o rechaza lo tecleado es tarea del arquitecto de software (CS-P5). **[firma solo si cambia lo que el SUPER ve]**
- **Reverso (se agrega a D1 7.4):** `DROP INDEX IX_BitacoraSeguridad_Caso` y `DROP CONSTRAINT` de `CK_BitacoraSeguridad_Caso` y `CK_BitacoraSeguridad_CierreUrgencia`. Las columnas se conservan, como el resto de las columnas nuevas de la bitácora [V D1:1007].
- **Privilegios:** sin cambios. `gpos_api` conserva su `INSERT` y el `DENY UPDATE, DELETE` sobre la bitácora [V D1:1059].
- **Pruebas (T1-1):**
  - aceptan: `GSF-261020-01` y `ABC123`;
  - rechazan con 547: `gsf-261020-01`, `GSF 261020`, `ÁBC123`, `ABC12` (5 caracteres), uno de 31 caracteres, `ABC123 ` (espacio final), caso sin modalidad, modalidad sin caso, e `INGRESO_SUPER` sin caso;
  - las filas de la fase A no cambian;
  - el plan de la consulta de urgencias abiertas usa `IX_BitacoraSeguridad_Caso` (sin recorrido de `PK_BitacoraSeguridad`).

**5. Consulta de urgencias abiertas (CS-05 y CS-06).** Abierta = un ingreso con urgencia del caso sin un cierre **posterior**. Se compara por `Id`, porque la identidad es monótona y no depende del reloj.

```sql
-- ConsultasAcceso.UrgenciasAbiertas (CS-06). Sin parámetros.
SELECT i.NumeroCaso, MIN(i.MomentoUtc) AS AbiertaDesde, COUNT(DISTINCT i.Empresa) AS Empresas
  FROM dbo.BitacoraSeguridad i
 WHERE i.NumeroCaso IS NOT NULL AND i.Urgencia = 1 AND i.Evento = 'INGRESO_SUPER'
   AND NOT EXISTS (SELECT 1 FROM dbo.BitacoraSeguridad c
                    WHERE c.NumeroCaso = i.NumeroCaso AND c.NumeroCaso IS NOT NULL AND c.Id > i.Id
                      AND c.Evento IN ('URGENCIA_CERRADA_RESPONDIDA', 'URGENCIA_CERRADA_RETICENCIA'))
 GROUP BY i.NumeroCaso
 ORDER BY AbiertaDesde;
```
- Si CS-P1 decide que el cambio de empresa es otro evento, se agrega al `IN`.
- `c.NumeroCaso IS NOT NULL` va escrito a propósito, para que el optimizador use el índice filtrado sin depender de que deduzca el filtro a partir de la igualdad [I].

### Alternativas descartadas
- **`nvarchar(30)` con la intercalación de la instancia:** duplica los bytes, y el `CHECK` en CI aceptaría minúsculas y acentos, salvo que se repita `COLLATE` en cada comparación.
- **`char(13)` ajustado a `GSF-AAMMDD-NN`:** amarra el esquema a una convención que CS-02 dejó abierta (de 6 a 30 caracteres) y que GSF puede cambiar sin firma.
- **Modalidad como `char(1)` (`'C'`/`'U'`) o `varchar`:** una sola columna de 1 byte frente a un `bit`, pero con colación que cuidar y un `CHECK IN` más. Con dos valores firmados, `bit` es lo más simple. Si un día hubiera una tercera modalidad, sería una precisión del ADR con su DDL.
- **Un `CHECK` general («todo evento del SUPER con motivo en `ACCESO`, `MEMBRESIA` o `CUENTA` exige caso»):** se descarta, porque rechazaría las inserciones de las rutas de rechazo. Por ejemplo, `ACCESO_EMPRESA_DENEGADO` con el motivo tecleado y sin caso: el evento se perdería con el EventId 4741 [V D1:485]. Además, las categorías no coinciden con «acciones que piden motivo».
- **La lista de CS-P1 dentro de un `CHECK`:** se descarta mientras CS-P1 esté abierta, porque cada cambio exige `DROP`/`ADD` con un recorrido de la tabla. **Propuesta:** el `CHECK` cubre solo `INGRESO_SUPER`, que es lo cierto. El resto de la lista lo impone la API (D2) con `EventosSeguridad.ExigenCasoSiSuper`, más una prueba por ruta. Cuando la lista se estabilice, puede pasar a un `CHECK` en una versión posterior.
- **Sin índice:** se descarta por el recorrido de unas 16 000 páginas en cada inicio de sesión del SUPER.
- **Índice no filtrado:** tendría una entrada por evento, cerca de un millón en 5 años, para unas 300 útiles.

---

## CS-P3: nombre y categoría del cierre, y comprobación de la urgencia previa

**Recomendación**
1. **Dos eventos en lugar de uno con un resultado aparte:** `URGENCIA_CERRADA_RESPONDIDA` y `URGENCIA_CERRADA_RETICENCIA`. Cada nombre tiene 27 caracteres, solo `A-Z` y `_`, y cumple `CK_CatalogoEventosSeguridad_Evento` [V D1:890].
   - El resultado queda validado por la FK al catálogo [V D1:927-932], sin otra columna. Llegan en CS-2 solo como dos líneas en `EventosSeguridad.Catalogo` (sin DDL) [V D1:635-636].
   - Severidad propuesta: `I` en la primera y `M` en la segunda.
2. **Categoría `ACCESO`** (5 años; la ve el ADMIN [V D1:881]). Así se cumple CS-07: el ADMIN ve el cierre junto al ingreso.
3. **Una fila de cierre por cada empresa** que tuvo un ingreso con urgencia abierto en ese caso, con `Empresa` informada y `EmpresaActua` nula.
   - Así se cumple `CK_BitacoraSeguridad_EmpresaCategoria` (`ACCESO` exige empresa) [V D1:922-923].
   - Así lo ve el ADMIN de cada empresa en Q8-a (filtra por `Empresa`) [V D1:86].
   - No es un acceso a los datos de esa empresa: solo un registro en `GPOS_SYSDATA` [V ADR92:60].
4. **La comprobación va en el servidor, no en la base.** Todo ocurre en una transacción:
   - `sp_getapplock @Resource = N'GPOS.Caso.' + @numeroCaso, @LockMode = 'Exclusive', @LockOwner = 'Transaction'`, que serializa dos cierres simultáneos del mismo caso;
   - la consulta de abiertas del caso (la de CS-P2 filtrada por `@numeroCaso`, que usa el índice filtrado);
   - si no hay ninguna, error de negocio (nombre y código los fija CS-P5);
   - si hay, un `INSERT` por empresa y `COMMIT`.
   - `sp_getapplock` no necesita permisos nuevos (basta ser miembro de `public`) [I].

**Alternativas descartadas**
- **Un solo evento `CASO_URGENCIA_CERRADO` con el resultado en `Detalle` o en `ValorNuevo`:** no se valida con una restricción. Es el mismo defecto que ADR92 descartó para el caso en CS-03 (b) y (c) [V ADR92:56-57].
- **Un solo evento con una tercera columna `ResultadoCierre`:** obliga a un segundo `ALTER` en CS-2, lo que contradice la intención de CS-03 [V ADR92:55].
- **Un disparador `AFTER INSERT` que valide la urgencia previa:** agrega trabajo a **cada** inserción de la bitácora (ruta caliente del inicio de sesión) y complica las rutas de fallo, que escriben fuera de la transacción [V D1:485].
- **Un índice único «un cierre por caso»:** se descarta, porque un caso puede reabrir otra urgencia después de un cierre y necesitar un segundo cierre.
- **Categoría `SISTEMA`:** retiene 2 años y el ADMIN no la ve [V D1:881-882]. No cumple CS-07 ni CS-08.

---

## CS-P4: retención de los eventos del caso y garantía frente a la evidencia del correo

**Recomendación**
1. **Sí: la de `ACCESO`, 5 años**, para `INGRESO_SUPER` y para los dos cierres, con `RetencionAnios` NULL en el catálogo [V D1:881 y :892].
2. **Cómo se garantiza que la bitácora no se purgue antes que la evidencia del correo (DP-4):**
   - **Barrera en la base, que ya existe en D1:**
     - el disparador `TR_BitacoraSeguridad_Purga` rechaza (52002) todo borrado de un evento dentro de su retención [V D1:672-678];
     - el procedimiento de purga usa `ISNULL(c.RetencionAnios, k.RetencionAnios)` [V D1:700];
     - la API no tiene `DELETE` [V D1:1059].
   - **Ajuste sin DDL:** cuando el abogado fije el plazo de la evidencia, si es mayor de 5 años y como mucho de 10, se fija `RetencionAnios` en esos tres eventos del catálogo. Es una línea de C#, aplicada por el `MERGE` del catálogo [V D1:904], sin tocar la categoría (51626 no se activa, porque solo cambia la retención). **[firma: la retención la firma el propietario con el dictamen]**
   - **Si el plazo pasa de 10 años:** hay que ampliar `CK_CatalogoEventosSeguridad_Retencion` (`BETWEEN 2 AND 10`) [V D1:892]. Eso sí es DDL, en una versión de esquema nueva.
   - **Guarda de prueba:** una constante `EventosSeguridad.RetencionMinimaEvidenciaCasoAnios` (hoy 5) y una prueba de arquitectura que exige que la retención efectiva de los eventos con caso sea igual o mayor. Así, cambiar el plazo en un solo sitio hace fallar la compilación de pruebas si el catálogo queda por debajo.
3. **Riesgo residual:** una urgencia que nunca se cierre desaparece de la lista de abiertas cuando se purga su ingreso, a los 5 años. Lo acepto por CS-06, que la muestra en cada inicio de sesión del SUPER.

**Alternativa descartada:** excluir de la purga los ingresos con urgencia abierta. Agrega un `NOT EXISTS` a cada vuelta de la purga por un caso irreal (5 años sin cerrar a la vista del SUPER).

---

## TT-P1: deducción de persona física por `TipoIdentificacion`

**Hechos**
- `cat.Cliente` y `cat.Suplidor` restringen la identificación así [V MNG `src/GPOS.Core/Datos/Empresa/Configuracion/MaeConfiguracion.cs:328-333` y `:400-405`]:
  - `R` = exactamente 9 dígitos;
  - `C` = exactamente 11 dígitos;
  - `P` = de 5 a 20 caracteres;
  - `N` = sin identificación.
- `rrhh.Empleado` solo admite cédula de 11 dígitos o nula [V MNG `CfgConfiguracion.cs:276` y `:285`]. Todo empleado es persona física.
- `ventas.Venta` copia el tipo (`R`, `C` o `P`) [V MNG `VenConfiguracion.cs:28` y `:37`].

**Respuesta a «¿la persona física comerciante se registra con `C` o con `R`?».** Con el esquema actual, **solo puede ir con `C`**: su RNC es su cédula de 11 dígitos y `R` no admite 11 dígitos [V, por el `CHECK`]. Que la DGII asigne a las personas físicas su cédula como RNC y reserve los 9 dígitos para las personas jurídicas es un dato tributario que **no verifiqué** [I].

**Recomendación**
- Mantener la deducción de TT-01 (a): `C`, `P` y `N` = física; `R` = jurídica.
- Una sola implementación:
  - una función en C# (`PersonaFisica.Es(tipo)`) que usan la ruta y la prueba de arquitectura (TT-P6);
  - donde se necesite en SQL, la misma expresión `TipoIdentificacion IN ('C', 'P', 'N')`.
- Sin columna calculada en las tablas temporales (evita otro `ALTER` en `cat.Cliente` y su historia).

**Casos que la deducción puede clasificar mal (mi lectura de datos):**
- **`N` usado para una empresa sin RNC capturado** (prospecto, comercio informal). Daño: se ofrecería «Solicitud del titular» sobre un registro de persona jurídica. Es por exceso, no por defecto, y la ejecuta el ADMIN.
- **`P` usado para una empresa extranjera.** Es un mal uso del tipo; mismo daño, por exceso.
- **RNC de 9 dígitos de una persona física** (registros antiguos, si existieran). Daño **por defecto**: no se atendería a un titular. Es el caso que importa.

**Preguntas que NO respondo (necesitan criterio fiscal, de negocio o legal):**
- **Q-TT1-a, para el contador o el especialista-pos:** ¿existen en la práctica RNC de 9 dígitos asignados a personas físicas? Si existen, la deducción falla por defecto y conviene la marca explícita de TT-01 (c).
- **Q-TT1-b, para el especialista-pos:** ¿los clientes registran empresas con `N` o con `P`? Si es frecuente, basta un aviso en la interfaz («este registro parece de una empresa»). No justifica la marca.
- **L-03 (abogado):** si la persona física comerciante está protegida. Ya es pregunta de ADR92:20.

**Alternativa descartada:** la marca explícita de TT-01 (c) **ahora**. Es una columna en dos tablas temporales y una decisión por registro, sin evidencia de casos que la deducción clasifique mal. Queda como salida si Q-TT1-a sale afirmativa. Costo, si hiciera falta: de 0,1 a 0,2 sp (columna `bit NULL` derivada al migrar, interfaz y prueba) [I].

---

## TT-P2: historial temporal de `cat.Cliente` y `cat.Suplidor`, y `rrhh.Empleado`

**Hecho que cambia el análisis (hallazgo, severidad Alta para TT-03):**
- `cat.Cliente` y `cat.Suplidor` son temporales, con `HISTORY_RETENTION_PERIOD = 10 YEARS` [V MNG `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesMae.cs:20-21`; `MaeConfiguracion.cs:335-340` y `:406-410`].
- Por eso, **el mismo `UPDATE` que anonimiza en TT-03 (i) copia la fila anterior, con los teléfonos, correos y dirección, a `ClienteHistorial`**, donde se queda 10 años más.
- Es decir: con el historial tratado como «bloqueo», la supresión **no retira** esos datos de la base. Los mueve al historial. TT-04 ya lo admite como riesgo residual («por omisión no se modifican»), pero conviene que el propietario sepa que la supresión **no retira** los datos y solo los saca de la vista del maestro.

**Recomendación**
1. **Por omisión, hasta L-03: bloqueo con acceso restringido.**
   - La API no expone el historial de un registro con `TitularBloqueadoEn` informado (ver TT-P5) salvo por una ruta de auditoría, con privilegio y bitácora.
   - Hoy no encontré lecturas del historial en `src/GPOS.Core/Consultas` ni en `src/GPOS.Api` [V `git grep ClienteHistorial|SuplidorHistorial` en MNG: solo el mapeo de EF].
2. **Si el abogado exige anonimizar el historial:** un **verbo de `GPOS.Migracion`** (`titulares --anonimizar-historial --empresa <código>`), ejecutado por la identidad de migración o de mantenimiento, **nunca por `gpos_api`** (ADR-82, RG-14).
   - Lo dispara el ADMIN como tarea programada o un técnico.
   - En una transacción, con `TABLOCKX` sobre la tabla:
     - `ALTER TABLE cat.Cliente SET (SYSTEM_VERSIONING = OFF)`;
     - `UPDATE cat.ClienteHistorial` de los campos de TT-03 (i) en las filas de los registros bloqueados que aún los tengan;
     - `ALTER TABLE … SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = cat.ClienteHistorial, DATA_CONSISTENCY_CHECK = ON, HISTORY_RETENTION_PERIOD = 10 YEARS))`;
     - lo mismo para `Suplidor`.
   - **Cuidado:** si no se repite `HISTORY_RETENTION_PERIOD` al reactivar el versionado, la retención vuelve a infinita [I, documentación de SQL Server]. El proyecto ya apaga y enciende el versionado en sus migraciones [V MNG `SqlMigracionesOla4b.cs:522`].
   - **Sin tabla de pendientes:** el verbo deduce los pendientes (registros bloqueados con algún campo personal no nulo en el historial).
   - **Bloqueo:** Sch-M sobre el maestro, de milisegundos a segundos. Se ejecuta fuera del horario de operación.
   - **Costo:** el de ADR92:88 (de 0,2 a 0,4 sp).
3. **`rrhh.Empleado` no es temporal** [V MNG `CfgConfiguracion.cs:274-278`, sin `IsTemporal`]. La API anonimiza directamente con `UPDATE`, sin residuo en la tabla. Quedan los respaldos (TT-04).

**Alternativa descartada:** un procedimiento firmado con certificado (`EXECUTE AS` o firma de módulo) que deje a la API apagar el versionado. Da a la identidad de la API una capacidad DDL indirecta, contra RG-14, para una operación rara que admite lote.

---

## TT-P3: inventario de datos personales de personas físicas fuera de los tres maestros

| Lugar | Datos | Evidencia | Propuesta |
|---|---|---|---|
| `ventas.Venta` (copia en el documento) | `NombreCliente`, `IdentificacionCliente`, `TelefonoCliente`, `CorreoCliente` | [V MNG `VenConfiguracion.cs:34-39`] | **Bloqueo** (TT-04, ADR-74). Si L-04 pide anonimizar el teléfono y el correo, es una precisión aparte |
| `caja.CajaChica` | `Beneficiario`, `RncCedula` | [V MNG `CmpConfiguracion.cs:161-162`] | **Bloqueo**: es un documento con soporte fiscal |
| `cat.ClienteHistorial`, `cat.SuplidorHistorial` | Todos los campos del maestro | TT-P2 | **Bloqueo** por omisión; anonimización por verbo si L-03 la exige |
| Registro del 606 | `RncCedula` | [V MNG `FisConfiguracion.cs:287-292`] | **Bloqueo** (fiscal) |
| `com.Comensal` (ADR-88 y ADR-128) | Nombre, código de empleado, foto cifrada con consentimiento | [V `ADR-088.md:18` y `:32-34`; `ADR-128.md:22`, sin cédula] | **Fuera de TT por ahora**: ya tiene su régimen (retirar el consentimiento borra la foto; la foto se borra a los 90 días de la baja). Cuando se construya (entrega 3), su ficha debe sumarse a TT-02 y TT-03 (el nombre). Lo marco para el especialista-pos |
| Pasaporte Duty Free (ADR-115) | Número sellado, huella HMAC y últimos 4 | [V `ADR-115.md:16` y `:40`] | **Bloqueo**: conservación de 10 años con borrado criptográfico por llave anual. Ya cumple el fin de conservación sin acción manual |
| Adjuntos (ADR-67) | Contenido y nombre de archivo | [V `ADR-067.md:19-20`] | **Supresión** con el motivo «Dato personal» (papelera y lápida «[retirado]»), salvo soporte fiscal (precisión del 2026-10-07, `ADR-067.md:78`), que va como **bloqueo** |
| `audit.Bitacora` y `dbo._LOG` de la empresa | `Usuario`, `Motivo` libre y `Detalle` JSON (pueden contener nombres) | [V MNG `CfgConfiguracion.cs:329-343`; `SqlMigracionesCfg.cs:15`, `DENY UPDATE, DELETE`] | **Bloqueo**: son de solo inserción. Riesgo conocido: el `Detalle` de adjuntos llevaba el nombre del archivo (revisión de seguridad de adjuntos, `docs/seguridad/2026-10-05-revision-adjuntos-documentos.md:437`) |
| `BitacoraSeguridad` (`GPOS_SYSDATA`) | Códigos de usuario, IP y motivo | D1 | **Fuera de TT**: son cuentas de usuarios del sistema, no titulares de clientes, suplidores o empleados. Retención de 5 años (L-12) |
| Respaldos | Todo | — | **Bloqueo** hasta que venza su retención (TT-04) |

**Alternativa descartada:** incluir los documentos en la supresión. Toca documentos sellados (ADR-74) y la conservación fiscal de 10 años.

**Pendiente de verificación [I]:** no recorrí las 128 tablas de empresa una por una; busqué columnas `Telefono*`, `Correo*`, `Direccion*`, `Cedula*`, `Contacto` y `NombreCliente`. Las cotizaciones, los pedidos y los conduces, si copian datos del cliente, siguen la regla de `ventas.Venta`. El especialista-pos fija la lista exacta de TT-02.

---

## TT-P4: ¿en qué bitácora va el evento de TT-06 y con qué retención?

**Recomendación: en `audit.Bitacora` de la empresa, en la misma transacción que el cambio.**
- **Motivo:** el cambio ocurre en la base de la empresa. `audit.Bitacora` está en esa misma base, así que el registro es atómico con el cambio. `BitacoraSeguridad` está en `GPOS_SYSDATA`: exigiría una transacción entre dos bases o un registro posterior no atómico, que es justo la razón por la que ADR-37 descartó la `Log` para los eventos de seguridad [V `ADR-037.md:18`].
- **Forma:**
  - `Accion` = `TITULAR_RECTIFICADO` o `TITULAR_SUPRIMIDO`;
  - `Entidad` = `Cliente`, `Suplidor` o `Empleado`;
  - `EntidadId` = el `Id` del registro (lo usa `IX_Bitacora_Entidad`) [V MNG `CfgConfiguracion.cs:341`];
  - `Motivo` = el motivo;
  - `Detalle` = JSON (`CK_Bitacora_Detalle` exige `ISJSON`) [V `:329`] con `{"FechaRecepcion":"AAAA-MM-DD","Codigo":"…","Campos":["Telefono","Correo",…]}`, **sin valores**.
- **Si el actor es el SUPER:** su acceso ya consta en `BitacoraSeguridad` (`INGRESO_SUPER` con caso). No se duplica.
- **Retención:** `audit.Bitacora` no tiene purga hoy [V: `git grep` sin resultados de purga sobre `audit.Bitacora` en MNG]. Propongo dejar escrito que estas dos acciones **se conservan al menos mientras exista el registro bloqueado y nunca menos de 10 años**: son la prueba de que el responsable cumplió. Si un día se diseña una purga (por ejemplo, el archivado por períodos en Express), estas acciones quedan fuera de ella dentro de ese plazo. **[firma: la retención; sujeta al abogado]**
- **Riesgo residual:** el `Motivo` es texto libre y el ADMIN podría escribir en él el dato que suprime. Mitigación de interfaz: un aviso junto al campo. No se puede validar en la base.

**Alternativa descartada:** `BitacoraSeguridad`. No es atómica con el cambio, mezcla actos del responsable (el cliente) con la seguridad de la plataforma, y su retención de 5 años sería menor que la conservación del registro bloqueado.

---

## TT-P5: fin de la conservación de un registro bloqueado y quién dispara la anonimización final

**Recomendación**
1. **Una sola columna nueva por maestro:** `TitularBloqueadoEn datetime2(3) NULL` en `cat.Cliente`, `cat.Suplidor` y `rrhh.Empleado`.
   - Va por migración de EF. En las tablas temporales, `ADD` de una columna nula se propaga al historial [I].
   - Restricción: `CHECK (TitularBloqueadoEn IS NULL OR Inhabilitado = 1)`.
   - Un disparador o la ruta impiden volver a `Inhabilitado = 0` con la marca informada (TT-03: «no se puede reactivar»).
   - Es la marca «Bloqueado por solicitud del titular» de TT-03 (ii).
2. **Sin fecha de vencimiento guardada:** el fin de la conservación se **calcula** cuando se va a usar.
   - Fórmula: `ConservarHasta = DATEADD(year, 10, MAX(fecha de los documentos que lo referencian))`, sobre las FK de ventas, compras, CxC y CxP, más `TitularBloqueadoEn` como piso.
   - **Motivo:** si la fecha se guardara, quedaría desfasada con cualquier documento que todavía se pueda crear sobre el registro (por ejemplo, una nota de crédito de una factura anterior).
3. **Quién lo dispara:** el **ADMIN** (el cliente es el responsable), desde un listado «Registros bloqueados con conservación vencida» que calcula la fecha.
   - La anonimización del nombre y del documento la hace la API en el maestro.
   - La del historial temporal (que el mismo `UPDATE` vuelve a llenar, ver TT-P2) la hace el verbo de TT-P2.
   - Las copias en los documentos vencidos siguen la política de archivado por períodos, no esta acción.
   - Fase posterior, como dice ADR92:26.

**Preguntas que no respondo (criterio fiscal o contable):**
- **Q-TT5-a, para el contador:** ¿los 10 años del Código Tributario (art. 50 h) se cuentan desde la fecha del comprobante o desde el cierre del ejercicio o la declaración?
- **Q-TT5-b, para el especialista-pos o el contador:** ¿qué documentos cuentan como «comprobante que lo usa»? ¿Solo los fiscales, o también las cotizaciones y los pedidos? ¿Una nota de crédito posterior al bloqueo es un «documento nuevo» prohibido por TT-03?

**Alternativas descartadas**
- **Tarea automática que anonimiza al vencer:** destrucción irreversible sin decisión humana, con un cálculo que depende de Q-TT5-a.
- **Guardar `ConservarHasta` al bloquear:** se desfasa (punto 2).

---

## Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-1 | La supresión de TT-03 en las tablas temporales deja en el historial, 10 años, los datos que pretende retirar | **Alta** (expectativa del cliente y del propietario) | Comunicarlo en la firma de la fase TT; verbo de TT-P2 si L-03 lo exige |
| R-2 | `CK_BitacoraSeguridad_IngresoSuper` con el texto anterior en una base de desarrollo no se actualiza con «crear si falta» | Baja | Comprobación de `definition` en T1-1 (CS-P2, idempotencia) |
| R-3 | Un escritor de la bitácora con `QUOTED_IDENTIFIER OFF` falla por el índice filtrado (1934) | Baja | Solo SqlClient escribe hoy; prueba de integración del `INSERT` |
| R-4 | La deducción `R` = jurídica deja fuera a un titular con RNC de 9 dígitos | Media hasta Q-TT1-a | Marca explícita de TT-01 (c) si Q-TT1-a sale afirmativa |
| R-5 | La lista de CS-P1 solo la impone la API (salvo `INGRESO_SUPER`) | Baja | Prueba por ruta; `CHECK` en una versión posterior cuando la lista se estabilice |

## Decisiones candidatas a ADR (precisiones de ADR-92; las prepara el Maestro)
1. Columnas `NumeroCaso varchar(30) COLLATE Latin1_General_BIN2` y `Urgencia bit`; `CK_BitacoraSeguridad_Caso`; `CK_BitacoraSeguridad_IngresoSuper` ampliada; `IX_BitacoraSeguridad_Caso` filtrado. Descartadas: `nvarchar` CI, `char(13)`, `CHECK` general por categoría y sin índice.
2. Cierre con dos eventos (`URGENCIA_CERRADA_RESPONDIDA` y `URGENCIA_CERRADA_RETICENCIA`) en `ACCESO`, una fila por empresa, comprobado en el servidor con `sp_getapplock`. Descartadas: un evento con el resultado en `Detalle`, una tercera columna y un disparador.
3. El evento de TT-06 va en `audit.Bitacora` de la empresa, atómico con el cambio. Descartada: `BitacoraSeguridad`.
4. Anonimización del historial temporal solo por un verbo de `GPOS.Migracion`, nunca por `gpos_api`. Descartada: un módulo firmado.
5. `TitularBloqueadoEn` en los tres maestros y fin de conservación calculado, no guardado.

## Supuestos
- S-1: CS-P1 (arquitecto de software) decidirá si el cambio de empresa es `INGRESO_SUPER` u otro evento. Si es otro, se agrega a `CK_BitacoraSeguridad_IngresoSuper` y a la consulta de urgencias abiertas.
- S-2: los volúmenes (300 filas con caso en 5 años; 16 000 páginas de bitácora) son inferidos de ADR92:90 y `ADR-037.md:18`, ±50 %. No ejecuté nada contra una base.
- S-3: el comportamiento de `LIKE` con rangos en intercalaciones no binarias, el de `HISTORY_RETENTION_PERIOD` al reactivar el versionado y el de `ADD` de una columna en las tablas temporales es conocimiento del motor, no probado aquí [I]. Las pruebas de T1-1 y de la fase TT lo confirman.

## Entregas a otros agentes
- **arquitecto-software (A o B):** CS-P1 (lista y si el cambio de empresa es `INGRESO_SUPER`); CS-P5 (normalizar a mayúsculas y nombre del error del cierre sin urgencia abierta); CS-P6 (la ruta de cierre usa la transacción con `sp_getapplock`); CS-P7 (texto de `Urgencia`).
- **especialista-pos:** Q-TT1-b, Q-TT5-b, la lista de TT-02 y la ficha de `com.Comensal` en TT.
- **contador (vía el propietario):** Q-TT1-a y Q-TT5-a.
- **abogado (vía el propietario):** L-03 y L-04 (historial temporal y copias), y la retención de TT-P4 y CS-P4.
- **desarrollador-backend (B, T1-1):** el bloque 5 b de CS-P2, la comprobación de `definition`, el reverso y las pruebas.

## Resumen (8 líneas)
1. CS-P2: `NumeroCaso varchar(30) COLLATE Latin1_General_BIN2 NULL` y `Urgencia bit NULL` en `BitacoraSeguridad`, en la DDL de D1 (bloque 5 b, DDL exacta incluida).
2. Restricciones: `CK_BitacoraSeguridad_Caso` (pareja caso y modalidad, de 6 a 30 caracteres con `DATALENGTH`, `[A-Z0-9-]` en BIN2) y `CK_BitacoraSeguridad_IngresoSuper` ampliada (mismo nombre).
3. Índice filtrado `IX_BitacoraSeguridad_Caso (NumeroCaso, Id) WHERE NumeroCaso IS NOT NULL`: unas 300 filas; evita recorrer unas 16 000 páginas en cada inicio de sesión del SUPER.
4. CS-P3: dos eventos de cierre en `ACCESO`, una fila por empresa, comprobados en el servidor con `sp_getapplock`; `CHECK` del cierre opcional ya en D1.
5. CS-P4: 5 años de `ACCESO`; si el abogado pide más, `RetencionAnios` por evento en el catálogo, sin DDL hasta 10 años, más una prueba de arquitectura.
6. TT-P1: la deducción se sostiene con el esquema (`R` = 9 dígitos); Q-TT1-a y Q-TT1-b quedan para el contador y el especialista-pos.
7. TT-P2 (hallazgo Alto): anonimizar una tabla temporal copia los datos al historial durante 10 años; por omisión, bloqueo; si L-03 lo exige, verbo de `GPOS.Migracion` sin DDL para la API. `Empleado` no es temporal.
8. TT-P3: inventario con bloqueo o supresión por lugar; TT-P4: `audit.Bitacora` de la empresa, atómica; TT-P5: `TitularBloqueadoEn` y fin de conservación calculado, disparado por el ADMIN (Q-TT5-a y Q-TT5-b al contador).

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\adr92-respuestas-datos-2026-10-21.md`
- Supuestos: S-1 a S-3
- Decisiones candidatas a ADR: las 5 de la sección «Decisiones candidatas a ADR»
- Entregas a otros agentes: arquitecto-software (CS-P1, CS-P5 a CS-P7); especialista-pos (Q-TT1-b, Q-TT5-b, TT-02 y comensales); contador (Q-TT1-a y Q-TT5-a); abogado (L-03, L-04 y retenciones); desarrollador-backend de B (bloque 5 b en T1-1)
- Próximo paso recomendado: que B integre CS-P2 en la DDL de D1 antes del 2026-11-02 y lleve R-1 (historial temporal) a la hoja de firma de la fase TT.
