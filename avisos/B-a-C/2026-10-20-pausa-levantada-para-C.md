```
Para: C        De: B        Fecha: 2026-10-20
Tipo: Encargo (el propietario levanta la pausa por cuota)
Prioridad: Media
Repositorio y rama: GPOS-NG master 45a9ab75 y origin/feature/modelo-ng b8f166db
Estado: Abierto
```

# C queda habilitado

El propietario escribió el 2026-10-20 en el chat: «Levanto la restricción que impone un alto hasta el miércoles 21». A ya estaba habilitado desde la mañana; con este mensaje queda levantada la pausa del 2026-10-18 (`2026-10-18-pausa-hasta-miercoles-21`) para todos los equipos. Mantengan el límite de sesiones de `limite-agentes-pc-b` y el modelo por agente vigente.

## Cola propuesta por B (C la contrasta con su sección de `estado.md` y publica la suya real y su orden en `C-a-B/`)
1. **Suite oficial sobre el resultado combinado** cuando A rebase el PR #103 (DV-07) sobre `feature/modelo-ng` @ b8f166db (PR #105 unido: ya no falla `PruebasNeutralesTests`). Filtro vigente `Transicion!=Ola5&Transicion!=Defecto`.
2. **Diseño del laboratorio de ADR-90** (firmado hoy; PT-07): `X509Chain` de .NET con Name Constraints (incluidas IP y CN vacío), CA fijada que excluye al almacén del sistema, vencimiento y renovación sin reinicio, y los móviles como fase posterior. Solo diseño; la construcción depende de A y de B. Insumos: `docs/adr/ADR-090.md`, `docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md` y `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` (en `master`).
3. **Lo que C ya tenía en curso** (pantallas web, pruebas T-n, R-5, acta firmada por GSF): C lo declara en su respuesta; B no lo reasigna.

## Qué no es de C ahora
Nada que toque `Program.cs` de la API (zona de DB-7 de B) ni el reparto de ADR-90 (A: API, Web, `tls`, agente en modo estación, MAUI en Windows; B: paquete único).
