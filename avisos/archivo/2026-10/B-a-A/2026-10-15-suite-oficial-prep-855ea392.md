```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Baja
Repositorio y rama: GPOS-NG b/prep-27oct @ 855ea392
Estado: Abierto (solo información; una observación Baja sin dueño todavía)
```

# Suite oficial de `b/prep-27oct` (855ea392): 3115 correctas, 2 fallas de concurrencia, 27 omitidas

## Corrida
- `GPOS.Tests`, filtro `Transicion!=Ola5&Transicion!=Defecto`, en `.\SQLEXPRESS` (LFMB), con la máquina sola: **3115 correctas, 2 fallidas y 27 omitidas** (3144 en total, 11 min 40 s).
- La corrimos antes de A-N2 por decisión del propietario, para detectar ya los problemas del rebase. Después de A-N2 se corre una versión reducida, y la suite completa una vez más antes de unir el 27-oct.

## Las 2 fallas: las dos pasan solas (no son del rebase)
| Prueba | Falla en la suite | Sola |
|---|---|---|
| `DispositivosK1Tests.K1_01_un_dispositivo_conocido_atraviesa_el_freno_por_IP_y_el_global` | Tiempo de espera del grupo de conexiones en `EsquemaSistema.ActualizarRestauracionAsync` al iniciar la API | 45/45 |
| `ConsultasVarcharTests.CP170_la_guarda_rechaza_caracteres_fuera_de_la_pagina…` | `Assert.Single(registro.Avisos)` vacío | 1/1, dos veces |

**Causa de CP170 (observación Baja, de las pruebas):**
- `LongitudesColumnas.Registro` es una propiedad estática.
- La prueba la reemplaza con su registro propio, pero `src/GPOS.Api/Program.cs:245` la vuelve a asignar cada vez que otra clase de pruebas en paralelo levanta la API.
- Por eso el aviso termina en el registro del servidor y no en el de la prueba. También se reprodujo corriendo CP170 junto con K1.

**Remedio sugerido**, sin cambiar producción:
- poner `ConsultasVarcharTests` y `NumeracionQaRevisionB7eTests` (que también tocan `Registro`) en una colección de xUnit sin paralelismo con las clases que levantan la API;
- o bien, que la prueba no dependa del estático (por ejemplo, `AsyncLocal` solo en las pruebas).

Sin dueño todavía. Si lo toma A, que sea en una rama aparte que no toque A-N2.
