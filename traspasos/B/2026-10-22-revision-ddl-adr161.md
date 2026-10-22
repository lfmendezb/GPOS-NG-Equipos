# Revisión de la DDL propuesta del ADR-161 (maestro «Tipo de identificador fiscal»)

- Fecha: 2026-10-22 · Revisor: arquitecto-datos · Modo: solo lectura (sin cambios en el repositorio, sin compilar, sin commit).
- Rama revisada: `master` (d5499a1f) para los documentos; `origin/feature/modelo-ng` (e3e729c1) para el código citado, con `git show`.
- Recomendación final: **Corregir** (la decisión es coherente; la DDL todavía no existe como artefacto revisable y el esbozo tiene un defecto Alto de integridad).

## 0. Qué se revisó y qué falta

- **El archivo pedido no existe:** `docs/datos/2026-10-22-adr-161-propuesto-tipo-identificador-fiscal.md` no está en `master` (`git ls-files docs/datos | grep 161` sin resultado). El único documento del ADR-161 es la propuesta `docs/propuestas/2026-10-22-adr-161-propuesto-tipo-identificador-fiscal.md`; en `docs/adr/` solo hay la referencia del índice (`docs/adr/README.md:14`). La propia propuesta lo reconoce: «Se confirma con el diseño de datos del `arquitecto-datos` antes de construir (DDL y migración)» (propuesta:74).
- Por tanto, esta revisión evalúa el **esbozo de DDL** que trae la propuesta (TI-01, TI-02, TI-05 y «Cómo se migra», líneas 25-29 y 51) contra el código real de `feature/modelo-ng`.

## 1. Hallazgos

### Alto

**A-1. La letra `C/P/N/R` derivada solo por el largo choca con los tipos alfanuméricos que el maestro permite: el alta falla con un error 547 de `CK_*_Identificacion`.**
- Evidencia [V]: `TiposIdentificacion.TipoDe` decide solo por el largo (9 → `R`, 11 → `C`) (`src/GPOS.Core/Dominio/Maestros/Terceros.cs:116-122`, modelo-ng); `FormatoRnc.Digitos` solo quita guiones y espacios, no letras (`src/GPOS.Contracts/Fiscal/FormatoRnc.cs:29-34`); `CK_Cliente_Identificacion` exige solo dígitos para `R` y `C` y de 5 a 20 caracteres para `P` (`src/GPOS.Core/Datos/Empresa/Configuracion/MaeConfiguracion.cs:326-335` en el archivo; líneas 89-94 del extracto revisado; igual en `CK_Suplidor_Identificacion`).
- Efecto: un `PASAPORTE_OTROS` o un `CARNET_MIGRACION` sembrados «de 5 a 20 alfanuméricos» (propuesta:26) con **exactamente 9 u 11 caracteres y alguna letra** pasa la regla del tipo, pero recibe la letra `R`/`C` y la base lo rechaza. Lo mismo ocurre con cualquier rango que el SUPER defina por debajo de 5 caracteres (la letra sería `P` y el CHECK exige 5 o más). TI-05 dice «la letra se sigue derivando de los dígitos, sin cambio» (propuesta:29): con el maestro, ese «sin cambio» deja de ser seguro. El defecto ya existe hoy con pasaportes alfanuméricos de 9 u 11 caracteres; el maestro lo vuelve una ruta normal.
- Remediación: (a) que `TipoDe` devuelva `R`/`C` solo si el valor es **solo dígitos** y de 9/11, y `P` en otro caso (cambio de una línea, sin cambio de esquema); y (b) acotar declarativamente lo que el SUPER puede definir con un CHECK en la tabla hija: `CK_TipoIdentificadorLargo_Rango: Desde BETWEEN 5 AND 20 AND Hasta BETWEEN Desde AND 20`, salvo que se declare explícitamente la excepción de 9 y 11 dígitos (que ya caen en 5-20, así que basta). El largo 20 es el de `Identificacion varchar(20)` (`MaeConfiguracion.cs`, extracto línea 112 y 181).

### Medio

**M-1. La derivación por omisión (TI-04, TI-06) depende de códigos fijos (`EMPRESA`, `PERSONA_FISICA`, `PASAPORTE_OTROS`) que el SUPER puede inhabilitar o cuyas reglas puede cambiar.**
- Evidencia: propuesta:28, 30 y 27 (el SUPER edita reglas e inhabilita). El catálogo es independiente por empresa (TI-01), así que nada garantiza que esos códigos existan, estén activos o admitan el largo derivado.
- Efecto: un cliente desplegado antiguo o una importación sin la columna nueva fallan en una empresa donde el SUPER tocó esos tipos; el fallo aparece en el alta, no al configurar.
- Remediación: hacer la derivación **guiada por datos**: columna `LetraPorOmision char(1) NULL` en `cat.TipoIdentificadorFiscal` con `CK (LetraPorOmision IN ('R','C','P'))` e índice único filtrado `UQ_TipoIdentificadorFiscal_Letra WHERE LetraPorOmision IS NOT NULL`; la siembra marca `R`→EMPRESA, `C`→PERSONA_FISICA, `P`→PASAPORTE_OTROS. El servicio rechaza inhabilitar un tipo con letra por omisión (o exige reasignarla antes). Alternativa descartada: marca `EsSistema` que congela los tres tipos: más simple, pero quita al SUPER la libertad que le dio el propietario.

**M-2. Cambiar `EsPersonaFisica` de un tipo con uso reclasifica en bloque a efectos de TT (ADR-92, supresión) sin control.**
- Evidencia: Q-TI-5 protege solo las reglas de largo (propuesta:71); TI-07 hace de `EsPersonaFisica` la fuente de TT (propuesta:31).
- Remediación: aplicar el mismo 409 de Q-TI-5 al cambio de `EsPersonaFisica` en un tipo con clientes o suplidores, o registrarlo en la bitácora del SUPER con motivo. Es regla de servicio; la DDL solo necesita el índice de M-3 para que la comprobación sea barata.

**M-3. Faltan el índice de la llave foránea y la regla de coherencia identificación/tipo.**
- Evidencia: el esbozo solo dice `TipoIdentificadorId smallint NULL (llave foránea)` (propuesta:29); las llaves foráneas del proyecto no crean índice salvo que se declare (`MaeConfiguracion.cs`, extracto 136-147).
- Consultas que lo justifican: Q-TI-5 y M-2 («¿qué clientes/suplidores del tipo X incumplen la nueva regla?»), la comprobación de uso antes de inhabilitar (ADR-08) y la vista `rpt` de TI-08.
- Remediación: `IX_Cliente_TipoIdentificador (TipoIdentificadorId) INCLUDE (Identificacion) WHERE TipoIdentificadorId IS NOT NULL`, y el homólogo en `cat.Suplidor`. Costo: 2 bytes por fila más la llave del índice; con 100 000 clientes, menos de 3 MB y una escritura adicional solo cuando cambia el tipo. Además, `CK_Cliente_TipoIdentificador: TipoIdentificadorId IS NULL OR Identificacion IS NOT NULL` (un tipo sin identificación no tiene sentido); el bicondicional («con identificación, tipo obligatorio», propuesta:28) conviene exigirlo en el servicio, porque el historial y los nodos pueden traer filas previas sin tipo.

**M-4. Nodos (TI-09): la forma de la llave no está fijada y el cliente se crea también en la sucursal.**
- Evidencia: `cat.Cliente` toma su llave del rango del nodo y se puede crear en la sucursal (`Terceros.cs:5-8`, `MaeConfiguracion.cs`, extracto 104-105); los catálogos simples son `ISoloCentral` con `smallint IDENTITY` (`src/GPOS.Core/Dominio/Maestros/Catalogos.cs:14-22`).
- Efecto: si el catálogo no baja al nodo con los **mismos Id** que la central, la llave foránea de un cliente creado en el nodo falla o apunta a otro tipo.
- Remediación: declarar `cat.TipoIdentificadorFiscal` y su hija como `ISoloCentral`, con el mismo mecanismo de bajada de los demás catálogos (Id de la central conservado). La copia entre empresas (Q-TI-7) se hace por `Codigo`, nunca por `Id`.

**M-5. Enmascarado en `rpt` de una persona física con RNC de 9 dígitos.**
- Evidencia: las vistas `rpt` muestran íntegro el RNC según la letra `R` (`database/ola5/LEEME.md:169`, modelo-ng). Con TI-05, una persona física con RNC sigue con `R` y su identificación sale completa en `rpt`.
- Remediación: que TI-08 decida si el enmascarado pasa a guiarse por `EsPersonaFisica` del tipo. Es decisión de reportes y de seguridad (ver entregas), no de DDL; la vista solo necesita la columna nueva.

### Bajo

**B-1. Largos y forma inconsistentes con el patrón de catálogos.** El esbozo propone `Descripcion varchar(60)` y «columnas de fechas y autor de los demás catálogos» (propuesta:25), pero `CatalogoSimple` usa `Codigo varchar(20)`, `Descripcion varchar(80)`, `Notas varchar(200)`, `Inhabilitado` y `Version rowversion`, **sin** fechas ni autor (`Catalogos.cs:14-22`; `MaeConfiguracion.cs:13-27`). Remediación: heredar de `CatalogoSimple` (80 de descripción, sin columnas de autoría) y agregar `EsPersonaFisica bit NOT NULL`, `SoloDigitos bit NOT NULL`, `LetraPorOmision` (M-1). La autoría de los cambios del SUPER va a la bitácora, no a columnas.

**B-2. Tabla hija sin restricciones declaradas.** Falta: `PK_TipoIdentificadorLargo (TipoIdentificadorId, Desde)`; `FK` sin cascada (precisión de ADR-08, `MaeConfiguracion.cs:9-10`); el CHECK de A-1. El no solapamiento de rangos y «al menos un rango por tipo activo» no son declarables sin disparadores: dejarlos en el servicio y dicho en el diseño. `tinyint` basta para `Desde`/`Hasta`.

**B-3. Mecanismo de migración e idempotencia: decir explícitamente por qué no se usan `01`/`02`.** El `CLAUDE.md` exige SQL idempotente en `database/01_esquema_base.sql` y `02_actualizacion_gpos.sql` y «no hay migraciones de EF Core»; eso describe `master`. En `feature/modelo-ng` el esquema de empresa sí se lleva con migraciones de EF (`src/GPOS.Core/Datos/Empresa/Migraciones/*`) y un guion acumulado idempotente (`database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql`, con guardas por `MigrationId`). La propuesta es coherente con la rama (propuesta:51), pero debe citarlo (ADR-52, efecto al corte) y: (a) escribir el relleno con `migrationBuilder.Sql` envuelto en `EXEC(N'...')` (en un guion idempotente, un `UPDATE` que nombra una columna creada en el mismo lote falla al compilar el lote), y (b) hacerlo idempotente por sí mismo (`WHERE TipoIdentificadorId IS NULL`) y por `Codigo`, no por Id literal.

**B-4. Relleno sobre tablas temporales.** El `UPDATE` de relleno escribe una fila de historial por cada cliente y suplidor (ver `IsTemporal`, `MaeConfiguracion.cs`, extracto 96-101). En bases de desarrollo y demostración el volumen es despreciable; documentarlo para que nadie lea esas filas como cambios de un usuario. No conviene apagar `SYSTEM_VERSIONING` para evitarlo (más riesgo que beneficio).

**B-5. Intercalación y ADR-50.** `varchar` es correcto (ADR-50): «Física» y «Migración» caben en la página de códigos 1252 de `SQL_Latin1_General_CP1_CI_AS`. La comparación de `Codigo` es insensible a mayúsculas por la intercalación; conviene un `CK (Codigo NOT LIKE '%[^A-Z0-9_]%' COLLATE Latin1_General_BIN)` o normalizar a mayúsculas en el servicio. Los parámetros de Dapper del 409 de Q-TI-5 y de las vistas deben ir como `varchar(20)` (ADR-50); el mapeo debe declarar los largos para que CP-169 (`tests/GPOS.Tests/ConsultasVarcharTests.cs:24`, modelo-ng) no falle. Sin hallazgo, solo condición de construcción.

**B-6. Privilegios.** `gpos_app` ya tiene `SELECT, INSERT, UPDATE, DELETE` sobre el esquema `cat` (guion acumulado, línea 430): las tablas nuevas no requieren permisos adicionales. La restricción «solo el SUPER define» es de aplicación, no de base; correcto según el modelo (ADR-35). Sin cambio.

## 2. Qué rompe, a quién afecta y cómo se migra (evaluación)

- **Qué rompe:** nada del esquema existente si se corrige A-1 (columna nula, sin cambio de CHECK ni de letra). Sin A-1, rompe el alta de identificadores alfanuméricos de 9 u 11 caracteres o de menos de 5.
- **A quién afecta:** SUPER (configura por empresa), ADMIN y usuarios (un selector), importación (columna opcional), vistas `rpt` (subida de contrato, ADR-109 cl. 11), nodos (bajada del catálogo).
- **Cómo se migra:** la propuesta es correcta en lo esencial (crear, sembrar, agregar columna, rellenar `R/C/P`, `N` sin tipo, historial sin rellenar; propuesta:51), con las correcciones B-3 y B-4. Solo bases de desarrollo y demostración (implantación desde cero, J-3).
- **Estimado:** 0,3 a 0,5 sp para datos es razonable; M-1 y M-3 añaden unas 0,05 a 0,1 sp. Costo de infraestructura: USD 0; crecimiento por empresa: kilobytes en el catálogo y menos de 3 MB de índice con 100 000 clientes.

## 3. DDL mínima recomendada (referencia, para el diseño en `docs/datos/`)

```sql
-- cat.TipoIdentificadorFiscal (ISoloCentral, forma de CatalogoSimple)
Id smallint IDENTITY PK_TipoIdentificadorFiscal,
Codigo varchar(20) NOT NULL UQ_TipoIdentificadorFiscal_Codigo,
Descripcion varchar(80) NOT NULL, Notas varchar(200) NULL,
EsPersonaFisica bit NOT NULL, SoloDigitos bit NOT NULL,
LetraPorOmision char(1) NULL  CK IN ('R','C','P'),  -- índice único filtrado
Inhabilitado bit NOT NULL DEFAULT 0, Version rowversion
-- cat.TipoIdentificadorLargo
TipoIdentificadorId smallint NOT NULL FK (sin cascada), Desde tinyint NOT NULL, Hasta tinyint NOT NULL,
PK (TipoIdentificadorId, Desde), CK Desde BETWEEN 5 AND 20 AND Hasta BETWEEN Desde AND 20
-- cat.Cliente / cat.Suplidor
TipoIdentificadorId smallint NULL FK, CK (TipoIdentificadorId IS NULL OR Identificacion IS NOT NULL),
IX_*_TipoIdentificador (TipoIdentificadorId) INCLUDE (Identificacion) WHERE TipoIdentificadorId IS NOT NULL
```

## 4. Recomendación final

**Corregir.** La decisión (TI-01 a TI-09) puede firmarse como ADR, pero la parte de datos no está lista: falta el blueprint de datos en `docs/datos/` y deben resolverse A-1 (obligatorio antes de construir) y M-1 a M-4. M-5 se decide con reportes y seguridad.

## Cierre
- Estado: Rechazado (la DDL, para corregir; la decisión de negocio no se objeta)
- Artefactos: este informe.
- Supuestos: el código de `origin/feature/modelo-ng` (e3e729c1) es la base de construcción; las líneas de `MaeConfiguracion.cs` citadas como «extracto» se tomaron del rango 300-440 leído con `sed`, y las del encabezado de la propuesta (326-335, 398-407) coinciden con el CHECK.
- Decisiones candidatas a ADR: derivación de la letra y del tipo guiada por datos (`LetraPorOmision`), como precisión de TI-05/TI-06.
- Entregas a otros agentes: equipo B / desarrollador-backend → corregir `TipoDe` (A-1) y reglas de servicio de M-1, M-2; especialista de reportes y seguridad → M-5 (enmascarado por `EsPersonaFisica`); arquitecto-datos → blueprint `docs/datos/2026-10-22-adr-161-...md` con la DDL de la sección 3.
- Próximo paso recomendado: redactar el blueprint de datos con A-1 y M-1 a M-4 resueltos y presentarlo junto con la firma del ADR-161.
