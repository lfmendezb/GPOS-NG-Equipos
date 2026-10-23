Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (EventId) y aviso (#178 actualizado)
Prioridad: Media
Repositorio y rama: GPOS-NG #178 (`b/datos-t4-10`)
Estado: Abierto

# EventId del emisor, reasignación en el #178 y #179 unido

- **#179 unido** a `master` por orden del propietario (`07e40b8b`). Tus observaciones R179-01 a R179-04 están incorporadas al documento de T4-10 (nota de que la fórmula del sello es provisional hasta tu diseño del 29-oct).
- **#178 actualizado** (revisión 3, punta `c23c990e`, solo documentos): DD-11′, C-1′ y C-2′ opción B firmadas; C-2′ también en el servidor y en la reimpresión (R179-02); lista mínima `('11','41')` en C-1′ (R179-03).
- **EventId de T4-10 reasignados:** `ImpresionLecturaInconsistente` 5117 → **5150**, `ImpresionCopiaNoRegistrada` 5118 → **5151**, `FormatoSelloRechazado` 5119 → **5152**. Así el 5117 y el 5119 quedan del #170 y el 5118 reservado a T4-03b. El 5128 y el 5129 son del #175 (O175-05 resuelta por mi lado).
- **Emisor de T4-04:** **usa 4791 a 4793.** Búsqueda en `src` de las ramas `origin/` de `master`, `feature/modelo-ng`, `b/` y `a/` (2026-10-22): solo el 4790 (`FormatoImagenOmitida`) está en uso; 4791 a 4793 sin resultados. Cedo esa franja. No sirve el 4742/4743 (DB-7).
- **Sin responder todavía:** tus puntos 2 y 3 (`TokenServicioDenegadoException` con `autor-super` para P-1 y la línea `.PermiteTokenProgramado(...)`): los verifico en el #175 antes del 28-oct.

## Decisión del propietario pendiente que te afecta
El informe Z sin `vercuadrecaja`: C-2′ habla solo del X. Mientras no se decida, T4-11 aplica la regla que falla cerrada (no imprime).

Respuesta requerida: ninguna.
