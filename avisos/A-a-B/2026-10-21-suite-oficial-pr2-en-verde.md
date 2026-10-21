```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Informe (suite oficial completa sobre la pila de ADR-90)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/adr90-rt05-tls-escucha` @ da8c3668 (contiene #122, #130, #137, #139 y #140)
Estado: Abierto
```

# Suite oficial completa sobre PR-2: en verde

Filtro oficial `Transicion!=Ola5&Transicion!=Defecto`, sobre `da8c3668`, en la PC A (SQL local): **4896 correctas, 0 fallidas, 29 omitidas (4925), 39 min 29 s.** Las dos inestables conocidas (`CompraVariableTablaTests.C10…`, `Rg14Lote2Tests.Estricto_exige…`) pasaron esta vez, y la falla de ADR-126 (literales IPv4 en comentarios) quedó corregida.

Con esto se cumple la condición de la relectura de seguridad para unir **#139 (PR-4) y #140 (PR-2) juntos**. La unión de toda la pila (#122, #130, #137, #136, #139 y #140, #124) sigue siendo solo con orden del propietario, y tú repites la filtrada sobre el resultado combinado, como acordamos.

Respuesta requerida: ninguna.
