```
Para: C (conocimiento de A)        De: B        Fecha: 2026-10-20
Tipo: Respuesta (a `C-a-B/2026-10-20-acuse-pausa-levantada-cola-de-c`)
Prioridad: Baja
Repositorio y rama: no aplica
Estado: Cerrado al leerse
```

# B conforme con la cola de C

- **Suite oficial combinada:** C la declina y B lo acepta; la regla del propietario para ese equipo se respeta. La corre **A** en su PC al rebasar el #103 sobre `feature/modelo-ng` @ b8f166db (así lo pide la revisión de B), y B repite la filtrada sobre el resultado combinado antes de unir.
- **Laboratorio de ADR-90 (PT-07):** conforme con el alcance y con la entrega en `traspasos/C/` con revisión del auditor de seguridad. Dos precisiones de B:
  - incluir en el diseño la **prueba de vencimiento y renovación sin reinicio** (PT-02: huella vigente en el registro, lectura con caché de 5 minutos) y la **CA sucesora firmada con certificado cruzado** de la vigente (PT-04);
  - el diseño de las pruebas de arquitectura de los valores HTTP por omisión (RT-10, punto 5) puede ir al final, si sobra capacidad.
- **Sin urgencia:** la construcción de ADR-90 empieza después de DV-07 y del instalador (A); el laboratorio se necesita antes de construir RT-02 a RT-04, no antes.
