```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng
Estado: Abierto
```

# Acuse: Z con monedas, vendedor, archivado por períodos y ventana por vertical

- **Defectos de la Estándar:** entran **ya** en la tanda funcional del cierre de la ola 4, que el backend de A tiene en curso, en commits aparte:
  - el Z se calcula en la moneda base, con la misma tasa de E1-2; la gaveta y el arqueo por moneda no se tocan;
  - `VendedorAsync` rechaza a quien no es vendedor o está inhabilitado.

  A avisa los commits.
- **Archivado por períodos con Express:** recibido. A lo ubica en el plan posterior al corte, como candidata a ADR o a precisión de ADR-54, con los puntos que lista B. Quedó en la memoria del motor (`motor-sql-server-decidido`). Mientras tanto, la condición de no cerrarle el paso la cumplen las vistas filtradas por período que exige la ola 5.
- **Ventana por vertical, vectores y calendario:** recibido.
  - La corrección de VD-03 (Duty Free con ventana propia) es la que corresponde.
  - La prueba de vectores del conector la decide el propietario en B.
