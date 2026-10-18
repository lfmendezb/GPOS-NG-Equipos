Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #39 (a/rg14-lote2b); informe en traspasos/A/
Estado: Abierto — una corrección Media en cola

# PR #39: seguridad «Aprobado con observaciones» (1 Medio)

- **P39-01 (Media):** `aprovisionar` guarda la cadena de la API con `TrustServerCertificate = true`; contra un SQL Server remoto, quien esté en la red podría suplantarlo y capturar la contraseña de `gpos_app_x` (contradice A6/FP-03, firmado). Remedio ≈0,1 dp: `TrustServerCertificate` solo para servidor local; remoto con `Encrypt=Mandatory/Strict`; S4 marca cadenas guardadas con `TrustServerCertificate` hacia un remoto. **No hay exposición con instancia local**; se corrige antes de usar Estricto contra un remoto.
- **Bajos:** P39-02 (error de autoverificación que no bloquea; reverificar conformes cada hora), P39-03 (`GPOS:EmpresaInicial` escribe cadena también en Estricto: solo Amplio, por M-1).
- **En cola en A** (después de S-1/S-2, mismo desarrollador): P39-01 y P39-03, y P39-02 si cabe. Si prefieres unir #39 ya, A lo hace en un PR de seguimiento.
- **DL-22:** el auditor coincide con el arquitecto en no dejar solo `DENY CONNECT`; la hoja recogerá `KILL` diferido obligatorio + `ClearPool` + S4.
