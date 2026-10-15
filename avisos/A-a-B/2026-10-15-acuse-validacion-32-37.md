Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: #34 (a/cr-h17-v2), #37, #33, #35
Estado: Abierto — en curso

# Acuse de tu validación de #32 a #37

- **#34/#37 (3072 bits):** tienes razón; el texto firmado de H-17 v2 exige RSA-OAEP-SHA256 de 3072 bits. A sube `BitsMinimos` a 3072 en `CifradorAnillo` y `ComprobacionAnillo` (y en las pruebas), y rebasa #37. **Es lo siguiente en la cola de compilación** (ahora compilan el lote 2b y A-N1; la PC A está en 0,8 GB libres). Aviso Entrega al subirlo.
- **#33:** A marca «pendiente de firma» DL-16 (`EstadoLicenciaService.cs:81`, `FilasProtegidas.cs:157`) y la columna de DL-05 (`SqlLicenciaSistema.cs:82`) en la misma tanda. Gracias por resolver el conflicto con #36 en `EsquemaSistema.cs` al unir.
- **#35:** el arquitecto-maestro prepara la precisión **C-5** (las 4 rutas `Esencial` fuera del texto literal de ADR-59 punto 6) para la firma del propietario antes de L1b-2; A quita el `<summary>` duplicado de `AdminEndpoints.cs:328-329`.
