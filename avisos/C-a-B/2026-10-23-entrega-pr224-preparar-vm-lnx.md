```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (opcional 10(a) del backlog de `B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7.md`) y preguntas
Prioridad: Normal
Repositorio y rama: GPOS-NG [PR #224](https://github.com/lfmendezb/GPOS-NG/pull/224) (`c/preparar-vm-lnx`, base `feature/modelo-ng`)
Estado: Abierto
```

# Entrega: `preparar-vm.sh` de VM-LNX y casos PVL-01 a PVL-20

PR #224: el equivalente Linux de `Preparar-Vm.ps1` para VM-LNX (Ubuntu 24.04), con sus pruebas y casos. Se basa en el diseño v3 del laboratorio (secciones 3, 6.3 y 7.1), las guardas LS-11 y ADR-129 bloque C (C1, C2, C6, C8, C15 y C17).

**Qué hace.** Se niega antes de tocar nada si no es Linux o es WSL, si no es root, si no es Ubuntu 24.04 con systemd, si no es una VM de VirtualBox (`systemd-detect-virt` = `oracle` y DMI «VirtualBox»), si el equipo no se llama `vm-lnx` (rechaza también lfmb y oshin-legion), si está en un dominio o ya tiene una instalación de GPOS NG, o si alguna carpeta usada es un enlace simbólico o no es de root. Pasos: retira el `id` del marcador anterior; busca los restos de la desatendida por nombre y por contenido con `grep -l` (nunca muestra la línea), apaga cloud-init, bloquea root, quita el inicio automático y se detiene si sudoers trae NOPASSWD; usuario sin privilegios `gpos-lab` (de sistema, `nologin`, sin clave ni grupos); NTP, timesyncd y chrony apagados, zona America/Santo_Domingo y reloj en UTC; journald persistente; netplan `90-gpos-lab.yaml` (`.30/24` y `fd00:50::30/64`, sin DHCP, anuncios de router, puerta de enlace ni DNS); el mismo bloque de 11 nombres en `hosts`; ufw activo, entrada denegada y sin reglas; comprobación final (.NET 10, OpenSSL 3, `libicu74`, ca-certificates, sin certificados del laboratorio en el almacén de la distribución); marcador `/etc/gpos-ng/laboratorio-tls/id` al final; evidencia JSON sin secretos. `--comprobar` es solo lectura; admite `--interfaz`, `--id`, `--nuevo-id` y `--usuario`; es idempotente.

**Verificación:** `bash -n` sin errores; `probar-preparar-vm.sh` 42 pasan, 0 fallan; dos mutaciones detectadas (PV-10 y PV-23). **No se ejecutó en ninguna VM ni como root** (VM-LNX todavía no instala). shellcheck no está instalado (regla del 2026-10-08). Añadí una línea a `.gitattributes` (`tests/laboratorio-adr090/**/*.sh text eol=lf`) porque con `autocrlf=true` el guion saldría con CRLF y bash no lo correría; solo afecta a esa carpeta.

**Dudas para ti (todas [I])**
1. **Por qué se cuelga la instalación:** `Crear-VmLaboratorio` le da a VM-LNX 1.536 MB; el instalador live-server de 24.04 podría quedarse corto. Prueba con 3 GB para instalar y bájala después; también VMSVGA con más memoria de vídeo, además de virtio y otro controlador de disco. Es inferencia mía, no verificada.
2. Que `hostname -s` dé `vm-lnx` y que `enp0s3` sea la red interna y `enp0s8` el NAT.
3. Restos reales de la desatendida de VirtualBox 7.2 en Ubuntu 24.04 y si su plantilla añade NOPASSWD (si lo añade, el paso 1 se detiene a propósito y hay que quitarlo con visudo).
4. Si el `50-cloud-init.yaml` del instalador trae direcciones, rutas o DNS para `enp0s3`: se sumarían a las nuestras y el paso 5 falla nombrando el archivo.
5. Formatos de `ufw status verbose` y `ufw show added` en ufw 0.36.2.
6. Qué paquete de .NET 10: el guion exige solo el runtime, pero N-L usa `dotnet test`, que necesita el SDK (o pruebas ya publicadas).
7. El marcador está dentro de `/etc/gpos-ng` (el diseño lo pide); una instalación real podría confundirse, y por eso el guion se niega si ya hay una instalación de GPOS NG.
8. Nombre del archivo en minúsculas (`preparar-vm.sh`, como en el diseño v3 y en los mensajes de `Preparar-Vm.ps1`); es un `git mv` si lo prefieres.

**Pendiente mío:** `limpiar-laboratorio.sh` (retira el bloque de hosts, los certificados y el usuario `gpos-lab`) y las pruebas `[FactLaboratorioTls]` para Linux.

Respuesta requerida: las dudas 1 a 8 cuando consigas VM-LNX; nada se une sin orden del propietario.
