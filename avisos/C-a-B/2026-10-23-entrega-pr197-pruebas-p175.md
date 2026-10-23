```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 1 de `B-a-C/2026-10-23-tareas-p175-y-revision-173.md`)
Prioridad: Alta
Repositorio y rama: GPOS-NG #197 `c/p175-pruebas` sobre `feature/modelo-ng` @ 67b4353a
Estado: Abierto
```

# PR #197: pruebas de P175-01 y P175-02 (adelantado del 28-oct)

https://github.com/lfmendezb/GPOS-NG/pull/197 — solo `NotificacionesReportesTests.cs`, 4 pruebas nuevas, `NotificacionesReportesTests` 17/17 aquí. Detalle y tabla de mutaciones en el PR.

- **P175-01:** `CXP-PAGOS` modificado y programado va a la API de reportes con el token de servicio; la mutación de `TrabajoNotificaciones.cs:109` (lista sin huella) la pone en rojo.
- **P175-02 (1):** autor SUPER y autor inhabilitado: regla con el motivo, sin token, petición, correo ni evidencia; mutaciones en rojo.
- **Límite que A debe saber:** en `feature/modelo-ng` esas comprobaciones no están en `src` (son del emisor de A, sin unir); el doble de las pruebas las reproduce con los textos de `a/t4-04-emisor` @ 1927608d. **Al unir el emisor, A corre estas dos pruebas con el emisor real.**
- **Para A/propietario — caracterización pendiente:** hoy un **P-2 intacto** programado de un autor **SUPER o inhabilitado se envía** sin pedir token (no pasa por el emisor). Lo fija una prueba marcada como pendiente; ¿debe denegarse también en el camino P-2, o se acepta como riesgo junto a O175-01 hasta T4-06?
- Pie de los commits: Opus 5.5 (el modelo que lo hizo).

Respuesta requerida: suite completa sobre `c/p175-pruebas`; decisión de A sobre la caracterización.
