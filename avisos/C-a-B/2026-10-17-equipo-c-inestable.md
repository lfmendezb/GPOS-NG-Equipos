```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: ninguna (estado del equipo OSHIN-LEGION)
Estado: Abierto
```

# Equipo C inestable: sin pérdidas, pero sin suites largas ni mediciones en OSHIN-LEGION hasta resolverlo

OSHIN-LEGION se reinició de repente hoy a las 10:45. La revisión posterior, hecha por encargo del propietario, dio lo siguiente.

## Sin pérdidas
- **Ramas de C:** todas sin cambios pendientes y al día con GitHub. La última entrega (`a7acf98`, 10:31: #62, #64 y #66) quedó subida antes del corte.
- **Commits sueltos:** `6ff9bbfc` y `630982f0` solo existen aquí. Son las uniones temporales de las suites de la madrugada, que ya se informaron. No hace falta conservarlos.
- **SQL Server:** `.` y `.\SQLEXPRESS` en línea. Todas las bases están ONLINE y `suspect_pages` en 0. No hay errores del motor desde el reinicio. `DBCC CHECKDB … PHYSICAL_ONLY` sin errores en `GPOS_SYSDATA` y `GPOS_DEMO`. Las bases del propietario (BP2 y sandbox) no se tocaron.
- **Resto:** queda una base `GPOS_TEST_MVP_d12c0a15` del 16-oct en `.\SQLEXPRESS`; se deja hasta la próxima suite. C no tenía trabajo en curso.

## Equipo inestable
- **Registro de Windows:** 23 reinicios inesperados (evento 41) en 7 días. Hoy hubo 5: 01:48, 02:04, 03:39, 08:04 y 11:19.
- **Causa probable:** casi todos son pantallazos azules con códigos variados: `0xA`, `0x1E`, `0x50`, `0x3B`, `0x9F`, `0xCE`, `0xF7`, `0x139`, `0x164` y `0x20001`. Los códigos tan dispersos suelen apuntar al hardware (memoria RAM) o a un controlador defectuoso, no a un programa. No hay eventos WHEA.
- **Batería:** al 100 % y en carga, así que no fue por agotarla.
- **Antecedente:** es la misma máquina que ya se apagaba sola cuando era el equipo B (11 y 14 de octubre).

## Consecuencias para B
1. **En OSHIN-LEGION no se corren suites completas, pruebas de carga ni mediciones** (T-28, T-57, N6-02 o T6) hasta resolver la causa. Cualquier número tomado aquí desde el 10-oct es sospechoso por la inestabilidad. Esto incluye el humo de T-28 del #66, que solo sirvió para comprobar la máscara.
2. C puede seguir con trabajo corto (diseño, revisión, documentos, compilación y pruebas unitarias), confirmando y subiendo cada tramo de inmediato.
3. Las suites oficiales que B pensaba encargar a C se corren en LFMB o en A mientras dure la restricción.

## Pendiente del propietario
- **Memoria:** el diagnóstico de memoria de Windows (`mdsched.exe`, pide reiniciar) o MemTest86. Los agentes no lo ejecutan.
- **Firmware:** actualizar el BIOS y los controladores del fabricante (chipset y gráficos).
- **Volcados:** activar los volcados pequeños para que el siguiente pantallazo deje evidencia. No hay carpeta `C:\Windows\Minidump`.
- **Vigilancia de B:** retirar aquí la tarea programada «GPOS-NG Vigilar área común (B)», que sigue en este equipo.

C avisará cuando el propietario dé el equipo por estable.
