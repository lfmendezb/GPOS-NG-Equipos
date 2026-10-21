```
Para: B        De: C            Fecha: 2026-10-20
Tipo: Entrega (cola de C, tarea 4)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C (leído contra feature/modelo-ng @ b8f166db)
Estado: Abierto (P-1 a P-9 para B antes del 2026-11-02)
```

# Entrega: plan de pruebas de DB-7 D1 (T1-1 a T1-4)

El plan está en `traspasos/C/2026-10-20-plan-pruebas-db7-d1.md`. Es solo un documento: no se compiló ni se ejecutó nada.

## Contenido
- **205 pruebas nuevas**, con su clase y método exactos: 76 de T1-1, 34 de T1-2, 65 de T1-3 y 30 de T1-4.
- **13 cambios en pruebas que ya existen**, con archivo y línea.
- Cada prueba lleva su tipo, su orden y por qué falla hoy, o qué mutante debe romperla.
- **Q3-P (7.1):** el plan incluye una prueba de la prueba que corre el texto defectuoso de la revisión 1 y demuestra que antes no salía el 409 `ULTIMO_ADMIN`.
- **Q13 (7.2):** dos pruebas fijan con SQL Server real la premisa de `OUTPUT … INTO` y del error 334, que hoy es inferida. Siguen 24 pruebas de consistencia y concurrencia, incluida la del orden de bloqueos (el padrón antes que `Usuarios`).
- **PF25 y PF43** se reescriben con eventos del catálogo (4.2 y 4.3).
- **Las pruebas de `Version == 5`** son 8 líneas en 2 archivos (4.1). Se propone comparar con `EsquemaSistema.Version`.

## Lo que DAT-D1 y RSW-D1 no dicen
1. Las pruebas que fijan la versión 5 son ocho, no dos.
2. `PF46_el_catalogo_incluye_la_licencia_y_el_sello` (`BitacoraSeguridadTests.cs:64-65`) se rompe al agregar `IDENTIFICACION_FALLIDA`.
3. `Con_AdministradaPorSuper_no_hay_409` y `Con_D7A_aplicado_EF_guarda_Usuarios` pasan en vacío, así que se proponen como pares.
4. Con la clave foránea del catálogo, los casos «sin catálogo» ya no se preparan con un `INSERT`.
5. Las constantes de `Consultas/Sistema/Acceso/` no pueden llevar `[ConsultaRegistrada]`.
6. Un resumen de más de 2 000 caracteres cortado a mano choca con `CK_BitacoraSeguridad_Json`.

## Preguntas para B (sección 12)
P-1 a P-9: el reverso de D7-A, la membresía en `BAJA`, `ULTIMO_ADMIN` en la ruta del SUPER, el evento 4733 en T1-1, el reintento ante 1205, los `CHECK` con mayúsculas, la tabla 5.1 (faltan eventos y el conteo no coincide), el gancho para inyectar fallos y la versión al guardar sin cambios. **P-2, P-3 y P-8 cambian pruebas de riesgo.**

No se propone ninguna tecnología nueva. Solo se agrega el campo `Size` a `ComandosSql`, sin cambiar lo que ya existe.
