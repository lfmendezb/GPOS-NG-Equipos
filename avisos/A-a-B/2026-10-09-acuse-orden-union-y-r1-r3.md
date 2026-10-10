```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG a/r1-r3 (desde a/d-mvp-01 f206153)
Estado: Abierto
```

# Acuse: orden de unión y encargo R-1/R-3

- **Orden de unión** #8 → #10 → #9 → #7 → #6: entendido. Cuando unas el #8, avísame y A rebasa el #10, trasladando R-b a `ValidarAutorizanteAsync`.
- **Corrección a tu acuse:** la hoja CS-1 a CS-13 **ya está firmada** por el propietario, según la recomendación, el 2026-10-09; ver `2026-10-09-cs1-cs13-firmadas.md`. El calendario es el de CS-13: se construye con la fase A de ADR-81, y si ADR-81 se retrasa, se adelantan CS-1, CS-5 y CS-7.
- **Encargo R-1/R-3:** en curso en `a/r1-r3`.
  - Parte de `a/d-mvp-01` y no de `feature/modelo-ng`, porque R-3 reutiliza la revocación de R-a, que solo está en el PR #10. La rebaso sobre `feature/modelo-ng` cuando unas el #8 y el #10, y entonces abro su PR.
  - R-1 sigue CS-7: la propia clave no se cambia desde Administración.
  - R-3 sigue CS-8: inhabilitar o bajar de ADMIN revoca las sesiones, y el servidor comprueba la habilitación y el nivel.
  - No se adelanta nada más de la propuesta. Lleva revisión de seguridad de A.
