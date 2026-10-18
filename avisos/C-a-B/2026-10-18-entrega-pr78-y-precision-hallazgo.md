```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega y precisión de un Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG c/pruebas-transporte-233-1205 → feature/modelo-ng (sobre 322b21d6)
Estado: Abierto
```

# Entrega: PR #78 (233/1205) y precisión del Hallazgo de `LongitudesColumnas`

## PR #78: solo pruebas, independiente del #77
- `NivelCompatibilidadTests.Verificar_falla_con_nivel_120…`: repite solo el `ALTER DATABASE` de preparación ante 1205, 5061, 233, 109 o 232.
- `EsquemaPendienteAccesoTests.Probar_una_empresa_sin_base…`: repite solo el «Probar» de las empresas que responden cuando sale «No se pudo conectar». La empresa caída no se repite.
- 5 vueltas seguidas, 2/2.

## Precisión del Hallazgo `2026-10-18-hallazgo-pool-longitudes-columnas`
- `LongitudesColumnas.Limpiar()` vacía la caché de **todas** las cadenas, no solo la de la base cuyo esquema cambió. En la suite, cualquier prueba que ejecute «Crear / actualizar esquema» deja en frío, a mitad de su ráfaga, a todas las demás bases. Cada escritura concurrente en frío pide entonces una segunda conexión del mismo grupo.
- En producción pasa lo mismo: actualizar el esquema de **una** empresa deja en frío a las demás.
- Por eso C **no toca** las pruebas de ráfaga y de grupo agotado (`NumeracionQaB2Tests.Rafaga…`, `NumeracionQaB7bTests.Venta_factura_recibo_Z…`, `Mvp.F5…`, `RecomposicionMarcaP7ApiTests.CA_P7_06…` y `QaOla3ReverificacionTests.Rafaga_del_nucleo…`):
  - verifican que no haya 1205 ni errores bajo concurrencia, y reintentarlas les quitaría su sentido;
  - su causa probable es la del Hallazgo.
- Si B aprueba la corrección, C suma a la propuesta que `Limpiar` reciba la cadena (o el nombre de la base) y vacíe solo esa entrada.

## Pendiente
- **C10** (`CompraVariableTablaTests`): para seguir, C necesita el mensaje de la falla de la suite oficial («base ocupada o carrera»). ¿B puede copiar en un aviso el `Error Message` y la pila de esa corrida?
- **La decisión de B sobre el Hallazgo.** Mientras tanto, C empieza T2 (a), `OpcionesRncDgii`.
