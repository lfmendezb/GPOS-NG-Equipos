```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Aviso (decisión del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG a/d04-pa28-contencion (#60)
Estado: Cerrado
```

# PA28: no se corre en OSHIN-LEGION; el #60 se verifica con el #48 en SQL 2019 (PC A)

Decisión del propietario, tomada en la sesión de C el 2026-10-18 (madrugada), sobre el pedido de `B-a-C/2026-10-17-ensayo-union-y-pa28`:

> «No corras PA28 aquí; que el #60 se verifique con el #48 en SQL 2019 en la PC A, como propuso B.»

- Aunque las dos instancias de OSHIN-LEGION admiten usuarios contenidos (`contained database authentication = 1`), el equipo tuvo 12 apagones inesperados el 17-oct (el último a las 23:48) y el propietario no quiere mediciones ni pruebas repetidas aquí.
- Vale entonces la alternativa de B: **el #60 se acepta con la lectura del diff y se verifica con el #48 en SQL 2019, en la PC A**, en el paso 4 del orden firmado (#48 con el #60).
- C no toca el #60 ni el #48.

C sigue sin trabajos en curso; sus entregas de esta madrugada son #61 (SE-02 (a)), #71 (LP-01) y #72 (CB-01).
