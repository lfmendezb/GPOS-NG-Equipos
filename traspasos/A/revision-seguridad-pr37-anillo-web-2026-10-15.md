# Informe de Seguridad: PR #37, anillo H-17 v2 en GPOS.Web (con N-15 y AN-05)

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #37, rama `a/cr-h17-v2-web` @ `8ab2f45f`, contra la base `a/cr-h17-v2` @ `386f02cc` (worktree `GPOS-NG-cr`). Son 13 archivos, +367 y −32 líneas.

**Contrato:** H-17 v2, puntos 6 y 7; `[PSF]` 4C.5; ADR-77 (N-15); mi informe del PR #34 (AN-01 a AN-05).

**Método:** no compilé ni ejecuté pruebas. Las cifras que menciono son las que declara el PR (`GPOS.Web.Tests` 641/641, anillo y arquitectura 228/228) y no las reproduje.

---

## 1. Alcance y superficie revisada

- **Configuración y comprobación de la Web:** `src/GPOS.Web/Servicios/ProteccionDatosWeb.cs` y `Program.cs`.
- **Proyecto de la Web:** `GPOS.Web.csproj`, con el vínculo a tres archivos de `GPOS.Core/Infraestructura/Anillo` y la referencia a `GPOS.Criptografia`.
- **Cambios en el adaptador que también usa la API:** `AnilloDataProtection.cs`, `ConformidadAnillo.MotivoRechazo` y `ProveedorSoloLectura`.
- **Guarda de arquitectura:** `AnilloArquitecturaTests` (frontera Web/Core).

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| AW-01 | Baja | La Web no tiene ancla con MAC: quien escribe en su carpeta puede inyectar una llave conforme (con el certificado de la Web y la recuperación configurada, o sin ella). Es el residual de DL-20, con poco impacto en la Web |
| AW-02 | Informativa | Nada impide configurar la misma carpeta para la Web y para la API (hoy falla cerrado por la DACL) |
| AW-03 | Informativa | `DpapiDemo` en la Web: mismo criterio y misma observación que AN-05 |

No hay hallazgos Críticos, Altos ni Medios.

---

## 3. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| **¿Los cambios del adaptador debilitan la API?** | **No.** `recuperacionOpcional` vale `false` por omisión en `Registrar`, `XmlCifradorAnillo`, `RepositorioAnilloConforme` y `MotivoRechazo`, y la API llama a `Registrar(servicios, config, carpeta)` sin el parámetro. La rama nueva del cifrador solo se ejecuta con `recuperacionOpcional`. `ProveedorSoloLectura` recibe ahora el nombre de la aplicación, y la API y `recuperar-anillo` le pasan `ProteccionDatosInstalacion.NombreAplicacion` («GPost»). Para la API, el comportamiento es idéntico | `ProteccionDatosInstalacion.cs:55`; `ComprobacionAnillo.cs`; `RecuperarAnillo.cs`; `ConformidadAnillo.cs:101-111` |
| Frontera Web/Core | Correcta. La Web referencia `GPOS.Criptografia` y compila como vínculo solo tres archivos del adaptador (sin base de datos). La prueba de arquitectura comprueba que la Web no referencia `GPOS.Core`, que solo vincula esos tres archivos y que estos no usan otros espacios de nombres de Core. Así hay una sola fuente de código de seguridad | `GPOS.Web.csproj`; `AnilloArquitecturaTests` |
| Web sin ancla | El decorador exige un principal admitido y que la recuperación sea la **configurada**. Sin recuperación configurada, solo admite llaves **sin** recuperación (rechaza las que traen una). Con recuperación configurada, rechaza las que no la traen o traen otra. Ver AW-01 | `ConformidadAnillo.MotivoRechazo`; `ProteccionDatosWeb.cs:118-131` |
| Cifrador de la Web | Solo crea llaves con el estado comprobado (`Anclada`) y la carpeta conforme. Sin recuperación configurada, envuelve solo para el principal. Si aparece una recuperación configurada que no se comprobó al arrancar, se niega. Un certificado no válido deja el estado en `SinComprobar`, así que no crea llaves (falla cerrado: la Web no puede emitir cookies) | `AnilloDataProtection.cs` (`XmlCifradorAnillo`); `ProteccionDatosWeb.cs:115-121` |
| N-15 / AN-05 en la Web | Verificado. En Release se rechaza `DpapiMaquina = true`. Sin certificado, Release no arranca salvo con `DpapiDemo`, que Estricto rechaza. Con el anillo, la carpeta es obligatoria y no se combina con DPAPI | `ProteccionDatosWeb.cs:47-76` |
| Comprobación antes de servir | Verificado. `ComprobarAlArrancar` corre después de `Build()` y antes de `app.Run()`. Hasta entonces el cifrador se niega, porque el estado empieza en `SinComprobar`. Comprueba la carpeta (en Estricto, una carpeta no conforme impide arrancar), el certificado, la recuperación y las llaves ajenas | `Program.cs:88, 154`; `ProteccionDatosWeb.cs:83-133` |
| Qué protege Data Protection en la Web | Solo la cookie de sesión y la antifalsificación (no encontré otro `CreateProtector` en la Web). La cookie lleva un id de sesión aleatorio que apunta a una sesión en memoria (`AlmacenSesiones`), y el token de la API no viaja en la cookie. Perder el anillo de la Web solo obliga a iniciar sesión de nuevo, por eso la recuperación opcional es razonable | `Program.cs:30-40` |

---

## 4. Hallazgos

### AW-01 · Baja · Llave conforme inyectada en el anillo de la Web (residual de DL-20)

- **Riesgo:** sin ancla con MAC, la Web confía en la recuperación configurada (o en ninguna). Quien pueda escribir en la carpeta de la Web (SYSTEM, Administradores, la identidad del servicio de la Web o la restauración de un respaldo) puede inyectar una llave conforme, envuelta para el certificado de la Web y la recuperación configurada o sin recuperación, y elegir su material. Es el mismo residual que AN-01 en la API, que cierra DL-20.
- **Impacto en la Web, menor que en la API:**
  - falsificar una cookie no da una sesión, porque esta vive en memoria con un id aleatorio;
  - con la llave se podrían descifrar cookies capturadas para obtener ids de sesión, pero eso exige además capturarlas (van por HTTPS y son `HttpOnly`);
  - la antifalsificación se podría falsificar, aunque `SameSite=Strict` ya mitiga el CSRF.
- **Remediación:** la de DL-20 (firma RSA-PSS de cada llave), aplicada también a la Web cuando se firme. Mientras tanto basta con la DACL de AN-03.

### AW-02 · Informativa · Carpeta compartida entre la Web y la API

Si por error se configura la misma carpeta, cada servicio rechaza las llaves del otro (principal no admitido y nombre de aplicación distinto), y la comprobación de la DACL falla para uno de los dos (solo admite una identidad de servicio). El resultado es que falla cerrado, con poca claridad. Conviene que la comprobación de la Web lo diga expresamente (por ejemplo, avisar si en la carpeta hay llaves envueltas para otro principal, que hoy cuentan como «ajenas») y que el instalador use carpetas distintas.

### AW-03 · Informativa · `DpapiDemo` en la Web

Es el mismo criterio que en la API: el modo Estricto se lee de `GPOS:Seguridad:ModoIdentidad`. La Web no conoce el anillo de la licencia, así que no puede aplicar la remediación propuesta para AN-05 (rechazarlo con una licencia `Produccion`). El impacto en la Web es bajo (solo cookies). Conviene que el instalador de producción nunca escriba `DpapiDemo` y que S5 lo informe.

---

## 5. Controles bien implementados

- **Una sola fuente del adaptador**, sin referenciar `GPOS.Core` y con una guarda de arquitectura.
- **Cambios del adaptador sin efecto en la API** (parámetros opcionales que valen `false` por omisión).
- **La Web falla cerrado:** no crea llaves antes de la comprobación, con la carpeta no conforme ni con el certificado no válido; en Estricto no arranca.
- **N-15 y AN-05** también en la Web.
- **Recuperación opcional pero coherente:** sin recuperación configurada, se rechazan las llaves que traen una; con recuperación configurada, se rechazan las que no la traen.

---

## 6. Recomendación

**PR #37: Aprobado con observaciones.**

No hay hallazgos Críticos, Altos ni Medios. Los cambios no debilitan la API. El residual de la Web (AW-01) es el de DL-20, con poco impacto. Es una recomendación técnica: la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr37-anillo-web-2026-10-15.md`
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir; la búsqueda de usos de Data Protection en la Web fue por texto (`CreateProtector`, `IDataProtect`).
- Decisiones candidatas a ADR: Ninguna nueva (DL-20 cubre también la Web).
- Entregas a otros agentes:
  - desarrollador-backend: el aviso explícito de carpeta compartida (AW-02);
  - devops: carpetas distintas para la Web y la API, y nunca `DpapiDemo` en producción (AW-03);
  - arquitecto: que DL-20 incluya el anillo de la Web
- Próximo paso recomendado: unir el PR #37 después del #34.
