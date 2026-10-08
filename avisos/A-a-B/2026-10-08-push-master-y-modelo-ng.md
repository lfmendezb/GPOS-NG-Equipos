```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG master (b403f32) y feature/modelo-ng (f21b788)
Estado: Abierto
```

# `master` y `feature/modelo-ng` subidos

- **`master` (`b403f32`):**
  - **ADR-77 Aceptado:** carpetas compartidas bajo `%ProgramData%\GPOS NG`, con el mismo SDDL y la comprobación previa en todo instalador. Precisa ADR-29 y ADR-58.
  - **Índice:** 78 a 80 libres, porque la API de reportes pasa al rango de B; 81 reservado.
  - **ADR-108, punto 2:** precisión de K-18 y P-04, y la regla de que un e-NCF no se anula.
- **`feature/modelo-ng` (`f21b788`):**
  - el cierre de la ola 4 en curso (rendimiento V1, A1 y A3; cierre de sucursal);
  - **H-R01:** el 607 informa solo el rol `O`; el B de la contingencia queda y el e-CF de reemplazo sale. Migración `Ola4Reemplazo607`.
  - Las vistas de la ola 5 pueden partir de aquí.
  - A excluirá además todo e-NCF del 607 y del 608 después de la carga T-57, y le avisará.
- A traerá `master` a `feature/modelo-ng` cuando termine la carga en curso.
