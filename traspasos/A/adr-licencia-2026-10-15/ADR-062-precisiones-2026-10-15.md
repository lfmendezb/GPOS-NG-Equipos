# ADR-62 · Precisiones del 2026-10-15 para registrar (tercera firma de la hoja de licencia)

**Para quien registra (B), no se copia al ADR.** Este archivo tiene tres partes con reglas distintas:

| Parte | Qué es | ¿Se registra ahora? |
|---|---|---|
| **A** | Precisiones P-1, P-2, P-4 y P-5 del blueprint v2.4 sobre la autorización `autNivel` (punto 6), aprobadas con «las P de v2.2 a v2.4» | **Sí** |
| **A, apartado 3** | P-3 del blueprint v2.4: fechas civiles en hora de RD. **Es el mismo contenido que C-3**, que B mantiene pendiente | **B decide:** registrarla ya por la aprobación de las P, o esperar a que el propietario confirme C-3 (observación de la sección 7 de la hoja v2.13) |
| **B** | Nota de remisión a ADR-84 por DL-11 (punto 3, Q-16 e INV-1) | **Sí, junto con ADR-84** |
| **C** | Precisión de Q-17 por DL-09 | **No, salvo que se dispare:** solo si el orquestador confirma un atraso de 5 días hábiles o más respecto de H-3 (2026-11-13). Hoy no aplica |

- **Dónde va:** al final de `docs/adr/ADR-062.md`, después de la precisión del 2026-10-14 del punto 7 (DL-14 y DL-17).
- **Fuente:** hoja DL-01 a DL-22 **v2.13** (`traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md` del área común), DL-09, DL-11, C-3, sección 5 (O-2) y sección 7; blueprint de la licencia del lote 2, registro de cambios v2.4; validación del PR #32 (`traspasos/A/validacion-l1a-2-reglas-aceptacion-2026-10-14.md`).
- **Fila del índice (`README.md`, fila 62), texto que se agrega con A y B:** «precisiones del 2026-10-15 del punto 6 (autorización `autNivel` con campos cerrados, misma `sec` = mismo contenido, `InstalacionId` en formato `D`) y remisión a ADR-84 (DL-11: la caducidad de `s1` la fija la versión con las llaves Avanzadas)».

---

## Parte A · Se registra ahora

> **Precisión del 2026-10-15 del punto 6: reglas de aceptación de la autorización de regreso temporal (`autNivel`) (precisiones P-1 a P-5 del registro de cambios v2.4 del blueprint de la licencia del lote 2, validación del PR #32, L1a-2; aprobadas por Leonardo Méndez, propietario, el 2026-10-15 en la sesión de B con la tercera firma de la hoja de firma DL-01 a DL-22 v2.13, en el área común `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`\*: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.», lista que incluye «las P de v2.2 a v2.4»).** Sin cambiar el texto firmado de arriba:
> 1. **Verificación compacta (P-1).** La autorización se verifica con `IVerificadorJws.VerificarCompacto`, que solo admite el `typ` `gpos-autorizacion-nivel+jws`, y esa función entra en la revisión de código del auditor-seguridad de `GPOS.Criptografia` (SEG-L2-08).
> 2. **Campos cerrados (P-2).** La autorización `autNivel` tiene un conjunto cerrado de campos: si trae uno desconocido, se rechaza. Es coherente con la `causa` de catálogo cerrado de la precisión del 2026-10-05.
> 3. **Fechas civiles en hora de RD (P-3; mismo contenido que C-3 de la hoja).** Las fechas civiles del formato se leen en hora de RD: `vence` (último día pagado), `aceptarHasta` (rige desde las 00:00 de RD de ese día), el tope de 200 días de DL-14 y el de `hasta` + 31 días, que toman la fecha de `emitida` en hora de RD. La diferencia con UTC es de un día como máximo y va del lado restrictivo; el emisor usa el mismo criterio.
> 4. **Misma `sec`, mismo contenido (P-4).** Dos autorizaciones con la misma `sec` y contenido distinto: la segunda se rechaza.
> 5. **Formato del `InstalacionId` (P-5).** Es un GUID en formato `D`, en minúsculas, y se compara sin distinguir mayúsculas.
>
> Costo: unos 0,15 dp en L1a-2 y 0,05 dp en el emisor. **Decidido, no implementado** (L1a-2 ya lo construye así).
>
> \* *La hoja vive en el área común; no está copiada en `master`.*

## Parte B · Se registra junto con ADR-84

> **Nota del registro (2026-10-15): caducidad de `s1` (punto 3, Q-16 e INV-1), por [ADR-84](ADR-084.md).** Con DL-11 (a), firmada por el propietario el 2026-10-15 (misma firma), la `aceptarHasta` de `gsf-lic-s1` y de su reserva `gsf-lic-s1r` la fija **la versión que incorpora las llaves Avanzadas**: su fecha prevista de publicación más 45 días, escrita en el PR de las llaves y corregida si la publicación se retrasa más de 7 días. La reemisión de transición se cofirma con `s1` y `a1`. Mientras no haya una llave Avanzada activa en los binarios, INV-1 sigue ignorando la caducidad (`LlaveBasicaSinRelevo`). Sustituye, para esas llaves, la fecha del 2026-12-31. Detalle en [ADR-84](ADR-084.md), punto 7. **Decidido, no implementado.**

## Parte C · Solo si se dispara DL-09 (hoy no se registra)

**Condición para registrarla:** el orquestador confirma por escrito un atraso de **5 días hábiles o más respecto de H-3** (2026-11-13) y la sesión principal decide usar el recorte. B la registra ese día con la fecha real y la evidencia del orquestador. Si el recorte no se usa, esta parte se descarta.

> **Precisión del AAAA-MM-DD del punto 6 y de su precisión del 2026-10-05 (Q-17): la autorización de regreso temporal sale de la versión del corte (DL-09 (a) de la hoja de firma DL-01 a DL-22 v2.13, firmada por Leonardo Méndez, propietario, el 2026-10-15 en la sesión de B: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.»; disparada el AAAA-MM-DD por un atraso de N días hábiles respecto de H-3, confirmado por el orquestador en `<ruta del informe>`).** Sin cambiar el texto firmado de arriba:
> 1. La autorización de regreso temporal a Básico (`autNivel`) **no se construye en la versión del corte**. Se construye a más tardar en la versión que incorpore las llaves Avanzadas, antes del paso a Avanzado (AP-05), con el campo `instalaciones` y la `causa` de catálogo cerrado desde su primera versión y con las reglas de la precisión del 2026-10-15 del punto 6.
> 2. *Sustituye,* en la precisión del 2026-10-05, «La autorización trae desde L1 el campo `instalaciones` […] El campo no se agrega después de L1» por «desde la primera versión que acepte autorizaciones `autNivel`».
> 3. **Por qué no deja ningún caso sin cubrir:** mientras no haya llaves Avanzadas en los binarios, toda licencia se firma en Básico (F-2) y no hay de qué regresar [I]. La versión del corte trata una licencia que traiga `autNivel` como lo fije el arquitecto-software (por ejemplo, rechazo con `LICENCIA_AUTORIZACION_INVALIDA`) [I].
> 4. Ahorra unos 1,75 dp del calendario del corte. `[SEG]`: sin objeción. **Decidido, no implementado.**
