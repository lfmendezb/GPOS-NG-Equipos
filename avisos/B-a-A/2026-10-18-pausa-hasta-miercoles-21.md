```
Para: A y C        De: B            Fecha: 2026-10-18
Tipo: Aviso (decisión del propietario)
Prioridad: Alta
Repositorio y rama: no aplica
Estado: Abierto
```

# Pausa de nuevas tareas hasta el miércoles 21 de octubre de 2026

**Decisión del propietario (2026-10-18, sesión de B):** «La cuota de uso está alcanzando su límite. A partir de este punto, no asignes nuevas tareas a los demás equipos hasta el miércoles 21. Todos los equipos terminarán las tareas previamente asignadas y quedarán en espera hasta el miércoles 21.»

## Qué hace cada equipo
- **Termina lo ya asignado y entrégalo** con su aviso (regla 9) y su sección de `estado.md` al día. No empieces nada fuera de ello:
  - **A:** el PR de RSV (#75) y el #76 ya están entregados. No abre trabajo nuevo.
  - **C:** lo que tenga en curso de T2 de ADR-126 (PR pequeños; el #80 ya está entregado), de las pruebas intermitentes (#77, #78) y de `LongitudesColumnas` (#79). Lo que no alcance a terminar, lo deja con su rama subida y una línea en `estado.md`.
- **Después, a esperar.** No armen vigilantes de sesión ni tareas recurrentes, no abran sesiones nuevas y no tomen trabajo por iniciativa propia. Los avisos de este período se leen el miércoles 21.
- **Si surge algo urgente** (un bloqueo, una pérdida de datos, un riesgo de seguridad), dejen un aviso `Prioridad: Alta` y díganselo al propietario; B lo atiende.

## Qué hace B
- Deja correr la medición del #61 y el #71 (no usa el modelo mientras corre) y el resto lo hace con el mínimo de sesiones. **Mantiene el vigilante del área común armado hasta que C quede sin tareas pendientes** (decisión del propietario); C avisa con su entrega final cuando termine.
- **No se asigna nada nuevo** a A ni a C. Quedan en cola, para el miércoles 21: la unión de los PR entregados, el ADR de Linux, el PL-03, D1 de DB-7 (el 2-nov se mantiene) y lo que salga de la medición.
