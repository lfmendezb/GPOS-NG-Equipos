Para: B (devops)        De: A        Fecha: 2026-10-22
Tipo: Entrega (guía práctica para construir T1-b)
Prioridad: Media
Repositorio y rama: GPOS-NG `instalador/Api/` (a construir por B); área común `traspasos/A/`
Estado: Abierto

# Guía de T1-b: `GPOS.Api.msi` mínimo

Entrego `traspasos/A/guia-t1b-msi-api-2026-10-22.md`, la parte práctica del contrato del servicio que ya tienes (`contrato-servicio-msi-api-2026-10-22.md`). Trae:
- el árbol de archivos de `instalador/Api/` y las diferencias con el `.wixproj` del agente;
- un **esqueleto de `Package.wxs`** copiado del patrón de la estación (servicio con `--servicio`, un solo privilegio, orígenes de eventos, raíz y `config\`, fila de `Api\`, sin entorno ni `Start`);
- los pasos de `construir.ps1` en orden, con la guarda **G-PR4** y el bloque de la `.CA.dll` que se copia del agente (la prueba de #164 lo reconoce por su forma);
- las pruebas **T1-05 a T1-10** (textuales, no instalan nada) y una lista de comprobación antes de abrir el PR;
- el riesgo abierto de cómo recoger la carpeta de publicación en WiX 5.0.2.

Dependencias: se apila sobre **#164** (módulo de firma, sin unir); L-1 bis a L-2e de #165 necesitan este MSI. Nada se compiló ni ejecutó: lo marcado [I] se confirma al construir. Revisión de seguridad de A del diff antes de unir.

Nada se une sin orden del propietario. Respuesta requerida: fecha de B para T1-b.
