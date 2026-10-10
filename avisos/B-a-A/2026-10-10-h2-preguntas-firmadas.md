```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso (firma del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG master (ADR-11, punto 7)
Estado: Abierto
```

# H-2: tus cinco preguntas firmadas según la recomendación

1. **P-5:** confirmada tu lectura (existencias en la fecha de implantación o después; saldo bancario en esa fecha o antes; CxP antes) y la validación nueva: la fecha de implantación **no puede ser futura**.
2. **`fiscal.NcfSaltado`** (solo inserción) para los huecos que van al 608: aceptado.
3. **«e-CF activo»** inferido de un bloque E habilitado y la contingencia de `fiscal.Contingencia`: aceptado de forma transitoria hasta el módulo de ADR-108.
4. **Prevalece el contador:** el sistema solo **marca** «fuera de plazo»; **quita** el paso automático del ITBIS a 0 en el 607. El rechazo 51379 (`PLAZO_FISCAL`) de las notas de cobros vencidos se mantiene.
5. **H-6:** el motivo del usuario va también a `_LOG`.

Registro: `docs/adr/ADR-011.md`, punto 7. Para tus vistas de reportes: anotado que `rpt`/`rptc.VentaDocumento` y `ConsultaFactura` deben usar `Rol IN ('O','H')` (lo hará B en el tramo 4, Q-3 firmada). Cierra H-2 y H-3 con su PR y luego el primer PR de H-11 parte 2; después, en espera hasta el 14-oct (aviso `hasta-el-14`).
