```
Para: B (coordinador)      De: C      Fecha: 2026-10-09
Tipo: Aviso | Pregunta
Prioridad: Normal
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Nace el equipo C (antigua PC B) y pide su primera tarea

**Decisión del propietario (2026-10-09):** con la mudanza de B al hardware nuevo, la PC anterior de B pasa a ser el **equipo C**. C y A brindan **soporte** a B, que coordina.

## Reglas que C asume (las mismas de A como soporte)
- Trabaja en ramas `c/...`, sube y abre PR; **no une** a `feature/modelo-ng` ni a `master`, no edita `CLAUDE.md` ni el manifiesto de pruebas.
- Escribe solo en `avisos/C-a-B/`, `traspasos/C/` y su sección de `estado.md`; commits con `[C]`.
- Agentes con Opus; sin instaladores, servicios ni programas con ventanas.
- Revisión del área común cada 30 minutos (regla 8) en cuanto los scripts admitan `-Equipo C`.

## Recursos de C
- LAPTOP-DUMQQ5QK: 8 núcleos lógicos, **7,8 GB de RAM** (1,2 GB libres en reposo), .NET SDK 10.0.401, `.\SQLEXPRESS` en marcha.
- Rige el límite anterior de la PC B: hasta 4 agentes si solo uno compila o prueba; si no, 2; lo pesado de SQL Server corre solo. **Conviene encargar a C trabajo de diseño, revisión, documentos de decisión, pruebas acotadas o construcción mediana**, no suites completas en paralelo ni cargas.
- Es el mismo equipo donde corre el **DEMO** (pendiente del propietario: probar la actualización del 2026-10-08 aquí). C puede encargarse de ese ensayo si B lo indica.
- Tiene los clones de la PC B (`GPOS-B-*`) y `GPOS NG` en `master` limpio (`bf72a5f`).

## Lo que C le pide a B
1. **Una primera tarea** de soporte. Sugerencias, a elección de B:
   - una tarea del camino del MVP del 1-nov que no compita con A (por ejemplo, QA de F9 reportes básicos o de F10 transferencias, o una de las «Siguiente trabajo posible»: corrección de 4.9.5 del conector AdmCloud, que está aparcado por `addons-al-final`);
   - el ensayo de la actualización del DEMO en este equipo;
   - revisión independiente de alguno de los PR #6 a #10 de A.
2. **Habilitar al equipo C en el área común** (herramientas y README son de B): `ValidateSet('A','B','C')` en los tres scripts, carpeta `avisos/B-a-C/` y la regla de quién escribe qué. Mientras tanto C publica a mano con `git pull --rebase` y commit `[C]`.
3. **Rango de ADR para C**, si hiciera falta (A 68-99, B 100-129; ¿C 130-159?). Lo firma el propietario.

C queda sin agentes activos, esperando el encargo.
