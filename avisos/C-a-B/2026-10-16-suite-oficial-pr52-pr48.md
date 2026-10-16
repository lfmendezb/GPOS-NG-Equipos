```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #48 (a/rg14-contencion-indice @ 808cbe0a) + #52 (a/dl22-rotacion @ cd480ddd), unión local temporal a99c3fb5
Estado: Abierto
```

# Suite oficial de #52 + #48 en OSHIN-LEGION: sin fallas atribuibles a los PR

Encargo del propietario a través de `A-a-B/2026-10-16-delegacion-a-c`.

## Cómo se corrió
- Unión local de #48 y #52, sin conflictos; la compilación dio 0 errores.
- `GPOS.Tests` con `--filter "Transicion!=Ola5&Transicion!=Defecto"`.
- **SQL Server 2025, instancia predeterminada `.`** (`GPOST_TEST_SERVER=.`), con autenticación contenida y modo mixto. Usé otra instancia para no compartir SQL con la construcción de SC08, que corría en `.\SQLEXPRESS`. La CPU sí estuvo compartida.

## Resultado
**3122 correctas, 5 fallidas y 18 omitidas (3145 en total), en 12 min 17 s.**

| Falla | Causa | Repetida sola |
|---|---|---|
| `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe…` | Conocida, anterior a DL-22 (A también la ve en su PC) | Falla 2 de 2: **falla siempre, también sin DL-22** |
| `EsquemaPendienteAccesoTests.Un_Super_Usuario_inhabilitado…` | Carga | Pasa |
| `RutasLicenciaHttpTests.L01_a_L09…` y `NoGenerarComprobanteHttpTests.Sin_el_privilegio…` | Error de inicio de sesión por memoria compartida, «No hay ningún proceso en el otro extremo», con la máquina cargada | Pasan |
| `CompraVariableTablaTests.C10…` | «Database is already open and can only have one user at a time»: carrera con otra clase sobre la base compartida | Pasa |

**La intermitente `RutasLicenciaHttpTests.Un_RESTORE_con_el_refresco…`:** con #52 + #48 dio 4 de 4 en verde. En la base sin #52 (`ce33b2a8` + H-V4) falló 1 de 4. **No la causa el #52.**

**Conclusión:** ninguna falla se puede atribuir al #48 ni al #52. En SQL 2025 no se ve el 12834 de SQL 2019, así que esta corrida complementa la de A y no la sustituye.

## PA-30 «ningún 500»
No se corrió 5 veces en esta tanda. Ya está publicado el #55 (DL-22 (b+), `a/dl22-bmas`), que devuelve PA-30 a la suite oficial: C corre ahora **#48 + #52 + #55** y repite PA-30 5 veces sobre esa punta.
