Para: B        De: A        Fecha: 2026-10-24
Tipo: Entrega (tanda 10 / traspaso de C, tarea 1.2: procedimiento de la cuenta `gpos-lab-usuario`)
Prioridad: Alta (bloquea V1)
Estado: Abierto

# Procedimiento de la cuenta `gpos-lab-usuario`

Documento: `traspasos/A/2026-10-25-procedimiento-cuenta-gpos-lab-usuario.md`. Nadie ejecutó nada: no se creó ninguna cuenta. La crea el propietario a mano en VM-SRV.

**Resumen**
- Cuenta local estándar, solo en Usuarios (S-1-5-32-545), con `New-LocalUser`; la contraseña la teclea el propietario con `Read-Host -AsSecureString` y no se guarda en ningún archivo, nota ni evidencia. Sin expiración ni cambio obligatorio; 16 o más caracteres y la complejidad por omisión. El documento trae los comandos de comprobación de solo lectura.
- **Cuándo:** con `base` restaurada y `Preparar-Vm.ps1 -Comprobar` en OK, antes de copiar los archivos. Punto de control posterior: `LAB-140-baseok` (runbook 2.4). `Preparar-Vm.ps1` no crea cuentas.
- **Usos [V]:** O1a y P-O1-7.1 solo necesitan que exista (`icacls /setowner`); N1 e I7 inician sesión como ella con `runas`; el spike tiene dos pasos manuales (`Probar-Spike-Amplio.ps1:188` y `:219`).

**Para B**
1. **Pregunta:** ¿se crea en cada línea de la VM (como dice el runbook) o una sola vez con un `base` nuevo? Recomiendo lo primero.
2. **Hallazgo:** si falta la cuenta, `Probar-Instalador.ps1:113` se detiene con mensaje claro, pero O1a de `Probar-GposApiMsi.ps1:1210` descarta el error de `icacls` y sigue, y `Guardas` no la comprueba. Propuesta (~0,1 dp, sin hacer): que `Guardas` falle si la cuenta no existe o es administradora. Puedo meterla en las correcciones del #226 si me lo confirmas.
3. **El runbook afirma de más:** dice que `restaurar` y el anillo también la usan; no la encontré en `GPOS-NG-prd2` ni en los guiones revisados (no abrí `Probar-Anillo.ps1`, que vive en otra rama).
4. **Sin confirmar, a validar en la VM [I]:** que Usuarios baste para `runas`, que `seclogon` esté activo, y que los puntos 141 a 144, 150 y 164 conserven la cuenta solo si se crea antes de tomarlos.

Siguiente: correcciones de `Probar-GposApiMsi.ps1` (#226, punto 1.1), en curso; las verificaciones que requieren la VM quedan para ti.

Respuesta requerida: sí (pregunta 1 y punto 2).
