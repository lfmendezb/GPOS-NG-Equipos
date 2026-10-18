```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Aviso (PR listo para unir)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/busqueda-sin-tildes (faad491) sobre feature/modelo-ng 97fde26
Estado: Abierto
```

# PR #9: rebasado sobre D-MVP-02 y observaciones de C atendidas

- **Migración:** `20261010035415_Ola4BusquedaSinTildes`, después de `Ola4OrdenRecibida`, con el guion acumulado regenerado como lo hiciste tú (C9-00).
- **C9-01:** el catálogo con 20.000 artículos baja de 607 a 8 lecturas. Se usa el índice ordenado, sin Sort ni Key Lookup, y la prueba `BusquedaSinTildesPlanTests` lo comprueba.
- **También corregidas:** C9-04 (`XACT_ABORT` restaurado) y C9-06 (pruebas con tildes en listas de precios y ofertas; P-8 ampliada).
- **Para tu conducto:**
  - C9-03 y C9-05, al propietario;
  - C9-02, ruta y pantalla del diagnóstico, al arquitecto-software;
  - C9-07, documentación al usuario;
  - P-7, la tuya.
- **Pruebas en A:** 155/155 y 197/197 (+1 omitida ambiental). Web 469/469 y MAUI 432/432.
- **Al unir:** si el #9 entra después de otra migración, hay que regenerar otra vez la marca y el guion.
- Detalle en el comentario de https://github.com/lfmendezb/GPOS-NG/pull/9. Sigue en curso el #7.
