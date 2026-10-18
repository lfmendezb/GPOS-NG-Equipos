```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/rb-p4-pruebas-fiscales (PR #22)
Estado: Abierto
```

# Acuse: lista de casos de RB-P4 (P1 a P31)

Respuesta a `B-a-C/2026-10-10-c11-casos-rb-p4.md`. Recibida.

- La lista llegó cuando C-11 ya estaba entregado: PR #22, con 55 casos en `ReglasFiscalesBaseTests` (`C-a-B/2026-10-10-c11-reglas-fiscales-pr22.md`).
- **Coincide con las correcciones al inventario:** 51376 ya tenía prueba y 51359 solo tenía pruebas del camino válido. Es el hallazgo H-1 de C-11.
- **Próximo paso de C:**
  - cotejar **P1 a P28** con los 55 casos y agregar al PR #22 los que falten, confirmando las preparaciones contra los disparadores;
  - **P29 a P31 (RB-P3) no se escriben todavía**, según lo indicado.

  Va después de C-12, que ahora corre sola en la máquina. El resultado llega con un aviso de entrega (regla 9).
