```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega final (sustituye la lista de pendientes del aviso anterior)
Prioridad: Media
Repositorio y rama: GPOS-NG, ramas c/ sobre feature/modelo-ng @ 322b21d6
Estado: Abierto
```

# Entrega final 2 de C: el encargo de T2 y de las pruebas intermitentes queda completo

El propietario pidió en la sesión de C completar los pendientes antes de cerrar (B no asigna hasta el miércoles 21). Se hicieron. **C queda sin trabajo en curso y en espera.**

## PR nuevos desde el aviso anterior
| PR | Qué es | Notas |
|---|---|---|
| [#82](https://github.com/lfmendezb/GPOS-NG/pull/82) | C10 (`CompraVariableTablaTests`) | Solo pruebas. **Causa inferida, no reproducida** (sin el mensaje de B): el plan sale de la caché bajo carga; el pago se repite hasta 4 veces y las aserciones del plan no cambian. Si la próxima corrida falla con otro mensaje, sería un defecto real del disparador |
| [#83](https://github.com/lfmendezb/GPOS-NG/pull/83) | T2 (c) + guarda 4 | Migración `20261018181156_T2cAceptaDeSuplidor` (posterior a `20261018153317`), guion idempotente nuevo que sustituye al anterior. Arquitecto de datos: Conforme con correcciones (aplicadas) |
| [#84](https://github.com/lfmendezb/GPOS-NG/pull/84) | T2 (d), guarda 3 | **Apilado sobre el #80**: su base es la rama del #80; al unir el #80, cambiar la base a `feature/modelo-ng` |

Con el [#77](https://github.com/lfmendezb/GPOS-NG/pull/77) al [#81](https://github.com/lfmendezb/GPOS-NG/pull/81) del aviso anterior son ocho PR. **Orden:** #80 → #81 y #84; los demás son independientes. Migración: solo el #83 trae una (la marca `20261018181156`); si otra rama une una antes, se regenera.

## Qué cambia en el #83 para el usuario (ADR-52)
Nada en el POS ni en compras con la siembra correcta. El ADMIN deja de sobrescribir `RequiereRnc`; la pantalla de tipos todavía no tiene las casillas de las dos columnas (D-02 del arquitecto de datos, para el frontend).

## Ráfagas y grupo agotado
`NumeracionQaB2` (ráfaga), `B7b` (Venta_factura_recibo_Z), F5, CA_P7_06 y `QaOla3` (ráfaga): **5/5 en tres vueltas seguidas con el #79**. No toqué esas pruebas: verifican que no haya errores bajo concurrencia, y la causa probable (la segunda conexión de `LongitudesColumnas`) se corrige en el #79. **Falla o no, lo dirá la suite oficial de B con el #79 unido.**

## Para decidir (B, el miércoles 21 o después)
- **Hallazgo nuevo de la guarda 4:** `ImportacionesService.cs:428` (`"01" or "31"`, crédito fiscal sin RNC) debe leer `RequiereRnc` de la tabla; queda como excepción de la guarda con tanda T3. Y B-03 (notas del suplidor desde `Categoria`).
- Del [#79](https://github.com/lfmendezb/GPOS-NG/pull/79): LC-03 a LC-05. Del [#81](https://github.com/lfmendezb/GPOS-NG/pull/81): S04, S05 y S07, y la comprobación de la DACL del archivo (requiere ADR-77 en el núcleo).
- Las casillas `RequiereRnc` y `AceptaDeSuplidor` en `NcfTipos.razor` (Web y MAUI).

## Modelo
Esta sesión corrió con Sonnet 5.5 (`claude-sonnet-5-5`), como pidió el propietario. El arquitecto de datos y el auditor de seguridad corrieron con Opus por su definición, y devops con el Sonnet de la suya.
