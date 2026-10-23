```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 4 de `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`) y preguntas
Prioridad: Media
Repositorio y rama: GPOS-NG `b/blueprint-tls-anillo` @ `b5328331` (leída con `git show`; sin cambios)
Estado: Abierto
```

# Entrega: plan de pruebas del anillo DM-07

Adelantada (acuse: 10-nov). `traspasos/C/2026-10-23-plan-pruebas-anillo-dm07.md`: oráculo de 17 reglas (K-01 a K-17), ~118 casos en niveles U/F/W/V con su mutación (77: MU-AN-01 a 77), 20 casos de laboratorio LABA-xx para `VM-SRV` (4 sesiones, ~10 h) con un script de apoyo `EstadoAnillo`, trazabilidad contra la sección 7.1 de tu blueprint y W-AN-01 a 05, y 10 requisitos de testabilidad (R-A1 a R-A10). Esfuerzo ~3,0 dp (±40 %). Nada se ejecutó; lo de `CopyWithPrivateKey`, `GENERIC_READ`, la ruta del contenedor CNG y correr como `NT SERVICE\GPOS.Api` queda [I].

**Hallazgos de lectura (8, ninguno Crítico ni Alto):** QA-AN-01 (Media): con llaves restauradas de otro principal, `ComprobacionAnillo` crea una llave nueva y la API arranca sin poder descifrar los secretos antiguos hasta `--recuperar`; el blueprint no dice si debe negarse a arrancar. QA-AN-03 (Media): `OrdenProgramaApiTests` caerá con la línea nueva `AgregarArchivoAnillo`; actualizarla en el mismo PR. QA-AN-06 (Baja): la suite corre en Debug y AN-05 (rechazo de `DpapiMaquina`) solo se prueba dentro de `if (CompilacionDepuracion)`; sin la costura R-A1 o una pasada en Release esos casos no prueban nada. QA-AN-02, 04, 05, 07, 08 (Baja): idempotencia incompleta, sin exclusión mutua en `--preparar`, contenedor con resolución de un segundo, `AnilloPrueba.Anclar` con `DateTime.UtcNow`, y el token de la cuenta virtual con `Everyone` y `Authenticated Users`.

**Dudas (15, sección 9):** bloquean casos D-AN-01 (la hoja `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md`, P-1 a P-9, no está en `b/blueprint-tls-anillo` ni en `master`; tomé como firmado lo que el blueprint declara firmado), D-AN-03 (qué hace `--preparar` con archivo sin certificado, certificado vencido o sin privada, archivo inválido, o certificado y llave sin archivo; recomiendo salida 4 sin reemplazar), D-AN-04 (¿exclusión mutua en `--preparar`?) y D-AN-08 (¿la API debe negarse a arrancar con llaves ajenas antes de `--recuperar`?, y ¿quién borra la privada importada en `CurrentUser\My`?). Para el Arquitecto Maestro: D-AN-08 y D-AN-14 (precisión de H-17 v2 y ADR-77).

Respuesta requerida: D-AN-01, 03, 04 y 08; decidir QA-AN-01 y QA-AN-02 antes de construir F1.
