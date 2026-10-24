```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (pendiente propio tras el #224) y preguntas
Prioridad: Normal
Repositorio y rama: GPOS-NG [PR #229](https://github.com/lfmendezb/GPOS-NG/pull/229) (`c/limpiar-laboratorio-lnx` @ `88dcaeed`), **apilado sobre el #224**
Estado: Abierto
```

# Entrega: `limpiar-laboratorio.sh` de VM-LNX

PR #229 (4 archivos, ~683 líneas agregadas), apilado sobre el [#224](https://github.com/lfmendezb/GPOS-NG/pull/224): se une después de él, o se rebasa si el #224 se une primero. Sigue el diseño v3, sección 7.2 (LS-11 y LS-22). Carga `preparar-vm.sh` con `source` para usar el mismo bloque de hosts, el mismo usuario `gpos-lab` y el mismo marcador, así que **los dos guiones se copian juntos a la VM**; sin `preparar-vm.sh`, se niega.

**Modo completo (por omisión).** Paso 0: mueve el `id` del marcador a `id-retirado` (desde ahí ningún guion del laboratorio corre aunque la limpieza quede a medias; `preparar-vm.sh` recupera el mismo id). Paso 1, certificados: borra de `/usr/local/share/ca-certificates` los archivos cuyos certificados son todos del laboratorio (`O=GPOS-LAB-TLS` exacto o huella SHA-256 en la lista de `--huellas`); no toca archivos que mezclen certificados del laboratorio con otros, los ajenos, los ilegibles, los de más de 1 MiB ni los enlaces rotos; corre `update-ca-certificates` sin `--fresh` y comprueba el almacén consolidado. Paso 2: quita el bloque de `/etc/hosts` escribiendo a un temporal y renombrando; si no hay bloque, no escribe. Paso 3: borra `gpos-lab` solo si es exactamente el que crea `preparar-vm.sh` y no tiene procesos (`userdel` sin `-r`; su grupo solo si quedó vacío; su crontab si existe; los archivos que dejó solo se cuentan). Pasos 4 y 5: comprobación final y evidencia JSON sin secretos. `--solo-certificados` hace solo el paso 1 (entre casos). `--comprobar` es de solo lectura: sale con 0 si está limpio, 1 si queda algo, 2 si hay un error de uso. Guardas antes de tocar nada (también con `--comprobar`): las de `preparar-vm.sh` más `GPOS_LAB_TLS_VM=1` y `GPOS_LAB_TLS_ID` igual a `id` o a `id-retirado` (para poder repetir); sin marcador, se niega. No toca red, ufw, hora, journald, cloud-init, `/etc/hosts.antes-gpos-lab` ni el resto de `/etc/gpos-ng`. De los certificados solo lee sujeto y huella.

**Verificación (esta PC, sin root):** `bash -n` sin errores; `probar-limpiar-laboratorio.sh` 57 pasan, 0 fallan, 0 omitidos (once con certificados reales de openssl en carpeta temporal); `probar-preparar-vm.sh` 42 pasan; cinco mutaciones detectadas (marcador escapado, archivo mezclado, uid de persona, ilegible con certificados del laboratorio y quitar las guardas). **Incidente declarado:** la mutación que quita las guardas hizo correr la limpieza de verdad en esta PC sin root; comprobé que no cambió nada (`/etc/hosts` de Git Bash conserva su fecha de 2024 y no existen `/var/lib/gpos-lab` ni `/usr/local/share/ca-certificates`). **No se ejecutó en ninguna VM** (VM-LNX todavía no instala). shellcheck no está instalado (regla del 2026-10-08).

**Para ti**
1. LLL-01 a LLL-11 en VM-LNX (sección 6 de `preparar-vm-lnx.md`) cuando la tengas.
2. **`[FactLaboratorioTls]` de Linux no se escribió:** ni el atributo ni `tests/GPOS.Tests/Laboratorio/Tls/` existen en `origin/feature/modelo-ng` (solo `LaboratorioInstaladorTests.cs` y `SpikeAmplioDemoTests.cs`, que revisan el texto de los guiones `.ps1` y según el LEEME son trabajo tuyo). Anoté que su guarda debe comparar con `id` y no con `id-retirado`. Tampoco existe `Limpiar-Laboratorio.ps1` de Windows (solo `Limpiar-Anfitrion.ps1`, que limpia el anfitrión).
3. **Lista de huellas:** el diseño no dice dónde la deja el generador ni en qué formato. Supuse SHA-256 del DER en 64 hexadecimales, recibida por `--huellas` [I]. Decide la ubicación.
4. **Decisión mía, revócala si no te gusta:** en el modo completo retiro el marcador, así la VM queda «no preparada» y ningún guion del laboratorio corre; si prefieres conservarlo, basta quitar el paso 0. Si el paso 3 falla (`gpos-lab` con procesos), el marcador ya está retirado y el bloque de hosts quitado: es a propósito, falla cerrada y se puede repetir.
5. Inferidos [I]: que `update-ca-certificates` sin `--fresh` quita los enlaces de un `.crt` borrado y el formato RFC 2253 del sujeto en OpenSSL 3.0 de Ubuntu 24.04.

Respuesta requerida: ninguna salvo la ubicación de la lista de huellas (punto 3).
