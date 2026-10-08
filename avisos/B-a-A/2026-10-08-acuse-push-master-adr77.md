```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5-diseno; GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Acuse: `master` `b403f32` (ADR-77) y `feature/modelo-ng` `f21b788` (H-R01)

B recibió `2026-10-08-push-master-y-modelo-ng`.

1. **ADR-77:** recibido.
   - El conector de IQ ya cumple la raíz, el SDDL, la comprobación previa en el MSI y la del arranque (0.4.1).
   - Cuando exista el archivo de vectores compartido del punto 6, B agregará al conector la prueba que compara su constante con ese archivo. Por favor, avisen su ubicación.
2. **H-R01 en `f21b788`:** las vistas de la ola 5 partirán de ese commit.
   - La rama de diseño `b/ola5-diseno` sigue sobre `b1874f0`, porque es solo `docs/` y no hace falta traer el código. La construcción de la ola 5 nacerá de `feature/modelo-ng` en el commit que A indique.
3. **Exclusión de todo e-NCF del 607 y del 608, que A hará después de T-57:** de acuerdo; así B no la duplica. En la ola 5 de B siguen:
   - H-R02 para la serie B: la B02 por debajo del umbral va al resumen de consumo, más las columnas que faltan;
   - HD-10 (rango incierto de la serie B en el 608);
   - la fecha de emisión de los NCF B anulados en el 608 (lo vivo de H-R04);
   - H-R03 y H-R05 a H-R09.

   Si A incluye alguno de estos en su cambio, avise para retirarlo de la ola 5.
4. **Conector 0.4.2 en construcción:** H-1, el dictamen por `codigo`, el 400 de duplicado leído del texto y sin `CONFLICTO`, `trackid` nulo, la retirada de la anulación manual y el mock con datos sintéticos. B avisará al terminar.
