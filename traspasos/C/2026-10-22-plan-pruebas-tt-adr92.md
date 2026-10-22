```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 5 del aviso 2026-10-22: plan de pruebas de TT-02/TT-03 de ADR-92 y de la prueba de arquitectura que fija CamposPersonalesTitular.json)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (esquema de destino; TT lo construye B con L1b desde 2026-11-16); fuentes en `origin/master`
Estado: Abierto (plan, sin código; adelantado respecto de la fecha 16-nov acordada)
```

# Plan de pruebas de TT (ADR-92): rectificar, suprimir y la prueba de arquitectura de la lista de campos

**Fuentes leídas:** (1) `traspasos/B/2026-10-22-respuesta-especialista-pos-tt.md` completa; (2) ADR-92 en `origin/master:docs/adr/ADR-092.md`, solo el bloque TT (cláusulas 1 a 6) y la precisión del 2026-10-22; (3) la hoja `origin/master:docs/decisiones/2026-10-22-hoja-firma-adr92-precisiones.md` (F-4 a F-9, P-1 a P-4, Q-TT1-a, abiertos); (4) el aviso de B. **No leí código vivo** (ver §10). Los nombres de tabla, columna, ruta y línea son los que da el especialista-pos o el ADR; los marco «dado», no «verificado».

**Clave.** Tipo: SQL = necesita base `GPOS_TEST_*`; HTTP = API en proceso con base; TX = prueba transaccional (fallo inyectado, atomicidad); ARQ = prueba de arquitectura sobre fuentes, JSON, ensamblados o esquema. **Falla si…** es la mutación mental: la línea de producción que, quitada o cambiada, debe volver rojo el test. **Dependencia:** `—` = se puede escribir ya con lo firmado; `[D-n]` = depende de una decisión abierta de la sección 1 (la prueba se escribe, pero el resultado esperado puede cambiar).

## 0. Resumen

- 95 pruebas nuevas en 8 grupos (A a H; conteo por prefijo de ID: ARQ 14, SQL 47, HTTP 32, TX 2; el prefijo es la familia, el tipo real está en la columna «Tipo»); 54 llevan alguna dependencia `[D-n]`, de las cuales unas 30 solo dependen de nombres o códigos sin definir (D-9) y el resto de decisiones de fondo (D-1 a D-7, D-10).
- Las cuatro pruebas de arquitectura de F-4 son el grupo A (ARQ-01 a ARQ-04); les sumo diez que salen de la respuesta del especialista (exclusión de `GENERICO`, columnas de texto sin clasificar, espejo heredado, `comensales`).
- Hallazgos del plan (§9): cuatro huecos del texto firmado o propuesto que hacen ambiguo el resultado esperado de al menos cinco pruebas.

## 1. Decisiones abiertas de las que cuelgan pruebas

| Id | Decisión abierta | Estado | Pruebas afectadas |
|---|---|---|---|
| D-1 | ¿Un registro bloqueado admite notas de crédito/débito que modifican un comprobante anterior, devoluciones, recibos, aplicaciones de saldo, cheque devuelto, pago de CxP? | El especialista **recomienda permitir** (§3.2) y propone redacción de TT-03; **no firmada, no verificada en código** (su pendiente 11) | HTTP-30 a HTTP-37 |
| D-2 | `PuenteMae`: ¿rectificar y suprimir escriben también la copia heredada (`Clientes`, `Suplidores`) o TT espera a que se elimine el puente? | Hallazgo 3 del especialista; sin decisión | SQL-20 a SQL-23, ARQ-09 |
| D-3 | Qué documentos cuentan como «comprobante que lo usa» (Q-TT5-b) y cómo se cuenta el plazo de 10 años (Q-TT5-a, contador) | Propuesta del especialista, sin firma | SQL-14, SQL-15, HTTP-26 |
| D-4 | Lista final de campos que se anonimizan (`NombreComercial`, `Contacto`, `PaginaWeb`, `Nota`): L-04 del abogado con el contador | Abierta | ARQ-01, SQL-10 a SQL-13 |
| D-5 | F-9: qué datos son «estrictamente necesarios» para avalar la deuda; quién completa la supresión aplazada; cómo se impide el uso ajeno al cobro | Propuesta de B en la hoja, **no firmada** | SQL-16 a SQL-19, HTTP-27 a HTTP-29 |
| D-6 | Deducción de persona física por `TipoIdentificacion` (TT-P1) hasta el maestro de ADR-161 | Lectura de B, no firmada; ADR-161 cambia la regla | ARQ-04, SQL-30 a SQL-32 |
| D-7 | Cuarta entrada `comensales` | Diseño, no código; entrega 3, tramo 3d | ARQ-12 a ARQ-14 y el grupo H |
| D-8 | Contenido de `CamposPersonalesTitular.json` | Lo **propone** el especialista (§1.7); B debe firmarlo antes de construir TT | Todo el grupo A |
| D-9 | Códigos de error: solo `CAMPO_NO_PERSONAL` está dado | Sin definir | Todas las HTTP; uso nombres simbólicos entre corchetes |
| D-10 | ¿Se puede rectificar un registro ya bloqueado? ¿Rectificar purga también el historial? | Sin texto | SQL-05, SQL-24, HTTP-12 |

## 2. Grupo A · Pruebas de arquitectura que fijan `CamposPersonalesTitular.json` (F-4, TT-05)

Las cuatro de F-4 son ARQ-01 a ARQ-04. Leen el JSON del repositorio (con `version`), el mapeo de EF (largos, CP-169), el esquema SQL de `database/` y las rutas registradas.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| ARQ-01 | **Lista de campos versionada.** El JSON tiene `version` entera, no vacía; el conjunto `{rectificar, anonimizarAlSuprimir, conservarBloqueado}` por maestro coincide con una **copia dorada** (`CamposPersonalesTitular.dorado.json`) y cualquier cambio exige subir `version` y el dorado a la vez. Cada campo existe como columna del maestro con el largo del mapeo | ARQ | alguien agrega o quita un campo del JSON sin versión ni dorado; o el campo no existe en la tabla (typo) | D-4, D-8 |
| ARQ-02 | **Sin campos extra.** Para cada ruta `/api/titulares/{maestro}/{codigo}/rectificar` y `/suprimir`, los DTO aceptan **exactamente** las propiedades de `rectificar` (más motivo, fecha de recepción, apoderado/poder, código de confirmación en suprimir). Por reflexión: ninguna otra propiedad pública; con `JsonSerializerOptions.UnmappedMemberHandling = Disallow`. En ejecución: un cuerpo con `LimiteCredito` devuelve 400 `CAMPO_NO_PERSONAL` y no cambia la base | ARQ + HTTP | el DTO gana una propiedad (p. ej. `LimiteCredito`, `TipoIdentificacion`, `Codigo`) o el deserializador ignora silenciosamente lo desconocido | D-8 |
| ARQ-03 | **Clase `Esencial` y lista aprobada.** Las tres rutas (GET, rectificar, suprimir) por cada uno de los tres maestros están en la lista aprobada de L1b con clase `Esencial`; **ninguna otra** ruta de edición de maestros lo está (la edición normal sigue `Operativa`); el privilegio exigido es `solicitudestitulares`, grupo «Especiales» | ARQ | alguien clasifica `Esencial` la edición normal de clientes (abre la edición de maestros en solo consulta, lo que la ley no exige y F-4 evita); o la ruta de TT queda `Operativa` y se bloquea en `SoloConsulta` | — |
| ARQ-04 | **Solo personas físicas.** El filtro `personaFisica` del JSON (`TipoIdentificacion IN ('C','P','N')` en cliente y suplidor; `siempre` en empleado) se aplica en el servidor: la ruta no consulta `TipoIdentificacion` del DTO, la decide la consulta a la base. Prueba de código: ningún DTO de TT tiene propiedad `EsPersonaFisica`/`TipoIdentificacion`/`Tipo` | ARQ | el tipo viaja en el pedido (F-4: «lo decide el servidor, no el pedido») | D-6 |
| ARQ-05 | **Intersección vacía.** `rectificar ∩ nunca = ∅` y `anonimizarAlSuprimir ∩ conservarBloqueado = ∅` y `conservarBloqueado ⊆ rectificar` (nombre y documento) por maestro | ARQ | un campo de dinero, crédito o numeración (`LimiteCredito`, `TerminoId`, `Codigo`) entra a `rectificar` | — |
| ARQ-06 | **Toda columna de texto está clasificada.** Cada columna `varchar`/`nvarchar` de `cat.Cliente`, `cat.Suplidor`, `rrhh.Empleado` (leídas del esquema real, no del JSON) aparece en `rectificar`, `anonimizarAlSuprimir`, `conservarBloqueado` o `nunca`. Una columna de texto nueva rompe la prueba y obliga a decidir (lo propuso el especialista) | ARQ | se agrega `Whatsapp`, `Direccion2`, `Observaciones` y nadie decide si es dato personal | — |
| ARQ-07 | **Alias del contrato.** El mapa `alias` (`Telefono`→`Telefono1`, `Movil`→`Mobil`, `Correo`→`CorreoElectronico1`, `Correo2`→`CorreoElectronico2`, `Identificacion`→`RNC`) coincide con los nombres reales del DTO de `/api/maestros/clientes` y `/suplidores` | ARQ | el contrato de maestros renombra una propiedad y TT deja de rectificar ese campo sin avisar | — |
| ARQ-08 | **Exclusión de `GENERICO` por constante, no por texto.** El JSON declara la exclusión; la ruta la lee y además usa la constante del dominio que da el especialista (`Cliente.CodigoContado`). La prueba comprueba que la cadena del JSON es igual a esa constante y que en cada tabla de datos iniciales (`database/*.sql`) toda fila de cliente/suplidor/empleado sembrada con `TipoIdentificacion IN ('C','P','N')` figura en `excluir` | ARQ | alguien siembra otro cliente de sistema (p. ej. «CLIENTE RAPIDO») con tipo `N` y no se excluye; o se renombra `GENERICO` y el JSON queda atrás | — |
| ARQ-09 | **Espejo heredado.** Mientras exista la clase `PuenteMae` (por símbolo en el ensamblado) el JSON debe tener `espejoHeredado` en clientes y suplidores con sus columnas extra (`Telefono3`, `CorreoElectronico3`, `IdDireccion`); cuando `PuenteMae` ya no exista, el JSON **no** debe tenerlo (`vigenteHasta`). Es un centinela de dos sentidos | ARQ | el puente sigue y TT no lo conoce (los datos suprimidos sobreviven en `Clientes`), o el puente desapareció y queda un camino muerto | D-2 |
| ARQ-10 | **Columnas personales del espejo.** Para cada columna de texto de `Clientes`/`Suplidores` heredadas que `PuenteMae` copia, la columna del modelo nuevo equivalente está clasificada; las que no tienen equivalente (las tres extra) figuran en `espejoHeredado.extra` | ARQ | `PuenteMae` empieza a copiar un campo nuevo (p. ej. `Celular2`) no clasificado | D-2 |
| ARQ-11 | **`TitularBloqueadoEn` solo lo escribe TT.** Búsqueda por símbolos: únicamente los servicios de `/api/titulares` asignan la propiedad; la API de maestros normal no (así «reactivar» no es una vía) | ARQ | el editor normal de maestros puede poner o quitar la marca | — |
| ARQ-12 | **Entrada `comensales` pendiente, no silenciosa.** El JSON contiene `comensales` con `estado = "pendiente-entrega-3"`; mientras el esquema `com` **no** exista la prueba pasa. Si `com.Comensal` existe en el modelo y el estado sigue «pendiente», **falla** (centinela: obliga a activar el grupo H) | ARQ | se construye `com.Comensal` y nadie amplía TT | D-7 |
| ARQ-13 | **`com.Comensal` sin identificadores ajenos al diseño.** Cuando el esquema `com` exista: `com.Comensal` y `com.ComensalAsignacion` no tienen columnas de cédula, teléfono, correo, dirección ni fecha de nacimiento (ADR-44/88: el padrón no las lleva). Su aparición obliga a ampliar TT y la hoja | ARQ | alguien agrega `Cedula` al comensal sin pasar por ADR | D-7 |
| ARQ-14 | **Toda columna de texto de `com.Comensal` y `com.ComensalAsignacion` está en el JSON** (mismo criterio que ARQ-06) | ARQ | `Departamento` o un campo nuevo se escapa de la anonimización | D-7 |

## 3. Grupo B · Rectificar (TT-02): servicio

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| SQL-01 | Rectificar cada campo permitido de **cliente** (12 campos de `rectificar`, uno por caso) con un cliente `C`: cambia ese campo y **solo** ese; `Version` y `ModificadoEn/Por` avanzan; el resto de columnas queda idéntico (comparación de la fila completa antes/después) | SQL | el servicio hace un `UPDATE` de todo el DTO con valores por omisión y borra otros campos | — |
| SQL-02 | Igual para **suplidor** (mismos 12) y para **empleado** (`Nombres`, `Apellidos`, `Cedula`, `Telefono`, `Correo`) | SQL | alguna columna se mapea mal entre maestros (p. ej. `Movil` en el suplidor) | — |
| SQL-03 | **Nunca el negocio**: con un cliente con crédito, lista de precios, vendedor, término y saldo; tras rectificar, `LimiteCredito`, `ListaPrecioId`, `VendedorId`, `TerminoId`, `TipoComprobanteCodigo`, `Codigo` son idénticos. Idem las retenciones del suplidor (`RetieneIsr`, `PorcRetencionIsr`) y `ComisionVentas`/`UsuarioSistemaId` del empleado | SQL | un DTO compartido arrastra esos campos | — |
| SQL-04 | **Comprobantes emitidos intactos (TT-04).** Cliente con factura emitida, 606 y nota previa: tras rectificar nombre, documento, teléfono y correo, `ventas.Venta` (`NombreCliente`, `IdentificacionCliente`, `TelefonoCliente`, `CorreoCliente`) y el registro de 606/607 no cambian | SQL | el servicio propaga el cambio a las copias de los documentos sellados (ADR-74) | — |
| SQL-05 | **Historial al rectificar.** Tras rectificar un teléfono en cliente (temporal), `cat.ClienteHistorial` contiene la fila con el **valor anterior**. La prueba documenta y fija el comportamiento decidido (ver D-10): si se decide que sobreviva hasta el verbo de F-5, se afirma su presencia; si se decide purgarlo, se afirma su ausencia | SQL | el comportamiento cambia sin decisión | D-10 |
| SQL-06 | **Duplicado de identificación** (regla 1.4.1): rectificar `Identificacion` a un RNC/cédula ya usado por otro registro de la misma empresa → rechazo; en `Empleado`, `UX_Empleado_Cedula` filtrado lo respalda; el mismo número en otro registro **bloqueado** también choca | SQL | la ruta de TT salta la validación del alta (SRV:166-169, dado) | — |
| SQL-07 | **El tipo resultante sigue en {C,P,N}** (regla 1.4.2): `C`→9 dígitos (sería `R`) → rechazado, registro sin cambio; `C`→20 caracteres (`P`) → acepta; `N` (sin número)→11 dígitos → acepta (`C`); `N`→9 dígitos → rechazado. El servidor recalcula `TipoIdentificacion` (el valor del pedido, si viene, se ignora o se rechaza) | SQL | la rectificación convierte en jurídica a la persona y la saca de la protección | — |
| SQL-08 | **No vaciar si el comprobante exige RNC** (regla 1.4.3): cliente con `TipoComprobanteCodigo` B01/E31, B14/E44 o B15/E45, rectificar `Identificacion` a vacío → rechazado con el mismo mensaje del alta. Con B02/E32 → acepta (y el tipo pasa a `N`) | SQL | la ruta permite dejar sin documento a un cliente de crédito fiscal | — |
| SQL-09 | **Efecto en índices y unicidad:** rectificar dos registros al mismo documento en dos pedidos concurrentes (barrera): uno gana, el otro falla; no hay interbloqueo (ADR-45: orden de bloqueos, aquí documentos y maestro) | SQL (concurrencia) | falta el chequeo atómico del duplicado | — |
| SQL-10 | **Parámetros con tipo y largo (ADR-50):** el texto se envía como `varchar(n)` del largo de la columna. Prueba de plan: la consulta por `Identificacion` y por `Codigo` usa `Index Seek` (sin conversión implícita) con `showplan` | SQL | un parámetro `nvarchar` degrada a scan y provoca interbloqueos | — |
| SQL-11 | **Largos:** rectificar con valor de largo máximo acepta; con largo +1 → 400 sin cambio (150, 30, 200, 250, 100 según columna) | SQL | el DTO no valida y el `UPDATE` trunca o falla tarde | — |
| HTTP-01 | **Campos requeridos del acto (TT-02):** sin motivo → 400; sin fecha de recepción → 400; fecha futura → 400 [pregunta 6]; fecha de hace 30 días hábiles → 200 y la respuesta trae el indicador «plazo vencido» (solo informativo, no bloquea) | HTTP | el plazo de 10 días hábiles pasa a bloquear (TT-02: «el sistema no bloquea por plazo») | D-9 |
| HTTP-02 | **Apoderado y poder (P-2):** con apoderado informado, el acto lo registra; el adjunto del poder va por el mecanismo de ADR-67; sin apoderado, procede. El poder sin datos del apoderado → 400 | HTTP | el registro del apoderado se omite o se vuelve obligatorio | D-9 |
| HTTP-03 | **Campo extra:** cuerpo con `LimiteCredito`, `Codigo`, `TipoIdentificacion`, `Inhabilitado`, `TitularBloqueadoEn`, `Version` (uno por caso) → 400 `CAMPO_NO_PERSONAL`; la base no cambia | HTTP | un campo sensible pasa al `UPDATE` | — |
| HTTP-04 | **Cuerpo vacío o sin ningún campo personal** → 400 (no hay un `UPDATE` vacío que sí escriba la bitácora) | HTTP | se registra un acto de rectificación que no cambió nada | — |
| HTTP-05 | **Concurrencia de versión:** rectificar con `Version` obsoleta → 409; sin pérdida de la edición normal intermedia | HTTP | el `rowversion` no se comprueba | — |

## 4. Grupo C · Suprimir (TT-03): servicio

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| SQL-12 | **Anonimización de cliente:** tras suprimir, las columnas de `anonimizarAlSuprimir` (`NombreComercial`, 3 teléfonos, 2 correos, `Fax`, `Direccion`, `Contacto`, `PaginaWeb`, `Nota`) quedan en el valor de anonimización acordado; las de `conservarBloqueado` (`RazonSocial`, `Identificacion`, `TipoIdentificacion`) quedan iguales. Resultado esperado del «valor anonimizado» (NULL o marcador): afirmado según la decisión del arquitecto de datos, con la misma regla en las tres tablas | SQL | queda un teléfono sin tocar; o se anonimiza el nombre y se pierde el soporte fiscal | D-4 |
| SQL-13 | Igual para **suplidor** y para **empleado** (solo `Telefono`, `Correo` se anonimizan; `Nombres`, `Apellidos`, `Cedula` se conservan). `Cedula` no queda `NULL` (el índice filtrado no es la razón de dejarla) | SQL | se anonimiza la cédula del empleado | D-4 |
| SQL-14 | **Bloqueo (ii):** `Inhabilitado = 1`, `TitularBloqueadoEn` con la hora del acto; `CK(TitularBloqueadoEn IS NULL OR Inhabilitado = 1)`: un `UPDATE` directo que pone `Inhabilitado = 0` con la marca viva es rechazado por la base | SQL | el CHECK de F-7 no se creó o se creó mal | — |
| SQL-15 | **Irreversible:** segundo suprimir sobre el mismo registro → conflicto [código simbólico] sin segundo evento de bitácora; reactivar por la API de maestros → rechazo; la reactivación por SQL directo la frena el CHECK | SQL + HTTP | se puede reactivar o la bitácora duplica | — |
| SQL-16 | **Historial temporal (F-5), a través del verbo:** `GPOS.Migracion titulares --anonimizar-historial --empresa <código>` sobre un cliente con 3 versiones previas: en `cat.ClienteHistorial` los campos de `anonimizarAlSuprimir` quedan anonimizados en **todas** las filas del cliente; nombre y documento se conservan (misma regla que el maestro); las filas de otros clientes quedan intactas; cada fila conserva `ValidoDesde/Hasta` | SQL | el verbo anonimiza solo la fila vigente, o recorre otros clientes | D-4 |
| SQL-17 | **El verbo deja el versionado como estaba:** antes y después, `SYSTEM_VERSIONING = ON` y `HISTORY_RETENTION_PERIOD = 10 YEARS` en `cat.Cliente` y `cat.Suplidor`; si el verbo falla a la mitad (fallo inyectado entre apagar y encender), la transacción deja el versionado **encendido** y el historial sin cambios | SQL / TX | el verbo apaga el versionado y no lo restaura; o la retención baja a otro valor | — |
| SQL-18 | **El verbo no corre con la identidad de la API (ADR-82, RG-14):** conectado con el login de la API, `ALTER TABLE … SET (SYSTEM_VERSIONING = OFF)` falla por permiso; el servicio de TT en la API **no** contiene ese comando (ARQ de texto sobre el servicio) | SQL + ARQ | alguien da a la API el permiso `ALTER` para «arreglar» TT | — |
| SQL-19 | **Verbo: `--caso`/`--motivo` y plazo:** el verbo exige `--empresa`; exige `--motivo` y `--caso` si F-2 lo cubre (no está en la lista de F-2: pregunta 4); rechaza una empresa que no existe; es idempotente (segunda corrida sin cambios, sin error). El verbo se ejecuta por empresa y solo sobre registros con `TitularBloqueadoEn` | SQL | corre sobre registros no bloqueados (anonimiza datos vivos de la empresa) | D-9 |
| SQL-20 | **Espejo `PuenteMae`, suprimir:** con el puente activo, tras suprimir un cliente con `Telefono3`, `CorreoElectronico3` e `IdDireccion` poblados en `Clientes`, esos campos quedan anonimizados/desvinculados y `Inhabilitado` coherente; mismo para `Suplidores`. Si D-2 resuelve «aplazar TT», esta prueba se reemplaza por una que afirme que **TT no se ofrece** mientras exista el puente | SQL | los datos sobreviven en la tabla heredada | D-2 |
| SQL-21 | **Espejo `PuenteMae`, rectificar:** rectificar teléfono/correo/dirección escribe también la fila heredada en la misma transacción; con fallo inyectado en la segunda escritura, **ninguna** de las dos copias cambia | TX | rectificación a medias entre las dos copias | D-2 |
| SQL-22 | **Espejo y duplicado:** la validación de documento duplicado considera también la tabla heredada si el puente la mantiene | SQL | rectificar crea una divergencia entre tablas | D-2 |
| SQL-23 | **Sin puente:** cuando `PuenteMae` no existe, no se toca ninguna tabla heredada (no hay `Clientes` en el esquema) | SQL | quedan sentencias contra tablas que ya no existen | D-2 |
| TX-01 | **Atomicidad de suprimir:** con fallo inyectado en cada paso (anonimizar, bloquear, escribir bitácora, espejo) la transacción deja el registro **como estaba** y sin evento; y a la inversa, un fallo al escribir la bitácora deshace el cambio (TT-06 y F-6: atómico con el cambio) | TX | la bitácora se escribe fuera de la transacción | — |
| TX-02 | **Atomicidad de rectificar** con los mismos puntos de fallo | TX | idem | — |
| HTTP-06 | **Confirmación tecleada (F-4):** suprimir con código distinto del registro → 400 sin cambio; con vacío → 400; con mayúsculas/minúsculas distintas [pregunta 7: definir si es sensible] ; con el código exacto → 200 | HTTP | la ruta suprime sin confirmar | D-9 |
| HTTP-07 | **Campo extra al suprimir:** el cuerpo con cualquier propiedad fuera del contrato → 400 `CAMPO_NO_PERSONAL`; el servicio **no** acepta una lista de campos a anonimizar (la lista la fija el JSON, no el pedido) | HTTP | el cliente decide qué anonimizar | — |

## 5. Grupo D · Registros fuera de alcance: `GENERICO`, personas jurídicas, fusionados

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| HTTP-08 | **`GENERICO`:** GET, rectificar y suprimir sobre `GENERICO` → rechazo [código simbólico] y la fila no cambia; el POS sigue pudiendo vender de contado después | HTTP + SQL | se suprime el cliente de contado y el POS queda sin cliente | — |
| HTTP-09 | **`GENERICO` por intercalación:** `generico` y `Genérico` (la intercalación `SQL_Latin1_General_CP1_CI_AS` es insensible a mayúsculas) también rechazados; la comparación de la exclusión no es sensible a mayúsculas | HTTP | la exclusión compara con `==` en memoria y el parámetro en minúsculas encuentra la fila y pasa | — |
| HTTP-10 | **Persona jurídica (`R`):** cliente y suplidor con RNC de 9 dígitos: GET, rectificar y suprimir → rechazo; **ningún** dato cambia, incluido `Contacto` (TT-01: el contacto profesional de una empresa no entra) | HTTP | la exclusión solo está en la interfaz | D-6 |
| HTTP-11 | **El servidor decide, no el pedido:** un pedido con una propiedad `tipo = "R"` sobre un cliente `C` no lo excluye; un pedido que dice «física» sobre uno `R` no lo incluye (ya cubierto por ARQ-04; aquí por comportamiento) | HTTP | la ruta confía en un campo del pedido | D-6 |
| HTTP-12 | **Rectificar un registro bloqueado:** definir y fijar el comportamiento (permitido o rechazado) | HTTP | cambio no decidido | D-10 |
| SQL-24 | **Aviso «parece empresa»** (si el diseñador UX lo mantiene): cliente `N` con `RazonSocial` terminada en «SRL» devuelve el indicador de aviso; **no** bloquea. Cliente `R` no devuelve aviso porque no es elegible | SQL / HTTP | el aviso pasa a ser bloqueo, o falta cuando el nombre es societario | D-6 |
| SQL-30 | **Empleado siempre persona física:** todo `rrhh.Empleado` es elegible; no depende de ningún tipo | SQL | un `Cedula` de 9 dígitos lo saca de TT | — |
| SQL-31 | **Cliente fusionado:** si `FusionadoEnId` apunta a otro cliente, suprimir al absorbente **también** cubre al absorbido (o, si se decide lo contrario, la ruta lo informa y exige actuar sobre ambos); el resultado queda en la decisión de B | SQL | los datos del titular sobreviven en el registro absorbido | D-9 |
| SQL-32 | **Suplidor e igual tratamiento de `GENERICO`:** si existe un suplidor sembrado, está excluido (ARQ-08 lo prueba en las semillas) | SQL | — | — |

## 6. Grupo E · F-9: supresión con deuda pendiente

La hoja deja como **abiertas y no firmadas** las propuestas de B (datos necesarios = nombre, documento y un medio de contacto; ADMIN completa la supresión aplazada desde un listado). Las pruebas siguientes afirman lo **firmado** (marcado «—»); lo propuesto va con `[D-5]`.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| SQL-40 | **Saldo a favor no bloquea (F-9, firmado):** cliente con saldo a favor (NC sin aplicar, anticipo) y sin deuda: suprimir procede completo, sin bandera | SQL | un saldo a favor se trata como deuda | — |
| SQL-41 | **Deuda por cobrar:** cliente con CxC > 0 (factura a crédito sin cobrar): suprimir **no destruye** los datos que avalan la deuda. Con la propuesta de B (D-5): nombre, documento y un medio de contacto se conservan; el resto se anonimiza; la fila queda marcada como supresión aplazada | SQL | se anonimiza todo y no se puede cobrar, o no se anonimiza nada | D-5 |
| SQL-42 | **Frontera del saldo:** saldo 0,00 → procede completo; 0,01 → deuda; documento anulado o saldado por NC/recibo no cuenta; moneda extranjera (saldo en USD) cuenta. Se prueba con redondeo de 2 y 4 decimales | SQL | un `>= 0` en vez de `> 0`, o se ignora la moneda | — |
| SQL-43 | **«Solo para el cobro»:** el registro con supresión aplazada está bloqueado para documentos nuevos y **excluido** de envíos masivos/avisos (si existen); hoy se verifica por búsqueda de usos del correo del cliente fuera de la cobranza | SQL / ARQ | el dato aplazado alimenta otro fin (campaña, correo del e-CF de otra venta) | D-5 |
| HTTP-27 | **Proveedor con CxP adeudada (F-9, firmado):** suprimir sin elegir opción → respuesta con la **bandera** (motivo = CxP adeudada, importe) y sin cambios; la respuesta lista las dos opciones «Proceder de todos modos» y «Esperar a saldar la deuda» | HTTP | la ruta procede por omisión, o devuelve solo un error genérico que se pasa por alto | — |
| HTTP-28 | **«Proceder de todos modos»** ejecuta la supresión completa y el evento registra la opción elegida; **«Esperar»** no cambia nada [y, según se decida, registra o no el intento] | HTTP + SQL | la opción por omisión es «Proceder»; o «Esperar» deja medio hecho | D-5 |
| HTTP-29 | **Proveedor sin CxP** (saldada o con solo NC a favor del proveedor): no hay bandera | HTTP | la bandera sale siempre | — |
| HTTP-29b | **Cliente con CxP o proveedor con CxC cruzados** (el mismo titular es cliente en un maestro y suplidor en otro): cada maestro se evalúa con su deuda; la bandera del suplidor no depende del saldo del cliente | HTTP | se mezclan saldos entre maestros | D-5 |

## 7. Grupo F · Registros bloqueados: documentos nuevos, notas y cobros (D-1)

Las pruebas HTTP-30 a HTTP-37 se escriben ya con el resultado **recomendado por el especialista** y se invierten si el propietario decide lo contrario. Primero hay una prueba de caracterización que no depende de nada.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| HTTP-30 | **Caracterización previa (pendiente 11 del especialista):** con un cliente inhabilitado con deuda por cobrar, ¿el código de hoy acepta recibo de cobro y nota de crédito? Se escribe primero **sin afirmar**, solo para documentar el resultado; define qué hay que cambiar para HTTP-31 a 33 | HTTP | — (es un descubrimiento, no un guardián) | D-1 |
| HTTP-31 | **Prohibidos (firmados en TT-03):** factura, factura POS, cotización, pedido, orden de compra, factura de compra, cheque nuevos con un cliente/suplidor bloqueado → 4xx con el mensaje «bloqueado por solicitud del titular» (no «inhabilitado»); ninguna fila ni número consumido | HTTP | se emite un documento nuevo | — |
| HTTP-32 | **Permitidos, recomendados:** nota de crédito B04/E34 que referencia una factura anterior del mismo cliente bloqueado → 200 y descuenta; devolución (es nota de crédito); recibo de cobro; aplicación de saldo a favor; cheque devuelto | HTTP + SQL | el bloqueo impide devolver o cobrar lo ya emitido (no se podría emitir la NC a otro, Ley 32-23 art. 15) | D-1 |
| HTTP-33 | **Permitidos al suplidor bloqueado:** pago de CxP, solicitud de pago, aplicación de saldo a favor CxP, devolución de compra, NC/ND de compra sobre FCP anterior | HTTP | no se puede pagar al proveedor que pidió suprimir | D-1 |
| HTTP-34 | **Nota de débito que no modifica un comprobante** (sin referencia o referencia de otro tercero) → rechazada; con referencia al mismo tercero → permitida | HTTP | la ND se usa para facturar «por la puerta de atrás» | D-1 |
| HTTP-35 | **Nota de crédito a otro tercero** que referencia una factura del bloqueado → rechazada (la regla fiscal ya la impone; no se debe aflojar por el bloqueo) | HTTP | el bloqueo cambia el adquiriente de la NC | D-1 |
| HTTP-36 | **Nota de crédito emitida al e-CF:** el payload al conector usa el nombre y el documento conservados, **no** los anonimizados (teléfono y correo vacíos); la emisión no falla por el correo vacío | HTTP | la NC falla o sale con datos en blanco | D-1 |
| HTTP-37 | **`ConservarHasta` se mueve** tras la NC posterior al bloqueo (cálculo, no guardado, F-7) | SQL | se guardó la fecha y queda vieja | D-1, D-3 |
| SQL-50 | **Listado «Registros bloqueados con conservación vencida» (F-7):** con fecha del último comprobante hace 10 años + 1 día aparece; hace 10 años − 1 día no; con CxC o CxP con saldo ≠ 0 no aparece aunque el comprobante sea antiguo; una cotización o un pedido no cuentan; una NC sí cuenta. Fecha bisiesta (29-feb) como frontera | SQL | cuenta documentos que no son comprobantes; o cuenta el plazo en 3650 días en vez de 10 años | D-3 |
| SQL-51 | **Anonimización final de nombre y documento (fase posterior):** solo la dispara el ADMIN desde el listado, no hay tarea automática; la prueba verifica que no existe `IHostedService` ni job que lo haga | ARQ | alguien añade una tarea automática (F-7) | — |
| SQL-52 | **Sin comprobantes** (titular que solo tuvo cotizaciones): decidir qué pasa con nombre y documento; hoy el texto es contradictorio (§9, hallazgo H-2). Se escribe con el resultado que B elija | SQL | — | D-3 |

## 8. Grupo G · Bitácora, permisos, aislamiento y estados de licencia

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| SQL-60 | **Bitácora sin datos personales (TT-06, F-6):** sembrar valores centinela únicos (`Zx9-NOMBRE`, `809-555-0199`, `zx9@ejemplo.test`, calle, cédula) en el registro antes y después; tras rectificar y suprimir, **ninguna** columna de texto de `audit.Bitacora`, `_LOG`, el cuerpo de la respuesta HTTP ni lo capturado por un proveedor de `ILogger` contiene un centinela. La bitácora contiene los **nombres** de campo (`Telefono`, `Correo`), el código del registro, el motivo, la fecha de recepción, el usuario | SQL + HTTP | se registra el valor anterior o nuevo; o la excepción escribe el dato en el log | — |
| SQL-61 | **Código del registro, no nombre:** el evento identifica por `Codigo`; el nombre del titular no aparece. Cuidado: el `Codigo` del cliente no debe ser, él mismo, un dato personal (p. ej. cédula usada como código); si lo es, anotarlo (pregunta 8) | SQL | el código es la cédula y la bitácora la filtra | D-9 |
| SQL-62 | **Datos del apoderado fuera de la bitácora:** el nombre del apoderado, que es dato personal de un tercero, no aparece en `audit.Bitacora`; se guarda en el registro de la solicitud (hoja P-2) | SQL | el apoderado queda en texto libre del evento | D-9 |
| SQL-63 | **Retención de la bitácora (F-6):** una purga o archivado de la bitácora de la empresa no elimina eventos de TT con menos de 10 años ni mientras exista el registro bloqueado | SQL | una política general de retención borra la evidencia del acto | D-9 |
| HTTP-40 | **Permisos:** `USER` sin `solicitudestitulares` → 403 en GET, rectificar y suprimir; `USER` con el privilegio → 200; `ADMIN` y `SUPER` por nivel → 200; sin autenticación → 401; el grupo «Especiales» muestra el privilegio junto a «Ver costos» y «No generar comprobante» | HTTP | el privilegio no se exige o se exige uno equivocado | — |
| HTTP-41 | **SUPER solo con caso (TT-05/CS-01):** el SUPER que no trae número de caso válido (CS-02: `[A-Z0-9-]`, de 6 a 30) → rechazo; con caso → procede y el evento lo guarda. Un `USER` con el privilegio no necesita caso | HTTP | el SUPER actúa sin solicitud trazable | D-9 |
| HTTP-42 | **ARQ de F-1:** la ruta de TT, si lleva `Motivo` y es de SUPER, implementa `IJustificacionSuper` (la prueba de F-1 recorre las rutas del SUPER) y no queda fuera de la lista cerrada | ARQ | TT agrega una ruta del SUPER fuera de la regla R2 | D-9 |
| HTTP-43 | **Aislamiento entre empresas:** con dos empresas A y B, cada una con un cliente de **mismo código**: la sesión de A rectifica y suprime el suyo; el de B queda intacto (fila completa, historial, bitácora). Un token de A contra `/api/titulares/clientes/{código-que-solo-existe-en-B}` → 404, nunca 200 ni 403 que revele existencia. Con cambio del encabezado/empresa en el pedido: ignorado | HTTP + SQL | el servicio abre la conexión de otra empresa o no acota por empresa | — |
| HTTP-44 | **Aislamiento del verbo:** `titulares --anonimizar-historial --empresa A` no modifica `cat.ClienteHistorial` de B (bases distintas, comprobado por suma de verificación de B antes y después) | SQL | el verbo usa una conexión compartida | — |
| HTTP-45 | **Estados de licencia (TT-05):** en `SoloConsulta`, `NoLicenciada` e `Invalida`: la ruta de TT **funciona**; la edición normal de maestros, **no** (sigue bloqueada); en `Vigente` ambas. Con cada estado, un caso rectificar y un caso suprimir | HTTP | la ruta de TT queda `Operativa`, o la clase `Esencial` se contagia a la edición normal | — |
| HTTP-46 | **Auditoría de acceso (GET):** leer el registro por `GET /api/titulares/...` también deja rastro, y la respuesta no incluye campos fuera de `rectificar` + `conservarBloqueado` (no devuelve saldos ni crédito) | HTTP | el GET filtra datos del negocio | D-9 |
| HTTP-47 | **Empleado con cuenta de acceso:** suprimir un empleado con `UsuarioSistemaId` no desactiva la cuenta (la respuesta trae el aviso); la cuenta sigue iniciando sesión [según la decisión, pregunta del negocio 4]. Un vendedor asignado a una caja/perfil produce el aviso de asignaciones | HTTP + SQL | desaparece el aviso, o suprimir toca el régimen de ADR-34 a 36 | D-9 |

## 9. Grupo H · Cuarta entrada `comensales` (`com.Comensal`, entrega 3, tramo 3d)

No existe en el código (el especialista lo verificó en `feature/modelo-ng` y `master`), de modo que **hoy solo corren ARQ-12 a ARQ-14**. El resto se escribe cuando exista el esquema y se activa con el centinela de ARQ-12. Resultado esperado según el diseño de A, no según código.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| SQL-70 | **Rectificar comensal:** `Nombres`, `Apellidos` y `com.ComensalAsignacion.Departamento` cambian; `NombreClave` (derivado, BIN2) se **recalcula**; `Codigo` (nómina), `EmpleadoId`, `Estado`, `FechaAlta/Baja`, `SuspendidoHasta` no cambian; un cuerpo con `Codigo` → 400 `CAMPO_NO_PERSONAL` | SQL / HTTP | `NombreClave` queda con el nombre viejo y la búsqueda sigue encontrando a la persona | D-7 |
| SQL-71 | **No hay cédula:** el DTO y la tabla no aceptan cédula, teléfono ni correo (ARQ-13 en comportamiento); un `rectificar` con `Cedula` → 400 | HTTP | se agrega un identificador que ADR-44/88 no autoriza | D-7 |
| SQL-72 | **Suprimir comensal:** `Departamento` anonimizado; `Nombres`/`Apellidos` se conservan **solo mientras existan consumos facturados**; sin consumos facturados se anonimizan (regla del especialista, a confirmar); `com.Carne` queda en `Estado = 'B'` con `MotivoEstado = 'solicitud del titular'`, no se borra, y el identificador no se puede reutilizar (índice único) | SQL | se borra el carné y se reutiliza el identificador, o se anonimiza el nombre con consumos facturados | D-7 |
| SQL-73 | **Foto fuera de TT:** `com.ComensalFoto.Contenido` no es campo rectificable; la ruta de TT no la acepta; suprimir **no depende** de la foto; el retiro del consentimiento (ADR-88) la borra en el acto por su propia vía y la prueba de ADR-88 se mantiene | SQL | TT duplica o contradice el régimen de la foto | D-7 |
| SQL-74 | **Siempre persona física, sin tipo:** la elegibilidad del comensal no consulta `TipoIdentificacion` (no existe); todo comensal es elegible | SQL | se intenta aplicar la deducción de TT-01 a una tabla sin ese campo | D-7 |
| SQL-75 | **Enlace con empleado:** suprimir el `rrhh.Empleado` no suprime su comensal ni al revés; la respuesta lista «este titular también aparece como comensal»; las dos rectificaciones, en una acción, producen **dos** eventos de bitácora | SQL / HTTP | se suprimen los dos padrones juntos (responsables distintos) | D-7 |
| SQL-76 | **Tablas de consumo:** `com.UsoBeneficio`, `com.Consumo`, `com.Saldo*` guardan `ComensalId` sin nombre; la relación ya emitida a la empresa cliente (CO-01) y las vistas `rptc.Corp*` no se reescriben; las vistas muestran el valor anonimizado del comensal suprimido, no el nombre viejo | SQL | un nombre queda copiado en una tabla de consumo | D-7 |
| SQL-77 | **No duplica el derecho de acceso:** TT no ofrece «Datos del comensal» (lo da ADR-88); la ruta de TT no devuelve la foto | HTTP | se agrega un segundo canal de acceso | D-7 |
| SQL-78 | **Comensal no es temporal:** la supresión no requiere el verbo de historial (diseño de A: `ModificadoPor/ModificadoEn` y `rowversion`); la prueba afirma que no existe `cat`-estilo `ComensalHistorial` | ARQ | aparece un historial sin tratar | D-7 |

## 10. Hallazgos del plan (huecos de los textos que vuelven ambiguo un resultado)

- **H-1. Rectificar deja el valor viejo en el historial (SQL-05, D-10).** Las tablas de cliente y suplidor son temporales. Cada rectificación escribe en `cat.ClienteHistorial` el teléfono, el correo o el nombre **anterior**. F-5 solo trata la supresión. Quien rectifica porque el dato es inexacto o está mal obtenido deja el dato original diez años en el historial. Pregunta 1.
- **H-2. Contradicción sobre el nombre sin comprobantes (SQL-52, D-3).** La tabla de campos del especialista siempre conserva `RazonSocial` e `Identificacion` («bloqueo»). Su sección 3.1 dice que los comprobantes «bloquean suprimir el nombre y el documento», lo que sugiere que sin comprobantes sí se anonimizan. TT-03 (i) y (ii) dicen que el bloqueo conserva el nombre «para los comprobantes ya emitidos». Un cliente que solo tuvo cotizaciones: ¿nombre y documento se conservan o se anonimizan? Pregunta 2.
- **H-3. `titulares --anonimizar-historial` no está en la lista de F-2.** F-2 enumera los verbos que piden `--caso`; el de TT no figura. SQL-19 no sabe si exigir `--motivo`/`--caso`. Pregunta 4.
- **H-4. Dónde se guarda la solicitud (P-2).** El apoderado es un tercero con datos personales; TT-06 prohíbe valores en la bitácora. Falta decir en qué tabla vive la solicitud (motivo, fecha de recepción, apoderado, adjunto). SQL-62 supone una tabla propia. Pregunta 5.
- **H-5. El especialista cuenta «cuatro datos» y enumera cinco** para el empleado (§1.5, nota) y el atributo `JSON.empleados.anonimizarAlSuprimir` solo trae dos. Sin consecuencia para el test; corregir el texto.
- **H-6. ARQ-08 lee `excluir` como texto** (`"Codigo = 'GENERICO'"`): una expresión en forma de cadena SQL no se puede evaluar con seguridad. Propongo que el JSON diga `"excluirCodigos": ["GENERICO"]` y que la constante la compare la prueba (HTTP-09 cubre la intercalación).

## 11. Orden de construcción y esfuerzo

Esfuerzo **inferido** de C, ±40 %, en días-persona de pruebas (sin contar el código de producción, que ya está en los 0,55 a 0,95 sp de TT):

| Orden | Qué | Por qué primero | Días |
|---|---|---|---|
| 1 | Grupo A ARQ-01 a ARQ-08 y ARQ-11 (con el JSON firmado, D-8) | Fijan el contrato antes de escribir el servicio; ARQ-06 fuerza la clasificación de columnas ya | 1,5 |
| 2 | HTTP-08 a HTTP-11, SQL-30 | La exclusión de `GENERICO` y de las jurídicas es el riesgo operativo más alto (Alta) | 0,75 |
| 3 | Grupo B (SQL-01 a SQL-11, HTTP-01 a HTTP-05) | Rectificar es el camino más corto y fija los helpers | 2 |
| 4 | Grupo G (SQL-60, HTTP-40, 43, 45) y TX-01/02 | Seguridad, aislamiento y atomicidad antes de abrir suprimir | 1,5 |
| 5 | Grupo C (SQL-12 a SQL-17, HTTP-06/07) | Suprimir sobre la base ya probada; SQL-16/17 exigen el verbo de `GPOS.Migracion` | 2 |
| 6 | Grupo F HTTP-30 (caracterización) y 31 | HTTP-30 se puede correr hoy y destraba D-1 | 0,5 |
| 7 | Grupo E y resto de F, tras las firmas D-1, D-3 y D-5 | Dependen de decisiones abiertas | 1,5 |
| 8 | SQL-20 a SQL-23 y ARQ-09/10 | Se resuelven según D-2 | 0,5 a 1 |
| 9 | Grupo H | Entrega 3; solo ARQ-12 a ARQ-14 antes (0,25) | 1,5 después |

Total: 11 a 12 días-persona (de 8 a 17 con el margen), más 1,5 días de Grupo H en la entrega 3. Sin suites completas: cada grupo corre con `--filter` y cada día termina con la suite filtrada oficial de B (`Transicion!=Ola5&Transicion!=Defecto`) en la máquina de B, no en OSHIN-LEGION.

## 12. Preguntas para B

1. ¿Rectificar sobre un registro de las tablas temporales debe purgar también la versión anterior del historial, o el valor viejo queda hasta el verbo de F-5? (H-1; SQL-05)
2. Un titular sin comprobantes (solo cotizaciones o nada): ¿nombre y documento se anonimizan al suprimir, o siempre se conservan? (H-2; SQL-12, SQL-52)
3. D-1: ¿lo firma el propietario antes de L1b, con la redacción de TT-03 que propone el especialista? ¿Quién verifica en código si hoy un cliente inhabilitado admite recibo y nota (HTTP-30)? ¿Lo hago yo cuando pueda ejecutar?
4. ¿`titulares --anonimizar-historial` exige `--motivo` y `--caso`, y se agrega a la lista cerrada de F-2? (SQL-19)
5. ¿Dónde se guarda la solicitud (motivo, fecha de recepción, apoderado, adjunto del poder)? (H-4; SQL-62)
6. ¿Una fecha de recepción futura o anterior a la creación del registro es 400? ¿Qué días cuentan como hábiles (feriados dominicanos)? El plazo es solo informativo, pero el indicador necesita regla. (HTTP-01)
7. La confirmación tecleada de suprimir: ¿distingue mayúsculas y espacios? (HTTP-06)
8. ¿El `Codigo` del cliente puede ser la cédula? Si sí, la bitácora, que registra el código, contendría un dato personal. (SQL-61)
9. D-2: ¿rectificar/suprimir escribe el espejo heredado o TT espera la eliminación del puente? En el primer caso, ¿qué se hace con `IdDireccion`?
10. ¿El JSON se cambia a `excluirCodigos` (H-6) y se firma el contenido del §1.7 del especialista como `version: 1`?
11. ¿La supresión de un cliente fusionado recorre la cadena `FusionadoEnId`? (SQL-31)
12. ¿Cuándo existe `com.Comensal` para activar el grupo H, y quién lo asume (A, B o C)?
13. Cuando llegue ADR-161 (tarea 6), ARQ-04, HTTP-10, HTTP-11 y SQL-30 se reescriben con el campo `EsPersonaFisica`: ¿me avisas para sincronizar el plan?

## 13. Qué no verifiqué

- **No compilé ni ejecuté nada**, ni el código de prueba ni el de producción. Ningún resultado «esperado» se corrió.
- **No leí código vivo:** ni `MaestrosService`, `PuenteMae`, `Terceros.cs`, `Personas.cs`, `MaeConfiguracion.cs`, `CfgConfiguracion.cs`, ni las rutas existentes, ni la clasificación de rutas de L1b, ni la lista de privilegios, ni `Cliente.CodigoContado`. Todas las referencias a archivo y línea (SRV:166-169, TER:116-122, MAE:328-333, CP-169, etc.) son las del especialista y las doy por buenas sin comprobarlas.
- **No leí `traspasos/A/adr92-respuestas-datos` ni `adr92-respuestas-software`** (fuente de TT-P1 a TT-P6 y del diseño de la bitácora, de `TitularBloqueadoEn` y del verbo de historial); trabajé con lo que resume la hoja de firma.
- **Del ADR-92 leí solo el bloque TT (cláusulas 1 a 6) y la precisión del 2026-10-22**, no los bloques UR y CS completos ni sus anexos. Del esquema `com` solo leí lo que cita el especialista; no abrí `datos-vertical-corporativa-2026-10-15.md`.
- **No leí la propuesta de ADR-161 ni la revisión de la DDL** (tarea 6), por lo que el plan de TT no cubre la interacción con el maestro de tipos.
- **No verifiqué los datos legales** (Ley 32-23, art. 15; art. 4.4; Código Tributario art. 50 h; plazos de 10 días hábiles ni 10 años): son del especialista y del ADR. Q-TT5-a (contador) y L-03/L-04 (abogado) siguen abiertos.
- **No verifiqué la rama** `b/adr92-dp1-dp3-dp5`; usé `origin/master`, donde ADR-92 está registrado.
- Los conteos de la §0 salen de un `grep` sobre este mismo documento; la fracción «unas 30 solo por D-9» es una estimación, no un conteo.
- No comprobé el nombre real de los códigos de error, de las rutas ni de los DTO, salvo `CAMPO_NO_PERSONAL` y las rutas `/api/titulares/{maestro}/{codigo}` de F-4.

### Cierre
- Estado: Completado (plan, sin ejecución; la recomendación de QA sobre el código aún no aplica)
- Artefactos: `C:/Users/lfmen/source/repos/GPOS-NG-Equipos/traspasos/C/2026-10-22-plan-pruebas-tt-adr92.md`
- Supuestos: los de la §13; el contenido de `CamposPersonalesTitular.json` es el propuesto por el especialista, no firmado (D-8); la numeración de pruebas es provisional
- Decisiones candidatas a ADR: ninguna nueva; las cuatro del especialista (§6 de su respuesta) siguen pendientes de B, y H-1, H-2 y H-4 piden precisión de ADR-92
- Entregas a otros agentes: B (arquitecto-software/desarrollador-backend) → preguntas 1 a 13, en especial D-1, D-2, H-1 y H-2 antes de la construcción; arquitecto-datos → dónde vive la solicitud (H-4) y el valor de anonimización; abogado y contador (vía el propietario) → D-3, D-4, D-5
- Próximo paso recomendado: que B firme el JSON (D-8) y responda las preguntas 1, 2 y 9; C escribe primero los ARQ-01 a ARQ-08.
