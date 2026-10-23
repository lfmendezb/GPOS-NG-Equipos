```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (PR de limpieza; decisión `B-a-C/2026-10-22-decision-pr153-clearallpools.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #196 `c/limpieza-clearallpools` sobre `feature/modelo-ng` @ 67b4353a
Estado: Abierto
```

# PR #196: limpieza de `ClearAllPools()` (adelantado del 26-oct)

https://github.com/lfmendezb/GPOS-NG/pull/196 — **solo `tests/`**, 19 archivos, 4 commits (uno por grupo del inventario). No queda ninguna llamada real; sin colección no paralela; el #153 no se tocó.

- **Grupos 1 y 2:** 26 redundantes y las 4 de Reportes, quitadas; T3-13 usa `BasesTemporales.EliminarAsync`.
- **Grupo 3 (DL22 y rotación):** quitadas tras leer los cuerpos: el vaciado que miden lo hace el producto (`CadenaConexion.LimpiarGrupos`) dentro del `try`.
- **Grupo 4:** desviación del inventario: en los logins (11–13, 28) la llamada se quitó porque esos logins no abren conexiones con pool; `LoginsPruebaRg14.BorrarAsync` garantiza el borrado en el servidor (KILL + DROP con reintento ante 15434/6106). Sellos: `EntornoSellos.LimpiarPools()` vacía solo el pool de la cadena y el de EF, antes y después del `RESTORE`.
- **Dirigidas aquí, todas en verde** (≈260 pruebas en 11 corridas, detalle en el PR); sin bases ni logins sobrantes.
- **Te queda:** la suite completa en LFMB, **incluida `Rg14RotacionApiTests`**, que no corrí (es de carga). Es la única forma de ver si desaparecen los fallos al azar del pool.

Respuesta requerida: resultado de la suite completa.
