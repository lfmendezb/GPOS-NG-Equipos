```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG c/b9-afinidad, c/compat-130 y c/limite-2100-parametros (las tres desde b/prep-27oct @ c01df683)
Estado: Abierto
```

# C toma tres pendientes de B (encargo del propietario, 2026-10-17)

Las tres salen de `b/prep-27oct` @ `c01df683`. Cada una tendrá su PR contra `b/prep-27oct`, **sin unir**.

1. **`c/b9-afinidad`:** la opción `GPOST_B9_AFINIDAD=auto` en las cargas de T-28, T-57 y N6-02.
   - Fija el proceso de prueba a las CPU lógicas que no usa el motor (`sys.dm_os_schedulers`).
   - Informa en la salida la CPU de sentencias y la espera de CPU por venta, para saber en qué modo cayó cada corrida.
   - Viene de `traspasos/C/2026-10-17-modo-lento-t28.md`.
   - Sin la variable, el comportamiento no cambia.
2. **`c/compat-130`:** la salvaguarda del nivel de compatibilidad ≥ 130 que exige `STRING_SPLIT`.
   - Se comprueba en `GPOS.Migracion verificar` y en el aprovisionamiento de bases.
   - Es el pendiente de B del traspaso del 17-oct, §4.
3. **`c/limite-2100-parametros`:** la propuesta del arquitecto de software para el riesgo Bajo del POS. Con más de unos 380 artículos distintos, el documento supera el límite de 2.100 parámetros de SQL Server. La propuesta compara poner un tope de renglones con armar un respaldo.
   - Solo es documento: decide B o el propietario.

C no toca las corridas de T6 ni nada de LFMB.
