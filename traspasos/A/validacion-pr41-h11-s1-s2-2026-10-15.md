# Validación del arquitecto: PR #41 (H-11, S-1 y S-2)

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A.
- **Qué revisé:** PR #41, rama `a/h11-s1-s2` @ `974cf675`, en el árbol `GPOS-NG-h11s`, en solo lectura: el cuerpo del PR, `ConsultasRestauracionSistema.cs` y `RespaldosPosteriores.cs`. No compilé ni ejecuté pruebas.
- **Contra qué lo contrasté:** la sección A de `validacion-rg14-lote2b-y-s1-2026-10-15.md` (S-1) y la adenda de `validacion-h11-500-pool-2026-10-15.md` (S-2).

## Dictamen: **Aprobado con observaciones. Nada bloquea la unión**

S-2 cumple la adenda: `ForkActual` y `DetectadaEn` en la clave de 5 columnas, `Id DESC` para R1 y R4, y sin migración de la base de empresa. S-1 cumple el texto: la excepción con tipo se lanza en la apertura, el manejador responde 503 con `Retry-After` y los trabajos usan un pool propio.

| # | Pregunta | Dictamen | ¿Bloquea? |
|---|---|---|---|
| 1 | La prueba de S-1 ocupa las conexiones ella misma con `Max Pool Size = 1`, en lugar de un trabajo esperando una base en `RESTORING` | **Basta para probar que la excepción se convierte en 503.** No prueba la otra mitad del remedio: que un trabajo **no** ocupe el pool de las peticiones. **Texto exacto de la prueba que falta:** con `Max Pool Size = 1` en la cadena de las peticiones, se mantiene abierta una conexión creada con `CadenaConexion.ParaTrabajo` y se pide R1, que tiene que responder **200**, no 503. A esto se suma una prueba unitaria que compruebe que `ParaTrabajo` cambia `Application Name` y que `Connect Timeout` vale 5. Con eso no hace falta reproducir el `RESTORING`, que es lento y propenso a carreras | No (secundaria; mejor en este PR) |
| 2 | Código 503 `ESTADO_CANDADO_NO_DISPONIBLE` | **Correcto**, y coincide con mi texto: «el código del estado no disponible que ya usa el candado». Reutilizarlo evita un código nuevo en los clientes. **Condición:** el texto que muestran la Web y MAUI para ese código tiene que ser genérico, por ejemplo «La base de la empresa no responde en este momento. Intente de nuevo en unos segundos.», y no hablar del candado, porque ahora también lo reciben rutas de operación | No |
| 3 | ¿El fork entra en el detalle de la bitácora (`AuditarRespaldo`)? | **Sí, hay que agregarlo.** Hoy el detalle es `{ reconciliacion, archivo }` (`RespaldosPosteriores.cs:123-128` [V]), y `EntidadId` es el número de reconciliación, **que se repite después de una restauración**: es justo el problema que resuelve S-2. **Texto exacto:** el detalle pasa a `{ reconciliacion, fork, detectadaEn, archivo }`, con `fork` como GUID en minúsculas y `detectadaEn` en ISO 8601 UTC. Así cada línea de la bitácora de la empresa se puede atribuir a un solo pedido | No (secundaria; ≈ 0,02 dp, mejor en este PR) |
| 4 | P-9 (reverso) como guion manual | **Aceptado, con condiciones.** `GPOS_SYSDATA` no usa migraciones de EF: se actualiza con DDL idempotente y una marca que solo sube, así que el reverso lo ejecuta un administrador. **Condiciones:** (a) el guion queda **como archivo en el repositorio**, por ejemplo `database/sistema/reverso-h11-s2.sql`, no solo descrito; (b) antes de rehacer el índice único de 3 columnas, comprueba si hay filas con la misma (empresa, reconciliación, base) y distinto fork u hora, y **se detiene** si las hay, porque no se pueden borrar pedidos sin decisión humana; (c) baja la marca `GPOS.EsquemaSistema` a 2 de forma explícita; (d) QA lo ejecuta una vez sobre una base de prueba | No (antes de cerrar H-11) |
| 5 | Hallazgo inferido: EF y una `SqlConnection` directa con la misma cadena usan pools distintos | **Plausible, sin efecto de seguridad.** El pool de SqlClient se identifica por el **texto exacto** de la cadena (más la identidad). Si EF recibe una cadena con otro texto (otro orden u otra normalización), arma un pool aparte [I]. **Consecuencias:** cada empresa puede tener hasta 2 × `Max Pool Size` conexiones, lo que SQL Server Express admite, y una prueba con `Max Pool Size = 1` tiene que ocupar los dos pools, como ya hace esta. **Seguimiento:** comprobar en una prueba si los textos coinciden. Si no coinciden, hacer que todas las cadenas salgan normalizadas de `CadenaConexion` (`SqlConnectionStringBuilder.ConnectionString`) y que EF y la conexión directa usen la misma | No |

## Correcciones (todas secundarias)

1. La prueba de que el pool de los trabajos está separado del de las peticiones (punto 1).
2. `fork` y `detectadaEn` en el detalle de `AuditarRespaldo` (punto 3).
3. El guion P-9 como archivo, con la comprobación de duplicados y la marca (punto 4).
4. Un texto genérico para `ESTADO_CANDADO_NO_DISPONIBLE` en los clientes (punto 2).
5. Comprobar el texto de la cadena de EF y de la conexión directa (punto 5).

### Cierre
- Estado: Aprobado con observaciones.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-pr41-h11-s1-s2-2026-10-15.md`.
- Supuestos: el punto 5 es una inferencia sobre cómo SqlClient forma la clave del pool, no está verificado.
- Decisiones candidatas a ADR: ninguna.
- Entregas a otros agentes:
  - **desarrollador-backend (A):** correcciones 1 a 3 y 5, preferiblemente en este PR;
  - **desarrollador-frontend:** corrección 4;
  - **qa-automatizado:** ejecutar el guion P-9.
- Próximo paso recomendado: aplicar las correcciones 1 a 3 y unir #41.
