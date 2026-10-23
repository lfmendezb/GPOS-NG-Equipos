```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 2 de `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`) y preguntas
Prioridad: Alta (P-D2-01 conviene corregirlo antes del 16-nov)
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` @ `cd44043c` (leída con `git show`; sin cambios)
Estado: Abierto
```

# Entrega: casos de laboratorio de PR-D2

Adelantada (acuse: 30-oct). `traspasos/C/2026-10-23-casos-laboratorio-pr-d2.md`: 31 casos LAB en cuatro bloques (LAB-RS-01 a 11: fase `restaurar`; LAB-RV-01 a 07: `Revertir-Actualizacion.ps1` con servicios; LAB-EM-01 a 07: creación de la empresa como GSF con `dbcreator`; LAB-CU-01 a 06: cuentas iniciales con el anillo F1), cada uno con control negativo (sin control no hay `Cumple`), tres sesiones (S6 ≈ 6 h, S7 ≈ 5 h, S8 ≈ 6 h) y la lista de revisión de evidencia (secciones F a I). Nada se ejecutó; EM y CU son [?] o [I] hasta que existan el paso de empresa y F1.

**Tres niveles de montaje:** `Instalar-Demo.ps1` en modo servicios termina a propósito con «BORRADOR» (`:167`) antes de escribir `instalacion.json`, así que `Actualizar` y `Revertir` no corren sin él. Nivel V (RS): `--fase carpetas`/`servicios` a mano con dos paquetes, sin SQL ni anillo; posible desde el 16-nov. Nivel G (RV): espera el instalador de A (5 al 9-nov) y F1. Nivel A (EM, CU): además anillo y servicios `Running`.

**Hallazgos por lectura:** **P-D2-01 (Media; Alta si el ciclo es uso normal):** encadenar actualizar, revertir, actualizar, revertir deja la segunda actualización sin `HuellaCopiaPrevia`; `Actualizar-Demo.ps1` avisa «no cambió los binarios» aunque sí cambiaron, y la segunda reversión restaura solo las bases (es el ciclo de LAB-RV-06). P-D2-02/03: `.aplicando` no impide `Start-Service` (R-04 (a)) y `Revertir` no llama a `comprobar-servidor` (R-09). P-D2-04: R-03 solo cubre `destino\api` y `destino\reportes`; un reanálisis o vínculo físico en el subárbol no se detecta (LAB-RS-05f/05g). **Riesgo de diseño en EM:** una base creada por un login con `dbcreator` queda con ese dueño, lo que choca con RG-14 (51606) y con el plan (dueño `sa`); y `lectura` corre antes de crear la empresa, así que probablemente no tiene cuenta de lectura para reportes (LAB-EM-06).

**Dudas (D-1 a D-11):** B: D-1 (quién construye PQ-A, PQ-B, PQ-B2 y PQ-C y desde qué commit; rige la restricción de no publicar un DEMO de `feature/modelo-ng` desde T4-06), D-2 (¿`GPOS.Reportes.Api.exe` a mano sin SQL se queda vivo?), D-7, D-9 (tres ventanas entre el 16 y el 27-nov y quién teclea), D-11 (herramientas de laboratorio, ≈ 0,2 dp). A: D-4 (confirmar P-D2-01), D-5 (quién concede `dbcreator` y cómo evitar que el login quede dueño), D-6, D-8 (si R-04 (a) y R-09 van antes de la VM). A auditor-seguridad: D-3, D-10, revisar RS-05 y CU-05.

Respuesta requerida: D-1 y D-9 de B; D-4 de A antes del 13-nov.
