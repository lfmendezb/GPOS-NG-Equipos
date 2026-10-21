```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (PR #130, #124 actualizado) y consultas
Prioridad: Media
Repositorio y rama: GPOS-NG PR #130 `a/adr90-rt06-filtro-origen` @ e53b71a3 (apilado sobre #122); PR #124 `a/instalador-o1-o3` @ 66d9127f
Estado: Abierto
```

# PR #130 (PR-3 de ADR-90) y #124 con S-06, S-07 y las pruebas de C

## #130: filtro por la IP de la conexión (RT-06, PT-05 punto 4)
- **Apilado sobre el #122** (su base es `a/adr90-rt01-modo-red`); al unirse el #122 se rebasa sobre `feature/modelo-ng`. Sin cablear: no toca ningún `Program.cs`.
- **Nota sobre el nombre:** PR-3 es el **filtro por IP** del plano (las reglas de cortafuegos y los parámetros son de B, verbo `red`/paquete). Tu lista decía «reglas de cortafuegos por clase y parámetros»; sigo mi plano v2 salvo que me digas otra cosa.
- Revisión de seguridad: Aprobado con observaciones (`traspasos/A/revision-seguridad-pr3-adr90-2026-10-20.md`). Corregidos S3-01 (el filtro se niega a prepararse si el marco va a reescribir la IP: `ForwardedHeaders_Enabled` o IIS fuera de proceso; esas fuentes entran en la regla 1 de RT-01, 4744 —cambio de `ArranqueRed.cs` que vive en este PR porque contiene el #122—), S3-04 y S3-03. S3-05 verificada con Kestrel real y no se confirma. **Para B/devops:** S3-02 (sin NAT, IP fija de nodo, IPv6) y nota en la guía de que el servicio no va detrás de IIS. **Para D2:** S3-06 (clave /64 en IPv6).
- EventId 4750 y 4751. Pruebas filtradas 533/533 y 10/10. Suite oficial completa sin correr.
- **PR-4** cablea dos líneas (API antes de `UseForwardedHeaders`, Web igual) con la prueba de arquitectura del orden; espera el N-1 de B (PR #127).

## #124: lo aplicado de tus respuestas y de C
- **S-06** como indicaste: condición por feature (`&EstacionImpresion=3 OR !EstacionImpresion=3`) mediante la variable `GposFeatureCarpetas` que define cada MSI consumidor (falta la variable = falla la compilación). Vector v3 sin cambios por esto. **Nota:** `REMOVE=EstacionImpresion` hace que la acción aún corra; alternativa `&F = 3 OR (!F = 3 AND NOT &F = 2)` documentada si quieres cerrarlo.
- **S-07: GUID nuevo de la raíz `66D68CDE-6BFC-4590-9089-68AD56F78DD3`** (publicado en el vector v3, aún sin publicar; SHA-256 recalculada; el `9E7A0D3C-…` pasa a `guidRetirados`). **Lo necesitas para IQ y AdmCloud (R-O3-4/P-O3-5).** También regeneré `ProgramaEstacion` (patrón no aleatorio). `OrigenEventosEstacion` tiene un GUID de aspecto manual que no entra en el criterio; solo existe en desarrollo, tú decides.
- **S-08:** `docs/operaciones/2026-10-20-raiz-gpos-ng-instalador.md` (incluye el procedimiento «Carpeta insegura», que no existía).
- **C (P124-01 a 07, 09):** atendidos; P124-02 con mi decisión (b): se comprueba el padre de la raíz antes de crearla, sin crear nada en el destino. Prueba de mutación hecha. P124-08: guardas de texto; la de la firma de la `.CA.dll` (S-04) queda **omitida con su motivo** hasta que devops firme en `construir.ps1`.
- Pruebas: 156 correctas, 1 omitida a propósito, 0 fallidas. Falta la relectura del auditor y el laboratorio elevado (P-O1-7 con caso FIPS, P-O1-8, P-O3-4).

## Laboratorio de ADR-90 (tu tarea 3)
Aún no he leído el diseño v3 de C para fijar fecha. Confirmo el reparto (el QA de A lo construye antes de RT-02 a RT-04) y propongo la fecha tras leerlo; la publico mañana.

Respuesta requerida: ninguna urgente (GUID a los conectores y la decisión sobre `OrigenEventosEstacion`).
