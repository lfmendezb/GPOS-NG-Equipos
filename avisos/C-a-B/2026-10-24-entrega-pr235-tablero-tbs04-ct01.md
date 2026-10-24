```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 5 de `B-a-C/2026-10-24-tareas-nuevas-para-c-tanda-10.md`)
Prioridad: Normal
Repositorio y rama: GPOS-NG [#235](https://github.com/lfmendezb/GPOS-NG/pull/235) (`c/pruebas-tablero-tbs04-ct04` @ `518b6166`, base `feature/modelo-ng`)
Estado: Abierto
```

# Tablero: TBS-04 en las 7 rutas con alarma de ruta nueva, y CT01 lista

PR #235, solo `tests/` (3 archivos, +258/−10; sin tocar `src/`).

**C-T03: completar TBS-04 (no la guarda de fuente CT04).** CT04 es un regex sobre el texto de `EndpointsReportes.cs`: se rompe si cambia el formato (rutas en otro archivo, `MapGroup` anidados) y solo prueba que la llamada está escrita, no que responde 403. En su lugar, `TBS_04_un_restringido_con_token_de_otra_empresa_recibe_403_en_todas_las_rutas` recorre una tabla `RutasDeDatos` con las 7 rutas (la exportación con `canal: true`): AJENO debe recibir 403 `SUCURSAL_NO_PERMITIDA` y, como control, RESTRINGIDO no debe recibirlo. `TBS_04_la_tabla_de_rutas_probadas_es_exactamente_la_de_las_rutas_registradas` lee el `EndpointDataSource` real y exige que la tabla coincida: una ruta nueva sin prueba hace fallar, que es la función del conteo de CT04. Costo ~0,25 dp, como estimaba mi revisión. **No cubre** las 4 rutas de `/interno/render` (no leen datos de la empresa y esa clase de pruebas no las monta; es el C-T04 informativo): esa excepción no tiene guarda hoy.

**Mutaciones** (una por vez, restauradas; el diff de `src/` quedó vacío): (1) en `vista-previa`, reemplazar `contexto.ObtenerAsync` por un contexto armado a mano: la prueba vieja de 3 rutas seguía verde, la nueva falla con «se esperaba 403 SUCURSAL_NO_PERMITIDA y se obtuvo 200»; (2) añadir `g.MapGet("/mutante", …)` sin contexto: falla la prueba de la tabla de rutas.

**CT01 lista para correr.** `tests/GPOS.Tests/Alcance/ConsultaFacturasRestringidoTests.cs` (`[Collection("bd")]`; escenario del anexo: S2 con 236, otra sucursal con 118): 5 pruebas `CT01_…` con `Transicion=Defecto` que fallan hoy (lista con suma de saldos 236 igual a la tarjeta; exportación `TodasAsync`; detalle por número, que acepta `null` o `AccesoDenegadoException`; búsqueda por número; falla cerrada sin sucursal, con sucursal inexistente o sin cuenta) y 2 controles sin marca que pasan hoy (el restringido ve su propia factura y la tarjeta dice 236; sin restricción ve ambas, 354). El servicio se construye por reflexión con lo que pida el constructor (fábrica, sesión o `IAlcanceAlmacenes`): si A pasa el alcance por constructor la prueba compila igual; si lo pasa por parámetro de método solo hay que ajustar `Servicio()`. Con la opción (a) pasan a verde las 5 `CT01_…` sin cambiar aserciones y se les quita `Defecto`; con (b) siguen `Defecto` hasta T4-08. El conteo de marcas `Defecto` queda en 7 (`ClasificacionPruebas.md`).

**Resultados** (SQL local, una compilación a la vez; corrí yo de nuevo lo esencial): `EndpointsReportesTests` 14/14; `ConsultaFacturasRestringidoTests` 5 con error y 2 superadas; con el filtro oficial 2 correctas, 0 con error. Del agente: `GPOS.Reportes.Tests` (`EndpointsReportesTests`, `ProveedorContextoTests`, `Tablero`) 53/53 antes y 54/54 después; `GPOS.Tests` con `Alcance` y `TableroReportes` y el filtro oficial 136/136; `PruebasNeutrales` 28/28 (el manifiesto y los rasgos siguen consistentes).

**No verificado:** que las 5 de CT01 pasen a verde con una implementación real del alcance (no se toca `src/`); conviene correrlas una vez antes de quitar el rasgo.

**Reparto:** el propietario decide C-T01 ((a) o (b)); A → implementar el alcance en `ConsultaFacturasService` si elige (a) y quitar `Defecto`; B → informar al propietario de que CT01 ya está lista.

Respuesta requerida: ninguna.
