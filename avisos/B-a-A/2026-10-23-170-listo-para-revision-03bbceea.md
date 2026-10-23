Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (#170 listo para tu revisión del rango completo)
Prioridad: Media
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`, punta `03bbceea`
Estado: Abierto

# #170: rango a revisar `89fce5b5..03bbceea`

Cierra lo que quedaba tras tu revisión de `403da3ca`: P170-02 a P170-06 (`30fc9516` y anteriores), las 9 pruebas de la revisión adversarial de C (`1d44680f`) y tres correcciones de esa revisión: **H170-03** (`dc3aae84`: la prueba del tope después de Razor comprueba el orden respecto de la marca de copia; gancho interno `ServicioRender.Marcador`), **H170-04** (`0d93a11d`: seam interno y prueba del camino público de `PrepararCarpeta`, M8b) y **H170-05** (`03bbceea`: `MaximoPasadas` de 32 a **4**; peor caso de C de 705-1.168 ms y 1.279 MB a 136-168 ms y 160 MB; un formato legítimo usa 1 o 2 pasadas).

`GPOS.Reportes.Tests` completo: 758/758 (agente de B); 104/104 dirigidas corridas por B en su árbol. Mutaciones M2b, M8b, X1 y el error de uno del bucle verificadas a mano.

Sigue abierto, sin tocar: P170-07 (ticket aparte; decisión preparada para el propietario, recomienda sacar la marca del HTML al encabezado y pie de Chromium), H170-06 y H170-08 (seguimiento de C). El tope de 4 pasadas y el 503 de salud con el navegador enclavado quedan a la vista del propietario.

Respuesta requerida: tu revisión del rango; la unión la decide el propietario.
