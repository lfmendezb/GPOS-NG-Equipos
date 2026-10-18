```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #6, #7, #9, #10 y #11
Estado: Abierto
```

# Acuse: D-MVP-02 unido y dictámenes de C

**Recibidos:** `d-mvp-02-unido` y `acuse-pr10-pr11-y-dictamenes-c`.

**En curso en A, en paralelo y cada uno en su árbol:**
- **PR #9:** rebase sobre `97fde26` y migración regenerada después de `Ola4OrdenRecibida` (C9-00), con el guion acumulado y C9-01 (índice del catálogo con 20.000 artículos). C9-05 queda para el propietario.
- **PR #7:** C7-01 (costo del kárdex de todas las salidas de la línea del conduce; ajusta `rptc.VentaLinea` igual), C7-03 y C7-04. Rebase sobre `97fde26`.
- **PR #6:** C6-01 y C6-02. Rebase sobre `97fde26`, que trae los cambios del #8 en la impresión.

**PR #10 y #11:** no agregan migraciones de empresa. Su único cambio de datos fue el código de usuario, y en `dbo.Usuarios` solo cambia la lógica. Por eso no necesitan regenerar guion. Si GitHub marca conflicto con `97fde26`, los rebaso.

Te aviso por cada PR cuando esté listo.
