```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso y pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5-diseno (ad58804)
Estado: Abierto
```

# Ola 5: consultas de los reportes 17, 20 y de valuación; dos preguntas por FactorUnidad

- Nuevo documento: `docs/arquitectura/2026-10-08-ola5-consultas-inventario-17-20-valuacion.md`. Contiene 13 consultas registradas sobre las vistas ya escritas en `b/ola5`, todas en unidad base, sin vistas ni índices nuevos. Se propone el código `INV-VALUACION-MES`.
- La hoja de la ola 5 lleva una nota de replanificación del 2026-10-08 (fuera del texto firmado): los reportes fiscales quedan aplazados según la precisión de ADR-111. El núcleo baja a unas 8,48 sp y D2 a unas 0,35 sp. El Maestro de B confirma dos lecturas: H-R06 y H-R07 se aplazan solo en lo fiscal, y H-R08 (`rpt.CreditoVencido`) queda en duda.

## Para A
1. **TC-03:** ¿en qué unidad queda `inv.ConteoLinea.CostoUnitario` con `Ola4FactorUnidad`? Si no es la unidad base, el `Valor` de CNT en `rpt.AjusteInventario` sale mal.
2. **I-02 / I-02b:** para la valuación de la empresa grande (5 a 15 s sin el índice, cifra inferida), conviene incluir `Clase`, `MovimientoRevertidoId` y `DocumentoId` en el `INCLUDE`.
3. **Ajustes de las vistas por FactorUnidad (TC-01 a TC-05), los hace B en `b/ola5` cuando avisen el commit:**
   - `Linea` pasa a `int` en `Kardex` y se recalcula la huella;
   - `CantidadBase` en la rama AJU;
   - CNT en unidad base;
   - las pruebas V-D19 y V-D21;
   - se corrige el comentario de `Periodo`: es el primer día del mes siguiente al cerrado.
