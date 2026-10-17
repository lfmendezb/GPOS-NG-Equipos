```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #61 c/serie-e-ecf @ 67a38771 (base feature/modelo-ng e80f4654); traspasos/C/2026-10-17-modo-lento-t28.md
Estado: Abierto
```

# Entregas de C: la serie E (PR #61) y la causa del modo lento de T-28

Cierra las dos tareas del aviso `2026-10-17-c-toma-modo-lento-t28-y-serie-e`.

## 1. Modo lento de T-28: no viene del código del candidato (`traspasos/C/2026-10-17-modo-lento-t28.md`)
- **Causa, verificada en OSHIN-LEGION:** el modo lento aparece cuando los hilos del proceso de prueba corren en los mismos núcleos físicos que el Express, es decir, en los hermanos de hiperhilo de sus planificadores. Midiendo con la afinidad del cliente, con el mismo código:
  - con el cliente en otros núcleos (`FF00`): p95 de 30,1 a 33,0 ms;
  - con el cliente en los núcleos del motor (`00FF`): p95 de 37,3 a 40,9 ms. Tiene la misma firma que vio B: todas las sentencias suben de forma uniforme y crece la espera de CPU dentro de `PAGELATCH` y `LCK_M_U`.
- **Base frente al candidato, con la ubicación controlada: iguales.** Con `FF00`, la razón es **0,991**. El reparto de LFMB, 6 de 9 frente a 1 de 7, da p ≈ 0,055 (Fisher), compatible con el azar.
- **Descartadas:**
  - pestillos en llaves crecientes: los mismos objetos en los dos lados, menos de 0,5 ms por venta;
  - spinlocks;
  - el grupo de hilos y `Monitor` del cliente;
  - dos sesiones en el mismo planificador.
- **Propuesta, para el banco y no para el producto:** `GPOST_B9_AFINIDAD=auto` en las cargas de T-28, T-57 y N6-02.
  - Fija el proceso de prueba a las CPU que no usa el motor, según `sys.dm_os_schedulers`.
  - Informa la CPU de sentencias y la espera de CPU por venta, para saber en qué modo cayó cada corrida.
  - Medido aquí: elimina el modo lento y deja la dispersión en ±5 %.
  - Exige más CPU lógicas que las del Express. Hay que comprobarlo en LFMB; si no las tiene, queda la regla 7.3 informando el modo de cada corrida.
  - Con la afinidad hay que volver a medir también la base.
- **Inferido, no medido:** que LFMB tenga el mismo mecanismo, y que la instalación pequeña, con la API y el Express en el mismo equipo, también lo sufra. No se recomienda afinidad en producción sin medirla con la API real.

## 2. Serie E: PR #61 (`c/serie-e-ecf` @ `67a38771`, sin unir)
- Con el e-CF activo (bloques E vigentes y sin contingencia), la venta POS y la Factura CxC emiten el tipo E del cliente: 01→31, 02→32, 14→44, 15→45 y **16→46**, que el propietario aprobó. En contingencia vuelven a B.
- Un tipo B elegido a mano fuera de contingencia se rechaza con un mensaje neutro. Con el e-CF activo, el selector del POS solo ofrece tipos E. Los avisos de la caja revisan E32 y E34.
- **Defecto previo, Alto, corregido en el mismo PR:** toda venta POS con un tipo E y artículos inventariables fallaba en `feature/modelo-ng` (`Must declare the scalar variable "@lote_falta"`). Revisarlo con quien mantiene V1 de rendimiento.
- **Pruebas:** `SerieEFacturaTests` es nueva (17 casos). Las dirigidas dan 339 correctas y 0 fallidas en `.`. **No se corrió la suite completa.**
- **Para decidir:**
  - el filtro del selector a solo E;
  - si un tipo E elegido a mano se rechaza en contingencia (hoy se admite).
- **Rendimiento:** solo hay un viaje de lectura más con el e-CF activo, y únicamente sin tipo elegido o con un tipo B elegido. Sin medir en T-28.

## C queda
Sin trabajos en curso. Espera el siguiente encargo.
