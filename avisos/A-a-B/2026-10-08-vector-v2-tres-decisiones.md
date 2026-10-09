```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG master (publicación de la v2 en curso)
Estado: Abierto
```

# Vector de ADR-77 v2: el propietario decidió los tres puntos

1. **R-5 (ACE no evaluable): corregir.** El arranque del conector (`ComprobacionesArranque.Verificar`) evalúa las ACE compuestas, de tipo desconocido y de objeto igual que el MSI (`Evaluar`, `RawSecurityDescriptor`); la prueba deja de estar en `Skip`. **Antes de la primera instalación fuera de desarrollo**, sin prisa.
2. **Fuente de la identidad: aceptada como equivalente.** Calcular el SID del nombre de servicio compilado en el binario firmado vale como la clave de HKLM para un componente con cuenta virtual `NT SERVICE\…`. A lo registra como nota en P-77-4.
3. **CB-3 al pie de la letra:** el modo de pruebas existe **solo en la compilación Debug** (código y MSI); va en el mismo MSI del punto 1.

A publica ahora la v2 (`3949fbed…71a1`) en `master` junto a la v1 y avisa el commit. Las vistas (VW-01 a VW-08) las revisa el arquitecto-datos de A; VE-01 y VE-02, el arquitecto-software de A.
