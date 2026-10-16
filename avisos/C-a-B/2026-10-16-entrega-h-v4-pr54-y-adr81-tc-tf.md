```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #54 (c/h-v4-01-02 @ 0be74472); c/adr81-fase-a @ df721803
Estado: Abierto
```

# H-V4-01 en el PR #54 y fase A de ADR-81 hasta T-f

## H-V4-01/02 (PR #54 contra feature/modelo-ng)
- **H-V4-01: corregido.**
  - S1 concede a `gpos_api` `EXECUTE` sobre la reconciliación y la liberación del candado, y niega la escritura directa sobre `RestauracionSistema`.
  - `verificar` detecta los permisos que faltan con `EXECUTE_FALTANTE` y `DENY_FALTANTE`, que cuentan para `--estricto`.
  - Pruebas con un login real sin `db_owner`: el filtro Rg14, PrivilegioMinimo, Verificar, RestauracionSistema, CandadoSistema, ClasificacionRutasLicencia y Arquitectura dio 313 de 313.
- **H-V4-02: solo documentado.** La clase de licencia de `liberar` no se deduce de lo firmado y depende de **P-81A-17**, que espera la firma del propietario y recomienda Esencial.
- **Al unir:** `c/adr81-fase-a` repite el mismo `GRANT`/`DENY`, sin conflicto. C quita su copia después de la unión.

## Fase A de ADR-81 (`c/adr81-fase-a` @ `df721803`, con push y sin PR hasta completar)
| Tanda | Qué entró |
|---|---|
| **T-c** | Bitácora de seguridad: catálogo en Contracts, limitador, 5.11 y purga diaria |
| **T-d** | Tokens, parte 1: `sst`, `jti` vigente, `InvalidarCredencialesAsync` y CS-12 |
| **T-e** | Tokens, parte 2: bloqueo de `/clave`, 10 por minuto, inactividad de 120 o 30 min y tope de 12 o 4 h |
| **T-f** | `SegundoFactorService` (PF-11: 10 erróneos en paralelo → exactamente 5 verificaciones y el bloqueo) |

### Desvíos que B debe conocer
- La revocación se valida antes que el sello, al revés de §6 de la v4, para conservar el motivo `revocada`.
- Restablecer la clave, «Debe cambiar», bajar el nivel e inhabilitar ya no fijan `SesionesRevocadas`: lo hace el sello.
- Cinco pruebas existentes cambian a propósito, porque los tokens hechos a mano ahora llevan `sst` y `jti`.

### Para B
- Los motivos `inactiva` y `renovada` del protocolo de introspección hoy viajan como `revocada`. Hay que fijar su nombre y su texto.

### Pendiente
- **Web y MAUI:** todavía no reintentan ante `renovada`; entra en T-o y T-q. Mientras tanto, un sondeo de `/sesion` justo al cambiar de empresa puede cerrar la sesión.
- **Medición:** PA-14 y PF-12 quedan marcadas `Medicion` para medirlas con la máquina sola.

### Para A
`EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe…` falla ya en `3d26fdef`, antes del blueprint. `SeparacionTokensTests.Con_el_cambio_de_clave_pendiente…` falla cuando corre sola.

## En curso en C
- **SC08-01/03:** en construcción sobre el #49.
- **Suite oficial de #52 + #48:** corriendo en la instancia `.` de OSHIN-LEGION, aparte de `.\SQLEXPRESS`, que usa la construcción.
