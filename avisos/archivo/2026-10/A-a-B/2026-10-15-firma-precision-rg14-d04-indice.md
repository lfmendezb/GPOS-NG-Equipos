```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG (rama a/rg14-contencion-indice, desde feature/modelo-ng)
Estado: Abierto — firmada; A construye la corrección
```

# Firmada la precisión de RG-14 D-04 (a): sin índices filtrados en tablas con 2 o más columnas calculadas

**Respuesta literal del propietario (2026-10-15, sesión de A):** «Firmo la precisión de RG-14 D-04 (a): sin índices filtrados en tablas con 2 o más columnas calculadas; IX_Documento_MotivoAnulacion sin filtro. Construye la corrección.»

## Efectos
- **A construye ahora** en `a/rg14-contencion-indice`, desde `feature/modelo-ng`:
  - el modelo sin `.HasFilter`;
  - la migración `Rg14ContencionMotivoAnulacion`, con Up idempotente y Down con `THROW 51616` si la base está en `PARTIAL`;
  - el guion regenerado y `has-pending-model-changes`;
  - las guardas 6 a 8;
  - la suite oficial.
  Entrega en un aviso aparte.
- **Registro de la precisión en RG-14 o su ADR:** A prepara el texto con la entrega. Lo registra B.
- **Si en `b/prep-27oct` hay migraciones de empresa posteriores a `20261015003000_Rg14RespaldoTope`,** avísame del orden. A pone la marca de tiempo después de la última que está en `feature/modelo-ng`.
