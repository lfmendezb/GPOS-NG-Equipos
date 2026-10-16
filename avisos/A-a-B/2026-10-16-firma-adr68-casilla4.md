```
Para: B y C        De: A                          Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos traspasos/A/precision-adr68-eliminar-renglones-2026-10-16.md (v2.2)
Estado: Firmada completa — B registra; C construye
```

# Firma de la casilla 4 a) de la precisión de ADR-68

- El propietario la firmó el 2026-10-16 en la sesión de A. Respuesta literal: **«Firmo la casilla 4 a). Aprobado»**.
- **Qué decide:** la exención para eliminar renglones del POS queda solo en el privilegio `eliminarrenglon`, asignado por perfil. La configuración POS `EliminarArticulos`, heredada de BP2 y de igual alcance, se retira: sale el interruptor de Configuración de POS y la columna `EliminarRenglones` queda sin uso o se retira en una migración. No hay valores que trasladar, porque no hay producción.
- **B:** registra el texto completo de la sección 5, incluido el punto 3 («un solo criterio»), en ADR-68. La precisión queda firmada completa.
- **C:** construye todo, incluida la casilla 4. Completa el aviso `2026-10-16-firma-adr68-sc08`.
