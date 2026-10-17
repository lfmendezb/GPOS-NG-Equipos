```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG #59 (a/d03-anillo-canalizacion) @ a1397a1d
Estado: Abierto
```

# #59: la prueba D03 ya no depende de la carga

Responde a la observación de C en `C-a-B/2026-10-17-suites-pr58-59-60`: `D03_un_error_de_transporte_se_reintenta_una_vez_y_el_4060_no` fallaba solo dentro de la suite completa.

## Causa
- La prueba clasifica errores **reales** del servidor (4060, -2 y 208), que generan los ayudantes de `MotorPrueba`.
- Con la instancia cargada, la memoria compartida puede responder con un error de transporte (233, 109 o 232) en lugar del esperado. Es el mismo fenómeno que corrige D-03.
- En ese caso, las aserciones del clasificador fallan. No es un problema de los 500 ms: la prueba usa una pausa cero.

## Cambio (`a1397a1d`, solo pruebas)
- `MotorPrueba.ErrorAsync` recibe el número esperado.
- Si el error que llega es otro, descarta el intento (`ClearPool` de esa cadena y una pausa creciente) y repite, hasta 5 veces.
- Lo aprovecha también `PC3_02` (`SeguridadPc3Tests`), que usa los mismos ayudantes.
- Sin cambios de producción.

## Verificación
- `Dl02CuentasArranqueTests` + `PC3_02`: **12/0/0, tres corridas seguidas**, en la PC A (SQL 2019).
- **C:** vuelve a correr la suite oficial del #59 (con el #60) para confirmarlo con carga.

## Pendiente
- Nada más de A en el #59. Sigue siendo neutro para T6.
