```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG master (180024d)
Estado: Abierto
```

# `[LIC]` v3.2.5 unida a master; ADR-078; revisión rpt/rptc y UX (para tu conocimiento)

- **`b/lic-v32` unida a `master`** en `bece8ef`; precisiones de ADR-58 (punto 0 y PL-01), ADR-59 (PL-07, NV-07) y nota de ADR-61 (PA-12) en `180024d`. Abiertas, técnicas: PA-3, PA-4 y PA-6 (Maestro de A y sincronizador).
- **`CLAUDE.md`:** ADR-123 y 124 con tu texto y los tres repositorios de conectores (`GPOS-NG-AddOn-Kit`, `-IQS`, `-Polaris`).
- **ADR-078** «Factor de unidad y auditoría del kárdex» en `master` (`be2f7b5`); redondeo del vuelto VF-06/VF-19 registrado como precisión de **ADR-16** (nota inferida en ADR-17 sobre el efectivo esperado con vuelto redondeado, por confirmar).
- **Revisión `rpt`/`rptc` del auditor de A** (`traspasos/A/revision-rpt-rptc-sensibles-2026-10-09.md`): **no publicar la 1.0 todavía**. RS-01 (Alta): seis columnas de seis vistas `rpt` muestran cédula y pasaporte completos (`VentaDocumento` ×2, `Cotizacion`, `ConsultaFactura`, `CatCliente`, `CatSuplidor`); RS-02: el cuadre de caja (esperado, declarado, contado, diferencia) a `rptc`; RS-03: privilegio por vista en el contrato; RS-07: la lista del LEEME omite tres vistas. **Los privilegios nuevos y el alcance van a firma del propietario hoy**; espera su decisión antes de corregir (te aviso).
- **UX de A** (`traspasos/A/ux-equivalencias-reimpresion-kardex-2026-10-09.md`): equivalencias, reimpresión («COPIA n», diálogo del 422 con dos parámetros nuevos en `DialogoAutorizacionSupervisor`), kárdex en unidad base y conteo con unidad. Pendiente de firma (UX-1 a UX-11). Tus ventanas pueden alinearse con el diálogo de reimpresión. Hallazgo: `gpos.imprimirDirecto` (`gpos.js:477`) abre ventana ante un 422; lo corrige A en la tanda de núcleo de caja.
