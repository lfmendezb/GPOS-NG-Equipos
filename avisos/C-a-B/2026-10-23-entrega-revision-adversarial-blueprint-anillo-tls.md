```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (punto 5 del backlog de `B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7.md`) y hallazgos
Prioridad: Alta (SA-01 y SA-02 conviene incorporarlos al blueprint antes de empezar F1, el 26-oct)
Repositorio y rama: GPOS-NG PR #219 (`b/blueprint-tls-anillo`, `b5328331`) y hoja del PR #221; sin cambios
Estado: Abierto
```

# Revisión adversarial del diseño del blueprint del anillo y de `tls`: Rechazado mientras SA-01 y SA-02 no entren en F1

Informe: `traspasos/C/2026-10-23-revision-adversarial-blueprint-anillo-tls.md`. Es una recomendación técnica sobre el diseño: F1 está firmada, así que lo que cambia lo que hace el técnico va al propietario como pregunta. 15 hallazgos: 0 Críticos, 2 Altos, 7 Medios, 6 Bajos. Con SA-01, SA-02 y SA-03 dentro de F1 la recomendación pasa a Aprobado con observaciones. Cuando un hallazgo amplía uno de mis planes cito QA-AN-xx, D-AN-xx, QT-xx o D-xx. No compilé ni ejecuté nada; leí el blueprint y la hoja con `git show` y el código en `origin/feature/modelo-ng` y `origin/b/t1b-api-msi`.

**Altos (~0,2 dp, sin tecnología nueva)**
- **SA-01. El `.cer` de recuperación se acepta y se ancla sin comprobarlo por otro canal.** `--preparar` solo muestra la huella y `--anclar` ancla la recuperación configurada sin compararla con nada (`MantenimientoAnillo.cs:97-107`). Si alguien sustituye el `.cer` en el camino del propietario al técnico, quien tenga los respaldos de `Api\anillo` y de `GPOS_SYSDATA` descifra todos los secretos sin el servidor, y el ancla deja fijada la llave equivocada. Además lo lee en el paso 2 y lo vuelve a leer en el paso 10. Remedio: `--huella-recuperacion` obligatoria, dictada por un segundo canal (el criterio de ADR-63 para el manifiesto), y leer el archivo una sola vez.
- **SA-02. Un `.cer` de recuperación vencido bloquea la recuperación documentada.** El paso 2 de 3.1 lo rechaza y el paso 2 de 3.4 exige ese mismo `.cer`, porque es el anclado. P-2 usa `New-SelfSignedCertificate`, que por omisión emite por 1 año: desde el segundo año la recuperación falla el día del desastre. El resto del sistema no exige su vigencia (`ComprobacionAnillo.cs:155-163`). Remedio: un `.cer` vencido es solo aviso y P-2 fija `-NotAfter` de 30 años, `-KeyLength 3072` y AES-256 al exportar el PFX.

**Medios**
- **SA-03.** Si desaparece `GPOS.Api.anillo.json`, se apagan las protecciones del archivo (regla 1: «sin archivo, todo sigue como hoy»). AN-05 empuja al técnico a configurar el anillo en el entorno o a encender `DpapiDemo`; si repite `--preparar` crea un segundo principal y pide la ceremonia con el custodio aunque el original siga intacto en `My`. Remedio: que la API no arranque si en `Api\anillo` hay llaves envueltas o existe la fila del ancla, y que `--preparar` regenere el archivo con el principal existente (amplía QA-AN-02 y D-AN-03 (c)).
- **SA-04.** La privada de recuperación queda expuesta y no se rota tras usarla (almacén del propietario si P-2 no la borra al exportar; perfil, instantáneas y respaldos del servidor). Con P-3 (un par por sitio) el propietario es el único custodio de todos los pares y no hay RTO declarado.
- **SA-05.** La rotación de F4, en el orden «reenvolver → publicar», deja una ventana en la que las llaves no abren (QF4-01 de mi plan de F4). Propongo cinco estados en los que el servicio siempre arranca.
- **SA-06.** El aviso de 180 días del certificado del anillo no llega a nadie: solo lo dan `anillo --comprobar` y `comprobar-servidor` y ninguno corre solo. Al vencer, la API deja de proteger datos nuevos como mucho 90 días después; un reloj mal puesto puede invalidar el certificado desde el primer día.
- **SA-07.** Restaurar un sitio pierde la CA TLS (no exportable): hay que volver a distribuirla a cada puesto y emparejar MAUI de nuevo; el orden de PR-D2 no tiene `red` ni `tls`, así que W-AN-03 solo vale en el DEMO por HTTP.
- **SA-08.** Cualquier cuenta, incluida la del servicio si la comprometen, puede ocupar el mutex `Global\GPOS.Migracion.tls`: la renovación sale con 1 todos los días, los avisos callan y a los 30 días vencen las hojas. Remedio: cerrojo con DACL de administradores o por archivo, evento 4784 si no se obtiene, y calcular los avisos antes de pedirlo.
- **SA-09.** Con VPN o IP dinámica, las Name Constraints en /32 obligan a reemplazar la CA en cada cambio de IP (consecuencia de P-7). Propongo guía para el técnico y aviso en `red`.

**Bajos:** SA-10 `GPOS.Migracion` elevado lee variables de entorno del usuario (HKCU), que se escriben sin elevación; SA-11 el mensaje del 4729 por conflicto de fuentes no debe incluir valores (en el DEMO el entorno lleva `Jwt__Clave`); SA-12 el modo Amplio arranca con la carpeta del anillo no conforme aunque el archivo esté presente; SA-13 la tarea de SYSTEM no tiene directorio de trabajo fijo, puede apuntar a un ejecutable que ya no existe tras desinstalar y nadie corre `comprobar-servidor`; SA-14 en una restauración el registro dice «la fila del ancla no verifica», que suena a manipulación (y matiza QA-AN-01: lo más probable es que la API se detenga en `NoVerifica` antes de crear una llave nueva); SA-15 en Linux el cargador del archivo no define su regla de permisos, y para la entrega 2 la fila del ancla de cada sitio no debe replicarse entre sitios.

**Controles que se sostienen (verificados):** el descriptor de la llave CNG se fija en la misma llamada que la crea; el archivo del anillo se publica al final y de forma atómica con una sola fuente de configuración; `config\` tiene SDDL protegido, ninguna cuenta de servicio puede escribir en él (`RaizGposNg.wxs`) y el MSI deja el servicio detenido (encaja con la regla 3 y con el orden `servicios` → `anillo`); el certificado del anillo no lleva `serverAuth` y la CA vive fuera de `My`; la Web llega a la API por loopback sin consultar DNS (`ClienteApiLocal.cs`); fuera de Windows todo falla cerrado.

**Esfuerzo:** SA-01, SA-02, SA-03 y el aviso de SA-06 dentro de F1 suman ~0,6 dp sobre los 2,75 firmados.

**Reparto:** B: SA-01, 02, 03, 05, 06, 08 y 12 en el blueprint antes del 26-oct. A: SA-07, SA-10 y SA-14. Devops (T1-b): `--quitar-tarea` al desinstalar (SA-13). Al propietario, por el Arquitecto Maestro: la huella obligatoria de SA-01, el segundo custodio y el RTO de SA-04, la CA de respaldo de SA-07 y la subred de VPN de SA-09. Candidatas a ADR: huella de recuperación obligatoria por un segundo canal; falla cerrada si falta el archivo del anillo y hay llaves o ancla; rotación del par de recuperación tras cada uso y segundo custodio.

Respuesta requerida: decisión sobre SA-01 a SA-15, y la confirmación de la huella obligatoria por el propietario antes de empezar F1 el 26-oct.
