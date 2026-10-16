```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #55 (a/dl22-bmas @ 32a594ae) + #48 (808cbe0a), unión local 402c2c9d
Estado: Abierto
```

# Suite oficial de #55 @ 32a594ae + #48, y PA-30 5 veces: ningún 500

Responde a `A-a-B/2026-10-16-suite-dl22-bmas-para-c`. **Sustituye** a la corrida sobre `d3a65288` (`C-a-B/2026-10-16-suite-oficial-pr55-pa30`), porque A agregó después `afbfdb29` (DL22-S13 a S17) y `32a594ae` (51617).

**Cómo se corrió:** SQL Server 2025 en la instancia `.` (`GPOST_TEST_SERVER=.`), con el filtro oficial. La compilación no tuvo errores. Las construcciones de C compartían la CPU, pero usaban `.\SQLEXPRESS`.

## Suite oficial: 3116 correctas, 15 fallidas y 18 omitidas (3149 en total), en 11 min 33 s
| Falla | Causa | Repetida sola |
|---|---|---|
| 11 de `NumeracionB7fReversionTests` (CP161) | Tiempo de espera del pool al **crear el fixture** (falló en 1 ms), por la carga | **13 de 13** |
| 2 de `CredencialesLecturaRealesTests` | Error de inicio de sesión por memoria compartida, «No hay ningún proceso en el otro extremo», por la carga | **13 de 13** (junto con CP161) |
| `AplicacionEmisionPlanTests.La_lectura_unificada…` | «Database is already open…»: carrera en la base compartida, la misma de las corridas anteriores | Pasa |
| `Rg14RotacionApiTests.PA30_…sin_ningun_500` | Ver abajo | 5 de 5 aparte |

### PA-30 dentro de la suite
- **2 peticiones fallidas de 2774.** Las dos son **503 `ESTADO_CANDADO_NO_DISPONIBLE`** con el texto «No se pudo abrir la base de la empresa en este momento…», en `POST /api/maestros/articulos`.
- **No hubo ningún 500:** la lista de causas de 500 quedó vacía.
- traceId: `00-44cf8896c8e68bdc1385df708390e7d8-f232cfb9936258f1-00` y `00-dab223223df996279c25843e829e28db-d9482c3f6fea11bf-00`.
- **Ventanas:**

  | Generación | Credencial | Sesión |
  |---|---|---|
  | `gpos_app_a` | 3,54 s (18456) | 15,07 s (916) |
  | `gpos_app_b` | 3,56 s (18456) | 15,07 s (916) |
- **Lectura de C:** la máquina estaba cargada y PA-30 hizo menos de la mitad de las peticiones que hace aparte (2774 frente a unas 6000). Con esa carga, la apertura de la base no llegó a tiempo en 2 peticiones y la API respondió el 503 controlado de S-1, con `Retry-After`.
  - Es el comportamiento firmado: 503 y no 500.
  - Pero la prueba cuenta cualquier respuesta que no sea correcta.
  - **A decide** si PA-30 debe aceptar un 503 con `Retry-After` como resultado válido, que es lo que dice el criterio «ningún 500», o si quiere investigar si alguno vino de la rotación y no de la carga.

## PA-30 aparte (`Rg14RotacionApiTests.PA30*`), 5 corridas: **5 de 5 en verde**
Unos 2 minutos por corrida, sin ningún fallo. La corrida anterior sobre `d3a65288` había dado 4 de 5 por un 400 de artículo duplicado; esta vez no se repitió.

## Conclusión
- Ninguna falla es atribuible al #55 ni al #48.
- DL-22 (b+) cumple «ningún 500» en SQL Server 2025.
- Las ventanas coinciden con las de la PC A en SQL 2019 (3,05 s y 15,07 s). La credencial tarda unos 0,5 s más en SQL 2025.
