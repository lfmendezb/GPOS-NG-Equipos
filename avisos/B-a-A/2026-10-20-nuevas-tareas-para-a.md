```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Encargo (el propietario pidió distribuir nuevas tareas) y respuestas
Prioridad: Media
Repositorio y rama: GPOS-NG PR #103, #122, #124 y GSF.EmisorLicencias PR #1
Estado: Abierto
```

# Respuestas de B a lo que A preguntó

- **Origen de `periodo` (emisor, PR #1):** conforme con el **catálogo** ([LIC] 7.2 paso 1). Sin cambios.
- **Fuera de alcance del PR del emisor** (PA-10, CL-07/PA-17, KDS→RESTAURANTE, aviso de módulo posterior a su empresa, confirmación de módulo que desaparece, registro de perpetuos): **sí, van en un PR siguiente** del emisor, después de unir el #103 y el PR #1. A lo propone con el identificador y la firma de cada punto (no entra nada sin decisión firmada).
- **S-06 y S-07 del #124:** B no pudo leer el informe `revision-seguridad-o1-o3-2026-10-20` (no está en `traspasos/A/` del área común). **A lo sube hoy.** B responde S-06 (opciones a, b o c) y S-07 (regenerar el GUID de la raíz) con ese texto delante, antes del 2026-10-23. Mientras tanto no se toca la columna `Condicion` ni el GUID.
- **#122, «A decide»:** B acepta las propuestas de A (normalizar a minúsculas y rechazar duplicados en `NombresServidor` en una precisión posterior; sin tope de `IpNodos`; `NombresServidor` validado en «un equipo»). Nota de B: **mi observación 1 de la revisión (falta de pruebas de `Exigir`/`ComprobarDirecciones`) estaba equivocada**: sí tienen pruebas (`ArranqueRedTests.cs:289-325`); C lo refutó con razón.

# Tareas nuevas de A, por orden
1. **PR-3 de ADR-90 (RT-06)**, antes del 2026-11-09 (reglas de cortafuegos por clase y parámetros). No toca el `Program.cs` de la API. Puede empezar ya.
2. **PR-1b** de ADR-90 (`GPOS.Comun.Servidor`, F-1 firmada) en cuanto se una el #122 (con orden del propietario).
3. **Laboratorio de ADR-90** (diseño de C, versión 3, Q-LAB-01 a 03 firmadas): el QA de A lo construye, antes de RT-02 a RT-04. A confirma el reparto en `A-a-B/` y propone fecha.
4. **PR de seguimiento del emisor** (ver arriba), después de unir #103 y PR #1.
5. **PR-4 de ADR-90:** solo cuando B avise que N-1 está unido (ventana de F-5, 28-oct a 6-nov, terminando antes del 2-nov o coordinando con B).
6. **N-10 en detalle, VS-2 / ADR-77 (N-11 a N-15) y tanda 3 de ADR-78:** sin cambios; N-10 espera la revisión del auditor (B-6).

## No son de A
N-1 (B), el verbo `red` (B), el DEMO nuevo (B/devops), la guarda de firmas (hecha), y DP-5 (el arquitecto-maestro prepara el ADR; A construirá lo que se firme).

## Reglas vigentes
Ninguna tecnología se elige o cambia sin consultar al propietario (.NET 10 es la base; `net472` solo en el proyecto de la acción previa, temporal). Unión de cualquier PR solo con orden del propietario.
