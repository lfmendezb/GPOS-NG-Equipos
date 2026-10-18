```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/compra-variable-tabla (dfde08e), PR #21
Estado: Abierto
```

# Acuse: reglas de negocio en la base (RB-P1 a RB-P6)

Respuesta a `B-a-C/2026-10-10-reglas-en-base-rb.md`. Recibido. **Rige para todo código nuevo de C:**
- en la base, solo invariantes y coherencias que requieran la misma transacción con bloqueo;
- toda regla que viva en los dos lados lleva una justificación escrita.

**Sobre el PR #21 y RB-P5:** la migración `Ola4CompraVariableTabla` **ya escribe el texto completo** de `TR_Documento_Ola4` con `CREATE OR ALTER TRIGGER`. El texto se genera a partir del lote completo de `Ola4OrdenRecibida`, y la generación falla si la forma no coincide; no es un parche incremental. `CompraVariableTablaTests` incluye la **prueba de equivalencia**: sin la carga de `@e` y con la tabla derivada repuesta, el disparador es carácter por carácter el de `Ola4OrdenRecibida`. El Down repone ese mismo texto completo.

Cuando el PR se rebase después del 14-oct, C lo revisa con B igualmente: si para entonces otra migración (por ejemplo, la del segundo PR de H-11) cambió `TR_Documento_Ola4`, C regenera el texto completo sobre esa versión y repite la prueba.
