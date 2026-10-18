```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (respuestas del propietario, puntos 29 a 31)
Estado: Abierto
```

# Decisiones del propietario sobre costos y existencias negativas (núcleo de A)

El propietario respondió el 2026-10-08 las preguntas de la opinión contable (aviso `opinion-costos-negativos-y-defecto-lote`). Tocan el núcleo de inventario de A.

## Existencias negativas: tres niveles (CO-04, aprobado)
1. **Empresa,** por omisión: **no se permiten negativos.**
2. **Grupo de artículos** (categoría, familia o clase): los artículos nuevos heredan la regla de su grupo.
3. **Artículo:** solo para excepciones.

**Gana el nivel más específico.** Los cambios masivos se hacen por filtro o con la plantilla de importación.

**Casos fijos:** los lotes de Duty Free, los lotes con vencimiento y los números de serie **nunca** admiten negativos. Esto incluye corregir el defecto de la existencia por lote (`ConsultasInventario.cs:37-47`).

**Hoy:** `PermiteNegativa` existe por artículo y los negativos se permiten por omisión en la empresa (`Empresa.cs:45`, `CfgConfiguracion.cs:111`). Hay que agregar los niveles de empresa y de grupo, y el valor por omisión pasa a «no». Qué pasa con las empresas existentes (todas de desarrollo) lo decide el diseño.

## Interruptor sin costos (A-11)
- **CO-02:** el costo de apertura al encender o reencender el cálculo se registra con **una entrada o un ajuste con costos**. El valor lo decide la contabilidad del cliente; puede ser el del ERP.
- **CO-03:** el cálculo de costos lo enciende y lo apaga el SUPER, con motivo.
- **Condiciones para encender** (punto 28): sin existencias negativas y con una fecha de corte para el recálculo.
- **CO-05:** con el cálculo apagado no hay control de venta por debajo del costo.
- **CO-06:** **un restaurante con recetas no puede usar la opción sin costos.**
- **CO-07:** un promedio calculado con costo cero no sirve. Por eso hace falta la apertura con costo.

## Salidas no facturadas hacia el ERP (CO-01)
Por ahora se registran a mano en AdmCloud, con un **conduce de despacho y una nota de justificación**. El envío automático va en una entrega posterior.

## Factura en el conector (punto 29, también en ADR-116, `master` `12d326c`)
- **Bandera de descuadre:** se resuelve en el ERP. Si se firma allí, GPOS NG consulta el estado y se actualiza; si se anula en el ERP, también se anula en GPOS NG.
- **Rechazo de AdmCloud** (sin GUID): queda con una bandera de advertencia y no se puede firmar.
- **Ventana administrativa:** muestra las facturas sincronizadas con AdmCloud y su estado.
