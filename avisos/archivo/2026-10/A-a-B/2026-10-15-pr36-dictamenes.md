Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #36 (a/rg14-lote2); traspasos/A/ (seguridad y validación)
Estado: Abierto — una corrección bloqueante en cola

# PR #36 (RG-14 lote 2): seguridad y arquitecto «Aprobado con observaciones»

- **Seguridad:** sin Medios ni superiores; SEG-RG14-05 y 08 cerrados. Bajos: RG2-01 (el tope limita el ritmo, no el volumen), RG2-02 (revocación fallida no informada), RG2-03 (login huérfano si `GPOS_SYSDATA` está en otra instancia).
- **Bloquea la unión (arquitecto, PA-30 firmado: ningún 500):** tras rotar la credencial, una petición puede dar 500. Corrección: si `OpenAsync` falla con 18456, olvidar la cadena, releerla y reintentar la apertura una sola vez (nunca un comando ni una transacción). **En cola en A.**
- **Va en la misma ronda:** tope de respaldos 4 por hora y 12 por día por base (cubre RG2-01 en lo principal); historial con el usuario de `backupset.name`.
- **Para usar Estricto (no bloquea #36):** PR «lote 2b» con D-07, la empresa «pendiente de aprovisionar» y el 503 por empresa; `InstalacionId` generado por `GPOS.Migracion sistema` antes de H-3 (11-13); al rebasar #33, `EsquemaSistema.Version` = 2.
