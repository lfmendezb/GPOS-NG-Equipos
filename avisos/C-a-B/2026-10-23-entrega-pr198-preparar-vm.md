```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (a `B-a-C/2026-10-23-confirmaciones-preparar-vm-y-p-m168-01.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #198 `c/preparar-vm` @ 44019807 sobre `feature/modelo-ng` @ 67b4353a
Estado: Abierto
```

# PR #198: `Preparar-Vm.ps1` y lista de revisión de la evidencia (adelantado del 18-nov)

https://github.com/lfmendezb/GPOS-NG/pull/198 — dos archivos nuevos, nada fuera de `tests/laboratorio-adr090/`:

- `invitado/Preparar-Vm.ps1` (VM-SRV y VM-PUESTO): restos de la desatendida, `AutoAdminLogon` y el secreto LSA `DefaultPassword` borrado sin leerlo (SL-07), `w32time` deshabilitado, CAPI2 a 64 MB, IP fija en la red interna (`.10`, `.11` sin salir como origen, `fd00:50::10/64`), bloque delimitado en `hosts` con los 11 nombres del diseño, comprobación y, **solo si todo quedó bien**, el marcador `HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id`. Evidencia sin secretos en `C:\GPOS-LAB\evidencia\preparar-vm-*.json`. `-Comprobar` solo mira. Idempotente.
- `revision-evidencia.md`: cómo correrlo, qué confirmar en `VM-SRV` y la lista de revisión de la evidencia de cada sesión (procedencia, guardas, secretos, resultado por caso y recomendación).

**Cómo:** dentro de `VM-SRV`, todavía con el NAT, con punto de control previo y consola elevada de Administrador: `powershell.exe -ExecutionPolicy Bypass -File .\Preparar-Vm.ps1 -Vm VM-SRV -Adaptador 'Ethernet 2'`. Mientras haya NAT, `-Adaptador` es obligatorio (con dos adaptadores no elige solo, por S-03). Al final imprime las dos variables (`GPOS_LAB_TLS_VM`, `GPOS_LAB_TLS_ID`) que se ponen en cada consola; no se fijan para la máquina, a propósito. Después: apagar y `Cerrar-Preparacion.ps1 -Vm VM-SRV`.

**Probado aquí (sin VM):** análisis sin errores en PS 5.1 y 7; se niega en OSHIN-LEGION y, con el nombre `VM-SRV` simulado, por falta de elevación, sin tocar nada; 35 casos de las funciones de `hosts`, red y borrado en las dos versiones (las pruebas encontraron y corrigieron dos defectos: el bloque de `hosts` en una sola línea y `File.Replace` con `""` en lugar de `null`). Revisión de seguridad independiente: **Aprobado con observaciones**, sin Críticos ni Altos; S-01 a S-06 y N-1 a N-3 atendidos (el más importante, S-01: un marcador viejo ya no sobrevive a una ejecución que falla). Tabla en la sección 3 de `revision-evidencia.md`.

**Para B (todo [I], confirmar en la primera corrida):** (1) ¿el equipo se llama `VM-SRV`? Si no, el guion se niega y pide `Rename-Computer`; (2) que `Ethernet 2` sea la red interna; (3) qué restos deja de verdad la desatendida de la 7.2; (4) que `POLICY_CREATE_SECRET` alcance para borrar el secreto LSA `DefaultPassword` (si no, el paso 1 se detiene); (5) que `-Comprobar` dé todo `OK` después y otra vez tras restaurar `base`. Lo que falle me lo devuelves y lo corrijo.

**Fuera:** `preparar-vm.sh` de `VM-LNX` (no estaba en el encargo; lo escribo si lo pides), `Limpiar-Laboratorio.ps1` (retirará el bloque de `hosts` por sus delimitadores) y el cortafuegos.

Respuesta requerida: correr el guion en `VM-SRV` cuando operes la VM y devolver lo que falle; orden de unión cuando lo decidas.
