# Procedimiento: cuenta `gpos-lab-usuario` en VM-SRV (tarea 1.2 de B)

Fecha: 2026-10-25 (redactado el 24-oct). Autor: equipo A. Lo ejecuta el propietario a mano. Ningún agente crea la cuenta.
Marcas: [V] verificado en archivos; [I] inferido, a confirmar en la VM.

## 1. Qué cuenta

- Nombre exacto: `gpos-lab-usuario` (minúsculas, con guiones) [V: valor por omisión de `-CuentaEstandar` en `Probar-GposApiMsi.ps1:92` y `Probar-Instalador.ps1:32`; el runbook lo repite, 2.3 punto 23].
- Local de `VM-SRV` (no de dominio), **estándar**: miembro solo del grupo `Usuarios` (`BUILTIN\Users`, SID `S-1-5-32-545`). NO miembro de `Administradores` ni de `Operadores de copia de seguridad`, `Usuarios avanzados`, `Operadores de configuración de red`, `Lectores del registro de eventos`, `Usuarios del administrador de sistema` ni de ningún otro grupo con poder [I: el criterio es que mida lo que puede un usuario común].
- Habilitada, con contraseña (no vacía: `runas` no acepta contraseña vacía [I]).
- Cuentas que ya existen y no se tocan: `Administrador` integrado (la consola elevada) y `gposlab` (no corre elevada) [V: `Preparar-Vm.ps1:118`, runbook punto 16]. `Preparar-Vm.ps1` no crea ninguna cuenta (no contiene `New-LocalUser` ni `net user`) [V].

## 2. Por qué la necesitan

| Caso | Qué prueba con ella | Evidencia |
|---|---|---|
| O1a (`Subcaso-O1 'a'`, `Probar-GposApiMsi.ps1:1210`) | Planta la raíz de datos de la API con **dueño** `gpos-lab-usuario` (`icacls /setowner`) y espera que el instalador rechace con `DUENO_NO_PERMITIDO`. Solo necesita que la cuenta exista (no inicia sesión con ella). | [V] |
| P-O1-7.1 de `Probar-Instalador.ps1` (y P-O1-7.7-ejecutar que lo repite) | Lo mismo con el MSI del agente de impresión (`Plantar-Raiz-De`, línea 110). Si la cuenta no existe, el guion se detiene con «¿existe la cuenta?» (línea 113). | [V] |
| N1 (`N1a-instrucciones`, `N1b-ejecutar`, `N1`; Crítica) | N1a: instalar el MSI como usuario estándar con `runas /user:%COMPUTERNAME%\gpos-lab-usuario "msiexec.exe /i ... /qn"`; debe fallar por falta de privilegios. Aquí sí se **inicia sesión** con la cuenta y se teclea su contraseña (líneas 1998 a 2011). | [V] |
| I7 (`I7-cuenta -Etiqueta usuario`, y `-Fase abrir`/`cerrar` del control) | Mide, **sin elevar y como esta cuenta**, qué derechos tiene sobre el servicio `GPOS.Api` (SDDL de Q-5: los `BU` solo consultan). Deja `I7-cuenta-usuario.json`; I7 no cierra sin él (líneas 1097 a 1155). | [V] |
| Spike DE-01 (`Probar-Spike-Amplio.ps1:188` y `:219`) | Pasos manuales: como la cuenta, abrir `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api` y listar tres carpetas; se anota solo «denegado» o «permitido». | [V] |
| `restaurar` (PR-D2) | El runbook (punto 23) dice que la cuenta sirve también a `restaurar`, pero no encontré ninguna referencia en los guiones de `GPOS-NG-prd2`. | [V] la ausencia; el runbook solo lo afirma |

Línea del anillo: el runbook (línea 214) dice que spike y anillo comparten la cuenta; el guion del anillo no la usa en los archivos que revisé [I: no abrí `Probar-Anillo.ps1`, que vive en otra rama].

## 3. Quién, dónde y cuándo

- **Quién:** el propietario, a mano, en la consola de `VM-SRV`. Ni C, ni B, ni los agentes (regla de los agentes: no crean cuentas).
- **Dónde:** `VM-SRV`, sesión **elevada** como `Administrador` integrado.
- **Cuándo:** en la preparación de la línea MSI, con `base` **restaurada** y **antes** de copiar los archivos del laboratorio y de instalar nada; es decir, justo antes del punto de control `LAB-140-baseok` [V: runbook 2.4 fila MSI «`base` restaurada + `gpos-lab-usuario` + archivos copiados y verificados, antes de instalar nada», y Parte B, «Estado de partida»]. Orden: restaurar `base` → `Preparar-Vm.ps1 -Comprobar` en `OK` (punto 16) → **crear la cuenta (este documento)** → copiar y verificar SHA-256 → B toma `LAB-140-baseok`.
- **Consecuencia importante:** la cuenta no vive en `base` (la crea el propietario después). Cada vez que se restaure `base` en vez de un punto derivado de `LAB-140-baseok`, hay que volver a crearla [I: un punto de control restaura el disco del momento]. Los puntos `LAB-141` a `LAB-144`, tomados después, la conservan [I]. Para spike y anillo el runbook propone arrancar de `LAB-150-sqllisto` y de `LAB-164-basef1`: **si se quiere que la cuenta viaje en ellos, hay que crearla antes de tomarlos** (decisión de B; lo ideal, y lo más barato, es crearla una vez y tomar un `base` nuevo si el propietario prefiere no repetir el paso: ver la pregunta del punto 7).

## 4. Cómo crearla (consola elevada, PowerShell 5.1)

No se guarda la contraseña en ningún archivo, nota, variable de entorno, historial ni evidencia. La teclea el propietario en una petición segura:

```powershell
$clave = Read-Host -AsSecureString 'Contraseña de gpos-lab-usuario (no la anote)'
New-LocalUser -Name 'gpos-lab-usuario' -Password $clave -FullName 'Usuario estandar del laboratorio' `
  -Description 'Laboratorio ADR-090: cuenta estandar, sin privilegios' `
  -PasswordNeverExpires -UserMayNotChangePassword -AccountNeverExpires
Add-LocalGroupMember -SID 'S-1-5-32-545' -Member 'gpos-lab-usuario'
Remove-Variable clave
```

Equivalente con herramienta: `lusrmgr.msc` (Usuarios y grupos locales) → Usuarios → Nuevo usuario; quitar «El usuario debe cambiar la contraseña en el siguiente inicio de sesión», marcar «La contraseña nunca expira»; pestaña «Miembro de»: solo `Usuarios`.
Con `net user` (no recomendado: la contraseña queda visible en pantalla y en el historial de la consola): evitarlo.

Antes de cerrar la consola: `Clear-History` no hace falta si se usó `Read-Host -AsSecureString` (la contraseña no aparece en el comando) [I].

### Política de contraseña y expiración para el laboratorio

- Contraseña de **16 o más caracteres**, que cumpla la complejidad que ya exige Windows Server (no se relaja la política local: el laboratorio también prueba bajo FIPS y la política por omisión) [I].
- `PasswordNeverExpires`: sí (la VM tiene el reloj detenido y se mueve con `Ajustar-Reloj.ps1`; una expiración falsearía N1 e I7) [I]. `AccountNeverExpires`: sí.
- `UserMayNotChangePassword`: sí. Sin cambio obligatorio al primer inicio (de lo contrario `runas` falla).
- Es una contraseña de laboratorio, **distinta** de cualquier otra del propietario; la VM no lleva datos reales. El técnico la memoriza o usa el gestor del propietario; no se escribe en el acta ni en `evidencia\`.
- No requiere derecho de «Permitir inicio de sesión local» extra; si N1a falla con «inicio de sesión no permitido», mirar si la política deniega a `Usuarios` y el servicio `Inicio de sesión secundario` (`seclogon`) está en ejecución [I].

## 5. Comprobar que existe y es estándar (solo lectura)

En PowerShell, en la VM (no requiere elevación):

```powershell
Get-LocalUser -Name 'gpos-lab-usuario' | Select-Object Name, Enabled, PasswordRequired, PasswordExpires, AccountExpires
Get-LocalGroup | ForEach-Object { $g = $_.Name; Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue |
  Where-Object Name -like '*\gpos-lab-usuario' | ForEach-Object { "$g <- $($_.Name)" } }
whoami /groups        # ejecutado COMO la cuenta (runas): no debe mostrar BUILTIN\Administrators ni nivel de integridad Alto
```

Esperado:

- `Enabled = True`, `PasswordRequired = True`, `PasswordExpires` vacío, `AccountExpires` vacío.
- La segunda orden devuelve **una sola línea**: `Usuarios <- <EQUIPO>\gpos-lab-usuario`. Cualquier otro grupo (sobre todo `Administradores`): quitar con `Remove-LocalGroupMember` y repetir; no tomar el punto.
- `whoami /groups` como la cuenta: sin `Administradores`, integridad «Medio» [I]. Es el mismo criterio de `Es-AdminFiltrado` del guion [V: `Probar-GposApiMsi.ps1:207`].

Dejar la hora y el resultado en el acta (sin contraseña).

## 6. Punto de control posterior

- Nombre: **`LAB-140-baseok`** [V: runbook 2.4; el alias válido para `Puntos-Control.ps1`; `LAB-140-base-ok` NO pasa el patrón, D-R1 de B]. Si B no aprueba el alias, se usa el nombre que B fije; no se inventa otro.
- Se toma con la VM apagada o como lo defina B, **después** de: cuenta creada y comprobada (punto 5), archivos copiados y SHA-256 verificados, y antes de instalar nada. La toma la hace B desde `LFMB` (en el runbook, la fila B0 «toma 140 (una vez, antes)»).
- Para spike y anillo: `LAB-150-sqllisto` y `LAB-164-basef1` (runbook 2.4) heredan la cuenta solo si se parte de ellos habiéndola creado antes; si se parte de `base`, repetir el punto 4.

## 7. Qué hace el guion si no existe

- `Probar-Instalador.ps1` P-O1-7.1: se detiene con «no se pudo cambiar el dueño de la raíz a gpos-lab-usuario (¿existe la cuenta?)» [V: línea 113].
- `Probar-GposApiMsi.ps1` O1a: **no se detiene**. `icacls /setowner` falla y el error se descarta (`2>&1 | Out-Null`, línea 1210); la raíz queda con el dueño por omisión y el caso daría un resultado engañoso (probablemente `No cumple`) [V la línea; I el resultado]. Hallazgo: `Guardas` tampoco comprueba la cuenta (no hay `Get-LocalUser` en el guion) [V]. Propuesta para C/B (cambio de `tests/`, no lo hago yo): que `Guardas` falle si `Get-LocalUser $CuentaEstandar` no existe y si es miembro de `Administradores`. Costo ≈ 0,1 dp.
- N1a: `runas` falla (usuario o contraseña incorrectos); N1 queda `No se pudo` por falta de `N1a.log` [V: líneas 2009 y 2010]. I7: `faltan: I7-cuenta -Etiqueta usuario` [V: línea 1147].

## 8. Pregunta para B

¿Se crea la cuenta una vez y se toma un `base` nuevo (más cómodo; cambia el `base` de las demás líneas y exige repetir `Preparar-Vm.ps1 -Comprobar`) o se crea en cada línea justo antes de su primer punto de control (lo que dice el runbook hoy)? Recomendación de A: como el runbook, para no tocar `base`; son ≈ 3 min por línea.

Contraseñas: ninguna aparece en este documento ni debe aparecer en la evidencia.
