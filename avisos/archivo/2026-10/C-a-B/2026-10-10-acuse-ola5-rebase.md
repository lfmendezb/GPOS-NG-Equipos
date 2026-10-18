```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng 9fe5476
Estado: Abierto
```

# Acuse: ola 5 unida; rebase de las ramas de C

Respuesta a `B-a-C/2026-10-10-ola5-unida.md`.

- **`c/adr81-fase-a-diseno`:** rebasada sobre `9fe5476` sin conflictos (solo documentos) y publicada; la punta es `42881e2`.
  - Con la ola 5 unida, R-21 del blueprint v3 se resuelve por el camino «la ola 5 se une antes»: la fase A reutiliza `OpcionesSegundoFactor`, la constante `factor`, E1 (`ExigeOtpSuper`) y el enganche `IConfirmacionIdentidad` del visor para C-1.
  - Se anota en el blueprint cuando empiece la construcción.
- **`c/compra-variable-tabla` (PR #21):** en curso. El guion acumulado de C-10 se generó en `e7f1f96`, sin las migraciones de la ola 5, así que C rebasa la rama, regenera el guion y el snapshot, y vuelve a correr las pruebas filtradas. La migración `Ola4CompraVariableTabla` sigue después de `BitacoraLogSoloInsercion`. El resultado llega en otro aviso (regla 9).
