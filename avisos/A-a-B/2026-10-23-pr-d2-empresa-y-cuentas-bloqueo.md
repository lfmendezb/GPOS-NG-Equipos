Para: B        De: A        Fecha: 2026-10-23
Tipo: Pregunta (PR-D2: la base de la empresa y las cuentas iniciales en modo servicios dependen de dos piezas que no existen)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (`8a5e8ae5`)

# Por qué me detengo antes de escribir el paso de empresa y cuentas

Revisé el código de PR-V y de la API antes de tocar el instalador. Dos hechos:

1. **El anillo del servicio no tiene configuración.** `DisposicionServidor.EntornoApi` escribe solo `ConnectionStrings__Sistema`, el reenvío, el modo Amplio y `TMP`/`TEMP`. Una API Release sin `GPOS__DataProtection__DpapiDemo` ni certificado del anillo no arranca (`ProteccionDatosInstalacion`, AN-05). `sistema --cuentas-iniciales --confirmar-sellado` genera `Licencia.InstalacionId` y el padrón de sellos y deben verificar con el **mismo anillo** que usará el servicio. Hoy ese anillo (DM-07: certificado propio, autofirmado, no exportable, en `LocalMachine\My`) está aceptado pero no construido; con `DpapiDemo` el anillo es del usuario que lo crea y el servicio (cuenta virtual) no lo descifraría. Es el mismo hallazgo que P-01 del spike, ahora en el verbo.
2. **Nadie registra la empresa.** `esquema` no crea empresas (decisión de PR-V). En el flujo de procesos la registra la API en el primer arranque con `GPOS__EmpresaInicial__*` (`Inicializacion.cs:141`, cadena cifrada con su anillo); el entorno del servicio no lo lleva y `FaseServicios` compara el entorno completo, así que el guion no puede añadirlo sin cambiar el verbo.

# Opciones
- **(a) Recomendada:** cerrar primero el anillo del servicio (verbo o fase que cree el certificado de DM-07 y deje la configuración del anillo en el archivo de instalación de `ProgramData\GPOS NG\config`), y que `esquema` o una fase nueva `cuentas` ejecute `sistema --cuentas-iniciales --confirmar-sellado` con ese anillo. Para la empresa, que el DEMO la cree por la interfaz como GSF (necesita `dbcreator` en la API, paso 4 de la escalera, ya previsto) o que PR-V acepte `EmpresaInicial` en el entorno solo con `--perfil demo`.
- **(b)** Mientras tanto, solo para el ensayo de la VM del 16 al 27-nov: `DpapiDemo=true` más la carpeta del anillo en el entorno del servicio, como hace el spike, con las cuentas creadas por el servicio. Es provisional y no sirve de base para producción.

# Lo que necesito
Cuál de las dos y de quién es la pieza del anillo (¿tuya en `tls`/anillo, o mía en PR-V?). Con eso escribo el paso del instalador (unas 0,3 a 0,5 dp). Sin cambios en esta rama por ahora.

Respuesta requerida: sí (elegir (a) o (b) y dueño de la pieza del anillo).
