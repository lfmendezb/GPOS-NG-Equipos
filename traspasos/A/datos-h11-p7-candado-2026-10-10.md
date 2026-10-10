# [Blueprint de Datos] H-11, segunda parte: migración `H11CandadoChequeras` y objetos de `GPOS_SYSDATA` (marca P-7, respaldo posterior y candado del sistema)

- **Autor:** arquitecto-datos, equipo A · **Fecha:** 2026-10-10
- **Árbol leído:** `GPOS-NG-h11b`, rama `a/h11-p7-candado` (`e7f1f96`). No cambié el árbol. Leí con `git show` `origin/c/adr81-fase-a-diseno` (blueprint v2 de la fase A, en adelante **[C81]**, y su revisión de datos `docs/datos/2026-10-10-revision-adr81-fase-a-datos.md`, **[C81-D]**) y busqué los números de error en las 68 referencias locales y remotas.
- **Entradas:** `blueprint-h11-p7-candado-2026-10-10.md` (**[SW]**, §10) y mi diseño de la primera parte, `datos-h11-desbloqueo-restauracion-2026-10-10.md` (**[D11]**).
- **Marcas:** **[V]** verificado hoy, con su cita `ruta:línea` desde la raíz del árbol · **[I]** inferido, sin medir · **PDS-nn** prueba de datos obligatoria (§11).
- **Estado:** listo para el desarrollador-backend. Hay **6 preguntas** (§13); ninguna bloquea, y cada una trae su opción por omisión.

---

## 0. Resumen y cambios respecto de [SW]

| # | Decisión de datos | Diferencia con [SW] |
|---|---|---|
| DD-7 | **El error del candado es 51403, no 51391.** 51387 a 51393 están **reservados por ADR-78** (firmado) para la tanda 3 de equivalencias (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla4FactorUnidad.cs:18`; `origin/master:docs/adr/ADR-078.md:33`) [V]. 51403 no aparece en ninguna de las 68 referencias ni en el área común [V]. **No se reserva un segundo número:** C9 usa 51329 con la regla «C9», como C0 a C8 | [SW] §1.1 y §10.1 daban 51391 y 51392 como libres: la búsqueda solo miró `Migraciones/*.cs` |
| DD-8 | **Disparador aparte, `doc.TR_Documento_Candado`, `AFTER INSERT, UPDATE, DELETE`.** No se funde con `TR_Documento_Nace` ni con `TR_Documento_Inmutable` | [SW] dejaba la fusión a mi criterio. Esos dos no leen el estado del sitio, así que fundirlos no ahorra la lectura; solo ahorra el despacho del disparador, a cambio de reescribir dos textos vivos y su `Down` |
| DD-9 | **Condición del candado = la de [SW] §4.1:** fork nulo o distinto, **o** `EmisionBloqueada = 1` **con** `MotivoBloqueo = 'RESTAURACION'`. Un bloqueo `MANUAL` no bloquea borradores | [SW] §10.1 decía «`EmisionBloqueada = 1`» a secas (la condición de 51330). Eso contradice su §4.1 y rompería los borradores con un bloqueo de otra causa |
| DD-10 | **El disparador no vuelve a leer el sitio en la emisión (0 → 1):** 51330 ya la vigila con una condición más amplia | Ahorra unos 19 µs por venta (la lectura medida en H0, 6.1, citada en [D11] §8.1) y conserva el código 51330 que esperan las pruebas actuales |
| DD-11 | **También `DELETE`:** borrar un borrador es una escritura de negocio | [SW] decía `INSERT, UPDATE` |
| DD-12 | **C9** valida el **contenido** de cada fila de `ReconciliacionChequera` contra `banco.Chequera` y `banco.DocBanco`, no solo la completitud. Dos `CHECK` nuevos en esa tabla | — |
| DD-13 | **`GRANT BACKUP DATABASE`** (no `db_backupoperator`) a `gpos_app` y a la cuenta de la API en `GPOS_SYSDATA` | `db_backupoperator` incluye `BACKUP LOG`: un respaldo de registro hecho por la API cortaría la cadena del cliente |
| DD-14 | **`MarcaDesbloqueoNcf`:** «solo sube» lo garantiza **la base** (disparador `AFTER INSERT`, 52008), no solo el procedimiento. Índice **único** de la clave | [SW] lo dejaba en `RegistrarMarcaP7` |
| DD-15 | **`RespaldoPosterior` sin índice por estado:** menos de 100 filas al año | [SW] pedía `(Estado, SolicitadoUtc)` |
| DD-16 | **Bloque B de [C81]: una corrección.** `LiberarCandadoRestauracion` aceptaba `@ForkEsperado = NULL` y se saltaba la comprobación del estado consultado (`@fork <> NULL` es desconocido, no verdadero) | Se avisa a C (§12) |

---

## 1. Contexto y modelo de tenencia aplicado

- **Tenencia:** una base por empresa, más `GPOS_SYSDATA` (`CLAUDE.md`, «Datos») [V].
  - El **disparador**, **C9** y la columna viven en la base de la empresa. El aislamiento lo da la conexión.
  - La **marca P-7** y el **respaldo posterior** viven en `GPOS_SYSDATA`, que no se restaura junto con la empresa: ese es el propósito de P-7. Cada fila lleva `EmpresaCodigo`, que el servicio toma de la sesión, nunca del cuerpo ([SW] §8).
  - La **recomposición** lee cada base de empresa con su propia cadena (`IConexionesEmpresa`), solo con `SELECT`.
- **Mecanismo de la base de empresa** (igual que en [D11] §1) [V]:
  - migración de EF con su `Designer`;
  - SQL a mano en `SqlMigraciones*.cs`, dentro de `Exec(...)`;
  - guion acumulado `database/empresa/gpos-empresa-<marca>_<Nombre>.sql`, regenerado con `--idempotent`, que **sustituye** al anterior (`database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql` es el vigente).
- **Mecanismo de `GPOS_SYSDATA`:** §7.3.

---

## 2. Tablas y relaciones

### 2.1 Base de empresa

**Ninguna tabla nueva.** Cambia una tabla.

**`sync.ReconciliacionChequera`: columna `Referencia varchar(100) NULL`** (P-3, el talonario consultado). Tiene el mismo largo que `ReconciliacionNcf.Referencia` (`src/GPOS.Core/Datos/Empresa/Configuracion/SyncConfiguracion.cs:116`) [V]. Admite nulo por dos razones: las filas de la entrega 2 y las anteriores no la tienen. En la base única, C9 la exige.

**Semántica de las columnas existentes** en la base única (`src/GPOS.Core/Dominio/Configuracion/Bandeja.cs:117-124`) [V]:

| Columna | Valor |
|---|---|
| `SiguienteLocal` | `banco.Chequera.Siguiente` antes de tocarla. Si la cuenta no tenía chequera (variante (b) de PD-Q2): `ISNULL(MAX(NumeroCheque), 0) + 1`, lo mismo que habría creado `CrearChequera` (`src/GPOS.Core/Consultas/Bancos/ConsultasLibroBanco.cs:36-40`) [V] |
| `UltimoEmitido` | `MAX(NumeroCheque)` de `banco.DocBanco` de la cuenta, **incluidos los anulados** (R4-51); `NULL` si no hay cheques |
| `SiguienteConfirmado` | El que confirma el SUPER con el talonario en la mano |
| `Referencia` | El talonario consultado, de 5 a 100 caracteres |

### 2.2 `GPOS_SYSDATA`

| Objeto | Origen | Filas |
|---|---|---|
| `dbo.BitacoraSeguridad` (con 2 índices y 2 disparadores) | **Bloque A de [C81]** (`§7.2`), sin cambios, **sin** `PurgarBitacoraSeguridad` (la construye C en T2) | Según [C81-D] §8: ≤ 40 MB en régimen |
| `dbo.RestauracionSistema`, `dbo.EstadoRestauracionSistema` y `dbo.LiberarCandadoRestauracion` | **Bloque B de [C81]**, con la corrección DD-16 | 1 |
| `dbo.ReconciliarRestauracionSistema` | Bloque B **sin** los pasos del factor (§7.2.3) | — |
| **`dbo.MarcaDesbloqueoNcf`** (nueva) | P-7 ([SW] §4.2) | Una por prefijo y desbloqueo que suba |
| **`dbo.RegistrarMarcaP7`** (nuevo) | P-7 | — |
| **`dbo.RespaldoPosterior`** (nueva) | R4 ([SW] §4.3) | 2 por desbloqueo |

**Relaciones:**
- `MarcaDesbloqueoNcf.EmpresaCodigo` y `RespaldoPosterior.EmpresaCodigo` → `dbo.Empresas (Codigo)`, sin cascada (PD-Q5). `Empresas.Codigo` es `nvarchar(30)` (`src/GPOS.Core/Data/Sistema/SistemaDbContext.cs:73-74`) [V].
- **Ninguna** referencia a `Usuarios`: la marca y el respaldo sobreviven a la cuenta, como `BitacoraSeguridad`.

**Tipos:** en `GPOS_SYSDATA` el texto es Unicode (ADR-50 no aplica). Hay una excepción: `Prefijo char(3)`, el mismo tipo que `fiscal.SecuenciaNcf.Prefijo` (`src/GPOS.Core/Datos/Empresa/Configuracion/FisConfiguracion.cs:44`) [V]. Así la comparación es directa al recomponer.

---

## 3. Restricciones e integridad

### 3.1 Base de empresa

| Nombre | Tabla | Expresión | Para qué |
|---|---|---|---|
| `CK_ReconciliacionChequera_Referencia` | `ReconciliacionChequera` | `Referencia IS NULL OR LEN(Referencia) >= 5` | Mismo piso que `CK_ReconciliacionNcf_Evidencia` |
| `CK_ReconciliacionChequera_Avance` | `ReconciliacionChequera` | `SiguienteConfirmado >= SiguienteLocal AND (UltimoEmitido IS NULL OR SiguienteConfirmado > UltimoEmitido) AND SiguienteConfirmado <= 999999999` | La chequera «solo avanza» (`src/GPOS.Core/Dominio/Bancos/Bancos.cs:6-8`) [V] y respeta `CK_Chequera_Siguiente` (`BanConfiguracion.cs:19`) [V]. Vale también para la entrega 2: tras restaurar, el contador nunca retrocede |

Se mantiene `CK_ReconciliacionChequera_Sig` (`SiguienteConfirmado > 0`, `SyncConfiguracion.cs:112`) [V].

**Disparador `doc.TR_Documento_Candado` → 51403** (§7.1.3). **C9 → 51329 «C9»** (§3.2).

### 3.2 Regla C9 de `sync.usp_ConfirmarReconciliacionLocal`

Como C0 a C8 ([D11] §3.3), el procedimiento no confía en el servicio: comprueba los datos ya escritos.

| Parte | Qué comprueba |
|---|---|
| C9a, completitud | Si `@Causa = 'RESTAURACION'` o ya hay filas de chequera en esta reconciliación, **toda cuenta del alcance** tiene su fila. **Alcance:** las cuentas con fila en `banco.Chequera`, como dice [SW]. Con la variante (b) de **PD-Q2**, también las cuentas habilitadas sin chequera. Es el mismo criterio que C6 para las series, y también contesta PD-Q3 |
| C9b, contenido | Para cada fila: la chequera existe; `banco.Chequera.Siguiente = SiguienteConfirmado`; `SiguienteConfirmado ≥ SiguienteLocal`; `SiguienteConfirmado > MAX(NumeroCheque)` de la cuenta, anulados incluidos; `UltimoEmitido` es igual a ese máximo (así el registro dice la verdad); y `Referencia` tiene 5 caracteres o más |

---

## 4. Índices y consultas que los justifican

| Índice | Decisión | Consulta | Costo de escritura |
|---|---|---|---|
| `UX_DocBanco_Cheque` (`CuentaBancariaId, NumeroCheque`), filtrado `NumeroCheque IS NOT NULL` | Existente (`BanConfiguracion.cs:54`) [V]; se reutiliza | C9b y la lectura de R1: `MAX(NumeroCheque) … WHERE CuentaBancariaId = … AND NumeroCheque IS NOT NULL`. **El predicado `IS NOT NULL` se escribe aunque `MAX` ignore los nulos**, para que el optimizador pueda usar el índice filtrado (búsqueda al final del rango) | — |
| `UX_MarcaDesbloqueoNcf_Clave` (`EmpresaCodigo, NodoId, Prefijo, UltimoProbado DESC`) `INCLUDE (Origen, RegistradoUtc)`, **único** | Nuevo | (1) La marca vigente por empresa y nodo (R1 a R3); (2) la lectura con `UPDLOCK, HOLDLOCK` de `RegistrarMarcaP7`, que bloquea **solo el rango de la clave** y no toda la tabla; (3) el disparador «solo sube». Que sea único es integridad: dos filas iguales no tienen sentido | Una fila por desbloqueo y prefijo, unas pocas veces al año |
| `PK_RespaldoPosterior` y `UX_RespaldoPosterior_Pedido` (`EmpresaCodigo, ReconciliacionId, BaseDatos`) | Nuevos | La unicidad hace **idempotente** el encolado: si se reintenta el paso 7 de R3, no se duplica la fila. El último respaldo de la empresa (R1) es `TOP (2) … WHERE EmpresaCodigo = @e ORDER BY ReconciliacionId DESC` sobre el mismo índice | 2 filas por desbloqueo |
| `(Estado, SolicitadoUtc)` de [SW] | **No se crea** | La cola del trabajador | Con menos de 100 filas al año [I], el recorrido cuesta menos que mantener el índice |
| **Ninguno** en `doc.Documento` | — | El disparador lee `sync.EstadoNodo` por su clave (1 fila) y la vista del catálogo | — |

**Consultas de referencia para el desarrollador** (SQL a mano con parámetros del tipo de su columna; ADR-50 en la base de empresa):

```sql
-- R1/R2 (base de empresa): chequeras del alcance. @conHabilitadas bit = 1 solo con la variante (b) de PD-Q2
SELECT c.Id AS CuentaBancariaId, c.Codigo, b.Nombre AS Banco,
       ISNULL(q.Siguiente, ISNULL(u.Ultimo, 0) + 1) AS SiguienteEnBase, u.Ultimo AS UltimoChequeEnBase,
       CONVERT(bit, CASE WHEN q.CuentaBancariaId IS NULL THEN 0 ELSE 1 END) AS TieneChequera
  FROM banco.CuentaBancaria c
  JOIN cat.Banco b ON b.Id = c.BancoId
  LEFT JOIN banco.Chequera q ON q.CuentaBancariaId = c.Id
 OUTER APPLY (SELECT MAX(d.NumeroCheque) AS Ultimo FROM banco.DocBanco d
               WHERE d.CuentaBancariaId = c.Id AND d.NumeroCheque IS NOT NULL) u
 WHERE q.CuentaBancariaId IS NOT NULL OR (@conHabilitadas = 1 AND c.Inhabilitado = 0)
 ORDER BY c.Id;

-- R1/R2 (I-12) y recomposición (base de empresa): el corte por nodo y prefijo de las reconciliaciones confirmadas
SELECT z.NodoId, z.Prefijo, z.Corte, z.ReconciliacionId, z.ForkActual
  FROM (SELECT r.NodoId, s.Prefijo, x.UltimoConocido AS Corte, r.Id AS ReconciliacionId, r.ForkActual,
               ROW_NUMBER() OVER (PARTITION BY r.NodoId, s.Prefijo ORDER BY x.UltimoConocido DESC, r.Id DESC) AS n
          FROM sync.ReconciliacionNcf x
          JOIN sync.Reconciliacion r ON r.Id = x.ReconciliacionId
          JOIN fiscal.SecuenciaNcf s ON s.Id = x.SecuenciaId
         WHERE r.Estado = 'C' AND r.Causa IN ('RESTAURACION', 'TRASLADO') AND x.UltimoConocido IS NOT NULL) z
 WHERE z.n = 1;

-- R1 a R3 (GPOS_SYSDATA): la marca vigente por prefijo. @e nvarchar(30), @n smallint
SELECT m.Prefijo, m.UltimoProbado, m.Origen, m.RegistradoUtc
  FROM (SELECT Prefijo, UltimoProbado, Origen, RegistradoUtc,
               ROW_NUMBER() OVER (PARTITION BY Prefijo ORDER BY UltimoProbado DESC) AS n
          FROM dbo.MarcaDesbloqueoNcf WHERE EmpresaCodigo = @e AND NodoId = @n) m
 WHERE m.n = 1;
```

Las tablas `sync.Reconciliacion*` tienen decenas de filas por desbloqueo ([D11] §10), así que la consulta de los cortes no necesita índice.

---

## 5. Auditoría y trazabilidad

- **P-3:** `sync.ReconciliacionChequera` es el registro (el anterior, el último emitido, el confirmado y el talonario). Es inmutable: tiene `DENY UPDATE, DELETE` (`SqlMigracionesH11.cs:258`) [V] y el disparador «solo abierta» (51389, `:265-273`) [V].
  - El servicio escribe `CHEQUERA_CONFIRMADA_RESTAURACION` en `audit.Bitacora`, una línea por cuenta ([SW] §4.4).
  - No la escribe el procedimiento. Las dos líneas finales de DD-1 ya dejan la confirmación y el desbloqueo juntos, y el detalle por cuenta está en la tabla. *Alternativa descartada:* un JSON por cuenta en el procedimiento. Duplicaría la tabla.
- **P-7:** `MarcaDesbloqueoNcf` guarda su propia historia: cada fila tiene origen, reconciliación, fork, usuario y hora, y no hay `UPDATE` ni `DELETE`. Los eventos `MARCA_P7_*` son el espejo legible ([SW] §4.4).
- **Respaldo posterior:** el estado queda en la tabla. El resultado va a `audit.Bitacora` de la empresa, y el tercer fallo, a `BitacoraSeguridad` (A).
- **Candado del sistema:** los eventos de [C81] §4.4 en `BitacoraSeguridad`. `SISTEMA_RESTAURADO` y `CANDADO_RESTAURACION_LIBERADO` los escriben los procedimientos, en la misma transacción que el cambio de estado.

---

## 6. Persistencia de la sincronización: R3 ampliado (P-3) y orden de bloqueos

No hay sincronización con la central en la entrega 1. Lo que sigue amplía la transacción única de [D11] §6.1. Los pasos nuevos llevan la letra «b».

| # | Nivel (ADR-45) | Sentencia | Bloqueo |
|---|---|---|---|
| **0b** | **Documentos** | `sp_getapplock` de `GPOS.Chequera:{CÓDIGO}` (`Chequeras.Recurso`, `src/GPOS.Core/Negocio/Comun.cs:250-251`) [V] por **cada cuenta del alcance**, en **una sola pasada ordinal** (`StringComparer.Ordinal` sobre el recurso, con `BloqueoDocumentos.BloquearRecursosAsync`), `LockOwner = 'Transaction'` (`src/GPOS.Core/Infraestructura/Motor/BloqueoAplicacion.cs:24`) [V]. Va **antes** del paso 1 | Bloqueo de aplicación `X` por cuenta hasta el `COMMIT` |
| 1 a 7 | Configuración → series → NCF | Sin cambios ([D11] §6.1) | — |
| **7b** | Fila de la chequera (ya protegida por 0b) | Por cuenta, en orden de `CuentaBancariaId`: (a) solo con la variante (b) de PD-Q2, `INSERT banco.Chequera (CuentaBancariaId, Siguiente) SELECT @cuenta, @confirmado WHERE NOT EXISTS (SELECT 1 FROM banco.Chequera WITH (UPDLOCK, HOLDLOCK) WHERE CuentaBancariaId = @cuenta);` (b) `UPDATE banco.Chequera SET Siguiente = @confirmado, ActualizadaEn = SYSUTCDATETIME() WHERE CuentaBancariaId = @cuenta;` (exige 1 fila) (c) `INSERT sync.ReconciliacionChequera (ReconciliacionId, CuentaBancariaId, SiguienteLocal, UltimoEmitido, SiguienteConfirmado, Referencia) VALUES (@rec, @cuenta, @local, @ultimo, @confirmado, @referencia);` | `X` de fila en `banco.Chequera` |
| 8 a 10 | — | Bitácora del servicio (más `CHEQUERA_CONFIRMADA_RESTAURACION`), `usp_ConfirmarReconciliacionLocal` (ahora con C9) y `COMMIT` | — |

**Tipos de los parámetros:** `@cuenta smallint`, `@confirmado int`, `@local int`, `@ultimo int` (admite nulo), `@referencia varchar(100)` y `@rec int`.

**Por qué no hay interbloqueo [I]** (lo prueba PDS-09):
- El único que toma `GPOS.Chequera:` hoy es el pago con cheque sin número (`Comun.cs:241-246`) [V]. Lo hace en el nivel de documentos, igual que 0b, así que dos transacciones con el mismo recurso hacen fila y no forman ciclo.
- El cheque con número escrito a mano (`AvanzarChequera`, `ConsultasLibroBanco.cs:43-45`) [V] toca la fila sin el bloqueo de aplicación. En una base restaurada, sin embargo, ese pago falla antes:
  - la guarda del servicio lee `sync.EstadoEmision WITH (HOLDLOCK)` en el nivel de configuración (`src/GPOS.Core/Servicios/Modulos/Numeracion/DocumentosNg.cs:43`) [V], y el paso 1 de R3 tiene la fila en `X`;
  - además, el disparador 51403 rechaza su `doc.Documento`;
  - y el middleware lo rechaza antes de llegar a la base.
- La lista de cuentas se lee **antes** de 0b. Una cuenta creada en el medio (imposible con el candado de la ruta) haría fallar C9a, con 51329 y la reversión completa. Es seguro.

---

## 7. Script de migración y reversión

### 7.1 Base de empresa: migración `H11CandadoChequeras` (después de `20261010130522_BitacoraLogSoloInsercion`)

#### 7.1.1 Archivos

| Archivo | Contenido |
|---|---|
| `src/GPOS.Core/Datos/Empresa/Migraciones/<marca>_H11CandadoChequeras.cs` y su `Designer` | Migración |
| `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesH11CandadoChequeras.cs` | `H11CandadoPrevia()`, `H11CandadoSql()`, `H11CandadoDownPrevia()`, `H11CandadoDownSql()` |
| `SqlMigracionesH11.cs` | **Refactorización sin cambiar el texto:** extraer el `Exec(...)` del procedimiento a `H11ConfirmarReconciliacion()` y la cadena de C0 a C8 a una constante. `H11VistaProcedimientosPermisos()` los compone igual que hoy. **Condición:** el tramo de H-11 del guion regenerado debe quedar idéntico byte a byte (lo comprueba PDS-01) |
| `Bandeja.cs` (clase `ReconciliacionChequera`) | `public string? Referencia { get; set; }` |
| `SyncConfiguracion.cs` | `Referencia` con `HasMaxLength(100)` (`varchar`, ADR-50) y los dos `CHECK` de §3.1 |
| `src/GPOS.Core/Datos/Empresa/Configuracion/DisparadoresNg.cs:31-32` | Agregar `"TR_Documento_Candado"` a `doc.Documento`. Es obligatorio por dos razones: EF no debe usar `OUTPUT` sin `INTO`, y la prueba que compara los disparadores de la base con la lista (`tests/GPOS.Tests/ModeloNg/NucleoTransaccionalNgTests.cs:85`) [V] fallaría |
| `EmpresaNgDbContextModelSnapshot.cs` | Regenerado |
| `database/empresa/gpos-empresa-<marca>_H11CandadoChequeras.sql` | `dotnet ef migrations script --idempotent -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o …`. **Se borra** `gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql` |
| `src/GPOS.Core/Infraestructura/Numeracion/ErroresNumeracion.cs` | 51403 → 503 `BASE_RESTAURADA`, junto a 51330 (`:128-129`) [V]. Lo hace el backend |

#### 7.1.2 Orden del `Up`

1. `Sql(H11CandadoPrevia())`:
   ```sql
   IF EXISTS (SELECT 1 FROM sync.ReconciliacionChequera
               WHERE SiguienteConfirmado < SiguienteLocal
                  OR (UltimoEmitido IS NOT NULL AND SiguienteConfirmado <= UltimoEmitido)
                  OR SiguienteConfirmado > 999999999)
       THROW 51399, N'Hay chequeras reconciliadas que retroceden: revíselas antes de aplicar H11CandadoChequeras.', 1;
   ```
   *Inferido:* en las bases reales la tabla está vacía. La comprobación protege las bases de prueba restauradas.
2. EF: `AddColumn Referencia varchar(100) NULL` y los dos `AddCheckConstraint`.
3. `Sql(H11CandadoSql())`, con cada objeto en `Exec(...)`: el disparador (7.1.3), el procedimiento con C9 (7.1.4) y el permiso:
   ```sql
   GRANT BACKUP DATABASE TO gpos_app;   -- DD-13: el respaldo posterior y «Respaldar ahora» con RG-14; sin BACKUP LOG
   ```
   El `GRANT EXECUTE` del procedimiento se conserva con `CREATE OR ALTER`.

**Duración y bloqueos [I]:**
- `ADD` de una columna que admite nulo: solo metadatos.
- Dos `CHECK` sobre una tabla de 0 filas.
- `CREATE TRIGGER` sobre `doc.Documento` toma `Sch-M` durante milisegundos.
- **Total: menos de 1 s.** Se aplica con la API detenida, como toda migración.

#### 7.1.3 Disparador del candado (CR-01)

```sql
CREATE OR ALTER TRIGGER doc.TR_Documento_Candado ON doc.Documento AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    -- DD-10: si la sentencia solo emite (0 → 1), 51330 ya la vigila con una condición más amplia; no se lee dos veces el estado del sitio.
    -- Sin filas (sentencia que no tocó nada) también sale aquí.
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.Id = i.Id
                    WHERE d.Id IS NULL OR NOT (d.Estado = 0 AND i.Estado = 1))
       AND NOT EXISTS (SELECT 1 FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.Id = d.Id))
        RETURN;
    -- CR-01 (DD-9): la base se restauró (fork nulo o distinto, falla cerrada) o sigue bloqueada por una restauración sin desbloquear.
    -- La excepción de la reaplicación (entrega 2) es la misma de 51330.
    IF EXISTS (SELECT 1 FROM sync.EstadoNodo s
                 LEFT JOIN sys.database_recovery_status r ON r.database_id = DB_ID()
                WHERE s.Id = 1
                  AND (r.recovery_fork_guid IS NULL OR r.recovery_fork_guid <> s.ForkRegistrado
                       OR (s.EmisionBloqueada = 1 AND s.MotivoBloqueo = 'RESTAURACION'))
                  AND NOT EXISTS (SELECT 1 FROM sync.Reconciliacion x
                                   WHERE x.Id = s.ReconciliacionId AND x.Estado = 'R'
                                     AND x.Id = TRY_CONVERT(int, SESSION_CONTEXT(N'gpos.reaplicacion'))))
        THROW 51403, N'La base fue restaurada: no se registran ni cambian documentos hasta desbloquearla (CR-01) (BASE_RESTAURADA).', 1;
END
```

**Qué cubre** (todo el negocio documental pasa por `doc.Documento`):

| Operación | Quién la rechaza |
|---|---|
| Alta de borrador (`INSERT`) | 51403 |
| Edición de borrador (notas, fecha, motivo) | 51403 |
| Borrado de borrador | 51403 |
| Emisión (0 → 1) | 51330, la guarda que ya existe (`SqlMigracionesOla3EmisionLigera.cs:49-55`) [V] |
| Anulación (1 → 2) | 51403. `TR_Documento_Anulacion` no lee el sitio |
| Caja (`caja.Movimiento`) | 51330 (`SqlMigracionesOla3.cs:334-342`) [V] |

**Base sin identidad de sitio** (sin fila en `EstadoNodo`): pasa, igual que 51330. Sin fork registrado no hay restauración que detectar.

**Escritores legítimos de la lista blanca de [SW] §5.4** (revisados contra el código; ninguno escribe `doc.Documento`):

| Escritor | Qué escribe | ¿Lo rompe 51403? |
|---|---|---|
| Reimpresión y reintento (PC-4; también los `GET` de impresión) | `doc.Impresion` (`src/GPOS.Core/Consultas/Numeracion/ConsultasImpresion.cs:39-41`), `doc.Autorizacion` (`ConsultasDocumentos.cs:167-170`) y `audit.Bitacora`/`_LOG` (`src/GPOS.Core/Servicios/ReimpresionService.cs:80-108`) [V] | **No**. Ninguna de esas tablas tiene un disparador que actualice `doc.Documento` [V: no hay `UPDATE doc.Documento` en ningún disparador] |
| Vista previa fiscal del formato | `audit.Bitacora` (`ReimpresionService.cs:115-123`) [V] | No |
| Alta de secuencias NCF por el SUPER (PC-2) | `fiscal.SecuenciaNcf`. Sus disparadores son 51324 a 51326 (solapes y cierres), no el candado [V] | No. Para el desbloqueo, la secuencia nueva es una `A` más: entra en el plan de R1 y C3 le exige su fila |
| R3 | `sync.*`, `num.Serie`, `fiscal.*`, `banco.Chequera` y `audit.Bitacora` | No |
| R4 y «Respaldar ahora» | `BACKUP` y una línea de auditoría (`src/GPOS.Core/Servicios/RespaldoService.cs:22-34`) [V] | No |
| Inicio de sesión, dispositivos, reloj y liberación del sistema | `GPOS_SYSDATA` | No |

**Pruebas actuales que dependen de esto [V]:**
- `DisparadoresEmisionTests` casos 16 y 17 (`tests/GPOS.Tests/ModeloNg/DisparadoresEmisionTests.cs:189-192`): siguen dando 51330. El caso 16 usa un bloqueo `MANUAL`, que no activa el candado (DD-9), y el 17 es una emisión pura (DD-10).
- Las pruebas de la guarda con `MANUAL` (`NucleoTransaccionalNgTests.cs:97`, `QaOla3RevisionTests.cs:368`) no cambian.
- `DesbloqueoRestauracionTests` rechaza por la guarda del servicio antes de insertar. Las pruebas que preparan datos **después** de `RestaurarAsync` (por ejemplo, un artículo con existencia inicial, que crea un documento) recibirán 51403. QA debe correr `ModeloNg` completo (§11).

**Migraciones de datos futuras sobre `doc.Documento`** (por ejemplo, H-2): deben aplicar `DISABLE TRIGGER doc.TR_Documento_Candado ON doc.Documento` y reactivarlo con el patrón `TRY/CATCH` de `SqlMigracionesOla4OrdenRecibida.cs:65-78` [V]. Si no, una base restaurada no se podría actualizar. Se protege con PDS-12, una guarda estática.

**Costo [I]:**
- Venta POS (un `INSERT` del borrador más la emisión en la misma transacción): una lectura de unos 19 µs en el `INSERT` más el despacho de un disparador, de unos 3 a 8 µs. La emisión no lee de nuevo. **Total ≈ 25 µs**, frente al tope de +0,03 ms. Es justo: lo mide PDS-06.
- **Plan de reserva**, si se pasa del tope:
  1. fundir la comprobación del `INSERT` en `TR_Documento_Nace`, que ahorra el despacho;
  2. si aun así no alcanza, que el propietario acepte el costo, porque CR-01 está firmado.
- *Alternativa descartada:* que el servicio marque `SESSION_CONTEXT` al pasar la guarda y el disparador lo use como atajo. `gpos_app` puede escribir esa clave, así que dejaría saltar el candado.

#### 7.1.4 Procedimiento de confirmación con C9

Se inserta **entre C8 y `IF @regla IS NOT NULL`** del texto de `SqlMigracionesH11.cs:200-209` [V]. El resto del procedimiento no cambia.

```sql
    -- C9 (P-3): chequeras. Completitud con el criterio de C6 (RESTAURACION, o ya hay filas)
    IF @regla IS NULL
       AND (@Causa = 'RESTAURACION' OR EXISTS (SELECT 1 FROM sync.ReconciliacionChequera WHERE ReconciliacionId = @ReconciliacionId))
       AND EXISTS (SELECT 1 FROM banco.CuentaBancaria c WITH (READCOMMITTEDLOCK)
                    WHERE (EXISTS (SELECT 1 FROM banco.Chequera q WITH (READCOMMITTEDLOCK) WHERE q.CuentaBancariaId = c.Id)
                           /* variante (b) de PD-Q2: */ OR c.Inhabilitado = 0)
                      AND NOT EXISTS (SELECT 1 FROM sync.ReconciliacionChequera x
                                       WHERE x.ReconciliacionId = @ReconciliacionId AND x.CuentaBancariaId = c.Id))
        SET @regla = 'C9';
    -- C9: contenido de cada fila contra la chequera y los cheques de la cuenta (anulados incluidos, R4-51)
    IF @regla IS NULL AND EXISTS (
        SELECT 1
          FROM sync.ReconciliacionChequera x
          LEFT JOIN banco.Chequera q WITH (READCOMMITTEDLOCK) ON q.CuentaBancariaId = x.CuentaBancariaId
         OUTER APPLY (SELECT MAX(d.NumeroCheque) AS Ultimo FROM banco.DocBanco d WITH (READCOMMITTEDLOCK)
                       WHERE d.CuentaBancariaId = x.CuentaBancariaId AND d.NumeroCheque IS NOT NULL) u
         WHERE x.ReconciliacionId = @ReconciliacionId
           AND (   q.CuentaBancariaId IS NULL
                OR q.Siguiente <> x.SiguienteConfirmado
                OR x.SiguienteConfirmado < x.SiguienteLocal
                OR (u.Ultimo IS NOT NULL AND x.SiguienteConfirmado <= u.Ultimo)
                OR ISNULL(x.UltimoEmitido, -1) <> ISNULL(u.Ultimo, -1)
                OR x.Referencia IS NULL OR LEN(x.Referencia) < 5))
        SET @regla = 'C9';
```

- Con la variante (a) de PD-Q2 se quita la línea `OR c.Inhabilitado = 0`. El texto es el mismo en todo lo demás.
- `READCOMMITTEDLOCK`, como C3 a C7: lee los datos confirmados con bloqueo, no la versión de RCSI.
- **`TRASLADO`** (PD-Q3): sin filas de chequera, C9 no exige nada. Con alguna fila, exige todas. Es el mismo criterio que C6.

#### 7.1.5 `Down`

1. `H11CandadoDownPrevia()`, dentro de `Exec` porque cita la columna nueva. Sigue la convención 51399:
   ```sql
   IF EXISTS (SELECT 1 FROM sync.ReconciliacionChequera WHERE Referencia IS NOT NULL)
       THROW 51399, N'La reversión perdería la evidencia de las chequeras de un desbloqueo: no se puede volver a BitacoraLogSoloInsercion.', 1;
   ```
2. `H11CandadoDownSql()`:
   ```sql
   DROP TRIGGER IF EXISTS doc.TR_Documento_Candado;
   REVOKE BACKUP DATABASE FROM gpos_app;
   ```
   Después, **`SqlMigraciones.H11ConfirmarReconciliacion()`**, el texto de H-11 sin C9, tomado de su clase y no copiado. Es el mismo patrón que el `Down` de `Ola4FactorUnidad` (`SqlMigracionesOla4FactorUnidad.cs:17-18`) [V].
3. EF, en orden inverso: los dos `DropCheckConstraint` y `DropColumn Referencia`.

**Prueba:** PDS-01 (`Up`, `Down`, `Up`, con el nombre fijo de la migración desde el principio, como pidió la revisión de los ajustes de B en [SW] §13.4).

### 7.2 `GPOS_SYSDATA`: SQL idempotente

Va en un archivo nuevo, `src/GPOS.Core/Data/Sistema/EsquemaSistema.Restauracion.cs` (`partial` de `EsquemaSistema`), con **cuatro constantes que se ejecutan en este orden** después del lote actual de `ActualizarAsync` (`EsquemaSistema.cs:46-150`) [V]:
1. `SqlBitacoraSeguridad`;
2. `SqlRestauracionSistema`;
3. `SqlMarcaP7`;
4. `SqlRespaldoPosterior`.

Así C agrega sus bloques al lado sin tocar las mismas líneas. Esto reduce R-14 de [SW].

**Reglas del texto:**
- todo `CREATE OR ALTER` de vista, procedimiento o disparador va en `EXEC (N'…')`;
- **también los `ENABLE TRIGGER`**, que [C81] deja sueltos: en una base nueva la tabla no existe cuando se compila el lote. Lo verifica PDS-20;
- **sin llaves `{` `}` en el texto**, porque `ExecuteSqlRawAsync` puede tratar la cadena como formato [I]. Otra opción: ejecutarlas con `SqlCommand`.

#### 7.2.1 `SqlBitacoraSeguridad`

Es el texto del bloque A de [C81] §7.2, de `IF OBJECT_ID(N'dbo.BitacoraSeguridad'…` a los dos `ENABLE TRIGGER`, **sin cambios** salvo que los `ENABLE` van en `EXEC`. **No** incluye las columnas de CS en `Usuarios`, `UsuariosFactor`, `UsuariosCodigosRespaldo` ni `PurgarBitacoraSeguridad`: los construye C.
- Los nombres y las columnas son idénticos, así que C no tiene que migrar nada: su `IF OBJECT_ID … IS NULL` encontrará la tabla.
- `TR_BitacoraSeguridad_Purga` deja borrar filas de más de 2 años aunque todavía no exista el procedimiento de purga. Es inocuo: con RG-14 la API no tiene `DELETE`.

#### 7.2.2 `SqlRestauracionSistema`: bloque B con la corrección DD-16

- La tabla `dbo.RestauracionSistema` y la vista `dbo.EstadoRestauracionSistema` son las de [C81] §7.2, **sin cambios**.
- `dbo.LiberarCandadoRestauracion` es el texto de [C81] con **un solo cambio**:

```sql
-- antes:  IF @@ROWCOUNT = 0 OR @fork IS NULL OR @fork <> @ForkEsperado OR @rec <> @fork
-- después:
    IF @@ROWCOUNT = 0 OR @fork IS NULL OR @ForkEsperado IS NULL OR @fork <> @ForkEsperado OR @rec <> @fork
        THROW 52004, ''El estado de la restauración cambió; vuelva a consultarlo.'', 1;
```

**Validación del bloque B** (pedida en [C81] §10; la confirma la prueba real PDS-15):

| Punto | Resultado |
|---|---|
| `Nivel = 'SUPER'` | **Verificado:** `NivelesUsuario.Super = "SUPER"` (`src/GPOS.Contracts/Seguridad/Cuentas.cs:32`). `Usuarios.Nivel` es `nvarchar(10)` (`SistemaDbContext.cs:31`) e `Inhabilitado` existe (`:135`) |
| `THROW` dentro de `BEGIN TRAN` | Correcto: con `XACT_ABORT ON`, `THROW` sin `TRY` deshace la transacción [I, PDS-15] |
| Primera vez sin fila | Registra el fork y no activa el candado. **Falla abierta** si se restaura un respaldo de `GPOS_SYSDATA` **anterior a esta versión**, que no tiene la tabla (R-D13, PD-Q6) |
| La vista con `sys.database_recovery_status`, leída por un usuario sin `VIEW DATABASE STATE` | En la base de empresa está medido: lo lee `gpos_app` (T95 de H0; PD-05 de H-11 en `tests/GPOS.Tests/ModeloNg/DesbloqueoRestauracionApiTests.cs:62-68`) [V]. En `GPOS_SYSDATA` debería ser igual [I]: lo mide PDS-16. **Plan de reserva:** una función `dbo.ufn_ForkActual()` con `EXECUTE AS OWNER` que la vista llama en lugar del `JOIN` (+0,03 sp) |
| Encadenamiento de propiedad | La vista y los procedimientos son de `dbo`, igual que las tablas. Un `DENY` directo sobre `RestauracionSistema` no afecta la lectura por la vista ni la escritura por los procedimientos [I, PDS-16] |
| `@ForkEsperado = NULL` | **Defecto** (DD-16), corregido arriba |

#### 7.2.3 `ReconciliarRestauracionSistema` sin el factor

Es el texto de [C81] con tres cambios: se quitan `SelloSeguridad` y `SesionTokenId` del `UPDATE dbo.Usuarios`, y se quita el `UPDATE` de `UsuariosFactor`. Esas columnas y esa tabla todavía no existen, y `CREATE PROCEDURE` no difiere la resolución de columnas en una tabla que ya existe. C lo reemplaza en su T5b con `CREATE OR ALTER`.

```sql
EXEC (N'CREATE OR ALTER PROCEDURE dbo.ReconciliarRestauracionSistema WITH EXECUTE AS OWNER AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @fork uniqueidentifier = (SELECT recovery_fork_guid FROM sys.database_recovery_status WHERE database_id = DB_ID());
    IF @fork IS NULL THROW 52003, ''No se pudo leer el fork de recuperación de GPOS_SYSDATA.'', 1;
    DECLARE @reg uniqueidentifier, @rec uniqueidentifier, @ahora datetime2(3) = SYSUTCDATETIME(), @previo datetime2(3);
    BEGIN TRAN;
    SELECT @reg = ForkRegistrado, @rec = ForkReconciliado FROM dbo.RestauracionSistema WITH (UPDLOCK, HOLDLOCK) WHERE Id = 1;
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.RestauracionSistema (Id, ForkRegistrado, ForkReconciliado) VALUES (1, @fork, @fork);
        COMMIT; SELECT CAST(0 AS bit) AS Reconcilio; RETURN;
    END
    IF @rec = @fork BEGIN COMMIT; SELECT CAST(0 AS bit) AS Reconcilio; RETURN; END
    SET @previo = (SELECT MAX(MomentoUtc) FROM dbo.BitacoraSeguridad);
    -- Versión de A (sin el factor): cierra todas las sesiones. C agrega el sello, SesionTokenId, UltimoPaso y CodigosRevividos (T5b)
    UPDATE dbo.Usuarios SET SesionId = NULL, SesionesRevocadas = @ahora;
    UPDATE dbo.RestauracionSistema SET ForkReconciliado = @fork, CandadoDesdeUtc = @ahora, UltimoEventoPrevioUtc = @previo,
                                       LiberadoUtc = NULL, LiberadoPor = NULL WHERE Id = 1;
    INSERT dbo.BitacoraSeguridad (Evento, Severidad, Actor, Canal, Detalle)
    VALUES (''SISTEMA_RESTAURADO'', ''A'', N''GPOS.Api'', ''SISTEMA'',
            CONCAT(N''Fork registrado '', @reg, N''; actual '', @fork, N''; último evento previo '', CONVERT(nvarchar(23), @previo, 126)));
    COMMIT; SELECT CAST(1 AS bit) AS Reconcilio;
END');
```

Las columnas `SesionId` y `SesionesRevocadas` existen (`EsquemaSistema.cs:50`, `:55-56`) [V].

**Deriva entre binarios (R-D14):**
- En desarrollo, varios árboles del mismo equipo usan el mismo `GPOS_SYSDATA` (`.\SQLEXPRESS;Database=GPOS_SYSDATA`, `src/GPOS.Api/appsettings.Development.json:3`) [V].
- Cuando entre la versión completa de C, un árbol más viejo de A que arranque **volverá a dejar la versión sin factor**, porque `CREATE OR ALTER` gana en cada arranque.
- **Recomendación (PD-Q4):** una guarda de versión por propiedad extendida, solo en este procedimiento:

```sql
IF ISNULL(CONVERT(int, (SELECT value FROM sys.extended_properties
                         WHERE class = 1 AND major_id = OBJECT_ID(N'dbo.ReconciliarRestauracionSistema') AND minor_id = 0
                           AND name = N'GPOS_Version')), 0) <= 1
BEGIN
    EXEC (N'CREATE OR ALTER PROCEDURE dbo.ReconciliarRestauracionSistema …');   -- el texto de arriba
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 1 AND major_id = OBJECT_ID(N'dbo.ReconciliarRestauracionSistema') AND name = N'GPOS_Version')
        EXEC sys.sp_updateextendedproperty N'GPOS_Version', 1, N'SCHEMA', N'dbo', N'PROCEDURE', N'ReconciliarRestauracionSistema';
    ELSE
        EXEC sys.sp_addextendedproperty N'GPOS_Version', 1, N'SCHEMA', N'dbo', N'PROCEDURE', N'ReconciliarRestauracionSistema';
END
```

C usa la versión 2 con `<= 2`. Con la misma versión se recrea en cada arranque, así que D81-06 se mantiene.

#### 7.2.4 `SqlMarcaP7`

```sql
IF OBJECT_ID(N'dbo.MarcaDesbloqueoNcf', N'U') IS NULL
    CREATE TABLE dbo.MarcaDesbloqueoNcf (
        Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_MarcaDesbloqueoNcf PRIMARY KEY,
        EmpresaCodigo nvarchar(30) NOT NULL CONSTRAINT FK_MarcaDesbloqueoNcf_Empresas REFERENCES dbo.Empresas (Codigo),
        NodoId smallint NOT NULL CONSTRAINT CK_MarcaDesbloqueoNcf_Nodo CHECK (NodoId >= 1),
        Prefijo char(3) NOT NULL CONSTRAINT CK_MarcaDesbloqueoNcf_Prefijo CHECK (Prefijo LIKE '[BE][0-9][0-9]'),
        UltimoProbado bigint NOT NULL CONSTRAINT CK_MarcaDesbloqueoNcf_Ultimo CHECK (UltimoProbado >= 1),
        Origen varchar(13) NOT NULL CONSTRAINT CK_MarcaDesbloqueoNcf_Origen CHECK (Origen IN ('DESBLOQUEO', 'RECOMPOSICION')),
        ReconciliacionId int NOT NULL,            -- la reconciliación de la empresa que fijó el corte (en la recomposición, la de origen)
        ForkEmpresa uniqueidentifier NULL,        -- el fork de la base de empresa en esa reconciliación
        RegistradoUtc datetime2(3) NOT NULL CONSTRAINT DF_MarcaDesbloqueoNcf_Registrado DEFAULT (SYSUTCDATETIME()),
        RegistradoPor nvarchar(30) NOT NULL);     -- el SUPER, o SISTEMA en la recomposición del arranque
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_MarcaDesbloqueoNcf_Clave' AND object_id = OBJECT_ID(N'dbo.MarcaDesbloqueoNcf'))
    CREATE UNIQUE INDEX UX_MarcaDesbloqueoNcf_Clave ON dbo.MarcaDesbloqueoNcf (EmpresaCodigo, NodoId, Prefijo, UltimoProbado DESC)
        INCLUDE (Origen, RegistradoUtc);

-- I-9: la marca nunca baja. Sin UPDATE ni DELETE, y una fila nueva tiene que superar a la vigente (52008). Se recrean y se habilitan en cada
-- arranque (D81-06).
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_MarcaDesbloqueoNcf_SinCambios ON dbo.MarcaDesbloqueoNcf INSTEAD OF UPDATE, DELETE AS
    BEGIN SET NOCOUNT ON; THROW 52008, ''La marca del desbloqueo es de solo inserción y nunca baja.'', 1; END');
EXEC (N'CREATE OR ALTER TRIGGER dbo.TR_MarcaDesbloqueoNcf_SoloSube ON dbo.MarcaDesbloqueoNcf AFTER INSERT AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.MarcaDesbloqueoNcf m
                     ON m.EmpresaCodigo = i.EmpresaCodigo AND m.NodoId = i.NodoId AND m.Prefijo = i.Prefijo
                    AND m.Id <> i.Id AND m.UltimoProbado >= i.UltimoProbado)
            THROW 52008, ''La marca del desbloqueo es de solo inserción y nunca baja.'', 1;
    END');
EXEC (N'ENABLE TRIGGER dbo.TR_MarcaDesbloqueoNcf_SinCambios ON dbo.MarcaDesbloqueoNcf;');
EXEC (N'ENABLE TRIGGER dbo.TR_MarcaDesbloqueoNcf_SoloSube ON dbo.MarcaDesbloqueoNcf;');

-- Registro y recomposición: inserta solo si sube. Es idempotente: el reintento del mismo corte no inserta nada. La lectura con UPDLOCK, HOLDLOCK
-- toma el rango de la clave en el índice único: dos registros de la misma clave hacen fila.
EXEC (N'CREATE OR ALTER PROCEDURE dbo.RegistrarMarcaP7
    @EmpresaCodigo nvarchar(30), @NodoId smallint, @Prefijo char(3), @UltimoProbado bigint, @Origen varchar(13),
    @ReconciliacionId int, @ForkEmpresa uniqueidentifier, @RegistradoPor nvarchar(30)
WITH EXECUTE AS OWNER AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @EmpresaCodigo IS NULL OR @NodoId IS NULL OR @Prefijo IS NULL OR @UltimoProbado IS NULL OR @ReconciliacionId IS NULL
       OR @Origen IS NULL OR @Origen NOT IN (''DESBLOQUEO'', ''RECOMPOSICION'') OR ISNULL(LEN(@RegistradoPor), 0) = 0
        THROW 52009, ''Marca del desbloqueo con datos incompletos.'', 1;
    DECLARE @vigente bigint, @insertada bit = 0;
    BEGIN TRAN;
    SELECT @vigente = MAX(UltimoProbado) FROM dbo.MarcaDesbloqueoNcf WITH (UPDLOCK, HOLDLOCK)
     WHERE EmpresaCodigo = @EmpresaCodigo AND NodoId = @NodoId AND Prefijo = @Prefijo;
    IF @vigente IS NULL OR @UltimoProbado > @vigente
    BEGIN
        INSERT dbo.MarcaDesbloqueoNcf (EmpresaCodigo, NodoId, Prefijo, UltimoProbado, Origen, ReconciliacionId, ForkEmpresa, RegistradoPor)
        VALUES (@EmpresaCodigo, @NodoId, @Prefijo, @UltimoProbado, @Origen, @ReconciliacionId, @ForkEmpresa, @RegistradoPor);
        SELECT @insertada = 1, @vigente = @UltimoProbado;
    END
    COMMIT;
    SELECT @insertada AS Insertada, @vigente AS Vigente;
END');
```

- **Uso:**
  - **registro después de R3:** una llamada por prefijo con corte, con `Origen = 'DESBLOQUEO'`;
  - **recomposición:** la misma llamada con `'RECOMPOSICION'`, por cada fila de la consulta de cortes (§4), y solo inserta si sube.
- El servicio registra `MARCA_P7_RECOMPUESTA` en `BitacoraSeguridad` solo si alguna llamada devolvió `Insertada = 1`.
- **Parámetros:** `@Prefijo` con `SqlDbType.Char, 3`; los demás con el tipo de su columna.
- **52009** es el error de A para los datos incompletos. **52008**, para la marca inmutable.
- **Por qué una llamada por prefijo** y no un parámetro de tabla ni JSON: con uno a diez prefijos por empresa es lo más simple. Evita un `CREATE TYPE`, que no admite `ALTER`, y no depende del nivel de compatibilidad (`OPENJSON`). La atomicidad entre prefijos no hace falta, porque cada inserción es monótona por sí misma.

#### 7.2.5 `SqlRespaldoPosterior`

```sql
IF OBJECT_ID(N'dbo.RespaldoPosterior', N'U') IS NULL
    CREATE TABLE dbo.RespaldoPosterior (
        Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_RespaldoPosterior PRIMARY KEY,
        Origen varchar(12) NOT NULL CONSTRAINT DF_RespaldoPosterior_Origen DEFAULT ('DESBLOQUEO')
            CONSTRAINT CK_RespaldoPosterior_Origen CHECK (Origen IN ('DESBLOQUEO')),
        EmpresaCodigo nvarchar(30) NOT NULL CONSTRAINT FK_RespaldoPosterior_Empresas REFERENCES dbo.Empresas (Codigo),
        ReconciliacionId int NOT NULL,
        BaseDatos nvarchar(128) NOT NULL,           -- nombre de la base (la de la empresa o GPOS_SYSDATA); nunca la cadena de conexión
        EsSistema bit NOT NULL,
        Estado char(1) NOT NULL CONSTRAINT DF_RespaldoPosterior_Estado DEFAULT ('P')
            CONSTRAINT CK_RespaldoPosterior_Estado CHECK (Estado IN ('P', 'E', 'C', 'F')),
        Intentos tinyint NOT NULL CONSTRAINT DF_RespaldoPosterior_Intentos DEFAULT (0)
            CONSTRAINT CK_RespaldoPosterior_Intentos CHECK (Intentos BETWEEN 0 AND 10),
        Archivo nvarchar(400) NULL,                 -- ruta completa en InstanceDefaultBackupPath (devops la toma de aquí)
        SolicitadoUtc datetime2(0) NOT NULL CONSTRAINT DF_RespaldoPosterior_Solicitado DEFAULT (SYSUTCDATETIME()),
        SolicitadoPor nvarchar(30) NOT NULL,
        IniciadoUtc datetime2(0) NULL,
        TerminadoUtc datetime2(0) NULL,
        Error nvarchar(400) NULL,                   -- texto neutro, sin rutas de red ni credenciales
        CONSTRAINT CK_RespaldoPosterior_Datos CHECK ((Estado = 'C' AND Archivo IS NOT NULL AND TerminadoUtc IS NOT NULL)
                                                  OR (Estado = 'E' AND IniciadoUtc IS NOT NULL)
                                                  OR Estado IN ('P', 'F')));
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_RespaldoPosterior_Pedido' AND object_id = OBJECT_ID(N'dbo.RespaldoPosterior'))
    CREATE UNIQUE INDEX UX_RespaldoPosterior_Pedido ON dbo.RespaldoPosterior (EmpresaCodigo, ReconciliacionId, BaseDatos);
```

**Transiciones** (el SQL lo escribe el backend):

| Transición | Sentencia |
|---|---|
| Encolar | `INSERT … SELECT … WHERE NOT EXISTS` sobre `UX_RespaldoPosterior_Pedido` (idempotente) |
| Tomar | `UPDATE TOP (1) … WITH (READPAST) SET Estado = 'E', IniciadoUtc = SYSUTCDATETIME(), Intentos = Intentos + 1 OUTPUT inserted.* WHERE Estado = 'P' OR (Estado = 'E' AND IniciadoUtc < DATEADD(minute, -30, SYSUTCDATETIME()))`. La segunda condición recoge las filas que quedaron en `E` si la API murió en medio de un respaldo, o las que vinieron dentro de un `GPOS_SYSDATA` restaurado |
| Terminar | `UPDATE … SET Estado = 'C', Archivo = @archivo, TerminadoUtc = … WHERE Id = @id AND Estado = 'E'` |
| Fallar | `UPDATE … SET Estado = CASE WHEN Intentos >= 3 THEN 'F' ELSE 'P' END, Error = @error WHERE Id = @id AND Estado = 'E'` |
| R4 | `UPDATE … SET Estado = 'P', Intentos = 0, Error = NULL WHERE EmpresaCodigo = @e AND ReconciliacionId = @ultima AND Estado = 'F'` |

**`BACKUP` de `GPOS_SYSDATA`:** la fila propia se cierra **después** del `BACKUP`, así que dentro del `.bak` queda en `E`. Si ese respaldo se restaura, la regla de los 30 min la vuelve a tomar y hace otro respaldo. Es inocuo: solo usa disco.

#### 7.2.6 Reversión de `GPOS_SYSDATA`

Las tablas y los procedimientos son aditivos: una API anterior los ignora. Solo con una decisión firmada, como la regla 8 de H-11 y [C81] §7.2:

```sql
DROP PROCEDURE IF EXISTS dbo.RegistrarMarcaP7, dbo.LiberarCandadoRestauracion, dbo.ReconciliarRestauracionSistema;
DROP VIEW IF EXISTS dbo.EstadoRestauracionSistema;
DROP TABLE IF EXISTS dbo.RespaldoPosterior, dbo.MarcaDesbloqueoNcf, dbo.RestauracionSistema;   -- DROP no dispara INSTEAD OF DELETE
-- BitacoraSeguridad no se borra: es de C (fase A) y su reversión está en [C81-D] §7.3.
```

**Una instalación con el candado no vuelve a un paquete sin él:** se perdería la marca P-7, y con ella la protección de R-D1.

### 7.3 Cómo se versiona `GPOS_SYSDATA` (punto 3 del encargo)

**Verificado:**
- **No hay número de versión ni tabla de historial.** Al arrancar, la API ejecuta tres cosas en orden:
  1. `EnsureCreatedAsync` (`src/GPOS.Api/Servicios/Inicializacion.cs:17`);
  2. `AsegurarOpcionesSistemaAsync` (DM-04, `:18`);
  3. **un solo lote idempotente**, `EsquemaSistema.ActualizarAsync` (`:19`; `EsquemaSistema.cs:46-150`), con `IF COL_LENGTH … IS NULL` e `IF OBJECT_ID … IS NULL`.
- **ADR-38** prevé llevarlo a un comando de migración aparte (`CLAUDE.md`, «Acceso multiempresa»). [C81-D] §9 lo llama M-4 y lo asocia a RG-14: con RG-14, la API ya no tiene `ALTER`.

**Decisión: se sigue el mecanismo actual, sin tabla de versión.**
- **Lo nuevo:**
  - las cuatro constantes de §7.2, en un `partial` aparte;
  - todo idempotente (`IF OBJECT_ID … IS NULL` para tablas e índices; `CREATE OR ALTER` y `ENABLE` en `EXEC` para el código);
  - la guarda de versión por objeto **solo** en `ReconciliarRestauracionSistema` (PD-Q4).
- *Alternativa descartada:* una tabla `dbo.EsquemaSistemaVersion` con migraciones numeradas. Es la tarea M-4 de ADR-38, cuesta unas 0,3 sp [I] y cambia el arranque de todos los equipos en medio de dos ramas que tocan `EsquemaSistema.cs`. No hay ningún riesgo de hoy que la justifique.
- **PF-30 de [C81]** (base nueva frente a base existente, mismo esquema) se amplía a los objetos de A: PDS-20.

---

## 8. Respaldo, restauración y retención

| Dato | Retención | Volumen [I] | Motivo |
|---|---|---|---|
| `MarcaDesbloqueoNcf` | **Sin purga** | < 1 KB por desbloqueo | Es soporte del control fiscal (como `sync.Reconciliacion*`, 10 años) y no pesa |
| `RespaldoPosterior` | Sin purga | ≈ 300 B por desbloqueo (2 filas) | Rastro de qué respaldo cubre qué desbloqueo |
| `RestauracionSistema` | 1 fila | — | — |
| `BitacoraSeguridad` | 2 años (disparador de C) | ≤ 40 MB ([C81-D] §8) | — |
| `.bak` del respaldo posterior | **Devops:** como mínimo, hasta el siguiente respaldo completo **verificado** de la cadena del cliente **que sea posterior al desbloqueo**, y siempre con copia fuera del equipo | 2 completos por desbloqueo: la empresa (de 0,5 a 10 GB con Express [I]) y `GPOS_SYSDATA` (de 50 a 300 MB, por el padrón de RNC [I]) | El desbloqueo es raro: el disco es el de los respaldos de devops. **USD 0** |

**Restauración (cómo actúa cada base):**
- **Empresa:** el fork cambia, la vista y el disparador 51403 actúan de inmediato y el middleware actúa en ≤ 15 s.
- **`GPOS_SYSDATA`:** el fork cambia. `ReconciliarRestauracionSistema` cierra las sesiones una sola vez por fork; el SUPER revisa y libera; al liberar se recomponen las marcas (P-81A-12).
- **Las dos a la vez, desde respaldos anteriores al último desbloqueo:** la marca no se puede recomponer. Es el residual R-11 de [SW], aceptado hasta H-14. El respaldo posterior de las dos bases lo reduce.

**Opciones de base:** DM-04 ya fija `AUTO_CLOSE OFF` en `GPOS_SYSDATA` (`EsquemaSistema.cs:26-44`) [V]. No hay nada nuevo.

**`RESTORE VERIFYONLY` en producción:** no lo ejecuta la API, porque exige `CREATE DATABASE` en el servidor [I] y eso sobra para su cuenta. `CHECKSUM` en el `BACKUP` detecta páginas dañadas al escribir. La verificación la hace devops (Backup Tool), y en las pruebas, PDS-17.

---

## 9. Privilegios de base de datos

### 9.1 Base de empresa (en la migración)

```sql
GRANT BACKUP DATABASE TO gpos_app;   -- DD-13: solo completos; no BACKUP LOG (no se toca la cadena de registro del cliente)
```

- **Sin `DENY` nuevos.** Se mantienen los de H-11 sobre `ReconciliacionChequera` (`UPDATE` y `DELETE`, `SqlMigracionesH11.cs:258`) [V].
- **Disparador a prueba de la aplicación:** `gpos_app` no tiene `ALTER` sobre el esquema `doc` (`SqlMigraciones.cs:35`, solo `SELECT, INSERT, UPDATE, DELETE`) [V], así que no puede hacer `DISABLE TRIGGER`. Hasta RG-14, la cuenta real de la API tiene permisos amplios: es el riesgo aceptado A-09 y R-06 de [C81].
- **`gpos_respaldo`** (`db_backupoperator`, `SqlMigraciones.cs:28,49`) [V] queda para Backup Tool, sin cambios.

### 9.2 `GPOS_SYSDATA` (con RG-14; hoy la API tiene permisos amplios)

Se suman a los de [C81] §7.4 y [C81-D] §9 (`<usuario_api>` es un marcador, sin secretos):

```sql
-- Bloque A (C): GRANT SELECT, INSERT ON dbo.BitacoraSeguridad; DENY UPDATE, DELETE, ALTER ON dbo.BitacoraSeguridad.
-- Bloque B:
GRANT SELECT ON dbo.EstadoRestauracionSistema TO <usuario_api>;
GRANT EXECUTE ON dbo.ReconciliarRestauracionSistema TO <usuario_api>;
GRANT EXECUTE ON dbo.LiberarCandadoRestauracion TO <usuario_api>;
DENY INSERT, UPDATE, DELETE, ALTER ON dbo.RestauracionSistema TO <usuario_api>;
-- P-7:
GRANT SELECT ON dbo.MarcaDesbloqueoNcf TO <usuario_api>;
DENY INSERT, UPDATE, DELETE, ALTER ON dbo.MarcaDesbloqueoNcf TO <usuario_api>;   -- solo por RegistrarMarcaP7 (encadenamiento de propiedad dbo → dbo)
GRANT EXECUTE ON dbo.RegistrarMarcaP7 TO <usuario_api>;
-- Respaldo posterior:
GRANT SELECT, INSERT, UPDATE ON dbo.RespaldoPosterior TO <usuario_api>;
DENY DELETE, ALTER ON dbo.RespaldoPosterior TO <usuario_api>;
GRANT BACKUP DATABASE TO <usuario_api>;
-- Devops (Backup Tool) solo lee la cola:
GRANT SELECT ON dbo.RespaldoPosterior TO <usuario_backup_tool>;
```

- **Con RG-14,** el DDL de §7.2 (`CREATE OR ALTER`, `ENABLE TRIGGER` y la propiedad extendida) pasa al comando M-4, con una identidad de despliegue (nunca `gsf` ni `sa`; ADR-44). La API deja de recrear los disparadores al arrancar. Hasta entonces sigue D81-06.
- **El `BACKUP` de las bases de empresa** lo hace la API con la conexión de cada empresa. Con RG-14, cada base necesita el `GRANT` de §9.1 para el usuario de la API.

---

## 10. Riesgos

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-D11 | El disparador 51403 pasa de +0,03 ms por venta | Media / medio | DD-10 ya quita la segunda lectura. PDS-06 lo mide; si se pasa, se aplica el plan de reserva de §7.1.3 |
| R-D12 | Una migración de datos futura sobre `doc.Documento` no deshabilita el disparador, y una base restaurada deja de poder actualizarse | Media / medio | Guarda estática PDS-12; regla escrita en el comentario del disparador; se entrega a H-2 |
| R-D13 | **Restaurar un respaldo de `GPOS_SYSDATA` anterior a esta versión** (sin `RestauracionSistema`): la primera reconciliación registra el fork y **no activa el candado** (falla abierta) | Baja (hoy no hay clientes; todo respaldo de un cliente será posterior) / alto | PD-Q6: aceptarlo y documentarlo en la guía de devops. *Alternativa descartada:* leer `msdb.dbo.restorehistory`, que exige permisos en `msdb` que la API no debe tener |
| R-D14 | Deriva del texto de `ReconciliarRestauracionSistema` entre árboles que comparten el mismo `GPOS_SYSDATA` | Media en desarrollo / bajo | Guarda de versión (PD-Q4, §7.2.3) |
| R-D15 | Pruebas actuales que preparan documentos después de simular una restauración ahora reciben 51403 en lugar de pasar | Media / calendario | QA corre `ModeloNg` completo con el filtro oficial y ajusta la preparación (antes de `RestaurarAsync`) |
| R-D16 | Pruebas de H-11 que desbloquean con cuentas que tienen chequera (por ejemplo, la de S-02 en `DesbloqueoRestauracionTests.cs:369`) [V] fallarán por C9 si no envían las chequeras | Alta / calendario | El backend amplía `Pedido(...)` de las pruebas con las chequeras |
| R-D17 | `sys.database_recovery_status` no es visible en `GPOS_SYSDATA` para un usuario con RG-14 | Baja / alto | PDS-16; plan de reserva con una función `EXECUTE AS OWNER` (+0,03 sp) |
| R-D18 | **La migración en sí** | Baja / bajo | Menos de 1 s, sin pérdida de datos. La previa y el `Down` usan 51399 |
| R-D19 | El `.bak` queda sin cifrar en `InstanceDefaultBackupPath` | La exposición ya existe hoy con «Respaldar ahora» ([SW] §8) | Devops: custodia y copia cifrada fuera del equipo |

---

## 11. Pruebas de datos

En `tests/GPOS.Tests/ModeloNg/CandadoRestauracionTests.cs`, `MarcaP7Tests.cs` y `RestauracionSistemaTests.cs`. Las bases son `GPOS_TEST_H11B_*` y `GPOS_TEST_SYS_*`, **nunca el `GPOS_SYSDATA` real**. Las suites se corren con el filtro oficial y nunca dos completas a la vez.

**La restauración real** se hace con el patrón de `DesbloqueoRestauracionApiTests.cs:191-200` [V]: `BACKUP … COPY_ONLY` → actividad → `SINGLE_USER WITH ROLLBACK IMMEDIATE` → `RESTORE … WITH REPLACE` → `MULTI_USER` → `ClearPool`, con los reintentos 924, 3101 y 5061.

| Id | Caso | Esperado |
|---|---|---|
| PDS-01 | `Up`, `Down` y `Up` de `H11CandadoChequeras` con el **nombre fijo**. `Down` con una fila con `Referencia`. El guion regenerado comparado con el anterior en el tramo de H-11 | Sin diferencias de esquema entre los dos `Up`. Con datos, `Down` da 51399 y no cambia nada. El tramo de H-11 queda idéntico |
| PDS-02 | **Restauración real de la base de empresa** y luego, como `gpos_app`: `INSERT` de un borrador, `UPDATE` de notas, `DELETE` de un borrador y anulación (1 → 2) | 51403 en los cuatro, y nada cambia |
| PDS-03 | En la misma base restaurada: emisión 0 → 1 de un borrador creado antes de restaurar | **51330**, no 51403 (DD-10) |
| PDS-04 | Bloqueo `MANUAL` con el fork igual: alta de borrador | Pasa (DD-9). La emisión da 51330 |
| PDS-05 | En la base restaurada, como `gpos_app`: la reimpresión (`doc.Impresion`, `doc.Autorizacion` y bitácora), el alta de una secuencia NCF y «Respaldar ahora» | Pasan los tres |
| PDS-06 | Rendimiento: 8.2 (5) de `Ola4AplicacionEmision` antes y después, más una microprueba de 1.000 altas de borrador | 8.2 (5) ≤ 0,55 ms; ≤ +0,03 ms por venta |
| PDS-07 | C9, rompiendo una regla por vez: falta una cuenta; la chequera no se actualizó; el confirmado es menor que el local; el confirmado es igual al último cheque; `UltimoEmitido` no coincide; la referencia tiene 4 caracteres | 51329 «C9». Todo se deshace: `EstadoNodo`, bloques, series, chequeras y bitácora |
| PDS-08 | C9 con `TRASLADO` sin filas de chequera, y con una sola fila | El primero pasa; el segundo da 51329 «C9» si falta otra cuenta |
| PDS-09 | Concurrencia: R3 con la chequera bloqueada por un pago con cheque sin número que ya tomó `GPOS.Chequera:` | Sin interbloqueo. R3 espera, y el pago termina o falla por la guarda |
| PDS-10 | Desbloqueo completo con chequeras: después, el primer cheque sin número | Toma `SiguienteConfirmado` |
| PDS-11 | `CHECK` de la columna nueva: `INSERT` directo con un confirmado que retrocede, o con una referencia de 3 caracteres | 547 |
| PDS-12 | **Guarda estática:** toda clase `SqlMigraciones*` de una migración **posterior** a `H11CandadoChequeras` que contenga `UPDATE doc.Documento` o `DELETE FROM doc.Documento` contiene también `DISABLE TRIGGER doc.TR_Documento_Candado` | Pasa hoy, porque no hay ninguna |
| PDS-13 | La prueba de disparadores declarados (`NucleoTransaccionalNgTests.cs:85`) | Incluye `TR_Documento_Candado` |
| PDS-14 | **`GPOS_SYSDATA` desde cero** (`EnsureCreated` + `EsquemaSistema` en `GPOS_TEST_SYS_*`), y el arranque repetido | Una fila en `RestauracionSistema`, `Restaurada = 0`. El segundo arranque no cambia nada |
| PDS-15 | **Restauración real de `GPOS_SYSDATA`:** respaldo → alta de un usuario y de un dispositivo, y una sesión abierta → `RESTORE` → `ReconciliarRestauracionSistema` dos veces | La primera, `Reconcilio = 1`, con `SesionId` nulo y `SesionesRevocadas` puesta en todas las filas y **un** `SISTEMA_RESTAURADO`. La segunda, `0`. `Restaurada = 1` y `Reconciliada = 1` |
| PDS-16 | Lo mismo como un usuario sin login con **solo** los permisos de §9.2 (`EXECUTE AS USER`) | La vista se lee y el fork no es nulo; los procedimientos corren. Un `UPDATE` directo de `RestauracionSistema` o de `MarcaDesbloqueoNcf` da 229 |
| PDS-17 | `LiberarCandadoRestauracion`: con el fork equivocado, **con `NULL`**, con un no SUPER, con un motivo de 9 caracteres, el caso correcto y luego otra vez | 52004, **52004** (DD-16), 52007, 52006, liberación con `CANDADO_RESTAURACION_LIBERADO`, y 52005 |
| PDS-18 | **Dos restauraciones seguidas del mismo respaldo** | El fork cambia cada vez [I] y hay una reconciliación por fork |
| PDS-19 | Marca P-7: `RegistrarMarcaP7` con 150 (inserta), 150 (no), 140 (no) y 160 (inserta). `INSERT` directo de 155, `UPDATE`, `DELETE`. `DISABLE TRIGGER` y nuevo arranque | `Insertada` 1, 0, 0 y 1. Después: 52008, 52008 y 52008; el disparador vuelve a quedar habilitado |
| PDS-20 | Igualdad de esquema (PF-30 ampliada): base nueva frente a base existente | Mismas tablas, `CHECK`, `DEFAULT`, índices y disparadores habilitados para los objetos de A |
| PDS-21 | **P-81A-12 de punta a punta:** desbloqueo de la empresa (marca 150) → restauración de `GPOS_SYSDATA` desde un respaldo previo (sin marca) → recomposición con la consulta de §4 y `RegistrarMarcaP7` → liberación | Marca 150 con `RECOMPOSICION` y `MARCA_P7_RECOMPUESTA`. Recomponer otra vez no inserta nada |
| PDS-22 | `RespaldoPosterior`: encolar dos veces la misma reconciliación; una fila en `E` con 31 min de antigüedad; tres fallos seguidos | Una sola fila por base; la fila vieja se vuelve a tomar; al tercer fallo queda en `F` |
| PDS-23 | Los dos `.bak` del respaldo posterior | `RESTORE VERIFYONLY … WITH CHECKSUM` pasa (la prueba corre con un login con privilegios) |

---

## 12. Entregas y coordinación con C

- **Errores:**
  - **51403** (base de empresa) queda asignado. Hay que **retirar 51391 y 51392** del blueprint de A.
  - **52008** (marca inmutable) y **52009** (marca con datos incompletos) son de A, dentro de la reserva 52001-52019 (`ADR-081.md:76`) [V].
  - C conserva 52001 a 52007 (de los cuales A implementa 52001, 52002 y 52003 a 52007) y 52010 a 52019.
- **A C (por medio de B):**
  - DD-16, la corrección de `LiberarCandadoRestauracion` (`@ForkEsperado IS NULL`);
  - los `ENABLE TRIGGER` en `EXEC`;
  - la guarda de versión de `ReconciliarRestauracionSistema` (A = 1, C = 2; PD-Q4);
  - el `partial` `EsquemaSistema.Restauracion.cs`, para que C agregue sus bloques al lado.

---

## 13. Preguntas

| # | Para | Pregunta | Recomendación y costo [I] | Por omisión |
|---|---|---|---|---|
| **PD-Q1** | Coordinación (B) y documentador | Confirmar el **51403** en lugar del 51391 (que está reservado por ADR-78) | Es un cambio técnico, no requiere firma. 0 sp | 51403 |
| **PD-Q2** | Propietario, con el especialista-pos | ¿P-3 cubre (a) solo las cuentas que tienen fila en `banco.Chequera`, como dice [SW], o (b) **también las cuentas habilitadas sin chequera**? Con (a) puede pasar esto: una cuenta cuya chequera se creó **después** del respaldo no tiene fila en la base restaurada, así que P-3 la salta, y el primer cheque sin número sale con `MAX(cheques de la base) + 1`, que puede **repetir** un cheque ya emitido | **(b).** Cierra ese hueco. Cuesta una o dos filas más en la pantalla y +0,03 sp (el `INSERT` de 7b(a) y una línea de C9a) | (b) |
| **PD-Q3** | Propietario | Con la causa `TRASLADO`, ¿se confirman las chequeras? | Con el criterio de C6: solo si hay alguna fila, y entonces todas. 0 sp | Ese criterio |
| **PD-Q4** | Coordinación con C | Guarda de versión por propiedad extendida en `ReconciliarRestauracionSistema` | Sí. Evita que un árbol viejo deshaga el texto de C en el `GPOS_SYSDATA` compartido de desarrollo. +0,02 sp | Sí |
| **PD-Q5** | Propietario | Llave foránea de `MarcaDesbloqueoNcf` y `RespaldoPosterior` hacia `Empresas`: una empresa con historia de desbloqueos **no se puede eliminar** (solo inhabilitar) | Sí: es la regla «eliminar solo sin referencias; si se transaccionó, inhabilitar». 0 sp | Sí |
| **PD-Q6** | Propietario | Restaurar un `GPOS_SYSDATA` anterior a esta versión no activa el candado (R-D13) | Aceptarlo y documentarlo en la guía de devops. Hoy no hay respaldos de clientes | Aceptar |

---

## 14. Esfuerzo [I], ±40 %

Es la parte de datos dentro de las 2,4 sp de [SW] §14. No se suma a esa cifra, salvo la última fila.

| Parte | sp |
|---|---|
| Migración `H11CandadoChequeras`: disparador, C9, columna, `CHECK`, permiso, refactorización de H-11, `Down` y guion regenerado | 0,15 |
| `GPOS_SYSDATA`: los 4 bloques, la corrección DD-16 y la guarda de versión | 0,12 |
| Pruebas de datos PDS-01 a PDS-23, con dos restauraciones reales (empresa y sistema) | 0,15 |
| **Subtotal (incluido en [SW])** | **0,42** (de 0,25 a 0,6) |
| **Agregado por este diseño:** PD-Q2 (b) +0,03, guarda de versión +0,02, guarda estática PDS-12 +0,02 | **+0,07** |
| Si fallan PDS-06 o PDS-16 (planes de reserva) | +0,03 a +0,05 |

**Costo:** USD 0 de infraestructura. El disco de los respaldos posteriores es el de devops: 2 completos por desbloqueo, que es un evento raro.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\datos-h11-p7-candado-2026-10-10.md`
- Supuestos:
  - (1) `recovery_fork_guid` cambia con cada `RESTORE … WITH RECOVERY`, también cuando se restaura dos veces el mismo respaldo (PDS-18);
  - (2) `sys.database_recovery_status` es visible en `GPOS_SYSDATA` para un usuario con los permisos mínimos, como en la base de empresa (PDS-16);
  - (3) la lectura del sitio cuesta unos 19 µs (H0, 6.1) y el despacho de un disparador, de 3 a 8 µs;
  - (4) `THROW` con `XACT_ABORT ON` deshace la transacción del procedimiento;
  - (5) en las bases reales, `sync.ReconciliacionChequera` está vacía;
  - (6) `ExecuteSqlRawAsync` podría interpretar llaves en el texto;
  - (7) `RESTORE VERIFYONLY` exige `CREATE DATABASE`.
- Decisiones candidatas a ADR (como precisiones de ADR-53, cláusula 9, y de ADR-81):
  - DD-7: 51403 para el candado de empresa, y 51391 y 51392 retirados;
  - DD-8 a DD-11: el disparador aparte, su condición (solo `RESTAURACION`), sin segunda lectura en la emisión, y también `DELETE`;
  - DD-12: C9 valida el contenido;
  - DD-13: `GRANT BACKUP DATABASE` en lugar de `db_backupoperator`;
  - DD-14: «solo sube» garantizado en la base;
  - DD-15: sin índice de estado;
  - DD-16: la corrección de `LiberarCandadoRestauracion`;
  - `GPOS_SYSDATA` sigue sin tabla de versión hasta M-4.
- Entregas a otros agentes:
  - **desarrollador-backend** → §6, §7.1 y §7.2, las consultas de §4, la traducción de 51403, el `partial` de `EsquemaSistema`, la refactorización de H-11 y las pruebas de H-11 con chequeras (R-D16);
  - **qa** → PDS-01 a PDS-23 y la corrida completa de `ModeloNg` (R-D15);
  - **especialista-pos** → PD-Q2 y PD-Q3;
  - **devops** → los permisos de §9 con RG-14, la retención y la copia fuera del equipo de los `.bak` (§8), R-D13 en la guía y la lectura de `RespaldoPosterior` desde Backup Tool;
  - **auditor-seguridad** → §9, DD-16, el disparador 51403 y la falla abierta de R-D13;
  - **equipo C (por medio de B)** → §12;
  - **arquitecto-maestro / B** → PD-Q1 a PD-Q6;
  - **documentador-tecnico** → registrar 51403, 52008 y 52009, y retirar 51391 y 51392 del registro de A.
- Próximo paso recomendado: que el backend construya primero PDS-02, PDS-06 y PDS-16 (restauración real, rendimiento y permisos mínimos), porque deciden si hacen falta los planes de reserva.
