```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #55 (a/dl22-bmas @ d3a65288, contiene #52) + #48 (808cbe0a), unión local 88946b3b
Estado: Abierto
```

# Suite oficial de #55 + #48 y PA-30 repetida 5 veces en OSHIN-LEGION

Encargo del propietario a través de `A-a-B/2026-10-16-delegacion-a-c`.

**Cómo se corrió:** SQL Server 2025, en la instancia `.` (`GPOST_TEST_SERVER=.`), con el filtro oficial. La compilación no tuvo errores. La CPU estaba compartida con las construcciones de C, que usaban `.\SQLEXPRESS`.

## Suite oficial: 3129 correctas, 2 fallidas y 18 omitidas (3149 en total), en 10 min 26 s
| Falla | Causa |
|---|---|
| `AplicacionEmisionPlanTests.La_lectura_unificada…` | «Database is already open and can only have one user at a time» (carrera en la base compartida, por carga) |
| `CompraVariableTablaTests.C10…` | «Database is in transition» (la misma carrera; ya había fallado así en la corrida de #52 y pasa sola) |

Ninguna se puede atribuir a DL-22. `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe…`, que fallaba siempre en la corrida de #52 + #48, **pasó en esta**.

## PA-30 («ningún 500»), clase `Rg14RotacionApiTests.PA30*`: 4 de 5 corridas en verde
**Ventanas medidas en la corrida 4 (la de la falla):** coinciden con lo firmado en (b+), que dice unos 3 s para la credencial y unos 15 s para las sesiones.

| Generación | Credencial | Sesión |
|---|---|---|
| `gpos_app_a` | 3,59 s (18456) | 15,07 s (916) |
| `gpos_app_b` | 3,49 s (18456) | 15,06 s (916) |

**La única falla (corrida 4):** `PA30_dos_rotaciones_normales_bajo_carga_sin_ningun_500` contó **1 petición fallida de 6052**.
- **No fue un 500.** Fue un 400 en `POST /api/maestros/articulos`: «Ya existe un artículo con el código A957A8F23». En la lista de causas de 500 no apareció ninguna.
- **Lo que C revisó:**
  - El cliente de pruebas (`Http.EnviarAsync` y `CrudoAsync`) no reintenta.
  - La API no usa ninguna estrategia de reintento de EF: no hay `EnableRetryOnFailure` ni `ExecutionStrategy`.
  - El 400 sale de la comprobación previa de `MaestrosService.Articulos.cs:318`.
  - El código lo genera `Datos.Id("A")`: «A» más 8 hexadecimales, o sea 32 bits aleatorios.
- **Hipótesis 1:** un choque de códigos aleatorios. Con unos 3.000 artículos por prueba, y unos 6.000 si las dos pruebas de la clase comparten la base, la probabilidad es de un 0,1 a 0,4 % por corrida. Es baja para verla en 1 de 5 corridas, pero no imposible.
- **Hipótesis 2:** que algún camino ejecute dos veces el mismo POST durante la rotación, por ejemplo en `ReaperturaConexionEmpresa`. C no lo pudo confirmar.

**Recomendación para A:**
1. PA-30 debería contar como fallo solo los 5xx, que es lo que dice su criterio, o generar códigos únicos secuenciales.
2. Si se quiere descartar la hipótesis 2, registrar en la prueba el `traceId` y la hora de cada fallo frente a las rotaciones. El de esta falla es `00-9a1a2ac930387dd8052b7d0861f39a3f-c529bee4f80d4134-00`.

**Conclusión de C:** con lo observado, DL-22 (b+) cumple «ningún 500». Las ventanas medidas coinciden con lo firmado.
