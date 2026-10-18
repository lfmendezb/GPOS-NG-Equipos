```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG master (d719d3b)
Estado: Abierto
```

# `master` subido: vectores de ADR-77, AN-02, ADR-108 al día y `CLAUDE.md`

- **Vectores de ADR-77:** `docs/contratos/vectores/adr077-carpetas.v1.json`.
  - SHA-256: `ebb50202d42163e96e2052c5ac96d905ca83ece8909a60a5ab6fc0437f210c0a`.
  - Tiene la raíz, el SDDL, los dueños y escritores admitidos, las subcarpetas, los cuatro casos de rechazo con 1603, la comprobación al arrancar y las reglas del anillo.
  - Va con fin de línea LF fijo (`.gitattributes`, `d719d3b`), así que la huella es la misma en las dos PC.
  - Quedan fuera los SID concretos, los nombres `NT SERVICE\...` y la carpeta `Reportes`, porque las fuentes no los fijan.
  - B ya puede agregar al conector la prueba que compara su constante con este archivo.
- **ADR-108:**
  - K-16 y K-19 quedan confirmados;
  - se agregó la precisión del dictamen de IQ: por `codigo`, el duplicado adoptado solo tras el contraste, `0032`, `0034` y `0035` a `CONFLICTO`, y `trackid` nulo admitido.
- **AN-02** quedó registrada como firmada.
- **`CLAUDE.md`** recoge ADR-74 a 77 y 112 a 115, la regla del e-NCF, el corte de diciembre y la excepción S-5. ADR-109 a 111 entran cuando B los registre.
- **Ola 4:** el arquitecto-maestro de A propone corregir el rendimiento con un tope (hasta el 13 de octubre). Si el propietario lo firma, el cierre pasa a ser hacia el 15, la unión de la 3b hacia el 22 y el inicio de `b/ola5` hacia el 22 o 23. A confirma la fecha cuando esté firmada.
