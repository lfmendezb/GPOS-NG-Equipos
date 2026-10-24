```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 8(a) de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9.md`) y preguntas
Prioridad: Alta (6 dudas bloquean casos; respuestas antes del 3-nov, cuando empiezas F2)
Repositorio y rama: GPOS-NG `b/blueprint-tls-anillo` y hoja de F2/F3 (leídos con `git show`); sin cambios
Estado: Abierto
```

# Plan de pruebas de F2 de `tls` (núcleo)

`traspasos/C/2026-10-24-plan-pruebas-tls-f2.md`. Nada compilado ni ejecutado.

**Qué es F2 (sección 1),** según la sección 8 del blueprint y la hoja que aprueba F2 y F3 completas: despacho, guardas, mutex y códigos 0 a 4; `ConstructorPki` y Name Constraints con `AsnWriter`; la CA (TPM o software, con 4781) en `LocalMachine\GPOS NG TLS`, no en `My`; las hojas Web y API con el descriptor fijado al crear la llave; la publicación según PT-02 (`HuellaApi`/`HuellaWeb`); `Root` y `Servidor\tls\ca.cer`; `--crear-ca`, `--emitir` (con `--servicio` y `--forzar`) y `--comprobar`; los eventos 4780 a 4782. A F3: renovación, tarea, avisos 20/10/3, `--importar --huella`, `--exportar-publica`, `--retirar` y `--quitar-tarea`. A F4: PFX, Avanzada y la CA sucesora. El mutex SA-08 no está firmado: F2 lo prueba como está en 4.1 (sin DACL), con un pin de transición.

**Cobertura.** 91 de los 122 casos de mi plan general entran en F2; 23 pasan a F3, 5 a F4 y 3 salen (N21, R14, P08). Se añaden 39 casos nuevos (T2-xx) para lo que el blueprint decidió después de mi plan (guardas en orden, salida 3, «lo propio», `--comprobar`, eventos, almacén propio): **130 casos** en total, 29 mutaciones nuevas (MU-65 a MU-93), 13 requisitos de testabilidad (R-2.1 a R-2.13), 4 casos W de verificación de supuestos (W-TLS-01 a 04) y 5 casos de laboratorio (LABT-22 a 26; 3 sesiones, ~9,5 h). Esfuerzo: ~2,8 dp de escritura más 0,5 dp de guiones y mutaciones [I, ±40 %]. Los casos de nombres quedan como paridad con `red` (N20), porque `tls` reutiliza `InterpretacionRed`.

**Orden de escritura (sección 7), rojo primero:** vectores y oráculo independiente sin producto; núcleo puro; guardas y registro; CA; hojas y publicación; `tls\`, `--comprobar` y eventos; casos W y laboratorio. **Para que las pruebas compilen en rojo el primer día, tu primer commit tiene que ser el esqueleto:** interfaces, firmas y `NotImplementedException`.

**Hallazgos de lectura (sección 8).** Ninguno Crítico ni Alto; cuatro Medios:
- **QF2-01:** el `IAlmacenMaquina` de F1 (`b/f1-anillo`) es solo RSA y software, no lista y no tiene almacenes nombrados; F2 necesita ECDSA con TPM o software, `GPOS NG TLS`, `Root`, reconocer «lo propio» y evaluar el acceso de un SID. Sin ampliar la interfaz y su falso, los casos F pasan a W.
- **QF2-02:** `--comprobar` está en F3 en la sección 1 del blueprint y en F2 en la sección 8.
- **QF2-03:** la sección 4.5 dice que `--emitir` crea la tarea que ejecuta `tls --renovar`, pero `--renovar` es de F3: una F2 publicada así crearía una tarea diaria de SYSTEM que falla cada día.
- **QF2-06:** una CA con certificado pero sin llave (un sitio restaurado, SA-07) no tiene regla definida; podría crearse una segunda CA.
- Seis Bajos (QF2-04, 05, 07, 08, 09 y 10): entre ellos, el blueprint cita H-SUFIJO y H-PADRE como el residual de los subdominios, pero ese residual es H-SUB; y `InterpretacionRed` no normaliza ni deduplica y acepta `::ffff:a.b.c.d`.

**Dudas (18 en la sección 9; 6 bloquean casos)**
- D-F2-01: `--comprobar` en F2 o F3 y su contrato (códigos de AVISO y FALLA, esquema JSON, umbral de días).
- D-F2-02: ¿`--emitir` crea la tarea en F2?
- D-F2-03: código de salida con la CA en software (0 o 2) y si el 4781 se repite.
- D-F2-04: CA sin llave, y `Root` sin la CA o con un certificado ajeno del mismo sujeto.
- D-F2-07: qué hacen las acciones de F3 en una F2.
- D-F2-12: quién amplía `IAlmacenMaquina` (F1 o F2) y quién escribe el falso.
- De las otras 12 pesan: D-F2-05 (qué se limpia si la comprobación falla), D-F2-06 (si SA-08 entra en F2), D-F2-14 (PR-V no tiene escritura atómica de archivos ni cerrojo con nombre), D-F2-15 (plan B si el almacén propio no funciona) y D-F2-18 (si CI corre en Windows para los casos con `X509Chain`).

**No verifiqué:** los supuestos de CNG y de los almacenes ([I], van a W-TLS-01 a 04); el código completo de `InterpretacionRed` (solo sus pruebas); `LecturaCarpeta` de PR-V; si VirtualBox emula TPM 2.0. Supuestos del plan: `--comprobar` va en F2 (QF2-02); la tarea no se crea en F2; la CA vive en `GPOS NG TLS`; `red` y `tls` comparten la pieza que escribe la clave.

**Reparto:** B → D-F2-01 a 18, QF2-01 a 06 y R-2.1 a R-2.13 antes del 3-nov, con el esqueleto como primer commit. A → PR-V unido el 3-nov (o aceptar el apilado) y confirmar escritura atómica y cerrojo en `ISistemaServidor`. Auditor de A → revisar T2-G01, C07, S09, X04 y K05 antes de la VM. C → escribir el oráculo y el núcleo puro antes del 3-nov, cuando tenga el esqueleto.

Respuesta requerida: las 6 dudas bloqueantes y el esqueleto de F2 antes del 3-nov.
