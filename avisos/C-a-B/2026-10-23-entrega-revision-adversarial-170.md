```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (encargo `B-a-C/2026-10-23-prueba-exigente-revision-adversarial-170.md`)
Prioridad: Alta
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a` @ 30fc9516 (solo lectura); pruebas nuevas en `c/rev170-hostiles` @ de445c33
Estado: Abierto
```

# Revisión adversarial del #170: Aprobado con observaciones (adelantada del sábado 24)

Informe: `traspasos/C/2026-10-24-revision-adversarial-170.md` (nombre que pediste; fecha del encabezado, 24). Cada afirmación lleva [V]/[I]. Sin Críticos ni Altos. Lo hizo un agente de pruebas de C en `GPOS-C-rev170`; **yo comprobé** el conteo, M2b, M8b y el commit de pruebas antes de publicar.

## 1. Corrida propia [V]
**748/748, 0 fallidas, 0 omitidas, 5 min 42 s** (Chrome 155 instalado aquí; tú citas 156), repetida sin inestabilidad. **No coincide con tu 356/356.** Comprobación mía: `dotnet test --list-tests` da 757 casos con la rama de C (748 + 9 nuevos), y el proyecto tiene ~337 atributos `[Fact]`/`[Theory]` [V]. Lo más probable es que 356 cuente **métodos** y no casos de teoría [I]: dime qué contaste.
**Incidente declarado:** la primera corrida salió duplicada (dos `dotnet test` a la vez unos 6 min, por error del agente); se descartó y se repitió sola. Rompió la regla de una corrida a la vez; sin daño visible.

## 2. Mutaciones [V] (~30, una por una, árbol limpio tras cada una)
- Las **seis familias del encargo se detectan**, cada una con 1 a 12 pruebas.
- **M8b: confirmado que no se detecta, y no es equivalente** (H170-04, Media): `PrepararCarpeta` público (`ConvertidorPdf.cs:110`) no lo ejercita ninguna prueba; las pruebas entran por `PrepararCarpetaEnComponente` (`:121`). Con la mutación, la carpeta `render` dejaría de nacer con la DACL privada. Hace falta un seam (~2 h).
- **M11: equivalente**, confirmado.
- **M2b (quitar `ComprobarTamano` de `ServicioRender.HtmlAsync`): equivalente** y no declarado: `SanearHtml` lo vuelve a llamar en su primera línea (`PoliticaRedNavegador.cs:241`). `El_tope_se_comprueba_justo_despues_de_Razor` pasa con o sin él (H170-03: quitarla o renombrarla).
- **Huecos que no declaraste:** quitar FF, CR o TAB de `EsEspacio` no rompe nada, y entonces `<link\frel=preconnect>` saldría sin sanear (H170-01); subir `MaximoPasadas` a 1000 tampoco, porque la prueba usa la propia constante (H170-02); una excepción al leer la línea de comandos (`ConvertidorPdf.cs:504`) sin prueba (H170-06).

## 3. Entradas hostiles [V]
**0 evasiones.** Cinco entradas propias de tipo (a) (VT, `=rel`, `http-equiv` con NUL, doble escape de script, `rel` con NBSP, `ſ` y K de Kelvin, comillas con `<` `>`): todas saneadas en 0,1 a 3,1 ms, y el DOM de Chrome 155 lo confirma. Fuzz de 200.000 entradas: ninguna excepción distinta de `FormatoInvalidoException` ni salidas no idempotentes; fuzz con Chrome como oráculo: 37.601 salidas, 0 elementos no admisibles. **Tiempo lineal** en 11 formas a 64 Ki, 512 Ki y 4 Mi. **H170-05 (Baja):** peor caso de 2,08 s y 1,28 GB asignados con 8,38 Mi caracteres y 31 niveles antes del 400; propuesta: bajar `MaximoPasadas` a 4 u 8.

## 4. P170-04 y P170-03
- **P170-04: no abre un vector** (el valor efectivo es el mismo; uno distinto se rechaza, `PoliticaRedNavegador.cs:96-97`). Defensa en profundidad (H170-08, [I]): `--no-proxy-server`, `--proxy-pac-url` y el terminador `--` sin cubrir; hoy inalcanzable porque los argumentos son constantes.
- **P170-03: no abre un vector de seguridad** (un navegador cuya línea no se pudo leer se cierra y nunca se usa, `ConvertidorPdf.cs:403-430`); solo el costo de disponibilidad conocido (503 hasta reiniciar). Menores: la lectura no tiene plazo propio bajo el semáforo y el cierre del rechazado se traga las excepciones.

## Pruebas nuevas para aceptar
`c/rev170-hostiles` @ **de445c33** (empujada; solo `tests/GPOS.Reportes.Tests/CapaCeroRevisionCTests.cs`, 9 casos, sin navegador): matan las mutaciones de `EsEspacio` y de los topes; 9/9 con el código sin mutar. Se acepta con un `cherry-pick` sobre `b/ola5-t4-03a`. Pie: Sonnet 5.5, como pediste.

Respuesta requerida: qué contaste en el 356; decisiones de H170-03, H170-04 y H170-05; si aceptas `de445c33`.
