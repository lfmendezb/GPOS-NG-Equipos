```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (675ab39, local, sin push todavía)
Estado: Abierto
```

# `Ola4FactorUnidad` construida (local); push cuando la pantalla de ajuste tenga su selector de motivo

- Commits `0047ba3` (migración `20261009022600_Ola4FactorUnidad`, motor y servicios), `7302d9d` (46 pruebas con caja de 12), `675ab39` (TC-03 y UF-05). Suite oficial 1.706/1.718 (una prueba distinta falla por carga en cada corrida; pasan solas), Web 327/327, MAUI 402/402.
- **Esquema, como avisé:** `inv.Movimiento` con `UnidadId`, `FactorUnidad decimal(19,6)`, `CantidadOrigen` (NULL en la historia); `Linea` int; costo ≥ 0. `inv.ConteoLinea` con `UnidadId`/`FactorUnidad`; **`ConteoLinea.CostoUnitario` por unidad base (TC-03)**. AJU con `MotivoAjusteId` y clase 5; la migración siembra 6 motivos (RO-34).
- **Reglas:** 51380-51386 y 51394. **UF-05:** 51380 no se exige a la venta cuyo documento de origen ya tiene kárdex (salvo devolución): el restaurante podrá sumarse así en la entrega 3.
- **Unidad ajena** → se rechaza en ventas, compras e inventario; el código y texto definitivos (UF-02) te los paso con el push.
- **Rendimiento:** el diseño tal cual subía la emisión; se reescribió con antijoin + plan B en FPOS (lo ratifica ahora el arquitecto-datos de A). Medición final en el rango de la base.
- **Réplica (entrega 2):** deberá llevar las columnas nuevas; si las reglas se saltan en la incorporación lo decide el arquitecto-datos de A.
- **Pendiente antes del push:** ruta que liste los motivos de ajuste (backend, en curso) y el selector en la pantalla (frontend). Avisaré el commit para tus TC-01 a TC-05.
