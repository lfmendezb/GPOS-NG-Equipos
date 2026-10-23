# Hoja de decisión SPV-03: el manifiesto del paquete se lee sin autenticar

Para: propietario (vía B) · De: A · 2026-10-23 · Estado: **Propuesta** (la firma es del propietario)

## 1. Qué es
`implantar-servidor --fase servicios` copia los binarios del paquete a Archivos de programa y los verifica contra `manifiesto.sha256`, que se lee de la **misma carpeta** (`--origen`) que los binarios. La verificación protege contra un cambio posterior a esa lectura (DM-08, SPV-01, SPW-01), no contra uno anterior: quien pudiera escribir en la carpeta del paquete antes de ejecutar cambiaría binario y manifiesto a la vez y todo pasaría. Severidad Media, residual del DEMO (revisión de seguridad PR-V, 22 y 23-oct).

## 2. Qué cambió desde la revisión
El límite de confianza es la carpeta del paquete: el mismo atacante ya cambiaría los guiones `.ps1` que corren elevados o `GPOS.Migracion.exe`. Por eso un manifiesto firmado solo no basta. El borrador de PR-D2 (`a/pr-d2-manifiesto`) ya cumple la condición de la opción (a): en el modo de servicios `Instalar-Demo.ps1` y `Actualizar-Demo.ps1` **se niegan** si el paquete está en OneDrive, dentro del perfil del usuario o en una carpeta que escriban cuentas distintas de SYSTEM y administradores, y exigen PowerShell elevado.

## 3. Opciones
| | (a) Aceptarlo como residual del DEMO | (b) Manifiesto firmado con llave anclada |
|---|---|---|
| Qué es | Se documenta como riesgo aceptado, con la condición ya implementada: paquete en carpeta local solo de administradores | Se firma `manifiesto.sha256` y se verifica la firma con una llave pública anclada (la misma pieza del manifiesto firmado de la actualización automática) |
| Costo | 0 | Unas 0,5 dp [I]; conviene compartirlo con el *bundle* |
| Qué cubre | Manipulación por cuentas sin permisos de administrador | Manipulación del manifiesto por quien escriba en el paquete; **no** los guiones ni `GPOS.Migracion.exe` |
| Qué deja abierto | Un administrador malicioso o malware con privilegios (ya tendría el equipo) | Los guiones y el ejecutable del verbo, salvo que también se firmen |
| Alcance | Solo el DEMO (no se entrega a clientes) | Reutilizable en producción |

## 4. Recomendación de A
**(a) para el DEMO**, con estas condiciones escritas en la guía del DEMO y verificadas por el verbo (ya están en el borrador de PR-D2): extracción en carpeta protegida fuera de OneDrive y del perfil, elevación obligatoria, y el paquete del DEMO no se entrega a clientes. La opción (b) se programa con el *bundle* y la actualización automática, no antes de D4.

## 5. Qué firma el propietario
- [ ] (a) aceptado como residual del DEMO, con las condiciones de la sección 4.
- [ ] (b) manifiesto firmado antes de D4 (unas 0,5 dp).
- Fecha y firma: ____________________

La decisión no cambia el código de PR-V; solo cierra SPV-03 en la matriz de la revisión.
