```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Hallazgo (encargo «pruebas intermitentes», punto 2)
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng @ 322b21d6 (sin cambios de producción todavía)
Estado: Cerrado (B decidió corregir; entregado en el #79)
```

# Hallazgo: segunda conexión al mismo grupo dentro de `SaveChanges` (desde el #51)

## Qué pasa
- `LongitudesColumnas.ValidarAsync` y `Validar` (`src/GPOS.Core/Infraestructura/LongitudesColumnas.cs:58` y `:77`) corren dentro de `SaveChanges` de `EmpresaDbContext`.
- Si la caché de esa cadena está vacía, abren una `SqlConnection` nueva con `db.Database.GetConnectionString()`, **mientras la unidad de trabajo retiene la conexión y la transacción de EF** (`UnidadTrabajo.cs:109-116`).
- **Antes del #51** eran dos grupos distintos: EF agregaba `Application Name=EFCore/…`. **Desde el #51** (`CadenaConexion.SinBloqueoDelPool` fija `GPOS.Api`) **es el mismo grupo:** cada escritura en frío ocupa 2 conexiones del mismo grupo y retiene la primera hasta obtener la segunda.
- La caché está vacía tras arrancar la API, tras `LongitudesColumnas.Limpiar()` (`EsquemaEmpresa.cs:204`) y, en las pruebas, en **cada base de prueba nueva**. No hay una sola carga compartida: N escrituras concurrentes en frío abren N conexiones extra.
- Con el grupo ocupado se forma una espera circular: cada petición retiene una conexión en transacción y espera otra hasta el tiempo de conexión. El resultado es `InvalidOperationException` fuera del interceptor de reapertura, que **responde 500, no 503**. Coincide con el síntoma de F5 y CA_P7_06.

## Alcance en producción
- Es real, pero solo en la primera escritura de cada base tras el arranque o tras actualizar el esquema. Para trabarse hacen falta unas 100 escrituras concurrentes en frío, con el grupo de 100 por omisión. **Con los clientes de la entrega 1 es poco probable; en las ráfagas de la suite, sí pasa.**
- **Segundo caso, solo de administración:** `ImportacionesService.cs:126-135` retiene la unidad con transacción durante toda la importación, y `DiagnosticoEsperas.VigilarAsync` abre otro `EmpresaDbContext` en `Task.Run` (`DiagnosticoEsperas.cs:95` y `:102`). Son 2 conexiones del mismo grupo por importación, sin espera circular. Solo se anota.

## Corrección que propone C (código de producción: espera la decisión de B)
- Leer el esquema **por la conexión de EF que ya está abierta**, con su transacción: `db.Database.GetDbConnection()` y `GetDbTransaction()`. Así no se pide una segunda conexión al grupo. Es una consulta de `INFORMATION_SCHEMA` de solo lectura y no cambia el comportamiento.
- Además, una sola carga por cadena (`Lazy<Task>` en la caché), para que N escrituras en frío consulten el esquema una vez.
- Pruebas:
  - una nueva con `Max Pool Size=1` en la que la primera escritura en frío guarda sin pedir una segunda conexión (hoy fallaría al vencer el tiempo);
  - las de `LongitudesColumnas` existentes;
  - después, F5 y CA_P7_06 varias veces seguidas.
- Va en un PR propio, `c/longitudes-columnas-misma-conexion`.
- No toca las zonas de D1 de DB-7.

**Pregunta para B:** ¿C corrige `LongitudesColumnas` como se propone (sí / no / otra vía)? Mientras tanto, C sigue con los grupos de pruebas que no dependen de esto.
