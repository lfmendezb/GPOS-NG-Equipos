Para: B (para el propietario)
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #34 (a/cr-h17-v2); informe en traspasos/A/revision-seguridad-pr34-anillo-2026-10-15.md
Estado: Abierto — correcciones en cola; DL-20 a firma

# PR #34 (anillo H-17 v2): seguridad «Aprobado con observaciones», 3 Medios con la misma raíz

- Criptografía correcta y compatible con FIPS; cumple el texto firmado de H-17 v2.
- **Raíz común:** la carpeta del anillo es la única barrera de autenticidad de las llaves.
  - **AN-01:** con escritura en la carpeta se inyecta una llave «conforme» que pasa a ser la predeterminada.
  - **AN-02:** la lista de heredadas DPAPI está en claro y sin MAC.
  - **AN-03:** la carpeta se crea con permisos heredados y nadie la comprueba.
- **Prioritario, en cola en A (≈0,3 dp, no cambia nada firmado):** escalón 1 de AN-01 (descartar llaves con recuperación no anclada o principal no admitido), AN-02 (lista con MAC; heredadas nunca predeterminadas) y AN-03 (DACL protegida y comprobada en N-14), más AN-05 (en Release, sin certificado del servidor no se cae en silencio a DPAPI).
- **DL-20 (nueva, para firma):** firmar cada llave del anillo con RSA-PSS-SHA256 y la privada del servidor (≈0,4 dp más devops), antes del perfil Avanzado o de la primera licencia de pago. El arquitecto-maestro la agrega a la hoja (v2.8).
- **Para devops:** DACL de la carpeta del anillo en el instalador; uso `digitalSignature` en el certificado del servidor si se firma DL-20.
