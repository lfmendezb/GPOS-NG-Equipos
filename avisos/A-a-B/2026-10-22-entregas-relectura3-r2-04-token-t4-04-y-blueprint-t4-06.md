```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (relectura 3 de PR-2; R2-04; frontera del token de T4-04; blueprint de T4-06) y respuestas pendientes
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/` (según el punto)
Estado: Abierto
```

# Entregas de A del 2026-10-22 (tarde)

## 1. Tercera relectura de seguridad de PR-2: aprobado con observaciones
`traspasos/A/relectura3-seguridad-pr2-adr90-2026-10-22.md`, sobre `89f03411` (incluye tu P139-01, correcto: coincide con `Program.cs:56`). **R2-01 y R2-02 cerrados.** Sin hallazgos Críticos, Altos ni Medios. R3-01 (Baja, informativa): las reglas de arquitectura solo se evaden con cambios intencionales; arreglo opcional (fijar el prefijo de S5 y acotar las excepciones por ruta). Solo lectura: depende de la suite oficial sobre `89f03411`, que A no corrió completa.

## 2. R2-04 y el #155
`traspasos/A/adr90-precision-h15-s2-04-2026-10-22.md`: texto de la «Precisión» de H-15 (S2-04 opción b) y H-09 para `ADR-090.md`, «Propuesto, pendiente de firma». **Discrepancia:** el #155 ya trae un bloque «Precisión del 2026-10-22» que se declara firmado; A no pudo verificar esa firma. Ese bloque no cubre H-09 y define «sin modo» de forma más estrecha (no dice que el residuo vale también para la Web). **Pregunta:** ¿existe la firma? Si el #155 se une, nuestro texto debe sustituir ese bloque, no sumarse.

## 3. T4-04, token de servicio: propuesta de frontera (para el arquitecto-software de B)
`traspasos/A/propuesta-frontera-token-servicio-t4-04-2026-10-22.md`. `IEmisorTokenServicio.EmitirAsync(...)` en `src/GPOS.Api/Seguridad/Programados/` (token que se revoca al desecharlo; excepciones que `EjecucionReglas` ya registra); referencia opaca de 256 bits ligada a una sesión técnica en memoria, no JWT; 5 min exactos; tres ajustes pequeños en la API de reportes a cargo de A; 1,5 dp (±30 %); acuerdo hasta el **28-oct**, PR apto el 6-nov, entrega antes del 10-nov.
- **P-1 (firma del propietario, vía B):** no emitir token para reglas guardadas por el SUPER (ADR-81 y ADR-92: acceso desatendido sin segundo factor); esas reglas dejan de enviarse hasta que un ADMIN las guarde de nuevo.
- **F-1 a F-5 (con B):** forma del token; si A toca archivos de la API de reportes; **lista de rutas que abre un token programado (B, antes del 30-oct)**; suspensión de Q7 (¿espera a D5?); 429 cuando el autor usa reportes en ese momento.
- Riesgo de capacidad: T4-06 y T4-04 coinciden desde el 3-nov en los dos cupos de la PC A; si PR-4 se atrasa, el token pasa al 12-nov.

## 4. T4-06: blueprint previo
`traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md`. 4,9 dp (2,9 a 6,9), 7 tareas (TA-0 a TA-6); trabajar del 3 al 7-nov, suite sola el 9 o 10-nov, unir antes del **11-nov** con orden del propietario. **H-T4-11: no falta ninguna vista**; el SQL sale de N1 a N7 con dos ajustes (quitar `ORDER BY`; sufijo `Base` en los tramos de antigüedad). La exigencia de Q-6 va en `AgregarReenvioReportes` (no en `Program.cs`), así que **el choque con PR-4 desaparece**; el PR debe pasar también `dotnet build src/GPOS.Api -c Release`.
- **Dos piezas que el plan no listaba:** H-A06-01 (Media, severidad por confirmar por seguridad): «Guardar» del diseñador ejecuta el SQL del ADMIN en la principal con el inicio de sesión de escritura aunque haya reenvío; propuesta `IDetectorColumnas` (+0,5 dp). Y las notificaciones (`TrabajoNotificaciones.cs:45,59`): si T4-06 se une antes que T4-04, Release no compila; en Release la regla falla cerrada y queda registrada.
- **R-2 (Alto):** con Q-6, una principal Release sin dirección de reenvío no arranca: el DEMO de `feature/modelo-ng` deja de arrancar (más grave que H-T4-07), y `Publicar-PaqueteDemo.ps1:130-134` exige que no haya dirección. **La tarea 3 (DEMO con la API de reportes) debe estar antes de publicar nada.**
- **Preguntas P-1 a P-9** al final del blueprint; **P-1 a P-3 antes del 3-nov** (cómo valida Guardar en Release; programados en Release; en Linux la principal Release no arranca). TA-1 (la semilla) no depende de PR-4 y se puede adelantar.
- Para B: arquitecto-datos, confirmar que en `caja.Movimiento` un monto positivo es ingreso.

## 5. Estado del #140 y suite
Punta `89f03411` con R-01 a R-05, R2-01, R2-02 y P139-01; la suite oficial sobre `23176529` dio 4937 correctas y 4 con error por concurrencia (avisada antes); no se repitió completa sobre `89f03411`.

Respuesta requerida: B responde P-1 (token) y F-1 a F-5 antes del 2026-10-28, la lista de rutas antes del 30-oct, P-1 a P-3 de T4-06 antes del 3-nov, y la pregunta sobre la firma del #155.
