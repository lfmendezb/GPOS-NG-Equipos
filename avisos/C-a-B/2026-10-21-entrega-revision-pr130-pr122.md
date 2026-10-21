```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 3: revisión de pruebas del #130 y correcciones del #122)
Prioridad: Media
Repositorio y rama: no aplica (informe en el área común y comentario en el #122 y el #130)
Estado: Abierto
```

# Entrega: revisión de pruebas del #130 (RT-06) y del #122

Informe completo: `traspasos/C/2026-10-21-revision-pruebas-pr130-y-pr122.md`. Comentario con el resumen en el [#122](https://github.com/lfmendezb/GPOS-NG/pull/122) y el [#130](https://github.com/lfmendezb/GPOS-NG/pull/130).

## Resumen de los 4 puntos que pidió
1. **Reenvío real (`ForwardedHeaders_Enabled`, IIS):** muy bien cubierto, con una canalización real y `X-Forwarded-For` falsificado.
2. **IPv6 con ámbito:** cubierto en varias clases.
3. **La muestra de 60 s con el reloj:** cubierto con reloj falso (`RelojManualRed`), no con `Thread.Sleep`; incluye una prueba de concurrencia (1000 llamadas en paralelo).
4. **Filtro sobre rutas con `PathBase`:** hallazgo **P130-01 (Baja, no bloquea)**. El código arma la ruta con `PathBase.Add(Path)`, pero ninguna de las 5 clases de prueba fija `PathBase` a un valor no vacío; todas corren con la raíz. No sé si la API llega a correr con `PathBase` configurado en producción; si es un escenario real, falta un caso con `ctx.Request.PathBase` no vacío.

También revisé con el criterio de "pruebas que no fallarían si se quita la línea que protegen" (como P120-01): bien protegidas, salvo que todavía no hay una prueba de arquitectura que fije el orden de `UseFiltroOrigenNodo` antes de `UseForwardedHeaders` en `Program.cs` — porque aún no está cableado (lo hace PR-4). Lo anoté para cuando llegue ese PR, no es un hallazgo de este.

Compilé y corrí con filtro: 500/500 (`GPOS.Tests.Red`) y 48/48 (`GPOS.Web.Tests…Red`). Ningún hallazgo bloquea el #122 ni el #130.

Antes del 28-oct, como estaba previsto. Sigo con la tarea 5 (PR de documentos sobre P126-01 a P126-05), con plazo 3-nov, o con la 6 (scripts del laboratorio) si la prefiere primero.
