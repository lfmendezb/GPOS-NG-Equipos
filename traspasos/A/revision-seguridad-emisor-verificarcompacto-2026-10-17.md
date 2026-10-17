# Informe de seguridad: emisor de licencias, `autNivel` verificado con `VerificarCompacto`

- **Fecha:** 2026-10-17
- **Agente:** auditor-seguridad (v3.1.0)
- **Repositorio:** `C:\Users\lfmen\source\repos\GSF.EmisorLicencias` (local, sin remoto)
- **Cambio revisado:** `git diff 7db1950..5f5bae0` (commits `51526d7`, `62f321f`, `5f5bae0`); submódulo `externo/GPOS-NG` de `b5e4c486` a `e80f4654`
- **Referencias:** `blueprint-licencia-lote2-2026-10-14.md` (6.1.2, 9.2, SEG-L2-09, SEG-L2-10, SEG-L2-19); en el submódulo, `AutorizacionRegresoNivel.cs`, `PisoNivelFirma.cs`, `LectorContenidoLicencia.cs` y `VerificadorJws.cs`

Las rutas `src/...` y `tests/...` son del repositorio del emisor. Las de `externo/GPOS-NG/...` son del submódulo en `e80f4654`.

## 1. Alcance y superficie revisada

- `src/Emisor/Emision/LlavesPublicadas.cs`: `ComprobacionLlaves.VerificarAutorizacion`, que sustituye a `VerificarAutorizacionProvisional`, y la lista propia `MiembrosAutorizacion`.
- `src/Emisor/Emision/ReglasEmisor.cs`: `ArmarAutorizacion` y la regla nueva de caducidad en `ComprobarLicenciaConAutorizacion`.
- `src/Emisor/Emision/ServicioEmision.cs`: los dos llamadores, que son la emisión de una licencia con `autNivel` y la verificación posterior de la autorización recién firmada.
- `src/Emisor/Proveedores/ResumenFirma.cs`: cambio de tipo y borrado de `ContenidoAutorizacionRegreso.cs`.
- Pruebas nuevas o cambiadas: `AutorizacionRegresoTests.cs` y `ReglasEmisorTests.cs`.
- Salto del submódulo: cambios en `GPOS.Criptografia` y en `GPOS.Contracts/Licencia` entre `b5e4c486` y `e80f4654`.
- Guarda CR-04 de `externo/GPOS-NG/src/GPOS.Criptografia/GPOS.Criptografia.csproj` y su efecto en la compilación del emisor.

**Comandos ejecutados (resultados reales):**

| Comando | Resultado |
|---|---|
| `dotnet test GSF.EmisorLicencias.slnx -c Release` | 91 de 91 correctas, 0 errores |
| `dotnet build src/Emisor/... -c Release -p:DefineConstants=DEBUG` | Falla con el error CR-04 de `GPOS.Criptografia.csproj(34,5)`. Es lo esperado |
| `DefineConstants=DEBUG dotnet build src/Emisor/... -c Release` (variable de entorno) | Falla con el mismo error CR-04. Es lo esperado |
| `dotnet build src/Emisor/... -c Debug -p:DefineConstants=TRACE` | Falla con el error CR-04 de `GPOS.Criptografia.csproj(36,5)`. Es lo esperado |
| `dotnet build GSF.EmisorLicencias.slnx -c Release` y `-c Debug` | 0 errores (se recompiló para dejar `bin/obj` como estaban) |

Las compilaciones negativas escribieron su salida en el scratchpad de la sesión. El árbol de trabajo quedó limpio: `git status` sin cambios.

**Lo que no se revisó:** la suite de `GPOS.Tests` del submódulo (`VerificadorJwsCompactoTests.cs` existe, pero no la ejecuté) y los PR ajenos a la licencia que trae el salto del submódulo.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| EV-01 | Baja | Las listas propias del modelo cerrado (miembros y obligatorios) pueden divergir de las de la API sin que falle ninguna prueba | Verificado |
| EV-02 | Baja | El emisor no valida el formato de `instalaciones` al leer la autorización; la API sí | Verificado |
| EV-03 | Baja | La caducidad se compara con `emitida` (NTP − 1 h) y no con la hora NTP, y no hay cota inferior en `desde`: `s2` puede firmar fuera de la ventana autorizada | Verificado |
| EV-04 | Baja | `VerificarAutorizacion` es pública y acepta un `IVerificadorJws` cualquiera (el patrón RA-03 que la API ya cerró) | Verificado |
| EV-05 | Baja | El propio proyecto del emisor no tiene guarda CR-04 para sus `#if DEBUG`; hoy solo lo protege la de `GPOS.Criptografia` | Verificado (protección actual) / inferido (vía de elusión) |
| EV-06 | Informativa | Prueba del `kid` de desarrollo sin aserción en Debug; ninguna prueba de duplicados en el emisor | Verificado |
| EV-07 | Informativa | El salto del submódulo incorpora `CifradorAnillo` y `ConformidadAnillo` al binario del emisor | Verificado |

No hay hallazgos Críticos, Altos ni Medios.

**Por qué ninguno sube de Baja.** La API vuelve a verificar la autorización por completo en `AutorizacionRegresoNivel.Verificar` (`externo/GPOS-NG/src/GPOS.Core/Sistema/Licencia/AutorizacionRegresoNivel.cs:70-132`). Todas las diferencias de este cambio fallan cerradas: en el peor caso, el emisor firma un archivo que la API rechaza (422 `AUTORIZACION_INVALIDA`) o se niega a firmar uno que la API aceptaría. Ninguna diferencia permite que la API acepte una licencia indebida.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | No aplica a este cambio: herramienta de consola, sin endpoints. El control equivalente (qué llave firma qué) está bien (sección 5) |
| A02 Fallos criptográficos | Correcto: ES256 con P1363 de 64 bytes, `alg` fijo, `typ` exacto, sin `crit` ni `b64` (`VerificadorJws.cs:115-137, 178-193, 253-270`). Observaciones EV-04 y EV-05 |
| A03 Inyección | No aplica: no hay consultas ni plantillas. La entrada JSON pasa por el lector estricto |
| A04 Diseño inseguro | Observaciones EV-01 y EV-03 (consistencia del modelo cerrado y ventana de uso de `s2`) |
| A05 Configuración | Guarda CR-04 verificada (sección 5). Observación EV-05 |
| A06 Componentes vulnerables | No aplica: no cambian paquetes NuGet. El submódulo es código propio (EV-07) |
| A07 Autenticación | No aplica: la confirmación del custodio no cambia |
| A08 Integridad de software y datos | Correcto: verificación posterior con la misma biblioteca que la API (SEG-L2-19) y comparación byte a byte del contenido (`ServicioEmision.cs:142-144`). Observación EV-01 |
| A09 Registro y monitoreo | Sin cambios: los rechazos siguen en el registro encadenado (`ServicioEmision.cs:108-112, 151-155`). Los mensajes no exponen secretos |
| A10 SSRF | No aplica |

## 4. Hallazgos

### EV-01 (Baja): las listas propias del modelo cerrado pueden divergir de las de la API sin que falle ninguna prueba

**Riesgo.** El emisor repite las dos listas de la API, `ObligatoriosAutorizacion` y `MiembrosAutorizacion`, porque no referencia `GPOS.Core`. La única prueba (`ModeloCerradoDeLaAutorizacion_CoincideConLosNombresSerializados`) compara la lista del emisor con los nombres serializados del contrato `ContenidoAutorizacionNivel`, no con la lista de la API. Así quedan sin detectar estos casos:

- la API cambia `LectorContenidoLicencia.MiembrosAutorizacion` (quita o restringe un miembro) sin tocar el contrato;
- la API cambia `ObligatoriosAutorizacion` (por ejemplo, hace obligatoria `instalaciones`), lista que no tiene ninguna prueba.

Solo se detecta el caso en que el contrato gana una propiedad y el emisor no la agrega. El efecto falla cerrado: el emisor firmaría autorizaciones que la API rechaza, o rechazaría las que la API acepta. No hay vía de aceptación indebida, pero sí un riesgo operativo en un procedimiento de emergencia: el regreso a Básico se usa cuando falta la YubiKey.

**Evidencia:**
- `src/Emisor/Emision/LlavesPublicadas.cs:83` (obligatorios, sin prueba)
- `src/Emisor/Emision/LlavesPublicadas.cs:90-91` (miembros)
- `tests/GSF.EmisorLicencias.Tests/ReglasEmisorTests.cs:277-282` (la prueba compara con el contrato)
- `externo/GPOS-NG/src/GPOS.Core/Sistema/Licencia/LectorContenidoLicencia.cs:60` y `:63-64` (listas de la API, `private` y `public` en `GPOS.Core`)

**Remediación.** Opción recomendada, alrededor de 0,15 dp en un PR de GPOS-NG:
- mover las dos listas a `GPOS.Contracts/Licencia/FormatoLicencia.cs`, por ejemplo `FormatoLicencia.Autorizacion.Miembros` y `Obligatorios`;
- ese archivo ya está enlazado en el emisor (`src/Emisor/GSF.EmisorLicencias.csproj`);
- `LectorContenidoLicencia` y `ComprobacionLlaves` las consumen desde ahí, con una sola fuente y sin posibilidad de divergencia.

*Alternativa más barata, descartada como definitiva* (alrededor de 0,05 dp, solo en el emisor): una prueba que lea el texto de `externo/GPOS-NG/src/GPOS.Core/Sistema/Licencia/LectorContenidoLicencia.cs` y compare las dos listas. Detecta la divergencia, pero depende del formato del código fuente y se rompe con cualquier refactorización.

### EV-02 (Baja): el emisor no valida el formato de `instalaciones` al leer la autorización

**Riesgo.** La API rechaza una autorización con un `InstalacionId` que no es un GUID en formato D. `VerificarAutorizacion` del emisor no lo comprueba. En la ruta propia no hay impacto, porque `ArmarAutorizacion` ya lo valida antes de firmar (`src/Emisor/Emision/ReglasEmisor.cs` dentro de `ArmarAutorizacion`, comprobación de `FormatoInstalacion.EsValido` y duplicados). Sí hay diferencia cuando el emisor recibe un `autNivel` en `EmitirAsync`: falla cerrado, porque la API rechazaría la licencia. Contradice además el objetivo declarado de verificar «como la API».

**Evidencia:**
- `src/Emisor/Emision/LlavesPublicadas.cs:119-121` (comprueba Kind UTC y `sec`, no `instalaciones`)
- `externo/GPOS-NG/src/GPOS.Core/Sistema/Licencia/LectorContenidoLicencia.cs:159-160` (la API lo comprueba)

**Remediación.** Agregar a la condición de la línea 119 `a.Instalaciones?.Any(i => !FormatoInstalacion.EsValido(i))`, con una prueba. Costo: alrededor de 0,05 dp. Si se adopta EV-01, conviene mover también esta validación a un helper común del contrato.

### EV-03 (Baja): la caducidad usa `emitida` y no la hora NTP, y no hay cota inferior en `desde`

**Coherencia con la API: verificada.** La API rechaza si `max(horaReferencia, emitida) > hasta` (`AutorizacionRegresoNivel.cs:101`; blueprint 6.1.2, punto 3). Por tanto, `emitida > hasta` es un subconjunto estricto de lo que la API rechaza. La regla nueva solo evita firmar archivos inútiles y **no abre ninguna vía de emisión indebida**. Se cumple lo pedido.

**Riesgo residual (control del operador sobre el uso de `s2`):**

1. **Retraso de una hora.** `emitida = NTP − 1 h` (`src/Emisor/Emision/ReglasEmisor.cs:147`). Por eso `s2` puede firmar hasta 1 hora real después de `hasta` sin que el emisor lo impida. La API rechaza esos archivos salvo que se carguen con una hora de referencia ≤ `hasta`, lo cual en la práctica es imposible.
2. **Sin cota inferior.** El emisor no impide que `s2` firme antes de `desde`, y la API acepta esa licencia si se carga dentro de `[desde, hasta]`: la cota inferior usa la hora de referencia, no `emitida`. Esto **no alarga la vigencia**, que sigue acotada por `vence ≤ fecha RD(hasta) + 31` y por la ventana. Lo que sí permite es usar la llave latente fuera de la ventana que autorizó la firma Avanzada. Eso empobrece la auditoría: el registro mostraría usos de `s2` anteriores a la causa que los justifica, y en un escenario `SospechaEquipoEmisor` esa es justo la señal que interesa ver.

**Evidencia:**
- `src/Emisor/Emision/ReglasEmisor.cs:285-286` (regla nueva)
- `src/Emisor/Emision/ReglasEmisor.cs:147` (cálculo de `emitida`)
- `src/Emisor/Emision/ServicioEmision.cs:66-78` (el `ntp` está disponible en el mismo método)
- `tests/GSF.EmisorLicencias.Tests/ReglasEmisorTests.cs:263-267`

**Remediación** (alrededor de 0,1 dp):
- pasar la hora NTP a `ComprobarLicenciaConAutorizacion` y rechazar si `ntp > hasta`;
- decidir explícitamente si `s2` puede firmar antes de `desde`. Mi recomendación es rechazar `ntp < desde`, porque la autorización se pide para usarla y no hay un caso operativo documentado para firmar por adelantado;
- si el propietario prefiere admitirlo, que quede en el registro con una marca propia.

Es una decisión de política: va en Decisiones candidatas a ADR.

### EV-04 (Baja): `VerificarAutorizacion` es pública y acepta un `IVerificadorJws` cualquiera

**Riesgo.** El método decide qué contenido se da por verificado, pero confía en el `ResultadoJws` de un verificador recibido por parámetro. Un verificador ajeno o un doble de prueba podría devolver el resultado verdadero de otro JWS. La revisión de seguridad del PR #32 cerró este mismo patrón en la API (RA-03): `PisoNivelFirma.EleveDesdeLicencia` solo expone la sobrecarga con el verificador real y deja la inyectable como `internal`.

Hoy el único llamador usa una instancia real, privada y de solo lectura, así que no es explotable. Es una cuestión de robustez frente a cambios futuros.

**Evidencia:**
- `src/Emisor/Emision/LlavesPublicadas.cs:99` (`public static ... IVerificadorJws verificador`)
- `src/Emisor/Emision/ServicioEmision.cs:26` (instancia real)
- `externo/GPOS-NG/src/GPOS.Core/Sistema/Licencia/PisoNivelFirma.cs:126-133` (patrón de la API)

**Remediación** (alrededor de 0,05 dp): una sobrecarga pública `VerificarAutorizacion(string, ConjuntoLlaves)` que use `new VerificadorJws()`, y la que recibe el verificador como `internal` (el proyecto de pruebas ya tiene `InternalsVisibleTo`).

### EV-05 (Baja): el proyecto del emisor no tiene guarda CR-04 propia

**Lo verificado.** La guarda de `GPOS.Criptografia.csproj` funciona y se propaga al emisor: `-c Release` con `DEBUG` (por propiedad o por variable de entorno) y `-c Debug` sin `DEBUG` hacen fallar toda la compilación (sección 1). Como el recurso de llaves de desarrollo y `LlavesDesarrollo.AdmitidasEnEstaCompilacion` se compilan en ese ensamblado, el rechazo del `kid` de desarrollo en Release (`VerificadorJws.cs:61, 142-144`) queda garantizado en el emisor. Tampoco hay `Directory.Build.props` en el emisor ni en el submódulo que pueda separar las propiedades de los dos proyectos.

**Riesgo residual (inferido).** El emisor tiene sus propios `#if DEBUG`: `GuardaEquipo.CompilacionDepuracion` y la carga del proveedor de software. Estos `#if DEBUG` solo están protegidos de forma transitiva, porque las propiedades globales llegan a los dos proyectos. Un `DefineConstants` agregado solo en `GSF.EmisorLicencias.csproj` produciría un emisor Release que se cree Debug y carga el proveedor de software sobre un `GPOS.Criptografia` Release. La verificación posterior rechazaría los `kid` de desarrollo, así que falla cerrado. Aun así, el proveedor de software quedaría dentro del binario Release, contra D-1. Esta vía exige un cambio de código en el repositorio, que pasaría por revisión.

**Evidencia:**
- `src/Emisor/Emision/GuardaEquipo.cs:43-48`
- `src/Emisor/Program.cs:74-77`
- `src/Emisor/Emision/ServicioEmision.cs:44-50`
- `externo/GPOS-NG/src/GPOS.Criptografia/GPOS.Criptografia.csproj:29-37`

**Remediación** (alrededor de 0,05 dp): copiar la `Target` `ComprobarDebugCoherente` en `src/Emisor/GSF.EmisorLicencias.csproj`, o mejor en un `Directory.Build.targets` en la raíz del emisor que cubra también las pruebas. Opcional: que el acta E-11 confirme con `huella` que el ejecutable es Release; el `README` ya imprime «Compilación: Release».

### EV-06 (Informativa): cobertura de pruebas

- `KidDeDesarrollo_EnReleaseSeRechazaPorAnillo` solo comprueba `AnilloNoAdmitido` cuando la compilación es Release. En Debug la prueba pasa porque el `kid` no está en el juego, no por el anillo (`tests/GSF.EmisorLicencias.Tests/AutorizacionRegresoTests.cs:104-110`). La suite Release se ejecutó en esta revisión, con 91 de 91. Conviene que el acta y el pipeline del emisor exijan las dos configuraciones, como ya dice el `README`.
- El emisor no tiene ninguna prueba de JSON con miembros duplicados en el encabezado o en el contenido de la autorización. Ese rechazo lo hace `LectorJsonEstricto` (`externo/GPOS-NG/src/GPOS.Criptografia/Jws/LectorJsonEstricto.cs:7-9, 32`), que se cubre en `externo/GPOS-NG/tests/GPOS.Tests/Criptografia/VerificadorJwsCompactoTests.cs` (no ejecutado aquí). Una prueba de humo en el emisor cuesta alrededor de 0,02 dp y fija la dependencia.

### EV-07 (Informativa): el salto del submódulo cambia el binario del emisor

Entre `b5e4c486` y `e80f4654`, `GPOS.Criptografia` incorpora `Anillo/CifradorAnillo.cs` (221 líneas) y `Anillo/ConformidadAnillo.cs` (169 líneas). El emisor no los usa, pero entran en su binario y cambian su SHA-256. `LlavesGsf.json` no cambia: lo verifiqué en el `diff --stat`, y coincide con el SHA anotado en el `README`. No hace falta ninguna acción más allá de anotarlo en el acta E-11, que ya registra los dos commits.

## 5. Controles bien implementados

- **Un solo camino de verificación.** No queda ninguna referencia a `VerificarAutorizacionProvisional` ni a `ContenidoAutorizacionRegreso` en el código del emisor (búsqueda en `5f5bae0`, sin coincidencias). Los dos llamadores (`ServicioEmision.cs:76` y `:142`) usan `VerificarAutorizacion`. `ResumenFirma` solo deserializa la entrada de firma que el propio emisor construyó, para mostrársela al custodio, y no se usa como verificación.
- **`typ`, `alg`, `kid` y nivel, igual que la API.** `VerificarCompacto` con `TiposJws.AutorizacionNivel` (`LlavesPublicadas.cs:101`) aplica:
  - tamaño máximo;
  - base64url estricto;
  - JSON estricto del encabezado y del contenido, sin duplicados;
  - `alg` = ES256, `typ` exacto, `kid` con `FormatoKid` y nivel válido;
  - rechazo de `crit` y `b64`;
  - función de la llave = licencias, nivel coherente con el recurso, firma P1363 de 64 bytes.

  Todo está en `VerificadorJws.cs:115-137, 140-175, 253-270`. Es la misma llamada que hace la API (`AutorizacionRegresoNivel.cs:74`).
- **Firma Avanzada activa y no retirada.** El predicado de `LlavesPublicadas.cs:104-106` es idéntico a `NivelFirmaLicencia.EsAvanzadaPropia` (`PisoNivelFirma.cs:15-17`).
- **`kid` de desarrollo rechazado en Release**, aunque el juego no lo conozca (`VerificadorJws.cs:142-144`), con la admisión ligada a la configuración por la guarda CR-04, verificada en compilación.
- **Modelo cerrado y obligatorios.** Los valores son hoy idénticos a los de la API (`LectorContenidoLicencia.cs:60, 63-64`). Las opciones del deserializador del emisor (`src/Emisor/Jws/ConstructorJws.cs:24-33`) son equivalentes a las de la API en lo relevante: ordinal, números estrictos, sin duplicados y con anotaciones de nulabilidad.
- **Kind UTC** en `desde`, `hasta` e `inicioRegreso`, y `sec > 0`, igual que la API.
- **El verificador del servicio es real**, privado y de solo lectura (`ServicioEmision.cs:26`).
- **Verificación posterior de la autorización firmada** con comparación byte a byte del contenido antes de registrar (`ServicioEmision.cs:142-144`; SEG-L2-19).
- **Licencia con `autNivel`:**
  - el `kid` de la autorización tiene que ser el del proveedor;
  - el proveedor tiene que estar `latente`, publicado y no retirado, y con la misma clave pública (`LlavesPublicadas.cs:64-80` con `conAutorizacion: true`);
  - `crit` incluye `autNivel` (`ReglasEmisor.cs:215`);
  - `vence ≤ fecha RD(hasta) + 31`.
- **Sin secretos** en el código ni en las pruebas: las llaves de prueba se generan en memoria.

## 6. Remediaciones priorizadas

| Prioridad | Hallazgo | Acción | Esfuerzo | Responsable |
|---|---|---|---|---|
| 1 | EV-01 | Mover `Miembros` y `Obligatorios` de la autorización a `FormatoLicencia` (contrato enlazado) y consumirlos en la API y en el emisor | 0,15 dp (PR de GPOS-NG, más una subida del submódulo) | Desarrollador de la API (equipo A) y del emisor |
| 2 | EV-03 | Comparar con la hora NTP; decidir y aplicar la cota en `desde` | 0,1 dp | Desarrollador del emisor, después de la decisión del propietario |
| 3 | EV-02 | Validar el formato de `instalaciones` en `VerificarAutorizacion` | 0,05 dp | Desarrollador del emisor |
| 4 | EV-04 | Sobrecarga pública con el verificador real; la inyectable, `internal` | 0,05 dp | Desarrollador del emisor |
| 5 | EV-05 | Guarda CR-04 propia en el emisor (`Directory.Build.targets`) | 0,05 dp | Devops o desarrollador del emisor |
| 6 | EV-06 | Prueba de duplicados; exigir la suite Release en el acta | 0,02 dp | qa-automatizado |

Total: alrededor de 0,4 dp. Nada bloquea el corte. Las prioridades 2 a 5 caben en un solo commit del emisor.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica: la decisión es del propietario).

El emisor verifica `autNivel` con la misma biblioteca y las mismas comprobaciones criptográficas que la API: `typ`, ES256, `kid`, nivel, firma Avanzada activa y no retirada, `kid` de desarrollo en Release, JSON estricto sin duplicados y modelo cerrado. No queda ningún camino con la verificación vieja. La regla nueva de caducidad es coherente con la API y no abre ninguna vía de emisión indebida. La guarda CR-04 hace fallar la compilación del emisor ante cualquier incoherencia entre `DEBUG` y la configuración.

Las siete observaciones son de severidad Baja o informativas y fallan cerradas. EV-01 es la que más conviene cerrar antes de la primera autorización real, porque convierte la igualdad de las listas en una garantía en lugar de una coincidencia.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-emisor-verificarcompacto-2026-10-17.md`
- Supuestos: se toma `e80f4654` como la versión de la API que comparar; no se ejecutó la suite `GPOS.Tests` del submódulo (la cobertura de duplicados de `VerificarCompacto` se infiere de la existencia de `VerificadorJwsCompactoTests.cs`); el informe se guarda en la raíz de la solución por indicación del encargo, no en `docs/seguridad/`.
- Decisiones candidatas a ADR: política de uso de `s2` respecto de la ventana de `autNivel` (EV-03). Opción recomendada: el emisor rechaza firmar con `hora NTP` fuera de `[desde, hasta]`. Alternativa descartada: admitir la firma anticipada sin marca, porque `s2` quedaría en uso fuera de la ventana autorizada y la auditoría perdería la relación causa-uso.
- Entregas a otros agentes: desarrollador de la API (equipo A) → mover las listas del modelo cerrado de la autorización a `GPOS.Contracts` (EV-01); desarrollador del emisor → EV-02 a EV-05; qa-automatizado → prueba de duplicados y suite Release obligatoria en el acta (EV-06); arquitecto-maestro → preparar para la firma del propietario la decisión de EV-03.
- Próximo paso recomendado: abrir el PR de GPOS-NG de EV-01 y, tras la decisión de EV-03, un solo commit del emisor con EV-02 a EV-05.
