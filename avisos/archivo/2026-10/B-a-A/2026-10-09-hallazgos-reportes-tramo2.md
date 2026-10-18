```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Hallazgos y decisión del propietario
Prioridad: Alta (hallazgo 3 de seguridad: fuga entre sucursales)
Repositorio y rama: GPOS-NG feature/modelo-ng (principal, ReportesService.cs); diseño en b/ola5 63cd7f7; precisión de ADR-109 en master
Estado: Abierto
```

# Reportes en la principal: tres hallazgos y D-01 a D-05 firmadas

El diseño del tramo 2 de la API de reportes (`b/ola5`, `docs/arquitectura/2026-10-09-ola5-api-reportes-tramo2.md`) verificó tres defectos en la principal. Las referencias de línea son del árbol de `fba132e`.

## Hallazgos en `ReportesService.cs`
1. **Filtros de texto como `nvarchar` (viola ADR-50).** `ReportesService.cs:292-296` y `:325` crean `new SqlParameter(nombre, valor)` sin tipo. Contra columnas `varchar` eso impide usar el índice y puede causar recorridos e interbloqueos.
2. **Totales incorrectos en reportes grandes.** `:350-352` suma los totales solo sobre las filas devueltas (máximo 10.000). El total de una columna `PROMEDIO` es la suma de los promedios. Es el punto del tablero asignado a la ola 5.
3. **Seguridad: los reportes del diseñador no aplican `RestringirSucursal`.** Ni los reportes ni sus filtros lo leen (búsqueda de `Restring` y `sucursal` sin uso). **Un usuario restringido a una sucursal ve los datos de todas.**

La API de reportes corrige los tres al pasar la ejecución a ella (tramo 2). **Pedido:** como la unión de la ola 5 es hacia el 22 o 23 de octubre y depende de `GPOS.Migracion`, B recomienda un arreglo puntual del hallazgo 3 en la principal antes de cualquier instalación fuera de desarrollo. Del 1 y el 2, decidan ustedes si esperan al tramo 2.

## Firmado por el propietario el 2026-10-09: D-01 a D-05 según la recomendación
Registrado como precisión de ADR-109 en master:
- **D-01:** la exportación usa un archivo temporal cifrado, para que el encabezado de evidencia lleve renglones y totales.
- **D-02:** la exportación se atiende solo por el canal interno con la principal.
- **D-03:** restricción de sucursal en los reportes del diseñador; 403 `SUCURSAL_NO_PERMITIDA` si el reporte no tiene columna de sucursal.
- **D-04:** máximo de 50.000 filas para recorrer en pantalla.
- **D-05:** totales sobre todo el resultado filtrado; promedio ponderado.

## Lo que le toca a A (sección 13 del diseño)
1. Agregar `src/GPOS.Reportes/Consultas/` y `src/GPOS.Reportes/Ejecucion/` a `Permitidos` de `SqlSoloEnLugaresPermitidosTests`.
2. Construir en la principal el cliente de exportación por la canalización (D-02), escribir `audit.Exportacion` y crear la clave `rptexportar` (precisión de ADR-11), concedida por omisión a quien hoy tiene reportes.
3. Sembrar los reportes registrados (`Fuente = 'REG'`) y validarlos: el diseñador no crea ni edita uno REG.
4. Integrar `rptsis` (22 o 23 de octubre).
5. **`GPOS.Migracion`** (llave ECDH del sitio, `crear-lectura` y `rotar-lectura`): bloquea la prueba de punta a punta del tramo 2. **Confirmen quién lo construye y cuándo.**

Esfuerzo del tramo 2 en B: unas 2,6 sp (1,6 a 3,6, inferido).
