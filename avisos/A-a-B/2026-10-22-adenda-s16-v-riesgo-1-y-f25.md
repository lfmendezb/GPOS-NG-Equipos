```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (adenda a la lista de rutas de S-16: V-RIESGO-1 y F-25) y preguntas
Prioridad: Media (Q-A1 y Q-A2 antes de empezar P-0 de E-1)
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (sección «Adenda 2026-10-22», líneas 213 a 386)
Estado: Abierto
```

# Adenda a S-16: V-RIESGO-1 y F-25 (entregada antes del 6-nov)

Base leída: `origin/feature/modelo-ng` @ b4378650 (la misma de C). Solo lectura, nada compilado.

## V-RIESGO-1
- **Corrección al plan de C:** «existencia insuficiente» **no** sale de `LibroInventario.ExistenciasAsync` sino de un `UPDATE` atómico (`ConsultasInventario.cs:13-39`), tras comprobar que la sucursal del documento puede mover el almacén (`LibroInventario.cs:169-190`). De las tres líneas que C llamó «de escritura», solo `InventarioService.cs:586` (la foto del borrador del conteo) escribe.
- **Decisión 1:** dos firmas. «Existencias para calcular» (interna: almacén obligatorio, sin alcance; el SQL deja de tratar el nulo como «todos», `ConsultasInventario.cs:224-230`) y «existencias para mostrar» `ExistenciasVisiblesAsync(..., AlcanceResuelto)` (falla cerrada, solo R-05). `AlcanceResuelto` solo lo crea `IAlcanceAlmacenes` y su valor por omisión es Vacío (responde la P-01 de C).
- **Decisión 2, fuga real por el guardado:** el documento toma la sucursal del token (`InventarioService.cs:552`, `DocumentosNg.cs:73-80`); con un token viejo, el mensaje de faltante revela existencias de la sucursal anterior. Se cierra en `RevocacionSesiones.Evaluar`: si el usuario está restringido y la sucursal del token no es su `SucursalDefault`, **401 `credenciales`** (una comparación de cadenas por petición; cierra también la P-13 de C sin ruta por ruta; se descarta el mecanismo de CS-4).
- **Decisión 3, corrección de D-1:** **R-07 pasa de `Operativo` a `Consulta`** (el conteo solo se guarda en almacenes de la propia sucursal, `InventarioService.cs:556-562`); con eso la P-07 de C ya no aplica.
- **Fuga nueva:** al cambiar «Requiere lote», el mensaje muestra cantidades de toda la empresa (`LotesDocumento.cs:162,165`); para un no global, sin cifras (va en E-1).

## F-25: diseñador de reportes
La API de reportes ya lo bloquea (`PuedeDisenar => EsAdmin && !RestringirSucursal`, `ContextoReportes.cs:43`, 403 `DISENO_NO_PERMITIDO`); la principal solo mira `EsAdmin` (`ReportesService.SoloAdmin()`, `:247-250`). **En E-1:** paridad con la API de reportes usando el alcance de P-0 (bloquea detectar, vista previa, Guardar y Eliminar). **En T4-06:** conservar la comprobación en Debug y que `IDetectorColumnas` en Release propague el **403**, no un 503 (fila nueva en el contrato de Guardar). **R-14 sale de S-16b** y lo cierra la Q-6 de T4-06 si se une antes del corte; si no, vuelve a S-16b.

## Efecto en la partición y el esfuerzo (±40 %)
E-1 +0,25 dp (~1,70; ~2,20 con las pruebas de C) · S-16b +0,05 dp (~1,60; ~2,40 con C) · T4-06 +0,05 dp. **Total +0,35 dp**, USD 0. Cambian en el plan de C: F-26 (F-26.1 a F-26.7, con separación borrador/aplicado), AL-10 (`Operativo` solo en R-05 y R-06), AL-12 fijado en Vacío, R-VIEJO-1 y R-VIEJO-3 (401 en todas las matrices, con pruebas unitarias de `Evaluar`), F-13, F-14.4 se elimina, F-05.7, F-20 pasa a T4-06, F-21.3 y F-21.7 (401), F-25.1 pasa a E-1 y se agregan F-25.2 y F-25.3.

## Preguntas para B
- **Q-A1:** ¿se corrige D-1 con R-07 en `Consulta`? · **Q-A2:** ¿se acepta el 401 `credenciales` para el token con otra sucursal? (**responder Q-A1 y Q-A2 antes de empezar P-0**: cambian la firma de `IAlcanceAlmacenes` y las matrices de R-VIEJO) · **Q-A3:** ¿se acepta que el ADMIN restringido tampoco pueda guardar ni eliminar definiciones de reportes? · **Q-A4:** ¿pasa R-14 a T4-06 con esa condición? · **Q-A5:** ¿qué regla se aplica al SUPER con bandera de restricción? La API de reportes ya lo restringe; C propone que nunca se restrinja; hace falta una sola regla para P-0 y para la API de reportes.

Supuestos [I]: `Despacho.cs:77,118` se tomó de C sin releer; que un ADMIN pueda saltarse el filtro declarando él mismo la columna de sucursal no se probó. Las decisiones 2 y 3 y la paridad del diseñador son precisiones de TA-P08 (ADR-93) que B registra.

Respuesta requerida: B responde Q-A1 a Q-A5 (Q-A1 y Q-A2 primero); C ajusta su plan de pruebas.
