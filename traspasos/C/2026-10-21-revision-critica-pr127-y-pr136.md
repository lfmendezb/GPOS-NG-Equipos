```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Revisión crítica (tarea 4: pruebas del #127, incluido el diff del #136)
Repositorio y rama: GPOS-NG origin/a/n1-endurecimiento-servicio @ 2cd41377 (feature/modelo-ng fc7f07f2 + #136)
Estado: Abierto
```

# Revisión crítica: pruebas de `ModoServicioApiTests` y `EndurecimientoServicioApiTests` (#127 + #136)

Leí `ModoServicioApi.cs`, `ModoServicioApiTests.cs` (del #127, ya unido) y `EndurecimientoServicioApiTests.cs` (del #136, S-03 a S-07 y R-02/R-03/R-06). Compilé y corrí con filtro: 548/549 (1 omitida a propósito, `PF12`), sin relación con este código.

## 1. ¿Fallaría alguna prueba si se quita la llamada a `ComprobarArranque`?

**Sí.** `ApiModoServicioArquitecturaTests.Program_invoca_el_modo_servicio_primero_y_antes_de_construir` lee el texto de `Program.cs` y exige, en orden exacto, las 4 líneas de `LineasServicio` (opciones, `ComprobarArranque`/`Rechazar`, `Registrar`, `FijarEscuchaPorOmision`). Quitar la línea de `ComprobarArranque` la hace fallar. Cubierto.

## 2. ¿Fallaría alguna si se invierte el orden identidad/privilegios?

**Parcialmente.** Dentro de `Comprobar(actual, privilegios)`, `La_identidad_se_comprueba_antes_que_los_privilegios` sí detecta una inversión: si el código comprobara primero `PrivilegiosSobrantes` y después la identidad, el caso `Comprobar(otra, ["SeImpersonatePrivilege"])` devolvería `ARRANQUE_PRIVILEGIOS` en vez de `ARRANQUE_IDENTIDAD`, y la prueba fallaría. Bien cubierto en ese nivel.

**Hallazgo P127-01 (Baja):** dentro de `Decidir`, nada impide que alguien mueva la lectura de `leerPrivilegios()` **antes** del `if (Comprobar(actual, []) is { } rechazoIdentidad) return ...`. El resultado final no cambiaría (`Comprobar` sigue revisando identidad primero), pero se llamaría a `leerPrivilegios()` con una identidad ya sabida inválida, algo que hoy se evita. Ninguna prueba usa `NoDebeLeerse<IReadOnlyList<string>>()` combinado con una identidad **inválida pero legible** (`SidApi` ≠ `actual`) como servicio; el patrón `NoDebeLeerse` solo se usa hoy para el caso en que la **lectura de la identidad lanza** (`S04_si_no_se_puede_leer_la_identidad_como_servicio...`) o cuando `pideServicio && !esServicio` (S-03). Sugerencia (no bloquea): agregar
```csharp
Assert.StartsWith("ARRANQUE_IDENTIDAD:",
    ModoServicioApi.Decidir(true, true, () => OtraCuenta, NoDebeLeerse<IReadOnlyList<string>>()));
```
para que una inversión de ese tipo, aunque no cambie el resultado, si llegara a leer el token de verdad (con efectos colaterales o una excepción real del sistema) se note en la prueba.

## 3. ¿Fallaría alguna si `Rechazar` no sale con código 1?

Lo verifica `S04_Rechazar_escribe_por_el_camino_seguro_y_sale_con_1`, pero **por texto**: lee el código fuente de `Rechazar` y busca `Environment.Exit(1);` al final del cuerpo. No ejecuta el método (no puede: terminaría el proceso de pruebas). Es la misma técnica que ya usa el proyecto en otras pruebas de arquitectura (`SellosEnLaApiTests`, citada en el propio comentario de la clase), así que no es una debilidad nueva, pero su cobertura real es "el texto dice que sale con 1", no "el proceso sale con 1". Si alguien cambia `Environment.Exit(1)` por `Environment.Exit(0)` en una refactorización que mueve las líneas de método (de forma que el recorte de texto `inicio..fin` deje de capturar la línea), la prueba podría no detectarlo. No pido cambio: lo dejo anotado porque es la pregunta que hizo B.

## 4. ¿Qué parte del ciclo no tiene ninguna prueba?

**`CicloDeVidaServicio` (la clase `internal sealed` al final de `ModoServicioApi.cs`) no tiene ninguna prueba unitaria.** Ni `StartAsync`/`StopAsync`, ni el registro de los eventos 4768/4769/4770 en los callbacks de `ApplicationStarted`/`ApplicationStopped`, ni la rama `catch (Win32Exception)` de `PrivilegiosParaElEvento` (que registra el evento 4770 con un texto distinto si falla la lectura del token ya en marcha). Las únicas menciones de `CicloDeVidaServicio` en las pruebas son como **cadena de texto**, para comprobar que esa categoría de registro llega en Información (S-05/R-06), no para ejercitar la clase.

**No es un descuido:** `GPOS.Api` no da `InternalsVisibleTo` a `GPOS.Tests` (los otros proyectos que sí lo hacen son `GPOS.Core` y `GPOS.Criptografia`), y la clase es `internal`. Probarla desde `GPOS.Tests` hoy exigiría exponerla (quitar `internal` o agregar `InternalsVisibleTo`), lo que no until pidió B. Además, el propio comentario de `ModoServicioApiTests` ya deja esto para el laboratorio: *"Que el servicio instalado arranque o se rechace con su cuenta virtual es del ensayo de devops (L-04, L-05)"*. Tampoco hay un precedente de un `IHostedService` de ciclo de vida probado así en `GPOS.AgenteImpresion` (revisé: no usa ese patrón).

**Para que B decida:** dejarlo así (cubierto solo por el ensayo de devops L-04/L-05, consistente con el resto del modo servicio) es razonable y no bloquea; si se quisiera una prueba unitaria de los 3 eventos y la rama de excepción, haría falta `InternalsVisibleTo` de `GPOS.Api` hacia `GPOS.Tests` (cambio de proyecto, a decidir con el propietario por la regla de no tocar tecnología/estructura sin consultar — aunque esto es solo una línea de csproj, no una tecnología nueva).

## Resumen

| # | Pregunta de B | Resultado |
|---|---|---|
| 1 | Quitar `ComprobarArranque` | Falla (arquitectura, cubierto) |
| 2 | Invertir identidad/privilegios | Falla en `Comprobar`; hueco menor (P127-01, Baja) dentro de `Decidir` |
| 3 | `Rechazar` sin salir con 1 | Se prueba por texto, no por ejecución (limitación conocida, no nueva) |
| 4 | Sin ninguna prueba | `CicloDeVidaServicio` completa (decisión consciente, dejada al laboratorio) |

Sin código de producción tocado. Ningún hallazgo bloquea el #127 ni el #136; P127-01 es una sugerencia de prueba adicional, no una corrección.
