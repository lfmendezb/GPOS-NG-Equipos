```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Solicitud (aprobada por el propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5 y ramas b/ de diseño; base feature/modelo-ng 0bb596c
Estado: Abierto
```

# Segundo encargo para B (aprobado por el propietario el 2026-10-08)

Según `prioridad-ventas-inventario`. **Orden:** 1 y 2 en paralelo; luego 4 y 5; el 3 cuando haya hueco. Respeta tu límite de agentes ([[limite-agentes-pc-b]]).

1. **Diseño de las ventanas de facturación por vertical, primero Duty Free** (punto 2 del encargo anterior, sigue siendo lo principal). Incorporar lo de hoy: vendedor **opcional** salvo `ExigirVendedor` por empresa (aviso `vendedor-opcional-y-calendario-a`); espera de la firma 15 s, de 3 a 60 s; constancia «pendiente de validación» (precisión de ADR-51, con VF-11); VF-06 (redondeo del vuelto por empresa); VF-13 (RI definitiva siempre impresa; reimpresión con privilegio o supervisor). Solo documentos y HTML estático; hoja de firma si hay decisiones.
2. **Correcciones de S-15 previas a unir el enganche** en `b/ola5`: S15-01, S15-02, S15-08 y S15-11, con las decisiones (a), (b) y (c) del aviso `s15-revisado-decisiones`. Solo archivos de B; el enganche en la principal sigue para la unión.
3. **Vector de ADR-77 v2 con CB-1 a CB-5** y actualización de `InstaladorVectorAdr077Tests` del conector IQ (≈ 0,07 sp); entregar con la huella nueva para que A lo publique. Incluir la prueba de la ACE no evaluable (Baja).
4. **Vistas de reportes de ventas e inventario para la API de reportes** (no aplazadas), en archivos nuevos y **sin aplicarlas al esquema**: se integran con el mecanismo de esquema de A al unir la ola 5. Nada fiscal.
5. **Plan de pruebas de ADR-118 y 119** para que A arranque el **15-oct** sin esperas: casos por tanda (T1, T2, T4), criterio p95 ≤ +5 %, y cómo resolver R-01 (28 archivos de prueba que venden sin existencia) en `BaseDatosFixture`. Documento; A lo aplica en su árbol.

**Fuera de este encargo:** A-11 (sin costos), construcción de AdmCloud y motor de formatos v2 (después del corte); reportes fiscales (aplazados).
