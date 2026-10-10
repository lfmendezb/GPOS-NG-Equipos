```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Encargo y decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng e3a1d2b
Estado: Abierto
```

# MVP: línea base, D-MVP-01 para A y la reimpresión en el camino crítico

**Línea base (QA de B, `e3a1d2b`, pruebas `tests/GPOS.Tests/Mvp/`, rasgo `Categoria=Mvp`):** F1 a F8 funcionan de punta a punta por la API real y el cliente web, en Express y Standard. Cuentan hoy **6 de 10**: F1, F2, F4, F5, F6 y F8.
- **F3** no cuenta por D-MVP-02 (Alto): una orden recibida con entrada y luego facturada duplica la existencia. El propietario aprobó la dirección: la factura de una orden ya recibida no vuelve a mover la existencia; solo CxP y ajuste de costo. Lo construye B tras el criterio del especialista contable.
- **F7** no cuenta hasta que exista la **reimpresión de facturas** (decisión del propietario del 2026-10-09: la impresión del Z guardado no basta).

## Para A
1. **La reimpresión de facturas (tu tarea 3, núcleo de caja) pasa al camino crítico del MVP del 1-nov.** Prioridad sobre la búsqueda sin tildes si no da tiempo a las dos. La parte de interfaz puede empezar ya; la de servidor que toca `PosService` va después de T4 (ADR-68), salvo que propongas un corte que no choque.
2. **D-MVP-01 (Media), nueva tarea 5:** «Debe cambiar la contraseña al entrar» solo lo exige la interfaz (`Login.razor:235`); el claim se emite en `Seguridad.cs:73` pero ninguna política lo aplica, y por la API el usuario trabaja con la clave inicial. Esperado: 403 (con código que la interfaz reconozca) en todo lo que no sea cambiar la clave o salir, hasta que la cambie. La prueba `F1_D_MVP_01_…` (marcada `Transicion=Defecto`) lo reproduce: al corregir, quita el rasgo. Rama `a/d-mvp-01`, PR a `feature/modelo-ng`.
