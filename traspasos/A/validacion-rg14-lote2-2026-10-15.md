# Validación del arquitecto: desviaciones del PR #36 (RG-14, lote 2, desarrollador I)

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A.
- **Qué revisé:** rama `a/rg14-lote2` @ `ac4b9489`, en el árbol `GPOS-NG-rg14l2`, solo en lectura. Leí el cuerpo del PR y los archivos `RespaldoCopia.cs`, `SqlMigracionesRg14Lote2.cs`, `PrivilegioMinimoSistema.cs`, `ExtensionesEsquemaSistema.cs` y los cambios de `EsquemaSistema.cs`, `RespaldoService.cs` y `EmpresasService.cs`. No compilé ni ejecuté pruebas.
- **Contra qué lo contrasté:**
  - `datos-t3-12-rg14-2026-10-14.md` (`[DAT]`): S1, D-05, D-07, PA-27, PA-30, R-RG14-09 y la tabla de esfuerzo de la línea 1114;
  - `datos-licencia-l1a4-2026-10-14.md` §1.3 (orden de `GPOS.Migracion sistema`);
  - el blueprint de la licencia v2.9;
  - SEG-RG14-05 (`revision-seguridad-pr28-rg14-lote1-2026-10-14.md`).

## Dictamen: **Aprobado con observaciones. Una corrección bloquea la unión (la 5)**

| # | Desviación | Dictamen | ¿Bloquea? |
|---|---|---|---|
| 1 | Tope de 12 respaldos por hora y por base, en lugar de «1 cada N minutos» (51608) | **El tope por ventana es correcto; la cifra no.** El tope tiene que permitir «Respaldar ahora» seguido del respaldo posterior de H-11 y sus reintentos, y eso se cumple con un límite por hora. Pero 12 por hora dan 288 respaldos completos al día por base, y eso no protege el disco, que era el objetivo de SEG-RG14-05. **Texto exacto:** como mucho **4 por hora y 12 por día** por base. Cuentan los respaldos `COPY_ONLY` con nombre `GPOS - %` de `msdb.dbo.backupset`. Las dos condiciones dan 51608. Además, la ruta `POST /api/admin/respaldos` lleva su propio límite (1 cada 10 minutos por empresa y uno a la vez; validación de L1b-1, LB-06) | No (secundaria; el auditor la calificó Baja) |
| 2 | D-05 vuelve a fijar el `DENY BACKUP DATABASE` en la migración nueva, sin reescribir el `Down` de Rg14 | **Confirmado.** Un permiso tiene un solo estado por principal: el `DENY` ya sustituía al `GRANT` de H-11, y repetirlo cubre una base en la que se haya aplicado el reverso. El `Down` de Rg14 devuelve el `GRANT` porque ese reverso desarma RG-14 entero (B ya lo aceptó). Revertir esas migraciones supone revertir también el código, que en ese momento ya no llama a `BACKUP` directamente | No |
| 3 | S1 agrega `DENY` sobre `LatidoNumeracion` | **Confirmado.** Es endurecimiento coherente con el patrón de S1: la API escribe esa tabla solo con `EXEC dbo.RegistrarLatidoNumeracion` y la lee con `SELECT` (`ConsultasRestauracionSistema.cs:17,24` [V]), y el procedimiento y la tabla tienen el mismo dueño (encadenamiento de propiedad). Se suma a la lista de S1 en `[DAT]` como precisión | No |
| 4 | «Respaldar ahora» cambia el nombre del archivo | **Confirmado.** Con D-05 (firmada), la ruta y el nombre los fija el servidor: `{base}_AHORA_{fecha}_{hora UTC}.bak`. **Secundario:** (a) la hora del nombre es UTC, cuatro horas por delante de la de RD; hay que decirlo en la ayuda o en el mensaje de la pantalla; (b) con `EXECUTE AS OWNER`, la columna `Usuario` del historial (`backupset.user_name`) muestra al dueño del procedimiento y no a quien pidió el respaldo. El historial tiene que mostrar `backupset.name` («GPOS - respaldo de {usuario}») o sacar al usuario de ahí | No |
| 5 | Tras rotar la credencial, una petición puede dar 500 antes de releer la cadena | **Corregir.** PA-30 de `[DAT]`, firmado, exige «ningún 500». **Texto exacto:** en el punto único donde se abre la conexión de la base de una empresa (la fábrica que usa `IConexionesEmpresa`), si `OpenAsync` falla con un **18456**, se llama a `Olvidar(empresa)`, se relee la cadena y se reintenta la apertura **una sola vez**. Si el reintento también falla, la excepción sigue su curso. Solo se reintenta la apertura, nunca un comando ni una transacción. **Prueba:** PA-30 completa con la API en marcha (rotar dos veces y comprobar que ninguna respuesta es 500) | **Sí** (≈ 0,1 dp; R-RG14-09) |
| 6 | Quedan fuera del PR: D-07, la empresa «pendiente de aprovisionar», el 503 por empresa en Estricto, `InstalacionId` y el sellado inicial | **Confirmado como corte del PR, con fechas.** El sellado inicial espera a DL-02 y está bien que quede fuera. **D-07, la empresa pendiente y el 503 son parte del lote 2 de `[DAT]`** (línea 1114): van en un PR **«lote 2b»** antes de PA-12 en Estricto (S9). **`InstalacionId`:** `[DAT]`:1022 y datos L1a-4 §1.3, paso 6, lo ponen en `GPOS.Migracion sistema`. En Estricto, sin él la API no arranca (L1a-4). Necesita el formato con MAC de L1a-4 (#33) y el anillo común (CR, #34). Se hace con un segundo enganche, `ExtensionesEsquemaSistema.TrasPermisos` (o equivalente), que L1a-4 llena con su generador. **Fecha:** antes de H-3 (11-13) | No bloquea #36. **Bloquea usar el modo Estricto** |
| 7 | Enganche `ExtensionesEsquemaSistema.Ddl` y `.Permisos` para `SqlLicenciaSistema` | **Confirmado.** El orden coincide con datos L1a-4 §1.3: DDL después de las tablas y antes de `rptsis`, en Amplio y en `sistema`; permisos solo en `sistema` y después de S1. **Precisión obligatoria:** el PR que agregue `SqlLicenciaSistema.Ddl` al enganche sube `EsquemaSistema.Version` (de 1 a 2). Si no, en Estricto la API arrancaría sobre una base sin `Licencias`. Que L edite una línea del enganche, que es archivo de I, es aceptable; se avisa en el PR | No (condición del rebase de #33) |

## Correcciones

| # | Qué | ¿Bloquea? |
|---|---|---|
| 1 | Reapertura única ante el 18456 (punto 5, PA-30) | **Bloquea la unión** |
| 2 | Tope de 4 por hora y 12 por día (punto 1) | Secundaria |
| 3 | Historial con el usuario tomado de `backupset.name` y aviso de la hora UTC en el nombre (punto 4) | Secundaria |
| 4 | PR «lote 2b»: D-07, empresa pendiente de aprovisionar y 503 por empresa en Estricto (punto 6) | Antes de PA-12 en Estricto |
| 5 | Enganche para `InstalacionId` en `sistema`, que llena L1a-4 (punto 6) | Antes de H-3 (11-13) |
| 6 | `EsquemaSistema.Version` sube a 2 al enganchar `SqlLicenciaSistema` (punto 7) | Condición del rebase de #33 |

### Cierre
- Estado: Aprobado con observaciones.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-rg14-lote2-2026-10-15.md`.
- Supuestos:
  - Revisé las desviaciones y los archivos citados, no todo el PR.
  - 12 respaldos al día es mi cifra: ajustarla si el tamaño de las bases lo exige.
- Decisiones candidatas a ADR: ninguna. Son precisiones de `[DAT]`, que está firmado (S1, D-05, PA-30).
- Entregas a otros agentes:
  - **desarrollador-backend (I):** correcciones 1 a 5;
  - **desarrollador-backend (L):** corrección 6 y el generador de `InstalacionId` en el enganche;
  - **arquitecto-datos:** sumar el `DENY` sobre `LatidoNumeracion` a S1 y el tope de 4 por hora y 12 por día a D-05;
  - **auditor-seguridad:** la cifra del tope (SEG-RG14-05).
- Próximo paso recomendado: aplicar la corrección 1 y rebasar #36 cuando B una #24, #26 y #28.
