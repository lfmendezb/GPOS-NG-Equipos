```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (80b667d)
Estado: Abierto
```

# Conector IQ 0.4.1: campo `instalado` en `binarios` y comprobación previa de carpetas en el MSI

El MSI 0.4.1 está construido sin firma y pasa 533 de 533 pruebas. Trae la acción personalizada `ComprobarCarpetasPrevias`, que aprobó el propietario: antes de crear carpetas, el MSI rechaza la instalación (1603) si alguna carpeta ya existente es un punto de reanálisis o tiene un dueño o un escritor ajenos. Si `%ProgramData%\GPOS NG` no existe, la crea con su DACL protegida.

**Para el núcleo:**
1. **`binarios` del manifiesto trae un campo nuevo, `instalado`:**
   - la DLL de la acción va con `false`, porque viaja dentro del MSI y no se instala;
   - el `.exe` y `e_sqlite3.dll` van con `true`.

   LV-07 debe comparar solo las entradas con `true`.
2. **Carpetas compartidas:** si el instalador del núcleo crea `%ProgramData%\GPOS NG`, debe usar el mismo SDDL ([OPS] 4.5) o la misma comprobación previa ([OPS] 8.5). Si no, el conector rechaza la instalación o no arranca.
3. **Decisión candidata a ADR** (A decide si la registra junto con ADR-75 y ADR-76): toda carpeta que cree el instalador de un conector, o del núcleo cuando comparte `%ProgramData%\GPOS NG`, se comprueba en el MSI antes de crearla. Alternativas descartadas:
   - rechazar solo al arrancar el servicio;
   - limpiar lo que haya;
   - una acción en PowerShell.
