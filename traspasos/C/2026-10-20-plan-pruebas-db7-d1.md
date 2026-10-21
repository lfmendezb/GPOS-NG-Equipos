# Plan de pruebas de DB-7, tramo D1 (T1-1 a T1-4)

**Fecha:** 2026-10-20 · **Autor:** QA del equipo C (OSHIN-LEGION) · **Encargo:** B, tarea 4 de `avisos/B-a-C/2026-10-20-cola-de-tareas-para-c.md` · **Destinatario:** el desarrollador que construya T1-1 desde el 2026-11-02 (y quien siga con T1-2 a T1-4).
**Estado:** plan. **No se compiló, no se programó y no se ejecutó nada.** Todo lo que dice "falla hoy" sale de leer el código; está marcado *inferido* cuando depende del comportamiento del motor y nadie lo ejecutó.

**Base leída (solo lectura, con `git show` y `git grep`, sin checkout, pull ni rebase):**
- documentos: `origin/master` @ `b39793f1` (`docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` revisión 2 = **DAT-D1**; `docs/arquitectura/2026-10-20-db7-d1-respuestas-arquitecto-software.md` = **RSW-D1**; `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md` = **PLAN-D1**; `docs/datos/2026-10-18-db7-d0-modelo-datos.md` = **DAT-D0**);
- código y pruebas: `origin/feature/modelo-ng` @ `b8f166db`. Las citas `archivo:línea` son de ese commit.
- el texto de la revisión 1 de Q3-P sale de `git show ffee214f:docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` (se copia en el Anexo C).

---

## 1. Resumen

- **Cuántas pruebas:** 13 cambios en pruebas **existentes** (8 aserciones de versión, los 2 métodos de PF25, PF43, PF46 y la S-05 de `CambioRncHttpTests`; sección 4) y **205 pruebas nuevas** (T1-1: 76, T1-2: 34, T1-3: 65, T1-4: 30; una teoría cuenta una vez). Cada criterio de los cuatro tramos tiene al menos una.
- **Seis cosas que DAT-D1 y RSW-D1 no dicen y que el desarrollador va a encontrar** (detalle en la sección 3):
  1. Las pruebas que fijan la marca 5 son **ocho líneas en dos archivos**, no dos (H-2).
  2. `PF46_el_catalogo_incluye_la_licencia_y_el_sello` fija `Limitados` en cuatro eventos y se rompe al agregar `IDENTIFICACION_FALLIDA` (H-1). No está en ninguna lista.
  3. `Con_AdministradaPorSuper_no_hay_409` **pasa en vacío** contra el texto defectuoso de Q3-P; y `Con_D7A_aplicado_EF_guarda_Usuarios` pasa en vacío si solo prueba un `INSERT` (H-3 y H-4).
  4. Con la FK del catálogo no se puede preparar con un `INSERT` directo un evento "sin catálogo" ni un catálogo con retención menor de 2 años: hay que usar la historia de una base v5 o `NOCHECK` (H-5).
  5. Las constantes de `Consultas/Sistema/Acceso/` **no** pueden llevar `[ConsultaRegistrada]`: `ContratoConsultasTests` las describiría contra una base de empresa y fallaría con 208 (H-6).
  6. Un resumen de más de 2 000 caracteres puede quedar como JSON inválido y chocar con `CK_BitacoraSeguridad_Json` (H-9).
- **Nueve preguntas para B** (sección 12), solo donde el diseño es ambiguo.

---

## 2. Convenciones del plan

### 2.1 Cómo leer las tablas
- **Ord** = orden recomendado dentro de la tarea (de la prueba más barata a la más cara; ver la sección 9).
- **Tipo:** **U** unidad (sin base ni red); **I** integración con base (una base `GPOS_TEST_*` real; incluye las que pasan por la API, marcadas **IH**); **A** arquitectura (lee el texto o los ensamblados del código).
- **Origen:** `D` = nombre dado por DAT-D1; `P` = PLAN-D1; `R` = RSW-D1; `QA` = agregada por este plan.
- **Rojo hoy / mutante:** por qué falla antes de construir y, en las pruebas de riesgo, **el sabotaje concreto que debe ponerla en rojo** (Anexo B). Una prueba que no se pone en rojo con su mutante no demuestra nada.
  - **NC** = no compila o el símbolo no existe todavía. **V5** = la base queda en la versión 5 y el objeto SQL no existe. **R** = existente que deja de ser válida. **G** = guardia: pasa hoy y protege una premisa; solo se pone en rojo con su mutante.

### 2.2 Protocolo "rojo primero" (propuesta)
1. Primer commit del PR: las pruebas (adaptadas y nuevas) más los **símbolos vacíos mínimos** para que compile (constantes `""`, `Version` aún en 5). Se ejecutan por clase y el desarrollador pega en el PR la lista de las que fallan y **con qué mensaje**: debe ser el esperado de la columna "Rojo hoy".
2. Las pruebas de riesgo se comprueban además contra su mutante (Anexo B) **una sola vez**, localmente, y se anota el resultado en el PR. No se deja el mutante en el árbol.
3. Segundo commit: la construcción. Las pruebas no se tocan salvo error propio, y el cambio va explicado en el PR.

### 2.3 Reglas del proyecto que las pruebas deben cumplir (verificadas en el código)
- Cada archivo `*Tests.cs` declara **un solo** rasgo `[Trait("Esquema", "NG")]` con esa grafía exacta (`PruebasNeutralesTests.cs`, `Cada_archivo_de_pruebas_declara_un_solo_esquema` y `Cada_clase_con_pruebas_lleva_el_rasgo_Esquema`). Todas las clases nuevas son `NG`. Los archivos de ayuda no terminan en `Tests.cs` (por ejemplo `AccesoPruebas.cs`).
- Propuesta: además `[Trait("Categoria", "Acceso")]` en todas (el rasgo `Categoria` ya existe con otros valores: Licencia, Sellos, Anillo…) y `[Trait("Medicion", "DB7")]` en las que duran más de unos segundos (bucles de 30 s). Así se filtran por módulo y las largas se excluyen de la corrida normal.
- Carpeta nueva `tests/GPOS.Tests/Acceso/` (PLAN-D1); espacio de nombres `GPOS.Tests.Acceso`. Las de arquitectura van en `tests/GPOS.Tests/Arquitectura/`.
- Bases temporales `GPOS_TEST_SIS_ACC_*` (prefijo `GPOS_`, nunca `GPOST_`): `BasesNgPrueba.Cadena(BasesNgPrueba.Servidor, "SIS_ACC")` y `BasesTemporales.EliminarAsync` en `finally`, como PF30 (`EsquemaSegundoFactorTests.cs:91-93` y `:163-169`).
- **ADR-50 y CP-169:** CP-169 (`ConsultasVarcharTests.CP169_…` y `MigracionesTests`) compara el **mapeo de EF** con el esquema de las **bases de empresa**; no alcanza a `GPOS_SYSDATA` ni a estas tablas, que están fuera de EF. Lo sustituyen la prueba 21 (matriz de tipos del Anexo A) y la 24 (las FK con el mismo tipo que la referenciada). `GPOS_SYSDATA` es Unicode (ADR-50 no aplica a sus columnas), pero la regla de fondo vale: cada parámetro lleva el tipo y el largo de su columna (DAT-D1 4.1). Se comprueba con `ComandosSql` (`ConsultasVarcharTests.cs:201`), que ya capta el tipo de cada parámetro; propongo agregarle el campo `Size` (cambio aditivo en una ayuda de pruebas).
- **Orden único de bloqueos de `CLAUDE.md`:** rige las bases de empresa; en D1 solo las toca el paso 11 del verbo. El orden de `GPOS_SYSDATA` es el de DAT-D0 3.7: padrón → `Usuarios` → `UsuariosEmpresas` → hijas → bitácora. Las pruebas de concurrencia lo verifican (T1-3, secciones 7.1 y 7.2).

### 2.4 Índice de clases (filtro, datos, tipo dominante)
`dotnet test tests/GPOS.Tests --filter "FullyQualifiedName~<Clase>"`. Por módulo: `--filter "Categoria=Acceso"`; sin las largas: `--filter "Categoria=Acceso&Medicion!=DB7"`. **La suite completa no se corre en la PC de C ni a la vez que otra** (regla de `CLAUDE.md`, sección Calidad, y de B).

| Clase (archivo en `tests/GPOS.Tests/`) | Tarea | Datos | Tipo |
|---|---|---|---|
| `EsquemaAccesoTests` (`Acceso/`) | T1-1 | DB-N por prueba (PF30) | U, I |
| `RestriccionesMembresiaTests` (`Acceso/`) | T1-1 y T1-3 | DB-F: fixture compartida `SistemaAccesoFixture` (copia de `SistemaSegundoFactorFixture`), filas con código único | I |
| `CatalogoEventosTests` (`Acceso/`) | T1-1 | U: sin base; I: DB-N | U, I |
| `EventosSeguridadTests` (`Acceso/`) | T1-1 | sin base | U |
| `PurgaBitacoraTests` (`Acceso/`) | T1-1 | DB-N (las que alteran el catálogo) o DB-F | I |
| `PrivilegiosSistemaTests` (`Acceso/`) | T1-1 | DB-L: base + login de `LoginsPruebaRg14` | I |
| `AccesoArquitecturaTests` (`Arquitectura/`) | T1-1 | texto del código | A |
| `EventIdUnicosTests` (existente, `Arquitectura/`) | T1-1 | texto del código | A |
| `AccesoPruebasTests`, `EstadoAccesoTests`, `EstadoAccesoServiceTests`, `PermisosEmpresaTests`, `BitacoraAccesoTests`, `CupoEmpresasTests` (`Acceso/`) | T1-2 | DB-N + escenario ESC (Anexo D); las pruebas 14 y 15 de 6.1 con DEMO-50 | I |
| `MembresiasServiceTests`, `DominioAdministracionTests`, `GuardarPrivilegiosSqlTests`, `DesbloqueoAdminTests`, `ConcurrenciaAccesoTests` (`Acceso/`) | T1-3 | DB-N + ESC | I |
| `MiembrosHttpTests`, `SuperCuentasHttpTests` (`Acceso/`) | T1-3 | `ApiMvpFactory` (Amplio) con su propia base + ESC | IH |
| `ConversionAccesosTests` (`Acceso/`) | T1-4 | DB-N con tablas globales pobladas (Anexo D, ESC-DEMO) y una o dos bases de empresa | I |

**Datos:** **DB-N** = `EnsureCreatedAsync` + `EsquemaSistema.ActualizarAsync` + `SubirMarcaAsync` (como `ArranqueAmplioAsync`). **DB-L** = `ComandoSistema.AplicarAsync(cadena, login, null, …)` con un login de `LoginsPruebaRg14` (Estricto, como PF43). **DB-5** = una DB-N a la que una función de la prueba le quita D7-A y baja la marca a 5 (como PF30 simula la versión 3, líneas 122-127).

---

## 3. Hallazgos de QA al leer el diseño

Son huecos del plan de pruebas, no defectos de código (no hay código). Severidad = lo que cuesta si no se atiende.

| # | Sev. | Hallazgo | Evidencia | Qué hace este plan |
|---|---|---|---|---|
| H-1 | Media | `PF46_el_catalogo_incluye_la_licencia_y_el_sello` afirma `Limitados == [TokenSuperSinOtp, DerivaReloj, AccesoRechazadoCandado, RecuperacionFactorRechazada]`. RSW-D1 6 agrega `IDENTIFICACION_FALLIDA` a `Limitados`: la prueba falla. No figura en DAT-D1 7.5 ni en RSW-D1 10.2. | `BitacoraSeguridadTests.cs:64-65`; `EventosSeguridad.cs` (`Limitados`) | Se agrega a la lista de adaptaciones (X-3) y se crea `EventosSeguridadTests.Limitados_conserva_los_cuatro_anteriores_y_agrega_IDENTIFICACION_FALLIDA`. |
| H-2 | Media | Las pruebas que fijan la marca 5 son **ocho líneas**, no dos: DAT-D1 solo cita `EsquemaSegundoFactorTests.cs:96` y `EsquemaRecuperacionFactorTests.cs:82`. | Sección 4.1 | Lista exacta con cambio esperado. |
| H-3 | Alta | Contra el texto de la revisión 1 de Q3-P, `Con_AdministradaPorSuper_no_hay_409` **pasa en vacío**: ese texto nunca devolvía 409, con o sin la marca. Una prueba así no discrimina. | Anexo C: sin otros ADMIN cuenta 1 | Se exige el **par** (misma escena con la marca en 0 → 409, en 1 → 200) y una "prueba de la prueba" que fija que el texto viejo falla los casos 1 y 2 (7.1, Ord 0a). |
| H-4 | Alta | `Con_D7A_aplicado_EF_guarda_Usuarios` pasa en vacío si solo prueba el alta: EF 10 usa `OUTPUT` en el `UPDATE`, no en el `INSERT` de una clave sin columnas generadas, y el disparador de `Usuarios` es `AFTER UPDATE` (*inferido* de la documentación de SQL Server: el error 334 es por acción). Además, **hoy** pasa (no hay disparador), así que no está en rojo. | `SistemaDbContext.cs:26-42` (sin `HasTrigger`, sin `RowVersion`); DAT-D1 2.4 | La prueba exige primero que el disparador exista (rojo hoy) y ejecuta cambio de clave, inicio de sesión y cambio de nivel (prueba 28); más una prueba general de `HasTrigger` (prueba 29). |
| H-5 | Media | Con `FK_BitacoraSeguridad_Evento` y `CK_CatalogoEventosSeguridad_Retencion` no se puede preparar con un `INSERT` el evento "sin catálogo" ni el catálogo con retención menor de 2 años que piden `Un_evento_sin_catalogo_se_guarda_5_anios` y `Nada_de_menos_de_2_anios…`. | DAT-D1 3.1 (FK solo `NOCHECK` para la historia) | Prueba 59: historia insertada **antes** de subir de la v5 a la v6. Prueba 60: `NOCHECK CONSTRAINT` temporal sobre el `CHECK` en una base propia. |
| H-6 | Media | `ContratoConsultasTests.Registradas()` toma todas las constantes con `[ConsultaRegistrada]` de `GPOS.Core.Consultas.*` y las describe contra una **base de empresa**. Ninguna constante de `Consultas/Sistema/` lo lleva hoy. | `ContratoConsultasTests.cs:22-31`; `git grep -c ConsultaRegistrada` en `Consultas/Sistema`: 0 | Guardia: prueba 10 de la sección 5. |
| H-7 | Media | `CambioRncHttpTests.S05_es_solo_del_SUPER_y_valida_el_rango` inserta `PRUEBA_S05_*` (`:205-207`) **y** afirma por esos nombres (`:210-211`). Cambiar solo el `INSERT` deja las dos aserciones en rojo. | `CambioRncHttpTests.cs:204-212` | X-5: cambia también las aserciones (se identifican por `Motivo`). |
| H-8 | Baja | PF43 filtra por nombre de evento en tres lugares más (`:297`, `:298`, `:312`), no solo en el `INSERT` (`:256-259`). | `EsquemaSegundoFactorTests.cs` | X-7: etiqueta en `Detalle`. |
| H-9 | Media | `ValorAnterior` y `ValorNuevo` son `nvarchar(2000)` con `CK_BitacoraSeguridad_Json`. Si C# **corta** el JSON a 2 000 caracteres queda inválido y el `INSERT` falla con 547; DAT-D0 5.1 pide un resumen `{"Excepciones":{"Cambiadas":n,"Huella":"…"}}` (*inferido*, sin texto final). | DAT-D1 3.1 y 4.8 | Prueba 30 de 6.2. |
| H-10 | Baja | DAT-D1 5.1 cuenta `FACTOR_*` como 9, pero hay 11 (se omiten `FACTOR_RESTABLECIDO_SUPER` y `FACTOR_RESTABLECIDO_CONSOLA`, `EventosSeguridad.cs:31-32`); y dice "unos 110" eventos cuando la tabla enumera **48 + 33 = 81**. | `EventosSeguridad.cs` (48 constantes); tabla 5.1 | Pregunta P-7; la prueba 8 de la sección 5 usa el mapa completo. |
| H-11 | Media | `ResolverSucursal_restringida_sin_sucursal_rechaza_en_toda_empresa` se asignó a `UsuariosServiceTests`, que **no existe**. El método vive en `ResolverSucursalTests` (`SucursalesAccesoTests.cs:10`), y ninguna de sus pruebas cubre `SucursalDefault = null` con restricción (`Restringido_solo_entra_a_su_sucursal_predeterminada` prueba `S7` y una lista vacía, no `null`). | `SucursalesAccesoTests.cs`; `UsuariosService.cs:766-768` | Prueba 13 de T1-4 en la clase existente (guardia G: pasa hoy). |
| H-12 | Baja | `CK_UsuariosEmpresas_Nivel/Estado/Origen` y `CK_BitacoraSeguridad_ActorNivel` comparan con la intercalación de la instancia (CI en las instalaciones): `'admin'` o `'habilitada'` pasan el `CHECK`. DAT-D1 usa `BIN2` solo en el nombre del evento. | DAT-D1 3.1 | Pregunta P-6; la prueba 47 documenta el comportamiento actual. |

---

## 4. Pruebas existentes que hay que adaptar en T1-1 (mismo PR)

### 4.1 Las que fijan la versión del esquema (`Version == 5`)

| # | Archivo y línea | Hoy | Cambio esperado |
|---|---|---|---|
| X-1a | `tests/GPOS.Tests/SegundoFactor/EsquemaSegundoFactorTests.cs:96` | `Assert.Equal(5, EsquemaSistema.Version)` | Quitar el literal; la versión queda fijada **una sola vez** en `EsquemaAccesoTests.La_version_del_esquema_de_GPOS_SYSDATA_es_6`. Las demás pasan a comparar con `EsquemaSistema.Version`, para que la versión 7 no repita este trabajo. |
| X-1b | `…EsquemaSegundoFactorTests.cs:109` | marca de la base nueva `Assert.Equal(5, …"GPOS.EsquemaSistema")` | `EsquemaSistema.Version` |
| X-1c | `…EsquemaSegundoFactorTests.cs:131` | marca de la base existente `Assert.Equal(5, …)` | `EsquemaSistema.Version` |
| X-1d | `…EsquemaSegundoFactorTests.cs:146` | `m.Contains($"{EsquemaSistema.Marca} = 5", …)` (mensaje de `ComandoSistema`, que dice `Marca GPOS.EsquemaSistema = 5 (esta versión espera 5)`) | `$"{EsquemaSistema.Marca} = {EsquemaSistema.Version}"` |
| X-1e | `tests/GPOS.Tests/SegundoFactor/EsquemaRecuperacionFactorTests.cs:82` | `Assert.Equal(5, EsquemaSistema.Version)` | quitar (igual que X-1a) |
| X-1f | `…EsquemaRecuperacionFactorTests.cs:95` | marca de la base nueva | `EsquemaSistema.Version` |
| X-1g | `…EsquemaRecuperacionFactorTests.cs:120` | marca de la base existente (después de volver a la 4) | `EsquemaSistema.Version` |
| X-1h | `…EsquemaRecuperacionFactorTests.cs:126` | `m.Contains($"{EsquemaSistema.Marca} = 5", …)` | igual que X-1d |

Además: el método `PF_J2_14_base_nueva_existente_de_la_version_4_y_Migracion_sistema_dan_las_tablas_de_la_via_con_la_marca_5` (`:75`) y los comentarios de `EsquemaRecuperacionFactorTests.cs:13` y `:71` y de `EsquemaSegundoFactorTests.cs:13` y `:85` dicen "marca 5". Renombrar el método a `…con_la_marca_vigente` **cambia su nombre completo**: buscar referencias antes (`git grep PF_J2_14_base_nueva`).

**Verificadas y que NO cambian** (para que nadie las toque por error):
- `Dl02CuentasArranqueTests.cs:270`, `Rg14Lote2Tests.cs:135` y `:242`, `RespaldoPosteriorForkTests.cs:216` y `:259`: comparan con la constante `EsquemaSistema.Version` (o con `> 2`).
- `Rg14CandadoSistemaEstrictoTests.cs:34` (`Assert.Equal(5, …)` cuenta **permisos**: dos `EXECUTE` y tres `DENY`) y `EsquemaRecuperacionFactorTests.cs:215`: filtran por `major_id` de objetos concretos, así que los `DENY` nuevos de D7-P no los alteran.
- `AprovisionamientoTests.cs:43` y `Ola3bTransferenciasMigracionTests.cs:329`: bases de empresa.
- `EsquemaSegundoFactorTests.cs:152` (`marca 3`) y `EsquemaRecuperacionFactorTests.cs:116` (`marca 4`): simulan versiones viejas; siguen válidas.

### 4.2 PF25: cómo debe quedar `BitacoraSeguridadTests` (`:158-205`)
Hoy inserta eventos `'PF25'`, fuera del catálogo: con la FK de T1-1 fallan con 547. Propuesta (ambos métodos usan constantes, no literales: `EventosSeguridad.DerivaReloj` = `FACTOR`, 2 años; `EventosSeguridad.ClaveCambiada` = `CUENTA`, 5 años por P-D0-D03):

`PF25_purga_disparadores_y_MomentoUtc_de_la_base`:
```sql
INSERT dbo.BitacoraSeguridad (MomentoUtc, Evento, Severidad, Usuario) VALUES
  (DATEADD(year, -3, SYSUTCDATETIME()), 'DERIVA_RELOJ',  'I', N'{u}'),   -- se purga (2 años)
  (DATEADD(year, -3, SYSUTCDATETIME()), 'DERIVA_RELOJ',  'I', N'{u}'),   -- se purga
  (DATEADD(hour, -12, DATEADD(year, -2, SYSUTCDATETIME())), 'DERIVA_RELOJ', 'I', N'{u}'),   -- margen de un día: se conserva
  (SYSUTCDATETIME(), 'DERIVA_RELOJ', 'I', N'{u}'),                       -- reciente: se conserva
  (DATEADD(year, -3, SYSUTCDATETIME()), 'CLAVE_CAMBIADA', 'I', N'{u}');  -- NUEVO: 5 años, no se purga a los 3
```
- `PurgarAsync() >= 2` queda igual; el recuento que sobrevive pasa de **2 a 3** (`:170`).
- La parte del disparador deshabilitado (`:172-178`) no cambia: el `DELETE` sigue dando 52002 porque quedan filas que no superan su retención.

`PF25_el_trabajo_omite_la_vuelta_con_el_candado` (`:196-204`): el evento `'PF25'` pasa a `'DERIVA_RELOJ'` (hace 3 años). Nada más.

### 4.3 PF43: cómo debe quedar `EsquemaSegundoFactorTests.PF43_Estricto_gpos_sistema_…` (`:234-330`)
`PF43_VIEJO`, `PF43_MARGEN` y `PF43_NUEVO` pasan a ser **el mismo evento del catálogo** (`DERIVA_RELOJ`), y la etiqueta va en `Detalle` (`nvarchar(400)`):

```sql
INSERT dbo.BitacoraSeguridad (MomentoUtc, Evento, Severidad, Canal, Detalle) VALUES
  (DATEADD(year, -3, SYSUTCDATETIME()), 'DERIVA_RELOJ', 'I', 'SISTEMA', N'PF43_VIEJO'), (… ×3),
  (DATEADD(hour, -12, DATEADD(year, -2, SYSUTCDATETIME())), 'DERIVA_RELOJ', 'I', 'SISTEMA', N'PF43_MARGEN'),
  (SYSUTCDATETIME(), 'DERIVA_RELOJ', 'I', 'SISTEMA', N'PF43_NUEVO'),
  (DATEADD(year, -3, SYSUTCDATETIME()), 'CLAVE_CAMBIADA', 'I', 'SISTEMA', N'PF43_CINCO');   -- NUEVO
```
- `:290` `Assert.Equal(3, EXEC dbo.PurgarBitacoraSeguridad)` **no cambia** (el `PF43_CINCO` se conserva): corre como `gpos_sistema` con los `DENY` de D7-P puestos y el procedimiento lee el catálogo por encadenamiento de propiedad, que es justo lo que hay que probar.
- `:297` y `:298`: `WHERE Evento = 'PF43_NUEVO'` / `'PF43_MARGEN'` → `WHERE Detalle = N'PF43_NUEVO'` / `N'PF43_MARGEN'` (siguen dando 229: el permiso se niega antes que el disparador).
- `:311-312`: `STRING_AGG(Evento…) WHERE Evento LIKE 'PF43[_]%'` → `STRING_AGG(Detalle…) WHERE Detalle LIKE N'PF43[_]%'`; el esperado pasa de `"PF43_MARGEN,PF43_NUEVO"` a `"PF43_CINCO,PF43_MARGEN,PF43_NUEVO"`.
- `:314` (`COUNT … 'SISTEMA_RESTAURADO', 'CANDADO_RESTAURACION_LIBERADO'` = 2) no cambia: ambos están en el catálogo (SISTEMA, 2 años) y son recientes.
- `:247-253` (4 permisos) no cambia; los `DENY` de D7-P se afirman en `PrivilegiosSistemaTests`.

### 4.4 Las demás adaptaciones

| # | Archivo y línea | Hoy | Cambio esperado |
|---|---|---|---|
| X-3 | `tests/GPOS.Tests/SegundoFactor/BitacoraSeguridadTests.cs:64-65` (`PF46_…`) | `Limitados == [4 eventos]` | `[…cuatro, IDENTIFICACION_FALLIDA]`, o mover la aserción a `EventosSeguridadTests` (prueba 5 de la sección 5) y dejar aquí solo `Contains`. El resto de PF46 (`:54-63`) sigue válido: `Todos` sin repetidos, ≤ 40 caracteres y `constantes == Todos` (la lista `Catalogo` no debe ser un campo `const`). |
| X-4 | `…BitacoraSeguridadTests.cs:147` (`El_limitador_aplica_solo_a_los_eventos_limitados`) | usa `Limitados.Count` | sin cambio de código; **verificar** que con cinco limitados el `Total` de `otro` sigue siendo `Limitados.Count` (cada limitado se registra una vez para `otro`). |
| X-5 | `tests/GPOS.Tests/Licencia/CambioRncHttpTests.cs:204-211` | tres `INSERT` de `PRUEBA_S05_API`, `_INFO`, `_VERBO` y aserciones por esos nombres | Eventos del catálogo con el canal y la severidad que el caso necesita: `API`/`A` → `ACCESO_RECHAZADO_CANDADO`; `CONSOLA`/`I` → `SELLADO_INICIAL`; `CONSOLA`/`A` → `CAMBIO_RNC_SUPER` (todos existen). Las aserciones `Contains`/`DoesNotContain` se hacen por `Motivo = N'Prueba S-05'` y por el evento, no por `PRUEBA_S05_*`. |
| X-6 | `tests/GPOS.Tests/SegundoFactor/EsquemaSegundoFactorTests.cs:89` (`PF30_…`) | compara la huella de las tres rutas | **No se cambia el cuerpo**: ya cubre las tablas, columnas, `CHECK`, `DEFAULT`, FK, índices y disparadores nuevos (incluye `parent_class = 1`). Sirve de regresión de ADR-07. Para que no engañe, la prueba 14 de la sección 5 agrega lo que su huella no ve (permisos, `is_not_trusted`, columnas de índice). |
| X-7 | `EsquemaSegundoFactorTests.cs:234` (`PF43_…`) | ver 4.3 | ver 4.3 |
| X-8 | `tests/GPOS.Tests/ModeloNg/RespaldoPosteriorForkTests.cs:179` (`P9_…`) | usa el reverso de S-2 con marca 3 y después `ActualizarAsync` | sin cambio. Sirve de **regresión**: tras D7-A, `ActualizarAsync` sobre una base con marca 3 debe seguir funcionando. |

**Otras clases a correr como regresión en T1-1** (no se modifican): `EsquemaSegundoFactorTests`, `EsquemaRecuperacionFactorTests`, `BitacoraSeguridadTests`, `BitacoraSeguridadHttpTests`, `CambioRncTests`, `CambioRncHttpTests`, `Rg14SistemaTests`, `Rg14CandadoSistemaEstrictoTests`, `Rg14Lote2Tests`, `RespaldoPosteriorForkTests`, `Dl02CuentasArranqueTests`, `LecturaReportesSistemaTests` (rptsis sigue funcionando con D7-A), `EventIdUnicosTests`, `SqlSoloEnLugaresPermitidosTests`, `PruebasNeutralesTests`.

---

## 5. T1-1 · Esquema de `GPOS_SYSDATA` v6 (D7-A y D7-P)

### Fase 1 · Sin base (segundos; en cada commit)

| Ord | Clase.Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 1 | `EsquemaAccesoTests.La_version_del_esquema_de_GPOS_SYSDATA_es_6` | U | `Assert.Equal(6, EsquemaSistema.Version)`; única aserción literal de la versión | Hoy 5 (`EsquemaSistema.cs:73`) | QA |
| 2 | `EsquemaAccesoTests.AccesoDdl_y_AccesoPermisos_no_tienen_GO_ni_llaves` | U | Ni línea `GO`, ni `{`, ni `}` en ninguno de los dos textos (se ejecutan con `ExecuteSqlRaw`; DAT-D1 1.3). Incluye el bloque 4 b generado | NC. Mutante: un nombre de evento o un comentario con llaves | QA |
| 3 | `EsquemaAccesoTests.AccesoDdl_y_AccesoPermisos_son_el_tercer_lote_de_Ddl_y_de_Permisos` | U | `ExtensionesEsquemaSistema.Ddl[2] == EsquemaSistema.AccesoDdl`, `Permisos[2] == AccesoPermisos`, ambas listas de 3 | Hoy dos elementos (`ExtensionesEsquemaSistema.cs:20` y `:23`). Patrón: `Los_permisos_sin_S1_fallan_con_51614` (`EsquemaSegundoFactorTests.cs:342-351`) | D |
| 4 | `EventosSeguridadTests.Identificacion_fallida_esta_en_Limitados` | U | `Limitados` contiene `IDENTIFICACION_FALLIDA` | NC | D |
| 5 | `EventosSeguridadTests.Limitados_conserva_los_cuatro_anteriores_y_agrega_IDENTIFICACION_FALLIDA` | U | Orden y contenido exactos de los cinco (reemplaza la aserción de PF46, H-1) | R | QA |
| 6 | `CatalogoEventosTests.El_catalogo_de_C_sharp_no_repite_nombres_ni_usa_categorias_desconocidas` | U | Nombres únicos (ordinal), `^[A-Z0-9_]{1,40}$`, categoría ∈ las 8, retención `NULL` o 2 a 10 | NC | QA |
| 7 | `CatalogoEventosTests.Todos_se_deriva_del_catalogo_y_conserva_el_orden_de_los_48_existentes` | U | Los 48 primeros de `Todos` son los de hoy y en ese orden (la pantalla usa `Take(25)`, `SegundoFactorSuperPantallasTests.cs:231`); `Todos` = nombres de `Catalogo`; `Catalogo` no es un campo `const` (PF46 `:62`) | Mutante: `Todos` reordenada | QA |
| 8 | `CatalogoEventosTests.Cada_evento_tiene_la_categoria_y_la_retencion_de_DAT_D1_5_1` | U | Mapa fijo **dentro de la prueba**: los 48 existentes (tabla 5.1 más `FACTOR_RESTABLECIDO_SUPER` y `_CONSOLA` → `FACTOR`) y los 33 nuevos, con los tres de RSW-D1 6 (`IDENTIFICACION_FALLIDA` → `CUENTA`; `FIRMA_SIN_TPM_ACEPTADA` y `FIRMA_SIN_TPM_ARRANQUE` → `SISTEMA`). Retención `NULL` salvo `ACCESOS_CONVERTIDOS_INSTALACION` = 5. `CLAVE_CAMBIADA` y `CLAVE_BLOQUEO_CAMBIO` → `CUENTA`; `CUENTAS_FUERA_DE_PADRON` → `SELLO`. Si el desarrollador agrega eventos de D2 a D5, la prueba exige agregarlos al mapa (P-7) | NC. Mutante: `CLAVE_CAMBIADA` en `FACTOR` (la pasaría a 2 años) | QA |
| 9 | `CatalogoEventosTests.El_generador_rechaza_nombres_con_comillas_minusculas_o_categoria_desconocida` | U | El generador del bloque 4 b falla (no devuelve texto) con `A'B`, `abc`, nombre de 41 caracteres o categoría fuera de las 8 (C-8 de DAT-D1) | NC. La firma del generador la fija el desarrollador (`internal` ya es visible a `GPOS.Tests`, `GPOS.Core.csproj:49`) | QA |
| 10 | `AccesoArquitecturaTests.Las_consultas_de_acceso_no_son_ConsultaRegistrada` | A | Ninguna constante de `GPOS.Core.Consultas.Sistema.*` lleva `[ConsultaRegistrada]` (H-6) | G. Mutante: marcar `ConsultasAcceso.Miembros` | QA |
| 11 | `AccesoArquitecturaTests.Todo_evento_escrito_con_literal_en_SQL_de_src_esta_en_EventosSeguridad` | A | En los `INSERT … BitacoraSeguridad` de `src/` (hoy: `SISTEMA_RESTAURADO`, `CANDADO_RESTAURACION_LIBERADO`) y en los `new EventoSeguridad("…")`, cada literal está en `Todos`. Evita un 547 en producción por un evento que solo existe en un `.sql` | G. Mutante: un `INSERT` con `'EVENTO_NUEVO'` | QA |
| 12 | `EventIdUnicosTests.Los_EventId_de_P_D1_01_conservan_su_nombre` | A | Si 4729, 4733 y 4735 a 4741 están declarados, llevan el nombre de P-D1-01 (`IntrospeccionAcceso`, `CatalogoEventosIncompleto`, `FirmaSinTpm`, `AccesoNoDisponible`, `IngresoSuper`, `AccesoEmpresaDenegado`, `ConversionAccesos`, `LlaveFirmaArranque`, `EventoSeguridadNoRegistrado`); 4724 a 4728 y 4734 no cambian | G. Mutante: `4736` con otro nombre. Método nuevo en la clase existente | QA |

### Fase 2 · Pruebas existentes adaptadas (sección 4)
Se hacen aquí: X-1a a X-1h, X-3, X-5 y las reescrituras de PF25 y PF43 (4.2 y 4.3). Cuáles están en rojo antes de construir (y por qué):
- **PF25 y PF43 reescritas:** rojas por **R**. Con la purga de 2 años fijos, el evento `CLAVE_CAMBIADA` de hace 3 años **se purga**, y los recuentos nuevos (3 filas que sobreviven en PF25; `PF43_CINCO` en PF43) no se cumplen.
- **X-3 (PF46):** roja en cuanto `IDENTIFICACION_FALLIDA` entra en `Limitados`; hoy verde.
- **X-5 (S-05):** hoy verde con los eventos del catálogo; roja si se deja el `INSERT` de `PRUEBA_S05_*` después de la FK.
- **X-1a a X-1h:** **verdes hoy** (comparan con la constante, que vale 5). El rojo de la versión lo da la prueba 1 (`La_version_del_esquema_de_GPOS_SYSDATA_es_6`); las demás solo evitan que la versión 7 repita este trabajo.

### Fase 3 · Esquema (una base por prueba)

| Ord | Clase.Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 13 | `EsquemaAccesoTests.Una_base_nueva_queda_en_la_version_6_con_los_objetos_de_D7A` | I | Arranque Amplio: marca 6; existen `UsuariosEmpresas`, `EmpresasPerfiles`, `EmpresasPerfilesPermisos`, `UsuariosEmpresasPerfiles`, `UsuariosEmpresasPermisos`, `CategoriasSeguridad`, `CatalogoEventosSeguridad`, `ConversionReportes` y las columnas nuevas de `Empresas`, `Usuarios`, `BitacoraSeguridad` y `Reportes` | V5 | QA |
| 14 | `EsquemaAccesoTests.Reaplicar_la_version_6_no_cambia_nada` | I | Dos aplicaciones más no cambian la huella. La huella cubre lo que la de PF30 no ve: definición (hash) y `is_disabled` de cada disparador, `is_not_trusted` de FK y `CHECK`, columnas de cada índice con `is_included_column` e `is_descending_key`, y, tras `ComandoSistema.AplicarAsync` (DB-L), los permisos de clase 1 de `gpos_api`. Excluye `modify_date` (`CREATE OR ALTER` lo cambia en cada pasada) | V5. Mutante: `CREATE TABLE` sin `IF OBJECT_ID … IS NULL` (falla al reaplicar) | P |
| 15 | `EsquemaAccesoTests.Una_base_en_la_version_5_sube_a_la_6` | I | DB-5 con datos: tres cuentas, una empresa y bitácora **histórica con eventos fuera del catálogo** (`'PF25'`, `'EVENTO_RETIRADO'`) y una fila de `CLAVE_CAMBIADA` de hace 3 años (que sí está en el catálogo). Al aplicar: marca 6; ninguna fila perdida; la historia sigue (las dos FK de la bitácora quedan `is_not_trusted = 1`); `AdministradaPorSuper = 0` y `FallosVentana = 0` en las filas existentes | V5. Mutante: FK `WITH CHECK` (falla con la historia) | P |
| 16 | `EsquemaAccesoTests.Estricto_no_arranca_con_la_marca_5_y_dice_que_ejecute_sistema` | I | Con la marca 5, `Inicializacion.ExigirMarcaSistemaAsync` lanza y el mensaje contiene `marca 5` y `GPOS.Migracion sistema` (patrón `EsquemaSegundoFactorTests.cs:149-153`) | **Falla hoy**: con `Version = 5` no lanza | QA |
| 17 | `EsquemaAccesoTests.Los_disparadores_deshabilitados_se_habilitan_al_reaplicar` | I | Para los seis disparadores nuevos: `DISABLE TRIGGER` y reaplicar → `is_disabled = 0` (D81-06) | V5. Mutante: sin los `ENABLE TRIGGER` (`DAT-D1 7.1`, últimas líneas del bloque 3) | QA |
| 18 | `EsquemaAccesoTests.Un_disparador_alterado_se_restituye_al_reaplicar` | I | `ALTER TRIGGER TR_UsuariosEmpresas_Version` con cuerpo vacío; reaplicar; el hash vuelve al original | V5 | QA |
| 19 | `EsquemaAccesoTests.D7A_no_retira_nada_de_las_tablas_globales` | I | `Perfiles`, `PerfilesPermisos`, `UsuariosPerfiles`, `UsuariosPermisos`, `Usuarios.RestringirSucursal`, `SucursalDefault` e `IntentosFallidos` siguen con la misma forma (D7-A es aditivo; el retiro es el paso 8 del verbo) | G | QA |
| 20 | `EsquemaAccesoTests.D7A_aplica_con_el_nivel_de_compatibilidad_minimo_130` | I | La base se baja a `NivelCompatibilidad.Minimo` (130) **antes** de aplicar; D7-A aplica sin error y `OPENJSON` e `ISJSON` funcionan (el `CHECK` de JSON y Q9/Q10/Q13 dependen de ellos; el nivel nativo de la instancia de pruebas es mayor y los ocultaría) | V5. Mutante: un `TRIM` o un `STRING_AGG` en el DDL (piden 140) | QA |
| 21 | `EsquemaAccesoTests.Las_columnas_nuevas_tienen_los_tipos_largos_y_nulabilidad_del_diseno` | I | Teoría con la matriz del Anexo A contra `INFORMATION_SCHEMA.COLUMNS`. Es la vigilancia de ADR-50/CP-169 para `GPOS_SYSDATA`: los códigos son `nvarchar(30)` por diseño; `Nivel varchar(5)`, `Estado varchar(10)`, `Origen varchar(10)`, `Categoria varchar(12)`, `Evento varchar(40)`, `ActorNivel varchar(7)` | V5. Mutante: `Categoria varchar(10)` (la errata de C-5) | QA |
| 22 | `EsquemaAccesoTests.Las_claves_primarias_y_unicas_son_las_del_diseno` | I | PK: `(UsuarioCodigo, EmpresaCodigo)` agrupada, las de las hijas, `(EmpresaCodigo, Codigo)`, `(EmpresaCodigo, PerfilCodigo, Opcion)`, `PK_ConversionReportes (EmpresaCodigo, IdOriginal)`; únicas: `UQ_CatalogoEventosSeguridad_EventoCategoria`, `UQ_ConversionReportes_IdNuevo`; columnas y orden | V5 | QA |
| 23 | `EsquemaAccesoTests.Las_claves_foraneas_son_las_del_diseno` | I | Tabla, columnas, referenciada y acción de borrado. Todas `NO ACTION` salvo `FK_EmpresasPerfilesPermisos_Perfil` (`CASCADE`). Solo `FK_BitacoraSeguridad_Evento` y `_EventoCategoria` están `is_not_trusted`. Total de FK nuevas = el del diseño | V5. Mutante: FK simple `(PerfilCodigo)` en lugar de la compuesta | QA |
| 24 | `EsquemaAccesoTests.Las_columnas_de_cada_FK_tienen_el_tipo_largo_y_colacion_de_la_referenciada` | I | Para toda FK de los objetos nuevos: `system_type_id`, `max_length` y `collation_name` iguales (evita la sorpresa de S-3 de DAT-D1) | V5 | QA |
| 25 | `EsquemaAccesoTests.Los_indices_nuevos_son_los_del_diseno_y_no_hay_otros` | I | `IX_UsuariosEmpresas_Empresa_Estado (EmpresaCodigo, Estado) INCLUDE (Nivel)`; `IX_UsuariosEmpresasPerfiles_Empresa_Perfil`; `IX_UsuariosEmpresasPermisos_Empresa_Opcion`; `IX_BitacoraSeguridad_Empresa (Empresa, Id DESC) INCLUDE (MomentoUtc, Evento, ActorNivel)`; ningún otro índice nuevo (DAT-D1 4.2 los descarta) | V5. Mutante: `UltimoAcceso` incluido en el índice de estado (costo de escritura en cada ingreso) | QA |
| 26 | `EsquemaAccesoTests.Las_restricciones_CHECK_y_los_valores_por_omision_son_los_del_diseno` | I | Nombres y definición de los `CHECK` de DAT-D1 3.1 y los `DEFAULT` (`RestringirSucursal` 0, `VersionPrivilegios` 1, `FechaAlta` `SYSUTCDATETIME()`, `Inhabilitado` 0, `AdministradaPorSuper` 0, `FallosVentana` 0); y que `CK_Usuarios_Nivel` y `CK_Reportes_Ambito` **no** existen aún | V5 | QA |
| 27 | `CatalogoEventosTests.Las_ocho_categorias_tienen_su_retencion_y_visibilidad` | I | `ACCESO` 5 años visible; `MEMBRESIA` 5 visible; `CUENTA` 5; `NOTIFICACION` 5; `FACTOR`, `LICENCIA`, `SELLO`, `SISTEMA` 2; solo `ACCESO` y `MEMBRESIA` con `VisibleAdmin = 1` | V5 | QA |
| 28 | `EsquemaAccesoTests.Con_D7A_aplicado_EF_guarda_Usuarios` | I | **Primero**: el disparador `TR_Usuarios_SuperSinMembresias` existe y está habilitado (esto lo pone en rojo hoy). Después, por EF: alta, **cambio de `PasswordHash`/`DebeCambiarClave`**, **inicio de sesión (`SesionId`, `SesionActividad`)**, **cambio de `Nivel` de `USER` a `ADMIN`** y baja de una cuenta sin membresías (CASCADE de las tablas globales). Sin error 334 (H-4) | **Falla hoy** por la precondición. Mutante: quitar `HasTrigger` → 334 en el `UPDATE` | D |
| 29 | `EsquemaAccesoTests.Todo_disparador_de_una_tabla_mapeada_en_EF_esta_declarado_con_HasTrigger` | I | Para cada tabla del modelo relacional de `SistemaDbContext`, el conjunto de disparadores de `sys.triggers` es igual al que EF declara; y en `Usuarios` es exactamente `{TR_Usuarios_SuperSinMembresias}`. Generaliza la decisión candidata 4 de DAT-D1 (la API de EF es `ITable.Triggers`, *inferido*) | **Falla hoy**: el conjunto de `Usuarios` está vacío. Mutante: quitar `HasTrigger` | QA |

### Fase 4 · Restricciones y disparadores de las membresías (`RestriccionesMembresiaTests`, fixture compartida)
Tipo: todas **I**. Datos: dos empresas `A` y `B`, una cuenta `USER`, una `ADMIN` y una `SUPER` (SQL directo; el ayudante `AccesoPruebas` llega con T1-2). Cada prueba usa códigos únicos (`Marca()` como en `BitacoraSeguridadTests.cs:48`). Todas fallan hoy por **V5** (las tablas no existen). Cuando una prueba aísla un disparador, sube la versión (`VersionPrivilegios + 1`) para que no salte antes el 51619.

| Ord | Método | Afirma | Mutante | Origen |
|---|---|---|---|---|
| 30 | `E51619_la_version_de_privilegios_no_retrocede` | `UPDATE … SET VersionPrivilegios = VersionPrivilegios - 1` → 51619 | disparador sin la comparación `i.VersionPrivilegios < d.VersionPrivilegios` | P |
| 31 | `E51619_cambiar_estado_nivel_restriccion_o_sucursal_sin_subir_la_version` (teoría de 4) | Cada cambio con la misma versión → 51619; con `+1` → sin error | disparador sin la rama de igual versión | QA |
| 32 | `E51619_reutilizar_una_fila_en_BAJA_sube_la_version` | `BAJA → HABILITADA` con la misma versión → 51619; con `+1` → válido | M10 | P |
| 33 | `E51619_la_clave_el_origen_y_el_alta_no_cambian` (teoría) | Cambiar `EmpresaCodigo` (a otra empresa existente, sin hijas), `Origen`, `FechaAlta` o `UsuarioAlta` → 51619 | disparador sin la comparación de `Origen`, `FechaAlta` y `UsuarioAlta` | QA |
| 34 | `Actualizar_solo_UltimoAcceso_SesionesRevocadas_SelloMembresia_o_FechaModificacion_no_exige_subir_la_version` (teoría) | C-1 de DAT-D1: el ingreso a una empresa (Q27) actualiza `UltimoAcceso` en cada inicio de sesión y no puede pedir versión | disparador que exige subir la versión ante cualquier `UPDATE` | D |
| 35 | `Un_UPDATE_sin_cambio_de_valor_no_da_error` | `SET Nivel = Nivel` no dispara 51619 | — | QA |
| 36 | `Un_UPDATE_de_varias_filas_con_una_invalida_no_cambia_ninguna` | Atomicidad de la sentencia | — | QA |
| 37 | `Un_UPDATE_de_cero_filas_no_da_error_en_ningun_disparador` | `WHERE 1=0` en las cinco tablas con disparador | — | QA |
| 38 | `E51620_una_membresia_no_se_borra` | `DELETE` de una fila y de varias → 51620; `DELETE … WHERE 1=0` → sin error | disparador sin `INSTEAD OF` | P |
| 39 | `E51623_una_membresia_en_BAJA_no_tiene_perfiles_ni_excepciones` (teoría de 5 vías) | (a) pasar a `BAJA` con un perfil; (b) con una excepción; (c) `INSERT` de perfil sobre `BAJA`; (d) de excepción; (e) `UPDATE` que mueve una hija a una membresía en `BAJA` (C-3). Todas → 51623 | solo `INSERT` vigilado | P |
| 40 | `E51623_pasar_a_BAJA_sin_hijas_es_valido` | Borrar las hijas y luego `BAJA` con `+1` → válido | — | QA |
| 41 | `E51624_el_SUPER_no_tiene_membresias` | `INSERT` `HABILITADA` y `SUSPENDIDA` de un `SUPER` → 51624; `INSERT` de varias filas con una `SUPER` → ninguna entra; `BAJA` → válido; `BAJA → HABILITADA` con `+1` → 51624 | — | P |
| 42 | `E51625_una_cuenta_con_membresias_no_pasa_a_SUPER` | `UPDATE Usuarios SET Nivel = 'SUPER'` con una membresía `HABILITADA` → 51625; con solo `BAJA` → válido; `UPDATE Descripcion` no dispara; `SUPER → SUPER` sin membresías → válido | — | P |
| 43 | `Las_FK_compuestas_impiden_asignar_un_perfil_de_otra_empresa` | Hija `(U, A, perfil que solo existe en B)` → 547 (aislamiento entre empresas) | M11 | QA |
| 44 | `Una_membresia_exige_cuenta_y_empresa_existentes_y_no_permite_borrarlas` | `INSERT` con cuenta o empresa inexistente → 547; `DELETE` de la `Usuarios` o `Empresas` con membresía → 547 (R-D1D-06 a nivel SQL) | FK con `CASCADE` | QA |
| 45 | `Borrar_un_perfil_asignado_da_547_y_uno_sin_asignaciones_borra_sus_permisos_en_cascada` | `NO ACTION` en la asignación; `CASCADE` solo en `EmpresasPerfilesPermisos` | M11 | QA |
| 46 | `Las_restricciones_CHECK_rechazan_lo_que_el_diseno_prohibe` (teoría) | `Nivel` ∉ {`ADMIN`,`USER`}; `Estado` y `Origen` inválidos; `VersionPrivilegios = 0`; `RestringirSucursal = 1` con sucursal `NULL`; `SUSPENDIDA` sin fecha, cuenta o motivo; motivo de 9 caracteres; motivo de 10 espacios (se descarta con `LTRIM(RTRIM())`); `FallosVentana = -1` → 547. Con 10 caracteres reales o `HABILITADA` sin motivo → válido | `LEN(MotivoEstado) >= 10` sin `RTRIM` | QA |
| 47 | `Los_CHECK_de_Nivel_Estado_y_Origen_distinguen_mayusculas` | **Documenta el comportamiento actual** con la intercalación de la instancia (*inferido*: CI acepta `'admin'`). Si B contesta P-6 con `BIN2`, se invierte | — (H-12) | QA |

### Fase 5 · Catálogo y bitácora en base (`CatalogoEventosTests`)

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 48 | `El_catalogo_de_la_base_es_igual_a_EventosSeguridad` | I | En una base nueva, en los dos sentidos: mismo conjunto de eventos, misma categoría, misma retención. Incluye los tres de RSW-D1 | V5. Mutante: un evento de C# sin su fila | P |
| 49 | `Un_evento_sin_categoria_valida_lo_rechaza_la_FK` | I | `INSERT` con evento desconocido → 547; con evento válido y `Categoria` ajena (`FACTOR` para un evento de `ACCESO`) → 547 (FK compuesta); con la pareja correcta → válido; con `Categoria` `NULL` → válido (vale la simple) | V5 | P |
| 50 | `Cambiar_la_categoria_de_un_evento_da_51626` | I | Se aplica el texto de `AccesoDdl` con **un reemplazo de texto** que mueve `FACTOR_ALTA_INICIADA` de `FACTOR` a `SISTEMA` sobre una base v6: → 51626 y el catálogo no cambia. Se repite en una base nueva **sin filas en la bitácora** (la regla no depende de la historia) | V5. Mutante: M12 (el `MERGE` actualiza la categoría) | D |
| 51 | `Cambiar_la_retencion_de_un_evento_actualiza_el_catalogo_sin_error` | I | `ACCESOS_CONVERTIDOS_INSTALACION` de 5 a 3 en el texto → el catálogo queda en 3; sin `WHEN NOT MATCHED BY SOURCE` | V5 | QA |
| 52 | `Un_evento_retirado_del_codigo_sigue_en_el_catalogo` | I | Quitar un evento del texto y reaplicar no borra su fila (la historia sigue siendo válida) | V5 | QA |
| 53 | `El_CHECK_del_nombre_distingue_mayusculas_y_rechaza_caracteres_raros` | I | `abc`, `A B`, `A'B`, `ÁB` → 547 (comparación `BIN2`); `A_1` → válido | V5 | QA |
| 54 | `Las_FK_de_la_bitacora_no_validan_la_historia_pero_si_lo_nuevo` | I | Fila histórica con evento fuera del catálogo sigue ahí tras subir a v6 (usa la DB-5 de la prueba 15); un `INSERT` nuevo con ese evento → 547 | V5. Mutante: `WITH CHECK` | QA |
| 55 | `Los_CHECK_de_la_bitacora_ActorNivel_Json_EmpresaCategoria_e_IngresoSuper` (teoría) | I | `ActorNivel` fuera de {`SUPER`,`ADMIN`,`USER`,`SISTEMA`} → 547; `ValorAnterior` no JSON → 547; `ACCESO` o `MEMBRESIA` sin `Empresa` → 547 salvo `ACCESO_EMPRESA_DENEGADO`; `INGRESO_SUPER` sin motivo, con 9 caracteres o con 10 espacios → 547; con 10 caracteres → válido | V5 | QA |
| 56 | `La_API_en_Release_no_arranca_si_falta_un_evento_en_el_catalogo_y_registra_4733` | I | **Condicional a P-4.** Compara `Todos` con la tabla antes de abrir el puerto; si falta uno en Release: no arranca y registra EventId 4733 | NC | QA |

### Fase 6 · Purga por categoría (`PurgaBitacoraTests`)
Tipo: todas **I**. Cada prueba usa un marcador propio en `Usuario` (como PF25). La retención sale del catálogo: `DERIVA_RELOJ` (`FACTOR`, 2 años), `CLAVE_CAMBIADA` (`CUENTA`, 5), `INGRESO_EMPRESA` (`ACCESO`, 5), `ACCESOS_CONVERTIDOS_INSTALACION` (`SISTEMA` con excepción de 5).

| Ord | Método | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|
| 57 | `Un_evento_de_ACCESO_de_3_anios_no_se_purga` | Tras `PurgarBitacoraSeguridad`, la fila sigue | NC (`INGRESO_EMPRESA` aún no existe en `EventosSeguridad`). Mutante M6: con la purga de 2 años fijos la fila desaparece | D |
| 58 | `Uno_de_FACTOR_de_3_anios_si` | Se purga (`DERIVA_RELOJ`) | G: pasa hoy. Mutante: purga que no borra nada | D |
| 59 | `Un_evento_sin_catalogo_se_guarda_5_anios` | Fila de hace 3 años con un evento fuera del catálogo **insertada en una DB-5 antes de subir a la v6** (H-5) → sigue tras purgar; la de hace 6 años → se purga | M6 | D |
| 60 | `Nada_de_menos_de_2_anios_y_un_dia_se_purga_aunque_el_catalogo_diga_otra_cosa` | En una base propia: `NOCHECK CONSTRAINT CK_CatalogoEventosSeguridad_Retencion` y `UPDATE … RetencionAnios = 1` para `DERIVA_RELOJ`; fila de hace 13 meses → sigue; la de 2 años y 12 horas → sigue (margen del día); la de 2 años y 2 días → se purga | procedimiento sin `@corte` | D |
| 61 | `La_retencion_propia_del_evento_manda_sobre_la_de_la_categoria` | `ACCESOS_CONVERTIDOS_INSTALACION` (5) de hace 3 años sigue; un `SISTEMA_RESTAURADO` (2) de hace 3 años se purga | procedimiento que lee solo la categoría | QA |
| 62 | `El_limite_superior_de_5_anios_se_respeta` | `INGRESO_EMPRESA` de hace 4 años sigue; de 5 años y 2 días → se purga | `ISNULL(…, 5)` mal puesto | QA |
| 63 | `El_disparador_rechaza_el_DELETE_directo_de_lo_que_no_supera_su_retencion_con_52002` | `DELETE` directo (administrador): `ACCESO` de 3 años → 52002; `FACTOR` de 3 años → válido; `FACTOR` de 1 año → 52002; sin catálogo de 4 años → 52002; sin catálogo de 6 años → válido. El disparador y el procedimiento se prueban **por separado** (cada uno puede estar bien y el otro mal) | M6 | QA |
| 64 | `La_purga_conserva_su_contrato_Lote_Purgadas_y_limpia_acuses_huerfanos` | `@Lote` `NULL`, 0 y 5000 no fallan (se usa 1000; con 1 500 filas viejas se purgan todas); un solo resultado `Purgadas`; con lote 2 sobre 7 filas borra las 7; borra los acuses de eventos purgados y conserva el del vigente (lo exige `PF_J2_14_Estricto…`, `:243-249`) | procedimiento sin la limpieza de acuses | QA |
| 65 | `Una_segunda_purga_devuelve_cero` | Idempotencia | — | QA |

### Fase 7 · Privilegios (`PrivilegiosSistemaTests`, DB-L con el login de `LoginsPruebaRg14`)
Tipo: todas **I**.

| Ord | Método | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|
| 66 | `D7P_la_identidad_de_la_API_no_borra_membresias` | Como `gpos_sistema`: `DELETE` → 229 (el permiso se niega antes que el disparador); como administrador la misma fila → 51620. Dos capas distintas | V5. Mutante: sin el `DENY` | P |
| 67 | `D7P_la_API_no_escribe_el_catalogo` | `INSERT`, `UPDATE` y `DELETE` sobre `CatalogoEventosSeguridad`, `CategoriasSeguridad` y `ConversionReportes` → 229; `SELECT` → válido | V5 | D |
| 68 | `D7P_la_API_si_inserta_y_actualiza_membresias_y_sus_hijas` | `INSERT`/`UPDATE` de `UsuariosEmpresas` y hijas funcionan con los disparadores corriendo con su identidad (los disparadores leen `Usuarios` y las hijas; el `GRANT` de S1 lo permite) | V5 | QA |
| 69 | `D7P_la_API_inserta_en_la_bitacora_con_las_FK_aunque_no_escriba_el_catalogo` | `INSERT` de un evento válido funciona; la FK no exige permiso sobre el catálogo | V5 | QA |
| 70 | `D7P_la_API_actualiza_Usuarios_y_el_disparador_de_Usuarios_corre_con_su_identidad` | `UPDATE Usuarios SET Nivel = …` como `gpos_sistema` → sin 229 | V5 | QA |
| 71 | `D7P_sin_el_rol_gpos_api_lanza_51614` | `DROP ROLE gpos_api` y ejecutar `AccesoPermisos` → 51614 (C-6; patrón `Los_permisos_sin_S1_fallan_con_51614`) | NC | QA |
| 72 | `D7P_es_idempotente` | Dos ejecuciones dejan el mismo conjunto de permisos | NC | QA |
| 73 | `D7P_el_usuario_de_reportes_del_sistema_no_lee_las_tablas_nuevas` | Con `CredencialesLectura.RolSistemaSql` y `SqlSimulado.UsuarioAsync(… "gpos_rpt_sis")`: `SELECT` sobre `dbo.UsuariosEmpresas`, `EmpresasPerfiles`, `CatalogoEventosSeguridad` → 229 (aislamiento: reportes solo ve vistas `rptsis`, ADR-40). DAT-D1 9 dice "sin cambios en D1" | G. Mutante: `GRANT SELECT` sobre el esquema `dbo` a `gpos_rpt_sis` | QA |

### Fase 8 · Reverso
El reverso de 7.4 no está en un archivo. El patrón existente es `database/sistema/reverso-h11-s2.sql`, que `RespaldoPosteriorForkTests.GuionReverso()` lee de disco (`:159-160`). Propuesta (P-1): `database/sistema/reverso-db7-d1.sql`.

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 74 | `EsquemaAccesoTests.El_reverso_deja_la_base_como_en_la_version_5_salvo_las_columnas_conservadas` | I | Sobre una DB-N sin membresías: desaparecen las ocho tablas, los disparadores, las FK, los `CHECK` y el índice de la bitácora; quedan `AdministradaPorSuper`, `SesionEmpresa`, `FallosVentana*` y las columnas nuevas de la bitácora; la marca **sigue en 6** (R-D14: no baja); una segunda ejecución no cambia nada; después un `ActualizarAsync` devuelve la huella de la prueba 14 | NC (archivo inexistente) | D |
| 75 | `EsquemaAccesoTests.El_reverso_se_detiene_con_51622_si_hay_membresias_o_Accesos_Modelo` | I | Con una fila en `UsuariosEmpresas` → 51622 y nada cambia; con la marca `Accesos.Modelo` en `Configuracion` → 51622 | NC | QA |
| 76 | `EsquemaAccesoTests.El_reverso_quita_el_disparador_de_Usuarios` | I | Tras el reverso `sys.triggers` de `Usuarios` queda vacío (la API v5 depende de ello: R-D1D-11) | NC | QA |

**Total T1-1:** 12 (fase 1) + 17 (fase 3) + 18 (fase 4) + 9 (fase 5) + 9 (fase 6) + 8 (fase 7) + 3 (fase 8) = **76 pruebas nuevas**, más los 13 cambios en pruebas existentes de la sección 4.

---

## 6. T1-2 · Núcleo de acceso en `GPOS.Core`

Depende de T1-1. Datos: DB-N + escenario ESC (Anexo D) construido con `AccesoPruebas` (T1-0). Filtro: `FullyQualifiedName~EstadoAccesoTests` y las demás clases de esta sección.

### 6.1 Q1 y `ICupoEmpresas`

| Ord | Clase.Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 1 | `AccesoPruebasTests.El_escenario_EST8_crea_las_siete_cuentas_con_sus_membresias` | I | P, Q, R, S, T, V y W con las membresías, perfiles y excepciones de EST §8 | NC | P |
| 2 | `AccesoPruebasTests.El_ayudante_no_escribe_en_las_tablas_globales_y_es_idempotente_por_base` | I | `CrearCuentaAsync` y `DarMembresiaAsync` solo tocan las tablas nuevas; repetir no duplica | NC | QA |
| 3 | `EstadoAccesoTests.Q1_devuelve_cuenta_empresa_y_membresia_en_un_viaje` | I | Con `ComandosSql`: **un solo** comando enviado a la base; los campos de DAT-D1 4.3 poblados | NC | P |
| 4 | `EstadoAccesoTests.Q1_membresia_SUSPENDIDA_da_sin_acceso` | I | Estado `SUSPENDIDA` en el resultado; el evaluador (T1-5) la tratará como sin acceso | NC | P |
| 5 | `EstadoAccesoTests.Q1_empresa_inhabilitada_da_sin_acceso` | I | `EmpresaInhabilitada = 1` | NC | P |
| 6 | `EstadoAccesoTests.Q1_SUPER_sin_membresia_tiene_nivel_efectivo_SUPER` | I | Sin fila de membresía, `NivelCuenta = SUPER`; `FactorAlta` solo si hay secreto | NC | P |
| 7 | `EstadoAccesoTests.Q1_con_la_version_en_cache_no_trae_permisos` | I | Con `@versionEnCache` igual a la versión, solo el conjunto 1; con otra o `NULL`, los conjuntos 2 y 3 | NC. Mutante: `IF EXISTS` siempre verdadero | P |
| 8 | `EstadoAccesoTests.D1_el_sello_de_membresia_aun_no_se_exige` | I | `SelloMembresia` se lee y el resultado es "no aplica" (D3 la invierte) | NC | P |
| 9 | `EstadoAccesoTests.Q1_membresia_BAJA_o_inexistente_da_sin_acceso_y_sin_permisos` | I | Con `BAJA` o sin fila, los conjuntos 2 y 3 no se envían (el `IF EXISTS` exige `HABILITADA`) | NC. Mutante: `Estado <> 'BAJA'` | QA |
| 10 | `EstadoAccesoTests.Q1_cuenta_inhabilitada_cuenta_o_empresa_inexistente` (teoría) | I | Cuenta inhabilitada → fila con `CuentaInhabilitada`; cuenta inexistente → cero filas; empresa inexistente → fila con `Empresa` `NULL` | NC | QA |
| 11 | `EstadoAccesoTests.Q1_trae_los_perfiles_habilitados_y_las_excepciones_y_omite_los_perfiles_inhabilitados` | I | Conjunto 2 = excepciones; conjunto 3 = permisos de los perfiles con `Inhabilitado = 0` | NC. Mutante: sin el predicado de perfil | QA |
| 12 | `EstadoAccesoTests.Q1_no_mezcla_los_permisos_de_otras_empresas` | I | Cuenta con membresías en A y B: pedir A no trae nada de B (QA-17) | NC. Mutante: Q1 sin `EmpresaCodigo` en la unión | QA |
| 13 | `EstadoAccesoTests.Q1_envia_los_parametros_con_el_tipo_de_su_columna` | I | `@usuario` y `@empresa` `nvarchar(30)`; `@versionEnCache` `int` (`ComandosSql` con `Size`; DAT-D1 4.1) | NC | QA |
| 14 | `EstadoAccesoTests.Q1_conjunto1_lee_12_paginas_o_menos` | I | DEMO-50: con `SET STATISTICS IO ON` y `InfoMessage`, ≤ 12 lecturas lógicas (conjunto 1 + `IF EXISTS`). Determinista, no mide tiempo | NC | D |
| 15 | `EstadoAccesoTests.Q1_plan_sin_recorridos` | I | Con `SET STATISTICS XML ON`: sin `Index Scan`, `Clustered Index Scan`, `Table Scan` ni `Key Lookup` | NC | D |
| 16 | `EstadoAccesoServiceTests.Un_1205_se_reintenta_una_vez_y_el_segundo_da_ACCESO_NO_DISPONIBLE_nunca_401` | U | **Condicional a P-5.** Con un doble que lanza 1205: un reintento si quedan más de 500 ms de los 2 s; después `ACCESO_NO_DISPONIBLE` con EventId 4736 | NC | QA |
| 17 | `CupoEmpresasTests.Cuenta_solo_membresias_HABILITADA_con_cuenta_habilitada` | I | RSW-D1 9: cuenta inhabilitada no consume | NC. Mutante: contar solo `Estado = HABILITADA` | R |
| 18 | `CupoEmpresasTests.No_cuenta_SUSPENDIDA_BAJA_ni_otras_empresas` | I | — | NC | QA |
| 19 | `CupoEmpresasTests.Habilitar_una_cuenta_con_membresias_pasa_a_consumir` | I | La misma cuenta, inhabilitada y luego habilitada, cambia el consumo en cada empresa | NC | QA |

### 6.2 Permisos y bitácora de acceso

| Ord | Clase.Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 20 | `PermisosEmpresaTests.Los_permisos_de_A_no_incluyen_los_perfiles_de_B` | I | Misma cuenta en A y B con perfiles distintos | NC | P |
| 21 | `PermisosEmpresaTests.Editar_un_perfil_de_A_sube_la_version_solo_de_sus_miembros` | I | Q6: solo las membresías de A que tienen ese perfil; no las de B ni las que no lo tienen | NC. Mutante: subir toda la empresa | P |
| 22 | `PermisosEmpresaTests.La_siembra_por_empresa_es_idempotente_y_sube_la_version` | I | SD0-11 y R-DB7-10: dos siembras no duplican; la versión sube una vez | NC | P |
| 23 | `PermisosEmpresaTests.La_siembra_no_sube_la_version_de_miembros_en_BAJA_ni_de_otras_empresas` | I | — | NC | QA |
| 24 | `PermisosEmpresaTests.EfectivosAsync_por_empresa_es_igual_a_Combinar_del_modelo_anterior` | I | Para los mismos datos (incluidas opciones `rpt:{id}`), `EfectivosAsync(cuenta, empresa)` sobre las tablas nuevas = `Permisos.Combinar` sobre las globales. Es la base de E7 (T1-4) | NC | QA |
| 25 | `PermisosEmpresaTests.Un_perfil_inhabilitado_no_aporta_permisos` | I | — | NC | QA |
| 26 | `PermisosEmpresaTests.Dos_siembras_o_ediciones_a_la_vez_no_duplican_ni_dan_1205` | I | Dos hilos con barrera; PK impide duplicados; ningún 1205/1222 (**orden de bloqueos**; ver P-5 sobre si la siembra toma el padrón) | NC | QA |
| 27 | `BitacoraAccesoTests.Un_cambio_de_privilegios_escribe_antes_y_despues_en_la_misma_transaccion` | I | `PRIVILEGIOS_CAMBIADOS` con `ValorAnterior`/`ValorNuevo` JSON válidos; al hacer `ROLLBACK` no queda la fila | NC | P |
| 28 | `BitacoraAccesoTests.En_una_ruta_de_fallo_el_evento_que_no_se_escribe_no_revierte_el_contador` | I | Sentencia aparte (SD0-07); con el evento retirado del catálogo, el contador queda y se registra EventId 4741 | NC | P |
| 29 | `BitacoraAccesoTests.Un_cambio_de_administracion_se_revierte_si_su_evento_no_esta_en_el_catalogo` | I | Lo contrario de la anterior: en cambios de administración, revertir es lo correcto (TRZ-01) | NC | QA |
| 30 | `BitacoraAccesoTests.Un_ValorNuevo_de_mas_de_2000_caracteres_se_guarda_como_resumen_JSON_valido` | I | H-9: 60 excepciones → el resumen cumple `ISJSON`; nunca un corte a 2 000 | NC. Mutante: `Substring(0, 2000)` | QA |
| 31 | `BitacoraAccesoTests.La_categoria_la_pone_el_catalogo_de_C_sharp` | I | El llamador no puede pasar una categoría; la FK compuesta no falla para ningún evento de `Catalogo` | NC | QA |
| 32 | `BitacoraAccesoTests.El_Actor_de_RegistrarEvento_admite_128_caracteres` | I | `EQUIPO\cuenta` de 100 caracteres (DAT-D1 4.1; `Actor nvarchar(128)`) | NC. Mutante: `Actor nvarchar(30)` | QA |
| 33 | `BitacoraAccesoTests.Los_eventos_con_reglas_de_datos_se_rechazan_antes_de_llegar_a_la_base` (teoría) | U | `INGRESO_SUPER` sin motivo o con menos de 10; `ACCESO`/`MEMBRESIA` sin empresa salvo `ACCESO_EMPRESA_DENEGADO`; `ActorNivel` inválido → excepción de regla (400), no 547/500 | NC | QA |
| 34 | `BitacoraAccesoTests.Los_parametros_de_RegistrarEvento_viajan_con_el_tipo_de_su_columna` | I | `@evento varchar(40)`, `@severidad char(1)`, `@categoria varchar(12)`, `@actorNivel varchar(7)`, `@empresaActua nvarchar(30)`, `@antes`/`@despues nvarchar(2000)` | NC | QA |

**Total T1-2:** 34 pruebas nuevas (las filas 1 a 34 de esta sección).

---

## 7. T1-3 · Membresías, ADMIN y SUPER por empresa

Depende de T1-2. La parte de mayor riesgo: **Q3-P (el último ADMIN)** y **Q13 (guardar privilegios)**. Van primero.

### 7.1 Q3-P: el caso que nunca daba 409

**Escenario (Anexo D, ESC-Q3P):** empresas `A` (`AdministradaPorSuper = 0`), `B`, `C`; cuentas `a1`, `a2` (ADMIN de A), `inh` (ADMIN de A con la cuenta inhabilitada), `sus` (ADMIN de A con membresía `SUSPENDIDA`), `baja` (ADMIN de A con membresía `BAJA`), `u1` (USER de A), `xb` (ADMIN solo de B).

**Ord 0a · Prueba de la prueba (se escribe primero y pasa siempre; tipo I):** `DominioAdministracionTests.Q3P_el_texto_de_la_revision_1_falla_los_casos_1_y_2` (Anexo C): ejecuta el texto defectuoso como constante **privada de la prueba** y afirma `OtrosAdmin = 1` sin otros ADMIN (caso 1) y `AdministradaPorSuper` `NULL` con todos inhabilitados (caso 2). Si el escenario no discrimina, esta falla y se corrige antes de seguir. Es lo que RSW-D1 y DAT-D1 piden con "se comprueba que falla".

**Ord 0b · A nivel SQL (tipo I)** (`DominioAdministracionTests.Q3P_devuelve_el_conteo_esperado_en_cada_escenario`, teoría de S1 a S12; ejecuta `OtrosAdminProvisional` y compara `(OtrosAdmin, AdministradaPorSuper)`; salvo S9, **después** del `UPDATE` que cambia a `a1`; Origen R y QA). **Ord 0c:** `DominioAdministracionTests.Q3P_empresa_inexistente_no_devuelve_fila` (S11 por separado, nombre de DAT-D1):

| Caso | Escena (cambiado = `a1`) | Esperado | Con el texto de la rev. 1 |
|---|---|---|---|
| S1 | A sin otros miembros | `(0, 0)` | `(1, 0)` ✗ |
| S2 | `inh` (cuenta inhabilitada) es el otro ADMIN | `(0, 0)` | `(0, NULL)` ✗ |
| S3 | `sus` (SUSPENDIDA) | `(0, 0)` | `(1, 0)` ✗ |
| S4 | `baja` | `(0, 0)` | `(1, 0)` ✗ |
| S5 | `xb` (ADMIN de B, no de A) | `(0, 0)` | `(1, 0)` ✗ |
| S6 | `u1` (USER de A) | `(0, 0)` | `(1, 0)` ✗ |
| S7 | `a2` habilitado | `(1, 0)` | `(1, 0)` |
| S8 | `inh` y `a2` | `(1, 0)` | `(1, 0)` |
| S9 | `a1` y `a2` ADMIN; la consulta se ejecuta **antes** del `UPDATE` sobre `a1` (la exclusión `<> @usuario` es inocua, DAT-D1 4.4) | `(1, 0)` | `(1, 0)` |
| S10 | A con `AdministradaPorSuper = 1`, sin otros | `(0, 1)` | `(1, 1)` ✗ |
| S11 | empresa inexistente | **ninguna fila** | una fila (aggregate) ✗ |
| S12 | el otro ADMIN es `SUPER` (se deshabilita `TR_UsuariosEmpresas_SinSuper` y `TR_Usuarios_SuperSinMembresias` con `try/finally ENABLE`) | `(0, 0)` | — (defensa `u.Nivel <> N'SUPER'`) |

Además: `AdministradaPorSuper` llega como `bit` (se lee como `bool`, no `int`; cambio de tipo de la revisión 2).

**A nivel HTTP (tipo IH)** (`MiembrosHttpTests`, `ApiMvpFactory`; las tres transiciones que dejan de ser ADMIN: suspender, dar de baja y degradar a `USER`; los nombres con origen D, P o R son los de DAT-D1, PLAN-D1 y RSW-D1):

| Ord | Método | Afirma | Mutante | Origen |
|---|---|---|---|---|
| 1 | `Suspender_al_ultimo_ADMIN_responde_409_ULTIMO_ADMIN` | S1: 409, código `ULTIMO_ADMIN`, y **nada cambia**: estado, versión, hijas y bitácora (el `ROLLBACK` deshace todo) | M1 | P y R |
| 2 | `Con_los_demas_ADMIN_inhabilitados_tambien_es_el_ultimo` | S2: 409 (no 200, no 500 por `DBNull`) | M1 | R |
| 3 | `Suspender_al_ultimo_ADMIN_responde_409_si_los_otros_estan_suspendidos_de_baja_en_otra_empresa_o_son_USER` (teoría de S3 a S6) | 409 en cada uno | M1 | QA |
| 4 | `Con_AdministradaPorSuper_no_hay_409` | **Par obligatorio** (H-3), dentro del mismo método: la misma escena con la marca en 0 → 409 y con la marca en 1 → 200 | M1 (el texto viejo pasa el primer miembro del par y falla el segundo) | R |
| 5 | `Dar_de_baja_al_ultimo_ADMIN_responde_409_y_deja_sus_perfiles_y_excepciones` | La baja borra hijas y sube la versión dentro de la misma transacción; el 409 las **restituye** | transacción que confirma el borrado | QA |
| 6 | `Degradar_a_USER_al_ultimo_ADMIN_responde_409` | La misma regla por Q13. Además: nivel, versión y las hijas quedan como estaban (Q13 ya borró e insertó hijas cuando corre Q3-P: el `ROLLBACK` debe deshacerlo) | Q3-P antes del `UPDATE` | D |
| 7 | `Cambiar_sucursal_o_perfiles_del_ultimo_ADMIN_si_sigue_siendo_ADMIN_responde_200` | La regla solo aplica cuando deja de ser ADMIN | regla aplicada siempre | QA |
| 8 | `Con_dos_ADMIN_se_puede_suspender_uno_y_despues_el_otro_responde_409` | Secuencia S7 | — | QA |
| 9 | `Un_ADMIN_inhabilitado_no_cuenta_como_otro_ADMIN` | S2 y S8 con la API | M1 | QA |
| 10 | `La_regla_del_ultimo_ADMIN_rige_tambien_en_la_ruta_del_SUPER` | `/api/super/empresas/{c}/miembros/…`: **supuesto de este plan** (P-3) | — | QA |
| 11 | `Suspender_en_una_empresa_inexistente_responde_404_no_409` | Sin fila, C# responde 404 (DAT-D1 4.4) | — | D |

**Concurrencia del invariante MEM-06** (`ConcurrenciaAccesoTests`, **orden de bloqueos**): `Dos_ADMIN_que_se_suspenden_a_la_vez_dejan_al_menos_uno_habilitado` — `a1` y `a2` son los únicos ADMIN; dos hilos con barrera, cada uno suspende al otro: exactamente un 200 y un 409, y al final hay un ADMIN `HABILITADA`. Funciona porque ambas transacciones empiezan por el padrón (`UPDLOCK, HOLDLOCK`) y quedan en serie; si alguna omite el padrón (lo dice el mutante M14), la prueba da dos 200. Ningún 1205.

### 7.2 Q13: `OUTPUT … INTO`, disparadores y consistencia

La premisa de DAT-D1 4.7 es *inferida* (S-8 y RSW-D1 10.3: nadie la ejecutó). Las dos primeras pruebas la **establecen empíricamente** y deben ir primero.

`GuardarPrivilegiosSqlTests` (SQL directo contra una DB-N con ESC; ejecuta `ConsultasAcceso.GuardarPrivilegios` dentro de una transacción `SERIALIZABLE`, como el servicio):

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 12 | `Q13_con_OUTPUT_sin_INTO_da_el_error_334_con_los_disparadores_habilitados` | I | Caracterización: el texto sin `INTO` (constante privada, Anexo B M2) falla con 334 en `UsuariosEmpresas`. Confirma por qué existe el `INTO` | NC. Si **no** falla, la premisa cae y hay que avisar a B | QA |
| 13 | `Q13_con_OUTPUT_INTO_la_variable_de_tabla_funciona_con_los_disparadores_habilitados` | I | El texto real corre sin error y devuelve `VersionNueva = N + 1` (cierra S-8) | NC. Mutante M2 | QA |
| 14 | `Q13_ROWCOUNT_despues_de_un_UPDATE_con_disparadores_AFTER_es_el_de_la_sentencia` | I | Caracterización de la duda de RSW-D1 10.3: `UPDATE` de una fila con `TR_UsuariosEmpresas_Version` y `_SinSuper` y lectura de `@@ROWCOUNT`. No bloquea; deja constancia | NC | QA |
| 15 | `Q13_sube_la_version_en_uno_y_los_disparadores_la_aceptan` | I | Cambio de `Nivel` con `+1` pasa `TR_Version`; con una versión igual (texto sabotado) daría 51619 | NC | QA |
| 16 | `Q13_con_version_vieja_devuelve_NULL_sin_tocar_la_fila_ni_las_hijas` | I | Otra transacción subió la versión de N a N+1 y confirmó; Q13 con `@versionLeida = N` devuelve `VersionNueva` `NULL`, **retorna antes de los `DELETE`/`INSERT`**, y las hijas quedan como las dejó la otra transacción. Es el caso que la guarda de C# sola no cubre (la lectura final daría N+1 = `versionLeida + 1`) | NC. Mutante M3 (sin el retorno anticipado) | D: DAT-D1 la nombra `RestriccionesMembresiaTests.Q13_con_version_vieja_no_toca_las_hijas`; se puede escribir allí con ese nombre |
| 17 | `Q13_sobre_una_membresia_en_BAJA_o_inexistente_devuelve_NULL` | I | El `UPDATE` no la toca (`Estado <> 'BAJA'`); no escribe hijas | NC. Mutante M4 | QA |
| 18 | `Q13_reemplaza_perfiles_y_excepciones_exactamente` | I | Conjuntos finales = los enviados; perfiles repetidos se deduplican; con listas vacías `[]` quedan sin hijas | NC | QA |
| 19 | `Q13_excepciones_con_la_misma_Opcion_dan_2627` | I | PK; el servicio las deduplica antes (MS3) | NC | QA |
| 20 | `Q13_perfil_de_otra_empresa_o_inexistente_da_547_y_no_deja_nada_a_medias` | I | Con `ROLLBACK` del llamador: ni versión ni hijas cambian (la FK compuesta es la segunda barrera) | NC. Mutante M11 | QA |
| 21 | `Q13_restringir_sin_sucursal_da_547` | I | `CK_UsuariosEmpresas_Sucursal` | NC | QA |
| 22 | `Q13_con_un_dato_invalido_en_el_JSON_revierte_todo` (teoría) | I | Excepción sin `n`; opción de 51 caracteres (**no** debe truncarse en silencio, *inferido*: `OPENJSON … nvarchar(50)` puede dar `NULL`); `a` no numérico → error y, por `XACT_ABORT ON`, la transacción queda condenada: versión e hijas intactas | NC | QA |
| 23 | `Q13_no_toca_otras_membresias_de_la_cuenta_ni_de_otros_miembros` | I | Aislamiento: filas de otra empresa, de otra cuenta y las hijas de ambas, sin cambio | NC. Mutante: `WHERE` sin `EmpresaCodigo` | QA |
| 24 | `Q13_actualiza_UsuarioModificacion_y_FechaModificacion` | I | `@actor` `nvarchar(30)` | NC | QA |
| 25 | `Q13_guardar_sin_cambiar_nada_igual_sube_la_version` | I | Caracterización (P-9) | NC | QA |
| 26 | `Q13_con_sello_nulo_conserva_el_sello_y_con_sello_lo_reemplaza` | I | `ISNULL(@selloNuevo, SelloMembresia)` | NC | QA |

`MembresiasServiceTests` (servicio, con la base real):

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 27 | `Q13_version_nueva_distinta_de_la_leida_mas_uno_hace_rollback_y_409` | I | Con un doble que devuelve otra versión: `ROLLBACK` y 409 `VERSION_PRIVILEGIOS` (segunda barrera de RSW-D1 10.3) | NC | D |
| 28 | `Q13_valida_los_perfiles_fuera_de_la_transaccion` | I | Inexistente, inhabilitado o de otra empresa → 400 `PERFIL_NO_VALIDO` **antes** de abrir la transacción | NC | QA |
| 29 | `Q13_deduplica_las_excepciones_por_Opcion_sin_distinguir_mayusculas` | I | `ventas.pos` y `VENTAS.POS` → una | NC | D |
| 30 | `Q13_el_antes_de_la_bitacora_es_el_leido_y_si_algo_cambio_en_medio_da_409_sin_evento` | I | El "antes" es exacto; si la versión cambió, no queda evento | NC | D |
| 31 | `Si_el_evento_PRIVILEGIOS_CAMBIADOS_no_esta_en_el_catalogo_el_cambio_se_revierte_completo` | I | Se borra la fila del catálogo (como administrador); Q13 termina sin confirmar nada | NC | QA |
| 32 | `Q13_toma_el_padron_antes_que_Usuarios_y_UsuariosEmpresas` | I | **Orden de bloqueos.** Otra conexión retiene el padrón (`ConsultasSellos.TomarFilas`); el servicio queda bloqueado; mientras espera **no tiene ningún bloqueo** sobre `Usuarios` ni `UsuariosEmpresas` (`sys.dm_tran_locks` por sesión) | NC. Mutante M14 | QA |

HTTP (`MiembrosHttpTests`) y concurrencia:
- `MiembrosHttpTests.Guardar_con_version_vieja_responde_409_VERSION_PRIVILEGIOS` (D): además, `ValorAnterior` y la versión no cambian.
- `RestriccionesMembresiaTests.E51619_la_version_de_privilegios_no_retrocede` ya está en T1-1 (prueba 30 de la sección 5).
- `ConcurrenciaAccesoTests.Dos_guardados_con_la_misma_version_pasa_exactamente_uno` (D): dos hilos con barrera; uno 200 y otro 409; **la versión final es N+1 (no N+2)**; las hijas finales son exactamente las del ganador; cero 1205/1222.
- `ConcurrenciaAccesoTests.Q3_y_Q13_en_bucle_30_s_sin_1205` y `…Q1_Q6_Q13_en_bucle_30_s_sin_1205` (D, `Medicion=DB7`): los bucles de 30 s no entran en la corrida normal.

### 7.3 Q9, Q10 y el resto

`DominioAdministracionTests` (SQL; ESC con empresas A, B, C; administrador `adm` = ADMIN de A y B):

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 33 | `Q9a_candidatos_matriz` (teoría) | I | Incluye: miembro `HABILITADA` solo de B; con `BAJA` en A (reactivable); cuenta inhabilitada (RSW-D1 8). Excluye: él mismo; `SUPER`; miembro `HABILITADA` o `SUSPENDIDA` de A; miembro solo de C (fuera del dominio); `SUSPENDIDA` solo en B; empresa inhabilitada del dominio; dominio vacío `[]`; mayúsculas distintas en el JSON; sin duplicados (una fila por cuenta) y ordenado por código | NC. Mutante M9 | QA |
| 34 | `Q9a_plan_sin_busqueda_de_marcador` | I | `SET STATISTICS XML ON`: ni `Key Lookup` ni `Table Scan` sobre tablas permanentes | NC | R |
| 35 | `Q9a_el_texto_empieza_por_el_comentario_Q9_a` | U | La medición de T1-8 identifica el lote por ese prefijo (RSW-D1 2) | NC | R |
| 36 | `Q9b_matriz` (teoría) | I | `EnDominio` y `EstadoEnEmpresa` (`NULL`, `BAJA`, `HABILITADA`, `SUSPENDIDA`); código inexistente, él mismo y `SUPER` → 0 | NC | QA |
| 37 | `Q9P_el_dominio_sale_de_las_filas_en_D1` | I | `DominioProvisional` solo trae empresas habilitadas donde `adm` es ADMIN `HABILITADA`. **D3 la invierte** | NC | D |

`DesbloqueoAdminTests` (tipo I; la 41 es U):

| Ord | Método | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|
| 38 | `Matriz_QA21_QA58` (teoría, 11 filas) | `PuedeDesbloquear`: él mismo → 0; `SUPER` → 0; sin membresía en A → 0; solo `BAJA` en A → 0; cuenta inexistente → 0; una membresía fuera del dominio → 0; todas en el dominio → 1; membresía `SUSPENDIDA` en A + otra en el dominio → 1; una `BAJA` fuera del dominio se ignora → 1; empresa de la sesión fuera del dominio → 0 | NC. Mutante M8 | D |
| 39 | `D1_una_fila_de_A_insertada_por_SQL_basta_para_desbloquear` | Documenta R-D1D-08 (D3 la invierte) | NC | D |
| 40 | `Desbloquear_limpia_solo_esa_cuenta` | `BloqueadoHasta` `NULL`, `FallosVentana = 0`, `FallosVentanaInicio` `NULL`, `IntentosFallidos = 0`; otras cuentas igual; `CUENTA_DESBLOQUEADA` con `Categoria CUENTA`, `Empresa` `NULL` y `EmpresaActua = A`; si `PuedeDesbloquear = 0`, no hay `UPDATE` ni evento | NC | QA |
| 41 | `El_punto_de_extension_MembresiasSelladasPermiten_devuelve_true_en_D1` | (U) Fija el único punto que D3 cambia | NC | R |
| 42 | `Desbloquear_sigue_el_orden_padron_Usuarios_UsuariosEmpresas` | **Orden de bloqueos**, igual que la prueba 32 de 7.2 | NC | QA |

`MiembrosHttpTests` (resto), todas **IH**, `ApiMvpFactory` con su base propia:

| Ord | Método | Afirma | Origen |
|---|---|---|---|
| 43 | `El_ADMIN_de_A_lista_solo_miembros_de_A` | Q3, QA-17: ninguna fila de B; sin `SUPER`; con los tres indicadores permitidos y nada más | P |
| 44 | `Un_ADMIN_de_A_no_ve_modifica_ni_da_de_baja_miembros_de_B` | 404 idéntico al de "no existe" | QA |
| 45 | `Alta_con_codigo_ocupado_responde_409_CODIGO_NO_DISPONIBLE` | — | P |
| 46 | `Vincular_fuera_del_dominio_y_codigo_inexistente_dan_el_mismo_404` | QA-19: cuerpo, código y encabezados idénticos | P y D |
| 47 | `Candidatos_incluye_cuentas_inhabilitadas_del_dominio` | RSW-D1 8 | R |
| 48 | `Vincular_una_cuenta_inhabilitada_no_consume_cupo` | RSW-D1 8 (depende de `CupoEmpresasProvisional`) | R |
| 49 | `Baja_borra_perfiles_y_excepciones_y_sube_la_version` | — | P |
| 50 | `Reactivar_una_BAJA_reutiliza_la_fila_con_una_version_mayor_y_conserva_el_origen` | — | QA |
| 51 | `La_vigesimoprimera_alta_en_una_hora_responde_429` | ADM-13 | P |
| 52 | `Sin_cupo_el_409_sale_despues_de_autorizacion_y_ambito` | QA-94: sin permiso → 403; fuera de ámbito → 404; solo entonces 409 | P |
| 53 | `Guardar_privilegios_sobre_una_membresia_en_BAJA_responde_lo_que_decida_B` | **Condicional a P-2** | QA |

`SuperCuentasHttpTests`:
- (**IH**) `Habilitar_una_cuenta_verifica_el_cupo_en_cada_empresa_sin_cambios_parciales` (P): con una empresa sin cupo, 409 y **ninguna** membresía ni la cuenta cambia.
- `Restablecer_la_clave_exige_autenticacion_reciente` (P).
- `Un_ADMIN_no_puede_usar_las_rutas_del_SUPER` (QA): 403.
- `El_SUPER_ve_los_miembros_de_cualquier_empresa_con_su_ruta` (QA).

`ResolverSucursalTests` (clase existente, `SucursalesAccesoTests.cs`, Neutral; se agrega la que RSW-D1 asigna a un `UsuariosServiceTests` inexistente): `Restringida_sin_sucursal_predeterminada_rechaza_con_y_sin_sucursales_habilitadas` — **guardia G** (tipo U) de la premisa de RSW-D1 3: pasa hoy; si alguien cambia `ResolverSucursal`, avisa (H-11). Es la prueba 13 de T1-4 y se cuenta allí.

**Total T1-3: 65 pruebas nuevas.** 7.1: 15 (0a, 0b, 0c, las 11 HTTP y la concurrencia de MEM-06). 7.2: 25 (15 de SQL, 6 de servicio, 1 HTTP y 3 de concurrencia). 7.3: 25 (5 de Q9, 5 de Q10, 11 de `MiembrosHttpTests`, 4 de `SuperCuentasHttpTests`). Una teoría cuenta una vez.

---

## 8. T1-4 · Verbo `GPOS.Migracion accesos --convertir` (sin sellar)

Depende de T1-2. Datos: DB-N con **tablas globales pobladas** (ESC-DEMO del Anexo D: 3 empresas, 8 cuentas, 4 perfiles, excepciones con `rpt:{id}`, 3 reportes personalizados, una cuenta restringida con sucursal, una restringida sin sucursal, una cuenta inhabilitada) y una o dos bases de empresa con `NotificacionesReglas`. Filtro: `FullyQualifiedName~ConversionAccesosTests`. Todos los métodos son de `ConversionAccesosTests`, salvo la prueba 1 (arquitectura) y la 13 (clase existente).

**Independencia (DAT-D1 4.9):** Q23 expresa la regla en SQL; el paso 3 debe construirse por otro camino (C# sobre entidades). Sin la prueba 1 de esta tabla, Q23 solo detectaría errores de copia, no de regla.

| Ord | Método | Tipo | Afirma | Rojo hoy / mutante | Origen |
|---|---|---|---|---|---|
| 1 | `AccesoArquitecturaTests.El_paso_3_no_comparte_el_SQL_de_Q23` | A | El código de `GPOS.Migracion/Accesos` que crea membresías no referencia `ConsultasAcceso.EquivalenciaConversion` ni su texto | NC. Mutante: paso 3 que ejecuta un `INSERT … SELECT` con la misma regla | QA |
| 2 | `Q23_sin_diferencias_en_el_DEMO` (teoría `D` y `M`) | I | El verbo termina y Q23 da cero en E1 a E6 y E8a a E8c, en los dos modos | NC | P y D |
| 3 | `Q23_detecta_cada_tipo_de_diferencia` (teoría) | I | Estado correcto + **un** cambio por vez: membresía de más (E1), nivel distinto (E1), perfil copiado con otra descripción (E3), permiso de perfil que falta (E4), asignación que falta (E5), excepción con `Nivel` `NULL` (E6, "falla cerrado"), reporte con `EmpresaCodigo` incoherente (E8a), copia faltante (E8b), copia distinta del original (E8c) → cada uno da su `Chequeo` > 0 y 51621. Sin esta, Q23 podría ser vacuo | NC | QA |
| 4 | `Una_diferencia_revierte_todo_con_51621` | I | Con el gancho de pruebas entre los pasos 3 y 4 (P-8): el verbo termina con 51621 y `CHECKSUM_AGG` de cada tabla (globales y nuevas) es igual al de antes | NC | D |
| 5 | `Un_fallo_en_cada_paso_deja_la_base_igual` (teoría: pasos 2, 3, 3 b, 5, **8** y 9) | I | La conversión es una sola transacción `SERIALIZABLE` con `XACT_ABORT ON`: un fallo inyectado en cada paso revierte todo, **también los `DROP` y `ALTER` del paso 8** (el DDL de SQL Server es transaccional) | NC | QA |
| 6 | `Una_segunda_ejecucion_informa_ya_convertido_y_no_cambia_nada` | I | Precondición 1: código 0, sin cambios | NC | P |
| 7 | `Con_la_API_en_marcha_se_detiene_con_51622` | I | Doble de `IEstadoServicios`; también con `GPOS.Reportes` en marcha; nada cambia | NC | P |
| 8 | `Las_demas_precondiciones_se_detienen_con_51622_y_no_cambian_nada` (teoría: 3, 4, 6, 7) | I | Anillo que no verifica; `FilaAusente` en el padrón v1; marca < 6; respaldo viejo | NC | QA |
| 9 | `Modo_minimo_crea_una_sola_membresia_USER_sin_ADMIN` | I | Sin `--instalacion-demo`: una membresía `USER` en `EmpresaDefault`; ninguna `ADMIN` (salvo `AdministradaPorSuper = 1`); perfiles y excepciones solo ahí; lista de pendientes | NC | P |
| 10 | `Restringida_recibe_membresia_solo_en_EmpresaDefault` | I | Modo DEMO con restricción: solo su empresa, con restricción y sucursal | NC | P |
| 11 | `Una_cuenta_restringida_sin_sucursal_queda_sin_membresia_y_en_pendientes` (teoría `D` y `M`) | I | RSW-D1 3: sin membresía, motivo `RESTRINGIDA_SIN_SUCURSAL`, el verbo **no** se detiene; `Pendientes` la cuenta (solo el número) | NC | D y R |
| 12 | `La_vista_previa_informa_las_cuentas_restringidas_sin_sucursal` | I | El número aparece antes de confirmar | NC | D y R |
| 13 | `ResolverSucursalTests.Restringida_sin_sucursal_predeterminada_rechaza_con_y_sin_sucursales_habilitadas` | U | **Guardia G** de la premisa de RSW-D1 3, en la clase existente de `SucursalesAccesoTests.cs`: una cuenta restringida con `SucursalDefault = null` lanza `ReglaNegocioException` con `[]` y con `Dos` sucursales habilitadas (`UsuariosService.cs:766-768`) | G: pasa hoy | R |
| 14 | `Con_exceso_de_cupo_se_detiene_y_lista_las_empresas` | I | 51622 con la lista; se revierte | NC | P |
| 15 | `Aceptar_exceso_exige_motivo` | I | `--aceptar-exceso` sin `--motivo-exceso` o con menos de 10 caracteres | NC | P |
| 16 | `Los_reportes_personalizados_se_copian_por_empresa_y_rpt_id_se_reasigna` | I | Original en la primera empresa por `Prioridad, Codigo`; copia en cada otra; `ConversionReportes`; `rpt:{id}` y `Detalle = "id:{original}"` reasignados | NC | P |
| 17 | `Modo_minimo_copia_los_reportes_personalizados_a_cada_empresa_habilitada` | I | El paso 3 b es el mismo en los dos modos (RSW-D1 7) | NC | D y R |
| 18 | `Modo_minimo_reasigna_las_reglas_de_notificacion_de_cada_empresa` | I | Paso 11 | NC | D y R |
| 19 | `El_paso_11_manda_ReporteId_como_int_y_no_tiene_transaccion_abierta_ni_bloqueos_en_GPOS_SYSDATA` | I | **Orden de bloqueos / ADR-50.** Con `ComandosSql` sobre la base de empresa: el `UPDATE` lleva parámetros `int` y ninguno de texto; con el gancho, mientras corre, la sesión del verbo no retiene bloqueos en `GPOS_SYSDATA` (la transacción ya confirmó) | NC | QA |
| 20 | `Si_una_base_de_empresa_no_responde_el_verbo_sale_con_codigo_distinto_de_0_y_nombra_las_pendientes` | I | Resiliencia: una empresa con cadena inválida; las demás se actualizan; `ReglasActualizadasUtc` queda `NULL` solo en la pendiente | NC | QA |
| 21 | `Solo_reglas_completa_las_pendientes_y_es_idempotente` | I | `--solo-reglas` repetido no cambia nada; una regla ya reasignada no se vuelve a tocar | NC | QA |
| 22 | `El_SUPER_no_recibe_membresias_ni_perfiles` | I | — | NC | QA |
| 23 | `Una_cuenta_inhabilitada_recibe_sus_membresias_y_sigue_inhabilitada` | I | Q23 E1 las espera `HABILITADA` | NC | QA |
| 24 | `Las_empresas_inhabilitadas_no_reciben_membresias_perfiles_ni_copias` | I | `@emp` de Q23 | NC | QA |
| 25 | `Los_perfiles_inhabilitados_se_copian_inhabilitados` | I | E3 incluye `Inhabilitado` | NC | QA |
| 26 | `Los_permisos_efectivos_son_iguales_antes_y_despues_E7` | I | Para cada membresía: `Permisos.Combinar` del modelo anterior (con el cambio de `rpt:{id}`) = `PermisosService.EfectivosAsync(cuenta, empresa)`; incluye `Detalle = "id:…"` (E7-bis) | NC | D |
| 27 | `Los_pasos_unicos_de_PermisosService_no_se_repiten_en_una_segunda_ejecucion` | I | R-D1-08 / E-SW-7: `MigrarModeloAnterior`, `MigrarReportesPorArea` y `AgregarPermisos*` según sus marcas; la segunda corrida no duplica | NC | P |
| 28 | `Los_ADMIN_convertidos_quedan_con_debe_cambiar_la_clave` | I | P-D0-04 (b), paso 8 d | NC | P |
| 29 | `Registra_ACCESOS_CONVERTIDOS_por_empresa_y_el_global_con_retencion_de_5_anios` | I | `MEMBRESIA` con `Empresa` y sin nombrar otras; el global en `SISTEMA` con excepción de 5; `ValorNuevo` JSON válido; la marca `Accesos.Modelo` se escribe al final | NC | QA |
| 30 | `Sistema_dos_veces_despues_de_convertir_no_resucita_las_tablas_globales` | I | R-2 de DAT-D0. **`Skip` con motivo "se activa con T1-5"** (convención del proyecto: `Fact(Skip = "…")`) | NC | P |

**Total T1-4:** 30 pruebas (la 13 es la guardia de 7.3, contada una sola vez).

---

## 9. Orden recomendado y cómo correrlo

El orden es el de la columna **Ord** de cada tabla (de lo más barato a lo más caro). Por PR:

| Paso | Qué | Clases a correr (filtro `FullyQualifiedName~<Clase>`) | Está en verde cuando |
|---|---|---|---|
| T1-1 / a | Fase 1 (sin base) y fase 2 (adaptadas, en rojo) | `EventosSeguridadTests`, `CatalogoEventosTests` (las U), `AccesoArquitecturaTests`, `EventIdUnicosTests`, `SqlSoloEnLugaresPermitidosTests`, `BitacoraSeguridadTests` | Segundos; sin base |
| T1-1 / b | Fases 3 a 5 (esquema, restricciones, catálogo) | `EsquemaAccesoTests`, `RestriccionesMembresiaTests`, `CatalogoEventosTests` | Existen `AccesoDdl`, `HasTrigger` y la lista con categorías |
| T1-1 / c | Fase 6 (purga) y PF25, PF43, S-05, PF30, PF_J2_14 | `PurgaBitacoraTests`, `BitacoraSeguridadTests`, `EsquemaSegundoFactorTests`, `EsquemaRecuperacionFactorTests`, `CambioRncHttpTests` | El disparador y el procedimiento de purga nuevos están editados en su sitio |
| T1-1 / d | Fases 7 y 8 (privilegios, reverso) | `PrivilegiosSistemaTests`, `EsquemaAccesoTests` (reverso) | Existen `AccesoPermisos` y el archivo de reverso |
| T1-1 / cierre | Regresión de la sección 4.4 | las clases de esa lista | Antes de abrir el PR. **La suite completa la corre B, sola** |
| T1-2 | 6.1 y 6.2 | clases de T1-2 | T1-1 unido |
| T1-3 / a | **Q3-P y Q13 primero** (7.1 y 7.2), antes que los endpoints | `DominioAdministracionTests`, `GuardarPrivilegiosSqlTests` | Las pruebas 12 a 14 de 7.2 y la 0a de 7.1 se ejecutan **antes** de escribir las constantes |
| T1-3 / b | Servicio, Q9, Q10 y HTTP | `MembresiasServiceTests`, `DesbloqueoAdminTests`, `MiembrosHttpTests`, `SuperCuentasHttpTests` | T1-2 unido |
| T1-3 / c | Concurrencia | `ConcurrenciaAccesoTests` (los bucles de 30 s llevan `Medicion=DB7` y los corre B) | — |
| T1-4 | Sección 8, en paralelo con T1-3 una vez unido T1-2 | `ConversionAccesosTests` | La 30 queda con `Skip` hasta T1-5 |

Ejemplos de comandos (el desarrollador ajusta la ruta):

```
dotnet test tests/GPOS.Tests --filter "FullyQualifiedName~EsquemaAccesoTests"
dotnet test tests/GPOS.Tests --filter "FullyQualifiedName~PurgaBitacoraTests|FullyQualifiedName~BitacoraSeguridadTests"
dotnet test tests/GPOS.Tests --filter "Categoria=Acceso&Medicion!=DB7"
```

Reglas de ejecución: sin dos suites a la vez; los bucles de 30 s y los tiempos (`MedicionQ*`) son de **T1-8** y de B, no de este plan; `GPOST_TEST_SERVER=.` si la instancia es la predeterminada.

---

## 10. Cobertura, trazabilidad y conteo

**Política aplicada** (la del QA por omisión, porque `CLAUDE.md` no fija otra): 70 % de líneas en el código modificado de los módulos críticos (seguridad y aislamiento). Medición con `dotnet test --collect:"XPlat Code Coverage"` (`coverlet.collector 6.0.4` ya está en `GPOS.Tests.csproj`) sobre las clases de las secciones 5 a 8, **corrida por B** (no en la PC de C). Objetivos: `GPOS.Core/Sistema/Acceso/*`, `MembresiasService`, `DominioAdministracion`, `GPOS.Migracion/Accesos/*`, `GPOS.Contracts/Seguridad/EventosSeguridad.cs`.

Las constantes SQL (`EsquemaAcceso.cs`, `ConsultasAcceso.cs`) no miden cobertura de líneas. Para ellas la medida es la **cobertura de ramas SQL**, que este plan cierra así:

| Rama SQL | Prueba que la ejecuta |
|---|---|
| 51619 (PK, retroceso, igual versión ×4 campos, origen/alta, reutilizar `BAJA`) | T1-1: 30 a 33 |
| 51620 | T1-1: 38 |
| 51623 (×5 vías) | T1-1: 39 y 40 |
| 51624 (insert, update de `Estado`, varias filas) | T1-1: 41 |
| 51625 | T1-1: 42 |
| 51626 (con y sin historia) | T1-1: 50 |
| 52002 del disparador de purga (retención de categoría) | T1-1: 63 |
| 51614 y los cuatro `DENY` | T1-1: 66, 67, 71 |
| Q3-P: S1 a S12 | T1-3: 7.1 (0b) |
| Q13: retorno anticipado, `OUTPUT INTO`, hijas, FK, `CHECK`, `XACT_ABORT` | T1-3: 12 a 26 de 7.2 |
| Q9-a, Q9-b, Q10 | T1-3: 7.3 (33, 36, 38) |
| Q23: E1 a E8c | T1-4 prueba 3 |

**Trazabilidad criterio → prueba** (resumen; los criterios de aceptación son los de PLAN-D1 4 y las "Qué" de cada tarea):

| Criterio | Pruebas |
|---|---|
| T1-1: tercer lote, versión 6, tablas, disparadores 51619 a 51625, catálogo con FK, `DENY` | 1 a 3, 13 a 29, 30 a 47, 48 a 56, 66 a 73 (sección 5) |
| T1-1: idempotencia (ADR-07), v5 → v6, reverso | 14, 15, 17, 18, 74 a 76 (más PF30 y PF_J2_14 sin cambiar el cuerpo) |
| T1-1: purga por categoría confirmada (RSW-D1 6) | 57 a 65 y PF25/PF43 adaptadas |
| T1-1: `HasTrigger` (R-D1D-01) | 28, 29 |
| T1-2: Q1 en un viaje y 12 lecturas, `BitacoraAcceso`, cupo provisional, siembra | 6.1 y 6.2 |
| T1-3: Q3-P corregida (R-D1D-12), Q13 (R-D1D-13), Q9, Q10, QA-17, QA-19, QA-21/58, ADM-13, QA-94 | 7.1 a 7.3 |
| T1-4: Q23, precondiciones, modos, reportes, reglas, atomicidad | 8 |

**Conteo de pruebas nuevas** (una teoría cuenta una vez): T1-1 **76**, T1-2 **34**, T1-3 **65**, T1-4 **30**; total **205**. Más los 13 cambios en pruebas existentes de la sección 4. El conteo exacto lo cierra el desarrollador al escribirlas; lo que importa es que cada fila de este plan tenga su método.

---

## 11. Riesgos no cubiertos por estas pruebas

1. **Binario v5 sobre base v6** (R-D1D-11): una API anterior reescribe el disparador de purga viejo en cada arranque (`CREATE OR ALTER` gana) y falla al guardar `Usuarios` por EF. No se puede probar con el binario actual; lo cubre el procedimiento de devops y la prueba 76.
2. **Carrera 51624/51625 por SQL directo** (R-D1D-07): dos transacciones en `READ COMMITTED` que se cruzan. Fuera de la API no hay prueba posible sin dos sesiones coordinadas; queda como riesgo aceptado del diseño.
3. **Rendimiento** (`MedicionQ*`, p95, 30 s): es T1-8 y de B. Este plan solo cubre lo determinista (lecturas lógicas y forma del plan).
4. **Colación de la instancia distinta de CI**: todo el plan corre en la instancia de pruebas (`SQL_Latin1_General_CP1_CI_AS`, *inferido*). Con una colación sensible a mayúsculas, los `JOIN` por código y los literales cambiarían de comportamiento.
5. **Express vs Standard**: `ALTER TABLE … ADD … NOT NULL DEFAULT` reescribe la tabla en esas ediciones; con cientos de filas no importa, pero no se mide.
6. **No hay ruta que borre cuentas ni empresas** (`git grep` de `Remove`, `ExecuteDelete` y `EliminarAsync` en `UsuariosService`, `EmpresasService` y `Endpoints`: sin resultados para cuentas o empresas). La traducción de 547 a "inhabilite en lugar de eliminar" (R-D1D-06) **no tiene dónde ejecutarse** y no se prueba; la FK se prueba a nivel SQL (prueba 44).
7. **Pantalla de bitácora del SUPER**: el filtro ofrece `EventosSeguridad.Todos` (`BitacoraSeguridad.razor:105`; `VistaEventosSeguridad.cs:56`) y los 33 eventos nuevos no tienen nombre legible; `SegundoFactorSuperPantallasTests.cs:231` solo revisa los primeros 25, así que no lo notaría. Es de la Web, fuera de T1-1 a T1-4; se anota para quien la toque.
8. **`GPOS.Reportes`** no se prueba aquí: D7-A no cambia las vistas `rptsis` v1; `LecturaReportesSistemaTests` es la regresión y la prueba 73 cubre el aislamiento por permisos.
9. **PC de C inestable**: este plan no corrió nada; las pruebas de concurrencia reales las corre B o quien construya.

---

## 12. Preguntas abiertas para B

Solo ambigüedades reales del diseño. Cada una dice qué prueba queda detenida y cuál es la respuesta que este plan supone.

| # | Pregunta | Detiene | Supuesto de este plan |
|---|---|---|---|
| P-1 | ¿Dónde vive el **reverso de D7-A**? DAT-D1 7.4 lo da como texto de documento; el precedente (`reverso-h11-s2.sql`) es un archivo leído por la prueba. | 74 a 76 | `database/sistema/reverso-db7-d1.sql` |
| P-2 | ¿Qué responde **guardar privilegios sobre una membresía en `BAJA`** (o inexistente)? El SQL devuelve `VersionNueva` `NULL`, igual que una versión vieja, y se vería como 409 `VERSION_PRIVILEGIOS`, engañoso. | 17 de 7.2 y 53 de 7.3 | 404 o 422 específico decidido en el paso 1 del servicio (lectura previa), antes de la transacción |
| P-3 | ¿La regla **`ULTIMO_ADMIN`** rige también en la ruta del SUPER (`/api/super/empresas/{c}/miembros/…`)? DAT-D1 dice "y la ruta del SUPER" para Q13 y Q3, pero BP3 define MEM-06 solo como «Último ADMIN, o empresa administrada por el SUPER» (línea 174) y no dice por qué ruta rige. | prueba 10 de 7.1 | Sí, en las dos rutas y en las tres transiciones (suspender, baja, degradar) |
| P-4 | ¿La **comprobación del catálogo al arrancar** (EventId 4733, DAT-D0 5.6) entra en T1-1? PLAN-D1 4 no la lista. | 56 de la fase 5 | Sí, en T1-1, solo en Release |
| P-5 | ¿Dónde vive el **reintento único ante 1205** de Q1: `EstadoAccesoService` (T1-2) o `ValidacionAcceso` (T1-5)? Y la siembra por empresa, ¿toma el padrón primero? | 16 y 26 de 6 | Reintento en el servicio de T1-2; la siembra toma el padrón |
| P-6 | Los `CHECK` de `Nivel`, `Estado`, `Origen` y `ActorNivel` usan la intercalación de la instancia (CI): `'admin'` pasa. ¿Se exige `COLLATE Latin1_General_BIN2` como en el nombre del evento? | 47 | No (se documenta el comportamiento actual). Si sí, la 47 se invierte |
| P-7 | La tabla 5.1 omite `FACTOR_RESTABLECIDO_SUPER` y `FACTOR_RESTABLECIDO_CONSOLA` (cuenta 9 `FACTOR_*` cuando son 11) y habla de "unos 110" eventos cuando enumera 81 (48 + 33). ¿Faltan eventos de D2 a D5 por enumerar? ¿Cuál es el punto de entrada del **generador** del bloque 4 b? | 8 y 9 de la fase 1 | Los dos `RESTABLECIDO` van en `FACTOR`; no hay más eventos que los 81; el generador es un método `internal static` que recibe la lista |
| P-8 | El verbo necesita un **gancho de pruebas** (51621 entre los pasos 3 y 4, y fallos inyectados en los pasos 2 a 9 y 11). ¿Qué mecanismo: una interfaz inyectable o un delegado opcional? No debe ser un indicador de producción. | 4, 5, 19 de T1-4 | Un delegado opcional que solo existe en el constructor `internal` |
| P-9 | ¿**Guardar sin cambiar nada** sube la versión? El texto de Q13 la sube siempre (invalida cachés de la membresía). | 25 de 7.2 | Sí, es intencional |

---

## Anexo A · Matriz de tipos de las columnas nuevas (prueba 21)

Formato `tabla.columna: tipo(largo) nulabilidad`. Fuente: DAT-D1 7.1.

- `Empresas.AdministradaPorSuper: bit NOT NULL`
- `Usuarios.SesionEmpresa: nvarchar(30) NULL`; `FallosVentana: int NOT NULL`; `FallosVentanaInicio: datetime2(3) NULL`
- `UsuariosEmpresas`: `UsuarioCodigo nvarchar(30) NOT NULL`; `EmpresaCodigo nvarchar(30) NOT NULL`; `Nivel varchar(5) NOT NULL`; `SucursalDefault nvarchar(30) NULL`; `RestringirSucursal bit NOT NULL`; `Estado varchar(10) NOT NULL`; `FechaEstado datetime2(0) NULL`; `CuentaEstado nvarchar(30) NULL`; `MotivoEstado nvarchar(200) NULL`; `VersionPrivilegios int NOT NULL`; `SesionesRevocadas datetime2(3) NULL`; `UltimoAcceso datetime2(0) NULL`; `Origen varchar(10) NOT NULL`; `FechaAlta datetime2(0) NOT NULL`; `UsuarioAlta nvarchar(30) NOT NULL`; `FechaModificacion datetime2(0) NULL`; `UsuarioModificacion nvarchar(30) NULL`; `SelloMembresia varbinary(512) NULL`
- `EmpresasPerfiles`: `EmpresaCodigo nvarchar(30)`, `Codigo nvarchar(30)`, `Descripcion nvarchar(100)`, `Inhabilitado bit` (todas `NOT NULL`)
- `EmpresasPerfilesPermisos`: `EmpresaCodigo nvarchar(30)`, `PerfilCodigo nvarchar(30)`, `Opcion nvarchar(50)`, `Nivel int`, `Acciones int` (todas `NOT NULL`)
- `UsuariosEmpresasPerfiles`: `UsuarioCodigo`, `EmpresaCodigo`, `PerfilCodigo`: `nvarchar(30) NOT NULL`
- `UsuariosEmpresasPermisos`: `UsuarioCodigo`, `EmpresaCodigo nvarchar(30)`, `Opcion nvarchar(50)`, `Nivel int`, `Acciones int` (todas `NOT NULL`)
- `CategoriasSeguridad`: `Categoria varchar(12) NOT NULL`; `RetencionAnios tinyint NOT NULL`; `VisibleAdmin bit NOT NULL`
- `CatalogoEventosSeguridad`: `Evento varchar(40) NOT NULL`; `Categoria varchar(12) NOT NULL`; `RetencionAnios tinyint NULL`
- `BitacoraSeguridad` (nuevas): `EmpresaActua nvarchar(30) NULL`; `ActorNivel varchar(7) NULL`; `Categoria varchar(12) NULL`; `ValorAnterior nvarchar(2000) NULL`; `ValorNuevo nvarchar(2000) NULL`. Ya existente: `Actor nvarchar(128)`, `Evento varchar(40)`, `Detalle nvarchar(400)`
- `Reportes.EmpresaCodigo: nvarchar(30) NULL`
- `ConversionReportes`: `EmpresaCodigo nvarchar(30)`, `IdOriginal int`, `IdNuevo int` (`NOT NULL`); `ReglasActualizadasUtc datetime2(0) NULL`

## Anexo B · Mutantes (cada prueba de riesgo debe ponerse en rojo con el suyo)

| M | Sabotaje | Lo debe romper |
|---|---|---|
| M1 | `OtrosAdminProvisional` con el texto de la revisión 1 (Anexo C) | T1-3, 7.1: las filas S1 a S6 y S10 de 0b y las pruebas 1 a 4, 9 |
| M2 | Q13 con `OUTPUT inserted.VersionPrivilegios` sin `INTO` | 13 de 7.2 (y 12 lo demuestra) |
| M3 | Q13 sin el retorno anticipado (sigue con los `DELETE`/`INSERT` aunque `@v` esté vacía; solo queda la guarda de C#) | 16 de 7.2, dos guardados simultáneos |
| M4 | Q13 sin `AND ue.Estado <> 'BAJA'` | 17 de 7.2 |
| M5 | D7-A sin `HasTrigger` en `Usuario` | 28 y 29 |
| M6 | Disparador y procedimiento de purga con los 2 años fijos | 57, 59, 61, 62, 63 |
| M7 | Q3 en un paso (índice no agrupado + búsqueda de marcador) | plan de Q3 y bucle de 30 s |
| M8 | Q10 sin `@empresa ∈ @dominio` | `Matriz_QA21_QA58` |
| M9 | Q9 con `m.Estado <> 'BAJA'` en vez de `= 'HABILITADA'` | `Q9a_candidatos_matriz` |
| M10 | `TR_UsuariosEmpresas_Version` sin la rama de igual versión con cambio de estado, nivel, restricción o sucursal | T1-1: 31 y 32 |
| M11 | FK simple `(PerfilCodigo)` en vez de la compuesta | 43 y 45 |
| M12 | `MERGE` del catálogo que actualiza `Categoria` | 50 |
| M13 | Verbo sin transacción global | T1-4 prueba 5 |
| M14 | `MembresiasService` que no toma el padrón primero | 32 de 7.2 y `Dos_ADMIN_que_se_suspenden_a_la_vez…` |

## Anexo C · Texto de Q3-P de la revisión 1 (constante privada de la prueba 0a de 7.1)

De `git show ffee214f:docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` (líneas 266-272):

```sql
SELECT COUNT(*) AS OtrosAdmin, MAX(CONVERT(int, e.AdministradaPorSuper)) AS AdministradaPorSuper
  FROM dbo.Empresas e
  LEFT JOIN dbo.UsuariosEmpresas ue ON ue.EmpresaCodigo = e.Codigo AND ue.Estado = 'HABILITADA' AND ue.Nivel = 'ADMIN'
                                   AND ue.UsuarioCodigo <> @usuario
  LEFT JOIN dbo.Usuarios u ON u.Codigo = ue.UsuarioCodigo AND u.Inhabilitado = 0 AND u.Nivel <> N'SUPER'
 WHERE e.Codigo = @empresa AND (ue.UsuarioCodigo IS NULL OR u.Codigo IS NOT NULL);
```

Comportamiento (verificado por lectura): sin otros ADMIN el `LEFT JOIN` produce una fila con `ue` en `NULL`, el `WHERE` la conserva y `COUNT(*)` da **1**; con todos inhabilitados el `WHERE` descarta todo y, al ser un agregado sin `GROUP BY`, devuelve una fila con `COUNT = 0` y `MAX = NULL`. Con la marca `AdministradaPorSuper` el caso 1 sigue dando 1, por eso `Con_AdministradaPorSuper_no_hay_409` pasa en vacío (H-3).

## Anexo D · Escenarios de datos

- **ESC-Q3P:** ver 7.1.
- **ESC-SQL (T1-1):** empresas `A`, `B`; cuentas `u1` (USER), `a1` (ADMIN), `s1` (SUPER); perfiles `P1` en A y `P2` solo en B; membresías creadas por `INSERT` directo con `UsuarioAlta` y `Origen = 'MANUAL'`.
- **ESC-A/B/C (T1-3):** empresas `A`, `B`, `C`; `adm` = ADMIN de A y B; `cA` en A; `cAB` en A y B; `cB` en B; `cC` en C; `sup` = SUPER; `inh` con la cuenta inhabilitada en B.
- **ESC-DEMO (T1-4):** 3 empresas (una inhabilitada), 8 cuentas (2 ADMIN, 1 SUPER, 1 inhabilitada, 1 restringida con sucursal, 1 restringida sin sucursal), 4 perfiles (uno inhabilitado), excepciones con `rpt:{id}` de 3 reportes personalizados, una regla en `NotificacionesReglas` por empresa.
- **DEMO-50:** 50 cuentas × 5 empresas (T1-2, pruebas 14 y 15). **DEMO-1000:** solo T1-8.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-plan-pruebas-db7-d1.md`
- Supuestos: (1) las dos premisas de SQL Server (error 334 solo por acción de disparador y `OUTPUT … INTO` permitido con disparadores) son *inferidas* de la documentación y nadie las ejecutó; las pruebas 12 a 14 de 7.2 las establecen; (2) la API de EF para leer los disparadores del modelo (`ITable.Triggers`) es *inferida*; (3) la instancia de pruebas tiene la colación CI de las instalaciones; (4) el reverso vivirá en `database/sistema/reverso-db7-d1.sql` (P-1); (5) los bucles de 30 s y los tiempos son de T1-8 y de B; (6) nada se compiló ni se ejecutó.
- Decisiones candidatas a ADR: Ninguna.
- Entregas a otros agentes: B → contestar P-1 a P-9 antes del 2026-11-02 (P-2, P-3 y P-8 cambian pruebas de riesgo); arquitecto-datos → corregir la tabla 5.1 de DAT-D1 (`FACTOR_RESTABLECIDO_*`, "unos 110"); desarrollador-backend (T1-1 a T1-4) → usar este plan, empezando por las secciones 3 y 4; documentador → H-1 y H-2 como adición a la lista de pruebas a adaptar de DAT-D1 7.5.
- Próximo paso recomendado: que B responda las nueve preguntas y que el desarrollador de T1-1 empiece por la sección 4 (adaptaciones en rojo) y las pruebas 12 a 14 de 7.2 (premisas de SQL Server).
