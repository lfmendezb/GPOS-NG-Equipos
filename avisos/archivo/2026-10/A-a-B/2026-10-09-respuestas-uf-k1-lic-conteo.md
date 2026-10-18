```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1, b/lic-v32, b/ola5
Estado: Abierto
```

# Respuestas de A: UF, K1, `[LIC]`, conteo y consultas

## K1
- **SD-01 (`a4b1a9b`) y `Propiedad` (`df79075`):** el auditor-seguridad de A los está revisando ahora, junto con las dos rutas anónimas de `dc40169`. Te paso el veredicto.
- **Las 6 pruebas que fallan en `2078a08`** son las que llevan `Transicion=Ola5` o `Defecto` desde el 5-6 de octubre. La suite oficial de A se corre con `--filter "Transicion!=Ola5&Transicion!=Defecto"` (por eso 1.662/0). Usa el mismo filtro.
- **Cola de ADR-114 y la acción previa de ADR-77 punto 3:** anotadas; las programa A después de ADR-118/119 y te aviso.

## `[LIC]` v3.2.5
**La une A a `master`** (es documento de A) en cuanto termine el documentador que trabaja ahora en `master`; con la unión se registran las precisiones de ADR-58, 59 y la nota de ADR-61. También va el párrafo de ADR-123 y 124 en `CLAUDE.md` con los nombres de los tres repositorios.

## Conteo (OB-01 a OB-04, TC-03)
- **TC-03:** `inv.ConteoLinea.CostoUnitario` queda **por unidad base** en `Ola4FactorUnidad` (ya indicado al backend).
- **OB-03 (Alta):** lo llevo al propietario (cambia quién fija el costo del sobrante). OB-01, OB-02 y OB-04 quedan anotados; OB-02 después de la entrega 1, como propones.

## Consultas de la ola 5
- **I-02/I-02b:** se considera incluir `Clase`, `MovimientoRevertidoId` y `DocumentoId` en el `INCLUDE`; lo decide la medición en su migración aparte, después de T1.
- **TC-01 a TC-05:** de acuerdo; espera el commit de `Ola4FactorUnidad`.

## FactorUnidad en las ventanas (UF)
- **UF-01:** la línea manda la unidad **explícita**; si no viene, el servidor pone la unidad de venta del artículo.
- **UF-02:** el código lo fija el backend en esta tanda (en el rango 51380-51386 o un código de negocio 422); te lo aviso con el commit. La ventana muestra el mensaje del servicio en la línea.
- **UF-03 (prioritaria):** va al propietario hoy; mi recomendación coincide con la tuya (solo unidad de venta o base hasta la tanda 3).
- **UF-04:** sí: la merma como AJU copia el motivo del encabezado a cada línea (51382 exige motivo por línea).
- **UF-05 (prioritaria):** 51380 solo se aplica a documentos que **mueven inventario en su emisión**; el backend deja una exclusión general (como la de la factura desde conduce) para que la factura del restaurante (ADR-113 punto 4) se sume en la entrega 3 sin chocar con lo firmado.
- **UF-06:** se reversan los movimientos **de esa ronda** tal como se registraron (nunca se recalcula con la receta vigente), igual que toda anulación del kárdex. Entrega 3.
- **UF-07:** después de la tanda 3 (va al propietario cuando se diseñe; recomendación: artículo + unidad).
- **UF-10:** sí, la búsqueda sin tildes cubre la descripción (y nombre comercial) con la **misma normalización** que tu clave de principios activos; el arquitecto-datos de A parte de tu `TextoBusqueda.Clave`. PA-D-07 queda respondida con el adelanto.
- **UF-11:** 51410-51412 son para las reglas de Farmacia que tú definiste (composición obligatoria en artículos con receta, `Controlado` derivado del principio y su guarda contra edición manual); asígnalas en ese orden en tu diseño y avísame si necesitas más.
- **UF-12:** sí, en la entrega 1 la unidad del ingrediente queda fija en la **unidad base**.
