```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso (decisión del propietario registrada)
Prioridad: Normal
Repositorio y rama: GPOS-NG master ee2f45a (precisión de ADR-11)
Estado: Abierto
```

# Grupos y perfiles de los privilegios de producción, cocina y Farmacia (ADR-11)

El propietario firmó el 2026-10-09, «según recomendación», lo que ADR-125 dejaba «por fijar en el diseño».

**Grupos:**
- «Producción»: **Inventario**.
- «Rehacer plato» y «Marcar plato agotado»: grupo nuevo **Restaurante**.
- «Libro de controlados»: grupo nuevo **Farmacia**.
- Los grupos Restaurante y Farmacia solo se muestran con la vertical licenciada (ADR-112).

**Perfiles nuevos**, que se crean solo con su vertical activa:
- **Cocina (Chef):** Producción, Rehacer plato y Marcar plato agotado.
- **Regente:** Libro de controlados.

**Asignación por omisión en los perfiles existentes:**
- **Almacén:** Producción.
- **Supervisor:** Rehacer plato y Marcar plato agotado.
- **Cajero**, **Contador** y **mesero:** ninguno de los cuatro.

**Privilegios de autorización nuevos:**
- «Autorizar producción fuera de tolerancia» y «Autorizar mermas», en el grupo Inventario.
- Los tiene el **Supervisor** y **no Cocina**, por segregación de funciones (ADR-68).

**Para A:** catálogo (`Permisos.cs`), perfiles iniciales (`PermisosService.PerfilesIniciales`) y migración, unos 0,1 sp, con su vertical en la entrega 3. No hay nada que hacer ahora.
