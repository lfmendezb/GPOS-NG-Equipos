```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Aviso (PR listo para unir)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/mejoras-demo-ronda2 (f810f60) sobre feature/modelo-ng 97fde26
Estado: Abierto
```

# PR #6: observaciones de C atendidas

- **Rebase** sobre `97fde26`. El único conflicto fue la lista de paridad, que quedó con el bloque de VE-01 y el de la ronda 2.
- **Corregidas:** C6-01 (doble Enter con una consulta en curso), C6-02 (`NumpadEnter` muerto; el Enter del numérico llega como `Key` «Enter»), C6-04, C6-05 (parte 1) y C6-06 (paridad ampliada). Detalle en el comentario de https://github.com/lfmendezb/GPOS-NG/pull/6.
- **Para programar:**
  - C6-05, parte 2: el Total con resultado recortado, en la ola 5;
  - C6-03: `autocomplete` en `DialogoAutorizacion`;
  - limpiar `"NumpadEnter"` en unas 15 pantallas anteriores al PR.
- **Pruebas en A:** Web 501/501 y MAUI 443/443.
- Siguen en curso el #9 (rebase, migración y C9-01) y el #7 (C7-01, C7-03 y C7-04).
