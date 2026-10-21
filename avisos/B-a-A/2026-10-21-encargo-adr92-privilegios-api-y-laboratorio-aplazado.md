```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Encargo (dos tareas nuevas) y aviso (laboratorio de ADR-90: hipervisor y aplazamiento)
Prioridad: Media
Repositorio y rama: ADR-92 en la rama `b/adr92-dp1-dp3-dp5` (PR #128, sin unir); N-1 en `b/n1-api-modo-servicio` (PR #127, `7afa929d`)
Estado: Abierto
```

# Encargo a A: preguntas técnicas de ADR-92 y operaciones de GPOS.Api como servicio

Su cola actual espera casi toda a B (PR-1b al #122, PR-4 al #127, el seguimiento del emisor al #103 y al PR #1). Estas dos tareas no dependen de nada y son de diseño, revisión y documentos: no necesitan SQL ni compilaciones largas (su PC es pequeña, `DEVLAB00`). Nada se une sin orden expresa del propietario.

## Tarea 1: preguntas técnicas abiertas de ADR-92
ADR-92 (solicitudes de los titulares y acceso del SUPER por caso) está firmado por el propietario (2026-10-20, P-1 (a)). Léanlo de la rama `b/adr92-dp1-dp3-dp5` (el #128 aún no se une a `master`): `docs/adr/ADR-092.md`, apartado «Preguntas técnicas antes de construir».
- **Para su arquitecto-datos:** TT-P1 a TT-P5 y CS-P2 a CS-P4.
- **Para su arquitecto-software:** TT-P6, CS-P1 y CS-P5 a CS-P7.
- **Entrega:** un documento en `traspasos/A/` con una respuesta propuesta por pregunta (la recomendación, la alternativa descartada y el motivo). B lo integra; **no es una decisión** y lo que cambie lo que ve o hace una persona va a firma del propietario.
- **Plazo:** **CS-P2 antes del 2026-11-02** (tipo y largo de las dos columnas del número de caso y su `CHECK`: la DDL de D1 de DB-7 depende de ella). El resto, antes del 2026-11-09.
- **Salvedad en TT-P1** (si la persona física se deduce por `TipoIdentificacion`: `C`, `P` y `N` física, `R` jurídica): si necesita criterio fiscal o contable, márquenla como pregunta para el especialista, no la inventen.
- **Para D1:** usen como base el DDL de D1 en `master` (`docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md`, rev. 2); no cambien nombres sin decirlo.

## Tarea 2: operaciones de GPOS.Api como servicio de Windows (N-1)
El #127 (N-1) deja la API corriendo como servicio `NT SERVICE\GPOS.Api` con `ModoServicioApi` (ver el comentario del #127 y mi aviso del 2026-10-21 sobre las franjas). **Falta lo que ADR-76 punto 2 exige por escrito antes de la primera instalación.**
1. **Documento de operaciones** de `GPOS.Api` como servicio (en `docs/operaciones/`; en `master` ya está el del instalador de Reportes, `2026-10-19-diseno-instalador-reportes.md`, como ejemplo de forma):
   - la lista de privilegios del token (`SeChangeNotifyPrivilege`, copiada de la estación y de Reportes) y la **justificación de cada uno y de los que falten**. La API lanza Chrome o Edge para el PDF (`ConvertidorPdf.cs`) y escribe en sus carpetas; hay que probar o razonar si necesita más;
   - cuenta virtual, `sc qprivs` exacto en la prueba de instalación, origen de eventos `GPOS.Api` (lo declara `GPOS.Api.msi`) y los EventId 4767 a 4770.
2. **Revisión de seguridad del #127** por su auditor-seguridad (en `traspasos/A/`): la comprobación de arranque (`ARRANQUE_IDENTIDAD` y `ARRANQUE_PRIVILEGIOS`), `IdentidadProceso`, el orden respecto de `ExigirArranque`, y el código de salida.
3. **Plazo:** antes del 2026-10-30.
- Esto no bloquea unir el #127 (no hay instalador de la API todavía); sí es condición antes de la primera instalación fuera del laboratorio.

# Aviso: laboratorio de ADR-90 (hipervisor y aplazamiento)
- **El propietario decidió el 2026-10-21:** VirtualBox, alojado en `LFMB` (equipo de B), con las VM **por bloques y no en paralelo** (la memoria de `LFMB` es de 13,9 GB). Ya no se usa Hyper-V; **la PC de A no se usa** (8 GB, 4 hilos).
- C rehace el diseño (tabla bloque → VM → memoria, vTPM y reloj en VirtualBox). No instalen VirtualBox ni bajen imágenes: lo pide B al propietario con nombre, origen y tamaño.
- **Aplazamiento:** el laboratorio no bloquea PR-1b, PR-3 ni PR-4; solo RT-02 a RT-04. B lo aplaza hasta que C entregue el rediseño y hasta fijar una ventana en que `LFMB` no esté en uso.
- **Pregunta para A:** **¿en qué fecha empezaría realmente RT-02?** Con eso B fija la ventana de la fase 1. Su estimación de 3 a 4 días hábiles era con las tres VM a la vez; por bloques tardará más, y A (con su QA) la recalcula cuando C publique el rediseño.
- **Quién opera y desde dónde** (el QA de A construye y ejecuta, pero `LFMB` es el equipo de B): B lo resuelve con el propietario; no lo den por supuesto.

# Lo que no cambia
PR-1b tras el #122, PR-4 tras el aviso de B de que el #127 está unido (retira `FijarEscuchaPorOmision`, ver mi aviso de revisión), el seguimiento del emisor tras el #103 y el PR #1, y N-10/VS-2/tanda 3 como estaban.

Respuesta requerida: acuse de las dos tareas con su fecha de entrega, y la fecha en que empezaría RT-02.
