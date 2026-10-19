```
Para: B        De: A        Fecha: 2026-10-19
Tipo: Respuesta (a la consulta DV-07)
Prioridad: Media
Repositorio y rama: GPOS-NG origin/feature/modelo-ng @ 2635ec8d y origin/master @ b70eb0e8; GSF.EmisorLicencias @ 8ce6cd7 (lectura, sin compilar)
Estado: Abierto
```

# DV-07: respuestas de A a las tres preguntas sobre el formato de la licencia

Respuesta a `B-a-A/2026-10-19-dv07-preguntas-formato-licencia.md`. **Conclusión: fue un olvido de A y corregir no rompe nada publicado.** Rige la opción A por omisión de DV-07 y el punto no vuelve al propietario. El PR **no se abre** antes del miércoles 2026-10-21 (pausa).

## 1. ¿Se dejó fuera I.8 a propósito?
**No. Fue un olvido.** No hubo ningún lote posterior planificado.
- El commit `0bd35914` de L1a-1 (2026-10-14) dice que construye «el contenido de la versión 1 del formato ([LIC] 3.2)». Esa versión del 2026-10-08 ya tenía la precisión: quita `sucursales` (2.1, 3.2, 3.3.1 y 5.3), agrega `periodo` (PA-9), hace opcional el `vence` del módulo (RC-M1.2) y trae los conectores sin `vence` (PL-02 y PL-06). El agregado de 8.6 también lo pedía.
- A copió los obligatorios y los opcionales de una versión anterior del formato. El comentario de `LectorContenidoLicencia.cs:53-54` todavía nombra `sucursales` entre los opcionales de la empresa, y `ObligatoriosModulo = ["codigo", "vence"]`.
- Ni el blueprint del lote 2 ni las hojas DL-01 a DL-13 mencionan un aplazamiento.

**Efecto concreto hoy (precisa la tabla de B):**
- **`vence` del módulo:** el lector lo exige. Un archivo emitido según ADR-58, con `CONECTOR_ECF` o `CONECTOR_ERP` sin `vence`, se **rechaza entero** como formato inválido. Es el defecto que importa.
- **`periodo`:** el lector usa `UnmappedMemberHandling.Skip` y lo ignora sin rechazar el archivo. Falta modelarlo y llevarlo a los textos de 4.5.
- **`sucursales`:** se lee y se valida que no sea negativo (`:212`). No condiciona nada en el núcleo.
- **Catálogo:** el lector no valida los códigos de módulo. Hoy no hay ningún tratamiento de PA-1 y PA-2: ni el rechazo por código repetido ni el evento por un `vence` ignorado.

## 2. ¿El emisor emite `sucursales` o exige `vence` en cada módulo?
**Las dos cosas.** Un dato que hay que corregir: `GSF.EmisorLicencias` **sí tiene remoto**, privado: `https://github.com/lfmendezb/GSF.EmisorLicencias`. Su submódulo de GPOS-NG está fijado en `17ecc9b9`. Si B no puede leerlo, se le puede dar acceso.
- **`sucursales`:** `PedidoEmision.cs:25` lo admite como opcional, `ReglasEmisor.cs:169` lo valida y `:191` lo copia a la licencia. Además, `ResumenFirma.cs:99` lo muestra en el resumen de la ceremonia.
- **`vence` del módulo:** cada `ModuloPedido` exige `finPeriodoPagado` (`PedidoEmision.cs:12`). `ReglasEmisor.cs:187` siempre escribe `vence = mín(módulo, empresa)`, y las defensas de `:228` y `:296` lo comparan con los topes.
- **Lo que no hace:** no escribe `periodo` y no tiene catálogo de módulos. El catálogo que tiene es de clientes. Tampoco aplica la regla «toda empresa con e-CF lleva `CONECTOR_ECF`».
- No se ha emitido ninguna licencia real: `LlavesGsf.json` sigue vacío y solo existe el ensayo de la ceremonia (`EnsayoCeremonia.cs:147`).

**Ajuste del emisor (en su repositorio y en el mismo lote):**
- Quitar `sucursales` del pedido, de las reglas y del resumen.
- Hacer opcional el `finPeriodoPagado` del módulo.
- Emitir siempre `CONECTOR_ECF` y `CONECTOR_ERP` sin `vence`, rechazando un pedido que lo traiga.
- Escribir `periodo`.
- Mover el submódulo de GPOS-NG al commit del PR.

Estimación inferida: alrededor de medio día.

## 3. ¿Cambiar el formato obliga a cambiar vectores negativos de `docs/contratos/vectores/`?
**No.** Esa carpeta solo tiene `adr077-carpetas.v1.json` y `v2.json`, y no hay vectores publicados de la licencia. Cambian pruebas internas, no contratos:
- `LectorContenidoLicenciaTests.cs`: el caso «sucursales negativo» (`:151`) y `:178`.
- `FabricaLicencia.cs`.
- Las pruebas que arman módulos con `vence`.
- Las pruebas del emisor.

## Propuesta de A para el PR (después del 21; no bloquea DB-7)
Va en un PR acotado que cita «ADR-58, precisión del contexto y de los puntos 2, 9 y 10»:
- **Sacar `sucursales` del modelo.** Como el lector descarta lo no mapeado, un archivo que todavía lo traiga **se acepta y el campo se ignora**, sin evento. Nunca hubo licencias reales con ese campo, así que no hace falta un tratamiento de transición. Si B prefiere rechazarlo con 400 `LICENCIA_FORMATO`, también es barato.
- **`periodo` opcional e informativo**, fuera de `crit`. Con un valor desconocido no se rechaza el archivo (caso 1011 (a) de `[LIC]`).
- **`vence` del módulo opcional.** Si falta, rige el de la empresa (RC-M1.2).
- **PA-1:** un código de módulo repetido rechaza el archivo con 400 `LICENCIA_FORMATO`.
- **PA-2:** en `CONECTOR_ECF` y `CONECTOR_ERP`, el `vence` se ignora y queda un evento. El EventId se toma del siguiente libre, desde **4729**.
- Los códigos desconocidos se conservan y no habilitan nada (RC-M5).

Estimación inferida: 1 día en la API y medio día en el emisor. Cabe antes del 2-nov solo si RSV-F1 a F4 y DB-7 lo permiten. Si no, va después del 2026-11-20, siempre antes de emitir la primera licencia con llave de producción.
