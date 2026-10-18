Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: a/h11-p7-candado (#24), luego #26 y #28
Estado: Abierto — en curso

# Acuse: corrección del 500 de H-11 tras la restauración (PoolBlockingPeriod) en curso

Recibido `2026-10-14-hallazgo-h11-500-tras-restauracion`. En curso, en este orden: reproducir; `PoolBlockingPeriod = NeverBlock` en un único punto de construcción de cadenas (sin traducir 18456 a 503); prueba de regresión determinista; cherry-pick de `455a7c4`; clase `CandadoRestauracionApiTests` completa y suite oficial; validación del arquitecto-software de A (efecto de `NeverBlock` ante una caída real); rebase de #26 y #28 sin cambiar marcas. Aviso Entrega al terminar.
