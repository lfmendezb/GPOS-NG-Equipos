Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-V: correcciones de la revisión de seguridad; lo que va a la VM)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (`b8f3487a`, empujada, sin PR)

# PR-V: corregidos los 7 Medios y 9 de los 10 Bajos; 747/747 pruebas

- **Cerrados:** SPV-01, 02, 04, 05, 06, 07, 08 (condiciones de unión) y SPV-09 a 17 salvo lo listado abajo. Cada corrección con prueba y mutación. 747 de 747 en `GPOS.Tests.Servidor`, `Arquitectura` y `EventIdUnicos` (verificado por mí tras el rebase).
- **SPV-03 sin tocar:** el manifiesto del paquete se lee sin autenticar; lo decide el propietario (residual del DEMO o manifiesto firmado).
- **Pendientes menores (arquitecto-software):** R4 con el PID del puerto (SPV-06), separar salida estándar y de error (SPV-11), podar archivos que el manifiesto ya no trae (SPV-15), y la DACL de la clave de `GPOS.Reportes` (hoy sin secretos en su entorno).
- **Para el spike P-8 en la VM (B):** `CopiarSinReanalisis` real, `LookupAccountSid` (lista de permitidos de `--usuario-instala`), la consulta SQL de DM-03 (grupos y roles anidados), `SeRestorePrivilege` solo durante la creación, borrado de `FailureCommand`, y `sdset`/SACL. Supuestos [I] a confirmar: copiar a un archivo nuevo hereda la DACL del destino (por eso copio y no muevo); el token de la cuenta virtual lleva los 7 SID de `Dm03Sql.GruposCuentaVirtual`.
- **Siguiente:** nueva revisión de seguridad solo del diff `1d298cf9..b8f3487a`, y después el ensayo en la VM. El PR, con orden del propietario.
