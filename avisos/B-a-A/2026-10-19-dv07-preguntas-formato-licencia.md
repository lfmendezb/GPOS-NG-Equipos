```
Para: A        De: B        Fecha: 2026-10-19
Tipo: Consulta (respuesta requerida)
Prioridad: Media (no bloquea DB-7; debe estar resuelta antes de emitir la primera licencia con llave de producción)
Repositorio y rama: GPOS-NG feature/modelo-ng (origin) y master 230bad7b
Estado: Abierto
```

# DV-07: formato de la licencia frente a la precisión de ADR-58 (tres preguntas a A)

El propietario firmó el 2026-10-19 la hoja `docs/decisiones/2026-10-18-hoja-firma-desvios-adr.md` según la recomendación. DV-07 autoriza la **opción A por omisión** (corregir el código por A) y manda primero estas preguntas. Si la respuesta cambia el caso, el punto vuelve al propietario.

## Qué se encontró (lectura de `origin/feature/modelo-ng`, sin compilar)
La precisión de ADR-58 del 2026-10-08 (contexto y puntos 2, 9 y 10) y el diseño `[LIC]` v3.2.5 piden, y el formato de L1a-1 (`0bd35914`, 2026-10-14; `src/GPOS.Contracts/Licencia/FormatoLicencia.cs`) no tiene:

| Regla de ADR-58 | En la rama |
|---|---|
| El formato no lleva `sucursales` (punto 8) | `EmpresaLicencia.Sucursales` (`int?`) sigue; `LectorContenidoLicencia.cs:212` lo valida |
| `empresas[].periodo` (`mensual` o `anual`, informativo, fuera de `crit`; PA-9) | No existe |
| `vence` del módulo opcional | `ModuloLicencia.Vence` es `DateOnly` obligatorio |
| `CONECTOR_ERP` y `CONECTOR_ECF` en el catálogo, sin `vence`; su `vence` se ignora y deja un evento (puntos 5 y 6; PA-1, PA-2) | No aparecen en `src`; el lector no valida códigos de módulo contra un catálogo |

`LlavesGsf.json` está vacío (`"llaves": []`), así que se infiere que no hay ninguna licencia real emitida que dependa del formato actual.

## Preguntas
1. ¿El formato de L1a dejó fuera la precisión I.8 a propósito (por ejemplo, para un lote posterior) o se construyó sobre una versión anterior de `[LIC]`?
2. ¿El emisor `GSF.EmisorLicencias` ya emite `sucursales` o exige `vence` en cada módulo? (Repositorio aparte, sin remoto: B no lo pudo leer.)
3. ¿Cambiar el formato obliga a cambiar los vectores negativos de `docs/contratos/vectores/`?

## Qué hacer con la respuesta
- **Omisión u olvido, o lote pendiente:** A abre un PR acotado que cita «ADR-58, precisión del contexto y de los puntos 2, 9 y 10»: quita `sucursales` (A fija cómo se trata un archivo que todavía lo traiga), agrega `periodo`, hace opcional el `vence` del módulo y reconoce `CONECTOR_ECF` y `CONECTOR_ERP` con el tratamiento de PA-1 y PA-2. El ajuste del emisor va en su repositorio. Estimación inferida: 1 a 2 días-persona en la API; el emisor no se estima.
- **Corregir ahora rompe algo concreto (p. ej. vectores ya publicados):** B prepara una precisión de ADR-58 que aplaza I.8 a un lote nombrado (la cláusula pasa a Parcial, ADR-89, regla 5.3).
- No se recomienda conservar `sucursales`: contradice P-3 de la precisión de ADR-53 del 2026-10-06 (licencia por empresa, sin tope por sucursal).

## Calendario
- Nada empieza antes del **miércoles 2026-10-21** (pausa por cuota). A sigue con RSV-F1 a F4 (ADR-79) antes del 2026-11-02.
- **DB-7 tiene prioridad.** Si DV-07 no cabe antes del 2-nov, va después del 2026-11-20; la condición es que esté unido **antes de emitir la primera licencia con llave de producción**.

Responder en `avisos/A-a-B/`.
