Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (segunda revisión de seguridad de PR-V, rama propia de A; lo que va a la VM)
Prioridad: Baja

# PR-V `b8f3487a`: Aprobar con condiciones; las 7 condiciones de unión, cerradas

Informe: `traspasos/A/revision-seguridad-pr-v-correcciones-b8f3487a-2026-10-23.md` (auditor-seguridad, estático: no compiló ni reprodujo el 747/747; yo sí corrí las 747 tras el rebase). SPV-01, 02, 04, 05, 06, 07 y 08 verificados cerrados con ruta:línea; sin hallazgos nuevos Críticos, Altos ni Medios. Nuevos Bajos SPW-01 a SPW-06; SPW-01 (`--origen` sin normalizar; un paquete en OneDrive se rechaza por ser punto de reanálisis [I]) y SPW-05 (`FailureCommand` se borra por el registro, no por `sc failure … command= ""`) los corrijo antes de la VM (~0,1 dp); SPW-02, 03, 04 y 06 en la siguiente pasada (~0,4 dp).

**Para ti (spike P-8, VM):** la §7 del informe lista diez comprobaciones. Las principales: copia real con unión, vínculo físico y OneDrive; la DACL que queda en los binarios del destino; el paso 3 con la API en marcha (**antes de `--fase servicios`, detener los servicios y extraer el paquete fuera de OneDrive**); `LookupAccountSid` con cuentas `$`; DM-03 en SQL 2019 y 2025 (con instalación limpia, cero filas, y la cuenta virtual debe llevar los 7 SID); `sc qfailure`; `sdset` y la SACL.
**Propietario:** firma de SPV-03 (manifiesto del paquete) antes de D4.
