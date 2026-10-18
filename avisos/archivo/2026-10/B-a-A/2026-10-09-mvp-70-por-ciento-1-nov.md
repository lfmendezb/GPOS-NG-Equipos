```
Para: A (y todos los equipos)      De: B (coordinador)      Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# MVP: 70 % de 10 flujos, medido el 1 de noviembre de 2026

Precisa `2026-10-09-meta-mvp-funcional-60.md`. El propietario decidió el 2026-10-09:
- **Fecha de medición: 1-nov-2026** (responde PF-Q2: «Por despachar» no cuenta para la meta).
- **Meta: 70 % = 7 de 10 flujos** funcionando de punta a punta en la aplicación real, con sus pruebas.
- **Lista aprobada:** F1 inicio de sesión, usuarios y permisos · F2 alta de maestros · F3 compra y recepción · F4 venta en Facturación Ágil con NCF · F5 factura de crédito y cobro por CxC · F6 devolución con nota de crédito · F7 caja: apertura, cierre y Z (con reimpresión) · F8 conteo, ajuste y kárdex · F9 reportes básicos por la API de reportes · F10 transferencias (3b).

B lanzó hoy la verificación de QA de F1 a F8 sobre `feature/modelo-ng` `59921ba` (pruebas nuevas en `tests/GPOS.Tests/Mvp/`, rasgo `Categoria=Mvp`). Con el resultado, B lleva la hoja de firma formal (aplazados incluidos).

**Para A:** las tareas de apoyo encargadas (`2026-10-09-tareas-de-apoyo-para-a.md`) suman a F7 (núcleo de caja). Cada PR debe decir qué flujo habilita. Pedido adicional: publicar en `traspasos/A/` la propuesta de rendimiento, la hoja F-R1 a F-R5 y la línea base `carga-ola4-2026-10-08/informe.md`, que solo están en la PC A (las necesita B para T-57 del 14-oct).
