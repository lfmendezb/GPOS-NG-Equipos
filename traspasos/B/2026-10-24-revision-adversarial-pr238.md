Para: B        De: revisor adversarial independiente (agente de B, solo lectura)        Fecha: 2026-10-24
Tipo: Revisión adversarial del PR #238 (`a/t4-02a-correcciones` @ `4c15743d`, base `b/t4-02a` @ `9288b01a`)
Estado: Aprobado con observaciones (recomendación técnica; la orden de unir es del propietario, C2)

Convención: [V] = lo comprobé con un comando y vi el resultado; [I] = inferido del código o de la documentación.
No hice checkout ni commit en el repositorio, no comenté el PR y no empujé nada. Para compilar y mutar usé una copia del árbol de la rama (`git archive`) en el scratchpad de la sesión. Restauré cada mutación y comprobé que el repositorio principal quedó sin cambios.

# 1. Qué se revisó

- Diff completo del PR: 2 archivos, `src/GPOS.Api/Impresion/ClienteRender.cs` y `tests/GPOS.Tests/Impresion/ClienteRenderTests.cs` (+284/−19), en 6 commits, uno por hallazgo [V].
- Encargo: `avisos/B-a-A/2026-10-23-tareas-nuevas-para-a-tanda-8.md`, punto 1 (H210-01, H210-02, S210-01, S210-02, S210-06, R2 y R3; S210-03 a S210-05 quedan fuera).
- Firma: hoja `docs/decisiones/2026-10-23-hoja-firma-s217-02-h210-msi-y-tls-f2-f3.md:14` (corregir H210-01 y H210-02 y añadir R2 y R3 antes de unir el #210; «Ninguno visible»).
- Informes de origen:
  - `traspasos/C/2026-10-23-revision-adversarial-pr210.md` (H210-01 a H210-08, mutaciones MA a MK, pruebas R1 a R8);
  - `traspasos/A/revision-seguridad-pr210-t4-02a-2026-10-23.md` (S210-01 a S210-06).
- Contraparte del servidor, para comprobar las listas blancas:
  - `src/GPOS.Reportes.Api/Seguridad/AutenticacionIntrospeccion.cs:81-103`;
  - `src/GPOS.Reportes.Api/ErroresReportes.cs:37-41`;
  - `src/GPOS.Reportes/Ejecucion/ErroresLectura.cs:136`;
  - `src/GPOS.Comun/Introspeccion/ProtocoloIntrospeccion.cs:36-60`.

# 2. Corridas [V]

| Corrida | Resultado |
|---|---|
| `dotnet test tests/GPOS.Tests/GPOS.Tests.csproj --filter "FullyQualifiedName~GPOS.Tests.Impresion.ClienteRender\|FullyQualifiedName~GPOS.Tests.Impresion.ContratoRenderTests"` sobre `4c15743d` | **78 de 78 correctas**, 4 s. Coincide con el PR |
| Advertencias de compilación en los dos archivos tocados (`--no-incremental`) | Ninguna |
| Suite completa | No la corrí (el PR tampoco) |

# 3. Mutaciones [V]

Cada mutación se aplicó sobre la copia, se compiló, se corrió `ClienteRenderTests` (47 casos) y se restauró el archivo.

| # | Mutación (`ClienteRender.cs` en `4c15743d`, salvo indicación) | Hallazgo que protege | Resultado |
|---|---|---|---|
| M1 | `:203` `TextoFormato(texto)` → `DetalleParaRegla(texto)` (vuelve el defecto) | H210-01 | **Muere**: 2 pruebas |
| M2 | `:55` `MaximoProblemaBytes` 1 MB → 64 KB | H210-02 | **Muere**: el caso de 70.000 caracteres |
| M3 | `:228` el `codigo` del 401 pasa sin la lista blanca | S210-01 | **Muere**: 2 casos |
| M4 | `:230` `MotivoSesion = motivo` sin la lista blanca | S210-01 | **Muere**: 2 casos |
| M5 | `:212` `codigoRegistro = codigo` (sin limpiar) | S210-01 (registro) | **Muere** |
| M6 | Quitar `:209` (tope de 60 s) | S210-02 / H210-07 | **Muere**: delta y fecha |
| M7 | Quitar `:208` (piso de cero; era MK de C) | H210-07 | **Muere**: fecha pasada |
| M8 | Quitar `:184` (32 MB dentro del bucle; era MB de C) | S210-06 / R2 | **Muere** |
| M9 | `:148` `PdfAsync(..., ct)` (cuerpo sin plazo; era MC de C) | R3 | **Muere** a los 20 s |
| M10 | `ReenvioReportes.cs:427` `RedactLoggedHeaders(_ => false)` | S210-06 (token) | **Muere** |
| M11 | `:291` `sb.Append(c)` (deja pasar los controles) | H210-01 | **Muere** |
| M12 | `:79` quitar `factor` de la lista blanca | S210-01 | **Muere** |
| M13 | `:202` `codigo == CodigoFormatoInvalido` → `codigo != null` | — | Sobrevive. **Equivalente**: el único 400 que llega a `Pasa` es `FORMATO_INVALIDO`; los demás van a `NoDisponible` y no usan `detalle` |
| M14 | `ReenvioReportes.cs:427` quitar `RedactLoggedHeaders` del todo | S210-06 (token) | Sobrevive, como declara el PR. Ver O-4 |

Conclusión: todas las correcciones tienen una prueba que falla sin el arreglo. La única mutación que sobrevive y no es equivalente es M14, y el PR ya la declaró.

# 4. Verificación hallazgo por hallazgo

| Hallazgo | ¿Corregido? | Evidencia |
|---|---|---|
| H210-01 (Media, C) | **Sí, con un defecto menor (O-1)** | `ClienteRender.cs:201-204` y `:285-300`: tope propio de 4.000 caracteres; conserva `\r` y `\n`; los demás controles pasan a espacio. Las pruebas `El_texto_de_FORMATO_INVALIDO_llega_igual_con_sus_saltos_de_linea` y `..._se_recorta_en_su_tope_y_sin_controles` son la R5 de C |
| H210-02 (Baja, C) | **Sí, en el cliente** | `:55`, `:255-279`: lee hasta 1 MB con un búfer que crece; con más de 1 MB falla cerrado (503). Prueba con dos casos (70.000 caracteres → 400, 1.100.000 → 503). C prefería acotar en el servidor; el encargo deja la API de reportes fuera, así que la solución del cliente cabe en el encargo. Ver O-3 |
| S210-01 (Baja, A) | **Sí** | `:79`, `:224-231`, `:212`, `:243`, `:246`. Comparé la lista blanca con el servidor [V]: el 401 del desafío no lleva cuerpo y pone `X-GPOS-Sesion` solo con revocada, reemplazada, cerrada o factor (`AutenticacionIntrospeccion.cs:99-102`); el 401 de `SesionInvalidaException` lleva `SESION_INVALIDA` (`ErroresLectura.cs:136`) y un motivo de sesión (`ErroresReportes.cs:37-38`). La lista blanca deja pasar exactamente esos valores. `Pasa` registra el `codigo` crudo (`:216`), pero solo con los códigos exactos del `switch`: no es un hueco |
| S210-02 (Baja, A) / H210-07 (C) | **Sí** | `:69`, `:208-209`. Cinco casos: delta grande, fecha lejana, fecha pasada, 60 s y 2 s |
| S210-06 (Baja, A) / R2 (C) | **Sí** | `Un_PDF_sin_largo_declarado_de_mas_de_32_MB_se_corta_al_leerlo` mata M8. `El_token_no_sale_en_el_registro` recorre el registro de `ClienteRender` y el del cliente con nombre en nivel Trace, en cuatro caminos, y mata M10 |
| R3 (C) | **Sí** | `Un_cuerpo_detenido_tras_los_encabezados_se_abandona_en_el_plazo` mata M9. El código ya pasaba `plazo.Token` desde `9288b01a`; el commit agrega solo la prueba. Ver O-5 |

Alcance [V]:
- Solo se tocan los dos archivos del encargo.
- No toca el núcleo (`GPOS.Core`), la API de reportes, `GPOS.Contracts` ni el esquema.
- No hay SQL: ADR-50 (`varchar`) y el orden de bloqueos no aplican.
- No agrega paquetes, tecnologías ni proyectos.
- No quedan secretos: el token de las pruebas es un literal de prueba.
- La rama está apilada sobre `9288b01a` (merge-base verificado).

# 5. Observaciones

## O-1 (Baja): el recorte de `FORMATO_INVALIDO` puede perder texto sin poner «…»

- **Evidencia [V].** `ClienteRender.cs:288-299`. El bucle se detiene con 4.001 caracteres y después hace `Trim()`. La decisión de poner «…» depende del largo *después* del `Trim` (`:295`), no de si quedó texto sin leer.
- **Escenario.** El carácter 4.000 o 4.001 cae en un salto de línea entre dos diagnósticos (es lo normal en un texto de varias líneas), o el texto empieza con espacios. El `Trim` deja 4.000 caracteres o menos y el texto se devuelve **sin «…»**, aunque se perdieron las líneas siguientes. El SUPER cree que ve todos los diagnósticos.
- **Prueba hostil [V]** (temporal, no está en la rama). Dos casos de `400 FORMATO_INVALIDO`, los dos fallan con `Assert.EndsWith("…")`:
  - `"   " + 5000×'a'`;
  - `3999×'a' + "\r\n\r\nbbbbbb"`: se pierde `bbbbbb` sin aviso.
- **Remedio (unos 20 min).** Marcar `truncado = true` cuando el bucle sale por el tope. Poner «…» según esa marca, no según `limpio.Length`. Agregar el caso de la línea en el borde a la prueba del tope. `DetalleParaRegla` no tiene este problema, porque no acumula espacios al inicio ni al final.

## O-2 (Baja, seguridad): H210-01 amplía la exposición de S210-03 de 300 a 4.000 caracteres

- **Evidencia.** S210-03 de A (`traspasos/A/...:71-73`) aceptó que `FORMATO_INVALIDO` lleve `ex.Message` de la plantilla (`GPOS.Reportes.Api/Impresion/MotorRazor.cs:106`), y lo dio por mitigado porque «queda acotado a 300 caracteres». Con este PR el texto llega hasta 4.000 caracteres y en varias líneas (`ClienteRender.cs:63`, `:203`).
- **Escenario.** Lo ve también el cajero que imprime con un formato roto, no solo el SUPER en el diseñador. Puede ver nombres de tipos o detalles internos de la excepción.
- **No es un defecto del PR.** La tabla 5.3 pide «el mismo texto», y el render en proceso de hoy ya da el texto completo (`GPOS.Api/Impresion/MotorRazor.cs:86,99` según C). Pero la mitigación que citó A desaparece.
- **Remedio.** Que S210-03 (mensaje genérico para los errores de *ejecución*, con el detalle solo en el registro; los diagnósticos de *compilación* sí van completos) sea **condición antes de T4-02b**, no un seguimiento sin fecha. Va en la API de reportes, fuera de este PR.

## O-3 (Informativa): el tope de 1 MB es del cliente; el servidor sigue sin límite

- Un `detail` de más de 1 MB sigue llegando como 503 «avise al administrador» (está probado y es falla cerrada, aceptable).
- El reenvío (`ReenvioReportes.MotivoRechazoAsync`, 64 KB, `ReenvioReportes.cs:261-264`) conserva el comportamiento anterior. Hoy no lleva `FORMATO_INVALIDO`, así que no es un defecto [I].
- La remediación barata de C (acotar `FormatoInvalidoException` en el servidor a 4.000 caracteres) cerraría los dos casos y haría innecesario leer 1 MB. Conviene sumarla a S210-03.

## O-4 (Informativa): `RedactLoggedHeaders(_ => true)` no está fijado por pruebas

- M14 sobrevive [V]: sin la llamada, el token tampoco aparece en el registro de nivel Trace.
- Es coherente con que Microsoft.Extensions.Http redacte los valores de los encabezados por omisión desde .NET 9 [I, no lo verifiqué en la documentación].
- La prueba sí detecta una desactivación explícita (M10). No hace falta cambiar nada. Conviene dejar en el comentario de `ReenvioReportes.cs:427` que la línea es defensa explícita ante un cambio del valor por omisión.

## O-5 (Informativa): títulos y textos del PR

- El commit `4c15743d` se titula «el plazo cubre también la lectura del cuerpo», pero solo agrega la prueba: el código ya estaba bien en `9288b01a` (MC era una mutación, no un defecto).
- En H210-01, el PR pide que el propietario confirme el cambio visible. No lo veo necesario: la hoja firmó «corregir H210-01» con «Ninguno visible», y el resultado iguala lo que hoy muestra el render en proceso y lo que pide la tabla 5.3. Además, todavía no hay llamadores. Lo dejo a juicio de B.
- `CodigoSesionInvalida = "SESION_INVALIDA"` (`:73`) repite el literal de `ErroresLectura.cs:136`. Si cambia uno, la lista blanca descarta el código y la interfaz pierde el `codigo`, aunque no el motivo. Es menor; se puede fijar con una prueba de igualdad si `GPOS.Tests` ve las dos constantes [I].

# 6. Condiciones recomendadas para unir (al unificar con el #210)

1. Corregir O-1 (marca de recorte y prueba con el salto de línea en el borde). Unos 20 min. Si B prefiere no hacerlo ahora, declararlo como seguimiento con dueño.
2. Registrar S210-03 (y el tope del servidor de O-3) como **condición previa a T4-02b**, por O-2.
3. Correr la suite oficial (`--filter "Transicion!=Ola5&Transicion!=Defecto"`) sobre el #210 ya unificado antes de pedir la orden de unión. Ni el PR ni esta revisión la corrieron.
4. Unir solo con la orden del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-24-revision-adversarial-pr238.md` (este informe). Copia de trabajo, registros y diferencias de las mutaciones en el scratchpad de la sesión (`...\scratchpad\pr238`, `...\scratchpad\mut`), fuera del repositorio.
- Supuestos: la redacción por omisión de los encabezados en .NET 9 o posterior (O-4) [I]; el texto del render en proceso de hoy, según el informe de C.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: A → O-1 en `a/t4-02a-correcciones`; B (dueño de la API de reportes) → S210-03 más el tope del servidor como condición de T4-02b.
- Próximo paso recomendado: A corrige O-1; B unifica el #238 con el #210, corre la suite oficial y pide la orden de unión.
