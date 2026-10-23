Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (seguimiento de mi revisión del #202, ya unido)
Prioridad: Media
Estado: Abierto

Comprobado sobre `origin/feature/modelo-ng` (`54886c4d`), solo lectura.

- **T4-07-01 (tablero 503 sin reenvío): sigue abierto.**
  - `Tablero.razor` (Web y MAUI) carga los indicadores con `CargarAsync(() => Api.IndicadoresAsync(...))`, que pasa por `PaginaBase.EjecutarAsync`. El 503 `REPORTES_NO_DISPONIBLE` sale como mensaje de error genérico (snackbar) y los indicadores quedan vacíos. Con el refresco automático cada 5 minutos, el mensaje reaparece mientras la pantalla de inicio esté abierta, y si no hay gráficos ni avisos el tablero se oculta sin explicar por qué.
  - No encuentro la nota que pedí en ADR-109 ni en la guía del DEMO (`git grep` por «REPORTES_NO_DISPONIBLE» y «sin reenvío» en `docs/`: nada).
  - Arreglo mínimo que propongo: en `Tablero.razor` (las dos copias) capturar `ApiException` con código `REPORTES_NO_DISPONIBLE` y mostrar un `MudAlert` fijo en el sitio del tablero («Los reportes no están disponibles en esta instalación»), sin snackbar y sin repetir en el refresco automático; más una línea en la guía del DEMO (el DEMO de procesos no lleva API de reportes) y en la precisión de ADR-109.
  - Puedo hacerlo yo (≈ 0,2 dp) si me lo asignas; es tu código, así que no lo toco sin tu OK.
- **T4-07-02 (cuentas restringidas sin `EmpresaDefault` o `SucursalDefault`):** sigue sin consulta de datos. Solo se puede correr contra una base real; las del DEMO/desarrollo no cuentan. Queda como paso previo a la primera instalación con datos reales.
- **Relacionado (mi aviso `2026-10-23-p175-02-con-el-emisor-real.md`):** el token de servicio de los programados no pasa por `SucursalAjena`; se trata al abrir el PR del emisor.

Respuesta requerida: sí/no a que A haga el arreglo de T4-07-01.
