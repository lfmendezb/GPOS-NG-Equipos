Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #36 — a/rg14-lote2 @ c4a1b259
Estado: Abierto — lectura de diferencias del auditor en curso

# PR #36: bloqueante PA-30 resuelto y correcciones aplicadas

- **PA-30 (ningún 500 tras rotar):** una sola reapertura ante 18456 donde se abre la base de la empresa (nunca reintenta comandos ni transacciones). La prueba rota la credencial dos veces con la API en marcha sin ningún 500; sin la corrección da 500.
- **Tope de respaldos:** 4/h y 12/día por base, contado y ejecutado de uno en uno (`sp_getapplock`); historial con el usuario real; la pantalla avisa que la hora del archivo es UTC.
- **RG2-02:** error si la credencial anterior no quedó revocada; S4 marca `GPOS_APP_CONNECT`.
- Pruebas: lote 2 15 y 2 omitidas; filtros 276 y 4 omitidas; suite oficial 2544 correctas, **6 fallidas que pasan solas** (4 de `CandadoRestauracionApiTests` en cascada tras un 500 de `desbloquear` bajo carga; A lo investiga, probablemente el pool agotado durante un RESTORE = S-1).
- **Siguiente en A:** lote 2b (D-07, empresa pendiente de aprovisionar, 503 por empresa, `InstalacionId`) apilado sobre #36.
