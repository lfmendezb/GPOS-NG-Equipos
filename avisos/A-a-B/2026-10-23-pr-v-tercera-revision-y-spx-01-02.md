Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-V: tercera revisión de seguridad publicada; SPX-01, SPX-02 y SPX-04 corregidos)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (`b43951af`, empujada, sin PR)

# PR-V, tercera revisión de seguridad: Aprobar con condiciones; las condiciones previas a la VM, corregidas

- **Informe:** `traspasos/A/revision-seguridad-pr-v-red-origen-82bf648d-2026-10-23.md`. Rango `79bf8905..82bf648d` (origen `GPOS.Instalacion`, verbo `red`, R4/P4). Sin hallazgos Críticos, Altos ni Medios; nueve Bajos (SPX-01 a SPX-09). Recomendación técnica: **Aprobar con condiciones**; la decisión es del propietario.
- **Corregido en `b43951af` (805/805 con el filtro de PR-V):**
  - **SPX-01:** `red` repite las guardas de PT-06 y de valores sobre la clave releída, justo antes de escribir; si otro administrador la creó en medio con otro modo, se detiene con 4 sin escribir valores.
  - **SPX-02:** `red` lee el padre `SOFTWARE\GPOS NG` (nuevo `ISistemaServidor.LeerPadreRed`), le aplica S-05 y se detiene con 4 si el padre o la clave `Servidor` son vínculos simbólicos (`REG_OPTION_OPEN_LINK` y `SymbolicLinkValue`). Un padre ilegible da 1.
  - **SPX-04** (de paso, 0,02 dp): un `PuertoApi` que no es `REG_DWORD` detiene con 4 si no se da `--puerto-api`; ya no se «arregla» en silencio.
  - Cinco pruebas nuevas en `RedServidorTests`.
- **Sin corregir (siguiente pasada):** SPX-03 (decisión del propietario: lectura por Usuarios autenticados; ACE de `GPOS.Web` en lugar de la de `GPOS.Reportes`), SPX-05, SPX-06, SPX-07, SPX-08, SPX-09 (unas 0,4 dp en total).
- **Para B y el MSI:** `SOFTWARE\GPOS NG` debe crearse con la DACL heredada, nunca más laxa; y un canal de eventos propio con `ChannelAccess` (SPX-07).
- **Para la VM (§7 del informe):** el vínculo simbólico solo se detecta de verdad en Windows; confirmar con un padre de DACL laxa preparado a propósito que el verbo se detiene con 4. La detección por P/Invoke no tiene prueba fuera de la VM.
- **Pendiente de A:** nada más en PR-V hasta tu respuesta sobre `tls` (aviso `2026-10-23-pr-v-verbo-red-y-tls.md`) y la orden de abrir el PR.
