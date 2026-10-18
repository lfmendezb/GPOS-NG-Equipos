```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (0bb596c; el parámetro del vendedor está en construcción)
Estado: Abierto
```

# Vendedor opcional salvo que la empresa lo exija; calendario de A (rendimiento, ADR-118/119)

## 1. Vendedor (decisión del propietario, 2026-10-08)
«El vendedor solo es obligatorio si se exige su uso en las ventas. De otra forma es opcional.» A lo construye ahora:
- **Parámetro por empresa «Exigir vendedor en las ventas»** (`ExigirVendedor`), **apagado por omisión**.
- **Apagado:** una venta sin vendedor es válida; se puede inhabilitar a cualquier vendedor; si el vendedor por omisión de la caja o del perfil del cajero está inhabilitado, la venta sale sin vendedor. Un vendedor elegido a mano e inhabilitado sigue rechazándose.
- **Encendido:** toda venta exige un vendedor habilitado; no se inhabilita a un vendedor asignado a una caja o a un perfil de cajero (precisa `5d33cd7`); no se enciende el parámetro con asignaciones inhabilitadas.
- **Para B:** las ventanas de facturación por vertical (Duty Free y las demás) deben tratar el vendedor como **opcional** salvo este parámetro. Si tu diseño de Duty Free lo pedía siempre, ajústalo o dime si el cliente necesita exigirlo (se enciende por empresa). Es una regla general del núcleo, no un parámetro por vertical.

## 2. Rendimiento de la ola 4
- `c92d858`: la causa real no era el disparador (< 1 ms) sino los decimales de SqlClient y la recompilación del último lote de la compra. Compra de 20 líneas con un hilo: 126 → 43 ms. 5a y 6 cumplen el respaldo F-R2; **la meta 1 (venta con compras) aún no** (≈ 94-102 ms frente a 52).
- **Corridas oficiales de QA el 14-oct** con la PC A sin uso; con ellas el maestro decide la meta 1 (seguir dentro del tope o llevar a firma la serie por caja o la meta). El commit de partida definitivo de `b/ola5` sale después.

## 3. ADR-118 y ADR-119
A construye T1, T2 y T4 juntas **desde el 15-oct**, después de las corridas oficiales, para no mover la medición; criterio p95 de la venta ≤ +5 %. T3 y T5 pueden ir después del corte.

## 4. VF-06
El redondeo del vuelto parametrizable no está en ningún ADR; A lo pone en la próxima precisión del núcleo de caja, con la tanda que lo construya.
