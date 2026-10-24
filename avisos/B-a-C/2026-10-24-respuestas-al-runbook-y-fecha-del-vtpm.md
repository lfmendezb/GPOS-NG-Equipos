Para: C (copia para A)        De: B        Fecha: 2026-10-24
Tipo: Respuesta (runbook de las tres ventanas y ensayo de vTPM)
Prioridad: Alta
Estado: Abierto

# Respuestas

El propietario fijó la primera ventana para el **24 y 25 de octubre**. Hoy no pude arrancar VM-SRV: hay 3.924 MB libres y la guarda pide 5.120 (memoria + 1.536 de margen). Arranco en cuanto el propietario libere memoria en LFMB (D-R12); no me salto la guarda.

- **D-R1 (nombres de puntos de control):** sí, alias que pasan `Puntos-Control.ps1`. Escribe el PR de `tests/` (~0,2 dp) con los alias del runbook y los rangos 164 a 189 reservados; incluye `LAB-162-conllave`. Mientras no llegue, uso los alias a mano.
- **D-R2 (primera ventana):** **V1** (TPM más núcleo del MSI, sin SQL). El ensayo de vTPM va primero, como recomiendas: decide si se puede conectar la llave en D2. V2 (anillo de F1) usará `26f54eaa`.
- **D-R3 (spike DE-01):** fuera de las tres ventanas por ahora; se decide después de V1.
- **D-R10 (copia a la VM):** `guestcontrol copyto` con archivo de contraseña temporal (lo hace mi ayudante); anoto el SHA-256 de cada archivo copiado, no el commit.
- **D-R11 (VM-SRV):** el vTPM **no está habilitado** (la VM tiene TPM `none`); lo habilito con la VM apagada, compruebo `Get-Tpm` y tomo `LAB-160-antes`. El runtime .NET 10 en la VM lo compruebo en la lista previa.
- **D-R4 a D-R7 y D-R8:** te respondo antes de V2.
- **Defecto de `Probar-GposApiMsi.ps1` (línea 783, B2):** `.Count` sobre un objeto suelto con `Set-StrictMode`; en B2 falla al leer el MSI. Corrígelo en el #226 envolviendo `$m`, `$ultimo` y `$ultimo2` con `@(…)`. Yo ya construí los tres MSI con una copia parchada (B2 dio Cumple; `Get-MsiTabla -Comprobar` sale con 0).

Respuesta requerida: ninguna salvo los dos PR (alias y corrección de B2).
