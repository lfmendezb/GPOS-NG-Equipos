```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Respuesta (PREGUNTA-1 a 4 de la revisión de seguridad del ADR-93, #134)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/revision-seguridad-adr93-2026-10-21.md`
Estado: Abierto
```

# Respuestas a la revisión de seguridad del ADR-93

Gracias por la revisión. Las PREGUNTA-1 a 4 están respondidas. S-01 a S-04 pasan a ser condiciones de construcción de E-2; S-06, S-08, S-10, S-12 y S-17 se cumplen antes de unir. Ninguna pregunta reabre el ADR.

## PREGUNTA-1 (quién escribe en el banco): respondida por el propietario el 2026-10-21 (chat)
Según la recomendación de B, **solo los ADMIN**, sin grupo local dedicado. Cargan desde la aplicación el ADMIN y el SUPER (TA-P07); los archivos dejados a mano en la carpeta los deja solo quien tenga escritura por el sistema operativo (administradores del servidor, ADR-77). Para las bases UNC del SUPER, la comprobación de DACL de ADR-77 no aplica y se documenta en operaciones (DevOps). Registrado en el PR #142.

## PREGUNTA-2 (TN-02): error del encargo
Fue un error de B al redactar el encargo: «TN-02» no es el permiso y el alcance de la foto. Lo que se pedía era la **matriz de permisos de la foto, de la subida, de la asignación masiva y de la lista de ambiguos**, que es el S-10 de ustedes. Quedó cubierto; no hay nada más que revisar.

## PREGUNTA-3 (TA-P08): respondida por el propietario el 2026-10-21 (chat)
**Es también una frontera de confidencialidad.** El usuario restringido a su sucursal no debe conocer las existencias de otras sucursales: se aplica el mismo alcance a `GET /api/inventario/existencias`, al kárdex y a la pestaña Almacenes, además de la tarjeta. Costo: 1 a 1,5 d fuera del ADR-93; B lo registra como precisión de TA-P08 y avisa al arquitecto-software. S-17 aplica a todas esas rutas (la restricción se lee en el servidor y falla cerrado: conjunto vacío, nunca «todos»). Pedimos a A la lista de rutas de inventario que hoy no filtran por sucursal.

## PREGUNTA-4 (alcance global): respondida por el propietario el 2026-10-21 (chat)
**Sí:** sin restricción por sucursal es alcance global aunque la sesión esté en una sucursal. Ya no queda como interpretación: está firmada.

Las cuatro quedaron registradas en el PR #142 (hoja de firma y ADR-93).

Respuesta requerida de A: la lista de rutas de inventario sin filtro por sucursal (S-16). Nada más.
