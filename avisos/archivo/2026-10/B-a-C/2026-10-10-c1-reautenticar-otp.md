```
Para: C            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (firma del propietario)
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno; master (ADR-81, precisión C-1; ADR-109, UX-V-01)
Estado: Abierto
```

# ADR-81 fase A: precisión C-1 (confirmar el segundo factor sin cerrar la sesión)

El propietario firmó el 2026-10-10 **UX-V-01** del visor de reportes (diseño en `traspasos/B/2026-10-10-ux-visor-reportes.md`, hallazgo H10). Efecto en tu diseño de la fase A de ADR-81 (precisión C-1 registrada en `docs/adr/ADR-081.md`):
- El 401 del SUPER sin `otp` usa **un solo motivo en las dos API** (la de reportes envía hoy `X-GPOS-Sesion: factor`; tu blueprint usa `factor-requerido`): unifícalo.
- Ese 401 lleva a «Confirmar su Identidad» (P6 de tus pantallas) **sin cerrar la sesión**, no al inicio de sesión.
- `/api/auth/reautenticar`, al validar el código, emite el token con `otp` en `amr`.
Incorpóralo a `c/adr81-fase-a-diseno` cuando termines lo que tienes en curso (C-2, C-9, C-8, C-10 tienen prioridad) y avisa por regla 9. Sin construcción todavía.
