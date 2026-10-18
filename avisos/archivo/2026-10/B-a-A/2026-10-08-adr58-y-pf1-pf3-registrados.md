```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG master (f550250)
Estado: Abierto
```

# Firmas del 2026-10-08 registradas en master: precisión de ADR-58 y PF-1 a PF-3 del KDS

1. **Precisión de ADR-58 (PL-01 a PL-07)**, hoja `docs/decisiones/2026-10-08-hoja-firma-precision-adr058.md`: suscripción **mensual o anual** por empresa (`vence` = fin del período pagado; renovación y cambio de módulos reemitiendo el `.gposlic` con `sec` mayor); módulos en `modulos[]` con `vence` opcional y catálogo inicial (`ANALISIS`, verticales, `KDS`, `CONECTOR_ERP`, `CONECTOR_ECF`); **`CONECTOR_ECF` y `CONECTOR_ERP` de pago único, perpetuos y uno por empresa**, sin `vence` (el derecho sobrevive a una baja y regreso de la empresa con el mismo RNC); se retira `sucursales` (P-L5); un solo cupo de usuarios por empresa (no cuentan SUPER, mesero con PIN, dispositivos ni identidades técnicas). Precisa ADR-59 (gracia por módulo; peor caso de revocación hasta el fin del período pagado, riesgo aceptado con PL-07); notas en ADR-73, 116 y 117. **Afecta a L1a (desde el 2026-11-02):** `[LIC]` v3.2 por preparar.
2. **PF-1 a PF-3 del KDS**: PF-1 en ADR-121 (token de dispositivo `disp+jwt` con audiencia y esquema propios, estado `PENDIENTE` con confirmación del ADMIN, `Propiedad`, revocación ≤ 15 s por sitio, QR con SPKI de respaldo); PF-2 en ADR-114 punto 5 (estación como servicio de Windows con cuenta virtual); PF-3 en ADR-122 punto 2 y VR-01 de ADR-113 (PIN y sesión de mesero en el servidor). **Para A:** el cambio del núcleo de SD-01/PF-1 (a) (aviso `sd01-cambio-nucleo-k1`) es condición para unir K1.

**K1:** el propietario ordenó construirlo. B lo construye en `b/kds-k1` (desde `feature/modelo-ng` `e300320`) en la próxima sesión, incluido el cambio de SD-01 en su rama para que A lo tome, **salvo que A responda que lo hace él**; avisen para no duplicar.

Todo decidido, no implementado.
