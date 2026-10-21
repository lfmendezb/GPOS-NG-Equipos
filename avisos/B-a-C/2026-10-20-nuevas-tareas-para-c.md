```
Para: C (conocimiento de A)        De: B        Fecha: 2026-10-20
Tipo: Encargo (el propietario pidió distribuir nuevas tareas) y acuse
Prioridad: Media
Repositorio y rama: GPOS-NG PR #119 a #126
Estado: Abierto
```

# Acuse
Recibidos los PR #123 (DrillDown), #125 (pruebas inestables), el plan de pruebas de D1 y la revisión de pruebas de los #119 a #122. **C tenía razón en lo de `Exigir`/`ComprobarDirecciones`** (sí tienen pruebas; B las había dado por ausentes por un filtro incompleto de su búsqueda). Gracias por refutarlo con evidencia.

# Tareas nuevas de C, por orden (mismas reglas de PC: filtros por clase, sin suites completas ni mediciones; sin tecnología nueva)
1. **Pruebas que faltan en el #121 (T4-05)**, las que C marcó como Altas: aserciones con datos de `rpt.Compra`, `rpt.DocBanco`, `rpt.CatTipoGasto` y `rpt.CatTermino`; el redondeo que «nunca redondea»; la evidencia de `MigracionOla5VistasTests`; y la comprobación de que el filtro exacto distingue mayúsculas y espacios con `CI_AS` (pregunta de C). Va en un **PR apilado sobre `b/t4-05-vistas-p2`** (base esa rama), solo pruebas. Ojo: el commit `59c16146` ya corrigió la tasa 1 del cheque devuelto y de la importación (SEG-T405-01); C ajusta lo suyo a ese estado.
2. **Revisión de pruebas, solo lectura**, de: el #124 (O-1 y O-3, acción previa y raíz/config), los commits nuevos de seguridad de #120 (`974128e5`, `8bacc925`) y #121 (`59c16146`), y el #126 (solo el texto de las firmas, no hay código). Entregar en `traspasos/C/` y como comentario en cada PR.
3. **Plan de pruebas de N-1** (modo servicio de `GPOS.Api`; lo construye B, rama `b/n1-api-modo-servicio`, ventana 28-oct a 6-nov, terminando antes del 2-nov): qué debe fijar la prueba de arquitectura del orden del middleware y qué no se puede probar sin instalar el servicio. Solo diseño.
4. **Respuesta de B sobre P120-01** (Alta; `Abrir` sin comprobar el dueño ni la ACL): ya lo cubre `S120-02` (`974128e5`, relee el descriptor al crear y al abrir). C confirma con su lectura del commit y baja o mantiene la severidad.

## Fuera de C
Mediciones con `GPOST_B9`, suite completa, compilación de MAUI (origen NuGet local) y todo lo que exija instalar o ejecutar servicios.
