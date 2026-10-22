# Tercera relectura de seguridad · PR-2 de ADR-90 (R2-01, R2-02 y P139-01)

- **Fecha:** 2026-10-22 · **Auditor:** auditor-seguridad (equipo A) · **Es una recomendación técnica. La decisión de unir es del propietario, por medio de B.**
- **Objeto:** `338d899f` (R2-01 y R2-02) y `89f03411` (P139-01, de B) en `a/adr90-rt05-tls-escucha` (`GPOS-NG-pr2`). La punta es `89f03411` y el árbol está limpio.
- **Origen:** `relectura2-seguridad-pr2-adr90-2026-10-22.md` (R2-01, R2-02).
- **Método:** solo lectura (`git show`, `git grep`). No compilé, no ejecuté nada y no cambié de rama. [V] = verificado en el código. [I] = inferido, no ejecutado.
- **Superficie:** no cambia. Los dos commits solo tocan `tests/GPOS.Tests/Arquitectura/` (`OrdenProgramaApiTests.cs` y `RedPlataformaArquitecturaTests.cs`), sin cambios en `src/`.

## 1. Tabla resumen

| ID | Severidad | Estado | Nota |
|---|---|---|---|
| R2-01 | Baja | **Cerrado** | Hay doble barrera: una regla semántica y el texto exacto fijado sobre el `Program.cs` real |
| R2-02 | Baja | **Cerrado** | Los tres huecos quedan cubiertos. Hay dos excepciones nombradas, mínimas y acotadas |
| P139-01 | — | **Correcto** | S5 coincide con `src/GPOS.Api/Program.cs:56` |
| R3-01 | Baja (informativa) | Nueva | Evasiones deliberadas de la acotación por cuerpo y del prefijo libre de S5 |

No hay hallazgos Críticos, Altos ni Medios.

## 2. Verificación

### R2-01 · Cerrado
- **[V] Regla nueva.** `SoloElMensajeALaSalidaDeError` (`OrdenProgramaApiTests.cs:213-227`) funciona en dos pasos:
  - quita la única forma admitida, `Console.Error.WriteLine(<v>.Message);`;
  - falla si queda cualquier uso de la variable o cualquier `Console`/`Write(Line)(Async)(`.

  Un `catch` sin variable que escriba texto propio también falla.
- **[V] Texto exacto.** Además, se fija el texto exacto del `try`/`catch` sobre el `Program.cs` real, como en la Web (`OrdenProgramaApiTests.cs:411-415`). El texto fijado coincide con `src/GPOS.Api/Program.cs:350-351`.
- **[V] Doce muestras negativas** (`:597-609`): `WriteLine(ex)`, `ToString`, `InnerException`, interpolada, `StackTrace`, `Write`, `Console.Out`, alias de `Console.Error`, `using static`, otro método, otra variable y texto propio.
- **¿Se puede evadir?** No en el archivo real: el texto exacto descarta cualquier variante sintáctica. La regla semántica queda como mensaje de diagnóstico.
- **[I] Saltos de línea.** La comparación con `"\n"` supone que `Limpiar` normaliza CRLF, o que el archivo usa LF. Si no fuera así, la prueba fallaría en rojo (falla cerrada, no deja pasar nada). Lo confirmará la suite.

### R2-02 · Cerrado
- **[V] Patrones** (`RedPlataformaArquitecturaTests.cs:113-114`):
  - `\bSslStream\b` ve `new(…)` con tipo de destino y el nombre completo, y no confunde `SslStreamCertificateContext` (autopruebas en `:286-296`);
  - `ServerCertificate\w*ValidationCallback` incluye `ServicePointManager` (`:288-289`).
- **[V] Recorrido.** `ProyectosDeSrc()` (`:164-168`) toma toda carpeta de `src/` que tenga un `.csproj`, sin lista cerrada. Hoy son 12 proyectos y todos tienen el `.csproj` en el primer nivel. Un `Assert.Superset` evita que la regla pase en vacío (`:247`). `Fuentes` lee `.cs` y `.razor` sin `bin` ni `obj`. En `src/` no hay `.cshtml`.
- **[V] Excepciones mínimas.** Son dos (`:142-148`), cada una por proyecto, archivo y firma exacta, con su motivo:
  - `GPOS.Comun.Servidor/ClienteApiLocal.cs`: la sobrecarga `internal` de pruebas;
  - `GPOS.AgenteImpresion/ClienteDispositivo.cs`: `CrearManejador(IReadOnlyList<string> fijadas)`.

  Según `git grep` sobre `89f03411`, las únicas apariciones del patrón en `src/` son `ClienteDispositivo.cs:80` y `ClienteApiLocal.cs:102`, `:107` y `:108`. Todas están dentro de esos cuerpos, así que no sobra ninguna excepción.
- **[V] Acotación.** Fallan los casos siguientes, y hay autoprueba para cada uno (`:259-276`):
  - una aparición fuera del cuerpo de la firma;
  - el archivo de la excepción sin la firma;
  - un archivo con el mismo nombre en otro proyecto;
  - otro archivo del mismo proyecto.

  En el agente, que tiene cuerpo de expresión, el «cuerpo» es el inicializador `new SocketsHttpHandler { … }`, y lo que va después del `;` queda fuera (`:268-269`). Eso es correcto.
- **[V] Reflexión.** Se mantiene la comprobación de que la sobrecarga de pruebas es `internal` y de que no hay otra sobrecarga pública (`:231-235`).
- **[V] Manejador primario.** Se vigila todo `src/` salvo la API (`:325`). La API conserva su regla `ManejadorTodosLosClientes` (`:334-335`), como acepté en la relectura 2.

### P139-01 · S5 refleja el `Program.cs` real
- **[V] Coincidencia.**
  - La regla exige `ServicioRed.Api, (prefijo.)*ComprobacionAnillo.EsEstricto(builder.Configuration))`, con cierre inmediato y sin cuarto argumento (`OrdenProgramaApiTests.cs:174-177`).
  - El programa real dice `EscuchaServidor.Preparar(builder, ServicioRed.Api, GPOS.Core.Infraestructura.Anillo.ComprobacionAnillo.EsEstricto(builder.Configuration))` (`src/GPOS.Api/Program.cs:56`), y coincide.
- **[V] Muestras.** Las cuatro negativas (`false`, `true`, `ProteccionDatosWeb.EsEstricto`, `EsEstricto(otra)`) y las positivas actualizadas están en `:590-599` y `:631-635`.
- **[V] Una sola clase.** Existe una única clase `ComprobacionAnillo` (`src/GPOS.Core/Infraestructura/Anillo/ComprobacionAnillo.cs:44`). Su `EsEstricto` lee la misma clave que `ProteccionDatosWeb.EsEstricto` (`ComprobacionAnillo.cs:47`; `ProteccionDatosWeb.cs:35`), así que la API y la Web deciden Estricto igual.
- **[V] Orden de los commits.** `89f03411` va encima de `338d899f` (índice `aba1376b..a1742ac9`) y no deshace R2-01.

## 3. Observación nueva

### R3-01 · Baja (informativa) · Evasiones deliberadas
- **[V] Prefijo libre en S5.** El prefijo `(?:\w+\s*\.\s*)*` admite otra clase llamada `ComprobacionAnillo` en otro espacio de nombres, o un alias `using`. Hoy esa clase no existe.
- **[V/I] Conteo de llaves.** `CuerpoSiExiste` cuenta llaves sin descontar las de cadenas ni comentarios. Un `"{"` dentro de una de las dos firmas exceptuadas alargaría el cuerpo e incluiría código posterior del mismo archivo. La acotación es por nombre de archivo, no por ruta: un segundo `ClienteApiLocal.cs` dentro de `GPOS.Comun.Servidor`, con la misma firma, quedaría exceptuado.
- **Riesgo.** Todas estas variantes exigen un cambio intencional y llamativo en un archivo de seguridad, y la revisión de código las detecta. Son guardas contra regresiones, como R2-03.
- **Remediación (opcional, minutos).**
  - Fijar el prefijo de S5 a `(?:GPOS\.Core\.Infraestructura\.Anillo\.)?`.
  - Acotar la excepción por ruta relativa en lugar del nombre del archivo.
  - *Descartado:* un analizador de Roslyn (alrededor de 1 día-persona), que no compensa hoy.

## 4. Checklist OWASP (para este lote)
- **A02 y A08:** reforzadas por R2-02 y P139-01.
- **A09:** reforzada por R2-01.
- **A01, A03 a A07 y A10:** no aplican, porque solo cambian pruebas de arquitectura.

## 5. Controles bien implementados
- El texto exacto del `catch` en la API iguala a la Web: solo sale el motivo saneado.
- La vigilancia de la validación propia cubre todo `src/` de forma automática, con excepciones declaradas, motivadas y comprobadas por autopruebas.
- S5 impide que la API arranque en Estricto con un `false` fijo, que la haría arrancar con aviso en lugar de detenerse con el 4743.

## 6. Recomendación
**Aprobado con observaciones** (recomendación técnica). R2-01 y R2-02 quedan cerrados, P139-01 es correcto y no hay regresiones. R3-01 es informativa y no bloquea. Siguen en pie las condiciones de los informes anteriores:
- la suite oficial (`Transicion!=Ola5&Transicion!=Defecto`) en verde sobre `89f03411`, que este revisor no ejecutó;
- la firma de F-5;
- N-1 unido.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\relectura3-seguridad-pr2-adr90-2026-10-22.md`
- Supuestos (todos [I]):
  - `Limpiar` normaliza los saltos de línea, o `Program.cs` usa LF; si no, la prueba de texto exacto falla en rojo;
  - `Assert.Superset(esperado, real)` comprueba que el conjunto real contiene al esperado;
  - no se ejecutó nada.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes:
  - desarrollador de A → R3-01 (opcional, minutos);
  - QA o C → suite oficial sobre `89f03411`.
- Próximo paso recomendado: avisar a B de que PR-2 sigue en «Aprobado con observaciones» con R2-01 y R2-02 cerrados, y unir cuando la suite oficial sobre `89f03411` esté en verde.
