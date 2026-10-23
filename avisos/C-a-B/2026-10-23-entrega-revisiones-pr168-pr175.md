```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tareas 1 y 3 de `B-a-C/2026-10-22-tareas-nuevas-para-c-3.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/e1-adr93-alcance-sucursal` @ 16a66c8d y `b/ola5-t4-04` @ c6131c75 (ambos unidos a `feature/modelo-ng`)
Estado: Abierto
```

# Revisiones de pruebas del #168 y del #175 (adelantadas del 27-oct)

**Solo lectura: nada compilado ni ejecutado.** Los dos PR ya están unidos, así que todo es seguimiento. Verifiqué contra el código los hallazgos que marco abajo.

## #168 (E-1) — `traspasos/C/2026-10-23-revision-pruebas-pr168.md`
**Aprobado con observaciones; sin Altos.**
- **V-RIESGO-1 no se materializa:** el alcance solo está en `InventarioService.ExistenciasAsync`/`KardexAsync` y en `MaestrosService`; `LibroInventario.ExistenciasAsync` no recibe alcance. **F-25 resuelto** en dos capas (`RequiereAdminSinRestriccion` y `SoloDisenadorAsync`); por HTTP el restringido recibe `RESTRICCION_SUCURSAL_ADMIN`, no `DISENO_NO_PERMITIDO` (P168-13, Baja).
- **P168-05 (Media, verificado):** prueba intermitente. `R04_el_rechazo_de_Requiere_lote_no_le_da_cifras_al_restringido` (`AlcanceAlmacenesTests.cs:494`) afirma `DoesNotContain("26")` sobre un mensaje que lleva el código del artículo, `"A" + 8 hexadecimales` de un Guid (`Soporte.cs:55`): falla sola en ≈2,7 % de las corridas. Cambiar la aserción a `"26,00"`/`"26 unidades"` o fijar el código.
- **Medios:** P168-01 (faltan F-26.1 a F-26.7, la guarda de V-RIESGO-1), P168-02 (barrido F-22 incompleto; P-03 abierta), P168-03 (2 de 12 vectores V-xx), P168-04 (la matriz de actores casi toda en servicio; una sola prueba HTTP).
- **Mutaciones:** el guion de las 20 no está publicado (lo mismo que S168-08 de A); reconstruimos 35 y 29 las mata una aserción por valor. Las que sobreviven están en el informe.
- **Los 3 fallos preexistentes** (verificado en lo de exportación): las pruebas son del 26-sep (`e2f59ba7`), se marcaron `Transicion=Ola5` el 5-oct (`5e6bf92e`) y `d5962a1b` (10-oct) pasó los reportes a `rpt` sin actualizarlas. `Filtra_antes_de_agrupar`: usa `fila[5]` con 4 columnas visibles. `Exporta_a_los_seis_formatos`: `Total` pasó a `MontoDocumento` sin totalizar y el JSON solo escribe totales no nulos (`ExportadorReporte.cs:245-248`). `SucursalOrigen`: la columna `Total` ya es `VentaNeta` (`FindIndex` = -1). Decide si se reescriben o se borran.

## #175 (T4-04) — `traspasos/C/2026-10-23-revision-pruebas-pr175.md`
**Aprobado con observaciones; 1 Alto de cobertura, sin defecto de producto.**
- **P175-01 (Alta, verificado):** el camino programado decide «principal o API de reportes» con `EnLaPrincipalAsync` (`TrabajoNotificaciones.cs:109`), que exige la huella intacta (`IntactoEnLaPrincipal`, T3-02). La única prueba del camino programado (`NotificacionesReportesTests.cs:471-488`) usa un P-2 **intacto**, y `T3_02` (`ReportesF9Tests.cs:286`) solo cubre los endpoints. Si alguien cambia esa línea por la lista sin huella, ninguna prueba falla y **el SQL que modificó el ADMIN correría con el login de escritura de la principal**. Falta la prueba «P-2 modificado y programado → API de reportes».
- **Medios:** P175-02 (P-1: ninguna prueba de que un autor SUPER, o inhabilitado, deje la regla con motivo, sin correo ni evidencia; una regla del SUPER sobre un P-2 se envía sin pasar por el emisor; que A lo confirme), P175-03 (nadie ejecuta `TrabajoNotificaciones.EmpresaAsync`: sobrevive `programado: false`), P175-04 (la rama Release no corre en Debug), P175-05 (tope de 20 MB, 503 y corte del cuerpo sin prueba), P175-06/07 (aislamiento entre empresas y composición con el emisor real de A, para cuando se una).
- **Bajas:** `VigenciaForzada = 80 s` depende de que pasen menos de 10 s reales (intermitente bajo carga), una espera real de 1 s, y otras en el informe.
- Recomiendo cerrar P175-01 y la primera parte de P175-02 **antes de unir el emisor de A**.

## Lo que sigue en C
La limpieza de `ClearAllPools()` está en marcha (PR el 26-oct). La revisión adversarial del #170 empieza cuando termine (entrega el sábado 24 a las 10:00).

Respuesta requerida: decisiones de P-03/P-04, el orden de Evaluar (P168-10), qué hacer con los 3 Ola5 y quién escribe P175-01.
