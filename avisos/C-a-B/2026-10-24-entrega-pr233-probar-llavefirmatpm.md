```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 2 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9.md`) y preguntas
Prioridad: Alta (ensayo que decide si se conecta la llave en D2)
Repositorio y rama: GPOS-NG [#233](https://github.com/lfmendezb/GPOS-NG/pull/233) (`c/guion-llave-firma-tpm` @ `67058ecb`, base `feature/modelo-ng`)
Estado: Abierto
```

# `Probar-LlaveFirmaTpm.ps1`: ensayo de H120P-01 y S120-02 con vTPM

PR #233: `tests/laboratorio-adr090/invitado/Probar-LlaveFirmaTpm.ps1` (1.159 líneas) y `LEEME-llave-firma-tpm.md` (235). Solo `tests/`. **Sintaxis:** 0 errores en PowerShell 5.1 y 7 (del agente y mía); el P/Invoke incrustado compila con el `csc` de .NET Framework sin errores ni advertencias. **No se ejecutó ningún caso: ni en una VM ni en esta PC, y no se creó ninguna llave en el TPM de la PC.**

**Cómo corre como `NT SERVICE\GPOS.Api`.** `Preparar` crea un servicio temporal llamado `GPOS.Api`; su cuenta virtual tiene el mismo SID que la de la API. El binario es `powershell.exe` con una copia del guion en modo `Sonda`. La orden llega por `C:\GPOS-LAB\tpm\bin\orden.json` (solo la escribe el administrador); la salida va a `tpm\salida`, la única carpeta donde escribe la cuenta virtual. Un segundo servicio, `GPOS.LabSondaTpm`, corre la misma sonda como LocalSystem: es el control positivo. Si el MSI de la API ya está instalado, el guion se niega, salvo con `-PrestarServicioMsi` (solo cambia el `ImagePath` del servicio durante cada corrida, lo anota en `estado.json`, lo devuelve y comprueba que quedó igual).

| Caso | Pregunta | Qué mide |
|---|---|---|
| T1 | (a) y (d) | Sin llave de máquina: `CngKey.Exists` y `NCryptEnumKeys` sobre el almacén de la máquina del PCP, en el orden del producto, con el código crudo de `NCryptOpenKey`; registra token y perfil. |
| T2 | (c) | El verbo real `aprovisionar --llave-firma`: si crea la llave o la borra con «quedó con otra seguridad». |
| T3 | (c) | Réplica de `Crear` que conserva la llave para leer el descriptor que dejó el PCP de la máquina: protección, ACE heredadas y SID `S-1-15-3-*`; crea `GPOS-LAB-TPM.SinUso`. |
| T4 | (b) | Las mismas consultas con la llave ya creada, más abrirla por nombre y firmar: es la opción (a). |
| T5 y T5-tras-reinicio | (d) | La llave en el almacén del usuario de la cuenta virtual: crear, firmar, reabrir en otra ejecución y tras reiniciar. Es la opción (c). |

Además `Sonda-Consola` repite, sin elevar, la medida de mi PC; `Decision` aplica el criterio del LEEME ((a) si abre por nombre, (c) si solo sirve el almacén del usuario, escalar si no sirve ninguna); `Limpiar` borra solo lo que anotó `estado.json`. Cada caso tiene control positivo y negativo; sin control medido o con un control que no distingue da `No se pudo`. Negativos: T1 (la cuenta virtual no puede crear una llave de máquina en el Software KSP: NTE_PERM o E_ACCESSDENIED), T4 (no firma con la llave que no le da uso), T3 (el verificador objeta un descriptor con `S-1-15-3-9`). Guardas de LS-11 como `Probar-Instalador.ps1`; evidencia con el mismo `Redactar` de `Probar-GposApiMsi.ps1`; ninguna llave exportable.

**Lo que necesitas hacer:** habilitar el vTPM (`VBoxManage modifyvm … --tpm-type=2.0` con la VM apagada, firmware EFI, `Get-Tpm`), tomar `LAB-160-antes` (la numeración 150 a 152 y 159 ya estaba ocupada; también 161-preparado, 162-con-llave y 163-despues) y correr de `Guardas` a `Decision`. Duración: ~100 min ±50 % (mi informe decía una hora; la diferencia está en T5 y el reinicio). T2 necesita `GPOS.Migracion` publicado en Release y el runtime de .NET 10 en la VM; si falta, queda `Bloqueado` y T3 y los demás siguen valiendo.

**Dudas e inferidos**
1. La sonda **no** ejecuta `ProveedorLlavesFirma.Abrir`: repite las mismas llamadas a CNG con el mismo orden y banderas. Si T1 o T4 dan `No cumple`, conviene confirmarlo con la API de T1-b (código tuyo) antes de cambiar el diseño.
2. Sin verificar [I]: que el SCM deje terminar a `powershell.exe` antes de cortarlo por el error 1053 (~30 s); que `sc config obj= "NT SERVICE\GPOS.Api"` funcione sin contraseña; que el servicio del MSI tenga SID sin restricción y solo `SeChangeNotifyPrivilege` (lo copié de lo que mide `Probar-GposApiMsi.ps1`); que el punto de control incluya el estado del vTPM; que `--tpm-type` admita `none`, `1.2`, `2.0`, `host` y `swtpm`.
3. VM-SRV es Windows Server 2025 y mi PC Windows 11 Home: si T1 no reproduce el NTE_PERM, el LEEME propone repetirlo en VM-PUESTO, porque el PCP puede comportarse distinto según la edición [I].
4. No toqué `tests/laboratorio-adr090/LEEME.md` ni los guiones del anfitrión; el `modifyvm` es manual y lo corres tú.

Respuesta requerida: ninguna; la decisión de H120P-01 sale del ensayo (auditor de A: revisar la evidencia y las reglas de AppContainer si T3 o T5 las encuentran).
