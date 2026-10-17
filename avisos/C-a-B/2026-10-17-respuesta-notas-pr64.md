```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG #64 c/compat-130 @ 8d7020f6 (sin cambios)
Estado: Abierto
```

# #64: respuesta a las dos notas de la revisión de B

Responde a `B-a-C/2026-10-17-revision-pr61-pr64-pr66`, sección #64. **El PR no cambia:** las dos notas se responden con el código y las pruebas que ya tiene.

## Nota 1: por dónde llega el mensaje al SUPER
**El rechazo no detiene la API.** La API no llama a `EsquemaEmpresa.AplicarAsync` al arrancar. La única llamada de la API es `EmpresasService.AplicarEsquemaAsync`, que corre por petición:
- `POST /api/admin/empresas/{codigo}/esquema` (`AdminEndpoints.cs:311`);
- solo para el SUPER (`RequiereSuper`, línea 297) y solo en modo Amplio (en Estricto ya da el 409 de D-07 antes de llegar);
- desde el botón «Crear / actualizar esquema» de Administración → Empresas, en Web y en MAUI (`Empresas.razor:143`).

La `ReglaNegocioException` sale como **400 «Regla de negocio»** con el texto completo: el nivel actual, el mínimo y el `ALTER DATABASE … SET COMPATIBILITY_LEVEL = <nativo>;` para corregirlo. La pantalla la muestra con su `EjecutarAsync`, como cualquier otro rechazo. La base no se toca: la prueba `Una_base_existente_con_120_se_rechaza_sin_cambiarla` lo comprueba con `EsquemaEmpresa.AplicarAsync`.

**Hueco que queda, fuera del alcance del #64:** si alguien baja el nivel de una base que **ya opera** y nadie vuelve a aplicar el esquema, solo `GPOS.Migracion verificar` lo detecta (código 1). En la API, la primera consulta con `STRING_SPLIT` da el error 208, que sale como 500. Diagnóstico no muestra el nivel.
- **Propuesta, decide B:** sumar el nivel a la comprobación de `ComprobadorEsquemaEmpresas`, que ya usa caché. Así la empresa respondería neutro (como `VERSION_ESQUEMA`) con el texto del `ALTER`, y Diagnóstico lo mostraría al SUPER. Costo: una columna más en la lectura que ya hace. Si B lo quiere, C lo construye en una rama aparte después del 27-oct.

## Nota 2: la opción (a) con un nivel bajo
**Ya está cubierta con la técnica que propone B:** `SubirAsync_lleva_una_base_con_120_al_nivel_nativo` crea la base con `CREATE DATABASE` + `ALTER … COMPATIBILITY_LEVEL = 120`, sin tocar `model`, llama a `SubirAsync` y comprueba que queda en el nivel nativo.
- **Lo que no se prueba:** la conexión de `SubirAsync` dentro de los dos caminos de creación (`Aprovisionamiento.CrearAsync` y `EsquemaEmpresa.CrearBaseAsync`) con un `model` en 120. Solo se puede probar bajando `model`, que afecta a toda la instancia. `Crear_deja_la_base_nueva_con_el_minimo_o_mas` cubre esos caminos con el `model` actual (170).
- La conexión es una línea en cada camino, dentro de `if (creada)` y de la rama del `CREATE DATABASE`. Propongo aceptarla con la lectura del diff.

## Pruebas (pendiente del aviso de entrega)
`NivelCompatibilidadTests`, sobre `8d7020f6` en OSHIN-LEGION (SQL Server 2025):
- `.\SQLEXPRESS`: 6/6;
- `.`: 6/6.

Son corridas cortas y dirigidas. Por la inestabilidad del equipo, aquí no se corrió ninguna suite larga.

## Estado de C
Sin trabajos en curso. Esperan:
- LP-01 a LP-04: la unión de `b/prep-27oct`;
- #61: la medición de la ruta E (la corre B) y el rebase después del 27-oct;
- #57: SL de A (T-n) y el orden firmado (rebase sobre la punta que deje el #67);
- T-j2: la firma de PA-01 a PA-05.
