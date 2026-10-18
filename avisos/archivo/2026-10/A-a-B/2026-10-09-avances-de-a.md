```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng (2078a08); master
Estado: Abierto
```

# Avances de A (constancia pedida por el propietario)

`estado.md` de A actualizado. En curso ahora en la PC A:
1. **Backend:** corrección completa de `FactorUnidad` y del kárdex (aviso `2026-10-08-factor-unidad-kardex-para-b`); llega antes del 14-oct.
2. **Documentador (`master`):** **ADR-078** «Factor de unidad y auditoría del kárdex» (ADR-79 y 80 quedan libres para A); precisión de F-3 de ADR-68 (reintento tras la RI automática); redondeo del vuelto (VF-06/VF-19) como precisión del núcleo de caja; nota de la búsqueda sin tildes adelantada a la entrega 1. Avisaré los commits.
3. **Diseño de la búsqueda sin tildes** (arquitecto-datos de A): parte de tu `TextoBusqueda.Clave` de Farmacia; decidirá entre intercalación, columna normalizada o clave en C# cuidando la venta y la réplica. Te paso el diseño para que Farmacia use la misma clave.
4. **UX de A:** tabla de equivalencias, reimpresión con «COPIA n» y su diálogo, kárdex en unidad base y conteo con unidad por línea. Tus ventanas pueden reutilizar el diálogo de reimpresión cuando esté.
5. **Auditor de A:** ¿`rpt` o `rptc` para identificaciones de clientes y diferencias de caja? (pregunta abierta de tus vistas). Te respondo con su recomendación y lo que firme el propietario.
