```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (7ec54c4, b668a98)
Estado: Abierto
```

# El conector de IQ cumple el vector de ADR-77; tres observaciones para una versión 2 del vector

B copió `adr077-carpetas.v1.json` al conector y comprobó que es idéntico al de `master`:
- SHA-256 `ebb50202…0c0a`;
- LF fijo con `.gitattributes`, necesario porque la PC B tiene `core.autocrlf=true`.

También agregó 10 pruebas (`InstaladorVectorAdr077Tests`) que comparan con el vector:
- la ruta y el SDDL de la raíz;
- la lista blanca en la acción del MSI, en el arranque y en el registro;
- el escritor adicional de las carpetas de datos;
- los cuatro rechazos con 1603;
- la creación de la raíz;
- las «carpetas de otros»;
- el anillo sin DPAPI de máquina.

**El conector no cambió.** La suite pasa 195 + 376 pruebas y el MSI sigue en 0.4.2.

**Observaciones** (no hay diferencias que corregir en el conector):
1. **SF-04, desviación ya aceptada:** al arrancar, el servicio admite **su propia identidad como dueña** de su carpeta de datos, porque él mismo crea ahí el diario, las credenciales y el anillo. El vector la admite solo como **escritora**. La acción del MSI sí sigue el vector al pie de la letra. **Proponemos** que una versión 2 del vector lo mencione, o que A lo registre como desviación aceptada de ADR-77.
2. **Un quinto motivo de rechazo en la acción,** `SEGURIDAD_ILEGIBLE` (no se puede abrir la carpeta o leer su seguridad): es más estricto que el vector y también termina en 1603. Conviene que el vector lo tenga, para que todos los instaladores lo traten igual.
3. **`CREATOR OWNER` se admite como escritor** en la acción y en el arranque, y el vector no lo menciona. En Windows es solo una plantilla que, al heredarse, se reemplaza por el dueño real (inferido; no se probó en una instalación). Conviene que el vector lo diga, en un sentido o en el otro.

Cuando A publique una versión nueva del vector, B la copia, actualiza la huella en la prueba y corre la suite.
