# Revisión del #198 (Preparar-Vm.ps1) y preparación de T4-06 (A, 2026-10-23)

## #198 (`44019807`, `Preparar-Vm.ps1` y lista de revisión de la evidencia): **aprobado**
Revisé el guion completo (627 líneas) y la lista; no lo ejecuté (es solo para la VM). Sin Críticos, Altos ni Medios.
- **Guardas (LS-11):** Windows, sesión elevada, modelo VirtualBox, fuera de dominio, nombre del equipo igual a la VM (nunca `LFMB` ni `OSHIN-LEGION`) y sistema acorde. Se comprueban antes de tocar nada.
- **Marcador:** `HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id` (vista de 64 bits), escrito el último, retirado al empezar y si algo falla (S-01); `IdRetirado` lo conserva sin que las guardas lo lean. Es el mismo valor y la misma ruta que leen `Probar-Spike-Amplio.ps1` (#173) y `Probar-Instalador.ps1` (#165): compatible. Lo que lee mi guion es el valor `Id` con la comparación sensible a mayúsculas (`-cne`), igual que el de C.
- **Secretos:** nunca lee la clave del inicio de sesión automático (solo presencia del valor) y borra el secreto LSA sin leerlo; la evidencia lleva rutas, huellas y estados, no valores.
- **hosts:** bloque delimitado, escritura por archivo temporal y reemplazo, se niega ante un `hosts` que no sea UTF-8 o ASCII y ante nombres del laboratorio fuera del bloque.
- **Red:** rechaza un adaptador con ruta por omisión o con una dirección 10.0.x.x del NAT de VirtualBox; sin puerta de enlace ni DNS.
- **Observaciones Bajas, sin pedir cambio:** (1) el paso 1 borra por nombre (`*unattend*.xml`, `VBoxPostInstall*`…) de forma recursiva en `Panther`, `Setup` y `Temp`; es aceptable dentro de la VM y las rutas quedan en la evidencia (`restosBorrados`). (2) Mis guiones asumen Windows PowerShell de 64 bits para leer el marcador (`HKLM:` sin `-Wow6432`); es el valor por omisión en la VM, pero conviene anotarlo en el procedimiento del 23-nov. (3) El punto 4 de «Qué confirmar en VM-SRV» (`-SkipAsSource`) y el 5 (qué restos deja VirtualBox 7.2) siguen como [I] hasta la primera sesión.

## T4-06: preparación (sin construir; arranque 3-nov)
Estado: el blueprint `blueprint-t4-06-lista-p2-2026-10-22.md` sigue vigente. **No empezar sin las respuestas de B a P-1, P-2 y P-3 (y P-4, Q-A4).** Lo nuevo de hoy que cambia o aclara el plan:
1. **#202 (T4-07)** ya está en revisión y toca los mismos archivos de reenvío (`ReportesEndpoints.cs`, `ReenvioReportes.cs`): T4-06 debe rebasar sobre T4-07 y heredar `ReenvioReportes.NoDisponible()` en vez de duplicar el 503 `REPORTES_NO_DISPONIBLE`. Choque a añadir en la sección 13.
2. **R-2 del blueprint (el DEMO, el ensayo corto y el laboratorio no arrancan sin `Reenvio:Direccion`) se agrava:** además de Q-6, T4-07 hace que el tablero responda 503 sin reenvío (T4-07-01 de mi revisión). El DEMO en modo procesos queda sin tablero ni reportes P-2. Debe resolverse en la tarea 3: el DEMO de servicios (PR-D2) lleva la API de reportes; el DEMO de procesos (`demo/2026-10-15`) no se actualiza.
3. **Reporte 9 reescrito:** debe usar `rpt.CxcDocumento.SucursalId` (misma regla que la tarjeta de CxC del tablero, TBS-01). Añadir a TA-1.
4. **P-2 del blueprint (programados):** con el #197 revisado, la caracterización de C queda confirmada y se invierte en T4-06; antes de abrir `a/t4-04-emisor` correré las dos pruebas de P175-02 con el emisor real. Si T4-06 se une antes que T4-04, sigue valiendo la falla cerrada (a).
5. **P-3 (Linux):** sin cambio.

### Preguntas que siguen abiertas para B (resumen)
| Id | Pregunta | Mi recomendación |
|---|---|---|
| P-1 | Guardar del diseñador en Release | (a) validar columnas en la API de reportes |
| P-2 | Programados si T4-06 se une antes que T4-04 | (a) falla cerrada |
| P-3 | La principal Release no arranca en Linux con Q-6 | (a) aceptar hasta el socket Unix |
| P-4 | Quién adapta el ensayo corto y no publicar DEMO entre T4-06 y la tarea 3 | Devops de A, con la tarea 3 |
| Q-A4 | (ver blueprint, sección 15) | — |
