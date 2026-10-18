```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: b/prep-27oct @ 3988078c; b/ola5-auditoria-r (punta en GitHub); feature/modelo-ng @ ce33b2a8
Estado: Abierto (solo información)
```

# Rango por nodo de la 3b, pruebas de plan estables y DEMO desde la punta

## `b/prep-27oct` (`3988078c`)
- **Ola 3b:** las cinco secuencias (`SecTransf*`) nacen con el rango de su nodo en una base ya registrada como otro nodo.
  - Ayudante `SecuenciaConRangoDelNodo` en `SqlMigracionesOla3b.cs` (RESTART, MINVALUE y MAXVALUE, K-57).
  - La migración de la 3b no está unida todavía, así que se corrige en ella misma.
  - Prueba Up/Down/Up con el nodo 2 simulado.
  - Guion regenerado: solo agrega los cinco ajustes y coincide byte a byte con una copia limpia. `has-pending-model-changes` sin cambios.
  - Cierra el hallazgo Bajo del aviso `2026-10-15-ola5-auditoria-rehecha`: **el arquitecto de datos de A no tiene que hacerlo.**
- **Pruebas de plan** (`Uf05PlanTests` y `AplicacionEmisionPlanTests`):
  - leen en dos pasos: primero una tabla variable con las filas del `plan_handle` del disparador, después el texto y el plan solo de ellas. En una sola consulta, el motor tocaba las bases de otras pruebas (952);
  - reintentan 952, 8181 y los errores graves (clase 20 o más).
  - **Resultado:** 0 fallas en 6 corridas alternando instancias, con Mvp, migraciones y la 3b en paralelo.
  - **Regla para pruebas nuevas de plan:** usar este patrón.

## `b/ola5-auditoria-r`
- Trae `3988078c`. `SecExportacion` usa el mismo ayudante y el guion está regenerado.
- 121/0/1 en las dos instancias (auditoría, 3b, migraciones, secuencias, planes y Mvp).

## `feature/modelo-ng` (`ce33b2a8`)
- Unido `b/devops-demo-sistema`: `Instalar-Demo.ps1` crea las cuentas iniciales con `GPOS.Migracion sistema`. Las claves viajan por `SecureString` y en el entorno del proceso hijo, nunca en disco ni en la línea de comandos.
- Lista de publicación Release actualizada con PB-1 a PB-7 firmadas y `verificar --estricto` (M8).
- **El DEMO sigue saliendo de `demo/2026-10-15`** hasta que exista la licencia con `s1`.
