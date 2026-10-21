```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Revisión (PR #122 y #130) y aviso para PR-4
Prioridad: Media
Repositorio y rama: GPOS-NG PR #122 y #130 (`a/adr90-rt06-filtro-origen` @ e53b71a3); PR #127 (`b/n1-api-modo-servicio` @ 7afa929d)
Estado: Abierto
```

# Revisión de B del #122 y el #130, y lo que PR-4 debe retirar del #127

## 1. Resultado de la revisión
**Aprobado con observaciones** (comentario en el #130, que contiene al #122). Es una revisión de contrato y de código, no sustituye la de seguridad de ustedes.
- Leí `ArranqueRed`, `FuenteConfiguracionRed(.Windows)`, `ModoRed`, `ValoresRegistroServidor`, `OrigenNodo`, `FiltroOrigenNodo` y el cambio de `LimitesPeticiones.Ip`. Cumplen lo firmado (modo solo del registro, 4743 y 4744, filtro por la IP de la conexión normalizada y nunca `X-Forwarded-For`). No leí línea por línea `InterpretacionRed` ni `DireccionIp`, ni las pruebas.
- Pruebas en un *worktree* limpio de `e53b71a3` (mi filtro, distinto del de ustedes): `GPOS.Tests` por `GPOS.Tests.Red`, `RedPlataformaArquitecturaTests` y `EventIdUnicosTests`: **505 correctas**; `GPOS.Web.Tests`, `RechazoOrigenNodoTests`: **10 correctas**. La suite completa no se corrió.
- Los dos PR siguen esperando la orden expresa del propietario. El #130 se rebasa sobre `feature/modelo-ng` al unirse el #122.

## 2. Lo que PR-4 debe retirar del #127
El #127 (N-1) trae `ModoServicioApi.FijarEscuchaPorOmision`: como servicio, y solo si la configuración no trae `urls` ni `Kestrel:Endpoints`, fija `http://localhost:5071` con `UseUrls`. Es un valor **transitorio** para la ventana F-5 (respuesta P-4 de B a C).
- **El choque:** comprobé que `UseUrls` escribe `urls` en `builder.Configuration`. Con el modo presente en el registro, `ArranqueRed.Evaluar` lo vería como fuente de escucha y negaría el arranque con **4744**. Pasaría en cuanto PR-4 cablee su RT-01 en la API.
- **Qué hace PR-4**, en el mismo PR que cablea RT-01/RT-05 en la API:
  1. Retirar la línea `ModoServicioApi.FijarEscuchaPorOmision(builder.Configuration, builder.WebHost);` de `Program.cs`.
  2. Retirar la función y la constante `EscuchaPorOmision` de `src/GPOS.Api/Servicio/ModoServicioApi.cs`.
  3. Quitar su entrada de `ApiModoServicioArquitecturaTests.LineasServicio` y el ajuste de índices de `Program_invoca_el_modo_servicio_primero_y_antes_de_construir`.
  4. Actualizar `ApiModoServicioArquitecturaTests.OrdenMiddleware` con el filtro de PT-05 antes de `UseForwardedHeaders` (ya lo prevé el comentario de esa prueba).
- Está marcado en el código como transitorio (commit `7afa929d`).
- **Sin modo en el registro** (desarrollo, pruebas, DEMO), RT-05 no arma la escucha: lo que hoy sustituye `FijarEscuchaPorOmision` queda como lo decida el PR-4. Si A quiere que el servicio sin modo siga escuchando en 5071, lo arma el código de RT-05 y no la configuración; **A decide** esa regla y la deja en la descripción de su PR.

## 3. Lo que A debe saber del #127 para apilar PR-4
- `Program.cs` ganó **cuatro líneas al principio** (opciones, comprobación de arranque, registro y escucha por omisión); PR-4 se apila sobre eso y retira la cuarta, como arriba.
- El #127 está sobre `feature/modelo-ng`; **se une con orden del propietario antes del 2-nov** y B avisa. Hasta entonces PR-4 no se abre.
- C apila sus pruebas de N-1 (#132) sobre `8b143377`; el commit `7afa929d` solo cambia un comentario y C rebasa.

## 4. Lo que no cambia de lo ya pedido a A
- Confirmar la franja de EventId, la decisión sobre `IdentidadProceso` y los datos de su PC para el laboratorio (avisos del 2026-10-21 anteriores).
- S3-02 del #130 (sin NAT, IP fija de nodo, IPv6) queda para devops y la guía, como A lo planteó.

Respuesta requerida: ninguna urgente para este aviso; basta con que PR-4 lo recoja.
