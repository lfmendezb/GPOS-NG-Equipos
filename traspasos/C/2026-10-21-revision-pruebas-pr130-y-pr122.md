```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Revisión de pruebas (tarea 3: #130 y correcciones nuevas del #122)
Repositorio y rama: GPOS-NG origin/a/adr90-rt06-filtro-origen @ e53b71a3 (incluye #122 + correcciones de la revisión de seguridad)
Estado: Abierto
```

# Revisión de pruebas: #130 (RT-06) y correcciones del #122

Leí `OrigenNodo.cs`, `FiltroOrigenNodo.cs`, `RechazoOrigenNodo.cs` y las 5 clases de prueba (`FiltroOrigenNodoTests`, `IpConexionApiTests`, `OrigenNodoTests`, `RutasSyncArquitecturaTests`, `RechazoOrigenNodoTests`), y el commit `e53b71a3` (correcciones S3-01, S3-03, S3-04, S3-05 sobre el #122). Compilé y corrí con filtro: 500/500 (`GPOS.Tests.Red`) y 48/48 (`GPOS.Web.Tests…Red`).

## Lo que pidió revisar, punto por punto

### Uniones reales de reenvío (`ForwardedHeaders_Enabled`, IIS)
**Muy bien cubierto.** `FiltroOrigenNodoTests` arma una canalización real con `b.Services.Configure<ForwardedHeadersOptions>` y `app.UseForwardedHeaders()` **después** del filtro, y prueba con un `X-Forwarded-For` falsificado que el filtro sigue viendo la IP de la conexión, no la reenviada (`X_Forwarded_For_falsificado_no_cambia_lo_que_ve_el_filtro`). Además, `Con_el_reenvio_del_marco_en_la_configuracion_el_filtro_no_se_prepara` y la variante por entorno prueban las claves reales (`ForwardedHeaders_Enabled`, `ASPNETCORE_/DOTNET_FORWARDEDHEADERS_ENABLED`, `TOKEN`, `APPL_PATH`, `IIS_HTTPAUTH`) con `Assert.Throws<InvalidOperationException>` al preparar. `RechazoOrigenNodoTests` repite la prueba equivalente para la Web, recorriendo `ArranqueRed.VariablesReenvioMarco` y `VariablesIisFueraDeProceso` completas (no una lista copiada a mano, así que no se desincroniza si se agrega una variable).

### IPv6 con ámbito
**Cubierto.** `OrigenNodoTests.Conjunto_normaliza_la_IPv4_mapeada_y_el_ambito` prueba `2001:db8::5%3`; `FiltroOrigenNodoTests.Un_nodo_alcanza_solo_api_sync` prueba `2001:db8::5%4` tanto en una ruta prohibida como en `/api/sync/estado`; `IpConexionApiTests` prueba `fe80::1%7`.

### La muestra de 60 s con el reloj
**Cubierto con reloj falso (`RelojManualRed`/`Reloj` local), no con `Thread.Sleep`.** `OrigenNodoTests.Muestreo_un_evento_por_IP_cada_60_s_con_los_suprimidos` prueba el límite exacto (59 s no alcanza, +1 s sí), el contador de suprimidos y que cada IP tiene su propia ventana; `Muestreo_concurrente_deja_un_solo_evento_por_ventana` corre 1000 llamadas en paralelo y exige exactamente 1 registrado (bajo el candado por IP). `FiltroOrigenNodoTests.Cien_rechazos_en_60_s_dejan_un_solo_4750_con_los_suprimidos` y `RechazoOrigenNodoTests.Un_evento_por_IP_cada_60_s_sin_la_consulta` repiten esto a través de la canalización HTTP real.

### El filtro sobre rutas con `PathBase`

**Hallazgo P130-01 (Baja, no bloquea).** El código arma la ruta como `ctx.Request.PathBase.Add(ctx.Request.Path)` tanto en `FiltroOrigenNodo.cs:55` como en `RechazoOrigenNodo.cs:48`, pero **ninguna de las 5 clases de prueba fija `PathBase`** (busqué `UsePathBase` y asignaciones directas a `.PathBase` en los 5 archivos: no hay ninguna). Todas las pruebas usan rutas de raíz (`/api/sync/...`), así que `PathBase.Add(Path)` siempre se ejercita con `PathBase` vacío, que es equivalente a usar solo `Path`. Si alguien cambiara esa línea por `ctx.Request.Path` a secas (perdiendo el prefijo cuando la API corra con un `PathBase` configurado), ninguna prueba lo notaría.

No sé si en producción la API llega a correr con `PathBase` no vacío (la detección de IIS fuera de proceso ya bloquea la preparación del filtro con `ASPNETCORE_APPL_PATH`, pero `UsePathBase()` explícito en `Program.cs`, sin IIS, seguiría pasando). Si es un escenario real, sugiero un caso como:
```csharp
app.Use((ctx, siguiente) => { ctx.Request.PathBase = "/gpos"; return siguiente(ctx); });
// antes de UseFiltroOrigenNodo, para que /gpos/api/sync/estado pase y /gpos/api/auth/empresas se rechace
```
Si `PathBase` nunca es no vacío en este sistema, la línea es inofensiva pero el código muerto podría simplificarse a `ctx.Request.Path`; en ese caso no hace falta la prueba.

## Pruebas que no fallarían si se quitara la línea que protegen (mutación manual)

Revisé los puntos de mayor riesgo con este criterio (como P120-01):
- **`OrigenNodo.EsNodo`:** si se quitara la normalización (`DireccionIp.Normalizar`) antes de comparar, `La_IPv4_mapeada_del_nodo_se_filtra_igual` y `Conjunto_normaliza_la_IPv4_mapeada_y_el_ambito` fallarían. Bien protegido.
- **El orden del filtro antes de `UseForwardedHeaders`:** no hay una prueba de arquitectura que lea `Program.cs` y exija ese orden literal (a diferencia de `ApiModoServicioArquitecturaTests` con sus 4 líneas de N-1), porque **todavía no está cableado en `Program.cs`** (lo hace PR-4). Cuando PR-4 lo cablee, conviene una prueba de arquitectura equivalente que fije `UseFiltroOrigenNodo` como primer middleware; lo dejo anotado para entonces, no es un hallazgo de este PR.
- **`ExigirSinReenvioDelMarco`:** si se quitara la llamada desde `UseFiltroOrigenNodo`/`UseRechazoOrigenNodo`, las pruebas `Con_el_reenvio_del_marco_...` fallarían (esperan `Assert.Throws`). Bien protegido.
- **El muestreo (`MuestreoRechazosOrigen`):** si se quitara el candado (`lock (e)`), `Muestreo_concurrente_deja_un_solo_evento_por_ventana` podría fallar de forma intermitente bajo carga (1000 iteraciones en paralelo); no es una garantía absoluta de detectar una carrera, pero es la misma técnica que ya usa el proyecto en otras pruebas de concurrencia.

## Resumen

| Punto pedido | Resultado |
|---|---|
| Reenvío real (ForwardedHeaders/IIS) | Muy bien cubierto |
| IPv6 con ámbito | Cubierto |
| Muestra de 60 s con el reloj | Cubierto con reloj falso |
| Filtro sobre rutas con `PathBase` | **Hallazgo P130-01 (Baja):** sin ninguna prueba con `PathBase` no vacío |
| Mutación manual de líneas clave | Bien protegidas, salvo el orden en `Program.cs` (pendiente de PR-4) |

Sin código de producción tocado, sin SQL. Ningún hallazgo bloquea el #122 ni el #130.
