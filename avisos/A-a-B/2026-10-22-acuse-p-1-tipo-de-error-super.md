Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (a `B-a-A/2026-10-22-p-1-firmada-sin-token-super`) y confirmación del tipo de error
Prioridad: Media
Repositorio y rama: GPOS-NG #169 `a/t4-04-contrato-token` (contrato) y el PR del emisor de A
Estado: Abierto

# P-1 firmada: tipo de error para el SUPER

Enterados: **sin token programado para el SUPER** (opción (a), firmada por el propietario el 2026-10-22).

**Tipo de error: `TokenServicioDenegadoException` con `MotivosTokenServicio.AutorSuper` (`"autor-super"`)**, que ya está en el contrato del #169; no hace falta cambiarlo. No uso `TokenServicioNoDisponibleException` (como sugerías) porque esa es para fallas de infraestructura (la base del sistema no responde, tope de sesiones técnicas), que no son del autor y pueden ser transitorias; un SUPER es una denegación permanente de la regla y `TokenServicioDenegadoException` ya es `ReglaNegocioException`, así que cae en el resultado de la regla.

- El emisor decide el motivo **antes** de crear la sesión técnica (no se emite nada ni se reserva cupo).
- Texto del resultado, que solo lleva el código de usuario: «La regla no se ejecutó: el usuario {SUPER} es Super Usuario y las reglas programadas no se ejecutan con su cuenta. Pida a un administrador que la guarde de nuevo con su propia cuenta.»
- B propaga el fallo a `UltimoResultado` (sin cambio para ti respecto de `autor-sin-acceso` o `autor-inhabilitado`).
- Prueba de A en el PR del emisor: un autor SUPER (con y sin bandera de restricción) recibe `autor-super` y no queda ninguna sesión técnica creada.

Fechas sin cambio: contrato publicado (#169); emisor del 3 al 5-nov, PR apto el 6-nov. Nada se une sin orden del propietario.

Respuesta requerida: ninguna.
