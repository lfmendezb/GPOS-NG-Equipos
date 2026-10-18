# Revisión de seguridad corta: T2 (b) de ADR-126 (archivo de instalación) y D-01

- Fecha: 2026-10-18 · Auditor de seguridad (equipo C) · Solo lectura, sin cambios de código.
- Rama: `c/t2b-archivo-instalacion` (worktree `GPOS-C-intermitentes`, cambios sin commit sobre `322b21d6`).
- Recomendación: **Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2).

## 1. Alcance y superficie revisada

- `src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs` (filtro, carpeta, orden de fuentes, advertencias).
- Uso en `src/GPOS.Api/Program.cs:27,334`, `src/GPOS.Web/Program.cs:11,98`, `src/GPOS.Reportes.Api/Program.cs:20,70`, `src/GPOS.Migracion/Program.cs:38-43`.
- Único consumidor de la sección permitida: `src/GPOS.Api/Servicios/TrabajoRncDgii.cs` (solo lee `GPOS:RncDgii:Url`; los intentos son la constante 3 de la línea 17 y el tiempo límite es de 30 min en `Program.cs:234`; `AgenteUsuario` no se lee en ninguna parte).
- DEMO: `instalador/Demo/scripts/herramientas/Comun-Demo.ps1` y `Instalar-Demo.ps1`, y el ejemplo `GPOS.Api.json.ejemplo`.
- D-01: los cuatro archivos del agente de impresión y del instalador, y la guarda `ValoresDeTercerosTests.cs`.

Comprobaciones hechas (C6):
- Orden real de las fuentes de `WebApplication.CreateBuilder` en .NET 10, con un programa mínimo en el scratchpad: 0 Memory, **1 Env `ASPNETCORE_`**, 2 Memory, **3 Env `DOTNET_`**, 4 `appsettings.json`, 5 `appsettings.{Entorno}.json`, 6-7 JSON adicionales, **8 Env sin prefijo**, 9 Chained.
- JSON con sintaxis inválida: al construir la configuración, `Optional = true` **no** evita el error (`InvalidDataException`). En una recarga, el proceso sigue vivo y la fuente queda vacía.
- ACL de `C:\ProgramData` en este equipo: `BUILTIN\Usuarios:(CI)(WD,AD,WEA,WA)` y `CREATOR OWNER:(OI)(CI)(IO)(F)`. `C:\ProgramData\GPOS NG` no existe.

## 2. Resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| T2B-S01 | Media | Un usuario local sin privilegios puede impedir el arranque de los cuatro procesos con un JSON inválido | Verificado |
| T2B-S02 | Media (latente) | Una `Url` de padrón ajena permite reemplazar el padrón de RNC (integridad fiscal), hacer peticiones ciegas a hosts https internos y llenar el disco | Camino verificado; efecto inferido |
| T2B-S03 | Media (funcional) | El archivo queda **por debajo** de `appsettings.json`, no entre `appsettings.json` y el entorno | Verificado |
| T2B-S04 | Baja | Los cambios en caliente no se registran (ni las claves ignoradas en la recarga ni la `Url` nueva) | Verificado |
| T2B-S05 | Baja | Ventana de carrera en la recarga: el filtro se aplica después de publicar `Data` | Verificado por lectura; efecto inferido |
| T2B-S06 | Baja | El nombre de la clave, que controla quien escribe el archivo, llega sin sanear al registro y a la consola (falsificación de líneas) | Verificado |
| T2B-S07 | Baja | Queda un ejemplo con un dominio registrado por un tercero (`ventas@empresa.com`) fuera del alcance de D-01 | Verificado |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP (acotado al cambio)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Observación: el archivo no tiene DACL propia hasta ADR-77 (S01, S02) |
| A02 Criptografía | No aplica (el archivo no admite secretos por construcción) |
| A03 Inyección | Baja: líneas de registro falsificables con el nombre de la clave (S06); sin SQL ni plantillas |
| A04 Diseño inseguro | Correcto: lista de permitidas en lugar de lista de prohibidas. Observación: S03 |
| A05 Configuración | S01, S03 |
| A06 Componentes | `Microsoft.Extensions.Configuration.Json` 10.0.12, igual que el marco; sin vulnerabilidad conocida |
| A07 Autenticación | No aplica |
| A08 Integridad de datos y software | S02 (padrón de una fuente no confiable) |
| A09 Registro y monitoreo | S04, S06; no se registra ningún valor (sección 5) |
| A10 SSRF | S02 (solo https, ciego) |

## 4. Respuestas a las cinco preguntas

**1. ¿Se puede saltar el filtro?** No, por las vías revisadas (verificado):
- *Mayúsculas y minúsculas:* `Data` de `JsonConfigurationProvider` no distingue mayúsculas, igual que `Permitida` (`ArchivoInstalacion.cs:36`). `gpos:rncdgii:url` es la misma clave permitida y no abre otra.
- *Prefijos tipo `GPOS:RncDgiiX`:* se exige igualdad exacta o `s + ":"` (`:36`); la prueba con `RncDgiiOtra` lo cubre.
- *Índices de arreglo:* `GPOS:RncDgii:Lista:0` sigue dentro de la sección permitida. Fuera de ella se filtra igual que cualquier otra clave.
- *Separador `__`:* el proveedor JSON no lo traduce (solo lo hace el de variables de entorno). `"GPOS__Jwt"` queda como clave literal, nadie la lee y además se filtra.
- *Clave JSON con `:` incrustado* (`"ConnectionStrings:Sistema"` en el primer nivel): se aplana a la misma ruta y se filtra.
- *Recarga:* `Load(Stream)` se vuelve a ejecutar en cada recarga (prueba `Al_releer_vuelve_a_filtrar`). Queda solo la ventana de S05.
- *Enlace simbólico, junction o punto de reanálisis:* el filtro actúa sobre el contenido y no sobre la ruta, así que no se salta. Lo que cambia es quién controla el archivo (S01, S02). Si la ruta apunta a otro JSON con secretos, solo se registran los nombres de sus claves, nunca los valores.

**2. Daño posible con el filtro.**
- `Intentos` y los tiempos no son configurables (constante y `Program.cs:234`). Por ese lado no hay negación del servicio del padrón.
- Lo que sí hay:
  - el arranque bloqueado con un JSON inválido (S01, real hoy);
  - una `Url` https ajena (S02, latente por S03).
- ¿Es aceptable sin DACL hasta ADR-77? Sí, con condiciones:
  - corregir S01 en este mismo PR;
  - no corregir S03 sin aplicar a la vez la remediación de S02.
- Motivo: la ACL heredada de `%ProgramData%` permite a **cualquier usuario local** crear el archivo mientras no exista (lo verifiqué en este equipo). No puede modificar un archivo que ya creó un administrador, porque `WD` y `AD` solo se heredan a carpetas. El atacante necesita, por tanto, una sesión local en el servidor, y el filtro reduce el daño a disponibilidad e integridad del padrón.

**3. Variable de entorno de la carpeta.** No abre nada nuevo:
- Quien fija variables de entorno del proceso puede fijar directamente `ConnectionStrings__*` o `Jwt__*` con prioridad mayor y sin filtro.
- En un servicio, el entorno vive en `HKLM\...\Services\<servicio>` o en las variables de equipo, que solo puede tocar un administrador. En el DEMO es el mismo usuario.
- Se lee con `Environment.GetEnvironmentVariable` (`:27`) y no desde la configuración, así que `appsettings.json` no puede desviarla.
- Observación menor: no se exige ruta absoluta. Una ruta relativa se resuelve contra el directorio actual, que en un servicio es `System32`. Rechace las rutas no absolutas (`Path.IsPathFullyQualified`) o regístrelas como advertencia.
- El DEMO apunta a `config\`, restringida con `/inheritance:r` (`Comun-Demo.ps1:118-122`): correcto.

**4. Registro.** No llega ningún valor (verificado):
- Las advertencias solo llevan la ruta del archivo, el nombre de la clave y la lista de secciones (`ArchivoInstalacion.cs:56`, `GPOS.Migracion/Program.cs:43`).
- El error de sintaxis de .NET da la ruta y la posición, no el contenido.
- `HttpRequestException` puede mostrar al ADMIN el host de la `Url`, que no es secreto.
- La única debilidad del registro es S06.

**5. D-01.**
- En el alcance de D-01 no queda ningún dominio registrable: los cuatro archivos usan `example.com` y la guarda ya no tiene esas excepciones.
- Fuera de ese alcance queda `src/GPOS.Contracts/Admin/Importaciones.cs:180`, `ventas@empresa.com` (S07).
- Los ejemplos `smtp.gmail.com` y `smtp.office365.com` son de proveedores reales, están documentados como permanentes (A-04) y son aceptables.

## 5. Hallazgos

### T2B-S01 · Media · Arranque bloqueado por un JSON inválido (verificado)
- **Riesgo:**
  - `Optional = true` solo cubre el archivo ausente. Con JSON mal formado (o con claves duplicadas), `Build()` lanza `InvalidDataException`, y no arrancan la API, la Web, la API de reportes ni el comando de migración.
  - En la Web, la API de reportes y la migración el archivo no aporta ninguna clave que se use, pero igual las puede tumbar.
  - Lo puede provocar cualquier usuario local mientras `%ProgramData%\GPOS NG\config\<proceso>.json` no exista.
- **Evidencia:**
  - `src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:41` (sin `OnLoadException`);
  - `src/GPOS.Migracion/Program.cs:34-40` (`Build()` fuera del `try`);
  - prueba mínima en el scratchpad (sección 1).
- **Remediación (aprox. 1 h):**
  - en `FuenteArchivoInstalacion`, fijar `OnLoadException = c => { c.Ignore = true; /* recordar el error */ }`;
  - registrar después una advertencia con la ruta y el tipo de error, sin el contenido;
  - agregar la prueba «JSON inválido: el proceso arranca y avisa».
- **Defensa en profundidad:** que el instalador cree `config\` con DACL protegida (ADR-77, punto 3) para cerrar la creación por terceros.

### T2B-S02 · Media (latente) · `Url` de padrón ajena (camino verificado; efecto inferido)
- **Riesgo:** quien cree el archivo fija `GPOS:RncDgii:Url` hacia cualquier host https. Con eso puede:
  - **reemplazar el padrón** con contribuyentes fabricados. Basta con que el archivo tenga al menos la mitad de los registros actuales (`RncDgiiService.cs:150`). El padrón falso afecta a C-3 (se aceptan RNC con dígito inválido si figuran en el padrón, `CambioRncService.cs:106`) y a los nombres que se sugieren al facturar;
  - hacer **peticiones ciegas** a hosts https internos (SSRF limitado: el ADMIN solo ve el mensaje de error);
  - **llenar `%TEMP%`**: la descarga no tiene límite de tamaño y dura hasta 30 min (`TrabajoRncDgii.cs:149-163`).

  La descarga programada la dispara el sistema sin intervención humana (`TrabajoRncDgii.cs:81-82`). Hoy no se puede explotar en la API, porque `appsettings.json:48-49` define la `Url` y gana por S03.
- **Evidencia:** `TrabajoRncDgii.cs:137-140` (solo exige el esquema https), `ArchivoInstalacion.cs:23`.
- **Remediación (aprox. 0,5 a 1 día, antes de corregir S03 o junto con ese cambio):**
  - aceptar el archivo solo si su dueño es SYSTEM, Administradores o TrustedInstaller y ninguna ACE concede escritura a Usuarios, Usuarios autenticados, Todos o INTERACTIVE; en caso contrario, ignorarlo entero con una advertencia (adelanta solo la parte de ADR-77 que se necesita aquí);
  - registrar el host efectivo de la descarga y su origen (paquete, archivo o entorno) en el resultado del padrón;
  - poner un tope de tamaño a la descarga (por ejemplo, 300 MB; el padrón actual pesa unas decenas de MB, cifra inferida).
- **Alternativa descartada:** una lista fija de hosts en el código, porque contradice VT-01 (ningún valor de tercero en el código).

### T2B-S03 · Media (funcional) · El archivo queda debajo de `appsettings.json` (verificado)
- **Riesgo:**
  - `FindIndex` encuentra la primera fuente de variables de entorno, que en `WebApplication.CreateBuilder` es la del prefijo `ASPNETCORE_` (índice 1). El archivo se inserta antes de `appsettings.json` y de `appsettings.{Entorno}.json`, que lo sobrescriben. En la API, la `Url` del archivo nunca se aplica.
  - La prueba `Va_despues_del_paquete_y_antes_de_las_variables_de_entorno` no lo detecta, porque usa un `ConfigurationBuilder` con una sola fuente de entorno.
  - En `GPOS.Migracion` el orden sí es el correcto.
- **Evidencia:** `ArchivoInstalacion.cs:44`; orden real en la sección 1.
- **Remediación:**
  - usar `FindLastIndex`: la última fuente de entorno es la que no tiene prefijo. Mejor aún, comprobar que su `Prefix` es nulo o vacío; el tipo está en el marco compartido, así que no hace falta otro paquete;
  - agregar una prueba con `WebApplication.CreateBuilder`.

  Aplíquese solo junto con la remediación de S02.

### T2B-S04 · Baja · Sin rastro de los cambios en caliente (verificado)
- **Riesgo:**
  - con `ReloadOnChange`, el archivo se puede crear o cambiar sin reiniciar el proceso;
  - `AdvertirIgnoradas` solo corre al arrancar, así que las claves ignoradas en una recarga no se avisan y el cambio de la `Url` no deja ninguna línea.
- **Evidencia:** `ArchivoInstalacion.cs:41,51-58`; `Api/Program.cs:334`.
- **Remediación (aprox. 1 h):** `ChangeToken.OnChange(raiz.GetReloadToken, ...)`, o un evento en el proveedor, que registre las claves ignoradas y los nombres de las claves permitidas que cambiaron, sin sus valores.

### T2B-S05 · Baja · Ventana de carrera en la recarga (verificado por lectura; efecto inferido)
- **Riesgo:**
  - `base.Load` publica el diccionario completo en `Data` y después se quitan las claves (`ArchivoInstalacion.cs:79-81`);
  - un hilo que lee la configuración en ese intervalo puede ver una clave no permitida;
  - además, `Dictionary` no admite que se modifique mientras otro hilo lo lee.

  La ventana es de microsegundos y solo afecta a las claves que no fija ninguna capa superior.
- **Remediación:** parsear en un diccionario local (por ejemplo, con un `ConfigurationBuilder().AddJsonStream(stream)` temporal), filtrarlo y asignar `Data` una sola vez.

### T2B-S06 · Baja · Nombre de la clave sin sanear en el registro (verificado)
- **Riesgo:** quien escribe el archivo elige los nombres de las claves. Con saltos de línea o caracteres de control, puede falsificar líneas en la consola de la migración y en los destinos de texto del registro.
- **Evidencia:** `ArchivoInstalacion.cs:56`, `GPOS.Migracion/Program.cs:43`.
- **Remediación:** sustituir los caracteres de control y truncar el nombre (por ejemplo, a 200 caracteres) antes de registrarlo.

### T2B-S07 · Baja · Ejemplo con un dominio de un tercero fuera de D-01 (verificado)
- **Riesgo:** `empresa.com` es un dominio registrado por un tercero. Un usuario que copie el ejemplo puede mandarle correos de prueba.
- **Evidencia:** `src/GPOS.Contracts/Admin/Importaciones.cs:180` (`ventas@empresa.com`).
- **Remediación:** cambiarlo a `ventas@example.com` y ampliar la guarda de `ValoresDeTercerosTests` a direcciones de correo de ejemplo.

## 6. Controles bien implementados

- **Lista de permitidas por sección**, con comparación exacta o por prefijo con `:` y sin distinguir mayúsculas. El archivo no admite secretos por construcción.
- El filtro se aplica también en cada recarga, y con una recarga inválida el proceso sigue vivo con la fuente vacía (verificado).
- Las advertencias solo registran nombres de claves, nunca valores. La prueba verifica que los valores no aparecen.
- La variable de la carpeta no amplía lo que el entorno ya permite. En el DEMO, la carpeta `config\` tiene la herencia cortada.
- El ejemplo del DEMO queda inactivo (`.ejemplo`), solo trae claves permitidas y su prueba prohíbe palabras de secretos.
- D-01 está completo en su alcance y se retiraron las cuatro excepciones de la guarda.

## 7. Remediaciones priorizadas

1. **S01**, en este PR (aprox. 1 h): `OnLoadException` con `Ignore` y advertencia, y su prueba.
2. **S02 y S03 juntas** (aprox. 0,5 a 1 día): comprobar el dueño y la DACL del archivo, registrar el host efectivo, poner un tope de tamaño a la descarga y, después, `FindLastIndex` con la prueba sobre `WebApplication.CreateBuilder`.
3. **S04, S05 y S06** (aprox. 2 h en conjunto).
4. **S07** (minutos).

## 8. Recomendación

**Aprobado con observaciones.** No hay Críticos ni Altos. S01 debería corregirse antes de unir. S02 debe estar resuelta antes de que S03 haga efectiva la capa del archivo. Es una recomendación técnica; la decisión de unir es del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\revision-seguridad-t2b-archivo-instalacion-2026-10-18.md`
- Supuestos: el tamaño del padrón (decenas de MB) es inferido; la ACL de `%ProgramData%` es la de fábrica de Windows (verificada en este equipo).
- Decisiones candidatas a ADR: ninguna (la comprobación de dueño y DACL de S02 es un adelanto acotado de ADR-77, punto 3, sin decisión nueva).
- Entregas a otros agentes: desarrolladores → S01, S03 (con su prueba sobre `WebApplication.CreateBuilder`), S04 a S07; qa-automatizado → la prueba de orden de fuentes y la del JSON inválido; devops → crear `config\` con DACL protegida en el instalador (ADR-77).
- Próximo paso recomendado: corregir S01 en el PR y planificar S02 junto con S03.
