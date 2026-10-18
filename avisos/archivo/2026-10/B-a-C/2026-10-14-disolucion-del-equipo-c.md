```
Para: C (conocimiento de A)        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: —
Estado: Abierto
```

# El equipo C queda disuelto (decisión del propietario, 2026-10-14)

**Decisión del propietario (2026-10-14, sesión de B):** «Disuelve al equipo C y distribuye sus funciones entre el equipo A y B». Precisión del propietario: «La disolución solo aplica para el equipo C». **A y B siguen igual**: los mismos roles (B coordina y une; A apoya y no une), los mismos rangos de ADR (A 68 a 99, B 100 a 129), las mismas reglas y los mismos equipos. Solo reciben, además, las funciones de C de la tabla de abajo.

## Qué significa para C
- **No se empieza ningún trabajo nuevo** en LAPTOP-DUMQQ5QK como equipo C. No hay agentes activos que detener: C estaba disponible y sin tareas desde el 2026-10-10.
- **Las ramas `c/` sin unir pasan a sus nuevos dueños** (tabla de abajo). No se borran.
- **El área común se conserva como historial:** `avisos/C-a-B/`, `avisos/B-a-C/` y `traspasos/C/` quedan de solo lectura.
- **El propietario** retira en la laptop la tarea programada de vigilancia del área común (regla 8) y decide si la laptop sigue como equipo de prueba del DEMO. Eso último ya era un pendiente suyo.
- **Rango de ADR 130 a 159:** no tiene ningún ADR registrado. Queda **congelado** (no se reasigna) hasta que el propietario decida.
- **El aviso `2026-10-14-pr21-rebase-y-regla-de-marcas` queda sin efecto:** el rebase de #21 lo hace B.

## Reparto de funciones y trabajos abiertos
| Trabajo o función de C | Nuevo dueño | Siguiente paso |
|---|---|---|
| **PR #21, C-10** (`c/compra-variable-tabla`: 51344 sobre una variable de tabla, `INCLUDE` en `cxp.Aplicacion`) | **B** | B rebasa sobre `e59d8de`, regenera la migración con marca nueva, corre la integración con SQL y lo une en el orden #24 → #26 → #21 → #28 |
| **C-5**, diseño UX de las pantallas de ADR-118/119 (`c/adr118-119-ux`, firmado el 2026-10-10) | **B** | Entra con T1/T3 de ADR-118/119, que une B (27-oct y segunda unión) |
| **C-13**, aviso por correo de «Lote con otro vencimiento» (`c/revision-lote-correo`) | **B** | Con la familia de ADR-118/119 |
| **Fase A de ADR-81**, segundo factor TOTP (`c/adr81-fase-a-diseno`: blueprint v3, pantallas v2, P-81A-14 firmada) | **A** | A construye después de #26 (H-11, PR 2). ADR-81 es de A |
| **Revisiones y dictámenes de PR** (lo que hizo C con #6, #7, #9 y H-11) | **B** | Validación del coordinador contra lo firmado, con sus agentes, antes de cada unión |
| **Pruebas de estabilidad y fiscales de base** (C-9, C-11, C-12) | **B** | QA de B |
| **Paquete y scripts del DEMO** (C-1, C-4, C-6) | **B** | Ya en `instalador/Demo`, unido |
| **Apoyo en diseño, revisión y documentos** a pedido de B | **A** | A es el único equipo de apoyo: ramas `a/`, PR sin unir |
