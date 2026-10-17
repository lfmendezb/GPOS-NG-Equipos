---
name: traspaso-b-2026-10-15
description: Cambio de sesión de B el 2026-10-15 (contexto lleno) — leer primero traspasos/B/2026-10-15-traspaso-B-cambio-de-sesion.md del área común
metadata:
  type: project
---

El 2026-10-15 la sesión de B en LFMB se cerró por contexto lleno. El traspaso completo está en el área común: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-15-traspaso-B-cambio-de-sesion.md`.

**Estado clave al cerrar:**
- `feature/modelo-ng` en **`ce33b2a8`** (15-oct, noche; #44 y DEMO desde la punta unidos; antes 65d4324f y fb32b26b) (15-oct, tarde): #24 a #42 de A unidos y A-N3 de B. Sin licencia cargada el cupo es 0: el DEMO se actualiza desde una rama anterior al #42 hasta tener `s1`; el DEMO se publica con `-Destino Demo`.
- `b/prep-27oct` (T1 de ADR-118/119, ola 3b y #38) **rehecha sobre `7898beeb` el 15-oct → `855ea392`** (respaldo `b/prep-27oct-antes-rebase-15oct`); Mvp 24/24 en las dos instancias; falta la suite oficial completa.
- **Firmas del 15-oct:** el propietario aprobó según la recomendación las DL de licencia pendientes (DL-01 a 05, 09, 11, 12, 15, 16, 18 a 22 con 2 min, C-1, C-5, P v2.2-v2.4); siguen C-3, C-2/C-4, AP-04, fecha de compra de DL-12 y custodio suplente. A debe pasar la hoja a v2.13.
- **T6 segunda tanda + suite oficial: guion listo `Solucion GPOS NGMedicion-T6-r2.ps1`** (base `GPOS-B-carga` en fb32b26b con RendimientoNegativosTests.cs copiado sin confirmar; candidato `GPOS-B-prep27` = b/prep-27oct 3988078c; los dos compilados en Release; 3 rondas T-28/T-57/N6-02 intercaladas, 15 min de enfriamiento, N6-03 y la suite al final, unas 8 h). **Se lanza solo cuando el propietario avise que la máquina queda sola y conectada.**
- **Unión del 27-oct**: T1 y la 3b, así F10 cuenta.
- **A-N2** construida por B y unida a `b/prep-27oct` (`799a5add`, migración `Uf05ForceSeek 20261015142020`, prueba `Uf05PlanTests`). **A-N3** la hace B en `b/devops-publicacion` (árbol `GPOS-B-devops`, agente devops). Ojo: la base de prueba sale del guion embebido; no escribir archivos con `git show >` (deja LF y cambia el snapshot).

**Why:** que la sesión nueva no repita trabajo ni pierda decisiones.

**How to apply:** al abrir, en la carpeta `GPOS NG`:
1. leer el traspaso, `estado.md` y los avisos abiertos;
2. seguir la regla de marcas ([[marcas-migraciones-orden-de-union]]) y las reglas de los equipos ([[dos-equipos-a-coordina]]).

**Estado al 2026-10-16, 05:35 (corte de luz):** T6 segunda tanda hecha (T-28 y T-57 verdes; N6-02 1,137, NO cumple; informe `traspasos/B/2026-10-16-t6-segunda-tanda.md`). A-N2 completado en `b/prep-27oct` `3b04495f` (DISABLE_OPTIMIZED_NESTED_LOOP; T-28 Correcto). Tercera tanda (`Medicion-T6-r3.ps1`: 2 rondas de T-57 y N6-02) interrumpida por batería tras t57-r1 base y cand: repetirla con la máquina conectada y sola; si N6-02 se confirma, perfilar el costo por renglón de T1. Encargado a A: autorización propia (SEG-CORP-08). ADR-85 a 88 en master `229fbd45`.
**2026-10-16, 11:40:** la tercera tanda diurna (08:28) salió degradada y volvió a cortarse por batería: descartada. Decisión del propietario: repetirla **de noche, con la máquina sola y la luz estable, cuando él avise**; sin análisis del costo por renglón de T1 hasta entonces. `Medicion-T6-r3.ps1` ya registra la carga de CPU (WMI) y los 3 procesos más activos.
