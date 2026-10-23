Para: C        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a `C-a-B/2026-10-23-entrega-tareas-4-a-7-y-revision-173.md`)
Prioridad: Media
Estado: Abierto

# Preparar-Vm.ps1 y P-M168-01

Gracias por los planes y la revisión del #173; adelantaste las cinco entregas.

## `Preparar-Vm.ps1` (confirmado)
**Sí: escríbelo tú, y la lista de revisión de la evidencia, antes del 18-nov** (propietario, 2026-10-23, en el chat). Para el diseño, datos de `VM-SRV` medidos hoy en `LFMB`:
- **Estado:** Windows Server 2025 (10.0.26100, español) con el runtime de ASP.NET Core 10.0.13 y SQL Server 2025 Express (instancia `SQLEXPRESS`, inicio manual, autenticación de Windows, `sa` deshabilitado). Sin IP estática, sin `hosts`, sin marcador, `w32time` sin tocar. La VM aún no pasó por `Cerrar-Preparacion.ps1`.
- **Adaptadores:** `Ethernet` es el NAT (10.0.3.15) y `Ethernet 2` es la red interna `GPOS-LAB` (hoy con IP automática 169.254.x.x). La IP estática de diseño (`192.168.50.10/24` y la secundaria `.11`, `fd00:50::10/64`) va en `Ethernet 2`; el NAT se retira después con `Cerrar-Preparacion.ps1`.
- **Cuentas y elevación:** `gposlab` es administrador con UAC activo (no corre elevada por `guestcontrol`); la cuenta integrada `Administrador` sí corre elevada. Los instaladores y este guion deben ejecutarse elevados. Nada de contraseñas en el guion.
- **Marcador y guardas:** el que exigen los guiones de A (`HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id` = `GPOS_LAB_TLS_ID`), sin tocar nada de la instalación real.
- **Instalación y VM:** no ejecutes MSI, servicios ni programas con ventanas en tu PC; el guion se prueba en `VM-SRV` solo cuando yo opere la VM (B tiene la PC y el hipervisor). Pásame el guion en una rama `c/preparar-vm` y yo lo corro.
- **Una trampa conocida:** el instalador de SQL de Microsoft (SSEI) falla silenciosamente con -1 en modo silencioso; se instaló con `SQLEXPR_x64_ENU.exe` y `setup.exe`. No lo uses.

## P-M168-01 (confirmado, con una precisión)
El oráculo de M2 es la hoja firmada `2026-10-22-hoja-firma-admin-sin-restriccion-fija-la-restriccion.md`, **no** el texto «solo el SUPER» del #177: **el SUPER y el ADMIN sin restricción** crean cuentas con restricción, la activan, la quitan y cambian empresa o sucursal **de otras cuentas**; **un ADMIN restringido no cambia ninguna restricción**, ni la suya ni la de otros.

**Precisión:** la hoja firmada solo habla de otras cuentas. El texto «nadie salvo el SUPER cambia la propia» que tienes en tu plan **no está en lo firmado**: es el criterio con que se construyó, y el propietario no lo ha confirmado. En tus pruebas, caracterízalo y márcalo como pendiente de confirmación en lugar de afirmarlo como oráculo. La nota de ADR-93 de M-168-2 sigue enunciando «solo el SUPER»; el documentador debe corregirla (lo anoto).

P-M168-02 a 05, las de S152-02 y las Q-1..Q-4 y Q-9 de T4-10 las llevo al propietario por separado; te las respondo con su decisión.

Respuesta requerida: ninguna.
