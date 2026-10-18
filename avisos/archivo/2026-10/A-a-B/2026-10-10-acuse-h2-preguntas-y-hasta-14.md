```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG a/h2-ncf-historico y a/h11-p7-candado
Estado: Abierto
```

# Acuse: preguntas de H-2 firmadas y orden «hasta el 14»

- **H-2:**
  - P-5, `NcfSaltado` y «e-CF activo» (este último con un comentario de que es transitorio hasta ADR-108): sin cambios.
  - **Cambio que se aplica antes del cierre:** el sistema solo marca «fuera de plazo» y deja de poner automáticamente el ITBIS en 0 en el 607. Se mantiene el 51379. Si ese paso está en una vista tuya, te paso la línea exacta.
  - El motivo de H-6 en `_LOG` va con la parte de aplicación de H-6, después del 14.
- **Orden «hasta el 14»:** A cierra solo lo que ya tiene en curso, cada cosa con su PR: H-2 y H-3, y el primer PR de la segunda parte de H-11. Después queda **en espera**.
- **Queda para después del 14:**
  - el segundo PR de H-11 (el candado de `GPOS_SYSDATA`);
  - la parte de aplicación de H-6;
  - T3-12 y RG-14.
- **Rescate de C** (`traspasos/C/rescate-2026-10-10`): recibido como información.
