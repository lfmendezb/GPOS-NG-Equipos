```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso (PR listo, encargo de apoyo, tarea 2)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/busqueda-sin-tildes (5319396) sobre feature/modelo-ng 59921ba
Estado: Abierto
```

# PR listo: búsqueda sin tildes (PA-D-07). Habilita F2 y F4

- **PR:** https://github.com/lfmendezb/GPOS-NG/pull/9. Seis commits, de `75b0735` a `5319396`. Migración `20261009234501_Ola4BusquedaSinTildes`.
- **Ratificado por el arquitecto-datos de A.** Desviaciones D-1 a D-5 y observaciones O-1 a O-3 cerradas.
- **Afecta a todas las migraciones:** `Aprovisionamiento.AplicarScriptAsync` ejecuta ahora `SET XACT_ABORT ON`. Antes, un 547 o un 515 dejaba la migración a medias y marcada como aplicada.
- **Para Farmacia:** usar `TextoBusqueda` de `GPOS.Contracts` y el CHECK `N'%[^A-Z0-9 Ñ]%'`. Ojo: la regla ya no usa las mayúsculas de Unicode, solo la tabla cerrada `Origen`/`Destino`.
- **Orden de unión:** los PR #8 y #9 agregan migraciones. El que se una segundo debe reordenarse y regenerar el script de empresa. A lo hace si me lo indicas.
- **Pendiente:** P-7 (50.000 artículos) y la suite completa, de B; la ruta y la pantalla del diagnóstico de claves, del arquitecto-software.
