```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (lote: revisión de pruebas de #137, #139 y #140; tareas 3, 4 y 5 del aviso 2026-10-22; CC-01..05; casos de laboratorio)
Prioridad: Media
Repositorio y rama: no aplica (área común)
Estado: Abierto
```

# Entrega del lote del 2026-10-22

Todo en `traspasos/C/`. **Nada compilado ni ejecutado** (lectura de las ramas `origin/a/adr90-*`); cada informe lo dice en «Qué no verifiqué». Nada se une.

## Tarea 5: revisión crítica de las pruebas de la pila de ADR-90
| PR | Informe | Hallazgos |
|---|---|---|
| #137 | `2026-10-22-revision-pruebas-pr137.md` | 12 (5 Medios P137-01..05, 7 Bajos); ninguno Alto |
| #139 | `2026-10-22-revision-pruebas-pr139.md` | 10: **P139-01 Alto**, 2 Medios, 7 Bajos |
| #140 | `2026-10-22-revision-pruebas-pr140.md` | 12 (4 Medios P140-01..04, 8 Bajos); ninguno Alto |

- **P139-01 (Alto):** nadie fija el argumento `estricto` de `Preparar` en `src/GPOS.Api/Program.cs:56` (hoy `ComprobacionAnillo.EsEstricto(builder.Configuration)`). La regla S5 solo mira `ServicioRed.Api`. Con `false` fijo, la API en Estricto sin modo arrancaría con aviso 4745 en vez de negarse con 4743 y ninguna prueba falla. La Web sí lo fija. Comprobé en la rama que `Program.cs` pasa `EsEstricto(...)` y que, en los dos archivos de arquitectura del PR, solo aparece en el cuerpo de una prueba; la mutación en sí no la ejecuté.
- **P140-03 (Media, inferido, posible defecto de producción):** si el registro lanza al escribir 4748/4749, el bucle del refresco muere en silencio (solo atrapa la cancelación). Es lectura, no reproducido.
- Recomendación de C: P137-01..05, P139-01..03 y P140-01..04 antes de unir; los Bajos, en un seguimiento. B decide.

## Tarea 4 (adelantada del 5-nov): `2026-10-22-plan-pruebas-t4-04-y-t4-06.md`
Preguntas Q-1..Q-5 en §4 (tope del adjunto de correo, truncado vs 413, nivel del token de servicio, etc.).

## Tarea 3 (adelantada del 13-nov): `2026-10-22-diseno-fixture-api-reportes-en-proceso-y-plan-t4-02.md`
Fixture en tres niveles sobre `ReportesF9*`, colección compartida y plan de `ClienteRenderTests`. **No construir antes de que T1-5 de D1 esté unida.** Preguntas Q-1..Q-3.

## Tarea 4 de la cola anterior: `2026-10-22-cuestionarios-cc-revision-y-adendo.md`
CC-01..05 ya existían (Parte B del 2026-10-19). Entrego revisión y una pregunta 6 propuesta (descuento por nómina). Nada enviado al contador.

## Casos de laboratorio: `2026-10-22-casos-laboratorio-chromium-y-comprobaciones-paquete.md`
14 casos de Chromium y 28 de R1..R10/Burn; preguntas Q-1..Q-5 (origen de Chromium, `--no-sandbox` = decisión de seguridad para el propietario).

## Pendiente de C
Pruebas inestables (en curso, 13-nov); dorados de T4-01 (6-nov) y revisión del PR de T4-01 esperan su aviso; revisión de los PR de D1 esperan su aviso.

Respuesta requerida: B decide qué hallazgos entran antes de la unión.
