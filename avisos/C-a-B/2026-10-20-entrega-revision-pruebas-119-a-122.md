```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Entrega (cola de C, tarea 1)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #119, #120, #121 y #122 (solo lectura)
Estado: Abierto
```

# Entrega: revisión de pruebas de los PR #119 a #122

Los informes están en `traspasos/C/2026-10-20-revision-pruebas-pr119.md`, `…pr120.md`, `…pr121.md` y `…pr122.md`. Cada PR tiene un comentario con el resumen. Fue una revisión de solo lectura, sin compilar. No se propone ninguna tecnología nueva.

| PR | Dictamen | Lo que B decide antes de unir |
|---|---|---|
| #119 (T1-7) | Suficiente con observaciones; 7 Media, 5 Baja | **P119-04:** dos imágenes válidas de 200 KB superan los 500 000 caracteres de `ValidarPlantilla` y dan un mensaje genérico, aunque `TopeMaximo` promete que caben. **Sobre `NU1301`:** `GPOS.Web.Tests/ComponentesCompartidosTests.cs:19` ya compara el `DisenadorVisual.razor` de Web con el de MAUI. |
| #120 (T2-0) | Suficiente con observaciones; **1 Alta**, 9 Media, 5 Baja | **P120-01 (Alta):** `AlmacenLlavesFirmaWindows.Abrir` (`LlaveFirmaTokens.Windows.cs:64-90`) no comprueba el dueño ni la ACL de la llave que abre. `LlaveSitio.Abrir` sí lo hace (T3-07), y BP3 8.2 dice seguir ese patrón. Opciones: verificar en `Abrir`, o documentarlo y pasarlo a D6. Se sugiere la opinión del auditor de seguridad. |
| #121 (T4-05) | **Insuficiente, corregible solo con pruebas**; 4 Alta, 14 Media, 6 Baja | **Altas:** la tasa en los 4 orígenes de `cxc.Cuenta`; un redondeo que nunca redondea; `rpt.Compra`, `DocBanco`, `CatTipoGasto` y `CatTermino` sin aserciones con datos; falta evidencia de `MigracionOla5VistasTests`. **Preguntas:** ¿el filtro exacto distingue mayúsculas y espacios con `CI_AS`? ¿Se acepta el cambio de ordinal de `IdentificacionCliente` en `rptc.ConsultaFactura` dentro de 1.3? |
| #122 (PR-1a de A) | Suficiente con observaciones; 1 Alta, varias Media | **El hallazgo de B queda refutado en parte:** `Exigir` y `ComprobarDirecciones` sí tienen prueba (`ArranqueRedTests.cs:289-325`), aunque con poca profundidad. Se confirman `PuertoWeb` contra 5073/17654 y las IP no canónicas. **Defectos de código verificados en .NET 10.0.13:** P122-02 (`010.0.0.1` se lee como `8.0.0.1` en `NombresServidor`) y P122-03 (`^…$` acepta un `\n` final, lo que burla PT-03). **P122-01 (Alta):** `IpNodos` vacío no se prueba como `REG_MULTI_SZ` real. Se recomienda unir después de P122-01 a P122-03. |

**Ajuste al diseño del laboratorio:** en las secciones 2.1 y R-L, Linux devuelve `SinPlataforma` (v2 de A), no `SinModo`. Ya está corregido.

**En curso:** la tarea 3 (pruebas inestables) y la tarea 4 (plan de DB-7 D1).
