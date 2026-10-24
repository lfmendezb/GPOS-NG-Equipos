```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 7 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y preguntas
Prioridad: Normal
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` @ `a3c71ce1` (leída con `git show`; sin cambios)
Estado: Abierto
```

# Plan de pruebas de PR-V (verbos `red`, `lectura` y `FaseServicios`; base de F2 de `tls`)

`traspasos/C/2026-10-24-plan-pruebas-pr-v.md`. No había plan previo (el `grep «PR-V»` en `traspasos/C`, `A` y `B` solo da menciones de pasada). La rama ya tiene buena cobertura (134 métodos de prueba en `tests/GPOS.Tests/Servidor`), así que el plan cita lo existente por nombre y se concentra en los huecos: ~60 casos con nivel, esperado y mutación, marcados como existente, a reforzar o nuevo (PV-T10 T1-10 estricta, PV-Q5 SDDL de Q-5, PV-S `FaseServicios`, PV-R `red`, PV-L fase `lectura`, PV-F base de F2 de `tls`); 15 casos de laboratorio para VM-SRV (LABP-01 a LABP-15, que cierran DE-11-verbo, DE-14-verbo, DE-15 y MI-B1/B3); requisitos de testabilidad R-1 a R-8 (~0,35 dp). No compilé ni ejecuté nada; los «hoy rojo» salen de leer código y pruebas, no de una corrida.

**Hallazgos principales**
1. **T1-10 pasa en vacío con PR-V:** busca el texto «sc create», pero el creador real es `ScObligatorio("create", …)`; la lista de creadores queda vacía y no se afirma nada. **Aunque la viera, fallaría:** exige el SDDL de Q-5 en el archivo creador y el DEMO usa el de DM-09; la prueba de A (`ServidorArquitecturaTests.cs:159`) prohíbe que `FaseServicios` nombre `ServicioProduccion`. «Estricta» = comparar valores (cuenta, argumento y privilegios, leídos del doble y del `Package.wxs` por XML) y exigir que los creadores sean exactamente dos (`SistemaServidorWindows.cs` y `Package.wxs`); las diferencias DEMO↔MSI quedan en una lista cerrada.
2. **El SDDL de Q-5 tiene 7 copias:** `SddlServicios.cs`, el literal de `ServidorArquitecturaTests`, `ApiInstaladorTests`, `Package.wxs` y 3 guiones míos (`Probar-Instalador.ps1`, `Probar-GposApiMsi.ps1`, `Get-MsiTabla.ps1`). Fuente única propuesta: `SddlServicios.ServicioProduccion`, con `PlantillaServicioDemo` derivada de ella (producción más una ACE para quien instala).
3. **La prueba actual del `.wxs` es débil:** `El_SDDL_de_produccion_es_el_del_Package_wxs_cuando_exista` hace `return` silencioso si no hay `.wxs` y, cuando lo hay, usa `Contains` sobre todo el archivo (un comentario basta). El plan pide leer el atributo `PermissionEx/@Sddl`.
4. **La recuperación del DEMO difiere de la del MSI:** el DEMO usa `restart/60000×3` y una prueba lo fija; el MSI firmó restart, restart, none. Con tres «restart» el SCM reinicia sin límite (mi L-01 del MSI).
5. **Defecto Bajo candidato:** la fase `lectura` no exige que las carpetas estén seguras antes de escribir `llave-sitio.pub` en `config\` (`servicios` sí lo exige); además hay una ventana entre la verificación de la huella y la lectura por el hijo `crear-lectura`.
6. **Otros huecos:** el aviso de puerto efímero (SPX-05) no tiene prueba; `ConfigurarServicio` nunca corrige inicio, privilegios ni tipo de SID de un servicio propio desviado; SPX-01 solo se prueba en la ruta de creación, no con la clave ya existente; `implantar-servidor` todavía imprime `e.Message` (SPX-09 se cerró solo en `red`); `ComandosServidor` es `internal` y no hay `InternalsVisibleTo`.
7. **Base de F2:** las guardas de `red` están privadas dentro de `ComandoRed` y `tls` escribirá en la misma clave; R-5 propone extraer una pieza compartida. Las pruebas que hoy fijan la decisión provisional deben llevar `Trait("Transicion","F2")`.

**Dudas (D-1 a D-11; completas en el documento)**
- A y B: D-1 ¿se alinea la recuperación del DEMO con el MSI? D-4 orden de unión de PR-V y `b/t1b-api-msi` (propongo que la parte XML de T1-10 y la prueba del `.wxs` vayan en el PR que se una segundo).
- A: D-2 ¿se comprueba el servicio ajeno antes de copiar binarios? Hoy se copia primero. D-3 ¿se agrega la precondición de carpetas a `lectura` y se cierra la ventana de la llave? D-5 ¿se extiende SPX-09 a `implantar-servidor`? D-6 ¿el evento 5139 también va cuando `red` falla sin cambios? D-7 una excepción fuera de la lista de `red` se propaga: ¿es el contrato? D-8 la huella del hijo `llave-sitio` toma la primera línea: ¿última, o exactamente una?
- B: D-9 ¿`SddlServicios.ServicioProduccion` es el lugar definitivo o va a `GPOS.Comun` para compartirlo con la acción del MSI (`net472`)? D-10 ¿`Instalar-Demo` siempre pasa `--usuario-instala` explícito? D-11 ¿prefieren que mis tres guiones lean el SDDL de un único archivo?

**Dato a verificar:** el contrato del MSI (no la hoja de firma `2026-10-23-hoja-firma-m2-217-…`, que no repite el valor del SDDL) es la fuente del SDDL de Q-5; no localicé otra hoja de firma que lo contenga.

**Siguiente paso mío:** cuando A suba el PR, escribo primero las pruebas rojas (PV-L-04, PV-S-12, PV-R-12, PV-R-13, PV-T10-02) en una rama apilada sobre él y corro las mutaciones y los LABP en VM-SRV.

Respuesta requerida: A responde D-1 y D-4 antes del 3-nov.
