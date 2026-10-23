# Revisión del PR #179 (hoja de firma de DD-11′, C-1′ y C-2′) · equipo A · 2026-10-22

Alcance: 3 documentos (hoja, ADR-109 y ADR-110). Sin código. Marcas: [V] verificado por lectura; [I] inferido.

**Recomendación: Aprobar.** La hoja y las precisiones reflejan lo firmado y no cambian texto firmado. Las observaciones son requisitos para el diseño del sello (29-oct) y para T4-10; ninguna bloquea el #179.

## Coincidencia con lo firmado [V]
- Las tres citas de firma del propietario coinciden entre la hoja y las precisiones de los ADR.
- DD-11′ conserva el alcance de S-02 (marca y sello a todo texto que no salga de `GeneradorRazor`, sin importar `Modo`, y `CK_FormatoImpresion_VisualConDiseno`).
- Dice que el nodo sin API de reportes rechaza el Razor (falla cerrada).

## Observaciones
- **R179-01 (Media, para el diseño del sello):** la hoja define el sello como `HMAC(llave, versión ‖ Id ‖ TipoDocumento ‖ Modo ‖ Papel ‖ UTF-8(Plantilla))` sin fijar la codificación. Una concatenación sin longitudes es ambigua (el límite entre `Papel` y `Plantilla` puede moverse). Debe ser con prefijo de longitud. Además:
  - **Repetición:** el sello no cubre una versión de la fila; quien escribe en `conf` puede restituir una plantilla vieja que un SUPER sí selló para ese `Id`. Debe incluir un contador o la versión de la fila.
  - **Llave:** derivar una subllave propia del anillo (HKDF con etiqueta de uso), no usar la del cifrador de otros datos; la `Huella` lleva el identificador de la llave para rotarla.
- **R179-02 (Media, para T4-10):** C-2′ se aplica en el servidor, no solo en la interfaz. `imp.Cierre`, la ruta de impresión y la reimpresión del X exigen `vercuadrecaja` y dejan línea en la bitácora cuando lo deniegan; sin eso un cliente que llame a la ruta directamente imprime el X. Verificar también el Z.
- **R179-03 (Baja):** C-1′ depende de que el contador confirme los tipos de comprobante ([I] en la hoja). Mientras no los confirme, la lista cerrada debe ser la mínima (en la duda, enmascara) y la prueba debe fallar si aparece un tipo fuera de la lista.
- **R179-04 (Baja):** la hoja estima de 1 a 1,5 dp más sobre los 0,75 dp de DD-11 y marca `[I]`; mi diseño del sello (29-oct) la ajusta.

## Para unir
Aprobada. Se une cuando el propietario lo ordene (lo hace B).
