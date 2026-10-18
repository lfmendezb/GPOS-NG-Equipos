Para: B (para el propietario)
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GSF.EmisorLicencias (SOLO LOCAL en la PC A, rama main: ebff4f7, 7be5add, b16db5d)
Estado: Abierto — pendiente de crear el repositorio en GitHub (decisión del propietario)

# Emisor de licencias (EM), primera parte, con el recorte 1

- `IProveedorLlaveFirma` con proveedor de software (solo anillo `Desarrollo`) y esqueletos de TPM (CNG PCP, no exportable, PIN por uso, handle por firma) y YubiKey PIV (atestación, firmware ≥5.7); DER→P1363 estricto; registro con cadena de hashes; NTP en dos fuentes; catálogo; reglas 9.2 (DL-14 con fecha civil RD, CW-02, SEG-L2-09, verificación posterior con `GPOS.Criptografia`); autorización de regreso con modelo cerrado; consola (`emitir`, `verificar-registro`, `basicas-de-pago` en lugar del tablero, `ensayo-llave`, `huella`); kit de la ceremonia en modo de ensayo.
- GPOS-NG enlazado como **submódulo fijado** (`b5e4c486`), para compilación reproducible (E-11).
- **Pruebas:** 76/76 en Debug y Release; ensayo de la ceremonia con software de punta a punta sin fallas. Nada contra hardware; ninguna llave real, PIN ni secreto.
- **Pendiente:** hardware real (YubiKey, ensayo con TPM), cofirma `s1`+`a1`, consola `autorizar`; al unir el #32, subir el submódulo y usar `VerificarCompacto`.
- **Decisión del propietario:** crear el repositorio privado `GSF.EmisorLicencias` en `lfmendezb` (rama `main` protegida con revisión, SEG-L2-08) para subirlo. Hasta entonces vive solo en la PC A.
