```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (blueprint previo de la tarea 1: instalador con `--servicio` y firma de la `.CA.dll`) y preguntas
Prioridad: Alta (Q-1 antes del 2026-10-28; cambia el alcance de la tarea 1)
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/blueprint-tarea1-instalador-servicio-2026-10-22.md`
Estado: Abierto
```

# Blueprint previo de la tarea 1 del instalador

Solo lectura sobre `origin/feature/modelo-ng` @ b4378650 (ya con #124 y #136) y `origin/master` @ b1bc9ba8; nada compilado ni ejecutado.

## Lo que cambia el alcance
- **H-1: no existe `GPOS.Api.msi`.** Ninguna rama remota tiene `instalador/Api` ni otro MSI de la principal, de reportes ni *bundle*; el diseño del paquete único (`docs/operaciones/2026-10-19-diseno-instalador-reportes.md:95-109`) lo marca «nuevo; no existe hoy» y la hoja del tramo 4 (`:533`) lo dejaba al devops de B, fuera del calendario. Así, `ServiceInstall/@Arguments="--servicio"` **no tiene dónde ir**. Propuesta: **A construye un MSI mínimo en `instalador/Api/`** (servicio con `--servicio`, lista exacta de privilegios, recuperación, orígenes de eventos `GPOS.Api` y `GPOS.Instalacion`, raíz, `config\`, carpeta `Api\` y la acción previa; sin red, sin secretos, sin *bundle*); cabe en la excepción F-1 ya firmada («tres `.wixproj`»).
- **H-3/H-4:** firmar la `.CA.dll` en el **agente** sería código muerto mientras rija K1-02 (la acción solo se compila con `-EstacionDesarrollo`, que rechaza `-Firmar`, `construir.ps1:50,96-99`); el `Skip` (`FragmentosInstaladorTests.cs:599-606`) solo mira el guion del agente y quitarlo sin más hace fallar la prueba. La firma funciona de verdad en el MSI de la API (lleva la acción siempre); en el agente queda completa pero latente. Retirar K1-02 sigue siendo del propietario. La prueba pasa a recorrer todos los `construir.ps1` que compilan la acción, sin `Skip`.
- **H-5: no existe certificado de firma** (ADR-33: falta el nombre legal, no se ha pedido, no hay dispositivos). El PR entrega la tubería de firma y sus pruebas, más un ensayo en la VM con un certificado de laboratorio que se descarta; la primera firma real la hace el custodio cuando exista el certificado.
- **P-O1-7 con FIPS** es una prueba elevada de laboratorio: ningún agente la ejecuta. A entrega el procedimiento, el guion para la VM y la plantilla de evidencia; el técnico la corre en la VM de `LFMB` (casos .1 a .9 y F-1/F-2).
- **H-7:** la tarea 1 **no depende de PR-4** técnicamente (ni #139 ni #140 tocan `instalador/`): T1-a y T1-c se pueden adelantar. **H-8:** un servicio instalado solo con el MSI no atiende todavía: le faltan la clave JWT (o la llave del #120) y, tras T4-06, la dirección del reenvío (Q-6); L-1, L-2 y el camino de reserva del 4767 sí se prueban; L-4 en adelante necesitan PR-V.

## Diseño en pocas líneas
- **Contrato del servicio:** `Arguments` es exactamente `ModoServicioApi.ArgumentoServicio` (un solo argumento); privilegios desde `PrivilegiosDeclarados`; sin `ServiceSid`; reinicio sin comando; el MSI no arranca el servicio ni escribe su entorno (ni `urls`, ni JWT, ni reenvío).
- **Laboratorio:** L-1 bis (`ImagePath` termina en ` --servicio`), L-2 bis (los dos orígenes), L-2c (`GPOS.Api.exe --servicio` desde consola → 4767), L-2d (sin el origen, el 4767 sale igual por el camino de reserva y la reparación restaura el origen), L-2e (con un privilegio de más, el servicio no arranca).
- **Firma:** módulo compartido `instalador/Comun/Firma-Instalador.ps1` (firma interna con el *target* del `.csproj` `:56-62`, firma exterior antes del `.wixproj`, carpeta de la acción explícita, comprobación del SHA-256 de la tabla `Binary` dentro del MSI); un MSI sin firmar se llama `-SINFIRMA`. **Guarda G-PR4:** no se puede firmar `GPOS.Api.msi` mientras `ModoServicioApi.cs` contenga `FijarEscuchaPorOmision` (aplica S-01(a) sin costo).
- **Choques:** PR-4/PR-2 ninguno de archivos; T4-06 (Q-6): la dirección del reenvío la escribe PR-V, no el MSI; DEMO y PR-V comparten nombre de servicio: prueba nueva T1-10 obliga a que `sc create` use el mismo argumento, privilegios y recuperación que el MSI, el DEMO y el MSI se excluyen en un mismo equipo y el SDDL de DM-09 queda solo para el DEMO (Q-5). Capacidad de A: del 3 al 13-nov coinciden T4-06, PR-D1, el spike y el inicio de PR-V.

## Esfuerzo y fechas
**3,75 a 4,0 dp (±40 %) con el MSI; 1,75 a 2,0 sin él.** Tres PR pequeños: T1-a (firma), T1-b (MSI, apilado sobre T1-a) y T1-c (documentos y laboratorio). El 13-nov alcanza para abrir los PR; la evidencia de laboratorio depende de la ventana de la VM. A empieza T1-a y T1-c en los huecos de PR-4 y T1-b el 4-nov, si B responde Q-1 antes del 28-oct. Licencias USD 0; certificado (ADR-33): USD 120 a 620 al año (OV con token) o cerca de USD 10 al mes en la nube de Microsoft.

## Preguntas
- **B:** **Q-1 (antes del 28-oct):** ¿el MSI mínimo de la API lo construye A o el devops de B? (recomendamos A). Q-2: ¿se acepta G-PR4? Q-5: ¿SDDL explícito del objeto de servicio en producción? Q-6: ventana de la VM, quién la opera y dónde va el guion (con C). Q-8: inicio `auto` o `delayed-auto`.
- **Propietario (vía B):** Q-3: proveedor de firma (OV con token FIPS 140-3, o la nube de Microsoft si GSF es elegible). Q-4: nombre legal y solicitud del certificado (mientras tanto `Manufacturer="GSF"`). Q-7: ¿se firman solo los binarios propios?

Decisiones candidatas a ADR: precisión de ADR-33 (módulo de firma compartido, comprobación de la tabla `Binary`, nombre `-SINFIRMA`), nota de ADR-76 punto 4 (`--servicio` coherente entre el MSI y los verbos) y G-PR4 como condición de publicación de `GPOS.Api.msi`. Supuestos [I]: conducta de WiX 5.0.2, de Windows/.NET (DACL por omisión del servicio, `RegisterEventSource` sin origen, FIPS y SHA-1) y de los proveedores de firma.

Respuesta requerida: B responde Q-1 antes del 2026-10-28 y el resto de sus preguntas antes del 3-nov; Q-3, Q-4 y Q-7 al propietario.
