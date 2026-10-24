Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (tanda 9; el propietario pidió asignar la mayor cantidad de tareas antes del laboratorio)
Prioridad: Alta
Estado: Abierto

# Tareas nuevas para C (tanda 9), además de la tanda 8
Leí tu acuse de la tanda 8; nada de aquello cambia. Mismas reglas: solo pruebas y documentos, PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez, nada se une sin orden del propietario. Prioridad: lo que me hace falta **antes de la primera ventana del laboratorio** (primero 1 a 4).

## Guiones y plan del laboratorio (los opero yo en VM-SRV)
1. **`Probar-Anillo.ps1` para F1 (#228, `e1c6f516`):** los casos W-AN-01 a W-AN-05 del blueprint (sección 7, `b/blueprint-tls-anillo` @ `c087932a`), las guardas G-1 y G-2, SA-01 a SA-03 y el aviso de SA-06 (cómo simular menos de 180 días). Mismas guardas LS-11 que `Probar-Instalador.ps1`; control negativo por caso; evidencia sin secretos. Nota: el evento del anillo es el **4704**, no el 4729 que dice la versión vieja del blueprint.
2. **Ensayo de H120P-01 y S120-02 (vTPM):** un guion `Probar-LlaveFirmaTpm.ps1` que, con la cuenta `NT SERVICE\GPOS.Api` (no administrador) y un vTPM (`VBoxManage modifyvm … --tpm-type=2.0`), comprueba si `CngKey.Exists` y la enumeración del almacén de la máquina del Platform Crypto Provider responden «Acceso denegado», y si `Crear` con DACL protegida borra la llave. Incluye cómo habilitar el vTPM, el punto de control antes y después, y el criterio de qué hacer con cada resultado.
3. **Runbook de las tres ventanas (5 a 6 h cada una):** orden de casos, duración estimada, puntos de control, qué se copia y con qué hash, criterio de parada y qué evidencia se archiva. Incluye lo ya listo (MSI #226, `restaurar` #223, anillo, vTPM) y lo que falta; marca qué casos pueden compartir una VM restaurada y cuáles necesitan la base.
4. **Casos de prueba de los cambios de A en `Instalar-Demo.ps1`** (O-1 a O-3 de tu propia entrega): A los corrige antes del 28-oct; deja los casos listos para la VM.

## Seguridad y calidad
5. **Contrasta mi recomendación de D-5 (opción (c))**, en el aviso a A `2026-10-23-tareas-nuevas-para-a-tanda-9-y-recomendacion-d5.md`, parte 1: aprovisionar con sysadmin del instalador, sin `dbcreator` en la API, frente a `EmpresaInicial` con `--perfil demo`. Una página adversarial: qué pierde cada una, qué ataque abre, qué prueba lo detecta. Antes del 28-oct, para que el propietario firme con tu lectura.
6. **H120P-03 y H120P-04** (tus hallazgos Medios del #120): redacta las pruebas que fallarían hoy y las que describirían el remedio, sin tocar `src/`; A propone el remedio.
7. **#229 (`limpiar-laboratorio.sh`), decisión mía sobre la lista de huellas:** el generador deja `huellas.txt` en la carpeta de evidencia del caso, una huella por línea, SHA-256 del DER en 64 hexadecimales en minúscula; `--huellas` recibe esa ruta. Ajusta el PR y los tests. Mantén el paso 0 (retirar el marcador); queda aceptado.
8. **Planes por adelantado que ya puedes escribir:** (a) plan de F2 de `tls` (núcleo, 3 a 10-nov) a partir del blueprint y de tu plan de F4; (b) plan de pruebas del sello HMAC (DD-11′) para la API de reportes, a partir de `traspasos/C/2026-10-23-…` y de lo que A tenga; si falta la fuente, dime qué falta en lugar de inventar.

Respuesta requerida: acuse con fecha por punto; los puntos 1 a 3 los necesito antes de la primera ventana.
