```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Entrega (diseño) y preguntas para el propietario (por tu conducto)
Prioridad: Alta (fiscal)
Repositorio y rama: GPOS-NG a/h2-ncf-historico (desde e7f1f96)
Estado: Abierto
```

# H-2, H-3 y la tanda posterior: diseño de datos listo; firma antes de construir

**Diseño:** `traspasos/A/datos-h2-h3-ncf-historico-2026-10-10.md`, del arquitecto-datos de A.

**Qué propone:**
- **H-2:** rol **H** en `fiscal.Comprobante`, con `SecuenciaId` NULL y tres `CHECK`.
  - Solo vale para facturas importadas (origen I, motivo H), en borrador, y como único comprobante del documento.
  - `NcfDocumento` lee los roles O y H, así que las devoluciones y las notas llevan B04 y modifican el NCF histórico.
  - El índice único detecta solapes con secuencias.
  - Se ajustan el disparador de inmutabilidad, el de bloques y el 608.
  - El 607 ya excluye el rol H.
- **Migración `H2ComprobanteHistorico`**, después de `BitacoraLogSoloInsercion`:
  - **relleno idempotente** de lo ya importado;
  - los NCF mal formados, de otro tipo o duplicados **no** se registran: quedan en la vista `rpt.NcfHistoricoIncidencia` y en la bitácora;
  - los solapes con bloques se informan como `COLISION_FUTURA`, sin detener la migración.
- **H-3:** parámetro nuevo `conf.Parametros.FechaImplantacion`, que no existe hoy, con dos disparadores:
  - 51423: la fecha queda después de toda factura histórica y antes de la primera factura propia;
  - 51424: se rechaza una histórica con fecha igual o posterior a la de implantación.
- **H-4:** el motivo H exige origen I (51425). **H-6:** SIN_NCF exige motivo. **H-7:** un evento en el registro del servidor, sin cambio de esquema.
- **DEMO (plantilla 08):** 9.604 facturas válidas (B01 1-1.914 y B02 1-7.690, del 2025-10-01 al 2026-09-30).
  - Fecha de implantación recomendada: **01/10/2026**.
  - Los bloques del DEMO deben registrarse **desde B01 1.915 y B02 7.691**.
- **Esfuerzo (inferido):** H-2 ≈ 1,15 sp, H-3 ≈ 0,4, H-4 ≈ 0,3, H-6 ≈ 0,15 y H-7 ≈ 0,1.

**Riesgos fiscales:**
- **NCF duplicado (Crítico en una empresa real):** si GPOS ya emitió un número que usó el sistema anterior, se informa pero no se corrige solo. Es posible en un DEMO que registró B02 desde el 1 y ya vendió.
- **Colisión futura (Alta):** las ventas de ese tipo se rechazan al llegar al número histórico, hasta aplicar el remedio de P-3.
- **Vistas de la ola 5 (tuyas):** si una vista `rpt` o `rptc` lee comprobantes sin filtrar el rol, declararía NCF históricos. Proponemos una prueba de guarda.
- **B04 o E34:** una empresa que ya usa e-CF y devuelve una factura histórica B sale con B04. La DGII podría exigir E34 (inferido; para el especialista POS).
- **Pruebas existentes:** las que importan facturas históricas fallarán con 51424 si no fijan antes la fecha de implantación.

**Preguntas para el propietario.** *Recomendación entre paréntesis.* **A no construye H-2 hasta tener firmadas P-1 a P-4 y P-7, porque son fiscales.** Mientras tanto avanza H-11.
1. **P-1:** ¿se prohíbe anular una factura histórica con NCF? *(Sí: el sistema anterior probablemente ya la declaró).*
2. **P-2:** ¿se crea el parámetro de fecha de implantación? *(Sí. La primera vez lo fija el ADMIN o el SUPER; después, solo el SUPER con motivo. En las bases existentes se infiere).*
3. **P-3:** ¿cómo se remedia un bloque que se solapa con NCF históricos? *(Una acción «Saltar los NCF del sistema anterior», con motivo; el contador confirma si los huecos van al 608).*
4. **P-4:** ¿qué pasa con las facturas históricas que tienen incidencia? *(Quedan bloqueadas con 422 y se reimportan).*
5. **P-5:** ¿la fecha de implantación vale también para las CxP pendientes, los saldos iniciales y las existencias?
6. **P-6:** factura B01 o E31 sin RNC del cliente. *(Advertencia).*
7. **P-7:** reservar los números de error **51420 a 51425** para A.
8. **P-8:** el evento de H-7, ¿solo en el registro o también en la bitácora? *(Solo en el registro).*
9. **P-9:** largo mínimo del motivo de H-6.

**Para devops:** que `Instalar-Demo.ps1` fije la fecha de implantación.
