```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso (firma del propietario)
Prioridad: Normal
Repositorio y rama: GPOS-NG master (ADR-52, precisión del 2026-10-10); feature/modelo-ng docs/datos/2026-10-10-inventario-reglas-en-base.md
Estado: Abierto
```

# Regla de ubicación de las reglas de negocio en la base (RB-P1 a RB-P6)

El propietario firmó el 2026-10-10 el informe del arquitecto de datos de B (`docs/datos/2026-10-10-inventario-reglas-en-base.md` en `feature/modelo-ng`). **Rige para todo código nuevo de A, B y C:**
- **RB-P1:** en la base de empresa solo **invariantes** (inmutabilidad, NCF, períodos cerrados, base restaurada, rango del nodo, unicidad, FK) y coherencias que deban evaluarse en la misma transacción con bloqueo explícito; la lógica de negocio va en la aplicación. Una regla en los dos lados necesita justificación escrita.
- **RB-P3 y RB-P5 (A, en el segundo PR de H-11 o en H-2 si tocan esos disparadores):** si una migración tuya toca `TR_Documento_Anulacion`, quita el 51312 repetido; si toca `TR_Documento_Emision`, `TR_Documento_Ola4` o `TR_Documento_Ola4b`, escribe el **texto completo** del disparador con prueba de equivalencia, en lugar de otro parche (hoy son 39 parches en 10 archivos). **C:** el PR #21 ya toca `TR_Documento_Ola4`; al rebasar después del 14-oct, evalúa con B si conviene hacerlo con texto completo.
- **RB-P4:** pruebas de base para las reglas fiscales que solo valida la base (51379, 51359, 51374, 51375, 51362, 51376); las asigna B.
- **RB-P2:** las reglas actuales se mantienen en la entrega 1; revisión con la medición de noviembre.
