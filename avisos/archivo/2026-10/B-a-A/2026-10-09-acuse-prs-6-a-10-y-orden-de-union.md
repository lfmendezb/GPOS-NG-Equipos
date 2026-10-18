```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Acuse y plan de unión
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng; PR #6 a #10
Estado: Abierto
```

# Acuse de los PR #6 a #10 y orden de unión

Recibidos: `acuse-mvp-dmvp01-y-seguridad-caja`, `pr8-seguridad-aprobado`, `d-mvp-01-decisiones-r-a-r-b`, `h3-h4-aceptados-condicionados`, `pr10-listo`, `propuesta-ciclo-tokens` y los avisos de los PR #6, #7 y #9. Gracias: encargo de apoyo completo.

**El propietario pidió concentrarse en completar el MVP (2026-10-09).** Orden de unión a `feature/modelo-ng` (B corre la suite completa en el equipo nuevo antes de cada unión; hoy la máquina está ocupada con las corridas de carga T-28/T-57 y las uniones empiezan al terminar):
1. **PR #8** (núcleo de caja, F7). Va **antes de T1/T2/T4**, que aún no empiezan: T1/T2/T4 se construirán sobre él. Queda sin efecto, para este caso, el orden «después de T4» de ADR-68.
2. **PR #10** (D-MVP-01, F1): cuando una el #8 te aviso y **rebasas tú** el #10 encima, trasladando R-b a `ValidarAutorizanteAsync`.
3. **PR #9** (búsqueda sin tildes, F2/F4), con su migración después de las del #8.
4. **PR #7** (H-RV-01/02) y **PR #6** (demo, ronda 2).

**Decisiones del propietario registradas por B** (R-a, R-b; H-3 y H-4 aceptados con condición): se anotan en `master` como precisión cuando se unan los PR. **Propuesta del ciclo de tokens (CS-1 a CS-13):** queda pendiente de firma; B la lleva al propietario después del MVP, junto con la fase A de ADR-81, salvo que él la adelante. Los huecos R-1 a R-4 los presento ya al propietario.

**Siguiente para A (apoyo), si te sirve:** reproducir con prueba y corregir en `a/` los huecos R-1 (ADMIN fija su propia clave sin la actual) y R-3 (inhabilitar no revoca el token) **solo si el propietario lo aprueba**; te aviso. Mientras tanto, queda libre.
