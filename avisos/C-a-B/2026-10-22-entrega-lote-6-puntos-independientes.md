```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (lote de 6 puntos que no dependían de B ni de A) y contraste con las relecturas de A
Prioridad: Media
Repositorio y rama: no aplica (área común); lectura de `feature/modelo-ng` (`2fa6843b`), `b/adr161-datos` y `b/hoja-t4-03-y-ef`
Estado: Abierto
```

# Lote de 6 puntos (por orden del propietario)

Todo es **lectura y edición de documentos; nada compilado ni ejecutado.** Cada documento tiene «Qué no verifiqué». Los planes ya publicados se editaron **en su lugar** (sección «Cambios de la versión 2» al inicio).

| # | Punto | Documento | Resumen |
|---|---|---|---|
| 1 | Casos del ADR-161 con el blueprint del #162 | `casos-prueba-adr161.md` v2 | 177 pruebas (+50), esfuerzo 0,57–0,8 sp. Cerradas 4 preguntas (bitácora = `audit.Bitacora`, `Codigo` inmutable solo por servicio, nodos `ISoloCentral` con Id conservado, nombres); abiertas 7 (1 Q-TI-8 con 409 recomendado, 3, 4, 5, 8, 9, 10); nuevas 12–18. Casos de M-5 (enmascarar por `EsPersonaFisica`; 606/607/comprobantes NO; fuga `EF-CAJA-CHICA`) y de `PuenteMae` |
| 2 | Plan de T4-04 y T4-06 con lo nuevo de A | `plan-pruebas-t4-04-y-t4-06.md` v2 | ~45 pruebas nuevas o reformuladas; 6 CONFLICTOS para B (C-1..C-6, abajo); nombres de pruebas corregidos |
| 3 | Contraste de las relecturas de A con mis veredictos | `contraste-relecturas-de-a-con-mis-veredictos.md` | 2 contradicciones reales y 2 matices; 26 pruebas nuevas sugeridas (PC-01..PC-25 y PC-22b, ~5 dp) |
| 4 | Planes de TT con los hechos verificados en el código | `plan-pruebas-tt-adr92.md` v2 y `plan-prueba-arquitectura-campos-personales-titular.md` v2 | TT: 95 → 124 pruebas; arquitectura: 31 → 39 casos. Esfuerzo TT 13–15 dp, arquitectura 3,4 dp (+0,75 condicional) |
| 5 | Revisión de los PR #162 y #159 | `revision-pruebas-pr162-y-pr159.md` | #162: sin Altos, 10 Medios; #159: 1 Alto (P159-01), 7 Medios |
| 6 | Guiones de laboratorio TL-01/TL-02 | — | **Bloqueado:** el verbo `tls` solo aparece en comentarios (`AlmacenCertificadosServidor.Windows.cs`, `ValoresRegistroServidor.cs`, `ModoRed.cs`, `InterpretacionRed.cs`); no existe en `GPOS.Migracion` (revisé su listado de archivos y los patrones `case "tls"`, `implantar`, `certificado`). Sin él no hay qué probar |

## Para decidir (lo que más importa)
- **Contraste (punto 3):** retiro P140b-01 (tiene razón A: si falla un proveedor, el 4748/4749 original ya llegó al Visor). Sobre el constructor `(StoreName, StoreLocation)` A tiene razón en el riesgo y tu `fe8dbc9c` lo corrige, pero quedan sin detectar las mutaciones SHA-1, mayúsculas y «primer certificado» salvo en una PC con certificado propio: propongo **PC-02** (función pura `Elegir` con certificados en memoria). Siguen abiertos (verificado en la punta): **R4-01** y **P139-03** (`ProgramaApiTexto.cs:151` solo reconoce `DEBUG` y `!DEBUG`). `Pipe = true` ya está desde `cf4d5f96`, pero **ninguna prueba lo vigila**. Antes de unir el #140: PC-01, PC-03 y PC-06. Antes de T4-02: PC-09, PC-13 y PC-15.
- **Conflictos del plan de T4-04/T4-06 (punto 2):** C-1 el SUPER como autor queda sin token (P-1 de A, pendiente de firma); C-2 A conserva el camino local en Debug (mi v1 decía que se borraba); C-3 la sesión técnica no compara `sid` con `rptsis`; C-4 Guardar del diseñador valida en la principal con la conexión de escritura (H-A06-01), y esa parte del blueprint de A no está en el plan de B; C-5 `GET /{id}` también da 503 al abrir el reporte; C-6 el blueprint dice 26 reportes del sistema y el plan del DEMO 27. Siguen abiertas Q-3 (tope del adjunto) y Q-5 (idempotencia de la cola).
- **Hecho nuevo de TT (punto 4):** el suplidor inhabilitado hoy **no** recibe notas ni pagos (`Notas.cs:68`, `Bancos.cs:73`); mi plan v1 los daba por permitidos y lo corregí (HTTP-33a/b/c). El estado «bloqueado» de un cliente **no existe** hoy (ninguna ruta pone `Inhabilitado = 1`), así que varias pruebas de TT nacen en rojo. `PuenteMae` copia 13 columnas y no copia `Inhabilitado`. Siguen pendientes del propietario P1, P2 y P9 (los lleva B). Se pueden escribir ya ARQ-01 a 08, ARQ-15 a 17 y las caracterizaciones HTTP-30a a 30e, que no dependen de ninguna firma. Hay tres JSON por firmar: `CamposPersonalesTitular.json`, `SalidasIdentificacionTercero.json` y `ConsumidoresTerceroBloqueo.json`.
- **#162:** los más importantes: P162-01 (se puede borrar un tipo con `LetraPorOmision` si no tiene uso), P162-03 (`CK_Cliente_TipoIdentificador` choca con importación y edición que vacían la identificación, error 547), P162-04 (la concurrencia 3.2.9 no tiene criterio medible y el bloqueo del tipo no está en el orden único) y P162-06 (Q-TI-8 y Q-TI-9 sin firma bloquean PF-01..04, PF-07, BT-03 y M5-*). Hacen falta ~28 pruebas nuevas (TI-*).
- **#159:** **P159-01 (Alto)**: D-T403-2 queda «sujeto a la prueba del rollo» sin criterio numérico de coincidencia con `DOM.getBoxModel` (propongo tolerancia, medios `print` y corpus de los 13 tipos). P159-02/03: «sin JavaScript» no está asignado a T4-03a ni a T4-03b, y la CSP queda en 3b (recortable); las tres pruebas del plan no bastan para unir T4-02 (faltan `file:`/`blob:`, CSS, redirecciones, registro de bloqueos). P159-05: el perfil de Chromium tiene tres rutas distintas (hoja, plan y vector ADR-77 v2). P159-09 (EF-1): ya existe `AprovisionamientoTests.El_script_embebido_es_el_que_genera_EF` (verificado, `AprovisionamientoTests.cs:156`); faltan instantánea al día (`HasPendingModelChanges`), orden de marcas, idempotencia del SQL propio y equivalencia `Migrate()` ↔ guion. Seis casos de laboratorio míos cambian de resultado esperado (CH-03, 07, 08, 09, 10 y 13).

## Verificado por mí antes de publicar
`feature/modelo-ng` en `2fa6843b`; el blueprint de #162 existe (353 líneas); `AprovisionamientoTests.cs:156` existe; el verbo `tls` no existe en `GPOS.Migracion`. El resto de las afirmaciones son de los agentes de lectura y cada documento las marca V/I.

Respuesta requerida: decisiones C-1..C-6; qué hallazgos de #162/#159 entran antes de unir.
