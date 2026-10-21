```
Para: B                         De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión del texto de las firmas, solo lectura (tarea 2 del encargo del 2026-10-20)
PR: #126 (firmas del 2026-10-20: DP-1, DP-3 a DP-6 de la consulta CI-7; F-5 y F-6 de ADR-90), rama b/firmas-dp-f5-f6, commit 71ef0404
Estado: UNIDO a master (merge d064656c, 2026-10-21T02:14Z, que son las 22:14 del 2026-10-20 en hora local)
```

# Revisión del texto de las firmas del PR #126

## Dictamen: Aprobado con observaciones (el PR ya está unido; las correcciones van en un PR de seguimiento solo de documentos)

Todas las firmas registradas coinciden con lo que dicen la consulta y el documento de B, y ninguna afirma como construido lo que solo está decidido: cada bloque cierra con «Decidida, no implementada» o «nada está construido», y la guarda `ManifiestoAdr*` no tiene nada que objetar. Hay dos puntos de fondo que conviene corregir pronto porque pueden leerse como una decisión que no está firmada (P126-01, DP-2 «provisional (C)») o como un compromiso más amplio del que se firmó (P126-02, las condiciones de DP-3), y varios de forma con la marca de DF-02 / línea de DF-01 (P126-03).

**Alcance.** `git show 71ef0404` (tres archivos: `docs/adr/ADR-090.md`, `docs/adr/registro-de-novedades.md` y `docs/decisiones/2026-10-20-consulta-legal-ci7-borrador.md`), contrastado con: `GPOS-NG-Equipos/traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (F-5 y F-6), la consulta en `master` (secciones 1.7, 2.7, 2.8, 3.5 a 3.7, (e), (g), anexo), ADR-91 (DF-01 a DF-05) y `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md`. No hay código. No pude ver el chat donde el propietario firmó: «verificado» significa «coincide con los documentos del repositorio y del área común»; lo que solo dependía del chat lo marco *no verificable*.

## Verificación de cada firma

| Firma | Texto registrado | Contraste | Resultado |
|---|---|---|---|
| F-5 (opción (a)) | ADR-090.md:265, punto 1 | Coincide con la sección F-5 de B (ventana 10-28 a 11-06, suite completa sola, después del 11-20 si no entra, estado «sin modo», 0,25 dp). Añade la condición del 2-nov, que viene de la pregunta del chat y del aviso `B-a-A/2026-10-20-nuevas-tareas-para-a.md:21`. | Coincide, con dos reservas: P126-04 (orden N-1 y PR-4) y P126-05 (zonas del `Program.cs`) |
| F-6 (i) y (ii) | ADR-090.md:266 | Coincide con F-6 de B: `Api:Url` y `AllowedHosts` derivados del registro (cambia PT-01, H-09 y H-15 de PT-10); `tls` después de los MSI (motivo: PT-02 y HB-01). | Coincide |
| «Sin cambiar el texto firmado» | ADR-090.md:264 y :267 | Es una precisión que se anota aparte (DF-04), sin reescribir PT-01 ni PT-10. | Cumple |
| DP-1 | Consulta (h), tabla | Coincide con (g) («personas físicas» y «bloqueo o anonimización») y con 1.3 y 1.7; añade «cuando haya obligación de conservar», que sale de 1.3 (arts. 8 y 15) | Coincide; ver P126-06 (a quién afecta) |
| DP-3 | Consulta (h), tabla | Preautorizar el acceso de urgencia coincide con (g) y 3.5. Las condiciones listadas no son las de 3.5 | Discrepa: P126-02 |
| DP-4 | Consulta (h), tabla | «Archivo corporativo común» coincide con 3.6. El «plazo y custodio» pasa de «propietario» en (g) a «los fija el abogado» | Coincide, con la reserva de P126-07 |
| DP-5 | Consulta (h), tabla | Coincide con (g) y 3.7. 3.7 aclara que lo prepara el arquitecto-maestro «como decisión para firma» | Coincide; el alcance de la firma, P126-08 |
| DP-6 | Consulta (h), tabla | Coincide con (g) y con el anexo («o decirle que aún no existe») | Coincide |
| DP-2 | Consulta (h), viñeta 1 | «Se mantiene provisionalmente la opción (C)» no tiene respaldo en la consulta | Discrepa: P126-01 |
| Plazos | Consulta (h), viñeta 2 y novedades | Preliminar 2026-11-09 y completa 2026-11-16 coinciden con (e) | Coincide |

## Hallazgos

### P126-01 · Media · DP-2 «provisional (C)» no está respaldado y puede leerse como un cambio de diseño
- **Evidencia:** consulta (h), `docs/decisiones/2026-10-20-consulta-legal-ci7-borrador.md:300` («Se mantiene provisionalmente la opción (C) (acotar la excepción 2)»); `docs/adr/registro-de-novedades.md:299` («DP-2 queda sin decidir, provisional (C)»). En la propia consulta, la opción **A** es la firmada (LV-12) (`:204`, «Mantenerla completa (como está en LV-12)»); la **C** es una alternativa que se pregunta al abogado (2.8, `:93`); y la regla firmada de (e) dice que, sin respuesta, **las tres excepciones quedan bloqueadas** (`:237`). Ningún documento dice que (C) rija hoy ni que sea la recomendada.
- **Por qué importa:** DP-2 no está firmada. «Se mantiene provisionalmente (C)» sugiere un estado intermedio que no es ninguno de los tres firmados (A por LV-12, o el bloqueo de (e)); alguien que construya la clasificación de rutas (L1b) podría leerlo como instrucción.
- **Corrección propuesta:** «DP-2 queda sin decidir. Mientras tanto rige lo firmado: la excepción 2 como en LV-12 (opción A) y, si el abogado no responde, la regla de (e). La opción (C) es la que se pregunta en 2.8, no la vigente.» Si el propietario dijo «(C) provisional» en el chat, cítese como su indicación para preparar la propuesta, no como estado del diseño.

### P126-02 · Media · Las condiciones de DP-3 no son las de 3.5 y omiten las que limitan el alcance
- **Evidencia:** (h), `:295` («condiciones: correo posterior obligatorio, caso no cerrado hasta la respuesta del cliente y todo en bitácora») frente a 3.5 (`:108`): (i) la urgencia la pide una persona identificada del cliente, (ii) se limita a restablecer la operación o consulta afectada, (iii) el SUPER registra la urgencia y el número de caso, (iv) correo de confirmación dentro de un plazo corto, (v) qué ocurre si el cliente nunca responde. «Todo en bitácora» no está en 3.5 (viene de 3.3).
- **Por qué importa:** (i) y (ii) son las que acotan el acceso frente a la Ley 53-07 («excediendo una autorización»); un lector del registro puede tomar la lista de tres como la totalidad firmada.
- **Corrección propuesta:** indicar si se firmó «las cinco condiciones candidatas de 3.5» o «estas tres», y en cualquier caso aclarar «lista mínima; el abogado fija la redacción y puede añadir o quitar» (ya dice que redacta él).

### P126-03 · Media · DP-2 (pendiente) sin la marca de DF-02 y sin la línea de DF-01
- **Evidencia:** el encabezado de la consulta (`:5`, «DP-2 pendiente del abogado»), la nota bajo la tabla (g) (`:284`, «DP-2 queda sin decidir») y (h) (`:300-303`) afirman que DP-2 sigue pendiente sin la forma `(estado de firma de DP-2 al 2026-10-20: pendiente; fuente: [...](...))` que pide DF-02 para los encabezados de hojas y los documentos vivos de `docs/`; la hoja no trae la línea `- **Pendiente de firma:** DP-2` de DF-01 (`git grep "Pendiente de firma"` en el archivo no da resultados). La guarda DF-05 no ve este archivo, así que nada falla.
- **Efecto:** el día que un ADR cite DP-2 como pendiente con la marca, la guarda (DF-05, inciso b) fallará porque la hoja no lista el identificador; hoy depende del barrido manual.
- **Corrección propuesta:** agregar en el encabezado `- **Pendiente de firma:** DP-2`; en `:5`, `:284` y `:300` la marca de DF-02 con la fuente a la sección (h); y cambiar «Pendiente del abogado: DP-2, la redacción de DP-3, y el plazo y custodio de DP-4» (`:303`) por «Insumo del abogado (no son firmas pendientes): la redacción de DP-3 y el plazo y custodio de DP-4; **pendiente de firma:** DP-2», para que DP-3 y DP-4 no parezcan sin firmar. DF-03 también pide dejar el barrido fechado en el registro de la firma de la hoja; hoy está en el registro de novedades y en el PR, no en (h).

### P126-04 · Baja · F-5 omite el orden de las dos uniones
- **Evidencia:** ADR-090.md:265 dice «uno detrás del otro»; B dice que el PR de N-1 va primero y PR-4 después (`respuestas-b…md:327`, «PR-4 … después del PR de N-1 de B», y «primero en la ventana»); el aviso a A lo repite («solo cuando B avise que N-1 está unido», `nuevas-tareas-para-a.md:21`).
- **Corrección propuesta:** «N-1 de B primero y, después, PR-4 de A».

### P126-05 · Media · «Choque con T1-1 a T1-4 de DB-7 en las zonas del `Program.cs`» no coincide con el plan de D1
- **Evidencia:** ADR-090.md:265 y `registro-de-novedades.md:299`. El plan de D1 (`docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md:435,438`) dice que `src/GPOS.Api/Program.cs` lo tocan **T1-3** (registro de rutas) y **T1-5** (`ValidacionAcceso`), y que `src/GPOS.Migracion/Program.cs` lo tocan **T1-4** y **T2-0**; T1-1 y T1-2 no tocan ningún `Program.cs`. B justifica la ventana con T1-3 (11-09) y T1-5 (congelada del 11-11 al 11-13) (`respuestas-b…md:238-242`). El 2-nov es el inicio de T1-1, T1-2 y T1-4 (`2026-10-19-ola5-tramo4-plan-de-trabajo.md:371`). No encontré en el repositorio de dónde sale «T1-1 a T1-4».
- **Corrección propuesta:** si la frase viene de la pregunta del propietario en el chat, citarla como tal y aclarar el conflicto real: «con T1-3 y T1-5 en el `Program.cs` de la API (y T1-4 y T2-0 en el de `GPOS.Migracion`)». Si no, corregirla. Importa porque define con quién hay que coordinar la ventana si no se termina antes del 2-nov.

### P126-06 · Baja · «A quién afecta» de DP-1 y DP-3 en (h) está mal asignado
- **Evidencia:** (h), `:302` («DP-1, DP-3 y DP-5 cambian lo que el usuario del SUPER ve o hace (motivo con número de caso y urgencia; supresión por bloqueo o anonimización)»). La supresión ante la solicitud del titular la hace el cliente con su **ADMIN** (anexo de la consulta, «Excepción 1»), no el SUPER; y DP-3 es una cláusula del contrato, no cambia pantallas (solo DP-5 cambia el motivo del SUPER).
- **Corrección propuesta (principio rector: qué rompe, a quién afecta, por qué, cómo se migra):** DP-1 afecta al ADMIN del cliente en el modo solo consulta (registros de personas jurídicas quedan bloqueados) y al titular que pide la supresión; DP-5 al SUPER; DP-3 al contrato (AP-06). «Qué rompe» de DP-1: la rectificación y la supresión dejan de estar disponibles en solo consulta para personas jurídicas, lo que reduce la excepción 1 firmada; conviene decirlo, porque «para el cliente no hay cambio hasta que exista el contrato» no es cierto para el comportamiento del código una vez construido.

### P126-07 · Baja · El custodio de la evidencia (DP-4) pasa de decisión de GSF a decisión del abogado
- **Evidencia:** (g), `:280` (responsable «propietario (proceso de GSF)») frente a (h), `:296` («el plazo y el custodio los fija el abogado»). 3.6 solo remite al abogado el plazo de conservación. El custodio es una decisión interna de GSF.
- **Corrección propuesta:** «el abogado fija el plazo; el propietario designa el custodio».

### P126-08 · Baja · El alcance de lo firmado en DP-5 (¿postura o autorización para construir?)
- **Evidencia:** (h), `:290` («fijan la postura de GSF para la consulta y para el contrato») y `:302` («se registran como ADR cuando el arquitecto-maestro los prepare»); `avisos/B-a-A/2026-10-20-nuevas-tareas-para-a.md:25` («DP-5 (el arquitecto-maestro prepara el ADR; A construirá lo que se firme)»). El texto es coherente, pero DP-5 tiene fecha límite de construcción («antes de DB-7 v1») y alguien de DB-7 podría leer «firmada» como luz verde.
- **Corrección propuesta:** una línea en (h): «DP-5 está firmada como postura; construir el número de caso en el motivo del SUPER exige el ADR que prepara el arquitecto-maestro y su firma».

### P126-09 · Baja · La fuente de F-5 y F-6 está fuera del repositorio
- **Evidencia:** ADR-090.md:264 («del área común (no está en `master`)»). DF-01: una hoja que vive fuera del repositorio no puede ser fuente; antes de citarla se copia lo necesario a `docs/decisiones/`. Aquí el texto de F-5 y F-6 sí está reproducido íntegro en el ADR, así que el contenido firmado es verificable, y no hay una afirmación de «pendiente» que dependa de esa hoja; la regla se cumple en el fondo.
- **Mejora:** copiar a `docs/decisiones/` las secciones F-5 y F-6 de B (o la hoja) cuando se haga el seguimiento, y enlazarlas en lugar de la ruta del área común.

## Lo que verifiqué y está bien
- No hay en los tres archivos una afirmación de que algo esté construido: «Decidida, no implementada» (ADR-090.md:267), «Decidido, no implementado; `estado.json` no cambia» (novedades) y «nada está construido» (consulta (h)).
- La marca de DF-02 no era necesaria en el bloque de ADR-90: no afirma pendientes. La guarda de firmas lo confirma según el PR (39 correctas, 0 omitidas; no lo ejecuté).
- «El 607 y el 608 no llevan e-NCF» y las demás reglas del propietario no se tocan.
- La frase «no sustituyen la revisión del abogado colegiado» (consulta (h), `:290`) y el borrador sigue marcado «no es asesoría legal».

## Texto de comentario para el PR #126 (unido; se publica como seguimiento)

```
Revisión del texto de las firmas (QA de C, solo lectura; sin código). Dictamen: Aprobado con observaciones. Informe: GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pr126-firmas.md
Coincide con la consulta y con el documento de B (F-5, F-6, DP-1, DP-4, DP-6, plazos), y no afirma como construido nada decidido.
- P126-01 (Media): «DP-2 … se mantiene provisionalmente (C)» no tiene respaldo: lo firmado es A (LV-12) y, sin respuesta, el bloqueo de (e); C es solo la pregunta 2.8.
- P126-02 (Media): las condiciones de DP-3 en (h) no son las cinco de 3.5 y omiten «persona identificada del cliente» y «limitado a restablecer lo afectado».
- P126-03 (Media): DP-2 pendiente sin la marca de DF-02 (:5, :284, :300) ni la línea DF-01 «Pendiente de firma: DP-2» en la hoja; el barrido de DF-03 no está en (h).
- P126-05 (Media): «choque con T1-1 a T1-4» no coincide con D1 (API: T1-3 y T1-5; Migracion: T1-4 y T2-0).
- Bajas: orden N-1 y luego PR-4 (P126-04); «a quién afecta» de DP-1 es el ADMIN, no el SUPER (P126-06); custodio de DP-4 (P126-07); DP-5 es postura, no luz verde (P126-08); copiar F-5/F-6 a docs/decisiones (P126-09).
```

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica sobre el texto; el PR ya está unido)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pr126-firmas.md`
- Supuestos: no tuve acceso al chat de la firma; lo que dependía de él (la recomendación mostrada al propietario, la frase «T1-1 a T1-4») lo marqué *no verificable*; no ejecuté la guarda `ManifiestoAdr*`.
- Decisiones candidatas a ADR: Ninguna (DP-1, DP-3 y DP-5 las prepara el arquitecto-maestro cuando corresponda, como ya dice la consulta).
- Entregas a otros agentes: documentador técnico → P126-01 a P126-09 en un PR de seguimiento solo de documentos (con la marca de DF-02, la línea de DF-01 y el barrido de DF-03 en (h)); B → publicar el comentario en el PR #126 (unido) o en el de seguimiento.
- Próximo paso recomendado: el documentador corrige P126-01, P126-02, P126-03 y P126-05 antes de que el arquitecto-maestro prepare los ADR de DP-1, DP-3 y DP-5.
