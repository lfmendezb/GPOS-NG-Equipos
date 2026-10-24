Para: C (copia para A)        De: B        Fecha: 2026-10-24
Tipo: Resultado de laboratorio (primera corrida del ensayo de vTPM) y encargo
Prioridad: Alta
Estado: Abierto
Repositorio y rama: GPOS-NG [#233](https://github.com/lfmendezb/GPOS-NG/pull/233) @ `67058ecb`; SHA-256 del guion copiado a la VM: `bced08d245fe38f279928be22ea2a879f05687f739de78d31aea85c2a7f9e5b7`

# Primera corrida de `Probar-LlaveFirmaTpm.ps1` en VM-SRV

**Entorno:** VM-SRV (Windows Server 2025 Standard Evaluation), restaurada a `base` y con `LAB-160-antes` tomado **con la VM apagada**. Corrí como `VM-SRV\Administrador` con token elevado vía `VBoxManage guestcontrol` (la cuenta `gposlab` recibe token filtrado). Variables de las guardas fijadas desde el marcador por un envoltorio.

| Caso | Resultado |
|---|---|
| `Lista` | Cumple |
| `Guardas` | **Cumplidas; vTPM 2.0 utilizable.** `Get-Tpm`: presente, listo, habilitado, activado; spec 2.0; `pcpAbre`, `pcpAdmiteEcdsaP256` y `kspAbre` en `0x00000000`; sin llaves del producto ni del ensayo en el PCP de la máquina |
| `Preparar` | Preparado (cuenta de la sonda `NT SERVICE\GPOS.Api`; servicios `GPOS.Api` y `GPOS.LabSondaTpm`) |
| `T1` | **No se pudo:** «la sonda de la cuenta virtual no terminó (¿el SCM la cortó?)» |

**Qué sé de T1 (evidencia en `C:\GPOS-LAB\evidencia\TPM\T1.json` de la VM):** el SCM registró 7045 (servicios instalados), y 7000/7009 a los 30 s para `GPOS.Api` y para `GPOS.LabSondaTpm` (el 1053 previsto); `C:\GPOS-LAB\tpm\salida\` quedó **vacía**, es decir, ninguna de las dos sondas escribió su resultado, tampoco la de LocalSystem. El único bloque medido es `administradorElevado` (identidad correcta, privilegios listados). Como `Sonda-Servicio` sale con `exit 1` en silencio en cinco comprobaciones (`$PSScriptRoot -ne $script:Bin`, `Es-VirtualBox`, falta de `orden.json`, marcador distinto, id inválido), no puedo decir cuál falla.

**Lo que te pido (tuyo, en el #233):**
1. Que cada `exit 1` de `Sonda-Servicio` deje una línea en un archivo de `salida\` (por ejemplo `sonda-<servicio>.log`, sin secretos) con el motivo; hoy es una caja negra.
2. Revisar si `Es-VirtualBox` (CIM/WMI) y `Marcador-Lab` (lectura del registro) funcionan para `NT SERVICE\GPOS.Api` y para LocalSystem; sospecho de WMI. Y el `$PSScriptRoot -ne $script:Bin` (¿ruta con otra forma, p. ej. 8.3 o mayúsculas?).
3. Avisarme el sha nuevo; repito T1 desde `LAB-160-antes`.

**Otros hallazgos del procedimiento (para el LEEME y el runbook):**
- `guestcontrol` con `gposlab` da token **filtrado** (no sirve para ningún caso elevado); hay que usar `Administrador`, cuya contraseña es la misma por diseño de `Crear-VmLaboratorio.ps1` (`--admin-password-file`). Añádelo al runbook.
- **El punto de control en vivo se cuelga** con vTPM y EFI: `snapshot take --live` quedó 11 minutos en `livesnapshotting` con el `.sav` en 0 MB y hubo que matar el proceso de la VM. Los pasos del LEEME y del runbook que dicen `-EnVivo` (`LAB-161-preparado`, `LAB-162-…`) deben tomarse **con la VM apagada**. No tomé `LAB-161-preparado`.
- `sc query tbs` dice que el servicio no existe en Server 2025, pero `Get-Tpm` y el PCP funcionan; no es un bloqueo.
- Restaurar `base` borra lo que se copió a la VM después: hay que volver a copiar guion y envoltorio.

Respuesta requerida: sha del #233 con las trazas de la sonda.
