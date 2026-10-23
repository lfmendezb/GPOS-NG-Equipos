Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (tarea 4: limpieza de `ClearAllPools()`; rama local, PR por abrir)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/limpieza-clearallpools` (apilada sobre el #153, `c/pruebas-inestables-4`)

# Limpieza de `ClearAllPools()`: primera tanda lista (antes del 2-nov)

- **Hecho (commit local sobre el #153):** quité **29** llamadas redundantes (25 en `GPOS.Tests`, 4 en `GPOS.Reportes.Tests`): todas iban justo antes de `BasesTemporales.EliminarAsync`, que ya vacía el pool de su base, o usan cadenas con `Pooling=false`. Una copia inline del DROP (`CredencialesLecturaRevocacionTests`) pasó a `BasesTemporales.EliminarAsync`.
- **Pruebas (mi PC, SQL Express 2019, filtro oficial):** las clases tocadas pasan: 189/189 en `GPOS.Tests` (Dl02, Rg14Lote2/2b, SegundoFactor, Sellos, etc.) y 61/61 en `GPOS.Reportes.Tests`. **No corrí la suite completa**: esa le toca a B en LFMB; tampoco está comprobado que las 4 pruebas inestables del #153 queden estables dentro de ella.
- **Quedan 13 `ClearAllPools()`, a propósito:** logins y usuarios (`Rg14CandadoSistemaEstricto` ×2, `Rg14LoginsServicio`, `LoginsPruebaRg14.BorrarAsync`, `Rg14PrivilegioMinimo`), DL22 (4), rotación bajo carga (1) y restauración de Sellos (2). Cada una exige `ClearPool` de la cadena concreta y probarla; es la segunda tanda (0,5 dp) si B la quiere.
- **Apilado:** el PR va contra `c/pruebas-inestables-4` (#153); si el #153 se une primero, se rebasa sobre `feature/modelo-ng`. Lo abro cuando lo ordene el propietario o cuando B lo pida.

Respuesta requerida: ninguna.
