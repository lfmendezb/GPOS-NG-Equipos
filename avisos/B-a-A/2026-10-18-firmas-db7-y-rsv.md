```
Para: A (copia a C)        De: B            Fecha: 2026-10-18
Tipo: Aviso (firmas del propietario y encargo)
Prioridad: Alta
Repositorio y rama: GPOS-NG; PR de RSV detrás del #73 (a/rs-anillo-sellos)
Estado: Abierto
```

# Firmadas las hojas de DB-7 y de RSV; DB-7 la construye B; el PR de RSV es de A

**Firma del propietario, 2026-10-18, en la sesión de B:**
> «Firmo según recomendación. Sobre quien realiza DB-7, entiendo que el equipo B debería asumir esta tarea por ser el equipo principal y mas estable con mayor capacidad de A y mejor estabildiad que C»

Hojas, con la firma al final: `traspasos/B/2026-10-18-propuesta-calendario-db7.md` y `traspasos/B/2026-10-18-hoja-firma-rsv-anillo-sellos.md`. B las registra en `master` (precisiones de ADR-34 a 37, 39, 41, 58, 59 y 83, y ADR-79 nuevo).

## Encargo a A: RSV-F1 a RSV-F4 (un PR detrás del #73)
- **RSV-F1 (a):** reprotección conjunta de padrón y sellos (`anillo --reproteger-sellos`), con las condiciones 1 a 8 de la sección 3.1 de la hoja y la abstracción de la fuente de sellos (para el sello por membresía de DB7-05).
- **RSV-F2 (2a) + (1):** los tres verbos (`--cambiar-recuperacion`, `--revocar-heredadas` y `--reproteger-sellos`) se niegan si un servicio `GPOS.Api` o `GPOS.Reportes` instalado no está detenido. El procedimiento (1) lo escribe devops de B.
- **RSV-F3 (a):** instantánea con más de 15 min → se reevalúa con la hora protegida; tras máx(`graciaDias`, 72 h) sin un refresco correcto → solo consulta, con eventos y aviso al SUPER.
- **RSV-F4 (a):** evento crítico `LicenciaFuenteAusente` **EventId 4723** (reservado), aviso al SUPER y reescritura desde la fila, salvo con el candado CR-01 activo. El siguiente libre es el 4724.
- **Bajas RSV-06, 08, 11 y 12:** en el mismo PR si caben (recomendado, no obligatorio).
- **Objetivo:** PR antes del **2026-11-02**. RSV-F1, F3 y F4 son condición de la **primera licencia de pago**. Hasta que se unan sigue la restricción operativa de RS-01 (a).
- Revisión de seguridad como siempre, sin migraciones si no hacen falta (si hacen falta, marca posterior a la última unida en ese momento).

## Cambio de reparto de DB-7 (DB7-06)
- La hoja proponía D0, D1 y D3 para A, y D2 y D4 para C. **Por decisión del propietario, B construye D0 a D6.** A ya no toma D0 ni D1 ni D3.
- El orden no cambia: la construcción empieza **después del #57 y del #73**; el diseño (D0) lo empieza B ahora. Punto de control el **2026-11-20**; firma de la v1 el **2026-12-11**.
- B le pedirá a A, cuando haga falta, la revisión del auditor de A sobre el diseño y sobre el código del sello por membresía, porque A es autor de SL y RN. Se avisa con tiempo; no hace falta reservar nada ahora.

## Sigue para A
1. Rebasar la cadena sobre `1768f6a3` (aviso `2026-10-18-unida-ola5-auditoria`); el #48 regenera Designer, snapshot y guion.
2. El PR de RSV detrás del #73.
