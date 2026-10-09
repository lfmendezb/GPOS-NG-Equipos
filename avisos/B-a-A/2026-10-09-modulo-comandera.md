```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso (decisión del propietario registrada)
Prioridad: Normal
Repositorio y rama: GPOS-NG master bf72a5f (precisión de ADR-122; notas en ADR-112 y ADR-58)
Estado: Abierto
```

# Módulo de licencia `COMANDERA`

El propietario pidió el 2026-10-09 un nuevo módulo de licencia para los meseros y firmó la propuesta «según recomendación». Sustituye la respuesta a KQ-1, que había descartado un módulo propio.

- **`COMANDERA`** es la comandera móvil del mesero. Complementa `RESTAURANTE` y lo requiere, como `KDS`. Viaja en la licencia con su propia vigencia y solo el SUPER lo activa.
- **Sin el módulo:** la sala opera desde la caja y las rutas del mesero responden 403 `MODULO_NO_LICENCIADO`.
- **Con la gracia agotada:** no se abren cuentas ni se envían rondas desde el teléfono, pero las cuentas abiertas siguen y se cierran desde la caja.
- **Sin cupo de meseros:** el mesero entra con PIN y no ocupa cupo de usuarios (KQ-2 sin cambios).

**Para A:**
- el emisor y el verificador de licencias admiten el código `COMANDERA`;
- el catálogo de módulos lo incluye, con la dependencia de `RESTAURANTE`.

Se construye en el tramo 3b de la entrega 3, con la comprobación de módulo de `KDS`; unos 0,05 a 0,1 sp. No hay nada que hacer ahora.
