```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 3 del aviso 2026-10-22: diseño del fixture «API de reportes en el proceso» y plan de pruebas de T4-02)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (código leído: `origin/feature/modelo-ng`, solo lectura)
Estado: Abierto (diseño, sin construir; adelantado respecto del 13-nov)
```

# Fixture «API de reportes en el proceso» y plan de pruebas de T4-02

**Fuentes:** plan del tramo 4 (T4-01, T4-02, §6.1 a 6.4) y, del código vivo, `tests/GPOS.Tests/Mvp/ReportesF9Tests.cs` (`ApiF9Factory`, `ReportesF9Factory`, `ReportesF9Fixture`) y `ApiMvpFactory.cs` (solo la cabecera). **No compilé ni ejecuté nada.** No leí `ClienteRender` (no existe aún) ni los seis archivos de pruebas a migrar; su lista es la del plan de B.

## 1. Lo que ya existe y se reutiliza (verificado en el código)
- `ApiF9Factory : ApiMvpFactory` arranca la principal con: introspección habilitada por canalización con nombre (sufijo aleatorio por instancia), `GPOS:Reportes:Reenvio:Direccion` a un puerto libre y la canalización de exportación; reutiliza la cuenta del proceso (`WindowsIdentity`).
- `ReportesF9Factory : WebApplicationFactory<reportes::Program>` levanta la **API de reportes real** con Kestrel en ese puerto, con `FuenteSistemaPrueba` (usuario contenido `gpos_sis_f9`) y `FuenteEmpresaPrueba` (usuarios `gpos_rpt_f9`/`gpos_lec_f9` por `EXECUTE AS USER`), y una carpeta temporal para la exportación.
- `ReportesF9Fixture` une las dos, crea los roles/usuarios (idempotente) y arranca con `UseKestrel()` + `StartServer()`.
- Cada clase de F9 es `IClassFixture<ReportesF9Fixture>`: **una pareja de API por clase**, con base propia (`GPOS_TEST_*`).

## 2. Qué le falta para T4-02 (huecos)
| # | Hueco | Por qué importa |
|---|---|---|
| H-F1 | `ApiF9Factory` configura **introspección y exportación**, pero no la **canalización de render** (`/interno/render/*`, T4-01) ni la cuenta que la ACL admite | Sin ella `ClienteRender` no tiene a quién llamar |
| H-F2 | La API de reportes real trae **Chromium (PuppeteerSharp)**; en la máquina de pruebas puede no haber navegador descargado y el arranque tarda | Las seis clases a migrar no deben depender de descargar un navegador ni de 30 s de precalentamiento |
| H-F3 | El fixture nace para el **flujo de reportes** (usuarios `rpt_f9`/`lec_f9`, rol de sistema). Las clases a migrar necesitan además **imprimir documentos** (facturas, conduces, cierres) | Hay que añadir lo mínimo, sin duplicar el aprovisionamiento |
| H-F4 | Una pareja de API por clase multiplica el costo (cada una crea una base y un host de Kestrel). Las 6 clases de T4-02 serían 6 parejas más, además de F9 | Riesgo de inestabilidad ya conocido en este equipo y de tiempo de suite |
| H-F5 | No hay forma de **simular una API de reportes caída o lenta** sin cerrar el host (para `ClienteRenderTests`) | Los casos 503/reintento/dueño necesitan un doble controlable |

## 3. Diseño propuesto

### 3.1 Tres niveles, de menor a mayor costo (el desarrollador elige el menor que sirva a cada prueba)

| Nivel | Qué es | Cuándo se usa | Costo |
|---|---|---|---|
| **N0 · Doble del render** | Servidor de canalización mínimo en el propio proceso de pruebas que implementa `/interno/render/*` con un `IRenderDeDocumento` falso (devuelve un PDF mínimo fijo o un HTML conocido, y puede fallar, tardar o responder con otro dueño a pedido) | `ClienteRenderTests` y todo lo que verifica **la llamada**, no el contenido: 503, reintento sin otra copia, dueño de la canalización, tamaño, token | Muy bajo; sin Chromium ni segunda API |
| **N1 · API de reportes real con render real sustituido** | `ReportesF9Factory` + `ConfigureTestServices` que reemplaza `ConvertidorPdf` por una implementación determinista (PDF generado sin navegador, p. ej. un PDF mínimo válido con el texto del HTML en claro) | Las seis clases a migrar cuando verifican **qué se imprime** (campos del documento, copia, letras del importe) | Medio; reutiliza F9 |
| **N2 · Render real con Chromium** | Solo las pruebas de T4-01/T4-03 (`RenderTrasladoTests`, dorados) | Contenido PDF/HTML real y red de Chromium | Alto; **no en OSHIN-LEGION**, solo en la máquina de B o `LFMB` |

La parte (c) de la regla del plan es: **que la mayoría de las clases migre a N1**, porque N2 depende de un navegador.

### 3.2 Estructura de clases (nombres propuestos; el desarrollador puede cambiarlos)
```
tests/GPOS.Tests/Mvp/ReportesEnProceso/
  ApiConReportesFactory.cs      // generaliza ApiF9Factory: Introspeccion + Reenvio + Exportacion + Render (H-F1)
  ReportesEnProcesoFactory.cs   // generaliza ReportesF9Factory; acepta un IRenderDeDocumento por inyección (H-F2)
  ReportesEnProcesoFixture.cs   // generaliza ReportesF9Fixture; crea roles/usuarios (H-F3)
  RenderFalso.cs                // N0/N1: implementa el render sin Chromium; modos: Normal, Lento(ms), Falla, OtroDueno (H-F5)
  ColeccionReportesEnProceso.cs // [CollectionDefinition]: una sola pareja compartida por varias clases (H-F4)
```
- `ApiF9Factory`, `ReportesF9Factory` y `ReportesF9Fixture` **no se borran en T4-02**: se vuelven alias o se heredan para no tocar `ReportesF9Tests` (que T4-06 y T1-5 también adaptan; ver §5 sobre el orden).
- La **colección compartida** (H-F4) permite que varias clases usen **una** pareja de API y una base: el plan de B lista seis clases; con la colección son una pareja, no seis. Costo: las clases no pueden correr en paralelo entre sí (xUnit las serializa dentro de la colección), lo que además reduce la inestabilidad.
- La canalización de render usa el mismo patrón de nombre con sufijo aleatorio por instancia (`GPOS.Reportes.Render.{sufijo}`), para que dos corridas simultáneas en la misma PC no choquen.

### 3.3 Qué debe ofrecer `RenderFalso` (H-F5)
| Modo | Efecto | Lo usa |
|---|---|---|
| `Normal` | Devuelve un PDF mínimo válido cuyo texto extraíble incluye el HTML recibido (para comprobar que el modelo llegó) | N1: las seis clases |
| `Lento(ms)` | Espera `ms` antes de responder; respeta la cancelación | `Un_render_de_mas_de_30_s_se_cancela` con reloj de pruebas, no 30 s reales |
| `Falla(codigo)` | Responde un error del render (413, 429, 500) | 503 y reintento |
| `OtroDueno` | La canalización pertenece a **otra cuenta** (o falta la ACL esperada) | `El_dueno_de_la_canalizacion_se_verifica_antes_de_enviar_el_modelo` |
| `Caida` | No existe la canalización | `Sin_la_API_de_reportes_imprimir_responde_503...` |
Registra además **qué recibió** (número de llamadas, tamaño del modelo, token presente) para que las pruebas afirmen sobre la llamada.

### 3.4 Qué decide B antes de construir
- **Q-1.** ¿El doble `IRenderDeDocumento` vive en `GPOS.Reportes.Api` como interfaz pública (para poder sustituirlo con `ConfigureTestServices`) o se sustituye `ConvertidorPdf` directamente? Recomiendo la interfaz: es la costura que T4-01 ya necesita para N0/N1.
- **Q-2.** ¿Se acepta la **colección compartida** (H-F4) aunque cambie el aislamiento entre clases? Recomiendo sí; si una clase deja la base sucia, usa su propia empresa dentro de la misma base (hay un fixture de empresas).
- **Q-3.** ¿Quién paga el cambio de `ApiMvpFactory`? Lo toca T1-5 de D1 (`AccesoPruebas`); ver §5.

## 4. Plan de pruebas de T4-02

### 4.1 `ClienteRenderTests` (nivel N0, sin base salvo cuando se indica)
| ID | Prueba | Falla si… |
|---|---|---|
| CR-01 | `Sin_la_API_de_reportes_imprimir_responde_503_y_el_documento_queda_guardado` (modo `Caida`): 503 `REPORTES_NO_DISPONIBLE`; el documento y su número **ya existen** en la base (SQL); no hay medio documento | el 503 revierte la venta o deja un documento sin número |
| CR-02 | `Si_el_render_falla_el_reintento_no_cuenta_otra_copia` (modo `Falla` y luego `Normal`): reimprimir tras el fallo **no incrementa el contador de copias** ni cambia el consecutivo; solo la impresión efectiva cuenta (SQL) | el fallo ya contó la copia (la prueba compara el contador antes/después) |
| CR-03 | `El_dueno_de_la_canalizacion_se_verifica_antes_de_enviar_el_modelo` (modo `OtroDueno`): **el doble no recibe ni un byte del modelo** (su contador de bytes es 0), la respuesta es 503 y se emite el evento 5122 | el cliente envía primero y verifica después |
| CR-04 | El token del usuario viaja y el servidor lo valida (modo `Normal` y modo «token vencido»): un token vencido ⇒ rechazo del lado del render, no impresión | se envía un token genérico o ninguno |
| CR-05 | El modelo enviado **no contiene datos de otra empresa** (empresa A imprime; el modelo recibido solo trae su empresa) | `FabricaModelo` mezcla empresas |
| CR-06 | Tamaño: un modelo con 10 000 líneas ⇒ 413 `REPORTE_DEMASIADO_GRANDE` mapeado, no 500 | el 413 se pierde |
| CR-07 | Cancelación: el cliente cancela y el render recibe la cancelación (modo `Lento`) | la API de reportes sigue renderizando para nadie |
| CR-08 | 30 s: respuesta que excede el tiempo ⇒ 504/503 definido y registro del evento; sin esperas reales de 30 s (reloj de pruebas) | la principal queda colgada |
| CR-09 | Sin Chromium ni red: el cliente no necesita nada de eso (la prueba corre sin `PuppeteerSharp` cargado: ver 4.3) | la principal vuelve a depender del motor |

### 4.2 Las seis clases a migrar (N1)
Para cada una: **qué verifica hoy**, **cómo migrar**, **riesgo**.

| Clase | Qué hay que conservar | Cómo migrar | Riesgo |
|---|---|---|---|
| `ImpresionDocumentosTests` | Que cada tipo de documento imprime con sus datos | Pasa a N1 con `RenderFalso.Normal`. Las aserciones sobre HTML pasan a leer el texto extraído del PDF falso | Aserciones sobre HTML exacto: los dorados de T4-01 las cubren; aquí no duplicar |
| `ModeloNg/ReimpresionTests` | Reimpresión con «COPIA» y contador | N1; añadir el caso CR-02 desde este nivel | El contador de copias es del servidor: no debe moverse |
| `ModeloNg/ReglasReimpresionTests` | Reglas de quién y cuándo se reimprime | Probablemente **N0** (no mira el PDF) | Si solo mira reglas, no debe necesitar la segunda API |
| `NumeracionPc3EjemploTests` | Ejemplo de numeración en formato | N1 | Cuidado con el orden de bloqueos (ADR-45): el render **no** debe ocurrir dentro de la transacción de la numeración |
| `SeguridadPc3Tests` | Permisos y aislamiento al imprimir | N1; incluir que la API de reportes **vuelve a aplicar** `rptsis.PermisoEfectivo` (defensa en profundidad, plan §9) | Es la clase de más riesgo: no relajar ninguna aserción de permisos |
| `Mvp/FlujosMvpTests` | Flujos completos (venta, cierre, transferencias) | Pasa a la colección compartida (N1) | Es la que más tardará; evita crear una pareja nueva |

Regla de migración común: **no cambiar una aserción de seguridad para que pase**; si una aserción depende del HTML exacto, se mueve a los dorados de T4-01, no se borra.

### 4.3 Pruebas que se mueven o se crean fuera de las seis
| ID | Prueba | Tipo | Nota |
|---|---|---|---|
| AR-01 | `GPOS_Api_no_referencia_motores_de_render` (renombrada desde `GPOS_Api_no_agrega_motores_de_render_a_los_que_ya_tiene`, `motoresPendientesDeMover` vacío) | ARQ | Mutación: agregar un `PackageReference` a Puppeteer/QuestPDF/Razor RuntimeCompilation a `GPOS.Api.csproj` debe hacerla fallar. Que se compruebe contra el **grafo de ensamblados resuelto**, no solo contra el `.csproj` (un paquete transitivo también cuenta) |
| AR-02 | Ningún `using` de `PuppeteerSharp`/`QuestPDF`/`Microsoft.AspNetCore.Mvc.Razor.RuntimeCompilation` queda en `GPOS.Api` | ARQ | Complemento de AR-01 |
| AR-03 | ClosedXML **sigue** en la principal (importación de plantillas): no se borra por error al limpiar paquetes | ARQ | El plan lo advierte expresamente |
| AR-04 | `FabricaModelo` sigue en `GPOS.Api` y arma el modelo; no se mueve (Q-T4-01) | ARQ | Evita que el modelo se arme dentro del proceso de reportes antes de tiempo |
| AR-05 | Las rutas antiguas de la principal conservan **ruta, método y DTO** (§6.2): comparar contra un contrato congelado | HTTP | Si falla, los clientes Web/MAUI se rompen |
| CL-01 | `GPOS.Web.Tests/ReimpresionPantallasTests` y `GPOS.UI.MAUI.Tests/ClienteNativoTests` **sin cambios**: correr y verificar verde | UI | Lo exige el plan; no se modifican |

### 4.4 Casos de salida del render que hoy no tienen prueba (mencionados en los hallazgos)
- **H-T4-10:** si la API de reportes cae, el POS no imprime pero **la venta se guarda** y la reimpresión posterior funciona. Es CR-01 más una prueba end-to-end: caer → vender → levantar → reimprimir. (Nueva: `FlujosMvpTests.Venta_con_reportes_caidos_se_guarda_y_se_reimprime_despues`.)
- **H-T4-09:** una imagen `http://` en una plantilla no sale a la red (es de T4-03, no de T4-02; se anota para que quien las escriba use el mismo `RenderFalso`/N2).

## 5. Orden y conflictos (plan §6.4)
- T4-02 se une **después del 11-13** y después de que T1-5 de D1 adopte `AccesoPruebas`. El fixture nuevo debe construirse **sobre `AccesoPruebas`**, no sobre el `ApiMvpFactory` actual, para no rehacerlo. **No empezar a construirlo antes de que T1-5 esté unida**, o se rehace.
- El **diseño** (este documento) sí puede revisarse ya; lo único que depende de T1-5 es la firma de `ApiConReportesFactory`.
- `ReportesF9Tests` no se toca aquí: lo adaptan T4-06 (antes del 11-11) y T1-5. Los alias de §3.2 evitan un tercer cambio.
- Compilación: el fixture nuevo no agrega proyectos; usa el `extern alias reportes` que ya existe.

## 6. Esfuerzo (inferido, ±40 %)
- Fixture + `RenderFalso` + colección: ~1,0 dp.
- `ClienteRenderTests` (CR-01..09): ~0,75 dp.
- Migración de las seis clases: ~1,25 dp (la de más peso es `FlujosMvpTests`).
- AR-01..05 + CL-01: ~0,4 dp.
- Total ≈ **3,4 dp**, que cabe en los 3,5 dp de T4-02 solo si el fixture lo construye quien ya hizo T4-01 y T1-5 llega antes. B decide si lo asume el agente de T4-02 o lo asigna a C.

## 7. Lo que no verifiqué
- No leí ninguna de las seis clases ni `ClienteRender` (no existe). La columna «Qué hay que conservar» es inferencia a partir de sus nombres.
- No compilé el fixture ni comprobé que `ConvertidorPdf` sea sustituible por inyección: Q-1 lo deja a B.
- No medí tiempos; las cifras de costo son estimaciones.
