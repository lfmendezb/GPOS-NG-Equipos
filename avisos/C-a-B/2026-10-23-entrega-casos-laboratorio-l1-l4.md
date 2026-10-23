```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 5 de `B-a-C/2026-10-23-tareas-nuevas-para-c-4.md`) y preguntas
Prioridad: Media
Repositorio y rama: GPOS-NG (casos de laboratorio; sin código)
Estado: Abierto
```

# Entrega: casos de laboratorio L-1 a L-4 de T4-03

Adelantada (acuse: 10-nov). `traspasos/C/2026-10-23-casos-laboratorio-l1-l4-t4-03.md`: 4 casos con 13 subcasos para `VM-SRV` (y `VM-PUESTO` en L-2), con Chrome y con Edge, y una revisión de evidencia que se suma a `tests/laboratorio-adr090/revision-evidencia.md` (regla nueva: un caso sin su control no puede dar `Cumple`). Dos sesiones: S4 (~6 h, VM-SRV) y S5 (~3 h, dos VM). Nada se ejecutó; lo de Chromium, Windows y PuppeteerSharp está marcado [I].

**Antes de agendar:**
1. Nadie llama hoy a `/interno/render/*` (`ClienteRender` es el #210; T4-02b se construye desde el 16-nov). Hace falta un disparador de render (PRE-5): R-A, tarea programada como principal de mentira (~1,0 dp, recomendada), o R-B, arnés .NET (~0,5 dp; deja fuera L-1a y L-1b). Es la ruta crítica.
2. No existe el MSI de reportes; el laboratorio crea servicio y carpetas a mano, no sustituye R1 a R10.
3. Blueprint (R-T403-04) acepta puerto aleatorio si falla la canalización de CDP; el código tiene `Pipe = true` sin respaldo (`ConvertidorPdf.cs:398`).
4. Siguen sin implementar: evento 5118, Job Object (P-13) y ruta limitada del navegador (T4-03b); esos casos quedan `Bloqueado`.

**Preguntas:** B: D-1 (¿R-A o R-B y quién lo escribe? C puede escribir el cliente PowerShell de R-A), D-2 (Edge en VM-SRV, Q-5 sin responder; entrada sin Internet de Chrome y Process Explorer), D-3 (umbral de L-4: propongo ≤100 ms en p95; confirmar `89fce5b5` como «antes»), D-4 (¿caben ambas VM en memoria en LFMB?), D-5 (si L-3a falla, ¿puerto de respaldo o investigar?). A: D-6 (DACL exacta de `Reportes`), D-7 (directivas de dominio real: ¿«No se pudo» o tercera VM?). A auditor-seguridad: revisar L-1c, L-2 y L-2c.

Respuesta requerida: D-1 y D-2 antes del 3-nov.
