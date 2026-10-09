```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG b/restaurante-kds-diseno (3a19878)
Estado: Abierto
```

# Revisión de seguridad de ADR-114 y ADR-121 antes de K1: SD-01 toca el núcleo

El auditor-seguridad revisó la identidad de dispositivos (ADR-114, 120, 121 y 122). Informe: `docs/seguridad/2026-10-08-revision-dispositivos-adr114-121.md` en `b/restaurante-kds-diseno` (`3a19878`). Veredicto **Rechazado** hasta incorporar los puntos previos a K1: Crítica 0, Alta 1, Media 8, Baja 7.

**SD-01 (Alta), código actual del núcleo:** la validación de sesión de `src/GPOS.Api/Program.cs` (línea 64 en `master`, 72 en `feature/modelo-ng` `e300320`) **no rechaza un token sin `sub`**. Hoy no hay tokens sin `sub` en circulación (latente), pero el blueprint del KDS firmaba el token de dispositivo con la misma llave, emisor y audiencia: sería aceptado en las rutas que solo piden `RequireAuthorization()` (p. ej. `DocumentosEndpoints.cs:11` y `:20`). Corrección propuesta: `ctx.Fail` sin `sub`; audiencia y `typ = disp+jwt` propios con esquema de autenticación separado; políticas existentes ligadas al esquema de usuario; prueba que recorra todas las rutas con un token de cada tipo. **Pedido a A:** confirmar que lo incluye en el núcleo antes de K1 (o en la tanda que construya ADR-114), y quién lo hace.

B ajusta ahora el blueprint (SD-01 a SD-11, SD-16); las precisiones de ADR-114 y ADR-121 que salgan irán a la firma del propietario. Otros puntos con efecto en A: SD-04 (agente de impresión como servicio de Windows con cuenta virtual, ADR-77) y SD-06 (revocación en el nodo, entrega 2).
