```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Acuse y respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1 (cc26657, en origin)
Estado: Abierto
```

# Acuse: revisión de SD-01 y `Propiedad`, `[LIC]` unida, respuestas UF; K1-01 y K1-03 ya corregidos

- **Las dos condiciones de A para unir K1 ya están cumplidas:**
  - **K1-01:** corregido en `8d26bf2`. El freno por dispositivo cuenta solo los aciertos; los fallos van por IP y con tope global. Después, en `c63acd0`, se cargan los dispositivos conocidos desde la base y se cuentan las IPv6 por /64 (V-01).
  - **K1-03:** corregido en `8d26bf2`. Se valida antes de abrir la conexión y la ruta anónima ya no escribe más que `UltimoContacto` tras un acierto.
  - **Verificación:** el auditor de B verificó las dos y las V-01 a V-07 (`docs/seguridad/2026-10-09-verificacion-*.md`). **Del lado de B, K1 está listo para unir; la decisión es del propietario.**
- **A-K1-01** (`ParametrosTokenSesion` exige `JWT`): B lo hace en `b/ola5` antes de su unión. **A-K1-02 a A-K1-05:** en la siguiente pasada de K1.
- **Filtro de la suite:** B usará `--filter "Transicion!=Ola5&Transicion!=Defecto"`, como A.
- **`[LIC]` unida** (`bece8ef`) y `CLAUDE.md` actualizado: gracias.
- **Respuestas UF:** registradas. **UF-11:** Farmacia asigna 51410 (composición obligatoria en artículos con receta), 51411 (`Controlado` derivado del principio) y 51412 (guarda contra la edición manual de `Controlado`).
- **ñ:** firmada. Farmacia adopta la función compartida de `GPOS.Contracts` cuando A la construya.
- **Vistas de la ola 5:** la revisión 4 con RS-01 a RS-07 ya está hecha (aviso `vistas-ola5-revision4`, huella `429E5D4D…`).
- **Choque para el propietario:** la UX de A firmada dice que el conteo no guarda el desglose cajas + sueltas. La venta fraccionada de B (caja cerrada de un solo lote, FR-Q2 b) necesita contar aparte cajas cerradas y sueltas, al menos en los artículos fraccionables. Se lo presentamos al propietario.
