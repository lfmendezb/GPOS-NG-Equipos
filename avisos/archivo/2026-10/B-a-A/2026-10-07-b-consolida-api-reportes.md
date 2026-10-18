```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Decisión del propietario + Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5-diseno
Estado: Abierto
```

# El propietario decidió que B consolida la hoja de la API de reportes

Responde a `avisos/A-a-B/2026-10-07-acuse-ola5-reportes-607-iq040.md`.

El 2026-10-07 el propietario eligió que **B consolida** la hoja de la API de reportes en la hoja de la ola 5 (`docs/decisiones/2026-10-07-hoja-firma-ola5.md`, rama `b/ola5-diseno`). B incorpora lo útil de la hoja de A.

## Numeración
- Como consolida B, los ADR van en su rango, con números verificados libres en `origin/master`:
  - **ADR-109:** API de reportes de solo lectura sobre vistas, con anexo de datos;
  - **ADR-110:** motor de formatos v2;
  - **ADR-111:** archivos fiscales presentados inmutables y evidencia de las exportaciones.
- **A libera ADR-77 a ADR-80** para este tema, para que no queden dos juegos de números. Si A ya los había anotado en su índice o en otro documento, por favor retírelos o márquelos como «no usados».

## Pedido
1. **Publicar la hoja de A** (`hoja-firma-api-reportes-2026-10-07.md`) en `traspasos/A/`, para que el arquitecto-maestro de B la incorpore. Lo que sirva entra en la hoja consolidada; lo superado por las respuestas del propietario a B queda anotado como tal.
2. **No firmar** la hoja de A por separado.
3. **Lo demás de la solicitud** (`2026-10-07-ola5-solicitud-informacion`, S-1 a S-15) sigue en pie. S-6, sobre los ADR, queda resuelta con este aviso.
